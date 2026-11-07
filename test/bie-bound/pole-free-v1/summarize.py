"""Collect scalar comparison tables from explicit run directories and historical reference rows.
Input: run parent, baseline CSV, output directory. Output: per-root CSV, panel CSV and audit JSON.
"""
import argparse
import csv
import json
from pathlib import Path


def load(path):
  return json.loads(path.read_text())


def seq(v):
  return v if isinstance(v,list) else [v]


def write_csv(path, rows):
  if not rows:
    return
  with path.open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(dict.fromkeys(k for row in rows for k in row)))
    w.writeheader()
    w.writerows(rows)


def collect(runs, baselines, dest):
  dest.mkdir(exist_ok=True)
  with baselines.open() as f:
    base={r['case']:r for r in csv.DictReader(f)}
  latest={}
  for f in sorted(runs.glob('*/result.json')):
    result=load(f)
    if 'accepted' in result:latest[result['label']]=f.parent
  roots=[];panels=[];legacy=[];cost=[];counts=[];identity=[];control=[]
  for folder in sorted(runs.glob('run-*')):
    plan=load(folder/'plan.json')
    if (folder/'monitor.json').exists():
      m=load(folder/'monitor.json')
      cost.append(dict(run=folder.name,seconds=m['wall_seconds'],peak_gib=m['peak_process_tree_rss_gib'],
                       observed= m['reason'],exit_code=m['returncode']))
    if isinstance(plan,list):
      for q in plan:
        d=folder/q['label']
        if not (d/'summary.json').exists():
          continue
        r=load(d/'summary.json')
        confirmed=seq(r.get('candidates',[]))
        part=seq(r.get('provisional',[]))
        active=confirmed or part
        legacy.append(dict(run=folder.name,label=q['label'],N=q['N'],M=q['M'],action=q['action'],
                           status=r['status'],message=r.get('message',''),returned_candidate_count=len(confirmed),provisional_count=len(part),
                           k=' '.join(format(v['k'],'.17g') for v in active),
                           ratio=' '.join('%.9g'%v.get('aphys_ratio',v.get('ratio')) for v in active)))
      continue
    if plan['action']=='identity':
      if (folder/'identity.json').exists():identity=load(folder/'identity.json')
      continue
    if plan['action']=='control':
      if (folder/'control.json').exists():control=load(folder/'control.json')
      continue
    case=plan['label']
    if case in latest and latest[case]!=folder:continue
    for n,m in [(128,6),(192,12)]:
      if not (folder/f'fields-{n}.json').exists():continue
      level=load(folder/f'fields-{n}.json');det=load(folder/f'search-{n}.json')
      freq=seq(level['search']);scan=seq(level['scan']);ref=list(map(float,base[case]['k'].split()))
      counts.append(dict(case=case,run=folder.name,N=n,det=len(freq),dense=len(scan),old=len(ref)))
      for j,e in enumerate(level['fields']):
        f=e['field'];roots.append(dict(case=case,run=folder.name,N=n,M=m,k=e['k'],
          border_sigma=e['sigma'],next_sigma=e['next_sigma'],border_max_sigma=e['max_sigma'],
          old_ratio=e['old_ratio'],old_status=e['old_status'],wall=f['wall_rms'],material=f['material_L2'],
          junction=f['junction_rms'],internal=f['internal_row_jump'],seam=f['seam_rms'],
          dense_root=min(scan,key=lambda z:abs(z-e['k'])) if scan else None,
          old_reference=min(ref,key=lambda z:abs(z-e['k'])),
          old_abs_difference=min(abs(v-e['k']) for v in ref)))
      for p in det['panels']:
        last=p['levels'][-1] if p['levels'] else {}
        panels.append(dict(case=case,N=n,depth=p['depth'],lo=p['bounds'][0],hi=p['bounds'][1],
                           localized=p['localized'],overlap_min=p['min_overlap_sigma'],overlap_condition=p['max_overlap_cond'],
                           degree=last.get('degree'),span=last.get('span'),tail=last.get('tail'),offgrid=last.get('offgrid'),
                           node_checks=json.dumps(p['tiny_nodes'],separators=(',',':'))))
  for name,rows in [('roots',roots),('panels',panels),('old-route',legacy),('counts',counts),('cost',cost)]:
    write_csv(dest/(name+'.csv'),rows)
  results=[load(d/'result.json') for d in latest.values()]
  a=dict(cases=len(results),accepted_pairs=sum(len(seq(v['accepted'])) for v in results),
         all_jump_tests=all(v['coverage'] for v in results),grid_comparisons=len(counts),
         all_counts=all(r['det']==r['dense']==r['old'] for r in counts),
         largest_reference_difference=max((r['old_abs_difference'] for r in roots),default=None),
         largest_scan_difference=max((abs(r['k']-r['dense_root']) for r in roots if r['dense_root'] is not None),default=None),
         identity_errors=[r['relative_error'] for r in identity],
         false_pole_control=control,monitored_seconds=sum(r['seconds'] for r in cost),
         peak_gib=max((r['peak_gib'] for r in cost),default=0),runs=len(cost))
  (dest/'audit.json').write_text(json.dumps(a,indent=2)+'\n')
  return a


if __name__=='__main__':
  p=argparse.ArgumentParser(description=__doc__)
  for name in ('runs','baselines','tables'):p.add_argument(name,type=Path)
  args=p.parse_args();collect(args.runs,args.baselines,args.tables)
