function out = i32v4_boundary_sequence(c, cfg, resource)
%I32V4_BOUNDARY_SEQUENCE Evaluate four coupled all-boundary residual levels.
% Purpose:
%   Evaluate the same frozen all-boundary layer-potential trial at the four
%   registered coupled circle/wall levels.  Each level executes one circle
%   action and one wall action and returns both normal and value defects.
% Input:
%   c        - Double-valued frozen fbie-a1 certificate.
%   cfg      - Frozen e-cap-v4 configuration from check_e_cap_v4.
%   resource - Shared 1800 s / 2048 MiB hard resource gate.
% Output:
%   out.private.levels - Four level records containing weighted wall/circle
%                        normal factors and total value coefficient maps.
%   out.private.gqp    - Finest unique GQP-only normal factors and value maps.
%   out.data           - Compact level, MFS, action, quadrature, and memory
%                        diagnostics; no fixed MFS table is returned.
% Main algorithm:
%   Build one fixed 2049-by-2049 six-field MFS remainder table, prolong only
%   the frozen finite densities, execute one coupled source=target action per
%   level with streamed Kress/self/cross products, transform total defects to
%   Fourier coordinates, and release the table after the finest action.
% Based on:
%   design-3-2e Sections 3--5.  The boundary formulas are a direct v4
%   translation of the reviewed v3 mathematical action; no old experiment
%   function is called.
% Numerical goal:
%   Supply the four scalar-sequence inputs without separate source/target
%   axes and preserve every finest unique smooth-remainder GQP piece.

timer = tic;
out = LOCAL_empty();
progress = struct('stage', 'entry', 'gqp_table_panels', 0.0, ...
  'logical_coupled_actions', 0.0, 'physical_circle_actions', 0.0, ...
  'physical_wall_actions', 0.0, 'completed_levels', 0.0, ...
  'completed_target_rows', 0.0, 'local_peak_mib', 0.0, ...
  'complete', false);
levels = cell(1, 4);
level_metrics = repmat(LOCAL_level_metric_empty(), 1, 4);
try
  LOCAL_validate(c, cfg, resource);

  % --- stage 1: one fixed MFS smooth-remainder table ---
  progress.stage = 'fixed MFS table';
  gqp = LOCAL_gqp_build(c, cfg, resource);
  out.data.gqp = gqp.data;
  progress.gqp_table_panels = gqp.audit.progress.completed_table_panels;
  progress.local_peak_mib = max(progress.local_peak_mib, ...
    gqp.memory.local_peak_mib);
  if ~gqp.available
    error(gqp.first_blocker, '%s', gqp.audit.exception_message);
  end

  % --- stage 2: four coupled source=target boundary actions ---
  progress.stage = 'coupled boundary levels';
  for level_index = 1:4
    n_circle = cfg.levels.circle(level_index);
    n_wall = cfg.levels.wall(level_index);
    collect_gqp = level_index == 4;
    circle = LOCAL_circle_action(c, gqp, cfg, resource, ...
      n_circle, n_wall, collect_gqp);
    progress.physical_circle_actions = ...
      progress.physical_circle_actions + 1.0;
    wall = LOCAL_wall_action(c, gqp, cfg, resource, ...
      n_wall, n_circle, collect_gqp);
    progress.physical_wall_actions = progress.physical_wall_actions + 1.0;
    progress.logical_coupled_actions = ...
      progress.logical_coupled_actions + 1.0;

    level = struct('N_circle', n_circle, 'N_wall', n_wall, ...
      'wall_normal_factor', wall.normal_factor, ...
      'circle_normal_factor', circle.normal_factor, ...
      'circle_value_map', circle.value_map, ...
      'wall_left_value_map', wall.left_value_map, ...
      'wall_right_value_map', wall.right_value_map, ...
      'operation_count', circle.operation_count + wall.operation_count);
    LOCAL_assert_level_finite(level);
    levels{level_index} = level;
    level_metrics(level_index) = LOCAL_level_metric(circle, wall, level);
    if collect_gqp
      finest_gqp = struct( ...
        'wall_normal_factors', {wall.gqp_normal_factors}, ...
        'circle_normal_factors', {circle.gqp_normal_factors}, ...
        'circle_value_maps', {circle.gqp_value_maps}, ...
        'wall_value_maps', {wall.gqp_value_maps});
      LOCAL_assert_gqp_finite(finest_gqp);
      out.private.gqp = finest_gqp;
    end
    out.private.levels = levels(1:level_index);
    out.data.level_metrics = level_metrics(1:level_index);
    progress.completed_levels = level_index;
    progress.completed_target_rows = progress.completed_target_rows + ...
      n_circle + 2.0 * n_wall;
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      LOCAL_caller_workspace_mib());
    LOCAL_resource(resource, progress.local_peak_mib);
    clear circle wall level
  end

  % The MFS table has no consumer after the finest coupled action.
  clear gqp
  out.private.levels = levels;
  out.data.level_metrics = level_metrics;
  out.data.levels = struct('circle', cfg.levels.circle, ...
    'wall', cfg.levels.wall, 'coupled_ratio', 2.0);
  out.data.action_counts = struct('logical_coupled', 4.0, ...
    'physical_circle', 4.0, 'physical_wall', 4.0, ...
    'physical_total', 8.0, 'separate_source_axes', 0.0, ...
    'separate_target_axes', 0.0);
  out.data.gqp_piece_ledger = struct( ...
    'wall_normal', {LOCAL_names(out.private.gqp.wall_normal_factors)}, ...
    'circle_normal', {LOCAL_names(out.private.gqp.circle_normal_factors)}, ...
    'circle_value', {LOCAL_names(out.private.gqp.circle_value_maps)}, ...
    'wall_value', {LOCAL_names(out.private.gqp.wall_value_maps)}, ...
    'unique_pieces_counted_once', true, ...
    'physical_total_added_again', false);
  out.audit.fixed_trial = true;
  out.audit.density_resolve_count = 0.0;
  out.audit.density_refinement = ...
    'same frozen finite trigonometric interpolants at every level';
  out.audit.circle_self_quadrature = ...
    'streamed Kress S,D,Dstar,T_out-T_in with explicit jumps';
  out.audit.wall_self_quadrature = ...
    'streamed periodic-gauge Kress split with explicit +1/2 jump';
  out.audit.fixed_mfs_gateway_embedded = true;
  out.audit.image_sum_code_path_zero = true;
  out.audit.rayleigh_field_code_path_zero = true;
  out.audit.M_role = 'artificial-wall total Dirichlet trace order only';
  out.counters = struct('density_solves', 0.0, ...
    'logical_coupled_actions', 4.0, 'physical_circle_actions', 4.0, ...
    'physical_wall_actions', 4.0, 'precomp_proxy_calls', 1.0, ...
    'image_sum_calls', 0.0, 'rayleigh_field_calls', 0.0, ...
    'old_experiment_helper_calls', 0.0);
  if any([level_metrics.circle_recombination] > ...
      cfg.threshold.recombination) || ...
      any([level_metrics.wall_recombination] > ...
      cfg.threshold.recombination) || ...
      any([level_metrics.wall_self_split_recombination] > ...
      cfg.threshold.recombination)
    out.warnings{end + 1} = 'BOUNDARY_RECOMBINATION_WARNING';
  end
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
  clear gqp
end
out.audit.progress = progress;
info = whos('out');
out.memory = struct('local_peak_mib', max(progress.local_peak_mib, ...
  info.bytes / 2^20), 'retained_mib', info.bytes / 2^20, ...
  'largest_object', 'four level value coefficient maps and finest GQP pieces', ...
  'os_rss_measured', false, 'cleared_objects', ...
  {{'fixed MFS table after finest action', ...
  'physical source/target panels after each streamed product'}});
out.audit.elapsed_s = toc(timer);
end

%% ==================== Fixed MFS gateway ====================
% The flat table and pair evaluator are the only v4 G_QP execution path.

function gqp = LOCAL_gqp_build(c, cfg, resource)
timer = tic;
gqp = struct('schema', 'I32V4_GQP_INTERNAL_V1', 'status', 'INITIALIZED', ...
  'available', false, 'first_blocker', '', 'data', struct(), ...
  'private', struct(), 'audit', struct(), 'memory', struct());
progress = struct('stage', 'entry', 'completed_proxy_builds', 0.0, ...
  'completed_table_panels', 0.0, 'completed_table_rows', 0.0, ...
  'local_peak_mib', 0.0, 'complete', false);
try
  if isempty(which('lsqminnorm'))
    error('I32V4:LSQMINNORMUnavailable', ...
      'Normal MATLAB resolution did not find lsqminnorm.');
  end
  pars = struct('d', c.d, 'beta', c.beta, 'k', c.khat);
  spec = struct('H', cfg.gqp.H, 'proxy_dist', cfg.gqp.proxy_distance, ...
    'N_side', cfg.gqp.Nside, 'N_top', cfg.gqp.Ntop, ...
    'N_proxy_edge', cfg.gqp.Nedge, 'M_pw', cfg.gqp.Mpw);
  progress.stage = 'proxy';
  LOCAL_resource(resource, LOCAL_proxy_mib(cfg));
  proxy = kernel.precomp_proxy(pars, spec);
  progress.completed_proxy_builds = 1.0;
  if any(~isfinite([proxy.q(:); proxy.Z(:); ...
      proxy.C_up(:); proxy.C_down(:)]))
    error('I32V4:MFSProxyNonfinite', 'The fixed MFS proxy is nonfinite.');
  end

  n = cfg.gqp.table_n;
  xgrid = linspace(cfg.gqp.table_x_bounds(1), ...
    cfg.gqp.table_x_bounds(2), n);
  ygrid = linspace(cfg.gqp.table_y_bounds(1), ...
    cfg.gqp.table_y_bounds(2), n);
  count = n * n;
  table = complex(zeros(count, 6));
  progress.stage = 'table';
  for first = 1.0:cfg.gqp.table_panel:count
    last = min(count, first + cfg.gqp.table_panel - 1.0);
    ids = first:last;
    [iy, ix] = ind2sub([n, n], ids);
    points = [xgrid(ix); ygrid(iy)];
    [pot, grad, hess] = kernel.h2d_directch(c.khat, ...
      proxy.Z, proxy.q, points);
    table(ids, :) = [pot(:), grad.', hess.'];
    progress.completed_table_panels = ...
      progress.completed_table_panels + 1.0;
    progress.completed_table_rows = last;
    probe = whos('table', 'points', 'pot', 'grad', 'hess', 'proxy');
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      sum([probe.bytes]) / 2^20);
    LOCAL_resource(resource, progress.local_peak_mib);
  end
  clear points pot grad hess proxy
  gqp.private = struct('table', table, 'xgrid', xgrid, ...
    'ygrid', ygrid, 'd', c.d, 'beta', c.beta, 'k', c.khat);
  gqp.data = struct('table_n', n, 'field_count', 6.0, ...
    'table_storage', 'n^2-by-6 flat', ...
    'relative_uncertainty', cfg.gqp.relative_uncertainty, ...
    'parameters', spec, ...
    'spot_qualification_executed', false);
  gqp.available = true;
  gqp.status = 'COMPLETE';
  progress.stage = 'complete';
  progress.complete = true;
catch err
  gqp.status = 'BLOCKED';
  gqp.first_blocker = LOCAL_identifier(err);
  gqp.audit.exception_message = err.message;
  progress.stage = 'blocked';
  clear table proxy points pot grad hess
end
gqp.audit.progress = progress;
gqp.audit.image_sum_code_path_zero = true;
gqp.audit.fixed_single_proxy = true;
gqp.audit.fixed_single_table = true;
info = whos('gqp');
gqp.memory = struct('local_peak_mib', max(progress.local_peak_mib, ...
  info.bytes / 2^20), 'retained_mib', info.bytes / 2^20);
gqp.audit.elapsed_s = toc(timer);
end

function [pot, gx, gy, hxx, hxy, hyy, audit, ...
    remainder_pot, remainder_gx, remainder_gy, ...
    remainder_hxx, remainder_hxy, remainder_hyy] = ...
    LOCAL_gqp_pair(gqp, src, trg, include_primary)
if ~isstruct(gqp) || ~isfield(gqp, 'available') || ~gqp.available || ...
    ~isfield(gqp, 'private') || size(src, 1) ~= 2 || ...
    size(trg, 1) ~= 2 || isempty(src) || isempty(trg) || ...
    any(~isfinite([src(:); trg(:)]))
  error('I32V4:GQPPairInterface', 'Invalid fixed-MFS pair request.');
end
d = gqp.private.d;
dx = trg(1, :).'-src(1, :);
dy = trg(2, :).'-src(2, :);
shift = round(dy / d);
xquery = dy - shift * d;
yquery = dx;
[values, interpolation_count] = ...
  LOCAL_gqp_interp(gqp.private, xquery, yquery);
phase = exp(1i * gqp.private.beta * d * shift(:));
values = values .* phase;
nt = size(trg, 2);
ns = size(src, 2);
pot = reshape(values(:, 1), nt, ns);
gx = reshape(values(:, 3), nt, ns);
gy = reshape(values(:, 2), nt, ns);
hxx = reshape(values(:, 6), nt, ns);
hxy = reshape(values(:, 5), nt, ns);
hyy = reshape(values(:, 4), nt, ns);
remainder_pot = pot;
remainder_gx = gx;
remainder_gy = gy;
remainder_hxx = hxx;
remainder_hxy = hxy;
remainder_hyy = hyy;
primary_calls = 0.0;
if logical(include_primary)
  points = [xquery(:).'; yquery(:).'];
  if any(sum(abs(points).^2, 1) == 0.0)
    error('I32V4:GQPSingularPrimary', ...
      'A complete-kernel request contains a coincidence.');
  end
  [p0, g0, h0] = kernel.h2d_directch(gqp.private.k, ...
    [0.0; 0.0], 1.0, points);
  p0 = p0(:) .* phase;
  g0 = g0 .* phase.';
  h0 = h0 .* phase.';
  pot = pot + reshape(p0, nt, ns);
  gx = gx + reshape(g0(2, :), nt, ns);
  gy = gy + reshape(g0(1, :), nt, ns);
  hxx = hxx + reshape(h0(3, :), nt, ns);
  hxy = hxy + reshape(h0(2, :), nt, ns);
  hyy = hyy + reshape(h0(1, :), nt, ns);
  primary_calls = 1.0;
end
audit = struct('pair_count', nt * ns, ...
  'interpolation_cma', interpolation_count, ...
  'bloch_phase_multiply_count', 6.0 * nt * ns, ...
  'analytic_primary_call_count', primary_calls, ...
  'image_sum_calls', 0.0, 'rayleigh_field_calls', 0.0, ...
  'finite', all(isfinite([pot(:); gx(:); gy(:); hxx(:); ...
  hxy(:); hyy(:)])));
end

function [values, operations] = LOCAL_gqp_interp(private, xquery, yquery)
x = private.xgrid;
y = private.ygrid;
table = private.table;
xquery = xquery(:);
yquery = yquery(:);
tol = 256.0 * eps(max([1.0, abs(x), abs(y)]));
if any(xquery < x(1) - tol | xquery > x(end) + tol | ...
    yquery < y(1) - tol | yquery > y(end) + tol)
  error('I32V4:GQPInterpolationDomain', ...
    'A folded interpolation query lies outside the fixed table.');
end
xquery = min(max(xquery, x(1)), x(end));
yquery = min(max(yquery, y(1)), y(end));
hx = x(2) - x(1);
hy = y(2) - y(1);
ix = min(max(floor((xquery - x(1)) / hx) - 1.0, 0.0), ...
  numel(x) - 4.0) + 1.0;
iy = min(max(floor((yquery - y(1)) / hy) - 1.0, 0.0), ...
  numel(y) - 4.0) + 1.0;
wx = LOCAL_cubic_weights(xquery, x, ix);
wy = LOCAL_cubic_weights(yquery, y, iy);
nq = numel(xquery);
values = complex(zeros(nq, 6));
ny = numel(y);
for row = 0.0:3.0
  for column = 0.0:3.0
    linear = (iy + row) + (ix + column - 1.0) * ny;
    weight = wy(:, row + 1.0) .* wx(:, column + 1.0);
    values = values + weight .* table(linear, :);
  end
end
operations = 31.0 * nq * 6.0;
end

function weights = LOCAL_cubic_weights(query, grid, first)
count = numel(query);
nodes = zeros(count, 4);
for j = 1.0:4.0
  nodes(:, j) = grid(first + j - 1.0);
end
weights = ones(count, 4);
for j = 1.0:4.0
  for k = 1.0:4.0
    if k ~= j
      weights(:, j) = weights(:, j) .* ...
        (query - nodes(:, k)) ./ (nodes(:, j) - nodes(:, k));
    end
  end
end
end

%% ==================== Coupled circle action ====================
% The same source=target action returns normal and value defects together.

function action = LOCAL_circle_action(c, gqp, cfg, resource, ...
    n_circle, n_wall, collect_gqp)
[tau, zeta, tau_s, theta] = LOCAL_circle_density(c, n_circle);
src = c.R * [cos(theta).'; sin(theta).'];
trg = src;
nsn = [cos(theta).'; sin(theta).'];
ntn = nsn;
state_count = size(tau, 2);
value = tau;
normal = zeta;
prescribed = tau;
self_value = complex(zeros(n_circle, state_count));
cross_value = complex(zeros(n_circle, state_count));
if collect_gqp
  piece = LOCAL_circle_piece_empty(n_circle, state_count);
else
  piece = struct();
end
operation_count = 0.0;
for first = 1.0:cfg.panel.target_max:n_circle
  last = min(n_circle, first + cfg.panel.target_max - 1.0);
  target_ids = first:last;
  value_free = complex(zeros(numel(target_ids), state_count));
  normal_free = value_free;
  for source_first = 1.0:cfg.panel.source_max:n_circle
    source_last = min(n_circle, ...
      source_first + cfg.panel.source_max - 1.0);
    source_ids = source_first:source_last;
    weights = LOCAL_rect_kress(theta(source_ids), theta(target_ids), ...
      n_circle, source_ids);
    [vf, nf] = LOCAL_circle_free(c.khat, ...
      c.khat * sqrt(c.rho_disk), c.R, theta(source_ids), ...
      theta(target_ids), weights, tau(source_ids, :), ...
      zeta(source_ids, :), tau_s(source_ids, :), n_circle);
    value_free = value_free + vf;
    normal_free = normal_free + nf;
    operation_count = operation_count + ...
      10.0 * numel(target_ids) * numel(source_ids) * state_count;
  end
  [value_proxy, normal_proxy, proxy_piece, proxy_ops] = ...
    LOCAL_circle_proxy(gqp, src, trg(:, target_ids), nsn, ...
    ntn(:, target_ids), tau, zeta, 2.0 * pi * c.R / n_circle, ...
    cfg.panel.source_max, collect_gqp);
  [value_wall, normal_wall, wall_piece, wall_ops] = ...
    LOCAL_walls_to_circle(c, gqp, trg(:, target_ids), ...
    ntn(:, target_ids), n_wall, cfg.panel.source_max, collect_gqp);
  self_panel = value_free + value_proxy;
  value(target_ids, :) = value(target_ids, :) + ...
    self_panel + value_wall;
  normal(target_ids, :) = normal(target_ids, :) + ...
    normal_free + normal_proxy + normal_wall;
  self_value(target_ids, :) = self_panel;
  cross_value(target_ids, :) = value_wall;
  if collect_gqp
    piece.circle_double.value(target_ids, :) = proxy_piece.value_double;
    piece.circle_double.normal(target_ids, :) = proxy_piece.normal_double;
    piece.circle_single.value(target_ids, :) = proxy_piece.value_single;
    piece.circle_single.normal(target_ids, :) = proxy_piece.normal_single;
    piece.wall_left.value(target_ids, :) = wall_piece.left.value;
    piece.wall_left.normal(target_ids, :) = wall_piece.left.normal;
    piece.wall_right.value(target_ids, :) = wall_piece.right.value;
    piece.wall_right.normal(target_ids, :) = wall_piece.right.normal;
  end
  operation_count = operation_count + proxy_ops + wall_ops;
  LOCAL_resource(resource, LOCAL_caller_workspace_mib());
end
recombined = prescribed + self_value + cross_value;
recombination = norm(value - recombined, 'fro') / ...
  max(norm(value, 'fro'), realmin);
value_map = LOCAL_circle_coeff(value, c.R);
normal_coeff = LOCAL_circle_coeff(normal, c.R);
normal_weight = LOCAL_circle_normal_weight(c, n_circle, ...
  cfg.normal.circle_riccati_steps);
normal_weighted = normal_coeff ./ sqrt(normal_weight);
normal_factor = struct('plus', normal_weighted * c.Gplus, ...
  'minus', normal_weighted * c.Gminus, ...
  'singleton', complex(zeros(0, 1)), ...
  'operation_count', operation_count, ...
  'trace_weight_kind', 'frozen inner/outer Riccati dual weight');
action = struct('normal_factor', normal_factor, ...
  'value_map', value_map, 'recombination_defect', recombination, ...
  'piece_norms', struct('prescribed', norm(prescribed, 'fro'), ...
  'self', norm(self_value, 'fro'), 'cross', norm(cross_value, 'fro'), ...
  'total', norm(value, 'fro')), 'operation_count', operation_count);
if collect_gqp
  [action.gqp_normal_factors, action.gqp_value_maps] = ...
    LOCAL_circle_gqp_outputs(piece, c, normal_weight);
end
end

function [value, normal, piece, operations] = LOCAL_circle_proxy( ...
    gqp, src, trg, nsn, ntn, tau, zeta, ds, source_panel, collect)
nt = size(trg, 2);
state_count = size(tau, 2);
value = complex(zeros(nt, state_count));
normal = value;
if collect
  piece = struct('value_double', value, 'value_single', value, ...
    'normal_double', value, 'normal_single', value);
else
  piece = struct();
end
operations = 0.0;
for first = 1.0:source_panel:size(src, 2)
  last = min(size(src, 2), first + source_panel - 1.0);
  ids = first:last;
  [p, gx, gy, hxx, hxy, hyy, audit] = ...
    LOCAL_gqp_pair(gqp, src(:, ids), trg, false);
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
  if collect
    piece.value_double = piece.value_double + vd;
    piece.value_single = piece.value_single + vs;
    piece.normal_double = piece.normal_double + nd;
    piece.normal_single = piece.normal_single + ns;
  end
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    4.0 * nt * numel(ids) * state_count;
end
end

function [value, normal, piece, operations] = LOCAL_walls_to_circle( ...
    c, gqp, trg, ntn, n_wall, source_panel, collect)
[xi_left, y, ds] = LOCAL_wall_density(c.xi_left_unit_512, c, n_wall);
[xi_right, ~, ~] = LOCAL_wall_density(c.xi_right_unit_512, c, n_wall);
nt = size(trg, 2);
state_count = size(xi_left, 2);
value = complex(zeros(nt, state_count));
normal = value;
if collect
  piece.left = struct('value', value, 'normal', value);
  piece.right = struct('value', value, 'normal', value);
else
  piece = struct();
end
operations = 0.0;
for side_index = 1:2
  if side_index == 1
    xwall = c.X_L;
    density = xi_left;
    side_name = 'left';
  else
    xwall = c.X_R;
    density = xi_right;
    side_name = 'right';
  end
  src = [xwall * ones(1, n_wall); y.'];
  for first = 1.0:source_panel:n_wall
    last = min(n_wall, first + source_panel - 1.0);
    ids = first:last;
    [p, gx, gy, ~, ~, ~, audit, rp, rgx, rgy] = ...
      LOCAL_gqp_pair(gqp, src(:, ids), trg, true);
    v = ds * p * density(ids, :);
    nk = gx .* ntn(1, :).' + gy .* ntn(2, :).';
    q = ds * nk * density(ids, :);
    value = value + v;
    normal = normal + q;
    if collect
      rv = ds * rp * density(ids, :);
      rnk = rgx .* ntn(1, :).' + rgy .* ntn(2, :).';
      rq = ds * rnk * density(ids, :);
      piece.(side_name).value = piece.(side_name).value + rv;
      piece.(side_name).normal = piece.(side_name).normal + rq;
    end
    operations = operations + audit.interpolation_cma + ...
      audit.bloch_phase_multiply_count + ...
      2.0 * nt * numel(ids) * state_count;
  end
end
end

%% ==================== Coupled wall action ====================
% Both artificial walls share the same frozen trace and are evaluated once.

function action = LOCAL_wall_action(c, gqp, cfg, resource, ...
    n_wall, n_circle, collect_gqp)
y_target = -c.d / 2.0 + c.d * ...
  ((0.0:n_wall - 1.0).' + 0.5) / n_wall;
[xi_left, y_source, ~] = ...
  LOCAL_wall_density(c.xi_left_unit_512, c, n_wall);
[xi_right, ~, ~] = ...
  LOCAL_wall_density(c.xi_right_unit_512, c, n_wall);
state_count = size(xi_left, 2);
raw_left = complex(zeros(n_wall, state_count));
raw_right = raw_left;
flux_left = raw_left;
flux_right = raw_left;
if collect_gqp
  pieces = LOCAL_wall_piece_empty(n_wall, state_count);
else
  pieces = struct();
end
diagnostics = LOCAL_wall_diagnostic_empty(n_wall, state_count);
self_split = 0.0;
operation_count = 0.0;
for first = 1.0:cfg.panel.target_max:n_wall
  last = min(n_wall, first + cfg.panel.target_max - 1.0);
  ids = first:last;
  [raw_left(ids, :), flux_left(ids, :), left_piece, ...
    left_diagnostic, split_left, ops_left] = ...
    LOCAL_wall_side(c, gqp, cfg, y_source, y_target(ids), ...
    xi_left, xi_right, n_circle, -1.0, collect_gqp);
  [raw_right(ids, :), flux_right(ids, :), right_piece, ...
    right_diagnostic, split_right, ops_right] = ...
    LOCAL_wall_side(c, gqp, cfg, y_source, y_target(ids), ...
    xi_left, xi_right, n_circle, 1.0, collect_gqp);
  self_split = max([self_split, split_left, split_right]);
  if collect_gqp
    names = fieldnames(pieces);
    for piece_index = 1:numel(names)
      name = names{piece_index};
      pieces.(name).value_left(ids, :) = left_piece.(name).value;
      pieces.(name).flux_left(ids, :) = left_piece.(name).flux;
      pieces.(name).value_right(ids, :) = right_piece.(name).value;
      pieces.(name).flux_right(ids, :) = right_piece.(name).flux;
    end
  end
  diagnostic_names = fieldnames(diagnostics);
  for diagnostic_index = 1:numel(diagnostic_names)
    name = diagnostic_names{diagnostic_index};
    diagnostics.(name).value_left(ids, :) = left_diagnostic.(name);
    diagnostics.(name).value_right(ids, :) = right_diagnostic.(name);
  end
  operation_count = operation_count + ops_left + ops_right;
  LOCAL_resource(resource, LOCAL_caller_workspace_mib());
end

state_maps = LOCAL_wall_state_maps(raw_left, raw_right, c);
normal_weight = LOCAL_wall_normal_weight(c, n_wall);
QL_raw = LOCAL_wall_coeff(flux_left, c);
QR_raw = LOCAL_wall_coeff(flux_right, c);
QL = QL_raw ./ sqrt(normal_weight);
QR = QR_raw ./ sqrt(normal_weight);
normal_factor = struct( ...
  'plus', QR * c.Gplus + QL * c.Gplus * c.Pplus, ...
  'minus', QL * c.Gminus + QR * c.Gminus * c.Pminus, ...
  'singleton', LOCAL_wall_flux_singleton( ...
  QL_raw, QR_raw, c, n_wall, normal_weight), ...
  'operation_count', operation_count, ...
  'trace_weight_kind', '2*kappa*tanh(kappa/2)');

prescribed_maps = LOCAL_wall_prescribed_maps(c, n_wall);
self_maps = LOCAL_wall_piece_residual(diagnostics.self, c, -1.0);
opposite_maps = LOCAL_wall_piece_residual( ...
  diagnostics.opposite_cross, c, -1.0);
circle_maps = LOCAL_wall_piece_residual( ...
  diagnostics.circle_cross, c, -1.0);
recombined_left = prescribed_maps.left + self_maps.left + ...
  opposite_maps.left + circle_maps.left;
recombined_right = prescribed_maps.right + self_maps.right + ...
  opposite_maps.right + circle_maps.right;
recombination = norm([state_maps.left - recombined_left; ...
  state_maps.right - recombined_right], 'fro') / ...
  max(norm([state_maps.left; state_maps.right], 'fro'), realmin);
action = struct('normal_factor', normal_factor, ...
  'left_value_map', state_maps.left, ...
  'right_value_map', state_maps.right, ...
  'recombination_defect', recombination, ...
  'self_split_recombination', self_split, ...
  'piece_norms', struct('prescribed', ...
  norm([prescribed_maps.left; prescribed_maps.right], 'fro'), ...
  'self', norm([self_maps.left; self_maps.right], 'fro'), ...
  'opposite_cross', norm([opposite_maps.left; opposite_maps.right], 'fro'), ...
  'circle_cross', norm([circle_maps.left; circle_maps.right], 'fro'), ...
  'total', norm([state_maps.left; state_maps.right], 'fro')), ...
  'operation_count', operation_count);
if collect_gqp
  [action.gqp_normal_factors, action.gqp_value_maps] = ...
    LOCAL_wall_gqp_outputs(pieces, c, normal_weight);
end
end

function [value, flux, piece, diagnostic, split, operations] = ...
    LOCAL_wall_side(c, gqp, cfg, y_source, y_target, ...
    xi_left, xi_right, n_circle, side, collect)
nt = numel(y_target);
state_count = size(xi_left, 2);
zero = complex(zeros(nt, state_count));
if collect
  piece = struct('wall_self', struct('value', zero, 'flux', zero), ...
    'wall_other', struct('value', zero, 'flux', zero), ...
    'circle_double', struct('value', zero, 'flux', zero), ...
    'circle_single', struct('value', zero, 'flux', zero));
else
  piece = struct();
end
diagnostic = struct('self', zero, 'opposite_cross', zero, ...
  'circle_cross', zero);
if side < 0.0
  x_target = c.X_L;
  x_other = c.X_R;
  density = xi_left;
  other = xi_right;
  normal_sign = -1.0;
else
  x_target = c.X_R;
  x_other = c.X_L;
  density = xi_right;
  other = xi_left;
  normal_sign = 1.0;
end
[self_value, self_flux, kernel_flux, remainder_value, split, self_ops] = ...
  LOCAL_wall_self(c, gqp, y_source, y_target, density, ...
  x_target, normal_sign, cfg.panel.source_max);
if collect
  piece.wall_self.value = remainder_value;
  piece.wall_self.flux = kernel_flux;
end
value = self_value;
flux = self_flux;
diagnostic.self = self_value;
ds = c.d / numel(y_source);
src = [x_other * ones(1, numel(y_source)); y_source.'];
trg = [x_target * ones(1, nt); y_target.'];
operations = self_ops;
for first = 1.0:cfg.panel.source_max:numel(y_source)
  last = min(numel(y_source), first + cfg.panel.source_max - 1.0);
  ids = first:last;
  [p, gx, ~, ~, ~, ~, audit, rp, rgx] = ...
    LOCAL_gqp_pair(gqp, src(:, ids), trg, true);
  v = ds * p * other(ids, :);
  q = ds * normal_sign * gx * other(ids, :);
  value = value + v;
  flux = flux + q;
  diagnostic.opposite_cross = diagnostic.opposite_cross + v;
  if collect
    piece.wall_other.value = piece.wall_other.value + ...
      ds * rp * other(ids, :);
    piece.wall_other.flux = piece.wall_other.flux + ...
      ds * normal_sign * rgx * other(ids, :);
  end
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    2.0 * nt * numel(ids) * state_count;
end
[circle_value, circle_flux, circle_piece, circle_ops] = ...
  LOCAL_circle_to_wall(c, gqp, trg, normal_sign, n_circle, ...
  cfg.panel.source_max, collect);
value = value + circle_value;
flux = flux + circle_flux;
diagnostic.circle_cross = circle_value;
if collect
  piece.circle_double = circle_piece.double;
  piece.circle_single = circle_piece.single;
end
operations = operations + circle_ops;
end

function [value, flux, piece, operations] = LOCAL_circle_to_wall( ...
    c, gqp, trg, normal_sign, n_circle, source_panel, collect)
[tau, zeta, ~, theta] = LOCAL_circle_density(c, n_circle);
src = c.R * [cos(theta).'; sin(theta).'];
nsn = [cos(theta).'; sin(theta).'];
nt = size(trg, 2);
state_count = size(tau, 2);
zero = complex(zeros(nt, state_count));
value = zero;
flux = zero;
if collect
  piece.double = struct('value', zero, 'flux', zero);
  piece.single = struct('value', zero, 'flux', zero);
else
  piece = struct();
end
ds = 2.0 * pi * c.R / n_circle;
operations = 0.0;
for first = 1.0:source_panel:n_circle
  last = min(n_circle, first + source_panel - 1.0);
  ids = first:last;
  [p, gx, gy, hxx, hxy, ~, audit, ...
    rp, rgx, rgy, rhxx, rhxy] = ...
    LOCAL_gqp_pair(gqp, src(:, ids), trg, true);
  sx = nsn(1, ids);
  sy = nsn(2, ids);
  D = -gx .* sx - gy .* sy;
  Dt = -normal_sign * (hxx .* sx + hxy .* sy);
  Sn = normal_sign * gx;
  vd = ds * D * tau(ids, :);
  vs = -ds * p * zeta(ids, :);
  qd = ds * Dt * tau(ids, :);
  qs = -ds * Sn * zeta(ids, :);
  value = value + vd + vs;
  flux = flux + qd + qs;
  if collect
    Dr = -rgx .* sx - rgy .* sy;
    Dtr = -normal_sign * (rhxx .* sx + rhxy .* sy);
    Snr = normal_sign * rgx;
    piece.double.value = piece.double.value + ...
      ds * Dr * tau(ids, :);
    piece.single.value = piece.single.value - ...
      ds * rp * zeta(ids, :);
    piece.double.flux = piece.double.flux + ...
      ds * Dtr * tau(ids, :);
    piece.single.flux = piece.single.flux - ...
      ds * Snr * zeta(ids, :);
  end
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    4.0 * nt * numel(ids) * state_count;
end
end

%% ==================== Streamed self quadrature ====================
% Large Kress actions are panelized; no full finest square matrix is stored.

function [value, normal] = LOCAL_circle_free(kout, kin, radius, ...
    source_nodes, target_nodes, log_weights, tau, zeta, tau_s, source_count)
h = 2.0 * pi / source_count;
outside = LOCAL_circle_splits(kout, radius, source_nodes, target_nodes);
inside = LOCAL_circle_splits(kin, radius, source_nodes, target_nodes);
D = log_weights .* (outside.L1 - inside.L1) + ...
  h * (outside.L2 - inside.L2);
S = log_weights .* (inside.M1 - outside.M1) + ...
  h * (inside.M2 - outside.M2);
Dstar = log_weights .* (inside.Ls1 - outside.Ls1) + ...
  h * (inside.Ls2 - outside.Ls2);
[source_mesh, target_mesh] = meshgrid(source_nodes, target_nodes);
geometry = cos(target_mesh - source_mesh);
A = (log_weights .* ...
  (kout^2 * outside.M1 - kin^2 * inside.M1) + ...
  h * (kout^2 * outside.M2 - kin^2 * inside.M2)) .* geometry;
B = (log_weights .* (outside.N1 - inside.N1) + ...
  h * (outside.N2 - inside.N2)) / radius;
value = D * tau + S * zeta;
normal = A * tau + B * tau_s + Dstar * zeta;
end

function split = LOCAL_circle_splits(k, radius, source_nodes, target_nodes)
[source_mesh, target_mesh] = meshgrid(source_nodes, target_nodes);
dx = radius * (cos(target_mesh) - cos(source_mesh));
dy = radius * (sin(target_mesh) - sin(source_mesh));
distance = hypot(dx, dy);
diagonal = distance <= 64.0 * eps(radius);
safe = distance;
safe(diagonal) = 1.0;
source_normal_x = radius * cos(source_mesh);
source_normal_y = radius * sin(source_mesh);
target_normal_x = cos(target_mesh);
target_normal_y = sin(target_mesh);
dot_source = dx .* source_normal_x + dy .* source_normal_y;
dot_target = dx .* target_normal_x + dy .* target_normal_y;
target_tangent_x = -radius * sin(target_mesh);
target_tangent_y = radius * cos(target_mesh);
dot_tangent = target_tangent_x .* dx + target_tangent_y .* dy;
logterm = log(4.0 * sin((target_mesh - source_mesh) / 2.0).^2);
cotterm = cot((target_mesh - source_mesh) / 2.0);
M = 1i / 4.0 * besselh(0, 1, k * safe) * radius;
split.M1 = -1.0 / (4.0 * pi) * besselj(0, k * safe) * radius;
L = 1i * k / 4.0 * (dot_source ./ safe) .* besselh(1, 1, k * safe);
split.L1 = -k / (4.0 * pi) * ...
  (dot_source ./ safe) .* besselj(1, k * safe);
Lstar = -1i * k / 4.0 * ...
  (dot_target ./ safe) .* besselh(1, 1, k * safe) * radius;
split.Ls1 = k / (4.0 * pi) * ...
  (dot_target ./ safe) .* besselj(1, k * safe) * radius;
N = -1i * k / 4.0 * ...
  (dot_tangent ./ safe) .* besselh(1, 1, k * safe);
split.N1 = k / (4.0 * pi) * ...
  (dot_tangent ./ safe) .* besselj(1, k * safe);
split.M2 = M - split.M1 .* logterm;
split.L2 = L - split.L1 .* logterm;
split.Ls2 = Lstar - split.Ls1 .* logterm;
split.N2 = N - 1.0 / (4.0 * pi) * cotterm - split.N1 .* logterm;
euler = 0.5772156649015328606;
split.M1(diagonal) = -radius / (4.0 * pi);
split.M2(diagonal) = 0.5 * (1i / 2.0 - euler / pi - ...
  log(k^2 * radius^2 / 4.0) / (2.0 * pi)) * radius;
split.L1(diagonal) = 0.0;
split.Ls1(diagonal) = 0.0;
split.N1(diagonal) = 0.0;
split.L2(diagonal) = -1.0 / (4.0 * pi);
split.Ls2(diagonal) = -1.0 / (4.0 * pi);
split.N2(diagonal) = 0.0;
end

function [value, flux, kernel_flux, remainder_value, ...
    recombination, operations] = LOCAL_wall_self(c, gqp, ...
    y_source, y_target, xi, xwall, normal_sign, source_panel)
source_count = numel(y_source);
target_count = numel(y_target);
a = c.d / (2.0 * pi);
t_source = 2.0 * pi * (y_source + c.d / 2.0) / c.d;
t_target = 2.0 * pi * (y_target + c.d / 2.0) / c.d;
euler = 0.5772156649015328606;
free_limit = 0.5 * (1i / 2.0 - euler / pi - ...
  log(c.khat^2 * a^2 / 4.0) / (2.0 * pi)) * a;
value_gauge = complex(zeros(target_count, size(xi, 2)));
kernel_flux = complex(zeros(target_count, size(xi, 2)));
remainder_value = complex(zeros(target_count, size(xi, 2)));
numerator = 0.0;
scale_squared = 0.0;
trg = [xwall * ones(1, target_count); y_target.'];
ds = c.d / source_count;
operations = 0.0;
for first = 1.0:source_panel:source_count
  last = min(source_count, first + source_panel - 1.0);
  ids = first:last;
  src = [xwall * ones(1, numel(ids)); y_source(ids).'];
  [regular, gx, ~, ~, ~, ~, audit] = ...
    LOCAL_gqp_pair(gqp, src, trg, false);
  dy = y_target(:) - y_source(ids).';
  shift = round(dy / c.d);
  folded = dy - shift * c.d;
  phase = exp(1i * c.beta * c.d * shift);
  distance = abs(folded);
  coincident = distance <= 64.0 * eps(c.d);
  primary = complex(zeros(target_count, numel(ids)));
  primary(~coincident) = 1i / 4.0 * ...
    besselh(0, 1, c.khat * distance(~coincident));
  complete = regular + phase .* primary;
  gauged = exp(-1i * c.beta * y_target(:)) .* complete .* ...
    exp(1i * c.beta * y_source(ids).') * a;
  [source_mesh, target_mesh] = meshgrid(t_source(ids), t_target);
  delta = target_mesh - source_mesh;
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
  weights = LOCAL_rect_kress(t_source(ids), t_target, ...
    source_count, ids);
  density_gauge = exp(-1i * c.beta * y_source(ids)) .* xi(ids, :);
  value_gauge = value_gauge + ...
    (weights .* A + (2.0 * pi / source_count) * B) * density_gauge;
  remainder_value = remainder_value + ds * regular * xi(ids, :);
  kernel_flux = kernel_flux + ds * normal_sign * gx * xi(ids, :);
  operations = operations + audit.interpolation_cma + ...
    audit.bloch_phase_multiply_count + ...
    3.0 * target_count * numel(ids) * size(xi, 2);
end
recombination = sqrt(numerator) / max(sqrt(scale_squared), realmin);
value = exp(1i * c.beta * y_target(:)) .* value_gauge;
xi_target = LOCAL_wall_density_target(xi, y_source, y_target, c);
flux = kernel_flux + 0.5 * xi_target;
end

function weights = LOCAL_rect_kress(source_nodes, target_nodes, ...
    source_count, source_indices)
source_nodes = source_nodes(:).';
target_nodes = target_nodes(:);
source_count = double(source_count);
source_indices = double(source_indices(:).');
h = 2.0 * pi / source_count;
source_origin = source_nodes(1) - (source_indices(1) - 1.0) * h;
q = (target_nodes - source_origin) / h;
integer = floor(q);
fraction = q - integer;
near_one = abs(fraction - 1.0) <= ...
  256.0 * eps(max(1.0, max(abs(q))));
integer(near_one) = integer(near_one) + 1.0;
fraction(near_one) = 0.0;
fraction(abs(fraction) <= ...
  256.0 * eps(max(1.0, max(abs(q))))) = 0.0;
group = zeros(numel(target_nodes), 1);
representatives = zeros(0, 1);
for j = 1:numel(target_nodes)
  hit = find(abs(representatives - fraction(j)) <= ...
    512.0 * eps(max(1.0, abs(fraction(j)))), 1);
  if isempty(hit)
    representatives(end + 1, 1) = fraction(j); %#ok<AGROW>
    hit = numel(representatives);
  end
  group(j) = hit;
end
bases = zeros(numel(representatives), source_count);
modes = 1.0:source_count / 2.0 - 1.0;
for j = 1:numel(representatives)
  delta0 = representatives(j) * h;
  spectrum = complex(zeros(1, source_count));
  spectrum(modes + 1.0) = ...
    exp(1i * modes * delta0) ./ (2.0 * modes);
  spectrum(source_count - modes + 1.0) = ...
    exp(-1i * modes * delta0) ./ (2.0 * modes);
  spectrum(source_count / 2.0 + 1.0) = ...
    cos((source_count / 2.0) * delta0) / source_count;
  bases(j, :) = -4.0 * pi / source_count * real(fft(spectrum));
end
weights = zeros(numel(target_nodes), numel(source_nodes));
indices = source_indices - 1.0;
for j = 1:numel(target_nodes)
  weights(j, :) = bases(group(j), ...
    mod(indices - integer(j), source_count) + 1.0);
end
end

%% ==================== Frozen density coordinates ====================
% Refinement evaluates one finite trigonometric density; it never resolves it.

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

function target = LOCAL_wall_density_target(samples, y_source, y_target, c)
n = numel(y_source);
orders = (-n / 2.0:n / 2.0 - 1.0).';
gauge = exp(-1i * c.beta * y_source) .* samples;
coeff = fftshift(fft(gauge, [], 1), 1) / n;
origin = -0.5 + 0.5 / n;
coeff = exp(-1i * 2.0 * pi * orders * origin) .* coeff;
target = exp(1i * c.beta * y_target(:)) .* ...
  (exp(1i * 2.0 * pi * y_target(:) / c.d * orders.') * coeff);
end

function coeff = LOCAL_circle_coeff(samples, radius)
n = size(samples, 1);
orders = (-n / 2.0:n / 2.0 - 1.0).';
coeff = sqrt(2.0 * pi * radius) * ...
  exp(-1i * orders * pi / n) .* ...
  (fftshift(fft(samples, [], 1), 1) / n);
end

function coeff = LOCAL_wall_coeff(samples, c)
n = size(samples, 1);
orders = (-n / 2.0:n / 2.0 - 1.0).';
y = -c.d / 2.0 + c.d * ((0.0:n - 1.0).' + 0.5) / n;
gauge = exp(-1i * c.beta * y) .* samples;
origin = -0.5 + 0.5 / n;
coeff = sqrt(c.d) * exp(-1i * 2.0 * pi * orders * origin) .* ...
  (fftshift(fft(gauge, [], 1), 1) / n);
end

function padded = LOCAL_pad(value, n)
old = size(value, 1);
if old == n
  padded = value;
  return
end
padded = complex(zeros(n, size(value, 2)));
old_orders = (-old / 2.0:old / 2.0 - 1.0).';
new_orders = (-n / 2.0:n / 2.0 - 1.0).';
[present, indices] = ismember(old_orders, new_orders);
padded(indices(present), :) = value(present, :);
end

%% ==================== Residual associations ====================
% Complete P matrices remain explicit in every weighted normal factor.

function maps = LOCAL_wall_state_maps(raw_left, raw_right, c)
n = size(raw_left, 1);
left = LOCAL_wall_coeff(raw_left, c);
right = LOCAL_wall_coeff(raw_right, c);
embed = LOCAL_wall_trace_embed(c, n);
zero = complex(zeros(n, c.K));
maps.left = [embed, zero] - left;
maps.right = [zero, embed] - right;
end

function maps = LOCAL_wall_prescribed_maps(c, n)
embed = LOCAL_wall_trace_embed(c, n);
zero = complex(zeros(n, c.K));
maps.left = [embed, zero];
maps.right = [zero, embed];
end

function embed = LOCAL_wall_trace_embed(c, n)
embed = complex(zeros(n, c.K));
all_orders = (-n / 2.0:n / 2.0 - 1.0).';
retained = (-c.M:c.M).';
[present, indices] = ismember(retained, all_orders);
if ~all(present)
  error('I32V4:WallBandwidth', 'A frozen M=48 trace mode is missing.');
end
embed(indices, :) = eye(c.K);
end

function maps = LOCAL_wall_piece_residual(piece, c, sign_value)
maps.left = sign_value * LOCAL_wall_coeff(piece.value_left, c);
maps.right = sign_value * LOCAL_wall_coeff(piece.value_right, c);
end

function singleton = LOCAL_wall_flux_singleton( ...
    QL, QR, c, n, normal_weight)
center = c.center_wall_jumps;
dx_left = LOCAL_pad(center.center_left_global_dx, n);
dx_right = LOCAL_pad(center.center_right_global_dx, n);
left = (-dx_left + QR * c.Gminus * c.cminus) ./ sqrt(normal_weight);
right = (dx_right + QL * c.Gplus * c.cplus) ./ sqrt(normal_weight);
singleton = [left; right];
end

function [normal_factors, value_maps] = LOCAL_circle_gqp_outputs( ...
    pieces, c, normal_weight)
names = fieldnames(pieces);
normal_factors = cell(1, numel(names));
value_maps = cell(1, numel(names));
for j = 1:numel(names)
  name = names{j};
  normal_coeff = LOCAL_circle_coeff(pieces.(name).normal, c.R) ./ ...
    sqrt(normal_weight);
  normal_factors{j} = struct('name', ['circle_normal_', name], ...
    'plus', normal_coeff * c.Gplus, ...
    'minus', normal_coeff * c.Gminus, ...
    'singleton', complex(zeros(0, 1)));
  value_maps{j} = struct('name', ['circle_value_', name], ...
    'map', LOCAL_circle_coeff(pieces.(name).value, c.R));
end
end

function [normal_factors, value_maps] = LOCAL_wall_gqp_outputs( ...
    pieces, c, normal_weight)
names = fieldnames(pieces);
normal_factors = cell(1, numel(names));
value_maps = cell(1, 2.0 * numel(names));
for j = 1:numel(names)
  name = names{j};
  piece = pieces.(name);
  q_left = LOCAL_wall_coeff(piece.flux_left, c) ./ sqrt(normal_weight);
  q_right = LOCAL_wall_coeff(piece.flux_right, c) ./ sqrt(normal_weight);
  normal_factors{j} = struct('name', ['wall_normal_', name], ...
    'plus', q_right * c.Gplus + q_left * c.Gplus * c.Pplus, ...
    'minus', q_left * c.Gminus + q_right * c.Gminus * c.Pminus, ...
    'singleton', [q_right * c.Gminus * c.cminus; ...
    q_left * c.Gplus * c.cplus]);
  left_map = -LOCAL_wall_coeff(piece.value_left, c);
  right_map = -LOCAL_wall_coeff(piece.value_right, c);
  value_maps{2.0 * j - 1.0} = struct( ...
    'name', ['wall_value_', name, '_left'], ...
    'side', 'left', 'map', left_map);
  value_maps{2.0 * j} = struct( ...
    'name', ['wall_value_', name, '_right'], ...
    'side', 'right', 'map', right_map);
end
end

%% ==================== Frozen dual trace weights ====================
% These weights belong to normal residuals, not the shifted value lift.

function weight = LOCAL_wall_normal_weight(c, n)
orders = (-n / 2.0:n / 2.0 - 1.0).';
alpha = c.beta + 2.0 * pi * orders / c.d;
kappa = sqrt(alpha.^2 + c.gamma);
weight = 2.0 * kappa .* tanh(kappa / 2.0);
if any(~isfinite(weight) | weight <= 0.0)
  error('I32V4:WallNormalWeight', ...
    'A frozen wall dual-trace weight is invalid.');
end
end

function weight = LOCAL_circle_normal_weight(c, n, steps)
orders = (-n / 2.0:n / 2.0 - 1.0).';
t_inner = log(c.R - c.delta_c);
t_zero = log(c.R);
t_outer = log(c.R + c.delta_c);
p_inner = LOCAL_riccati(zeros(size(orders)), t_inner, t_zero, ...
  steps, orders, c.gamma * c.rho_disk);
p_outer = LOCAL_riccati(zeros(size(orders)), t_outer, t_zero, ...
  steps, orders, c.gamma);
weight = (p_inner - p_outer) / c.R;
if any(~isfinite(weight) | weight <= 0.0)
  error('I32V4:CircleNormalWeight', ...
    'A frozen circle dual-trace weight is invalid.');
end
end

function p = LOCAL_riccati(p, t0, t1, steps, orders, alpha)
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

%% ==================== Compact diagnostics and contracts ====================
% Blocked returns retain completed compact levels but no incomplete raw panel.

function piece = LOCAL_circle_piece_empty(target_count, state_count)
zero = complex(zeros(target_count, state_count));
entry = struct('value', zero, 'normal', zero);
piece = struct('circle_double', entry, 'circle_single', entry, ...
  'wall_left', entry, 'wall_right', entry);
end

function pieces = LOCAL_wall_piece_empty(target_count, state_count)
zero = complex(zeros(target_count, state_count));
entry = struct('value_left', zero, 'value_right', zero, ...
  'flux_left', zero, 'flux_right', zero);
pieces = struct('wall_self', entry, 'wall_other', entry, ...
  'circle_double', entry, 'circle_single', entry);
end

function diagnostics = LOCAL_wall_diagnostic_empty(target_count, state_count)
zero = complex(zeros(target_count, state_count));
entry = struct('value_left', zero, 'value_right', zero);
diagnostics = struct('self', entry, 'opposite_cross', entry, ...
  'circle_cross', entry);
end

function metric = LOCAL_level_metric(circle, wall, level)
metric = LOCAL_level_metric_empty();
metric.N_circle = size(level.circle_value_map, 1);
metric.N_wall = size(level.wall_left_value_map, 1);
metric.circle_recombination = circle.recombination_defect;
metric.wall_recombination = wall.recombination_defect;
metric.wall_self_split_recombination = wall.self_split_recombination;
metric.circle_piece_norms = circle.piece_norms;
metric.wall_piece_norms = wall.piece_norms;
metric.wall_normal_factor_norm = LOCAL_factor_norm(level.wall_normal_factor);
metric.circle_normal_factor_norm = LOCAL_factor_norm(level.circle_normal_factor);
metric.circle_value_map_norm = norm(level.circle_value_map, 'fro');
metric.wall_left_value_map_norm = norm(level.wall_left_value_map, 'fro');
metric.wall_right_value_map_norm = norm(level.wall_right_value_map, 'fro');
metric.operation_count = level.operation_count;
metric.normal_and_value_same_action = true;
end

function metric = LOCAL_level_metric_empty()
metric = struct('N_circle', 0.0, 'N_wall', 0.0, ...
  'circle_recombination', NaN, 'wall_recombination', NaN, ...
  'wall_self_split_recombination', NaN, ...
  'circle_piece_norms', struct(), 'wall_piece_norms', struct(), ...
  'wall_normal_factor_norm', NaN, 'circle_normal_factor_norm', NaN, ...
  'circle_value_map_norm', NaN, 'wall_left_value_map_norm', NaN, ...
  'wall_right_value_map_norm', NaN, 'operation_count', 0.0, ...
  'normal_and_value_same_action', false);
end

function value = LOCAL_factor_norm(factor)
value = sqrt(norm(factor.plus, 'fro')^2 + ...
  norm(factor.minus, 'fro')^2 + norm(factor.singleton)^2);
end

function names = LOCAL_names(entries)
names = cell(1, numel(entries));
for j = 1:numel(entries)
  names{j} = entries{j}.name;
end
end

function LOCAL_assert_level_finite(level)
expected = [level.N_circle, 97.0];
if ~isequal(size(level.circle_normal_factor.plus), expected) || ...
    ~isequal(size(level.circle_normal_factor.minus), expected) || ...
    ~isequal(size(level.circle_value_map), [level.N_circle, 194.0]) || ...
    ~isequal(size(level.wall_normal_factor.plus), [level.N_wall, 97.0]) || ...
    ~isequal(size(level.wall_normal_factor.minus), [level.N_wall, 97.0]) || ...
    ~isequal(size(level.wall_normal_factor.singleton), ...
    [2.0 * level.N_wall, 1.0]) || ...
    ~isequal(size(level.wall_left_value_map), [level.N_wall, 194.0]) || ...
    ~isequal(size(level.wall_right_value_map), [level.N_wall, 194.0])
  error('I32V4:BoundaryLevelShape', ...
    'A coupled level returned an invalid factor or value-map shape.');
end
values = {level.circle_normal_factor.plus, ...
  level.circle_normal_factor.minus, level.circle_value_map, ...
  level.wall_normal_factor.plus, level.wall_normal_factor.minus, ...
  level.wall_normal_factor.singleton, level.wall_left_value_map, ...
  level.wall_right_value_map};
for j = 1:numel(values)
  if any(~isfinite(values{j}(:)))
    error('I32V4:BoundaryLevelNonfinite', ...
      'A coupled level returned a nonfinite numerical object.');
  end
end
end

function LOCAL_assert_gqp_finite(gqp)
groups = {'wall_normal_factors', 'circle_normal_factors', ...
  'circle_value_maps', 'wall_value_maps'};
for group_index = 1:numel(groups)
  entries = gqp.(groups{group_index});
  for entry_index = 1:numel(entries)
    entry = entries{entry_index};
    names = fieldnames(entry);
    for field_index = 1:numel(names)
      value = entry.(names{field_index});
      if isnumeric(value) && any(~isfinite(value(:)))
        error('I32V4:GQPPieceNonfinite', ...
          'A finest GQP-only piece is nonfinite.');
      end
    end
  end
end
end

function LOCAL_validate(c, cfg, resource)
required = {'khat', 'mu_h', 'gamma', 'beta', 'd', 'R', 'rho_disk', ...
  'M', 'K', 'delta_c', 'delta_w', 'X_L', 'X_R', 'Gplus', ...
  'Gminus', 'Pplus', 'Pminus', 'cplus', 'cminus', ...
  'eta_unit_256', 'xi_left_unit_512', 'xi_right_unit_512', ...
  'center_wall_jumps'};
if ~isstruct(c) || ~all(isfield(c, required)) || ...
    ~isstruct(cfg) || ~all(isfield(cfg, ...
    {'levels', 'gqp', 'normal', 'panel', 'threshold'})) || ...
    ~isstruct(resource) || ~all(isfield(resource, ...
    {'start_tic', 'hard_s', 'memory_mib_max'}))
  error('I32V4:BoundaryInterface', ...
    'The boundary-sequence interface is incomplete.');
end
if ~isequal(cfg.levels.circle, [1024.0, 1280.0, 1536.0, 2048.0]) || ...
    ~isequal(cfg.levels.wall, [2048.0, 2560.0, 3072.0, 4096.0]) || ...
    ~isequal(cfg.levels.wall, 2.0 * cfg.levels.circle) || ...
    cfg.normal.circle_riccati_steps ~= 2048.0
  error('I32V4:BoundaryLevels', 'The frozen coupled levels drifted.');
end
gqp_tuple = [cfg.gqp.H, cfg.gqp.proxy_distance, cfg.gqp.Nside, ...
  cfg.gqp.Ntop, cfg.gqp.Nedge, cfg.gqp.Mpw, cfg.gqp.table_n, ...
  cfg.gqp.relative_uncertainty];
if ~isequal(gqp_tuple, ...
    [1.1, 0.2, 160.0, 160.0, 80.0, 32.0, 2049.0, 1.0e-10]) || ...
    ~isequal(cfg.gqp.table_x_bounds, [-0.5, 0.5]) || ...
    ~isequal(cfg.gqp.table_y_bounds, [-1.0, 1.0]) || ...
    cfg.panel.target_max ~= 128.0 || cfg.panel.source_max ~= 256.0 || ...
    cfg.gqp.table_panel ~= 512.0 || resource.hard_s ~= 1800.0 || ...
    resource.memory_mib_max ~= 2048.0
  error('I32V4:BoundaryConfiguration', ...
    'A fixed MFS, panel, or resource parameter drifted.');
end
if ~isequal([c.d, c.beta, c.R, c.rho_disk, c.M, c.K], ...
    [1.0, 0.5, 0.2, 17.0, 48.0, 97.0]) || ...
    ~isequal(size(c.Gplus), [194, 97]) || ...
    ~isequal(size(c.Gminus), [194, 97]) || ...
    ~isequal(size(c.Pplus), [97, 97]) || ...
    ~isequal(size(c.Pminus), [97, 97]) || ...
    ~isequal(size(c.cplus), [97, 1]) || ...
    ~isequal(size(c.cminus), [97, 1]) || ...
    ~isequal(size(c.eta_unit_256), [512, 194]) || ...
    ~isequal(size(c.xi_left_unit_512), [512, 194]) || ...
    ~isequal(size(c.xi_right_unit_512), [512, 194]) || ...
    ~all(isfield(c.center_wall_jumps, ...
    {'center_left_global_dx', 'center_right_global_dx'}))
  error('I32V4:BoundaryCertificate', ...
    'A frozen certificate field or dimension drifted.');
end
values = {c.khat, c.mu_h, c.gamma, c.Gplus, c.Gminus, ...
  c.Pplus, c.Pminus, c.cplus, c.cminus, c.eta_unit_256, ...
  c.xi_left_unit_512, c.xi_right_unit_512, ...
  c.center_wall_jumps.center_left_global_dx, ...
  c.center_wall_jumps.center_right_global_dx};
for j = 1:numel(values)
  if ~isa(values{j}, 'double') || any(~isfinite(values{j}(:)))
    error('I32V4:BoundaryCertificateNonfinite', ...
      'A required frozen numerical object is non-double or nonfinite.');
  end
end
end

function mib = LOCAL_proxy_mib(cfg)
equations = 2.0 * cfg.gqp.Nside + 4.0 * cfg.gqp.Ntop;
unknowns = 4.0 * cfg.gqp.Nedge + ...
  2.0 * (2.0 * cfg.gqp.Mpw + 1.0);
bytes = 12.0 * equations * unknowns * 16.0 + ...
  16.0 * (equations + unknowns)^2;
mib = bytes / 2^20;
end

function LOCAL_resource(resource, local_mib)
if toc(resource.start_tic) > resource.hard_s
  error('I32V4:HARD_TIME_LIMIT', ...
    'The hard boundary-sequence time gate was reached.');
end
retained = 0.0;
publication = 64.0;
if isfield(resource, 'retained_mib')
  retained = resource.retained_mib;
end
if isfield(resource, 'publication_mib')
  publication = resource.publication_mib;
end
if retained + local_mib + publication > resource.memory_mib_max
  error('I32V4:HARD_MEMORY_LIMIT', ...
    'The hard boundary-sequence memory proxy was exceeded.');
end
end

function mib = LOCAL_caller_workspace_mib()
items = evalin('caller', 'whos');
mib = sum([items.bytes]) / 2^20;
end

function out = LOCAL_empty()
out = struct('schema', 'I32V4_BOUNDARY_SEQUENCE_V1', ...
  'status', 'INITIALIZED', 'available', false, 'warnings', {{}}, ...
  'first_blocker', '', 'audit', struct(), 'counters', struct(), ...
  'memory', struct(), 'data', struct(), 'private', struct());
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V4:UNIDENTIFIED_BLOCKER';
end
end
