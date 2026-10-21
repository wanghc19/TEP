function out = i32v2_lifting_module(view, circle, wall, gqp, cfg, resource)
%I32V2_LIFTING_MODULE Form value-only wall/circle lift volume factors.
% Purpose:
%   Convert recomputed boundary value defects of the same frozen trial into
%   the explicit cubic wall-strip and circle-collar residual factors.
% Input:
%   view          - authenticated i32v2_computation_view return.
%   circle, wall  - completed boundary-action modules.
%   gqp           - MFS module, used only for compact uncertainty provenance.
%   cfg           - preregistered levels and lift geometry.
%   resource      - shared time and memory gates.
% Output:
%   out - finest combined volume factors and compact axis/GQP metrics.
% Main algorithm:
%   Transform already-evaluated boundary residual samples to density Fourier
%   coordinates, integrate separable cubic-lift source weights by Gauss rules,
%   and form the exact frozen full-P wall/circle pairing.
% Notes:
%   Fourier transforms here act only on boundary residuals. They never replace
%   a layer-potential action or define a cell field.

module_tic = tic;
out = LOCAL_empty_return();
local_peak_mib = 0;
out.data.checkpoint = struct('stage', 'entry', ...
  'gauss_levels_completed', 0, 'gauss_level_in_progress', 0, ...
  'completed_objects', {{}}, 'local_peak_mib', 0, ...
  'operation_count', 0);
out.audit.symbol_ledger = struct( ...
  'delta_D', 'exterior-minus-interior circle value defect', ...
  'a_wall', 'shared trace minus material-cell raw wall trace', ...
  'chi', 'frozen cubic value-only lift shape', ...
  'D_X', 'augmented full-P difference through N=32 with endpoint tails', ...
  'operation_ledger', 'typed executed recurrence and comparison counts', ...
  'F_vol_plus', 'paired right-lead volume factor', ...
  'F_vol_minus', 'paired left-lead volume factor');

try
  view_audit = i32v2_validate_computation_view(view, cfg, 'lifting');
  c = view.data.certificate;
  out.audit.computation_view = view_audit;
  LOCAL_resource_check(resource, cfg, 'lifting entry');
  if nargin < 4 || ~isstruct(gqp) || ~isfield(gqp, 'available') || ~gqp.available
    error('I32V2:GQPUnavailableForLifting', ...
      'The completed MFS-only GQP module is required for provenance.');
  end

  % --- stage 1: extract recomputed finest value-defect maps ---
  circle_value.plus = LOCAL_required(circle, ...
    {'data', 'finest', 'value_plus'}, 'circle plus value-defect map');
  circle_value.minus = LOCAL_required(circle, ...
    {'data', 'finest', 'value_minus'}, 'circle minus value-defect map');
  wall_value.left_plus = LOCAL_required(wall, ...
    {'data', 'finest', 'value_left_plus'}, 'left-wall plus value-defect map');
  wall_value.right_plus = LOCAL_required(wall, ...
    {'data', 'finest', 'value_right_plus'}, 'right-wall plus value-defect map');
  wall_value.left_minus = LOCAL_required(wall, ...
    {'data', 'finest', 'value_left_minus'}, 'left-wall minus value-defect map');
  wall_value.right_minus = LOCAL_required(wall, ...
    {'data', 'finest', 'value_right_minus'}, 'right-wall minus value-defect map');
  LOCAL_validate_value_maps(circle_value, wall_value, c.K, cfg);

  % Boundary-sample transforms retain all actual circle/wall modes.
  circle_coeff.plus = LOCAL_circle_coefficients(circle_value.plus, c.R);
  circle_coeff.minus = LOCAL_circle_coefficients(circle_value.minus, c.R);
  wall_coeff.left_plus = LOCAL_wall_coefficients(wall_value.left_plus, c.beta, c.d);
  wall_coeff.right_plus = LOCAL_wall_coefficients(wall_value.right_plus, c.beta, c.d);
  wall_coeff.left_minus = LOCAL_wall_coefficients(wall_value.left_minus, c.beta, c.d);
  wall_coeff.right_minus = LOCAL_wall_coefficients(wall_value.right_minus, c.beta, c.d);
  probe = whos;
  local_peak_mib = max(local_peak_mib, sum([probe.bytes]) / 2^20);
  out.data.checkpoint.stage = 'boundary residual coordinates complete';
  out.data.checkpoint.completed_objects{end + 1} = ...
    'circle/wall value residual Fourier coordinates';
  out.data.checkpoint.local_peak_mib = local_peak_mib;
  clear circle_value wall_value
  LOCAL_resource_check(resource, cfg, 'boundary Fourier coordinates', ...
    local_peak_mib);

  % --- stage 2: preregistered 32/64/128 Gauss evaluation ---
  gauss_levels = cfg.levels.lift_gauss;
  for j = 1:numel(gauss_levels)
    Ng = gauss_levels(j);
    out.data.checkpoint.stage = 'lift Gauss evaluation';
    out.data.checkpoint.gauss_level_in_progress = Ng;
    weights.circle = i32v2_lift_mode_weights('circle', ...
      size(circle_coeff.plus, 1), Ng, c);
    weights.wall = i32v2_lift_mode_weights('wall', ...
      size(wall_coeff.left_plus, 1), Ng, c);

    Cplus = weights.circle .* circle_coeff.plus;
    Cminus = weights.circle .* circle_coeff.minus;
    Lleft_plus = weights.wall .* wall_coeff.left_plus;
    Lright_plus = weights.wall .* wall_coeff.right_plus;
    Lleft_minus = weights.wall .* wall_coeff.left_minus;
    Lright_minus = weights.wall .* wall_coeff.right_minus;

    Fplus = [Cplus; Lright_plus; Lleft_plus * c.Pplus];
    Fminus = [Cminus; Lleft_minus; Lright_minus * c.Pminus];
    singleton = LOCAL_singleton_factor(c, weights.wall, Lleft_plus, ...
      Lright_minus, cfg);
    gauss(j) = LOCAL_level_metric(Fplus, Fminus, singleton, c, cfg); %#ok<AGROW>
    out.data.checkpoint.gauss_levels_completed = j;
    out.data.checkpoint.gauss_B(j) = gauss(j).B;
    out.data.checkpoint.gauss_coordinate_norm(j) = norm(gauss(j).coordinate);
    out.data.checkpoint.operation_count = ...
      out.data.checkpoint.operation_count + gauss(j).operation_count;
    out.data.checkpoint.completed_objects{end + 1} = ...
      sprintf('lift Gauss level %d', Ng);
    if j == numel(gauss_levels)
      finest.volume_plus = Fplus;
      finest.volume_minus = Fminus;
      finest.singleton = singleton;
    end
    probe = whos;
    local_peak_mib = max(local_peak_mib, sum([probe.bytes]) / 2^20);
    out.data.checkpoint.local_peak_mib = local_peak_mib;
    clear weights Cplus Cminus Lleft_plus Lright_plus Lleft_minus Lright_minus
    clear Fplus Fminus singleton
    LOCAL_resource_check(resource, cfg, sprintf('lift Gauss %d', Ng), ...
      local_peak_mib);
  end

  d1 = max(abs(gauss(2).B - gauss(1).B), ...
    norm(gauss(2).coordinate - gauss(1).coordinate));
  d2 = max(abs(gauss(3).B - gauss(2).B), ...
    norm(gauss(3).coordinate - gauss(2).coordinate));
  n_gauss = sum([gauss.operation_count]) + numel(gauss(3).coordinate) * 2;
  omega_gauss = cfg.roundoff.multiplier * n_gauss * cfg.roundoff.eps * ...
    max([realmin, [gauss.B], cellfun(@(x) norm(x), {gauss.coordinate})]);
  gauss_available = d2 <= cfg.threshold.refinement_contraction * d1;
  if gauss_available
    gauss_remainder = 2 * max(d2, omega_gauss);
  else
    gauss_remainder = NaN;
    out.warnings{end + 1} = 'LIFT_GAUSS_REFINEMENT_UNRESOLVED';
  end
  clear gauss

  % --- stage 3: propagate lift-weighted value-action GQP uncertainty once ---
  gqp_metrics = LOCAL_value_gqp_cap(circle, wall, c, cfg);
  out.data.checkpoint.stage = 'volume GQP propagation complete';
  out.data.checkpoint.completed_objects{end + 1} = ...
    'volume GQP compact metric';
  gqp_cap = gqp_metrics.cap;
  if ~isfinite(gqp_cap)
    out.warnings{end + 1} = 'VOLUME_GQP_PROPAGATION_UNRESOLVED';
  end

  % --- stage 4: compact source/target axis ledgers ---
  circle_target = LOCAL_required(circle, ...
    {'data', 'axis_metrics', 'target', 'value'}, ...
    'circle target value-axis metric');
  wall_target = LOCAL_required(wall, ...
    {'data', 'axis_metrics', 'target', 'value'}, ...
    'wall target value-axis metric');
  circle_source = LOCAL_required(circle, ...
    {'data', 'axis_metrics', 'source', 'value'}, ...
    'circle source value-axis metric');
  wall_source = LOCAL_required(wall, ...
    {'data', 'axis_metrics', 'source', 'value'}, ...
    'wall source value-axis metric');
  out.data.axis_metrics.target = LOCAL_combined_axis_cap( ...
    circle_target, wall_target, c, cfg);
  out.data.axis_metrics.source = LOCAL_combined_axis_cap( ...
    circle_source, wall_source, c, cfg);
  out.data.axis_metrics.gauss = struct('d1', d1, 'd2', d2, ...
    'omega', omega_gauss, 'contraction_pass', gauss_available, ...
    'remainder', gauss_remainder);
  out.data.gqp_metrics = gqp_metrics;
  out.data.gqp_metrics.counted_once_in = 'V';
  out.data.finest = finest;
  out.data.checkpoint.stage = 'complete';
  out.data.checkpoint.completed_objects{end + 1} = ...
    'combined volume axis metrics';
  if numel(finest.singleton)~=4*cfg.levels.wall_target(end)
    error('I32V2:LiftSingletonShape', ...
      'The four disjoint wall-strip singleton blocks were not preserved.');
  end

  out.audit.self_quadrature = ...
    'Boundary values supplied by rectangular Kress actions; lift integration uses Gauss weights.';
  out.audit.circle_jacobian = 'r/R included';
  out.audit.rho_weight = 'rho^(-1/2) included before gamma^(-1/2)';
  out.audit.fourier_use = 'boundary residual coordinates only';
  out.counters.density_solves = 0;
  out.counters.rayleigh_field_calls = 0;
  out.counters.image_sum_calls = 0;
  out.counters.interpft_calls = 0;
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
out.memory.largest_object = 'finest combined volume factors';
out.memory.cleared_objects = {'boundary value samples', ...
  'coarse Gauss factors', 'Gauss nodes', 'Gauss coordinates'};
out.data.checkpoint.local_peak_mib = out.memory.local_peak_mib;
out.audit.elapsed_s = toc(module_tic);
end

%% ==================== Boundary residual Fourier coordinates ====================
% FFTs represent boundary residuals and native Nyström densities only.

function coeff = LOCAL_circle_coefficients(samples, R)
N = size(samples, 1);
orders = (-N / 2:N / 2 - 1).';
phase = exp(-1i * pi * orders / N);
coeff = sqrt(2 * pi * R) * (fftshift(fft(samples, [], 1), 1) / N);
coeff = phase .* coeff;
end

function coeff = LOCAL_wall_coefficients(samples, beta, d)
N = size(samples, 1);
d = double(d);
orders = (-N / 2:N / 2 - 1).';
y = -d / 2 + d * ((0:N - 1).' + 0.5) / N;
gauged = exp(-1i * beta * y) .* samples;
phase = exp(1i * pi * orders) .* exp(-1i * pi * orders / N);
coeff = sqrt(d) * (fftshift(fft(gauged, [], 1), 1) / N);
coeff = phase .* coeff;
end

%% ==================== Full-P aligned lift metrics ====================
% Coarse arrays are released immediately after augmented differences form.

function metric = LOCAL_level_metric(Fp, Fm, singleton, c, cfg)
N = cfg.levels.fullp(end);
[vp, tp, op_p] = LOCAL_action_and_tail(Fp, c.Pplus, c.cplus, N);
[vm, tm, op_m] = LOCAL_action_and_tail(Fm, c.Pminus, c.cminus, N);
metric.coordinate = [singleton(:); vp; vm; sqrt(max(0, tp)); sqrt(max(0, tm))];
metric.B = norm(metric.coordinate);
metric.operation_count = op_p + op_m + numel(metric.coordinate);
end

function [values, tail, operations] = LOCAL_action_and_tail(F, P, state, N)
rows = size(F, 1);
K = size(P, 1);
values = complex(zeros(rows * N, 1));
power_state = state;
for n = 1:N
  indices = (n - 1) * rows + (1:rows);
  values(indices) = F * power_state;
  power_state = P * power_state;
end
W0 = F' * F;
W = W0;
PN = P;
current = 1;
operations=N*(rows*K+K^2);
while current < N
  W = W + PN' * W * PN;
  PN = PN * PN;
  operations=operations+3*K^3+K^2;
  current = 2 * current;
end
a_hi = norm(PN, 2) + 100 * K * eps * max(1, norm(PN, 2));
if ~(isfinite(a_hi) && a_hi < 1)
  error('I32V2:FullPTailUnavailable', ...
    'The lift full-P tail cannot be formed.');
end
omega_W = 100 * K * eps * norm(W, 2);
tail = a_hi^2 / (1 - a_hi^2) * (norm(W, 2) + omega_W) * norm(state)^2;
operations = operations + rows*K^2+12;
end

%% ==================== Lift-weighted GQP cap ====================
% Circle and wall value maps are combined as one volume direct sum.

function metrics = LOCAL_value_gqp_cap(circle, wall, c, cfg)
metrics = struct('cap', NaN, 'proxy_relative', NaN, ...
  'interp_relative_01', NaN, 'interp_relative_12', NaN, ...
  'scale_diagnostic', NaN, 'scale_fine', NaN, ...
  'proxy_remainder', NaN, 'interp_remainder', NaN, ...
  'interp_contraction_pass', false,'exact_zero_gate',false, ...
  'operation_count_scale',NaN,'operation_count_relative',NaN);
[cg, found_circle] = LOCAL_get(circle, {'data', 'value_gqp_metrics'});
[wg, found_wall] = LOCAL_get(wall, {'data', 'value_gqp_metrics'});
if ~(found_circle && found_wall)
  error('I32V2:ValueGQPSchema', ...
    'Circle and wall value GQP metrics are required.');
end
K = double(c.K);
  variants = 5;
  proxy_changes = zeros(variants, 1);
  [proxy_high,high_ops]=LOCAL_combined_endpoint(cg.proxy.high_plus_gram, ...
    wg.proxy.high_plus_gram,cg.proxy.high_minus_gram, ...
    wg.proxy.high_minus_gram,cg.proxy.high_singleton_squared+ ...
    wg.proxy.high_singleton_squared,c,cfg);
  relative_ops=high_ops;
  for j = 1:variants
    Wp = LOCAL_gram_slice(cg.proxy.delta_plus_grams, j, K) + ...
      LOCAL_gram_slice(wg.proxy.delta_plus_grams, j, K);
    Wm = LOCAL_gram_slice(cg.proxy.delta_minus_grams, j, K) + ...
      LOCAL_gram_slice(wg.proxy.delta_minus_grams, j, K);
    singleton_squared = double(cg.proxy.singleton_squared(j)) + ...
      double(wg.proxy.singleton_squared(j));
    [variant_endpoint,variant_ops]=LOCAL_combined_endpoint( ...
      LOCAL_gram_slice(cg.proxy.variant_plus_grams,j,K), ...
      LOCAL_gram_slice(wg.proxy.variant_plus_grams,j,K), ...
      LOCAL_gram_slice(cg.proxy.variant_minus_grams,j,K), ...
      LOCAL_gram_slice(wg.proxy.variant_minus_grams,j,K), ...
      cg.proxy.variant_singleton_squared(j)+ ...
      wg.proxy.variant_singleton_squared(j),c,cfg);
    [change_D,change_ops]=LOCAL_augmented_difference(Wp,Wm, ...
      singleton_squared,proxy_high,variant_endpoint,c,cfg);
    proxy_changes(j)=max(abs(variant_endpoint.B-proxy_high.B),change_D);
    relative_ops=relative_ops+variant_ops+change_ops;
  end

  [circle_scale_diag,circle_diag_ops]=LOCAL_separated_scale(cg.scale_diag,c,cfg);
  [wall_scale_diag,wall_diag_ops]=LOCAL_separated_scale(wg.scale_diag,c,cfg);
  [circle_scale_fine,circle_fine_ops]=LOCAL_separated_scale(cg.scale_fine,c,cfg);
  [wall_scale_fine,wall_fine_ops]=LOCAL_separated_scale(wg.scale_fine,c,cfg);
  scale_diag=circle_scale_diag+wall_scale_diag;
  scale_fine=circle_scale_fine+wall_scale_fine;
  scale_diag_ops=circle_diag_ops+wall_diag_ops+1;
  scale_fine_ops=circle_fine_ops+wall_fine_ops+1;
  if ~(isfinite(scale_diag) && isfinite(scale_fine) && ...
      scale_diag >= 0 && scale_fine >= 0)
    return
  end
  exact_zero=LOCAL_bitwise_zero(cg.proxy)&&LOCAL_bitwise_zero(wg.proxy)&& ...
    LOCAL_bitwise_zero(cg.interp)&&LOCAL_bitwise_zero(wg.interp)&& ...
    LOCAL_bitwise_zero(cg.scale_diag)&&LOCAL_bitwise_zero(wg.scale_diag)&& ...
    LOCAL_bitwise_zero(cg.scale_fine)&&LOCAL_bitwise_zero(wg.scale_fine);
  metrics.exact_zero_gate=exact_zero;
  if exact_zero
    metrics.cap = 0;
    metrics.proxy_relative = 0;
    metrics.interp_relative_01 = 0;
    metrics.interp_relative_12 = 0;
    metrics.scale_diagnostic = 0;
    metrics.scale_fine = 0;
    metrics.proxy_remainder = 0;
    metrics.interp_remainder = 0;
    metrics.interp_contraction_pass = true;
    metrics.operation_count_scale=scale_diag_ops;
    metrics.operation_count_relative=relative_ops+scale_diag_ops+scale_fine_ops;
    return
  elseif scale_diag <= 0 || scale_fine <= 0
    return
  end

  n_scale=LOCAL_operation_total(cg.operation_ledger)+ ...
    LOCAL_operation_total(wg.operation_ledger)+scale_diag_ops;
  omega_scale = cfg.roundoff.multiplier * n_scale * cfg.roundoff.eps * ...
    max(scale_diag, realmin);
  denominator = max(scale_diag, omega_scale);
  r_proxy = max(proxy_changes) / denominator;

  interp_endpoint=cell(1,3);
  for j=1:3
    [interp_endpoint{j},endpoint_ops]=LOCAL_combined_endpoint( ...
      cg.interp.level_plus_grams(:,:,j),wg.interp.level_plus_grams(:,:,j), ...
      cg.interp.level_minus_grams(:,:,j),wg.interp.level_minus_grams(:,:,j), ...
      cg.interp.singleton_squared(j)+wg.interp.singleton_squared(j),c,cfg);
    relative_ops=relative_ops+endpoint_ops;
  end
  [d01,d01_ops]=LOCAL_combined_interp_change(cg.interp,wg.interp, ...
    'delta01',interp_endpoint{1},interp_endpoint{2},c,cfg);
  [d12,d12_ops]=LOCAL_combined_interp_change(cg.interp,wg.interp, ...
    'delta12',interp_endpoint{2},interp_endpoint{3},c,cfg);
  d01=max(abs(interp_endpoint{2}.B-interp_endpoint{1}.B),d01);
  d12=max(abs(interp_endpoint{3}.B-interp_endpoint{2}.B),d12);
  relative_ops=relative_ops+d01_ops+d12_ops+8;
  r01 = d01 / denominator;
  r12 = d12 / denominator;
  n_relative=LOCAL_operation_total(cg.operation_ledger)+ ...
    LOCAL_operation_total(wg.operation_ledger)+relative_ops+ ...
    scale_diag_ops+scale_fine_ops+18;
  omega_relative = cfg.roundoff.multiplier * n_relative * cfg.roundoff.eps;

  proxy_remainder = 2 * max([r_proxy, cfg.gqp.relative_floor, ...
    omega_relative]) * scale_fine;
  contraction_pass = r12 <= cfg.gqp.interp_contraction * r01;
  if contraction_pass
    interp_remainder = 2 * max(r12, omega_relative) * scale_fine;
    cap = proxy_remainder + interp_remainder;
  else
    interp_remainder = NaN;
    cap = NaN;
  end
  metrics.cap = cap;
  metrics.proxy_relative = r_proxy;
  metrics.interp_relative_01 = r01;
  metrics.interp_relative_12 = r12;
  metrics.scale_diagnostic = scale_diag;
  metrics.scale_fine = scale_fine;
  metrics.proxy_remainder = proxy_remainder;
  metrics.interp_remainder = interp_remainder;
metrics.interp_contraction_pass = contraction_pass;
metrics.operation_count_scale=n_scale;
metrics.operation_count_relative=n_relative;
end

function [value,operations] = LOCAL_combined_interp_change(cg,wg,prefix, ...
    endpoint_a,endpoint_b,c,cfg)
Wp = cg.([prefix, '_plus_gram']) + wg.([prefix, '_plus_gram']);
Wm = cg.([prefix, '_minus_gram']) + wg.([prefix, '_minus_gram']);
singleton_squared = double(cg.([prefix, '_singleton_squared'])) + ...
  double(wg.([prefix, '_singleton_squared']));
[value,operations]=LOCAL_augmented_difference(Wp,Wm,singleton_squared, ...
  endpoint_a,endpoint_b,c,cfg);
end

function [scale,operations] = LOCAL_separated_scale(value, c, cfg)
K = double(c.K);
count = size(value.piece_plus_grams, 3);
if size(value.piece_minus_grams, 3) ~= count || ...
    numel(value.piece_singleton_norms) ~= count
  error('I32V2:ValueGQPSchema', 'Separated GQP scale shapes disagree.');
end
scale = 0;
operations=0;
for j = 1:count
  Wp = LOCAL_gram_slice(value.piece_plus_grams, j, K);
  Wm = LOCAL_gram_slice(value.piece_minus_grams, j, K);
  singleton_squared = abs(value.piece_singleton_norms(j))^2;
  [piece,piece_ops]=LOCAL_gram_component_norm(Wp,Wm,singleton_squared,c,cfg);
  scale=scale+piece; operations=operations+piece_ops+1;
end
end

function [value,operations] = LOCAL_gram_component_norm(Wp,Wm,singleton_squared,c,cfg)
[endpoint,operations]=LOCAL_gram_endpoint(Wp,Wm,singleton_squared,c,cfg);
value=endpoint.B;
end

function [endpoint,operations]=LOCAL_combined_endpoint(Wp_circle,Wp_wall, ...
    Wm_circle,Wm_wall,singleton_squared,c,cfg)
  [endpoint,operations]=LOCAL_gram_endpoint(Wp_circle+Wp_wall, ...
    Wm_circle+Wm_wall,singleton_squared,c,cfg);
  operations=operations+2*numel(Wp_circle);
end

function [endpoint,operations]=LOCAL_gram_endpoint(Wp,Wm,singleton_squared,c,cfg)
LOCAL_validate_gram(Wp, double(c.K));
LOCAL_validate_gram(Wm, double(c.K));
N = cfg.levels.fullp(end);
plus = LOCAL_gram_side_sum(Wp, c.Pplus, c.cplus, N);
minus = LOCAL_gram_side_sum(Wm, c.Pminus, c.cminus, N);
squared = real(singleton_squared) + plus.finite + plus.tail + ...
  minus.finite + minus.tail;
tol = cfg.threshold.gram * max([norm(Wp, 2), norm(Wm, 2), realmin]) * ...
  max([norm(c.cplus)^2, norm(c.cminus)^2, 1]);
if squared < -tol
  error('I32V2:ValueGQPIndefinite', ...
    'A lift-weighted GQP difference Gram is significantly indefinite.');
end
endpoint=struct('B',sqrt(max(0,squared)),'tail_plus',plus.tail, ...
  'tail_minus',minus.tail);
operations=plus.operation_count+minus.operation_count+4;
end

function [value,operations]=LOCAL_augmented_difference(Wp,Wm, ...
    singleton_squared,endpoint_a,endpoint_b,c,cfg)
  LOCAL_validate_gram(Wp,double(c.K)); LOCAL_validate_gram(Wm,double(c.K));
  N=cfg.levels.fullp(end);
  plus=LOCAL_gram_finite(Wp,c.Pplus,c.cplus,N);
  minus=LOCAL_gram_finite(Wm,c.Pminus,c.cminus,N);
  squared=real(singleton_squared)+plus.finite+minus.finite+ ...
    (sqrt(max(0,endpoint_b.tail_plus))-sqrt(max(0,endpoint_a.tail_plus)))^2+ ...
    (sqrt(max(0,endpoint_b.tail_minus))-sqrt(max(0,endpoint_a.tail_minus)))^2;
  tol=cfg.threshold.gram*max([norm(Wp,2),norm(Wm,2),realmin])* ...
    max([norm(c.cplus)^2,norm(c.cminus)^2,1]);
  if squared < -tol
    error('I32V2:ValueAugmentedDifference', ...
      'A volume augmented direct-action difference is indefinite.');
  end
  value=sqrt(max(0,squared));
  operations=plus.operation_count+minus.operation_count+12;
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
    'A lift-weighted GQP full-P tail cannot be formed.');
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
finite=real(state'*W*state); tol=100*K*eps*norm(W,2)*norm(state)^2;
if finite < -tol
  error('I32V2:ValueAugmentedFinite', ...
    'A volume delta-factor finite direct-action norm is negative.');
end
side=struct('finite',max(0,finite), ...
  'operation_count',operations+K^2+K);
end

function gram = LOCAL_gram_slice(value, index, K)
if ~isnumeric(value) || ~isequal(size(value, 1), K) || ...
    ~isequal(size(value, 2), K) || size(value, 3) < index
  error('I32V2:ValueGQPSchema', 'A GQP Gram stack has invalid shape.');
end
gram = value(:, :, index);
end

function LOCAL_validate_gram(value, K)
if ~isnumeric(value) || ~isequal(size(value), [K, K]) || ...
    ~all(isfinite(value(:)))
  error('I32V2:ValueGQPSchema', 'A required GQP Gram is invalid.');
end
scale = norm(value, 2);
if norm(value - value', 2) > 100 * eps * max(scale, realmin)
  error('I32V2:ValueGQPNonHermitian', 'A required GQP Gram is non-Hermitian.');
end
end

function count=LOCAL_operation_total(ledger)
if ~isstruct(ledger)||~isfield(ledger,'total')|| ...
    ~isscalar(ledger.total)||~isfinite(ledger.total)||ledger.total<0
  error('I32V2:OperationLedgerSchema', ...
    'A typed executed boundary-operation ledger is missing or invalid.');
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

function singleton = LOCAL_singleton_factor(c, wall_weights, Lleft_plus, ...
    Lright_minus, cfg)
center_left = c.center_wall_jumps.left_value_lift_source;
center_right = c.center_wall_jumps.right_value_lift_source;
left_coeff = LOCAL_wall_coefficients(center_left, c.beta, c.d);
right_coeff = LOCAL_wall_coefficients(center_right, c.beta, c.d);
N = numel(wall_weights);
left_padded = LOCAL_pad_modes(left_coeff, N);
right_padded = LOCAL_pad_modes(right_coeff, N);
center_factor = [wall_weights .* left_padded; wall_weights .* right_padded];
lead_factor = [Lleft_plus * c.cplus; Lright_minus * c.cminus];
singleton = [center_factor; lead_factor];
if ~all(isfinite(singleton)) || cfg.lift.delta_wall ~= c.delta_w
  error('I32V2:LiftSingletonUnavailable', ...
    'The center/first value-lift singleton is invalid.');
end
end

function padded = LOCAL_pad_modes(native, N)
Nnative = size(native, 1);
if Nnative > N || mod(Nnative, 2) ~= 0 || mod(N, 2) ~= 0
  error('I32V2:ModePadding', 'Invalid midpoint-grid mode padding.');
end
padded = complex(zeros(N, size(native, 2)));
start_index = N / 2 - Nnative / 2 + 1;
padded(start_index:start_index + Nnative - 1, :) = native;
end

%% ==================== Compact metrics and validation ====================
% These helpers preserve fail-open diagnostics for finite refinement failures.

function metric = LOCAL_combined_axis_cap(circle, wall, c, cfg)
fields = {'level_plus_gram', 'level_minus_gram'};
for j = 1:numel(fields)
  field = fields{j};
  combined.(field) = circle.(field) + wall.(field);
end
combined.singleton_squared = circle.singleton_squared + wall.singleton_squared;
names = {'delta01', 'delta12'};
for j = 1:numel(names)
  name = names{j};
  combined.([name, '_plus_gram']) = circle.([name, '_plus_gram']) + ...
    wall.([name, '_plus_gram']);
  combined.([name, '_minus_gram']) = circle.([name, '_minus_gram']) + ...
    wall.([name, '_minus_gram']);
  combined.([name, '_singleton_squared']) = ...
    circle.([name, '_singleton_squared']) + ...
    wall.([name, '_singleton_squared']);
end
K = double(c.K);
if ~isequal(size(combined.level_plus_gram), [K, K, 3]) || ...
    ~isequal(size(combined.level_minus_gram), [K, K, 3]) || ...
    numel(combined.singleton_squared) ~= 3
  error('I32V2:ValueAxisSchema', 'Combined value-axis schema is invalid.');
end
operation_count=LOCAL_operation_total(circle.operation_ledger)+ ...
  LOCAL_operation_total(wall.operation_ledger)+10*K^2+9;
endpoint=cell(1,3);
for j = 1:3
  [endpoint{j},endpoint_ops]=LOCAL_gram_endpoint( ...
    combined.level_plus_gram(:,:,j),combined.level_minus_gram(:,:,j), ...
    combined.singleton_squared(j),c,cfg);
  B(j)=endpoint{j}.B; operation_count=operation_count+endpoint_ops; %#ok<AGROW>
end
[D01,difference_ops_01]=LOCAL_augmented_difference( ...
  combined.delta01_plus_gram,combined.delta01_minus_gram, ...
  combined.delta01_singleton_squared,endpoint{1},endpoint{2},c,cfg);
[D12,difference_ops_12]=LOCAL_augmented_difference( ...
  combined.delta12_plus_gram,combined.delta12_minus_gram, ...
  combined.delta12_singleton_squared,endpoint{2},endpoint{3},c,cfg);
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
  'combination', 'circle-wall-volume-direct-sum', ...
  'difference_semantics','AUGMENTED_DIRECT_N32_PLUS_ENDPOINT_TAILS', ...
  'operation_count',operation_count);
end

function LOCAL_validate_value_maps(circle_value, wall_value, K, cfg)
circle_names = fieldnames(circle_value);
for k = 1:numel(circle_names)
  value = circle_value.(circle_names{k});
  if size(value, 1) ~= cfg.levels.circle_target(end) || ...
      size(value, 2) ~= K || ~all(isfinite(value(:)))
    error('I32V2:ModuleInterface', 'Invalid finest circle value map.');
  end
end
wall_names = fieldnames(wall_value);
for k = 1:numel(wall_names)
  value = wall_value.(wall_names{k});
  if size(value, 1) ~= cfg.levels.wall_target(end) || ...
      size(value, 2) ~= K || ~all(isfinite(value(:)))
    error('I32V2:ModuleInterface', 'Invalid finest wall value map.');
  end
end
end

function value = LOCAL_required(root, path, label)
[value, found] = LOCAL_get(root, path);
if ~found
  error('I32V2:ModuleInterface', 'Missing %s.', label);
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
% The module always returns a serializable compact blocker or result.

function out = LOCAL_empty_return()
out.schema = 'I32V2_LIFTING_V1';
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
