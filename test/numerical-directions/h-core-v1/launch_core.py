"""Core certificate monitored MATLAB launcher.
Input: fresh run output, cutoffs, trapezoid nodes, left/right numerical matrices.
Output: monitor records and small JSON scientific results.
"""
import argparse,json,os,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--mode',choices=['count','validate'],default='count');p.add_argument('--output',required=True);p.add_argument('--Nx',type=int,required=True);p.add_argument('--Ny',type=int,required=True);p.add_argument('--nodes',type=int,required=True);p.add_argument('--left',required=True);p.add_argument('--right',required=True);a=p.parse_args()
here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE';q=lambda x:"'"+str(x).replace("'","''")+"'"
expr=f"addpath({q(here)});core_run({q(out/'science')},{a.Nx},{a.Ny},{a.nodes},{q(Path(a.left).resolve())},{q(Path(a.right).resolve())});"
if a.mode=='validate':expr=f"addpath({q(here)});core_validate({q(out/'science')},{q(Path(a.left).resolve())},{q(Path(a.right).resolve())});"
(out/'forecast.json').write_text(json.dumps({'seconds':[60,240] if a.Nx<20 else [120,480],'peak_gib':[.8,1.8] if a.Nx<20 else [1,2.3],'threads':11,'OMP_DYNAMIC':'FALSE'},indent=2))
m=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
