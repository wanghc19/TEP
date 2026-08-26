function out = i32v3_boundary(c, gqp, cfg, resource)
%I32V3_BOUNDARY Evaluate all frozen-trial circle and wall boundary actions.
% Purpose:
%   Form the wall-normal, circle-normal, and boundary-value residual factors
%   of one unchanged all-boundary layer-potential trial.
% Input:
%   c        - Double frozen certificate.
%   gqp      - One-table return from i32v3_gqp.
%   cfg      - Frozen Section 13 configuration.
%   resource - Shared 1800 s / 2048 MiB resource gate.
% Output:
%   out.private - Finest factors, compact source/target/Riccati axes, value
%                 maps for lifting, and unique GQP piece factors.
%   out.data    - Compact self/cross/total, common-band, and audit metrics.
% Main algorithm:
%   Prolong only the frozen Nyström densities, apply rectangular/off-grid
%   Kress self quadrature with explicit jumps, stream positive-distance
%   cross actions through i32v3_gqp, then align boundary residuals on fixed
%   finest Fourier grids.
% Based on:
%   design-3-2d Sections 5--7 and Section 13.
% Main changes:
%   All action and Kress formulas are local to v3; no old e-cap evaluator is
%   called and Fourier analysis occurs only after layer-potential evaluation.

timer = tic;
out = LOCAL_empty();
progress = struct('stage', 'entry', 'completed_actions', 0.0, ...
  'completed_physical_actions', 0.0, 'completed_reused_actions', 0.0, ...
  'completed_target_levels', 0.0, 'completed_source_levels', 0.0, ...
  'completed_rows', 0.0, 'local_peak_mib', 0.0, 'complete', false);
out.audit.symbol_ledger = struct( ...
  'tau', 'frozen circle double-layer density interpolant', ...
  'zeta', 'frozen circle coordinate zeta=-sigma', ...
  'xi_left', 'frozen left-wall single-layer density interpolant', ...
  'j_W', 'adjacent-cell outward wall Neumann sum', ...
  'j_Gamma', 'interior-minus-exterior material-normal defect', ...
  'delta_D', 'exterior-minus-interior circle value defect', ...
  'D_X', 'aligned level-factor difference with endpoint tail coordinates');
try
  LOCAL_validate(c, gqp, cfg, resource);
  circle_levels = cfg.levels.circle_target;
  wall_levels = cfg.levels.wall_target;
  circle_target = cell(1, 3);
  circle_source = cell(1, 3);
  wall_target = cell(1, 3);
  wall_source = cell(1, 3);

  % --- stage 1: circle target and paired-source axes ---
  progress.stage = 'circle axes';
  for j = 1:3
    circle_target{j} = LOCAL_circle_action(c, gqp, cfg, resource, ...
      circle_levels(end), wall_levels(end), circle_levels(j), ...
      circle_levels(end), true);
    progress.completed_physical_actions = ...
      progress.completed_physical_actions + 1.0;
    progress.completed_rows = progress.completed_rows + circle_levels(j);
    if j == 3
      circle_source{j} = circle_target{j};
      progress.completed_reused_actions = ...
        progress.completed_reused_actions + 1.0;
    else
      circle_source{j} = LOCAL_circle_action(c, gqp, cfg, resource, ...
        circle_levels(j), wall_levels(j), circle_levels(end), ...
        circle_levels(end), false);
      progress.completed_physical_actions = ...
        progress.completed_physical_actions + 1.0;
      progress.completed_rows = progress.completed_rows + circle_levels(end);
    end
    progress.completed_actions = progress.completed_actions + 2.0;
    progress.completed_target_levels = j;
    progress.completed_source_levels = j;
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      LOCAL_workspace_mib());
    LOCAL_resource(resource, progress.local_peak_mib);
  end
  circle_fine = circle_target{3};
  circle_normal_target = LOCAL_axis(LOCAL_factors(circle_target, ...
    'normal_factor'));
  circle_normal_source = LOCAL_axis(LOCAL_factors(circle_source, ...
    'normal_factor'));
  circle_value_target = LOCAL_axis(LOCAL_factors(circle_target, ...
    'volume_factor'));
  circle_value_source = LOCAL_axis(LOCAL_factors(circle_source, ...
    'volume_factor'));
  circle_riccati = LOCAL_circle_riccati(circle_fine, c, cfg);
  circle_bands = LOCAL_band_levels(circle_target, cfg, 'circle');
  clear circle_target circle_source

  % --- stage 2: wall target and paired-source axes ---
  progress.stage = 'wall axes';
  for j = 1:3
    wall_target{j} = LOCAL_wall_action(c, gqp, cfg, resource, ...
      wall_levels(end), circle_levels(end), wall_levels(j), ...
      wall_levels(end), true);
    progress.completed_physical_actions = ...
      progress.completed_physical_actions + 1.0;
    progress.completed_rows = progress.completed_rows + wall_levels(j);
    if j == 3
      wall_source{j} = wall_target{j};
      progress.completed_reused_actions = ...
        progress.completed_reused_actions + 1.0;
    else
      wall_source{j} = LOCAL_wall_action(c, gqp, cfg, resource, ...
        wall_levels(j), circle_levels(j), wall_levels(end), ...
        wall_levels(end), false);
      progress.completed_physical_actions = ...
        progress.completed_physical_actions + 1.0;
      progress.completed_rows = progress.completed_rows + wall_levels(end);
    end
    progress.completed_actions = progress.completed_actions + 2.0;
    progress.completed_target_levels = progress.completed_target_levels + 1.0;
    progress.completed_source_levels = progress.completed_source_levels + 1.0;
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      LOCAL_workspace_mib());
    LOCAL_resource(resource, progress.local_peak_mib);
  end
  wall_fine = wall_target{3};
  wall_normal_target = LOCAL_axis(LOCAL_factors(wall_target, ...
    'normal_factor'));
  wall_normal_source = LOCAL_axis(LOCAL_factors(wall_source, ...
    'normal_factor'));
  wall_value_target = LOCAL_axis(LOCAL_factors(wall_target, ...
    'volume_factor'));
  wall_value_source = LOCAL_axis(LOCAL_factors(wall_source, ...
    'volume_factor'));
  wall_bands = LOCAL_band_levels(wall_target, cfg, 'wall');
  clear wall_target wall_source

  % --- stage 3: compact return and unique GQP piece ledger ---
  private.wall_factor = wall_fine.normal_factor;
  private.circle_factor = circle_fine.normal_factor;
  private.value_maps = struct( ...
    'circle_plus', circle_fine.value_plus_samples, ...
    'circle_minus', circle_fine.value_minus_samples, ...
    'wall_left_plus', wall_fine.value_left_plus_samples, ...
    'wall_right_plus', wall_fine.value_right_plus_samples, ...
    'wall_left_minus', wall_fine.value_left_minus_samples, ...
    'wall_right_minus', wall_fine.value_right_minus_samples);
  private.axes = struct( ...
    'wall_target', wall_normal_target, 'wall_source', wall_normal_source, ...
    'circle_target', circle_normal_target, ...
    'circle_source', circle_normal_source, ...
    'circle_riccati', circle_riccati, ...
    'value_target_circle', circle_value_target, ...
    'value_target_wall', wall_value_target, ...
    'value_source_circle', circle_value_source, ...
    'value_source_wall', wall_value_source);
  private.gqp_factors = struct( ...
    'wall', {wall_fine.gqp_normal_factors}, ...
    'circle', {circle_fine.gqp_normal_factors}, ...
    'volume_circle', {circle_fine.gqp_value_factors}, ...
    'volume_wall', {wall_fine.gqp_value_factors});
  private.wall_cross_maps = wall_fine.cross_maps;

  out.data = struct();
  out.data.source_axis_counts = [circle_levels(:), wall_levels(:)];
  out.data.circle = struct('recombination_defect', ...
    circle_fine.recombination_defect, 'piece_norms', ...
    circle_fine.piece_norms, 'bands', circle_bands, ...
    'normal_factor_norm', LOCAL_factor_fro(circle_fine.normal_factor), ...
    'value_factor_norm', LOCAL_factor_fro(circle_fine.volume_factor));
  out.data.wall = struct('recombination_defect', ...
    wall_fine.recombination_defect, 'self_split_recombination', ...
    wall_fine.self_split_recombination, 'piece_norms', ...
    wall_fine.piece_norms, 'bands', wall_bands, ...
    'normal_factor_norm', LOCAL_factor_fro(wall_fine.normal_factor), ...
    'value_factor_norm', LOCAL_factor_fro(wall_fine.volume_factor));
  out.data.wall.map_audit = struct( ...
    'opposite_cross', LOCAL_map_audit(wall_fine.cross_maps.opposite_cross), ...
    'circle_cross', LOCAL_map_audit(wall_fine.cross_maps.circle_cross), ...
    'dense_maps_retained_private_only', true);
  out.data.gqp_piece_ledger = struct( ...
    'wall', {LOCAL_piece_names(wall_fine.gqp_normal_factors)}, ...
    'circle', {LOCAL_piece_names(circle_fine.gqp_normal_factors)}, ...
    'volume_circle', {LOCAL_piece_names(circle_fine.gqp_value_factors)}, ...
    'volume_wall', {LOCAL_piece_names(wall_fine.gqp_value_factors)}, ...
    'counted_once', true);
  out.audit.fixed_trial = true;
  out.audit.density_resolve_count = 0.0;
  out.audit.circle_self_quadrature = ...
    'rectangular Kress S,D,Dstar,T-difference plus explicit jumps';
  out.audit.wall_self_quadrature = ...
    'periodic-gauge rectangular Kress split plus explicit +1/2 interior jump';
  out.audit.target_axis = ...
    'source finest; target 3 levels aligned on family finest grid';
  out.audit.source_axis = ...
    ['paired circle/wall sources; target fixed family finest grid; ', ...
    'identical finest target/source action reused'];
  out.audit.fourier_use = ...
    'boundary residual coordinates and diagnostics only';
  out.audit.image_sum_code_path_zero = true;
  out.audit.rayleigh_field_code_path_zero = true;
  out.counters = struct('density_solves', 0.0, 'image_sum_calls', 0.0, ...
    'rayleigh_field_calls', 0.0, 'old_ecap_calls', 0.0, ...
    'logical_target_actions', 6.0, 'logical_source_actions', 6.0, ...
    'physical_actions', progress.completed_physical_actions, ...
    'reused_actions', progress.completed_reused_actions);
  if max([circle_fine.recombination_defect, ...
      wall_fine.recombination_defect, wall_fine.self_split_recombination]) ...
      > cfg.threshold.recombination
    out.warnings{end + 1} = 'BOUNDARY_RECOMBINATION_WARNING';
  end
  out.private = private;
  out.available = true;
  out.status = 'COMPLETE';
  progress.stage = 'complete';
  progress.complete = true;
  clear circle_fine wall_fine private
catch err
  out.status = 'BLOCKED';
  out.first_blocker = LOCAL_identifier(err);
  out.audit.exception_message = err.message;
  progress.stage = 'blocked';
  progress.first_blocker = out.first_blocker;
  clear circle_target circle_source wall_target wall_source
end
out.audit.progress = progress;
info = whos('out');
out.memory = struct('local_peak_mib', max(progress.local_peak_mib, ...
  info.bytes / 2^20), 'retained_mib', info.bytes / 2^20, ...
  'largest_object', 'finest physical boundary value maps', ...
  'cleared_objects', {{'coarse actions after compact axes', ...
  'raw source/target panels after each product'}});
out.audit.elapsed_s = toc(timer);
end

%% ==================== Circle all-boundary action ====================
% Value and normal defects use the same finite density at every level.

function action = LOCAL_circle_action(c, gqp, cfg, resource, ...
    nc, nw, nt, ncommon, collect_pieces)
[tau, zeta, tau_s, theta_s] = LOCAL_circle_density(c, nc);
[tau_t, zeta_t, ~, theta_t] = LOCAL_circle_density(c, nt);
src = c.R * [cos(theta_s).'; sin(theta_s).'];
trg = c.R * [cos(theta_t).'; sin(theta_t).'];
nsn = [cos(theta_s).'; sin(theta_s).'];
ntn = [cos(theta_t).'; sin(theta_t).'];
state_count = size(tau, 2);
value = tau_t;
normal = zeta_t;
prescribed = tau_t;
self_value = complex(zeros(nt, state_count));
cross_value = self_value;
piece = LOCAL_circle_piece_empty(nt, state_count);
operation_count = 0.0;
for first = 1.0:cfg.panel.target_max:nt
  last = min(nt, first + cfg.panel.target_max - 1.0);
  ids = first:last;
  value_free = complex(zeros(numel(ids), state_count));
  normal_free = value_free;
  for source_first = 1.0:cfg.panel.source_max:nc
    source_last = min(nc, source_first + cfg.panel.source_max - 1.0);
    source_ids = source_first:source_last;
    weights = LOCAL_rect_kress(theta_s(source_ids), theta_t(ids), ...
      nc, source_ids);
    [vf, nf] = LOCAL_circle_free(c.khat, ...
      c.khat * sqrt(c.rho_disk), c.R, theta_s(source_ids), ...
      theta_t(ids), weights, tau(source_ids, :), zeta(source_ids, :), ...
      tau_s(source_ids, :), nc);
    value_free = value_free + vf;
    normal_free = normal_free + nf;
    operation_count = operation_count + ...
      10.0 * numel(ids) * numel(source_ids) * state_count;
  end
  [value_proxy, normal_proxy, proxy_piece, proxy_ops] = ...
    LOCAL_circle_proxy(gqp, src, trg(:, ids), nsn, ntn(:, ids), ...
    tau, zeta, 2.0 * pi * c.R / nc, cfg.panel.source_max);
  [value_wall, normal_wall, wall_piece, wall_ops] = ...
    LOCAL_walls_to_circle(c, gqp, trg(:, ids), ntn(:, ids), nw, ...
    cfg.panel.source_max);
  self_panel = value_free + value_proxy;
  value(ids, :) = value(ids, :) + self_panel + value_wall;
  normal(ids, :) = normal(ids, :) + normal_free + normal_proxy + normal_wall;
  self_value(ids, :) = self_panel;
  cross_value(ids, :) = value_wall;
  if collect_pieces
    piece.circle_double.value(ids, :) = proxy_piece.value_double;
    piece.circle_double.normal(ids, :) = proxy_piece.normal_double;
    piece.circle_single.value(ids, :) = proxy_piece.value_single;
    piece.circle_single.normal(ids, :) = proxy_piece.normal_single;
    piece.wall_left.value(ids, :) = wall_piece.left.value;
    piece.wall_left.normal(ids, :) = wall_piece.left.normal;
    piece.wall_right.value(ids, :) = wall_piece.right.value;
    piece.wall_right.normal(ids, :) = wall_piece.right.normal;
  end
  operation_count = operation_count + proxy_ops + wall_ops;
  LOCAL_resource(resource, LOCAL_workspace_mib());
end
recombined = prescribed + self_value + cross_value;
recombination = norm(value - recombined, 'fro') / max(norm(value, 'fro'), realmin);
value_coeff = LOCAL_circle_coeff(value, c.R, ncommon);
normal_coeff = LOCAL_circle_coeff(normal, c.R, ncommon);
weight = LOCAL_circle_weight(c, ncommon, cfg.levels.riccati(end));
normal_weighted = normal_coeff ./ sqrt(weight);
normal_factor = struct('plus', normal_weighted * c.Gplus, ...
  'minus', normal_weighted * c.Gminus, ...
  'singleton', complex(zeros(0, 1)), ...
  'operation_count', operation_count);
lift_weight = i32v3_lifting('weights', 'circle', ncommon, ...
  cfg.levels.lift_gauss(end), c);
volume_factor = struct('plus', (lift_weight .* value_coeff) * c.Gplus, ...
  'minus', (lift_weight .* value_coeff) * c.Gminus, ...
  'singleton', complex(zeros(0, 1)), ...
  'operation_count', operation_count);
action = struct('normal_factor', normal_factor, ...
  'volume_factor', volume_factor, ...
  'normal_aligned_plus', normal_coeff * c.Gplus, ...
  'normal_aligned_minus', normal_coeff * c.Gminus, ...
  'value_plus_samples', value * c.Gplus, ...
  'value_minus_samples', value * c.Gminus, ...
  'recombination_defect', recombination, ...
  'piece_norms', struct('prescribed', norm(prescribed, 'fro'), ...
  'self', norm(self_value, 'fro'), 'cross', norm(cross_value, 'fro'), ...
  'total', norm(value, 'fro')), 'operation_count', operation_count);
if collect_pieces
  action.band_factors = LOCAL_circle_band_factors(prescribed, self_value, ...
    cross_value, value, c, ncommon);
  [action.gqp_normal_factors, action.gqp_value_factors] = ...
    LOCAL_circle_gqp_factors(piece, c, ncommon, weight, lift_weight);
end
end

function [value, normal, piece, operations] = LOCAL_circle_proxy( ...
    gqp, src, trg, nsn, ntn, tau, zeta, ds, source_panel)
nt = size(trg, 2);
state_count = size(tau, 2);
value = complex(zeros(nt, state_count));
normal = value;
piece = struct('value_double', value, 'value_single', value, ...
  'normal_double', value, 'normal_single', value);
operations = 0.0;
for first = 1.0:source_panel:size(src, 2)
  last = min(size(src, 2), first + source_panel - 1.0);
  ids = first:last;
  [p, gx, gy, hxx, hxy, hyy, audit] = ...
    i32v3_gqp('pair', gqp, src(:, ids), trg, false);
  sx = nsn(1, ids);
  sy = nsn(2, ids);
  D = -gx .* sx - gy .* sy;
  T = -hxx .* (ntn(1, :).'*sx) ...
    - hxy .* (ntn(1, :).'*sy + ntn(2, :).'*sx) ...
    - hyy .* (ntn(2, :).'*sy);
  Sn = gx .* ntn(1, :).' + gy .* ntn(2, :).';
  vd = ds * D * tau(ids, :);
  vs = -ds * p * zeta(ids, :);
  nd = ds * T * tau(ids, :);
  ns = -ds * Sn * zeta(ids, :);
  value = value + vd + vs;
  normal = normal + nd + ns;
  piece.value_double = piece.value_double + vd;
  piece.value_single = piece.value_single + vs;
  piece.normal_double = piece.normal_double + nd;
  piece.normal_single = piece.normal_single + ns;
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    4.0 * nt * numel(ids) * state_count;
end
end

function [value, normal, piece, operations] = LOCAL_walls_to_circle( ...
    c, gqp, trg, ntn, nw, source_panel)
[xi_left, y, ds] = LOCAL_wall_density(c.xi_left_unit_512, c, nw);
[xi_right, ~, ~] = LOCAL_wall_density(c.xi_right_unit_512, c, nw);
nt = size(trg, 2);
state_count = size(xi_left, 2);
value = complex(zeros(nt, state_count));
normal = value;
piece.left = struct('value', value, 'normal', value);
piece.right = struct('value', value, 'normal', value);
operations = 0.0;
for side = 1:2
  if side == 1, x = c.X_L; density = xi_left; name = 'left';
  else, x = c.X_R; density = xi_right; name = 'right'; end
  src = [x * ones(1, nw); y.'];
  for first = 1.0:source_panel:nw
    last = min(nw, first + source_panel - 1.0);
    ids = first:last;
    [p, gx, gy, ~, ~, ~, audit, rp, rgx, rgy] = ...
      i32v3_gqp('pair', gqp, src(:, ids), trg, true);
    v = ds * p * density(ids, :);
    nk = gx .* ntn(1, :).' + gy .* ntn(2, :).';
    q = ds * nk * density(ids, :);
    rv = ds * rp * density(ids, :);
    rnk = rgx .* ntn(1, :).' + rgy .* ntn(2, :).';
    rq = ds * rnk * density(ids, :);
    value = value + v;
    normal = normal + q;
    piece.(name).value = piece.(name).value + rv;
    piece.(name).normal = piece.(name).normal + rq;
    operations = operations + audit.interpolation_cma + ...
      audit.bloch_phase_multiply_count + ...
      2.0 * nt * numel(ids) * state_count;
  end
end
end

%% ==================== Wall all-boundary action ====================
% Same-wall, opposite-wall, and circle pieces remain separately auditable.

function action = LOCAL_wall_action(c, gqp, cfg, resource, ...
    nw, nc, nt, ncommon, collect_pieces)
yt = -c.d / 2.0 + c.d * ((0.0:nt - 1.0).' + 0.5) / nt;
[xi_left, ys, ~] = LOCAL_wall_density(c.xi_left_unit_512, c, nw);
[xi_right, ~, ~] = LOCAL_wall_density(c.xi_right_unit_512, c, nw);
state_count = size(xi_left, 2);
raw_left = complex(zeros(nt, state_count));
raw_right = raw_left;
flux_left = raw_left;
flux_right = raw_left;
pieces = LOCAL_wall_piece_empty(nt, state_count);
diagnostics = LOCAL_wall_value_diagnostic_empty(nt, state_count);
self_split = 0.0;
operation_count = 0.0;
for first = 1.0:cfg.panel.target_max:nt
  last = min(nt, first + cfg.panel.target_max - 1.0);
  ids = first:last;
  [raw_left(ids, :), flux_left(ids, :), left_piece, left_diagnostic, ...
    split_left, ops_left] = ...
    LOCAL_wall_side(c, gqp, cfg, ys, yt(ids), xi_left, xi_right, ...
    nc, -1.0);
  [raw_right(ids, :), flux_right(ids, :), right_piece, right_diagnostic, ...
    split_right, ops_right] = ...
    LOCAL_wall_side(c, gqp, cfg, ys, yt(ids), xi_left, xi_right, ...
    nc, 1.0);
  self_split = max([self_split, split_left, split_right]);
  names = fieldnames(pieces);
  for j = 1:numel(names)
    name = names{j};
    pieces.(name).value_left(ids, :) = left_piece.(name).value;
    pieces.(name).flux_left(ids, :) = left_piece.(name).flux;
    pieces.(name).value_right(ids, :) = right_piece.(name).value;
    pieces.(name).flux_right(ids, :) = right_piece.(name).flux;
  end
  diagnostic_names = fieldnames(diagnostics);
  for j = 1:numel(diagnostic_names)
    name = diagnostic_names{j};
    diagnostics.(name).value_left(ids, :) = left_diagnostic.(name);
    diagnostics.(name).value_right(ids, :) = right_diagnostic.(name);
  end
  operation_count = operation_count + ops_left + ops_right;
  LOCAL_resource(resource, LOCAL_workspace_mib());
end
[state_maps, sample_maps] = LOCAL_wall_state_maps(raw_left, raw_right, c, ncommon);
weight = LOCAL_wall_weight(c, ncommon);
QL_raw = LOCAL_wall_coeff(flux_left, c, ncommon);
QR_raw = LOCAL_wall_coeff(flux_right, c, ncommon);
QL = QL_raw ./ sqrt(weight);
QR = QR_raw ./ sqrt(weight);
normal_factor = struct( ...
  'plus', QR * c.Gplus + QL * c.Gplus * c.Pplus, ...
  'minus', QL * c.Gminus + QR * c.Gminus * c.Pminus, ...
  'singleton', LOCAL_wall_flux_singleton(QL_raw, QR_raw, c, ncommon, weight), ...
  'operation_count', operation_count);
lift_weight = i32v3_lifting('weights', 'wall', ncommon, ...
  cfg.levels.lift_gauss(end), c);
volume_factor = LOCAL_wall_volume_factor(state_maps, lift_weight, c);
volume_factor.operation_count = operation_count;
value_samples = LOCAL_wall_value_samples(sample_maps, c);

% Residual pieces are prescribed - self - cross.
prescribed_maps = LOCAL_wall_prescribed_maps(c, ncommon);
self_maps = LOCAL_wall_piece_state(diagnostics.self, c, ncommon, -1.0);
opposite_maps = LOCAL_wall_piece_state( ...
  diagnostics.opposite_cross, c, ncommon, -1.0);
circle_maps = LOCAL_wall_piece_state( ...
  diagnostics.circle_cross, c, ncommon, -1.0);
total_maps = LOCAL_wall_state_residual(state_maps, c);
recombined_left = prescribed_maps.left + self_maps.left + ...
  opposite_maps.left + circle_maps.left;
recombined_right = prescribed_maps.right + self_maps.right + ...
  opposite_maps.right + circle_maps.right;
recombination = norm([total_maps.left - recombined_left; ...
  total_maps.right - recombined_right], 'fro') / ...
  max(norm([total_maps.left; total_maps.right], 'fro'), realmin);

action = struct('normal_factor', normal_factor, ...
  'volume_factor', volume_factor, ...
  'value_left_plus_samples', value_samples.left * c.Gplus, ...
  'value_right_plus_samples', value_samples.right * c.Gplus, ...
  'value_left_minus_samples', value_samples.left * c.Gminus, ...
  'value_right_minus_samples', value_samples.right * c.Gminus, ...
  'recombination_defect', recombination, ...
  'self_split_recombination', self_split, ...
  'piece_norms', struct('prescribed', ...
  norm([prescribed_maps.left; prescribed_maps.right], 'fro'), ...
  'self', norm([self_maps.left; self_maps.right], 'fro'), ...
  'opposite_cross', norm([opposite_maps.left; opposite_maps.right], 'fro'), ...
  'circle_cross', norm([circle_maps.left; circle_maps.right], 'fro'), ...
  'total', norm([total_maps.left; total_maps.right], 'fro')), ...
  'operation_count', operation_count);
if collect_pieces
  action.cross_maps = struct('opposite_cross', opposite_maps, ...
    'circle_cross', circle_maps);
  action.band_factors = LOCAL_wall_band_factors(prescribed_maps, ...
    self_maps, opposite_maps, circle_maps, total_maps, c);
  [action.gqp_normal_factors, action.gqp_value_factors] = ...
    LOCAL_wall_gqp_factors(pieces, c, ncommon, weight, lift_weight);
end
end

function [value, flux, piece, diagnostic, split, operations] = LOCAL_wall_side( ...
    c, gqp, cfg, ys, yt, xi_left, xi_right, nc, side)
nt = numel(yt);
state_count = size(xi_left, 2);
zero = complex(zeros(nt, state_count));
piece = struct('wall_self', struct('value', zero, 'flux', zero), ...
  'wall_other', struct('value', zero, 'flux', zero), ...
  'circle_double', struct('value', zero, 'flux', zero), ...
  'circle_single', struct('value', zero, 'flux', zero));
diagnostic = struct('self', zero, 'opposite_cross', zero, ...
  'circle_cross', zero);
if side < 0.0
  xt = c.X_L; xo = c.X_R; density = xi_left; other = xi_right; normal = -1.0;
else
  xt = c.X_R; xo = c.X_L; density = xi_right; other = xi_left; normal = 1.0;
end
[self_value, self_flux, kernel_flux, remainder_value, split, self_ops] = ...
  LOCAL_wall_self(c, gqp, ys, yt, density, xt, normal, ...
  cfg.panel.source_max);
piece.wall_self.value = remainder_value;
piece.wall_self.flux = kernel_flux;
value = self_value;
flux = self_flux;
diagnostic.self = self_value;
ds = c.d / numel(ys);
src = [xo * ones(1, numel(ys)); ys.'];
trg = [xt * ones(1, nt); yt.'];
operations = self_ops;
for first = 1.0:cfg.panel.source_max:numel(ys)
  last = min(numel(ys), first + cfg.panel.source_max - 1.0);
  ids = first:last;
  [p, gx, ~, ~, ~, ~, audit, rp, rgx] = ...
    i32v3_gqp('pair', gqp, src(:, ids), trg, true);
  v = ds * p * other(ids, :);
  q = ds * normal * gx * other(ids, :);
  rv = ds * rp * other(ids, :);
  rq = ds * normal * rgx * other(ids, :);
  value = value + v;
  flux = flux + q;
  diagnostic.opposite_cross = diagnostic.opposite_cross + v;
  piece.wall_other.value = piece.wall_other.value + rv;
  piece.wall_other.flux = piece.wall_other.flux + rq;
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    2.0 * nt * numel(ids) * state_count;
end
[circle_value, circle_flux, circle_piece, circle_ops] = ...
  LOCAL_circle_to_wall(c, gqp, trg, normal, nc, cfg.panel.source_max);
value = value + circle_value;
flux = flux + circle_flux;
diagnostic.circle_cross = circle_value;
piece.circle_double = circle_piece.double;
piece.circle_single = circle_piece.single;
operations = operations + circle_ops;
end

function [value, flux, piece, operations] = LOCAL_circle_to_wall( ...
    c, gqp, trg, normal_sign, nc, source_panel)
[tau, zeta, ~, theta] = LOCAL_circle_density(c, nc);
src = c.R * [cos(theta).'; sin(theta).'];
nsn = [cos(theta).'; sin(theta).'];
nt = size(trg, 2);
state_count = size(tau, 2);
zero = complex(zeros(nt, state_count));
value = zero;
flux = zero;
piece.double = struct('value', zero, 'flux', zero);
piece.single = struct('value', zero, 'flux', zero);
ds = 2.0 * pi * c.R / nc;
operations = 0.0;
for first = 1.0:source_panel:nc
  last = min(nc, first + source_panel - 1.0);
  ids = first:last;
  [p, gx, gy, hxx, hxy, ~, audit, rp, rgx, rgy, rhxx, rhxy, ~] = ...
    i32v3_gqp('pair', gqp, src(:, ids), trg, true);
  sx = nsn(1, ids);
  sy = nsn(2, ids);
  D = -gx .* sx - gy .* sy;
  Dt = -normal_sign * (hxx .* sx + hxy .* sy);
  Sn = normal_sign * gx;
  Dr = -rgx .* sx - rgy .* sy;
  Dtr = -normal_sign * (rhxx .* sx + rhxy .* sy);
  Snr = normal_sign * rgx;
  vd = ds * D * tau(ids, :);
  vs = -ds * p * zeta(ids, :);
  qd = ds * Dt * tau(ids, :);
  qs = -ds * Sn * zeta(ids, :);
  rvd = ds * Dr * tau(ids, :);
  rvs = -ds * rp * zeta(ids, :);
  rqd = ds * Dtr * tau(ids, :);
  rqs = -ds * Snr * zeta(ids, :);
  value = value + vd + vs;
  flux = flux + qd + qs;
  piece.double.value = piece.double.value + rvd;
  piece.double.flux = piece.double.flux + rqd;
  piece.single.value = piece.single.value + rvs;
  piece.single.flux = piece.single.flux + rqs;
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    4.0 * nt * numel(ids) * state_count;
end
end

%% ==================== Self quadrature ====================
% These local formulas are the v3 production paths, not copied function calls.

function [value, normal, exterior] = LOCAL_circle_free(kout, kin, R, ...
    ts, tt, log_weights, tau, zeta, tau_s, source_count)
h = 2.0 * pi / source_count;
outside = LOCAL_circle_splits(kout, R, ts, tt);
inside = LOCAL_circle_splits(kin, R, ts, tt);
D = log_weights .* (outside.L1 - inside.L1) + ...
  h * (outside.L2 - inside.L2);
S = log_weights .* (inside.M1 - outside.M1) + ...
  h * (inside.M2 - outside.M2);
Ds = log_weights .* (inside.Ls1 - outside.Ls1) + ...
  h * (inside.Ls2 - outside.Ls2);
[TS, TT] = meshgrid(ts, tt);
geometry = cos(TT - TS);
A = (log_weights .* (kout^2 * outside.M1 - kin^2 * inside.M1) + ...
  h * (kout^2 * outside.M2 - kin^2 * inside.M2)) .* geometry;
B = (log_weights .* (outside.N1 - inside.N1) + ...
  h * (outside.N2 - inside.N2)) / R;
value = D * tau + S * zeta;
normal = A * tau + B * tau_s + Ds * zeta;
Dout = log_weights .* outside.L1 + h * outside.L2;
Sout = log_weights .* outside.M1 + h * outside.M2;
Aout = (log_weights .* (kout^2 * outside.M1) + ...
  h * kout^2 * outside.M2) .* geometry;
Bout = (log_weights .* outside.N1 + h * outside.N2) / R;
exterior = struct('value_double', Dout * tau, ...
  'value_single', -Sout * zeta, ...
  'normal_double', Aout * tau + Bout * tau_s, ...
  'normal_single', -(log_weights .* outside.Ls1 + ...
  h * outside.Ls2) * zeta);
end

function split = LOCAL_circle_splits(k, R, ts, tt)
[TS, TT] = meshgrid(ts, tt);
dx = R * (cos(TT) - cos(TS));
dy = R * (sin(TT) - sin(TS));
radius = hypot(dx, dy);
diagonal = radius <= 64.0 * eps(R);
safe = radius;
safe(diagonal) = 1.0;
nusx = R * cos(TS);
nusy = R * sin(TS);
ntx = cos(TT);
nty = sin(TT);
dot_source = dx .* nusx + dy .* nusy;
dot_target = dx .* ntx + dy .* nty;
zptx = -R * sin(TT);
zpty = R * cos(TT);
dot_tangent = zptx .* dx + zpty .* dy;
logterm = log(4.0 * sin((TT - TS) / 2.0).^2);
cotterm = cot((TT - TS) / 2.0);
M = 1i / 4.0 * besselh(0, 1, k * safe) * R;
split.M1 = -1.0 / (4.0 * pi) * besselj(0, k * safe) * R;
L = 1i * k / 4.0 * (dot_source ./ safe) .* besselh(1, 1, k * safe);
split.L1 = -k / (4.0 * pi) * (dot_source ./ safe) .* besselj(1, k * safe);
Ls = -1i * k / 4.0 * (dot_target ./ safe) .* besselh(1, 1, k * safe) * R;
split.Ls1 = k / (4.0 * pi) * (dot_target ./ safe) .* besselj(1, k * safe) * R;
N = -1i * k / 4.0 * (dot_tangent ./ safe) .* besselh(1, 1, k * safe);
split.N1 = k / (4.0 * pi) * (dot_tangent ./ safe) .* besselj(1, k * safe);
split.M2 = M - split.M1 .* logterm;
split.L2 = L - split.L1 .* logterm;
split.Ls2 = Ls - split.Ls1 .* logterm;
split.N2 = N - 1.0 / (4.0 * pi) * cotterm - split.N1 .* logterm;
euler = 0.5772156649015328606;
split.M1(diagonal) = -R / (4.0 * pi);
split.M2(diagonal) = 0.5 * (1i / 2.0 - euler / pi - ...
  log(k^2 * R^2 / 4.0) / (2.0 * pi)) * R;
split.L1(diagonal) = 0.0;
split.Ls1(diagonal) = 0.0;
split.N1(diagonal) = 0.0;
split.L2(diagonal) = -1.0 / (4.0 * pi);
split.Ls2(diagonal) = -1.0 / (4.0 * pi);
split.N2(diagonal) = 0.0;
end

function [value, flux, kernel_flux, remainder_value, recombination, operations] = ...
    LOCAL_wall_self(c, gqp, ys, yt, xi, xwall, normal_sign, source_panel)
ns = numel(ys);
nt = numel(yt);
a = c.d / (2.0 * pi);
ts = 2.0 * pi * (ys + c.d / 2.0) / c.d;
tt = 2.0 * pi * (yt + c.d / 2.0) / c.d;
euler = 0.5772156649015328606;
free_limit = 0.5 * (1i / 2.0 - euler / pi - ...
  log(c.khat^2 * a^2 / 4.0) / (2.0 * pi)) * a;
value_gauge = complex(zeros(nt, size(xi, 2)));
kernel_flux = complex(zeros(nt, size(xi, 2)));
remainder_value = complex(zeros(nt, size(xi, 2)));
numerator = 0.0;
scale_squared = 0.0;
trg = [xwall * ones(1, nt); yt.'];
ds = c.d / ns;
operations = 0.0;
for first = 1.0:source_panel:ns
  last = min(ns, first + source_panel - 1.0);
  ids = first:last;
  src = [xwall * ones(1, numel(ids)); ys(ids).'];
  [regular, gx, ~, ~, ~, ~, audit] = ...
    i32v3_gqp('pair', gqp, src, trg, false);
  dy = yt(:) - ys(ids).';
  shift = round(dy / c.d);
  folded = dy - shift * c.d;
  phase = exp(1i * c.beta * c.d * shift);
  radius = abs(folded);
  coincident = radius <= 64.0 * eps(c.d);
  primary = complex(zeros(nt, numel(ids)));
  primary(~coincident) = 1i / 4.0 * ...
    besselh(0, 1, c.khat * radius(~coincident));
  complete = regular + phase .* primary;
  gauged = exp(-1i * c.beta * yt(:)) .* complete .* ...
    exp(1i * c.beta * ys(ids).') * a;
  [TS, TT] = meshgrid(ts(ids), tt);
  delta = TT - TS;
  wrapped = delta - 2.0 * pi * floor((delta + pi) / (2.0 * pi));
  r = abs(wrapped);
  cutoff = zeros(size(r));
  cutoff(r <= pi / 4.0) = 1.0;
  transition = r > pi / 4.0 & r < pi / 2.0;
  left = exp(-1.0 ./ (pi / 2.0 - r(transition)));
  right = exp(-1.0 ./ (r(transition) - pi / 4.0));
  cutoff(transition) = left ./ (left + right);
  q = cutoff .* wrapped;
  A = -a / (4.0 * pi) * exp(-1i * c.beta * a * q) .* ...
    besselj(0, c.khat * a * abs(q));
  logarithm = log(4.0 * sin(delta / 2.0).^2);
  logarithm(coincident) = 0.0;
  B = gauged - A .* logarithm;
  B(coincident) = free_limit + a * regular(coincident);
  A(coincident) = -a / (4.0 * pi);
  active = ~coincident;
  defect = gauged(active) - ...
    (A(active) .* logarithm(active) + B(active));
  numerator = numerator + sum(abs(defect).^2);
  scale_squared = scale_squared + sum(abs(gauged(active)).^2);
  weights = LOCAL_rect_kress(ts(ids), tt, ns, ids);
  density_gauge = exp(-1i * c.beta * ys(ids)) .* xi(ids, :);
  value_gauge = value_gauge + ...
    (weights .* A + (2.0 * pi / ns) * B) * density_gauge;
  remainder_value = remainder_value + ds * regular * xi(ids, :);
  kernel_flux = kernel_flux + ds * normal_sign * gx * xi(ids, :);
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    3.0 * nt * numel(ids) * size(xi, 2);
end
recombination = sqrt(numerator) / max(sqrt(scale_squared), realmin);
value = exp(1i * c.beta * yt(:)) .* value_gauge;
xi_target = LOCAL_wall_density_target(xi, ys, yt, c);
flux = kernel_flux + 0.5 * xi_target;
end

function weights = LOCAL_rect_kress(source_nodes, target_nodes, ...
    source_count, source_indices)
s = source_nodes(:).';
t = target_nodes(:);
ns = double(source_count);
source_indices = double(source_indices(:).');
h = 2.0 * pi / ns;
source_origin = s(1) - (source_indices(1) - 1.0) * h;
q = (t - source_origin) / h;
integer = floor(q);
fraction = q - integer;
near_one = abs(fraction - 1.0) <= 256.0 * eps(max(1.0, max(abs(q))));
integer(near_one) = integer(near_one) + 1.0;
fraction(near_one) = 0.0;
fraction(abs(fraction) <= 256.0 * eps(max(1.0, max(abs(q))))) = 0.0;
group = zeros(numel(t), 1);
representatives = zeros(0, 1);
for j = 1:numel(t)
  hit = find(abs(representatives - fraction(j)) <= ...
    512.0 * eps(max(1.0, abs(fraction(j)))), 1);
  if isempty(hit)
    representatives(end + 1, 1) = fraction(j); %#ok<AGROW>
    hit = numel(representatives);
  end
  group(j) = hit;
end
bases = zeros(numel(representatives), ns);
modes = 1.0:ns / 2.0 - 1.0;
for j = 1:numel(representatives)
  delta0 = representatives(j) * h;
  spectrum = complex(zeros(1, ns));
  spectrum(modes + 1.0) = exp(1i * modes * delta0) ./ (2.0 * modes);
  spectrum(ns - modes + 1.0) = exp(-1i * modes * delta0) ./ (2.0 * modes);
  spectrum(ns / 2.0 + 1.0) = cos((ns / 2.0) * delta0) / ns;
  bases(j, :) = -4.0 * pi / ns * real(fft(spectrum));
end
weights = zeros(numel(t), numel(s));
indices = source_indices - 1.0;
for j = 1:numel(t)
  weights(j, :) = bases(group(j), mod(indices - integer(j), ns) + 1.0);
end
end

%% ==================== Density and Fourier coordinates ====================
% Trigonometric interpolation changes only source quadrature, never density.

function [tau, zeta, tau_s, theta] = LOCAL_circle_density(c, n)
native = 256.0;
orders = (-native / 2.0:native / 2.0 - 1.0).';
tau_native = c.eta_unit_256(1:native, :);
zeta_native = c.eta_unit_256(native + 1.0:end, :);
tau_coeff = fftshift(fft(tau_native, [], 1), 1) / native;
zeta_coeff = fftshift(fft(zeta_native, [], 1), 1) / native;
theta = 2.0 * pi * ((0.0:n - 1.0).' + 0.5) / n;
basis = exp(1i * theta * orders.');
tau = basis * tau_coeff;
zeta = basis * zeta_coeff;
tau_s = basis * (1i * orders .* tau_coeff);
end

function [xi, y, ds] = LOCAL_wall_density(coeff, c, n)
orders = (-256.0:255.0).';
y = -c.d / 2.0 + c.d * ((0.0:n - 1.0).' + 0.5) / n;
ds = c.d / n;
kappa = c.beta + 2.0 * pi * orders / c.d;
xi = exp(1i * y * kappa.') * coeff / sqrt(c.d);
end

function target = LOCAL_wall_density_target(samples, ys, yt, c)
n = numel(ys);
orders = (-n / 2.0:n / 2.0 - 1.0).';
gauge = exp(-1i * c.beta * ys) .* samples;
coeff = fftshift(fft(gauge, [], 1), 1) / n;
origin = -0.5 + 0.5 / n;
coeff = exp(-1i * 2.0 * pi * orders * origin) .* coeff;
target = exp(1i * c.beta * yt(:)) .* ...
  (exp(1i * 2.0 * pi * yt(:) / c.d * orders.') * coeff);
end

function coeff = LOCAL_circle_coeff(samples, R, ncommon)
n = size(samples, 1);
orders = (-n / 2.0:n / 2.0 - 1.0).';
coeff = fftshift(fft(samples, [], 1), 1) / n;
coeff = sqrt(2.0 * pi * R) * exp(-1i * orders * pi / n) .* coeff;
coeff = LOCAL_pad(coeff, ncommon);
end

function coeff = LOCAL_wall_coeff(samples, c, ncommon)
n = size(samples, 1);
orders = (-n / 2.0:n / 2.0 - 1.0).';
y = -c.d / 2.0 + c.d * ((0.0:n - 1.0).' + 0.5) / n;
gauge = exp(-1i * c.beta * y) .* samples;
coeff = fftshift(fft(gauge, [], 1), 1) / n;
origin = -0.5 + 0.5 / n;
coeff = sqrt(c.d) * exp(-1i * 2.0 * pi * orders * origin) .* coeff;
coeff = LOCAL_pad(coeff, ncommon);
end

function padded = LOCAL_pad(value, n)
old = size(value, 1);
if old == n, padded = value; return; end
padded = complex(zeros(n, size(value, 2)));
old_orders = (-old / 2.0:old / 2.0 - 1.0).';
new_orders = (-n / 2.0:n / 2.0 - 1.0).';
[present, indices] = ismember(old_orders, new_orders);
padded(indices(present), :) = value(present, :);
end

%% ==================== Factor associations ====================
% Complete 97-by-97 P matrices remain in every lead association.

function [maps, sample_maps] = LOCAL_wall_state_maps(raw_left, raw_right, c, n)
left = LOCAL_wall_coeff(raw_left, c, n);
right = LOCAL_wall_coeff(raw_right, c, n);
K = c.K;
embed = complex(zeros(n, K));
all_orders = (-n / 2.0:n / 2.0 - 1.0).';
retained = (-c.M:c.M).';
[present, indices] = ismember(retained, all_orders);
if ~all(present)
  error('I32V3:WallBandwidth', 'A retained wall trace mode is missing.');
end
embed(indices, :) = eye(K);
maps.left = [embed, complex(zeros(n, K))] - left;
maps.right = [complex(zeros(n, K)), embed] - right;
y = -c.d / 2.0 + c.d * ((0.0:size(raw_left, 1) - 1.0).' + 0.5) ...
  / size(raw_left, 1);
E = exp(1i * y * (c.beta + 2.0 * pi * retained / c.d).') / sqrt(c.d);
sample_maps.left = [E, complex(zeros(size(E)))] - raw_left;
sample_maps.right = [complex(zeros(size(E))), E] - raw_right;
end

function maps = LOCAL_wall_state_residual(state_maps, ~)
maps.left = state_maps.left;
maps.right = state_maps.right;
end

function maps = LOCAL_wall_prescribed_maps(c, n)
K = c.K;
embed = complex(zeros(n, K));
all_orders = (-n / 2.0:n / 2.0 - 1.0).';
[~, indices] = ismember((-c.M:c.M).', all_orders);
embed(indices, :) = eye(K);
maps.left = [embed, complex(zeros(n, K))];
maps.right = [complex(zeros(n, K)), embed];
end

function maps = LOCAL_wall_piece_state(piece, c, n, sign_value)
maps.left = sign_value * LOCAL_wall_coeff(piece.value_left, c, n);
maps.right = sign_value * LOCAL_wall_coeff(piece.value_right, c, n);
end

function samples = LOCAL_wall_value_samples(sample_maps, ~)
samples.left = sample_maps.left;
samples.right = sample_maps.right;
end

function singleton = LOCAL_wall_flux_singleton(QL, QR, c, n, weight)
center = c.center_wall_jumps;
dx_left = LOCAL_pad(center.center_left_global_dx, n);
dx_right = LOCAL_pad(center.center_right_global_dx, n);
left = (-dx_left + QR * c.Gminus * c.cminus) ./ sqrt(weight);
right = (dx_right + QL * c.Gplus * c.cplus) ./ sqrt(weight);
singleton = [left; right];
end

function factor = LOCAL_wall_volume_factor(maps, weight, c)
left_plus = weight .* (maps.left * c.Gplus);
right_plus = weight .* (maps.right * c.Gplus);
left_minus = weight .* (maps.left * c.Gminus);
right_minus = weight .* (maps.right * c.Gminus);
factor = struct('plus', [right_plus; left_plus * c.Pplus], ...
  'minus', [left_minus; right_minus * c.Pminus], ...
  'singleton', [left_plus * c.cplus; right_minus * c.cminus]);
end

function [normal_factors, value_factors] = LOCAL_circle_gqp_factors( ...
    piece, c, n, normal_weight, lift_weight)
names = fieldnames(piece);
normal_factors = cell(1, numel(names));
value_factors = cell(1, numel(names));
for j = 1:numel(names)
  name = names{j};
  normal_coeff = LOCAL_circle_coeff(piece.(name).normal, c.R, n) ...
    ./ sqrt(normal_weight);
  value_coeff = lift_weight .* ...
    LOCAL_circle_coeff(piece.(name).value, c.R, n);
  normal_factors{j} = struct('name', name, ...
    'plus', normal_coeff * c.Gplus, ...
    'minus', normal_coeff * c.Gminus, ...
    'singleton', complex(zeros(0, 1)));
  value_factors{j} = struct('name', ['circle_', name], ...
    'plus', value_coeff * c.Gplus, ...
    'minus', value_coeff * c.Gminus, ...
    'singleton', complex(zeros(0, 1)));
end
end

function [normal_factors, value_factors] = LOCAL_wall_gqp_factors( ...
    pieces, c, n, normal_weight, lift_weight)
names = fieldnames(pieces);
normal_factors = cell(1, numel(names));
value_factors = cell(1, 2.0 * numel(names));
for j = 1:numel(names)
  name = names{j};
  p = pieces.(name);
  ql = LOCAL_wall_coeff(p.flux_left, c, n) ./ sqrt(normal_weight);
  qr = LOCAL_wall_coeff(p.flux_right, c, n) ./ sqrt(normal_weight);
  normal_factors{j} = struct('name', name, ...
    'plus', qr * c.Gplus + ql * c.Gplus * c.Pplus, ...
    'minus', ql * c.Gminus + qr * c.Gminus * c.Pminus, ...
    'singleton', [qr * c.Gminus * c.cminus; ...
    ql * c.Gplus * c.cplus]);
  left_map = -LOCAL_wall_coeff(p.value_left, c, n);
  right_map = -LOCAL_wall_coeff(p.value_right, c, n);
  zero = complex(zeros(size(left_map)));
  left_factor = LOCAL_wall_volume_factor( ...
    struct('left', left_map, 'right', zero), lift_weight, c);
  left_factor.name = ['wall_', name, '_left'];
  right_factor = LOCAL_wall_volume_factor( ...
    struct('left', zero, 'right', right_map), lift_weight, c);
  right_factor.name = ['wall_', name, '_right'];
  value_factors{2.0 * j - 1.0} = left_factor;
  value_factors{2.0 * j} = right_factor;
end
end

function factors = LOCAL_circle_band_factors(prescribed, self_value, ...
    cross_value, total, c, n)
names = {'prescribed', 'self', 'cross', 'total'};
values = {prescribed, self_value, cross_value, total};
factors = struct();
for j = 1:numel(names)
  coeff = LOCAL_circle_coeff(values{j}, c.R, n);
  factors.(names{j}) = struct('plus', coeff * c.Gplus, ...
    'minus', coeff * c.Gminus);
end
end

function factors = LOCAL_wall_band_factors(prescribed, self_maps, ...
    opposite_maps, circle_maps, total_maps, c)
names = {'prescribed', 'self', 'opposite_cross', 'circle_cross', 'total'};
values = {prescribed, self_maps, opposite_maps, circle_maps, total_maps};
factors = struct();
for j = 1:numel(names)
  maps = values{j};
  factors.(names{j}) = struct('plus', ...
    [maps.left * c.Gplus; maps.right * c.Gplus], ...
    'minus', [maps.left * c.Gminus; maps.right * c.Gminus]);
end
end

%% ==================== Compact axes and bands ====================
% Raw coarse arrays die immediately after positive Grams and band sums form.

function factors = LOCAL_factors(actions, field)
factors = cell(1, numel(actions));
for j = 1:numel(actions)
  factors{j} = actions{j}.(field);
end
end

function axis = LOCAL_axis(factors)
K = size(factors{1}.plus, 2);
axis.level_plus_gram = complex(zeros(K, K, 3));
axis.level_minus_gram = complex(zeros(K, K, 3));
axis.singleton_squared = zeros(3, 1);
operation_count = 0.0;
for j = 1:3
  axis.level_plus_gram(:, :, j) = factors{j}.plus' * factors{j}.plus;
  axis.level_minus_gram(:, :, j) = factors{j}.minus' * factors{j}.minus;
  axis.singleton_squared(j) = real(factors{j}.singleton' * ...
    factors{j}.singleton);
  operation_count = operation_count + factors{j}.operation_count + ...
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
  operation_count = operation_count + ...
    (size(dp, 1) + size(dm, 1)) * K^2 + numel(ds);
end
axis.operation_count = operation_count;
end

function axis = LOCAL_circle_riccati(action, c, cfg)
factors = cell(1, 3);
for j = 1:3
  weight = LOCAL_circle_weight(c, size(action.normal_aligned_plus, 1), ...
    cfg.levels.riccati(j));
  factors{j} = struct('plus', action.normal_aligned_plus ./ sqrt(weight), ...
    'minus', action.normal_aligned_minus ./ sqrt(weight), ...
    'singleton', complex(zeros(0, 1)), ...
    'operation_count', action.operation_count);
end
axis = LOCAL_axis(factors);
axis.steps = cfg.levels.riccati;
end

function bands = LOCAL_band_levels(actions, cfg, family)
names = fieldnames(actions{1}.band_factors);
bands = struct('definitions', cfg.bands, 'family', family, ...
  'all_modes_enter_residual', true, 'cap_contribution', 0.0);
if strcmp(family, 'wall')
  target_counts = cfg.levels.wall_target;
else
  target_counts = cfg.levels.circle_target;
end
for k = 1:numel(names)
  name = names{k};
  energy = zeros(3, size(cfg.bands, 1));
  for level = 1:3
    factor = actions{level}.band_factors.(name);
    energy(level, :) = LOCAL_band_energy(factor, cfg.bands, family);
  end
  common_difference = zeros(1, 2);
  new_shell = zeros(1, 2);
  for level = 1:2
    lower = actions{level}.band_factors.(name);
    upper = actions{level + 1}.band_factors.(name);
    common_difference(level) = LOCAL_common_factor_difference( ...
      upper, lower, target_counts(level), family);
    new_shell(level) = LOCAL_new_shell_factor_norm( ...
      upper, target_counts(level), target_counts(level + 1), family);
  end
  bands.pieces.(name) = struct('level_energy', energy, ...
    'common_factor_difference', common_difference, ...
    'new_shell_factor_norm', new_shell, ...
    'difference_formula', 'norm(Pi_I_Nj*(F_jplus1-F_j))', ...
    'new_shell_formula', 'norm(Pi_(I_Njplus1_minus_I_Nj)*F_jplus1)', ...
    'energy_is_diagnostic_only', true);
end
end

function value = LOCAL_common_factor_difference(upper, lower, nkeep, family)
difference = struct('plus', upper.plus - lower.plus, ...
  'minus', upper.minus - lower.minus);
ncommon = LOCAL_family_rows(difference, family);
orders = (-ncommon / 2.0:ncommon / 2.0 - 1.0).';
mask = orders >= -nkeep / 2.0 & orders <= nkeep / 2.0 - 1.0;
value = LOCAL_factor_mask_norm(difference, mask, family);
end

function value = LOCAL_new_shell_factor_norm(upper, nlower, nupper, family)
ncommon = LOCAL_family_rows(upper, family);
orders = (-ncommon / 2.0:ncommon / 2.0 - 1.0).';
lower_mask = orders >= -nlower / 2.0 & orders <= nlower / 2.0 - 1.0;
upper_mask = orders >= -nupper / 2.0 & orders <= nupper / 2.0 - 1.0;
value = LOCAL_factor_mask_norm(upper, upper_mask & ~lower_mask, family);
end

function rows = LOCAL_family_rows(factor, family)
rows = size(factor.plus, 1);
if strcmp(family, 'wall')
  rows = rows / 2.0;
end
end

function value = LOCAL_factor_mask_norm(factor, mask, family)
n = numel(mask);
squared = 0.0;
if strcmp(family, 'wall')
  blocks = {1.0:n, n + (1.0:n)};
else
  blocks = {1.0:n};
end
for j = 1:numel(blocks)
  ids = blocks{j}(mask);
  squared = squared + norm(factor.plus(ids, :), 'fro')^2 + ...
    norm(factor.minus(ids, :), 'fro')^2;
end
value = sqrt(squared);
end

function energy = LOCAL_band_energy(factor, definitions, family)
rows = size(factor.plus, 1);
if strcmp(family, 'wall')
  n = rows / 2.0;
  plus_blocks = {factor.plus(1:n, :), factor.plus(n + 1:end, :)};
  minus_blocks = {factor.minus(1:n, :), factor.minus(n + 1:end, :)};
else
  n = rows;
  plus_blocks = {factor.plus};
  minus_blocks = {factor.minus};
end
orders = abs((-n / 2.0:n / 2.0 - 1.0).');
energy = zeros(1, size(definitions, 1));
for j = 1:size(definitions, 1)
  mask = orders >= definitions(j, 1) & orders <= definitions(j, 2);
  for k = 1:numel(plus_blocks)
    energy(j) = energy(j) + norm(plus_blocks{k}(mask, :), 'fro')^2;
  end
  for k = 1:numel(minus_blocks)
    energy(j) = energy(j) + norm(minus_blocks{k}(mask, :), 'fro')^2;
  end
end
end

function value = LOCAL_factor_fro(factor)
value = sqrt(norm(factor.plus, 'fro')^2 + ...
  norm(factor.minus, 'fro')^2 + norm(factor.singleton)^2);
end

function names = LOCAL_piece_names(factors)
names = cell(1, numel(factors));
for j = 1:numel(factors), names{j} = factors{j}.name; end
end

%% ==================== Boundary weights ====================
% Trace weights remain positive or the required norm is unavailable.

function weight = LOCAL_wall_weight(c, n)
orders = (-n / 2.0:n / 2.0 - 1.0).';
beta = c.beta + 2.0 * pi * orders / c.d;
kappa = sqrt(beta.^2 + c.gamma);
weight = 2.0 * kappa .* tanh(kappa / 2.0);
if any(~isfinite(weight) | weight <= 0.0)
  error('I32V3:WallWeight', 'A wall trace weight is invalid.');
end
end

function weight = LOCAL_circle_weight(c, n, steps)
orders = (-n / 2.0:n / 2.0 - 1.0).';
tin = log(c.R - c.delta_c);
t0 = log(c.R);
tout = log(c.R + c.delta_c);
pin = LOCAL_rk4(zeros(size(orders)), tin, t0, steps, orders, ...
  c.gamma * c.rho_disk);
pout = LOCAL_rk4(zeros(size(orders)), tout, t0, steps, orders, c.gamma);
weight = (pin - pout) / c.R;
if any(~isfinite(weight) | weight <= 0.0)
  error('I32V3:CircleWeight', 'A circle trace weight is invalid.');
end
end

function p = LOCAL_rk4(p, t0, t1, steps, orders, alpha)
h = (t1 - t0) / steps;
t = t0;
for j = 1:steps
  k1 = orders.^2 + alpha * exp(2.0 * t) - p.^2;
  q = p + h * k1 / 2.0;
  k2 = orders.^2 + alpha * exp(2.0 * (t + h / 2.0)) - q.^2;
  q = p + h * k2 / 2.0;
  k3 = orders.^2 + alpha * exp(2.0 * (t + h / 2.0)) - q.^2;
  q = p + h * k3;
  k4 = orders.^2 + alpha * exp(2.0 * (t + h)) - q.^2;
  p = p + h * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
  t = t + h;
end
end

%% ==================== Small structures and contracts ====================
% Dense incomplete arrays are never placed in a blocked return.

function piece = LOCAL_circle_piece_empty(nt, states)
zero = complex(zeros(nt, states));
entry = struct('value', zero, 'normal', zero);
piece = struct('circle_double', entry, 'circle_single', entry, ...
  'wall_left', entry, 'wall_right', entry);
end

function pieces = LOCAL_wall_piece_empty(nt, states)
zero = complex(zeros(nt, states));
entry = struct('value_left', zero, 'value_right', zero, ...
  'flux_left', zero, 'flux_right', zero);
pieces = struct('wall_self', entry, 'wall_other', entry, ...
  'circle_double', entry, 'circle_single', entry);
end

function diagnostics = LOCAL_wall_value_diagnostic_empty(nt, states)
zero = complex(zeros(nt, states));
entry = struct('value_left', zero, 'value_right', zero);
diagnostics = struct('self', entry, 'opposite_cross', entry, ...
  'circle_cross', entry);
end

function audit = LOCAL_map_audit(maps)
audit = struct('left_size', size(maps.left), ...
  'right_size', size(maps.right), ...
  'left_fro', norm(maps.left, 'fro'), ...
  'right_fro', norm(maps.right, 'fro'), ...
  'common_finest_coefficient_grid', true);
end

function LOCAL_validate(c, gqp, cfg, resource)
required = {'khat', 'mu_h', 'gamma', 'beta', 'd', 'R', 'rho_disk', ...
  'M', 'K', 'delta_c', 'delta_w', 'X_L', 'X_R', 'Gplus', ...
  'Gminus', 'Pplus', 'Pminus', 'cplus', 'cminus', ...
  'eta_unit_256', 'xi_left_unit_512', 'xi_right_unit_512', ...
  'center_wall_jumps'};
if ~isstruct(c) || ~all(isfield(c, required)) || ...
    ~isstruct(gqp) || ~isfield(gqp, 'available') || ~gqp.available || ...
    ~isfield(gqp, 'private') || ~isstruct(cfg) || ...
    ~isstruct(resource) || ~all(isfield(resource, ...
    {'start_tic', 'hard_s', 'memory_mib_max'}))
  error('I32V3:BoundaryInterface', 'Boundary inputs are incomplete.');
end
if ~isequal(cfg.levels.circle_source, [512.0, 1024.0, 2048.0]) || ...
    ~isequal(cfg.levels.wall_source, [1024.0, 2048.0, 4096.0])
  error('I32V3:BoundaryLevels', 'Frozen source/target levels drifted.');
end
end

function LOCAL_resource(resource, local_mib)
if toc(resource.start_tic) > resource.hard_s
  error('I32V3:HARD_TIME_LIMIT', 'The hard boundary time gate was reached.');
end
publication = 64.0;
retained = 0.0;
if isfield(resource, 'publication_mib'), publication = resource.publication_mib; end
if isfield(resource, 'retained_mib'), retained = resource.retained_mib; end
if retained + local_mib + publication > resource.memory_mib_max
  error('I32V3:HARD_MEMORY_LIMIT', 'The hard boundary memory gate was reached.');
end
end

function mib = LOCAL_workspace_mib()
items = whos;
mib = sum([items.bytes]) / 2^20;
end

function out = LOCAL_empty()
out = struct('schema', 'I32V3_BOUNDARY_V1', 'status', 'INITIALIZED', ...
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
