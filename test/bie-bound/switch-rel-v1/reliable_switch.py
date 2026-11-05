"""Reliable switch-line bounds. BIE: boundary integral equation; MFS: method of fundamental solutions.
Input: exact binary64 export, output directory, explicitly selected stage.
Output: Arb enclosures, certified scalar upper bounds, counts and stage timings.
All numerical bounds after decoding use python-flint Arb/Acb arithmetic.
"""
import argparse,json,math,struct,time
from pathlib import Path
import flint
from flint import arb,acb,acb_mat,ctx
ctx.prec=128
I=acb(0,1)
HANKELS=0

def upper(x):
  x=abs(x) if isinstance(x,acb) else x
  if x.is_zero():return 0.0
  y=float(x.upper())
  while not arb(str(y))>x:y=math.nextafter(y,math.inf)
  return y

def pack(x):
  if isinstance(x,acb):return [str(x.real),str(x.imag)]
  return str(x)

def unpack(x):return acb(arb(x[0]),arb(x[1]))

def exact(h):return arb(struct.unpack('>d',bytes.fromhex(h))[0])

def matrix(o):
  nr,nc=o['shape'];re=o['real'];im=o['imag']
  if isinstance(re,str):re=[re];im=[im]
  return acb_mat(nr,nc,[acb(exact(re[i+j*nr]),exact(im[i+j*nr])) for i in range(nr) for j in range(nc)])

def scalar(o):return matrix(o)[0,0]

def normf(A):return sum((abs(A[i,j])**2 for i in range(A.nrows()) for j in range(A.ncols())),arb(0)).sqrt()

def part(out,s):
  (out/'part.txt').write_text(s);print(s,flush=True)

def save(out,name,data):
  (out/name).write_text(json.dumps(data,indent=2))

class Kernel:
  def __init__(self,data):
    self.k=scalar(data['k']).real;self.d=scalar(data['d']).real;self.H=scalar(data['H']).real
    self.q=scalar(data['phase']);self.qm=scalar(data['phase_minus']);self.beta=scalar(data['beta']).real
    Z=matrix(data['proxy_Z']);c=matrix(data['proxy_c']);self.terms=[(arb(0),arb(0),acb(1))]
    self.clearance=[]
    for j in range(Z.ncols()):
      x=Z[0,j].real;y=Z[1,j].real
      dx=abs(x)-self.d/2;dy=abs(y)-self.H
      assert dx>0 or dy>0,'Proxy intersects closed kernel box'
      self.clearance.append(max(dx.lower(),dy.lower()))
      self.terms.append((x,y,c[0,j] if c.nrows()==1 else c[j,0]))
    for p in data['pieces']:assert p['proxy_equal'],'Distinct exterior kernels need separate tables'
  def branch(self,Y,side,envelope=False):
    global HANKELS
    a=[acb(0),acb(0),acb(0)];b=[arb(0),arb(0),arb(0)]
    for zx,zy,c in self.terms:
      dx=side*self.d/2-zx;dy=Y-zy;rr=dx*dx+dy*dy
      assert rr.real>0,'Complex ellipse crosses square-root branch cut'
      r=rr.sqrt();z=self.k*r
      h0=z.bessel_j(0)+I*z.bessel_y(0);h1=z.bessel_j(1)+I*z.bessel_y(1);HANKELS+=2
      f=I*c*h0/4;g=-I*c*self.k*h1/(4*r);v=[f,g*dy,g*dx]
      for j in range(3):
        if envelope:b[j]+=abs(v[j])
        else:a[j]+=v[j]
    return b if envelope else a
  def jumps(self,Y):
    low=self.branch(Y,1);up=self.branch(Y,-1)
    return [self.q*up[j]-low[j] for j in range(3)]+[up[j]-self.qm*low[j] for j in range(3)]
  def envelope(self,c,a,rho):
    # This rectangle contains the closed Bernstein ellipse in the physical Y plane.
    rad=a*(rho+1/rho)/2;Y=acb(arb(c,rad.upper()),arb(0,rad.upper()))
    lo=self.branch(Y,1,True);hi=self.branch(Y,-1,True)
    return [abs(self.q)*hi[j]+lo[j] for j in range(3)]+[hi[j]+abs(self.qm)*lo[j] for j in range(3)]

def kernel_panels(K,count=64,n=40,only=0):
  rho=arb(4);a=arb(7)/(8*count);panels=[];global_bounds=[arb(0)]*6
  angles=[arb.pi()*(2*j+1)/(2*n) for j in range(n)]
  nodes=[a.cos() for a in angles];cosines=[[ (l*t).cos() for t in angles] for l in range(n)]
  for k in range(only or count):
    t=time.perf_counter();c=-arb(7)/8+(2*k+1)*a;env=K.envelope(c,a,rho)
    vals=[K.jumps(acb(c+a*x)) for x in nodes]
    coeff=[];errors=[];sup=[]
    for l in range(6):
      co=[sum((vals[j][l]*cosines[m][j] for j in range(n)),acb(0))*2/n for m in range(n)];co[0]/=2
      er=4*env[l]*rho**(1-n)/(rho-1)
      su=sum((abs(v) for v in co),arb(0))+er
      coeff.append([pack(v) for v in co]);errors.append(pack(er));sup.append(upper(su))
      global_bounds[l]=max(global_bounds[l],su.upper())
    panels.append({'center':pack(c),'halfwidth':pack(a),'coeff':coeff,'error':errors,'sup':sup,'envelope':[upper(x) for x in env], 'seconds':time.perf_counter()-t})
    if k%8==0:print('kernel panel',k,'seconds',panels[-1]['seconds'],flush=True)
  return {'panels':panels,'count':count,'nodes':n,'rho':4,'range':['-0.875','0.875'],'global_sup':[upper(x) for x in global_bounds]}

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--stage',choices=['pilot','kernel','integrate','all'],required=True);p.add_argument('--kernel');p.add_argument('--sources',type=int,default=512);p.add_argument('--micro',type=int,default=1024);a=p.parse_args()
  out=Path(a.output);out.mkdir(parents=True,exist_ok=True);start=time.perf_counter();data=json.loads(Path(a.input).read_text());K=Kernel(data)
  if a.stage in ['pilot','kernel','all']:
    part(out,'kernel');t=time.perf_counter();v=K.jumps(acb(arb(1)/8));unit=time.perf_counter()-t
    result={'unit_kernel_seconds':unit,'unit_kernel_Hankels':HANKELS,'unit_jump':[pack(x) for x in v], 'proxy_min_clearance_lower':pack(min(K.clearance)), 'phase_modulus_defect':pack(abs(K.q)**2-1)}
    result['kernel']=kernel_panels(K,only=1 if a.stage=='pilot' else 0)
    result.update(seconds=time.perf_counter()-start,hankel_evaluations=HANKELS,precision=ctx.prec)
    save(out,'kernel.json',result);print({k:v for k,v in result.items() if k!='kernel'},flush=True)
    if a.stage=='all':integrate(data,result,out,start,a.sources,a.micro)
  else:
    integrate(data,json.loads(Path(a.kernel).read_text()),out,start,a.sources,a.micro)



def constants(data):
  mu=scalar(data['k']).real**2;beta=scalar(data['beta']).real;d=scalar(data['d']).real
  delta=arb(1)/5;eta=arb(1165764)/1000000;D0=(1+eta)/(2*delta);D1=(1+1/eta)*delta/6
  aa=D0;bb=D1+D0;cc=17*D1;lam0=beta**2/17
  values=[cc,(aa+bb*lam0+cc*lam0**2)/(lam0+mu)**2]
  den=2*cc*mu-bb
  if not den.contains(0):
    ls=(2*aa-bb*mu)/den
    if ls>lam0:values.append((aa+bb*ls+cc*ls**2)/(ls+mu)**2)
  line=max(v.upper() for v in values).sqrt()
  assert 34*mu-20>0 and 17*mu**2-100>0
  omega=2*arb.pi()/d;M=1000
  S=sum((1/(4*d*(10+(beta+omega*m)**2)**arb('1.5')) for m in range(-M,M+1)),arb(0))
  tail=sum((1/((10+(omega*M+sg*beta)**2).sqrt()*((10+(omega*M+sg*beta)**2).sqrt()+omega*M+sg*beta)) for sg in [-1,1]),arb(0))/(4*d*omega)
  return mu,line,(17*(S+tail)).sqrt(),{'C_line_upper':upper(line),'S10_finite':pack(S),'S10_tail_upper':upper(tail),'C_point_upper':upper((17*(S+tail)).sqrt()),'volume_positive_coefficients':[pack(34*mu-20),pack(17*mu**2-100)],'eta':'1.165764'}

class Table:
  def __init__(self,obj,data,micro):
    self.panels=obj['kernel']['panels'];self.count=obj['kernel']['count'];self.a=arb(self.panels[0]['halfwidth']);self.step=arb(7)/(4*micro);self.micro=micro
    self.coeff=[[list(map(unpack,c)) for c in p['coeff']] for p in self.panels]
    # Enclose both the exported phase and the exact quasi-periodic phase.
    q=scalar(data['phase']);qm=scalar(data['phase_minus']);qe=(I*scalar(data['beta'])*scalar(data['d'])).exp()
    self.phase_error=[abs(qe-q)]*3+[abs(qe.conjugate()-qm)]*3
    self.errors=[]
    for p in self.panels:
      self.errors.append([arb(p['error'][j])+self.phase_error[j]*arb(str(p['envelope'][j]))/min(arb(1),abs(q).lower(),abs(qm).lower()) for j in range(6)])
    self.global_sup=[max((sum((abs(x) for x in self.coeff[k][j]),arb(0))+self.errors[k][j]).upper() for k in range(self.count)) for j in range(6)]
    self.cells=[];self.prefix=[[acb(0)]*18]
    for j in range(micro):
      c=-arb(7)/8+(j+arb('0.5'))*self.step;y=arb(c,self.step.upper()/2)
      # micro is a multiple of the analytic-panel count; no cell crosses a polynomial panel.
      k=j*self.count//micro;v=self.evaluate_in_panel(y,k)
      self.cells.append(v);mom=[]
      for side in range(2):
        g=v[3*side:3*side+3]
        mom.extend([g[ii].conjugate()*g[jj]*self.step for ii in range(3) for jj in range(3)])
      self.prefix.append([a+b for a,b in zip(self.prefix[-1],mom)])
  def evaluate_in_panel(self,y,k):
    t=(y-arb(self.panels[k]['center']))/self.a;v=[]
    for j in range(6):
      co=self.coeff[k][j];b1=acb(0);b2=acb(0)
      for a in reversed(co[1:]):b0=a+2*t*b1-b2;b2,b1=b1,b0
      z=co[0]+t*b1-b2;e=self.errors[k][j].upper()
      v.append(z+acb(arb(0,e),arb(0,e)))
    return v
  def index(self,y,lower):
    # Float only selects a candidate index; exact Arb comparisons widen it if needed.
    q=(y+arb(7)/8)/self.step;j=max(0,min(self.micro-1,int(float(q.mid()))))
    if lower:
      while j>0 and not (-arb(7)/8+j*self.step)<=y:j-=1
    else:
      while j<self.micro-1 and not (-arb(7)/8+(j+1)*self.step)>=y:j+=1
    return j
  def point(self,y):
    lo=self.index(y.lower(),True);hi=self.index(y.upper(),False)
    v=self.cells[lo].copy()
    for k in range(lo+1,hi+1):v=[acb(a.real.union(b.real),a.imag.union(b.imag)) for a,b in zip(v,self.cells[k])]
    return v
  def moments(self,x,side):
    lo=self.index((-arb('0.5')-x).lower(),True);hi=self.index((arb('0.5')-x).upper(),False)
    # The selected cell union contains every translated full-cell segment.
    return [self.prefix[hi+1][side*9+j]-self.prefix[lo][side*9+j] for j in range(9)]

class Density:
  def __init__(self,C,modes):
    self.C=C;self.modes=modes;self.lips=[]
    for j in range(C.ncols()):
      self.lips.append(sum((abs(C[i,j])*abs(m) for i,m in enumerate(modes)),arb(0)))
  def values(self,t,h,basis=None):
    if basis is None:basis=acb_mat(1,len(self.modes),[(I*m*t).exp() for m in self.modes])
    V=basis*self.C;out=[]
    for j,L in enumerate(self.lips):
      e=(L*h).upper();out.append(V[0,j]+acb(arb(0,e),arb(0,e)))
    return out

def map_bound(C):
  return sum((sum((abs(C[i,j])**2 for j in range(C.ncols())),arb(0)).sqrt() for i in range(C.nrows())),arb(0))

def prepare(piece):
  t=time.perf_counter();T=matrix(piece['tau_coeff']);Z=matrix(piece['zeta_coeff']);modes=piece['modes'];record={'name':piece['name']}
  if piece['name']=='center':
    return Density(T,modes),Density(Z,modes),None,dict(record,seconds=time.perf_counter()-t)
  G=matrix(piece['G']);P=matrix(piece['P']);c=matrix(piece['c']);T=T*G;Z=Z*G
  power=acb_mat(P.nrows(),P.ncols());
  for i in range(P.nrows()):power[i,i]=1
  norms=[arb(1)];contraction=None;scanned=[]
  for p in range(1,201):
    power=power*P;r=normf(power);scanned.append(upper(r))
    if r<1:contraction=(p,r);break
    norms.append(r)
  record['scanned_frobenius_upper']=scanned
  if contraction is None:
    record['status']='NO_CONTRACTION';record['seconds']=time.perf_counter()-t
    return None,None,None,record
  p,r=contraction;N=40;states=acb_mat(P.nrows(),N);v=c
  for j in range(N):
    for i in range(P.nrows()):states[i,j]=v[i,0]
    v=P*v
  tailnorm=normf(v);Tbound=map_bound(T);Zbound=map_bound(Z)
  tail={'line_factor':tailnorm*(sum((x*x for x in norms),arb(0))/(1-r*r)).sqrt(),
    'end_factor':tailnorm*sum(norms,arb(0))/(1-r),'Tmap':Tbound,'Zmap':Zbound}
  record.update(p=p,r_upper=upper(r),state40_norm_upper=upper(tailnorm),map_tau_upper=upper(Tbound),map_zeta_upper=upper(Zbound),
    line_factor_upper=upper(tail['line_factor']),end_factor_upper=upper(tail['end_factor']),cells=N,status='CONTRACTIVE',seconds=time.perf_counter()-t)
  return Density(T*states,modes),Density(Z*states,modes),tail,record

def curve(piece,params,t):
  R,c3,elong,one,scale,an,ap,leadR=params
  if piece['name']=='center':
    fac=R*scale;xc=[(1,fac*elong),(4,fac*c3/2),(6,fac*c3/2)];yc=[(1,fac*one),(4,-fac*c3/2),(6,fac*c3/2)]
  else:
    a=an if piece['name']=='negative' else ap;fac=leadR/(1+a*a/2).sqrt()
    xc=[(1,fac),(2,fac*a/2),(4,fac*a/2)];yc=[(1,fac),(2,-fac*a/2),(4,fac*a/2)]
  mid=t.mid();h=t.rad();u=arb(0,h)
  x0=sum((v*(m*mid).cos() for m,v in xc),arb(0));y0=sum((v*(m*mid).sin() for m,v in yc),arb(0))
  dx0=sum((-m*v*(m*mid).sin() for m,v in xc),arb(0));dy0=sum((m*v*(m*mid).cos() for m,v in yc),arb(0))
  bx=sum((m*m*abs(v) for m,v in xc),arb(0));by=sum((m*m*abs(v) for m,v in yc),arb(0))
  x=x0+dx0*u+arb(0,(bx*h*h/2).upper());y=y0+dy0*u+arb(0,(by*h*h/2).upper())
  dx=dx0+arb(0,(bx*h).upper());dy=dy0+arb(0,(by*h).upper())
  sp=(dx*dx+dy*dy).sqrt();assert sp>0,'Curve regularity not certified'
  assert abs(x)<arb('0.375') and abs(y)<arb('0.25'),'Switch line may intersect an inclusion or exceed kernel table'
  orientation=x*dy-y*dx;assert orientation>0,'Star-shaped orientation not certified'
  return x,y,dy/sp,-dx/sp,sp,orientation

def integrate(data,kernel,out,start,N,micro):
  assert micro%kernel['kernel']['count']==0
  mu,Cl,Cp,cr=constants(data);part(out,'kernel-table');tt=time.perf_counter();tab=Table(kernel,data,micro);tabletime=time.perf_counter()-tt
  part(out,'independent-kernel-check');K=Kernel(data);checks=[];checkstart=time.perf_counter()
  for ys in ['-0.873','-0.613','-0.127','0.031','0.433','0.859']:
    y=arb(ys);direct=K.jumps(acb(y));q=(y+arb(7)/8)/(2*tab.a);k=int(float(q.mid()));c=arb(tab.panels[k]['center']);assert abs(y-c)<tab.a
    enc=tab.evaluate_in_panel(y,k)
    flags=[a.contains(b) for a,b in zip(enc,direct)]
    checks.append({'Y':ys,'all_contained':all(flags),'component_checks':flags,'direct':[pack(x) for x in direct],'enclosure':[pack(x) for x in enc]})
  save(out,'kernel-checks.json',{'points':checks,'seconds':time.perf_counter()-checkstart,'Hankels':HANKELS,'proxy_clearance_lower':pack(min(K.clearance))})
  assert all(x['all_contained'] for x in checks),'Independent kernel check failed'
  params=[matrix(data['curve_parameters'])[0,j].real for j in range(8)]
  result={'precision':ctx.prec,'python_flint_version':flint.__version__,'arb_threads':getattr(ctx,'threads',None),'source_panels':N,'kernel_micro_panels':micro,'constants':cr,'kernel_table_seconds':tabletime,'kernel_certificate_seconds':kernel['seconds'],'kernel_certificate_hankels':kernel['hankel_evaluations'],'pieces':[],'phase_correction_upper':[upper(x) for x in tab.phase_error], 'global_kernel_sup':[upper(x) for x in tab.global_sup],'independent_kernel_checks_pass':all(x['all_contained'] for x in checks)}
  g=[max(tab.global_sup[j],tab.global_sup[j+3]) for j in range(3)]
  total_line=arb(0);total_end=arb(0);coarse_line=arb(0);coarse_end=arb(0)
  for piece in data['pieces']:
    part(out,'prepare-'+piece['name']);dt,dz,tail,pr=prepare(piece);result['pieces'].append(pr);save(out,'bounds.json',result)
    if dt is None:result['status']='NO_CONTRACTION';save(out,'bounds.json',result);return
    part(out,'source-'+piece['name']);t0=time.perf_counter();sumline=arb(0);sumend=arb(0);roughline=arb(0);roughend=arb(0);length=arb(0);h=arb.pi()/N
    minclear=arb(1);minspeed=arb(100);minorient=arb(100);maxY=arb(0)
    for i in range(N):
      mid=(2*i+1)*h;t=arb(mid,h.upper());x,y,nx,ny,sp,orientation=curve(piece,params,t)
      minclear=min(minclear,(arb('0.25')-abs(y)).lower());minspeed=min(minspeed,sp.lower());minorient=min(minorient,orientation.lower());maxY=max(maxY,(abs(x)+arb('0.5')).upper());length+=2*h*sp.upper()
      basis=acb_mat(1,len(dt.modes),[(I*m*mid).exp() for m in dt.modes]);tv=dt.values(mid,h,basis);zv=dz.values(mid,h,basis)
      T2=sum((abs(v)**2 for v in tv),arb(0));Z2=sum((abs(v)**2 for v in zv),arb(0));C=sum((a.conjugate()*b for a,b in zip(tv,zv)),acb(0));T1=sum((abs(v) for v in tv),arb(0))
      sides=[1] if y>=0 else ([0] if y<0 else [0,1]);endsa=tab.point(-arb('0.5')-x);endsb=tab.point(arb('0.5')-x)
      sb=[];eb=[]
      for side in sides:
        H=tab.moments(x,side)
        aa=mu**2*ny**2*H[0].real+H[4].real+H[8].real
        bb=H[0].real+H[8].real
        cc=-mu*ny*H[2]+nx*H[3]+ny*H[6]
        sq=aa*T2+bb*Z2+2*(cc*C).real
        assert sq.upper()>0
        sb.append(sq.upper().sqrt())
        ea=abs(ny*endsa[3*side+1]-nx*endsa[3*side+2]);ebv=abs(ny*endsb[3*side+1]-nx*endsb[3*side+2]);eb.append(((ea+ebv)*T1).upper())
      sumline+=2*h*sp.upper()*max(v.upper() for v in sb);sumend+=2*h*sp.upper()*max(eb)
      # Crude full-cell sup estimate; same source panels, no finite quadrature.
      roughsq=2*((mu**2*ny**2*g[0]**2+g[1]**2+g[2]**2)*T2+(g[0]**2+g[2]**2)*Z2)
      roughline+=2*h*sp.upper()*roughsq.upper().sqrt();roughend+=2*h*sp.upper()*2*(abs(ny)*g[1]+abs(nx)*g[2])*T1.upper()
    lt=arb(0);et=arb(0)
    if tail:
      theta=2*((mu**2*g[0]**2+g[1]**2+g[2]**2)*tail['Tmap']**2+(g[0]**2+g[2]**2)*tail['Zmap']**2)
      lt=tail['line_factor']*length*theta.sqrt();et=tail['end_factor']*length*2*(g[1]+g[2])*tail['Tmap']
    sumline+=lt;sumend+=et;roughline+=lt;roughend+=et
    ql=Cl*sumline;qe=Cp*sumend;total_line+=ql;total_end+=qe;coarse_line+=Cl*roughline;coarse_end+=Cp*roughend
    pr.update(source_seconds=time.perf_counter()-t0,orientation_lower=pack(minorient),max_needed_abs_Y_upper=upper(maxY),curve_length_upper=upper(length),height_quarter_clearance_lower=pack(minclear),speed_lower=pack(minspeed),
      line_integral_upper=upper(sumline),endpoint_integral_upper=upper(sumend),Q_line_upper=upper(ql),Q_end_upper=upper(qe),Q_switch_upper=upper(ql+qe),
      line_tail_integral_upper=upper(lt),endpoint_tail_integral_upper=upper(et),crude_Q_line_upper=upper(Cl*roughline),crude_Q_end_upper=upper(Cp*roughend))
    print(pr,flush=True);save(out,'bounds.json',result)
  Q=total_line+total_end;Qgrp=arb('4.008815436e-12');allows=[arb('6.352112e-11'),arb('6.986448e-10')]
  result.update(status='COMPLETE',Q_line_upper=upper(total_line),Q_end_upper=upper(total_end),Q_switch_upper=upper(Q),Q_switch_ball=pack(Q),
    crude_switch_upper=upper(coarse_line+coarse_end),ratio_to_floating_upper=upper(Q/arb('4.2679006033e-11')),
    mixed_Q_upper=upper(Q+Qgrp),mixed_margin_lower=[pack((v/(Q+Qgrp)).lower()) for v in allows],seconds=time.perf_counter()-start,hankel_evaluations=HANKELS)
  save(out,'bounds.json',result)

if __name__=='__main__':main()
