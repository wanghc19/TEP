"""Dynamic one-panel queue for the complete central material curve.
Input: exact field, explicit target range and worker count.
Output: complete leaf certificates, worker/cache costs and load averages.
"""
import argparse,json,os,resource,sys,time,multiprocessing,traceback
from concurrent.futures import ProcessPoolExecutor,as_completed
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import ctx
from cached import Sources
from panel import compute
from chebyshev import SelfDomainFailure
from material import dump
DATA=None;CACHE=None;OUT=None;START=None;CPU=None;DONE=[];FAIL=[]

def worker_record():
  return dict(pid=os.getpid(),completed=DONE,failed=FAIL,cache=CACHE.record(),flint_threads=ctx.threads,
    process_wall_seconds=time.perf_counter()-START,process_cpu_seconds=time.process_time()-CPU,
    self_peak_rss_gib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/2**30)

def initialize(input_path,output):
  global DATA,CACHE,OUT,START,CPU
  START=time.perf_counter();CPU=time.process_time();ctx.prec=128;ctx.threads=1
  OUT=Path(output);DATA=json.loads(Path(input_path).read_text());CACHE=Sources(DATA,192,160,40,1152)
  rejected=False
  try:CACHE.validate(DATA,192,161,40,1152)
  except ValueError:rejected=True
  assert rejected
  dump(OUT/f'cache-{os.getpid()}.json',dict(**CACHE.record(),mismatch_rejected=rejected,pid=os.getpid()))
  dump(OUT/f'worker-{os.getpid()}.json',worker_record())

def task(idx):
  start=time.perf_counter();cpu=time.process_time();splits=[];leaves=[];failed=[]
  def part(depth,sub):
    ctx.prec=128
    try:
      r=compute(DATA,OUT,idx,192,160,52,40,1152,40,False,CACHE,depth,sub)
      leaves.append(dict(panel=idx,depth=depth,sub=sub,path=f"panel-{idx}"+(f'-d{depth}-s{sub}' if depth else '')+'.json'))
    except SelfDomainFailure as error:
      splits.append(dict(depth=depth,sub=sub,error=str(error)))
      if depth<2:
        part(depth+1,2*sub);part(depth+1,2*sub+1)
      else:failed.append(dict(depth=depth,sub=sub,error=str(error)))
    except Exception as error:
      failed.append(dict(depth=depth,sub=sub,error=str(error),traceback=traceback.format_exc()))
  part(0,0)
  result=dict(panel=idx,pid=os.getpid(),leaves=leaves,splits=splits,failed=failed,valid=not failed,
    wall_seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu)
  DONE.append(idx)
  if failed:FAIL.append(idx)
  dump(OUT/f'task-{idx}.json',result);dump(OUT/f'worker-{os.getpid()}.json',worker_record())
  print(json.dumps(dict(panel=idx,valid=not failed,leaves=len(leaves),seconds=result['wall_seconds'],pid=os.getpid())),flush=True)
  return result

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True)
  p.add_argument('--first',type=int,default=0);p.add_argument('--count',type=int,default=192);p.add_argument('--workers',type=int,default=8);a=p.parse_args()
  assert 1<=a.workers<=11 and 0<=a.first<a.first+a.count<=192
  start=time.perf_counter();parent_cpu_start=time.process_time();load_before=os.getloadavg();out=Path(a.output);rows=[]
  ctx0=multiprocessing.get_context('spawn')
  with ProcessPoolExecutor(max_workers=a.workers,mp_context=ctx0,initializer=initialize,initargs=(a.input,a.output)) as pool:
    futures={pool.submit(task,j):j for j in range(a.first,a.first+a.count)}
    for future in as_completed(futures):
      row=future.result();rows.append(row)
      if row['failed']:
        # Preserve the first invalid panel; pending jobs are cancelled. Running
        # jobs finish their own records, which remain visibly separate.
        for f in futures:f.cancel()
        break
  workers=[json.loads(f.read_text()) for f in out.glob('worker-*.json')]
  usage=resource.getrusage(resource.RUSAGE_CHILDREN)
  parent_cpu=time.process_time()-parent_cpu_start
  result=dict(parent_cpu_seconds=parent_cpu,reaped_child_cpu_seconds=usage.ru_utime+usage.ru_stime,total_python_cpu_seconds=parent_cpu+usage.ru_utime+usage.ru_stime,first=a.first,count=a.count,workers=a.workers,load_before=load_before,load_after=os.getloadavg(),
    wall_seconds=time.perf_counter()-start,summed_worker_cpu_seconds=sum(v['process_cpu_seconds'] for v in workers),
    worker_records=workers,tasks=rows,all_requested_valid=len(rows)==a.count and all(r['valid'] for r in rows))
  dump(out/'queue.json',result)
  if not result['all_requested_valid']:raise RuntimeError('Incomplete curve partition; see task and worker records')
if __name__=='__main__':main()
