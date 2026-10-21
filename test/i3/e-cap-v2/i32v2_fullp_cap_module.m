function out = i32v2_fullp_cap_module(view, circle, wall, lifting, cfg, resource)
%I32V2_FULLP_CAP_MODULE Contract full propagation powers and empirical caps.
% Purpose:
%   Preserve nonnormal P coupling while forming ordinary component centers,
%   nested full-P differences, the one-sided field-lower cap, q_emp, and the
%   nominal unqualified k interval.
% Input:
%   view                 - authenticated i32v2_computation_view return.
%   circle, wall, lifting - completed scientific module returns.
%   cfg                  - preregistered configuration.
%   resource             - shared elapsed-time and memory gates.
% Output:
%   out - common compact module schema with caps and estimator data.
% Main algorithm:
%   Apply literal 97-by-97 P powers at N=8,16,32 without eigendecomposition;
%   compare aligned augmented vectors; combine preformed axis/GQP metrics;
%   recompute the field partial by direct, Gram, and compensated paths.

module_tic = tic;
out = LOCAL_empty_return();
local_peak_mib = 0;
out.data.checkpoint = struct('stage', 'entry', ...
  'components_completed', 0, 'component_in_progress', '', ...
  'completed_objects', {{}}, 'local_peak_mib', 0, ...
  'operation_count', 0);
out.audit.symbol_ledger = struct( ...
  'Pplus', 'complete right-lead propagation matrix', ...
  'Pminus', 'complete left-lead propagation matrix', ...
  'F_X_plus', 'weighted one-cell component factor', ...
  'F_X_minus', 'weighted one-cell component factor', ...
  'D_X', 'augmented factor difference through N=32 plus endpoint tail coordinates', ...
  'operation_ledger', 'typed executed recurrence and comparison counts', ...
  'N_h_star', 'direct-path N=8 shared-trace field partial', ...
  'epsilon_N_emp', 'one-sided empirical denominator cap');

try
  view_audit = i32v2_validate_computation_view(view, cfg, 'fullp');
  c = view.data.certificate;
  a = view.data.ordinary_anchor;
  out.audit.computation_view = view_audit;
  LOCAL_resource_check(resource, cfg, 'full-P entry');

  % --- stage 1: extract only registered finest factors ---
  factors.wall.plus = LOCAL_required(wall, ...
    {'data', 'finest', 'internal_plus'}, 'wall internal plus factor');
  factors.wall.minus = LOCAL_required(wall, ...
    {'data', 'finest', 'internal_minus'}, 'wall internal minus factor');
  factors.wall.singleton = [LOCAL_required(wall, ...
    {'data', 'center_first_left_flux'}, 'left center/first flux singleton'); ...
    LOCAL_required(wall, {'data', 'center_first_right_flux'}, ...
    'right center/first flux singleton')];

  factors.circle.plus = LOCAL_required(circle, ...
    {'data', 'finest', 'normal_plus'}, 'circle normal plus factor');
  factors.circle.minus = LOCAL_required(circle, ...
    {'data', 'finest', 'normal_minus'}, 'circle normal minus factor');
  factors.circle.singleton = complex(zeros(0, 1));

  factors.volume.plus = LOCAL_required(lifting, ...
    {'data', 'finest', 'volume_plus'}, 'combined volume plus factor');
  factors.volume.minus = LOCAL_required(lifting, ...
    {'data', 'finest', 'volume_minus'}, 'combined volume minus factor');
  factors.volume.singleton = LOCAL_optional(lifting, ...
    {'data', 'finest', 'singleton'}, complex(zeros(0, 1)));

  names = {'wall', 'circle', 'volume'};
  for k = 1:numel(names)
    LOCAL_validate_factor(factors.(names{k}).plus, c.K, [names{k}, ' plus']);
    LOCAL_validate_factor(factors.(names{k}).minus, c.K, [names{k}, ' minus']);
    if ~all(isfinite(factors.(names{k}).singleton(:)))
      error('I32V2:NonfiniteSingleton', ...
        'Nonfinite singleton factor for %s.', names{k});
    end
  end
  probe = whos;
  local_peak_mib = max(local_peak_mib, sum([probe.bytes]) / 2^20);
  LOCAL_resource_check(resource, cfg, 'registered finest factors', ...
    local_peak_mib);

  % --- stage 2: full-P ordinary centers and nested differences ---
  for k = 1:numel(names)
    name = names{k};
    out.data.checkpoint.stage = 'full-P component contraction';
    out.data.checkpoint.component_in_progress = name;
    component.(name) = LOCAL_component_fullp(factors.(name), c, cfg);
    out.counters.(['fullp_', name, '_fma']) = component.(name).operation_count;
    if ~component.(name).cap_available
      out.warnings{end + 1} = upper([name, '_FULLP_REFINEMENT_UNRESOLVED']);
    end
    out.data.checkpoint.components_completed = k;
    out.data.checkpoint.component.(name) = component.(name);
    out.data.checkpoint.operation_count = ...
      out.data.checkpoint.operation_count + component.(name).operation_count;
    out.data.checkpoint.completed_objects{end + 1} = ...
      [name, ' full-P component'];
    LOCAL_resource_check(resource, cfg, ['full-P ', name]);
  end

  % Fourier shells use the same finest residual factors.  They diagnose
  % target-axis high-mode behavior only and contribute exactly zero again.
  fourier_shell = LOCAL_fourier_shells(factors, c, cfg);
  shell_names = fieldnames(fourier_shell);
  for k = 1:numel(shell_names)
    if ~fourier_shell.(shell_names{k}).contraction_pass
      out.warnings{end + 1} = upper([shell_names{k}, ...
        '_FOURIER_SHELL_UNRESOLVED']);
    end
  end
  probe = whos;
  local_peak_mib = max(local_peak_mib, sum([probe.bytes]) / 2^20);
  LOCAL_resource_check(resource, cfg, 'Fourier shell diagnostics', ...
    local_peak_mib);
  out.data.checkpoint.stage = 'Fourier shell diagnostics complete';
  out.data.checkpoint.fourier_shell = fourier_shell;
  out.data.checkpoint.local_peak_mib = local_peak_mib;
  out.data.checkpoint.completed_objects{end + 1} = ...
    'four diagnostic-only Fourier shell rows';

  % --- stage 3: one-sided field lower and denominator cap ---
  field = LOCAL_field_lower(c, a, cfg);
  out.data.checkpoint.stage = 'field lower complete';
  out.data.checkpoint.field = field;
  out.data.checkpoint.completed_objects{end + 1} = ...
    'field lower and denominator cap';
  out.counters.field_operation_count = field.operation_count;
  out.audit.field_dependency = struct( ...
    'inputs', {{'certificate.center_wall_jumps.field_squared', ...
      'ordinary_anchor.lead_field_factor_plus', ...
      'ordinary_anchor.lead_field_factor_minus', 'cplus', 'cminus', ...
      'Pplus', 'Pminus'}}, ...
    'kernel_module_referenced', false, ...
    'boundary_action_referenced', false, ...
    'lifting_module_referenced', false, ...
    'epsilon_N_GQP_emp', 0);
  if field.negative_increment
    out.warnings{end + 1} = 'FIELD_FULLP_NEGATIVE_INCREMENT_EMPIRICAL';
  end
  if field.path_spread > field.omega_arithmetic
    out.warnings{end + 1} = 'FIELD_ARITHMETIC_SPREAD_EXCEEDS_FLOOR';
  end

  % --- stage 4: combine componentwise axis, GQP, and arithmetic caps ---
  for k = 1:numel(names)
    name = names{k};
    source_module = LOCAL_source_module(name, wall, circle, lifting);
    caps.(name) = LOCAL_component_caps(component.(name), source_module, ...
      name, c, cfg);
    if ~isfinite(caps.(name).total)
      out.warnings{end + 1} = upper([name, '_EMPIRICAL_CAP_UNRESOLVED']);
    end
  end
  caps.wall.fourier = 0;
  caps.wall.fourier_diagnostic = fourier_shell.wall_wall;
  caps.circle.fourier = 0;
  caps.circle.fourier_diagnostic = fourier_shell.circle_circle;
  caps.volume.fourier = 0;
  caps.volume.fourier_diagnostic = struct( ...
    'circle', fourier_shell.volume_circle, ...
    'wall', fourier_shell.volume_wall);
  caps.epsilon_GQP_emp = caps.wall.gqp + caps.circle.gqp + caps.volume.gqp;
  caps.epsilon_M_emp = caps.wall.total + caps.circle.total + caps.volume.total;
  caps.epsilon_N_emp = field.epsilon_N_emp;
  caps.epsilon_N_GQP_emp = 0;

  estimator.B_wall = component.wall.B_finest;
  estimator.B_circle = component.circle.B_finest;
  estimator.B_volume = component.volume.B_finest;
  estimator.M_h = estimator.B_wall + estimator.B_circle + estimator.B_volume;
  estimator.field_lower = field.N_h_star;
  estimator.q_emp = NaN;
  estimator.k_interval = struct('lower', NaN, 'upper', NaN, ...
    'width', NaN, 'width_below_1e6', false);

  denominator = field.N_h_star - field.epsilon_N_emp;
  if isfinite(caps.epsilon_M_emp) && isfinite(estimator.M_h) && ...
      isfinite(denominator) && denominator > 0
    estimator.q_emp = (estimator.M_h + caps.epsilon_M_emp) / sqrt(denominator);
    if isfinite(estimator.q_emp) && estimator.q_emp < 1
      q = estimator.q_emp;
      mu_lower = max(0, (c.mu_h - q * c.gamma) / (1 + q));
      mu_upper = (c.mu_h + q * c.gamma) / (1 - q);
      if isfinite(mu_upper) && mu_upper >= 0
        estimator.k_interval.lower = sqrt(mu_lower);
        estimator.k_interval.upper = sqrt(mu_upper);
        estimator.k_interval.width = estimator.k_interval.upper - ...
          estimator.k_interval.lower;
        estimator.k_interval.width_below_1e6 = ...
          estimator.k_interval.width < cfg.threshold.interval_width;
      end
    elseif isfinite(estimator.q_emp)
      out.warnings{end + 1} = 'Q_EMP_NOT_BELOW_ONE';
    end
  else
    out.warnings{end + 1} = 'EMPIRICAL_Q_UNRESOLVED';
  end

  out.data.caps = caps;
  out.data.estimator = estimator;
  out.data.component = component;
  out.data.field = field;
  out.data.fourier_shell = fourier_shell;
  out.data.checkpoint.stage = 'complete';
  duplicate_names = {'component', 'field', 'fourier_shell'};
  out.data.checkpoint = rmfield(out.data.checkpoint, ...
    intersect(fieldnames(out.data.checkpoint), duplicate_names));
  out.available = true;
  out.status = 'COMPLETE';
catch err
  out.available = false;
  out.status = 'BLOCKED';
  out.first_blocker = LOCAL_identifier(err);
  out.audit.exception_message = err.message;
end

info = whos('out');
out.memory.local_peak_mib = max(local_peak_mib, info.bytes / 2^20);
out.memory.retained_mib = info.bytes / 2^20;
out.memory.entry_mib = LOCAL_resource_field(resource, 'retained_mib', 0);
out.memory.cow_mib = LOCAL_resource_field(resource, 'cow_mib', 0);
out.memory.publication_mib = LOCAL_resource_field(resource, ...
  'publication_mib', 64);
out.memory.proxy_mib = out.memory.entry_mib + out.memory.local_peak_mib + ...
  out.memory.cow_mib + out.memory.publication_mib;
out.memory.largest_object = 'compact full-P and cap ledgers';
out.memory.cleared_objects = {'aligned component vectors', ...
  'direct powers', 'temporary Grams'};
out.audit.elapsed_s = toc(module_tic);
end

%% ==================== Full-P component contraction ====================
% Complete P matrices are retained; no modal or eigenvector replacement occurs.

function result = LOCAL_component_fullp(factor, c, cfg)
levels = cfg.levels.fullp;
P = {c.Pplus, c.Pminus};
state = {c.cplus, c.cminus};
F = {factor.plus, factor.minus};
Nmax = levels(end);
for j = 1:numel(levels)
  N = levels(j);
  side = cell(1, 2);
  for s = 1:2
    side{s} = LOCAL_side_sum(F{s}, P{s}, state{s}, N);
  end
  squared = norm(factor.singleton)^2;
  for s = 1:2
    squared = squared + side{s}.finite + side{s}.tail;
  end
  B(j) = sqrt(max(0, real(squared))); %#ok<AGROW>
  [action_plus,action_plus_ops]=LOCAL_zero_padded_action( ...
    F{1},P{1},state{1},N,Nmax);
  [action_minus,action_minus_ops]=LOCAL_zero_padded_action( ...
    F{2},P{2},state{2},N,Nmax);
  augmented{j} = [factor.singleton(:); action_plus; action_minus; ...
    sqrt(max(0, side{1}.tail)); sqrt(max(0, side{2}.tail))]; %#ok<AGROW>
  tail_share(j) = (side{1}.tail + side{2}.tail) / ...
    max(realmin, squared); %#ok<AGROW>
  operation_count(j) = side{1}.operation_count + ...
    side{2}.operation_count+action_plus_ops+action_minus_ops; %#ok<AGROW>
end
d1 = max(abs(B(2) - B(1)), norm(augmented{2} - augmented{1}));
d2 = max(abs(B(3) - B(2)), norm(augmented{3} - augmented{2}));
n_compare = numel(augmented{1}) + numel(augmented{2}) + ...
  numel(augmented{3}) + 6;
n_axis=sum(operation_count)+n_compare;
omega = cfg.roundoff.multiplier * n_axis * cfg.roundoff.eps * ...
  max([realmin, abs(B), cellfun(@norm, augmented)]);
result.levels = levels;
result.B = B;
result.B_finest = B(end);
result.tail_share = tail_share;
result.d1 = d1;
result.d2 = d2;
result.omega = omega;
result.cap_available = isfinite(d1) && isfinite(d2) && ...
  d2 <= cfg.threshold.refinement_contraction * d1;
if result.cap_available
  result.fullp_cap = 2 * max(d2, omega);
else
  result.fullp_cap = NaN;
end
result.operation_count = n_axis;
result.arithmetic_paths = [B(end), norm(augmented{end}), ...
  sqrt(max(0, LOCAL_kahan_sum(abs(augmented{end}).^2)))];
result.arithmetic_spread = max([ ...
  abs(result.arithmetic_paths(1) - result.arithmetic_paths(2)), ...
  abs(result.arithmetic_paths(1) - result.arithmetic_paths(3)), ...
  abs(result.arithmetic_paths(2) - result.arithmetic_paths(3))]);
result.arithmetic_omega = cfg.roundoff.multiplier * ...
  max(1, result.operation_count) * cfg.roundoff.eps * ...
  max([realmin, abs(result.arithmetic_paths)]);
end

%% ==================== Diagnostic-only Fourier shells ====================
% Shells retain the full-P association but are already covered by target axes.

function rows = LOCAL_fourier_shells(factors, c, cfg)
Nc = double(cfg.levels.circle_target(end));
Nw = double(cfg.levels.wall_target(end));
K = double(c.K);
if Nc ~= 2048 || Nw ~= 4096
  error('I32V2:FourierShellLevels', ...
    'Fourier shell levels differ from the preregistered circle/wall grids.');
end
LOCAL_validate_block(factors.circle.plus, Nc, K, 'circle plus');
LOCAL_validate_block(factors.circle.minus, Nc, K, 'circle minus');
LOCAL_validate_block(factors.wall.plus, Nw, K, 'wall plus');
LOCAL_validate_block(factors.wall.minus, Nw, K, 'wall minus');
if numel(factors.wall.singleton) ~= 2 * Nw
  error('I32V2:FourierShellShape', ...
    'The wall shell requires two first-lead singleton blocks.');
end
if size(factors.volume.plus, 1) ~= Nc + 2 * Nw || ...
    size(factors.volume.minus, 1) ~= Nc + 2 * Nw || ...
    size(factors.volume.plus, 2) ~= K || ...
    size(factors.volume.minus, 2) ~= K || ...
    numel(factors.volume.singleton) ~= 4 * Nw
  error('I32V2:FourierShellShape', ...
    'The volume shell block structure is inconsistent with the frozen lift.');
end

wall_singleton = LOCAL_vector_blocks(factors.wall.singleton, Nw, 2);
volume_singleton = LOCAL_vector_blocks(factors.volume.singleton, Nw, 4);
rows.wall_wall = LOCAL_fourier_shell_row( ...
  {factors.wall.plus}, {factors.wall.minus}, wall_singleton, ...
  Nw, [1024, 2048], [2048, 4096], c, cfg, 'W / wall');
rows.circle_circle = LOCAL_fourier_shell_row( ...
  {factors.circle.plus}, {factors.circle.minus}, {}, ...
  Nc, [512, 1024], [1024, 2048], c, cfg, 'Gamma / circle');
rows.volume_circle = LOCAL_fourier_shell_row( ...
  {factors.volume.plus(1:Nc, :)}, ...
  {factors.volume.minus(1:Nc, :)}, {}, ...
  Nc, [512, 1024], [1024, 2048], c, cfg, 'V / circle');
rows.volume_wall = LOCAL_fourier_shell_row( ...
  {factors.volume.plus(Nc + (1:Nw), :), ...
  factors.volume.plus(Nc + Nw + (1:Nw), :)}, ...
  {factors.volume.minus(Nc + (1:Nw), :), ...
  factors.volume.minus(Nc + Nw + (1:Nw), :)}, ...
  volume_singleton, Nw, [1024, 2048], [2048, 4096], ...
  c, cfg, 'V / wall');
end

function row = LOCAL_fourier_shell_row(plus_blocks, minus_blocks, ...
    singleton_blocks, N, inner, outer, c, cfg, label)
K = double(c.K);
for j = 1:numel(plus_blocks)
  LOCAL_validate_block(plus_blocks{j}, N, K, [label, ' plus block']);
end
for j = 1:numel(minus_blocks)
  LOCAL_validate_block(minus_blocks{j}, N, K, [label, ' minus block']);
end
for j = 1:numel(singleton_blocks)
  if ~isnumeric(singleton_blocks{j}) || ...
      ~isequal(size(singleton_blocks{j}), [N, 1]) || ...
      ~all(isfinite(singleton_blocks{j}))
    error('I32V2:FourierShellShape', ...
      'A %s singleton block has an invalid shape.', label);
  end
end

for level = 1:2
  mask = LOCAL_shell_mask(N, inner(level), outer(level));
  Wp = complex(zeros(K));
  Wm = complex(zeros(K));
  singleton_squared = 0;
  gram_operations = 0;
  for j = 1:numel(plus_blocks)
    selected = plus_blocks{j}(mask, :);
    Wp = Wp + selected' * selected;
    gram_operations = gram_operations + nnz(mask) * K^2 + K^2;
  end
  for j = 1:numel(minus_blocks)
    selected = minus_blocks{j}(mask, :);
    Wm = Wm + selected' * selected;
    gram_operations = gram_operations + nnz(mask) * K^2 + K^2;
  end
  for j = 1:numel(singleton_blocks)
    selected = singleton_blocks{j}(mask);
    singleton_squared = singleton_squared + real(selected' * selected);
    gram_operations = gram_operations + nnz(mask) + 1;
  end
  [endpoint{level}, endpoint_operations] = LOCAL_gram_endpoint( ...
    Wp, Wm, singleton_squared, c, cfg); %#ok<AGROW>
  S(level) = endpoint{level}.B; %#ok<AGROW>
  operation_count(level) = gram_operations + endpoint_operations; %#ok<AGROW>
  shell_count(level) = nnz(mask); %#ok<AGROW>
  clear selected Wp Wm mask
end
n_exec = sum(operation_count) + 8;
scale = max([S, endpoint{1}.plus_norm, endpoint{1}.minus_norm, ...
  endpoint{2}.plus_norm, endpoint{2}.minus_norm, ...
  endpoint{1}.singleton_norm, endpoint{2}.singleton_norm, realmin]);
omega = cfg.roundoff.multiplier * n_exec * cfg.roundoff.eps * scale;
near_zero = all(S <= omega);
contraction_pass = near_zero || ...
  S(2) <= max(cfg.threshold.refinement_contraction * S(1), omega);
if near_zero
  ratio = 0;
elseif S(1) <= omega && S(2) > omega
  ratio = Inf;
else
  ratio = S(2) / S(1);
end
row = struct('label', label, 'S1', S(1), 'S2', S(2), ...
  'ratio', ratio, 'omega', omega, 'near_zero', near_zero, ...
  'contraction_pass', contraction_pass, 'R_Fourier', 0, ...
  'counted_in', 'corresponding target-axis remainder', ...
  'shell_mode_counts', shell_count, 'operation_count', n_exec, ...
  'all_computed_modes_retained', true, ...
  'outward_tail_bound', false);
end

function mask = LOCAL_shell_mask(N, inner_count, outer_count)
if outer_count > N || inner_count >= outer_count || ...
    any(mod([N, inner_count, outer_count], 2))
  error('I32V2:FourierShellLevels', 'A Fourier shell band is invalid.');
end
orders = (-N / 2:N / 2 - 1).';
inner = orders >= -inner_count / 2 & orders <= inner_count / 2 - 1;
outer = orders >= -outer_count / 2 & orders <= outer_count / 2 - 1;
mask = outer & ~inner;
if nnz(mask) ~= outer_count - inner_count
  error('I32V2:FourierShellMask', ...
    'A Fourier shell mask has the wrong number of modes.');
end
end

function blocks = LOCAL_vector_blocks(value, rows, count)
if numel(value) ~= rows * count
  error('I32V2:FourierShellShape', ...
    'A Fourier singleton vector has the wrong block count.');
end
blocks = cell(1, count);
for j = 1:count
  blocks{j} = value((j - 1) * rows + (1:rows));
end
end

function LOCAL_validate_block(value, rows, columns, label)
if ~isnumeric(value) || ~isequal(size(value), [rows, columns]) || ...
    ~all(isfinite(value(:)))
  error('I32V2:FourierShellShape', 'Invalid %s.', label);
end
end

function side = LOCAL_side_sum(F, P, c, N)
K = size(P, 1);
W0 = F' * F;
[W_double, PN_double,W_double_ops] = LOCAL_doubling(W0, P, N);
[W_direct, PN_direct,W_direct_ops] = LOCAL_direct_gram(W0, P, N);
eP = norm(PN_double - PN_direct, 2);
a_hi = norm(PN_double, 2) + eP + 100 * K * eps * ...
  max([1, norm(PN_double, 2), norm(PN_direct, 2)]);
if norm(W0, 'fro') == 0
  omega_W = 0;
else
  omega_W = norm(W_double - W_direct, 2) + 100 * K * eps * ...
    max(norm(W_double, 2), norm(W_direct, 2));
end
finite = real(c' * W_double * c);
negative_tol = 100 * K * eps * norm(W_double, 2) * norm(c)^2;
if finite < -negative_tol
  error('I32V2:IndefiniteFullPGram', ...
    'A full-P Gram contraction is significantly negative.');
elseif finite < 0
  finite = 0;
end
if ~(isfinite(a_hi) && a_hi < 1)
  error('I32V2:FullPTailUnavailable', ...
    'The complete-matrix full-P tail cannot be formed at a required level.');
end
tail = a_hi^2 / (1 - a_hi^2) * ...
  (norm(W_double, 2) + omega_W) * norm(c)^2;
side = struct('finite', finite, 'tail', tail, 'a_hi', a_hi, ...
  'omega_W', omega_W, 'operation_count', ...
  size(F,1)*K^2+W_double_ops+W_direct_ops+ ...
  2*K^2+4*K+12);
end

function [W, PN,operations] = LOCAL_doubling(W0, P, N)
W = W0;
PN = P;
current = 1;
K=size(P,1); operations=0;
while current < N
  W = W + PN' * W * PN;
  PN = PN * PN;
  operations=operations+3*K^3+K^2;
  current = 2 * current;
end
end

function [W, PN,operations] = LOCAL_direct_gram(W0, P, N)
K = size(P, 1);
W = zeros(K, K, 'like', W0);
power = eye(K, 'like', P);
operations=0;
for n = 1:N
  W = W + power' * W0 * power;
  power = P * power;
  operations=operations+3*K^3+K^2;
end
PN = power;
end

function [vector,operations] = LOCAL_zero_padded_action(F, P, c, N, Nmax)
rows = size(F, 1);
vector = complex(zeros(rows * Nmax, 1));
state = c;
K=size(P,1); operations=0;
for n = 1:N
  indices = (n - 1) * rows + (1:rows);
  vector(indices) = F * state;
  state = P * state;
  operations=operations+rows*K+K^2;
end
end

%% ==================== Field-lower three-path audit ====================
% The helper receives no kernel or action module and proves the GQP row zero.

function field = LOCAL_field_lower(c, a, cfg)
levels = cfg.levels.fullp;
Fp = a.lead_field_factor_plus;
Fm = a.lead_field_factor_minus;
center = real(c.center_wall_jumps.field_squared);
for j = 1:numel(levels)
  [direct(j), direct_ops(j)] = LOCAL_field_direct(Fp, c.Pplus, c.cplus, ...
    Fm, c.Pminus, c.cminus, center, levels(j)); %#ok<AGROW>
end
[gram8, gram_ops] = LOCAL_field_gram(Fp, c.Pplus, c.cplus, ...
  Fm, c.Pminus, c.cminus, center, levels(1));
[comp8, comp_ops] = LOCAL_field_compensated(Fp, c.Pplus, c.cplus, ...
  Fm, c.Pminus, c.cminus, center, levels(1));

N_h_star = direct(1);
historical = real(a.N_tilde);
downward = [max(0, historical - direct(1)), ...
  max(0, direct(1) - direct(2)), max(0, direct(2) - direct(3))];
A_obs = sum(downward);
n_cmp = sum(direct_ops) + 3;
omega_cmp = cfg.roundoff.multiplier * n_cmp * cfg.roundoff.eps * ...
  max([realmin, abs(historical), abs(direct)]);
A_N = A_obs + omega_cmp;

paths = [direct(1), gram8, comp8];
r_N = max([abs(paths(1) - paths(2)), abs(paths(1) - paths(3)), ...
  abs(paths(2) - paths(3))]);
n_N = max([direct_ops(1), gram_ops, comp_ops]);
s_N = max([realmin, abs(paths)]);
omega_N = cfg.roundoff.multiplier * n_N * cfg.roundoff.eps * s_N;
epsilon_N = A_N + 2 * max(r_N, omega_N);

if ~all(isfinite([direct, paths, epsilon_N])) || N_h_star <= 0
  error('I32V2:FieldLowerUnavailable', ...
    'The required field-lower finite partial or weight is invalid.');
end
field.levels = levels;
field.direct = direct;
field.paths_N8 = struct('direct', paths(1), 'gram', paths(2), ...
  'compensated', paths(3));
field.N_h_star = N_h_star;
field.historical_anchor = historical;
field.downward_terms = downward;
field.A_N_observed = A_obs;
field.omega_comparison = omega_cmp;
field.A_N = A_N;
field.path_spread = r_N;
field.omega_arithmetic = omega_N;
field.epsilon_N_emp = epsilon_N;
field.negative_increment = any(downward(2:3) > 0);
field.operation_count = n_cmp + n_N;
end

function [value, operations] = LOCAL_field_direct(Fp, Pp, cp, Fm, Pm, cm, center, N)
value = center;
vp = cp;
vm = cm;
for n = 1:N
  yp = Fp * vp;
  ym = Fm * vm;
  value = value + real(yp' * yp) + real(ym' * ym);
  vp = Pp * vp;
  vm = Pm * vm;
end
K = size(Pp, 1);
operations = N * (size(Fp, 1) * K + size(Fm, 1) * K + ...
  size(Fp, 1) + size(Fm, 1) + 2 * K^2 + 2);
end

function [value, operations] = LOCAL_field_gram(Fp, Pp, cp, Fm, Pm, cm, center, N)
K = size(Pp, 1);
[Wp,~,ops_p] = LOCAL_direct_gram(Fp' * Fp, Pp, N);
[Wm,~,ops_m] = LOCAL_direct_gram(Fm' * Fm, Pm, N);
value = center + real(cp' * Wp * cp) + real(cm' * Wm * cm);
operations = (size(Fp,1)+size(Fm,1))*K^2+ ...
  ops_p+ops_m+2*(K^2+K)+2;
end

function [value, operations] = LOCAL_field_compensated(Fp, Pp, cp, Fm, Pm, cm, center, N)
terms = zeros(2 * N + 1, 1);
terms(1) = center;
vp = cp;
vm = cm;
for n = 1:N
  yp = Fp * vp;
  ym = Fm * vm;
  terms(2 * n) = real(yp' * yp);
  terms(2 * n + 1) = real(ym' * ym);
  vp = Pp * vp;
  vm = Pm * vm;
end
value = LOCAL_kahan_sum(terms);
K = size(Pp, 1);
operations = N * (size(Fp, 1) * K + size(Fm, 1) * K + ...
  size(Fp, 1) + size(Fm, 1) + 2 * K^2) + 4 * numel(terms);
end

function total = LOCAL_kahan_sum(values)
total = 0;
correction = 0;
for k = 1:numel(values)
  adjusted = values(k) - correction;
  updated = total + adjusted;
  correction = (updated - total) - adjusted;
  total = updated;
end
end

%% ==================== Cap aggregation and validation ====================
% Axis metrics have already released their coarse raw arrays.

function caps = LOCAL_component_caps(component, module, name, c, cfg)
if strcmp(name, 'volume')
  caps.target = LOCAL_metric(module, ...
    {'data', 'axis_metrics', 'target', 'remainder'});
  caps.source = LOCAL_metric(module, ...
    {'data', 'axis_metrics', 'source', 'remainder'});
else
  target_metric = LOCAL_required(module, ...
    {'data', 'axis_metrics', 'target', 'normal'}, ...
    [name, ' target-axis metric']);
  source_metric = LOCAL_required(module, ...
    {'data', 'axis_metrics', 'source', 'normal'}, ...
    [name, ' source-axis metric']);
  caps.target_diagnostic = LOCAL_gram_axis_cap(target_metric, c, cfg);
  caps.source_diagnostic = LOCAL_gram_axis_cap(source_metric, c, cfg);
  caps.target = caps.target_diagnostic.remainder;
  caps.source = caps.source_diagnostic.remainder;
end
if strcmp(name, 'circle')
  riccati = LOCAL_required(module, {'data', 'axis_metrics', 'riccati'}, ...
    'circle Riccati-axis metric');
  caps.weight_diagnostic = LOCAL_riccati_axis_cap(riccati, c, cfg);
  caps.weight_or_gauss = caps.weight_diagnostic.remainder;
elseif strcmp(name, 'volume')
  caps.weight_or_gauss = LOCAL_metric(module, ...
    {'data', 'axis_metrics', 'gauss', 'remainder'});
else
  caps.weight_or_gauss = 0;
end
caps.fullp = component.fullp_cap;
if strcmp(name, 'volume')
  caps.gqp = LOCAL_metric(module, {'data', 'gqp_metrics', 'cap'});
  caps.gqp_diagnostic = LOCAL_optional(module, {'data', 'gqp_metrics'}, struct());
else
  gqp = LOCAL_required(module, {'data', 'gqp_metrics'}, ...
    [name, ' GQP metric']);
  caps.gqp_diagnostic = LOCAL_gqp_cap(gqp, c, cfg);
  caps.gqp = caps.gqp_diagnostic.cap;
end
caps.arithmetic = 2 * max(component.arithmetic_spread, ...
  component.arithmetic_omega);
values = [caps.target, caps.source, caps.weight_or_gauss, ...
  caps.fullp, caps.gqp, caps.arithmetic];
if all(isfinite(values)) && all(values >= 0)
  caps.total = sum(values);
else
  caps.total = NaN;
end
end

function metric = LOCAL_gram_axis_cap(value, c, cfg)
K = double(c.K);
if ~isequal(size(value.level_plus_gram), [K, K, 3]) || ...
    ~isequal(size(value.level_minus_gram), [K, K, 3]) || ...
    numel(value.singleton_squared) ~= 3
  error('I32V2:AxisMetricSchema', 'A normal/value axis level schema is invalid.');
end
endpoint=cell(1,3); operation_count=LOCAL_operation_total(value.operation_ledger);
for j = 1:3
  [endpoint{j},endpoint_ops]=LOCAL_gram_endpoint( ...
    value.level_plus_gram(:, :, j),value.level_minus_gram(:, :, j), ...
    value.singleton_squared(j),c,cfg);
  B(j)=endpoint{j}.B; %#ok<AGROW>
  operation_count=operation_count+endpoint_ops;
end
[D01,difference_ops_01]=LOCAL_augmented_difference( ...
  value.delta01_plus_gram,value.delta01_minus_gram, ...
  value.delta01_singleton_squared,endpoint{1},endpoint{2},c,cfg);
[D12,difference_ops_12]=LOCAL_augmented_difference( ...
  value.delta12_plus_gram,value.delta12_minus_gram, ...
  value.delta12_singleton_squared,endpoint{2},endpoint{3},c,cfg);
d1 = max(abs(B(2) - B(1)), D01);
d2 = max(abs(B(3) - B(2)), D12);
operation_count=operation_count+difference_ops_01+difference_ops_12+8;
n_ops = operation_count;
omega = cfg.roundoff.multiplier * n_ops * cfg.roundoff.eps * ...
  max([realmin,abs(B)]);
pass = d2 <= cfg.threshold.refinement_contraction * d1;
if pass
  remainder = 2 * max(d2, omega);
else
  remainder = NaN;
end
metric = struct('B', B, 'difference_01', D01, 'difference_12', D12, ...
  'd1', d1, 'd2', d2, 'omega', omega, ...
  'contraction_pass', pass, 'remainder', remainder, ...
  'difference_semantics','AUGMENTED_DIRECT_N32_PLUS_ENDPOINT_TAILS', ...
  'operation_count',operation_count);
end

function metric = LOCAL_riccati_axis_cap(value, c, cfg)
K = double(c.K);
for j = 1:3
  Wp(:, :, j) = LOCAL_cell_gram(value.normal_plus.level, j, K); %#ok<AGROW>
  Wm(:, :, j) = LOCAL_cell_gram(value.normal_minus.level, j, K); %#ok<AGROW>
end
unified.level_plus_gram = Wp;
unified.level_minus_gram = Wm;
unified.singleton_squared = zeros(3, 1);
unified.delta01_plus_gram = LOCAL_cell_gram(value.normal_plus.difference, 1, K);
unified.delta01_minus_gram = LOCAL_cell_gram(value.normal_minus.difference, 1, K);
unified.delta01_singleton_squared = 0;
unified.delta12_plus_gram = LOCAL_cell_gram(value.normal_plus.difference, 2, K);
unified.delta12_minus_gram = LOCAL_cell_gram(value.normal_minus.difference, 2, K);
unified.delta12_singleton_squared = 0;
unified.operation_ledger=value.operation_ledger;
metric = LOCAL_gram_axis_cap(unified, c, cfg);
end

function gram = LOCAL_cell_gram(values, index, K)
if ~iscell(values) || numel(values) < index
  error('I32V2:AxisMetricSchema', 'A Riccati Gram cell is missing.');
end
gram = values{index};
LOCAL_validate_gram(gram, K);
end

function metric = LOCAL_gqp_cap(value, c, cfg)
metric = struct('cap', NaN, 'proxy_relative', NaN, ...
  'interp_relative_01', NaN, 'interp_relative_12', NaN, ...
  'scale_diagnostic', NaN, 'scale_fine', NaN, ...
  'proxy_remainder', NaN, 'interp_remainder', NaN, ...
  'interp_contraction_pass', false,'exact_zero_gate',false, ...
  'operation_count_scale',NaN,'operation_count_relative',NaN);
K = double(c.K);
changes = zeros(5, 1);
[high,high_ops]=LOCAL_gram_endpoint(value.proxy.high_plus_gram, ...
  value.proxy.high_minus_gram,value.proxy.high_singleton_squared,c,cfg);
relative_ops=high_ops;
for j = 1:5
  [variant,variant_ops]=LOCAL_gram_endpoint( ...
    LOCAL_gram_slice(value.proxy.variant_plus_grams,j,K), ...
    LOCAL_gram_slice(value.proxy.variant_minus_grams,j,K), ...
    value.proxy.variant_singleton_squared(j),c,cfg);
  [change_D,change_ops]=LOCAL_augmented_difference( ...
    LOCAL_gram_slice(value.proxy.delta_plus_grams, j, K), ...
    LOCAL_gram_slice(value.proxy.delta_minus_grams, j, K), ...
    value.proxy.singleton_squared(j),high,variant,c,cfg);
  changes(j)=max(abs(variant.B-high.B),change_D);
  relative_ops=relative_ops+variant_ops+change_ops;
end
[scale_diag,scale_diag_ops] = LOCAL_separated_scale(value.scale_diag, c, cfg);
[scale_fine,scale_fine_ops] = LOCAL_separated_scale(value.scale_fine, c, cfg);
exact_zero=LOCAL_bitwise_zero(value.proxy)&&LOCAL_bitwise_zero(value.interp)&& ...
  LOCAL_bitwise_zero(value.scale_diag)&&LOCAL_bitwise_zero(value.scale_fine);
metric.exact_zero_gate=exact_zero;
if exact_zero
  metric.cap = 0;
  metric.proxy_relative = 0;
  metric.interp_relative_01 = 0;
  metric.interp_relative_12 = 0;
  metric.scale_diagnostic = 0;
  metric.scale_fine = 0;
  metric.proxy_remainder = 0;
  metric.interp_remainder = 0;
  metric.interp_contraction_pass = true;
  metric.operation_count_scale=scale_diag_ops;
  metric.operation_count_relative=relative_ops+scale_diag_ops+scale_fine_ops;
  return
end
if ~(isfinite(scale_diag) && isfinite(scale_fine) && ...
    scale_diag > 0 && scale_fine > 0)
  return
end
n_scale = LOCAL_operation_total(value.operation_ledger)+scale_diag_ops;
omega_scale = cfg.roundoff.multiplier * n_scale * cfg.roundoff.eps * ...
  max(scale_diag, realmin);
denominator = max(scale_diag, omega_scale);
r_proxy = max(changes) / denominator;
interp_endpoint=cell(1,3);
for j=1:3
  [interp_endpoint{j},endpoint_ops]=LOCAL_gram_endpoint( ...
    value.interp.level_plus_grams(:,:,j),value.interp.level_minus_grams(:,:,j), ...
    value.interp.singleton_squared(j),c,cfg);
  relative_ops=relative_ops+endpoint_ops;
end
[d01,d01_ops]=LOCAL_augmented_difference(value.interp.delta01_plus_gram, ...
  value.interp.delta01_minus_gram,value.interp.delta01_singleton_squared, ...
  interp_endpoint{1},interp_endpoint{2},c,cfg);
[d12,d12_ops]=LOCAL_augmented_difference(value.interp.delta12_plus_gram, ...
  value.interp.delta12_minus_gram,value.interp.delta12_singleton_squared, ...
  interp_endpoint{2},interp_endpoint{3},c,cfg);
d01=max(abs(interp_endpoint{2}.B-interp_endpoint{1}.B),d01);
d12=max(abs(interp_endpoint{3}.B-interp_endpoint{2}.B),d12);
relative_ops=relative_ops+d01_ops+d12_ops+8;
r01 = d01 / denominator;
r12 = d12 / denominator;
n_relative = LOCAL_operation_total(value.operation_ledger)+relative_ops+ ...
  scale_diag_ops+scale_fine_ops+18;
omega_relative = cfg.roundoff.multiplier*n_relative*cfg.roundoff.eps;
proxy_remainder = 2 * max([r_proxy, cfg.gqp.relative_floor, ...
  omega_relative]) * scale_fine;
pass = r12 <= cfg.gqp.interp_contraction * r01;
if pass
  interp_remainder = 2 * max(r12, omega_relative) * scale_fine;
  cap = proxy_remainder + interp_remainder;
else
  interp_remainder = NaN;
  cap = NaN;
end
metric.cap = cap;
metric.proxy_relative = r_proxy;
metric.interp_relative_01 = r01;
metric.interp_relative_12 = r12;
metric.scale_diagnostic = scale_diag;
metric.scale_fine = scale_fine;
metric.proxy_remainder = proxy_remainder;
metric.interp_remainder = interp_remainder;
metric.interp_contraction_pass = pass;
metric.operation_count_scale=n_scale;
metric.operation_count_relative=n_relative;
end

function [scale,operations] = LOCAL_separated_scale(value, c, cfg)
count = size(value.piece_plus_grams, 3);
if size(value.piece_minus_grams, 3) ~= count || ...
    numel(value.piece_singleton_norms) ~= count
  error('I32V2:GQPScaleSchema', 'Separated GQP scale shapes disagree.');
end
scale = 0;
operations=0;
for j = 1:count
  [piece,piece_ops] = LOCAL_gram_component_norm( ...
    value.piece_plus_grams(:, :, j), value.piece_minus_grams(:, :, j), ...
    abs(value.piece_singleton_norms(j))^2, c, cfg);
  scale=scale+piece; operations=operations+piece_ops+1;
end
end

function [value,operations] = LOCAL_gram_component_norm(Wp, Wm, singleton_squared, c, cfg)
[endpoint,operations]=LOCAL_gram_endpoint(Wp,Wm,singleton_squared,c,cfg);
value=endpoint.B;
end

function [endpoint,operations] = LOCAL_gram_endpoint(Wp,Wm,singleton_squared,c,cfg)
K = double(c.K);
LOCAL_validate_gram(Wp, K);
LOCAL_validate_gram(Wm, K);
N = cfg.levels.fullp(end);
plus = LOCAL_gram_side_sum(Wp, c.Pplus, c.cplus, N);
minus = LOCAL_gram_side_sum(Wm, c.Pminus, c.cminus, N);
squared = real(singleton_squared) + plus.finite + plus.tail + ...
  minus.finite + minus.tail;
tol = cfg.threshold.gram * max([norm(Wp, 2), norm(Wm, 2), realmin]) * ...
  max([norm(c.cplus)^2, norm(c.cminus)^2, 1]);
if squared < -tol
  error('I32V2:IndefiniteDiagnosticGram', ...
    'A diagnostic full-P Gram is significantly indefinite.');
end
endpoint=struct('B',sqrt(max(0,squared)),'tail_plus',plus.tail, ...
  'tail_minus',minus.tail, ...
  'plus_norm',sqrt(max(0,plus.finite+plus.tail)), ...
  'minus_norm',sqrt(max(0,minus.finite+minus.tail)), ...
  'singleton_norm',sqrt(max(0,real(singleton_squared))));
operations=plus.operation_count+minus.operation_count+4;
end

function [value,operations]=LOCAL_augmented_difference(Wp,Wm, ...
    singleton_squared,endpoint_a,endpoint_b,c,cfg)
  K=double(c.K); LOCAL_validate_gram(Wp,K); LOCAL_validate_gram(Wm,K);
  N=cfg.levels.fullp(end);
  plus=LOCAL_gram_finite(Wp,c.Pplus,c.cplus,N);
  minus=LOCAL_gram_finite(Wm,c.Pminus,c.cminus,N);
  squared=real(singleton_squared)+plus.finite+minus.finite+ ...
    (sqrt(max(0,endpoint_b.tail_plus))-sqrt(max(0,endpoint_a.tail_plus)))^2+ ...
    (sqrt(max(0,endpoint_b.tail_minus))-sqrt(max(0,endpoint_a.tail_minus)))^2;
  tol=cfg.threshold.gram*max([norm(Wp,2),norm(Wm,2),realmin])* ...
    max([norm(c.cplus)^2,norm(c.cminus)^2,1]);
  if squared < -tol
    error('I32V2:IndefiniteAugmentedDifference', ...
      'An augmented direct-action difference is significantly indefinite.');
  end
  value=sqrt(max(0,squared)); operations=plus.operation_count+ ...
    minus.operation_count+12;
end

function side = LOCAL_gram_side_sum(W0, P, state, N)
K = size(P, 1);
W = W0;
PN = P;
current = 1;
operations=0;
while current < N
  W = W + PN' * W * PN;
  PN = PN * PN;
  operations=operations+3*K^3+K^2;
  current = 2 * current;
end
finite = real(state' * W * state);
operations=operations+K^2+K;
a_hi = norm(PN, 2) + 100 * K * eps * max(1, norm(PN, 2));
if ~(isfinite(a_hi) && a_hi < 1)
  error('I32V2:FullPTailUnavailable', ...
    'A diagnostic full-P tail cannot be formed.');
end
omega_W = 100 * K * eps * norm(W, 2);
tail = a_hi^2 / (1 - a_hi^2) * (norm(W, 2) + omega_W) * norm(state)^2;
side = struct('finite', finite, 'tail', tail, ...
  'operation_count',operations+12);
end

function side=LOCAL_gram_finite(W0,P,state,N)
  K=size(P,1); W=W0; PN=P; current=1; operations=0;
  while current<N
    W=W+PN'*W*PN; PN=PN*PN;
    operations=operations+3*K^3+K^2; current=2*current;
  end
  finite=real(state'*W*state);
  tol=100*K*eps*norm(W,2)*norm(state)^2;
  if finite < -tol
    error('I32V2:IndefiniteAugmentedFinite', ...
      'A delta-factor finite direct-action norm is significantly negative.');
  end
  side=struct('finite',max(0,finite), ...
    'operation_count',operations+K^2+K);
end

function count=LOCAL_operation_total(ledger)
  if ~isstruct(ledger)||~isfield(ledger,'total')|| ...
      ~isscalar(ledger.total)||~isfinite(ledger.total)||ledger.total<0
    error('I32V2:OperationLedgerSchema', ...
      'A typed executed operation ledger is missing or invalid.');
  end
  count=double(ledger.total);
end

function tf=LOCAL_bitwise_zero(value)
  if isnumeric(value)||islogical(value)
    tf=all(value(:)==0);
  elseif isstruct(value)
    tf=true; names=fieldnames(value);
    for j=1:numel(names)
      tf=tf&&LOCAL_bitwise_zero(value.(names{j}));
      if ~tf, return; end
    end
  elseif iscell(value)
    tf=true;
    for j=1:numel(value)
      tf=tf&&LOCAL_bitwise_zero(value{j});
      if ~tf, return; end
    end
  else
    tf=true;
  end
end

function gram = LOCAL_gram_slice(value, index, K)
if ~isnumeric(value) || size(value, 1) ~= K || size(value, 2) ~= K || ...
    size(value, 3) < index
  error('I32V2:GQPMetricSchema', 'A GQP Gram stack has invalid shape.');
end
gram = value(:, :, index);
end

function LOCAL_validate_gram(value, K)
if ~isnumeric(value) || ~isequal(size(value), [K, K]) || ...
    ~all(isfinite(value(:)))
  error('I32V2:DiagnosticGramSchema', 'A required diagnostic Gram is invalid.');
end
scale = norm(value, 2);
if norm(value - value', 2) > 100 * eps * max(scale, realmin)
  error('I32V2:DiagnosticGramNonHermitian', ...
    'A required diagnostic Gram is non-Hermitian.');
end
end

function module = LOCAL_source_module(name, wall, circle, lifting)
switch name
  case 'wall'
    module = wall;
  case 'circle'
    module = circle;
  case 'volume'
    module = lifting;
  otherwise
    error('I32V2:UnknownComponent', 'Unknown residual component.');
end
end

function value = LOCAL_metric(root, path)
[value, found] = LOCAL_get(root, path);
if ~found || ~(isnumeric(value) && isscalar(value) && isreal(value))
  error('I32V2:ModuleInterface', ...
    'A required scalar metric is missing or has the wrong dimension.');
end
if isinf(value) || (~isnan(value) && value < 0)
  error('I32V2:ModuleInterface', ...
    'A required scalar metric is infinite or negative.');
end
end

function value = LOCAL_required(root, path, label)
[value, found] = LOCAL_get(root, path);
if ~found
  error('I32V2:ModuleInterface', 'Missing %s.', label);
end
end

function value = LOCAL_optional(root, path, fallback)
[value, found] = LOCAL_get(root, path);
if ~found
  value = fallback;
end
end

function [value, found] = LOCAL_get(root, path)
value = root;
found = true;
for k = 1:numel(path)
  if ~isstruct(value) || ~isfield(value, path{k})
    value = [];
    found = false;
    return
  end
  value = value.(path{k});
end
end

function LOCAL_validate_factor(F, K, label)
if ~isnumeric(F) || size(F, 2) ~= K || ~all(isfinite(F(:)))
  error('I32V2:ModuleInterface', 'Invalid %s.', label);
end
end

function LOCAL_resource_check(resource, cfg, location, measured_local_mib)
if nargin < 4
  measured_local_mib = 0;
end
if toc(resource.start_tic) > resource.hard_s
  error('I32V2:HARD_TIME_LIMIT', 'Hard time gate exceeded at %s.', location);
end
proxy_mib = LOCAL_resource_field(resource, 'retained_mib', 0) + ...
  measured_local_mib + LOCAL_resource_field(resource, 'cow_mib', 0) + ...
  LOCAL_resource_field(resource, 'publication_mib', ...
  cfg.resource.publication_reserve_mib);
if proxy_mib > resource.memory_mib_max
  error('I32V2:HARD_MEMORY_LIMIT', 'Memory proxy exceeded at %s.', location);
end
end

function value = LOCAL_resource_field(resource, name, fallback)
value = fallback;
if isstruct(resource) && isfield(resource, name) && ...
    isnumeric(resource.(name)) && isscalar(resource.(name)) && ...
    isfinite(resource.(name))
  value = double(resource.(name));
end
end

%% ==================== Common return schema ====================
% The common return remains compact and serializable after blockers.

function out = LOCAL_empty_return()
out.schema = 'I32V2_FULLP_CAP_V1';
out.status = 'INITIALIZED';
out.available = false;
out.warnings = {};
out.first_blocker = '';
out.audit = struct();
out.counters = struct();
out.memory = struct();
out.data = struct();
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V2:UNIDENTIFIED_BLOCKER';
end
end
