#!/usr/bin/env python3
"""Post-run machine summary of one I9.6a run (no scientific decisions).

Reads only the run directory written by dtn_bound_i96.m and the launcher
record; writes summary.json and summary.md (identity, native qualification,
gate verdicts, ordinary terms per level, cost ledger). Missing pieces are
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
  lines += ['', '| level | N | M | D0 | delta_u | E_v | c_R E_R | E_y/b_M | eps0 | R_mu | R_k | ordinary | exact |',
    '|---|---|---|---|---|---|---|---|---|---|---|---|---|']
  for level in levels:
    o = level.get('ordinary', {})
    e = level.get('exact', {})
    row = dict(name=level.get('name'), N=level.get('N'), M=level.get('M'), skipped=level.get('skipped'),
      D0=o.get('D0'), delta_u=o.get('delta_u'), E_v=o.get('E_v'), c_R_E_R=o.get('c_R_E_R'),
      E_y_over_b_M=o.get('E_y_over_b_M'), eps0=o.get('eps0'), R_mu=o.get('R_mu'), R_k=o.get('R_k'),
      ordinary_status=o.get('resolution_status'), exact_status=e.get('status'))
    rows.append(row)
    lines.append('| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |' % (
      row['name'], row['N'], row['M'], fmt(row['D0'], '.6e'), fmt(row['delta_u']), fmt(row['E_v']),
      fmt(row['c_R_E_R']), fmt(row['E_y_over_b_M']), fmt(row['eps0']), fmt(row['R_mu']),
      fmt(row['R_k']), row['ordinary_status'], row['exact_status']))
  summary['levels'] = rows
  gates = source.get('gates') or []
  if isinstance(gates, dict):
    gates = [gates]
  summary['gates'] = [dict(level=g.get('level'), closure_supported=g.get('closure_supported'),
    reason=g.get('reason'), seconds=g.get('seconds')) for g in gates]
  if gates:
    lines += ['', 'Gate:']
    for g in gates:
      lines.append('- %s: closure_supported=%s; %s (%.1fs)' % (g.get('level'),
        g.get('closure_supported'), g.get('reason'), g.get('seconds') or 0))
  timing = source.get('timing')
  if timing:
    lines += ['', 'MATLAB exclusive timers (s): ' + ', '.join('%s %s' % (k, fmt(v, '.2f'))
      for k, v in timing.items())]
  (output/'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=True) + '\n')
  (output/'summary.md').write_text('\n'.join(lines) + '\n')
  return summary
