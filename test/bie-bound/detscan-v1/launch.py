"""Launch determinant scan with explicit dependencies and five solver threads."""
import argparse,os,sys
from pathlib import Path
from monitor import run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--search-path',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--mode',choices=['bracket','window'],required=True);a=p.parse_args()
out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Use a fresh numbered run directory.')
os.environ.update(OMP_NUM_THREADS='5',OMP_DYNAMIC='FALSE',OPENBLAS_NUM_THREADS='5',MKL_NUM_THREADS='5',VECLIB_MAXIMUM_THREADS='5')
def quote(x):return "'"+str(x).replace("'","''")+"'"
paths=[Path(__file__).resolve().parent,a.package_root,a.search_path,a.fmm_root]
expr=';'.join('addpath('+quote(x)+')' for x in paths)+';s=struct(\'mode\','+quote(a.mode)+",'degrees',[4,8,16,32]"+(",'tail_tol',1e-11,'split_span',18);" if a.mode=='bracket' else ",'tail_tol',1e-11,'split_span',18);s.degrees=[4,8,16,32,64];")+'determinant_scan('+quote(out)+',s);'
r=run(out,expr);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
