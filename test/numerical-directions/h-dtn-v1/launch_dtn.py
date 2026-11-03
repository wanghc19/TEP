"""DtN means Dirichlet-to-Neumann: launch monitored certificate calculations.
Input: a fresh output directory and numerical mode. Output: monitor and JSON.
"""
import argparse,json,os,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--inputs');p.add_argument('--mode',choices=['baseline','run','compare','analyze'],default='run');p.add_argument('--side',default='left');p.add_argument('--group',default='g24');p.add_argument('--degree',type=int,default=4);p.add_argument('--order',type=int,default=16);p.add_argument('--certify',type=int,default=0);p.add_argument('--lift',type=float,default=0);a=p.parse_args()
here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE';q=lambda x:"'"+str(x).replace("'","''")+"'"
if a.mode=='compare':expr=f"dtn_compare({q(out/'science')});"
elif a.mode=='analyze':expr=f"dtn_analyze({q(out/'science')},{q(Path(a.inputs).resolve())});"
elif a.mode=='baseline':expr=f"dtn_baseline({q(out/'science')});"
else:expr=f"dtn_run({q(out/'science')},{q(a.side)},{q(a.group)},{a.degree},{a.order},{a.certify},{a.lift});"
expr=f"addpath({q(here)});"+expr
(out/'forecast.json').write_text(json.dumps({'seconds':[120,240] if a.mode=='baseline' else [180,1500],'peak_gib':[1.8,2.6],'threads':11,'OMP_DYNAMIC':'FALSE'},indent=2))
m=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
