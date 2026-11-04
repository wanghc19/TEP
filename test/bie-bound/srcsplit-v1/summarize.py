"""Summarize source-split wall outputs without new field computation.
Input: an explicit completed run directory.
Output: table.csv and summary.json with raw squares, budgets and convergence.
"""
import argparse,csv,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('run',type=Path);a=p.parse_args()
r=json.loads((a.run/'result.json').read_text());m=json.loads((a.run/'monitor.json').read_text())
assert r['status']=='COMPLETE' and m['returncode']==0
rows=r['rows'];cols=['rule','source_nodes','targets','backend','left_normal','right_normal','junction_value','inner_normal','inner_value','wall_total','seconds']
with (a.run/'table.csv').open('w') as f:
  w=csv.DictWriter(f,fieldnames=cols,extrasaction='ignore');w.writeheader();w.writerows(rows)
s={'monitor':m,'baseline':r['baseline'],'breakpoints':r['breakpoints'],'budget':r['finest_split_budget'],'fmm_direct':r.get('fmm_direct',{}),'convergence':[]}
for nt in [768,1536]:
  z=[x for x in rows if x['rule']=='split' and x['targets']==nt]
  for x,y in zip(z,z[1:]):
    s['convergence'].append({'targets':nt,'source_from':x['source_nodes'],'source_to':y['source_nodes'],**{k:y[k]/x[k]-1 for k in ['left_normal','right_normal','junction_value','inner_normal','wall_total']}})
(a.run/'summary.json').write_text(json.dumps(s,indent=2)+'\n')
print(json.dumps(s,indent=2))
