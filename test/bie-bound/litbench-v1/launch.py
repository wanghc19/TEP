"""Launch a literature benchmark in a fresh monitored MATLAB process.
Input: explicit package, FMM, MATLAB and output paths.
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
for name in ('output','package-root','fmm','matlab'):
  p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--mode',choices=['fundamental','second','regression','regression-single','reciprocal'],required=True)
p.add_argument('--size',type=int,required=True)
p.add_argument('--order',type=int,required=True)
p.add_argument('--parameters',type=Path)
p.add_argument('--second-parameters',type=Path)
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
paths=[a.package_root,a.fmm,here]
expr=f"benchmark({quote(out)},{quote(a.mode)},{a.size},{a.order});"
if a.mode=='reciprocal':
  if not a.parameters or not a.second_parameters:raise ValueError('Pass both fine-search result.json files explicitly')
  expr=f"reciprocal_check({quote(out)},{quote(a.parameters.resolve())},{quote(a.second_parameters.resolve())});"
setup='restoredefaultpath;'+''.join('addpath('+quote(x.resolve())+');' for x in paths)
(out/'config.json').write_text(json.dumps({'mode':a.mode,'size':a.size,'order':a.order,'threads':11},indent=2))
record=run(out,setup+expr,matlab_path=str(a.matlab.resolve()))
sys.exit(0 if record['returncode']==0 and record['reason']=='completed' else 1)
