"""Launch small polynomial certificate checks through the MATLAB monitor.
Input: new output directory. Output: monitor and small JSON diagnostics.
"""
import argparse,json,os,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--output',required=True);a=p.parse_args();here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
q=lambda s:"'"+str(s).replace("'","''")+"'"
expr=f"addpath({q(here)}); library_tests({q(out/'science')});"
(out/'forecast.json').write_text(json.dumps({'seconds':[10,30],'peak_gib':[.5,1.2],'threads':11,'OMP_DYNAMIC':'FALSE'},indent=2))
r=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'))['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
