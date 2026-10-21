function run_i4_1b(run_id, execution_id)
%RUN_I4_1B Produce the frozen I4.1b quadratic-FEM candidate.
% Purpose:
%   Solve the independent fixed-beta bulk and line-defect problems with the
%   fitted straight-sided conforming P2 method frozen in design Sections
%   1--15.
% Input:
%   run_id - Exactly 'run-001' or 'resource-preflight-001'.
%   execution_id - Formal 'execution-001' or preflight 'execution-002'.
% Output:
%   Formal dispatch publishes scientific artifacts. Preflight dispatch
%   publishes only the Section 16 representation/resource leaves.
% Main algorithm:
%   Build nine fitted meshes with globally shared edge-midpoint P2 DOFs,
%   assemble degree-five-quadrature P2 and analytic P1 forms, impose vertex
%   and midpoint phases, compute 72 bulk, 47 defect, and five companion P1
%   spectra, optionally compute 17 consistent 60-root anchor spectra, then
%   track and rank every valid field-bearing W3 P2 component.
% Based on:
%   run_i4_1a.m for the fitted-mesh concept; authoritative mathematics is
%   design-4-1b.md Sections 1--15, especially Section 15.
% Main changes:
%   Uses the complete quadratic Lagrange element, exact graph/assignment and
%   P2-only rank. Current-run P1 companions are non-ranking Ritz/drift data.
% Numerical goal:
%   Publish one empirical, non-certified P2 FEM candidate whenever the finite
%   schedule contains a numerically valid field-bearing W3 component.
% Notes:
%   This function reads only source constants and current-run caches. It never
%   reads Markdown, Git, historical output, BIE/QZ objects, or estimators.

  if nargin ~= 2 || ~(ischar(run_id) || ...
      (isstring(run_id) && isscalar(run_id))) || ...
      ~(ischar(execution_id) || ...
      (isstring(execution_id) && isscalar(execution_id)))
    error('I4B:InvalidIdentity', ...
      'The formal entry requires the fixed run and execution IDs.');
  end
  run_id = char(run_id);
  execution_id = char(execution_id);
  is_formal = strcmp(run_id, 'run-001') && ...
    strcmp(execution_id, 'execution-001');
  is_preflight = strcmp(run_id, 'resource-preflight-001') && ...
    strcmp(execution_id, 'execution-002');
  if ~is_formal && ~is_preflight
    error('I4B:InvalidIdentity', ...
      'The entry identity is not in the exact formal/preflight allowlist.');
  end
  entry_dir = fileparts(mfilename('fullpath'));
  output_dir = fullfile(entry_dir, 'output', run_id, execution_id);
  if ~exist(output_dir, 'dir')
    error('I4B:OutputUnavailable', ...
      'The fixed runner must create the exact output identity first.');
  end
  if is_preflight
    LOCAL_resource_preflight(output_dir);
    return;
  end
  work_dir = fullfile(output_dir, 'work');
  if exist(work_dir, 'dir') || exist(work_dir, 'file')
    error('I4B:OutputCollision', 'The current-run work directory exists.');
  end
  [made_work, work_message] = mkdir(work_dir);
  if ~made_work
    error('I4B:OutputUnavailable', 'Cannot create work: %s', work_message);
  end
  if exist(fullfile(output_dir, 'scientific-result.mat'), 'file') || ...
      exist(fullfile(output_dir, 'fields.mat'), 'file') || ...
      exist(fullfile(output_dir, 'run-summary.csv'), 'file')
    error('I4B:OutputCollision', 'A terminal execution-001 artifact exists.');
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
  companion_inventory = struct([]);
  terminal_class = 'OPERATIONAL_FAILURE';
  terminal_status = 'RUNNING';
  first_failure = '';
  fprintf('I4.1b quadratic fitted-FEM run %s/%s\n', ...
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
    LOCAL_log(output_dir, 'stage=p2-candidate-ranking');
    [candidate_inventory, tracking] = LOCAL_candidate_inventory( ...
      spec, bulk_inventory, defect_inventory, mesh_registry, work_dir);
    if isempty(candidate_inventory.objects)
      LOCAL_raise('NO_VALID_FIELD_BEARING_W3_EIGENOBJECT', ...
        ['The complete finite schedule contains no numerically valid ' ...
        'field-bearing W3 eigenobject.']);
    end
    [candidate_inventory, selected_candidate] = LOCAL_rank_candidates( ...
      spec, bulk_inventory, defect_inventory, candidate_inventory, tracking);
    LOCAL_log(output_dir, 'stage=p1-companion');
    [companion_inventory, run_state] = LOCAL_companion_inventory( ...
      spec, mesh_registry, work_dir, output_dir, run_state, ...
      defect_inventory, candidate_inventory);
    [candidate_inventory, selected_candidate] = ...
      LOCAL_attach_companion_drift(spec, candidate_inventory, ...
      selected_candidate.candidate_id, companion_inventory);
    LOCAL_publish_fields(output_dir, mesh_registry, candidate_inventory, ...
      companion_inventory, selected_candidate);
    terminal_class = 'SCIENTIFIC_READY';
    terminal_status = 'P2_FEM_CANDIDATE_READY';
    LOCAL_publish_scientific(output_dir, spec, run_state, mesh_registry, ...
      mesh_failures, bulk_inventory, defect_inventory, candidate_inventory, ...
      tracking, selected_candidate, companion_inventory, terminal_class, ...
      terminal_status, first_failure);
  catch caught
    [failure_code, failure_message] = LOCAL_decode_failure(caught);
    terminal_status = failure_code;
    first_failure = failure_message;
    if LOCAL_is_scientific_terminal(failure_code)
      terminal_class = 'SCIENTIFIC_NEGATIVE';
      if ~strcmp(failure_code, 'CANONICAL_PUBLICATION_FAILURE')
        LOCAL_publish_scientific(output_dir, spec, run_state, mesh_registry, ...
          mesh_failures, bulk_inventory, defect_inventory, ...
          candidate_inventory, tracking, struct([]), companion_inventory, ...
          terminal_class, terminal_status, first_failure);
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
% Design Sections 1--15 fix the model, P2 element, schedules and rank.

function spec = LOCAL_spec()
  spec = struct();
  spec.design_id = 'I4.1B-P2-FEM-REFERENCE-V1';
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
  spec.eigs_subspace_40 = 80;
  spec.eigs_subspace_48 = 96;
  spec.eigs_subspace_60 = 100;
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
  spec.nodal_tolerance = 5e-14;
  spec.partition_gradient_tolerance = 5e-13;
  spec.monomial_tolerance = 2e-13;
  spec.embedding_tolerance = 1e-12;
  spec.expansion_frequency_tolerance = 1e-8;
  spec.expansion_overlap_tolerance = 1e-8;
  spec.resolution_terminal_fraction = 5e-4;
  spec.total_resolution_fraction = 0.02;
  spec.algebraic_relative_cap = 1e-8;
  spec.algebraic_component_fraction = 0.05;
  spec.core_grid_x = linspace(-2.5, 2.5, 161);
  spec.core_grid_y = linspace(-0.5, 0.5, 65);
  spec.planned_bulk_solves = 72;
  spec.planned_defect_solves = 47;
  spec.planned_companion_solves = 5;
  spec.planned_base_solves = 124;
  spec.maximum_solves = 141;
  spec.search_windows = [1.65, 2.05; 1.25, 2.45; ...
    0.85, 2.85; 0.45, 3.25];
  spec.configuration_priority = {'p2-anchor', 'p2-h2-g1', 'p2-h1', ...
    'p2-h0', 'p2-g0', 'p2-n4', 'p2-loose'};
  spec.object_allocation_order = {'p2-h0', 'p2-h1', 'p2-h2-g1', ...
    'p2-g0', 'p2-anchor', 'p2-n4', 'p2-loose'};
end

%% ==================== Zero-eigensolve resource preflight ====================
% Design Section 16 constructs representations and capacities but no spectra.

function LOCAL_resource_preflight(output_dir)
  if exist(fullfile(output_dir, 'mesh-operators.tsv'), 'file')
    LOCAL_raise('OUTPUT_COLLISION', ...
      'The create-once preflight mesh table already exists.');
  end
  spec = LOCAL_spec();
  schedule = LOCAL_mesh_schedule();
  processing_order = [1:7, 9, 8];
  rows = struct('mesh_id', {}, 'vertex_count', {}, 'triangle_count', {}, ...
    'boundary_edge_count', {}, 'edge_count', {}, ...
    'p1_full_dof', {}, 'p1_reduced_dof', {}, ...
    'p2_full_dof', {}, 'p2_reduced_dof', {}, ...
    'p1_full_nnz_K', {}, 'p1_full_nnz_M', {}, ...
    'p2_full_nnz_K', {}, 'p2_full_nnz_M', {}, ...
    'p1_reduced_nnz_K_max', {}, 'p1_reduced_nnz_M_max', {}, ...
    'p2_reduced_nnz_K_max', {}, 'p2_reduced_nnz_M_max', {}, ...
    'applicable_nev_p', {});
  anchor_mesh = struct([]);
  fprintf('I4.1b zero-eigensolve resource preflight\n');
  for order_index = 1:numel(processing_order)
    mesh_spec = schedule(processing_order(order_index));
    LOCAL_preflight_marker(output_dir, ['mesh-' mesh_spec.id], ...
      'mesh-construction,p1-p2-phase-reductions', 0);
    mesh = LOCAL_build_mesh(spec, mesh_spec);
    phases = LOCAL_preflight_phases(spec, mesh.id);
    p1_nnz_K = 0;
    p1_nnz_M = 0;
    p2_nnz_K = 0;
    p2_nnz_M = 0;
    p1_pair = struct([]);
    p2_pair = struct([]);
    for phase_index = 1:numel(phases)
      [p2_pair, ~] = LOCAL_phase_reduce( ...
        spec, mesh, phases(phase_index), 'resource-preflight');
      [p1_pair, ~] = LOCAL_phase_reduce_p1( ...
        spec, mesh, phases(phase_index));
      p1_nnz_K = max(p1_nnz_K, nnz(p1_pair.stiffness));
      p1_nnz_M = max(p1_nnz_M, nnz(p1_pair.mass));
      p2_nnz_K = max(p2_nnz_K, nnz(p2_pair.stiffness));
      p2_nnz_M = max(p2_nnz_M, nnz(p2_pair.mass));
    end
    row = struct('mesh_id', mesh.id, ...
      'vertex_count', size(mesh.points, 1), ...
      'triangle_count', size(mesh.triangles, 1), ...
      'boundary_edge_count', mesh.boundary_edge_count, ...
      'edge_count', size(mesh.edges, 1), ...
      'p1_full_dof', size(mesh.points, 1), ...
      'p1_reduced_dof', mesh.p1_reduced_dof, ...
      'p2_full_dof', size(mesh.p2_points, 1), ...
      'p2_reduced_dof', mesh.reduced_dof, ...
      'p1_full_nnz_K', nnz(mesh.p1_stiffness_full), ...
      'p1_full_nnz_M', nnz(mesh.p1_mass_full), ...
      'p2_full_nnz_K', nnz(mesh.stiffness_full), ...
      'p2_full_nnz_M', nnz(mesh.mass_full), ...
      'p1_reduced_nnz_K_max', p1_nnz_K, ...
      'p1_reduced_nnz_M_max', p1_nnz_M, ...
      'p2_reduced_nnz_K_max', p2_nnz_K, ...
      'p2_reduced_nnz_M_max', p2_nnz_M, ...
      'applicable_nev_p', LOCAL_preflight_nev_p(mesh.id));
    rows(end + 1) = row; %#ok<AGROW>
    internal_bytes = LOCAL_value_bytes(mesh) + ...
      LOCAL_value_bytes(p1_pair) + LOCAL_value_bytes(p2_pair);
    LOCAL_preflight_marker(output_dir, ['mesh-' mesh.id], ...
      sprintf('mesh:%d,p1-pair:%d,p2-pair:%d', ...
      LOCAL_value_bytes(mesh), LOCAL_value_bytes(p1_pair), ...
      LOCAL_value_bytes(p2_pair)), internal_bytes);
    pause(0.5);
    if strcmp(mesh.id, 'defect-N5-s18-g48')
      anchor_mesh = mesh;
    end
    clear mesh p1_pair p2_pair
  end
  [found_rows, row_order] = ismember({schedule.id}, {rows.mesh_id});
  if ~all(found_rows)
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      'The preflight mesh table is incomplete.');
  end
  rows = rows(row_order);
  LOCAL_write_mesh_table(output_dir, rows);
  if isempty(anchor_mesh)
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      'The anchor representation was not constructed.');
  end

  LOCAL_preflight_marker(output_dir, 'reduced-operator-factor', ...
    'anchor-mesh,reduced-K-M,mass-factor', 0);
  [anchor_pair, ~] = LOCAL_phase_reduce( ...
    spec, anchor_mesh, pi / 4, 'resource-preflight');
  factor_bytes = LOCAL_value_bytes(anchor_mesh) + ...
    LOCAL_value_bytes(anchor_pair);
  LOCAL_preflight_marker(output_dir, 'reduced-operator-factor', ...
    sprintf('anchor-mesh:%d,reduced-K:%d,reduced-M:%d,mass-factor:%d', ...
    LOCAL_value_bytes(anchor_mesh), ...
    LOCAL_value_bytes(anchor_pair.stiffness), ...
    LOCAL_value_bytes(anchor_pair.mass), ...
    LOCAL_value_bytes(anchor_pair.mass_factor)), factor_bytes);
  pause(1);

  LOCAL_preflight_marker(output_dir, 'solver-capacity', ...
    'anchor-factor,p100-Arnoldi,60-vector-return', 0);
  arnoldi_capacity = LOCAL_commit_complex_capacity( ...
    anchor_mesh.reduced_dof * spec.eigs_subspace_60);
  return_capacity = LOCAL_commit_complex_capacity( ...
    size(anchor_mesh.p2_points, 1) * spec.defect_expand_nev);
  solver_bytes = factor_bytes + LOCAL_value_bytes(arnoldi_capacity) + ...
    LOCAL_value_bytes(return_capacity);
  LOCAL_preflight_marker(output_dir, 'solver-capacity', ...
    sprintf('anchor-factor:%d,p100-Arnoldi:%d,60-vector-return:%d', ...
    factor_bytes, LOCAL_value_bytes(arnoldi_capacity), ...
    LOCAL_value_bytes(return_capacity)), solver_bytes);
  pause(1);
  clear arnoldi_capacity return_capacity anchor_pair

  full_dof = containers.Map({rows.mesh_id}, num2cell([rows.p2_full_dof]));
  field_count = 48 * 5 * (full_dof('defect-N5-s12-g36') + ...
    full_dof('defect-N5-s15-g36') + ...
    full_dof('defect-N5-s18-g36') + ...
    full_dof('defect-N5-s18-g24') + ...
    full_dof('defect-N4-s18-g48') + ...
    full_dof('defect-N5-s18-g48')) + ...
    60 * 17 * full_dof('defect-N5-s18-g48');
  sample_count = numel(spec.core_grid_x) * numel(spec.core_grid_y) * ...
    (48 * 5 * 6 + 60 * 17);
  field_capacity = LOCAL_commit_complex_capacity(field_count);
  sample_capacity = LOCAL_commit_complex_capacity(sample_count);

  LOCAL_preflight_marker(output_dir, 'companion-simultaneous-capacity', ...
    ['p2-fields,p2-common-grid,four-prior-p1-fields,current-p1-' ...
    'reduced-and-full,p1-full-and-reduced-K-M-prolongation-factor,' ...
    'p96-Arnoldi,48-return,companion-metadata'], 0);
  [companion_pair, ~] = LOCAL_phase_reduce_p1( ...
    spec, anchor_mesh, pi / 4);
  prior_companion_capacity = LOCAL_commit_complex_capacity( ...
    size(anchor_mesh.points, 1) * 48 * 4);
  current_companion_full_capacity = LOCAL_commit_complex_capacity( ...
    size(anchor_mesh.points, 1) * 48);
  current_companion_reduced_capacity = LOCAL_commit_complex_capacity( ...
    anchor_mesh.p1_reduced_dof * 48);
  companion_arnoldi_capacity = LOCAL_commit_complex_capacity( ...
    anchor_mesh.p1_reduced_dof * spec.eigs_subspace_48);
  companion_metadata_capacity = LOCAL_commit_complex_capacity(48 * 16);
  companion_bytes = LOCAL_value_bytes(anchor_mesh) + ...
    LOCAL_value_bytes(field_capacity) + ...
    LOCAL_value_bytes(sample_capacity) + ...
    LOCAL_value_bytes(companion_pair) + ...
    LOCAL_value_bytes(prior_companion_capacity) + ...
    LOCAL_value_bytes(current_companion_full_capacity) + ...
    LOCAL_value_bytes(current_companion_reduced_capacity) + ...
    LOCAL_value_bytes(companion_arnoldi_capacity) + ...
    LOCAL_value_bytes(companion_metadata_capacity);
  LOCAL_preflight_marker(output_dir, 'companion-simultaneous-capacity', ...
    sprintf(['anchor-mesh:%d,p2-fields:%d,p2-common-grid:%d,' ...
    'p1-pair:%d,four-prior-p1-fields:%d,current-p1-full:%d,' ...
    'current-p1-reduced:%d,p96-Arnoldi:%d,companion-metadata:%d'], ...
    LOCAL_value_bytes(anchor_mesh), ...
    LOCAL_value_bytes(field_capacity), LOCAL_value_bytes(sample_capacity), ...
    LOCAL_value_bytes(companion_pair), ...
    LOCAL_value_bytes(prior_companion_capacity), ...
    LOCAL_value_bytes(current_companion_full_capacity), ...
    LOCAL_value_bytes(current_companion_reduced_capacity), ...
    LOCAL_value_bytes(companion_arnoldi_capacity), ...
    LOCAL_value_bytes(companion_metadata_capacity)), companion_bytes);
  pause(1);

  clear companion_pair current_companion_reduced_capacity ...
    companion_arnoldi_capacity companion_metadata_capacity
  % Compact source payload: 64 complex words per possible P2/P1 object.
  source_payload_count = 64 * ( ...
    spec.planned_defect_solves * spec.defect_main_nev + ...
    spec.planned_companion_solves * spec.defect_main_nev + ...
    numel(spec.theta_17) * spec.defect_expand_nev);
  source_payload_capacity = LOCAL_commit_complex_capacity( ...
    source_payload_count);
  LOCAL_preflight_marker(output_dir, 'publication-simultaneous-capacity', ...
    ['p2-fields,p2-common-grid,five-p1-fields,' ...
    'candidate-companion-payload,512MiB-publication-copy'], 0);
  publication_capacity = LOCAL_commit_complex_capacity(32 * 1024^2);
  publication_bytes = LOCAL_value_bytes(field_capacity) + ...
    LOCAL_value_bytes(sample_capacity) + ...
    LOCAL_value_bytes(prior_companion_capacity) + ...
    LOCAL_value_bytes(current_companion_full_capacity) + ...
    LOCAL_value_bytes(source_payload_capacity) + ...
    LOCAL_value_bytes(publication_capacity);
  LOCAL_preflight_marker(output_dir, 'publication-simultaneous-capacity', ...
    sprintf(['p2-fields:%d,p2-common-grid:%d,five-p1-fields:%d,' ...
    'candidate-companion-payload:%d,publication-copy:%d'], ...
    LOCAL_value_bytes(field_capacity), LOCAL_value_bytes(sample_capacity), ...
    LOCAL_value_bytes(prior_companion_capacity) + ...
    LOCAL_value_bytes(current_companion_full_capacity), ...
    LOCAL_value_bytes(source_payload_capacity), ...
    LOCAL_value_bytes(publication_capacity)), ...
    publication_bytes);
  pause(1);
  clear field_capacity sample_capacity prior_companion_capacity ...
    current_companion_full_capacity source_payload_capacity ...
    publication_capacity anchor_mesh
  LOCAL_preflight_terminal(output_dir, 'PREFLIGHT_COMPLETE');
end

function phases = LOCAL_preflight_phases(spec, mesh_id)
  if strcmp(mesh_id, 'bulk-s12-g36') || strcmp(mesh_id, 'bulk-s18-g36')
    phases = spec.bulk_alpha_17;
  elseif strcmp(mesh_id, 'bulk-s18-g48')
    phases = spec.bulk_alpha_33;
  elseif strcmp(mesh_id, 'defect-N5-s18-g48')
    phases = spec.theta_17;
  else
    phases = spec.theta_5;
  end
end

function label = LOCAL_preflight_nev_p(mesh_id)
  if strcmp(mesh_id, 'bulk-s12-g36') || strcmp(mesh_id, 'bulk-s18-g36')
    label = '40/80';
  elseif strcmp(mesh_id, 'bulk-s18-g48')
    label = '40/80;48/96';
  elseif strcmp(mesh_id, 'defect-N5-s18-g48')
    label = '48/96;60/100;P1-48/96';
  else
    label = '48/96';
  end
end

function LOCAL_preflight_marker(output_dir, stage, classes, internal_bytes)
  file_id = fopen(fullfile(output_dir, 'preflight.log'), 'a');
  if file_id < 0
    LOCAL_raise('OUTPUT_UNAVAILABLE', 'Cannot append preflight.log.');
  end
  cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
  fprintf(file_id, 'PREFLIGHT_STAGE\t%s\t%s\t%.0f\n', ...
    stage, classes, internal_bytes);
end

function LOCAL_preflight_terminal(output_dir, terminal)
  file_id = fopen(fullfile(output_dir, 'preflight.log'), 'a');
  if file_id < 0
    LOCAL_raise('OUTPUT_UNAVAILABLE', 'Cannot append preflight terminal.');
  end
  cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
  fprintf(file_id, 'PREFLIGHT_TERMINAL\t%s\n', terminal);
end

function bytes = LOCAL_value_bytes(value)
  information = whos('value');
  bytes = information.bytes;
end

function value = LOCAL_commit_complex_capacity(count)
  value = zeros(count, 1, 'like', 1i);
  value(1:256:end) = 1 + 1i;
  if ~isempty(value)
    value(end) = 1 + 1i;
  end
end

function LOCAL_write_mesh_table(output_dir, rows)
  path = fullfile(output_dir, 'mesh-operators.tsv');
  file_id = fopen(path, 'w');
  if file_id < 0
    LOCAL_raise('OUTPUT_UNAVAILABLE', ...
      'Cannot create the preflight mesh table.');
  end
  cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
  fprintf(file_id, ['mesh_id\tV\tT\tB\tE\tp1_full_dof\t' ...
    'p1_reduced_dof\tp2_full_dof\tp2_reduced_dof\t' ...
    'p1_full_nnz_K\tp1_full_nnz_M\tp2_full_nnz_K\t' ...
    'p2_full_nnz_M\tp1_reduced_nnz_K_max\t' ...
    'p1_reduced_nnz_M_max\tp2_reduced_nnz_K_max\t' ...
    'p2_reduced_nnz_M_max\tapplicable_nev_p\n']);
  for index = 1:numel(rows)
    row = rows(index);
    fprintf(file_id, ['%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t' ...
      '%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\n'], ...
      row.mesh_id, row.vertex_count, row.triangle_count, ...
      row.boundary_edge_count, row.edge_count, row.p1_full_dof, ...
      row.p1_reduced_dof, row.p2_full_dof, row.p2_reduced_dof, ...
      row.p1_full_nnz_K, row.p1_full_nnz_M, row.p2_full_nnz_K, ...
      row.p2_full_nnz_M, row.p1_reduced_nnz_K_max, ...
      row.p1_reduced_nnz_M_max, row.p2_reduced_nnz_K_max, ...
      row.p2_reduced_nnz_M_max, row.applicable_nev_p);
  end
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
  if spec.planned_bulk_solves + spec.planned_defect_solves + ...
      spec.planned_companion_solves ~= 124 || ...
      spec.maximum_solves ~= 141 || spec.defect_main_nev ~= 48 || ...
      spec.defect_expand_nev ~= 60 || ...
      spec.period ~= 1 || spec.radius ~= 0.2 || spec.q_inside ~= 17 || ...
      spec.q_outside ~= 1 || spec.beta ~= 0.5 || spec.missing_column ~= 0
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'The source model or 72+47+5 schedule changed.');
  end
  LOCAL_validate_assignment_fixtures();
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
  lambda_ref_p2 = NaN;
  k_ref_p2 = NaN;
  if ~isempty(selected_candidate)
    collection_size = selected_candidate.collection_size;
    lambda_ref_p2 = selected_candidate.lambda_ref_p2;
    k_ref_p2 = selected_candidate.k_ref_p2;
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
  fprintf(file_id, 'lambda_ref_p2\t%.17g\n', lambda_ref_p2);
  fprintf(file_id, 'k_ref_p2\t%.17g\n', k_ref_p2);
  fprintf(file_id, 'first_failure\t%s\n', ...
    strrep(strrep(first_failure, sprintf('\n'), ' '), sprintf('\t'), ' '));
  fprintf(file_id, 'matlab_elapsed_seconds\t%.9f\n', toc(run_state.start_clock));
  fprintf(file_id, 'claim_boundary\t%s\n', ...
    'EMPIRICAL_P2_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY');
end

function yes = LOCAL_is_scientific_terminal(code)
  terminals = {'NO_VALID_FIELD_BEARING_W3_EIGENOBJECT', ...
    'DISCRETE_IMPLEMENTATION_INVALID', 'MESH_INVALID', ...
    'QUASIPERIODIC_MAP_INVALID', 'MATRIX_NONFINITE', ...
    'MATRIX_NON_HERMITIAN', 'MASS_NOT_SPD', ...
    'TRACKING_IMPLEMENTATION_FAILURE', ...
    'CANONICAL_PUBLICATION_FAILURE'};
  yes = any(strcmp(terminals, code));
end

function LOCAL_raise(code, message)
  error(['I4B:' code], '%s', message);
end

function [code, message] = LOCAL_decode_failure(caught)
  if startsWith(caught.identifier, 'I4B:')
    code = caught.identifier(5:end);
  else
    code = 'EXECUTION_UNAVAILABLE';
  end
  message = caught.message;
end

function schedule = LOCAL_mesh_schedule()
  schedule = struct('id', {}, 'kind', {}, 'N', {}, 's', {}, 'n_gamma', {});
  schedule(end + 1) = LOCAL_mesh_item('bulk-s12-g36', 'bulk', 0, 12, 36);
  schedule(end + 1) = LOCAL_mesh_item('bulk-s18-g36', 'bulk', 0, 18, 36);
  schedule(end + 1) = LOCAL_mesh_item('bulk-s18-g48', 'bulk', 0, 18, 48);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s12-g36', 'defect', 5, 12, 36);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s15-g36', 'defect', 5, 15, 36);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s18-g36', 'defect', 5, 18, 36);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s18-g24', 'defect', 5, 18, 24);
  schedule(end + 1) = LOCAL_mesh_item('defect-N5-s18-g48', 'defect', 5, 18, 48);
  schedule(end + 1) = LOCAL_mesh_item('defect-N4-s18-g48', 'defect', 4, 18, 48);
end

function item = LOCAL_mesh_item(id, kind, N, s, n_gamma)
  item = struct('id', id, 'kind', kind, 'N', N, 's', s, ...
    'n_gamma', n_gamma);
end

function schedule = LOCAL_defect_schedule(spec)
  schedule = struct('id', {}, 'mesh_id', {}, 'theta', {}, 'tol', {}, ...
    'nev', {}, 'role', {}, 'configuration', {});
  schedule = LOCAL_add_solve_group(schedule, 'p2-h0', ...
    'defect-N5-s12-g36', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'p2-h0');
  schedule = LOCAL_add_solve_group(schedule, 'p2-h1', ...
    'defect-N5-s15-g36', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'p2-h1');
  schedule = LOCAL_add_solve_group(schedule, 'p2-h2-g1', ...
    'defect-N5-s18-g36', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'p2-h2-g1');
  schedule = LOCAL_add_solve_group(schedule, 'p2-g0', ...
    'defect-N5-s18-g24', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'p2-g0');
  schedule = LOCAL_add_solve_group(schedule, 'p2-anchor', ...
    'defect-N5-s18-g48', spec.theta_17, 1e-11, ...
    spec.defect_main_nev, 'tight', 'p2-anchor');
  schedule = LOCAL_add_solve_group(schedule, 'p2-n4', ...
    'defect-N4-s18-g48', spec.theta_5, 1e-11, ...
    spec.defect_main_nev, 'tight', 'p2-n4');
  schedule = LOCAL_add_solve_group(schedule, 'p2-loose', ...
    'defect-N5-s18-g48', spec.theta_5, 1e-8, ...
    spec.defect_main_nev, 'loose-count', 'p2-loose');
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

%% ==================== Geometry-fitted P2 meshes ====================
% Straight P1 triangles gain one globally shared DOF per sorted active edge.

function [registry, failures] = LOCAL_mesh_registry(spec, work_dir)
  schedule = LOCAL_mesh_schedule();
  registry = struct('id', {}, 'path', {}, 'descriptor', {});
  failures = struct('mesh_id', {}, 'code', {}, 'reason', {});
  for index = 1:numel(schedule)
    try
      mesh = LOCAL_build_mesh(spec, schedule(index));
    catch caught
      [code, reason] = LOCAL_decode_failure(caught);
      recordable = strcmp(code, 'MESH_INVALID') || ...
        strcmp(code, 'MESH_QUALITY_UNRESOLVED') || ...
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
      'vertex_count', size(mesh.points, 1), ...
      'triangle_count', size(mesh.triangles, 1), ...
      'boundary_edge_count', mesh.boundary_edge_count, ...
      'edge_count', size(mesh.edges, 1), ...
      'p2_full_dof', size(mesh.p2_points, 1), ...
      'p2_reduced_dof', mesh.reduced_dof, ...
      'p1_reduced_dof', mesh.p1_reduced_dof, ...
      'nnz_p2_stiffness_full', nnz(mesh.stiffness_full), ...
      'nnz_p2_mass_full', nnz(mesh.mass_full), ...
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
  [p1_stiffness_full, p1_mass_full, p1_mass_center, ...
    p1_mass_core, p1_mass_tail] = LOCAL_assemble_p1( ...
    spec, mesh_spec, points, triangles, centroids, material_inside);
  [edges, triangle_p2, p2_points, edge_incidence, boundary_edge_count] = ...
    LOCAL_p2_topology(points, triangles);
  element_validation = LOCAL_validate_p2_element(spec);
  [stiffness_full, mass_full, mass_center, mass_core, mass_tail, ...
    embedding_validation] = LOCAL_assemble_p2(spec, mesh_spec, points, ...
    triangles, triangle_p2, centroids, material_inside);
  if any(~isfinite(nonzeros(stiffness_full))) || ...
      any(~isfinite(nonzeros(mass_full))) || ...
      any(~isfinite(nonzeros(p1_stiffness_full))) || ...
      any(~isfinite(nonzeros(p1_mass_full)))
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s assembly contains nonfinite entries.', mesh_spec.id));
  end
  stiffness_full = LOCAL_checked_hermitian( ...
    spec, stiffness_full, false, 'MESH_QUALITY_UNRESOLVED');
  mass_full = LOCAL_checked_hermitian( ...
    spec, mass_full, true, 'MESH_QUALITY_UNRESOLVED');
  p1_stiffness_full = LOCAL_checked_hermitian( ...
    spec, p1_stiffness_full, false, 'MESH_QUALITY_UNRESOLVED');
  p1_mass_full = LOCAL_checked_hermitian( ...
    spec, p1_mass_full, true, 'MESH_QUALITY_UNRESOLVED');
  reflected_edges = sort([reflection_index(edges(:, 1)), ...
    reflection_index(edges(:, 2))], 2);
  [reflected_edges_found, edge_reflection_index] = ...
    ismember(reflected_edges, edges, 'rows');
  edge_count = size(edges, 1);
  if any(~reflected_edges_found) || ...
      numel(unique(edge_reflection_index)) ~= edge_count
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s has a nonclosed reflected active-edge graph.', ...
      mesh_spec.id));
  end
  if ~isequal(edge_reflection_index(edge_reflection_index), ...
      (1:edge_count).')
    LOCAL_raise('DISCRETE_IMPLEMENTATION_INVALID', ...
      'The reflected active-edge permutation is not involutive.');
  end
  vertex_count = size(points, 1);
  p2_reflection_index = [reflection_index(:); ...
    vertex_count + edge_reflection_index(:)];
  if numel(unique(p2_reflection_index)) ~= size(p2_points, 1) || ...
      ~isequal(p2_reflection_index(p2_reflection_index), ...
      (1:size(p2_points, 1)).')
    LOCAL_raise('DISCRETE_IMPLEMENTATION_INVALID', ...
      'The edge-derived P2 reflection map is not bijective and involutive.');
  end
  reflected_p2_points = [-p2_points(:, 1), p2_points(:, 2)];
  p2_reflection_defect = max(abs( ...
    p2_points(p2_reflection_index, :) - reflected_p2_points), [], 'all');
  if ~isfinite(p2_reflection_defect) || ...
      p2_reflection_defect > spec.coordinate_tolerance
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s has an invalid P2 reflection coordinate defect.', ...
      mesh_spec.id));
  end
  LOCAL_validate_p2_reflection(points, edges, reflection_index, ...
    p2_reflection_index);
  p2_node_count = size(p2_points, 1);
  reflection = sparse((1:p2_node_count).', p2_reflection_index, 1, ...
    p2_node_count, p2_node_count);
  reflection_stiffness_defect = norm(stiffness_full - ...
    reflection' * stiffness_full * reflection, 1) / ...
    max(1, norm(stiffness_full, 1));
  reflection_mass_defect = norm(mass_full - ...
    reflection' * mass_full * reflection, 1) / ...
    max(1, norm(mass_full, 1));
  p1_periodic = LOCAL_periodic_maps( ...
    points, xmin, xmax, ymin, ymax, spec.coordinate_tolerance);
  periodic = LOCAL_periodic_maps( ...
    p2_points, xmin, xmax, ymin, ymax, spec.coordinate_tolerance);
  LOCAL_validate_midpoint_periodicity(spec, points, edges, edge_incidence, ...
    periodic, p1_periodic);
  hausdorff_defect = spec.radius * (1 - cos(pi / mesh_spec.n_gamma));
  mesh = struct('id', mesh_spec.id, 'kind', mesh_spec.kind, ...
    'N', mesh_spec.N, 's', mesh_spec.s, 'n_gamma', mesh_spec.n_gamma, ...
    'points', points, 'triangles', triangles, ...
    'edges', edges, 'triangle_p2', triangle_p2, ...
    'p2_points', p2_points, 'edge_incidence', edge_incidence, ...
    'boundary_edge_count', boundary_edge_count, ...
    'material_inside', material_inside, 'disk_centers', disk_centers, ...
    'stiffness_full', stiffness_full, 'mass_full', mass_full, ...
    'mass_center', mass_center, 'mass_core', mass_core, ...
    'mass_tail', mass_tail, 'reflection_index', p2_reflection_index, ...
    'p1_stiffness_full', p1_stiffness_full, ...
    'p1_mass_full', p1_mass_full, 'p1_mass_center', p1_mass_center, ...
    'p1_mass_core', p1_mass_core, 'p1_mass_tail', p1_mass_tail, ...
    'p1_reflection_index', reflection_index, 'p1_periodic', p1_periodic, ...
    'periodic', periodic, 'reduced_dof', max(periodic.master_index), ...
    'p1_reduced_dof', max(p1_periodic.master_index), ...
    'element_validation', element_validation, ...
    'embedding_validation', embedding_validation, ...
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

function [edges, triangle_p2, p2_points, incidence, boundary_count] = ...
    LOCAL_p2_topology(points, triangles)
  triangle_count = size(triangles, 1);
  local_edges = [triangles(:, [1, 2]); triangles(:, [2, 3]); ...
    triangles(:, [3, 1])];
  [edges, ~, edge_ids] = unique(sort(local_edges, 2), 'rows');
  if any(edges(:, 1) == edges(:, 2))
    LOCAL_raise('MESH_INVALID', 'A P2 edge has duplicate endpoints.');
  end
  incidence = accumarray(edge_ids, 1, [size(edges, 1), 1]);
  if any(incidence < 1 | incidence > 2)
    LOCAL_raise('MESH_INVALID', ...
      'An active edge does not have boundary/interior incidence one/two.');
  end
  edge_by_triangle = [edge_ids(1:triangle_count), ...
    edge_ids((triangle_count + 1):(2 * triangle_count)), ...
    edge_ids((2 * triangle_count + 1):(3 * triangle_count))];
  vertex_count = size(points, 1);
  triangle_p2 = [triangles, vertex_count + edge_by_triangle];
  midpoints = (points(edges(:, 1), :) + points(edges(:, 2), :)) / 2;
  p2_points = [points; midpoints];
  if any(~isfinite(p2_points), 'all')
    LOCAL_raise('MESH_INVALID', 'The global P2 midpoint topology is invalid.');
  end
  boundary_count = nnz(incidence == 1);
end

function validation = LOCAL_validate_p2_element(spec)
  interpolation_nodes = [1, 0, 0; 0, 1, 0; 0, 0, 1; ...
    0.5, 0.5, 0; 0, 0.5, 0.5; 0.5, 0, 0.5];
  [quadrature_points, quadrature_weights] = LOCAL_p2_quadrature();
  reference_gradients = [-1, 1, 0; -1, 0, 1];
  nodal_matrix = zeros(6);
  partition_value_defect = 0;
  partition_gradient_defect = 0;
  probes = [interpolation_nodes; quadrature_points];
  for index = 1:size(probes, 1)
    [basis, gradients] = LOCAL_p2_basis( ...
      probes(index, :), reference_gradients);
    partition_value_defect = max(partition_value_defect, ...
      abs(sum(basis) - 1));
    partition_gradient_defect = max(partition_gradient_defect, ...
      norm(sum(gradients, 2), 2));
    if index <= 6
      nodal_matrix(index, :) = basis;
    end
  end
  nodal_defect = norm(nodal_matrix - eye(6), inf);
  monomial_defect = 0;
  for degree = 0:5
    for exponent_1 = 0:degree
      for exponent_2 = 0:(degree - exponent_1)
        exponent_3 = degree - exponent_1 - exponent_2;
        observed = sum(quadrature_weights .* ...
          quadrature_points(:, 1) .^ exponent_1 .* ...
          quadrature_points(:, 2) .^ exponent_2 .* ...
          quadrature_points(:, 3) .^ exponent_3);
        exact = 2 * factorial(exponent_1) * factorial(exponent_2) * ...
          factorial(exponent_3) / factorial(degree + 2);
        defect = abs(observed - exact) / max(1, abs(exact));
        monomial_defect = max(monomial_defect, defect);
      end
    end
  end
  if nodal_defect > spec.nodal_tolerance || ...
      partition_value_defect > spec.nodal_tolerance || ...
      partition_gradient_defect > spec.partition_gradient_tolerance || ...
      monomial_defect > spec.monomial_tolerance
    LOCAL_raise('DISCRETE_IMPLEMENTATION_INVALID', ...
      'The frozen P2 nodal, partition, or quadrature check failed.');
  end
  validation = struct('nodal_defect', nodal_defect, ...
    'partition_value_defect', partition_value_defect, ...
    'partition_gradient_defect', partition_gradient_defect, ...
    'monomial_defect', monomial_defect);
end

function [points, weights] = LOCAL_p2_quadrature()
  a = 0.059715871789770;
  b = 0.470142064105115;
  c = 0.797426985353087;
  d = 0.101286507323456;
  points = [1 / 3, 1 / 3, 1 / 3; ...
    a, b, b; b, a, b; b, b, a; ...
    c, d, d; d, c, d; d, d, c];
  weights = [0.225; repmat(0.132394152788506, 3, 1); ...
    repmat(0.125939180544827, 3, 1)];
end

function [basis, gradients] = LOCAL_p2_basis(lambda, gradient_lambda)
  basis = [lambda(1) * (2 * lambda(1) - 1), ...
    lambda(2) * (2 * lambda(2) - 1), ...
    lambda(3) * (2 * lambda(3) - 1), ...
    4 * lambda(1) * lambda(2), ...
    4 * lambda(2) * lambda(3), ...
    4 * lambda(3) * lambda(1)];
  gradients = zeros(2, 6);
  gradients(:, 1) = (4 * lambda(1) - 1) * gradient_lambda(:, 1);
  gradients(:, 2) = (4 * lambda(2) - 1) * gradient_lambda(:, 2);
  gradients(:, 3) = (4 * lambda(3) - 1) * gradient_lambda(:, 3);
  gradients(:, 4) = 4 * (lambda(1) * gradient_lambda(:, 2) + ...
    lambda(2) * gradient_lambda(:, 1));
  gradients(:, 5) = 4 * (lambda(2) * gradient_lambda(:, 3) + ...
    lambda(3) * gradient_lambda(:, 2));
  gradients(:, 6) = 4 * (lambda(3) * gradient_lambda(:, 1) + ...
    lambda(1) * gradient_lambda(:, 3));
end

function [stiffness_full, mass_full, mass_center, mass_core, mass_tail, ...
    validation] = LOCAL_assemble_p2(spec, mesh_spec, points, triangles, ...
    triangle_p2, centroids, material_inside)
  triangle_count = size(triangles, 1);
  entry_count = 36 * triangle_count;
  rows = zeros(entry_count, 1);
  columns = zeros(entry_count, 1);
  stiffness_values = zeros(entry_count, 1);
  mass_values = zeros(entry_count, 1);
  center_values = zeros(entry_count, 1);
  core_values = zeros(entry_count, 1);
  tail_values = zeros(entry_count, 1);
  [quadrature_points, quadrature_weights] = LOCAL_p2_quadrature();
  embedding = [1, 0, 0; 0, 1, 0; 0, 0, 1; ...
    0.5, 0.5, 0; 0, 0.5, 0.5; 0.5, 0, 0.5];
  maximum_stiffness_embedding_defect = 0;
  maximum_mass_embedding_defect = 0;
  for triangle_index = 1:triangle_count
    vertices = triangles(triangle_index, :);
    coordinates = points(vertices, :);
    twice_area = det([coordinates(2, :) - coordinates(1, :); ...
      coordinates(3, :) - coordinates(1, :)]);
    area = abs(twice_area) / 2;
    gradient_lambda = [ ...
      coordinates(2, 2) - coordinates(3, 2), ...
      coordinates(3, 2) - coordinates(1, 2), ...
      coordinates(1, 2) - coordinates(2, 2); ...
      coordinates(3, 1) - coordinates(2, 1), ...
      coordinates(1, 1) - coordinates(3, 1), ...
      coordinates(2, 1) - coordinates(1, 1)] / twice_area;
    local_stiffness = zeros(6);
    local_mass_unit = zeros(6);
    for quadrature_index = 1:7
      [basis, gradients] = LOCAL_p2_basis( ...
        quadrature_points(quadrature_index, :), gradient_lambda);
      weight = area * quadrature_weights(quadrature_index);
      local_stiffness = local_stiffness + weight * ...
        (gradients' * gradients);
      local_mass_unit = local_mass_unit + weight * (basis' * basis);
    end
    coefficient = spec.q_outside + ...
      (spec.q_inside - spec.q_outside) * material_inside(triangle_index);
    local_mass = coefficient * local_mass_unit;
    p1_stiffness = area * (gradient_lambda' * gradient_lambda);
    p1_mass = coefficient * area * ...
      [2, 1, 1; 1, 2, 1; 1, 1, 2] / 12;
    stiffness_defect = norm(embedding' * local_stiffness * embedding - ...
      p1_stiffness, 'fro') / max(1, norm(p1_stiffness, 'fro'));
    mass_defect = norm(embedding' * local_mass * embedding - p1_mass, ...
      'fro') / max(1, norm(p1_mass, 'fro'));
    maximum_stiffness_embedding_defect = max( ...
      maximum_stiffness_embedding_defect, stiffness_defect);
    maximum_mass_embedding_defect = max( ...
      maximum_mass_embedding_defect, mass_defect);
    block = (36 * (triangle_index - 1) + 1):(36 * triangle_index);
    nodes = triangle_p2(triangle_index, :);
    [local_rows, local_columns] = ndgrid(nodes, nodes);
    rows(block) = local_rows(:);
    columns(block) = local_columns(:);
    stiffness_values(block) = local_stiffness(:);
    mass_values(block) = local_mass(:);
    center_values(block) = local_mass(:) * ...
      (abs(centroids(triangle_index, 1)) < 0.5);
    core_values(block) = local_mass(:) * ...
      (abs(centroids(triangle_index, 1)) < 1.5);
    if strcmp(mesh_spec.kind, 'defect')
      tail_values(block) = local_mass(:) * ...
        (abs(centroids(triangle_index, 1)) > mesh_spec.N - 1.5);
    end
  end
  if maximum_stiffness_embedding_defect > spec.embedding_tolerance || ...
      maximum_mass_embedding_defect > spec.embedding_tolerance
    LOCAL_raise('DISCRETE_IMPLEMENTATION_INVALID', ...
      'A local P1-in-P2 bilinear embedding identity failed.');
  end
  dof_count = max(triangle_p2(:));
  stiffness_full = sparse(rows, columns, stiffness_values, ...
    dof_count, dof_count);
  mass_full = sparse(rows, columns, mass_values, dof_count, dof_count);
  mass_center = sparse(rows, columns, center_values, dof_count, dof_count);
  mass_core = sparse(rows, columns, core_values, dof_count, dof_count);
  mass_tail = sparse(rows, columns, tail_values, dof_count, dof_count);
  validation = struct( ...
    'maximum_stiffness_embedding_defect', ...
    maximum_stiffness_embedding_defect, ...
    'maximum_mass_embedding_defect', maximum_mass_embedding_defect);
end

function LOCAL_validate_midpoint_periodicity(spec, points, edges, incidence, ...
    periodic, p1_periodic)
  boundary_edges = find(incidence == 1);
  endpoint_classes = sort([p1_periodic.master_index(edges(boundary_edges, 1)), ...
    p1_periodic.master_index(edges(boundary_edges, 2))], 2);
  midpoint_rows = size(points, 1) + boundary_edges;
  midpoint_classes = periodic.master_index(midpoint_rows);
  [groups, ~, group_index] = unique(endpoint_classes, 'rows'); %#ok<ASGLU>
  for index = 1:size(groups, 1)
    members = find(group_index == index);
    if numel(members) ~= 2 || ...
        numel(unique(midpoint_classes(members))) ~= 1
      LOCAL_raise('QUASIPERIODIC_MAP_INVALID', ...
        'A periodic boundary edge midpoint is not paired bijectively.');
    end
  end
  if periodic.coordinate_mismatch > spec.coordinate_tolerance
    LOCAL_raise('QUASIPERIODIC_MAP_INVALID', ...
      'The P2 periodic coordinate pairing is inconsistent.');
  end
end

function LOCAL_validate_p2_reflection(points, edges, vertex_reflection, ...
    p2_reflection)
  reflected_edges = sort([vertex_reflection(edges(:, 1)), ...
    vertex_reflection(edges(:, 2))], 2);
  [found, reflected_edge_id] = ismember(reflected_edges, edges, 'rows');
  vertex_count = size(points, 1);
  expected = vertex_count + reflected_edge_id;
  actual = p2_reflection(vertex_count + (1:size(edges, 1))).';
  if any(~found) || ~isequal(actual(:), expected(:))
    LOCAL_raise('DISCRETE_IMPLEMENTATION_INVALID', ...
      'The P2 midpoint reflection does not follow reflected edge endpoints.');
  end
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
  [prolongation, phases] = LOCAL_phase_prolongation( ...
    mesh.periodic, phase_x, spec.beta);
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
  global_embedding = struct('required', false, 'commutator_defect', NaN, ...
    'stiffness_defect', NaN, 'mass_defect', NaN);
  if LOCAL_embedding_phase_required(mesh.id, phase_x)
    global_embedding = LOCAL_global_embedding_check( ...
      spec, mesh, phase_x, prolongation, stiffness, mass);
  end
  pair = struct('stiffness', stiffness, 'mass', mass, ...
    'mass_factor', mass_factor, 'prolongation', prolongation);
  diagnostic = struct('phase_kind', phase_kind, 'phase', phase_x, ...
    'seam_residual', seam_residual, 'global_embedding', global_embedding, ...
    'phase_factor_min', min(abs(phases)), ...
    'phase_factor_max', max(abs(phases)));
end

function [prolongation, phases] = LOCAL_phase_prolongation( ...
    periodic, phase_x, beta)
  phases = exp(1i * (phase_x * double(periodic.x_slave) + ...
    beta * double(periodic.y_slave)));
  full_dof = numel(periodic.master_index);
  reduced_dof = max(periodic.master_index);
  prolongation = sparse((1:full_dof).', periodic.master_index, phases, ...
    full_dof, reduced_dof);
  if nnz(prolongation) ~= full_dof || ...
      any(sum(spones(prolongation), 2) ~= 1) || ...
      any(sum(spones(prolongation), 1) == 0) || ...
      any(abs(abs(nonzeros(prolongation)) - 1) > 5e-14)
    LOCAL_raise('QUASIPERIODIC_MAP_INVALID', ...
      'The phase prolongation is not a supported unit-modulus map.');
  end
end

function required = LOCAL_embedding_phase_required(mesh_id, phase_x)
  required = abs(phase_x - pi / 4) < 1e-13 && any(strcmp(mesh_id, ...
    {'bulk-s12-g36', 'defect-N5-s12-g36', 'defect-N5-s18-g48'}));
end

function diagnostic = LOCAL_global_embedding_check( ...
    spec, mesh, phase_x, p2_prolongation, p2_stiffness, p2_mass)
  [p1_prolongation, ~] = LOCAL_phase_prolongation( ...
    mesh.p1_periodic, phase_x, spec.beta);
  vertex_count = size(mesh.points, 1);
  edge_count = size(mesh.edges, 1);
  embedding_full = sparse(vertex_count + edge_count, vertex_count);
  embedding_full(1:vertex_count, 1:vertex_count) = speye(vertex_count);
  edge_rows = vertex_count + (1:edge_count);
  embedding_full = embedding_full + sparse( ...
    [edge_rows, edge_rows], ...
    [mesh.edges(:, 1).', mesh.edges(:, 2).'], 0.5, ...
    vertex_count + edge_count, vertex_count);
  embedded = embedding_full * p1_prolongation;
  master_rows = accumarray(mesh.periodic.master_index, ...
    (1:size(mesh.p2_points, 1)).', [], @min);
  p2_phase = full(sum(p2_prolongation, 2));
  embedding_reduced = spdiags(1 ./ p2_phase(master_rows), 0, ...
    numel(master_rows), numel(master_rows)) * embedded(master_rows, :);
  commutator_defect = norm(embedded - ...
    p2_prolongation * embedding_reduced, 'fro') / ...
    max(1, norm(embedded, 'fro'));
  p1_stiffness = LOCAL_canonical_hermitian( ...
    p1_prolongation' * mesh.p1_stiffness_full * p1_prolongation);
  p1_mass = LOCAL_canonical_hermitian( ...
    p1_prolongation' * mesh.p1_mass_full * p1_prolongation);
  stiffness_defect = norm(embedding_reduced' * p2_stiffness * ...
    embedding_reduced - p1_stiffness, 'fro') / ...
    max(1, norm(p1_stiffness, 'fro'));
  mass_defect = norm(embedding_reduced' * p2_mass * ...
    embedding_reduced - p1_mass, 'fro') / max(1, norm(p1_mass, 'fro'));
  if max([commutator_defect, stiffness_defect, mass_defect]) > ...
      spec.embedding_tolerance
    LOCAL_raise('DISCRETE_IMPLEMENTATION_INVALID', ...
      'A named global P1-in-P2 phase identity failed.');
  end
  diagnostic = struct('required', true, ...
    'commutator_defect', commutator_defect, ...
    'stiffness_defect', stiffness_defect, 'mass_defect', mass_defect);
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
  subspace_dimension = LOCAL_eigs_subspace(spec, requested_nev);
  if reduced_dof <= subspace_dimension
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      sprintf('%s has insufficient reduced DOF.', mesh.id));
  end
  master_rows = accumarray(mesh.periodic.master_index, ...
    (1:size(mesh.p2_points, 1)).', [], @min);
  master_points = mesh.p2_points(master_rows, :);
  start_vector = (1 + cos(sqrt(2) * master_points(:, 1)) / 8 + ...
    sin(sqrt(3) * master_points(:, 2)) / 8) .* ...
    exp(1i * ((sqrt(5) - 2) * master_points(:, 1) + ...
    (sqrt(7) - 2) * master_points(:, 2)));
  start_vector = start_vector / norm(start_vector, 2);
  options = struct('tol', tolerance, 'maxit', spec.eigs_maxit, ...
    'p', subspace_dimension, 'v0', start_vector, ...
    'issym', true, 'isreal', false, 'disp', 0);
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
    'element_order', 'p2', ...
    'requested_nev', requested_nev, 'solver_flag', solver_flag, ...
    'eigenvalues', eigenvalues, 'frequencies', frequencies, ...
    'residuals', residuals, 'cluster_ids', cluster_ids, ...
    'cluster_multiplicities', multiplicities, ...
    'vectors_full', vectors_full, ...
    'orthogonality_defect', orthogonality_defect);
end

function [pair, diagnostic] = LOCAL_phase_reduce_p1( ...
    spec, mesh, phase_x)
  [prolongation, ~] = LOCAL_phase_prolongation( ...
    mesh.p1_periodic, phase_x, spec.beta);
  stiffness_raw = prolongation' * mesh.p1_stiffness_full * prolongation;
  mass_raw = prolongation' * mesh.p1_mass_full * prolongation;
  x_residual = norm(prolongation(mesh.p1_periodic.right_nodes, :) - ...
    exp(1i * phase_x) * ...
    prolongation(mesh.p1_periodic.left_nodes, :), inf);
  y_residual = norm(prolongation(mesh.p1_periodic.top_nodes, :) - ...
    exp(1i * spec.beta) * ...
    prolongation(mesh.p1_periodic.bottom_nodes, :), inf);
  seam_residual = max(x_residual, y_residual);
  if seam_residual > spec.seam_tolerance
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', ...
      'A companion P1 phase space fails its seam identities.');
  end
  stiffness = LOCAL_checked_hermitian( ...
    spec, stiffness_raw, false, 'SPECTRUM_INVENTORY_TRUNCATED');
  [mass, mass_factor] = LOCAL_checked_hermitian( ...
    spec, mass_raw, true, 'SPECTRUM_INVENTORY_TRUNCATED');
  pair = struct('stiffness', stiffness, 'mass', mass, ...
    'mass_factor', mass_factor, 'prolongation', prolongation);
  diagnostic = struct('phase_kind', 'companion-p1-theta', ...
    'phase', phase_x, 'seam_residual', seam_residual);
end

function [spectrum, phase_diagnostic] = LOCAL_low_spectrum_p1( ...
    spec, mesh, phase_x, tolerance, requested_nev, role)
  [pair, phase_diagnostic] = LOCAL_phase_reduce_p1(spec, mesh, phase_x);
  subspace_dimension = LOCAL_eigs_subspace(spec, requested_nev);
  reduced_dof = size(pair.stiffness, 1);
  if reduced_dof <= subspace_dimension
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'The companion P1 space has insufficient reduced DOF.');
  end
  master_rows = accumarray(mesh.p1_periodic.master_index, ...
    (1:size(mesh.points, 1)).', [], @min);
  master_points = mesh.points(master_rows, :);
  start_vector = (1 + cos(sqrt(2) * master_points(:, 1)) / 8 + ...
    sin(sqrt(3) * master_points(:, 2)) / 8) .* ...
    exp(1i * ((sqrt(5) - 2) * master_points(:, 1) + ...
    (sqrt(7) - 2) * master_points(:, 2)));
  start_vector = start_vector / norm(start_vector);
  options = struct('tol', tolerance, 'maxit', spec.eigs_maxit, ...
    'p', subspace_dimension, 'v0', start_vector, ...
    'issym', true, 'isreal', false, 'disp', 0);
  [vectors_reduced, diagonal_values, solver_flag] = eigs( ...
    pair.stiffness, pair.mass, requested_nev, 'smallestabs', options);
  eigenvalues_complex = diag(diagonal_values);
  if solver_flag ~= 0 || numel(eigenvalues_complex) ~= requested_nev || ...
      size(vectors_reduced, 2) ~= requested_nev || ...
      any(~isfinite(eigenvalues_complex)) || ...
      any(~isfinite(vectors_reduced), 'all')
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'A companion P1 solve returned an incomplete inventory.');
  end
  relative_imaginary = abs(imag(eigenvalues_complex)) ./ ...
    max(1, abs(real(eigenvalues_complex)));
  if any(relative_imaginary > spec.imaginary_tolerance) || ...
      any(real(eigenvalues_complex) <= 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'A companion P1 eigenvalue is nonpositive or nonreal.');
  end
  [eigenvalues, order] = sort(real(eigenvalues_complex), 'ascend');
  vectors_reduced = vectors_reduced(:, order);
  for root_index = 1:requested_nev
    mass_norm = real(vectors_reduced(:, root_index)' * pair.mass * ...
      vectors_reduced(:, root_index));
    if ~isfinite(mass_norm) || mass_norm <= 0
      LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
        'A companion P1 vector has invalid mass norm.');
    end
    vectors_reduced(:, root_index) = ...
      vectors_reduced(:, root_index) / sqrt(mass_norm);
  end
  frequencies = sqrt(eigenvalues);
  stiffness_norm = norm(pair.stiffness, 1);
  mass_operator_norm = norm(pair.mass, 1);
  residuals = zeros(requested_nev, 1);
  for root_index = 1:requested_nev
    vector = vectors_reduced(:, root_index);
    residuals(root_index) = norm(pair.stiffness * vector - ...
      eigenvalues(root_index) * pair.mass * vector, 2) / ...
      ((stiffness_norm + eigenvalues(root_index) * mass_operator_norm) * ...
      norm(vector, 2));
  end
  cluster_ids = LOCAL_cluster_ids(spec, frequencies, residuals);
  vectors_reduced = LOCAL_normalize_defect_clusters( ...
    spec, pair.mass, vectors_reduced, cluster_ids);
  for root_index = 1:requested_nev
    vector = vectors_reduced(:, root_index);
    residuals(root_index) = norm(pair.stiffness * vector - ...
      eigenvalues(root_index) * pair.mass * vector, 2) / ...
      ((stiffness_norm + eigenvalues(root_index) * mass_operator_norm) * ...
      norm(vector, 2));
  end
  orthogonality_defect = norm(vectors_reduced' * pair.mass * ...
    vectors_reduced - eye(requested_nev), 2);
  if orthogonality_defect > spec.orthogonality_tolerance || ...
      any(residuals > spec.residual_tolerance) || any(diff(frequencies) < 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'A companion P1 residual/orthogonality/order check failed.');
  end
  vectors_full = pair.prolongation * vectors_reduced;
  spectrum = struct('mesh_id', mesh.id, 'phase', phase_x, 'role', role, ...
    'element_order', 'p1', 'requested_nev', requested_nev, ...
    'solver_flag', solver_flag, 'eigenvalues', eigenvalues, ...
    'frequencies', frequencies, 'residuals', residuals, ...
    'cluster_ids', cluster_ids, ...
    'cluster_multiplicities', accumarray(cluster_ids, 1), ...
    'vectors_full', vectors_full, ...
    'orthogonality_defect', orthogonality_defect);
end

function subspace_dimension = LOCAL_eigs_subspace(spec, requested_nev)
  if requested_nev == 40
    subspace_dimension = spec.eigs_subspace_40;
  elseif requested_nev == 48
    subspace_dimension = spec.eigs_subspace_48;
  elseif requested_nev == 60
    subspace_dimension = spec.eigs_subspace_60;
  else
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'The requested root count has no frozen Arnoldi dimension.');
  end
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
  levels(1) = struct('id', 'B1', 'mesh_id', 'bulk-s12-g36', ...
    'alphas', spec.bulk_alpha_17, 'tol', 1e-9);
  levels(2) = struct('id', 'B2', 'mesh_id', 'bulk-s18-g36', ...
    'alphas', spec.bulk_alpha_17, 'tol', 1e-10);
  levels(3) = struct('id', 'B4', 'mesh_id', 'bulk-s18-g48', ...
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
      spec, registry, work_dir, solve_id, 'bulk-s18-g48', phase, ...
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
  anchor_base = entries(strcmp({entries.configuration}, 'p2-anchor'));
  coverage_48_w3 = LOCAL_all_slice_ceiling_pass( ...
    anchor_base, spec.search_windows(4, 2) + ...
    spec.upper_sentinel_margin, 17);
  expansion_performed = ~coverage_48_w3;
  expansion_inconsistent = false;
  if expansion_performed
    run_state.planned_solves = spec.maximum_solves;
    expansion = LOCAL_add_solve_group(LOCAL_empty_defect_schedule(), ...
      'p2-anchor-expand60', 'defect-N5-s18-g48', spec.theta_17, 1e-11, ...
      spec.defect_expand_nev, 'expansion-60', 'p2-anchor');
    for solve_index = 1:numel(expansion)
      [entry, run_state] = LOCAL_run_defect_item( ...
        spec, registry, work_dir, output_dir, run_state, ...
        expansion(solve_index));
      base_index = find(abs([anchor_base.theta] - entry.theta) < 1e-13, 1);
      entry.agreement = LOCAL_expansion_agreement( ...
        spec, anchor_base(base_index), entry, registry, work_dir);
      expansion_inconsistent = expansion_inconsistent || ...
        ~entry.agreement.pass;
      entries(end + 1) = entry; %#ok<AGROW>
    end
  end
  defect_inventory = struct('entries', entries, ...
    'base_schedule_count', 47, ...
    'expansion_performed', expansion_performed, ...
    'expansion_inconsistent', expansion_inconsistent, ...
    'actual_schedule_count', numel(entries));
  defect_inventory.root_coverage = LOCAL_root_coverage(spec, entries);
  if expansion_inconsistent || ...
      ~defect_inventory.root_coverage.p2_anchor.covered_by_window(4)
    defect_inventory.coverage_status = 'SPECTRUM_COVERAGE_PARTIAL';
  else
    defect_inventory.coverage_status = 'SPECTRUM_COVERED_THROUGH_W3';
  end
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
    'path', {}, 'failure_code', {}, 'failure_reason', {}, 'summary', {}, ...
    'agreement', {});
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
    'failure_code', code, 'failure_reason', reason, 'summary', summary, ...
    'agreement', struct('pass', false, 'frequency_mismatch', NaN, ...
    'cluster_match', false, 'minimum_overlap', NaN, ...
    'status', 'NOT_APPLICABLE'));
end

function agreement = LOCAL_expansion_agreement( ...
    spec, base_entry, expansion_entry, registry, work_dir)
  agreement = struct('pass', false, 'frequency_mismatch', NaN, ...
    'cluster_match', false, 'minimum_overlap', NaN, ...
    'status', 'SPECTRUM_EXPANSION_INCONSISTENT');
  if ~base_entry.valid || ~expansion_entry.valid
    return;
  end
  base = LOCAL_load_spectrum(base_entry.path);
  expansion = LOCAL_load_spectrum(expansion_entry.path);
  mesh = LOCAL_load_mesh(registry, work_dir, base_entry.mesh_id);
  agreement.frequency_mismatch = max(abs( ...
    base.frequencies - expansion.frequencies(1:48)));
  agreement.cluster_match = isequal( ...
    base.cluster_ids, expansion.cluster_ids(1:48));
  overlaps = zeros(max(base.cluster_ids), 1);
  if agreement.cluster_match
    for cluster_id = 1:max(base.cluster_ids)
      roots = find(base.cluster_ids == cluster_id);
      singular_values = svd(base.vectors_full(:, roots)' * ...
        mesh.mass_full * expansion.vectors_full(:, roots));
      overlaps(cluster_id) = min(singular_values);
    end
    agreement.minimum_overlap = min(overlaps);
  end
  agreement.pass = agreement.frequency_mismatch <= ...
    spec.expansion_frequency_tolerance && agreement.cluster_match && ...
    agreement.minimum_overlap >= 1 - spec.expansion_overlap_tolerance;
  if agreement.pass
    agreement.status = 'SPECTRUM_EXPANSION_CONSISTENT';
  end
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
    if strcmp(name, 'p2-anchor')
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
  if ~strcmp(name, 'p2-anchor')
    selected = base;
    return;
  end
  expansion = entries(strcmp({entries.role}, 'expansion-60'));
  selected = base;
  for index = 1:numel(selected)
    replacement = find(abs([expansion.theta] - selected(index).theta) < ...
      1e-13 & [expansion.valid] & ...
      arrayfun(@(entry) entry.agreement.pass, expansion), 1);
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
  loose = entries(strcmp({entries.configuration}, 'p2-loose'));
  fine = LOCAL_effective_entries(entries, 'p2-anchor');
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

%% ==================== Current-run P1 companions ====================
% Design Sections 4.2, 8 and 15 keep this graph outside the P2 rank.

function [inventory, run_state] = LOCAL_companion_inventory( ...
    spec, registry, work_dir, output_dir, run_state, defect_inventory, ...
    p2_inventory)
  anchor_entries = LOCAL_effective_entries( ...
    defect_inventory.entries, 'p2-anchor');
  entries = struct('id', {}, 'theta', {}, 'valid', {}, 'path', {}, ...
    'failure_code', {}, 'failure_reason', {}, 'ritz_max_excess', {});
  p1_objects = LOCAL_empty_objects();
  next_object_id = numel(p2_inventory.objects) + 1;
  for theta_index = 1:numel(spec.theta_5)
    theta = spec.theta_5(theta_index);
    solve_id = sprintf('p1-companion-p%02d', theta_index);
    [valid, spectrum, path, code, reason] = ...
      LOCAL_attempt_companion_spectrum(spec, registry, work_dir, ...
      solve_id, theta);
    run_state = LOCAL_record_solve( ...
      run_state, output_dir, solve_id, valid);
    ritz_max_excess = NaN;
    anchor_index = find(abs([anchor_entries.theta] - theta) < 1e-13, 1);
    if valid && ~isempty(anchor_index) && anchor_entries(anchor_index).valid
      p2_spectrum = LOCAL_load_spectrum(anchor_entries(anchor_index).path);
      p2_values = p2_spectrum.eigenvalues(1:48);
      p2_residuals = p2_spectrum.residuals(1:48);
      allowance = 20 * (spectrum.residuals + p2_residuals) + ...
        500 * eps .* max([ones(48, 1), abs(spectrum.eigenvalues), ...
        abs(p2_values)], [], 2);
      excess = p2_values - spectrum.eigenvalues - allowance;
      ritz_max_excess = max(excess);
      if ritz_max_excess > 0
        LOCAL_raise('DISCRETE_IMPLEMENTATION_INVALID', ...
          'The ordered same-geometry P1/P2 Rayleigh--Ritz check failed.');
      end
    end
    entries(end + 1) = struct('id', solve_id, 'theta', theta, ...
      'valid', valid, 'path', path, 'failure_code', code, ...
      'failure_reason', reason, 'ritz_max_excess', ritz_max_excess); %#ok<AGROW>
    if ~valid
      continue;
    end
    mesh = LOCAL_load_mesh(registry, work_dir, 'defect-N5-s18-g48');
    objects = LOCAL_w3_clusters_p1(spec, mesh, spectrum);
    for object_index = 1:numel(objects)
      object = objects(object_index);
      object.object_id = next_object_id;
      object.seed_candidate_id = next_object_id;
      object.configuration = 'p1-companion';
      object.configuration_priority = numel(spec.configuration_priority) + 1;
      object.solve_id = solve_id;
      object.mesh_id = mesh.id;
      object.theta = theta;
      object.theta_index = theta_index;
      p1_objects(end + 1) = object; %#ok<AGROW>
      next_object_id = next_object_id + 1;
    end
  end
  combined = [p2_inventory.objects, p1_objects];
  assignments = LOCAL_empty_tracking_edges();
  for theta_index = 1:numel(spec.theta_5)
    theta = spec.theta_5(theta_index);
    source_ids = [p1_objects(abs([p1_objects.theta] - theta) < 1e-13).object_id];
    target_ids = [p2_inventory.objects( ...
      strcmp({p2_inventory.objects.configuration}, 'p2-anchor') & ...
      abs([p2_inventory.objects.theta] - theta) < 1e-13).object_id];
    new_assignments = LOCAL_assign_object_sets( ...
      spec, combined, source_ids, target_ids, 'p1-p2', ...
      'cross-order-non-ranking');
    assignments = [assignments, new_assignments]; %#ok<AGROW>
  end
  inventory = struct('entries', entries, 'objects', p1_objects, ...
    'assignments', assignments, 'rank_influence', false);
end

function [valid, spectrum, path, code, reason] = ...
    LOCAL_attempt_companion_spectrum( ...
    spec, registry, work_dir, solve_id, theta)
  valid = false;
  spectrum = struct([]);
  path = '';
  code = '';
  reason = '';
  try
    mesh = LOCAL_load_mesh( ...
      registry, work_dir, 'defect-N5-s18-g48');
    spectrum = LOCAL_low_spectrum_p1( ...
      spec, mesh, theta, 1e-11, 48, 'p1-companion');
    path = fullfile(work_dir, [solve_id '.mat']);
    LOCAL_save_spectrum(path, spectrum);
    valid = true;
  catch caught
    [code, reason] = LOCAL_decode_failure(caught);
    recordable = any(strcmp(code, {'QUASIPERIODIC_SEAM_UNRESOLVED', ...
      'SPECTRUM_INVENTORY_TRUNCATED', 'NUMERICAL_OBJECT_INVALID'}));
    if strcmp(code, 'EXECUTION_UNAVAILABLE') || startsWith(code, 'OUTPUT_') || ...
        ~recordable
      rethrow(caught);
    end
  end
end

function objects = LOCAL_w3_clusters_p1(spec, mesh, spectrum)
  objects = LOCAL_empty_objects();
  w3 = spec.search_windows(4, :);
  for cluster_id = unique(spectrum.cluster_ids).'
    roots = find(spectrum.cluster_ids == cluster_id);
    envelope = [min(spectrum.frequencies(roots)), ...
      max(spectrum.frequencies(roots))];
    if envelope(2) < w3(1) || envelope(1) > w3(2)
      continue;
    end
    subspace = spectrum.vectors_full(:, roots);
    gram = subspace' * mesh.p1_mass_full * subspace;
    [~, factor] = LOCAL_checked_hermitian( ...
      spec, gram, true, 'NUMERICAL_OBJECT_INVALID');
    subspace = subspace / factor;
    samples = [];
    weights = [];
    common_valid = false;
    common_reason = '';
    try
      [samples, weights] = LOCAL_sample_subspace_p1(spec, mesh, subspace);
      [~, sample_factor] = LOCAL_checked_hermitian(spec, ...
        samples' * (weights .* samples), true, ...
        'TRACKING_DIAGNOSTIC_UNAVAILABLE');
      samples = samples / sample_factor;
      common_valid = true;
    catch caught
      [~, common_reason] = LOCAL_decode_failure(caught);
      samples = [];
      weights = [];
    end
    object = LOCAL_empty_object();
    object.cluster_id = cluster_id;
    object.root_index = roots(1);
    object.root_indices = roots;
    object.dimension = numel(roots);
    object.eigenvalues = spectrum.eigenvalues(roots);
    object.frequencies = spectrum.frequencies(roots);
    object.lambda_envelope = [min(object.eigenvalues), max(object.eigenvalues)];
    object.k_envelope = envelope;
    object.subspace = subspace;
    object.residual_max = max(spectrum.residuals(roots));
    object.L0_min = NaN;
    object.Lcore_min = NaN;
    object.tail_max = NaN;
    object.localization_status = 'NON_RANKING_COMPANION';
    object.localization_reason = '';
    object.parity_values = [];
    object.parity_label = 'non-ranking-companion';
    object.parity_status = 'NON_RANKING_COMPANION';
    object.parity_reason = '';
    object.common_core_samples = samples;
    object.common_core_weights = weights;
    object.common_core_valid = common_valid;
    object.common_core_reason = common_reason;
    object.window_label = LOCAL_window_label(spec, envelope);
    object.window_edge_straddle = ...
      envelope(1) < w3(1) || envelope(2) > w3(2);
    object.gap_label = 'COMPANION_NON_RANKING';
    objects(end + 1) = object; %#ok<AGROW>
  end
end

function [inventory, selected] = LOCAL_attach_companion_drift( ...
    spec, inventory, selected_id, companion)
  p1_ids = [companion.objects.object_id];
  p2_objects = inventory.objects;
  for candidate_index = 1:numel(inventory.candidates)
    candidate = inventory.candidates(candidate_index);
    changes = NaN(1, numel(spec.theta_5));
    for theta_index = 1:numel(spec.theta_5)
      theta = spec.theta_5(theta_index);
      match = companion.assignments([companion.assignments.real_pair]);
      for assignment_index = 1:numel(match)
        target_id = match(assignment_index).target_object_id;
        if ~ismember(target_id, candidate.realization_ids)
          continue;
        end
        p1_index = find(p1_ids == ...
          match(assignment_index).source_object_id, 1);
        p2_index = find([p2_objects.object_id] == target_id, 1);
        if ~isempty(p1_index) && ~isempty(p2_index) && ...
            abs(companion.objects(p1_index).theta - theta) < 1e-13
          value = LOCAL_envelope_distance( ...
            companion.objects(p1_index).k_envelope, ...
            p2_objects(p2_index).k_envelope);
          if isfinite(changes(theta_index))
            changes(theta_index) = max(changes(theta_index), value);
          else
            changes(theta_index) = value;
          end
        end
      end
    end
    if all(isfinite(changes))
      candidate.delta_p1p2 = max(changes);
    else
      candidate.delta_p1p2 = NaN;
    end
    internal = [candidate.delta_h, candidate.delta_g, candidate.delta_N, ...
      candidate.delta_twist, candidate.delta_algebraic];
    if all(isfinite([internal, candidate.delta_p1p2]))
      candidate.delta_ref_obs = sum([internal, candidate.delta_p1p2]);
      candidate.resolution_status = 'EMPIRICAL_RESOLUTION_COMPLETE';
    else
      candidate.delta_ref_obs = NaN;
      candidate.resolution_status = 'EMPIRICAL_RESOLUTION_PARTIAL';
      candidate.classification{end + 1} = 'p1-p2-drift-unavailable';
    end
    inventory.candidates(candidate_index) = candidate;
  end
  selected_index = find([inventory.candidates.candidate_id] == selected_id, 1);
  selected = inventory.candidates(selected_index);
  selected.collection_size = numel(inventory.candidates);
end

%% ==================== W3 objects and threshold-free tracking ====================
% Design Sections 6--8 and 15 retain every valid field-bearing W3 object.

function [inventory, tracking] = LOCAL_candidate_inventory( ...
    spec, bulk_inventory, defect_inventory, registry, work_dir)
  objects = LOCAL_empty_objects();
  invalid_objects = struct('solve_id', {}, 'cluster_id', {}, ...
    'code', {}, 'reason', {});
  configurations = struct('name', {}, 'priority', {}, 'slices', {});
  next_object_id = 1;
  for allocation_index = 1:numel(spec.object_allocation_order)
    name = spec.object_allocation_order{allocation_index};
    rank_priority = find(strcmp(spec.configuration_priority, name), 1);
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
            object.configuration_priority = rank_priority;
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
      'priority', rank_priority, 'slices', slices); %#ok<AGROW>
  end
  edges = LOCAL_tracking_edges( ...
    spec, objects, configurations, registry, work_dir);
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
  reflection = sparse((1:size(mesh.p2_points, 1)).', ...
    mesh.reflection_index, 1, size(mesh.p2_points, 1), ...
    size(mesh.p2_points, 1));
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
          if mesh.reflection_mass_defect > spec.hermitian_tolerance
            LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', ...
              'The full P2 reflection is not mass invariant.');
          end
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

function edges = LOCAL_tracking_edges( ...
    spec, objects, configurations, registry, work_dir)
  edges = LOCAL_empty_tracking_edges();
  for config_index = 1:numel(configurations)
    slices = configurations(config_index).slices;
    for slice_index = 2:numel(slices)
      new_edges = LOCAL_assign_object_sets(spec, objects, ...
        slices(slice_index - 1).object_ids, ...
        slices(slice_index).object_ids, 'twist', 'within-configuration', ...
        registry, work_dir);
      edges = [edges, new_edges]; %#ok<AGROW>
    end
  end
  families = { ...
    'p2-h0', 'p2-h1', 'h'; ...
    'p2-h1', 'p2-h2-g1', 'h'; ...
    'p2-g0', 'p2-h2-g1', 'g'; ...
    'p2-h2-g1', 'p2-anchor', 'g'; ...
    'p2-n4', 'p2-anchor', 'N'; ...
    'p2-loose', 'p2-anchor', 'algebraic'};
  for family_index = 1:size(families, 1)
    new_edges = LOCAL_configuration_edges(spec, objects, configurations, ...
      families{family_index, 1}, families{family_index, 2}, ...
      families{family_index, 3}, registry, work_dir);
    edges = [edges, new_edges]; %#ok<AGROW>
  end
end

function edges = LOCAL_empty_tracking_edges()
  edges = struct('source_object_id', {}, 'target_object_id', {}, ...
    'axis', {}, 'kind', {}, 'overlap', {}, ...
    'frequency_distance', {}, 'low_overlap', {}, ...
    'dimension_changed', {}, 'mutual_best', {}, 'real_pair', {}, ...
    'assignment_row', {}, 'assignment_column', {}, ...
    'assignment_kind', {}, 'cost_tuple', {}, 'exact_tie', {});
end

function edges = LOCAL_configuration_edges( ...
    spec, objects, configurations, source_name, target_name, axis, ...
    registry, work_dir)
  edges = LOCAL_empty_tracking_edges();
  source_index = find(strcmp({configurations.name}, source_name), 1);
  target_index = find(strcmp({configurations.name}, target_name), 1);
  if isempty(source_index) || isempty(target_index)
    return;
  end
  source = configurations(source_index);
  target = configurations(target_index);
  for source_slice = 1:numel(source.slices)
    target_slice = find(abs([target.slices.theta] - ...
      source.slices(source_slice).theta) < 1e-13, 1);
    if isempty(target_slice)
      continue;
    end
    new_edges = LOCAL_assign_object_sets(spec, objects, ...
      source.slices(source_slice).object_ids, ...
      target.slices(target_slice).object_ids, axis, ...
      'cross-configuration', registry, work_dir);
    edges = [edges, new_edges]; %#ok<AGROW>
  end
end

function edges = LOCAL_assign_object_sets( ...
    spec, objects, source_ids, target_ids, axis, kind, registry, work_dir)
  edges = LOCAL_empty_tracking_edges();
  if isempty(source_ids) || isempty(target_ids)
    return;
  end
  overlap = NaN(numel(source_ids), numel(target_ids));
  distance = NaN(size(overlap));
  exact_mass = [];
  same_mesh = numel(unique( ...
    [{objects(source_ids).mesh_id}, {objects(target_ids).mesh_id}])) == 1;
  if same_mesh && nargin >= 8 && ~isempty(registry)
    mesh = LOCAL_load_mesh(registry, work_dir, objects(source_ids(1)).mesh_id);
    exact_mass = mesh.mass_full;
  end
  for source_index = 1:numel(source_ids)
    source = objects(source_ids(source_index));
    for target_index = 1:numel(target_ids)
      target = objects(target_ids(target_index));
      distance(source_index, target_index) = ...
        LOCAL_envelope_distance(source.k_envelope, target.k_envelope);
      if ~isempty(exact_mass)
        singular_values = svd(source.subspace' * exact_mass * ...
          target.subspace);
        overlap(source_index, target_index) = min(singular_values);
      elseif source.common_core_valid && target.common_core_valid
        try
          overlap(source_index, target_index) = ...
            LOCAL_common_core_overlap(source, target);
        catch
          overlap(source_index, target_index) = NaN;
        end
      end
    end
  end
  [assignment, costs, exact_tie] = LOCAL_maximum_overlap_assignment( ...
    objects, source_ids, target_ids, overlap, distance);
  source_count = numel(source_ids);
  target_count = numel(target_ids);
  for row = 1:numel(assignment)
    column = assignment(row);
    source_object_id = 0;
    target_object_id = 0;
    pair_overlap = NaN;
    pair_distance = NaN;
    low_overlap = false;
    dimension_changed = false;
    mutual_best = false;
    real_pair = row <= source_count && column <= target_count;
    if real_pair
      source_index = row;
      target_index = column;
      source = objects(source_ids(source_index));
      target = objects(target_ids(target_index));
      source_object_id = source.object_id;
      target_object_id = target.object_id;
      pair_overlap = overlap(source_index, target_index);
      pair_distance = distance(source_index, target_index);
      threshold = spec.cluster_overlap_min;
      if source.dimension == 1 && target.dimension == 1
        threshold = spec.simple_overlap_min;
      end
      low_overlap = pair_overlap < threshold;
      dimension_changed = source.dimension ~= target.dimension;
      [~, source_best] = max(overlap(source_index, :));
      [~, target_best] = max(overlap(:, target_index));
      mutual_best = source_best == target_index && ...
        target_best == source_index;
      assignment_kind = 'REAL_PAIR';
    elseif row <= source_count
      assignment_kind = 'DEATH';
      source_object_id = objects(source_ids(row)).object_id;
    elseif column <= target_count
      assignment_kind = 'BIRTH';
      target_object_id = objects(target_ids(column)).object_id;
    else
      assignment_kind = 'DUMMY_DUMMY';
    end
    edges(end + 1) = struct( ...
      'source_object_id', source_object_id, ...
      'target_object_id', target_object_id, 'axis', axis, 'kind', kind, ...
      'overlap', pair_overlap, 'frequency_distance', pair_distance, ...
      'low_overlap', low_overlap, 'dimension_changed', dimension_changed, ...
      'mutual_best', mutual_best, 'real_pair', real_pair, ...
      'assignment_row', row, 'assignment_column', column, ...
      'assignment_kind', assignment_kind, ...
      'cost_tuple', reshape(costs(row, column, :), 1, []), ...
      'exact_tie', exact_tie); %#ok<AGROW>
  end
end

function [assignment, costs, exact_tie] = LOCAL_maximum_overlap_assignment( ...
    objects, source_ids, target_ids, overlap, distance)
  source_count = numel(source_ids);
  target_count = numel(target_ids);
  total_count = source_count + target_count;
  tuple_count = 7;
  costs = Inf(total_count, total_count, tuple_count);
  for source_index = 1:source_count
    source = objects(source_ids(source_index));
    for target_index = 1:target_count
      if isfinite(overlap(source_index, target_index))
        target = objects(target_ids(target_index));
        tuple = [-overlap(source_index, target_index), 0, ...
          distance(source_index, target_index), target.root_index, ...
          source.object_id, target.object_id, 0];
        costs(source_index, target_index, :) = reshape(tuple, 1, 1, []);
      end
    end
    tuple = [0, 1, 0, 0, source.object_id, 0, 1];
    costs(source_index, target_count + source_index, :) = ...
      reshape(tuple, 1, 1, []);
  end
  for target_index = 1:target_count
    row = source_count + target_index;
    tuple = [0, 1, 0, ...
      objects(target_ids(target_index)).root_index, 0, ...
      objects(target_ids(target_index)).object_id, 2];
    costs(row, target_index, :) = reshape(tuple, 1, 1, []);
    for source_index = 1:source_count
      tuple = [0, 0, 0, 0, ...
        objects(source_ids(source_index)).object_id, ...
        objects(target_ids(target_index)).object_id, 3];
      costs(row, target_count + source_index, :) = ...
        reshape(tuple, 1, 1, []);
    end
  end
  [assignment, exact_tie] = LOCAL_lexicographic_assignment(costs);
end

function [assignment, exact_tie] = LOCAL_lexicographic_assignment(costs)
  assignment = LOCAL_lexicographic_hungarian(costs);
  optimum = LOCAL_assignment_cost(costs, assignment);
  exact_tie = false;
  count = size(costs, 1);
  fixed = zeros(count, 1);
  available = 1:count;
  for row = 1:count
    feasible_columns = zeros(0, 1);
    feasible_assignments = cell(0, 1);
    for column = available
      if ~all(isfinite(reshape(costs(row, column, :), 1, [])))
        continue;
      end
      remaining_rows = (row + 1):count;
      remaining_columns = available(available ~= column);
      candidate = fixed;
      candidate(row) = column;
      if ~isempty(remaining_rows)
        suffix = LOCAL_lexicographic_hungarian( ...
          costs(remaining_rows, remaining_columns, :));
        candidate(remaining_rows) = remaining_columns(suffix);
      end
      if isequal(LOCAL_assignment_cost(costs, candidate), optimum)
        feasible_columns(end + 1, 1) = column; %#ok<AGROW>
        feasible_assignments{end + 1, 1} = candidate; %#ok<AGROW>
      end
    end
    if isempty(feasible_columns)
      LOCAL_raise('TRACKING_IMPLEMENTATION_FAILURE', ...
        'The exact-tie assignment refinement lost the optimum.');
    end
    exact_tie = exact_tie || numel(feasible_columns) > 1;
    [~, choice] = min(feasible_columns);
    fixed = feasible_assignments{choice};
    available(available == fixed(row)) = [];
  end
  assignment = fixed;
end

function total = LOCAL_assignment_cost(costs, assignment)
  total = zeros(1, size(costs, 3));
  for row = 1:numel(assignment)
    total = total + reshape(costs(row, assignment(row), :), 1, []);
  end
end

function LOCAL_validate_assignment_fixtures()
  objects = repmat(struct('object_id', 0, 'root_index', 1), 1, 4);
  for index = 1:4
    objects(index).object_id = index;
  end
  distance = zeros(2);
  [assignment, ~, ~] = LOCAL_maximum_overlap_assignment( ...
    objects, [1, 2], [3, 4], [0.4, 0.9; 0.8, 0.3], distance);
  if ~isequal(assignment(1:2).', [2, 1])
    LOCAL_raise('TRACKING_IMPLEMENTATION_FAILURE', ...
      'The crossing assignment fixture failed.');
  end
  [assignment, ~, ~] = LOCAL_maximum_overlap_assignment( ...
    objects, [1, 2], 3, [0.8; 0.7], zeros(2, 1));
  if assignment(1) ~= 1 || assignment(2) ~= 3
    LOCAL_raise('TRACKING_IMPLEMENTATION_FAILURE', ...
      'The two-to-one assignment fixture failed.');
  end
  [assignment, ~, ~] = LOCAL_maximum_overlap_assignment( ...
    objects, 1, [2, 3], [0.8, 0.7], zeros(1, 2));
  if assignment(1) ~= 1 || assignment(3) ~= 2
    LOCAL_raise('TRACKING_IMPLEMENTATION_FAILURE', ...
      'The one-to-two assignment fixture failed.');
  end
  [assignment, ~, exact_tie] = LOCAL_maximum_overlap_assignment( ...
    objects, [1, 2], [3, 4], 0.5 * ones(2), zeros(2));
  if ~isequal(assignment(1:2).', [1, 2]) || ~exact_tie
    LOCAL_raise('TRACKING_IMPLEMENTATION_FAILURE', ...
      'The exact-tie assignment fixture failed.');
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
    if ~edges(edge_index).real_pair
      continue;
    end
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
  minimum_ids = zeros(numel(roots), 1);
  for index = 1:numel(roots)
    members = find(labels == roots(index));
    minimum_ids(index) = min([objects(members).object_id]);
  end
  [~, order] = sort(minimum_ids, 'ascend');
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
% Design Sections 6, 8 and 15 define the total rank and realization.

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
    member_edge(edge_index) = edges(edge_index).real_pair && ...
      ismember(edges(edge_index).source_object_id, ids) && ...
      ismember(edges(edge_index).target_object_id, ids);
  end
  linked_edges = edges(member_edge);
  axes = unique({linked_edges.axis});
  if isempty(linked_edges)
    linked_configurations = 0;
    linked_twists = 0;
  else
    linked_ids = unique([[linked_edges.source_object_id], ...
      [linked_edges.target_object_id]]);
    linked_configurations = numel(unique({objects(linked_ids).configuration}));
    linked_twists = numel(unique([objects(linked_ids).theta]));
  end
  n_axes = numel(axes);
  n_config = linked_configurations;
  n_theta = linked_twists;
  deltas = LOCAL_candidate_deltas(spec, objects, ids);
  delta_values = [deltas.delta_h, deltas.delta_g, deltas.delta_N, ...
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
    anchor.root_index, anchor.object_id, component.candidate_id];
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
    candidate_status = 'EMPIRICAL_P2_FEM_CANDIDATE_WITH_CAVEATS';
  else
    candidate_status = 'EMPIRICAL_P2_FEM_REFERENCE_CANDIDATE';
  end
  candidate = struct('candidate_id', component.candidate_id, ...
    'realization_ids', ids, 'n_axes', n_axes, 'n_config', n_config, ...
    'n_theta', n_theta, 'tracking_status', tracking_status, ...
    'delta_h', deltas.delta_h, 'delta_g', deltas.delta_g, ...
    'delta_N', deltas.delta_N, ...
    'delta_twist', deltas.delta_twist, ...
    'delta_algebraic', deltas.delta_algebraic, ...
    'delta_p1p2', NaN, 'delta_ref_obs', delta_ref_obs, ...
    'resolution_status', resolution_status, ...
    'residual_max', residual_max, 'localization_center', localization_center, ...
    'localization_core', localization_core, 'tail_max', tail_max, ...
    'parity_rank', parity_rank, 'covered_window', covered_window, ...
    'covered_slices', covered_slices, 'ceiling_margin', ceiling_margin, ...
    'rank_key', rank_key, 'classification', {classifications}, ...
    'candidate_status', candidate_status, 'publication', publication, ...
    'lambda_ref_p2', publication.lambda_ref_p2, ...
    'k_ref_p2', publication.k_ref_p2);
end

function deltas = LOCAL_candidate_deltas(spec, objects, ids)
  h0 = LOCAL_component_envelope(objects, ids, 'p2-h0', spec.theta_5);
  h1 = LOCAL_component_envelope(objects, ids, 'p2-h1', spec.theta_5);
  h2 = LOCAL_component_envelope(objects, ids, 'p2-h2-g1', spec.theta_5);
  g0 = LOCAL_component_envelope(objects, ids, 'p2-g0', spec.theta_5);
  g1 = h2;
  g2 = LOCAL_component_envelope(objects, ids, 'p2-anchor', spec.theta_5);
  anchor_9 = LOCAL_component_envelope( ...
    objects, ids, 'p2-anchor', spec.theta_9);
  anchor_17 = LOCAL_component_envelope( ...
    objects, ids, 'p2-anchor', spec.theta_17);
  n4 = LOCAL_component_envelope(objects, ids, 'p2-n4', spec.theta_5);
  d_h21 = LOCAL_optional_distance(h2, h1);
  d_h10 = LOCAL_optional_distance(h1, h0);
  if isfinite(d_h21) && isfinite(d_h10)
    delta_h = d_h21 + abs(d_h21 - d_h10);
  else
    delta_h = NaN;
  end
  d_g21 = LOCAL_optional_distance(g2, g1);
  d_g10 = LOCAL_optional_distance(g1, g0);
  if isfinite(d_g21) && isfinite(d_g10)
    delta_g = d_g21 + abs(d_g21 - d_g10);
  else
    delta_g = NaN;
  end
  delta_N = LOCAL_optional_distance(g2, n4);
  twist_sampling = LOCAL_optional_distance(anchor_17, anchor_9);
  if all(isfinite(anchor_17)) && isfinite(twist_sampling)
    delta_twist = diff(anchor_17) / 2 + twist_sampling;
  else
    delta_twist = NaN;
  end
  delta_algebraic = LOCAL_component_algebraic_change( ...
    objects, ids, spec.theta_5);
  deltas = struct('delta_h', delta_h, 'delta_g', delta_g, ...
    'delta_N', delta_N, ...
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
    tight = ids(strcmp({objects(ids).configuration}, 'p2-anchor') & ...
      abs([objects(ids).theta] - grid(phase_index)) < 1e-13);
    loose = ids(strcmp({objects(ids).configuration}, 'p2-loose') & ...
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
    tuples(index, :) = [group(1).configuration_priority, ...
      -numel(unique([group.theta])), min([group.theta_index]), ...
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
  lambda_ref_p2 = mean(lambda_envelope);
  k_ref_p2 = sqrt(lambda_ref_p2);
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
    'lambda_ref_p2', lambda_ref_p2, 'k_ref_p2', k_ref_p2, ...
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
    tracking, selected_candidate, companion_inventory, terminal_class, ...
    terminal_status, first_failure)
  payload = struct('schema_version', 'i4b-p2-reference-v1', ...
    'run_id', run_state.run_id, 'execution_id', run_state.execution_id, ...
    'terminal_class', terminal_class, ...
    'scientific_terminal', terminal_status, 'first_failure', first_failure, ...
    'attempted_solves', run_state.attempted_solves, ...
    'completed_solves', run_state.completed_solves, ...
    'planned_solves', run_state.planned_solves, ...
    'claim_boundary', ...
    'EMPIRICAL_P2_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY', ...
    'certification_status', 'EMPIRICAL_NON_CERTIFIED', ...
    'effectivity_performed', false, ...
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
  payload.companion_inventory = ...
    LOCAL_compact_companion(companion_inventory);
  try
    LOCAL_atomic_save(fullfile(output_dir, 'scientific-result.mat'), payload);
  catch caught
    LOCAL_raise('CANONICAL_PUBLICATION_FAILURE', caught.message);
  end
end

function compact = LOCAL_compact_companion(inventory)
  compact = inventory;
  if isempty(compact)
    return;
  end
  if ~isempty(compact.entries) && isfield(compact.entries, 'path')
    compact.entries = rmfield(compact.entries, 'path');
  end
  for index = 1:numel(compact.objects)
    compact.objects(index).subspace = [];
    compact.objects(index).common_core_samples = [];
    compact.objects(index).common_core_weights = [];
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

function LOCAL_publish_fields(output_dir, registry, candidate_inventory, ...
    companion_inventory, selected)
  mesh = LOCAL_load_mesh(registry, '', selected.publication.anchor_mesh_id);
  anchor = candidate_inventory.objects(strcmp( ...
    {candidate_inventory.objects.configuration}, 'p2-anchor'));
  winner = candidate_inventory.objects(ismember( ...
    [candidate_inventory.objects.object_id], selected.realization_ids));
  payload = struct('schema_version', 'i4b-p2-fields-v1', ...
    'run_id', 'run-001', 'execution_id', 'execution-001', ...
    'candidate_id', selected.candidate_id, ...
    'lambda_ref_p2', selected.lambda_ref_p2, ...
    'k_ref_p2', selected.k_ref_p2, ...
    'multiplicity', selected.publication.multiplicity, ...
    'anchor_mesh_id', selected.publication.anchor_mesh_id, ...
    'anchor_theta', selected.publication.anchor_theta, ...
    'points', mesh.points, 'triangles', mesh.triangles, ...
    'edges', mesh.edges, 'triangle_p2', mesh.triangle_p2, ...
    'p2_points', mesh.p2_points, ...
    'material_inside', mesh.material_inside, ...
    'anchor_objects', anchor, 'winner_objects', winner, ...
    'companion_entries', companion_inventory.entries, ...
    'companion_objects', companion_inventory.objects, ...
    'p1_p2_assignments', companion_inventory.assignments, ...
    'subspace', selected.publication.subspace, ...
    'simple_vector', selected.publication.simple_vector, ...
    'basis_status', selected.publication.basis_status, ...
    'claim_boundary', ...
    'EMPIRICAL_P2_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY', ...
    'certification_status', 'EMPIRICAL_NON_CERTIFIED', ...
    'effectivity_performed', false);
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
  [triangle_index, barycentric] = LOCAL_deterministic_location(mesh, query);
  if any(isnan(triangle_index))
    LOCAL_raise('TRACKING_DIAGNOSTIC_UNAVAILABLE', ...
      'The common-core grid is not covered by a mesh.');
  end
  nodes = mesh.triangle_p2(triangle_index, :);
  basis = [barycentric(:, 1) .* (2 * barycentric(:, 1) - 1), ...
    barycentric(:, 2) .* (2 * barycentric(:, 2) - 1), ...
    barycentric(:, 3) .* (2 * barycentric(:, 3) - 1), ...
    4 * barycentric(:, 1) .* barycentric(:, 2), ...
    4 * barycentric(:, 2) .* barycentric(:, 3), ...
    4 * barycentric(:, 3) .* barycentric(:, 1)];
  samples = zeros(size(query, 1), size(subspace, 2));
  for local_node = 1:6
    samples = samples + basis(:, local_node) .* ...
      subspace(nodes(:, local_node), :);
  end
  weights = weights .* q_values;
end

function [samples, weights] = LOCAL_sample_subspace_p1(spec, mesh, subspace)
  [grid_x, grid_y] = meshgrid(spec.core_grid_x, spec.core_grid_y);
  query = [grid_x(:), grid_y(:)];
  weight_x = ones(size(spec.core_grid_x));
  weight_y = ones(size(spec.core_grid_y));
  weight_x([1, end]) = 0.5;
  weight_y([1, end]) = 0.5;
  [tensor_weight_x, tensor_weight_y] = meshgrid(weight_x, weight_y);
  weights = tensor_weight_x(:) .* tensor_weight_y(:) * ...
    (spec.core_grid_x(2) - spec.core_grid_x(1)) * ...
    (spec.core_grid_y(2) - spec.core_grid_y(1));
  on_circle = false(size(query, 1), 1);
  q_values = spec.q_outside * ones(size(query, 1), 1);
  disk_centers = -2:2;
  disk_centers(disk_centers == spec.missing_column) = [];
  for center_index = 1:numel(disk_centers)
    distance = hypot(query(:, 1) - disk_centers(center_index), query(:, 2));
    on_circle = on_circle | abs(distance - spec.radius) <= 1e-12;
    q_values(distance < spec.radius) = spec.q_inside;
  end
  query(on_circle, :) = [];
  weights(on_circle) = [];
  q_values(on_circle) = [];
  [triangle_index, barycentric] = LOCAL_deterministic_location(mesh, query);
  nodes = mesh.triangles(triangle_index, :);
  samples = zeros(size(query, 1), size(subspace, 2));
  for local_node = 1:3
    samples = samples + barycentric(:, local_node) .* ...
      subspace(nodes(:, local_node), :);
  end
  weights = weights .* q_values;
end

function [triangle_index, barycentric] = ...
    LOCAL_deterministic_location(mesh, query)
  physical = triangulation(mesh.triangles, mesh.points);
  [triangle_index, barycentric] = pointLocation(physical, query);
  if any(isnan(triangle_index))
    return;
  end
  boundary_queries = find(min(abs(barycentric), [], 2) <= 1e-12);
  for query_position = boundary_queries.'
    queue = triangle_index(query_position);
    visited = false(size(mesh.triangles, 1), 1);
    candidates = zeros(0, 1);
    minima = zeros(0, 1);
    while ~isempty(queue)
      triangle_id = queue(1);
      queue(1) = [];
      if visited(triangle_id)
        continue;
      end
      visited(triangle_id) = true;
      lambda = cartesianToBarycentric(physical, triangle_id, ...
        query(query_position, :));
      if min(lambda) >= -1e-12
        candidates(end + 1, 1) = triangle_id; %#ok<AGROW>
        minima(end + 1, 1) = min(lambda); %#ok<AGROW>
      end
      across = find(abs(lambda) <= 1e-12);
      neighbor_ids = neighbors(physical, triangle_id);
      neighbor_ids = neighbor_ids(across);
      queue = [queue; neighbor_ids(~isnan(neighbor_ids)).']; %#ok<AGROW>
    end
    best_minimum = max(minima);
    best = candidates(abs(minima - best_minimum) <= 5e-15);
    triangle_index(query_position) = min(best);
    barycentric(query_position, :) = cartesianToBarycentric( ...
      physical, triangle_index(query_position), query(query_position, :));
  end
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
