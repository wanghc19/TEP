"""Resolution-study scalar CSV/JSON tables. CSV is comma-separated values.
Input: completed run paths; optional baseline comparison is postprocessing only.
Output: per-group reliable inputs, ordinary polynomial estimates, timing/checks.
"""
import argparse,csv,gzip,json,math,struct
from pathlib import Path
from decimal import Decimal,localcontext

def load(p):
  if p.exists():return json.loads(p.read_text())
  with gzip.open(str(p)+'.gz','rt') as f:return json.load(f)
def mid(s):return float(str(s).strip('[]').split(' +/-')[0])
def estimates(s):
  tails={(x['kind'],x['side']):x['N'] for x in s['groups']['tails']};v=[0.]*5
  def rows(r):return r.get('leaves',[r])
  for r in s['tasks']:
    kind=r['kind'];side=r.get('side',0)
    if kind=='center':v[0]+=sum(mid(x['V']) for x in r['center']['leaves'])
    elif kind=='references':continue
    else:
      slot=side if kind=='material' else 4 if kind=='seam' else 3
      n=1 if kind=='junction' or (kind=='seam' and side==0) else tails[(kind,side)]
      v[slot]+=sum(sum(mid(x) for x in l['V_columns'][:n]) for l in rows(r))
  return [math.sqrt(x) for x in v]
def summarize(run):
  r=load(run/'result.json');assert r['status']=='COMPLETE';g=load(run/'03-residuals/groups.json');s=load(run/'03-residuals/summary.json');a=load(run/'06-enclosure/result.json');u=load(run/'05-mass/disks.json');audit=load(run/'04-residual-audit/summary.json');end=load(run/'end-to-end.json');settings=r.get('settings',dict(center_nodes=512,lead_nodes=256,rayleigh_M=48,panels=1,chebyshev=48,precision=128,field_source=None));x=a['assemblies'][0]
  for b in a['assemblies']:
    assert b['epsilon_decimal_readback']==[str(z) for z in g['epsilon_upper']] and b['U_certificate_readback']==u['U_lower']
    assert b['R_upper']==b['exact_rational_R_upper']==x['R_upper']
  assert audit['all_passed'];assert abs(r['worker_seconds']-sum(z['driver_seconds'] for z in r['stages'])-r['source_preparation_seconds']-r['orchestration_seconds'])<1e-7
  if settings['field_source']:
    source=Path(settings['field_source']).resolve();ledger=load(run/'scientific-inputs.json')
    for key in ['fixed-input.json','coefficients.json']:
      matches=[Path(z['path']).resolve() for z in ledger if Path(z['path']).name==key]
      assert matches and all(z==source/'02-field'/key for z in matches)
    original=load(source/'candidate.json');assert r['candidate']['k_hex']==original['k_hex']
  ff=estimates(s)
  return dict(run=run.name,settings=settings,k=r['candidate']['k_decimal'],k_hex=r['candidate']['k_hex'],eps=x['epsilon_decimal_readback'],C=['2.490254','1.181583','1.233941','1.035553','1.035553'],weighted=x['terms_upper'],Q=x['Q_upper'],U=x['U_used'],mass_certificate=x['U_certificate_readback'],width=x['width_upper'],mu_interval=x['mu_interval'],k_interval=x['k_interval'],floating_finite=ff,evaluation_fraction=[float(e)/f-1 for e,f in zip(x['epsilon_decimal_readback'],ff)],tails=[{k:v for k,v in z.items() if k!='choices'} for z in g['tails']],wall_seconds=end['wall_seconds'],rss_gib=end['monitor']['peak_process_tree_rss_gib'],stages=[dict(stage=z['stage'],seconds=z['driver_seconds']) for z in r['stages']],audit=audit,checks=dict(directed_readback=True,exact_rational=True,timing=True,band_reused=bool(settings['field_source'])),model_errors=[l['e_I'] for t in s['tasks'] if t['kind']=='center' for l in t['center']['leaves']])
def main():
  p=argparse.ArgumentParser();p.add_argument('--runs',nargs='+',required=True);p.add_argument('--output',required=True);p.add_argument('--baseline');a=p.parse_args();out=Path(a.output);out.mkdir(exist_ok=True);rows=[summarize(Path(r)) for r in a.runs]
  if a.baseline:
    old=load(Path(a.baseline)/'result.json');x=old['assembly'];ref=rows[0]
    diff=dict(same_k_bits=ref['k_hex']==old['candidate']['k_hex'],epsilon_relative=[float(Decimal(e)/Decimal(v)-1) for e,v in zip(ref['eps'],x['epsilon_decimal_readback'])],Q_relative=float(Decimal(ref['Q'])/Decimal(x['Q_upper'])-1),width_relative=float(Decimal(ref['width'])/Decimal(x['width_upper'])-1))
    oldclock=load(Path(a.baseline)/'end-to-end.json');oldstages={z['stage']:z['driver_seconds'] for z in old['stages']}
    diff['timing']=dict(old_wall_seconds=oldclock['wall_seconds'],new_wall_seconds=ref['wall_seconds'],stage_differences_seconds={z['stage']:z['seconds']-oldstages[z['stage']] for z in ref['stages']})
    diff['passed']=diff['same_k_bits'] and max(map(abs,diff['epsilon_relative']+[diff['Q_relative'],diff['width_relative']]))<=.01
    (out/'baseline-check.json').write_text(json.dumps(diff,indent=2));assert diff['passed'],diff
  ref=rows[0]
  for r in rows:r['k_ulp_from_reference']=int(r['k_hex'],16)-int(ref['k_hex'],16)
  (out/'reference-results.json').write_text(json.dumps(rows,indent=2))
  csvrows=[]
  for r in rows:
    t={k:r[k] for k in ['run','k','k_hex','k_ulp_from_reference','Q','U','width','wall_seconds','rss_gib']};t.update(r['settings'])
    for j,name in enumerate(['center','left','right','walls','seams']):t.update({f'epsilon_{name}':r['eps'][j],f'C_epsilon_{name}':r['weighted'][j],f'floating_finite_{name}':r['floating_finite'][j],f'evaluation_fraction_{name}':r['evaluation_fraction'][j]})
    csvrows.append(t)
  with (out/'resolution.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=csvrows[0]);w.writeheader();w.writerows(csvrows)
  print(json.dumps([{k:r[k] for k in ['run','k','Q','width','wall_seconds','rss_gib']} for r in rows],indent=2))
if __name__=='__main__':main()
