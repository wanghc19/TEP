#!/usr/bin/env python3
"""Cross-group summary of I10.2 (design-10-2a sections 4.2, 5 and 6).

Purpose: collect the three solve-discretization groups (historical g12 and
  g48 accepted in reuse.json, new g24), freeze the scientific table (roots,
  rule differences, d23/d34, q_obs, B_{g,p}, R_{g,0}, R_{g,N}, exact k
  intervals, same-mode and cross-grid wall correlations, interval
  compatibility ratios), and only then add the BIE external reference
  differences; write the cost ledger (NEW_RUN / REUSED_HISTORICAL, task
  accounting over every run directory) and two SVG figures.
Based on: test/i10/enrich-v1/summarize_enrich.py (BIE comparison and cost
  ledger) and reuse_refine.py (MAT reader and wall-trace port, loaded by path).
Main changes: new; multi-group tables, cross-grid correlation against the
  finest available group, exact mu -> k interval conversion, SVG figures.
Standard library only. The BIE value is used only after science.json is
written; it never enters any selection, gate or parameter.
"""
import argparse
import csv
import importlib.util
import json
import math
from pathlib import Path
import time

HERE = Path(__file__).resolve().parent
ATTEMPT = HERE/'output'/'attempt-1'
# Frozen inputs of this attempt (run identifiers chosen at execution time).
REUSE_DIR = ATTEMPT/'reuse-01'
NEW_RUNS = {'g24': ATTEMPT/'run-g24-01'}
PROBES = {'g12': ATTEMPT/'probe-g12-01'}
GROUPS = ['g12', 'g24', 'g48']
SN = {'g12': (12, 80), 'g24': (24, 160), 'g48': (48, 320)}
EPS = 1e-10
FLOOR = 3e-10                     # eps3 + 2 eps4
Q_RATIO_MIN = 2e-9                # q_obs only when d23 > 10 (eps2 + eps3)
CORR_MIN = 0.99
K_BIE = 1.5584378941820909        # external reference, used after science.json only


def load_module(name):
  spec = importlib.util.spec_from_file_location(name, HERE/(name + '.py'))
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  return module


REUSE = load_module('reuse_refine')


def jload(path):
  return json.loads(Path(path).read_text())


def k_interval(m, R):
  """Exact conversion of the mu-ball [m-R, m+R] to k (design 5)."""
  if m is None or R is None or not (math.isfinite(m) and math.isfinite(R)):
    return None
  if m > 0 and R < m:
    return dict(k_low=math.sqrt(m - R), k_high=math.sqrt(m + R),
      k_radius_max=R/(math.sqrt(m) + math.sqrt(m - R)), status='OK')
  return dict(k_low=0.0 if m <= R else math.sqrt(m - R), k_high=math.sqrt(m + R),
    k_radius_max=None, status='RESOLUTION_INSUFFICIENT')


def finite(x):
  return isinstance(x, (int, float)) and math.isfinite(x)


# ---------------------------------------------------------------------------
def group_records(reuse):
  """Per-group raw records and wall samples (Python port for all groups)."""
  out = {}
  for g in GROUPS:
    if g in NEW_RUNS:
      run = NEW_RUNS[g]
      if not (run/'result.json').exists():
        out[g] = dict(group=g, available=False, reason='no result.json in ' + run.name,
          source_kind='NEW_RUN', run=str(run))
        continue
      result = jload(run/'result.json')
      walls = jload(run/'wall-samples.json')
      kind, label = 'NEW_RUN', 'I10.2 new run ' + run.name
    else:
      item = reuse['groups'].get(g)
      if not item or not item['accepted']:
        out[g] = dict(group=g, available=False, reason='historical source not accepted',
          source_kind='REUSED_HISTORICAL')
        continue
      run = Path(item['source'])
      result = jload(run/'result.json')
      walls = jload(REUSE_DIR/('wall-samples-%s.json' % g))
      kind, label = 'REUSED_HISTORICAL', item['label']
    s, n = SN[g]
    beta = result.get('geometry') and jload(run/'config.json')['model']['beta']
    y = REUSE.common_y()
    layers = walls['layers'] if isinstance(walls['layers'], list) else [walls['layers']]
    samples, port = {}, {}
    for L in layers:
      g_coef = [complex(a, b) for a, b in zip(L['coefficients_re'], L['coefficients_im'])]
      v = REUSE.transfer(g_coef, s, L['p'], beta, y)
      samples[L['p']] = v
      if 'samples_re' in L and kind == 'NEW_RUN':
        mat = [complex(a, b) for a, b in zip(L['samples_re'], L['samples_im'])]
        port['P%d' % L['p']] = max(abs(a - b) for a, b in zip(v, mat))/max(abs(b) for b in mat)
    out[g] = dict(group=g, available=True, source_kind=kind, label=label, run=str(run),
      result=result, samples=samples, port_max_relative_difference=port)
  return out


def science_table(records):
  groups = {}
  rows = []
  for g in GROUPS:
    rec = records[g]
    if not rec['available']:
      groups[g] = dict(group=g, available=False, reason=rec['reason'],
        source_kind=rec['source_kind'])
      continue
    r = rec['result']
    est = r['estimate']
    geo = r['geometry']
    spaces = r['spaces'] if isinstance(r['spaces'], list) else [r['spaces']]
    chains = {c['name']: c for c in r['chains']}
    layers = {L['p']: L for L in r['layers']}
    nu = {p: (layers[p]['nu'] if layers.get(p) and layers[p]['qualified'] else None)
      for p in (2, 3, 4)}
    item = dict(group=g, available=True, s=SN[g][0], n_gamma=SN[g][1],
      source_kind=rec['source_kind'], label=rec['label'], run=rec['run'],
      final_status=r['final_status'], final_reason=r['final_reason'],
      estimate_label=est['label'], S_verified=est['S_verified'], E_certified=est['E_certified'],
      mesh=dict(triangles=r['mesh_identity']['triangles'], p2_nodes=r['mesh_identity']['p2_nodes'],
        flips=(geo.get('flip', {}) or {}).get('accepted', 0) if geo.get('flip_stage_entered') else 0,
        flip_stage_entered=bool(geo.get('flip_stage_entered', False)),
        deletion_outcome=geo.get('deletion_outcome'), det_ratio_max=geo.get('det_ratio_max'),
        geometry_status=geo.get('status')),
      location={rule: dict(points=b['total_points'], failures=b['total_failures'],
        dual=b['total_dual'], tolerance_owner=b['total_tolerance_owner'])
        for rule, b in r['bands'].items() if isinstance(b, dict) and 'total_points' in b},
      orders={})
    nu4 = nu[4]
    d34 = abs(nu[4] - nu[3]) if nu[3] is not None and nu4 is not None else None
    B4 = d34 + FLOOR if d34 is not None else None
    for p in (2, 3, 4):
      L = layers.get(p)
      sp = next((x for x in spaces if x['p'] == p), None)
      prim, chk = chains.get('P%d-primary' % p), chains.get('P%d-check' % p)
      o = dict(p=p, free_dofs=sp['free_dofs'] if sp else None,
        wall_dofs=sp['wall_dofs'] if sp else None,
        status=L['status'] if L else 'NOT_RUN', evaluation_status=L['evaluation_status'] if L else None,
        final_rule=L['final_rule'] if L else None, extra_triggered=L['extra_triggered'] if L else None,
        k=L['k'] if L and L['qualified'] else None, mu=nu[p],
        k_primary=prim['k'] if prim else None, mu_primary=prim['mu'] if prim else None,
        k_check=chk['k'] if chk else None, mu_check=chk['mu'] if chk else None,
        rule_difference=L['rule_difference_primary_check'] if L else None,
        rule_difference_check_extra=L['rule_difference_check_extra'] if L else None,
        bracket_mu_width=L['bracket_mu_width'] if L else None, theta=L['theta'] if L else None,
        mass_status=L.get('mass_status') if L else None,
        frequency_counts={c: chains[c].get('frequency_count') for c in chains
          if chains[c]['p'] == p})
      if p == 4:
        o['B'] = B4
      elif B4 is not None and nu[p] is not None:
        o['B'] = abs(nu[p] - nu4) + B4
      else:
        o['B'] = None
      o['B_note'] = ('B_{g,4} = |nu4-nu3| + 3e-10' if p == 4 else
        'B_{g,p} = |nu_p-nu_4| + B_{g,4} (triangle transfer; cost includes P3/P4 roots)')
      o['k_interval'] = k_interval(nu[p], o['B'])
      item['orders']['P%d' % p] = o
      rows.append(dict(group=g, p=p, source_kind=rec['source_kind'], k=o['k'], mu=o['mu'],
        final_rule=o['final_rule'], rule_difference=o['rule_difference'],
        bracket_mu_width=o['bracket_mu_width'], evaluation_status=o['evaluation_status'],
        free_dofs_center=o['free_dofs'][1] if o['free_dofs'] else None,
        wall_dofs=o['wall_dofs'], B=o['B'],
        k_radius_max=(o['k_interval'] or {}).get('k_radius_max')))
    d23 = abs(nu[3] - nu[2]) if nu[2] is not None and nu[3] is not None else None
    item['d23'], item['d34'] = d23, d34
    item['signed_increment_23'] = nu[3] - nu[2] if d23 is not None else None
    item['signed_increment_34'] = nu[4] - nu[3] if d34 is not None else None
    if d23 is not None and d23 > Q_RATIO_MIN and d34 is not None:
      item['q_obs'] = d34/d23
      item['q_obs_status'] = 'RESOLVED'
      item['saturation_diagnostic'] = ('SATURATION_DIAGNOSTIC_SUPPORTED' if item['q_obs'] <= 0.5
        else 'NOT_SUPPORTED')
    else:
      item['q_obs'] = None
      item['q_obs_status'] = 'UNRESOLVED'
      item['saturation_diagnostic'] = 'UNRESOLVED'
    item['sign_flip'] = (None if d23 is None or d34 is None else
      (item['signed_increment_23'] > 0) != (item['signed_increment_34'] > 0))
    item['B4'] = B4
    item['B4_over_floor'] = B4/FLOOR if B4 is not None else None
    mu0, muN = r['mu0'], est.get('mu_N')
    item['mu0'], item['mu_N'], item['k_N'] = mu0, muN, est.get('k_N')
    item['prediction_status'] = est.get('prediction_status')
    item['R0'] = abs(mu0 - nu4) + B4 if B4 is not None else None
    item['RN'] = abs(muN - nu4) + B4 if B4 is not None and finite(muN) else None
    item['k_interval_nu4'] = k_interval(nu4, B4)
    item['k_interval_mu0'] = k_interval(mu0, item['R0'])
    item['k_interval_muN'] = k_interval(muN, item['RN']) if item['RN'] is not None else None
    item['signed_nu4_minus_mu0'] = nu4 - mu0 if nu4 is not None else None
    item['prediction_nu3_minus_muN'] = (nu[3] - muN if nu[3] is not None and finite(muN) else None)
    # consistency with the MATLAB estimate (same formulas)
    item['matlab_estimate_check'] = dict(
      B4=(B4 - est['B4']) if B4 is not None and finite(est.get('B4')) else None,
      R0=(item['R0'] - est['R0']) if item['R0'] is not None and finite(est.get('R0')) else None,
      RN=(item['RN'] - est['RN']) if item['RN'] is not None and finite(est.get('RN')) else None)
    item['same_mode_within_group'] = r['same_mode']['pairs']
    item['same_mode_pass_23'] = r['same_mode'].get('pass_23')
    item['same_mode_pass_34'] = r['same_mode'].get('pass_34')
    item['evaluation_resolved_P34'] = est.get('evaluation_resolved_P34')
    item['port_max_relative_difference'] = rec['port_max_relative_difference']
    item['matlab_elapsed_at_final_candidate'] = r.get('matlab_elapsed_at_final_candidate')
    groups[g] = item
  return groups, rows


def cross_grid(records, groups):
  avail = [g for g in GROUPS if groups[g].get('available') and 4 in records[g].get('samples', {})]
  anchor = 'g48' if 'g48' in avail else (avail[-1] if avail else None)
  out = dict(anchor=anchor, anchor_note=('g48 (planned anchor)' if anchor == 'g48' else
    'finest available group used as anchor'), y='y_j = -1/2 + j/200, j = 0..200; x = -1/2, +1/2',
    corr_min=CORR_MIN, pairs=[], interval_ratios=[], signed_P4_increments=[])
  if anchor is None:
    return out
  f = records[anchor]['samples'][4]
  m = len(f)//2
  fnorm = math.sqrt(sum(abs(x)**2 for x in f))
  for g in avail:
    if g == anchor:
      continue
    v = records[g]['samples'][4]
    item = dict(group=g, anchor=anchor, concatenated=REUSE.correlation(v, f))
    for name, sl in (('left', slice(0, m)), ('right', slice(m, 2*m))):
      share = math.sqrt(sum(abs(x)**2 for x in v[sl]))/math.sqrt(sum(abs(x)**2 for x in v))
      share_f = math.sqrt(sum(abs(x)**2 for x in f[sl]))/fnorm
      c = REUSE.correlation(v[sl], f[sl])
      item[name] = dict(correlation=c, norm_share_group=share, norm_share_anchor=share_f,
        status='UNRESOLVED_NEAR_ZERO' if min(share, share_f) < 1e-3 else 'RECORDED')
    item['status'] = 'PASS' if item['concatenated'] >= CORR_MIN else 'CROSS_GRID_MODE_UNRESOLVED'
    out['pairs'].append(item)
  for a, b in (('g12', 'g48'), ('g24', 'g48'), ('g12', 'g24')):
    A, B = groups.get(a, {}), groups.get(b, {})
    if not (A.get('available') and B.get('available') and A['B4'] is not None and B['B4'] is not None):
      out['interval_ratios'].append(dict(pair=[a, b], ratio=None, reason='group or B4 unavailable'))
      continue
    nua, nub = A['orders']['P4']['mu'], B['orders']['P4']['mu']
    ratio = abs(nua - nub)/(A['B4'] + B['B4'])
    out['interval_ratios'].append(dict(pair=[a, b], nu4_difference=nua - nub,
      sum_of_radii=A['B4'] + B['B4'], ratio=ratio,
      status='COMPATIBLE_LE_1' if ratio <= 1 else 'INCOMPATIBLE_GT_1',
      note='floating-point diagnostic; <= 1 does not prove S/E, > 1 flags the joint interpretation'))
    out['signed_P4_increments'].append(dict(pair=[a, b], nu4_a_minus_nu4_b=nua - nub,
      k4_a_minus_k4_b=A['orders']['P4']['k'] - B['orders']['P4']['k']))
  return out


def bie_section(groups):
  mu_bie = K_BIE**2
  out = dict(k_bie=K_BIE, mu_bie=mu_bie, note=('external reference only (BIE has its own '
    'discretization error); differences below max(rule difference, mu bracket width, eps_p) '
    'are marked UNDER_RESOLVED'), groups={})
  for g in GROUPS:
    G = groups[g]
    if not G.get('available'):
      out['groups'][g] = None
      continue
    item = dict(orders={})
    for p in (2, 3, 4):
      o = G['orders']['P%d' % p]
      if o['mu'] is None:
        item['orders']['P%d' % p] = None
        continue
      scale = max(abs(o['rule_difference'] or 0), o['bracket_mu_width'] or 0, EPS)
      dmu = abs(o['mu'] - mu_bie)
      item['orders']['P%d' % p] = dict(k_minus_k_bie=o['k'] - K_BIE,
        abs_k_difference=abs(o['k'] - K_BIE), abs_mu_difference=dmu, resolution_scale=scale,
        resolved=dmu > scale, reference_over_B=dmu/o['B'] if o['B'] else None)
    for name, m, R in (('mu0', G['mu0'], G['R0']), ('mu_N', G['mu_N'], G['RN'])):
      if finite(m):
        d = abs(m - mu_bie)
        item[name] = dict(abs_mu_difference=d, abs_k_difference=abs(math.sqrt(m) - K_BIE),
          reference_over_radius=d/R if R else None)
    out['groups'][g] = item
  return out


# ---------------------------------------------------------------------------
def cost_section(records, reuse, summary_started):
  task = jload(ATTEMPT/'task-deadline.json')
  out = dict(groups={}, runs=[], task=dict(start_utc=task['start_utc'],
    deadline_utc=task['deadline_utc'], budget_seconds=task['budget_seconds'],
    elapsed_at_summary_seconds=time.time() - task['start_epoch']))
  for g in GROUPS:
    rec = records[g]
    if not rec['available']:
      out['groups'][g] = dict(source_kind=rec['source_kind'], available=False)
      continue
    run = Path(rec['run'])
    status = jload(run/'status.json')
    timing = jload(run/'timing.json')
    cats = timing['categories']
    pick = lambda names: sum(cats.get(n, 0) for n in names)
    ledger = dict(
      mesh_repair_dofs_checks=pick(['mesh', 'dofs', 'basis_embedding_checks']),
      location_and_KM_assembly=pick(['location'] + [c for c in cats if c.startswith('assembly_')]),
      lead_elimination_qz_dtn=pick(['lead_elimination', 'qz_dtn']),
      center_root=pick(['center_small', 'root_control', 'identity_diagnostic']),
      prediction_recovery_checks=pick(['extension', 'stein_mass', 'recovery_delivery',
        'prediction_mass', 'derivative_check', 'estimate']),
      save_figures=pick(['save', 'figures']),
      unattributed=timing.get('matlab_unattributed_seconds'))
    env = rec['result'].get('environment', {})
    item = dict(source_kind=rec['source_kind'], run=str(run),
      launcher_wall_seconds=status['wall_seconds'], peak_tree_rss_bytes=status['peak_tree_rss_bytes'],
      matlab_function_seconds=timing['matlab_function_seconds'],
      launcher_overhead_seconds=status['wall_seconds'] - timing['matlab_function_seconds'],
      attributed_seconds=timing['attributed_seconds'], ledger_exclusive=ledger,
      ledger_raw=cats, matlab_elapsed_at_final_candidate=rec['result'].get(
        'matlab_elapsed_at_final_candidate'),
      launched_utc=status['launched_utc'], environment=dict(matlab=env.get('matlab_version'),
        platform=env.get('platform'), threads=env.get('max_threads')),
      note=('measured in this task' if rec['source_kind'] == 'NEW_RUN' else
        'historical complete cost of the original run (not re-measured in this task); this '
        'task only read and checked its records'))
    if rec['source_kind'] == 'REUSED_HISTORICAL':
      item['this_task_read_and_check_seconds'] = reuse['groups'][g]['read_and_check_seconds']
    out['groups'][g] = item
  for d in sorted(p for p in ATTEMPT.iterdir() if p.is_dir()):
    st = d/'status.json'
    row = dict(run=d.name)
    if st.exists():
      s = jload(st)
      row.update(reason=s.get('reason'), stop_status=s.get('stop_status'),
        wall_seconds=s.get('wall_seconds'), peak_tree_rss_bytes=s.get('peak_tree_rss_bytes'),
        group=s.get('group'), summarize=s.get('summarize'))
    elif (d/'reuse.json').exists():
      row.update(reason='reuse qualification', wall_seconds=jload(d/'reuse.json')['total_seconds'])
    else:
      row.update(reason='in progress or no status record')
    out['runs'].append(row)
  done = [r for r in out['runs'] if r.get('wall_seconds') is not None]
  out['task_totals'] = dict(
    recorded_run_wall_seconds=sum(r['wall_seconds'] for r in done),
    recorded_runs=[r['run'] for r in done],
    failed_or_stopped_runs=[r['run'] for r in done if r.get('reason') not in
      ('completed', 'reuse qualification')],
    note=('wall of every recorded launcher/reuse run in output/attempt-1 (probe, new runs, '
      'reuse checks, earlier summaries); the running summary is recorded by its own '
      'launcher status.json after this file is written; authoring/debugging time is the '
      'task elapsed time, not a run cost'))
  out['summary_compute_seconds'] = time.monotonic() - summary_started
  return out


def probe_section():
  out = {}
  for g, run in PROBES.items():
    hist = Path(jload(REUSE_DIR/'reuse.json')['groups'][g]['source'])
    if not (run/'result.json').exists():
      out[g] = dict(available=False)
      continue
    a, b = jload(run/'result.json'), jload(hist/'result.json')
    ca = {c['name']: c for c in a['chains']}
    cb = {c['name']: c for c in b['chains']}
    diffs = {n: dict(k=ca[n]['k'] - cb[n]['k'], mu=ca[n]['mu'] - cb[n]['mu']) for n in cb if n in ca}
    out[g] = dict(available=True, probe=str(run), historical=str(hist),
      chain_differences=diffs, bitwise_equal_roots=all(v['k'] == 0 and v['mu'] == 0
        for v in diffs.values()),
      estimate_differences={k: a['estimate'][k] - b['estimate'][k] for k in ('B4', 'R0', 'RN')},
      note='operational equivalence probe of the new kernel on the historical g12 path; '
           'not a replacement of the reused g12 result')
  return out


# ---------------------------------------------------------------------------
# SVG figures (static; light/dark via prefers-color-scheme; native <title> tips).
STYLE = ('<style>.s{--bg:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--grid:#e4e3df;--c1:#2a78d6;'
  '--c2:#eb6834}@media (prefers-color-scheme: dark){.s{--bg:#1a1a19;--ink:#ffffff;'
  '--ink2:#c3c2b7;--grid:#3a3936;--c1:#3987e5;--c2:#d95926}}text{font-family:Helvetica,'
  'Arial,sans-serif;fill:var(--ink2);font-size:12px}.t{fill:var(--ink);font-size:14px}</style>')


def log_axis(lo, hi):
  a, b = math.floor(math.log10(lo)), math.ceil(math.log10(hi))
  return a, b


def svg_plot(path, title, xlabel, ylabel, xs_range, ys_range, series, notes):
  W, H, L, R, T, B = 640, 400, 80, 170, 48, 56
  xa, xb = log_axis(*xs_range)
  ya, yb = log_axis(*ys_range)
  X = lambda x: L + (math.log10(x) - xa)/(xb - xa)*(W - L - R)
  Y = lambda y: H - B - (math.log10(y) - ya)/(yb - ya)*(H - T - B)
  parts = ['<svg xmlns="http://www.w3.org/2000/svg" class="s" width="%d" height="%d" '
    'viewBox="0 0 %d %d" role="img" aria-label="%s">' % (W, H, W, H, title), STYLE,
    '<rect width="100%%" height="100%%" fill="var(--bg)"/>',
    '<text class="t" x="%d" y="24">%s</text>' % (L, title)]
  for e in range(ya, yb + 1):
    y = Y(10**e)
    parts.append('<line x1="%d" x2="%d" y1="%.1f" y2="%.1f" stroke="var(--grid)" '
      'stroke-width="1"/>' % (L, W - R, y, y))
    parts.append('<text x="%d" y="%.1f" text-anchor="end">1e%d</text>' % (L - 6, y + 4, e))
  for e in range(xa, xb + 1):
    x = X(10**e)
    parts.append('<text x="%.1f" y="%d" text-anchor="middle">1e%d</text>' % (x, H - B + 18, e))
    parts.append('<line x1="%.1f" x2="%.1f" y1="%d" y2="%d" stroke="var(--grid)" '
      'stroke-width="1"/>' % (x, x, T, H - B))
  parts.append('<text x="%d" y="%d" text-anchor="middle">%s</text>' % ((L + W - R)//2, H - 14, xlabel))
  parts.append('<text transform="translate(18,%d) rotate(-90)" text-anchor="middle">%s</text>'
    % ((T + H - B)//2, ylabel))
  for n in notes:                               # horizontal reference lines
    y = Y(n['y'])
    parts.append('<line x1="%d" x2="%d" y1="%.1f" y2="%.1f" stroke="var(--ink2)" '
      'stroke-width="1" stroke-dasharray="4 4"/>' % (L, W - R, y, y))
    parts.append('<text x="%d" y="%.1f">%s</text>' % (W - R + 6, y + 4, n['label']))
  for s in series:
    pts = [(X(x), Y(y), d) for x, y, d in s['points']]
    if s.get('line') and len(pts) > 1:
      parts.append('<polyline fill="none" stroke="var(%s)" stroke-width="2" points="%s"/>'
        % (s['color'], ' '.join('%.1f,%.1f' % (a, b) for a, b, _ in pts)))
    for a, b, d in pts:
      fill = 'var(%s)' % s['color'] if d.get('filled', True) else 'var(--bg)'
      parts.append('<circle cx="%.1f" cy="%.1f" r="5" fill="%s" stroke="var(%s)" '
        'stroke-width="2"><title>%s</title></circle>' % (a, b, fill, s['color'], d['tip']))
      if d.get('label'):
        parts.append('<text x="%.1f" y="%.1f">%s</text>' % (a + 9, b - 7, d['label']))
    if s.get('name'):
      a, b, _ = pts[-1]
      parts.append('<text x="%d" y="%.1f" style="fill:var(%s)">%s</text>'
        % (W - R + 6, b + 4, s['color'], s['name']))
  parts.append('</svg>')
  Path(path).write_text('\n'.join(parts) + '\n')


def figures(out_dir, groups, bie, cost):
  fig = out_dir/'figures'
  fig.mkdir(exist_ok=True)
  avail = [g for g in GROUPS if groups[g].get('available') and groups[g]['B4'] is not None]
  dofs = {g: groups[g]['orders']['P4']['free_dofs'][1] for g in avail}
  radius = {g: groups[g]['k_interval_nu4']['k_radius_max'] for g in avail}
  ref = {g: bie['groups'][g]['orders']['P4'] for g in avail}
  s1 = dict(name='conditional k radius of B_g4', color='--c1', line=True, points=[
    (dofs[g], radius[g], dict(tip='%s: k radius %.3e' % (g, radius[g]), label=g)) for g in avail])
  s2 = dict(name='|k_g4 - k_BIE| (external)', color='--c2', line=True, points=[
    (dofs[g], ref[g]['abs_k_difference'], dict(filled=ref[g]['resolved'],
      tip='%s: |k-k_BIE| %.3e%s' % (g, ref[g]['abs_k_difference'],
        '' if ref[g]['resolved'] else ' (under-resolved)'),
      label=None if ref[g]['resolved'] else 'under-resolved')) for g in avail])
  ys = [p[1] for s in (s1, s2) for p in s['points']] + [FLOOR/(2*math.sqrt(K_BIE**2))]
  svg_plot(fig/'radius-vs-size.svg', 'P4 conditional k radius and BIE reference difference',
    'P4 free dofs of the centre template (log)', 'k units (log)',
    (min(dofs.values())/1.5, max(dofs.values())*1.5), (min(ys)/3, max(ys)*3), [s1, s2],
    [dict(y=FLOOR/(2*K_BIE), label='floor 3e-10 (mu) in k')])
  wall = {g: cost['groups'][g]['launcher_wall_seconds'] for g in avail}
  s3 = dict(color='--c1', line=False, points=[(wall[g], radius[g], dict(
    filled=groups[g]['source_kind'] == 'NEW_RUN', label='%s %s' % (g, 'new' if
      groups[g]['source_kind'] == 'NEW_RUN' else 'historical'),
    tip='%s: full launcher wall %.1f s, k radius %.3e' % (g, wall[g], radius[g]))) for g in avail])
  svg_plot(fig/'cost-vs-radius.svg', 'Full launcher cost vs conditional k radius of B_g4',
    'complete launcher wall seconds (log; hollow = historical, not re-measured)',
    'k radius (log)', (min(wall.values())/2, max(wall.values())*2),
    (min(radius.values())/3, max(radius.values())*3), [s3], [])
  return ['figures/radius-vs-size.svg', 'figures/cost-vs-radius.svg']


# ---------------------------------------------------------------------------
def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  args = parser.parse_args()
  started = time.monotonic()
  out = Path(args.output).resolve()
  reuse = jload(REUSE_DIR/'reuse.json')
  records = group_records(reuse)
  groups, rows = science_table(records)
  grid = cross_grid(records, groups)
  science = dict(schema='I102_SCIENCE_V1', label='CONDITIONAL_ON_SATURATION_AND_EVALUATION',
    S_verified=False, E_certified=False, q=0.5, epsilon=[EPS]*3, floor=FLOOR,
    groups=groups, cross_grid=grid, probes=probe_section())
  # freeze the scientific table before the external reference is introduced
  (out/'science.json').write_text(json.dumps(science, indent=2, allow_nan=True) + '\n')
  with (out/'table.csv').open('w', newline='') as handle:
    writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()) + ['abs_k_minus_k_bie',
      'abs_mu_minus_mu_bie', 'bie_resolved'])
    writer.writeheader()
    bie = bie_section(groups)
    for row in rows:
      b = (bie['groups'].get(row['group']) or {}).get('orders', {}).get('P%d' % row['p'])
      row.update(abs_k_minus_k_bie=b and b['abs_k_difference'],
        abs_mu_minus_mu_bie=b and b['abs_mu_difference'], bie_resolved=b and b['resolved'])
      writer.writerow({k: ('' if v is None else v) for k, v in row.items()})
  cost = cost_section(records, reuse, started)
  files = figures(out, groups, bie, cost)
  summary = dict(schema='I102_SUMMARY_V1', science_file='science.json', bie=bie, cost=cost,
    figures=files)
  (out/'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=True) + '\n')
  print(json.dumps({g: dict(status=groups[g].get('final_status'), B4=groups[g].get('B4'))
    for g in GROUPS}))


if __name__ == '__main__':
  main()
