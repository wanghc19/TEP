function results = aug_bie_experiment()
% Purpose:
%   Validate the frozen Stage 2 augmented BIE assembly, density coordinate,
%   and conditional discrete Schur reduction.
%
% Main algorithm:
%   Run exact manufactured algebra and scaling oracles, assemble the corrected
%   ellipse-center/circle-lead interface smoke over doubled finite leads, and
%   exercise all mandatory shared-gate negative cases.
%
% Based on:
%   research/projects/eig-apost/implementation/aug-bie.md, version 1.0.
%
% Main changes:
%   This experiment retains all center and far amplitudes in the primary
%   n+8p matrix and uses the scaled density xi = D_h*eta.
%
% Numerical goal:
%   Establish only STAGE2_DISCRETE_ALGEBRA_GO.  No root search, Cayley map,
%   or physical kernel-field interpretation is performed.

  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(here));
  output_dir = fullfile(here, 'output');
  if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
  end
  addpath(repo_root);
  previous = LOCAL_previous(output_dir);

  diary('off');
  log_file = fullfile(output_dir, 'run.log');
  if exist(log_file, 'file') == 2
    delete(log_file);
  end
  diary(log_file);
  diary_cleanup = onCleanup(@() diary('off')); %#ok<NASGU>

  cfg = LOCAL_config(repo_root, here, output_dir);
  ledger = LOCAL_empty_ledger();
  representation_ledger = LOCAL_empty_representation_ledger();
  algebra_rows = LOCAL_empty_algebra_rows();
  kernel_rows = LOCAL_empty_kernel_rows();
  negative_rows = LOCAL_empty_negative_rows();

  fprintf('Augmented BIE Stage 2 experiment\n');
  fprintf('Representation: %s\n', cfg.representation_id);
  fprintf('Root ready: STOP\n');
  fprintf('Explicit inv/pinv calls: none\n');
  fprintf('bloch.solve_modes calls: none\n');

  [case_a1, ledger, algebra_rows, kernel_rows] = ...
    LOCAL_run_a1(cfg, ledger, algebra_rows, kernel_rows);
  [case_a2, algebra_rows, negative_rows] = ...
    LOCAL_run_a2(cfg, case_a1, algebra_rows, negative_rows);
  [case_b, ledger, representation_ledger, algebra_rows, kernel_rows] = ...
    LOCAL_run_actual(cfg, ledger, representation_ledger, algebra_rows, kernel_rows);
  [negative_cases, ledger, representation_ledger, negative_rows] = ...
    LOCAL_run_negatives(cfg, case_a1, case_b, ledger, ...
    representation_ledger, negative_rows);

  ledger_pass = ~any(strcmp({ledger.status}, 'FAIL'));
  representation_pass = ~any(strcmp({representation_ledger.status}, 'FAIL'));
  preliminary_pass = case_a1.pass && case_a2.pass && case_b.pass && ...
    negative_cases.pass && ledger_pass && representation_pass;

  results = struct();
  results.config = cfg;
  results.case_a1 = case_a1;
  results.case_a2 = case_a2;
  results.case_b = case_b;
  results.algebra = algebra_rows;
  results.kernel = kernel_rows;
  results.pole_ledger = ledger;
  results.representation_ledger = representation_ledger;
  results.negative_cases = negative_cases;
  results.root_ready = 'STOP';
  results.all_pass = preliminary_pass;
  results.repro_vector = LOCAL_repro_vector(results);
  results.reproducibility = LOCAL_compare_previous(previous, ...
    results.repro_vector, cfg.source_hashes);
  all_pass = preliminary_pass && results.reproducibility.pass && ...
    strcmp(results.reproducibility.status, 'REPRODUCED');
  results.all_pass = all_pass;
  if all_pass
    results.stage2_status = 'STAGE2_DISCRETE_ALGEBRA_GO';
  else
    results.stage2_status = 'STAGE2_DISCRETE_ALGEBRA_REVISE';
  end

  LOCAL_write_outputs(results, output_dir);
  save(fullfile(output_dir, 'results.mat'), 'results');
  LOCAL_write_reproducibility(results, output_dir);

  fprintf('A1 pass: %d\n', case_a1.pass);
  fprintf('A2 pass: %d\n', case_a2.pass);
  fprintf('Actual interface smoke pass: %d\n', case_b.pass);
  fprintf('Negative suite pass: %d\n', negative_cases.pass);
  fprintf('Ledger pass: %d\n', ledger_pass && representation_pass);
  fprintf('STAGE2_DISCRETE_ALGEBRA_GO: %d\n', all_pass);
  if all_pass
    fprintf('ALL TESTS PASS\n');
  else
    fprintf('TESTS FAILED\n');
  end
end

%% ==================== Configuration ====================
% These helpers freeze parameters, thresholds, and source provenance.

function cfg = LOCAL_config(repo_root, here, output_dir)
  cfg.repo_root = repo_root;
  cfg.output_dir = output_dir;
  cfg.representation_id = 'eig-apost-aug-bie-v1.0';
  cfg.levels = 0:6;
  cfg.algebra_tol = 1e-11;
  cfg.actual_schur_tol = 1e-10;
  cfg.incident_tol = 1e-12;
  cfg.bie_residual_tol = 1e-10;
  cfg.bie_rcond_min = 1e-2;
  cfg.rcond_min = 1e-10;
  cfg.gamma_min = 0.1;
  cfg.rank_factor = 1e-10;
  cfg.second_singular_min = 1e-4;
  cfg.participation_min = 1e-4;
  cfg.mutation_min = 1e-4;
  cfg.scaling_mutation_min = 1e-3;
  cfg.noncommutator_min = 1e-3;
  cfg.allowed_delta_tol = 1e-13;
  cfg.forbidden_delta_tol = 1e-14;
  cfg.beta = 0.8;
  cfg.kext = 0.10;
  cfg.kint = 0.30;
  cfg.nref = 3;
  cfg.radius = 0.4;
  cfg.ellipse_axes = [0.28, 0.21];
  cfg.L = 2;
  cfg.d = 2 * pi;
  cfg.M = 7;
  cfg.p = 15;
  cfg.ntot = 60;
  cfg.ntot_center = 60;
  cfg.walls = [-1, 1];
  cfg.command = sprintf([ ...
    'perl -e ''alarm shift; exec @ARGV'' 1800 conda run -n octave ', ...
    'octave --quiet --no-gui --eval "addpath(''%s/test/aug-bie''); ', ...
    'results=run_aug_bie_experiment();"'], repo_root);
  source_paths = { ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'aug-bie.md'), ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'SYMBOL.md'), ...
    fullfile(repo_root, '+op', 'construct_A_QP.m'), ...
    fullfile(repo_root, '+bloch', 'construct_S.m'), ...
    fullfile(repo_root, '+bloch', 'incident_rhs.m'), ...
    fullfile(repo_root, '+bloch', 'farfield_extractors.m'), ...
    fullfile(here, 'aug_bie_experiment.m'), ...
    fullfile(here, 'run_aug_bie_experiment.m')};
  source_names = {'aug_bie', 'SYMBOL', 'construct_A_QP', 'construct_S', ...
    'incident_rhs', 'farfield_extractors', 'experiment', 'wrapper'};
  for idx = 1:length(source_paths)
    cfg.source_hashes.(source_names{idx}).path = source_paths{idx};
    cfg.source_hashes.(source_names{idx}).sha256 = ...
      LOCAL_source_hash(source_paths{idx});
  end
end

%% ==================== Frozen layout and assembly ====================
% These helpers implement the primary nine-group matrix without elimination.

function layout = LOCAL_layout(n_density, p_channels)
  layout.n = n_density;
  layout.p = p_channels;
  layout.total = n_density + 8 * p_channels;
  layout.col.xi = 1:n_density;
  names = {'ac_minus', 'bc_plus', 'bc_minus', 'ac_plus', ...
    'af_minus', 'bf_minus', 'bf_plus', 'af_plus'};
  for idx = 1:8
    layout.col.(names{idx}) = n_density + (idx - 1) * p_channels + (1:p_channels);
  end
  layout.row.g1 = 1:n_density;
  for idx = 2:9
    layout.row.(['g', num2str(idx)]) = ...
      n_density + (idx - 2) * p_channels + (1:p_channels);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function F_aug = LOCAL_assemble_augmented(center, lead_minus, lead_plus)
  n = size(center.A_c, 1);
  p = size(center.B_L, 2);
  layout = LOCAL_layout(n, p);
  F_aug = zeros(layout.total);
  c = layout.col;
  r = layout.row;
  I = eye(p);

  F_aug(r.g1, c.xi) = center.A_c;
  F_aug(r.g1, c.ac_minus) = center.B_L;
  F_aug(r.g1, c.bc_plus) = center.B_R;
  F_aug(r.g2, c.xi) = -center.E_L;
  F_aug(r.g2, c.ac_minus) = -center.J_LL;
  F_aug(r.g2, c.bc_plus) = -center.J_LR;
  F_aug(r.g2, c.bc_minus) = I;
  F_aug(r.g3, c.xi) = -center.E_R;
  F_aug(r.g3, c.ac_minus) = -center.J_RL;
  F_aug(r.g3, c.bc_plus) = -center.J_RR;
  F_aug(r.g3, c.ac_plus) = I;

  F_aug(r.g4, c.bc_minus) = -lead_minus.T_RL;
  F_aug(r.g4, c.af_minus) = -lead_minus.R_L;
  F_aug(r.g4, c.bf_minus) = I;
  F_aug(r.g5, c.ac_minus) = I;
  F_aug(r.g5, c.bc_minus) = -lead_minus.R_R;
  F_aug(r.g5, c.af_minus) = -lead_minus.T_LR;
  F_aug(r.g6, c.af_minus) = I;
  F_aug(r.g6, c.bf_minus) = I;

  F_aug(r.g7, c.bc_plus) = I;
  F_aug(r.g7, c.ac_plus) = -lead_plus.R_L;
  F_aug(r.g7, c.bf_plus) = -lead_plus.T_RL;
  F_aug(r.g8, c.ac_plus) = -lead_plus.T_LR;
  F_aug(r.g8, c.bf_plus) = -lead_plus.R_R;
  F_aug(r.g8, c.af_plus) = I;
  F_aug(r.g9, c.bf_plus) = I;
  F_aug(r.g9, c.af_plus) = I;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function raw = LOCAL_raw_schur(F_aug, n_density, p_channels)
  layout = LOCAL_layout(n_density, p_channels);
  retained_cols = [layout.col.ac_minus, layout.col.bc_plus];
  retained_rows = [layout.row.g5, layout.row.g7];
  eliminated_cols = setdiff(1:layout.total, retained_cols, 'stable');
  eliminated_rows = setdiff(1:layout.total, retained_rows, 'stable');
  raw.K_ee = F_aug(eliminated_rows, eliminated_cols);
  raw.K_er = F_aug(eliminated_rows, retained_cols);
  raw.K_re = F_aug(retained_rows, eliminated_cols);
  raw.K_rr = F_aug(retained_rows, retained_cols);
  [eliminated_response, raw.solve_residual] = ...
    LOCAL_solve(raw.K_ee, raw.K_er);
  raw.F_schur = raw.K_rr - raw.K_re * eliminated_response;
  raw.retained_cols = retained_cols;
  raw.eliminated_cols = eliminated_cols;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function z = LOCAL_lift_reduced(raw, center_incoming, total_size)
  eliminated = -(raw.K_ee \ (raw.K_er * center_incoming));
  z = zeros(total_size, 1);
  z(raw.retained_cols) = center_incoming;
  z(raw.eliminated_cols) = eliminated;
end

%% ==================== Independent reduced oracle ====================
% These helpers consume primitive blocks and never inspect the raw matrix.

function reduced = LOCAL_reduced_oracle(center, lead_minus, lead_plus)
  p = size(center.B_L, 2);
  I = eye(p);
  rhs_center = [center.B_L, center.B_R];
  [H, reduced.center_solve_residual] = LOCAL_solve(center.A_c, -rhs_center);
  E_stack = [center.E_L; center.E_R];
  reduced.S_center = [center.J_LL, center.J_LR; ...
    center.J_RL, center.J_RR] + E_stack * H;
  reduced.R_Lc = reduced.S_center(1:p, 1:p);
  reduced.T_RLc = reduced.S_center(1:p, p + 1:end);
  reduced.T_LRc = reduced.S_center(p + 1:end, 1:p);
  reduced.R_Rc = reduced.S_center(p + 1:end, p + 1:end);

  reduced.terminal_minus = I + lead_minus.R_L;
  [left_return, reduced.left_solve_residual] = ...
    LOCAL_solve(reduced.terminal_minus, lead_minus.T_RL);
  reduced.Rhat_minus_D = lead_minus.R_R - lead_minus.T_LR * left_return;
  reduced.terminal_plus = I + lead_plus.R_R;
  [right_return, reduced.right_solve_residual] = ...
    LOCAL_solve(reduced.terminal_plus, lead_plus.T_LR);
  reduced.Rhat_plus_D = lead_plus.R_L - lead_plus.T_RL * right_return;
  reduced.Rhat_block_D = blkdiag(reduced.Rhat_minus_D, reduced.Rhat_plus_D);
  reduced.F_reduced = eye(2 * p) - reduced.Rhat_block_D * reduced.S_center;
end

%% ==================== Manufactured exact oracle A1 ====================
% These helpers construct and validate the exact noncommuting kernel fixture.

function [result, ledger, algebra_rows, kernel_rows] = ...
    LOCAL_run_a1(cfg, ledger, algebra_rows, kernel_rows)
  fixture = LOCAL_a1_fixture();
  a1_aux.density_scale = ones(4, 1);
  a1_descriptor = LOCAL_representation_descriptor(fixture.center, a1_aux, cfg);
  a1_options = LOCAL_availability_options();
  a1_availability = LOCAL_availability_gate(fixture.center, ...
    fixture.lead_minus, fixture.lead_plus, a1_descriptor, ...
    a1_descriptor, cfg, a1_options);
  F_aug = LOCAL_assemble_augmented(fixture.center, fixture.lead_minus, ...
    fixture.lead_plus);
  reduced = LOCAL_reduced_oracle(fixture.center, fixture.lead_minus, ...
    fixture.lead_plus);
  raw = LOCAL_raw_schur(F_aug, 4, 2);
  z_lift = LOCAL_lift_reduced(raw, fixture.x_star, size(F_aug, 1));

  aug_residual = LOCAL_relres0(F_aug, fixture.z_star);
  reduced_residual = LOCAL_relres0(reduced.F_reduced, fixture.x_star);
  schur_error = LOCAL_relmat(raw.F_schur, reduced.F_reduced);
  lift_error = LOCAL_direction_error(z_lift, fixture.z_star);
  [aug_nullity, aug_singular] = LOCAL_nullity(F_aug, cfg.rank_factor);
  [red_nullity, red_singular] = LOCAL_nullity(reduced.F_reduced, cfg.rank_factor);
  second_singular = aug_singular(end - 1) / max(1, norm(F_aug, 2));
  z_unit = fixture.z_star / norm(fixture.z_star);
  participation = LOCAL_participation(z_unit, 4, 2);
  participation_aggregate = [participation(1), ...
    norm(participation(2:5)), norm(participation(6:9))];
  noncommutator = LOCAL_relmat(fixture.Rhat_block_D * fixture.S_center, ...
    fixture.S_center * fixture.Rhat_block_D);

  wrong_order = eye(4) - fixture.S_center * fixture.Rhat_block_D;
  wrong_order_residual = LOCAL_relres0(wrong_order, fixture.x_star);
  wrong_center = fixture.center;
  wrong_center.J_LL = fixture.center.J_LR;
  wrong_center.J_LR = zeros(2);
  wrong_center.J_RL = zeros(2);
  wrong_center.J_RR = fixture.center.J_RL;
  wrong_J_residual = LOCAL_relres0(LOCAL_assemble_augmented( ...
    wrong_center, fixture.lead_minus, fixture.lead_plus), fixture.z_star);
  wrong_terminal = F_aug;
  layout = LOCAL_layout(4, 2);
  wrong_terminal(layout.row.g6, layout.col.bf_minus) = -eye(2);
  wrong_terminal_residual = LOCAL_relres0(wrong_terminal, fixture.z_star);
  swap_left = LOCAL_swap_transmissions(fixture.lead_minus);
  swap_right = LOCAL_swap_transmissions(fixture.lead_plus);
  swap_left_residual = LOCAL_relres0(LOCAL_assemble_augmented( ...
    fixture.center, swap_left, fixture.lead_plus), fixture.z_star);
  swap_right_residual = LOCAL_relres0(LOCAL_assemble_augmented( ...
    fixture.center, fixture.lead_minus, swap_right), fixture.z_star);
  swap_both_residual = LOCAL_relres0(LOCAL_assemble_augmented( ...
    fixture.center, swap_left, swap_right), fixture.z_star);
  side_swap_residual = LOCAL_relres0(LOCAL_assemble_augmented( ...
    fixture.center, fixture.lead_plus, fixture.lead_minus), fixture.z_star);

  direct_left_error = LOCAL_relmat(reduced.Rhat_minus_D, fixture.R_minus);
  direct_right_error = LOCAL_relmat(reduced.Rhat_plus_D, fixture.R_plus);
  direct_phase_left = LOCAL_relmat([fixture.center.J_LL; fixture.center.J_RL], ...
    [zeros(2); fixture.center.phase_center]);
  direct_phase_right = LOCAL_relmat([fixture.center.J_LR; fixture.center.J_RR], ...
    [fixture.center.phase_center; zeros(2)]);

  metrics = { ...
    'a1_augmented_residual', aug_residual, cfg.algebra_tol, '<='; ...
    'a1_reduced_residual', reduced_residual, cfg.algebra_tol, '<='; ...
    'a1_raw_schur_error', schur_error, cfg.algebra_tol, '<='; ...
    'a1_lift_direction_error', lift_error, cfg.algebra_tol, '<='; ...
    'a1_second_singular', second_singular, cfg.second_singular_min, '>'; ...
    'a1_density_participation', participation_aggregate(1), ...
      cfg.participation_min, '>'; ...
    'a1_center_participation_pi_c', participation_aggregate(2), ...
      cfg.participation_min, '>'; ...
    'a1_far_participation_pi_f', participation_aggregate(3), ...
      cfg.participation_min, '>'; ...
    'a1_noncommutator', noncommutator, cfg.noncommutator_min, '>'; ...
    'a1_wrong_order_residual', wrong_order_residual, cfg.mutation_min, '>'; ...
    'a1_wrong_J_residual', wrong_J_residual, cfg.mutation_min, '>'; ...
    'a1_wrong_terminal_residual', wrong_terminal_residual, cfg.mutation_min, '>'; ...
    'a1_swap_left_residual', swap_left_residual, cfg.mutation_min, '>'; ...
    'a1_swap_right_residual', swap_right_residual, cfg.mutation_min, '>'; ...
    'a1_swap_both_residual', swap_both_residual, cfg.mutation_min, '>'; ...
    'a1_side_swap_residual', side_swap_residual, cfg.mutation_min, '>'; ...
    'a1_left_Rhat_error', direct_left_error, cfg.algebra_tol, '<='; ...
    'a1_right_Rhat_error', direct_right_error, cfg.algebra_tol, '<='; ...
    'a1_direct_phase_left', direct_phase_left, cfg.algebra_tol, '<='; ...
    'a1_direct_phase_right', direct_phase_right, cfg.algebra_tol, '<='; ...
    'a1_availability_complete', double(a1_availability.all_available), 1, '>='};
  [algebra_rows, metric_pass] = LOCAL_add_metrics(algebra_rows, 'A1', metrics);

  kernel_rows(end + 1) = LOCAL_kernel_row('A1_augmented', aug_nullity, ...
    aug_singular(end), second_singular, participation, aug_residual, false); %#ok<AGROW>
  kernel_rows(end + 1) = LOCAL_kernel_row('A1_reduced', red_nullity, ...
    red_singular(end), red_singular(end - 1) / max(1, norm(reduced.F_reduced, 2)), ...
    [NaN, NaN, NaN], reduced_residual, false); %#ok<AGROW>
  ledger = LOCAL_add_matrix_ledger(ledger, 'A1', -1, 'A_c', ...
    fixture.center.A_c, reduced.center_solve_residual, cfg.rcond_min, ...
    cfg.algebra_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, 'A1', -1, 'terminal_minus', ...
    reduced.terminal_minus, reduced.left_solve_residual, cfg.rcond_min, ...
    cfg.algebra_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, 'A1', -1, 'terminal_plus', ...
    reduced.terminal_plus, reduced.right_solve_residual, cfg.rcond_min, ...
    cfg.algebra_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, 'A1', -1, 'K_ee', ...
    raw.K_ee, raw.solve_residual, cfg.rcond_min, cfg.algebra_tol, true, true);

  result.fixture = fixture;
  result.F_aug = F_aug;
  result.F_reduced = reduced.F_reduced;
  result.F_raw_schur = raw.F_schur;
  result.z_lift = z_lift;
  result.augmented_residual = aug_residual;
  result.reduced_residual = reduced_residual;
  result.schur_error = schur_error;
  result.lift_error = lift_error;
  result.augmented_nullity = aug_nullity;
  result.reduced_nullity = red_nullity;
  result.second_singular = second_singular;
  result.participation = participation;
  result.participation_aggregate = participation_aggregate;
  result.swap_residuals = [swap_left_residual, swap_right_residual, swap_both_residual];
  result.availability = a1_availability;
  result.pass = metric_pass && aug_nullity == 1 && red_nullity == 1 && ...
    all(participation_aggregate > cfg.participation_min) && ...
    all(participation > cfg.participation_min);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fixture = LOCAL_a1_fixture()
  I = eye(2);
  Z = zeros(2);
  A_c = [2, 0.2 + 0.1i, 0, 0.1; -0.1i, 1.7, 0.15, 0; ...
    0.05, 0, 1.5, -0.2i; 0, 0.1, 0.05, 1.8];
  phase_center = diag([0.7 + 0.1i, 0.4 - 0.2i]);
  E_L = [I, Z];
  E_R = [Z, I];
  R_minus = [0.4, 0.1 + 0.2i; -0.05i, 0.3];
  R_plus = [0.2, -0.15i; 0.07 + 0.04i, 0.35];
  Rhat_block_D = blkdiag(R_minus, R_plus);
  x_star = [1; 2i; -1 + 1i; 0.5];
  S0 = [0.2, 0.05i, 0.1, -0.03; -0.04, 0.25, 0.02 + 0.01i, 0.06; ...
    0.08, -0.02i, 0.18, 0.07; 0.01 + 0.03i, 0.05, -0.06, 0.22];
  y_star = Rhat_block_D \ x_star;
  S_center = S0 + (y_star - S0 * x_star) * (x_star') / (x_star' * x_star);
  J_center = [Z, phase_center; phase_center, Z];
  B_all = -A_c * (S_center - J_center);

  center.A_c = A_c;
  center.B_L = B_all(:, 1:2);
  center.B_R = B_all(:, 3:4);
  center.E_L = E_L;
  center.E_R = E_R;
  center.J_LL = Z;
  center.J_LR = phase_center;
  center.J_RL = phase_center;
  center.J_RR = Z;
  center.phase_center = phase_center;

  T_LR_minus = [1, 0.2; -0.1i, 0.8];
  T_RL_minus = [0.7, 0.1i; 0.15, 1.1];
  lead_minus.R_L = Z;
  lead_minus.T_RL = T_RL_minus;
  lead_minus.T_LR = T_LR_minus;
  lead_minus.R_R = R_minus + T_LR_minus * T_RL_minus;
  T_LR_plus = [0.9, -0.1i; 0.2, 1.2];
  T_RL_plus = [1.1, 0.15; -0.05i, 0.75];
  lead_plus.R_L = R_plus + T_RL_plus * T_LR_plus;
  lead_plus.T_RL = T_RL_plus;
  lead_plus.T_LR = T_LR_plus;
  lead_plus.R_R = Z;

  xi_star = (S_center - J_center) * x_star;
  bc_minus = y_star(1:2);
  ac_plus = y_star(3:4);
  af_minus = -T_RL_minus * bc_minus;
  bf_minus = T_RL_minus * bc_minus;
  bf_plus = -T_LR_plus * ac_plus;
  af_plus = T_LR_plus * ac_plus;
  z_star = [xi_star; x_star(1:2); x_star(3:4); bc_minus; ac_plus; ...
    af_minus; bf_minus; bf_plus; af_plus];

  fixture.center = center;
  fixture.lead_minus = lead_minus;
  fixture.lead_plus = lead_plus;
  fixture.R_minus = R_minus;
  fixture.R_plus = R_plus;
  fixture.Rhat_block_D = Rhat_block_D;
  fixture.S_center = S_center;
  fixture.x_star = x_star;
  fixture.y_star = y_star;
  fixture.z_star = z_star;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lead = LOCAL_swap_transmissions(lead)
  old_T_LR = lead.T_LR;
  lead.T_LR = lead.T_RL;
  lead.T_RL = old_T_LR;
end

%% ==================== Scaling oracle A2 ====================
% These helpers verify that scaled and physical density coordinates commute.

function [result, algebra_rows, negative_rows] = ...
    LOCAL_run_a2(cfg, case_a1, algebra_rows, negative_rows)
  fixture = case_a1.fixture;
  Q = diag([1, 2, 3, 4]);
  center = fixture.center;
  scaled = center;
  scaled.A_c = Q * center.A_c / Q;
  scaled.B_L = Q * center.B_L;
  scaled.B_R = Q * center.B_R;
  scaled.E_L = center.E_L / Q;
  scaled.E_R = center.E_R / Q;

  unscaled_reduced = LOCAL_reduced_oracle(center, fixture.lead_minus, ...
    fixture.lead_plus);
  scaled_reduced = LOCAL_reduced_oracle(scaled, fixture.lead_minus, ...
    fixture.lead_plus);
  density_physical = -(center.A_c \ [center.B_L, center.B_R]);
  density_scaled = -(scaled.A_c \ [scaled.B_L, scaled.B_R]);
  density_error = LOCAL_relmat(density_scaled, Q * density_physical);
  scattering_error = LOCAL_relmat(scaled_reduced.S_center, ...
    unscaled_reduced.S_center);
  reduced_error = LOCAL_relmat(scaled_reduced.F_reduced, ...
    unscaled_reduced.F_reduced);

  wrong_scaled = scaled;
  wrong_scaled.B_L = center.B_L;
  wrong_scaled.B_R = center.B_R;
  wrong_scaled.E_L = center.E_L;
  wrong_scaled.E_R = center.E_R;
  wrong_reduced = LOCAL_reduced_oracle(wrong_scaled, fixture.lead_minus, ...
    fixture.lead_plus);
  mismatch = LOCAL_relmat(wrong_reduced.S_center, ...
    unscaled_reduced.S_center);

  metrics = { ...
    'a2_density_coordinate_error', density_error, cfg.algebra_tol, '<='; ...
    'a2_scattering_coordinate_error', scattering_error, cfg.algebra_tol, '<='; ...
    'a2_reduced_coordinate_error', reduced_error, cfg.algebra_tol, '<='; ...
    'a2_wrong_scaling_mismatch', mismatch, cfg.scaling_mutation_min, '>'};
  [algebra_rows, metric_pass] = LOCAL_add_metrics(algebra_rows, 'A2', metrics);
  negative_rows(end + 1) = LOCAL_negative_row( ...
    'A2_WRONG_SCALING', 'SCALING_COORDINATE_MISMATCH', ...
    'REDUCED_CROSSCHECK_UNAVAILABLE', mismatch, ...
    cfg.scaling_mutation_min, mismatch > cfg.scaling_mutation_min, ...
    false, false, 'unscaled B and E used with scaled A'); %#ok<AGROW>

  result.Q = Q;
  result.density_error = density_error;
  result.scattering_error = scattering_error;
  result.reduced_error = reduced_error;
  result.mismatch = mismatch;
  result.pass = metric_pass;
end

%% ==================== Actual BIE interface smoke ====================
% These helpers build the corrected ellipse center and doubled circle leads.

function [result, ledger, representation_ledger, algebra_rows, kernel_rows] = ...
    LOCAL_run_actual(cfg, ledger, representation_ledger, algebra_rows, kernel_rows)
  [center, center_aux] = LOCAL_build_center(cfg, 'ellipse');
  [lead_cell, lead_aux] = LOCAL_build_circle_lead(cfg);
  p = cfg.p;
  n = size(center.A_c, 1);

  incident_left_error = LOCAL_relmat(center_aux.B_L_physical, ...
    LOCAL_incident_formula(center_aux.geom, center_aux.channels, ...
    cfg.walls(1), cfg.walls(2), 'left'));
  incident_right_error = LOCAL_relmat(center_aux.B_R_physical, ...
    LOCAL_incident_formula(center_aux.geom, center_aux.channels, ...
    cfg.walls(1), cfg.walls(2), 'right'));
  physical_density_error = LOCAL_relmat(center_aux.H_scaled, ...
    center_aux.D_h * center_aux.H_physical);
  physical_scattering_error = LOCAL_relmat(center_aux.S_scaled, ...
    center_aux.S_physical);
  circle_oracle_error = LOCAL_scattering_error(lead_cell, lead_aux.oracle);
  expected_phase = diag(center_aux.channels.phase(:));
  phase_left_error = LOCAL_relmat([center.J_LL; center.J_RL], ...
    [zeros(p); expected_phase]);
  phase_right_error = LOCAL_relmat([center.J_LR; center.J_RR], ...
    [expected_phase; zeros(p)]);

  base_metrics = { ...
    'actual_incident_left_formula', incident_left_error, cfg.incident_tol, '<='; ...
    'actual_incident_right_formula', incident_right_error, cfg.incident_tol, '<='; ...
    'actual_scaled_density_relation', physical_density_error, cfg.algebra_tol, '<='; ...
    'actual_scaled_physical_scattering', physical_scattering_error, cfg.algebra_tol, '<='; ...
    'actual_circle_construct_S_oracle', circle_oracle_error, cfg.algebra_tol, '<='; ...
    'actual_direct_phase_left', phase_left_error, cfg.algebra_tol, '<='; ...
    'actual_direct_phase_right', phase_right_error, cfg.algebra_tol, '<='; ...
    'actual_min_abs_gamma', center_aux.min_abs_gamma, cfg.gamma_min, '>='};
  [algebra_rows, base_pass] = LOCAL_add_metrics(algebra_rows, 'B', base_metrics);

  ledger = LOCAL_add_matrix_ledger(ledger, 'B', -1, 'center_A_c', ...
    center.A_c, center_aux.solve_residual, cfg.bie_rcond_min, ...
    cfg.bie_residual_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, 'B', -1, 'lead_A_QP', ...
    lead_aux.A_QP, lead_aux.solve_residual, cfg.bie_rcond_min, ...
    cfg.bie_residual_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, 'B', -1, 'D_h_fingerprint', ...
    center_aux.D_h, 0, cfg.rcond_min, cfg.algebra_tol, true, true);
  descriptor = LOCAL_representation_descriptor(center, center_aux, cfg);
  representation_gate = LOCAL_representation_gate(center, descriptor, ...
    descriptor, cfg);

  current_minus = lead_cell;
  current_plus = lead_cell;
  previous_F = [];
  previous_minus = [];
  previous_plus = [];
  levels = struct('level', {}, 'N', {}, 'F_aug', {}, 'F_reduced', {}, ...
    'F_schur', {}, 'schur_error', {}, 'delta_allowed_error', {}, ...
    'delta_block_errors', {}, 'delta_forbidden_ratio', {}, ...
    'delta_sign_mutation', {}, 'delta_slot_mutation', {}, ...
    'participation', {}, 'availability', {});
  level_pass = true;
  for level = cfg.levels
    N = 2 ^ level;
    availability_options = LOCAL_availability_options();
    availability_options.center_rcond_min = cfg.bie_rcond_min;
    availability = LOCAL_availability_gate(center, current_minus, ...
      current_plus, descriptor, descriptor, cfg, availability_options);
    F_aug = availability.F_aug;
    if availability.all_available
      reduced = LOCAL_reduced_oracle(center, current_minus, current_plus);
      raw = LOCAL_raw_schur(F_aug, n, p);
      schur_error = LOCAL_relmat(raw.F_schur, reduced.F_reduced);
      [raw_left_return, raw_left_residual] = ...
        LOCAL_raw_terminal_return(current_minus, 'left');
      [raw_right_return, raw_right_residual] = ...
        LOCAL_raw_terminal_return(current_plus, 'right');
      direct_left_error = LOCAL_relmat(reduced.Rhat_minus_D, raw_left_return);
      direct_right_error = LOCAL_relmat(reduced.Rhat_plus_D, raw_right_return);
    else
      reduced.F_reduced = availability.F_reduced;
      reduced.Rhat_minus_D = availability.Rhat_minus;
      reduced.Rhat_plus_D = availability.Rhat_plus;
      reduced.center_solve_residual = availability.center_residual;
      reduced.terminal_minus = eye(p) + current_minus.R_L;
      reduced.terminal_plus = eye(p) + current_plus.R_R;
      reduced.left_solve_residual = availability.Rhat_minus_residual;
      reduced.right_solve_residual = availability.Rhat_plus_residual;
      raw.F_schur = availability.F_raw_schur;
      raw.K_ee = availability.K_ee;
      raw.solve_residual = availability.raw_schur_residual;
      schur_error = NaN;
      direct_left_error = NaN;
      direct_right_error = NaN;
      raw_left_residual = NaN;
      raw_right_residual = NaN;
    end
    [delta_allowed, delta_blocks, delta_forbidden, delta_mutations] = ...
      LOCAL_delta_support( ...
      previous_F, F_aug, n, p, previous_minus, previous_plus, ...
      current_minus, current_plus);
    [actual_nullity, singular_values] = LOCAL_nullity(F_aug, cfg.rank_factor);
    [~, ~, V] = svd(F_aug);
    min_direction = V(:, end) / norm(V(:, end));
    participation = LOCAL_participation(min_direction, n, p);
    kernel_rows(end + 1) = LOCAL_kernel_row( ...
      sprintf('B_level_%d_diagnostic', level), actual_nullity, ...
      singular_values(end), singular_values(end - 1) / max(1, norm(F_aug, 2)), ...
      participation, LOCAL_relres0(F_aug, min_direction), true); %#ok<AGROW>

    metrics = { ...
      sprintf('actual_L%d_raw_schur_error', level), schur_error, ...
        cfg.actual_schur_tol, '<='; ...
      sprintf('actual_L%d_left_return_error', level), direct_left_error, ...
        cfg.algebra_tol, '<='; ...
      sprintf('actual_L%d_right_return_error', level), direct_right_error, ...
        cfg.algebra_tol, '<='; ...
      sprintf('actual_L%d_left_raw_group_residual', level), raw_left_residual, ...
        cfg.algebra_tol, '<='; ...
      sprintf('actual_L%d_right_raw_group_residual', level), raw_right_residual, ...
        cfg.algebra_tol, '<='; ...
      sprintf('actual_L%d_delta_allowed', level), delta_allowed, ...
        cfg.allowed_delta_tol, '<='; ...
      sprintf('actual_L%d_delta_forbidden', level), delta_forbidden, ...
        cfg.forbidden_delta_tol, '<='; ...
      sprintf('actual_L%d_availability_complete', level), ...
        double(availability.all_available), 1, '>='; ...
      sprintf('actual_L%d_availability_equivalence', level), ...
        availability.equivalence_error, cfg.actual_schur_tol, '<='};
    [algebra_rows, this_pass] = LOCAL_add_metrics(algebra_rows, 'B', metrics);
    delta_names = {'g4_bc_minus', 'g4_af_minus', 'g5_bc_minus', ...
      'g5_af_minus', 'g7_ac_plus', 'g7_bf_plus', ...
      'g8_ac_plus', 'g8_bf_plus'};
    for delta_idx = 1:length(delta_names)
      one_metric = {sprintf('actual_L%d_delta_%s', level, ...
        delta_names{delta_idx}), delta_blocks(delta_idx), ...
        cfg.allowed_delta_tol, '<='};
      [algebra_rows, delta_pass] = LOCAL_add_metrics( ...
        algebra_rows, 'B', one_metric);
      this_pass = this_pass && delta_pass;
    end
    if level == 1
      mutation_metrics = { ...
        'actual_delta_sign_mutation', delta_mutations(1), ...
          cfg.mutation_min, '>'; ...
        'actual_delta_allowed_slot_swap_mutation', delta_mutations(2), ...
          cfg.mutation_min, '>'};
      [algebra_rows, mutation_pass] = LOCAL_add_metrics( ...
        algebra_rows, 'B', mutation_metrics);
      this_pass = this_pass && mutation_pass;
    end
    level_pass = level_pass && this_pass;

    ledger = LOCAL_add_matrix_ledger(ledger, 'B', level, 'center_solve', ...
      center.A_c, reduced.center_solve_residual, cfg.bie_rcond_min, ...
      cfg.bie_residual_tol, true, true);
    ledger = LOCAL_add_matrix_ledger(ledger, 'B', level, 'far_left', ...
      [-current_minus.R_L, eye(p); eye(p), eye(p)], ...
      0, cfg.rcond_min, cfg.algebra_tol, true, true);
    ledger = LOCAL_add_matrix_ledger(ledger, 'B', level, 'far_right', ...
      [-current_plus.R_R, eye(p); eye(p), eye(p)], ...
      0, cfg.rcond_min, cfg.algebra_tol, true, true);
    ledger = LOCAL_add_matrix_ledger(ledger, 'B', level, 'terminal_minus', ...
      reduced.terminal_minus, reduced.left_solve_residual, cfg.rcond_min, ...
      cfg.algebra_tol, true, true);
    ledger = LOCAL_add_matrix_ledger(ledger, 'B', level, 'terminal_plus', ...
      reduced.terminal_plus, reduced.right_solve_residual, cfg.rcond_min, ...
      cfg.algebra_tol, true, true);
    ledger = LOCAL_add_matrix_ledger(ledger, 'B', level, 'K_ee', ...
      raw.K_ee, raw.solve_residual, cfg.rcond_min, ...
      cfg.actual_schur_tol, true, true);
    representation_ledger(end + 1) = LOCAL_representation_row( ...
      'B', level, cfg.representation_id, n, p, ...
      representation_gate.smallest_singular, representation_gate.rank_value, ...
      representation_gate.raw_status, representation_gate.all_failures, ...
      representation_gate.status); %#ok<AGROW>

    levels(end + 1) = struct('level', level, 'N', N, ...
      'F_aug', F_aug, 'F_reduced', reduced.F_reduced, ...
      'F_schur', raw.F_schur, 'schur_error', schur_error, ...
      'delta_allowed_error', delta_allowed, ...
      'delta_block_errors', delta_blocks, ...
      'delta_forbidden_ratio', delta_forbidden, ...
      'delta_sign_mutation', delta_mutations(1), ...
      'delta_slot_mutation', delta_mutations(2), ...
      'participation', participation, ...
      'availability', availability); %#ok<AGROW>
    previous_F = F_aug;
    previous_minus = current_minus;
    previous_plus = current_plus;
    if level < cfg.levels(end)
      [current_minus, minus_info] = LOCAL_star(current_minus, current_minus);
      [current_plus, plus_info] = LOCAL_star(current_plus, current_plus);
      ledger = LOCAL_add_star_ledger(ledger, 'B', level + 1, ...
        minus_info, plus_info, cfg);
    end
  end

  result.label = 'UNSCREENED_CENTER_BIE_INTERFACE_SMOKE';
  result.center = center;
  result.center_aux = center_aux;
  result.lead_cell = lead_cell;
  result.levels = levels;
  result.representation_descriptor = descriptor;
  result.representation_gate = representation_gate;
  result.pass = base_pass && level_pass && representation_gate.pass;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [center, aux] = LOCAL_build_center(cfg, shape)
  pars1.k = cfg.kext;
  pars1.beta = cfg.beta;
  pars1.d = cfg.d;
  pars1.periodic_axis = 'y';
  pars2.H = 1.8;
  pars2.proxy_dist = 0.7;
  pars2.N_side = 40;
  pars2.N_top = 40;
  pars2.N_proxy_edge = 24;
  pars2.M_pw = 8;
  channels = bloch.rayleigh_channels(cfg.kext, cfg.beta, cfg.d, ...
    cfg.M, cfg.L);
  if strcmp(shape, 'ellipse')
    [geom_data, curvelen] = geom.construct_cont(cfg.ntot_center, ...
      'ellipse', 0, 0, cfg.ellipse_axes);
  else
    [geom_data, curvelen] = geom.construct_cont(cfg.ntot, ...
      'circle', 0, 0, cfg.radius);
  end
  proxy = kernel.precomp_proxy(pars1, pars2);
  A_c = full(complex(op.construct_A_QP(geom_data, cfg.kext, cfg.kint, ...
    pars1, proxy, curvelen)));
  [B_L_physical, B_R_physical] = bloch.incident_rhs(geom_data, channels, ...
    cfg.walls(1), cfg.walls(2));
  [E_L_physical, E_R_physical] = bloch.farfield_extractors(geom_data, ...
    channels, cfg.walls(1), cfg.walls(2), curvelen);
  h = curvelen / size(geom_data, 2);
  speed = sqrt(geom_data(2, :).^2 + geom_data(5, :).^2);
  density_scale = sqrt(h * [speed, speed]).';
  D_h = diag(density_scale);
  B_L = bsxfun(@times, B_L_physical, density_scale);
  B_R = bsxfun(@times, B_R_physical, density_scale);
  E_L = bsxfun(@rdivide, E_L_physical, density_scale.');
  E_R = bsxfun(@rdivide, E_R_physical, density_scale.');
  phase = diag(channels.phase(:));

  center.A_c = A_c;
  center.B_L = B_L;
  center.B_R = B_R;
  center.E_L = E_L;
  center.E_R = E_R;
  center.J_LL = zeros(cfg.p);
  center.J_LR = phase;
  center.J_RL = phase;
  center.J_RR = zeros(cfg.p);
  center.phase_center = phase;

  [H_scaled, solve_residual] = LOCAL_solve(A_c, -[B_L, B_R]);
  A_physical = D_h \ (A_c * D_h);
  [H_physical, physical_residual] = LOCAL_solve(A_physical, ...
    -[B_L_physical, B_R_physical]);
  J = [zeros(cfg.p), phase; phase, zeros(cfg.p)];
  S_scaled = J + [E_L; E_R] * H_scaled;
  S_physical = J + [E_L_physical; E_R_physical] * H_physical;

  aux.geom = geom_data;
  aux.curvelen = curvelen;
  aux.channels = channels;
  aux.min_abs_gamma = min(abs(channels.gamma_m));
  aux.D_h = D_h;
  aux.density_scale = density_scale;
  aux.A_physical = A_physical;
  aux.B_L_physical = B_L_physical;
  aux.B_R_physical = B_R_physical;
  aux.E_L_physical = E_L_physical;
  aux.E_R_physical = E_R_physical;
  aux.H_scaled = H_scaled;
  aux.H_physical = H_physical;
  aux.S_scaled = S_scaled;
  aux.S_physical = S_physical;
  aux.solve_residual = solve_residual;
  aux.physical_residual = physical_residual;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [lead, aux] = LOCAL_build_circle_lead(cfg)
  [center, center_aux] = LOCAL_build_center(cfg, 'circle');
  reduced = LOCAL_reduced_oracle(center, LOCAL_zero_lead(cfg.p), ...
    LOCAL_zero_lead(cfg.p));
  S = reduced.S_center;
  lead = LOCAL_scattering_from_full(S);

  pars1.k = cfg.kext;
  pars1.beta = cfg.beta;
  pars1.d = cfg.d;
  pars1.periodic_axis = 'y';
  pars2.H = 1.8;
  pars2.proxy_dist = 0.7;
  pars2.N_side = 40;
  pars2.N_top = 40;
  pars2.N_proxy_edge = 24;
  pars2.M_pw = 8;
  proxy = kernel.precomp_proxy(pars1, pars2);
  oracle_raw = bloch.construct_S(center_aux.geom, cfg.kext, cfg.kint, ...
    pars1, proxy, center_aux.curvelen, center_aux.channels, ...
    cfg.walls(1), cfg.walls(2));
  aux.oracle = LOCAL_scattering_blocks(oracle_raw);
  aux.A_QP = oracle_raw.A_QP;
  aux.solve_residual = LOCAL_relres(oracle_raw.A_QP, ...
    [oracle_raw.H_L, oracle_raw.H_R], -[oracle_raw.B_L, oracle_raw.B_R]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lead = LOCAL_zero_lead(p)
  lead.R_L = zeros(p);
  lead.R_R = zeros(p);
  lead.T_LR = zeros(p);
  lead.T_RL = zeros(p);
  lead.K = p;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function B = LOCAL_incident_formula(geom_data, channels, X_L, X_R, side)
  x = geom_data(1, :).';
  y = geom_data(4, :).';
  dxdt = geom_data(2, :).';
  dydt = geom_data(5, :).';
  speed = sqrt(dxdt.^2 + dydt.^2);
  nx = dydt ./ speed;
  ny = -dxdt ./ speed;
  beta_m = channels.beta_m(:).';
  gamma_m = channels.gamma_m(:).';
  psi = exp(1i * y * beta_m) / sqrt(channels.d);
  if strcmp(side, 'left')
    U = exp(1i * (x - X_L) * gamma_m) .* psi;
    dU = 1i * (nx * gamma_m + ny * beta_m) .* U;
  else
    U = exp(-1i * (x - X_R) * gamma_m) .* psi;
    dU = 1i * (-nx * gamma_m + ny * beta_m) .* U;
  end
  B = [U; dU];
end

%% ==================== Scattering composition ====================
% These helpers double finite sections and retain both internal factors.

function [AB, info] = LOCAL_star(A, B)
  p = size(A.R_L, 1);
  I = eye(p);
  info.G_A = I - A.R_R * B.R_L;
  info.G_B = I - B.R_L * A.R_R;
  [X_LR, residual_lr] = LOCAL_solve(info.G_A, A.T_LR);
  [X_RR, residual_rr] = LOCAL_solve(info.G_A, A.R_R * B.T_RL);
  [X_RL, residual_rl] = LOCAL_solve(info.G_B, B.T_RL);
  AB.R_L = A.R_L + A.T_RL * B.R_L * X_LR;
  AB.T_LR = B.T_LR * X_LR;
  AB.T_RL = A.T_RL * X_RL;
  AB.R_R = B.R_R + B.T_LR * X_RR;
  AB.K = p;
  info.G_A_residual = max(residual_lr, residual_rr);
  info.G_B_residual = residual_rl;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_add_star_ledger(ledger, case_name, level, ...
    minus_info, plus_info, cfg)
  ledger = LOCAL_add_matrix_ledger(ledger, case_name, level, ...
    'double_minus_G_A', minus_info.G_A, minus_info.G_A_residual, ...
    cfg.rcond_min, cfg.algebra_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, case_name, level, ...
    'double_minus_G_B', minus_info.G_B, minus_info.G_B_residual, ...
    cfg.rcond_min, cfg.algebra_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, case_name, level, ...
    'double_plus_G_A', plus_info.G_A, plus_info.G_A_residual, ...
    cfg.rcond_min, cfg.algebra_tol, true, true);
  ledger = LOCAL_add_matrix_ledger(ledger, case_name, level, ...
    'double_plus_G_B', plus_info.G_B, plus_info.G_B_residual, ...
    cfg.rcond_min, cfg.algebra_tol, true, true);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lead = LOCAL_scattering_from_full(S)
  p = size(S, 1) / 2;
  lead.R_L = S(1:p, 1:p);
  lead.T_RL = S(1:p, p + 1:end);
  lead.T_LR = S(p + 1:end, 1:p);
  lead.R_R = S(p + 1:end, p + 1:end);
  lead.K = p;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lead = LOCAL_scattering_blocks(raw)
  lead.R_L = raw.R_L;
  lead.T_LR = raw.T_LR;
  lead.T_RL = raw.T_RL;
  lead.R_R = raw.R_R;
  lead.K = size(raw.R_L, 1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function error_value = LOCAL_scattering_error(A, B)
  error_value = max([LOCAL_relmat(A.R_L, B.R_L), ...
    LOCAL_relmat(A.T_LR, B.T_LR), LOCAL_relmat(A.T_RL, B.T_RL), ...
    LOCAL_relmat(A.R_R, B.R_R)]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Rhat, residual] = LOCAL_raw_terminal_return(lead, side)
  p = size(lead.R_L, 1);
  if strcmp(side, 'left')
    factor = [-lead.R_L, eye(p); eye(p), eye(p)];
    rhs = [lead.T_RL; zeros(p)];
    [far, residual] = LOCAL_solve(factor, rhs);
    Rhat = lead.R_R + lead.T_LR * far(1:p, :);
  else
    factor = [-lead.R_R, eye(p); eye(p), eye(p)];
    rhs = [lead.T_LR; zeros(p)];
    [far, residual] = LOCAL_solve(factor, rhs);
    Rhat = lead.R_L + lead.T_RL * far(1:p, :);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [allowed_error, block_errors, forbidden_ratio, mutation_errors] = ...
    LOCAL_delta_support(old_F, new_F, n, p, old_minus, old_plus, ...
    new_minus, new_plus)
  if isempty(old_F)
    allowed_error = 0;
    block_errors = zeros(1, 8);
    forbidden_ratio = 0;
    mutation_errors = [NaN, NaN];
    return;
  end
  layout = LOCAL_layout(n, p);
  delta = new_F - old_F;
  allowed = false(size(delta));
  c = layout.col;
  r = layout.row;
  allowed(r.g4, [c.bc_minus, c.af_minus]) = true;
  allowed(r.g5, [c.bc_minus, c.af_minus]) = true;
  allowed(r.g7, [c.ac_plus, c.bf_plus]) = true;
  allowed(r.g8, [c.ac_plus, c.bf_plus]) = true;
  forbidden = delta;
  forbidden(allowed) = 0;
  forbidden_ratio = norm(forbidden, 'fro') / max(1, norm(delta, 'fro'));

  expected = zeros(size(delta));
  expected_blocks = { ...
    -(new_minus.T_RL - old_minus.T_RL), ...
    -(new_minus.R_L - old_minus.R_L), ...
    -(new_minus.R_R - old_minus.R_R), ...
    -(new_minus.T_LR - old_minus.T_LR), ...
    -(new_plus.R_L - old_plus.R_L), ...
    -(new_plus.T_RL - old_plus.T_RL), ...
    -(new_plus.T_LR - old_plus.T_LR), ...
    -(new_plus.R_R - old_plus.R_R)};
  actual_blocks = { ...
    delta(r.g4, c.bc_minus), delta(r.g4, c.af_minus), ...
    delta(r.g5, c.bc_minus), delta(r.g5, c.af_minus), ...
    delta(r.g7, c.ac_plus), delta(r.g7, c.bf_plus), ...
    delta(r.g8, c.ac_plus), delta(r.g8, c.bf_plus)};
  expected(r.g4, c.bc_minus) = expected_blocks{1};
  expected(r.g4, c.af_minus) = expected_blocks{2};
  expected(r.g5, c.bc_minus) = expected_blocks{3};
  expected(r.g5, c.af_minus) = expected_blocks{4};
  expected(r.g7, c.ac_plus) = expected_blocks{5};
  expected(r.g7, c.bf_plus) = expected_blocks{6};
  expected(r.g8, c.ac_plus) = expected_blocks{7};
  expected(r.g8, c.bf_plus) = expected_blocks{8};
  block_errors = zeros(1, 8);
  for idx = 1:8
    block_errors(idx) = LOCAL_relmat(actual_blocks{idx}, expected_blocks{idx});
  end
  allowed_error = LOCAL_relmat(delta, expected);
  sign_mutation = expected;
  sign_mutation(r.g4, c.bc_minus) = -expected_blocks{1};
  slot_mutation = expected;
  slot_mutation(r.g4, c.bc_minus) = expected_blocks{2};
  slot_mutation(r.g4, c.af_minus) = expected_blocks{1};
  mutation_errors = [LOCAL_relmat(delta, sign_mutation), ...
    LOCAL_relmat(delta, slot_mutation)];
end

%% ==================== Representation gate ====================
% This shared gate validates dimensions, fingerprints, and the frozen V_c stack.

function descriptor = LOCAL_representation_descriptor(center, aux, cfg)
  descriptor.representation_id = cfg.representation_id;
  descriptor.n_density = size(center.A_c, 1);
  descriptor.p_channels = size(center.B_L, 2);
  descriptor.column_order = ...
    'xi,ac_minus,bc_plus,bc_minus,ac_plus,af_minus,bf_minus,bf_plus,af_plus';
  descriptor.row_order = 'g1,g2,g3,g4,g5,g6,g7,g8,g9';
  descriptor.phase = diag(center.phase_center);
  descriptor.density_scale = aux.density_scale(:);
  descriptor.padding = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function gate = LOCAL_representation_gate(center, candidate, expected, cfg)
  failures = {};
  n = candidate.n_density;
  p = candidate.p_channels;
  primitive_finite = all(isfinite(center.A_c(:))) && ...
    all(isfinite(center.B_L(:))) && all(isfinite(center.B_R(:))) && ...
    all(isfinite(center.E_L(:))) && all(isfinite(center.E_R(:)));
  dimensions_match = isequal(size(center.A_c), [n, n]) && ...
    isequal(size(center.B_L), [n, p]) && isequal(size(center.B_R), [n, p]) && ...
    isequal(size(center.E_L), [p, n]) && isequal(size(center.E_R), [p, n]);
  fingerprint_match = strcmp(candidate.representation_id, ...
    expected.representation_id) && ...
    strcmp(candidate.column_order, expected.column_order) && ...
    strcmp(candidate.row_order, expected.row_order) && ...
    candidate.padding == expected.padding && ...
    candidate.n_density == expected.n_density && ...
    candidate.p_channels == expected.p_channels && ...
    LOCAL_relmat(candidate.phase(:), expected.phase(:)) <= cfg.algebra_tol && ...
    LOCAL_relmat(candidate.density_scale(:), ...
      expected.density_scale(:)) <= cfg.algebra_tol;
  if ~primitive_finite || ~dimensions_match || ~fingerprint_match
    failures{end + 1} = 'DIMENSION_OR_FINGERPRINT_MISMATCH'; %#ok<AGROW>
  end

  if primitive_finite && dimensions_match
    V_c = [center.A_c; center.E_L; center.E_R];
    singular_values = svd(V_c);
    rank_value = LOCAL_rank(V_c, cfg.rank_factor);
    smallest_singular = singular_values(end);
    if rank_value < n
      failures{end + 1} = 'ZERO_FIELD_REPRESENTATION'; %#ok<AGROW>
    end
  else
    V_c = NaN;
    rank_value = NaN;
    smallest_singular = NaN;
  end
  raw_available = primitive_finite && dimensions_match && fingerprint_match;
  if raw_available
    raw_status = 'RAW_RETAINED';
  else
    raw_status = 'RAW_UNAVAILABLE';
  end
  gate.pass = isempty(failures);
  gate.raw_available = raw_available;
  gate.raw_status = raw_status;
  gate.rank_value = rank_value;
  gate.smallest_singular = smallest_singular;
  gate.V_c = V_c;
  if gate.pass
    gate.primary_failure = '';
    gate.all_failures = '';
    gate.status = 'PASS';
  else
    gate.primary_failure = failures{1};
    gate.all_failures = strjoin(failures, ';');
    gate.status = 'FAIL';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function options = LOCAL_availability_options()
  options.prior_failure = '';
  options.post_raw_failure = '';
  options.center_rcond_min = NaN;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function gate = LOCAL_availability_gate(center, lead_minus, lead_plus, ...
    candidate, expected, cfg, options)
  % Initialize every layer with an explicit unavailable/NaN sentinel.
  expected_n = expected.n_density;
  expected_p = expected.p_channels;
  expected_total = expected_n + 8 * expected_p;
  gate.F_aug_available = false;
  gate.Sc_available = false;
  gate.Rhat_minus_available = false;
  gate.Rhat_plus_available = false;
  gate.Fred_available = false;
  gate.raw_schur_available = false;
  gate.equivalence_available = false;
  gate.root_available = false;
  gate.physical_available = false;
  gate.root_ready = 'STOP';
  gate.F_aug = NaN(expected_total);
  gate.S_center = NaN(2 * expected_p);
  gate.Rhat_minus = NaN(expected_p);
  gate.Rhat_plus = NaN(expected_p);
  gate.F_reduced = NaN(2 * expected_p);
  gate.F_raw_schur = NaN(2 * expected_p);
  gate.equivalence_error = NaN;
  gate.root_value = NaN;
  gate.physical_value = NaN;
  gate.K_ee = NaN(expected_n + 6 * expected_p);
  gate.K_ee_rcond = NaN;
  gate.center_rcond = NaN;
  gate.far_minus_rcond = NaN;
  gate.far_plus_rcond = NaN;
  gate.terminal_minus_rcond = NaN;
  gate.terminal_plus_rcond = NaN;
  gate.center_residual = NaN;
  gate.Rhat_minus_residual = NaN;
  gate.Rhat_plus_residual = NaN;
  gate.raw_schur_residual = NaN;
  failures = {};

  if ~isempty(options.prior_failure)
    failures = LOCAL_append_failure(failures, options.prior_failure);
    gate = LOCAL_finish_availability(gate, failures);
    return;
  end

  representation = LOCAL_representation_gate(center, candidate, expected, cfg);
  gate.representation = representation;
  if ~representation.raw_available
    failures = LOCAL_append_failure(failures, ...
      'DIMENSION_OR_FINGERPRINT_MISMATCH');
    gate = LOCAL_finish_availability(gate, failures);
    return;
  end

  n = size(center.A_c, 1);
  p = size(center.B_L, 2);
  gate.F_aug = LOCAL_assemble_augmented(center, lead_minus, lead_plus);
  gate.F_aug_available = all(isfinite(gate.F_aug(:)));
  if ~gate.F_aug_available
    failures = LOCAL_append_failure(failures, ...
      'DIMENSION_OR_FINGERPRINT_MISMATCH');
    gate = LOCAL_finish_availability(gate, failures);
    return;
  end
  raw = LOCAL_raw_partition(gate.F_aug, n, p);
  gate.K_ee = raw.K_ee;
  gate.K_ee_rcond = rcond(raw.K_ee);
  if ~isempty(options.post_raw_failure)
    failures = LOCAL_append_failure(failures, options.post_raw_failure);
    gate = LOCAL_finish_availability(gate, failures);
    return;
  end

  center_threshold = options.center_rcond_min;
  if ~isfinite(center_threshold)
    center_threshold = cfg.rcond_min;
  end
  gate.center_rcond = rcond(center.A_c);
  center_factor_pass = isfinite(gate.center_rcond) && ...
    gate.center_rcond >= center_threshold;
  if ~center_factor_pass
    failures = LOCAL_append_failure(failures, 'CENTER_BIE_POLE');
  elseif representation.rank_value < n
    center_factor_pass = false;
  end
  if representation.rank_value < n
    failures = LOCAL_append_failure(failures, 'ZERO_FIELD_REPRESENTATION');
  end
  if center_factor_pass
    [H, gate.center_residual] = LOCAL_solve(center.A_c, ...
      -[center.B_L, center.B_R]);
    J = [center.J_LL, center.J_LR; center.J_RL, center.J_RR];
    gate.S_center = J + [center.E_L; center.E_R] * H;
    gate.Sc_available = all(isfinite(gate.S_center(:))) && ...
      gate.center_residual <= cfg.bie_residual_tol;
    if ~gate.Sc_available
      gate.S_center = NaN(2 * p);
      failures = LOCAL_append_failure(failures, ...
        'BLOCK_ORDER_OR_SIGN_MISMATCH');
    end
  else
    gate.center_residual = NaN;
  end

  I = eye(p);
  far_minus = [-lead_minus.R_L, I; I, I];
  far_plus = [-lead_plus.R_R, I; I, I];
  terminal_minus = I + lead_minus.R_L;
  terminal_plus = I + lead_plus.R_R;
  gate.far_minus_rcond = rcond(far_minus);
  gate.far_plus_rcond = rcond(far_plus);
  gate.terminal_minus_rcond = rcond(terminal_minus);
  gate.terminal_plus_rcond = rcond(terminal_plus);
  minus_pass = min(gate.far_minus_rcond, gate.terminal_minus_rcond) >= ...
    cfg.rcond_min;
  plus_pass = min(gate.far_plus_rcond, gate.terminal_plus_rcond) >= ...
    cfg.rcond_min;
  if minus_pass
    [gate.Rhat_minus, gate.Rhat_minus_residual] = ...
      LOCAL_raw_terminal_return(lead_minus, 'left');
    gate.Rhat_minus_available = all(isfinite(gate.Rhat_minus(:))) && ...
      gate.Rhat_minus_residual <= cfg.algebra_tol;
    if ~gate.Rhat_minus_available
      gate.Rhat_minus = NaN(p);
      failures = LOCAL_append_failure(failures, 'TERMINAL_RESONANCE');
    end
  else
    gate.Rhat_minus_residual = NaN;
    failures = LOCAL_append_failure(failures, 'TERMINAL_RESONANCE');
  end
  if plus_pass
    [gate.Rhat_plus, gate.Rhat_plus_residual] = ...
      LOCAL_raw_terminal_return(lead_plus, 'right');
    gate.Rhat_plus_available = all(isfinite(gate.Rhat_plus(:))) && ...
      gate.Rhat_plus_residual <= cfg.algebra_tol;
    if ~gate.Rhat_plus_available
      gate.Rhat_plus = NaN(p);
      failures = LOCAL_append_failure(failures, 'TERMINAL_RESONANCE');
    end
  else
    gate.Rhat_plus_residual = NaN;
    failures = LOCAL_append_failure(failures, 'TERMINAL_RESONANCE');
  end

  if gate.Sc_available && gate.Rhat_minus_available && ...
      gate.Rhat_plus_available
    R_D = blkdiag(gate.Rhat_minus, gate.Rhat_plus);
    gate.F_reduced = eye(2 * p) - R_D * gate.S_center;
    gate.Fred_available = all(isfinite(gate.F_reduced(:)));
    if ~gate.Fred_available
      gate.F_reduced = NaN(2 * p);
      failures = LOCAL_append_failure(failures, ...
        'BLOCK_ORDER_OR_SIGN_MISMATCH');
    end
  end

  if isfinite(gate.K_ee_rcond) && gate.K_ee_rcond >= cfg.rcond_min
    [response, gate.raw_schur_residual] = ...
      LOCAL_solve(raw.K_ee, raw.K_er);
    gate.F_raw_schur = raw.K_rr - raw.K_re * response;
    gate.raw_schur_available = all(isfinite(gate.F_raw_schur(:))) && ...
      gate.raw_schur_residual <= cfg.actual_schur_tol;
    if ~gate.raw_schur_available
      gate.F_raw_schur = NaN(2 * p);
      failures = LOCAL_append_failure(failures, 'RAW_SCHUR_POLE');
    end
  else
    gate.raw_schur_residual = NaN;
    failures = LOCAL_append_failure(failures, 'RAW_SCHUR_POLE');
  end
  if gate.Fred_available && gate.raw_schur_available
    gate.equivalence_error = LOCAL_relmat(gate.F_reduced, ...
      gate.F_raw_schur);
    gate.equivalence_available = isfinite(gate.equivalence_error);
  end
  gate = LOCAL_finish_availability(gate, failures);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function raw = LOCAL_raw_partition(F_aug, n_density, p_channels)
  layout = LOCAL_layout(n_density, p_channels);
  retained_cols = [layout.col.ac_minus, layout.col.bc_plus];
  retained_rows = [layout.row.g5, layout.row.g7];
  eliminated_cols = setdiff(1:layout.total, retained_cols, 'stable');
  eliminated_rows = setdiff(1:layout.total, retained_rows, 'stable');
  raw.K_ee = F_aug(eliminated_rows, eliminated_cols);
  raw.K_er = F_aug(eliminated_rows, retained_cols);
  raw.K_re = F_aug(retained_rows, eliminated_cols);
  raw.K_rr = F_aug(retained_rows, retained_cols);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function failures = LOCAL_append_failure(failures, value)
  if ~any(strcmp(failures, value))
    failures{end + 1} = value;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function gate = LOCAL_finish_availability(gate, failures)
  if isempty(failures)
    gate.primary_failure = '';
    gate.all_failures = '';
  else
    gate.primary_failure = failures{1};
    gate.all_failures = strjoin(failures, ';');
  end
  gate.all_available = gate.F_aug_available && gate.Sc_available && ...
    gate.Rhat_minus_available && gate.Rhat_plus_available && ...
    gate.Fred_available && gate.raw_schur_available && ...
    gate.equivalence_available && ~gate.root_available && ...
    ~gate.physical_available && strcmp(gate.root_ready, 'STOP');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_expected_availability(gate, expected)
  actual = [gate.F_aug_available, gate.Sc_available, ...
    gate.Rhat_minus_available, gate.Rhat_plus_available, ...
    gate.Fred_available, gate.raw_schur_available, ...
    gate.equivalence_available];
  values = {gate.F_aug, gate.S_center, gate.Rhat_minus, ...
    gate.Rhat_plus, gate.F_reduced, gate.F_raw_schur, ...
    gate.equivalence_error};
  value_pass = true;
  for idx = 1:length(values)
    if expected(idx)
      value_pass = value_pass && all(isfinite(values{idx}(:)));
    else
      value_pass = value_pass && all(isnan(values{idx}(:)));
    end
  end
  if expected(1)
    value_pass = value_pass && all(isfinite(gate.K_ee(:)));
  else
    value_pass = value_pass && all(isnan(gate.K_ee(:)));
  end
  pass = isequal(logical(actual), logical(expected)) && value_pass && ...
    ~gate.root_available && ~gate.physical_available && ...
    all(isnan(gate.root_value(:))) && all(isnan(gate.physical_value(:))) && ...
    strcmp(gate.root_ready, 'STOP');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_apply_availability_to_row(row, gate)
  row.raw_available = gate.F_aug_available;
  row.derived_available = gate.equivalence_available;
  row.F_aug_available = gate.F_aug_available;
  row.Sc_available = gate.Sc_available;
  row.Rhat_minus_available = gate.Rhat_minus_available;
  row.Rhat_plus_available = gate.Rhat_plus_available;
  row.Fred_available = gate.Fred_available;
  row.raw_schur_available = gate.raw_schur_available;
  row.equivalence_available = gate.equivalence_available;
  row.root_ready = gate.root_ready;
  row.pass = row.pass && LOCAL_expected_availability(gate, ...
    [true, false, false, false, false, false, false]);
end

%% ==================== Shared-gate negative suite ====================
% These helpers preserve raw evidence while marking derived layers unavailable.

function [result, ledger, representation_ledger, negative_rows] = ...
    LOCAL_run_negatives(cfg, case_a1, case_b, ledger, ...
    representation_ledger, negative_rows)
  fixture = case_a1.fixture;
  F_reference = case_a1.F_aug;
  manufactured_aux.density_scale = ones(4, 1);
  fixture_descriptor = LOCAL_representation_descriptor( ...
    fixture.center, manufactured_aux, cfg);
  availability_cases = struct();
  post_options = LOCAL_availability_options();
  post_options.post_raw_failure = 'BLOCK_ORDER_OR_SIGN_MISMATCH';
  scaling_options = LOCAL_availability_options();
  scaling_options.post_raw_failure = 'SCALING_COORDINATE_MISMATCH';
  scaling_gate = LOCAL_availability_gate(fixture.center, ...
    fixture.lead_minus, fixture.lead_plus, fixture_descriptor, ...
    fixture_descriptor, cfg, scaling_options);
  availability_cases.A2_WRONG_SCALING = scaling_gate;
  a2_index = find(strcmp({negative_rows.case_name}, 'A2_WRONG_SCALING'), 1);
  negative_rows(a2_index) = LOCAL_apply_availability_to_row( ...
    negative_rows(a2_index), scaling_gate);
  mutation_specs = { ...
    'A1_WRONG_J', 'BLOCK_ORDER_OR_SIGN_MISMATCH', ...
      LOCAL_a1_mutation(fixture, 'wrong_J'); ...
    'A1_WRONG_REDUCED_ORDER', 'BLOCK_ORDER_OR_SIGN_MISMATCH', ...
      eye(4) - fixture.S_center * fixture.Rhat_block_D; ...
    'A1_TERMINAL_SIGN', 'BLOCK_ORDER_OR_SIGN_MISMATCH', ...
      LOCAL_a1_mutation(fixture, 'terminal_sign'); ...
    'A1_TRANSMISSION_SWAP', 'BLOCK_ORDER_OR_SIGN_MISMATCH', ...
      LOCAL_a1_mutation(fixture, 'transmission_swap'); ...
    'A1_SIDE_SWAP', 'BLOCK_ORDER_OR_SIGN_MISMATCH', ...
      LOCAL_a1_mutation(fixture, 'side_swap')};
  for idx = 1:size(mutation_specs, 1)
    mutated = mutation_specs{idx, 3};
    if isequal(size(mutated), size(F_reference))
      metric = LOCAL_relres0(mutated, fixture.z_star);
    else
      metric = LOCAL_relres0(mutated, fixture.x_star);
    end
    mutation_gate = LOCAL_availability_gate(fixture.center, ...
      fixture.lead_minus, fixture.lead_plus, fixture_descriptor, ...
      fixture_descriptor, cfg, post_options);
    availability_cases.(mutation_specs{idx, 1}) = mutation_gate;
    mutation_pass = metric > cfg.mutation_min && ...
      LOCAL_expected_availability(mutation_gate, ...
      [true, false, false, false, false, false, false]);
    negative_rows(end + 1) = LOCAL_negative_row(mutation_specs{idx, 1}, ...
      mutation_specs{idx, 2}, 'REDUCED_CROSSCHECK_UNAVAILABLE', metric, ...
      cfg.mutation_min, mutation_pass, mutation_gate.F_aug_available, ...
      mutation_gate.equivalence_available, 'deterministic A1 mutation', ...
      mutation_gate); %#ok<AGROW>
  end
  delta_level = case_b.levels(2);
  delta_sign_gate = LOCAL_availability_gate(case_b.center, ...
    case_b.lead_cell, case_b.lead_cell, case_b.representation_descriptor, ...
    case_b.representation_descriptor, cfg, post_options);
  availability_cases.ACTUAL_DELTA_SIGN_MUTATION = delta_sign_gate;
  negative_rows(end + 1) = LOCAL_negative_row( ...
    'ACTUAL_DELTA_SIGN_MUTATION', 'BLOCK_ORDER_OR_SIGN_MISMATCH', '', ...
    delta_level.delta_sign_mutation, cfg.mutation_min, ...
    delta_level.delta_sign_mutation > cfg.mutation_min && ...
    LOCAL_expected_availability(delta_sign_gate, ...
    [true, false, false, false, false, false, false]), ...
    delta_sign_gate.F_aug_available, delta_sign_gate.equivalence_available, ...
    'primitive expected delta with one allowed-block sign reversed', ...
    delta_sign_gate); %#ok<AGROW>
  delta_slot_gate = LOCAL_availability_gate(case_b.center, ...
    case_b.lead_cell, case_b.lead_cell, case_b.representation_descriptor, ...
    case_b.representation_descriptor, cfg, post_options);
  availability_cases.ACTUAL_DELTA_SLOT_SWAP_MUTATION = delta_slot_gate;
  negative_rows(end + 1) = LOCAL_negative_row( ...
    'ACTUAL_DELTA_SLOT_SWAP_MUTATION', 'BLOCK_ORDER_OR_SIGN_MISMATCH', '', ...
    delta_level.delta_slot_mutation, cfg.mutation_min, ...
    delta_level.delta_slot_mutation > cfg.mutation_min && ...
    LOCAL_expected_availability(delta_slot_gate, ...
    [true, false, false, false, false, false, false]), ...
    delta_slot_gate.F_aug_available, delta_slot_gate.equivalence_available, ...
    'primitive expected delta with two allowed positions swapped', ...
    delta_slot_gate); %#ok<AGROW>

  wood_channels = bloch.rayleigh_channels(0.20, cfg.beta, cfg.d, ...
    cfg.M, cfg.L);
  wood_metric = min(abs(wood_channels.gamma_m));
  wood_options = LOCAL_availability_options();
  wood_options.prior_failure = 'WOOD_POINT';
  wood_gate = LOCAL_availability_gate(case_b.center, case_b.lead_cell, ...
    case_b.lead_cell, case_b.representation_descriptor, ...
    case_b.representation_descriptor, cfg, wood_options);
  availability_cases.WOOD_K_0P2 = wood_gate;
  negative_rows(end + 1) = LOCAL_negative_row('WOOD_K_0P2', ...
    'WOOD_POINT', '', wood_metric, cfg.gamma_min, ...
    wood_metric < cfg.gamma_min && LOCAL_expected_availability(wood_gate, ...
    false(1, 7)), wood_gate.F_aug_available, ...
    wood_gate.equivalence_available, ...
    'screened before BIE or lead construction', wood_gate); %#ok<AGROW>

  singular_A.R_L = zeros(2);
  singular_A.R_R = eye(2);
  singular_A.T_LR = eye(2);
  singular_A.T_RL = eye(2);
  singular_B = singular_A;
  singular_B.R_L = eye(2);
  G = eye(2) - singular_A.R_R * singular_B.R_L;
  doubling_metric = rcond(G);
  doubling_options = LOCAL_availability_options();
  doubling_options.prior_failure = 'DOUBLING_POLE';
  doubling_gate = LOCAL_availability_gate(fixture.center, ...
    fixture.lead_minus, fixture.lead_plus, fixture_descriptor, ...
    fixture_descriptor, cfg, doubling_options);
  availability_cases.DOUBLING_EXACT_POLE = doubling_gate;
  negative_rows(end + 1) = LOCAL_negative_row('DOUBLING_EXACT_POLE', ...
    'DOUBLING_POLE', 'REDUCED_CROSSCHECK_UNAVAILABLE', doubling_metric, ...
    cfg.rcond_min, doubling_metric < cfg.rcond_min && ...
    LOCAL_expected_availability(doubling_gate, false(1, 7)), ...
    doubling_gate.F_aug_available, doubling_gate.equivalence_available, ...
    'R_R^A=I and R_L^B=I', doubling_gate); %#ok<AGROW>
  ledger = LOCAL_add_matrix_ledger(ledger, 'DOUBLING_EXACT_POLE', -1, ...
    'G_A', G, NaN, cfg.rcond_min, cfg.algebra_tol, true, false);

  pole_center = fixture.center;
  pole_center.A_c = diag([1, 1, 1, 0]);
  full_extract = [eye(4)];
  center_metric = rcond(pole_center.A_c);
  F_center_pole = LOCAL_assemble_augmented(pole_center, fixture.lead_minus, ...
    fixture.lead_plus);
  ledger = LOCAL_add_matrix_ledger(ledger, 'CENTER_EXACT_POLE', -1, ...
    'A_c', pole_center.A_c, NaN, cfg.rcond_min, cfg.algebra_tol, true, false);
  center_descriptor = LOCAL_representation_descriptor( ...
    pole_center, manufactured_aux, cfg);
  center_options = LOCAL_availability_options();
  center_gate = LOCAL_availability_gate(pole_center, fixture.lead_minus, ...
    fixture.lead_plus, center_descriptor, center_descriptor, cfg, ...
    center_options);
  availability_cases.CENTER_EXACT_POLE = center_gate;
  center_expected = [true, false, true, true, false, false, false];
  center_pass = center_metric < cfg.rcond_min && rank(full_extract) == 4 && ...
    LOCAL_expected_availability(center_gate, center_expected) && ...
    isequal(center_gate.F_aug, F_center_pole) && ...
    all(isnan(center_gate.F_reduced(:)));
  negative_rows(end + 1) = LOCAL_negative_row('CENTER_EXACT_POLE', ...
    center_gate.primary_failure, center_gate.all_failures, center_metric, ...
    cfg.rcond_min, center_pass, center_gate.F_aug_available, ...
    center_gate.equivalence_available, ...
    'raw augmented matrix retained; V has full column rank', center_gate); %#ok<AGROW>
  ledger = LOCAL_add_matrix_ledger(ledger, 'CENTER_EXACT_POLE', -1, ...
    'K_ee', center_gate.K_ee, NaN, cfg.rcond_min, ...
    cfg.actual_schur_tol, true, false);
  center_rep_gate = LOCAL_representation_gate(pole_center, ...
    center_descriptor, center_descriptor, cfg);
  representation_ledger(end + 1) = LOCAL_representation_row( ...
    'CENTER_EXACT_POLE', -1, cfg.representation_id, 4, 2, ...
    center_rep_gate.smallest_singular, center_rep_gate.rank_value, ...
    center_rep_gate.raw_status, center_rep_gate.all_failures, ...
    center_rep_gate.status); %#ok<AGROW>

  zero_center = pole_center;
  zero_center.E_L = [eye(2), zeros(2)];
  zero_center.E_R = [0, 0, 1, 0; 0, 0, 0, 0];
  V_zero = [zero_center.E_L; zero_center.E_R];
  F_zero = LOCAL_assemble_augmented(zero_center, fixture.lead_minus, ...
    fixture.lead_plus);
  zero_direction = zeros(size(F_zero, 1), 1);
  zero_direction(4) = 1;
  zero_metric = LOCAL_relres0(F_zero, zero_direction);
  zero_pass = zero_metric <= cfg.algebra_tol && norm(V_zero(:, 4)) == 0;
  zero_descriptor = LOCAL_representation_descriptor( ...
    zero_center, manufactured_aux, cfg);
  zero_options = LOCAL_availability_options();
  zero_gate = LOCAL_availability_gate(zero_center, fixture.lead_minus, ...
    fixture.lead_plus, zero_descriptor, zero_descriptor, cfg, zero_options);
  availability_cases.ZERO_FIELD_EXACT = zero_gate;
  zero_expected = [true, false, true, true, false, false, false];
  zero_pass = zero_pass && LOCAL_expected_availability( ...
    zero_gate, zero_expected) && isequal(zero_gate.F_aug, F_zero) && ...
    all(isnan(zero_gate.S_center(:)));
  negative_rows(end + 1) = LOCAL_negative_row('ZERO_FIELD_EXACT', ...
    zero_gate.primary_failure, zero_gate.all_failures, zero_metric, ...
    cfg.algebra_tol, zero_pass, zero_gate.F_aug_available, ...
    zero_gate.equivalence_available, ...
    'density-only augmented null direction e4', zero_gate); %#ok<AGROW>
  ledger = LOCAL_add_matrix_ledger(ledger, 'ZERO_FIELD_EXACT', -1, ...
    'K_ee', zero_gate.K_ee, NaN, cfg.rcond_min, ...
    cfg.actual_schur_tol, true, false);
  zero_rep_gate = LOCAL_representation_gate(zero_center, zero_descriptor, ...
    zero_descriptor, cfg);
  representation_ledger(end + 1) = LOCAL_representation_row( ...
    'ZERO_FIELD_EXACT', -1, cfg.representation_id, 4, 2, ...
    zero_rep_gate.smallest_singular, zero_rep_gate.rank_value, ...
    zero_rep_gate.raw_status, zero_rep_gate.all_failures, ...
    'EXPECTED_FAIL'); %#ok<AGROW>

  left_terminal = fixture.lead_minus;
  left_terminal.R_L = -eye(2);
  right_terminal = fixture.lead_plus;
  right_terminal.R_R = -eye(2);
  terminal_cases = { ...
    'LEFT_TERMINAL_EXACT', eye(2) + left_terminal.R_L; ...
    'RIGHT_TERMINAL_EXACT', eye(2) + right_terminal.R_R};
  for idx = 1:size(terminal_cases, 1)
    factor = terminal_cases{idx, 2};
    metric = rcond(factor);
    terminal_options = LOCAL_availability_options();
    if idx == 1
      terminal_gate = LOCAL_availability_gate(fixture.center, ...
        left_terminal, fixture.lead_plus, fixture_descriptor, ...
        fixture_descriptor, cfg, terminal_options);
      expected_flags = [true, true, false, true, false, false, false];
    else
      terminal_gate = LOCAL_availability_gate(fixture.center, ...
        fixture.lead_minus, right_terminal, fixture_descriptor, ...
        fixture_descriptor, cfg, terminal_options);
      expected_flags = [true, true, true, false, false, false, false];
    end
    availability_cases.(terminal_cases{idx, 1}) = terminal_gate;
    terminal_pass = metric < cfg.rcond_min && ...
      terminal_gate.K_ee_rcond < cfg.rcond_min && ...
      LOCAL_expected_availability(terminal_gate, expected_flags) && ...
      all(isnan(terminal_gate.F_reduced(:)));
    negative_rows(end + 1) = LOCAL_negative_row(terminal_cases{idx, 1}, ...
      terminal_gate.primary_failure, terminal_gate.all_failures, metric, ...
      cfg.rcond_min, terminal_pass, terminal_gate.F_aug_available, ...
      terminal_gate.equivalence_available, ...
      'raw augmented matrix and K_ee retained; derived values are NaN', ...
      terminal_gate); %#ok<AGROW>
    ledger = LOCAL_add_matrix_ledger(ledger, terminal_cases{idx, 1}, ...
      -1, 'terminal_factor', factor, NaN, cfg.rcond_min, ...
      cfg.algebra_tol, true, false);
    if idx == 1
      far_factor = [-left_terminal.R_L, eye(2); eye(2), eye(2)];
    else
      far_factor = [-right_terminal.R_R, eye(2); eye(2), eye(2)];
    end
    ledger = LOCAL_add_matrix_ledger(ledger, terminal_cases{idx, 1}, ...
      -1, 'far_terminal_factor', far_factor, NaN, cfg.rcond_min, ...
      cfg.algebra_tol, true, false);
    ledger = LOCAL_add_matrix_ledger(ledger, terminal_cases{idx, 1}, ...
      -1, 'K_ee', terminal_gate.K_ee, NaN, cfg.rcond_min, ...
      cfg.actual_schur_tol, true, false);
  end

  expected_descriptor = case_b.representation_descriptor;
  candidates = cell(5, 1);
  candidates{1} = expected_descriptor;
  candidates{1}.p_channels = expected_descriptor.p_channels + 1;
  candidates{2} = expected_descriptor;
  candidates{2}.column_order = ...
    'xi,bc_plus,ac_minus,bc_minus,ac_plus,af_minus,bf_minus,bf_plus,af_plus';
  candidates{3} = expected_descriptor;
  candidates{3}.phase(1) = -candidates{3}.phase(1);
  candidates{4} = expected_descriptor;
  candidates{4}.density_scale(1) = 1.1 * candidates{4}.density_scale(1);
  candidates{5} = expected_descriptor;
  candidates{5}.padding = 1;
  representation_mutations = { ...
    'REP_CHANGED_P', 'changed channel count p', 1; ...
    'REP_CHANGED_ORDER', 'changed amplitude order', 1; ...
    'REP_CHANGED_PHASE', 'changed direct phase convention', ...
      LOCAL_relmat(candidates{3}.phase, expected_descriptor.phase); ...
    'REP_CHANGED_DH', 'changed D_h fingerprint', ...
      LOCAL_relmat(candidates{4}.density_scale, ...
      expected_descriptor.density_scale); ...
    'REP_PADDING', 'padded density representation', 1};
  for idx = 1:size(representation_mutations, 1)
    representation_options = LOCAL_availability_options();
    gate = LOCAL_availability_gate(case_b.center, case_b.lead_cell, ...
      case_b.lead_cell, candidates{idx}, expected_descriptor, cfg, ...
      representation_options);
    availability_cases.(representation_mutations{idx, 1}) = gate;
    rep_gate = gate.representation;
    metric = representation_mutations{idx, 3};
    gate_detected = strcmp(gate.primary_failure, ...
      'DIMENSION_OR_FINGERPRINT_MISMATCH') && metric > cfg.algebra_tol && ...
      LOCAL_expected_availability(gate, false(1, 7));
    negative_rows(end + 1) = LOCAL_negative_row( ...
      representation_mutations{idx, 1}, ...
      gate.primary_failure, gate.all_failures, metric, cfg.algebra_tol, ...
      gate_detected, gate.F_aug_available, gate.equivalence_available, ...
      representation_mutations{idx, 2}, gate); %#ok<AGROW>
    representation_ledger(end + 1) = LOCAL_representation_row( ...
      representation_mutations{idx, 1}, -1, candidates{idx}.representation_id, ...
      candidates{idx}.n_density, candidates{idx}.p_channels, ...
      rep_gate.smallest_singular, rep_gate.rank_value, rep_gate.raw_status, ...
      rep_gate.all_failures, ...
      'EXPECTED_FAIL'); %#ok<AGROW>
  end

  result.rows = negative_rows;
  result.center_pole_raw = F_center_pole;
  result.zero_field_raw = F_zero;
  result.left_terminal_raw = availability_cases.LEFT_TERMINAL_EXACT.F_aug;
  result.right_terminal_raw = availability_cases.RIGHT_TERMINAL_EXACT.F_aug;
  result.left_terminal_K_ee = availability_cases.LEFT_TERMINAL_EXACT.K_ee;
  result.right_terminal_K_ee = availability_cases.RIGHT_TERMINAL_EXACT.K_ee;
  result.availability = availability_cases;
  result.actual_raw_retained = case_b.levels(1).F_aug;
  result.pass = all([negative_rows.pass]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function M = LOCAL_a1_mutation(fixture, name)
  if strcmp(name, 'wrong_J')
    center = fixture.center;
    center.J_LL = center.J_LR;
    center.J_LR = zeros(2);
    center.J_RL = zeros(2);
    center.J_RR = fixture.center.J_RL;
    M = LOCAL_assemble_augmented(center, fixture.lead_minus, fixture.lead_plus);
  elseif strcmp(name, 'terminal_sign')
    M = LOCAL_assemble_augmented(fixture.center, fixture.lead_minus, ...
      fixture.lead_plus);
    layout = LOCAL_layout(4, 2);
    M(layout.row.g6, layout.col.bf_minus) = -eye(2);
  elseif strcmp(name, 'transmission_swap')
    M = LOCAL_assemble_augmented(fixture.center, ...
      LOCAL_swap_transmissions(fixture.lead_minus), ...
      LOCAL_swap_transmissions(fixture.lead_plus));
  else
    M = LOCAL_assemble_augmented(fixture.center, fixture.lead_plus, ...
      fixture.lead_minus);
  end
end

%% ==================== Linear algebra and row builders ====================
% These helpers apply the frozen metrics and deterministic failure labels.

function [X, residual] = LOCAL_solve(M, B)
  X = M \ B;
  residual = LOCAL_relres(M, X, B);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_relmat(X, Y)
  value = norm(X - Y, 'fro') / max([1, norm(X, 'fro'), norm(Y, 'fro')]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_relres(M, X, B)
  value = norm(M * X - B, 'fro') / ...
    max([1, norm(M, 2) * norm(X, 'fro') + norm(B, 'fro')]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_relres0(M, x)
  value = norm(M * x) / max(1, norm(M, 2) * norm(x));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_direction_error(actual, expected)
  value = LOCAL_relmat(actual, expected);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [nullity, singular_values] = LOCAL_nullity(M, rank_factor)
  singular_values = svd(M);
  tolerance = rank_factor * max(1, norm(M, 2));
  nullity = sum(singular_values <= tolerance);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rank_value = LOCAL_rank(M, rank_factor)
  singular_values = svd(M);
  tolerance = rank_factor * max(1, norm(M, 2));
  rank_value = sum(singular_values > tolerance);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function values = LOCAL_participation(z, n, p)
  layout = LOCAL_layout(n, p);
  values = [norm(z(layout.col.xi)), ...
    norm(z(layout.col.ac_minus)), norm(z(layout.col.bc_plus)), ...
    norm(z(layout.col.bc_minus)), norm(z(layout.col.ac_plus)), ...
    norm(z(layout.col.af_minus)), norm(z(layout.col.bf_minus)), ...
    norm(z(layout.col.bf_plus)), norm(z(layout.col.af_plus))];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_algebra_rows()
  rows = struct('case_name', {}, 'metric', {}, 'value', {}, ...
    'threshold', {}, 'relation', {}, 'status', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rows, pass] = LOCAL_add_metrics(rows, case_name, metrics)
  pass = true;
  for idx = 1:size(metrics, 1)
    relation = metrics{idx, 4};
    value = metrics{idx, 2};
    threshold = metrics{idx, 3};
    if strcmp(relation, '<=')
      this_pass = isfinite(value) && value <= threshold;
    elseif strcmp(relation, '>=')
      this_pass = isfinite(value) && value >= threshold;
    else
      this_pass = isfinite(value) && value > threshold;
    end
    rows(end + 1) = struct('case_name', case_name, ...
      'metric', metrics{idx, 1}, 'value', value, ...
      'threshold', threshold, 'relation', relation, ...
      'status', LOCAL_pass_label(this_pass)); %#ok<AGROW>
    pass = pass && this_pass;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_kernel_rows()
  rows = struct('case_name', {}, 'nullity', {}, 'smallest_singular', {}, ...
    'second_singular_normalized', {}, 'density_participation', {}, ...
    'center_participation_pi_c', {}, 'far_participation_pi_f', {}, ...
    'center_participation_min', {}, 'far_participation_min', {}, ...
    'residual', {}, 'diagnostic_only', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_kernel_row(case_name, nullity, smallest, second, ...
    participation, residual, diagnostic_only)
  if length(participation) >= 9
    density_participation = participation(1);
    center_aggregate = norm(participation(2:5));
    far_aggregate = norm(participation(6:9));
    center_min = min(participation(2:5));
    far_min = min(participation(6:9));
  else
    density_participation = participation(1);
    center_aggregate = participation(2);
    far_aggregate = participation(3);
    center_min = participation(2);
    far_min = participation(3);
  end
  row = struct('case_name', case_name, 'nullity', nullity, ...
    'smallest_singular', smallest, ...
    'second_singular_normalized', second, ...
    'density_participation', density_participation, ...
    'center_participation_pi_c', center_aggregate, ...
    'far_participation_pi_f', far_aggregate, ...
    'center_participation_min', center_min, ...
    'far_participation_min', far_min, 'residual', residual, ...
    'diagnostic_only', diagnostic_only);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_ledger()
  rows = struct('case_name', {}, 'level', {}, 'factor', {}, ...
    'size_label', {}, 'rcond_value', {}, 'residual', {}, ...
    'rcond_threshold', {}, 'residual_threshold', {}, ...
    'raw_available', {}, 'derived_available', {}, ...
    'primary_failure', {}, 'all_failures', {}, 'status', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_add_matrix_ledger(rows, case_name, level, ...
    factor_name, factor, residual, rcond_threshold, residual_threshold, ...
    raw_available, expect_pass)
  rcond_value = rcond(factor);
  failures = {};
  if ~isfinite(rcond_value) || rcond_value < rcond_threshold
    failures{end + 1} = LOCAL_factor_failure(factor_name); %#ok<AGROW>
  end
  if isfinite(residual) && residual > residual_threshold
    failures{end + 1} = 'BLOCK_ORDER_OR_SIGN_MISMATCH'; %#ok<AGROW>
  end
  if isempty(failures)
    primary_failure = '';
    all_failures = '';
    derived_available = true;
    status = 'PASS';
  else
    primary_failure = failures{1};
    all_failures = strjoin(failures, ';');
    derived_available = false;
    if expect_pass
      status = 'FAIL';
    else
      status = 'EXPECTED_FAIL';
    end
  end
  rows(end + 1) = struct('case_name', case_name, 'level', level, ...
    'factor', factor_name, 'size_label', LOCAL_size_label(factor), ...
    'rcond_value', rcond_value, 'residual', residual, ...
    'rcond_threshold', rcond_threshold, ...
    'residual_threshold', residual_threshold, ...
    'raw_available', raw_available, ...
    'derived_available', derived_available, ...
    'primary_failure', primary_failure, 'all_failures', all_failures, ...
    'status', status);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = LOCAL_factor_failure(name)
  if ~isempty(strfind(name, 'A_c')) || ~isempty(strfind(name, 'center'))
    label = 'CENTER_BIE_POLE';
  elseif ~isempty(strfind(name, 'A_QP')) || ~isempty(strfind(name, 'lead'))
    label = 'LEAD_BIE_POLE';
  elseif ~isempty(strfind(name, 'G_'))
    label = 'DOUBLING_POLE';
  elseif ~isempty(strfind(name, 'far')) || ~isempty(strfind(name, 'terminal'))
    label = 'TERMINAL_RESONANCE';
  elseif ~isempty(strfind(name, 'K_ee'))
    label = 'RAW_SCHUR_POLE';
  else
    label = 'DIMENSION_OR_FINGERPRINT_MISMATCH';
  end
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_representation_ledger()
  rows = struct('case_name', {}, 'level', {}, 'representation_id', {}, ...
    'n_density', {}, 'p_channels', {}, 'smallest_singular', {}, ...
    'rank_value', {}, 'raw_status', {}, 'all_reasons', {}, 'status', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_representation_row(case_name, level, representation_id, ...
    n_density, p_channels, smallest_singular, rank_value, raw_status, ...
    all_reasons, status)
  row = struct('case_name', case_name, 'level', level, ...
    'representation_id', representation_id, 'n_density', n_density, ...
    'p_channels', p_channels, 'smallest_singular', smallest_singular, ...
    'rank_value', rank_value, 'raw_status', raw_status, ...
    'all_reasons', all_reasons, 'status', status);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rows = LOCAL_empty_negative_rows()
  rows = struct('case_name', {}, 'primary_failure', {}, ...
    'all_failures', {}, 'observed_metric', {}, 'threshold', {}, ...
    'pass', {}, 'raw_available', {}, 'derived_available', {}, ...
    'F_aug_available', {}, 'Sc_available', {}, ...
    'Rhat_minus_available', {}, 'Rhat_plus_available', {}, ...
    'Fred_available', {}, 'raw_schur_available', {}, ...
    'equivalence_available', {}, 'root_ready', {}, 'note', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_negative_row(case_name, primary_failure, all_failures, ...
    observed_metric, threshold, pass, raw_available, derived_available, ...
    note, availability)
  if nargin < 10
    availability.F_aug_available = raw_available;
    availability.Sc_available = derived_available;
    availability.Rhat_minus_available = derived_available;
    availability.Rhat_plus_available = derived_available;
    availability.Fred_available = derived_available;
    availability.raw_schur_available = derived_available;
    availability.equivalence_available = derived_available;
    availability.root_ready = 'STOP';
  end
  if isempty(all_failures)
    all_failures = primary_failure;
  elseif isempty(strfind([';', all_failures, ';'], ...
      [';', primary_failure, ';']))
    all_failures = [primary_failure, ';', all_failures];
  end
  row = struct('case_name', case_name, ...
    'primary_failure', primary_failure, 'all_failures', all_failures, ...
    'observed_metric', observed_metric, 'threshold', threshold, ...
    'pass', logical(pass), 'raw_available', logical(raw_available), ...
    'derived_available', logical(derived_available), ...
    'F_aug_available', availability.F_aug_available, ...
    'Sc_available', availability.Sc_available, ...
    'Rhat_minus_available', availability.Rhat_minus_available, ...
    'Rhat_plus_available', availability.Rhat_plus_available, ...
    'Fred_available', availability.Fred_available, ...
    'raw_schur_available', availability.raw_schur_available, ...
    'equivalence_available', availability.equivalence_available, ...
    'root_ready', availability.root_ready, 'note', note);
end

%% ==================== Provenance and reproducibility ====================
% These helpers compare two unchanged-source runs and hash every executed source.

function previous = LOCAL_previous(output_dir)
  previous.available = false;
  previous.repro_vector = [];
  previous.source_hashes = struct();
  path = fullfile(output_dir, 'results.mat');
  if exist(path, 'file') == 2
    loaded = load(path, 'results');
    if isfield(loaded, 'results') && isfield(loaded.results, 'repro_vector')
      previous.available = true;
      previous.repro_vector = loaded.results.repro_vector;
      if isfield(loaded.results, 'config') && ...
          isfield(loaded.results.config, 'source_hashes')
        previous.source_hashes = loaded.results.config.source_hashes;
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function vector = LOCAL_repro_vector(results)
  negative_flags = [[results.negative_cases.rows.F_aug_available].', ...
    [results.negative_cases.rows.Sc_available].', ...
    [results.negative_cases.rows.Rhat_minus_available].', ...
    [results.negative_cases.rows.Rhat_plus_available].', ...
    [results.negative_cases.rows.Fred_available].', ...
    [results.negative_cases.rows.raw_schur_available].', ...
    [results.negative_cases.rows.equivalence_available].'];
  level_flags = zeros(length(results.case_b.levels), 7);
  for idx = 1:length(results.case_b.levels)
    item = results.case_b.levels(idx).availability;
    level_flags(idx, :) = [item.F_aug_available, item.Sc_available, ...
      item.Rhat_minus_available, item.Rhat_plus_available, ...
      item.Fred_available, item.raw_schur_available, ...
      item.equivalence_available];
  end
  vector = [ ...
    results.case_a1.augmented_residual; ...
    results.case_a1.reduced_residual; ...
    results.case_a1.schur_error; ...
    results.case_a2.density_error; ...
    results.case_a2.scattering_error; ...
    results.case_a2.mismatch; ...
    [results.case_b.levels.schur_error].'; ...
    [results.case_b.levels.delta_allowed_error].'; ...
    [results.case_b.levels.delta_forbidden_ratio].'; ...
    [results.algebra.value].'; ...
    [results.kernel.smallest_singular].'; ...
    [results.kernel.second_singular_normalized].'; ...
    [results.pole_ledger.rcond_value].'; ...
    [results.pole_ledger.residual].'; ...
    [results.representation_ledger.smallest_singular].'; ...
    [results.representation_ledger.rank_value].'; ...
    [results.negative_cases.rows.observed_metric].'; ...
    negative_flags(:); ...
    level_flags(:)];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function repro = LOCAL_compare_previous(previous, vector, source_hashes)
  repro.previous_available = previous.available;
  repro.tolerance = 1e-12;
  repro.manifest_equal = LOCAL_manifest_equal( ...
    previous.source_hashes, source_hashes);
  if ~previous.available
    repro.relative_difference = NaN;
    repro.status = 'BASELINE_CREATED';
    repro.pass = true;
    return;
  end
  if ~repro.manifest_equal || length(previous.repro_vector) ~= length(vector)
    repro.relative_difference = NaN;
    repro.status = 'SOURCE_CHANGED_BASELINE_CREATED';
    repro.pass = true;
    return;
  end
  old = previous.repro_vector(:);
  new = vector(:);
  finite_mask = isfinite(old) & isfinite(new);
  same_nonfinite = all(isnan(old(~finite_mask)) == isnan(new(~finite_mask))) && ...
    all(isinf(old(~finite_mask)) == isinf(new(~finite_mask)));
  if any(finite_mask)
    relative_difference = LOCAL_relmat(old(finite_mask), new(finite_mask));
  else
    relative_difference = 0;
  end
  repro.relative_difference = relative_difference;
  repro.pass = same_nonfinite && relative_difference <= repro.tolerance;
  if repro.pass
    repro.status = 'REPRODUCED';
  else
    repro.status = 'UNCHANGED_SOURCE_MISMATCH';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    if ~isfield(old_item, 'path') || ~isfield(old_item, 'sha256') || ...
        ~strcmp(old_item.path, new_item.path) || ...
        ~strcmp(old_item.sha256, new_item.sha256)
      equal = false;
      return;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%% ==================== Deterministic artifacts ====================
% These helpers write the complete audit bundle inside this experiment only.

function LOCAL_write_outputs(results, output_dir)
  LOCAL_write_config(results, fullfile(output_dir, 'config.txt'));
  LOCAL_write_levels(results.case_b.levels, fullfile(output_dir, 'levels.csv'));
  LOCAL_write_algebra(results.algebra, fullfile(output_dir, 'algebra.csv'));
  LOCAL_write_kernel(results.kernel, fullfile(output_dir, 'kernel.csv'));
  LOCAL_write_pole_ledger(results.pole_ledger, ...
    fullfile(output_dir, 'pole-ledger.csv'));
  LOCAL_write_representation_ledger(results.representation_ledger, ...
    fullfile(output_dir, 'representation-ledger.csv'));
  LOCAL_write_negative(results.negative_cases.rows, ...
    fullfile(output_dir, 'negative-cases.csv'));
  LOCAL_write_svg(fullfile(output_dir, 'assembly.svg'));
  LOCAL_write_report(results, fullfile(output_dir, 'report.md'));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_config(results, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  cfg = results.config;
  fprintf(fid, 'representation_id=%s\n', cfg.representation_id);
  fprintf(fid, 'actual_label=%s\n', results.case_b.label);
  fprintf(fid, 'root_ready=%s\n', results.root_ready);
  fprintf(fid, 'stage2_status=%s\n', results.stage2_status);
  fprintf(fid, 'beta=%.17g\n', cfg.beta);
  fprintf(fid, 'kext=%.17g\n', cfg.kext);
  fprintf(fid, 'kint=%.17g\n', cfg.kint);
  fprintf(fid, 'ellipse_axes=%.17g,%.17g\n', cfg.ellipse_axes);
  fprintf(fid, 'levels=0,1,2,3,4,5,6\n');
  fprintf(fid, 'p=%d\n', cfg.p);
  fprintf(fid, 'ntot_lead=%d\n', cfg.ntot);
  fprintf(fid, 'ntot_center=%d\n', cfg.ntot_center);
  fprintf(fid, 'explicit_inv_pinv=none\n');
  fprintf(fid, 'bloch_solve_modes=not_called\n');
  fprintf(fid, 'root_search=not_performed\n');
  fprintf(fid, 'command=%s\n', cfg.command);
  names = fieldnames(cfg.source_hashes);
  fprintf(fid, 'source_hash_manifest_count=%d\n', length(names));
  for idx = 1:length(names)
    item = cfg.source_hashes.(names{idx});
    fprintf(fid, 'source_%s_path=%s\n', names{idx}, item.path);
    fprintf(fid, 'source_%s_sha256=%s\n', names{idx}, item.sha256);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_levels(rows, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['level,N,schur_error,delta_allowed_error,', ...
    'delta_forbidden_ratio,density_participation,center_pi_c,far_pi_f,', ...
    'center_min,far_min,F_aug_available,Sc_available,', ...
    'Rhat_minus_available,Rhat_plus_available,Fred_available,', ...
    'raw_schur_available,equivalence_available,root_ready\n']);
  for idx = 1:length(rows)
    p = rows(idx).participation;
    a = rows(idx).availability;
    fprintf(fid, ['%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%d,%d,%d,%d,%d,%d,%d,%s\n'], ...
      rows(idx).level, rows(idx).N, rows(idx).schur_error, ...
      rows(idx).delta_allowed_error, rows(idx).delta_forbidden_ratio, ...
      p(1), norm(p(2:5)), norm(p(6:9)), min(p(2:5)), min(p(6:9)), ...
      a.F_aug_available, a.Sc_available, a.Rhat_minus_available, ...
      a.Rhat_plus_available, a.Fred_available, ...
      a.raw_schur_available, a.equivalence_available, a.root_ready);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_algebra(rows, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'case,metric,value,relation,threshold,status\n');
  for idx = 1:length(rows)
    fprintf(fid, '%s,%s,%.17g,%s,%.17g,%s\n', rows(idx).case_name, ...
      rows(idx).metric, rows(idx).value, rows(idx).relation, ...
      rows(idx).threshold, rows(idx).status);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_kernel(rows, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case,nullity,smallest_singular,second_singular_normalized,', ...
    'density_participation,center_pi_c,far_pi_f,center_min,far_min,', ...
    'residual,diagnostic_only\n']);
  for idx = 1:length(rows)
    fprintf(fid, ['%s,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%d\n'], ...
      rows(idx).case_name, rows(idx).nullity, rows(idx).smallest_singular, ...
      rows(idx).second_singular_normalized, rows(idx).density_participation, ...
      rows(idx).center_participation_pi_c, ...
      rows(idx).far_participation_pi_f, ...
      rows(idx).center_participation_min, rows(idx).far_participation_min, ...
      rows(idx).residual, rows(idx).diagnostic_only);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_pole_ledger(rows, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case,level,factor,size,rcond,residual,rcond_threshold,', ...
    'residual_threshold,raw_available,derived_available,primary_failure,', ...
    'all_failures,status\n']);
  for idx = 1:length(rows)
    fprintf(fid, '%s,%d,%s,%s,%.17g,%.17g,%.17g,%.17g,%d,%d,%s,%s,%s\n', ...
      rows(idx).case_name, rows(idx).level, rows(idx).factor, ...
      rows(idx).size_label, rows(idx).rcond_value, rows(idx).residual, ...
      rows(idx).rcond_threshold, rows(idx).residual_threshold, ...
      rows(idx).raw_available, rows(idx).derived_available, ...
      rows(idx).primary_failure, rows(idx).all_failures, rows(idx).status);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_representation_ledger(rows, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case,level,representation_id,n_density,p_channels,', ...
    'smallest_singular,rank,raw_status,all_reasons,status\n']);
  for idx = 1:length(rows)
    fprintf(fid, '%s,%d,%s,%d,%d,%.17g,%.17g,%s,%s,%s\n', ...
      rows(idx).case_name, rows(idx).level, rows(idx).representation_id, ...
      rows(idx).n_density, rows(idx).p_channels, ...
      rows(idx).smallest_singular, rows(idx).rank_value, ...
      rows(idx).raw_status, rows(idx).all_reasons, rows(idx).status);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_negative(rows, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case,primary_failure,all_failures,observed_metric,threshold,', ...
    'pass,raw_available,derived_available,F_aug_available,Sc_available,', ...
    'Rhat_minus_available,Rhat_plus_available,Fred_available,', ...
    'raw_schur_available,equivalence_available,root_ready,note\n']);
  for idx = 1:length(rows)
    fprintf(fid, ['%s,%s,%s,%.17g,%.17g,%d,%d,%d,%d,%d,%d,%d,', ...
      '%d,%d,%d,%s,%s\n'], ...
      rows(idx).case_name, rows(idx).primary_failure, ...
      LOCAL_csv_text(rows(idx).all_failures), rows(idx).observed_metric, ...
      rows(idx).threshold, rows(idx).pass, rows(idx).raw_available, ...
      rows(idx).derived_available, rows(idx).F_aug_available, ...
      rows(idx).Sc_available, rows(idx).Rhat_minus_available, ...
      rows(idx).Rhat_plus_available, rows(idx).Fred_available, ...
      rows(idx).raw_schur_available, rows(idx).equivalence_available, ...
      rows(idx).root_ready, LOCAL_csv_text(rows(idx).note));
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_csv_text(value)
  value = strrep(value, ',', ';');
  value = strrep(value, sprintf('\n'), ' ');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_svg(path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '<svg xmlns="http://www.w3.org/2000/svg" width="960" height="310">\n');
  fprintf(fid, '<rect width="960" height="310" fill="white"/>\n');
  fprintf(fid, '<style>text{font-family:monospace;font-size:14px}.b{fill:#eef4ff;stroke:#244}.a{fill:#fff5df;stroke:#642}</style>\n');
  fprintf(fid, '<rect class="b" x="20" y="90" width="180" height="90"/><text x="45" y="125">finite lead -</text><text x="42" y="150">4p amplitudes</text>\n');
  fprintf(fid, '<rect class="a" x="240" y="55" width="480" height="160"/><text x="285" y="90">ellipse center: A_c xi + B_L a_c^- + B_R b_c^+ = 0</text><text x="305" y="125">xi = D_h eta; direct J off-diagonal</text><text x="315" y="160">primary matrix: n + 8p columns</text><text x="330" y="195">nine frozen row groups</text>\n');
  fprintf(fid, '<rect class="b" x="760" y="90" width="180" height="90"/><text x="785" y="125">finite lead +</text><text x="782" y="150">4p amplitudes</text>\n');
  fprintf(fid, '<path d="M200 135 H240 M720 135 H760" stroke="#222" stroke-width="2"/><text x="270" y="265">raw Schur (retained a_c^-, b_c^+) == independent reduced oracle</text>\n');
  fprintf(fid, '</svg>\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_report(results, path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, '# Stage 2 augmented BIE discrete-algebra report\n\n');
  fprintf(fid, '- Decision: `%s`\n', results.stage2_status);
  fprintf(fid, '- Root readiness: `%s`\n', results.root_ready);
  fprintf(fid, '- Actual case label: `%s`\n', results.case_b.label);
  fprintf(fid, '- Overall pass: `%d`\n\n', results.all_pass);
  fprintf(fid, '## Scope\n\n');
  fprintf(fid, ['This bundle checks the frozen finite-dimensional block algebra, ', ...
    'density-coordinate scaling, conditional Schur reduction, and shared ', ...
    'availability gates. It does not perform a root search, call a modal ', ...
    'solver, or make physical kernel-field or multiplicity claims.\n\n']);
  fprintf(fid, '## Manufactured oracles\n\n');
  fprintf(fid, '- A1 augmented residual: `%.6e`\n', ...
    results.case_a1.augmented_residual);
  fprintf(fid, '- A1 raw/reduced Schur error: `%.6e`\n', ...
    results.case_a1.schur_error);
  fprintf(fid, '- A1 literal transmission-swap residuals: `%.6e, %.6e, %.6e`\n', ...
    results.case_a1.swap_residuals);
  fprintf(fid, ['- The original identity-transmission fixture could not detect a ', ...
    'literal `T_LR`/`T_RL` swap; the frozen fixture therefore uses the ', ...
    'nontrivial transmission blocks recorded in `results.mat`.\n']);
  fprintf(fid, '- A2 scaled/physical scattering error: `%.6e`\n', ...
    results.case_a2.scattering_error);
  fprintf(fid, '- A2 wrong-coordinate mismatch: `%.6e`\n\n', ...
    results.case_a2.mismatch);
  fprintf(fid, '## Actual interface smoke\n\n');
  fprintf(fid, ['The ellipse center uses `B=D_h B_phys` and `E=E_phys/D_h`; ', ...
    'the variable-speed raw `construct_S` result is not treated as physical ', ...
    'truth. The constant-speed circle is used as the allowed oracle.\n\n']);
  fprintf(fid, '| level | N | raw Schur error | forbidden delta ratio |\n');
  fprintf(fid, '|---:|---:|---:|---:|\n');
  for idx = 1:length(results.case_b.levels)
    row = results.case_b.levels(idx);
    fprintf(fid, '| %d | %d | %.6e | %.6e |\n', row.level, row.N, ...
      row.schur_error, row.delta_forbidden_ratio);
  end
  fprintf(fid, '\n## Computed availability propagation\n\n');
  fprintf(fid, ['Unavailable derived matrices are stored as fixed-size `NaN` ', ...
    'sentinels. Raw `F_aug` and `K_ee` are retained whenever primitive ', ...
    'dimensions and fingerprints pass.\n\n']);
  fprintf(fid, ['| case | F_aug | S_c | Rhat- | Rhat+ | F_red | raw Schur | ', ...
    'equivalence | root |\n']);
  fprintf(fid, '|---|---:|---:|---:|---:|---:|---:|---:|---|\n');
  central = {'WOOD_K_0P2', 'DOUBLING_EXACT_POLE', 'CENTER_EXACT_POLE', ...
    'ZERO_FIELD_EXACT', 'LEFT_TERMINAL_EXACT', 'RIGHT_TERMINAL_EXACT', ...
    'REP_CHANGED_DH'};
  for idx = 1:length(central)
    row_idx = find(strcmp({results.negative_cases.rows.case_name}, ...
      central{idx}), 1);
    row = results.negative_cases.rows(row_idx);
    fprintf(fid, '| %s | %d | %d | %d | %d | %d | %d | %d | %s |\n', ...
      row.case_name, row.F_aug_available, row.Sc_available, ...
      row.Rhat_minus_available, row.Rhat_plus_available, ...
      row.Fred_available, row.raw_schur_available, ...
      row.equivalence_available, row.root_ready);
  end
  fprintf(fid, '\n## Reproducibility\n\n');
  fprintf(fid, '- Status: `%s`\n', results.reproducibility.status);
  fprintf(fid, '- Relative difference: `%.6e`\n', ...
    results.reproducibility.relative_difference);
  fprintf(fid, ['- The source hash manifest covers the specification, symbol ', ...
    'appendix, all four reused BIE helpers, the experiment, and its wrapper.\n']);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_reproducibility(results, output_dir)
  path = fullfile(output_dir, 'reproducibility.txt');
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'status=%s\n', results.reproducibility.status);
  fprintf(fid, 'pass=%d\n', results.reproducibility.pass);
  fprintf(fid, 'relative_difference=%.17g\n', ...
    results.reproducibility.relative_difference);
  fprintf(fid, 'tolerance=%.17g\n', results.reproducibility.tolerance);
  fprintf(fid, 'unchanged_source_required=true\n');
  fprintf(fid, 'source_manifest_equal=%d\n', ...
    results.reproducibility.manifest_equal);
  fprintf(fid, 'source_hash_manifest=config.txt\n');
  fprintf(fid, 'manifest_scope=specification;symbol_appendix;BIE_helpers;experiment;wrapper\n');
  fprintf(fid, 'command=%s\n', results.config.command);
end
