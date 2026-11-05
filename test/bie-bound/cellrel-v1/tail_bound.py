"""Whole right-lead envelope tail without a computed full residual map.
Input: exact density maps, state propagation and fixed point coefficients.
Output: material/wall/seam operator bounds, contraction and least tail depth.
"""
import time
from flint import arb,acb,ctx
from material import matrix,up,I
from expansion import geometry,major,norm
from self_interaction import Radial,self_domain,fourier_bound

def envelope(K,piece,bc,Z,beta,d):
  start=time.perf_counter();ctx.prec=192;Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);G=matrix(piece['G']);P=matrix(piece['P']);c=matrix(piece['c']);modes=piece['modes'];g=geometry(K,arb('.12'));radius=g['radius'];gn=norm(G);r=norm(P);assert r<1
  D=2*arb.pi()*sum((norm([C[j,l] for C in [Ct,Cz] for l in range(C.ncols())]) for j in range(Ct.nrows())),arb(0))
  charge=sum((norm([bc[j,l] for l in range(bc.ncols())]) for j in range(bc.nrows())),arb(0));dist=[(Z[0,j].real**2+Z[1,j].real**2).sqrt() for j in range(Z.ncols())];dmin=min(x.lower() for x in dist);dmax=max(x.upper() for x in dist)
  point=major(K.k,dmin,dmax,(arb(1)/2).sqrt(),arb(0),charge)
  near=major(K.k,1-radius,1+radius,radius,arb(0),arb(2),g)*D
  # Real-source/real-target ordinary layer bound. The closed square has
  # minimum boundary distance >= .5-radius and three-image maximum below
  # sqrt(.5^2+1.5^2)+radius. R=delta=0 is the real evaluation case of CK11.
  ordinary=major(K.k,arb('.5')-radius,(arb('.5')**2+arb('1.5')**2).sqrt()+radius,arb(0),arb(0),arb(3),g)*D
  incoming=arb(0)
  for m in range(-48,49):
    bm=beta+2*arb.pi()*m/d;gamma=acb(K.k**2-bm**2).sqrt();incoming+=2*(1+abs(gamma)**2+bm*bm)/d
  incoming=incoming.sqrt()
  trace=g['speed'].sqrt()*max(arb(1),g['normal']);assert trace<1
  local=trace*(fourier_bound(Ct,modes,arb(0))+fourier_bound(Cz,modes,arb(0))+incoming)
  rad=Radial(K.k,arb(17));selfmax=arb(0);domain=[]
  for j in range(64):
    h=arb.pi()/64;t=(2*j+1)*h;a=arb('.16');HA,HB,rec=self_domain(K.k,K.R,K.b,t,h,a,Ct,Cz,modes,rad)
    bound=2*HA/((a-h).exp()-1)+HB;selfmax=max(selfmax,bound);domain.append(dict(panel=j,envelope=up(bound),**rec))
  # RE23: integrate the scalar envelope of the signed Kress kernel.
  material=(2*arb.pi()).sqrt()*((selfmax+local+trace*near)*gn+trace*point)
  face=(ordinary+incoming)*gn+point
  wall=(1+r)*face;seam=2*face
  C=[arb('1.2336397935832015'),arb('1.0355521263049683'),arb('1.0355521263049683')];BL=[material,wall,seam]
  states=[c];budgets=[]
  for N in range(201):
    tailfactor=norm(states[-1])/(1-r*r).sqrt();weighted=sum((a*b for a,b in zip(C,BL)),arb(0))*tailfactor;budgets.append(up(weighted))
    if weighted<=arb('1e-17'):break
    states.append(P*states[-1])
  else:raise ArithmeticError('No lead-tail depth <=200')
  for j in range(10):states.append(P*states[-1])
  rec=dict(N=N,p=1,r=up(r),B_material=up(material),B_wall=up(wall),B_seam=up(seam),B_material_uniform=up(material/(2*arb.pi()).sqrt()),self_envelope=up(selfmax),near_envelope=up(near),point_envelope=up(point),local_envelope=up(local),ordinary_envelope=up(ordinary),weighted_tail_at_depth=budgets,domain=domain,seconds=time.perf_counter()-start)
  return BL,states,r,rec
