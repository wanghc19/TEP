"""Render compact Markdown result tables from the experiment's scalar outputs.
Input: monitored runs, derived tables and historical baseline CSV.
Output: tables.md, suitable for inclusion in the experiment README.
"""
import argparse
import csv
import json
from pathlib import Path


def read(path):
  with path.open() as f:
    return list(csv.DictReader(f))


def num(v):
  return format(float(v),'.3g')


def build(runs,tables,base_path):
  baseline={r['case']:r for r in read(base_path)}
  roots=read(tables/'roots.csv');counts=read(tables/'counts.csv');old=read(tables/'old-route.csv')
  legacy={r['label']:r for r in old};cost={r['run']:r for r in read(tables/'cost.csv')}
  text=['| Case and grid | Old search, k (ratio) | New accepted k | DtN ratio at new k | Four-wall jump | Material jump | Bordered minimum singular value | Dense count |',
        '|---|---|---:|---:|---:|---:|---:|---:|']
  order=['reference','offset','aligned','node','example2','width2','w3-1.67541','w3-0.2','small-star']
  for count in sorted(counts,key=lambda v:(order.index(v['case']),int(v['N']))):
    case=count['case'];n=count['N'];rs=[r for r in roots if r['case']==case and r['N']==n]
    tag={'offset':'pole','aligned':'aligned','node':'node'}.get(case)
    fine_label='old-'+case+'-'+n
    if tag or fine_label in legacy:
      v=legacy.get('old-'+tag+'-'+n) if tag else legacy[fine_label]
      if not v: olddesc='pending'
      else:
        desc={'REFUSED':'refused','OBSERVATION_LIMIT':'timed observation','COMPLETE':'complete'}.get(v['status'],v['status'])
        series=list(zip(v['k'].split(),v['ratio'].split()))
        short=[];seen=[]
        for k,s in series:
          value=float(k)
          if all(abs(value-previous)>2e-12 for previous in seen):
            short.append(f'{value:.17g} ({num(s)})')
            seen.append(value)
        olddesc=desc+(', '+', '.join(short) if short else ', no returned root')
        if v['provisional_count']!='0':olddesc+=' provisional'
    elif case=='reference' and n=='128':
      v=legacy['old-reference'];olddesc=f"complete, {v['k']} ({num(v['ratio'])})"
    else:
      v=baseline[case]
      olddesc=('old fine search unavailable' if n=='192' else 'prior complete, '+', '.join(f'{float(k):.17g} ({num(s)})' for k,s in zip(v['k'].split(),v['ratio'].split())))
    for j,r in enumerate(rs):
      text.append(f"| {case}, {n}/{r['M']} | {olddesc if j==0 else 'same list'} | {float(r['k']):.16f} | {num(r['old_ratio']) if r['old_ratio'] else 'unavailable'} | {num(r['wall'])} | {num(r['material'])} | {num(r['border_sigma'])} | {count['dense']} |")
  text+=['','| Run | Plan | Monitored wall (s) | Peak RSS (GiB) |','|---:|---|---:|---:|']
  for name,r in cost.items():
    q=json.load(open(runs/name/'plan.json'))
    if isinstance(q,list):label=', '.join(a['label'] for a in q)
    else:label=q.get('label',q['action'])
    text.append(f"| {name} | {label} | {float(r['seconds']):.1f} | {float(r['peak_gib']):.3f} |")
  return '\n'.join(text)+'\n'


if __name__=='__main__':
  p=argparse.ArgumentParser(description=__doc__)
  for k in ('runs','tables','baseline','output'):p.add_argument(k,type=Path)
  a=p.parse_args();a.output.write_text(build(a.runs,a.tables,a.baseline))
