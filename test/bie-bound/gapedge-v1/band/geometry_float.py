# Stage C source: test/bie-bound/example2-v1/band/geometry_float.py; local adaptations only.
"""Independent NumPy boundary trapezoid for B2 indicator matrices.
Input: radius, lobe, rotation, period. Output: Hermitian floating comparison B.
"""
import numpy as np

def indicator(R,a,angle,L,MN,J=2048):
 t=2*np.pi*np.arange(J)/J;r=R/np.sqrt(1+a*a/2)*(1+a*np.cos(3*t));dr=-3*R*a/np.sqrt(1+a*a/2)*np.sin(3*t)
 x=r*np.cos(t);y=r*np.sin(t);dx=dr*np.cos(t)-r*np.sin(t);dy=dr*np.sin(t)+r*np.cos(t)
 co=np.cos(angle);sn=np.sin(angle);x,y,dx,dy=co*x-sn*y,sn*x+co*y,co*dx-sn*dy,sn*dx+co*dy
 freq=np.arange(-12,13);coeff=np.empty((25,25),complex)
 for i,m in enumerate(freq):
  qx=2*np.pi*m/L;qy=2*np.pi*freq[:,None];q2=qx*qx+qy*qy;nz=q2[:,0]>0
  integrand=np.exp(1j*(qx*x+qy*y))*(qx*dy-qy*dx)
  val=np.sum(integrand,axis=1)*2*np.pi/J
  coeff[i,nz]=-1j*val[nz]/q2[nz,0]/L
  if m==0:coeff[i,12]=np.pi*R*R/L
 dm=MN[None,:,0]-MN[:,None,0];dn=MN[None,:,1]-MN[:,None,1];B=coeff[dm+12,dn+12]
 return (B+B.conj().T)/2
