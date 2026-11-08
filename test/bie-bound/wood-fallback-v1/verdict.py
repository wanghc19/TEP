"""Print the measured comparison counts and empirical frequency-error envelope."""
import argparse,csv,math
from collections import Counter
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--tables',required=True,type=Path);a=p.parse_args()
def read(name):
  with (a.tables/name).open() as f:return list(csv.DictReader(f))
rows=read('planned-grid.csv'); roots=read('roots.csv'); s=read('branch.csv');refs=read('local-references.csv')
for route,delta in [('plain',.01),('plain',.001),('plain',.0001),('sqrt',.001),('sqrt',.0001),('sqrt',.00001)]:
  g=[r for r in rows if r['route']==route and float(r['delta'])==delta]
  print(route,delta,dict(Counter(r['status'] for r in g)))
print('branch:',dict(Counter(r['status'] for r in s)),'complete',sum(r['complete']=='True' for r in s),'extra',sum(bool(r['off_branch_anywhere']) for r in s))
for typ in ['ex1','w3']:
  v=[(abs(float(r['signed_reference_difference'])*float(r['signed_t'])),r['tag']) for r in roots if r['model']==typ and r['reference_k']]
  v += [(abs(float(r['signed_root_difference'])*float(r['reference_t'])),r['tag']) for r in refs if r['model']==typ]
  print(typ,'max t*err',max(v),'rounded coefficient',math.ceil(max(v)[0]/1e-14)*1e-14)
scan=[r for r in roots if r['tag'].startswith('scan') and r['reference_k']]
if scan:
  for key in ['grid_difference','signed_reference_difference','green_prediction']:
    v=[abs(float(r[key])) for r in scan];print('branch',key,min(v),max(v))
  print('grid underestimates',sum(abs(float(r['signed_reference_difference']))>float(r['grid_difference']) for r in scan),'of',len(scan))
print('Missing references',[(r['tag'],r['k192']) for r in roots if not r['reference_k']])
