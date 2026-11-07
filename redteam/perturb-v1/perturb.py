"""Write one perturbed example and check every binary64 word on zero input.

Pass canonical and new output directories, a signed relative shift, or a
coefficient group, noise amplitude and seed. The new directory contains the
six package files and a record of the applied change.
"""
import argparse
from collections import Counter
from fractions import Fraction
import json
import math
from pathlib import Path
import random
import re
import struct


def number(word):
  return struct.unpack('>d', bytes.fromhex(word))[0]


def word(value):
  return struct.pack('>d', value).hex()


def vary(array, epsilon, rng):
  """Multiply each complex entry by 1 + epsilon times a complex normal."""
  scale = epsilon / math.sqrt(2)
  for i, (x, y) in enumerate(zip(array['real'], array['imag'], strict=True)):
    value = complex(number(x), number(y))
    factor = complex(1 + scale * rng.gauss(0, 1), scale * rng.gauss(0, 1))
    value *= factor
    array['real'][i], array['imag'][i] = word(value.real), word(value.imag)


def compare(a, b, counts):
  if isinstance(a, dict):
    assert a.keys() == b.keys()
    for key in a:
      compare(a[key], b[key], counts)
  elif isinstance(a, list):
    assert len(a) == len(b)
    for x, y in zip(a, b):
      compare(x, y, counts)
  elif isinstance(a, str) and re.fullmatch('[0-9a-f]{16}', a):
    assert struct.pack('>d', number(a)) == struct.pack('>d', number(b))
    counts['identical_binary64_words'] += 1
  else:
    assert type(a) is type(b) and a == b


def main():
  p = argparse.ArgumentParser(description=__doc__)
  p.add_argument('--source', type=Path, required=True)
  p.add_argument('--output', type=Path, required=True)
  p.add_argument('--shift', type=Fraction, default=Fraction(0))
  p.add_argument('--group', choices=['density', 'sources'])
  p.add_argument('--epsilon', type=float, default=0)
  p.add_argument('--seed', type=int)
  args = p.parse_args()
  if (args.epsilon and not args.group) or (args.group and args.shift) or (args.group and args.seed is None):
    p.error('Supply either a shift, or a group and a seed.')
  args.output.mkdir(parents=True, exist_ok=False)
  files = ['fixed-input', 'coefficients', 'model', 'band-inputs', 'disks-input', 'manifest']
  data = {s: json.loads((args.source / (s + '.json')).read_bytes()) for s in files}
  fixed = data['fixed-input']
  old = fixed['k']['real'][0]
  assert data['model']['k0']['binary64'] == old
  new = word(float(Fraction.from_float(number(old)) * (1 + args.shift)))
  fixed['k']['real'][0] = new
  data['model']['k0']['binary64'] = new
  rng = random.Random(args.seed)
  if args.epsilon and args.group == 'density':
    for piece in fixed['pieces']:
      for key in ['tau_coeff', 'zeta_coeff']:
        vary(piece[key], args.epsilon, rng)
  if args.epsilon and args.group == 'sources':
    # All four copies describe the same 320 construction strengths.
    for piece in fixed['pieces']:
      assert piece['proxy_equal'] and piece['proxy_c'] == fixed['proxy_c']
    vary(fixed['proxy_c'], args.epsilon, rng)
    for piece in fixed['pieces']:
      piece['proxy_c'] = fixed['proxy_c']
    for key in ['B_center', 'B_negative', 'B_positive']:
      vary(data['coefficients'][key], args.epsilon, rng)
  if args.shift or args.epsilon:
    data['manifest']['source'] = 'Perturbed example 1. See perturbation.json.'
  counts = Counter()
  for name, value in data.items():
    dest = args.output / (name + '.json')
    dest.write_text(json.dumps(value, separators=(',', ':')) + '\n')
    if not (args.shift or args.epsilon):
      compare(json.loads((args.source / dest.name).read_bytes()), json.loads(dest.read_bytes()), counts)
  record = dict(original=old, candidate=new, shift=str(args.shift), group=args.group,
                epsilon=args.epsilon, seed=args.seed, **counts)
  (args.output / 'perturbation.json').write_text(json.dumps(record, indent=2) + '\n')
  print(json.dumps(record))


if __name__ == '__main__':
  main()
