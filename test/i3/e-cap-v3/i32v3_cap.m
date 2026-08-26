function out = i32v3_cap(trial, boundary, lifting, gqp_public, cfg, resource)
%I32V3_CAP Contract full P powers and form all empirical epsilon rows.
% Purpose:
%   Compute independent wall, circle, and volume finite candidates, nested
%   evaluation caps, the trace-only denominator cap, q_emp, and the nominal
%   asymmetric k interval when their prerequisites are finite.
% Input:
%   trial       - Frozen certificate and ordinary anchor.
%   boundary    - Completed v3 boundary module.
%   lifting     - Completed v3 lifting module.
%   gqp_public  - Compact fixed-table support/spot record.
%   cfg         - Frozen Section 13 levels and formulas.
%   resource    - Shared hard resource gate.
% Output:
%   out.data - Component centers, every empirical cap row, field lower,
%              unresolved ledger, q_emp, and nominal interval.
% Main algorithm:
%   Preserve complete 97-by-97 nonnormal propagation matrices in the
%   doubling recurrence, compare augmented factors at N=8/16/32, apply the
%   Section 13 absolute-plateau rule, and count each GQP piece exactly once.
% Based on:
%   design-3-2d Sections 7--8 and Section 13.
% Notes:
%   Every claim remains EMPIRICAL / UNQUALIFIED; no gap or existence claim
%   is made even when q_emp is finite and below one.

timer = tic;
out = LOCAL_empty();
progress = struct('stage', 'entry', 'components_completed', 0.0, ...
  'local_peak_mib', 0.0, 'complete', false);
out.audit.symbol_ledger = struct( ...
  'B_W', 'wall normal-jump finite component candidate', ...
  'B_Gamma', 'circle normal-defect finite component candidate', ...
  'B_V', 'value-lifting volume finite component candidate', ...
  'epsilon_M_emp', 'sum of W, Gamma, and V empirical cap rows', ...
  'N_h_star', 'direct N=8 shared-trace field lower candidate', ...
  'epsilon_N_emp', 'one-sided denominator empirical cap', ...
  'q_emp', 'empirical majorant ratio');
try
  LOCAL_validate(trial, boundary, lifting, gqp_public, cfg, resource);
  c = trial.certificate;
  a = trial.ordinary_anchor;
  factors = struct('wall', boundary.private.wall_factor, ...
    'circle', boundary.private.circle_factor, ...
    'volume', lifting.private.factor);
  names = {'wall', 'circle', 'volume'};
  unresolved = {};
  warnings = {};

  % --- stage 1: component centers and complete-matrix full-P axes ---
  progress.stage = 'full-P components';
  for j = 1:numel(names)
    name = names{j};
    component.(name) = LOCAL_component(factors.(name), c, cfg);
    if ~component.(name).fullp.resolved
      unresolved{end + 1} = [upper(name), '_FULLP']; %#ok<AGROW>
    end
    progress.components_completed = j;
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      LOCAL_workspace_mib());
    LOCAL_resource(resource, progress.local_peak_mib);
  end

  % --- stage 2: target/source/weight axes and unique GQP scales ---
  caps.wall.target = LOCAL_axis_cap(boundary.private.axes.wall_target, c, cfg);
  caps.wall.source = LOCAL_axis_cap(boundary.private.axes.wall_source, c, cfg);
  caps.wall.weight = LOCAL_zero_row('no independent wall weight axis');
  caps.circle.target = LOCAL_axis_cap(boundary.private.axes.circle_target, c, cfg);
  caps.circle.source = LOCAL_axis_cap(boundary.private.axes.circle_source, c, cfg);
  caps.circle.weight = LOCAL_axis_cap(boundary.private.axes.circle_riccati, c, cfg);
  caps.volume.target = LOCAL_axis_cap(lifting.private.axes.target, c, cfg);
  caps.volume.source = LOCAL_axis_cap(lifting.private.axes.source, c, cfg);
  caps.volume.weight = LOCAL_axis_cap(lifting.private.axes.gauss, c, cfg);

  supported = logical(gqp_public.data.supported);
  caps.wall.gqp = LOCAL_gqp_cap(boundary.private.gqp_factors.wall, ...
    c, cfg, supported);
  caps.circle.gqp = LOCAL_gqp_cap(boundary.private.gqp_factors.circle, ...
    c, cfg, supported);
  caps.volume.gqp = LOCAL_gqp_cap(lifting.private.gqp_factors, ...
    c, cfg, supported);
  for j = 1:numel(names)
    name = names{j};
    caps.(name).fullp = component.(name).fullp;
    caps.(name).roundoff = struct('remainder', ...
      2.0 * max(component.(name).arithmetic_spread, ...
      component.(name).arithmetic_omega), ...
      'spread', component.(name).arithmetic_spread, ...
      'omega', component.(name).arithmetic_omega, ...
      'separate_from_gqp_scale', true);
    caps.(name).fourier = struct('remainder', 0.0, ...
      'diagnostic_only', true, 'counted_in', 'target axis');
    values = [caps.(name).target.remainder, ...
      caps.(name).source.remainder, caps.(name).weight.remainder, ...
      caps.(name).fullp.remainder, caps.(name).gqp.remainder, ...
      caps.(name).roundoff.remainder];
    if all(isfinite(values)) && all(values >= 0.0)
      caps.(name).total = sum(values);
    else
      caps.(name).total = NaN;
      unresolved{end + 1} = [upper(name), '_TOTAL_CAP']; %#ok<AGROW>
    end
    axis_names = {'target', 'source', 'weight', 'fullp', 'gqp'};
    for k = 1:numel(axis_names)
      axis_name = axis_names{k};
      if ~isfinite(caps.(name).(axis_name).remainder)
        unresolved{end + 1} = ...
          [upper(name), '_', upper(axis_name)]; %#ok<AGROW>
      end
    end
  end

  % --- stage 3: field lower and conditional nominal interval ---
  field = LOCAL_field_lower(c, a, cfg);
  caps.epsilon_M_emp = caps.wall.total + caps.circle.total + caps.volume.total;
  caps.epsilon_N_emp = field.epsilon_N_emp;
  caps.epsilon_N_GQP_emp = 0.0;
  caps.field_dependency = struct('kernel_calls', 0.0, ...
    'boundary_action_calls', 0.0, 'lifting_calls', 0.0, ...
    'trace_only_dependency_verified', true);
  estimator = struct('B_wall', component.wall.B_finest, ...
    'B_circle', component.circle.B_finest, ...
    'B_volume', component.volume.B_finest);
  estimator.M_h = estimator.B_wall + estimator.B_circle + estimator.B_volume;
  estimator.field_lower = field.N_h_star;
  estimator.q_emp = NaN;
  estimator.k_interval = struct('lower', NaN, 'upper', NaN, ...
    'width', NaN, 'width_below_1e6', false, ...
    'label', 'EMPIRICAL / UNQUALIFIED');
  denominator = field.N_h_star - field.epsilon_N_emp;
  if isfinite(caps.epsilon_M_emp) && isfinite(estimator.M_h) && ...
      isfinite(denominator) && denominator > 0.0
    estimator.q_emp = (estimator.M_h + caps.epsilon_M_emp) / sqrt(denominator);
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
    end
  else
    unresolved{end + 1} = 'Q_EMP_AND_INTERVAL';
  end
  if ~supported
    warnings{end + 1} = 'KERNEL_ASSUMPTION_UNRESOLVED';
  end
  if field.negative_increment
    warnings{end + 1} = 'FIELD_FULLP_NEGATIVE_INCREMENT_EMPIRICAL';
  end

  out.data = struct('component', component, 'caps', caps, ...
    'field', field, 'estimator', estimator, ...
    'unresolved', {unique(unresolved, 'stable')});
  out.warnings = unique(warnings, 'stable');
  out.audit.fullp_matrices_complete = true;
  out.audit.diagonalization_calls = 0.0;
  out.audit.gqp_formula = ...
    'epsilon_X_G=1e-10*sum_p norm(A_X_p F_X_p); each unique piece once';
  out.audit.volume_piece_ownership = ...
    'circle collar and left/right strips are disjoint; no total residual norm added';
  out.audit.field_dependency = caps.field_dependency;
  out.counters = struct('eig_calls', 0.0, 'pinv_calls', 0.0, ...
    'kernel_calls', 0.0, 'image_sum_calls', 0.0, ...
    'rayleigh_field_calls', 0.0);
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
  'largest_object', 'compact full-P/cap ledger');
out.audit.elapsed_s = toc(timer);
end

%% ==================== Full-P component center ====================
% Literal P recurrences retain nonnormal and Jordan coupling.

function result = LOCAL_component(factor, c, cfg)
levels = cfg.levels.fullp;
Nmax = levels(end);
augmented = cell(1, 3);
operations = zeros(1, 3);
for j = 1:3
  N = levels(j);
  plus = LOCAL_side(factor.plus, c.Pplus, c.cplus, N);
  minus = LOCAL_side(factor.minus, c.Pminus, c.cminus, N);
  squared = real(factor.singleton' * factor.singleton) + ...
    plus.finite + plus.tail + minus.finite + minus.tail;
  B(j) = sqrt(max(0.0, squared)); %#ok<AGROW>
  [yp, op_p] = LOCAL_action(factor.plus, c.Pplus, c.cplus, N, Nmax);
  [ym, op_m] = LOCAL_action(factor.minus, c.Pminus, c.cminus, N, Nmax);
  augmented{j} = [factor.singleton(:); yp; ym; ...
    sqrt(max(0.0, plus.tail)); sqrt(max(0.0, minus.tail))];
  tail_plus_squared(j) = plus.tail; %#ok<AGROW>
  tail_minus_squared(j) = minus.tail; %#ok<AGROW>
  tail_share(j) = (plus.tail + minus.tail) / max(squared, realmin); %#ok<AGROW>
  operations(j) = plus.operations + minus.operations + op_p + op_m;
end
axis = LOCAL_vector_axis(B, augmented, sum(operations), cfg);
paths = [B(3), norm(augmented{3}), ...
  sqrt(max(0.0, LOCAL_kahan(abs(augmented{3}).^2)))];
spread = max([abs(paths(1) - paths(2)), abs(paths(1) - paths(3)), ...
  abs(paths(2) - paths(3))]);
omega = cfg.roundoff.multiplier * max(1.0, sum(operations)) * ...
  cfg.roundoff.eps * max([realmin, abs(paths)]);
result = struct('B', B, 'B_finest', B(3), 'tail_share', tail_share, ...
  'fullp', axis, 'arithmetic_paths', paths, ...
  'arithmetic_spread', spread, 'arithmetic_omega', omega, ...
  'operation_count', sum(operations));
combined_squared = tail_plus_squared + tail_minus_squared;
combined_norm = sqrt(max(0.0, combined_squared));
result.tail = struct('levels', levels, ...
  'plus_squared', tail_plus_squared, ...
  'minus_squared', tail_minus_squared, ...
  'combined_squared', combined_squared, ...
  'combined_norm', combined_norm, ...
  'finest_plus_squared', tail_plus_squared(end), ...
  'finest_minus_squared', tail_minus_squared(end), ...
  'finest_combined_squared', combined_squared(end), ...
  'finest_combined_norm', combined_norm(end), ...
  'nested_change_8_16_norm', abs(combined_norm(2) - combined_norm(1)), ...
  'nested_change_16_32_norm', abs(combined_norm(3) - combined_norm(2)), ...
  'finite_available', all(isfinite([tail_plus_squared, ...
  tail_minus_squared, combined_squared])) && ...
  all([tail_plus_squared, tail_minus_squared, combined_squared] >= 0.0), ...
  'diagnostic_only', true, 'cap_contribution', 0.0, ...
  'counted_in', 'augmented full-P row');
end

function side = LOCAL_side(F, P, state, N)
K = size(P, 1);
W0 = F' * F;
[Wd, PNd, ops_d] = LOCAL_doubling(W0, P, N);
[Wr, PNr, ops_r] = LOCAL_direct_gram(W0, P, N);
power_defect = norm(PNd - PNr, 2);
a_hi = norm(PNd, 2) + power_defect + ...
  100.0 * K * eps('double') * max([1.0, norm(PNd, 2), norm(PNr, 2)]);
omega_W = norm(Wd - Wr, 2) + 100.0 * K * eps('double') * ...
  max([norm(Wd, 2), norm(Wr, 2), realmin]);
finite = real(state' * Wd * state);
negative_tol = 100.0 * K * eps('double') * norm(Wd, 2) * norm(state)^2;
if finite < -negative_tol
  error('I32V3:IndefiniteFullPGram', ...
    'A full-P Gram contraction is significantly negative.');
end
finite = max(0.0, finite);
if ~(isfinite(a_hi) && a_hi < 1.0)
  error('I32V3:FullPTailUnavailable', ...
    'A complete-matrix infinite tail cannot be formed.');
end
tail = a_hi^2 / (1.0 - a_hi^2) * ...
  (norm(Wd, 2) + omega_W) * norm(state)^2;
side = struct('finite', finite, 'tail', tail, 'a_hi', a_hi, ...
  'operations', size(F, 1) * K^2 + ops_d + ops_r + 2.0 * K^2 + 12.0);
end

function [W, PN, operations] = LOCAL_doubling(W0, P, N)
W = W0;
PN = P;
current = 1.0;
K = size(P, 1);
operations = 0.0;
while current < N
  W = W + PN' * W * PN;
  PN = PN * PN;
  operations = operations + 3.0 * K^3 + K^2;
  current = 2.0 * current;
end
end

function [W, PN, operations] = LOCAL_direct_gram(W0, P, N)
K = size(P, 1);
W = zeros(K, K, 'like', W0);
PN = eye(K, 'like', P);
operations = 0.0;
for j = 1:N
  W = W + PN' * W0 * PN;
  PN = P * PN;
  operations = operations + 3.0 * K^3 + K^2;
end
end

function [vector, operations] = LOCAL_action(F, P, state, N, Nmax)
rows = size(F, 1);
K = size(P, 1);
vector = complex(zeros(rows * Nmax, 1));
power_state = state;
operations = 0.0;
for j = 1:N
  ids = (j - 1.0) * rows + (1.0:rows);
  vector(ids) = F * power_state;
  power_state = P * power_state;
  operations = operations + rows * K + K^2;
end
end

%% ==================== Nested axis and GQP rows ====================
% Absolute plateaus are explicit; unresolved candidates are never caps.

function row = LOCAL_axis_cap(axis, c, cfg)
K = c.K;
if ~isequal(size(axis.level_plus_gram), [K, K, 3]) || ...
    ~isequal(size(axis.level_minus_gram), [K, K, 3]) || ...
    numel(axis.singleton_squared) ~= 3
  error('I32V3:AxisSchema', 'A compact axis has invalid dimensions.');
end
endpoint = cell(1, 3);
operations = axis.operation_count;
for j = 1:3
  endpoint{j} = LOCAL_gram_endpoint(axis.level_plus_gram(:, :, j), ...
    axis.level_minus_gram(:, :, j), axis.singleton_squared(j), c, cfg);
  B(j) = endpoint{j}.B; %#ok<AGROW>
  operations = operations + endpoint{j}.operations;
end
[D01, ops01] = LOCAL_augmented(axis.delta01_plus_gram, ...
  axis.delta01_minus_gram, axis.delta01_singleton_squared, ...
  endpoint{1}, endpoint{2}, c, cfg);
[D12, ops12] = LOCAL_augmented(axis.delta12_plus_gram, ...
  axis.delta12_minus_gram, axis.delta12_singleton_squared, ...
  endpoint{2}, endpoint{3}, c, cfg);
d1 = max(abs(B(2) - B(1)), D01);
d2 = max(abs(B(3) - B(2)), D12);
operations = operations + ops01 + ops12 + 8.0;
absolute = max(cfg.threshold.absolute_floor, ...
  cfg.roundoff.multiplier * cfg.roundoff.eps * max([1.0, abs(B)]));
contraction = d2 <= cfg.threshold.refinement_contraction * d1;
plateau = max(d1, d2) <= absolute;
resolved = isfinite(d1) && isfinite(d2) && (contraction || plateau);
candidate = 2.0 * max(d2, absolute);
if resolved, remainder = candidate; else, remainder = NaN; end
row = struct('B', B, 'D01', D01, 'D12', D12, 'd1', d1, 'd2', d2, ...
  'absolute_floor', absolute, 'contraction_pass', contraction, ...
  'absolute_plateau', plateau, 'resolved', resolved, ...
  'candidate', candidate, 'remainder', remainder, ...
  'difference_semantics', 'AUGMENTED_N32_PLUS_ENDPOINT_TAILS', ...
  'operation_count', operations);
end

function row = LOCAL_vector_axis(B, vectors, operations, cfg)
d1 = max(abs(B(2) - B(1)), norm(vectors{2} - vectors{1}));
d2 = max(abs(B(3) - B(2)), norm(vectors{3} - vectors{2}));
absolute = max(cfg.threshold.absolute_floor, ...
  cfg.roundoff.multiplier * cfg.roundoff.eps * max([1.0, abs(B)]));
contraction = d2 <= cfg.threshold.refinement_contraction * d1;
plateau = max(d1, d2) <= absolute;
resolved = isfinite(d1) && isfinite(d2) && (contraction || plateau);
candidate = 2.0 * max(d2, absolute);
if resolved, remainder = candidate; else, remainder = NaN; end
row = struct('B', B, 'd1', d1, 'd2', d2, ...
  'absolute_floor', absolute, 'contraction_pass', contraction, ...
  'absolute_plateau', plateau, 'resolved', resolved, ...
  'candidate', candidate, 'remainder', remainder, ...
  'operation_count', operations);
end

function row = LOCAL_gqp_cap(pieces, c, cfg, supported)
scale = 0.0;
names = cell(1, numel(pieces));
piece_norms = zeros(1, numel(pieces));
operations = 0.0;
for j = 1:numel(pieces)
  piece = pieces{j};
  endpoint = LOCAL_factor_endpoint(piece, c, cfg.levels.fullp(end));
  piece_norms(j) = endpoint.B;
  scale = scale + piece_norms(j);
  names{j} = piece.name;
  operations = operations + endpoint.operations + 1.0;
end
if supported && isfinite(scale) && scale >= 0.0
  remainder = cfg.gqp.relative_uncertainty * scale;
else
  remainder = NaN;
end
row = struct('supported', supported, 'scale', scale, ...
  'relative_factor', cfg.gqp.relative_uncertainty, ...
  'piece_names', {names}, 'piece_norms', piece_norms, ...
  'unique_piece_count', numel(pieces), 'counted_once', true, ...
  'total_residual_norm_added', false, 'roundoff_in_scale', false, ...
  'remainder', remainder, 'operation_count', operations);
end

function endpoint = LOCAL_factor_endpoint(factor, c, N)
plus = LOCAL_side(factor.plus, c.Pplus, c.cplus, N);
minus = LOCAL_side(factor.minus, c.Pminus, c.cminus, N);
squared = real(factor.singleton' * factor.singleton) + ...
  plus.finite + plus.tail + minus.finite + minus.tail;
endpoint = struct('B', sqrt(max(0.0, squared)), ...
  'operations', plus.operations + minus.operations + numel(factor.singleton));
end

function endpoint = LOCAL_gram_endpoint(Wp, Wm, singleton_squared, c, cfg)
plus = LOCAL_gram_side(Wp, c.Pplus, c.cplus, cfg.levels.fullp(end));
minus = LOCAL_gram_side(Wm, c.Pminus, c.cminus, cfg.levels.fullp(end));
squared = real(singleton_squared) + plus.finite + plus.tail + ...
  minus.finite + minus.tail;
tol = cfg.threshold.gram * max([norm(Wp, 2), norm(Wm, 2), realmin]);
if squared < -tol
  error('I32V3:IndefiniteDiagnosticGram', ...
    'A diagnostic Gram is significantly indefinite.');
end
endpoint = struct('B', sqrt(max(0.0, squared)), ...
  'tail_plus', plus.tail, 'tail_minus', minus.tail, ...
  'operations', plus.operations + minus.operations + 4.0);
end

function side = LOCAL_gram_side(W0, P, state, N)
K = size(P, 1);
[W, PN, operations_d] = LOCAL_doubling(W0, P, N);
[W_direct, PN_direct, operations_r] = LOCAL_direct_gram(W0, P, N);
power_defect = norm(PN - PN_direct, 2);
finite = real(state' * W * state);
tol = 100.0 * K * eps('double') * norm(W, 2) * norm(state)^2;
if finite < -tol
  error('I32V3:IndefiniteDiagnosticGram', ...
    'A diagnostic finite Gram is significantly negative.');
end
finite = max(0.0, finite);
a_hi = norm(PN, 2) + power_defect + 100.0 * K * eps('double') * ...
  max([1.0, norm(PN, 2), norm(PN_direct, 2)]);
if ~(isfinite(a_hi) && a_hi < 1.0)
  error('I32V3:FullPTailUnavailable', 'A diagnostic tail is unavailable.');
end
omega = norm(W - W_direct, 2) + 100.0 * K * eps('double') * ...
  max([norm(W, 2), norm(W_direct, 2), realmin]);
tail = a_hi^2 / (1.0 - a_hi^2) * ...
  (norm(W, 2) + omega) * norm(state)^2;
side = struct('finite', finite, 'tail', tail, ...
  'operations', operations_d + operations_r + 2.0 * K^2 + K + 12.0);
end

function [value, operations] = LOCAL_augmented(Wp, Wm, singleton_squared, ...
    endpoint_a, endpoint_b, c, cfg)
plus = LOCAL_gram_finite(Wp, c.Pplus, c.cplus, cfg.levels.fullp(end));
minus = LOCAL_gram_finite(Wm, c.Pminus, c.cminus, cfg.levels.fullp(end));
squared = real(singleton_squared) + plus.finite + minus.finite + ...
  (sqrt(max(0.0, endpoint_b.tail_plus)) - ...
  sqrt(max(0.0, endpoint_a.tail_plus)))^2 + ...
  (sqrt(max(0.0, endpoint_b.tail_minus)) - ...
  sqrt(max(0.0, endpoint_a.tail_minus)))^2;
tol = cfg.threshold.gram * max([norm(Wp, 2), norm(Wm, 2), realmin]);
if squared < -tol
  error('I32V3:IndefiniteAugmentedDifference', ...
    'An augmented difference is significantly indefinite.');
end
value = sqrt(max(0.0, squared));
operations = plus.operations + minus.operations + 12.0;
end

function side = LOCAL_gram_finite(W0, P, state, N)
[W, ~, operations] = LOCAL_doubling(W0, P, N);
finite = real(state' * W * state);
K = size(P, 1);
tol = 100.0 * K * eps('double') * norm(W, 2) * norm(state)^2;
if finite < -tol
  error('I32V3:IndefiniteAugmentedFinite', ...
    'An augmented finite coordinate is negative.');
end
side = struct('finite', max(0.0, finite), ...
  'operations', operations + K^2 + K);
end

function row = LOCAL_zero_row(note)
row = struct('B', [0.0, 0.0, 0.0], 'd1', 0.0, 'd2', 0.0, ...
  'absolute_floor', 0.0, 'contraction_pass', true, ...
  'absolute_plateau', true, 'resolved', true, 'candidate', 0.0, ...
  'remainder', 0.0, 'note', note, 'operation_count', 0.0);
end

%% ==================== Trace-only denominator ====================
% This call graph consumes no GQP, boundary-action, or lifting object.

function field = LOCAL_field_lower(c, a, cfg)
levels = cfg.levels.fullp;
Fp = a.lead_field_factor_plus;
Fm = a.lead_field_factor_minus;
center = real(c.center_wall_jumps.field_squared);
for j = 1:3
  [direct(j), direct_ops(j)] = LOCAL_field_direct(Fp, c.Pplus, c.cplus, ...
    Fm, c.Pminus, c.cminus, center, levels(j)); %#ok<AGROW>
end
[gram8, gram_ops] = LOCAL_field_gram(Fp, c.Pplus, c.cplus, ...
  Fm, c.Pminus, c.cminus, center, levels(1));
[comp8, comp_ops] = LOCAL_field_compensated(Fp, c.Pplus, c.cplus, ...
  Fm, c.Pminus, c.cminus, center, levels(1));
N_h_star = direct(1);
historical = real(a.N_tilde);
downward = [max(0.0, historical - direct(1)), ...
  max(0.0, direct(1) - direct(2)), max(0.0, direct(2) - direct(3))];
A_obs = sum(downward);
n_cmp = sum(direct_ops) + 3.0;
omega_cmp = cfg.roundoff.multiplier * n_cmp * cfg.roundoff.eps * ...
  max([realmin, abs(historical), abs(direct)]);
A_N = A_obs + omega_cmp;
paths = [direct(1), gram8, comp8];
r_N = max([abs(paths(1) - paths(2)), abs(paths(1) - paths(3)), ...
  abs(paths(2) - paths(3))]);
n_N = max([direct_ops(1), gram_ops, comp_ops]);
omega_N = cfg.roundoff.multiplier * n_N * cfg.roundoff.eps * ...
  max([realmin, abs(paths)]);
epsilon_N = A_N + 2.0 * max(r_N, omega_N);
if ~all(isfinite([direct, paths, epsilon_N])) || N_h_star <= 0.0
  error('I32V3:FieldLowerUnavailable', ...
    'The trace-only field lower is invalid.');
end
field = struct('levels', levels, 'direct', direct, ...
  'paths_N8', struct('direct', paths(1), 'gram', paths(2), ...
  'compensated', paths(3)), 'N_h_star', N_h_star, ...
  'historical_anchor', historical, 'downward_terms', downward, ...
  'A_N_observed', A_obs, 'omega_comparison', omega_cmp, 'A_N', A_N, ...
  'path_spread', r_N, 'omega_arithmetic', omega_N, ...
  'epsilon_N_emp', epsilon_N, ...
  'negative_increment', any(downward(2:3) > 0.0), ...
  'epsilon_N_GQP_emp', 0.0, 'operation_count', n_cmp + n_N);
end

function [value, operations] = LOCAL_field_direct( ...
    Fp, Pp, cp, Fm, Pm, cm, center, N)
value = center;
vp = cp;
vm = cm;
for j = 1:N
  yp = Fp * vp;
  ym = Fm * vm;
  value = value + real(yp' * yp) + real(ym' * ym);
  vp = Pp * vp;
  vm = Pm * vm;
end
K = size(Pp, 1);
operations = N * (size(Fp, 1) * K + size(Fm, 1) * K + ...
  size(Fp, 1) + size(Fm, 1) + 2.0 * K^2 + 2.0);
end

function [value, operations] = LOCAL_field_gram( ...
    Fp, Pp, cp, Fm, Pm, cm, center, N)
K = size(Pp, 1);
[Wp, ~, ops_p] = LOCAL_direct_gram(Fp' * Fp, Pp, N);
[Wm, ~, ops_m] = LOCAL_direct_gram(Fm' * Fm, Pm, N);
value = center + real(cp' * Wp * cp) + real(cm' * Wm * cm);
operations = (size(Fp, 1) + size(Fm, 1)) * K^2 + ...
  ops_p + ops_m + 2.0 * (K^2 + K) + 2.0;
end

function [value, operations] = LOCAL_field_compensated( ...
    Fp, Pp, cp, Fm, Pm, cm, center, N)
terms = zeros(2.0 * N + 1.0, 1);
terms(1) = center;
vp = cp;
vm = cm;
for j = 1:N
  yp = Fp * vp;
  ym = Fm * vm;
  terms(2.0 * j) = real(yp' * yp);
  terms(2.0 * j + 1.0) = real(ym' * ym);
  vp = Pp * vp;
  vm = Pm * vm;
end
value = LOCAL_kahan(terms);
K = size(Pp, 1);
operations = N * (size(Fp, 1) * K + size(Fm, 1) * K + ...
  size(Fp, 1) + size(Fm, 1) + 2.0 * K^2) + 4.0 * numel(terms);
end

function total = LOCAL_kahan(values)
total = 0.0;
correction = 0.0;
for j = 1:numel(values)
  adjusted = values(j) - correction;
  updated = total + adjusted;
  correction = (updated - total) - adjusted;
  total = updated;
end
end

%% ==================== Contracts and resources ====================
% Hard failures are limited to invalid finite algebra or resource gates.

function LOCAL_validate(trial, boundary, lifting, gqp, cfg, resource)
if ~isstruct(trial) || ~all(isfield(trial, ...
    {'certificate', 'ordinary_anchor'})) || ...
    ~isstruct(boundary) || ~boundary.available || ~isfield(boundary, 'private') || ...
    ~isstruct(lifting) || ~lifting.available || ~isfield(lifting, 'private') || ...
    ~isstruct(gqp) || ~isfield(gqp, 'data') || ...
    ~all(isfield(gqp.data, {'supported', 'relative_uncertainty'})) || ...
    ~isstruct(cfg) || ~isequal(cfg.levels.fullp, [8.0, 16.0, 32.0]) || ...
    ~isstruct(resource) || ~all(isfield(resource, ...
    {'start_tic', 'hard_s', 'memory_mib_max'}))
  error('I32V3:CapInterface', 'The cap interface is incomplete.');
end
end

function LOCAL_resource(resource, local_mib)
if toc(resource.start_tic) > resource.hard_s
  error('I32V3:HARD_TIME_LIMIT', 'The hard cap time gate was reached.');
end
retained = 0.0;
publication = 64.0;
if isfield(resource, 'retained_mib'), retained = resource.retained_mib; end
if isfield(resource, 'publication_mib'), publication = resource.publication_mib; end
if retained + local_mib + publication > resource.memory_mib_max
  error('I32V3:HARD_MEMORY_LIMIT', 'The hard cap memory gate was reached.');
end
end

function mib = LOCAL_workspace_mib()
items = whos;
mib = sum([items.bytes]) / 2^20;
end

function out = LOCAL_empty()
out = struct('schema', 'I32V3_CAP_V1', 'status', 'INITIALIZED', ...
  'available', false, 'warnings', {{}}, 'first_blocker', '', ...
  'audit', struct(), 'counters', struct(), 'memory', struct(), ...
  'data', struct());
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V3:UNIDENTIFIED_BLOCKER';
end
end
