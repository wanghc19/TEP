"""Replay decimal printing of an already computed defect product.

Pass the package, an output JSON file, and one or more verifier directories
whose traces stopped at terms_upper. The original package routine is called
with the saved five group bounds at the original precisions.
"""
import argparse
from fractions import Fraction
import json
from pathlib import Path
import sys


if __name__ == '__main__':
  p = argparse.ArgumentParser(description=__doc__)
  p.add_argument('--package', type=Path, required=True)
  p.add_argument('--output', type=Path, required=True)
  p.add_argument('runs', type=Path, nargs='+')
  a = p.parse_args()
  sys.path.insert(0, str(a.package / 'src/python/enclosure'))
  from assemble import PARAMS, directed
  from flint import arb, ctx
  report = []
  for run in a.runs:
    log = (run / '06-enclosure/run.log').read_text()
    assert 'terms_upper=[directed(v,30,True) for v in terms]' in log and 'NoneType' in log
    groups = json.loads((run / '03-residuals/groups.json').read_text(), parse_float=str)
    for bits in (192, 160):
      ctx.prec = bits
      for (group, _, _, _, c), e in zip(PARAMS, groups['epsilon_upper'], strict=True):
        term = arb(c)*arb(e)
        try:
          directed(term, 30, True)
        except TypeError as error:
          scaled = term.upper()*10**30
          report.append(dict(run=str(run), bits=bits, group=group, constant=c, epsilon=e,
                             exact_scaled_term=str(Fraction(c)*Fraction(e)*10**30),
                             possible_ceiling=str(scaled.ceil()), unique=str(scaled.ceil().unique_fmpz()),
                             error=str(error)))
          break
      else:
        continue
      break
    else:
      raise ValueError(f'Could not reproduce the conversion failure for {run}')
  a.output.write_text(json.dumps(report, indent=2) + '\n')
