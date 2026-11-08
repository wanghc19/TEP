"""Audit frequencies, cumulative panel accounting, resource limits and regression checks."""
import argparse
import csv
import json
import math
from pathlib import Path

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--runs',type=Path,required=True);p.add_argument('--tables',type=Path,required=True)
a=p.parse_args()
def read(path):return json.loads(path.read_text())
def records(name):
  with (a.tables/name).open() as f:return list(csv.DictReader(f))
def intervals(x):
  if not x:return []
  return [tuple(y[:2]) for y in (x if isinstance(x[0],list) else [x])]
def merge(parts):
  out=[]
  for left,right in sorted(parts):
    if out and left<=out[-1][1]+4*math.ulp(left):out[-1]=(out[-1][0],max(out[-1][1],right))
    else:out.append((left,right))
  return out
leaves={};max_endpoint_defect=0;checked_windows=0
nsearch=nfield=0;mingap=math.inf;max_time_defect=0;partials=0
for row in records('searches.csv'):
  root=a.runs/row['file'];v=read(root)
  fs=v['frequencies'] if isinstance(v['frequencies'],list) else [v['frequencies']]
  ks=[*fs,*[f['k'] for f in v['fields']]]
  nsearch+=len(fs);nfield+=len(ks)-len(fs)
  for k in ks:
    dist=min(abs(k-abs(v['beta']+2*math.pi*m)) for m in range(-6,7))
    assert dist>=v['delta'];mingap=min(mingap,dist-v['delta'])
  segments=intervals(v['finished_intervals'])
  if 'total_panels' in v:
    parent=None;parent_path=None
    if v.get('reused_files'):
      parent_path=root.parent/v['reused_files'][-1];parent=read(parent_path)
    elif v.get('parent_file'):
      key=v['parent_file']
      parent_path=root.parent/key[5:] if key.startswith('this/') else a.runs/key;parent=read(parent_path)
    sec=0;pn=ev=0
    if parent is not None:
      segments+=leaves[str(parent_path)]
      sec=parent.get('total_seconds',parent['seconds']);pn=parent.get('total_panels',parent['panels'])
      ev=parent.get('total_evaluations',parent['evaluations'])
      assert parent['beta']==v['beta'] and parent['N']==v['N'] and parent['M']==v['M'] and parent['delta']>v['delta']
    assert pn+v['panels']==v['total_panels'] and ev+v['evaluations']==v['total_evaluations']
    max_time_defect=max(max_time_defect,abs(sec+v['seconds']-v['total_seconds']))
    partials+=int(v['status']=='outer_incomplete')
  leaves[str(root)]=segments
  if v.get('total_complete',v['complete']):
    l,h=v.get('original_window',v['window']);d=v['delta'];w=v['beta']
    # The only order meeting these particular windows is m=0.
    assert all(abs(v['beta']+m*2*math.pi)+d<l or abs(v['beta']+m*2*math.pi)-d>h for m in [-3,-2,-1,1,2,3])
    expected=[v for v in ((l,min(h,w-d)),(max(l,w+d),h)) if v[0]<v[1]]
    got=merge(segments);assert len(got)==len(expected),(row['file'],got,expected)
    max_endpoint_defect=max([max_endpoint_defect]+[abs(a-b) for s,t in zip(got,expected) for a,b in zip(s,t)])
    checked_windows+=1
assert max_endpoint_defect<5e-15
check=read(a.runs/'run-003/check.json')
k=check['search']['proposals'];target=1.558437894182088;assert abs(k-target)<=2e-14
reg=read(a.runs/'run-001/regression.json')['proposals'];assert abs(reg-target)<=2e-14
regular=[x for x in records('searches.csv') if x['protocol']=='control']
diffs=[]
for x in regular:
  if x['route']=='plain':
    y=next(z for z in regular if z['tag']==x['tag'] and z['N']==x['N'] and z['route']=='sqrt')
    diffs.append(abs(float(x['accepted'])-float(y['accepted'])))
assert len(diffs)==4 and max(diffs)<=1e-13
cost=records('cost.csv');time=sum(float(x['wall_seconds']) for x in cost);peak=max(float(x['peak_process_tree_rss_gib']) for x in cost)
assert max_time_defect<=1e-9 and peak<=2 and time<=5400
ans=dict(regular_regression_k=k,original_regression_k=reg,reference_k=target,away_route_differences=diffs,
 determinant_cell_calls_checked=nsearch,field_calls_checked=nfield,minimum_clearance_beyond_declared_delta=mingap,
 maximum_cumulative_time_defect_seconds=max_time_defect,completed_window_unions_checked=checked_windows,maximum_endpoint_defect=max_endpoint_defect,inherited_incomplete_rows=partials,total_monitored_seconds=time,peak_gib=peak)
(a.tables/'checks.json').write_text(json.dumps(ans,indent=2)+'\n')
