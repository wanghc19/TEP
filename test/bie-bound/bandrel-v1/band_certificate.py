"""Rounding-inclusive periodic-band certificate in Arb/Acb ball arithmetic.
Input: explicit exact geometry export, output, bits, pilot/full setting.
Output: interval assembly, 472 sign tests, cross-checks and timing records.
"""
import argparse,json,time,sys,struct,math,resource,runpy,io,contextlib
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import numpy as np
from scipy.linalg import eigh
from flint import arb,acb,acb_mat,fmpq,ctx
from floating import MN,END,N,J,SCALE,DIM,reproduce
I=acb(0,1)

def exact_float(x):
  p,q=float(x).as_integer_ratio();return arb(fmpq(p,q))
def upper(x):
  u=x.upper();v=float(u)
  while not arb(str(v))>u:v=math.nextafter(v,math.inf)
  return v
def lower(x):
  u=x.lower();v=float(u)
  while not arb(str(v))<u:v=math.nextafter(v,-math.inf)
  return v
def hull(a,b):return arb((a+b)/2,(abs(a-b)/2).upper())
def decode(data):
  return [exact_float(struct.unpack('>d',bytes.fromhex(s))[0]) for s in data['real']]
def adj(A):return A.conjugate().transpose()
def ball_matrix(A):
  return acb_mat(A.shape[0],A.shape[1],[acb(exact_float(z.real),exact_float(z.imag)) for z in A.ravel()])
def midpoint(A):
  return np.array([[complex(float(A[i,j].real.mid()),float(A[i,j].imag.mid())) for j in range(A.ncols())] for i in range(A.nrows())])
def hermitian(A):return (A+adj(A))/2

def assemble_B(R,a,Bfloat):
  start=time.perf_counter();pi=arb.pi();scale=R/(1+a*a/2).sqrt();s=arb(1)/10
  Cim=scale*(s.sinh()+a*((4*s).sinh()+(2*s).sinh())/2)
  C1=scale*(s.cosh()+a*(4*(4*s).cosh()+2*(2*s).cosh())/2)
  envelope=C1/(2*pi)*(48*pi*Cim).exp()
  assert Cim<arb('.033') and C1<arb('.33') and envelope<8 and scale*(1+a)<arb('.5')
  eb=32*pi/((s*J).exp()-1);X=[];Y=[];dx=[];dy=[]
  for j in range(J):
    t=2*pi*j/J;r=scale*(1+a*(3*t).cos());dr=-3*scale*a*(3*t).sin()
    x=r*t.cos();y=r*t.sin();dx.append(dr*t.cos()-r*t.sin());dy.append(dr*t.sin()+r*t.cos())
    X.append([(I*2*pi*m*x).exp() for m in range(-12,13)]);Y.append([(I*2*pi*n*y).exp() for n in range(-12,13)])
  yy=acb_mat(J,25,[Y[j][n] for j in range(J) for n in range(25)])
  xd=acb_mat(25,J,[X[j][m]*dy[j] for m in range(25) for j in range(J)])
  xx=acb_mat(25,J,[X[j][m]*dx[j] for m in range(25) for j in range(J)])
  sy=xd*yy;sx=xx*yy;coeff={}
  for m in range(-12,13):
    for n in range(-12,13):
      coeff[m,n]=acb(pi*R*R) if m==n==0 else -I*(m*sy[m+12,n+12]-n*sx[m+12,n+12])/(J*(m*m+n*n))
  B=hermitian(acb_mat(DIM,DIM,[coeff[int(mj-mi),int(nj-ni)] for mi,ni in MN for mj,nj in MN]))
  # B encloses the quadrature matrix for the full parameter hull. The analytic
  # coefficient remainder is propagated separately by the Appendix A formulas.
  error=arb(0);rad=arb(0)
  for i in range(DIM):
    for j in range(DIM):
      z=acb(exact_float(Bfloat[i,j].real),exact_float(Bfloat[i,j].imag))
      error=max(error,abs(B[i,j]-z).upper());rad=max(rad,abs(B[i,j]-B[i,j].mid()).upper())
  assert error<arb('1e-12')
  M=16*B
  for i in range(DIM):M[i,i]+=1
  G=hermitian(256*(B-B*B))
  return B,M,G,dict(seconds=time.perf_counter()-start,geometry_radius=str(R),geometry_a=str(a),
    strip_Cim_upper=upper(Cim),strip_C1_upper=upper(C1),integrand_envelope_upper=upper(envelope),
    coefficient_analytic_error=str(eb),coefficient_rounding_geometry_radius=upper(rad),
    floating_B_entry_error_bound=upper(error+eb),floating_B_norm_error_bound=upper(DIM*(error+eb)),zero_frequency=str(pi*R*R))

def scalars(panel,high_override=None):
  l,h=END[panel:panel+2];pi=arb.pi();theta=pi*(l+h)/(2*SCALE);r=pi*(h-l)/(2*SCALE)
  kl=arb(659)/500;ku=arb(19)/8;assert kl>r
  low=(kl-r)*(kl-r);high=(ku+r)*(ku+r) if high_override is None else high_override
  kin=[(2*pi*int(m)+theta)**2+(arb(1)/2+2*pi*int(n))**2 for m,n in MN]
  t1=(14*pi-theta)**2+arb(1)/4;t2=(14*pi-arb(1)/2)**2+theta**2
  tail=min(t1.lower(),t2.lower());den=tail-17*high;assert den>0
  eps=32*pi/((arb(J)/10).exp()-1);eb=DIM*eps;em=16*eb;eg=256*eb*(3+eb);err=high*em+high**2/den*eg
  return kin,low,high,den,em,err,dict(theta=str(theta),radius=str(r),low=str(low),high=str(high),tail_lower=str(tail),denominator=str(den),coefficient_error=str(eps),mass_error=str(em),G_error=str(eg),upper_error=str(err))
def matrices(M,G,panel,high_override=None):
  kin,low,high,den,em,err,rec=scalars(panel,high_override)
  L=-low*M;H=-high*M-high**2/den*G
  for i in range(DIM):L[i,i]+=kin[i];H[i,i]+=kin[i]-err
  return hermitian(L),hermitian(H),low*em,rec

def positive_subspace(H,V=None):
  start=time.perf_counter()
  if V is None:
    ev,V=eigh(midpoint(H),check_finite=False)
  else:ev=np.linalg.eigvalsh(midpoint(H))
  W=ball_matrix(V[:,1:]);C=hermitian(adj(W)*H*W);Gram=hermitian(adj(W)*W)
  g=arb('1e10');glo=arb('1e10');ghi=arb(0)
  for i in range(DIM-1):
    off=sum((abs(C[i,j]).upper() for j in range(DIM-1) if i!=j),arb(0))
    goff=sum((abs(Gram[i,j]).upper() for j in range(DIM-1) if i!=j),arb(0))
    g=min(g,(C[i,i].real-off).lower());glo=min(glo,(Gram[i,i].real-goff).lower());ghi=max(ghi,(Gram[i,i].real+goff).upper())
  assert glo>0
  margin=g/ghi
  return dict(passed=bool(g>0),margin_lower=lower(margin),compressed_lower=lower(g),Gram_lower=lower(glo),Gram_upper=upper(ghi),float_second=float(ev[1]),seconds=time.perf_counter()-start),V

def lower_test(L,correction):
  e,V=eigh(midpoint(L),subset_by_index=[0,0],check_finite=False);v=ball_matrix(V)
  norm=(adj(v)*v)[0,0].real;assert norm>0
  quotient=(adj(v)*L*v)[0,0].real/norm;bound=quotient+correction
  return dict(passed=bool(bound<0),margin_lower=lower(-bound),Rayleigh=str(quotient),correction=str(correction),floating_margin=-float(e[0])-float(correction.mid()))

def inertia(H):
  start=time.perf_counter();n=H.nrows();L=[[acb(0) for j in range(n)] for i in range(n)];D=[];neg=0;pos=0;minpivot=arb('1e10')
  for j in range(n):
    dj=H[j,j].real-sum(((L[j][k]*L[j][k].conjugate()).real*D[k] for k in range(j)),arb(0))
    if dj>0:pos+=1
    elif dj<0:neg+=1
    else:return dict(passed=False,pivot=j,pivot_ball=str(dj),seconds=time.perf_counter()-start)
    D.append(dj);minpivot=min(minpivot,abs(dj).lower());L[j][j]=1
    for i in range(j+1,n):L[i][j]=(H[i,j]-sum((L[i][k]*D[k]*L[j][k].conjugate() for k in range(j)),acb(0)))/dj
  return dict(passed=True,negative=neg,positive=pos,min_abs_pivot_lower=lower(minpivot),seconds=time.perf_counter()-start)

def failed_control(M,G):
  high=arb(10);steps=[]
  for attempt in range(10):
    _,H,_,rec=matrices(M,G,0,high);ev,V=eigh(midpoint(H),check_finite=False);steps.append(dict(high=str(high),floating_second=float(ev[1])))
    if ev[1]<-.01:break
    high*=arb(3)/2
  else:raise RuntimeError('No failing control found within positive complement budget')
  test,_=positive_subspace(H,V);assert not test['passed']
  W=ball_matrix(V[:,:2]);C=hermitian(adj(W)*H*W);Gr=adj(W)*W
  gmax=max((C[i,i].real+abs(C[i,1-i])).upper() for i in range(2))
  gmin=min((Gr[i,i].real-abs(Gr[i,1-i])).lower() for i in range(2))
  assert gmax<0 and gmin>0
  return dict(steps=steps,check=test,two_negative_directions_upper=upper(gmax),Gram_lower=lower(gmin),scalars=rec)

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--mode',choices=['pilot','full'],required=True);p.add_argument('--bits',type=int,default=128);p.add_argument('--enclosure');args=p.parse_args()
  start=time.perf_counter();cpu=time.process_time();ctx.prec=args.bits;ctx.threads=1;out=Path(args.output)
  data=json.loads(Path(args.input).read_text());pars=decode(data['curve_parameters']);R=hull(pars[7],arb(1)/5);aa=[hull(pars[5],arb(3)/25),hull(pars[6],arb(1)/5)]
  assert decode(data['beta'])[0]==arb(1)/2 and decode(data['d'])[0]==1
  f,Bfs=reproduce()
  captured=io.StringIO()
  with contextlib.redirect_stdout(captured):runpy.run_path(str(Path(__file__).with_name('original_reference.py')))
  original=json.loads(captured.getvalue());differences={k:abs(f[k]-v) for k,v in original.items() if k in f and isinstance(v,(int,float))}
  assert all(d<=1e-12*max(abs(original[k]),1e-100) for k,d in differences.items()),differences
  f['original_reproduction']=dict(printed=original,absolute_differences=differences)
  (out/'floating.json').write_text(json.dumps(f,indent=2));print('floating',f['min_lower_negative_margin'],f['min_upper_positive_margin'],flush=True)
  result=dict(mode=args.mode,bits=args.bits,panels=118,model=dict(beta='.5',d=1,L=1,rho_background=1,rho_inclusion=17),assembly=[],tests=[],independent=[])
  panels=[0,117] if args.mode=='pilot' else list(range(118))
  assert END[0]==0 and END[-1]==4096 and len(END)==119 and all(x<y for x,y in zip(END,END[1:]))
  for side,a in enumerate(aa):
    B,M,G,rec=assemble_B(R,a,Bfs[side]);result['assembly'].append(rec);print('assembly',side,rec['seconds'],flush=True)
    for panel in panels:
      L,H,corr,sc=matrices(M,G,panel);lo=lower_test(L,corr);hi,V=positive_subspace(H)
      row=dict(side=side,panel=panel,lower=lo,upper=hi,scalars=sc);result['tests'].append(row)
      (out/'result.json').write_text(json.dumps(result,indent=2))
      assert lo['passed'] and hi['passed'],(side,panel,lo,hi)
      if panel in [0,117]:
        ld=inertia(H);result['independent'].append(dict(side=side,panel=panel,LDL=ld,subspace=hi));assert ld['passed'] and ld['negative']==1 and ld['positive']==168
      if panel%20==0 or panel==117:print('panel',side,panel,lo['margin_lower'],hi['margin_lower'],flush=True)
    if side==0:result['failing_control']=failed_control(M,G)
  if args.enclosure:
    enc=json.loads(Path(args.enclosure).read_text())['assemblies'][0]
    lo,hi=[arb(x) for x in enc['mu_interval']]
    margins=[lo-(arb(659)/500)**2,(arb(19)/8)**2-hi]
    assert all(x>0 for x in margins)
    result['T15']=dict(mu_interval=enc['mu_interval'],margins=[str(x) for x in margins],margins_lower=[lower(x) for x in margins])
  result.update(status='PASS',sign_tests=2*len(result['tests']),seconds=time.perf_counter()-start,cpu_seconds=time.process_time()-cpu,peak_process_rss_bytes=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss)
  result['minima']=[dict(side=s,lower=min(t['lower']['margin_lower'] for t in result['tests'] if t['side']==s),upper=min(t['upper']['margin_lower'] for t in result['tests'] if t['side']==s)) for s in [0,1]]
  (out/'result.json').write_text(json.dumps(result,indent=2));print('PASS',result['minima'],result['seconds'],flush=True)
if __name__=='__main__':main()
