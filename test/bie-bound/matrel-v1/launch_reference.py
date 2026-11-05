"""Evaluate floating sample values from an existing same-run binary64 export.
Input: explicit package/FMM roots, run directory and MATLAB executable.
Output: a monitored subdirectory with the signed central jump samples.
"""
import argparse,json,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--matlab',default='/Applications/MATLAB_R2023b.app/bin/matlab');p.add_argument('--name',default='floating-reference');a=p.parse_args()
root=Path(a.run).resolve();out=root/a.name
if out.exists():raise ValueError('Use a fresh output')
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11',OPENBLAS_NUM_THREADS='11')
def m(s):return "'"+str(s).replace("'","''")+"'"
expr='addpath(%s);addpath(%s);addpath(%s);export_fixed(%s,pilot_config(),%s);'%tuple(map(m,[Path(__file__).resolve().parent,a.package_root,a.fmm_root,out,root/'export/fixed-input.json']))
used=sum(json.loads(p.read_text())['wall_seconds'] for p in root.glob('*/monitor.json'))
assert used+50<1800
r=run(out,expr,soft=1800-used,hard=2400-used,matlab_path=a.matlab);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
