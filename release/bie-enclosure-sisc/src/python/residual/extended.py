# Copied from test/bie-bound/pipeline-v1/residual/extended.py; release R1 path/data interfaces may be adapted.
# Copied from test/bie-bound/grouprel-v1/extended.py; pipeline adaptations documented in README.
"""One full lead material map and physical wall/seam residual pilots.
Input: same-process sources, fitted fields and exact stable-state data.
Output: CK18/CK20a matrix bounds and continuous segment residual ledgers.
"""
import time,copy
from flint import arb,acb,acb_mat,ctx
from material import I,Proxy,matrix,geom,up,dump
from expansion import Sources,Expansion,norm
from map_models import interpolate,integral,gauss_integral,evaluate
from lead_self import compute as self_map

def trace(v,x,y,K,material=False,normal=(arb(1),arb(0)),t=None):
  if material:
    _,_,dx,dy=geom(t,K.R,K.b);speed=(dx*dx+dy*dy).sqrt();nx=dy/speed;ny=-dx/speed;weight=speed.sqrt()
  else:nx,ny=normal;weight=arb(1)
  return acb_mat(2,v.ncols(),[weight*z for r in range(2) for j in range(v.ncols()) for z in [[v[0,j],nx*v[1,j]+ny*v[2,j]][r]]])

def incident(K,beta,d,x,y):
  modes=range(-48,49);v=acb_mat(3,194)
  for side in range(2):
    sign=1-2*side;wall=-arb(sign)/2
    for j,m in enumerate(modes):
      bm=beta+2*arb.pi()*m/d;gamma=acb(K.k**2-bm**2).sqrt();u=(I*((x-wall)*gamma*sign+y*bm)).exp()/d.sqrt();col=side*97+j
      v[0,col]=u;v[1,col]=I*gamma*sign*u;v[2,col]=I*bm*u
  return v

def local_map(K,piece,beta,d,t):
  x,y,_,_=geom(t,K.R,K.b);v=trace(incident(K,beta,d,x,y),x,y,K,True,t=t);Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);phase=acb_mat(1,len(piece['modes']),[(I*m*t).exp() for m in piece['modes']]);ct=phase*Ct;cz=phase*Cz
  _,_,dx,dy=geom(t,K.R,K.b);weight=(dx*dx+dy*dy).sqrt().sqrt()
  for j in range(194):v[0,j]+=weight*ct[0,j];v[1,j]+=weight*cz[0,j]
  return v

def model(nodes,anal,h,envelope):
  mids=[];finite=arb(0)
  for v in nodes:
    mid=acb_mat(v.nrows(),v.ncols(),[v[i,j].mid() for i in range(v.nrows()) for j in range(v.ncols())]);finite=max(finite,norm(v-mid));mids.append(mid)
  ctx.prec=192;cf,conv=interpolate(mids);L=len(nodes);rho=arb('4.5');tail=4*envelope*rho**(1-L)/(rho-1);e=tail+(2*arb(L)-1).sqrt()*(anal+finite)+conv
  return cf,e,dict(analytic_node_error=up(anal),finite_node_radius=up(finite),interpolation_tail=up(tail),conversion=up(conv))

def addmaps(items):
  D=max(len(cf) for cf,map in items);nr=items[0][0][0].nrows();nc=items[0][1].ncols();out=[];err=arb(0)
  for j in range(D):
    v=acb_mat(nr,nc)
    for cf,G in items:
      if j<len(cf):v+=cf[j]*G
    mid=acb_mat(nr,nc,[v[i,l].mid() for i in range(nr) for l in range(nc)]);err+=norm(v-mid);out.append(mid)
  return out,err.upper()

def map_bound(cf,e,h,piece):
  G=matrix(piece['G']);P=matrix(piece['P']);c=matrix(piece['c']);v=c;Sw=arb(0);Sv=arb(0);states=[]
  for j in range(40):Sw+=norm(G*v)**2;Sv+=norm(v)**2;states.append(v);v=P*v
  state_matrix=acb_mat(97,40,[states[j][i,0] for i in range(97) for j in range(40)])
  finitecf=[a*state_matrix for a in cf];V=integral(finitecf,h);Vmap=integral(cf,h);gauss=gauss_integral(cf,h);relative=abs(gauss-Vmap)/Vmap.lower();assert relative<arb('1e-12')
  B=Vmap.upper().sqrt()+(2*h).sqrt()*e;r=norm(P);assert r<1;tail=B**2*norm(v)**2/(1-r*r)
  finite=V.upper().sqrt()+(2*h).sqrt()*e*Sv.sqrt();bound=(finite*finite+tail).sqrt()
  return dict(V_finite=str(V),V_map=str(Vmap),V_map_gauss=str(gauss),V_relative_check=up(relative),S_w=up(Sw),S_v=up(Sv),contraction_p=1,contraction_r=up(r),state40_norm=up(norm(v)),CK20a_B=up(B),tail_squared=up(tail),epsilon_panel_upper=up(bound))

def run(data,fits,K0,sources0,near0,A0,B0,out,verify=False):
  start=time.perf_counter();ctx.prec=128;ctx.cap=81;piece=data['pieces'][2];pars=matrix(data['curve_parameters']);K=Proxy(data);K.R=(pars[0,7].real,);K.b=pars[0,6].real
  beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real;phase=(I*beta*d).exp();Z=matrix(fits['Z']);aa=matrix(fits['A']);bc=matrix(fits['B_positive']);charges=[(Z[1,j].real,Z[0,j].real,aa[0,j]) for j in range(Z.ncols())];images=[(arb(0),arb(m),phase**m) for m in [-1,1]]
  result={};(out/'part.txt').write_text('right-lead-sources');src=Sources(K,piece,64,80,arb('.12'));trace_bound=src.g['speed'].sqrt()*max(arb(1),src.g['normal']);assert trace_bound<1;result['target_trace_upper']=up(trace_bound);result['source_seconds']=src.seconds;result['source_times']=src.times
  (out/'part.txt').write_text('right-lead-expansions');near=Expansion(K,images,arb('.60'),72,src);ea=Expansion(K,charges,arb('.90'),288,src);eb=Expansion(K,charges,arb('1.1'),144,coefficients=bc,table=B0.table);result['near_setup']=near.record;result['A_setup']=ea.record;result['B_setup']=eb.record
  ct=arb.pi()/64;h=arb.pi()/64;rt=arb('.12');rho=arb('4.5');L=48;G=matrix(piece['G']);identity=acb_mat(194,194,[int(i==j) for i in range(194) for j in range(194)]);ident97=acb_mat(97,97,[int(i==j) for i in range(97) for j in range(97)])
  (out/'part.txt').write_text('right-lead-self');selfcf,eself,sr=self_map(K,src.Ct,src.Cz,piece['modes'],ct,h);result['self']=sr;dump(out/'extended-summary.json',result)
  # Local exact finite terms on the target disk; positivity of speed is checked by self domains.
  ctx.prec=192;t=time.perf_counter();box=acb(arb(ct,rt),arb(0,rt));localB=norm(local_map(K,piece,beta,d,box));nodes=[local_map(K,piece,beta,d,ct+h*(arb.pi()*(2*l+1)/(2*L)).cos()) for l in range(L)];local,elocal,lr=model(nodes,arb(0),h,localB);result['local']=dict(seconds=time.perf_counter()-t,envelope=up(localB),e_local=up(elocal),**lr)
  result['lead']=[]
  if verify:
    from lead_self import source as make_grid,kernel as self_kernel
    from self_interaction import Radial
    from chebyshev import sharp
    ctx.prec=256;control_grid,control_density=make_grid(K,src.Ct,src.Cz,piece['modes'],2304);control_radial=Radial(K.k,arb(17))
    control_self_error=sharp(arb(sr['small']['H_A']),arb(sr['small']['H_B']),arb('.16'),2304)
  for tag,ex,deg in [('A',ea,64),('B',eb,64)]:
    (out/'part.txt').write_text('right-lead-'+tag);ctx.prec=128;t=time.perf_counter();near_nodes=[];proxy_nodes=[];basisn=arb(0);basisp=arb(0)
    for l in range(L):
      tt=ct+h*(arb.pi()*(2*l+1)/(2*L)).cos();x,y,_,_=geom(tt,K.R,K.b);vn,en=near.value(x,y);vp,ep=ex.value(x,y,deg);near_nodes.append(trace(vn,x,y,K,True,t=tt));proxy_nodes.append(trace(vp,x,y,K,True,t=tt));basisn=max(basisn,en);basisp=max(basisp,ep)
    nodes_seconds=time.perf_counter()-t;t=time.perf_counter();radius=src.g['radius'];nt=near.tails(radius);pt=ex.tails(radius,deg);cn,en,nr=model(near_nodes,sum(nt,arb(0))+basisn,h,trace_bound*near.B);cp,ep,pr=model(proxy_nodes,sum(pt,arb(0))+basisp,h,trace_bound*ex.B)
    if tag=='A':cf,rounding=addmaps([(selfcf,G),(local,G),(cn,G),(cp,G)]);error=(eself+elocal+en+ep)*norm(G)+rounding
    else:cf,rounding=addmaps([(selfcf,G),(local,G),(cn,G),(cp,ident97)]);error=(eself+elocal+en)*norm(G)+ep+rounding
    algebra=time.perf_counter()-t;t=time.perf_counter();bounds=map_bound(cf,error,h,piece);state_seconds=time.perf_counter()-t
    controls=[];control_start=time.perf_counter()
    for u in [arb('-.7'),arb(0),arb('.7')]:
      tt=ct+h*u;x,y,_,_=geom(tt,K.R,K.b);direct=ex.direct(x,y);regular,phi=ex.value(x,y,deg)
      dm=acb_mat(3,direct.ncols(),[direct[i,j].mid() for i in range(3) for j in range(direct.ncols())]);rm=acb_mat(3,regular.ncols(),[regular[i,j].mid() for i in range(3) for j in range(regular.ncols())])
      physical,source=ex.tails(radius,deg);allow=physical+2*source+phi+norm(direct-dm)+norm(regular-rm);difference=norm(dm-rm)
      controls.append(dict(x=str(u),difference=up(difference),allowance=up(allow),passed=bool(difference<=allow)))
      if tag=='A':break
    control_seconds=time.perf_counter()-control_start
    full_controls=[];full_seconds=0.
    if verify:
      ctx.prec=256;t=time.perf_counter()
      for u in [arb(0),arb('.37')]:
        tt=ct+h*u;x,y,_,_=geom(tt,K.R,K.b)
        sd=self_kernel(tt,K,control_radial,control_grid)*control_density
        nd=trace(near.direct(x,y),x,y,K,True,t=tt);pd,pbasis=ex.value(x,y,deg);pd=trace(pd,x,y,K,True,t=tt)
        exact=(sd+local_map(K,piece,beta,d,tt)+nd)*G+pd*(G if tag=='A' else ident97)
        qs=arb.pi()/(src.S*src.rs);nsource=near.B*qs**(src.n+1)/(1-qs)
        pphy,psource=ex.tails(radius,deg)
        allowance=error+(control_self_error+nsource)*norm(G)+(pphy+psource+pbasis)*(norm(G) if tag=='A' else 1)
        difference=norm(exact-evaluate(cf,u));full_controls.append(dict(x=str(u),difference=up(difference),allowance=up(allowance),passed=bool(difference<allowance)))
      full_seconds=time.perf_counter()-t
    row=dict(method=tag,full_controls=full_controls,full_control_seconds=full_seconds,columns_port=194,columns_state=97,e_map=up(error),e_near=up(en),e_proxy=up(ep),e_self=up(eself),e_local=up(elocal),combination_radius=up(rounding),near=nr,proxy=pr,nodes_seconds=nodes_seconds,model_algebra_seconds=algebra,state_and_norm_seconds=state_seconds,controls=controls,control_seconds=control_seconds,**bounds);result['lead'].append(row);dump(out/'extended-summary.json',result);assert all(z['passed'] for z in controls+full_controls),'Lead independent control failed'
  # Physical right junction wall: center x=.5 and right lead local x=-.5.
  (out/'part.txt').write_text('wall-and-seam-setup');three=[(arb(0),arb(m),phase**m) for m in [-1,0,1]]
  wc=Expansion(K0,three,arb('.08'),80,sources0,(arb('.5'),arb('.03125')));wl=Expansion(K,three,arb('.08'),80,src,(arb('-.5'),arb('.03125')))
  top=Expansion(K0,three,arb('.16'),80,sources0,(arb('.0625'),arb('.5')));bottom=Expansion(K0,three,arb('.16'),80,sources0,(arb('.0625'),arb('-.5')))
  result['boundary_setup']={k:v.record for k,v in [('wall_center',wc),('wall_lead',wl),('top',top),('bottom',bottom)]};result['boundary']=[]
  q=matrix(data['incident']);vstate=matrix(piece['c']);wstate=G*vstate
  for name,hb,region in [('wall',arb('.03125'),[wc,wl]),('seam',arb('.0625'),[top,bottom])]:
    for tag,pc,pl in [('A',A0,ea),('B',B0,eb)]:
      (out/'part.txt').write_text(name+'-'+tag);ctx.prec=128;t=time.perf_counter();nodes=[];extra=arb(0)
      # Projection of matrix errors to the particular first stable state is bounded once.
      scalarfactor=norm(wstate);pointfactor=norm(vstate)
      physical_radius=arb('.5') if name=='wall' else arb('.5')
      ar=(arb('.5')**2+(2*hb)**2).sqrt()
      errors=sum(wc.tails(hb),arb(0)) if name=='wall' else sum(top.tails(hb),arb(0))+sum(bottom.tails(hb),arb(0))
      if name=='wall':errors+=sum(wl.tails(hb),arb(0))*scalarfactor
      errors+=sum(pc.tails(ar),arb(0))*(1 if name=='wall' else 2)
      if name=='wall':errors+=sum(pl.tails(ar),arb(0))*(scalarfactor if tag=='A' else pointfactor)
      # Trace maps on flat sides have norm one; source and fixed-point envelopes are combined with state norms.
      envelope=(wc.B+wl.B*scalarfactor+pc.B+pl.B*(scalarfactor if tag=='A' else pointfactor)) if name=='wall' else top.B+bottom.B+2*pc.B
      if name=='wall':
        yt=acb(arb('.03125'),arb(0,arb('.08')));envelope+=norm(incident(K0,beta,d,arb('.5'),yt)*q)+norm(incident(K,beta,d,arb('-.5'),yt)*wstate)
      for l in range(L):
        u=(arb.pi()*(2*l+1)/(2*L)).cos()
        if name=='wall':
          y=arb('.03125')+hb*u;cv,ce=wc.value(arb('.5'),y);pv,pe=pc.value(arb('.5'),y);lv,le=wl.value(arb('-.5'),y);lp,lpe=pl.value(arb('-.5'),y)
          cfield=cv+pv+incident(K0,beta,d,arb('.5'),y)*q;lfield=(lv+incident(K,beta,d,arb('-.5'),y))*wstate+lp*(wstate if tag=='A' else vstate)
          nodes.append(acb_mat(2,1,[lfield[0,0]-cfield[0,0],cfield[1,0]-lfield[1,0]]));extra=max(extra,ce+pe+le*scalarfactor+lpe*(scalarfactor if tag=='A' else pointfactor))
        else:
          x=arb('.0625')+hb*u;tv,te=top.value(x,arb('.5'));bv,be=bottom.value(x,arb('-.5'));tp,tpe=pc.value(x,arb('.5'));bp,bpe=pc.value(x,arb('-.5'))
          tv+=tp;bv+=bp;nodes.append(acb_mat(2,1,[phase*bv[0,0]-tv[0,0],tv[2,0]-phase*bv[2,0]]));extra=max(extra,te+be+tpe+bpe)
      node_seconds=time.perf_counter()-t;t=time.perf_counter();cf,error,ledger=model(nodes,errors+extra,hb,envelope);V=integral(cf,hb);vg=gauss_integral(cf,hb);rel=abs(vg-V)/V.lower();assert rel<arb('1e-12');eps=V.upper().sqrt()+(2*hb).sqrt()*error
      production_norm=time.perf_counter()-t;checks=[];controltime=0.
      if verify:
        ctx.prec=256;t=time.perf_counter()
        for u in ([arb(0)] if tag=='A' else [arb('-.37'),arb(0),arb('.37')]):
          if name=='wall':
            y=arb('.03125')+hb*u
            cd=wc.direct(arb('.5'),y)+pc.direct(arb('.5'),y)+incident(K0,beta,d,arb('.5'),y)*q
            ld=(wl.direct(arb('-.5'),y)+incident(K,beta,d,arb('-.5'),y))*wstate+pl.direct(arb('-.5'),y)*(wstate if tag=='A' else vstate)
            direct=acb_mat(2,1,[ld[0,0]-cd[0,0],cd[1,0]-ld[1,0]])
          else:
            x=arb('.0625')+hb*u
            td=top.direct(x,arb('.5'))+pc.direct(x,arb('.5'));bd=bottom.direct(x,arb('-.5'))+pc.direct(x,arb('-.5'))
            direct=acb_mat(2,1,[phase*bd[0,0]-td[0,0],td[2,0]-phase*bd[2,0]])
          # The direct source-CM error is smaller than the charged CK9 tails.
          allowance=error+errors;difference=norm(direct-evaluate(cf,u));checks.append(dict(x=str(u),difference=up(difference),allowance=up(allowance),passed=bool(difference<allowance)))
        controltime=time.perf_counter()-t
      row=dict(target=name,method=tag,controls=checks,control_seconds=controltime,e_I=up(error),V=str(V),V_gauss=str(vg),V_relative_check=up(rel),epsilon_panel_upper=up(eps),node_seconds=node_seconds,model_norm_seconds=production_norm,**ledger);result['boundary'].append(row);dump(out/'extended-summary.json',result);assert all(z['passed'] for z in checks),'Boundary independent control failed'
  result['seconds']=time.perf_counter()-start;dump(out/'extended-summary.json',result);return result
