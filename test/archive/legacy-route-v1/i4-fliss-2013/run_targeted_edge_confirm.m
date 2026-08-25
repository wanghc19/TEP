function results = run_targeted_edge_confirm()
% RUN_TARGETED_EDGE_CONFIRM Confirm the strong-control adjacent band edges.
%
% Purpose:
%   Refine only the band-1 upper edge and band-2 lower edge near the
%   baseline extremizer for beta = 0.5 at N = 80 and N = 120.
%
% Output:
%   results - Sampled eigenvalues, residuals, edge estimates, uncertainty,
%             frozen safety gates, and output paths.
%
% Main algorithm:
%   Use eleven shared theta samples in a bounded periodic neighborhood of
%   theta = -pi.  Each sparse generalized eigenproblem returns the first two
%   bands, so each edge uses at most eleven EVP evaluations per N.  The
%   transformed Hermitian problem is
%
%     rho^(-1/2) * K(theta,beta) * rho^(-1/2) * w = lambda * w.
%
% Based on:
%   i4_fd_track.m and the completed baseline strong-control band scan.
%
% Main changes:
%   Restrict work to the two reference-adjacent edges and add N = 120.
%
% Numerical goal:
%   Check epsilon_80_120 <= 1e-3, where epsilon_80_120 is the maximum
%   of both spatial edge shifts and all four fine/coarse theta shifts.
%   Also check a conservative gap wider than 20*epsilon_80_120 and a
%   candidate distance greater than
%   10*epsilon_80_120, and normalized residual at most 1e-10.

  here = fileparts(mfilename('fullpath'));
  output_dir = fullfile(here, 'output', 'targeted-edge-confirm');
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
  rng(0, 'twister');

  % --- stage 1: frozen parameters ---

  config.model_id = 'fliss-smooth-fd-targeted-edge-v1';
  config.beta = 0.5;
  config.N_values = [80, 120];
  config.num_theta = 11;
  config.maximum_evp_per_edge_per_N = 12;
  config.baseline_theta_step = 2 * pi / 81;
  config.theta_center = -pi;
  config.theta_half_width = config.baseline_theta_step;
  config.lambda_candidate = 3.4609750440405129;
  config.epsilon_max = 1e-3;
  config.gap_factor = 20;
  config.margin_factor = 10;
  config.residual_max = 1e-10;
  config.eigs_tolerance = 1e-12;
  config.eigs_max_iterations = 2500;
  offsets = linspace(-config.theta_half_width, ...
    config.theta_half_width, config.num_theta).';
  config.theta = LOCAL_wrap_theta(config.theta_center + offsets);
  % Nested coarse subset: every other fine point plus the exact theta=-pi
  % center sample (index 6).  No additional EVP is evaluated.
  config.coarse_theta_indices = unique([1:2:config.num_theta, ...
    (config.num_theta + 1) / 2]);

  fprintf('Targeted strong-control edge confirmation\n');
  fprintf('beta = %.17g, theta samples per N = %d\n', ...
    config.beta, config.num_theta);

  % --- stage 2: N = 80 and N = 120 edge refinement ---

  runs = repmat(LOCAL_empty_run(), length(config.N_values), 1);
  for j = 1:length(config.N_values)
    N = config.N_values(j);
    fprintf('Solving N = %d targeted theta samples.\n', N);
    runs(j) = LOCAL_run_N(N, config);
  end

  % --- stage 3: frozen confirmation gates ---

  edge1 = [runs.band1_upper];
  edge2 = [runs.band2_lower];
  epsilon_edges = abs([edge1(2) - edge1(1), edge2(2) - edge2(1)]);
  eta_theta = [runs.eta_theta_band1_upper, ...
    runs.eta_theta_band2_lower];
  epsilon_components = [epsilon_edges, eta_theta];
  epsilon_80_120 = max(epsilon_components);
  safe_lower_edge = max(edge1) + epsilon_80_120;
  safe_upper_edge = min(edge2) - epsilon_80_120;
  safe_gap_width = safe_upper_edge - safe_lower_edge;
  candidate_distances = [config.lambda_candidate - safe_lower_edge, ...
    safe_upper_edge - config.lambda_candidate];
  candidate_margin = min(candidate_distances);
  maximum_residual = max([runs.maximum_normalized_residual]);

  gates.epsilon_pass = epsilon_80_120 <= config.epsilon_max;
  gates.safe_gap_width_pass = safe_gap_width > ...
    config.gap_factor * epsilon_80_120;
  gates.candidate_margin_pass = candidate_margin > ...
    config.margin_factor * epsilon_80_120;
  gates.residual_pass = maximum_residual <= config.residual_max;
  gates.pass = gates.epsilon_pass && gates.safe_gap_width_pass && ...
    gates.candidate_margin_pass && gates.residual_pass;

  results.config = config;
  results.runs = runs;
  results.epsilon_band1_upper = epsilon_edges(1);
  results.epsilon_band2_lower = epsilon_edges(2);
  results.eta_theta = eta_theta;
  results.epsilon_components = epsilon_components;
  results.epsilon_80_120 = epsilon_80_120;
  results.safe_lower_edge = safe_lower_edge;
  results.safe_upper_edge = safe_upper_edge;
  results.safe_gap_width = safe_gap_width;
  results.candidate_margin = candidate_margin;
  results.maximum_normalized_residual = maximum_residual;
  results.gates = gates;
  results.pass = gates.pass;
  results.elapsed_seconds = toc(start_token);
  results.output_dir = output_dir;

  % --- stage 4: independent evidence bundle ---

  LOCAL_write_samples(results, output_dir);
  LOCAL_write_summary(results, output_dir);
  LOCAL_write_report(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results');
  fprintf('PASS = %d; elapsed seconds = %.6f\n', ...
    results.pass, results.elapsed_seconds);
end

%% ==================== Sparse EVP evaluation ====================
% These helpers construct and solve the two-band perfect-cell problem.

function run = LOCAL_run_N(N, config)
  h = 1 / N;
  x = -0.5 + (0:N - 1).' * h;
  [X, Y] = ndgrid(x, x);
  rho = 1 + 16 * exp(-(X.^2 + Y.^2) / 0.2^2);
  invsqrt_rho = 1 ./ sqrt(rho(:));
  mass_scale = spdiags(invsqrt_rho, 0, N * N, N * N);
  Dy = LOCAL_qp_second_difference(N, h, config.beta);
  I = speye(N);
  samples = repmat(LOCAL_empty_sample(), length(config.theta), 1);

  for j = 1:length(config.theta)
    theta = config.theta(j);
    Dx = LOCAL_qp_second_difference(N, h, theta);
    K = kron(I, Dx) + kron(Dy, I);
    A = mass_scale * K * mass_scale;
    opts.issym = true;
    opts.isreal = false;
    opts.tol = config.eigs_tolerance;
    opts.maxit = config.eigs_max_iterations;
    opts.disp = 0;
    opts.v0 = ones(N * N, 1) / N;
    [W, D, flag] = eigs(A, 2, -1e-7, opts);
    lambda = real(diag(D));
    [lambda, order] = sort(lambda, 'ascend');
    W = W(:, order);

    residual = NaN(2, 1);
    for iband = 1:2
      u = invsqrt_rho .* W(:, iband);
      residual(iband) = LOCAL_evp_residual( ...
        K, rho(:), u, lambda(iband));
    end
    samples(j).theta = theta;
    samples(j).band1 = lambda(1);
    samples(j).band2 = lambda(2);
    samples(j).band1_residual = residual(1);
    samples(j).band2_residual = residual(2);
    samples(j).eigs_flag = flag;
  end

  [band1_upper, idx1] = max([samples.band1]);
  [band2_lower, idx2] = min([samples.band2]);
  coarse = samples(config.coarse_theta_indices);
  [coarse_band1_upper, coarse_idx1] = max([coarse.band1]);
  [coarse_band2_lower, coarse_idx2] = min([coarse.band2]);
  run.N = N;
  run.num_evp = length(samples);
  run.samples = samples;
  run.band1_upper = band1_upper;
  run.band1_theta = samples(idx1).theta;
  run.band2_lower = band2_lower;
  run.band2_theta = samples(idx2).theta;
  run.coarse_band1_upper = coarse_band1_upper;
  run.coarse_band1_theta = coarse(coarse_idx1).theta;
  run.coarse_band2_lower = coarse_band2_lower;
  run.coarse_band2_theta = coarse(coarse_idx2).theta;
  run.eta_theta_band1_upper = abs(band1_upper - coarse_band1_upper);
  run.eta_theta_band2_lower = abs(band2_lower - coarse_band2_lower);
  run.maximum_normalized_residual = max([ ...
    samples.band1_residual, samples.band2_residual]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function D = LOCAL_qp_second_difference(n, h, phase)
  e = ones(n, 1);
  D = spdiags([-e, 2 * e, -e], -1:1, n, n) / h^2;
  D(1, n) = -exp(-1i * phase) / h^2;
  D(n, 1) = -exp(1i * phase) / h^2;
  D = sparse(D);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_evp_residual(K, rho, u, lambda)
  Ku = K * u;
  Mu = rho(:) .* u;
  value = norm(Ku - lambda * Mu) / ...
    max(norm(Ku) + abs(lambda) * norm(Mu), eps);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function theta = LOCAL_wrap_theta(theta)
  theta = mod(theta + pi, 2 * pi) - pi;
end

%% ==================== Deterministic outputs ====================
% These helpers write the independent CSV and Markdown evidence.

function LOCAL_write_samples(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'edge-samples.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,N,evaluation_index,coarse_subset,theta,band1,band2,', ...
    'band1_normalized_residual,band2_normalized_residual,eigs_flag\n']);
  for irun = 1:length(results.runs)
    run = results.runs(irun);
    for j = 1:length(run.samples)
      sample = run.samples(j);
      is_coarse = any(results.config.coarse_theta_indices == j);
      fprintf(fid, '%s,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%d\n', ...
        results.config.model_id, run.N, j, is_coarse, sample.theta, sample.band1, ...
        sample.band2, sample.band1_residual, ...
        sample.band2_residual, sample.eigs_flag);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_summary(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'edge-summary.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['model_id,N80_band1_upper,N120_band1_upper,', ...
    'N80_band2_lower,N120_band2_lower,epsilon_band1_upper,', ...
    'epsilon_band2_lower,N80_coarse_band1_upper,N120_coarse_band1_upper,', ...
    'N80_coarse_band2_lower,N120_coarse_band2_lower,', ...
    'N80_eta_theta_band1_upper,N120_eta_theta_band1_upper,', ...
    'N80_eta_theta_band2_lower,N120_eta_theta_band2_lower,', ...
    'epsilon_80_120,epsilon_max,', ...
    'safe_lower_edge,safe_upper_edge,safe_gap_width,gap_factor,', ...
    'lambda_candidate,candidate_margin,margin_factor,', ...
    'maximum_normalized_residual,residual_max,epsilon_pass,', ...
    'safe_gap_width_pass,candidate_margin_pass,residual_pass,pass\n']);
  fprintf(fid, ['%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
    '%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
    '%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
    '%.17g,%.17g,%.17g,%d,%d,%d,%d,%d\n'], results.config.model_id, ...
    results.runs(1).band1_upper, results.runs(2).band1_upper, ...
    results.runs(1).band2_lower, results.runs(2).band2_lower, ...
    results.epsilon_band1_upper, results.epsilon_band2_lower, ...
    results.runs(1).coarse_band1_upper, ...
    results.runs(2).coarse_band1_upper, ...
    results.runs(1).coarse_band2_lower, ...
    results.runs(2).coarse_band2_lower, ...
    results.runs(1).eta_theta_band1_upper, ...
    results.runs(2).eta_theta_band1_upper, ...
    results.runs(1).eta_theta_band2_lower, ...
    results.runs(2).eta_theta_band2_lower, ...
    results.epsilon_80_120, results.config.epsilon_max, ...
    results.safe_lower_edge, results.safe_upper_edge, ...
    results.safe_gap_width, results.config.gap_factor, ...
    results.config.lambda_candidate, results.candidate_margin, ...
    results.config.margin_factor, results.maximum_normalized_residual, ...
    results.config.residual_max, results.gates.epsilon_pass, ...
    results.gates.safe_gap_width_pass, ...
    results.gates.candidate_margin_pass, results.gates.residual_pass, ...
    results.pass);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, output_dir)
  fid = LOCAL_open(fullfile(output_dir, 'report.md'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# Targeted strong-control edge confirmation\n\n');
  fprintf(fid, '- Model ID: `%s`\n', results.config.model_id);
  fprintf(fid, '- Beta: %.17g\n', results.config.beta);
  fprintf(fid, '- EVP evaluations per edge per N: %d (maximum %d)\n', ...
    results.config.num_theta, ...
    results.config.maximum_evp_per_edge_per_N);
  for j = 1:length(results.runs)
    run = results.runs(j);
    fprintf(fid, ['- N=%d: band-1 upper=%.17g at theta=%.17g; ', ...
      'band-2 lower=%.17g at theta=%.17g; ', ...
      'eta-theta upper/lower=%.3e/%.3e.\n'], run.N, ...
      run.band1_upper, run.band1_theta, run.band2_lower, run.band2_theta, ...
      run.eta_theta_band1_upper, run.eta_theta_band2_lower);
  end
  fprintf(fid, ['- Combined epsilon 80/120 (two spatial shifts and ', ...
    'four eta-theta shifts): %.6e (pass=%d)\n'], ...
    results.epsilon_80_120, results.gates.epsilon_pass);
  fprintf(fid, '- Conservative safe gap width: %.6e (pass=%d)\n', ...
    results.safe_gap_width, results.gates.safe_gap_width_pass);
  fprintf(fid, '- Candidate margin: %.6e (pass=%d)\n', ...
    results.candidate_margin, results.gates.candidate_margin_pass);
  fprintf(fid, '- Maximum normalized residual: %.6e (pass=%d)\n', ...
    results.maximum_normalized_residual, results.gates.residual_pass);
  fprintf(fid, '- Overall pass: `%d`\n', results.pass);
end

%% ==================== Schema and file helpers ====================
% These helpers initialize stable structs and checked output files.

function run = LOCAL_empty_run()
  run = struct('N', [], 'num_evp', [], 'samples', [], ...
    'band1_upper', NaN, 'band1_theta', NaN, ...
    'band2_lower', NaN, 'band2_theta', NaN, ...
    'coarse_band1_upper', NaN, 'coarse_band1_theta', NaN, ...
    'coarse_band2_lower', NaN, 'coarse_band2_theta', NaN, ...
    'eta_theta_band1_upper', NaN, 'eta_theta_band2_lower', NaN, ...
    'maximum_normalized_residual', NaN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sample = LOCAL_empty_sample()
  sample = struct('theta', NaN, 'band1', NaN, 'band2', NaN, ...
    'band1_residual', NaN, 'band2_residual', NaN, 'eigs_flag', NaN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fid = LOCAL_open(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_targeted_edge_confirm:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end
