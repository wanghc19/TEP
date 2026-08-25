function results = run_i4_rayleigh_budget(profile, overrides, output_label)
% RUN_I4_RAYLEIGH_BUDGET Time Rayleigh trace and stability diagnostics.
%
% Purpose:
%   Build reproducible low-reference evidence on the frozen smoke grid
%   without assigning M_trace or M_stable while cross-resolution gates
%   remain unavailable.
%
% Input:
%   profile      - One of 'smoke', 'core', or 'stress'.  Default: 'smoke'.
%   overrides    - Optional scalar struct of test-local configuration
%                  replacements.  Nested proxy fields are merged.
%   output_label - Optional filesystem-safe output subdirectory label.
%
% Output:
%   results - Configuration, rectangular BIE response evidence, square-cell
%             principal restrictions, ordered-QZ metrics, doubling metrics,
%             timings, and output paths.  M_trace and M_stable are NaN.
%
% Main algorithm:
%   First solve low-order incident BIE columns and extract them on a larger
%   Rayleigh output space.  Validate those rectangular outgoing columns by
%   direct wall Dirichlet/x-derivative projection, following
%   benchmark/bloch/bloch_test_F.m.  Then construct square S_M cells,
%   compare their central principal restrictions to a higher-M reference,
%   record projective ordered-QZ deflating-subspace residuals, test
%   deterministic scattering-data perturbations, and time Redheffer
%   self-doubling with reflection and DtN action comparisons.
%
% Based on:
%   benchmark/bloch/bloch_test_F.m, test/hg-map/hg_map_experiment.m,
%   test/i4-fliss-2013, and the public +bloch package.
%
% Main changes:
%   Separate rectangular trace-resolution evidence from square stability
%   evidence.  Transmission rank is recorded only in a diagnostic ledger.
%
% Numerical goal:
%   Measure the workload and preserve raw evidence for the frozen gates.
%   This partial-gate scaffold issues no scientific readiness label and
%   makes no root or eigenvalue claim.

  if nargin < 1 || isempty(profile)
    profile = 'smoke';
  end
  if nargin < 2 || isempty(overrides)
    overrides = struct();
  end
  if nargin < 3 || isempty(output_label)
    output_label = profile;
  end
  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  addpath(repo_root);
  config = i4_rayleigh_budget_config(profile);
  config = LOCAL_apply_overrides(config, overrides);
  output_label = LOCAL_output_label(output_label);
  config.output_label = output_label;
  output_dir = fullfile(here, 'output', output_label);
  if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
  end

  diary('off');
  log_path = fullfile(output_dir, 'run.log');
  if exist(log_path, 'file') == 2
    delete(log_path);
  end
  diary(log_path);
  diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>
  start_token = tic;
  runtime.start_token = start_token;
  runtime.max_seconds = config.max_runtime_seconds;

  % --- stage 1: shared physical geometry and proxy representation ---

  [C, curvelen, ~, ~] = geom.construct_cont(config.ntot, 'circle', ...
    0, 0, config.radius);
  geometry.C = C;
  geometry.curvelen = curvelen;
  pars1.k = config.k;
  pars1.beta = config.beta;
  pars1.d = config.period_y;
  pars1.periodic_axis = 'y';
  proxy_token = tic;
  proxy = kernel.precomp_proxy(pars1, config.proxy);
  shared_timing.proxy_seconds = toc(proxy_token);
  LOCAL_check_deadline(runtime, 'shared proxy construction');

  fprintf('I4 Rayleigh-budget timing scaffold: profile=%s.\n', ...
    config.profile);
  fprintf('Decision grid status: %s.\n', config.grid_status);

  % --- stage 2: rectangular low-input/high-output trace evidence ---

  rectangular = LOCAL_rectangular_response(config, geometry, pars1, ...
    proxy, runtime);
  LOCAL_check_deadline(runtime, 'rectangular response');

  % --- stage 3: square cells, ordered QZ, and finite-depth doubling ---

  square_M = unique([config.square_M_values(:); ...
    config.square_reference_M]).';
  square = repmat(LOCAL_empty_square(), length(square_M), 1);
  for j = 1:length(square_M)
    fprintf('Timing square cell M=%d.\n', square_M(j));
    square(j) = LOCAL_square_sample(config, rectangular, ...
      square_M(j), runtime);
    LOCAL_check_deadline(runtime, sprintf('square M=%d', square_M(j)));
  end
  square = LOCAL_add_principal_restrictions(square, ...
    config.square_reference_M, config.action_column_count);

  results.config = config;
  results.shared_timing = shared_timing;
  results.rectangular = rectangular;
  results.square = square;
  results.M_trace = NaN;
  results.M_trace_status = config.M_trace_status;
  results.M_stable = NaN;
  results.M_stable_status = config.M_stable_status;
  results.decision_labels_enabled = false;
  results.root_claim = false;
  results.eigenvalue_claim = false;
  results.elapsed_seconds = toc(start_token);
  results.output_dir = output_dir;

  % --- stage 4: deterministic timing-only evidence bundle ---

  LOCAL_write_config(results, output_dir, here);
  LOCAL_write_rectangular_summary(results, output_dir);
  LOCAL_write_trace_spectrum(results, output_dir);
  LOCAL_write_trace_tail(results, output_dir);
  LOCAL_write_square_summary(results, output_dir);
  LOCAL_write_transmission_ledger(results, output_dir);
  LOCAL_write_perturbations(results, output_dir);
  LOCAL_write_doubling(results, output_dir);
  LOCAL_write_timings(results, output_dir);
  LOCAL_write_report(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results');
  fprintf('Timing scaffold elapsed seconds: %.6f.\n', ...
    results.elapsed_seconds);
end

%% ==================== Rectangular physical BIE response ====================
% These helpers solve M_in incident columns and observe them at M_out.

function rectangular = LOCAL_rectangular_response(config, geometry, ...
    pars1, proxy, runtime)
  rectangular = LOCAL_empty_rectangular();
  rectangular.M_in = config.M_in;
  rectangular.M_out = config.M_out;
  token_total = tic;

  token = tic;
  channels_in = bloch.rayleigh_channels(config.k, config.beta, ...
    config.period_y, config.M_in, config.period_x);
  channels_out = bloch.rayleigh_channels(config.k, config.beta, ...
    config.period_y, config.M_out, config.period_x);
  rectangular.timing.channel_seconds = toc(token);
  rectangular.K_in = channels_in.K;
  rectangular.K_out = channels_out.K;
  rectangular.channels_in = channels_in;
  rectangular.channels_out = channels_out;
  rectangular.minimum_abs_gamma = min(abs(channels_out.gamma_m));

  token = tic;
  A_QP = full(complex(op.construct_A_QP(geometry.C, config.k, ...
    config.refractive_index * config.k, pars1, proxy, ...
    geometry.curvelen)));
  rectangular.timing.A_QP_seconds = toc(token);

  token = tic;
  [B_L, B_R] = bloch.incident_rhs(geometry.C, channels_in, ...
    config.wall_left, config.wall_right);
  rectangular.timing.incident_seconds = toc(token);

  token = tic;
  [F_L, F_R] = bloch.farfield_extractors(geometry.C, channels_out, ...
    config.wall_left, config.wall_right, geometry.curvelen);
  rectangular.timing.extractor_seconds = toc(token);

  rhs = [B_L, B_R];
  token = tic;
  H_all = -(A_QP \ rhs);
  rectangular.timing.solve_seconds = toc(token);
  rectangular.solve_relative_residual = norm(A_QP * H_all + rhs, 'fro') / ...
    max(1, norm(rhs, 'fro'));
  K_in = channels_in.K;
  H_L = H_all(:, 1:K_in);
  H_R = H_all(:, K_in + 1:2 * K_in);
  scattered_L = F_L * H_all;
  scattered_R = F_R * H_all;

  injection = LOCAL_channel_injection(channels_in, channels_out);
  direct = injection * diag(channels_in.phase(:));
  rectangular.R_L = scattered_L(:, 1:K_in);
  rectangular.T_RL = direct + scattered_L(:, K_in + 1:end);
  rectangular.T_LR = direct + scattered_R(:, 1:K_in);
  rectangular.R_R = scattered_R(:, K_in + 1:end);

  token = tic;
  wall = LOCAL_direct_wall_projection(config, geometry, pars1, proxy, ...
    channels_out, H_all);
  rectangular.timing.wall_projection_seconds = toc(token);
  rectangular.extractor_error_L_D = LOCAL_relerr(scattered_L, wall.s_L_D);
  rectangular.extractor_error_R_D = LOCAL_relerr(scattered_R, wall.s_R_D);
  rectangular.extractor_error_L_N = LOCAL_relerr(scattered_L, wall.s_L_N);
  rectangular.extractor_error_R_N = LOCAL_relerr(scattered_R, wall.s_R_N);
  rectangular.extractor_validation_error = max([ ...
    rectangular.extractor_error_L_D, rectangular.extractor_error_R_D, ...
    rectangular.extractor_error_L_N, rectangular.extractor_error_R_N]);
  rectangular.extractor_validation_pass = ...
    rectangular.minimum_abs_gamma >= config.nonwood_gamma_tolerance && ...
    rectangular.extractor_validation_error <= ...
    config.extractor_validation_tolerance;
  probe = find(abs(channels_in.m) <= config.M_probe);
  probe_columns = [probe; channels_in.K + probe];
  rectangular.spectrum = LOCAL_trace_spectrum(channels_out, ...
    scattered_L(:, probe_columns), scattered_R(:, probe_columns), ...
    LOCAL_restrict_wall(wall, probe_columns));
  rectangular.tail = LOCAL_trace_tail(rectangular.spectrum, ...
    config.M_probe, config.M_out);
  rectangular.timing.total_seconds = toc(token_total);
  rectangular.status = 'TIMING_EVIDENCE_RECORDED_NO_M_TRACE_DECISION';
  LOCAL_check_deadline(runtime, 'rectangular direct wall projection');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function injection = LOCAL_channel_injection(channels_in, channels_out)
  injection = zeros(channels_out.K, channels_in.K);
  for j = 1:channels_in.K
    index = find(channels_out.m == channels_in.m(j));
    if length(index) ~= 1
      error('run_i4_rayleigh_budget:ChannelInjection', ...
        'Every input Rayleigh order must occur once in the output grid.');
    end
    injection(index, j) = 1;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function wall = LOCAL_direct_wall_projection(config, geometry, pars1, ...
    proxy, channels, H_all)
  C = geometry.C;
  N = size(C, 2);
  x = C(1, :).';
  y = C(4, :).';
  dxdt = C(2, :).';
  dydt = C(5, :).';
  speed = sqrt(dxdt .^ 2 + dydt .^ 2);
  nx = dydt ./ speed;
  ny = -dxdt ./ speed;
  weights = (geometry.curvelen / N) * speed;
  yq = config.period_y * (0:config.Ny_wall - 1) / config.Ny_wall;
  targets_L = [config.wall_left * ones(1, config.Ny_wall); yq];
  targets_R = [config.wall_right * ones(1, config.Ny_wall); yq];
  source = [x.'; y.'];

  [pot_L, gradx_L, grady_L, hessxx_L, hessxy_L, ~] = ...
    kernel.qpgreen_mfs_pairmat(source, targets_L, pars1, proxy);
  [pot_R, gradx_R, grady_R, hessxx_R, hessxy_R, ~] = ...
    kernel.qpgreen_mfs_pairmat(source, targets_R, pars1, proxy);
  dGdnu_L = -bsxfun(@times, gradx_L, nx.') - ...
    bsxfun(@times, grady_L, ny.');
  dGdnu_R = -bsxfun(@times, gradx_R, nx.') - ...
    bsxfun(@times, grady_R, ny.');
  dx_dGdnu_L = -bsxfun(@times, hessxx_L, nx.') - ...
    bsxfun(@times, hessxy_L, ny.');
  dx_dGdnu_R = -bsxfun(@times, hessxx_R, nx.') - ...
    bsxfun(@times, hessxy_R, ny.');

  tau = H_all(1:N, :);
  mu = H_all(N + 1:2 * N, :);
  tau_w = bsxfun(@times, tau, weights);
  mu_w = bsxfun(@times, mu, weights);
  u_L = dGdnu_L * tau_w - pot_L * mu_w;
  u_R = dGdnu_R * tau_w - pot_R * mu_w;
  dx_u_L = dx_dGdnu_L * tau_w - gradx_L * mu_w;
  dx_u_R = dx_dGdnu_R * tau_w - gradx_R * mu_w;

  dy = config.period_y / config.Ny_wall;
  psi = (1 / sqrt(config.period_y)) * ...
    exp(1i * (channels.beta_m(:) * yq));
  D_L = dy * (conj(psi) * u_L);
  D_R = dy * (conj(psi) * u_R);
  Dx_L = dy * (conj(psi) * dx_u_L);
  Dx_R = dy * (conj(psi) * dx_u_R);
  gamma = channels.gamma_m(:);
  wall.s_L_D = D_L;
  wall.s_R_D = D_R;
  wall.s_L_N = -bsxfun(@rdivide, Dx_L, 1i * gamma);
  wall.s_R_N = bsxfun(@rdivide, Dx_R, 1i * gamma);
  wall.D_L = D_L;
  wall.D_R = D_R;
  wall.Dx_L = Dx_L;
  wall.Dx_R = Dx_R;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function spectrum = LOCAL_trace_spectrum(channels, scattered_L, ...
    scattered_R, wall)
  gamma = channels.gamma_m(:);
  xi_weight = sqrt(1 + abs(channels.beta_m(:)) .^ 2);
  spectrum.m = channels.m(:);
  spectrum.beta_m = channels.beta_m(:);
  spectrum.gamma_m = gamma;
  spectrum.outgoing_L_row_norm = LOCAL_row_norms(scattered_L);
  spectrum.outgoing_R_row_norm = LOCAL_row_norms(scattered_R);
  spectrum.direct_D_L_row_norm = LOCAL_row_norms(wall.D_L);
  spectrum.direct_D_R_row_norm = LOCAL_row_norms(wall.D_R);
  spectrum.direct_Dx_L_row_norm = LOCAL_row_norms(wall.Dx_L);
  spectrum.direct_Dx_R_row_norm = LOCAL_row_norms(wall.Dx_R);
  spectrum.xi_weight = xi_weight;
  spectrum.weighted_cauchy_L_row_norm = sqrt( ...
    xi_weight .* spectrum.direct_D_L_row_norm .^ 2 + ...
    spectrum.direct_Dx_L_row_norm .^ 2 ./ xi_weight);
  spectrum.weighted_cauchy_R_row_norm = sqrt( ...
    xi_weight .* spectrum.direct_D_R_row_norm .^ 2 + ...
    spectrum.direct_Dx_R_row_norm .^ 2 ./ xi_weight);
  spectrum.outgoing_derivative_L_row_norm = ...
    abs(gamma) .* spectrum.outgoing_L_row_norm;
  spectrum.outgoing_derivative_R_row_norm = ...
    abs(gamma) .* spectrum.outgoing_R_row_norm;
  spectral_Dx_L = -1i * bsxfun(@times, gamma, scattered_L);
  spectral_Dx_R = 1i * bsxfun(@times, gamma, scattered_R);
  spectrum.spectral_weighted_cauchy_L_row_norm = sqrt( ...
    xi_weight .* spectrum.outgoing_L_row_norm .^ 2 + ...
    spectrum.outgoing_derivative_L_row_norm .^ 2 ./ xi_weight);
  spectrum.spectral_weighted_cauchy_R_row_norm = sqrt( ...
    xi_weight .* spectrum.outgoing_R_row_norm .^ 2 + ...
    spectrum.outgoing_derivative_R_row_norm .^ 2 ./ xi_weight);
  difference_D_L = LOCAL_row_norms(wall.D_L - scattered_L);
  difference_D_R = LOCAL_row_norms(wall.D_R - scattered_R);
  difference_Dx_L = LOCAL_row_norms(wall.Dx_L - spectral_Dx_L);
  difference_Dx_R = LOCAL_row_norms(wall.Dx_R - spectral_Dx_R);
  spectrum.discrepancy_weighted_cauchy_L_row_norm = sqrt( ...
    xi_weight .* difference_D_L .^ 2 + difference_Dx_L .^ 2 ./ xi_weight);
  spectrum.discrepancy_weighted_cauchy_R_row_norm = sqrt( ...
    xi_weight .* difference_D_R .^ 2 + difference_Dx_R .^ 2 ./ xi_weight);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function restricted = LOCAL_restrict_wall(wall, columns)
  restricted.s_L_D = wall.s_L_D(:, columns);
  restricted.s_R_D = wall.s_R_D(:, columns);
  restricted.s_L_N = wall.s_L_N(:, columns);
  restricted.s_R_N = wall.s_R_N(:, columns);
  restricted.D_L = wall.D_L(:, columns);
  restricted.D_R = wall.D_R(:, columns);
  restricted.Dx_L = wall.Dx_L(:, columns);
  restricted.Dx_R = wall.Dx_R(:, columns);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tail = LOCAL_trace_tail(spectrum, M_min, M_out)
  tail = repmat(struct('M', NaN, ...
    'spectral_tail_L', NaN, 'spectral_tail_R', NaN, ...
    'spectral_tail_max', NaN, 'direct_tail_L', NaN, ...
    'direct_tail_R', NaN, 'direct_tail_max', NaN, ...
    'discrepancy_tail_L', NaN, 'discrepancy_tail_R', NaN, ...
    'discrepancy_tail_max', NaN), ...
    M_out - M_min + 1, 1);
  spectral_total_L = norm(spectrum.spectral_weighted_cauchy_L_row_norm);
  spectral_total_R = norm(spectrum.spectral_weighted_cauchy_R_row_norm);
  direct_total_L = norm(spectrum.weighted_cauchy_L_row_norm);
  direct_total_R = norm(spectrum.weighted_cauchy_R_row_norm);
  discrepancy_scale_L = max(spectral_total_L, direct_total_L);
  discrepancy_scale_R = max(spectral_total_R, direct_total_R);
  for M = M_min:M_out
    index = M - M_min + 1;
    mask = abs(spectrum.m) > M;
    tail(index).M = M;
    tail(index).spectral_tail_L = norm( ...
      spectrum.spectral_weighted_cauchy_L_row_norm(mask)) / ...
      max(spectral_total_L, eps);
    tail(index).spectral_tail_R = norm( ...
      spectrum.spectral_weighted_cauchy_R_row_norm(mask)) / ...
      max(spectral_total_R, eps);
    tail(index).spectral_tail_max = max(tail(index).spectral_tail_L, ...
      tail(index).spectral_tail_R);
    tail(index).direct_tail_L = ...
      norm(spectrum.weighted_cauchy_L_row_norm(mask)) / max(direct_total_L, eps);
    tail(index).direct_tail_R = ...
      norm(spectrum.weighted_cauchy_R_row_norm(mask)) / max(direct_total_R, eps);
    tail(index).direct_tail_max = max(tail(index).direct_tail_L, ...
      tail(index).direct_tail_R);
    tail(index).discrepancy_tail_L = norm( ...
      spectrum.discrepancy_weighted_cauchy_L_row_norm(mask)) / ...
      max(discrepancy_scale_L, eps);
    tail(index).discrepancy_tail_R = norm( ...
      spectrum.discrepancy_weighted_cauchy_R_row_norm(mask)) / ...
      max(discrepancy_scale_R, eps);
    tail(index).discrepancy_tail_max = max( ...
      tail(index).discrepancy_tail_L, tail(index).discrepancy_tail_R);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function values = LOCAL_row_norms(A)
  values = sqrt(sum(abs(A) .^ 2, 2));
end

%% ==================== Square cell and ordered-QZ diagnostics ====================
% These helpers record raw stability evidence without deciding M_stable.

function sample = LOCAL_square_sample(config, rectangular, M, runtime)
  sample = LOCAL_empty_square();
  sample.M = M;
  sample.K = 2 * M + 1;
  token_total = tic;
  try
    token = tic;
    channels = bloch.rayleigh_channels(config.k, config.beta, ...
      config.period_y, M, config.period_x);
    sample.timing.channel_seconds = toc(token);
    sample.minimum_abs_gamma = min(abs(channels.gamma_m));
    [present_out, output_indices] = ismember(channels.m, ...
      rectangular.channels_out.m);
    [present_in, input_indices] = ismember(channels.m, ...
      rectangular.channels_in.m);
    if ~(all(present_out) && all(present_in))
      error('run_i4_rayleigh_budget:MasterRestriction', ...
        'Square channels must be contained in the master response.');
    end
    token = tic;
    blocks.R_L = rectangular.R_L(output_indices, input_indices);
    blocks.T_LR = rectangular.T_LR(output_indices, input_indices);
    blocks.T_RL = rectangular.T_RL(output_indices, input_indices);
    blocks.R_R = rectangular.R_R(output_indices, input_indices);
    blocks.K = channels.K;
    sample.blocks = blocks;
    sample.timing.master_restriction_seconds = toc(token);
    sample.cell_solve_relative_residual = rectangular.solve_relative_residual;
    sample.channels = channels;
    sample.transmission = LOCAL_transmission_metrics(blocks, channels);

    token = tic;
    sample.qz = LOCAL_qz_metrics(sample.blocks, channels, config);
    sample.timing.qz_seconds = toc(token);

    token = tic;
    sample.perturbation = LOCAL_perturbation_metrics(sample.blocks, ...
      channels, sample.qz, config);
    sample.timing.perturbation_seconds = toc(token);

    token = tic;
    sample.doubling = LOCAL_doubling_metrics(sample.blocks, channels, ...
      sample.qz, config);
    sample.timing.doubling_seconds = toc(token);
    sample.status = 'TIMING_EVIDENCE_RECORDED_NO_M_STABLE_DECISION';
  catch ME
    sample.status = 'TIMING_SAMPLE_FAILED';
    sample.error_id = ME.identifier;
    sample.error_message = strrep(ME.message, sprintf('\n'), ' ');
  end
  sample.timing.total_seconds = toc(token_total);
  LOCAL_check_deadline(runtime, sprintf('square M=%d sample', M));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function metrics = LOCAL_transmission_metrics(S, channels)
  singular_LR = svd(S.T_LR);
  singular_RL = svd(S.T_RL);
  relative_tolerances = [eps * channels.K, 1e-14, 1e-12, 1e-10];
  ranks_LR = zeros(size(relative_tolerances));
  ranks_RL = zeros(size(relative_tolerances));
  for j = 1:length(relative_tolerances)
    ranks_LR(j) = sum(singular_LR > ...
      relative_tolerances(j) * singular_LR(1));
    ranks_RL(j) = sum(singular_RL > ...
      relative_tolerances(j) * singular_RL(1));
  end
  metrics.singular_values_LR = singular_LR;
  metrics.singular_values_RL = singular_RL;
  metrics.minimum_singular_value_LR = singular_LR(end);
  metrics.maximum_singular_value_LR = singular_LR(1);
  metrics.minimum_singular_value_RL = singular_RL(end);
  metrics.maximum_singular_value_RL = singular_RL(1);
  metrics.relative_rank_tolerances = relative_tolerances;
  metrics.numerical_ranks_LR = ranks_LR;
  metrics.numerical_ranks_RL = ranks_RL;
  metrics.minimum_phase_abs = min(abs(channels.phase));
  metrics.maximum_phase_abs = max(abs(channels.phase));
  metrics.ledger_only = true;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function qz_info = LOCAL_qz_metrics(S, channels, config)
  K = S.K;
  I = eye(K);
  Z0 = zeros(K);
  A_sc = [-S.R_L, I; S.T_LR, Z0];
  B_sc = [Z0, S.T_RL; I, -S.R_R];
  [S0, T0, Q0, Z_qz] = qz(A_sc, B_sc, 'complex');
  classification = LOCAL_classify_qz(diag(S0), diag(T0), ...
    A_sc, B_sc, config);
  stable = LOCAL_ordered_qz(A_sc, B_sc, S0, T0, Q0, Z_qz, ...
    classification.stable, K);
  unstable = LOCAL_ordered_qz(A_sc, B_sc, S0, T0, Q0, Z_qz, ...
    classification.unstable, K);

  qz_info = LOCAL_empty_qz();
  qz_info.stable_count = classification.stable_count;
  qz_info.unstable_count = classification.unstable_count;
  qz_info.neutral_count = classification.neutral_count;
  qz_info.infinite_count = classification.infinite_count;
  qz_info.indeterminate_count = classification.indeterminate_count;
  qz_info.minimum_unit_gap = classification.minimum_unit_gap;
  qz_info.stable = stable;
  qz_info.unstable = unstable;
  if ~(stable.available && unstable.available)
    qz_info.status = 'ORDERED_SUBSPACES_UNAVAILABLE';
    return;
  end

  A_stable = stable.Z(1:K, :);
  B_stable = stable.Z(K + 1:end, :);
  [R_plus, graph_residual_plus] = ...
    LOCAL_right_solve_with_residual(B_stable, A_stable);
  A_unstable = unstable.Z(1:K, :);
  B_unstable = unstable.Z(K + 1:end, :);
  [R_minus, graph_residual_minus] = ...
    LOCAL_right_solve_with_residual(A_unstable, B_unstable);
  qz_info.R_plus = R_plus;
  qz_info.R_minus = R_minus;
  qz_info.graph_residual_plus = graph_residual_plus;
  qz_info.graph_residual_minus = graph_residual_minus;
  qz_info.rcond_A_stable = rcond(A_stable);
  qz_info.rcond_B_unstable = rcond(B_unstable);

  factor_plus = I - R_plus * S.R_R;
  [fixed_plus, solve_plus] = LOCAL_left_solve( ...
    factor_plus, R_plus * S.T_LR);
  factor_minus = I - R_minus * S.R_L;
  [fixed_minus, solve_minus] = LOCAL_left_solve( ...
    factor_minus, R_minus * S.T_RL);
  qz_info.fixed_residual_plus = LOCAL_relerr( ...
    R_plus, S.R_L + S.T_RL * fixed_plus);
  qz_info.fixed_residual_minus = LOCAL_relerr( ...
    R_minus, S.R_R + S.T_LR * fixed_minus);
  qz_info.fixed_solve_plus = solve_plus;
  qz_info.fixed_solve_minus = solve_minus;
  Gamma = diag(channels.gamma_m(:));
  [qz_info.DtN_plus, qz_info.cayley_residual_plus] = ...
    LOCAL_cayley(R_plus, Gamma);
  [qz_info.DtN_minus, qz_info.cayley_residual_minus] = ...
    LOCAL_cayley(R_minus, Gamma);
  qz_info.available = true;
  qz_info.status = 'ORDERED_SUBSPACES_RECORDED_NO_STABILITY_DECISION';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function classification = LOCAL_classify_qz(alpha, beta_qz, A, B, config)
  pair_scale = abs(alpha) + abs(beta_qz);
  global_scale = config.qz_pair_tolerance * ...
    max([1, norm(A, 'fro'), norm(B, 'fro')]);
  indeterminate = pair_scale <= global_scale;
  infinite = ~indeterminate & abs(beta_qz) <= ...
    config.qz_pair_tolerance .* max(abs(alpha), abs(beta_qz));
  finite = ~indeterminate & ~infinite;
  lambda = NaN(size(alpha));
  lambda(finite) = alpha(finite) ./ beta_qz(finite);
  neutral = finite & abs(abs(lambda) - 1) <= config.qz_unit_tolerance;
  stable = finite & abs(lambda) < 1 - config.qz_unit_tolerance;
  unstable = infinite | ...
    (finite & abs(lambda) > 1 + config.qz_unit_tolerance);
  if any(finite)
    minimum_unit_gap = min(abs(abs(lambda(finite)) - 1));
  else
    minimum_unit_gap = NaN;
  end
  classification.stable = stable;
  classification.unstable = unstable;
  classification.stable_count = sum(stable);
  classification.unstable_count = sum(unstable);
  classification.neutral_count = sum(neutral);
  classification.infinite_count = sum(infinite);
  classification.indeterminate_count = sum(indeterminate);
  classification.minimum_unit_gap = minimum_unit_gap;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ordered = LOCAL_ordered_qz(A, B, S0, T0, Q0, Z0, select, K)
  ordered = LOCAL_empty_ordered();
  ordered.selected_count = sum(select);
  if ordered.selected_count ~= K
    ordered.status = 'SELECTED_COUNT_NOT_K';
    return;
  end
  [S_ordered, T_ordered, Q_ordered, Z_ordered] = ...
    ordqz(S0, T0, Q0, Z0, select);
  S_lead = S_ordered(1:K, 1:K);
  T_lead = T_ordered(1:K, 1:K);
  Z_lead = Z_ordered(:, 1:K);
  Q_lead = LOCAL_qz_left_block(A, B, Z_lead, S_lead, ...
    T_lead, Q_ordered, K);
  ordered.residual_A = norm(A * Z_lead - Q_lead * S_lead, 'fro') / ...
    max(1, norm(A, 'fro') * norm(Z_lead, 'fro') + norm(S_lead, 'fro'));
  ordered.residual_B = norm(B * Z_lead - Q_lead * T_lead, 'fro') / ...
    max(1, norm(B, 'fro') * norm(Z_lead, 'fro') + norm(T_lead, 'fro'));
  ordered.Z = Z_lead;
  ordered.Q = Q_lead;
  ordered.S = S_lead;
  ordered.T = T_lead;
  ordered.available = true;
  ordered.status = 'ORDERED_SUBSPACE_AVAILABLE';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Q_lead = LOCAL_qz_left_block(A, B, Z, S, T, Q_ordered, K)
  candidate_matlab = Q_ordered(:, 1:K);
  Q_transpose = Q_ordered';
  candidate_octave = Q_transpose(:, 1:K);
  score_matlab = norm(A * Z - candidate_matlab * S, 'fro') + ...
    norm(B * Z - candidate_matlab * T, 'fro');
  score_octave = norm(A * Z - candidate_octave * S, 'fro') + ...
    norm(B * Z - candidate_octave * T, 'fro');
  if score_matlab <= score_octave
    Q_lead = candidate_matlab;
  else
    Q_lead = candidate_octave;
  end
end

%% ==================== Deterministic data perturbations ====================
% These helpers measure QZ-map sensitivity to reproducible relative changes.

function rows = LOCAL_perturbation_metrics(S, channels, qz_reference, config)
  rows = repmat(LOCAL_empty_perturbation_row(), ...
    length(config.perturbation_epsilons), 1);
  actions = LOCAL_action_columns(channels, config.action_column_count);
  for j = 1:length(config.perturbation_epsilons)
    epsilon_data = config.perturbation_epsilons(j);
    row = LOCAL_empty_perturbation_row();
    row.epsilon_data = epsilon_data;
    [perturbed, row.relative_data_perturbation] = ...
      LOCAL_perturb_blocks(S, epsilon_data);
    qz_perturbed = LOCAL_qz_metrics(perturbed, channels, config);
    row.qz_status = qz_perturbed.status;
    row.stable_count = qz_perturbed.stable_count;
    row.unstable_count = qz_perturbed.unstable_count;
    row.neutral_count = qz_perturbed.neutral_count;
    row.infinite_count = qz_perturbed.infinite_count;
    row.indeterminate_count = qz_perturbed.indeterminate_count;
    row.minimum_unit_gap = qz_perturbed.minimum_unit_gap;
    row.qz_residual_max = max([qz_perturbed.stable.residual_A, ...
      qz_perturbed.stable.residual_B, ...
      qz_perturbed.unstable.residual_A, ...
      qz_perturbed.unstable.residual_B]);
    row.graph_rcond_min = min([qz_perturbed.rcond_A_stable, ...
      qz_perturbed.rcond_B_unstable]);
    if qz_reference.available && qz_perturbed.available
      row.classification_preserved = ...
        qz_perturbed.stable_count == qz_reference.stable_count && ...
        qz_perturbed.unstable_count == qz_reference.unstable_count && ...
        qz_perturbed.neutral_count == qz_reference.neutral_count && ...
        qz_perturbed.indeterminate_count == ...
        qz_reference.indeterminate_count;
      row.DtN_action_change_plus = LOCAL_action_error( ...
        qz_perturbed.DtN_plus, qz_reference.DtN_plus, actions, channels);
      row.DtN_action_change_minus = LOCAL_action_error( ...
        qz_perturbed.DtN_minus, qz_reference.DtN_minus, actions, channels);
      row.kappa = max(row.DtN_action_change_plus, ...
        row.DtN_action_change_minus) / max(row.relative_data_perturbation, eps);
      row.pass = row.classification_preserved && ...
        row.qz_residual_max <= config.qz_residual_tolerance && ...
        row.graph_rcond_min >= config.qz_rcond_floor && ...
        row.kappa <= config.perturbation_kappa_limit;
    end
    rows(j) = row;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [perturbed, relative_change] = LOCAL_perturb_blocks(S, epsilon_data)
  names = {'R_L', 'T_LR', 'T_RL', 'R_R'};
  K = S.K;
  [row_index, column_index] = ndgrid(1:K, 1:K);
  data_norm_squared = 0;
  direction_norm_squared = 0;
  direction = struct();
  for j = 1:length(names)
    name = names{j};
    data_norm_squared = data_norm_squared + norm(S.(name), 'fro') ^ 2;
    angle = sqrt(2) * row_index + sqrt(3) * column_index + sqrt(5) * j;
    direction.(name) = exp(1i * angle);
    direction_norm_squared = direction_norm_squared + ...
      norm(direction.(name), 'fro') ^ 2;
  end
  data_norm = sqrt(data_norm_squared);
  scale = epsilon_data * max(data_norm, eps) / sqrt(direction_norm_squared);
  change_norm_squared = 0;
  perturbed = S;
  for j = 1:length(names)
    name = names{j};
    change = scale * direction.(name);
    perturbed.(name) = S.(name) + change;
    actual_change = perturbed.(name) - S.(name);
    change_norm_squared = change_norm_squared + ...
      norm(actual_change, 'fro') ^ 2;
  end
  relative_change = sqrt(change_norm_squared) / max(data_norm, eps);
end

%% ==================== Doubling reflection and DtN actions ====================
% These helpers time finite-depth self-composition against QZ reference maps.

function rows = LOCAL_doubling_metrics(S, channels, qz_info, config)
  rows = repmat(LOCAL_empty_doubling_row(), ...
    length(config.doubling_levels), 1);
  current = S;
  Gamma = diag(channels.gamma_m(:));
  actions = LOCAL_action_columns(channels, config.action_column_count);
  for j = 1:length(config.doubling_levels)
    level = config.doubling_levels(j);
    row = LOCAL_empty_doubling_row();
    row.level = level;
    row.num_cells = 2 ^ level;
    row.reflection_right_norm = norm(current.R_L, 'fro');
    row.reflection_left_norm = norm(current.R_R, 'fro');
    [DtN_right, cayley_right] = LOCAL_cayley(current.R_L, Gamma);
    [DtN_left, cayley_left] = LOCAL_cayley(current.R_R, Gamma);
    row.cayley_residual_right = cayley_right;
    row.cayley_residual_left = cayley_left;
    if qz_info.available
      row.reflection_error_right = ...
        LOCAL_relerr(current.R_L, qz_info.R_plus);
      row.reflection_error_left = ...
        LOCAL_relerr(current.R_R, qz_info.R_minus);
      row.DtN_action_error_right = LOCAL_action_error( ...
        DtN_right, qz_info.DtN_plus, actions, channels);
      row.DtN_action_error_left = LOCAL_action_error( ...
        DtN_left, qz_info.DtN_minus, actions, channels);
    end
    if j < length(config.doubling_levels)
      token = tic;
      [current, star] = LOCAL_star(current, current);
      row.self_star_seconds = toc(token);
      row.interface_rcond = min(star.rcond_GA, star.rcond_GB);
      row.interface_solve_residual = max(star.residual_GA, star.residual_GB);
    end
    rows(j) = row;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function actions = LOCAL_action_columns(channels, count)
  K = channels.K;
  index = (0:K - 1).';
  xi_weight = sqrt(1 + abs(channels.beta_m(:)) .^ 2);
  actions = zeros(K, count);
  for j = 1:count
    column = exp(2i * pi * j * index / max(K, 1));
    weighted_norm = sqrt(sum(xi_weight .* abs(column) .^ 2));
    actions(:, j) = column / max(weighted_norm, eps);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function error_value = LOCAL_action_error(actual, reference, actions, channels)
  xi_weight = sqrt(1 + abs(channels.beta_m(:)) .^ 2);
  difference = bsxfun(@rdivide, (actual - reference) * actions, ...
    sqrt(xi_weight));
  reference_action = bsxfun(@rdivide, reference * actions, ...
    sqrt(xi_weight));
  error_value = norm(difference, 'fro') / ...
    max(1, norm(reference_action, 'fro'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [AB, info] = LOCAL_star(A, B)
  K = A.K;
  I = eye(K);
  GA = I - A.R_R * B.R_L;
  GB = I - B.R_L * A.R_R;
  [X_tlr, residual_tlr] = LOCAL_left_solve(GA, A.T_LR);
  [X_rr, residual_rr] = LOCAL_left_solve(GA, A.R_R * B.T_RL);
  [X_trl, residual_trl] = LOCAL_left_solve(GB, B.T_RL);
  AB.R_L = A.R_L + A.T_RL * B.R_L * X_tlr;
  AB.T_LR = B.T_LR * X_tlr;
  AB.T_RL = A.T_RL * X_trl;
  AB.R_R = B.R_R + B.T_LR * X_rr;
  AB.K = K;
  info.rcond_GA = rcond(GA);
  info.rcond_GB = rcond(GB);
  info.residual_GA = max(residual_tlr, residual_rr);
  info.residual_GB = residual_trl;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Lambda, residual] = LOCAL_cayley(R, Gamma)
  factor = eye(size(R, 1)) + R;
  numerator = 1i * Gamma * (eye(size(R, 1)) - R);
  [Lambda, residual] = LOCAL_right_solve_with_residual(numerator, factor);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [X, residual] = LOCAL_left_solve(A, B)
  X = A \ B;
  residual = norm(A * X - B, 'fro') / max(1, norm(B, 'fro'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [X, residual] = LOCAL_right_solve_with_residual(B, A)
  X = (A.' \ B.').';
  residual = norm(X * A - B, 'fro') / max(1, norm(B, 'fro'));
end

%% ==================== Principal restriction comparison ====================
% This helper compares S_M only with the matching central block of S_Mref.

function square = LOCAL_add_principal_restrictions(square, reference_M, ...
    action_column_count)
  reference_index = find([square.M] == reference_M, 1);
  if isempty(reference_index) || isempty(square(reference_index).channels)
    return;
  end
  reference = square(reference_index);
  for j = 1:length(square)
    if isempty(square(j).channels) || square(j).M > reference_M
      continue;
    end
    [present, indices] = ismember(square(j).channels.m, ...
      reference.channels.m);
    if ~all(present)
      continue;
    end
    restricted.R_L = reference.blocks.R_L(indices, indices);
    restricted.T_LR = reference.blocks.T_LR(indices, indices);
    restricted.T_RL = reference.blocks.T_RL(indices, indices);
    restricted.R_R = reference.blocks.R_R(indices, indices);
    errors = [LOCAL_relerr(square(j).blocks.R_L, restricted.R_L), ...
      LOCAL_relerr(square(j).blocks.T_LR, restricted.T_LR), ...
      LOCAL_relerr(square(j).blocks.T_RL, restricted.T_RL), ...
      LOCAL_relerr(square(j).blocks.R_R, restricted.R_R)];
    square(j).principal_restriction_error = max(errors);
    square(j).principal_restriction_available = true;
    if square(j).qz.available && reference.qz.available
      actions = LOCAL_action_columns(square(j).channels, ...
        action_column_count);
      square(j).qz_reference_reflection_error_plus = LOCAL_relerr( ...
        square(j).qz.R_plus, reference.qz.R_plus(indices, indices));
      square(j).qz_reference_reflection_error_minus = LOCAL_relerr( ...
        square(j).qz.R_minus, reference.qz.R_minus(indices, indices));
      square(j).qz_reference_DtN_action_error_plus = LOCAL_action_error( ...
        square(j).qz.DtN_plus, ...
        reference.qz.DtN_plus(indices, indices), actions, ...
        square(j).channels);
      square(j).qz_reference_DtN_action_error_minus = LOCAL_action_error( ...
        square(j).qz.DtN_minus, ...
        reference.qz.DtN_minus(indices, indices), actions, ...
        square(j).channels);
      square(j).qz_reference_available = true;
    end
  end
end

%% ==================== Deterministic timing-only outputs ====================
% These helpers write raw evidence while preserving disabled decision fields.

function LOCAL_write_config(results, output_dir, here)
  fid = LOCAL_open(fullfile(output_dir, 'config.txt'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  c = results.config;
  fprintf(fid, 'experiment_id=%s\n', c.experiment_id);
  fprintf(fid, 'profile=%s\n', c.profile);
  fprintf(fid, 'output_label=%s\n', c.output_label);
  fprintf(fid, 'grid_status=%s\n', c.grid_status);
  fprintf(fid, 'decision_labels_enabled=%d\n', c.decision_labels_enabled);
  fprintf(fid, 'k=%.17g\n', c.k);
  fprintf(fid, 'beta=%.17g\n', c.beta);
  fprintf(fid, 's=%.17g\n', c.s);
  fprintf(fid, 'delta=%.17g\n', c.delta);
  fprintf(fid, 'ntot=%d\n', c.ntot);
  fprintf(fid, 'Ny_wall=%d\n', c.Ny_wall);
  fprintf(fid, 'M_in=%d\n', c.M_in);
  fprintf(fid, 'M_out=%d\n', c.M_out);
  fprintf(fid, 'square_M_values=%s\n', mat2str(c.square_M_values));
  fprintf(fid, 'square_reference_M=%d\n', c.square_reference_M);
  fprintf(fid, 'doubling_levels=%s\n', mat2str(c.doubling_levels));
  fprintf(fid, 'proxy_N_side=%d\n', c.proxy.N_side);
  fprintf(fid, 'proxy_N_top=%d\n', c.proxy.N_top);
  fprintf(fid, 'proxy_N_proxy_edge=%d\n', c.proxy.N_proxy_edge);
  fprintf(fid, 'proxy_M_pw=%d\n', c.proxy.M_pw);
  fprintf(fid, 'extractor_validation_tolerance=%.17g\n', ...
    c.extractor_validation_tolerance);
  fprintf(fid, 'trace_tail_tolerance=%.17g\n', c.trace_tail_tolerance);
  fprintf(fid, 'qz_residual_tolerance=%.17g\n', ...
    c.qz_residual_tolerance);
  fprintf(fid, 'qz_rcond_floor=%.17g\n', c.qz_rcond_floor);
  fprintf(fid, 'doubling_action_tolerance=%.17g\n', ...
    c.doubling_action_tolerance);
  fprintf(fid, 'ntot_action_tolerance=%.17g\n', ...
    c.ntot_action_tolerance);
  fprintf(fid, 'perturbation_epsilons=%s\n', ...
    mat2str(c.perturbation_epsilons));
  fprintf(fid, 'perturbation_kappa_limit=%.17g\n', ...
    c.perturbation_kappa_limit);
  fprintf(fid, 'max_runtime_seconds=%d\n', c.max_runtime_seconds);
  fprintf(fid, 'command=%s\n', sprintf(c.command, here));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_rectangular_summary(results, output_dir)
  r = results.rectangular;
  fid = LOCAL_open(fullfile(output_dir, 'rectangular-summary.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['profile,M_in,K_in,M_out,K_out,min_abs_gamma,', ...
    'solve_relative_residual,extractor_error_L_D,extractor_error_R_D,', ...
    'extractor_error_L_N,extractor_error_R_N,extractor_validation_error,', ...
    'extractor_validation_pass,status,M_trace,M_trace_status\n']);
  LOCAL_write_csv_row(fid, {results.config.profile, r.M_in, r.K_in, ...
    r.M_out, r.K_out, r.minimum_abs_gamma, r.solve_relative_residual, ...
    r.extractor_error_L_D, r.extractor_error_R_D, ...
    r.extractor_error_L_N, r.extractor_error_R_N, ...
    r.extractor_validation_error, r.extractor_validation_pass, ...
    r.status, results.M_trace, results.M_trace_status});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_trace_spectrum(results, output_dir)
  spectrum = results.rectangular.spectrum;
  fid = LOCAL_open(fullfile(output_dir, 'trace-spectrum.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['profile,M_in,M_out,index,m,beta_m,gamma_real,gamma_imag,', ...
    'outgoing_L_row_norm,outgoing_R_row_norm,', ...
    'outgoing_derivative_L_row_norm,outgoing_derivative_R_row_norm,', ...
    'direct_D_L_row_norm,direct_D_R_row_norm,', ...
    'direct_Dx_L_row_norm,direct_Dx_R_row_norm,', ...
    'xi_weight,weighted_cauchy_L_row_norm,', ...
    'weighted_cauchy_R_row_norm,', ...
    'spectral_weighted_cauchy_L_row_norm,', ...
    'spectral_weighted_cauchy_R_row_norm,', ...
    'discrepancy_weighted_cauchy_L_row_norm,', ...
    'discrepancy_weighted_cauchy_R_row_norm\n']);
  for j = 1:length(spectrum.m)
    LOCAL_write_csv_row(fid, {results.config.profile, ...
      results.rectangular.M_in, results.rectangular.M_out, j, ...
      spectrum.m(j), spectrum.beta_m(j), real(spectrum.gamma_m(j)), ...
      imag(spectrum.gamma_m(j)), spectrum.outgoing_L_row_norm(j), ...
      spectrum.outgoing_R_row_norm(j), ...
      spectrum.outgoing_derivative_L_row_norm(j), ...
      spectrum.outgoing_derivative_R_row_norm(j), ...
      spectrum.direct_D_L_row_norm(j), spectrum.direct_D_R_row_norm(j), ...
      spectrum.direct_Dx_L_row_norm(j), spectrum.direct_Dx_R_row_norm(j), ...
      spectrum.xi_weight(j), spectrum.weighted_cauchy_L_row_norm(j), ...
      spectrum.weighted_cauchy_R_row_norm(j), ...
      spectrum.spectral_weighted_cauchy_L_row_norm(j), ...
      spectrum.spectral_weighted_cauchy_R_row_norm(j), ...
      spectrum.discrepancy_weighted_cauchy_L_row_norm(j), ...
      spectrum.discrepancy_weighted_cauchy_R_row_norm(j)});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_trace_tail(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'trace-tail.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['profile,M_probe,M_out,candidate_M,spectral_tail_L,', ...
    'spectral_tail_R,spectral_tail_max,direct_tail_L,direct_tail_R,', ...
    'direct_tail_max,discrepancy_tail_L,discrepancy_tail_R,', ...
    'discrepancy_tail_max,tau_tail,reference_gate_status\n']);
  for j = 1:length(results.rectangular.tail)
    row = results.rectangular.tail(j);
    LOCAL_write_csv_row(fid, {results.config.profile, ...
      results.config.M_probe, results.config.M_out, row.M, ...
      row.spectral_tail_L, row.spectral_tail_R, row.spectral_tail_max, ...
      row.direct_tail_L, row.direct_tail_R, row.direct_tail_max, ...
      row.discrepancy_tail_L, row.discrepancy_tail_R, ...
      row.discrepancy_tail_max, results.config.trace_tail_tolerance, ...
      'INCONCLUSIVE_REFERENCE_LEVEL_PENDING'});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_square_summary(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'square-summary.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['profile,M,K,status,min_abs_gamma,cell_solve_residual,', ...
    'principal_restriction_available,principal_restriction_error,', ...
    'qz_status,qz_stable_count,qz_unstable_count,qz_neutral_count,', ...
    'qz_infinite_count,qz_indeterminate_count,qz_minimum_unit_gap,', ...
    'stable_residual_A,stable_residual_B,unstable_residual_A,', ...
    'unstable_residual_B,graph_residual_plus,graph_residual_minus,', ...
    'rcond_A_stable,rcond_B_unstable,fixed_residual_plus,', ...
    'fixed_residual_minus,fixed_solve_plus,fixed_solve_minus,', ...
    'qz_maps_available,qz_reference_available,', ...
    'qz_reference_reflection_error_plus,', ...
    'qz_reference_reflection_error_minus,', ...
    'qz_reference_weighted_DtN_action_error_plus,', ...
    'qz_reference_weighted_DtN_action_error_minus,', ...
    'final_doubling_level,', ...
    'final_weighted_DtN_action_error_max,', ...
    'final_reflection_closure_error_max,M_stable,M_stable_status,', ...
    'error_id,error_message\n']);
  for j = 1:length(results.square)
    s = results.square(j);
    final = LOCAL_final_doubling_row(s.doubling);
    LOCAL_write_csv_row(fid, {results.config.profile, s.M, s.K, s.status, ...
      s.minimum_abs_gamma, s.cell_solve_relative_residual, ...
      s.principal_restriction_available, ...
      s.principal_restriction_error, s.qz.status, s.qz.stable_count, ...
      s.qz.unstable_count, s.qz.neutral_count, s.qz.infinite_count, ...
      s.qz.indeterminate_count, s.qz.minimum_unit_gap, ...
      s.qz.stable.residual_A, s.qz.stable.residual_B, ...
      s.qz.unstable.residual_A, s.qz.unstable.residual_B, ...
      s.qz.graph_residual_plus, s.qz.graph_residual_minus, ...
      s.qz.rcond_A_stable, s.qz.rcond_B_unstable, ...
      s.qz.fixed_residual_plus, s.qz.fixed_residual_minus, ...
      s.qz.fixed_solve_plus, s.qz.fixed_solve_minus, s.qz.available, ...
      s.qz_reference_available, ...
      s.qz_reference_reflection_error_plus, ...
      s.qz_reference_reflection_error_minus, ...
      s.qz_reference_DtN_action_error_plus, ...
      s.qz_reference_DtN_action_error_minus, ...
      final.level, max(final.DtN_action_error_right, ...
      final.DtN_action_error_left), max(final.reflection_error_right, ...
      final.reflection_error_left), results.M_stable, ...
      results.M_stable_status, ...
      s.error_id, s.error_message});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_transmission_ledger(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'transmission-ledger.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['profile,M,K,direction,min_singular_value,', ...
    'max_singular_value,min_phase_abs,max_phase_abs,', ...
    'relative_rank_tolerance,numerical_rank,ledger_only\n']);
  for j = 1:length(results.square)
    sample = results.square(j);
    if isempty(sample.transmission)
      continue;
    end
    t = sample.transmission;
    for k = 1:length(t.relative_rank_tolerances)
      LOCAL_write_csv_row(fid, {results.config.profile, sample.M, sample.K, ...
        'T_LR', t.minimum_singular_value_LR, ...
        t.maximum_singular_value_LR, t.minimum_phase_abs, ...
        t.maximum_phase_abs, t.relative_rank_tolerances(k), ...
        t.numerical_ranks_LR(k), t.ledger_only});
      LOCAL_write_csv_row(fid, {results.config.profile, sample.M, sample.K, ...
        'T_RL', t.minimum_singular_value_RL, ...
        t.maximum_singular_value_RL, t.minimum_phase_abs, ...
        t.maximum_phase_abs, t.relative_rank_tolerances(k), ...
        t.numerical_ranks_RL(k), t.ledger_only});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_perturbations(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'perturbation.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['profile,M,K,epsilon_data,relative_data_perturbation,', ...
    'qz_status,stable_count,unstable_count,neutral_count,infinite_count,', ...
    'indeterminate_count,minimum_unit_gap,qz_residual_max,', ...
    'graph_rcond_min,classification_preserved,', ...
    'DtN_action_change_plus,DtN_action_change_minus,kappa,kappa_limit,', ...
    'perturbation_gate_pass\n']);
  for j = 1:length(results.square)
    sample = results.square(j);
    for k = 1:length(sample.perturbation)
      row = sample.perturbation(k);
      LOCAL_write_csv_row(fid, {results.config.profile, sample.M, sample.K, ...
        row.epsilon_data, row.relative_data_perturbation, row.qz_status, ...
        row.stable_count, row.unstable_count, row.neutral_count, ...
        row.infinite_count, row.indeterminate_count, row.minimum_unit_gap, ...
        row.qz_residual_max, row.graph_rcond_min, ...
        row.classification_preserved, row.DtN_action_change_plus, ...
        row.DtN_action_change_minus, row.kappa, ...
        results.config.perturbation_kappa_limit, row.pass});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_doubling(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'doubling.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['profile,M,K,level,num_cells,reflection_right_norm,', ...
    'reflection_left_norm,reflection_error_right,reflection_error_left,', ...
    'DtN_action_error_right,DtN_action_error_left,', ...
    'cayley_residual_right,cayley_residual_left,self_star_seconds,', ...
    'interface_rcond,interface_solve_residual\n']);
  for j = 1:length(results.square)
    sample = results.square(j);
    for k = 1:length(sample.doubling)
      row = sample.doubling(k);
      LOCAL_write_csv_row(fid, {results.config.profile, sample.M, ...
        sample.K, row.level, row.num_cells, row.reflection_right_norm, ...
        row.reflection_left_norm, row.reflection_error_right, ...
        row.reflection_error_left, row.DtN_action_error_right, ...
        row.DtN_action_error_left, row.cayley_residual_right, ...
        row.cayley_residual_left, row.self_star_seconds, ...
        row.interface_rcond, row.interface_solve_residual});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_timings(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'timings.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'profile,scope,M,stage,seconds\n');
  LOCAL_write_csv_row(fid, {results.config.profile, 'shared', NaN, ...
    'proxy', results.shared_timing.proxy_seconds});
  names = fieldnames(results.rectangular.timing);
  for j = 1:length(names)
    LOCAL_write_csv_row(fid, {results.config.profile, 'rectangular', ...
      results.rectangular.M_out, names{j}, ...
      results.rectangular.timing.(names{j})});
  end
  for j = 1:length(results.square)
    names = fieldnames(results.square(j).timing);
    for k = 1:length(names)
      LOCAL_write_csv_row(fid, {results.config.profile, 'square', ...
        results.square(j).M, names{k}, ...
        results.square(j).timing.(names{k})});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'report.md'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# I4 Rayleigh-budget timing scaffold\n\n');
  fprintf(fid, '- Profile: `%s`\n', results.config.profile);
  fprintf(fid, '- Output label: `%s`\n', results.config.output_label);
  fprintf(fid, '- Grid status: `%s`\n', results.config.grid_status);
  fprintf(fid, '- Decision labels enabled: `%d`\n', ...
    results.decision_labels_enabled);
  fprintf(fid, '- M_trace: `NaN` (`%s`)\n', results.M_trace_status);
  fprintf(fid, '- M_stable: `NaN` (`%s`)\n', results.M_stable_status);
  fprintf(fid, '- Root claim: `%d`\n', results.root_claim);
  fprintf(fid, '- Eigenvalue claim: `%d`\n', results.eigenvalue_claim);
  fprintf(fid, '- Elapsed seconds: %.6f\n\n', results.elapsed_seconds);
  fprintf(fid, ['The rectangular run records physical BIE response columns, ', ...
    'direct-wall Cauchy projections, outgoing spectral tails, direct-wall ', ...
    'tails, and their common-mode discrepancy.  Direct-wall agreement is ', ...
    'an extractor-validation gate only; no one tail defines M_trace.\n\n']);
  fprintf(fid, ['The square runs record principal restrictions, projective ', ...
    'ordered-QZ deflating-subspace residuals, and finite-depth reflection/', ...
    'DtN action comparisons.  Deterministic data perturbations record a ', ...
    'weighted DtN-action condition metric.  Transmission rank is not used ', ...
    'as a gate, and the missing cross-ntot comparison leaves M_stable ', ...
    'inconclusive.\n']);
  fprintf(fid, ['This is a case-local report and does not perform low/high ', ...
    'pairing.  The batch aggregate performs and records the independent ', ...
    'ntot action-sensitivity comparison.\n']);
end

%% ==================== Runtime, schemas, and CSV helpers ====================
% These helpers keep partial timing fields stable and outputs machine-readable.

function config = LOCAL_apply_overrides(config, overrides)
  if ~(isstruct(overrides) && isscalar(overrides))
    error('run_i4_rayleigh_budget:InvalidOverrides', ...
      'overrides must be a scalar struct.');
  end
  names = fieldnames(overrides);
  for j = 1:length(names)
    name = names{j};
    if ~isfield(config, name)
      error('run_i4_rayleigh_budget:UnknownOverride', ...
        'Unknown configuration override %s.', name);
    end
    if strcmp(name, 'proxy')
      proxy_names = fieldnames(overrides.proxy);
      for k = 1:length(proxy_names)
        proxy_name = proxy_names{k};
        if ~isfield(config.proxy, proxy_name)
          error('run_i4_rayleigh_budget:UnknownProxyOverride', ...
            'Unknown proxy override %s.', proxy_name);
        end
        config.proxy.(proxy_name) = overrides.proxy.(proxy_name);
      end
    else
      config.(name) = overrides.(name);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = LOCAL_output_label(label)
  if isstring(label)
    label = char(label);
  end
  if ~(ischar(label) && isrow(label) && ~isempty(label) && ...
      ~isempty(regexp(label, '^[A-Za-z0-9._-]+$', 'once')))
    error('run_i4_rayleigh_budget:InvalidOutputLabel', ...
      'output_label must contain only letters, digits, dot, underscore, or dash.');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_check_deadline(runtime, label)
  elapsed = toc(runtime.start_token);
  if elapsed >= runtime.max_seconds
    error('run_i4_rayleigh_budget:RuntimeCap', ...
      'Runtime cap reached after %.1f seconds before %s.', elapsed, label);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rectangular = LOCAL_empty_rectangular()
  rectangular = struct('M_in', NaN, 'M_out', NaN, 'K_in', NaN, ...
    'K_out', NaN, 'channels_in', [], 'channels_out', [], ...
    'minimum_abs_gamma', NaN, ...
    'solve_relative_residual', NaN, 'R_L', [], 'T_LR', [], ...
    'T_RL', [], 'R_R', [], 'extractor_error_L_D', NaN, ...
    'extractor_error_R_D', NaN, 'extractor_error_L_N', NaN, ...
    'extractor_error_R_N', NaN, 'extractor_validation_error', NaN, ...
    'extractor_validation_pass', false, 'spectrum', struct(), ...
    'tail', [], ...
    'timing', struct(), 'status', 'not-run');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function square = LOCAL_empty_square()
  square = struct('M', NaN, 'K', NaN, 'minimum_abs_gamma', NaN, ...
    'cell_solve_relative_residual', NaN, 'channels', [], 'blocks', [], ...
    'transmission', [], ...
    'qz', LOCAL_empty_qz(), ...
    'perturbation', repmat(LOCAL_empty_perturbation_row(), 0, 1), ...
    'doubling', repmat(LOCAL_empty_doubling_row(), 0, 1), ...
    'principal_restriction_available', false, ...
    'principal_restriction_error', NaN, ...
    'qz_reference_available', false, ...
    'qz_reference_reflection_error_plus', NaN, ...
    'qz_reference_reflection_error_minus', NaN, ...
    'qz_reference_DtN_action_error_plus', NaN, ...
    'qz_reference_DtN_action_error_minus', NaN, 'timing', struct(), ...
    'status', 'not-run', 'error_id', '', 'error_message', '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function qz_info = LOCAL_empty_qz()
  qz_info = struct('stable_count', NaN, 'unstable_count', NaN, ...
    'neutral_count', NaN, 'infinite_count', NaN, ...
    'indeterminate_count', NaN, 'minimum_unit_gap', NaN, ...
    'stable', LOCAL_empty_ordered(), 'unstable', LOCAL_empty_ordered(), ...
    'R_plus', [], 'R_minus', [], 'graph_residual_plus', NaN, ...
    'graph_residual_minus', NaN, 'rcond_A_stable', NaN, ...
    'rcond_B_unstable', NaN, 'fixed_residual_plus', NaN, ...
    'fixed_residual_minus', NaN, 'fixed_solve_plus', NaN, ...
    'fixed_solve_minus', NaN, 'DtN_plus', [], 'DtN_minus', [], ...
    'cayley_residual_plus', NaN, 'cayley_residual_minus', NaN, ...
    'available', false, 'status', 'not-run');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ordered = LOCAL_empty_ordered()
  ordered = struct('selected_count', NaN, 'Z', [], 'Q', [], ...
    'S', [], 'T', [], 'residual_A', NaN, 'residual_B', NaN, ...
    'available', false, 'status', 'not-run');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_empty_perturbation_row()
  row = struct('epsilon_data', NaN, 'relative_data_perturbation', NaN, ...
    'qz_status', 'not-run', 'stable_count', NaN, ...
    'unstable_count', NaN, 'neutral_count', NaN, 'infinite_count', NaN, ...
    'indeterminate_count', NaN, 'minimum_unit_gap', NaN, ...
    'qz_residual_max', NaN, 'graph_rcond_min', NaN, ...
    'classification_preserved', false, 'DtN_action_change_plus', NaN, ...
    'DtN_action_change_minus', NaN, 'kappa', NaN, 'pass', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_empty_doubling_row()
  row = struct('level', NaN, 'num_cells', NaN, ...
    'reflection_right_norm', NaN, 'reflection_left_norm', NaN, ...
    'reflection_error_right', NaN, 'reflection_error_left', NaN, ...
    'DtN_action_error_right', NaN, 'DtN_action_error_left', NaN, ...
    'cayley_residual_right', NaN, 'cayley_residual_left', NaN, ...
    'self_star_seconds', NaN, 'interface_rcond', NaN, ...
    'interface_solve_residual', NaN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_final_doubling_row(rows)
  row = LOCAL_empty_doubling_row();
  if ~isempty(rows)
    row = rows(end);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function error_value = LOCAL_relerr(actual, expected)
  error_value = norm(actual - expected, 'fro') / ...
    max(1, norm(expected, 'fro'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_csv_row(fid, values)
  encoded = cell(size(values));
  for j = 1:length(values)
    value = values{j};
    if ischar(value)
      encoded{j} = LOCAL_csv_quote(value);
    elseif islogical(value) && isscalar(value)
      encoded{j} = sprintf('%d', value);
    elseif isnumeric(value) && isscalar(value)
      encoded{j} = sprintf('%.17g', value);
    else
      error('run_i4_rayleigh_budget:CsvValue', ...
        'CSV values must be character strings or numeric scalars.');
    end
  end
  fprintf(fid, '%s\n', strjoin(encoded, ','));
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
    error('run_i4_rayleigh_budget:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end
