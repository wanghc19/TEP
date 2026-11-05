"""Whole central cell-kernel curve with a shared dynamic process queue.
Input: exact field/fit paths, target range and worker count.
Output: leaf polynomials, reliable RE16 sum, checks and worker costs.
"""
import argparse,json,sys,time,os,resource,multiprocessing,traceback
from concurrent.futures import ProcessPoolExecutor,as_completed
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,ctx
from material import Proxy,matrix,I,up,dump
from expansion import Sources,Expansion
from real_panels import SelfCache
from chebyshev import coefficients,SelfDomainFailure
from panel import incident
from central_pilot import central
DATA=K=CACHE=NEAR=PROXY=OUT=None
START=CPU=None;DONE=[]
def initialize():
  global START,CPU,DONE
  START=time.perf_counter();CPU=time.process_time();DONE=[];ctx.threads=1;ctx.prec=128

def task(idx):
  start=time.perf_counter();cpu=time.process_time();leaves=[];splits=[];failed=[]
  def part(depth,sub):
    try:
      # Preserve the copied serial path: the first parameter ball was made
      # at 128 bits, subsequent ones after its 192-bit conversion.
      ctx.prec=128 if idx==0 and depth==0 else 192;ht=arb.pi()/(192*2**depth);ct=(idx+(sub+.5)/2**depth)*2*arb.pi()/192
      t=time.perf_counter();cf,e,_,rec=coefficients(K,ct,ht,52,CACHE.Ct,CACHE.Cz,CACHE.modes,arb('.04'),arb('.0625'),1152,40,CACHE);selftime=time.perf_counter()-t
      ctx.prec=192;t=time.perf_counter();loc,M=incident(DATA,ct,ht,52,arb('.04'),K,CACHE.Ct,CACHE.Cz,CACHE.modes);tail=M*(ht/arb('.04'))**53/(1-ht/arb('.04'));localtime=time.perf_counter()-t
      r=central(DATA,K,CACHE,NEAR,PROXY,idx,'B',OUT,(cf,e,rec),(loc,tail),52,False,depth,sub)
      r.pop('polynomial');r.update(self_seconds=selftime,local_seconds=localtime,self_flag=e>arb('1e-16'))
      if idx<2 and depth==0:
        expected=[2.4032764279321695e-18,3.312527089399887e-18][idx];r['baseline_exact']=r['e_I']==expected;assert r['baseline_exact'],'Central reproduction failed'
      leaves.append(r)
    except SelfDomainFailure as err:
      splits.append(dict(depth=depth,sub=sub,error=str(err)))
      if depth<2:part(depth+1,2*sub);part(depth+1,2*sub+1)
      else:failed.append(str(err))
    except Exception as err:failed.append(dict(error=str(err),traceback=traceback.format_exc()))
  part(0,0);DONE.append(idx)
  row=dict(panel=idx,pid=os.getpid(),leaves=leaves,splits=splits,failed=failed,wall_seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu)
  dump(OUT/f'task-{idx}.json',row);dump(OUT/f'worker-{os.getpid()}.json',dict(pid=os.getpid(),done=DONE,wall_seconds=time.perf_counter()-START,cpu_seconds=time.process_time()-CPU,peak_rss_gib=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/2**30))
  print(json.dumps(dict(panel=idx,valid=not failed,seconds=row['wall_seconds'])),flush=True);return row

def main():
  global DATA,K,CACHE,NEAR,PROXY,OUT
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--output',required=True);p.add_argument('--count',type=int,default=192);p.add_argument('--workers',type=int,default=8);a=p.parse_args()
  assert 1<=a.workers<=11 and 1<=a.count<=192
  OUT=Path(a.output);DATA=json.loads(Path(a.input).read_text());fits=json.loads(Path(a.coefficients).read_text());ctx.prec=128;ctx.cap=81;ctx.threads=1
  start=time.perf_counter();cpu=time.process_time();load=os.getloadavg();K=Proxy(DATA);(OUT/'part.txt').write_text('shared-setup');src=Sources(K,DATA['pieces'][0]);phase=(I*matrix(DATA['beta'])[0,0]*matrix(DATA['d'])[0,0]).exp()
  NEAR=Expansion(K,[(arb(0),arb(m),phase**m) for m in [-1,1]],arb('.6'),128,src);Z=matrix(fits['Z']);charges=[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())];PROXY=Expansion(K,charges,arb('1.1'),144,coefficients=matrix(fits['B_center']));CACHE=SelfCache(DATA,K)
  setup=dict(seconds=time.perf_counter()-start,source_seconds=src.seconds,source_times=src.times,near=NEAR.record,proxy=PROXY.record,self_cache_seconds=CACHE.seconds,policy='single parent computation; read-only fork sharing')
  dump(OUT/'setup.json',setup);(OUT/'part.txt').write_text('target-queue');rows=[];qstart=time.perf_counter()
  with ProcessPoolExecutor(max_workers=a.workers,mp_context=multiprocessing.get_context('fork'),initializer=initialize) as pool:
    futures=[pool.submit(task,i) for i in range(a.count)]
    for f in as_completed(futures):
      r=f.result();rows.append(r)
      if r['failed']:
        for ff in futures:ff.cancel()
        break
  qseconds=time.perf_counter()-qstart;ctx.prec=192;valid=len(rows)==a.count and all(not r['failed'] for r in rows)
  result=dict(setup=setup,queue_seconds=qseconds,workers=a.workers,count=a.count,load_before=load,load_after=os.getloadavg(),valid=valid,tasks=rows)
  if valid:
    eps2=arb(0);intervals=[]
    for r in rows:
      for leaf in r['leaves']:
        d=leaf['depth'];s=leaf['sub'];idx=leaf['panel'];intervals.append((idx+s/2**d,idx+(s+1)/2**d))
        # Every leaf upper is outward in JSON; exact binary64 import pays it again.
        eps2+=arb(str(leaf['epsilon_panel_upper']))**2
    intervals.sort();assert intervals[0][0]==0 and intervals[-1][1]==a.count and all(x[1]==y[0] for x,y in zip(intervals,intervals[1:]))
    eps=eps2.sqrt();result.update(epsilon_upper=up(eps),ratio_to_floating=up(eps/arb('1.2610675455e-12')),coverage=intervals)
  usage=resource.getrusage(resource.RUSAGE_CHILDREN);result.update(wall_seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu+usage.ru_utime+usage.ru_stime)
  dump(OUT/'summary.json',result);assert valid,'Incomplete target coverage'
if __name__=='__main__':main()
