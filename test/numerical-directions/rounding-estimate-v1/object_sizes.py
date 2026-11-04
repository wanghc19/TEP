"""Measure stored-object discrepancies and estimate local field changes.
Input: MATLAB scalar samples, nodal fields and coefficient caches.
Output: observed discrepancies and centroid-geometry perturbation estimates.
"""
from pathlib import Path
import argparse,json,time,math
import numpy as np
from scipy.io import loadmat
from scipy.spatial import cKDTree
from flint import arb,acb,arb_mat,acb_mat,fmpq,ctx
ctx.prec=192;ctx.threads=11;p=argparse.ArgumentParser();p.add_argument('--experiment',required=True);p.add_argument('--field-run',default='run-010');a=p.parse_args();base=Path(a.experiment);start=time.perf_counter();d=loadmat(base/'output/run-007/science/scalars.mat');phase=complex(d['phase'][0,0]);phaseerr=float(abs(acb(phase)-acb(0,arb(1)/2).exp()).upper());moderr=float(abs(arb(phase.real)**2+arb(phase.imag)**2-1).upper());curve=np.zeros(3);truecurves=[[],[],[]];kap=0.;betaerr=0.
for j,k in enumerate(range(-16,17)):
  beta=arb(1)/2+2*arb.pi()*k;kap=max(kap,float(abs((1+beta**2).sqrt()-arb(float(d['kappa'][j,0]))).upper()));betaerr=max(betaerr,float(abs(beta-arb(float(d['beta'][j,0]))).upper()))
for i,vals in enumerate(d['curves']):
  t=arb.pi()*arb(fmpq(i,320));ct=t.cos();st=t.sin();c5=(5*t).cos()
  for j in range(3):
    if j==1:x=arb(fmpq(1,5))*(arb(fmpq(3,2))+arb(fmpq(3,10))*c5)*ct;y=arb(fmpq(1,5))*(1+arb(fmpq(3,10))*c5)*st
    else:
      aa=arb(fmpq(3,25)) if j==0 else arb(fmpq(1,5));r=arb(fmpq(1,5))/(1+aa*aa/2).sqrt()*(1+aa*(3*t).cos());x=r*ct;y=r*st
    truecurves[j].append(acb(x,y));curve[j]=max(curve[j],float(abs(acb(x,y)-acb(complex(vals[2*j],vals[2*j+1]))).upper()))
models=[];degrees=[(dd-j,j) for dd in range(4) for j in range(dd+1)]
def integ(a,b):return math.factorial(a)*math.factorial(b)/math.factorial(a+b+2)
Q0=np.array([[integ(ai+aj,bi+bj) for aj,bj in degrees] for ai,bi in degrees]);Qx=np.zeros((10,10));Qy=Qx.copy();Qxy=Qx.copy()
for i,(ai,bi) in enumerate(degrees):
  for j,(aj,bj) in enumerate(degrees):
    if ai*aj:Qx[i,j]=ai*aj*integ(ai+aj-2,bi+bj)
    if bi*bj:Qy[i,j]=bi*bj*integ(ai+aj,bi+bj-2)
    if ai*bj:Qxy[i,j]=ai*bj*integ(ai+aj-1,bi+bj-1)
for name in ['left','center','right']:
  z=loadmat(base/'output'/a.field_run/'science'/(name+'-field.mat'));C=z['coefficients'];C=C[:,:,None] if C.ndim==2 else C;nt,nm,nc=C.shape;nodal=z['U'][z['dofs'].astype(int)-1,:];alpha=z['alpha'];V=arb_mat([[arb(fmpq(int(row[1]),3))**aa*arb(fmpq(int(row[2]),3))**bb for aa,bb in degrees] for row in alpha]);Vi=V.inv();cond=np.linalg.cond(np.array([[float(V[i,j]) for j in range(10)] for i in range(10)]),np.inf)
  cr=C.transpose(0,2,1).reshape(-1,10);nr=nodal.transpose(0,2,1).reshape(-1,10);delta=np.zeros(cr.shape,complex);maxnodal=0.
  for first in range(0,len(cr),512):
    c=acb_mat(cr[first:first+512].tolist());v=acb_mat(nr[first:first+512].tolist());diff=v*acb_mat(Vi.transpose())-c
    rr=v-c*acb_mat(V.transpose());maxnodal=max(maxnodal,max(float(abs(x).upper()) for x in rr.entries()));delta[first:first+len(diff.table())]=np.array([[complex(x) for x in row] for row in diff.table()]);
  mx=z['mx'];my=z['my'];reference=[(0,0),(1,0),(0,1),(.5,0),(.5,.5),(0,.5)];powers=np.array([[1,x,y,x*x,x*y,y*y] for x,y in reference]);points=np.stack([mx@powers.T,my@powers.T],axis=2).reshape(-1,2);tree=cKDTree(points);mesh_curve_error=0.;matches=0
  for target in truecurves[['left','center','right'].index(name)]:
    ids=tree.query_ball_point([float(target.real.mid()),float(target.imag.mid())],1e-11);assert ids,'Missing analytic interface node';matches+=len(ids)
    for point_id in ids:
      ee,loc=divmod(point_id,6);xx=sum((arb(float(mx[ee,k]))*arb(float(powers[loc,k])) for k in range(6)),arb(0));yy=sum((arb(float(my[ee,k]))*arb(float(powers[loc,k])) for k in range(6)),arb(0));mesh_curve_error=max(mesh_curve_error,float(abs(acb(xx,yy)-target).upper()))
  aa=mx[:,1]+2*mx[:,3]/3+mx[:,4]/3;bb=mx[:,2]+mx[:,4]/3+2*mx[:,5]/3;cc=my[:,1]+2*my[:,3]/3+my[:,4]/3;dd=my[:,2]+my[:,4]/3+2*my[:,5]/3;det=aa*dd-bb*cc;cells=z['cells'].ravel();rho=z['rho'].ravel();ec=mc=0.;crossE=crossM=0.
  quad=lambda c,Q:np.real(np.einsum('bi,ij,bj->b',c.conj(),Q,c))
  for j in range(nc):
    dc=delta.reshape(nt,nc,10)[:,j,:];old=C[:,:,j];ex=quad(dc,Qx);ey=quad(dc,Qy);xy=quad(dc,Qxy);mass=det*quad(dc,Q0);eg=((dd*dd+bb*bb)*ex+(cc*cc+aa*aa)*ey-2*(dd*cc+aa*bb)*xy)/det
    if abs(cells[j])>=12:eg=2*eg+2*(math.pi/4)**2*mass
    ec+=float(np.sum(eg));mc+=float(np.sum(rho*mass))
  models.append({'template':name,'triangles':nt,'cells':nc,'V_cond_inf':float(cond),'actual_geometry_node_error':mesh_curve_error,'matched_curve_nodes':640,'matched_element_node_images':matches,'exact_nodal_reconstruction_error':maxnodal,'max_coefficient_change':float(np.max(abs(delta))),'centroid_gradient_change_squared':ec,'centroid_mass_change_squared':mc})
result={'description':'measured object discrepancies; physical effects use centroid geometry and are estimates','precision':192,'phase_error':phaseerr,'phase_modulus_squared_error':moderr,'max_beta_error':betaerr,'max_kappa_error':kap,'curve_error_by_template':curve.tolist(),'field_conversion':models,'gradient_change_squared':sum(x['centroid_gradient_change_squared'] for x in models),'mass_change_squared':sum(x['centroid_mass_change_squared'] for x in models),'seconds':time.perf_counter()-start}
(base/'output/object-sizes.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
