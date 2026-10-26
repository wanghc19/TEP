#!/usr/bin/env python3
"""Summarize one plan-D.1 eq_mm_d1 run: estimate table and mutually exclusive cost views.
Reads only result.json and status.json of the given run (and optional smoke runs);
writes summary.json next to them. No scientific decision is made here.
"""
import argparse
import json
from pathlib import Path

# Stage groups (names are the exclusive MATLAB laps of eq_mm_d1).
COLD = ['input_load', 'tail_recovery', 'recovery_checks', 'partition', 'geometry_space',
  'cache_volume', 'cache_ends', 'mm', 'mm_trace_checks', 'direct_q10_selected', 'save']
WARM_EXCLUDED = ['partition', 'cache_volume', 'cache_ends']
DIAGNOSTIC = ['partition_check', 'baseline_space_checks', 'direct_q10_baseline',
  'baseline_consistency', 'projection', 'direct_q8_baseline', 'direct_q8_selected', 'comparison']
HISTORICAL = dict(candidate_algorithm_seconds=1.45, candidate_process_seconds=16.72,
  run03_partition_seconds=10.9, run03_element_data_seconds=10.8, run03_baseline_solve_seconds=0.5739,
  run03_process_seconds=432.43,
  note='Historical I9.3/I9.5 records; cross-run sums are estimates, and the 432 s run-03 '
  'process (several fluxes and shifts) is not a single-estimate cost.')


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('run')
  parser.add_argument('--smoke', nargs='*', default=[])
  args = parser.parse_args()
  run = Path(args.run)
  result = json.loads((run/'result.json').read_text())
  status = json.loads((run/'status.json').read_text())
  t = result['timings']
  stages = {k: v for k, v in t.items() if k not in ('matlab_function_seconds', 'unattributed_seconds')}
  # direct_q10_selected is absent when the baseline is selected: then the baseline pass is the estimate.
  cold_names = [n for n in COLD if n in stages]
  if 'direct_q10_selected' not in stages:
    cold_names.append('direct_q10_baseline')
  startup = status['wall_seconds'] - t['matlab_function_seconds']
  cold = startup + sum(stages[n] for n in cold_names)
  warm = cold - sum(stages[n] for n in WARM_EXCLUDED if n in stages)
  steps = [dict(step=s['step'], build=s['build_seconds'], assembly=s['solve']['assembly_seconds'],
    solve=s['solve']['solve_seconds'], evaluation=s['evaluation_seconds'], total=s['step_seconds'])
    for s in result['mm_steps']]
  cost = dict(stages=stages, unattributed_seconds=t['unattributed_seconds'],
    matlab_function_seconds=t['matlab_function_seconds'],
    matlab_startup_exit_and_launcher_seconds=startup,
    process_wall_seconds=status['wall_seconds'], peak_process_tree_rss_bytes=status['peak_rss_bytes'],
    mm_steps=steps, projection_solve=result['projection']['solve'],
    research_total_seconds=status['wall_seconds'],
    cold_single_estimate_seconds=cold, cold_components=['startup_exit'] + cold_names,
    warm_single_estimate_seconds=warm,
    warm_definition='cold minus partition and cache build; loading a stored cache is not measured',
    baseline_flux_not_rebuilt='p0 reused from run-03; producing p0 cold would add about '
    'run-03 element data + solve (cross-run estimate)',
    cross_run_cold_with_p0_estimate_seconds=cold + HISTORICAL['run03_element_data_seconds']
    + HISTORICAL['run03_baseline_solve_seconds'],
    diagnostic_only_seconds=sum(stages[n] for n in DIAGNOSTIC if n in stages
      and not (n == 'direct_q10_baseline' and 'direct_q10_selected' not in stages)),
    historical=HISTORICAL)
  smoke = []
  for path in args.smoke:
    s = json.loads((Path(path)/'status.json').read_text())
    smoke.append(dict(run=Path(path).name, wall_seconds=s['wall_seconds'],
      peak_rss_bytes=s['peak_rss_bytes'], exit_code=s['exit_code']))
  d = result['direct']
  table = {}
  for key in ('q10_baseline', 'q10_selected', 'q8_baseline', 'q8_selected'):
    f = d[key]['final']
    b = d[key]['totals']
    table[key] = dict(eta_m=f['eta_m'], bulk=b['bulkB'], end_contribution=b['end_contribution'],
      gradient_difference=f['gradient_difference'], eps2_total=b['eps2_total'],
      osc2_total=b['osc2_total'], weighted_osc_total=b['weighted_osc_total'],
      mean_part_over_s=b['mean_part_over_s'], branch1_elements=b['branch1_elements'],
      end_norms=b['end_norms'], unresolved_area=b['unresolved_area'], mu_R=f['mu_R'], U=f['U'],
      transfer_m_to_mu_R=f['transfer_m_to_mu_R'], eta_R=f['eta_R'], tau_R=f['tau_R'],
      tau_h=f['tau_h'], R_linear_mu_h=f['R_linear_mu_h'], k_interval_linear=f['k_interval_linear'],
      k_halfwidth_linear_first_order=f['k_halfwidth_linear_first_order'], x_T=f['x_T'],
      R_conditional_mu_h=f['R_conditional_mu_h'], k_interval_conditional=f['k_interval_conditional'],
      k_distance_conditional_direct=f['k_distance_conditional_direct'])
  summary = dict(status=result['status'], classification=result['comparison']['classification'],
    selected=result['selected'], estimates=table, comparison=result['comparison']['quantities'],
    projection=dict(sqrt_JP=result['projection']['sqrt_JP'],
      baseline_eps=result['projection']['baseline_eps'], label=result['projection']['label']),
    mm=[dict(step=s['step'], Q_old=s['Q_old'], Q_new=s['Q_new'], F_delta_old=s['F_delta_old'],
      F_delta_new=s['F_delta_new'], F_old=s['F_old'], F_new=s['F_new'], step_length=s['step_length'],
      branch1_frozen=s['branch1_elements_frozen'], branch2_frozen=s['branch2_elements_frozen'],
      majorant_identity_relative=s['majorant_identity_relative'],
      solve_relative_residual=s['solve']['relative_residual']) for s in result['mm_steps']],
    mm_stop=result['mm_stop'], cost=cost, smoke_runs=smoke)
  (run/'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=False) + '\n')
  print(json.dumps(dict(classification=summary['classification'], cold=cold, warm=warm,
    wall=status['wall_seconds'], peak=status['peak_rss_bytes']), indent=1))


if __name__ == '__main__':
  main()
