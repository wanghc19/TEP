#!/usr/bin/env python3
"""Summarize one I10.1 enrichment run (design-10-1a D1 step 8); stdlib only.

Purpose: after every scientific MATLAB output is frozen, add the external
  comparisons and accounting that the MATLAB kernel must not contain:
  (1) absolute and signed differences to the historical BIE reference for the
      original candidate k0, the P3 prediction kN and the P2/P3/P4 roots;
  (2) the recorded mesh identity against the I9.5b attempt-1/run-02 fine level
      (historical result.json, read here only, never by MATLAB);
  (3) a cost split: cold delivery chain vs research verification/diagnostics
      (an accounting estimate from the MATLAB ledger and per-chain timers).
The BIE difference is an external reference comparison only; its ratio to a
conditional radius is not named an effectivity. Nothing here changes a
MATLAB status or upgrades a conditional estimate.
Based on: test/i9/fem-dtn-v1/summarize_dtn.py (BIE constant, comparison layout).
Outputs: summary.json and summary.md in the run directory.
"""
import argparse
import csv
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
K_BIE = 1.5584378941820909          # historical BIE reference (summary layer only)
I95B_RESULT = HERE.parent.parent/'i9'/'fem-dtn-v1'/'output'/'attempt-1'/'run-02'/'result.json'
I95B_CHAIN = 'fine-q12'


def load(path):
  try:
    return json.loads(Path(path).read_text())
  except (OSError, ValueError):
    return None


def as_list(value):
  """MATLAB jsonencode writes a 1x1 struct array as an object."""
  if value is None:
    return []
  if isinstance(value, dict):
    return [value]
  return list(value)


def num(value):
  if isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value):
    return float(value)
  return None


def bie_row(label, k, source, qualified=True):
  k = num(k)
  row = dict(label=label, source=source, k=k, qualified=qualified, k_bie=K_BIE,
    abs_k_difference=None, signed_k_difference=None, abs_mu_difference=None)
  if k is not None:
    row.update(abs_k_difference=abs(k-K_BIE), signed_k_difference=k-K_BIE,
      abs_mu_difference=abs(k*k-K_BIE*K_BIE))
  return row


def mesh_identity(result):
  old = load(I95B_RESULT)
  record = dict(reference=str(I95B_RESULT.relative_to(HERE.parent.parent.parent)),
    reference_chain=I95B_CHAIN, status='UNAVAILABLE')
  if old is None or result is None:
    record['reason'] = 'historical result.json or current result.json unreadable'
    return record
  chain = next((c for c in as_list(old.get('chains')) if c.get('name') == I95B_CHAIN), None)
  spaces = as_list(result.get('spaces'))
  p2 = next((s for s in spaces if s.get('p') == 2), None)
  ident = result.get('mesh_identity') or {}
  if chain is None or p2 is None:
    record['reason'] = 'reference chain or current P2 space missing'
    return record
  dims = chain.get('dimensions') or {}
  checks = dict(
    free_dofs=dict(current=p2.get('free_dofs'), reference=dims.get('free_dofs')),
    interior_dofs=dict(current=p2.get('interior_dofs'), reference=dims.get('interior_dofs')),
    template_p2_nodes=dict(current=p2.get('dofs'), reference=dims.get('p2_nodes')),
    wall_dofs=dict(current=p2.get('wall_dofs'), reference=dims.get('wall_dofs')),
    mesh_key=dict(current='s%d-n%d' % (48, 320) if result.get('mode') != 'smoke' else 'smoke',
      reference=chain.get('mesh_key')),
    joint_counts=dict(current=[ident.get('triangles'), ident.get('p2_nodes')],
      reference_config=[ident.get('expected_triangles'), ident.get('expected_p2_nodes')]))
  for item in checks.values():
    ref = item.get('reference', item.get('reference_config'))
    item['match'] = item['current'] == ref
  record.update(checks=checks, status='MATCH' if all(v['match'] for v in checks.values())
    else 'MISMATCH', note='count-level identity of the deterministic rebuild; recorded, '
    'never used as an execution gate')
  return record


def cost_split(result, timing, status_rows):
  """Accounting estimate (design 7/9): cold delivery chain = mesh + all dof maps
  + band location of the P4 final rule + P4 final-rule assembly + P4 final root
  chain + P4 recovery; everything else attributed in the ledger is research
  verification/diagnostics (primary/extra rules, P2/P3 layers, prediction, Stein,
  derivative, nested/identity checks, estimate, figures, save)."""
  ledger = (timing or {}).get('categories') or {}
  attributed = num((timing or {}).get('attributed_seconds'))
  total = num((timing or {}).get('matlab_function_seconds'))
  layers = as_list((result or {}).get('layers'))
  chains = as_list((result or {}).get('chains'))
  bands = (result or {}).get('bands') or {}
  predictions = as_list((result or {}).get('predictions'))
  record = dict(kind='ACCOUNTING_ESTIMATE', ledger=ledger, attributed_seconds=attributed,
    matlab_function_seconds=total, status='UNAVAILABLE')
  p4 = next((L for L in layers if L.get('p') == 4), None)
  per_chain = [dict(name=c.get('name'), status=c.get('status'), root_seconds=num(c.get('root_seconds')),
    frequency_count=c.get('frequency_count'), cache_hits=c.get('cache_hits'),
    slowest_eval_seconds=num(c.get('slowest_eval_seconds'))) for c in chains]
  per_assembly = []
  for L in layers:
    for rule, ch in ((L.get('matrix_checks') or {}).items()):
      if isinstance(ch, dict):
        per_assembly.append(dict(p=L.get('p'), rule=rule, seconds=sum(num(ch.get(k)) or 0 for k in
          ('seconds_volume', 'seconds_band', 'seconds_checks'))))
  record.update(per_chain=per_chain, per_assembly=per_assembly,
    per_location={r: num(b.get('seconds')) for r, b in bands.items() if isinstance(b, dict)},
    per_prediction=[dict(label=p.get('label'), seconds=num(p.get('seconds')),
      derivative_seconds=num(p.get('derivative_seconds'))) for p in predictions],
    per_recovery=[dict(p=L.get('p'), seconds=num(L.get('recovery_seconds'))) for L in layers])
  if p4 is None or not p4.get('final_rule') or attributed is None:
    record['reason'] = 'P4 layer or final rule unavailable; only the raw ledger is reported'
    return record
  rule = p4['final_rule']
  chain = next((c for c in chains if c.get('name') == 'P4-%s' % rule), {})
  assembly = next((a['seconds'] for a in per_assembly if a['p'] == 4 and a['rule'] == rule), None)
  location = record['per_location'].get(rule)
  parts = dict(mesh=num(ledger.get('mesh')), dof_maps_all_orders=num(ledger.get('dofs')),
    location_final_rule=location, assembly_P4_final_rule=assembly,
    root_P4_final_chain=num(chain.get('root_seconds')),
    recovery_P4=num(p4.get('recovery_seconds')))
  missing = [k for k, v in parts.items() if v is None]
  cold = sum(v for v in parts.values() if v is not None)
  record.update(status='OK' if not missing else 'PARTIAL', missing_parts=missing,
    cold_delivery_parts=parts, cold_delivery_seconds=cold,
    verification_diagnostic_seconds=attributed-cold,
    note='cold chain counts all three dof maps (upper bound); a P4 chain started without '
    'P2/P3 would need its own bracket search, so this is an estimate, not a measurement')
  old = load(I95B_RESULT)
  if old:
    q12 = next((c for c in as_list(old.get('chains')) if c.get('name') == I95B_CHAIN), {})
    record['i95b_reference_cost'] = dict(fine_q12_root_seconds=num(q12.get('root_seconds')),
      matlab_function_seconds=num((old.get('timing') or {}).get('matlab_function_seconds')),
      note='old candidate cost (different task: no enrichment or error estimate); '
      'not a speed-up comparison')
  if status_rows:
    record['tree_rss_peak_bytes_during_matlab'] = max(r for _, r in status_rows)
  return record


def resources(output):
  rows = []
  try:
    with (output/'resources.csv').open() as handle:
      for row in csv.DictReader(handle):
        rows.append((row['child'], int(row['tree_rss_bytes'])))
  except (OSError, ValueError, KeyError):
    pass
  return [r for r in rows if r[0] == 'matlab']


def fmt(value, spec='.3e'):
  return '—' if value is None else format(value, spec)


def summarize(output):
  result = load(output/'result.json')
  partial = load(output/'partial-result.json')
  failure = load(output/'failure.json')
  timing = load(output/'timing.json') or ((failure or {}).get('timing'))
  source = result if result is not None else (partial or {})
  estimate = (result or {}).get('estimate') or {}
  layers = as_list(source.get('layers'))
  chains = as_list(source.get('chains'))
  predictions = as_list(source.get('predictions'))
  config = load(output/'config.json') or {}
  k0 = num(config.get('k0'))
  bie = [bie_row('original k0', k0, 'config (I9.5b candidate)')]
  pred = next((p for p in predictions if p.get('label') == estimate.get('prediction_label')), None)
  if pred is None and predictions:
    pred = predictions[0]
  bie.append(bie_row('prediction kN', (pred or {}).get('k_N'),
    'prediction-P3-%s' % (pred or {}).get('label'), bool(pred)))
  for L in layers:
    bie.append(bie_row('P%d root (%s)' % (L.get('p'), L.get('final_rule')), L.get('k'),
      'layer final rule', bool(L.get('qualified'))))
  for c in chains:
    bie.append(bie_row('chain %s' % c.get('name'), c.get('k'), 'root chain',
      bool(c.get('qualified'))))
  final = next((L for L in layers if L.get('p') == 4), None)
  radii = {}
  for key in ('B4', 'R0', 'RN'):
    value = num(estimate.get(key))
    radii[key] = value
  final_k = num((final or {}).get('k'))
  external = dict(final_P4_abs_mu_difference=abs(final_k**2-K_BIE**2) if final_k else None,
    note='external reference difference; ratios to B4/R0/RN are not effectivities')
  if final_k and radii.get('R0'):
    external['abs_mu_difference_over_R0'] = external['final_P4_abs_mu_difference']/radii['R0']
  status_rows = resources(output)
  summary = dict(schema='I101_SUMMARY_V1', run=output.name,
    matlab_final_status=(result or {}).get('final_status') or (failure or {}).get('status'),
    matlab_final_reason=(result or {}).get('final_reason') or (failure or {}).get('message'),
    failure_stage=(failure or {}).get('stage'), estimate_label=estimate.get('label'),
    S_verified=estimate.get('S_verified', False), E_certified=estimate.get('E_certified', False),
    bie=bie, external=external, mesh_identity=mesh_identity(result or partial),
    cost=cost_split(result, timing, status_rows))
  (output/'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=True) + '\n')
  lines = ['# I10.1 run summary: %s' % output.name, '',
    '- MATLAB final status: `%s`' % summary['matlab_final_status'],
    '- Reason: %s' % summary['matlab_final_reason'],
    '- Estimate label: `%s` (S_verified = %s, E_certified = %s)' % (
      summary['estimate_label'], summary['S_verified'], summary['E_certified']),
    '- Mesh identity vs I9.5b run-02 %s: `%s`' % (I95B_CHAIN, summary['mesh_identity']['status']),
    '', '| item | k | qualified | k - k_BIE | abs mu difference |', '|---|---|---|---|---|']
  for row in bie:
    lines.append('| %s | %s | %s | %s | %s |' % (row['label'], fmt(row['k'], '.16g'),
      row['qualified'], fmt(row['signed_k_difference']), fmt(row['abs_mu_difference'])))
  cost = summary['cost']
  lines += ['', '- Cost (accounting estimate): cold delivery %s s, verification/diagnostics %s s, '
    'MATLAB function %s s.' % (fmt(cost.get('cold_delivery_seconds'), '.1f'),
      fmt(cost.get('verification_diagnostic_seconds'), '.1f'),
      fmt(cost.get('matlab_function_seconds'), '.1f')),
    '- BIE differences are an external reference comparison only.']
  (output/'summary.md').write_text('\n'.join(lines) + '\n')
  return summary


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  args = parser.parse_args()
  summary = summarize(Path(args.output).resolve())
  print(json.dumps(dict(status=summary['matlab_final_status'],
    mesh_identity=summary['mesh_identity']['status'],
    cold=summary['cost'].get('cold_delivery_seconds')), allow_nan=True))


if __name__ == '__main__':
  main()
