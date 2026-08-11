function r = run_hg_adef(run_label)
%RUN_HG_ADEF Run the fail-closed I1.2 half-guide/A-def pilot.
% Purpose:
%   Verify the empty-center graph and Dirichlet-DtN formulas on deterministic
%   manufactured K=3 data, then qualify the frozen low-order real half-guide.
% Input:
%   run_label - output subdirectory label; default is 'pilot'.
% Output:
%   r - result struct saved verbatim to output/<run-label>/result.mat.
% Main algorithm:
%   Assemble independent Cauchy blocks, compare graph elimination with the
%   DtN form, execute registered negatives, and, after strict MATLAB input
%   provenance, run two-pass QZ, graph, chart, DtN, and A-def gates.
% Based on:
%   implementation/i1/design.md and the legacy i4-rayleigh one-cell/QZ data.
% Main changes:
%   Replaces the finite-tail map by independent original/reversed QZ graphs
%   and keeps M=5/8 explicitly below production M_trace=48.
% Numerical goal:
%   Return I1_2_PASS_LOW_ORDER only when every manufactured and real gate
%   passes; never construct a locator, root, estimator, or A-def derivative.
% Notes:
%   This is an assembly oracle only. It has no locator, root, or estimator.

  if nargin < 1 || isempty(run_label)
    run_label = 'pilot';
  end
  cfg = config();
  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(fileparts(here)));
  addpath(repo_root);
  output_dir = fullfile(here, 'output', run_label);
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end
  t_all = tic;

  % --- stage 1: deterministic manufactured graph data ---
  K = cfg.K;
  I = eye(K);
  Gamma = diag([0.7, 1.1, 1.6]);
  E = diag(exp(1i * diag(Gamma) * cfg.W));
  Dm = [1.10, 0.08i, 0.02; 0, 0.90, -0.04i; 0.03, 0, 1.30];
  Nm = [0.32i, 0.07, 0; -0.02, 0.61i, 0.05; 0, 0.03, 0.48i];
  Dp = [0.95, -0.03, 0.06i; 0.04i, 1.25, 0; 0, 0.02, 1.05];
  Np = [0.55i, 0, -0.04; 0.06, 0.37i, 0.02i; 0, -0.05, 0.69i];
  Lambda_m = Nm / Dm;
  Lambda_p = Np / Dp;
  A_D = LOCAL_assemble_dtn(Gamma, E, Lambda_m, Lambda_p);
  A_G = LOCAL_assemble_graph(Gamma, E, Dm, Nm, Dp, Np);

  scattering.R_L = [0.11i, 0.03, -0.02; 0.01, -0.07i, 0.04; 0, 0.02, 0.09i];
  scattering.T_RL = [0.82, 0.06i, 0.01; -0.03, 0.74, 0.05i; 0.02i, 0, 0.68];
  scattering.T_LR = [0.61, -0.02, 0.07i; 0.05i, 0.79, -0.01; 0.03, 0.04i, 0.57];
  scattering.R_R = [-0.05i, 0.01, 0.03; -0.02i, 0.13i, 0; 0.04, -0.01, 0.06i];
  cell_pair = LOCAL_cell_pair(scattering);

  gates = {};
  dim_error = max([abs(size(A_D) - [2*K, 2*K]), ...
    abs(size(A_G) - [4*K, 4*K])]);
  gates(end+1, :) = LOCAL_gate('manufactured', 'dimensions', ...
    'PASS', dim_error == 0, dim_error, 0, '2K and 4K dimensions and orders');

  expected_A_sc = [-scattering.R_L, I; scattering.T_LR, zeros(K)];
  expected_B_sc = [zeros(K), scattering.T_RL; I, -scattering.R_R];
  pencil_formula_error = norm([cell_pair.A_sc, cell_pair.B_sc] - ...
    [expected_A_sc, expected_B_sc], 'fro');
  gates(end+1, :) = LOCAL_gate('manufactured', 'cell_pair_formula', ...
    'PASS', pencil_formula_error <= cfg.tol_alg, pencil_formula_error, ...
    cfg.tol_alg, 'A_sc=[-R_L I;T_LR 0], B_sc=[0 T_RL;I -R_R]');

  expected_left_D = [I, E];
  expected_left_N = [-1i*Gamma, 1i*Gamma*E];
  expected_right_D = [E, I];
  expected_right_N = [1i*Gamma*E, -1i*Gamma];
  sign_error = max([norm(A_G(1:K, 1:2*K) - expected_left_D, 'fro'), ...
    norm(A_G(K+1:2*K, 1:2*K) - expected_left_N, 'fro'), ...
    norm(A_G(2*K+1:3*K, 1:2*K) - expected_right_D, 'fro'), ...
    norm(A_G(3*K+1:4*K, 1:2*K) - expected_right_N, 'fro')]);
  gates(end+1, :) = LOCAL_gate('manufactured', 'left_right_cauchy_signs', ...
    'PASS', sign_error <= cfg.tol_alg, sign_error, cfg.tol_alg, ...
    'outward normals and wall anchoring');

  d_rows = [1:K, 2*K+1:3*K];
  n_rows = [K+1:2*K, 3*K+1:4*K];
  q_cols = 1:2*K;
  c_cols = 2*K+1:4*K;
  A_schur = A_G(n_rows, q_cols) - ...
    A_G(n_rows, c_cols) * (A_G(d_rows, c_cols) \ A_G(d_rows, q_cols));
  schur_error = norm(A_schur - A_D, 'fro') / max(1, norm(A_D, 'fro'));
  gates(end+1, :) = LOCAL_gate('manufactured', 'graph_dtn_schur', ...
    'PASS', schur_error <= cfg.tol_alg, schur_error, cfg.tol_alg, ...
    'left solve elimination; no explicit inverse');

  Sm = [1, 0.2i, 0; 0.1, 1.1, -0.1; 0, 0.05, 0.9];
  Sp = [0.9, -0.1, 0.04i; 0, 1.2, 0.08; 0.03, 0, 1.05];
  A_G_basis = LOCAL_assemble_graph(Gamma, E, Dm*Sm, Nm*Sm, Dp*Sp, Np*Sp);
  T_basis = blkdiag(eye(2*K), Sm, Sp);
  basis_graph_error = norm(A_G_basis - A_G*T_basis, 'fro') / ...
    max(1, norm(A_G, 'fro'));
  basis_dtn_error = norm(LOCAL_assemble_dtn(Gamma, E, ...
    (Nm*Sm)/(Dm*Sm), (Np*Sp)/(Dp*Sp)) - A_D, 'fro') / ...
    max(1, norm(A_D, 'fro'));
  basis_error = max(basis_graph_error, basis_dtn_error);
  gates(end+1, :) = LOCAL_gate('manufactured', 'graph_basis_invariance', ...
    'PASS', basis_error <= cfg.tol_alg, basis_error, cfg.tol_alg, ...
    'nonsingular left and right graph-coordinate changes');

  safe_m = LOCAL_chart(Dm, Nm, cfg.graph_error, cfg);
  safe_p = LOCAL_chart(Dp, Np, cfg.graph_error, cfg);
  safe_chart_error = max(norm(safe_m.Lambda-Lambda_m, 'fro'), ...
    norm(safe_p.Lambda-Lambda_p, 'fro'));
  safe_chart_pass = safe_m.dtn_available && safe_p.dtn_available && ...
    safe_chart_error <= cfg.tol_alg;
  gates(end+1, :) = LOCAL_gate('manufactured', 'safe_dirichlet_chart', ...
    'PASS', safe_chart_pass, safe_chart_error, cfg.tol_alg, ...
    'safe DtN formation uses the same chart decision routine');

  D_vertical = cfg.unsafe_D_scale * I;
  N_vertical = I;
  vertical_chart = LOCAL_chart(D_vertical, N_vertical, cfg.graph_error, cfg);
  retained_graph = ~vertical_chart.dtn_available && ...
    strcmp(vertical_chart.realization, 'CAUCHY_RELATION');
  gates(end+1, :) = LOCAL_gate('manufactured', 'unsafe_dirichlet_retains_graph', ...
    'PASS', retained_graph, vertical_chart.margin_D, 100*K*eps, ...
    'D=1e-12 I returns dtn_available=false and CAUCHY_RELATION');

  [infinite_status, infinite_ok] = LOCAL_pair_class(1, 0, cfg.tol_alg);
  [neutral_status, neutral_ok] = LOCAL_pair_class(1i, 1, cfg.tol_alg);
  [indeterminate_status, indeterminate_ok] = LOCAL_pair_class(0, 0, cfg.tol_alg);
  pair_ok = infinite_ok && ~neutral_ok && ~indeterminate_ok;
  gates(end+1, :) = LOCAL_gate('manufactured', 'projective_pair_policy', ...
    'PASS', pair_ok, double(pair_ok), 1, ...
    [infinite_status, ';', neutral_status, ';', indeterminate_status]);
  scale_values = [1e-120*exp(0.3i), 1e120*exp(-0.4i)];
  [base_status, base_ok] = LOCAL_pair_class(0.4+0.2i, 1.3-0.1i, cfg.tol_alg);
  scale_ok = true;
  for j = 1:numel(scale_values)
    [scaled_status, scaled_ok] = LOCAL_pair_class( ...
      scale_values(j)*(0.4+0.2i), scale_values(j)*(1.3-0.1i), cfg.tol_alg);
    scale_ok = scale_ok && scaled_ok == base_ok && strcmp(scaled_status, base_status);
  end
  gates(end+1, :) = LOCAL_gate('manufactured', 'projective_scaling', ...
    'PASS', scale_ok, double(scale_ok), 1, 'classification invariant under common scaling');

  % --- stage 2: registered mutation negatives ---
  negatives = {};
  A_sign = A_D;
  A_sign(1:K, 1:K) = -(-1i*Gamma + Lambda_m);
  negatives(end+1, :) = LOCAL_negative('normal_sign', ...
    LOCAL_rel_change(A_D, A_sign), cfg.tol_mutation);
  E_reference = diag(exp(1i * diag(Gamma) * (cfg.W + 0.17)));
  negatives(end+1, :) = LOCAL_negative('reference_plane', ...
    LOCAL_rel_change(A_D, LOCAL_assemble_dtn(Gamma, E_reference, ...
    Lambda_m, Lambda_p)), cfg.tol_mutation);
  swapped = scattering;
  swapped.T_RL = scattering.T_LR;
  swapped.T_LR = scattering.T_RL;
  swapped_pair = LOCAL_cell_pair(swapped);
  negatives(end+1, :) = LOCAL_negative('trl_tlr_pencil_swap', ...
    LOCAL_rel_change([cell_pair.A_sc, cell_pair.B_sc], ...
    [swapped_pair.A_sc, swapped_pair.B_sc]), cfg.tol_mutation);
  E_back = E \ I;
  negatives(end+1, :) = LOCAL_negative('e_inverse_anchoring', ...
    LOCAL_rel_change(A_D, LOCAL_assemble_dtn(Gamma, E_back, ...
    Lambda_m, Lambda_p)), cfg.tol_mutation);
  row_perm = [K+1:2*K, 1:K, 3*K+1:4*K, 2*K+1:3*K];
  col_perm = [K+1:2*K, 1:K, 3*K+1:4*K, 2*K+1:3*K];
  negatives(end+1, :) = LOCAL_negative('row_unknown_order', ...
    LOCAL_rel_change(A_G, A_G(row_perm, col_perm)), cfg.tol_mutation);
  negative_pass = all(cell2mat(negatives(:, 4)));
  manufactured_negative_pass = negative_pass;
  gates(end+1, :) = LOCAL_gate('manufactured', 'registered_negatives', ...
    'PASS', negative_pass, min(cell2mat(negatives(:, 2))), ...
    cfg.tol_mutation, 'every mutation must be detected');

  % --- stage 3: fail-closed real-input preflight ---
  input_path = fullfile(here, 'input', 'cell.mat');
  [preflight_ok, preflight_note, provenance] = ...
    LOCAL_preflight(input_path, cfg, here, repo_root);
  if preflight_ok
    preflight_status = 'PASS';
  else
    preflight_status = 'CELL_INPUT_PROVENANCE_FAIL';
  end
  gates(end+1, :) = LOCAL_gate('real', 'cell_input_provenance', ...
    preflight_status, preflight_ok, double(preflight_ok), 1, preflight_note);
  real_names = {'real_qz', 'real_halfguide_graph', 'real_dtn', 'real_adef'};
  real = LOCAL_empty_real();
  if preflight_ok && strcmp(LOCAL_runtime_name(), 'MATLAB')
    data = load(input_path, 'cell_data');
    real = LOCAL_real_chain(data.cell_data, cfg);
    gates = [gates; real.gates];
    negatives = [negatives; real.neg_rows];
    negative_pass = all(cell2mat(negatives(:,4)));
  else
    if preflight_ok
      later_note = 'strict input passed, but the real chain is MATLAB-only';
    else
      later_note = 'CELL_INPUT_PROVENANCE_FAIL blocks all real constructors';
    end
    for j = 1:numel(real_names)
      gates(end+1, :) = LOCAL_gate('real', real_names{j}, ...
        'NOT_RUN_PREREQ', false, NaN, NaN, later_note);
    end
  end

  % --- stage 4: persist auditable artifacts ---
  manufactured_rows = strcmp(gates(:, 1), 'manufactured');
  manufactured_pass = all(cell2mat(gates(manufactured_rows, 4)));
  if manufactured_pass && manufactured_negative_pass && preflight_ok && real.pass
    overall_status = 'I1_2_PASS_LOW_ORDER';
  elseif manufactured_pass && manufactured_negative_pass && preflight_ok && ...
      ~isempty(real.first_failure)
    overall_status = 'I1_2_BLOCKED_REAL';
  elseif manufactured_pass && manufactured_negative_pass && ~preflight_ok
    overall_status = 'MANUFACTURED_PASS_REAL_NOT_RUN_PREREQ';
  elseif manufactured_pass && manufactured_negative_pass
    overall_status = 'MANUFACTURED_PASS_REAL_NOT_RUN_PREREQ';
  else
    overall_status = 'MANUFACTURED_FAIL';
  end
  elapsed = toc(t_all);
  timing = {'total_pilot', elapsed, 'manufactured oracle plus real preflight'};
  r = struct();
  r.run_label = run_label;
  r.status = overall_status;
  r.K = K;
  r.tol_alg = cfg.tol_alg;
  r.tol_mutation = cfg.tol_mutation;
  r.derivative_available = cfg.derivative_available;
  r.gates = gates;
  r.negatives = negatives;
  r.provenance = provenance;
  r.real = real;
  r.A_def_D_manufactured = A_D;
  r.A_def_G_manufactured = A_G;
  r.elapsed_seconds = elapsed;
  r.preflight_status = preflight_status;
  r.config_snapshot = cfg;
  r.environment = struct('runtime', LOCAL_runtime_name(), 'version', version, ...
    'git_sha', LOCAL_git_sha(repo_root));

  LOCAL_write_csv(fullfile(output_dir, 'gates.csv'), ...
    {'category','gate','status','pass','value','tolerance','note'}, gates);
  LOCAL_write_csv(fullfile(output_dir, 'neg.csv'), ...
    {'mutation','relative_change','threshold','pass'}, negatives);
  LOCAL_write_csv(fullfile(output_dir, 'timing.csv'), ...
    {'stage','seconds','note'}, timing);
  LOCAL_write_csv(fullfile(output_dir, 'qz.csv'), ...
    {'M','level','side','plane','stable','unstable','neutral','infinite', ...
    'indeterminate','tau_proj','raw_residual','residual','unit_gap', ...
    'sep_u','sep_l','sep','wall_residual','pass'}, ...
    real.qz_rows);
  LOCAL_write_csv(fullfile(output_dir, 'wall.csv'), ...
    {'M','level','plus_residual','minus_residual','mode_order_flip','pass'}, ...
    real.wall_rows);
  LOCAL_write_csv(fullfile(output_dir, 'swap.csv'), ...
    {'M','level','plus_available','plus_status','plus_residual', ...
    'minus_available','minus_status','minus_residual','detected','pass'}, ...
    real.swap_rows);
  LOCAL_write_csv(fullfile(output_dir, 'level.csv'), ...
    {'M','pair_change','subspace_plus','subspace_minus','action_plus', ...
    'action_minus','graph_plus_low','graph_plus_high', ...
    'graph_minus_low','graph_minus_high','pass'}, ...
    real.level_rows);
  LOCAL_write_csv(fullfile(output_dir, 'chart.csv'), ...
    {'M','side','margin','condition','graph_error','realization', ...
    'solve_residual','safe'}, real.chart_rows);
  LOCAL_write_csv(fullfile(output_dir, 'adef.csv'), ...
    {'M','rows_dtn','rows_graph','schur_error','tolerance','pass'}, ...
    real.adef_rows);
  save(fullfile(output_dir, 'result.mat'), 'r');
  LOCAL_write_report(fullfile(output_dir, 'report.md'), r);
  LOCAL_write_log(fullfile(output_dir, 'run.log'), r, input_path);
  LOCAL_write_estimate(fullfile(output_dir, 'estimate.md'), r);
  fprintf('HG_ADEF_STATUS=%s\n', overall_status);
  fprintf('HG_ADEF_OUTPUT=%s\n', output_dir);
end

%% ==================== Assembly helpers ====================
% These helpers keep each manufactured formula and ledger operation explicit.

function A = LOCAL_assemble_dtn(Gamma, E, Lambda_m, Lambda_p)
  A = [-(1i*Gamma + Lambda_m), (1i*Gamma - Lambda_m)*E; ...
    (1i*Gamma - Lambda_p)*E, -(1i*Gamma + Lambda_p)];
end

function A = LOCAL_assemble_graph(Gamma, E, Dm, Nm, Dp, Np)
  K = size(Gamma, 1);
  I = eye(K);
  Z = zeros(K);
  A = [I, E, -Dm, Z; ...
    -1i*Gamma, 1i*Gamma*E, -Nm, Z; ...
    E, I, Z, -Dp; ...
    1i*Gamma*E, -1i*Gamma, Z, -Np];
end

function pair = LOCAL_cell_pair(S)
  K = size(S.R_L, 1);
  pair.A_sc = [-S.R_L, eye(K); S.T_LR, zeros(K)];
  pair.B_sc = [zeros(K), S.T_RL; eye(K), -S.R_R];
  pair.state_order = {'a_L', 'b_L'};
  pair.reference_planes = {'LEFT_CELL_WALL', 'RIGHT_CELL_WALL'};
end

function chart = LOCAL_chart(D, N, graph_error, cfg, beta_m)
  if nargin < 5
    beta_m = zeros(size(D,1),1);
  end
  K = size(D,1);
  bracket = sqrt(1+abs(beta_m(:)).^2);
  GD_half = diag(sqrt(bracket));
  GD = diag(bracket);
  GN = diag(1./bracket);
  graph_gram = D'*GD*D + N'*GN*N;
  [V, L] = eig((graph_gram + graph_gram')/2);
  graph_half = V*diag(sqrt(max(real(diag(L)), 0)))*V';
  D_weighted = GD_half*D;
  D_bar = (graph_half.' \ D_weighted.').';
  singular_values = svd(D_bar);
  chart.margin_D = min(singular_values);
  chart.cond_D = max(singular_values) / chart.margin_D;
  safe = chart.margin_D > 100*K*eps && ...
    graph_error/chart.margin_D <= 1e-9 && chart.cond_D*eps <= 1e-9;
  if safe
    chart.realization = 'DIRICHLET_DTN';
    chart.dtn_available = true;
    chart.Lambda = LOCAL_right_solve(N,D);
    chart.solve_residual = norm(chart.Lambda*D-N,'fro') / ...
      max(1,norm(N,'fro'));
    safe = chart.solve_residual <= 1e3*K*eps;
    chart.dtn_available = safe;
    if ~safe
      chart.realization = 'CAUCHY_RELATION';
      chart.Lambda = [];
    end
  else
    chart.realization = 'CAUCHY_RELATION';
    chart.dtn_available = false;
    chart.Lambda = [];
    chart.solve_residual = NaN;
  end
end

function row = LOCAL_gate(category, name, status, pass, value, tolerance, note)
  row = {category, name, status, logical(pass), value, tolerance, note};
end

function row = LOCAL_negative(name, value, threshold)
  row = {name, value, threshold, logical(value > threshold)};
end

function value = LOCAL_rel_change(A, B)
  value = norm(A - B, 'fro') / max(1, norm(A, 'fro'));
end

function [status, accepted] = LOCAL_pair_class(alpha, beta, tolerance)
  projective_norm = hypot(abs(alpha), abs(beta));
  if projective_norm == 0 || ~isfinite(projective_norm)
    status = 'INDETERMINATE_REJECTED';
    accepted = false;
    return;
  end
  alpha = alpha / projective_norm;
  beta = beta / projective_norm;
  if abs(beta) <= tolerance
    status = 'REGULAR_INFINITE_ACCEPTED';
    accepted = true;
  elseif abs(abs(alpha) - abs(beta)) <= tolerance
    status = 'NEUTRAL_REJECTED';
    accepted = false;
  else
    status = 'FINITE_ACCEPTED';
    accepted = true;
  end
end

%% ==================== Real half-guide helpers ====================
% These helpers qualify the two QZ graphs before any safe-DtN elimination.

function real = LOCAL_empty_real()
  real = struct('pass', false, 'first_failure', '', 'scope', ...
    'LOW_ORDER_M5_M8_NOT_PRODUCTION_MTRACE48', 'gates', {cell(0,7)}, ...
    'qz_rows', {cell(0,18)}, 'wall_rows', {cell(0,6)}, ...
    'swap_rows', {cell(0,10)}, ...
    'level_rows', {cell(0,11)}, 'neg_rows', {cell(0,4)}, ...
    'chart_rows', {cell(0,8)}, 'adef_rows', {cell(0,6)}, ...
    'levels', []);
end

function real = LOCAL_real_chain(cell_data, cfg)
  real = LOCAL_empty_real();
  Ms = [5, 8];
  level_results = cell(2, 2);
  wall_ok = isequal(cell_data.wall_labels, ...
    {'LEFT_CELL_WALL', 'RIGHT_CELL_WALL'});
  real.gates(end+1,:) = LOCAL_gate('real', 'reference_wall_labels', ...
    LOCAL_pass_text(wall_ok), wall_ok, double(wall_ok), 1, ...
    'right pass starts at LEFT_CELL_WALL; reversed pass starts at RIGHT_CELL_WALL');
  if ~wall_ok
    real.first_failure = 'REFERENCE_WALL_LABEL_FAIL';
    real.gates = LOCAL_stop_rows(real.gates, ...
      {'real_qz','real_reference_wall','real_halfguide_graph','real_dtn','real_adef'}, ...
      real.first_failure);
    return;
  end

  % --- real stage 1: ordered-QZ frames and exact separation ---
  names = {'low','high'};
  qz_ok = true;
  ref_ok = true;
  graph_swap_ok = true;
  for im = 1:numel(Ms)
    M = Ms(im);
    for il = 1:numel(names)
      level = cell_data.(names{il});
      reduced = LOCAL_restrict_level(level, M, cell_data.master_M);
      result = LOCAL_two_pass(reduced, M, cfg);
      if result.plus.pass && result.minus.pass
        wall = LOCAL_wall_check(reduced.blocks, result.plus.Z, result.minus.Z);
        graph_swap = LOCAL_graph_swap(reduced.blocks, result.plus.Z, ...
          result.minus.Z, cfg.tol_mutation);
        result.plus.wall_residual = wall.plus_residual;
        result.minus.wall_residual = wall.minus_residual;
        wall_pass = max(wall.plus_residual,wall.minus_residual) <= ...
          cfg.real.qz_residual_max && wall.mode_order_flip > cfg.tol_mutation;
      else
        wall = struct('plus_residual',NaN,'minus_residual',NaN, ...
          'mode_order_flip',NaN);
        result.plus.wall_residual = NaN;
        result.minus.wall_residual = NaN;
        wall_pass = false;
        graph_swap = struct('plus_available',false,'plus_residual',NaN, ...
          'plus_status','NOT_RUN_QZ_PREREQ', ...
          'minus_available',false,'minus_residual',NaN, ...
          'minus_status','NOT_RUN_QZ_PREREQ', ...
          'detected',false,'pass',false);
      end
      real.wall_rows(end+1,:) = {M,names{il},wall.plus_residual, ...
        wall.minus_residual,wall.mode_order_flip,wall_pass};
      real.neg_rows(end+1,:) = {sprintf('mode_order_flip_M%d_%s',M,names{il}), ...
        wall.mode_order_flip,cfg.tol_mutation, ...
        wall.mode_order_flip > cfg.tol_mutation};
      ref_ok = ref_ok && wall_pass;
      real.swap_rows(end+1,:) = {M,names{il},graph_swap.plus_available, ...
        graph_swap.plus_status,graph_swap.plus_residual, ...
        graph_swap.minus_available,graph_swap.minus_status, ...
        graph_swap.minus_residual,graph_swap.detected,graph_swap.pass};
      graph_swap_ok = graph_swap_ok && graph_swap.pass;
      level_results{im,il} = result;
      for side = 1:2
        if side == 1
          q = result.plus; side_name = 'plus'; plane = 'LEFT_CELL_WALL';
        else
          q = result.minus; side_name = 'minus'; plane = 'RIGHT_CELL_WALL';
        end
        real.qz_rows(end+1,:) = {M, names{il}, side_name, plane, ...
          q.stable_count, q.unstable_count, q.neutral_count, ...
          q.infinite_count, q.indeterminate_count, q.tau_proj, ...
          q.raw_residual, q.residual, q.unit_gap, q.sep_u, q.sep_l, ...
          q.sep, q.wall_residual, q.pass};
        qz_ok = qz_ok && q.pass;
      end
      if ~qz_ok
        break;
      end
    end
    if ~qz_ok
      break;
    end
  end
  real.gates(end+1,:) = LOCAL_gate('real', 'real_qz', ...
    LOCAL_pass_text(qz_ok), qz_ok, double(qz_ok), 1, ...
    'exact K counts, no neutral/indeterminate pairs, residual and two separations gated');
  if ~qz_ok
    real.first_failure = 'REAL_QZ_OR_SEPARATION_FAIL';
    real.gates = LOCAL_stop_rows(real.gates, ...
      {'real_reference_wall','real_halfguide_graph','real_dtn','real_adef'}, ...
      real.first_failure);
    real.levels = level_results;
    return;
  end
  real.gates(end+1,:) = LOCAL_gate('real', 'real_reference_wall', ...
    LOCAL_pass_text(ref_ok), ref_ok, double(ref_ok), 1, ...
    'independent graph fixed-point identities and mode-order flip mutation');
  if ~ref_ok
    real.first_failure = 'REAL_REFERENCE_WALL_FAIL';
    real.gates = LOCAL_stop_rows(real.gates, ...
      {'real_halfguide_graph','real_dtn','real_adef'}, real.first_failure);
    real.levels = level_results;
    return;
  end
  real.gates(end+1,:) = LOCAL_gate('real', 'wall_graph_swap', ...
    LOCAL_pass_text(graph_swap_ok), graph_swap_ok, double(graph_swap_ok), 1, ...
    'Zminus on plus wall and Zplus on minus wall must mismatch or expose unsafe graph chart');
  if ~graph_swap_ok
    real.first_failure = 'WALL_GRAPH_SWAP_UNDETECTED';
    real.gates = LOCAL_stop_rows(real.gates, ...
      {'real_halfguide_graph','real_dtn','real_adef'}, real.first_failure);
    real.levels = level_results;
    return;
  end

  % --- real stage 2: adjacent discretization and graph qualification ---
  graph_ok = true;
  for im = 1:numel(Ms)
    low = level_results{im,1};
    high = level_results{im,2};
    pair_change = LOCAL_pair_change(low.pair, high.pair);
    sub_p = LOCAL_projector_change(low.plus.Z, high.plus.Z);
    sub_m = LOCAL_projector_change(low.minus.Z, high.minus.Z);
    graph_pl = max(pair_change, low.plus.residual) / low.plus.sep;
    graph_ph = max(pair_change, high.plus.residual) / high.plus.sep;
    graph_ml = max(pair_change, low.minus.residual) / low.minus.sep;
    graph_mh = max(pair_change, high.minus.residual) / high.minus.sep;
    pass = max([sub_p,sub_m]) <= cfg.real.level_change_max && ...
      max([graph_pl,graph_ph,graph_ml,graph_mh]) <= cfg.real.graph_error_max;
    real.level_rows(end+1,:) = {Ms(im), pair_change, sub_p, sub_m, ...
      NaN, NaN, graph_pl, graph_ph, graph_ml, graph_mh, pass};
    level_results{im,1}.graph_error_plus = graph_pl;
    level_results{im,1}.graph_error_minus = graph_ml;
    level_results{im,2}.graph_error_plus = graph_ph;
    level_results{im,2}.graph_error_minus = graph_mh;
    graph_ok = graph_ok && pass;
    if ~pass
      break;
    end
  end
  real.gates(end+1,:) = LOCAL_gate('real', 'real_halfguide_graph', ...
    LOCAL_pass_text(graph_ok), graph_ok, double(graph_ok), 1, ...
    'low/high same-M projectors <=1e-7; both-level graph estimates <=1e-9');
  if ~graph_ok
    real.first_failure = 'REAL_HALF_GUIDE_STABILITY_FAIL';
    real.gates = LOCAL_stop_rows(real.gates, {'real_dtn','real_adef'}, ...
      real.first_failure);
    real.levels = level_results;
    return;
  end

  % --- real stage 3: shared chart and graph/DtN A-def equivalence ---
  dtn_ok = true;
  dtn_failure = '';
  adef_ok = true;
  high_lambdas = cell(2,2);
  for im = 1:numel(Ms)
    low = level_results{im,1};
    high = level_results{im,2};
    K = 2*Ms(im)+1;
    [Dp_l,Np_l,Dm_l,Nm_l] = LOCAL_cauchy(low, low.Gamma);
    [Dp,Np,Dm,Nm] = LOCAL_cauchy(high, high.Gamma);
    chart_pl = LOCAL_chart(Dp_l, Np_l, low.graph_error_plus, cfg, low.beta_m);
    chart_ml = LOCAL_chart(Dm_l, Nm_l, low.graph_error_minus, cfg, low.beta_m);
    chart_p = LOCAL_chart(Dp, Np, high.graph_error_plus, cfg, high.beta_m);
    chart_m = LOCAL_chart(Dm, Nm, high.graph_error_minus, cfg, high.beta_m);
    real.chart_rows(end+1,:) = {Ms(im),'plus-low',chart_pl.margin_D, ...
      chart_pl.cond_D,low.graph_error_plus,chart_pl.realization, ...
      chart_pl.solve_residual,chart_pl.dtn_available};
    real.chart_rows(end+1,:) = {Ms(im),'minus-low',chart_ml.margin_D, ...
      chart_ml.cond_D,low.graph_error_minus,chart_ml.realization, ...
      chart_ml.solve_residual,chart_ml.dtn_available};
    real.chart_rows(end+1,:) = {Ms(im),'plus',chart_p.margin_D, ...
      chart_p.cond_D,high.graph_error_plus,chart_p.realization, ...
      chart_p.solve_residual,chart_p.dtn_available};
    real.chart_rows(end+1,:) = {Ms(im),'minus',chart_m.margin_D, ...
      chart_m.cond_D,high.graph_error_minus,chart_m.realization, ...
      chart_m.solve_residual,chart_m.dtn_available};
    dtn_ok = dtn_ok && chart_pl.dtn_available && chart_ml.dtn_available && ...
      chart_p.dtn_available && chart_m.dtn_available;
    if ~dtn_ok
      dtn_failure = 'REAL_DIRICHLET_CHART_UNSAFE';
      break;
    end
    act_p = LOCAL_rel_change(chart_pl.Lambda,chart_p.Lambda);
    act_m = LOCAL_rel_change(chart_ml.Lambda,chart_m.Lambda);
    real.level_rows{im,5} = act_p;
    real.level_rows{im,6} = act_m;
    action_ok = max(act_p,act_m) <= cfg.real.level_change_max;
    real.level_rows{im,11} = real.level_rows{im,11} && action_ok;
    dtn_ok = dtn_ok && action_ok;
    if ~dtn_ok
      dtn_failure = 'REAL_LOW_HIGH_ACTION_FAIL';
      break;
    end
    high_lambdas{im,1} = chart_p.Lambda;
    high_lambdas{im,2} = chart_m.Lambda;
    A_D_real = LOCAL_assemble_dtn(high.Gamma, high.E, ...
      chart_m.Lambda, chart_p.Lambda);
    A_G_real = LOCAL_assemble_graph(high.Gamma, high.E, Dm, Nm, Dp, Np);
    d_rows = [1:K,2*K+1:3*K];
    n_rows = [K+1:2*K,3*K+1:4*K];
    q_cols = 1:2*K;
    c_cols = 2*K+1:4*K;
    A_schur = A_G_real(n_rows,q_cols) - A_G_real(n_rows,c_cols) * ...
      (A_G_real(d_rows,c_cols) \ A_G_real(d_rows,q_cols));
    schur_error = LOCAL_rel_change(A_D_real, A_schur);
    schur_tol = cfg.real.schur_factor*K*eps;
    pass = isequal(size(A_D_real),[2*K,2*K]) && ...
      isequal(size(A_G_real),[4*K,4*K]) && schur_error <= schur_tol;
    real.adef_rows(end+1,:) = {Ms(im),size(A_D_real,1), ...
      size(A_G_real,1),schur_error,schur_tol,pass};
    adef_ok = adef_ok && pass;
    if ~pass
      break;
    end
  end
  if dtn_ok
    K5 = 11;
    K8 = 17;
    P5 = zeros(K5,K8);
    P5(:,4:14) = eye(K5);
    Q5 = P5';
    mact_p = LOCAL_rel_change(high_lambdas{1,1}, ...
      P5*high_lambdas{2,1}*Q5);
    mact_m = LOCAL_rel_change(high_lambdas{1,2}, ...
      P5*high_lambdas{2,2}*Q5);
    m_action_ok = max(mact_p,mact_m) <= cfg.real.level_change_max;
    real.gates(end+1,:) = LOCAL_gate('real','m5_m8_action', ...
      LOCAL_pass_text(m_action_ok),m_action_ok,max(mact_p,mact_m), ...
      cfg.real.level_change_max, ...
      'explicit P5*Lambda_M8*Q5 common-retained action; no unequal projector comparison');
    dtn_ok = dtn_ok && m_action_ok;
    if ~m_action_ok
      dtn_failure = 'REAL_M5_M8_ACTION_FAIL';
    end
  else
    real.gates(end+1,:) = LOCAL_gate('real','m5_m8_action', ...
      'NOT_RUN_PREREQ',false,NaN,NaN,'unsafe or unstable same-M DtN action');
  end
  real.gates(end+1,:) = LOCAL_gate('real', 'real_dtn', ...
    LOCAL_pass_text(dtn_ok), dtn_ok, double(dtn_ok), 1, ...
    'shared weighted Dirichlet chart; unsafe charts retain the graph and stop');
  if ~dtn_ok
    real.first_failure = dtn_failure;
    real.gates = LOCAL_stop_rows(real.gates, {'real_adef'}, real.first_failure);
    real.levels = level_results;
    return;
  end
  real.gates(end+1,:) = LOCAL_gate('real', 'real_adef', ...
    LOCAL_pass_text(adef_ok), adef_ok, double(adef_ok), 1, ...
    'safe DtN A-def equals exact graph elimination at M=5 and M=8');
  if ~adef_ok
    real.first_failure = 'REAL_ADEF_SCHUR_FAIL';
  else
    real.pass = true;
  end
  real.levels = level_results;
end

function reduced = LOCAL_restrict_level(level, M, master_M)
  idx = (master_M-M+1):(master_M+M+1);
  names = {'R_L','T_RL','T_LR','R_R'};
  S = struct();
  for j = 1:numel(names)
    S.(names{j}) = level.blocks.(names{j})(idx,idx);
  end
  reduced.pair = LOCAL_cell_pair(S);
  reduced.blocks = S;
  reduced.Gamma = diag(level.modes.gamma_m(idx));
  reduced.E = diag(level.modes.phase(idx));
  reduced.beta_m = level.modes.beta_m(idx);
end

function result = LOCAL_two_pass(reduced, M, cfg)
  result = reduced;
  result.plus = LOCAL_qz_pass(reduced.pair.A_sc, reduced.pair.B_sc, ...
    M, cfg);
  result.minus = LOCAL_qz_pass(reduced.pair.B_sc, reduced.pair.A_sc, ...
    M, cfg);
end

function q = LOCAL_qz_pass(A, B, M, cfg)
  K = 2*M+1;
  rho = hypot(norm(A,'fro'),norm(B,'fro'));
  A = A/rho;
  B = B/rho;
  [S,T,Q,Z] = qz(A,B,'complex');
  raw_left = Q';
  raw_residual = hypot(norm(A-raw_left*S*Z','fro'), ...
    norm(B-raw_left*T*Z','fro'));
  tau_proj = max(100*eps,10*raw_residual);
  cls = LOCAL_classify_diag(diag(S),diag(T),tau_proj);
  q = struct('stable_count',sum(cls.stable), ...
    'unstable_count',sum(cls.unstable), 'neutral_count',sum(cls.neutral), ...
    'infinite_count',sum(cls.infinite), ...
    'indeterminate_count',sum(cls.indeterminate), 'unit_gap',cls.unit_gap, ...
    'tau_proj',tau_proj,'raw_residual',raw_residual,'residual',Inf, ...
    'sep_u',0,'sep_l',0,'sep',0,'wall_residual',NaN, ...
    'Z',zeros(2*K,K),'pass',false);
  count_ok = q.stable_count == K && q.unstable_count == K && ...
    q.neutral_count == 0 && q.indeterminate_count == 0;
  if ~count_ok
    return;
  end
  [So,To,Qo,Zo] = ordqz(S,T,Q,Z,cls.stable);
  Zs = Zo(:,1:K);
  Qleft = Qo';
  Qs = Qleft(:,1:K);
  residuals = [norm(A-Qleft*So*Zo','fro'),norm(B-Qleft*To*Zo','fro'), ...
    norm(A*Zs-Qs*So(1:K,1:K),'fro'), ...
    norm(B*Zs-Qs*To(1:K,1:K),'fro')];
  q.residual = max(residuals);
  [q.sep_u,q.sep_l] = LOCAL_exact_sep(So,To,K);
  q.sep = min(q.sep_u,q.sep_l);
  q.Z = Zs;
  q.pass = q.raw_residual <= cfg.real.qz_residual_max && ...
    q.residual <= cfg.real.qz_residual_max && ...
    q.sep > 100*K*eps;
end

function cls = LOCAL_classify_diag(alpha, beta, tau_proj)
  scale = hypot(abs(alpha),abs(beta));
  cls.indeterminate = scale <= tau_proj;
  scale(cls.indeterminate) = 1;
  an = abs(alpha)./scale;
  bn = abs(beta)./scale;
  cls.infinite = ~cls.indeterminate & bn <= tau_proj & an > tau_proj;
  cls.neutral = ~cls.indeterminate & ~cls.infinite & ...
    abs(an-bn) <= tau_proj;
  cls.stable = ~cls.indeterminate & ~cls.infinite & ~cls.neutral & ...
    an < bn-tau_proj;
  cls.unstable = cls.infinite | (~cls.indeterminate & ~cls.neutral & ...
    an > bn+tau_proj);
  finite_gap = abs(an(~cls.indeterminate)-bn(~cls.indeterminate));
  if isempty(finite_gap)
    cls.unit_gap = 0;
  else
    cls.unit_gap = min(finite_gap);
  end
end

function [sep_u,sep_l] = LOCAL_exact_sep(S,T,K)
  Ss = S(1:K,1:K); Ts = T(1:K,1:K);
  Sc = S(K+1:end,K+1:end); Tc = T(K+1:end,K+1:end);
  I = eye(K);
  Lu = [kron(I,Ss),-kron(Sc.',I);kron(I,Ts),-kron(Tc.',I)];
  Ll = [kron(I,Sc),-kron(Ss.',I);kron(I,Tc),-kron(Ts.',I)];
  su = svd(Lu,'econ');
  sl = svd(Ll,'econ');
  sep_u = min(su);
  sep_l = min(sl);
end

function [Dp,Np,Dm,Nm] = LOCAL_cauchy(level, Gamma)
  K = size(Gamma,1);
  Ap = level.plus.Z(1:K,:); Bp = level.plus.Z(K+1:end,:);
  Am = level.minus.Z(1:K,:); Bm = level.minus.Z(K+1:end,:);
  Dp = Ap+Bp;
  Np = 1i*Gamma*(Ap-Bp);
  Dm = Am+Bm;
  Nm = -1i*Gamma*(Am-Bm);
end

function wall = LOCAL_wall_check(S,Zp,Zm)
  K = size(S.R_L,1);
  I = eye(K);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  Rp = LOCAL_right_solve(Bp,Ap);
  Rm = LOCAL_right_solve(Am,Bm);
  graph_p = LOCAL_rel_change(Bp,Rp*Ap);
  graph_m = LOCAL_rel_change(Am,Rm*Bm);
  Fp = I-Rp*S.R_R;
  xp = Fp \ (Rp*S.T_LR);
  solve_p = LOCAL_rel_change(Fp*xp,Rp*S.T_LR);
  Fm = I-Rm*S.R_L;
  xm = Fm \ (Rm*S.T_RL);
  solve_m = LOCAL_rel_change(Fm*xm,Rm*S.T_RL);
  fixed_p = LOCAL_rel_change(Rp,S.R_L+S.T_RL*xp);
  fixed_m = LOCAL_rel_change(Rm,S.R_R+S.T_LR*xm);
  wall.plus_residual = max([graph_p,solve_p,fixed_p]);
  wall.minus_residual = max([graph_m,solve_m,fixed_m]);

  P = fliplr(I);
  Rp_bad = P*Rp*P;
  Rm_bad = P*Rm*P;
  xp_bad = (I-Rp_bad*S.R_R) \ (Rp_bad*S.T_LR);
  xm_bad = (I-Rm_bad*S.R_L) \ (Rm_bad*S.T_RL);
  bad_p = LOCAL_rel_change(Rp_bad,S.R_L+S.T_RL*xp_bad);
  bad_m = LOCAL_rel_change(Rm_bad,S.R_R+S.T_LR*xm_bad);
  wall.mode_order_flip = min(bad_p,bad_m);
end

function swapped = LOCAL_graph_swap(S,Zp,Zm,threshold)
  K = size(S.R_L,1);
  I = eye(K);
  Ap = Zp(1:K,:); Bp = Zp(K+1:end,:);
  Am = Zm(1:K,:); Bm = Zm(K+1:end,:);
  chart_tol = 100*K*eps;
  swapped.plus_available = rcond(Am) > chart_tol;
  swapped.plus_residual = NaN;
  if swapped.plus_available
    Rwrong = LOCAL_right_solve(Bm,Am);
    F = I-Rwrong*S.R_R;
    swapped.plus_available = rcond(F) > chart_tol;
    if swapped.plus_available
      x = F \ (Rwrong*S.T_LR);
      swapped.plus_residual = LOCAL_rel_change( ...
        Rwrong,S.R_L+S.T_RL*x);
    end
  end
  swapped.minus_available = rcond(Bp) > chart_tol;
  swapped.minus_residual = NaN;
  if swapped.minus_available
    Rwrong = LOCAL_right_solve(Ap,Bp);
    F = I-Rwrong*S.R_L;
    swapped.minus_available = rcond(F) > chart_tol;
    if swapped.minus_available
      x = F \ (Rwrong*S.T_RL);
      swapped.minus_residual = LOCAL_rel_change( ...
        Rwrong,S.R_R+S.T_LR*x);
    end
  end
  plus_detected = ~swapped.plus_available || ...
    swapped.plus_residual > threshold;
  minus_detected = ~swapped.minus_available || ...
    swapped.minus_residual > threshold;
  if ~swapped.plus_available
    swapped.plus_status = 'CHART_UNAVAILABLE_DETECTED';
  elseif plus_detected
    swapped.plus_status = 'MISMATCH_DETECTED';
  else
    swapped.plus_status = 'MISMATCH_UNDETECTED';
  end
  if ~swapped.minus_available
    swapped.minus_status = 'CHART_UNAVAILABLE_DETECTED';
  elseif minus_detected
    swapped.minus_status = 'MISMATCH_DETECTED';
  else
    swapped.minus_status = 'MISMATCH_UNDETECTED';
  end
  swapped.detected = plus_detected && minus_detected;
  swapped.pass = swapped.detected;
end

function Lambda = LOCAL_right_solve(N,D)
  Lambda = (D.' \ N.').';
end

function value = LOCAL_pair_change(low,high)
  numerator = hypot(norm(high.A_sc-low.A_sc,'fro'), ...
    norm(high.B_sc-low.B_sc,'fro'));
  denominator = hypot(norm(high.A_sc,'fro'),norm(high.B_sc,'fro'));
  value = numerator/denominator;
end

function value = LOCAL_projector_change(Z1,Z2)
  value = norm(Z1*Z1'-Z2*Z2','fro')/max(1,norm(Z2*Z2','fro'));
end

function gates = LOCAL_stop_rows(gates,names,cause)
  for j = 1:numel(names)
    gates(end+1,:) = LOCAL_gate('real',names{j},'NOT_RUN_PREREQ', ...
      false,NaN,NaN,['first failure: ',cause]);
  end
end

function status = LOCAL_pass_text(pass)
  if pass
    status = 'PASS';
  else
    status = 'FAIL';
  end
end

function [ok, note, provenance] = LOCAL_preflight(input_path, cfg, here, repo_root)
  provenance = struct('input_path', input_path, 'input_exists', false, ...
    'runtime_kind', LOCAL_runtime_name(), 'solver_name', '', ...
    'lsqminnorm_path', '', 'validation', 'NOT_RUN');
  provenance.input_exists = exist(input_path, 'file') == 2;
  if ~provenance.input_exists
    ok = false;
    note = 'input/cell.mat absent; MATLAB lsqminnorm provenance required';
    return;
  end
  data = load(input_path);
  if ~isfield(data, 'provenance') || ~isstruct(data.provenance) || ...
      ~isfield(data, 'cell_data') || ~isstruct(data.cell_data)
    ok = false;
    note = 'input/cell.mat requires cell_data and provenance structs';
    return;
  end
  p = data.provenance;
  required = {'runtime_kind', 'matlab_version', 'solver_name', ...
    'lsqminnorm_path', 'git_sha', 'source_paths', 'source_hashes', ...
    'pinv_calls', 'fallbacks', 'silent_rank_truncations', 'generated_utc'};
  if ~all(isfield(p, required))
    ok = false;
    note = 'provenance is missing one or more required audit fields';
    return;
  end
  provenance = p;
  provenance.input_path = input_path;
  provenance.input_exists = true;
  provenance.validation = 'FAIL';
  zero_audit = isequal(p.pinv_calls, 0) && isequal(p.fallbacks, 0) && ...
    isequal(p.silent_rank_truncations, 0);
  source_names = {'make_cell', 'precomp_proxy', 'construct_S', 'construct_A_QP'};
  source_ok = isstruct(p.source_paths) && isstruct(p.source_hashes) && ...
    all(isfield(p.source_paths, source_names)) && ...
    all(isfield(p.source_hashes, source_names));
  if source_ok
    expected_paths = struct('make_cell', fullfile(here, 'make_cell.m'), ...
      'precomp_proxy', which('kernel.precomp_proxy'), ...
      'construct_S', which('bloch.construct_S'), ...
      'construct_A_QP', which('op.construct_A_QP'));
    for j = 1:numel(source_names)
      hash_value = p.source_hashes.(source_names{j});
      source_ok = source_ok && ischar(hash_value) && ...
        ~isempty(regexp(hash_value, '^[0-9a-f]{64}$', 'once')) && ...
        strcmp(p.source_paths.(source_names{j}), expected_paths.(source_names{j})) && ...
        strcmp(hash_value, LOCAL_source_hash(expected_paths.(source_names{j})));
    end
  end
  provenance_ok = strcmp(p.runtime_kind, 'MATLAB') && ...
    strcmp(p.solver_name, 'lsqminnorm') && ~isempty(p.lsqminnorm_path) && ...
    ~isempty(p.matlab_version) && ~isempty(p.generated_utc) && zero_audit && ...
    source_ok && strcmp(p.git_sha, LOCAL_git_sha(repo_root));
  if ~provenance_ok
    ok = false;
    note = 'MATLAB solver, Git, source-hash, or zero-fallback provenance mismatch';
    return;
  end
  cell_data = data.cell_data;
  cell_required = {'schema', 'physical', 'available_M', 'master_M', 'level_kind', ...
    'wall_labels', 'low', 'high', 'provenance'};
  if ~all(isfield(cell_data, cell_required)) || ...
      ~strcmp(cell_data.schema, cfg.real.schema)
    ok = false;
    note = 'cell_data schema or required fields are invalid';
    return;
  end
  physical = cell_data.physical;
  physical_required = {'k','beta','d','R','X_L','X_R','s','M_master', ...
    'available_M','proxy_dist','proxy_H','refractive_index'};
  if ~all(isfield(physical, physical_required))
    ok = false;
    note = 'physical snapshot is incomplete';
    return;
  end
  physical_error = max(abs([physical.k-cfg.real.k, ...
    physical.beta-cfg.real.beta, physical.d-cfg.real.d, physical.R-cfg.real.R, ...
    physical.X_L-cfg.real.X_L, physical.X_R-cfg.real.X_R, ...
    physical.s-cfg.real.s, physical.refractive_index-sqrt(1+16*cfg.real.s), ...
    physical.proxy_dist-cfg.real.proxy_dist, physical.proxy_H-cfg.real.proxy_H]));
  order_ok = isequal(cell_data.available_M(:).', cfg.real.available_M) && ...
    cell_data.master_M == cfg.real.M_master && ...
    strcmp(cell_data.level_kind, cfg.real.level_kind) && ...
    isequal(cell_data.wall_labels, cfg.real.wall_labels) && ...
    isequaln(cell_data.provenance, p);
  [low_ok, low_note] = LOCAL_validate_level(cell_data.low, cfg.real.low, cfg);
  [high_ok, high_note] = LOCAL_validate_level(cell_data.high, cfg.real.high, cfg);
  ok = physical_error <= cfg.tol_alg && order_ok && low_ok && high_ok;
  if ok
    provenance.validation = 'PASS';
    note = 'strict two-level MATLAB cell provenance and schema validated';
  elseif ~low_ok
    note = ['low level invalid: ', low_note];
  elseif ~high_ok
    note = ['high level invalid: ', high_note];
  else
    note = 'physical parameters, M=5/8 availability, or wall labels mismatch';
  end
end

function [ok, note] = LOCAL_validate_level(level, spec, cfg)
  required = {'ntot','proxy','blocks','modes','wall_labels', ...
    'bie_residual','bie_relative_residual'};
  if ~isstruct(level) || ~all(isfield(level, required))
    ok = false; note = 'missing level fields'; return;
  end
  proxy_fields = {'H','proxy_dist','N_side','N_top','N_proxy_edge','M_pw'};
  block_fields = {'R_L','T_RL','T_LR','R_R','S','A_sc','B_sc'};
  mode_fields = {'M','K','m','beta_m','gamma_m','phase'};
  if ~all(isfield(level.proxy, proxy_fields)) || ...
      ~all(isfield(level.blocks, block_fields)) || ...
      ~all(isfield(level.modes, mode_fields))
    ok = false; note = 'proxy, block, or mode schema incomplete'; return;
  end
  K = 2*cfg.real.M_master + 1;
  dims_ok = true;
  for j = 1:4
    dims_ok = dims_ok && isequal(size(level.blocks.(block_fields{j})), [K,K]);
  end
  dims_ok = dims_ok && isequal(size(level.blocks.S), [2*K,2*K]) && ...
    isequal(size(level.blocks.A_sc), [2*K,2*K]) && ...
    isequal(size(level.blocks.B_sc), [2*K,2*K]);
  A_expected = [-level.blocks.R_L, eye(K); level.blocks.T_LR, zeros(K)];
  B_expected = [zeros(K), level.blocks.T_RL; eye(K), -level.blocks.R_R];
  pencil_error = norm([level.blocks.A_sc-A_expected, ...
    level.blocks.B_sc-B_expected], 'fro');
  proxy_ok = level.ntot == spec.ntot && level.proxy.N_side == spec.N_side && ...
    level.proxy.N_top == spec.N_top && ...
    level.proxy.N_proxy_edge == spec.N_proxy_edge && ...
    level.proxy.M_pw == spec.M_pw && ...
    abs(level.proxy.proxy_dist-cfg.real.proxy_dist) <= cfg.tol_alg && ...
    abs(level.proxy.H-cfg.real.proxy_H) <= cfg.tol_alg;
  modes_ok = level.modes.M == cfg.real.M_master && level.modes.K == K && ...
    isequal(level.modes.m(:), (-cfg.real.M_master:cfg.real.M_master).') && ...
    norm(level.modes.beta_m(:) - ...
    (cfg.real.beta + 2*pi*level.modes.m(:)/cfg.real.d), inf) <= cfg.tol_alg;
  gamma_expected = sqrt(cfg.real.k^2-level.modes.beta_m(:).^2);
  gamma_expected(imag(gamma_expected) < 0) = ...
    -gamma_expected(imag(gamma_expected) < 0);
  phase_expected = exp(1i*gamma_expected*(cfg.real.X_R-cfg.real.X_L));
  modes_ok = modes_ok && ...
    norm(level.modes.gamma_m(:)-gamma_expected, inf) <= cfg.tol_alg && ...
    norm(level.modes.phase(:)-phase_expected, inf) <= cfg.tol_alg;
  residual_ok = isfinite(level.bie_relative_residual) && ...
    level.bie_relative_residual <= cfg.real.solve_residual_max;
  ok = dims_ok && proxy_ok && modes_ok && residual_ok && ...
    pencil_error <= cfg.tol_alg && isequal(level.wall_labels, cfg.real.wall_labels);
  if ok
    note = 'PASS';
  else
    note = 'dimension/proxy/mode/order/wall/residual/pencil mismatch';
  end
end

function name = LOCAL_runtime_name()
  if exist('OCTAVE_VERSION', 'builtin') ~= 0
    name = 'Octave';
  else
    name = 'MATLAB';
  end
end

function sha = LOCAL_git_sha(repo_root)
  [status, output] = system(sprintf('git -C "%s" rev-parse HEAD', repo_root));
  if status == 0
    sha = strtrim(output);
  else
    sha = 'UNAVAILABLE';
  end
end

function value = LOCAL_source_hash(path)
  fid = fopen(path, 'r');
  if fid < 0
    value = 'UNAVAILABLE';
    return;
  end
  cleanup = onCleanup(@() fclose(fid));
  bytes = fread(fid, Inf, '*uint8');
  digest = javaMethod('getInstance', ...
    'java.security.MessageDigest', 'SHA-256');
  digest.update(typecast(bytes(:), 'int8'));
  raw = typecast(digest.digest(), 'uint8');
  value = lower(reshape(dec2hex(raw, 2).', 1, []));
  clear cleanup;
end

%% ==================== Artifact helpers ====================
% These helpers write compact text artifacts without toolbox dependencies.

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_hg_adef:artifact', 'Cannot open %s', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  LOCAL_csv_row(fid, headers);
  if ~iscell(rows)
    rows = {rows};
  end
  if isvector(rows) && numel(rows) == numel(headers)
    rows = reshape(rows, 1, []);
  end
  for j = 1:size(rows, 1)
    LOCAL_csv_row(fid, rows(j, :));
  end
  clear cleanup;
end

function LOCAL_csv_row(fid, row)
  fields = cell(1, numel(row));
  for j = 1:numel(row)
    value = row{j};
    if islogical(value)
      text = sprintf('%d', value);
    elseif isnumeric(value)
      text = sprintf('%.17g', value);
    else
      text = char(value);
    end
    text = strrep(text, '"', '""');
    fields{j} = ['"', text, '"'];
  end
  fprintf(fid, '%s\n', strjoin(fields, ','));
end

function LOCAL_write_report(path, r)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# Half-guide to A-def pilot report\n\n');
  fprintf(fid, '- Status: `%s`\n', r.status);
  fprintf(fid, '- Manufactured K: `%d`\n', r.K);
  fprintf(fid, '- Real K: `11 (M=5), 17 (M=8)`\n');
  fprintf(fid, '- Algebra tolerance: `%.17g`\n', r.tol_alg);
  fprintf(fid, '- Mutation threshold: `%.17g`\n', r.tol_mutation);
  fprintf(fid, '- `derivative_available`: `%s`\n', ...
    LOCAL_bool_text(r.derivative_available));
  fprintf(fid, '- Runtime: `%s %s`\n', r.environment.runtime, r.environment.version);
  fprintf(fid, '- Git SHA: `%s`\n', r.environment.git_sha);
  fprintf(fid, '- Real scope: `%s`\n', r.real.scope);
  if ~isempty(r.real.first_failure)
    fprintf(fid, '- First real failure: `%s`\n', r.real.first_failure);
  end
  fprintf(fid, '- Config snapshot: `K=%d, W=%.17g, graph_error=%.17g, unsafe_D=%.17g`\n\n', ...
    r.config_snapshot.K, r.config_snapshot.W, r.config_snapshot.graph_error, ...
    r.config_snapshot.unsafe_D_scale);
  fprintf(fid, '| Category | Gate | Status | Pass |\n');
  fprintf(fid, '|---|---|---|---:|\n');
  for j = 1:size(r.gates, 1)
    fprintf(fid, '| %s | %s | %s | %d |\n', r.gates{j,1}, ...
      r.gates{j,2}, r.gates{j,3}, r.gates{j,4});
  end
  fprintf(fid, '\nPreflight status is `%s`; later real gates retain their recorded statuses above.\n\n', ...
    r.preflight_status);
  fprintf(fid, 'This pilot contains no locator, root claim, or estimator.\n');
  fprintf(fid, 'The input provenance is generator self-attestation checked by source hashes; it is not an independent solver audit.\n');
  fprintf(fid, 'M=5/8 is a low-order mechanism test and does not authorize production M_trace=48.\n');
  clear cleanup;
end

function LOCAL_write_log(path, r, input_path)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, 'status=%s\n', r.status);
  fprintf(fid, 'K=%d\n', r.K);
  fprintf(fid, 'tol_alg=%.17g\n', r.tol_alg);
  fprintf(fid, 'tol_mutation=%.17g\n', r.tol_mutation);
  fprintf(fid, 'derivative_available=false\n');
  fprintf(fid, 'runtime=%s\n', r.environment.runtime);
  fprintf(fid, 'version=%s\n', r.environment.version);
  fprintf(fid, 'git_sha=%s\n', r.environment.git_sha);
  fprintf(fid, 'config_K=%d\n', r.config_snapshot.K);
  fprintf(fid, 'config_W=%.17g\n', r.config_snapshot.W);
  fprintf(fid, 'config_graph_error=%.17g\n', r.config_snapshot.graph_error);
  fprintf(fid, 'config_unsafe_D=%.17g\n', r.config_snapshot.unsafe_D_scale);
  fprintf(fid, 'cell_input=%s\n', input_path);
  fprintf(fid, 'cell_preflight=%s\n', r.preflight_status);
  for j = 1:size(r.gates, 1)
    fprintf(fid, 'gate.%s=%s\n', r.gates{j,2}, r.gates{j,3});
  end
  clear cleanup;
end

function LOCAL_write_estimate(path, r)
  fid = fopen(path, 'w');
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# Execution timing\n\n');
  fprintf(fid, 'Observed %s run time: `%.6g` seconds.\n\n', ...
    r.environment.runtime, ...
    r.elapsed_seconds);
  fprintf(fid, 'This run includes the manufactured oracle, provenance preflight, and the M=5/8 real QZ/chart/A-def chain.\n\n');
  fprintf(fid, 'This is a timing record, not a spectral estimator. No locator or root computation is implemented.\n');
  clear cleanup;
end

function text = LOCAL_bool_text(value)
  if value
    text = 'true';
  else
    text = 'false';
  end
end
