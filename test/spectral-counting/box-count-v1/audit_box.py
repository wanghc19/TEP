#!/usr/bin/env python3
"""Rebuild box certificates with finite Laurent-Taylor material moments.

This audit replaces all boundary quadratures by formula B7. It verifies
overlap with saved enclosures, independently reconstructs the exact scalar
tail bounds, and repeats all inertia checks with ball LDL only. Physical
geometry, matrix assembly, and the Arb backend are shared with box_count.py.
"""

import argparse
import json
import math
from pathlib import Path

from flint import acb, acb_poly, arb, ctx
from gap_fourier import check_budget, configure_budget, interval, write_json
from audit_gap import ball_ldl, load_ball, singleton
from box_count import mass_balls


def fourier_geometry(name):
  if name=='center':
    return {1:arb(3)/10,4:arb(3)/100,6:arb(3)/100}, {1:arb(1)/5,4:-arb(3)/100,6:arb(3)/100}
  alpha=arb('0.12' if name=='left' else '0.20')
  r0=1/(5*(1+alpha*alpha/2).sqrt())
  return {1:r0,2:r0*alpha/2,4:r0*alpha/2}, {1:r0,2:-r0*alpha/2,4:r0*alpha/2}


def laurent_moments(name,width,nx,my,degree):
  aa,bb=fourier_geometry(name);d=max(max(aa),max(bb))
  x=[acb(0) for _ in range(2*d+1)];y=[acb(0) for _ in range(2*d+1)]
  for k,v in aa.items():x[d+k]+=v/2;x[d-k]+=v/2
  for k,v in bb.items():y[d+k]+=acb(0,-v/2);y[d-k]+=acb(0,v/2)
  xx,yy=acb_poly(x),acb_poly(y)
  area=arb.pi()*sum(k*v*bb.get(k,arb(0)) for k,v in aa.items())
  xmax=sum(abs(v) for v in aa.values());ymax=sum(abs(v) for v in bb.values())
  values={(0,0):acb(area)};errors=[]
  for k in range(2*nx+1):
    p=arb(k)/(2*width)
    for q in range(2*my+1):
      check_budget()
      if k==q==0:continue
      phase=p*xx+q*yy
      derivative={}
      if p>=q:
        prefactor=acb(0,1/p);derivative_bound=sum(j*abs(v) for j,v in bb.items())/p
        for j,v in bb.items():derivative[j]=acb(j*v/2);derivative[-j]=acb(j*v/2)
      else:
        prefactor=acb(0,-arb(1)/q);derivative_bound=sum(j*abs(v) for j,v in aa.items())/q
        for j,v in aa.items():derivative[j]=acb(0,j*v/2);derivative[-j]=acb(0,-j*v/2)
      power=acb_poly([1]);scale=acb(1);total=acb(0)
      for j in range(degree+1):
        constant=acb(0)
        for exponent,value in derivative.items():
          index=d*j-exponent
          if 0<=index<=power.degree():constant+=value*power[index]
        total+=scale*constant
        scale*=acb(0,-2*arb.pi())/(j+1)
        power=power*phase
      total*=prefactor
      wave=2*arb.pi()*(p*xmax+q*ymax)
      error=(derivative_bound*wave**(degree+1)/math.factorial(degree+1)).upper()
      values[k,q]=acb(total.real+arb(0,error),total.imag+arb(0,error));errors.append(error)
  return values,max(errors)


def main():
  parser=argparse.ArgumentParser(description=__doc__)
  parser.add_argument('certificate');parser.add_argument('--output',required=True)
  parser.add_argument('--deadline-utc');parser.add_argument('--storage-root')
  args=parser.parse_args()
  if Path(args.output).exists():raise FileExistsError('Use a fresh audit filename.')
  configure_budget(args.deadline_utc,args.storage_root);ctx.prec=192
  source=Path(args.certificate);data=json.loads(source.read_text())
  length,nx,my=data['lead_cells_per_side'],data['nx'],data['my'];width=2*length+1
  if not 1<=length<=3 or not 8<=nx<=32 or not 1<=my<=3:raise ValueError('Audit budget exceeded.')
  if data['target']!=['2.40','2.46'] or data['width']!=width:raise ValueError('Wrong target.')
  old=json.loads(source.with_name(source.stem+'-moments.json').read_text())
  moments={};geometry={}
  for name in ['left','right','center']:
    values,error=laurent_moments(name,width,nx,my,96)
    for (k,q),z in values.items():
      previous=old[name][f'{k},{q}']
      if not z.overlaps(acb(load_ball(previous['real']),load_ball(previous['imag']))):
        raise RuntimeError(f'Independent material moment is disjoint: {name}, {k}, {q}.')
    moments[name]=values
    geometry[name]={'count':len(values),'all_overlap':True,'maximum_taylor_remainder':interval(error)}
    print(json.dumps({'geometry':name,'moment_count':len(values),'pass':True}),flush=True)
  tau=singleton(data['tail_kinetic_lower'])
  exact_tau=min(((arb.pi()*(nx+1)/width)**2+arb(1)/4).lower(),
    ((2*arb.pi()*(my+1)-arb(1)/2)**2).lower())
  if not tau<=exact_tau:raise ValueError('Invalid kinetic lower bound.')
  records=[]
  for bc in ['D','N']:
    mass,indices=mass_balls(moments,length,nx,my,bc,1)
    mass2,_=mass_balls(moments,length,nx,my,bc,2);covariance=mass2-mass*mass
    for target in ['2.40','2.46']:
      row=next(r for r in data['rows'] if r['boundary']==bc and r['mu']==target)
      value=arb(target);h=singleton(row['tail_positive_lower']);factor=singleton(row['covariance_factor_upper'])
      if not h>0 or not h<=tau-17*value or not factor>=value*value/h:
        raise ValueError('Invalid complement or covariance coefficient.')
      upper=-value*mass
      for i,(n,m) in enumerate(indices):upper[i,i]+=(arb.pi()*n/width)**2+(2*arb.pi()*m+arb(1)/2)**2
      lower=upper-factor*covariance
      checks=[ball_ldl(upper),ball_ldl(lower)]
      if not all(c['pass'] and c['negative']==row['negative'] for c in checks):
        raise RuntimeError('Independent box LDL failed.')
      records.append({'boundary':bc,'mu':target,'pass':True,'upper':checks[0],'lower':checks[1]})
      print(json.dumps({'boundary':bc,'mu':target,'negative':row['negative'],'pass':True}),flush=True)
  result={'status':'LAURENT_GEOMETRY_AND_BOX_LDL_AUDIT_PASSED','source':source.name,
    'bits':192,'taylor_degree':96,'geometry':geometry,'records':records,
    'resources':check_budget(),'scope':'Independent Laurent integration; shared geometry model, assembly, and Arb backend.'}
  write_json(args.output,result)
  print(json.dumps({'status':result['status'],'resources':result['resources']}),flush=True)


if __name__=='__main__':main()
