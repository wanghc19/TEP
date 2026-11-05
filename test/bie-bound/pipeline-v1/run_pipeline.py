"""Run the complete BIE (boundary integral equation) route from empty output.
Input: explicit package, search-code, FMM, MATLAB and Conda paths; output.
Output: monitored stage records, reliable interval, input ledger and figures.
"""
import argparse,csv,json,os,platform,struct,subprocess,sys,time,shutil,traceback
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from monitor import run
HERE=Path(__file__).resolve().parent

def write(p,x):p.write_text(json.dumps(x,indent=2))
def matlab_quote(x):return "'"+str(x).replace("'","''")+"'"
def empty(out):
  if out.exists() and any(out.iterdir()):raise RuntimeError('Output must be empty; use a fresh numbered run.')

def preflight():
  raw=subprocess.check_output(['ps','-axo','pid=,ppid=,%cpu=,rss=,comm=,args='],text=True);jobs=[]
  for line in raw.splitlines():
    v=line.split(None,5)
    if len(v)<6:continue
    pid=int(v[0]);name=Path(v[4]).name.lower();cmd=v[5];exe=Path(cmd.split()[0]).name.lower()
    if pid==os.getpid():continue
    if ('matlab' in name or name.startswith('python') or 'matlab' in exe or exe.startswith('python')) and (float(v[2])>20 or 'test/' in cmd or 'flint' in cmd):
      jobs.append(dict(pid=pid,cpu=float(v[2]),rss_kib=int(v[3]),command=cmd))
  return dict(heavy_jobs=jobs,ps_output=raw,load=os.getloadavg())

def environment(a):
  info=dict(platform=platform.platform(),machine=platform.machine(),python=platform.python_version(),matlab=a.matlab,fmm_source=a.fmm_root)
  for key in ['machdep.cpu.brand_string','hw.physicalcpu','hw.logicalcpu','hw.memsize','hw.perflevel0.physicalcpu','hw.perflevel1.physicalcpu']:
    x=subprocess.run(['sysctl','-n',key],capture_output=True,text=True);info[key]=x.stdout.strip() if x.returncode==0 else x.stderr.strip()
  info['os']=subprocess.check_output(['sw_vers'],text=True);return info

def worker(a,out):
  sys.path.insert(0,str(HERE/'search'));from prepare_support import prepare
  begin=time.perf_counter();rows=[];inputs=[]
  def stage(name,cmd,threads,scientific_inputs=()):
    dest=out/name;dest.mkdir();(out/'part.txt').write_text(name)
    os.environ.update(OMP_NUM_THREADS=str(threads),OPENBLAS_NUM_THREADS=str(threads),MKL_NUM_THREADS=str(threads),VECLIB_MAXIMUM_THREADS=str(threads),OMP_DYNAMIC='FALSE',PYTHONDONTWRITEBYTECODE='1')
    for f in scientific_inputs:
      path=Path(f).resolve();assert path.is_relative_to(out) and path.exists();inputs.append(dict(stage=name,path=str(path)))
    t=time.perf_counter();elapsed=t-begin;rec=run(dest,cmd,soft=max(1,1800-elapsed),hard=max(1,2400-elapsed))
    rows.append(dict(stage=name,driver_seconds=time.perf_counter()-t,threads_or_workers=8 if name=='03-residuals' else threads,monitor=rec,command=cmd));write(out/'stages.json',rows);write(out/'scientific-inputs.json',inputs)
    if rec['returncode']!=0 or rec['reason']!='completed':raise RuntimeError(name+' failed: '+json.dumps(rec))
    return dest
  def arb(name,folder,script,opts,inputs=()):
    dest=out/name
    cmd=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(HERE/'audit_entry.py'),'--run-root',str(out),'--entry',str(HERE/folder/script),'--','--output',str(dest)]+list(map(str,opts))
    return stage(name,cmd,1,inputs)
  def matlab(name,paths,call):
    dest=out/name;expr=';'.join('addpath('+matlab_quote(x)+')' for x in [a.package_root,a.fmm_root,HERE]+paths)+';'+call+';write_dependencies('+matlab_quote(dest)+');'
    return stage(name,[a.matlab,'-batch',expr],11)
  t=time.perf_counter();support=out/'inputs';prepare(a.search_path,support)
  for name in ['detsearch.m','search_config.m']:shutil.copyfile(HERE/'search'/name,support/name)
  source_list=[str(Path(a.search_path)/n) for n in ['search_i9_run.m','search_i9_config.m','search_i9_geometry.m','search_i9_classify.m','search_i9_physics.m']]
  write(out/'source-inputs.json',source_list);setup_seconds=time.perf_counter()-t
  search=matlab('01-search',[support],"s=search_config(11,'production');s.resolution="+matlab_quote(a.resolution)+";detsearch("+matlab_quote(out/'01-search')+',s)')
  result=json.loads((search/'result.json').read_text());assert result['status']=='COMPLETE'
  candidates=result['candidates'];candidates=[candidates] if isinstance(candidates,dict) else candidates
  assert len(candidates)==1,'Single-candidate pipeline requires exactly one confirmed candidate'
  candidate=candidates[0];k=struct.unpack('>d',bytes.fromhex(candidate['k_hex']))[0]
  assert k==candidate['k'];candidate['k_decimal']=repr(k);candidate['k_hexfloat']=k.hex();write(out/'candidate.json',candidate)
  field=matlab('02-field',[HERE/'field'],"field_export("+matlab_quote(out/'02-field')+','+repr(k)+','+matlab_quote(a.resolution)+')')
  fixed=field/'fixed-input.json';fits=field/'coefficients.json'
  check=json.loads(fixed.read_text());kh=check['k']['real'];kh=kh if isinstance(kh,str) else kh[0];assert kh==candidate['k_hex'],'Frequency handoff changed'
  residual=arb('03-residuals','residual','groups.py',['--input',fixed,'--coefficients',fits,'--workers','8','--states','80'],[fixed,fits])
  audit=arb('04-residual-audit','residual','audit_groups.py',['--run',residual],[residual/'summary.json'])
  mass=arb('05-mass','mass','disks.py',['--input',fixed,'--order','30'],[fixed])
  enclosure=arb('06-enclosure','enclosure','assemble.py',['--input',fixed,'--groups',residual/'groups.json','--disks',mass/'disks.json'],[fixed,residual/'groups.json',mass/'disks.json'])
  band=arb('07-band','band','band_certificate.py',['--input',fixed,'--enclosure',enclosure/'result.json','--mode','full'],[fixed,enclosure/'result.json'])
  last=json.loads((enclosure/'result.json').read_text());bands=json.loads((band/'result.json').read_text());assert bands['status']=='PASS' and bands['sign_tests']==472
  interval=last['assemblies'][0]
  from decimal import Decimal
  assert Decimal(interval['k_interval'][0])<Decimal.from_float(k)<Decimal(interval['k_interval'][1])
  meta_start=time.perf_counter();write(out/'environment-python.json',get_python_environment(a));metadata_seconds=time.perf_counter()-meta_start
  elapsed=time.perf_counter()-begin
  final=dict(status='COMPLETE',candidate=candidate,assembly=interval,band=bands['minima'],T15=bands['T15'],stages=rows,source_preparation_seconds=setup_seconds,worker_seconds=elapsed,environment_metadata_seconds=metadata_seconds,orchestration_seconds=elapsed-setup_seconds-sum(x['driver_seconds'] for x in rows),same_run_frequency_hex=kh)
  write(out/'result.json',final)
  print('PIPELINE COMPLETE',json.dumps(dict(k=k,width=interval['width_upper'],seconds=elapsed)),flush=True)

def get_python_environment(a):
  text=subprocess.check_output([a.conda,'run','-n','octave','python','-I','-c',"import flint,sys,json;print(json.dumps({'python':sys.version,'python_flint':flint.__version__,'flint':str(getattr(flint,'__FLINT_VERSION__','unavailable'))}))"],text=True)
  return json.loads(text)

def main():
  p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--search-path',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--matlab',required=True);p.add_argument('--conda',required=True);p.add_argument('--resolution',choices=['reference','coarse'],default='reference');p.add_argument('--worker',action='store_true');a=p.parse_args();out=Path(a.output).resolve()
  if a.worker:
    try:worker(a,out)
    except Exception as e:write(out/'failure.json',dict(error=str(e),traceback=traceback.format_exc()));raise
    return
  start=time.perf_counter();empty(out);out.mkdir(parents=True,exist_ok=True)
  pre=preflight();write(out/'preflight.json',pre)
  if pre['heavy_jobs']:raise RuntimeError('Competing heavy scientific process present; timed run not launched.')
  write(out/'environment.json',environment(a))
  # Exercise the same refusal rule against this now nonempty directory.
  try:empty(out)
  except RuntimeError:write(out/'empty-start-check.json',dict(initial_empty=True,nonempty_refused=True))
  else:raise AssertionError('Empty-start guard failed')
  os.environ.update(PYTHONDONTWRITEBYTECODE='1',OMP_DYNAMIC='FALSE')
  cmd=[sys.executable,'-I',str(HERE/'run_pipeline.py')]+sys.argv[1:]+['--worker']
  rec=run(out,cmd);elapsed=time.perf_counter()-start
  write(out/'end-to-end.json',dict(wall_seconds=elapsed,monitor=rec,preflight_and_parent_seconds=elapsed-rec['wall_seconds']))
  if rec['returncode'] or rec['reason']!='completed':raise SystemExit(1)
if __name__=='__main__':main()
