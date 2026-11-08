"""Launch a split-window BIE experiment in a fresh monitored MATLAB process.
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
p.add_argument('--handoff-root',type=Path,help='Parent of the explicitly named runs for a replay.')

p.add_argument('--max-wall',type=int,default=1800,help='Shorter observation budget in seconds, at most 1800.')
a = p.parse_args()
out = a.output.resolve()
if out.exists() and any(out.iterdir()):
  raise ValueError('Output directory must be empty')
out.mkdir(parents=True,exist_ok=True)
(out/'preflight.json').write_text(json.dumps({'threads':5,'concurrent_experiment_allowed':True,'platform':os.uname().machine}))
for var in ('OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','VECLIB_MAXIMUM_THREADS','MKL_NUM_THREADS'):
  os.environ[var]='5'
os.environ['OMP_DYNAMIC']='FALSE'
def quote(path):return "'"+str(path).replace("'","''")+"'"
paths=[a.package_root,a.fmm,here]
plan=json.loads(a.plan.read_text())
if a.handoff_root is not None and 'handoff_root' in plan:
  plan['handoff_root']=str(a.handoff_root.resolve())
(out/'plan.json').write_text(json.dumps(plan,indent=2))
entry="fallback_probe"
expr=f"{entry}({quote(out)},{quote(out/'plan.json')});"
setup='restoredefaultpath;'+''.join('addpath('+quote(x.resolve())+');' for x in paths)
command=setup+expr
assert 1<=a.max_wall<=1800
record=run(out,command,matlab_path=str(a.matlab.resolve()),soft=a.max_wall)
sys.exit(0 if record['returncode']==0 and record['reason']=='completed' else 1)
