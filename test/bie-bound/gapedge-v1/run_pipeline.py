# Stage C source: test/bie-bound/example2-v1/run_pipeline.py; local changes documented in README.
# B2 source: test/bie-bound/pipeline-v1/run_pipeline.py; explicit example model.
"""Run the complete BIE (boundary integral equation) route from empty output.
Input: explicit package, search-code, FMM, MATLAB and Conda paths; output.
Output: monitored stage records, reliable interval, input ledger and figures.
"""
import argparse,csv,json,os,platform,struct,subprocess,sys,time,shutil,traceback,gzip
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from monitor import run
HERE=Path(__file__).resolve().parent

def write(p,x):p.write_text(json.dumps(x,indent=2))
def matlab_quote(x):return "'"+str(x).replace("'","''")+"'"
def archive_completed(path):
  """Lossless archive after the last scientific read of an owned artifact."""
  raw=path.read_bytes()
  if isinstance(json.loads(raw),dict) and 'archive' in json.loads(raw):return
  dest=path.with_suffix(path.suffix+'.gz')
  with gzip.open(dest,'wb') as f:f.write(raw)
  assert gzip.decompress(dest.read_bytes())==raw
  path.write_text(json.dumps(dict(archive=dest.name,encoding='gzip',original_format='JSON')))

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
  begin=time.perf_counter();rows=[];inputs=[]
  def stage(name,cmd,threads,scientific_inputs=()):
    dest=out/name;dest.mkdir();(out/'part.txt').write_text(name)
    os.environ.update(OMP_NUM_THREADS=str(threads),OPENBLAS_NUM_THREADS=str(threads),MKL_NUM_THREADS=str(threads),VECLIB_MAXIMUM_THREADS=str(threads),OMP_DYNAMIC='FALSE',PYTHONDONTWRITEBYTECODE='1')
    for f in scientific_inputs:
      path=Path(f).resolve();assert path.is_relative_to(out) and path.exists();inputs.append(dict(stage=name,path=str(path)))
    t=time.perf_counter();elapsed=t-begin;rec=run(dest,cmd,soft=max(1,1800-elapsed),hard=max(1,2400-elapsed))
    rows.append(dict(stage=name,driver_seconds=time.perf_counter()-t,threads_or_workers=a.workers if name=='03-residuals' else threads,monitor=rec,command=cmd));write(out/'stages.json',rows);write(out/'scientific-inputs.json',inputs)
    if rec['returncode']!=0 or rec['reason']!='completed':raise RuntimeError(name+' failed: '+json.dumps(rec))
    return dest
  def arb(name,folder,script,opts,inputs=()):
    dest=out/name
    cmd=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(HERE/'audit_entry.py'),'--run-root',str(out),'--entry',str(HERE/folder/script),'--','--output',str(dest)]+list(map(str,opts))
    return stage(name,cmd,1,inputs)
  def matlab(name,paths,call):
    dest=out/name;expr=';'.join('addpath('+matlab_quote(x)+')' for x in [a.package_root,a.fmm_root,HERE]+paths)+';'+call+';write_dependencies('+matlab_quote(dest)+');'
    return stage(name,[a.matlab,'-batch',expr],11)
  setup_seconds=0.;support=HERE/'search'
  search=matlab('01-search',[support],"e=example_parameters("+matlab_quote(a.example)+','+repr(a.center_width)+");s=search_config(11,'production');s.example=e;detsearch("+matlab_quote(out/'01-search')+',s)')
  result=json.loads((search/'result.json').read_text());assert result['status']=='COMPLETE'
  candidates=result['candidates'];candidates=[candidates] if isinstance(candidates,dict) else candidates
  assert candidates,'No confirmed guided-mode candidate'
  candidates=sorted(candidates,key=lambda c:c['k'])
  write(out/'candidate-selection.json',dict(policy='lowest confirmed k in the searched common window',selected_index=0,candidates=candidates))
  candidate=candidates[0];k=struct.unpack('>d',bytes.fromhex(candidate['k_hex']))[0]
  assert k==candidate['k'];candidate['k_decimal']=repr(k);candidate['k_hexfloat']=k.hex();write(out/'candidate.json',candidate)
  for path in search.rglob('*.json'):
    if path.stat().st_size>200000:archive_completed(path)
  field=matlab('02-field',[HERE/'field'],"field_export("+matlab_quote(out/'02-field')+','+repr(k)+','+matlab_quote(a.resolution)+',example_parameters('+matlab_quote(a.example)+','+repr(a.center_width)+'))')
  fixed=field/'fixed-input.json.gz';fits=field/'coefficients.json.gz'
  check=json.loads(gzip.decompress(fixed.read_bytes()));kh=check['k']['real'];kh=kh if isinstance(kh,str) else kh[0];assert kh==candidate['k_hex'],'Frequency handoff changed'
  conditions=arb('02-conditions','','conditions.py',['--input',fixed,'--coefficients',fits],[fixed,fits])
  residual=arb('03-residuals','residual','groups.py',['--input',fixed,'--coefficients',fits,'--workers',a.workers,'--states',a.states,'--states-left',a.states_left or a.states,'--states-right',a.states_right or a.states,'--tail-ratio',a.tail_ratio],[fixed,fits])
  audit=arb('04-residual-audit','residual','audit_groups.py',['--run',residual],[residual/'summary.json'])
  archive_completed(residual/'summary.json')
  mass=arb('05-mass','mass','disks.py',['--input',fixed,'--order','30'],[fixed])
  window_args=(['--k-lower',a.k_lower] if a.k_lower else [])+(['--k-upper',a.k_upper] if a.k_upper else [])
  enclosure=arb('06-enclosure','enclosure','assemble.py',['--input',fixed,'--groups',residual/'groups.json','--disks',mass/'disks.json']+window_args,[fixed,residual/'groups.json',mass/'disks.json'])
  band=arb('07-band','band','band_certificate.py',['--input',fixed,'--enclosure',enclosure/'result.json','--mode','full']+window_args,[fixed,enclosure/'result.json'])
  last=json.loads((enclosure/'result.json').read_text());bands=json.loads((band/'result.json').read_text());assert bands['status']=='PASS' and bands['sign_tests']==944
  interval=last['assemblies'][0]
  from decimal import Decimal
  assert Decimal(interval['k_interval'][0])<Decimal.from_float(k)<Decimal(interval['k_interval'][1])
  meta_start=time.perf_counter();write(out/'environment-python.json',get_python_environment(a));metadata_seconds=time.perf_counter()-meta_start
  elapsed=time.perf_counter()-begin
  final=dict(status='COMPLETE',candidate=candidate,assembly=interval,band=bands['minima'],T15=bands['T15'],stages=rows,source_preparation_seconds=setup_seconds,worker_seconds=elapsed,environment_metadata_seconds=metadata_seconds,orchestration_seconds=elapsed-setup_seconds-sum(x['driver_seconds'] for x in rows),same_run_frequency_hex=kh)
  if a.example=='reference':
    ref=[1.261583568749579e-12,5.081050050368226e-14,5.231554719622704e-14,2.0345791259404752e-13,5.783689953127645e-15]
    new=json.loads((residual/'groups.json').read_text())['epsilon_upper']
    diff=[abs(x/y-1) for x,y in zip(new,ref)]
    checks=dict(k_hex_equal=kh=='3ff8ef5c92c5bf30',epsilon_relative=diff,Q_relative=abs(float(interval['Q_upper'])/3.482935419894950973e-12-1),width_relative=abs(float(interval['width_upper'])/2.73786243218470e-11-1))
    write(out/'regression.json',checks);assert checks['k_hex_equal'] and max(diff+[checks['Q_relative'],checks['width_relative']])<=1e-6
    final['regression']=checks
  for path in out.rglob('*.json'):
    if path.stat().st_size>50000:archive_completed(path)
  write(out/'result.json',final)
  print('PIPELINE COMPLETE',json.dumps(dict(k=k,width=interval['width_upper'],seconds=elapsed)),flush=True)

def get_python_environment(a):
  text=subprocess.check_output([a.conda,'run','-n','octave','python','-I','-c',"import flint,sys,json;print(json.dumps({'python':sys.version,'python_flint':flint.__version__,'flint':str(getattr(flint,'__FLINT_VERSION__','unavailable'))}))"],text=True)
  return json.loads(text)

def main():
  p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--matlab',required=True);p.add_argument('--conda',required=True);p.add_argument('--example',choices=['reference','empty-rotated'],required=True);p.add_argument('--resolution',choices=['reference','coarse'],default='reference');p.add_argument('--center-width',type=float,default=1.0);p.add_argument('--workers',type=int,default=8);p.add_argument('--states',type=int,default=80);p.add_argument('--tail-ratio',default='1e-6');p.add_argument('--states-left',type=int);p.add_argument('--states-right',type=int);p.add_argument('--k-lower');p.add_argument('--k-upper');p.add_argument('--worker',action='store_true');a=p.parse_args();out=Path(a.output).resolve()
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
