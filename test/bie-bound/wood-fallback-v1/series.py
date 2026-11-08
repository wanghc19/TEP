"""Run explicit study blocks serially under the same monitored compute allowance."""
import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

p=argparse.ArgumentParser(description=__doc__)
for key in ('sequence','output','package-root','fmm','matlab'):
  p.add_argument('--'+key,type=Path,required=True)
p.add_argument('--after',type=Path)
a=p.parse_args()
if a.after:
  while not a.after.exists():
    time.sleep(2)
  record=json.loads(a.after.read_text())
  assert record['reason']=='completed' and record['returncode']==0
  if a.after.parent.name=='run-004':
    rows=[json.loads(f.read_text()) for f in sorted(a.after.parent.glob('search-*.json'))]
    for row in rows:
      peer=next(r for r in rows if r['tag']==row['tag'] and r['N']==row['N'] and r['route']!=row['route'])
      assert row['complete'] and isinstance(row['proposals'],(int,float)) and isinstance(peer['proposals'],(int,float))
      assert abs(row['proposals']-peer['proposals'])<=1e-13
for job in json.loads(a.sequence.read_text()):
  prior=sum(json.loads(f.read_text())['wall_seconds'] for f in a.output.glob('run-*/monitor.json'))
  if prior+job['forecast']>5400:
    print(f'Stopped at {prior:.2f} s before {job["plan"]}, forecast {job["forecast"]} s.',flush=True)
    break
  out=a.output/f"run-{job['run']:03d}"
  cmd=[sys.executable,'-B',str(Path(__file__).with_name('launch.py')),
       '--output',str(out),'--handoff-root',str(a.output),'--plan',str(a.sequence.parent/(job['plan']+'.json')),
       '--max-wall',str(min(1800,int(5399-prior)))]
  for key,path in [('package-root',a.package_root),('fmm',a.fmm),('matlab',a.matlab)]:
    cmd.extend(['--'+key,str(path)])
  subprocess.run(cmd,check=True)
