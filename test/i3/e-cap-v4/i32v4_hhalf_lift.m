function out = i32v4_hhalf_lift(c, boundary, cfg, resource)
%I32V4_HHALF_LIFT Form shifted-trace factors for the v4 companion lift.
% Purpose:
%   Convert the four coupled levels of total wall/circle value-defect
%   coefficient maps into weighted factors representing L(N).  Compute the
%   fixed exterior-annulus right-inverse constant and the unique GQP-only
%   factors used later by the full-P/cap module.
% Input:
%   c        - Frozen fbie-a1 certificate numerical view.
%   boundary - Completed v4 coupled boundary-sequence module.
%   cfg      - Frozen v4 configuration and oracle threshold.
%   resource - Shared hard time and memory gates.
% Output:
%   out.private.levels{j}.volume_factor - Full-P factor for L(N_j).
%   out.private.gqp_volume_factors      - Unique GQP-only weighted factors.
%   out.data                            - Constants, local weighted-map
%                                         diagnostics, ODE, and one oracle.
% Main algorithm:
%   Apply the shifted H^(1/2) Fourier weights to orthonormal boundary
%   coefficient maps, assemble the frozen plus/minus/singleton associations,
%   and solve the exterior annulus ODE in t=log(r) by vectorized fixed RK4.
% Based on:
%   design-3-2e Section 6.
% Notes:
%   This module does not contract P powers or tails and therefore does not
%   report the global L sequence.  It executes no cubic, Gauss-lift, strong-
%   source, old-experiment, image-sum, or Rayleigh-field path.

timer = tic;
out = LOCAL_empty();
progress = struct('stage', 'entry', 'levels_completed', 0.0, ...
  'ode_steps_completed', 0.0, 'local_peak_mib', 0.0, ...
  'complete', false);
try
  LOCAL_validate(c, boundary, cfg, resource);
  level_count = numel(boundary.private.levels);
  circle_counts = zeros(1, level_count);
  wall_counts = zeros(1, level_count);
  for j = 1:level_count
    maps = boundary.private.levels{j};
    circle_counts(j) = size(maps.circle_value_map, 1);
    wall_counts(j) = size(maps.wall_left_value_map, 1);
  end
  if ~isequal(circle_counts, [1024.0, 1280.0, 1536.0, 2048.0]) || ...
      ~isequal(wall_counts, 2.0 * circle_counts)
    error('I32V4:HhalfLevelCounts', ...
      'The coupled wall/circle level counts drifted.');
  end

  % --- stage 1: fixed shifted-trace constants ---
  progress.stage = 'shifted trace constants';
  [C_E_W_squared, lambda_W_min] = LOCAL_wall_constant(c);
  finest_circle_orders = (-circle_counts(end) / 2.0: ...
    circle_counts(end) / 2.0 - 1.0).';
  [circle_energy, ode_audit] = LOCAL_annulus_energy( ...
    finest_circle_orders, c, cfg.ode.steps, resource);
  progress.ode_steps_completed = ode_audit.steps;
  lambda_circle_finest = sqrt(c.gamma + ...
    (finest_circle_orders / c.R).^2);
  energy_ratio = circle_energy ./ lambda_circle_finest;
  if any(~isfinite(energy_ratio) | energy_ratio <= 0.0)
    error('I32V4:AnnulusEnergyRatio', ...
      'A finest-set annulus energy ratio is invalid.');
  end
  [C_E_circle_squared, maximizing_index] = max(energy_ratio);
  C_E_W = sqrt(C_E_W_squared);
  C_E_circle = sqrt(C_E_circle_squared);
  C_A = 1.0 + c.mu_h / c.gamma;
  if any(~isfinite([C_E_W, C_E_circle, C_A])) || ...
      any([C_E_W, C_E_circle, C_A] <= 0.0)
    error('I32V4:HhalfConstant', ...
      'A required shifted-trace constant is invalid.');
  end

  % --- stage 2: four coupled weighted factors ---
  progress.stage = 'coupled weighted factors';
  private.levels = cell(1, level_count);
  level_data = cell(1, level_count);
  for j = 1:level_count
    maps = boundary.private.levels{j};
    [factor, diagnostic] = LOCAL_level_factor(c, maps, C_E_W, ...
      C_E_circle);
    private.levels{j} = struct('volume_factor', factor, ...
      'circle_factor_rows', size(maps.circle_value_map, 1));
    level_data{j} = diagnostic;
    progress.levels_completed = j;
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      LOCAL_workspace_mib());
    LOCAL_resource(resource, progress.local_peak_mib);
  end

  % --- stage 3: unique GQP-only factors and normalization oracle ---
  progress.stage = 'GQP factors and oracle';
  private.gqp_volume_factors = LOCAL_gqp_factors(c, ...
    boundary.private.gqp, C_E_W, C_E_circle);
  oracle = LOCAL_single_mode_oracle(c, C_E_W_squared, ...
    circle_energy, finest_circle_orders, cfg.ode.oracle_mode, ...
    cfg.threshold.single_mode);
  if ~oracle.pass
    error('I32V4:HhalfOracle', ...
      'The composite shifted-trace normalization oracle failed.');
  end

  out.private = private;
  out.data = struct('C_A', C_A, 'C_E_wall', C_E_W, ...
    'C_E_wall_squared', C_E_W_squared, ...
    'lambda_wall_min', lambda_W_min, ...
    'C_E_circle', C_E_circle, ...
    'C_E_circle_squared', C_E_circle_squared, ...
    'maximizing_circle_order', ...
    finest_circle_orders(maximizing_index), ...
    'maximizing_energy_ratio', energy_ratio(maximizing_index), ...
    'circle_constant_set', [-1024.0, 1023.0], ...
    'levels', {level_data}, 'ode', ode_audit, 'oracle', oracle, ...
    'global_L_deferred_to_fit', true, ...
    'gqp_piece_names', {LOCAL_names(private.gqp_volume_factors)});
  out.audit = struct( ...
    'wall_basis', 'd^(-1/2)*exp(i*(beta+2*pi*m/d)*y) in L2(dy)', ...
    'circle_basis', '(2*pi*R)^(-1/2)*exp(i*l*theta) in L2(ds)', ...
    'circle_measure_jacobian', 'r/R', ...
    'annulus_side', 'exterior background collar only', ...
    'annulus_boundary_conditions', 'h(R)=1, h(R+delta_c)=0', ...
    'annulus_steps', cfg.ode.steps, ...
    'finest_circle_constant_reused_at_all_levels', true, ...
    'left_right_wall_defects_orthogonal', true, ...
    'global_L_and_tail_contractions_deferred_to_fit', true, ...
    'cubic_calls', 0.0, 'gauss_lift_calls', 0.0, ...
    'strong_source_calls', 0.0, 'old_experiment_calls', 0.0);
  out.counters = struct('density_solves', 0.0, 'image_sum_calls', 0.0, ...
    'rayleigh_field_calls', 0.0, 'old_experiment_calls', 0.0, ...
    'cubic_calls', 0.0, 'gauss_lift_calls', 0.0, ...
    'strong_source_calls', 0.0, ...
    'annulus_rk4_steps', cfg.ode.steps);
  out.available = true;
  out.status = 'COMPLETE';
  progress.stage = 'complete';
  progress.complete = true;
catch err
  out.status = 'BLOCKED';
  out.first_blocker = LOCAL_identifier(err);
  out.audit.exception_message = err.message;
  progress.stage = 'blocked';
  progress.first_blocker = out.first_blocker;
end
out.audit.progress = progress;
info = whos('out');
out.memory = struct('local_peak_mib', max(progress.local_peak_mib, ...
  info.bytes / 2^20), 'retained_mib', info.bytes / 2^20, ...
  'largest_object', 'four finest-weighted factor maps');
out.audit.elapsed_s = toc(timer);
end

%% ==================== Shifted trace constants ====================
% These helpers implement the one-sided strip and exterior-annulus energies.

function [constant_squared, lambda_min] = LOCAL_wall_constant(c)
center = -c.beta * c.d / (2.0 * pi);
candidates = unique([floor(center), ceil(center)]);
alpha = c.beta + 2.0 * pi * candidates / c.d;
lambda_min = min(sqrt(c.gamma + alpha.^2));
constant_squared = 1.0 / tanh(lambda_min * c.delta_w);
if ~(isfinite(lambda_min) && lambda_min > 0.0 && ...
    isfinite(constant_squared) && constant_squared > 0.0)
  error('I32V4:WallStripConstant', ...
    'The one-sided wall-strip constant is invalid.');
end
end

function [energy, audit] = LOCAL_annulus_energy(orders, c, steps, resource)
steps = double(steps);
t_outer = log(c.R + c.delta_c);
t_inner = log(c.R);
dt = (t_inner - t_outer) / steps;
order_squared = double(orders).^2;
value = zeros(size(orders));
derivative = ones(size(orders));
t = t_outer;
for step = 1:steps
  coefficient_1 = order_squared + c.gamma * exp(2.0 * t);
  k1_value = derivative;
  k1_derivative = coefficient_1 .* value;

  half_value = value + 0.5 * dt * k1_value;
  half_derivative = derivative + 0.5 * dt * k1_derivative;
  coefficient_2 = order_squared + c.gamma * exp(2.0 * (t + 0.5 * dt));
  k2_value = half_derivative;
  k2_derivative = coefficient_2 .* half_value;

  half_value = value + 0.5 * dt * k2_value;
  half_derivative = derivative + 0.5 * dt * k2_derivative;
  k3_value = half_derivative;
  k3_derivative = coefficient_2 .* half_value;

  end_value = value + dt * k3_value;
  end_derivative = derivative + dt * k3_derivative;
  coefficient_4 = order_squared + c.gamma * exp(2.0 * (t + dt));
  k4_value = end_derivative;
  k4_derivative = coefficient_4 .* end_value;

  value = value + dt * (k1_value + 2.0 * k2_value + ...
    2.0 * k3_value + k4_value) / 6.0;
  derivative = derivative + dt * (k1_derivative + ...
    2.0 * k2_derivative + 2.0 * k3_derivative + ...
    k4_derivative) / 6.0;
  t = t + dt;
  if mod(step, 256.0) == 0.0
    LOCAL_resource(resource, LOCAL_workspace_mib());
  end
end
energy = -derivative ./ (c.R * value);
positive = (1.0:double(max(orders))).';
positive_index = positive + double(max(abs(orders))) + 1.0;
negative_index = -positive + double(max(abs(orders))) + 1.0;
symmetry = norm(energy(positive_index) - energy(negative_index)) / ...
  max(norm(energy(positive_index)), realmin);
if any(~isfinite([value; derivative; energy])) || any(energy <= 0.0)
  error('I32V4:AnnulusODESolve', ...
    'The fixed exterior-annulus RK4 solve is invalid.');
end
audit = struct('coordinate', 't=log(r)', 'steps', steps, ...
  'initial_side', 'r=R+delta_c', ...
  'fundamental_initial_data', '[v,v_t]=[0,1]', ...
  'energy_formula', '-v_t(R)/(R*v(R))', ...
  'minimum_energy', min(energy), 'maximum_energy', max(energy), ...
  'even_order_symmetry_defect', symmetry, ...
  'all_positive_finite', true);
end

%% ==================== Weighted factor assembly ====================
% Boundary maps are already orthonormal Fourier coefficient maps.

function [factor, diagnostic] = LOCAL_level_factor(c, maps, ...
    C_E_W, C_E_circle)
circle_map = maps.circle_value_map;
left_map = maps.wall_left_value_map;
right_map = maps.wall_right_value_map;
n_circle = size(circle_map, 1);
n_wall = size(left_map, 1);
state_count = 2.0 * c.K;
if ~isequal(size(circle_map), [n_circle, state_count]) || ...
    ~isequal(size(left_map), [n_wall, state_count]) || ...
    ~isequal(size(right_map), [n_wall, state_count]) || ...
    n_wall ~= 2.0 * n_circle || any(~isfinite([circle_map(:); ...
    left_map(:); right_map(:)]))
  error('I32V4:HhalfMapShape', ...
    'A total value-defect coefficient map is invalid.');
end

circle_weight = LOCAL_circle_weight(c, n_circle, C_E_circle);
wall_weight = LOCAL_wall_weight(c, n_wall, C_E_W);
circle_weighted = circle_weight .* circle_map;
left_weighted = wall_weight .* left_map;
right_weighted = wall_weight .* right_map;

C_plus = circle_weighted * c.Gplus;
C_minus = circle_weighted * c.Gminus;
L_plus = left_weighted * c.Gplus;
L_minus = left_weighted * c.Gminus;
R_plus = right_weighted * c.Gplus;
R_minus = right_weighted * c.Gminus;
center_left = wall_weight .* LOCAL_center_coeff( ...
  c.center_wall_jumps.left_value_lift_source, c, n_wall);
center_right = wall_weight .* LOCAL_center_coeff( ...
  c.center_wall_jumps.right_value_lift_source, c, n_wall);
singleton = [center_left; center_right; ...
  L_plus * c.cplus; R_minus * c.cminus];
factor = struct('plus', [C_plus; R_plus; L_plus * c.Pplus], ...
  'minus', [C_minus; L_minus; R_minus * c.Pminus], ...
  'singleton', singleton, ...
  'operation_count', LOCAL_factor_operations(n_circle, n_wall, c.K));
factor_squared = norm(factor.plus, 'fro')^2 + ...
  norm(factor.minus, 'fro')^2 + norm(factor.singleton)^2;
block_squared = norm(C_plus, 'fro')^2 + norm(C_minus, 'fro')^2 + ...
  norm(R_plus, 'fro')^2 + norm(L_plus * c.Pplus, 'fro')^2 + ...
  norm(L_minus, 'fro')^2 + norm(R_minus * c.Pminus, 'fro')^2 + ...
  norm(center_left)^2 + norm(center_right)^2 + ...
  norm(L_plus * c.cplus)^2 + norm(R_minus * c.cminus)^2;
diagnostic = struct('N_circle', n_circle, 'N_wall', n_wall, ...
  'circle_weighted_map_norm', norm(circle_weighted, 'fro'), ...
  'wall_left_weighted_map_norm', norm(left_weighted, 'fro'), ...
  'wall_right_weighted_map_norm', norm(right_weighted, 'fro'), ...
  'center_left_weighted_norm', norm(center_left), ...
  'center_right_weighted_norm', norm(center_right), ...
  'volume_factor_fro', sqrt(factor_squared), ...
  'direct_sum_identity_defect', abs(factor_squared - block_squared) / ...
  max(factor_squared, realmin), ...
  'global_L_deferred_to_fit', true);
end

function factors = LOCAL_gqp_factors(c, gqp, C_E_W, C_E_circle)
circle_maps = gqp.circle_value_maps;
wall_maps = gqp.wall_value_maps;
n_circle = size(circle_maps{1}.map, 1);
n_wall = size(wall_maps{1}.map, 1);
circle_weight = LOCAL_circle_weight(c, n_circle, C_E_circle);
wall_weight = LOCAL_wall_weight(c, n_wall, C_E_W);
factors = cell(1, numel(circle_maps) + numel(wall_maps));
for j = 1:numel(circle_maps)
  piece = circle_maps{j};
  weighted = circle_weight .* piece.map;
  factors{j} = struct('name', char(string(piece.name)), ...
    'plus', weighted * c.Gplus, 'minus', weighted * c.Gminus, ...
    'singleton', complex(zeros(0, 1)), ...
    'operation_count', 2.0 * n_circle * (2.0 * c.K) * c.K);
end
offset = numel(circle_maps);
for j = 1:numel(wall_maps)
  piece = wall_maps{j};
  zero = complex(zeros(size(piece.map)));
  if strcmp(piece.side, 'left')
    left_map = piece.map;
    right_map = zero;
  elseif strcmp(piece.side, 'right')
    left_map = zero;
    right_map = piece.map;
  else
    error('I32V4:HhalfGQPSide', ...
      'A wall GQP value map has an invalid side.');
  end
  left = (wall_weight .* left_map) * c.Gplus;
  left_minus = (wall_weight .* left_map) * c.Gminus;
  right = (wall_weight .* right_map) * c.Gplus;
  right_minus = (wall_weight .* right_map) * c.Gminus;
  factors{offset + j} = struct('name', char(string(piece.name)), ...
    'plus', [right; left * c.Pplus], ...
    'minus', [left_minus; right_minus * c.Pminus], ...
    'singleton', [left * c.cplus; right_minus * c.cminus], ...
    'operation_count', LOCAL_factor_operations(0.0, n_wall, c.K));
end
end

function weight = LOCAL_wall_weight(c, N, constant)
orders = (-N / 2.0:N / 2.0 - 1.0).';
alpha = c.beta + 2.0 * pi * orders / c.d;
lambda = sqrt(c.gamma + alpha.^2);
weight = constant * sqrt(lambda);
end

function weight = LOCAL_circle_weight(c, N, constant)
orders = (-N / 2.0:N / 2.0 - 1.0).';
lambda = sqrt(c.gamma + (orders / c.R).^2);
weight = constant * sqrt(lambda);
end

function coeff = LOCAL_center_coeff(samples, c, target_count)
source_count = size(samples, 1);
if mod(source_count, 2.0) ~= 0.0 || source_count > target_count
  error('I32V4:CenterWallSamples', ...
    'A frozen center-wall sample vector has an invalid size.');
end
orders = (-source_count / 2.0:source_count / 2.0 - 1.0).';
y = -c.d / 2.0 + c.d * ((0.0:source_count - 1.0).' + 0.5) / ...
  source_count;
gauge = exp(-1i * c.beta * y) .* samples;
native = sqrt(c.d) * exp(1i * pi * orders) .* ...
  exp(-1i * pi * orders / source_count) .* ...
  (fftshift(fft(gauge, [], 1), 1) / source_count);
coeff = LOCAL_pad(native, target_count);
end

function padded = LOCAL_pad(value, target_count)
source_count = size(value, 1);
padded = complex(zeros(target_count, size(value, 2)));
first = target_count / 2.0 - source_count / 2.0 + 1.0;
padded(first:first + source_count - 1.0, :) = value;
end

function operations = LOCAL_factor_operations(n_circle, n_wall, K)
state_count = 2.0 * K;
operations = 2.0 * n_circle * state_count * K + ...
  4.0 * n_wall * state_count * K + 2.0 * n_wall * K^2 + ...
  2.0 * n_wall * K;
end

%% ==================== Composite single-mode oracle ====================
% One mode checks both coefficient measures and the two energy formulas.

function oracle = LOCAL_single_mode_oracle(c, C_E_W_squared, ...
    circle_energy, circle_orders, mode, threshold)
N_wall = 128.0;
wall_orders = (-N_wall / 2.0:N_wall / 2.0 - 1.0).';
y = -c.d / 2.0 + c.d * ((0.0:N_wall - 1.0).' + 0.5) / N_wall;
alpha = c.beta + 2.0 * pi * mode / c.d;
wall_samples = exp(1i * alpha * y) / sqrt(c.d);
wall_coeff = LOCAL_center_coeff(wall_samples, c, N_wall);
wall_index = find(wall_orders == mode, 1);
wall_selected = abs(wall_coeff(wall_index) - 1.0);
wall_coeff(wall_index) = 0.0;
wall_leakage = norm(wall_coeff);

N_circle = 128.0;
circle_mode_orders = (-N_circle / 2.0:N_circle / 2.0 - 1.0).';
theta = 2.0 * pi * ((0.0:N_circle - 1.0).' + 0.5) / N_circle;
circle_samples = exp(1i * mode * theta) / sqrt(2.0 * pi * c.R);
circle_coeff = sqrt(2.0 * pi * c.R) * ...
  exp(-1i * circle_mode_orders * pi / N_circle) .* ...
  (fftshift(fft(circle_samples, [], 1), 1) / N_circle);
circle_index = find(circle_mode_orders == mode, 1);
circle_selected = abs(circle_coeff(circle_index) - 1.0);
circle_coeff(circle_index) = 0.0;
circle_leakage = norm(circle_coeff);

lambda_wall = sqrt(c.gamma + alpha^2);
strip_energy = lambda_wall / tanh(lambda_wall * c.delta_w);
strip_reference = lambda_wall * coth(lambda_wall * c.delta_w);
strip_ratio = strip_energy / lambda_wall;
strip_defect = abs(strip_energy - strip_reference) / ...
  max([1.0, abs(strip_energy), abs(strip_reference)]);
[wall_constant_reference, ~] = LOCAL_wall_constant(c);
wall_constant_defect = abs(C_E_W_squared - wall_constant_reference) / ...
  max([1.0, abs(C_E_W_squared), abs(wall_constant_reference)]);

finest_index = find(circle_orders == mode, 1);
annulus_rk4 = circle_energy(finest_index);
annulus_bessel = LOCAL_annulus_bessel_energy(mode, c);
annulus_defect = abs(annulus_rk4 - annulus_bessel) / ...
  max([1.0, abs(annulus_rk4), abs(annulus_bessel)]);
maximum = max([wall_selected, wall_leakage, circle_selected, ...
  circle_leakage, strip_defect, wall_constant_defect, annulus_defect]);
oracle = struct('mode', mode, 'wall_selected_defect', wall_selected, ...
  'wall_leakage', wall_leakage, ...
  'circle_selected_defect', circle_selected, ...
  'circle_leakage', circle_leakage, ...
  'strip_energy', strip_energy, ...
  'strip_reference', strip_reference, ...
  'strip_ratio', strip_ratio, 'strip_ratio_defect', strip_defect, ...
  'wall_constant_defect', wall_constant_defect, ...
  'annulus_RK4_energy', annulus_rk4, ...
  'annulus_modified_bessel_energy', annulus_bessel, ...
  'annulus_relative_defect', annulus_defect, ...
  'maximum_defect', maximum, 'threshold', threshold, ...
  'pass', isfinite(maximum) && maximum <= threshold, ...
  'oracle_count', 1.0);
end

function energy = LOCAL_annulus_bessel_energy(order, c)
kappa = sqrt(c.gamma);
z_inner = kappa * c.R;
z_outer = kappa * (c.R + c.delta_c);
ell = abs(order);
I_inner = besseli(ell, z_inner);
K_inner = besselk(ell, z_inner);
I_outer = besseli(ell, z_outer);
K_outer = besselk(ell, z_outer);
I_prime = 0.5 * (besseli(ell - 1.0, z_inner) + ...
  besseli(ell + 1.0, z_inner));
K_prime = -0.5 * (besselk(ell - 1.0, z_inner) + ...
  besselk(ell + 1.0, z_inner));
denominator = I_inner * K_outer - K_inner * I_outer;
derivative = kappa * (I_prime * K_outer - K_prime * I_outer);
energy = -derivative / denominator;
if ~(isfinite(energy) && energy > 0.0)
  error('I32V4:AnnulusBesselOracle', ...
    'The modified-Bessel annulus reference is invalid.');
end
end

function names = LOCAL_names(factors)
names = cell(1, numel(factors));
for j = 1:numel(factors)
  names{j} = factors{j}.name;
end
end

%% ==================== Contracts and resources ====================
% Runtime checks are limited to the scientific schema and hard gates.

function LOCAL_validate(c, boundary, cfg, resource)
required = {'K', 'mu_h', 'gamma', 'beta', 'd', 'R', 'delta_c', ...
  'delta_w', 'X_L', 'X_R', 'Pplus', 'Pminus', 'cplus', 'cminus', ...
  'Gplus', 'Gminus', 'center_wall_jumps'};
center_required = {'left_value_lift_source', 'right_value_lift_source'};
if ~isstruct(c) || ~all(isfield(c, required)) || ...
    ~isstruct(c.center_wall_jumps) || ...
    ~all(isfield(c.center_wall_jumps, center_required)) || ...
    ~isstruct(boundary) || ~isfield(boundary, 'available') || ...
    ~boundary.available || ~isfield(boundary, 'private') || ...
    ~isfield(boundary.private, 'levels') || ...
    ~isfield(boundary.private, 'gqp') || ...
    ~isstruct(cfg) || ~isfield(cfg, 'threshold') || ...
    ~isfield(cfg.threshold, 'single_mode') || ...
    ~isfield(cfg, 'ode') || ...
    ~all(isfield(cfg.ode, {'steps', 'oracle_mode'})) || ...
    ~isstruct(resource) || ~all(isfield(resource, ...
    {'start_tic', 'hard_s', 'memory_mib_max'}))
  error('I32V4:HhalfInterface', ...
    'The shifted-trace module interface is incomplete.');
end
K = c.K;
if K ~= 97.0 || ~isequal(size(c.Gplus), [194, 97]) || ...
    ~isequal(size(c.Gminus), [194, 97]) || ...
    ~isequal(size(c.Pplus), [97, 97]) || ...
    ~isequal(size(c.Pminus), [97, 97]) || ...
    ~isequal(size(c.cplus), [97, 1]) || ...
    ~isequal(size(c.cminus), [97, 1]) || ...
    numel(boundary.private.levels) ~= 4 || ...
    ~(isfinite(cfg.threshold.single_mode) && ...
    cfg.threshold.single_mode > 0.0) || ...
    ~isequal(cfg.ode.steps, 8192.0) || ...
    ~(isfinite(cfg.ode.oracle_mode) && ...
    cfg.ode.oracle_mode == fix(cfg.ode.oracle_mode) && ...
    abs(cfg.ode.oracle_mode) < 64.0) || ...
    any(~isfinite([c.mu_h, c.gamma, c.beta, c.d, c.R, ...
    c.delta_c, c.delta_w, c.X_L, c.X_R])) || ...
    any([c.gamma, c.d, c.R, c.delta_c, c.delta_w] <= 0.0)
  error('I32V4:HhalfFrozenSchema', ...
    'A frozen shifted-trace scalar or array drifted.');
end
wall_distance = min(abs([c.X_L, c.X_R]));
if c.R + c.delta_c >= wall_distance - c.delta_w
  error('I32V4:HhalfSupportOverlap', ...
    'The exterior circle collar overlaps a wall strip.');
end
gqp = boundary.private.gqp;
if ~isfield(gqp, 'circle_value_maps') || ...
    ~iscell(gqp.circle_value_maps) || isempty(gqp.circle_value_maps) || ...
    ~isfield(gqp, 'wall_value_maps') || ...
    ~iscell(gqp.wall_value_maps) || isempty(gqp.wall_value_maps)
  error('I32V4:HhalfGQPSchema', ...
    'The unique GQP value-map ledger is unavailable.');
end
end

function LOCAL_resource(resource, local_mib)
if toc(resource.start_tic) > resource.hard_s
  error('I32V4:HARD_TIME_LIMIT', 'The 1800 s hard time gate was reached.');
end
retained = 0.0;
publication = 64.0;
if isfield(resource, 'retained_mib'), retained = resource.retained_mib; end
if isfield(resource, 'publication_mib'), publication = resource.publication_mib; end
if retained + local_mib + publication > resource.memory_mib_max
  error('I32V4:HARD_MEMORY_LIMIT', ...
    'The 2048 MiB hard memory proxy was exceeded.');
end
end

function mib = LOCAL_workspace_mib()
items = whos;
mib = sum([items.bytes]) / 2^20;
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V4:UNIDENTIFIED_BLOCKER';
end
end

function out = LOCAL_empty()
out = struct('schema', 'I32V4_HHALF_LIFT_V1', ...
  'status', 'INITIALIZED', 'available', false, 'warnings', {{}}, ...
  'first_blocker', '', 'audit', struct(), 'counters', struct(), ...
  'memory', struct(), 'data', struct(), 'private', struct());
end
