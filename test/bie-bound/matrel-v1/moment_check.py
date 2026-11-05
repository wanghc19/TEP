"""Check scaled source moments against an independently enclosed analytic value.
Input: explicit output directory and common field path. Output: moment-check.json.
"""
import sys,argparse
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from material import dump
from panel import moment_basis
from flint import arb,ctx
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--input',required=True);a=p.parse_args()
h=arb.pi()/128;F=moment_basis([0],h,40);rows=[]
for j in range(41):
  coarse=2*h/(j+1) if j%2==0 else arb(0)
  ctx.prec=384
  reference=2*arb.pi()/(128*(j+1)) if j%2==0 else arb(0)
  ctx.prec=128
  rows.append(dict(j=j,ball=str(F[0,j]),same_precision_reference=str(coarse),old_contains=F[0,j].contains(coarse),overlaps=F[0,j].overlaps(coarse),high_precision_reference=str(reference),certifies_value=F[0,j].contains(reference)))
dump(Path(a.output)/'moment-check.json',rows)
assert all(v['certifies_value'] for v in rows),'Independent high precision moment not enclosed'
