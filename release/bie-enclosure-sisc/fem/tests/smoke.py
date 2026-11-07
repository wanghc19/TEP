"""Finite element method canonical-array and interval smoke test.
Input: explicit canonical data and reference directories. Output: PASS lines.
This is a small structural check, not a substitute for the integral verifier.
"""
import argparse,json,sys
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--data',type=Path,required=True);p.add_argument('--reference',type=Path,required=True);a=p.parse_args()
for name in ['native','flux']:
  m=json.loads((a.data/(name+'.json')).read_text());assert m['format']=='numpy-struct-v1'
  import numpy as np
  paths={}
  def array_paths(x,path):
    if x['kind']=='array':paths[x['key']]=path
    elif x['kind']=='struct':
      for row in x['values']:
        for field,value in zip(x['fields'],row):array_paths(value,path+'.'+field)
    elif x['kind']=='cell':
      for i,value in enumerate(x['values']):array_paths(value,path+f'[{i}]')
  for key,value in m['variables'].items():array_paths(value,key)
  placeholders={'example.discretization.native.'+f for f in ('k0','mu0','window')}
  with np.load(a.data/(name+'.npz'),allow_pickle=False) as z:
    assert len(z)>0
    for key in z.files:
      v=z[key];assert v.dtype!=object
      if v.dtype.kind in 'fc' and not np.isfinite(v).all():
        # Only search-configuration placeholders are nonfinite, never the field.
        assert name=='native' and paths[key] in placeholders and np.isnan(v).all(),paths[key]
        print('PASS unused initial search placeholder',paths[key])
      if v.dtype.kind in 'US':assert not any(prefix in str(v) for prefix in ['/'+'Users/','/'+'home/','/'+'private/','/'+'Applications/'])
  print('PASS',name,'open canonical arrays')
r=json.loads((a.reference/'interval.json').read_text());h=json.loads((a.reference/'isolation.json').read_text())
assert r['four_corner']['pass'] and h['H'] and h['negative_count']==1
assert h['alpha'][0]<r['I_1']['endpoints'][0]<r['I_1']['endpoints'][1]<h['alpha'][1]
assert all(x>0 for x in h['intersection_margins'])
print('PASS independent spectral intersection and isolation')
