"""Verify finite element canonical data without a field or flux solve.
Input: explicit data/reference/output directories, part, MATLAB and Python paths.
Output: recomputed integrals or isolation predicates with monitors and comparisons.
"""
import argparse,json,os,sys,subprocess,time
from pathlib import Path
sys.dont_write_bytecode=True
PKG=Path(__file__).resolve().parents[2];BASE=PKG/'fem';sys.path.insert(0,str(PKG/'scripts'));sys.path.insert(0,str(BASE/'scripts'))
from monitor import run,disk_size
from arrays import materialize
from write_intervals import process
p=argparse.ArgumentParser();p.add_argument('--example',choices=['ex1'],required=True);p.add_argument('--part',choices=['interval','isolation'],required=True)
for k in ['data','reference','output','matlab','storage-root']:p.add_argument('--'+k,type=Path,required=True)
p.add_argument('--interval',type=Path);a=p.parse_args();out=a.output.resolve();data=a.data.resolve();assert not out.exists() or not any(out.iterdir())
assert disk_size(PKG)<200_000_000 and disk_size(a.storage_root)<1_990_000_000
out.mkdir(parents=True,exist_ok=True);(out/'preflight.txt').write_text(subprocess.check_output(['ps','-axo','pid=,ppid=,%cpu=,rss=,comm='],text=True))
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',VECLIB_MAXIMUM_THREADS='11',OPENBLAS_NUM_THREADS='11',PYTHONDONTWRITEBYTECODE='1',BIE_STORAGE_ROOT=str(a.storage_root))
opened_python=set()
def read_audit(event,args):
  if event=='open' and isinstance(args[0],(str,bytes)):
    mode=args[1];flags=args[2]
    if (isinstance(mode,str) and 'r' in mode) or (mode is None and isinstance(flags,int) and not flags & (os.O_WRONLY|os.O_RDWR)):
      opened_python.add(str(Path(os.fsdecode(args[0])).resolve()))
sys.addaudithook(read_audit)
q=lambda s:"'"+str(s).replace("'","''")+"'";science=out/'science';science.mkdir();start=time.monotonic();transport=0
if a.part=='interval':
  t=time.monotonic();local=out/'transport';local.mkdir()
  for name in ['native','flux']:materialize(data/name,local/(name+'.mat'))
  (local/'integrals.json').write_bytes((data/'integrals.json').read_bytes());transport=time.monotonic()-t
  paths=[BASE/'src/interval',BASE/'examples'];expr=f"library_tests({q(science/'polynomial-tests')});verify_integrals({q(local)},{q(science)});"
else:
  assert a.interval is not None
  # The full band integration/sign computation is repeated, not read as a verdict.
  r=run(out/'band-monitor',[sys.executable,'-B','-I',str(BASE/'src/band.py'),str(science/'band.json')]);assert r['returncode']==0 and r['reason']=='completed',r
  old=json.loads((data/'band.json').read_text());new=json.loads((science/'band.json').read_text());assert old==new,'Band reproduction differs'
  paths=[BASE/'src/surface',BASE/'src/dtn',BASE/'src/core'];expr=f"verify_isolation({q(data)},{q(a.interval.resolve())},{q(science)});"
paths.append(BASE/'src/common')
code='restoredefaultpath;addpath('+','.join(q(x) for x in paths)+');'+f"fem_read('start',{q(out/'scientific-opened.json')});"+expr
code+="f=inmem('-completenames');fid=fopen("+q(out/'matlab-opened.json')+",'w');fwrite(fid,jsonencode(f));fclose(fid);"
r=run(out/'monitor',[str(a.matlab),'-batch',code],soft=max(1,1800-(time.monotonic()-start)),hard=max(1,2400-(time.monotonic()-start)))
assert r['returncode']==0 and r['reason']=='completed',r
if a.part=='interval':
  process(science)
  old=json.loads((a.reference/'interval.json').read_text());new=json.loads((science/'interval.json').read_text())
  assert old['four_corner']['decimal_endpoints']==new['four_corner']['decimal_endpoints'] and old['I_1']['decimal_endpoints']==new['I_1']['decimal_endpoints']
opened=json.loads((out/'matlab-opened.json').read_text());foreign=[x for x in opened if x and not (x.startswith(str(PKG)) or x.startswith(str(a.matlab.parent.parent)))]
(out/'read-check.json').write_text(json.dumps({'pass':not foreign,'foreign':foreign,'scientific_data':str(data),'interval':str(a.interval) if a.interval else None,'opened':opened},indent=2));assert not foreign
(out/'python-opened.json').write_text(json.dumps(sorted(opened_python),indent=2)+'\n')
(out/'timing.json').write_text(json.dumps({'wall_seconds':time.monotonic()-start,'transport_seconds':transport,'monitor_seconds':r['wall_seconds'],'pass':True},indent=2));print('PASS')
