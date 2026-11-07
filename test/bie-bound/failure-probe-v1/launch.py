"""Launch a BIE failure probe in a fresh monitored MATLAB process.
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
p.add_argument('--plan',type=Path,required=True)
p.add_argument('--bands-python',type=Path)
p.add_argument('--max-wall',type=int,default=1800,help='Shorter observation budget in seconds, at most 1800.')
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
plan=json.loads(a.plan.read_text())
(out/'plan.json').write_text(json.dumps(plan,indent=2))
expr=f"probe({quote(out)},{quote(out/'plan.json')});"
setup='restoredefaultpath;'+''.join('addpath('+quote(x.resolve())+');' for x in paths)
command=setup+expr
if a.bands_python:
  os.environ.update(OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1',MKL_NUM_THREADS='1')
  command=[str(a.bands_python),'-B',str(here/'bands.py'),str(out)]
assert 1<=a.max_wall<=1800
record=run(out,command,matlab_path=str(a.matlab.resolve()),soft=a.max_wall)
sys.exit(0 if record['returncode']==0 and record['reason']=='completed' else 1)
