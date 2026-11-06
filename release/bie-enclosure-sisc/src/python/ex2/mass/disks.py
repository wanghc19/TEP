# Copied from test/bie-bound/gapedge-v1/mass/disks.py for release R2.
import gzip
# Stage C source: test/bie-bound/example2-v1/mass/disks.py; local adaptations only.
# B2 source: test/bie-bound/pipeline-v1/mass/disks.py; generalized model plumbing.
# Copied from test/bie-bound/matrel-v1/disks.py; pipeline adaptations documented in README.
"""Eight in-column disks and their certified Bessel mass lower bound.
Input: explicitly supplied same-run field and disk geometry. Output: disks.json.
"""
import argparse,math,time,sys,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from flint import arb,acb,ctx
from material import I,geom,matrix,up,dump
from self_interaction import box,fourier_bound

def shape(t,kind,P):
  if kind==0:return geom(t,P[0],P[1])
  a=P[4+kind];c=P[7]/(1+a*a/2).sqrt()
  r=c*(1+a*(3*t).cos());dr=-3*c*a*(3*t).sin()
  return r*t.cos(),r*t.sin(),dr*t.cos()-r*t.sin(),dr*t.sin()+r*t.cos()

def geometry(kind,x,y,r,P):
  pi=arb.pi();mind=arb(100);M=2048
  for j in range(M):
    t=arb((2*j+1)*pi/M,(pi/M).upper())
    sx,sy,tx,ty=shape(t,kind,P)
    assert sx*ty-sy*tx>0
    ds=(sx-x)**2+(sy-y)**2
    assert ds>r**2,'Disk is too close to the material boundary'
    mind=min(mind,ds.lower())
    # The whole path from origin to center stays on the same side of the curve.
    if not (x.is_zero() and y.is_zero()):
      cross=x*sy-y*sx;dot=x*sx+y*sy
      assert not cross.contains(0) or dot<0 or dot>x*x+y*y,'Unresolved radial side test'
  assert abs(x)+r<arb('.5') and abs(y)+r<arb('.5')
  return mind.sqrt().lower()

def eval_field(kind,x,y,k,Ct,Cz,modes,P,order):
  N=128;h=arb.pi()/N;R=2*h
  ds=[fourier_bound(C,modes,R) for C in [Ct,Cz]];sol=acb(0);err=arb(0);clear=arb(100)
  roots=[arb.legendre_p_root(order,j,True) for j in range(order)]
  def val(t,env):
    sx,sy,dx,dy=shape(t,kind,P);d1=x-sx;d2=y-sy;z=d1*d1+d2*d2;ss=dx*dx+dy*dy
    if not(z.real>0 and ss.real>0):return None,None
    rr=z.sqrt();arg=k*rr
    g=I*(arg.bessel_j(0)+I*arg.bessel_y(0))/4
    d=I*k*(arg.bessel_j(1)+I*arg.bessel_y(1))*(d1*dy-d2*dx)/(4*rr);v=-g*ss.sqrt()
    if env:return (abs(d)*ds[0]+abs(v)*ds[1]).upper(),z.real.lower()
    phase=[(I*m*t).exp() for m in modes];tau=sum((Ct[i,0]*e for i,e in enumerate(phase)),acb(0));sig=sum((Cz[i,0]*e for i,e in enumerate(phase)),acb(0))
    return d*tau+v*sig,z.real.lower()
  used=0
  def panel(c,a,dep):
    nonlocal err,sol,clear,used
    M,sep=val(box(c,2*a),True)
    if M is None or not M.is_finite():
      assert dep<12,'No analytic source panel for disk center'
      panel(c-a/2,a/2,dep+1);panel(c+a/2,a/2,dep+1);return
    clear=min(clear,sep);used+=1
    for v,w in roots:sol+=a*w*val(acb(c+a*v),False)[0]
    err+=8*a*M*arb(2)**(-2*order)
  for j in range(N):panel((2*j+1)*h,h,0)
  return sol,err,used,clear

def main():
  p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--order',type=int,default=14);args=p.parse_args()
  start=time.perf_counter();data=json.loads((gzip.decompress(Path(args.input).read_bytes()).decode() if str(args.input).endswith(".gz") else Path(args.input).read_text()));out=Path(args.output);D=matrix(data['disks']);params=matrix(data['curve_parameters']);P=[params[0,j].real for j in range(8)]
  empty=data['pieces'][0]['shape']=='none';assert D.nrows()==(3 if empty else 8);rows=[];lower=arb(0);pieces=[];centers=[];clearances=[]
  for p in data['pieces']:
    T=matrix(p['tau_coeff']);Z=matrix(p['zeta_coeff'])
    if p['name']!='center':
      state=matrix(p['G'])*matrix(p['c']);T=T*state;Z=Z*state
    pieces.append((T,Z,p['modes']))
  for j in range(D.nrows()):
    kind=int(float(D[j,0].real))-1;x,y,r,rho=[D[j,i].real for i in range(1,5)];assert rho in ([1] if empty else [4,17])
    if empty:
      assert kind==0;L=matrix(data['cell_widths'])[0,0].real;boundary=min(L/2-abs(x),arb('.5')-abs(y));assert boundary>r;xx=x
    else:xx=x+([0,-1,1][kind]);boundary=geometry(kind,x,y,r,P)
    for ox,oy,rr in centers:
      d=((xx-ox)**2+(y-oy)**2).sqrt()-rr-r
      assert d>0,'Selected disks overlap';clearances.append(d.lower())
    centers.append((xx,y,r));k=matrix(data['k'])[0,0].real*rho.sqrt()
    if empty:
      W=matrix(data['incident']);beta=matrix(data['beta'])[0,0].real;d=matrix(data['d'])[0,0].real;u=acb(0)
      for side in range(2):
        sign=1-2*side
        for l,m in enumerate(data['rayleigh_modes']):
          bm=beta+2*arb.pi()*m/d;gamma=acb(k*k-bm*bm).sqrt();u+=(I*((x+sign*L/2)*gamma*sign+y*bm)).exp()/d.sqrt()*W[side*97+l,0]
      e=arb(0);np=0;sep=boundary
    else:u,e,np,sep=eval_field(kind,x,y,k,*pieces[kind],P,args.order)
    amplitude=max(arb(0),(abs(u)-e).lower());arg=k*r
    J0=arg.bessel_j(0);J1=arg.bessel_j(1);mass=(rho*arb.pi()*r*r*(J0*J0+J1*J1)*amplitude**2).lower()
    lower+=mass;rows.append(dict(template=kind,xy=[str(xx),str(y)],radius=str(r),rho=str(rho),boundary_distance_lower=str(boundary),source_panels=np,complex_separation_lower=str(sep),quadrature_error=up(e),center_quadrature=[str(u.real),str(u.imag)],J0=str(J0),J1=str(J1),mass_lower=str(mass)))
    dump(out/'disks.json',dict(rows=rows,gauss_order=args.order,U_lower=str(lower.sqrt().lower()),seconds=time.perf_counter()-start))
  dump(out/'disks.json',dict(rows=rows,gauss_order=args.order,U_lower=str(lower.sqrt().lower()),pair_clearance_lower=str(min(clearances)),seconds=time.perf_counter()-start))
if __name__=='__main__':main()
