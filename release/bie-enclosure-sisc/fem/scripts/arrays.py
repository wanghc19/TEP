"""Open canonical arrays for the finite element method comparison.
Input: MATLAB version-5 transport files or a JSON dictionary plus NPZ arrays.
Output: lossless numeric arrays (no pickle) and version-5 run-local transport.
NPZ means a ZIP collection of NumPy arrays; JSON describes structs/cells/shapes.
"""
import json,warnings
from pathlib import Path
import numpy as np
from scipy.io import loadmat,savemat

def read_pair(path):
  # MATLAB may store a double array using an integer compressed representation.
  # mat_dtype=True recovers the MATLAB class, but may discard complex imaginary
  # parts. Read values separately and use the second read only as class metadata.
  raw=loadmat(path)
  with warnings.catch_warnings():
    warnings.simplefilter('ignore');typed=loadmat(path,mat_dtype=True)
  return raw,typed

def numeric_class(a,typed):
  if isinstance(typed,np.ndarray) and not a.dtype.names and a.dtype!=object:
    dtype=typed.dtype
    if a.dtype.kind=='c':
      assert dtype.kind in 'fc'
      dtype=np.dtype('complex64' if dtype.itemsize<=4 else 'complex128') if dtype.kind=='f' else dtype
    return a.astype(dtype,copy=False)
  return a

def export(source,destination):
  source=Path(source);destination=Path(destination);arrays={}
  def encode(a,typed=None):
    a=np.asarray(a)
    if a.dtype==object and a.size and all(v is None for v in a.flat):
      return dict(kind='empty_struct',shape=list(a.shape))
    if a.dtype.names:
      return dict(kind='struct',shape=list(a.shape),fields=list(a.dtype.names),values=[[encode(a.flat[i][f],typed.flat[i][f]) for f in a.dtype.names] for i in range(a.size)])
    if a.dtype==object:return dict(kind='cell',shape=list(a.shape),values=[encode(v,typed.flat[i]) for i,v in enumerate(a.flat)])
    a=numeric_class(a,typed)
    key=f'array_{len(arrays):06d}';arrays[key]=a;return dict(kind='array',key=key,shape=list(a.shape),dtype=a.dtype.str)
  raw,typed=read_pair(source)
  data={k:encode(v,typed[k]) for k,v in raw.items() if not k.startswith('__')}
  destination.with_suffix('.json').write_text(json.dumps(dict(format='numpy-struct-v1',matlab_class_preserved=True,variables=data),indent=2)+'\n')
  np.savez_compressed(destination.with_suffix('.npz'),**arrays)
  return sum(p.stat().st_size for p in [destination.with_suffix('.json'),destination.with_suffix('.npz')])

def materialize(source,destination):
  source=Path(source);meta=json.loads(source.with_suffix('.json').read_text())
  assert meta['format']=='numpy-struct-v1' and meta['matlab_class_preserved']
  with np.load(source.with_suffix('.npz'),allow_pickle=False) as arrays:
    def decode(x):
      if x['kind']=='array':
        a=arrays[x['key']];assert list(a.shape)==x['shape'] and a.dtype.str==x['dtype'];return a
      if x['kind']=='empty_struct':
        assert x['shape']==[1,1], 'Only scalar empty structs are supported'
        return {}
      if x['kind']=='cell':
        a=np.empty(x['shape'],dtype=object)
        for i,v in enumerate(x['values']):a.flat[i]=decode(v)
        return a
      assert x['kind']=='struct';a=np.empty(x['shape'],dtype=[(f,object) for f in x['fields']])
      for i,row in enumerate(x['values']):
        for f,v in zip(x['fields'],row):a.flat[i][f]=decode(v)
      return a
    data={k:decode(v) for k,v in meta['variables'].items()}
    savemat(destination,data,do_compression=True,long_field_names=True)

def equal_mat(a,b):
  def same(x,tx,y,ty):
    if x is None or y is None:return x is y
    if x.shape!=y.shape:return False
    if x.dtype.names:
      if x.dtype.names!=y.dtype.names:return False
      return all(same(x.flat[i][f],tx.flat[i][f],y.flat[i][f],ty.flat[i][f]) for i in range(x.size) for f in x.dtype.names)
    if x.dtype==object:
      if y.dtype!=object:return False
      return all(same(u,tu,v,tv) for u,tu,v,tv in zip(x.flat,tx.flat,y.flat,ty.flat))
    x=numeric_class(x,tx);y=numeric_class(y,ty)
    return x.dtype==y.dtype and x.tobytes(order='C')==y.tobytes(order='C')
  x,tx=read_pair(a);y,ty=read_pair(b)
  return all(same(x[k],tx[k],y[k],ty[k]) for k in x if not k.startswith('__'))
