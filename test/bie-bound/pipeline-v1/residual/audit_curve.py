# Copied from test/bie-bound/grouprel-v1/audit_curve.py; pipeline adaptations documented in README.
"""Independent decimal-outward RE16 aggregation and two Gauss checks.
Input: explicit completed queue directory. Output: scalar curve certificate.
"""
import argparse,json,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,acb_poly,ctx
from material import up,dump
p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--output',required=True);a=p.parse_args();root=Path(a.run);out=Path(a.output);ctx.prec=192;start=time.perf_counter();cpu=time.process_time();r=json.loads((root/'summary.json').read_text());assert r['valid'] and r['count']==192
bound=arb(0);rows=[];checks=[];coverage=[]
for task in r['tasks']:
  for leaf in task['leaves']:
    idx=leaf['panel'];d=leaf['depth'];s=leaf['sub'];h=arb.pi()/(192*2**d);v=arb(leaf['V']);error=sum((arb(str(leaf[k])) for k in ['e_self','local_tail','e_smooth','combination_error']),arb(0));eps=v.upper().sqrt()+(2*h).sqrt()*error;bound+=eps**2;coverage.append((idx+s/2**d,idx+(s+1)/2**d));rows.append(dict(panel=idx,depth=d,sub=s,e_I=up(error),epsilon_upper=up(eps),L=leaf['self']['L'],Rt=leaf['self']['Rt'],flag=leaf['self_flag']))
    if idx in [0,1] and d==0:
      raw=json.loads((root/f'B-panel-{idx}-d0-s0-M52.json').read_text());polys=[acb_poly([acb(arb(z[0]),arb(z[1])) for z in col]) for col in raw['polynomial']];D=max(len(x) for x in raw['polynomial']);g=h*sum((w*sum((abs(f(x))**2 for f in polys),arb(0)) for x,w in [arb.legendre_p_root(D,j,True) for j in range(D)]),arb(0));rel=abs(g-v)/v.lower();assert rel<arb('1e-12');checks.append(dict(panel=idx,V=str(v),Gauss=str(g),relative=up(rel)))
coverage.sort();assert coverage[0][0]==0 and coverage[-1][1]==192 and all(x[1]==y[0] for x,y in zip(coverage,coverage[1:]));eps=bound.sqrt();result=dict(epsilon_upper=up(eps),ratio=up(eps/arb('1.2610675455e-12')),coverage_complete=True,panels=rows,Gauss=checks,seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu,interpretation='decimal outward fields re-added in Arb; whole central B curve only');dump(out/'summary.json',result)
