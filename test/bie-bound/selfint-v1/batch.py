"""Serial/parallel central panels with explicit D1 source reuse.
Input: exact field, target range and process count. Output: panel ledgers and CPU/wall times.
CPU means central processing unit. No worker affinity is selected or inferred.
"""
import argparse,json,sys,time,multiprocessing
from concurrent.futures import ProcessPoolExecutor,as_completed
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import ctx
from cached import Sources
from panel import compute
from material import dump

def worker(input_path,output,indices):
  ctx.prec=128;ctx.threads=1
  start=time.perf_counter();cpu=time.process_time();data=json.loads(Path(input_path).read_text());out=Path(output);out.mkdir(parents=True,exist_ok=True)
  cache=Sources(data,192,160,40,1152)
  rejected=False
  try:cache.validate(data,192,161,40,1152)
  except ValueError:rejected=True
  assert rejected
  dump(out/'cache.json',dict(**cache.record(),mismatch_rejected=rejected))
  rows=[]
  for j in indices:
    try:
      rows.append(compute(data,out,j,192,160,52,40,1152,40,False,cache))
    except Exception as error:
      dump(out/'failure.json',dict(panel=j,error=str(error),completed=[v['panel'] for v in rows],
        wall_seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu,cache=cache.record()))
      raise
  result=dict(indices=indices,cache=cache.record(),mismatch_rejected=rejected,flint_threads=ctx.threads,
    panel_seconds=[v['seconds'] for v in rows],panel_total_seconds=[v['total_seconds_with_controls'] for v in rows],
    wall_seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu)
  dump(out/'worker.json',result)
  return result

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--count',type=int,default=8);p.add_argument('--workers',type=int,default=1);a=p.parse_args()
  assert 1<=a.workers<=11
  start=time.perf_counter();out=Path(a.output);rows=[]
  if a.workers==1:rows=[worker(a.input,str(out/'worker-0'),list(range(a.count)))]
  else:
    with ProcessPoolExecutor(max_workers=a.workers,mp_context=multiprocessing.get_context('spawn')) as pool:
      tasks=[pool.submit(worker,a.input,str(out/f'worker-{j}'),list(range(j,a.count,a.workers))) for j in range(a.workers)]
      for f in as_completed(tasks):rows.append(f.result())
  dump(out/'batch.json',dict(workers=a.workers,count=a.count,wall_seconds=time.perf_counter()-start,
    summed_worker_cpu_seconds=sum(v['cpu_seconds'] for v in rows),worker_records=rows))
if __name__=='__main__':main()
