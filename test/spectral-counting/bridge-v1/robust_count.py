#!/usr/bin/env python3
"""Rebuild the full count certificate for a certified geometry neighbourhood.

Every inclusion may change by symmetric-difference area <= 1e-10, with
unchanged cell placement and material values. Source binary64 literals and
an explicit coefficient neighbourhood are enclosed using swept-area bounds.
The run uses mathematical constants only; no saved result JSON is consumed.
Both endpoint bands have radius 1e-12. Baseline source files are unchanged.
"""

import argparse
from pathlib import Path
import json

from flint import acb, arb, ctx
from gap_fourier import check_budget, configure_budget, interval, write_json
from half_gap import polar_moments, mass_matrix
from audit_box import fourier_geometry, laurent_moments
from box_count import mass_balls, finite_check


def literal(text):
  n,d=float(text).as_integer_ratio()
  return arb(n)/d, {'text':text,'numerator':str(n),'denominator':str(d),'hex':float(text).hex()}


def binary_geometry(name):
  rb,_=literal('0.2')
  if name=='center':
    cb,_=literal('0.3');v=rb*cb/2
    return {1:3*rb/2,4:v,6:v},{1:rb,4:-v,6:v}
  alpha,_=literal('0.12' if name=='left' else '0.20')
  u=rb/(1+alpha*alpha/2).sqrt();v=u*alpha/2
  return {1:u,2:v,4:v},{1:u,2:-v,4:v}


def model_enclosure(area_error,mu_error):
  entries={s:literal(s)[1] for s in ['0.12','0.20','0.2','0.3','0.5','1.5','2.40','2.46']}
  coefficients={};tol=arb('1e-13')
  for name in ['left','right','center']:
    aa,bb=fourier_geometry(name);ab,bbin=binary_geometry(name)
    differences=[(k,(ab[k]-v).abs_upper()) for k,v in aa.items()]
    differences += [(k,(bbin[k]-v).abs_upper()) for k,v in bb.items()]
    d0=sum(v for _,v in differences).upper();d1=sum(k*v for k,v in differences).upper()
    v=sum(k*abs(z) for k,z in aa.items())+sum(k*abs(z) for k,z in bb.items())
    r=sum(abs(z) for z in aa.values())+sum(abs(z) for z in bb.values())
    if name=='center':m=arb(93)/5000
    else:
      alpha=arb('0.12' if name=='left' else '0.20')
      r0=1/(5*(1+alpha*alpha/2).sqrt());m=(r0*(1-alpha))**2
    literal_area=(2*arb.pi()*d0*(v+d1)).upper()
    dn0=(d0+len(differences)*tol).upper()
    dn1=(d1+sum(k for k,_ in differences)*tol).upper()
    orientation=(m-dn0*v-r*dn1-dn0*dn1).lower()
    neighbourhood_area=(2*arb.pi()*dn0*(v+dn1)).upper()
    inside=(sum(abs(z) for z in ab.values())+len(ab)*tol<arb(1)/2
      and sum(abs(z) for z in bbin.values())+len(bbin)*tol<arb(1)/2)
    passed=bool(orientation>0 and neighbourhood_area<area_error and inside)
    if not passed:raise RuntimeError('Binary geometry was not enclosed.')
    coefficients[name]={'pass':passed,'literal_position_difference_upper':interval(d0),
      'literal_velocity_difference_upper':interval(d1),
      'literal_symmetric_difference_area_upper':interval(literal_area),
      'coefficient_neighbourhood_radius':'1e-13',
      'neighbourhood_symmetric_difference_area_upper':interval(neighbourhood_area),
      'orientation_lower':interval(orientation),'inside_original_cell':bool(inside),
      'binary_x_coefficients':{str(k):interval(z) for k,z in ab.items()},
      'binary_y_coefficients':{str(k):interval(z) for k,z in bbin.items()}}
  endpoints={}
  for s in ['2.40','2.46']:
    value,_=literal(s);difference=(value-arb(s)).abs_upper()
    if not difference<mu_error:raise RuntimeError('Binary endpoint is outside the band.')
    endpoints[s]={'binary_value':interval(value),'difference_upper':interval(difference),'covered':True}
  return {'literals':entries,'geometry':coefficients,'endpoints':endpoints,
    'interpretation':'Exact analytic interpretation of source binary64 literals; not a bitwise MATLAB execution or mesh certificate.'}


def inflate_mass(matrix,indices,width,total_contrast,area_error):
  for i,(n,_) in enumerate(indices):
    ci=arb(1) if n==0 else arb(2).sqrt()
    for j,(ell,_) in enumerate(indices):
      cj=arb(1) if ell==0 else arb(2).sqrt()
      error=(ci*cj*total_contrast*area_error/width).upper()
      matrix[i,j]+=acb(arb(0,error),arb(0,error))
  return matrix


def certify_leads(area_error):
  nx,my=4,2;indices=[(n,m) for n in range(nx+1) for m in range(-my,my+1)]
  a0,b0=arb('2.30'),arb('2.60')
  tau=min(((arb.pi()*(nx+1))**2+arb(1)/4).lower(),
    ((2*arb.pi()*(my+1)-arb(1)/2)**2).lower())
  h=(tau-17*b0).lower();delta=(64*b0*b0/h).upper();rows=[]
  for side,alpha in [('left','0.12'),('right','0.20')]:
    moments,error=polar_moments(alpha,nx,my,64)
    denominator=1+16*(arb.pi()/25+moments[2,0].real)+arb(0,(32*area_error).upper())
    trial=((arb.pi()**2+arb(1)/4)/denominator).upper()
    mass=inflate_mass(mass_matrix(moments,indices),indices,1,16,area_error)
    matrix=-b0*mass
    for i,(n,m) in enumerate(indices):matrix[i,i]+=(arb.pi()*n)**2+(2*arb.pi()*m+arb(1)/2)**2-delta
    signs=finite_check(matrix)
    passed=bool(h>0 and denominator>0 and trial<a0 and signs['pass'] and signs['congruence']['negative']==1)
    rows.append({'side':side,'pass':passed,'dirichlet_trial_upper':interval(trial),
      'inertia':signs,'moment_remainder_upper':interval(error)})
    print(json.dumps({'stage':'robust_lead','side':side,'pass':passed}),flush=True)
  return {'barriers':['2.30','2.60'],'nx':nx,'my':my,'tail_kinetic_lower':interval(tau),
    'tail_positive_lower':interval(h),'schur_correction_upper':interval(delta),'rows':rows,
    'pass':all(r['pass'] for r in rows)}


def certify_box(area_error,mu_error):
  length,nx,my=3,32,3;width=7;moments={};errors={}
  for name in ['left','right','center']:
    moments[name],error=laurent_moments(name,width,nx,my,96);errors[name]=interval(error)
    print(json.dumps({'stage':'fresh_laurent_geometry','shape':name,'count':len(moments[name])}),flush=True)
  tau=min(((arb.pi()*(nx+1)/width)**2+arb(1)/4).lower(),
    ((2*arb.pi()*(my+1)-arb(1)/2)**2).lower())
  rows=[]
  for bc in ['D','N']:
    mass,indices=mass_balls(moments,length,nx,my,bc,1)
    mass=inflate_mass(mass,indices,width,6*16+3,area_error)
    mass2,_=mass_balls(moments,length,nx,my,bc,2)
    mass2=inflate_mass(mass2,indices,width,6*288+15,area_error)
    covariance=mass2-mass*mass
    for target in ['2.40','2.46']:
      check_budget();value=arb(target)+arb(0,mu_error.upper())
      h=(tau-17*value).lower();factor=(value*value/h).upper()
      upper=-value*mass
      for i,(n,m) in enumerate(indices):upper[i,i]+=(arb.pi()*n/width)**2+(2*arb.pi()*m+arb(1)/2)**2
      lower=upper-factor*covariance
      uc,lc=finite_check(upper),finite_check(lower)
      passed=bool(h>0 and uc['pass'] and lc['pass'] and uc['congruence']['negative']==lc['congruence']['negative'])
      rows.append({'boundary':bc,'endpoint':target,'endpoint_band':interval(value),'dimension':len(indices),
        'pass':passed,'negative':uc['congruence']['negative'] if passed else None,
        'tail_positive_lower':interval(h),'covariance_factor_upper':interval(factor),'upper':uc,'lower':lc})
      print(json.dumps({'stage':'robust_box','boundary':bc,'endpoint':target,'pass':passed,
        'negative':rows[-1]['negative']}),flush=True)
  accepted=all(r['pass'] for r in rows) and all(rows[j]['negative']==rows[j+2]['negative'] for j in [0,1])
  return {'pass':accepted,'lead_cells_per_side':length,'nx':nx,'my':my,
    'tail_kinetic_lower':interval(tau),'geometry_remainder_upper':errors,'rows':rows,
    'count':rows[1]['negative']-rows[0]['negative'] if accepted else None}


def main():
  parser=argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output',required=True);parser.add_argument('--deadline-utc');parser.add_argument('--storage-root')
  args=parser.parse_args()
  if Path(args.output).exists():raise FileExistsError('Use a fresh result filename.')
  configure_budget(args.deadline_utc,args.storage_root);ctx.prec=192
  area_error,mu_error=arb('1e-10'),arb('1e-12')
  model=model_enclosure(area_error,mu_error)
  leads=certify_leads(area_error);box=certify_box(area_error,mu_error)
  passed=leads['pass'] and box['pass'] and box['count']==1
  result={'status':'ROBUST_CONTINUOUS_MODE_COUNT_PROVED' if passed else 'ROBUST_CRITERION_NOT_PASSED',
    'inclusion_symmetric_difference_area_budget':'1e-10','endpoint_band_radius':'1e-12',
    'bits':192,'model_bridge':model,'lead_certificate':leads,'box_certificate':box,
    'resources':check_budget(),'read_saved_scientific_outputs':False,
    'scope':'Exact literal-binary analytic model and certified coefficient neighbourhood; not old meshes or bitwise MATLAB trajectories.'}
  write_json(args.output,result)
  print(json.dumps({'status':result['status'],'resources':result['resources']}),flush=True)


if __name__=='__main__':main()
