"""Summarize the Goerisch flux audit and fixed solves from scalar records.

Input: experiment directory and an existing output run directory.
Output: study-summary.json and study-results.csv; no solver or field data.
JSON means JavaScript Object Notation; CSV means comma-separated values.
"""
import csv
import json
import sys
from decimal import Decimal, localcontext
from pathlib import Path

base = Path(sys.argv[1])
out = Path(sys.argv[2])
assert out.is_dir()
def read(number, name='science/result.json'):
  return json.loads((base/f'output/run-{number:03d}'/name).read_text())

a = read(16)
components = {}
for label in ('gram_minus_point_low', 'gram_minus_point_high', 'low_point', 'high_point'):
  components[label] = [[sum(t[label][i][j] for t in a['localization']) for j in range(3)] for i in range(2)]
localization = dict(components=components, component_rows=['unchanged', 'curved'],
  component_columns=['flux_mass', 'div_div', 'twice_load'], mass=a['mass'],
  combined_gram_minus_point_numerator=(a['J_gram']-a['J'])*a['mass'],
  matrix_relative_frobenius_range=[min(c['matrix_relative_frobenius'] for t in a['localization'] for c in t['orders_comparison']),max(c['matrix_relative_frobenius'] for t in a['localization'] for c in t['orders_comparison'])],
  load_relative_frobenius_range=[min(c['load_relative_frobenius'] for t in a['localization'] for c in t['orders_comparison']),max(c['load_relative_frobenius'] for t in a['localization'] for c in t['orders_comparison'])],
  interior_residual_range=[min(t['interior_equation_relative_residual'] for t in a['localization']),max(t['interior_equation_relative_residual'] for t in a['localization'])],
  global_solve_residual=a['checks']['global_solve_residual'])
rows=[]
for number in range(17,23):
  run=base/f'output/run-{number:03d}'
  if not (run/'science/result.json').exists() or not (run/'monitor.json').exists(): continue
  r=read(number);m=read(number,'monitor.json');c=r['checks']
  rows.append(dict(run=number,trial=r['config']['trial'],degree=r['config']['degree'],refinement=r['config']['refinement'],
    q=r['q'],theta=r['theta'],J=r['J'],J_check=r['J_check'],J_gram=r['J_gram'],
    qJ_minus_one=r['qJ_minus_one'],lower=r['enclosure'][0],upper=r['enclosure'][1],width=r['width'],
    quadrature_fraction=c['scaled_quadrature_fraction'],gram_fraction=c['gram_scaled_fraction'],
    J_quadrature_change=c['J_quadrature_change'],wall_seconds=m['wall_seconds'],peak_rss_gib=m['peak_process_tree_rss_gib'],
    max_inclusion_area_relative=max(z['relative_error'] for t in r['templates'] for z in t['area_check'].values()),
    max_cell_area_error=max(abs(z['cell_area']-1) for t in r['templates'] for z in t['area_check'].values()),
    theta_relative_difference=c['theta_relative_difference'],timing=r['timing']))
  assert all(c[k] for k in ('variance_positive','contains_reference','sign_conditions','quadrature_pass','gram_pass'))
  assert m['returncode']==0 and m['reason']=='completed'
  for template in r['templates']:
    for area in template['area_check'].values(): assert area['relative_error']<1e-12 and abs(area['cell_area']-1)<1e-12
  if r['config']['trial']=='R': assert c['theta_relative_difference']<1e-12 and r['width']>=7.677e-8
monotonicity=[]
for row in rows:
  previous=14 if row['trial']=='R' else 12
  if row['degree']==4:
    previous=next(x['run'] for x in rows if x['trial']==row['trial'] and x['degree']==3 and x['refinement']==0)
  p=read(previous)
  decrease=p['J']-row['J'];uncertainty=abs(p['checks']['J_quadrature_change'])+abs(row['J_quadrature_change'])
  monotonicity.append(dict(trial=row['trial'],previous_run=previous,run=row['run'],J_drop=decrease,quadrature_uncertainty=uncertainty,passed=decrease>=-uncertainty))
  assert decrease>=-uncertainty, 'Nested-space monotonicity failed.'
with localcontext() as context:
  context.prec=60
  q=Decimal(str(a['q']));lo=Decimal(str(a['config']['mu']));hi=Decimal(str(a['config']['nu']))
  reference=Decimal(str(a['config']['mu_bie']));delta=q-1-reference
  least_J=(hi-delta)/(hi*(q-delta))
  def width(j): return (hi-lo)*(q*j-1)/((1-lo*j)*(hi*j-1))
  left=1/q;right=Decimal(str(a['J']))
  for _ in range(160):
    midpoint=(left+right)/2
    if width(midpoint)<Decimal('1e-7'): left=midpoint
    else:right=midpoint
  constraints=dict(containment_J_min=float(least_J),containment_qJ_minus_one_min=float(q*least_J-1),
    containment_width_min=float(width(least_J)),qJ_minus_one_for_width_1e_7=float(q*(left+right)/2-1),
    maximum_flux_contribution_from_containment=float(q*(Decimal(str(a['J']))-least_J)))
tradeoffs=[]
for k,h in ((3,0),(2,1),(4,0)):
  pair={r['trial']:r for r in rows if r['degree']==k and r['refinement']==h}
  if len(pair)==2:
    r,d=pair['R'],pair['D']
    tradeoffs.append(dict(degree=k,refinement=h,width_ratio_D_to_R=d['width']/r['width'],
      wall_ratio_R_to_D=r['wall_seconds']/d['wall_seconds'],R_field_fraction_of_wall=r['timing']['field_evaluation']/r['wall_seconds']))
summary=dict(localization=localization,rows=rows,monotonicity=monotonicity,quotient_constraints=constraints,tradeoffs=tradeoffs,
  optional_rt4_rows_complete=all(any(x['trial']==t and x['degree']==4 for x in rows) for t in ('R','D')),
  requested_solve_rows_complete=all(any(x['trial']==t and x['degree']==d and x['refinement']==h for x in rows) for t in ('R','D') for d,h in ((3,0),(2,1))))
(out/'study-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
if rows:
  columns=[k for k in rows[0] if k!='timing']
  with (out/'study-results.csv').open('w',newline='') as stream:
    writer=csv.DictWriter(stream,fieldnames=columns,extrasaction='ignore');writer.writeheader();writer.writerows(rows)
print(json.dumps(dict(quotient_constraints=constraints,monotonicity=monotonicity,complete=summary['requested_solve_rows_complete']),indent=2))
