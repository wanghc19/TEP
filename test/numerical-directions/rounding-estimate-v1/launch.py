"""Launch instrumented MATLAB estimates under the existing monitor.
Input: band/core/qj action and a fresh output directory. Output: monitored run.
"""
import argparse,os,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('action',choices=['band','core','qj','dtn-left','dtn-right','qj-cert','field','gauss']);p.add_argument('--output',required=True);a=p.parse_args();here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE';os.environ['OPENBLAS_NUM_THREADS']='11'
q=lambda s:"'"+str(s).replace("'","''")+"'"
if a.action=='gauss':expr=f"addpath({q(here)});gauss_export({q(out/'science')});"
elif a.action=='band':expr=f"addpath({q(here/'band')});band_estimate({q(out/'science')});"
elif a.action=='core':
  inputs=here.parent/'h-dtn-v1';expr=f"addpath({q(here/'core')});r=core_estimate({q(out/'science')},31,16,512,{q(inputs/'left-certificate.json')},{q(inputs/'right-certificate.json')});assert(abs(r.gamma_2/0.3653736908439648-1)<1e-9);rounding_scalars({q(out/'science')});"
elif a.action.startswith('dtn-'):expr=f"addpath({q(here/'dtn')});dtn_estimate({q(out/'science')},{q(a.action[4:])},'g48',4,24,false,12);"
elif a.action=='field':expr=f"addpath({q(here/'qj')});field_export({q(out/'science')});"
elif a.action=='qj-cert':expr=f"addpath({q(here/'qj')});rounding_qj_run({q(out/'science')},true);"
else:expr=f"addpath({q(here/'qj')});rounding_qj_run({q(out/'science')});"
m=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400);raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
