"""Pilot E3: rigorous inertia of a fixed exported Hermitian double matrix.
Input: real part, exact max-imaginary bound, negative vector and Cholesky data.
Output: Arb residual/inverse bounds, rational second-eigenvalue lower bound.
This verifies the exported matrix family, not the preceding core assembly.
"""
import argparse,json,time
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from flint import arb,arb_mat,fmpq,ctx
p=argparse.ArgumentParser();p.add_argument('--mat',required=True);p.add_argument('--output',required=True);a=p.parse_args();out=Path(a.output);out.mkdir(parents=True,exist_ok=True)
ctx.prec=128;ctx.threads=11;started=time.perf_counter();d=loadmat(a.mat);Tn=d['T_real'];Rn=d['R_factor'];vn=d['v_negative'].ravel();n=len(vn)
assert np.isfinite(Tn).all() and np.isfinite(Rn).all() and np.isfinite(vn).all();assert np.array_equal(Tn,Tn.T);assert (np.diag(Rn)>0).all() and (np.tril(Rn,-1)==0).all()
T=arb_mat(Tn.tolist());R=arb_mat(Rn.tolist());v=arb_mat(n,1,[float(x) for x in vn]);gamma=arb(fmpq(36537,100000));tau=arb(8);imag_max=arb(float(d['imag_max'][0,0]));delta=n*imag_max
print('pilot imported',n,'seconds',time.perf_counter()-started,flush=True)
t0=time.perf_counter();E=T+tau*(v*v.transpose())-R.transpose()*R
for i in range(n):E[i,i]=E[i,i]-gamma
product_seconds=time.perf_counter()-t0;print('residual matrix product seconds',product_seconds,flush=True)
# A Frobenius upper bound encloses the exact residual of the arbitrary factor.
sq=arb(0)
for i in range(n):
 row=arb(0)
 for j in range(n):
  z=E[i,j].abs_upper();row=row+z*z
 sq=sq+row
residual=sq.sqrt().upper();del E
print('residual bound',residual.str(15),flush=True)
# Comparison triangular solves bound both induced inverse norms without
# trusting a floating inverse or assuming diagonal dominance.
up=[arb(0) for _ in range(n)];down=[arb(0) for _ in range(n)];ra=np.abs(Rn)
for i in range(n-1,-1,-1):
 z=arb(1)
 for j in range(i+1,n):
  if ra[i,j]!=0:z=z+arb(float(ra[i,j]))*up[j]
 up[i]=z/arb(float(ra[i,i]))
for i in range(n):
 z=arb(1)
 for j in range(i):
  if ra[j,i]!=0:z=z+arb(float(ra[j,i]))*down[j]
 down[i]=z/arb(float(ra[i,i]))
ni=max(x.upper() for x in up);no=max(x.upper() for x in down);rho=(residual*ni*no).upper();positive_lower=1/(ni*no)-residual
rayleigh=(v.transpose()*T*v)[0,0];vnorm=(v.transpose()*v)[0,0];negative_upper=rayleigh+delta*vnorm
published=arb(fmpq(36536998,100000000));strict_tests={'residual_times_inverse_norms_lt_one':bool(rho<1),'positive_corrected_lower':bool(positive_lower>0),'negative_direction':bool(negative_upper<0),'published_gamma_below_full_bound':bool(gamma-delta>published)}
result={'target':'frozen exported Hermitian double L_cert, with its full imaginary part covered by a max-entry bound','dimension':n,'precision_bits':ctx.prec,'threads':ctx.threads,'gamma_shift_rational':'36537/100000','published_gamma_rational':'36536998/100000000',
 'residual_F_upper':residual.str(30),'inverse_inf_upper':ni.str(30),'inverse_one_upper':no.str(30),'residual_condition_upper':rho.str(30),'rank_one_corrected_positive_lower':positive_lower.str(30),'imaginary_operator_upper':delta.str(30),'second_eigenvalue_ball_lower_expression':(gamma-delta).str(30),'negative_Rayleigh_upper':negative_upper.str(30),'strict_tests':strict_tests,'negative_count':1 if all(strict_tests.values()) else None,'matrix_product_seconds':product_seconds,'seconds':time.perf_counter()-started,'preceding_assembly_certified':False}
(out/'pilot-certificate.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2),flush=True);assert all(strict_tests.values())
