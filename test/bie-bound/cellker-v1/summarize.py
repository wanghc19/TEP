"""Summarize the cell-bounded kernel's floating budget.
Input: explicit kernel-pilot and budget run directories.
Output: scalar summary.json and groups.csv in the budget run.
"""
import argparse,csv,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--pilot',required=True);p.add_argument('--budget',required=True);a=p.parse_args()
b=Path(a.budget);r=json.loads((b/'result.json').read_text());k=json.loads((Path(a.pilot)/'kernel.json').read_text())
assert r['status']=='COMPLETE'
old,new=r['old'],r['new'];rows=[]
for j,name in enumerate(new['names']):
 rows.append(dict(group=name,C=new['C'][j],old_epsilon=old['epsilon'][j],new_epsilon=new['epsilon'][j],old_contribution=old['Cepsilon'][j],new_contribution=new['Cepsilon'][j],epsilon_ratio=new['epsilon'][j]/old['epsilon'][j]))
with (b/'groups.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
switch=4.848522979818595e-11
qold=old['Q']+switch
summary=dict(old_groups_Q=old['Q'],old_groups_reference_difference=r['old_Q_relative'],new_Q=new['Q'],new_width=new['width'],old_Q_with_switch=qold,old_width_same_U=4*new['mu']*qold/(new['U']-qold),width_ratio_to_4p1e_minus10=new['width']/4.1e-10,source_refinement_relative=r['new_Q_source_change'],dominant_group=max(rows,key=lambda z:z['new_contribution'])['group'],groups=rows,seconds=r['seconds'],timings={n:v for n,v in r.items() if n.endswith('_seconds')},new_level_seconds=[v['seconds'] for v in r['new_levels']])
summary['monitor']=json.loads((b/'monitor.json').read_text())
(b/'summary.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary,indent=2))
