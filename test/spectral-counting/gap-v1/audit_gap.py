#!/usr/bin/env python3
"""Recheck a saved bulk-gap result with polar Taylor moments and ball LDL.

The geometry integration and inertia algorithm differ from gap_fourier.py.
Only formatting/resource helpers are shared. The audit verifies every saved
scalar inequality and the exact rational parameter covering, then rebuilds
all finite matrices. All arithmetic certification uses python-flint/Arb.
"""

import argparse
import json
import math
from pathlib import Path
import time

from flint import acb, acb_mat, arb, arb_poly, ctx
from gap_fourier import check_budget, complex_interval, configure_budget, interval, write_json


def dyadic(data):
  return arb((int(data['mantissa']), int(data['exponent'])))


def singleton(record):
  a, b = dyadic(record['lower']), dyadic(record['upper'])
  if a != b:
    raise ValueError('Scalar certificate bound is not an exact singleton.')
  return a


def load_ball(record):
  a, b = dyadic(record['lower']), dyadic(record['upper'])
  return arb((a+b)/2, (b-a)/2)


def area_moments(alpha_text, cutoff, degree):
  """Formula F10: finite Laurent constant terms plus a real-phase remainder."""
  alpha = arb(alpha_text)
  r0 = 1/(5*(1+alpha**2/2).sqrt())
  radius = r0*(1+alpha)
  g = arb_poly([alpha/2, 0, 0, 1, 0, 0, alpha/2])
  powers = []
  power = g*g
  for j in range(degree+1):
    powers.append(power)
    power = power*g
  coefficients = {(0, 0): acb(arb.pi()/25)}
  remainders = []
  for p in range(2*cutoff+1):
    for q in range(2*cutoff+1):
      check_budget()
      if p == q == 0:
        continue
      plus, minus = acb(p, -q)/2, acb(p, q)/2
      plus_powers, minus_powers = [acb(1)], [acb(1)]
      for j in range(degree):
        plus_powers.append(plus_powers[-1]*plus)
        minus_powers.append(minus_powers[-1]*minus)
      total = acb(0)
      scale = acb(2*arb.pi()*r0**2)
      for j in range(degree+1):
        constant = acb(0)
        for k in range(j+1):
          index = 4*j+6-2*k
          if index % 3 == 0:
            constant += math.comb(j, k)*plus_powers[k]*minus_powers[j-k]*powers[j][index]
        total += scale*constant/(j+2)
        scale *= acb(0, -2*arb.pi()*r0)/(j+1)
      phase_bound = 2*arb.pi()*arb(p*p+q*q).sqrt()*radius
      error = (arb.pi()/25*phase_bound**(degree+1)/math.factorial(degree+1)).upper()
      z = acb(total.real+arb(0, error), total.imag+arb(0, error))
      if p == 0:
        if not z.imag.contains(0):
          raise ValueError('Reflection symmetry failed in area moments.')
        z = acb(z.real)
      coefficients[p, q] = z
      remainders.append(error)
  return coefficients, max(remainders)


def ball_ldl(matrix):
  """Unpivoted exact-form Hermitian elimination with interval pivots."""
  n = matrix.nrows()
  lower = [[acb(0) for _ in range(n)] for _ in range(n)]
  diagonal = []
  for k in range(n):
    pivot = matrix[k, k]
    for j in range(k):
      pivot -= lower[k][j]*lower[k][j].conjugate()*diagonal[j]
    if not pivot.imag.contains(0):
      raise ValueError('A Hermitian elimination pivot excludes real values.')
    pivot = pivot.real
    if not (pivot > 0 or pivot < 0):
      return {'pass': False, 'failed_pivot': k, 'pivot': interval(pivot)}
    diagonal.append(pivot)
    lower[k][k] = acb(1)
    for i in range(k+1, n):
      value = matrix[i, k]
      for j in range(k):
        value -= lower[i][j]*diagonal[j]*lower[k][j].conjugate()
      lower[i][k] = value/pivot
  return {'pass': True, 'negative': sum(d < 0 for d in diagonal),
    'positive': sum(d > 0 for d in diagonal),
    'min_abs_pivot': interval(min(d.abs_lower() for d in diagonal)),
    'pivots': [interval(d) for d in diagonal]}


def circle_check():
  moments, _ = area_moments('0', 1, 48)
  checked = 0
  for (p, q), computed in moments.items():
    if p == q == 0:
      reference = acb(arb.pi()/25)
    else:
      wave = 2*arb.pi()*arb(p*p+q*q).sqrt()
      reference = acb(2*arb.pi()/5*(wave/5).bessel_j(1)/wave)
    if not computed.overlaps(reference):
      raise ValueError('Area moments disagree with exact circular Bessel moments.')
    checked += 1
  return {'pass': True, 'moments_compared': checked,
    'reference': '2*pi*R*J_1(|wave|*R)/|wave|, R=1/5'}


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('certificate')
  parser.add_argument('--output', required=True)
  parser.add_argument('--degree', type=int, default=64)
  parser.add_argument('--bits', type=int, default=192)
  parser.add_argument('--deadline-utc', help='Optional UTC ISO date and time.')
  parser.add_argument('--storage-root', help='Optional explicit directory for storage monitoring.')
  args = parser.parse_args()
  if not 80 <= args.bits <= 512:
    raise ValueError('Audit precision exceeds the declared budget.')
  configure_budget(args.deadline_utc, args.storage_root)
  ctx.prec = args.bits
  started = time.monotonic()
  source = Path(args.certificate)
  data = json.loads(source.read_text())
  if Path(args.output).exists():
    raise FileExistsError('Use a fresh audit filename in the same attempt.')
  if data['target'] != ['2.40', '2.46'] or data['beta'] != '1/2':
    raise ValueError('The saved result concerns a different physical target.')
  n, cells = data['cutoff'], data['cells']
  if not 1 <= n <= 5 or not 8 <= cells <= 512 or not 32 <= args.degree <= 96:
    raise ValueError('Audit budget exceeded.')
  radius = singleton(data['radius'])
  a, b = singleton(data['a_expanded']), singleton(data['b_expanded'])
  tau = singleton(data['tail_kinetic_lower'])
  h, delta = singleton(data['tail_positive_lower']), singleton(data['schur_correction_upper'])
  exact_tau = min((((2*n+1)*arb.pi())**2+arb(1)/4).lower(),
    ((2*arb.pi()*(n+1)-arb(1)/2)**2).lower())
  checks = {
    'radius_covers_cell': bool(radius >= arb.pi()/cells),
    'radius_less_than_sqrt_a': bool(radius < arb('2.40').sqrt()),
    'expanded_lower_valid': bool(a <= (arb('2.40').sqrt()-radius)**2),
    'expanded_upper_valid': bool(b >= (arb('2.46').sqrt()+radius)**2),
    'tail_kinetic_lower_valid': bool(tau <= exact_tau),
    'tail_positive_lower_valid': bool(h <= tau-17*b and h > 0),
    'schur_correction_upper_valid': bool(delta >= 64*b*b/h),
    'dimension_valid': data['dimension'] == (2*n+1)**2,
  }
  if not all(checks.values()):
    raise ValueError(f'A scalar proof obligation failed: {checks}')
  saved_rows = {(r['side'], r['cell']): r for r in data['rows']}
  if len(saved_rows) != 2*cells or len(data['rows']) != 2*cells:
    raise ValueError('Missing or duplicate interval records.')
  saved_moments = json.loads(source.with_name(source.stem+'-moments.json').read_text())
  indices = [(u, v) for u in range(-n, n+1) for v in range(-n, n+1)]
  records = []
  geometry = {}
  for side, alpha in [('left', '0.12'), ('right', '0.20')]:
    moments, remainder = area_moments(alpha, n, args.degree)
    comparison = []
    for (p, q), z in moments.items():
      old = saved_moments[side]['coefficient_balls'][f'{p},{q}']
      previous = acb(load_ball(old['real']), load_ball(old['imag']))
      comparison.append(z.overlaps(previous))
    if not all(comparison):
      raise ValueError('Independent material moment enclosures are disjoint.')
    geometry[side] = {'moments_overlap': True, 'count': len(comparison),
      'max_taylor_remainder': interval(remainder)}
    mass = acb_mat(len(indices), len(indices))
    for i, (u, v) in enumerate(indices):
      for j, (w, z) in enumerate(indices):
        p, q = u-w, v-z
        coefficient = moments[abs(p), abs(q)]
        if p < 0:
          coefficient = coefficient.conjugate()
        mass[i, j] = (1 if i == j else 0)+16*coefficient
    for j in range(cells):
      check_budget()
      row = saved_rows[side, j]
      numerator = -cells+2*j+1
      if row['theta_over_pi'] != [numerator, cells] or row['theta_interval_over_pi'] != [-cells+2*j, -cells+2*j+2, cells]:
        raise ValueError('The exact rational interval covering is invalid.')
      theta = arb.pi()*numerator/cells
      results = []
      for value, shift in [(a, arb(0)), (b, delta)]:
        matrix = -mass*value
        for i, (u, v) in enumerate(indices):
          matrix[i, i] += (2*arb.pi()*u+theta)**2+(2*arb.pi()*v+arb(1)/2)**2-shift
        results.append(ball_ldl(matrix))
      low, high = results
      passed = (low['pass'] and high['pass'] and low['negative'] == high['negative']
        and low['negative'] == row['lower']['negative'] == row['upper']['negative'])
      if not passed:
        raise ValueError(f'Independent LDL check failed: {side}, {j}, {results}')
      records.append({'side': side, 'cell': j, 'pass': passed, 'lower': low, 'upper': high})
  result = {'status': 'INDEPENDENT_GEOMETRY_AND_LDL_AUDIT_PASSED',
    'source': source.name, 'bits': args.bits, 'taylor_degree': args.degree,
    'scalar_checks': checks, 'circle_check': circle_check(), 'geometry': geometry,
    'interval_count': len(records), 'matrix_count': 2*len(records), 'records': records,
    'seconds': time.monotonic()-started, 'resources': check_budget(),
    'independence': 'Polar Taylor area moments and interval LDL; shared physical model and Arb backend.'}
  write_json(args.output, result)
  print(json.dumps({k:v for k,v in result.items() if k!='records'}), flush=True)


if __name__ == '__main__':
  main()
