"""Launch explicit cell-kernel field-fit inputs through the MATLAB monitor.
Input: output, shared-package root, FMM root and exact input JSON.
Output: monitored run; FMM means fast multipole method.
"""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--input',required=True);a=p.parse_args()
exp=Path(__file__).resolve().parent;out=Path(a.output).resolve()
if out.exists():raise RuntimeError('Use a fresh numbered output directory')
out.mkdir(parents=True)
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11')
def m(x):return "'"+str(x).replace("'","''")+"'"
expr='addpath(%s);addpath(%s);addpath(%s);field_budget(%s,cell_settings(),%s);'%(*map(m,[exp,a.package_root,a.fmm_root]),m(out),m(Path(a.input).resolve()))
r=run(out,expr);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
