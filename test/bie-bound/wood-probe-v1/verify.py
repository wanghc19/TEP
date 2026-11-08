"""Check Wood-probe records and the two equivalent lead pencils.
Input: explicit experiment directory with completed runs.
Output: results/checks.json and pencil-checks.csv (comma-separated values).
"""
import argparse
import csv
import json
import math
import os
from pathlib import Path
import numpy as np
from scipy.linalg import ordqz

p=argparse.ArgumentParser()
for name in ['experiment','pilot','samples','chebyshev','controls']:
  p.add_argument('--'+name,type=Path,required=True)
p.add_argument('--extra-run',type=Path,action='append',default=[])
a=p.parse_args();root=a.experiment
def read(name):
  return json.loads((root/name).read_text())
def cx(v):
  return np.asarray(v['real'])+1j*np.asarray(v['imag'])
def stable(A,B):
  scale=np.hypot(np.linalg.norm(A),np.linalg.norm(B))
  S,T,alpha,beta,Q,Z=ordqz(A/scale,B/scale,sort='iuc',output='complex')
  count=int(sum(np.abs(alpha)<np.abs(beta)))
  return Z[:,:count],count

samples=json.loads((a.samples/'samples.json').read_text());cheb=json.loads((a.chebyshev/'chebyshev.json').read_text());s=read('results/summary.json')
reg=json.loads((a.pilot/'regression.json').read_text())
assert abs(reg['k']-1.558437894182088)<=2e-14
assert len(samples)==84 and len(cheb)==132
assert all(r['common_gap'] for r in samples)
assert all(r['k']!=abs(r['beta']) for r in samples+cheb)
roundtrip=max(r[c]['roundtrip_relative'] for r in samples if abs(r['t'])==.1 for c in ['lead','center'])
assert roundtrip<=1e-12
assert all(r['points']>=4 and 'maximum_grid_difference' in r for r in s['root_fits']+s['late_fits']+s['condition_fits']+s['green_fits'])

rows=[]
for r in samples:
  if r['N']!=128 or abs(r['t']) not in [.1,.0001,.0000001]:continue
  S=cx(r['lead']['S_common']);D=cx(r['lead']['D_common']);n=13;I=np.eye(n);O=np.zeros((n,n));
  g=np.sqrt((r['k']**2-(r['beta']+2*np.pi*np.arange(-6,7))**2).astype(complex));G=np.diag(g)
  A=np.block([[-S[:n,:n],I],[S[n:,:n],O]]);B=np.block([[O,S[:n,n:]],[I,-S[n:,n:]]])
  Ac=np.block([[-D[:n,:n],-I],[D[n:,:n],O]]);Bc=np.block([[D[:n,n:],O],[-D[n:,n:],I]])
  Za,na=stable(B,A);Zc,nc=stable(Bc,Ac);assert na==nc==n
  C=np.block([[I,I],[1j*G,-1j*G]]);mapped=np.linalg.qr(C@Za,mode='reduced')[0]
  angle=np.linalg.norm(mapped-Zc@(Zc.conj().T@mapped),2)
  rows.append(dict(beta=r['beta'],t=r['t'],amplitude_count=na,cauchy_count=nc,
    maximum_principal_sine=float(angle),coordinate_condition=float(np.linalg.cond(C))))
with (root/'results/pencil-checks.csv').open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
monitors=[json.loads((path/'monitor.json').read_text()) for path in [a.pilot,a.samples,a.chebyshev,a.controls]+a.extra_run]
assert all(m['returncode']==0 and m['reason']=='completed' for m in monitors)
assert all(m['peak_process_tree_rss_gib']<=2 and m['wall_seconds']<=2400 for m in monitors)
assert not list(root.rglob('*.mat'))
size=sum((Path(d)/f).lstat().st_size for d,ds,fs in os.walk(root,followlinks=False) for f in fs)
assert size<50_000_000
result=dict(regression_error=abs(reg['k']-1.558437894182088),roundtrip_at_point_one=roundtrip,
  sample_count=len(samples),chebyshev_points=len(cheb),all_samples_common_gap=True,
  every_exponent_has_range_and_grid_difference=True,pencil_tests=rows,
  total_monitored_seconds=sum(m['wall_seconds'] for m in monitors),peak_rss_gib=max(m['peak_process_tree_rss_gib'] for m in monitors),
  experiment_bytes=size,field_mat_files=0,required_checks='PASS')
(root/'results/checks.json').write_text(json.dumps(result,indent=2))
print(json.dumps({k:v for k,v in result.items() if k!='pencil_tests'},indent=2))
