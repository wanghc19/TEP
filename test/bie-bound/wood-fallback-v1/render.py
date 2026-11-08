"""Render measured tables into the experiment README from the scalar CSV results."""
import argparse,csv,json
from collections import Counter,defaultdict
from pathlib import Path

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--tables',type=Path,required=True);p.add_argument('--readme',type=Path,required=True)
a=p.parse_args()
def read(name):
  path=a.tables/(name+'.csv')
  if not path.exists():return []
  with path.open() as f:return list(csv.DictReader(f))
def fmt(x,n=3):
  return f'{float(x):.{n}g}' if x not in (None,'') else '—'
def span(rs,key,places=1):
  v=[float(r[key]) for r in rs if r[key]!=''];f=lambda x:f'{x:.{places}f}'
  return f(min(v)) if min(v)==max(v) else f(min(v))+'–'+f(max(v))
def table(head,rows):
  return '\n'.join(['| '+' | '.join(head)+' |','|'+'|'.join(['---']*len(head))+'|']+['| '+' | '.join(map(str,row))+' |' for row in rows])
s=read('searches');rr=read('roots');refs=read('local-references');scan=read('branch');cost=read('cost');planned=read('planned-grid')
lines=['## Measurements','']
lines+=['The [search ledger](results/searches.csv) gives each grid, every frequency proposal and paired return, the closest cell evaluation, and the new and cumulative counts. The [coverage ledger](results/planned-grid.csv) names all 144 requested width/grid/phase combinations and their records. An inherited incomplete outer panel is listed separately from a fresh timeout. The [expected-mode ledger](results/expected-modes.csv) locates the independent reference relative to the exclusion, including cases at the band boundary.','']
group=defaultdict(list)
for row in s:
  if row['protocol']=='control':continue
  typ='branch scan' if row['tag'].startswith('scan') else row['protocol']
  group[(typ,row['route'],float(row['delta']))].append(row)
vals=[]
for (typ,route,d),g in sorted(group.items(),key=lambda v:(v[0][0],v[0][1],-v[0][2])):
  attempted=[r for r in g if r['status']!='outer_incomplete']
  if not attempted:continue
  vals.append([typ,route,f'{d:g}',sum(r['complete']=='True' for r in g),sum(r['status']=='timed_out' for r in g),sum(r['status']=='unresolved' for r in g),
    len(g)-len(attempted),span(attempted,'total_panels',0),span(attempted,'total_evaluations',0),
    span(attempted,'new_search_seconds'),span(attempted,'total_search_seconds')])
lines += [table(['Protocol','Variable','$\\delta$','Complete','Timed out','Depth limit','Outer incomplete','Total panels','Total determinant calls','New s','Cumulative s'],vals),'']
lines+=['### Returned-root accuracy','',
 'Each row shows one completed, physically paired search at the stated phase, preferring the smallest completed exclusion. An empty return has its independently seeded local root shift in the last column. The [root table](results/roots.csv) gives the three error quantities for every paired return, including roots retained when a later strip timed out. [All physical proposals](results/proposals.csv) and [local reference shifts](results/local-references.csv) are separate records.','']
vals=[]
for ref in refs:
  if ref['tag'].startswith('scan'):continue
  choices=[r for r in rr if r['model']==ref['model'] and r['beta']==ref['beta'] and r['reference_tag']==ref['tag'] and r['complete_both']=='True']
  z=min(choices,key=lambda row:(float(row['delta']),row['route']!='sqrt')) if choices else {}
  vals.append([ref['model']+(' (second)' if ref['tag']=='w3-secondary' else ''),fmt(ref['detuning']),z.get('route','—')+' '+(fmt(z.get('delta')) if z else ''),
    z.get('k192','—'),fmt(z.get('grid_difference')),fmt(z.get('signed_reference_difference')),
    fmt(ref['green_prediction']),fmt(ref['signed_root_difference'])])
lines += [table(['Model','Signed nominal $t$','Search and $\\delta$','Fine returned $k$','Two-grid difference','Fine minus reference','Predicted scale','Local fine minus reference'],vals),'']
lines+=['### Branch scan','',
 'The expected detuning is a leave-one-out interpolation of the nearest four neighboring observed branch locations (the independent local references at larger detunings supply outer anchors). The search never uses this prediction. The [branch table](results/branch.csv) includes the interpolation phases and any off-branch return within twice the exclusion radius.',''] if scan else ['### Branch scan','','TODO.','']
if scan:
  branch_rows=[]
  for item in sorted(scan,key=lambda z:float(z['beta'])):
    v=next((r for r in rr if r['tag'].startswith('scan') and r['beta']==item['beta']),{})
    branch_rows.append([item['beta'],fmt(item['expected'],6),item['roots'] or '—',
      fmt(v.get('grid_difference')),fmt(v.get('signed_reference_difference')),fmt(v.get('green_prediction')),
      item['complete'],item['status'],item['extra_within_2delta'] or '—'])
  lines += [table(['$\\beta$','Interpolated $k_*-k_W$','Returned $k$','Grid difference','Fine minus reference',
    'Predicted scale','Both complete','Branch verdict','Additional near-edge roots'],branch_rows),'']
rates=read('rates')
lines += ['### Rate fits and cost','',table(['Quantity','Model','Side','Phases','Detuning range','$\\log$–$\\log$ slope','RMS log residual'],
 [[r['quantity'],r['model'],r['sign'],r['n'],fmt(r['min_t'])+'–'+fmt(r['max_t']),fmt(r['power']),fmt(r['rms_log'])] for r in rates]),'',
 'Fits use absolute fine-grid differences from the changed-Green reference. The two W3 distances determine a two-point slope. For the returned-root fit each phase contributes once, using complete searches whose reported root clears the exclusion boundary by more than the measured error. The raw root table flags boundary cases.','']
summary=json.loads((a.tables/'summary.json').read_text())
counts=Counter(r['status'] for r in planned)
lines+=[f"Measured {len(cost)} monitored runs, {summary['monitored_seconds']:.1f} s total and {summary['peak_gib']:.3f} GiB maximum process-tree RSS. The [monitor ledger](results/cost.csv) lists every run. Requested ladder rows: "+', '.join(f'{v} {k}' for k,v in sorted(counts.items()))+'.','']
start='<!-- measured tables -->';end='<!-- end measured tables -->'
doc=a.readme.read_text()
if start in doc:doc=doc[:doc.index(start)]+doc[doc.index(end)+len(end):].lstrip('\n')
where=doc.index('## Forecasts and boundaries');doc=doc[:where]+start+'\n'+'\n'.join(lines)+end+'\n\n'+doc[where:]
a.readme.write_text(doc)
