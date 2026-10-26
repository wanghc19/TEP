#!/usr/bin/env python3
"""Post-solve summary of one I9.5b run (design-9-5b D2, Sections 6, 7.1, 7.3).

The historical BIE reference and the E.2 machine timings are frozen constants
here, used only after every MATLAB solve has finished; they are never passed to
MATLAB. A missing coarse control (D2 fine independent entry) is carried as
null delta_h with its status and disclosed at the top. Reads result.json (or partial-result.json / failure.json) and
resources.csv from the run directory; writes summary.json. Standard library only.
"""
import csv
import json
import math
from pathlib import Path
import sys

K_BIE = 1.5584378941820909          # historical BIE reference (summary layer only)
K_E2 = 1.558439927483915            # E.2 FEM candidate = this run's local start k0
E2_TIMINGS = dict(                  # eq-temple-v1/output/attempt-3/run-01/fem/summary.json
  source='test/i9/eq-temple-v1/output/attempt-3/run-01/fem/summary.json',
  algorithm_seconds=2.6523975, mesh_seconds=0.5320042083333333,
  assembly_constraints_seconds=1.015760875, eigensolve_seconds=1.0685265,
  delivery_seconds=0.03610591666666667, matlab_function_seconds_with_save=4.859808875,
  note='finite 17-cell Dirichlet FEM, h=1/24, 160 segments, Q8, one eigs shift; '
       '515.14695675 s is the separate spectral-distance task and is not a baseline')
E2_CONTRACT = ('E.2: finite Dirichlet strip (8 cells per side), one shift-invert eigs, no DtN, '
  'no root bracketing; I9.5b: one centre cell + exact discrete lead DtN, local nonlinear '
  'bracketed root per configuration, coarse/fine/Q-check chains and delivery checks')


def load(path):
  try:
    return json.loads(path.read_text())
  except (OSError, ValueError):
    return None


def finite(value):
  return isinstance(value, (int, float)) and math.isfinite(value)


def summarize(run, launcher=None, launcher_elapsed_before_summary=None):
  run = Path(run)
  result = load(run/'result.json')
  partial = load(run/'partial-result.json')
  failure = load(run/'failure.json')
  launcher = launcher or load(run/'status.json') or {}
  chains = (result or {}).get('chains') or (partial or {}).get('chains') or []
  if isinstance(chains, dict):
    chains = [chains]
  peak = 0
  samples = 0
  try:
    with (run/'resources.csv').open() as handle:
      for row in csv.DictReader(handle):
        samples += 1
        peak = max(peak, int(float(row['rss_bytes'])))
  except OSError:
    pass
  rows = []
  for c in chains:
    k = c.get('k')
    rows.append(dict(name=c.get('name'), status=c.get('status'), qualified=c.get('qualified'),
      k=k, bracket_width=c.get('bracket_width'), lambda_target=c.get('lambda'),
      center_residual=c.get('center_residual'), frequency_count=c.get('frequency_count'),
      precompute_seconds=c.get('precompute_seconds'), root_seconds=c.get('root_seconds'),
      recovery_seconds=c.get('recovery_seconds'),
      matlab_elapsed_at_completion=c.get('matlab_elapsed_at_completion'),
      initialization_source=c.get('initialization_source'),
      geometry_status=c.get('geometry_status'), geometry_failure_kind=c.get('geometry_failure_kind'),
      mesh_structural_checks_pass=c.get('mesh_structural_checks_pass'),
      bie_difference=abs(k-K_BIE) if finite(k) and c.get('qualified') else None,
      bie_signed_difference=(k-K_BIE) if finite(k) and c.get('qualified') else None))
  status = (result or {}).get('final_status')
  if launcher.get('stop_status') == 'RESOURCE_STOP':
    status = 'RESOURCE_STOP'
  elif status is None:
    status = (failure or {}).get('status', 'CELL_OR_DTN_EXCEPTION')
  final_k = (result or {}).get('final_k')
  e2_diff = abs(K_E2-K_BIE)
  interpretation = dict(e2_bie_difference=e2_diff)
  if finite(final_k) and status != 'RESOURCE_STOP':
    final_diff = abs(final_k-K_BIE)
    drop = e2_diff-final_diff
    dq = (result or {}).get('delta_Q16') if finite((result or {}).get('delta_Q16')) \
      else (result or {}).get('delta_Q')
    names = [r['name'] for r in rows]
    final_name = (result or {}).get('final_candidate')
    width = rows[names.index(final_name)]['bracket_width'] if final_name in names else None
    scale = max(v for v in (dq, width, 0.0) if finite(v))
    interpretation.update(final_bie_difference=final_diff, final_signed=final_k-K_BIE,
      drop_vs_e2=drop, resolution_scale=scale,
      label=('reference difference improved' if drop > 0 else 'no improvement')
        + ('' if drop <= 0 or drop > scale else ' (improvement unresolved)'))
  timing = (result or {}).get('timing') or (partial or {}).get('timing') or \
    (failure or {}).get('timing') or {}
  matlab_function = timing.get('matlab_function_seconds')
  process_seconds = launcher.get('matlab_process_seconds')
  account = dict(matlab_internal=timing)
  if finite(process_seconds) and finite(matlab_function):
    account['startup_exit_seconds'] = process_seconds-matlab_function
  if finite(launcher_elapsed_before_summary) and finite(process_seconds):
    account['launcher_other_before_summary_seconds'] = launcher_elapsed_before_summary-process_seconds
  final_elapsed = (result or {}).get('matlab_elapsed_at_final_candidate')
  if finite(final_elapsed) and finite(process_seconds) and finite(matlab_function):
    account['cold_start_to_final_candidate_seconds'] = \
      (process_seconds-matlab_function) + final_elapsed
    account['cold_start_to_final_candidate_note'] = (
      'MATLAB startup (process minus function time, i.e. startup+exit, an upper bound on '
      'startup) + MATLAB elapsed at final candidate checks; excludes figures/save/summary')
  res = result or {}
  unavailable = res.get('coarse_control_unavailable')
  disclosure = None
  if unavailable:
    disclosure = ('NO COARSE/FINE CONTROL: coarse GEOMETRY_FAILED (%s); fine-q10 started '
      'independently from k0 (%s). delta_h and the coarse/fine correlation are '
      'UNAVAILABLE_COARSE_GEOMETRY; spatial stability was not checked.'
      % ((res.get('coarse_failure') or {}).get('failure_kind'),
         res.get('fine_q10_initialization_source')))
  summary = dict(final_status=status, final_reason=(result or {}).get('final_reason'),
    headline_disclosure=disclosure,
    effective_required_chains=res.get('effective_required_chains'),
    coarse_control_unavailable=unavailable,
    coarse_fine_comparison_status=res.get('coarse_fine_comparison_status'),
    two_level_sensitivity_available=res.get('two_level_sensitivity_available'),
    delta_h_status=res.get('delta_h_status'), coarse_failure=res.get('coarse_failure'),
    fine_entry=res.get('fine_entry'), mode=res.get('mode'),
    final_candidate=(result or {}).get('final_candidate'), final_k=final_k,
    final_mu=(result or {}).get('final_mu'), k_bie_reference=K_BIE,
    delta_h=(result or {}).get('delta_h'), delta_Q=(result or {}).get('delta_Q'),
    delta_Q16=(result or {}).get('delta_Q16'), q16_triggered=(result or {}).get('q16_triggered'),
    same_mode=(result or {}).get('same_mode'), configurations=rows,
    interpretation=interpretation, e2_comparison=dict(k_e2=K_E2, timings=E2_TIMINGS,
      contract_difference=E2_CONTRACT),
    timing=account, launcher=launcher, peak_rss_sampled_bytes=peak, rss_samples=samples,
    failure=None if failure is None else dict(stage=failure.get('stage'),
      identifier=failure.get('identifier'), message=failure.get('message')),
    note='ordinary floating-point discrete results; BIE difference is a numerical '
         'reference comparison, not a certified error')
  (run/'summary.json').write_text(json.dumps(summary, indent=2, allow_nan=True) + '\n')
  return summary


if __name__ == '__main__':
  print(json.dumps(summarize(sys.argv[1])['interpretation'], indent=2))
