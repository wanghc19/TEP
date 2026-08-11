function results = run_bie_m4_m5_scan()
% RUN_BIE_M4_M5_SCAN Compare bounded real-axis A_def dips for M = 4 and 5.
%
% Purpose:
%   Run two independently gated sharp-disk scans on the same 49-point real
%   k grid, match strict interior local minima, and refine a matched pair in
%   bounded neighboring intervals.
%
% Output:
%   results - Coarse samples, strict minima, bounded refinements, agreement
%             gates, diagnostic label, and independent output paths.
%
% Main algorithm:
%   At every k and for each M, require 2K finite Bloch modes, K outgoing
%   traces on each side, no near-unit multiplier, and a normalized Bloch
%   pencil residual below tolerance before forming A_def.  A coarse point is
%   eligible only when it is a strict interior local minimum with usable
%   neighbors.  No endpoint or global-minimum fallback is allowed.
%
% Based on:
%   i4_bie_track.m and the public +geom, +kernel, and +bloch packages.
%
% Main changes:
%   Restrict the Rayleigh truncations to M = 4 and M = 5 and require a
%   cross-M location agreement before assigning the strongest diagnostic
%   label.
%
% Numerical goal:
%   Assign M4_M5_STABLE_REAL_AXIS_DIP_DIAGNOSTIC only when both scans have
%   a matched strict coarse minimum, both bounded refinements retain a
%   strict interior minimum, and their final k positions differ by at most
%   one coarse step.

  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  addpath(repo_root);
  output_dir = fullfile(here, 'output', 'bie-m4-m5-scan');
  if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
  end

  log_path = fullfile(output_dir, 'run.log');
  diary('off');
  if exist(log_path, 'file') == 2
    delete(log_path);
  end
  diary(log_path);
  diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
  start_token = tic;

  % --- stage 1: frozen physical and numerical parameters ---

  config.model_id = 'sharp-disk-bie-m4-m5-real-axis-v1';
  config.claim_scope = 'bounded-real-axis-dip-diagnostic-only';
  config.strongest_label = 'M4_M5_STABLE_REAL_AXIS_DIP_DIAGNOSTIC';
  config.blocked_label = 'M4_M5_REAL_AXIS_DIP_DIAGNOSTIC_BLOCKED';
  config.k_interval = [1.55, 2.15];
  config.num_k = 49;
  config.k_grid = linspace(config.k_interval(1), ...
    config.k_interval(2), config.num_k).';
  config.coarse_step = config.k_grid(2) - config.k_grid(1);
  config.num_refine = 11;
  config.M_values = [4, 5];
  config.s = 1;
  config.refractive_index = sqrt(1 + 16 * config.s);
  config.beta = 0.5;
  config.period_x = 1;
  config.period_y = 1;
  config.radius = 0.2;
  config.ntot = 60;
  config.unit_tolerance = 1e-4;
  config.mode_selection_tolerance = 1e-9;
  config.bloch_residual_tolerance = 1e-8;
  config.max_runtime_seconds = 1800;
  config.proxy.padding = 0.4;
  config.proxy.proxy_dist = 0.7;
  config.proxy.N_side = 60;
  config.proxy.N_top = 60;
  config.proxy.N_proxy_edge = 36;
  config.proxy.M_pw = 14;

  runtime.start_token = start_token;
  runtime.max_seconds = config.max_runtime_seconds;
  [C, curvelen, ~, ~] = geom.construct_cont(config.ntot, 'circle', ...
    0, 0, config.radius);
  geometry.C = C;
  geometry.curvelen = curvelen;

  fprintf('Bounded M4/M5 real-axis A_def diagnostic\n');
  fprintf('k interval = [%.17g, %.17g], num_k = %d\n', ...
    config.k_interval(1), config.k_interval(2), config.num_k);

  % --- stage 2: two fully gated 49-point coarse scans ---

  scans = repmat(LOCAL_empty_scan(), length(config.M_values), 1);
  for j = 1:length(config.M_values)
    M = config.M_values(j);
    fprintf('Running coarse scan for M = %d.\n', M);
    scans(j) = LOCAL_scan_grid(config, geometry, M, ...
      config.k_grid, 'coarse', runtime);
  end

  % --- stage 3: match strict interior coarse minima ---

  matches = LOCAL_match_minima(scans(1), scans(2), config.coarse_step);
  selected_match = LOCAL_empty_match();
  refinement = repmat(LOCAL_empty_refinement(), 2, 1);
  selection_status = 'NO_MATCHED_STRICT_INTERIOR_COARSE_MINIMUM';
  location_agreement_pass = false;
  pass = false;

  if ~isempty(matches)
    [~, selected_index] = min([matches.joint_score]);
    selected_match = matches(selected_index);
    selection_status = 'MATCHED_COARSE_MINIMUM_SELECTED';
    refinement(1) = LOCAL_refine_match(config, geometry, scans(1), ...
      selected_match.index_M4, runtime);
    refinement(2) = LOCAL_refine_match(config, geometry, scans(2), ...
      selected_match.index_M5, runtime);
    if refinement(1).pass && refinement(2).pass
      location_difference = abs(refinement(1).minimum_k - ...
        refinement(2).minimum_k);
      location_agreement_pass = ...
        location_difference <= config.coarse_step;
      if location_agreement_pass
        selection_status = 'MATCHED_REFINED_INTERIOR_MINIMA_ACCEPTED';
        pass = true;
      else
        selection_status = 'REFINED_LOCATION_AGREEMENT_FAILED';
      end
    else
      selection_status = 'REFINED_STRICT_INTERIOR_MINIMUM_UNAVAILABLE';
    end
  end

  if pass
    diagnostic_label = config.strongest_label;
  else
    diagnostic_label = config.blocked_label;
  end

  results.config = config;
  results.scans = scans;
  results.coarse_matches = matches;
  results.selected_match = selected_match;
  results.refinement = refinement;
  results.location_agreement_pass = location_agreement_pass;
  if refinement(1).pass && refinement(2).pass
    results.refined_location_difference = abs( ...
      refinement(1).minimum_k - refinement(2).minimum_k);
  else
    results.refined_location_difference = NaN;
  end
  results.endpoint_fallback_used = false;
  results.global_fallback_used = false;
  results.root_claim = false;
  results.eigenvalue_claim = false;
  results.seed_promotion = false;
  results.gating_result = false;
  results.smoke_diagnostic_only = true;
  results.selection_status = selection_status;
  results.diagnostic_label = diagnostic_label;
  results.pass = pass;
  results.elapsed_seconds = toc(start_token);
  results.output_dir = output_dir;

  % --- stage 4: independent deterministic evidence bundle ---

  LOCAL_write_samples(results, output_dir, 'coarse-samples.csv', false);
  LOCAL_write_samples(results, output_dir, 'refine-samples.csv', true);
  LOCAL_write_summary(results, output_dir);
  LOCAL_write_report(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results');
  fprintf('Diagnostic label: %s\n', results.diagnostic_label);
  fprintf('Elapsed seconds: %.6f\n', results.elapsed_seconds);
end

%% ==================== Gated real-axis evaluation ====================
% These helpers scan one M and form A_def only after every sample gate passes.

function scan = LOCAL_scan_grid(config, geometry, M, k_grid, stage, runtime)
  samples = repmat(LOCAL_empty_sample(), length(k_grid), 1);
  for j = 1:length(k_grid)
    samples(j) = LOCAL_evaluate_sample(config, geometry, M, ...
      k_grid(j), stage, runtime);
  end
  strict_indices = LOCAL_strict_minima(samples);
  scan.M = M;
  scan.K = 2 * M + 1;
  scan.k_grid = k_grid;
  scan.samples = samples;
  scan.strict_minimum_indices = strict_indices;
  scan.num_usable = sum(strcmp({samples.status}, 'usable'));
  scan.num_mode_count_failed = ...
    sum(strcmp({samples.status}, 'mode-count-gate-failed'));
  scan.num_unit_circle_failed = ...
    sum(strcmp({samples.status}, 'unit-circle-gate-failed'));
  scan.num_decay_count_failed = ...
    sum(strcmp({samples.status}, 'decay-count-gate-failed'));
  scan.num_outgoing_count_failed = ...
    sum(strcmp({samples.status}, 'outgoing-count-gate-failed'));
  scan.num_bloch_residual_failed = ...
    sum(strcmp({samples.status}, 'bloch-residual-gate-failed'));
  scan.num_evaluation_failed = ...
    sum(strcmp({samples.status}, 'evaluation-failed'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sample = LOCAL_evaluate_sample(config, geometry, M, ...
    k_real, stage, runtime)
  LOCAL_check_deadline(runtime, sprintf('M=%d k=%.8g start', M, k_real));
  sample = LOCAL_empty_sample();
  sample.M = M;
  sample.K = 2 * M + 1;
  sample.k_real = k_real;
  sample.stage = stage;

  try
    kext = k_real;
    kint = config.refractive_index * kext;
    pars1.k = kext;
    pars1.beta = config.beta;
    pars1.d = config.period_y;
    pars1.periodic_axis = 'y';
    pars2.H = config.period_x / 2 + config.radius + ...
      config.proxy.padding;
    pars2.proxy_dist = config.proxy.proxy_dist;
    pars2.N_side = config.proxy.N_side;
    pars2.N_top = config.proxy.N_top;
    pars2.N_proxy_edge = config.proxy.N_proxy_edge;
    pars2.M_pw = config.proxy.M_pw;

    proxy = kernel.precomp_proxy(pars1, pars2);
    channels = bloch.rayleigh_channels(kext, config.beta, ...
      config.period_y, M, config.period_x);
    S_cell = bloch.construct_S(geometry.C, kext, kint, pars1, proxy, ...
      geometry.curvelen, channels, -config.period_x / 2, ...
      config.period_x / 2);
    mode_opts.lambda_tol = config.unit_tolerance;
    mode_opts.normalize = 'V';
    modes = bloch.solve_modes(S_cell, mode_opts);
    lambda = modes.lambda(:);
    abs_lambda = abs(lambda);

    sample.num_modes = length(lambda);
    sample.expected_num_modes = 2 * channels.K;
    sample.count_unit = sum(abs(abs_lambda - 1) <= ...
      config.unit_tolerance);
    sample.count_right_decay = sum(abs_lambda < ...
      1 - config.unit_tolerance);
    sample.count_left_decay = sum(abs_lambda > ...
      1 + config.unit_tolerance);
    sample.bloch_normalized_residual = LOCAL_bloch_residual(modes);
    sample.cell_solve_relative_residual = ...
      S_cell.solve_relative_residual_norm;

    if sample.num_modes ~= sample.expected_num_modes
      sample.status = 'mode-count-gate-failed';
      return;
    end
    if sample.count_unit ~= 0
      sample.status = 'unit-circle-gate-failed';
      return;
    end
    if sample.count_right_decay ~= channels.K || ...
        sample.count_left_decay ~= channels.K
      sample.status = 'decay-count-gate-failed';
      return;
    end
    if ~(isfinite(sample.bloch_normalized_residual) && ...
        sample.bloch_normalized_residual <= ...
        config.bloch_residual_tolerance)
      sample.status = 'bloch-residual-gate-failed';
      return;
    end

    traces = bloch.mode_traces(modes.lambda, modes.V, channels);
    select_opts.lambda_tol = config.mode_selection_tolerance;
    [D_plus, N_plus, selected_plus] = ...
      bloch.select_port_traces(modes, traces, '+', select_opts);
    [D_minus, N_minus, selected_minus] = ...
      bloch.select_port_traces(modes, traces, '-', select_opts);
    sample.count_selected_plus = selected_plus.numSelected;
    sample.count_selected_minus = selected_minus.numSelected;
    if sample.count_selected_plus ~= channels.K || ...
        sample.count_selected_minus ~= channels.K
      sample.status = 'outgoing-count-gate-failed';
      return;
    end

    A_def = LOCAL_empty_defect_matrix(channels, config.period_x, ...
      D_minus, N_minus, D_plus, N_plus);
    singular_values = svd(A_def);
    sample.raw_sigma = singular_values(end);
    sample.matrix_norm_2 = singular_values(1);
    sample.normalized_sigma = singular_values(end) / ...
      max(singular_values(1), eps);
    sample.status = 'usable';
  catch ME
    if strcmp(ME.identifier, 'run_bie_m4_m5_scan:RuntimeCap')
      rethrow(ME);
    end
    sample.status = 'evaluation-failed';
    sample.error_id = ME.identifier;
    sample.error_message = strrep(ME.message, sprintf('\n'), ' ');
  end
  LOCAL_check_deadline(runtime, sprintf('M=%d k=%.8g complete', M, k_real));
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

%% ==================== Strict-minimum selection ====================
% These helpers prohibit endpoint/global fallbacks and match the two M scans.

function indices = LOCAL_strict_minima(samples)
  indices = [];
  for j = 2:length(samples) - 1
    triplet = samples(j - 1:j + 1);
    if all(strcmp({triplet.status}, 'usable')) && ...
        samples(j).normalized_sigma < samples(j - 1).normalized_sigma && ...
        samples(j).normalized_sigma < samples(j + 1).normalized_sigma
      indices(end + 1, 1) = j; %#ok<AGROW>
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function matches = LOCAL_match_minima(scan4, scan5, coarse_step)
  matches = repmat(LOCAL_empty_match(), 0, 1);
  for i4 = scan4.strict_minimum_indices(:).'
    for i5 = scan5.strict_minimum_indices(:).'
      k_difference = abs(scan4.samples(i4).k_real - ...
        scan5.samples(i5).k_real);
      if k_difference <= coarse_step + 10 * eps
        entry.index_M4 = i4;
        entry.index_M5 = i5;
        entry.k_M4 = scan4.samples(i4).k_real;
        entry.k_M5 = scan5.samples(i5).k_real;
        entry.sigma_M4 = scan4.samples(i4).normalized_sigma;
        entry.sigma_M5 = scan5.samples(i5).normalized_sigma;
        entry.coarse_location_difference = k_difference;
        entry.joint_score = max(entry.sigma_M4, entry.sigma_M5);
        matches(end + 1, 1) = entry; %#ok<AGROW>
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function refinement = LOCAL_refine_match(config, geometry, scan, ...
    coarse_index, runtime)
  refinement = LOCAL_empty_refinement();
  refinement.M = scan.M;
  refinement.coarse_index = coarse_index;
  refinement.k_left = scan.samples(coarse_index - 1).k_real;
  refinement.k_right = scan.samples(coarse_index + 1).k_real;
  k_grid = linspace(refinement.k_left, refinement.k_right, ...
    config.num_refine).';
  refined_scan = LOCAL_scan_grid(config, geometry, scan.M, ...
    k_grid, 'refine', runtime);
  refinement.samples = refined_scan.samples;
  refinement.strict_minimum_indices = ...
    refined_scan.strict_minimum_indices;
  if isempty(refinement.strict_minimum_indices)
    refinement.status = 'NO_STRICT_INTERIOR_REFINED_MINIMUM';
    return;
  end

  values = [refinement.samples( ...
    refinement.strict_minimum_indices).normalized_sigma];
  [~, local_index] = min(values);
  selected_index = refinement.strict_minimum_indices(local_index);
  refinement.minimum_index = selected_index;
  refinement.minimum_k = refinement.samples(selected_index).k_real;
  refinement.minimum_normalized_sigma = ...
    refinement.samples(selected_index).normalized_sigma;
  refinement.status = 'STRICT_INTERIOR_REFINED_MINIMUM';
  refinement.pass = selected_index > 1 && ...
    selected_index < length(refinement.samples);
end

%% ==================== Deterministic evidence outputs ====================
% These helpers write all coarse/refined samples and the bounded decision.

function LOCAL_write_samples(results, output_dir, filename, write_refine)
  fid = LOCAL_open(fullfile(output_dir, filename));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  LOCAL_write_sample_header(fid);
  if write_refine
    for j = 1:length(results.refinement)
      refinement = results.refinement(j);
      for isample = 1:length(refinement.samples)
        is_minimum = any(refinement.strict_minimum_indices == isample);
        LOCAL_write_sample_row(fid, results.config.model_id, ...
          refinement.samples(isample), isample, is_minimum);
      end
    end
  else
    for j = 1:length(results.scans)
      scan = results.scans(j);
      for isample = 1:length(scan.samples)
        is_minimum = any(scan.strict_minimum_indices == isample);
        LOCAL_write_sample_row(fid, results.config.model_id, ...
          scan.samples(isample), isample, is_minimum);
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_sample_header(fid)
  fprintf(fid, ['model_id,M,K,stage,index,k_real,status,num_modes,', ...
    'expected_num_modes,count_unit,count_right_decay,count_left_decay,', ...
    'count_selected_plus,count_selected_minus,bloch_normalized_residual,', ...
    'cell_solve_relative_residual,raw_sigma,normalized_sigma,', ...
    'matrix_norm_2,strict_interior_local_minimum,error_id,error_message\n']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_sample_row(fid, model_id, sample, index, is_minimum)
  fprintf(fid, ['%s,%d,%d,%s,%d,%.17g,%s,%g,%g,%g,%g,%g,%g,%g,', ...
    '%.17g,%.17g,%.17g,%.17g,%.17g,%d,%s,%s\n'], model_id, ...
    sample.M, sample.K, sample.stage, index, sample.k_real, sample.status, ...
    sample.num_modes, sample.expected_num_modes, sample.count_unit, ...
    sample.count_right_decay, sample.count_left_decay, ...
    sample.count_selected_plus, sample.count_selected_minus, ...
    sample.bloch_normalized_residual, sample.cell_solve_relative_residual, ...
    sample.raw_sigma, sample.normalized_sigma, sample.matrix_norm_2, ...
    is_minimum, sample.error_id, LOCAL_csv_quote(sample.error_message));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_summary(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'scan-summary.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,label,selection_status,coarse_step,', ...
    'M4_usable,M5_usable,M4_strict_minima,M5_strict_minima,', ...
    'matched_coarse_minima,selected_coarse_k_M4,selected_coarse_k_M5,', ...
    'selected_coarse_sigma_M4,selected_coarse_sigma_M5,', ...
    'refined_k_M4,refined_k_M5,refined_sigma_M4,refined_sigma_M5,', ...
    'refined_location_difference,location_agreement_pass,', ...
    'endpoint_fallback_used,global_fallback_used,root_claim,', ...
    'eigenvalue_claim,seed_promotion,gating_result,', ...
    'smoke_diagnostic_only,pass\n']);
  fprintf(fid, ['%s,%s,%s,%.17g,%d,%d,%d,%d,%d,%.17g,%.17g,', ...
    ['%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%d,%d,%d,', ...
    '%d,%d,%d,%d,%d\n']], ...
    results.config.model_id, results.diagnostic_label, ...
    results.selection_status, results.config.coarse_step, ...
    results.scans(1).num_usable, results.scans(2).num_usable, ...
    length(results.scans(1).strict_minimum_indices), ...
    length(results.scans(2).strict_minimum_indices), ...
    length(results.coarse_matches), results.selected_match.k_M4, ...
    results.selected_match.k_M5, results.selected_match.sigma_M4, ...
    results.selected_match.sigma_M5, results.refinement(1).minimum_k, ...
    results.refinement(2).minimum_k, ...
    results.refinement(1).minimum_normalized_sigma, ...
    results.refinement(2).minimum_normalized_sigma, ...
    results.refined_location_difference, results.location_agreement_pass, ...
    results.endpoint_fallback_used, results.global_fallback_used, ...
    results.root_claim, results.eigenvalue_claim, ...
    results.seed_promotion, results.gating_result, ...
    results.smoke_diagnostic_only, results.pass);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'report.md'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# Bounded M4/M5 real-axis A_def diagnostic\n\n');
  fprintf(fid, '- Model ID: `%s`\n', results.config.model_id);
  fprintf(fid, '- Claim scope: `%s`\n', results.config.claim_scope);
  fprintf(fid, '- Label: `%s`\n', results.diagnostic_label);
  fprintf(fid, '- Selection status: `%s`\n', results.selection_status);
  fprintf(fid, '- Coarse grid: %d points over [%.17g, %.17g]\n', ...
    results.config.num_k, results.config.k_interval(1), ...
    results.config.k_interval(2));
  for j = 1:length(results.scans)
    scan = results.scans(j);
    fprintf(fid, ['- M=%d: usable=%d, strict interior coarse minima=%d, ', ...
      'mode/unit/decay/outgoing/residual/evaluation ', ...
      'failures=%d/%d/%d/%d/%d/%d.\n'], ...
      scan.M, scan.num_usable, length(scan.strict_minimum_indices), ...
      scan.num_mode_count_failed, scan.num_unit_circle_failed, ...
      scan.num_decay_count_failed, scan.num_outgoing_count_failed, ...
      scan.num_bloch_residual_failed, scan.num_evaluation_failed);
  end
  fprintf(fid, '- Matched strict coarse minima: %d\n', ...
    length(results.coarse_matches));
  fprintf(fid, '- Refined M4 position: %.17g\n', ...
    results.refinement(1).minimum_k);
  fprintf(fid, '- Refined M5 position: %.17g\n', ...
    results.refinement(2).minimum_k);
  fprintf(fid, '- Refined position difference: %.6e (pass=%d)\n', ...
    results.refined_location_difference, results.location_agreement_pass);
  fprintf(fid, '- Endpoint fallback used: `%d`\n', ...
    results.endpoint_fallback_used);
  fprintf(fid, '- Global fallback used: `%d`\n', ...
    results.global_fallback_used);
  fprintf(fid, '- Root claim: `%d`\n', results.root_claim);
  fprintf(fid, '- Eigenvalue claim: `%d`\n', results.eigenvalue_claim);
  fprintf(fid, '- Seed promotion: `%d`\n', results.seed_promotion);
  fprintf(fid, '- Gating result: `%d`\n', results.gating_result);
  fprintf(fid, '- Smoke diagnostic only: `%d`\n', ...
    results.smoke_diagnostic_only);
  fprintf(fid, ['\nThe output is confined to the bounded real-axis ', ...
    'diagnostic scope; no spectral or downstream promotion is made.\n']);
end

%% ==================== Runtime, schema, and file helpers ====================
% These helpers enforce the cap and initialize stable output schemas.

function LOCAL_check_deadline(runtime, label)
  elapsed = toc(runtime.start_token);
  if elapsed >= runtime.max_seconds
    error('run_bie_m4_m5_scan:RuntimeCap', ...
      'Runtime cap reached after %.1f seconds before %s.', elapsed, label);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function scan = LOCAL_empty_scan()
  scan = struct('M', [], 'K', [], 'k_grid', [], 'samples', [], ...
    'strict_minimum_indices', [], 'num_usable', 0, ...
    'num_mode_count_failed', 0, 'num_unit_circle_failed', 0, ...
    'num_decay_count_failed', 0, 'num_outgoing_count_failed', 0, ...
    'num_bloch_residual_failed', 0, 'num_evaluation_failed', 0);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sample = LOCAL_empty_sample()
  sample = struct('M', NaN, 'K', NaN, 'stage', '', 'k_real', NaN, ...
    'status', 'unset', 'num_modes', NaN, 'expected_num_modes', NaN, ...
    'count_unit', NaN, 'count_right_decay', NaN, ...
    'count_left_decay', NaN, 'count_selected_plus', NaN, ...
    'count_selected_minus', NaN, 'bloch_normalized_residual', NaN, ...
    'cell_solve_relative_residual', NaN, 'raw_sigma', NaN, ...
    'normalized_sigma', NaN, 'matrix_norm_2', NaN, ...
    'error_id', '', 'error_message', '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function match = LOCAL_empty_match()
  match = struct('index_M4', NaN, 'index_M5', NaN, ...
    'k_M4', NaN, 'k_M5', NaN, 'sigma_M4', NaN, 'sigma_M5', NaN, ...
    'coarse_location_difference', NaN, 'joint_score', NaN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function refinement = LOCAL_empty_refinement()
  refinement = struct('M', NaN, 'coarse_index', NaN, ...
    'k_left', NaN, 'k_right', NaN, 'samples', [], ...
    'strict_minimum_indices', [], 'minimum_index', NaN, ...
    'minimum_k', NaN, 'minimum_normalized_sigma', NaN, ...
    'status', 'not-run', 'pass', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_csv_quote(value)
  value = strrep(value, '"', '""');
  value = ['"', value, '"'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fid = LOCAL_open(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_bie_m4_m5_scan:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end
