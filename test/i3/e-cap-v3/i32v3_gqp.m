function varargout = i32v3_gqp(operation, varargin)
%I32V3_GQP Fixed one-table MFS evaluator and sole v3 G_QP gateway.
% Purpose:
%   Build one 2049-by-2049 six-field MFS smooth-remainder table or evaluate
%   that table on a streamed physical source/target panel.
% Input:
%   `i32v3_gqp('build', certificate, cfg, resource)` builds the table.
%   `i32v3_gqp('pair', gqp, src, trg, include_primary)` evaluates pairs.
% Output:
%   Build returns one module struct. Pair returns potential, two target
%   derivatives, three Hessian entries, and a compact audit.
% Main algorithm:
%   Fold physical Delta-y by MATLAB round, interpolate the proxy remainder
%   with a one-sided 4-by-4 tensor cubic stencil, apply the Bloch phase, and
%   optionally add the exactly folded free-space primary.
% Based on:
%   design-3-2d Section 13 and the project MFS primitives
%   kernel.precomp_proxy, kernel.h2d_directch, kernel.qpgreen_mfs_pairmat.
% Main changes:
%   Exactly one proxy and one 2049 table; no variant, sweep, fallback, image
%   sum, outer plane-wave evaluator, or old e-cap helper.

switch char(operation)
  case 'build'
    if numel(varargin) ~= 3
      error('I32V3:GQPBuildInterface', ...
        'build requires certificate, cfg, and resource.');
    end
    varargout{1} = LOCAL_build(varargin{1}, varargin{2}, varargin{3});
  case 'pair'
    if numel(varargin) ~= 4
      error('I32V3:GQPPairInterface', ...
        'pair requires gqp, src, trg, and include_primary.');
    end
    [varargout{1:nargout}] = LOCAL_pair(varargin{:});
  otherwise
    error('I32V3:GQPOperation', 'Unknown GQP operation.');
end
end

%% ==================== One fixed MFS build ====================
% This path performs the only lsqminnorm-backed proxy construction.

function out = LOCAL_build(c, cfg, resource)
timer = tic;
out = LOCAL_empty();
progress = struct('stage', 'entry', 'completed_proxy_builds', 0.0, ...
  'completed_table_panels', 0.0, 'completed_table_rows', 0.0, ...
  'local_peak_mib', 0.0, 'complete', false);
out.audit.symbol_ledger = struct( ...
  'table', '2049^2-by-6 flat MFS smooth-remainder table', ...
  'xgrid', 'folded physical Delta-y coordinate', ...
  'ygrid', 'physical Delta-x coordinate', ...
  'kernel_relative_uncertainty', 'fixed empirical 1e-10 action factor');
try
  LOCAL_validate_build(c, cfg, resource);
  if isempty(which('lsqminnorm'))
    error('I32V3:LSQMINNORMUnavailable', ...
      'Normal MATLAB resolution did not find lsqminnorm.');
  end
  pars = struct('d', c.d, 'beta', c.beta, 'k', c.khat);
  spec = struct('H', cfg.gqp.H, 'proxy_dist', cfg.gqp.proxy_distance, ...
    'N_side', cfg.gqp.Nside, 'N_top', cfg.gqp.Ntop, ...
    'N_proxy_edge', cfg.gqp.Nedge, 'M_pw', cfg.gqp.Mpw);
  progress.stage = 'proxy';
  LOCAL_resource(resource, LOCAL_proxy_bytes(cfg));
  proxy = kernel.precomp_proxy(pars, spec);
  progress.completed_proxy_builds = 1.0;
  if any(~isfinite([proxy.q(:); proxy.Z(:); proxy.C_up(:); proxy.C_down(:)]))
    error('I32V3:MFSProxyNonfinite', 'The fixed MFS proxy is nonfinite.');
  end

  n = cfg.gqp.table_n;
  xgrid = linspace(cfg.gqp.table_x_bounds(1), ...
    cfg.gqp.table_x_bounds(2), n);
  ygrid = linspace(cfg.gqp.table_y_bounds(1), ...
    cfg.gqp.table_y_bounds(2), n);
  count = n * n;
  flat = complex(zeros(count, 6));
  progress.stage = 'table';
  for first = 1.0:cfg.gqp.table_panel:count
    last = min(count, first + cfg.gqp.table_panel - 1.0);
    ids = first:last;
    [iy, ix] = ind2sub([n, n], ids);
    points = [xgrid(ix); ygrid(iy)];
    [pot, grad, hess] = kernel.h2d_directch(c.khat, ...
      proxy.Z, proxy.q, points);
    flat(ids, :) = [pot(:), grad.', hess.'];
    progress.completed_table_panels = ...
      progress.completed_table_panels + 1.0;
    progress.completed_table_rows = last;
    probe = whos('flat', 'points', 'pot', 'grad', 'hess', 'proxy');
    progress.local_peak_mib = max(progress.local_peak_mib, ...
      sum([probe.bytes]) / 2^20);
    LOCAL_resource(resource, progress.local_peak_mib * 2^20);
  end
  clear points pot grad hess
  private = struct('schema', 'I32V3_GQP_TABLE_V1', ...
    'table', flat, 'xgrid', xgrid, 'ygrid', ygrid, ...
    'd', c.d, 'beta', c.beta, 'k', c.khat);
  [spot, supported] = LOCAL_spots(private, proxy, cfg);
  clear proxy

  out.private = private;
  out.data = struct('table_n', n, 'field_count', 6.0, ...
    'relative_uncertainty', cfg.gqp.relative_uncertainty, ...
    'supported', supported, 'spot_oracle', spot, ...
    'parameters', spec, 'table_coordinate_order', ...
    'linear rows=Delta-x fastest within folded Delta-y; six fields in columns', ...
    'table_storage', 'n^2-by-6 flat');
  out.audit.image_sum_code_path_zero = true;
  out.audit.rayleigh_field_code_path_zero = true;
  out.audit.fixed_single_proxy = true;
  out.audit.fixed_single_table = true;
  out.audit.direct_spots_are_global_bound = false;
  out.counters = struct('precomp_proxy', 1.0, ...
    'lsqminnorm_selected', 1.0, 'pinv_fallback', 0.0, ...
    'image_sum_calls', 0.0, 'mfs_variants', 0.0, ...
    'mfs_sweeps', 0.0, 'direct_spot_pairs', spot.pair_count);
  if ~supported
    out.warnings{end + 1} = 'KERNEL_ASSUMPTION_UNRESOLVED';
  end
  progress.stage = 'complete';
  progress.complete = true;
  out.audit.progress = progress;
  out.available = true;
  out.status = 'COMPLETE';
catch err
  out.status = 'BLOCKED';
  out.first_blocker = LOCAL_identifier(err);
  out.audit.exception_message = err.message;
  progress.stage = 'blocked';
  progress.first_blocker = out.first_blocker;
  out.audit.progress = progress;
  clear flat proxy points pot grad hess
end
info = whos('out');
out.memory = struct('local_peak_mib', max(progress.local_peak_mib, ...
  info.bytes / 2^20), 'retained_mib', info.bytes / 2^20, ...
  'largest_object', '2049^2 six-field complex remainder table');
out.audit.elapsed_s = toc(timer);
end

function [spot, supported] = LOCAL_spots(private, proxy, cfg)
points = [-0.4375, -0.73; -0.183, 0.31; 0.117, -0.47; 0.421, 0.82; ...
  -0.49, -0.91; -0.49, 0.67; 0.49, -0.63; 0.49, 0.93; ...
  -0.251, -0.19; 0.251, 0.23; -0.071, 0.57; 0.079, -0.83];
points = points(1:cfg.gqp.spot_count, :);
relative = zeros(size(points, 1), 6);
for j = 1:size(points, 1)
  dy = points(j, 1);
  dx = points(j, 2);
  src = [0.0; 0.0];
  trg = [dx; dy];
  g = struct('available', true, 'private', private);
  [p, gx, gy, hxx, hxy, hyy] = LOCAL_pair(g, src, trg, false);
  interpolated = [p, gx, gy, hxx, hxy, hyy];
  qp = struct('d', private.d, 'beta', private.beta, ...
    'k', private.k, 'periodic_axis', 'y');
  [pd, gxd, gyd, hxxd, hxyd, hyyd] = ...
    kernel.qpgreen_mfs_pairmat(src, trg, qp, proxy);
  shift = round(dy / private.d);
  folded = dy - shift * private.d;
  phase = exp(1i * private.beta * private.d * shift);
  [p0, g0, h0] = kernel.h2d_directch(private.k, [0.0; 0.0], ...
    1.0, [folded; dx]);
  direct = [pd - phase * p0, gxd - phase * g0(2), ...
    gyd - phase * g0(1), hxxd - phase * h0(3), ...
    hxyd - phase * h0(2), hyyd - phase * h0(1)];
  relative(j, :) = abs(interpolated - direct) ./ ...
    max(abs(direct), realmin);
end
maximum = max(relative, [], 1);
supported = all(maximum <= cfg.gqp.spot_tolerance);
spot = struct('pair_count', size(points, 1), ...
  'maximum_relative_by_field', maximum, ...
  'maximum_relative', max(maximum), ...
  'threshold', cfg.gqp.spot_tolerance, 'supported', supported, ...
  'interpretation', 'compatibility spot only; not a global bound');
end

%% ==================== Physical pair gateway ====================
% Boundary modules reach the quasiperiodic kernel only through this path.

function [pot, gx, gy, hxx, hxy, hyy, audit, ...
    remainder_pot, remainder_gx, remainder_gy, ...
    remainder_hxx, remainder_hxy, remainder_hyy] = ...
    LOCAL_pair(g, src, trg, include_primary)
if ~isstruct(g) || ~isfield(g, 'available') || ~g.available || ...
    ~isfield(g, 'private') || size(src, 1) ~= 2 || size(trg, 1) ~= 2 || ...
    isempty(src) || isempty(trg) || any(~isfinite([src(:); trg(:)])) || ...
    ~(islogical(include_primary) || ...
    (isnumeric(include_primary) && isscalar(include_primary)))
  error('I32V3:GQPPairInterface', 'Invalid GQP pair request.');
end
d = g.private.d;
dx = trg(1, :).'-src(1, :);
dy = trg(2, :).'-src(2, :);
shift = round(dy / d);
xquery = dy - shift * d;
yquery = dx;
[values, interpolation_count] = LOCAL_interp(g.private, xquery, yquery);
phase = exp(1i * g.private.beta * d * shift(:));
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
    error('I32V3:GQPSingularPrimary', ...
      'A complete-kernel pair request contains a coincidence.');
  end
  [p0, g0, h0] = kernel.h2d_directch(g.private.k, ...
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

function [values, operations] = LOCAL_interp(private, xquery, yquery)
x = private.xgrid;
y = private.ygrid;
table = private.table;
xquery = xquery(:);
yquery = yquery(:);
tol = 256.0 * eps(max([1.0, abs(x), abs(y)]));
if any(xquery < x(1) - tol | xquery > x(end) + tol | ...
    yquery < y(1) - tol | yquery > y(end) + tol)
  error('I32V3:GQPInterpolationDomain', ...
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

%% ==================== Contracts and resources ====================
% Hard gates stop only impossible/resource-invalid numerical work.

function LOCAL_validate_build(c, cfg, resource)
if ~isstruct(c) || ~all(isfield(c, {'d', 'beta', 'khat'})) || ...
    ~isequal(c.d, 1.0) || any(~isfinite([c.d, c.beta, c.khat])) || ...
    ~isstruct(cfg) || cfg.gqp.table_n ~= 2049.0 || ...
    ~isequal([cfg.gqp.H, cfg.gqp.proxy_distance, cfg.gqp.Nside, ...
    cfg.gqp.Ntop, cfg.gqp.Nedge, cfg.gqp.Mpw], ...
    [1.1, 0.2, 160.0, 160.0, 80.0, 32.0]) || ...
    ~isstruct(resource) || ~all(isfield(resource, ...
    {'start_tic', 'hard_s', 'memory_mib_max'}))
  error('I32V3:GQPConfig', 'The fixed MFS interface or parameters drifted.');
end
end

function bytes = LOCAL_proxy_bytes(cfg)
equations = 2.0 * cfg.gqp.Nside + 4.0 * cfg.gqp.Ntop;
unknowns = 4.0 * cfg.gqp.Nedge + 2.0 * (2.0 * cfg.gqp.Mpw + 1.0);
bytes = 12.0 * equations * unknowns * 16.0 + ...
  16.0 * (equations + unknowns)^2;
end

function LOCAL_resource(resource, local_bytes)
if toc(resource.start_tic) > resource.hard_s
  error('I32V3:HARD_TIME_LIMIT', 'The 1800 s hard time gate was reached.');
end
retained = 0.0;
publication = 64.0;
if isfield(resource, 'retained_mib'), retained = resource.retained_mib; end
if isfield(resource, 'publication_mib'), publication = resource.publication_mib; end
if retained + local_bytes / 2^20 + publication > resource.memory_mib_max
  error('I32V3:HARD_MEMORY_LIMIT', ...
    'The 2048 MiB hard memory proxy was exceeded.');
end
end

function out = LOCAL_empty()
out = struct('schema', 'I32V3_GQP_V1', 'status', 'INITIALIZED', ...
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
