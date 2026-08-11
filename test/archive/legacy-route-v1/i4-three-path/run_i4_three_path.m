function results = run_i4_three_path(mode)
%RUN_I4_THREE_PATH Run the reproducible I4 Ewald/MFS/Rayleigh experiment.
%
% Purpose:
%   Certify a test-local implementation of Linton's Eq. (2.65), measure a
%   low-cost three-path pilot, or run the frozen SLP-D coefficient ladder.
%
% Input:
%   mode - 'qualification', 'pilot', or 'slp'.  The full 'slp' mode is
%          intentionally separate because it is expensive and must not be
%          started before qualification and a pilot runtime estimate exist.
%
% Output:
%   results - Result bundle saved with portable CSV ledgers and a report.
%
% Main algorithm:
%   1. Qualify a local real/reciprocal Linton Ewald split against Tables 2--5,
%      independent refinements, a Rayleigh point sum, symmetries, and
%      deliberate sign/axis/phase mutations.
%   2. On one circle quadrature, evaluate the SLP-D field as
%        u(x) = - integral G(x,z) rho(z) ds(z)
%      by local Ewald (E), package MFS (P), and package far-field extraction
%      (R), then compare Fourier coefficients mode by mode on each wall.
%   3. Keep later SLP-N/DLP-D/DLP-N stages stopped unless SLP-D passes.
%
% Based on:
%   Linton (1998), Eq. (2.65), and the public package interfaces
%   kernel.qpgreen_mfs_pairmat and bloch.farfield_extractors.
%
% Main changes:
%   The Ewald implementation is entirely test-local, consumes Linton
%   separations (X,Y) = (dx_phys,dy_phys) directly, exposes its
%   reciprocal/real split, and never calls benchmark Ewald, package
%   Rayleigh-channel construction, or MFS internally.  The [y;x] swap is
%   confined to the package first-coordinate-periodic MFS wrapper.
%
% Numerical goal:
%   Produce an audit-ready per-path and per-mode ledger without silently
%   substituting one numerical path for another.

  if nargin < 1 || isempty(mode)
    mode = 'qualification';
  end
  if isstring(mode)
    mode = char(mode);
  end
  mode = lower(strtrim(mode));
  if ~any(strcmp(mode, {'qualification', 'pilot', 'slp'}))
    error('run_i4_three_path:InvalidMode', ...
      'mode must be ''qualification'', ''pilot'', or ''slp''.');
  end

  config = i4_three_path_config();
  addpath(config.repo_root);
  if LOCAL_is_octave() && isempty(which('Faddeeva_erfc'))
    addpath(fullfile(config.here, 'octave_compat'));
  end

  label = mode;
  if strcmp(mode, 'slp')
    fresh_qualification = run_i4_three_path('qualification');
    if ~strcmp(fresh_qualification.status, 'EWALD_REFERENCE_CERTIFIED')
      error('run_i4_three_path:EwaldReferenceUncertified', ...
        'Fresh qualification failed; refusing full SLP-D.');
    end
    label = 'canonical';
    LOCAL_require_qualification(config);
  end
  output_dir = fullfile(config.output_root, label);
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end

  log_path = fullfile(output_dir, 'run.log');
  log_fid = fopen(log_path, 'w');
  if log_fid < 0
    error('run_i4_three_path:LogOpenFailed', ...
      'Could not open %s.', log_path);
  end
  log_cleanup = onCleanup(@() fclose(log_fid));
  started = datestr(now, 31);
  LOCAL_log(log_fid, 'I4 three-path experiment\n');
  LOCAL_log(log_fid, 'mode=%s started=%s\n', mode, started);
  LOCAL_log(log_fid, 'coordinate_map=%s\n', config.coordinate_map);
  LOCAL_log(log_fid, 'time=%s project_free=%s Linton_free=%s\n', ...
    config.time_convention, config.free_project, config.free_linton);
  LOCAL_log(log_fid, 'Bloch=%s\n', config.bloch_translation);

  ledgers = LOCAL_empty_ledgers();
  total_token = tic;
  switch mode
    case 'qualification'
      [summary, ledgers] = LOCAL_run_qualification( ...
        config, ledgers, log_fid);
    case 'pilot'
      [summary, ledgers] = LOCAL_run_pilot( ...
        config, ledgers, log_fid, output_dir);
    case 'slp'
      [summary, ledgers] = LOCAL_run_slp( ...
        config, ledgers, log_fid);
  end
  total_seconds = toc(total_token);
  ledgers.timings.rows(end + 1, :) = {'total', total_seconds, ...
    'measured wall-clock time'};

  results = struct();
  results.mode = mode;
  results.label = label;
  results.started = started;
  results.finished = datestr(now, 31);
  results.total_seconds = total_seconds;
  results.status = summary.status;
  results.summary = summary;
  results.config = config;
  results.ledgers = ledgers;
  results.wood_distance = LOCAL_wood_distance(config.k, config.beta, config.d);
  results.clearance = config.clearance;
  results.conventions = struct('coordinate_map', config.coordinate_map, ...
    'time', config.time_convention, 'project_free', config.free_project, ...
    'linton_free', config.free_linton, 'project_pde', config.pde_project, ...
    'linton_pde', config.pde_linton, 'branch', config.branch_convention, ...
    'bloch_translation', config.bloch_translation, ...
    'slp_sign', 'u=-integral G rho ds; eta=[tau;-sigma]');

  LOCAL_write_all_ledgers(output_dir, ledgers);
  LOCAL_write_report(fullfile(output_dir, 'report.md'), results);
  save(fullfile(output_dir, 'results.mat'), 'results');
  LOCAL_log(log_fid, 'status=%s total_seconds=%.6f\n', ...
    results.status, total_seconds);
  LOCAL_log(log_fid, 'saved=%s\n', output_dir);
  clear log_cleanup;
end

%% ==================== Mode workflows ====================
% These helpers run the three externally visible experiment stages.

function [summary, ledgers] = LOCAL_run_qualification(config, ledgers, log_fid)
  LOCAL_log(log_fid, 'Stage 1: Linton Tables 2--5.\n');
  token = tic;
  [table_summary, ledgers] = LOCAL_qualify_linton_tables(config, ledgers);
  ledgers.timings.rows(end + 1, :) = {'linton_tables', toc(token), ...
    'five local-Ewald checkpoints'};

  LOCAL_log(log_fid, 'Stage 2: independent Ewald refinements and point paths.\n');
  token = tic;
  [ewald_summary, ledgers] = LOCAL_qualify_ewald(config, ledgers, log_fid);
  ledgers.timings.rows(end + 1, :) = {'ewald_qualification', toc(token), ...
    'axis, a, Rayleigh, symmetry, and point checks'};

  LOCAL_log(log_fid, 'Stage 3: pure Fourier projection oracle.\n');
  token = tic;
  [projection_summary, ledgers] = LOCAL_projection_oracle(config, ledgers, 64);
  ledgers.timings.rows(end + 1, :) = {'projection_oracle', toc(token), ...
    'finite exact Bloch sum'};

  gate_rows = { ...
    'linton_tables', table_summary.max_error, config.gate.linton_abs, ...
      table_summary.max_error <= config.gate.linton_abs, 1, ...
      'all five printed Linton values after project sign conversion'; ...
    'ewald_M1_change', ewald_summary.M1_change, ...
      config.gate.ewald_axis_change, ...
      ewald_summary.M1_change <= config.gate.ewald_axis_change, 1, ...
      'only M1 refined'; ...
    'ewald_M2_change', ewald_summary.M2_change, ...
      config.gate.ewald_axis_change, ...
      ewald_summary.M2_change <= config.gate.ewald_axis_change, 1, ...
      'only M2 refined'; ...
    'ewald_N_change', ewald_summary.N_change, ...
      config.gate.ewald_axis_change, ...
      ewald_summary.N_change <= config.gate.ewald_axis_change, 1, ...
      'only exponential-integral order refined'; ...
    'ewald_a_spread', ewald_summary.a_spread, ...
      config.gate.ewald_a_spread, ...
      ewald_summary.a_spread <= config.gate.ewald_a_spread, 1, ...
      'a=1.5,2,2.5 at joint truncation'; ...
    'ewald_vs_rayleigh_M96', ewald_summary.rayleigh_error, ...
      config.gate.ewald_rayleigh, ...
      ewald_summary.rayleigh_error <= config.gate.ewald_rayleigh, 1, ...
      'independent local Rayleigh point sum'; ...
    'quasiperiodic_translation', ewald_summary.translation_error, ...
      config.gate.translation, ...
      ewald_summary.translation_error <= config.gate.translation, 1, ...
      'target shift +d uses exp(+i beta d)'; ...
    'beta_reciprocity', ewald_summary.reciprocity_error, ...
      config.gate.reciprocity, ...
      ewald_summary.reciprocity_error <= config.gate.reciprocity, 1, ...
      'G_beta(X,Y)=G_-beta(-X,-Y)'; ...
    'pure_projection', projection_summary.max_error, ...
      config.gate.projection, ...
      projection_summary.max_error <= config.gate.projection, 1, ...
      'normalized Fourier projection'; ...
    'mutation_wrong_sign_detected', ewald_summary.wrong_sign_error, ...
      config.gate.linton_abs, ...
      ewald_summary.wrong_sign_error > config.gate.linton_abs, 1, ...
      'pass means the deliberate global-sign mutation fails'; ...
    'mutation_wrong_axis_detected', ewald_summary.wrong_axis_error, ...
      config.gate.linton_abs, ...
      ewald_summary.wrong_axis_error > config.gate.linton_abs, 1, ...
      'pass means the deliberate coordinate mutation fails'; ...
    'mutation_wrong_phase_detected', ewald_summary.wrong_phase_error, ...
      config.gate.linton_abs, ...
      ewald_summary.wrong_phase_error > config.gate.linton_abs, 1, ...
      'pass means the deliberate Bloch-phase mutation fails'; ...
    'mutation_translation_phase_detected', ...
      ewald_summary.wrong_translation_error, config.gate.translation, ...
      ewald_summary.wrong_translation_error > config.gate.translation, 1, ...
      'pass means exp(-i beta d) is rejected'};
  ledgers.gates.rows = [ledgers.gates.rows; gate_rows];
  mandatory = cell2mat(gate_rows(:, 5)) ~= 0;
  pass = cell2mat(gate_rows(:, 4)) ~= 0;
  all_pass = all(pass(mandatory));
  if all_pass
    status = 'EWALD_REFERENCE_CERTIFIED';
    classification = 'MINOR CAVEAT';
    note = 'Qualification certifies value-only Ewald and projection conventions.';
  else
    status = 'EWALD_REFERENCE_UNCERTIFIED';
    classification = 'BLOCKER';
    note = 'Full SLP-D is refused until every mandatory Ewald gate passes.';
  end
  ledgers.decision.rows(end + 1, :) = {'qualification', classification, ...
    status, all_pass, note};
  ledgers.decision.rows(end + 1, :) = {'SLP-N/DLP-D/DLP-N', ...
    'IMPORTANT CAVEAT', 'NOT_RUN_PREREQUISITE', 0, ...
    'Derivative layers are outside this qualification stage.'};
  summary = struct('status', status, 'all_mandatory_pass', all_pass, ...
    'table', table_summary, 'ewald', ewald_summary, ...
    'projection', projection_summary);
end

function [summary, ledgers] = LOCAL_run_pilot(config, ledgers, log_fid, output_dir)
  LOCAL_log(log_fid, ['Pilot only: ntot=%d Ny=%d M=%d; no scientific ', ...
    'verdict will be issued.\n'], config.pilot.ntot, config.pilot.Ny, ...
    config.pilot.M);
  token = tic;
  [path_data, wall_rows, timing_rows] = LOCAL_three_path_level(config, ...
    config.pilot.ntot, config.pilot.Ny, config.pilot.M, ...
    config.ewald.base, config.proxy.base, true, log_fid);
  ledgers.timings.rows = [ledgers.timings.rows; timing_rows];
  ledgers.timings.rows(end + 1, :) = {'pilot_three_path', toc(token), ...
    'includes proxy precomputation and both walls'};
  ledgers.wall.rows = [ledgers.wall.rows; wall_rows];
  ledgers = LOCAL_append_coefficients(config, ledgers, path_data, ...
    'pilot_base', false);
  [projection_summary, ledgers] = LOCAL_projection_oracle(config, ledgers, ...
    config.pilot.Ny);
  estimate = LOCAL_runtime_estimate(config, timing_rows);
  pairwise = LOCAL_pairwise_max(config, path_data);
  LOCAL_write_runtime_estimate(fullfile(output_dir, 'runtime-estimate.md'), ...
    config, estimate);
  ledgers.path_levels.rows(end + 1, :) = {'pilot', 'all', 'base', ...
    config.pilot.ntot, config.pilot.Ny, config.pilot.M, ...
    config.ewald.base.a, config.ewald.base.M1, config.ewald.base.M2, ...
    config.ewald.base.N, config.proxy.base.N_side, ...
    config.proxy.base.N_top, config.proxy.base.N_proxy_edge, ...
    config.proxy.base.M_pw, NaN, NaN, 0, ...
    'timing scale only; no frozen scientific gate'};
  ledgers.gates.rows(end + 1, :) = {'pilot_no_scientific_verdict', NaN, ...
    NaN, 1, 0, 'pilot measurements are not acceptance evidence'};
  ledgers.decision.rows(end + 1, :) = {'pilot', 'IMPORTANT CAVEAT', ...
    'PILOT_TIMING_ONLY', 1, ...
    'Use the estimate before any full SLP-D wall evaluation.'};
  ledgers.decision.rows(end + 1, :) = {'pilot_triangle_observation', ...
    'IMPORTANT CAVEAT', 'TIMING_ONLY_TRIANGLE_OBSERVATION', 0, ...
    sprintf(['E-P=%.3e, E-R=%.3e, P-R=%.3e; E-R closes while ', ...
      'base P differs, but pilot resolution cannot certify a path.'], ...
      pairwise(1), pairwise(2), pairwise(3))};
  ledgers.decision.rows(end + 1, :) = {'SLP-N/DLP-D/DLP-N', ...
    'IMPORTANT CAVEAT', 'NOT_RUN_PREREQUISITE', 0, ...
    'Derivative layers remain stopped.'};
  summary = struct('status', 'PILOT_TIMING_ONLY', ...
    'projection', projection_summary, 'runtime_estimate', estimate, ...
    'pairwise_max', pairwise, 'path_data', path_data);
end

function [summary, ledgers] = LOCAL_run_slp(config, ledgers, log_fid)
  LOCAL_log(log_fid, ['Full SLP-D mode authorized by caller.  This mode ', ...
    'runs the frozen refinement ladder.\n']);
  [summary, ledgers] = LOCAL_full_slp_ladder(config, ledgers, log_fid);
end

%% ==================== Ewald qualification ====================
% These helpers certify the local Eq. (2.65) implementation without MFS.

function [summary, ledgers] = LOCAL_qualify_linton_tables(config, ledgers)
  errors = zeros(length(config.linton), 1);
  mfs_errors = zeros(length(config.linton), 1);
  for j = 1:length(config.linton)
    c = config.linton(j);
    [linton_value, reciprocal, real_space] = LOCAL_linton_ewald( ...
      c.k, c.beta, c.d, c.X, c.Y, config.ewald.joint, +1);
    project_value = -linton_value;
    signed_for_linton = -project_value;
    errors(j) = abs(signed_for_linton - c.reference);

    % Compare the package MFS path at the identical physical Linton point.
    % Linton (X,Y) maps to physical (x,y); the y-periodic package wrapper
    % performs its own internal [y;x] swap.
    pars1 = struct('k', c.k, 'beta', c.beta, 'd', c.d, ...
      'periodic_axis', 'y');
    token = tic;
    proxy = kernel.precomp_proxy(pars1, config.proxy.base);
    mfs_data = kernel.qpgreen_mfs([0; 0], [c.X; c.Y], pars1, proxy);
    mfs_seconds = toc(token);
    mfs_value = mfs_data.pot(1);
    mfs_errors(j) = abs(mfs_value - project_value);
    ledgers.timings.rows(end + 1, :) = { ...
      ['linton_mfs_', c.label], mfs_seconds, ...
      'package y-periodic MFS at the identical Linton point'};

    ledgers.ewald_tables.rows(end + 1, :) = {c.label, c.k * c.d, ...
      c.beta * c.d, c.X / c.d, c.Y / c.d, real(c.reference), ...
      imag(c.reference), real(project_value), imag(project_value), ...
      real(signed_for_linton), imag(signed_for_linton), ...
      real(reciprocal), imag(reciprocal), real(real_space), ...
      imag(real_space), real(mfs_value), imag(mfs_value), ...
      mfs_errors(j), errors(j), config.gate.linton_abs, ...
      errors(j) <= config.gate.linton_abs};
  end
  summary.max_error = max(errors);
  summary.errors = errors;
  summary.mfs_max_error = max(mfs_errors);
  summary.mfs_errors = mfs_errors;
end

function [summary, ledgers] = LOCAL_qualify_ewald(config, ledgers, log_fid)
  npoint = length(config.points);
  base = zeros(npoint, 1);
  joint = zeros(npoint, 1);
  M1_value = zeros(npoint, 1);
  M2_value = zeros(npoint, 1);
  N_value = zeros(npoint, 1);
  rayleigh = zeros(npoint, 1);
  a_values = zeros(npoint, length(config.ewald.a_values));
  pars1 = struct('k', config.k, 'beta', config.beta, 'd', config.d, ...
    'periodic_axis', 'y');

  % MFS is evaluated only as a reported third point path, never as Ewald.
  LOCAL_log(log_fid, '  package proxy base precomputation for point ledger ...\n');
  token = tic;
  proxy = kernel.precomp_proxy(pars1, config.proxy.base);
  proxy_seconds = toc(token);
  ledgers.timings.rows(end + 1, :) = {'qualification_proxy_precomp', ...
    proxy_seconds, 'package MFS point diagnostic only'};

  for j = 1:npoint
    point = config.points(j);
    X = point.dx_transverse;
    Y = point.dy_periodic;
    base(j) = LOCAL_project_ewald(config.k, config.beta, config.d, ...
      X, Y, config.ewald.base);
    M1_value(j) = LOCAL_project_ewald(config.k, config.beta, config.d, ...
      X, Y, config.ewald.M1);
    M2_value(j) = LOCAL_project_ewald(config.k, config.beta, config.d, ...
      X, Y, config.ewald.M2);
    N_value(j) = LOCAL_project_ewald(config.k, config.beta, config.d, ...
      X, Y, config.ewald.N);
    joint(j) = LOCAL_project_ewald(config.k, config.beta, config.d, ...
      X, Y, config.ewald.joint);
    rayleigh(j) = LOCAL_rayleigh_point(config.k, config.beta, config.d, ...
      X, Y, config.qualification_rayleigh_M);
    for ia = 1:length(config.ewald.a_values)
      level = config.ewald.joint;
      level.a = config.ewald.a_values(ia);
      a_values(j, ia) = LOCAL_project_ewald(config.k, config.beta, ...
        config.d, X, Y, level);
    end

    levels = {'base', 'M1', 'M2', 'N', 'joint'};
    level_config = {config.ewald.base, config.ewald.M1, ...
      config.ewald.M2, config.ewald.N, config.ewald.joint};
    values = [base(j), M1_value(j), M2_value(j), N_value(j), joint(j)];
    for il = 1:length(levels)
      q = level_config{il};
      ledgers.ewald_convergence.rows(end + 1, :) = {point.label, ...
        levels{il}, q.a, q.M1, q.M2, q.N, real(values(il)), ...
        imag(values(il)), abs(values(il) - base(j)), ...
        point.is_holdout, 'single-axis and joint truncation ledger'};
    end
    for ia = 1:length(config.ewald.a_values)
      q = config.ewald.joint;
      q.a = config.ewald.a_values(ia);
      ledgers.ewald_convergence.rows(end + 1, :) = {point.label, ...
        sprintf('a_%.1f', q.a), q.a, q.M1, q.M2, q.N, ...
        real(a_values(j, ia)), imag(a_values(j, ia)), ...
        abs(a_values(j, ia) - joint(j)), point.is_holdout, ...
        'a sweep at joint truncation'};
    end

    src = [0; 0];
    trg = [X; Y];
    token = tic;
    mfs = kernel.qpgreen_mfs(src, trg, pars1, proxy);
    point_mfs_seconds = toc(token);
    ewald_rayleigh = abs(joint(j) - rayleigh(j));
    ewald_mfs = abs(joint(j) - mfs.pot);
    mfs_rayleigh = abs(mfs.pot - rayleigh(j));
    ledgers.point_values.rows(end + 1, :) = {point.label, ...
      point.is_holdout, X, Y, real(base(j)), imag(base(j)), ...
      real(joint(j)), imag(joint(j)), real(mfs.pot), imag(mfs.pot), ...
      real(rayleigh(j)), imag(rayleigh(j)), ewald_mfs, ...
      ewald_rayleigh, mfs_rayleigh, abs(joint(j) - base(j)), ...
      point_mfs_seconds};
  end

  summary.M1_change = max(abs(M1_value - base));
  summary.M2_change = max(abs(M2_value - base));
  summary.N_change = max(abs(N_value - base));
  spread = zeros(npoint, 1);
  for j = 1:npoint
    spread(j) = max(max(abs(a_values(j, :) - a_values(j, :).')));
  end
  summary.a_spread = max(spread);
  summary.rayleigh_error = max(abs(joint - rayleigh));

  % Quasi-periodic translation and beta reciprocity use independent calls.
  X = config.points(4).dx_transverse;
  Y = config.points(4).dy_periodic;
  base_sym = LOCAL_project_ewald(config.k, config.beta, config.d, X, Y, ...
    config.ewald.joint);
  translated = LOCAL_project_ewald(config.k, config.beta, config.d, ...
    X, Y + config.d, config.ewald.joint);
  expected_translation = exp(1i * config.beta * config.d) * base_sym;
  summary.translation_error = abs(translated - expected_translation);
  reverse_beta = LOCAL_project_ewald(config.k, -config.beta, config.d, ...
    -X, -Y, config.ewald.joint);
  summary.reciprocity_error = abs(base_sym - reverse_beta);

  % Deliberate mutations must be separated from production branch helpers.
  c = config.linton(1);
  project_table = LOCAL_project_ewald(c.k, c.beta, c.d, c.X, c.Y, ...
    config.ewald.joint);
  summary.wrong_sign_error = abs(project_table - c.reference);
  wrong_axis_project = LOCAL_project_ewald(c.k, c.beta, c.d, c.Y, c.X, ...
    config.ewald.joint);
  summary.wrong_axis_error = abs(-wrong_axis_project - c.reference);
  [wrong_phase_linton, ~, ~] = LOCAL_linton_ewald(c.k, c.beta, c.d, ...
    c.X, c.Y, config.ewald.joint, -1);
  summary.wrong_phase_error = abs(wrong_phase_linton - c.reference);
  wrong_expected = exp(-1i * config.beta * config.d) * base_sym;
  summary.wrong_translation_error = abs(translated - wrong_expected);

  ledgers.ewald_convergence.rows(end + 1, :) = {'symmetry_holdout', ...
    'translation', config.ewald.joint.a, config.ewald.joint.M1, ...
    config.ewald.joint.M2, config.ewald.joint.N, real(translated), ...
    imag(translated), summary.translation_error, true, ...
    'G(y+d) versus exp(+i beta d)G(y)'};
  ledgers.ewald_convergence.rows(end + 1, :) = {'symmetry_holdout', ...
    'beta_reciprocity', config.ewald.joint.a, config.ewald.joint.M1, ...
    config.ewald.joint.M2, config.ewald.joint.N, real(reverse_beta), ...
    imag(reverse_beta), summary.reciprocity_error, true, ...
    'G_beta(X,Y) versus G_-beta(-X,-Y)'};
end

function [summary, ledgers] = LOCAL_projection_oracle(config, ledgers, Ny)
  M = min(12, floor((Ny - 1) / 2));
  m = (-M:M).';
  beta_m = config.beta + 2 * pi * m / config.d;
  y = config.d * (0:Ny - 1) / Ny;
  exact = (0.19 - 0.07i) * exp((0.11 + 0.03i) * m);
  psi = (1 / sqrt(config.d)) * exp(1i * (beta_m * y));
  u = exact.' * psi;
  observed = LOCAL_fourier_project(config.d, beta_m, y, u);
  errors = abs(observed - exact);
  for j = 1:length(m)
    ledgers.projection.rows(end + 1, :) = {Ny, m(j), ...
      real(exact(j)), imag(exact(j)), real(observed(j)), ...
      imag(observed(j)), errors(j), config.gate.projection, ...
      errors(j) <= config.gate.projection};
  end
  summary.max_error = max(errors);
end

%% ==================== Local Linton and Rayleigh kernels ====================
% These independent helpers define branches and phase signs in one place.

function value = LOCAL_project_ewald(k, beta, d, X, Y, level)
  [linton_value, ~, ~] = LOCAL_linton_ewald(k, beta, d, X, Y, level, +1);
  value = -linton_value;
end

function [value, reciprocal, real_space] = LOCAL_linton_ewald( ...
    k, beta, d, X, Y, level, phase_sign)
  % Linton Eq. (2.65): G_L = G_reciprocal + G_real, with source +delta.
  X = abs(X);
  m1 = -level.M1:level.M1;
  beta_m = beta + 2 * pi * m1 / d;
  q_m = LOCAL_linton_branch(k, beta_m);
  arg_plus = q_m * d / (2 * level.a) + level.a * X / d;
  arg_minus = q_m * d / (2 * level.a) - level.a * X / d;
  bracket = exp(q_m * X) .* LOCAL_complex_erfc(arg_plus) + ...
    exp(-q_m * X) .* LOCAL_complex_erfc(arg_minus);
  phase = exp(phase_sign * 1i * beta_m * Y);
  reciprocal = -(1 / (4 * d)) * sum(phase .* bracket ./ q_m);

  m2 = -level.M2:level.M2;
  image_r = sqrt(X .^ 2 + (Y - m2 * d) .^ 2);
  singular_tol = max(1e-14, 10 * eps(max(1, abs(d))));
  if min(image_r) <= singular_tol
    value = NaN;
    reciprocal = NaN;
    real_space = NaN;
    return;
  end
  z = (level.a * image_r / d) .^ 2;
  exp_neg_z = exp(-z);
  En_current = expint(z);
  series = zeros(size(z));
  for n = 0:level.N
    coefficient = (k * d / (2 * level.a)) ^ (2 * n) / factorial(n);
    series = series + coefficient * En_current;
    if n < level.N
      En_current = (exp_neg_z - z .* En_current) / (n + 1);
    end
  end
  image_phase = exp(phase_sign * 1i * beta * m2 * d);
  real_space = -(1 / (4 * pi)) * sum(image_phase .* series);
  value = reciprocal + real_space;
end

function q_m = LOCAL_linton_branch(k, beta_m)
  q_m = zeros(size(beta_m));
  difference = beta_m .^ 2 - k ^ 2;
  evanescent = difference >= 0;
  propagating = ~evanescent;
  q_m(evanescent) = sqrt(difference(evanescent));
  q_m(propagating) = -1i * sqrt(-difference(propagating));
end

function gamma_m = LOCAL_rayleigh_branch(k, beta_m)
  gamma_m = sqrt(k ^ 2 - beta_m .^ 2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);
  real_negative = abs(imag(gamma_m)) <= 10 * eps & real(gamma_m) < 0;
  gamma_m(real_negative) = -gamma_m(real_negative);
end

function value = LOCAL_rayleigh_point(k, beta, d, X, Y, M)
  m = (-M:M).';
  beta_m = beta + 2 * pi * m / d;
  gamma_m = LOCAL_rayleigh_branch(k, beta_m);
  value = (1i / (2 * d)) * sum(exp(1i * beta_m * Y) .* ...
    exp(1i * gamma_m * abs(X)) ./ gamma_m);
end

function values = LOCAL_project_ewald_matrix( ...
    config, source, target, level)
  ns = size(source, 2);
  nt = size(target, 2);
  X = bsxfun(@minus, target(1, :).', source(1, :));
  Y = bsxfun(@minus, target(2, :).', source(2, :));
  X_flat = X(:).';
  Y_flat = Y(:).';
  values_flat = zeros(size(X_flat));
  chunk_size = 4096;
  for first = 1:chunk_size:length(X_flat)
    last = min(length(X_flat), first + chunk_size - 1);
    index = first:last;
    values_flat(index) = LOCAL_project_ewald_vector(config.k, ...
      config.beta, config.d, X_flat(index), Y_flat(index), level);
  end
  values = reshape(values_flat, nt, ns);
end

function values = LOCAL_project_ewald_vector(k, beta, d, X, Y, level)
  % Vectorized Eq. (2.65) for a chunk of nonsingular target-source pairs.
  X = abs(X(:).');
  Y = Y(:).';
  m1 = (-level.M1:level.M1).';
  beta_m = beta + 2 * pi * m1 / d;
  q_m = LOCAL_linton_branch(k, beta_m);
  arg_plus = bsxfun(@plus, q_m * d / (2 * level.a), ...
    level.a * X / d);
  arg_minus = bsxfun(@minus, q_m * d / (2 * level.a), ...
    level.a * X / d);
  exponential_plus = exp(bsxfun(@times, q_m, X));
  exponential_minus = exp(bsxfun(@times, -q_m, X));
  bracket = exponential_plus .* LOCAL_complex_erfc(arg_plus) + ...
    exponential_minus .* LOCAL_complex_erfc(arg_minus);
  phase = exp(1i * bsxfun(@times, beta_m, Y));
  reciprocal = -(1 / (4 * d)) * sum(bsxfun(@rdivide, ...
    phase .* bracket, q_m), 1);

  m2 = (-level.M2:level.M2).';
  image_Y = bsxfun(@minus, Y, m2 * d);
  image_r = sqrt(bsxfun(@plus, X .^ 2, image_Y .^ 2));
  singular_tol = max(1e-14, 10 * eps(max(1, abs(d))));
  if any(min(image_r, [], 1) <= singular_tol)
    error('run_i4_three_path:SingularEwaldPair', ...
      'A wall Ewald chunk contains a singular source-image pair.');
  end
  z = (level.a * image_r / d) .^ 2;
  exp_neg_z = exp(-z);
  En_current = expint(z);
  series = zeros(size(z));
  for n = 0:level.N
    coefficient = (k * d / (2 * level.a)) ^ (2 * n) / factorial(n);
    series = series + coefficient * En_current;
    if n < level.N
      En_current = (exp_neg_z - z .* En_current) / (n + 1);
    end
  end
  image_phase = exp(1i * beta * m2 * d);
  real_space = -(1 / (4 * pi)) * sum(bsxfun(@times, ...
    image_phase, series), 1);
  values = -(reciprocal + real_space);
end

function values = LOCAL_complex_erfc(z)
  if ~isempty(which('Faddeeva_erfc'))
    values = Faddeeva_erfc(z);
  else
    values = erfc(z);
  end
end

%% ==================== Three-path SLP-D evaluation ====================
% These helpers reuse exactly one circle quadrature and one wall grid.

function [data, wall_rows, timing_rows] = LOCAL_three_path_level( ...
    config, ntot, Ny, M, ewald_level, proxy_level, keep_wall_rows, ...
    log_fid, path_selector)
  if nargin < 9
    path_selector = 'all';
  end
  run_E = strcmp(path_selector, 'all') || strcmp(path_selector, 'E');
  run_P = strcmp(path_selector, 'all') || strcmp(path_selector, 'P');
  [circle, source, weights] = LOCAL_circle_geometry(config, ntot);
  y_wall = config.d * (0:Ny - 1) / Ny;
  targets = { ...
    [config.X_L * ones(1, Ny); y_wall], ...
    [config.X_R * ones(1, Ny); y_wall]};
  sides = {'L', 'R'};
  channels = LOCAL_channels(config, M);
  densities = config.density;
  timing_rows = cell(0, 3);

  pars1 = struct('k', config.k, 'beta', config.beta, 'd', config.d, ...
    'periodic_axis', 'y');
  if run_P
    LOCAL_log(log_fid, '  proxy precomputation (%d,%d,%d,%d) ...\n', ...
      proxy_level.N_side, proxy_level.N_top, ...
      proxy_level.N_proxy_edge, proxy_level.M_pw);
    token = tic;
    proxy = kernel.precomp_proxy(pars1, proxy_level);
    timing_rows(end + 1, :) = {'proxy_precomp', toc(token), ...
      'package kernel.precomp_proxy'};
  end

  ewald_matrix = cell(1, 2);
  mfs_matrix = cell(1, 2);
  for is = 1:2
    if run_E
      LOCAL_log(log_fid, '  Ewald wall matrix side=%s ntot=%d Ny=%d ...\n', ...
        sides{is}, ntot, Ny);
      token = tic;
      ewald_matrix{is} = LOCAL_project_ewald_matrix( ...
        config, source, targets{is}, ewald_level);
      timing_rows(end + 1, :) = {['ewald_wall_', sides{is}], toc(token), ...
        sprintf('%d source-target interactions', ntot * Ny)};
    end
    if run_P
      LOCAL_log(log_fid, '  MFS wall matrix side=%s ntot=%d Ny=%d ...\n', ...
        sides{is}, ntot, Ny);
      token = tic;
      [mfs_matrix{is}, ~, ~, ~, ~, ~] = ...
        kernel.qpgreen_mfs_pairmat(source, targets{is}, pars1, proxy);
      timing_rows(end + 1, :) = {['mfs_wall_', sides{is}], toc(token), ...
        sprintf('%d source-target interactions', ntot * Ny)};
    end
  end

  [F_L, F_R] = bloch.farfield_extractors(circle, channels, ...
    config.X_L, config.X_R, 2 * pi);
  extractors = {F_L, F_R};
  wall_rows = cell(0, 13);
  for id = 1:length(densities)
    density = LOCAL_density_values(densities(id), ntot);
    weighted_density = density .* weights;
    eta = [zeros(ntot, 1); density];
    for is = 1:2
      R_coeff = extractors{is} * eta;
      data.(densities(id).label).(sides{is}).R = R_coeff;
      if run_E
        E_wall = -ewald_matrix{is} * weighted_density;
        E_coeff = LOCAL_fourier_project(config.d, channels.beta_m, ...
          y_wall, E_wall.');
        data.(densities(id).label).(sides{is}).E = E_coeff;
        data.(densities(id).label).(sides{is}).E_wall = E_wall;
      end
      if run_P
        P_wall = -mfs_matrix{is} * weighted_density;
        P_coeff = LOCAL_fourier_project(config.d, channels.beta_m, ...
          y_wall, P_wall.');
        data.(densities(id).label).(sides{is}).P = P_coeff;
        data.(densities(id).label).(sides{is}).P_wall = P_wall;
      end
      if keep_wall_rows && run_E && run_P
        for jy = 1:Ny
          wall_rows(end + 1, :) = {densities(id).label, sides{is}, ...
            jy, y_wall(jy), real(E_wall(jy)), imag(E_wall(jy)), ...
            real(P_wall(jy)), imag(P_wall(jy)), ...
            abs(E_wall(jy) - P_wall(jy)), ntot, Ny, ...
            ewald_level.M1, proxy_level.N_proxy_edge};
        end
      end
    end
  end
  data.channels = channels;
  data.ntot = ntot;
  data.Ny = Ny;
  data.M = M;
  data.ewald_level = ewald_level;
  data.proxy_level = proxy_level;
end

function ledgers = LOCAL_append_coefficients( ...
    config, ledgers, data, level_label, enforce_gate)
  density_labels = {config.density.label};
  sides = {'L', 'R'};
  pairs = {'E', 'P'; 'E', 'R'; 'P', 'R'};
  channels = data.channels;
  reference_scale = 0;
  for id = 1:length(density_labels)
    for is = 1:2
      values = data.(density_labels{id}).(sides{is});
      reference_scale = max(reference_scale, ...
        max(abs([values.E(:); values.P(:); values.R(:)])));
    end
  end
  floor_value = max(config.relative_floor_abs, ...
    config.relative_floor_scale * reference_scale);
  for id = 1:length(density_labels)
    density_label = density_labels{id};
    for is = 1:2
      side = sides{is};
      values = data.(density_label).(side);
      for im = 1:channels.K
        for ip = 1:size(pairs, 1)
          left_path = pairs{ip, 1};
          right_path = pairs{ip, 2};
          left = values.(left_path)(im);
          right = values.(right_path)(im);
          abs_error = abs(left - right);
          floor_relative = abs_error / max(floor_value, abs(right));
          pass = abs_error <= config.gate.coefficient_abs;
          ledgers.coefficients.rows(end + 1, :) = {level_label, ...
            density_label, 'SLP', side, 'D', channels.m(im), ...
            left_path, right_path, real(left), imag(left), real(right), ...
            imag(right), abs_error, floor_relative, floor_value, ...
            config.gate.coefficient_abs, pass, enforce_gate};
        end
      end
    end
  end
end

function [summary, ledgers] = LOCAL_full_slp_ladder(config, ledgers, log_fid)
  M = max(config.rayleigh_M);
  ewald_labels = config.slp.ewald_labels;
  ewald_levels = {config.ewald.base, config.ewald.wall_a, ...
    config.ewald.M1, config.ewald.M2, config.ewald.N, config.ewald.joint};
  proxy_labels = config.slp.proxy_labels;
  proxy_levels = {config.proxy.base, config.proxy.Nside, config.proxy.Ntop, ...
    config.proxy.Nedge, config.proxy.Mpw, config.proxy.joint};

  % Ewald single-axis ladder holds the proxy path at its base level.
  ewald_data = cell(length(ewald_levels), 1);
  ewald_changes = NaN(length(ewald_levels), 1);
  for il = 1:length(ewald_levels)
    [ewald_data{il}, wall_rows, timing_rows] = LOCAL_three_path_level( ...
      config, config.ntot.authority, config.Ny.authority, M, ...
      ewald_levels{il}, config.proxy.base, false, log_fid, 'E');
    ledgers.timings.rows = [ledgers.timings.rows; ...
      LOCAL_prefix_timings(timing_rows, ['ewald_', ewald_labels{il}])];
    change = NaN;
    if il > 1
      change = LOCAL_path_max_change(config, ewald_data{1}, ...
        ewald_data{il}, 'E');
    end
    ewald_changes(il) = change;
    pass = isnan(change) || change <= config.gate.self_change;
    q = ewald_levels{il};
    ledgers.path_levels.rows(end + 1, :) = {'slp', 'E', ...
      ewald_labels{il}, config.ntot.authority, config.Ny.authority, M, ...
      q.a, q.M1, q.M2, q.N, NaN, NaN, NaN, NaN, change, ...
      config.gate.self_change, pass, ...
      LOCAL_refinement_note('local Ewald', il, length(ewald_levels))};
  end

  % MFS single-axis ladder holds the certified Ewald level fixed at joint.
  proxy_data = cell(length(proxy_levels), 1);
  proxy_changes = NaN(length(proxy_levels), 1);
  for il = 1:length(proxy_levels)
    [proxy_data{il}, ~, timing_rows] = LOCAL_three_path_level( ...
      config, config.ntot.authority, config.Ny.authority, M, ...
      config.ewald.joint, proxy_levels{il}, false, log_fid, 'P');
    ledgers.timings.rows = [ledgers.timings.rows; ...
      LOCAL_prefix_timings(timing_rows, ['proxy_', proxy_labels{il}])];
    change = NaN;
    if il > 1
      change = LOCAL_path_max_change(config, proxy_data{1}, ...
        proxy_data{il}, 'P');
    end
    proxy_changes(il) = change;
    pass = isnan(change) || change <= config.gate.self_change;
    q = proxy_levels{il};
    ledgers.path_levels.rows(end + 1, :) = {'slp', 'P', ...
      proxy_labels{il}, config.ntot.authority, config.Ny.authority, M, ...
      NaN, NaN, NaN, NaN, q.N_side, q.N_top, q.N_proxy_edge, ...
      q.M_pw, change, config.gate.self_change, pass, ...
      LOCAL_refinement_note('package MFS', il, length(proxy_levels))};
  end

  % Boundary and wall refinements vary only ntot or Ny at the base E/P levels.
  [boundary_ref, ~, timing_rows] = LOCAL_three_path_level(config, ...
    config.ntot.boundary_ref, config.Ny.authority, M, ...
    config.ewald.base, config.proxy.base, false, log_fid);
  ledgers.timings.rows = [ledgers.timings.rows; ...
    LOCAL_prefix_timings(timing_rows, 'boundary_ref')];
  [wall_ref, ~, timing_rows] = LOCAL_three_path_level(config, ...
    config.ntot.boundary_ref, config.Ny.wall_ref, M, ...
    config.ewald.base, config.proxy.base, false, log_fid);
  ledgers.timings.rows = [ledgers.timings.rows; ...
    LOCAL_prefix_timings(timing_rows, 'wall_ref')];

  authority = proxy_data{1};
  authority_E = ewald_data{1};
  % Combine E authority with P/R authority so all three rows share grids.
  authority = LOCAL_replace_path(config, authority, authority_E, 'E');
  ledgers.wall.rows = [ledgers.wall.rows; ...
    LOCAL_wall_rows_from_data(config, authority, config.ewald.base, ...
    config.proxy.base)];
  ledgers = LOCAL_append_coefficients(config, ledgers, authority, ...
    'authority', true);

  boundary_change_E = LOCAL_path_max_change(config, ewald_data{1}, ...
    boundary_ref, 'E');
  boundary_change_P = LOCAL_path_max_change(config, proxy_data{1}, ...
    boundary_ref, 'P');
  wall_change_E = LOCAL_path_max_change(config, boundary_ref, wall_ref, 'E');
  wall_change_P = LOCAL_path_max_change(config, boundary_ref, wall_ref, 'P');
  [rayleigh_retained, retained_rows] = ...
    LOCAL_rayleigh_retained_change(config);
  ledgers.coefficients.rows = [ledgers.coefficients.rows; retained_rows];
  pairwise = LOCAL_pairwise_max(config, authority);
  self_values = [ewald_changes(2:end - 1).', proxy_changes(2:end - 1).', ...
    boundary_change_E, boundary_change_P, wall_change_E, wall_change_P];
  self_max = max(self_values);
  pair_max = max(pairwise);
  slp_pass = self_max <= config.gate.self_change && ...
    pair_max <= config.gate.coefficient_abs && ...
    rayleigh_retained <= config.gate.rayleigh_retained;

  ledgers.path_levels.rows(end + 1, :) = {'slp', 'E', 'boundary_ref', ...
    config.ntot.boundary_ref, config.Ny.authority, M, ...
    config.ewald.base.a, config.ewald.base.M1, ...
    config.ewald.base.M2, config.ewald.base.N, NaN, NaN, NaN, NaN, ...
    boundary_change_E, config.gate.self_change, ...
    boundary_change_E <= config.gate.self_change, 'boundary refinement'};
  ledgers.path_levels.rows(end + 1, :) = {'slp', 'P', 'boundary_ref', ...
    config.ntot.boundary_ref, config.Ny.authority, M, NaN, NaN, NaN, NaN, ...
    config.proxy.base.N_side, config.proxy.base.N_top, ...
    config.proxy.base.N_proxy_edge, config.proxy.base.M_pw, ...
    boundary_change_P, config.gate.self_change, ...
    boundary_change_P <= config.gate.self_change, 'boundary refinement'};
  ledgers.path_levels.rows(end + 1, :) = {'slp', 'E', 'wall_ref', ...
    config.ntot.boundary_ref, config.Ny.wall_ref, M, ...
    config.ewald.base.a, config.ewald.base.M1, ...
    config.ewald.base.M2, config.ewald.base.N, NaN, NaN, NaN, NaN, ...
    wall_change_E, config.gate.self_change, ...
    wall_change_E <= config.gate.self_change, 'wall refinement'};
  ledgers.path_levels.rows(end + 1, :) = {'slp', 'P', 'wall_ref', ...
    config.ntot.boundary_ref, config.Ny.wall_ref, M, NaN, NaN, NaN, NaN, ...
    config.proxy.base.N_side, config.proxy.base.N_top, ...
    config.proxy.base.N_proxy_edge, config.proxy.base.M_pw, wall_change_P, ...
    config.gate.self_change, wall_change_P <= config.gate.self_change, ...
    'wall refinement'};
  ledgers.path_levels.rows(end + 1, :) = {'slp', 'R', ...
    'retained_M12_M24_M48', config.ntot.authority, NaN, M, ...
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, rayleigh_retained, ...
    config.gate.rayleigh_retained, ...
    rayleigh_retained <= config.gate.rayleigh_retained, ...
    'retained rows |m|<=24 compared across direct extractor grids'};

  ledgers.gates.rows(end + 1, :) = {'slp_self_change', self_max, ...
    config.gate.self_change, self_max <= config.gate.self_change, 1, ...
    'maximum per-axis, boundary, or wall coefficient change'};
  ledgers.gates.rows(end + 1, :) = {'slp_pairwise_coefficients', pair_max, ...
    config.gate.coefficient_abs, pair_max <= config.gate.coefficient_abs, 1, ...
    'maximum E-P, E-R, or P-R coefficient difference per side/mode'};
  ledgers.gates.rows(end + 1, :) = {'rayleigh_retained_rows', ...
    rayleigh_retained, config.gate.rayleigh_retained, ...
    rayleigh_retained <= config.gate.rayleigh_retained, 1, ...
    'direct extractor retained modes across M=12,24,48'};
  [classification, triangle_note] = LOCAL_triangle_decision( ...
    pairwise, config.gate.coefficient_abs);
  if slp_pass
    status = 'SLP_D_CERTIFIED';
  else
    status = 'SLP_D_UNCERTIFIED';
  end
  ledgers.decision.rows(end + 1, :) = {'SLP-D', classification, ...
    status, slp_pass, triangle_note};
  if slp_pass
    later_status = 'NOT_RUN_NOT_IMPLEMENTED';
    later_note = 'SLP-D passed; derivative layers remain for a later engineering round.';
  else
    later_status = 'NOT_RUN_PREREQUISITE';
    later_note = 'SLP-D failed, so derivative layers are stopped.';
  end
  ledgers.decision.rows(end + 1, :) = {'SLP-N/DLP-D/DLP-N', ...
    'IMPORTANT CAVEAT', later_status, 0, later_note};
  summary = struct('status', status, 'slp_pass', slp_pass, ...
    'self_max', self_max, 'pairwise_max', pairwise, ...
    'rayleigh_retained', rayleigh_retained, ...
    'weighted_aggregate', LOCAL_weighted_aggregate(config, authority));
end

%% ==================== Geometry and coefficient helpers ====================
% These helpers define the shared circle, modes, and comparison reductions.

function [circle, source, weights] = LOCAL_circle_geometry(config, ntot)
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  x = config.R * cos(theta);
  y = config.R * sin(theta);
  dxdt = -config.R * sin(theta);
  dydt = config.R * cos(theta);
  circle = struct('x', x, 'y', y, 'dxdt', dxdt, 'dydt', dydt, ...
    'speed', config.R * ones(ntot, 1), 'nx', cos(theta), ...
    'ny', sin(theta));
  source = [x.'; y.'];
  weights = (2 * pi / ntot) * config.R * ones(ntot, 1);
end

function density = LOCAL_density_values(density_config, ntot)
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  density = zeros(ntot, 1);
  for j = 1:length(density_config.ell)
    density = density + density_config.coeff(j) * ...
      exp(1i * density_config.ell(j) * theta);
  end
end

function channels = LOCAL_channels(config, M)
  channels.m = (-M:M).';
  channels.beta_m = config.beta + 2 * pi * channels.m / config.d;
  channels.gamma_m = LOCAL_rayleigh_branch(config.k, channels.beta_m);
  channels.d = config.d;
  channels.K = length(channels.m);
end

function coeff = LOCAL_fourier_project(d, beta_m, y, values)
  psi_conjugate = (1 / sqrt(d)) * exp(-1i * (beta_m(:) * y));
  coeff = (d / length(y)) * psi_conjugate * values(:);
end

function change = LOCAL_path_max_change(config, left, right, path)
  change = 0;
  density_labels = {config.density.label};
  sides = {'L', 'R'};
  for id = 1:length(density_labels)
    for is = 1:2
      a = left.(density_labels{id}).(sides{is}).(path);
      b = right.(density_labels{id}).(sides{is}).(path);
      if length(a) ~= length(b)
        m_left = left.channels.m;
        m_right = right.channels.m;
        common = intersect(m_left, m_right);
        for im = 1:length(common)
          ia = find(m_left == common(im), 1);
          ib = find(m_right == common(im), 1);
          change = max(change, abs(a(ia) - b(ib)));
        end
      else
        change = max(change, max(abs(a(:) - b(:))));
      end
    end
  end
end

function combined = LOCAL_replace_path(config, combined, donor, path)
  density_labels = {config.density.label};
  sides = {'L', 'R'};
  for id = 1:length(density_labels)
    for is = 1:2
      combined.(density_labels{id}).(sides{is}).(path) = ...
        donor.(density_labels{id}).(sides{is}).(path);
      wall_field = [path, '_wall'];
      if isfield(donor.(density_labels{id}).(sides{is}), wall_field)
        combined.(density_labels{id}).(sides{is}).(wall_field) = ...
          donor.(density_labels{id}).(sides{is}).(wall_field);
      end
    end
  end
end

function rows = LOCAL_wall_rows_from_data(config, data, ewald_level, proxy_level)
  rows = cell(0, 13);
  density_labels = {config.density.label};
  sides = {'L', 'R'};
  y = config.d * (0:data.Ny - 1) / data.Ny;
  for id = 1:length(density_labels)
    for is = 1:2
      values = data.(density_labels{id}).(sides{is});
      for jy = 1:data.Ny
        rows(end + 1, :) = {density_labels{id}, sides{is}, jy, y(jy), ...
          real(values.E_wall(jy)), imag(values.E_wall(jy)), ...
          real(values.P_wall(jy)), imag(values.P_wall(jy)), ...
          abs(values.E_wall(jy) - values.P_wall(jy)), data.ntot, ...
          data.Ny, ewald_level.M1, proxy_level.N_proxy_edge};
      end
    end
  end
end

function note = LOCAL_refinement_note(path, index, count)
  if index == count
    note = [path, ' joint higher level is supplemental diagnostic only'];
  else
    note = [path, ' base or single-axis refinement'];
  end
end

function pairwise = LOCAL_pairwise_max(config, data)
  pairs = {'E', 'P'; 'E', 'R'; 'P', 'R'};
  pairwise = zeros(1, 3);
  density_labels = {config.density.label};
  sides = {'L', 'R'};
  for ip = 1:3
    for id = 1:length(density_labels)
      for is = 1:2
        a = data.(density_labels{id}).(sides{is}).(pairs{ip, 1});
        b = data.(density_labels{id}).(sides{is}).(pairs{ip, 2});
        pairwise(ip) = max(pairwise(ip), max(abs(a(:) - b(:))));
      end
    end
  end
end

function [retained, rows] = LOCAL_rayleigh_retained_change(config)
  retained = 0;
  rows = cell(0, 18);
  density_labels = {config.density.label};
  sides = {'L', 'R'};
  values = cell(length(config.rayleigh_M), 1);
  for iM = 1:length(config.rayleigh_M)
    M = config.rayleigh_M(iM);
    channels = LOCAL_channels(config, M);
    [circle, ~, ~] = LOCAL_circle_geometry(config, config.ntot.authority);
    [F_L, F_R] = bloch.farfield_extractors(circle, channels, ...
      config.X_L, config.X_R, 2 * pi);
    F = {F_L, F_R};
    for id = 1:length(density_labels)
      rho = LOCAL_density_values(config.density(id), config.ntot.authority);
      eta = [zeros(config.ntot.authority, 1); rho];
      for is = 1:2
        values{iM}.(density_labels{id}).(sides{is}) = F{is} * eta;
      end
    end
    values{iM}.m = channels.m;
  end
  reference_scale = 0;
  for iM = 1:length(config.rayleigh_M)
    for id = 1:length(density_labels)
      for is = 1:2
        reference_scale = max(reference_scale, max(abs( ...
          values{iM}.(density_labels{id}).(sides{is}))));
      end
    end
  end
  floor_value = max(config.relative_floor_abs, ...
    config.relative_floor_scale * reference_scale);
  for iM = 1:length(config.rayleigh_M) - 1
    common = values{iM}.m(abs(values{iM}.m) <= 24);
    for id = 1:length(density_labels)
      for is = 1:2
        for im = 1:length(common)
          ia = find(values{iM}.m == common(im), 1);
          ib = find(values{iM + 1}.m == common(im), 1);
          a = values{iM}.(density_labels{id}).(sides{is})(ia);
          b = values{iM + 1}.(density_labels{id}).(sides{is})(ib);
          abs_error = abs(a - b);
          retained = max(retained, abs_error);
          rows(end + 1, :) = {sprintf('retained_M%d_M%d', ...
            config.rayleigh_M(iM), config.rayleigh_M(iM + 1)), ...
            density_labels{id}, 'SLP', sides{is}, 'D', common(im), ...
            sprintf('R_M%d', config.rayleigh_M(iM)), ...
            sprintf('R_M%d', config.rayleigh_M(iM + 1)), ...
            real(a), imag(a), real(b), imag(b), abs_error, ...
            abs_error / max(floor_value, abs(b)), floor_value, ...
            config.gate.rayleigh_retained, ...
            abs_error <= config.gate.rayleigh_retained, true};
        end
      end
    end
  end
end

function values = LOCAL_non_nan_path_changes(rows)
  if isempty(rows)
    values = 0;
    return;
  end
  values = cell2mat(rows(:, 15));
  values = values(~isnan(values));
  if isempty(values)
    values = 0;
  end
end

function [classification, note] = LOCAL_triangle_decision(pairwise, tolerance)
  pass = pairwise <= tolerance;
  if all(pass)
    classification = 'MINOR CAVEAT';
    note = 'E-P, E-R, and P-R all satisfy the frozen per-mode gate.';
  elseif pass(2) && ~pass(1) && ~pass(3)
    classification = 'BLOCKER';
    note = ['E-R closes while both pairs containing P fail; the current ', ...
      'Octave P path is isolated, but its internal cause remains unresolved.'];
  elseif pass(3) && ~pass(1) && ~pass(2)
    classification = 'BLOCKER';
    note = 'P-R closes while both pairs containing E fail; local Ewald is isolated.';
  elseif pass(1) && ~pass(2) && ~pass(3)
    classification = 'BLOCKER';
    note = 'E-P closes while both pairs containing R fail; direct extraction is isolated.';
  else
    classification = 'IMPORTANT CAVEAT';
    note = 'The pairwise triangle does not isolate a unique numerical path.';
  end
end

function aggregate = LOCAL_weighted_aggregate(config, data)
  scale_sum = 0;
  error_sum = 0;
  density_labels = {config.density.label};
  sides = {'L', 'R'};
  pairs = {'E', 'P'; 'E', 'R'; 'P', 'R'};
  for id = 1:length(density_labels)
    for is = 1:2
      for ip = 1:3
        a = data.(density_labels{id}).(sides{is}).(pairs{ip, 1});
        b = data.(density_labels{id}).(sides{is}).(pairs{ip, 2});
        weight = 1 ./ max(config.relative_floor_abs, abs(b));
        error_sum = error_sum + sum(weight .* abs(a - b));
        scale_sum = scale_sum + sum(weight);
      end
    end
  end
  aggregate = error_sum / max(scale_sum, eps);
end

function rows = LOCAL_prefix_timings(rows, prefix)
  for j = 1:size(rows, 1)
    rows{j, 1} = [prefix, '_', rows{j, 1}];
  end
end

%% ==================== Runtime extrapolation ====================
% This helper converts pilot timings to explicit interaction-count estimates.

function estimate = LOCAL_runtime_estimate(config, timing_rows)
  pilot_ewald = LOCAL_timing_sum(timing_rows, 'ewald_wall_');
  pilot_mfs = LOCAL_timing_sum(timing_rows, 'mfs_wall_');
  pilot_precomp = LOCAL_timing_sum(timing_rows, 'proxy_precomp');
  pilot_interactions = 2 * config.pilot.ntot * config.pilot.Ny;
  base_cost = LOCAL_ewald_cost(config.ewald.base);
  ewald_levels = {config.ewald.base, config.ewald.wall_a, ...
    config.ewald.M1, config.ewald.M2, config.ewald.N, config.ewald.joint};
  ewald_seconds = 0;
  ewald_interactions = 0;
  for j = 1:length(ewald_levels)
    count = 2 * config.ntot.authority * config.Ny.authority;
    ewald_interactions = ewald_interactions + count;
    ewald_seconds = ewald_seconds + pilot_ewald * ...
      (count / pilot_interactions) * ...
      (LOCAL_ewald_cost(ewald_levels{j}) / base_cost);
  end
  count = 2 * config.ntot.boundary_ref * config.Ny.authority;
  ewald_interactions = ewald_interactions + count;
  ewald_seconds = ewald_seconds + pilot_ewald * ...
    (count / pilot_interactions) * ...
    (LOCAL_ewald_cost(config.ewald.base) / base_cost);
  count = 2 * config.ntot.boundary_ref * config.Ny.wall_ref;
  ewald_interactions = ewald_interactions + count;
  ewald_seconds = ewald_seconds + pilot_ewald * ...
    (count / pilot_interactions) * ...
    (LOCAL_ewald_cost(config.ewald.base) / base_cost);

  proxy_levels = {config.proxy.base, config.proxy.Nside, config.proxy.Ntop, ...
    config.proxy.Nedge, config.proxy.Mpw, config.proxy.joint};
  mfs_seconds = 0;
  precomp_seconds = 0;
  proxy_interactions = 0;
  base_proxy_cost = 1 + 4 * config.proxy.base.N_proxy_edge;
  base_precomp_cost = LOCAL_proxy_precomp_cost(config.proxy.base);
  for j = 1:length(proxy_levels)
    q = proxy_levels{j};
    count = 2 * config.ntot.authority * config.Ny.authority;
    proxy_interactions = proxy_interactions + count * ...
      (1 + 4 * q.N_proxy_edge);
    mfs_seconds = mfs_seconds + pilot_mfs * ...
      (count / pilot_interactions) * ...
      ((1 + 4 * q.N_proxy_edge) / base_proxy_cost);
    precomp_seconds = precomp_seconds + pilot_precomp * ...
      (LOCAL_proxy_precomp_cost(q) / base_precomp_cost);
  end
  q = config.proxy.base;
  count = 2 * config.ntot.boundary_ref * config.Ny.authority;
  proxy_interactions = proxy_interactions + count * ...
    (1 + 4 * q.N_proxy_edge);
  mfs_seconds = mfs_seconds + pilot_mfs * ...
    (count / pilot_interactions) * ...
    ((1 + 4 * q.N_proxy_edge) / base_proxy_cost);
  precomp_seconds = precomp_seconds + pilot_precomp * ...
    (LOCAL_proxy_precomp_cost(q) / base_precomp_cost);
  count = 2 * config.ntot.boundary_ref * config.Ny.wall_ref;
  proxy_interactions = proxy_interactions + count * ...
    (1 + 4 * q.N_proxy_edge);
  mfs_seconds = mfs_seconds + pilot_mfs * ...
    (count / pilot_interactions) * ...
    ((1 + 4 * q.N_proxy_edge) / base_proxy_cost);
  precomp_seconds = precomp_seconds + pilot_precomp * ...
    (LOCAL_proxy_precomp_cost(q) / base_precomp_cost);

  estimate.pilot_ewald_seconds = pilot_ewald;
  estimate.pilot_mfs_seconds = pilot_mfs;
  estimate.pilot_proxy_precomp_seconds = pilot_precomp;
  estimate.pilot_source_target_interactions = pilot_interactions;
  estimate.full_ewald_source_target_interactions = ewald_interactions;
  estimate.full_proxy_weighted_interactions = proxy_interactions;
  estimate.ewald_seconds = ewald_seconds;
  estimate.mfs_matrix_seconds = mfs_seconds;
  estimate.proxy_precomp_seconds = precomp_seconds;
  estimate.central_seconds = ewald_seconds + mfs_seconds + precomp_seconds;
  estimate.lower_seconds = 0.8 * estimate.central_seconds;
  estimate.upper_seconds = 1.5 * estimate.central_seconds;
end

function value = LOCAL_ewald_cost(level)
  value = (2 * level.M1 + 1) + ...
    (2 * level.M2 + 1) * (level.N + 1);
end

function value = LOCAL_proxy_precomp_cost(level)
  equations = 2 * level.N_side + 4 * level.N_top;
  unknowns = 4 * level.N_proxy_edge + 2 * (2 * level.M_pw + 1);
  value = equations * unknowns ^ 2;
end

function seconds = LOCAL_timing_sum(rows, prefix)
  seconds = 0;
  for j = 1:size(rows, 1)
    if strncmp(rows{j, 1}, prefix, length(prefix))
      seconds = seconds + rows{j, 2};
    end
  end
end

%% ==================== Artifact and report helpers ====================
% These helpers keep every mode on the same portable output contract.

function ledgers = LOCAL_empty_ledgers()
  ledgers.ewald_tables = LOCAL_ledger({ ...
    'case', 'kd', 'beta_d', 'X_over_d', 'Y_over_d', ...
    'reference_real', 'reference_imag', 'project_real', 'project_imag', ...
    'minus_project_real', 'minus_project_imag', 'reciprocal_real', ...
    'reciprocal_imag', 'real_space_real', 'real_space_imag', ...
    'mfs_real', 'mfs_imag', 'abs_E_minus_P', 'abs_table_error', ...
    'gate', 'pass'});
  ledgers.ewald_convergence = LOCAL_ledger({ ...
    'case', 'level', 'a', 'M1', 'M2', 'N', 'value_real', 'value_imag', ...
    'change', 'holdout', 'note'});
  ledgers.point_values = LOCAL_ledger({ ...
    'point', 'holdout', 'X_transverse', 'Y_periodic', ...
    'ewald_base_real', 'ewald_base_imag', 'ewald_joint_real', ...
    'ewald_joint_imag', 'mfs_real', 'mfs_imag', 'rayleigh_real', ...
    'rayleigh_imag', 'abs_E_minus_P', 'abs_E_minus_R', ...
    'abs_P_minus_R', 'ewald_base_joint_change', 'mfs_eval_seconds'});
  ledgers.projection = LOCAL_ledger({ ...
    'Ny', 'm', 'reference_real', 'reference_imag', 'observed_real', ...
    'observed_imag', 'abs_error', 'gate', 'pass'});
  ledgers.path_levels = LOCAL_ledger({ ...
    'mode', 'path', 'level', 'ntot', 'Ny', 'M', 'a', 'M1', 'M2', 'N', ...
    'Nside', 'Ntop', 'Nedge', 'Mpw', 'self_change', 'gate', 'pass', 'note'});
  ledgers.wall = LOCAL_ledger({ ...
    'density', 'side', 'index', 'y', 'ewald_real', 'ewald_imag', ...
    'mfs_real', 'mfs_imag', 'abs_E_minus_P', 'ntot', 'Ny', ...
    'ewald_M1', 'proxy_Nedge'});
  ledgers.coefficients = LOCAL_ledger({ ...
    'level', 'density', 'layer', 'side', 'trace', 'm', 'left_path', ...
    'right_path', 'left_real', 'left_imag', 'right_real', 'right_imag', ...
    'abs_error', 'floor_relative_error', 'floor', 'gate', 'pass', ...
    'gate_enforced'});
  ledgers.gates = LOCAL_ledger({ ...
    'gate', 'value', 'tolerance', 'pass', 'mandatory', 'note'});
  ledgers.decision = LOCAL_ledger({ ...
    'stage', 'classification', 'status', 'pass', 'note'});
  ledgers.timings = LOCAL_ledger({ ...
    'stage', 'seconds', 'note'});
end

function ledger = LOCAL_ledger(headers)
  ledger.headers = headers;
  ledger.rows = cell(0, length(headers));
end

function LOCAL_write_all_ledgers(output_dir, ledgers)
  files = { ...
    'ewald-tables.csv', ledgers.ewald_tables; ...
    'ewald-convergence.csv', ledgers.ewald_convergence; ...
    'point-values.csv', ledgers.point_values; ...
    'projection-oracle.csv', ledgers.projection; ...
    'path-levels.csv', ledgers.path_levels; ...
    'wall-point-comparison.csv', ledgers.wall; ...
    'coefficient-comparison.csv', ledgers.coefficients; ...
    'gates.csv', ledgers.gates; ...
    'decision-matrix.csv', ledgers.decision; ...
    'timings.csv', ledgers.timings};
  for j = 1:size(files, 1)
    LOCAL_write_csv(fullfile(output_dir, files{j, 1}), ...
      files{j, 2}.headers, files{j, 2}.rows);
  end
end

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_three_path:CsvOpenFailed', 'Could not open %s.', path);
  end
  cleaner = onCleanup(@() fclose(fid));
  LOCAL_write_csv_row(fid, headers);
  for j = 1:size(rows, 1)
    LOCAL_write_csv_row(fid, rows(j, :));
  end
  clear cleaner;
end

function LOCAL_write_csv_row(fid, values)
  for j = 1:length(values)
    if j > 1
      fprintf(fid, ',');
    end
    fprintf(fid, '%s', LOCAL_csv_value(values{j}));
  end
  fprintf(fid, '\n');
end

function value = LOCAL_csv_value(item)
  if ischar(item)
    value = ['"', strrep(item, '"', '""'), '"'];
  elseif isstring(item)
    value = ['"', strrep(char(item), '"', '""'), '"'];
  elseif islogical(item)
    value = sprintf('%d', item ~= 0);
  elseif isnumeric(item) && isscalar(item)
    if isnan(item)
      value = 'NaN';
    elseif isinf(item)
      value = sprintf('%+g', item);
    elseif isreal(item)
      value = sprintf('%.16e', item);
    else
      value = sprintf('"%.16e%+.16ei"', real(item), imag(item));
    end
  else
    error('run_i4_three_path:UnsupportedCsvValue', ...
      'CSV cells must contain scalar numeric, logical, or text values.');
  end
end

function LOCAL_write_report(path, results)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_three_path:ReportOpenFailed', ...
      'Could not open %s.', path);
  end
  cleaner = onCleanup(@() fclose(fid));
  c = results.config;
  fprintf(fid, '# I4 three-path experiment\n\n');
  fprintf(fid, '- Mode: `%s`\n', results.mode);
  fprintf(fid, '- Status: `%s`\n', results.status);
  fprintf(fid, '- Started: `%s`\n', results.started);
  fprintf(fid, '- Finished: `%s`\n', results.finished);
  fprintf(fid, '- Total wall time: `%.6f s`\n', results.total_seconds);
  fprintf(fid, '- Wood distance $\\min_m |\\gamma_m|$: `%.16e`\n', ...
    results.wood_distance);
  fprintf(fid, '- Circle-to-wall clearance: `%.16e`\n\n', ...
    results.clearance);

  fprintf(fid, '## Frozen conventions\n\n');
  fprintf(fid, ['The local Linton helper consumes physical separations ', ...
    '$(X,Y)=(x_t-x_s,y_t-y_s)$ directly, with $Y$ periodic. Only the ', ...
    'package first-coordinate-periodic MFS wrapper uses `[y;x]`. ', ...
    'Linton uses source ', ...
    '$+\\delta$ and free kernel $-\\mathrm{i}H_0^{(1)}/4$; the project ', ...
    'uses source $-\\delta$ and free kernel ', ...
    '$+\\mathrm{i}H_0^{(1)}/4$. Therefore ', ...
    '$G_{\\mathrm{project}}=-G_{\\mathrm{Linton}}$. Both use the ', ...
    '$\\exp(-\\mathrm{i}\\omega t)$ outgoing convention and a target ', ...
    'shift by $+d$ has factor $\\exp(+\\mathrm{i}\\beta d)$.\n\n']);
  fprintf(fid, 'The branch ledger is `%s`. The SLP-D field is ', ...
    c.branch_convention);
  fprintf(fid, ['$u=-\\int G\\rho\\,ds$, consistent with ', ...
    '`eta=[tau;-sigma]`. The local Ewald path exposes real-space and ', ...
    'reciprocal-space contributions and has no Rayleigh fallback.\n\n']);

  fprintf(fid, '## Gates\n\n');
  fprintf(fid, '| Gate | Value | Tolerance | Pass | Mandatory |\n');
  fprintf(fid, '|---|---:|---:|---:|---:|\n');
  for j = 1:size(results.ledgers.gates.rows, 1)
    r = results.ledgers.gates.rows(j, :);
    fprintf(fid, '| %s | %.6e | %.6e | %d | %d |\n', ...
      r{1}, r{2}, r{3}, r{4}, r{5});
  end
  fprintf(fid, '\n## Decision matrix\n\n');
  fprintf(fid, '| Stage | Classification | Status | Pass | Note |\n');
  fprintf(fid, '|---|---|---|---:|---|\n');
  for j = 1:size(results.ledgers.decision.rows, 1)
    r = results.ledgers.decision.rows(j, :);
    fprintf(fid, '| %s | %s | %s | %d | %s |\n', ...
      r{1}, r{2}, r{3}, r{4}, r{5});
  end
  fprintf(fid, '\n');

  if strcmp(results.mode, 'pilot')
    e = results.summary.runtime_estimate;
    fprintf(fid, '## Pilot interpretation\n\n');
    fprintf(fid, ['Pilot uses `ntot=%d`, `Ny=%d`, and `M=%d`. It is a ', ...
      'timing-only run and supplies no scientific verdict. The full ', ...
      'ladder central estimate is `%.1f s` with a simple pilot scaling ', ...
      'range of `%.1f--%.1f s`. See `runtime-estimate.md`.\n\n'], ...
      c.pilot.ntot, c.pilot.Ny, c.pilot.M, e.central_seconds, ...
      e.lower_seconds, e.upper_seconds);
  elseif strcmp(results.mode, 'qualification')
    fprintf(fid, '## Qualification interpretation\n\n');
    fprintf(fid, ['This result certifies only value-level Linton Ewald, ', ...
      'coordinate/sign/phase conventions, and Fourier projection. MFS ', ...
      'point discrepancies are reported but are not used to tune or ', ...
      'certify the Ewald implementation. The maximum Ewald--MFS error ', ...
      'at the five printed Linton points is `%.6e`.\n\n'], ...
      results.summary.table.mfs_max_error);
  else
    fprintf(fid, '## SLP-D interpretation\n\n');
    fprintf(fid, ['All E-P, E-R, and P-R rows remain explicit in ', ...
      '`coefficient-comparison.csv`; weighted aggregation is supplemental ', ...
      'and does not replace per-mode maxima. The weighted aggregate is ', ...
      '`%.16e`.\n\n'], results.summary.weighted_aggregate);
  end
  fprintf(fid, ['Later SLP-N/DLP-D/DLP-N stages are not run in this ', ...
    'delivery unless separately implemented after SLP-D certification.\n']);
  clear cleaner;
end

function LOCAL_write_runtime_estimate(path, config, estimate)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_three_path:EstimateOpenFailed', ...
      'Could not open %s.', path);
  end
  cleaner = onCleanup(@() fclose(fid));
  fprintf(fid, '# I4 full SLP-D runtime estimate\n\n');
  fprintf(fid, ['This estimate is measured from the pilot with `ntot=%d`, ', ...
    '`Ny=%d`, `M=%d`, the base Ewald truncation, and the base package ', ...
    'proxy. It is required before any full wall ladder is launched.\n\n'], ...
    config.pilot.ntot, config.pilot.Ny, config.pilot.M);
  fprintf(fid, '| Quantity | Value |\n');
  fprintf(fid, '|---|---:|\n');
  fprintf(fid, '| Pilot Ewald two-wall time (s) | %.6f |\n', ...
    estimate.pilot_ewald_seconds);
  fprintf(fid, '| Pilot MFS two-wall time (s) | %.6f |\n', ...
    estimate.pilot_mfs_seconds);
  fprintf(fid, '| Pilot proxy precomputation (s) | %.6f |\n', ...
    estimate.pilot_proxy_precomp_seconds);
  fprintf(fid, '| Pilot source-target interactions | %.0f |\n', ...
    estimate.pilot_source_target_interactions);
  fprintf(fid, '| Full Ewald source-target interactions | %.0f |\n', ...
    estimate.full_ewald_source_target_interactions);
  fprintf(fid, '| Full proxy-weighted interactions | %.0f |\n', ...
    estimate.full_proxy_weighted_interactions);
  fprintf(fid, '| Ewald ladder estimate (s) | %.3f |\n', ...
    estimate.ewald_seconds);
  fprintf(fid, '| MFS wall matrices estimate (s) | %.3f |\n', ...
    estimate.mfs_matrix_seconds);
  fprintf(fid, '| Proxy precomputations estimate (s) | %.3f |\n', ...
    estimate.proxy_precomp_seconds);
  fprintf(fid, '| Central full-ladder estimate (s) | %.3f |\n', ...
    estimate.central_seconds);
  fprintf(fid, '| Scaling range (s) | %.3f--%.3f |\n\n', ...
    estimate.lower_seconds, estimate.upper_seconds);
  fprintf(fid, ['Ewald matrix time is scaled by source-target count and ', ...
    'the explicit Eq. (2.65) work proxy ', ...
    '`(2*M1+1)+(2*M2+1)*(N+1)`. MFS matrix time is scaled by ', ...
    'source-target count and `1+4*Nedge`; proxy setup is scaled by ', ...
    '`equations*unknowns^2`. The range is a workload estimate, not a ', ...
    'deadline or scientific result.\n']);
  clear cleaner;
end

%% ==================== Validation and logging helpers ====================
% These helpers enforce staged stopping and record deterministic metadata.

function LOCAL_require_qualification(config)
  path = fullfile(config.output_root, 'qualification', 'results.mat');
  if ~exist(path, 'file')
    error('run_i4_three_path:EwaldReferenceUncertified', ...
      'Qualification results are missing; refusing full SLP-D.');
  end
  loaded = load(path, 'results');
  if ~isfield(loaded, 'results') || ...
      ~strcmp(loaded.results.status, 'EWALD_REFERENCE_CERTIFIED')
    error('run_i4_three_path:EwaldReferenceUncertified', ...
      'Qualification status is not EWALD_REFERENCE_CERTIFIED; refusing full SLP-D.');
  end
end

function distance = LOCAL_wood_distance(k, beta, d)
  m = (-50:50).';
  gamma = LOCAL_rayleigh_branch(k, beta + 2 * pi * m / d);
  distance = min(abs(gamma));
end

function tf = LOCAL_is_octave()
  tf = exist('OCTAVE_VERSION', 'builtin') ~= 0;
end

function LOCAL_log(fid, varargin)
  fprintf(varargin{:});
  fprintf(fid, varargin{:});
end
