"""Collect the scalar Goerisch results and check the refinement comparisons.

Input: experiment directory and an existing completed run directory for output.
Output: comparison.json and comparison.csv; no field data or solver invocation.
JSON is JavaScript Object Notation; CSV is comma-separated values.
"""
import csv
import json
import sys
from decimal import Decimal, localcontext
from pathlib import Path

experiment = Path(sys.argv[1])
output = Path(sys.argv[2])
assert output.is_dir()
rows = []
for number in (10, 11, 12, 13, 14, 15):
  run = experiment / 'output' / f'run-{number:03d}'
  science = run / 'science' / 'result.json'
  monitoring = run / 'monitor.json'
  if not science.exists() or not monitoring.exists():
    continue
  result = json.loads(science.read_text())
  monitor = json.loads(monitoring.read_text())
  check = result['checks']
  rows.append(dict(run=number, trial=result['config']['trial'], degree=result['config']['degree'],
    theta=result['theta'], q=result['q'], J=result['J'], J_check=result['J_check'],
    J_gram=result['J_gram'], gram_minus_point=result['J_gram']-result['J'],
    variance=result['qJ_minus_one'], lower=result['enclosure'][0], upper=result['enclosure'][1],
    width=result['width'], wall_seconds=monitor['wall_seconds'], solver_seconds=result['wall_seconds'],
    peak_rss_gib=monitor['peak_process_tree_rss_gib'],
    J_quadrature_change=check['J_quadrature_change'], scaled_quadrature_fraction=check['scaled_quadrature_fraction'],
    quadrature_pass=check['quadrature_pass'], contains_reference=check['contains_reference'],
    sign_conditions=check['sign_conditions'], variance_positive=check['variance_positive'],
    exit_code=monitor['returncode']))
rows.sort(key=lambda x: (x['degree'], x['trial'] == 'D'))
monotonicity = []
for trial in ('R', 'D'):
  group = sorted((x for x in rows if x['trial'] == trial), key=lambda x: x['degree'])
  for first, second in zip(group, group[1:]):
    uncertainty = abs(first['J_quadrature_change']) + abs(second['J_quadrature_change'])
    drop = first['J']-second['J']
    monotonicity.append(dict(trial=trial, degrees=[first['degree'], second['degree']],
      J_drop=drop, quadrature_uncertainty=uncertainty, passed=drop >= -uncertainty))
reference = json.loads((experiment/'output/run-010/science/result.json').read_text())
with localcontext() as context:
  context.prec = 50
  q = Decimal(str(reference['q']))
  lower_edge = Decimal(str(reference['config']['mu']))
  upper_edge = Decimal(str(reference['config']['nu']))
  exact = Decimal(str(reference['config']['mu_bie']))
  delta = q-1-exact
  least_J = (upper_edge-delta)/(upper_edge*(q-delta))
  least_width = (q-lower_edge)/(1-lower_edge*least_J)-1-exact
  quotient_constraint = dict(theta_minus_reference=float(delta),
    J_for_lower_endpoint_equal_reference=float(least_J),
    minimum_width_to_contain_reference=float(least_width))
summary = dict(complete=len(rows)==6, rows=rows, monotonicity=monotonicity,
  quotient_constraint=quotient_constraint,
  measured_wall_seconds=sum(x['wall_seconds'] for x in rows))
(output/'comparison.json').write_text(json.dumps(summary, indent=2)+'\n')
with (output/'comparison.csv').open('w', newline='') as stream:
  writer = csv.DictWriter(stream, fieldnames=rows[0].keys())
  writer.writeheader()
  writer.writerows(rows)
print(json.dumps(dict(complete=summary['complete'], monotonicity=monotonicity,
  quotient_constraint=quotient_constraint), indent=2))
assert all(x['passed'] for x in monotonicity), 'Nested-space monotonicity failed.'
assert all(x['quadrature_pass'] and x['contains_reference'] and x['sign_conditions']
  and x['variance_positive'] and x['exit_code']==0 for x in rows), 'A run check failed.'
