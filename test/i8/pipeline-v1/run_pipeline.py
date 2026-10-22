#!/usr/bin/env python3
"""Run both independent pipelines from zero using MATLAB's sole configuration.

Only local current-attempt JSON passes search state between serial MATLAB batches.
All model/evaluation/search constants come from pipeline_i8_config.m. Process
walls are mutually exclusive; callback timers remain subsets of numeric stages.
"""
import argparse
import csv
import datetime as dt
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def write_json(path, value):
  path.write_text(json.dumps(value, indent=2, allow_nan=False) + '\n')


def snapshot():
  result = subprocess.run(['ps','-axo','pid=,ppid=,pgid=,rss=,%cpu=,comm='],
    capture_output=True, text=True, check=True)
  rows = {}
  for line in result.stdout.splitlines():
    fields = line.split(maxsplit=5)
    if len(fields) == 6:
      pid, ppid, pgid, rss, cpu, command = fields
      rows[int(pid)] = dict(ppid=int(ppid), pgid=int(pgid), rss=int(rss)*1024,
        cpu=float(cpu), command=command)
  return rows


def descendants(rows, roots):
  members = set(roots)
  while True:
    added = {pid for pid, row in rows.items() if row['ppid'] in members} - members
    if not added:
      return members
    members |= added


def matlab_pids(rows):
  return {pid for pid, row in rows.items() if 'matlab' in row['command'].lower()}


def matlab_quote(text):
  return "'" + str(text).replace("'", "''") + "'"


def run_batch(request, batch_dir, paths, config=None):
  request['output_dir'] = str(batch_dir)
  if batch_dir.exists() and paths.get('resume'):
    previous_request=json.loads((batch_dir/'request.json').read_text())
    if previous_request != request:
      raise RuntimeError('resume request differs from current-attempt batch')
    status_path=batch_dir/'status.json'
    previous_status=json.loads(status_path.read_text()) if status_path.exists() else {}
    if previous_status.get('exit_code')==0 and not previous_status.get('survivors'):
      required={'config':'config.json','points':'points.json','estimate':'result.json'}[request['action']]
      if not (batch_dir/required).exists():
        raise RuntimeError('successful batch missing its numerical output')
      print('RESUME completed current-attempt batch '+str(batch_dir),flush=True)
      return previous_status
    retry=1
    while batch_dir.with_name(batch_dir.name+f'-failed-{retry:02d}').exists():
      retry+=1
    batch_dir.rename(batch_dir.with_name(batch_dir.name+f'-failed-{retry:02d}'))
  batch_dir.mkdir(parents=True, exist_ok=False)
  request_path = batch_dir / 'request.json'
  write_json(request_path, request)
  # Bootstrap has no numerical evaluation; all later limits use exported config.
  limits = config['resources'] if config else dict(rss_bytes=3*1024**3,
    soft_seconds=1800, hard_seconds=2400, sample_seconds=.5,
    deadline_utc='2026-10-21T07:47:41Z')
  if paths.get('deadline'):
    limits=dict(limits,deadline_utc=paths['deadline'])
  threads = config['backend']['threads'] if config else 11
  expression = '; '.join('addpath('+matlab_quote(path)+')' for path in paths['addpath'])
  expression += '; pipeline_i8_batch(' + matlab_quote(request_path) + ');'
  command = [paths['matlab'], '-batch', expression]
  env = dict(os.environ, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC='FALSE')
  write_json(batch_dir/'command.json', dict(command=command, threads=threads))
  started = time.monotonic(); process = None; known = set(); peak = 0
  reason = 'not_started'; exit_code = 3; grace = False
  deadline = dt.datetime.fromisoformat(limits['deadline_utc'].replace('Z','+00:00')).timestamp()
  def cleanup():
    if process is None:
      return
    try:
      os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
      pass
    for pid in known:
      try:
        os.kill(pid, signal.SIGKILL)
      except ProcessLookupError:
        pass
    process.wait()
  def interrupted(signum, frame):
    raise KeyboardInterrupt('signal ' + str(signum))
  prior_handlers = {sig:signal.signal(sig, interrupted) for sig in (signal.SIGINT,signal.SIGTERM,signal.SIGHUP)}
  try:
    rows = snapshot(); write_json(batch_dir/'preflight.json', rows)
    if matlab_pids(rows):
      raise RuntimeError('preexisting MATLAB prevents serial launch')
    with (batch_dir/'run.log').open('w') as log, (batch_dir/'resources.csv').open('w') as resources:
      writer = csv.writer(resources); writer.writerow(['elapsed_seconds','rss_bytes','cpu_percent','pids','external_matlab'])
      process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, env=env, start_new_session=True)
      known.add(process.pid); reason = 'process_exited'
      while process.poll() is None:
        time.sleep(limits['sample_seconds'])
        rows = snapshot(); pids = descendants(rows,{process.pid}); known |= pids
        external = matlab_pids(rows)-pids
        rss = sum(rows[pid]['rss'] for pid in pids if pid in rows); peak = max(peak,rss)
        elapsed = time.monotonic()-started
        writer.writerow([elapsed,rss,sum(rows[pid]['cpu'] for pid in pids if pid in rows),sorted(pids),sorted(external)])
        resources.flush()
        if external:
          raise RuntimeError('foreign MATLAB detected')
        if rss >= limits['rss_bytes']:
          raise RuntimeError('3 GiB process-tree RSS hard limit')
        if elapsed >= limits['hard_seconds'] or time.time() >= deadline:
          raise RuntimeError('hard time limit')
        if elapsed >= limits['soft_seconds'] and not grace:
          progress_path = batch_dir/'progress.json'
          progress = json.loads(progress_path.read_text()) if progress_path.exists() else {}
          remaining = (progress.get('total',1)-progress.get('done',0))*elapsed/max(1,progress.get('done',0))
          if not progress.get('done') or remaining > limits['hard_seconds']-elapsed:
            raise RuntimeError('soft limit without objective imminent completion')
          grace = True
      exit_code = process.wait()
      if exit_code:
        raise RuntimeError('MATLAB exit ' + str(exit_code))
  except BaseException as error:
    reason = type(error).__name__ + ': ' + str(error)
    raise
  finally:
    cleanup()
    survivors = []; cleanup_verification='no_process_launched'
    if process:
      time.sleep(.1)
      try:
        rows = snapshot()
        survivors = [pid for pid,row in rows.items() if pid in known or row['pgid']==process.pid]
        cleanup_verification='clean' if not survivors else 'survivors'
      except (OSError,subprocess.SubprocessError,ValueError) as error:
        cleanup_verification='verification_failed: '+str(error)
        reason+='; cleanup verification unavailable'
        exit_code=3
    status = dict(wall_seconds=time.monotonic()-started, peak_rss_bytes=peak,
      exit_code=exit_code, reason=reason, grace=grace, survivors=survivors,
      cleanup_verification=cleanup_verification)
    write_json(batch_dir/'status.json',status)
    for sig, handler in prior_handlers.items():
      signal.signal(sig,handler)
  if survivors or cleanup_verification.startswith('verification_failed'):
    raise RuntimeError('process cleanup could not be verified')
  print(str(batch_dir.name)+' '+json.dumps(status), flush=True)
  return status


def grid_between(first,last,count):
  # MATLAB linspace is authoritative: controller requests bounds below.
  return [first+(last-first)*j/(count-1) for j in range(count)]


def select_round(rows, kind):
  scores = [row['aphys_ratio'] for row in rows]
  best = min(scores); first_global = scores.index(best)
  dips = [j for j in range(1,len(rows)-1) if scores[j]<scores[j-1] and scores[j]<scores[j+1]]
  selected = min(dips,key=lambda j:scores[j]) if kind=='wide' and dips else first_global
  if kind=='wide' and not dips:
    raise RuntimeError('NO_STRICT_INTERIOR_DIP')
  return selected,dips,first_global


def pipeline(backend, output, config, paths):
  pipeline_started=time.monotonic()
  directory = output/backend; directory.mkdir(exist_ok=paths.get('resume',False))
  search=config['search']; resources=config['resources']
  domain_first=search['wide_first']; domain_last=domain_first+(search['wide_count']-1)*search['wide_step']
  requested=[domain_first+j*search['wide_step'] for j in range(search['wide_count'])]
  all_rows=[]; rounds=[]; batch_status=[]; history=[]; kind='wide'; round_index=0
  requested_step=search['wide_step']; estimate_point=resources['initial_'+backend+'_point_seconds']
  while True:
    if round_index > search['max_refinement_rounds']:
      raise RuntimeError('maximum round resource guard')
    if len(set(requested)) != len(requested) or any(b<=a for a,b in zip(requested,requested[1:])):
      raise RuntimeError('non-distinct requested doubles')
    current=[]
    chunk=search['wide_batch_count'] if kind=='wide' else search['refine_count']
    for offset in range(0,len(requested),chunk):
      values=requested[offset:offset+chunk]
      remaining=dt.datetime.fromisoformat(resources['deadline_utc'].replace('Z','+00:00')).timestamp()-time.time()
      expected=len(values)*estimate_point+15
      if expected > resources['soft_seconds'] or expected+resources['review_reserve_seconds'] > remaining:
        raise RuntimeError('batch cannot fit available budget')
      request=dict(schema='I84_PIPELINE_BATCH_V1',action='points',backend=backend,config=config,k_values=values)
      if kind!='wide':
        request['linspace_bounds']=[requested[0],requested[-1]]
        request['grid_history']=[dict(nodes=nodes) for nodes in history]
        if kind=='refine':
          request['previous_selected_k']=rounds[-1]['selected_k']
      batch_dir=directory/f'round-{round_index:02d}-batch-{offset//chunk:02d}'
      status=run_batch(request,batch_dir,paths,config); batch_status.append(status)
      rows=json.loads((batch_dir/'points.json').read_text())
      for row in rows:
        row.update(evaluation_index=len(all_rows)+1,round_index=round_index,round_kind=kind,node_index=len(current)+1)
        all_rows.append(row); current.append(row)
      estimate_point=sum(row['seconds'] for row in all_rows)/len(all_rows)
      write_json(directory/'points.json',all_rows)
    selected,dips,global_index=select_round(current,kind)
    actual=[row['k'] for row in current]; actual_W=actual[-1]-actual[0]
    if actual in history:
      raise RuntimeError('repeated actual MATLAB grid')
    history.append(actual)
    interior=0<selected<len(current)-1
    cumulative=min(all_rows,key=lambda row:row['aphys_ratio'])
    record=dict(round_index=round_index,kind=kind,count=len(current),first=actual[0],last=actual[-1],
      actual_W=actual_W,requested_step=requested_step,selected_index=selected+1,
      selected_k=actual[selected],selected_ratio=current[selected]['aphys_ratio'],
      global_index=global_index+1,strict_dips=[j+1 for j in dips],interior=interior,
      left_neighbor=actual[selected-1] if interior else None,right_neighbor=actual[selected+1] if interior else None,
      cumulative_k=cumulative['k'],cumulative_ratio=cumulative['aphys_ratio'])
    rounds.append(record); write_json(directory/'rounds.json',rounds)
    print(backend+' ROUND '+json.dumps(record),flush=True)
    if kind!='wide' and interior and actual_W<=search['width_target']:
      break
    if interior:
      first,last=actual[selected-1],actual[selected+1]; kind='refine'
      requested_step=(last-first)/(search['refine_count']-1)
    else:
      shift=search['endpoint_shift_steps']*requested_step
      first=actual[0]+(-shift if selected==0 else shift)
      requested_span=requested_step*(search['refine_count']-1)
      first=min(max(first,domain_first),domain_last-requested_span)
      last=first+requested_span; kind='recovery'
    requested=grid_between(first,last,search['refine_count']); round_index+=1
  winner=min(all_rows,key=lambda row:row['aphys_ratio'])
  result=dict(status='complete',backend=backend,candidate=winner,final_round_winner=current[selected],
    point_count=len(all_rows),round_count=len(rounds),search_point_seconds=sum(row['seconds'] for row in all_rows),
    search_process_wall=sum(status['wall_seconds'] for status in batch_status),final_round=rounds[-1])
  write_json(directory/'search-result.json',result)
  remaining=dt.datetime.fromisoformat(resources['deadline_utc'].replace('Z','+00:00')).timestamp()-time.time()
  if resources['estimate_budget_seconds']+resources['review_reserve_seconds'] > remaining:
    raise RuntimeError('estimate cannot fit remaining budget')
  request=dict(schema='I84_PIPELINE_BATCH_V1',action='estimate',backend=backend,config=config,k_values=winner['k'])
  status=run_batch(request,directory/'estimate',paths,config)
  result['estimate_process_wall']=status['wall_seconds']
  result['pipeline_elapsed_wall']=time.monotonic()-pipeline_started
  result['resumed']=paths.get('resume',False)
  result['elapsed_wall_scope']='current invocation; successful batch process walls retained across resume'
  result['pipeline_process_wall']=result['search_process_wall']+status['wall_seconds']
  result['peak_rss_bytes']=max([status['peak_rss_bytes']]+[item['peak_rss_bytes'] for item in batch_status])
  result['estimate']=json.loads((directory/'estimate/result.json').read_text())
  write_json(directory/'pipeline-result.json',result)
  return result


def main():
  parser=argparse.ArgumentParser()
  parser.add_argument('--output',required=True)
  parser.add_argument('--package-root',required=True)
  parser.add_argument('--fmm-root',required=True)
  parser.add_argument('--matlab',default='/Applications/MATLAB_R2023b.app/bin/matlab')
  parser.add_argument('--resume',action='store_true',help='Reuse only verified completed batches in this current attempt')
  parser.add_argument('--deadline',help='Explicit run resource deadline; science unchanged')
  args=parser.parse_args()
  launcher_started=time.monotonic()
  output=Path(args.output).resolve(); output.mkdir(parents=True,exist_ok=args.resume)
  source=Path(__file__).resolve().parent
  paths=dict(matlab=args.matlab,addpath=[str(Path(args.package_root).resolve()),str(source),str(Path(args.fmm_root).resolve())])
  paths['deadline']=args.deadline
  paths['resume']=args.resume
  setup=run_batch(dict(action='config'),output/'setup',paths)
  config=json.loads((output/'setup/config.json').read_text())
  if args.deadline:
    config['resources']['deadline_utc']=args.deadline
  results={backend:pipeline(backend,output,config,paths) for backend in config['backend']['order']}
  write_json(output/'result.json',dict(config=config,setup=setup,pipelines=results,launcher_wall=time.monotonic()-launcher_started))


if __name__=='__main__':
  main()
