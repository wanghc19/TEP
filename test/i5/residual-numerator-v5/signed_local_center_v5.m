function out = signed_local_center_v5(z, geometry, configuration, density)
%SIGNED_LOCAL_CENTER_V5 Evaluate the signed local Kress centre and p=4 radii.
% Purpose:
%   Instantiate (I5.1f-6)--(I5.1f-11) for the frozen circle adapter while
%   exposing only the shape-general signed-centre/radius interface.
% Input:
%   z - Frozen certificate; geometry - certified evaluation geometry;
%   configuration - L, N, series and alias cutoffs, plus evaluate_centers;
%   density - exact-oracle finite Fourier data for tau and zeta=-sigma.
% Output:
%   out.center.val/nor and disjoint source/target/series radii, together with
%   complete p=4 derivative and omitted-Fourier certificates.
% Main algorithm:
%   Build signed J/Y/cancellation-safe finite series, enclose fourth source
%   derivatives by Bell/Leibniz sums, stream the Kress action, and transform
%   retained target rows without a Fourier--Bessel operator diagonalization.
% Based on:
%   design-5-1f.md, equations (I5.1f-6)--(I5.1f-11), and KR-15--KR-25.
% Notes:
%   The retained rows are ideal centres.  Their unresolved sf/fp enclosure is
%   deliberately not represented by a numerical zero.

LOCAL_validate_inputs(z, geometry, configuration, density);
R = double(z.R);
Q = double(configuration.kernel_series_cutoff);
x_max = 4.0 * R^2;
kappa_e = double(z.khat);
kappa_i = sqrt(double(z.rho_disk)) * kappa_e;
orders = double(density.orders(:));
tau_coeff = double(density.tau_coeff);
zeta_coeff = double(density.zeta_coeff);
d_tau = LOCAL_density_derivatives(orders, tau_coeff, 5);
d_zeta = LOCAL_density_derivatives(orders, zeta_coeff, 5);

outer = LOCAL_primitive(kappa_e, x_max, Q, 4);
inner = LOCAL_primitive(kappa_i, x_max, Q, 4);
[factors, factor_gate] = LOCAL_factor_bounds( ...
  outer, inner, kappa_e, kappa_i, R);
certificate = LOCAL_derivative_certificate( ...
  factors, d_tau, d_zeta, R, geometry);

N = double(configuration.evaluation_node_count);
L = double(configuration.residual_mode_cutoff);
mode_orders = (-(L - 1):L - 1).';
[source_val, kress_constants] = LOCAL_source_radius( ...
  certificate.val.source_L1_p4, geometry, N);
[source_nor, ~] = LOCAL_source_radius( ...
  certificate.nor.source_L1_p4, geometry, N);
[target_val, alias_val] = LOCAL_alias_radius( ...
  certificate.val, geometry, mode_orders, N, configuration.alias_cutoff);
[target_nor, alias_nor] = LOCAL_alias_radius( ...
  certificate.nor, geometry, mode_orders, N, configuration.alias_cutoff);

build_center = logical(configuration.evaluate_centers);
[center_val, center_nor, series_val, series_nor, center_ledger] = ...
  LOCAL_streamed_center( ...
    z, geometry, configuration, density, outer.signed, inner.signed, ...
    factors.tail, build_center);
if ~build_center
  center_val = complex(zeros(numel(mode_orders), size(tau_coeff, 2)));
  center_nor = center_val;
end
radius_val = source_val + target_val + series_val;
radius_nor = source_nor + target_nor + series_nor;

high = LOCAL_high_tail(certificate, geometry, configuration);
all_values = [center_val(:); center_nor(:); radius_val(:); radius_nor(:); ...
  certificate.val.H_q(:); certificate.nor.H_q(:); ...
  certificate.val.Q2; certificate.val.Q4; ...
  certificate.nor.Q2; certificate.nor.Q4; high.val.p2_squared; ...
  high.val.p4_squared; high.nor.p2_squared; high.nor.p4_squared];
gates = struct( ...
  'circle_adapter', certificate.gates.circle_adapter, ...
  'density_support', certificate.gates.density_support, ...
  'density_row2_derivatives', all(isfinite([d_tau, d_zeta])) && ...
    all([d_tau, d_zeta] >= 0), ...
  'p4_factor_ratio', factor_gate, ...
  'p4_source_certificate', certificate.gates.p4_source, ...
  'p4_target_alias', alias_val.pass && alias_nor.pass, ...
  'series_delta_tail_only', center_ledger.series_delta_tail_only, ...
  'identity_included_once', center_ledger.identity_included_once, ...
  'cotangent_cancelled_before_bound', true, ...
  'signed_retained_polynomial_center', true, ...
  'centers_evaluated', build_center, ...
  'shape_general_interface', true, ...
  'circle_adapter_no_operator_diagonalization', true, ...
  'finite_nonnegative', all(isfinite(all_values)) && ...
    all([radius_val(:); radius_nor(:); high.val.selected_squared; ...
      high.nor.selected_squared] >= 0));
gates.pass = all(structfun(@(x) isequal(x, true), gates));

out = struct( ...
  'mode_orders', mode_orders, ...
  'center', struct('val', center_val, 'nor', center_nor), ...
  'centers_evaluated', build_center, ...
  'radius', struct( ...
    'val', struct('source', repmat(source_val, numel(mode_orders), 1), ...
      'target', target_val, 'series', repmat(series_val, numel(mode_orders), 1), ...
      'total', radius_val), ...
    'nor', struct('source', repmat(source_nor, numel(mode_orders), 1), ...
      'target', target_nor, 'series', repmat(series_nor, numel(mode_orders), 1), ...
      'total', radius_nor)), ...
  'derivative_certificate', certificate, ...
  'density_derivative_row2_upper', struct('tau', d_tau, 'zeta', d_zeta), ...
  'kress_constants', kress_constants, ...
  'alias_certificate', struct('val', alias_val, 'nor', alias_nor), ...
  'series_certificate', center_ledger, ...
  'high_tail', high, ...
  'series', struct('outer', outer.audit, 'inner', inner.audit), ...
  'instance_adapter', ...
    'circle analytic geometry derivative bounds; no Fourier/Bessel diagonalization', ...
  'delta_sf', 'UNRESOLVED', ...
  'delta_fp', 'UNRESOLVED', ...
  'gates', gates, ...
  'sf_ledger', struct( ...
    'Bessel_calls', 0, 'Hankel_calls', 0, 'qpgreen_calls', 0, ...
    'Faddeeva_calls', 0, 'expint_calls', 0, ...
    'finite_log_scalar_count', 3, ...
    'finite_exp_scalar_count', center_ledger.exp_scalar_count, ...
    'finite_sin_cos_scalar_count', center_ledger.trig_scalar_count, ...
    'finite_fft_calls', center_ledger.fft_calls, ...
    'Euler_constant_source', 'literal decimal; exact-oracle phase', ...
    'finite_evaluation', 'sf/fp UNRESOLVED'));
end

%% ==================== Input and coefficient certificates ====================
% Validate the current adapter and construct coefficient-row derivative sums.

function LOCAL_validate_inputs(z, geometry, configuration, density)
required_z = {'R', 'khat', 'rho_disk', 'mu_h'};
required_g = {'boundary_length', 'speed_lower', 'speed_upper', ...
  'constant_speed_parameterization', 'parameter_nodes', 'speed_nodes', ...
  'tubular_C0', 'tubular_C1', 'trace_tail_slope_lower'};
required_c = {'kernel_series_cutoff', 'evaluation_node_count', ...
  'residual_mode_cutoff', 'alias_cutoff', 'evaluate_centers'};
required_d = {'orders', 'tau_coeff', 'zeta_coeff'};
if ~all(isfield(z, required_z)) || ~all(isfield(geometry, required_g)) || ...
    ~all(isfield(configuration, required_c)) || ...
    ~all(isfield(density, required_d))
  error('I5v5Local:Schema', 'The local input contract is incomplete.');
end
N = double(configuration.evaluation_node_count);
L = double(configuration.residual_mode_cutoff);
M_eta = max(abs(double(density.orders(:))));
if N ~= fix(N) || mod(N, 2) ~= 0 || N <= 2 * max(L, M_eta) || ...
    ~geometry.constant_speed_parameterization || ...
    double(geometry.speed_lower) <= 0 || ...
    size(density.tau_coeff, 1) ~= numel(density.orders) || ...
    ~isequal(size(density.tau_coeff), size(density.zeta_coeff)) || ...
    ~isequal(double(density.orders(:)), (-128:127).') || ...
    double(configuration.kernel_series_cutoff) < 5 || ...
    double(configuration.kernel_series_cutoff) ~= ...
      fix(double(configuration.kernel_series_cutoff)) || ...
    double(configuration.alias_cutoff) < 1 || ...
    double(configuration.alias_cutoff) ~= fix(double(configuration.alias_cutoff)) || ...
    double(configuration.target_block_size) < 1 || ...
    double(configuration.target_block_size) ~= ...
      fix(double(configuration.target_block_size)) || ...
    double(geometry.tubular_C0) <= 0 || double(geometry.tubular_C1) <= 0 || ...
    double(geometry.trace_tail_slope_lower) <= 0
  error('I5v5Local:Gate', 'The strict index, speed, or density gate failed.');
end
end

function bounds = LOCAL_density_derivatives(orders, coefficients, max_order)
row_norm = vecnorm(coefficients, 2, 2);
bounds = zeros(1, max_order + 1);
for q = 0:max_order
  bounds(q + 1) = sum(abs(orders).^q .* row_norm);
end
end

%% ==================== Entire-series factor bounds ====================
% Retained absolute sums plus first-omitted geometric tails certify p=4.

function out = LOCAL_primitive(kappa, x_max, cutoff, max_derivative)
alpha = kappa^2 / 4;
euler_constant = 0.57721566490153286060;
c0 = 1i / 4 - (log(kappa / 2) + euler_constant) / (2 * pi);
a = complex(zeros(cutoff + 1, 1));
y = complex(zeros(cutoff + 1, 1));
a(1) = 1;
harmonic = 0;
for n = 1:cutoff
  a(n + 1) = a(n) * (-alpha) / n^2;
  harmonic = harmonic + 1 / n;
  y(n + 1) = harmonic * a(n + 1);
end
m = (0:cutoff - 1).';
jshift = a(2:end);
jfirst = -2 * (m + 1) .* a(2:end);
cfrak = -a(2:end) / (2 * pi) + ...
  2 * c0 * (m + 1) .* a(2:end) + (m + 1) .* y(2:end) / pi;
qcoeff = NaN(size(a));
qcoeff(:) = c0 * a + y / (2 * pi);
out.signed = struct('a', a, 'y', y, 'jshift', jshift, ...
  'jfirst', jfirst, 'cfrak', cfrak, 'qcoeff_without_logc', qcoeff, ...
  'c0', c0);
% J/Y need one extra derivative because J^[1] and cfrak use the shifted
% (r+1)-derivative tails in the exact Researcher ledger.
J = LOCAL_entire_series(kappa, x_max, cutoff, max_derivative + 1, 'J');
Y = LOCAL_entire_series(kappa, x_max, cutoff, max_derivative + 1, 'Y');
Jshift = LOCAL_entire_series( ...
  kappa, x_max, cutoff, max_derivative, 'j_shift');
Jfirst = LOCAL_retained_record(abs(jfirst), x_max, max_derivative);
Cfrak = LOCAL_retained_record(abs(cfrak), x_max, max_derivative);
for r = 0:max_derivative
  Jfirst.tail(r + 1) = 2 * J.tail(r + 2);
  Jfirst.upper(r + 1) = Jfirst.upper(r + 1) + Jfirst.tail(r + 1);
  Cfrak.tail(r + 1) = ...
    (1 / (2 * pi * (r + 1)) + 2 * abs(c0)) * J.tail(r + 2) + ...
    Y.tail(r + 2) / pi;
  Cfrak.upper(r + 1) = Cfrak.upper(r + 1) + Cfrak.tail(r + 1);
end
Jfirst.ratio = J.ratio(2:max_derivative + 2);
Cfrak.ratio = max(J.ratio(2:max_derivative + 2), ...
  Y.ratio(2:max_derivative + 2));
out.bound = struct('J', J, 'Y', Y, 'Jfirst', Jfirst, ...
  'Jshift', Jshift, 'Cfrak', Cfrak, 'c0_abs', abs(c0));
out.audit = struct('cutoff', cutoff, 'first_J_Y', cutoff + 1, ...
  'first_shifted', cutoff, 'ratio_pass', ...
  J.pass && Y.pass && Jshift.pass && all(isfinite(Jfirst.upper)) && ...
  all(isfinite(Cfrak.upper)) && all(Jfirst.ratio < 1) && ...
  all(Cfrak.ratio < 1));
end

function record = LOCAL_retained_record(retained_abs, x_max, max_derivative)
upper = zeros(1, max_derivative + 1);
tail = zeros(1, max_derivative + 1);
powers = (0:numel(retained_abs) - 1).';
for r = 0:max_derivative
  keep = powers >= r;
  falling = ones(sum(keep), 1);
  selected = powers(keep);
  for j = 0:r - 1
    falling = falling .* (selected - j);
  end
  upper(r + 1) = sum(retained_abs(keep) .* falling .* ...
    x_max.^(selected - r));
end
record = struct('upper', upper, 'tail', tail, ...
  'ratio', zeros(1, max_derivative + 1));
end

function record = LOCAL_entire_series(kappa, x_max, cutoff, max_derivative, kind)
alpha = kappa^2 / 4;
upper = zeros(1, max_derivative + 1);
tail = zeros(1, max_derivative + 1);
ratio = zeros(1, max_derivative + 1);
for r = 0:max_derivative
  if strcmp(kind, 'j_shift')
    last = cutoff - 1;
    for m = r:last
      upper(r + 1) = upper(r + 1) + exp( ...
        gammaln(m + 1) - gammaln(m - r + 1) + ...
        (m + 1) * log(alpha) + (m - r) * log(x_max) - ...
        2 * gammaln(m + 2));
    end
    m = cutoff;
    first = exp(gammaln(m + 1) - gammaln(m - r + 1) + ...
      (m + 1) * log(alpha) + (m - r) * log(x_max) - ...
      2 * gammaln(m + 2));
    ratio(r + 1) = alpha * x_max * (m + 1) / ...
      ((m + 1 - r) * (m + 2)^2);
  else
    start = r;
    if strcmp(kind, 'Y')
      start = max(1, r);
    end
    for n = start:cutoff
      harmonic = 1;
      if strcmp(kind, 'Y')
        harmonic = sum(1 ./ (1:n));
      end
      upper(r + 1) = upper(r + 1) + harmonic * exp( ...
        gammaln(n + 1) - gammaln(n - r + 1) + ...
        n * log(alpha) + (n - r) * log(x_max) - ...
        2 * gammaln(n + 1));
    end
    n = cutoff + 1;
    harmonic = 1;
    if strcmp(kind, 'Y')
      harmonic = sum(1 ./ (1:n));
    end
    first = harmonic * exp(gammaln(n + 1) - gammaln(n - r + 1) + ...
      n * log(alpha) + (n - r) * log(x_max) - ...
      2 * gammaln(n + 1));
    ratio(r + 1) = alpha * x_max / ((n + 1) * (n + 1 - r));
    if strcmp(kind, 'Y')
      ratio(r + 1) = ratio(r + 1) * (1 + 1 / (n + 1));
    end
  end
  if ratio(r + 1) >= 1
    tail(r + 1) = Inf;
  else
    tail(r + 1) = first / (1 - ratio(r + 1));
  end
  upper(r + 1) = upper(r + 1) + tail(r + 1);
end
record = struct('upper', upper, 'tail', tail, 'ratio', ratio, ...
  'pass', all(isfinite(upper)) && all(ratio < 1));
end

function [f, pass] = LOCAL_factor_bounds(outer, inner, ke, ki, R)
logc = abs(log(R^2));
Jsum = outer.bound.J.upper + inner.bound.J.upper;
Ysum = outer.bound.Y.upper + inner.bound.Y.upper;
Jfsum = outer.bound.Jfirst.upper + inner.bound.Jfirst.upper;
Csum = outer.bound.Cfrak.upper + inner.bound.Cfrak.upper;
qouter = (logc / (4 * pi) + outer.bound.c0_abs) * ...
  outer.bound.J.upper + outer.bound.Y.upper / (2 * pi);
qinner = (logc / (4 * pi) + inner.bound.c0_abs) * ...
  inner.bound.J.upper + inner.bound.Y.upper / (2 * pi);
W = logc * Jfsum / (4 * pi) + Csum;

S1x = R * Jsum / (4 * pi);
S2x = R * (qouter + qinner);
D1x = Jfsum / (8 * pi);
D2x = W / 2;
C1x = Jfsum / (4 * pi);
C2x = W;
A1x = R / (4 * pi) * (ke^2 * outer.bound.J.upper + ...
  ki^2 * inner.bound.J.upper);
A2x = R * (ke^2 * qouter + ki^2 * qinner);

one = [1, 0, 0, 0, 0];
x_h = [4 * R^2, 2 * R^2, 2 * R^2, 2 * R^2, 2 * R^2];
p_h = R^2 * ones(1, 5);
cos_h = ones(1, 5);
f.S1 = LOCAL_product(LOCAL_compose(S1x, R), one);
f.S2 = LOCAL_product(LOCAL_compose(S2x, R), one);
f.D1 = LOCAL_product(LOCAL_compose(D1x, R), x_h);
f.D2 = LOCAL_product(LOCAL_compose(D2x, R), x_h);
f.C1 = LOCAL_product(LOCAL_compose(C1x, R), p_h);
f.C2 = LOCAL_product(LOCAL_compose(C2x, R), p_h);
f.A1cos = LOCAL_product(LOCAL_compose(A1x, R), cos_h);
f.A2cos = LOCAL_product(LOCAL_compose(A2x, R), cos_h);

tail_J = outer.bound.J.tail(1) + inner.bound.J.tail(1);
tail_Y = outer.bound.Y.tail(1) + inner.bound.Y.tail(1);
tail_Jf = outer.bound.Jfirst.tail(1) + inner.bound.Jfirst.tail(1);
tail_C = outer.bound.Cfrak.tail(1) + inner.bound.Cfrak.tail(1);
q_tail_outer = (logc / (4 * pi) + outer.bound.c0_abs) * ...
  outer.bound.J.tail(1) + outer.bound.Y.tail(1) / (2 * pi);
q_tail_inner = (logc / (4 * pi) + inner.bound.c0_abs) * ...
  inner.bound.J.tail(1) + inner.bound.Y.tail(1) / (2 * pi);
W_tail = logc * tail_Jf / (4 * pi) + tail_C;
f.tail = struct( ...
  'S1', R * tail_J / (4 * pi), ...
  'S2', R * (q_tail_outer + q_tail_inner), ...
  'D1', 4 * R^2 * tail_Jf / (8 * pi), ...
  'D2', 4 * R^2 * W_tail / 2, ...
  'C1', R^2 * tail_Jf / (4 * pi), ...
  'C2', R^2 * W_tail, ...
  'A1cos', R / (4 * pi) * (ke^2 * outer.bound.J.tail(1) + ...
    ki^2 * inner.bound.J.tail(1)), ...
  'A2cos', R * (ke^2 * q_tail_outer + ki^2 * q_tail_inner));
pass = outer.audit.ratio_pass && inner.audit.ratio_pass && ...
  all(isfinite(struct2array(f.tail))) && ...
  all(struct2array(f.tail) >= 0);
end

function h = LOCAL_compose(xder, R)
X1 = 2 * R^2;
h = zeros(1, 5);
h(1) = xder(1);
h(2) = xder(2) * X1;
h(3) = xder(3) * X1^2 + xder(2) * X1;
h(4) = xder(4) * X1^3 + 3 * xder(3) * X1^2 + xder(2) * X1;
h(5) = xder(5) * X1^4 + 6 * xder(4) * X1^3 + ...
  7 * xder(3) * X1^2 + xder(2) * X1;
end

function h = LOCAL_product(a, b)
h = zeros(1, 5);
for q = 0:4
  for r = 0:q
    h(q + 1) = h(q + 1) + nchoosek(q, r) * ...
      a(r + 1) * b(q - r + 1);
  end
end
end

function c = LOCAL_derivative_certificate(f, tau, zeta, R, geometry)
[c.val.source_L1_p4, c.val.diagonal] = LOCAL_action_bounds( ...
  {f.D1, f.S1}, {f.D2, f.S2}, {tau, zeta}, {tau, zeta});
[c.nor.source_L1_p4, c.nor.diagonal] = LOCAL_action_bounds( ...
  {f.A1cos, LOCAL_scale(f.C1, 1 / R), f.D1}, ...
  {f.A2cos, LOCAL_scale(f.C2, 1 / R), f.D2}, ...
  {tau, tau(2:6), zeta}, {tau, tau(2:6), zeta});
c.val.identity = tau(1:5);
c.nor.identity = zeta(1:5);
c.val.H_q = c.val.identity + 8 * pi * log(2) * c.val.diagonal(1, :) + ...
  2 * pi * c.val.diagonal(2, :);
c.nor.H_q = c.nor.identity + 8 * pi * log(2) * c.nor.diagonal(1, :) + ...
  2 * pi * c.nor.diagonal(2, :);
s = double(geometry.speed_lower);
c.val.Q2 = 2 * pi * c.val.H_q(3) / s;
c.nor.Q2 = 2 * pi * c.nor.H_q(3) / s;
c.val.Q4 = 2 * pi * c.val.H_q(5) / s^3;
c.nor.Q4 = 2 * pi * c.nor.H_q(5) / s^3;
c.gates = struct('p4_source', all(isfinite([c.val.source_L1_p4, ...
  c.nor.source_L1_p4, c.val.H_q, c.nor.H_q])) && ...
  all([c.val.source_L1_p4, c.nor.source_L1_p4, ...
  c.val.H_q, c.nor.H_q] >= 0), ...
  'constant_speed_Q4', geometry.constant_speed_parameterization && s > 0, ...
  'density_support', true, ...
  'circle_adapter', isequal(double(geometry.boundary_length), 2 * pi * R) && ...
    isequal(double(geometry.speed_lower), R) && ...
    isequal(double(geometry.speed_upper), R) && ...
    geometry.parameter_grid_contract_pass && ...
    geometry.outward_normal_contract_pass);
end

function scaled = LOCAL_scale(value, factor)
scaled = value * factor;
end

function [source, diagonal] = LOCAL_action_bounds(f1, f2, d1, d2)
groups_f = {f1, f2};
groups_d = {d1, d2};
source = zeros(1, 2);
diagonal = zeros(2, 5);
for j = 1:2
  for term = 1:numel(groups_f{j})
    fh = groups_f{j}{term};
    dh = groups_d{j}{term};
    fourth = 0;
    for r = 0:4
      fourth = fourth + nchoosek(4, r) * fh(r + 1) * dh(5 - r);
    end
    source(j) = source(j) + 2 * pi * fourth;
    diagonal(j, :) = diagonal(j, :) + fh(1) * dh(1:5);
  end
end
end

%% ==================== Source, target, and high-mode radii ====================
% KR-17 and exact constant-speed DFT aliases supply finite p=4 constants.

function [radius, constants] = LOCAL_source_radius(S, geometry, N)
p = 4;
half = N / 2;
harmonic = sum(1 ./ (1:half - 1));
C_K = 2 * N^(-p) * (2 * harmonic + 2 / N) * ...
  (2^p + 2^(p - 1) / (p - 1)) + half^(-p - 1) + ...
  2 / p * half^(-p);
C_T = 2 * N^(-p) * (1 + 1 / (p - 1));
radius = 2 * pi * double(geometry.speed_upper) / ...
  sqrt(double(geometry.boundary_length)) * (S(1) * C_K + S(2) * C_T);
constants = struct('p', p, 'C_K', C_K, 'C_T', C_T, ...
  'harmonic_number', harmonic);
end

function [radius, certificate] = LOCAL_alias_radius( ...
    derivative, geometry, ell, N, alias_cutoff)
a = abs(double(ell(:)));
if any(a >= N / 2)
  error('I5v5Local:AliasIndex', 'A retained target order reaches Nyquist.');
end
sum2 = zeros(size(a));
sum4 = zeros(size(a));
for q = 1:alias_cutoff
  sum2 = sum2 + (q * N - a).^(-2) + (q * N + a).^(-2);
  sum4 = sum4 + (q * N - a).^(-4) + (q * N + a).^(-4);
end
q0 = alias_cutoff + 1;
tail2 = (q0 * N - a).^(-2) + 1 ./ (N * (q0 * N - a)) + ...
  (q0 * N + a).^(-2) + 1 ./ (N * (q0 * N + a));
tail4 = (q0 * N - a).^(-4) + 1 ./ (3 * N * (q0 * N - a).^3) + ...
  (q0 * N + a).^(-4) + 1 ./ (3 * N * (q0 * N + a).^3);
P = double(geometry.boundary_length);
r2 = derivative.Q2 * P^(3 / 2) / (4 * pi^2) * (sum2 + tail2);
r4 = derivative.Q4 * P^(7 / 2) / (2 * pi)^4 * (sum4 + tail4);
radius = min(r2, r4);
certificate = struct('p2', r2, 'p4', r4, 'selected', radius, ...
  'alias_cutoff', alias_cutoff, 'first_omitted', q0, ...
  'pass', all(isfinite([r2; r4])) && all([r2; r4] >= 0));
end

function high = LOCAL_high_tail(c, geometry, configuration)
L = double(configuration.residual_mode_cutoff);
P = double(geometry.boundary_length);
C0 = double(geometry.tubular_C0);
C1 = double(geometry.tubular_C1);
ctr = double(geometry.trace_tail_slope_lower);
high.val.p2_squared = 2 * c.val.Q2^2 / P * ( ...
  C0 * (P / (2 * pi))^4 * (L^(-4) + L^(-3) / 3) + ...
  C1 * (P / (2 * pi))^2 * (L^(-2) + L^(-1)));
high.nor.p2_squared = 2 * c.nor.Q2^2 / (P * ctr) * ...
  (P / (2 * pi))^5 * (L^(-5) + L^(-4) / 4);
% Integral-test tails for |d_l|<=Q4/(sqrt(P)|xi_l|^4).
high.val.p4_squared = 2 * c.val.Q4^2 / P * ( ...
  C0 * (P / (2 * pi))^8 * (L^(-8) + L^(-7) / 7) + ...
  C1 * (P / (2 * pi))^6 * (L^(-6) + L^(-5) / 5));
high.nor.p4_squared = 2 * c.nor.Q4^2 / (P * ctr) * ...
  (P / (2 * pi))^9 * (L^(-9) + L^(-8) / 8);
high.val.selected_squared = min(high.val.p2_squared, high.val.p4_squared);
high.nor.selected_squared = min(high.nor.p2_squared, high.nor.p4_squared);
high.index_owner = '|ell|>=L';
high.alternatives_min_not_sum = true;
end

%% ==================== Streamed signed Kress centre ====================
% Blocks avoid forming a full N-by-N collection of every split kernel.

function [val_rows, nor_rows, series_val, series_nor, ledger] = ...
    LOCAL_streamed_center(z, geometry, configuration, density, outer, inner, ...
    tail, build_center)
N = double(configuration.evaluation_node_count);
L = double(configuration.residual_mode_cutoff);
R = double(z.R);
nodes = double(geometry.parameter_nodes(:));
orders = double(density.orders(:));
phase = exp(1i * nodes * orders.');
tau = phase * double(density.tau_coeff);
zeta = phase * double(density.zeta_coeff);
tau_prime = phase * ((1i * orders) .* double(density.tau_coeff));
mode_orders = (-(L - 1):L - 1).';
samples_val = complex(zeros(N, size(tau, 2)));
samples_nor = samples_val;
series_error_val = zeros(N, 1);
series_error_nor = zeros(N, 1);
rvec = quad.quad_kress_rvec(N);
dt = 2 * pi / N;
block = double(configuration.target_block_size);
for first = 1:block:N
  ids = first:min(first + block - 1, N);
  h = nodes(ids) - nodes.';
  x = 4 * R^2 * sin(h / 2).^2;
  pT = R^2 * sin(h);
  cosh_real = cos(h);
  [split, split_tail] = LOCAL_signed_splits( ...
    z, R, x, pT, cosh_real, outer, inner, tail);
  offset = mod((ids - 1).' - (0:N - 1), N) + 1;
  Rblock = rvec(offset);
  if build_center
    D = Rblock .* split.D1 + dt * split.D2;
    S = Rblock .* split.S1 + dt * split.S2;
    A = Rblock .* split.A1cos + dt * split.A2cos;
    C = Rblock .* (split.C1 / R) + dt * (split.C2 / R);
    samples_val(ids, :) = tau(ids, :) + D * tau - S * zeta;
    samples_nor(ids, :) = -zeta(ids, :) - A * tau - ...
      C * tau_prime + D * zeta;
  end
  tau_norm = vecnorm(tau, 2, 2).';
  zeta_norm = vecnorm(zeta, 2, 2).';
  tau_prime_norm = vecnorm(tau_prime, 2, 2).';
  delta1_val = split_tail.D1 * tau_norm + split_tail.S1 * zeta_norm;
  delta2_val = split_tail.D2 * tau_norm + split_tail.S2 * zeta_norm;
  delta1_nor = split_tail.A1cos * tau_norm + ...
    split_tail.C1 / R * tau_prime_norm + split_tail.D1 * zeta_norm;
  delta2_nor = split_tail.A2cos * tau_norm + ...
    split_tail.C2 / R * tau_prime_norm + split_tail.D2 * zeta_norm;
  series_error_val(ids) = abs(Rblock) * delta1_val.' + ...
    dt * sum(delta2_val);
  series_error_nor(ids) = abs(Rblock) * delta1_nor.' + ...
    dt * sum(delta2_nor);
end
P = double(geometry.boundary_length);
series_val = dt / sqrt(P) * sum(double(geometry.speed_nodes(:)) .* ...
  series_error_val);
series_nor = dt / sqrt(P) * sum(double(geometry.speed_nodes(:)) .* ...
  series_error_nor);
if build_center
  val_rows = LOCAL_parameter_rows_stream(samples_val, nodes, mode_orders, P, block);
  nor_rows = LOCAL_parameter_rows_stream(samples_nor, nodes, mode_orders, P, block);
else
  val_rows = complex(zeros(numel(mode_orders), size(tau, 2)));
  nor_rows = val_rows;
end
ledger = struct('series_delta_tail_only', true, ...
  'identity_included_once', true, 'target_blocks', ceil(N / block), ...
  'center_required', logical(build_center), ...
  'series_radius_val', series_val, 'series_radius_nor', series_nor, ...
  'exp_scalar_count', numel(phase) + 2 * numel(mode_orders) * N, ...
  'trig_scalar_count', 3 * N^2, 'fft_calls', 0, ...
  'finite_evaluation', 'ORACLE; sf/fp UNRESOLVED');
end

function [s, t] = LOCAL_signed_splits(z, R, x, pT, cosh_real, outer, inner, tail)
logc = log(R^2);
Je = LOCAL_polyval(outer.a, x);
Ji = LOCAL_polyval(inner.a, x);
Ye = LOCAL_polyval(outer.y, x);
Yi = LOCAL_polyval(inner.y, x);
Jfe = LOCAL_polyval(outer.jfirst, x);
Jfi = LOCAL_polyval(inner.jfirst, x);
Ce = LOCAL_polyval(outer.cfrak, x);
Ci = LOCAL_polyval(inner.cfrak, x);
qe = (-logc / (4 * pi) + outer.c0) * Je + Ye / (2 * pi);
qi = (-logc / (4 * pi) + inner.c0) * Ji + Yi / (2 * pi);
dJ = Je - Ji;
dJf = Jfe - Jfi;
W = logc * dJf / (4 * pi) + Ce - Ci;
s.S1 = -R * dJ / (4 * pi);
s.S2 = R * (qe - qi);
s.D1 = x .* dJf / (8 * pi);
s.D2 = x .* W / 2;
s.C1 = pT .* dJf / (4 * pi);
s.C2 = pT .* W;
Se1 = -R * Je / (4 * pi);
Si1 = -R * Ji / (4 * pi);
Se2 = R * qe;
Si2 = R * qi;
s.A1cos = (double(z.khat)^2 * Se1 - ...
  (sqrt(double(z.rho_disk)) * double(z.khat))^2 * Si1) .* cosh_real;
s.A2cos = (double(z.khat)^2 * Se2 - ...
  (sqrt(double(z.rho_disk)) * double(z.khat))^2 * Si2) .* cosh_real;
t = tail;
end

function values = LOCAL_polyval(coefficients, x)
values = complex(zeros(size(x)));
for j = numel(coefficients):-1:1
  values = values .* x + coefficients(j);
end
end

function rows = LOCAL_parameter_rows_stream(samples, nodes, orders, P, block)
rows = complex(zeros(numel(orders), size(samples, 2)));
scale = (P / numel(nodes)) / sqrt(P);
for first = 1:block:numel(orders)
  ids = first:min(first + block - 1, numel(orders));
  rows(ids, :) = exp(-1i * orders(ids) * nodes.') * samples * scale;
end
end
