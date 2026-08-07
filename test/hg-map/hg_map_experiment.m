function results = hg_map_experiment()
% Purpose:
%   Validate finite-section half-guide reflection and DtN maps against an
%   independent ordered generalized-Schur reference.
%
% Main algorithm:
%   Run noncommuting algebra oracles, an exactly solvable diagonal cell, and
%   one real EDC cell.  Double finite sections with the Redheffer product,
%   impose three far-end closures, and compare both half-guide maps with two
%   ordered-QZ deflating subspaces.
%
% Numerical goal:
%   Produce a deterministic Stage 1 evidence bundle under output/ without
%   calling bloch.solve_modes or forming an explicit matrix inverse.

  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  output_dir = fullfile(here, 'output');
  if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
  end
  addpath(repo_root);

  previous = LOCAL_previous_result(output_dir);
  log_file = fullfile(output_dir, 'run.log');
  diary('off');
  if exist(log_file, 'file') == 2
    delete(log_file);
  end
  diary(log_file);
  diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>

  config = LOCAL_config(repo_root, output_dir, here);
  fprintf('Half-guide map Stage 1 experiment\n');
  fprintf('Repository: %s\n', repo_root);
  fprintf('Levels: %s\n', mat2str(config.levels));
  fprintf('Explicit inv calls: none\n');
  fprintf('bloch.solve_modes calls: none\n');

  ledger = LOCAL_empty_ledger();
  [a0, ledger] = LOCAL_run_a0(config, ledger);
  [case_a, ledger] = LOCAL_run_case_a(config, ledger);
  [case_b, ledger] = LOCAL_run_case_b(config, ledger);
  [negative_cases, ledger] = LOCAL_run_negative_cases(config, a0, ledger);

  ledger_pass = ~any(strcmp({ledger.status}, 'FAIL'));
  all_pass = a0.pass && case_a.pass && case_b.pass && ...
    negative_cases.pass && ledger_pass;

  results = struct();
  results.config = config;
  results.a0 = a0;
  results.case_a = case_a;
  results.case_b = case_b;
  results.pole_ledger = ledger;
  results.negative_cases = negative_cases;
  results.all_pass = all_pass;
  results.repro_vector = LOCAL_repro_vector(results);
  results.reproducibility = LOCAL_compare_previous(previous, results.repro_vector);

  LOCAL_write_outputs(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results');
  LOCAL_write_reproducibility(results, output_dir);

  fprintf('A0 pass: %d\n', a0.pass);
  fprintf('Case A pass: %d\n', case_a.pass);
  fprintf('Case B pass: %d\n', case_b.pass);
  fprintf('Negative case pass: %d\n', negative_cases.pass);
  fprintf('Ledger pass: %d\n', ledger_pass);
  fprintf('GO: %d\n', all_pass);
end

%% ==================== Configuration ====================
% These helpers define the frozen cases, tolerances, and representation ledger.

function config = LOCAL_config(repo_root, output_dir, here)
  config.repo_root = repo_root;
  config.output_dir = output_dir;
  config.levels = 0:6;
  config.N_values = 2 .^ config.levels;
  config.closures = {'zero', 'dirichlet', 'robin'};
  config.zeta = 0.7;
  config.resonant_zeta = 1;
  config.qz_pair_tol = 1e-12;
  config.unit_gap_min = 0.1;
  config.rcond_min = 1e-10;
  config.a_qp_rcond_min = 1e-2;
  config.solve_residual_max = 1e-11;
  config.qz_residual_max = 1e-10;
  config.a0_error_max = 1e-11;
  config.associativity_error_max = 1e-10;
  config.analytic_error_max = 1e-10;
  config.edc_error_max = 1e-8;
  config.nonwood_gamma_min = 0.1;
  config.command = sprintf([ ...
    'perl -e ''alarm shift; exec @ARGV'' 1800 conda run -n octave ', ...
    'octave --quiet --no-gui --eval "addpath(''%s/test/hg-map''); ', ...
    'results=run_hg_map_experiment();"'], repo_root);
  source_paths = { ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'half_guide_map.md'), ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'SYMBOL.md'), ...
    fullfile(repo_root, '+bloch', 'construct_S.m'), ...
    fullfile(here, 'hg_map_experiment.m')};
  source_names = {'half_guide_map', 'SYMBOL', 'construct_S', 'experiment'};
  for j = 1:length(source_paths)
    config.source_hashes.(source_names{j}).path = source_paths{j};
    config.source_hashes.(source_names{j}).sha256 = ...
      LOCAL_source_hash(source_paths{j});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fingerprint = LOCAL_fingerprint(case_name, S, channels, walls, ...
    Gamma, zeta)
  gamma = channels.gamma_m(:);
  m = channels.m(:);
  C_zero = zeros(S.K);
  C_dirichlet = -eye(S.K);
  C_robin = LOCAL_terminal_matrix('robin', Gamma, zeta);
  fingerprint = sprintf(['case=%s;K=%d;block_order=RL,TRL;TLR,RR;', ...
    'm=%s;gamma_re=%s;gamma_im=%s;phase_origin=walls;', ...
    'basis=rayleigh_unit_amplitude;scaling=none;walls=[%.17g,%.17g];', ...
    'C0=%s;CD=%s;CR_re=%s;CR_im=%s'], ...
    case_name, S.K, mat2str(m.'), mat2str(real(gamma.'), 17), ...
    mat2str(imag(gamma.'), 17), walls(1), walls(2), mat2str(C_zero, 17), ...
    mat2str(C_dirichlet, 17), mat2str(real(C_robin), 17), ...
    mat2str(imag(C_robin), 17));
end

%% ==================== Algebra oracle ====================
% These helpers run direct noncommuting composition, terminal, and Cayley tests.

function [result, ledger] = LOCAL_run_a0(config, ledger)
  A = LOCAL_a0_segment_a();
  B = LOCAL_a0_segment_b();
  C = A;

  [AB, info_ab] = LOCAL_star(A, B);
  ledger = LOCAL_add_star_rows(ledger, 'A0', 0, 2, 'AB', info_ab, config);
  [direct, ~] = LOCAL_direct_compose(A, B);
  block_error = LOCAL_scattering_error(AB, direct);

  [AB_C, info_left] = LOCAL_star(AB, C);
  ledger = LOCAL_add_star_rows(ledger, 'A0', 0, 3, '(AB)A', info_left, config);
  [BC, info_bc] = LOCAL_star(B, C);
  ledger = LOCAL_add_star_rows(ledger, 'A0', 0, 2, 'BA', info_bc, config);
  [A_BC, info_right] = LOCAL_star(A, BC);
  ledger = LOCAL_add_star_rows(ledger, 'A0', 0, 3, 'A(BA)', info_right, config);
  associativity_error = LOCAL_scattering_error(AB_C, A_BC);

  Gamma0 = diag([0.7 + 0.2i, 1.3 + 0.1i]);
  closure_names = config.closures;
  terminal_error = 0;
  cayley_residual = 0;
  for ic = 1:length(closure_names)
    name = closure_names{ic};
    terminal_C = LOCAL_terminal_matrix(name, Gamma0, config.zeta);
    for side_cell = {'right', 'left'}
      side = side_cell{1};
      [Rhat, terminal_info] = LOCAL_terminal_map(AB, terminal_C, side, ...
        config.rcond_min);
      ledger = LOCAL_add_terminal_rows(ledger, 'A0', 0, 2, side, name, ...
        terminal_info, config);
      terminal_error = max(terminal_error, terminal_info.raw_error);
      [~, cayley_info] = LOCAL_cayley(Rhat, Gamma0);
      ledger = LOCAL_add_matrix_row(ledger, 'A0', 0, 2, side, name, ...
        'I_plus_Rhat', cayley_info.factor, cayley_info.residual, ...
        config.rcond_min, config.solve_residual_max);
      cayley_residual = max(cayley_residual, cayley_info.residual);
    end
  end

  Rhat0 = [0.10, 0.20; -0.05i, 0.15];
  trace_A = eye(2);
  D = (eye(2) + Rhat0) * trace_A;
  N = 1i * Gamma0 * (eye(2) - Rhat0) * trace_A;
  [Lambda, oracle_info] = LOCAL_cayley(Rhat0, Gamma0);
  trace_error = LOCAL_relerr(Lambda * D, N);
  reversed = 1i * LOCAL_right_solve(eye(2) - Rhat0, eye(2) + Rhat0) * Gamma0;
  reversed_error = LOCAL_relerr(reversed * D, N);
  ledger = LOCAL_add_matrix_row(ledger, 'A0', 0, 1, 'trace', 'oracle', ...
    'I_plus_Rhat_oracle', oracle_info.factor, oracle_info.residual, ...
    config.rcond_min, config.solve_residual_max);

  result.block_error = block_error;
  result.associativity_error = associativity_error;
  result.terminal_error = terminal_error;
  result.cayley_residual = cayley_residual;
  result.trace_error = trace_error;
  result.reversed_error = reversed_error;
  result.pass = block_error <= config.a0_error_max && ...
    associativity_error <= config.associativity_error_max && ...
    terminal_error <= config.a0_error_max && ...
    cayley_residual <= config.solve_residual_max && ...
    trace_error <= config.a0_error_max && reversed_error > 1e-3;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = LOCAL_a0_segment_a()
  S.R_L = [0.10 + 0.02i, 0.03; -0.02i, 0.08 - 0.01i];
  S.R_R = [0.05, -0.02 + 0.01i; 0.04, 0.07];
  S.T_LR = [0.85, 0.06 - 0.02i; -0.03 + 0.01i, 0.80];
  S.T_RL = [0.82, -0.04i; 0.05 + 0.02i, 0.78];
  S.K = 2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = LOCAL_a0_segment_b()
  S.R_L = [0.06 - 0.01i, -0.03; 0.02 + 0.04i, 0.09];
  S.R_R = [0.07, 0.01 + 0.03i; -0.04, 0.05 + 0.02i];
  S.T_LR = [0.79, 0.02 + 0.03i; -0.05i, 0.83];
  S.T_RL = [0.81, -0.02 + 0.01i; 0.04, 0.77];
  S.K = 2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [direct, info] = LOCAL_direct_compose(A, B)
  K = A.K;
  I = eye(K);
  interface_matrix = [I, -A.R_R; -B.R_L, I];
  exterior_input = eye(2 * K);
  rhs = [A.T_LR, zeros(K); zeros(K), B.T_RL] * exterior_input;
  [internal, solve_residual] = LOCAL_left_solve(interface_matrix, rhs);
  a_interface = internal(1:K, :);
  b_interface = internal(K + 1:end, :);
  b_left = A.R_L * exterior_input(1:K, :) + A.T_RL * b_interface;
  a_right = B.T_LR * a_interface + B.R_R * exterior_input(K + 1:end, :);
  S_all = [b_left; a_right];
  direct.R_L = S_all(1:K, 1:K);
  direct.T_RL = S_all(1:K, K + 1:end);
  direct.T_LR = S_all(K + 1:end, 1:K);
  direct.R_R = S_all(K + 1:end, K + 1:end);
  direct.K = K;
  info.factor = interface_matrix;
  info.residual = solve_residual;
end

%% ==================== Exact analytic case ====================
% These helpers validate both half-guide maps against closed-form answers.

function [result, ledger] = LOCAL_run_case_a(config, ledger)
  rho = [0.6, 0.8];
  S = struct();
  S.R_L = 1i * diag(rho);
  S.R_R = S.R_L;
  S.T_LR = diag(sqrt(1 - rho .^ 2));
  S.T_RL = S.T_LR;
  S.K = 2;
  Gamma = diag([1, 2]);
  channels.K = 2;
  channels.m = [0; 1];
  channels.gamma_m = diag(Gamma);
  walls = [-0.5, 0.5];
  fingerprint = LOCAL_fingerprint('A', S, channels, walls, Gamma, config.zeta);

  [qz_ref, ledger] = LOCAL_qz_reference('A', S, config, ledger);
  qz_ref.exact_multiplier_error = LOCAL_exact_multiplier_error( ...
    qz_ref.lambda_stable, qz_ref.lambda_unstable, [1 / 2; 1 / 3], [2; 3]);
  exact_R = 1i * eye(2);
  qz_ref.exact_map_error = max(LOCAL_relerr(qz_ref.R_plus, exact_R), ...
    LOCAL_relerr(qz_ref.R_minus, exact_R));
  [qz_ref, ledger] = LOCAL_add_qz_cayley_reference( ...
    'A', qz_ref, Gamma, ledger, config);
  qz_ref.exact_dtn_error = max(LOCAL_relerr(qz_ref.Lambda_plus, Gamma), ...
    LOCAL_relerr(qz_ref.Lambda_minus, Gamma));

  [closure_rows, level_rows, final_maps, ledger] = LOCAL_doubling_run( ...
    'A', S, Gamma, qz_ref, config, ledger);
  final_error = max([closure_rows([closure_rows.N] == 64).map_error, ...
    closure_rows([closure_rows.N] == 64).dtn_error]);
  closure_spread = LOCAL_closure_spread(final_maps);
  monotone_pass = LOCAL_monotonicity_pass(closure_rows, config);
  fingerprint_check = strcmp(fingerprint, ...
    LOCAL_fingerprint('A', S, channels, walls, Gamma, config.zeta));

  result.fingerprint = fingerprint;
  result.one_cell = S;
  result.Gamma = Gamma;
  result.qz = qz_ref;
  result.closure_rows = closure_rows;
  result.level_rows = level_rows;
  result.final_error = final_error;
  result.closure_spread = closure_spread;
  result.monotone_pass = monotone_pass;
  result.pass = qz_ref.pass && ...
    qz_ref.exact_multiplier_error <= config.analytic_error_max && ...
    qz_ref.exact_map_error <= config.analytic_error_max && ...
    qz_ref.exact_dtn_error <= config.analytic_error_max && ...
    final_error <= config.analytic_error_max && ...
    closure_spread <= config.analytic_error_max && monotone_pass && fingerprint_check;
end

%% ==================== Real EDC case ====================
% These helpers construct the frozen physical cell and its Wood-point negative.

function [result, ledger] = LOCAL_run_case_b(config, ledger)
  beta = 0.8;
  kext = 0.10;
  nref = 3;
  kint = nref * kext;
  radius = 0.4;
  L = 2;
  d = 2 * pi;
  M = 7;
  ntot = 60;
  X_L = -1;
  X_R = 1;

  pars1.k = kext;
  pars1.beta = beta;
  pars1.d = d;
  pars1.periodic_axis = 'y';
  pars2.H = 1.8;
  pars2.proxy_dist = 0.7;
  pars2.N_side = 40;
  pars2.N_top = 40;
  pars2.N_proxy_edge = 24;
  pars2.M_pw = 8;

  channels = bloch.rayleigh_channels(kext, beta, d, M, L);
  min_abs_gamma = min(abs(channels.gamma_m));
  nonwood_pass = min_abs_gamma >= config.nonwood_gamma_min;
  if ~nonwood_pass
    error('hg_map_experiment:UnexpectedWoodPoint', ...
      'Case B failed its non-Wood gate before BIE construction.');
  end
  [geom, curvelen, ~, ~] = geom.construct_cont(ntot, 'circle', 0, 0, radius);
  proxy = kernel.precomp_proxy(pars1, pars2);
  S_bloch = bloch.construct_S(geom, kext, kint, pars1, proxy, curvelen, ...
    channels, X_L, X_R);
  S = LOCAL_blocks(S_bloch);

  a_qp_rcond = rcond(S_bloch.A_QP);
  bie_residual = S_bloch.solve_relative_residual_norm;
  a_qp_status = LOCAL_pass_label(a_qp_rcond >= config.a_qp_rcond_min && ...
    bie_residual <= 1e-10);
  ledger = LOCAL_add_row(ledger, 'B', -1, 1, 'cell', 'bie', 'A_QP', ...
    LOCAL_size_label(S_bloch.A_QP), a_qp_rcond, bie_residual, ...
    config.a_qp_rcond_min, a_qp_status);

  Gamma = diag(channels.gamma_m(:));
  fingerprint = LOCAL_fingerprint('B', S, channels, [X_L, X_R], ...
    Gamma, config.zeta);
  [qz_ref, ledger] = LOCAL_qz_reference('B', S, config, ledger);
  [qz_ref, ledger] = LOCAL_add_qz_cayley_reference( ...
    'B', qz_ref, Gamma, ledger, config);
  [closure_rows, level_rows, final_maps, ledger] = LOCAL_doubling_run( ...
    'B', S, Gamma, qz_ref, config, ledger);
  final_error = max([closure_rows([closure_rows.N] == 64).map_error, ...
    closure_rows([closure_rows.N] == 64).dtn_error]);
  closure_spread = LOCAL_closure_spread(final_maps);
  monotone_pass = LOCAL_monotonicity_pass(closure_rows, config);
  fingerprint_check = strcmp(fingerprint, ...
    LOCAL_fingerprint('B', S, channels, [X_L, X_R], Gamma, config.zeta));

  result.fingerprint = fingerprint;
  result.one_cell = S;
  result.Gamma = Gamma;
  result.min_abs_gamma = min_abs_gamma;
  result.a_qp_rcond = a_qp_rcond;
  result.bie_residual = bie_residual;
  result.qz = qz_ref;
  result.closure_rows = closure_rows;
  result.level_rows = level_rows;
  result.final_error = final_error;
  result.closure_spread = closure_spread;
  result.monotone_pass = monotone_pass;
  result.pass = nonwood_pass && a_qp_rcond >= config.a_qp_rcond_min && ...
    bie_residual <= 1e-10 && qz_ref.pass && ...
    final_error <= config.edc_error_max && ...
    closure_spread <= config.edc_error_max && monotone_pass && fingerprint_check;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [negative, ledger] = LOCAL_run_negative_cases(config, a0, ledger)
  rows = LOCAL_empty_negative_rows();

  channels = bloch.rayleigh_channels(0.20, 0.8, 2 * pi, 7, 2);
  min_abs_gamma = min(abs(channels.gamma_m));
  wood_pass = min_abs_gamma < config.nonwood_gamma_min;
  rows(end + 1) = LOCAL_negative_row('B_WOOD', 0.20, min_abs_gamma, NaN, ...
    NaN, 'WOOD_POINT', 'CELL_BIE_POLE_RISK', ...
    'USER_SUPPLIED_PRIOR_SCREENING', false, false, false, false, false, ...
    NaN, NaN, NaN, min_abs_gamma, wood_pass); %#ok<AGROW>

  Gamma = diag([1, 2]);
  resonant_C = LOCAL_terminal_matrix('robin', Gamma, config.resonant_zeta);
  exact_R = 1i * eye(2);
  resonance_gate = LOCAL_terminal_gate(exact_R, resonant_C, config.rcond_min);
  resonance_row = LOCAL_negative_row('A_ROBIN_RESONANCE', NaN, NaN, ...
    config.resonant_zeta, resonance_gate.primary_rcond, ...
    'TERMINAL_RESONANCE', 'DOWNSTREAM_UNAVAILABLE', ...
    'PRESERVED_FIRST_SMOKE_AND_EXACT_ORACLE', false, false, false, false, ...
    false, NaN, NaN, NaN, resonance_gate.primary_rcond, false);
  resonance_row.pass = ~resonance_gate.pass && ...
    resonance_gate.primary_rcond < config.rcond_min && ...
    ~resonance_row.qz_available && ~resonance_row.map_available && ...
    ~resonance_row.dtn_available && ...
    ~resonance_row.qz_comparison_available && ...
    isnan(resonance_row.map_value) && isnan(resonance_row.dtn_value) && ...
    isnan(resonance_row.qz_comparison_value);
  rows(end + 1) = resonance_row; %#ok<AGROW>
  ledger = LOCAL_add_expected_resonance_rows(ledger, resonance_gate, config);

  convention_pass = a0.reversed_error > 1e-3;
  rows(end + 1) = LOCAL_negative_row('A0_CAYLEY_ORDER', NaN, NaN, NaN, ...
    NaN, 'REVERSED_CAYLEY_ORDER', 'DIRECT_TRACE_MISMATCH', ...
    'DETERMINISTIC_NONCOMMUTING_ORACLE', false, false, false, false, false, ...
    NaN, NaN, NaN, a0.reversed_error, convention_pass); %#ok<AGROW>

  negative.rows = rows;
  negative.robin_zeta = config.resonant_zeta;
  negative.pass = all([rows.pass]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_negative_rows()
  rows = struct('case_name', {}, 'k', {}, 'min_abs_gamma', {}, ...
    'robin_zeta', {}, 'factor_rcond', {}, 'primary_status', {}, ...
    'secondary_status', {}, 'provenance', {}, 'construct_S_called', {}, ...
    'qz_available', {}, 'map_available', {}, 'dtn_available', {}, ...
    'qz_comparison_available', {}, 'map_value', {}, 'dtn_value', {}, ...
    'qz_comparison_value', {}, 'observed_failure_metric', {}, 'pass', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_negative_row(case_name, k, min_abs_gamma, robin_zeta, ...
    factor_rcond, primary_status, secondary_status, provenance, ...
    construct_S_called, qz_available, map_available, dtn_available, ...
    qz_comparison_available, map_value, dtn_value, qz_comparison_value, ...
    observed_failure_metric, pass)
  row = struct('case_name', case_name, 'k', k, ...
    'min_abs_gamma', min_abs_gamma, 'robin_zeta', robin_zeta, ...
    'factor_rcond', factor_rcond, 'primary_status', primary_status, ...
    'secondary_status', secondary_status, 'provenance', provenance, ...
    'construct_S_called', construct_S_called, 'qz_available', qz_available, ...
    'map_available', map_available, 'dtn_available', dtn_available, ...
    'qz_comparison_available', qz_comparison_available, ...
    'map_value', map_value, 'dtn_value', dtn_value, ...
    'qz_comparison_value', qz_comparison_value, ...
    'observed_failure_metric', observed_failure_metric, 'pass', pass);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_add_expected_resonance_rows(ledger, gate, config)
  status = 'EXPECTED_TERMINAL_RESONANCE';
  ledger = LOCAL_add_row(ledger, 'A_ROBIN_RESONANCE', -1, Inf, 'right', ...
    'robin_zeta_1', 'terminal_primary', LOCAL_size_label(gate.primary), ...
    gate.primary_rcond, NaN, config.rcond_min, status);
  ledger = LOCAL_add_row(ledger, 'A_ROBIN_RESONANCE', -1, Inf, 'right', ...
    'robin_zeta_1', 'terminal_paired', LOCAL_size_label(gate.paired), ...
    gate.paired_rcond, NaN, config.rcond_min, status);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = LOCAL_blocks(S_bloch)
  S.R_L = S_bloch.R_L;
  S.T_LR = S_bloch.T_LR;
  S.T_RL = S_bloch.T_RL;
  S.R_R = S_bloch.R_R;
  S.K = S_bloch.K;
end

%% ==================== Redheffer composition ====================
% These helpers compose adjacent cells and expose every internal solve factor.

function [AB, info] = LOCAL_star(A, B)
  LOCAL_validate_blocks(A);
  LOCAL_validate_blocks(B);
  K = A.K;
  if B.K ~= K
    error('hg_map_experiment:StarSizeMismatch', ...
      'Adjacent scattering matrices must use the same channel count.');
  end
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

  [direct, direct_info] = LOCAL_direct_compose(A, B);

  info.GA = GA;
  info.GB = GB;
  info.GA_residual = max(residual_tlr, residual_rr);
  info.GB_residual = residual_trl;
  info.direct_factor = direct_info.factor;
  info.direct_residual = direct_info.residual;
  info.direct_error = LOCAL_scattering_error(AB, direct);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_add_star_rows(ledger, case_name, level, N, tag, info, config)
  ledger = LOCAL_add_matrix_row(ledger, case_name, level, N, 'internal', ...
    'star', [tag, '_GA'], info.GA, info.GA_residual, config.rcond_min, ...
    config.solve_residual_max);
  ledger = LOCAL_add_matrix_row(ledger, case_name, level, N, 'internal', ...
    'star', [tag, '_GB'], info.GB, info.GB_residual, config.rcond_min, ...
    config.solve_residual_max);
  ledger = LOCAL_add_matrix_row(ledger, case_name, level, N, 'internal', ...
    'raw', [tag, '_raw_interface'], info.direct_factor, ...
    info.direct_residual, config.rcond_min, config.solve_residual_max);
  ledger = LOCAL_add_row(ledger, case_name, level, N, 'external', 'raw', ...
    [tag, '_response_match'], 'response', NaN, info.direct_error, ...
    config.a0_error_max, LOCAL_pass_label(info.direct_error <= config.a0_error_max));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function error_value = LOCAL_scattering_error(A, B)
  errors = [LOCAL_relerr(A.R_L, B.R_L), LOCAL_relerr(A.T_LR, B.T_LR), ...
    LOCAL_relerr(A.T_RL, B.T_RL), LOCAL_relerr(A.R_R, B.R_R)];
  error_value = max(errors);
end

%% ==================== Terminal and Cayley maps ====================
% These helpers impose far-end closures and convert reflection to DtN form.

function terminal_C = LOCAL_terminal_matrix(name, Gamma, zeta)
  K = size(Gamma, 1);
  if strcmp(name, 'zero')
    terminal_C = zeros(K);
  elseif strcmp(name, 'dirichlet')
    terminal_C = -eye(K);
  elseif strcmp(name, 'robin')
    terminal_C = (1i * Gamma - zeta * eye(K)) \ ...
      (1i * Gamma + zeta * eye(K));
  else
    error('hg_map_experiment:UnknownClosure', 'Unknown terminal closure.');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Rhat, info] = LOCAL_terminal_map(S, terminal_C, side, rcond_min)
  K = S.K;
  if strcmp(side, 'right')
    gate = LOCAL_terminal_gate(S.R_R, terminal_C, rcond_min);
    if ~gate.pass
      error('hg_map_experiment:TerminalResonance', ...
        'Terminal factor failed the shared reciprocal-condition gate.');
    end
    factor = gate.primary;
    [returned, residual] = LOCAL_left_solve(factor, terminal_C * S.T_LR);
    Rhat = S.R_L + S.T_RL * returned;

    paired_factor = gate.paired;
    [far_outgoing, paired_residual] = LOCAL_left_solve(paired_factor, S.T_LR);
    raw_Rhat = S.R_L + S.T_RL * terminal_C * far_outgoing;
  elseif strcmp(side, 'left')
    gate = LOCAL_terminal_gate(S.R_L, terminal_C, rcond_min);
    if ~gate.pass
      error('hg_map_experiment:TerminalResonance', ...
        'Terminal factor failed the shared reciprocal-condition gate.');
    end
    factor = gate.primary;
    [returned, residual] = LOCAL_left_solve(factor, terminal_C * S.T_RL);
    Rhat = S.R_R + S.T_LR * returned;

    paired_factor = gate.paired;
    [far_outgoing, paired_residual] = LOCAL_left_solve(paired_factor, S.T_RL);
    raw_Rhat = S.R_R + S.T_LR * terminal_C * far_outgoing;
  else
    error('hg_map_experiment:UnknownSide', 'Side must be left or right.');
  end
  info.factor = factor;
  info.residual = residual;
  info.paired_factor = paired_factor;
  info.paired_residual = paired_residual;
  info.raw_error = LOCAL_relerr(Rhat, raw_Rhat);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function gate = LOCAL_terminal_gate(R_far, terminal_C, rcond_min)
  K = size(R_far, 1);
  gate.primary = eye(K) - terminal_C * R_far;
  gate.paired = eye(K) - R_far * terminal_C;
  gate.primary_rcond = rcond(gate.primary);
  gate.paired_rcond = rcond(gate.paired);
  gate.pass = min(gate.primary_rcond, gate.paired_rcond) >= rcond_min;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_add_terminal_rows(ledger, case_name, level, N, ...
    side, closure, info, config)
  ledger = LOCAL_add_matrix_row(ledger, case_name, level, N, side, closure, ...
    'terminal_primary', info.factor, info.residual, config.rcond_min, ...
    config.solve_residual_max);
  ledger = LOCAL_add_matrix_row(ledger, case_name, level, N, side, closure, ...
    'terminal_paired', info.paired_factor, info.paired_residual, ...
    config.rcond_min, config.solve_residual_max);
  raw_status = LOCAL_pass_label(info.raw_error <= config.a0_error_max);
  ledger = LOCAL_add_row(ledger, case_name, level, N, side, closure, ...
    'terminal_raw_match', 'response', NaN, info.raw_error, ...
    config.a0_error_max, raw_status);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Lambda, info] = LOCAL_cayley(Rhat, Gamma)
  K = size(Rhat, 1);
  factor = eye(K) + Rhat;
  numerator = 1i * Gamma * (eye(K) - Rhat);
  [Lambda, residual] = LOCAL_right_solve_with_residual(numerator, factor);
  info.factor = factor;
  info.residual = residual;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [qz_ref, ledger] = LOCAL_add_qz_cayley_reference( ...
    case_name, qz_ref, Gamma, ledger, config)
  [qz_ref.Lambda_plus, cayley_plus] = LOCAL_cayley(qz_ref.R_plus, Gamma);
  [qz_ref.Lambda_minus, cayley_minus] = LOCAL_cayley(qz_ref.R_minus, Gamma);
  ledger = LOCAL_add_matrix_row(ledger, case_name, -1, Inf, 'right', ...
    'qz', 'I_plus_Rhat', cayley_plus.factor, cayley_plus.residual, ...
    config.rcond_min, config.solve_residual_max);
  ledger = LOCAL_add_matrix_row(ledger, case_name, -1, Inf, 'left', ...
    'qz', 'I_plus_Rhat', cayley_minus.factor, cayley_minus.residual, ...
    config.rcond_min, config.solve_residual_max);
end

%% ==================== Ordered generalized Schur reference ====================
% These helpers independently form and order the scattering pencil twice.

function [qz_ref, ledger] = LOCAL_qz_reference(case_name, S, config, ledger)
  LOCAL_validate_blocks(S);
  K = S.K;
  I = eye(K);
  Z0 = zeros(K);
  A_sc = [-S.R_L, I; S.T_LR, Z0];
  B_sc = [Z0, S.T_RL; I, -S.R_R];

  [S0, T0] = qz(A_sc, B_sc, 'complex');
  classification = LOCAL_classify_qz(diag(S0), diag(T0), A_sc, B_sc, config);
  pencil_pass = classification.indeterminate_count == 0 && ...
    classification.infinite_count == 0 && classification.neutral_count == 0 && ...
    classification.stable_count == K && classification.unstable_count == K && ...
    classification.min_unit_gap >= config.unit_gap_min;
  ledger = LOCAL_add_row(ledger, case_name, -1, 1, 'pencil', 'qz', ...
    'QZ_pencil_status', sprintf('%dx%d', 2 * K, 2 * K), NaN, ...
    classification.min_unit_gap, config.unit_gap_min, LOCAL_pass_label(pencil_pass));

  stable = LOCAL_ordered_qz_pass(A_sc, B_sc, 'stable', K, config);
  unstable = LOCAL_ordered_qz_pass(A_sc, B_sc, 'unstable', K, config);

  A_stable = stable.Z(1:K, :);
  B_stable = stable.Z(K + 1:end, :);
  [R_plus, graph_plus_residual] = LOCAL_right_solve_with_residual(B_stable, A_stable);
  A_unstable = unstable.Z(1:K, :);
  B_unstable = unstable.Z(K + 1:end, :);
  [R_minus, graph_minus_residual] = LOCAL_right_solve_with_residual(A_unstable, B_unstable);
  ledger = LOCAL_add_matrix_row(ledger, case_name, -1, Inf, 'right', 'qz', ...
    'A_stable_graph', A_stable, graph_plus_residual, config.rcond_min, ...
    config.solve_residual_max);
  ledger = LOCAL_add_matrix_row(ledger, case_name, -1, Inf, 'left', 'qz', ...
    'B_unstable_graph', B_unstable, graph_minus_residual, config.rcond_min, ...
    config.solve_residual_max);

  factor_plus = I - R_plus * S.R_R;
  [fixed_term_plus, fixed_solve_plus] = LOCAL_left_solve( ...
    factor_plus, R_plus * S.T_LR);
  fixed_residual_plus = LOCAL_relerr( ...
    R_plus, S.R_L + S.T_RL * fixed_term_plus);
  factor_minus = I - R_minus * S.R_L;
  [fixed_term_minus, fixed_solve_minus] = LOCAL_left_solve( ...
    factor_minus, R_minus * S.T_RL);
  fixed_residual_minus = LOCAL_relerr( ...
    R_minus, S.R_R + S.T_LR * fixed_term_minus);
  ledger = LOCAL_add_matrix_row(ledger, case_name, -1, Inf, 'right', 'qz', ...
    'I_minus_Rplus_RR', factor_plus, fixed_solve_plus, config.rcond_min, ...
    config.solve_residual_max);
  ledger = LOCAL_add_matrix_row(ledger, case_name, -1, Inf, 'left', 'qz', ...
    'I_minus_Rminus_RL', factor_minus, fixed_solve_minus, config.rcond_min, ...
    config.solve_residual_max);

  ordered_residuals = [stable.residual_A, stable.residual_B, ...
    unstable.residual_A, unstable.residual_B];
  qz_ref.K = K;
  qz_ref.A_sc = A_sc;
  qz_ref.B_sc = B_sc;
  qz_ref.lambda_stable = stable.lambda;
  qz_ref.lambda_unstable = unstable.lambda;
  qz_ref.R_plus = R_plus;
  qz_ref.R_minus = R_minus;
  qz_ref.stable_count = classification.stable_count;
  qz_ref.unstable_count = classification.unstable_count;
  qz_ref.infinite_count = classification.infinite_count;
  qz_ref.indeterminate_count = classification.indeterminate_count;
  qz_ref.neutral_count = classification.neutral_count;
  qz_ref.min_unit_gap = classification.min_unit_gap;
  qz_ref.rcond_A_stable = rcond(A_stable);
  qz_ref.rcond_B_unstable = rcond(B_unstable);
  qz_ref.ordered_residuals = ordered_residuals;
  qz_ref.fixed_residual_plus = fixed_residual_plus;
  qz_ref.fixed_residual_minus = fixed_residual_minus;
  qz_ref.fixed_solve_plus = fixed_solve_plus;
  qz_ref.fixed_solve_minus = fixed_solve_minus;
  qz_ref.pass = pencil_pass && min([qz_ref.rcond_A_stable, ...
    qz_ref.rcond_B_unstable, rcond(factor_plus), rcond(factor_minus)]) >= ...
    config.rcond_min && max(ordered_residuals) <= config.qz_residual_max && ...
    max(fixed_residual_plus, fixed_residual_minus) <= config.qz_residual_max && ...
    max([graph_plus_residual, graph_minus_residual, fixed_solve_plus, ...
    fixed_solve_minus]) <= config.solve_residual_max;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function classification = LOCAL_classify_qz(alpha, beta, A_sc, B_sc, config)
  pair_scale = abs(alpha) + abs(beta);
  global_scale = config.qz_pair_tol * max([1, norm(A_sc, 'fro'), ...
    norm(B_sc, 'fro')]);
  indeterminate = pair_scale <= global_scale;
  infinite = ~indeterminate & abs(beta) <= ...
    config.qz_pair_tol .* max(abs(alpha), abs(beta));
  finite = ~indeterminate & ~infinite;
  lambda = NaN(size(alpha));
  lambda(finite) = alpha(finite) ./ beta(finite);
  neutral = finite & abs(abs(lambda) - 1) <= config.qz_pair_tol;
  stable = finite & abs(lambda) < 1 & ~neutral;
  unstable = finite & abs(lambda) > 1 & ~neutral;
  if any(finite)
    min_unit_gap = min(abs(abs(lambda(finite)) - 1));
  else
    min_unit_gap = NaN;
  end
  classification.lambda = lambda;
  classification.stable = stable;
  classification.unstable = unstable;
  classification.neutral = neutral;
  classification.stable_count = sum(stable);
  classification.unstable_count = sum(unstable);
  classification.neutral_count = sum(neutral);
  classification.infinite_count = sum(infinite);
  classification.indeterminate_count = sum(indeterminate);
  classification.min_unit_gap = min_unit_gap;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_ordered_qz_pass(A_sc, B_sc, selected_set, K, config)
  [S0, T0, Q0, Z0] = qz(A_sc, B_sc, 'complex');
  flags = LOCAL_classify_qz(diag(S0), diag(T0), A_sc, B_sc, config);
  if strcmp(selected_set, 'stable')
    select = flags.stable;
  elseif strcmp(selected_set, 'unstable')
    select = flags.unstable;
  else
    error('hg_map_experiment:UnknownQZSelection', 'Unknown QZ selected set.');
  end
  if sum(select) ~= K
    error('hg_map_experiment:QZCount', ...
      'Ordered QZ pass did not find exactly K selected eigenvalues.');
  end
  [S_ordered, T_ordered, Q_ordered, Z_ordered] = ...
    ordqz(S0, T0, Q0, Z0, select);
  S_lead = S_ordered(1:K, 1:K);
  T_lead = T_ordered(1:K, 1:K);
  Z_lead = Z_ordered(:, 1:K);
  Q_lead = LOCAL_qz_left_block(A_sc, B_sc, Z_lead, S_lead, ...
    T_lead, Q_ordered, K);
  residual_A = norm(A_sc * Z_lead - Q_lead * S_lead, 'fro') / ...
    max(1, norm(A_sc, 'fro') * norm(Z_lead, 'fro') + norm(S_lead, 'fro'));
  residual_B = norm(B_sc * Z_lead - Q_lead * T_lead, 'fro') / ...
    max(1, norm(B_sc, 'fro') * norm(Z_lead, 'fro') + norm(T_lead, 'fro'));
  pass.Z = Z_lead;
  pass.Q = Q_lead;
  pass.S = S_lead;
  pass.T = T_lead;
  pass.lambda = diag(S_lead) ./ diag(T_lead);
  pass.residual_A = residual_A;
  pass.residual_B = residual_B;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Q_lead = LOCAL_qz_left_block(A_sc, B_sc, Z_lead, S_lead, ...
    T_lead, Q_ordered, K)
  candidate_matlab = Q_ordered(:, 1:K);
  Q_transpose = Q_ordered';
  candidate_octave = Q_transpose(:, 1:K);
  score_matlab = norm(A_sc * Z_lead - candidate_matlab * S_lead, 'fro') + ...
    norm(B_sc * Z_lead - candidate_matlab * T_lead, 'fro');
  score_octave = norm(A_sc * Z_lead - candidate_octave * S_lead, 'fro') + ...
    norm(B_sc * Z_lead - candidate_octave * T_lead, 'fro');
  if score_matlab <= score_octave
    Q_lead = candidate_matlab;
  else
    Q_lead = candidate_octave;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function error_value = LOCAL_exact_multiplier_error(stable, unstable, ...
    exact_stable, exact_unstable)
  stable = stable(:);
  unstable = unstable(:);
  [~, stable_order] = sort(abs(stable));
  [~, exact_stable_order] = sort(abs(exact_stable));
  [~, unstable_order] = sort(abs(unstable));
  [~, exact_unstable_order] = sort(abs(exact_unstable));
  error_value = max(LOCAL_relerr(stable(stable_order), ...
    exact_stable(exact_stable_order)), LOCAL_relerr(unstable(unstable_order), ...
    exact_unstable(exact_unstable_order)));
end

%% ==================== Finite-section convergence ====================
% These helpers double cell sections and compare all closures with QZ maps.

function [closure_rows, level_rows, final_maps, ledger] = LOCAL_doubling_run( ...
    case_name, S_cell, Gamma, qz_ref, config, ledger)
  closure_rows = LOCAL_empty_closure_rows();
  level_rows = LOCAL_empty_level_rows();
  final_maps = struct();
  current = S_cell;
  for j = config.levels
    N = 2 ^ j;
    level_rows(end + 1) = struct( ...
      'case_name', case_name, 'level', j, 'N', N, ...
      'transmission_lr', norm(current.T_LR, 'fro'), ...
      'transmission_rl', norm(current.T_RL, 'fro'), ...
      'R_L', current.R_L, 'T_LR', current.T_LR, ...
      'T_RL', current.T_RL, 'R_R', current.R_R); %#ok<AGROW>

    for ic = 1:length(config.closures)
      closure = config.closures{ic};
      terminal_C = LOCAL_terminal_matrix(closure, Gamma, config.zeta);
      for side_cell = {'right', 'left'}
        side = side_cell{1};
        [Rhat, terminal_info] = LOCAL_terminal_map(current, terminal_C, side, ...
          config.rcond_min);
        ledger = LOCAL_add_terminal_rows(ledger, case_name, j, N, side, ...
          closure, terminal_info, config);
        [Lambda, cayley_info] = LOCAL_cayley(Rhat, Gamma);
        ledger = LOCAL_add_matrix_row(ledger, case_name, j, N, side, ...
          closure, 'I_plus_Rhat', cayley_info.factor, cayley_info.residual, ...
          config.rcond_min, config.solve_residual_max);
        if strcmp(side, 'right')
          R_reference = qz_ref.R_plus;
          Lambda_reference = qz_ref.Lambda_plus;
        else
          R_reference = qz_ref.R_minus;
          Lambda_reference = qz_ref.Lambda_minus;
        end
        closure_rows(end + 1) = struct( ...
          'case_name', case_name, 'level', j, 'N', N, ...
          'closure', closure, 'side', side, ...
          'map_error', LOCAL_relerr(Rhat, R_reference), ...
          'dtn_error', LOCAL_relerr(Lambda, Lambda_reference), ...
          'terminal_raw_error', terminal_info.raw_error, ...
          'terminal_rcond', rcond(terminal_info.factor), ...
          'cayley_rcond', rcond(cayley_info.factor), ...
          'map_R', Rhat, 'dtn_Lambda', Lambda, ...
          'terminal_C', terminal_C); %#ok<AGROW>
        if j == config.levels(end)
          key = [closure, '_', side];
          final_maps.(key).R = Rhat;
          final_maps.(key).Lambda = Lambda;
        end
      end
    end

    if j < config.levels(end)
      [current, star_info] = LOCAL_star(current, current);
      ledger = LOCAL_add_star_rows(ledger, case_name, j + 1, 2 * N, ...
        sprintf('double_%d_to_%d', N, 2 * N), star_info, config);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_closure_rows()
  rows = struct('case_name', {}, 'level', {}, 'N', {}, 'closure', {}, ...
    'side', {}, 'map_error', {}, 'dtn_error', {}, ...
    'terminal_raw_error', {}, 'terminal_rcond', {}, 'cayley_rcond', {}, ...
    'map_R', {}, 'dtn_Lambda', {}, 'terminal_C', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_level_rows()
  rows = struct('case_name', {}, 'level', {}, 'N', {}, ...
    'transmission_lr', {}, 'transmission_rl', {}, 'R_L', {}, ...
    'T_LR', {}, 'T_RL', {}, 'R_R', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function spread = LOCAL_closure_spread(final_maps)
  spread = 0;
  for side_cell = {'right', 'left'}
    side = side_cell{1};
    keys = {['zero_', side], ['dirichlet_', side], ['robin_', side]};
    for i = 1:3
      for j = i + 1:3
        spread = max(spread, LOCAL_relerr(final_maps.(keys{i}).R, ...
          final_maps.(keys{j}).R));
        spread = max(spread, LOCAL_relerr(final_maps.(keys{i}).Lambda, ...
          final_maps.(keys{j}).Lambda));
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_monotonicity_pass(rows, config)
  pass = true;
  for ic = 1:length(config.closures)
    closure = config.closures{ic};
    for side_cell = {'right', 'left'}
      side = side_cell{1};
      mask = strcmp({rows.closure}, closure) & strcmp({rows.side}, side);
      selected = rows(mask);
      [~, order] = sort([selected.N]);
      selected = selected(order);
      map_errors = [selected.map_error];
      dtn_errors = [selected.dtn_error];
      map_tail = map_errors(end - 2:end);
      dtn_tail = dtn_errors(end - 2:end);
      map_ok = map_tail(2) <= map_tail(1) + 1e-12 && ...
        map_tail(3) <= map_tail(2) + 1e-12;
      dtn_ok = dtn_tail(2) <= dtn_tail(1) + 1e-12 && ...
        dtn_tail(3) <= dtn_tail(2) + 1e-12;
      pass = pass && map_ok && dtn_ok;
    end
  end
end

%% ==================== Linear algebra and ledger ====================
% These helpers standardize right/left solves, errors, and pole-ledger rows.

function [X, residual] = LOCAL_left_solve(A, B)
  X = A \ B;
  residual = norm(A * X - B, 'fro') / max(1, norm(B, 'fro'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function X = LOCAL_right_solve(B, A)
  X = (A.' \ B.').';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [X, residual] = LOCAL_right_solve_with_residual(B, A)
  X = LOCAL_right_solve(B, A);
  residual = norm(X * A - B, 'fro') / max(1, norm(B, 'fro'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function error_value = LOCAL_relerr(actual, expected)
  error_value = norm(actual - expected, 'fro') / max(1, norm(expected, 'fro'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_blocks(S)
  names = {'R_L', 'T_LR', 'T_RL', 'R_R'};
  if ~(isstruct(S) && isfield(S, 'K') && isscalar(S.K) && ...
      isfinite(S.K) && S.K >= 1 && S.K == floor(S.K))
    error('hg_map_experiment:InvalidChannelCount', ...
      'Scattering data must have a positive integer channel count.');
  end
  for j = 1:length(names)
    block = S.(names{j});
    if ~isequal(size(block), [S.K, S.K]) || any(~isfinite(block(:)))
      error('hg_map_experiment:InvalidScatteringBlock', ...
        'Every scattering block must be finite and K-by-K.');
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_empty_ledger()
  ledger = struct('case_name', {}, 'level', {}, 'N', {}, 'side', {}, ...
    'closure', {}, 'factor', {}, 'size_label', {}, 'rcond_value', {}, ...
    'residual', {}, 'threshold', {}, 'status', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_add_matrix_row(ledger, case_name, level, N, side, ...
    closure, factor_name, factor, residual, rcond_min, residual_max)
  rcond_value = rcond(factor);
  status = LOCAL_pass_label(isfinite(rcond_value) && rcond_value >= rcond_min && ...
    isfinite(residual) && residual <= residual_max);
  ledger = LOCAL_add_row(ledger, case_name, level, N, side, closure, ...
    factor_name, LOCAL_size_label(factor), rcond_value, residual, ...
    rcond_min, status);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_add_row(ledger, case_name, level, N, side, closure, ...
    factor, size_label, rcond_value, residual, threshold, status)
  ledger(end + 1) = struct('case_name', case_name, 'level', level, ...
    'N', N, 'side', side, 'closure', closure, 'factor', factor, ...
    'size_label', size_label, 'rcond_value', rcond_value, ...
    'residual', residual, 'threshold', threshold, 'status', status);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = LOCAL_size_label(A)
  dims = size(A);
  label = sprintf('%dx%d', dims(1), dims(2));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = LOCAL_pass_label(pass)
  if pass
    label = 'PASS';
  else
    label = 'FAIL';
  end
end

%% ==================== Deterministic outputs ====================
% These helpers serialize the numerical evidence without plotting toolkits.

function previous = LOCAL_previous_result(output_dir)
  previous.available = false;
  previous.vector = [];
  result_file = fullfile(output_dir, 'results.mat');
  if exist(result_file, 'file') == 2
    loaded = load(result_file, 'results');
    if isfield(loaded, 'results') && isfield(loaded.results, 'repro_vector')
      previous.available = true;
      previous.vector = loaded.results.repro_vector;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function comparison = LOCAL_compare_previous(previous, current_vector)
  comparison.previous_available = previous.available;
  if previous.available && numel(previous.vector) == numel(current_vector)
    comparison.max_abs_difference = max(abs(previous.vector(:) - current_vector(:)));
    comparison.pass = comparison.max_abs_difference <= 1e-12;
    comparison.status = LOCAL_pass_label(comparison.pass);
  elseif previous.available
    comparison.max_abs_difference = Inf;
    comparison.pass = false;
    comparison.status = 'SIZE_MISMATCH';
  else
    comparison.max_abs_difference = NaN;
    comparison.pass = true;
    comparison.status = 'NO_BASELINE_FIRST_RUN';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function vector = LOCAL_repro_vector(results)
  vector = [results.a0.block_error; results.a0.associativity_error; ...
    results.a0.terminal_error; results.a0.trace_error; ...
    results.a0.reversed_error; results.case_a.final_error; ...
    results.case_a.closure_spread; results.case_a.qz.min_unit_gap; ...
    results.case_b.min_abs_gamma; results.case_b.a_qp_rcond; ...
    results.case_b.bie_residual; results.case_b.final_error; ...
    results.case_b.closure_spread; results.case_b.qz.min_unit_gap; ...
    double(results.all_pass)];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_outputs(results, output_dir)
  LOCAL_write_config(results, fullfile(output_dir, 'config.txt'));
  LOCAL_write_levels(results, fullfile(output_dir, 'levels.csv'));
  LOCAL_write_closures(results, fullfile(output_dir, 'closures.csv'));
  LOCAL_write_qz(results, fullfile(output_dir, 'qz-reference.csv'));
  LOCAL_write_ledger(results.pole_ledger, fullfile(output_dir, 'pole-ledger.csv'));
  LOCAL_write_negative(results.negative_cases, ...
    fullfile(output_dir, 'negative-cases.csv'));
  LOCAL_write_svg(results, fullfile(output_dir, 'convergence.svg'));
  LOCAL_write_report(results, fullfile(output_dir, 'report.md'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_config(results, filename)
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  c = results.config;
  fprintf(fid, 'experiment=half-guide-map-stage-1\n');
  fprintf(fid, 'levels=%s\n', mat2str(c.levels));
  fprintf(fid, 'N_values=%s\n', mat2str(c.N_values));
  fprintf(fid, 'closures=zero,dirichlet,robin\n');
  fprintf(fid, 'zeta=%.17g\n', c.zeta);
  fprintf(fid, 'resonant_negative_zeta=%.17g\n', c.resonant_zeta);
  fprintf(fid, 'qz_pair_tol=%.17g\n', c.qz_pair_tol);
  fprintf(fid, 'unit_gap_min=%.17g\n', c.unit_gap_min);
  fprintf(fid, 'rcond_min=%.17g\n', c.rcond_min);
  fprintf(fid, 'solve_residual_max=%.17g\n', c.solve_residual_max);
  fprintf(fid, 'qz_residual_max=%.17g\n', c.qz_residual_max);
  fprintf(fid, 'case_A_K=2\n');
  fprintf(fid, 'case_A_rho=0.6,0.8\n');
  fprintf(fid, 'case_A_gamma=1,2\n');
  fprintf(fid, ['case_B=beta:0.8,kext:0.10,n:3,kint:0.30,radius:0.4,', ...
    'L:2,d:2*pi,M:7,K:15,ntot:60,X_L:-1,X_R:1\n']);
  fprintf(fid, ['case_B_proxy=periodic_axis:y,H:1.8,proxy_dist:0.7,', ...
    'N_side:40,N_top:40,N_proxy_edge:24,M_pw:8,absorption:none\n']);
  fprintf(fid, 'case_A_fingerprint=%s\n', results.case_a.fingerprint);
  fprintf(fid, 'case_B_fingerprint=%s\n', results.case_b.fingerprint);
  fprintf(fid, 'construct_S_calls=1\n');
  fprintf(fid, 'solve_modes_calls=0\n');
  fprintf(fid, 'explicit_inv_calls=0\n');
  hash_names = fieldnames(c.source_hashes);
  for j = 1:length(hash_names)
    item = c.source_hashes.(hash_names{j});
    fprintf(fid, 'source_%s_path=%s\n', hash_names{j}, item.path);
    fprintf(fid, 'source_%s_sha256=%s\n', hash_names{j}, item.sha256);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_levels(results, filename)
  rows = [results.case_a.level_rows, results.case_b.level_rows];
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'case,level,N,transmission_lr_fro,transmission_rl_fro\n');
  for j = 1:length(rows)
    fprintf(fid, '%s,%d,%d,%.17g,%.17g\n', rows(j).case_name, ...
      rows(j).level, rows(j).N, rows(j).transmission_lr, ...
      rows(j).transmission_rl);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_closures(results, filename)
  rows = [results.case_a.closure_rows, results.case_b.closure_rows];
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case,level,N,closure,side,map_relative_error,', ...
    'dtn_relative_error,terminal_raw_error,terminal_rcond,cayley_rcond\n']);
  for j = 1:length(rows)
    fprintf(fid, '%s,%d,%d,%s,%s,%.17g,%.17g,%.17g,%.17g,%.17g\n', ...
      rows(j).case_name, rows(j).level, rows(j).N, rows(j).closure, ...
      rows(j).side, rows(j).map_error, rows(j).dtn_error, ...
      rows(j).terminal_raw_error, rows(j).terminal_rcond, rows(j).cayley_rcond);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_qz(results, filename)
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case,K,stable,unstable,infinite,indeterminate,neutral,', ...
    'min_unit_gap,rcond_As,rcond_Bu,rA_stable,rB_stable,rA_unstable,', ...
    'rB_unstable,fixed_plus,fixed_minus,pass\n']);
  for item = {results.case_a, results.case_b}
    q = item{1}.qz;
    fprintf(fid, ['%s,%d,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d\n'], ...
      item{1}.closure_rows(1).case_name, q.K, q.stable_count, ...
      q.unstable_count, q.infinite_count, q.indeterminate_count, ...
      q.neutral_count, q.min_unit_gap, q.rcond_A_stable, ...
      q.rcond_B_unstable, q.ordered_residuals(1), q.ordered_residuals(2), ...
      q.ordered_residuals(3), q.ordered_residuals(4), ...
      q.fixed_residual_plus, q.fixed_residual_minus, q.pass);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_ledger(ledger, filename)
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'case,level,N,side,closure,factor,size,rcond,residual,threshold,status\n');
  for j = 1:length(ledger)
    fprintf(fid, '%s,%g,%g,%s,%s,%s,%s,%.17g,%.17g,%.17g,%s\n', ...
      ledger(j).case_name, ledger(j).level, ledger(j).N, ledger(j).side, ...
      ledger(j).closure, ledger(j).factor, ledger(j).size_label, ...
      ledger(j).rcond_value, ledger(j).residual, ledger(j).threshold, ...
      ledger(j).status);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_negative(negative, filename)
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case,k,min_abs_gamma,robin_zeta,factor_rcond,primary_status,', ...
    'secondary_status,provenance,construct_S_called,qz_available,map_available,', ...
    'dtn_available,qz_comparison_available,map_value,dtn_value,', ...
    'qz_comparison_value,observed_failure_metric,pass\n']);
  for j = 1:length(negative.rows)
    row = negative.rows(j);
    fprintf(fid, ['%s,%.17g,%.17g,%.17g,%.17g,%s,%s,%s,%d,%d,%d,%d,%d,', ...
      '%.17g,%.17g,%.17g,%.17g,%d\n'], row.case_name, row.k, ...
      row.min_abs_gamma, row.robin_zeta, row.factor_rcond, ...
      row.primary_status, row.secondary_status, row.provenance, ...
      row.construct_S_called, row.qz_available, row.map_available, ...
      row.dtn_available, row.qz_comparison_available, row.map_value, ...
      row.dtn_value, row.qz_comparison_value, row.observed_failure_metric, ...
      row.pass);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, filename)
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  if results.all_pass
    verdict = 'GO';
  else
    verdict = 'NO-GO';
  end
  fprintf(fid, '# Half-guide map Stage 1 report\n\n');
  fprintf(fid, 'Verdict: **%s**.\n\n', verdict);
  fprintf(fid, '## Gate summary\n\n');
  fprintf(fid, '- A0 noncommuting algebra: %s.\n', LOCAL_pass_label(results.a0.pass));
  fprintf(fid, '- Exact analytic cell: %s.\n', LOCAL_pass_label(results.case_a.pass));
  fprintf(fid, '- Real EDC smoke point: %s.\n', LOCAL_pass_label(results.case_b.pass));
  fprintf(fid, '- Negative-case suite: %s.\n', ...
    LOCAL_pass_label(results.negative_cases.pass));
  fprintf(fid, '- Wood/BIE-risk stop: %s.\n', ...
    LOCAL_pass_label(results.negative_cases.rows(1).pass));
  fprintf(fid, '- Robin terminal-resonance stop: %s.\n', ...
    LOCAL_pass_label(results.negative_cases.rows(2).pass));
  fprintf(fid, '- Reversed Cayley-order rejection: %s.\n', ...
    LOCAL_pass_label(results.negative_cases.rows(3).pass));
  fprintf(fid, '- Pole/conditioning ledger: %s.\n\n', ...
    LOCAL_pass_label(~any(strcmp({results.pole_ledger.status}, 'FAIL'))));
  fprintf(fid, '## Key diagnostics\n\n');
  fprintf(fid, '- A0 direct composition error: %.6e.\n', results.a0.block_error);
  fprintf(fid, '- A0 associativity error: %.6e.\n', results.a0.associativity_error);
  fprintf(fid, '- A0 reversed-order trace residual: %.6e.\n', results.a0.reversed_error);
  fprintf(fid, '- Case A final maximum error: %.6e.\n', results.case_a.final_error);
  fprintf(fid, '- Case B minimum channel magnitude: %.6e.\n', ...
    results.case_b.min_abs_gamma);
  fprintf(fid, '- Case B BIE reciprocal condition estimate: %.6e.\n', ...
    results.case_b.a_qp_rcond);
  fprintf(fid, '- Case B final maximum error: %.6e.\n\n', ...
    results.case_b.final_error);
  fprintf(fid, '## Preserved pre-formal failure\n\n');
  fprintf(fid, ['The original Robin run with zeta equal to 1 is preserved in ', ...
    '[pilot-universal-terminal-gate](pilot-universal-terminal-gate/report.md). ', ...
    'Its apparent cancellation and map agreement are inadmissible because ', ...
    'the terminal factor is singular and the far condition selects the wrong branch.\n\n']);
  fprintf(fid, '## Claim boundary\n\n');
  fprintf(fid, ['The exact diagonal cell supplies independent algebraic gap truth. ', ...
    'The EDC computation is one real-frequency smoke point and a same-cell ', ...
    'finite-section versus ordered-QZ cross-check. It is not an independent ', ...
    'physical validation, a frequency-interval certification, or a limiting-absorption proof.\n']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_svg(results, filename)
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  width = 900;
  height = 430;
  fprintf(fid, ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" ', ...
    'height="%d" viewBox="0 0 %d %d">\n'], width, height, width, height);
  fprintf(fid, '<rect width="100%%" height="100%%" fill="white"/>\n');
  fprintf(fid, '<text x="450" y="28" text-anchor="middle" font-size="18">Half-guide map convergence</text>\n');
  LOCAL_svg_panel(fid, results.case_a.closure_rows, 55, 55, 370, 315, 'Case A');
  LOCAL_svg_panel(fid, results.case_b.closure_rows, 485, 55, 370, 315, 'Case B');
  fprintf(fid, '</svg>\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_svg_panel(fid, rows, x0, y0, width, height, title_text)
  fprintf(fid, '<rect x="%g" y="%g" width="%g" height="%g" fill="none" stroke="black"/>\n', ...
    x0, y0, width, height);
  fprintf(fid, '<text x="%g" y="%g" text-anchor="middle" font-size="15">%s</text>\n', ...
    x0 + width / 2, y0 - 10, title_text);
  colors = {'#1f77b4', '#d62728', '#2ca02c', '#9467bd', '#ff7f0e', '#17becf'};
  series_index = 0;
  closures = {'zero', 'dirichlet', 'robin'};
  sides = {'right', 'left'};
  for ic = 1:3
    for is = 1:2
      series_index = series_index + 1;
      mask = strcmp({rows.closure}, closures{ic}) & strcmp({rows.side}, sides{is});
      selected = rows(mask);
      [~, order] = sort([selected.N]);
      errors = max([selected(order).map_error], 1e-16);
      x = x0 + ((0:length(errors) - 1) / (length(errors) - 1)) * width;
      log_error = log10(errors);
      y = y0 + height * (1 - min(1, max(0, (-log_error) / 16)));
      points = '';
      for j = 1:length(x)
        points = [points, sprintf('%.3f,%.3f ', x(j), y(j))]; %#ok<AGROW>
      end
      fprintf(fid, '<polyline fill="none" stroke="%s" stroke-width="1.5" points="%s"/>\n', ...
        colors{series_index}, points);
    end
  end
  fprintf(fid, '<text x="%g" y="%g" text-anchor="middle" font-size="11">levels 0 through 6</text>\n', ...
    x0 + width / 2, y0 + height + 20);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_reproducibility(results, output_dir)
  filename = fullfile(output_dir, 'reproducibility.txt');
  fid = LOCAL_open_file(filename);
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'formal_command=%s\n', results.config.command);
  fprintf(fid, 'hard_timeout_seconds=1800\n');
  fprintf(fid, 'poll_interval_seconds=30_or_less\n');
  fprintf(fid, 'previous_available=%d\n', ...
    results.reproducibility.previous_available);
  fprintf(fid, 'comparison_status=%s\n', results.reproducibility.status);
  fprintf(fid, 'max_abs_difference=%.17g\n', ...
    results.reproducibility.max_abs_difference);
  fprintf(fid, 'current_vector=%s\n', mat2str(results.repro_vector.', 17));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fid = LOCAL_open_file(filename)
  fid = fopen(filename, 'w');
  if fid < 0
    error('hg_map_experiment:OutputOpenFailed', ...
      'Could not open output file %s.', filename);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function digest = LOCAL_source_hash(filename)
  command = sprintf('shasum -a 256 "%s"', filename);
  [status, output] = system(command);
  if status ~= 0
    error('hg_map_experiment:SourceHashFailed', ...
      'Could not hash source file %s.', filename);
  end
  tokens = strsplit(strtrim(output));
  digest = tokens{1};
end
