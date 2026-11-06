# Copied from test/bie-bound/pipeline-v1/residual/lead_self.py.
# Copied from test/bie-bound/grouprel-v1/lead_self.py; pipeline adaptations documented in README.
"""Kress self-interaction for all 194 lead density columns.
Input: lead geometry, both material wave numbers and full Fourier maps.
Output: matrix polynomial, SI5/SI8 error and domain/timing ledger.
"""
import time
from flint import arb,acb,acb_mat,ctx
from material import I,geom,up
from self_interaction import Radial,self_domain,free_blocks,divided_chord
from chebyshev import sharp
from expansion import norm
from map_models import interpolate

def source(K,Ct,Cz,modes,N):
  nc=Ct.ncols();vals=[]
  for C in [Ct,Cz]:
    cols=[]
    for l in range(nc):
      co=[acb(0)]*N
      for j,m in enumerate(modes):co[m%N]+=C[j,l]*N
      cols.append(acb.dft(co,inverse=True))
    vals.append(cols)
  grid=[];V=acb_mat(2*N,nc)
  for j in range(N):
    s=2*arb.pi()*j/N;x,y,dx,dy=geom(s,K.R,K.b);speed=(dx*dx+dy*dy).sqrt();grid.append((s,x,y,dy/speed,-dx/speed))
    for l in range(nc):V[j,l]=speed*vals[0][l][j];V[N+j,l]=speed*vals[1][l][j]
  return grid,V

def kernel(t,K,rad,grid):
  N=len(grid);n=N//2;x,y,dx,dy=geom(t,K.R,K.b);speed=(dx*dx+dy*dy).sqrt();nx=dy/speed;ny=-dx/speed;co=[acb(0)]*N
  for m in range(1,n+1):
    zp=(I*m*t).exp();zm=(-I*m*t).exp()
    if m==n:co[n]=-(zp+zm)/(2*n)
    else:co[m]=-zp/m;co[-m]=-zm/m
  weights=acb.dft(co);H=acb_mat(2,2*N);weight=2*arb.pi()/N*speed.sqrt()
  for j,(s,u,v,mx,my) in enumerate(grid):
    delta=(x-u,y-v);q=delta[0]**2+delta[1]**2;cx,cy=divided_chord(t,s,K.R,K.b);ch=cx*cx+cy*cy
    A,B=free_blocks(rad,q,ch.log(),delta,(nx,ny),(mx,my),(cx,cy),ch)
    for r in range(2):
      H[r,j]=weight*(weights[j]*A[2*r]+B[2*r]);H[r,N+j]=weight*(weights[j]*A[2*r+1]+B[2*r+1])
  return H

def compute(K,Ct,Cz,modes,ct,ht,N=1152,rt=None):
  start=time.perf_counter();ctx.prec=192;rad=Radial(K.k,arb(17));rt=arb('.12') if rt is None else rt;a=arb('.16');rho=arb('4.5');assert ht*(rho+1/rho)/2<rt
  t=time.perf_counter();HA0,HB0,large=self_domain(K.k,K.R,K.b,ct,rt,a,Ct,Cz,modes,rad);HA,HB,small=self_domain(K.k,K.R,K.b,ct,ht,a,Ct,Cz,modes,rad);domain=time.perf_counter()-t
  M=2*HA0/((a-rt).exp()-1)+HB0;L=48
  while 4*M*rho**(1-L)/(rho-1)>arb('2e-18'):L+=1
  source_error=sharp(HA,HB,a,N);ctx.prec=128;t=time.perf_counter();grid,V=source(K,Ct,Cz,modes,N);cachetime=time.perf_counter()-t
  nodes=[];finite=arb(0);kernel_time=0.;algebra=0.
  for l in range(L):
    x=(arb.pi()*(2*l+1)/(2*L)).cos();t=time.perf_counter();H=kernel(ct+ht*x,K,rad,grid);kernel_time+=time.perf_counter()-t
    t=time.perf_counter();v=H*V;mid=acb_mat(2,V.ncols(),[v[i,j].mid() for i in range(2) for j in range(V.ncols())]);finite=max(finite,norm(v-mid));nodes.append(mid);algebra+=time.perf_counter()-t
  ctx.prec=192;t=time.perf_counter();cf,conv=interpolate(nodes);conversion=time.perf_counter()-t;tail=4*M*rho**(1-L)/(rho-1);e=tail+(2*arb(L)-1).sqrt()*(source_error+finite)+conv
  rec=dict(columns=Ct.ncols(),N=N,L=L,Rt=str(rt),source_strip=str(a),large=large,small=small,M=up(M),source_error=up(source_error),finite_radius=up(finite),interpolation_tail=up(tail),conversion=up(conv),e_self=up(e),times=dict(domains=domain,source_cache=cachetime,kernel=kernel_time,state_algebra=algebra,conversion=conversion),seconds=time.perf_counter()-start)
  return cf,e,rec
