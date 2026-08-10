function results = run_bie_pencil_diagnostic()
% RUN_BIE_PENCIL_DIAGNOSTIC Diagnose affine 0/infinity mode collapse.
%
% Purpose:
%   At one frozen sharp-disk sample, compare M = 10 and M = 5 using the
%   transmission-block singular values and homogeneous QZ pairs of the
%   scattering pencil.  This function diagnoses package output but does not
%   modify or replace any package routine.
%
% Output:
%   results - Transmission SVDs, numerical ranks, QZ alpha/beta data,
%             affine mode counts, and deterministic output paths.
%
% Main algorithm:
%   Construct the public one-cell scattering matrix and the pencil
%
%     A_sc = [-R_L, I; T_LR, 0],
%     B_sc = [0, T_RL; I, -R_R].
%
%   Record singular values of T_LR and T_RL, then classify homogeneous QZ
%   pairs without first dividing alpha by beta.
%
% Based on:
%   i4_bie_track.m, bloch.construct_S, and bloch.solve_modes.
%
% Main changes:
%   Preserve projective zero/infinite information discarded by the public
%   affine finite-eigenvalue filter.
%
% Numerical goal:
%   Determine whether the M = 10 count 32 = 21 + 11 is explained by a
%   ten-dimensional numerical transmission-rank loss, and whether M = 5
%   removes that high-order scale separation.

  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  addpath(repo_root);
  output_dir = fullfile(here, 'output', 'bie-pencil-diagnostic');
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

  config.model_id = 'sharp-disk-bie-pencil-diagnostic-v1';
  config.k = 1.85;
  config.s = 1;
  config.refractive_index = sqrt(1 + 16 * config.s);
  config.beta = 0.5;
  config.period_x = 1;
  config.period_y = 1;
  config.radius = 0.2;
  config.ntot = 60;
  config.M_values = [10, 5];
  config.qz_pair_tolerance = 1e-12;
  config.proxy.H = config.period_x / 2 + config.radius + 0.4;
  config.proxy.proxy_dist = 0.7;
  config.proxy.N_side = 60;
  config.proxy.N_top = 60;
  config.proxy.N_proxy_edge = 36;
  config.proxy.M_pw = 14;

  [C, curvelen, ~, ~] = geom.construct_cont(config.ntot, 'circle', ...
    0, 0, config.radius);
  geometry.C = C;
  geometry.curvelen = curvelen;
  cases = repmat(LOCAL_empty_case(), length(config.M_values), 1);

  % --- stage 2: M = 10 and M = 5 diagnostics ---

  for j = 1:length(config.M_values)
    M = config.M_values(j);
    fprintf('BIE pencil diagnostic: M = %d.\n', M);
    cases(j) = LOCAL_evaluate_M(config, geometry, M);
  end

  results.config = config;
  results.cases = cases;
  results.claim_scope = 'diagnostic-only-no-package-repair';
  results.elapsed_seconds = toc(start_token);
  results.output_dir = output_dir;

  % --- stage 3: independent evidence bundle ---

  LOCAL_write_summary(results, output_dir);
  LOCAL_write_singular_values(results, output_dir);
  LOCAL_write_qz_pairs(results, output_dir);
  LOCAL_write_report(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results');
  fprintf('Diagnostic completed in %.6f seconds.\n', ...
    results.elapsed_seconds);
end

%% ==================== One-M pencil diagnostic ====================
% These helpers construct one cell and preserve its projective QZ data.

function one = LOCAL_evaluate_M(config, geometry, M)
  kext = config.k;
  kint = config.refractive_index * kext;
  pars1.k = kext;
  pars1.beta = config.beta;
  pars1.d = config.period_y;
  pars1.periodic_axis = 'y';
  pars2 = config.proxy;
  proxy = kernel.precomp_proxy(pars1, pars2);
  channels = bloch.rayleigh_channels(kext, config.beta, ...
    config.period_y, M, config.period_x);
  S_cell = bloch.construct_S(geometry.C, kext, kint, pars1, proxy, ...
    geometry.curvelen, channels, -config.period_x / 2, ...
    config.period_x / 2);

  singular_lr = svd(S_cell.T_LR);
  singular_rl = svd(S_cell.T_RL);
  rank_tol_lr = LOCAL_rank_tolerance(S_cell.T_LR, singular_lr);
  rank_tol_rl = LOCAL_rank_tolerance(S_cell.T_RL, singular_rl);

  K = channels.K;
  I = eye(K);
  Z0 = zeros(K);
  A_sc = [-S_cell.R_L, I; S_cell.T_LR, Z0];
  B_sc = [Z0, S_cell.T_RL; I, -S_cell.R_R];
  [S_qz, T_qz] = qz(A_sc, B_sc, 'complex');
  alpha = diag(S_qz);
  beta_qz = diag(T_qz);
  qz = LOCAL_classify_qz(alpha, beta_qz, A_sc, B_sc, ...
    config.qz_pair_tolerance);

  mode_opts.lambda_tol = 1e-4;
  mode_opts.normalize = 'V';
  modes = bloch.solve_modes(S_cell, mode_opts);
  abs_lambda = abs(modes.lambda(:));

  one.M = M;
  one.K = K;
  one.phase_abs = abs(channels.phase(:));
  one.minimum_phase_abs = min(one.phase_abs);
  one.maximum_phase_abs = max(one.phase_abs);
  one.singular_values_T_LR = singular_lr;
  one.singular_values_T_RL = singular_rl;
  one.rank_tolerance_T_LR = rank_tol_lr;
  one.rank_tolerance_T_RL = rank_tol_rl;
  one.numerical_rank_T_LR = sum(singular_lr > rank_tol_lr);
  one.numerical_rank_T_RL = sum(singular_rl > rank_tol_rl);
  one.numerical_rank_A_sc = rank(A_sc);
  one.numerical_rank_B_sc = rank(B_sc);
  one.qz = qz;
  one.solve_modes_count = length(modes.lambda);
  one.solve_modes_raw_nonfinite_count = ...
    sum(~isfinite(modes.raw_lambda));
  one.count_right_decay = sum(abs_lambda < 1 - mode_opts.lambda_tol);
  one.count_left_decay = sum(abs_lambda > 1 + mode_opts.lambda_tol);
  one.count_neutral = sum(abs(abs_lambda - 1) <= mode_opts.lambda_tol);
  one.cell_solve_relative_residual = ...
    S_cell.solve_relative_residual_norm;
  one.expected_B_rank_from_T_RL = K + one.numerical_rank_T_RL;
  one.expected_A_rank_from_T_LR = K + one.numerical_rank_T_LR;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tolerance = LOCAL_rank_tolerance(A, singular_values)
  if isempty(singular_values)
    tolerance = 0;
    return;
  end
  tolerance = max(size(A)) * eps(max(singular_values(1), 1));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function qz = LOCAL_classify_qz(alpha, beta_qz, A_sc, B_sc, tolerance)
  pair_scale = abs(alpha) + abs(beta_qz);
  global_scale = tolerance * max([1, norm(A_sc, 'fro'), ...
    norm(B_sc, 'fro')]);
  indeterminate = pair_scale <= global_scale;
  relative_scale = max(abs(alpha), abs(beta_qz));
  infinite = ~indeterminate & abs(beta_qz) <= ...
    tolerance .* relative_scale;
  zero = ~indeterminate & ~infinite & abs(alpha) <= ...
    tolerance .* relative_scale;
  finite_nonzero = ~indeterminate & ~infinite & ~zero;
  affine_finite = ~indeterminate & ~infinite;

  classification = repmat({''}, length(alpha), 1);
  classification(indeterminate) = {'indeterminate'};
  classification(infinite) = {'infinite'};
  classification(zero) = {'zero'};
  classification(finite_nonzero) = {'finite-nonzero'};

  qz.alpha = alpha;
  qz.beta = beta_qz;
  qz.classification = classification;
  qz.zero_count = sum(zero);
  qz.infinite_count = sum(infinite);
  qz.finite_nonzero_count = sum(finite_nonzero);
  qz.affine_finite_count = sum(affine_finite);
  qz.indeterminate_count = sum(indeterminate);
  qz.exact_zero_alpha_count = sum(alpha == 0 & beta_qz ~= 0);
  qz.exact_zero_beta_count = sum(beta_qz == 0 & alpha ~= 0);
end

%% ==================== Deterministic outputs ====================
% These helpers write summaries, singular values, QZ pairs, and a report.

function LOCAL_write_summary(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'pencil-summary.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,k,s,beta,M,K,min_phase_abs,max_phase_abs,', ...
    'rank_T_LR,rank_T_RL,rank_tol_T_LR,rank_tol_T_RL,rank_A_sc,', ...
    'rank_B_sc,expected_A_rank_from_T_LR,expected_B_rank_from_T_RL,', ...
    'qz_zero,qz_infinite,qz_finite_nonzero,qz_affine_finite,', ...
    'qz_indeterminate,exact_zero_alpha,exact_zero_beta,', ...
    'solve_modes_count,raw_nonfinite_count,count_right_decay,', ...
    'count_left_decay,count_neutral,cell_solve_relative_residual\n']);
  for j = 1:length(results.cases)
    one = results.cases(j);
    fprintf(fid, ['%s,%.17g,%.17g,%.17g,%d,%d,%.17g,%.17g,%d,%d,', ...
      '%.17g,%.17g,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,', ...
      '%d,%d,%d,%.17g\n'], results.config.model_id, results.config.k, ...
      results.config.s, results.config.beta, one.M, one.K, ...
      one.minimum_phase_abs, one.maximum_phase_abs, ...
      one.numerical_rank_T_LR, one.numerical_rank_T_RL, ...
      one.rank_tolerance_T_LR, one.rank_tolerance_T_RL, ...
      one.numerical_rank_A_sc, one.numerical_rank_B_sc, ...
      one.expected_A_rank_from_T_LR, one.expected_B_rank_from_T_RL, ...
      one.qz.zero_count, one.qz.infinite_count, ...
      one.qz.finite_nonzero_count, one.qz.affine_finite_count, ...
      one.qz.indeterminate_count, one.qz.exact_zero_alpha_count, ...
      one.qz.exact_zero_beta_count, one.solve_modes_count, ...
      one.solve_modes_raw_nonfinite_count, one.count_right_decay, ...
      one.count_left_decay, one.count_neutral, ...
      one.cell_solve_relative_residual);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_singular_values(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'transmission-singular-values.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'model_id,M,K,block,index,singular_value,rank_tolerance,retained\n');
  for j = 1:length(results.cases)
    one = results.cases(j);
    LOCAL_write_singular_block(fid, results.config.model_id, one, ...
      'T_LR', one.singular_values_T_LR, one.rank_tolerance_T_LR);
    LOCAL_write_singular_block(fid, results.config.model_id, one, ...
      'T_RL', one.singular_values_T_RL, one.rank_tolerance_T_RL);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_singular_block(fid, model_id, one, block, values, tolerance)
  for j = 1:length(values)
    fprintf(fid, '%s,%d,%d,%s,%d,%.17g,%.17g,%d\n', ...
      model_id, one.M, one.K, block, j, values(j), tolerance, ...
      values(j) > tolerance);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_qz_pairs(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'qz-pairs.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,M,K,index,alpha_real,alpha_imag,alpha_abs,', ...
    'beta_real,beta_imag,beta_abs,classification\n']);
  for j = 1:length(results.cases)
    one = results.cases(j);
    for iqz = 1:length(one.qz.alpha)
      alpha = one.qz.alpha(iqz);
      beta_qz = one.qz.beta(iqz);
      fprintf(fid, '%s,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%s\n', ...
        results.config.model_id, one.M, one.K, iqz, real(alpha), ...
        imag(alpha), abs(alpha), real(beta_qz), imag(beta_qz), ...
        abs(beta_qz), one.qz.classification{iqz});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'report.md'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# Sharp-disk BIE pencil diagnostic\n\n');
  fprintf(fid, ['This is a single-point, diagnostic-only comparison. ', ...
    'It does not repair package mode extraction or assert a defect root.\n\n']);
  fprintf(fid, '- k=%.17g, s=%.17g, beta=%.17g\n', ...
    results.config.k, results.config.s, results.config.beta);
  fprintf(fid, '- QZ pair tolerance: %.3e\n', ...
    results.config.qz_pair_tolerance);
  for j = 1:length(results.cases)
    one = results.cases(j);
    fprintf(fid, ['- M=%d, K=%d: rank(T_LR)=%d, rank(T_RL)=%d, ', ...
      'QZ zero/infinite/finite-nonzero=%d/%d/%d, ', ...
      'affine finite=%d, solve_modes=%d, right/left/neutral=%d/%d/%d.\n'], ...
      one.M, one.K, one.numerical_rank_T_LR, ...
      one.numerical_rank_T_RL, one.qz.zero_count, ...
      one.qz.infinite_count, one.qz.finite_nonzero_count, ...
      one.qz.affine_finite_count, one.solve_modes_count, ...
      one.count_right_decay, one.count_left_decay, one.count_neutral);
  end
end

%% ==================== Schema and file helpers ====================
% These helpers initialize the stable result schema and checked files.

function one = LOCAL_empty_case()
  one = struct('M', [], 'K', [], 'phase_abs', [], ...
    'minimum_phase_abs', NaN, 'maximum_phase_abs', NaN, ...
    'singular_values_T_LR', [], 'singular_values_T_RL', [], ...
    'rank_tolerance_T_LR', NaN, 'rank_tolerance_T_RL', NaN, ...
    'numerical_rank_T_LR', NaN, 'numerical_rank_T_RL', NaN, ...
    'numerical_rank_A_sc', NaN, 'numerical_rank_B_sc', NaN, ...
    'qz', [], 'solve_modes_count', NaN, ...
    'solve_modes_raw_nonfinite_count', NaN, 'count_right_decay', NaN, ...
    'count_left_decay', NaN, 'count_neutral', NaN, ...
    'cell_solve_relative_residual', NaN, ...
    'expected_B_rank_from_T_RL', NaN, ...
    'expected_A_rank_from_T_LR', NaN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fid = LOCAL_open(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_bie_pencil_diagnostic:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end
