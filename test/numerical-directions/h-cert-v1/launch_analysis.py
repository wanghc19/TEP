"""Launch the monitored isolation-hypothesis cross-checks.
Input: new run output directory and explicit path manifest. Output: analysis.
"""
import argparse,json,os,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--manifest',required=True);a=p.parse_args()
here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
q=lambda s:"'"+str(s).replace("'","''")+"'"
expr=f"addpath({q(here)}); h_analyze({q(out/'science')},{q(Path(a.manifest).resolve())});"
(out/'forecast.json').write_text(json.dumps({'seconds':[15,45],'peak_gib':[.7,1.2],'threads':11,'OMP_DYNAMIC':'FALSE'},indent=2))
m=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
