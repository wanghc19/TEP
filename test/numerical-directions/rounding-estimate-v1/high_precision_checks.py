"""Compare double eigenvalues and positive sums with high-precision evaluations.
Input: exported band/core matrices and optional positive element terms.
Output: observed differences, residuals, and summation-order comparisons.
"""
import argparse,json,time,math
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from scipy.linalg import eigh
from flint import arb,acb,acb_mat,arb_mat,ctx
p=argparse.ArgumentParser();p.add_argument('--root',required=True);p.add_argument('--output',required=True);a=p.parse_args();root=Path(a.root);ctx.prec=192;ctx.threads=11;t0=time.perf_counter();out={}
# High-precision inverse iteration on the exact stored double matrix.
b=loadmat(root/'output/run-003/science/panel.mat');Tn=b['panel_matrix'];n=len(Tn);T=acb_mat(Tn.tolist());x=acb_mat(b['panel_vector'].tolist());ld=float(b['panel_value'][0,0]);shift=acb(ld+1e-7);A=T-acb_mat(n,n,[shift if i==j else 0 for i in range(n) for j in range(n)])
for _ in range(4):
  x=A.solve(x);norm=(x.conjugate().transpose()*x)[0,0].real.sqrt();x=x*(1/acb(norm))
rq=(x.conjugate().transpose()*T*x)[0,0].real;res=T*x-x*acb(rq);resid=sum(z.real*z.real+z.imag*z.imag for z in res.entries()).sqrt();diff=abs(arb(ld)-rq)
out['A']={'dimension':n,'double_value':ld,'high_precision_value':rq.str(45),'observed_difference':float(diff.upper()),'residual':resid.str(15),'panel_info':b['panel_info'].ravel().tolist()}
d=loadmat(root/'output/run-002/science/core.mat');L=d['L_fixed'];V=d['eigenvectors'];ev=d['evL'].ravel();eps=float(d['epsilon'][0,0]);j=1;v=V[:,j];nn=len(v)
# A high-precision Rayleigh value is eigenvalue-accurate to O(residual^2/gap).
vb=acb_mat(nn,1,v.tolist());Lb=acb_mat(L.tolist());lv=Lb*vb;vn=(vb.conjugate().transpose()*vb)[0,0].real;rq=(vb.conjugate().transpose()*lv)[0,0].real/vn
res=lv-vb*acb(rq);resid=sum(z.real*z.real+z.imag*z.imag for z in res.entries()).sqrt()/vn.sqrt();target=float(ev[j]-eps);gap=float(min(ev[j]-ev[j-1],ev[j+1]-ev[j]));vec_effect=float(resid.upper())**2/gap
pilot_root=root.parent/'rounding-v1/probe';pilot_data=loadmat(pilot_root/'run-002/science/pilot.mat',variable_names=['T_real','imag_max']);pilot_json=json.loads((pilot_root/'run-003/science/pilot-certificate.json').read_text());pilot_equal=bool(np.array_equal(pilot_data['T_real'],np.real(L)));pilot_imag=bool(np.max(abs(np.imag(L)))<=float(pilot_data['imag_max'][0,0]));
out['D']={'pilot_real_matrix_bit_equal':pilot_equal,'imaginary_entries_within_pilot_max':pilot_imag,'pilot_recorded_negative_count':pilot_json['negative_count'],'dimension':nn,'double_center_value':float(ev[j]),'subtracted_epsilon':eps,'double_fixed_value':target,'high_precision_Rayleigh_value':rq.str(45),'observed_difference':float(abs(arb(target)-rq).upper()),'Rayleigh_residual':resid.str(20),'neighbor_gap_double':gap,'Rayleigh_vector_effect_estimate':vec_effect,'pilot_lower':.36536998,'pilot_consistent':bool(rq>arb('0.36536998'))}
del Lb,L,V
sums={}
for key in ['energy_terms','mass_terms','residual_terms','mass_correction_terms']:
  paths=sorted((root/'output/run-004/science').glob('*-terms.mat'))
  if not paths:break
  vec=np.concatenate([loadmat(p,variable_names=[key])[key].ravel() for p in paths]);fixed=sum((arb(float(z)) for z in vec),arb(0));ascending=np.sort(vec);descending=ascending[::-1]
  forward=0.;reverse=0.
  for z in vec:forward=forward+float(z)
  for z in vec[::-1]:reverse=reverse+float(z)
  values={'numpy':float(np.sum(vec)),'ascending':float(np.sum(ascending)),'descending':float(np.sum(descending)),'python_sequential':forward,'reverse_sequential':reverse,'fsum':math.fsum(float(z) for z in vec)}
  sums[key]={'count':len(vec),'positive':bool((vec>=0).all()),'absolute_sum':float(np.sum(abs(vec))),'high_precision_sum':fixed.str(45),'values':values,'observed_errors':{k:float(abs(arb(v)-fixed).upper()) for k,v in values.items()}}
out['sums']=sums;out['seconds']=time.perf_counter()-t0;Path(a.output).write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
