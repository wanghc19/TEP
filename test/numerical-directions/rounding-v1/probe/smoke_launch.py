"""Smoke launch through the existing MATLAB resource monitor.
Input: fresh run output directory. Output: small MAT and monitoring records.
"""
import argparse,runpy,os,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--output',required=True);a=p.parse_args()
here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
q=lambda x:"'"+str(x).replace("'","''")+"'"
expr=f"addpath({q(here)});smoke_export({q(out/'science')});"
m=runpy.run_path(str(here.parent.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
