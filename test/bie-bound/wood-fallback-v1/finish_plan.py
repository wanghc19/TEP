"""Choose one affordable remaining pair of width tests from explicit measured parents.
Input: prepared plans and numbered monitored output root. Output: reviewable plan and forecast.
"""
import argparse,json
from pathlib import Path

def load(p):return json.loads(p.read_text())
p=argparse.ArgumentParser(description=__doc__)
for key in ('plans','runs'):p.add_argument('--'+key,type=Path,required=True)
p.add_argument('--number',type=int,required=True)
a=p.parse_args();out=a.runs.resolve();P=a.plans
used=sum(load(f)['wall_seconds'] for f in out.glob('run-*/monitor.json'))
seen={}
for run in sorted(out.glob('run-*')):
  if not (run/'monitor.json').exists():raise ValueError('A run is still active')
  for f in sorted(list(run.glob('search-*.json'))+list(run.glob('nested-*.json'))+list(run.glob('strip-*.json'))):
    r=load(f)
    if r['control'] or r['tag'].startswith('scan'):continue
    key=(r['model'],r['beta'],r['N'],r['route'],r['delta'])
    seen[key]=(str(f.relative_to(out)),r)
avail=[]
singles=[]
for i in range(1,13):
  base=load(P/f'nested-{i:02d}.json')['jobs']
  for method,d in [('sqrt',1e-4),('sqrt',1e-5),('plain',1e-4)]:
    jobs=[];cost=14;nominal_missing=False
    for q in base:
      k=(q['model'],q['beta'],q['N'],method,d)
      if k in seen:continue
      old={1e-4:.001,1e-5:.0001}[d]
      parent=seen.get((*k[:4],old))
      if not parent:nominal_missing=True;break
      path,r=parent
      row_cost=0
      if r.get('total_complete',r['complete']):
        row_cost=max(0,150-r.get('total_seconds',r['seconds']))+12
      cost+=row_cost
      job=dict(q,route=method,delta=d,parent_file=path)
      jobs.append(job)
      if 14+row_cost<5393-used:
        singles.append((row_cost,14+row_cost,i,method,d,[job]))
    if jobs and not nominal_missing and cost<min(1785,5393-used):
      # Prefer paired widths that fit; favor square-root results when costs are similar.
      avail.append((cost/len(jobs) * (0.87 if method == 'sqrt' else 1),cost,i,method,d,jobs))
if not avail and singles:
  avail=singles
if not avail:
  print(f'No new width test forecast to fit {5400-used:.1f} s.')
else:
  _,forecast,i,method,d,jobs=min(avail,key=lambda x:x[:5])
  name=f'finish-{a.number:03d}';plan=P/(name+'.json')
  plan.write_text(json.dumps(dict(action='strips',handoff_root=str(out),jobs=jobs),indent=2)+'\n')
  (P/(name+'-series.json')).write_text(json.dumps([dict(run=a.number,plan=name,forecast=round(forecast,3))],indent=2)+'\n')
  print(f'{name}: phase {i}, {method}, delta {d:g}, {len(jobs)} new rows; forecast <= {forecast:.1f} s and 1.4 GiB; {5400-used:.1f} s remain.')
