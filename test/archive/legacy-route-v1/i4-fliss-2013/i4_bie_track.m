function [result, negative_cases] = i4_bie_track(config, runtime)
% I4_BIE_TRACK Run the separate sharp-disk real-axis diagnostic.
%
% Purpose:
%   Reuse the public quasi-periodic BIE and Bloch-cell functions to scan a
%   missing-column sharp-disk surrogate.  Report projected-gap multipliers
%   and normalized singular-value dips without making a root or eigenvalue
%   claim.
%
% Input:
%   config  - Full experiment configuration from i4_fliss_config.
%   runtime - Struct with start_token and max_seconds fields.
%
% Output:
%   result         - Continuation scans and diagnostic summaries.
%   negative_cases - Homogeneous-lead and no-root-claim controls.
%
% Main algorithm:
%   For each real k, construct the one-cell scattering matrix with public
%   package functions, solve its Bloch pencil, classify near-unit
%   multipliers, and, only in a projected-gap sample, form the empty-cell
%   trace-matching matrix.  Its reported diagnostic is
%
%     sigma_min(A_def) / sigma_max(A_def).
%
% Based on:
%   tep_edc_projected_gap_scan.m and tep_edc_scan_local.m, while calling the
%   public +geom, +kernel, and +bloch functions without modifying them.
%
% Main changes:
%   Keep the continuation and normalized singular-value evaluator local to
%   this experiment and attach a permanent no-root-claim classification.
%
% Numerical goal:
%   Compare the behavior of a radius-0.2 sharp disk against Track A while
%   preserving the fact that the two material models are different.

  cfg = config.bie;
  LOCAL_check_deadline(runtime, 'Track B start');
  if cfg.s_values(1) ~= 1
    error('i4_bie_track:ContinuationOrder', ...
      'The contrast continuation must start at s=1.');
  end

  [C, curvelen, ~, ~] = geom.construct_cont(cfg.ntot, 'circle', ...
    0, 0, cfg.radius);
  geometry.C = C;
  geometry.curvelen = curvelen;

  result.model_id = cfg.model_id;
  result.claim_scope = cfg.claim_scope;
  result.root_claim_allowed = cfg.root_claim_allowed;
  result.profile = config.profile;
  result.continuation_rule = 'n(s)^2=1+16*s; ordered from s=1 downward';
  result.cases = repmat(LOCAL_empty_case(), length(cfg.beta), 1);

  for icase = 1:length(cfg.beta)
    one = LOCAL_empty_case();
    one.case_id = icase;
    one.case_name = cfg.case_name{icase};
    one.beta = cfg.beta(icase);
    one.reference_omega2 = cfg.reference_omega2(icase);
    one.reference_k = cfg.reference_k(icase);
    one.continuation = repmat(LOCAL_empty_continuation(), ...
      length(cfg.s_values), 1);
    active_window = cfg.k_windows(icase, :);

    for is = 1:length(cfg.s_values)
      s = cfg.s_values(is);
      LOCAL_check_deadline(runtime, sprintf( ...
        'Track B case %d continuation s=%.3g', icase, s));
      cont = LOCAL_scan_window(cfg, geometry, icase, s, ...
        active_window, runtime);
      one.continuation(is) = cont;
      if is < length(cfg.s_values) && isfinite(cont.best_dip_k)
        half_width = 0.5 * diff(cfg.k_windows(icase, :));
        active_window = cont.best_dip_k + [-half_width, half_width];
        active_window(1) = max(active_window(1), 1e-6);
      end
    end
    result.cases(icase) = one;
  end

  % --- required negative controls ---

  LOCAL_check_deadline(runtime, 'Track B homogeneous negative control');
  negative_grid = linspace(cfg.k_windows(1, 1), ...
    cfg.k_windows(1, 2), 5);
  homogeneous = repmat(LOCAL_empty_sample(), length(negative_grid), 1);
  for j = 1:length(negative_grid)
    homogeneous(j) = LOCAL_evaluate_homogeneous_sample(cfg, 1, ...
      negative_grid(j), runtime);
  end
  num_successful = sum(strcmp({homogeneous.status}, 'ok'));
  num_gap = sum(strcmp({homogeneous.status}, 'ok') & ...
    [homogeneous.count_unit] == 0);
  negative_cases = repmat(LOCAL_empty_negative(), 2, 1);
  negative_cases(1).track = 'B';
  negative_cases(1).name = 'homogeneous-medium-no-projected-gap';
  negative_cases(1).value = num_gap;
  negative_cases(1).threshold = 0;
  negative_cases(1).pass = ...
    num_successful == length(homogeneous) && num_gap == 0;
  negative_cases(1).detail = ...
    ['The exact s=0 homogeneous limit must retain propagating bulk modes ', ...
    'at every control sample.'];

  negative_cases(2).track = 'B';
  negative_cases(2).name = 'singular-value-dip-is-not-a-root';
  negative_cases(2).value = double(cfg.root_claim_allowed);
  negative_cases(2).threshold = 0;
  negative_cases(2).pass = ~cfg.root_claim_allowed;
  negative_cases(2).detail = ...
    'Every BIE candidate remains a real-axis singular-value diagnostic only.';

  result.homogeneous_negative_samples = homogeneous;
  result.completed = true;
  result.negative_controls_pass = all([negative_cases.pass]);
  continuations = repmat(LOCAL_empty_continuation(), 0, 1);
  for icase = 1:length(result.cases)
    continuations = [continuations; ...
      result.cases(icase).continuation(:)]; %#ok<AGROW>
  end
  result.mode_completeness_blocked = ...
    any([continuations.num_bad_count] > 0) || ...
    any([continuations.num_incomplete_modes] > 0);
  if result.mode_completeness_blocked
    result.scientific_decision = 'BIE_MODE_COMPLETENESS_BLOCKED';
  else
    result.scientific_decision = 'BIE_DIAGNOSTIC_COMPLETE_NO_ROOT_CLAIM';
  end
end

%% ==================== Continuation scan ====================
% These helpers scan, refine, and summarize one contrast parameter.

function cont = LOCAL_scan_window(cfg, geometry, case_id, s, window, runtime)
  k_grid = linspace(window(1), window(2), cfg.num_k);
  coarse = repmat(LOCAL_empty_sample(), length(k_grid), 1);
  for j = 1:length(k_grid)
    coarse(j) = LOCAL_evaluate_sample(cfg, geometry, case_id, s, ...
      k_grid(j), 'coarse', runtime);
  end

  finite_idx = find(isfinite([coarse.normalized_sigma]));
  refined = repmat(LOCAL_empty_sample(), 0, 1);
  if ~isempty(finite_idx)
    values = [coarse(finite_idx).normalized_sigma];
    [~, local_best] = min(values);
    best_idx = finite_idx(local_best);
    left_idx = max(1, best_idx - 1);
    right_idx = min(length(k_grid), best_idx + 1);
    refine_grid = linspace(k_grid(left_idx), k_grid(right_idx), cfg.num_refine);
    refined = repmat(LOCAL_empty_sample(), length(refine_grid), 1);
    for j = 1:length(refine_grid)
      refined(j) = LOCAL_evaluate_sample(cfg, geometry, case_id, s, ...
        refine_grid(j), 'refine', runtime);
    end
  end

  all_samples = [coarse; refined];
  all_values = [all_samples.normalized_sigma];
  finite_all = find(isfinite(all_values));
  best_k = NaN;
  best_value = NaN;
  best_raw = NaN;
  if ~isempty(finite_all)
    [best_value, local_best] = min(all_values(finite_all));
    best_sample = all_samples(finite_all(local_best));
    best_k = best_sample.k_real;
    best_raw = best_sample.raw_sigma;
  end

  cont.case_id = case_id;
  cont.s = s;
  cont.refractive_index = sqrt(1 + 16 * s);
  cont.k_window = window;
  cont.coarse = coarse;
  cont.refined = refined;
  cont.gap_intervals = LOCAL_gap_intervals(coarse, cfg.unit_tol);
  cont.best_dip_k = best_k;
  cont.best_normalized_sigma = best_value;
  cont.best_raw_sigma = best_raw;
  cont.num_successful = sum(strcmp({all_samples.status}, 'ok'));
  cont.num_failed = sum(strcmp({all_samples.status}, 'failed'));
  cont.num_bad_count = sum(strcmp({all_samples.status}, 'bad-count'));
  evaluated = ~strcmp({all_samples.status}, 'failed') & ...
    ~strcmp({all_samples.status}, 'unset');
  cont.projected_gap_candidate_count = sum(evaluated & ...
    [all_samples.count_unit] == 0);
  cont.usable_gap_samples = sum(strcmp({all_samples.status}, 'ok') & ...
    [all_samples.count_unit] == 0);
  K_values = [all_samples.K];
  mode_values = [all_samples.num_modes];
  finite_mode_data = isfinite(K_values) & isfinite(mode_values);
  mode_deficit = max(2 * K_values(finite_mode_data) - ...
    mode_values(finite_mode_data), 0);
  cont.num_incomplete_modes = sum(mode_deficit);
  cont.num_incomplete_samples = sum(mode_deficit > 0);
  residuals = [all_samples.bloch_evp_residual];
  residuals = residuals(isfinite(residuals));
  if isempty(residuals)
    cont.maximum_bloch_residual = NaN;
    cont.bloch_residual_pass = false;
  else
    cont.maximum_bloch_residual = max(residuals);
    cont.bloch_residual_pass = ...
      cont.maximum_bloch_residual <= cfg.bloch_residual_tolerance;
  end
  cont.dip_warning = isfinite(best_value) && ...
    best_value <= cfg.normalized_sigma_warning;
  cont.root_claim = false;
  cont.classification = 'real-axis-singular-value-diagnostic';
  if cont.num_bad_count > 0 || cont.num_incomplete_modes > 0
    cont.completeness_decision = 'BIE_MODE_COMPLETENESS_BLOCKED';
  else
    cont.completeness_decision = 'BIE_MODE_COMPLETE';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function intervals = LOCAL_gap_intervals(samples, unit_tol)
  evaluated = ~strcmp({samples.status}, 'failed') & ...
    ~strcmp({samples.status}, 'unset');
  mask = evaluated & [samples.count_unit] == 0;
  intervals = repmat(struct('k_left', [], 'k_right', [], ...
    'num_samples', [], 'unit_tol', []), 0, 1);
  if ~any(mask)
    return;
  end
  k = [samples.k_real];
  j = 1;
  while j <= length(samples)
    if ~mask(j)
      j = j + 1;
      continue;
    end
    left = j;
    while j < length(samples) && mask(j + 1)
      j = j + 1;
    end
    right = j;
    entry.k_left = k(left);
    entry.k_right = k(right);
    entry.num_samples = right - left + 1;
    entry.unit_tol = unit_tol;
    intervals(end + 1, 1) = entry; %#ok<AGROW>
    j = j + 1;
  end
end

%% ==================== One-sample BIE diagnostic ====================
% These helpers reuse public package functions and assemble only A_def locally.

function sample = LOCAL_evaluate_sample(cfg, geometry, case_id, s, ...
    k_real, stage, runtime)
  sample = LOCAL_empty_sample();
  sample.case_id = case_id;
  sample.beta = cfg.beta(case_id);
  sample.s = s;
  sample.refractive_index = sqrt(1 + 16 * s);
  sample.k_real = k_real;
  sample.stage = stage;
  sample.root_claim = false;
  LOCAL_check_deadline(runtime, sprintf( ...
    'Track B k=%.8g before cell solve', k_real));

  try
    kext = k_real + 1i * cfg.eps_k;
    kint = sample.refractive_index * kext;
    pars1.k = kext;
    pars1.beta = sample.beta;
    pars1.d = cfg.period_y;
    pars1.periodic_axis = 'y';
    pars2.H = cfg.period_x / 2 + cfg.radius + cfg.proxy.padding;
    pars2.proxy_dist = cfg.proxy.proxy_dist;
    pars2.N_side = cfg.proxy.N_side;
    pars2.N_top = cfg.proxy.N_top;
    pars2.N_proxy_edge = cfg.proxy.N_proxy_edge;
    pars2.M_pw = cfg.proxy.M_pw;

    proxy = kernel.precomp_proxy(pars1, pars2);
    channels = bloch.rayleigh_channels(kext, sample.beta, ...
      cfg.period_y, cfg.M, cfg.period_x);
    S_cell = bloch.construct_S(geometry.C, kext, kint, pars1, proxy, ...
      geometry.curvelen, channels, -cfg.period_x / 2, cfg.period_x / 2);
    mode_opts.lambda_tol = cfg.unit_tol;
    mode_opts.normalize = 'V';
    modes = bloch.solve_modes(S_cell, mode_opts);
    lambda = modes.lambda(:);
    unit_distance = abs(abs(lambda) - 1);

    sample.status = 'ok';
    sample.K = channels.K;
    sample.num_modes = length(lambda);
    sample.count_unit = sum(unit_distance <= cfg.unit_tol);
    sample.min_unit_distance = LOCAL_min_or_nan(unit_distance);
    sample.count_right_decay = sum(abs(lambda) < 1 - cfg.unit_tol);
    sample.count_left_decay = sum(abs(lambda) > 1 + cfg.unit_tol);
    sample.cell_solve_residual = S_cell.solve_relative_residual_norm;
    sample.bloch_evp_residual = LOCAL_bloch_residual(modes);
    sample.minimum_abs_gamma = min(abs(channels.gamma_m));

    if sample.count_unit == 0
      traces = bloch.mode_traces(modes.lambda, modes.V, channels);
      select_opts.lambda_tol = cfg.lambda_tol;
      [D_plus, N_plus, selected_plus] = ...
        bloch.select_port_traces(modes, traces, '+', select_opts);
      [D_minus, N_minus, selected_minus] = ...
        bloch.select_port_traces(modes, traces, '-', select_opts);
      sample.count_selected_plus = selected_plus.numSelected;
      sample.count_selected_minus = selected_minus.numSelected;
      if selected_plus.numSelected == channels.K && ...
          selected_minus.numSelected == channels.K
        A_def = LOCAL_empty_defect_matrix(channels, cfg.period_x, ...
          D_minus, N_minus, D_plus, N_plus);
        singular_values = svd(A_def);
        sample.raw_sigma = singular_values(end);
        sample.matrix_norm_2 = singular_values(1);
        sample.normalized_sigma = singular_values(end) / ...
          max(singular_values(1), eps);
      else
        sample.status = 'bad-count';
      end
    end
  catch ME
    if strcmp(ME.identifier, 'i4_bie_track:RuntimeCap')
      rethrow(ME);
    end
    sample.status = 'failed';
    sample.error_id = ME.identifier;
    sample.error_message = strrep(ME.message, sprintf('\n'), ' ');
  end
  LOCAL_check_deadline(runtime, sprintf( ...
    'Track B k=%.8g after cell solve', k_real));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sample = LOCAL_evaluate_homogeneous_sample(cfg, case_id, ...
    k_real, runtime)
  sample = LOCAL_empty_sample();
  sample.case_id = case_id;
  sample.beta = cfg.beta(case_id);
  sample.s = 0;
  sample.refractive_index = 1;
  sample.k_real = k_real;
  sample.stage = 'negative-analytic';
  sample.root_claim = false;
  LOCAL_check_deadline(runtime, sprintf( ...
    'Track B homogeneous k=%.8g', k_real));

  channels = bloch.rayleigh_channels(k_real, sample.beta, ...
    cfg.period_y, cfg.M, cfg.period_x);
  gamma = channels.gamma_m(:);
  propagation_tol = 100 * eps * max(1, max(abs(gamma)));
  propagating = abs(imag(gamma)) <= propagation_tol;
  num_propagating = sum(propagating);

  sample.status = 'ok';
  sample.K = channels.K;
  sample.num_modes = 2 * channels.K;
  sample.count_unit = 2 * num_propagating;
  if num_propagating > 0
    sample.min_unit_distance = 0;
  end
  sample.count_right_decay = channels.K - num_propagating;
  sample.count_left_decay = channels.K - num_propagating;
  sample.cell_solve_residual = 0;
  sample.bloch_evp_residual = 0;
  sample.minimum_abs_gamma = min(abs(gamma));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A_def = LOCAL_empty_defect_matrix(channels, width, ...
    D_minus, N_minus, D_plus, N_plus)
  K = channels.K;
  Gamma = diag(channels.gamma_m(:));
  E = diag(exp(1i * channels.gamma_m(:) * width));
  E_inv = diag(exp(-1i * channels.gamma_m(:) * width));
  I = eye(K);
  Z = zeros(K);
  A_def = [ ...
    I, I, -D_minus, Z; ...
    -1i * Gamma, 1i * Gamma, -N_minus, Z; ...
    E, E_inv, Z, -D_plus; ...
    1i * Gamma * E, -1i * Gamma * E_inv, Z, -N_plus];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_bloch_residual(modes)
  if isempty(modes.lambda)
    value = NaN;
    return;
  end
  left = modes.A_sc * modes.V;
  right = modes.B_sc * bsxfun(@times, modes.V, modes.lambda.');
  value = norm(left - right, 'fro') / ...
    max(norm(left, 'fro') + norm(right, 'fro'), eps);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_min_or_nan(values)
  if isempty(values)
    value = NaN;
  else
    value = min(values);
  end
end

%% ==================== Runtime and schema helpers ====================
% These helpers enforce the runtime cap and initialize stable output schemas.

function LOCAL_check_deadline(runtime, label)
  elapsed = toc(runtime.start_token);
  if elapsed >= runtime.max_seconds
    error('i4_bie_track:RuntimeCap', ...
      'Runtime cap reached after %.1f seconds before %s.', elapsed, label);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function one = LOCAL_empty_case()
  one = struct('case_id', [], 'case_name', '', 'beta', [], ...
    'reference_omega2', [], 'reference_k', [], 'continuation', []);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cont = LOCAL_empty_continuation()
  cont = struct('case_id', [], 's', [], 'refractive_index', [], ...
    'k_window', [], 'coarse', [], 'refined', [], 'gap_intervals', [], ...
    'best_dip_k', NaN, 'best_normalized_sigma', NaN, ...
    'best_raw_sigma', NaN, 'num_successful', [], 'num_failed', [], ...
    'num_bad_count', [], 'projected_gap_candidate_count', [], ...
    'usable_gap_samples', [], ...
    'num_incomplete_modes', [], 'num_incomplete_samples', [], ...
    'maximum_bloch_residual', NaN, ...
    'bloch_residual_pass', false, 'dip_warning', false, ...
    'root_claim', false, 'classification', '', ...
    'completeness_decision', '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sample = LOCAL_empty_sample()
  sample = struct( ...
    'case_id', [], 'beta', NaN, 's', NaN, 'refractive_index', NaN, ...
    'k_real', NaN, 'stage', '', 'status', 'unset', 'error_id', '', ...
    'error_message', '', 'K', NaN, 'num_modes', NaN, ...
    'count_unit', NaN, 'min_unit_distance', NaN, ...
    'count_right_decay', NaN, 'count_left_decay', NaN, ...
    'count_selected_plus', NaN, 'count_selected_minus', NaN, ...
    'raw_sigma', NaN, 'normalized_sigma', NaN, 'matrix_norm_2', NaN, ...
    'cell_solve_residual', NaN, 'bloch_evp_residual', NaN, ...
    'minimum_abs_gamma', NaN, 'root_claim', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_empty_negative()
  row = struct('track', '', 'name', '', 'value', [], 'threshold', [], ...
    'pass', false, 'detail', '');
end
