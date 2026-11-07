"""Continue the example-1 BIE ladder from explicit fixed-grid measurements.
Input: output parent containing the required fixed configurations and next run number,
      plus the numerical source, MATLAB and FMM paths used by launch.py.
Output: a fresh cold run at each new setting and the coarsening decisions.
"""
import argparse
import json
from pathlib import Path
import subprocess
import sys
from summarize import error_to_reference

p=argparse.ArgumentParser()
for name in ('output','package-root','i9','fmm','fem','matlab'):
  p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--first',type=int,required=True)
a=p.parse_args()
driver=Path(__file__).resolve().with_name('launch.py')
number=a.first
observations={}
decisions=[]

def inspect(folder):
  state=folder/'fallback-001/state.json'
  if not (folder/'result.json').exists() and state.is_file():
    failure=json.loads(state.read_text())
    if failure['status']=='SEARCH_FINISHED_WITH_UNRESOLVED_INTERVALS':
      return dict(run=folder.name,side='unresolved',provisional=failure['candidates'])
  data=json.loads((folder/'result.json').read_text())
  assert data['status']=='COMPLETE' and len(data['candidates'])==1,folder
  root=data['candidates'][0]['k']
  side,distance=error_to_reference(root)
  return dict(run=folder.name,k=root,side=side,distance=str(distance))

for folder in sorted(a.output.glob('run-*')):
  if ((folder/'result.json').exists() or (folder/'fallback-001/state.json').exists()) and (folder/'monitor.json').exists():
    cfg=json.loads((folder/'config.json').read_text())
    if cfg['solver']=='bie':
      observations[cfg['size'],cfg['order']]=inspect(folder)

def test(size,order):
  global number
  key=(size,order)
  if key not in observations:
    folder=a.output/f'run-{number:03d}'
    number+=1
    command=[sys.executable,'-B',str(driver),'--output',str(folder),'--solver','bie',
             '--size',str(size),'--order',str(order)]
    for field in ('package-root','i9','fmm','fem','matlab'):
      command+=['--'+field,str(getattr(a,field.replace('-','_')))]
    completed=subprocess.run(command)
    if completed.returncode and not (folder/'fallback-001/state.json').exists():
      completed.check_returncode()
    observations[key]=inspect(folder)
  entry=dict(size=size,order=order,**observations[key])
  decisions.append(entry)
  (a.output/'coarsening.json').write_text(json.dumps(decisions,indent=2)+'\n')
  print(entry,flush=True)
  return entry['side']=='inside'

for size in (128,192):
  if test(size,32):test(size,24)

# Follow the density axis at the lowest qualifying width on the coarsest
# qualifying fixed density. A known outside point already brackets that axis.
size,order=min(key for key,v in observations.items() if v['side']=='inside')
for lower in [n for n in (192,128,96,64,32,16) if n<size]:
  if not test(lower,order):break
  size=lower

# Follow the Fourier axis independently on this density. Both bracketing
# observations count in the tier comparison, including an outside candidate.
for lower in [m for m in (40,32,24,16,12,8,6,4,2,1,0) if m<order]:
  if not test(size,lower):break
  order=lower
