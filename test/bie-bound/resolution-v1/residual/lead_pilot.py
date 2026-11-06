# Copied from test/bie-bound/pipeline-v1/residual/lead_pilot.py.
# Copied from test/bie-bound/grouprel-v1/lead_pilot.py; pipeline adaptations documented in README.
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

def build(K,piece,bc,Z,beta,d,out,name,W=None):
  start=time.perf_counter();ctx.prec=128;Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);G=matrix(piece['G']);Vstate=None
  prep=time.perf_counter()
  if W is not None:
    W,Vstate=W;ctx.prec=192;Ct=Ct*W;Cz=Cz*W;bc=bc*Vstate;ctx.prec=128
  project_seconds=time.perf_counter()-prep
  cp=dict(piece,tau_coeff=Ct,zeta_coeff=Cz);src=Sources(K,cp,64,80,arb('.12'));phase=(I*beta*d).exp();images=[(arb(0),arb(m),phase**m) for m in [-1,1]];charges=[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())]
  near=Expansion(K,images,arb('.6'),72,src);proxy=Expansion(K,charges,arb('1.1'),144,coefficients=bc);setup=time.perf_counter()-start
  ct=arb.pi()/64;h=arb.pi()/64;L=48;rt=arb('.12');tc=src.g['speed'].sqrt()*max(arb(1),src.g['normal']);assert tc<1
  scf,es,sr=self_map(K,Ct,Cz,piece['modes'],ct,h)
  ctx.prec=192;t=time.perf_counter();box=acb(arb(ct,rt),arb(0,rt));lb=local(K,Ct,Cz,piece['modes'],W,beta,d,box);locnodes=[local(K,Ct,Cz,piece['modes'],W,beta,d,ct+h*(arb.pi()*(2*l+1)/(2*L)).cos()) for l in range(L)]
  if W is None:lcf,el,lr=model(locnodes,arb(0),h,norm(lb))
  else:lcf,el,lr=models(locnodes,[arb(0)]*Ct.ncols(),[column_norm(lb,j) for j in range(Ct.ncols())])
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
  record=dict(name=name,columns=Ct.ncols(),project_seconds=project_seconds,source=src.times,source_seconds=src.seconds,near_setup=near.record,proxy_setup=proxy.record,setup_seconds=setup,self=sr,local_seconds=localtime,local=lr,node_seconds=nodetime,algebra_seconds=algtime,e_I=up(err),column_errors=None if errs is None else list(map(up,errs)),near=nr,proxy=pr)
  if W is None:
    t=time.perf_counter();record['baseline']=map_bound(cf,err,h,piece);record['norm_seconds']=time.perf_counter()-t
    assert abs(record['baseline']['epsilon_panel_upper']/7.888339401528067e-15-1)<1e-6,'194-column reproduction failed'
  else:
    t=time.perf_counter();vv=integral(cf,h);vg=gauss_integral(cf,h);rel=abs(vv-vg)/vv.lower();assert rel<arb('1e-12');record.update(V=str(vv),V_gauss=str(vg),V_difference=up(rel),finite_upper=up(vv.upper().sqrt()+(2*h).sqrt()*err),norm_seconds=time.perf_counter()-t)
  record['seconds']=time.perf_counter()-start;dump(out/f'{name}.json',record)
  return cf,err,src,proxy,record

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--output',required=True);a=p.parse_args();out=Path(a.output);data=json.loads(Path(a.input).read_text());fits=json.loads(Path(a.coefficients).read_text());ctx.prec=128;ctx.cap=81;ctx.threads=1;start=time.perf_counter();cpu=time.process_time()
  piece=data['pieces'][2];K=Proxy(data);pars=matrix(data['curve_parameters']);K.R=(pars[0,7].real,);K.b=pars[0,6].real;beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real;Z=matrix(fits['Z']);bc=matrix(fits['B_positive']);G=matrix(piece['G'])
  (out/'part.txt').write_text('tail-envelopes');BL,states,r,tr=envelope(K,piece,bc,Z,beta,d);dump(out/'tail.json',tr);N=tr['N'];rows=[];objects={}
  (out/'part.txt').write_text('full-194');full,ef,srcfull,pfull,recfull=build(K,piece,bc,Z,beta,d,out,'full194');h=arb.pi()/64
  for n in [N,N+10]:
    (out/'part.txt').write_text('actual-'+str(n));ctx.prec=192;V=acb_mat(97,n,[states[j][i,0] for i in range(97) for j in range(n)]);W=G*V
    cf,err,src,proxy,rec=build(K,piece,bc,Z,beta,d,out,'state'+str(n),(W,V));ctx.prec=192;t=time.perf_counter();full_columns=[a*V for a in full];v0=integral(full_columns,h);v1=integral(cf,h);joint=ef*norm(V)+err
    allowance=2*h*joint*joint+2*(2*h).sqrt()*joint*(v0.upper().sqrt()+v1.upper().sqrt());difference=abs(v0-v1)
    tail=BL[0]**2/(64*(1-r*r))*norm(states[n])**2;upper=((v1.upper().sqrt()+(2*h).sqrt()*err)**2+tail).sqrt();fullupper=v0.upper().sqrt()+(2*h).sqrt()*ef*norm(V)
    rec.update(N=n,V_full=str(v0),V_state=str(v1),V_difference_upper=up(difference),V_error_allowance=up(allowance),finite_comparison_passed=bool(difference<allowance),tail_squared=up(tail),epsilon_upper=up(upper),ratio_to_full194=up(upper/arb(str(recfull['baseline']['epsilon_panel_upper']))),tail_check_seconds=time.perf_counter()-t)
    objects[n]=(src,proxy,W,V);rows.append(rec);dump(out/f'state{n}.json',rec);dump(out/'summary.json',dict(tail=tr,full=recfull,states=rows));assert rec['finite_comparison_passed'] and abs(rec['ratio_to_full194']-1)<.01
  from wall_columns import compute as wall
  (out/'part.txt').write_text('wall-center-setup');ctx.prec=128;K0=Proxy(data);s0=Sources(K0,data['pieces'][0]);charges=[(Z[1,j].real,Z[0,j].real,acb(1)) for j in range(Z.ncols())];p0=Expansion(K0,charges,arb('1.1'),144,coefficients=matrix(fits['B_center']));phase=(I*beta*d).exp();reg0=Expansion(K0,[(arb(0),arb(m),phase**m) for m in [-1,0,1]],arb('.08'),80,s0,(arb('.5'),arb('.03125')));center=(K0,s0,p0,matrix(data['incident']),reg0)
  ctx.prec=192;V0=states[0];W0=G*V0;cp=dict(piece,tau_coeff=matrix(piece['tau_coeff'])*W0,zeta_coeff=matrix(piece['zeta_coeff'])*W0);ctx.prec=128;s1=Sources(K,cp,64,80,arb('.12'));p1=Expansion(K,charges,arb('1.1'),144,coefficients=bc*V0)
  wallrows=[];wallrefs={}
  for tag,ss,pp,fullflag in [('full194',srcfull,pfull,True),('state1',s1,p1,False)]:
    (out/'part.txt').write_text('junction-'+tag);cf,e,rr=wall(K,ss,pp,W0,V0,beta,d,'junction',center,fullflag);wallrows.append(dict(name=tag,source_seconds=ss.seconds,**rr));wallrefs[tag]=(cf,e);dump(out/'walls.json',wallrows)
  vf=integral(wallrefs['full194'][0],arb('.03125'));vn=integral(wallrefs['state1'][0],arb('.03125'));ee=wallrefs['full194'][1]+wallrefs['state1'][1];allow=2*(arb('.0625')).sqrt()*ee*(vf.upper().sqrt()+vn.upper().sqrt())+arb('.0625')*ee*ee;assert abs(vn-vf)<allow,'Junction state-column comparison failed'
  wc=dict(V_full=str(vf),V_state=str(vn),difference=up(abs(vn-vf)),allowance=up(allow),passed=True)
  dump(out/'wall-comparison.json',wc)
  # The N+10 check already supplied the source moments. Restrict them to
  # exactly N+1 actual states for N consecutive interior walls.
  (out/'part.txt').write_text('interior-state-restriction');t=time.perf_counter();ss0,pp0,WW,VV=objects[N+10];nn=N+1
  cut=lambda A:acb_mat(A.nrows(),nn,[A[i,j] for i in range(A.nrows()) for j in range(nn)])
  ss=copy.copy(ss0);ss.nc=nn;ss.Ct=cut(ss0.Ct);ss.Cz=cut(ss0.Cz);ss.rows=[(x,y,cut(b)) for x,y,b in ss0.rows];WW=cut(WW);VV=cut(VV)
  pp=Expansion(K,charges,arb('1.1'),144,coefficients=bc*VV);restriction=time.perf_counter()-t;interior=[];irefs={}
  for tag,sx,px,fullflag in [('full194',srcfull,pfull,True),('state'+str(nn),ss,pp,False)]:
    (out/'part.txt').write_text('interior-'+tag);cf,e,rr=wall(K,sx,px,WW,VV,beta,d,'interior',None,fullflag);tail=BL[1]**2*norm(states[N])**2/(16*(1-r*r));vv=integral(cf,arb('.03125'));total=((vv.upper().sqrt()+arb('.0625').sqrt()*e)**2+tail).sqrt();rr.update(name=tag,N=N,tail_squared=up(tail),epsilon_upper=up(total));interior.append(rr);irefs[tag]=(cf,e);dump(out/'interior.json',interior)
  vf=integral(irefs['full194'][0],arb('.03125'));vn=integral(irefs['state'+str(nn)][0],arb('.03125'));ee=irefs['full194'][1]+irefs['state'+str(nn)][1];allow=2*arb('.0625').sqrt()*ee*(vf.upper().sqrt()+vn.upper().sqrt())+arb('.0625')*ee*ee
  ic=dict(difference=up(abs(vn-vf)),allowance=up(allow),passed=bool(abs(vn-vf)<allow),restriction_seconds=restriction);dump(out/'interior-comparison.json',ic);assert ic['passed'],'Interior wall state-column comparison failed'
  tailratio=(norm(states[N+10])/norm(states[N]));result=dict(tail=tr,full=recfull,states=rows,walls=wallrows,wall_comparison=wc,interior=interior,interior_comparison=ic,wall_common_setup_seconds=s0.seconds+p0.record['seconds']+reg0.record['seconds'],tail_norm_ratio=up(tailratio),contraction_tenth_power=up(r**10),seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu)
  dump(out/'summary.json',result)
if __name__=='__main__':main()
