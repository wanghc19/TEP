"""Compare endpoint linear sensitivities with finite changes of the same size.
Input: nominal E/M/S and the estimated errors. Output: high-precision diagnostic.
"""
from pathlib import Path
from itertools import product
import json
from flint import arb,ctx
ctx.prec=256;here=Path(__file__).resolve().parent;repo=here.parents[2];read=lambda p:json.loads(Path(p).read_text());r=read(here/'output/estimates.json');q=r['extras']['qj'];d=read(repo/'test/numerical-directions/qj-cert-v2/output/run-004/science/interface-certificate.json');s=arb(q['s']);mu=arb(float(1.32**2+1));nu=arb(float(2.37**2+1));errors=[q['roundE'],q['roundM'],q['roundS']]
def endpoints(e,m,S):
  qq=1+e/m;delta=qq*S/m-(qq-s)**2/s**2;F=lambda t:qq-1+qq*t*delta/(qq-t-t*delta);sq=(delta+delta**2/4).sqrt();return [F(nu),F(mu),qq*(1+delta/2-sq)-1,qq*(1+delta/2+sq)-1]
nom=[[],[],[],[]];pert=[[],[],[],[]]
for e,m in product(d['full_interval']['E'],d['M']):
  for k,v in enumerate(endpoints(arb(e),arb(m),arb(q['S']))):nom[k].append(v)
  for signs in product([-1,1],repeat=3):
    inp=[arb(v)+sg*arb(er) for v,sg,er in zip([e,m,q['S']],signs,errors)]
    for k,v in enumerate(endpoints(*inp)):pert[k].append(v)
res={}
for i,key in enumerate(['L','U','I1L','I1U']):
  choose=min if i%2==0 else max;shift=abs(float((choose(pert[i])-choose(nom[i])).mid()));linear_total=r['extras']['endpoints'][key]['estimated_shift'];val=r['extras']['endpoints'][key]['value_float'];linear=linear_total-(100*2**-53/(1-100*2**-53))*abs(val);res[key]={'finite_shift':shift,'linear_input_sensitivity':linear,'linear_with_final_evaluation':linear_total,'relative_difference':abs(shift/linear-1),'within_one_per_mille':abs(shift/linear-1)<.001}
(here/'output/finite-sensitivity.json').write_text(json.dumps(res,indent=2)+'\n');print(json.dumps(res,indent=2))
