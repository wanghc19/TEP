function out = i32v4_fit_cap(c, anchor, boundary, hhalf, cfg, resource)
%I32V4_FIT_CAP Contract full P powers and fit four scalar sequences.
% Purpose:
%   Form B_W, B_Gamma, shifted-trace B_V, and M on four coupled levels;
%   fit B_inf+C*N^(-p); aggregate fit, GQP, roundoff, and full-P rows;
%   update the empirical companion field candidate and nominal interval.
% Input:
%   c        - Frozen double-valued certificate.
%   anchor   - Frozen ordinary field anchor.
%   boundary - Coupled normal/value layer-potential actions.
%   hhalf    - Shifted trace factors and right-inverse constants.
%   cfg      - Frozen design-3-2e configuration.
%   resource - Shared hard time and memory gate.
% Output:
%   out.data - Four sequences, fits, empirical rows, field, and estimator.
% Main algorithm:
%   Retain complete nonnormal P matrices and the frozen tail formula, fit
%   scalar centers through a deterministic one-dimensional p search, and
%   keep invalid fits local to their own component.
% Based on:
%   design-3-2e Sections 7--10.
% Notes:
%   All results are EMPIRICAL / UNQUALIFIED. No geometric d_n gate is used.

timer = tic;
out = LOCAL_empty();
try
  LOCAL_validate(c, anchor, boundary, hhalf, cfg, resource);
  level_count = numel(cfg.levels.circle);
  C_A = 1.0 + c.mu_h / c.gamma;
  component_names = {'wall', 'circle', 'lift'};
  B = struct('wall', zeros(1, level_count), ...
    'circle', zeros(1, level_count), 'lift', zeros(1, level_count), ...
    'wall_Hhalf', zeros(1, level_count), ...
    'circle_Hhalf', zeros(1, level_count));
  endpoints = struct();

  % --- stage 1: four J=32 component centers ---
  for level_idx = 1:level_count
    LOCAL_resource(resource, 0.0);
    factors = struct('wall', ...
      boundary.private.levels{level_idx}.wall_normal_factor, ...
      'circle', boundary.private.levels{level_idx}.circle_normal_factor, ...
      'lift', hhalf.private.levels{level_idx}.volume_factor);
    for name_idx = 1:numel(component_names)
      name = component_names{name_idx};
      endpoints.(name){level_idx} = LOCAL_endpoint( ...
        factors.(name), c, cfg.levels.fullp(end), cfg);
      B.(name)(level_idx) = endpoints.(name){level_idx}.B;
    end
    circle_rows = hhalf.private.levels{level_idx}.circle_factor_rows;
    circle_factor = LOCAL_lift_component(factors.lift, circle_rows, ...
      'circle');
    wall_factor = LOCAL_lift_component(factors.lift, circle_rows, 'wall');
    circle_endpoint = LOCAL_endpoint(circle_factor, c, ...
      cfg.levels.fullp(end), cfg);
    wall_endpoint = LOCAL_endpoint(wall_factor, c, ...
      cfg.levels.fullp(end), cfg);
    B.circle_Hhalf(level_idx) = circle_endpoint.B / ...
      hhalf.data.C_E_circle;
    B.wall_Hhalf(level_idx) = wall_endpoint.B / hhalf.data.C_E_wall;
    clear circle_factor wall_factor circle_endpoint wall_endpoint
  end
  B.volume = C_A * B.lift;
  B.majorant = B.wall + B.circle + B.volume;

  % --- stage 2: J=8/16/32 finest rows and arithmetic paths ---
  finest = level_count;
  finest_factors = struct('wall', ...
    boundary.private.levels{finest}.wall_normal_factor, ...
    'circle', boundary.private.levels{finest}.circle_normal_factor, ...
    'lift', hhalf.private.levels{finest}.volume_factor);
  for name_idx = 1:numel(component_names)
    name = component_names{name_idx};
    for fullp_idx = 1:numel(cfg.levels.fullp)
      J = cfg.levels.fullp(fullp_idx);
      fullp.(name).endpoint{fullp_idx} = ...
        LOCAL_endpoint(finest_factors.(name), c, J, cfg);
      fullp.(name).B(fullp_idx) = ...
        fullp.(name).endpoint{fullp_idx}.B;
    end
    fullp.(name).cap = max(abs(fullp.(name).B(1:2) - ...
      fullp.(name).B(3)));
    fullp.(name).resolved = all(isfinite(fullp.(name).B)) && ...
      isfinite(fullp.(name).cap) && fullp.(name).cap >= 0.0;
  end
  fullp.volume = fullp.lift;
  fullp.volume.B = C_A * fullp.lift.B;
  fullp.volume.cap = C_A * fullp.lift.cap;
  fullp.volume.endpoint = fullp.lift.endpoint;
  fullp.majorant.B = fullp.wall.B + fullp.circle.B + fullp.volume.B;
  fullp.majorant.direct_change = max(abs(fullp.majorant.B(1:2) - ...
    fullp.majorant.B(3)));
  fullp.majorant.cap = fullp.wall.cap + fullp.circle.cap + ...
    fullp.volume.cap;
  fullp.majorant.resolved = fullp.wall.resolved && ...
    fullp.circle.resolved && fullp.volume.resolved && ...
    all(isfinite(fullp.majorant.B)) && ...
    isfinite(fullp.majorant.direct_change) && ...
    isfinite(fullp.majorant.cap) && fullp.majorant.cap >= 0.0;

  roundoff.wall = LOCAL_roundoff(fullp.wall.endpoint{3}, cfg);
  roundoff.circle = LOCAL_roundoff(fullp.circle.endpoint{3}, cfg);
  roundoff.lift = LOCAL_roundoff(fullp.lift.endpoint{3}, cfg);
  roundoff.volume = C_A * roundoff.lift;
  scalar_sum = cfg.roundoff.multiplier * cfg.roundoff.eps * 2.0 * ...
    max([1.0, abs(B.wall(end)), abs(B.circle(end)), ...
    abs(B.volume(end)), abs(B.majorant(end))]);
  roundoff.majorant = roundoff.wall + roundoff.circle + ...
    roundoff.volume + scalar_sum;

  % --- stage 3: unique fixed-GQP empirical rows ---
  gqp.wall = LOCAL_gqp_row(boundary.private.gqp.wall_normal_factors, ...
    c, cfg, 1.0);
  gqp.circle = LOCAL_gqp_row( ...
    boundary.private.gqp.circle_normal_factors, c, cfg, 1.0);
  gqp.lift = LOCAL_gqp_row(hhalf.private.gqp_volume_factors, ...
    c, cfg, 1.0);
  gqp.volume = gqp.lift;
  gqp.volume.piece_norms = C_A * gqp.lift.piece_norms;
  gqp.volume.scale = C_A * gqp.lift.scale;
  gqp.volume.remainder = C_A * gqp.lift.remainder;
  gqp.majorant = struct('scale', gqp.wall.scale + gqp.circle.scale + ...
    gqp.volume.scale, 'remainder', gqp.wall.remainder + ...
    gqp.circle.remainder + gqp.volume.remainder, ...
    'relative_factor', cfg.gqp.relative_uncertainty, ...
    'counted_once', true, 'component_sum_only', true);

  % --- stage 4: scalar full/LOO fits or arithmetic/GQP plateaus ---
  fit.wall = LOCAL_fit_sequence(cfg.levels.circle, B.wall, ...
    gqp.wall.remainder + roundoff.wall, cfg);
  fit.circle = LOCAL_fit_sequence(cfg.levels.circle, B.circle, ...
    gqp.circle.remainder + roundoff.circle, cfg);
  fit.volume = LOCAL_fit_sequence(cfg.levels.circle, B.volume, ...
    gqp.volume.remainder + roundoff.volume, cfg);
  fit.majorant = LOCAL_fit_sequence(cfg.levels.circle, B.majorant, ...
    gqp.majorant.remainder + roundoff.majorant, cfg);

  caps.wall = LOCAL_component_cap(fit.wall, gqp.wall, roundoff.wall, ...
    fullp.wall);
  caps.circle = LOCAL_component_cap(fit.circle, gqp.circle, ...
    roundoff.circle, fullp.circle);
  caps.volume = LOCAL_component_cap(fit.volume, gqp.volume, ...
    roundoff.volume, fullp.volume);
  majorant_rows = [fit.majorant.remainder, gqp.wall.remainder, ...
    gqp.circle.remainder, gqp.volume.remainder, ...
    fullp.majorant.cap, roundoff.majorant];
  if all(isfinite(majorant_rows)) && all(majorant_rows >= 0.0)
    caps.epsilon_M_emp = sum(majorant_rows);
  else
    caps.epsilon_M_emp = NaN;
  end
  caps.majorant = struct('fit', fit.majorant.remainder, ...
    'gqp', gqp.majorant.remainder, 'roundoff', roundoff.majorant, ...
    'roundoff_scalar_sum', scalar_sum, 'fullp', fullp.majorant.cap, ...
    'total', caps.epsilon_M_emp, ...
    'component_fit_caps_added', false);
  caps.gqp = gqp;
  caps.roundoff = roundoff;
  caps.fullp = fullp;

  % --- stage 5: once-corrected field candidate and nominal interval ---
  field = LOCAL_field(c, anchor, B.lift(end), cfg);
  caps.epsilon_N_emp = field.epsilon_N_emp;
  caps.epsilon_N_GQP_emp = 0.0;
  estimator = struct('M_finest', B.majorant(end), ...
    'field_companion_candidate', field.N_comp_lower, ...
    'q_emp', NaN, 'k_interval', struct('lower', NaN, 'upper', NaN, ...
    'width', NaN, 'width_below_1e6', false, ...
    'label', 'EMPIRICAL / UNQUALIFIED'));
  unresolved = {};
  warnings = {};
  if ~fit.wall.resolved, unresolved{end + 1} = 'FIT_WALL'; end
  if ~fit.circle.resolved, unresolved{end + 1} = 'FIT_CIRCLE'; end
  if ~fit.volume.resolved, unresolved{end + 1} = 'FIT_VOLUME'; end
  if ~fit.majorant.resolved, unresolved{end + 1} = 'FIT_MAJORANT'; end
  if ~isfinite(caps.epsilon_M_emp)
    unresolved{end + 1} = 'EPSILON_M';
  end
  if field.N_comp_lower > 0.0 && isfinite(caps.epsilon_M_emp)
    estimator.q_emp = (B.majorant(end) + caps.epsilon_M_emp) / ...
      sqrt(field.N_comp_lower);
    if isfinite(estimator.q_emp) && estimator.q_emp < 1.0
      q = estimator.q_emp;
      mu_lower = max(0.0, (c.mu_h - q * c.gamma) / (1.0 + q));
      mu_upper = (c.mu_h + q * c.gamma) / (1.0 - q);
      if isfinite(mu_upper) && mu_upper >= 0.0
        estimator.k_interval.lower = sqrt(mu_lower);
        estimator.k_interval.upper = sqrt(mu_upper);
        estimator.k_interval.width = estimator.k_interval.upper - ...
          estimator.k_interval.lower;
        estimator.k_interval.width_below_1e6 = ...
          estimator.k_interval.width < cfg.threshold.interval_width;
      end
    else
      warnings{end + 1} = 'Q_EMP_NOT_BELOW_ONE';
      unresolved{end + 1} = 'NOMINAL_INTERVAL';
    end
  else
    unresolved{end + 1} = 'Q_EMP_AND_INTERVAL';
  end
  if field.N_comp_lower <= 0.0
    unresolved{end + 1} = 'COMPANION_FIELD_CANDIDATE';
  end

  out.data = struct('sequence', struct('N', cfg.levels.circle, ...
    'N_wall', cfg.levels.wall, 'B_W', B.wall, ...
    'B_Gamma', B.circle, 'L', B.lift, ...
    'wall_Hhalf_norm', B.wall_Hhalf, ...
    'circle_Hhalf_norm', B.circle_Hhalf, ...
    'B_V_Hhalf', B.volume, 'M', B.majorant), ...
    'fit', fit, 'caps', caps, 'field', field, ...
    'estimator', estimator, ...
    'unresolved', {unique(unresolved, 'stable')});
  out.warnings = unique(warnings, 'stable');
  out.audit = struct('full_P_complete', true, ...
    'modal_diagonalization_calls', 0.0, ...
    'geometric_difference_gate_calls', 0.0, ...
    'log_B_fit_calls', 0.0, 'component_fit_caps_added_to_M', false, ...
    'epsilon_N_subtraction_count', 1.0, ...
    'GQP_piece_counted_once', true, ...
    'tail_counted_in_centers', true);
  out.available = true;
  out.status = 'COMPLETE';
catch err
  out.status = 'BLOCKED';
  out.first_blocker = LOCAL_identifier(err);
  out.audit.exception_message = err.message;
end
info = whos('out');
out.memory = struct('local_peak_mib', info.bytes / 2^20, ...
  'retained_mib', info.bytes / 2^20, ...
  'measurement', 'compact MATLAB result object proxy');
out.audit.elapsed_s = toc(timer);
end

%% ==================== Complete-P endpoints ====================
% These helpers preserve full matrices and the frozen complete-tail formula.

function component = LOCAL_lift_component(total, circle_rows, name)
if ~(isscalar(circle_rows) && isfinite(circle_rows) && ...
    circle_rows >= 1.0 && circle_rows == floor(circle_rows) && ...
    size(total.plus, 1) > circle_rows && ...
    size(total.minus, 1) > circle_rows)
  error('I32V4:LiftComponentRows', ...
    'The shifted-trace component row split is invalid.');
end
if strcmp(name, 'circle')
  component = struct('plus', total.plus(1:circle_rows, :), ...
    'minus', total.minus(1:circle_rows, :), ...
    'singleton', zeros(0, 1, 'like', total.singleton));
elseif strcmp(name, 'wall')
  component = struct('plus', total.plus(circle_rows + 1:end, :), ...
    'minus', total.minus(circle_rows + 1:end, :), ...
    'singleton', total.singleton);
else
  error('I32V4:LiftComponentName', ...
    'The shifted-trace component name is invalid.');
end
end

function endpoint = LOCAL_endpoint(factor, c, J, cfg)
plus = LOCAL_side(factor.plus, c.Pplus, c.cplus, J, cfg);
minus = LOCAL_side(factor.minus, c.Pminus, c.cminus, J, cfg);
squared = real(factor.singleton' * factor.singleton) + ...
  plus.finite + plus.tail + minus.finite + minus.tail;
tol = cfg.roundoff.multiplier * cfg.roundoff.eps * max([1.0, ...
  abs(squared), norm(factor.singleton)^2]);
if squared < -tol
  error('I32V4:NegativeEndpoint', 'A full-P endpoint is negative.');
end
B = sqrt(max(0.0, squared));
[vector_plus, ops_plus] = LOCAL_action(factor.plus, c.Pplus, c.cplus, J);
[vector_minus, ops_minus] = LOCAL_action( ...
  factor.minus, c.Pminus, c.cminus, J);
vector = [factor.singleton(:); vector_plus; vector_minus; ...
  sqrt(max(0.0, plus.tail)); sqrt(max(0.0, minus.tail))];
paths = [B, norm(vector), sqrt(max(0.0, LOCAL_kahan(abs(vector).^2)))];
endpoint = struct('B', B, 'paths', paths, ...
  'tail_plus_squared', plus.tail, 'tail_minus_squared', minus.tail, ...
  'tail_combined_norm', sqrt(max(0.0, plus.tail + minus.tail)), ...
  'operations', plus.operations + minus.operations + ops_plus + ...
  ops_minus + numel(factor.singleton), 'J', J);
end

function side = LOCAL_side(F, P, state, J, cfg)
K = size(P, 1);
W0 = F' * F;
[Wd, PNd, ops_d] = LOCAL_doubling(W0, P, J);
[Wr, PNr, ops_r] = LOCAL_direct_gram(W0, P, J);
power_defect = norm(PNd - PNr, 2);
a_hi = norm(PNd, 2) + power_defect + ...
  cfg.roundoff.multiplier * K * cfg.roundoff.eps * ...
  max([1.0, norm(PNd, 2), norm(PNr, 2)]);
omega_W = norm(Wd - Wr, 2) + ...
  cfg.roundoff.multiplier * K * cfg.roundoff.eps * ...
  max([norm(Wd, 2), norm(Wr, 2), realmin]);
finite = real(state' * Wd * state);
negative_tol = cfg.roundoff.multiplier * K * cfg.roundoff.eps * ...
  norm(Wd, 2) * norm(state)^2;
if finite < -negative_tol
  error('I32V4:IndefiniteFullPGram', ...
    'A full-P finite Gram is significantly negative.');
end
if ~(isfinite(a_hi) && a_hi < 1.0)
  error('I32V4:FullPTailUnavailable', ...
    'The complete-matrix tail cannot be formed.');
end
finite = max(0.0, finite);
tail = a_hi^2 / (1.0 - a_hi^2) * ...
  (norm(Wd, 2) + omega_W) * norm(state)^2;
if ~(isfinite(tail) && tail >= 0.0)
  error('I32V4:FullPTailUnavailable', 'A tail value is invalid.');
end
side = struct('finite', finite, 'tail', tail, 'a_hi', a_hi, ...
  'operations', size(F, 1) * K^2 + ops_d + ops_r + 2.0 * K^2);
end

function [W, PN, operations] = LOCAL_doubling(W0, P, J)
W = W0;
PN = P;
current = 1.0;
K = size(P, 1);
operations = 0.0;
while current < J
  W = W + PN' * W * PN;
  PN = PN * PN;
  operations = operations + 3.0 * K^3 + K^2;
  current = 2.0 * current;
end
end

function [W, PN, operations] = LOCAL_direct_gram(W0, P, J)
K = size(P, 1);
W = zeros(K, K, 'like', W0);
PN = eye(K, 'like', P);
operations = 0.0;
for power_idx = 1:J
  W = W + PN' * W0 * PN;
  PN = P * PN;
  operations = operations + 3.0 * K^3 + K^2;
end
end

function [vector, operations] = LOCAL_action(F, P, state, J)
rows = size(F, 1);
K = size(P, 1);
vector = complex(zeros(rows * J, 1));
power_state = state;
operations = 0.0;
for power_idx = 1:J
  ids = (power_idx - 1.0) * rows + (1.0:rows);
  vector(ids) = F * power_state;
  power_state = P * power_state;
  operations = operations + rows * K + K^2;
end
end

function value = LOCAL_roundoff(endpoint, cfg)
spread = max([abs(endpoint.paths(1) - endpoint.paths(2)), ...
  abs(endpoint.paths(1) - endpoint.paths(3)), ...
  abs(endpoint.paths(2) - endpoint.paths(3))]);
omega = cfg.roundoff.multiplier * cfg.roundoff.eps * ...
  max(1.0, endpoint.operations) * ...
  max([realmin, abs(endpoint.paths)]);
value = 2.0 * max(spread, omega);
end

%% ==================== Fixed-GQP empirical rows ====================
% Unique non-cancelling GQP-only pieces are counted once at the finest level.

function row = LOCAL_gqp_row(pieces, c, cfg, scale_multiplier)
if ~iscell(pieces)
  error('I32V4:GQPPieceSchema', 'GQP factors must be a cell array.');
end
piece_norms = zeros(1, numel(pieces));
names = cell(1, numel(pieces));
for piece_idx = 1:numel(pieces)
  endpoint = LOCAL_endpoint(pieces{piece_idx}, c, ...
    cfg.levels.fullp(end), cfg);
  piece_norms(piece_idx) = scale_multiplier * endpoint.B;
  if isfield(pieces{piece_idx}, 'name')
    names{piece_idx} = pieces{piece_idx}.name;
  else
    names{piece_idx} = sprintf('piece_%d', piece_idx);
  end
end
scale = sum(piece_norms);
row = struct('scale', scale, ...
  'relative_factor', cfg.gqp.relative_uncertainty, ...
  'remainder', cfg.gqp.relative_uncertainty * scale, ...
  'piece_names', {names}, 'piece_norms', piece_norms, ...
  'unique_piece_count', numel(pieces), 'counted_once', true, ...
  'total_residual_added', false);
end

%% ==================== Scalar power-law fits ====================
% The unknown nonzero limit is fitted directly; log(B) is never used.

function fit = LOCAL_fit_sequence(N, B, floor_value, cfg)
fit = struct('status', 'UNRESOLVED', 'resolved', false, ...
  'plateau', false, 'floor', floor_value, 'records', [], ...
  'valid_mask', false(1, 5), 'full_p', NaN, 'full_B_inf', NaN, ...
  'full_amplitude_normalized', NaN, 'full_residual', NaN, ...
  'leave_one_out_B_inf_spread', NaN, ...
  'max_asymptote_distance', NaN, ...
  'max_prediction_residual', NaN, 'remainder', NaN, ...
  'adjacent_differences', abs(diff(B)));
if any(~isfinite([N(:); B(:); floor_value])) || ...
    any(N <= 0.0) || any(B < 0.0) || floor_value < 0.0
  return
end
if max(B) <= floor_value
  fit.status = 'PLATEAU';
  fit.resolved = true;
  fit.plateau = true;
  fit.remainder = max(abs(B - B(end)));
  fit.max_asymptote_distance = fit.remainder;
  fit.max_prediction_residual = 0.0;
  fit.leave_one_out_B_inf_spread = 0.0;
  return
end
sets = {1:4, [2, 3, 4], [1, 3, 4], [1, 2, 4], [1, 2, 3]};
records = repmat(LOCAL_fit_record(), 1, numel(sets));
for set_idx = 1:numel(sets)
  records(set_idx) = LOCAL_fit_one(N, B, sets{set_idx}, cfg);
end
valid = [records.valid];
fit.records = records;
fit.valid_mask = valid;
if records(1).valid
  fit.full_p = records(1).p;
  fit.full_B_inf = records(1).B_inf;
  fit.full_amplitude_normalized = records(1).amplitude_normalized;
  fit.full_residual = records(1).max_prediction_residual;
end
if ~any(valid)
  return
end
valid_records = records(valid);
asymptotes = [valid_records.B_inf];
asymptote_distance = abs(asymptotes - B(end));
prediction_residuals = [valid_records.max_prediction_residual];
fit.max_asymptote_distance = max(asymptote_distance);
fit.max_prediction_residual = max(prediction_residuals);
fit.remainder = fit.max_asymptote_distance + ...
  fit.max_prediction_residual;
loo_records = records(2:end);
loo_valid = [loo_records.valid];
if any(loo_valid)
  loo_asymptotes = [loo_records(loo_valid).B_inf];
  fit.leave_one_out_B_inf_spread = ...
    max(loo_asymptotes) - min(loo_asymptotes);
end
fit.status = 'VALID_FIT_SET';
fit.resolved = true;
end

function record = LOCAL_fit_one(N, B, indices, cfg)
record = LOCAL_fit_record();
record.indices = indices;
count = cfg.fit.s_grid_count;
s_grid = (1.0:count) / (count + 1.0);
objective = zeros(1, count);
for grid_idx = 1:count
  objective(grid_idx) = LOCAL_fit_objective( ...
    s_grid(grid_idx), N, B, indices, cfg);
end
[~, best_idx] = min(objective);
if best_idx <= 1 || best_idx >= count || ~isfinite(objective(best_idx))
  record.reason = 'SEARCH_ENDPOINT_OR_NONFINITE';
  return
end
options = optimset('TolX', cfg.fit.fmin_tol, ...
  'MaxIter', cfg.fit.fmin_iterations, 'Display', 'off');
[s, objective_value] = fminbnd(@(value) LOCAL_fit_objective( ...
  value, N, B, indices, cfg), s_grid(best_idx - 1), ...
  s_grid(best_idx + 1), options);
[coeff, predictions, p, condition_value, rank_value] = ...
  LOCAL_fit_linear(s, N, B, indices);
valid = all(isfinite([s, objective_value, coeff(:).', ...
  predictions, p, condition_value, rank_value])) && ...
  s > 0.0 && s < 1.0 && p > 0.0 && coeff(1) >= 0.0 && ...
  rank_value == 2.0 && condition_value >= cfg.fit.rcond_min;
if ~valid
  record.reason = 'FIT_VALIDITY_CONDITION';
  return
end
record.valid = true;
record.reason = 'VALID';
record.s = s;
record.p = p;
record.B_inf = coeff(1);
record.amplitude_normalized = coeff(2);
record.objective = objective_value;
record.predictions = predictions;
record.max_prediction_residual = max(abs(B - predictions));
record.rcond = condition_value;
record.rank = rank_value;
end

function value = LOCAL_fit_objective(s, N, B, indices, cfg)
[coeff, predictions, p, condition_value, rank_value] = ...
  LOCAL_fit_linear(s, N, B, indices);
if any(~isfinite([coeff(:).', predictions, p, condition_value, ...
    rank_value])) || p <= 0.0 || coeff(1) < 0.0 || rank_value ~= 2.0 || ...
    condition_value < cfg.fit.rcond_min
  value = realmax('double') / 16.0;
  return
end
residual = B(indices).' - predictions(indices).';
value = real(residual' * residual);
if ~isfinite(value)
  value = realmax('double') / 16.0;
end
end

function [coeff, predictions, p, condition_value, rank_value] = ...
    LOCAL_fit_linear(s, N, B, indices)
p = s / (1.0 - s);
x = exp(-p * log(N / N(1)));
A = [ones(numel(indices), 1), x(indices).'];
rank_value = rank(A);
condition_value = rcond(A' * A);
if rank_value == 2.0 && isfinite(condition_value) && condition_value > 0.0
  coeff = A \ B(indices).';
else
  coeff = [NaN; NaN];
end
predictions = coeff(1) + coeff(2) * x;
end

function record = LOCAL_fit_record()
record = struct('valid', false, 'reason', 'NOT_RUN', 'indices', [], ...
  's', NaN, 'p', NaN, 'B_inf', NaN, ...
  'amplitude_normalized', NaN, 'objective', NaN, ...
  'predictions', NaN(1, 4), 'max_prediction_residual', NaN, ...
  'rcond', NaN, 'rank', NaN);
end

function cap = LOCAL_component_cap(fit, gqp, roundoff, fullp)
rows = [fit.remainder, gqp.remainder, roundoff, fullp.cap];
if all(isfinite(rows)) && all(rows >= 0.0)
  total = sum(rows);
else
  total = NaN;
end
cap = struct('fit', fit.remainder, 'gqp', gqp.remainder, ...
  'roundoff', roundoff, 'fullp', fullp.cap, 'total', total);
end

%% ==================== Frozen field anchor ====================
% epsilon_N is subtracted once before the shifted companion correction.

function field = LOCAL_field(c, a, L_finest, cfg)
Fp = a.lead_field_factor_plus;
Fm = a.lead_field_factor_minus;
center = real(c.center_wall_jumps.field_squared);
levels = cfg.levels.fullp;
direct = zeros(1, numel(levels));
operations = zeros(1, numel(levels));
for level_idx = 1:numel(levels)
  [direct(level_idx), operations(level_idx)] = LOCAL_field_direct( ...
    Fp, c.Pplus, c.cplus, Fm, c.Pminus, c.cminus, ...
    center, levels(level_idx));
end
[gram8, gram_ops] = LOCAL_field_gram(Fp, c.Pplus, c.cplus, ...
  Fm, c.Pminus, c.cminus, center, levels(1));
[comp8, comp_ops] = LOCAL_field_compensated(Fp, c.Pplus, c.cplus, ...
  Fm, c.Pminus, c.cminus, center, levels(1));
historical = real(a.N_tilde);
downward = [max(0.0, historical - direct(1)), ...
  max(0.0, direct(1) - direct(2)), max(0.0, direct(2) - direct(3))];
A_obs = sum(downward);
n_compare = sum(operations) + 3.0;
omega_compare = cfg.roundoff.multiplier * n_compare * ...
  cfg.roundoff.eps * max([realmin, abs(historical), abs(direct)]);
A_N = A_obs + omega_compare;
paths = [direct(1), gram8, comp8];
path_spread = max([abs(paths(1) - paths(2)), ...
  abs(paths(1) - paths(3)), abs(paths(2) - paths(3))]);
n_path = max([operations(1), gram_ops, comp_ops]);
omega_path = cfg.roundoff.multiplier * n_path * cfg.roundoff.eps * ...
  max([realmin, abs(paths)]);
epsilon_N = A_N + 2.0 * max(path_spread, omega_path);
if any(~isfinite([direct, paths, epsilon_N, L_finest])) || ...
    epsilon_N < 0.0 || L_finest < 0.0
  error('I32V4:FieldUnavailable', 'The field candidate is invalid.');
end
r_N = max(0.0, historical - epsilon_N);
N_comp = max(0.0, sqrt(r_N) - L_finest)^2;
field = struct('N_tilde', historical, 'direct', direct, ...
  'paths_N8', paths, 'epsilon_N_emp', epsilon_N, ...
  'epsilon_N_GQP_emp', 0.0, 'r_N', r_N, 'L_finest', L_finest, ...
  'N_comp_lower', N_comp, 'epsilon_N_subtraction_count', 1.0, ...
  'epsilon_L_subtracted', false, 'enclosure_claim', false, ...
  'label', 'EMPIRICAL COMPANION FIELD-LOWER CANDIDATE');
end

function [value, operations] = LOCAL_field_direct( ...
    Fp, Pp, cp, Fm, Pm, cm, center, J)
value = center;
vp = cp;
vm = cm;
for power_idx = 1:J
  yp = Fp * vp;
  ym = Fm * vm;
  value = value + real(yp' * yp) + real(ym' * ym);
  vp = Pp * vp;
  vm = Pm * vm;
end
K = size(Pp, 1);
operations = J * (size(Fp, 1) * K + size(Fm, 1) * K + ...
  size(Fp, 1) + size(Fm, 1) + 2.0 * K^2 + 2.0);
end

function [value, operations] = LOCAL_field_gram( ...
    Fp, Pp, cp, Fm, Pm, cm, center, J)
K = size(Pp, 1);
[Wp, ~, ops_p] = LOCAL_direct_gram(Fp' * Fp, Pp, J);
[Wm, ~, ops_m] = LOCAL_direct_gram(Fm' * Fm, Pm, J);
value = center + real(cp' * Wp * cp) + real(cm' * Wm * cm);
operations = (size(Fp, 1) + size(Fm, 1)) * K^2 + ...
  ops_p + ops_m + 2.0 * (K^2 + K) + 2.0;
end

function [value, operations] = LOCAL_field_compensated( ...
    Fp, Pp, cp, Fm, Pm, cm, center, J)
terms = zeros(2.0 * J + 1.0, 1);
terms(1) = center;
vp = cp;
vm = cm;
for power_idx = 1:J
  yp = Fp * vp;
  ym = Fm * vm;
  terms(2.0 * power_idx) = real(yp' * yp);
  terms(2.0 * power_idx + 1.0) = real(ym' * ym);
  vp = Pp * vp;
  vm = Pm * vm;
end
value = LOCAL_kahan(terms);
K = size(Pp, 1);
operations = J * (size(Fp, 1) * K + size(Fm, 1) * K + ...
  size(Fp, 1) + size(Fm, 1) + 2.0 * K^2) + 4.0 * numel(terms);
end

function total = LOCAL_kahan(values)
total = 0.0;
correction = 0.0;
for value_idx = 1:numel(values)
  adjusted = values(value_idx) - correction;
  updated = total + adjusted;
  correction = (updated - total) - adjusted;
  total = updated;
end
end

%% ==================== Contracts and resources ====================
% Only necessary schema, finite, and hard-resource checks are retained.

function LOCAL_validate(c, anchor, boundary, hhalf, cfg, resource)
if ~isstruct(c) || ~isstruct(anchor) || ~isstruct(boundary) || ...
    ~isfield(boundary, 'available') || ~boundary.available || ...
    ~isfield(boundary, 'private') || ~isstruct(hhalf) || ...
    ~isfield(hhalf, 'available') || ~hhalf.available || ...
    ~isfield(hhalf, 'private') || ...
    ~isequal(cfg.levels.circle, [1024.0, 1280.0, 1536.0, 2048.0]) || ...
    ~isequal(cfg.levels.wall, [2048.0, 2560.0, 3072.0, 4096.0]) || ...
    ~isequal(cfg.levels.fullp, [8.0, 16.0, 32.0]) || ...
    ~isstruct(resource) || ~all(isfield(resource, ...
    {'start_tic', 'hard_s', 'memory_mib_max'}))
  error('I32V4:FitInterface', 'A fit-cap input has invalid schema.');
end
if numel(boundary.private.levels) ~= 4 || ...
    numel(hhalf.private.levels) ~= 4
  error('I32V4:FitLevelCount', 'Four coupled factors are required.');
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
  error('I32V4:HARD_MEMORY_LIMIT', 'The 2048 MiB memory gate was reached.');
end
end

function out = LOCAL_empty()
out = struct('schema', 'I32V4_FIT_CAP_V1', 'status', 'INITIALIZED', ...
  'available', false, 'warnings', {{}}, 'first_blocker', '', ...
  'audit', struct(), 'memory', struct(), 'data', struct());
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V4:UNIDENTIFIED_BLOCKER';
end
end
