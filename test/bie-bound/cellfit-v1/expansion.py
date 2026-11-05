"""Regular Helmholtz expansions with shared source contractions.
Input: exact binary64 density maps, charges, regions and explicit orders.
Output: coefficient balls, analytic tails and independent direct evaluations.
"""
import time
from flint import arb,acb,acb_mat,ctx
from material import I,Proxy,matrix,geom,translate,up
from panel import moment_basis

def norm(x):
  if isinstance(x,acb_mat):return sum((abs(x[i,j]).upper()**2 for i in range(x.nrows()) for j in range(x.ncols())),arb(0)).sqrt().upper()
  return sum((abs(z).upper()**2 for z in x),arb(0)).sqrt().upper()

def geometry(K,rs):
  pi=arb.pi();deriv=arb(0);speed=arb(0);low=arb(100);radius=arb(0)
  for j in range(512):
    real=arb((2*j+1)*pi/512,(pi/512).upper());x,y,dx,dy=geom(real,K.R,K.b)
    radius=max(radius,abs(acb(x,y)).upper())
    for l in range(8):
      t=acb(real,arb(-rs+(2*l+1)*rs/8,(rs/8).upper()));x,y,dx,dy=geom(t,K.R,K.b)
      deriv=max(deriv,abs(dx+I*dy).upper(),abs(dx-I*dy).upper());speed=max(speed,norm([dx,dy]));low=min(low,(dx*dx+dy*dy).real.lower())
  assert low>0
  return dict(delta=(rs*deriv).upper(),speed=speed,normal=(speed/low.sqrt()).upper(),speed_square_lower=low,radius=radius)

def major(k,dmin,dmax,R,delta,charge,g=None):
  assert R+delta<dmin
  lo=(dmin-R-delta)**2;Q=(dmax+R+delta)**2
  L=max(abs((dmin*dmin).log()),abs((dmax*dmax).log()))-2*(1-(R+delta)/dmin).log()
  b=k*k/4;e=(b*Q).exp();C=arb(1)/4+(abs((k/2).log())+arb.const_euler())/(2*arb.pi())
  z=[b**j*e*(L/(4*arb.pi())+C+(j+b*Q)/(2*arb.pi())) for j in range(3)]
  z[1]+=e/(4*arb.pi()*lo);z[2]+=e*(2*b/lo+1/lo**2)/(4*arb.pi());d=dmax+R+delta
  if g is None:return (charge*(z[0]+2*d*z[1])).upper()
  n=g['normal'];return (charge*g['speed']*(z[0]+2*(n+1)*d*z[1]+n*(2*z[1]+4*d*d*z[2]))).upper()

class Sources:
  def __init__(self,K,piece,S=160,n=80,rs=arb('.055')):
    start=time.perf_counter();ctx.cap=max(ctx.cap,n+1);self.K=K;self.S=S;self.n=n;self.rs=rs;self.g=geometry(K,rs)
    Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);self.Ct=Ct;self.Cz=Cz;self.modes=piece['modes'];self.nc=Ct.ncols();nc=self.nc;hs=arb.pi()/S
    self.D=(2*arb.pi()*sum((norm([C[j,l] for C in [Ct,Cz] for l in range(nc)]) for j in range(Ct.nrows())),arb(0))).upper()
    t=time.perf_counter();F=moment_basis(self.modes,hs,n);self.times={'moment_basis':time.perf_counter()-t,'moments':0.,'geometry':0.,'contraction':0.};self.rows=[]
    for j in range(S):
      c=(2*j+1)*hs;t=time.perf_counter();phase=[(I*m*c).exp() for m in self.modes]
      co=acb_mat(2*nc,len(self.modes),[C[i,l]*phase[i] for C in [Ct,Cz] for l in range(nc) for i in range(len(self.modes))]);v=co*F
      mt=acb_mat(n+1,nc,[v[l,i] for i in range(n+1) for l in range(nc)]);mz=acb_mat(n+1,nc,[v[nc+l,i] for i in range(n+1) for l in range(nc)])
      self.times['moments']+=time.perf_counter()-t;t=time.perf_counter();sv,sn,x,y=translate(c,hs,n,K.k,K.R,K.b,True);self.times['geometry']+=time.perf_counter()-t
      t=time.perf_counter();b=sn.transpose()*mt+sv.transpose()*mz;self.times['contraction']+=time.perf_counter()-t;self.rows.append((x,y,b))
    self.seconds=time.perf_counter()-start

class Expansion:
  def __init__(self,K,charges,R,M,sources=None,center=(arb(0),arb(0)),coefficients=None,table=None):
    start=time.perf_counter();self.K=K;self.R=R;self.M=M;self.center=center;self.sources=sources;self.charges=charges
    old=K.charges;K.charges=charges;nc=sources.nc if sources else coefficients.ncols();self.nc=nc
    V=acb_mat(2*M+3,nc);dmin=arb(100);dmax=arb(0);self.times=dict(harmonics=0.,contraction=0.)
    if sources:
      for sx,sy,b in sources.rows:
        for X,Y,c in charges:
          d=((center[0]-sx-X)**2+(center[1]-sy-Y)**2).sqrt();assert d.imag.is_zero();d=d.real;dmin=min(dmin,d.lower());dmax=max(dmax,d.upper())
        t=time.perf_counter();hh=K.harmonics(center[0]-sx,center[1]-sy,M+sources.n+2);self.times['harmonics']+=time.perf_counter()-t
        t=time.perf_counter();H=acb_mat(2*M+3,2*sources.n+3,[hh[i+j] for i in range(2*M+3) for j in range(2*sources.n+3)]);V+=H*b;self.times['contraction']+=time.perf_counter()-t
      charge=sum((abs(c).upper() for X,Y,c in charges),arb(0));self.B=major(K.k,dmin,dmax,R,sources.g['delta'],charge,sources.g)*sources.D
    else:
      # One harmonic table, multiplied by every state column simultaneously.
      key=(str(K.k),str(R),M,tuple(str(v) for v in center),tuple((str(X),str(Y)) for X,Y,c in charges))
      H=acb_mat(2*M+3,len(charges)) if table is None else table['H'];t=time.perf_counter()
      if table is not None:assert table['key']==key,'Incompatible fixed-point harmonic table'

      for j,(X,Y,_) in enumerate(charges):
        if table is None:
          K.charges=[(X,Y,acb(1))];hh=K.harmonics(center[0],center[1],M+1)
          for i in range(2*M+3):H[i,j]=hh[i]
        d=((center[0]-X)**2+(center[1]-Y)**2).sqrt();dmin=min(dmin,d.lower());dmax=max(dmax,d.upper())
      self.table=dict(key=key,H=H);self.times['harmonics']=time.perf_counter()-t;t=time.perf_counter();V=H*coefficients;self.times['contraction']=time.perf_counter()-t
      charge=sum((norm([coefficients[i,j] for j in range(nc)]) for i in range(coefficients.nrows())),arb(0));self.B=major(K.k,dmin,dmax,R,arb(0),charge);self.coefficients=coefficients
    K.charges=old;self.plus=[];self.minus=[];fac=arb(1)
    for m in range(M+1):
      if m:fac*=K.k*R/(2*m)
      rows=[]
      for sign in (1,-1):
        l=sign*m;h=lambda a,j:V[a+M+1,j];scale=fac*((-1)**m if sign==-1 else 1)
        rows.append(acb_mat(3,nc,[scale*z for r in range(3) for j in range(nc) for z in [[h(l,j),K.k*(h(l+1,j)-h(l-1,j))/2,I*K.k*(h(l+1,j)+h(l-1,j))/2][r]]]))
      self.plus.append(rows[0]);self.minus.append(rows[1])
    self.record=dict(M=M,R=str(R),center=[str(x) for x in center],columns=nc,B=up(self.B),dmin=str(dmin),dmax=str(dmax),separation=str((dmin-R-(sources.g['delta'] if sources else 0)).lower()),seconds=time.perf_counter()-start,times=self.times)
  def tails(self,a,M=None):
    M=self.M if M is None else M;q=a/self.R;assert q<1;power=(self.K.k**2*a*a/4).exp();physical=2*self.B*power*q**(M+1)/(1-q);source=arb(0)
    if self.sources:
      s=self.sources;qs=arb.pi()/(s.S*s.rs);source=self.B*qs**(s.n+1)/(1-qs)*power*(1+2*q*(1-q**M)/(1-q))
    return physical.upper(),source.upper()
  def value(self,x,y,M=None,J=14):
    M=self.M if M is None else M;z=x-self.center[0]+I*(y-self.center[1]);w=x-self.center[0]-I*(y-self.center[1]);xi=-self.K.k**2*z*w/4;zp=acb(1);wp=acb(1);v=acb_mat(3,self.nc);tail=arb(0)
    for m in range(M+1):
      phi=acb(1);term=acb(1)
      for j in range(1,J+1):term*=xi/(j*(m+j));phi+=term
      ratio=abs(xi)/((J+2)*(m+J+2));assert ratio<1
      rem=abs(term*xi/((J+1)*(m+J+1)))/(1-ratio)
      comb=self.plus[m]*zp+(self.minus[m]*wp if m else acb_mat(3,self.nc));tail+=rem*norm(comb);v+=comb*phi;zp*=z/self.R;wp*=w/self.R
    return v,tail.upper()
  def direct(self,x,y):
    K=self.K;old=K.charges;K.charges=self.charges;v=acb_mat(3,self.nc)
    if self.sources:
      for sx,sy,b in self.sources.rows:
        n=self.sources.n;h=K.harmonics(x-sx,y-sy,n+2);off=n+2
        H=acb_mat(3,2*n+3,[z for r in range(3) for j in range(2*n+3) for z in [[h[j+1],K.k*(h[j+2]-h[j])/2,I*K.k*(h[j+2]+h[j])/2][r]]]);v+=H*b
    else:
      for j,(X,Y,_) in enumerate(self.charges):
        K.charges=[(X,Y,acb(1))];h=K.harmonics(x,y,1);vals=[h[1],K.k*(h[2]-h[0])/2,I*K.k*(h[2]+h[0])/2]
        for r in range(3):
          for l in range(self.nc):v[r,l]+=vals[r]*self.coefficients[j,l]
    K.charges=old;return v
