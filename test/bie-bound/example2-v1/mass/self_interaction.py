# B2 source: test/bie-bound/pipeline-v1/mass/self_interaction.py; generalized model plumbing.
# Copied from test/bie-bound/matrel-v1/self_interaction.py; pipeline adaptations documented in README.
"""Kress product integration for the signed central Müller free-space difference.
Input: exact fixed field, target disk and source strip in angular coordinates.
Output: RE5, Cauchy coefficient errors and scaled target Taylor coefficients.
"""
import math,time
from flint import arb,acb,acb_poly,ctx
from material import I,geom,matrix,up

def box(c,r):
  return acb(arb(c,r),arb(0,r))

def absolute_vec(x,y):
  return (abs(x).upper()**2+abs(y).upper()**2).sqrt().upper()

def divided_chord(t,s,R,b):
  """Analytic (r(t)-r(s))/(2 sin((t-s)/2)), including the diagonal."""
  d=(t-s)/2;m=(t+s)/2
  c=d.cos();c3=(3*d).cos();c5=(5*d).cos()
  u4=2*(c+c3);u6=u4+2*c5
  x=-R*(arb('1.5')*m.sin()+b*((4*m).sin()*u4+(6*m).sin()*u6)/2)
  y=R*(m.cos()+b*(-(4*m).cos()*u4+(6*m).cos()*u6)/2)
  return x,y

def fourier_bound(C,modes,a):
  return sum((abs(C[j,0])*(abs(m)*a).exp() for j,m in enumerate(modes)),arb(0)).upper()

class Radial:
  """Q3 entire coefficients a,b of G_ext-G_int = a(q) log(q)+b(q)."""
  def __init__(self,k):
    pi=arb.pi();A=[];B=[];he=arb(0);fe=arb(1);fi=arb(1)
    for j in range(41):
      if j:
        he+=arb(1)/j;fe*=-(k*k)/(4*j*j);fi*=-(k*k)/(j*j)
      A.append(-(fe-fi)/(4*pi))
      B.append((I/4+(-((k/2).log()+arb.const_euler())+he)/(2*pi))*fe-
               (I/4+(-(k.log()+arb.const_euler())+he)/(2*pi))*fi)
    aa=acb_poly(A);bb=acb_poly(B)
    self.poly=[aa,aa.derivative(),aa.derivative().derivative(),bb,bb.derivative(),bb.derivative().derivative(),acb_poly(A[1:])]
    j=41;v=2*k*k
    ratio=v/(j+1)**2*(arb(j+2)/(j+1))**3
    assert ratio<1
    self.error=100*(j+1)**3*v**j/math.factorial(j)**2/(1-ratio)
  def eval(self,q):
    assert abs(q)<2,'Radial series envelope exceeded'
    rad=arb(0,self.error.upper());epsilon=acb(rad,rad)
    return [p(q)+epsilon for p in self.poly]

def free_blocks(rad,q,Hlog,delta,n_t,n_s,chord,H):
  """Value and outward-derivative rows, signed before taking any norms."""
  a,ap,app,b,bp,bpp,aq=rad.eval(q)
  dx,dy=delta;nx,ny=n_t;mx,my=n_s;cx,cy=chord
  ntD=2*(dx*nx+dy*ny);nsD=2*(dx*mx+dy*my)
  dot=nx*mx+ny*my;divided=4*(cx*nx+cy*ny)*(cx*mx+cy*my)/H
  reg1=bp+ap*Hlog+aq
  A=[-nsD*ap,-a,-(2*dot*ap+ntD*nsD*app),-ntD*ap]
  B=[-nsD*reg1,-(b+a*Hlog),
     -(2*dot*reg1+ntD*nsD*(bpp+app*Hlog)+divided*(2*ap-aq)),-ntD*reg1]
  return A,B

def norms(C,ds):
  return abs(C[0])*ds[0]+abs(C[1])*ds[1]+abs(C[2])*ds[0]+abs(C[3])*ds[1]

def self_domain(k,R,b,ct,rt,a,Ct,Cz,modes,rad):
  """Tile a rectangle containing the target disk and whole complex source strip.
  Reject tiles until positivity is certified; at maximum depth fail explicitly.
  """
  pi=arb.pi();ds=[fourier_bound(C,modes,a) for C in [Ct,Cz]]
  maxA=arb(0);maxB=arb(0);minH=arb(100);minv=arb(100);tiles=0
  def tile(tc,tw,ti,th,sc,sw,si,sh,depth):
    nonlocal maxA,maxB,minH,minv,tiles
    t=acb(arb(tc,tw.upper()),arb(ti,th.upper()));s=acb(arb(sc,sw.upper()),arb(si,sh.upper()))
    x,y,xt,yt=geom(t,R,b);u,v,xs,ys=geom(s,R,b)
    vx=xt*xt+yt*yt;vs=xs*xs+ys*ys
    cx,cy=divided_chord(t,s,R,b);H=cx*cx+cy*cy;q=(x-u)**2+(y-v)**2
    if not (vx.real>0 and vs.real>0 and H.real>0 and abs(q)<2):
      if depth>=12:raise ArithmeticError('No certified speed/chord branch on the selected complex domain')
      # Bisect the widest real or imaginary coordinate.
      widths=[tw,th,sw,sh];centers=[tc,ti,sc,si];j=max(range(4),key=lambda l:float(widths[l]))
      widths[j]/=2
      for sign in [-1,1]:
        c=centers.copy();c[j]+=sign*widths[j]
        tile(c[0],widths[0],c[1],widths[1],c[2],widths[2],c[3],widths[3],depth+1)
      return
    vt=vx.sqrt();vv=vs.sqrt();w=abs(vt.sqrt()*vv)*2*pi
    A,B=free_blocks(rad,q,H.log(),(x-u,y-v),(yt/vt,-xt/vt),(ys/vv,-xs/vv),(cx,cy),H)
    maxA=max(maxA,(w*norms(A,ds)).upper());maxB=max(maxB,(w*norms(B,ds)).upper())
    minH=min(minH,H.real.lower());minv=min(minv,vx.real.lower(),vs.real.lower());tiles+=1
  N=128
  for j in range(N):
    tile(ct,rt,arb(0),rt,(2*j+1)*pi/N,pi/N,arb(0),a,0)
  return maxA,maxB,dict(tiles=tiles,min_real_chord_square=str(minH),min_real_speed_square=str(minv),H_A=up(maxA),H_B=up(maxB))

def source_grid(N,Ct,Cz,modes,R,b):
  pi=arb.pi()
  def density(C):
    co=[acb(0)]*N
    for j,m in enumerate(modes):co[m%N]+=C[j,0]*N
    v=acb.dft(co,inverse=True)
    assert v[0].overlaps(sum((C[j,0] for j in range(len(modes))),acb(0)))
    return v
  tau=density(Ct);zeta=density(Cz);grid=[]
  for j in range(N):
    s=2*pi*j/N;x,y,dx,dy=geom(s,R,b);w=(dx*dx+dy*dy).sqrt()
    grid.append((s,x,y,dy/w,-dx/w,w*tau[j],w*zeta[j]))
  return grid

def kress_at(t,rad,R,b,grid):
  N=len(grid);n=N//2;pi=arb.pi()
  x,y,xt,yt=geom(t,R,b);wt=(xt*xt+yt*yt).sqrt();nx=yt/wt;ny=-xt/wt
  ep=(I*t).exp();em=(-I*t).exp();zp=acb(1);zm=acb(1);coeff=[acb(0)]*N
  for m in range(1,n+1):
    if m%16==1:
      zp=(I*m*t).exp();zm=(-I*m*t).exp()
    else:
      zp*=ep;zm*=em
    if m==n:coeff[n]=-(zp+zm)/(2*n)
    else:coeff[m]=-zp/m;coeff[-m]=-zm/m
  weights=acb.dft(coeff)
  result=[acb(0),acb(0)]
  for j,(s,u,v,mx,my,tau,zeta) in enumerate(grid):
    dx=x-u;dy=y-v;q=dx*dx+dy*dy
    den=2*((t-s)/2).sin()
    if abs(den)>arb('1e-12'):cx=dx/den;cy=dy/den
    else:cx,cy=divided_chord(t,s,R,b)
    H=cx*cx+cy*cy
    A,B=free_blocks(rad,q,H.log(),(dx,dy),(nx,ny),(mx,my),(cx,cy),H)
    for l in range(2):
      result[l]+=weights[j]*(A[2*l]*tau+A[2*l+1]*zeta)+B[2*l]*tau+B[2*l+1]*zeta
  return [z*(2*pi/N)*wt.sqrt() for z in result]

def self_coefficients(K,ct,ht,p,Ct,Cz,modes,rt,a,N,L,diagnostic=False):
  ctx.prec=192
  start=time.perf_counter();rad=Radial(K.k)
  print("Kress domain",flush=True)
  HA,HB,record=self_domain(K.k,K.R,K.b,ct,rt,a,Ct,Cz,modes,rad)
  record['domain_seconds']=time.perf_counter()-start;print('Kress domain complete',record,flush=True)
  inner=4*HA*(-(a-rt)*(N//2)).exp()/(1-(-(a-rt)).exp())+2*HB/((a*N).exp()-1)
  M=2*HA/((a-rt).exp()-1)+HB
  t=time.perf_counter();grid=source_grid(N,Ct,Cz,modes,K.R,K.b)
  record['grid_seconds']=time.perf_counter()-t;print('Kress grid complete',flush=True)
  vals=[[],[]];pi=arb.pi();t=time.perf_counter()
  for l in range(1 if diagnostic else L):
    root=(I*pi*(2*l+1)/L).exp();v=kress_at(ct+ht*root,rad,K.R,K.b,grid)
    for j in range(2):vals[j].append(v[j])
  elapsed=time.perf_counter()-t
  record.update(N=N,L=L,point_seconds=elapsed/len(vals[0]),Kress_RE5=up(inner),M_self=up(M),evaluation_seconds=elapsed)
  if diagnostic:
    ctx.prec=128
    return record
  coefficients=[]
  for row in vals:
    F=acb.dft(row)
    coefficients.append([F[j]*(-I*pi*j/L).exp()/L for j in range(p+1)])
  # Sampled Q_N on a circle of radius h. Finite DFT aliases coefficients j+mL.
  ratio=ht/rt
  alias=(M+inner)*ratio**L/(1-ratio**L)/(1-ratio)
  record['alias_upper']=up(alias)
  ctx.prec=128
  return coefficients,inner,M,alias,record
