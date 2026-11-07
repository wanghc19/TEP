"""Run the two literature modes serially on the declared density and Fourier grid.
Input: explicit source/dependency paths, output parent and first run number.
Output: one numbered monitored run per mode and resolution plus a compact ledger.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

p=argparse.ArgumentParser()
for key in ('package-root','fmm','matlab','output'):
  p.add_argument('--'+key,type=Path,required=True)
p.add_argument('--first',type=int,required=True)
p.add_argument('--mode',choices=['fundamental','second'],required=True)
a=p.parse_args()
runner=Path(__file__).resolve().with_name('launch.py')
previous=[]
for j,(n,m) in enumerate((n,m) for n in [64,128,256] for m in [12,24]):
  folder=a.output/f'run-{a.first+j:03d}'
  command=[sys.executable,'-B',str(runner),'--package-root',str(a.package_root),'--fmm',str(a.fmm),
    '--matlab',str(a.matlab),'--output',str(folder),'--size',str(n),'--order',str(m),'--mode',a.mode]
  subprocess.run(command,check=True)
  data=json.loads((folder/'benchmark.json').read_text())
  # A lost or additional mode calls for inspection before starting another mesh.
  if len(data['candidates'])!=1 or data['status']!='COMPLETE':
    raise RuntimeError(f'Inspect candidate list in {folder}')
  value=data['candidates'][0]['normalized_frequency']
  previous.append(value)
  if len(previous)>1 and max(previous)-min(previous)>=(0.01 if a.mode=='fundamental' else 0.00006):
    raise RuntimeError(f'Refinement exceeds printed or graphical resolution in {folder}')
  print(a.mode,n,m,value,flush=True)
