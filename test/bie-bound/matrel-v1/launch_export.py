"""Launch the fixed-field export. BIE means boundary integral equation.
Input: output, shared-package root, FMM root, MATLAB executable. Output: monitored export.
"""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--matlab',default='/Applications/MATLAB_R2023b.app/bin/matlab');a=p.parse_args()
out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Use a fresh output directory')
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11',OPENBLAS_NUM_THREADS='11')
def m(x):return "'"+str(x).replace("'","''")+"'"
expr='addpath(%s);addpath(%s);addpath(%s);export_fixed(%s,pilot_config());'%tuple(map(m,[Path(__file__).resolve().parent,a.package_root,a.fmm_root,out]))
r=run(out,expr,matlab_path=a.matlab);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
