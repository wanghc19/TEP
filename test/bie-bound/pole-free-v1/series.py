"""Launch the explicit plans in order, using a new monitored MATLAB process per plan.
Input: run sequence, launcher paths, and output parent. Output: numbered run directories.
A failed numerical assertion or a monitor limit stops the sequence.
"""
import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

p=argparse.ArgumentParser(description=__doc__)
for key in ('sequence','output','package-root','matlab','fmm'):
  p.add_argument('--'+key,type=Path,required=True)
p.add_argument('--after',type=Path,help='Wait for the named prerequisite monitor to finish successfully.')
a=p.parse_args()
if a.after:
  while not a.after.exists():
    time.sleep(2)
  prior=json.loads(a.after.read_text())
  if prior['returncode']!=0 or prior['reason']!='completed':
    raise RuntimeError('Prerequisite run did not pass')
for job in json.loads(a.sequence.read_text()):
  used=sum(json.loads(f.read_text())['wall_seconds'] for f in a.output.glob('run-*/monitor.json'))
  if used+job['forecast_seconds']>7200:
    raise RuntimeError('Forecast exceeds cumulative compute allowance')
  dest=a.output/f"run-{job['run']:03d}"
  command=[sys.executable,'-B',str(Path(__file__).with_name('launch.py')),
           '--output',str(dest),'--plan',str(a.sequence.parent/(job['plan']+'.json'))]
  for name,path in [('package-root',a.package_root),('matlab',a.matlab),('fmm',a.fmm)]:
    command.extend(['--'+name,str(path)])
  if job.get('old'):command.append('--old')
  subprocess.run(command,check=True)
  print(dest.name,job['plan'],flush=True)
