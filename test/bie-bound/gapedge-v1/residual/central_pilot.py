# Stage C source: test/bie-bound/example2-v1/residual/central_pilot.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/residual/central_pilot.py; generalized model plumbing.
# Copied from test/bie-bound/grouprel-v1/central_pilot.py; pipeline adaptations documented in README.
"""Reliable central material pilot for the two cell-kernel field definitions.
Input: explicit original exact field and same-run fitted coefficients.
Output: central residual polynomials, error ledgers, controls and measured costs.
"""
import argparse,json,sys,time,gc
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,acb_poly,ctx
from envelope_gate import FiniteGate
from material import I,Proxy,matrix,geom,up,dump
from expansion import Sources,Expansion,norm
from real_panels import SelfCache,interpolate
from chebyshev import coefficients,control
from panel import incident,absolute_vec

def target_trace(v,t,K):
  _,_,dx,dy=geom(t,K.R,K.b);speed=(dx*dx+dy*dy).sqrt();weight=speed.sqrt()
  return [weight*v[0,0],weight*(dy*v[1,0]-dx*v[2,0])/speed]

def central(data,K,cache,near,proxy,idx,method,out,selfpart,localpart,Mproxy,controls=True,depth=0,sub=0):
  ctx.prec=128;start=time.perf_counter();ht=arb.pi()/(192*2**depth);ct=(idx+(sub+.5)/2**depth)*2*arb.pi()/192;rho=arb('4.5');L=48;p=52
  selfcf,eself,sr=selfpart;local,ltail=localpart;radius=near.sources.g['radius'];tails=[near.tails(radius),proxy.tails(radius,Mproxy)];anal=sum((x for row in tails for x in row),arb(0));B=near.B+proxy.B
  t=time.perf_counter();values=[];maxrad=arb(0);maxbasis=arb(0)
  for l in range(L):
    u=(arb.pi()*(2*l+1)/(2*L)).cos();tt=acb(ct+ht*u);x,y,_,_=geom(tt,K.R,K.b)
    a,ea=near.value(x,y);b,eb=proxy.value(x,y,Mproxy);v=target_trace(a+b,tt,K);mid=[z.mid() for z in v]
    maxrad=max(maxrad,absolute_vec(v[0]-mid[0],v[1]-mid[1]));maxbasis=max(maxbasis,ea+eb);values.append(mid)
  nodes=time.perf_counter()-t;node=anal+maxrad+maxbasis
  ctx.prec=192;t=time.perf_counter();smooth,conv=interpolate(values,p);conversion=time.perf_counter()-t
  interp=4*3*B*rho**(1-L)/(rho-1);e_smooth=interp+(2*arb(L)-1).sqrt()*node+conv
  t=time.perf_counter();D=max(p+1,len(selfcf[0]));pcf=[[],[]];arithmetic=arb(0)
  for j in range(D):
    z=[(selfcf[r][j] if j<len(selfcf[r]) else 0)+(smooth[r][j] if j<=p else 0)+(local[r][j] if j<=p else 0) for r in range(2)]
    mid=[x.mid() for x in z];arithmetic+=absolute_vec(z[0]-mid[0],z[1]-mid[1]);pcf[0].append(mid[0]);pcf[1].append(-mid[1])
  e=eself+ltail+e_smooth+arithmetic
  V=2*ht*sum(((row[i].conjugate()*row[j]).real/(i+j+1) for row in pcf for i in range(D) for j in range(i%2,D,2)),arb(0))
  if not V.is_finite():raise FiniteGate("Nonfinite central polynomial integral")
  assert V.lower()>0
  eps=V.upper().sqrt()+(2*ht).sqrt()*e;combine=time.perf_counter()-t;production=time.perf_counter()-start
  t=time.perf_counter();polys=[acb_poly(r) for r in pcf]
  Vg=sum((ht*w*sum((abs(f(x))**2 for f in polys),arb(0)) for x,w in [arb.legendre_p_root(D,j,True) for j in range(D)]),arb(0));vgrel=abs(Vg-V)/V.lower();assert V.overlaps(Vg) and vgrel<arb('1e-12');integration=time.perf_counter()-t
  rows=[];t=time.perf_counter()
  if controls:
    for u in [arb('-.7'),arb(0),arb('.7')]:
      tt=acb(ct+ht*u);x,y,_,_=geom(tt,K.R,K.b);direct=target_trace(proxy.direct(x,y),tt,K);regular,rb=proxy.value(x,y,Mproxy);reg=target_trace(regular,tt,K)
      diff=absolute_vec(direct[0]-reg[0],direct[1]-reg[1]);pt,st=proxy.tails(radius,Mproxy);allow=pt+2*st+rb
      passed=bool(diff<=allow);rows.append(dict(x=str(u),difference=up(diff),allowance=up(allow),passed=passed))
  ctsec=time.perf_counter()-t
  rec=dict(method=method,panel=idx,depth=depth,sub=sub,M_proxy=Mproxy,source_degree=80,L=L,precision=128,conversion_precision=192,
    e_self=up(eself),local_tail=up(ltail),near_physical_tail=up(tails[0][0]),near_source_tail=up(tails[0][1]),proxy_physical_tail=up(tails[1][0]),proxy_source_tail=up(tails[1][1]),
    node_radius=up(maxrad),basis_tail=up(maxbasis),node_error=up(node),interpolation_tail=up(interp),conversion_error=up(conv),combination_error=up(arithmetic),e_smooth=up(e_smooth),e_I=up(e),
    V=str(V),V_gauss=str(Vg),V_relative_check=up(vgrel),epsilon_panel_upper=up(eps),self=sr,controls=rows,
    times=dict(nodes=nodes,conversion=conversion,combination=combine,production_without_shared_self_local=production,independent_integral=integration,controls=ctsec),
    tight_gates=dict(node=bool(node<=arb('2e-20')),conversion=bool(conv<=arb('1e-21')),e_I=bool(e<arb(['2.60e-18','3.51e-18'][idx])) if idx<2 and depth==0 else None),
    fallback_gates=dict(node=bool(node<=arb('1.05e-18')),conversion=bool(conv<=arb('1e-19'))),
    polynomial=[[[z.real.str(55),z.imag.str(55)] for z in r] for r in pcf])
  dump(out/f'{method}-panel-{idx}-d{depth}-s{sub}-M{Mproxy}.json',rec)
  assert all(r['passed'] for r in rows),'Independent point-source/CM control failed'
  assert all(rec['fallback_gates'].values()),'CK12 fallback gate failed'
  return rec

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--output',required=True);p.add_argument('--baseline',action='store_true');p.add_argument('--extended',action='store_true');a=p.parse_args();out=Path(a.output)
  data=json.loads(Path(a.input).read_text());fits=json.loads(Path(a.coefficients).read_text());ctx.prec=128;ctx.cap=81;ctx.threads=1;start=time.perf_counter();cpu=time.process_time();result={}
  if a.baseline:
    from aggregation import Aggregation
    from domains import certify
    from real_panels import compute
    (out/'part.txt').write_text('old-baseline');old=out/'old';old.mkdir();k=Proxy(data);dom=certify(k,data,160,arb('.41'),arb('.055'));agg=Aggregation(data,dom,576,72,160,arb('.055'),160,old)
    c=SelfCache(data,k);rows=[]
    for i,ref in enumerate([2.6495208364838675e-18,3.558771497506436e-18]):
      r=compute(agg,data,c,i,old,576,48,14,False);rows.append(dict(panel=i,e_I=r['e_I'],reference=ref,exact=r['e_I']==ref));assert r['e_I']==ref
    result['baseline']=rows;result['baseline_seconds']=time.perf_counter()-start;dump(out/'summary.json',result);del agg,c;gc.collect()
  (out/'part.txt').write_text('shared-source');ctx.prec=128;ctx.cap=81;K=Proxy(data);Z=matrix(fits['Z']);A=matrix(fits['A']);bc=matrix(fits['B_center']);charges=[(Z[1,j].real,Z[0,j].real,A[0,j]) for j in range(Z.ncols())]
  result['A_l1']=up(sum((abs(c) for x,y,c in charges),arb(0)));result['B_l1']=up(sum((abs(bc[j,0]) for j in range(bc.nrows())),arb(0)))
  assert result['A_l1']<4.01 and result['B_l1']<5
  sources=Sources(K,data['pieces'][0]);result['source_seconds']=sources.seconds;result['source_times']=sources.times
  phase=(I*matrix(data['beta'])[0,0]*matrix(data['d'])[0,0]).exp();near_charges=[(arb(0),arb(m),phase**m) for m in [-1,1]]
  (out/'part.txt').write_text('near-expansion');near=Expansion(K,near_charges,arb('.60'),128,sources);result['near_setup']=near.record
  (out/'part.txt').write_text('A-expansion');ea=Expansion(K,charges,arb('.90'),288,sources);result['A_setup']=ea.record
  (out/'part.txt').write_text('B-expansion');eb=Expansion(K,charges,arb('1.1'),144,coefficients=bc);result['B_setup']=eb.record;dump(out/'summary.json',result)
  cache=SelfCache(data,K);result['self_cache_seconds']=cache.seconds;result['panels']=[];result['shared_targets']=[]
  for i in [0,1]:
    (out/'part.txt').write_text(f'central-{i}');t=time.perf_counter();ct=(2*i+1)*arb.pi()/192;ht=arb.pi()/192;selfcf,eself,_,sr=coefficients(K,ct,ht,52,cache.Ct,cache.Cz,cache.modes,arb('.04'),arb('.0625'),1152,40,cache);selfseconds=time.perf_counter()-t
    ctx.prec=192;t=time.perf_counter();local,mlocal=incident(data,ct,ht,52,arb('.04'),K,cache.Ct,cache.Cz,cache.modes);localtail=mlocal*(ht/arb('.04'))**53/(1-ht/arb('.04'));localtime=time.perf_counter()-t
    result['shared_targets'].append(dict(panel=i,self_seconds=selfseconds,local_seconds=localtime))
    for name,ex,M in [('A',ea,80),('B',eb,52)]:
      r=central(data,K,cache,near,ex,i,name,out,(selfcf,eself,sr),(local,localtail),M);r.pop('polynomial');result['panels'].append(r)
    if i==0:
      # Lower the actual central A truncation by four; a 32-mode drop exceeds CK12.
      low=central(data,K,cache,near,ea,0,'A-reduced',out,(selfcf,eself,sr),(local,localtail),76,False)
      oldtail=ea.tails(sources.g['radius'],80)[0];newtail=ea.tails(sources.g['radius'],76)[0];ratio=newtail/oldtail;pred=(sources.g['radius']/ea.R)**(-4)
      result['reduced_order']=dict(M=76,reference_M=80,ratio=up(ratio),predicted_ratio=up(pred),e_I=low['e_I']);assert abs(ratio/pred-1)<arb('1e-20')
    dump(out/'summary.json',result)
  if a.extended:
    from extended import run
    result['extended']=run(data,fits,K,sources,near,ea,eb,out)
  result.update(seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu);dump(out/'summary.json',result)
if __name__=='__main__':main()
