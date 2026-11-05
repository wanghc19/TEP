"""Global regular Helmholtz proxy expansion with source aggregation.
Input: exact field, physical/source degrees and certified domains.
Output: coefficient balls, source-error ledger and point evaluations.
"""
import time
from flint import arb,acb,acb_mat,ctx
from material import I,Proxy,matrix,translate,up,dump,geom
from panel import moment_basis,moments,absolute_vec

def norm(v):
  return sum((abs(z).upper()**2 for z in v),arb(0)).sqrt().upper()

class Aggregation:
  def __init__(self,data,domain,M,n,S,rs,count,out,bits=128):
    ctx.prec=bits;ctx.cap=max(73,n+1);self.K=K=Proxy(data);self.dom=domain;self.M=M;self.n=n;self.S=S;self.R=domain['R'];self.rs=rs;self.bits=bits
    start=time.perf_counter();cpu=time.process_time();self.times=dict(moment_basis=0.,moments=0.,source_geometry=0.,source_contraction=0.,harmonics=0.,harmonic_contraction=0.,normalization=0.)
    piece=data['pieces'][0];Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);modes=piece['modes'];hs=arb.pi()/S
    t=time.perf_counter();F=moment_basis(modes,hs,n);self.times['moment_basis']=time.perf_counter()-t
    V=acb_mat(2*M+3,1);self.sources=[];records=[];moment_sum=arb(0)
    for j in range(count):
      c=(2*j+1)*hs;t=time.perf_counter();mom,dm=moments(Ct,Cz,modes,c,F);self.times['moments']+=time.perf_counter()-t
      t=time.perf_counter();sv,sn,x,y=translate(c,hs,n,K.k,K.R,K.b,True);self.times['source_geometry']+=time.perf_counter()-t
      t=time.perf_counter();b=sn.transpose()*mom[0]+sv.transpose()*mom[1];self.times['source_contraction']+=time.perf_counter()-t
      t=time.perf_counter();h=K.harmonics(-x,-y,M+n+2);self.times['harmonics']+=time.perf_counter()-t
      t=time.perf_counter();H=acb_mat(2*M+3,2*n+3,[h[i+l] for i in range(2*M+3) for l in range(2*n+3)]);V+=H*b;self.times['harmonic_contraction']+=time.perf_counter()-t
      me=sum((d*(hs/rs)**l for l,d in enumerate(dm)),arb(0));moment_sum+=me
      self.sources.append((x,y,b));records.append(dict(source=j,moment_errors=[up(d) for d in dm],weighted_moment_error=up(me)))
      del sv,sn,H,h,mom
      if j%20==0:print('SOURCE',j,'seconds',time.perf_counter()-start,flush=True)
    t=time.perf_counter()
    def yjet(l):
      hh=lambda i:V[i+M+1,0]
      return [hh(l),K.k*(hh(l+1)-hh(l-1))/2,I*K.k*(hh(l+1)+hh(l-1))/2]
    self.plus=[yjet(0)];self.minus=[yjet(0)];fac=arb(1)
    for m in range(1,M+1):
      fac*=K.k*self.R/(2*m)
      self.plus.append([z*fac for z in yjet(m)]);self.minus.append([z*fac*(-1)**m for z in yjet(-m)])
    self.times['normalization']=time.perf_counter()-t
    self.moment_E=(domain['major']*moment_sum).upper();self.source_records=records
    self.seconds=time.perf_counter()-start;self.cpu_seconds=time.process_time()-cpu
    self.record=dict(M=M,n=n,S=S,source_count=count,bits=bits,series_capacity=ctx.cap,seconds=self.seconds,cpu_seconds=self.cpu_seconds,times=self.times,moment_E_upper=up(self.moment_E),source_records=records)
    q=domain['a']/self.R;weighted=norm([z-z.mid() for z in self.plus[0]])
    radii=[]
    for m in range(M+1):
      pp=norm([z-z.mid() for z in self.plus[m]]);mm=norm([z-z.mid() for z in self.minus[m]]) if m else arb(0)
      radii.append([up(pp),up(mm)])
      if m:weighted+=q**m*(pp+mm)
    self.record.update(weighted_coefficient_radius=up(weighted),coefficient_radii=radii)
    dump(out/'setup.json',self.record)
    dump(out/'coefficients.json',dict(plus=[[[z.real.str(50),z.imag.str(50)] for z in row] for row in self.plus],minus=[[[z.real.str(50),z.imag.str(50)] for z in row] for row in self.minus]))

  def tails(self,M=None):
    M=self.M if M is None else M;d=self.dom;a=d['a'];q=a/self.R;qs=arb.pi()/(self.S*self.rs);power=(self.K.k**2*a*a/4).exp()
    growth=1+2*q*(1-q**M)/(1-q)
    physical=2*d['B']*power*q**(M+1)/(1-q)
    source=d['B']*qs**(self.n+1)/(1-qs)*power*growth
    moment=self.moment_E*power*growth
    return physical.upper(),source.upper(),moment.upper()

  def value(self,t,J=14,M=None):
    M=self.M if M is None else M;K=self.K
    x,y,dx,dy=geom(t,K.R,K.b);z=x+I*y;w=x-I*y;xi=-K.k*K.k*z*w/4
    zp=acb(1);wp=acb(1);v=[acb(0)]*3;tail=arb(0)
    for m in range(M+1):
      phi=acb(1);term=acb(1)
      for j in range(1,J+1):term*=xi/(j*(m+j));phi+=term
      ratio=abs(xi)/((J+2)*(m+J+2));assert ratio<1
      rem=abs(term*xi/((J+1)*(m+J+1)))/(1-ratio)
      combination=[self.plus[m][r]*zp+(self.minus[m][r]*wp if m else 0) for r in range(3)]
      tail+=rem*norm(combination)
      for r in range(3):v[r]+=phi*combination[r]
      zp*=z/self.R;wp*=w/self.R
    speed=(dx*dx+dy*dy).sqrt();weight=speed.sqrt()
    out=[weight*v[0],weight*(dy*v[1]-dx*v[2])/speed]
    # Real nodes are balls on the real axis. The exact real normal has unit norm.
    return out,(abs(weight)*tail).upper()

  def direct(self,t):
    """Independent 192-bit source-CM evaluation, without global physical expansion."""
    K=self.K;x,y,dx,dy=geom(t,K.R,K.b);v=[acb(0)]*3;n=self.n
    for sx,sy,b in self.sources:
      h=K.harmonics(x-sx,y-sy,n+2);off=n+2
      for j in range(2*n+3):
        m=j-n-1;c=b[j,0]
        v[0]+=h[off+m]*c
        v[1]+=K.k*(h[off+m+1]-h[off+m-1])*c/2
        v[2]+=I*K.k*(h[off+m+1]+h[off+m-1])*c/2
    speed=(dx*dx+dy*dy).sqrt();weight=speed.sqrt()
    return [weight*v[0],weight*(dy*v[1]-dx*v[2])/speed]
