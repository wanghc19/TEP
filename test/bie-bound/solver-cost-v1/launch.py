"""Launch an example-1 solver in a fresh monitored MATLAB process.
Input: explicit package, FEM source, I9 source, FMM, MATLAB and output paths.
Output: cold time, peak process-tree memory, preflight and solver records.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
sys.dont_write_bytecode = True
from monitor import run

here = Path(__file__).resolve().parent
p = argparse.ArgumentParser()
for name in ('output','package-root','i9','fmm','fem','matlab'):
  p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--solver',choices=['bie','fem'],required=True)
p.add_argument('--size',type=int,required=True)
p.add_argument('--order',type=int,required=True)
a = p.parse_args()
out = a.output.resolve()
if out.exists() and any(out.iterdir()):
  raise ValueError('Output directory must be empty')
raw = subprocess.check_output(['ps','-axo','pid=,ppid=,%cpu=,rss=,comm=,args='],text=True)
jobs = []
for line in raw.splitlines():
  v=line.split(None,5)
  if len(v)<6 or int(v[0]) in (os.getpid(),os.getppid()):continue
  name=Path(v[4]).name.lower()
  if name=='matlab' or ((name.startswith('python') or name in ('julia','octave','rscript')) and (float(v[2])>20 or 'run_pipeline.py' in v[5] or 'groups.py' in v[5])):jobs.append(line)
out.mkdir(parents=True,exist_ok=True)
(out/'preflight.json').write_text(json.dumps({'numerical_jobs':jobs,'threads':11,'platform':os.uname().machine},indent=2))
if jobs:raise RuntimeError('Other numerical job detected: '+str(jobs))
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',VECLIB_MAXIMUM_THREADS='11',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11')
def quote(path):return "'"+str(path).replace("'","''")+"'"
if a.solver=='bie':
  paths=[a.package_root,a.fmm,a.i9,here]
  expr=f"s=search_config(11,'production');s.window=[1.4509999999999998,2.249];s.center_nodes={a.size};s.lead_nodes={a.size//2};s.rayleigh_M={a.order};detsearch({quote(out)},s);"
else:
  paths=[a.fem/'examples',a.fem/'internal',here]
  expr=f"fem_search({quote(out)},{a.size},{a.order});"
setup='restoredefaultpath;'+''.join('addpath('+quote(x.resolve())+');' for x in paths)
(out/'config.json').write_text(json.dumps({'solver':a.solver,'size':a.size,'order':a.order,'threads':11,'window':[1.4509999999999998,2.249]},indent=2))
record=run(out,setup+expr,matlab_path=str(a.matlab.resolve()))
sys.exit(0 if record['returncode']==0 and record['reason']=='completed' else 1)
