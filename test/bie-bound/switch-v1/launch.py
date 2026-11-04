"""Launch switch-line diagnostics with explicit shared-package and FMM paths.
Input: output directory, package root and FMM (fast multipole method) root.
Output: monitored MATLAB logs and compact scalar records.
"""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--formula',choices=['original','prime'],default='original');a=p.parse_args()
exp=Path(__file__).resolve().parent;out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Use a fresh numbered output directory.')
if not (Path(a.fmm_root)/'fmm2d.mexmaca64').is_file():raise RuntimeError('Explicit FMM2D path has no MEX.')
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11')
def m(x):return "'"+str(x).replace("'","''")+"'"
setting='switch_prime_settings' if a.formula=='prime' else 'switch_settings'
expr='addpath(%s);addpath(%s);addpath(%s);switch_run(%s,pilot_config(),%s());'%(*map(m,[exp,a.package_root,a.fmm_root,out]),setting)
r=run(out,expr);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
