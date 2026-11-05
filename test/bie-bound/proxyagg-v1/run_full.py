"""Complete global proxy aggregation and two-panel reliable checks.
Input: exact field path, output directory and explicit expansion settings.
Output: setup, coefficient balls, two panels, reduced-order check and timing.
"""
import argparse,json,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,ctx
from material import Proxy,dump,up
from domains import certify
from aggregation import Aggregation
from real_panels import SelfCache,compute

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True)
  p.add_argument('--physical-degree',dest='M',type=int,default=576);p.add_argument('--source-degree',dest='n',type=int,default=72);p.add_argument('--source-panels',dest='S',type=int,default=160);p.add_argument('--real-node-count',dest='L',type=int,default=48);p.add_argument('--basis-order',dest='J',type=int,default=14);p.add_argument('--bits',type=int,default=128);a=p.parse_args()
  out=Path(a.output);data=json.loads(Path(a.input).read_text());ctx.prec=a.bits;ctx.cap=max(73,a.n+1);ctx.threads=1;start=time.perf_counter();cpu=time.process_time()
  (out/'part.txt').write_text('domains');t=time.perf_counter();K=Proxy(data);domain=certify(K,data,a.S,arb('.41'),arb('.055'));domain_time=time.perf_counter()-t;dump(out/'domains.json',domain['record'])
  (out/'part.txt').write_text('source-aggregation');A=Aggregation(data,domain,a.M,a.n,a.S,arb('.055'),a.S,out,a.bits)
  (out/'part.txt').write_text('self-cache');cache=SelfCache(data,K);rows=[]
  for idx in [0,1]:
    (out/'part.txt').write_text(f'panel-{idx}');r=compute(A,data,cache,idx,out,a.M,a.L,a.J);rows.append(r)
    print('PANEL',idx,'eproxy',r['e_proxy'],'eI',r['e_I'],'online',r['online_nonself_seconds'],flush=True)
  (out/'part.txt').write_text('lower-order-panel');low=compute(A,data,cache,0,out,544,a.L,a.J,False)
  highphys,_,_=A.tails(a.M);lowphys,_,_=A.tails(544);pred=(domain['a']/domain['R'])**(544-a.M)
  ratio=lowphys/highphys;assert abs(ratio/pred-1)<arb('1e-20')
  result=dict(domains_seconds=domain_time,aggregation_seconds=A.seconds,setup_seconds=domain_time+A.seconds+cache.seconds,self_cache_seconds=cache.seconds,panels=[{k:r[k] for k in ['panel','M','e_I','e_proxy','V','online_nonself_seconds','production_seconds','seconds','cpu_seconds','times']} for r in rows],reduced_order=dict(M=544,n=a.n,physical_tail_ratio=up(ratio),predicted_ratio=up(pred),e_I=low['e_I'],e_proxy=low['e_proxy'],source_tail=low['source_tail']),seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu)
  dump(out/'summary.json',result);(out/'part.txt').write_text('complete')
if __name__=='__main__':main()
