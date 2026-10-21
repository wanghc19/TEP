#!/usr/bin/env python3
"""Audit saved certificate algebra with exact rational arithmetic.

Purpose: independently check directed scalar assembly, endpoint serialization,
trace formula and run resources. This does not replace the kernel/remainder
proof or validate the numerical library implementation.
Input: one completed run directory; reads only machine-readable scientific data.
Output: a JSON report on stdout. No files are modified.
"""

from fractions import Fraction
import json
from pathlib import Path
import struct
import sys


def endpoint(record, side='upper'):
  value = record[side + '_dyadic']
  return Fraction(int(value['mantissa'])) * Fraction(2) ** value['exponent']


def audit(run_dir):
  data = json.loads((run_dir / 'certificate.json').read_text())
  resources = json.loads((run_dir / 'resource.json').read_text())
  manifest = json.loads((run_dir / 'binary64-input/manifest.json').read_text())
  checks = {}
  balls = 0

  def require(name, condition):
    if not condition:
      raise AssertionError(name)
    checks[name] = True

  def scan(value):
    nonlocal balls
    if isinstance(value, dict):
      if 'lower_dyadic' in value:
        lo, hi = endpoint(value, 'lower'), endpoint(value)
        require('ordered_ball_endpoints', lo <= hi)
        require('exact_decimal_serialization',
                Fraction(value['lower_decimal_exact']) == lo and
                Fraction(value['upper_decimal_exact']) == hi)
        balls += 1
      else:
        for item in value.values():
          scan(item)
    elif isinstance(value, list):
      for item in value:
        scan(item)

  def scalar(name):
    meta = manifest['fields'][name]
    require('scalar_input_' + name, meta['count'] == 1 and not meta['complex'])
    raw = (run_dir / 'binary64-input' / meta['file']).read_bytes()
    return Fraction.from_float(struct.unpack('<d', raw)[0])

  scan(data)
  require('certified_status', data['status'] == 'CERTIFIED_SPECTRAL_DISTANCE_UPPER_BOUND')
  require('all_top_level_gates', all(data['gates'].values()))
  khat = scalar('khat')
  mu = khat * khat
  require('same_exact_mu', endpoint(data['candidate']['mu_exact_khat_squared'], 'lower') <= mu <=
          endpoint(data['candidate']['mu_exact_khat_squared']))
  radius, d = scalar('R'), scalar('d')
  h = min(scalar('delta_c'), scalar('delta_w'))
  rho_min = min(scalar('rho_disk'), scalar('rho_exterior'))
  rho_max = max(scalar('rho_disk'), scalar('rho_exterior'))
  theta = 1 - h / radius
  require('positive_trace_inputs', min(theta, h, mu, rho_min, d) > 0)
  c0, c1 = 1 / (theta * h), h / (2 * theta)
  exact_trace_squared = c0 / (rho_min * mu**2) + (c1 + d*d*c0) / (4*mu) + d*d*c1*rho_max
  C = endpoint(data['trace']['constant_upper'])
  require('rational_trace_upper', C >= 0 and C*C >= exact_trace_squared)
  require('trace_geometry_gates', all(data['trace']['geometry_gates'].values()))

  wall_gates = data['wall']['gates']
  require('wall_structural_gates',
          all(wall_gates[name] for name in ('Dplus_Gplus_near_exact',
              'Dminus_Gminus_near_exact', 'shared_wall_input_selectors_exact',
              'flat_value_multiplier_i_over_2gamma',
              'curve_value_multiplier_inverse_i_gamma')) and
          wall_gates['retained_mode_count'] == 513 and
          wall_gates['first_omitted_absolute_order'] == 257)
  for side in ('plus', 'minus'):
    prop = data['propagation'][side]
    r = endpoint(prop['frobenius_upper'])
    power_sum = endpoint(prop['sum_power_squared_upper'])
    require('propagation_' + side, 0 <= r < 1 and power_sum >= 1/(1-r*r))

  material = data['material']
  material_totals = {}
  for kind in ('value', 'normal'):
    sides = []
    for side in ('minus', 'plus'):
      item = material[kind + '_' + side]
      total = endpoint(item['total_squared'])
      parts = sum(endpoint(item[name]) for name in
                  ('finite_node_squared', 'finite_contour_squared', 'propagation_tail_squared'))
      require('material_' + kind + '_' + side, min(total, parts) >= 0 and total >= parts)
      sides.append(total)
    material_totals[kind] = endpoint(material[kind + '_total_squared'])
    require('material_' + kind + '_sum', material_totals[kind] >= sum(sides))
  wall_totals = {}
  for kind in ('value', 'normal'):
    item = data['wall'][kind]
    total = endpoint(item['total'])
    parts = [endpoint(item[name]) for name in ('singleton', 'finite', 'propagation_tail', 'high_mode')]
    require('wall_' + kind + '_sum', min(parts) >= 0 and total >= sum(parts))
    wall_totals[kind] = total
  value2 = endpoint(data['defect']['value_squared_upper'])
  normal2 = endpoint(data['defect']['normal_squared_upper'])
  require('all_value_interfaces', value2 >= material_totals['value'] + wall_totals['value'])
  require('all_normal_interfaces', normal2 >= material_totals['normal'] + wall_totals['normal'])
  eps2 = endpoint(data['defect']['epsilon_boundary_squared_upper'])
  eps = endpoint(data['defect']['epsilon_boundary_upper'])
  require('paired_norm_weight', eps2 >= normal2 + value2/(d*d))
  require('epsilon_upper_sqrt', eps >= 0 and eps*eps >= eps2)
  U = endpoint(data['mass']['U_lower'], 'lower')
  require('mass_downward_sqrt', 0 < U and U*U <= endpoint(data['mass']['center_mass_squared_lower'], 'lower'))
  require('exact_zero_volume', endpoint(data['defect']['epsilon_volume_exact']) == 0 ==
          endpoint(data['defect']['epsilon_volume_exact'], 'lower'))
  f14 = data['F14']
  Q = endpoint(f14['Q_upper'])
  D = endpoint(f14['denominator_lower'], 'lower')
  R = endpoint(f14['spectral_distance_upper'])
  require('Q_upward', Q >= C*eps)
  require('denominator_downward_positive', 0 < D <= U-Q)
  require('F14_upward', R >= 2*mu*Q/D)
  require('interval_outward', endpoint(f14['interval_lower'], 'lower') <= mu-R and
          endpoint(f14['interval_upper']) >= mu+R)
  require('completed_run', resources['termination'] == 'completed' and resources['return_code'] == 0)
  samples = [json.loads(line) for line in (run_dir/'resource-samples.jsonl').read_text().splitlines()]
  require('monitor_active', bool(samples) and not any('monitor_error' in item for item in samples))
  peak = max(item['process_tree_rss_bytes'] for item in samples)
  require('resource_limits', resources['elapsed_seconds'] <= 2700 and peak < 3_000_000_000)
  require('resource_peak_matches', peak == resources['process_tree_peak_sampled_rss_bytes'])
  return {'status': 'PASS', 'scope': 'exact scalar algebra and resource audit; not kernel proof replacement',
          'ball_records_checked': balls, 'checks': checks,
          'normalized_defect_ratio_diagnostic': float(Q/U),
          'spectral_upper_diagnostic': float(R), 'run_directory': str(run_dir)}


if __name__ == '__main__':
  if len(sys.argv) != 2:
    raise SystemExit('usage: audit_scalar_certificate_v3.py RUN_DIR')
  print(json.dumps(audit(Path(sys.argv[1]).resolve()), indent=2))
