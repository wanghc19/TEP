#!/usr/bin/env python3
"""Post-run machine summary of one I9.6a run (no scientific decisions).

Reads only the run directory written by dtn_bound_i96.m and the launcher
record; writes summary.json and summary.md (identity, native qualification,
pilot and self-test verdicts, D2 intervals and ordinary column per level,
acceptance answers, cost ledger). Missing pieces are
recorded as missing, never filled in.
"""
import json
import math
from pathlib import Path


def load(path):
  try:
    return json.loads(path.read_text())
  except (OSError, ValueError):
    return None


def fmt(value, spec='.3e'):
  if isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value):
    return format(value, spec)
  return str(value)


def summarize(output, launcher, launcher_seconds_before_summary):
  output = Path(output)
  result = load(output/'result.json')
  failure = load(output/'failure.json')
  partial = load(output/'partial-result.json')
  summary = dict(launcher=launcher, launcher_seconds_before_summary=launcher_seconds_before_summary,
    result_present=result is not None, failure=failure)
  lines = ['# I9.6a run summary (machine)', '']
  lines.append('- launcher exit: %s; reason: %s; stop: %s' % (launcher.get('exit_code'),
    launcher.get('reason'), launcher.get('stop_status')))
  lines.append('- MATLAB process seconds: %s; peak process-tree RSS: %s bytes' % (
    fmt(launcher.get('matlab_process_seconds'), '.1f'), launcher.get('peak_rss_bytes')))
  if failure:
    lines.append('- failure at stage `%s`: %s (%s)' % (failure.get('stage'),
      failure.get('identifier'), failure.get('message')))
  source = result or partial or {}
  if result:
    summary.update(final_status=result.get('final_status'), final_reason=result.get('final_reason'),
      input_identity=result.get('input_identity'), timing=result.get('timing'))
    native = result.get('native', {})
    lines += ['- final status: `%s` (%s)' % (result.get('final_status'), result.get('final_reason')),
      '- input identity: `%s`' % result.get('input_identity'),
      '- native: lambda %s, centre residual %s, gap %s, U0 %s' % (fmt(native.get('lambda')),
        fmt(native.get('center_residual')), fmt(native.get('target_gap')), fmt(native.get('U0'), '.15f'))]
  levels = source.get('levels') or []
  if isinstance(levels, dict):
    levels = [levels]
  rows = []
  lines += ['', 'D2 exact-arithmetic intervals and ordinary column (per level):', '',
    '| level | N | M | status | D0^- | delta_u^+ | E_v^+ | c_R E_R^+ | moment | E_y^+/b_M | eps0^+ | R_mu | R_k | R_k ordinary | correction | engine stops |',
    '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
  for level in levels:
    o = level.get('ordinary') or {}
    e = level.get('exact') or {}
    c = level.get('correction') or {}
    eng = level.get('engine') or []
    if isinstance(eng, dict):
      eng = [eng]
    def lo(key):
      v = e.get(key)
      return v[0] if isinstance(v, list) and v else v
    def hi(key):
      v = e.get(key)
      return v[-1] if isinstance(v, list) and v else v
    row = dict(name=level.get('name'), N=level.get('N'), M=level.get('M'),
      completed=level.get('completed'), skip_reason=level.get('skip_reason'),
      status=e.get('status'), reason=e.get('reason'), D0_lo=lo('D0'), delta_u_hi=hi('delta_u'),
      E_v_hi=hi('E_v'), c_R_E_R=e.get('c_R_E_R'), moment_term=e.get('moment_term'),
      E_y_over_b_M=e.get('E_y_over_b_M'), eps0=e.get('eps0'), R_mu=e.get('R_mu'), R_k=e.get('R_k'),
      R_k_ordinary=o.get('R_k'), failed_budgets=e.get('failed_budgets'),
      correction=c.get('decision'), T0=c.get('T0'), T1=c.get('T1'),
      engine_stops=[x.get('stop') for x in eng], seconds=level.get('seconds'))
    rows.append(row)
    lines.append('| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (
      row['name'], row['N'], row['M'], row['status'], fmt(row['D0_lo'], '.9f'), fmt(row['delta_u_hi']),
      fmt(row['E_v_hi']), fmt(row['c_R_E_R']), fmt(row['moment_term']), fmt(row['E_y_over_b_M']),
      fmt(row['eps0']), fmt(row['R_mu']), fmt(row['R_k']), fmt(row['R_k_ordinary']), row['correction'],
      ','.join(map(str, row['engine_stops']))))
  summary['levels'] = rows
  for row in rows:
    if row['reason'] or row['skip_reason']:
      lines.append('- %s: %s %s' % (row['name'], row['reason'] or '', row['skip_reason'] or ''))
  pilot = source.get('pilot') or load(output/'pilot.json')
  if pilot:
    summary['pilot'] = dict(passed=pilot.get('pass'), reason=pilot.get('reason'),
      closure_prediction=pilot.get('closure_prediction'), seconds=pilot.get('seconds'))
    lines += ['', '- pilot: pass=%s; %s; closure %s (%s s)' % (pilot.get('pass'), pilot.get('reason'),
      pilot.get('closure_prediction'), fmt(pilot.get('seconds'), '.1f'))]
  selftest = source.get('selftest') or load(output/'selftest.json')
  if selftest:
    summary['selftest'] = dict(passed=selftest.get('pass'), reason=selftest.get('reason'))
    lines.append('- selftest: pass=%s %s' % (selftest.get('pass'), selftest.get('reason') or ''))
  if source.get('acceptance'):
    summary['acceptance'] = source['acceptance']
    lines += ['', 'Acceptance answers (machine):']
    lines += ['- %s: %s' % (k, v) for k, v in source['acceptance'].items()]
  timing = source.get('timing')
  if timing:
    lines += ['', 'MATLAB exclusive timers (s): ' + ', '.join('%s %s' % (k, fmt(v, '.2f'))
      for k, v in timing.items())]
  (output/'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=True) + '\n')
  (output/'summary.md').write_text('\n'.join(lines) + '\n')
  return summary
