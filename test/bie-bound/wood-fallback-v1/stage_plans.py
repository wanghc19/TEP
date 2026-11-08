"""Build a sequence of explicit outer-panel handoffs for the remaining widths.
Input: prepared plans, run output root and first run number. Output: numbered plans.
"""
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--plans',required=True,type=Path);p.add_argument('--output',required=True,type=Path)
a=p.parse_args();plans=a.plans;out=a.output.resolve()
cases={i:json.loads((plans/f'nested-{i:02d}.json').read_text())['jobs'] for i in range(1,13)}
# 008 and 009 cover cases 03 and 11. Reuse the directly measured pilot search when available.
seen={}
for label,ns,route,delta,dirname,index in [
  (4,128,'plain',.01,2,1),(4,128,'sqrt',.0001,2,2),(4,128,'plain',.0001,2,3),
  (4,128,'sqrt',.00001,2,4),(4,192,'plain',.01,6,1),(4,192,'sqrt',.0001,6,2),
  (9,128,'plain',.01,7,1),(9,192,'plain',.01,7,2),(9,128,'sqrt',.001,7,3),(9,192,'sqrt',.001,7,4),
  (9,128,'sqrt',.0001,7,5),(9,192,'sqrt',.0001,7,6)]:
  seen[(label,ns,route,delta)]=f'run-{dirname:03d}/search-{index:03d}.json'
seq=[]
def block(number,name,indices,methods,guess):
  jobs=[]
  for i in indices:
    for x in cases[i]:
      for (route,delta) in methods:
        key=(i,x['N'],route,delta)
        if key in seen:continue
        if delta==.01:parent=''
        else:
          up={.001:.01,.0001:.001,.00001:.0001}[delta]
          parent=seen[(i,x['N'],'plain' if up==.01 else route,up)]
          if parent.startswith(f'run-{number:03d}/'):parent='this/'+parent.split('/')[1]
        jobs.append(dict(x,route=route,delta=delta,parent_file=parent))
        seen[key]=f'run-{number:03d}/strip-{len(jobs):03d}.json'
  if jobs:
    (plans/(name+'.json')).write_text(json.dumps(dict(action='strips',handoff_root=str(out),jobs=jobs),indent=2))
    seq.append(dict(plan=name,run=number,forecast=guess))
def extra(number,name,guess):
  seq.append(dict(plan=name,run=number,forecast=guess))
common=[('plain',.01),('plain',.001),('sqrt',.001)]
# Include both signs, both models and both resolution levels before the narrowest exclusions.
block(10,'outer-a',[2,7,4],common,780)
# The pilots already covered the full 0.0001 exclusions at these phases.
outer=plans/'outer-a.json';o=json.loads(outer.read_text())
for i,n in [(4,192),(9,128),(9,192)]:
  q=next(x for x in cases[i] if x['N']==n)
  o['jobs'].append(dict(q,route='sqrt',delta=.00001,parent_file=seen[(i,n,'sqrt',.0001)]))
  seen[(i,n,'sqrt',.00001)]=f'run-010/strip-{len(o["jobs"]):03d}.json'
outer.write_text(json.dumps(o,indent=2))
extra(11,'scan-1',440)
block(12,'outer-b',[5,6,10,12,9],common,500)
extra(13,'scan-2',440)
block(14,'outer-c',[1,8],common,290)
ws=json.loads((plans/'nested-12.json').read_text())['jobs'][1]
cfg=plans/'outer-c.json';payload=json.loads(cfg.read_text())
payload['secondary_parent']=seen[(12,192,'plain',.01)]
payload['secondary_config']=ws
cfg.write_text(json.dumps(payload,indent=2)+'\n')
extra(15,'scan-3',440)
block(16,'narrow-w3',[10],[('sqrt',.0001),('plain',.0001),('sqrt',.00001)],600)
block(17,'narrow-edge',[4,5],[('sqrt',.0001),('plain',.0001),('sqrt',.00001)],620)
block(18,'narrow-mode',[2,7,6],[('sqrt',.0001),('plain',.0001),('sqrt',.00001)],900)
block(19,'narrow-outside',[1,8],[('sqrt',.0001),('plain',.0001),('sqrt',.00001)],680)
(plans/'remaining.json').write_text(json.dumps(seq,indent=2))
