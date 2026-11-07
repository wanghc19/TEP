"""Recompute the published checks from scalar output, independent of the MATLAB pass flags.
Input: run directory and historical root CSV. Output: JSON with the individual check values.
"""
import argparse
import cmath
import csv
import json
import math
from pathlib import Path


def read(p):
  return json.loads(p.read_text())


def arr(x):
  return x if isinstance(x,list) else [x]


def delta(a,b):
  a,b=sorted(a),sorted(b)
  if len(a)!=len(b):
    raise ValueError(f'Candidate count mismatch: {len(a)}, {len(b)}')
  return max((abs(x-y) for x,y in zip(a,b)),default=0)


def physical(a,b):
  cols=('wall_rms','material_L2')
  return all(math.isfinite(a[c]) and math.isfinite(b[c]) and max(a[c],b[c])<.005
             and b[c]<=max(.8*a[c],1e-11) for c in cols)


def check(runs, baselines, out):
  with baselines.open() as f:
    references={r['case']:list(map(float,r['k'].split())) for r in csv.DictReader(f)}
  paired={}
  for f in sorted(runs.glob('*/result.json')):
    r=read(f)
    if 'accepted' in r:paired[r['label']]=f.parent
  assert set(paired)==set(references)
  record=[];pairs=0;regular=[]
  for case,d in paired.items():
    a,b=(read(d/f'fields-{n}.json') for n in (128,192))
    co=sorted(a['fields'],key=lambda v:v['k']);fi=sorted(b['fields'],key=lambda v:v['k'])
    assert len(co)==len(fi)
    selected=[(u,v) for u,v in zip(co,fi) if abs(v['k']-u['k'])<1e-8 and physical(u['field'],v['field'])]
    ak,bk=([pair[i]['k'] for pair in selected] for i in (0,1))
    assert delta(bk,arr(read(d/'result.json')['accepted']))==0
    pairs+=len(ak)
    for n,freq,level in [(128,ak,a),(192,bk,b)]:
      diff=delta(freq,references[case]);gap=delta(freq,arr(level['scan']))
      assert diff<=(2e-14 if case=='reference' and n==128 else 1e-12) and gap<1e-8
      record.append(dict(case=case,N=n,accepted=freq,old_max_difference=diff,dense_max_difference=gap))
      if case not in ('offset','aligned','node'):
        label='old-reference' if case=='reference' and n==128 else f'old-{case}-{n}'
        old_file=next(runs.glob('*/'+label+'/summary.json'),None)
        if old_file:
          old=read(old_file);assert old['status']=='COMPLETE'
          comparator=[v['k'] for v in old['candidates']];source=old_file.parent.parent.name
        else:
          assert n==128, 'Missing fine-grid old comparator'
          comparator=references[case];source='baselines.csv'
        distance=delta(freq,comparator);assert distance<=1e-12
        regular.append(dict(case=case,N=n,source=source,max_difference=distance))
  identity_file=next(runs.glob('*/identity.json'))
  id_data=read(identity_file);K=2*read(identity_file.parent/'plan.json')['M']+1
  errors=[]
  for r in id_data:
    log_ratio=complex(*r['border'])-sum(complex(*r[v]) for v in ('center','dirichlet','DtN'))
    log_ratio+=sum(complex(*r[v]) for v in ('port_transform','overlaps'))
    log_ratio-=1j*math.pi*K
    errors.append(abs(cmath.exp(log_ratio)-1))
  assert len(errors)==5 and max(errors)<1e-10
  controls=read(next(runs.glob('*/control.json')))
  negative={key:physical(controls[0][key],controls[1][key]) for key in ('field','old_field')}
  assert not any(negative.values())
  replay=[read(p)['candidates'][0] for p in sorted(runs.glob('*/pole-*/summary.json'))]
  assert len(replay)==2 and all(abs(r['k']-1.55625025815)<1e-8 and r['ratio']<=1e-11 for r in replay)
  whole=read(next(runs.glob('*/old-pole-192/summary.json')))
  provisional=arr(whole.get('provisional',whole.get('candidates',[])))
  assert any(abs(v['k']-1.55625025815)<1e-8 for v in provisional)
  m=[read(p) for p in runs.glob('*/monitor.json')]
  assert all(v['returncode']==0 and v['reason']=='completed' and v['peak_process_tree_rss_gib']<2 for v in m)
  assert all(read(p)['rss_limit_gib']==2 for p in runs.glob('*/command.json'))
  out.write_text(json.dumps(dict(grid_checks=record,regular_grid_matched=regular,accepted_pairs=pairs,identity_error_scalar_recheck=errors,
    replay=replay,full_window_provisional_count=len(provisional),pole_field_passes=negative,
    monitored_seconds=sum(v['wall_seconds'] for v in m),peak_gib=max(v['peak_process_tree_rss_gib'] for v in m),
    monitor_count=len(m)),indent=2)+'\n')


if __name__=='__main__':
  p=argparse.ArgumentParser(description=__doc__)
  for name in ('runs','baselines','output'):p.add_argument(name,type=Path)
  a=p.parse_args();check(a.runs,a.baselines,a.output)
