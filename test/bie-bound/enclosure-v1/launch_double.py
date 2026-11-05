"""Launch the floating lead diagnostic; RSS means resident set size.
Input: explicit input, fit, shared package, output and MATLAB paths.
Output: monitored MATLAB diagnostic.
"""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--input',required=True);p.add_argument('--fits',required=True);p.add_argument('--package-root',required=True);p.add_argument('--matlab',required=True);a=p.parse_args()
out=Path(a.output).resolve();assert not out.exists();exp=Path(__file__).resolve().parent
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11')
def m(x):return "'"+str(x).replace("'","''")+"'"
expr='addpath(%s);addpath(%s);lead_double(%s,%s,%s);'%tuple(map(m,[exp,a.package_root,Path(a.input).resolve(),Path(a.fits).resolve(),out]))
r=run(out,expr,matlab_path=a.matlab);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
