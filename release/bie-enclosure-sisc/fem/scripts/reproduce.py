"""Reproduce the finite element method comparison with explicit inputs.
Input: example, stage, output, MATLAB and Python executables, and handoff files.
Output: monitored numerical stages and compact records; MATLAB data for verify.
"""
import argparse,json,os,sys,subprocess,time
from pathlib import Path
sys.dont_write_bytecode=True
PKG=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(PKG/'scripts'));from monitor import run,disk_size
p=argparse.ArgumentParser();p.add_argument('--example',choices=['ex1'],required=True);p.add_argument('--stage',choices=['interval','band','surface','dtn','core'],required=True)
p.add_argument('--mesh',type=int,choices=[24,36,48],default=48);p.add_argument('--output',type=Path,required=True);p.add_argument('--matlab',type=Path,required=True);p.add_argument('--python',type=Path,default=Path(sys.executable));p.add_argument('--inputs',type=Path);p.add_argument('--side',choices=['left','right']);p.add_argument('--endpoint',choices=['lower','upper']);p.add_argument('--storage-root',type=Path,required=True)
a=p.parse_args();out=a.output.resolve();assert not out.exists() or not any(out.iterdir()),'Output must be empty'
assert disk_size(PKG)<200_000_000 and disk_size(a.storage_root)<1_990_000_000
out.mkdir(parents=True,exist_ok=True)
pre=subprocess.check_output(['ps','-axo','pid=,ppid=,%cpu=,rss=,comm='],text=True);(out/'preflight.txt').write_text(pre)
# Record heavy processes; a separate preflight inspection precedes each launch.
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',VECLIB_MAXIMUM_THREADS='11',OPENBLAS_NUM_THREADS='11',PYTHONDONTWRITEBYTECODE='1',BIE_STORAGE_ROOT=str(a.storage_root.resolve()))
q=lambda s:"'"+str(s).replace("'","''")+"'"
base=PKG/'fem';science=out/'science';science.mkdir()
paths=[base/'src/interval',base/'examples']
if a.stage=='interval':
  expr=f"run_pipeline(example_mesh({a.mesh}),'original',{q(science)});"
elif a.stage=='band':
  r=run(out/'monitor',[str(a.python),'-I',str(base/'src/band.py'),str(science/'band.json')])
  assert r['reason']=='completed' and r['returncode']==0,r
  (out/'read-check.json').write_text(json.dumps({'pass':True,'scientific_inputs':[],'source':str(base/'src/band.py')}))
  print('COMPLETE');sys.exit(0)
else:
  assert a.inputs is not None,'An explicit handoff JSON is required'
  hand=json.loads(a.inputs.read_text());paths=[base/'src'/a.stage]
  if a.stage=='surface':expr=f"surface_run({q(science)},{q(hand['band'])});"
  elif a.stage=='dtn':expr=f"dtn_stage({q(science)},{q(hand['band'])},{q(hand['surface'])});"
  elif a.stage=='core':expr=f"core_stage({q(science)},"+','.join(q(hand[k]) for k in ['band','surface','left','right','interval'])+");"

paths.append(base/'src/common')
code='restoredefaultpath;addpath('+','.join(q(x) for x in paths)+');'+f"fem_read('start',{q(out/'scientific-opened.json')});"+expr
code+="f=inmem('-completenames'); fid=fopen("+q(out/'matlab-opened.json')+",'w');fwrite(fid,jsonencode(f));fclose(fid);"
(out/'scientific-inputs.json').write_text(json.dumps({'example':a.example,'stage':a.stage,'mesh':a.mesh,'inputs':([] if a.inputs is None else json.loads(a.inputs.read_text())),'source_paths':[str(x) for x in paths]},indent=2))
r=run(out/'monitor',[str(a.matlab),'-batch',code]);assert r['reason']=='completed' and r['returncode']==0,r
if a.stage=='interval':
  sys.path.insert(0,str(base/'scripts'));from write_intervals import process;process(science)
opened=json.loads((out/'matlab-opened.json').read_text());foreign=[x for x in opened if x and not (x.startswith(str(PKG)) or x.startswith(str(a.matlab.parent.parent)))]
(out/'read-check.json').write_text(json.dumps({'pass':not foreign,'foreign':foreign,'opened':opened},indent=2));assert not foreign,foreign
print('COMPLETE',flush=True)
