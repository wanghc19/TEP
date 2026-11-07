"""Run the remaining solver configurations serially in separate cold MATLAB processes.
Input: explicit output parent, first run number, dependency paths and solver settings.
Output: normal scalar and monitor files in each fresh numbered directory.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys

p=argparse.ArgumentParser()
for name in ('output','package-root','i9','fmm','fem','matlab'):
  p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--first',type=int,required=True)
p.add_argument('settings',nargs='+',help='solver,size,order triples')
a=p.parse_args()
driver=Path(__file__).resolve().with_name('launch.py')
for number,setting in enumerate(a.settings,a.first):
  solver,size,order=setting.split(',')
  folder=a.output/f'run-{number:03d}'
  cmd=[sys.executable,'-B',str(driver),'--output',str(folder),'--solver',solver,
       '--size',size,'--order',order]
  for key in ('package-root','i9','fmm','fem','matlab'):
    cmd.extend(['--'+key,str(getattr(a,key.replace('-','_')))])
  subprocess.run(cmd,check=True)
  result=json.loads((folder/'result.json').read_text())
  print(folder.name,setting,result['status'],[c['k'] for c in result['candidates']],flush=True)
  if result['status']!='COMPLETE' or len(result['candidates'])!=1:
    raise RuntimeError('Inspect all returned candidates and search status before continuing.')
