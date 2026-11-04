"""Launch acceleration probe with the unchanged resident set size (RSS) monitor.
Input: new output directory. Output: compact MATLAB and monitor records.
"""
import argparse,json,os,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--entry',choices=['accel_probe','accel_sweep','accel_iterations'],default='accel_probe');a=p.parse_args()
here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
q=lambda s:"'"+str(s).replace("'","''")+"'"
expr=f"addpath({q(here)}); {a.entry}({q(out/'science')});"
(out/'forecast.json').write_text(json.dumps({'seconds':([350,550] if a.entry=='accel_iterations' else [1100,1650]),'peak_gib':[2.1,2.6],'threads':11,'OMP_DYNAMIC':'FALSE'},indent=2))
m=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
