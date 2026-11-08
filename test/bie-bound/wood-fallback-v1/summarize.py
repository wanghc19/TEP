"""Summarize guarded searches, two-grid physical decisions and independent references.
Input: explicit output tree and table directory. Output: scalar CSV and check summary.
"""
import argparse
import csv
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

def arr(x):
  return x if isinstance(x,list) else [x]

def scalar(x):
  return arr(x)[0] if arr(x) else None

def write(path,rows):
  if not rows:return
  with path.open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)

def gate(a,b):
  ca=[a['field'][v] for v in ('wall_rms','material_L2')]
  fi=[b['field'][v] for v in ('wall_rms','material_L2')]
  return max(ca+fi)<.005 and all(y<=max(.8*x,1e-11) for x,y in zip(ca,fi))

def distinct_fields(fs):
  # Use the same frequency tolerance as the within-panel proposal merger.
  final=[]
  for f in sorted(fs,key=lambda v:v['k']):
    if not final or abs(f['k']-final[-1]['k'])>2e-12:final.append(f)
  return final

def freq(v):
  return ' '.join(format(x,'.17g') for x in v)

def fit(xs,ys):
  pts=[(math.log(x),math.log(y)) for x,y in zip(xs,ys) if x>0 and y>0]
  if len(pts)<2:return {}
  x,y=zip(*pts);mx=statistics.mean(x);my=statistics.mean(y)
  slope=sum((i-mx)*(j-my) for i,j in pts)/sum((i-mx)**2 for i in x)
  return dict(n=len(x),min_t=math.exp(min(x)),max_t=math.exp(max(x)),power=slope,
              rms_log=math.sqrt(statistics.mean((j-my-slope*(i-mx))**2 for i,j in pts)))

def interp(b,pts):
  scale=max(abs(x-b) for x,y in pts); xs=[(x-b)/scale for x,y in pts]
  return sum(y*math.prod(-xs[j]/(xs[i]-xs[j]) for j in range(len(xs)) if i!=j) for i,(x,y) in enumerate(pts))

p=argparse.ArgumentParser(description=__doc__)
for name in ('runs','tables','scan','plans'):
  p.add_argument('--'+name,type=Path,required=True)
a=p.parse_args();a.tables.mkdir(exist_ok=True)
raw=[];refs={};mon=[];bad=[];detail=[];field_times={}
for run in sorted(a.runs.glob('run-*')):
  for file in sorted(run.glob('accuracy-*.json')):
    r=json.loads(file.read_text());refs[(r['model'],r['beta'],r['tag'])]=r
  f=run/'monitor.json'
  if f.exists():mon.append(dict(run=run.name,**{k:json.loads(f.read_text())[k] for k in ('wall_seconds','peak_process_tree_rss_gib','reason','returncode')}))
  for f in sorted([*run.glob('search-*.json'),*run.glob('nested-*.json'),*run.glob('strip-*.json')]):
    r=json.loads(f.read_text());nested='total_fields' in r
    r['method']='nested' if nested else ('control' if r['control'] else 'independent')
    r['file']=f'{run.name}/{f.name}'
    if not nested:
      for k in ('complete','fields','seconds','panels','evaluations','closest_k','closest_distance'):
        r['total_'+k]=r[k]
    else:
      for oldfile in r.get('reused_files',[]):
        assert (run/oldfile).exists()
    parentfield=0
    if r.get('reused_files'):parentfield=field_times[run.name+'/'+r['reused_files'][-1]]
    if r.get('parent_file'):
      key=r['parent_file']
      parentfield=field_times[run.name+'/'+key[5:] if key.startswith('this/') else key]
    own=r.get('field_seconds',0 if not r['fields'] else None)
    field_times[r['file']]=None if own is None or parentfield is None else parentfield+own
    r['total_check_seconds']=field_times[r['file']]
    vals=arr(r['frequencies'])
    for k in vals+[v['k'] for v in r['fields']]:
      # Account for every port order that could meet these positive windows.
      d=min(abs(k-abs(r['beta']+m*2*math.pi)) for m in range(-3,4))
      if d<r['delta']:bad.append((r['file'],k,d))
    if vals:
      assert abs(min(abs(k-r['beta']) for k in vals)-r['closest_distance'])<1e-15
    for x in r['panel_log']:
      detail.append(dict(file=r['file'],depth=x['depth'],lower=x['bounds'][0],upper=x['bounds'][1],degree=x['degree'],
                         tail=scalar(x['tail']),offgrid=scalar(x['offgrid']),passed=x['localized'],chart_ok=x['chart_ok']))
    r['merged_proposals']=len(r['total_fields'])-len(distinct_fields(r['total_fields']))
    r['total_fields']=distinct_fields(r['total_fields'])
    choices=[f['k'] for f in r['total_fields']]
    if scalar(r['total_closest_k']) is not None:choices.append(scalar(r['total_closest_k']))
    if choices:
      kmin=min(choices,key=lambda k:abs(k-r['beta']))
      r['closest_checked_k']=kmin;r['closest_checked_t']=abs(kmin-r['beta'])
    else:r['closest_checked_k']=None;r['closest_checked_t']=None
    raw.append(r)
key=lambda r:(r['model'],r['beta'],r['route'],r['delta'],r['method'])
by=defaultdict(dict)
for r in raw:
  by[key(r)][r['N']]=r
accept={};rootrows=[];comp=[];proposals=[];coverage=[]
for k,levels in by.items():
  co=levels.get(128);fi=levels.get(192);returned=[[],[]]
  if co and fi:
    for x in co['total_fields']:
      match=[y for y in fi['total_fields'] if abs(x['k']-y['k'])<1e-8]
      if len(match)!=1 or not gate(x,match[0]):continue
      y=match[0]
      if any(abs(y['k']-v)<2e-12 for v in returned[1]):continue
      returned[0].append(x['k']);returned[1].append(y['k'])
      ref=next((v for (m,b,_),v in refs.items() if (m,b)==k[:2] and abs(v['reference_k']-y['k'])<1e-6),{})
      kr=ref.get('reference_k');err=None if kr is None else y['k']-kr
      rootrows.append(dict(model=k[0],beta=k[1],tag=fi['tag'],reference_tag=ref.get('tag'),route=k[2],delta=k[3],protocol=k[4],
        complete_both=bool(co['total_complete'] and fi['total_complete']),k128=x['k'],k192=y['k'],
        signed_t=y['k']-k[1],grid_difference=abs(y['k']-x['k']),reference_k=kr,
        signed_reference_difference=err,coarse_reference_difference=None if kr is None else x['k']-kr,
        green_prediction=ref.get('predicted_root_shift_scale'),
        boundary_distance=abs(y['k']-k[1])-k[3],
        boundary_within_error=abs(abs(y['k']-k[1])-k[3])<=max(2e-12,abs(err or 0),abs(y['k']-x['k'])),
        coarse_wall=x['field']['wall_rms'],
        coarse_material=x['field']['material_L2'],fine_wall=y['field']['wall_rms'],fine_material=y['field']['material_L2']))
  for n,r in levels.items():
    paired=bool(co and fi);accepted=returned[0 if n==128 else 1];accept[r['file']]=accepted
    comp.append(dict(file=r['file'],model=k[0],tag=r['tag'],beta=k[1],N=n,M=r['M'],protocol=k[4],route=k[2],
      delta=k[3],detuning=r['detuning'],status=r['status'],complete=r['total_complete'],paired=paired,
      new_panels=r['panels'],total_panels=r['total_panels'],new_evaluations=r['evaluations'],total_evaluations=r['total_evaluations'],
      new_search_seconds=r['seconds'],total_search_seconds=r['total_seconds'],new_checks_seconds=r.get('field_seconds'),total_checks_seconds=r['total_check_seconds'],
      wall_with_checks_seconds=None if r['total_check_seconds'] is None else r['total_seconds']+r['total_check_seconds'],
      closest_k=r['closest_checked_k'],closest_t=r['closest_checked_t'],
      merged_duplicates=r['merged_proposals'],proposals=freq(x['k'] for x in r['total_fields']),accepted=freq(accepted)))
  if not (co and fi):
    for side in levels.values():
      for v in side['total_fields']:
        proposals.append(dict(file=side['file'],k=v['k'],N=side['N'],matches=None,physical_pass=None,
          wall_rms=v['field']['wall_rms'],material_L2=v['field']['material_L2']))
  if co and fi:
    roots=returned[1]
    for side,other in ((co,fi),(fi,co)):
      for v in side['total_fields']:
        matches=[x for x in other['total_fields'] if abs(x['k']-v['k'])<1e-8]
        ok=len(matches)==1 and (gate(v,matches[0]) if side['N']==128 else gate(matches[0],v))
        proposals.append(dict(file=side['file'],k=v['k'],N=side['N'],matches=len(matches),
          physical_pass=ok,wall_rms=v['field']['wall_rms'],material_L2=v['field']['material_L2']))
    ref=next((v['reference_k'] for (m,b,tag),v in refs.items() if (m,b)==k[:2] and tag!='w3-secondary'),None)
    branch_roots=[v for v in roots if ref is not None and abs(v-ref)<1e-6]
    if ref is not None:
      win=fi.get('original_window',fi['window']);t=abs(ref-k[1])
      if not(win[0]<=ref<=win[1]):decision='tracked mode outside requested window'
      elif t<k[3]:decision='missed in unsearched band' if not branch_roots else 'reference inside band; proposal at edge'
      elif branch_roots:decision='returned on searched set'
      elif co['total_complete'] and fi['total_complete']:decision='no accepted proposal outside band'
      else:decision='unresolved on searched set'
      coverage.append(dict(model=k[0],beta=k[1],delta=k[3],route=k[2],protocol=k[4],
        reference_t=t,distance_from_exclusion=t-k[3],accepted=freq(roots),decision=decision))
write(a.tables/'proposals.csv',proposals);write(a.tables/'expected-modes.csv',coverage)
write(a.tables/'searches.csv',comp);write(a.tables/'panels.csv',detail);write(a.tables/'roots.csv',rootrows);write(a.tables/'cost.csv',mon)

local=[]
for (m,b,tag),v in refs.items():
  local.append(dict(tag=v['tag'],model=m,beta=b,detuning=v['detuning'],k_default=v['original_local_k'],
    k_reference=v['reference_k'],reference_t=v['actual_t'],signed_root_difference=v['original_local_k']-v['reference_k'],
    original_green_error=v['green_background_error'],reference_green_error=v['green_reference_error'],
    sensitivity_real=v['root_sensitivity'][0],sensitivity_imag=v['root_sensitivity'][1],green_prediction=v['predicted_root_shift_scale']))
write(a.tables/'local-references.csv',local)
fits=[]
for model in ('ex1','w3'):
  for sign in (-1,1):
    rs=[r for r in local if r['model']==model and r['detuning']*sign>0 and not r['tag'].startswith('scan') and r['tag']!='w3-secondary']
    if len(rs)>1:fits.append(dict(quantity='local reference shift',model=model,sign=sign,**fit([r['reference_t'] for r in rs],[abs(r['signed_root_difference']) for r in rs])))
# One median signed bias per phase keeps frequently repeated width settings from weighting the fit.
for model in ('ex1','w3'):
  for sign in (-1,1):
    group=defaultdict(list)
    for row in rootrows:
      if (row['model']==model and row['reference_tag']!='w3-secondary' and row['signed_t']*sign>0
          and row['reference_k'] is not None and row['complete_both'] and not row['boundary_within_error']):
        group[row['beta']].append(row)
    if len(group)>=2:
      tt=[abs(g[0]['reference_k']-b) for b,g in group.items()]
      ee=[abs(statistics.median(z['signed_reference_difference'] for z in g)) for g in group.values()]
      ff=fit(tt,ee)
      if ff:fits.append(dict(quantity='interior returned root reference shift',model=model,sign=sign,**ff))
write(a.tables/'rates.csv',fits)

# Classify unseen branch frequencies from accepted neighboring detunings only.
scan=[];targets=json.loads(a.scan.read_text())['jobs']
for q in targets:
  picks=[r for r in comp if r['N']==192 and r['beta']==q['beta'] and r['route']=='sqrt' and r['delta']==.0001]
  if not picks:continue
  r=picks[-1]
  klist=[float(v) for v in r['accepted'].split()]
  scan.append(dict(beta=q['beta'],target=q['detuning'],file=r['file'],complete=r['complete'] and r['paired'] and
    any(p['N']==128 and p['beta']==r['beta'] and p['protocol']==r['protocol'] and p['complete'] and p['route']=='sqrt' and p['delta']==.0001 for p in comp),
    roots=klist,expected=None,linear_expected=None,interpolation_spread=None,interpolator='',status='',off_branch_anywhere=[],extra_within_2delta=[]))
known=sorted((s['beta'],s['roots'][0]-s['beta']) for s in scan if len(s['roots'])==1)
anchors=sorted((b,r['reference_k']-b) for (m,b,tag),r in refs.items() if m=='ex1' and abs(r['detuning']) in (.001,.01))
for s in scan:
  b=s['beta'];pts=[p for p in known if p[0]!=b]
  for x in anchors:
    if all(x[0]!=v[0] for v in pts):pts.append(x)
  below=[v for v in pts if v[0]<b];above=[v for v in pts if v[0]>b]
  if below and above:s['linear_expected']=interp(b,[max(below),min(above)])
  pts=sorted(sorted(pts,key=lambda p:abs(p[0]-b))[:4])
  if len(pts)>=2:
    expected=interp(b,pts)
    s['expected']=expected;s['interpolation_spread']=abs(s['linear_expected']-expected) if s['linear_expected'] is not None else None;s['interpolator']=freq(x for x,y in pts)
    near=[v for v in s['roots'] if abs(v-b-expected)<=1e-7]
    s['off_branch_anywhere']=[v for v in s['roots'] if v not in near]
    s['extra_within_2delta']=[v for v in s['off_branch_anywhere'] if max(0,abs(v-b)-.0001)<=.0002]
    if near:s['status']='on branch'
    elif abs(expected)<.0001:s['status']='missed in excluded band'
    elif s['complete']:s['status']='missed outside band'
    else:s['status']='unresolved outside band'
  s['roots']=freq(s['roots']);s['off_branch_anywhere']=freq(s['off_branch_anywhere']);s['extra_within_2delta']=freq(s['extra_within_2delta'])
write(a.tables/'branch.csv',scan)
planned=[]
for f in sorted(a.plans.glob('ladder-*.json')):
  for j in json.loads(f.read_text())['jobs']:
    found=[r for r in comp if r['beta']==j['beta'] and r['N']==j['N'] and r['route']==j['route']
      and r['delta']==j['delta'] and r['protocol']!='control']
    normal=[r for r in found if r['status']!='outer_incomplete']
    status='TODO' if not found else ('complete' if any(r['complete'] for r in found) else
      'timed_out' if any(r['status']=='timed_out' for r in found) else found[0]['status'])
    planned.append(dict(model=j['model'],beta=j['beta'],detuning=j['detuning'],route=j['route'],delta=j['delta'],
      N=j['N'],M=j['M'],status=status,fresh_search=bool(normal),records=' '.join(r['file'] for r in found)))
write(a.tables/'planned-grid.csv',planned)
summary=dict(guard_violations=bad,number_searches=len(comp),branch_phases=len(scan),peak_gib=max([x['peak_process_tree_rss_gib'] for x in mon],default=0),
  monitored_seconds=sum(x['wall_seconds'] for x in mon))
(a.tables/'summary.json').write_text(json.dumps(summary,indent=2)+'\n');assert not bad
