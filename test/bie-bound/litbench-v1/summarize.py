"""Summarize literature benchmark refinements from explicit numbered run records.
Input: experiment output directory. Output: scalar results CSV and summary JSON.
"""
import argparse
import csv
import json
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('--output',required=True,type=Path)
a=parser.parse_args()
rows=[]
cost=0
for directory in sorted(a.output.glob('run-*')):
  path=directory/'monitor.json'
  if not path.exists():continue
  monitor=json.loads(path.read_text())
  cost+=monitor['wall_seconds']
  data=directory/'benchmark.json'
  if not data.exists():continue
  r=json.loads(data.read_text())
  for c in r['candidates']:
    rows.append(dict(run=directory.name,mode=r['mode'],nodes=r['nodes'],M=r['M'],
      beta=r['beta'],k=c['k'],frequency=c['normalized_frequency'],count=len(r['candidates']),
      sigma_ratio=c['ratio'],distance_left=c['unit_distance'][0],distance_right=c['unit_distance'][1],
      qualified_all=all(x['left']==x['right']=='GAP' for x in r['gap_samples']),
      status=r['status'],wall=monitor['wall_seconds'],peak_gib=monitor['peak_process_tree_rss_gib']))
with (a.output/'results.csv').open('w') as f:
  writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
summary={'total_wall_seconds':cost,'modes':{}}
for mode in ['fundamental','second']:
  sub=[r for r in rows if r['mode']==mode]
  if not sub:continue
  vals=[r['frequency'] for r in sub]
  common=0
  for digits in range(1,18):
    if len({format(v,f'.{digits}g') for v in vals})!=1:break
    common=digits
  summary['modes'][mode]={'runs':len(sub),'min':min(vals),'max':max(vals),
    'spread':max(vals)-min(vals),'same_rounded_significant_digits':common,'finest':sub[-1]}
(a.output/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
