"""Launch spectral gap endpoint checks through the existing resource monitor.
Input: stage and a new output directory. Output: logs, scalar JSON and CSV.
"""
import argparse, json, os, runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--stage',choices=['baseline','scan'],required=True);p.add_argument('--output',required=True)
a=p.parse_args();here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists()
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
quote=lambda x:"'"+str(x).replace("'","''")+"'"
expr=f"addpath({quote(here)}); gap_run({quote(a.stage)},{quote(out/'science')});"
monitor=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'))
out.mkdir(parents=True)
(out/'forecast.json').write_text(json.dumps({'stage':a.stage,'seconds':[120,300] if a.stage=='baseline' else [300,900],'peak_gib':[2.2,2.7] if a.stage=='baseline' else [2.0,2.7],'threads':11,'OMP_DYNAMIC':'FALSE'},indent=2))
r=monitor['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['reason']=='completed' and r['returncode']==0 else 1)
