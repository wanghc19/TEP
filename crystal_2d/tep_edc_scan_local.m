function varargout = tep_edc_scan_local(user_opts)
% TEP_EDC_SCAN_LOCAL Recursively scan an empty-defect Bloch matching system.
%
% Purpose:
%   Run a recursive local real-k scan for the missing-column /
%   empty-defect-cell cavity problem.  The center cell is homogeneous
%   background material, and the positive and negative half-leads are
%   identical periodic cells with a circular dielectric inclusion.
%
% Mathematical problem:
%   The center empty cell occupies X0_minus <= x <= X0_plus and is expanded
%   in the y-quasiperiodic Rayleigh basis.  The left/right notation L/R is
%   reserved for the walls of one lead cell.  The port signs +/- denote the
%   center positive/negative ports and the positive/negative half-leads.
%
% Unknown vector:
%   The homogeneous system uses
%
%     [c_plus; c_minus; a_minus; a_plus].
%
%   Here c_plus and c_minus are right-going and left-going Rayleigh
%   coefficients in the center empty cell.  They do not denote positive and
%   negative half-leads.
%
% Matrix formula:
%   Let K = 2*M + 1, Gamma = diag(gamma_m),
%
%     E = diag(exp(1i*gamma_m*L0)),  E_inv = inv(E),
%     L0 = X0_plus - X0_minus.
%
%   The center empty-cell traces are
%
%     D0_minus = c_plus + c_minus,
%     N0_minus = -1i*Gamma*(c_plus - c_minus),
%     D0_plus  = E*c_plus + E_inv*c_minus,
%     N0_plus  = 1i*Gamma*(E*c_plus - E_inv*c_minus).
%
%   Matching these traces to selected outgoing lead traces gives
%
%     D0_minus = D_out_minus*a_minus,
%     N0_minus = N_out_minus*a_minus,
%     D0_plus  = D_out_plus*a_plus,
%     N0_plus  = N_out_plus*a_plus.
%
%   Therefore the assembled matrix is
%
%     A_def =
%       [ I,           I,             -D_out_minus,   0;
%        -1i*Gamma,   1i*Gamma,      -N_out_minus,   0;
%         E,           E_inv,          0,            -D_out_plus;
%         1i*Gamma*E, -1i*Gamma*E_inv, 0,            -N_out_plus ].
%
% Scan target:
%   Use +scan to first sample sigma_min = min(svd(A_def)) on a coarse real-k
%   grid inside [k_margin, beta - k_margin], collect several local-minimum
%   candidates, then recursively refine each candidate independently.  Samples
%   with incorrect outgoing mode counts are marked invalid and are not used as
%   minima.
%
% Input:
%   user_opts - Optional struct whose fields override the default parameters
%               in LOCAL_default_params.  For example,
%
%                 tep_edc_scan_local(struct('beta', 0.6, ...
%                   'initial_interval', [0.05, 0.55], ...
%                   'num_k_coarse', 41, 'make_plot', false))
%
%               The legacy field num_k, when supplied, sets both
%               num_k_coarse and num_k_refine.

  if nargin < 1 || isempty(user_opts)
    user_opts = struct();
  end

  format long;

  % --- stage 1: set user parameters ---

  params = LOCAL_default_params();
  params = LOCAL_apply_user_options(params, user_opts);
  params = LOCAL_apply_backward_compatibility(params);
  params = LOCAL_finalize_params(params, user_opts);
  LOCAL_validate_params(params);
  LOCAL_print_run_header(params);

  % --- stage 2: build lead geometry and objective context ---

  geom_data = LOCAL_build_lead_geometry(params);
  ctx = params;
  ctx.geom_data = geom_data;
  objective = @(k_real) LOCAL_empty_defect_sigma_min(k_real, ctx);

  % --- stage 3: coarse scan, dip selection, and local refinement ---

  scan_result = LOCAL_run_candidate_scan(objective, params);

  % --- stage 4: report ranked candidates and diagnostics ---

  LOCAL_print_scan_result(scan_result, params);

  % --- stage 5: plot scan result ---

  if params.make_plot
    LOCAL_plot_scan_result(scan_result, params);
  end

  fprintf('\nFinished recursive empty-defect scan.\n');

  if nargout > 0
    varargout{1} = scan_result;
  end
  if nargout > 1
    varargout{2} = scan_result.coarse;
  end
  if nargout > 2
    varargout{3} = scan_result.candidates;
  end

end

%% ==================== Parameter helper ====================
% These helpers define, normalize, validate, and print run parameters.

function params = LOCAL_default_params()

  % Circular inclusion discretization for each periodic lead cell.
  params.ntot = 60;
  params.flag_geom = 'circle';
  params.radius = 0.4;
  params.ellipse_a = 0.4;
  params.ellipse_b = 0.4;

  % Exterior/background and interior refractive-index ratio for the lead
  % cylinder.  The empty defect cell uses only the exterior/background medium.
  params.n = 3.0;

  % Physical periods.  L is the x-period of one lead cell and d is the
  % y-period used by the quasiperiodic Rayleigh basis.
  params.L = 2.0;
  params.d = 2 * pi;

  % Fixed y-quasiperiodic parameter.  The default value is set to the
  % strongest candidate found by the Octave rough scan:
  % beta = 0.8, n = 3.0, radius = 0.4, with a dip near k = 0.2.
  params.beta = 0.8;
  params.k_margin = 1e-3;
  params.projected_gap_interval = [0.18, 0.22];
  % params.projected_gap_interval = [params.k_margin, params.beta - params.k_margin];

  % Small imaginary offset used in kext = k_real + 1i*eps_k for mode
  % selection near delicate real-k samples.
  params.eps_k = 1e-8;

  % Rayleigh truncation half-width.  The basis uses K = 2*M + 1 channels.
  params.M = 7;

  % Recursive scan controls.  The coarse grid finds candidate dips over the
  % whole initial interval, while the refinement grid only narrows local
  % intervals around each candidate.  These grids should not generally use
  % the same number of points; odd values give a clear center sample.
  params.num_k_coarse = 25;
  params.num_k_refine = 9;
  params.max_candidates = 2;
  params.max_refine_level = 3;

  % Spike diagnostics for the coarse scan.  A local minimum with
  % sigma(i) < spike_ratio*min(sigma(i-1), sigma(i+1)) is kept, but marked as
  % spike_like so it can be interpreted separately from smoother dips.
  params.enable_spike_filter = true;
  params.spike_ratio = 1e-2;
  params.refine_spike_like = true;

  % Plot scaling.  Use a logarithmic y-axis by default so small singular
  % value dips are visible across several orders of magnitude.
  params.plot_log_y = true;
  params.make_plot = true;

  % Lead-cell and center-empty-cell wall coordinates.  L/R denotes lead-cell
  % walls only; +/- denotes center ports and half-leads.
  params.X_L = -params.L / 2;
  params.X_R = params.L / 2;
  params.X0_minus = -params.L / 2;
  params.X0_plus = params.L / 2;
  params.L0 = params.X0_plus - params.X0_minus;

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

  % Mode-selection tolerance for outgoing half-lead traces.
  params.opts.lambda_tol = 1e-11;

  params.initial_interval = params.projected_gap_interval;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params = LOCAL_apply_user_options(params, user_opts)

  option_names = fieldnames(user_opts);
  for j = 1:length(option_names)
    name = option_names{j};
    value = user_opts.(name);
    if strcmp(name, 'num_k')
      params.num_k_coarse = value;
      params.num_k_refine = value;
    elseif isfield(params, name)
      params.(name) = value;
    else
      error('tep_edc_scan_local:UnknownOption', ...
        'Unknown option ''%s''.', name);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params = LOCAL_apply_backward_compatibility(params)

  if isfield(params, 'num_k')
    used_deprecated = false;
    if ~isfield(params, 'num_k_coarse')
      params.num_k_coarse = params.num_k;
      used_deprecated = true;
    end
    if ~isfield(params, 'num_k_refine')
      params.num_k_refine = params.num_k;
      used_deprecated = true;
    end
    if used_deprecated
      warning('tep_edc_scan_local:DeprecatedNumK', ...
        'params.num_k is deprecated; use params.num_k_coarse and params.num_k_refine.');
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params = LOCAL_finalize_params(params, user_opts)

  if ~isfield(user_opts, 'X_L')
    params.X_L = -params.L / 2;
  end
  if ~isfield(user_opts, 'X_R')
    params.X_R = params.L / 2;
  end
  if ~isfield(user_opts, 'X0_minus')
    params.X0_minus = -params.L / 2;
  end
  if ~isfield(user_opts, 'X0_plus')
    params.X0_plus = params.L / 2;
  end
  if ~isfield(user_opts, 'L0')
    params.L0 = params.X0_plus - params.X0_minus;
  end

  if ~isfield(user_opts, 'pars1')
    params.pars1.beta = params.beta;
    params.pars1.d = params.d;
    params.pars1.periodic_axis = 'y';
  end
  if ~isfield(user_opts, 'pars2')
    params.pars2.H = params.L / 2 + LOCAL_geometry_x_extent(params) + 0.4;
    params.pars2.proxy_dist = 0.7;
    params.pars2.N_side = 40;
    params.pars2.N_top = 40;
    params.pars2.N_proxy_edge = 24;
    params.pars2.M_pw = 8;
  end

  user_set_interval = isfield(user_opts, 'initial_interval') || ...
    isfield(user_opts, 'projected_gap_interval');
  if ~user_set_interval && LOCAL_user_changed_projected_gap_source(user_opts)
    params.projected_gap_interval = [params.k_margin, params.beta - params.k_margin];
  end
  if isfield(user_opts, 'initial_interval')
    params.initial_interval = user_opts.initial_interval;
  else
    params.initial_interval = params.projected_gap_interval;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = LOCAL_user_changed_projected_gap_source(user_opts)

  names = {'beta', 'L', 'd', 'n', 'flag_geom', 'radius', ...
    'ellipse_a', 'ellipse_b', 'k_margin'};
  tf = false;
  for j = 1:length(names)
    if isfield(user_opts, names{j})
      tf = true;
      return;
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x_extent = LOCAL_geometry_x_extent(params)

  if strcmp(params.flag_geom, 'circle')
    x_extent = params.radius;
  elseif strcmp(params.flag_geom, 'ellipse')
    x_extent = params.ellipse_a;
  else
    x_extent = params.radius;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_params(params)

  if params.initial_interval(2) <= params.initial_interval(1)
    error('tep_edc_scan_local:InvalidScanInterval', ...
      'beta must be larger than 2*k_margin.');
  end
  if params.num_k_coarse < 3 || params.num_k_coarse ~= floor(params.num_k_coarse)
    error('tep_edc_scan_local:InvalidNumK', ...
      'num_k_coarse must be an integer at least 3.');
  end
  if params.num_k_refine < 3 || params.num_k_refine ~= floor(params.num_k_refine)
    error('tep_edc_scan_local:InvalidNumK', ...
      'num_k_refine must be an integer at least 3.');
  end
  if mod(params.num_k_coarse, 2) == 0 || mod(params.num_k_refine, 2) == 0
    warning('tep_edc_scan_local:EvenGridSize', ...
      'Odd num_k_coarse and num_k_refine values are recommended.');
  end
  if params.max_candidates < 1 || params.max_candidates ~= floor(params.max_candidates)
    error('tep_edc_scan_local:InvalidMaxCandidates', ...
      'max_candidates must be a positive integer.');
  end
  if params.max_refine_level < 1 || ...
      params.max_refine_level ~= floor(params.max_refine_level)
    error('tep_edc_scan_local:InvalidMaxRefineLevel', ...
      'max_refine_level must be a positive integer.');
  end
  if params.spike_ratio <= 0 || ~isfinite(params.spike_ratio)
    error('tep_edc_scan_local:InvalidSpikeRatio', ...
      'spike_ratio must be a positive finite number.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_run_header(params)

  fprintf('Running recursive empty-defect local scan\n');
  fprintf('  beta = %.16g, L = %.16g, d = %.16g\n', ...
    params.beta, params.L, params.d);
  fprintf('  M = %d, ntot = %d, num_k_coarse = %d, num_k_refine = %d\n', ...
    params.M, params.ntot, params.num_k_coarse, params.num_k_refine);
  fprintf('  max_candidates = %d, max_refine_level = %d\n', ...
    params.max_candidates, params.max_refine_level);
  fprintf('  k_margin = %.3e, eps_k = %.3e\n', ...
    params.k_margin, params.eps_k);
  fprintf('  initial interval = [%.16g, %.16g]\n', ...
    params.initial_interval(1), params.initial_interval(2));
  fprintf('  spike filter = %s, spike_ratio = %.3e, refine_spike_like = %s\n', ...
    LOCAL_tf_label(params.enable_spike_filter), params.spike_ratio, ...
    LOCAL_tf_label(params.refine_spike_like));

end

%% ==================== Geometry helper ====================
% This helper builds the boundary data shared by all scan samples.

function geom_data = LOCAL_build_lead_geometry(params)

  if strcmp(params.flag_geom, 'circle')
    [C, curvelen, ~, ~] = geom.construct_cont(params.ntot, ...
      params.flag_geom, 0, 0, params.radius);
  elseif strcmp(params.flag_geom, 'ellipse')
    [C, curvelen, ~, ~] = geom.construct_cont(params.ntot, ...
      params.flag_geom, 0, 0, params.ellipse_a, params.ellipse_b);
  else
    [C, curvelen, ~, ~] = geom.construct_cont(params.ntot, ...
      params.flag_geom, 0, 0);
  end

  geom_data.C = C;
  geom_data.curvelen = curvelen;

end

%% ==================== Candidate scan helper ====================
% These helpers run the coarse scan, collect local minima, and refine them.

function scan_result = LOCAL_run_candidate_scan(objective, params)

  opts = scan.default_options( ...
    'num_initial_points', params.num_k_coarse, ...
    'num_refine_points', params.num_k_refine, ...
    'ignore_nan', true, ...
    'verbose', false);

  k_grid = linspace(params.initial_interval(1), params.initial_interval(2), ...
    params.num_k_coarse);
  [sigma, info] = scan.eval_grid(objective, k_grid, opts);

  coarse = struct();
  coarse.k_grid = k_grid;
  coarse.sigma = sigma;
  coarse.info = info;
  coarse.x_grid = k_grid;
  coarse.values = sigma;
  coarse.infos = info;
  coarse.interval = params.initial_interval;
  coarse.num_finite = sum(isfinite(sigma(:)));
  coarse.num_invalid = LOCAL_count_invalid_samples(sigma);
  coarse.num_bad_count = LOCAL_count_status(info, 'bad_count');
  [coarse_candidates, num_local_minima] = ...
    LOCAL_find_coarse_candidates(k_grid, sigma, info, params);
  coarse.num_local_minima = num_local_minima;
  coarse.candidates = coarse_candidates;

  candidates = coarse_candidates;
  for j = 1:length(candidates)
    candidates(j) = LOCAL_refine_candidate(candidates(j), objective, ...
      k_grid, params, opts);
  end

  final_ranked = LOCAL_rank_final_candidates(candidates);
  scan_result = LOCAL_build_scan_result(coarse, candidates, final_ranked, ...
    params, opts);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [candidates, num_local_minima] = LOCAL_find_coarse_candidates( ...
    k_grid, sigma, info, params)

  candidates = repmat(LOCAL_empty_candidate(), 0, 1);
  num_local_minima = 0;

  for idx = 2:(length(k_grid) - 1)
    if isfinite(sigma(idx)) && isfinite(sigma(idx - 1)) && ...
        isfinite(sigma(idx + 1)) && sigma(idx) < sigma(idx - 1) && ...
        sigma(idx) < sigma(idx + 1)
      num_local_minima = num_local_minima + 1;
      candidate = LOCAL_make_coarse_candidate(idx, k_grid, sigma, info, ...
        false, params);
      candidates(end + 1, 1) = candidate;
    end
  end

  if isempty(candidates)
    [sigma_min, idx_min] = LOCAL_min_finite(sigma);
    if ~isnan(idx_min)
      candidate = LOCAL_make_coarse_candidate(idx_min, k_grid, sigma, info, ...
        true, params);
      candidate.initial_sigma = sigma_min;
      candidates = candidate;
    end
  end

  if isempty(candidates)
    return;
  end

  candidates = LOCAL_sort_candidates_by_sigma(candidates, 'initial_sigma');
  keep_count = min(params.max_candidates, length(candidates));
  candidates = candidates(1:keep_count);
  for j = 1:length(candidates)
    candidates(j).id = j;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidate = LOCAL_make_coarse_candidate(idx, k_grid, sigma, info, ...
    is_fallback, params)

  candidate = LOCAL_empty_candidate();
  candidate.id = NaN;
  candidate.coarse_idx = idx;
  candidate.initial_k = k_grid(idx);
  candidate.initial_sigma = sigma(idx);
  candidate.endpoint_flag = LOCAL_endpoint_label(idx, length(k_grid));
  candidate.is_endpoint = ~strcmp(candidate.endpoint_flag, 'none');
  candidate.is_fallback = is_fallback;
  candidate.kind = 'local_min';
  if is_fallback
    candidate.kind = 'fallback_global_min';
  end
  candidate.spike_like = LOCAL_is_spike_like(idx, sigma, params);
  candidate.coarse_bad_count_nearby = LOCAL_has_bad_count_nearby(idx, info);
  candidate.levels = repmat(LOCAL_empty_level_entry(), 0, 1);
  candidate.final_k = candidate.initial_k;
  candidate.final_sigma = candidate.initial_sigma;
  candidate.final_interval = [];
  candidate.final_interval_width = NaN;
  candidate.final_level = 0;
  candidate.any_bad_count_nearby = candidate.coarse_bad_count_nearby;
  candidate.skipped = false;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidate = LOCAL_refine_candidate(candidate, objective, coarse_grid, ...
    params, opts)

  current_interval = LOCAL_neighbor_interval(coarse_grid, candidate.coarse_idx, ...
    params.initial_interval);

  if candidate.spike_like && ~params.refine_spike_like
    candidate.skipped = true;
    candidate.final_interval = current_interval;
    candidate.final_interval_width = current_interval(2) - current_interval(1);
    return;
  end

  levels = repmat(LOCAL_empty_level_entry(), params.max_refine_level, 1);
  completed_levels = 0;
  prev_sigma = candidate.initial_sigma;

  for level = 1:params.max_refine_level
    k_grid = linspace(current_interval(1), current_interval(2), ...
      params.num_k_refine);
    [sigma, info] = scan.eval_grid(objective, k_grid, opts);
    [sigma_min, idx_min] = LOCAL_min_finite(sigma);

    entry = LOCAL_make_level_entry(level, current_interval, k_grid, sigma, ...
      info, idx_min, sigma_min, prev_sigma);
    levels(level) = entry;
    completed_levels = level;

    if entry.bad_count_count > 0
      candidate.any_bad_count_nearby = true;
    end
    if ~isfinite(sigma_min)
      break;
    end

    candidate.final_k = entry.k_min;
    candidate.final_sigma = entry.sigma_min;
    candidate.final_interval = entry.interval;
    candidate.final_interval_width = entry.interval_width;
    candidate.final_level = level;
    prev_sigma = sigma_min;

    if level < params.max_refine_level
      current_interval = scan.build_refined_interval(k_grid, idx_min);
      current_interval = LOCAL_clamp_interval(current_interval, ...
        params.initial_interval);
    end
  end

  candidate.levels = levels(1:completed_levels);
  if isempty(candidate.final_interval)
    candidate.final_interval = current_interval;
    candidate.final_interval_width = current_interval(2) - current_interval(1);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function entry = LOCAL_make_level_entry(level, interval, k_grid, sigma, info, ...
    idx_min, sigma_min, prev_sigma)

  entry = LOCAL_empty_level_entry();
  entry.level = level;
  entry.interval = interval;
  entry.interval_width = interval(2) - interval(1);
  entry.k_grid = k_grid;
  entry.sigma = sigma;
  entry.info = info;
  entry.x_grid = k_grid;
  entry.values = sigma;
  entry.infos = info;
  entry.idx_min = idx_min;
  entry.sigma_min = sigma_min;
  entry.value_min = sigma_min;
  entry.invalid_count = LOCAL_count_invalid_samples(sigma);
  entry.bad_count_count = LOCAL_count_status(info, 'bad_count');

  if isnan(idx_min)
    entry.k_min = NaN;
    entry.x_min = NaN;
    entry.endpoint_flag = 'all_nan';
  else
    entry.k_min = k_grid(idx_min);
    entry.x_min = entry.k_min;
    entry.endpoint_flag = LOCAL_endpoint_label(idx_min, length(k_grid));
  end

  if isfinite(prev_sigma) && isfinite(sigma_min) && prev_sigma ~= 0
    entry.rel_improvement = (prev_sigma - sigma_min) / prev_sigma;
  else
    entry.rel_improvement = NaN;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function final_ranked = LOCAL_rank_final_candidates(candidates)

  final_ranked = repmat(LOCAL_empty_rank_entry(), 0, 1);
  for j = 1:length(candidates)
    entry = LOCAL_empty_rank_entry();
    entry.rank = NaN;
    entry.candidate_id = candidates(j).id;
    entry.final_k = candidates(j).final_k;
    entry.final_sigma = candidates(j).final_sigma;
    entry.initial_k = candidates(j).initial_k;
    entry.initial_sigma = candidates(j).initial_sigma;
    entry.spike_like = candidates(j).spike_like;
    entry.any_bad_count_nearby = candidates(j).any_bad_count_nearby;
    entry.final_interval_width = candidates(j).final_interval_width;
    final_ranked(end + 1, 1) = entry;
  end

  if isempty(final_ranked)
    return;
  end

  sigma_values = [final_ranked.final_sigma];
  sigma_values(~isfinite(sigma_values)) = Inf;
  [~, order] = sort(sigma_values);
  final_ranked = final_ranked(order);
  for j = 1:length(final_ranked)
    final_ranked(j).rank = j;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function scan_result = LOCAL_build_scan_result(coarse, candidates, final_ranked, ...
    params, opts)

  scan_result = struct();
  scan_result.coarse = coarse;
  scan_result.candidates = candidates;
  scan_result.final_ranked = final_ranked;
  scan_result.params = params;
  scan_result.opts = opts;
  scan_result.history = candidates;
  scan_result.success = false;
  scan_result.message = 'No finite candidate was refined.';
  scan_result.best_x = NaN;
  scan_result.best_value = NaN;
  scan_result.best_level = NaN;
  scan_result.best_interval = [];

  if isempty(final_ranked) || ~isfinite(final_ranked(1).final_sigma)
    return;
  end

  best_id = final_ranked(1).candidate_id;
  best_idx = find([candidates.id] == best_id, 1);
  scan_result.success = true;
  scan_result.message = 'Candidate refinement completed.';
  scan_result.best_x = final_ranked(1).final_k;
  scan_result.best_value = final_ranked(1).final_sigma;
  scan_result.best_level = candidates(best_idx).final_level;
  scan_result.best_interval = candidates(best_idx).final_interval;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidate = LOCAL_empty_candidate()

  candidate = struct( ...
    'id', [], ...
    'coarse_idx', [], ...
    'initial_k', [], ...
    'initial_sigma', [], ...
    'endpoint_flag', '', ...
    'is_endpoint', false, ...
    'is_fallback', false, ...
    'kind', '', ...
    'spike_like', false, ...
    'coarse_bad_count_nearby', false, ...
    'levels', [], ...
    'final_k', [], ...
    'final_sigma', [], ...
    'final_interval', [], ...
    'final_interval_width', [], ...
    'final_level', [], ...
    'any_bad_count_nearby', false, ...
    'skipped', false);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function entry = LOCAL_empty_level_entry()

  entry = struct( ...
    'level', [], ...
    'interval', [], ...
    'interval_width', [], ...
    'k_grid', [], ...
    'sigma', [], ...
    'info', [], ...
    'x_grid', [], ...
    'values', [], ...
    'infos', [], ...
    'idx_min', [], ...
    'k_min', [], ...
    'x_min', [], ...
    'sigma_min', [], ...
    'value_min', [], ...
    'rel_improvement', [], ...
    'endpoint_flag', '', ...
    'invalid_count', [], ...
    'bad_count_count', []);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function entry = LOCAL_empty_rank_entry()

  entry = struct( ...
    'rank', [], ...
    'candidate_id', [], ...
    'final_k', [], ...
    'final_sigma', [], ...
    'initial_k', [], ...
    'initial_sigma', [], ...
    'spike_like', false, ...
    'any_bad_count_nearby', false, ...
    'final_interval_width', []);

end

%% ==================== Objective helper ====================
% These helpers evaluate and assemble the empty-defect matrix objective.

function [sigma_min, info] = LOCAL_empty_defect_sigma_min(k_real, ctx)

  info = LOCAL_empty_point_info();
  info.status = 'ok';

  kext = k_real + 1i * ctx.eps_k;
  kint = ctx.n * kext;
  pars1 = ctx.pars1;
  pars1.k = kext;
  proxy = kernel.precomp_proxy(pars1, ctx.pars2);
  rayleighchan = bloch.rayleigh_channels(kext, ctx.beta, ctx.d, ctx.M, ctx.L);
  K = rayleighchan.K;

  % --- stage 4: construct Bloch modes and select port traces ---

  S_cell = bloch.construct_S(ctx.geom_data.C, kext, kint, pars1, proxy, ...
    ctx.geom_data.curvelen, rayleighchan, ctx.X_L, ctx.X_R);
  modes = bloch.solve_modes(S_cell);
  traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);
  [D_out_plus, N_out_plus, selected_plus] = ...
    bloch.select_port_traces(modes, traces, '+', ctx.opts);
  [D_out_minus, N_out_minus, selected_minus] = ...
    bloch.select_port_traces(modes, traces, '-', ctx.opts);

  info.K = K;
  info.K_out_plus = selected_plus.numSelected;
  info.K_out_minus = selected_minus.numSelected;

  if info.K_out_plus ~= K || info.K_out_minus ~= K
    info.status = 'bad_count';
    sigma_min = NaN;
    return;
  end

  % --- stage 5: assemble empty-defect matrix ---

  A_def = LOCAL_assemble_empty_defect_matrix(rayleighchan, ctx.L0, ...
    D_out_minus, N_out_minus, D_out_plus, N_out_plus);
  expected_size = [4 * K, 2 * K + info.K_out_minus + info.K_out_plus];
  A_size = size(A_def);
  info.A_rows = A_size(1);
  info.A_cols = A_size(2);

  if ~isequal(A_size, expected_size)
    info.status = 'badsize';
    sigma_min = NaN;
    return;
  end

  % --- stage 6: compute singular values and report candidates ---

  s = svd(A_def);
  if isempty(s)
    info.status = 'emptysvd';
    sigma_min = NaN;
  else
    sigma_min = min(s);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A_def = LOCAL_assemble_empty_defect_matrix(rayleighchan, L0, ...
    D_out_minus, N_out_minus, D_out_plus, N_out_plus)

  K = rayleighchan.K;
  K_out_minus = size(D_out_minus, 2);
  K_out_plus = size(D_out_plus, 2);
  Gamma = diag(rayleighchan.gamma_m(:));
  E = diag(exp(1i * rayleighchan.gamma_m(:) * L0));
  E_inv = diag(exp(-1i * rayleighchan.gamma_m(:) * L0));
  I_K = eye(K);
  Z_minus = zeros(K, K_out_minus);
  Z_plus = zeros(K, K_out_plus);

  A_def = [
    I_K, I_K, -D_out_minus, Z_plus;
    -1i * Gamma, 1i * Gamma, -N_out_minus, Z_plus;
    E, E_inv, Z_minus, -D_out_plus;
    1i * Gamma * E, -1i * Gamma * E_inv, Z_minus, -N_out_plus
  ];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function info = LOCAL_empty_point_info()

  info = struct( ...
    'K', NaN, ...
    'K_out_plus', NaN, ...
    'K_out_minus', NaN, ...
    'A_rows', NaN, ...
    'A_cols', NaN, ...
    'status', 'unset');

end

%% ==================== Reporting helper ====================
% These helpers print coarse, per-candidate, and final ranked diagnostics.

function LOCAL_print_scan_result(scan_result, params)

  coarse = scan_result.coarse;

  fprintf('\nCoarse scan summary:\n');
  fprintf('  interval = [%.16g, %.16g]\n', ...
    coarse.interval(1), coarse.interval(2));
  fprintf('  num_k_coarse = %d\n', params.num_k_coarse);
  fprintf('  finite samples = %d / %d\n', coarse.num_finite, ...
    numel(coarse.sigma));
  fprintf('  invalid samples = %d, bad_count samples = %d\n', ...
    coarse.num_invalid, coarse.num_bad_count);
  fprintf('  local minima found = %d, selected candidates = %d\n', ...
    coarse.num_local_minima, length(coarse.candidates));

  fprintf('\nTop coarse candidates:\n');
  if isempty(coarse.candidates)
    fprintf('  No finite coarse candidates were found.\n');
  else
    fprintf('  id        k_real             sigma_min          endpoint  spike_like  kind\n');
    for j = 1:length(coarse.candidates)
      cand = coarse.candidates(j);
      fprintf('  %2d  %.16f  %.8e  %-8s  %-10s  %s\n', ...
        cand.id, cand.initial_k, cand.initial_sigma, cand.endpoint_flag, ...
        LOCAL_tf_label(cand.spike_like), cand.kind);
    end
  end

  for j = 1:length(scan_result.candidates)
    LOCAL_print_candidate_summary(scan_result.candidates(j));
  end

  LOCAL_print_final_ranked(scan_result);

  if scan_result.success
    fprintf('\nFinal best result: candidate %d, level %d, k_real = %.16f, eps_k = %.6e, sigma_min = %.16e\n', ...
      scan_result.final_ranked(1).candidate_id, scan_result.best_level, ...
      scan_result.best_x, params.eps_k, scan_result.best_value);
  else
    fprintf('\nNo finite final candidate was found: %s\n', scan_result.message);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_candidate_summary(candidate)

  fprintf('\nCandidate %d refinement summary:\n', candidate.id);
  fprintf('  initial coarse k = %.16f, sigma_min = %.8e, kind = %s, spike_like = %s\n', ...
    candidate.initial_k, candidate.initial_sigma, candidate.kind, ...
    LOCAL_tf_label(candidate.spike_like));

  if candidate.skipped
    fprintf('  Refinement skipped because refine_spike_like is false.\n');
  elseif isempty(candidate.levels)
    fprintf('  No refinement levels were completed.\n');
  else
    fprintf('  level  interval left       interval right      width          k_min             sigma_min     rel_impr    endpoint  invalid  bad_count\n');
    for level = 1:length(candidate.levels)
      entry = candidate.levels(level);
      fprintf('  %5d  %.10f  %.10f  %.4e  %.10f  %.4e  %.3e  %-8s  %7d  %9d\n', ...
        entry.level, entry.interval(1), entry.interval(2), ...
        entry.interval_width, entry.k_min, entry.sigma_min, ...
        entry.rel_improvement, entry.endpoint_flag, entry.invalid_count, ...
        entry.bad_count_count);
    end
  end

  fprintf('  final k = %.16f, final sigma_min = %.8e, final interval width = %.4e\n', ...
    candidate.final_k, candidate.final_sigma, candidate.final_interval_width);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_final_ranked(scan_result)

  fprintf('\nFinal ranked candidate table:\n');
  if isempty(scan_result.final_ranked)
    fprintf('  No candidates to rank.\n');
    return;
  end

  fprintf('  rank  id        final k          final sigma      initial k        spike_like  bad_count_nearby  final width\n');
  for j = 1:length(scan_result.final_ranked)
    entry = scan_result.final_ranked(j);
    fprintf('  %4d  %2d  %.12f  %.6e  %.12f  %-10s  %-16s  %.4e\n', ...
      entry.rank, entry.candidate_id, entry.final_k, entry.final_sigma, ...
      entry.initial_k, LOCAL_tf_label(entry.spike_like), ...
      LOCAL_tf_label(entry.any_bad_count_nearby), entry.final_interval_width);
  end

end

%% ==================== Plotting helper ====================
% This helper displays the coarse scan and multi-candidate refinements.

function LOCAL_plot_scan_result(scan_result, params)

  figure('Name', 'Empty Defect Recursive Scan', 'Color', 'w');
  hold on;

  coarse = scan_result.coarse;
  plot(coarse.k_grid, coarse.sigma, 'k--', 'LineWidth', 1.0, ...
    'DisplayName', 'Coarse scan');

  candidates = scan_result.candidates;
  plot_count = min(params.max_candidates, length(candidates));
  cmap = lines(max(plot_count, 1));

  for j = 1:plot_count
    candidate = candidates(j);
    for level = 1:length(candidate.levels)
      entry = candidate.levels(level);
      if level == 1
        plot(entry.k_grid, entry.sigma, '-o', 'LineWidth', 1.2, ...
          'MarkerSize', 4, 'Color', cmap(j, :), ...
          'DisplayName', sprintf('Cand %d ref', candidate.id));
      else
        plot(entry.k_grid, entry.sigma, '-o', 'LineWidth', 1.2, ...
          'MarkerSize', 4, 'Color', cmap(j, :), ...
          'HandleVisibility', 'off');
      end
    end
    if isfinite(candidate.final_sigma)
      plot(candidate.final_k, candidate.final_sigma, 's', 'MarkerSize', 7, ...
        'MarkerFaceColor', cmap(j, :), 'MarkerEdgeColor', cmap(j, :), ...
        'HandleVisibility', 'off');
    end
  end

  if params.plot_log_y
    set(gca, 'YScale', 'log');
  end
  grid on;
  xlabel('Real wavenumber k_{real}', 'FontSize', 11);
  ylabel('\sigma_{min}(A_{def})', 'FontSize', 11);
  title(sprintf('Empty defect candidate scan: beta = %.4g, M = %d, ntot = %d, eps_k = %.1e', ...
    params.beta, params.M, params.ntot, params.eps_k), 'FontSize', 12);
  legend('Location', 'northeast');

end

%% ==================== Scan utility helper ====================
% These helpers provide small status, sorting, and interval utilities.

function n_invalid = LOCAL_count_invalid_samples(values)

  n_invalid = sum(~isfinite(values(:)));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function n_status = LOCAL_count_status(info, status)

  n_status = 0;
  for j = 1:numel(info)
    if LOCAL_info_has_status(info{j}, status)
      n_status = n_status + 1;
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = LOCAL_info_has_status(info, status)

  tf = isstruct(info) && isfield(info, 'status') && strcmp(info.status, status);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [value_min, idx_min] = LOCAL_min_finite(values)

  finite_idx = find(isfinite(values(:)));
  if isempty(finite_idx)
    value_min = NaN;
    idx_min = NaN;
    return;
  end

  flat_values = values(:);
  [value_min, local_idx] = min(flat_values(finite_idx));
  idx_min = finite_idx(local_idx);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidates = LOCAL_sort_candidates_by_sigma(candidates, field_name)

  sigma_values = NaN(length(candidates), 1);
  for j = 1:length(candidates)
    sigma_values(j) = candidates(j).(field_name);
  end
  sigma_values(~isfinite(sigma_values)) = Inf;
  [~, order] = sort(sigma_values);
  candidates = candidates(order);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = LOCAL_is_spike_like(idx, sigma, params)

  tf = false;
  if ~params.enable_spike_filter || idx <= 1 || idx >= length(sigma)
    return;
  end

  neighbor_min = min(sigma(idx - 1), sigma(idx + 1));
  if isfinite(sigma(idx)) && isfinite(neighbor_min) && neighbor_min > 0 && ...
      sigma(idx) < params.spike_ratio * neighbor_min
    tf = true;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tf = LOCAL_has_bad_count_nearby(idx, info)

  tf = false;
  left_idx = max(1, idx - 1);
  right_idx = min(numel(info), idx + 1);
  for j = left_idx:right_idx
    if LOCAL_info_has_status(info{j}, 'bad_count')
      tf = true;
      return;
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = LOCAL_endpoint_label(idx, npts)

  if isnan(idx)
    label = 'none';
  elseif idx <= 1
    label = 'left';
  elseif idx >= npts
    label = 'right';
  else
    label = 'none';
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function interval = LOCAL_neighbor_interval(k_grid, idx, bounds)

  interval = scan.build_refined_interval(k_grid, idx);
  interval = LOCAL_clamp_interval(interval, bounds);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function interval = LOCAL_clamp_interval(interval, bounds)

  interval(1) = max(interval(1), bounds(1));
  interval(2) = min(interval(2), bounds(2));
  if interval(2) <= interval(1)
    error('tep_edc_scan_local:InvalidRefinedInterval', ...
      'Refined interval collapsed after clamping.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = LOCAL_tf_label(tf)

  if tf
    label = 'yes';
  else
    label = 'no';
  end

end
