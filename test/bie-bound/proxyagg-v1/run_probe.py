"""Run the copied baseline and a small source-aggregation timing pilot.
Input: exact field path and output directory. Output: baseline and pilot ledgers.
"""
import argparse,json,sys,time,gc
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,ctx
from material import Proxy,dump
from cached import Sources
from panel import compute
from domains import certify
from aggregation import Aggregation

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--sources',type=int,default=4);a=p.parse_args()
  out=Path(a.output);data=json.loads(Path(a.input).read_text());ctx.threads=1;ctx.prec=128;ctx.cap=64
  cache=Sources(data,192,160,40,1152);dump(out/'baseline-cache.json',cache.record());old=[]
  for i,ref in enumerate([2.015114157818781e-15,2.582298610633771e-15]):
    r=compute(data,out,i,192,160,52,40,1152,40,False,cache);old.append(dict(panel=i,e_upper=r['e_upper'],reference=ref,exact=r['e_upper']==ref))
    dump(out/'baseline.json',old);assert r['e_upper']==ref,'Copied baseline e_I differs'
  del cache;gc.collect();ctx.prec=128;ctx.cap=73;K=Proxy(data)
  t=time.perf_counter();domain=certify(K,data,160,arb('.41'),arb('.055'));domain['record']['seconds']=time.perf_counter()-t;dump(out/'domains.json',domain['record'])
  A=Aggregation(data,domain,576,72,160,arb('.055'),a.sources,out)
  dump(out/'pilot.json',dict(sources=a.sources,source_setup_seconds=A.seconds,forecast_160_seconds=A.seconds*160/a.sources,domains=domain['record']))
if __name__=='__main__':main()
