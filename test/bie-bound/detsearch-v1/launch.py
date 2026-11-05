"""Launch one empty-start determinant root search with explicit paths.
BIE means boundary integral equation; FMM means fast multipole method.
"""
import argparse,csv,json,os,struct,subprocess,sys,time
from pathlib import Path
from monitor import run
from prepare_support import prepare

def active_jobs():
  raw=subprocess.check_output(['ps','-axo','pid=,ppid=,%cpu=,rss=,comm=,args='],text=True)
  jobs=[]
  for row in raw.splitlines():
    v=row.split(None,5)
    if len(v)<6:continue
    pid=int(v[0]);name=Path(v[4]).name.lower();cmd=v[5]
    if pid==os.getpid():continue
    if ('matlab' in name or name.startswith('python')) and (float(v[2])>20 or 'test/' in cmd or 'flint' in cmd):
      jobs.append(dict(pid=pid,cpu=float(v[2]),rss_kib=int(v[3]),command=cmd))
  return jobs

def export(out):
  r=json.loads((out/'result.json').read_text());c=r['candidates']
  if isinstance(c,dict):c=[c]
  for x in c:
    k=struct.unpack('>d',bytes.fromhex(x['k_hex']))[0]
    assert float(x['k_decimal'])==k and x['k']==k
    x['k_decimal']=repr(k);x['k_hexfloat']=k.hex()
  (out/'candidate-list.json').write_text(json.dumps(c,indent=2))
  (out/'candidate-k.txt').write_text(''.join(x['k_decimal']+' '+x['k_hex']+'\n' for x in c))
  for name,rows in [('nodes.csv',r['points'])]:
    if rows:
      with (out/name).open('w') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
  coeff=[]
  for i,panel in enumerate(r['panels']):
    for lev in panel['levels']:
      for j,val in enumerate(lev['relative_coefficients']):coeff.append(dict(panel=i,degree=lev['degree'],index=j,relative=val,real=lev['coeff_real'][j],imag=lev['coeff_imag'][j]))
  if coeff:
    with (out/'coefficients.csv').open('w') as f:
      w=csv.DictWriter(f,fieldnames=list(coeff[0]));w.writeheader();w.writerows(coeff)

p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--search-path',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--mode',choices=['production','forced-fallback'],default='production');p.add_argument('--threads',type=int,choices=[5,11],default=11);a=p.parse_args()
out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Output must be empty; use a fresh numbered run.')
jobs=active_jobs();(out/'preflight.json').write_text(json.dumps({'heavy_jobs':jobs,'threads':a.threads},indent=2))
if a.threads==11 and jobs:raise RuntimeError('Heavy numerical job present; use five threads or wait.')
prepare(a.search_path,out/'inputs')
for name in ['detsearch.m','search_config.m']:(out/'inputs'/name).write_text((Path(__file__).parent/name).read_text())
os.environ.update(OMP_NUM_THREADS=str(a.threads),OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS=str(a.threads),MKL_NUM_THREADS=str(a.threads),VECLIB_MAXIMUM_THREADS=str(a.threads))
def quote(x):return "'"+str(x).replace("'","''")+"'"
paths=[a.package_root,a.fmm_root,out/'inputs']
expr=';'.join('addpath('+quote(x)+')' for x in paths)+';s=search_config('+str(a.threads)+','+quote(a.mode)+');detsearch('+quote(out)+',s);'
t=time.monotonic();result=run(out,expr)
if result['returncode']==0 and result['reason']=='completed':export(out)
(out/'launch-summary.json').write_text(json.dumps({'wall_seconds_including_export':time.monotonic()-t,'heavy_jobs_after':active_jobs()},indent=2))
sys.exit(0 if result['returncode']==0 and result['reason']=='completed' else 1)
