"""Reproduce existing domain bounds with copied arithmetic before new certificates.
Input: explicit exact field. Output: two domain-bound scalar records.
"""
import argparse,json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from material import Proxy,matrix,dump,up
from self_interaction import Radial,self_domain
from flint import arb,ctx
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);a=p.parse_args()
d=json.loads(Path(a.input).read_text());K=Proxy(d);c=d['pieces'][0];Ct=matrix(c['tau_coeff']);Cz=matrix(c['zeta_coeff']);modes=c['modes'];ctx.prec=192
rows=[]
for j in range(2):
 # Target centers were constructed at 128 bits in the original panel path.
 ctx.prec=128;h=arb.pi()/192;ct=(2*j+1)*h;rt=arb('.04');strip=arb('.0625');ctx.prec=192
 HA,HB,r=self_domain(K.k,K.R,K.b,ct,rt,strip,Ct,Cz,modes,Radial(K.k));rows.append(r)
dump(Path(a.output)/'reproduction.json',rows)
