"""Floating series CSV (comma-separated values) from explicit continuation runs.
Input: series JSON paths and output CSV; edge1.441 is a floating locator.
Output: root, singular values, lead norms and baseline1.46 distance.
"""
import argparse,csv,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--inputs',nargs='+',required=True);p.add_argument('--output',required=True);a=p.parse_args();rows=[]
for f in a.inputs:
 for r in json.loads(Path(f).read_text())['rows']:
  assert r['passed'];x=dict(L0=r['L0'],k=r['k'],sigma_min=r['sigma_min'],sigma_second=r['sigma_second'],distance_to_floating_lower_edge=r['k']-1.441,distance_to_baseline_k146=r['k']-1.46)
  for side,key in [('left','negative'),('right','positive')]:
   x.update({side+'_radius':r[key]['spectral_radius'],side+'_norm2':r[key]['norm2'],side+'_p':r[key]['p'],side+'_r':r[key]['r']})
  rows.append(x)
with Path(a.output).open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
