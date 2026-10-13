#!/usr/bin/env python3
"""Certify I7.4 geometric, propagation, wall-tail, mass, and scalar pieces.

Purpose: use the I6 Arb endpoint helpers to recompute exact mu=khat*khat,
the ellipse/circle collar constant, full propagation contraction, omitted
wall modes, and same-field safe-disk mass. F14 still uses a numerical jump
estimate: unclosed continuous material/wall action errors stay explicit.
Input: a newly computed EPOST_I7_RESOLVENT_V1_NUMERICAL_INPUT JSON file.
Output: a create-once JSON report with exact dyadic endpoints and status.
Based on: I6 resolvent-v3 trace_constant, ball_record, and F14 scalar chain.
Main changes: ellipse curvature/reach and actual material separations replace
the circle-only geometry. No empty-center mass formula is used.
"""

from fractions import Fraction
import json
import math
from pathlib import Path
import sys

from flint import arb, acb, acb_mat
from arb_common_v3 import ball_record, exp_i


def LOCAL_scalar(value):
  """Lift a finite binary64 input as its exact real dyadic value."""
  value = float(value)
  if not math.isfinite(value):
    raise ValueError("nonfinite numerical input")
  result = arb(value)
  if result.rad() != 0:
    raise ValueError("input was not lifted exactly")
  return result


def LOCAL_propagation(data):
  """Bound the full frozen matrices; this does not bound interface actions."""
  report = {}
  for side in ('plus', 'minus'):
    real, imag = data[side]['real'], data[side]['imag']
    if len(real) != 97 or len(imag) != 97 or \
        any(len(row) != 97 for row in real + imag):
      raise ValueError('frozen M=48 propagation matrix shape')
    squared = arb(0)
    for rrow, irow in zip(real, imag):
      for rpart, ipart in zip(rrow, irow):
        r, i = LOCAL_scalar(rpart), LOCAL_scalar(ipart)
        squared += r * r + i * i
    squared = squared.upper()
    passed = bool(squared < 1)
    report[side] = {
      'frobenius_squared_upper': ball_record(squared),
      'frobenius_upper': ball_record(squared.sqrt().upper()),
      'strict_contraction': passed,
      'sum_power_squared_upper': ball_record((1 / (1 - squared)).upper())
        if passed else None,
    }
  return report


def LOCAL_fro(data):
  """Outward Euclidean/Frobenius norm of frozen complex binary64 entries."""
  real, imag = data['real'], data['imag']
  if real and not isinstance(real[0], list):
    real, imag = [real], [imag]
  if len(real) != len(imag):
    raise ValueError('complex array shape')
  squared = arb(0)
  for rrow, irow in zip(real, imag):
    if len(rrow) != len(irow):
      raise ValueError('complex array row shape')
    for rpart, ipart in zip(rrow, irow):
      r, i = LOCAL_scalar(rpart), LOCAL_scalar(ipart)
      squared += r * r + i * i
  return squared.sqrt().upper()


def LOCAL_wall_tail(data, propagation_data, k, beta, d, a, radius):
  """Bound all omitted wall modes of the frozen continuous raw field.

  The shape-general positive-distance Rayleigh bound uses L1 density
  estimates from discrete Parseval and the full propagation contraction.
  It is reported separately: physical full-node wall quadrature already
  samples these modes, so this tail is not added again to that estimate.
  """
  n = 256
  center, lead = data['center_density'], data['lead_density_map']
  for name in ('real', 'imag'):
    if len(center[name]) != 2 * n or any(isinstance(x, list) for x in center[name]):
      raise ValueError('wall-tail center density shape')
    if len(lead[name]) != 2 * n or any(len(row) != 194 for row in lead[name]):
      raise ValueError('wall-tail lead density-map shape')
    for side in ('plus', 'minus'):
      G, c = data['G' + side][name], data['c' + side][name]
      if len(G) != 194 or any(len(row) != 97 for row in G):
        raise ValueError('wall-tail cell input-map shape')
      if len(c) != 97 or any(isinstance(x, list) for x in c):
        raise ValueError('wall-tail propagation state shape')

  def part(array, first, last):
    return {name: array[name][first:last] for name in ('real', 'imag')}

  center_tau = 2 * arb.pi() * a * LOCAL_fro(part(center, 0, n)) / arb(n).sqrt()
  center_zeta = 2 * arb.pi() * a * LOCAL_fro(part(center, n, 2 * n)) / arb(n).sqrt()
  lead_tau = 2 * arb.pi() * radius * LOCAL_fro(part(lead, 0, n)) / arb(n).sqrt()
  lead_zeta = 2 * arb.pi() * radius * LOCAL_fro(part(lead, n, 2 * n)) / arb(n).sqrt()

  def energy(tau, zeta, delta):
    N = 49
    q0 = 2 * arb.pi() / d
    t = q0 * N - abs(beta)
    if not (delta > 0 and t > k):
      raise ValueError('wall-tail separation or evanescence')
    decay = (t * t - k * k).sqrt()
    r = (-2 * delta * q0).exp()
    rN = r ** N
    S0 = rN / (1 - r)
    S1 = rN * (N / (1 - r) + r / ((1 - r) ** 2))
    S2 = rN * (N * N / (1 - r) + 2 * N * r / ((1 - r) ** 2)
               + r * (1 + r) / ((1 - r) ** 3))
    H = (1 + t / decay) * tau + zeta / decay
    C = 2 * abs(beta) * tau + zeta
    factor = (2 * delta * (k + abs(beta))).exp() / (2 * d)
    value = factor * H * H * S0
    normal = factor * (4 * q0 * q0 * tau * tau * S2
                       + 4 * q0 * tau * C * S1 + C * C * S0)
    return value.upper(), normal.upper()

  center_value, center_normal = energy(center_tau, center_zeta, arb(1) / 2 - a)
  total_value, total_normal = arb(0), arb(0)
  sides = {}
  for side in ('plus', 'minus'):
    rho = LOCAL_fro(propagation_data[side])
    if not rho < 1:
      raise ValueError('wall-tail full propagation contraction')
    amplitude = LOCAL_fro(data['G' + side]) * LOCAL_fro(data['c' + side])
    lead_value, lead_normal = energy(
      lead_tau * amplitude, lead_zeta * amplitude, arb(1) / 2 - radius)
    interface_value = (center_value.sqrt() + lead_value.sqrt()) ** 2
    interface_normal = (center_normal.sqrt() + lead_normal.sqrt()) ** 2
    internal_factor = (1 + rho) ** 2 / (1 - rho * rho)
    internal_value = lead_value * internal_factor
    internal_normal = lead_normal * internal_factor
    total_value += interface_value + internal_value
    total_normal += interface_normal + internal_normal
    sides[side] = {
      'center_wall_value_squared_upper': ball_record(interface_value.upper()),
      'center_wall_normal_squared_upper': ball_record(interface_normal.upper()),
      'all_internal_walls_value_squared_upper': ball_record(internal_value.upper()),
      'all_internal_walls_normal_squared_upper': ball_record(internal_normal.upper()),
    }
  return {
    'retained_M': 48,
    'center_tau_L1_upper': ball_record(center_tau.upper()),
    'center_zeta_L1_upper': ball_record(center_zeta.upper()),
    'value_squared_upper': ball_record(total_value.upper()),
    'normal_squared_upper': ball_record(total_normal.upper()),
    'sides': sides,
    'certified_for_frozen_continuous_density_definition': True,
    'included_again_in_physical_quadrature_total': False,
    'scope': 'Only |m|>48 on all walls; retained wall-mode errors remain unclosed.',
  }


def LOCAL_mass(data, qdata, k, beta, d, a, b):
  """Certify a same-field safe-disk mass via exact QP Rayleigh coefficients.

  This disk lies to the right of every source. Source trapezoid errors use
  an analytic parameter strip; positive-distance geometric sums enclose
  all omitted Rayleigh modes. No MFS values enter this lower bound.
  """
  from certify_resolvent_v3 import exact_dft_operator
  density = data['center_density']
  for name in ('real', 'imag'):
    if len(density[name]) != 512 or any(isinstance(x, list) for x in density[name]):
      raise ValueError('mass density shape')
    if len(qdata[name]) != 194 or any(isinstance(x, list) for x in qdata[name]):
      raise ValueError('mass incident amplitude shape')
  eta = acb_mat(512, 1)
  for n, (real, imag) in enumerate(zip(density['real'], density['imag'])):
    eta[n, 0] = acb(LOCAL_scalar(real), LOCAL_scalar(imag))
  orders, tau_dft, zeta_dft = exact_dft_operator(eta)
  # interpft splits the even-grid Nyquist coefficient between +/-128.
  tau = [tau_dft[j, 0] for j in range(256)]
  zeta = [zeta_dft[j, 0] for j in range(256)]
  tau[0] /= 2
  zeta[0] /= 2
  tau.append(tau[0])
  zeta.append(zeta[0])
  orders = orders + [128]
  N = 512
  alpha, xstar, radius = arb(1) / 10, arb(3) / 8, arb(1) / 16
  cosh, sinh = alpha.cosh(), alpha.sinh()
  speed_lower = (a * a + b * b - (a * a - b * b) * (2 * alpha).cosh()) / 2
  if not (speed_lower > 0 and xstar - radius - a * cosh > b * sinh):
    raise ValueError('mass analytic-strip or source/disk separation')
  # v(z)^2=c-d*cos(2z), so |v(z)^2| <= c+d*cosh(2*alpha).
  vstrip = ((a * a + b * b + (a * a - b * b) * (2 * alpha).cosh()) / 2).sqrt()
  nodal_tau = LOCAL_fro({name: density[name][:256] for name in ('real', 'imag')}) / 16
  nodal_zeta = LOCAL_fro({name: density[name][256:] for name in ('real', 'imag')}) / 16
  strip_factor = arb(257).sqrt() * (128 * alpha).exp()
  tau_strip, zeta_strip = nodal_tau * strip_factor, nodal_zeta * strip_factor
  nodes = []
  for n in range(N):
    t = 2 * arb.pi() * n / N
    cs, sn = t.cos(), t.sin()
    powers = [exp_i(order * t) for order in orders]
    tau_value = sum((c * p for c, p in zip(tau, powers)), acb(0))
    zeta_value = sum((c * p for c, p in zip(zeta, powers)), acb(0))
    speed = (a * a * sn * sn + b * b * cs * cs).sqrt()
    nodes.append((cs, sn, speed, tau_value, zeta_value))
  q = [acb(LOCAL_scalar(r), LOCAL_scalar(i))
       for r, i in zip(qdata['real'], qdata['imag'])]
  value = acb(0)
  gradient = arb(0)
  quadrature_error_sum = arb(0)
  for index, m in enumerate(range(-48, 49)):
    bm = beta + 2 * arb.pi() * m / d
    gamma = acb(k * k - bm * bm).sqrt()
    if not abs(gamma).lower() > 0:
      raise ValueError('mass Rayleigh Wood denominator')
    coefficient = acb(0)
    for cs, sn, speed, tau_value, zeta_value in nodes:
      phase = exp_i(gamma * (xstar - a * cs) - bm * b * sn)
      integrand = acb(0, 1) / (2 * d * gamma) * phase * (
        -acb(0, 1) * (gamma * b * cs + bm * a * sn) * tau_value
        - speed * zeta_value)
      coefficient += integrand
    coefficient *= 2 * arb.pi() / N
    exponent = (-gamma.imag * (xstar - a * cosh)
                + abs(gamma.real) * a * sinh + abs(bm) * b * sinh)
    Mstrip = exponent.exp() / (2 * d * abs(gamma)) * (
      (abs(gamma) * b + abs(bm) * a) * cosh * tau_strip
      + vstrip * zeta_strip)
    error = (4 * arb.pi() * Mstrip / ((alpha * N).exp() - 1)).upper()
    coefficient += acb(arb(0, error), arb(0, error))
    quadrature_error_sum += error
    value += coefficient
    gradient += (abs(gamma) + abs(bm)) * abs(coefficient) * (gamma.imag * radius).exp()
    left = q[index] * exp_i(gamma * (xstar + arb(1) / 2)) / d.sqrt()
    right = q[97 + index] * exp_i(-gamma * (xstar - arb(1) / 2)) / d.sqrt()
    value += left + right
    gradient += (abs(gamma) + abs(bm)) * (abs(left) + abs(right)) * (gamma.imag * radius).exp()
  A_tau, A_zeta = 2 * arb.pi() * a * nodal_tau, 2 * arb.pi() * a * nodal_zeta

  def omitted(delta):
    first, q0 = 49, 2 * arb.pi() / d
    tfirst = q0 * first - abs(beta)
    decay = (tfirst * tfirst - k * k).sqrt()
    H = (1 + tfirst / decay) * A_tau + A_zeta / decay
    r = (-delta * q0).exp()
    S0 = r ** first / (1 - r)
    S1 = r ** first * (first / (1 - r) + r / ((1 - r) ** 2))
    factor = (delta * (k + abs(beta))).exp() * H / d
    return (factor * S0).upper(), (2 * factor * (q0 * S1 + abs(beta) * S0)).upper()

  point_tail, _ = omitted(xstar - a)
  _, gradient_tail = omitted(xstar - radius - a)
  value += acb(arb(0, point_tail), arb(0, point_tail))
  point_lower = abs(value).lower()
  gradient_upper = (gradient + gradient_tail).upper()
  margin = (point_lower - radius * gradient_upper).lower()
  U = (arb.pi().sqrt() * radius * max(arb(0), margin)).lower()
  return {
    'certified_same_raw_field_mass_lower': True,
    'positive_lower_bound': bool(U > 0),
    'density_interpolation': '256-node trig interpolant with split +/-128 Nyquist',
    'source_nodes': N, 'retained_M': 48,
    'point_value_real': ball_record(value.real),
    'point_value_imag': ball_record(value.imag),
    'point_abs_lower': ball_record(point_lower),
    'disk_gradient_upper': ball_record(gradient_upper),
    'point_source_quadrature_error_sum_upper': ball_record(quadrature_error_sum.upper()),
    'point_mode_tail_upper': ball_record(point_tail),
    'gradient_mode_tail_upper': ball_record(gradient_tail),
    'cone_margin_lower': ball_record(margin),
    'Uunder': ball_record(U),
  }, U


def certify(input_path, output_path):
  data = json.loads(Path(input_path).read_text())
  if data['schema'] != 'EPOST_I7_RESOLVENT_V1_NUMERICAL_INPUT':
    raise ValueError('unexpected numerical input schema')
  model = data['model']
  frozen = {'khat': 1.755995740875, 'beta': 0.5, 'd': 1.0, 'L': 1.0,
            'R': 0.2, 'rho_center': 2.0, 'rho_lead': 17.0,
            'rho_exterior': 1.0, 'X_L': -0.5, 'X_R': 0.5,
            'delta_c': 0.04, 'delta_w': 0.04}
  if any(float(model[name]) != value for name, value in frozen.items()) or \
      [float(value) for value in model['axes']] != [0.25, 0.16]:
    raise ValueError('input differs from the frozen I7.4 model or collar')
  k = LOCAL_scalar(model['khat'])
  beta = LOCAL_scalar(model['beta'])
  d, L, radius = [LOCAL_scalar(model[name]) for name in ('d', 'L', 'R')]
  a, b = [LOCAL_scalar(value) for value in model['axes']]
  delta_c, delta_w = [LOCAL_scalar(model[name]) for name in ('delta_c', 'delta_w')]
  xleft, xright = [LOCAL_scalar(model[name]) for name in ('X_L', 'X_R')]
  densities = [LOCAL_scalar(model[name]) for name in
               ('rho_exterior', 'rho_center', 'rho_lead')]
  if not (a >= b > 0 and radius > 0 and d > 0 and L > 0 and k > 0
          and delta_c > 0 and delta_w > 0 and min(densities) > 0):
    raise ValueError('nonpositive model or geometry')
  mu = k * k
  h = min(delta_c, delta_w)
  curvature = max(a / (b * b), 1 / radius)
  theta = 1 - h * curvature
  # Disjoint bounding boxes suffice for different material/flat-wall collars.
  geometry = {
    'ellipse_normal_tube': bool(h < b * b / a),
    'circle_normal_tube': bool(h < radius),
    'positive_jacobian': bool(theta > 0),
    'center_wall': bool(min(-xleft - a, xright - a) > h + delta_w),
    'lead_wall': bool(L / 2 - radius > h + delta_w),
    'center_lead': bool(L - a - radius > 2 * h),
    'lead_copies_x': bool(L - 2 * radius > 2 * h),
    'center_copies_y': bool(d - 2 * b > 2 * h),
    'lead_copies_y': bool(d - 2 * radius > 2 * h),
    'wall_pairs': bool(min(L, xright - xleft) > 2 * delta_w),
  }
  if not all(geometry.values()):
    raise ValueError('ellipse/circle collar geometry failed')
  # These nonvanishing gates are necessary, not quadrature remainder bounds.
  alpha = arb(1) / 5
  speed_squared_lower = ((a * a + b * b) / 2
                         - (a * a - b * b) * (2 * alpha).cosh() / 2).lower()
  strip_wall_clearance = (min(-xleft, xright) - a * alpha.cosh()).lower()
  c0 = 1 / (theta * h)
  c1 = h / (2 * theta)
  c_squared = (c0 / (min(densities) * mu * mu)
               + (c1 + d * d * c0) / (4 * mu)
               + d * d * c1 * max(densities))
  C = c_squared.sqrt().upper()
  eps = LOCAL_scalar(data['epsilon_boundary'])
  U = LOCAL_scalar(data['U_lower_candidate'])
  sampled_U = U
  if not (eps >= 0 and U >= 0):
    raise ValueError('negative mass or jump estimate')
  Q = (C * eps).upper()
  denominator = (U - Q).lower()
  k_fraction = Fraction.from_float(float(model['khat']))
  mu_fraction = k_fraction * k_fraction
  structure = data['structure']
  required = ('piecewise_pde_exact', 'quasiperiodic_exact', 'square_integrable')
  propagation = LOCAL_propagation(data['propagation']) if 'propagation' in data else None
  propagation_pass = propagation is not None and all(
    propagation[side]['strict_contraction'] for side in ('plus', 'minus'))
  structure_pass = (all(structure.get(name) is True for name in required)
                    and propagation_pass)
  wall_tail = LOCAL_wall_tail(data['wall_tail_data'], data['propagation'],
                             k, beta, d, a, radius) \
    if 'wall_tail_data' in data and propagation_pass else None
  mass_certificate = None
  if 'q' in data:
    if wall_tail is None:
      raise ValueError('mass requires validated frozen density and propagation inputs')
    mass_certificate, U = LOCAL_mass(data['wall_tail_data'], data['q'], k, beta, d, a, b)
    denominator = (U - Q).lower()
  unresolved = [
    'continuous material-curve jump norm upper bounds, including stored-density versus Hmap*q evaluation roundoff',
    'complete wall jump upper bounds: retained modes and numerical evaluation errors',
    'complete infinite-cell action tail upper bounds',
  ]
  if mass_certificate is None:
    unresolved.append('same-raw-field mass lower bound')
  report = {
    'schema': 'EPOST_I7_RESOLVENT_V1_SCALAR_REPORT',
    'status': 'UNCERTIFIED_F14_ESTIMATE',
    'continuous_spectrum_bound_certified': False,
    'model_binary64': model,
    'certified_scope': 'exact mu, collar/strip geometry, full propagation contraction, and conditional scalar composition; wall tail and same-field mass if reported',
    'mu_exact_fraction': str(mu_fraction),
    'mu': ball_record(mu), 'beta': ball_record(beta),
    'trace': {'curvature_upper': ball_record(curvature.upper()),
              'ellipse_reach': ball_record(b * b / a),
              'theta': ball_record(theta), 'c0': ball_record(c0),
              'c1': ball_record(c1), 'C_squared': ball_record(c_squared),
              'Cbar': ball_record(C), 'geometry_gates': geometry},
    'ellipse_analytic_strip': {
      'width': ball_record(alpha),
      'speed_squared_real_part_lower': ball_record(speed_squared_lower),
      'chord_factor_real_part_lower': ball_record(speed_squared_lower),
      'wall_real_clearance_lower': ball_record(strip_wall_clearance),
      'nonvanishing_gates': bool(speed_squared_lower > 0 and strip_wall_clearance > 0),
      'continuous_quadrature_remainder_certified': False,
    },
    'epsilon_input_candidate': ball_record(eps),
    'U_input_candidate': ball_record(sampled_U),
    'U_used_in_formula': ball_record(U),
    'same_field_mass_certificate': mass_certificate,
    'Q_conditional_upper': ball_record(Q),
    'denominator_conditional_lower': ball_record(denominator),
    'structure': structure,
    'structure_pass': structure_pass,
    'propagation_arithmetic': propagation,
    'omitted_wall_modes': wall_tail,
    'numerical_input_caveats': data['unresolved_certification'],
    'unresolved_certification': unresolved,
    'not_certified_by_this_script': unresolved,
    'components': data['components'],
    'R_spec_estimate': None,
    'spectral_parameter_interval_estimate': None,
    'warning': 'Epsilon is not a certified upper bound. U_used is a certified lower bound only when same_field_mass_certificate is present; outward rounding alone does not certify sampled inputs.',
  }
  if denominator > 0 and structure_pass:
    R = (2 * mu * Q / denominator).upper()
    report['R_spec_estimate'] = ball_record(R)
    report['spectral_parameter_interval_estimate'] = {
      'left': ball_record((mu - R).lower()),
      'right': ball_record((mu + R).upper()),
      'certified_spectral_inclusion': False,
    }
  elif not structure_pass:
    report['status'] = 'STRUCTURAL_OBLIGATIONS_UNRESOLVED'
  else:
    report['status'] = 'NONPOSITIVE_DENOMINATOR_NO_FINITE_BOUND'
  with Path(output_path).open('x') as stream:
    json.dump(report, stream, indent=2, allow_nan=False)
    stream.write('\n')
  print(report['status'], flush=True)
  return report


if __name__ == '__main__':
  if len(sys.argv) != 3:
    raise SystemExit('usage: certify_scalars_i7.py NUMERICAL_INPUT_JSON OUTPUT_JSON')
  certify(sys.argv[1], sys.argv[2])
