function varargout = i32v3_lifting(operation, varargin)
%I32V3_LIFTING Frozen value-only lift weights, factors, and single-mode oracle.
% Purpose:
%   Return registered wall/circle mode weights or form the combined volume
%   residual factor from boundary value defects of the unchanged trial.
% Input:
%   `i32v3_lifting('weights',kind,N,Ng,certificate)` returns row weights.
%   `i32v3_lifting('run',certificate,boundary,cfg,resource)` runs lifting.
% Output:
%   Run returns finest volume factors, compact target/source/Gauss axes,
%   unique lift-associated GQP pieces, and a fixed single-mode oracle.
% Main algorithm:
%   Transform already-computed residual samples to boundary Fourier
%   coordinates, apply cubic second-order lift-source weights, and form
%     F_V+=[C+;R+;L+P+], F_V-=[C-;L-;R-P-].
% Based on:
%   design-3-2d Sections 6--8 and Section 13.
% Notes:
%   Fourier is used only for boundary residual norms and analytic lifting;
%   it never replaces a layer-potential field action.

switch char(operation)
  case 'weights'
    if numel(varargin) ~= 4
      error('I32V3:LiftWeightInterface', ...
        'weights requires kind, N, Ng, and certificate.');
    end
    varargout{1} = LOCAL_weights(varargin{:});
  case 'run'
    if numel(varargin) ~= 4
      error('I32V3:LiftingInterface', ...
        'run requires certificate, boundary, cfg, and resource.');
    end
    varargout{1} = LOCAL_run(varargin{:});
  otherwise
    error('I32V3:LiftingOperation', 'Unknown lifting operation.');
end
end

%% ==================== Volume lifting ====================
% The three Gauss levels change numerical evaluation only.

function out = LOCAL_run(c, boundary, cfg, resource)
timer = tic;
out = LOCAL_empty();
progress = struct('stage', 'entry', 'gauss_levels_completed', 0.0, ...
  'local_peak_mib', 0.0, 'complete', false);
out.audit.symbol_ledger = struct( ...
  'delta_D', 'circle exterior-minus-interior value defect', ...
  'a_wall', 'shared-minus-material wall value defect', ...
  'chi', 'cubic value-only lifting profile', ...
  'F_volume_plus', 'circle/right/propagated-left direct-sum factor', ...
  'F_volume_minus', 'circle/left/propagated-right direct-sum factor');
try
  LOCAL_validate(c, boundary, cfg, resource);
  maps = boundary.private.value_maps;
  circle_coeff.plus = LOCAL_circle_coeff(maps.circle_plus, c.R);
  circle_coeff.minus = LOCAL_circle_coeff(maps.circle_minus, c.R);
  wall_coeff.left_plus = LOCAL_wall_coeff(maps.wall_left_plus, c);
  wall_coeff.right_plus = LOCAL_wall_coeff(maps.wall_right_plus, c);
  wall_coeff.left_minus = LOCAL_wall_coeff(maps.wall_left_minus, c);
  wall_coeff.right_minus = LOCAL_wall_coeff(maps.wall_right_minus, c);
  clear maps
  factors = cell(1, 3);
  progress.stage = 'Gauss levels';
  for j = 1:3
    Ng = cfg.levels.lift_gauss(j);
    wc = LOCAL_weights('circle', size(circle_coeff.plus, 1), Ng, c);
    ww = LOCAL_weights('wall', size(wall_coeff.left_plus, 1), Ng, c);
    Cplus = wc .* circle_coeff.plus;
    Cminus = wc .* circle_coeff.minus;
    Lplus = ww .* wall_coeff.left_plus;
    Rplus = ww .* wall_coeff.right_plus;
    Lminus = ww .* wall_coeff.left_minus;
    Rminus = ww .* wall_coeff.right_minus;
    factor = struct('plus', [Cplus; Rplus; Lplus * c.Pplus], ...
      'minus', [Cminus; Lminus; Rminus * c.Pminus], ...
      'singleton', LOCAL_singleton(c, ww, Lplus, Rminus), ...
      'operation_count', LOCAL_factor_operations(Cplus, Lplus, c));
    if numel(factor.singleton) ~= 4.0 * cfg.levels.wall_target(end)
      error('I32V3:LiftSingletonShape', ...
        'The four disjoint singleton blocks were not retained.');
    end
    factors{j} = factor;
    if j == 3
      finest_blocks = LOCAL_finest_block_norms(factor, Cplus, Cminus, ...
        Lplus, Lminus, Rplus, Rminus, c);
    end
    progress.gauss_levels_completed = j;
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      LOCAL_workspace_mib());
    LOCAL_resource(resource, progress.local_peak_mib);
  end
  private.factor = factors{3};
  private.axes.gauss = LOCAL_axis(factors);
  private.axes.target = LOCAL_combine_axis( ...
    boundary.private.axes.value_target_circle, ...
    boundary.private.axes.value_target_wall);
  private.axes.source = LOCAL_combine_axis( ...
    boundary.private.axes.value_source_circle, ...
    boundary.private.axes.value_source_wall);
  private.gqp_factors = [boundary.private.gqp_factors.volume_circle, ...
    boundary.private.gqp_factors.volume_wall];
  oracle = LOCAL_single_mode_oracle(c, cfg);
  out.data = struct('oracle', oracle, ...
    'factor_norm', LOCAL_factor_norm(private.factor), ...
    'block_norms', finest_blocks, ...
    'singleton_block_count', 4.0, ...
    'circle_rows', cfg.levels.circle_target(end), ...
    'wall_rows_per_block', cfg.levels.wall_target(end), ...
    'gqp_piece_names', {LOCAL_names(private.gqp_factors)});
  if ~oracle.pass
    out.warnings{end + 1} = 'LIFT_SINGLE_MODE_ORACLE_WARNING';
  end
  out.private = private;
  out.audit.fourier_use = 'boundary residual coordinates only';
  out.audit.circle_jacobian = 'r/R included';
  out.audit.rho_scaling = 'rho^(-1/2) in the inner collar';
  out.audit.gamma_scaling = 'gamma^(-1/2) applied to both lift families';
  out.audit.block_norms_cap_contribution = 0.0;
  out.audit.block_norms_are_diagnostic_only = true;
  out.audit.density_resolve_count = 0.0;
  out.counters = struct('density_solves', 0.0, ...
    'kernel_calls', 0.0, 'image_sum_calls', 0.0, ...
    'rayleigh_field_calls', 0.0);
  out.available = true;
  out.status = 'COMPLETE';
  progress.stage = 'complete';
  progress.complete = true;
  clear factors circle_coeff wall_coeff private
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
  'largest_object', 'finest combined volume factor');
out.audit.elapsed_s = toc(timer);
end

%% ==================== Frozen lift weights ====================
% These weights include every Jacobian and coefficient in Section 13.

function weights = LOCAL_weights(kind, N, Ng, c)
N = double(N);
Ng = double(Ng);
if ~(isscalar(N) && N >= 2.0 && N == fix(N) && mod(N, 2.0) == 0.0 && ...
    isscalar(Ng) && Ng >= 1.0 && Ng == fix(Ng))
  error('I32V3:LiftWeightOrder', 'Lift mode or Gauss order is invalid.');
end
[t, wg] = LOCAL_gauss(Ng, 0.0, 1.0);
chi = 1.0 - 3.0 * t.^2 + 2.0 * t.^3;
chi1 = -6.0 * t + 6.0 * t.^2;
chi2 = -6.0 + 12.0 * t;
orders = (-N / 2.0:N / 2.0 - 1.0).';
switch char(kind)
  case 'wall'
    alpha = c.beta + 2.0 * pi * orders / c.d;
    source = -chi2.' / c.delta_w^2 + ...
      (alpha.^2 - c.mu_h) .* chi.';
    squared = c.delta_w * (abs(source).^2 * wg);
  case 'circle'
    squared = zeros(N, 1);
    rout = c.R + c.delta_c * t;
    hout = -0.5 * chi;
    h1out = -0.5 * chi1 / c.delta_c;
    h2out = -0.5 * chi2 / c.delta_c^2;
    for j = 1:Ng
      source = -h2out(j) - h1out(j) / rout(j) + ...
        (orders.^2 / rout(j)^2 - c.mu_h) * hout(j);
      squared = squared + c.delta_c * wg(j) * (rout(j) / c.R) ...
        * abs(source).^2;
    end
    rin = c.R - c.delta_c * t;
    hin = 0.5 * chi;
    h1in = -0.5 * chi1 / c.delta_c;
    h2in = 0.5 * chi2 / c.delta_c^2;
    for j = 1:Ng
      source = -h2in(j) - h1in(j) / rin(j) + ...
        (orders.^2 / rin(j)^2 - c.mu_h * c.rho_disk) * hin(j);
      squared = squared + c.delta_c * wg(j) * (rin(j) / c.R) ...
        * abs(source).^2 / c.rho_disk;
    end
  otherwise
    error('I32V3:LiftWeightKind', 'Lift kind must be circle or wall.');
end
if ~(isfinite(c.gamma) && c.gamma > 0.0) || ...
    any(~isfinite(squared) | squared < 0.0)
  error('I32V3:LiftWeightUnavailable', 'A lift weight is invalid.');
end
weights = sqrt(max(0.0, squared)) / sqrt(c.gamma);
end

function [nodes, weights] = LOCAL_gauss(N, lower, upper)
indices = (1.0:N - 1.0).';
offdiag = indices ./ sqrt(4.0 * indices.^2 - 1.0);
J = diag(offdiag, 1) + diag(offdiag, -1);
[vectors, values] = eig(J, 'vector');
[values, order] = sort(values);
vectors = vectors(:, order);
nodes = (upper - lower) * (values + 1.0) / 2.0 + lower;
weights = (upper - lower) * vectors(1, :).^2;
weights = weights(:);
expected_sum = upper - lower;
if abs(sum(weights) - expected_sum) > ...
    128.0 * eps('double') * max(1.0, abs(expected_sum))
  error('I32V3:GaussWeightNormalization', ...
    'Gauss--Legendre weights do not integrate the constant mode exactly.');
end
end

%% ==================== Fourier maps and singleton blocks ====================
% Midpoint origins and physical Bloch gauge are explicit.

function coeff = LOCAL_circle_coeff(samples, R)
N = size(samples, 1);
orders = (-N / 2.0:N / 2.0 - 1.0).';
coeff = sqrt(2.0 * pi * R) * ...
  exp(-1i * pi * orders / N) .* ...
  (fftshift(fft(samples, [], 1), 1) / N);
end

function coeff = LOCAL_wall_coeff(samples, c)
N = size(samples, 1);
orders = (-N / 2.0:N / 2.0 - 1.0).';
y = -c.d / 2.0 + c.d * ((0.0:N - 1.0).' + 0.5) / N;
gauge = exp(-1i * c.beta * y) .* samples;
coeff = sqrt(c.d) * exp(1i * pi * orders) .* ...
  exp(-1i * pi * orders / N) .* ...
  (fftshift(fft(gauge, [], 1), 1) / N);
end

function singleton = LOCAL_singleton(c, wall_weight, Lplus, Rminus)
left = LOCAL_pad(LOCAL_wall_coeff( ...
  c.center_wall_jumps.left_value_lift_source, c), numel(wall_weight));
right = LOCAL_pad(LOCAL_wall_coeff( ...
  c.center_wall_jumps.right_value_lift_source, c), numel(wall_weight));
center = [wall_weight .* left; wall_weight .* right];
lead = [Lplus * c.cplus; Rminus * c.cminus];
singleton = [center; lead];
end

function padded = LOCAL_pad(value, N)
old = size(value, 1);
padded = complex(zeros(N, size(value, 2)));
start = N / 2.0 - old / 2.0 + 1.0;
padded(start:start + old - 1.0, :) = value;
end

%% ==================== Compact axes and oracle ====================
% Axis returns contain positive Grams and no coarse dense factors.

function axis = LOCAL_axis(factors)
K = size(factors{1}.plus, 2);
axis.level_plus_gram = complex(zeros(K, K, 3));
axis.level_minus_gram = complex(zeros(K, K, 3));
axis.singleton_squared = zeros(3, 1);
operations = 0.0;
for j = 1:3
  axis.level_plus_gram(:, :, j) = factors{j}.plus' * factors{j}.plus;
  axis.level_minus_gram(:, :, j) = factors{j}.minus' * factors{j}.minus;
  axis.singleton_squared(j) = real(factors{j}.singleton' * ...
    factors{j}.singleton);
  operations = operations + factors{j}.operation_count + ...
    (size(factors{j}.plus, 1) + size(factors{j}.minus, 1)) * K^2;
end
for j = 1:2
  dp = factors{j + 1}.plus - factors{j}.plus;
  dm = factors{j + 1}.minus - factors{j}.minus;
  ds = factors{j + 1}.singleton - factors{j}.singleton;
  prefix = sprintf('delta%d%d', j - 1, j);
  axis.([prefix, '_plus_gram']) = dp' * dp;
  axis.([prefix, '_minus_gram']) = dm' * dm;
  axis.([prefix, '_singleton_squared']) = real(ds' * ds);
  operations = operations + ...
    (size(dp, 1) + size(dm, 1)) * K^2 + numel(ds);
end
axis.operation_count = operations;
end

function combined = LOCAL_combine_axis(circle, wall)
combined = circle;
combined.level_plus_gram = circle.level_plus_gram + wall.level_plus_gram;
combined.level_minus_gram = circle.level_minus_gram + wall.level_minus_gram;
combined.singleton_squared = circle.singleton_squared + wall.singleton_squared;
for name = {'delta01', 'delta12'}
  prefix = name{1};
  combined.([prefix, '_plus_gram']) = ...
    circle.([prefix, '_plus_gram']) + wall.([prefix, '_plus_gram']);
  combined.([prefix, '_minus_gram']) = ...
    circle.([prefix, '_minus_gram']) + wall.([prefix, '_minus_gram']);
  combined.([prefix, '_singleton_squared']) = ...
    circle.([prefix, '_singleton_squared']) + ...
    wall.([prefix, '_singleton_squared']);
end
combined.operation_count = circle.operation_count + wall.operation_count + ...
  10.0 * size(circle.level_plus_gram, 1)^2;
end

function oracle = LOCAL_single_mode_oracle(c, cfg)
N = 1024.0;
ell = 7.0;
theta = 2.0 * pi * ((0.0:N - 1.0).' + 0.5) / N;
circle_samples = exp(1i * ell * theta) / sqrt(2.0 * pi * c.R);
circle_coeff = LOCAL_circle_coeff(circle_samples, c.R);
circle_index = N / 2.0 + ell + 1.0;
circle_leak = norm(circle_coeff([1:circle_index - 1, ...
  circle_index + 1:end]));
y = -c.d / 2.0 + c.d * ((0.0:N - 1.0).' + 0.5) / N;
wall_samples = exp(1i * (c.beta + 2.0 * pi * ell / c.d) * y) / sqrt(c.d);
wall_coeff = LOCAL_wall_coeff(wall_samples, c);
wall_index = N / 2.0 + ell + 1.0;
wall_leak = norm(wall_coeff([1:wall_index - 1, wall_index + 1:end]));
wc = LOCAL_weights('circle', N, 128.0, c);
ww = LOCAL_weights('wall', N, 128.0, c);
[wc_ref, ww_ref] = LOCAL_single_mode_reference(ell, c, 128.0);
defects = [abs(circle_coeff(circle_index) - 1.0), circle_leak, ...
  abs(wall_coeff(wall_index) - 1.0), wall_leak, ...
  abs(wc(circle_index) - wc_ref) / max(wc_ref, realmin), ...
  abs(ww(wall_index) - ww_ref) / max(ww_ref, realmin)];
oracle = struct('mode', ell, 'defects', defects, ...
  'maximum_defect', max(defects), 'threshold', cfg.threshold.single_mode, ...
  'pass', max(defects) <= cfg.threshold.single_mode, ...
  'checks', {{'circle Fourier normalization', 'circle leakage', ...
  'wall gauge/origin normalization', 'wall leakage', ...
  'circle Jacobian/rho/gamma weight', 'wall strip/gamma weight'}});
end

function [circle_weight, wall_weight] = ...
    LOCAL_single_mode_reference(ell, c, Ng)
if Ng ~= 128.0
  error('I32V3:SingleModeReferenceOrder', ...
    'The independent single-mode reference is frozen at Ng=128.');
end
alpha = c.beta + 2.0 * pi * ell / c.d;
amplitude = alpha^2 - c.mu_h;
wall_coefficients = [6.0 / c.delta_w^2 + amplitude; ...
  -12.0 / c.delta_w^2; -3.0 * amplitude; 2.0 * amplitude];
wall_integral = 0.0;
for j = 1:4
  for k = 1:4
    wall_integral = wall_integral + ...
      wall_coefficients(j) * wall_coefficients(k) / (j + k - 1.0);
  end
end
wall_weight = sqrt(c.delta_w * wall_integral / c.gamma);

outer_integrand = @(t) LOCAL_circle_reference_integrand( ...
  t, ell, c, 1.0);
inner_integrand = @(t) LOCAL_circle_reference_integrand( ...
  t, ell, c, -1.0);
circle_squared = integral(outer_integrand, 0.0, 1.0, ...
  'AbsTol', 1.0e-13, 'RelTol', 1.0e-13) + ...
  integral(inner_integrand, 0.0, 1.0, ...
  'AbsTol', 1.0e-13, 'RelTol', 1.0e-13);
circle_weight = sqrt(circle_squared / c.gamma);
end

function value = LOCAL_circle_reference_integrand(t, ell, c, side)
chi = 1.0 - 3.0 * t.^2 + 2.0 * t.^3;
chi1 = -6.0 * t + 6.0 * t.^2;
chi2 = -6.0 + 12.0 * t;
if side > 0.0
  radius = c.R + c.delta_c * t;
  h = -0.5 * chi;
  h1 = -0.5 * chi1 / c.delta_c;
  h2 = -0.5 * chi2 / c.delta_c^2;
  density_weight = 1.0;
  mass = c.mu_h;
else
  radius = c.R - c.delta_c * t;
  h = 0.5 * chi;
  h1 = -0.5 * chi1 / c.delta_c;
  h2 = 0.5 * chi2 / c.delta_c^2;
  density_weight = 1.0 / c.rho_disk;
  mass = c.mu_h * c.rho_disk;
end
source = -h2 - h1 ./ radius + ...
  (ell^2 ./ radius.^2 - mass) .* h;
value = c.delta_c * (radius / c.R) .* abs(source).^2 * density_weight;
end

function operations = LOCAL_factor_operations(C, W, c)
K = c.K;
operations = (size(C, 1) + 2.0 * size(W, 1)) * K^2 + ...
  (size(C, 1) + 4.0 * size(W, 1)) * K;
end

function blocks = LOCAL_finest_block_norms(factor, Cplus, Cminus, ...
    Lplus, Lminus, Rplus, Rminus, c)
nwall = size(Lplus, 1);
left_propagated = Lplus * c.Pplus;
right_propagated = Rminus * c.Pminus;
blocks.circle_collar = sqrt(norm(Cplus, 'fro')^2 + ...
  norm(Cminus, 'fro')^2);
blocks.left_wall_strip = sqrt(norm(left_propagated, 'fro')^2 + ...
  norm(Lminus, 'fro')^2);
blocks.right_wall_strip = sqrt(norm(Rplus, 'fro')^2 + ...
  norm(right_propagated, 'fro')^2);
blocks.center_left = norm(factor.singleton(1:nwall));
blocks.center_right = norm(factor.singleton(nwall + (1:nwall)));
blocks.first_plus = norm(factor.singleton(2.0 * nwall + (1:nwall)));
blocks.first_minus = norm(factor.singleton(3.0 * nwall + (1:nwall)));
direct_sum_squared = blocks.circle_collar^2 + blocks.left_wall_strip^2 + ...
  blocks.right_wall_strip^2 + blocks.center_left^2 + ...
  blocks.center_right^2 + blocks.first_plus^2 + blocks.first_minus^2;
factor_squared = norm(factor.plus, 'fro')^2 + ...
  norm(factor.minus, 'fro')^2 + norm(factor.singleton)^2;
blocks.direct_sum_identity_defect = abs(factor_squared - direct_sum_squared) ...
  / max(factor_squared, realmin);
blocks.cap_contribution = 0.0;
blocks.diagnostic_only = true;
end

function value = LOCAL_factor_norm(factor)
value = sqrt(norm(factor.plus, 'fro')^2 + ...
  norm(factor.minus, 'fro')^2 + norm(factor.singleton)^2);
end

function names = LOCAL_names(factors)
names = cell(1, numel(factors));
for j = 1:numel(factors), names{j} = factors{j}.name; end
end

%% ==================== Contracts and resources ====================
% No scientific fallback or parameter adaptation is present.

function LOCAL_validate(c, boundary, cfg, resource)
if ~isstruct(c) || ~all(isfield(c, {'mu_h', 'gamma', 'beta', 'd', ...
    'R', 'rho_disk', 'delta_c', 'delta_w', 'Pplus', 'Pminus', ...
    'cplus', 'cminus', 'center_wall_jumps'})) || ...
    ~isstruct(boundary) || ~isfield(boundary, 'available') || ...
    ~boundary.available || ~isfield(boundary, 'private') || ...
    ~isstruct(cfg) || ~isequal(cfg.levels.lift_gauss, [32.0, 64.0, 128.0]) || ...
    ~isstruct(resource) || ~all(isfield(resource, ...
    {'start_tic', 'hard_s', 'memory_mib_max'}))
  error('I32V3:LiftingInterface', 'The lifting interface is incomplete.');
end
end

function LOCAL_resource(resource, local_mib)
if toc(resource.start_tic) > resource.hard_s
  error('I32V3:HARD_TIME_LIMIT', 'The hard lifting time gate was reached.');
end
retained = 0.0;
publication = 64.0;
if isfield(resource, 'retained_mib'), retained = resource.retained_mib; end
if isfield(resource, 'publication_mib'), publication = resource.publication_mib; end
if retained + local_mib + publication > resource.memory_mib_max
  error('I32V3:HARD_MEMORY_LIMIT', 'The hard lifting memory gate was reached.');
end
end

function mib = LOCAL_workspace_mib()
items = whos;
mib = sum([items.bytes]) / 2^20;
end

function out = LOCAL_empty()
out = struct('schema', 'I32V3_LIFTING_V1', 'status', 'INITIALIZED', ...
  'available', false, 'warnings', {{}}, 'first_blocker', '', ...
  'audit', struct(), 'counters', struct(), 'memory', struct(), ...
  'data', struct(), 'private', struct());
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V3:UNIDENTIFIED_BLOCKER';
end
end
