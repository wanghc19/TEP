"""Prepare explicit study parameters from the published branch-tracing CSV files.
Input: fixed-frequency and continuation tables; output: JSON plans.
"""
import argparse
import csv
import json
from pathlib import Path

def rows(path):
  with path.open() as f:
    return list(csv.DictReader(f))

def write(path, action, jobs):
  path.write_text(json.dumps(dict(action=action,jobs=jobs),indent=2)+'\n')

def interpolate(points, value):
  return sum(y*product((value-b)/(a-b) for b,_ in points if b!=a) for a,y in points)

def product(xs):
  p=1
  for x in xs:
    p*=x
  return p

p=argparse.ArgumentParser(description=__doc__)
for key in ('fixed','branches','output'):
  p.add_argument('--'+key,type=Path,required=True)
a=p.parse_args()
fixed=rows(a.fixed); trace=rows(a.branches)
base=[]
for x in fixed:
  model=x['model'];t=float(x['delta']);beta=float(x['beta'])
  if model=='w3' and abs(t) not in (.01,.0001): continue
  assert any(r['model']==model and r['finished'].lower()=='true' and float(r['detuning'])==t and float(r['beta'])==beta for r in trace)
  base.append(dict(tag=model+format(t,'+.5f'),model=model,beta=beta,window=[beta-.02,beta+.02],detuning=t,cap=150,control=False))
a.output.mkdir(exist_ok=True)
methods=[('plain',.01),('sqrt',.001),('sqrt',.0001),('plain',.001),('plain',.0001),('sqrt',.00001)]
def searches(cs,mm):
  return [dict(x,route=r,delta=d,N=n,M=m) for x in cs for r,d in mm for n,m in [(128,6),(192,12)]]
ref=[dict(x,N=192,M=12,seed=x['beta']+x['detuning']) for x in base]
write(a.output/'accuracy.json','accuracy',ref)
controls=[dict(x,control=True,full_diagnostics=True,window=[x['beta']+x['detuning']-.002,x['beta']+x['detuning']+.002]) for x in base if abs(x['detuning'])==.1]
write(a.output/'regular.json','batch',searches(controls,[('plain',.0001),('sqrt',.0001)]))
points=[(x['detuning'],x['beta']) for x in base if x['model']=='ex1' and abs(x['detuning'])<=.001]
scan=[]
for t in [-.0005,-.0004,-.0003,-.0002,-.00012,-.00008,-.00004,0,.00004,.00008,.00012,.0002,.0003,.0004,.0005]:
  beta=interpolate(points,t)
  scan.append(dict(tag='scan'+format(t,'+.5f'),model='ex1',beta=beta,window=[beta-.02,beta+.02],detuning=t,cap=150,control=False))
write(a.output/'scan-phases.json','parameters',scan)
# Mix the two signs and excluded/interior cases within each monitored block.
order=[7,4,10,0,14,5,9,1,13,2,6,8,3,11,12]
for i in range(0,len(scan),5):
  write(a.output/f'scan-{1+i//5}.json','batch',searches([scan[j] for j in order[i:i+5]],[('sqrt',.0001)]))
for j,case in enumerate(base):
  write(a.output/f'ladder-{j+1:02d}.json','batch',searches([case],methods))
