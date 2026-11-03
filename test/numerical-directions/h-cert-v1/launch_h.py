"""H means hypothesis: launch its monitored endpoint computations.
Input: run output directory and numerical case. Output: monitor and small JSON.
"""
import argparse,json,os,runpy
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--analytic',action='store_true');p.add_argument('--certificate',action='store_true');p.add_argument('--poisson2',action='store_true');p.add_argument('--degree',type=int,default=5);p.add_argument('--phase-order',type=int,default=48);p.add_argument('--output',required=True);p.add_argument('--material',type=float,required=True);p.add_argument('--lambda',dest='endpoint',type=float,required=True);p.add_argument('--order',type=int,default=10);p.add_argument('--phases',type=int,default=128);p.add_argument('--quadrature',type=int,default=20);a=p.parse_args()
here=Path(__file__).resolve().parent;out=Path(a.output).resolve();assert not out.exists();out.mkdir(parents=True)
os.environ['OMP_NUM_THREADS']='11';os.environ['OMP_DYNAMIC']='FALSE'
q=lambda s:"'"+str(s).replace("'","''")+"'"
entry='h_bloch' if a.analytic or a.certificate else 'h_run'
extra=f',[{a.degree},{a.phase_order},{int(a.poisson2)}]' if a.certificate else ''
expr=f"addpath({q(here)}); {entry}({q(out/'science')},{a.material},{a.endpoint},{a.order},{a.phases},{a.quadrature}{extra});"
(out/'forecast.json').write_text(json.dumps({'seconds':([480,1320] if a.certificate else [120,900]),'peak_gib':([1.8,2.8] if a.certificate else [.7,2.5]),'threads':11,'OMP_DYNAMIC':'FALSE'},indent=2))
m=runpy.run_path(str(here.parent/'diagnostics-v1/monitor.py'));r=m['run'](out,expr,soft=1800,hard=2400)
raise SystemExit(0 if r['returncode']==0 and r['reason']=='completed' else 1)
