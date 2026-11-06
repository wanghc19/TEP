"""B1 (second-example preparation) launcher; RSS means resident set size.
Input: explicit output, model settings, package/FMM/MATLAB paths.
Output: monitor, ps preflight, command, numerical results. No old outputs.
"""
import argparse,json,os,subprocess,sys
from pathlib import Path
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from monitor import run
p=argparse.ArgumentParser()
for x in ['output','package-root','fmm-root','matlab']:p.add_argument('--'+x,required=True)
p.add_argument('--mode',choices=['regression','search','bands','confirm'],default='search');p.add_argument('--center-width',type=float,default=1);p.add_argument('--right-period',type=float,default=.85);p.add_argument('--rotation',type=float,default=.13);p.add_argument('--nodes',type=int,default=256)
p.add_argument('--candidate',type=float);p.add_argument('--conda');p.add_argument('--cutoffs',nargs='+',type=int,default=[6,8]);
a=p.parse_args();out=Path(a.output).resolve();here=Path(__file__).resolve().parent
if out.exists() and any(out.iterdir()):raise RuntimeError('Output must be empty')
out.mkdir(parents=True,exist_ok=True)
raw=subprocess.check_output(['ps','-axo','pid=,ppid=,%cpu=,rss=,comm=,args='],text=True)
(out/'preflight.txt').write_text(raw)
for line in raw.splitlines():
 v=line.split(None,5)
 if len(v)<6 or int(v[0])==os.getpid():continue
 name=Path(v[4]).name.lower();exe=Path(v[5].split()[0]).name.lower()
 if ('matlab' in name or name.startswith('python') or 'matlab' in exe or exe.startswith('python')) and float(v[2])>20:raise RuntimeError('Other heavy process: '+line)
quote=lambda x:"'"+str(x).replace("'","''")+"'"
expr=';'.join('addpath('+quote(x)+')' for x in [a.package_root,a.fmm_root,here,here/'search',here/'field',here/'reference'])+';'
expr+="e=example_parameters("+quote('reference' if a.mode=='regression' else 'empty-rotated')+','+str(a.center_width)+','+str(a.right_period)+','+str(a.rotation)+');'
if a.mode!='regression':expr+='e.lead_nodes='+str(a.nodes)+';'
if a.mode=='confirm':
 if a.candidate is None:raise RuntimeError('Confirm requires an explicit same-experiment candidate')
 expr+='confirm_root('+quote(out)+',e,'+repr(a.candidate)+');'
else:expr+='example_run('+quote(out)+','+quote(a.mode)+',e);'
os.environ.update(OMP_NUM_THREADS='11',OPENBLAS_NUM_THREADS='11',MKL_NUM_THREADS='11',VECLIB_MAXIMUM_THREADS='11',OMP_DYNAMIC='FALSE')
command=[a.matlab,'-batch',expr]
if a.mode=='bands':
 if not a.conda:raise RuntimeError('Bands requires explicit --conda')
 os.environ.update(OMP_NUM_THREADS='1',OPENBLAS_NUM_THREADS='1',MKL_NUM_THREADS='1',VECLIB_MAXIMUM_THREADS='1')
 command=[a.conda,'run','--no-capture-output','-n','octave','python','-I',str(here/'bands.py'),'--output',str(out),'--right-period',str(a.right_period),'--center-width',str(a.center_width),'--rotation',str(a.rotation),'--cutoffs']+list(map(str,a.cutoffs))
r=run(out,command);sys.exit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
