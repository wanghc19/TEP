"""PWE (plane-wave expansion) full-phase floating band diagrams.
Adapted from rounding-estimate-v1/band/h-band-reproduce.py indicator formula.
Input: explicit periods, rotation, cutoff list, output. Output: sampled bands,
locally optimized extrema, convergence, normalization and geometry CSV.
This is floating Galerkin exploration, not a certified band exclusion.
"""
import argparse,csv,json,time
from pathlib import Path
import numpy as np
from scipy.linalg import eigh
from scipy.optimize import minimize_scalar

def geometry(t,a,angle):
 r=.2/np.sqrt(1+a*a/2)*(1+a*np.cos(3*t));dr=-.6*a/np.sqrt(1+a*a/2)*np.sin(3*t)
 x=r*np.cos(t);y=r*np.sin(t);dx=dr*np.cos(t)-r*np.sin(t);dy=dr*np.sin(t)+r*np.cos(t)
 c=np.cos(angle);s=np.sin(angle)
 return c*x-s*y,s*x+c*y,c*dx-s*dy,s*dx+c*dy

def band(N,L,a,angle,beta,points,out,side):
 started=time.perf_counter();J=2048;t=2*np.pi*np.arange(J)/J;x,y,dx,dy=geometry(t,a,angle)
 mn=np.array([(m,n) for m in range(-N,N+1) for n in range(-N,N+1)])
 integers=np.arange(-2*N,2*N+1);coeff=np.empty((4*N+1,4*N+1),complex)
 for i,m in enumerate(integers):
  qx=2*np.pi*m/L;qy=2*np.pi*integers[:,None];q2=qx*qx+qy*qy
  wave=np.exp(1j*(qx*x[None,:]+qy*y[None,:]));flux=qx*dy[None,:]-qy*dx[None,:]
  integ=np.sum(wave*flux,axis=1)*2*np.pi/J;nz=q2[:,0]>0
  coeff[i,nz]=-1j*integ[nz]/q2[nz,0]/L
  if m==0:coeff[i,2*N]=.04*np.pi/L
 dm=mn[None,:,0]-mn[:,None,0];dn=mn[None,:,1]-mn[:,None,1]
 B=coeff[dm+2*N,dn+2*N];B=(B+B.conj().T)/2;mass=np.eye(len(mn))+16*B
 def ev(phi):
  kin=((2*np.pi*mn[:,0]+phi)/L)**2+(beta+2*np.pi*mn[:,1])**2
  return np.sqrt(eigh(np.diag(kin),mass,subset_by_index=[0,3],eigvals_only=True,check_finite=False))
 phases=np.linspace(-np.pi,np.pi,points);values=np.array([ev(p) for p in phases])
 with (out/f'bands-{side}-N{N}.csv').open('w') as f:
  w=csv.writer(f);w.writerow(['phase','theta','k1','k2','k3','k4']);w.writerows([p,p/L,*v] for p,v in zip(phases,values))
 edges=[]
 for j,sgn in [(0,-1),(1,1)]:
  f=sgn*values[:,j];items=[(phases[0],values[0,j]),(phases[-1],values[-1,j])]
  for i in range(1,len(phases)-1):
   if f[i]<=f[i-1] and f[i]<=f[i+1]:
    r=minimize_scalar(lambda p:sgn*ev(p)[j],bounds=(phases[i-1],phases[i+1]),method='bounded',options={'xatol':1e-10})
    items.append((r.x,sgn*r.fun))
  edges.append(min(items,key=lambda z:sgn*z[1]))
 result=dict(side=side,N=N,dimension=len(mn),L=L,a=a,rotation=angle,beta=beta,phase_range=[-float(np.pi),float(np.pi)],phase_points=points,quadrature_nodes=J,normalization='1/(L*d), d=1',B00=float(B[0,0].real),expected_B00=float(.04*np.pi/L),hermitian_error=float(np.linalg.norm(B-B.conj().T)),lower_edge=dict(phase=edges[0][0],k=edges[0][1]),upper_edge=dict(phase=edges[1][0],k=edges[1][1]),reflection_band_difference=np.max(abs(values-values[::-1]),axis=0).tolist(),seconds=time.perf_counter()-started)
 print(json.dumps(result),flush=True);return result

def main():
 p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--right-period',type=float,default=.85);p.add_argument('--rotation',type=float,default=.13);p.add_argument('--center-width',type=float,default=1);p.add_argument('--beta',type=float,default=.5);p.add_argument('--cutoffs',type=int,nargs='+',default=[6,8]);p.add_argument('--points',type=int,default=129);a=p.parse_args();out=Path(a.output);out.mkdir(parents=True,exist_ok=True);start=time.perf_counter();rows=[]
 for N in a.cutoffs:
  for side,L,shape,angle in [('negative',1,.12,0),('positive',a.right_period,.20,a.rotation)]:
   rows.append(band(N,L,shape,angle,a.beta,a.points,out,side));(out/'bands.json').write_text(json.dumps(dict(rows=rows,seconds=time.perf_counter()-start),indent=2))
 with (out/'geometry.csv').open('w') as f:
  w=csv.writer(f);w.writerow(['side','cell','t','x','y']);t=np.linspace(0,2*np.pi,257)
  for side,L,shape,angle,sgn in [('negative',1,.12,0,-1),('positive',a.right_period,.2,a.rotation,1)]:
   x,y,_,_=geometry(t,shape,angle)
   for j in range(3):w.writerows([side,j,float(tt),float(xx+sgn*(a.center_width/2+(j+.5)*L)),float(yy)] for tt,xx,yy in zip(t,x,y))
if __name__=='__main__':main()
