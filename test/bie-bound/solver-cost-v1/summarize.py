"""Summarize window-only solver costs from explicit cold run records.
Input: experiment output parent. Output: configuration and candidate CSVs and tier JSON.
CSV means comma-separated values. JSON means JavaScript Object Notation.
"""
import argparse
import csv
from decimal import Decimal
import json
from pathlib import Path
import struct

LOW = Decimal('1.5584378941776960')
HIGH = Decimal('1.5584378941864800')

def read(path):
  return json.loads(path.read_text())

def write_csv(path, rows):
  if rows:
    fields = list(dict.fromkeys(key for row in rows for key in row))
    with path.open('w') as file:
      writer = csv.DictWriter(file,fields)
      writer.writeheader()
      writer.writerows(rows)

def error_to_reference(k):
  value = Decimal.from_float(k)
  if value < LOW:
    return 'below', LOW-value
  if value > HIGH:
    return 'above', value-HIGH
  return 'inside', Decimal(0)

def collect(parent):
  rows, candidates, incomplete = [], [], []
  total = 0.
  for folder in sorted(parent.glob('run-*')):
    if not (folder/'monitor.json').exists():
      continue
    monitor=read(folder/'monitor.json')
    cfg=read(folder/'config.json')
    total+=monitor['wall_seconds']
    idle=not read(folder/'preflight.json')['numerical_jobs']
    if monitor['returncode'] or monitor['reason']!='completed':
      entry=dict(run=folder.name,**cfg,reason=monitor['reason'],returncode=monitor['returncode'],
        wall=monitor['wall_seconds'],rss=monitor['peak_process_tree_rss_gib'],idle=idle)
      entry['provisional']=[]
      for state in sorted(folder.glob('fallback-*/state.json')):
        f=read(state);entry['search_status']=f['status'];entry['fallback_counts']=f['counters']
        for c in f['candidates']:
          k=c['k'];side,distance=error_to_reference(k)
          entry['provisional'].append(dict(k=k,side=side,distance=str(distance),
            ratio=c['aphys_ratio'],width=c['W'],status=c['status'],reason=c['stop_reason']))
          candidates.append(dict(run=folder.name,index=len(entry['provisional']),k=repr(k),
            hex=struct.pack('>d',k).hex(),side=side,distance=str(distance),ratio=c['aphys_ratio'],status=c['status']))
      incomplete.append(entry)
      continue
    result=read(folder/'result.json')
    score=[]
    for j,c in enumerate(result['candidates']):
      k=struct.unpack('>d',bytes.fromhex(c['k_hex']))[0]
      assert c['k']==k
      side,distance=error_to_reference(k)
      ratio=c['aphys_ratio'] if cfg['solver']=='bie' else c['ratio']
      candidates.append(dict(run=folder.name,index=j+1,k=repr(k),hex=c['k_hex'],side=side,distance=str(distance),ratio=ratio,status=result['status']))
      score.append(distance)
    science=result['science_seconds']
    row=dict(run=folder.name,solver=cfg['solver'],size=cfg['size'],order=cfg['order'],
      wall=monitor['wall_seconds'],rss=monitor['peak_process_tree_rss_gib'],science=science,
      outside_science=monitor['wall_seconds']-science,gap=0,count=len(score),status=result['status'],
      idle=idle,threads=cfg['threads'],score=str(score[0]) if len(score)==1 else None,
      k=candidates[-1]['k'] if len(score)==1 else None,side=candidates[-1]['side'] if len(score)==1 else None)
    if cfg['solver']=='bie':
      t=result['timing'];e=result['counts'];env=result['environment']
      row.update(window_stage=t['determinant'],polish=t['polish'],confirmation=t['confirmation'],
        fallback=t['fallback'],window_evals=e['determinant'],root_evals=e['polish'],confirmation_evals=e['confirmation'],
        fallback_evals=e['fallback'],matching=2*(2*cfg['order']+1),other_science=science-sum(t.values()))
      row['environment_ok']=env['threads']==11 and env['OMP_NUM_THREADS']=='11' and env['OMP_DYNAMIC']=='FALSE' and 'R2023b' in env['version']
      assert t['gap']==0 and t['validation']==0
    else:
      row.update(window_stage=result['p2_seconds'],window_evals=len(result['p2_solves']),
        ritz_per_shift=result['p2_solves'][0]['requested'],p2_free=result['p2_dof'])
      row['environment_ok']=result['threads']==11 and result['omp']=='11' and result['omp_dynamic']=='FALSE' and 'R2023b' in result['version']
      for field,source in [('mesh','mesh_space'),('assembly','location_assembly'),('root','root'),('confirmation','confirmation')]:
        row[field]=sum(c['timing'][source] for c in result['candidates'])
      row['other_science']=science-sum(row[f] for f in ['window_stage','mesh','assembly','root','confirmation'])
      row['root_evals']=sum(c['root_evaluations'] for c in result['candidates'])
      row['confirmation_evals']=sum(c['fresh_evaluations'] for c in result['candidates'])
      if result['candidates']:
        c=result['candidates'][0];row.update(matching=c['matching_size'],free_dofs=c['free_dof'])
    assert idle and row['environment_ok'] and row['rss']<3
    rows.append(row)
  return rows,candidates,incomplete,total

def ranking(rows):
  tiers={}
  for tier in ('1e-6','1e-8','1e-10','inside','1e-11'):
    tol=Decimal(0) if tier=='inside' else Decimal(tier)
    pair={}
    for solver in ('bie','fem'):
      eligible=[r for r in rows if r['solver']==solver and r['status']=='COMPLETE' and r['count']==1 and Decimal(r['score'])<=tol]
      if eligible:
        best=min(eligible,key=lambda r:r['wall']);pair[solver]={k:best[k] for k in ('run','size','order','wall','rss')}
    if len(pair)==2:pair['ratio']=pair['bie']['wall']/pair['fem']['wall']
    tiers[tier]=pair
  return tiers

def monotonicity(rows):
  checks=[]
  for solver in ('bie','fem'):
    subset=[r for r in rows if r['solver']==solver and r['count']==1 and r['status']=='COMPLETE']
    for axis,fixed in [('size','order'),('order','size')]:
      for value in sorted({r[fixed] for r in subset}):
        group=sorted([r for r in subset if r[fixed]==value],key=lambda r:r[axis])
        if len(group)<2:continue
        increases=[[a['run'],b['run'],a['score'],b['score']] for a,b in zip(group,group[1:]) if Decimal(a['score'])<Decimal(b['score'])]
        checks.append(dict(solver=solver,fixed=fixed,value=value,refined=axis,runs=[r['run'] for r in group],increases=increases))
  return checks

def dominance_exceptions(rows):
  exceptions=[]
  for coarse in rows:
    for fine in rows:
      if coarse['solver']!=fine['solver'] or None in (coarse['score'],fine['score']):
        continue
      if (coarse['size'],coarse['order'])==(fine['size'],fine['order']):
        continue
      if coarse['size']<=fine['size'] and coarse['order']<=fine['order']:
        if Decimal(fine['score'])>Decimal(coarse['score']):
          exceptions.append([coarse['run'],fine['run'],coarse['score'],fine['score']])
  return exceptions

def tables(rows,tiers):
  """Format the raw configurations and the independently rankable tier data."""
  def name(r,solver):
    if solver=='fem':return f"P{r['order']} g{r['size']}"
    return f"{r['size']}/{r['size']//2}/{r['size']//2} M{r['order']}"
  accuracy=['| Distance in $k$ | Cheapest BIE, s / GiB | Cheapest FEM, s / GiB | BIE/FEM cold time |',
            '|---|---|---|---:|']
  for key in ('1e-6','1e-8','1e-10','inside'):
    t=tiers[key]
    entries=[]
    for solver in ('bie','fem'):
      r=t.get(solver)
      entries.append(f"{name(r,solver)}, {r['wall']:.2f} / {r['rss']:.3f}" if r else 'No eligible measurement')
    ratio=f"{t['ratio']:.2f}" if 'ratio' in t else '—'
    accuracy.append(f"| {key} | {entries[0]} | {entries[1]} | {ratio} |")
  bie=['| Run | N / M | Matching dimension | Candidate $k$ | Reference distance | Gap s | Det / polish / confirm (s) | Calls | Cold s | Peak GiB |',
       '|---|---|---:|---:|---|---:|---|---|---:|---:|']
  fem=['| Run | Degree / grid | Local free DOFs, L / core / R | Candidate $k$ | Reference distance | Gap s | P2 / setup / root / confirm (s) | Root + fresh calls | Cold s | Peak GiB |',
       '|---|---|---|---:|---|---:|---|---|---:|---:|']
  for r in sorted(rows,key=lambda row:(row['solver'],row['size'],row['order'])):
    distance='inside' if r['side']=='inside' else f"{r['side']} {Decimal(r['score']):.4e}"
    if r['solver']=='bie':
      line=f"| {r['run'][4:]} | {r['size']} / {r['order']} | {r['matching']} | {r['k']} | {distance} | {r['gap']} | {r['window_stage']:.2f} / {r['polish']:.2f} / {r['confirmation']:.2f} | {r['window_evals']}+{r['root_evals']}+{r['confirmation_evals']} | {r['wall']:.2f} | {r['rss']:.3f} |"
      bie.append(line)
    else:
      dofs='/'.join(str(d) for d in r['free_dofs'])
      line=f"| {r['run'][4:]} | P{r['order']} g{r['size']} | {dofs} | {r['k']} | {distance} | {r['gap']} | {r['window_stage']:.2f} / {r['mesh']+r['assembly']:.2f} / {r['root']:.2f} / {r['confirmation']:.2f} | {r['root_evals']}+{r['confirmation_evals']} | {r['wall']:.2f} | {r['rss']:.3f} |"
      fem.append(line)
  return ('\n'.join(accuracy),'\n'.join(bie),'\n'.join(fem))

if __name__=='__main__':
  parser=argparse.ArgumentParser();parser.add_argument('--output',type=Path,required=True)
  parser.add_argument('--tables',action='store_true',help='Print the Markdown result tables')
  args=parser.parse_args();folder=args.output;rows,candidates,failures,seconds=collect(folder)
  write_csv(folder/'configurations.csv',rows);write_csv(folder/'candidates.csv',candidates)
  report=dict(reference=[str(LOW),str(HIGH)],tiers=ranking(rows),monotonicity=monotonicity(rows),
    dominance_exceptions=dominance_exceptions(rows),completed=len(rows),incomplete=failures,total_monitored_seconds=seconds)
  (folder/'tiers.json').write_text(json.dumps(report,indent=2)+'\n')
  if args.tables:print('\n\n'.join(tables(rows,report['tiers'])))
  else:print(json.dumps(report['tiers']))
