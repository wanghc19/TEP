# Copied from test/bie-bound/grouprel-v1/material_group.py; pipeline adaptations documented in README.
"""Lead actual-state-column pilot for material and wall segments.
Input: exact field and saved B fit, explicit output.
Output: full-map reproduction, reduced-column comparisons and tail ledger.
"""
import argparse,json,sys,time,copy
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,acb_mat,ctx
from material import Proxy,matrix,geom,I,up,dump
from expansion import Sources,Expansion,norm
from extended import trace,incident,model,addmaps,map_bound
from map_models import integral,evaluate,gauss_integral
from lead_self import compute as self_map
from self_interaction import fourier_bound
from column_models import models,combine,column_norm
from tail_bound import envelope
from envelope_gate import rectangle

def local(K,Ct,Cz,modes,W,beta,d,t):
  x,y,dx,dy=geom(t,K.R,K.b);v=incident(K,beta,d,x,y)
  if W is not None:v=v*W
  v=trace(v,x,y,K,True,t=t);phase=acb_mat(1,len(modes),[(I*m*t).exp() for m in modes]);ct=phase*Ct;cz=phase*Cz;weight=(dx*dx+dy*dy).sqrt().sqrt()
  for j in range(Ct.ncols()):v[0,j]+=weight*ct[0,j];v[1,j]+=weight*cz[0,j]
  return v

def ratios(Ct,Cz,modes):
  ds=[fourier_bound(C,modes,arb('.16')) for C in [Ct,Cz]];rs=[]
  for j in range(Ct.ncols()):
    vals=[]
    for l,C in enumerate([Ct,Cz]):
      col=acb_mat(C.nrows(),1,[C[i,j] for i in range(C.nrows())]);vals.append(fourier_bound(col,modes,arb('.16'))/ds[l].lower())
    rs.append(max(vals))
  return rs

def build(K,piece,bc,Z,beta,d,out,name,W=None,prepared=None,idx=0,depth=0,sub=0):
  start=time.perf_counter();ctx.prec=128;Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);G=matrix(piece['G']);Vstate=None
  if prepared is None:
    prep=time.perf_counter()
    if W is not None:
      W,Vstate=W;ctx.prec=192;Ct=Ct*W;Cz=Cz*W;bc=bc*Vstate;ctx.prec=128
    project_seconds=time.perf_counter()-prep
    cp=dict(piece,tau_coeff=Ct,zeta_coeff=Cz);src=Sources(K,cp,64,80,arb('.12'));phase=(I*beta*d).exp();images=[(arb(0),arb(m),phase**m) for m in [-1,1]];charges=[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())]
    near=Expansion(K,images,arb('.6'),72,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=bc);setup=time.perf_counter()-start
  else:
    src,near,proxy,W,Vstate=prepared;Ct=src.Ct;Cz=src.Cz;bc=proxy.coefficients;setup=0.;project_seconds=0.
  ct=(idx+(sub+.5)/2**depth)*2*arb.pi()/64;h=arb.pi()/(64*2**depth);L=48;rt=arb('.12')/2**depth;tc=src.g['speed'].sqrt()*max(arb(1),src.g['normal']);assert tc<1
  scf,es,sr=self_map(K,Ct,Cz,piece['modes'],ct,h,rt=rt)
  ctx.prec=192;t=time.perf_counter()
  def speed_branch(z):
    _,_,dx,dy=geom(z,K.R,K.b);return (dx*dx+dy*dy).real
  eb,ew,gate=rectangle(lambda z:local(K,Ct,Cz,piece['modes'],W,beta,d,z),ct,rt,rt,speed_branch)
  locnodes=[local(K,Ct,Cz,piece['modes'],W,beta,d,ct+h*(arb.pi()*(2*l+1)/(2*L)).cos()) for l in range(L)]
  if W is None:lcf,el,lr=model(locnodes,arb(0),h,ew)
  else:lcf,el,lr=models(locnodes,[arb(0)]*Ct.ncols(),eb)
  lr['envelope_gate']=gate
  localtime=time.perf_counter()-t;ctx.prec=128;t=time.perf_counter();nn=[];pn=[];bn=arb(0);bp=arb(0)
  for l in range(L):
    tt=ct+h*(arb.pi()*(2*l+1)/(2*L)).cos();x,y,_,_=geom(tt,K.R,K.b);v,en=near.value(x,y);p,ep=proxy.value(x,y,64);nn.append(trace(v,x,y,K,True,t=tt));pn.append(trace(p,x,y,K,True,t=tt));bn=max(bn,en);bp=max(bp,ep)
  nodetime=time.perf_counter()-t;t=time.perf_counter();radius=src.g['radius'];nt=sum(near.tails(radius),arb(0));pt=sum(proxy.tails(radius,64),arb(0))
  if W is None:
    ncf,en,nr=model(nn,nt+bn,h,tc*near.B);pcf,ep,pr=model(pn,pt+bp,h,tc*proxy.B);ident=acb_mat(97,97,[int(i==j) for i in range(97) for j in range(97)]);cf,rounding=addmaps([(scf,G),(lcf,G),(ncf,G),(pcf,ident)]);err=(es+el+en)*norm(G)+ep+rounding;errs=None
  else:
    nc=Ct.ncols();Dj=[2*arb.pi()*sum((norm([Ct[i,j],Cz[i,j]]) for i in range(Ct.nrows())),arb(0)) for j in range(nc)];near_ratio=[v/src.D.lower() for v in Dj]
    ch=sum((norm([bc[i,j] for j in range(nc)]) for i in range(bc.nrows())),arb(0));point_ratio=[sum((abs(bc[i,j]).upper() for i in range(bc.nrows())),arb(0))/ch.lower() for j in range(nc)]
    ncf,en,nr=models(nn,[nt*r+bn for r in near_ratio],[tc*near.B*r for r in near_ratio]);pcf,ep,pr=models(pn,[pt*r+bp for r in point_ratio],[tc*proxy.B*r for r in point_ratio]);cf,rounding=combine([scf,lcf,ncf,pcf]);rs=ratios(Ct,Cz,piece['modes']);leb=(2*arb(sr['L'])-1).sqrt()
    esj=[r*(arb(str(sr['interpolation_tail']))+leb*arb(str(sr['source_error'])))+leb*arb(str(sr['finite_radius']))+arb(str(sr['conversion'])) for r in rs]
    errs=[esj[j]+el[j]+en[j]+ep[j]+rounding[j] for j in range(nc)];err=norm(errs)
  algtime=time.perf_counter()-t
  record=dict(name=name,depth=depth,sub=sub,columns=Ct.ncols(),project_seconds=project_seconds,source=src.times,source_seconds=src.seconds,near_setup=near.record,proxy_setup=proxy.record,setup_seconds=setup,self=sr,local_seconds=localtime,local=lr,node_seconds=nodetime,algebra_seconds=algtime,e_I=up(err),column_errors=None if errs is None else list(map(up,errs)),near=nr,proxy=pr)
  if W is None:
    t=time.perf_counter();record['baseline']=map_bound(cf,err,h,piece);record['norm_seconds']=time.perf_counter()-t
    record['full_map_reference']=True
  else:
    t=time.perf_counter();vv=integral(cf,h);vg=gauss_integral(cf,h);rel=abs(vv-vg)/vv.lower();assert rel<arb('1e-12');record.update(V=str(vv),V_gauss=str(vg),V_difference=up(rel),finite_upper=up(vv.upper().sqrt()+(2*h).sqrt()*err),norm_seconds=time.perf_counter()-t)
  record['seconds']=time.perf_counter()-start;dump(out/f'{name}.json',record)
  return cf,err,src,proxy,record,errs
