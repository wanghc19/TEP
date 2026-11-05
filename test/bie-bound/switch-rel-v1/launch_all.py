"""Launch one self-contained BIE switch certificate, including fixed-field export.
BIE means boundary integral equation; FMM means fast multipole method.
Input: fresh output directory, package/FMM roots, MATLAB and Conda executables.
Output: monitored matlab/ and arb/ subdirectories and pipeline.json.
"""
import argparse,json,os,sys,time
from pathlib import Path
from monitor import run as matlab_run
from monitor_arb import run as arb_run
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--package-root',required=True);p.add_argument('--fmm-root',required=True);p.add_argument('--matlab',default='/Applications/MATLAB_R2023b.app/bin/matlab');p.add_argument('--conda',required=True);a=p.parse_args()
out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
if any(out.iterdir()):raise RuntimeError('Use a fresh run directory')
exp=Path(__file__).resolve().parent
os.environ.update(OMP_NUM_THREADS='11',OMP_DYNAMIC='FALSE',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11',OPENBLAS_NUM_THREADS='11',PYTHONDONTWRITEBYTECODE='1')
def m(x):return "'"+str(x).replace("'","''")+"'"
start=time.perf_counter();result={'status':'STARTED'}
expr='addpath(%s);addpath(%s);addpath(%s);export_fixed(%s,pilot_config());'%tuple(map(m,[exp,a.package_root,a.fmm_root,out/'matlab']))
r=matlab_run(out/'matlab',expr,matlab_path=a.matlab);result['matlab_monitor']=r
(out/'pipeline.json').write_text(json.dumps(result,indent=2))
if r['returncode']!=0 or r['reason']!='completed':sys.exit(1)
cmd=[a.conda,'run','-n','octave','python','-I',str(exp/'reliable_switch.py'),'--input',str(out/'matlab'/'fixed-input.json'),'--output',str(out/'arb'),'--stage','all','--sources','2048','--micro','4096']
r=arb_run(out/'arb',cmd,soft=1800-result['matlab_monitor']['wall_seconds'],hard=2400-result['matlab_monitor']['wall_seconds']);result['arb_monitor']=r
result['wall_seconds']=time.perf_counter()-start;result['peak_process_tree_rss_gib']=max(result['matlab_monitor']['peak_process_tree_rss_gib'],r['peak_process_tree_rss_gib'])
result['status']='COMPLETE' if r['returncode']==0 and r['reason']=='completed' else 'FAILED'
(out/'pipeline.json').write_text(json.dumps(result,indent=2));print(json.dumps(result),flush=True);sys.exit(0 if result['status']=='COMPLETE' else 1)
