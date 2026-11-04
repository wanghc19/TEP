"""Compare floating Golub-Welsch rules with high-precision Legendre roots.
Input: MATLAB nodes/weights on [0,1]. Output: observed node/weight/moment errors.
"""
from pathlib import Path
import argparse,json,time
import numpy as np
from scipy.io import loadmat
from flint import arb,ctx
ctx.prec=512;p=argparse.ArgumentParser();p.add_argument('--experiment',required=True);a=p.parse_args();here=Path(a.experiment);d=loadmat(here/'output/run-016/science/gauss.mat');started=time.perf_counter();rows=[]
def legendre(n,t):
  p0=arb(1);p1=t
  for k in range(2,n+1):p0,p1=p1,((2*k-1)*t*p1-(k-1)*p0)/k
  return p1,n*(p0-t*p1)/(1-t*t)
for ii,n0 in enumerate(d['orders'].ravel()):
  n=int(n0);xx=d['X'][0,ii].ravel();ww=d['W'][0,ii].ravel();ex=ew=rw=0.;maxres=maxrad=0.;roots=[]
  for xf,wf in zip(xx,ww):
    t=2*arb(float(xf))-1
    for _ in range(5):v,dv=legendre(n,t);t=(t-v/dv).mid()
    _,dv=legendre(n,t);xr=(t+1)/2;wr=1/((1-t*t)*dv*dv);maxres=max(maxres,float(abs(legendre(n,t)[0]).upper()));maxrad=max(maxrad,float(xr.rad()),float(wr.rad()));ex=max(ex,float(abs(xr-arb(float(xf))).upper()));ew=max(ew,float(abs(wr-arb(float(wf))).upper()));rw=max(rw,float((abs(wr-arb(float(wf)))/wr).upper()));roots.append((xr,wr))
  moment=[]
  for k in [0,1,2,4,6,8,12,16]:
    if k>=2*n:continue
    val=sum((arb(float(w))*arb(float(x))**k for x,w in zip(xx,ww)),arb(0));moment.append(float(abs(val-arb(1)/(k+1)).upper()))
  rows.append({'order':n,'max_root_residual':maxres,'max_comparator_radius':maxrad,'max_node_absolute_error':ex,'max_weight_absolute_error':ew,'max_weight_relative_error':rw,'max_polynomial_moment_error_through_degree_16':max(moment),'minimum_one_minus_node':float(1-max(xx))})
result={'description':'observed high-precision comparisons, used as condition-calibrated rounding estimates','precision':512,'rules':rows,'seconds':time.perf_counter()-started};(here/'output/gauss-checks.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'seconds':result['seconds'],'rules':[r for r in rows if r['order'] in [10,16,24,40,77,104]]},indent=2))
