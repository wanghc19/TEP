"""Verify the canonical boundary-integral field using Python and ball arithmetic.
Input: explicit canonical data and empty output directories; optional references.
Output: recomputed residual, mass, trace, gap and interval certificates and audits.
"""
import argparse,json,os,sys,time,subprocess,traceback
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from monitor import run
from reproduce import empty,preflight,write
PACKAGE=Path(__file__).resolve().parent.parent

def worker(a,out):
  if a.example!='ex1':
    from verify_family import verify
    return verify(a,out)
  from access_guard import install
  install(out,a.forbid_root)
  start=time.perf_counter();rows=[];data=Path(a.data).resolve();fixed=data/'fixed-input.json';fits=data/'coefficients.json'
  inputs=[fixed,fits]+[data/n for n in ['model.json','disks-input.json','band-inputs.json']];assert all(p.is_file() for p in inputs)
  from validate_data import validate
  write(out/'data-checks.json',validate(data))
  write(out/'scientific-inputs.json',{'canonical':list(map(str,inputs)),'generated':[]})
  def stage(name,folder,script,opts):
    dest=out/name;dest.mkdir();(out/'part.txt').write_text(name)
    cmd=[sys.executable,'-B','-I',str(PACKAGE/'scripts/audit_entry.py'),'--run-root',str(out),'--allowed-data',str(data),'--entry',str(PACKAGE/'src/python'/folder/script)]
    if a.forbid_root:cmd+=['--forbid-root',a.forbid_root]
    cmd+=['--','--output',str(dest)]+list(map(str,opts));t=time.perf_counter();elapsed=t-start
    rec=run(dest,cmd,soft=max(1,1800-elapsed),hard=max(1,2400-elapsed))
    rows.append(dict(stage=name,seconds=time.perf_counter()-t,monitor=rec));write(out/'stages.json',rows)
    if rec['returncode'] or rec['reason']!='completed':raise RuntimeError(name+' failed')
    return dest
  residual=stage('03-residuals','residual','groups.py',['--input',fixed,'--coefficients',fits,'--workers',a.workers,'--states',80])
  stage('04-residual-audit','residual','audit_groups.py',['--run',residual])
  mass=stage('05-mass','mass','disks.py',['--input',fixed,'--order',30])
  assembly=stage('06-enclosure','enclosure','assemble.py',['--input',fixed,'--groups',residual/'groups.json','--disks',mass/'disks.json'])
  band=stage('07-band','band','band_certificate.py',['--input',fixed,'--enclosure',assembly/'result.json','--mode','full'])
  direct=stage('08-traces','residual','direct_traces.py',['--input',fixed,'--coefficients',fits,'--residuals',residual])
  checks={};result=json.loads((assembly/'result.json').read_text());br=json.loads((band/'result.json').read_text())
  checks['four_LDL']=len(br['independent'])==4 and all(x['LDL']['passed'] and x['LDL']['negative']==1 and x['LDL']['positive']==168 for x in br['independent'])
  checks['deliberate_failure']=not br['failing_control']['check']['passed'] and br['failing_control']['two_negative_directions_upper']<0
  checks['band_472']=br['status']=='PASS' and br['sign_tests']==472
  checks['two_precision_and_rational']=all(x['R_upper']==x['exact_rational_R_upper']==result['assemblies'][0]['R_upper'] for x in result['assemblies'])
  checks['two_sided_traces']=json.loads((direct/'result.json').read_text())['passed']
  if a.reference:
    ref=json.loads((Path(a.reference)/'results.json').read_text());current=result['assemblies'][0]
    for key in ['epsilon_decimal_readback','U_certificate_readback','Q_upper','R_upper','mu_interval','k_interval','width_upper']:
      checks['reference_'+key]=current[key]==ref['assembly'][key]
    checks['reference_band']=br['minima']==ref['band_minima']
  opened=[json.loads(l) for l in (out/'opened-files.jsonl').read_text().splitlines()]
  opened += [json.loads(l) for l in (out/'driver-opened-files.jsonl').read_text().splitlines()]
  if a.forbid_root:checks['no_forbidden_reads']=not any(Path(x['path']).resolve().is_relative_to(Path(a.forbid_root).resolve()) for x in opened)
  final=dict(status='PASS' if all(checks.values()) else 'FAIL',checks=checks,assembly=result['assemblies'][0],band_minima=br['minima'],seconds=time.perf_counter()-start,stages=rows,opened_files=len(opened))
  write(out/'result.json',final)
  for k,v in checks.items():print(('PASS' if v else 'FAIL')+' '+k,flush=True)
  assert all(checks.values()),'Verification check failed; see result.json'

def main():
  p=argparse.ArgumentParser();p.add_argument('--example',choices=['ex1','ex2-L1','ex2-L1.6','ex2-L1.9','ex2-L2'],required=True);p.add_argument('--data',required=True);p.add_argument('--output',required=True);p.add_argument('--reference');p.add_argument('--workers',type=int,default=8);p.add_argument('--forbid-root');p.add_argument('--worker',action='store_true');a=p.parse_args();out=Path(a.output).resolve()
  os.environ.update(PYTHONDONTWRITEBYTECODE='1',OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1',OMP_DYNAMIC='FALSE')
  if a.worker:
    try:worker(a,out)
    except Exception as e:write(out/'failure.json',dict(error=str(e),traceback=traceback.format_exc()));raise
    return
  start=time.perf_counter();empty(out);out.mkdir(parents=True,exist_ok=True);pre=preflight();write(out/'preflight.json',pre)
  if pre['heavy_jobs']:raise RuntimeError('Competing scientific process present')
  try:empty(out)
  except RuntimeError:write(out/'empty-start-check.json',dict(nonempty_refused=True))
  rec=run(out,[sys.executable,'-B','-I',str(Path(__file__).resolve())]+sys.argv[1:]+['--worker'])
  write(out/'end-to-end.json',dict(wall_seconds=time.perf_counter()-start,monitor=rec))
  if rec['returncode'] or rec['reason']!='completed':raise SystemExit(1)
if __name__=='__main__':main()
