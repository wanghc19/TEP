"""Launch source-split diagnostics with explicit shared-package and FMM paths.
Input: output directory, package root and FMM (fast multipole method) root.
Output: monitored MATLAB logs and compact scalar records.
"""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--formula',choices=['pilot','full','fine'],default='pilot');p.add_argument('--soft-seconds',type=float,default=1800);p.add_argument('--hard-seconds',type=float,default=2400);a=p.parse_args()
exp=Path(__file__).resolve().parent;out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Use a fresh numbered output directory.')
if not (Path(a.fmm_root)/'fmm2d.mexmaca64').is_file():raise RuntimeError('Explicit FMM2D path has no MEX.')
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11')
def m(x):return "'"+str(x).replace("'","''")+"'"
setting="srcsplit_settings('%s')"%a.formula
entry='srcsplit_fine' if a.formula=='fine' else 'srcsplit_run'
expr='addpath(%s);addpath(%s);addpath(%s);%s(%s,pilot_config(),%s);'%(*map(m,[exp,a.package_root,a.fmm_root]),entry,m(out),setting)
r=run(out,expr,soft=a.soft_seconds,hard=a.hard_seconds);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
