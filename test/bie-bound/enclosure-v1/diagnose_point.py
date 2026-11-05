"""Locate the diagnostic's radial-domain failure without changing a bound.
Input: exact field and output. Output: first invalid squared distance.
"""
import sys,json,argparse
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,ctx
from material import Proxy,matrix,geom
from lead_self import source,kernel
from self_interaction import Radial
p=argparse.ArgumentParser();p.add_argument('--input');p.add_argument('--output');a=p.parse_args();ctx.prec=192
d=json.loads(Path(a.input).read_text());K=Proxy(d);pars=matrix(d['curve_parameters']);K.R=(pars[0,7].real,);K.b=pars[0,6].real;piece=d['pieces'][2];W=matrix(piece['G'])*matrix(piece['c']);T=matrix(piece['tau_coeff'])*W;Z=matrix(piece['zeta_coeff'])*W
grid,V=source(K,T,Z,piece['modes'],1152);rad=Radial(K.k,arb(17));t=arb(0);x,y,_,_=geom(t,K.R,K.b)
records=[]
for j,(s,u,v,mx,my) in enumerate(grid):
 q=(x-u)*(x-u)+(y-v)*(y-v)
 if not abs(q)<2:records.append(dict(j=j,s=str(s),x=str(x),y=str(y),u=str(u),v=str(v),q=str(q)))
print('bad q',records[:3]);print('kernel');v=kernel(t,K,rad,grid)*V;print(v)
(Path(a.output)/'diagnosis.json').write_text(json.dumps(records,indent=2))
