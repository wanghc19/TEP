"""Pure-Python verification of the four empty-center release examples.
Input: explicit canonical data, example, reference and output directories.
Output: reliable bounds, same-field audits and full-phase common-gap tests.
"""
import json,os,sys,time
from pathlib import Path
from monitor import run
from reproduce import write
PACKAGE=Path(__file__).resolve().parent.parent
def verify(a,out):
  from access_guard import install
  install(out,a.forbid_root)
  start=time.perf_counter();rows=[];data=Path(a.data).resolve();fixed=data/'fixed-input.json';fits=data/'coefficients.json'
  inputs=[fixed,fits]+[data/n for n in ['example-settings.json','disks-input.json','band-inputs.json']];assert all(p.is_file() for p in inputs)
  from examples import load_case
  case=load_case(a.example);settings=json.loads((data/'example-settings.json').read_text())
  assert case==settings,'Canonical settings do not match the selected example'
  field=json.loads(fixed.read_text());assert field['example']==case['model']
  assert json.loads((data/'disks-input.json').read_text())==field['disks']
  binput=json.loads((data/'band-inputs.json').read_text());assert binput['k_lower']==case['evaluation']['k_lower'] and binput['k_upper']==case['evaluation']['k_upper']
  assert binput['fourier_halfwidth']==6 and binput['quadrature_nodes']==2048 and binput['phase_scale']==4096
  assert field['pieces'][0]['shape']=='none' and field['pieces'][0]['tau_coeff']['shape'][0]==0
  write(out/'data-checks.json',dict(example=a.example,model=True,empty_center=True))
  write(out/'scientific-inputs.json',{'canonical':list(map(str,inputs)),'generated':[]})
  def stage(name,folder,script,opts):
    dest=out/name;dest.mkdir();(out/'part.txt').write_text(name)
    cmd=[sys.executable,'-B','-I',str(PACKAGE/'scripts/audit_entry.py'),'--run-root',str(out),'--allowed-data',str(data),'--entry',str(PACKAGE/'src/python/ex2'/folder/script)]
    if a.forbid_root:cmd+=['--forbid-root',a.forbid_root]
    cmd+=['--','--output',str(dest)]+list(map(str,opts));t=time.perf_counter();elapsed=t-start
    rec=run(dest,cmd,soft=max(1,1800-elapsed),hard=max(1,2400-elapsed))
    rows.append(dict(stage=name,seconds=time.perf_counter()-t,monitor=rec));write(out/'stages.json',rows)
    if rec['returncode'] or rec['reason']!='completed':raise RuntimeError(name+' failed')
    return dest
  cfg=case['evaluation'];window=['--k-lower',cfg['k_lower'],'--k-upper',cfg['k_upper']]
  stage('02-conditions','','conditions.py',['--input',fixed,'--coefficients',fits])
  residual=stage('03-residuals','residual','groups.py',['--input',fixed,'--coefficients',fits,'--workers',cfg['workers'],'--states-left',cfg['states_left'],'--states-right',cfg['states_right'],'--tail-ratio',cfg['tail_ratio']])
  stage('04-residual-audit','residual','audit_groups.py',['--run',residual])
  mass=stage('05-mass','mass','disks.py',['--input',fixed,'--order',30])
  assembly=stage('06-enclosure','enclosure','assemble.py',['--input',fixed,'--groups',residual/'groups.json','--disks',mass/'disks.json']+window)
  band=stage('07-band','band','band_certificate.py',['--input',fixed,'--enclosure',assembly/'result.json','--mode','full']+window)
  checks={};result=json.loads((assembly/'result.json').read_text());br=json.loads((band/'result.json').read_text())
  checks['canonical_band_partition']=br['full_phase_integer_endpoints']==binput['phase_integer_endpoints']
  checks['eight_LDL']=len(br['independent'])==8 and all(x['LDL']['passed'] and x['LDL']['negative']==1 and x['LDL']['positive']==168 for x in br['independent'])
  checks['deliberate_failure']=not br['failing_control']['check']['passed'] and br['failing_control']['two_negative_directions_upper']<0
  checks['band_944']=br['status']=='PASS' and br['sign_tests']==944
  checks['two_precision_and_rational']=all(x['R_upper']==x['exact_rational_R_upper']==result['assemblies'][0]['R_upper'] for x in result['assemblies'])
  groups=json.loads((residual/'groups.json').read_text())
  checks['general_p_and_N_plus_10']=all(t['power_demo']['checked'] for t in groups['tails'])
  if a.reference:
    ref=json.loads((Path(a.reference)/'results.json').read_text());current=result['assemblies'][0]
    for key in ['epsilon_decimal_readback','U_certificate_readback','Q_upper','R_upper','mu_interval','k_interval','width_upper']:
      checks['reference_'+key]=current[key]==ref['assembly'][key]
    checks['reference_band']=br['minima']==ref['band_minima']
  opened=[json.loads(l) for l in (out/'opened-files.jsonl').read_text().splitlines()]
  opened += [json.loads(l) for l in (out/'driver-opened-files.jsonl').read_text().splitlines()]
  if a.forbid_root:checks['no_forbidden_reads']=not any(Path(x['path']).resolve().is_relative_to(Path(a.forbid_root).resolve()) for x in opened)
  final=dict(example=a.example,status='PASS' if all(checks.values()) else 'FAIL',checks=checks,assembly=result['assemblies'][0],band_minima=br['minima'],seconds=time.perf_counter()-start,stages=rows,opened_files=len(opened))
  write(out/'result.json',final)
  for k,v in checks.items():print(('PASS' if v else 'FAIL')+' '+k,flush=True)
  assert all(checks.values()),'Verification check failed; see result.json'

