"""Export compact paper tables and CSV (comma-separated values) figure data.
Input: completed same-run directory, explicit old enclosure for comparison only,
       destination for small tracked records. No numerical stage calls this file.
Output: geometry, determinant nodes/coefficients, center contributions and summary.
"""
import argparse,csv,json,math,struct
from pathlib import Path
from decimal import Decimal,localcontext

def load(p):return json.loads(p.read_text())
def seq(x):return [x] if isinstance(x,dict) else x

def table(path,rows):
  with path.open('w') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

def midpoint(s):return Decimal(str(s).strip('[]').split(' +/-')[0])

def main():
  p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--baseline',required=True);p.add_argument('--output',required=True);a=p.parse_args();run=Path(a.run).resolve();out=Path(a.output);out.mkdir(exist_ok=True)
  r=load(run/'result.json');assert r['status']=='COMPLETE';old=load(Path(a.baseline))['assemblies'][0];new=r['assembly'];end=load(run/'end-to-end.json');stages=load(run/'stages.json');search=load(run/'01-search/result.json');field=load(run/'02-field/result.json');mass=load(run/'05-mass/disks.json');groups=load(run/'03-residuals/groups.json');band=load(run/'07-band/result.json');audit=load(run/'04-residual-audit/summary.json');assert audit['all_passed']
  comparison={'baseline_path':a.baseline,'used_for_comparison_only':True}
  with localcontext() as ctx:
    ctx.prec=60
    comparison['epsilon_relative_changes']=[str(Decimal(str(x))/Decimal(y)-1) for x,y in zip(groups['epsilon_upper'],old['epsilon_decimal_readback'])]
    comparison['U_relative_change']=str(midpoint(mass['U_lower'])/midpoint(old['U_certificate_readback'])-1)
    comparison['R_relative_change']=str(Decimal(new['R_upper'])/Decimal(old['R_upper'])-1)
    comparison['mu_endpoint_changes']=[str(Decimal(x)-Decimal(y)) for x,y in zip(new['mu_interval'],old['mu_interval'])]
    comparison['k_intervals_overlap']=max(Decimal(new['k_interval'][0]),Decimal(old['k_interval'][0]))<min(Decimal(new['k_interval'][1]),Decimal(old['k_interval'][1]))
    k=struct.unpack('>d',bytes.fromhex(r['candidate']['k_hex']))[0]
    comparison['new_candidate_contained']=Decimal(new['k_interval'][0])<Decimal.from_float(k)<Decimal(new['k_interval'][1])
    comparison['printed_R_exact_rational_match']=new['R_upper']==new['exact_rational_R_upper']
    comparison['FEM_width_over_BIE']=str(Decimal('4.4623318373737675e-9')/Decimal(new['width_upper']))
    comparison['printed_endpoint_width']=str(Decimal(new['mu_interval'][1])-Decimal(new['mu_interval'][0]))
  assert all(comparison[k] for k in ['k_intervals_overlap','new_candidate_contained','printed_R_exact_rational_match'])
  fixed=load(run/'02-field/fixed-input.json');pars=[struct.unpack('>d',bytes.fromhex(x))[0] for x in fixed['curve_parameters']['real']];model=field['config']['model']
  geom=[]
  for cell in range(-3,4):
    for j in range(257):
      t=2*math.pi*j/256
      if cell==0:x=pars[4]*pars[0]*(pars[2]+pars[1]*math.cos(5*t))*math.cos(t);y=pars[4]*pars[0]*(pars[3]+pars[1]*math.cos(5*t))*math.sin(t);rho=model['rho_center']
      else:
        aa=pars[5] if cell<0 else pars[6];rr=pars[7]/math.sqrt(1+aa*aa/2)*(1+aa*math.cos(3*t));x=rr*math.cos(t);y=rr*math.sin(t);rho=model['rho_lead']
      geom.append(dict(cell=cell,material=rho,node=j,parameter=t,x=cell*model['L']+x,y=y))
  table(out/'geometry.csv',geom)
  points=seq(search['points']);nodes=[];coeff=[]
  for ip,panel in enumerate(seq(search['panels'])):
    levels=seq(panel['levels']);lev=levels[-1];n=lev['degree'];lo,hi=panel['bounds'];mid=(lo+hi)/2;half=(hi-lo)/2
    for j in range(n+1):
      target=mid+half*math.cos(math.pi*j/n);v=min(points,key=lambda z:abs(z['k']-target));assert abs(v['k']-target)<5e-15
      nodes.append(dict(panel=ip,degree=n,node=j,k=v['k'],normalized_determinant_absolute=math.exp(v['logabs']-panel['log_reference']),log_absolute=v['logabs'],normalization_log=panel['log_reference']))
    for lev in levels:
      for j,(re,im,rel) in enumerate(zip(lev['coeff_real'],lev['coeff_imag'],lev['relative_coefficients'])):coeff.append(dict(panel=ip,degree=lev['degree'],index=j,absolute=math.hypot(re,im),relative=rel))
  table(out/'determinant-nodes.csv',nodes);table(out/'determinant-coefficients.csv',coeff)
  center=[]
  for p in sorted((run/'03-residuals').glob('target-center-*.json'),key=lambda x:int(x.stem.split('-')[-1])):
    row=load(p)
    for leaf in row['center']['leaves']:
      idx=leaf['panel'];dep=leaf['depth'];sub=leaf['sub'];ee=leaf['epsilon_panel_upper']
      center.append(dict(panel=idx,depth=dep,subpanel=sub,t_left=2*math.pi*(idx+sub/2**dep)/192,t_right=2*math.pi*(idx+(sub+1)/2**dep)/192,epsilon_upper=ee,epsilon_squared_for_plot=ee*ee,model_error_upper=leaf['e_I'],self_degree=leaf['self'].get('L','')))
  assert len({x['panel'] for x in center})==192;table(out/'center-contributions.csv',center)
  numerical_reads=[];dependency_metadata=[]
  for line in (run/'opened-files.jsonl').read_text().splitlines():
    x=json.loads(line)
    if x['numerical']:
      path=Path(x['path'])
      if path.is_relative_to(run):numerical_reads.append(str(path.relative_to(run)))
      elif 'site-packages' in path.parts and any(v.endswith('.dist-info') for v in path.parts):dependency_metadata.append(str(path))
      else:raise AssertionError('External scientific data read: '+str(path))
  numerical_reads=sorted(set(numerical_reads));(run/'numerical-read-audit.json').write_text(json.dumps(dict(inputs=numerical_reads,dependency_metadata=sorted(set(dependency_metadata)),no_prior_output_reads=True),indent=2))
  scientific=load(run/'scientific-inputs.json');assert all(Path(x['path']).is_relative_to(run) for x in scientific)
  times=[]
  for x in stages:times.append(dict(stage=x['stage'],driver_seconds=x['driver_seconds'],monitor_seconds=x['monitor']['wall_seconds'],threads_or_workers=x['threads_or_workers'],peak_rss_gib=x['monitor']['peak_process_tree_rss_gib']))
  table(out/'stage-times.csv',times)
  residual=load(run/'03-residuals/summary.json');certs=load(run/'06-enclosure/result.json')['certificates'];caps=[x['published'] for x in certs[0]['rows']]
  env=load(run/'environment.json');env.update(load(run/'environment-python.json'));env['matlab_stage']=field['environment']
  compact=dict(candidate=r['candidate'],assembly=new,trace_caps=caps,trace_certified_uppers=[x['trace']['C_upper'] for x in certs[0]['rows']],epsilon_upper=groups['epsilon_upper'],mass_certificate=mass['U_lower'],band_minima=band['minima'],band_signs=band['sign_tests'],comparison=comparison,times=times,end_to_end=end,worker_seconds=r['worker_seconds'],source_preparation_seconds=r['source_preparation_seconds'],orchestration_seconds=r['orchestration_seconds'],field_times={k:v for k,v in field.items() if k.endswith('seconds')},search_times=search['timing'],residual_times={k:residual[k] for k in ['wall_seconds','cpu_seconds','queue_seconds','workers','states']},environment=env,model=field['config']['model'],discretization=field['config']['discretization'],backend=field['config']['backend'],search_settings=search['settings'],B_fit=field['fit'],empty_start=load(run/'empty-start-check.json'),numerical_input_files=numerical_reads,checks=dict(coverage_targets=audit['coverage_targets'],Gauss_max_relative=audit['max_Gauss_relative'],trace_configurations=len(certs),independent_band_checks=len(band['independent']),band_failing_control=not band['failing_control']['check']['passed']))
  (out/'reference-results.json').write_text(json.dumps(compact,indent=2));(run/'comparison.json').write_text(json.dumps(comparison,indent=2))
  print(json.dumps(dict(comparison=comparison,total=end['wall_seconds'],peak=end['monitor']['peak_process_tree_rss_gib'],width=new['width_upper']),indent=2))
if __name__=='__main__':main()
