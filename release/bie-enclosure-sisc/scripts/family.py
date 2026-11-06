"""Release R2 empty-center family reproduction.
Input: explicit example, executables, FMM installation and fresh output directory.
Output: complete cold-run certificates. Source: gapedge-v1/run_pipeline.py.
"""
import argparse,csv,json,os,platform,struct,subprocess,sys,time,shutil,traceback,gzip
from pathlib import Path
from monitor import run
from reproduce import write,matlab_quote,empty,preflight
SCRIPTS=Path(__file__).resolve().parent
PACKAGE=SCRIPTS.parent
MATLAB=PACKAGE/'src/matlab'
HERE=MATLAB/'ex2'
PYTHON=PACKAGE/'src/python/ex2'

def archive_completed(path):
  """Lossless archive after the last scientific read of an owned artifact."""
  raw=path.read_bytes()
  if isinstance(json.loads(raw),dict) and 'archive' in json.loads(raw):return
  dest=path.with_suffix(path.suffix+'.gz')
  with gzip.open(dest,'wb') as f:f.write(raw)
  assert gzip.decompress(dest.read_bytes())==raw
  path.write_text(json.dumps(dict(archive=dest.name,encoding='gzip',original_format='JSON')))

def reproduce(a,out):
  from examples import load_case
  from types import SimpleNamespace
  case=load_case(a.example);a=SimpleNamespace(**vars(a))
  a.workers=case["evaluation"]["workers"];a.states=80
  a.states_left=case["evaluation"]["states_left"];a.states_right=case["evaluation"]["states_right"]
  a.tail_ratio=case["evaluation"]["tail_ratio"];a.k_lower=case["evaluation"]["k_lower"];a.k_upper=case["evaluation"]["k_upper"]
  write(out/"example-settings.json",case)
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
    cmd=[a.python,'-B','-I',str(SCRIPTS/'audit_entry.py'),'--run-root',str(out),'--entry',str(PYTHON/folder/script),'--','--output',str(dest)]+list(map(str,opts))
    return stage(name,cmd,1,inputs)
  def matlab(name,paths,call):
    dest=out/name;expr='restoredefaultpath;'+ ';'.join('addpath('+matlab_quote(x)+')' for x in [MATLAB,a.fmm_root,HERE]+paths)+';'+call+';write_dependencies('+matlab_quote(dest)+');'
    path=stage(name,[a.matlab,'-sd',str(dest),'-batch',expr],11)
    deps=json.loads((path/'dependencies.json').read_text());allowed=[MATLAB.resolve(),Path(a.fmm_root).resolve(),Path(a.matlab).resolve().parents[1]]
    unexpected=[f for files in deps.values() for f in files if not any(Path(f).resolve().is_relative_to(root) for root in allowed)]
    write(path/'dependency-check.json',dict(passed=not unexpected,unexpected=unexpected));assert not unexpected,unexpected
    return path
  setup_seconds=0.;support=HERE/'search'
  search=matlab('01-search',[support],"e=example_parameters("+matlab_quote(out/'example-settings.json')+");s=search_config(11,'production');s.example=e;detsearch("+matlab_quote(out/'01-search')+',s)')
  result=json.loads((search/'result.json').read_text());assert result['status']=='COMPLETE'
  candidates=result['candidates'];candidates=[candidates] if isinstance(candidates,dict) else candidates
  assert candidates,'No confirmed guided-mode candidate'
  candidates=sorted(candidates,key=lambda c:c['k'])
  write(out/'candidate-selection.json',dict(policy='lowest confirmed k in the searched common window',selected_index=0,candidates=candidates))
  candidate=candidates[0];k=struct.unpack('>d',bytes.fromhex(candidate['k_hex']))[0]
  assert k==candidate['k'];candidate['k_decimal']=repr(k);candidate['k_hexfloat']=k.hex();write(out/'candidate.json',candidate)
  for path in search.rglob('*.json'):
    if path.stat().st_size>200000:archive_completed(path)
  field=matlab('02-field',[HERE/'field'],"field_export("+matlab_quote(out/'02-field')+','+repr(k)+','+matlab_quote(a.resolution)+',example_parameters('+matlab_quote(out/'example-settings.json')+'))')
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
  final=dict(example=case['example'],settings=case,status='COMPLETE',candidate=candidate,assembly=interval,band=bands['minima'],T15=bands['T15'],stages=rows,source_preparation_seconds=setup_seconds,worker_seconds=elapsed,environment_metadata_seconds=metadata_seconds,orchestration_seconds=elapsed-setup_seconds-sum(x['driver_seconds'] for x in rows),same_run_frequency_hex=kh)
  for path in out.rglob('*.json'):
    if path.stat().st_size>50000:archive_completed(path)
  write(out/'result.json',final)
  print('PIPELINE COMPLETE',json.dumps(dict(k=k,width=interval['width_upper'],seconds=elapsed)),flush=True)

def get_python_environment(a):
  text=subprocess.check_output([a.python,'-B','-I','-c',"import flint,sys,json;print(json.dumps({'python':sys.version,'python_flint':flint.__version__,'flint':str(getattr(flint,'__FLINT_VERSION__','unavailable'))}))"],text=True)
  return json.loads(text)

