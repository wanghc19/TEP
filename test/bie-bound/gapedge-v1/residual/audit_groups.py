# Stage C source: test/bie-bound/example2-v1/residual/audit_groups.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/audit_groups.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/audit_groups.py; pipeline adaptations documented in README.
"""Independent decimal-outward five-group sum and coverage audit.
Input: explicit completed run directory. Output: final scalar bounds and checks.
"""
import argparse,json,sys,time,gzip
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,ctx
from material import up,dump
def read(path):
  path=Path(path);r=json.loads(gzip.decompress(path.read_bytes()) if path.suffix=='.gz' else path.read_text())
  return read(path.parent/r['archive']) if 'archive' in r else r
p=argparse.ArgumentParser();p.add_argument('--run',required=True);p.add_argument('--output',required=True);a=p.parse_args();root=Path(a.run);out=Path(a.output);ctx.prec=192;start=time.perf_counter();cpu=time.process_time();r=read(root/'summary.json');assert r['passed'] and not r['pilot'];rows=r['tasks'];g=r['groups'];expected={('center',0,i) for i in range(192)}|{('material',s,i) for s in [1,2] for i in range(64)}|{(k,s,i) for k in ['junction','interior'] for s in [1,2] for i in range(16)}|{('seam',s,i) for s in [0,1,2] for i in range(8)}|{('references',0,0)}
if r.get('empty_center',False):expected={x for x in expected if x[0]!='center'}
keys=[(x['kind'],x.get('side',0),x.get('index',0)) for x in rows];assert len(keys)==len(expected) and set(keys)==expected
vals=[arb(0) for _ in range(5)];checks=[]
for x in rows:
  if x['kind']=='center':
    cover=[]
    for l in x['center']['leaves']:
      h=arb.pi()/(192*2**l['depth']);e=sum((arb(str(l[k])) for k in ['e_self','local_tail','e_smooth','combination_error']),arb(0));vals[0]+=(arb(l['V']).upper().sqrt()+(2*h).sqrt()*e)**2;cover.append((l['sub']/2**l['depth'],(l['sub']+1)/2**l['depth']))
    cover.sort();assert cover[0][0]==0 and cover[-1][1]==1 and all(a[1]==b[0] for a,b in zip(cover,cover[1:]))
  elif x['kind']=='junction':vals[3]+=arb(str(x['upper_squared'][0]))
  elif x['kind']=='seam' and x['side']==0:vals[4]+=arb(str(x['upper_squared'][0]))
  if 'gauss_relative' in x:checks.append(dict(kind=x['kind'],side=x['side'],index=x['index'],relative=x['gauss_relative']));assert x['gauss_relative']<1e-12
for tr in g['tails']:
  kind=tr['kind'];side=tr['side'];n=tr['N'];rr=[x for x in rows if x.get('kind')==kind and x.get('side')==side];f=sum((arb(str(x['upper_squared'][j])) for x in rr for j in range(n)),arb(0));slot=side if kind=='material' else 3 if kind=='interior' else 4;vals[slot]+=f+arb(str(tr['tail_squared']));assert tr['relative_tail']<=float(tr.get('tail_ratio_target','1e-6')) and arb(tr['overlap_lower'])>0
es=[v.sqrt() for v in vals]
assert all(arb(str(x))>=y for x,y in zip(g['epsilon_upper'],es)), 'Readback upper bounds too small'
rec=dict(epsilon_upper=list(map(up,es)),coverage_targets=len(expected)-1,Gauss_checks=checks,max_Gauss_relative=max(x['relative'] for x in checks),all_passed=True,seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu)
dump(out/'summary.json',rec)
