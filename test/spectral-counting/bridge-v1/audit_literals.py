#!/usr/bin/env python3
"""Check saved binary-literal and sign witnesses using exact rational arithmetic.

No Arb calls or scientific solver runs are used. Decimal literals are checked
against the midpoints of adjacent IEEE binary64 numbers. Center coefficients
are rational identities; lead coefficients are checked by squaring positive
intervals. Saved inertia signs and geometry-budget inequalities are rechecked.
"""

import argparse
from fractions import Fraction
import json
from pathlib import Path
import struct


def endpoint(item):
  return Fraction(int(item['mantissa']))*Fraction(2)**item['exponent']


def bounds(item):
  lo,hi=endpoint(item['lower']),endpoint(item['upper'])
  if lo>hi:raise ValueError('Reversed interval.')
  return lo,hi


def single(item):
  lo,hi=bounds(item)
  if lo!=hi:raise ValueError('Expected an exact dyadic scalar.')
  return lo


def signs(item,expected,dimension):
  c,d=item['congruence'],item['ldl']
  assert endpoint(c['dominance_margin']['lower'])>0
  counts=[-1 if endpoint(p['upper'])<0 else 1 if endpoint(p['lower'])>0 else 0 for p in d['pivots']]
  assert len(counts)==dimension and all(counts) and counts.count(-1)==expected
  assert c['negative']==d['negative']==expected and c['positive']==d['positive']==dimension-expected
  return dimension


def main():
  parser=argparse.ArgumentParser(description=__doc__)
  parser.add_argument('certificate');parser.add_argument('--output',required=True)
  args=parser.parse_args();out=Path(args.output)
  if out.exists():raise FileExistsError('Use a fresh audit filename.')
  data=json.loads(Path(args.certificate).read_text())
  model=data['model_bridge'];literal_checks={};literal_values={}
  for text,row in model['literals'].items():
    x=Fraction(int(row['numerator']),int(row['denominator']))
    value=float.fromhex(row['hex']);assert Fraction.from_float(value)==x
    bits=struct.unpack('>Q',struct.pack('>d',value))[0]
    previous=Fraction.from_float(struct.unpack('>d',struct.pack('>Q',bits-1))[0])
    following=Fraction.from_float(struct.unpack('>d',struct.pack('>Q',bits+1))[0])
    exact=Fraction(text)
    assert (previous+x)/2<exact<(x+following)/2
    literal_checks[text]={'nearest_binary64_verified':True,
      'signed_difference_numerator':str((x-exact).numerator),
      'signed_difference_denominator':str((x-exact).denominator)}
    literal_values[text]=x
  geometry_checks={};tol=Fraction('1e-13');epsilon=Fraction(data['inclusion_symmetric_difference_area_budget'])
  rb,cb=literal_values['0.2'],literal_values['0.3']
  for name,row in model['geometry'].items():
    assert endpoint(row['orientation_lower']['lower'])>0
    assert endpoint(row['neighbourhood_symmetric_difference_area_upper']['upper'])<epsilon
    assert endpoint(row['literal_symmetric_difference_area_upper']['upper'])<epsilon
    aa,bb=row['binary_x_coefficients'],row['binary_y_coefficients']
    for coefficients in [aa,bb]:
      assert sum(max(abs(v) for v in bounds(z)) for z in coefficients.values())+len(coefficients)*tol<Fraction(1,2)
    if name=='center':
      expected_a={'1':3*rb/2,'4':rb*cb/2,'6':rb*cb/2}
      expected_b={'1':rb,'4':-rb*cb/2,'6':rb*cb/2}
      for actual,expected in [(aa,expected_a),(bb,expected_b)]:
        for k,x in expected.items():
          lo,hi=bounds(actual[k]);assert lo<=x<=hi
    else:
      alpha=literal_values['0.12' if name=='left' else '0.20'];den=1+alpha*alpha/2
      for coord,actual in [('x',aa),('y',bb)]:
        for k,record in actual.items():
          lo,hi=bounds(record)
          factor=Fraction(1) if k=='1' else alpha/2
          if coord=='y' and k=='2':lo,hi=-hi,-lo
          assert 0<lo<=hi and lo*lo*den<=rb*rb*factor*factor<=hi*hi*den
    geometry_checks[name]={'coefficient_formula_verified':True,'orientation_and_area_budget_pass':True,'inside_cell':True}
  for target in ['2.40','2.46']:
    assert abs(literal_values[target]-Fraction(target))<Fraction(data['endpoint_band_radius'])
  lead=data['lead_certificate'];tau=single(lead['tail_kinetic_lower']);h=single(lead['tail_positive_lower'])
  assert 0<h<=tau-17*Fraction('2.60')
  assert single(lead['schur_correction_upper'])>=64*Fraction('2.60')**2/h
  pivot_count=0
  for row in lead['rows']:
    assert endpoint(row['dirichlet_trial_upper']['upper'])<Fraction('2.30')
    pivot_count+=signs(row['inertia'],1,25)
  box=data['box_certificate'];tau=single(box['tail_kinetic_lower'])
  expected={('D','2.40'):6,('D','2.46'):7,('N','2.40'):6,('N','2.46'):7}
  assert {(r['boundary'],r['endpoint']) for r in box['rows']}==set(expected) and len(box['rows'])==4
  for row in box['rows']:
    lo,hi=bounds(row['endpoint_band']);center=Fraction(row['endpoint']);radius=Fraction(data['endpoint_band_radius'])
    assert lo<=center-radius and hi>=center+radius
    assert lo<=literal_values[row['endpoint']]<=hi
    h=single(row['tail_positive_lower']);factor=single(row['covariance_factor_upper'])
    assert 0<h<=tau-17*hi and factor>=hi*hi/h
    for side in ['upper','lower']:pivot_count+=signs(row[side],expected[row['boundary'],row['endpoint']],row['dimension'])
  result={'status':'BINARY_LITERALS_COEFFICIENTS_AND_ROBUST_SIGNS_VERIFIED',
    'source':Path(args.certificate).name,'literal_checks':literal_checks,'geometry_checks':geometry_checks,
    'total_ldl_pivots_checked':pivot_count,'robust_endpoint_counts':[6,7,6,7],
    'scope':'Exact rational audit; no claim of bitwise MATLAB replay or old mesh certification.'}
  out.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))


if __name__=='__main__':main()
