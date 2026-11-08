"""Fit Wood-threshold measurements and Chebyshev coefficients.
Input: explicit sampling, Chebyshev and result directories.
Output: JSON (JavaScript Object Notation), CSV (comma-separated values) tables.
"""
import argparse
import csv
import json
import math
from pathlib import Path
import numpy as np
from scipy.fft import dct

def read(path):
  return json.loads(path.read_text())

def cx(v):
  return np.asarray(v['real'])+1j*np.asarray(v['imag'])

def write(path,rows):
  if not rows:
    return
  keys=list(dict.fromkeys(k for r in rows for k in r))
  with path.open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows(rows)

def powerfit(t,v):
  x=np.log(np.abs(t));y=np.log(np.maximum(v,np.finfo(float).tiny))
  slope,intercept=np.linalg.lstsq(np.column_stack([x,np.ones_like(x)]),y,rcond=None)[0]
  residual=y-intercept-slope*x
  return dict(exponent=float(slope),rms_log=float(np.linalg.norm(residual)/math.sqrt(len(x))),
    t_min=float(np.min(np.abs(t))),t_max=float(np.max(np.abs(t))),points=len(x))

def extrapolate(t,values,kind):
  if kind=='S':
    mask=np.abs(t)<=1.00001e-4;z=t
    # The caller replaces z with the exact channel value for its beta.
    degree=3
  else:
    mask=(np.abs(t)<=1.00001e-3)&(np.abs(t)>=.99999e-5);z=t;degree=2
  return mask,z,degree

def main():
  p=argparse.ArgumentParser()
  p.add_argument('--samples',type=Path,required=True)
  p.add_argument('--chebyshev',type=Path)
  p.add_argument('--controls',type=Path)
  p.add_argument('--output',type=Path,required=True)
  a=p.parse_args();a.output.mkdir(exist_ok=True,parents=True)
  raw=read(a.samples/'samples.json');lookup={(r['beta'],r['t'],r['N'],r['M']):r for r in raw}
  fits=[];latefits=[];curves=[];conditions=[];polynomials=[];limits=[];limitchecks=[]
  labelsS=['RL00','TLR00','RL01','TLR01','RL10','TLR10','RL11','TLR11','RL12','TLR12']
  labelsD=['DLL00','DLR00','DLL01','DLR01','DLL10','DLR10','DLL11','DLR11','DLL12','DLR12']
  for beta in [1.95,1.98154]:
    for N,M in [(128,6),(192,12),(192,6)]:
      rr=sorted([r for r in raw if (r['beta'],r['N'],r['M'])==(beta,N,M)],key=lambda r:r['t'])
      t=np.asarray([r['t'] for r in rr]);gamma=np.asarray([cx(r['gamma0']).item() for r in rr])
      for cell in ['lead','center']:
        for kind in ['S','D']:
          selected=np.stack([cx(r[cell]['selected_'+kind]) for r in rr])
          matrices=np.stack([cx(r[cell][kind+'_common']) for r in rr])
          mask,z,degree=extrapolate(t,selected,kind)
          if kind=='S':z=gamma
          scale=np.max(np.abs(z[mask]));design=np.column_stack([(z[mask]/scale)**j for j in range(degree+1)])
          select_coeff=np.linalg.lstsq(design,selected[mask],rcond=None)[0]
          matrix_coeff=np.linalg.lstsq(design,matrices[mask].reshape(sum(mask),-1),rcond=None)[0]
          ref=select_coeff[0];matrixref=matrix_coeff[0].reshape(matrices.shape[1:])
          if kind=='S':
            side_limits=[]
            for sign in [-1,1]:
              side=mask&(t*sign>0);V=np.column_stack([(z[side]/scale)**j for j in range(4)])
              side_limits.append(np.linalg.lstsq(V,selected[side],rcond=None)[0][0])
            limitchecks.append(dict(beta=beta,N=N,M=M,cell=cell,
              maximum_side_limit_difference=float(max(abs(side_limits[0]-side_limits[1]))),
              maximum_joint_to_side_difference=float(max(np.max(abs(v-ref)) for v in side_limits))))
          limits.append(dict(beta=beta,N=N,M=M,cell=cell,kind=kind,limit_real=ref.real.tolist(),limit_imag=ref.imag.tolist(),
            reference_t=[float(x) for x in t[mask]],reference_degree=degree,reference_variable='gamma' if kind=='S' else 't'))
          error=np.abs(selected-ref);matrix_error=np.linalg.norm(matrices-matrixref,axis=(1,2))
          for j,r in enumerate(rr):
            coarse=lookup[(beta,r['t'],128,6)]
            other=lookup[(beta,r['t'],192,12)]
            control=lookup[(beta,r['t'],192,6)]
            delta=np.abs(cx(other[cell]['selected_'+kind])-cx(coarse[cell]['selected_'+kind]))
            delta_density=np.abs(cx(control[cell]['selected_'+kind])-cx(coarse[cell]['selected_'+kind]))
            diffmatrix=np.linalg.norm(cx(other[cell][kind+'_common'])-cx(coarse[cell][kind+'_common']))
            densitymatrix=np.linalg.norm(cx(control[cell][kind+'_common'])-cx(coarse[cell][kind+'_common']))
            curves.append(dict(beta=beta,N=N,M=M,cell=cell,kind=kind,entry='common_matrix_Frobenius',t=r['t'],
              distance_to_limit=matrix_error[j],grid_difference=diffmatrix,density_difference=densitymatrix))
            labels=labelsS if kind=='S' else labelsD
            for entry,label in enumerate(labels):
              curves.append(dict(beta=beta,N=N,M=M,cell=cell,kind=kind,entry=label,t=r['t'],
                distance_to_limit=error[j,entry],grid_difference=delta[entry],density_difference=delta_density[entry]))
          for sign in [-1,1]:
            use=(t*sign>0)&(np.abs(t)<=1.00001e-3)&(np.abs(t)>=.99999e-6)
            for entry,label in enumerate(labelsS if kind=='S' else labelsD):
              f=powerfit(t[use],error[use,entry])
              cc=[v for v in curves if (v['beta'],v['N'],v['M'],v['cell'],v['kind'],v['entry'])==(beta,N,M,cell,kind,label) and v['t']*sign>0 and .99999e-6<=abs(v['t'])<=1.00001e-3]
              f.update(beta=beta,N=N,M=M,cell=cell,kind=kind,entry=label,side=sign,
                maximum_grid_difference=max(v['grid_difference'] for v in cc),maximum_density_difference=max(v['density_difference'] for v in cc),
                minimum_signal_to_grid=min(v['distance_to_limit']/max(v['grid_difference'],1e-300) for v in cc))
              fits.append(f)
            f=powerfit(t[use],matrix_error[use]);f.update(beta=beta,N=N,M=M,cell=cell,kind=kind,entry='common_matrix_Frobenius',side=sign)
            dd=[];dc=[];rat=[]
            for i in np.flatnonzero(use):
              coarse=lookup[(beta,rr[i]['t'],128,6)];other=lookup[(beta,rr[i]['t'],192,12)];control=lookup[(beta,rr[i]['t'],192,6)]
              diff=np.linalg.norm(cx(other[cell][kind+'_common'])-cx(coarse[cell][kind+'_common']))
              den=np.linalg.norm(cx(control[cell][kind+'_common'])-cx(coarse[cell][kind+'_common']))
              dd.append(diff);dc.append(den);rat.append(matrix_error[i]/max(diff,1e-300))
            f.update(maximum_grid_difference=max(dd),maximum_density_difference=max(dc),minimum_signal_to_grid=min(rat));fits.append(f)
          if kind=='S':
            for sign in [-1,1]:
              use=(t*sign>0)&(np.abs(t)<=1.00001e-4)&(np.abs(t)>=.99999e-7)
              for entry,label in enumerate(labelsS):
                f=powerfit(t[use],error[use,entry])
                cc=[v for v in curves if (v['beta'],v['N'],v['M'],v['cell'],v['kind'],v['entry'])==(beta,N,M,cell,kind,label) and v['t']*sign>0 and .99999e-7<=abs(v['t'])<=1.00001e-4]
                f.update(beta=beta,N=N,M=M,cell=cell,kind=kind,entry=label,side=sign,
                  maximum_grid_difference=max(v['grid_difference'] for v in cc),maximum_density_difference=max(v['density_difference'] for v in cc),
                  minimum_signal_to_grid=min(v['distance_to_limit']/max(v['grid_difference'],1e-300) for v in cc))
                latefits.append(f)
          polyuse=np.abs(t)<=1.00001e-2;xx=t[polyuse]/.01;Y=matrices[polyuse].reshape(sum(polyuse),-1)
          for deg in [1,2,4,6]:
            V=np.polynomial.chebyshev.chebvander(xx,deg);coef=np.linalg.lstsq(V,Y,rcond=None)[0]
            residual=np.linalg.norm((Y-V@coef).reshape((-1,*matrices.shape[1:])),axis=(1,2))
            polynomials.append(dict(beta=beta,N=N,M=M,cell=cell,kind=kind,degree=deg,
              t_min=-.01,t_max=.01,maximum_absolute_residual=float(max(residual)),
              maximum_relative_residual=float(max(residual)/np.max(np.linalg.norm(Y,axis=1)))))
        for sign in [-1,1]:
          use=(t*sign>0)&(np.abs(t)<=1.00001e-3)
          for key in ['rcond','singular_ratio','A_norm','A_sigma_min','proxy_norm','extract_norm','trace_rcond']:
            f=powerfit(t[use],np.asarray([r[cell][key] for r in rr])[use]);f.update(beta=beta,N=N,M=M,cell=cell,quantity=key,side=sign)
            deltas=[];densities=[]
            for i in np.flatnonzero(use):
              coarse=lookup[(beta,rr[i]['t'],128,6)][cell][key]
              high=lookup[(beta,rr[i]['t'],192,12)][cell][key]
              control=lookup[(beta,rr[i]['t'],192,6)][cell][key]
              deltas.append(abs(high-coarse));densities.append(abs(control-coarse))
            f.update(maximum_grid_difference=max(deltas),maximum_density_difference=max(densities))
            conditions.append(f)
  scalar=[];greenfits=[]
  def kernel_error(r):
    return abs(cx(r['Green_total']).item()-cx(r['Green0']).item()-kernel_regular(r,60))
  def kernel_regular(r,order):
    m=np.r_[np.arange(-order,0),np.arange(1,order+1)]
    b=r['beta']+2*np.pi*m;g=np.sqrt((r['k']**2-b*b).astype(complex))
    return np.sum(1j/(2*g)*np.exp(-1j*b*.17+1j*g*.4))
  for r in raw:
    row={k:r[k] for k in ['N','M','beta','t','k','common_gap','seconds']}
    row.update(gamma_abs=abs(cx(r['gamma0']).item()),Green0_abs=abs(cx(r['Green0']).item()),
      Green_total_abs=abs(cx(r['Green_total']).item()),Green_remainder_abs=abs(cx(r['Green_total']).item()-cx(r['Green0']).item()))
    row['Green_spectral_error']=kernel_error(r)
    row['Green_spectral_change_60_80']=abs(kernel_regular(r,60)-kernel_regular(r,80))
    for c in ['lead','center']:
      row.update({c+'_'+k:r[c][k] for k in ['rcond','singular_ratio','A_norm','A_sigma_min','trace_rcond','D_norm','roundtrip_relative','D_hermitian_relative','proxy_norm','extract_norm']})
      if 'grid_difference' in r:
        row.update({c+'_grid_'+k:v for k,v in r['grid_difference'][c].items()})
    scalar.append(row)
  assert max(r['Green_spectral_error']/r['Green0_abs'] for r in scalar)<1e-4, 'Check source-to-target phase consistency'
  for beta in [1.95,1.98154]:
    for N,M in [(128,6),(192,12),(192,6)]:
      for sign in [-1,1]:
        rr=[r for r in scalar if (r['beta'],r['N'],r['M'])==(beta,N,M) and r['t']*sign>0 and abs(r['t'])<=1.00001e-3]
        for key in ['Green0_abs','Green_total_abs','Green_spectral_error']:
          f=powerfit([r['t'] for r in rr],[r[key] for r in rr]);f.update(beta=beta,N=N,M=M,side=sign,quantity=key)
          differences=[]
          for r in rr:
            high=next(q for q in scalar if (q['beta'],q['t'],q['N'],q['M'])==(beta,r['t'],192,12))
            coarse=next(q for q in scalar if (q['beta'],q['t'],q['N'],q['M'])==(beta,r['t'],128,6))
            differences.append(abs(high[key]-coarse[key]))
          f['maximum_grid_difference']=max(differences);greenfits.append(f)
  write(a.output/'samples.csv',scalar);write(a.output/'exponents.csv',fits);write(a.output/'point-errors.csv',curves)
  write(a.output/'late-exponents.csv',latefits);write(a.output/'condition-exponents.csv',conditions);write(a.output/'joint-polynomials.csv',polynomials)
  write(a.output/'green-exponents.csv',greenfits)
  (a.output/'limits.json').write_text(json.dumps(limits,indent=2));write(a.output/'limit-checks.csv',limitchecks)
  cheb=[];cheb_summary=[];squared_summary=[]
  if a.chebyshev:
    data=read(a.chebyshev/'chebyshev.json')
    for N in [128,192]:
      rr=sorted([r for r in data if r['N']==N],key=lambda r:r['node']);degree=rr[0]['degree']
      for route,name in enumerate(['original_amplitude','condensed_amplitude','condensed_cauchy']):
        vv=[r['values'][route] for r in rr];logs=np.asarray([v['logabs'] for v in vv]);phase=np.asarray([v['phase'] for v in vv])
        determinant=np.exp(logs-max(logs)+1j*phase)
        for quantity,values in [('determinant',determinant),('sigma_min',np.asarray([v['sigma_min'] for v in vv]))]:
          coef=dct(values,type=1)/degree;coef[[0,-1]]/=2;relative=np.abs(coef)/max(np.abs(coef))
          for j,value in enumerate(relative):cheb.append(dict(N=N,route=name,quantity=quantity,order=j,relative_coefficient=float(value)))
          env=[float(max(relative[j:j+8])) for j in range(1,degree,8)]
          use=np.arange(8,49) if quantity=='determinant' else np.arange(8,33,2)
          if name=='condensed_cauchy' and quantity=='determinant':use=np.arange(1,6)
          fit=powerfit(use,relative[use]);fit['coefficient_orders']=use.tolist()
          fit['order_min']=fit.pop('t_min');fit['order_max']=fit.pop('t_max')
          linear=np.polyfit(use,np.log(relative[use]),1)
          geometric_rms=float(np.linalg.norm(np.log(relative[use])-np.polyval(linear,use))/math.sqrt(len(use)))
          cheb_summary.append(dict(N=N,route=name,quantity=quantity,log_modulus_range=float(max(logs)-min(logs)),
            coefficient_8=float(relative[8]),coefficient_16=float(relative[16]),coefficient_32=float(relative[32]),
            coefficient_48=float(relative[48]),tail_8=float(max(relative[-8:])),eight_order_envelopes=env,
            algebraic_fit=fit if name!='condensed_cauchy' or quantity!='determinant' else None,
            geometric_log_rms=geometric_rms,geometric_per_order=float(np.exp(linear[0])),fit_orders=use.tolist()))
        if name=='condensed_cauchy':
          values=np.asarray([v['sigma_min'] for v in vv])**2
          coef=dct(values,type=1)/degree;coef[[0,-1]]/=2;relative=np.abs(coef)/max(np.abs(coef))
          for j,value in enumerate(relative):cheb.append(dict(N=N,route=name,quantity='sigma_min_squared',order=j,relative_coefficient=float(value)))
          squared_summary.append(dict(N=N,coefficient_8=float(relative[8]),coefficient_16=float(relative[16]),
            coefficient_32=float(relative[32]),tail_8=float(max(relative[-8:]))))
    write(a.output/'chebyshev-coefficients.csv',cheb)
  control_rows=[];cauchyroot=None
  if a.controls:
    for r in read(a.controls/'controls.json'):
      base=lookup[(r['beta'],r['t'],128,6)]
      v=dict(beta=r['beta'],t=r['t'],backend='direct' if r['backend']['direct'] else 'FMM-1e-14',
        Green_spectral_error=kernel_error(r),Green_difference_from_base=abs(cx(r['Green_total']).item()-cx(base['Green_total']).item()))
      for cell in ['lead','center']:
        for kind in ['S','D']:
          v[cell+'_'+kind+'_difference_from_base']=float(np.linalg.norm(cx(r[cell][kind+'_common'])-cx(base[cell][kind+'_common'])))
        v[cell+'_D_hermitian_relative']=r[cell]['D_hermitian_relative']
      control_rows.append(v)
    write(a.output/'backend-controls.csv',control_rows)
    cauchyroot=read(a.controls/'cauchy-root.json')
  summary=dict(root_fits=fits,late_fits=latefits,condition_fits=conditions,green_fits=greenfits,chebyshev=cheb_summary,cauchy_sigma_squared=squared_summary,backend_controls=control_rows,cauchy_root=cauchyroot,
    sample_count=len(raw),all_common_gap=all(r['common_gap'] for r in raw),
    maximum_roundtrip=max(r[c]['roundtrip_relative'] for r in raw for c in ['lead','center']),
    maximum_roundtrip_at_point_one=max(r[c]['roundtrip_relative'] for r in raw if abs(r['t'])==.1 for c in ['lead','center']))
  (a.output/'summary.json').write_text(json.dumps(summary,indent=2))
  print(json.dumps({k:v for k,v in summary.items() if k not in ['root_fits','late_fits','condition_fits','green_fits','chebyshev','backend_controls']},indent=2))

if __name__=='__main__':
  main()
