function results = run_bie_bidirectional_pencil_diagnostic()
% RUN_BIE_BIDIRECTIONAL_PENCIL_DIAGNOSTIC Build stable port bases at one k.
%
% Purpose:
%   Diagnose forward and reverse small-multiplier bases for the sharp-disk
%   cell at one frozen real-axis sample without changing public packages.
%
% Output:
%   results - Per-M pencil, mode, trace-basis, pairing, legacy-span, and
%             A_def column-scaling invariance diagnostics.
%
% Main algorithm:
%   With A = [-R_L,I;T_LR,0] and B = [0,T_RL;I,-R_R], solve
%   A*v = lambda*B*v and B*w = mu*A*w independently.  Select exactly K
%   small multipliers from each pencil.  For v=[a_L;b_L], form
%   D_+=a_L+b_L and N_+=i*Gamma*(a_L-b_L).  For the reverse projective
%   blocks w=[a_R;b_R], form D_-=a_R+b_R and
%   N_-=-i*Gamma*(a_R-b_R).  Normalize each column using
%   t=[D;N/max(1,abs(k))], then gate residuals, conjugate pairing, trace
%   rank/conditioning, the applicable legacy M=5 span, and fixed
%   column-scaling invariance.
%
% Based on:
%   run_bie_pencil_diagnostic.m, i4_bie_track.m, and the public +geom,
%   +kernel, and +bloch packages.
%
% Main changes:
%   The left-port basis comes from the reverse pencil directly.  No 1/mu
%   multipliers are formed, and all trace normalization is port-local.
%
% Numerical goal:
%   Assign M5_PORT_BASIS_READY_FOR_REAL_AXIS_DIAGNOSTIC or
%   M10_PORT_BASIS_READY_FOR_REAL_AXIS_DIAGNOSTIC only when every frozen
%   gate passes.  This diagnostic never asserts a root or eigenvalue.

  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  addpath(repo_root);
  output_dir = fullfile(here, 'output', 'bie-bidirectional-pencil');
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

  % --- stage 1: frozen single-point configuration ---

  config.model_id = 'sharp-disk-bie-bidirectional-pencil-v1';
  config.k = 1.85;
  config.s = 1;
  config.refractive_index = sqrt(1 + 16 * config.s);
  config.beta = 0.5;
  config.period_x = 1;
  config.period_y = 1;
  config.radius = 0.2;
  config.ntot = 60;
  config.M_values = [5, 10];
  config.unit_tolerance = 1e-4;
  config.mode_residual_tolerance = 1e-8;
  config.pairing_tolerance = 1e-6;
  config.trace_minimum_norm = 1e-14;
  config.trace_rank_relative_tolerance = 1e-10;
  config.trace_condition_limit = 1e10;
  config.legacy_projector_tolerance = 1e-6;
  config.projective_tolerance = 1e-12;
  config.scaling_sigma_absolute_tolerance = 1e-10;
  config.scaling_sigma_relative_tolerance = 1e-6;
  config.num_scaling_tests = 3;
  config.scaling_minimum_amplitude = 1e-4;
  config.scaling_maximum_amplitude = 1e4;
  config.max_runtime_seconds = 60;
  config.proxy.H = config.period_x / 2 + config.radius + 0.4;
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

  % --- stage 2: independent forward/reverse diagnostics for M=5 and M=10 ---

  cases = repmat(LOCAL_empty_case(), length(config.M_values), 1);
  for j = 1:length(config.M_values)
    M = config.M_values(j);
    LOCAL_check_deadline(runtime, sprintf('M=%d start', M));
    fprintf('Bidirectional BIE pencil diagnostic: M = %d.\n', M);
    cases(j) = LOCAL_evaluate_M(config, geometry, M, runtime);
    if cases(j).pass
      cases(j).label = sprintf( ...
        'M%d_PORT_BASIS_READY_FOR_REAL_AXIS_DIAGNOSTIC', M);
    else
      cases(j).label = sprintf('M%d_PORT_BASIS_BLOCKED', M);
    end
    LOCAL_check_deadline(runtime, sprintf('M=%d complete', M));
  end

  results.config = config;
  results.cases = cases;
  results.claim_scope = 'single-point-port-basis-diagnostic-only';
  results.root_claim = false;
  results.eigenvalue_claim = false;
  results.seed_promotion = false;
  results.elapsed_seconds = toc(start_token);
  results.output_dir = output_dir;

  % --- stage 3: independent deterministic evidence bundle ---

  LOCAL_write_case_summary(results, output_dir);
  LOCAL_write_modes(results, output_dir);
  LOCAL_write_qz_pairs(results, output_dir);
  LOCAL_write_trace_singular_values(results, output_dir);
  LOCAL_write_scaling_invariance(results, output_dir);
  LOCAL_write_report(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results');
  fprintf('Diagnostic completed in %.6f seconds.\n', ...
    results.elapsed_seconds);
end

%% ==================== Bidirectional pencil construction ====================
% These helpers build one cell and keep forward and reverse pencils separate.

function one = LOCAL_evaluate_M(config, geometry, M, runtime)
  one = LOCAL_empty_case();
  one.M = M;
  one.K = 2 * M + 1;
  try
    kext = config.k;
    kint = config.refractive_index * kext;
    pars1.k = kext;
    pars1.beta = config.beta;
    pars1.d = config.period_y;
    pars1.periodic_axis = 'y';
    proxy = kernel.precomp_proxy(pars1, config.proxy);
    channels = bloch.rayleigh_channels(kext, config.beta, ...
      config.period_y, M, config.period_x);
    S_cell = bloch.construct_S(geometry.C, kext, kint, pars1, proxy, ...
      geometry.curvelen, channels, -config.period_x / 2, ...
      config.period_x / 2);
    one.cell_solve_relative_residual = ...
      S_cell.solve_relative_residual_norm;

    K = channels.K;
    I = eye(K);
    Z = zeros(K);
    A_sc = [-S_cell.R_L, I; S_cell.T_LR, Z];
    B_sc = [Z, S_cell.T_RL; I, -S_cell.R_R];
    one.qz_forward = LOCAL_qz_diagnostic(A_sc, B_sc, ...
      'forward', config.projective_tolerance);
    one.qz_reverse = LOCAL_qz_diagnostic(B_sc, A_sc, ...
      'reverse', config.projective_tolerance);

    [V_forward, Lambda_forward] = eig(A_sc, B_sc);
    [V_reverse, Lambda_reverse] = eig(B_sc, A_sc);
    lambda_all = diag(Lambda_forward);
    mu_all = diag(Lambda_reverse);
    forward_small = isfinite(lambda_all) & ...
      abs(lambda_all) < 1 - config.unit_tolerance;
    reverse_small = isfinite(mu_all) & ...
      abs(mu_all) < 1 - config.unit_tolerance;
    one.forward_raw_count = length(lambda_all);
    one.reverse_raw_count = length(mu_all);
    one.forward_nonfinite_count = sum(~isfinite(lambda_all));
    one.reverse_nonfinite_count = sum(~isfinite(mu_all));
    one.forward_small_count = sum(forward_small);
    one.reverse_small_count = sum(reverse_small);

    if one.forward_small_count ~= K || one.reverse_small_count ~= K
      one.status = 'SMALL_MULTIPLIER_COUNT_GATE_FAILED';
      return;
    end

    lambda = lambda_all(forward_small);
    mu = mu_all(reverse_small);
    V = V_forward(:, forward_small);
    W = V_reverse(:, reverse_small);
    one.forward = LOCAL_mode_diagnostic(A_sc, B_sc, lambda, V, ...
      config.projective_tolerance);
    one.reverse = LOCAL_mode_diagnostic(B_sc, A_sc, mu, W, ...
      config.projective_tolerance);
    one.forward.residual_pass = one.forward.maximum_residual <= ...
      config.mode_residual_tolerance;
    one.reverse.residual_pass = one.reverse.maximum_residual <= ...
      config.mode_residual_tolerance;
    one.selected_pair_valid = one.forward.selected_valid && ...
      one.reverse.selected_valid;

    one.pairing = LOCAL_pair_modes(lambda, mu);
    one.pairing.pass = one.pairing.maximum_defect <= ...
      config.pairing_tolerance;

    Gamma = diag(channels.gamma_m(:));
    a_L = V(1:K, :);
    b_L = V(K + 1:2 * K, :);
    D_plus_raw = a_L + b_L;
    N_plus_raw = 1i * Gamma * (a_L - b_L);
    a_R = W(1:K, :);
    b_R = W(K + 1:2 * K, :);
    D_minus_raw = a_R + b_R;
    N_minus_raw = -1i * Gamma * (a_R - b_R);

    k_scale = max(1, abs(config.k));
    one.trace_plus = LOCAL_normalize_traces(D_plus_raw, N_plus_raw, ...
      k_scale, config);
    one.trace_minus = LOCAL_normalize_traces(D_minus_raw, N_minus_raw, ...
      k_scale, config);
    one.trace_gate_pass = one.trace_plus.valid && ...
      one.trace_minus.valid && one.trace_plus.rank_pass && ...
      one.trace_minus.rank_pass && one.trace_plus.condition_pass && ...
      one.trace_minus.condition_pass;

    one.legacy = LOCAL_legacy_span(config, S_cell, channels, ...
      one.trace_plus, one.trace_minus, M);
    A_def = LOCAL_empty_defect_matrix(channels, config.period_x, ...
      one.trace_minus.D, one.trace_minus.N, ...
      one.trace_plus.D, one.trace_plus.N);
    one.A_def = LOCAL_matrix_diagnostic(A_def, ...
      config.trace_rank_relative_tolerance);
    one.scaling = LOCAL_scaling_diagnostic(config, channels, ...
      D_minus_raw, N_minus_raw, D_plus_raw, N_plus_raw, one.A_def, ...
      one.trace_minus, one.trace_plus);
    one.scaling_pass = all([one.scaling.pass]);

    one.pass = one.selected_pair_valid && ...
      one.forward.residual_pass && one.reverse.residual_pass && ...
      one.pairing.pass && one.trace_gate_pass && one.legacy.pass && ...
      one.A_def.finite && one.scaling_pass;
    if one.pass
      one.status = 'ALL_PORT_BASIS_GATES_PASSED';
    else
      one.status = 'PORT_BASIS_GATE_FAILED';
    end
  catch ME
    if strcmp(ME.identifier, ...
        'run_bie_bidirectional_pencil_diagnostic:RuntimeCap')
      rethrow(ME);
    end
    one.status = 'EVALUATION_FAILED';
    one.error_id = ME.identifier;
    one.error_message = strrep(ME.message, sprintf('\n'), ' ');
  end
  LOCAL_check_deadline(runtime, sprintf('M=%d evaluation', M));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function qz_info = LOCAL_qz_diagnostic(A, B, direction, tolerance)
  [S_qz, T_qz] = qz(A, B, 'complex');
  alpha = diag(S_qz);
  beta_qz = diag(T_qz);
  pair_scale = abs(alpha) + abs(beta_qz);
  global_scale = tolerance * max([1, norm(A, 'fro'), norm(B, 'fro')]);
  indeterminate = pair_scale <= global_scale;
  relative_scale = max(abs(alpha), abs(beta_qz));
  infinite = ~indeterminate & abs(beta_qz) <= ...
    tolerance .* relative_scale;
  zero = ~indeterminate & ~infinite & abs(alpha) <= ...
    tolerance .* relative_scale;
  finite_nonzero = ~indeterminate & ~infinite & ~zero;
  classification = repmat({''}, length(alpha), 1);
  classification(indeterminate) = {'indeterminate'};
  classification(infinite) = {'infinite'};
  classification(zero) = {'zero'};
  classification(finite_nonzero) = {'finite-nonzero'};
  affine = NaN(size(alpha));
  affine(~indeterminate & ~infinite) = ...
    alpha(~indeterminate & ~infinite) ./ ...
    beta_qz(~indeterminate & ~infinite);

  qz_info.direction = direction;
  qz_info.alpha = alpha;
  qz_info.beta = beta_qz;
  qz_info.affine = affine;
  qz_info.classification = classification;
  qz_info.zero_count = sum(zero);
  qz_info.infinite_count = sum(infinite);
  qz_info.finite_nonzero_count = sum(finite_nonzero);
  qz_info.indeterminate_count = sum(indeterminate);
end

%% ==================== Mode residuals and pairing ====================
% These helpers reject invalid selected eigenpairs and solve a bijective match.

function info = LOCAL_mode_diagnostic(A, B, multiplier, vectors, tolerance)
  count = length(multiplier);
  residual = NaN(count, 1);
  indeterminate = true(count, 1);
  matrix_scale = norm(A, 2) + norm(B, 2);
  for j = 1:count
    vector = vectors(:, j);
    Av = A * vector;
    Bv = B * vector;
    numerator = norm(Av - multiplier(j) * Bv);
    equation_scale = norm(Av) + abs(multiplier(j)) * norm(Bv);
    residual(j) = numerator / max(equation_scale, eps * ...
      max(1, matrix_scale * norm(vector)));
    projective_scale = norm(Av) + norm(Bv);
    indeterminate(j) = projective_scale <= tolerance * ...
      max(1, matrix_scale * norm(vector));
  end
  info.multiplier = multiplier;
  info.vectors = vectors;
  info.residual = residual;
  info.indeterminate = indeterminate;
  info.nonfinite_count = sum(~isfinite(multiplier)) + ...
    sum(~isfinite(vectors(:))) + sum(~isfinite(residual));
  info.indeterminate_count = sum(indeterminate);
  info.zero_multiplier_count = sum(multiplier == 0);
  info.selected_valid = info.nonfinite_count == 0 && ...
    info.indeterminate_count == 0 && info.zero_multiplier_count == 0;
  if isempty(residual)
    info.maximum_residual = Inf;
  else
    info.maximum_residual = max(residual);
  end
  info.residual_pass = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pairing = LOCAL_pair_modes(lambda, mu)
  K = length(lambda);
  costs = zeros(K);
  for j = 1:K
    denominator = max([1e-14 * ones(1, K); ...
      abs(lambda(j)) * ones(1, K); abs(mu(:).')], [], 1);
    costs(j, :) = abs(mu(:).' - conj(lambda(j))) ./ denominator;
  end
  assignment = LOCAL_hungarian(costs);
  defect = NaN(K, 1);
  for j = 1:K
    defect(j) = costs(j, assignment(j));
  end
  pairing.assignment = assignment;
  pairing.defect = defect;
  pairing.total_defect = sum(defect);
  pairing.maximum_defect = max(defect);
  pairing.pass = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function assignment = LOCAL_hungarian(costs)
  n = size(costs, 1);
  if size(costs, 2) ~= n || any(~isfinite(costs(:)))
    error('run_bie_bidirectional_pencil_diagnostic:InvalidPairingCost', ...
      'Pairing costs must form a finite square matrix.');
  end
  u = zeros(n, 1);
  v = zeros(n + 1, 1);
  p = zeros(n + 1, 1);
  way = zeros(n + 1, 1);
  for i = 1:n
    p(1) = i;
    j0 = 1;
    minv = Inf(n + 1, 1);
    used = false(n + 1, 1);
    while true
      used(j0) = true;
      i0 = p(j0);
      delta = Inf;
      j1 = 0;
      for j = 2:n + 1
        if ~used(j)
          current = costs(i0, j - 1) - u(i0) - v(j);
          if current < minv(j)
            minv(j) = current;
            way(j) = j0;
          end
          if minv(j) < delta
            delta = minv(j);
            j1 = j;
          end
        end
      end
      for j = 1:n + 1
        if used(j)
          u(p(j)) = u(p(j)) + delta;
          v(j) = v(j) - delta;
        else
          minv(j) = minv(j) - delta;
        end
      end
      j0 = j1;
      if p(j0) == 0
        break;
      end
    end
    while true
      j1 = way(j0);
      p(j0) = p(j1);
      j0 = j1;
      if j0 == 1
        break;
      end
    end
  end
  assignment = zeros(n, 1);
  for j = 2:n + 1
    assignment(p(j)) = j - 1;
  end
end

%% ==================== Trace normalization and legacy comparison ====================
% These helpers use the frozen port signs and a balanced local trace norm.

function trace = LOCAL_normalize_traces(D, N, k_scale, config)
  K = size(D, 2);
  trace = LOCAL_empty_trace();
  trace.raw_norm = NaN(K, 1);
  trace.pivot_index = NaN(K, 1);
  trace.D = complex(NaN(size(D)));
  trace.N = complex(NaN(size(N)));
  if ~isequal(size(D), size(N)) || any(~isfinite(D(:))) || ...
      any(~isfinite(N(:)))
    return;
  end
  valid_columns = true(K, 1);
  for j = 1:K
    combined = [D(:, j); N(:, j) / k_scale];
    trace.raw_norm(j) = norm(combined);
    if ~(isfinite(trace.raw_norm(j)) && ...
        trace.raw_norm(j) >= config.trace_minimum_norm)
      valid_columns(j) = false;
      continue;
    end
    D_column = D(:, j) / trace.raw_norm(j);
    N_column = N(:, j) / trace.raw_norm(j);
    normalized_combined = [D_column; N_column / k_scale];
    [~, pivot_index] = max(abs(normalized_combined));
    pivot = normalized_combined(pivot_index);
    if ~(isfinite(pivot) && abs(pivot) > 0)
      valid_columns(j) = false;
      continue;
    end
    phase = pivot / abs(pivot);
    trace.D(:, j) = D_column * conj(phase);
    trace.N(:, j) = N_column * conj(phase);
    trace.pivot_index(j) = pivot_index;
  end
  trace.valid_columns = valid_columns;
  trace.valid = all(valid_columns);
  if ~trace.valid
    return;
  end
  trace.T = [trace.D; trace.N / k_scale];
  singular_values = svd(trace.T);
  trace.singular_values = singular_values;
  trace.rank_tolerance = config.trace_rank_relative_tolerance * ...
    singular_values(1);
  trace.numerical_rank = sum(singular_values > trace.rank_tolerance);
  trace.rank_pass = trace.numerical_rank == K;
  if trace.rank_pass && singular_values(end) > 0
    trace.condition_number = singular_values(1) / singular_values(end);
  else
    trace.condition_number = Inf;
  end
  trace.condition_pass = isfinite(trace.condition_number) && ...
    trace.condition_number <= config.trace_condition_limit;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function legacy = LOCAL_legacy_span(config, S_cell, channels, ...
    trace_plus, trace_minus, M)
  legacy = LOCAL_empty_legacy();
  if M ~= 5
    legacy.status = 'NOT_APPLICABLE_FOR_M10';
    legacy.applicable = false;
    legacy.pass = true;
    return;
  end
  legacy.applicable = true;
  try
    mode_opts.lambda_tol = config.unit_tolerance;
    mode_opts.normalize = 'V';
    modes = bloch.solve_modes(S_cell, mode_opts);
    traces = bloch.mode_traces(modes.lambda, modes.V, channels);
    select_opts.lambda_tol = config.unit_tolerance;
    [D_plus, N_plus, selected_plus] = ...
      bloch.select_port_traces(modes, traces, '+', select_opts);
    [D_minus, N_minus, selected_minus] = ...
      bloch.select_port_traces(modes, traces, '-', select_opts);
    legacy.mode_count = length(modes.lambda);
    legacy.plus_count = selected_plus.numSelected;
    legacy.minus_count = selected_minus.numSelected;
    legacy.complete = legacy.mode_count == 2 * channels.K && ...
      legacy.plus_count == channels.K && ...
      legacy.minus_count == channels.K;
    if ~legacy.complete
      legacy.status = 'LEGACY_M5_INCOMPLETE';
      return;
    end
    k_scale = max(1, abs(config.k));
    legacy_plus = LOCAL_normalize_traces(D_plus, N_plus, ...
      k_scale, config);
    legacy_minus = LOCAL_normalize_traces(D_minus, N_minus, ...
      k_scale, config);
    if ~(legacy_plus.valid && legacy_minus.valid && ...
        legacy_plus.rank_pass && legacy_minus.rank_pass)
      legacy.status = 'LEGACY_M5_TRACE_BASIS_INVALID';
      return;
    end
    legacy.plus_projector_difference = ...
      LOCAL_projector_difference(trace_plus.T, legacy_plus.T, ...
      config.trace_rank_relative_tolerance);
    legacy.minus_projector_difference = ...
      LOCAL_projector_difference(trace_minus.T, legacy_minus.T, ...
      config.trace_rank_relative_tolerance);
    legacy.maximum_projector_difference = max( ...
      legacy.plus_projector_difference, ...
      legacy.minus_projector_difference);
    legacy.pass = isfinite(legacy.maximum_projector_difference) && ...
      legacy.maximum_projector_difference <= ...
      config.legacy_projector_tolerance;
    if legacy.pass
      legacy.status = 'LEGACY_M5_SPANS_AGREE';
    else
      legacy.status = 'LEGACY_M5_SPAN_GATE_FAILED';
    end
  catch ME
    legacy.status = 'LEGACY_M5_EVALUATION_FAILED';
    legacy.error_id = ME.identifier;
    legacy.error_message = strrep(ME.message, sprintf('\n'), ' ');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function difference = LOCAL_projector_difference(T1, T2, tolerance)
  Q1 = LOCAL_span_basis(T1, tolerance);
  Q2 = LOCAL_span_basis(T2, tolerance);
  if size(Q1, 2) ~= size(T1, 2) || size(Q2, 2) ~= size(T2, 2)
    difference = Inf;
    return;
  end
  difference = norm(Q1 * Q1' - Q2 * Q2', 2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Q = LOCAL_span_basis(T, tolerance)
  [U, S, ~] = svd(T, 'econ');
  singular_values = diag(S);
  if isempty(singular_values)
    Q = zeros(size(T, 1), 0);
    return;
  end
  retained = singular_values > tolerance * singular_values(1);
  Q = U(:, retained);
end

%% ==================== A_def scaling invariance ====================
% These helpers re-normalize three fixed complex rescalings of each port basis.

function scaling = LOCAL_scaling_diagnostic(config, channels, ...
    D_minus, N_minus, D_plus, N_plus, baseline, ...
    baseline_minus, baseline_plus)
  scaling = repmat(LOCAL_empty_scaling(), config.num_scaling_tests, 1);
  K = channels.K;
  k_scale = max(1, abs(config.k));
  for j = 1:config.num_scaling_tests
    [scale_minus, scale_plus] = LOCAL_fixed_scaling(K, j);
    entry = LOCAL_empty_scaling();
    entry.index = j;
    entry.minimum_amplitude = min(abs([scale_minus; scale_plus]));
    entry.maximum_amplitude = max(abs([scale_minus; scale_plus]));
    scaled_minus = LOCAL_normalize_traces( ...
      bsxfun(@times, D_minus, scale_minus.'), ...
      bsxfun(@times, N_minus, scale_minus.'), k_scale, config);
    scaled_plus = LOCAL_normalize_traces( ...
      bsxfun(@times, D_plus, scale_plus.'), ...
      bsxfun(@times, N_plus, scale_plus.'), k_scale, config);
    if ~(scaled_minus.valid && scaled_plus.valid)
      entry.status = 'TRACE_RENORMALIZATION_FAILED';
      scaling(j) = entry;
      continue;
    end
    entry.scaled_minus_trace_rank = scaled_minus.numerical_rank;
    entry.scaled_plus_trace_rank = scaled_plus.numerical_rank;
    entry.scaled_minus_trace_rank_pass = scaled_minus.rank_pass;
    entry.scaled_plus_trace_rank_pass = scaled_plus.rank_pass;
    entry.minus_trace_rank_unchanged = ...
      scaled_minus.numerical_rank == baseline_minus.numerical_rank;
    entry.plus_trace_rank_unchanged = ...
      scaled_plus.numerical_rank == baseline_plus.numerical_rank;
    entry.trace_rank_gate_pass = ...
      entry.scaled_minus_trace_rank_pass && ...
      entry.scaled_plus_trace_rank_pass && ...
      entry.minus_trace_rank_unchanged && ...
      entry.plus_trace_rank_unchanged;
    A_scaled = LOCAL_empty_defect_matrix(channels, config.period_x, ...
      scaled_minus.D, scaled_minus.N, scaled_plus.D, scaled_plus.N);
    diagnostic = LOCAL_matrix_diagnostic(A_scaled, ...
      config.trace_rank_relative_tolerance);
    entry.matrix_size_unchanged = ...
      isequal(diagnostic.matrix_size, baseline.matrix_size);
    entry.finite_unchanged = diagnostic.finite == baseline.finite;
    entry.rank_unchanged = ...
      diagnostic.numerical_rank == baseline.numerical_rank;
    entry.normalized_sigma = diagnostic.normalized_sigma;
    entry.sigma_difference = abs(diagnostic.normalized_sigma - ...
      baseline.normalized_sigma);
    entry.sigma_tolerance = ...
      config.scaling_sigma_absolute_tolerance + ...
      config.scaling_sigma_relative_tolerance * ...
      baseline.normalized_sigma;
    entry.sigma_pass = isfinite(entry.sigma_difference) && ...
      entry.sigma_difference <= entry.sigma_tolerance;
    entry.pass = entry.matrix_size_unchanged && ...
      entry.finite_unchanged && entry.rank_unchanged && ...
      entry.trace_rank_gate_pass && entry.sigma_pass;
    if entry.pass
      entry.status = 'SCALING_INVARIANCE_PASSED';
    else
      entry.status = 'SCALING_INVARIANCE_FAILED';
    end
    scaling(j) = entry;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scale_minus, scale_plus] = LOCAL_fixed_scaling(K, index)
  exponents = linspace(-4, 4, K).';
  base_phase = 2 * pi * (0:K - 1).' / K;
  switch index
    case 1
      exponent_minus = exponents;
      exponent_plus = flipud(exponents);
      phase_minus = base_phase;
      phase_plus = -base_phase + pi / 7;
    case 2
      shift = floor(K / 3);
      exponent_minus = circshift(exponents, shift);
      exponent_plus = circshift(flipud(exponents), -shift);
      phase_minus = 3 * base_phase + pi / 5;
      phase_plus = 5 * base_phase - pi / 11;
    case 3
      order = mod(2 * (0:K - 1).', K) + 1;
      exponent_minus = exponents(order);
      exponent_plus = flipud(exponents(order));
      phase_minus = 7 * base_phase - pi / 3;
      phase_plus = 11 * base_phase + pi / 13;
    otherwise
      error('run_bie_bidirectional_pencil_diagnostic:ScalingIndex', ...
        'Only the three frozen scaling sets are defined.');
  end
  scale_minus = 10 .^ exponent_minus .* exp(1i * phase_minus);
  scale_plus = 10 .^ exponent_plus .* exp(1i * phase_plus);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function diagnostic = LOCAL_matrix_diagnostic(A, rank_relative_tolerance)
  diagnostic.matrix_size = size(A);
  diagnostic.finite = all(isfinite(A(:)));
  diagnostic.singular_values = [];
  diagnostic.rank_tolerance = NaN;
  diagnostic.numerical_rank = NaN;
  diagnostic.normalized_sigma = NaN;
  if ~diagnostic.finite || isempty(A)
    return;
  end
  singular_values = svd(A);
  diagnostic.singular_values = singular_values;
  diagnostic.rank_tolerance = rank_relative_tolerance * singular_values(1);
  diagnostic.numerical_rank = ...
    sum(singular_values > diagnostic.rank_tolerance);
  diagnostic.normalized_sigma = singular_values(end) / ...
    max(singular_values(1), eps);
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

%% ==================== Deterministic evidence outputs ====================
% These helpers write compact CSV evidence and a human-readable report.

function LOCAL_write_case_summary(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'case-summary.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,k,beta,s,M,K,label,status,pass,', ...
    'forward_raw,reverse_raw,forward_small,reverse_small,', ...
    'forward_nonfinite,reverse_nonfinite,selected_pair_valid,', ...
    'forward_max_residual,reverse_max_residual,pair_max_defect,', ...
    'trace_plus_rank,trace_minus_rank,trace_plus_cond,trace_minus_cond,', ...
    'trace_gate_pass,legacy_status,legacy_max_projector_difference,', ...
    'A_def_rows,A_def_cols,A_def_finite,A_def_rank,A_def_normalized_sigma,', ...
    'scaling_pass,cell_solve_relative_residual,error_id,error_message\n']);
  for j = 1:length(results.cases)
    one = results.cases(j);
    LOCAL_write_csv_row(fid, {results.config.model_id, results.config.k, ...
      results.config.beta, results.config.s, one.M, one.K, one.label, ...
      one.status, one.pass, one.forward_raw_count, one.reverse_raw_count, ...
      one.forward_small_count, one.reverse_small_count, ...
      one.forward_nonfinite_count, one.reverse_nonfinite_count, ...
      one.selected_pair_valid, one.forward.maximum_residual, ...
      one.reverse.maximum_residual, one.pairing.maximum_defect, ...
      one.trace_plus.numerical_rank, one.trace_minus.numerical_rank, ...
      one.trace_plus.condition_number, one.trace_minus.condition_number, ...
      one.trace_gate_pass, one.legacy.status, ...
      one.legacy.maximum_projector_difference, ...
      LOCAL_size_value(one.A_def.matrix_size, 1), ...
      LOCAL_size_value(one.A_def.matrix_size, 2), one.A_def.finite, ...
      one.A_def.numerical_rank, one.A_def.normalized_sigma, ...
      one.scaling_pass, one.cell_solve_relative_residual, ...
      one.error_id, one.error_message});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_modes(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'selected-modes.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,M,K,direction,index,multiplier_real,', ...
    'multiplier_imag,multiplier_abs,normalized_residual,indeterminate,', ...
    'paired_index,pair_relative_defect,trace_raw_norm,trace_pivot_index\n']);
  for j = 1:length(results.cases)
    one = results.cases(j);
    if isempty(one.forward.multiplier) || isempty(one.reverse.multiplier)
      continue;
    end
    reverse_to_forward = zeros(one.K, 1);
    for imode = 1:one.K
      reverse_to_forward(one.pairing.assignment(imode)) = imode;
      lambda = one.forward.multiplier(imode);
      LOCAL_write_csv_row(fid, {results.config.model_id, one.M, one.K, ...
        'forward', imode, real(lambda), imag(lambda), abs(lambda), ...
        one.forward.residual(imode), one.forward.indeterminate(imode), ...
        one.pairing.assignment(imode), one.pairing.defect(imode), ...
        one.trace_plus.raw_norm(imode), ...
        one.trace_plus.pivot_index(imode)});
    end
    for imode = 1:one.K
      mu = one.reverse.multiplier(imode);
      forward_index = reverse_to_forward(imode);
      LOCAL_write_csv_row(fid, {results.config.model_id, one.M, one.K, ...
        'reverse', imode, real(mu), imag(mu), abs(mu), ...
        one.reverse.residual(imode), one.reverse.indeterminate(imode), ...
        forward_index, one.pairing.defect(forward_index), ...
        one.trace_minus.raw_norm(imode), ...
        one.trace_minus.pivot_index(imode)});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_qz_pairs(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'qz-pairs.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,M,K,direction,index,alpha_real,alpha_imag,', ...
    'alpha_abs,beta_real,beta_imag,beta_abs,affine_real,affine_imag,', ...
    'affine_abs,classification\n']);
  for j = 1:length(results.cases)
    one = results.cases(j);
    qz_sets = {one.qz_forward, one.qz_reverse};
    for iqz_set = 1:length(qz_sets)
      qz_info = qz_sets{iqz_set};
      for iqz = 1:length(qz_info.alpha)
        alpha = qz_info.alpha(iqz);
        beta_qz = qz_info.beta(iqz);
        affine = qz_info.affine(iqz);
        LOCAL_write_csv_row(fid, {results.config.model_id, one.M, one.K, ...
          qz_info.direction, iqz, real(alpha), imag(alpha), abs(alpha), ...
          real(beta_qz), imag(beta_qz), abs(beta_qz), real(affine), ...
          imag(affine), abs(affine), qz_info.classification{iqz}});
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_trace_singular_values(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'trace-singular-values.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,M,K,port,index,singular_value,rank_tolerance,', ...
    'retained\n']);
  for j = 1:length(results.cases)
    one = results.cases(j);
    LOCAL_write_trace_block(fid, results.config.model_id, one, ...
      'plus', one.trace_plus);
    LOCAL_write_trace_block(fid, results.config.model_id, one, ...
      'minus', one.trace_minus);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_trace_block(fid, model_id, one, port, trace)
  for j = 1:length(trace.singular_values)
    LOCAL_write_csv_row(fid, {model_id, one.M, one.K, port, j, ...
      trace.singular_values(j), trace.rank_tolerance, ...
      trace.singular_values(j) > trace.rank_tolerance});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_scaling_invariance(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'scaling-invariance.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,M,K,test_index,min_amplitude,max_amplitude,', ...
    'scaled_minus_trace_rank,scaled_plus_trace_rank,', ...
    'scaled_minus_trace_rank_pass,scaled_plus_trace_rank_pass,', ...
    'minus_trace_rank_unchanged,plus_trace_rank_unchanged,', ...
    'trace_rank_gate_pass,matrix_size_unchanged,finite_unchanged,', ...
    'rank_unchanged,', ...
    'normalized_sigma,sigma_difference,sigma_tolerance,sigma_pass,', ...
    'status,pass\n']);
  for j = 1:length(results.cases)
    one = results.cases(j);
    for iscale = 1:length(one.scaling)
      scaling = one.scaling(iscale);
      LOCAL_write_csv_row(fid, {results.config.model_id, one.M, one.K, ...
        scaling.index, scaling.minimum_amplitude, ...
        scaling.maximum_amplitude, scaling.scaled_minus_trace_rank, ...
        scaling.scaled_plus_trace_rank, ...
        scaling.scaled_minus_trace_rank_pass, ...
        scaling.scaled_plus_trace_rank_pass, ...
        scaling.minus_trace_rank_unchanged, ...
        scaling.plus_trace_rank_unchanged, ...
        scaling.trace_rank_gate_pass, scaling.matrix_size_unchanged, ...
        scaling.finite_unchanged, scaling.rank_unchanged, ...
        scaling.normalized_sigma, scaling.sigma_difference, ...
        scaling.sigma_tolerance, scaling.sigma_pass, scaling.status, ...
        scaling.pass});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'report.md'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# Bidirectional sharp-disk BIE pencil diagnostic\n\n');
  fprintf(fid, ['The reverse basis is computed directly from ', ...
    '`B*w = mu*A*w`; no reciprocal multiplier is formed.\n\n']);
  fprintf(fid, '- k=%.17g, beta=%.17g, s=%.17g, ntot=%d\n', ...
    results.config.k, results.config.beta, results.config.s, ...
    results.config.ntot);
  fprintf(fid, '- Small-multiplier tolerance: %.3e\n', ...
    results.config.unit_tolerance);
  fprintf(fid, '- Per-mode residual tolerance: %.3e\n', ...
    results.config.mode_residual_tolerance);
  fprintf(fid, '- Pairing tolerance: %.3e\n', ...
    results.config.pairing_tolerance);
  fprintf(fid, '- Root claim: `%d`\n', results.root_claim);
  fprintf(fid, '- Eigenvalue claim: `%d`\n', results.eigenvalue_claim);
  fprintf(fid, '- Seed promotion: `%d`\n\n', results.seed_promotion);
  for j = 1:length(results.cases)
    one = results.cases(j);
    fprintf(fid, '- M=%d label: `%s`\n', one.M, one.label);
    fprintf(fid, '  - Status: `%s`\n', one.status);
    fprintf(fid, '  - Forward/reverse small counts: %d/%d (required %d/%d)\n', ...
      one.forward_small_count, one.reverse_small_count, one.K, one.K);
    fprintf(fid, '  - Maximum forward/reverse residual: %.6e / %.6e\n', ...
      one.forward.maximum_residual, one.reverse.maximum_residual);
    fprintf(fid, '  - Maximum conjugate-pair relative defect: %.6e\n', ...
      one.pairing.maximum_defect);
    fprintf(fid, '  - Plus/minus trace rank: %g/%g; condition: %.6e/%.6e\n', ...
      one.trace_plus.numerical_rank, one.trace_minus.numerical_rank, ...
      one.trace_plus.condition_number, one.trace_minus.condition_number);
    fprintf(fid, '  - Legacy span: `%s`, maximum projector difference %.6e\n', ...
      one.legacy.status, one.legacy.maximum_projector_difference);
    fprintf(fid, '  - A_def normalized sigma: %.6e; scaling pass: %d\n', ...
      one.A_def.normalized_sigma, one.scaling_pass);
  end
end

%% ==================== Runtime, schema, and CSV helpers ====================
% These helpers enforce the cap and keep partial failure outputs well formed.

function LOCAL_check_deadline(runtime, label)
  elapsed = toc(runtime.start_token);
  if elapsed >= runtime.max_seconds
    error('run_bie_bidirectional_pencil_diagnostic:RuntimeCap', ...
      'Runtime cap reached after %.1f seconds before %s.', elapsed, label);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function one = LOCAL_empty_case()
  one = struct('M', NaN, 'K', NaN, 'label', '', 'status', 'not-run', ...
    'pass', false, 'forward_raw_count', NaN, 'reverse_raw_count', NaN, ...
    'forward_nonfinite_count', NaN, 'reverse_nonfinite_count', NaN, ...
    'forward_small_count', NaN, 'reverse_small_count', NaN, ...
    'selected_pair_valid', false, 'forward', LOCAL_empty_modes(), ...
    'reverse', LOCAL_empty_modes(), 'pairing', LOCAL_empty_pairing(), ...
    'trace_plus', LOCAL_empty_trace(), 'trace_minus', LOCAL_empty_trace(), ...
    'trace_gate_pass', false, 'legacy', LOCAL_empty_legacy(), ...
    'A_def', LOCAL_empty_matrix(), ...
    'scaling', repmat(LOCAL_empty_scaling(), 0, 1), ...
    'scaling_pass', false, 'qz_forward', LOCAL_empty_qz('forward'), ...
    'qz_reverse', LOCAL_empty_qz('reverse'), ...
    'cell_solve_relative_residual', NaN, 'error_id', '', ...
    'error_message', '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function info = LOCAL_empty_modes()
  info = struct('multiplier', [], 'vectors', [], 'residual', [], ...
    'indeterminate', [], 'nonfinite_count', NaN, ...
    'indeterminate_count', NaN, 'zero_multiplier_count', NaN, ...
    'selected_valid', false, ...
    'maximum_residual', NaN, 'residual_pass', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pairing = LOCAL_empty_pairing()
  pairing = struct('assignment', [], 'defect', [], ...
    'total_defect', NaN, 'maximum_defect', NaN, 'pass', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function trace = LOCAL_empty_trace()
  trace = struct('raw_norm', [], 'pivot_index', [], 'D', [], 'N', [], ...
    'T', [], 'valid_columns', [], 'valid', false, ...
    'singular_values', [], 'rank_tolerance', NaN, ...
    'numerical_rank', NaN, 'rank_pass', false, ...
    'condition_number', NaN, 'condition_pass', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function legacy = LOCAL_empty_legacy()
  legacy = struct('applicable', false, 'status', 'not-run', ...
    'mode_count', NaN, 'plus_count', NaN, 'minus_count', NaN, ...
    'complete', false, 'plus_projector_difference', NaN, ...
    'minus_projector_difference', NaN, ...
    'maximum_projector_difference', NaN, 'pass', false, ...
    'error_id', '', 'error_message', '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function qz_info = LOCAL_empty_qz(direction)
  qz_info = struct('direction', direction, 'alpha', [], 'beta', [], ...
    'affine', [], 'classification', {{}}, 'zero_count', NaN, ...
    'infinite_count', NaN, 'finite_nonzero_count', NaN, ...
    'indeterminate_count', NaN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function diagnostic = LOCAL_empty_matrix()
  diagnostic = struct('matrix_size', [], 'finite', false, ...
    'singular_values', [], 'rank_tolerance', NaN, ...
    'numerical_rank', NaN, 'normalized_sigma', NaN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function scaling = LOCAL_empty_scaling()
  scaling = struct('index', NaN, 'minimum_amplitude', NaN, ...
    'maximum_amplitude', NaN, 'scaled_minus_trace_rank', NaN, ...
    'scaled_plus_trace_rank', NaN, ...
    'scaled_minus_trace_rank_pass', false, ...
    'scaled_plus_trace_rank_pass', false, ...
    'minus_trace_rank_unchanged', false, ...
    'plus_trace_rank_unchanged', false, ...
    'trace_rank_gate_pass', false, 'matrix_size_unchanged', false, ...
    'finite_unchanged', false, 'rank_unchanged', false, ...
    'normalized_sigma', NaN, 'sigma_difference', NaN, ...
    'sigma_tolerance', NaN, 'sigma_pass', false, ...
    'status', 'not-run', 'pass', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_size_value(matrix_size, index)
  if length(matrix_size) < index
    value = NaN;
  else
    value = matrix_size(index);
  end
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
      error('run_bie_bidirectional_pencil_diagnostic:CsvValue', ...
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
    error('run_bie_bidirectional_pencil_diagnostic:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end
