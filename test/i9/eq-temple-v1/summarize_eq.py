#!/usr/bin/env python3
"""Collect I9.5 eq-temple result.json files into one comparison table.

Purpose: read-only post-processing of finished runs; no scientific decisions.
Usage: python3 summarize_eq.py RUN_DIR [RUN_DIR ...] --output summary.json
       python3 summarize_eq.py --e2 RUN_DIR [--smoke SMOKE_DIR ...]
The --e2 form (design-9-5a Section 6) writes RUN_DIR/summary.json: the two-order
estimate table and the exclusive cold cost from mesh generation (FEM summary,
estimator laps, launcher wall clock and peak process-tree RSS).
Each flux row reports Theorem B eta, the B.1 (9) eta, the bulk/end split,
the linear bound at mu_h and the conditional Temple radii for every lambda_plus.
"""
import argparse
import json
from pathlib import Path


def rows(run):
  result = json.loads((run / 'result.json').read_text())
  tail = result.get('tail') or {}
  label = run.name
  if tail.get('glue_cell') is not None:
    label += ' (glue %d, tail %d)' % (tail['glue_cell'], tail['tail_cells'])
  fluxes = result['fluxes']
  if isinstance(fluxes, dict):
    fluxes = [fluxes]
  for flux in fluxes:
    t, s = flux['totals'], flux['scalars']
    x_t = s['x_T'] if isinstance(s['x_T'], list) else [s['x_T']]
    yield dict(run=label, flux=flux['name'], s=flux['s'], eta_B=t['etaB'], eta_9=t['eta9'],
      bulk_B=t['bulkB'], end=t['end_contribution'], eps=t['eps2_total'] ** .5,
      tau_R=s['tau_R'], R_linear=s['R_linear_mu_h'], x_T=x_t, lambda_plus=s['lambda_plus'],
      dist_conditional=s['dist_mu_h_conditional'], mu_R=result['mu_R'], U=result['U'])


# Design 6.6 exclusive stages -> measured laps (FEM laps come from fem/summary.json).
E2_STAGES = [
  ('fem_mesh_assembly_solve_screen_save', ['fem']),
  ('candidate_tail_qualification', ['candidate_input', 'tail']),
  ('geometry_partition', ['geometry_space', 'partition']),
  ('ls_condense_solve_recover_checks', ['ls_assembly_condense', 'ls_factor_solve', 'ls_recovery',
    'ls_residual_rebuild', 'trace_checks']),
  ('direct_q10', ['direct_q10']),
  ('direct_q8', ['direct_q8']),
  ('startup_exit_comparison_save_other', ['startup', 'comparison', 'save', 'unattributed_seconds'])]
E2_DIAGNOSTIC = ['reference_similarity']


def e2(run, smokes):
  result = json.loads((run/'result.json').read_text())
  status = json.loads((run/'status.json').read_text())
  fem = json.loads((run/'fem'/'summary.json').read_text())['timings']
  laps = dict(result['timings'])
  laps['fem'] = fem['matlab_function_seconds']
  laps['startup'] = status['wall_seconds'] - fem['matlab_function_seconds'] - laps['matlab_function_seconds']
  stages = {name: sum(laps.get(k, 0) for k in keys) for name, keys in E2_STAGES}
  diagnostic = {k: laps[k] for k in E2_DIAGNOSTIC if k in laps}
  smoke = []
  for path in smokes:
    st = json.loads((Path(path)/'status.json').read_text())
    smoke.append(dict(run=Path(path).name, wall_seconds=st['wall_seconds'],
      peak_rss_bytes=st['peak_rss_bytes'], exit_code=st['exit_code']))
  table = {}
  for q in ('q10', 'q8'):
    f = result['direct'][q]
    table[q] = {k: f[k] for k in ('order', 'end_order', 'eta_m', 'U', 'mu_R', 'tau_h', 'R', 'k_interval',
      'gradient_difference', 'mean_part_over_s', 'osc2_total', 'weighted_osc_total', 'end_contributions',
      'bulk', 'unresolved_area', 'conditional', 'seconds')}
  summary = dict(status=result['status'], candidate=result['candidate'], estimates=table,
    comparison=result['comparison'], cost=dict(exclusive_stages=stages,
    diagnostic_only=diagnostic, fem_laps=fem, estimator_laps=result['timings'],
    process_wall_seconds=status['wall_seconds'], peak_process_tree_rss_bytes=status['peak_rss_bytes'],
    sum_check_seconds=sum(stages.values()) + sum(diagnostic.values())), smoke_runs=smoke)
  (run/'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=False) + '\n')
  print(json.dumps(dict(stages=stages, diagnostic=diagnostic, wall=status['wall_seconds'],
    peak=status['peak_rss_bytes']), indent=1))


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('runs', nargs='*')
  parser.add_argument('--output')
  parser.add_argument('--e2', help='E.2 run directory (writes summary.json there)')
  parser.add_argument('--smoke', nargs='*', default=[])
  args = parser.parse_args()
  if args.e2:
    e2(Path(args.e2), args.smoke)
    return
  if not args.runs or not args.output:
    parser.error('RUN_DIR ... and --output are required without --e2')
  table = [row for run in args.runs for row in rows(Path(run))]
  Path(args.output).write_text(json.dumps(table, indent=2) + '\n')
  print('| run | flux | s | eta_B | eta_9 | bulk_B | end | R_lin(mu_h) | x_T(4.785) | x_T(4) | x_T(3) |')
  print('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|')
  for r in table:
    print('| %s | %s | %.4f | %.5f | %.5f | %.5f | %.5f | %.5f | %.3e | %.3e | %.3e |' % (
      r['run'], r['flux'], r['s'], r['eta_B'], r['eta_9'], r['bulk_B'], r['end'], r['R_linear'],
      *r['x_T'][:3]))
  best = min((r for r in table if r['flux'] != 'i94_average_witness'), key=lambda r: r['x_T'][0])
  lin = min((r for r in table if r['flux'] != 'i94_average_witness'), key=lambda r: r['R_linear'])
  print('\nbest conditional x_T(4.785): %.6e (%s, %s)' % (best['x_T'][0], best['run'], best['flux']))
  print('best unconditional R_linear: %.6e (%s, %s)' % (lin['R_linear'], lin['run'], lin['flux']))


if __name__ == '__main__':
  main()
