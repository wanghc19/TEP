"""Summarize saved mode-comparison metrics without a numerical solver run.

All inputs and outputs are explicit. This analysis uses the already saved
cell masses; it does not create new fields, roots, or spectral certificates.
"""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('metrics')
parser.add_argument('output')
args = parser.parse_args()
data = json.loads(Path(args.metrics).read_text())
main = data['levels'][-1]['prefix12']
out = {'status': 'ORDINARY_SAVED_DATA_ANALYSIS', 'regions': {}}
for name, indices in [('left', range(12)), ('center', [12]), ('right', range(13, 25))]:
  out['regions'][name] = {
    'mass_fraction_B': sum(main['mass_fraction_B'][j] for j in indices),
    'mass_fraction_F': sum(main['mass_fraction_F'][j] for j in indices),
  }
for name, start in [('left', 0), ('right', 13)]:
  item = out['regions'][name]
  for method in ['B', 'F']:
    masses = main['cell_mass_' + method][start:start + 12]
    item['far_cell_mass_ratios_' + method] = [masses[j + 1] / masses[j] for j in range(7, 11)]
    item['dominant_multiplier_abs_squared_' + method] = data['multipliers'][name][method + '_abs'][0]**2
  item['F_tail_fraction_after12'] = data['multipliers'][name]['F_tail_mass_after12'] / main['norm_F']**2
out['mass_fraction_outside_four_cells_each_side_B'] = sum(main['mass_fraction_B'][4:12] + main['mass_fraction_B'][17:25])
out['mass_fraction_outside_four_cells_each_side_F'] = sum(main['mass_fraction_F'][4:12] + main['mass_fraction_F'][17:25])
Path(args.output).write_text(json.dumps(out, indent=2) + '\n')
print(json.dumps(out, indent=2))
