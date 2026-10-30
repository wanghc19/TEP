#!/usr/bin/env python3
"""Certify a half-guide Dirichlet gap by single-cell D/N bracketing.

An explicit Dirichlet trial gives the first eigenvalue upper bound. A
cosine/Fourier Neumann block and a positive infinite complement bound the
second eigenvalue below. Boundary trapezoidal and polar Taylor material
moments provide two reliable constructions, checked by congruence and LDL.
The formulas are D5--D8 and HD1--HD2 in s-half-gap.md. No MATLAB is used.
"""

import argparse
import json
import math
from pathlib import Path
import time

import numpy as np
from flint import acb, acb_mat, arb, arb_poly, ctx

from gap_fourier import (check_budget, certified_inertia, complex_interval,
  configure_budget, geometry_balls, interval, write_json)
from audit_gap import ball_ldl


def boundary_moments(alpha_text, nx, my, nodes):
  """F3 boundary quadrature, now including half-integer x frequencies."""
  alpha, strip = arb(alpha_text), arb('0.2')
  r0, geometry = geometry_balls(alpha, nodes)
  hs = r0*(strip.sinh()+alpha*((4*strip).sinh()+(2*strip).sinh())/2)
  js = r0*(strip.cosh()+alpha*(2*(4*strip).cosh()+(2*strip).cosh()))
  denominator = (nodes*strip).exp()-1
  moments = {(0, 0): acb(arb.pi()/25)}
  errors = []
  for k in range(2*nx+1):
    p = arb(k)/2
    for q in range(2*my+1):
      check_budget()
      if k == q == 0:
        continue
      total = acb(0)
      for x, y, dx, dy in geometry:
        factor = acb(0, dy/(2*arb.pi()*p)) if p >= q else acb(0, -dx/(2*arb.pi()*q))
        total += factor*acb(0, -2*arb.pi()*(p*x+q*y)).exp()
      total *= 2*arb.pi()/nodes
      maximum = js/(2*arb.pi()*max(p, q))*(2*arb.pi()*(p+q)*hs).exp()
      error = (4*arb.pi()*maximum/denominator).upper()
      z = acb(total.real+arb(0, error), total.imag+arb(0, error))
      if k == 0:
        if not z.imag.contains(0):
          raise RuntimeError('Reflection identity failed.')
        z = acb(z.real, 0)
      moments[k, q] = z
      errors.append(error)
  return moments, max(errors)


def polar_moments(alpha_text, nx, my, degree):
  """Adapt F5 area moments to p=k/2; no boundary quadrature is reused."""
  alpha = arb(alpha_text)
  r0 = 1/(5*(1+alpha**2/2).sqrt())
  radius = r0*(1+alpha)
  g = arb_poly([alpha/2, 0, 0, 1, 0, 0, alpha/2])
  power, powers = g*g, []
  for j in range(degree+1):
    powers.append(power)
    power = power*g
  moments = {(0, 0): acb(arb.pi()/25)}
  errors = []
  for k in range(2*nx+1):
    p = arb(k)/2
    for q in range(2*my+1):
      check_budget()
      if k == q == 0:
        continue
      plus, minus = acb(p, -q)/2, acb(p, q)/2
      plus_powers, minus_powers = [acb(1)], [acb(1)]
      for j in range(degree):
        plus_powers.append(plus_powers[-1]*plus)
        minus_powers.append(minus_powers[-1]*minus)
      total, scale = acb(0), acb(2*arb.pi()*r0**2)
      for j in range(degree+1):
        constant = acb(0)
        for ell in range(j+1):
          index = 4*j+6-2*ell
          if index % 3 == 0:
            constant += math.comb(j, ell)*plus_powers[ell]*minus_powers[j-ell]*powers[j][index]
        total += scale*constant/(j+2)
        scale *= acb(0, -2*arb.pi()*r0)/(j+1)
      wave = 2*arb.pi()*(p*p+q*q).sqrt()*radius
      error = (arb.pi()/25*wave**(degree+1)/math.factorial(degree+1)).upper()
      z = acb(total.real+arb(0, error), total.imag+arb(0, error))
      if k == 0:
        if not z.imag.contains(0):
          raise RuntimeError('Polar reflection identity failed.')
        z = acb(z.real, 0)
      moments[k, q] = z
      errors.append(error)
  return moments, max(errors)


def mass_matrix(moments, indices):
  """D8: exact cosine products preserve both coordinates of the material."""
  phases = [acb(1), acb(0, -1), acb(-1), acb(0, 1)]
  def cosine(k, q):
    z = moments[abs(k), abs(q)]
    if k < 0:
      z = z.conjugate()
    return (phases[k % 4]*z).real
  mass = acb_mat(len(indices), len(indices))
  for i, (n, m) in enumerate(indices):
    cn = arb(1) if n == 0 else arb(2).sqrt()
    for j, (ell, v) in enumerate(indices):
      cl = arb(1) if ell == 0 else arb(2).sqrt()
      mass[i, j] = (1 if i == j else 0)+8*cn*cl*(cosine(n-ell, m-v)+cosine(n+ell, m-v))
  return mass


def evaluate(moments, indices, a0, b0, delta, method):
  denominator = 1+16*(arb.pi()/25+moments[2, 0].real)
  if not denominator > 0:
    raise RuntimeError('Trial mass has no proved positive lower bound.')
  trial = ((arb.pi()**2+arb(1)/4)/denominator).upper()
  mass = mass_matrix(moments, indices)
  matrix = -b0*mass
  for i, (n, m) in enumerate(indices):
    matrix[i, i] += (n*arb.pi())**2+(2*arb.pi()*m+arb(1)/2)**2-delta
  if method == 'congruence':
    mid = np.array([[complex(float(matrix[i,j].real.mid()), float(matrix[i,j].imag.mid()))
      for j in range(len(indices))] for i in range(len(indices))])
    inertia = certified_inertia(matrix, mid)
  else:
    inertia = ball_ldl(matrix)
  accepted = bool(trial < a0 and inertia['pass'] and inertia['negative'] == 1)
  return {'pass': accepted, 'dirichlet_trial_upper': interval(trial),
    'trial_mass': interval(denominator), 'neumann_corrected_inertia': inertia}


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--nx', type=int, default=4)
  parser.add_argument('--my', type=int, default=2)
  parser.add_argument('--a0', default='2.30')
  parser.add_argument('--b0', default='2.60')
  parser.add_argument('--deadline-utc')
  parser.add_argument('--storage-root')
  args = parser.parse_args()
  if not 2 <= args.nx <= 6 or not 1 <= args.my <= 3:
    raise ValueError('Configuration exceeds the declared small-run budget.')
  if Path(args.output).exists():
    raise FileExistsError('Use a fresh result filename in the same attempt.')
  configure_budget(args.deadline_utc, args.storage_root)
  ctx.prec = 192
  a0, b0 = arb(args.a0), arb(args.b0)
  if not 0 < a0 < arb('2.40') < arb('2.46') < b0:
    raise ValueError('Barriers must strictly enclose the target interval.')
  tau = min(((arb.pi()*(args.nx+1))**2+arb(1)/4).lower(),
    ((2*arb.pi()*(args.my+1)-arb(1)/2)**2).lower())
  h = (tau-17*b0).lower()
  if not h > 0:
    raise RuntimeError('Unresolved positive Neumann complement.')
  delta = (64*b0*b0/h).upper()
  indices = [(n,m) for n in range(args.nx+1) for m in range(-args.my,args.my+1)]
  results, evidence = [], {}
  out = Path(args.output)
  for side, alpha in [('left','0.12'), ('right','0.20')]:
    start = time.monotonic()
    boundary, error_b = boundary_moments(alpha,args.nx,args.my,256)
    polar, error_p = polar_moments(alpha,args.nx,args.my,64)
    overlap = all(boundary[key].overlaps(polar[key]) for key in boundary)
    if not overlap:
      raise RuntimeError('Independent geometry moments are disjoint.')
    first = evaluate(boundary,indices,a0,b0,delta,'congruence')
    second = evaluate(polar,indices,a0,b0,delta,'ldl')
    results.append({'side':side,'alpha':alpha,'boundary_congruence':first,
      'polar_ldl':second,'moments_overlap':overlap,'moment_count':len(boundary),
      'boundary_remainder_upper':interval(error_b),'polar_remainder_upper':interval(error_p),
      'pass':first['pass'] and second['pass'],'seconds':time.monotonic()-start})
    evidence[side] = {method:{f'{k},{q}':complex_interval(z) for (k,q),z in values.items()}
      for method,values in [('boundary',boundary),('polar',polar)]}
    print(json.dumps({'side':side,'pass':results[-1]['pass'],
      'trial':first['dirichlet_trial_upper']['display'],
      'congruence_negative':first['neumann_corrected_inertia']['negative'],
      'ldl_negative':second['neumann_corrected_inertia']['negative']}),flush=True)
  accepted = all(row['pass'] for row in results)
  distance = min((arb('2.40')-a0).lower(),(b0-arb('2.46')).lower())
  result = {'status':'HALF_GUIDE_DIRICHLET_GAP_PROVED' if accepted else 'BRACKETING_NOT_PASSED',
    'target':['2.40','2.46'],'barriers':[args.a0,args.b0],'beta':'1/2',
    'actual_cuts':['-1/2','1/2'],'nx':args.nx,'my':args.my,'dimension':len(indices),
    'bits':192,'boundary_nodes':256,'polar_degree':64,
    'tail_kinetic_lower':interval(tau),'tail_positive_lower':interval(h),
    'schur_correction_upper':interval(delta),
    'half_guide_spectral_distance_lower':interval(distance) if accepted else None,
    'rows':results,'resources':check_budget(),
    'scope':'Exact analytic geometry; actual cell-edge Dirichlet walls; no defect mode count.',
    'independence':'Different integration and inertia algorithms; shared assembly and Arb backend.'}
  write_json(out.with_name(out.stem+'-moments.json'),evidence)
  write_json(out,result)
  print(json.dumps({'status':result['status'],'resources':result['resources']}),flush=True)


if __name__ == '__main__':
  main()
