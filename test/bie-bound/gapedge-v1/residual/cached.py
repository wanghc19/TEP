# Stage C source: test/bie-bound/example2-v1/residual/cached.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/cached.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/cached.py; pipeline adaptations documented in README.
"""D1 reuse of source geometry and moments on one fixed central curve.
Input: exact field and explicit mesh/degrees. Output: validated in-memory cache.
"""
import json,time
from flint import arb,ctx
from material import Proxy,matrix,translate
from panel import moment_basis,moments
from self_interaction import source_grid

class Sources:
  def __init__(self,data,P,S,n,N):
    ctx.prec=128;start=time.perf_counter();self.key=self.make_key(data,P,S,n,N)
    K=Proxy(data);piece=data['pieces'][0];Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);modes=piece['modes'];hs=arb.pi()/S
    t=time.perf_counter();self.F=moment_basis(modes,hs,n);self.moments=[moments(Ct,Cz,modes,(2*j+1)*hs,self.F) for j in range(S)]
    self.moment_seconds=time.perf_counter()-t;t=time.perf_counter()
    self.jets=[translate((2*j+1)*hs,hs,n,K.k,K.R,K.b,True) for j in range(S)]
    self.geometry_seconds=time.perf_counter()-t;t=time.perf_counter()
    self.grid=source_grid(N,Ct,Cz,modes,K.R,K.b);self.grid_seconds=time.perf_counter()-t
    self.seconds=time.perf_counter()-start
    self.counts=dict(source_jets=S,source_moments=S,kress_points=N,source_transform_complex_entries=S*2*(n+1)*(2*n+3))
  @staticmethod
  def make_key(data,P,S,n,N):
    # Full exact-input equality, not a filename or a density-blind mesh key.
    return (json.dumps(data,sort_keys=True,separators=(',',':')),P,S,n,N,ctx.prec)
  def validate(self,data,P,S,n,N):
    if self.key!=self.make_key(data,P,S,n,N):raise ValueError('Source cache input, geometry, density, wave number, partition, order or precision mismatch')
  def record(self):
    return dict(seconds=self.seconds,moments=self.moment_seconds,geometry=self.geometry_seconds,source_grid=self.grid_seconds,counts=self.counts)
