"""Independent scalar audit of finite-state and infinite-tail comparisons.
Input: completed lead summary. Output: intervals and N+10 checks in Arb.
"""
import argparse,json,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,ctx
from material import up,dump
p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--output',required=True);a=p.parse_args();r=json.loads((Path(a.run)/'summary.json').read_text());ctx.prec=192;start=time.perf_counter();cpu=time.process_time();rows=[];intervals=[]
for x in r['states']:
  v=arb(x['V_state']);e=arb(str(x['e_I']));t=arb(str(x['tail_squared']));h=arb.pi()/64
  lo=v.lower().sqrt()-(2*h).sqrt()*e;hi=((v.upper().sqrt()+(2*h).sqrt()*e)**2+t).sqrt();intervals.append((lo,hi));rows.append(dict(N=x['N'],lower=str(lo.lower()),upper=str(hi.upper()),width=up(hi-lo)))
overlap=min(y for x,y in intervals)-max(x for x,y in intervals);assert overlap>0,'N and N+10 residual-norm intervals disjoint'
tail_ratio=(arb(str(r['states'][1]['tail_squared']))/arb(str(r['states'][0]['tail_squared']))).sqrt();r10=arb(str(r['tail']['r']))**10;assert tail_ratio<=r10
material_ratio=arb(str(r['states'][0]['epsilon_upper']))/arb(str(r['full']['baseline']['epsilon_panel_upper']));assert abs(material_ratio-1)<arb('.01')
junction_ratio=arb(str(r['walls'][1]['finite_upper']))/arb(str(r['walls'][0]['finite_upper']));interior_ratio=arb(str(r['interior'][1]['epsilon_upper']))/arb(str(r['interior'][0]['epsilon_upper']));assert abs(junction_ratio-1)<arb('.01') and abs(interior_ratio-1)<arb('.01')
result=dict(material_ratio=str(material_ratio),junction_ratio=str(junction_ratio),interior_ratio=str(interior_ratio),residual_norm_intervals=rows,overlap_lower=str(overlap.lower()),tail_norm_ratio=up(tail_ratio),r_power_10=up(r10),tail_ratio_relative_to_contraction=str(tail_ratio/r10),all_passed=True,seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu);dump(Path(a.output)/'summary.json',result)
