# Copied from test/bie-bound/grouprel-v1/panel.py; pipeline adaptations documented in README.
"""Certify selected contiguous central material panels and measure their cost.
Input: same-run exact field and explicit panel/degrees. Output: scalar and Taylor-ball ledger.
"""
import argparse,json,math,sys,time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from material import I,TAU,Proxy,translate,benchmark,matrix,up,dump,geom
from self_interaction import box,absolute_vec,fourier_bound
from chebyshev import coefficients,control
from flint import acb,arb,acb_mat,acb_series,ctx

def proxy_envelope(K,ct,cs,rt,rs):
  """Uniform operator-norm bound for the four proxy blocks on a complex bidisk."""
  def tile(tc,tw,ti,th,sc,sw,si,sh,depth):
    t=acb(arb(tc,tw.upper()),arb(ti,th.upper()));s=acb(arb(sc,sw.upper()),arb(si,sh.upper()))
    x,y,xt,yt=geom(t,K.R,K.b);u,v,xs,ys=geom(s,K.R,K.b)
    ft=xt*xt+yt*yt;fs=xs*xs+ys*ys;valid=ft.real>0 and fs.real>0
    total=arb(0);clear=arb(100)
    if valid:
      speed=fs.sqrt();wt=ft.sqrt()
      nt=absolute_vec(xt,yt)/ft.real.lower().sqrt();ns=absolute_vec(xs,ys)/fs.real.lower().sqrt()
      for X,Y,c in K.charges:
        dx=x-u-X;dy=y-v-Y;z=dx*dx+dy*dy
        if not z.real>0:valid=False;break
        clear=min(clear,z.real.lower())
        # Q3 entire-series majorants. Re(z)>0 fixes the logarithm branch.
        Q=abs(z).upper();lo=z.real.lower();b0=K.k**2/4
        base=(b0*Q).exp()
        log_bound=max(abs(lo.log()).upper(),abs(Q.log()).upper())+arb.pi()/2
        const=arb(1)/4+(abs((K.k/2).log())+arb.const_euler())/(2*arb.pi())
        core=[b0**m*base*(log_bound/(4*arb.pi())+const+(m+b0*Q)/(2*arb.pi())) for m in range(3)]
        g0=core[0];gp=core[1]+base/(4*arb.pi()*lo)
        gpp=core[2]+base*(2*b0/lo+1/lo**2)/(4*arb.pi())
        dd=absolute_vec(dx,dy)
        total+=abs(c)*(g0+(nt+ns)*2*dd*gp+nt*ns*(2*gp+4*dd**2*gpp))
      if valid and total.is_finite():return (total*abs(speed).upper()*abs(wt.sqrt()).upper()).upper(),clear,1,min(ft.real.lower(),fs.real.lower())
    if depth>=12:raise ArithmeticError('Proxy separation or speed branch could not be certified')
    widths=[tw,th,sw,sh];centers=[tc,ti,sc,si];j=max(range(4),key=lambda l:float(widths[l]));widths[j]/=2
    vals=[]
    for sign in [-1,1]:
      c=centers.copy();c[j]+=sign*widths[j]
      vals.append(tile(c[0],widths[0],c[1],widths[1],c[2],widths[2],c[3],widths[3],depth+1))
    return max(x[0] for x in vals),min(x[1] for x in vals),sum(x[2] for x in vals),min(x[3] for x in vals)
  return tile(ct,rt,arb(0),rt,cs,rs,arb(0),rs,0)

def moment_basis(modes,hs,n):
  """Normalized power moments on [-1,1], with the entire exponential tail."""
  cut=96;f=acb_mat(len(modes),n+1)
  for i,m in enumerate(modes):
    z=I*m*hs;term=acb(1);series=[]
    for l in range(cut+1):
      series.append(term);term*=z/(l+1)
    tail=(2*hs*(abs(z).exp())*abs(z)**(cut+1)/math.factorial(cut+1)).upper()
    e=acb(arb(0,tail),arb(0,tail))
    for j in range(n+1):
      f[i,j]=2*hs*sum((series[l]/(j+l+1) for l in range(j%2,cut+1,2)),acb(0))+e
  return f

def moments(Ct,Cz,modes,c,F):
  phase=[(I*m*c).exp() for m in modes]
  co=acb_mat(2,len(modes),[C[i,0]*phase[i] for C in [Ct,Cz] for i in range(len(modes))]);V=co*F
  mids=[];err=[]
  for l in range(2):
    mids.append(acb_mat(V.ncols(),1,[V[l,j].mid() for j in range(V.ncols())]))
  for j in range(V.ncols()):err.append(absolute_vec(V[0,j]-mids[0][j,0],V[1,j]-mids[1][j,0]))
  return mids,err

def density_jet(C,modes,ct,h,p):
  coeff=[acb(0) for _ in range(p+1)]
  for i,m in enumerate(modes):
    z=C[i,0]*(I*m*ct).exp()
    for j in range(p+1):
      coeff[j]+=z;z*=I*m*h/(j+1)
  return acb_series(coeff,p+1)

def incident(data,ct,h,p,rt,K,Ct,Cz,modes):
  q=matrix(data['incident']);beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real
  t=acb_series([ct,h],p+1);x,y,dx,dy=geom(t,K.R,K.b);w=(dx*dx+dy*dy).sqrt()
  nx=dy/w;ny=-dx/w
  f=[density_jet(Ct,modes,ct,h,p),density_jet(Cz,modes,ct,h,p)]
  channels=data['rayleigh_modes'];N=len(channels)
  amplitudes=[]
  for idx,m in enumerate(channels):
    beta_m=beta+2*arb.pi()*m/d
    gamma=acb(K.k*K.k-beta_m**2).sqrt()
    for j,sign in enumerate([1,-1]):
      wall=-arb(sign)/2;am=q[j*N+idx,0]/d.sqrt()
      u=(((x-wall)*gamma*sign+y*beta_m)*I).exp()*am
      f[0]+=u;f[1]+=u*(nx*gamma*sign+ny*beta_m)*I
      amplitudes.append((sign,gamma,wall,beta_m,am))
  dens=fourier_bound(Ct,modes,rt)+fourier_bound(Cz,modes,rt)
  def envelope(c,a,b,h,depth):
    xb,yb,dx,dy=geom(acb(arb(c,a.upper()),arb(b,h.upper())),K.R,K.b)
    v2=dx*dx+dy*dy
    if not v2.real>0:
      if depth>=12:raise ArithmeticError('No analytic speed for incident envelope')
      if a>=h:return max(envelope(c+sg*a/2,a/2,b,h,depth+1) for sg in [-1,1])
      return max(envelope(c,a,b+sg*h/2,h/2,depth+1) for sg in [-1,1])
    nb=absolute_vec(dx,dy)/v2.real.lower().sqrt()
    env=dens
    for sign,gamma,wall,beta_m,am in amplitudes:
      phase=I*(sign*gamma*(xb-wall)+beta_m*yb)
      env+=abs(am)*phase.real.upper().exp()*(1+nb*(abs(gamma)+abs(beta_m)))
    return (env*abs(v2).upper().sqrt().sqrt()).upper()
  # A single finite rectangle gives the original panel-0 majorant. If its
  # magnitude division is indefinite, use the positive-real endpoint tiles.
  xb,yb,dxb,dyb=geom(box(ct,rt),K.R,K.b)
  wb=(dxb*dxb+dyb*dyb).sqrt();whole=None
  if wb.is_finite() and abs(wb)>0:
    nb=absolute_vec(dxb,dyb)/abs(wb)
    v=dens
    for sign,gamma,wall,beta_m,am in amplitudes:
      v+=abs((I*(sign*gamma*(xb-wall)+beta_m*yb)).exp()*am)*(1+nb*(abs(gamma)+abs(beta_m)))
    candidate=(v*abs(wb.sqrt())).upper()
    if candidate.is_finite():whole=candidate
  if whole is None:whole=envelope(ct,rt,arb(0),rt,0)
  return [[(v*w.sqrt())[j] for j in range(p+1)] for v in f],whole

def direct_check(K,T,S,B):
  tv,tn,x,y=T;sv,sn,u,v=S
  ct=direct_check.ct;cs=direct_check.cs
  _,_,xt,yt=geom(ct,K.R,K.b);_,_,xs,ys=geom(cs,K.R,K.b)
  vt=(xt*xt+yt*yt).sqrt();vs=(xs*xs+ys*ys).sqrt()
  nx,ny=yt/vt,-xt/vt;mx,my=ys/vs,-xs/vs
  sums=[acb(0) for _ in range(4)]
  for X,Y,c in K.charges:
    dx=x-u-X;dy=y-v-Y;q=dx*dx+dy*dy;r=q.sqrt();z=K.k*r
    g=I*c*(z.bessel_j(0)+I*z.bessel_y(0))/4
    gp=-I*c*K.k*(z.bessel_j(1)+I*z.bessel_y(1))/(8*r);gpp=-(4*gp+K.k**2*g)/(4*q)
    dn=2*(dx*nx+dy*ny);dm=2*(dx*mx+dy*my)
    for j,z in enumerate([-dm*gp,-g,-dn*dm*gpp-2*(nx*mx+ny*my)*gp,-dn*gp]):sums[j]+=z
  flags=[(z*vt.sqrt()*vs).overlaps(B[l][0,0]) for l,z in enumerate(sums)]
  assert all(flags),'Independent radial derivative check failed'
  return flags

def geometry_certificate(K,data):
  pi=arb.pi();maxy=arb(0);maxx=arb(0);orient=arb(100)
  for j in range(4096):
    t=arb((2*j+1)*pi/4096,(pi/4096).upper());x,y,dx,dy=geom(t,K.R,K.b)
    maxy=max(maxy,abs(y).upper());maxx=max(maxx,abs(x).upper());orient=min(orient,(x*dy-y*dx).lower())
  H=matrix(data['H'])[0,0].real
  assert 2*maxy<arb('.5') and 2*maxx<H and orient>0
  sep=min(max((abs(x)-H).lower(),(abs(y)-arb('.5')).lower()) for x,y,c in K.charges)
  assert sep>0
  return dict(height_span_upper=up(2*maxy),horizontal_span_upper=up(2*maxx),orientation_lower=str(orient),proxy_box_clearance_lower=str(sep),branch_integer=0)

def compute(data,out,idx,P,S,p,n,N,L,diag,cache=None,depth=0,sub=0):
  if cache is not None:cache.validate(data,P,S,n,N)
  K=Proxy(data);piece=data['pieces'][0];Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);modes=piece['modes']
  pi=arb.pi();base=pi/P;ht=base/(2**depth);ct=2*idx*base+(2*sub+1)*ht;hs=pi/S;rt=arb('.04');rs=arb('.055');a=arb('.0625')
  assert ht<rt<a and hs<rs and L>=2
  tag=str(idx) if depth==0 else f'{idx}-d{depth}-s{sub}'
  start=time.perf_counter();cpu_start=time.process_time()
  cf,eself,Mself,srec=coefficients(K,ct,ht,p,Ct,Cz,modes,rt,a,N,L,cache)
  dump(out/f'self-{tag}.json',srec)
  assert srec['gates']['node_radius'] and srec['gates']['conversion'], 'Node or conversion arithmetic gate failed'
  degree=srec['degree']
  self_cf=[row.copy() for row in cf]
  local,Mlocal=incident(data,ct,ht,p,rt,K,Ct,Cz,modes)
  cf=[[v+(lr[j] if j<=p else 0) for j,v in enumerate(row)] for row,lr in zip(cf,local)]
  times=dict(moments=0.,geometry=0.,mixed=0.,envelopes=0.,contraction=0.)
  t=time.perf_counter();F=moment_basis(modes,hs,n) if cache is None else cache.F;times['moments']+=time.perf_counter()-t
  iz=modes.index(0)
  for j in range(n+1):
    ctx.prec=384
    exact=2*arb.pi()/(S*(j+1)) if j%2==0 else arb(0)
    ctx.prec=128
    assert F[iz,j].contains(exact),'Zero Fourier mode moment disagrees'
  D=2*hs*sum((absolute_vec(Ct[j,0],Cz[j,0]) for j in range(len(modes))),arb(0))
  t=time.perf_counter();T=translate(ct,ht,p,K.k,K.R,K.b,False);times['geometry']+=time.perf_counter()-t
  trunc=arb(0);merr=arb(0);Mproxy=arb(0);checks=[];source_records=[]
  for j in range(S):
    cs=(2*j+1)*hs
    t=time.perf_counter();Sjet=translate(cs,hs,n,K.k,K.R,K.b,True) if cache is None else cache.jets[j];times['geometry']+=time.perf_counter()-t
    t=time.perf_counter();B=K.pair(T,Sjet,p,n);times['mixed']+=time.perf_counter()-t
    if j==0:
      direct_check.ct=ct;direct_check.cs=cs;checks=direct_check(K,T,Sjet,B)
    t=time.perf_counter();mom,dm=moments(Ct,Cz,modes,cs,F) if cache is None else cache.moments[j];times['moments']+=time.perf_counter()-t
    t=time.perf_counter()
    for l in range(2):
      V=B[2*l]*mom[0]+B[2*l+1]*mom[1]
      for i in range(p+1):cf[l][i]+=V[i,0]
    times['contraction']+=time.perf_counter()-t
    t=time.perf_counter();M,sep,tiles,speed=proxy_envelope(K,ct,cs,rt,rs);times['envelopes']+=time.perf_counter()-t
    er=M*D*(hs/rs)**(n+1)/(1-hs/rs);em=M*sum((d*(hs/rs)**i for i,d in enumerate(dm)),arb(0))
    trunc+=er;merr+=em;Mproxy+=M*D
    source_records.append(dict(panel=j,M_upper=up(M),distance_squared_lower=str(sep),speed_square_lower=str(speed),moment_radii_max=up(max(dm)),tiles=tiles,CM_trunc=up(er),moment_error=up(em)))
  growth=1/(1-ht/rt);Mtotal=Mlocal+Mproxy
  pcf=[[x.mid() for x in row] for row in cf];pcf[1]=[-x for x in pcf[1]]
  balls=sum((absolute_vec(cf[0][j]-pcf[0][j],cf[1][j]+pcf[1][j]) for j in range(degree+1)),arb(0))
  tail=Mtotal*(ht/rt)**(p+1)*growth
  coeff_radii=[up(absolute_vec(cf[0][j]-pcf[0][j],cf[1][j]+pcf[1][j])) for j in range(degree+1)]
  errors=[eself,trunc*growth,merr*growth,balls,tail,arb(0)]
  names=['self_SI8','CM_truncation','moment_radii','coefficient_balls','other_target_tail','moving_cut']
  e=sum(errors,arb(0))
  V=2*ht*sum(((row[i].conjugate()*row[j]).real/(i+j+1) for row in pcf for i in range(degree+1) for j in range(i%2,degree+1,2)),arb(0))
  assert V.upper()>=0
  bound=V.upper().sqrt()+(2*ht).sqrt()*e
  r=dict(panel=idx,depth=depth,sub=sub,P=P,S=S,p=degree,other_p=p,n=n,angular_interval=[str(ct-ht),str(ct+ht)],h=str(ht),Rt=str(rt),Rs=str(rs),source_strip=str(a),
    self_record=srec,source_records=source_records,direct_radial_check=checks,times=times,M_I_upper=up(Mtotal),M_local_upper=up(Mlocal),M_proxy_upper=up(Mproxy),
    geometry_certificate=geometry_certificate(K,data),scaled_coefficient_radii=coeff_radii,density_integral_upper=up(D),terms={k:up(v) for k,v in zip(names,errors)},V=str(V),e_upper=up(e),epsilon_panel_upper=up(bound),
    polynomial=[[ [str(x.real),str(x.imag)] for x in row] for row in pcf],seconds=time.perf_counter()-start)
  r['reuse_counts']=dict(source_jets=S if cache is not None else 0,source_moments=S if cache is not None else 0,kress_source_points=N if cache is not None else 0)
  r['control']=control(K,ct,ht,Ct,Cz,modes,self_cf,eself,srec)
  r['cpu_seconds']=time.process_time()-cpu_start
  r['total_seconds_with_controls']=time.perf_counter()-start
  dump(out/f'panel-{tag}.json',r)
  assert all(v['passed'] for v in r['control']['points']), 'Independent control point failed'
  r['working_error_gate_passed']=srec['gates']['self_error']
  return r

def main():
  ap=argparse.ArgumentParser();ap.add_argument('--input',required=True);ap.add_argument('--output',required=True)
  ap.add_argument('--stage',choices=['sample','panels'],required=True);ap.add_argument('--first',type=int,default=0);ap.add_argument('--count',type=int,default=1)
  ap.add_argument('--P',type=int,default=192);ap.add_argument('--S',type=int,default=160);ap.add_argument('--p',type=int,default=52);ap.add_argument('--n',type=int,default=40)
  ap.add_argument('--N',type=int,default=1152);ap.add_argument('--L',type=int,default=40)
  args=ap.parse_args();out=Path(args.output);data=json.loads(Path(args.input).read_text())
  for i in range(args.first,args.first+args.count):compute(data,out,i,args.P,args.S,args.p,args.n,args.N,args.L,args.stage=='sample')
if __name__=='__main__':main()
