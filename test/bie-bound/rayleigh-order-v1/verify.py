"""Check the retained Rayleigh experiment and independently refit its rates.
Input: explicit experiment directory, with completed numerical runs.
Output: results/checks.json (JavaScript Object Notation).
"""
import argparse
import json
import math
import os
from pathlib import Path
import numpy as np

p = argparse.ArgumentParser()
p.add_argument('--experiment', type=Path, required=True)
a = p.parse_args()
root = a.experiment
def read(name):
  return json.loads((root/name).read_text())

s = read('results/summary.json')
rows = read('output/run-002/roots.json')
dims = read('output/run-003/dimension.json')
assert len(rows) == 63 and all(r['status'] == 'MEASURED' for r in rows)
assert len(dims) == 94 and all(r['status'] == 'MEASURED' for r in dims)
regression = abs(s['regression']['k'] - 1.558437894182088)
assert regression <= 2e-14
assert max(r['ratio'] for r in rows) < 1e-11
assert s['empty']['flux_defect'] < 1e-13
assert s['empty']['trace_check'] < 1e-13
assert s['rod']['flux_defect'] < 1e-13
assert s['rod']['neutrality'] < 1e-13
fit_checks = []
for f in s['root_fits'] + s['late_fits']:
  rr = [r for r in rows if (r['model'],r['N'],r['cut']) == (f['model'],f['N'],f['cut'])]
  ref = next(r['k'] for r in rr if r['M'] == 24)
  lookup = {r['M']:r for r in rr}
  xx = np.asarray(f['points'],dtype=float)
  yy = np.log([abs(lookup[m]['k']-ref) for m in f['points']])
  design = np.column_stack([xx,np.ones_like(xx)])
  coefficients = np.linalg.lstsq(design,yy,rcond=None)[0]
  width = -coefficients[0]/(2*math.pi)
  rms = np.linalg.norm(yy-design@coefficients)/math.sqrt(len(xx))
  assert abs(width-f['width']) < 1e-13
  assert abs(rms-f['rms_log']) < 1e-13
  for m in f['points']:
    floor = 20*math.ulp(ref)
    if f['model'] == 'ex1':
      floor = max(floor,10*s['density_difference'][str(m)],10*s['density_difference']['24'])
    assert abs(lookup[m]['k']-ref) > floor
  fit_checks.append(dict(model=f['model'],N=f['N'],cut=f['cut'],points=f['points'],
    independent_width=width,width_difference=abs(width-f['width']),independent_rms=rms))

monitors = [read(f'output/run-{i:03}/monitor.json') for i in range(1,7)]
assert all(m['peak_process_tree_rss_gib'] <= 2 for m in monitors)
assert all(m['wall_seconds'] <= 2400 for m in monitors)
assert all(monitors[i-1]['returncode'] == 0 for i in [1,2,3,4,6])
assert monitors[4]['returncode'] == 1
size = sum((Path(d)/f).lstat().st_size for d,ds,fs in os.walk(root,followlinks=False) for f in fs)
assert size < 100_000_000
assert not list(root.rglob('*.mat'))
result = dict(required_checks='PASS',regression_error=regression,
  root_jobs=len(rows),lead_cases=len(dims),independent_fits=fit_checks,
  total_monitored_seconds=sum(m['wall_seconds'] for m in monitors),
  peak_rss_gib=max(m['peak_process_tree_rss_gib'] for m in monitors),
  experiment_bytes=size,field_mat_files=0,
  pass_with_non_K=sum(r['defect_below_distance'] and not r['count_is_K'] for r in dims),
  fail_with_K=sum(not r['defect_below_distance'] and r['count_is_K'] for r in dims))
(root/'results/checks.json').write_text(json.dumps(result,indent=2))
print(json.dumps({k:v for k,v in result.items() if k != 'independent_fits'},indent=2))
