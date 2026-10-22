#!/usr/bin/env python3
"""Independently reconstruct current-run search and sampled resource evidence."""
import ast
import csv
import json
import math
from pathlib import Path
import statistics
import struct
import sys

ROOT = Path(sys.argv[1]); ISSUES = []; CHECKS = 0
METRICS = ['adef_sigma', 'adef_ratio', 'aphys_sigma', 'aphys_ratio']


def load(p):
  return json.loads(p.read_text())


def ck(ok, label):
  global CHECKS
  CHECKS += 1
  if not ok:
    ISSUES.append(label)


def near(a, b):
  return math.isclose(a, b, rel_tol=2e-13, abs_tol=1e-10)


def same(a, b):
  return struct.pack('>d', a) == struct.pack('>d', b)


def science(c):
  return {k: v for k, v in c.items() if k != 'resources'}


def arr(x):
  return x if isinstance(x, list) else [x]


CONFIG = load(ROOT/'setup/config.json'); S = CONFIG['search']; LIM = CONFIG['resources']


def callbacks(row, backend, label):
  calls = arr(row['proxy_calls'])
  expected = [CONFIG['discretization']['ntot_lead']**2, CONFIG['discretization']['ntot_center']**2]
  ck(len(calls) == 2, label+' two field callbacks')
  ck([c['nt'] for c in calls] == expected, label+' actual field target counts')
  for c in calls:
    ck(c['method'] == backend and c['stage'] == 'field' and c['ier'] == 0, label+' backend/stage/ier')
    ck(c['ns'] == 4*CONFIG['discretization']['nproxy'], label+' actual source count')
    expected_batches = 1 if backend == 'fmm' else math.ceil(c['nt']/CONFIG['backend']['direct_target_batch'])
    ck(c['batches'] == expected_batches, label+' callback batches')
  ck(sum(c['seconds'] for c in calls) <= row['seconds']+1e-8, label+' callback child time')


def search_audit(backend):
  directory = ROOT/backend
  points = load(directory/'points.json'); rounds = load(directory/'rounds.json')
  sr = load(directory/'search-result.json'); pr = load(directory/'pipeline-result.json')
  rebuilt = []; batch_walls = 0.; exports = 0.; within_matlab = 0.; process_overhead = 0.
  for batch in sorted(directory.glob('round-*-batch-*')):
    if '-failed-' in batch.name or not batch.is_dir():
      continue
    req = load(batch/'request.json'); status = load(batch/'status.json')
    rows = arr(load(batch/'points.json')); timing = load(batch/'batch-timing.json')
    ck(status['exit_code'] == 0 and not status['survivors'], str(batch)+' success')
    ck(req['backend'] == backend and science(req['config']) == science(CONFIG), str(batch)+' shared config')
    if 'linspace_bounds' not in req:
      ck([x['k'] for x in rows] == arr(req['k_values']), str(batch)+' actual requested wide nodes')
    else:
      bounds = req['linspace_bounds']; ks = [x['k'] for x in rows]
      ck(ks[0] == bounds[0] and ks[-1] == bounds[1], str(batch)+' actual endpoints')
      ck(len(ks) == S['refine_count'], str(batch)+' full local count')
      for j, k in enumerate(ks):
        ideal = bounds[0]+j*(bounds[1]-bounds[0])/(len(ks)-1)
        ck(abs(k-ideal) <= 2*math.ulp(k), str(batch)+' linspace rounded node '+str(j))
    for j, row in enumerate(rows):
      raw = load(batch/f'point-{j+1:03d}.json')
      ck(raw == row, str(batch)+' perpoint export '+str(j))
      callbacks(row, backend, str(batch)+' point '+str(j)); rebuilt.append(row)
    point_total = sum(x['seconds'] for x in rows)
    ck(near(point_total, timing['search_point']), str(batch)+' point timing sum')
    batch_walls += status['wall_seconds']; exports += timing['save_export']
    within_matlab += timing['matlab_batch']-point_total-timing['save_export']
    process_overhead += status['wall_seconds']-timing['matlab_batch']
  ck(len(points) == len(rebuilt), backend+' point count from batches')
  for j, (row, raw) in enumerate(zip(points, rebuilt)):
    ck(row['evaluation_index'] == j+1, backend+' evaluation ordering')
    ck(all(row[k] == v for k, v in raw.items()), backend+' raw aggregate identity '+str(j))
    ck(row['valid'] and all(math.isfinite(row[k]) and row[k] >= 0 for k in METRICS), backend+' valid metrics '+str(j))
  wide = [S['wide_first']+j*S['wide_step'] for j in range(S['wide_count'])]
  seen = []; cumulative = []; reconstructed = []; previous = None
  repeated = {}; repeated_max = {m: 0. for m in METRICS}; repeat_count = 0
  for idx, record in enumerate(rounds):
    rows = [r for r in points if r['round_index'] == idx]
    ks = [r['k'] for r in rows]; scores = [r['aphys_ratio'] for r in rows]
    ck(record['round_index'] == idx, backend+' round order')
    ck(len(rows) == (S['wide_count'] if idx == 0 else S['refine_count']), backend+' complete round '+str(idx))
    ck(all(math.isfinite(k) for k in ks) and all(b > a for a, b in zip(ks, ks[1:])) and len(set(ks)) == len(ks), backend+' actual ordered unique grid '+str(idx))
    ck(ks not in seen, backend+' nonrepeated window '+str(idx)); seen.append(ks)
    ck([r['node_index'] for r in rows] == list(range(1, len(rows)+1)), backend+' node order '+str(idx))
    dips = [j for j in range(1, len(rows)-1) if scores[j] < scores[j-1] and scores[j] < scores[j+1]]
    global_j = min(range(len(rows)), key=lambda j: scores[j])
    selected = min(dips, key=lambda j: scores[j]) if idx == 0 and dips else global_j
    if idx == 0:
      ck(ks == wide, backend+' exact first wide grid')
      ck(bool(dips), backend+' strict wide dip exists')
    else:
      oldks, oldj, oldrecord = previous
      if 0 < oldj < len(oldks)-1:
        ck(record['kind'] == 'refine' and ks[0] == oldks[oldj-1] and ks[-1] == oldks[oldj+1], backend+' actual neighbor refinement '+str(idx))
        ck(ks[0] < oldks[oldj] < ks[-1], backend+' old winner interior '+str(idx))
        ck(record['requested_step'] == (oldks[oldj+1]-oldks[oldj-1])/(S['refine_count']-1), backend+' refined step '+str(idx))
      else:
        step = oldrecord['requested_step']; span = step*(S['refine_count']-1)
        shift = S['endpoint_shift_steps']*step
        first = oldks[0]+(-shift if oldj == 0 else shift)
        first = min(max(first, wide[0]), wide[-1]-span)
        ck(record['kind'] == 'recovery' and ks[0] == first and ks[-1] == first+span and record['requested_step'] == step, backend+' deterministic recovery '+str(idx))
    cumulative += rows; best = min(cumulative, key=lambda r: r['aphys_ratio'])
    interior = 0 < selected < len(rows)-1; W = ks[-1]-ks[0]
    spacing = [b-a for a, b in zip(ks, ks[1:])]
    ck(record['selected_index'] == selected+1 and record['selected_k'] == ks[selected] and record['selected_ratio'] == scores[selected], backend+' stable selected winner '+str(idx))
    ck(record['global_index'] == global_j+1 and record['strict_dips'] == [j+1 for j in dips], backend+' dips and global winner '+str(idx))
    ck(record['actual_W'] == W and record['interior'] == interior, backend+' width interior '+str(idx))
    ck(record['count'] == len(rows) and record['first'] == ks[0] and record['last'] == ks[-1], backend+' recorded actual bounds/count '+str(idx))
    ck(record['left_neighbor'] == (ks[selected-1] if interior else None) and record['right_neighbor'] == (ks[selected+1] if interior else None), backend+' recorded actual neighbors '+str(idx))
    ck(all(r['round_kind'] == record['kind'] for r in rows), backend+' round kind consistency '+str(idx))
    ck(record['cumulative_k'] == best['k'] and record['cumulative_ratio'] == best['aphys_ratio'], backend+' cumulative first minimum '+str(idx))
    if idx < len(rounds)-1:
      ck(not(idx > 0 and interior and W <= S['width_target']), backend+' no missed stop '+str(idx))
    reconstructed.append(dict(round_index=idx, kind=record['kind'], W=W, spacing=spacing,
      w=ks[selected+1]-ks[selected-1] if interior else None, selected_index=selected+1,
      cumulative_evaluation_index=best['evaluation_index']))
    previous = (ks, selected, record)
    for row in rows:
      if row['k'] in repeated:
        repeat_count += 1
        for m in METRICS:
          repeated_max[m] = max(repeated_max[m], abs(row[m]-repeated[row['k']][m]))
      else:
        repeated[row['k']] = row
  winner = min(points, key=lambda r: r['aphys_ratio']); ks, j, last = previous
  ck(last['kind'] != 'wide' and 0 < j < len(ks)-1 and ks[-1]-ks[0] <= S['width_target'], backend+' complete final width gate')
  ck(sr['status'] == 'complete' and sr['candidate'] == winner and sr['final_round_winner'] == rows[j], backend+' formal own cumulative candidate')
  ck(sr['point_count'] == len(points) and sr['round_count'] == len(rounds), backend+' summary counts')
  ck(near(sr['search_process_wall'], batch_walls) and near(sr['search_point_seconds'], sum(r['seconds'] for r in points)), backend+' search time reconstruction')
  er = load(directory/'estimate/request.json'); estimate = load(directory/'estimate/result.json')
  es = load(directory/'estimate/status.json'); save = load(directory/'estimate/save-timing.json')
  ck(er['action'] == 'estimate' and er['backend'] == backend and er['k_values'] == winner['k'], backend+' own fresh estimate input')
  ck(science(er['config']) == science(CONFIG) and science(estimate['config']) == science(CONFIG), backend+' fresh shared config')
  ck(estimate['k0'] == winner['k'] and estimate['point']['k'] == winner['k'] and estimate['backend'] == backend, backend+' own fresh output')
  ck(estimate['status'] == 'UNCERTIFIED_RNUM' and estimate['certified'] is False and estimate['denominator'] > 0, backend+' numeric output state')
  field = [c for c in arr(estimate['proxy_calls']) if c['stage'] == 'field']
  callbacks(dict(proxy_calls=field, seconds=estimate['timing']['final_field']), backend, backend+' fresh field')
  allcalls = arr(estimate['proxy_calls'])
  ck(all(c['method'] == backend and c['ier'] == 0 for c in allcalls), backend+' full estimate callbacks')
  stage_alias = {'field': 'final_field', 'jumps': 'jumps', 'mass': 'mass'}
  for stage, key in stage_alias.items():
    ck(sum(c['seconds'] for c in allcalls if c['stage'] == stage) <= estimate['timing'][key]+1e-8, backend+' callback subsets '+stage)
  stages = estimate['timing']; est_numeric = sum(stages.values()); est_export = save['save_export']
  points_total = sum(r['seconds'] for r in points)
  ledger = dict(search_points=points_total, search_export=exports, search_matlab_other=within_matlab,
    search_process_other=process_overhead, final_field=stages['final_field'], jumps=stages['jumps'],
    mass=stages['mass'], geometry_assembly=stages['geometry_assembly'], estimate_save_export=est_export,
    estimate_process_other=es['wall_seconds']-est_numeric-est_export)
  ck(all(v >= -1e-8 for v in ledger.values()), backend+' nonnegative timing partition')
  ck(near(sum(ledger.values()), batch_walls+es['wall_seconds']), backend+' mutually exclusive partition sum')
  ck(near(pr['pipeline_process_wall'], batch_walls+es['wall_seconds']), backend+' retained successful process walls')
  if not pr.get('resumed', False):
    ck(pr['pipeline_elapsed_wall'] >= pr['pipeline_process_wall'], backend+' pipeline elapsed covers subprocess walls')
  return dict(point_count=len(points), distinct_k_count=len(repeated), repeat_count=repeat_count,
    repeat_metrics_max_abs=repeated_max, candidate_k=winner['k'],
    candidate_evaluation_index=winner['evaluation_index'], final_bracket_winner=ks[j],
    candidate_inside_final_window=ks[0] <= winner['k'] <= ks[-1],
    fresh_metric_abs={m: abs(estimate['point'][m]-winner[m]) for m in METRICS},
    fresh_metrics_bitwise={m: same(estimate['point'][m], winner[m]) for m in METRICS},
    rounds=reconstructed, point_seconds_min=min(r['seconds'] for r in points),
    point_seconds_median=statistics.median(r['seconds'] for r in points),
    point_seconds_max=max(r['seconds'] for r in points), timing_partition=ledger,
    pipeline_process_wall=batch_walls+es['wall_seconds'], pipeline_elapsed_wall=pr['pipeline_elapsed_wall'],
    elapsed_scope=pr.get('elapsed_wall_scope', 'complete current invocation'),
    resumed=pr.get('resumed', False), estimate_callback_count=len(allcalls))


def resource_audit():
  records = []
  for path in sorted(ROOT.parent.glob('run-*/**/status.json')):
    batch = path.parent; st = load(path); respath = batch/'resources.csv'
    rows = list(csv.DictReader(respath.open())) if respath.exists() else []
    peak = max([int(r['rss_bytes']) for r in rows]+[0])
    elapsed = [float(r['elapsed_seconds']) for r in rows]
    ck(peak == st['peak_rss_bytes'], str(batch)+' independently sampled RSS peak')
    ck(not st['survivors'], str(batch)+' cleanup survivors')
    ck(all(ast.literal_eval(r['external_matlab']) == [] for r in rows), str(batch)+' no foreign MATLAB')
    ck(all(b > a for a, b in zip(elapsed, elapsed[1:])), str(batch)+' monitor monotone time')
    ck(not elapsed or elapsed[-1] <= st['wall_seconds'], str(batch)+' monitor within wall')
    pf = batch/'preflight.json'
    if pf.exists():
      ck(not any('matlab' in r['command'].lower() for r in load(pf).values()), str(batch)+' no preexisting MATLAB')
    success = st['exit_code'] == 0 and st['reason'] == 'process_exited'
    if success:
      ck(peak < LIM['rss_bytes'], str(batch)+' successful RSS below hard limit')
      ck(st['wall_seconds'] < LIM['hard_seconds']+2, str(batch)+' successful wall within hard limit plus monitor cleanup')
      ck(st['wall_seconds'] < LIM['soft_seconds']+2 or st['grace'], str(batch)+' soft time / disclosed grace')
    req = load(batch/'request.json'); action = req['action']; backend = req.get('backend', 'setup')
    records.append(dict(path=str(batch.relative_to(ROOT.parent)), backend=backend, action=action,
      success=success, wall_seconds=st['wall_seconds'], sample_count=len(rows),
      peak_rss_bytes=peak, grace=st['grace'], reason=st['reason']))
  return dict(records=records, successful_batch_seconds=sum(x['wall_seconds'] for x in records if x['success']),
    failed_batch_seconds=sum(x['wall_seconds'] for x in records if not x['success']),
    all_batch_seconds=sum(x['wall_seconds'] for x in records),
    sampled_peak_rss_bytes=max([x['peak_rss_bytes'] for x in records]+[0]),
    absolute_utc_intervals='not recorded; do not infer from file mtimes',
    rss_scope='sampled process-tree peak, not a continuous supremum')


out = {'schema': 'I84_INDEPENDENT_SEARCH_RESOURCE_AUDIT_V1', 'root': str(ROOT)}
try:
  ck(CONFIG['discretization']['ntot_center'] == 512 and CONFIG['discretization']['ntot_lead'] == 256, 'frozen first-point construction orders')
  ck(CONFIG['evaluation']['material_nodes'] == 768 and CONFIG['evaluation']['wall_nodes'] == 768 and CONFIG['evaluation']['disk_grid'] == [32, 64] and CONFIG['evaluation']['disk_shift'] == 0.5 and CONFIG['evaluation']['lead_cells'] == 40, 'frozen single evaluation level')
  ck(CONFIG['backend']['order'] == ['direct', 'fmm'] and CONFIG['backend']['fmm_eps'] == 1e-12, 'backend order and tolerance')
  for backend in ['direct', 'fmm']:
    out[backend] = search_audit(backend)
  out['resources'] = resource_audit()
  out['comparison'] = {'candidate_abs_difference': abs(out['direct']['candidate_k']-out['fmm']['candidate_k']),
    'point_counts': [out['direct']['point_count'], out['fmm']['point_count']],
    'successful_process_wall_ratio_direct_over_fmm': out['direct']['pipeline_process_wall']/out['fmm']['pipeline_process_wall'],
    'interpretation': 'observed own-path cost ratio; search point counts may differ; callback times are subsets, not extra costs'}
except Exception as error:
  ISSUES.append(type(error).__name__+': '+str(error))
out['checks_run'] = CHECKS; out['issues'] = ISSUES; out['all_checks_pass'] = not ISSUES
print(json.dumps(out, indent=2, allow_nan=False))
if ISSUES:
  sys.exit(1)
