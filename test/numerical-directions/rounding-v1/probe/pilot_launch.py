"""Pilot MATLAB/Python stages, both monitored by the existing MATLAB runner.
Input: fresh output directory; export or proof mode. Output: small pilot data.
"""
import argparse,os,runpy,shlex,shutil,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--mode',choices=['export','proof'],required=True);p.add_argument('--output',required=True);p.add_argument('--left');p.add_argument('--right');p.add_argument('--mat');a=p.parse_args()
here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE';os.environ['OPENBLAS_NUM_THREADS']='11'
q=lambda s:"'"+str(s).replace("'","''")+"'"
if a.mode=='export':
 expr=f"addpath({q(here/'pilot')});r=pilot_core_run({q(out/'science')},31,16,512,{q(Path(a.left).resolve())},{q(Path(a.right).resolve())});assert(abs(r.gamma_2/0.3653736908439648-1)<1e-12);"
else:
 args=[shutil.which('conda'),'run','-n','octave','python','-I',str(here/'pilot_verify.py'),'--mat',str(Path(a.mat).resolve()),'--output',str(out/'science')]
 command=' '.join(shlex.quote(x) for x in args);expr=f"status=system({q(command)});assert(status==0,'pilot:Python','Arb verification failed.');"
(out/'forecast.json').write_text(json.dumps({'seconds':[30,120] if a.mode=='export' else [300,1500],'peak_gib':[.8,1.3] if a.mode=='export' else [1.5,2.8],'threads':11},indent=2))
m=runpy.run_path(str(here.parent.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400);raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
