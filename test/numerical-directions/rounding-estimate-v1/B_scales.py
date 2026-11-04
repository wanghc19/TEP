"""Measure absolute Fourier-moment and source-product scales for stage B.
Input: the original analytic trefoil and N=26,J=2560 formulas.
Output: small JSON of absolute quadrature envelopes and condition inputs.
"""
from pathlib import Path
import numpy as np,math,json,time
started=time.perf_counter();base=Path(__file__).resolve().parent;N=26;J=2560;u=2.**-53;gamma=lambda n:n*u/(1-n*u);out=[]
def rectangle_norm(c):
  s=np.pad(np.cumsum(np.cumsum(c,axis=0),axis=1),((1,0),(1,0)));w=2*N+1
  return float(np.max(s[w:,w:]-s[:-w,w:]-s[w:,:-w]+s[:-w,:-w]))
for a in [.12,.20]:
  t=np.arange(J)*2*np.pi/J;r=.2/np.sqrt(1+a*a/2)*(1+a*np.cos(3*t));dr=-.6*a/np.sqrt(1+a*a/2)*np.sin(3*t);x=.5+r*np.cos(t);y=r*np.sin(t);dx=(dr*np.cos(t)-r*np.sin(t))*2*np.pi/J;dy=(dr*np.sin(t)+r*np.cos(t))*2*np.pi/J;dm,dn=np.meshgrid(np.arange(-2*N,2*N+1),np.arange(-2*N,2*N+1),indexing='ij');uv=dm.ravel();vv=dn.ravel();coeff=np.zeros(len(uv),complex);ca=np.zeros(len(uv))
  for first in range(0,len(uv),128):
    ids=np.arange(first,min(first+128,len(uv)));m=uv[ids];n=vv[ids];phase=np.exp(2j*np.pi*(x[:,None]*m+y[:,None]*n));ix=m!=0;iy=(~ix)&(n!=0);iz=(~ix)&(~iy);val=np.zeros(len(ids),complex);ab=np.zeros(len(ids));val[ix]=np.sum(dy[:,None]*phase[:,ix],axis=0)/(2j*np.pi*m[ix]);ab[ix]=np.sum(abs(dy))/(2*np.pi*abs(m[ix]));val[iy]=-np.sum(dx[:,None]*phase[:,iy],axis=0)/(2j*np.pi*n[iy]);ab[iy]=np.sum(abs(dx))/(2*np.pi*abs(n[iy]));val[iz]=.04*np.pi;ab[iz]=.04*np.pi;coeff[ids]=val;ca[ids]=ab
  xabs=rectangle_norm(abs(coeff.reshape(dm.shape)));xquad=rectangle_norm(ca.reshape(dm.shape));deltaX=gamma(8*J+200)*xquad
  for lam in [1.7424,5.6169]:
    k=np.arange(-10,11);beta=.5+2*np.pi*k;q=np.sqrt(1+beta**2);kap=np.sqrt(np.where(k==0,1+beta**2,beta**2-lam));amp=np.sqrt(q)/(2*kap);S=np.column_stack([np.exp(-x[:,None]*kap),np.exp(-(1-x[:,None])*kap)]);rates=np.r_[-kap,kap];bb=np.r_[beta,beta];sx=rates[:,None]+rates[None,:];sy=bb[None,:]-bb[:,None];Ha=np.zeros((42,42));A=S.T@(abs(dy[:,None])*S);B=S.T@(abs(dx[:,None])*S);ix=abs(sx)>1e-12;iy=(~ix)&(abs(sy)>1e-12);Ha[ix]=A[ix]/abs(sx[ix]);Ha[iy]=B[iy]/abs(sy[iy]);zero=(~ix)&(~iy);sc0=np.r_[np.exp(-.5*kap),np.exp(-.5*kap)];Ha[zero]=.04*np.pi*(sc0[:,None]*sc0[None,:])[zero];deltaH=gamma(8*J+200)*Ha
    maxIT=maxTT=0.
    for theta in [0.,np.pi/2,np.pi]:
      plus=amp/(1-np.exp(-kap-1j*theta));minus=amp*np.exp(1j*theta)/(1-np.exp(-kap+1j*theta));Sc=np.vstack([np.diag(abs(plus)),np.diag(abs(minus))]);TTerr=Sc.T@deltaH@Sc;maxTT=max(maxTT,float(np.linalg.norm(TTerr,1)));num1=np.sum(abs(dy[:,None])*np.exp(-x[:,None]*kap),axis=0);num2=np.sum(abs(dy[:,None])*np.exp(-(1-x[:,None])*kap),axis=0);den=np.sqrt(kap[None,:]**2+(2*np.pi*np.arange(-N,N+1)[:,None]+theta)**2);it=gamma(8*J+200)*(num1*abs(plus)+num2*abs(minus))/den;maxIT=max(maxIT,float(np.linalg.norm(it,'fro')*math.sqrt(2*N+1)))
    denmin=np.sqrt(kap[None,:]**2+np.maximum(0,2*np.pi*abs(np.arange(-N,N+1))-np.pi)[:,None]**2);am=amp/(1-np.exp(-kap));it_global=gamma(8*J+200)*(num1*am+num2*am)/denmin;maxIT=float(np.linalg.norm(it_global,'fro')*math.sqrt(2*N+1));
    TF=math.sqrt(np.sum(amp**2/kap));out.append({'a':a,'lambda':lam,'N':N,'J':J,'X_abs_norm1':xabs,'X_quadrature_abs_norm1':xquad,'delta_X_estimate':deltaX,'delta_IT_F_estimate':maxIT,'delta_TT_norm1_estimate':maxTT,'T_L2_Frobenius':TF,'source_phase_samples':[0.,np.pi/2,np.pi],'moment_gamma_path':8*J+200})
result={'description':'rounding scale estimates; no reliable bounds','records':out,'seconds':time.perf_counter()-started};(base/'output/B-scales.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
