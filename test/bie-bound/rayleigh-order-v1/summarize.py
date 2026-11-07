"""Summarize measured Rayleigh root errors and flux diagnostics.
Input: explicit pilot, ladder, dimension output directories and result directory.
Output: CSV (comma-separated values), JSON and Markdown comparison tables.
"""
import argparse
import csv
import json
import math
from pathlib import Path

def read(path):
  return json.loads(Path(path).read_text())

def write_csv(path, rows):
  if not rows:
    return
  keys = list(dict.fromkeys(k for r in rows for k in r))
  with Path(path).open('w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=keys)
    w.writeheader()
    w.writerows(rows)

def fit(points):
  if len(points) < 2:
    return None
  x, y = zip(*points)
  xm, ym = sum(x)/len(x), sum(y)/len(y)
  slope = sum((a-xm)*(b-ym) for a,b in points)/sum((a-xm)**2 for a in x)
  intercept = ym-slope*xm
  residual = [b-intercept-slope*a for a,b in points]
  total = sum((b-ym)**2 for b in y)
  return dict(slope=slope, intercept=intercept, width=-slope/(2*math.pi),
    reduction=math.exp(slope), rms_log=math.sqrt(sum(v*v for v in residual)/len(x)),
    max_log=max(abs(v) for v in residual),
    R2=1-sum(v*v for v in residual)/total if total else 1,
    points=list(x), residuals=residual)

def fmt(x):
  if x is None:
    return '—'
  if isinstance(x, (int,str)):
    return str(x)
  return f'{x:.6g}'

def main():
  p=argparse.ArgumentParser()
  for n in ('pilot','ladder','dimension','output'):
    p.add_argument('--'+n,type=Path,required=True)
  p.add_argument('--cutcheck',type=Path)
  a=p.parse_args();a.output.mkdir(exist_ok=True,parents=True)
  raw=read(a.ladder/'roots.json');geometry=read(a.pilot/'geometry.json')
  valid=[r for r in raw if r['status']=='MEASURED']
  assert len(valid)==len(raw), 'A root job failed; report it before fitting'
  assert all(r['ratio']<1e-11 for r in valid), 'Candidate confirmation failed'
  by={(r['model'],r['N'],r['cut'],r['M']):r for r in valid}
  control={M:abs(by[('ex1',128,0,M)]['k']-by[('ex1',192,0,M)]['k']) for M in [24,*range(1,9)]}
  groups=list(dict.fromkeys((r['model'],r['N'],r['cut']) for r in valid))
  root_rows=[];fits=[];latefits=[];tails=[];tailfits=[];cuttailfits=[]
  for model,N,cut in groups:
    ref=by[(model,N,cut,24)]['k'];points=[];group=[]
    for M in range(1,9):
      r=by[(model,N,cut,M)];err=abs(r['k']-ref)
      floor=20*math.ulp(ref)
      if model=='ex1':
        floor=max(floor,10*control[M],10*control[24])
      row=dict(model=model,N=N,cut=cut,M=M,k=r['k'],reference=ref,
        error=err,signed_error=r['k']-ref,floor=floor,used=err>floor,
        density_difference=control[M] if model=='ex1' else None,
        D_left=r['D_min'][0],D_right=r['D_min'][1],ratio=r['ratio'],calls=r['calls'],seconds=r['seconds'])
      root_rows.append(row);group.append(row)
      if err>floor:points.append((M,math.log(err)))
      cols=['a_left','b_left','a_right','b_right']
      for m,co in zip(r['m'],r['coeff_abs']):
        if abs(m)>=max(1,M-1):
          tails.append(dict(model=model,N=N,cut=cut,M=M,m=m,**dict(zip(cols,co))))
    f=fit(points)
    if f:
      f.update(model=model,N=N,cut=cut,wmin=geometry[model+'_wmin'])
      fits.append(f)
    late=fit([xy for xy in points if xy[0]>=2])
    if late:
      late.update(model=model,N=N,cut=cut,wmin=geometry[model+'_wmin'])
      latefits.append(late)
    refrow=by[(model,N,cut,24)];lookup=dict(zip(refrow['m'],refrow['coeff_abs']))
    for col,name in enumerate(['a_left','b_left','a_right','b_right']):
      vals=[]
      for m in range(1,25):
        amp=math.hypot(lookup[-m][col],lookup[m][col])
        if 3<=m<=10 and amp>1e-14:vals.append((m,math.log(amp)))
      tf=fit(vals)
      if tf:
        tf.update(model=model,N=N,cut=cut,amplitude=name)
        tailfits.append(tf)
      if model=='ex1' and N==128 and col in (2,3):
        cf=fit([(m,math.log(math.hypot(lookup[-m][col],lookup[m][col]))) for m in range(3,9)])
        cf.update(model=model,N=N,cut=cut,amplitude=name)
        cuttailfits.append(cf)
  write_csv(a.output/'roots.csv',root_rows)
  write_csv(a.output/'fits.csv',[{k:(str(v) if isinstance(v,list) else v) for k,v in r.items()} for r in fits])
  write_csv(a.output/'late-fits.csv',[{k:(str(v) if isinstance(v,list) else v) for k,v in r.items()} for r in latefits])
  write_csv(a.output/'tails.csv',tails)
  write_csv(a.output/'tail-fits.csv',[{k:(str(v) if isinstance(v,list) else v) for k,v in r.items()} for r in tailfits])
  write_csv(a.output/'cut-tail-fits.csv',[{k:(str(v) if isinstance(v,list) else v) for k,v in r.items()} for r in cuttailfits])
  cutrows=read(a.ladder/'cut-window.json');write_csv(a.output/'cut-window.csv',cutrows)
  fullcuts=read(a.cutcheck/'cut-window.json') if a.cutcheck else []
  write_csv(a.output/'cut-full-gap.csv',fullcuts)
  cuts=[]
  for cut in [-.04,0,.06,.16]:
    rr=[r for r in valid if r['model']=='ex1' and r['N']==128 and r['cut']==cut]
    cuts.append(dict(cut=cut,delta_center=.14+cut,delta_right=geometry['ex1_strips'][1]-(.14+cut),
      reference=by[('ex1',128,cut,24)]['k'],
      maximum_root_difference=max(abs(r['k']-by[('ex1',128,0,r['M'])]['k']) for r in rr),
      minimum_D_left_at_roots=min(r['D_min'][0] for r in rr),
      minimum_D_at_roots=min(r['D_min'][1] for r in rr),
      minimum_D_on_grid=min(r['D_min'] for r in cutrows if r['cut']==cut),
      minimum_D_full_gap=min((r['D_min'] for r in fullcuts if r['cut']==cut),default=None)))
  write_csv(a.output/'cuts.csv',cuts)
  dims=read(a.dimension/'dimension.json')
  common_edges=[1.317414080243+t for t in [1e-2,1e-3,1e-4]]
  common_edges += [2.380844148165-t for t in [1e-2,1e-3,1e-4]]
  for row in dims:
    label=row['location']
    if label=='b':
      label='b-common' if any(abs(row['k']-k)<1e-10 for k in common_edges) else 'b-extra'
    row['analysis_location']=label
  failures=[r for r in dims if r.get('status')!='MEASURED']
  dr=[{k:v for k,v in r.items() if k!='multipliers_abs'} for r in dims]
  write_csv(a.output/'dimension.csv',dr)
  summaries=[]
  for loc in ['a','b-common','b-extra','c','d']:
    for side in ['negative','positive']:
      rr=[r for r in dims if r.get('status')=='MEASURED' and r['analysis_location']==loc and r['side']==side]
      if not rr:continue
      summary=dict(location=loc,side=side,points=len(rr),counts=sorted(set(r['inside_count'] for r in rr)),
        non_K=sum(not r['count_is_K'] for r in rr),near_unit_cases=sum(r['near_unit_count']>0 for r in rr),
        maximum_flux=max(r['flux_defect'] for r in rr),maximum_neutrality=max(r['neutrality'] for r in rr),
        minimum_distance=min(r['unit_distance'] for r in rr),minimum_gamma=min(r['gamma_min'] for r in rr),
        smallest_max_inside=min(r['max_inside'] for r in rr),largest_max_inside=max(r['max_inside'] for r in rr),
        smallest_min_outside=min(r['min_outside'] for r in rr),largest_min_outside=max(r['min_outside'] for r in rr),
        inequality_passes=sum(r['defect_below_distance'] for r in rr),
        pass_non_K=sum(r['defect_below_distance'] and not r['count_is_K'] for r in rr),
        fail_K=sum(not r['defect_below_distance'] and r['count_is_K'] for r in rr))
      summaries.append(summary)
  write_csv(a.output/'dimension-summary.csv',summaries)
  summary=dict(geometry=geometry,density_difference=control,root_fits=fits,late_fits=latefits,tail_fits=tailfits,cut_tail_fits=cuttailfits,cuts=cuts,
    dimension=summaries,dimension_errors=failures,
    regression=read(a.pilot/'regression.json'),empty=read(a.pilot/'empty-flux.json'),rod=read(a.pilot/'rod-flux.json'),
    monitors=[read(d/'monitor.json') for d in [a.pilot,a.ladder,a.dimension]+([a.cutcheck] if a.cutcheck else [])])
  (a.output/'summary.json').write_text(json.dumps(summary,indent=2))
  lines=['# Measured tables','','## Root errors','','| Model / nodes / cut | '+' | '.join('M'+str(i) for i in range(1,9))+' |','|---|'+'---|'*8]
  for model,N,cut in groups:
    rr=[r for r in root_rows if (r['model'],r['N'],r['cut'])==(model,N,cut)]
    lines.append(f'| {model} / {N} / {cut:+.2f} | '+' | '.join(fmt(r['error']) for r in rr)+' |')
  lines+=['','## Root fits','','| Model / N / cut | M used | effective width | strip width | per-order ratio | RMS log residual | max log residual |','|---|---|---|---|---|---|---|']
  for r in fits:
    lines.append(f"| {r['model']} / {r['N']} / {r['cut']:+.2f} | {r['points']} | {fmt(r['width'])} | {fmt(r['wmin'])} | {fmt(r['reduction'])} | {fmt(r['rms_log'])} | {fmt(r['max_log'])} |")
  lines+=['','## Sensitivity fits excluding M1','','| Model / N / cut | M used | effective width | RMS log residual | max log residual |','|---|---|---|---|---|']
  for r in latefits:
    lines.append(f"| {r['model']} / {r['N']} / {r['cut']:+.2f} | {r['points']} | {fmt(r['width'])} | {fmt(r['rms_log'])} | {fmt(r['max_log'])} |")
  lines+=['','## Cuts','','| Shift | center clearance | right clearance | max root change | min D at roots | min D on frequency grid |','|---|---|---|---|---|---|']
  for r in cuts:lines.append('| '+' | '.join(fmt(r[k]) for k in ['cut','delta_center','delta_right','maximum_root_difference','minimum_D_at_roots','minimum_D_on_grid'])+' |')
  lines+=['','## Tail fits on M24 reference','','| Model / N / cut | coefficient | orders | effective width | RMS log residual |','|---|---|---|---|---|']
  for r in tailfits:lines.append(f"| {r['model']} / {r['N']} / {r['cut']:+.2f} | {r['amplitude']} | {r['points']} | {fmt(r['width'])} | {fmt(r['rms_log'])} |")
  lines+=['','## Dimension summaries','','| Location / side | cases | raw counts | non-K | near-unit cases | max flux defect | max neutrality | min unit distance | min gamma | passes / pass non-K / fail K |','|---|---|---|---|---|---|---|---|---|---|']
  for r in summaries:
    lines.append(f"| {r['location']} / {r['side']} | {r['points']} | {r['counts']} | {r['non_K']} | {r['near_unit_cases']} | {fmt(r['maximum_flux'])} | {fmt(r['maximum_neutrality'])} | {fmt(r['minimum_distance'])} | {fmt(r['minimum_gamma'])} | {r['inequality_passes']} / {r['pass_non_K']} / {r['fail_K']} |")
  (a.output/'tables.md').write_text('\n'.join(lines)+'\n')
  print(json.dumps(dict(fits=[{k:r[k] for k in ['model','N','cut','points','width','rms_log']} for r in fits],dimension=summaries,cuts=cuts),indent=2))

if __name__=='__main__':
  main()
