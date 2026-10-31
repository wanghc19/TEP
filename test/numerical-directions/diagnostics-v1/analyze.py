"""Summarize the integration rate and Dirichlet-to-Neumann interpolation diagnostics.
Input: retained numerical records in output/run-002 and output/run-003.
Output: compact CSV (comma-separated values) and JSON (JavaScript Object Notation) summaries.
"""
import csv
import json
import math
import statistics
from pathlib import Path

base = Path(__file__).parent
rate = base / 'output/run-002'
lead = base / 'output/run-003'

def fit(x, y):
  xs, ys = list(map(math.log, x)), list(map(math.log, y))
  xm, ym = statistics.mean(xs), statistics.mean(ys)
  slope = sum((a-xm)*(b-ym) for a,b in zip(xs,ys))/sum((a-xm)**2 for a in xs)
  residual = sum((b-ym-slope*(a-xm))**2 for a,b in zip(xs,ys))
  return {'r': -slope, 'C': math.exp(ym-slope*xm),
          'R_squared': 1-residual/sum((b-ym)**2 for b in ys),
          'points': len(x), 'piece_span': max(x)/min(x)}

def write_csv(path, rows):
  with path.open('w') as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)

rows = []
for path in rate.glob('cap-*/template-rate.json'):
  data = json.loads(path.read_text())
  if not isinstance(data, list):
    continue
  resource = json.loads((path.parent/'monitor.json').read_text())
  for row in data:
    row.update({k: resource[k] for k in ['wall_seconds','peak_process_tree_rss_gib']})
    rows.append(row)
rows.sort(key=lambda r: (r['piece_limit'], r['level'], r['template']))
write_csv(rate/'rate-data.csv', rows)
fits = []
for level in ['control','main']:
  for name in ['left','center','right']:
    data = [r for r in rows if r['level']==level and r['template']==name]
    fits.append({'level':level, 'template':name,
      **fit([r['terminal_pieces'] for r in data], [r['moment_uncertainty_upper'] for r in data])})
level_rows = []
for cap in sorted({r['piece_limit'] for r in rows}):
  for level in ['control','main']:
    data = [r for r in rows if r['piece_limit']==cap and r['level']==level]
    row = data[0]
    level_rows.append({'piece_limit':cap, 'level':level,
      'terminal_pieces_total':sum(r['terminal_pieces'] for r in data),
      **{k:row[k] for k in ['level_moment_upper','level_moment_share_Rmu','R_mu','R_k','E_v']}})
global_fits = []
for level in ['control','main']:
  data = [r for r in level_rows if r['level']==level]
  global_fits.append({'level':level,
    **fit([r['terminal_pieces_total'] for r in data],[r['level_moment_upper'] for r in data])})
formal = json.loads((rate/'formal-reference.json').read_text())
r = next(f['r'] for f in global_fits if f['level']=='main')
factor = (formal['moment_term']/formal['E_v'])**(1/r)
extrapolation = {'formal_main_moment':formal['moment_term'], 'target_E_v':formal['E_v'],
  'fitted_r':r, 'piece_multiplier':factor,
  'predicted_terminal_pieces':{k:v*factor for k,v in formal['terminal_pieces'].items()},
  'predicted_piece_cap':formal['piece_cap']*factor,
  'linear_work_main_engine_seconds':sum(formal['engine_seconds'].values())*factor,
  'assumption':'same exponent and proportional piece scaling transfer from smoke to formal main'}
(rate/'rate-fits.json').write_text(json.dumps({'template_fits':fits, 'global_fits':global_fits,
  'level_summary':level_rows, 'formal_extrapolation':extrapolation}, indent=2))
write_csv(rate/'rate-fits.csv', fits)
write_csv(rate/'level-summary.csv', level_rows)

with (lead/'interpolation.csv').open() as f:
  interpolation = list(csv.DictReader(f))
with (lead/'evaluations.csv').open() as f:
  evaluations = list(csv.DictReader(f))
# Each interval includes the already computed root matrix as its middle node.
# Three CSV rows reuse it; the initial root evaluation is outside that CSV.
fresh = [e for e in evaluations if abs(float(e['k'])-1.5584378942105757)>1e-13]
initial_seconds = json.loads((lead/'summary.json').read_text())['response_pair_seconds_at_root']
times = [float(e['pair_seconds']) for e in fresh]+[initial_seconds]
curves = []
for h in [1e-4,1e-3,1e-2]:
  for n in [2,4,8,16]:
    data = [r for r in interpolation if float(r['h'])==h and int(r['degree'])==n]
    curves.append({'h':h,'degree':n,
      'worst_relative_fro':max(float(r['max_relative_fro']) for r in data),
      'worst_relative_2':max(float(r['max_relative_2']) for r in data),
      'pair_interpolant_seconds':sum(float(r['interpolant_seconds']) for r in data)})
bands = json.loads((lead/'bands.json').read_text())
d = min(b['nearest_distance_k'] for b in bands)
ellipses = [{'h':h, 'rho_real_edge':d/h+math.sqrt((d/h)**2-1)} for h in [1e-4,1e-3,1e-2]]
with (lead/'iterations-reference.csv').open() as f:
  iterations = list(csv.DictReader(f))
purposes = {name:sum(r['purpose']==name for r in iterations) for name in sorted({r['purpose'] for r in iterations})}
summary = {'response_pair_evaluations':len(fresh)+1,'reused_root_rows':len(evaluations)-len(fresh),
  'response_pair_seconds_median':statistics.median(times), 'response_pair_seconds_min':min(times),
  'response_pair_seconds_max':max(times), 'curves':curves, 'real_edge_ellipses':ellipses,
  'historical_response_purposes':purposes,
  'scope':'off-grid matrix interpolation errors and sampled discrete band extrema; no uniform continuum certificate'}
(lead/'analysis.json').write_text(json.dumps(summary,indent=2))
write_csv(lead/'interpolation-summary.csv',curves)
print(json.dumps({'template_rates':fits,'formal_extrapolation':extrapolation,
                 'response_pair_evaluations':len(fresh)+1,'median_pair_seconds':statistics.median(times)},indent=2))
