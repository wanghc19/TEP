#!/usr/bin/env python3
"""Monitor one I10.2 run (design-10-2a D1); no scientific decisions.

Purpose: either launch refine_i102 in MATLAB for one explicit group
  (--group g12|g24|g48), or run the cross-group summarizer
  summarize_refine.py (--summarize), as a monitored child under one wall clock
  and one process-tree memory budget.
Based on: test/i10/enrich-v1/run_enrich.py (launcher-rooted process-tree RSS
  sampling, killpg cleanup, soft/grace/hard limits, source snapshot, records).
Main changes: explicit group argument; the stop time of every managed child is
  the earlier of the per-configuration hard limit (2400 s) and the fixed
  total-task deadline read from task-deadline.json minus a closing reserve,
  so restarting the launcher or changing run-id never resets the task clock;
  a launch is refused when the remaining task budget is below the reserve.
MATLAB receives only the output path and the group name.
"""
import argparse
import csv
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
SOURCES = ['refine_i102.m', 'refine_i102_config.m', 'run_refine.py', 'reuse_refine.py',
  'summarize_refine.py']
DEADLINE_FILE = HERE/'output'/'attempt-1'/'task-deadline.json'


def write_json(path, value):
  path.write_text(json.dumps(value, indent=2, allow_nan=True) + '\n')


def utc():
  return dt.datetime.now(dt.timezone.utc).isoformat()


def snapshot():
  result = subprocess.run(['ps', '-axo', 'pid=,ppid=,pgid=,rss=,%cpu=,comm='],
    capture_output=True, text=True, check=True)
  rows = {}
  for line in result.stdout.splitlines():
    parts = line.split(maxsplit=5)
    if len(parts) == 6:
      pid, parent, group, rss, cpu, command = parts
      rows[int(pid)] = dict(parent=int(parent), group=int(group), rss=int(rss)*1024,
        cpu=float(cpu), command=command)
  return rows


def tree(rows, root):
  members = {root}
  while True:
    added = {pid for pid, row in rows.items() if row['parent'] in members} - members
    if not added:
      return members
    members |= added


def matlab(rows):
  return {pid for pid, row in rows.items() if 'matlab' in row['command'].lower()}


def provenance(paths):
  """Identity of launched source files, machine record only."""
  record = {}
  for path in paths:
    stat = path.stat()
    record[path.name] = dict(path=str(path), bytes=stat.st_size,
      sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
      mtime_utc=dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat())
  return record


def quote(value):
  return "'" + str(value).replace("'", "''") + "'"


def grace_decision(progress_path, limits, k_target=2e-12):
  """Design 7: one grace (<= grace_seconds) only with objective evidence that
  completion is imminent: (a) all roots done and only figures/save remain;
  (b) the last P4 chain is in recovery; (c) the last P4 chain (check or a
  triggered extra) holds a valid bracket whose remaining Brent/bisection
  steps x slowest evaluation (+ recovery and save) x 1.5 fit in the grace."""
  try:
    progress = json.loads(progress_path.read_text())
  except (OSError, ValueError) as error:
    return dict(granted=False, rule=None, reason='progress unreadable: ' + str(error))
  phase = progress.get('phase')
  slowest = progress.get('slowest_eval_seconds')
  slowest = float(slowest) if isinstance(slowest, (int, float)) else math.nan
  known = float(progress.get('save_estimate_seconds') or 60)
  p = progress.get('p')
  rule = progress.get('rule') or ''
  last_chain = p == 4 and rule in ('check', 'extra')
  record = dict(progress=progress, grace_seconds=limits['grace_seconds'])
  if progress.get('all_roots_done') and phase in ('estimate', 'figures', 'save', 'done'):
    predicted = known
    record.update(rule='all_roots_done', predicted_seconds=predicted,
      granted=1.5*predicted <= limits['grace_seconds'])
    return record
  if phase == 'recovery' and last_chain:
    predicted = 3*slowest + known
    record.update(rule='last_chain_recovery', predicted_seconds=predicted,
      granted=math.isfinite(predicted) and 1.5*predicted <= limits['grace_seconds'])
    return record
  width = progress.get('bracket_width')
  if phase == 'root' and last_chain and isinstance(width, (int, float)) and width > 0:
    steps = max(0, math.ceil(math.log2(width/k_target))) + 2
    predicted = steps*slowest + 3*slowest + known
    record.update(rule='last_bracketed_chain', bisection_steps=steps,
      predicted_seconds=predicted,
      granted=math.isfinite(predicted) and 1.5*predicted <= limits['grace_seconds'])
    return record
  record.update(rule=None, granted=False,
    reason='required chains not started or no valid last-chain bracket at the soft limit')
  return record


class Stop(RuntimeError):
  pass


def monitor(name, command, env, output, state, writer, log, allow_grace):
  """Run one child in its own session; sample the launcher-rooted tree."""
  limits = state['limits']
  process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
    start_new_session=True, cwd=str(HERE))
  state['children'].append(dict(name=name, pid=process.pid, started=time.monotonic()-state['t0']))
  known = {process.pid}
  try:
    while process.poll() is None:
      time.sleep(limits['sample_seconds'])
      rows = snapshot()
      members = tree(rows, os.getpid())
      known |= tree(rows, process.pid)
      outside = matlab(rows) - members
      rss = sum(rows[pid]['rss'] for pid in members if pid in rows)
      state['peak'] = max(state['peak'], rss)
      elapsed = time.monotonic()-state['t0']
      writer.writerow([utc(), '%.3f' % elapsed, name, rss,
        ' '.join(map(str, sorted(members))), ' '.join(map(str, sorted(outside)))])
      state['resource_file'].flush()
      if state['warned'] is None and rss >= limits['warn_bytes']:
        state['warned'] = elapsed
        log.write('LAUNCHER RSS warning %.0f bytes at %.1fs\n' % (rss, elapsed))
        log.flush()
      if outside:
        raise Stop('Concurrent MATLAB detected: ' + ' '.join(map(str, sorted(outside))))
      if rss >= limits['rss_bytes']:
        raise Stop('Process-tree RSS hard limit (%.0f bytes)' % rss)
      if elapsed >= limits['hard_seconds']:
        raise Stop('hard limit (%.0f s: min of 40-minute configuration limit and task deadline)'
          % limits['hard_seconds'])
      if state['soft_crossed'] is None and elapsed >= limits['soft_seconds']:
        state['soft_crossed'] = elapsed
        if allow_grace:
          state['grace'] = grace_decision(output/'progress.json', limits)
        else:
          state['grace'] = dict(granted=False, rule=None, reason='summarizer still running')
        log.write('LAUNCHER soft limit at %.1fs during %s; grace %s (%s)\n' % (elapsed, name,
          state['grace'].get('granted'), state['grace'].get('rule')))
        log.flush()
        if not state['grace'].get('granted'):
          raise Stop('Soft limit without objective grace evidence')
        state['deadline'] = min(limits['soft_seconds'] + limits['grace_seconds'],
          limits['hard_seconds'])
      if state['soft_crossed'] is not None and elapsed >= state['deadline']:
        raise Stop('Grace deadline reached')
    return process.wait()
  finally:
    if process.poll() is None:
      try:
        os.killpg(process.pid, signal.SIGKILL)
      except ProcessLookupError:
        pass
      rows = snapshot()
      for pid in known:
        if pid in rows:
          try:
            os.kill(pid, signal.SIGKILL)
          except ProcessLookupError:
            pass
      process.wait()
    # descendants may still be shutting down right after exit: poll up to 15 s
    initial = None
    for _ in range(16):
      rows = snapshot()
      left = sorted(pid for pid, row in rows.items()
        if row['group'] == process.pid or pid in known)
      if initial is None:
        initial = left
      if not left:
        break
      time.sleep(1)
    state['survivors'][name] = dict(at_exit=initial, after_wait=left)


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--matlab', required=True)
  parser.add_argument('--group', choices=['g12', 'g24', 'g48'])
  parser.add_argument('--summarize', action='store_true',
    help='run summarize_refine.py over output/attempt-1 instead of MATLAB')
  parser.add_argument('--reserve-seconds', type=float, default=600,
    help='closing reserve kept before the total task deadline')
  parser.add_argument('--soft-seconds', type=float, default=1800)
  parser.add_argument('--grace-seconds', type=float, default=600)
  parser.add_argument('--hard-seconds', type=float, default=2400)
  parser.add_argument('--warn-bytes', type=int, default=2_700_000_000)
  parser.add_argument('--rss-bytes', type=int, default=3_000_000_000)
  args = parser.parse_args()
  if bool(args.group) == bool(args.summarize):
    parser.error('give exactly one of --group or --summarize')
  task = json.loads(DEADLINE_FILE.read_text())
  remaining = task['deadline_epoch'] - time.time() - args.reserve_seconds
  if remaining <= 60:
    print(json.dumps(dict(reason='task budget exhausted', remaining_seconds=remaining)))
    sys.exit(2)
  output = Path(args.output).resolve()
  output.mkdir(parents=True, exist_ok=False)
  hard = min(args.hard_seconds, remaining)
  limits = dict(rss_bytes=args.rss_bytes, warn_bytes=args.warn_bytes, sample_seconds=1,
    soft_seconds=min(args.soft_seconds, hard), grace_seconds=args.grace_seconds,
    hard_seconds=hard, configuration_hard_seconds=args.hard_seconds,
    task_deadline_utc=task['deadline_utc'], task_reserve_seconds=args.reserve_seconds)
  threads = 11
  t0 = time.monotonic()
  launched_utc = utc()
  # source snapshot (copies of the launched files) and identities
  (output/'source').mkdir()
  for name in SOURCES:
    shutil.copy2(HERE/name, output/'source'/name)
  write_json(output/'provenance.json', dict(sources=provenance([HERE/n for n in SOURCES])))
  expression = ('addpath(' + quote(HERE) + '); refine_i102(' + quote(output) + ','
    + quote(args.group) + ');')
  matlab_command = [args.matlab, '-batch', expression]
  summary_command = [sys.executable, '-I', str(HERE/'summarize_refine.py'), '--output',
    str(output)]
  write_json(output/'command.json', dict(matlab=matlab_command if args.group else None,
    summary=summary_command if args.summarize else None,
    group=args.group, launcher=sys.argv, started_utc=launched_utc, limits=limits,
    threads=threads, environment=dict(OMP_NUM_THREADS=str(threads), python=sys.version)))
  state = dict(limits=limits, t0=t0, peak=0, warned=None, soft_crossed=None, grace=None,
    deadline=limits['soft_seconds'], children=[], survivors={})
  phases = {}
  stop_status = None
  reason = 'not_started'
  exit_codes = {}

  def interrupted(signum, frame):
    raise KeyboardInterrupt('signal ' + str(signum))
  for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
    signal.signal(sig, interrupted)

  log = (output/'run.log').open('w')
  resource = (output/'resources.csv').open('w')
  state['resource_file'] = resource
  writer = csv.writer(resource)
  writer.writerow(['utc', 'elapsed_seconds', 'child', 'tree_rss_bytes', 'tree_pids',
    'external_matlab'])
  try:
    rows = snapshot()
    write_json(output/'preflight.json', dict(external_matlab=sorted(matlab(rows)),
      launcher_pid=os.getpid()))
    if matlab(rows):
      raise Stop('Existing MATLAB prevents serial launch')
    env = dict(os.environ, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC='FALSE')
    if args.group:
      start = time.monotonic()
      log.write('LAUNCHER matlab start %s group %s hard %.0fs\n' % (utc(), args.group, hard))
      log.flush()
      reason = 'matlab_running'
      exit_codes['matlab'] = monitor('matlab', matlab_command, env, output, state, writer, log,
        True)
      phases['matlab_seconds'] = time.monotonic()-start
      if exit_codes['matlab']:
        log.write('LAUNCHER MATLAB exit %d\n' % exit_codes['matlab'])
    else:
      start = time.monotonic()
      log.write('LAUNCHER summary start %s\n' % utc())
      log.flush()
      reason = 'summary_running'
      exit_codes['summary'] = monitor('summary', summary_command, dict(os.environ), output,
        state, writer, log, False)
      phases['summary_seconds'] = time.monotonic()-start
    reason = 'completed' if not any(exit_codes.values()) else 'child_nonzero_exit'
  except BaseException as error:  # record; cleanup happens inside monitor()
    stop_status = 'RESOURCE_STOP' if isinstance(error, Stop) else 'LAUNCHER_INTERRUPTED'
    reason = type(error).__name__ + ': ' + str(error)
  finally:
    resource.close()
    log.close()
  status = dict(launched_utc=launched_utc, finished_utc=utc(), group=args.group,
    summarize=args.summarize,
    exit_codes=exit_codes, reason=reason, stop_status=stop_status, phases=phases,
    wall_seconds=time.monotonic()-t0, peak_tree_rss_bytes=state['peak'],
    rss_warning_seconds=state['warned'], soft_limit_crossed_seconds=state['soft_crossed'],
    grace=state['grace'], children=state['children'], survivors=state['survivors'],
    limits=limits)
  write_json(output/'resource.json', dict(peak_tree_rss_bytes=state['peak'],
    tree_root='launcher (includes the MATLAB or summarizer subprocess)',
    rss_warning_seconds=state['warned'], soft_limit_crossed_seconds=state['soft_crossed'],
    grace=state['grace'], stop_status=stop_status, wall_seconds=status['wall_seconds'],
    phases=phases, survivors=state['survivors'], limits=limits))
  write_json(output/'status.json', status)
  print(json.dumps({k: status[k] for k in ('exit_codes', 'reason', 'stop_status',
    'wall_seconds', 'peak_tree_rss_bytes')}), flush=True)
  if stop_status or any(exit_codes.values()):
    sys.exit(1)


if __name__ == '__main__':
  main()
