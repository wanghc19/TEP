# B2 source: test/bie-bound/pipeline-v1/residual/real_panels.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/real_panels.py; pipeline adaptations documented in README.
"""Real-node proxy interpolation and signed material-panel assembly.
Input: global coefficient balls, exact field, panel and orders.
Output: PA14, D2 and RE12 error accounts, controls and disjoint timers.
"""
import time
from types import SimpleNamespace
from flint import arb,acb,acb_poly,ctx
from material import I,geom,matrix,up,dump
from panel import incident,absolute_vec
from chebyshev import coefficients,control
from self_interaction import source_grid

class SelfCache:
  def __init__(self,data,K,N=1152):
    t=time.perf_counter();piece=data['pieces'][0]
    self.Ct=matrix(piece['tau_coeff']);self.Cz=matrix(piece['zeta_coeff']);self.modes=piece['modes']
    self.grid=source_grid(N,self.Ct,self.Cz,self.modes,K.R,K.b);self.seconds=time.perf_counter()-t

def interpolate(values,degree):
  L=len(values);angles=[arb.pi()*(2*l+1)/(2*L) for l in range(L)]
  basis=[acb_poly([1]),acb_poly([0,1])]
  for j in range(2,L):basis.append(acb_poly([0,2])*basis[-1]-basis[-2])
  balls=[];mid=[]
  for row in range(2):
    p=acb_poly([0])
    for j in range(L):
      c=sum((values[l][row]*(j*angles[l]).cos() for l in range(L)),acb(0))*(1 if j==0 else 2)/L
      p+=basis[j]*c
    balls.append([p[j] for j in range(degree+1)]);mid.append([p[j].mid() for j in range(degree+1)])
  error=sum((absolute_vec(balls[0][j]-mid[0][j],balls[1][j]-mid[1][j]) for j in range(degree+1)),arb(0))
  return mid,error

def compute(A,data,cache,idx,out,M,L=48,J=14,controls=True):
  start=time.perf_counter();cpu=time.process_time();times={};K=A.K;ctx.prec=128
  ht=arb.pi()/192;ct=(2*idx+1)*ht;rt=arb('.04');rho=arb('4.5');p=52
  Ct,Cz,modes=cache.Ct,cache.Cz,cache.modes
  t=time.perf_counter();selfcf,eself,_,sr=coefficients(K,ct,ht,p,Ct,Cz,modes,rt,arb('.0625'),1152,40,cache);times['self']=time.perf_counter()-t
  assert all(sr['gates'].values())
  t=time.perf_counter();physical,source,moment=A.tails(M);interp=4*3*A.dom['B']*rho**(1-L)/(rho-1)
  assert ht*(rho+1/rho)/2<rt;times['envelopes']=time.perf_counter()-t
  t=time.perf_counter();values=[];node_radius=arb(0);phi=arb(0)
  for l in range(L):
    # Irrational node locations remain enclosed; only field values become exact midpoints.
    x=(arb.pi()*(2*l+1)/(2*L)).cos();v,ep=A.value(acb(ct+ht*x),J,M)
    mid=[z.mid() for z in v];node_radius=max(node_radius,absolute_vec(v[0]-mid[0],v[1]-mid[1]));phi=max(phi,ep);values.append(mid)
  times['regular_nodes']=time.perf_counter()-t
  remaining=moment+node_radius+phi;node=physical+source+remaining
  ctx.prec=192;t=time.perf_counter();proxycf,conv=interpolate(values,p);times['change_of_basis']=time.perf_counter()-t
  eproxy=interp+(2*arb(L)-1).sqrt()*node+conv
  t=time.perf_counter();local,Mlocal=incident(data,ct,ht,p,rt,K,Ct,Cz,modes)
  localtail=Mlocal*(ht/rt)**(p+1)/(1-ht/rt);times['local_terms']=time.perf_counter()-t
  t=time.perf_counter();D=max(len(selfcf[0]),p+1);cf=[[],[]];pcf=[[],[]]
  for row in range(2):
    for j in range(D):
      z=(selfcf[row][j] if j<len(selfcf[row]) else 0)+(proxycf[row][j] if j<=p else 0)+(local[row][j] if j<=p else 0)
      cf[row].append(z);pcf[row].append(z.mid()*(1 if row==0 else -1))
  arithmetic=sum((absolute_vec(cf[0][j]-pcf[0][j],cf[1][j]+pcf[1][j]) for j in range(D)),arb(0))
  e=eself+eproxy+localtail+arithmetic
  V=2*ht*sum(((row[i].conjugate()*row[j]).real/(i+j+1) for row in pcf for i in range(D) for j in range(i%2,D,2)),arb(0))
  assert V.lower()>0
  bound=V.upper().sqrt()+(2*ht).sqrt()*e
  times['combination_and_norm']=time.perf_counter()-t
  production=time.perf_counter()-start
  # New polynomial, independently integrated; no old square integral enters the computation.
  t=time.perf_counter();polys=[acb_poly(row) for row in pcf]
  Vg=sum((ht*w*sum((abs(f(x))**2 for f in polys),arb(0)) for x,w in [arb.legendre_p_root(D,j,True) for j in range(D)]),arb(0))
  normcheck=abs(Vg-V)/V.lower();normpass=V.overlaps(Vg) and normcheck<arb('1e-12');times['independent_norm']=time.perf_counter()-t
  gate=dict(remaining_node=bool(remaining<=arb('1e-18')),conversion=bool(conv<=arb('1e-19')),local_combination=bool(arithmetic<=arb('1e-19')),old_error_acceptance=bool(e<=arb(1.1)*arb([2.015114157818781e-15,2.582298610633771e-15][idx])),independent_norm=bool(normpass))
  record=dict(panel=idx,M=M,n=A.n,L=L,J=J,precision=128,conversion_precision=192,self=sr,physical_tail=up(physical),source_tail=up(source),moment_error=up(moment),basis_tail=up(phi),node_ball_radius=up(node_radius),remaining_node_error=up(remaining),node_error=up(node),interpolation_tail=up(interp),conversion_error=up(conv),e_proxy=up(eproxy),local_tail=up(localtail),local_combination_error=up(arithmetic),e_I=up(e),V=str(V),V_independent=str(Vg),norm_check_relative=up(normcheck),epsilon_panel_upper=up(bound),times=times,production_seconds=production,online_nonself_seconds=sum(v for k,v in times.items() if k not in ['self','independent_norm']),gates=gate,polynomial=[[[z.real.str(55),z.imag.str(55)] for z in row] for row in pcf])
  dump(out/f'new-panel-{idx}-M{M}.json',record)
  assert all(gate.values()),'Node/conversion/local/norm/acceptance gate failed'
  rows=[];t=time.perf_counter()
  if controls:
    # Direct source-CM sum at 192 bits uses the same source data but no global expansion.
    # The two values independently enclose the true field once both source errors are added.
    for xi in [arb('-.7'),arb(0),arb('.7')]:
      target=acb(ct+ht*xi);direct=A.direct(target);new,ep=A.value(target,J,M)
      poly=[acb_poly(row)(xi) for row in proxycf]
      direct_radius=absolute_vec(direct[0]-direct[0].mid(),direct[1]-direct[1].mid())
      new_radius=absolute_vec(new[0]-new[0].mid(),new[1]-new[1].mid())
      direct_error=source+moment+direct_radius;new_error=physical+source+moment+ep+new_radius
      diff=absolute_vec(direct[0].mid()-new[0].mid(),direct[1].mid()-new[1].mid())
      poly_diff=absolute_vec(direct[0].mid()-poly[0],direct[1].mid()-poly[1])
      passed=bool(diff<=direct_error+new_error and poly_diff<=direct_error+eproxy)
      rows.append(dict(x=str(xi),field_difference=up(diff),field_allowance=up(direct_error+new_error),polynomial_difference=up(poly_diff),polynomial_allowance=up(direct_error+eproxy),passed=passed))
    record['self_controls']=control(K,ct,ht,Ct,Cz,modes,selfcf,eself,sr)
  times['controls']=time.perf_counter()-t;record['controls']=rows;record['times']=times
  record['seconds']=time.perf_counter()-start;record['cpu_seconds']=time.process_time()-cpu
  dump(out/f'new-panel-{idx}-M{M}.json',record)
  assert all(z['passed'] for z in rows),'Independent proxy control failed'
  if controls:assert all(z['passed'] for z in record['self_controls']['points'])
  ctx.prec=128
  return record
