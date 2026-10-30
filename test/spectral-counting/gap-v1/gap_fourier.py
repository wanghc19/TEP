#!/usr/bin/env python3
"""Enclose a common bulk gap for two genuine two-dimensional periodic leads.

The scalar Helmholtz operator is -rho^{-1} Delta, with rho=17 inside a
trilobe and rho=1 outside. This independent Fourier implementation uses
the exact radial geometry, an analytic trapezoidal remainder, a positive
infinite complement, and square-root band Lipschitz coverage. NumPy supplies
only an arbitrary congruence matrix; Arb certifies all accepted signs.

Inputs are explicit CLI parameters. No reports, Git state, or old results
are needed. Output is compact JSON/CSV; no full eigenvector arrays are saved.
"""

import argparse
import csv
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import resource
import sys
import time

import numpy as np
from flint import acb, acb_mat, arb, ctx
import flint


A = '2.40'
B = '2.46'
ALPHAS = [('left', '0.12'), ('right', '0.20')]
STARTED = time.monotonic()
DEADLINE = None
STORAGE_ROOT = None
STORAGE_CHECKED = -math.inf
STORAGE_BYTES = None


def configure_budget(deadline_utc=None, storage_root=None):
  """Accept explicit run controls without baking a historical date into reuse."""
  global DEADLINE, STORAGE_ROOT
  if deadline_utc:
    DEADLINE = datetime.fromisoformat(deadline_utc).replace(tzinfo=timezone.utc).timestamp()
  if storage_root:
    STORAGE_ROOT = Path(storage_root).resolve()
  resource.setrlimit(resource.RLIMIT_CPU, (1800, 1801))
  check_budget(force_storage=True)


def check_budget(force_storage=False):
  """Enforce the serial process budget before each bounded numerical block."""
  elapsed = time.monotonic() - STARTED
  rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
  if sys.platform != 'darwin':
    rss *= 1024
  global STORAGE_CHECKED, STORAGE_BYTES
  if elapsed > 1800 or (DEADLINE is not None and time.time() >= DEADLINE):
    raise RuntimeError('Scientific wall-time or research deadline reached.')
  if rss >= 1_000_000_000:
    raise RuntimeError('The one-process memory budget was exceeded.')
  if STORAGE_ROOT is not None and (force_storage or elapsed-STORAGE_CHECKED >= 1):
    # Never traverse symlinks or inspect Git metadata. Reserve space for its pointer.
    total = 1_048_576
    pending = [STORAGE_ROOT]
    while pending:
      parent = pending.pop()
      for item in os.scandir(parent):
        if item.name == '.git':
          continue
        stat = item.stat(follow_symlinks=False)
        total += max(stat.st_size, stat.st_blocks*512)
        if item.is_dir(follow_symlinks=False):
          pending.append(Path(item.path))
    STORAGE_BYTES = total
    STORAGE_CHECKED = elapsed
    if total >= 900_000_000:
      raise RuntimeError('Repository storage reached the 900 MB pre-stop threshold.')
  return {'elapsed_seconds': elapsed, 'peak_rss_bytes': int(rss),
    'storage_budget_bytes': STORAGE_BYTES}


def endpoint(x):
  """Serialize an exact dyadic Arb endpoint without decimal truncation."""
  if not x.is_exact():
    raise ValueError('Expected an exact dyadic endpoint.')
  mantissa, exponent = x.man_exp()
  return {'mantissa': str(mantissa), 'exponent': int(exponent)}


def interval(x):
  return {'lower': endpoint(x.lower()), 'upper': endpoint(x.upper()),
    'display': str(x)}


def complex_interval(z):
  return {'real': interval(z.real), 'imag': interval(z.imag)}


def write_json(path, data):
  payload = json.dumps(data, indent=2, allow_nan=False)+'\n'
  if len(payload.encode()) > 10_000_000:
    raise RuntimeError('A compact output would exceed the 10 MB file budget.')
  check_budget(force_storage=True)
  Path(path).write_text(payload)


def modes(cutoff):
  return [(n, m) for n in range(-cutoff, cutoff+1)
    for m in range(-cutoff, cutoff+1)]


def geometry_float(alpha, nodes):
  t = 2*np.pi*np.arange(nodes)/nodes
  r0 = 0.2/np.sqrt(1+alpha*alpha/2)
  r = r0*(1+alpha*np.cos(3*t))
  dr = -3*r0*alpha*np.sin(3*t)
  ct, st = np.cos(t), np.sin(t)
  return r*ct, r*st, dr*ct-r*st, dr*st+r*ct


def mass_float(alpha, cutoff, nodes):
  """Ordinary quadrature for reconnaissance, never for a certificate."""
  x, y, dx, dy = geometry_float(alpha, nodes)
  coeff = {(0, 0): complex(np.pi/25)}
  for p in range(2*cutoff+1):
    for q in range(2*cutoff+1):
      if p == q == 0:
        continue
      phase = np.exp(-2j*np.pi*(p*x+q*y))
      values = (1j*dy/(2*np.pi*p) if p >= q else
        -1j*dx/(2*np.pi*q))*phase
      z = 2*np.pi*np.mean(values)
      coeff[p, q] = complex(z.real, 0) if p == 0 else z
  indices = modes(cutoff)
  result = np.empty((len(indices), len(indices)), dtype=complex)
  for i, (ni, mi) in enumerate(indices):
    for j, (nj, mj) in enumerate(indices):
      p, q = ni-nj, mi-mj
      z = coeff[abs(p), abs(q)]
      result[i, j] = (1 if i == j else 0) + 16*(z.conjugate() if p < 0 else z)
  return result


def bounds_float(cutoff, cells):
  radius = np.pi/cells
  a = (np.sqrt(float(A))-radius)**2
  b = (np.sqrt(float(B))+radius)**2
  tau = min(((2*cutoff+1)*np.pi)**2+0.25,
    (2*np.pi*(cutoff+1)-0.5)**2)
  h = tau-17*b
  return radius, a, b, h, 64*b*b/h if h > 0 else math.inf


def probe(args):
  rows = []
  for cutoff in [1, 2, 3, 4, 5]:
    matrices = [(side, mass_float(float(alpha), cutoff, args.nodes))
      for side, alpha in ALPHAS]
    indices = np.array(modes(cutoff))
    for cells in [8, 16, 32, 64, 128]:
      radius, a, b, h, delta = bounds_float(cutoff, cells)
      if radius >= math.sqrt(float(A)) or h <= 0:
        continue
      counts = set()
      min_gap = math.inf
      for side, mass in matrices:
        for j in range(cells):
          check_budget()
          theta = np.pi*(-1+(2*j+1)/cells)
          kinetic = (2*np.pi*indices[:, 0]+theta)**2 + (2*np.pi*indices[:, 1]+0.5)**2
          for value, shift in [(a, 0), (b, delta)]:
            vals = np.linalg.eigvalsh(np.diag(kinetic-shift)-value*mass)
            counts.add(int(np.count_nonzero(vals < 0)))
            min_gap = min(min_gap, float(np.min(np.abs(vals))))
      row = dict(cutoff=cutoff, dimension=len(indices), cells=cells,
        radius=radius, a_expanded=a, b_expanded=b, h=h, delta=delta,
        negative_counts=sorted(counts), min_abs_eigenvalue=min_gap,
        ordinary_pass=(len(counts) == 1),
        rough_congruence_work=4*cells*len(indices)**3)
      rows.append(row)
      print(json.dumps(row), flush=True)
      if len(counts) == 1:
        break
  write_json(args.output, {'status': 'ORDINARY_FEASIBILITY_ONLY', 'rows': rows,
    'versions': {'numpy': np.__version__, 'python_flint': flint.__version__},
    'resources': check_budget()})


def geometry_balls(alpha, nodes):
  r0 = arb(1)/(5*(1+alpha*alpha/2).sqrt())
  values = []
  for j in range(nodes):
    t = 2*arb.pi()*j/nodes
    ct, st = t.cos(), t.sin()
    r = r0*(1+alpha*(3*t).cos())
    dr = -3*r0*alpha*(3*t).sin()
    values.append((r*ct, r*st, dr*ct-r*st, dr*st+r*ct))
  return r0, values


def mass_balls(alpha_text, cutoff, nodes, strip_text):
  """Enclose every needed true-material Fourier moment using formula F8."""
  alpha, strip = arb(alpha_text), arb(strip_text)
  r0, geometry = geometry_balls(alpha, nodes)
  imag_bound = r0*(strip.sinh()+alpha*((4*strip).sinh()+(2*strip).sinh())/2)
  derivative_bound = r0*(strip.cosh()+alpha*(2*(4*strip).cosh()+(2*strip).cosh()))
  denominator = (nodes*strip).exp()-1
  coeff = {(0, 0): acb(arb.pi()/25)}
  remainders = {}
  for p in range(2*cutoff+1):
    for q in range(2*cutoff+1):
      check_budget()
      if p == q == 0:
        continue
      total = acb(0)
      for x, y, dx, dy in geometry:
        factor = acb(0, dy/(2*arb.pi()*p)) if p >= q else acb(0, -dx/(2*arb.pi()*q))
        total += factor*acb(0, -2*arb.pi()*(p*x+q*y)).exp()
      total *= 2*arb.pi()/nodes
      maximum = derivative_bound/(2*arb.pi()*max(p, q)) * (2*arb.pi()*(p+q)*imag_bound).exp()
      remainder = (4*arb.pi()*maximum/denominator).upper()
      # A complex error of modulus <= remainder is in this rectangle.
      z = acb(total.real+arb(0, remainder), total.imag+arb(0, remainder))
      if p == 0:
        if not z.imag.contains(0):
          raise RuntimeError('Exact reflection symmetry is outside the computed enclosure.')
        z = acb(z.real, 0)
      coeff[p, q] = z
      remainders[p, q] = remainder
  indices = modes(cutoff)
  mass = acb_mat(len(indices), len(indices))
  mid = np.empty((len(indices), len(indices)), dtype=complex)
  for i, (ni, mi) in enumerate(indices):
    for j, (nj, mj) in enumerate(indices):
      p, q = ni-nj, mi-mj
      z = coeff[abs(p), abs(q)]
      if p < 0:
        z = z.conjugate()
      mass[i, j] = (1 if i == j else 0)+16*z
      z = mass[i, j]
      mid[i, j] = complex(float(z.real.mid()), float(z.imag.mid()))
  evidence = {'alpha': alpha_text, 'nodes': nodes, 'strip': strip_text,
    'max_trapezoid_remainder': interval(max(remainders.values())),
    'coefficient_balls': {f'{p},{q}': complex_interval(z) for (p, q), z in coeff.items()}}
  return mass, mid, evidence


def certified_inertia(matrix, mid):
  """Prove inertia by exact-dyadic congruence and strict diagonal dominance."""
  _, vectors = np.linalg.eigh(mid)
  size = len(vectors)
  transform = acb_mat([[acb(float(vectors[i, j].real), float(vectors[i, j].imag))
    for j in range(size)] for i in range(size)])
  transformed = transform.conjugate().transpose()*(matrix*transform)
  signs = []
  margins = []
  for i in range(size):
    diagonal = transformed[i, i]
    if not diagonal.imag.contains(0):
      raise RuntimeError('Hermitian diagonal enclosure excludes zero imaginary part.')
    diagonal = diagonal.real
    sign = -1 if diagonal < 0 else (1 if diagonal > 0 else 0)
    off = arb(0)
    for j in range(size):
      if i != j:
        off += transformed[i, j].abs_upper()
    margin = (diagonal.abs_lower()-off).lower()
    signs.append(sign)
    margins.append(margin)
  minimum = min(margins)
  passed = all(s != 0 for s in signs) and all(m > 0 for m in margins)
  return {'pass': passed, 'negative': signs.count(-1), 'positive': signs.count(1),
    'unresolved': signs.count(0), 'dominance_margin': interval(minimum),
    'dominance_margin_float': float(minimum),
    'ordinary_eigen_min_abs': float(np.min(np.abs(np.linalg.eigvalsh(mid))))}


def certify(args):
  cutoff, cells = args.cutoff, args.cells
  ctx.prec = args.bits
  indices = modes(cutoff)
  radius = (arb.pi()/cells).upper()
  if not radius < arb(A).sqrt():
    raise ValueError('Coverage radius is too large.')
  a = ((arb(A).sqrt()-radius)**2).lower()
  b = ((arb(B).sqrt()+radius)**2).upper()
  tau = min((((2*cutoff+1)*arb.pi())**2+arb(1)/4).lower(),
    ((2*arb.pi()*(cutoff+1)-arb(1)/2)**2).lower())
  h = (tau-17*b).lower()
  if not h > 0:
    raise RuntimeError('The omitted Fourier block has no proved positive lower bound.')
  delta = (64*b*b/h).upper()
  rows = []
  moments = {}
  summary = {'status': 'IN_PROGRESS', 'target': [A, B], 'beta': '1/2',
    'cutoff': cutoff, 'dimension': len(indices), 'cells': cells, 'bits': args.bits,
    'radius': interval(radius), 'a_expanded': interval(a), 'b_expanded': interval(b),
    'tail_kinetic_lower': interval(tau), 'tail_positive_lower': interval(h),
    'schur_correction_upper': interval(delta),
    'versions': {'numpy': np.__version__, 'python_flint': flint.__version__},
    'rows': rows}
  out = Path(args.output)
  with out.with_suffix('.csv').open('w') as stream:
    writer = csv.writer(stream, lineterminator='\n')
    writer.writerow(['side', 'cell', 'theta_over_pi_numerator', 'denominator',
      'lower_negative', 'upper_negative', 'lower_margin', 'upper_margin', 'pass', 'seconds'])
    for side, alpha in ALPHAS:
      mass, mid_mass, moment_evidence = mass_balls(alpha, cutoff, args.nodes, args.strip)
      moments[side] = moment_evidence
      write_json(out.with_name(out.stem+'-moments.json'), moments)
      for j in range(cells):
        before = time.monotonic()
        check_budget()
        numerator = -cells+2*j+1
        theta = arb.pi()*numerator/cells
        kinetic = [(2*arb.pi()*n+theta)**2+(2*arb.pi()*m+arb(1)/2)**2 for n, m in indices]
        results = []
        for value, shift in [(a, arb(0)), (b, delta)]:
          matrix = -mass*value
          mid = -mid_mass*float(value)
          for k, kin in enumerate(kinetic):
            matrix[k, k] += kin-shift
            mid[k, k] += float(kin.mid())-float(shift)
          results.append(certified_inertia(matrix, mid))
        low, high = results
        passed = low['pass'] and high['pass'] and low['negative'] == high['negative']
        row = {'side': side, 'cell': j, 'theta_over_pi': [numerator, cells],
          'theta_interval_over_pi': [-cells+2*j, -cells+2*j+2, cells],
          'lower': low, 'upper': high, 'pass': passed, 'seconds': time.monotonic()-before}
        rows.append(row)
        writer.writerow([side, j, numerator, cells, low['negative'], high['negative'],
          low['dominance_margin_float'], high['dominance_margin_float'], passed, row['seconds']])
        stream.flush()
        print(f'{side} {j+1}/{cells}: counts {low["negative"]}/{high["negative"]}, '
          f'margins {low["dominance_margin_float"]:.6g}/{high["dominance_margin_float"]:.6g}, pass={passed}', flush=True)
        summary['resources'] = check_budget()
        write_json(out, summary)
  complete = len(rows) == 2*cells and all(row['pass'] for row in rows)
  summary['status'] = 'COMMON_PROJECTED_GAP_PROVED' if complete else 'CRITERION_NOT_PASSED'
  summary['resources'] = check_budget()
  summary['scope'] = 'Periodic bulk operators only; no half-guide pole exclusion or defect mode count.'
  write_json(out, summary)
  print(json.dumps({'status': summary['status'], 'resources': summary['resources']}), flush=True)


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('mode', choices=['probe', 'certify'])
  parser.add_argument('--output', required=True)
  parser.add_argument('--cutoff', type=int, default=3)
  parser.add_argument('--cells', type=int, default=32)
  parser.add_argument('--nodes', type=int, default=256)
  parser.add_argument('--strip', default='0.2')
  parser.add_argument('--bits', type=int, default=128)
  parser.add_argument('--deadline-utc', help='Optional UTC ISO date and time.')
  parser.add_argument('--storage-root', help='Optional explicit directory for storage monitoring.')
  args = parser.parse_args()
  if not 1 <= args.cutoff <= 5 or not 8 <= args.cells <= 512 or not 64 <= args.nodes <= 512:
    raise ValueError('Configuration exceeds the declared small-run budget.')
  if not 80 <= args.bits <= 512 or not arb(args.strip) > 0:
    raise ValueError('Require 80--512 bits and a strictly positive strip width.')
  configure_budget(args.deadline_utc, args.storage_root)
  if Path(args.output).exists():
    raise FileExistsError('Choose a fresh run filename in the same attempt directory.')
  probe(args) if args.mode == 'probe' else certify(args)


if __name__ == '__main__':
  main()
