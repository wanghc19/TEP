#!/usr/bin/env python3
"""Finite reuse qualification of historical I10.1 groups (design-10-2a section 3).

Purpose: check that the historical g12 (I10.1 enrich-v1 smoke-03) and g48
  (I10.1 enrich-v1 run-02) records match the I10.2 contract, extract the final
  P2/P3/P4 wall-trace coefficients from the uncompressed recovery MAT files,
  sample them on y_j = -1/2 + j/200 by a port of LOCAL_wall_eval /
  LOCAL_transfer, validate that port against the recorded I10.1 same-mode
  correlations, and write reuse.json plus wall-samples-<group>.json.
Based on: test/i10/enrich-v1/summarize_enrich.py (record reading) and
  enrich_i101.m::LOCAL_wall_eval / LOCAL_transfer (wall interpolation).
Main changes: new. Standard library only; historical files are read only.
  Execution never depends on Markdown, Git or this script's output being
  present; MATLAB never reads any of these records.
Usage: python3 -I reuse_refine.py --output output/attempt-1/reuse-01
         --new-config output/attempt-1/<new run>/config.json
"""
import argparse
import cmath
import json
import math
from pathlib import Path
import re
import struct
import time

HERE = Path(__file__).resolve().parent
ENRICH = HERE.parent/'enrich-v1'
HISTORY = {
  'g12': dict(run=ENRICH/'output'/'attempt-1'/'smoke-03', label='HISTORICAL_SMOKE_SOURCE',
    note='I10.1 smoke-03 (s12-n80); accepted for I10.2 by the section-3 checks, '
         'kept with its historical smoke label'),
  'g48': dict(run=ENRICH/'output'/'attempt-1'/'run-02', label='HISTORICAL_FORMAL_SOURCE',
    note='I10.1 D2 formal run-02 (s48-n320), R2 PASS WITH CONDITIONS'),
}
SN = {'g12': (12, 80), 'g24': (24, 160), 'g48': (48, 320)}
TRACE_POINTS = 201

# ---------------------------------------------------------------------------
# Minimal MAT level-5 reader (uncompressed -v6 files): top-level numeric arrays.
MI = {1: ('b', 1), 2: ('B', 1), 3: ('h', 2), 4: ('H', 2), 5: ('i', 4), 6: ('I', 4),
      7: ('f', 4), 9: ('d', 8), 12: ('q', 8), 13: ('Q', 8)}


def _tag(buf, pos, endian):
  first, second = struct.unpack_from(endian + 'II', buf, pos)
  if first >> 16:                       # small data element: 4-byte payload
    return first & 0xFFFF, first >> 16, pos + 4, pos + 8
  return first, second, pos + 8, pos + 8 + ((second + 7)//8)*8


def _numbers(buf, start, mtype, nbytes, endian):
  code, size = MI[mtype]
  return list(struct.unpack_from(endian + code*(nbytes//size), buf, start))


def mat_read(path, names):
  """Return {name: list of (complex) numbers, column-major} for top-level
  numeric arrays in names; other variables are skipped without parsing."""
  buf = Path(path).read_bytes()
  endian = '<' if buf[126:128] == b'IM' else '>'
  pos, out = 128, {}
  while pos < len(buf) and len(out) < len(names):
    mtype, nbytes, start, nxt = _tag(buf, pos, endian)
    if mtype == 15:
      raise ValueError('compressed MAT element (expected -v6): ' + str(path))
    if mtype == 14:
      p = start
      t, n, s, p = _tag(buf, p, endian)                          # array flags
      flags = struct.unpack_from(endian + 'I', buf, s)[0]
      t, n, s, p = _tag(buf, p, endian)                          # dimensions
      t, n, s, p = _tag(buf, p, endian)                          # name
      name = buf[s:s+n].decode('ascii')
      cls, is_complex = flags & 0xFF, bool(flags & 0x0800)
      if name in names and cls == 6:
        t, n, s, p = _tag(buf, p, endian)
        real = _numbers(buf, s, t, n, endian)
        if is_complex:
          t, n, s, p = _tag(buf, p, endian)
          imag = _numbers(buf, s, t, n, endian)
          out[name] = [complex(a, b) for a, b in zip(real, imag)]
        else:
          out[name] = [complex(a, 0) for a in real]
    pos = nxt
  return out


# ---------------------------------------------------------------------------
# Port of enrich_i101.m::LOCAL_wall_eval / LOCAL_transfer (P_p wall traces on
# s*p uniform nodes, quasi-periodic closure g(n+1) = exp(i beta) g(1)).
def lagrange_1d(p, t):
  nodes = [j/p for j in range(p + 1)]
  values = []
  for j in range(p + 1):
    v = 1.0
    for m in range(p + 1):
      if m != j:
        v *= (t - nodes[m])/(nodes[j] - nodes[m])
    values.append(v)
  return values


def wall_eval(g, s, p, beta, y):
  n = s*p
  assert len(g) == n, 'wall trace length mismatch'
  ext = list(g) + [cmath.exp(1j*beta)*g[0]]
  out = []
  for yq in y:
    m = max(min(math.floor((yq + 0.5)*s), s - 1), 0)
    t = (yq + 0.5)*s - m
    B = lagrange_1d(p, t)
    out.append(sum(ext[m*p + j]*B[j] for j in range(p + 1)))
  return out


def transfer(g, s, p, beta, y):
  n = len(g)//2
  return wall_eval(g[:n], s, p, beta, y) + wall_eval(g[n:], s, p, beta, y)


def correlation(a, b):
  dot = sum(x.conjugate()*y for x, y in zip(a, b))
  na = math.sqrt(sum(abs(x)**2 for x in a))
  nb = math.sqrt(sum(abs(x)**2 for x in b))
  return abs(dot)/(na*nb) if na > 0 and nb > 0 else math.nan


def common_y():
  return [-0.5 + j/(TRACE_POINTS - 1) for j in range(TRACE_POINTS)]


# ---------------------------------------------------------------------------
# Function-level source comparison (error identifiers normalized).
def functions(text):
  text = re.sub(r"'i(101|102|95b):", "'ID:", text)
  parts = re.split(r'(?m)^function ', text)
  table = {}
  for part in parts[1:]:
    head = part.split('\n', 1)[0]
    match = re.search(r'(LOCAL_\w+|enrich_i101|refine_i102)\s*\(', head)
    key = match.group(1) if match else head
    if key in ('enrich_i101', 'refine_i102'):
      key = 'ENTRY'
    lines = part.rstrip('\n').split('\n')
    while lines and (not lines[-1].strip() or lines[-1].lstrip().startswith('%')):
      lines.pop()                       # trailing section markers belong to the next group
    table[key] = '\n'.join(lines)
  return table


def source_diff(old_path, new_path):
  old, new = functions(old_path.read_text()), functions(new_path.read_text())
  return dict(
    changed=sorted(k for k in old if k in new and old[k] != new[k]),
    added=sorted(k for k in new if k not in old),
    removed=sorted(k for k in old if k not in new),
    unchanged_count=sum(1 for k in old if k in new and old[k] == new[k]))


# ---------------------------------------------------------------------------
SCIENTIFIC_FIELDS = ['model', 'k0', 'mu0', 'window', 'orders', 'rules', 'epsilon', 'q',
  'extra_trigger_factor', 'ratio_floor_factor', 'nested_tol', 'edge_tol', 'location', 'gates',
  'root', 'same_mode', 'stein', 'derivative', 'delivery', 'solver']


def qualify(group, info, new_config):
  run = info['run']
  t0 = time.monotonic()
  result = json.loads((run/'result.json').read_text())
  config = json.loads((run/'config.json').read_text())
  status = json.loads((run/'status.json').read_text())
  timing = json.loads((run/'timing.json').read_text())
  checks = {}
  s, n = SN[group]
  checks['mesh_group'] = config['mesh'] == {'subdivisions': s, 'interface_segments': n}
  mesh_rules = {k: v for k, v in new_config['mesh_rules'].items()
    if k not in ('repair_seconds', 'flip')}
  checks['mesh_rules_equal'] = config['mesh_rules'] == mesh_rules
  differing = [f for f in SCIENTIFIC_FIELDS if config.get(f) != new_config.get(f)]
  checks['scientific_config_equal'] = not differing
  checks['threads'] = config['resources']['threads'] == new_config['resources']['threads']
  checks['mode_not_sizing'] = config['mode'] in ('formal', 'smoke') and 'sizing' not in result
  bands = result.get('bands', {})
  checks['band_location_complete'] = all(bands.get(r, {}).get('total_failures') == 0
    for r in ('primary', 'check'))
  checks['no_tolerance_owner'] = all(bands.get(r, {}).get('total_tolerance_owner') == 0
    for r in ('primary', 'check'))
  checks['geometry_pass'] = result['geometry'].get('status') == 'PASS'
  checks['flip_not_needed'] = 'bad elements' in result['geometry'].get('deletion_outcome', '') \
    and result['geometry'].get('bad_elements') == 0
  checks['edge_traces_pass'] = result['edge_traces'].get('pass') is True
  names = sorted(c['name'] for c in result['chains'])
  checks['six_chains'] = names == sorted('P%d-%s' % (p, r) for p in (2, 3, 4)
    for r in ('primary', 'check'))
  checks['all_chains_root_found'] = all(c['status'] == 'ROOT_FOUND' for c in result['chains'])
  checks['three_layers_qualified'] = [L['p'] for L in result['layers']] == [2, 3, 4] and \
    all(L['qualified'] for L in result['layers'])
  checks['true_material_band_mass'] = all(
    L['matrix_checks']['check']['pass'] for L in result['layers'])
  preds = result['predictions']
  preds = preds if isinstance(preds, list) else [preds]
  checks['prediction_saved'] = any(p['status'] == 'PREDICTION_SAVED' for p in preds)
  checks['estimate_delivered'] = result['final_status'] == 'CONDITIONAL_ESTIMATE_DELIVERED'
  files = ['evidence.mat', 'iterations.csv', 'resources.csv', 'timing.json', 'run.log',
    'prediction-P3-check.mat'] + ['recovery-P%d-check-%s.mat' % (p, c) for p in (2, 3, 4)
    for c in ('center', 'left', 'right')] + ['layer-P%d-check-matrices.mat' % p for p in (2, 3, 4)]
  missing = [f for f in files if not (run/f).exists()]
  checks['raw_files_present'] = not missing
  # final-rule wall traces from the recovery MAT files, sampled on the common y
  y = common_y()
  beta = config['model']['beta']
  samples, coefficients, port = {}, {}, {}
  for L in result['layers']:
    p, rule = L['p'], L['final_rule']
    data = mat_read(run/('recovery-P%d-%s-center.mat' % (p, rule)), {'g'})
    g = data['g']
    checks['wall_length_P%d' % p] = len(g) == 2*s*p
    coefficients[p] = g
    samples[p] = transfer(g, s, p, beta, y)
  for pair in result['same_mode']['pairs']:
    a, b = pair['from'], pair['to']
    value = correlation(samples[a], samples[b])
    port['P%d-P%d' % (a, b)] = dict(recorded=pair['wall_correlation'], python_port=value,
      difference=value - pair['wall_correlation'])
  checks['wall_port_reproduces_recorded_correlations'] = all(
    abs(v['difference']) <= 1e-12 for v in port.values())
  seconds = time.monotonic() - t0
  record = dict(group=group, label=info['label'], note=info['note'], source=str(run),
    accepted=all(checks.values()), checks=checks, missing_files=missing,
    differing_scientific_fields=differing, wall_port_validation=port,
    environment=result.get('environment'), historical_mode=config['mode'],
    historical_cost=dict(launcher_wall_seconds=status['wall_seconds'],
      peak_tree_rss_bytes=status['peak_tree_rss_bytes'],
      matlab_function_seconds=timing.get('matlab_function_seconds'),
      launched_utc=status['launched_utc'], finished_utc=status['finished_utc']),
    read_and_check_seconds=seconds)
  wall = dict(group=group, source=str(run), y=y, layers=[dict(p=p, final_rule=next(
    L['final_rule'] for L in result['layers'] if L['p'] == p), s=s, wall_dofs=s*p,
    samples_re=[v.real for v in samples[p]], samples_im=[v.imag for v in samples[p]],
    coefficients_re=[v.real for v in coefficients[p]],
    coefficients_im=[v.imag for v in coefficients[p]]) for p in sorted(samples)])
  return record, wall


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--new-config', required=True,
    help='config.json written by a refine_i102 run (current contract values)')
  args = parser.parse_args()
  out = Path(args.output).resolve()
  out.mkdir(parents=True, exist_ok=False)
  t0 = time.monotonic()
  new_config = json.loads(Path(args.new_config).read_text())
  snapshots = {g: info['run']/'source' for g, info in HISTORY.items()}
  same_snapshots = all((snapshots['g12']/f).read_bytes() == (snapshots['g48']/f).read_bytes()
    for f in ('enrich_i101.m', 'enrich_i101_config.m'))
  diff = source_diff(snapshots['g48']/'enrich_i101.m', HERE/'refine_i102.m')
  record = dict(schema='I102_REUSE_V1', contract='design-10-2a D1 section 3',
    new_config_source=str(Path(args.new_config).resolve()),
    historical_snapshots_identical=same_snapshots, kernel_function_diff=diff,
    kernel_diff_note=('changed/added functions relative to the historical kernel; '
      'chain, assembly, location, DtN, root, prediction, recovery and estimate '
      'functions must be unchanged for reuse'), groups={})
  for group, info in HISTORY.items():
    item, wall = qualify(group, info, new_config)
    record['groups'][group] = item
    (out/('wall-samples-%s.json' % group)).write_text(json.dumps(wall) + '\n')
    print('%s accepted=%s port=%s' % (group, item['accepted'],
      {k: '%.2e' % v['difference'] for k, v in item['wall_port_validation'].items()}))
  record['total_seconds'] = time.monotonic() - t0
  (out/'reuse.json').write_text(json.dumps(record, indent=2) + '\n')
  print(json.dumps(dict(changed=diff['changed'], added=diff['added'], removed=diff['removed'])))


if __name__ == '__main__':
  main()
