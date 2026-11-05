"""Summarize determinant scans: LU is lower-upper factorization; DtN is Dirichlet-to-Neumann.
Input: one or more explicit current-run directories. Output: compact CSV tables.
"""
import argparse,csv,json,statistics
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('runs',nargs='+');a=p.parse_args()
for item in a.runs:
  run=Path(item);r=json.loads((run/'result.json').read_text());rows=[];roots=[];coeff=[]
  for panel in r['panels']:
    for level in panel['levels']:
      row={'panel':panel['label'],'degree':level['degree'],'used_degree':level['used_degree'],'tail':level['tail'],'offgrid_absolute_scaled_max':max(x[3] for x in level['offgrid']),'offgrid_relative_max':max(x[4] for x in level['offgrid']),'evaluations_so_far':level['evaluations_so_far']}
      rr=level['roots']
      if rr and isinstance(rr[0],(int,float)):rr=[rr]
      near=[x for x in rr if abs(x[1])<1e-6]
      row['near_real_count']=len(near)
      if near: row['nearest_real_error']=min(abs(x[0]-r['reference_k']) for x in near)
      rows.append(row)
      for j,x in enumerate(rr):roots.append(dict(panel=panel['label'],degree=level['degree'],real=x[0],imag=x[1],rho=level['root_rho'][j] if isinstance(level['root_rho'],list) else level['root_rho']))
      for j,x in enumerate(level['coefficient_relative']):coeff.append(dict(panel=panel['label'],degree=level['degree'],index=j,relative=x))
  for name,data in [('levels.csv',rows),('roots.csv',roots),('coefficients.csv',coeff)]:
    if data:
      fields=list(dict.fromkeys(k for x in data for k in x));f=(run/name).open('w');w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(data);f.close()
  pts=r['points'];times=[x['seconds'] for x in pts]
  print(item,'evaluations',r['evaluations'],'science',r['seconds'],'mean_eval',statistics.mean(times),'median_eval',statistics.median(times),'rconds',r['minimum_positive_rcond'],r['minimum_negative_rcond'])
  for row in rows:print(row)
  print('polished',r['polished']);print('determinant checks',r['checks'])
