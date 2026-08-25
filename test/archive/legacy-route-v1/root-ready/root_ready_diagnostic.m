function results = root_ready_diagnostic()
% Purpose:
%   Diagnose whether the current quasi-periodic proxy construction has a
%   reproducible fixed-coordinate surrogate for a later complex-k root
%   evaluator.  The experiment deliberately stops before candidate scans,
%   complex disks, Cauchy--Riemann tests, roots, or estimators.
%
% Main algorithm:
%   Reconstruct a mirrored proxy collocation system following
%   kernel.precomp_proxy, compare its observable production outputs, compare
%   pointwise and seed-frozen SVD solvers at three real k values, evaluate
%   independent shifted collocation residuals, repeat at one frozen proxy
%   refinement, and measure downstream double-ellipse BIE/scattering drift.
%
% Based on:
%   research/projects/eig-apost/implementation/root_readiness.md and the
%   Stage 2 corrected density-coordinate path in test/aug-bie.
%
% Main changes:
%   This is an early-stop diagnostic only.  All previously reported values
%   from a corrupted interactive constructor are discarded and never enter
%   a gate.
%
% Numerical goal:
%   Produce an auditable evidence bundle that can support a renewed proxy
%   design review.  No positive root-readiness claim is permitted here.

  started = tic;
  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  output_dir = fullfile(here, 'output');
  if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
  end

  previous = LOCAL_load_previous(fullfile(output_dir, 'results.mat'));
  cfg = LOCAL_config(repo_root, here, output_dir);

  fprintf('Root-readiness early-stop proxy diagnostic\n');
  fprintf('Decision scope: PROXY_DIAGNOSTIC_COMPLETE only\n');
  fprintf('Root, disk, CR, Newton, estimator: NOT_RUN_UPSTREAM_STOP\n');

  [singular_rows, solver_rows, off_rows, cache, seed_data] = ...
    LOCAL_run_proxy_diagnostic(cfg);
  [projector_fingerprints, projectors] = ...
    LOCAL_projector_fingerprints(seed_data);
  resolution_rows = LOCAL_resolution_rows(cfg, cache, off_rows, seed_data);
  downstream_rows = LOCAL_downstream_rows(cfg, cache);
  gate_rows = LOCAL_gate_rows(cfg, solver_rows, off_rows, ...
    resolution_rows, downstream_rows);

  results.cfg = cfg;
  results.singular_spectrum = singular_rows;
  results.solver_comparison = solver_rows;
  results.off_collocation = off_rows;
  results.projector_fingerprints = projector_fingerprints;
  results.projectors = projectors;
  results.resolution = resolution_rows;
  results.downstream_mismatch = downstream_rows;
  results.gates = gate_rows;
  results.status = 'PROXY_DIAGNOSTIC_COMPLETE';
  results.root_readiness = 'BLOCKED_UPSTREAM_PROVENANCE';
  results.root_readiness_sampled_discrete_go = false;
  results.physical_root_ready = 'STOP';
  results.primary_state = ...
    'BLOCKED_MIRRORED_CONSTRUCTOR_OUTPUT_REPRODUCTION';
  results.not_run = { ...
    'candidate_scan', 'candidate_disk', 'full_F_CR', 'root_count', ...
    'bordered_Newton', 'adjacent_level_matching', 'estimator'};
  results.elapsed_seconds = toc(started);
  results.repro_vector = LOCAL_repro_vector(results);
  results.reproducibility = LOCAL_compare_previous(previous, ...
    results.repro_vector, cfg.source_hashes, projector_fingerprints);

  LOCAL_write_outputs(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results', '-v7');

  fprintf('Status: %s\n', results.status);
  fprintf('Readiness: %s; sampled discrete GO: %d\n', ...
    results.root_readiness, results.root_readiness_sampled_discrete_go);
  fprintf('Physical root ready: %s\n', results.physical_root_ready);
  fprintf('Reproducibility: %s\n', results.reproducibility.status);
  fprintf('Elapsed seconds: %.6f\n', results.elapsed_seconds);
end

%% ==================== Configuration ====================
% These helpers freeze the two diagnostic proxy discretizations and sources.

function cfg = LOCAL_config(repo_root, here, output_dir)
  cfg.repo_root = repo_root;
  cfg.here = here;
  cfg.output_dir = output_dir;
  cfg.version = 'eig-apost-root-readiness-early-stop-v2';
  cfg.k_nodes = [0.095, 0.100, 0.105];
  cfg.k_seed = 0.100;
  cfg.beta = 0.8;
  cfg.d = 2 * pi;
  cfg.nref = 3;
  cfg.periodic_axis = 'y';
  cfg.ratio_rank_threshold = 1e-8;
  cfg.object_compatibility_tol = 1e-5;
  cfg.constructor_tol = 1e-11;
  cfg.bulk_axes = [0.40, 0.30];
  cfg.defect_axes = [0.28, 0.21];
  cfg.ntot = 60;
  cfg.rayleigh_M = 7;
  cfg.L = 2;
  cfg.walls = [-1, 1];
  cfg.command = [ ...
    'conda run -n octave octave --quiet --no-gui --eval ', ...
    '"addpath(''test/root-ready''); run_root_ready_diagnostic();"'];
  cfg.discarded_evidence = 'DISCARDED_CORRUPTED_INTERACTIVE_PREFLIGHT';

  cfg.proxy(1) = LOCAL_proxy_config('base', 40, 40, 24, 8, cfg);
  cfg.proxy(2) = LOCAL_proxy_config('refined', 48, 48, 28, 10, cfg);

  source_paths = { ...
    fullfile(here, 'root_ready_diagnostic.m'), ...
    fullfile(here, 'run_root_ready_diagnostic.m'), ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'root_readiness.md'), ...
    fullfile(repo_root, '+kernel', 'precomp_proxy.m'), ...
    fullfile(repo_root, '+kernel', 'qpgreen_mfs_pairmat.m'), ...
    fullfile(repo_root, '+geom', 'construct_cont.m'), ...
    fullfile(repo_root, '+op', 'construct_A_QP.m'), ...
    fullfile(repo_root, '+bloch', 'rayleigh_channels.m'), ...
    fullfile(repo_root, '+bloch', 'incident_rhs.m'), ...
    fullfile(repo_root, '+bloch', 'farfield_extractors.m')};
  source_names = { ...
    'diagnostic', 'wrapper', 'design', 'precomp_proxy', ...
    'qpgreen_pairmat', 'construct_cont', 'construct_A_QP', 'rayleigh_channels', ...
    'incident_rhs', 'farfield_extractors'};
  for idx = 1:length(source_paths)
    cfg.source_hashes.(source_names{idx}).path = source_paths{idx};
    cfg.source_hashes.(source_names{idx}).sha256 = ...
      LOCAL_source_hash(source_paths{idx});
  end
end

function proxy_cfg = LOCAL_proxy_config(label, n_side, n_top, ...
    n_proxy_edge, m_pw, cfg)
  proxy_cfg.label = label;
  proxy_cfg.beta = cfg.beta;
  proxy_cfg.d = cfg.d;
  proxy_cfg.H = 1.8;
  proxy_cfg.proxy_dist = 0.7;
  proxy_cfg.N_side = n_side;
  proxy_cfg.N_top = n_top;
  proxy_cfg.N_proxy_edge = n_proxy_edge;
  proxy_cfg.M_pw = m_pw;
  proxy_cfg.k_seed = cfg.k_seed;
end

%% ==================== Proxy systems and solvers ====================
% One mirrored constructor is shared by every diagnostic solver and residual.

function [singular_rows, solver_rows, off_rows, cache, seed_data] = ...
    LOCAL_run_proxy_diagnostic(cfg)
  singular_rows = LOCAL_empty_singular_rows();
  solver_rows = LOCAL_empty_solver_rows();
  off_rows = LOCAL_empty_off_rows();
  cache = struct([]);
  seed_data = struct([]);

  for ic = 1:length(cfg.proxy)
    pcfg = cfg.proxy(ic);
    [A_seed, b_seed, meta_seed] = LOCAL_build_proxy_system( ...
      cfg.k_seed, pcfg, 'collocation');
    [U_seed, S_seed, V_seed] = svd(A_seed, 'econ');
    s_seed = diag(S_seed);
    ratio_rank = sum(s_seed / s_seed(1) >= cfg.ratio_rank_threshold);
    pinv_tol_seed = max(size(A_seed)) * s_seed(1) * eps;
    pinv_rank_seed = sum(s_seed > pinv_tol_seed);
    seed_data(ic).U = U_seed;
    seed_data(ic).V = V_seed;
    seed_data(ic).s = s_seed;
    seed_data(ic).ratio_rank = ratio_rank;
    seed_data(ic).pinv_rank = pinv_rank_seed;
    seed_data(ic).meta = meta_seed;

    for ik = 1:length(cfg.k_nodes)
      k = cfg.k_nodes(ik);
      [proxy_A, proxy_b, meta] = LOCAL_build_proxy_system( ...
        k, pcfg, 'collocation');
      [U_now, S_now, V_now] = svd(proxy_A, 'econ');
      s_now = diag(S_now);
      pinv_tol = max(size(proxy_A)) * s_now(1) * eps;
      rank_pinv = sum(s_now > pinv_tol);
      rank_ratio = sum(s_now / s_now(1) >= cfg.ratio_rank_threshold);

      for is = 1:length(s_now)
        singular_rows(end + 1) = struct( ...
          'config', pcfg.label, 'k', k, 'm', size(proxy_A, 1), ...
          'n', size(proxy_A, 2), 'index', is, 'sigma', s_now(is), ...
          'sigma_over_sigma1', s_now(is) / s_now(1), ...
          'pinv_tol', pinv_tol, 'rank_pinv', rank_pinv, ...
          'rank_ratio_1e8', rank_ratio);
      end

      pars1 = LOCAL_pars1(k, cfg);
      pars2 = LOCAL_pars2(pcfg);
      production_proxy = kernel.precomp_proxy(pars1, pars2);
      production_coefficients = LOCAL_proxy_coefficients(production_proxy);
      production_field = LOCAL_field_vector(pars1, production_proxy);

      evaluations = LOCAL_solver_evaluations(proxy_A, proxy_b, meta, ...
        production_coefficients, production_field, U_now, s_now, V_now, ...
        U_seed, V_seed, ratio_rank, pinv_tol, pars1);

      [off_A, off_b, off_meta] = LOCAL_build_proxy_system( ...
        k, pcfg, 'off_collocation');
      for ie = 1:length(evaluations)
        ev = evaluations(ie);
        solver_rows(end + 1) = LOCAL_solver_row( ...
          pcfg.label, k, ev);
        off_rows(end + 1) = LOCAL_off_row( ...
          pcfg.label, k, ev, off_A, off_b, off_meta);
      end

      cache(ic, ik).config = pcfg.label;
      cache(ic, ik).k = k;
      cache(ic, ik).meta = meta;
      cache(ic, ik).production = LOCAL_find_evaluation( ...
        evaluations, 'production_actual');
      cache(ic, ik).selected = LOCAL_find_evaluation( ...
        evaluations, 'ratio_rank_rseed');
    end
  end
end

function [rows, projectors] = LOCAL_projector_fingerprints(seed_data)
  rows = struct('config', {}, 'rank', {}, ...
    'left_rows', {}, 'left_cols', {}, 'right_rows', {}, 'right_cols', {}, ...
    'left_trace', {}, 'right_trace', {}, ...
    'left_frobenius', {}, 'right_frobenius', {}, ...
    'left_idempotence', {}, 'right_idempotence', {}, ...
    'left_weighted_real', {}, 'left_weighted_imag', {}, ...
    'right_weighted_real', {}, 'right_weighted_imag', {}, ...
    'left_sha256', {}, 'right_sha256', {});
  projectors = struct('config', {}, 'rank', {}, 'left', {}, 'right', {});
  labels = {'base', 'refined'};
  for idx = 1:length(seed_data)
    rank_value = seed_data(idx).ratio_rank;
    U_r = seed_data(idx).U(:, 1:rank_value);
    V_r = seed_data(idx).V(:, 1:rank_value);
    P_left = U_r * U_r';
    P_right = V_r * V_r';
    [left_real, left_imag] = LOCAL_weighted_checksum(P_left);
    [right_real, right_imag] = LOCAL_weighted_checksum(P_right);
    rows(end + 1) = struct('config', labels{idx}, 'rank', rank_value, ...
      'left_rows', size(P_left, 1), 'left_cols', size(P_left, 2), ...
      'right_rows', size(P_right, 1), 'right_cols', size(P_right, 2), ...
      'left_trace', real(trace(P_left)), ...
      'right_trace', real(trace(P_right)), ...
      'left_frobenius', norm(P_left, 'fro'), ...
      'right_frobenius', norm(P_right, 'fro'), ...
      'left_idempotence', LOCAL_relmat(P_left * P_left, P_left), ...
      'right_idempotence', LOCAL_relmat(P_right * P_right, P_right), ...
      'left_weighted_real', left_real, ...
      'left_weighted_imag', left_imag, ...
      'right_weighted_real', right_real, ...
      'right_weighted_imag', right_imag, ...
      'left_sha256', LOCAL_matrix_sha256(P_left), ...
      'right_sha256', LOCAL_matrix_sha256(P_right));
    projectors(end + 1) = struct('config', labels{idx}, ...
      'rank', rank_value, 'left', P_left, 'right', P_right);
  end
end

function [real_part, imag_part] = LOCAL_weighted_checksum(A)
  weights = mod((1:numel(A)).', 104729) + 1;
  value = sum(A(:) .* weights) / max(1, numel(A));
  real_part = real(value);
  imag_part = imag(value);
end

function digest = LOCAL_matrix_sha256(A)
  if exist('hash', 'builtin') ~= 5 && exist('hash', 'file') ~= 2
    digest = 'HASH_UNAVAILABLE';
    return;
  end
  values = [real(A(:)).'; imag(A(:)).'];
  payload = sprintf('rows=%d;cols=%d;', size(A, 1), size(A, 2));
  payload = [payload, sprintf('%.17e,%.17e;', values)];
  digest = hash('sha256', payload);
end

function evaluations = LOCAL_solver_evaluations(A, b, meta, ...
    production_c, production_field, U_now, s_now, V_now, ...
    U_seed, V_seed, rseed, pinv_tol, pars1)
  evaluations = LOCAL_empty_evaluations();

  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'production_actual', true, pinv_tol, sum(s_now > pinv_tol), ...
    production_c, NaN, A, b, meta, production_c, production_field, ...
    pars1, 'kernel.precomp_proxy output');

  c_pinv = pinv(A) * b;
  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'pinv_default', true, pinv_tol, sum(s_now > pinv_tol), ...
    c_pinv, NaN, A, b, meta, production_c, production_field, ...
    pars1, 'pinv(A)*b with Octave default tolerance');

  keep = s_now > pinv_tol;
  c_svd = V_now(:, keep) * ((U_now(:, keep)' * b) ./ s_now(keep));
  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'explicit_svd_pinv_tol', true, pinv_tol, sum(keep), ...
    c_svd, NaN, A, b, meta, production_c, production_field, ...
    pars1, 'explicit thin-SVD pseudoinverse at the recorded tolerance');

  rank_offsets = [0, -1, -2];
  solver_names = { ...
    'ratio_rank_rseed', 'ratio_rank_rseed_minus1', ...
    'ratio_rank_rseed_minus2'};
  for idx = 1:length(rank_offsets)
    rank_value = rseed + rank_offsets(idx);
    if rank_value < 1
      evaluations(end + 1) = LOCAL_unavailable_evaluation( ...
        solver_names{idx}, 'ratio-selected rank is smaller than one');
      continue;
    end
    U_r = U_seed(:, 1:rank_value);
    V_r = V_seed(:, 1:rank_value);
    reduced_A = U_r' * A * V_r;
    reduced_b = U_r' * b;
    a_r = reduced_A \ reduced_b;
    c_r = V_r * a_r;
    projected_residual = norm(reduced_A * a_r - reduced_b, 2) / ...
      max(1, norm(reduced_b, 2));
    factor_rcond = rcond(reduced_A);
    solver_note = sprintf([ ...
      'seed-frozen two-sided SVD coordinates;factor_rcond=%.17g'], ...
      factor_rcond);
    ev = LOCAL_make_evaluation(solver_names{idx}, true, ...
      cfg_nan(), rank_value, c_r, projected_residual, A, b, meta, ...
      production_c, production_field, pars1, ...
      solver_note);
    ev.factor_rcond = factor_rcond;
    evaluations(end + 1) = ev;
  end

  evaluations(end + 1) = LOCAL_unavailable_evaluation( ...
    'lsqminnorm', 'lsqminnorm is unavailable in the Octave environment');
end

function ev = LOCAL_make_evaluation(name, available, tolerance, rank_value, ...
    coefficients, projected_residual, A, b, meta, production_c, ...
    production_field, pars1, note)
  residual = A * coefficients - b;
  full_residual = norm(residual, 2) / max(1, norm(b, 2));
  denominator = max(1, norm(A, 2) * norm(coefficients, 2) + norm(b, 2));
  proxy = LOCAL_proxy_from_coefficients(coefficients, meta);
  field = LOCAL_field_vector(pars1, proxy);

  ev.name = name;
  ev.available = available;
  ev.tolerance = tolerance;
  ev.rank = rank_value;
  ev.coefficients = coefficients;
  ev.coefficient_norm = norm(coefficients, 2);
  ev.projected_residual = projected_residual;
  ev.full_residual = full_residual;
  ev.full_system_backward = norm(residual, 2) / denominator;
  ev.production_coefficient_error = LOCAL_relmat( ...
    coefficients, production_c);
  ev.production_proxy_field_error = LOCAL_relmat( ...
    field, production_field);
  ev.factor_rcond = NaN;
  ev.proxy = proxy;
  ev.field = field;
  ev.status = 'COMPUTED';
  ev.note = note;
end

function ev = LOCAL_unavailable_evaluation(name, note)
  ev.name = name;
  ev.available = false;
  ev.tolerance = NaN;
  ev.rank = -1;
  ev.coefficients = NaN;
  ev.coefficient_norm = NaN;
  ev.projected_residual = NaN;
  ev.full_residual = NaN;
  ev.full_system_backward = NaN;
  ev.production_coefficient_error = NaN;
  ev.production_proxy_field_error = NaN;
  ev.factor_rcond = NaN;
  ev.proxy = struct();
  ev.field = NaN;
  ev.status = 'UNAVAILABLE';
  ev.note = note;
end

function value = cfg_nan()
  value = NaN;
end

function ev = LOCAL_find_evaluation(evaluations, name)
  matches = find(strcmp({evaluations.name}, name));
  if length(matches) ~= 1
    error('root_ready_diagnostic:EvaluationLookup', ...
      'Expected exactly one evaluation named %s.', name);
  end
  ev = evaluations(matches);
end

function [A, b, meta] = LOCAL_build_proxy_system(k, pcfg, point_set)
  d = pcfg.d;
  beta = pcfg.beta;
  H = pcfg.H;
  proxy_dist = pcfg.proxy_dist;
  n_side = pcfg.N_side;
  n_top = pcfg.N_top;
  n_proxy_edge = pcfg.N_proxy_edge;
  m_pw = pcfg.M_pw;

  if strcmp(point_set, 'collocation')
    y_side = linspace(-H, H, n_side).';
    x_top = linspace(-d / 2, d / 2, n_top).';
  elseif strcmp(point_set, 'off_collocation')
    n_side = 2 * n_side;
    n_top = 2 * n_top;
    y_side = -H + ((0:n_side - 1).' + 0.5) * (2 * H / n_side);
    x_top = -d / 2 + ((0:n_top - 1).' + 0.5) * (d / n_top);
  else
    error('root_ready_diagnostic:PointSet', ...
      'Unknown proxy point set %s.', point_set);
  end

  p_L = [-d / 2 * ones(n_side, 1), y_side];
  p_R = [ d / 2 * ones(n_side, 1), y_side];
  p_T = [x_top, H * ones(n_top, 1)];
  p_B = [x_top, -H * ones(n_top, 1)];

  x_min = -d / 2 - proxy_dist;
  x_max = d / 2 + proxy_dist;
  y_min = -H - proxy_dist;
  y_max = H + proxy_dist;
  tx = linspace(x_min, x_max, n_proxy_edge + 1).';
  ty = linspace(y_min, y_max, n_proxy_edge + 1).';
  tx(end) = [];
  ty(end) = [];
  px = [tx; repmat(x_max, n_proxy_edge, 1); flipud(tx); ...
    repmat(x_min, n_proxy_edge, 1)];
  py = [repmat(y_min, n_proxy_edge, 1); ty; ...
    repmat(y_max, n_proxy_edge, 1); flipud(ty)];
  Z_proxy = [px, py];
  n_proxy = size(Z_proxy, 1);

  m_vec = (-m_pw:m_pw).';
  beta_m = beta + m_vec * (2 * pi / d);
  gamma_m = sqrt(k^2 - beta_m.^2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);
  n_pw = length(m_vec);

  n_eqs = 2 * n_side + 4 * n_top;
  n_unknowns = n_proxy + 2 * n_pw;
  A = zeros(n_eqs, n_unknowns);
  b = zeros(n_eqs, 1);

  idx_LR_v = 1:n_side;
  idx_LR_d = n_side + (1:n_side);
  idx_T_v = 2 * n_side + (1:n_top);
  idx_T_d = 2 * n_side + n_top + (1:n_top);
  idx_B_v = 2 * n_side + 2 * n_top + (1:n_top);
  idx_B_d = 2 * n_side + 3 * n_top + (1:n_top);
  col_proxy = 1:n_proxy;
  col_pw_T = n_proxy + (1:n_pw);
  col_pw_B = n_proxy + n_pw + (1:n_pw);

  phase = exp(1i * beta * d);
  src = [0, 0];
  [V_sL, dVdx_sL, ~] = LOCAL_eval_G(k, p_L, src);
  [V_sR, dVdx_sR, ~] = LOCAL_eval_G(k, p_R, src);
  b(idx_LR_v) = -(V_sR - phase * V_sL);
  b(idx_LR_d) = -(dVdx_sR - phase * dVdx_sL);
  [V_sT, ~, dVdy_sT] = LOCAL_eval_G(k, p_T, src);
  b(idx_T_v) = -V_sT;
  b(idx_T_d) = -dVdy_sT;
  [V_sB, ~, dVdy_sB] = LOCAL_eval_G(k, p_B, src);
  b(idx_B_v) = -V_sB;
  b(idx_B_d) = -dVdy_sB;

  [V_pL, dVdx_pL, ~] = LOCAL_eval_G(k, p_L, Z_proxy);
  [V_pR, dVdx_pR, ~] = LOCAL_eval_G(k, p_R, Z_proxy);
  A(idx_LR_v, col_proxy) = V_pR - phase * V_pL;
  A(idx_LR_d, col_proxy) = dVdx_pR - phase * dVdx_pL;
  [V_pT, ~, dVdy_pT] = LOCAL_eval_G(k, p_T, Z_proxy);
  A(idx_T_v, col_proxy) = V_pT;
  A(idx_T_d, col_proxy) = dVdy_pT;
  [V_pB, ~, dVdy_pB] = LOCAL_eval_G(k, p_B, Z_proxy);
  A(idx_B_v, col_proxy) = V_pB;
  A(idx_B_d, col_proxy) = dVdy_pB;

  PW_T = exp(1i * p_T(:, 1) * beta_m.');
  A(idx_T_v, col_pw_T) = -PW_T;
  A(idx_T_d, col_pw_T) = -PW_T .* (1i * gamma_m.');
  PW_B = exp(1i * p_B(:, 1) * beta_m.');
  A(idx_B_v, col_pw_B) = -PW_B;
  A(idx_B_d, col_pw_B) = -PW_B .* (-1i * gamma_m.');

  meta.Z_proxy = Z_proxy;
  meta.H = H;
  meta.n_proxy = n_proxy;
  meta.n_pw = n_pw;
  meta.indices = {idx_LR_v, idx_LR_d, idx_T_v, ...
    idx_T_d, idx_B_v, idx_B_d};
  meta.point_set = point_set;
end

function [V, dVdx, dVdy] = LOCAL_eval_G(k, pt, ps)
  dx = pt(:, 1) - ps(:, 1).';
  dy = pt(:, 2) - ps(:, 2).';
  rho = sqrt(dx.^2 + dy.^2);
  V = (1i / 4) * besselh(0, 1, k * rho);
  coefficient = -(1i * k / 4) * besselh(1, 1, k * rho) ./ rho;
  dVdx = coefficient .* dx;
  dVdy = coefficient .* dy;
end

function pars1 = LOCAL_pars1(k, cfg)
  pars1.k = k;
  pars1.beta = cfg.beta;
  pars1.d = cfg.d;
  pars1.periodic_axis = cfg.periodic_axis;
end

function pars2 = LOCAL_pars2(pcfg)
  pars2.H = pcfg.H;
  pars2.proxy_dist = pcfg.proxy_dist;
  pars2.N_side = pcfg.N_side;
  pars2.N_top = pcfg.N_top;
  pars2.N_proxy_edge = pcfg.N_proxy_edge;
  pars2.M_pw = pcfg.M_pw;
end

function coefficients = LOCAL_proxy_coefficients(proxy)
  coefficients = [proxy.q(:); proxy.C_up(:); proxy.C_down(:)];
end

function proxy = LOCAL_proxy_from_coefficients(coefficients, meta)
  nq = meta.n_proxy;
  npw = meta.n_pw;
  proxy.q = coefficients(1:nq).';
  proxy.Z = meta.Z_proxy.';
  proxy.H = meta.H;
  proxy.C_up = coefficients(nq + (1:npw));
  proxy.C_down = coefficients(nq + npw + (1:npw));
end

function field = LOCAL_field_vector(pars1, proxy)
  src = [-0.15, 0.10, 0.22; 0.07, -0.13, 0.18];
  trg = [0.25, -0.20, 0.05, -0.10; -0.11, 0.17, 0.24, -0.20];
  [pot, gradx, grady, hessxx, hessxy, hessyy] = ...
    kernel.qpgreen_mfs_pairmat(src, trg, pars1, proxy);
  field = [pot(:); gradx(:); grady(:); hessxx(:); hessxy(:); hessyy(:)];
end

%% ==================== Independent diagnostics ====================
% These helpers form off-collocation, resolution, and downstream evidence.

function row = LOCAL_solver_row(config, k, ev)
  row = struct('config', config, 'k', k, 'solver', ev.name, ...
    'available', ev.available, 'tolerance', ev.tolerance, ...
    'rank', ev.rank, 'coefficient_norm', ev.coefficient_norm, ...
    'projected_residual', ev.projected_residual, ...
    'full_residual', ev.full_residual, ...
    'full_system_backward', ev.full_system_backward, ...
    'production_coefficient_error', ev.production_coefficient_error, ...
    'production_proxy_field_error', ev.production_proxy_field_error, ...
    'status', ev.status, 'note', ev.note);
end

function row = LOCAL_off_row(config, k, ev, A, b, meta)
  values = NaN(1, 6);
  combined = NaN;
  status = 'UNAVAILABLE';
  if ev.available
    residual = A * ev.coefficients - b;
    for idx = 1:6
      rows = meta.indices{idx};
      values(idx) = norm(residual(rows), 2) / max(1, norm(b(rows), 2));
    end
    combined = norm(residual, 2) / max(1, norm(b, 2));
    status = 'COMPUTED';
  end
  row = struct('config', config, 'k', k, 'solver', ev.name, ...
    'point_set', 'shifted_densified', ...
    'qp_value_residual', values(1), ...
    'qp_derivative_residual', values(2), ...
    'top_value_residual', values(3), ...
    'top_derivative_residual', values(4), ...
    'bottom_value_residual', values(5), ...
    'bottom_derivative_residual', values(6), ...
    'combined_residual', combined, 'status', status);
end

function rows = LOCAL_resolution_rows(cfg, cache, off_rows, seed_data)
  rows = struct('k', {}, 'base_solver', {}, 'refined_solver', {}, ...
    'base_rank', {}, 'refined_rank', {}, 'base_full_residual', {}, ...
    'refined_full_residual', {}, 'base_off_residual', {}, ...
    'refined_off_residual', {}, 'coefficient_norms', {}, ...
    'green_pot_diff', {}, 'green_grad_diff', {}, ...
    'green_hess_diff', {}, 'status', {});
  for ik = 1:length(cfg.k_nodes)
    base = cache(1, ik).selected;
    refined = cache(2, ik).selected;
    base_off = LOCAL_off_lookup(off_rows, 'base', cfg.k_nodes(ik), ...
      'ratio_rank_rseed');
    refined_off = LOCAL_off_lookup(off_rows, 'refined', cfg.k_nodes(ik), ...
      'ratio_rank_rseed');
    [pot_diff, grad_diff, hess_diff] = LOCAL_field_component_diffs( ...
      base.field, refined.field);
    norm_text = sprintf('base:%.17g|refined:%.17g', ...
      base.coefficient_norm, refined.coefficient_norm);
    observed = max([pot_diff, grad_diff, hess_diff]);
    rows(end + 1) = struct('k', cfg.k_nodes(ik), ...
      'base_solver', 'ratio_rank_rseed', ...
      'refined_solver', 'ratio_rank_rseed', ...
      'base_rank', seed_data(1).ratio_rank, ...
      'refined_rank', seed_data(2).ratio_rank, ...
      'base_full_residual', base.full_residual, ...
      'refined_full_residual', refined.full_residual, ...
      'base_off_residual', base_off.combined_residual, ...
      'refined_off_residual', refined_off.combined_residual, ...
      'coefficient_norms', norm_text, 'green_pot_diff', pot_diff, ...
      'green_grad_diff', grad_diff, 'green_hess_diff', hess_diff, ...
      'status', LOCAL_pass_status(observed <= cfg.object_compatibility_tol));
  end
end

function row = LOCAL_off_lookup(rows, config, k, solver)
  mask = strcmp({rows.config}, config) & strcmp({rows.solver}, solver) & ...
    abs([rows.k] - k) < 10 * eps;
  found = find(mask);
  if length(found) ~= 1
    error('root_ready_diagnostic:OffLookup', ...
      'Expected one off-collocation row.');
  end
  row = rows(found);
end

function [pot_diff, grad_diff, hess_diff] = LOCAL_field_component_diffs(a, b)
  n_pot = 12;
  n_grad = 24;
  pot_diff = LOCAL_relmat(a(1:n_pot), b(1:n_pot));
  grad_diff = LOCAL_relmat(a(n_pot + (1:n_grad)), ...
    b(n_pot + (1:n_grad)));
  hess_diff = LOCAL_relmat(a(n_pot + n_grad + 1:end), ...
    b(n_pot + n_grad + 1:end));
end

function rows = LOCAL_downstream_rows(cfg, cache)
  rows = struct('k', {}, 'geometry', {}, 'quantity', {}, ...
    'solver_a', {}, 'solver_b', {}, 'relative_difference', {}, ...
    'rcond', {}, 'solve_residual', {}, 'status', {});
  [defect_geom, defect_length] = geom.construct_cont(cfg.ntot, ...
    'ellipse', 0, 0, cfg.defect_axes);
  [bulk_geom, bulk_length] = geom.construct_cont(cfg.ntot, ...
    'ellipse', 0, 0, cfg.bulk_axes);

  for ic = 1:length(cfg.proxy)
    for ik = 1:length(cfg.k_nodes)
      k = cfg.k_nodes(ik);
      pars1 = LOCAL_pars1(k, cfg);
      channels = bloch.rayleigh_channels(k, cfg.beta, cfg.d, ...
        cfg.rayleigh_M, cfg.L);
      solver_a = sprintf('%s:production_actual', cfg.proxy(ic).label);
      solver_b = sprintf('%s:ratio_rank_rseed', cfg.proxy(ic).label);

      rows = LOCAL_add_proxy_downstream(rows, k, ...
        cache(ic, ik).production.field, cache(ic, ik).selected.field, ...
        solver_a, solver_b, cfg);

      rows = LOCAL_add_geometry_downstream(rows, 'defect', defect_geom, ...
        defect_length, k, pars1, channels, cache(ic, ik).production.proxy, ...
        cache(ic, ik).selected.proxy, solver_a, solver_b, cfg);
      rows = LOCAL_add_geometry_downstream(rows, 'bulk', bulk_geom, ...
        bulk_length, k, pars1, channels, cache(ic, ik).production.proxy, ...
        cache(ic, ik).selected.proxy, solver_a, solver_b, cfg);
    end
  end
end

function rows = LOCAL_add_proxy_downstream(rows, k, field_a, field_b, ...
    solver_a, solver_b, cfg)
  [pot_diff, grad_diff, hess_diff] = LOCAL_field_component_diffs( ...
    field_a, field_b);
  quantities = {'green_pot', 'green_grad', 'green_hess'};
  differences = [pot_diff, grad_diff, hess_diff];
  for idx = 1:length(quantities)
    pass = differences(idx) <= cfg.object_compatibility_tol;
    rows(end + 1) = struct('k', k, 'geometry', 'proxy', ...
      'quantity', quantities{idx}, 'solver_a', solver_a, ...
      'solver_b', solver_b, 'relative_difference', differences(idx), ...
      'rcond', NaN, 'solve_residual', NaN, ...
      'status', LOCAL_pass_status(pass));
  end
end

function rows = LOCAL_add_geometry_downstream(rows, geometry_name, C, ...
    curvelen, k, pars1, channels, proxy_a, proxy_b, solver_a, solver_b, cfg)
  a = LOCAL_scaled_scattering(C, curvelen, k, pars1, channels, proxy_a, cfg);
  b = LOCAL_scaled_scattering(C, curvelen, k, pars1, channels, proxy_b, cfg);
  quantities = {'A_QP', 'R_L', 'T_LR', 'T_RL', 'R_R'};
  for idx = 1:length(quantities)
    name = quantities{idx};
    difference = LOCAL_relmat(a.(name), b.(name));
    status = LOCAL_pass_status(difference <= cfg.object_compatibility_tol);
    rows(end + 1) = struct('k', k, 'geometry', geometry_name, ...
      'quantity', name, 'solver_a', solver_a, 'solver_b', solver_b, ...
      'relative_difference', difference, ...
      'rcond', min(a.A_rcond, b.A_rcond), ...
      'solve_residual', max(a.solve_residual, b.solve_residual), ...
      'status', status);
  end
end

function status = LOCAL_pass_status(pass)
  if pass
    status = 'PASS';
  else
    status = 'FAIL';
  end
end

function data = LOCAL_scaled_scattering(C, curvelen, k, pars1, ...
    channels, proxy, cfg)
  A_QP = full(complex(op.construct_A_QP(C, k, cfg.nref * k, ...
    pars1, proxy, curvelen)));
  [B_L_physical, B_R_physical] = bloch.incident_rhs( ...
    C, channels, cfg.walls(1), cfg.walls(2));
  [E_L_physical, E_R_physical] = bloch.farfield_extractors( ...
    C, channels, cfg.walls(1), cfg.walls(2), curvelen);
  h = curvelen / size(C, 2);
  speed = sqrt(C(2, :).^2 + C(5, :).^2);
  density_scale = sqrt(h * [speed, speed]).';
  B_L = bsxfun(@times, B_L_physical, density_scale);
  B_R = bsxfun(@times, B_R_physical, density_scale);
  E_L = bsxfun(@rdivide, E_L_physical, density_scale.');
  E_R = bsxfun(@rdivide, E_R_physical, density_scale.');
  rhs = -[B_L, B_R];
  H_all = A_QP \ rhs;
  solve_residual = norm(A_QP * H_all - rhs, 'fro') / ...
    max(1, norm(rhs, 'fro'));
  p = channels.K;
  H_L = H_all(:, 1:p);
  H_R = H_all(:, p + 1:2 * p);
  phase = diag(channels.phase);

  data.A_QP = A_QP;
  data.R_L = E_L * H_L;
  data.T_LR = phase + E_R * H_L;
  data.T_RL = phase + E_L * H_R;
  data.R_R = E_R * H_R;
  data.A_rcond = rcond(A_QP);
  data.solve_residual = solve_residual;
end

%% ==================== Gates and reproducibility ====================
% Observable output, frozen-object, and provenance gates are kept distinct.

function rows = LOCAL_gate_rows(cfg, solver_rows, off_rows, ...
    resolution_rows, downstream_rows)
  rows = struct('gate', {}, 'threshold', {}, 'observed', {}, ...
    'pass', {}, 'availability', {}, 'failure_reason', {});
  constructor_errors = [];
  constructor_field_errors = [];
  residual_identity = [];
  for ic = 1:length(cfg.proxy)
    for ik = 1:length(cfg.k_nodes)
      prod = LOCAL_solver_lookup(solver_rows, cfg.proxy(ic).label, ...
        cfg.k_nodes(ik), 'production_actual');
      pinv_row = LOCAL_solver_lookup(solver_rows, cfg.proxy(ic).label, ...
        cfg.k_nodes(ik), 'pinv_default');
      constructor_errors(end + 1) = pinv_row.production_coefficient_error;
      constructor_field_errors(end + 1) = ...
        pinv_row.production_proxy_field_error;
      residual_identity(end + 1) = abs(prod.full_residual - pinv_row.full_residual);
    end
  end
  constructor_observed = max(constructor_errors);
  constructor_field_observed = max(constructor_field_errors);
  residual_observed = max(residual_identity);
  rows(end + 1) = LOCAL_gate('production_internal_A_b_identity', ...
    NaN, NaN, false, false, 'NOT_OBSERVABLE_WITH_CURRENT_INTERFACE');
  rows(end + 1) = LOCAL_gate( ...
    'mirrored_constructor_coefficient_output_reproduction', ...
    cfg.constructor_tol, constructor_observed, ...
    constructor_observed <= cfg.constructor_tol, true, ...
    LOCAL_reason(constructor_observed <= cfg.constructor_tol, ...
      'MIRRORED_CONSTRUCTOR_COEFFICIENT_OUTPUT_REPRODUCTION_FAILURE'));
  rows(end + 1) = LOCAL_gate( ...
    'mirrored_constructor_proxy_field_output_reproduction', ...
    cfg.constructor_tol, constructor_field_observed, ...
    constructor_field_observed <= cfg.constructor_tol, true, ...
    LOCAL_reason(constructor_field_observed <= cfg.constructor_tol, ...
      'MIRRORED_CONSTRUCTOR_PROXY_FIELD_OUTPUT_REPRODUCTION_FAILURE'));
  rows(end + 1) = LOCAL_gate( ...
    'mirrored_constructor_residual_output_reproduction', ...
    cfg.constructor_tol, residual_observed, ...
    residual_observed <= cfg.constructor_tol, true, ...
    LOCAL_reason(residual_observed <= cfg.constructor_tol, ...
      'MIRRORED_CONSTRUCTOR_RESIDUAL_OUTPUT_REPRODUCTION_FAILURE'));

  selected_off = off_rows(strcmp({off_rows.solver}, 'ratio_rank_rseed'));
  off_observed = max([selected_off.combined_residual]);
  rows(end + 1) = LOCAL_gate('off_collocation_readiness', NaN, ...
    off_observed, false, false, 'PENDING_REVIEW');

  resolution_values = [[resolution_rows.green_pot_diff], ...
    [resolution_rows.green_grad_diff], [resolution_rows.green_hess_diff]];
  resolution_observed = max(resolution_values);
  resolution_pass = resolution_observed <= cfg.object_compatibility_tol && ...
    all(strcmp({resolution_rows.status}, 'PASS'));
  rows(end + 1) = LOCAL_gate('object_compatibility_resolution', ...
    cfg.object_compatibility_tol, resolution_observed, resolution_pass, ...
    true, LOCAL_reason(resolution_pass, ...
      'OBJECT_COMPATIBILITY_RESOLUTION_FAILURE'));

  downstream_observed = max([downstream_rows.relative_difference]);
  downstream_pass = downstream_observed <= cfg.object_compatibility_tol && ...
    all(strcmp({downstream_rows.status}, 'PASS'));
  rows(end + 1) = LOCAL_gate('object_compatibility_downstream', ...
    cfg.object_compatibility_tol, downstream_observed, downstream_pass, ...
    true, LOCAL_reason(downstream_pass, ...
      'OBJECT_COMPATIBILITY_DOWNSTREAM_FAILURE'));
  all_object_observed = max(resolution_observed, downstream_observed);
  all_object_pass = resolution_pass && downstream_pass;
  rows(end + 1) = LOCAL_gate('object_compatibility_all', ...
    cfg.object_compatibility_tol, all_object_observed, all_object_pass, ...
    true, LOCAL_reason(all_object_pass, 'OBJECT_COMPATIBILITY_FAILURE'));

  hashes = fieldnames(cfg.source_hashes);
  source_ok = true;
  for idx = 1:length(hashes)
    value = cfg.source_hashes.(hashes{idx}).sha256;
    source_ok = source_ok && ~strcmp(value, 'MISSING') && ...
      ~strcmp(value, 'HASH_FAILED');
  end
  rows(end + 1) = LOCAL_gate('source_provenance', 1, source_ok, ...
    source_ok, true, LOCAL_reason(source_ok, 'SOURCE_PROVENANCE_FAILURE'));
end

function row = LOCAL_solver_lookup(rows, config, k, solver)
  mask = strcmp({rows.config}, config) & strcmp({rows.solver}, solver) & ...
    abs([rows.k] - k) < 10 * eps;
  found = find(mask);
  if length(found) ~= 1
    error('root_ready_diagnostic:SolverLookup', ...
      'Expected one solver-comparison row.');
  end
  row = rows(found);
end

function row = LOCAL_gate(name, threshold, observed, pass, availability, reason)
  row = struct('gate', name, 'threshold', threshold, ...
    'observed', observed, 'pass', pass, ...
    'availability', availability, 'failure_reason', reason);
end

function reason = LOCAL_reason(pass, failure_reason)
  if pass
    reason = '';
  else
    reason = failure_reason;
  end
end

function previous = LOCAL_load_previous(path)
  previous.available = false;
  previous.projector_fingerprints = struct([]);
  if exist(path, 'file') ~= 2
    return;
  end
  loaded = load(path);
  if isfield(loaded, 'results') && isfield(loaded.results, 'repro_vector') && ...
      isfield(loaded.results, 'cfg') && ...
      isfield(loaded.results.cfg, 'source_hashes')
    previous.available = true;
    previous.vector = loaded.results.repro_vector;
    previous.source_hashes = loaded.results.cfg.source_hashes;
    if isfield(loaded.results, 'projector_fingerprints')
      previous.projector_fingerprints = loaded.results.projector_fingerprints;
    end
  end
end

function repro = LOCAL_compare_previous(previous, vector, source_hashes, ...
    projector_fingerprints)
  repro.tolerance = 1e-13;
  if ~previous.available
    repro.status = 'BASELINE_CREATED';
    repro.relative_difference = NaN;
    repro.manifest_equal = false;
    repro.projector_fingerprints_equal = false;
    repro.pass = false;
    return;
  end
  old = previous.vector(:);
  new = vector(:);
  if length(old) ~= length(new)
    relative_difference = Inf;
  else
    finite_mask = isfinite(old) & isfinite(new);
    nonfinite_equal = all(isnan(old(~finite_mask)) == isnan(new(~finite_mask))) && ...
      all(isinf(old(~finite_mask)) == isinf(new(~finite_mask)));
    if any(finite_mask)
      relative_difference = LOCAL_relmat(old(finite_mask), new(finite_mask));
    else
      relative_difference = 0;
    end
    if ~nonfinite_equal
      relative_difference = Inf;
    end
  end
  manifest_equal = LOCAL_manifest_equal(previous.source_hashes, source_hashes);
  projector_fingerprints_equal = LOCAL_projector_fingerprints_equal( ...
    previous.projector_fingerprints, projector_fingerprints);
  repro.relative_difference = relative_difference;
  repro.manifest_equal = manifest_equal;
  repro.projector_fingerprints_equal = projector_fingerprints_equal;
  repro.pass = manifest_equal && projector_fingerprints_equal && ...
    relative_difference <= repro.tolerance;
  if repro.pass
    repro.status = 'REPRODUCED';
  else
    repro.status = 'REPRODUCIBILITY_FAILURE';
  end
end

function equal = LOCAL_projector_fingerprints_equal(old_rows, new_rows)
  equal = length(old_rows) == length(new_rows) && ~isempty(new_rows);
  if ~equal
    return;
  end
  for idx = 1:length(new_rows)
    old = old_rows(idx);
    new = new_rows(idx);
    hashes_available = ~strcmp(old.left_sha256, 'HASH_UNAVAILABLE') && ...
      ~strcmp(old.right_sha256, 'HASH_UNAVAILABLE') && ...
      ~strcmp(new.left_sha256, 'HASH_UNAVAILABLE') && ...
      ~strcmp(new.right_sha256, 'HASH_UNAVAILABLE');
    equal = hashes_available && strcmp(old.config, new.config) && ...
      old.rank == new.rank && old.left_rows == new.left_rows && ...
      old.left_cols == new.left_cols && ...
      old.right_rows == new.right_rows && ...
      old.right_cols == new.right_cols && ...
      strcmp(old.left_sha256, new.left_sha256) && ...
      strcmp(old.right_sha256, new.right_sha256);
    if ~equal
      return;
    end
  end
end

function equal = LOCAL_manifest_equal(old_hashes, new_hashes)
  old_names = sort(fieldnames(old_hashes));
  new_names = sort(fieldnames(new_hashes));
  if ~isequal(old_names, new_names)
    equal = false;
    return;
  end
  equal = true;
  for idx = 1:length(old_names)
    old_item = old_hashes.(old_names{idx});
    new_item = new_hashes.(old_names{idx});
    if ~strcmp(old_item.path, new_item.path) || ...
        ~strcmp(old_item.sha256, new_item.sha256)
      equal = false;
      return;
    end
  end
end

function vector = LOCAL_repro_vector(results)
  vector = [];
  for idx = 1:length(results.projector_fingerprints)
    row = results.projector_fingerprints(idx);
    vector = [vector; row.rank; row.left_rows; row.left_cols; ...
      row.right_rows; row.right_cols; row.left_trace; row.right_trace; ...
      row.left_frobenius; row.right_frobenius; ...
      row.left_idempotence; row.right_idempotence; ...
      row.left_weighted_real; row.left_weighted_imag; ...
      row.right_weighted_real; row.right_weighted_imag]; %#ok<AGROW>
  end
  for idx = 1:length(results.singular_spectrum)
    row = results.singular_spectrum(idx);
    vector = [vector; row.k; row.m; row.n; row.index; row.sigma; ...
      row.sigma_over_sigma1; row.pinv_tol; row.rank_pinv; ...
      row.rank_ratio_1e8]; %#ok<AGROW>
  end
  for idx = 1:length(results.solver_comparison)
    row = results.solver_comparison(idx);
    vector = [vector; row.k; row.available; row.tolerance; row.rank; ...
      row.coefficient_norm; row.projected_residual; row.full_residual; ...
      row.full_system_backward; row.production_coefficient_error; ...
      row.production_proxy_field_error]; %#ok<AGROW>
  end
  for idx = 1:length(results.off_collocation)
    row = results.off_collocation(idx);
    vector = [vector; row.k; row.qp_value_residual; ...
      row.qp_derivative_residual; row.top_value_residual; ...
      row.top_derivative_residual; row.bottom_value_residual; ...
      row.bottom_derivative_residual; row.combined_residual]; %#ok<AGROW>
  end
  for idx = 1:length(results.resolution)
    row = results.resolution(idx);
    vector = [vector; row.k; row.base_rank; row.refined_rank; ...
      row.base_full_residual; row.refined_full_residual; ...
      row.base_off_residual; row.refined_off_residual; ...
      row.green_pot_diff; row.green_grad_diff; row.green_hess_diff]; %#ok<AGROW>
  end
  for idx = 1:length(results.downstream_mismatch)
    row = results.downstream_mismatch(idx);
    vector = [vector; row.k; row.relative_difference; row.rcond; ...
      row.solve_residual]; %#ok<AGROW>
  end
  for idx = 1:length(results.gates)
    row = results.gates(idx);
    vector = [vector; row.threshold; row.observed; row.pass; ...
      row.availability]; %#ok<AGROW>
  end
end

function value = LOCAL_source_hash(path)
  if exist(path, 'file') ~= 2
    value = 'MISSING';
    return;
  end
  command = sprintf('shasum -a 256 "%s"', strrep(path, '"', '\"'));
  [status, output] = system(command);
  if status ~= 0
    value = 'HASH_FAILED';
    return;
  end
  parts = strsplit(strtrim(output));
  value = parts{1};
end

function error_value = LOCAL_relmat(actual, expected)
  error_value = norm(actual - expected, 'fro') / ...
    max(1, norm(expected, 'fro'));
end

%% ==================== Deterministic outputs ====================
% These helpers serialize the complete diagnostic evidence bundle.

function LOCAL_write_outputs(results, output_dir)
  LOCAL_write_config(results, fullfile(output_dir, 'config.txt'));
  LOCAL_write_singular(results.singular_spectrum, ...
    fullfile(output_dir, 'singular-spectrum.csv'));
  LOCAL_write_solver(results.solver_comparison, ...
    fullfile(output_dir, 'solver-comparison.csv'));
  LOCAL_write_off(results.off_collocation, ...
    fullfile(output_dir, 'off-collocation.csv'));
  LOCAL_write_projectors(results.projector_fingerprints, ...
    fullfile(output_dir, 'projector-fingerprint.csv'));
  LOCAL_write_resolution(results.resolution, ...
    fullfile(output_dir, 'resolution.csv'));
  LOCAL_write_downstream(results.downstream_mismatch, ...
    fullfile(output_dir, 'downstream-mismatch.csv'));
  LOCAL_write_gates(results.gates, fullfile(output_dir, 'gate.csv'));
  LOCAL_write_report(results, fullfile(output_dir, 'report.md'));
  LOCAL_write_repro(results, fullfile(output_dir, 'reproducibility.txt'));
end

function LOCAL_write_config(results, path)
  fid = LOCAL_open(path);
  cfg = results.cfg;
  fprintf(fid, 'version=%s\n', cfg.version);
  fprintf(fid, 'status=%s\n', results.status);
  fprintf(fid, 'root_readiness=%s\n', results.root_readiness);
  fprintf(fid, 'root_readiness_sampled_discrete_go=%d\n', ...
    results.root_readiness_sampled_discrete_go);
  fprintf(fid, 'physical_root_ready=%s\n', results.physical_root_ready);
  fprintf(fid, 'primary_state=%s\n', results.primary_state);
  fprintf(fid, 'discarded_evidence=%s\n', cfg.discarded_evidence);
  fprintf(fid, 'k_nodes=%.17g,%.17g,%.17g\n', cfg.k_nodes);
  fprintf(fid, 'beta=%.17g\n', cfg.beta);
  fprintf(fid, 'd=%.17g\n', cfg.d);
  fprintf(fid, 'nref=%.17g\n', cfg.nref);
  fprintf(fid, 'base_proxy=40,40,24,8\n');
  fprintf(fid, 'refined_proxy=48,48,28,10\n');
  fprintf(fid, 'ratio_rank_threshold=%.17g\n', cfg.ratio_rank_threshold);
  fprintf(fid, 'mirrored_constructor_output_threshold=%.17g\n', ...
    cfg.constructor_tol);
  fprintf(fid, 'object_compatibility_threshold=%.17g\n', ...
    cfg.object_compatibility_tol);
  fprintf(fid, ['production_internal_A_b_identity=', ...
    'NOT_OBSERVABLE_WITH_CURRENT_INTERFACE\n']);
  fprintf(fid, 'source_manifest_scope=DIRECT_PROJECT_CALLS_ONLY\n');
  fprintf(fid, 'transitive_dependency_manifest=NOT_RELIABLY_ENUMERATED\n');
  fprintf(fid, 'command=%s\n', cfg.command);
  fprintf(fid, 'elapsed_seconds=%.17g\n', results.elapsed_seconds);
  names = sort(fieldnames(cfg.source_hashes));
  for idx = 1:length(names)
    item = cfg.source_hashes.(names{idx});
    fprintf(fid, 'source.%s.path=%s\n', names{idx}, item.path);
    fprintf(fid, 'source.%s.sha256=%s\n', names{idx}, item.sha256);
  end
  fclose(fid);
end

function LOCAL_write_projectors(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,rank,left_rows,left_cols,right_rows,right_cols,', ...
    'left_trace,right_trace,left_frobenius,right_frobenius,', ...
    'left_idempotence,right_idempotence,left_weighted_real,', ...
    'left_weighted_imag,right_weighted_real,right_weighted_imag,', ...
    'left_sha256,right_sha256\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, ['%s,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%s,%s\n'], ...
      r.config, r.rank, r.left_rows, r.left_cols, r.right_rows, ...
      r.right_cols, r.left_trace, r.right_trace, r.left_frobenius, ...
      r.right_frobenius, r.left_idempotence, r.right_idempotence, ...
      r.left_weighted_real, r.left_weighted_imag, ...
      r.right_weighted_real, r.right_weighted_imag, ...
      r.left_sha256, r.right_sha256);
  end
  fclose(fid);
end

function LOCAL_write_singular(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,k,m,n,index,sigma,sigma_over_sigma1,pinv_tol,', ...
    'rank_pinv,rank_ratio_1e8\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%s,%.17g,%d,%d,%d,%.17g,%.17g,%.17g,%d,%d\n', ...
      r.config, r.k, r.m, r.n, r.index, r.sigma, ...
      r.sigma_over_sigma1, r.pinv_tol, r.rank_pinv, r.rank_ratio_1e8);
  end
  fclose(fid);
end

function LOCAL_write_solver(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,k,solver,available,tolerance,rank,coefficient_norm,', ...
    'projected_residual,full_residual,full_system_backward,', ...
    'production_coefficient_error,production_proxy_field_error,status,note\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%s,%.17g,%s,%d,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%s,%s\n', ...
      r.config, r.k, r.solver, r.available, r.tolerance, r.rank, ...
      r.coefficient_norm, r.projected_residual, r.full_residual, ...
      r.full_system_backward, r.production_coefficient_error, ...
      r.production_proxy_field_error, r.status, LOCAL_csv_text(r.note));
  end
  fclose(fid);
end

function LOCAL_write_off(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,k,solver,point_set,qp_value_residual,', ...
    'qp_derivative_residual,top_value_residual,top_derivative_residual,', ...
    'bottom_value_residual,bottom_derivative_residual,combined_residual,status\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%s,%.17g,%s,%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%s\n', ...
      r.config, r.k, r.solver, r.point_set, r.qp_value_residual, ...
      r.qp_derivative_residual, r.top_value_residual, ...
      r.top_derivative_residual, r.bottom_value_residual, ...
      r.bottom_derivative_residual, r.combined_residual, r.status);
  end
  fclose(fid);
end

function LOCAL_write_resolution(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['k,base_solver,refined_solver,base_rank,refined_rank,', ...
    'base_full_residual,refined_full_residual,base_off_residual,', ...
    'refined_off_residual,coefficient_norms,green_pot_diff,', ...
    'green_grad_diff,green_hess_diff,status\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%.17g,%s,%s,%d,%d,%.17g,%.17g,%.17g,%.17g,%s,%.17g,%.17g,%.17g,%s\n', ...
      r.k, r.base_solver, r.refined_solver, r.base_rank, r.refined_rank, ...
      r.base_full_residual, r.refined_full_residual, ...
      r.base_off_residual, r.refined_off_residual, ...
      LOCAL_csv_text(r.coefficient_norms), r.green_pot_diff, ...
      r.green_grad_diff, r.green_hess_diff, r.status);
  end
  fclose(fid);
end

function LOCAL_write_downstream(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['k,geometry,quantity,solver_a,solver_b,relative_difference,', ...
    'rcond,solve_residual,status\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%.17g,%s,%s,%s,%s,%.17g,%.17g,%.17g,%s\n', ...
      r.k, r.geometry, r.quantity, r.solver_a, r.solver_b, ...
      r.relative_difference, r.rcond, r.solve_residual, r.status);
  end
  fclose(fid);
end

function LOCAL_write_gates(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, 'gate,threshold,observed,pass,availability,failure_reason\n');
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%s,%.17g,%.17g,%d,%d,%s\n', r.gate, r.threshold, ...
      r.observed, r.pass, r.availability, r.failure_reason);
  end
  fclose(fid);
end

function LOCAL_write_report(results, path)
  fid = LOCAL_open(path);
  prod = results.solver_comparison(strcmp( ...
    {results.solver_comparison.solver}, 'production_actual'));
  selected = results.solver_comparison(strcmp( ...
    {results.solver_comparison.solver}, 'ratio_rank_rseed'));
  downstream_max = max([results.downstream_mismatch.relative_difference]);
  off_selected = results.off_collocation(strcmp( ...
    {results.off_collocation.solver}, 'ratio_rank_rseed'));
  resolution_max = max([[results.resolution.green_pot_diff], ...
    [results.resolution.green_grad_diff], ...
    [results.resolution.green_hess_diff]]);
  coefficient_gate = results.gates(strcmp( ...
    {results.gates.gate}, ...
    'mirrored_constructor_coefficient_output_reproduction'));
  field_gate = results.gates(strcmp( ...
    {results.gates.gate}, ...
    'mirrored_constructor_proxy_field_output_reproduction'));
  residual_gate = results.gates(strcmp( ...
    {results.gates.gate}, ...
    'mirrored_constructor_residual_output_reproduction'));
  resolution_gate = results.gates(strcmp( ...
    {results.gates.gate}, 'object_compatibility_resolution'));
  downstream_gate = results.gates(strcmp( ...
    {results.gates.gate}, 'object_compatibility_downstream'));
  all_object_gate = results.gates(strcmp( ...
    {results.gates.gate}, 'object_compatibility_all'));

  fprintf(fid, '# Root-readiness early-stop proxy diagnostic\n\n');
  fprintf(fid, '- Diagnostic status: `%s`\n', results.status);
  fprintf(fid, '- Root readiness: `%s`\n', results.root_readiness);
  fprintf(fid, '- Sampled discrete GO: `%d`\n', ...
    results.root_readiness_sampled_discrete_go);
  fprintf(fid, '- Physical root ready: `%s`\n', results.physical_root_ready);
  fprintf(fid, '- Primary state: `%s`\n\n', results.primary_state);

  fprintf(fid, '## Scope\n\n');
  fprintf(fid, ['This experiment reconstructs and compares proxy solvers only. ', ...
    'Candidate scans, complex disks, Cauchy--Riemann checks, root counts, ', ...
    'Newton solves, eigenvalues, and estimators were not run.\n\n']);
  fprintf(fid, ['The earlier interactive pilot numbers are labeled ', ...
    '`%s` and are excluded from every gate.\n\n'], ...
    results.cfg.discarded_evidence);

  fprintf(fid, '## Production observations\n\n');
  for idx = 1:3
    fprintf(fid, ['- Base k=%.3f production full residual: `%.6e`; ', ...
      'coefficient norm: `%.6e`.\n'], prod(idx).k, ...
      prod(idx).full_residual, prod(idx).coefficient_norm);
  end
  fprintf(fid, ['\nThe production interface does not expose its internal ', ...
    'collocation matrix or right-hand side. Their entrywise or bytewise ', ...
    'identity with the mirrored constructor is therefore ', ...
    '`NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`; no such identity is ', ...
    'claimed.\n\n']);

  fprintf(fid, '## Seed-frozen ratio-rank diagnostic\n\n');
  fprintf(fid, ['- Selected ranks (base/refined): `%d/%d`.\n'], ...
    results.resolution(1).base_rank, results.resolution(1).refined_rank);
  fprintf(fid, ['- Maximum selected full residual: `%.6e`.\n'], ...
    max([selected.full_residual]));
  fprintf(fid, ['- Maximum selected off-collocation residual: `%.6e`.\n'], ...
    max([off_selected.combined_residual]));
  fprintf(fid, ['- Maximum downstream relative difference: `%.6e`.\n'], ...
    downstream_max);
  for idx = 1:length(results.projector_fingerprints)
    p = results.projector_fingerprints(idx);
    fprintf(fid, ['- `%s` projector rank `%d`; left SHA-256 `%s`; ', ...
      'right SHA-256 `%s`.\n'], p.config, p.rank, ...
      p.left_sha256, p.right_sha256);
  end
  fprintf(fid, '\n');

  fprintf(fid, '## Mirrored-constructor output verdict\n\n');
  fprintf(fid, ['These are output comparisons, not proof of internal ', ...
    'constructor identity. The three frozen `1e-11` checks are:\n\n']);
  fprintf(fid, ['- Coefficient-output relative error: `%.6e` ', ...
    '(threshold `%.1e`; pass `%d`; label `%s`).\n'], ...
    coefficient_gate.observed, coefficient_gate.threshold, ...
    coefficient_gate.pass, coefficient_gate.failure_reason);
  fprintf(fid, ['- Proxy-field-output relative error: `%.6e` ', ...
    '(threshold `%.1e`; pass `%d`).\n'], field_gate.observed, ...
    field_gate.threshold, field_gate.pass);
  fprintf(fid, ['- Residual-output difference: `%.6e` ', ...
    '(threshold `%.1e`; pass `%d`).\n\n'], residual_gate.observed, ...
    residual_gate.threshold, residual_gate.pass);

  fprintf(fid, '## Frozen object-compatibility gate\n\n');
  fprintf(fid, ['Every computed Green potential/gradient/Hessian, defect ', ...
    'and bulk `A_QP`, and scattering object has an individual `PASS` or ', ...
    '`FAIL` row against the frozen `1e-5` threshold.\n\n']);
  fprintf(fid, ['- Base/refined Green maximum: `%.6e`; pass `%d`.\n'], ...
    resolution_max, resolution_gate.pass);
  fprintf(fid, ['- Production/selected downstream maximum: `%.6e`; ', ...
    'pass `%d`.\n'], downstream_max, downstream_gate.pass);
  fprintf(fid, ['- Aggregate object compatibility: pass `%d`.\n\n'], ...
    all_object_gate.pass);

  fprintf(fid, '## Provenance boundary\n\n');
  fprintf(fid, ['The source manifest hashes the diagnostic, wrapper, design, ', ...
    'and every directly called project helper, including ', ...
    '`+geom/construct_cont.m`. It is intentionally labeled ', ...
    '`DIRECT_PROJECT_CALLS_ONLY`: transitive dependencies cannot be ', ...
    'reliably enumerated here without runtime instrumentation. The ', ...
    'diagnostic source SHA-256 is `%s`.\n\n'], ...
    results.cfg.source_hashes.diagnostic.sha256);

  fprintf(fid, '## Decision boundary\n\n');
  fprintf(fid, ['The frozen object-compatibility gate is enforced and may ', ...
    'pass independently. It cannot override the three failed observable ', ...
    'output-reproduction checks or the unavailable internal `A,b` ', ...
    'identity check.\n\n']);
  fprintf(fid, ['Therefore this experiment emits `PROXY_DIAGNOSTIC_COMPLETE`, ', ...
    '`ROOT_READINESS_SAMPLED_DISCRETE_GO=0`, and ', ...
    '`PHYSICAL_ROOT_READY=STOP`. No scan, disk, Cauchy--Riemann, root, ', ...
    'Newton, eigenvalue, or estimator stage was run.\n\n']);

  fprintf(fid, '## Reproducibility\n\n');
  fprintf(fid, '- Status: `%s`\n', results.reproducibility.status);
  fprintf(fid, '- Relative numeric difference: `%.6e`\n', ...
    results.reproducibility.relative_difference);
  fprintf(fid, '- Source manifest equal: `%d`\n', ...
    results.reproducibility.manifest_equal);
  fprintf(fid, '- Projector fingerprints equal: `%d`\n', ...
    results.reproducibility.projector_fingerprints_equal);
  fclose(fid);
end

function LOCAL_write_repro(results, path)
  fid = LOCAL_open(path);
  fprintf(fid, 'status=%s\n', results.reproducibility.status);
  fprintf(fid, 'pass=%d\n', results.reproducibility.pass);
  fprintf(fid, 'relative_difference=%.17g\n', ...
    results.reproducibility.relative_difference);
  fprintf(fid, 'tolerance=%.17g\n', results.reproducibility.tolerance);
  fprintf(fid, 'manifest_equal=%d\n', results.reproducibility.manifest_equal);
  fprintf(fid, 'projector_fingerprints_equal=%d\n', ...
    results.reproducibility.projector_fingerprints_equal);
  fclose(fid);
end

function fid = LOCAL_open(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('root_ready_diagnostic:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end

function value = LOCAL_csv_text(value)
  value = strrep(value, '"', '""');
  value = ['"', value, '"'];
end

function rows = LOCAL_empty_singular_rows()
  rows = struct('config', {}, 'k', {}, 'm', {}, 'n', {}, ...
    'index', {}, 'sigma', {}, 'sigma_over_sigma1', {}, ...
    'pinv_tol', {}, 'rank_pinv', {}, 'rank_ratio_1e8', {});
end

function rows = LOCAL_empty_solver_rows()
  rows = struct('config', {}, 'k', {}, 'solver', {}, ...
    'available', {}, 'tolerance', {}, 'rank', {}, ...
    'coefficient_norm', {}, 'projected_residual', {}, ...
    'full_residual', {}, 'full_system_backward', {}, ...
    'production_coefficient_error', {}, ...
    'production_proxy_field_error', {}, 'status', {}, 'note', {});
end

function rows = LOCAL_empty_off_rows()
  rows = struct('config', {}, 'k', {}, 'solver', {}, ...
    'point_set', {}, 'qp_value_residual', {}, ...
    'qp_derivative_residual', {}, 'top_value_residual', {}, ...
    'top_derivative_residual', {}, 'bottom_value_residual', {}, ...
    'bottom_derivative_residual', {}, 'combined_residual', {}, ...
    'status', {});
end

function rows = LOCAL_empty_evaluations()
  rows = struct('name', {}, 'available', {}, 'tolerance', {}, ...
    'rank', {}, 'coefficients', {}, 'coefficient_norm', {}, ...
    'projected_residual', {}, 'full_residual', {}, ...
    'full_system_backward', {}, 'production_coefficient_error', {}, ...
    'production_proxy_field_error', {}, 'factor_rcond', {}, ...
    'proxy', {}, 'field', {}, 'status', {}, 'note', {});
end
