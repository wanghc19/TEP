"""Explicit path launcher; uses only this experiment's copied monitor."""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser()
p.add_argument('--output',required=True)
p.add_argument('--package-root',required=True)
p.add_argument('--fmm-root',required=True)
a=p.parse_args()
if not (Path(a.fmm_root)/'fmm2d.mexmaca64').is_file():
 raise RuntimeError('The explicit FMM2D path must contain the existing macOS ARM64 MATLAB MEX.')
exp=Path(__file__).resolve().parent
out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()): raise RuntimeError('Choose a fresh numbered output directory.')
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11')
def matstr(s):return "'"+str(s).replace("'","''")+"'"
expr="addpath(%s);addpath(%s);addpath(%s);settings=struct('optional_direct1536',true,'soft_seconds',1800);eval_pilot(%s,pilot_config(),settings);"%tuple(map(matstr,[exp,a.package_root,a.fmm_root,out]))
r=run(out,expr)
sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
