"""Plane-wave expansion of the first common stop band, on the full normal phase range.
Input: output folder. Output: beta-dependent edge estimates and Wood intersections.
The boundary integral for the Fourier coefficients follows example2-v1/bands.py.
"""
import csv,json,sys,time
from pathlib import Path
import numpy as np
from scipy.linalg import eigh
from scipy.optimize import brentq
from scipy.special import j1

def pencil(N,L,a,angle,w3):
  t=np.arange(512)*2*np.pi/512
  r=.2*(1+a*np.cos(3*t))/np.sqrt(1+a*a/2);rp=-.6*a*np.sin(3*t)/np.sqrt(1+a*a/2)
  z=r*np.exp(1j*(t+angle));dz=(rp+1j*r)*np.exp(1j*(t+angle))
  mn=np.array([(m,n) for m in range(-N,N+1) for n in range(-N,N+1)])
  coeff=np.empty((4*N+1,4*N+1),complex);ns=np.arange(-2*N,2*N+1)
  for i,m in enumerate(ns):
    x=2*np.pi*m/L;y=2*np.pi*ns[:,None];l2=(x*x+y*y)[:,0];nz=l2>0
    if w3:
      # Circular rods at (-L/4,-1/4) and (L/4,1/4).
      v=np.sqrt(l2[nz]);coeff[i,nz]=2*np.cos((x*L+y[nz,0])/4)*2*np.pi*.2*j1(.2*v)/(L*v)
    else:
      wave=np.exp(1j*(x*z.real+y*z.imag));v=np.mean(wave*(x*dz.imag-y*dz.real),axis=1)*2*np.pi
      coeff[i,nz]=-1j*v[nz]/(L*l2[nz])
    if m==0:coeff[i,2*N]=np.pi*.04*(2 if w3 else 1)/L
  delta=mn[None,:,:]-mn[:,None,:]
  B=coeff[delta[...,0]+2*N,delta[...,1]+2*N]
  mass=np.eye(len(mn))+(8 if w3 else 16)*(B+B.conj().T)/2
  j=1 if w3 else 0
  def edges(beta):
    values=[]
    for phase in np.linspace(-np.pi,np.pi,25):
      diagonal=((2*np.pi*mn[:,0]+phase)/L)**2+(beta+2*np.pi*mn[:,1])**2
      values.append(np.sqrt(np.maximum(0,eigh(np.diag(diagonal),mass,subset_by_index=[j,j+1],eigvals_only=True,check_finite=False))))
    values=np.array(values);return max(values[:,0]),min(values[:,1])
  return edges

def main(out):
  t=time.monotonic();rows=[];ranges=[]
  for N in (4,6):
    for model in ('ex1','ex2','w3'):
      w3=model=='w3'
      left=pencil(N,np.sqrt(3) if w3 else 1,0 if w3 else .12,0,w3)
      right=left if w3 else pencil(N,.85 if model=='ex2' else 1,.2,.13 if model=='ex2' else 0,False)
      def common(beta):
        a=left(beta);b=right(beta) if right!=left else a
        return max(a[0],b[0]),min(a[1],b[1])
      grid=np.linspace(0,np.pi,33);ab=np.array([common(b) for b in grid])
      rows.extend((model,N,b,*e) for b,e in zip(grid,ab))
      for m in (0,-1):
        wood=np.abs(grid+2*np.pi*m)
        crossings=[0.,np.pi]
        for i in (0,1):
          y=ab[:,i]-wood
          for k in range(len(grid)-1):
            if y[k]*y[k+1]<0:
              crossings.append(brentq(lambda b:common(b)[i]-abs(b+2*np.pi*m),grid[k],grid[k+1],xtol=1e-6))
        cuts=sorted(crossings);segments=[]
        for a,b in zip(cuts,cuts[1:]):
          v=(a+b)/2;lo,hi=common(v)
          if lo<abs(v+2*np.pi*m)<hi:segments.append([a,b])
        ranges.append(dict(model=model,N=N,m=m,beta_intervals=segments))
      print(model,N,ranges[-2:],flush=True)
      (out/'intersections.json').write_text(json.dumps(ranges,indent=2))
      with (out/'bands.csv').open('w') as f:
        w=csv.writer(f);w.writerow(['example','cutoff','beta','lower_k','upper_k']);w.writerows(rows)
  print('seconds',time.monotonic()-t,flush=True)
if __name__=='__main__': main(Path(sys.argv[1]))
