#!/usr/bin/env python3
"""Certify continuous finite-box inertia for D/N bracketing of a defect mode.

The exact five-lobe center and trilobe leads retain densities 4 and 17.
True material moments have analytic trapezoidal remainders. A matrix-valued
covariance controls all omitted cosine/sine-Fourier directions. Congruence
and ball LDL certify the finite upper and lower matrices at both endpoints.
See BC1--BC3 and B5--B6 in s-box-count.md for the infinite-guide implication.
"""

import argparse
import json
from pathlib import Path
import time

import numpy as np
from flint import acb, acb_mat, arb, ctx
from gap_fourier import (check_budget, certified_inertia, complex_interval,
  configure_budget, geometry_balls, geometry_float, interval, write_json)
from audit_gap import ball_ldl


def center_float(nodes):
  t = 2*np.pi*np.arange(nodes)/nodes
  x = .3*np.cos(t)+.03*(np.cos(4*t)+np.cos(6*t))
  y = .2*np.sin(t)+.03*(np.sin(6*t)-np.sin(4*t))
  dx = -.3*np.sin(t)-.12*np.sin(4*t)-.18*np.sin(6*t)
  dy = .2*np.cos(t)+.18*np.cos(6*t)-.12*np.cos(4*t)
  return x,y,dx,dy


def moments_float(length,nx,my,nodes=256):
  width=2*length+1
  shapes={'left':geometry_float(.12,nodes),'right':geometry_float(.20,nodes),
    'center':center_float(nodes)}
  result={name:{} for name in shapes}
  for name,(x,y,dx,dy) in shapes.items():
    for k in range(2*nx+1):
      p=k/(2*width)
      for q in range(2*my+1):
        if k==q==0:
          z=(309*np.pi/5000) if name=='center' else np.pi/25
        else:
          factor=1j*dy/(2*np.pi*p) if p>=q else -1j*dx/(2*np.pi*q)
          z=2*np.pi*np.mean(factor*np.exp(-2j*np.pi*(p*x+q*y)))
        result[name][k,q]=z
  return result


def mass_float(moments,length,nx,my,bc,power):
  width=2*length+1
  cosine=np.empty((2*nx+1,2*my+1))
  for k in range(2*nx+1):
    p=k/(2*width)
    for q in range(2*my+1):
      z=(4**power-1)*moments['center'][k,q]
      for j in range(1,length+1):
        z+=(17**power-1)*(moments['left'][k,q]*np.exp(2j*np.pi*p*j)
          +moments['right'][k,q]*np.exp(-2j*np.pi*p*j))
      cosine[k,q]=((-1j)**k*z).real
  modes=np.array([(n,m) for n in range(0 if bc=='N' else 1,nx+1)
    for m in range(-my,my+1)])
  n,m=modes.T
  c=np.where(n==0,1,np.sqrt(2))
  q=np.abs(m[:,None]-m[None,:])
  terms=cosine[np.abs(n[:,None]-n[None,:]),q]
  terms=terms+(1 if bc=='N' else -1)*cosine[n[:,None]+n[None,:],q]
  return np.eye(len(n))+c[:,None]*c[None,:]*terms/(2*width),modes


def probe(args):
  rows=[]
  for length in [1,2,3]:
    for nx in [16,24,32]:
      check_budget()
      my=3; width=2*length+1
      moments=moments_float(length,nx,my)
      counts={}; margin=float('inf')
      for bc in ['D','N']:
        mass,indices=mass_float(moments,length,nx,my,bc,1)
        mass2,_=mass_float(moments,length,nx,my,bc,2)
        covariance=mass2-mass@mass
        kinetic=(indices[:,0]*np.pi/width)**2+(2*np.pi*indices[:,1]+.5)**2
        tau=min((np.pi*(nx+1)/width)**2+.25,(2*np.pi*(my+1)-.5)**2)
        for value in [2.40,2.46]:
          h=tau-17*value
          if h<=0: raise RuntimeError('Probe tail is not positive.')
          upper=np.diag(kinetic)-value*mass
          lower=upper-(value*value/h)*covariance
          numbers=[]
          for matrix in [upper,lower]:
            vals=np.linalg.eigvalsh(matrix)
            numbers.append(int(np.count_nonzero(vals<0)))
            margin=min(margin,float(np.min(np.abs(vals))))
          counts[f'{bc}-{value:.2f}']=numbers
      passing=all(len(set(counts[f'D-{v}']+counts[f'N-{v}']))==1 for v in ['2.40','2.46'])
      row={'lead_cells_per_side':length,'nx':nx,'my':my,'counts':counts,
        'minimum_ordinary_margin':margin,'ordinary_pass':passing}
      rows.append(row); print(json.dumps(row),flush=True)
      if passing:
        write_json(args.output,{'status':'ORDINARY_FEASIBILITY_ONLY','rows':rows,'selected':row,
          'resources':check_budget()})
        return
  write_json(args.output,{'status':'NO_ORDINARY_CONFIGURATION_PASSED','rows':rows,
    'resources':check_budget()})


def center_balls(nodes,strip):
  geometry=[]
  for j in range(nodes):
    t=2*arb.pi()*j/nodes
    x=3*t.cos()/10+3*((4*t).cos()+(6*t).cos())/100
    y=t.sin()/5+3*((6*t).sin()-(4*t).sin())/100
    dx=-3*t.sin()/10-3*(4*t).sin()/25-9*(6*t).sin()/50
    dy=t.cos()/5+9*(6*t).cos()/50-3*(4*t).cos()/25
    geometry.append((x,y,dx,dy))
  hx=3*strip.sinh()/10+3*((4*strip).sinh()+(6*strip).sinh())/100
  hy=strip.sinh()/5+3*((4*strip).sinh()+(6*strip).sinh())/100
  jx=3*strip.cosh()/10+3*(4*strip).cosh()/25+9*(6*strip).cosh()/50
  jy=strip.cosh()/5+3*(4*strip).cosh()/25+9*(6*strip).cosh()/50
  return geometry,hx,hy,jx,jy


def moments_balls(length,nx,my,nodes):
  width=2*length+1;strip=arb('0.2')
  result={}; errors={}
  for name,alpha_text in [('left','0.12'),('right','0.20'),('center',None)]:
    if name=='center':
      geometry,hx,hy,jx,jy=center_balls(nodes,strip)
      area=309*arb.pi()/5000
    else:
      alpha=arb(alpha_text);r0,geometry=geometry_balls(alpha,nodes)
      hx=hy=r0*(strip.sinh()+alpha*((4*strip).sinh()+(2*strip).sinh())/2)
      jx=jy=r0*(strip.cosh()+alpha*(2*(4*strip).cosh()+(2*strip).cosh()))
      area=arb.pi()/25
    values={(0,0):acb(area)};remainders=[]
    for k in range(2*nx+1):
      p=arb(k)/(2*width)
      for q in range(2*my+1):
        check_budget()
        if k==q==0:continue
        total=acb(0)
        for x,y,dx,dy in geometry:
          factor=acb(0,dy/(2*arb.pi()*p)) if p>=q else acb(0,-dx/(2*arb.pi()*q))
          total+=factor*acb(0,-2*arb.pi()*(p*x+q*y)).exp()
        total*=2*arb.pi()/nodes
        prefactor=jy/(2*arb.pi()*p) if p>=q else jx/(2*arb.pi()*q)
        maximum=prefactor*(2*arb.pi()*(p*hx+q*hy)).exp()
        error=(4*arb.pi()*maximum/((nodes*strip).exp()-1)).upper()
        values[k,q]=acb(total.real+arb(0,error),total.imag+arb(0,error))
        remainders.append(error)
    result[name]=values;errors[name]=interval(max(remainders))
  return result,errors


def mass_balls(moments,length,nx,my,bc,power):
  width=2*length+1;phases=[acb(1),acb(0,-1),acb(-1),acb(0,1)]
  cosine={}
  for k in range(2*nx+1):
    p=arb(k)/(2*width)
    for q in range(2*my+1):
      z=(4**power-1)*moments['center'][k,q]
      for j in range(1,length+1):
        phase=acb(0,2*arb.pi()*p*j).exp()
        z+=(17**power-1)*(moments['left'][k,q]*phase
          +moments['right'][k,q]*phase.conjugate())
      cosine[k,q]=(phases[k%4]*z).real
  indices=[(n,m) for n in range(0 if bc=='N' else 1,nx+1) for m in range(-my,my+1)]
  mass=acb_mat(len(indices),len(indices))
  for i,(n,m) in enumerate(indices):
    cn=arb(1) if n==0 else arb(2).sqrt()
    for j,(ell,v) in enumerate(indices):
      cl=arb(1) if ell==0 else arb(2).sqrt()
      term=cosine[abs(n-ell),abs(m-v)]+(1 if bc=='N' else -1)*cosine[n+ell,abs(m-v)]
      mass[i,j]=(1 if i==j else 0)+cn*cl*term/(2*width)
  return mass,indices


def finite_check(matrix):
  size=matrix.nrows()
  mid=np.array([[float(matrix[i,j].real.mid()) for j in range(size)] for i in range(size)])
  congruence=certified_inertia(matrix,mid)
  ldl=ball_ldl(matrix)
  return {'pass':congruence['pass'] and ldl['pass'] and congruence['negative']==ldl['negative'],
    'congruence':congruence,'ldl':ldl}


def certify(args):
  ctx.prec=192;length,nx,my=args.length,args.nx,args.my;width=2*length+1
  moments,errors=moments_balls(length,nx,my,256)
  out=Path(args.output)
  write_json(out.with_name(out.stem+'-moments.json'),
    {name:{f'{k},{q}':complex_interval(z) for (k,q),z in values.items()}
    for name,values in moments.items()})
  tau=min(((arb.pi()*(nx+1)/width)**2+arb(1)/4).lower(),
    ((2*arb.pi()*(my+1)-arb(1)/2)**2).lower())
  rows=[]
  for bc in ['D','N']:
    mass,indices=mass_balls(moments,length,nx,my,bc,1)
    mass2,_=mass_balls(moments,length,nx,my,bc,2)
    covariance=mass2-mass*mass
    for text_value in ['2.40','2.46']:
      check_budget();start=time.monotonic();value=arb(text_value)
      h=(tau-17*value).lower()
      if not h>0:raise RuntimeError('Finite-box complement not positive.')
      factor=(value*value/h).upper()
      upper=-value*mass
      for i,(n,m) in enumerate(indices):
        upper[i,i]+=(arb.pi()*n/width)**2+(2*arb.pi()*m+arb(1)/2)**2
      lower=upper-factor*covariance
      uc,lc=finite_check(upper),finite_check(lower)
      passed=uc['pass'] and lc['pass'] and uc['congruence']['negative']==lc['congruence']['negative']
      row={'boundary':bc,'mu':text_value,'dimension':len(indices),'tail_positive_lower':interval(h),
        'covariance_factor_upper':interval(factor),'upper':uc,'lower':lc,'pass':passed,
        'negative':uc['congruence']['negative'] if passed else None,'seconds':time.monotonic()-start}
      rows.append(row)
      print(json.dumps({'boundary':bc,'mu':text_value,'dimension':len(indices),'pass':passed,
        'upper_negative':uc['congruence']['negative'],'lower_negative':lc['congruence']['negative'],
        'seconds':row['seconds']}),flush=True)
  complete=all(r['pass'] for r in rows) and all(rows[j]['negative']==rows[j+2]['negative'] for j in [0,1])
  result={'status':'CONTINUOUS_BOX_ENDPOINTS_PROVED' if complete else 'BOX_CRITERION_NOT_PASSED',
    'lead_cells_per_side':length,'nx':nx,'my':my,'width':width,'bits':192,'nodes':256,
    'target':['2.40','2.46'],'tail_kinetic_lower':interval(tau),'geometry_remainder_upper':errors,
    'rows':rows,'resources':check_budget(),
    'continuous_center_inertia':[rows[j]['negative']-2*length for j in [0,1]] if complete else None,
    'defect_mode_count':rows[1]['negative']-rows[0]['negative'] if complete else None,
    'scope':'Conditional on BC1--BC3 and certified single-cell D/N separation; exact analytic geometry.'}
  write_json(out,result)
  print(json.dumps({'status':result['status'],'count':result['defect_mode_count'],'resources':result['resources']}),flush=True)


def main():
  parser=argparse.ArgumentParser(description=__doc__)
  parser.add_argument('mode',choices=['probe','certify']);parser.add_argument('--output',required=True)
  parser.add_argument('--length',type=int,default=2);parser.add_argument('--nx',type=int,default=24)
  parser.add_argument('--my',type=int,default=3);parser.add_argument('--deadline-utc');parser.add_argument('--storage-root')
  args=parser.parse_args()
  if not 1<=args.length<=3 or not 8<=args.nx<=32 or not 1<=args.my<=3:
    raise ValueError('Configuration exceeds the declared small-run budget.')
  if Path(args.output).exists():raise FileExistsError('Use a fresh filename in the same attempt.')
  configure_budget(args.deadline_utc,args.storage_root)
  probe(args) if args.mode=='probe' else certify(args)


if __name__=='__main__':main()
