"""Evaluate the published radius formula from a completed residual stage.

Inputs are the release's enclosure source, a run, its data, and its exact
comparison record. Output is rational arithmetic for interpreting a stop or
cross-checking an issued radius. This calculation issues no interval.
"""
import argparse
import ast
from decimal import Decimal, localcontext
from fractions import Fraction
import json
from pathlib import Path
import struct


def decimal_string(value):
  with localcontext() as ctx:
    ctx.prec = 65
    return str(Decimal(value.numerator) / Decimal(value.denominator))


def trace_margins(settings, mu):
  """Compare the three candidate extrema in trace_constants.trace as rationals."""
  result = {}
  for name, delta, eta, curvature, cap in settings:
    d, e, curvature, cap = map(Fraction, [delta, eta, curvature, cap])
    h = d*curvature
    tau = d/6 + d*h*h/(40*(1-h*h))
    a = (1+e)/(2*d)
    d1 = (1+1/e)*tau
    b, c = a+d1, 17*d1
    endpoint = Fraction(1, 68)
    stationary = (2*a-b*mu)/(2*c*mu-b)
    def quotient(t):
      return (a+b*t+c*t*t)/(t+mu)**2
    values = [quotient(endpoint), c]
    if stationary > endpoint:
      values.append(quotient(stationary))
    result[name] = decimal_string(cap*cap - max(values))
  return result


def components(package, run, data, comparison):
  module = ast.parse((package / 'src/python/enclosure/assemble.py').read_text())
  assignment = next(node for node in module.body if isinstance(node, ast.Assign)
                    and any(isinstance(t, ast.Name) and t.id == 'PARAMS' for t in node.targets))
  settings = ast.literal_eval(assignment.value)
  constants = [Fraction(row[4]) for row in settings]
  with (run / '03-residuals/groups.json').open() as stream:
    eps = json.load(stream, parse_float=str)['epsilon_upper']
  fixed = json.loads((data / 'fixed-input.json').read_text())
  reference = json.loads((package / 'reference/ex1/results.json').read_text())['assembly']
  k = Fraction.from_float(struct.unpack('>d', bytes.fromhex(fixed['k']['real'][0]))[0])
  terms = [c*Fraction(e) for c, e in zip(constants, eps, strict=True)]
  q = sum(terms)
  u = Fraction(reference['U_used'])
  assert q < u
  radius = 2*k*k*q/(u-q)
  delta = Fraction(comparison['delta'])
  result = dict(epsilon_decimal=eps, Q_formula=decimal_string(q), U_assumed=str(Decimal(reference['U_used'])),
                R_fraction=str(radius), R_formula=decimal_string(radius),
                R_over_delta_formula=decimal_string(radius/delta) if delta else None,
                R_over_canonical=decimal_string(radius/Fraction(reference['R_upper'])))
  result['published_C_squared_minus_required_C_squared'] = trace_margins(settings, k*k)
  disks = run / '05-mass/disks.json'
  if disks.is_file():
    result['disk_mass_readback'] = json.loads(disks.read_text())['U_lower']
  if 'R' in comparison:
    assert radius <= Fraction(comparison['R']) <= radius + Fraction(1,10**25)
  return result


if __name__ == '__main__':
  p = argparse.ArgumentParser(description=__doc__)
  for key in ['package', 'run', 'data', 'comparison']:
    p.add_argument('--' + key, type=Path, required=True)
  a=p.parse_args()
  print(json.dumps(components(a.package, a.run, a.data, json.loads(a.comparison.read_text())), indent=2))
