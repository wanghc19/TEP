"""Summarize saved switch-line scalars, without rebuilding any field.

Input: explicit completed run directory.
Output: summary.json, including sampled kernel ranges and arithmetic checks.
"""
import argparse
import csv
import json
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('run', type=Path)
a = p.parse_args()
r = json.loads((a.run / 'result.json').read_text())
m = json.loads((a.run / 'monitor.json').read_text())
assert r['status'] == 'COMPLETE' and m['reason'] == 'completed'
with (a.run / 'kernel-jumps.csv').open() as f:
  rows = list(csv.DictReader(f))
fields = ['G', 'Gx', 'Gy', 'Hxx', 'Hxy', 'Hyy']
def value(row, name):
  return complex(float(row[name + '_re']), float(row[name + '_im']))

pieces = []
for g, b in zip(r['geometry'], r['refined_line']['pieces']):
  selected = [x for x in rows if g['Y_range'][0] <= float(x['Y']) <= g['Y_range'][1]]
  pieces.append({
    'piece': g['piece'], 'Y_range': g['Y_range'],
    'sampled_jump_max_physical_G_Gx_Gy_Hxx_Hxy_Hyy':
      [max(abs(value(x, f)) for x in selected) for f in fields],
    'Q_sw_piece': r['settings']['C_line'] * b['integral'],
    'share_percent': 100 * r['settings']['C_line'] * b['integral'] / r['Q_sw'],
  })
s = {'pieces': pieces, 'budget': r['budget'], 'convergence': r['convergence'],
     'Q_sw_over_Q_grp': r['Q_sw'] / r['settings']['Q_grp'],
     'helmholtz_jump_identity_max': max(abs(value(x, 'Hxx') + value(x, 'Hyy')
       + r['config']['k0'] ** 2 * value(x, 'G')) for x in rows),
     'codepath': [], 'monitor': m, 'matlab_stage_seconds': r['times'],
     'matlab_seconds': r['seconds'],
     'startup_shutdown_monitor_seconds': m['wall_seconds'] - r['seconds']}
for offset in r['settings']['offsets']:
  checks = [x for x in r['codepath'] if x['offset'] == offset]
  s['codepath'].append({'offset': offset,
    'max_value_difference_after_smooth_drift': max(x['difference'] for x in checks),
    'max_raw_y_difference': max(abs(complex(*x['raw_y']) - complex(*x['predicted_y'])) for x in checks),
    'passes': all(x['pass'] for x in checks)})
assert abs(sum(r['times'].values()) - r['seconds']) < .1
(a.run / 'summary.json').write_text(json.dumps(s, indent=2) + '\n')
print(json.dumps({'Q_sw': r['Q_sw'], 'margin': r['budget']['margin'], 'seconds': m['wall_seconds']}, indent=2))
