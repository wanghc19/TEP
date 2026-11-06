"""I1: direct two-sided traces of the actual cell-kernel field.
Input: exact field, fitted point sources, freshly computed residual directory.
Output: individual interior/exterior traces and comparison with certified models.
The independent evaluation uses separate wave numbers, a common Laplace layer,
Kress source sums, direct near-image layers and direct fitted point-source sums.
"""
import argparse,json,time,math,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,acb_mat,acb_poly,ctx
from material import I,matrix,Proxy,geom,up,dump
from self_interaction import source_grid,kress_at,self_domain,fourier_bound
from chebyshev import sharp
from expansion import norm,Sources,Expansion
from extended import incident,trace
from material_group import build
from map_models import evaluate

class SingleRegular:
  """G_k - G_L = a(q) log(q)+b(q), G_L=-log(q)/(4 pi).
  Entire coefficients and their derivatives are evaluated separately for k_e,k_i.
  The j=0 logarithm is in the common Laplace layer, never in the Muller difference.
  """
  def __init__(self,k):
    A=[];B=[];f=arb(1);harm=arb(0);pi=arb.pi()
    for j in range(41):
      if j:harm+=arb(1)/j;f*=-(k*k)/(4*j*j)
      A.append(-f/(4*pi) if j else arb(0))
      B.append((I/4+(-((k/2).log()+arb.const_euler())+harm)/(2*pi))*f)
    a=acb_poly(A);b=acb_poly(B)
    self.poly=[a,a.derivative(),a.derivative().derivative(),b,b.derivative(),b.derivative().derivative(),acb_poly(A[1:])]
    j=41;v=k*k/2;ratio=v/(j+1)**2*(arb(j+2)/(j+1))**3;assert ratio<1
    self.error=100*(j+1)**3*v**j/math.factorial(j)**2/(1-ratio)
  def eval(self,q):
    assert abs(q)<2
    e=acb(arb(0,self.error.upper()),arb(0,self.error.upper()))
    return [p(q)+e for p in self.poly]

def densities(C,modes,t,derivative=0):
  return sum((C[j,0]*(I*m)**derivative*(I*m*t).exp() for j,m in enumerate(modes)),acb(0))

def weights(t,N):
  co=[acb(0)]*N
  for m in range(1,N//2+1):
    zp=(I*m*t).exp();zm=(-I*m*t).exp()
    if m==N//2:co[m]=-(zp+zm)/(2*m)
    else:co[m]=-zp/m;co[-m]=-zm/m
  return acb.dft(co)

def laplace(t,K,Ct,Cz,modes,grid):
  """Individual Laplace traces: Kress log and analytic periodic cotangent PV.
  Maue's identity writes H_L tau = d_t S_L d_s tau. The cotangent
  part is integrated exactly on the finite Fourier density.
  """
  x,y,xt,yt=geom(t,K.R,K.b);vt=(xt*xt+yt*yt).sqrt();nx=yt/vt;ny=-xt/vt
  N=len(grid);ws=weights(t,N);v=acb(0);n=acb(0);pi=arb.pi()
  # A DFT of the derivative density avoids a repeated Fourier sum at every node.
  co=[acb(0)]*N
  for j,m in enumerate(modes):co[m%N]+=I*m*Ct[j,0]*N
  derivative=acb.dft(co,inverse=True)
  for j,(s,u,w,mx,my,tau,zeta) in enumerate(grid):
    dx=x-u;dy=y-w;q=dx*dx+dy*dy;dd=(t-s)/2;sn=dd.sin();assert abs(sn)>0
    H=q/(4*sn*sn)
    # tau,zeta already include the source speed.
    v+=(dx*mx+dy*my)*tau/(2*pi*q)+(ws[j]+H.log())*zeta/(4*pi)
    n+=(dx*nx+dy*ny)*zeta/(2*pi*q)
    smooth=-(dx*xt+dy*yt)/(2*pi*vt*q)+dd.cos()/(4*pi*vt*sn)
    n+=smooth*derivative[j]
  n=n*(2*pi/N)-sum((abs(m)*Ct[j,0]*(I*m*t).exp() for j,m in enumerate(modes)),acb(0))/(2*vt)
  return [v*(2*pi/N),n]

def smooth_direct(t,K,Ct,Cz,modes,grid,bc,Z,W,beta,d):
  x,y,xt,yt=geom(t,K.R,K.b);vt=(xt*xt+yt*yt).sqrt();nx=yt/vt;ny=-xt/vt
  values=[acb(0),acb(0)];proxy=[acb(0),acb(0)];pi=arb.pi()
  for shift in [-1,1]:
    phase=(I*beta*d*shift).exp()
    for s,u,v,mx,my,tau,zeta in grid:
      dx=x-u;dy=y-v-shift*d;q=dx*dx+dy*dy;r=q.sqrt();z=K.k*r
      g=I*(z.bessel_j(0)+I*z.bessel_y(0))/4
      gp=-I*K.k*(z.bessel_j(1)+I*z.bessel_y(1))/(8*r);gpp=-(4*gp+K.k*K.k*g)/(4*q)
      ns=2*(dx*mx+dy*my);nt=2*(dx*nx+dy*ny)
      values[0]+=phase*(-ns*gp*tau-g*zeta)*(2*pi/len(grid))
      values[1]+=phase*(-(2*(nx*mx+ny*my)*gp+nt*ns*gpp)*tau-nt*gp*zeta)*(2*pi/len(grid))
  for j in range(Z.ncols()):
    dx=x-Z[1,j];dy=y-Z[0,j];r=(dx*dx+dy*dy).sqrt();z=K.k*r
    g=I*(z.bessel_j(0)+I*z.bessel_y(0))/4
    grad=-I*K.k*(z.bessel_j(1)+I*z.bessel_y(1))/(4*r)
    proxy[0]+=bc[j,0]*g;proxy[1]+=bc[j,0]*grad*(dx*nx+dy*ny)
  inc=incident(K,beta,d,x,y)*W
  iv=[inc[0,0],nx*inc[1,0]+ny*inc[2,0]]
  return [values[i]+proxy[i]+iv[i] for i in range(2)],proxy,iv,values

def record_complex(v):return [[z.real.str(55),z.imag.str(55)] for z in v]

def point(data,fits,res,out,side):
  start=time.perf_counter();ctx.prec=192;ctx.cap=81;K=Proxy(data);pars=matrix(data['curve_parameters']);piece=data['pieces'][side]
  Ct=matrix(piece['tau_coeff']);Cz=matrix(piece['zeta_coeff']);modes=piece['modes'];Z=matrix(fits['Z']);beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real
  if side:
    K.R=(pars[0,7].real,);K.b=pars[0,4+side].real;c=matrix(piece['c']);W=matrix(piece['G'])*c;Ct=Ct*W;Cz=Cz*W;bc=matrix(fits['B_positive' if side==2 else 'B_negative'])*c;P=64;rho=arb(17)
  else:W=matrix(data['incident']);bc=matrix(fits['B_center']);P=192;rho=arb(4)
  u=arb(1)/7;ht=arb.pi()/P;t=acb(ht*(1+u));_,_,dx,dy=geom(t,K.R,K.b);speed=(dx*dx+dy*dy).sqrt();weight=speed.sqrt()
  # Recompute the production model on a single actual state, not a port proxy.
  if not side:
    r=json.loads((res/'B-panel-0-d0-s0-M52.json').read_text());cf=[acb_poly([acb(arb(z[0]),arb(z[1])) for z in row]) for row in r['polynomial']]
    model=[cf[0](u),-cf[1](u)];model_error=arb(str(r['e_I']))
  else:
    V=matrix(piece['c']);cf,e,_,_,rr,errs=build(K,piece,matrix(fits['B_positive']),Z,beta,d,out,'i1-right-state',(W,V),idx=0)
    ctx.prec=192;v=evaluate(cf,u);model=[v[0,0],v[1,0]];model_error=errs[0]
  ctx.prec=256;N=4096;grid=source_grid(N,Ct,Cz,modes,K.R,K.b);values=[];errors=[];domains=[]
  for k in [K.k,K.k*rho.sqrt()]:
    rad=SingleRegular(k);HA,HB,dom=self_domain(k,K.R,K.b,t.real,arb(0),arb('.08'),Ct,Cz,modes,rad)
    values.append([z/weight for z in kress_at(t,rad,K.R,K.b,grid)])
    errors.append(sharp(HA,HB,arb('.08'),N));domains.append(dom)
  lp=laplace(t,K,Ct,Cz,modes,grid)
  smooth,proxy,inc,near=smooth_direct(t,K,Ct,Cz,modes,grid,bc,Z,W,beta,d)
  tau=densities(Ct,modes,t);zeta=densities(Cz,modes,t)
  outer=[lp[i]+values[0][i]+[tau,zeta][i]/2+smooth[i] for i in range(2)]
  inner=[lp[i]+values[1][i]-[tau,zeta][i]/2 for i in range(2)]
  jump=[outer[i]-inner[i] for i in range(2)];weighted=[weight*z for z in jump]
  # The exact common Laplace potential cancels between the two traces.
  # Its source quadrature error therefore contributes zero to their difference.
  # Smooth near-image source remainder uses a deliberately loose analytic
  # strip bound. Check its geometric/density hypotheses before using it.
  from panel import proxy_envelope
  old=K.charges;K.charges=[(arb(0),arb(m)*d,(I*beta*d*m).exp()) for m in [-1,1]]
  ds=fourier_bound(Ct,modes,arb('.08'))+fourier_bound(Cz,modes,arb('.08'));major=arb(0)
  for j in range(128):
    B,sep,tiles,sp=proxy_envelope(K,t.real,(2*j+1)*arb.pi()/128,arb(0),arb('.08'))
    major=max(major,B)
  K.charges=old
  nearerror=4*arb.pi()*major*ds/((arb('.08')*N).exp()-1)
  directerror=sum(errors,arb(0))+nearerror+norm([z-z.mid() for z in weighted])
  diff=norm([weighted[i]-model[i] for i in range(2)]);allow=model_error+directerror
  rec=dict(side=side,panel=0,point=str(t),normalized_point=str(u),source_nodes=N,bits=256,
    exterior_trace=record_complex(outer),interior_trace=record_complex(inner),direct_jump=record_complex(jump),weighted_direct_jump=record_complex(weighted),evaluator_weighted_jump=record_complex(model),
    proxy_trace=record_complex(proxy),proxy_trace_norm=up(norm(proxy)),incident_trace=record_complex(inc),near_image_trace=record_complex(near),common_laplace_trace=record_complex(lp),
    domains=domains,regular_Kress_errors=list(map(up,errors)),near_source_error=up(nearerror),direct_error_upper=up(directerror),evaluator_error_upper=up(model_error),difference_upper=up(diff),allowance_upper=up(allow),passed=bool(diff<=allow),seconds=time.perf_counter()-start,
    convention='outer minus inner, both derivatives in the inclusion-outward normal; evaluator second row sign restored for the center',
    common_term='The same exact Laplace layer is present in both traces and cancels algebraically; its displayed quadrature value is diagnostic only.')
  dump(out/f'traces-{side}.json',rec);assert rec['passed'],'Actual two-sided trace disagrees with certified evaluator'
  return rec

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--coefficients',required=True);p.add_argument('--residuals',required=True);p.add_argument('--output',required=True);a=p.parse_args();out=Path(a.output);out.mkdir(parents=True,exist_ok=True)
  data=json.loads(Path(a.input).read_text());fits=json.loads(Path(a.coefficients).read_text());t=time.perf_counter();rows=[]
  for side in [0,2]:rows.append(point(data,fits,Path(a.residuals),out,side))
  dump(out/'result.json',dict(passed=all(r['passed'] for r in rows),targets=rows,seconds=time.perf_counter()-t))
if __name__=='__main__':main()
