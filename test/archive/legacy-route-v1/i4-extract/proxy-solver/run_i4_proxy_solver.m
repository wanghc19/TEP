function results = run_i4_proxy_solver()
%RUN_I4_PROXY_SOLVER Diagnose canonical proxy least-squares solver cutoffs.
%
% Purpose:
%   Rebuild the package precomp_proxy matrix A and right-hand side b in this
%   test directory, compare package/default-pinv/backslash/manual-SVD
%   solutions, and evaluate only three inexpensive point Green values.
%
% Output:
%   results - Configuration, references, singular spectra, solver ledgers,
%             decision diagnostics, timings, and artifact paths.
%
% Main algorithm:
%   1. Certify point references by Rayleigh M=48/96 and two Ewald levels.
%   2. Rebuild the high (720-by-354) and higher (960-by-450) systems exactly.
%   3. Compute one thin SVD per level and sweep relative cutoffs retaining
%      s_j > tau*s_1.
%   4. Apply residual, norm, point-reference, adjacent-tau, and cross-level
%      gates before choosing the largest admissible tau.
%
% Based on:
%   +kernel/precomp_proxy.m and test/i4-extract/run_i4_extract_oracles.m.
%
% Main changes:
%   The constructor is mirrored locally only to expose A,b.  No dense wall
%   pair matrix, derivative, BIE, density, or package modification is used.
%
% Numerical goal:
%   Decide whether the point-value floor is caused by the default pseudoinverse
%   cutoff or remains limited by the proxy basis/collocation construction.

  config = i4_proxy_solver_config();
  addpath(config.repo_root);
  addpath(fullfile(config.repo_root, 'benchmark', 'qpgreen'));
  if ~exist(config.output_dir, 'dir')
    mkdir(config.output_dir);
  end

  log_path = fullfile(config.output_dir, 'run.log');
  log_fid = fopen(log_path, 'w');
  if log_fid < 0
    error('run_i4_proxy_solver:LogOpenFailed', 'Could not open %s.', log_path);
  end
  log_cleanup = onCleanup(@() fclose(log_fid));
  is_octave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
  ewald_backend = 'repository Faddeeva_erfc';
  if is_octave && isempty(which('Faddeeva_erfc'))
    addpath(fullfile(config.extract_root, 'octave_compat'));
    ewald_backend = 'Octave complex erfc compatibility shim';
  end

  LOCAL_log(log_fid, 'i4 cheap proxy-solver diagnostic\n');
  LOCAL_log(log_fid, 'Estimated runtime: <%.0f seconds\n', ...
    config.expected_runtime_seconds);
  LOCAL_log(log_fid, 'Hard runtime limit: %.0f seconds\n', ...
    config.hard_runtime_seconds);
  LOCAL_log(log_fid, 'No pairmat, wall grid, BIE, gradient, or Hessian call.\n');
  LOCAL_log(log_fid, 'Ewald erfc backend: %s\n', ewald_backend);

  total_token = tic;
  timings = cell(0, 2);
  pars1 = struct('d', config.d, 'beta', config.beta, 'k', config.k, ...
    'periodic_axis', 'y');

  % --- stage 1: certify independent point references ---
  token = tic;
  refs = LOCAL_point_references(config, pars1);
  timings(end + 1, :) = {'point_references', toc(token)};
  LOCAL_log(log_fid, 'Reference eligibility max change: %.6e (tol %.1e)\n', ...
    refs.eligibility_max, config.gate.reference_eligibility);
  LOCAL_check_deadline(total_token, config, 'point references');

  % --- stage 2: rebuild, decompose, and solve both proxy systems ---
  level_data = cell(1, length(config.levels));
  package_backend = LOCAL_package_backend();
  for il = 1:length(config.levels)
    level = config.levels(il);
    LOCAL_log(log_fid, 'Level %s: rebuilding A,b and computing thin SVD ...\n', ...
      level.label);
    token = tic;
    [A, b, meta] = LOCAL_build_proxy_system(config, level);
    if ~isequal(size(A), [level.expected_m, level.expected_n])
      error('run_i4_proxy_solver:UnexpectedSystemSize', ...
        '%s A has size %d-by-%d, expected %d-by-%d.', level.label, ...
        size(A, 1), size(A, 2), level.expected_m, level.expected_n);
    end
    [U, S, V] = svd(A, 'econ');
    s = diag(S);
    matrix_norm = norm(A);
    tol_abs = max(size(A)) * matrix_norm * eps;
    tol_rel = tol_abs / s(1);
    rank_default = sum(s > tol_abs);
    tau_abs = config.selected_tau * matrix_norm;
    rank_tau = sum(s > tau_abs);

    pars2 = LOCAL_level_pars(config, level);
    package_proxy = kernel.precomp_proxy(pars1, pars2);
    package_c = LOCAL_proxy_coefficients(package_proxy);
    package_field = LOCAL_point_fields(config, pars1, package_proxy);
    package_proxy_repeat = kernel.precomp_proxy(pars1, pars2);
    package_c_repeat = LOCAL_proxy_coefficients(package_proxy_repeat);
    package_field_repeat = LOCAL_point_fields( ...
      config, pars1, package_proxy_repeat);
    package_coefficient_repeat = norm(package_c_repeat - package_c) / ...
      max(1, norm(package_c));
    package_field_repeat_change = LOCAL_field_change( ...
      package_field_repeat, package_field);

    pinv_c = pinv(A) * b;
    pinv_proxy = LOCAL_proxy_from_coefficients(pinv_c, meta);
    pinv_field = LOCAL_point_fields(config, pars1, pinv_proxy);
    pinv_c_repeat = pinv(A) * b;
    pinv_proxy_repeat = LOCAL_proxy_from_coefficients(pinv_c_repeat, meta);
    pinv_field_repeat = LOCAL_point_fields(config, pars1, pinv_proxy_repeat);
    pinv_coefficient_repeat = norm(pinv_c_repeat - pinv_c) / ...
      max(1, norm(pinv_c));
    pinv_field_repeat_change = LOCAL_field_change( ...
      pinv_field_repeat, pinv_field);
    pinv_explicit_c = pinv(A, tol_abs) * b;
    pinv_explicit_proxy = LOCAL_proxy_from_coefficients(pinv_explicit_c, meta);
    pinv_explicit_field = LOCAL_point_fields( ...
      config, pars1, pinv_explicit_proxy);
    default_explicit_coefficient_diff = norm(pinv_c - pinv_explicit_c) / ...
      max(1, norm(pinv_explicit_c));
    default_explicit_field_diff = LOCAL_field_change( ...
      pinv_field, pinv_explicit_field);
    pinv_tau_c = pinv(A, tau_abs) * b;
    pinv_tau_proxy = LOCAL_proxy_from_coefficients(pinv_tau_c, meta);
    pinv_tau_field = LOCAL_point_fields(config, pars1, pinv_tau_proxy);
    coefficient_diff = norm(pinv_c - package_c) / max(1, norm(package_c));
    field_diff = LOCAL_field_change(pinv_field, package_field);

    evaluations = LOCAL_solver_evaluations(config, A, b, meta, U, s, V, ...
      refs, package_c, package_field, package_backend, tol_abs, tol_rel, ...
      rank_default);
    level_data{il} = struct('level', level, 'A', A, 'b', b, 'meta', meta, ...
      's', s, 'tol_abs', tol_abs, 'tol_rel', tol_rel, ...
      'matrix_norm', matrix_norm, 'tau_abs', tau_abs, 'rank_tau', rank_tau, ...
      'rank_default', rank_default, 'coefficient_diff', coefficient_diff, ...
      'field_diff', field_diff, ...
      'package_coefficient_repeat', package_coefficient_repeat, ...
      'package_field_repeat', package_field_repeat_change, ...
      'pinv_coefficient_repeat', pinv_coefficient_repeat, ...
      'pinv_field_repeat', pinv_field_repeat_change, ...
      'default_explicit_coefficient_diff', ...
      default_explicit_coefficient_diff, ...
      'default_explicit_field_diff', default_explicit_field_diff, ...
      'pinv_tau_field', pinv_tau_field, ...
      'evaluations', evaluations);
    timings(end + 1, :) = {['level_', level.label], toc(token)};
    LOCAL_log(log_fid, ['  A=%d-by-%d, default rank=%d, tol_rel=%.6e, ', ...
      'package coeff diff=%.3e, field diff=%.3e, repeats=%.1e/%.1e\n'], ...
      size(A, 1), size(A, 2), ...
      rank_default, tol_rel, coefficient_diff, field_diff, ...
      max(package_coefficient_repeat, pinv_coefficient_repeat), ...
      max(package_field_repeat_change, pinv_field_repeat_change));
    LOCAL_check_deadline(total_token, config, ['level ', level.label]);
  end

  % --- stage 3: apply cross-level and decision gates ---
  [level_data, decision] = LOCAL_finalize_gates(config, refs, level_data);
  singular_rows = LOCAL_singular_rows(level_data);
  solver_rows = LOCAL_solver_rows(level_data);
  point_rows = LOCAL_point_rows(config, refs, level_data);
  reproduction_rows = LOCAL_reproduction_rows(config, level_data);
  total_seconds = toc(total_token);
  timings(end + 1, :) = {'total', total_seconds};

  LOCAL_write_csv(fullfile(config.output_dir, 'singular-spectrum.csv'), ...
    {'level', 'm', 'n', 'index', 'sigma', 'sigma_over_sigma1', ...
    'tol_abs_default', 'tol_rel_default', 'rank_default'}, singular_rows);
  LOCAL_write_csv(fullfile(config.output_dir, 'solver-ledger.csv'), ...
    {'level', 'solver', 'tau', 'backend', 'rank', 'm', 'n', ...
    'tol_abs', 'tol_rel', 'relative_residual', 'rho_min', 'rho_tol', ...
    'rho_pass', 'normal_residual', 'coefficient_norm', 'norm_min', ...
    'norm_pass', 'discarded_rhs_energy', 'point_error_spectral', ...
    'point_error_ewald', 'point_error_max', 'point_pass', ...
    'adjacent_tau_change_lower', 'adjacent_tau_change_upper', ...
    'adjacent_tau_change', 'adjacent_tau_pass', 'cross_level_change', ...
    'cross_level_pass', 'finite', 'all_pass'}, solver_rows);
  LOCAL_write_csv(fullfile(config.output_dir, 'point-errors.csv'), ...
    {'level', 'solver', 'tau', 'delta', 'observed_real', 'observed_imag', ...
    'spectral_M48_real', 'spectral_M48_imag', 'spectral_M96_real', ...
    'spectral_M96_imag', 'ewald_low_real', 'ewald_low_imag', ...
    'ewald_high_real', 'ewald_high_imag', 'relative_error_spectral', ...
    'relative_error_ewald', 'cross_level_point_change'}, point_rows);
  LOCAL_write_csv(fullfile(config.output_dir, 'reproduction.csv'), ...
    {'level', 'source', 'coefficient_repeat_change', ...
    'point_field_repeat_change', 'tolerance', 'pass'}, reproduction_rows);
  LOCAL_write_csv(fullfile(config.output_dir, 'timings.csv'), ...
    {'stage', 'seconds'}, timings);

  results = struct();
  results.config = config;
  results.references = refs;
  results.package_backend = package_backend;
  results.level_data = level_data;
  results.decision = decision;
  results.singular_rows = singular_rows;
  results.solver_rows = solver_rows;
  results.point_rows = point_rows;
  results.reproduction_rows = reproduction_rows;
  results.timings = timings;
  results.total_seconds = total_seconds;
  results.output_dir = config.output_dir;
  if is_octave
    save(fullfile(config.output_dir, 'results.mat'), 'results', '-mat7-binary');
  else
    save(fullfile(config.output_dir, 'results.mat'), 'results', '-v7');
  end
  LOCAL_write_decision(fullfile(config.output_dir, 'decision.txt'), ...
    config, refs, level_data, decision, total_seconds);
  LOCAL_write_report(fullfile(config.output_dir, 'report.md'), config, refs, ...
    level_data, decision, package_backend, ewald_backend, total_seconds);

  LOCAL_log(log_fid, 'Decision: %s\n', decision.label);
  LOCAL_log(log_fid, 'Chosen manual tau: %.6e\n', decision.chosen_tau);
  LOCAL_log(log_fid, 'Default/best point-error improvement: %.6e\n', ...
    decision.improvement_factor);
  LOCAL_log(log_fid, 'Total seconds: %.6f\n', total_seconds);
  LOCAL_log(log_fid, 'Artifacts: %s\n', config.output_dir);
  clear log_cleanup;
end

%% ==================== Independent point references ====================
% These helpers certify values without using a proxy coefficient vector.

function refs = LOCAL_point_references(config, pars1)
  npoint = length(config.delta);
  refs.spectral_low = zeros(npoint, 1);
  refs.spectral_high = zeros(npoint, 1);
  refs.ewald_low = zeros(npoint, 1);
  refs.ewald_high = zeros(npoint, 1);
  pars_ewald = rmfield(pars1, 'periodic_axis');
  for ip = 1:npoint
    [src, trg] = LOCAL_physical_points(config, config.delta(ip));
    refs.spectral_low(ip) = LOCAL_spectral_value( ...
      config, src, trg, config.spectral_M(1));
    refs.spectral_high(ip) = LOCAL_spectral_value( ...
      config, src, trg, config.spectral_M(2));
    refs.ewald_low(ip) = qpgreen_ewald_xperiodic_bench( ...
      src([2 1]), trg([2 1]), pars_ewald, config.ewald_low);
    refs.ewald_high(ip) = qpgreen_ewald_xperiodic_bench( ...
      src([2 1]), trg([2 1]), pars_ewald, config.ewald_high);
  end
  refs.spectral_change = LOCAL_field_change( ...
    refs.spectral_low, refs.spectral_high);
  refs.ewald_change = LOCAL_field_change(refs.ewald_low, refs.ewald_high);
  refs.cross_method_change = LOCAL_field_change( ...
    refs.spectral_high, refs.ewald_high);
  refs.eligibility_max = max([refs.spectral_change, refs.ewald_change, ...
    refs.cross_method_change]);
  refs.eligible = refs.eligibility_max <= ...
    config.gate.reference_eligibility;
end

function value = LOCAL_spectral_value(config, src, trg, M)
  m = (-M:M).';
  beta_m = config.beta + 2 * pi * m / config.d;
  gamma_m = sqrt(config.k ^ 2 - beta_m .^ 2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);
  value = 1i / (2 * config.d) * sum( ...
    exp(1i * beta_m * (trg(2) - src(2))) .* ...
    exp(1i * gamma_m * abs(trg(1) - src(1))) ./ gamma_m);
end

function [src, trg] = LOCAL_physical_points(config, delta)
  src = [config.X_R - delta; config.source_y];
  trg = [config.X_R; config.target_y];
end

%% ==================== Mirrored proxy system ====================
% This group mirrors +kernel/precomp_proxy.m through construction of A,b.

function [A, b, meta] = LOCAL_build_proxy_system(config, level)
  d = config.d;
  beta = config.beta;
  k = config.k;
  H = config.H;
  proxy_dist = config.proxy_dist;
  N_side = level.N_side;
  N_top = level.N_top;
  N_proxy_edge = level.N_proxy_edge;
  M_pw = level.M_pw;
  src = [0, 0];

  y_side = linspace(-H, H, N_side).';
  p_L = [-d / 2 * ones(N_side, 1), y_side];
  p_R = [ d / 2 * ones(N_side, 1), y_side];
  x_top = linspace(-d / 2, d / 2, N_top).';
  p_T = [x_top,  H * ones(N_top, 1)];
  p_B = [x_top, -H * ones(N_top, 1)];

  x_min = -d / 2 - proxy_dist;
  x_max =  d / 2 + proxy_dist;
  y_min = -H - proxy_dist;
  y_max =  H + proxy_dist;
  tx = linspace(x_min, x_max, N_proxy_edge + 1).';
  tx(end) = [];
  ty = linspace(y_min, y_max, N_proxy_edge + 1).';
  ty(end) = [];
  px = [tx; repmat(x_max, N_proxy_edge, 1); flipud(tx); ...
    repmat(x_min, N_proxy_edge, 1)];
  py = [repmat(y_min, N_proxy_edge, 1); ty; ...
    repmat(y_max, N_proxy_edge, 1); flipud(ty)];
  Z_proxy = [px, py];
  N_proxy = size(Z_proxy, 1);

  m_vec = (-M_pw:M_pw).';
  beta_m = beta + m_vec * (2 * pi / d);
  gamma_m = sqrt(k ^ 2 - beta_m .^ 2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);
  N_pw_total = length(m_vec);
  N_unknowns = N_proxy + 2 * N_pw_total;
  N_eqs = 2 * N_side + 4 * N_top;
  A = zeros(N_eqs, N_unknowns);
  b = zeros(N_eqs, 1);

  idx_LR_v = 1:N_side;
  idx_LR_d = (1:N_side) + N_side;
  idx_T_v = (1:N_top) + 2 * N_side;
  idx_T_d = (1:N_top) + 2 * N_side + N_top;
  idx_B_v = (1:N_top) + 2 * N_side + 2 * N_top;
  idx_B_d = (1:N_top) + 2 * N_side + 3 * N_top;
  col_proxy = 1:N_proxy;
  col_pw_T = (1:N_pw_total) + N_proxy;
  col_pw_B = (1:N_pw_total) + N_proxy + N_pw_total;
  phase = exp(1i * beta * d);

  % Preserve the package expression tree exactly.  Algebraically equivalent
  % factoring changes A,b at roundoff and is amplified by this ill-conditioned
  % system enough to invalidate the strict coefficient-reproduction preflight.
  eval_G = @(pt, ps) deal( ...
    (1i/4) * besselh(0, 1, k * sqrt((pt(:,1)-ps(:,1).').^2 + ...
    (pt(:,2)-ps(:,2).').^2)), ...
    -(1i*k/4) * besselh(1, 1, k * sqrt((pt(:,1)-ps(:,1).').^2 + ...
    (pt(:,2)-ps(:,2).').^2)) .* ((pt(:,1)-ps(:,1).') ./ ...
    sqrt((pt(:,1)-ps(:,1).').^2 + (pt(:,2)-ps(:,2).').^2)), ...
    -(1i*k/4) * besselh(1, 1, k * sqrt((pt(:,1)-ps(:,1).').^2 + ...
    (pt(:,2)-ps(:,2).').^2)) .* ((pt(:,2)-ps(:,2).') ./ ...
    sqrt((pt(:,1)-ps(:,1).').^2 + (pt(:,2)-ps(:,2).').^2)));

  [V_sL, dVdx_sL, ~] = eval_G(p_L, src);
  [V_sR, dVdx_sR, ~] = eval_G(p_R, src);
  b(idx_LR_v) = -(V_sR - phase * V_sL);
  b(idx_LR_d) = -(dVdx_sR - phase * dVdx_sL);
  [V_sT, ~, dVdy_sT] = eval_G(p_T, src);
  b(idx_T_v) = -V_sT;
  b(idx_T_d) = -dVdy_sT;
  [V_sB, ~, dVdy_sB] = eval_G(p_B, src);
  b(idx_B_v) = -V_sB;
  b(idx_B_d) = -dVdy_sB;

  [V_pL, dVdx_pL, ~] = eval_G(p_L, Z_proxy);
  [V_pR, dVdx_pR, ~] = eval_G(p_R, Z_proxy);
  A(idx_LR_v, col_proxy) = V_pR - phase * V_pL;
  A(idx_LR_d, col_proxy) = dVdx_pR - phase * dVdx_pL;
  [V_pT, ~, dVdy_pT] = eval_G(p_T, Z_proxy);
  A(idx_T_v, col_proxy) = V_pT;
  A(idx_T_d, col_proxy) = dVdy_pT;
  [V_pB, ~, dVdy_pB] = eval_G(p_B, Z_proxy);
  A(idx_B_v, col_proxy) = V_pB;
  A(idx_B_d, col_proxy) = dVdy_pB;

  PW_T_val = exp(1i * p_T(:, 1) * beta_m.');
  A(idx_T_v, col_pw_T) = -PW_T_val;
  A(idx_T_d, col_pw_T) = -PW_T_val .* (1i * gamma_m.');
  PW_B_val = exp(1i * p_B(:, 1) * beta_m.');
  A(idx_B_v, col_pw_B) = -PW_B_val;
  A(idx_B_d, col_pw_B) = -PW_B_val .* (-1i * gamma_m.');

  meta.Z = Z_proxy.';
  meta.H = H;
  meta.N_proxy = N_proxy;
  meta.N_pw_total = N_pw_total;
end

function pars2 = LOCAL_level_pars(config, level)
  pars2 = struct('H', config.H, 'proxy_dist', config.proxy_dist, ...
    'N_side', level.N_side, 'N_top', level.N_top, ...
    'N_proxy_edge', level.N_proxy_edge, 'M_pw', level.M_pw);
end

%% ==================== Solver construction and gates ====================
% This group evaluates each coefficient vector on the shared systems.

function evaluations = LOCAL_solver_evaluations(config, A, b, meta, U, s, V, ...
    refs, package_c, package_field, package_backend, tol_abs, tol_rel, ...
    rank_default)
  evaluations = struct([]);
  evaluations(end + 1) = LOCAL_make_evaluation(config, A, b, meta, U, s, ...
    refs, 'package', NaN, package_backend, rank_default, package_c, ...
    tol_abs, tol_rel);
  c_pinv = pinv(A) * b;
  evaluations(end + 1) = LOCAL_make_evaluation(config, A, b, meta, U, s, ...
    refs, 'pinv_default', tol_rel, 'pinv(A)*b', rank_default, c_pinv, ...
    tol_abs, tol_rel);
  c_explicit_default = pinv(A, tol_abs) * b;
  evaluations(end + 1) = LOCAL_make_evaluation(config, A, b, meta, U, s, ...
    refs, 'pinv_explicit_default', tol_rel, 'pinv(A,tol_default)*b', ...
    rank_default, c_explicit_default, tol_abs, tol_rel);
  tau_abs = config.selected_tau * s(1);
  rank_tau = sum(s > tau_abs);
  c_tau = pinv(A, tau_abs) * b;
  evaluations(end + 1) = LOCAL_make_evaluation(config, A, b, meta, U, s, ...
    refs, 'pinv_tau_selected', config.selected_tau, ...
    'pinv(A,selected_tau*norm(A))*b', rank_tau, c_tau, tau_abs, ...
    config.selected_tau);
  c_backslash = A \ b;
  evaluations(end + 1) = LOCAL_make_evaluation(config, A, b, meta, U, s, ...
    refs, 'backslash', NaN, 'A\\b', length(s), c_backslash, NaN, NaN);

  for it = 1:length(config.tau)
    tau = config.tau(it);
    keep = s > tau * s(1);
    coefficients = V(:, keep) * ((U(:, keep)' * b) ./ s(keep));
    evaluations(end + 1) = LOCAL_make_evaluation(config, A, b, meta, U, s, ...
      refs, 'manual_svd', tau, 'thin SVD', sum(keep), coefficients, ...
      tau * s(1), tau);
  end

  rho_values = [evaluations.relative_residual];
  finite_values = [evaluations.finite];
  rho_min = min(rho_values(finite_values));
  rho_tol = max(config.gate.residual_factor * rho_min, ...
    config.gate.residual_floor);
  near = finite_values & rho_values <= rho_tol;
  norm_values = [evaluations.coefficient_norm];
  norm_min = min(norm_values(near));
  for ie = 1:length(evaluations)
    evaluations(ie).rho_min = rho_min;
    evaluations(ie).rho_tol = rho_tol;
    evaluations(ie).rho_pass = evaluations(ie).finite && ...
      evaluations(ie).relative_residual <= rho_tol;
    evaluations(ie).norm_min = norm_min;
    evaluations(ie).norm_pass = evaluations(ie).finite && ...
      evaluations(ie).coefficient_norm <= config.gate.norm_factor * norm_min;
    evaluations(ie).adjacent_tau_change_lower = NaN;
    evaluations(ie).adjacent_tau_change_upper = NaN;
    evaluations(ie).adjacent_tau_change = NaN;
    evaluations(ie).adjacent_tau_pass = true;
    evaluations(ie).cross_level_change = NaN;
    evaluations(ie).cross_level_point_change = NaN(size(package_field));
    evaluations(ie).cross_level_pass = false;
    evaluations(ie).all_pass = false;
  end

  manual_index = find(strcmp({evaluations.solver}, 'manual_svd'));
  for jj = 1:length(manual_index)
    ie = manual_index(jj);
    lower_change = NaN;
    upper_change = NaN;
    if jj > 1
      lower_change = LOCAL_field_change( ...
        evaluations(ie).field, evaluations(manual_index(jj - 1)).field);
    end
    if jj < length(manual_index)
      upper_change = LOCAL_field_change( ...
        evaluations(ie).field, evaluations(manual_index(jj + 1)).field);
    end
    evaluations(ie).adjacent_tau_change_lower = lower_change;
    evaluations(ie).adjacent_tau_change_upper = upper_change;
    changes = [lower_change, upper_change];
    changes = changes(isfinite(changes));
    evaluations(ie).adjacent_tau_change = max(changes);
    evaluations(ie).adjacent_tau_pass = ...
      evaluations(ie).adjacent_tau_change <= config.gate.adjacent_tau_change;
  end
end

function ev = LOCAL_make_evaluation(config, A, b, meta, U, s, refs, ...
    solver, tau, backend, rank_value, coefficients, tol_abs, tol_rel)
  action = A * coefficients;
  residual = action - b;
  norm_b = norm(b);
  norm_residual = norm(residual);
  proxy = LOCAL_proxy_from_coefficients(coefficients, meta);
  pars1 = struct('d', config.d, 'beta', config.beta, 'k', config.k, ...
    'periodic_axis', 'y');
  field = LOCAL_point_fields(config, pars1, proxy);
  finite = all(isfinite(coefficients)) && all(isfinite(field)) && ...
    isfinite(norm_residual);
  projected = U' * b;
  keep = false(length(s), 1);
  keep(1:min(rank_value, length(s))) = true;
  outside_sq = max(0, norm_b ^ 2 - norm(projected) ^ 2);
  discarded = sqrt(outside_sq + norm(projected(~keep)) ^ 2) / norm_b;
  normal_numerator = norm(A' * residual);
  normal_denominator = s(1) * norm(action) + norm(A' * b);
  if normal_denominator == 0 && normal_numerator == 0
    normal_residual = 0;
  elseif normal_denominator == 0
    normal_residual = Inf;
  else
    normal_residual = normal_numerator / normal_denominator;
  end

  ev.solver = solver;
  ev.tau = tau;
  ev.backend = backend;
  ev.rank = rank_value;
  ev.coefficients = coefficients;
  ev.field = field;
  ev.tol_abs = tol_abs;
  ev.tol_rel = tol_rel;
  ev.relative_residual = norm_residual / norm_b;
  ev.normal_residual = normal_residual;
  ev.coefficient_norm = norm(coefficients);
  ev.discarded_rhs_energy = discarded;
  ev.point_error_spectral = LOCAL_field_change(field, refs.spectral_high);
  ev.point_error_ewald = LOCAL_field_change(field, refs.ewald_high);
  ev.point_error_max = max(ev.point_error_spectral, ev.point_error_ewald);
  ev.point_pass = finite && ev.point_error_max <= config.gate.point_error;
  ev.finite = finite;
end

function [level_data, decision] = LOCAL_finalize_gates(config, refs, level_data)
  for ie = 1:length(level_data{1}.evaluations)
    high_field = level_data{1}.evaluations(ie).field;
    higher_field = level_data{2}.evaluations(ie).field;
    point_change = abs(high_field - higher_field) ./ ...
      max(ones(size(higher_field)), abs(higher_field));
    cross_change = max(point_change);
    for il = 1:2
      level_data{il}.evaluations(ie).cross_level_point_change = point_change;
      level_data{il}.evaluations(ie).cross_level_change = cross_change;
      level_data{il}.evaluations(ie).cross_level_pass = ...
        cross_change <= config.gate.cross_level_change;
      ev = level_data{il}.evaluations(ie);
      level_data{il}.evaluations(ie).all_pass = refs.eligible && ...
        ev.finite && ev.rho_pass && ev.norm_pass && ev.point_pass && ...
        ev.adjacent_tau_pass && ev.cross_level_pass;
    end
  end

  preflight_coeff = max([level_data{1}.coefficient_diff, ...
    level_data{2}.coefficient_diff]);
  preflight_field = max([level_data{1}.field_diff, level_data{2}.field_diff]);
  repeat_coefficient = max([level_data{1}.package_coefficient_repeat, ...
    level_data{1}.pinv_coefficient_repeat, ...
    level_data{2}.package_coefficient_repeat, ...
    level_data{2}.pinv_coefficient_repeat]);
  repeat_field = max([level_data{1}.package_field_repeat, ...
    level_data{1}.pinv_field_repeat, level_data{2}.package_field_repeat, ...
    level_data{2}.pinv_field_repeat]);
  same_backend_coefficient = max([ ...
    level_data{1}.default_explicit_coefficient_diff, ...
    level_data{2}.default_explicit_coefficient_diff]);
  same_backend_field = max([level_data{1}.default_explicit_field_diff, ...
    level_data{2}.default_explicit_field_diff]);
  preflight_pass = preflight_coeff <= config.gate.rebuild_reproduction && ...
    preflight_field <= config.gate.rebuild_reproduction && ...
    repeat_coefficient <= config.gate.rebuild_reproduction && ...
    repeat_field <= config.gate.rebuild_reproduction && ...
    same_backend_field <= config.gate.same_backend_default;

  package_index = LOCAL_evaluation_index(level_data{1}.evaluations, ...
    'package', NaN);
  default_index = LOCAL_evaluation_index(level_data{1}.evaluations, ...
    'pinv_default', NaN);
  explicit_index = LOCAL_evaluation_index(level_data{1}.evaluations, ...
    'pinv_explicit_default', NaN);
  tau_index = LOCAL_evaluation_index(level_data{1}.evaluations, ...
    'pinv_tau_selected', config.selected_tau);
  backslash_index = LOCAL_evaluation_index(level_data{1}.evaluations, ...
    'backslash', NaN);
  package_pass = level_data{1}.evaluations(package_index).all_pass && ...
    level_data{2}.evaluations(package_index).all_pass;
  default_pass = level_data{1}.evaluations(default_index).all_pass && ...
    level_data{2}.evaluations(default_index).all_pass;
  explicit_default_match_pass = ...
    same_backend_field <= config.gate.same_backend_default;
  tau_point_pass = level_data{1}.evaluations(tau_index).point_pass && ...
    level_data{2}.evaluations(tau_index).point_pass;
  tau_cross_pass = level_data{1}.evaluations(tau_index).cross_level_pass && ...
    level_data{2}.evaluations(tau_index).cross_level_pass;
  tau_finite = level_data{1}.evaluations(tau_index).finite && ...
    level_data{2}.evaluations(tau_index).finite;
  same_backend_pass = explicit_default_match_pass && tau_point_pass && ...
    tau_cross_pass && tau_finite;
  backslash_pass = level_data{1}.evaluations(backslash_index).all_pass && ...
    level_data{2}.evaluations(backslash_index).all_pass;

  chosen_tau = NaN;
  chosen_index = NaN;
  manual_indices = find(strcmp( ...
    {level_data{1}.evaluations.solver}, 'manual_svd'));
  for jj = 1:length(manual_indices)
    ie = manual_indices(jj);
    if level_data{1}.evaluations(ie).all_pass && ...
        level_data{2}.evaluations(ie).all_pass
      chosen_tau = level_data{1}.evaluations(ie).tau;
      chosen_index = ie;
    end
  end
  manual_pass = isfinite(chosen_tau);

  solver_error = zeros(length(level_data{1}.evaluations), 1);
  for ie = 1:length(solver_error)
    solver_error(ie) = max([ ...
      level_data{1}.evaluations(ie).point_error_max, ...
      level_data{2}.evaluations(ie).point_error_max]);
  end
  default_error = solver_error(default_index);
  best_error = min(solver_error);
  improvement = default_error / max(best_error, realmin);
  [~, best_index] = min(solver_error);
  if manual_pass
    selected_error = solver_error(chosen_index);
    selected_solver = 'manual_svd';
  elseif backslash_pass
    selected_error = solver_error(backslash_index);
    selected_solver = 'backslash';
  else
    selected_error = NaN;
    selected_solver = 'none';
  end
  if isfinite(selected_error)
    selected_improvement = default_error / max(selected_error, realmin);
  else
    selected_improvement = NaN;
  end
  only_large_norm_reduces = best_error < default_error && ...
    ~(level_data{1}.evaluations(best_index).norm_pass && ...
    level_data{2}.evaluations(best_index).norm_pass);

  plateau = false;
  for jj = 1:length(manual_indices)
    ie = manual_indices(jj);
    plateau = plateau || (level_data{1}.evaluations(ie).adjacent_tau_pass && ...
      level_data{2}.evaluations(ie).adjacent_tau_pass);
  end
  [agreement_high, agreement_count_high] = ...
    LOCAL_near_solver_agreement(level_data{1}.evaluations);
  [agreement_higher, agreement_count_higher] = ...
    LOCAL_near_solver_agreement(level_data{2}.evaluations);
  agreement = [agreement_high, agreement_higher];
  agreement_count = [agreement_count_high, agreement_count_higher];
  cross_values = [level_data{1}.evaluations.cross_level_change];
  best_cross = min(cross_values);
  basis_limited = all(agreement_count >= 2) && ...
    all(agreement <= config.gate.near_solver_agreement) && ...
    (best_error > config.gate.point_error || ...
    best_cross > config.gate.cross_level_change);

  cutoff_below_default = false;
  restored_directions = 0;
  if manual_pass
    cutoff_below_default = chosen_tau < min([ ...
      level_data{1}.tol_rel, level_data{2}.tol_rel]);
    restored_directions = min([ ...
      level_data{1}.evaluations(tau_index).rank - level_data{1}.rank_default, ...
      level_data{2}.evaluations(tau_index).rank - level_data{2}.rank_default]);
  end
  alternate_pass = manual_pass || backslash_pass;

  if ~refs.eligible || ~preflight_pass
    label = 'INVALID_REFERENCE_OR_REBUILD';
  elseif default_pass && package_pass
    label = 'POINT_VALUE_MFS_GATE_CLOSED_ONLY';
  elseif ~default_pass && alternate_pass && manual_pass && ...
      same_backend_pass && cutoff_below_default && restored_directions >= 1 && ...
      improvement >= config.gate.cutoff_improvement && ...
      selected_improvement >= config.gate.cutoff_improvement
    label = 'CUTOFF_CAUSAL_AND_CLOSED';
  elseif improvement >= config.gate.contribution_improvement && ...
      ~alternate_pass
    label = 'CUTOFF_CONTRIBUTES_NOT_CLOSED';
  elseif basis_limited
    label = 'PROXY_BASIS_COLLOCATION_LIMITED';
  elseif ~plateau || only_large_norm_reduces
    label = 'ILL_CONDITIONED_UNRESOLVED';
  else
    label = 'PROXY_SOLVER_DIAGNOSTIC_UNRESOLVED';
  end

  decision.label = label;
  decision.reference_pass = refs.eligible;
  decision.preflight_pass = preflight_pass;
  decision.preflight_coefficient_diff = preflight_coeff;
  decision.preflight_field_diff = preflight_field;
  decision.repeat_coefficient_change = repeat_coefficient;
  decision.repeat_field_change = repeat_field;
  decision.same_backend_coefficient_diff = same_backend_coefficient;
  decision.same_backend_field_diff = same_backend_field;
  decision.explicit_default_match_pass = explicit_default_match_pass;
  decision.same_backend_tau_point_pass = tau_point_pass;
  decision.same_backend_tau_cross_pass = tau_cross_pass;
  decision.same_backend_pass = same_backend_pass;
  decision.same_backend_tau_point_error = max([ ...
    level_data{1}.evaluations(tau_index).point_error_max, ...
    level_data{2}.evaluations(tau_index).point_error_max]);
  decision.same_backend_tau_cross_change = ...
    level_data{1}.evaluations(tau_index).cross_level_change;
  decision.rank_tau = [level_data{1}.evaluations(tau_index).rank, ...
    level_data{2}.evaluations(tau_index).rank];
  decision.package_pass = package_pass;
  decision.default_pass = default_pass;
  decision.backslash_pass = backslash_pass;
  decision.manual_pass = manual_pass;
  decision.chosen_tau = chosen_tau;
  decision.chosen_index = chosen_index;
  if manual_pass
    decision.selected_adjacent_change_lower = ...
      level_data{1}.evaluations(chosen_index).adjacent_tau_change_lower;
    decision.selected_adjacent_change_upper = ...
      level_data{1}.evaluations(chosen_index).adjacent_tau_change_upper;
    decision.selected_adjacent_change_lower_higher = ...
      level_data{2}.evaluations(chosen_index).adjacent_tau_change_lower;
    decision.selected_adjacent_change_upper_higher = ...
      level_data{2}.evaluations(chosen_index).adjacent_tau_change_upper;
  else
    decision.selected_adjacent_change_lower = NaN;
    decision.selected_adjacent_change_upper = NaN;
    decision.selected_adjacent_change_lower_higher = NaN;
    decision.selected_adjacent_change_upper_higher = NaN;
  end
  decision.cutoff_below_default = cutoff_below_default;
  decision.restored_directions = restored_directions;
  decision.default_error = default_error;
  decision.best_error = best_error;
  decision.best_solver_index = best_index;
  decision.best_solver = level_data{1}.evaluations(best_index).solver;
  decision.best_cross_level_change = best_cross;
  decision.improvement_factor = improvement;
  decision.selected_solver = selected_solver;
  decision.selected_error = selected_error;
  decision.selected_improvement_factor = selected_improvement;
  decision.adjacent_plateau_exists = plateau;
  decision.near_solver_agreement = agreement;
  decision.near_solver_agreement_count = agreement_count;
  decision.only_large_norm_reduces = only_large_norm_reduces;
  decision.point_claim = strcmp(label, 'POINT_VALUE_MFS_GATE_CLOSED_ONLY') || ...
    strcmp(label, 'CUTOFF_CAUSAL_AND_CLOSED');
  decision.derivative_wall_claim = false;
end

function [agreement, count] = LOCAL_near_solver_agreement(evaluations)
  index = find([evaluations.rho_pass]);
  count = length(index);
  if count < 2
    agreement = NaN;
    return;
  end
  agreement = 0;
  for ia = 1:length(index)
    for ib = ia + 1:length(index)
      agreement = max(agreement, LOCAL_field_change( ...
        evaluations(index(ia)).field, evaluations(index(ib)).field));
    end
  end
end

function index = LOCAL_evaluation_index(evaluations, solver, tau)
  candidates = find(strcmp({evaluations.solver}, solver));
  if isfinite(tau)
    values = [evaluations(candidates).tau];
    candidates = candidates(values == tau);
  end
  if length(candidates) ~= 1
    error('run_i4_proxy_solver:EvaluationLookup', ...
      'Expected exactly one evaluation for solver %s.', solver);
  end
  index = candidates;
end

function proxy = LOCAL_proxy_from_coefficients(coefficients, meta)
  nproxy = meta.N_proxy;
  npw = meta.N_pw_total;
  proxy.q = coefficients(1:nproxy).';
  proxy.Z = meta.Z;
  proxy.H = meta.H;
  proxy.C_up = coefficients(nproxy + (1:npw));
  proxy.C_down = coefficients(nproxy + npw + (1:npw));
end

function coefficients = LOCAL_proxy_coefficients(proxy)
  coefficients = [proxy.q(:); proxy.C_up(:); proxy.C_down(:)];
end

function fields = LOCAL_point_fields(config, pars1, proxy)
  fields = zeros(length(config.delta), 1);
  for ip = 1:length(config.delta)
    [src, trg] = LOCAL_physical_points(config, config.delta(ip));
    data = kernel.qpgreen_mfs(src, trg, pars1, proxy);
    fields(ip) = data.pot;
  end
end

function change = LOCAL_field_change(left, right)
  change = max(abs(left(:) - right(:)) ./ ...
    max(ones(numel(right), 1), abs(right(:))));
end

function backend = LOCAL_package_backend()
  if exist('lsqminnorm', 'file')
    backend = 'lsqminnorm';
  else
    backend = 'pinv';
  end
end

%% ==================== Ledger assembly ====================
% This group converts the diagnostic structs to portable CSV cell rows.

function rows = LOCAL_singular_rows(level_data)
  rows = cell(0, 9);
  for il = 1:length(level_data)
    data = level_data{il};
    for is = 1:length(data.s)
      rows(end + 1, :) = {data.level.label, size(data.A, 1), ...
        size(data.A, 2), is, data.s(is), data.s(is) / data.s(1), ...
        data.tol_abs, data.tol_rel, data.rank_default};
    end
  end
end

function rows = LOCAL_solver_rows(level_data)
  rows = cell(0, 30);
  for il = 1:length(level_data)
    data = level_data{il};
    for ie = 1:length(data.evaluations)
      ev = data.evaluations(ie);
      rows(end + 1, :) = {data.level.label, ev.solver, ev.tau, ev.backend, ...
        ev.rank, size(data.A, 1), size(data.A, 2), ev.tol_abs, ev.tol_rel, ...
        ev.relative_residual, ev.rho_min, ev.rho_tol, ev.rho_pass, ...
        ev.normal_residual, ev.coefficient_norm, ev.norm_min, ev.norm_pass, ...
        ev.discarded_rhs_energy, ev.point_error_spectral, ...
        ev.point_error_ewald, ev.point_error_max, ev.point_pass, ...
        ev.adjacent_tau_change_lower, ev.adjacent_tau_change_upper, ...
        ev.adjacent_tau_change, ev.adjacent_tau_pass, ...
        ev.cross_level_change, ev.cross_level_pass, ev.finite, ev.all_pass};
    end
  end
end

function rows = LOCAL_point_rows(config, refs, level_data)
  rows = cell(0, 17);
  for il = 1:length(level_data)
    evaluations = level_data{il}.evaluations;
    for ie = 1:length(evaluations)
      ev = evaluations(ie);
      for ip = 1:length(config.delta)
        err_spectral = abs(ev.field(ip) - refs.spectral_high(ip)) / ...
          max(1, abs(refs.spectral_high(ip)));
        err_ewald = abs(ev.field(ip) - refs.ewald_high(ip)) / ...
          max(1, abs(refs.ewald_high(ip)));
        rows(end + 1, :) = {level_data{il}.level.label, ev.solver, ev.tau, ...
          config.delta(ip), real(ev.field(ip)), imag(ev.field(ip)), ...
          real(refs.spectral_low(ip)), imag(refs.spectral_low(ip)), ...
          real(refs.spectral_high(ip)), imag(refs.spectral_high(ip)), ...
          real(refs.ewald_low(ip)), imag(refs.ewald_low(ip)), ...
          real(refs.ewald_high(ip)), imag(refs.ewald_high(ip)), ...
          err_spectral, err_ewald, ev.cross_level_point_change(ip)};
      end
    end
  end
end

function rows = LOCAL_reproduction_rows(config, level_data)
  rows = cell(0, 6);
  for il = 1:length(level_data)
    data = level_data{il};
    tolerance = config.gate.rebuild_reproduction;
    rows(end + 1, :) = {data.level.label, 'package_precomp_proxy', ...
      data.package_coefficient_repeat, data.package_field_repeat, tolerance, ...
      data.package_coefficient_repeat <= tolerance && ...
      data.package_field_repeat <= tolerance};
    rows(end + 1, :) = {data.level.label, 'local_pinv', ...
      data.pinv_coefficient_repeat, data.pinv_field_repeat, tolerance, ...
      data.pinv_coefficient_repeat <= tolerance && ...
      data.pinv_field_repeat <= tolerance};
    rows(end + 1, :) = {data.level.label, ...
      'pinv_default_vs_explicit_default', ...
      data.default_explicit_coefficient_diff, ...
      data.default_explicit_field_diff, config.gate.same_backend_default, ...
      data.default_explicit_field_diff <= ...
      config.gate.same_backend_default};
  end
end

%% ==================== Persistence and reporting ====================
% This group writes the required CSV, text, Markdown, MAT, and log artifacts.

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_proxy_solver:CsvOpenFailed', 'Could not open %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  for ih = 1:length(headers)
    if ih > 1
      fprintf(fid, ',');
    end
    fprintf(fid, '%s', headers{ih});
  end
  fprintf(fid, '\n');
  for ir = 1:size(rows, 1)
    for ic = 1:size(rows, 2)
      if ic > 1
        fprintf(fid, ',');
      end
      LOCAL_write_csv_value(fid, rows{ir, ic});
    end
    fprintf(fid, '\n');
  end
  clear cleanup;
end

function LOCAL_write_csv_value(fid, value)
  if ischar(value)
    fprintf(fid, '"%s"', strrep(value, '"', '""'));
  elseif islogical(value)
    fprintf(fid, '%d', value);
  elseif isnumeric(value) && isscalar(value)
    if isnan(value)
      fprintf(fid, 'NaN');
    elseif isinf(value)
      fprintf(fid, '%sInf', repmat('-', 1, value < 0));
    else
      fprintf(fid, '%.16e', value);
    end
  else
    error('run_i4_proxy_solver:CsvValue', 'Unsupported CSV value.');
  end
end

function LOCAL_write_decision(path, config, refs, level_data, decision, seconds)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_proxy_solver:DecisionOpenFailed', 'Could not open %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, 'decision=%s\n', decision.label);
  fprintf(fid, 'reference_eligibility=%.16e\n', refs.eligibility_max);
  fprintf(fid, 'reference_tolerance=%.16e\n', ...
    config.gate.reference_eligibility);
  fprintf(fid, 'preflight_coefficient_diff=%.16e\n', ...
    decision.preflight_coefficient_diff);
  fprintf(fid, 'preflight_field_diff=%.16e\n', decision.preflight_field_diff);
  fprintf(fid, 'repeat_coefficient_change=%.16e\n', ...
    decision.repeat_coefficient_change);
  fprintf(fid, 'repeat_field_change=%.16e\n', decision.repeat_field_change);
  fprintf(fid, 'same_backend_coefficient_diff=%.16e\n', ...
    decision.same_backend_coefficient_diff);
  fprintf(fid, 'same_backend_field_diff=%.16e\n', ...
    decision.same_backend_field_diff);
  fprintf(fid, 'explicit_default_match_pass=%d\n', ...
    decision.explicit_default_match_pass);
  fprintf(fid, 'same_backend_tau_point_pass=%d\n', ...
    decision.same_backend_tau_point_pass);
  fprintf(fid, 'same_backend_tau_cross_pass=%d\n', ...
    decision.same_backend_tau_cross_pass);
  fprintf(fid, 'same_backend_tau_point_error=%.16e\n', ...
    decision.same_backend_tau_point_error);
  fprintf(fid, 'same_backend_tau_cross_change=%.16e\n', ...
    decision.same_backend_tau_cross_change);
  fprintf(fid, 'rank_tau_high=%d\n', decision.rank_tau(1));
  fprintf(fid, 'rank_tau_higher=%d\n', decision.rank_tau(2));
  fprintf(fid, 'same_backend_pass=%d\n', decision.same_backend_pass);
  fprintf(fid, 'package_pass=%d\n', decision.package_pass);
  fprintf(fid, 'default_pass=%d\n', decision.default_pass);
  fprintf(fid, 'backslash_pass=%d\n', decision.backslash_pass);
  fprintf(fid, 'manual_pass=%d\n', decision.manual_pass);
  fprintf(fid, 'chosen_tau=%.16e\n', decision.chosen_tau);
  fprintf(fid, 'default_tol_rel_high=%.16e\n', level_data{1}.tol_rel);
  fprintf(fid, 'default_tol_rel_higher=%.16e\n', level_data{2}.tol_rel);
  fprintf(fid, 'restored_directions=%d\n', decision.restored_directions);
  fprintf(fid, 'default_error=%.16e\n', decision.default_error);
  fprintf(fid, 'best_error=%.16e\n', decision.best_error);
  fprintf(fid, 'improvement_factor=%.16e\n', decision.improvement_factor);
  fprintf(fid, 'selected_solver=%s\n', decision.selected_solver);
  fprintf(fid, 'selected_error=%.16e\n', decision.selected_error);
  fprintf(fid, 'selected_improvement_factor=%.16e\n', ...
    decision.selected_improvement_factor);
  fprintf(fid, 'adjacent_plateau_exists=%d\n', ...
    decision.adjacent_plateau_exists);
  fprintf(fid, 'selected_adjacent_lower_high=%.16e\n', ...
    decision.selected_adjacent_change_lower);
  fprintf(fid, 'selected_adjacent_upper_high=%.16e\n', ...
    decision.selected_adjacent_change_upper);
  fprintf(fid, 'selected_adjacent_lower_higher=%.16e\n', ...
    decision.selected_adjacent_change_lower_higher);
  fprintf(fid, 'selected_adjacent_upper_higher=%.16e\n', ...
    decision.selected_adjacent_change_upper_higher);
  fprintf(fid, 'near_solver_agreement_high=%.16e\n', ...
    decision.near_solver_agreement(1));
  fprintf(fid, 'near_solver_agreement_higher=%.16e\n', ...
    decision.near_solver_agreement(2));
  fprintf(fid, 'near_solver_agreement_count_high=%d\n', ...
    decision.near_solver_agreement_count(1));
  fprintf(fid, 'near_solver_agreement_count_higher=%d\n', ...
    decision.near_solver_agreement_count(2));
  fprintf(fid, 'point_claim=%d\n', decision.point_claim);
  fprintf(fid, 'derivative_wall_claim=0\n');
  fprintf(fid, 'total_seconds=%.16e\n', seconds);
  clear cleanup;
end

function LOCAL_write_report(path, config, refs, level_data, decision, ...
    package_backend, ewald_backend, seconds)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_proxy_solver:ReportOpenFailed', 'Could not open %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# i4 Proxy Solver Diagnostic\n\n');
  fprintf(fid, '- Decision: `%s`\n', decision.label);
  fprintf(fid, '- Runtime: `%.6f` seconds\n', seconds);
  fprintf(fid, '- Package backend observed: `%s`\n', package_backend);
  fprintf(fid, '- Ewald backend: `%s`\n', ewald_backend);
  fprintf(fid, '- Reference eligibility: `%.6e` (tolerance `%.1e`)\n', ...
    refs.eligibility_max, config.gate.reference_eligibility);
  fprintf(fid, '- Chosen manual tau: `%.6e`\n\n', decision.chosen_tau);
  fprintf(fid, '## Rebuild preflight\n\n');
  fprintf(fid, ['| Level | A size | Default rank | Relative cutoff | ', ...
    'Coeff diff | Field diff | Max coeff repeat | Max field repeat |\n']);
  fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|\n');
  for il = 1:2
    data = level_data{il};
    fprintf(fid, ['| %s | %d-by-%d | %d | %.6e | %.6e | %.6e | ', ...
      '%.6e | %.6e |\n'], ...
      data.level.label, size(data.A, 1), size(data.A, 2), ...
      data.rank_default, data.tol_rel, data.coefficient_diff, data.field_diff, ...
      max(data.package_coefficient_repeat, data.pinv_coefficient_repeat), ...
      max(data.package_field_repeat, data.pinv_field_repeat));
  end
  fprintf(fid, '\n## Decision diagnostics\n\n');
  fprintf(fid, '- Package/default/backslash/manual pass: `%d/%d/%d/%d`\n', ...
    decision.package_pass, decision.default_pass, decision.backslash_pass, ...
    decision.manual_pass);
  fprintf(fid, '- Default point error: `%.6e`\n', decision.default_error);
  fprintf(fid, '- Best point error: `%.6e`\n', decision.best_error);
  fprintf(fid, '- Improvement factor: `%.6e`\n', decision.improvement_factor);
  fprintf(fid, '- Selected solver/error/improvement: `%s`, `%.6e`, `%.6e`\n', ...
    decision.selected_solver, decision.selected_error, ...
    decision.selected_improvement_factor);
  fprintf(fid, ['- Same-backend default coefficient/field difference: ', ...
    '`%.6e`, `%.6e`\n'], decision.same_backend_coefficient_diff, ...
    decision.same_backend_field_diff);
  fprintf(fid, '- Same-backend selected-tau point/cross pass: `%d/%d`\n', ...
    decision.same_backend_tau_point_pass, ...
    decision.same_backend_tau_cross_pass);
  fprintf(fid, ['- Same-backend selected-tau point error/cross change: ', ...
    '`%.6e`, `%.6e`\n'], decision.same_backend_tau_point_error, ...
    decision.same_backend_tau_cross_change);
  fprintf(fid, '- Selected-tau ranks high/higher: `%d/%d`\n', ...
    decision.rank_tau(1), decision.rank_tau(2));
  fprintf(fid, '- Restored singular directions: `%d`\n', ...
    decision.restored_directions);
  fprintf(fid, '- Adjacent-tau plateau exists: `%d`\n', ...
    decision.adjacent_plateau_exists);
  fprintf(fid, ['- Selected-tau lower/upper neighbor changes high: ', ...
    '`%.6e`, `%.6e`\n'], decision.selected_adjacent_change_lower, ...
    decision.selected_adjacent_change_upper);
  fprintf(fid, ['- Selected-tau lower/upper neighbor changes higher: ', ...
    '`%.6e`, `%.6e`\n'], ...
    decision.selected_adjacent_change_lower_higher, ...
    decision.selected_adjacent_change_upper_higher);
  fprintf(fid, ['- Near-solver field agreement high/higher: `%.6e`, ', ...
    '`%.6e` (qualified counts `%d/%d`; NaN means vacuous)\n\n'], ...
    decision.near_solver_agreement(1), decision.near_solver_agreement(2), ...
    decision.near_solver_agreement_count(1), ...
    decision.near_solver_agreement_count(2));
  fprintf(fid, '## Claim boundary\n\n');
  fprintf(fid, ['This decision concerns three canonical point Green values ', ...
    'only. It makes no derivative, Hessian, wall projection, layer-density, ', ...
    'BIE, complex-root, or root-readiness claim.\n']);
  clear cleanup;
end

function LOCAL_log(fid, varargin)
  fprintf(1, varargin{:});
  fprintf(fid, varargin{:});
  if exist('OCTAVE_VERSION', 'builtin') ~= 0
    fflush(1);
    fflush(fid);
  end
end

function LOCAL_check_deadline(token, config, stage)
  if toc(token) > config.hard_runtime_seconds
    error('run_i4_proxy_solver:RuntimeLimit', ...
      'Hard %.0f-second runtime limit exceeded after %s.', ...
      config.hard_runtime_seconds, stage);
  end
end
