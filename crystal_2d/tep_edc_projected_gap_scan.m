function results = tep_edc_projected_gap_scan(user_opts)
% TEP_EDC_PROJECTED_GAP_SCAN Find projected-gap k candidates for EDC scans.
%
% Purpose:
%   Runs a fixed-beta diagnostic scan on the perfect periodic lead cell used
%   by tep_edc_scan_local.m.  The goal is to identify real wavenumbers k for
%   which the corresponding perfect crystal has no horizontal propagating
%   Bloch multiplier, hence the empty-defect or missing-column problem has a
%   plausible evanescent far-field background.
%
% Main algorithm:
%   For each sampled real k, construct the one-cell scattering matrix S_cell
%   for the periodic lead cell and solve the generalized Bloch eigenproblem
%
%     A_sc v = lambda B_sc v.
%
%   A sample is marked as a projected-gap candidate when no retained
%   multiplier satisfies
%
%     ||lambda_j| - 1| <= unit_tol.
%
%   This is not a search for a defect eigenmode.  It is a pre-scan that
%   finds frequency intervals where a later defect mode could decay in the
%   x direction because the perfect crystal has no x-propagating bulk branch.
%
% Based on:
%   tep_edc_scan_local.m for the lead geometry, periods, refractive index,
%   Rayleigh truncation, and proxy parameters.  It also follows the Bloch
%   mode workflow used in bloch_test_modes.m.
%
% Main changes:
%   This helper does not assemble the empty-defect trace-matching matrix and
%   does not compute sigma_min(A_def).  It only scans the perfect lead-cell
%   Bloch multipliers to suggest k intervals worth passing to the defect
%   scan.
%
% Numerical goal:
%   For a fixed beta, report contiguous k intervals where the number of
%   near-unit Bloch multipliers is zero.  These intervals are the most
%   plausible targets for later empty-defect or line-defect singular-value
%   scans.
%
% Input:
%   user_opts - Optional struct overriding parameters in stage 1.
%
% Output:
%   results - Struct containing k samples, multiplier diagnostics, candidate
%             interval summaries, and all user-adjustable parameters.

  if nargin < 1 || isempty(user_opts)
    user_opts = struct();
  end

  format long;

  % --- stage 1: set user parameters ---

  params = LOCAL_default_params();
  params = LOCAL_apply_user_options(params, user_opts);
  LOCAL_validate_params(params);
  LOCAL_print_run_header(params);

  % --- stage 2: build shared lead geometry ---

  geom_data = LOCAL_build_lead_geometry(params);
  ctx = params;
  ctx.geom_data = geom_data;
  ctx.mode_opts = struct();
  ctx.mode_opts.lambda_tol = params.unit_tol;
  ctx.mode_opts.normalize = 'V';

  % --- stage 3: scan k values and classify horizontal Bloch multipliers ---

  k_grid = linspace(params.k_interval(1), params.k_interval(2), params.num_k);
  point = repmat(LOCAL_empty_point_result(), params.num_k, 1);
  for j = 1:params.num_k
    point(j) = LOCAL_eval_projected_gap_point(k_grid(j), ctx);
    if params.verbose
      LOCAL_print_point_line(j, params.num_k, k_grid(j), point(j));
    end
  end

  % --- stage 4: collect projected-gap candidate intervals ---

  target_mask = LOCAL_target_mask(point);
  intervals = LOCAL_build_candidate_intervals(k_grid, point, target_mask);
  top_samples = LOCAL_rank_target_samples(k_grid, point, target_mask, ...
    params.max_samples_report);
  results = LOCAL_build_results(params, k_grid, point, target_mask, ...
    intervals, top_samples);

  % --- stage 5: report and plot diagnostics ---

  LOCAL_print_summary(results);
  if params.make_plot
    LOCAL_plot_results(results);
  end

end

%% ==================== Parameter helper ====================
% These helpers define, override, validate, and print scan parameters.

function params = LOCAL_default_params()

  % Boundary discretization and geometry for the perfect periodic lead cell.
  % These defaults match tep_edc_scan_local.m.
  params.ntot = 40;
  params.flag_geom = 'circle';
  params.radius = 0.3;
  params.ellipse_a = 0.4;
  params.ellipse_b = 0.4;

  % Exterior/background and inclusion refractive-index ratio.  The perfect
  % lead cell contains the dielectric inclusion; the defect cell itself is
  % not assembled in this diagnostic.
  params.n = 1.5;

  % Physical x/y periods and fixed y-quasiperiodic parameter.  beta is held
  % fixed while real k is scanned.
  params.L = 2.0;
  params.d = 2 * pi;
  params.beta = 0.4;

  % Default k interval mirrors tep_edc_scan_local.m.  Increase k_interval(2)
  % when using this helper as a broader projected-band scan.
  params.k_margin = 1e-3;
  params.k_interval = [params.k_margin, params.beta - params.k_margin];
  params.num_k = 81;

  % Real-k scan by default.  A small positive eps_k can be used as a rough
  % regularization if the one-cell QP solve is singular at isolated samples.
  params.eps_k = 0;

  % Rayleigh truncation half-width.  The number of Rayleigh channels is
  % K = 2*M + 1.
  params.M = 10;

  % A sample is treated as having an x-propagating bulk branch when at least
  % one multiplier obeys ||lambda|-1| <= unit_tol.
  params.unit_tol = 1e-3;

  % Reporting and plotting controls.
  params.max_samples_report = 10;
  params.make_plot = true;
  params.verbose = false;

  % Lead-cell wall coordinates.
  params.X_L = -params.L / 2;
  params.X_R = params.L / 2;

  % Quasi-periodic Green parameters.  For physical y-periodicity,
  % precomp_proxy sees the swapped computational coordinates used by
  % kernel.qpgreen_mfs.
  params.pars1.beta = params.beta;
  params.pars1.d = params.d;
  params.pars1.periodic_axis = 'y';
  params.pars2.H = params.L / 2 + params.radius + 0.4;
  params.pars2.proxy_dist = 0.7;
  params.pars2.N_side = 40;
  params.pars2.N_top = 40;
  params.pars2.N_proxy_edge = 24;
  params.pars2.M_pw = 8;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params = LOCAL_apply_user_options(params, user_opts)

  names = fieldnames(user_opts);
  for j = 1:length(names)
    name = names{j};
    if ~isfield(params, name)
      error('tep_edc_projected_gap_scan:UnknownOption', ...
        'Unknown option ''%s''.', name);
    end
    params.(name) = user_opts.(name);
  end

  params.X_L = -params.L / 2;
  params.X_R = params.L / 2;

  if ~isfield(user_opts, 'k_interval') || isempty(user_opts.k_interval)
    params.k_interval = [params.k_margin, params.beta - params.k_margin];
  end
  if ~isfield(user_opts, 'pars1') || isempty(user_opts.pars1)
    params.pars1.beta = params.beta;
    params.pars1.d = params.d;
    params.pars1.periodic_axis = 'y';
  end
  if ~isfield(user_opts, 'pars2') || isempty(user_opts.pars2)
    params.pars2.H = params.L / 2 + LOCAL_geometry_x_extent(params) + 0.4;
    params.pars2.proxy_dist = 0.7;
    params.pars2.N_side = 40;
    params.pars2.N_top = 40;
    params.pars2.N_proxy_edge = 24;
    params.pars2.M_pw = 8;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_params(params)

  if params.ntot < 4 || params.ntot ~= floor(params.ntot)
    error('tep_edc_projected_gap_scan:InvalidNtot', ...
      'ntot must be an integer at least 4.');
  end
  if mod(params.ntot, 2) ~= 0
    warning('tep_edc_projected_gap_scan:OddNtot', ...
      'Even ntot values are recommended for Kress quadrature consistency.');
  end
  if ~(ischar(params.flag_geom) || isstring(params.flag_geom))
    error('tep_edc_projected_gap_scan:InvalidGeometry', ...
      'flag_geom must be a character vector or string scalar.');
  end
  if params.L <= 0 || params.d <= 0
    error('tep_edc_projected_gap_scan:InvalidPeriod', ...
      'L and d must be positive.');
  end
  if ~(isnumeric(params.k_interval) && isreal(params.k_interval) && ...
      numel(params.k_interval) == 2 && params.k_interval(2) > params.k_interval(1))
    error('tep_edc_projected_gap_scan:InvalidKInterval', ...
      'k_interval must be an increasing two-entry real vector.');
  end
  if params.num_k < 2 || params.num_k ~= floor(params.num_k)
    error('tep_edc_projected_gap_scan:InvalidNumK', ...
      'num_k must be an integer at least 2.');
  end
  if params.M < 0 || params.M ~= floor(params.M)
    error('tep_edc_projected_gap_scan:InvalidM', ...
      'M must be a nonnegative integer.');
  end
  if params.unit_tol < 0 || ~isfinite(params.unit_tol)
    error('tep_edc_projected_gap_scan:InvalidUnitTol', ...
      'unit_tol must be a nonnegative finite scalar.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_run_header(params)

  fprintf('Running projected-gap pre-scan for tep_edc_scan_local\n');
  fprintf('  beta = %.16g, k interval = [%.16g, %.16g]\n', ...
    params.beta, params.k_interval(1), params.k_interval(2));
  fprintf('  L = %.16g, d = %.16g, M = %d, ntot = %d\n', ...
    params.L, params.d, params.M, params.ntot);
  fprintf('  geometry = %s, n = %.16g, eps_k = %.3e\n', ...
    char(params.flag_geom), params.n, params.eps_k);
  fprintf('  num_k = %d, unit_tol = %.3e\n', params.num_k, params.unit_tol);

end

%% ==================== Geometry helper ====================
% This helper builds the perfect lead-cell boundary used at every k sample.

function geom_data = LOCAL_build_lead_geometry(params)

  flag_geom = char(params.flag_geom);
  if strcmp(flag_geom, 'circle')
    [C, curvelen, ~, ~] = geom.construct_cont(params.ntot, flag_geom, ...
      0, 0, params.radius);
  elseif strcmp(flag_geom, 'ellipse')
    [C, curvelen, ~, ~] = geom.construct_cont(params.ntot, flag_geom, ...
      0, 0, params.ellipse_a, params.ellipse_b);
  else
    [C, curvelen, ~, ~] = geom.construct_cont(params.ntot, flag_geom, 0, 0);
  end

  geom_data.C = C;
  geom_data.curvelen = curvelen;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x_extent = LOCAL_geometry_x_extent(params)

  flag_geom = char(params.flag_geom);
  if strcmp(flag_geom, 'circle')
    x_extent = params.radius;
  elseif strcmp(flag_geom, 'ellipse')
    x_extent = params.ellipse_a;
  else
    x_extent = 0.4;
  end

end

%% ==================== Bloch multiplier helper ====================
% These helpers evaluate one k sample and classify its perfect-crystal modes.

function point = LOCAL_eval_projected_gap_point(k_real, ctx)

  point = LOCAL_empty_point_result();
  point.k_real = k_real;

  try
    kext = k_real + 1i * ctx.eps_k;
    kint = ctx.n * kext;
    pars1 = ctx.pars1;
    pars1.k = kext;

    proxy = kernel.precomp_proxy(pars1, ctx.pars2);
    rayleighchan = bloch.rayleigh_channels(kext, ctx.beta, ctx.d, ...
      ctx.M, ctx.L);
    S_cell = bloch.construct_S(ctx.geom_data.C, kext, kint, pars1, proxy, ...
      ctx.geom_data.curvelen, rayleighchan, ctx.X_L, ctx.X_R);
    modes = bloch.solve_modes(S_cell, ctx.mode_opts);

    lambda = modes.lambda(:);
    abs_lambda = abs(lambda);
    unit_distance = abs(abs_lambda - 1);

    point.status = 'ok';
    point.K = rayleighchan.K;
    point.num_modes = length(lambda);
    point.count_unit = sum(unit_distance <= ctx.unit_tol);
    point.count_right_decay = sum(abs_lambda < 1 - ctx.unit_tol);
    point.count_left_decay = sum(abs_lambda > 1 + ctx.unit_tol);
    point.min_unit_distance = LOCAL_min_or_nan(unit_distance);
    point.min_abs_lambda = LOCAL_min_or_nan(abs_lambda);
    point.max_abs_lambda = LOCAL_max_or_nan(abs_lambda);
    point.lambda = lambda;
    point.solve_relative_residual_norm = LOCAL_get_field_or_nan( ...
      S_cell, 'solve_relative_residual_norm');
  catch ME
    point.status = 'failed';
    point.error_id = ME.identifier;
    point.error_message = ME.message;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function point = LOCAL_empty_point_result()

  point = struct( ...
    'k_real', NaN, ...
    'status', 'unset', ...
    'error_id', '', ...
    'error_message', '', ...
    'K', NaN, ...
    'num_modes', NaN, ...
    'count_unit', NaN, ...
    'count_right_decay', NaN, ...
    'count_left_decay', NaN, ...
    'min_unit_distance', NaN, ...
    'min_abs_lambda', NaN, ...
    'max_abs_lambda', NaN, ...
    'lambda', [], ...
    'solve_relative_residual_norm', NaN);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function target_mask = LOCAL_target_mask(point)

  target_mask = false(size(point));
  for j = 1:numel(point)
    target_mask(j) = strcmp(point(j).status, 'ok') && ...
      point(j).count_unit == 0;
  end

end

%% ==================== Candidate interval helper ====================
% These helpers turn target samples into contiguous candidate k intervals.

function intervals = LOCAL_build_candidate_intervals(k_grid, point, target_mask)

  intervals = repmat(LOCAL_empty_interval(), 0, 1);
  if ~any(target_mask)
    return;
  end

  n = length(k_grid);
  j = 1;
  while j <= n
    if ~target_mask(j)
      j = j + 1;
      continue;
    end

    start_idx = j;
    while j < n && target_mask(j + 1)
      j = j + 1;
    end
    end_idx = j;

    interval = LOCAL_empty_interval();
    interval.id = length(intervals) + 1;
    interval.start_idx = start_idx;
    interval.end_idx = end_idx;
    interval.num_samples = end_idx - start_idx + 1;
    interval.sample_k_min = k_grid(start_idx);
    interval.sample_k_max = k_grid(end_idx);
    interval.k_left = LOCAL_left_interval_edge(k_grid, start_idx);
    interval.k_right = LOCAL_right_interval_edge(k_grid, end_idx);
    interval.width = interval.k_right - interval.k_left;

    distances = [point(start_idx:end_idx).min_unit_distance];
    [interval.best_score, local_best] = max(distances);
    interval.best_idx = start_idx + local_best - 1;
    interval.best_k = k_grid(interval.best_idx);
    intervals(end + 1, 1) = interval;
    j = j + 1;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function interval = LOCAL_empty_interval()

  interval = struct( ...
    'id', [], ...
    'start_idx', [], ...
    'end_idx', [], ...
    'num_samples', [], ...
    'sample_k_min', [], ...
    'sample_k_max', [], ...
    'k_left', [], ...
    'k_right', [], ...
    'width', [], ...
    'best_idx', [], ...
    'best_k', [], ...
    'best_score', []);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function edge = LOCAL_left_interval_edge(k_grid, idx)

  if idx <= 1
    edge = k_grid(1);
  else
    edge = 0.5 * (k_grid(idx - 1) + k_grid(idx));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function edge = LOCAL_right_interval_edge(k_grid, idx)

  if idx >= length(k_grid)
    edge = k_grid(end);
  else
    edge = 0.5 * (k_grid(idx) + k_grid(idx + 1));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function top_samples = LOCAL_rank_target_samples(k_grid, point, target_mask, max_count)

  top_samples = repmat(LOCAL_empty_sample_rank(), 0, 1);
  idx = find(target_mask(:));
  if isempty(idx)
    return;
  end

  score = [point(idx).min_unit_distance].';
  [~, order] = sort(score, 'descend');
  idx = idx(order);
  keep_count = min(max_count, length(idx));

  for j = 1:keep_count
    jj = idx(j);
    entry = LOCAL_empty_sample_rank();
    entry.rank = j;
    entry.idx = jj;
    entry.k = k_grid(jj);
    entry.score = point(jj).min_unit_distance;
    entry.count_right_decay = point(jj).count_right_decay;
    entry.count_left_decay = point(jj).count_left_decay;
    top_samples(end + 1, 1) = entry;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function entry = LOCAL_empty_sample_rank()

  entry = struct( ...
    'rank', [], ...
    'idx', [], ...
    'k', [], ...
    'score', [], ...
    'count_right_decay', [], ...
    'count_left_decay', []);

end

%% ==================== Result and reporting helper ====================
% These helpers package, print, and plot the projected-gap scan diagnostics.

function results = LOCAL_build_results(params, k_grid, point, target_mask, ...
    intervals, top_samples)

  results = struct();
  results.params = params;
  results.k_grid = k_grid;
  results.point = point;
  results.status = {point.status}.';
  results.count_unit = [point.count_unit].';
  results.count_right_decay = [point.count_right_decay].';
  results.count_left_decay = [point.count_left_decay].';
  results.min_unit_distance = [point.min_unit_distance].';
  results.target_mask = target_mask(:);
  results.intervals = intervals;
  results.top_samples = top_samples;
  results.num_ok = sum(strcmp(results.status, 'ok'));
  results.num_failed = sum(strcmp(results.status, 'failed'));
  results.num_target = sum(results.target_mask);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_summary(results)

  fprintf('\nProjected-gap scan summary:\n');
  fprintf('  successful samples = %d / %d\n', ...
    results.num_ok, length(results.k_grid));
  fprintf('  failed samples = %d\n', results.num_failed);
  fprintf('  projected-gap target samples = %d\n', results.num_target);

  fprintf('\nCandidate k intervals with no |lambda| near one:\n');
  if isempty(results.intervals)
    fprintf('  No projected-gap intervals were found on this grid.\n');
  else
    fprintf('  id      k_left        k_right       width       samples      best_k       best_dist\n');
    for j = 1:length(results.intervals)
      entry = results.intervals(j);
      fprintf('  %2d  %.10f  %.10f  %.3e  %7d  %.10f  %.3e\n', ...
        entry.id, entry.k_left, entry.k_right, entry.width, ...
        entry.num_samples, entry.best_k, entry.best_score);
    end
  end

  fprintf('\nTop target samples ranked by distance from |lambda| = 1:\n');
  if isempty(results.top_samples)
    fprintf('  No target samples to rank.\n');
  else
    fprintf('  rank  idx       k_real       min_dist    right_decay  left_decay\n');
    for j = 1:length(results.top_samples)
      entry = results.top_samples(j);
      fprintf('  %4d  %3d  %.10f  %.3e  %11d  %10d\n', ...
        entry.rank, entry.idx, entry.k, entry.score, ...
        entry.count_right_decay, entry.count_left_decay);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_point_line(j, n, k_real, point)

  if strcmp(point.status, 'ok')
    fprintf('  [%3d/%3d] k = %.10f, count_unit = %d, min_dist = %.3e\n', ...
      j, n, k_real, point.count_unit, point.min_unit_distance);
  else
    fprintf('  [%3d/%3d] k = %.10f, failed: %s\n', ...
      j, n, k_real, point.error_message);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_results(results)

  figure('Name', 'Projected gap pre-scan', 'Color', 'w');

  subplot(2, 1, 1);
  plot(results.k_grid, results.count_unit, '-o', 'LineWidth', 1.2, ...
    'MarkerSize', 4);
  grid on;
  xlabel('Real wavenumber k');
  ylabel('count(| |lambda| - 1 | <= tol)');
  title(sprintf('Near-unit Bloch multiplier count, beta = %.4g', ...
    results.params.beta));

  subplot(2, 1, 2);
  semilogy(results.k_grid, results.min_unit_distance, '-o', ...
    'LineWidth', 1.2, 'MarkerSize', 4);
  hold on;
  if any(results.target_mask)
    semilogy(results.k_grid(results.target_mask), ...
      results.min_unit_distance(results.target_mask), 's', ...
      'MarkerSize', 6, 'MarkerFaceColor', [0.85, 0.2, 0.1], ...
      'MarkerEdgeColor', [0.85, 0.2, 0.1], ...
      'DisplayName', 'candidate');
  end
  grid on;
  xlabel('Real wavenumber k');
  ylabel('min_j ||lambda_j| - 1|');
  title('Distance from horizontal propagating bulk branches');
  legend('Location', 'best');

end

%% ==================== Small utility helper ====================
% These helpers keep scalar diagnostic extraction robust for failed samples.

function val = LOCAL_min_or_nan(x)

  x = x(:);
  x = x(isfinite(x));
  if isempty(x)
    val = NaN;
  else
    val = min(x);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function val = LOCAL_max_or_nan(x)

  x = x(:);
  x = x(isfinite(x));
  if isempty(x)
    val = NaN;
  else
    val = max(x);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function val = LOCAL_get_field_or_nan(s, field_name)

  if isstruct(s) && isfield(s, field_name)
    val = s.(field_name);
  else
    val = NaN;
  end

end
