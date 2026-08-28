function run_i4_1a(run_id)
%RUN_I4_1A Produce the blinded I4.1a fitted-FEM reference artifact.
% Purpose:
%   Solve the frozen independent fixed-beta bulk and line-defect problems by
%   a self-contained polygon-interface conforming P1 finite-element method.
% Input:
%   run_id - Explicit artifact label.  It changes no scientific parameter.
% Output:
%   Machine-readable artifacts below output/<run_id>/ next to this file.
% Main algorithm:
%   Build deterministic fitted meshes, assemble volume stiffness and
%   weighted mass forms, impose both quasiperiodic phases through a nodal
%   prolongation, inventory all frozen low spectra, track cluster subspaces,
%   and apply the preregistered coverage and empirical-resolution gates.
% Based on:
%   research/projects/eig-apost/implementation/i4/design-4-1a.md, Sections
%   2--12, under method-4-1.md and method-review.md.
% Main changes:
%   This is an independent volume-FEM implementation.  It does not call or
%   read any current BIE, QZ, estimator, density, candidate, or field object.
% Numerical goal:
%   Export REFERENCE_COLLECTION_READY or one complete fail-closed ledger.
% Notes:
%   The code reads only its own current-run machine caches.  It never reads
%   Markdown, Git metadata, historical output, or a repository path.

  if nargin ~= 1 || ~(ischar(run_id) || (isstring(run_id) && isscalar(run_id)))
    error('I4A:InvalidRunId', 'run_id must be one character vector or string scalar.');
  end
  run_id = char(run_id);
  if isempty(regexp(run_id, '^[A-Za-z0-9][A-Za-z0-9-]*$', 'once'))
    error('I4A:InvalidRunId', 'run_id must match [A-Za-z0-9][A-Za-z0-9-]*.');
  end

  entry_dir = fileparts(mfilename('fullpath'));
  output_dir = fullfile(entry_dir, 'output', run_id);
  if exist(output_dir, 'dir') || exist(output_dir, 'file')
    error('I4A:OutputCollision', 'OUTPUT_COLLISION: output/%s already exists.', run_id);
  end
  [made_output, output_message] = mkdir(output_dir);
  if ~made_output
    error('I4A:OutputUnavailable', 'Cannot create output directory: %s', output_message);
  end
  work_dir = fullfile(output_dir, 'work');
  [made_work, work_message] = mkdir(work_dir);
  if ~made_work
    error('I4A:OutputUnavailable', 'Cannot create work directory: %s', work_message);
  end

  diary_path = fullfile(output_dir, 'matlab.log');
  diary(diary_path);
  cleanup_diary = onCleanup(@() diary('off')); %#ok<NASGU>
  fprintf('I4.1a blinded fitted-FEM run %s\n', run_id);
  fprintf('MATLAB %s on %s\n', version, computer);

  spec = LOCAL_spec();
  run_state = LOCAL_initial_state(run_id, spec);
  artifacts = struct();
  artifacts.mesh_rows = cell(0, 21);
  artifacts.seam_rows = cell(0, 12);
  artifacts.bulk_rows = cell(0, 10);
  artifacts.bulk_gap_rows = cell(0, 14);
  artifacts.spectrum_rows = cell(0, 14);
  artifacts.branch_edge_rows = cell(0, 14);
  artifacts.branch_rows = cell(0, 24);
  artifacts.coverage_rows = cell(0, 12);
  artifacts.resolution_rows = cell(0, 19);
  artifacts.resource_rows = cell(0, 10);

  try
    % --- stage 1: establish the source-owned specification and environment ---
    run_state.current_stage = 'SPEC_AND_ENVIRONMENT';
    run_state = LOCAL_progress(run_state, output_dir, 'stage-start', NaN);
    LOCAL_check_environment(spec);
    LOCAL_write_model_and_config(spec, output_dir);

    % --- stage 2: build all frozen meshes and enforce pre-solve oracles ---
    run_state.current_stage = 'MESH_ORACLES';
    run_state = LOCAL_progress(run_state, output_dir, 'stage-start', NaN);
    [mesh_registry, artifacts.mesh_rows, artifacts.seam_rows, ...
      preflight, artifacts.resource_rows] = LOCAL_preflight_audit( ...
      spec, work_dir, output_dir, toc(run_state.start_clock));
    LOCAL_write_mesh_artifacts(artifacts, output_dir);
    LOCAL_write_resource_preflight(preflight, artifacts.resource_rows, output_dir);
    run_state.wall_estimate_minutes = preflight.wall_estimate_minutes;
    run_state.peak_estimate_gib = preflight.peak_estimate_gib;
    run_state.resource_preflight = preflight;
    if ~preflight.pass
      LOCAL_raise('RESOURCE_BUDGET_UNAVAILABLE', preflight.reason);
    end

    % --- stage 3: inventory the independent bulk spectrum and target gap ---
    run_state.current_stage = 'BULK_INVENTORY';
    run_state = LOCAL_progress(run_state, output_dir, 'stage-start', NaN);
    [bulk_inventory, run_state, artifacts] = LOCAL_bulk_inventory( ...
      spec, mesh_registry, work_dir, output_dir, run_state, artifacts);
    LOCAL_write_bulk_artifacts(artifacts, output_dir);

    % --- stage 4: compute the complete frozen defect solve union ---
    run_state.current_stage = 'DEFECT_INVENTORY';
    run_state = LOCAL_progress(run_state, output_dir, 'stage-start', NaN);
    [defect_inventory, run_state, artifacts] = LOCAL_defect_inventory( ...
      spec, bulk_inventory, mesh_registry, work_dir, output_dir, ...
      run_state, artifacts);
    LOCAL_write_defect_artifact(artifacts, output_dir);

    % --- stage 5: track subspaces and apply the all-object coverage gate ---
    run_state.current_stage = 'BRANCH_AND_COVERAGE';
    run_state = LOCAL_progress(run_state, output_dir, 'stage-start', NaN);
    [branch_inventory, coverage_result, artifacts] = ...
      LOCAL_branch_and_coverage(spec, bulk_inventory, defect_inventory, ...
      mesh_registry, work_dir, artifacts);
    LOCAL_write_branch_artifacts(artifacts, output_dir);
    if ~coverage_result.pass
      if ~isempty(branch_inventory.reached_anchor_fields)
        LOCAL_export_failure_fields(branch_inventory, mesh_registry, ...
          work_dir, output_dir, coverage_result.failure_code, ...
          coverage_result.reason);
      end
      LOCAL_raise(coverage_result.failure_code, coverage_result.reason);
    end
    if isempty(branch_inventory.finest_branches)
      failure_reason = ...
        'No branch qualified under the frozen observed localization screen.';
      artifacts = LOCAL_mark_branch_failure(artifacts, ...
        'NO_LOCALIZED_BRANCH', failure_reason);
      LOCAL_write_branch_artifacts(artifacts, output_dir);
      if ~isempty(branch_inventory.reached_anchor_fields)
        LOCAL_export_failure_fields(branch_inventory, mesh_registry, ...
          work_dir, output_dir, 'NO_LOCALIZED_BRANCH', failure_reason);
      end
      LOCAL_raise('NO_LOCALIZED_BRANCH', ...
        failure_reason);
    end

    % --- stage 6: form the basis-invariant four-axis resolution ledger ---
    run_state.current_stage = 'RESOLUTION';
    run_state = LOCAL_progress(run_state, output_dir, 'stage-start', NaN);
    [resolution_result, artifacts] = LOCAL_resolution( ...
      spec, bulk_inventory, branch_inventory, artifacts);
    LOCAL_write_resolution_artifact(artifacts, output_dir);
    if ~resolution_result.pass
      artifacts = LOCAL_mark_branch_failure(artifacts, ...
        resolution_result.failure_code, resolution_result.reason);
      LOCAL_write_branch_artifacts(artifacts, output_dir);
      LOCAL_export_failure_fields(branch_inventory, mesh_registry, ...
        work_dir, output_dir, resolution_result.failure_code, ...
        resolution_result.reason);
      LOCAL_raise(resolution_result.failure_code, resolution_result.reason);
    end

    % --- stage 7: atomically publish the blinded collection and fields ---
    run_state.current_stage = 'BLIND_EXPORT';
    run_state = LOCAL_progress(run_state, output_dir, 'stage-start', NaN);
    run_state.terminal_status = 'REFERENCE_COLLECTION_READY';
    run_state.success = true;
    LOCAL_export_success(spec, bulk_inventory, branch_inventory, ...
      coverage_result, resolution_result, mesh_registry, work_dir, ...
      output_dir, run_state);

    % --- stage 8: stop before any reveal or current-chain comparison ---
    run_state.current_stage = 'STOP_BEFORE_REVEAL';
    run_state = LOCAL_progress(run_state, output_dir, 'complete', 0);
    LOCAL_write_failures({}, output_dir);
    LOCAL_write_summary(run_state, output_dir);
    fprintf('Terminal status: %s\n', run_state.terminal_status);
  catch caught
    [failure_code, failure_message] = LOCAL_decode_failure(caught);
    run_state.success = false;
    run_state.terminal_status = failure_code;
    run_state.first_failure = failure_message;
    run_state.elapsed_seconds = toc(run_state.start_clock);
    LOCAL_write_failures({failure_code, failure_message, ...
      run_state.current_stage, run_state.elapsed_seconds}, output_dir);
    LOCAL_export_failure(spec, run_state, output_dir);
    LOCAL_write_summary(run_state, output_dir);
    fprintf(2, 'Terminal status: %s\n%s\n', failure_code, failure_message);
    if strcmp(failure_code, 'EXECUTION_UNAVAILABLE')
      fprintf(2, '%s\n', getReport(caught, 'extended', 'hyperlinks', 'off'));
    end
  end
end

%% ==================== Frozen specification ====================
% These helpers own every scientific parameter and the fixed solve union.

function spec = LOCAL_spec()
  spec = struct();
  spec.design_id = 'I4.1A-FEM-SUPERCELL-REFERENCE-V1';
  spec.model_id = 'scalar-laplace-q17-r0p2-beta0p5-missing0-v1';
  spec.period = 1;
  spec.radius = 0.2;
  spec.q_inside = 17;
  spec.q_outside = 1;
  spec.missing_column = 0;
  spec.beta = 0.5;
  spec.cue_interval = [1.65, 2.05];
  spec.guard_interval = [1.25, 2.45];
  spec.bulk_alpha_17 = linspace(0, pi, 17);
  spec.bulk_alpha_33 = linspace(0, pi, 33);
  spec.count_phases = [0, pi / 4, pi / 2, 3 * pi / 4, pi];
  spec.theta_5 = linspace(0, pi, 5);
  spec.theta_9 = linspace(0, pi, 9);
  spec.theta_17 = linspace(0, pi, 17);
  spec.bulk_main_nev = 40;
  spec.defect_main_nev = 40;
  spec.count_nev = 48;
  spec.eigs_maxit = 800;
  spec.eigs_subspace_main = 80;
  spec.eigs_subspace_count = 96;
  spec.eigs_subspace_cap = 100;
  spec.residual_tolerance = 1e-9;
  spec.orthogonality_tolerance = 1e-7;
  spec.imaginary_tolerance = 1e-10;
  spec.hermitian_tolerance = 5e-13;
  spec.coordinate_tolerance = 1e-13;
  spec.seam_tolerance = 1e-12;
  spec.constraint_tolerance = 2e-12;
  spec.reflection_tolerance = 5e-11;
  spec.minimum_angle_degrees = 3;
  spec.finest_hausdorff_cap = 5e-4;
  spec.cluster_frequency_tolerance = 1e-6;
  spec.cluster_residual_factor = 20;
  spec.bulk_count_frequency_tolerance = 1e-8;
  spec.defect_count_frequency_tolerance = 1e-7;
  spec.lower_sentinel_margin = 0.10;
  spec.upper_sentinel_margin = 0.10;
  spec.safe_gap_fraction = 0.80;
  spec.bulk_terminal_fraction = 5e-3;
  spec.localization_center_min = 0.15;
  spec.localization_core_min = 0.60;
  spec.tail_max = 0.02;
  spec.collapse_factor = 0.80;
  spec.tail_plateau = 1e-4;
  spec.simple_overlap_min = 0.90;
  spec.cluster_overlap_min = 0.80;
  spec.parity_threshold = 0.80;
  spec.resolution_terminal_fraction = 5e-4;
  spec.total_resolution_fraction = 0.02;
  spec.algebraic_relative_cap = 1e-8;
  spec.algebraic_component_fraction = 0.05;
  spec.core_grid_x = linspace(-2.5, 2.5, 161);
  spec.core_grid_y = linspace(-0.5, 0.5, 65);
  spec.dof_cap = 12000;
  spec.nnz_cap = 2000000;
  spec.preflight_peak_cap_gib = 1.5;
  spec.hard_peak_cap_gib = 2.0;
  spec.soft_wall_minutes = 30;
  spec.hard_wall_minutes = 40;
  spec.planned_bulk_solves = 72;
  spec.planned_defect_solves = 47;
  spec.planned_solves = 119;
  spec.design_wall_estimate_minutes = 29.8;
  spec.design_peak_estimate_gib = 1.2;
  spec.random_seed = 4101;
  spec.model_digest = LOCAL_model_digest(spec);
end

function digest = LOCAL_model_digest(spec)
  canonical = sprintf(['period=%.17g;radius=%.17g;qin=%.17g;qout=%.17g;' ...
    'missing=%d;beta=%.17g;cue=%.17g,%.17g;guard=%.17g,%.17g;' ...
    'bulk=12,24,18,36,24,48;defect=N3,N4,N5;nev=40,48;seed=%d'], ...
    spec.period, spec.radius, spec.q_inside, spec.q_outside, ...
    spec.missing_column, spec.beta, spec.cue_interval, ...
    spec.guard_interval, spec.random_seed);
  try
    engine = java.security.MessageDigest.getInstance('SHA-256');
    hash_bytes = typecast(engine.digest(uint8(canonical)), 'uint8');
    digest = lower(reshape(dec2hex(hash_bytes, 2).', 1, []));
  catch
    digest = 'SHA256_UNAVAILABLE';
  end
end

function schedule = LOCAL_mesh_schedule()
  schedule = struct('id', {}, 'kind', {}, 'N', {}, 's', {}, 'n_gamma', {});
  schedule(end + 1) = LOCAL_mesh_item('bulk-s12-g24', 'bulk', 0, 12, 24);
  schedule(end + 1) = LOCAL_mesh_item('bulk-s18-g36', 'bulk', 0, 18, 36);
  schedule(end + 1) = LOCAL_mesh_item('bulk-s24-g48', 'bulk', 0, 24, 48);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s12-g24', 'defect', 5, 12, 24);
  schedule(end + 1) = LOCAL_mesh_item('defect-N3-s18-g36', 'defect', 3, 18, 36);
  schedule(end + 1) = LOCAL_mesh_item('defect-N4-s18-g36', 'defect', 4, 18, 36);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s18-g36', 'defect', 5, 18, 36);
  schedule(end + 1) = LOCAL_mesh_item('defect-N4-s24-g48', 'defect', 4, 24, 48);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s24-g48', 'defect', 5, 24, 48);
end

function item = LOCAL_mesh_item(id, kind, N, s, n_gamma)
  item = struct('id', id, 'kind', kind, 'N', N, 's', s, ...
    'n_gamma', n_gamma);
end

function schedule = LOCAL_defect_schedule(spec)
  schedule = struct('id', {}, 'mesh_id', {}, 'theta', {}, 'tol', {}, ...
    'nev', {}, 'role', {});
  schedule = LOCAL_add_solve_group(schedule, 'fem-coarse', ...
    'defect-N5-s12-g24', spec.theta_5, 1e-11, 40, 'tight');
  schedule = LOCAL_add_solve_group(schedule, 'fem-medium', ...
    'defect-N5-s18-g36', spec.theta_5, 1e-11, 40, 'tight');
  schedule = LOCAL_add_solve_group(schedule, 'fine', ...
    'defect-N5-s24-g48', spec.theta_17, 1e-11, 40, 'tight');
  schedule = LOCAL_add_solve_group(schedule, 'N3-medium', ...
    'defect-N3-s18-g36', spec.theta_5, 1e-11, 40, 'tight');
  schedule = LOCAL_add_solve_group(schedule, 'N4-medium', ...
    'defect-N4-s18-g36', spec.theta_5, 1e-11, 40, 'tight');
  schedule = LOCAL_add_solve_group(schedule, 'N4-fine', ...
    'defect-N4-s24-g48', spec.theta_5, 1e-11, 40, 'tight');
  schedule = LOCAL_add_solve_group(schedule, 'fine-loose-count', ...
    'defect-N5-s24-g48', spec.theta_5, 1e-8, 48, 'loose-count');
end

function schedule = LOCAL_add_solve_group(schedule, prefix, mesh_id, ...
    phases, tolerance, nev, role)
  for phase_index = 1:numel(phases)
    item = struct();
    item.id = sprintf('%s-p%02d', prefix, phase_index);
    item.mesh_id = mesh_id;
    item.theta = phases(phase_index);
    item.tol = tolerance;
    item.nev = nev;
    item.role = role;
    schedule(end + 1) = item; %#ok<AGROW>
  end
end

%% ==================== Run state and atomic artifacts ====================
% These helpers implement stage-first progress and first-failure publication.

function run_state = LOCAL_initial_state(run_id, spec)
  run_state = struct();
  run_state.run_id = run_id;
  run_state.design_id = spec.design_id;
  run_state.model_id = spec.model_id;
  run_state.model_digest = spec.model_digest;
  run_state.start_clock = tic;
  run_state.current_stage = 'INITIALIZING';
  run_state.terminal_status = 'RUNNING';
  run_state.first_failure = '';
  run_state.success = false;
  run_state.completed_solves = 0;
  run_state.planned_solves = spec.planned_solves;
  run_state.wall_estimate_minutes = spec.design_wall_estimate_minutes;
  run_state.peak_estimate_gib = spec.design_peak_estimate_gib;
  run_state.progress_rows = cell(0, 8);
  run_state.elapsed_seconds = 0;
end

function LOCAL_check_environment(spec)
  required_functions = {'sparse', 'eigs', 'symbfact'};
  for function_index = 1:numel(required_functions)
    if exist(required_functions{function_index}, 'file') == 0 && ...
        exist(required_functions{function_index}, 'builtin') == 0
      LOCAL_raise('DEPENDENCY_UNAVAILABLE', ...
        sprintf('Required base MATLAB function is unavailable: %s', ...
        required_functions{function_index}));
    end
  end
  required_classes = {'delaunayTriangulation', 'triangulation'};
  for class_index = 1:numel(required_classes)
    if exist(required_classes{class_index}, 'class') == 0
      LOCAL_raise('DEPENDENCY_UNAVAILABLE', ...
        sprintf('Required base MATLAB class is unavailable: %s', ...
        required_classes{class_index}));
    end
  end
  triangulation_methods = methods('triangulation');
  if ~any(strcmp(triangulation_methods, 'pointLocation'))
    LOCAL_raise('DEPENDENCY_UNAVAILABLE', ...
      'Required triangulation class method is unavailable: pointLocation');
  end
  if spec.planned_bulk_solves + spec.planned_defect_solves ~= 119
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'Frozen bulk and defect solve counts do not sum to 119.');
  end
  if strcmp(spec.model_digest, 'SHA256_UNAVAILABLE')
    LOCAL_raise('DEPENDENCY_UNAVAILABLE', ...
      'The source-owned physical specification digest is unavailable.');
  end
  if spec.period ~= 1 || spec.radius ~= 0.2 || ...
      spec.q_inside ~= 17 || spec.q_outside ~= 1 || ...
      spec.beta ~= 0.5 || spec.missing_column ~= 0
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'Source-owned physical constants differ from the frozen scalar model.');
  end
end

function run_state = LOCAL_progress(run_state, output_dir, note, eta_seconds)
  run_state.elapsed_seconds = toc(run_state.start_clock);
  rate = NaN;
  if run_state.completed_solves > 0
    rate = run_state.elapsed_seconds / run_state.completed_solves;
  end
  row = {size(run_state.progress_rows, 1) + 1, run_state.current_stage, ...
    note, run_state.completed_solves, run_state.planned_solves, ...
    run_state.elapsed_seconds, rate, eta_seconds};
  run_state.progress_rows(end + 1, :) = row;
  LOCAL_write_csv(fullfile(output_dir, 'progress.csv'), ...
    {'sequence', 'stage', 'note', 'completed_solves', 'planned_solves', ...
    'elapsed_seconds', 'seconds_per_completed_solve', 'eta_seconds'}, ...
    run_state.progress_rows);
end

function LOCAL_write_model_and_config(spec, output_dir)
  model_rows = {
    'model_id', spec.model_id;
    'model_digest', spec.model_digest;
    'weak_form', 'integral_grad_u_grad_v_equals_lambda_integral_q_u_v';
    'polarization_identity', 'A_equals_I_B_equals_q';
    'geometry_target', 'exact_circle_polygon_fitted_variational_crime';
    'information_state', 'BLINDED_NO_CURRENT_CHAIN_INPUT'};
  LOCAL_write_csv(fullfile(output_dir, 'model.csv'), ...
    {'field', 'value'}, model_rows);

  names = fieldnames(spec);
  config_rows = cell(0, 3);
  for field_index = 1:numel(names)
    value = spec.(names{field_index});
    if isnumeric(value) || islogical(value)
      config_rows(end + 1, :) = {names{field_index}, ...
        LOCAL_flat_numeric(value), class(value)}; %#ok<AGROW>
    elseif ischar(value)
      config_rows(end + 1, :) = {names{field_index}, value, 'char'}; %#ok<AGROW>
    end
  end
  LOCAL_write_csv(fullfile(output_dir, 'config.csv'), ...
    {'parameter', 'value', 'type'}, config_rows);
end

function text_value = LOCAL_flat_numeric(value)
  if isempty(value)
    text_value = '';
    return;
  end
  pieces = arrayfun(@(entry) sprintf('%.17g', entry), value(:).', ...
    'UniformOutput', false);
  text_value = strjoin(pieces, ';');
end

function LOCAL_write_mesh_artifacts(artifacts, output_dir)
  LOCAL_write_csv(fullfile(output_dir, 'mesh-ledger.csv'), ...
    {'mesh_id', 'kind', 'N', 's', 'n_gamma', 'full_nodes', ...
    'reduced_dof', 'triangles', 'constraints', 'min_angle_degrees', ...
    'area_deficit', 'hausdorff_defect', 'constraint_missing_count', ...
    'cross_interface_count', 'nnz_stiffness', 'nnz_mass', ...
    'reflection_stiffness_defect', 'reflection_mass_defect', ...
    'reached_boundary', 'first_failure_code', 'first_failure_reason'}, ...
    artifacts.mesh_rows);
  LOCAL_write_csv(fullfile(output_dir, 'seam-checks.csv'), ...
    {'mesh_id', 'phase_kind', 'phase', 'x_pairs', 'y_pairs', ...
    'corner_pairs', 'coordinate_mismatch', 'seam_residual', ...
    'corner_factor_real', 'corner_factor_imag', ...
    'hermitian_stiffness_defect', 'hermitian_mass_defect'}, ...
    artifacts.seam_rows);
end

function LOCAL_write_resource_preflight(preflight, rows, output_dir)
  LOCAL_write_csv(fullfile(output_dir, 'resource-preflight.csv'), ...
    {'category', 'kind', 'solve_count', 'nominal_seconds_per_solve', ...
    'complexity_scale', 'runtime_safety_factor', 'estimated_seconds', ...
    'estimated_peak_bytes', 'estimated_cache_bytes', 'notes'}, rows);
  LOCAL_atomic_save(fullfile(output_dir, 'resource-preflight.mat'), preflight);
end

function LOCAL_write_bulk_artifacts(artifacts, output_dir)
  LOCAL_write_csv(fullfile(output_dir, 'bulk-bands.csv'), ...
    {'level', 'solve_id', 'alpha', 'root_index', 'frequency', ...
    'eigenvalue', 'algebraic_residual', 'cluster_id', ...
    'cluster_multiplicity', 'solver_role'}, artifacts.bulk_rows);
  LOCAL_write_csv(fullfile(output_dir, 'bulk-gaps.csv'), ...
    {'level', 'gap_index', 'lower_edge', 'upper_edge', 'contains_cue', ...
    'inside_guard', 'lower_change', 'upper_change', 'delta_lower', ...
    'delta_upper', 'safe_lower', 'safe_upper', 'gate_pass', 'reason'}, ...
    artifacts.bulk_gap_rows);
end

function LOCAL_write_defect_artifact(artifacts, output_dir)
  LOCAL_write_csv(fullfile(output_dir, 'spectrum-inventory.csv'), ...
    {'solve_id', 'mesh_id', 'role', 'theta', 'requested_nev', ...
    'root_index', 'frequency', 'eigenvalue', 'algebraic_residual', ...
    'cluster_id', 'cluster_multiplicity', 'in_raw_gap', ...
    'in_safe_gap', 'in_edge_buffer'}, artifacts.spectrum_rows);
end

function LOCAL_write_branch_artifacts(artifacts, output_dir)
  LOCAL_write_csv(fullfile(output_dir, 'branch-edges.csv'), ...
    {'configuration', 'from_theta', 'to_theta', 'from_cluster', ...
    'to_cluster', 'dimension', 'minimum_overlap', 'threshold', ...
    'mutual_unique', 'accepted', 'from_branch', 'to_branch', ...
    'first_failure_code', 'first_failure_reason'}, ...
    artifacts.branch_edge_rows);
  LOCAL_write_csv(fullfile(output_dir, 'branch-inventory.csv'), ...
    {'configuration', 'branch_id', 'dimension', 'theta', ...
    'frequency_min', 'frequency_max', 'L0_min', 'Lcore_min', ...
    'tail_max', 'parity_signature', 'parity_ambiguous', ...
    'localization_pass', 'tail_pass', 'continuation_pass', ...
    'envelope_min', 'envelope_max', 'envelope_center', ...
    'twist_half_width', 'all_slice_pass', 'decision', ...
    'basis_label', 'failure_reason', 'first_failure_code', ...
    'first_failure_reason'}, artifacts.branch_rows);
  LOCAL_write_csv(fullfile(output_dir, 'coverage-ledger.csv'), ...
    {'configuration', 'solve_id', 'theta', 'cluster_id', 'multiplicity', ...
    'branch_id', 'disposition', 'reason', 'edge_buffer', 'coverage_pass', ...
    'first_failure_code', 'first_failure_reason'}, ...
    artifacts.coverage_rows);
end

function LOCAL_write_resolution_artifact(artifacts, output_dir)
  LOCAL_write_csv(fullfile(output_dir, 'branch-resolution.csv'), ...
    {'branch_id', 'multiplicity', 'reference_frequency', ...
    'reference_min', 'reference_max', 'delta_fem_previous', ...
    'delta_fem', 'delta_N_previous', 'delta_N_medium', ...
    'delta_N_fine', 'delta_N', 'delta_twist_previous', ...
    'delta_twist_sampling', 'twist_half_width', 'delta_twist', ...
    'delta_algebraic', 'delta_reference', 'gate_pass', 'reason'}, ...
    artifacts.resolution_rows);
end

function LOCAL_write_failures(failure_row, output_dir)
  if isempty(failure_row)
    rows = cell(0, 4);
  else
    rows = reshape(failure_row, 1, 4);
  end
  LOCAL_write_csv(fullfile(output_dir, 'failures.csv'), ...
    {'failure_code', 'message', 'stage', 'elapsed_seconds'}, rows);
end

function LOCAL_write_summary(run_state, output_dir)
  run_state.elapsed_seconds = toc(run_state.start_clock);
  payload = run_state;
  payload.matlab_version = version;
  payload.computer = computer;
  payload.claim_boundary = ['EMPIRICAL_OBSERVED_REFERENCE_ONLY;' ...
    'NOT_CERTIFIED;NO_EFFECTIVITY;STOP_BEFORE_REVEAL'];
  LOCAL_atomic_save(fullfile(output_dir, 'run-summary.mat'), payload);
end

function LOCAL_export_failure(spec, run_state, output_dir)
  reference_collection = struct('model_id', spec.model_id, ...
    'status', run_state.terminal_status, 'branches', [], ...
    'claim_boundary', 'EMPTY_FAIL_CLOSED_COLLECTION');
  LOCAL_atomic_save(fullfile(output_dir, 'reference-collection.mat'), ...
    reference_collection);
end

function LOCAL_export_success(spec, bulk_inventory, branch_inventory, ...
    coverage_result, resolution_result, mesh_registry, work_dir, ...
    output_dir, run_state)
  reference_collection = struct();
  reference_collection.model_id = spec.model_id;
  reference_collection.model_digest = spec.model_digest;
  reference_collection.status = 'REFERENCE_COLLECTION_READY';
  reference_collection.bulk_gap = bulk_inventory.target_gap;
  reference_collection.coverage = coverage_result;
  reference_collection.branches = resolution_result.collection;
  reference_collection.claim_boundary = ['FINITE_EMPIRICAL_OBSERVED_SET;' ...
    'DELTA_IS_NOT_AN_UPPER_BOUND;NO_CONTINUOUS_COMPLETENESS;NO_EFFECTIVITY'];
  LOCAL_atomic_save(fullfile(output_dir, 'reference-collection.mat'), ...
    reference_collection);

  finest_mesh = LOCAL_load_mesh(mesh_registry, work_dir, ...
    'defect-N5-s24-g48');
  fields = struct();
  fields.model_id = spec.model_id;
  fields.artifact_status = 'QUALIFIED / REFERENCE_COLLECTION_READY';
  fields.mesh_points = finest_mesh.points;
  fields.mesh_triangles = finest_mesh.triangles;
  fields.material_inside = finest_mesh.material_inside;
  fields.anchor_theta = 0;
  fields.branches = branch_inventory.anchor_fields;
  fields.basis_status = 'NONCANONICAL_BASIS_FOR_SUBSPACE_ONLY';
  LOCAL_atomic_save(fullfile(output_dir, 'fields.mat'), fields);
  run_state.elapsed_seconds = toc(run_state.start_clock); %#ok<NASGU>
end

function LOCAL_export_failure_fields(branch_inventory, registry, work_dir, ...
    output_dir, failure_code, failure_reason)
  reached_anchor_fields = branch_inventory.reached_anchor_fields;
  field_meshes = LOCAL_failure_field_meshes( ...
    reached_anchor_fields, registry, work_dir);
  primary_anchor_index = find(strcmp( ...
    {reached_anchor_fields.configuration}, 'fine'), 1);
  if isempty(primary_anchor_index)
    primary_anchor_index = 1;
  end
  primary_mesh_index = find(strcmp({field_meshes.mesh_id}, ...
    reached_anchor_fields(primary_anchor_index).mesh_id), 1);
  primary_mesh = field_meshes(primary_mesh_index);
  fields = struct();
  fields.artifact_status = 'UNQUALIFIED / FAILURE_ARTIFACT';
  fields.failure_code = failure_code;
  fields.failure_reason = failure_reason;
  fields.qualified_reference = false;
  fields.mesh_id = primary_mesh.mesh_id;
  fields.mesh_points = primary_mesh.points;
  fields.mesh_triangles = primary_mesh.triangles;
  fields.material_inside = primary_mesh.material_inside;
  fields.meshes = field_meshes;
  fields.anchor_theta = 0;
  fields.branches = reached_anchor_fields;
  fields.basis_status = 'NONCANONICAL_BASIS_FOR_SUBSPACE_ONLY';
  fields.claim_boundary = ['REACHED_BRANCH_ANCHORS_ONLY;UNQUALIFIED;' ...
    'NOT_A_REFERENCE_COLLECTION'];
  LOCAL_atomic_save(fullfile(output_dir, 'fields.mat'), fields);
end

function field_meshes = LOCAL_failure_field_meshes( ...
    reached_anchor_fields, registry, work_dir)
  field_meshes = struct('mesh_id', {}, 'points', {}, 'triangles', {}, ...
    'material_inside', {});
  mesh_ids = {};
  for anchor_index = 1:numel(reached_anchor_fields)
    mesh_id = reached_anchor_fields(anchor_index).mesh_id;
    if any(strcmp(mesh_ids, mesh_id))
      continue;
    end
    mesh = LOCAL_load_mesh(registry, work_dir, mesh_id);
    field_meshes(end + 1) = struct('mesh_id', mesh_id, ...
      'points', mesh.points, 'triangles', mesh.triangles, ...
      'material_inside', mesh.material_inside); %#ok<AGROW>
    mesh_ids{end + 1} = mesh_id; %#ok<AGROW>
  end
end

function LOCAL_atomic_save(path, payload)
  partial_path = [path '.partial'];
  save(partial_path, 'payload', '-v7.3');
  [moved, message] = movefile(partial_path, path, 'f');
  if ~moved
    error('I4A:AtomicWrite', 'Atomic MAT publication failed: %s', message);
  end
end

function LOCAL_write_csv(path, header, rows)
  partial_path = [path '.partial'];
  file_id = fopen(partial_path, 'w');
  if file_id < 0
    error('I4A:CsvOpen', 'Cannot open CSV partial file: %s', partial_path);
  end
  cleanup_file = onCleanup(@() LOCAL_safe_fclose(file_id)); %#ok<NASGU>
  fprintf(file_id, '%s\n', strjoin(cellfun(@LOCAL_csv_escape, header, ...
    'UniformOutput', false), ','));
  for row_index = 1:size(rows, 1)
    encoded = cell(1, size(rows, 2));
    for column_index = 1:size(rows, 2)
      encoded{column_index} = LOCAL_csv_value(rows{row_index, column_index});
    end
    fprintf(file_id, '%s\n', strjoin(encoded, ','));
  end
  LOCAL_safe_fclose(file_id);
  delete(cleanup_file);
  [moved, message] = movefile(partial_path, path, 'f');
  if ~moved
    error('I4A:AtomicWrite', 'Atomic CSV publication failed: %s', message);
  end
end

function LOCAL_safe_fclose(file_id)
  if any(fopen('all') == file_id)
    fclose(file_id);
  end
end

function encoded = LOCAL_csv_value(value)
  if isnumeric(value) || islogical(value)
    if isempty(value)
      encoded = '';
    elseif isscalar(value)
      encoded = sprintf('%.17g', double(value));
    else
      encoded = LOCAL_csv_escape(LOCAL_flat_numeric(value));
    end
  elseif isstring(value)
    encoded = LOCAL_csv_escape(char(value));
  elseif ischar(value)
    encoded = LOCAL_csv_escape(value);
  else
    encoded = LOCAL_csv_escape(class(value));
  end
end

function encoded = LOCAL_csv_escape(value)
  value = strrep(value, '"', '""');
  if any(value == ',') || any(value == '"') || any(value == newline)
    encoded = ['"' value '"'];
  else
    encoded = value;
  end
end

function LOCAL_raise(code, message)
  error('I4A:ScientificGate', '%s|%s', code, message);
end

function [code, message] = LOCAL_decode_failure(caught)
  separator = strfind(caught.message, '|');
  if strcmp(caught.identifier, 'I4A:ScientificGate') && ~isempty(separator)
    code = caught.message(1:(separator(1) - 1));
    message = caught.message((separator(1) + 1):end);
  elseif strcmp(caught.identifier, 'I4A:OutputCollision')
    code = 'OUTPUT_COLLISION';
    message = caught.message;
  else
    code = 'EXECUTION_UNAVAILABLE';
    message = caught.message;
  end
end

%% ==================== Geometry-fitted meshes ====================
% These helpers build deterministic constrained meshes and hard quality gates.

function [registry, mesh_rows, seam_rows, preflight, resource_rows] = ...
    LOCAL_preflight_audit(spec, work_dir, output_dir, ...
    elapsed_before_audit_seconds)
  audit_clock = tic;
  [registry, mesh_rows, seam_rows] = LOCAL_mesh_oracles( ...
    spec, work_dir, output_dir);
  elapsed_at_gate_seconds = elapsed_before_audit_seconds + toc(audit_clock);
  [preflight, resource_rows] = LOCAL_resource_preflight( ...
    spec, registry, work_dir, elapsed_at_gate_seconds);
end

function [registry, mesh_rows, seam_rows] = LOCAL_mesh_oracles( ...
    spec, work_dir, output_dir)
  schedule = LOCAL_mesh_schedule();
  registry = struct('id', {}, 'path', {}, 'full_nodes', {}, ...
    'reduced_dof', {}, 'triangles', {}, 'nnz_total', {});
  mesh_rows = cell(0, 21);
  seam_rows = cell(0, 12);
  for mesh_index = 1:numel(schedule)
    mesh_spec = schedule(mesh_index);
    [mesh, mesh_diagnostic] = LOCAL_build_mesh( ...
      spec, mesh_spec, mesh_rows, seam_rows, output_dir);
    mesh_rows(end + 1, :) = LOCAL_mesh_diagnostic_row( ...
      mesh_spec, mesh_diagnostic, 'MESH_COMPLETE_SEAM_PENDING', '', ''); %#ok<AGROW>
    LOCAL_checkpoint_mesh_artifacts(mesh_rows, seam_rows, output_dir);
    cache_path = fullfile(work_dir, [mesh_spec.id '.mat']);
    LOCAL_atomic_save(cache_path, mesh);
    registry(end + 1) = struct('id', mesh_spec.id, 'path', cache_path, ...
      'full_nodes', size(mesh.points, 1), ...
      'reduced_dof', mesh.reduced_dof, ...
      'triangles', size(mesh.triangles, 1), ...
      'nnz_total', nnz(mesh.stiffness_full) + nnz(mesh.mass_full)); %#ok<AGROW>
    try
      [~, phase_diag] = LOCAL_phase_reduce(spec, mesh, 0, 'mesh-oracle');
    catch caught
      [failure_code, failure_reason] = LOCAL_decode_failure(caught);
      if strcmp(failure_code, 'QUASIPERIODIC_SEAM_UNRESOLVED')
        LOCAL_checkpoint_mesh_failure(mesh_rows(1:(end - 1), :), ...
          seam_rows, mesh_spec, mesh_diagnostic, ...
          'PHASE_REDUCTION_ORACLE', failure_code, failure_reason, output_dir);
      end
      rethrow(caught);
    end
    seam_rows(end + 1, :) = LOCAL_seam_row(mesh_spec.id, ...
      'mesh-oracle', 0, phase_diag); %#ok<AGROW>
    mesh_rows{end, 19} = 'MESH_AND_SEAM_COMPLETE';
    LOCAL_checkpoint_mesh_artifacts(mesh_rows, seam_rows, output_dir);
  end
end

function [mesh, mesh_diagnostic] = LOCAL_build_mesh( ...
    spec, mesh_spec, prior_mesh_rows, prior_seam_rows, output_dir)
  mesh_diagnostic = LOCAL_initial_mesh_diagnostic(spec, mesh_spec);
  h = 1 / mesh_spec.s;
  if strcmp(mesh_spec.kind, 'bulk')
    xmin = -0.5;
    xmax = 0.5;
    disk_centers = 0;
  else
    xmin = -mesh_spec.N - 0.5;
    xmax = mesh_spec.N + 0.5;
    disk_centers = -mesh_spec.N:mesh_spec.N;
    disk_centers(disk_centers == spec.missing_column) = [];
  end
  ymin = -0.5;
  ymax = 0.5;
  x_grid = linspace(xmin, xmax, round((xmax - xmin) / h) + 1);
  y_grid = linspace(ymin, ymax, mesh_spec.s + 1);
  [grid_x, grid_y] = meshgrid(x_grid, y_grid);
  raw_points = [grid_x(:), grid_y(:)];

  remove_point = false(size(raw_points, 1), 1);
  for center_index = 1:numel(disk_centers)
    radius_from_center = hypot(raw_points(:, 1) - disk_centers(center_index), ...
      raw_points(:, 2));
    remove_point = remove_point | ...
      abs(radius_from_center - spec.radius) < h / 3;
  end
  on_outer = abs(raw_points(:, 1) - xmin) < spec.coordinate_tolerance | ...
    abs(raw_points(:, 1) - xmax) < spec.coordinate_tolerance | ...
    abs(raw_points(:, 2) - ymin) < spec.coordinate_tolerance | ...
    abs(raw_points(:, 2) - ymax) < spec.coordinate_tolerance;
  raw_points(remove_point & ~on_outer, :) = [];
  raw_constraints = zeros(0, 2);

  [raw_points, raw_constraints] = LOCAL_append_polyline(raw_points, ...
    raw_constraints, [x_grid(:), ymin * ones(numel(x_grid), 1)], false);
  [raw_points, raw_constraints] = LOCAL_append_polyline(raw_points, ...
    raw_constraints, [x_grid(:), ymax * ones(numel(x_grid), 1)], false);
  [raw_points, raw_constraints] = LOCAL_append_polyline(raw_points, ...
    raw_constraints, [xmin * ones(numel(y_grid), 1), y_grid(:)], false);
  [raw_points, raw_constraints] = LOCAL_append_polyline(raw_points, ...
    raw_constraints, [xmax * ones(numel(y_grid), 1), y_grid(:)], false);

  cell_boundaries = (ceil(xmin - 0.5):(floor(xmax - 0.5))) + 0.5;
  cell_boundaries = cell_boundaries(cell_boundaries > xmin & ...
    cell_boundaries < xmax);
  for boundary_index = 1:numel(cell_boundaries)
    line_points = [cell_boundaries(boundary_index) * ...
      ones(numel(y_grid), 1), y_grid(:)];
    [raw_points, raw_constraints] = LOCAL_append_polyline(raw_points, ...
      raw_constraints, line_points, false);
  end

  angles = (0:(mesh_spec.n_gamma - 1)).' * ...
    (2 * pi / mesh_spec.n_gamma);
  for center_index = 1:numel(disk_centers)
    center_x = disk_centers(center_index);
    polygon = [center_x + spec.radius * cos(angles), ...
      spec.radius * sin(angles)];
    inner_ring = [center_x + 0.5 * spec.radius * cos(angles), ...
      0.5 * spec.radius * sin(angles)];
    outer_ring = [center_x + (spec.radius + h / 2) * cos(angles), ...
      (spec.radius + h / 2) * sin(angles)];
    [raw_points, raw_constraints] = LOCAL_append_polyline(raw_points, ...
      raw_constraints, polygon, true);
    raw_points = [raw_points; inner_ring; outer_ring]; %#ok<AGROW>
  end

  key_scale = spec.coordinate_tolerance;
  point_keys = round(raw_points / key_scale);
  [~, first_indices, point_map] = unique(point_keys, 'rows');
  points = raw_points(first_indices, :);
  constraints = point_map(raw_constraints);
  constraints = sort(constraints, 2);
  constraints(constraints(:, 1) == constraints(:, 2), :) = [];
  constraints = unique(constraints, 'rows');

  triangulation_object = delaunayTriangulation(points, constraints);
  points = triangulation_object.Points;
  triangles = triangulation_object.ConnectivityList;
  mesh_diagnostic.full_nodes = size(points, 1);
  mesh_diagnostic.triangles = size(triangles, 1);
  mesh_diagnostic.constraints = size(constraints, 1);
  signed_twice_area = LOCAL_signed_twice_area(points, triangles);
  flipped = signed_twice_area < 0;
  triangles(flipped, [2, 3]) = triangles(flipped, [3, 2]);
  signed_twice_area = LOCAL_signed_twice_area(points, triangles);
  if any(signed_twice_area <= 0)
    failure_reason = sprintf( ...
      '%s contains inverted or zero-area triangles.', mesh_spec.id);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'SIGNED_AREA_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end

  mesh_edges = sort(edges(triangulation(triangles, points)), 2);
  missing_constraints = ~ismember(constraints, mesh_edges, 'rows');
  constraint_missing_count = nnz(missing_constraints);
  mesh_diagnostic.constraint_missing_count = constraint_missing_count;
  if constraint_missing_count > 0
    failure_reason = sprintf('%s lost %d constrained edges.', ...
      mesh_spec.id, constraint_missing_count);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'CONSTRAINT_EDGE_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end

  [minimum_angle_degrees, cross_interface_count] = ...
    LOCAL_mesh_quality(points, triangles, disk_centers, spec.radius, ...
    spec.constraint_tolerance);
  mesh_diagnostic.minimum_angle_degrees = minimum_angle_degrees;
  mesh_diagnostic.cross_interface_count = cross_interface_count;
  if minimum_angle_degrees < spec.minimum_angle_degrees || ...
      cross_interface_count > 0
    failure_reason = sprintf( ...
      '%s quality gate failed: min angle %.6g, cross-interface %d.', ...
      mesh_spec.id, minimum_angle_degrees, cross_interface_count);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'ANGLE_INTERFACE_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end

  centroids = (points(triangles(:, 1), :) + ...
    points(triangles(:, 2), :) + points(triangles(:, 3), :)) / 3;
  material_inside = false(size(triangles, 1), 1);
  for center_index = 1:numel(disk_centers)
    polygon = [disk_centers(center_index) + spec.radius * cos(angles), ...
      spec.radius * sin(angles)];
    material_inside = material_inside | inpolygon(centroids(:, 1), ...
      centroids(:, 2), polygon(:, 1), polygon(:, 2));
  end
  [stiffness_full, mass_full, mass_center, mass_core, mass_tail] = ...
    LOCAL_assemble_p1(spec, mesh_spec, points, triangles, centroids, ...
    material_inside);
  mesh_diagnostic.nnz_stiffness = nnz(stiffness_full);
  mesh_diagnostic.nnz_mass = nnz(mass_full);

  [reflection_index, reflection_coordinate_defect] = ...
    LOCAL_reflection_map(points, spec.coordinate_tolerance);
  if reflection_coordinate_defect > spec.coordinate_tolerance
    failure_reason = sprintf( ...
      '%s reflection node oracle failed.', mesh_spec.id);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'REFLECTION_NODE_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end
  node_count = size(points, 1);
  reflection = sparse((1:node_count).', reflection_index, 1, ...
    node_count, node_count);
  reflection_stiffness_defect = norm(stiffness_full - ...
    reflection' * stiffness_full * reflection, 1) / ...
    max(1, norm(stiffness_full, 1));
  reflection_mass_defect = norm(mass_full - ...
    reflection' * mass_full * reflection, 1) / max(1, norm(mass_full, 1));
  mesh_diagnostic.reflection_stiffness_defect = ...
    reflection_stiffness_defect;
  mesh_diagnostic.reflection_mass_defect = reflection_mass_defect;
  if reflection_stiffness_defect > spec.reflection_tolerance || ...
      reflection_mass_defect > spec.reflection_tolerance
    failure_reason = sprintf( ...
      '%s constrained triangulation breaks the reflection oracle.', ...
      mesh_spec.id);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'REFLECTION_MATRIX_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end

  try
    periodic = LOCAL_periodic_maps(points, xmin, xmax, ymin, ymax, ...
      spec.coordinate_tolerance);
  catch caught
    [failure_code, failure_reason] = LOCAL_decode_failure(caught);
    if strcmp(failure_code, 'QUASIPERIODIC_SEAM_UNRESOLVED')
      LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
        mesh_spec, mesh_diagnostic, 'PERIODIC_NODE_PAIRING', ...
        failure_code, failure_reason, output_dir);
    end
    rethrow(caught);
  end
  reduced_dof = max(periodic.master_index);
  mesh_diagnostic.reduced_dof = reduced_dof;
  area_deficit = mesh_diagnostic.area_deficit;
  hausdorff_defect = mesh_diagnostic.hausdorff_defect;
  if mesh_spec.n_gamma == 48 && ...
      hausdorff_defect > spec.finest_hausdorff_cap
    failure_reason = sprintf( ...
      '%s fails the finest geometry diagnostic.', mesh_spec.id);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'FINEST_GEOMETRY_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end

  mesh = struct();
  mesh.id = mesh_spec.id;
  mesh.kind = mesh_spec.kind;
  mesh.N = mesh_spec.N;
  mesh.s = mesh_spec.s;
  mesh.n_gamma = mesh_spec.n_gamma;
  mesh.xmin = xmin;
  mesh.xmax = xmax;
  mesh.ymin = ymin;
  mesh.ymax = ymax;
  mesh.points = points;
  mesh.triangles = triangles;
  mesh.constraints = constraints;
  mesh.material_inside = material_inside;
  mesh.disk_centers = disk_centers;
  mesh.stiffness_full = stiffness_full;
  mesh.mass_full = mass_full;
  mesh.mass_center = mass_center;
  mesh.mass_core = mass_core;
  mesh.mass_tail = mass_tail;
  mesh.reflection_index = reflection_index;
  mesh.periodic = periodic;
  mesh.reduced_dof = reduced_dof;
  mesh.minimum_angle_degrees = minimum_angle_degrees;
  mesh.area_deficit = area_deficit;
  mesh.hausdorff_defect = hausdorff_defect;
  mesh.constraint_missing_count = constraint_missing_count;
  mesh.cross_interface_count = cross_interface_count;
  mesh.reflection_stiffness_defect = reflection_stiffness_defect;
  mesh.reflection_mass_defect = reflection_mass_defect;
end

function mesh_diagnostic = LOCAL_initial_mesh_diagnostic(spec, mesh_spec)
  mesh_diagnostic = struct();
  mesh_diagnostic.full_nodes = NaN;
  mesh_diagnostic.reduced_dof = NaN;
  mesh_diagnostic.triangles = NaN;
  mesh_diagnostic.constraints = NaN;
  mesh_diagnostic.minimum_angle_degrees = NaN;
  mesh_diagnostic.area_deficit = 1 - mesh_spec.n_gamma * ...
    sin(2 * pi / mesh_spec.n_gamma) / (2 * pi);
  mesh_diagnostic.hausdorff_defect = spec.radius * ...
    (1 - cos(pi / mesh_spec.n_gamma));
  mesh_diagnostic.constraint_missing_count = NaN;
  mesh_diagnostic.cross_interface_count = NaN;
  mesh_diagnostic.nnz_stiffness = NaN;
  mesh_diagnostic.nnz_mass = NaN;
  mesh_diagnostic.reflection_stiffness_defect = NaN;
  mesh_diagnostic.reflection_mass_defect = NaN;
end

function row = LOCAL_mesh_diagnostic_row(mesh_spec, mesh_diagnostic, ...
    reached_boundary, failure_code, failure_reason)
  row = {mesh_spec.id, mesh_spec.kind, mesh_spec.N, mesh_spec.s, ...
    mesh_spec.n_gamma, mesh_diagnostic.full_nodes, ...
    mesh_diagnostic.reduced_dof, mesh_diagnostic.triangles, ...
    mesh_diagnostic.constraints, mesh_diagnostic.minimum_angle_degrees, ...
    mesh_diagnostic.area_deficit, mesh_diagnostic.hausdorff_defect, ...
    mesh_diagnostic.constraint_missing_count, ...
    mesh_diagnostic.cross_interface_count, mesh_diagnostic.nnz_stiffness, ...
    mesh_diagnostic.nnz_mass, ...
    mesh_diagnostic.reflection_stiffness_defect, ...
    mesh_diagnostic.reflection_mass_defect, reached_boundary, ...
    failure_code, failure_reason};
end

function LOCAL_checkpoint_mesh_failure(prior_mesh_rows, seam_rows, ...
    mesh_spec, mesh_diagnostic, reached_boundary, failure_code, ...
    failure_reason, output_dir)
  failure_mesh_rows = prior_mesh_rows;
  if ~isempty(failure_mesh_rows)
    failure_mesh_rows(:, 20) = {failure_code};
    failure_mesh_rows(:, 21) = {failure_reason};
  end
  failure_mesh_rows(end + 1, :) = LOCAL_mesh_diagnostic_row( ...
    mesh_spec, mesh_diagnostic, reached_boundary, failure_code, ...
    failure_reason);
  LOCAL_checkpoint_mesh_artifacts(failure_mesh_rows, seam_rows, output_dir);
end

function LOCAL_checkpoint_mesh_artifacts(mesh_rows, seam_rows, output_dir)
  checkpoint_artifacts = struct();
  checkpoint_artifacts.mesh_rows = mesh_rows;
  checkpoint_artifacts.seam_rows = seam_rows;
  LOCAL_write_mesh_artifacts(checkpoint_artifacts, output_dir);
end

function [raw_points, raw_constraints] = LOCAL_append_polyline( ...
    raw_points, raw_constraints, polyline, close_loop)
  first = size(raw_points, 1) + 1;
  raw_points = [raw_points; polyline]; %#ok<AGROW>
  indices = (first:(first + size(polyline, 1) - 1)).';
  raw_constraints = [raw_constraints; indices(1:(end - 1)), ...
    indices(2:end)]; %#ok<AGROW>
  if close_loop
    raw_constraints(end + 1, :) = [indices(end), indices(1)];
  end
end

function signed_twice_area = LOCAL_signed_twice_area(points, triangles)
  first = points(triangles(:, 1), :);
  second = points(triangles(:, 2), :);
  third = points(triangles(:, 3), :);
  signed_twice_area = (second(:, 1) - first(:, 1)) .* ...
    (third(:, 2) - first(:, 2)) - ...
    (second(:, 2) - first(:, 2)) .* ...
    (third(:, 1) - first(:, 1));
end

function [minimum_angle_degrees, cross_interface_count] = ...
    LOCAL_mesh_quality(points, triangles, disk_centers, radius, tolerance)
  first = points(triangles(:, 1), :);
  second = points(triangles(:, 2), :);
  third = points(triangles(:, 3), :);
  side_a = hypot(second(:, 1) - third(:, 1), ...
    second(:, 2) - third(:, 2));
  side_b = hypot(first(:, 1) - third(:, 1), ...
    first(:, 2) - third(:, 2));
  side_c = hypot(first(:, 1) - second(:, 1), ...
    first(:, 2) - second(:, 2));
  angle_a = acosd(LOCAL_clip((side_b .^ 2 + side_c .^ 2 - ...
    side_a .^ 2) ./ (2 .* side_b .* side_c), -1, 1));
  angle_b = acosd(LOCAL_clip((side_a .^ 2 + side_c .^ 2 - ...
    side_b .^ 2) ./ (2 .* side_a .* side_c), -1, 1));
  angle_c = 180 - angle_a - angle_b;
  minimum_angle_degrees = min([angle_a; angle_b; angle_c]);

  cross_interface = false(size(triangles, 1), 1);
  for center_index = 1:numel(disk_centers)
    radii = zeros(size(triangles, 1), 3);
    for vertex_index = 1:3
      vertex = points(triangles(:, vertex_index), :);
      radii(:, vertex_index) = hypot(vertex(:, 1) - ...
        disk_centers(center_index), vertex(:, 2));
    end
    has_inside = any(radii < radius - tolerance, 2);
    has_outside = any(radii > radius + tolerance, 2);
    cross_interface = cross_interface | (has_inside & has_outside);
  end
  cross_interface_count = nnz(cross_interface);
end

function clipped = LOCAL_clip(value, lower_bound, upper_bound)
  clipped = min(max(value, lower_bound), upper_bound);
end

function [stiffness_full, mass_full, mass_center, mass_core, mass_tail] = ...
    LOCAL_assemble_p1(spec, mesh_spec, points, triangles, centroids, ...
    material_inside)
  triangle_count = size(triangles, 1);
  row_indices = zeros(9 * triangle_count, 1);
  column_indices = zeros(9 * triangle_count, 1);
  stiffness_values = zeros(9 * triangle_count, 1);
  mass_values = zeros(9 * triangle_count, 1);
  center_values = zeros(9 * triangle_count, 1);
  core_values = zeros(9 * triangle_count, 1);
  tail_values = zeros(9 * triangle_count, 1);
  unit_mass = [2, 1, 1; 1, 2, 1; 1, 1, 2] / 12;
  for triangle_index = 1:triangle_count
    nodes = triangles(triangle_index, :);
    coordinates = points(nodes, :);
    twice_area = det([coordinates(2, :) - coordinates(1, :); ...
      coordinates(3, :) - coordinates(1, :)]);
    area = abs(twice_area) / 2;
    gradient_x = [coordinates(2, 2) - coordinates(3, 2); ...
      coordinates(3, 2) - coordinates(1, 2); ...
      coordinates(1, 2) - coordinates(2, 2)] / twice_area;
    gradient_y = [coordinates(3, 1) - coordinates(2, 1); ...
      coordinates(1, 1) - coordinates(3, 1); ...
      coordinates(2, 1) - coordinates(1, 1)] / twice_area;
    local_stiffness = area * (gradient_x * gradient_x' + ...
      gradient_y * gradient_y');
    coefficient = spec.q_outside + ...
      (spec.q_inside - spec.q_outside) * material_inside(triangle_index);
    local_mass = coefficient * area * unit_mass;
    block = (9 * (triangle_index - 1) + 1):(9 * triangle_index);
    [local_rows, local_columns] = ndgrid(nodes, nodes);
    row_indices(block) = local_rows(:);
    column_indices(block) = local_columns(:);
    stiffness_values(block) = local_stiffness(:);
    mass_values(block) = local_mass(:);
    center_values(block) = local_mass(:) * ...
      (abs(centroids(triangle_index, 1)) < 0.5);
    core_values(block) = local_mass(:) * ...
      (abs(centroids(triangle_index, 1)) < 1.5);
    if strcmp(mesh_spec.kind, 'defect')
      tail_boundary = mesh_spec.N - 1.5;
      tail_values(block) = local_mass(:) * ...
        (abs(centroids(triangle_index, 1)) > tail_boundary);
    end
  end
  node_count = size(points, 1);
  stiffness_full = sparse(row_indices, column_indices, stiffness_values, ...
    node_count, node_count);
  mass_full = sparse(row_indices, column_indices, mass_values, ...
    node_count, node_count);
  mass_center = sparse(row_indices, column_indices, center_values, ...
    node_count, node_count);
  mass_core = sparse(row_indices, column_indices, core_values, ...
    node_count, node_count);
  mass_tail = sparse(row_indices, column_indices, tail_values, ...
    node_count, node_count);
end

function [reflection_index, coordinate_defect] = ...
    LOCAL_reflection_map(points, tolerance)
  point_keys = round(points / tolerance);
  reflected_keys = round([-points(:, 1), points(:, 2)] / tolerance);
  [found, reflection_index] = ismember(reflected_keys, point_keys, 'rows');
  if any(~found)
    coordinate_defect = Inf;
    return;
  end
  reflected_points = [-points(:, 1), points(:, 2)];
  coordinate_defect = max(abs(points(reflection_index, :) - ...
    reflected_points), [], 'all');
end

function periodic = LOCAL_periodic_maps(points, xmin, xmax, ymin, ymax, tolerance)
  on_left = abs(points(:, 1) - xmin) <= tolerance;
  on_right = abs(points(:, 1) - xmax) <= tolerance;
  on_bottom = abs(points(:, 2) - ymin) <= tolerance;
  on_top = abs(points(:, 2) - ymax) <= tolerance;
  left_nodes = find(on_left);
  right_nodes = find(on_right);
  bottom_nodes = find(on_bottom);
  top_nodes = find(on_top);
  [left_y, left_order] = sort(points(left_nodes, 2));
  left_nodes = left_nodes(left_order);
  [right_y, right_order] = sort(points(right_nodes, 2));
  right_nodes = right_nodes(right_order);
  [bottom_x, bottom_order] = sort(points(bottom_nodes, 1));
  bottom_nodes = bottom_nodes(bottom_order);
  [top_x, top_order] = sort(points(top_nodes, 1));
  top_nodes = top_nodes(top_order);
  if numel(left_nodes) ~= numel(right_nodes) || ...
      numel(bottom_nodes) ~= numel(top_nodes)
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', ...
      'Periodic boundary node pairing failed.');
  end
  coordinate_mismatch = max([max(abs(left_y - right_y)), ...
    max(abs(bottom_x - top_x))]);
  if coordinate_mismatch > tolerance
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', ...
      'Periodic boundary coordinate pairing failed.');
  end
  canonical = points;
  canonical(right_nodes, 1) = xmin;
  canonical(top_nodes, 2) = ymin;
  point_keys = round(points / tolerance);
  canonical_keys = round(canonical / tolerance);
  [found, canonical_node] = ismember(canonical_keys, point_keys, 'rows');
  if any(~found)
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', ...
      'A periodic slave has no master node.');
  end
  [~, ~, master_index] = unique(canonical_node);
  periodic = struct();
  periodic.left_nodes = left_nodes;
  periodic.right_nodes = right_nodes;
  periodic.bottom_nodes = bottom_nodes;
  periodic.top_nodes = top_nodes;
  periodic.x_slave = on_right;
  periodic.y_slave = on_top;
  periodic.master_index = master_index;
  periodic.coordinate_mismatch = coordinate_mismatch;
  periodic.corner_count = nnz((on_left | on_right) & (on_bottom | on_top));
end

function [reduced, diagnostic] = LOCAL_phase_reduce(spec, mesh, phase_x, phase_kind)
  phases = exp(1i * (phase_x * double(mesh.periodic.x_slave) + ...
    spec.beta * double(mesh.periodic.y_slave)));
  node_count = size(mesh.points, 1);
  reduced_dof = max(mesh.periodic.master_index);
  phase_prolongation = sparse((1:node_count).', ...
    mesh.periodic.master_index, phases, node_count, reduced_dof);
  stiffness_reduced = phase_prolongation' * mesh.stiffness_full * ...
    phase_prolongation;
  mass_reduced = phase_prolongation' * mesh.mass_full * ...
    phase_prolongation;
  x_residual = norm(phase_prolongation(mesh.periodic.right_nodes, :) - ...
    exp(1i * phase_x) * phase_prolongation(mesh.periodic.left_nodes, :), inf);
  y_residual = norm(phase_prolongation(mesh.periodic.top_nodes, :) - ...
    exp(1i * spec.beta) * phase_prolongation(mesh.periodic.bottom_nodes, :), inf);
  seam_residual = max(x_residual, y_residual);
  stiffness_defect = norm(stiffness_reduced - stiffness_reduced', 1) / ...
    max(1, norm(stiffness_reduced, 1));
  mass_defect = norm(mass_reduced - mass_reduced', 1) / ...
    max(1, norm(mass_reduced, 1));
  if mesh.periodic.coordinate_mismatch > spec.coordinate_tolerance || ...
      seam_residual > spec.seam_tolerance
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', sprintf( ...
      '%s phase %.17g fails seam identities.', mesh.id, phase_x));
  end
  if stiffness_defect > spec.hermitian_tolerance || ...
      mass_defect > spec.hermitian_tolerance
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', sprintf( ...
      '%s phase %.17g fails Hermitian reduction.', mesh.id, phase_x));
  end
  reduced = struct('stiffness', stiffness_reduced, 'mass', mass_reduced, ...
    'prolongation', phase_prolongation);
  diagnostic = struct('phase_kind', phase_kind, 'phase', phase_x, ...
    'x_pairs', numel(mesh.periodic.left_nodes), ...
    'y_pairs', numel(mesh.periodic.bottom_nodes), ...
    'corner_pairs', mesh.periodic.corner_count, ...
    'coordinate_mismatch', mesh.periodic.coordinate_mismatch, ...
    'seam_residual', seam_residual, ...
    'corner_factor', exp(1i * (spec.beta + phase_x)), ...
    'stiffness_defect', stiffness_defect, 'mass_defect', mass_defect);
end

function row = LOCAL_seam_row(mesh_id, phase_kind, phase, diagnostic)
  row = {mesh_id, phase_kind, phase, diagnostic.x_pairs, ...
    diagnostic.y_pairs, diagnostic.corner_pairs, ...
    diagnostic.coordinate_mismatch, diagnostic.seam_residual, ...
    real(diagnostic.corner_factor), imag(diagnostic.corner_factor), ...
    diagnostic.stiffness_defect, diagnostic.mass_defect};
end

function mesh = LOCAL_load_mesh(registry, work_dir, mesh_id) %#ok<INUSD>
  matches = find(strcmp({registry.id}, mesh_id));
  if numel(matches) ~= 1
    error('I4A:MeshRegistry', 'Mesh registry lookup failed for %s.', mesh_id);
  end
  loaded = load(registry(matches).path, 'payload');
  mesh = loaded.payload;
end

function [preflight, rows] = LOCAL_resource_preflight( ...
    spec, registry, work_dir, elapsed_at_gate_seconds)
  runtime_safety_factor = 1.25;
  bytes_per_complex = 16;
  bytes_per_sparse_entry = 24;
  runtime_baseline_bytes = 0.35 * 1024 ^ 3;
  csv_buffer_bytes = 8 * 1024 ^ 2;
  schedule = LOCAL_defect_schedule(spec);
  rows = cell(0, 10);
  mesh_details = struct('id', {}, 'reduced_dof', {}, 'reduced_nnz', {}, ...
    'symbolic_factor_nnz', {}, 'workspace_40_bytes', {}, ...
    'workspace_48_bytes', {}, 'cache_bytes', {});
  max_peak_bytes = 0;
  total_mesh_cache_bytes = 0;
  max_dof = 0;
  max_nnz = 0;
  max_symbolic_factor_nnz = 0;
  for mesh_index = 1:numel(registry)
    mesh = LOCAL_load_mesh(registry, work_dir, registry(mesh_index).id);
    [reduced, ~] = LOCAL_phase_reduce(spec, mesh, 0, 'resource-preflight');
    reduced_nnz = nnz(reduced.stiffness) + nnz(reduced.mass);
    symbolic_pattern = spones(reduced.stiffness) + ...
      spones(reduced.mass) + speye(size(reduced.stiffness, 1));
    symbolic_counts = symbfact(symbolic_pattern);
    symbolic_factor_nnz = sum(symbolic_counts);
    file_record = dir(registry(mesh_index).path);
    cache_bytes = file_record.bytes;
    workspace_40_bytes = LOCAL_workspace_bytes(size(reduced.stiffness, 1), ...
      size(mesh.points, 1), reduced_nnz, symbolic_factor_nnz, 40, 80, ...
      bytes_per_complex, bytes_per_sparse_entry);
    workspace_48_bytes = LOCAL_workspace_bytes(size(reduced.stiffness, 1), ...
      size(mesh.points, 1), reduced_nnz, symbolic_factor_nnz, 48, 96, ...
      bytes_per_complex, bytes_per_sparse_entry);
    mesh_details(end + 1) = struct('id', registry(mesh_index).id, ...
      'reduced_dof', size(reduced.stiffness, 1), ...
      'reduced_nnz', reduced_nnz, ...
      'symbolic_factor_nnz', symbolic_factor_nnz, ...
      'workspace_40_bytes', workspace_40_bytes, ...
      'workspace_48_bytes', workspace_48_bytes, ...
      'cache_bytes', cache_bytes); %#ok<AGROW>
    mesh_peak = max(workspace_40_bytes, workspace_48_bytes) + ...
      cache_bytes + runtime_baseline_bytes + csv_buffer_bytes;
    max_peak_bytes = max(max_peak_bytes, mesh_peak);
    total_mesh_cache_bytes = total_mesh_cache_bytes + cache_bytes;
    max_dof = max(max_dof, size(reduced.stiffness, 1));
    max_nnz = max(max_nnz, reduced_nnz);
    max_symbolic_factor_nnz = max(max_symbolic_factor_nnz, ...
      symbolic_factor_nnz);
    rows(end + 1, :) = {registry(mesh_index).id, 'mesh-symbolic', 0, ...
      0, 1, runtime_safety_factor, 0, mesh_peak, cache_bytes, ...
      sprintf('dof=%d;reduced_nnz=%d;symbolic_factor_nnz=%d;ws40=%d;ws48=%d', ...
      size(reduced.stiffness, 1), reduced_nnz, symbolic_factor_nnz, ...
      round(workspace_40_bytes), round(workspace_48_bytes))}; %#ok<AGROW>
  end

  defect_cache_bytes = 0;
  for solve_index = 1:numel(schedule)
    mesh_index = find(strcmp({registry.id}, schedule(solve_index).mesh_id), 1);
    defect_cache_bytes = defect_cache_bytes + bytes_per_complex * ...
      registry(mesh_index).full_nodes * schedule(solve_index).nev;
  end
  bulk_cache_bytes = spec.planned_bulk_solves * 48 * 8 * 6;
  export_buffer_bytes = bytes_per_complex * ...
    max([registry.full_nodes]) * spec.count_nev + 64 * 1024 ^ 2;
  cache_and_export_bytes = total_mesh_cache_bytes + defect_cache_bytes + ...
    bulk_cache_bytes + export_buffer_bytes;
  branch_peak_bytes = total_mesh_cache_bytes + export_buffer_bytes + ...
    runtime_baseline_bytes + csv_buffer_bytes;
  max_peak_bytes = max(max_peak_bytes, branch_peak_bytes);
  estimated_peak_bytes = max(runtime_safety_factor * max_peak_bytes, ...
    spec.design_peak_estimate_gib * 1024 ^ 3);

  fine_mesh = mesh_details(strcmp({mesh_details.id}, 'defect-N5-s24-g48'));
  medium_mesh = mesh_details(strcmp({mesh_details.id}, 'defect-N5-s18-g36'));
  bulk_mesh = mesh_details(strcmp({mesh_details.id}, 'bulk-s24-g48'));
  fine_scale = max(1, (fine_mesh.reduced_dof / 9000) ^ 1.5);
  medium_scale = max(1, (medium_mesh.reduced_dof / 7000) ^ 1.5);
  bulk_scale = max(1, (bulk_mesh.reduced_dof / 900) ^ 1.5);
  bulk_main_seconds = 67 * 1.2 * runtime_safety_factor * bulk_scale;
  bulk_count_seconds = 5 * 1.2 * runtime_safety_factor * bulk_scale;
  defect_medium_seconds = 20 * 12 * runtime_safety_factor * medium_scale;
  defect_fine_seconds = 27 * 28 * runtime_safety_factor * fine_scale;
  postprocess_seconds = 240 * runtime_safety_factor;
  remaining_seconds = bulk_main_seconds + bulk_count_seconds + ...
    defect_medium_seconds + defect_fine_seconds + postprocess_seconds;
  forecast_seconds = elapsed_at_gate_seconds + remaining_seconds;
  forecast_seconds = max(forecast_seconds, ...
    spec.design_wall_estimate_minutes * 60);
  rows(end + 1, :) = {'environment-mesh-audit', 'elapsed-preflight', 0, ...
    0, 1, 1, elapsed_at_gate_seconds, max_peak_bytes, ...
    total_mesh_cache_bytes, 'same-command elapsed; never resets'}; %#ok<AGROW>
  rows(end + 1, :) = {'bulk-main', 'eigensolve', 67, 1.2, bulk_scale, ...
    runtime_safety_factor, bulk_main_seconds, ...
    max([mesh_details.workspace_40_bytes]), bulk_cache_bytes, ...
    'B1=17;B2=17;B4=33;B3 is alias only'}; %#ok<AGROW>
  rows(end + 1, :) = {'bulk-count', 'eigensolve', 5, 1.2, bulk_scale, ...
    runtime_safety_factor, bulk_count_seconds, ...
    max([mesh_details.workspace_48_bytes]), bulk_cache_bytes, ...
    'five fixed 48-root sentinels'}; %#ok<AGROW>
  rows(end + 1, :) = {'defect-medium', 'eigensolve', 20, 12, ...
    medium_scale, runtime_safety_factor, defect_medium_seconds, ...
    medium_mesh.workspace_40_bytes, defect_cache_bytes, ...
    'N5-s12,N5-s18,N3-s18,N4-s18;five phases each'}; %#ok<AGROW>
  rows(end + 1, :) = {'defect-fine-corner-count', 'eigensolve', 27, ...
    28, fine_scale, runtime_safety_factor, defect_fine_seconds, ...
    max(fine_mesh.workspace_40_bytes, fine_mesh.workspace_48_bytes), ...
    defect_cache_bytes, 'N5-s24=17;N4-s24=5;loose-count=5'}; %#ok<AGROW>
  rows(end + 1, :) = {'branch-cache-csv-mat-export', 'postprocess', 0, ...
    240, 1, runtime_safety_factor, postprocess_seconds, ...
    branch_peak_bytes, cache_and_export_bytes, ...
    'current-run caches plus CSV/MAT buffers and atomic export'}; %#ok<AGROW>
  rows(end + 1, :) = {'TOTAL', 'complete-command', spec.planned_solves, ...
    0, 1, runtime_safety_factor, forecast_seconds, ...
    estimated_peak_bytes, cache_and_export_bytes, ...
    '72 bulk + 47 defect; includes elapsed preflight and all exports'}; %#ok<AGROW>

  preflight = struct();
  preflight.elapsed_at_gate_seconds = elapsed_at_gate_seconds;
  preflight.runtime_safety_factor = runtime_safety_factor;
  preflight.mesh_details = mesh_details;
  preflight.max_reduced_dof = max_dof;
  preflight.max_reduced_nnz = max_nnz;
  preflight.max_symbolic_factor_nnz = max_symbolic_factor_nnz;
  preflight.workspace_40_peak_bytes = max([mesh_details.workspace_40_bytes]);
  preflight.workspace_48_peak_bytes = max([mesh_details.workspace_48_bytes]);
  preflight.total_mesh_cache_bytes = total_mesh_cache_bytes;
  preflight.estimated_defect_cache_bytes = defect_cache_bytes;
  preflight.estimated_export_buffer_bytes = export_buffer_bytes;
  preflight.wall_estimate_minutes = forecast_seconds / 60;
  preflight.peak_estimate_gib = estimated_peak_bytes / 1024 ^ 3;
  preflight.planned_bulk_solves = spec.planned_bulk_solves;
  preflight.planned_defect_solves = spec.planned_defect_solves;
  preflight.planned_solves = spec.planned_solves;
  preflight.pass = max_dof <= spec.dof_cap && max_nnz <= spec.nnz_cap && ...
    preflight.wall_estimate_minutes <= spec.soft_wall_minutes && ...
    preflight.peak_estimate_gib <= spec.preflight_peak_cap_gib;
  preflight.reason = sprintf(['pre-eigensolve audit: DOF %d, reduced nnz %d, ' ...
    'symbolic factor nnz %d, wall %.6g min, peak %.6g GiB, solves %d'], ...
    max_dof, max_nnz, max_symbolic_factor_nnz, ...
    preflight.wall_estimate_minutes, preflight.peak_estimate_gib, ...
    preflight.planned_solves);
end

function bytes = LOCAL_workspace_bytes(reduced_dof, full_nodes, reduced_nnz, ...
    symbolic_factor_nnz, nev, subspace_size, bytes_per_complex, ...
    bytes_per_sparse_entry)
  sparse_pair_bytes = bytes_per_sparse_entry * reduced_nnz;
  symbolic_factor_bytes = bytes_per_sparse_entry * symbolic_factor_nnz;
  krylov_bytes = bytes_per_complex * reduced_dof * ...
    (subspace_size + 2 * nev + 12);
  full_vector_bytes = bytes_per_complex * full_nodes * nev;
  bytes = sparse_pair_bytes + symbolic_factor_bytes + ...
    krylov_bytes + full_vector_bytes;
end

%% ==================== Generalized low-spectrum solver ====================
% These helpers enforce complete-return, residual, multiplicity, and sentinels.

function [spectrum, phase_diagnostic] = LOCAL_low_spectrum( ...
    spec, mesh, phase_x, tolerance, requested_nev, role, bounds)
  [reduced, phase_diagnostic] = LOCAL_phase_reduce( ...
    spec, mesh, phase_x, role);
  reduced_dof = size(reduced.stiffness, 1);
  if reduced_dof <= requested_nev + 2
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s has only %d reduced DOF for %d requested roots.', ...
      mesh.id, reduced_dof, requested_nev));
  end
  [~, chol_flag] = chol(reduced.mass);
  if chol_flag ~= 0
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      sprintf('%s reduced mass is not positive definite.', mesh.id));
  end

  master_rows = accumarray(mesh.periodic.master_index, ...
    (1:size(mesh.points, 1)).', [], @min);
  master_points = mesh.points(master_rows, :);
  start_vector = exp(1i * (0.371 * master_points(:, 1) + ...
    0.233 * master_points(:, 2))) + ...
    0.17 * cos(1.113 * master_points(:, 1) - ...
    0.719 * master_points(:, 2));
  start_vector = start_vector / norm(start_vector, 2);
  options = struct();
  options.tol = tolerance;
  options.maxit = spec.eigs_maxit;
  options.p = min(reduced_dof - 1, max(2 * requested_nev, ...
    spec.eigs_subspace_main));
  options.p = min(options.p, spec.eigs_subspace_cap);
  options.v0 = start_vector;
  options.issym = true;
  options.isreal = false;
  rng(spec.random_seed, 'twister');
  [vectors_reduced, diagonal_values, solver_flag] = eigs( ...
    reduced.stiffness, reduced.mass, requested_nev, ...
    'smallestabs', options);
  eigenvalues_complex = diag(diagonal_values);
  if solver_flag ~= 0 || size(vectors_reduced, 2) ~= requested_nev || ...
      numel(eigenvalues_complex) ~= requested_nev
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g returned flag %d and %d/%d roots.', mesh.id, ...
      phase_x, solver_flag, numel(eigenvalues_complex), requested_nev));
  end
  if any(~isfinite(eigenvalues_complex)) || ...
      any(~isfinite(vectors_reduced), 'all')
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      sprintf('%s phase %.17g returned nonfinite objects.', mesh.id, phase_x));
  end
  relative_imaginary = abs(imag(eigenvalues_complex)) ./ ...
    max(1, abs(real(eigenvalues_complex)));
  if any(relative_imaginary > spec.imaginary_tolerance) || ...
      any(real(eigenvalues_complex) <= 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      sprintf('%s phase %.17g returned nonpositive/nonreal roots.', ...
      mesh.id, phase_x));
  end
  [eigenvalues, order] = sort(real(eigenvalues_complex), 'ascend');
  vectors_reduced = vectors_reduced(:, order);
  for root_index = 1:requested_nev
    mass_norm = real(vectors_reduced(:, root_index)' * reduced.mass * ...
      vectors_reduced(:, root_index));
    if ~isfinite(mass_norm) || mass_norm <= 0
      LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
        sprintf('%s phase %.17g has invalid mass norm.', mesh.id, phase_x));
    end
    vectors_reduced(:, root_index) = vectors_reduced(:, root_index) / ...
      sqrt(mass_norm);
  end
  orthogonality_defect = norm(vectors_reduced' * reduced.mass * ...
    vectors_reduced - eye(requested_nev), 2);
  if orthogonality_defect > spec.orthogonality_tolerance
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g M-orthogonality defect %.17g.', ...
      mesh.id, phase_x, orthogonality_defect));
  end

  stiffness_norm = norm(reduced.stiffness, 1);
  mass_norm = norm(reduced.mass, 1);
  residuals = zeros(requested_nev, 1);
  for root_index = 1:requested_nev
    vector = vectors_reduced(:, root_index);
    residuals(root_index) = norm(reduced.stiffness * vector - ...
      eigenvalues(root_index) * reduced.mass * vector, 2) / ...
      ((stiffness_norm + abs(eigenvalues(root_index)) * mass_norm) * ...
      norm(vector, 2));
  end
  if any(residuals > spec.residual_tolerance)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g has algebraic residual %.17g.', ...
      mesh.id, phase_x, max(residuals)));
  end
  frequencies = sqrt(eigenvalues);
  if any(diff(frequencies) < 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'Ordered frequency gate failed.');
  end
  if isfield(bounds, 'upper_required') && ...
      frequencies(end) <= bounds.upper_required
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g upper sentinel %.17g <= %.17g.', ...
      mesh.id, phase_x, frequencies(end), bounds.upper_required));
  end
  if isfield(bounds, 'lower_required') && ...
      frequencies(1) >= bounds.lower_required
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g lower sentinel %.17g >= %.17g.', ...
      mesh.id, phase_x, frequencies(1), bounds.lower_required));
  end

  cluster_ids = LOCAL_cluster_ids(spec, frequencies, residuals);
  multiplicities = accumarray(cluster_ids, 1);
  if sum(multiplicities) ~= requested_nev
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'Cluster multiplicities do not sum to the requested count.');
  end
  vectors_full = reduced.prolongation * vectors_reduced;
  spectrum = struct();
  spectrum.mesh_id = mesh.id;
  spectrum.phase = phase_x;
  spectrum.role = role;
  spectrum.requested_nev = requested_nev;
  spectrum.solver_flag = solver_flag;
  spectrum.eigenvalues = eigenvalues;
  spectrum.frequencies = frequencies;
  spectrum.residuals = residuals;
  spectrum.cluster_ids = cluster_ids;
  spectrum.cluster_multiplicities = multiplicities;
  spectrum.vectors_full = vectors_full;
  spectrum.orthogonality_defect = orthogonality_defect;
end

function cluster_ids = LOCAL_cluster_ids(spec, frequencies, residuals)
  cluster_ids = ones(numel(frequencies), 1);
  next_cluster = 1;
  for root_index = 2:numel(frequencies)
    residual_scale = spec.cluster_residual_factor * ...
      max(residuals((root_index - 1):root_index)) * ...
      max(1, frequencies(root_index));
    threshold = max(spec.cluster_frequency_tolerance, residual_scale);
    if frequencies(root_index) - frequencies(root_index - 1) > threshold
      next_cluster = next_cluster + 1;
    end
    cluster_ids(root_index) = next_cluster;
  end
end

function run_state = LOCAL_after_solve(spec, run_state, output_dir, note)
  run_state.completed_solves = run_state.completed_solves + 1;
  elapsed_seconds = toc(run_state.start_clock);
  remaining = run_state.planned_solves - run_state.completed_solves;
  eta_seconds = elapsed_seconds / run_state.completed_solves * remaining;
  run_state = LOCAL_progress(run_state, output_dir, note, eta_seconds);
  if elapsed_seconds > spec.hard_wall_minutes * 60
    LOCAL_raise('RESOURCE_BUDGET_UNAVAILABLE', ...
      'The shared command reached the 40-minute hard wall limit.');
  end
  if elapsed_seconds > spec.soft_wall_minutes * 60
    fraction_complete = run_state.completed_solves / run_state.planned_solves;
    if fraction_complete < 0.90 || eta_seconds > 10 * 60
      LOCAL_raise('RESOURCE_BUDGET_UNAVAILABLE', ...
        'The 30-minute gate failed without objective imminent-completion evidence.');
    end
  end
end

function LOCAL_save_spectrum(path, spectrum)
  LOCAL_atomic_save(path, spectrum);
end

function spectrum = LOCAL_load_spectrum(path)
  loaded = load(path, 'payload');
  spectrum = loaded.payload;
end

%% ==================== Independent bulk inventory ====================
% These helpers compute 67 main and five fixed count-sentinel bulk solves.

function [bulk_inventory, run_state, artifacts] = LOCAL_bulk_inventory( ...
    spec, registry, work_dir, output_dir, run_state, artifacts)
  levels = struct('id', {}, 'mesh_id', {}, 'alphas', {}, 'tol', {});
  levels(1) = struct('id', 'B1', 'mesh_id', 'bulk-s12-g24', ...
    'alphas', spec.bulk_alpha_17, 'tol', 1e-9);
  levels(2) = struct('id', 'B2', 'mesh_id', 'bulk-s18-g36', ...
    'alphas', spec.bulk_alpha_17, 'tol', 1e-10);
  levels(3) = struct('id', 'B4', 'mesh_id', 'bulk-s24-g48', ...
    'alphas', spec.bulk_alpha_33, 'tol', 1e-11);
  bulk_inventory = struct();
  bulk_inventory.levels = struct();
  bounds = struct('upper_required', spec.guard_interval(2));
  for level_index = 1:numel(levels)
    level = levels(level_index);
    mesh = LOCAL_load_mesh(registry, work_dir, level.mesh_id);
    frequency_matrix = zeros(spec.bulk_main_nev, numel(level.alphas));
    residual_matrix = zeros(spec.bulk_main_nev, numel(level.alphas));
    paths = cell(1, numel(level.alphas));
    for phase_index = 1:numel(level.alphas)
      solve_id = sprintf('%s-p%02d', level.id, phase_index);
      [spectrum, phase_diagnostic] = LOCAL_low_spectrum(spec, mesh, ...
        level.alphas(phase_index), level.tol, spec.bulk_main_nev, ...
        'bulk-main', bounds);
      frequency_matrix(:, phase_index) = spectrum.frequencies;
      residual_matrix(:, phase_index) = spectrum.residuals;
      paths{phase_index} = fullfile(work_dir, [solve_id '.mat']);
      spectrum.vectors_full = [];
      LOCAL_save_spectrum(paths{phase_index}, spectrum);
      artifacts.seam_rows(end + 1, :) = LOCAL_seam_row(mesh.id, ...
        'bulk-main', level.alphas(phase_index), phase_diagnostic); %#ok<AGROW>
      artifacts.bulk_rows = LOCAL_append_bulk_rows(artifacts.bulk_rows, ...
        level.id, solve_id, level.alphas(phase_index), spectrum, 'main');
      LOCAL_write_bulk_artifacts(artifacts, output_dir);
      LOCAL_write_mesh_artifacts(artifacts, output_dir);
      run_state = LOCAL_after_solve(spec, run_state, output_dir, solve_id);
    end
    bulk_inventory.levels.(level.id) = struct('mesh_id', level.mesh_id, ...
      'alphas', level.alphas, 'frequencies', frequency_matrix, ...
      'residuals', residual_matrix, 'paths', {paths});
  end
  b4 = bulk_inventory.levels.B4;
  bulk_inventory.levels.B3 = struct('mesh_id', b4.mesh_id, ...
    'alphas', b4.alphas(1:2:end), ...
    'frequencies', b4.frequencies(:, 1:2:end), ...
    'residuals', b4.residuals(:, 1:2:end), ...
    'paths', {b4.paths(1:2:end)});
  for alias_index = 1:numel(bulk_inventory.levels.B3.alphas)
    reused_spectrum = LOCAL_load_spectrum( ...
      bulk_inventory.levels.B3.paths{alias_index});
    alias_solve_id = sprintf('B3-reuse-B4-p%02d', 2 * alias_index - 1);
    artifacts.bulk_rows = LOCAL_append_bulk_rows(artifacts.bulk_rows, ...
      'B3', alias_solve_id, bulk_inventory.levels.B3.alphas(alias_index), ...
      reused_spectrum, 'alias-reuse-no-solve');
  end
  LOCAL_write_bulk_artifacts(artifacts, output_dir);

  gap_b1 = LOCAL_target_gap(spec, bulk_inventory.levels.B1.frequencies, 'B1');
  gap_b2 = LOCAL_target_gap(spec, bulk_inventory.levels.B2.frequencies, 'B2');
  gap_b3 = LOCAL_target_gap(spec, bulk_inventory.levels.B3.frequencies, 'B3');
  gap_b4 = LOCAL_target_gap(spec, bulk_inventory.levels.B4.frequencies, 'B4');
  gaps = {gap_b1, gap_b2, gap_b3, gap_b4};
  gap_names = {'B1', 'B2', 'B3', 'B4'};
  for gap_index = 1:4
    gap = gaps{gap_index};
    artifacts.bulk_gap_rows(end + 1, :) = {gap_names{gap_index}, ...
      gap.band_index, gap.lower, gap.upper, true, true, NaN, NaN, ...
      NaN, NaN, NaN, NaN, gap.pass, gap.reason}; %#ok<AGROW>
  end

  for sentinel_index = 1:numel(spec.count_phases)
    alpha = spec.count_phases(sentinel_index);
    main_index = find(abs(spec.bulk_alpha_33 - alpha) < 1e-14, 1);
    if isempty(main_index)
      LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
        'A fixed bulk count phase is absent from B4.');
    end
    solve_id = sprintf('B4-count-p%02d', sentinel_index);
    mesh = LOCAL_load_mesh(registry, work_dir, 'bulk-s24-g48');
    [sentinel, phase_diagnostic] = LOCAL_low_spectrum(spec, mesh, alpha, ...
      1e-11, spec.count_nev, 'bulk-count', bounds);
    main_frequencies = bulk_inventory.levels.B4.frequencies(:, main_index);
    main_spectrum = LOCAL_load_spectrum( ...
      bulk_inventory.levels.B4.paths{main_index});
    cluster_match = isequal(sentinel.cluster_ids(1:40), ...
      main_spectrum.cluster_ids(1:40));
    sentinel_mismatch = ...
      max(abs(sentinel.frequencies(1:40) - main_frequencies)) > ...
        spec.bulk_count_frequency_tolerance || ...
        ~cluster_match || ...
        any(sentinel.frequencies(41:48) > gap_b4.lower & ...
        sentinel.frequencies(41:48) < gap_b4.upper);
    artifacts.seam_rows(end + 1, :) = LOCAL_seam_row(mesh.id, ...
      'bulk-count', alpha, phase_diagnostic); %#ok<AGROW>
    artifacts.bulk_rows = LOCAL_append_bulk_rows(artifacts.bulk_rows, ...
      'B4-count', solve_id, alpha, sentinel, 'count-sentinel');
    sentinel_machine = sentinel;
    sentinel_machine.vectors_full = [];
    LOCAL_save_spectrum(fullfile(work_dir, [solve_id '.mat']), sentinel_machine);
    LOCAL_write_bulk_artifacts(artifacts, output_dir);
    LOCAL_write_mesh_artifacts(artifacts, output_dir);
    run_state = LOCAL_after_solve(spec, run_state, output_dir, solve_id);
    if sentinel_mismatch
      LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
        'Bulk count sentinel %s disagrees with the 40-root inventory.', solve_id));
    end
  end

  gap_width = gap_b4.upper - gap_b4.lower;
  delta_lower = abs(gap_b4.lower - gap_b2.lower) + ...
    abs(gap_b4.lower - gap_b3.lower);
  delta_upper = abs(gap_b4.upper - gap_b2.upper) + ...
    abs(gap_b4.upper - gap_b3.upper);
  lower_previous = abs(gap_b2.lower - gap_b1.lower);
  upper_previous = abs(gap_b2.upper - gap_b1.upper);
  lower_joint = abs(gap_b4.lower - gap_b2.lower);
  upper_joint = abs(gap_b4.upper - gap_b2.upper);
  lower_terminal = abs(gap_b4.lower - gap_b3.lower);
  upper_terminal = abs(gap_b4.upper - gap_b3.upper);
  refinement_pass = (lower_joint <= lower_previous || ...
    lower_terminal < spec.bulk_terminal_fraction * gap_width) && ...
    (upper_joint <= upper_previous || ...
    upper_terminal < spec.bulk_terminal_fraction * gap_width);
  safe_lower = gap_b4.lower + delta_lower;
  safe_upper = gap_b4.upper - delta_upper;
  safe_pass = safe_upper > safe_lower && ...
    safe_upper - safe_lower >= spec.safe_gap_fraction * gap_width;
  if ~refinement_pass || ~safe_pass
    LOCAL_raise('BULK_GAP_UNRESOLVED', ...
      'Bulk edge refinement or empirical safe-gap width gate failed.');
  end
  bulk_inventory.target_gap = struct('index', gap_b4.band_index, ...
    'raw', [gap_b4.lower, gap_b4.upper], ...
    'safe', [safe_lower, safe_upper], ...
    'delta_lower', delta_lower, 'delta_upper', delta_upper, ...
    'width', gap_width);
  artifacts.bulk_gap_rows(end + 1, :) = {'FINAL', gap_b4.band_index, ...
    gap_b4.lower, gap_b4.upper, true, true, lower_joint, upper_joint, ...
    delta_lower, delta_upper, safe_lower, safe_upper, true, 'PASS'};
end

function rows = LOCAL_append_bulk_rows(rows, level_id, solve_id, alpha, ...
    spectrum, role)
  multiplicities = spectrum.cluster_multiplicities;
  for root_index = 1:numel(spectrum.frequencies)
    cluster_id = spectrum.cluster_ids(root_index);
    rows(end + 1, :) = {level_id, solve_id, alpha, root_index, ...
      spectrum.frequencies(root_index), spectrum.eigenvalues(root_index), ...
      spectrum.residuals(root_index), cluster_id, ...
      multiplicities(cluster_id), role}; %#ok<AGROW>
  end
end

function gap = LOCAL_target_gap(spec, frequency_matrix, level_id)
  band_lower = min(frequency_matrix, [], 2);
  band_upper = max(frequency_matrix, [], 2);
  lower_edges = band_upper(1:(end - 1));
  upper_edges = band_lower(2:end);
  open_gap = upper_edges > lower_edges;
  contains_cue = lower_edges < spec.cue_interval(1) & ...
    upper_edges > spec.cue_interval(2);
  inside_guard = lower_edges > spec.guard_interval(1) & ...
    upper_edges < spec.guard_interval(2);
  candidates = find(open_gap & contains_cue & inside_guard);
  if numel(candidates) ~= 1
    LOCAL_raise('BULK_GAP_UNRESOLVED', sprintf( ...
      '%s has %d observed gaps containing the full cue interval.', ...
      level_id, numel(candidates)));
  end
  band_index = candidates(1);
  gap = struct('band_index', band_index, ...
    'lower', lower_edges(band_index), 'upper', upper_edges(band_index), ...
    'pass', true, 'reason', 'UNIQUE_CUE_GAP');
end

%% ==================== Complete defect inventory ====================
% These helpers compute the fixed 47-solve union and empty edge-buffer gate.

function [defect_inventory, run_state, artifacts] = LOCAL_defect_inventory( ...
    spec, bulk_inventory, registry, work_dir, output_dir, run_state, artifacts)
  schedule = LOCAL_defect_schedule(spec);
  if numel(schedule) ~= spec.planned_defect_solves
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'The frozen defect schedule does not contain exactly 47 solves.');
  end
  raw_gap = bulk_inventory.target_gap.raw;
  safe_gap = bulk_inventory.target_gap.safe;
  bounds = struct('lower_required', raw_gap(1) - ...
    spec.lower_sentinel_margin, 'upper_required', raw_gap(2) + ...
    spec.upper_sentinel_margin);
  entries = struct('id', {}, 'mesh_id', {}, 'theta', {}, 'tol', {}, ...
    'nev', {}, 'role', {}, 'path', {});
  for solve_index = 1:numel(schedule)
    item = schedule(solve_index);
    mesh = LOCAL_load_mesh(registry, work_dir, item.mesh_id);
    [spectrum, phase_diagnostic] = LOCAL_low_spectrum(spec, mesh, ...
      item.theta, item.tol, item.nev, item.role, bounds);
    in_raw = spectrum.frequencies > raw_gap(1) & ...
      spectrum.frequencies < raw_gap(2);
    in_safe = spectrum.frequencies > safe_gap(1) & ...
      spectrum.frequencies < safe_gap(2);
    in_buffer = in_raw & ~in_safe;
    artifacts.spectrum_rows = LOCAL_append_defect_rows( ...
      artifacts.spectrum_rows, item, spectrum, in_raw, in_safe, in_buffer);
    artifacts.seam_rows(end + 1, :) = LOCAL_seam_row(mesh.id, ...
      item.role, item.theta, phase_diagnostic); %#ok<AGROW>
    LOCAL_write_defect_artifact(artifacts, output_dir);
    LOCAL_write_mesh_artifacts(artifacts, output_dir);
    if any(in_buffer)
      LOCAL_raise('BULK_GAP_UNRESOLVED', sprintf( ...
        '%s contains %d eigenobjects in the raw-gap edge buffer.', ...
        item.id, nnz(in_buffer)));
    end
    path = fullfile(work_dir, [item.id '.mat']);
    LOCAL_save_spectrum(path, spectrum);
    entries(end + 1) = struct('id', item.id, 'mesh_id', item.mesh_id, ...
      'theta', item.theta, 'tol', item.tol, 'nev', item.nev, ...
      'role', item.role, 'path', path); %#ok<AGROW>

    if strcmp(item.role, 'loose-count')
      tight_index = LOCAL_theta_index(spec.theta_17, item.theta);
      tight_id = sprintf('fine-p%02d', tight_index);
      tight_entry = find(strcmp({entries.id}, tight_id), 1);
      if isempty(tight_entry)
        LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
          'A loose defect count sentinel has no prior tight solve.');
      end
      tight = LOCAL_load_spectrum(entries(tight_entry).path);
      mismatch = max(abs(spectrum.frequencies(1:40) - ...
        tight.frequencies(1:40)));
      cluster_match = isequal(spectrum.cluster_ids(1:40), ...
        tight.cluster_ids(1:40));
      upper_objects_in_gap = spectrum.frequencies(41:48) > raw_gap(1) & ...
        spectrum.frequencies(41:48) < raw_gap(2);
      if mismatch > spec.defect_count_frequency_tolerance || ...
          ~cluster_match || ...
          any(upper_objects_in_gap)
        LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
          '%s fails the fixed 48-versus-40 count sentinel.', item.id));
      end
    end
    run_state = LOCAL_after_solve(spec, run_state, output_dir, item.id);
  end
  if run_state.completed_solves ~= spec.planned_solves
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      'Completed %d of the frozen 119 eigensolves.', ...
      run_state.completed_solves));
  end
  defect_inventory = struct('entries', entries, 'raw_gap', raw_gap, ...
    'safe_gap', safe_gap);
end

function rows = LOCAL_append_defect_rows(rows, item, spectrum, ...
    in_raw, in_safe, in_buffer)
  multiplicities = spectrum.cluster_multiplicities;
  for root_index = 1:numel(spectrum.frequencies)
    cluster_id = spectrum.cluster_ids(root_index);
    rows(end + 1, :) = {item.id, item.mesh_id, item.role, item.theta, ...
      item.nev, root_index, spectrum.frequencies(root_index), ...
      spectrum.eigenvalues(root_index), spectrum.residuals(root_index), ...
      cluster_id, multiplicities(cluster_id), in_raw(root_index), ...
      in_safe(root_index), in_buffer(root_index)}; %#ok<AGROW>
  end
end

function phase_index = LOCAL_theta_index(grid, phase)
  [distance, phase_index] = min(abs(grid - phase));
  if distance > 1e-13
    error('I4A:PhaseGrid', 'Phase %.17g is not on the frozen grid.', phase);
  end
end

%% ==================== Cluster subspaces and coverage ====================
% These helpers use only basis-invariant Grams, envelopes, and principal angles.

function [branch_inventory, coverage, artifacts] = ...
    LOCAL_branch_and_coverage(spec, bulk_inventory, defect_inventory, ...
    registry, work_dir, artifacts)
  group_names = {'fem-coarse', 'fem-medium', 'fine', 'N3-medium', ...
    'N4-medium', 'N4-fine', 'fine-loose-count'};
  configurations = struct();
  maps = struct();
  artifacts.coverage_rows = LOCAL_pending_coverage_rows( ...
    defect_inventory, bulk_inventory.target_gap);
  for group_index = 1:numel(group_names)
    name = group_names{group_index};
    field_name = LOCAL_field_name(name);
    try
      [configurations.(field_name), build_failure] = LOCAL_build_configuration( ...
        spec, name, defect_inventory, bulk_inventory.target_gap, registry, ...
        work_dir);
    catch caught
      [failure_code, failure_reason] = LOCAL_decode_failure(caught);
      if strcmp(failure_code, 'EXECUTION_UNAVAILABLE')
        rethrow(caught);
      end
      [branch_inventory, coverage, artifacts] = ...
        LOCAL_branch_failure_handoff(artifacts, configurations, maps, ...
        spec, failure_code, failure_reason);
      return;
    end
    if build_failure.failed
      [branch_inventory, coverage, artifacts] = ...
        LOCAL_branch_failure_handoff(artifacts, configurations, maps, ...
        spec, build_failure.code, build_failure.reason);
      return;
    end
    [configurations.(field_name), edge_rows, stage_failure] = ...
      LOCAL_track_twists(spec, configurations.(field_name));
    artifacts.branch_edge_rows = [artifacts.branch_edge_rows; edge_rows]; %#ok<AGROW>
    if stage_failure.failed
      [branch_inventory, coverage, artifacts] = ...
        LOCAL_branch_failure_handoff(artifacts, configurations, maps, ...
        spec, stage_failure.code, stage_failure.reason);
      return;
    end
  end

  finest = configurations.fine;
  comparison_names = {'fem_coarse', 'fem_medium', 'N3_medium', ...
    'N4_medium', 'N4_fine', 'fine_loose_count'};
  maps.fine = 1:numel(finest.branches);
  for comparison_index = 1:numel(comparison_names)
    field_name = comparison_names{comparison_index};
    other = configurations.(field_name);
    try
      maps.(field_name) = LOCAL_match_configurations(spec, finest, other);
    catch caught
      [failure_code, failure_reason] = LOCAL_decode_failure(caught);
      if strcmp(failure_code, 'EXECUTION_UNAVAILABLE')
        rethrow(caught);
      end
      [branch_inventory, coverage, artifacts] = ...
        LOCAL_branch_failure_handoff(artifacts, configurations, maps, ...
        spec, failure_code, failure_reason);
      return;
    end
  end

  coverage_rows = cell(0, 12);
  all_configuration_names = fieldnames(configurations);
  for config_index = 1:numel(all_configuration_names)
    field_name = all_configuration_names{config_index};
    config = configurations.(field_name);
    for slice_index = 1:numel(config.slices)
      slice = config.slices(slice_index);
      for cluster_index = 1:numel(slice.clusters)
        cluster = slice.clusters(cluster_index);
        branch_id = config.cluster_to_branch{slice_index}(cluster_index);
        coverage_rows(end + 1, :) = {config.name, slice.solve_id, ...
          slice.theta, cluster.cluster_id, cluster.dimension, branch_id, ...
          'TRACKED', 'SAFE_GAP_CLUSTER', false, true, '', ''}; %#ok<AGROW>
      end
    end
  end

  qualified_indices = zeros(0, 1);
  mode_ambiguous = false;
  for branch_index = 1:numel(finest.branches)
    branch = finest.branches(branch_index);
    localization_pass = all(branch.L0_min >= ...
      spec.localization_center_min) && all(branch.Lcore_min >= ...
      spec.localization_core_min) && all(branch.tail_max <= spec.tail_max);
    [tail_pass, tail_reason] = LOCAL_tail_collapse(spec, branch_index, ...
      configurations, maps);
    [twist_pass, twist_reason] = LOCAL_twist_collapse(spec, branch_index, ...
      bulk_inventory.target_gap.width, configurations, maps);
    if localization_pass && tail_pass && twist_pass
      qualified_indices(end + 1, 1) = branch_index; %#ok<AGROW>
      disposition = 'QUALIFIED_FOR_RESOLUTION';
      reason = 'ALL_LOCALIZATION_TAIL_TWIST_GATES_PASS';
    elseif ~localization_pass
      disposition = 'EXCLUDED';
      reason = 'FROZEN_LOCALIZATION_SCREEN_FAILED';
    elseif ~tail_pass
      [branch_inventory, coverage, artifacts] = ...
        LOCAL_branch_failure_handoff(artifacts, configurations, maps, ...
        spec, 'SUPERCELL_RESOLUTION_UNAVAILABLE', tail_reason);
      return;
    else
      [branch_inventory, coverage, artifacts] = ...
        LOCAL_branch_failure_handoff(artifacts, configurations, maps, ...
        spec, 'SUPERCELL_RESOLUTION_UNAVAILABLE', twist_reason);
      return;
    end
    if branch.parity_ambiguous
      mode_ambiguous = true;
    end
    configurations.fine.branches(branch_index).qualification = disposition;
    configurations.fine.branches(branch_index).qualification_reason = reason;
    for coverage_index = 1:size(coverage_rows, 1)
      if strcmp(coverage_rows{coverage_index, 1}, 'fine') && ...
          coverage_rows{coverage_index, 6} == branch_index
        coverage_rows{coverage_index, 7} = disposition;
        coverage_rows{coverage_index, 8} = reason;
      end
    end
  end

  for config_index = 1:numel(all_configuration_names)
    field_name = all_configuration_names{config_index};
    config = configurations.(field_name);
    artifacts.branch_rows = LOCAL_append_branch_rows(artifacts.branch_rows, ...
      config, spec);
  end
  artifacts.coverage_rows = coverage_rows;
  coverage = struct('pass', true, 'failure_code', '', 'reason', 'PASS', ...
    'mode_id_ambiguous', mode_ambiguous, ...
    'empirical_only', true, 'continuous_completeness_certified', false);
  branch_inventory = struct();
  branch_inventory.configurations = configurations;
  branch_inventory.maps = maps;
  branch_inventory.qualified_indices = qualified_indices;
  branch_inventory.finest_branches = ...
    configurations.fine.branches(qualified_indices);
  branch_inventory.anchor_fields = LOCAL_anchor_fields( ...
    configurations.fine.branches, qualified_indices);
  branch_inventory.reached_anchor_fields = ...
    LOCAL_reached_anchor_fields(configurations);
end

function rows = LOCAL_pending_coverage_rows(defect_inventory, target_gap)
  rows = cell(0, 12);
  for entry_index = 1:numel(defect_inventory.entries)
    entry = defect_inventory.entries(entry_index);
    spectrum = LOCAL_load_spectrum(entry.path);
    in_raw = spectrum.frequencies > target_gap.raw(1) & ...
      spectrum.frequencies < target_gap.raw(2);
    cluster_ids = unique(spectrum.cluster_ids(in_raw)).';
    for cluster_index = 1:numel(cluster_ids)
      cluster_id = cluster_ids(cluster_index);
      multiplicity = nnz(spectrum.cluster_ids == cluster_id);
      rows(end + 1, :) = {entry.role, entry.id, entry.theta, ...
        cluster_id, multiplicity, NaN, 'REACHED_UNASSIGNED', ...
        'BRANCH_STAGE_PENDING', false, false, '', ''}; %#ok<AGROW>
    end
  end
end

function [branch_inventory, coverage, artifacts] = ...
    LOCAL_branch_failure_handoff(artifacts, configurations, maps, spec, ...
    failure_code, failure_reason)
  configuration_names = fieldnames(configurations);
  for config_index = 1:numel(configuration_names)
    config = configurations.(configuration_names{config_index});
    if isfield(config, 'branches') && ~isempty(config.branches)
      artifacts.branch_rows = LOCAL_append_branch_rows( ...
        artifacts.branch_rows, config, spec);
    elseif isfield(config, 'slices') && ~isempty(config.slices)
      artifacts.branch_rows = LOCAL_append_reached_cluster_rows( ...
        artifacts.branch_rows, config, spec);
    end
  end
  artifacts = LOCAL_mark_branch_failure(artifacts, ...
    failure_code, failure_reason);
  coverage = struct('pass', false, 'failure_code', failure_code, ...
    'reason', failure_reason, 'mode_id_ambiguous', false, ...
    'empirical_only', true, 'continuous_completeness_certified', false);
  branch_inventory = struct('configurations', configurations, 'maps', maps, ...
    'qualified_indices', zeros(0, 1), 'finest_branches', struct([]), ...
    'anchor_fields', struct([]), 'reached_anchor_fields', ...
    LOCAL_reached_anchor_fields(configurations));
end

function rows = LOCAL_append_reached_cluster_rows(rows, config, spec)
  for slice_index = 1:numel(config.slices)
    slice = config.slices(slice_index);
    for cluster_index = 1:numel(slice.clusters)
      cluster = slice.clusters(cluster_index);
      localization_pass = cluster.L0_min >= spec.localization_center_min && ...
        cluster.Lcore_min >= spec.localization_core_min;
      tail_pass = cluster.tail_max <= spec.tail_max;
      rows(end + 1, :) = {config.name, NaN, cluster.dimension, ...
        slice.theta, cluster.envelope(1), cluster.envelope(2), ...
        cluster.L0_min, cluster.Lcore_min, cluster.tail_max, ...
        LOCAL_flat_numeric(cluster.parity_spectrum), ...
        cluster.parity_ambiguous, localization_pass, tail_pass, false, ...
        cluster.envelope(1), cluster.envelope(2), mean(cluster.envelope), ...
        diff(cluster.envelope) / 2, false, 'REACHED_UNTRACKED', ...
        'NONCANONICAL_BASIS_FOR_SUBSPACE_ONLY', ...
        'CONTINUATION_NOT_COMPLETED', '', ''}; %#ok<AGROW>
    end
  end
end

function artifacts = LOCAL_mark_branch_failure(artifacts, code, reason)
  if ~isempty(artifacts.branch_edge_rows)
    artifacts.branch_edge_rows(:, 13) = {code};
    artifacts.branch_edge_rows(:, 14) = {reason};
  end
  if ~isempty(artifacts.branch_rows)
    artifacts.branch_rows(:, 23) = {code};
    artifacts.branch_rows(:, 24) = {reason};
  end
  if ~isempty(artifacts.coverage_rows)
    artifacts.coverage_rows(:, 11) = {code};
    artifacts.coverage_rows(:, 12) = {reason};
  end
  artifacts.branch_edge_rows(end + 1, :) = {'FAILURE_MARKER', NaN, NaN, ...
    NaN, NaN, NaN, NaN, NaN, false, false, NaN, NaN, code, reason};
  artifacts.branch_rows(end + 1, :) = {'FAILURE_MARKER', NaN, NaN, NaN, ...
    NaN, NaN, NaN, NaN, NaN, '', false, false, false, false, NaN, NaN, ...
    NaN, NaN, false, 'UNQUALIFIED', 'FAILURE_ARTIFACT', reason, code, reason};
  artifacts.coverage_rows(end + 1, :) = {'FAILURE_MARKER', '', NaN, NaN, ...
    NaN, NaN, 'FAIL_CLOSED', reason, false, false, code, reason};
end

function failure = LOCAL_empty_stage_failure()
  failure = struct('failed', false, 'code', '', 'reason', '');
end

function failure = LOCAL_stage_failure(code, reason)
  failure = struct('failed', true, 'code', code, 'reason', reason);
end

function name = LOCAL_field_name(name)
  name = strrep(name, '-', '_');
end

function [config, failure] = LOCAL_build_configuration(spec, name, defect_inventory, ...
    target_gap, registry, work_dir)
  failure = LOCAL_empty_stage_failure();
  entry_mask = startsWith({defect_inventory.entries.id}, [name '-p']);
  entries = defect_inventory.entries(entry_mask);
  if isempty(entries)
    error('I4A:Configuration', 'No solves found for configuration %s.', name);
  end
  [~, order] = sort([entries.theta]);
  entries = entries(order);
  mesh = LOCAL_load_mesh(registry, work_dir, entries(1).mesh_id);
  slices = struct('solve_id', {}, 'theta', {}, 'clusters', {});
  config = struct('name', name, 'mesh_id', entries(1).mesh_id, ...
    'mesh', mesh, 'slices', slices, 'branches', [], ...
    'cluster_to_branch', {{}});
  for slice_index = 1:numel(entries)
    spectrum = LOCAL_load_spectrum(entries(slice_index).path);
    try
      clusters = LOCAL_gap_clusters(spec, spectrum, target_gap, mesh);
    catch caught
      [failure_code, failure_reason] = LOCAL_decode_failure(caught);
      if strcmp(failure_code, 'EXECUTION_UNAVAILABLE')
        rethrow(caught);
      end
      failure = LOCAL_stage_failure(failure_code, failure_reason);
      config.slices = slices;
      return;
    end
    slices(end + 1) = struct('solve_id', entries(slice_index).id, ...
      'theta', entries(slice_index).theta, 'clusters', clusters); %#ok<AGROW>
  end
  config.slices = slices;
end

function clusters = LOCAL_gap_clusters(spec, spectrum, target_gap, mesh)
  raw = target_gap.raw;
  in_raw = spectrum.frequencies > raw(1) & spectrum.frequencies < raw(2);
  cluster_numbers = unique(spectrum.cluster_ids(in_raw)).';
  clusters = struct('cluster_id', {}, 'root_indices', {}, 'dimension', {}, ...
    'frequencies', {}, 'envelope', {}, 'subspace', {}, 'L0_min', {}, ...
    'Lcore_min', {}, 'tail_max', {}, 'parity_spectrum', {}, ...
    'parity_ambiguous', {});
  reflection = sparse((1:size(mesh.points, 1)).', mesh.reflection_index, 1, ...
    size(mesh.points, 1), size(mesh.points, 1));
  for local_index = 1:numel(cluster_numbers)
    cluster_id = cluster_numbers(local_index);
    root_indices = find(spectrum.cluster_ids == cluster_id);
    if any(~in_raw(root_indices))
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'A frequency cluster straddles a raw observed gap edge.');
    end
    subspace = spectrum.vectors_full(:, root_indices);
    gram_full = subspace' * mesh.mass_full * subspace;
    [normalizer, normalizer_flag] = chol((gram_full + gram_full') / 2);
    if normalizer_flag ~= 0
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'A gap cluster cannot be M-orthonormalized.');
    end
    subspace = subspace / normalizer;
    gram_center = (subspace' * mesh.mass_center * subspace);
    gram_core = (subspace' * mesh.mass_core * subspace);
    gram_tail = (subspace' * mesh.mass_tail * subspace);
    center_values = real(eig((gram_center + gram_center') / 2));
    core_values = real(eig((gram_core + gram_core') / 2));
    tail_values = real(eig((gram_tail + gram_tail') / 2));
    parity_matrix = subspace' * mesh.mass_full * reflection * subspace;
    parity_values = real(eig((parity_matrix + parity_matrix') / 2));
    parity_ambiguous = any(abs(parity_values) < spec.parity_threshold);
    clusters(end + 1) = struct('cluster_id', cluster_id, ...
      'root_indices', root_indices, 'dimension', numel(root_indices), ...
      'frequencies', spectrum.frequencies(root_indices), ...
      'envelope', [min(spectrum.frequencies(root_indices)), ...
      max(spectrum.frequencies(root_indices))], 'subspace', subspace, ...
      'L0_min', min(center_values), 'Lcore_min', min(core_values), ...
      'tail_max', max(tail_values), 'parity_spectrum', parity_values, ...
      'parity_ambiguous', parity_ambiguous); %#ok<AGROW>
  end
end

function [config, edge_rows, failure] = LOCAL_track_twists(spec, config)
  slice_count = numel(config.slices);
  edge_rows = cell(0, 14);
  failure = LOCAL_empty_stage_failure();
  cluster_counts = zeros(1, slice_count);
  for slice_index = 1:slice_count
    cluster_counts(slice_index) = numel(config.slices(slice_index).clusters);
  end
  if slice_count == 0 || all(cluster_counts == 0)
    config.branches = struct([]);
    config.cluster_to_branch = cell(1, slice_count);
    return;
  end
  if any(cluster_counts == 0) || any(cluster_counts ~= cluster_counts(1))
    failure = LOCAL_stage_failure('REFERENCE_SET_COVERAGE_UNRESOLVED', sprintf( ...
      '%s has a partial-empty or changing raw-gap cluster inventory.', ...
      config.name));
    config.branches = struct([]);
    config.cluster_to_branch = cell(1, slice_count);
    return;
  end
  initial_count = cluster_counts(1);
  mapping = cell(1, slice_count);
  mapping{1} = 1:initial_count;
  for slice_index = 2:slice_count
    previous = config.slices(slice_index - 1).clusters;
    current = config.slices(slice_index).clusters;
    if numel(previous) ~= initial_count || numel(current) ~= initial_count
      failure = LOCAL_stage_failure('REFERENCE_SET_COVERAGE_UNRESOLVED', sprintf( ...
        '%s changes its raw-gap cluster count across twist.', config.name));
      config.cluster_to_branch = mapping;
      return;
    end
    score = -inf(initial_count, initial_count);
    for previous_index = 1:initial_count
      for current_index = 1:initial_count
        if previous(previous_index).dimension == current(current_index).dimension
          score(previous_index, current_index) = ...
            LOCAL_same_mesh_overlap(previous(previous_index).subspace, ...
            current(current_index).subspace, config.mesh.mass_full);
        end
      end
    end
    [previous_best, previous_choice] = max(score, [], 2);
    [~, current_choice] = max(score, [], 1);
    mapping{slice_index} = zeros(1, initial_count);
    for previous_index = 1:initial_count
      current_index = previous_choice(previous_index);
      dimension = previous(previous_index).dimension;
      threshold = spec.cluster_overlap_min;
      if dimension == 1
        threshold = spec.simple_overlap_min;
      end
      mutual = current_choice(current_index) == previous_index;
      accepted = mutual && previous_best(previous_index) >= threshold;
      edge_rows(end + 1, :) = {config.name, ...
        config.slices(slice_index - 1).theta, ...
        config.slices(slice_index).theta, ...
        previous(previous_index).cluster_id, current(current_index).cluster_id, ...
        dimension, previous_best(previous_index), threshold, mutual, ...
        accepted, mapping{slice_index - 1}(previous_index), ...
        mapping{slice_index - 1}(previous_index), '', ''}; %#ok<AGROW>
      if ~accepted || mapping{slice_index}(current_index) ~= 0
        failure = LOCAL_stage_failure('REFERENCE_SET_COVERAGE_UNRESOLVED', sprintf( ...
          '%s has nonunique or weak twist continuation.', config.name));
        config.cluster_to_branch = mapping;
        return;
      end
      mapping{slice_index}(current_index) = ...
        mapping{slice_index - 1}(previous_index);
    end
    if any(mapping{slice_index} == 0)
      failure = LOCAL_stage_failure('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'A twist cluster is not assigned to a branch.');
      config.cluster_to_branch = mapping;
      return;
    end
  end
  branches = repmat(struct(), 1, initial_count);
  for branch_id = 1:initial_count
    branch_clusters = cell(1, slice_count);
    for slice_index = 1:slice_count
      cluster_index = find(mapping{slice_index} == branch_id, 1);
      branch_clusters{slice_index} = config.slices(slice_index).clusters(cluster_index);
    end
    dimensions = cellfun(@(cluster) cluster.dimension, branch_clusters);
    if any(dimensions ~= dimensions(1))
      failure = LOCAL_stage_failure('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'A tracked branch changes subspace dimension.');
      config.cluster_to_branch = mapping;
      return;
    end
    envelope_cells = cellfun(@(cluster) cluster.envelope, ...
      branch_clusters, 'UniformOutput', false);
    envelopes = vertcat(envelope_cells{:});
    branches(branch_id).id = branch_id;
    branches(branch_id).dimension = dimensions(1);
    branches(branch_id).clusters = branch_clusters;
    branches(branch_id).thetas = [config.slices.theta];
    branches(branch_id).L0_min = cellfun(@(cluster) cluster.L0_min, ...
      branch_clusters);
    branches(branch_id).Lcore_min = cellfun(@(cluster) cluster.Lcore_min, ...
      branch_clusters);
    branches(branch_id).tail_max = cellfun(@(cluster) cluster.tail_max, ...
      branch_clusters);
    branches(branch_id).envelope = [min(envelopes(:, 1)), ...
      max(envelopes(:, 2))];
    branches(branch_id).center = mean(branches(branch_id).envelope);
    branches(branch_id).half_width = diff(branches(branch_id).envelope) / 2;
    branches(branch_id).parity_ambiguous = ...
      branch_clusters{1}.parity_ambiguous || ...
      branch_clusters{end}.parity_ambiguous;
    branches(branch_id).parity_signature = LOCAL_parity_signature( ...
      branch_clusters{1}.parity_spectrum, ...
      branch_clusters{end}.parity_spectrum, spec.parity_threshold);
    branches(branch_id).qualification = 'NOT_EVALUATED';
    branches(branch_id).qualification_reason = '';
  end
  config.branches = branches;
  config.cluster_to_branch = mapping;
end

function overlap = LOCAL_same_mesh_overlap(first_subspace, second_subspace, mass)
  singular_values = svd(first_subspace' * mass * second_subspace);
  overlap = min(singular_values);
end

function signature = LOCAL_parity_signature(first_values, last_values, threshold)
  all_values = [sort(first_values(:)); sort(last_values(:))];
  labels = cell(numel(all_values), 1);
  for value_index = 1:numel(all_values)
    if all_values(value_index) >= threshold
      labels{value_index} = 'even';
    elseif all_values(value_index) <= -threshold
      labels{value_index} = 'odd';
    else
      labels{value_index} = 'ambiguous';
    end
  end
  signature = strjoin(labels, ';');
end

function mapping = LOCAL_match_configurations(spec, finest, other)
  fine_count = numel(finest.branches);
  other_count = numel(other.branches);
  if fine_count == 0 && other_count == 0
    mapping = zeros(1, 0);
    return;
  end
  if fine_count ~= other_count
    LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', sprintf( ...
      '%s and %s have different raw-gap branch counts.', ...
      finest.name, other.name));
  end
  common_phases = linspace(0, pi, 5);
  score = -inf(fine_count, other_count);
  for fine_index = 1:fine_count
    for other_index = 1:other_count
      if finest.branches(fine_index).dimension ~= ...
          other.branches(other_index).dimension
        continue;
      end
      slice_scores = zeros(1, numel(common_phases));
      for phase_index = 1:numel(common_phases)
        fine_slice = LOCAL_theta_index(finest.branches(fine_index).thetas, ...
          common_phases(phase_index));
        other_slice = LOCAL_theta_index(other.branches(other_index).thetas, ...
          common_phases(phase_index));
        fine_subspace = finest.branches(fine_index).clusters{fine_slice}.subspace;
        other_subspace = other.branches(other_index).clusters{other_slice}.subspace;
        slice_scores(phase_index) = LOCAL_common_core_overlap(spec, ...
          finest.mesh, fine_subspace, other.mesh, other_subspace);
      end
      score(fine_index, other_index) = min(slice_scores);
    end
  end
  [fine_best, fine_choice] = max(score, [], 2);
  [~, other_choice] = max(score, [], 1);
  mapping = zeros(1, fine_count);
  for fine_index = 1:fine_count
    other_index = fine_choice(fine_index);
    dimension = finest.branches(fine_index).dimension;
    threshold = spec.cluster_overlap_min;
    if dimension == 1
      threshold = spec.simple_overlap_min;
    end
    if other_choice(other_index) ~= fine_index || ...
        fine_best(fine_index) < threshold || any(mapping == other_index)
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', sprintf( ...
        '%s has nonunique common-core continuation from finest geometry.', ...
        other.name));
    end
    mapping(fine_index) = other_index;
  end
end

function overlap = LOCAL_common_core_overlap(spec, first_mesh, first_subspace, ...
    second_mesh, second_subspace)
  [first_samples, weights] = LOCAL_sample_subspace(spec, first_mesh, ...
    first_subspace);
  [second_samples, second_weights] = LOCAL_sample_subspace(spec, second_mesh, ...
    second_subspace);
  if numel(weights) ~= numel(second_weights) || ...
      max(abs(weights - second_weights)) > 1e-14
    LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
      'Common-core diagnostic weights differ across meshes.');
  end
  first_gram = first_samples' * (weights .* first_samples);
  second_gram = second_samples' * (weights .* second_samples);
  [first_factor, first_flag] = chol((first_gram + first_gram') / 2);
  [second_factor, second_flag] = chol((second_gram + second_gram') / 2);
  if first_flag ~= 0 || second_flag ~= 0
    LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
      'Common-core sampled subspace is rank deficient.');
  end
  first_samples = first_samples / first_factor;
  second_samples = second_samples / second_factor;
  singular_values = svd(first_samples' * (weights .* second_samples));
  overlap = min(singular_values);
end

function [samples, weights] = LOCAL_sample_subspace(spec, mesh, subspace)
  [grid_x, grid_y] = meshgrid(spec.core_grid_x, spec.core_grid_y);
  query = [grid_x(:), grid_y(:)];
  weight_x = ones(size(spec.core_grid_x));
  weight_y = ones(size(spec.core_grid_y));
  weight_x([1, end]) = 0.5;
  weight_y([1, end]) = 0.5;
  [tensor_weight_x, tensor_weight_y] = meshgrid(weight_x, weight_y);
  weights = tensor_weight_x(:) .* tensor_weight_y(:);
  weights = weights * (spec.core_grid_x(2) - spec.core_grid_x(1)) * ...
    (spec.core_grid_y(2) - spec.core_grid_y(1));
  on_circle = false(size(query, 1), 1);
  q_values = spec.q_outside * ones(size(query, 1), 1);
  disk_centers = -2:2;
  disk_centers(disk_centers == spec.missing_column) = [];
  for center_index = 1:numel(disk_centers)
    radial_distance = hypot(query(:, 1) - disk_centers(center_index), ...
      query(:, 2));
    on_circle = on_circle | abs(radial_distance - spec.radius) <= 1e-12;
    q_values(radial_distance < spec.radius) = spec.q_inside;
  end
  query(on_circle, :) = [];
  weights(on_circle) = [];
  q_values(on_circle) = [];
  physical_triangulation = triangulation(mesh.triangles, mesh.points);
  [triangle_index, barycentric] = pointLocation(physical_triangulation, query);
  if any(isnan(triangle_index))
    LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
      'Common-core diagnostic grid is not covered by a mesh.');
  end
  vertices = mesh.triangles(triangle_index, :);
  samples = barycentric(:, 1) .* subspace(vertices(:, 1), :) + ...
    barycentric(:, 2) .* subspace(vertices(:, 2), :) + ...
    barycentric(:, 3) .* subspace(vertices(:, 3), :);
  weights = weights .* q_values;
end

function [pass, reason] = LOCAL_tail_collapse(spec, fine_index, ...
    configurations, maps)
  branch_n3 = configurations.N3_medium.branches(maps.N3_medium(fine_index));
  branch_n4 = configurations.N4_medium.branches(maps.N4_medium(fine_index));
  branch_n5 = configurations.fem_medium.branches(maps.fem_medium(fine_index));
  branch_n4_fine = configurations.N4_fine.branches(maps.N4_fine(fine_index));
  branch_n5_fine = configurations.fine.branches(fine_index);
  pass = true;
  for phase_index = 1:5
    medium_values = [branch_n3.tail_max(phase_index), ...
      branch_n4.tail_max(phase_index), branch_n5.tail_max(phase_index)];
    pass = pass && LOCAL_three_level_collapse(medium_values, spec);
    fine_slice = LOCAL_theta_index(branch_n5_fine.thetas, ...
      branch_n4_fine.thetas(phase_index));
    pass = pass && LOCAL_two_level_collapse( ...
      branch_n4_fine.tail_max(phase_index), ...
      branch_n5_fine.tail_max(fine_slice), spec);
  end
  if pass
    reason = 'PASS';
  else
    reason = sprintf('Branch %d fails an every-slice outer-tail collapse.', ...
      fine_index);
  end
end

function pass = LOCAL_three_level_collapse(values, spec)
  if values(3) <= spec.tail_plateau
    pass = values(3) <= values(2) + spec.tail_plateau && ...
      values(2) <= values(1) + spec.tail_plateau;
  else
    pass = values(3) <= spec.collapse_factor * values(2) && ...
      values(2) <= spec.collapse_factor * values(1);
  end
end

function pass = LOCAL_two_level_collapse(coarse_value, fine_value, spec)
  if fine_value <= spec.tail_plateau
    pass = fine_value <= coarse_value + spec.tail_plateau;
  else
    pass = fine_value <= spec.collapse_factor * coarse_value;
  end
end

function [pass, reason] = LOCAL_twist_collapse(spec, fine_index, gap_width, ...
    configurations, maps)
  branch_n3 = configurations.N3_medium.branches(maps.N3_medium(fine_index));
  branch_n4 = configurations.N4_medium.branches(maps.N4_medium(fine_index));
  branch_n5 = configurations.fem_medium.branches(maps.fem_medium(fine_index));
  medium_widths = [branch_n3.half_width, branch_n4.half_width, ...
    branch_n5.half_width];
  medium_pass = medium_widths(3) <= medium_widths(2) + 1e-14 && ...
    medium_widths(2) <= medium_widths(1) + 1e-14;
  branch_n4_fine = configurations.N4_fine.branches(maps.N4_fine(fine_index));
  branch_n5_fine = configurations.fine.branches(fine_index);
  fine_envelope_theta5 = LOCAL_envelope_on_grid(branch_n5_fine, spec.theta_5);
  fine_width_theta5 = diff(fine_envelope_theta5) / 2;
  final_pass = fine_width_theta5 <= ...
    spec.collapse_factor * branch_n4_fine.half_width || ...
    fine_width_theta5 <= 1e-4 * gap_width;
  pass = medium_pass && final_pass;
  if pass
    reason = 'PASS';
  else
    reason = sprintf('Branch %d fails the frozen twist-width collapse.', ...
      fine_index);
  end
end

function envelope = LOCAL_envelope_on_grid(branch, grid)
  lower_values = zeros(1, numel(grid));
  upper_values = zeros(1, numel(grid));
  for phase_index = 1:numel(grid)
    slice_index = LOCAL_theta_index(branch.thetas, grid(phase_index));
    lower_values(phase_index) = branch.clusters{slice_index}.envelope(1);
    upper_values(phase_index) = branch.clusters{slice_index}.envelope(2);
  end
  envelope = [min(lower_values), max(upper_values)];
end

function rows = LOCAL_append_branch_rows(rows, config, spec)
  for branch_index = 1:numel(config.branches)
    branch = config.branches(branch_index);
    localization_all = all(branch.L0_min >= spec.localization_center_min) && ...
      all(branch.Lcore_min >= spec.localization_core_min);
    tail_all = all(branch.tail_max <= spec.tail_max);
    for slice_index = 1:numel(branch.clusters)
      cluster = branch.clusters{slice_index};
      rows(end + 1, :) = {config.name, branch.id, branch.dimension, ...
        branch.thetas(slice_index), cluster.envelope(1), ...
        cluster.envelope(2), cluster.L0_min, cluster.Lcore_min, ...
        cluster.tail_max, branch.parity_signature, ...
        branch.parity_ambiguous, localization_all, tail_all, true, ...
        branch.envelope(1), branch.envelope(2), branch.center, ...
        branch.half_width, localization_all && tail_all, ...
        branch.qualification, 'NONCANONICAL_BASIS_FOR_SUBSPACE_ONLY', ...
        branch.qualification_reason, '', ''}; %#ok<AGROW>
    end
  end
end

function anchor_fields = LOCAL_anchor_fields(branches, qualified_indices)
  anchor_fields = struct('branch_id', {}, 'multiplicity', {}, ...
    'subspace', {}, 'simple_vector', {}, 'basis_status', {});
  for output_index = 1:numel(qualified_indices)
    branch_index = qualified_indices(output_index);
    branch = branches(branch_index);
    subspace = branch.clusters{1}.subspace;
    simple_vector = [];
    if branch.dimension == 1
      [~, pivot] = max(abs(subspace(:, 1)));
      phase = exp(-1i * angle(subspace(pivot, 1)));
      simple_vector = subspace(:, 1) * phase;
    end
    anchor_fields(end + 1) = struct('branch_id', branch.id, ...
      'multiplicity', branch.dimension, 'subspace', subspace, ...
      'simple_vector', simple_vector, ...
      'basis_status', 'NONCANONICAL_BASIS_FOR_SUBSPACE_ONLY'); %#ok<AGROW>
  end
end

function reached_anchor_fields = LOCAL_reached_anchor_fields(configurations)
  reached_anchor_fields = struct('configuration', {}, 'mesh_id', {}, ...
    'branch_id', {}, 'multiplicity', {}, 'anchor_theta', {}, ...
    'subspace', {}, 'simple_vector', {}, 'basis_status', {}, ...
    'qualification', {}, 'qualification_reason', {});
  configuration_names = fieldnames(configurations);
  for config_index = 1:numel(configuration_names)
    config = configurations.(configuration_names{config_index});
    if ~isfield(config, 'branches') || isempty(config.branches)
      continue;
    end
    for branch_index = 1:numel(config.branches)
      branch = config.branches(branch_index);
      subspace = branch.clusters{1}.subspace;
      simple_vector = [];
      if branch.dimension == 1
        [~, pivot] = max(abs(subspace(:, 1)));
        phase = exp(-1i * angle(subspace(pivot, 1)));
        simple_vector = subspace(:, 1) * phase;
      end
      reached_anchor_fields(end + 1) = struct( ...
        'configuration', config.name, 'mesh_id', config.mesh_id, ...
        'branch_id', branch.id, 'multiplicity', branch.dimension, ...
        'anchor_theta', branch.thetas(1), 'subspace', subspace, ...
        'simple_vector', simple_vector, ...
        'basis_status', 'NONCANONICAL_BASIS_FOR_SUBSPACE_ONLY', ...
        'qualification', branch.qualification, ...
        'qualification_reason', branch.qualification_reason); %#ok<AGROW>
    end
  end
end

%% ==================== Four-axis observed resolution ====================
% These helpers implement the frozen envelope formulas without error-bound claims.

function [result, artifacts] = LOCAL_resolution(spec, bulk_inventory, ...
    branch_inventory, artifacts)
  configs = branch_inventory.configurations;
  maps = branch_inventory.maps;
  gap_width = bulk_inventory.target_gap.width;
  collection = struct('branch_id', {}, 'multiplicity', {}, ...
    'reference_frequency', {}, 'reference_envelope', {}, ...
    'delta_fem', {}, 'delta_supercell', {}, 'delta_twist', {}, ...
    'delta_algebraic', {}, 'delta_reference', {}, ...
    'parity_signature', {}, 'mode_id_ambiguous', {}, ...
    'uncertainty_status', {});
  all_pass = true;
  failure_messages = cell(0, 1);
  for qualified_index = 1:numel(branch_inventory.qualified_indices)
    fine_index = branch_inventory.qualified_indices(qualified_index);
    fine_branch = configs.fine.branches(fine_index);
    coarse_branch = configs.fem_coarse.branches( ...
      maps.fem_coarse(fine_index));
    medium_branch = configs.fem_medium.branches( ...
      maps.fem_medium(fine_index));
    n3_branch = configs.N3_medium.branches(maps.N3_medium(fine_index));
    n4_branch = configs.N4_medium.branches(maps.N4_medium(fine_index));
    n4_fine_branch = configs.N4_fine.branches(maps.N4_fine(fine_index));
    loose_branch = configs.fine_loose_count.branches( ...
      maps.fine_loose_count(fine_index));

    envelope_fine_5 = LOCAL_envelope_on_grid(fine_branch, spec.theta_5);
    envelope_fine_9 = LOCAL_envelope_on_grid(fine_branch, spec.theta_9);
    envelope_fine_17 = fine_branch.envelope;
    delta_fem_previous = LOCAL_envelope_distance( ...
      medium_branch.envelope, coarse_branch.envelope);
    delta_fem = LOCAL_envelope_distance( ...
      envelope_fine_5, medium_branch.envelope);
    delta_n_previous = LOCAL_envelope_distance( ...
      n4_branch.envelope, n3_branch.envelope);
    delta_n_medium = LOCAL_envelope_distance( ...
      medium_branch.envelope, n4_branch.envelope);
    delta_n_fine = LOCAL_envelope_distance( ...
      envelope_fine_5, n4_fine_branch.envelope);
    delta_supercell = delta_n_fine + ...
      abs(delta_n_fine - delta_n_medium);
    delta_twist_previous = LOCAL_envelope_distance( ...
      envelope_fine_9, envelope_fine_5);
    delta_twist_sampling = LOCAL_envelope_distance( ...
      envelope_fine_17, envelope_fine_9);
    twist_half_width = diff(envelope_fine_17) / 2;
    delta_twist = twist_half_width + delta_twist_sampling;
    delta_algebraic = LOCAL_algebraic_change( ...
      fine_branch, loose_branch, spec.theta_5);
    delta_reference = delta_fem + delta_supercell + ...
      delta_twist + delta_algebraic;

    fem_pass = delta_fem <= spec.collapse_factor * delta_fem_previous || ...
      delta_fem < spec.resolution_terminal_fraction * gap_width;
    n_pass = delta_n_medium <= spec.collapse_factor * delta_n_previous || ...
      delta_n_medium < spec.resolution_terminal_fraction * gap_width;
    twist_pass = delta_twist_sampling <= ...
      spec.collapse_factor * delta_twist_previous || ...
      delta_twist_sampling < spec.resolution_terminal_fraction * gap_width;
    other_max = max([delta_fem, delta_supercell, delta_twist]);
    algebraic_pass = delta_algebraic <= ...
      spec.algebraic_relative_cap * max(1, abs(fine_branch.center)) && ...
      delta_algebraic <= spec.algebraic_component_fraction * other_max;
    total_pass = delta_reference <= spec.total_resolution_fraction * gap_width;
    branch_pass = fem_pass && n_pass && twist_pass && ...
      algebraic_pass && total_pass;
    if branch_pass
      reason = 'PASS';
    else
      reason = strjoin(LOCAL_failed_resolution_gates(fem_pass, n_pass, ...
        twist_pass, algebraic_pass, total_pass), ';');
      all_pass = false;
      failure_messages{end + 1, 1} = sprintf('branch %d: %s', ...
        fine_branch.id, reason); %#ok<AGROW>
    end
    artifacts.resolution_rows(end + 1, :) = {fine_branch.id, ...
      fine_branch.dimension, fine_branch.center, envelope_fine_17(1), ...
      envelope_fine_17(2), delta_fem_previous, delta_fem, ...
      delta_n_previous, delta_n_medium, delta_n_fine, ...
      delta_supercell, delta_twist_previous, delta_twist_sampling, ...
      twist_half_width, delta_twist, delta_algebraic, ...
      delta_reference, branch_pass, reason}; %#ok<AGROW>
    if branch_pass
      collection(end + 1) = struct('branch_id', fine_branch.id, ...
        'multiplicity', fine_branch.dimension, ...
        'reference_frequency', fine_branch.center, ...
        'reference_envelope', envelope_fine_17, ...
        'delta_fem', delta_fem, 'delta_supercell', delta_supercell, ...
        'delta_twist', delta_twist, ...
        'delta_algebraic', delta_algebraic, ...
        'delta_reference', delta_reference, ...
        'parity_signature', fine_branch.parity_signature, ...
        'mode_id_ambiguous', fine_branch.parity_ambiguous, ...
        'uncertainty_status', ...
        'EMPIRICAL_SENSITIVITY_ENVELOPE_NOT_AN_UPPER_BOUND'); %#ok<AGROW>
    end
  end
  if all_pass
    result = struct('pass', true, 'failure_code', '', 'reason', 'PASS', ...
      'collection', collection);
  else
    result = struct('pass', false, ...
      'failure_code', 'REFERENCE_RESOLUTION_UNRESOLVED', ...
      'reason', strjoin(failure_messages, ' | '), 'collection', []);
  end
end

function distance = LOCAL_envelope_distance(first, second)
  distance = max(abs(first - second));
end

function change = LOCAL_algebraic_change(tight_branch, loose_branch, grid)
  changes = zeros(1, numel(grid));
  for phase_index = 1:numel(grid)
    tight_index = LOCAL_theta_index(tight_branch.thetas, grid(phase_index));
    loose_index = LOCAL_theta_index(loose_branch.thetas, grid(phase_index));
    changes(phase_index) = LOCAL_envelope_distance( ...
      tight_branch.clusters{tight_index}.envelope, ...
      loose_branch.clusters{loose_index}.envelope);
  end
  change = max(changes);
end

function labels = LOCAL_failed_resolution_gates(fem_pass, n_pass, ...
    twist_pass, algebraic_pass, total_pass)
  labels = cell(0, 1);
  if ~fem_pass
    labels{end + 1, 1} = 'FEM_AXIS'; %#ok<AGROW>
  end
  if ~n_pass
    labels{end + 1, 1} = 'SUPERCELL_AXIS'; %#ok<AGROW>
  end
  if ~twist_pass
    labels{end + 1, 1} = 'TWIST_AXIS'; %#ok<AGROW>
  end
  if ~algebraic_pass
    labels{end + 1, 1} = 'ALGEBRAIC_AXIS'; %#ok<AGROW>
  end
  if ~total_pass
    labels{end + 1, 1} = 'TOTAL_ENVELOPE'; %#ok<AGROW>
  end
end
