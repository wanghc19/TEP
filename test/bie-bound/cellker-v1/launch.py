"""Launch the cell-bounded kernel experiment with explicit dependencies.
Input: output, package root, FMM (fast multipole method) root, mode.
Output: monitored MATLAB run and compact scalar records.
"""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--mode',choices=['pilot','budget'],default='pilot');a=p.parse_args()
exp=Path(__file__).resolve().parent;out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Use a fresh numbered output directory.')
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11')
def m(x):return "'"+str(x).replace("'","''")+"'"
entry='cell_kernel_pilot' if a.mode=='pilot' else 'cell_budget'
expr='addpath(%s);addpath(%s);addpath(%s);%s(%s,cell_settings());'%(*map(m,[exp,a.package_root,a.fmm_root]),entry,m(out))
r=run(out,expr);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
