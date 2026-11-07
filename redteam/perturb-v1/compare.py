"""Compare one completed verifier run with the published example 1 interval.

Inputs are a verifier run, its field data, and the reference results file.
Output is a JSON record on standard output. All interval comparisons and the
candidate displacement use exact decimal endpoints.
"""
import argparse
from decimal import Decimal, Inexact, localcontext
import json
from pathlib import Path
import struct


def load(path):
  return json.loads(path.read_text(), parse_float=str)


def compare(run, data, reference):
  ref = load(reference)['assembly']
  x, y = map(Decimal, ref['k_interval'])
  kh = load(data / 'fixed-input.json')['k']['real'][0]
  k = Decimal.from_float(struct.unpack('>d', bytes.fromhex(kh))[0])
  with localcontext() as ctx:
    ctx.prec = 160
    ctx.traps[Inexact] = True
    mu, lower, upper = k*k, x*x, y*y
    delta = max(Decimal(0), lower - mu, mu - upper)
  end = load(run / 'end-to-end.json')
  row = dict(k_hex=kh, mu=str(mu), reference_mu_from_k=[str(lower), str(upper)],
             delta=str(delta), seconds=end['wall_seconds'],
             peak_gib=end['monitor']['peak_process_tree_rss_gib'])
  if end['monitor']['reason'] != 'completed':
    raise RuntimeError(end['monitor']['reason'])
  if (run / 'failure.json').exists():
    row.update(stop=load(run / 'failure.json')['error'], verdict='verifier stopped')
    return row
  result = load(run / 'result.json')
  assert end['monitor']['returncode'] == 0 and result['status'] == 'PASS' and all(result['checks'].values())
  assembly = result['assembly']
  a, b = map(Decimal, assembly['k_interval'])
  lo, hi = map(Decimal, assembly['mu_interval'])
  assert a <= k <= b and lo <= mu <= hi
  inside = Decimal('1.7424') < lo <= hi < Decimal('5.6169')
  if a <= x and y <= b:
    verdict = 'contains reference'
  elif b < x or a > y:
    verdict = 'disjoint'
  else:
    verdict = 'partial overlap'
  with localcontext() as ctx:
    ctx.prec = 45
    ratio = str(Decimal(assembly['R_upper']) / delta) if delta else None
  row.update(k_interval=assembly['k_interval'], mu_interval=assembly['mu_interval'],
             Q=assembly['Q_upper'], U=assembly['U_used'], mass_readback=assembly['U_certificate_readback'],
             R=assembly['R_upper'], R_over_delta=ratio, inside_isolation_window=inside, verdict=verdict)
  return row


if __name__ == '__main__':
  p = argparse.ArgumentParser(description=__doc__)
  for arg in ['run', 'data', 'reference']:
    p.add_argument('--' + arg, required=True, type=Path)
  args = p.parse_args()
  print(json.dumps(compare(args.run, args.data, args.reference), indent=2))
