# B2 source: test/bie-bound/pipeline-v1/residual/chebyshev.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/chebyshev.py; pipeline adaptations documented in README.
"""Real Chebyshev self-interaction using A2, A3 and D2.
Input: exact field, panel and explicit orders. Output: fixed coefficients and SI8 ledger.
DCT means discrete cosine transform; SI denotes the self-interaction theorem equations.
"""
import time
from flint import arb,acb,acb_poly,ctx
from material import up
from self_interaction import Radial,self_domain,source_grid,kress_at,absolute_vec

def sharp(HA,HB,a,N):
  """SI5 at real targets, including the symmetric Nyquist convention."""
  n=N//2;alias=arb(0)
  for j in range(N):
    m=(n+j)%N;k=min(m,N-m)
    if k:alias+=(-a*j).exp()/k
  return (2*HA*((-a*n).exp()/(n*(1-(-a).exp()))+
    (-a*n).exp()*alias/(1-(-a*N).exp()))+2*HB/((a*N).exp()-1)).upper()

class SelfDomainFailure(ArithmeticError):
  """No permitted self-interaction domain yielded a valid certificate."""
  pass

def coefficients(K,ct,ht,p,Ct,Cz,modes,rt,a,N,L,cache=None):
  start=time.perf_counter();times={};ctx.prec=192
  rad=Radial(K.k);t=time.perf_counter()
  attempts=[]
  for candidate in [rt,arb('.035'),arb('.030')]:
    try:
      HA0,HB0,large=self_domain(K.k,K.R,K.b,ct,candidate,arb('.0625'),Ct,Cz,modes,rad)
      chosen_rt=candidate
      M=2*HA0/((arb('.0625')-chosen_rt).exp()-1)+HB0
      if len(attempts)==0:
        rho=arb('4.5')
      else:
        ratio=chosen_rt/ht
        # A strict inequality has a supremum rather than a largest real rho.
        # Choose an outward-certified lower endpoint just below that supremum.
        rho=(ratio+(ratio*ratio-1).sqrt()).lower()*(1-arb(2)**-48)
      assert ht*(rho+1/rho)/2<chosen_rt
      attempts.append(dict(Rt=str(candidate),valid=True))
      break
    except ArithmeticError as error:
      attempts.append(dict(Rt=str(candidate),valid=False,error=str(error)))
  else:
    raise SelfDomainFailure(str(attempts))
  try:
    HA,HB,small=self_domain(K.k,K.R,K.b,ct,ht,arb('.08'),Ct,Cz,modes,rad)
  except ArithmeticError as error:
    raise SelfDomainFailure('Small source-strip domain: '+str(error)) from error
  L=40
  while not 4*M*rho**(1-L)/(rho-1)<=arb('2e-17'):
    L+=1
  degree=max(p,L-1)
  times['domains']=time.perf_counter()-t
  ctx.prec=128;t=time.perf_counter();rad=Radial(K.k)
  grid=source_grid(N,Ct,Cz,modes,K.R,K.b) if cache is None else cache.grid
  times['source_grid']=time.perf_counter()-t
  t=time.perf_counter();values=[];maxrad=arb(0)
  for l in range(L):
    x=(arb.pi()*(2*l+1)/(2*L)).cos()
    v=kress_at(ct+ht*x,rad,K.R,K.b,grid)
    mid=[z.mid() for z in v]
    maxrad=max(maxrad,absolute_vec(v[0]-mid[0],v[1]-mid[1]))
    values.append(mid)
  times['node_sums']=time.perf_counter()-t
  ctx.prec=192;t=time.perf_counter()
  # Only the exact binary midpoints enter the finite DCT. Sample uncertainty
  # is paid once in SI8, outside this conversion.
  xs=[arb.pi()*(2*l+1)/(2*L) for l in range(L)]
  cheb=[acb_poly([1]),acb_poly([0,1])]
  for j in range(2,L):cheb.append(acb_poly([0,2])*cheb[-1]-cheb[-2])
  balls=[];cf=[]
  for row in range(2):
    poly=acb_poly([0])
    for j in range(L):
      d=sum((values[l][row]*(j*xs[l]).cos() for l in range(L)),acb(0))*(1 if j==0 else 2)/L
      poly+=cheb[j]*d
    balls.append([poly[j] for j in range(degree+1)])
    cf.append([poly[j].mid() for j in range(degree+1)])
  conv=sum((absolute_vec(balls[0][j]-cf[0][j],balls[1][j]-cf[1][j]) for j in range(degree+1)),arb(0))
  times['conversion']=time.perf_counter()-t
  source=sharp(HA,HB,arb('.08'),N)
  interp=4*M*rho**(1-L)/(rho-1)
  error=interp+(2*arb(L)-1).sqrt()*(source+maxrad)+conv
  record=dict(N=N,L=L,degree=degree,Rt=str(chosen_rt),rho=str(rho),domain_attempts=attempts,node_bits=128,conversion_bits=192,large_domain=large,small_domain=small,
    M_self=up(M),ellipse_semimajor_upper=up(ht*(rho+1/rho)/2),source_SI5=up(source),
    e_node=up(maxrad),interpolation_remainder=up(interp),e_conv=up(conv),e_self=up(error),
    times=times,self_seconds=time.perf_counter()-start,
    gates=dict(node_radius=bool(maxrad<=arb('4e-18')),conversion=bool(conv<=arb('1e-18')),self_error=bool(error<=arb('1e-16'))))
  ctx.prec=128
  return cf,error,M,record

def control(K,ct,ht,Ct,Cz,modes,cf,err,record):
  """Independent 192-bit, 3072-source checks of the fixed polynomial."""
  start=time.perf_counter();ctx.prec=192
  rad=Radial(K.k);grid=source_grid(3072,Ct,Cz,modes,K.R,K.b)
  # Recompute bounds, rather than parsing rounded display values as balls.
  HA,HB,_=self_domain(K.k,K.R,K.b,ct,ht,arb('.08'),Ct,Cz,modes,rad)
  es=sharp(HA,HB,arb('.08'),3072);rows=[]
  for x in [arb('-0.7'),arb(0),arb('.7')]:
    v=kress_at(ct+ht*x,rad,K.R,K.b,grid)
    pred=[acb_poly(row)(x) for row in cf]
    # Upper distance of the balls is compared with both analytic errors.
    diff=absolute_vec(v[0]-pred[0],v[1]-pred[1]);allow=err+es
    rows.append(dict(x=str(x),difference_upper=up(diff),allowance_upper=up(allow),passed=bool(diff<=allow)))
  ctx.prec=128
  return dict(points=rows,seconds=time.perf_counter()-start,N=3072,bits=192)
