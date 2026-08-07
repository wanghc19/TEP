function results = run_manufactured_nep()
%RUN_MANUFACTURED_NEP Validate the manufactured eig-apost NEP pipeline.
% Purpose:
%   Exercise contour isolation, bordered Newton, simple-root qualification,
%   projected corrections, effectivity, and prescribed failure gates.
% Input:
%   None. The pre-registered configuration is defined locally.
% Output:
%   results - Structure containing configuration, raw root diagnostics,
%             estimator rows, negative cases, and the final pass flag.
% Main algorithm:
%   Solve five levels of a fixed 2-by-2 analytic nonlinear eigenvalue
%   problem, validate four adjacent-level estimators, then run four negative
%   cases through the same numerical gates.
% Notes:
%   This is a manufactured finite-dimensional experiment. It does not
%   implement or validate the physical BIE/DtN formulation.

  experiment_dir = fileparts(mfilename('fullpath'));
  project_root = fileparts(fileparts(experiment_dir));
  output_dir = fullfile(experiment_dir, 'output');
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end

  cfg = LOCAL_default_config(project_root, experiment_dir, output_dir);
  log_lines = {
    'stage 1: configuration loaded'
    'stage 2: positive root hierarchy started'
  };

  % --- stage 1: compute and qualify all root levels ---
  roots = repmat(LOCAL_empty_root_result(), 1, numel(cfg.root_levels));
  for idx = 1:numel(cfg.root_levels)
    roots(idx) = LOCAL_run_root_level(cfg, cfg.root_levels(idx));
  end
  log_lines{end + 1} = 'stage 2: positive root hierarchy completed';

  % --- stage 2: compute adjacent-level estimators ---
  estimators = repmat(LOCAL_empty_estimator_result(), 1, ...
    numel(cfg.estimator_levels));
  for idx = 1:numel(cfg.estimator_levels)
    estimators(idx) = LOCAL_run_estimator(cfg, roots(idx), roots(idx + 1));
  end
  consistency = [estimators.linearization_consistency];
  effectivity = [estimators.tail_effectivity];
  consistency_trend_pass = all(diff(consistency) < 0) && ...
    consistency(end) <= cfg.consistency_last_tol;
  effectivity_trend_pass = all(diff(abs(effectivity - 1)) < 0) && ...
    abs(effectivity(end) - 1) <= cfg.effectivity_last_tol;
  for idx = 1:numel(estimators)
    estimators(idx).consistency_trend_pass = consistency_trend_pass;
    estimators(idx).effectivity_trend_pass = effectivity_trend_pass;
    estimators(idx).gate_pass = estimators(idx).gate_pass && ...
      consistency_trend_pass && effectivity_trend_pass;
    if ~estimators(idx).gate_pass && isempty(estimators(idx).failure_reason)
      estimators(idx).failure_reason = 'ESTIMATOR_TREND_FAILURE';
    end
  end
  log_lines{end + 1} = 'stage 3: estimator hierarchy completed';

  % --- stage 3: run prescribed negative cases ---
  negative_cases = LOCAL_run_negative_cases(cfg, roots, estimators);
  log_lines{end + 1} = 'stage 4: negative cases completed';

  root_pass = all([roots.gate_pass]);
  estimator_pass = all([estimators.gate_pass]);
  negative_pass = all([negative_cases.pass]);
  results = struct();
  results.config = cfg;
  results.roots = roots;
  results.estimators = estimators;
  results.negative_cases = negative_cases;
  results.consistency_trend_pass = consistency_trend_pass;
  results.effectivity_trend_pass = effectivity_trend_pass;
  results.all_pass = root_pass && estimator_pass && negative_pass;

  % --- stage 4: write deterministic experiment artifacts ---
  if results.all_pass
    log_lines{end + 1} = 'internal exit status: 0';
    log_lines{end + 1} = 'exceptions: none';
    log_lines{end + 1} = 'final status: ALL TESTS PASS';
  else
    log_lines{end + 1} = 'internal exit status: 1';
    log_lines{end + 1} = 'exceptions: none';
    log_lines{end + 1} = 'final status: TESTS FAILED';
  end
  LOCAL_write_config(results, fullfile(output_dir, 'config.txt'));
  LOCAL_write_levels_csv(results, fullfile(output_dir, 'levels.csv'));
  LOCAL_write_contours_csv(results, fullfile(output_dir, 'contours.csv'));
  LOCAL_write_checks_csv(results, fullfile(output_dir, 'checks.csv'));
  LOCAL_write_negative_csv(results, fullfile(output_dir, 'negative-cases.csv'));
  LOCAL_write_effectivity_svg(results, fullfile(output_dir, 'effectivity.svg'));
  LOCAL_write_report(results, fullfile(output_dir, 'report.md'));
  LOCAL_write_lines(log_lines, fullfile(output_dir, 'run.log'));
  LOCAL_save_results(results, fullfile(output_dir, 'results.mat'));

  LOCAL_print_summary(results);
end

%% ==================== Configuration and matrix model ====================
% These helpers define the frozen experiment and analytic manufactured NEP.

function cfg = LOCAL_default_config(project_root, experiment_dir, output_dir)
  cfg = struct();
  cfg.version_label = 'eig-apost-manufactured-v1.2';
  cfg.representation_id = 'manufactured-nep-v1';
  cfg.estimator_label = 'conditional/empirical';
  cfg.project_root = project_root;
  cfg.experiment_dir = experiment_dir;
  cfg.output_dir = output_dir;
  cfg.k_star = 2.3;
  cfg.alpha = complex(4, 3);
  cfg.curvature_c = 0.2;
  cfg.second_diag_slope_q = 0.1;
  cfg.theta = 0.25;
  cfg.root_levels = 0:4;
  cfg.estimator_levels = 0:3;
  cfg.scan_interval = [1.8, 2.5];
  cfg.scan_count = 401;
  cfg.contour_center = cfg.k_star;
  cfg.contour_radii = [0.4, 0.32];
  cfg.contour_nodes = [128, 256];
  cfg.newton_tol = 1e-12;
  cfg.newton_maxit = 20;
  cfg.complex_seed_offset = complex(0, 0.05);
  cfg.derivative_steps = [1e-3, 5e-4, 2.5e-4];
  cfg.count_tol = 1e-8;
  cfg.contour_separation_tol = 1e-4;
  cfg.root_repeat_tol = 1e-10;
  cfg.root_oracle_tol = 1e-10;
  cfg.root_residual_tol = 1e-11;
  cfg.singular_gap_tol = 1e-3;
  cfg.root_slope_tol = 1e-2;
  cfg.border_rcond_tol = 1e-12;
  cfg.derivative_spread_tol = 1e-7;
  cfg.derivative_exact_tol = 1e-8;
  cfg.direction_angle_tol = 1e-8;
  cfg.root_to_map_ratio = 0.05;
  cfg.correction_oracle_tol = 1e-10;
  cfg.consistency_last_tol = 1e-4;
  cfg.effectivity_last_tol = 1e-3;
  cfg.level_scale = ones(size(cfg.root_levels));
  cfg.row_scale_fingerprint = [1, 1];
  cfg.column_scale_fingerprint = [1, 1];
  cfg.total_effectivity_collapses_to_tail = true;
  cfg.git_base = LOCAL_git_base(project_root);
  cfg.hash_records = LOCAL_hash_records(project_root, experiment_dir);
end

function epsilon_j = LOCAL_epsilon(cfg, level_j)
  if isinf(level_j)
    epsilon_j = 0;
  else
    epsilon_j = cfg.theta^(2^level_j);
  end
end

function [F_level, dFdk] = LOCAL_eval_nep(cfg, level_j, k)
  epsilon_j = LOCAL_epsilon(cfg, level_j);
  s = k - cfg.k_star;
  F_level = [s + cfg.curvature_c * s^2 + epsilon_j, cfg.alpha; ...
             0, 1 + cfg.second_diag_slope_q * s];
  dFdk = [1 + 2 * cfg.curvature_c * s, 0; ...
          0, cfg.second_diag_slope_q];
end

function k_exact = LOCAL_exact_root(cfg, level_j)
  epsilon_j = LOCAL_epsilon(cfg, level_j);
  branch_value = sqrt(1 - 4 * cfg.curvature_c * epsilon_j);
  s_exact = (-1 + branch_value) / (2 * cfg.curvature_c);
  k_exact = cfg.k_star + s_exact;
end

function [x_exact, y_exact] = LOCAL_exact_directions(cfg, level_j)
  k_exact = LOCAL_exact_root(cfg, level_j);
  s_exact = k_exact - cfg.k_star;
  second_factor = 1 + cfg.second_diag_slope_q * s_exact;
  x_exact = [1; 0];
  y_exact = [conj(second_factor); -conj(cfg.alpha)];
  y_exact = y_exact / norm(y_exact, 2);
end

function pass = LOCAL_representation_gate(representation_ids, level_scales, ...
    row_fingerprints, column_fingerprints)
  pass = all(strcmp(representation_ids, representation_ids{1})) && ...
    all(abs(level_scales - 1) <= eps) && ...
    all(all(abs(row_fingerprints - row_fingerprints(1, :)) <= eps)) && ...
    all(all(abs(column_fingerprints - column_fingerprints(1, :)) <= eps));
end

%% ==================== Root search and qualification ====================
% These helpers isolate roots, run bordered Newton, and apply simple-root gates.

function result = LOCAL_run_root_level(cfg, level_j)
  result = LOCAL_empty_root_result();
  result.level_j = level_j;
  result.n_cells = 2^level_j;
  result.epsilon_j = LOCAL_epsilon(cfg, level_j);
  result.k_exact_j = LOCAL_exact_root(cfg, level_j);
  result.representation_id = cfg.representation_id;
  result.level_scale = 1;

  [result.scan_candidate, result.scan_sigma_min] = ...
    LOCAL_real_scan(cfg, level_j);

  contour_records = repmat(struct('radius', 0, 'nodes', 0, 'count', 0, ...
    'moment', 0, 'min_relative_sigma', 0), 1, ...
    numel(cfg.contour_radii) * numel(cfg.contour_nodes));
  record_idx = 0;
  for radius = cfg.contour_radii
    for nodes = cfg.contour_nodes
      record_idx = record_idx + 1;
      [root_count, root_moment, min_relative_sigma] = ...
        LOCAL_contour_moments(cfg, level_j, cfg.contour_center, radius, nodes);
      contour_records(record_idx).radius = radius;
      contour_records(record_idx).nodes = nodes;
      contour_records(record_idx).count = root_count;
      contour_records(record_idx).moment = root_moment;
      contour_records(record_idx).min_relative_sigma = min_relative_sigma;
    end
  end
  result.contour_records = contour_records;
  counts = [contour_records.count];
  separations = [contour_records.min_relative_sigma];
  [result.contour_pass, count_integer_pass, count_stability_pass, ...
    separation_pass] = LOCAL_contour_count_gate(cfg, counts, separations, 1);
  result.contour_count = contour_records(2).count;
  result.contour_min_relative_sigma = min(separations);
  if ~result.contour_pass
    result.failure_reason = 'CONTOUR_COUNT_NOT_ONE';
    if count_integer_pass && count_stability_pass && ~separation_pass
      result.failure_reason = 'CONTOUR_NOT_SEPARATED';
    end
    return;
  end

  moment_seed = contour_records(2).moment / contour_records(2).count;
  [F_scan, ~] = LOCAL_eval_nep(cfg, level_j, result.scan_candidate);
  [U_scan, ~, V_scan] = svd(F_scan);
  border_column = U_scan(:, end);
  border_row = V_scan(:, end);
  seeds = [result.scan_candidate, moment_seed, ...
    result.scan_candidate + cfg.complex_seed_offset];
  root_values = zeros(size(seeds));
  converged = false(size(seeds));
  iterations = zeros(size(seeds));
  border_rconds = zeros(size(seeds));
  exit_reasons = cell(size(seeds));
  for idx = 1:numel(seeds)
    [root_values(idx), converged(idx), iterations(idx), ...
      border_rconds(idx), exit_reasons{idx}] = LOCAL_bordered_newton( ...
      cfg, level_j, seeds(idx), border_column, border_row, 1);
  end
  result.newton_roots = root_values;
  result.newton_iterations = max(iterations);
  result.newton_exit_reasons = exit_reasons;
  result.border_rcond = min(border_rconds);
  root_spread = max(abs(root_values - root_values(1)));
  repeat_pass = all(converged) && root_spread <= cfg.root_repeat_tol;
  if ~repeat_pass
    result.failure_reason = 'ROOT_NOT_REPEATABLE';
    return;
  end

  result.k_root = root_values(1);
  [F_root, dFdk] = LOCAL_eval_nep(cfg, level_j, result.k_root);
  [U_root, S_root, V_root] = svd(F_root);
  singular_values = diag(S_root);
  result.x_right = V_root(:, end);
  result.y_left = U_root(:, end);
  result.singular_values = singular_values;
  matrix_scale = max(1, norm(F_root, 2));
  result.relative_root_residual = singular_values(end) / matrix_scale;
  result.right_residual = norm(F_root * result.x_right, 2) / matrix_scale;
  result.left_residual = norm(result.y_left' * F_root, 2) / matrix_scale;
  result.singular_gap = singular_values(end - 1) / matrix_scale;
  result.root_slope = result.y_left' * dFdk * result.x_right;
  result.root_error = abs(result.k_root - result.k_exact_j);
  [x_exact, y_exact] = LOCAL_exact_directions(cfg, level_j);
  result.right_angle_error = LOCAL_direction_error(x_exact, result.x_right);
  result.left_angle_error = LOCAL_direction_error(y_exact, result.y_left);
  [result.derivative_spread, result.derivative_exact_error] = ...
    LOCAL_derivative_check(cfg, level_j, result.k_root, ...
    result.x_right, result.y_left, dFdk);

  residual_pass = result.relative_root_residual <= cfg.root_residual_tol && ...
    result.right_residual <= cfg.root_residual_tol && ...
    result.left_residual <= cfg.root_residual_tol;
  gap_pass = result.singular_gap >= cfg.singular_gap_tol;
  slope_pass = abs(result.root_slope) >= cfg.root_slope_tol;
  border_pass = result.border_rcond >= cfg.border_rcond_tol;
  derivative_pass = result.derivative_spread <= cfg.derivative_spread_tol && ...
    result.derivative_exact_error <= cfg.derivative_exact_tol;
  angle_pass = result.right_angle_error <= cfg.direction_angle_tol && ...
    result.left_angle_error <= cfg.direction_angle_tol;
  oracle_pass = result.root_error <= cfg.root_oracle_tol;
  result.gate_pass = residual_pass && gap_pass && slope_pass && border_pass && ...
    derivative_pass && angle_pass && oracle_pass;
  result.available = result.gate_pass;
  if ~result.gate_pass
    if ~residual_pass || ~oracle_pass || ~angle_pass
      result.failure_reason = 'ROOT_RESIDUAL';
    elseif ~gap_pass
      result.failure_reason = 'MULTIPLE_OR_DEFECTIVE_ROOT';
    elseif ~slope_pass
      result.failure_reason = 'SMALL_TRANSVERSE_SLOPE';
    elseif ~border_pass
      result.failure_reason = 'BORDER_ILL_CONDITIONED';
    else
      result.failure_reason = 'DERIVATIVE_UNSTABLE';
    end
  else
    result.failure_reason = 'PASS';
  end
end

function [candidate, sigma_minimum] = LOCAL_real_scan(cfg, level_j)
  scan_k = linspace(cfg.scan_interval(1), cfg.scan_interval(2), cfg.scan_count);
  sigma_values = zeros(size(scan_k));
  for idx = 1:numel(scan_k)
    [F_level, ~] = LOCAL_eval_nep(cfg, level_j, scan_k(idx));
    current_singular_values = svd(F_level);
    sigma_values(idx) = current_singular_values(end);
  end
  [sigma_minimum, minimum_idx] = min(sigma_values);
  candidate = scan_k(minimum_idx);
end

function [root_count, root_moment, min_relative_sigma] = ...
    LOCAL_contour_moments(cfg, level_j, center, radius, node_count)
  root_count = 0;
  root_moment = 0;
  min_relative_sigma = Inf;
  for idx = 0:(node_count - 1)
    angle = 2 * pi * idx / node_count;
    radial_factor = exp(complex(0, angle));
    k = center + radius * radial_factor;
    [F_level, dFdk] = LOCAL_eval_nep(cfg, level_j, k);
    trace_value = trace(F_level \ dFdk);
    quadrature_weight = radius * radial_factor / node_count;
    root_count = root_count + trace_value * quadrature_weight;
    root_moment = root_moment + k * trace_value * quadrature_weight;
    singular_values = svd(F_level);
    relative_sigma = singular_values(end) / max(1, norm(F_level, 2));
    min_relative_sigma = min(min_relative_sigma, relative_sigma);
  end
end

function [pass, integer_pass, stability_pass, separation_pass] = ...
    LOCAL_contour_count_gate(cfg, counts, separations, expected_count)
  integer_pass = all(abs(real(counts) - expected_count) <= cfg.count_tol) && ...
    all(abs(imag(counts)) <= cfg.count_tol);
  stability_pass = max(abs(counts - counts(1))) <= cfg.count_tol;
  if isempty(separations)
    separation_pass = true;
  else
    separation_pass = min(separations) >= cfg.contour_separation_tol;
  end
  pass = integer_pass && stability_pass && separation_pass;
end

function [k, converged, iterations, min_border_rcond, exit_reason] = ...
    LOCAL_bordered_newton(cfg, level_j, initial_k, border_column, border_row, ...
    matrix_scale)
  k = initial_k;
  converged = false;
  iterations = 0;
  min_border_rcond = Inf;
  exit_reason = 'MAX_ITERATIONS';
  for iteration = 1:cfg.newton_maxit
    [F_level, dFdk] = LOCAL_eval_nep(cfg, level_j, k);
    F_level = matrix_scale * F_level;
    dFdk = matrix_scale * dFdk;
    bordered = [F_level, border_column; border_row', 0];
    current_rcond = rcond(bordered);
    min_border_rcond = min(min_border_rcond, current_rcond);
    if current_rcond < cfg.border_rcond_tol
      exit_reason = 'BORDER_ILL_CONDITIONED';
      iterations = iteration;
      return;
    end
    solution = bordered \ [zeros(2, 1); 1];
    x_implicit = solution(1:2);
    implicit_determinant = solution(3);
    derivative_solution = bordered \ [-dFdk * x_implicit; 0];
    implicit_derivative = derivative_solution(3);
    if abs(implicit_derivative) <= eps
      exit_reason = 'ZERO_IMPLICIT_DERIVATIVE';
      iterations = iteration;
      return;
    end
    step = -implicit_determinant / implicit_derivative;
    iterations = iteration;
    if abs(step) <= cfg.newton_tol * max(1, abs(k)) && ...
        abs(implicit_determinant) <= cfg.newton_tol
      converged = true;
      exit_reason = 'CONVERGED';
      return;
    end
    k = k + step;
  end
end

function [derivative_spread, derivative_exact_error] = ...
    LOCAL_derivative_check(cfg, level_j, k, x_right, y_left, dFdk)
  projected_values = zeros(size(cfg.derivative_steps));
  exact_errors = zeros(size(cfg.derivative_steps));
  for idx = 1:numel(cfg.derivative_steps)
    step = cfg.derivative_steps(idx);
    [F_plus, ~] = LOCAL_eval_nep(cfg, level_j, k + step);
    [F_minus, ~] = LOCAL_eval_nep(cfg, level_j, k - step);
    dFdk_fd = (F_plus - F_minus) / (2 * step);
    projected_values(idx) = y_left' * dFdk_fd * x_right;
    exact_errors(idx) = norm(dFdk_fd - dFdk, 2) / max(1, norm(dFdk, 2));
  end
  projected_reference = y_left' * dFdk * x_right;
  derivative_spread = max(abs(projected_values - projected_reference)) / ...
    max(1, abs(projected_reference));
  derivative_exact_error = max(exact_errors);
end

function error_value = LOCAL_direction_error(reference_vector, computed_vector)
  reference_vector = reference_vector / norm(reference_vector, 2);
  computed_vector = computed_vector / norm(computed_vector, 2);
  orthogonal_component = computed_vector - ...
    reference_vector * (reference_vector' * computed_vector);
  error_value = min(1, norm(orthogonal_component, 2));
end

function result = LOCAL_empty_root_result()
  result = struct('level_j', NaN, 'n_cells', NaN, 'epsilon_j', NaN, ...
    'k_exact_j', complex(NaN, NaN), 'representation_id', '', ...
    'level_scale', NaN, 'scan_candidate', NaN, 'scan_sigma_min', NaN, ...
    'contour_records', struct([]), 'contour_pass', false, ...
    'contour_count', complex(NaN, NaN), ...
    'contour_min_relative_sigma', NaN, 'newton_roots', [], ...
    'newton_iterations', NaN, 'newton_exit_reasons', {{}}, ...
    'border_rcond', NaN, 'k_root', complex(NaN, NaN), ...
    'x_right', complex(NaN(2, 1), NaN(2, 1)), ...
    'y_left', complex(NaN(2, 1), NaN(2, 1)), 'singular_values', NaN(2, 1), ...
    'relative_root_residual', NaN, 'right_residual', NaN, ...
    'left_residual', NaN, 'singular_gap', NaN, ...
    'root_slope', complex(NaN, NaN), 'root_error', NaN, ...
    'right_angle_error', NaN, 'left_angle_error', NaN, ...
    'derivative_spread', NaN, 'derivative_exact_error', NaN, ...
    'available', false, 'gate_pass', false, 'failure_reason', 'UNAVAILABLE');
end

%% ==================== Estimator evaluation ====================
% These helpers form the three corrections and compare them with exact oracles.

function result = LOCAL_run_estimator(cfg, coarse_root, fine_root)
  result = LOCAL_empty_estimator_result();
  result.level_j = coarse_root.level_j;
  result.available = coarse_root.gate_pass && fine_root.gate_pass;
  if ~result.available
    result.failure_reason = 'ROOT_QUALIFICATION_FAILED';
    return;
  end

  level_j = coarse_root.level_j;
  k_root = coarse_root.k_root;
  x_right = coarse_root.x_right;
  y_left = coarse_root.y_left;
  correction = LOCAL_correction_quantities(cfg, level_j, k_root, x_right, y_left);
  result.delta_root = correction.delta_root;
  result.delta_map = correction.delta_map;
  result.delta_total = correction.delta_total;
  result.delta_total_direct = correction.delta_total_direct;
  epsilon_j = coarse_root.epsilon_j;
  epsilon_jp1 = fine_root.epsilon_j;
  result.delta_map_oracle = (epsilon_j - epsilon_jp1) / ...
    sqrt(1 - 4 * cfg.curvature_c * epsilon_j);
  result.delta_map_oracle_error = abs(result.delta_map - result.delta_map_oracle);
  result.delta_total_sum_error = abs(result.delta_total - ...
    (result.delta_root + result.delta_map));
  result.delta_total_direct_error = abs(result.delta_total - ...
    result.delta_total_direct);
  result.eta_map = abs(result.delta_map);
  result.root_increment = fine_root.k_root - coarse_root.k_root;
  result.root_increment_oracle = fine_root.k_exact_j - coarse_root.k_exact_j;
  noise_floor = 100 * eps * max(1, abs(coarse_root.k_root));
  if abs(result.root_increment) < noise_floor
    result.linearization_consistency = NaN;
    result.consistency_status = 'NOISE_FLOOR';
  else
    result.linearization_consistency = abs(result.delta_map - ...
      result.root_increment) / abs(result.root_increment);
    result.consistency_status = 'AVAILABLE';
  end
  tail_error = abs(coarse_root.k_exact_j - cfg.k_star);
  result.tail_effectivity = result.eta_map / tail_error;
  result.root_error_ratio = abs(result.delta_root) / max(result.eta_map, realmin);

  oracle_tol = cfg.correction_oracle_tol * ...
    max(1, abs(result.delta_map_oracle));
  total_sum_tol = cfg.correction_oracle_tol * max(1, abs(result.delta_total));
  total_direct_tol = cfg.correction_oracle_tol * ...
    max(1, abs(result.delta_total_direct));
  root_defect_pass = LOCAL_root_dominance_gate(cfg, correction);
  oracle_pass = result.delta_map_oracle_error <= oracle_tol;
  total_pass = result.delta_total_sum_error <= total_sum_tol && ...
    result.delta_total_direct_error <= total_direct_tol;
  direction_pass = real(conj(result.root_increment) * result.delta_map) > 0;
  representation_pass = LOCAL_representation_gate( ...
    {coarse_root.representation_id, fine_root.representation_id}, ...
    [coarse_root.level_scale, fine_root.level_scale], ...
    repmat(cfg.row_scale_fingerprint, 2, 1), ...
    repmat(cfg.column_scale_fingerprint, 2, 1));
  result.gate_pass = root_defect_pass && oracle_pass && total_pass && ...
    direction_pass && representation_pass && ...
    strcmp(result.consistency_status, 'AVAILABLE');
  if result.gate_pass
    result.failure_reason = 'PASS';
  elseif ~root_defect_pass
    result.failure_reason = 'ROOT_ERROR_DOMINATES';
  elseif ~representation_pass
    result.failure_reason = 'LEVEL_SCALING_REJECTED';
  else
    result.failure_reason = 'CORRECTION_ORACLE_FAILURE';
  end
end

function correction = LOCAL_correction_quantities(cfg, level_j, k, x_right, y_left)
  [F_level, dFdk] = LOCAL_eval_nep(cfg, level_j, k);
  [F_next, ~] = LOCAL_eval_nep(cfg, level_j + 1, k);
  correction = struct();
  correction.root_slope = y_left' * dFdk * x_right;
  correction.delta_root = -(y_left' * F_level * x_right) / ...
    correction.root_slope;
  correction.delta_map = -(y_left' * (F_next - F_level) * x_right) / ...
    correction.root_slope;
  correction.delta_total = correction.delta_root + correction.delta_map;
  correction.delta_total_direct = -(y_left' * F_next * x_right) / ...
    correction.root_slope;
  correction.eta_map = abs(correction.delta_map);
end

function pass = LOCAL_root_dominance_gate(cfg, correction)
  pass = abs(correction.delta_root) <= ...
    cfg.root_to_map_ratio * correction.eta_map;
end

function result = LOCAL_empty_estimator_result()
  result = struct('level_j', NaN, 'available', false, ...
    'delta_root', complex(NaN, NaN), 'delta_map', complex(NaN, NaN), ...
    'delta_total', complex(NaN, NaN), ...
    'delta_total_direct', complex(NaN, NaN), ...
    'delta_map_oracle', complex(NaN, NaN), ...
    'delta_map_oracle_error', NaN, 'delta_total_sum_error', NaN, ...
    'delta_total_direct_error', NaN, 'eta_map', NaN, ...
    'root_increment', complex(NaN, NaN), ...
    'root_increment_oracle', complex(NaN, NaN), ...
    'linearization_consistency', NaN, 'consistency_status', 'UNAVAILABLE', ...
    'tail_effectivity', NaN, 'root_error_ratio', NaN, ...
    'consistency_trend_pass', false, 'effectivity_trend_pass', false, ...
    'gate_pass', false, 'failure_reason', 'UNAVAILABLE');
end

%% ==================== Negative cases ====================
% These helpers inject failures and require the shared gates to reject them.

function negative_cases = LOCAL_run_negative_cases(cfg, roots, estimators)
  negative_cases = repmat(struct('name', '', 'expected_label', '', ...
    'observed_label', '', 'metric_1', NaN, 'metric_2', NaN, ...
    'available', false, 'pass', false), 1, 4);

  k0 = 1.7;
  dip_tau = 0.03;
  scan_k = linspace(1.4, 2.0, 601);
  scan_values = abs(scan_k - k0 + complex(0, dip_tau));
  scan_minimum = min(scan_values);
  small_count = LOCAL_scalar_contour_count(k0, 0.015, 128, k0, dip_tau);
  large_count = LOCAL_scalar_contour_count(k0, 0.06, 128, k0, dip_tau);
  [small_gate, ~, ~, ~] = LOCAL_contour_count_gate(cfg, small_count, [], 0);
  [large_gate, ~, ~, ~] = LOCAL_contour_count_gate(cfg, large_count, [], 1);
  dip_pass = abs(scan_minimum - dip_tau) <= 1e-12 && small_gate && large_gate;
  negative_cases(1).name = 'real-axis dip without a real root';
  negative_cases(1).expected_label = 'REAL_AXIS_DIP_ONLY';
  negative_cases(1).observed_label = LOCAL_label(dip_pass, ...
    'REAL_AXIS_DIP_ONLY', 'UNEXPECTED_DIP_RESULT');
  negative_cases(1).metric_1 = small_count;
  negative_cases(1).metric_2 = large_count;
  negative_cases(1).pass = strcmp(negative_cases(1).observed_label, ...
    negative_cases(1).expected_label);

  level_j = 1;
  coarse = roots(level_j + 1);
  k_exact = coarse.k_exact_j;
  [F_coarse, dFdk_coarse] = LOCAL_eval_nep(cfg, level_j, k_exact);
  [F_fine, ~] = LOCAL_eval_nep(cfg, level_j + 1, k_exact);
  [x_exact, y_exact] = LOCAL_exact_directions(cfg, level_j);
  scale_coarse = 2^level_j;
  scale_fine = 2^(level_j + 1);
  scaled_delta = -(y_exact' * (scale_fine * F_fine - ...
    scale_coarse * F_coarse) * x_exact) / ...
    (y_exact' * (scale_coarse * dFdk_coarse) * x_exact);
  scale_ratio = scaled_delta / estimators(level_j + 1).delta_map_oracle;
  scaling_gate = LOCAL_representation_gate( ...
    {cfg.representation_id, cfg.representation_id}, ...
    [scale_coarse, scale_fine], ...
    repmat(cfg.row_scale_fingerprint, 2, 1), ...
    repmat(cfg.column_scale_fingerprint, 2, 1));
  [F_scaled_scan, ~] = LOCAL_eval_nep(cfg, level_j, coarse.scan_candidate);
  [U_scaled, ~, V_scaled] = svd(scale_coarse * F_scaled_scan);
  [scaled_root, scaled_converged, ~, ~, ~] = LOCAL_bordered_newton( ...
    cfg, level_j, coarse.scan_candidate, U_scaled(:, end), V_scaled(:, end), ...
    scale_coarse);
  scaled_root_error = abs(scaled_root - coarse.k_root);
  scaling_pass = ~scaling_gate && scaled_converged && ...
    scaled_root_error <= cfg.root_repeat_tol && abs(scale_ratio - 2) <= 1e-10;
  negative_cases(2).name = 'level-dependent scaling';
  negative_cases(2).expected_label = 'LEVEL_SCALING_REJECTED';
  negative_cases(2).observed_label = LOCAL_label(scaling_pass, ...
    'LEVEL_SCALING_REJECTED', 'UNEXPECTED_SCALING_RESULT');
  negative_cases(2).metric_1 = scale_ratio;
  negative_cases(2).metric_2 = scaled_root_error;
  negative_cases(2).pass = strcmp(negative_cases(2).observed_label, ...
    negative_cases(2).expected_label);

  [miss_count, ~, ~] = LOCAL_contour_moments(cfg, Inf, ...
    cfg.k_star + 0.6, 0.1, 128);
  [miss_gate, ~, ~, ~] = LOCAL_contour_count_gate(cfg, miss_count, [], 1);
  negative_cases(3).name = 'contour misses target root';
  negative_cases(3).expected_label = 'CONTOUR_COUNT_NOT_ONE';
  negative_cases(3).observed_label = LOCAL_label(~miss_gate, ...
    'CONTOUR_COUNT_NOT_ONE', 'UNEXPECTED_CONTOUR_RESULT');
  negative_cases(3).metric_1 = miss_count;
  negative_cases(3).metric_2 = double(miss_gate);
  negative_cases(3).pass = strcmp(negative_cases(3).observed_label, ...
    negative_cases(3).expected_label);

  pollution_level = 3;
  polluted_k = roots(pollution_level + 1).k_exact_j + 1e-4;
  [F_polluted, ~] = LOCAL_eval_nep(cfg, pollution_level, polluted_k);
  [U_polluted, ~, V_polluted] = svd(F_polluted);
  x_polluted = V_polluted(:, end);
  y_polluted = U_polluted(:, end);
  polluted_correction = LOCAL_correction_quantities(cfg, pollution_level, ...
    polluted_k, x_polluted, y_polluted);
  pollution_ratio = abs(polluted_correction.delta_root) / ...
    max(polluted_correction.eta_map, realmin);
  pollution_pass = ~LOCAL_root_dominance_gate(cfg, polluted_correction);
  negative_cases(4).name = 'deterministic root pollution';
  negative_cases(4).expected_label = 'ROOT_ERROR_DOMINATES';
  negative_cases(4).observed_label = LOCAL_label(pollution_pass, ...
    'ROOT_ERROR_DOMINATES', 'UNEXPECTED_ROOT_POLLUTION_RESULT');
  negative_cases(4).metric_1 = pollution_ratio;
  negative_cases(4).metric_2 = cfg.root_to_map_ratio;
  negative_cases(4).pass = strcmp(negative_cases(4).observed_label, ...
    negative_cases(4).expected_label);
end

function root_count = LOCAL_scalar_contour_count(center, radius, node_count, k0, dip_tau)
  root_count = 0;
  for idx = 0:(node_count - 1)
    angle = 2 * pi * idx / node_count;
    radial_factor = exp(complex(0, angle));
    k = center + radius * radial_factor;
    scalar_value = k - k0 + complex(0, dip_tau);
    quadrature_weight = radius * radial_factor / node_count;
    root_count = root_count + quadrature_weight / scalar_value;
  end
end

function label = LOCAL_label(condition, pass_label, failure_label)
  if condition
    label = pass_label;
  else
    label = failure_label;
  end
end

%% ==================== Artifact generation ====================
% These helpers write deterministic tables, logs, reports, and an SVG image.

function LOCAL_write_config(results, output_path)
  cfg = results.config;
  file_id = LOCAL_open_output(output_path);
  fprintf(file_id, 'version_label=%s\n', cfg.version_label);
  fprintf(file_id, 'representation_id=%s\n', cfg.representation_id);
  fprintf(file_id, 'estimator_label=%s\n', cfg.estimator_label);
  fprintf(file_id, 'git_base=%s\n', cfg.git_base);
  fprintf(file_id, 'k_star=%.17g\n', cfg.k_star);
  fprintf(file_id, 'alpha_real=%.17g\n', real(cfg.alpha));
  fprintf(file_id, 'alpha_imag=%.17g\n', imag(cfg.alpha));
  fprintf(file_id, 'curvature_c=%.17g\n', cfg.curvature_c);
  fprintf(file_id, 'second_diag_slope_q=%.17g\n', cfg.second_diag_slope_q);
  fprintf(file_id, 'theta=%.17g\n', cfg.theta);
  fprintf(file_id, 'root_levels=0:4\n');
  fprintf(file_id, 'estimator_levels=0:3\n');
  fprintf(file_id, 'scan_interval=%.17g,%.17g\n', ...
    cfg.scan_interval(1), cfg.scan_interval(2));
  fprintf(file_id, 'scan_count=%d\n', cfg.scan_count);
  fprintf(file_id, 'contour_center=%.17g\n', cfg.contour_center);
  fprintf(file_id, 'contour_radii=0.4,0.32\n');
  fprintf(file_id, 'contour_nodes=128,256\n');
  fprintf(file_id, 'newton_tol=%.17g\n', cfg.newton_tol);
  fprintf(file_id, 'newton_maxit=%d\n', cfg.newton_maxit);
  fprintf(file_id, 'complex_seed_offset_real=%.17g\n', real(cfg.complex_seed_offset));
  fprintf(file_id, 'complex_seed_offset_imag=%.17g\n', imag(cfg.complex_seed_offset));
  fprintf(file_id, 'derivative_steps=%.17g,%.17g,%.17g\n', ...
    cfg.derivative_steps(1), cfg.derivative_steps(2), cfg.derivative_steps(3));
  fprintf(file_id, 'count_tol=%.17g\n', cfg.count_tol);
  fprintf(file_id, 'contour_separation_tol=%.17g\n', cfg.contour_separation_tol);
  fprintf(file_id, 'root_repeat_tol=%.17g\n', cfg.root_repeat_tol);
  fprintf(file_id, 'root_oracle_tol=%.17g\n', cfg.root_oracle_tol);
  fprintf(file_id, 'root_residual_tol=%.17g\n', cfg.root_residual_tol);
  fprintf(file_id, 'singular_gap_tol=%.17g\n', cfg.singular_gap_tol);
  fprintf(file_id, 'root_slope_tol=%.17g\n', cfg.root_slope_tol);
  fprintf(file_id, 'border_rcond_tol=%.17g\n', cfg.border_rcond_tol);
  fprintf(file_id, 'derivative_spread_tol=%.17g\n', cfg.derivative_spread_tol);
  fprintf(file_id, 'derivative_exact_tol=%.17g\n', cfg.derivative_exact_tol);
  fprintf(file_id, 'direction_angle_tol=%.17g\n', cfg.direction_angle_tol);
  fprintf(file_id, 'root_to_map_ratio=%.17g\n', cfg.root_to_map_ratio);
  fprintf(file_id, 'correction_oracle_tol=%.17g\n', cfg.correction_oracle_tol);
  fprintf(file_id, 'consistency_last_tol=%.17g\n', cfg.consistency_last_tol);
  fprintf(file_id, 'effectivity_last_tol=%.17g\n', cfg.effectivity_last_tol);
  fprintf(file_id, 'total_effectivity_collapses_to_tail=true\n');
  for idx = 1:numel(cfg.hash_records)
    fprintf(file_id, 'sha256[%s]=%s\n', ...
      cfg.hash_records(idx).relative_path, cfg.hash_records(idx).hash);
  end
  fclose(file_id);
end

function LOCAL_write_levels_csv(results, output_path)
  file_id = LOCAL_open_output(output_path);
  header = ['j,epsilon_j,k_exact_real,k_exact_imag,k_root_real,k_root_imag,' ...
    'root_available,contour_count_real,contour_count_imag,' ...
    'contour_min_relative_sigma,newton_iterations,border_rcond,' ...
    'relative_root_residual,left_residual,right_residual,singular_smallest,' ...
    'singular_second,root_slope_real,root_slope_imag,left_angle_error,' ...
    'right_angle_error,estimator_available,delta_root_real,delta_root_imag,' ...
    'delta_map_real,delta_map_imag,delta_map_oracle_real,' ...
    'delta_map_oracle_imag,delta_total_real,delta_total_imag,' ...
    'root_increment_real,root_increment_imag,linearization_consistency,' ...
    'tail_effectivity,gate_pass,status'];
  fprintf(file_id, '%s\n', header);
  for idx = 1:numel(results.roots)
    root = results.roots(idx);
    if idx <= numel(results.estimators)
      estimator = results.estimators(idx);
      estimator_available = estimator.available;
      delta_root = estimator.delta_root;
      delta_map = estimator.delta_map;
      delta_map_oracle = estimator.delta_map_oracle;
      delta_total = estimator.delta_total;
      root_increment = estimator.root_increment;
      linearization_consistency = estimator.linearization_consistency;
      tail_effectivity = estimator.tail_effectivity;
      combined_pass = root.gate_pass && estimator.gate_pass;
      status = estimator.failure_reason;
    else
      estimator_available = false;
      delta_root = complex(NaN, NaN);
      delta_map = complex(NaN, NaN);
      delta_map_oracle = complex(NaN, NaN);
      delta_total = complex(NaN, NaN);
      root_increment = complex(NaN, NaN);
      linearization_consistency = NaN;
      tail_effectivity = NaN;
      combined_pass = root.gate_pass;
      status = 'ROOT_ONLY';
    end
    fprintf(file_id, ['%d,%.17g,%.17g,%.17g,%.17g,%.17g,%d,' ...
      '%.17g,%.17g,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,' ...
      '%.17g,%.17g,%.17g,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.17g,' ...
      '%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%d,%s\n'], ...
      root.level_j, root.epsilon_j, real(root.k_exact_j), imag(root.k_exact_j), ...
      real(root.k_root), imag(root.k_root), root.available, ...
      real(root.contour_count), imag(root.contour_count), ...
      root.contour_min_relative_sigma, root.newton_iterations, root.border_rcond, ...
      root.relative_root_residual, root.left_residual, root.right_residual, ...
      root.singular_values(end), root.singular_values(end - 1), ...
      real(root.root_slope), imag(root.root_slope), root.left_angle_error, ...
      root.right_angle_error, estimator_available, real(delta_root), ...
      imag(delta_root), real(delta_map), imag(delta_map), ...
      real(delta_map_oracle), imag(delta_map_oracle), real(delta_total), ...
      imag(delta_total), real(root_increment), imag(root_increment), ...
      linearization_consistency, tail_effectivity, combined_pass, status);
  end
  fclose(file_id);
end

function LOCAL_write_contours_csv(results, output_path)
  file_id = LOCAL_open_output(output_path);
  fprintf(file_id, ['j,radius,nodes,count_real,count_imag,' ...
    'min_relative_sigma,root_available,root_status\n']);
  for root_idx = 1:numel(results.roots)
    root = results.roots(root_idx);
    for contour_idx = 1:numel(root.contour_records)
      contour = root.contour_records(contour_idx);
      fprintf(file_id, '%d,%.17g,%d,%.17g,%.17g,%.17g,%d,%s\n', ...
        root.level_j, contour.radius, contour.nodes, real(contour.count), ...
        imag(contour.count), contour.min_relative_sigma, root.available, ...
        root.failure_reason);
    end
  end
  fclose(file_id);
end

function LOCAL_write_checks_csv(results, output_path)
  file_id = LOCAL_open_output(output_path);
  fprintf(file_id, ['j,root_error,derivative_spread,derivative_exact_error,' ...
    'left_angle_error,right_angle_error,estimator_available,' ...
    'delta_map_oracle_error,delta_total_sum_error,' ...
    'delta_total_direct_error,root_error_ratio,root_status,' ...
    'estimator_status\n']);
  for idx = 1:numel(results.roots)
    root = results.roots(idx);
    if idx <= numel(results.estimators)
      estimator = results.estimators(idx);
      fprintf(file_id, ['%d,%.17g,%.17g,%.17g,%.17g,%.17g,%d,' ...
        '%.17g,%.17g,%.17g,%.17g,%s,%s\n'], root.level_j, ...
        root.root_error, root.derivative_spread, root.derivative_exact_error, ...
        root.left_angle_error, root.right_angle_error, estimator.available, ...
        estimator.delta_map_oracle_error, estimator.delta_total_sum_error, ...
        estimator.delta_total_direct_error, estimator.root_error_ratio, ...
        root.failure_reason, estimator.failure_reason);
    else
      fprintf(file_id, ['%d,%.17g,%.17g,%.17g,%.17g,%.17g,0,' ...
        'NaN,NaN,NaN,NaN,%s,ROOT_ONLY\n'], root.level_j, root.root_error, ...
        root.derivative_spread, root.derivative_exact_error, ...
        root.left_angle_error, root.right_angle_error, root.failure_reason);
    end
  end
  fclose(file_id);
end

function LOCAL_write_negative_csv(results, output_path)
  file_id = LOCAL_open_output(output_path);
  fprintf(file_id, 'case_name,expected_label,observed_label,metric_1_real,metric_1_imag,metric_2_real,metric_2_imag,downstream_available,pass\n');
  for idx = 1:numel(results.negative_cases)
    current = results.negative_cases(idx);
    fprintf(file_id, '%s,%s,%s,%.17g,%.17g,%.17g,%.17g,%d,%d\n', ...
      strrep(current.name, ',', ';'), current.expected_label, ...
      current.observed_label, real(current.metric_1), imag(current.metric_1), ...
      real(current.metric_2), imag(current.metric_2), current.available, current.pass);
  end
  fclose(file_id);
end

function LOCAL_write_effectivity_svg(results, output_path)
  effectivity = [results.estimators.tail_effectivity];
  consistency = [results.estimators.linearization_consistency];
  levels = [results.estimators.level_j];
  width = 760;
  height = 600;
  left = 90;
  right = 720;
  effect_top = 55;
  effect_bottom = 260;
  effect_min = 0.75;
  effect_max = 1.01;
  consistency_top = 340;
  consistency_bottom = 540;
  consistency_log_min = -6;
  consistency_log_max = -1;
  x_values = left + (right - left) * (levels - min(levels)) / ...
    max(1, max(levels) - min(levels));
  effect_y = effect_bottom - (effect_bottom - effect_top) * ...
    (effectivity - effect_min) / (effect_max - effect_min);
  consistency_log = log10(consistency);
  consistency_y = consistency_bottom - ...
    (consistency_bottom - consistency_top) * ...
    (consistency_log - consistency_log_min) / ...
    (consistency_log_max - consistency_log_min);
  file_id = LOCAL_open_output(output_path);
  fprintf(file_id, '<?xml version="1.0" encoding="UTF-8"?>\n');
  fprintf(file_id, '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n', width, height, width, height);
  fprintf(file_id, '<rect width="100%%" height="100%%" fill="white"/>\n');
  fprintf(file_id, '<text x="380" y="25" text-anchor="middle" font-family="sans-serif" font-size="18">Manufactured estimator diagnostics</text>\n');
  fprintf(file_id, '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="black"/>\n', left, effect_bottom, right, effect_bottom);
  fprintf(file_id, '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="black"/>\n', left, effect_top, left, effect_bottom);
  y_one = effect_bottom - (effect_bottom - effect_top) * ...
    (1 - effect_min) / (effect_max - effect_min);
  fprintf(file_id, '<line x1="%d" y1="%.6f" x2="%d" y2="%.6f" stroke="#777" stroke-dasharray="6,4"/>\n', left, y_one, right, y_one);
  fprintf(file_id, '<text x="%d" y="%.6f" text-anchor="end" font-family="sans-serif" font-size="12">1.0</text>\n', left - 8, y_one + 4);
  fprintf(file_id, '<polyline fill="none" stroke="#1769aa" stroke-width="3" points="');
  for idx = 1:numel(levels)
    fprintf(file_id, '%.6f,%.6f ', x_values(idx), effect_y(idx));
  end
  fprintf(file_id, '"/>\n');
  for idx = 1:numel(levels)
    fprintf(file_id, '<circle cx="%.6f" cy="%.6f" r="5" fill="#1769aa"/>\n', x_values(idx), effect_y(idx));
    fprintf(file_id, '<text x="%.6f" y="%.6f" text-anchor="middle" font-family="sans-serif" font-size="11">%.6f</text>\n', x_values(idx), effect_y(idx) - 10, effectivity(idx));
  end
  fprintf(file_id, '<text x="25" y="158" transform="rotate(-90 25 158)" text-anchor="middle" font-family="sans-serif" font-size="14">tail effectivity</text>\n');

  fprintf(file_id, '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="black"/>\n', left, consistency_bottom, right, consistency_bottom);
  fprintf(file_id, '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="black"/>\n', left, consistency_top, left, consistency_bottom);
  for exponent = consistency_log_min:consistency_log_max
    tick_y = consistency_bottom - ...
      (consistency_bottom - consistency_top) * ...
      (exponent - consistency_log_min) / ...
      (consistency_log_max - consistency_log_min);
    fprintf(file_id, '<line x1="%d" y1="%.6f" x2="%d" y2="%.6f" stroke="#ddd"/>\n', left, tick_y, right, tick_y);
    fprintf(file_id, '<text x="%d" y="%.6f" text-anchor="end" font-family="sans-serif" font-size="12">10^%d</text>\n', left - 8, tick_y + 4, exponent);
  end
  fprintf(file_id, '<polyline fill="none" stroke="#c75b12" stroke-width="3" points="');
  for idx = 1:numel(levels)
    fprintf(file_id, '%.6f,%.6f ', x_values(idx), consistency_y(idx));
  end
  fprintf(file_id, '"/>\n');
  for idx = 1:numel(levels)
    fprintf(file_id, '<circle cx="%.6f" cy="%.6f" r="5" fill="#c75b12"/>\n', x_values(idx), consistency_y(idx));
    fprintf(file_id, '<text x="%.6f" y="%.6f" text-anchor="middle" font-family="sans-serif" font-size="11">%.2e</text>\n', x_values(idx), consistency_y(idx) - 10, consistency(idx));
    fprintf(file_id, '<text x="%.6f" y="%d" text-anchor="middle" font-family="sans-serif" font-size="12">j=%d</text>\n', x_values(idx), consistency_bottom + 22, levels(idx));
  end
  fprintf(file_id, '<text x="25" y="440" transform="rotate(-90 25 440)" text-anchor="middle" font-family="sans-serif" font-size="14">linearization consistency</text>\n');
  fprintf(file_id, '</svg>\n');
  fclose(file_id);
end

function LOCAL_write_report(results, output_path)
  file_id = LOCAL_open_output(output_path);
  fprintf(file_id, '# Manufactured NEP experiment report\n\n');
  fprintf(file_id, '- Version: `%s`\n', results.config.version_label);
  fprintf(file_id, '- Estimator status: `%s`\n', results.config.estimator_label);
  fprintf(file_id, '- Overall result: **%s**\n\n', ...
    LOCAL_label(results.all_pass, 'PASS', 'FAIL'));
  fprintf(file_id, '## Question and method\n\n');
  fprintf(file_id, ['This experiment tests the fixed-dimensional contour, bordered-Newton, ' ...
    'root-qualification, and projected-correction pipeline on the pre-registered 2-by-2 ' ...
    'analytic hierarchy. It does not test a physical BIE or DtN map.\n\n']);
  fprintf(file_id, '## Positive hierarchy\n\n');
  fprintf(file_id, '| j | root error | consistency | tail effectivity | status |\n');
  fprintf(file_id, '|---:|---:|---:|---:|---|\n');
  for idx = 1:numel(results.estimators)
    root = results.roots(idx);
    estimator = results.estimators(idx);
    fprintf(file_id, '| %d | %.6e | %.6e | %.9f | %s |\n', ...
      estimator.level_j, root.root_error, estimator.linearization_consistency, ...
      estimator.tail_effectivity, estimator.failure_reason);
  end
  fprintf(file_id, '\n## Negative cases\n\n');
  fprintf(file_id, '| case | expected | observed | pass |\n');
  fprintf(file_id, '|---|---|---|---:|\n');
  for idx = 1:numel(results.negative_cases)
    current = results.negative_cases(idx);
    fprintf(file_id, '| %s | `%s` | `%s` | %d |\n', current.name, ...
      current.expected_label, current.observed_label, current.pass);
  end
  fprintf(file_id, '\n## Interpretation\n\n');
  fprintf(file_id, ['Passing results support only the manufactured finite-dimensional ' ...
    'algorithm and the conditional empirical effectivity trend. Tail and total errors ' ...
    'coincide here. No certified interval, BIE mapping, branch chart, pole ledger, ' ...
    'half-guide convergence, or physical guided mode has been validated.\n']);
  fclose(file_id);
end

function LOCAL_write_lines(lines, output_path)
  file_id = LOCAL_open_output(output_path);
  for idx = 1:numel(lines)
    fprintf(file_id, '%s\n', lines{idx});
  end
  fclose(file_id);
end

function LOCAL_save_results(results, output_path)
  if exist('OCTAVE_VERSION', 'builtin')
    save('-mat7-binary', output_path, 'results');
  else
    save(output_path, 'results', '-v7');
  end
end

function file_id = LOCAL_open_output(output_path)
  file_id = fopen(output_path, 'w');
  if file_id < 0
    error('run_manufactured_nep:OutputOpenFailed', ...
      'Could not open output file: %s', output_path);
  end
end

%% ==================== Provenance and console reporting ====================
% These helpers record source identity and print the compact run summary.

function git_base = LOCAL_git_base(project_root)
  command = sprintf('git -C "%s" rev-parse --short=12 HEAD', project_root);
  [status, output] = system(command);
  if status == 0
    git_base = strtrim(output);
  else
    git_base = 'UNAVAILABLE';
  end
end

function records = LOCAL_hash_records(project_root, experiment_dir)
  relative_paths = {
    'research/projects/eig-apost/phase4-report/method.tex'
    'research/projects/eig-apost/phase3-analysis/s-root.md'
    'research/projects/eig-apost/phase3-analysis/s-estimator.md'
    'research/projects/eig-apost/phase3-analysis/p-implement.md'
    'research/projects/eig-apost/implementation/design.md'
    'research/projects/eig-apost/implementation/SYMBOL.md'
    'research/projects/eig-apost/implementation/experiment_plan.md'
    'research/projects/eig-apost/implementation/nep-review.md'
    'test/eig-apost-nep/run_manufactured_nep.m'
  };
  records = repmat(struct('relative_path', '', 'hash', ''), 1, ...
    numel(relative_paths));
  for idx = 1:numel(relative_paths)
    records(idx).relative_path = relative_paths{idx};
    if strcmp(relative_paths{idx}, 'test/eig-apost-nep/run_manufactured_nep.m')
      absolute_path = fullfile(experiment_dir, 'run_manufactured_nep.m');
    else
      absolute_path = fullfile(project_root, relative_paths{idx});
    end
    records(idx).hash = LOCAL_sha256(absolute_path);
  end
end

function hash_value = LOCAL_sha256(file_path)
  command = sprintf('shasum -a 256 "%s"', file_path);
  [status, output] = system(command);
  if status ~= 0
    hash_value = 'UNAVAILABLE';
    return;
  end
  tokens = strsplit(strtrim(output));
  hash_value = tokens{1};
end

function LOCAL_print_summary(results)
  fprintf('j   root error       consistency      tail effectivity\n');
  for idx = 1:numel(results.estimators)
    fprintf('%d   %.6e   %.6e   %.9f\n', ...
      results.estimators(idx).level_j, results.roots(idx).root_error, ...
      results.estimators(idx).linearization_consistency, ...
      results.estimators(idx).tail_effectivity);
  end
  for idx = 1:numel(results.negative_cases)
    fprintf('%s: %s\n', results.negative_cases(idx).name, ...
      results.negative_cases(idx).observed_label);
  end
  if results.all_pass
    fprintf('ALL TESTS PASS\n');
  else
    fprintf('TESTS FAILED\n');
  end
end
