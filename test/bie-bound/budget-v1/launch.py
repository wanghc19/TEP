"""Launch the fixed-field budget through the copied monitor, with explicit paths."""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);a=p.parse_args()
exp=Path(__file__).resolve().parent;out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Use a fresh numbered output directory.')
if not (Path(a.fmm_root)/'fmm2d.mexmaca64').is_file():raise RuntimeError('Explicit FMM2D path has no MEX.')
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11')
def m(x):return "'"+str(x).replace("'","''")+"'"
expr='addpath(%s);addpath(%s);addpath(%s);s=struct(\'source_counts\',[0,768,1536,3072],\'target_count\',1536,\'material_count\',1536,\'seam_count\',1536,\'mass_source\',1536);budget_run(%s,pilot_config(),s);'%tuple(map(m,[exp,a.package_root,a.fmm_root,out]))
r=run(out,expr);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
