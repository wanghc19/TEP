"""Run explicit probe plans serially, preserving all monitored outputs."""
import argparse,json,subprocess,sys
from pathlib import Path
p=argparse.ArgumentParser()
for k in ('output','package-root','fmm','matlab'):p.add_argument('--'+k,type=Path,required=True)
p.add_argument('--first',type=int,required=True);p.add_argument('plans',nargs='+',type=Path)
a=p.parse_args()
for n,plan in enumerate(a.plans,a.first):
  used=sum(json.loads(f.read_text())['wall_seconds'] for f in a.output.glob('run-*/monitor.json'))
  if used>=7100:raise RuntimeError('Aggregate compute budget reached')
  out=a.output/f'run-{n:03d}';cmd=[sys.executable,'-B',str(Path(__file__).with_name('launch.py')),'--output',str(out),'--plan',str(plan)]
  for k in ('package-root','fmm','matlab'):cmd+=['--'+k,str(getattr(a,k.replace('-','_')))]
  subprocess.run(cmd,check=True);print(n,plan.name,flush=True)
