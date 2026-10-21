function run_i4_1a(run_id)
%RUN_I4_1A Produce the frozen I4.1a diagnostic-ranked FEM candidate.
% Purpose:
%   Solve the independent fixed-beta bulk and line-defect problems with the
%   geometry-fitted conforming P1 finite-element method frozen in Sections
%   36--37.
% Input:
%   run_id - Must be exactly 'run-007'; it changes no scientific parameter.
% Output:
%   scientific-result.mat, conditional fields.mat, run.log, and a transient
%   terminal draft below output/run-007/execution-001/.
% Main algorithm:
%   Build nine fitted meshes, assemble P1 stiffness and weighted mass forms,
%   impose quasiperiodic phases, compute 72 bulk and 47 base defect spectra,
%   conditionally add 17 fine 60-root spectra, track every valid field-bearing
%   W3 object, and rank all components by the frozen lexicographic rule.
% Based on:
%   research/projects/eig-apost/implementation/i4/design-4-1a.md, Sections
%   36--37.
% Main changes:
%   Former gap, localization, coverage, parity, and resolution gates are
%   diagnostic labels rather than candidate-cancelling thresholds.
% Numerical goal:
%   Publish the top empirical FEM candidate whenever the finite schedule
%   contains a numerically valid field-bearing object intersecting W3.
% Notes:
%   This function reads only source constants and current-run caches. It never
%   reads Markdown, Git, historical output, BIE/QZ objects, or estimators.

  if nargin ~= 1 || ~(ischar(run_id) || (isstring(run_id) && isscalar(run_id)))
    error('I4A:InvalidRunId', 'The formal entry requires one run ID.');
  end
  run_id = char(run_id);
  if ~strcmp(run_id, 'run-007')
    error('I4A:InvalidRunId', 'The formal entry is fixed to run-007.');
  end
  execution_id = 'execution-001';
  entry_dir = fileparts(mfilename('fullpath'));
  output_dir = fullfile(entry_dir, 'output', run_id, execution_id);
  if ~exist(output_dir, 'dir')
    error('I4A:OutputUnavailable', ...
      'The fixed runner must create output/run-007/execution-001 first.');
  end
  work_dir = fullfile(output_dir, 'work');
  if exist(work_dir, 'dir') || exist(work_dir, 'file')
    error('I4A:OutputCollision', 'The current-run work directory exists.');
  end
  [made_work, work_message] = mkdir(work_dir);
  if ~made_work
    error('I4A:OutputUnavailable', 'Cannot create work: %s', work_message);
  end
  if exist(fullfile(output_dir, 'scientific-result.mat'), 'file') || ...
      exist(fullfile(output_dir, 'fields.mat'), 'file') || ...
      exist(fullfile(output_dir, 'run-summary.csv'), 'file')
    error('I4A:OutputCollision', 'A terminal execution-001 artifact exists.');
  end

  spec = LOCAL_spec();
  run_state = LOCAL_initial_state(run_id, execution_id, spec);
  mesh_registry = struct([]);
  mesh_failures = struct([]);
  bulk_inventory = struct([]);
  defect_inventory = struct([]);
  candidate_inventory = struct([]);
  tracking = struct([]);
  selected_candidate = struct([]);
  terminal_class = 'OPERATIONAL_FAILURE';
  terminal_status = 'RUNNING';
  first_failure = '';
  fprintf('I4.1a diagnostic-ranked fitted-FEM run %s/%s\n', ...
    run_id, execution_id);
  try
    LOCAL_check_environment(spec);
    LOCAL_log(output_dir, 'stage=mesh');
    [mesh_registry, mesh_failures] = LOCAL_mesh_registry(spec, work_dir);
    LOCAL_log(output_dir, 'stage=bulk');
    [bulk_inventory, run_state] = LOCAL_bulk_inventory( ...
      spec, mesh_registry, work_dir, output_dir, run_state);
    LOCAL_log(output_dir, 'stage=defect');
    [defect_inventory, run_state] = LOCAL_defect_inventory( ...
      spec, mesh_registry, work_dir, output_dir, run_state);
    LOCAL_log(output_dir, 'stage=candidate-ranking');
    [candidate_inventory, tracking] = LOCAL_candidate_inventory( ...
      spec, bulk_inventory, defect_inventory, mesh_registry, work_dir);
    if isempty(candidate_inventory.objects)
      LOCAL_raise('NO_VALID_FIELD_BEARING_W3_EIGENOBJECT', ...
        ['The complete finite schedule contains no numerically valid ' ...
        'field-bearing W3 eigenobject.']);
    end
    [candidate_inventory, selected_candidate] = LOCAL_rank_candidates( ...
      spec, bulk_inventory, defect_inventory, candidate_inventory, tracking);
    LOCAL_publish_fields(output_dir, mesh_registry, selected_candidate);
    terminal_class = 'SCIENTIFIC_READY';
    terminal_status = 'FEM_REFERENCE_CANDIDATE_READY';
    LOCAL_publish_scientific(output_dir, spec, run_state, mesh_registry, ...
      mesh_failures, bulk_inventory, defect_inventory, candidate_inventory, ...
      tracking, selected_candidate, terminal_class, terminal_status, ...
      first_failure);
  catch caught
    [failure_code, failure_message] = LOCAL_decode_failure(caught);
    terminal_status = failure_code;
    first_failure = failure_message;
    if LOCAL_is_scientific_terminal(failure_code)
      terminal_class = 'SCIENTIFIC_NEGATIVE';
      if ~strcmp(failure_code, 'CANONICAL_PUBLICATION_FAILURE')
        LOCAL_publish_scientific(output_dir, spec, run_state, mesh_registry, ...
          mesh_failures, bulk_inventory, defect_inventory, ...
          candidate_inventory, tracking, struct([]), terminal_class, ...
          terminal_status, first_failure);
      end
    end
    LOCAL_write_terminal_draft(output_dir, run_state, terminal_class, ...
      terminal_status, first_failure, selected_candidate);
    fprintf(2, 'Terminal status: %s\n%s\n', terminal_status, first_failure);
    if strcmp(terminal_class, 'OPERATIONAL_FAILURE')
      rethrow(caught);
    end
    return;
  end
  LOCAL_write_terminal_draft(output_dir, run_state, terminal_class, ...
    terminal_status, first_failure, selected_candidate);
  LOCAL_log(output_dir, ['terminal=' terminal_status]);
  fprintf('Terminal status: %s\n', terminal_status);
end
%% ==================== Frozen source specification ====================
% Section 31 retains the continuous model and all scientific schedules.

function spec = LOCAL_spec()
  spec = struct();
  spec.design_id = 'I4.1A-FEM-DIAGNOSTIC-RANKING-V2';
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
  spec.defect_main_nev = 48;
  spec.defect_expand_nev = 60;
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
  spec.planned_bulk_solves = 72;
  spec.planned_defect_solves = 47;
  spec.planned_base_solves = 119;
  spec.maximum_solves = 136;
  spec.search_windows = [1.65, 2.05; 1.25, 2.45; ...
    0.85, 2.85; 0.45, 3.25];
  spec.configuration_priority = {'fine', 'N4-fine', 'fem-medium', ...
    'N4-medium', 'N3-medium', 'fem-coarse', 'fine-loose-count'};
  spec.random_seed = 4101;
end

%% ==================== Run state and minimal publication ====================
% The runner owns resource.tsv and publishes run-summary.csv last.

function run_state = LOCAL_initial_state(run_id, execution_id, spec)
  run_state = struct('run_id', run_id, 'execution_id', execution_id, ...
    'attempted_solves', 0, 'completed_solves', 0, ...
    'planned_solves', spec.planned_base_solves, 'start_clock', tic);
end

function LOCAL_check_environment(spec)
  required = {'sparse', 'eigs', 'delaunayTriangulation', 'triangulation'};
  for index = 1:numel(required)
    if exist(required{index}, 'file') == 0 && ...
        exist(required{index}, 'class') == 0 && ...
        exist(required{index}, 'builtin') == 0
      LOCAL_raise('DEPENDENCY_UNAVAILABLE', ...
        sprintf('Required MATLAB object unavailable: %s', required{index}));
    end
  end
  if spec.planned_bulk_solves + spec.planned_defect_solves ~= 119 || ...
      spec.maximum_solves ~= 136 || spec.defect_main_nev ~= 48 || ...
      spec.defect_expand_nev ~= 60 || ...
      spec.period ~= 1 || spec.radius ~= 0.2 || spec.q_inside ~= 17 || ...
      spec.q_outside ~= 1 || spec.beta ~= 0.5 || spec.missing_column ~= 0
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'The source model or 72+47 schedule changed.');
  end
end

function LOCAL_log(output_dir, message)
  file_id = fopen(fullfile(output_dir, 'run.log'), 'a');
  if file_id < 0
    LOCAL_raise('OUTPUT_UNAVAILABLE', 'Cannot append run.log.');
  end
  cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
  fprintf(file_id, '%s\n', message);
end

function LOCAL_atomic_save(path, payload)
  partial = [path '.partial'];
  if exist(path, 'file') || exist(partial, 'file')
    LOCAL_raise('OUTPUT_COLLISION', 'A create-once MAT artifact exists.');
  end
  save(partial, 'payload', '-v7.3');
  [moved, message] = movefile(partial, path, 'f');
  if ~moved
    LOCAL_raise('OUTPUT_UNAVAILABLE', message);
  end
end

function LOCAL_save_spectrum(path, spectrum)
  LOCAL_atomic_save(path, spectrum);
end

function spectrum = LOCAL_load_spectrum(path)
  loaded = load(path, 'payload');
  spectrum = loaded.payload;
end

function LOCAL_write_terminal_draft(output_dir, run_state, terminal_class, ...
    terminal_status, first_failure, selected_candidate)
  collection_size = 0;
  lambda_ref_fem = NaN;
  k_ref_fem = NaN;
  if ~isempty(selected_candidate)
    collection_size = selected_candidate.collection_size;
    lambda_ref_fem = selected_candidate.lambda_ref_fem;
    k_ref_fem = selected_candidate.k_ref_fem;
  end
  file_id = fopen(fullfile(output_dir, 'work', 'matlab-terminal.tsv'), 'w');
  if file_id < 0
    LOCAL_raise('OUTPUT_UNAVAILABLE', 'Cannot write terminal draft.');
  end
  cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
  fprintf(file_id, 'terminal_class\t%s\n', terminal_class);
  fprintf(file_id, 'scientific_terminal\t%s\n', terminal_status);
  fprintf(file_id, 'execution_id\t%s\n', run_state.execution_id);
  fprintf(file_id, 'attempted_solves\t%d\n', run_state.attempted_solves);
  fprintf(file_id, 'completed_solves\t%d\n', run_state.completed_solves);
  fprintf(file_id, 'planned_solves\t%d\n', run_state.planned_solves);
  fprintf(file_id, 'collection_size\t%d\n', collection_size);
  fprintf(file_id, 'lambda_ref_fem\t%.17g\n', lambda_ref_fem);
  fprintf(file_id, 'k_ref_fem\t%.17g\n', k_ref_fem);
  fprintf(file_id, 'first_failure\t%s\n', ...
    strrep(strrep(first_failure, sprintf('\n'), ' '), sprintf('\t'), ' '));
  fprintf(file_id, 'matlab_elapsed_seconds\t%.9f\n', toc(run_state.start_clock));
  fprintf(file_id, 'claim_boundary\t%s\n', ...
    'EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY');
end

function yes = LOCAL_is_scientific_terminal(code)
  terminals = {'NO_VALID_FIELD_BEARING_W3_EIGENOBJECT', ...
    'CANONICAL_PUBLICATION_FAILURE'};
  yes = any(strcmp(terminals, code));
end

function LOCAL_raise(code, message)
  error(['I4A:' code], '%s', message);
end

function [code, message] = LOCAL_decode_failure(caught)
  if startsWith(caught.identifier, 'I4A:')
    code = caught.identifier(5:end);
  else
    code = 'EXECUTION_UNAVAILABLE';
  end
  message = caught.message;
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
    'nev', {}, 'role', {}, 'configuration', {});
  schedule = LOCAL_add_solve_group(schedule, 'fem-coarse', ...
    'defect-N5-s12-g24', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'fem-coarse');
  schedule = LOCAL_add_solve_group(schedule, 'fem-medium', ...
    'defect-N5-s18-g36', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'fem-medium');
  schedule = LOCAL_add_solve_group(schedule, 'fine', ...
    'defect-N5-s24-g48', spec.theta_17, 1e-11, ...
    spec.defect_main_nev, 'tight', 'fine');
  schedule = LOCAL_add_solve_group(schedule, 'N3-medium', ...
    'defect-N3-s18-g36', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'N3-medium');
  schedule = LOCAL_add_solve_group(schedule, 'N4-medium', ...
    'defect-N4-s18-g36', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'N4-medium');
  schedule = LOCAL_add_solve_group(schedule, 'N4-fine', ...
    'defect-N4-s24-g48', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'N4-fine');
  schedule = LOCAL_add_solve_group(schedule, 'fine-loose-count', ...
    'defect-N5-s24-g48', spec.theta_5, 1e-8, ...
    spec.defect_main_nev, 'loose-count', 'fine-loose-count');
end

function schedule = LOCAL_add_solve_group(schedule, prefix, mesh_id, ...
    phases, tolerance, nev, role, configuration)
  for phase_index = 1:numel(phases)
    item = struct();
    item.id = sprintf('%s-p%02d', prefix, phase_index);
    item.mesh_id = mesh_id;
    item.theta = phases(phase_index);
    item.tol = tolerance;
    item.nev = nev;
    item.role = role;
    item.configuration = configuration;
    schedule(end + 1) = item; %#ok<AGROW>
  end
end

%% ==================== Run state and atomic artifacts ====================
% These helpers implement stage-first progress and first-failure publication.

%% ==================== Geometry-fitted P1 meshes ====================
% Only checks that directly define or reject the frozen FEM object remain.

function [registry, failures] = LOCAL_mesh_registry(spec, work_dir)
  schedule = LOCAL_mesh_schedule();
  registry = struct('id', {}, 'path', {}, 'descriptor', {});
  failures = struct('mesh_id', {}, 'code', {}, 'reason', {});
  for index = 1:numel(schedule)
    try
      mesh = LOCAL_build_mesh(spec, schedule(index));
    catch caught
      [code, reason] = LOCAL_decode_failure(caught);
      recordable = strcmp(code, 'MESH_QUALITY_UNRESOLVED') || ...
        strcmp(code, 'QUASIPERIODIC_SEAM_UNRESOLVED');
      if strcmp(code, 'EXECUTION_UNAVAILABLE') || startsWith(code, 'OUTPUT_') || ...
          ~recordable
        rethrow(caught);
      end
      failures(end + 1) = struct('mesh_id', schedule(index).id, ...
        'code', code, 'reason', reason); %#ok<AGROW>
      continue;
    end
    path = fullfile(work_dir, ['mesh-' schedule(index).id '.mat']);
    LOCAL_atomic_save(path, mesh);
    descriptor = struct('id', mesh.id, 'kind', mesh.kind, 'N', mesh.N, ...
      's', mesh.s, 'n_gamma', mesh.n_gamma, ...
      'node_count', size(mesh.points, 1), ...
      'triangle_count', size(mesh.triangles, 1), ...
      'reduced_dof', mesh.reduced_dof, ...
      'area_deficit', mesh.area_deficit, ...
      'hausdorff_defect', mesh.hausdorff_defect, ...
      'cross_interface_count', mesh.cross_interface_count, ...
      'reflection_stiffness_defect', mesh.reflection_stiffness_defect, ...
      'reflection_mass_defect', mesh.reflection_mass_defect);
    registry(end + 1) = struct('id', mesh.id, 'path', path, ...
      'descriptor', descriptor); %#ok<AGROW>
  end
end

function mesh = LOCAL_load_mesh(registry, work_dir, mesh_id) %#ok<INUSD>
  index = find(strcmp({registry.id}, mesh_id));
  if numel(index) ~= 1
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('Mesh registry lookup failed for %s.', mesh_id));
  end
  loaded = load(registry(index).path, 'payload');
  mesh = loaded.payload;
end

function mesh = LOCAL_build_mesh(spec, mesh_spec)
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
    distance = hypot(raw_points(:, 1) - disk_centers(center_index), ...
      raw_points(:, 2));
    remove_point = remove_point | abs(distance - spec.radius) < h / 3;
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
  cell_boundaries = (ceil(xmin - 0.5):floor(xmax - 0.5)) + 0.5;
  cell_boundaries = cell_boundaries(cell_boundaries > xmin & ...
    cell_boundaries < xmax);
  for boundary_index = 1:numel(cell_boundaries)
    line_points = [cell_boundaries(boundary_index) * ...
      ones(numel(y_grid), 1), y_grid(:)];
    [raw_points, raw_constraints] = LOCAL_append_polyline( ...
      raw_points, raw_constraints, line_points, false);
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
    [raw_points, raw_constraints] = LOCAL_append_polyline( ...
      raw_points, raw_constraints, polygon, true);
    raw_points = [raw_points; inner_ring; outer_ring]; %#ok<AGROW>
  end
  [~, first_indices, point_map] = unique( ...
    round(raw_points / spec.coordinate_tolerance), 'rows');
  points = raw_points(first_indices, :);
  constraints = point_map(raw_constraints);
  constraints = sort(constraints, 2);
  constraints(constraints(:, 1) == constraints(:, 2), :) = [];
  constraints = unique(constraints, 'rows');
  dt = delaunayTriangulation(points, constraints);
  points = dt.Points;
  triangles = dt.ConnectivityList;
  if any(~isfinite(points), 'all') || any(~isfinite(triangles), 'all') || ...
      any(triangles(:) < 1) || any(triangles(:) > size(points, 1))
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s has invalid coordinates or connectivity.', mesh_spec.id));
  end
  [reflection_index, reflection_defect] = ...
    LOCAL_reflection_map(points, spec.coordinate_tolerance);
  if reflection_defect > spec.coordinate_tolerance || ...
      LOCAL_unpaired_constraint_count(constraints, reflection_index) > 0
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s fails reflection-compatible constraints.', mesh_spec.id));
  end
  [triangles, repair] = LOCAL_reflection_closed_triangles( ...
    spec, mesh_spec.id, points, triangles, reflection_index);
  if ~repair.pass
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', repair.reason);
  end
  signed_twice_area = LOCAL_signed_twice_area(points, triangles);
  flipped = signed_twice_area < 0;
  triangles(flipped, [2, 3]) = triangles(flipped, [3, 2]);
  signed_twice_area = LOCAL_signed_twice_area(points, triangles);
  canonical_triangles = sort(triangles, 2);
  if any(signed_twice_area <= 0) || ...
      size(unique(canonical_triangles, 'rows'), 1) ~= size(triangles, 1)
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s has nonpositive or duplicate triangles.', mesh_spec.id));
  end
  active_edges = unique(sort([triangles(:, [1, 2]); ...
    triangles(:, [2, 3]); triangles(:, [3, 1])], 2), 'rows');
  if any(~ismember(constraints, active_edges, 'rows'))
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s lost a required constraint.', mesh_spec.id));
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
  cross_interface_count = LOCAL_cross_interface_count( ...
    points, triangles, disk_centers, spec.radius, spec.constraint_tolerance);
  [unpaired_triangle_count, material_mismatch_count] = ...
    LOCAL_triangle_reflection_diagnostics( ...
    triangles, material_inside, reflection_index);
  if cross_interface_count > 0 || unpaired_triangle_count > 0 || ...
      material_mismatch_count > 0
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s fails fitted-interface/material checks.', mesh_spec.id));
  end
  [stiffness_full, mass_full, mass_center, mass_core, mass_tail] = ...
    LOCAL_assemble_p1(spec, mesh_spec, points, triangles, centroids, ...
    material_inside);
  if any(~isfinite(nonzeros(stiffness_full))) || ...
      any(~isfinite(nonzeros(mass_full)))
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s assembly contains nonfinite entries.', mesh_spec.id));
  end
  node_count = size(points, 1);
  reflection = sparse((1:node_count).', reflection_index, 1, ...
    node_count, node_count);
  reflection_stiffness_defect = norm(stiffness_full - ...
    reflection' * stiffness_full * reflection, 1) / ...
    max(1, norm(stiffness_full, 1));
  reflection_mass_defect = norm(mass_full - ...
    reflection' * mass_full * reflection, 1) / ...
    max(1, norm(mass_full, 1));
  periodic = LOCAL_periodic_maps( ...
    points, xmin, xmax, ymin, ymax, spec.coordinate_tolerance);
  hausdorff_defect = spec.radius * (1 - cos(pi / mesh_spec.n_gamma));
  mesh = struct('id', mesh_spec.id, 'kind', mesh_spec.kind, ...
    'N', mesh_spec.N, 's', mesh_spec.s, 'n_gamma', mesh_spec.n_gamma, ...
    'points', points, 'triangles', triangles, ...
    'material_inside', material_inside, 'disk_centers', disk_centers, ...
    'stiffness_full', stiffness_full, 'mass_full', mass_full, ...
    'mass_center', mass_center, 'mass_core', mass_core, ...
    'mass_tail', mass_tail, 'reflection_index', reflection_index, ...
    'periodic', periodic, 'reduced_dof', max(periodic.master_index), ...
    'area_deficit', 1 - mesh_spec.n_gamma * ...
    sin(2 * pi / mesh_spec.n_gamma) / (2 * pi), ...
    'hausdorff_defect', hausdorff_defect, ...
    'cross_interface_count', cross_interface_count, ...
    'reflection_stiffness_defect', reflection_stiffness_defect, ...
    'reflection_mass_defect', reflection_mass_defect, ...
    'reflection_accuracy_pass', ...
    reflection_stiffness_defect <= spec.reflection_tolerance && ...
    reflection_mass_defect <= spec.reflection_tolerance, ...
    'hausdorff_accuracy_pass', mesh_spec.n_gamma ~= 48 || ...
    hausdorff_defect <= spec.finest_hausdorff_cap);
end

function count = LOCAL_cross_interface_count( ...
    points, triangles, disk_centers, radius, tolerance)
  mask = false(size(triangles, 1), 1);
  for center_index = 1:numel(disk_centers)
    radii = zeros(size(triangles, 1), 3);
    for vertex_index = 1:3
      vertex = points(triangles(:, vertex_index), :);
      radii(:, vertex_index) = hypot( ...
        vertex(:, 1) - disk_centers(center_index), vertex(:, 2));
    end
    mask = mask | (any(radii < radius - tolerance, 2) & ...
      any(radii > radius + tolerance, 2));
  end
  count = nnz(mask);
end

function count = LOCAL_unpaired_constraint_count(constraints, reflection_index)
  canonical_constraints = sort(constraints, 2);
  reflected_constraints = reshape( ...
    reflection_index(constraints(:)), size(constraints));
  reflected_constraints = sort(reflected_constraints, 2);
  count = nnz(~ismember(reflected_constraints, ...
    canonical_constraints, 'rows'));
end

function [triangles, diagnostic] = LOCAL_reflection_closed_triangles( ...
    spec, mesh_id, points, triangles, reflection_index)
  original_triangles = triangles;
  canonical_original = sort(original_triangles, 2);
  reflected_original = reshape( ...
    reflection_index(original_triangles(:)), size(original_triangles));
  reflected_original = sort(reflected_original, 2);
  paired_original = ismember(reflected_original, canonical_original, 'rows');
  centroid_x = mean(reshape(points(original_triangles(:), 1), ...
    size(original_triangles)), 2);
  unpaired_left = ~paired_original & ...
    centroid_x < -spec.coordinate_tolerance;
  unpaired_right = ~paired_original & ...
    centroid_x > spec.coordinate_tolerance;
  unpaired_center = ~paired_original & ...
    ~(unpaired_left | unpaired_right);

  reflected_left = reshape( ...
    reflection_index(original_triangles(unpaired_left, :)), [], 3);
  repaired_triangles = [original_triangles(paired_original, :); ...
    original_triangles(unpaired_left, :); reflected_left];
  repaired_canonical = sort(repaired_triangles, 2);
  duplicate_count = size(repaired_canonical, 1) - ...
    size(unique(repaired_canonical, 'rows'), 1);
  [~, triangle_order] = sortrows(repaired_canonical);
  triangles = repaired_triangles(triangle_order, :);

  domain_area = (max(points(:, 1)) - min(points(:, 1))) * ...
    (max(points(:, 2)) - min(points(:, 2)));
  repaired_area = sum(abs(LOCAL_signed_twice_area(points, triangles))) / 2;
  area_defect = abs(repaired_area - domain_area) / max(1, domain_area);
  diagnostic = struct();
  diagnostic.unresolved_triangle_count = nnz(unpaired_center) + ...
    abs(nnz(unpaired_left) - nnz(unpaired_right));
  diagnostic.duplicate_triangle_count = duplicate_count;
  diagnostic.area_defect = area_defect;
  diagnostic.pass = diagnostic.unresolved_triangle_count == 0 && ...
    duplicate_count == 0 && ...
    area_defect <= spec.constraint_tolerance;
  if nnz(unpaired_center) > 0
    diagnostic.reason = sprintf( ...
      '%s has %d unresolved zero-centroid reflection-tie triangles.', ...
      mesh_id, nnz(unpaired_center));
  elseif nnz(unpaired_left) ~= nnz(unpaired_right)
    diagnostic.reason = sprintf( ...
      '%s has unbalanced left/right reflection-tie inventories %d/%d.', ...
      mesh_id, nnz(unpaired_left), nnz(unpaired_right));
  elseif duplicate_count > 0
    diagnostic.reason = sprintf( ...
      '%s reflection tie resolution produced %d duplicate triangles.', ...
      mesh_id, duplicate_count);
  elseif area_defect > spec.constraint_tolerance
    diagnostic.reason = sprintf( ...
      '%s repaired connectivity has relative area defect %.17g.', ...
      mesh_id, area_defect);
  else
    diagnostic.reason = 'PASS';
  end
end

function [unpaired_triangle_count, material_pair_mismatch_count] = ...
    LOCAL_triangle_reflection_diagnostics( ...
    triangles, material_inside, reflection_index)
  canonical_triangles = sort(triangles, 2);
  reflected_triangles = reshape( ...
    reflection_index(triangles(:)), size(triangles));
  reflected_triangles = sort(reflected_triangles, 2);
  [found, reflected_partner] = ismember( ...
    reflected_triangles, canonical_triangles, 'rows');
  unique_partner_count = numel(unique(reflected_partner(found)));
  unpaired_triangle_count = nnz(~found) + nnz(found) - ...
    unique_partner_count;
  material_pair_mismatch_count = 0;
  if all(found) && unique_partner_count == size(triangles, 1)
    triangle_ids = (1:size(triangles, 1)).';
    material_mismatch = material_inside ~= ...
      material_inside(reflected_partner);
    material_pair_mismatch_count = nnz( ...
      material_mismatch & triangle_ids <= reflected_partner);
  end
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

%% ==================== Quasiperiodic operators and low spectra ====================
% Raw Hermitian gates precede one canonical upper-triangle construction.

function [pair, diagnostic] = LOCAL_phase_reduce( ...
    spec, mesh, phase_x, phase_kind)
  phases = exp(1i * (phase_x * double(mesh.periodic.x_slave) + ...
    spec.beta * double(mesh.periodic.y_slave)));
  node_count = size(mesh.points, 1);
  reduced_dof = max(mesh.periodic.master_index);
  prolongation = sparse((1:node_count).', ...
    mesh.periodic.master_index, phases, node_count, reduced_dof);
  stiffness_raw = prolongation' * mesh.stiffness_full * prolongation;
  mass_raw = prolongation' * mesh.mass_full * prolongation;
  x_residual = norm(prolongation(mesh.periodic.right_nodes, :) - ...
    exp(1i * phase_x) * prolongation(mesh.periodic.left_nodes, :), inf);
  y_residual = norm(prolongation(mesh.periodic.top_nodes, :) - ...
    exp(1i * spec.beta) * prolongation(mesh.periodic.bottom_nodes, :), inf);
  seam_residual = max(x_residual, y_residual);
  if mesh.periodic.coordinate_mismatch > spec.coordinate_tolerance || ...
      seam_residual > spec.seam_tolerance
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', sprintf( ...
      '%s phase %.17g fails seam identities.', mesh.id, phase_x));
  end
  stiffness = LOCAL_checked_hermitian( ...
    spec, stiffness_raw, false, 'SPECTRUM_INVENTORY_TRUNCATED');
  [mass, mass_factor] = LOCAL_checked_hermitian( ...
    spec, mass_raw, true, 'SPECTRUM_INVENTORY_TRUNCATED');
  pair = struct('stiffness', stiffness, 'mass', mass, ...
    'mass_factor', mass_factor, 'prolongation', prolongation);
  diagnostic = struct('phase_kind', phase_kind, 'phase', phase_x, ...
    'seam_residual', seam_residual);
end

function [canonical, factor] = LOCAL_checked_hermitian( ...
    spec, raw, require_spd, terminal_code)
  factor = [];
  if size(raw, 1) ~= size(raw, 2) || any(~isfinite(nonzeros(raw)))
    LOCAL_raise(terminal_code, 'A required operator is non-square or nonfinite.');
  end
  raw_defect = norm(raw - raw', 1) / max(1, norm(raw, 1));
  if ~isfinite(raw_defect) || raw_defect > spec.hermitian_tolerance
    LOCAL_raise(terminal_code, sprintf( ...
      'Raw Hermitian defect %.17g exceeds tolerance.', raw_defect));
  end
  canonical = LOCAL_canonical_hermitian(raw);
  if ~isequal(canonical, canonical') || ...
      any(~isfinite(nonzeros(canonical)))
    LOCAL_raise(terminal_code, 'Canonical Hermitian construction failed.');
  end
  if require_spd
    if any(real(diag(canonical)) <= 0)
      LOCAL_raise(terminal_code, 'Reduced mass has a nonpositive diagonal.');
    end
    [factor, flag] = chol(canonical);
    if flag ~= 0
      LOCAL_raise(terminal_code, 'Reduced mass is not positive definite.');
    end
  end
end

function [spectrum, phase_diagnostic] = LOCAL_low_spectrum( ...
    spec, mesh, phase_x, tolerance, requested_nev, role, phase_kind)
  [pair, phase_diagnostic] = LOCAL_phase_reduce( ...
    spec, mesh, phase_x, phase_kind);
  reduced_dof = size(pair.stiffness, 1);
  if reduced_dof <= requested_nev + 2
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      sprintf('%s has insufficient reduced DOF.', mesh.id));
  end
  master_rows = accumarray(mesh.periodic.master_index, ...
    (1:size(mesh.points, 1)).', [], @min);
  master_points = mesh.points(master_rows, :);
  start_vector = exp(1i * (0.371 * master_points(:, 1) + ...
    0.233 * master_points(:, 2))) + ...
    0.17 * cos(1.113 * master_points(:, 1) - ...
    0.719 * master_points(:, 2));
  start_vector = start_vector / norm(start_vector, 2);
  options = struct('tol', tolerance, 'maxit', spec.eigs_maxit, ...
    'p', min([reduced_dof - 1, max(2 * requested_nev, ...
    spec.eigs_subspace_main), spec.eigs_subspace_cap]), ...
    'v0', start_vector, 'issym', true, 'isreal', false);
  rng(spec.random_seed, 'twister');
  [vectors_reduced, diagonal_values, solver_flag] = eigs( ...
    pair.stiffness, pair.mass, requested_nev, 'smallestabs', options);
  eigenvalues_complex = diag(diagonal_values);
  if solver_flag ~= 0 || numel(eigenvalues_complex) ~= requested_nev || ...
      size(vectors_reduced, 2) ~= requested_nev || ...
      any(~isfinite(eigenvalues_complex)) || ...
      any(~isfinite(vectors_reduced), 'all')
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g returned an incomplete inventory.', mesh.id, phase_x));
  end
  relative_imaginary = abs(imag(eigenvalues_complex)) ./ ...
    max(1, abs(real(eigenvalues_complex)));
  if any(relative_imaginary > spec.imaginary_tolerance) || ...
      any(real(eigenvalues_complex) <= 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'A generalized eigenvalue is nonpositive or nonreal.');
  end
  [eigenvalues, order] = sort(real(eigenvalues_complex), 'ascend');
  vectors_reduced = vectors_reduced(:, order);
  for root_index = 1:requested_nev
    value = real(vectors_reduced(:, root_index)' * pair.mass * ...
      vectors_reduced(:, root_index));
    if ~isfinite(value) || value <= 0
      LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', 'Invalid mass norm.');
    end
    vectors_reduced(:, root_index) = ...
      vectors_reduced(:, root_index) / sqrt(value);
  end
  frequencies = sqrt(eigenvalues);
  stiffness_norm = norm(pair.stiffness, 1);
  mass_norm = norm(pair.mass, 1);
  residuals = zeros(requested_nev, 1);
  for root_index = 1:requested_nev
    vector = vectors_reduced(:, root_index);
    residuals(root_index) = norm(pair.stiffness * vector - ...
      eigenvalues(root_index) * pair.mass * vector, 2) / ...
      ((stiffness_norm + abs(eigenvalues(root_index)) * mass_norm) * ...
      norm(vector, 2));
  end
  cluster_ids = LOCAL_cluster_ids(spec, frequencies, residuals);
  if strcmp(phase_kind, 'defect-theta')
    vectors_reduced = LOCAL_normalize_defect_clusters( ...
      spec, pair.mass, vectors_reduced, cluster_ids);
  end
  vectors_full = pair.prolongation * vectors_reduced;
  orthogonality_defect = norm(vectors_reduced' * pair.mass * ...
    vectors_reduced - eye(requested_nev), 2);
  for root_index = 1:requested_nev
    vector = vectors_reduced(:, root_index);
    residuals(root_index) = norm(pair.stiffness * vector - ...
      eigenvalues(root_index) * pair.mass * vector, 2) / ...
      ((stiffness_norm + abs(eigenvalues(root_index)) * mass_norm) * ...
      norm(vector, 2));
  end
  if orthogonality_defect > spec.orthogonality_tolerance || ...
      any(residuals > spec.residual_tolerance) || any(diff(frequencies) < 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'Residual, orthogonality, or ordering gate failed.');
  end
  verified_clusters = LOCAL_cluster_ids(spec, frequencies, residuals);
  if ~isequal(verified_clusters, cluster_ids)
    LOCAL_raise('NUMERICAL_OBJECT_INVALID', ...
      'Cluster normalization changed the cluster inventory.');
  end
  multiplicities = accumarray(cluster_ids, 1);
  if sum(multiplicities) ~= requested_nev
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'Cluster multiplicities do not sum to the root count.');
  end
  spectrum = struct('mesh_id', mesh.id, 'phase', phase_x, 'role', role, ...
    'requested_nev', requested_nev, 'solver_flag', solver_flag, ...
    'eigenvalues', eigenvalues, 'frequencies', frequencies, ...
    'residuals', residuals, 'cluster_ids', cluster_ids, ...
    'cluster_multiplicities', multiplicities, ...
    'vectors_full', vectors_full, ...
    'orthogonality_defect', orthogonality_defect);
end

function vectors_reduced = LOCAL_normalize_defect_clusters( ...
    spec, mass, vectors_reduced, cluster_ids)
  for cluster_id = unique(cluster_ids).'
    roots = find(cluster_ids == cluster_id);
    initial = vectors_reduced(:, roots);
    [~, factor] = LOCAL_checked_hermitian( ...
      spec, initial' * mass * initial, true, ...
      'NUMERICAL_OBJECT_INVALID');
    normalized = initial / factor;
    if norm(normalized' * mass * normalized - eye(numel(roots)), 2) > ...
        spec.orthogonality_tolerance
      LOCAL_raise('NUMERICAL_OBJECT_INVALID', ...
        'Cluster mass normalization failed.');
    end
    vectors_reduced(:, roots) = normalized;
  end
end

function canonical = LOCAL_canonical_hermitian(raw)
  strict_upper = triu(raw, 1);
  real_diagonal = real(diag(raw));
  if issparse(raw)
    diagonal_matrix = spdiags(real_diagonal, 0, size(raw, 1), size(raw, 2));
  else
    diagonal_matrix = diag(real_diagonal);
  end
  canonical = strict_upper + strict_upper' + diagonal_matrix;
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

%% ==================== Frozen bulk and defect inventories ====================
% The exact schedule contains 72 bulk and 47 defect eigensolves.

function [bulk_inventory, run_state] = LOCAL_bulk_inventory( ...
    spec, registry, work_dir, output_dir, run_state)
  levels(1) = struct('id', 'B1', 'mesh_id', 'bulk-s12-g24', ...
    'alphas', spec.bulk_alpha_17, 'tol', 1e-9);
  levels(2) = struct('id', 'B2', 'mesh_id', 'bulk-s18-g36', ...
    'alphas', spec.bulk_alpha_17, 'tol', 1e-10);
  levels(3) = struct('id', 'B4', 'mesh_id', 'bulk-s24-g48', ...
    'alphas', spec.bulk_alpha_33, 'tol', 1e-11);
  sentinels = struct('id', {}, 'phase', {}, 'valid', {}, 'path', {}, ...
    'failure_code', {}, 'failure_reason', {}, 'mismatch', {}, ...
    'cluster_match', {});
  bulk_inventory = struct('levels', struct(), ...
    'count_sentinels', sentinels, 'gap_diagnostic', struct());
  for level_index = 1:numel(levels)
    level = levels(level_index);
    record = struct('mesh_id', level.mesh_id, 'alphas', level.alphas, ...
      'frequencies', NaN(spec.bulk_main_nev, numel(level.alphas)), ...
      'residuals', NaN(spec.bulk_main_nev, numel(level.alphas)), ...
      'valid', false(1, numel(level.alphas)), ...
      'paths', {cell(1, numel(level.alphas))}, ...
      'failure_codes', {cell(1, numel(level.alphas))}, ...
      'failure_reasons', {cell(1, numel(level.alphas))});
    for phase_index = 1:numel(level.alphas)
      solve_id = sprintf('%s-p%02d', level.id, phase_index);
      [valid, spectrum, path, code, reason] = LOCAL_attempt_spectrum( ...
        spec, registry, work_dir, solve_id, level.mesh_id, ...
        level.alphas(phase_index), level.tol, spec.bulk_main_nev, ...
        'bulk-main', 'bulk-alpha', false);
      run_state = LOCAL_record_solve( ...
        run_state, output_dir, solve_id, valid);
      record.valid(phase_index) = valid;
      record.paths{phase_index} = path;
      record.failure_codes{phase_index} = code;
      record.failure_reasons{phase_index} = reason;
      if valid
        record.frequencies(:, phase_index) = spectrum.frequencies;
        record.residuals(:, phase_index) = spectrum.residuals;
      end
    end
    bulk_inventory.levels.(level.id) = record;
  end
  b4 = bulk_inventory.levels.B4;
  bulk_inventory.levels.B3 = struct('mesh_id', b4.mesh_id, ...
    'alphas', b4.alphas(1:2:end), ...
    'frequencies', b4.frequencies(:, 1:2:end), ...
    'residuals', b4.residuals(:, 1:2:end), ...
    'valid', b4.valid(1:2:end), 'paths', {b4.paths(1:2:end)}, ...
    'failure_codes', {b4.failure_codes(1:2:end)}, ...
    'failure_reasons', {b4.failure_reasons(1:2:end)});

  bulk_inventory.gap_diagnostic = LOCAL_bulk_gap_diagnostic( ...
    spec, bulk_inventory.levels);
  for sentinel_index = 1:numel(spec.count_phases)
    phase = spec.count_phases(sentinel_index);
    solve_id = sprintf('B4-count-p%02d', sentinel_index);
    [valid, spectrum, path, code, reason] = LOCAL_attempt_spectrum( ...
      spec, registry, work_dir, solve_id, 'bulk-s24-g48', phase, ...
      1e-11, spec.count_nev, 'bulk-count', 'bulk-alpha', false);
    run_state = LOCAL_record_solve( ...
      run_state, output_dir, solve_id, valid);
    mismatch = NaN;
    cluster_match = false;
    main_index = find(abs(spec.bulk_alpha_33 - phase) < 1e-14, 1);
    if valid && ~isempty(main_index) && b4.valid(main_index)
      mismatch = max(abs(spectrum.frequencies(1:40) - ...
        b4.frequencies(1:40, main_index)));
      cluster_match = isequal(spectrum.cluster_ids(1:40), ...
        LOCAL_cluster_ids(spec, b4.frequencies(:, main_index), ...
        b4.residuals(:, main_index)));
    end
    bulk_inventory.count_sentinels(end + 1) = struct( ...
      'id', solve_id, 'phase', phase, 'valid', valid, 'path', path, ...
      'failure_code', code, 'failure_reason', reason, ...
      'mismatch', mismatch, 'cluster_match', cluster_match); %#ok<AGROW>
  end
end

function [defect_inventory, run_state] = LOCAL_defect_inventory( ...
    spec, registry, work_dir, output_dir, run_state)
  schedule = LOCAL_defect_schedule(spec);
  if numel(schedule) ~= spec.planned_defect_solves
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'The base defect schedule does not contain exactly 47 solves.');
  end
  entries = LOCAL_empty_defect_entries();
  for solve_index = 1:numel(schedule)
    [entry, run_state] = LOCAL_run_defect_item( ...
      spec, registry, work_dir, output_dir, run_state, ...
      schedule(solve_index));
    entries(end + 1) = entry; %#ok<AGROW>
  end
  fine_base = entries(strcmp({entries.configuration}, 'fine'));
  coverage_48_w3 = LOCAL_all_slice_ceiling_pass( ...
    fine_base, spec.search_windows(4, 2) + spec.upper_sentinel_margin, 17);
  expansion_performed = ~coverage_48_w3;
  if expansion_performed
    run_state.planned_solves = spec.maximum_solves;
    expansion = LOCAL_add_solve_group(LOCAL_empty_defect_schedule(), ...
      'fine-expand60', 'defect-N5-s24-g48', spec.theta_17, 1e-11, ...
      spec.defect_expand_nev, 'expansion-60', 'fine');
    for solve_index = 1:numel(expansion)
      [entry, run_state] = LOCAL_run_defect_item( ...
        spec, registry, work_dir, output_dir, run_state, ...
        expansion(solve_index));
      entries(end + 1) = entry; %#ok<AGROW>
    end
  end
  defect_inventory = struct('entries', entries, ...
    'base_schedule_count', 47, ...
    'expansion_performed', expansion_performed, ...
    'actual_schedule_count', numel(entries));
  defect_inventory.root_coverage = LOCAL_root_coverage(spec, entries);
  defect_inventory.count_agreement_diagnostic = ...
    LOCAL_defect_count_diagnostic(spec, entries);
end

function schedule = LOCAL_empty_defect_schedule()
  schedule = struct('id', {}, 'mesh_id', {}, 'theta', {}, 'tol', {}, ...
    'nev', {}, 'role', {}, 'configuration', {});
end

function entries = LOCAL_empty_defect_entries()
  entries = struct('id', {}, 'configuration', {}, 'mesh_id', {}, ...
    'theta', {}, 'tol', {}, 'nev', {}, 'role', {}, 'valid', {}, ...
    'path', {}, 'failure_code', {}, 'failure_reason', {}, 'summary', {});
end

function [entry, run_state] = LOCAL_run_defect_item( ...
    spec, registry, work_dir, output_dir, run_state, item)
  [valid, spectrum, path, code, reason] = LOCAL_attempt_spectrum( ...
    spec, registry, work_dir, item.id, item.mesh_id, item.theta, ...
    item.tol, item.nev, item.role, 'defect-theta', true);
  run_state = LOCAL_record_solve(run_state, output_dir, item.id, valid);
  summary = spectrum;
  if valid
    summary.vectors_full = [];
  end
  entry = struct('id', item.id, 'configuration', item.configuration, ...
    'mesh_id', item.mesh_id, 'theta', item.theta, 'tol', item.tol, ...
    'nev', item.nev, 'role', item.role, 'valid', valid, 'path', path, ...
    'failure_code', code, 'failure_reason', reason, 'summary', summary);
end

function [valid, spectrum, path, code, reason] = LOCAL_attempt_spectrum( ...
    spec, registry, work_dir, solve_id, mesh_id, phase, tolerance, ...
    requested_nev, role, phase_kind, keep_fields)
  valid = false;
  spectrum = struct([]);
  path = '';
  code = '';
  reason = '';
  try
    mesh = LOCAL_load_mesh(registry, work_dir, mesh_id);
    spectrum = LOCAL_low_spectrum(spec, mesh, phase, tolerance, ...
      requested_nev, role, phase_kind);
    path = fullfile(work_dir, [solve_id '.mat']);
    saved = spectrum;
    if ~keep_fields
      saved.vectors_full = [];
    end
    LOCAL_save_spectrum(path, saved);
    valid = true;
  catch caught
    [code, reason] = LOCAL_decode_failure(caught);
    recordable = strcmp(code, 'QUASIPERIODIC_SEAM_UNRESOLVED') || ...
      strcmp(code, 'MESH_QUALITY_UNRESOLVED') || ...
      strcmp(code, 'SPECTRUM_INVENTORY_TRUNCATED') || ...
      strcmp(code, 'NUMERICAL_OBJECT_INVALID');
    if strcmp(code, 'EXECUTION_UNAVAILABLE') || startsWith(code, 'OUTPUT_') || ...
        ~recordable
      rethrow(caught);
    end
  end
end

function run_state = LOCAL_record_solve( ...
    run_state, output_dir, solve_id, valid)
  run_state.attempted_solves = run_state.attempted_solves + 1;
  if valid
    run_state.completed_solves = run_state.completed_solves + 1;
    status = 'VALID';
  else
    status = 'INVALID';
  end
  LOCAL_log(output_dir, sprintf('attempt=%d/%d completed=%d id=%s status=%s', ...
    run_state.attempted_solves, run_state.planned_solves, ...
    run_state.completed_solves, solve_id, status));
end

function pass = LOCAL_all_slice_ceiling_pass(entries, threshold, expected)
  pass = numel(entries) == expected && all([entries.valid]);
  if pass
    ceilings = arrayfun(@(entry) entry.summary.frequencies(end), entries);
    pass = all(ceilings > threshold);
  end
end

function diagnostic = LOCAL_bulk_gap_diagnostic(spec, levels)
  names = {'B1', 'B2', 'B3', 'B4'};
  diagnostic = struct('levels', struct(), 'target_gap', struct());
  for index = 1:numel(names)
    diagnostic.levels.(names{index}) = LOCAL_level_gap_diagnostic( ...
      spec, levels.(names{index}));
  end
  gaps = cellfun(@(name) diagnostic.levels.(name), names, ...
    'UniformOutput', false);
  available = all(cellfun(@(gap) numel(gap.candidate_indices) == 1, gaps));
  if available
    indices = cellfun(@(gap) gap.candidate_indices(1), gaps);
    available = all(indices == indices(end));
  end
  if ~available
    diagnostic.target_gap = struct('available', false, 'index', NaN, ...
      'raw', [NaN, NaN], 'safe', [NaN, NaN], 'width', NaN, ...
      'refinement_pass', false, 'safe_pass', false, ...
      'classification', 'BULK_GAP_UNRESOLVED_DIAGNOSTIC');
    return;
  end
  gap_b1 = gaps{1}.open_gaps(indices(1), :);
  gap_b2 = gaps{2}.open_gaps(indices(2), :);
  gap_b3 = gaps{3}.open_gaps(indices(3), :);
  gap_b4 = gaps{4}.open_gaps(indices(4), :);
  width = diff(gap_b4);
  delta_lower = abs(gap_b4(1) - gap_b2(1)) + ...
    abs(gap_b4(1) - gap_b3(1));
  delta_upper = abs(gap_b4(2) - gap_b2(2)) + ...
    abs(gap_b4(2) - gap_b3(2));
  safe = [gap_b4(1) + delta_lower, gap_b4(2) - delta_upper];
  refinement_pass = (abs(gap_b4(1) - gap_b2(1)) <= ...
    abs(gap_b2(1) - gap_b1(1)) || ...
    abs(gap_b4(1) - gap_b3(1)) < spec.bulk_terminal_fraction * width) && ...
    (abs(gap_b4(2) - gap_b2(2)) <= ...
    abs(gap_b2(2) - gap_b1(2)) || ...
    abs(gap_b4(2) - gap_b3(2)) < spec.bulk_terminal_fraction * width);
  safe_pass = safe(2) > safe(1) && diff(safe) >= spec.safe_gap_fraction * width;
  diagnostic.target_gap = struct('available', true, ...
    'index', indices(end), 'raw', gap_b4, 'safe', safe, 'width', width, ...
    'refinement_pass', refinement_pass, 'safe_pass', safe_pass, ...
    'classification', 'BULK_GAP_DIAGNOSTIC_ONLY');
end

function diagnostic = LOCAL_level_gap_diagnostic(spec, level)
  valid_columns = find(level.valid);
  if isempty(valid_columns)
    diagnostic = struct('valid_phase_count', 0, ...
      'open_gaps', zeros(0, 2), 'candidate_indices', zeros(0, 1), ...
      'classification', 'BULK_GAP_UNRESOLVED_DIAGNOSTIC');
    return;
  end
  frequency_matrix = level.frequencies(:, valid_columns);
  band_lower = min(frequency_matrix, [], 2);
  band_upper = max(frequency_matrix, [], 2);
  lower_edges = band_upper(1:(end - 1));
  upper_edges = band_lower(2:end);
  open = upper_edges > lower_edges;
  open_gaps = [lower_edges, upper_edges];
  open_gaps(~open, :) = NaN;
  contains_cue = lower_edges < spec.cue_interval(1) & ...
    upper_edges > spec.cue_interval(2);
  inside_guard = lower_edges > spec.guard_interval(1) & ...
    upper_edges < spec.guard_interval(2);
  candidates = find(open & contains_cue & inside_guard);
  diagnostic = struct('valid_phase_count', numel(valid_columns), ...
    'open_gaps', open_gaps, 'candidate_indices', candidates, ...
    'classification', 'BULK_GAP_DIAGNOSTIC_ONLY');
end

function coverage = LOCAL_root_coverage(spec, entries)
  coverage = struct();
  for config_index = 1:numel(spec.configuration_priority)
    name = spec.configuration_priority{config_index};
    selected = LOCAL_effective_entries(entries, name);
    expected = 5;
    if strcmp(name, 'fine')
      expected = 17;
    end
    ceilings = NaN(1, numel(selected));
    for index = 1:numel(selected)
      if selected(index).valid
        ceilings(index) = selected(index).summary.frequencies(end);
      end
    end
    covered_by_window = false(1, 4);
    covered_slices = zeros(1, 4);
    minimum_margin = NaN(1, 4);
    for window_index = 1:4
      margin = ceilings - (spec.search_windows(window_index, 2) + ...
        spec.upper_sentinel_margin);
      covered_slices(window_index) = nnz(margin > 0);
      covered_by_window(window_index) = numel(selected) == expected && ...
        all(isfinite(margin)) && all(margin > 0);
      if any(isfinite(margin))
        minimum_margin(window_index) = min(margin(isfinite(margin)));
      end
    end
    last = find(covered_by_window, 1, 'last');
    if isempty(last)
      largest_covered_window = -1;
    else
      largest_covered_window = last - 1;
    end
    field_name = LOCAL_field_name(name);
    coverage.(field_name) = struct('configuration', name, ...
      'expected_slices', expected, 'valid_slices', nnz(isfinite(ceilings)), ...
      'ceilings', ceilings, 'covered_by_window', covered_by_window, ...
      'covered_slices', covered_slices, ...
      'minimum_margin', minimum_margin, ...
      'largest_covered_window', largest_covered_window, ...
      'classification', LOCAL_coverage_classification(covered_by_window));
  end
end

function label = LOCAL_coverage_classification(covered_by_window)
  if covered_by_window(4)
    label = 'SPECTRUM_COVERED_THROUGH_W3';
  else
    label = 'SPECTRUM_COVERAGE_PARTIAL';
  end
end

function selected = LOCAL_effective_entries(entries, name)
  base = entries(strcmp({entries.configuration}, name) & ...
    ~strcmp({entries.role}, 'expansion-60'));
  if ~strcmp(name, 'fine')
    selected = base;
    return;
  end
  expansion = entries(strcmp({entries.role}, 'expansion-60'));
  selected = base;
  for index = 1:numel(selected)
    replacement = find(abs([expansion.theta] - selected(index).theta) < ...
      1e-13 & [expansion.valid], 1);
    if ~isempty(replacement)
      selected(index) = expansion(replacement);
    end
  end
  [~, order] = sort([selected.theta]);
  selected = selected(order);
end

function diagnostic = LOCAL_defect_count_diagnostic(spec, entries)
  diagnostic = struct('theta', {}, 'mismatch', {}, 'cluster_match', {}, ...
    'pass', {});
  loose = entries(strcmp({entries.configuration}, 'fine-loose-count'));
  fine = LOCAL_effective_entries(entries, 'fine');
  for index = 1:numel(loose)
    tight_index = find(abs([fine.theta] - loose(index).theta) < 1e-13, 1);
    mismatch = NaN;
    cluster_match = false;
    if loose(index).valid && ~isempty(tight_index) && fine(tight_index).valid
      count = min(loose(index).nev, fine(tight_index).nev);
      mismatch = max(abs(loose(index).summary.frequencies(1:count) - ...
        fine(tight_index).summary.frequencies(1:count)));
      cluster_match = isequal( ...
        loose(index).summary.cluster_ids(1:count), ...
        fine(tight_index).summary.cluster_ids(1:count));
    end
    diagnostic(end + 1) = struct('theta', loose(index).theta, ...
      'mismatch', mismatch, 'cluster_match', cluster_match, ...
      'pass', isfinite(mismatch) && ...
      mismatch <= spec.defect_count_frequency_tolerance && ...
      cluster_match); %#ok<AGROW>
  end
end

%% ==================== Complete defect inventory ====================
% These helpers compute the fixed 47-solve union and empty edge-buffer gate.

%% ==================== W3 objects and threshold-free tracking ====================
% Sections 36.3--36.4 and 37.1 retain every valid field-bearing W3 object.

function [inventory, tracking] = LOCAL_candidate_inventory( ...
    spec, bulk_inventory, defect_inventory, registry, work_dir)
  objects = LOCAL_empty_objects();
  invalid_objects = struct('solve_id', {}, 'cluster_id', {}, ...
    'code', {}, 'reason', {});
  configurations = struct('name', {}, 'priority', {}, 'slices', {});
  next_object_id = 1;
  for config_index = 1:numel(spec.configuration_priority)
    name = spec.configuration_priority{config_index};
    entries = LOCAL_effective_entries(defect_inventory.entries, name);
    slices = struct('theta', {}, 'theta_index', {}, 'object_ids', {}, ...
      'solve_id', {}, 'valid', {}, 'failure_reason', {});
    for slice_index = 1:numel(entries)
      entry = entries(slice_index);
      object_ids = zeros(0, 1);
      failure_reason = entry.failure_reason;
      if entry.valid
        try
          mesh = LOCAL_load_mesh(registry, work_dir, entry.mesh_id);
          spectrum = LOCAL_load_spectrum(entry.path);
          [clusters, invalid] = LOCAL_w3_clusters( ...
            spec, mesh, spectrum, bulk_inventory.gap_diagnostic);
          for invalid_index = 1:numel(invalid)
            invalid_objects(end + 1) = struct( ...
              'solve_id', entry.id, ...
              'cluster_id', invalid(invalid_index).cluster_id, ...
              'code', invalid(invalid_index).code, ...
              'reason', invalid(invalid_index).reason); %#ok<AGROW>
          end
          for cluster_index = 1:numel(clusters)
            object = clusters(cluster_index);
            object.object_id = next_object_id;
            object.seed_candidate_id = next_object_id;
            object.configuration = name;
            object.configuration_priority = config_index;
            object.solve_id = entry.id;
            object.mesh_id = entry.mesh_id;
            object.theta = entry.theta;
            object.theta_index = slice_index;
            objects(end + 1) = object; %#ok<AGROW>
            object_ids(end + 1, 1) = next_object_id; %#ok<AGROW>
            next_object_id = next_object_id + 1;
          end
        catch caught
          [code, failure_reason] = LOCAL_decode_failure(caught);
          if strcmp(code, 'EXECUTION_UNAVAILABLE') || startsWith(code, 'OUTPUT_')
            rethrow(caught);
          end
          invalid_objects(end + 1) = struct('solve_id', entry.id, ...
            'cluster_id', NaN, 'code', code, ...
            'reason', failure_reason); %#ok<AGROW>
        end
      end
      slices(end + 1) = struct('theta', entry.theta, ...
        'theta_index', slice_index, 'object_ids', object_ids, ...
        'solve_id', entry.id, 'valid', entry.valid, ...
        'failure_reason', failure_reason); %#ok<AGROW>
    end
    configurations(end + 1) = struct('name', name, ...
      'priority', config_index, 'slices', slices); %#ok<AGROW>
  end
  edges = LOCAL_tracking_edges(spec, objects, configurations);
  tracking = LOCAL_tracking_components(objects, edges);
  inventory = struct('objects', objects, ...
    'invalid_objects', invalid_objects, ...
    'configurations', configurations, 'candidates', struct([]), ...
    'ordered_candidate_ids', zeros(0, 1));
end

function objects = LOCAL_empty_objects()
  objects = struct('object_id', {}, 'seed_candidate_id', {}, ...
    'configuration', {}, 'configuration_priority', {}, ...
    'solve_id', {}, 'mesh_id', {}, 'theta', {}, 'theta_index', {}, ...
    'cluster_id', {}, 'root_index', {}, 'root_indices', {}, ...
    'dimension', {}, 'eigenvalues', {}, 'frequencies', {}, ...
    'lambda_envelope', {}, 'k_envelope', {}, 'subspace', {}, ...
    'residual_max', {}, 'L0_min', {}, 'Lcore_min', {}, 'tail_max', {}, ...
    'localization_status', {}, 'localization_reason', {}, ...
    'parity_values', {}, 'parity_label', {}, ...
    'parity_status', {}, 'parity_reason', {}, ...
    'common_core_samples', {}, 'common_core_weights', {}, ...
    'common_core_valid', {}, 'common_core_reason', {}, ...
    'window_label', {}, 'window_edge_straddle', {}, 'gap_label', {});
end

function [clusters, invalid] = LOCAL_w3_clusters( ...
    spec, mesh, spectrum, bulk_gap_diagnostic)
  clusters = LOCAL_empty_objects();
  invalid = struct('cluster_id', {}, 'code', {}, 'reason', {});
  w3 = spec.search_windows(4, :);
  cluster_numbers = unique(spectrum.cluster_ids).';
  reflection = sparse((1:size(mesh.points, 1)).', ...
    mesh.reflection_index, 1, size(mesh.points, 1), size(mesh.points, 1));
  restricted_mass = {mesh.mass_center, mesh.mass_core, mesh.mass_tail};
  for index = 1:numel(cluster_numbers)
    cluster_id = cluster_numbers(index);
    roots = find(spectrum.cluster_ids == cluster_id);
    k_envelope = [min(spectrum.frequencies(roots)), ...
      max(spectrum.frequencies(roots))];
    if k_envelope(2) < w3(1) || k_envelope(1) > w3(2)
      continue;
    end
    try
      subspace = spectrum.vectors_full(:, roots);
      if isempty(subspace) || any(~isfinite(subspace), 'all')
        LOCAL_raise('NUMERICAL_OBJECT_INVALID', ...
          'A W3 cluster has no finite field subspace.');
      end
      field_gram = LOCAL_checked_hermitian(spec, ...
        subspace' * mesh.mass_full * subspace, true, ...
        'NUMERICAL_OBJECT_INVALID');
      if norm(field_gram - eye(numel(roots)), 2) > ...
          spec.orthogonality_tolerance
        LOCAL_raise('NUMERICAL_OBJECT_INVALID', ...
          'A W3 cluster field is not mass normalized.');
      end
      localization_values = [NaN, NaN, NaN];
      localization_status = 'UNAVAILABLE';
      localization_reason = '';
      try
        restricted_values = cell(1, 3);
        for restricted_index = 1:3
          gram = LOCAL_checked_hermitian(spec, ...
            subspace' * restricted_mass{restricted_index} * subspace, ...
            false, 'LOCALIZATION_DIAGNOSTIC_UNAVAILABLE');
          restricted_values{restricted_index} = real(eig(gram));
          if any(~isfinite(restricted_values{restricted_index}))
            LOCAL_raise('LOCALIZATION_DIAGNOSTIC_UNAVAILABLE', ...
              'A restricted Gram has nonfinite eigenvalues.');
          end
        end
        localization_values = [min(restricted_values{1}), ...
          min(restricted_values{2}), max(restricted_values{3})];
        localization_status = 'AVAILABLE';
      catch caught
        [~, localization_reason] = LOCAL_decode_failure(caught);
      end
      parity_values = [];
      parity_label = 'parity-unavailable';
      parity_status = 'UNAVAILABLE';
      parity_reason = 'NOT_ENDPOINT_TWIST';
      if abs(spectrum.phase) < 1e-13 || abs(spectrum.phase - pi) < 1e-13
        try
          parity = LOCAL_checked_hermitian(spec, ...
            subspace' * mesh.mass_full * reflection * subspace, false, ...
            'PARITY_DIAGNOSTIC_UNAVAILABLE');
          parity_values = real(eig(parity));
          if any(~isfinite(parity_values))
            LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', ...
              'The parity Gram has nonfinite eigenvalues.');
          end
          parity_label = LOCAL_parity_label(parity_values, ...
            spec.parity_threshold);
          parity_status = 'AVAILABLE';
          parity_reason = '';
        catch caught
          [~, parity_reason] = LOCAL_decode_failure(caught);
          parity_values = [];
          parity_label = 'parity-unavailable';
        end
      end
      common_samples = [];
      common_weights = [];
      common_valid = false;
      common_reason = '';
      try
        [common_samples, common_weights] = LOCAL_sample_subspace( ...
          spec, mesh, subspace);
        [~, factor] = LOCAL_checked_hermitian(spec, ...
          common_samples' * (common_weights .* common_samples), true, ...
          'TRACKING_DIAGNOSTIC_UNAVAILABLE');
        common_samples = common_samples / factor;
        common_valid = true;
      catch caught
        [~, common_reason] = LOCAL_decode_failure(caught);
        common_samples = [];
        common_weights = [];
      end
      object = LOCAL_empty_object();
      object.cluster_id = cluster_id;
      object.root_index = roots(1);
      object.root_indices = roots;
      object.dimension = numel(roots);
      object.eigenvalues = spectrum.eigenvalues(roots);
      object.frequencies = spectrum.frequencies(roots);
      object.lambda_envelope = [min(object.eigenvalues), ...
        max(object.eigenvalues)];
      object.k_envelope = k_envelope;
      object.subspace = subspace;
      object.residual_max = max(spectrum.residuals(roots));
      object.L0_min = localization_values(1);
      object.Lcore_min = localization_values(2);
      object.tail_max = localization_values(3);
      object.localization_status = localization_status;
      object.localization_reason = localization_reason;
      object.parity_values = parity_values;
      object.parity_label = parity_label;
      object.parity_status = parity_status;
      object.parity_reason = parity_reason;
      object.common_core_samples = common_samples;
      object.common_core_weights = common_weights;
      object.common_core_valid = common_valid;
      object.common_core_reason = common_reason;
      object.window_label = LOCAL_window_label(spec, k_envelope);
      object.window_edge_straddle = ...
        k_envelope(1) < w3(1) || k_envelope(2) > w3(2);
      object.gap_label = LOCAL_gap_label( ...
        bulk_gap_diagnostic, k_envelope);
      clusters(end + 1) = object; %#ok<AGROW>
    catch caught
      [code, reason] = LOCAL_decode_failure(caught);
      if strcmp(code, 'EXECUTION_UNAVAILABLE') || startsWith(code, 'OUTPUT_')
        rethrow(caught);
      end
      invalid(end + 1) = struct('cluster_id', cluster_id, ...
        'code', code, 'reason', reason); %#ok<AGROW>
    end
  end
end

function object = LOCAL_empty_object()
  empty = LOCAL_empty_objects();
  object = struct();
  names = fieldnames(empty);
  for index = 1:numel(names)
    object.(names{index}) = [];
  end
end

function label = LOCAL_window_label(spec, envelope)
  label = 'expansion-shell-3';
  for window_index = 1:4
    window = spec.search_windows(window_index, :);
    if envelope(2) >= window(1) && envelope(1) <= window(2)
      if window_index == 1
        label = 'cue-member';
      else
        label = sprintf('expansion-shell-%d', window_index - 1);
      end
      return;
    end
  end
end

function label = LOCAL_gap_label(diagnostic, envelope)
  b4 = diagnostic.levels.B4;
  valid_gap = all(isfinite(b4.open_gaps), 2);
  containing = find(valid_gap & ...
    b4.open_gaps(:, 1) <= envelope(1) & ...
    b4.open_gaps(:, 2) >= envelope(2), 1);
  if isempty(containing)
    if b4.valid_phase_count == 0
      label = 'bulk-gap-unresolved';
    else
      label = 'embedded-or-bulk-overlap';
    end
    return;
  end
  target = diagnostic.target_gap;
  if target.available && containing == target.index && ...
      all(isfinite(target.safe)) && envelope(1) > target.safe(1) && ...
      envelope(2) < target.safe(2)
    label = 'gap-interior';
  else
    label = 'gap-edge-or-safe-buffer';
  end
end

function label = LOCAL_parity_label(values, threshold)
  if isempty(values)
    label = 'parity-unavailable';
  elseif all(values >= threshold)
    label = 'even';
  elseif all(values <= -threshold)
    label = 'odd';
  else
    label = 'mixed/ambiguous';
  end
end

function edges = LOCAL_tracking_edges(spec, objects, configurations)
  edges = LOCAL_empty_tracking_edges();
  for config_index = 1:numel(configurations)
    slices = configurations(config_index).slices;
    for slice_index = 2:numel(slices)
      new_edges = LOCAL_assign_object_sets(spec, objects, ...
        slices(slice_index - 1).object_ids, ...
        slices(slice_index).object_ids, 'twist', 'within-configuration');
      edges = [edges, new_edges]; %#ok<AGROW>
    end
  end
  for target_index = 2:numel(configurations)
    target = configurations(target_index);
    for target_slice = 1:numel(target.slices)
      if isempty(target.slices(target_slice).object_ids)
        continue;
      end
      source_ids = zeros(0, 1);
      for source_index = 1:(target_index - 1)
        source = configurations(source_index);
        match = find(abs([source.slices.theta] - ...
          target.slices(target_slice).theta) < 1e-13, 1);
        if ~isempty(match) && ~isempty(source.slices(match).object_ids)
          source_ids = source.slices(match).object_ids;
          break;
        end
      end
      if isempty(source_ids)
        continue;
      end
      axis = LOCAL_tracking_axis(target.name);
      new_edges = LOCAL_assign_object_sets(spec, objects, source_ids, ...
        target.slices(target_slice).object_ids, axis, ...
        'cross-configuration');
      edges = [edges, new_edges]; %#ok<AGROW>
    end
  end
end

function edges = LOCAL_empty_tracking_edges()
  edges = struct('source_object_id', {}, 'target_object_id', {}, ...
    'axis', {}, 'kind', {}, 'overlap', {}, ...
    'frequency_distance', {}, 'low_overlap', {}, ...
    'dimension_changed', {}, 'mutual_best', {});
end

function axis = LOCAL_tracking_axis(configuration)
  if strcmp(configuration, 'fine-loose-count')
    axis = 'algebraic';
  elseif startsWith(configuration, 'N')
    axis = 'supercell';
  else
    axis = 'fem';
  end
end

function edges = LOCAL_assign_object_sets( ...
    spec, objects, source_ids, target_ids, axis, kind)
  edges = LOCAL_empty_tracking_edges();
  if isempty(source_ids) || isempty(target_ids)
    return;
  end
  overlap = NaN(numel(source_ids), numel(target_ids));
  distance = NaN(size(overlap));
  for source_index = 1:numel(source_ids)
    source = objects(source_ids(source_index));
    for target_index = 1:numel(target_ids)
      target = objects(target_ids(target_index));
      distance(source_index, target_index) = ...
        LOCAL_envelope_distance(source.k_envelope, target.k_envelope);
      if source.common_core_valid && target.common_core_valid
        try
          overlap(source_index, target_index) = ...
            LOCAL_common_core_overlap(source, target);
        catch
          overlap(source_index, target_index) = NaN;
        end
      end
    end
  end
  pairs = LOCAL_maximum_overlap_assignment( ...
    objects, source_ids, target_ids, overlap, distance);
  for pair_index = 1:size(pairs, 1)
    source_index = pairs(pair_index, 1);
    target_index = pairs(pair_index, 2);
    source = objects(source_ids(source_index));
    target = objects(target_ids(target_index));
    threshold = spec.cluster_overlap_min;
    if source.dimension == 1 && target.dimension == 1
      threshold = spec.simple_overlap_min;
    end
    [~, source_best] = max(overlap(source_index, :));
    [~, target_best] = max(overlap(:, target_index));
    mutual_best = source_best == target_index && ...
      target_best == source_index;
    edges(end + 1) = struct( ...
      'source_object_id', source.object_id, ...
      'target_object_id', target.object_id, 'axis', axis, 'kind', kind, ...
      'overlap', overlap(source_index, target_index), ...
      'frequency_distance', distance(source_index, target_index), ...
      'low_overlap', overlap(source_index, target_index) < threshold, ...
      'dimension_changed', source.dimension ~= target.dimension, ...
      'mutual_best', mutual_best); %#ok<AGROW>
  end
end

function pairs = LOCAL_maximum_overlap_assignment( ...
    objects, source_ids, target_ids, overlap, distance)
  source_count = numel(source_ids);
  target_count = numel(target_ids);
  total_count = source_count + target_count;
  tuple_count = 6;
  costs = Inf(total_count, total_count, tuple_count);
  for source_index = 1:source_count
    source = objects(source_ids(source_index));
    for target_index = 1:target_count
      if isfinite(overlap(source_index, target_index))
        target = objects(target_ids(target_index));
        tuple = [-overlap(source_index, target_index), 0, ...
          distance(source_index, target_index), target.root_index, ...
          source.seed_candidate_id, target.object_id];
        costs(source_index, target_index, :) = reshape(tuple, 1, 1, []);
      end
    end
    tuple = [0, 1, 0, 0, source.seed_candidate_id, 0];
    costs(source_index, target_count + source_index, :) = ...
      reshape(tuple, 1, 1, []);
  end
  for target_index = 1:target_count
    row = source_count + target_index;
    tuple = [0, 1, 0, ...
      objects(target_ids(target_index)).root_index, 0, ...
      objects(target_ids(target_index)).object_id];
    costs(row, target_index, :) = reshape(tuple, 1, 1, []);
    costs(row, (target_count + 1):end, :) = 0;
  end
  assignment = LOCAL_lexicographic_hungarian(costs);
  pairs = zeros(0, 2);
  for source_index = 1:source_count
    target_index = assignment(source_index);
    if target_index >= 1 && target_index <= target_count && ...
        isfinite(overlap(source_index, target_index))
      pairs(end + 1, :) = [source_index, target_index]; %#ok<AGROW>
    end
  end
end

function assignment = LOCAL_lexicographic_hungarian(costs)
  count = size(costs, 1);
  tuple_count = size(costs, 3);
  row_potential = zeros(count, tuple_count);
  column_potential = zeros(count + 1, tuple_count);
  column_row = zeros(count + 1, 1);
  predecessor = zeros(count + 1, 1);
  for row = 1:count
    column_row(1) = row;
    column = 1;
    best = Inf(count, tuple_count);
    reached = false(1, count);
    used = false(1, count + 1);
    while true
      used(column) = true;
      active_row = column_row(column);
      delta = Inf(1, tuple_count);
      next_column = 0;
      for candidate = 1:count
        if used(candidate + 1)
          continue;
        end
        current = reshape(costs(active_row, candidate, :), 1, []) - ...
          row_potential(active_row, :) - column_potential(candidate + 1, :);
        if ~reached(candidate) || LOCAL_lex_less(current, best(candidate, :))
          best(candidate, :) = current;
          predecessor(candidate + 1) = column;
          reached(candidate) = true;
        end
        if LOCAL_lex_less(best(candidate, :), delta)
          delta = best(candidate, :);
          next_column = candidate + 1;
        end
      end
      if next_column == 0 || ~all(isfinite(delta))
        LOCAL_raise('TRACKING_IMPLEMENTATION_FAILURE', ...
          'The deterministic assignment has no finite completion.');
      end
      for used_column = find(used)
        assigned_row = column_row(used_column);
        if assigned_row > 0
          row_potential(assigned_row, :) = ...
            row_potential(assigned_row, :) + delta;
        end
        column_potential(used_column, :) = ...
          column_potential(used_column, :) - delta;
      end
      for candidate = 1:count
        if ~used(candidate + 1) && reached(candidate)
          best(candidate, :) = best(candidate, :) - delta;
        end
      end
      column = next_column;
      if column_row(column) == 0
        break;
      end
    end
    while true
      previous = predecessor(column);
      column_row(column) = column_row(previous);
      column = previous;
      if column == 1
        break;
      end
    end
  end
  assignment = zeros(count, 1);
  for column = 2:(count + 1)
    if column_row(column) > 0
      assignment(column_row(column)) = column - 1;
    end
  end
end

function less = LOCAL_lex_less(first, second)
  less = false;
  for index = 1:numel(first)
    if first(index) < second(index)
      less = true;
      return;
    elseif first(index) > second(index)
      return;
    end
  end
end

function tracking = LOCAL_tracking_components(objects, edges)
  parent = 1:numel(objects);
  for edge_index = 1:numel(edges)
    first = LOCAL_find_parent(parent, edges(edge_index).source_object_id);
    second = LOCAL_find_parent(parent, edges(edge_index).target_object_id);
    if first ~= second
      parent(second) = first;
    end
  end
  labels = zeros(1, numel(objects));
  for object_index = 1:numel(objects)
    labels(object_index) = LOCAL_find_parent(parent, object_index);
  end
  roots = unique(labels, 'stable');
  anchor_keys = zeros(numel(roots), 4);
  for index = 1:numel(roots)
    members = find(labels == roots(index));
    keys = [[objects(members).configuration_priority].', ...
      [objects(members).theta_index].', [objects(members).root_index].', ...
      [objects(members).object_id].'];
    keys = sortrows(keys, 1:4);
    anchor_keys(index, :) = keys(1, :);
  end
  [~, order] = sortrows(anchor_keys, 1:4);
  components = struct('candidate_id', {}, 'realization_ids', {});
  for candidate_id = 1:numel(order)
    members = find(labels == roots(order(candidate_id)));
    components(end + 1) = struct('candidate_id', candidate_id, ...
      'realization_ids', members); %#ok<AGROW>
  end
  tracking = struct('edges', edges, 'components', components);
end

function root = LOCAL_find_parent(parent, node)
  root = node;
  while parent(root) ~= root
    root = parent(root);
  end
end

%% ==================== Lexicographic ranking and publication ====================
% Sections 36.5--36.7 and 37.2 define the total rank and published realization.

function [inventory, selected] = LOCAL_rank_candidates( ...
    spec, bulk_inventory, defect_inventory, inventory, tracking)
  candidates = struct([]);
  for index = 1:numel(tracking.components)
    candidate = LOCAL_candidate_record(spec, bulk_inventory, ...
      defect_inventory, inventory.objects, tracking.edges, ...
      tracking.components(index));
    if isempty(candidates)
      candidates = candidate;
    else
      candidates(end + 1) = candidate; %#ok<AGROW>
    end
  end
  rank_matrix = vertcat(candidates.rank_key);
  [~, order] = sortrows(rank_matrix, 1:size(rank_matrix, 2));
  ordered_ids = [candidates(order).candidate_id].';
  inventory.candidates = candidates;
  inventory.ordered_candidate_ids = ordered_ids;
  selected = candidates(order(1));
  selected.collection_size = numel(candidates);
end

function candidate = LOCAL_candidate_record( ...
    spec, bulk_inventory, defect_inventory, objects, edges, component)
  ids = component.realization_ids;
  member_edge = false(1, numel(edges));
  for edge_index = 1:numel(edges)
    member_edge(edge_index) = ismember(edges(edge_index).source_object_id, ids) && ...
      ismember(edges(edge_index).target_object_id, ids);
  end
  linked_edges = edges(member_edge);
  axes = unique({linked_edges.axis});
  configurations = unique({objects(ids).configuration});
  if isempty(linked_edges)
    linked_twists = 0;
  else
    linked_ids = unique([[linked_edges.source_object_id], ...
      [linked_edges.target_object_id]]);
    linked_twists = numel(unique([objects(linked_ids).theta]));
  end
  n_axes = numel(axes);
  n_config = max(numel(configurations) - 1, 0);
  n_theta = max(linked_twists - 1, 0);
  deltas = LOCAL_candidate_deltas(spec, objects, ids);
  delta_values = [deltas.delta_fem, deltas.delta_supercell, ...
    deltas.delta_twist, deltas.delta_algebraic];
  missing_count = nnz(~isfinite(delta_values));
  finite_sum = sum(delta_values(isfinite(delta_values)));
  if missing_count == 0
    delta_ref_obs = finite_sum;
    resolution_status = 'EMPIRICAL_RESOLUTION_COMPLETE';
  else
    delta_ref_obs = NaN;
    resolution_status = 'EMPIRICAL_RESOLUTION_PARTIAL';
  end
  residual_max = max([objects(ids).residual_max]);
  localization_available = strcmp( ...
    {objects(ids).localization_status}, 'AVAILABLE');
  if all(localization_available)
    localization_center = min([objects(ids).L0_min]);
    localization_core = min([objects(ids).Lcore_min]);
    tail_max = max([objects(ids).tail_max]);
  else
    localization_center = NaN;
    localization_core = NaN;
    tail_max = NaN;
  end
  parity_rank = LOCAL_candidate_parity_rank(objects(ids));
  [covered_window, covered_slices, ceiling_margin] = ...
    LOCAL_candidate_coverage(defect_inventory.root_coverage, objects(ids));
  anchor_key = [[objects(ids).configuration_priority].', ...
    [objects(ids).theta_index].', [objects(ids).root_index].', ...
    [objects(ids).object_id].'];
  [~, anchor_order] = sortrows(anchor_key, 1:4);
  anchor = objects(ids(anchor_order(1)));
  publication = LOCAL_publication_realization( ...
    spec, objects, ids, component.candidate_id);
  classifications = LOCAL_candidate_classifications(spec, ...
    bulk_inventory.gap_diagnostic, publication, localization_center, ...
    localization_core, tail_max, parity_rank, resolution_status, ...
    covered_window, covered_slices, ceiling_margin, objects(ids));
  rank_key = [-n_axes, -n_config, -n_theta, missing_count, finite_sum, ...
    LOCAL_nan_min(residual_max), ...
    LOCAL_nan_negative(localization_center), ...
    LOCAL_nan_negative(localization_core), LOCAL_nan_min(tail_max), ...
    parity_rank, -covered_window, -covered_slices, ...
    LOCAL_nan_negative(ceiling_margin), ...
    anchor.configuration_priority, anchor.theta_index, ...
    anchor.root_index, component.candidate_id];
  if n_axes == 0 && n_config == 0 && n_theta == 0
    tracking_status = 'UNTRACKED_SINGLE_CONFIGURATION';
  else
    tracking_status = 'TRACKED_WITH_DIAGNOSTIC_EDGES';
  end
  caveat = missing_count > 0 || parity_rank > 0 || ...
    ~all(isfinite([localization_center, localization_core, tail_max])) || ...
    localization_center < spec.localization_center_min || ...
    localization_core < spec.localization_core_min || ...
    tail_max > spec.tail_max || covered_window < 3 || ...
    ~strcmp(publication.gap_label, 'gap-interior');
  if caveat
    candidate_status = 'EMPIRICAL_FEM_CANDIDATE_WITH_CAVEATS';
  else
    candidate_status = 'EMPIRICAL_FEM_REFERENCE_CANDIDATE';
  end
  candidate = struct('candidate_id', component.candidate_id, ...
    'realization_ids', ids, 'n_axes', n_axes, 'n_config', n_config, ...
    'n_theta', n_theta, 'tracking_status', tracking_status, ...
    'delta_fem', deltas.delta_fem, ...
    'delta_supercell', deltas.delta_supercell, ...
    'delta_twist', deltas.delta_twist, ...
    'delta_algebraic', deltas.delta_algebraic, ...
    'delta_ref_obs', delta_ref_obs, ...
    'resolution_status', resolution_status, ...
    'residual_max', residual_max, 'localization_center', localization_center, ...
    'localization_core', localization_core, 'tail_max', tail_max, ...
    'parity_rank', parity_rank, 'covered_window', covered_window, ...
    'covered_slices', covered_slices, 'ceiling_margin', ceiling_margin, ...
    'rank_key', rank_key, 'classification', {classifications}, ...
    'candidate_status', candidate_status, 'publication', publication, ...
    'lambda_ref_fem', publication.lambda_ref_fem, ...
    'k_ref_fem', publication.k_ref_fem);
end

function deltas = LOCAL_candidate_deltas(spec, objects, ids)
  fine_5 = LOCAL_component_envelope(objects, ids, 'fine', spec.theta_5);
  fine_9 = LOCAL_component_envelope(objects, ids, 'fine', spec.theta_9);
  fine_17 = LOCAL_component_envelope(objects, ids, 'fine', spec.theta_17);
  medium_5 = LOCAL_component_envelope( ...
    objects, ids, 'fem-medium', spec.theta_5);
  n4_medium_5 = LOCAL_component_envelope( ...
    objects, ids, 'N4-medium', spec.theta_5);
  n4_fine_5 = LOCAL_component_envelope( ...
    objects, ids, 'N4-fine', spec.theta_5);
  delta_fem = LOCAL_optional_distance(fine_5, medium_5);
  fine_n = LOCAL_optional_distance(fine_5, n4_fine_5);
  medium_n = LOCAL_optional_distance(medium_5, n4_medium_5);
  if isfinite(fine_n) && isfinite(medium_n)
    delta_supercell = fine_n + abs(fine_n - medium_n);
  else
    delta_supercell = NaN;
  end
  twist_sampling = LOCAL_optional_distance(fine_17, fine_9);
  if all(isfinite(fine_17)) && isfinite(twist_sampling)
    delta_twist = diff(fine_17) / 2 + twist_sampling;
  else
    delta_twist = NaN;
  end
  delta_algebraic = LOCAL_component_algebraic_change( ...
    objects, ids, spec.theta_5);
  deltas = struct('delta_fem', delta_fem, ...
    'delta_supercell', delta_supercell, ...
    'delta_twist', delta_twist, 'delta_algebraic', delta_algebraic);
end

function envelope = LOCAL_component_envelope(objects, ids, name, grid)
  envelope = [NaN, NaN];
  lower = NaN(1, numel(grid));
  upper = NaN(1, numel(grid));
  for phase_index = 1:numel(grid)
    selected = ids(strcmp({objects(ids).configuration}, name) & ...
      abs([objects(ids).theta] - grid(phase_index)) < 1e-13);
    if isempty(selected)
      return;
    end
    values = vertcat(objects(selected).k_envelope);
    lower(phase_index) = min(values(:, 1));
    upper(phase_index) = max(values(:, 2));
  end
  envelope = [min(lower), max(upper)];
end

function distance = LOCAL_optional_distance(first, second)
  if all(isfinite(first)) && all(isfinite(second))
    distance = LOCAL_envelope_distance(first, second);
  else
    distance = NaN;
  end
end

function change = LOCAL_component_algebraic_change(objects, ids, grid)
  changes = NaN(1, numel(grid));
  for phase_index = 1:numel(grid)
    tight = ids(strcmp({objects(ids).configuration}, 'fine') & ...
      abs([objects(ids).theta] - grid(phase_index)) < 1e-13);
    loose = ids(strcmp({objects(ids).configuration}, 'fine-loose-count') & ...
      abs([objects(ids).theta] - grid(phase_index)) < 1e-13);
    if isempty(tight) || isempty(loose)
      change = NaN;
      return;
    end
    tight_values = vertcat(objects(tight).k_envelope);
    loose_values = vertcat(objects(loose).k_envelope);
    tight_envelope = [min(tight_values(:, 1)), max(tight_values(:, 2))];
    loose_envelope = [min(loose_values(:, 1)), max(loose_values(:, 2))];
    changes(phase_index) = ...
      LOCAL_envelope_distance(tight_envelope, loose_envelope);
  end
  change = max(changes);
end

function rank = LOCAL_candidate_parity_rank(objects)
  endpoint = (abs([objects.theta]) < 1e-13) | ...
    (abs([objects.theta] - pi) < 1e-13);
  if ~any(endpoint)
    rank = 2;
    return;
  end
  endpoint_objects = objects(endpoint);
  if any(~strcmp({endpoint_objects.parity_status}, 'AVAILABLE'))
    rank = 2;
    return;
  end
  labels = {endpoint_objects.parity_label};
  if all(strcmp(labels, 'even')) || all(strcmp(labels, 'odd'))
    rank = 0;
  else
    rank = 1;
  end
end

function [covered_window, covered_slices, margin] = ...
    LOCAL_candidate_coverage(coverage, objects)
  covered_window = -1;
  covered_slices = 0;
  margin = NaN;
  configurations = unique({objects.configuration});
  for index = 1:numel(configurations)
    current = coverage.(LOCAL_field_name(configurations{index}));
    candidate = [current.largest_covered_window, ...
      current.covered_slices(4), current.minimum_margin(4)];
    incumbent = [covered_window, covered_slices, margin];
    if candidate(1) > incumbent(1) || ...
        (candidate(1) == incumbent(1) && candidate(2) > incumbent(2)) || ...
        (candidate(1) == incumbent(1) && candidate(2) == incumbent(2) && ...
        LOCAL_nan_negative(candidate(3)) < LOCAL_nan_negative(incumbent(3)))
      covered_window = candidate(1);
      covered_slices = candidate(2);
      margin = candidate(3);
    end
  end
end

function publication = LOCAL_publication_realization( ...
    spec, objects, ids, candidate_id)
  configurations = unique({objects(ids).configuration}, 'stable');
  tuples = zeros(numel(configurations), 5);
  grouped_ids = cell(1, numel(configurations));
  for index = 1:numel(configurations)
    grouped_ids{index} = ids(strcmp( ...
      {objects(ids).configuration}, configurations{index}));
    group = objects(grouped_ids{index});
    tuples(index, :) = [-numel(unique([group.theta])), ...
      group(1).configuration_priority, min([group.theta_index]), ...
      min([group.root_index]), candidate_id];
  end
  [~, order] = sortrows(tuples, 1:5);
  level_ids = grouped_ids{order(1)};
  level = objects(level_ids);
  anchor_keys = [[level.theta_index].', [level.root_index].', ...
    [level.object_id].'];
  [~, anchor_order] = sortrows(anchor_keys, 1:3);
  anchor = level(anchor_order(1));
  lambda_values = vertcat(level.lambda_envelope);
  k_values = vertcat(level.k_envelope);
  lambda_envelope = [min(lambda_values(:, 1)), max(lambda_values(:, 2))];
  k_envelope = [min(k_values(:, 1)), max(k_values(:, 2))];
  lambda_ref_fem = mean(lambda_envelope);
  k_ref_fem = sqrt(lambda_ref_fem);
  simple_vector = [];
  basis_status = 'MASS_NORMALIZED_SUBSPACE';
  if anchor.dimension == 1
    [~, pivot] = max(abs(anchor.subspace(:, 1)));
    phase = exp(-1i * angle(anchor.subspace(pivot, 1)));
    simple_vector = anchor.subspace(:, 1) * phase;
    basis_status = 'PHASE_FIXED_MASS_NORMALIZED_VECTOR';
  end
  publication = struct('configuration', anchor.configuration, ...
    'valid_twist_count', numel(unique([level.theta])), ...
    'anchor_object_id', anchor.object_id, 'anchor_mesh_id', anchor.mesh_id, ...
    'anchor_theta', anchor.theta, 'anchor_theta_index', anchor.theta_index, ...
    'anchor_root_index', anchor.root_index, ...
    'multiplicity', anchor.dimension, ...
    'lambda_envelope', lambda_envelope, 'k_envelope', k_envelope, ...
    'lambda_ref_fem', lambda_ref_fem, 'k_ref_fem', k_ref_fem, ...
    'subspace', anchor.subspace, 'simple_vector', simple_vector, ...
    'basis_status', basis_status, 'window_label', anchor.window_label, ...
    'gap_label', LOCAL_gap_label_from_envelope( ...
    spec, anchor.gap_label, k_envelope));
end

function label = LOCAL_gap_label_from_envelope(spec, anchor_label, envelope)
  if envelope(1) < spec.search_windows(4, 1) || ...
      envelope(2) > spec.search_windows(4, 2)
    label = [anchor_label ';WINDOW_EDGE_STRADDLE'];
  else
    label = anchor_label;
  end
end

function labels = LOCAL_candidate_classifications( ...
    spec, bulk_diagnostic, publication, center, core, tail, parity_rank, ...
    resolution_status, covered_window, covered_slices, margin, objects)
  labels = {publication.window_label, publication.gap_label};
  if ~all(isfinite([center, core, tail]))
    labels{end + 1} = 'localization-unavailable';
  elseif center >= spec.localization_center_min && ...
      core >= spec.localization_core_min && tail <= spec.tail_max
    labels{end + 1} = 'localized';
  else
    labels{end + 1} = 'weakly-localized';
  end
  if parity_rank == 0
    labels{end + 1} = 'stable-parity-assignment';
  elseif parity_rank == 1
    labels{end + 1} = 'mixed/ambiguous';
  else
    labels{end + 1} = 'parity-unavailable';
  end
  labels{end + 1} = lower(strrep(resolution_status, '_', '-'));
  if covered_window == 3
    labels{end + 1} = 'spectrum-covered-through-W3';
  else
    labels{end + 1} = 'spectrum-coverage-partial';
  end
  if any([objects.window_edge_straddle])
    labels{end + 1} = 'WINDOW_EDGE_STRADDLE';
  end
  if bulk_diagnostic.target_gap.available && ...
      (~bulk_diagnostic.target_gap.refinement_pass || ...
      ~bulk_diagnostic.target_gap.safe_pass)
    labels{end + 1} = 'pre-asymptotic-diagnostic';
  end
  labels{end + 1} = sprintf( ...
    'coverage-W%d-slices-%d-margin-%.17g', ...
    covered_window, covered_slices, margin);
end

function value = LOCAL_nan_min(value)
  if ~isfinite(value)
    value = Inf;
  end
end

function value = LOCAL_nan_negative(value)
  if isfinite(value)
    value = -value;
  else
    value = Inf;
  end
end

function LOCAL_publish_scientific(output_dir, spec, run_state, registry, ...
    mesh_failures, bulk_inventory, defect_inventory, candidate_inventory, ...
    tracking, selected_candidate, terminal_class, terminal_status, first_failure)
  payload = struct('schema_version', 'i4a-diagnostic-ranking-v2', ...
    'run_id', run_state.run_id, 'execution_id', run_state.execution_id, ...
    'terminal_class', terminal_class, ...
    'scientific_terminal', terminal_status, 'first_failure', first_failure, ...
    'attempted_solves', run_state.attempted_solves, ...
    'completed_solves', run_state.completed_solves, ...
    'planned_solves', run_state.planned_solves, ...
    'claim_boundary', ...
    'EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY', ...
    'spec', spec, 'search_windows', spec.search_windows);
  if isempty(registry)
    payload.mesh_descriptors = struct([]);
  else
    payload.mesh_descriptors = [registry.descriptor];
  end
  payload.mesh_failures = mesh_failures;
  payload.bulk_inventory = LOCAL_compact_bulk(bulk_inventory);
  payload.defect_inventory = LOCAL_compact_defect(defect_inventory);
  payload.candidate_inventory = ...
    LOCAL_compact_candidate_inventory(candidate_inventory);
  payload.tracking = tracking;
  payload.selected_candidate = LOCAL_compact_selected(selected_candidate);
  try
    LOCAL_atomic_save(fullfile(output_dir, 'scientific-result.mat'), payload);
  catch caught
    LOCAL_raise('CANONICAL_PUBLICATION_FAILURE', caught.message);
  end
end

function compact = LOCAL_compact_candidate_inventory(inventory)
  compact = inventory;
  if isempty(compact) || ~isfield(compact, 'objects')
    return;
  end
  for index = 1:numel(compact.objects)
    compact.objects(index).subspace = [];
    compact.objects(index).common_core_samples = [];
    compact.objects(index).common_core_weights = [];
  end
  for index = 1:numel(compact.candidates)
    compact.candidates(index).publication = ...
      LOCAL_compact_publication(compact.candidates(index).publication);
  end
end

function compact = LOCAL_compact_selected(selected)
  compact = selected;
  if ~isempty(compact)
    compact.publication = LOCAL_compact_publication(compact.publication);
  end
end

function compact = LOCAL_compact_publication(publication)
  compact = publication;
  if ~isempty(compact)
    compact.subspace = [];
    compact.simple_vector = [];
  end
end

function LOCAL_publish_fields(output_dir, registry, selected)
  mesh = LOCAL_load_mesh(registry, '', selected.publication.anchor_mesh_id);
  payload = struct('schema_version', 'i4a-fields-v2', ...
    'run_id', 'run-007', 'execution_id', 'execution-001', ...
    'candidate_id', selected.candidate_id, ...
    'lambda_ref_fem', selected.lambda_ref_fem, ...
    'k_ref_fem', selected.k_ref_fem, ...
    'multiplicity', selected.publication.multiplicity, ...
    'anchor_mesh_id', selected.publication.anchor_mesh_id, ...
    'anchor_theta', selected.publication.anchor_theta, ...
    'points', mesh.points, 'triangles', mesh.triangles, ...
    'material_inside', mesh.material_inside, ...
    'subspace', selected.publication.subspace, ...
    'simple_vector', selected.publication.simple_vector, ...
    'basis_status', selected.publication.basis_status, ...
    'claim_boundary', ...
    'EMPIRICAL_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY');
  try
    LOCAL_atomic_save(fullfile(output_dir, 'fields.mat'), payload);
  catch caught
    LOCAL_raise('CANONICAL_PUBLICATION_FAILURE', caught.message);
  end
end

%% ==================== Shared candidate helpers ====================
% These helpers support names, common-core overlaps, and compact publication.

function name = LOCAL_field_name(name)
  name = strrep(name, '-', '_');
end

function overlap = LOCAL_common_core_overlap(first_cluster, second_cluster)
  first_samples = first_cluster.common_core_samples;
  weights = first_cluster.common_core_weights;
  second_samples = second_cluster.common_core_samples;
  second_weights = second_cluster.common_core_weights;
  if numel(weights) ~= numel(second_weights) || ...
      max(abs(weights - second_weights)) > 1e-14
    LOCAL_raise('TRACKING_DIAGNOSTIC_UNAVAILABLE', ...
      'Common-core quadrature weights differ across meshes.');
  end
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
    LOCAL_raise('TRACKING_DIAGNOSTIC_UNAVAILABLE', ...
      'The common-core grid is not covered by a mesh.');
  end
  vertices = mesh.triangles(triangle_index, :);
  samples = barycentric(:, 1) .* subspace(vertices(:, 1), :) + ...
    barycentric(:, 2) .* subspace(vertices(:, 2), :) + ...
    barycentric(:, 3) .* subspace(vertices(:, 3), :);
  weights = weights .* q_values;
end

function distance = LOCAL_envelope_distance(first, second)
  distance = max(abs(first - second));
end

function compact = LOCAL_compact_bulk(inventory)
  compact = inventory;
  if isempty(compact) || ~isfield(compact, 'levels')
    return;
  end
  names = fieldnames(compact.levels);
  for index = 1:numel(names)
    if isfield(compact.levels.(names{index}), 'paths')
      compact.levels.(names{index}) = rmfield( ...
        compact.levels.(names{index}), 'paths');
    end
  end
  if isfield(compact, 'count_sentinels') && ...
      ~isempty(compact.count_sentinels) && ...
      isfield(compact.count_sentinels, 'path')
    compact.count_sentinels = rmfield(compact.count_sentinels, 'path');
  end
end

function compact = LOCAL_compact_defect(inventory)
  compact = inventory;
  if isempty(compact) || ~isfield(compact, 'entries')
    return;
  end
  if isfield(compact.entries, 'path')
    compact.entries = rmfield(compact.entries, 'path');
  end
end
