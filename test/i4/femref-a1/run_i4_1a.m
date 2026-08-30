function run_i4_1a(run_id, mode)
%RUN_I4_1A Produce the blinded I4.1a fitted-FEM reference artifact.
% Purpose:
%   Solve the frozen independent fixed-beta bulk and line-defect problems by
%   a self-contained polygon-interface conforming P1 finite-element method.
% Input:
%   run_id - Explicit artifact label.  It changes no scientific parameter.
%   mode   - Optional exact mesh-, mass-, or representation-diagnostic
%            dispatch.  The one-input
%            formal scientific entry retains its original semantics.
% Output:
%   Machine-readable artifacts below output/<run_id>/ next to this file.
% Main algorithm:
%   Build deterministic fitted meshes, assemble volume stiffness and
%   weighted mass forms, impose both quasiperiodic phases through a nodal
%   prolongation, inventory all frozen low spectra, track cluster subspaces,
%   and apply the preregistered coverage and empirical-resolution gates.
% Based on:
%   research/projects/eig-apost/implementation/i4/design-4-1a.md, Sections
%   2--12, 15--18, 20, and 22--22.15, under method-4-1.md and
%   method-review.md.
% Main changes:
%   This is an independent volume-FEM implementation.  It does not call or
%   read any current BIE, QZ, estimator, density, candidate, or field object.
%   Section 15 adds pre-assembly reflection-closed tie resolution and a
%   create-once, non-eigensolve mesh diagnostic dispatch.  Section 18 adds
%   a create-once raw mass-gate evidence diagnostic with zero eigensolves.
%   Section 20 adds the append-only 002 publication repair and scalar gate.
%   Section 22 adds proof-backed upper-triangle canonical reduced operators,
%   OP2/DRV2 evidence, and a create-once zero-eigensolve representation gate.
% Numerical goal:
%   Export REFERENCE_COLLECTION_READY or one complete fail-closed ledger.
% Notes:
%   The formal code reads only its own current-run machine caches.  It never reads
%   Markdown, Git metadata, historical output, or a repository path.

  if nargin == 2
    valid_labels = ischar(run_id) || (isstring(run_id) && isscalar(run_id));
    valid_mode = ischar(mode) || (isstring(mode) && isscalar(mode));
    if ~valid_labels || ~valid_mode
      error('I4A:InvalidDiagnosticMode', ...
        'Diagnostic labels and modes must be character vectors or string scalars.');
    end
    diagnostic_id = char(run_id);
    diagnostic_mode = char(mode);
    if strcmp(diagnostic_id, 'mesh-repair-001') && ...
        strcmp(diagnostic_mode, 'mesh-diagnostic')
      LOCAL_run_mesh_diagnostic();
      return;
    elseif strcmp(diagnostic_id, 'mass-gate-001') && ...
        strcmp(diagnostic_mode, 'mass-diagnostic')
      LOCAL_run_mass_diagnostic(diagnostic_id);
      return;
    elseif strcmp(diagnostic_id, 'mass-gate-002') && ...
        strcmp(diagnostic_mode, 'mass-diagnostic')
      LOCAL_run_mass_diagnostic(diagnostic_id);
      return;
    elseif strcmp(diagnostic_id, 'representation-gate-001') && ...
        strcmp(diagnostic_mode, 'representation-diagnostic')
      LOCAL_run_representation_diagnostic(diagnostic_id);
      return;
    elseif strcmp(diagnostic_id, 'representation-gate-002') && ...
        strcmp(diagnostic_mode, 'representation-diagnostic')
      LOCAL_run_representation_diagnostic(diagnostic_id);
      return;
    elseif strcmp(diagnostic_id, 'representation-gate-003') && ...
        strcmp(diagnostic_mode, 'representation-diagnostic')
      LOCAL_run_representation_diagnostic(diagnostic_id);
      return;
    end
    error('I4A:InvalidDiagnosticMode', ...
      ['Diagnostic invocation must use the exact registered ' ...
      'diagnostic ID and mode.']);
  end

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
  artifacts.mesh_rows = cell(0, 36);
  artifacts.seam_rows = cell(0, 12);
  artifacts.bulk_rows = cell(0, 10);
  artifacts.bulk_gap_rows = cell(0, 14);
  artifacts.spectrum_rows = cell(0, 14);
  artifacts.branch_edge_rows = cell(0, 14);
  artifacts.branch_rows = cell(0, 24);
  artifacts.coverage_rows = cell(0, 12);
  artifacts.resolution_rows = cell(0, 19);
  artifacts.resource_rows = cell(0, 10);
  artifacts.operator_ledger = LOCAL_initial_operator_ledger( ...
    spec, output_dir, 'FORMAL');

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
    LOCAL_write_bulk_artifacts(artifacts, output_dir);
    LOCAL_write_operator_representation(artifacts.operator_ledger);
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

%% ==================== Non-eigensolve mesh diagnostic ====================
% This create-once path builds only the nine frozen meshes and resource audit.

function LOCAL_run_mesh_diagnostic()
  entry_dir = fileparts(mfilename('fullpath'));
  diagnostic_dir = fullfile(entry_dir, 'diagnostics', 'mesh-repair-001');
  if exist(diagnostic_dir, 'dir') || exist(diagnostic_dir, 'file')
    error('I4A:DiagnosticCollision', ...
      'DIAGNOSTIC_COLLISION: diagnostics/mesh-repair-001 already exists.');
  end
  temporary_work_dir = tempname;
  [made_work, work_message] = mkdir(temporary_work_dir);
  if ~made_work
    error('I4A:OutputUnavailable', ...
      'Cannot create temporary diagnostic work directory: %s', work_message);
  end
  cleanup_work = onCleanup( ...
    @() LOCAL_remove_diagnostic_work(temporary_work_dir)); %#ok<NASGU>
  [made_diagnostic, diagnostic_message] = mkdir(diagnostic_dir);
  if ~made_diagnostic
    error('I4A:OutputUnavailable', ...
      'Cannot create mesh diagnostic directory: %s', diagnostic_message);
  end

  diagnostic_clock = tic;
  summary = struct();
  summary.diagnostic_id = 'mesh-repair-001';
  summary.status = 'RUNNING';
  summary.mesh_count = 0;
  summary.completed_eigensolves = 0;
  summary.wall_estimate_minutes = NaN;
  summary.peak_estimate_gib = NaN;
  summary.resource_forecast_complete = false;
  summary.resource_pass = false;
  summary.closure_pass = false;
  summary.failure_code = '';
  summary.failure_reason = '';
  summary.reference_exported = false;
  summary.claim_boundary = ['NON_EIGENSOLVE_IMPLEMENTATION_DIAGNOSTIC;' ...
    'NOT_A_REFERENCE_COLLECTION;NO_GUIDED_MODE_OR_EFFECTIVITY_CLAIM'];

  try
    spec = LOCAL_spec();
    LOCAL_check_environment(spec);
    [mesh_registry, mesh_rows, seam_rows, preflight, resource_rows] = ...
      LOCAL_preflight_audit(spec, temporary_work_dir, diagnostic_dir, ...
      toc(diagnostic_clock));
    diagnostic_artifacts = struct();
    diagnostic_artifacts.mesh_rows = mesh_rows;
    diagnostic_artifacts.seam_rows = seam_rows;
    LOCAL_write_mesh_artifacts(diagnostic_artifacts, diagnostic_dir);
    LOCAL_write_resource_preflight(preflight, resource_rows, diagnostic_dir);
    summary.mesh_count = numel(mesh_registry);
    summary.wall_estimate_minutes = preflight.wall_estimate_minutes;
    summary.peak_estimate_gib = preflight.peak_estimate_gib;
    summary.resource_forecast_complete = true;
    summary.resource_pass = preflight.pass;
    closure_pass = summary.mesh_count == 9 && size(seam_rows, 1) == 9 && ...
      all(cell2mat(mesh_rows(:, 19)) == 0) && ...
      all(cell2mat(mesh_rows(:, 20)) <= spec.constraint_tolerance) && ...
      all(cell2mat(mesh_rows(:, 21)) == 0) && ...
      all(cell2mat(mesh_rows(:, 22)) == 0) && ...
      all(cell2mat(mesh_rows(:, 23)) == 0) && ...
      all(cell2mat(mesh_rows(:, 24)) == 0) && ...
      all(cell2mat(mesh_rows(:, 25)) == 0) && ...
      all(cell2mat(mesh_rows(:, 26)) == 0) && ...
      all(cell2mat(mesh_rows(:, 27)) == cell2mat(mesh_rows(:, 28))) && ...
      all(cell2mat(mesh_rows(:, 29)) == 0) && ...
      all(cell2mat(mesh_rows(:, 30)) == 0) && ...
      all(cell2mat(mesh_rows(:, 31)) == 0) && ...
      all(cell2mat(mesh_rows(:, 32)) == 1) && ...
      all(cell2mat(mesh_rows(:, 33)) == 1);
    summary.closure_pass = closure_pass;
    if ~closure_pass
      summary.status = 'MESH_REFLECTION_CLOSURE_UNRESOLVED';
      summary.failure_code = summary.status;
      summary.failure_reason = ...
        ['One or more frozen meshes lacks planar-complex or ' ...
        'triangle/material reflection closure.'];
    elseif ~preflight.pass
      summary.status = 'RESOURCE_BUDGET_UNAVAILABLE';
      summary.failure_code = summary.status;
      summary.failure_reason = preflight.reason;
    else
      summary.status = 'PASS';
    end
  catch caught
    [failure_code, failure_reason] = LOCAL_decode_failure(caught);
    summary.status = failure_code;
    summary.failure_code = failure_code;
    summary.failure_reason = failure_reason;
  end
  summary.elapsed_seconds = toc(diagnostic_clock);
  LOCAL_write_diagnostic_summary(summary, diagnostic_dir);
  fprintf('Mesh diagnostic status: %s\n', summary.status);
  if ~strcmp(summary.status, 'PASS')
    error('I4A:MeshDiagnosticFailed', '%s|%s', ...
      summary.failure_code, summary.failure_reason);
  end
end

function LOCAL_write_diagnostic_summary(summary, diagnostic_dir)
  rows = {summary.diagnostic_id, summary.status, summary.mesh_count, ...
    summary.completed_eigensolves, summary.elapsed_seconds, ...
    summary.wall_estimate_minutes, summary.peak_estimate_gib, ...
    summary.resource_forecast_complete, summary.resource_pass, ...
    summary.closure_pass, summary.reference_exported, summary.failure_code, ...
    summary.failure_reason, summary.claim_boundary};
  LOCAL_write_csv(fullfile(diagnostic_dir, 'diagnostic-summary.csv'), ...
    {'diagnostic_id', 'status', 'mesh_count', 'completed_eigensolves', ...
    'elapsed_seconds', 'wall_estimate_minutes', 'peak_estimate_gib', ...
    'resource_forecast_complete', 'resource_pass', ...
    'closure_pass', 'reference_exported', 'failure_code', 'failure_reason', ...
    'claim_boundary'}, rows);
  LOCAL_atomic_save(fullfile(diagnostic_dir, 'diagnostic-summary.mat'), summary);
end

function LOCAL_remove_diagnostic_work(temporary_work_dir)
  if exist(temporary_work_dir, 'dir')
    [removed, message] = rmdir(temporary_work_dir, 's');
    if ~removed
      warning('I4A:DiagnosticCleanup', ...
        'Temporary diagnostic cache cleanup failed: %s', message);
    end
  end
end

%% ==================== Non-eigensolve mass diagnostic ====================
% This create-once path rebuilds one frozen mesh and audits raw mass support.

function LOCAL_run_mass_diagnostic(diagnostic_id)
  allowed_ids = {'mass-gate-001', 'mass-gate-002'};
  if ~any(strcmp(diagnostic_id, allowed_ids))
    error('I4A:InvalidDiagnosticMode', ...
      'Mass diagnostic ID must match the exact registered allowlist.');
  end
  diagnostic_clock = tic;
  entry_dir = fileparts(mfilename('fullpath'));
  diagnostic_dir = fullfile(entry_dir, 'diagnostics', diagnostic_id);
  if exist(diagnostic_dir, 'dir') || exist(diagnostic_dir, 'file')
    error('I4A:DiagnosticCollision', ...
      'DIAGNOSTIC_COLLISION: diagnostics/%s already exists.', ...
      diagnostic_id);
  end
  [made_diagnostic, diagnostic_message] = mkdir(diagnostic_dir);
  if ~made_diagnostic
    error('I4A:OutputUnavailable', ...
      'Cannot create mass diagnostic directory: %s', diagnostic_message);
  end

  diagnostic_summary = struct();
  diagnostic_summary.diagnostic_id = diagnostic_id;
  diagnostic_summary.status = 'RUNNING';
  diagnostic_summary.input_kind = ...
    'SOURCE_REBUILD_MATCHING_FROZEN_RUN005_SPEC';
  diagnostic_summary.mesh_id = 'bulk-s12-g24';
  diagnostic_summary.alpha = 0;
  diagnostic_summary.completed_eigensolves = 0;
  diagnostic_summary.reference_exported = false;
  diagnostic_summary.bulk_band_rows = 0;
  diagnostic_summary.bulk_gap_rows = 0;
  diagnostic_summary.evidence_complete = false;
  diagnostic_summary.wall_estimate_minutes = 2;
  diagnostic_summary.peak_estimate_gib = 1;
  diagnostic_summary.failure_code = '';
  diagnostic_summary.failure_reason = '';
  diagnostic_summary.claim_boundary = [ ...
    'SOURCE_REBUILD_MASS_EVIDENCE_ONLY;ZERO_EIGENSOLVES;' ...
    'NOT_A_REFERENCE_COLLECTION;NO_FORMAL_RETRY_AUTHORITY'];
  diagnostic_summary.reached_boundary = 'NAMESPACE_CREATED';
  mass_artifacts = LOCAL_empty_mass_artifacts();
  bulk_artifacts = struct();
  bulk_artifacts.bulk_rows = cell(0, 10);
  bulk_artifacts.bulk_gap_rows = cell(0, 14);

  try
    LOCAL_write_bulk_artifacts(bulk_artifacts, diagnostic_dir);
    LOCAL_write_mass_artifacts(mass_artifacts, diagnostic_dir);
    diagnostic_summary.reached_boundary = ...
      'HEADER_ONLY_SCHEMAS_PUBLISHED';

    spec = LOCAL_spec();
    schedule = LOCAL_mesh_schedule();
    mesh_matches = find(strcmp({schedule.id}, 'bulk-s12-g24'));
    if numel(mesh_matches) ~= 1
      error('I4A:MassDiagnosticSpec', ...
        'Frozen mass diagnostic mesh ID is not unique.');
    end
    mesh_spec = schedule(mesh_matches);
    if ~strcmp(mesh_spec.kind, 'bulk') || mesh_spec.N ~= 0 || ...
        mesh_spec.s ~= 12 || mesh_spec.n_gamma ~= 24 || spec.beta ~= 0.5
      error('I4A:MassDiagnosticSpec', ...
        'Frozen mass diagnostic source identity does not match Section 18.');
    end
    diagnostic_summary.reached_boundary = 'FROZEN_SPEC_SELECTED';

    mesh_rows = cell(0, 36);
    seam_rows = cell(0, 12);
    [mesh, mesh_diagnostic] = LOCAL_build_mesh( ...
      spec, mesh_spec, mesh_rows, seam_rows, diagnostic_dir);
    mesh_rows(end + 1, :) = LOCAL_mesh_diagnostic_row( ...
      mesh_spec, mesh_diagnostic, 'MESH_COMPLETE_SEAM_PENDING', '', '');
    mesh_artifacts = struct();
    mesh_artifacts.mesh_rows = mesh_rows;
    mesh_artifacts.seam_rows = seam_rows;
    LOCAL_write_mesh_artifacts(mesh_artifacts, diagnostic_dir);
    diagnostic_summary.reached_boundary = 'MESH_BUILT';

    [reduced, phase_diagnostic] = LOCAL_phase_reduce( ...
      spec, mesh, 0, 'mass-diagnostic');
    seam_rows(end + 1, :) = LOCAL_seam_row( ...
      mesh.id, 'mass-diagnostic', 0, phase_diagnostic);
    mesh_rows{end, 34} = 'MESH_AND_SEAM_COMPLETE';
    mesh_artifacts.mesh_rows = mesh_rows;
    mesh_artifacts.seam_rows = seam_rows;
    LOCAL_write_mesh_artifacts(mesh_artifacts, diagnostic_dir);
    diagnostic_summary.reached_boundary = 'RAW_MASS_OBJECTS_FORMED';

    evidence = LOCAL_mass_gate_diagnostics(mesh, reduced);
    mass_artifacts.node_rows = evidence.node_rows;
    mass_artifacts.master_rows = evidence.master_rows;
    mass_artifacts.matrix_rows = evidence.matrix_rows;
    mass_artifacts.chol_rows = evidence.chol_rows;
    diagnostic_summary.reached_boundary = 'MASS_EVIDENCE_COMPUTED';

    mass_summary = struct();
    mass_summary.diagnostic_id = diagnostic_id;
    mass_summary.input_kind = diagnostic_summary.input_kind;
    mass_summary.model_id = spec.model_id;
    mass_summary.model_digest = spec.model_digest;
    mass_summary.mesh_id = mesh.id;
    mass_summary.phase_kind = 'mass-diagnostic';
    mass_summary.alpha = 0;
    mass_summary.beta = spec.beta;
    mass_summary.full_point_count = size(mesh.points, 1);
    mass_summary.triangle_used_point_count = ...
      nnz(evidence.node_incidence > 0);
    mass_summary.unused_point_count = numel(evidence.unused_point_ids);
    mass_summary.unused_point_ids = ...
      LOCAL_integer_list(evidence.unused_point_ids);
    mass_summary.master_min = evidence.master_min;
    mass_summary.master_max = evidence.master_max;
    mass_summary.master_unique_count = numel(evidence.master_ids);
    mass_summary.p_rows = size(reduced.prolongation, 1);
    mass_summary.p_columns = size(reduced.prolongation, 2);
    mass_summary.p_nnz = nnz(reduced.prolongation);
    mass_summary.p_zero_support_column_count = ...
      numel(evidence.p_zero_support_column_ids);
    mass_summary.p_zero_support_column_ids = ...
      LOCAL_integer_list(evidence.p_zero_support_column_ids);
    mass_summary.p_entry_modulus_min = evidence.p_entry_modulus_min;
    mass_summary.p_entry_modulus_max = evidence.p_entry_modulus_max;
    mass_summary.chol_flag = evidence.chol_flag;
    mass_summary.completed_eigensolves = 0;
    mass_summary.reference_exported = false;
    diagnostic_summary.bulk_band_rows = ...
      size(bulk_artifacts.bulk_rows, 1);
    diagnostic_summary.bulk_gap_rows = ...
      size(bulk_artifacts.bulk_gap_rows, 1);
    LOCAL_write_mass_artifacts(mass_artifacts, diagnostic_dir);
    pre_summary_artifacts_present = ...
      LOCAL_required_mass_artifacts_present(diagnostic_dir, false);
    mass_summary.evidence_complete = evidence.measurements_complete && ...
      size(evidence.node_rows, 1) == size(mesh.points, 1) && ...
      size(evidence.master_rows, 1) == numel(evidence.master_ids) && ...
      size(evidence.matrix_rows, 1) == 2 && ...
      size(evidence.chol_rows, 1) == 1 && ...
      size(mesh_rows, 1) == 1 && size(seam_rows, 1) == 1 && ...
      diagnostic_summary.bulk_band_rows == 0 && ...
      diagnostic_summary.bulk_gap_rows == 0 && ...
      pre_summary_artifacts_present;

    mass_payload = struct();
    mass_payload.identity = mass_summary;
    mass_payload.points = mesh.points;
    mass_payload.triangles = mesh.triangles;
    mass_payload.node_incidence = evidence.node_incidence;
    mass_payload.unused_point_ids = evidence.unused_point_ids;
    mass_payload.master_index = mesh.periodic.master_index;
    mass_payload.master_ids = evidence.master_ids;
    mass_payload.master_group_members = evidence.master_group_members;
    mass_payload.phase_prolongation = reduced.prolongation;
    mass_payload.mass_full = mesh.mass_full;
    mass_payload.mass_reduced = reduced.mass;
    mass_payload.partial_factor = evidence.partial_factor;
    mass_payload.chol_call_completed = evidence.chol_call_completed;
    mass_payload.chol_error_identifier = evidence.chol_error_identifier;
    mass_payload.chol_error_message = evidence.chol_error_message;
    mass_payload.chol_flag = evidence.chol_flag;
    mass_payload.matrix_diagnostics = evidence.matrix_diagnostics;
    mass_payload.pivot_support = evidence.pivot_support;
    mass_payload.completed_eigensolves = 0;
    mass_payload.reference_exported = false;
    mass_payload.claim_boundary = diagnostic_summary.claim_boundary;

    LOCAL_write_mass_summary(mass_summary, mass_payload, diagnostic_dir);
    required_artifacts_present = ...
      LOCAL_required_mass_artifacts_present(diagnostic_dir, true);
    diagnostic_summary.evidence_complete = ...
      mass_summary.evidence_complete && required_artifacts_present && ...
      diagnostic_summary.completed_eigensolves == 0 && ...
      ~diagnostic_summary.reference_exported;
    if required_artifacts_present
      diagnostic_summary.reached_boundary = 'EVIDENCE_PUBLISHED';
    else
      diagnostic_summary.reached_boundary = ...
        'ARTIFACT_PUBLICATION_INCOMPLETE';
    end

    if ~diagnostic_summary.evidence_complete
      diagnostic_summary.status = 'MASS_DIAGNOSTIC_INCOMPLETE';
      diagnostic_summary.failure_code = diagnostic_summary.status;
      diagnostic_summary.failure_reason = ...
        'Required mass evidence or atomic artifact publication is incomplete.';
    elseif evidence.chol_flag == 0
      diagnostic_summary.status = 'MASS_DIAGNOSTIC_COMPLETE_CHOL_PASS';
    else
      diagnostic_summary.status = 'MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL';
      diagnostic_summary.failure_code = diagnostic_summary.status;
      diagnostic_summary.failure_reason = sprintf( ...
        'Raw reduced mass returned natural 1-based chol_flag %d.', ...
        evidence.chol_flag);
    end
  catch caught
    [first_failure_code, first_failure_reason] = ...
      LOCAL_decode_failure(caught);
    diagnostic_summary.status = 'MASS_DIAGNOSTIC_INCOMPLETE';
    diagnostic_summary.evidence_complete = false;
    diagnostic_summary.failure_code = first_failure_code;
    diagnostic_summary.failure_reason = sprintf( ...
      'reached_boundary=%s;%s', diagnostic_summary.reached_boundary, ...
      first_failure_reason);
  end

  diagnostic_summary.elapsed_seconds = toc(diagnostic_clock);
  LOCAL_write_mass_diagnostic_summary(diagnostic_summary, diagnostic_dir);
  fprintf('Mass diagnostic status: %s\n', diagnostic_summary.status);
  if strcmp(diagnostic_summary.status, ...
      'MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL')
    error('I4A:MassDiagnosticCholFail', '%s|%s', ...
      diagnostic_summary.failure_code, diagnostic_summary.failure_reason);
  elseif strcmp(diagnostic_summary.status, 'MASS_DIAGNOSTIC_INCOMPLETE')
    error('I4A:MassDiagnosticIncomplete', '%s|%s', ...
      diagnostic_summary.failure_code, diagnostic_summary.failure_reason);
  end
end

function artifacts = LOCAL_empty_mass_artifacts()
  artifacts = struct();
  artifacts.node_rows = cell(0, 9);
  artifacts.master_rows = cell(0, 7);
  artifacts.matrix_rows = cell(0, 14);
  artifacts.chol_rows = cell(0, 23);
end

function LOCAL_write_mass_artifacts(artifacts, output_dir)
  LOCAL_assert_mass_csv_rows( ...
    artifacts.node_rows, 'mass-node-incidence.csv', 9);
  LOCAL_assert_mass_csv_rows( ...
    artifacts.master_rows, 'mass-master-groups.csv', 7);
  LOCAL_assert_mass_csv_rows( ...
    artifacts.matrix_rows, 'mass-matrices.csv', 14);
  LOCAL_assert_mass_csv_rows( ...
    artifacts.chol_rows, 'mass-chol-pivot.csv', 23);
  LOCAL_write_csv(fullfile(output_dir, 'mass-node-incidence.csv'), ...
    {'full_node_id', 'triangle_incidence', 'triangle_used', 'master_id', ...
    'p_row_nnz', 'p_row_column_id', 'p_entry_real', 'p_entry_imag', ...
    'p_entry_modulus'}, artifacts.node_rows);
  LOCAL_write_csv(fullfile(output_dir, 'mass-master-groups.csv'), ...
    {'master_id', 'group_size', 'member_node_ids', 'p_column_nnz', ...
    'p_support_node_ids', 'p_entry_modulus_min', ...
    'p_entry_modulus_max'}, artifacts.master_rows);
  LOCAL_write_csv(fullfile(output_dir, 'mass-matrices.csv'), ...
    {'matrix_id', 'rows', 'columns', 'nnz', 'stored_nonfinite_count', ...
    'zero_row_count', 'zero_row_ids', 'zero_column_count', ...
    'zero_column_ids', 'diagonal_real_min', 'diagonal_real_max', ...
    'diagonal_max_abs_imag', 'hermitian_defect_absolute_1', ...
    'hermitian_defect_normalized_1'}, artifacts.matrix_rows);
  LOCAL_write_csv(fullfile(output_dir, 'mass-chol-pivot.csv'), ...
    {'chol_call_completed', 'chol_error_identifier', ...
    'chol_error_message', 'chol_flag', 'partial_factor_rows', ...
    'partial_factor_columns', 'partial_factor_nnz', ...
    'partial_factor_nonfinite_count', 'pivot_reduced_id', ...
    'pivot_master_id', 'pivot_group_size', 'pivot_full_node_ids', ...
    'pivot_triangle_incidences', 'pivot_p_column_nnz', ...
    'pivot_p_support_node_ids', 'pivot_reduced_row_nnz', ...
    'pivot_reduced_column_nnz', 'pivot_reduced_support_ids', ...
    'pivot_full_mass_support_node_ids', 'pivot_diagonal_real', ...
    'pivot_diagonal_imag', 'pivot_row_nonfinite_count', ...
    'pivot_column_nonfinite_count'}, artifacts.chol_rows);
end

function LOCAL_write_mass_summary(summary, payload, output_dir)
  row = {summary.diagnostic_id, summary.input_kind, summary.model_id, ...
    summary.model_digest, summary.mesh_id, summary.phase_kind, ...
    summary.alpha, summary.beta, summary.full_point_count, ...
    summary.triangle_used_point_count, summary.unused_point_count, ...
    summary.unused_point_ids, summary.master_min, summary.master_max, ...
    summary.master_unique_count, summary.p_rows, summary.p_columns, ...
    summary.p_nnz, summary.p_zero_support_column_count, ...
    summary.p_zero_support_column_ids, summary.p_entry_modulus_min, ...
    summary.p_entry_modulus_max, summary.chol_flag, ...
    summary.completed_eigensolves, summary.reference_exported, ...
    summary.evidence_complete};
  LOCAL_assert_mass_csv_rows(row, 'mass-summary.csv', 26);
  LOCAL_write_csv(fullfile(output_dir, 'mass-summary.csv'), ...
    {'diagnostic_id', 'input_kind', 'model_id', 'model_digest', ...
    'mesh_id', 'phase_kind', 'alpha', 'beta', 'full_point_count', ...
    'triangle_used_point_count', 'unused_point_count', ...
    'unused_point_ids', 'master_min', 'master_max', ...
    'master_unique_count', 'p_rows', 'p_columns', 'p_nnz', ...
    'p_zero_support_column_count', 'p_zero_support_column_ids', ...
    'p_entry_modulus_min', 'p_entry_modulus_max', 'chol_flag', ...
    'completed_eigensolves', 'reference_exported', ...
    'evidence_complete'}, row);
  LOCAL_atomic_save(fullfile(output_dir, 'mass-summary.mat'), payload);
end

function LOCAL_write_mass_diagnostic_summary(summary, output_dir)
  row = {summary.diagnostic_id, summary.status, summary.input_kind, ...
    summary.mesh_id, summary.alpha, summary.completed_eigensolves, ...
    summary.reference_exported, summary.bulk_band_rows, ...
    summary.bulk_gap_rows, summary.evidence_complete, ...
    summary.wall_estimate_minutes, summary.peak_estimate_gib, ...
    summary.elapsed_seconds, summary.failure_code, ...
    summary.failure_reason, summary.claim_boundary};
  LOCAL_assert_mass_csv_rows(row, 'diagnostic-summary.csv', 16);
  LOCAL_atomic_save(fullfile(output_dir, 'diagnostic-summary.mat'), summary);
  LOCAL_write_csv(fullfile(output_dir, 'diagnostic-summary.csv'), ...
    {'diagnostic_id', 'status', 'input_kind', 'mesh_id', 'alpha', ...
    'completed_eigensolves', 'reference_exported', 'bulk_band_rows', ...
    'bulk_gap_rows', 'evidence_complete', 'wall_estimate_minutes', ...
    'peak_estimate_gib', 'elapsed_seconds', 'failure_code', ...
    'failure_reason', 'claim_boundary'}, row);
end

function LOCAL_assert_mass_csv_rows(rows, ledger_name, expected_columns)
  if ~iscell(rows) || ~ismatrix(rows) || ...
      size(rows, 2) ~= expected_columns
    LOCAL_raise('MASS_EVIDENCE_REPRESENTATION_UNSAFE', sprintf( ...
      '%s has %d columns, expected %d.', ledger_name, ...
      size(rows, 2), expected_columns));
  end
  for row_index = 1:size(rows, 1)
    for column_index = 1:size(rows, 2)
      cell_value = rows{row_index, column_index};
      if isnumeric(cell_value) || islogical(cell_value)
        safe_value = ~issparse(cell_value) && ...
          (isempty(cell_value) || isscalar(cell_value));
      elseif ischar(cell_value)
        safe_value = isempty(cell_value) || isrow(cell_value);
      elseif isstring(cell_value)
        safe_value = isscalar(cell_value);
      else
        safe_value = false;
      end
      if ~safe_value
        LOCAL_raise('MASS_EVIDENCE_REPRESENTATION_UNSAFE', sprintf( ...
          ['%s row %d column %d has unsafe class=%s, sparse=%d, ' ...
          'size=%s.'], ledger_name, row_index, column_index, ...
          class(cell_value), issparse(cell_value), ...
          LOCAL_flat_numeric(size(cell_value))));
      end
    end
  end
end

function present = LOCAL_required_mass_artifacts_present( ...
    output_dir, include_summary)
  required_names = {'mesh-ledger.csv', 'seam-checks.csv', ...
    'bulk-bands.csv', 'bulk-gaps.csv', 'mass-node-incidence.csv', ...
    'mass-master-groups.csv', 'mass-matrices.csv', ...
    'mass-chol-pivot.csv'};
  if include_summary
    required_names = [required_names, ...
      {'mass-summary.csv', 'mass-summary.mat'}];
  end
  present = true;
  for name_index = 1:numel(required_names)
    final_path = fullfile(output_dir, required_names{name_index});
    present = present && exist(final_path, 'file') == 2 && ...
      exist([final_path '.partial'], 'file') ~= 2;
  end
end

function evidence = LOCAL_mass_gate_diagnostics(mesh, reduced)
  full_point_count = size(mesh.points, 1);
  node_incidence = accumarray(mesh.triangles(:), 1, ...
    [full_point_count, 1]);
  unused_point_ids = find(node_incidence == 0);
  master_index = mesh.periodic.master_index(:);
  master_ids = unique(master_index);
  if isempty(master_ids)
    master_min = NaN;
    master_max = NaN;
  else
    master_min = min(master_ids);
    master_max = max(master_ids);
  end

  phase_prolongation = reduced.prolongation;
  p_row_support = sum(spones(phase_prolongation), 2);
  p_column_support = sum(spones(phase_prolongation), 1).';
  p_zero_support_column_ids = find(p_column_support == 0);
  p_entry_modulus = abs(nonzeros(phase_prolongation));
  if isempty(p_entry_modulus)
    p_entry_modulus_min = NaN;
    p_entry_modulus_max = NaN;
  else
    p_entry_modulus_min = min(p_entry_modulus);
    p_entry_modulus_max = max(p_entry_modulus);
  end

  node_rows = cell(full_point_count, 9);
  for node_id = 1:full_point_count
    if node_id <= size(phase_prolongation, 1)
      p_row_column_ids = find(phase_prolongation(node_id, :));
      p_row_values = full(phase_prolongation( ...
        node_id, p_row_column_ids));
      p_row_nnz = full(p_row_support(node_id));
    else
      p_row_column_ids = [];
      p_row_values = [];
      p_row_nnz = 0;
    end
    if numel(p_row_values) == 1
      p_entry_real = real(p_row_values);
      p_entry_imag = imag(p_row_values);
      p_entry_modulus_value = abs(p_row_values);
    else
      p_entry_real = NaN;
      p_entry_imag = NaN;
      p_entry_modulus_value = NaN;
    end
    node_rows(node_id, :) = {node_id, node_incidence(node_id), ...
      node_incidence(node_id) > 0, master_index(node_id), p_row_nnz, ...
      LOCAL_integer_list(p_row_column_ids), p_entry_real, ...
      p_entry_imag, p_entry_modulus_value};
  end

  master_rows = cell(numel(master_ids), 7);
  master_group_members = cell(numel(master_ids), 1);
  for master_row_id = 1:numel(master_ids)
    master_id = master_ids(master_row_id);
    member_node_ids = find(master_index == master_id);
    master_group_members{master_row_id} = member_node_ids;
    if isfinite(master_id) && master_id == fix(master_id) && ...
        master_id >= 1 && master_id <= size(phase_prolongation, 2)
      p_support_node_ids = find(phase_prolongation(:, master_id));
      p_column_values = nonzeros(phase_prolongation(:, master_id));
    else
      p_support_node_ids = [];
      p_column_values = [];
    end
    if isempty(p_column_values)
      p_column_modulus_min = NaN;
      p_column_modulus_max = NaN;
    else
      p_column_modulus_min = min(abs(p_column_values));
      p_column_modulus_max = max(abs(p_column_values));
    end
    master_rows(master_row_id, :) = {master_id, numel(member_node_ids), ...
      LOCAL_integer_list(member_node_ids), numel(p_support_node_ids), ...
      LOCAL_integer_list(p_support_node_ids), p_column_modulus_min, ...
      p_column_modulus_max};
  end

  full_matrix_diagnostic = LOCAL_mass_matrix_diagnostics( ...
    'full-as-built', mesh.mass_full);
  reduced_matrix_diagnostic = LOCAL_mass_matrix_diagnostics( ...
    'reduced-as-built', reduced.mass);
  matrix_rows = [full_matrix_diagnostic.csv_row; ...
    reduced_matrix_diagnostic.csv_row];

  partial_factor = sparse(0, 0);
  chol_flag = NaN;
  chol_call_completed = false;
  chol_error_identifier = '';
  chol_error_message = '';
  try
    [partial_factor, chol_flag] = chol(reduced.mass);
    chol_call_completed = true;
  catch caught
    chol_error_identifier = caught.identifier;
    chol_error_message = caught.message;
  end
  reduced_order = size(reduced.mass, 1);
  chol_flag_valid = chol_call_completed && isscalar(chol_flag) && ...
    isreal(chol_flag) && isfinite(chol_flag) && ...
    chol_flag == fix(chol_flag) && chol_flag >= 0 && ...
    chol_flag <= reduced_order;
  [chol_row, pivot_support] = LOCAL_chol_pivot_evidence( ...
    mesh, reduced, node_incidence, partial_factor, ...
    chol_call_completed, chol_error_identifier, chol_error_message, ...
    chol_flag, chol_flag_valid);

  evidence = struct();
  evidence.node_rows = node_rows;
  evidence.master_rows = master_rows;
  evidence.matrix_rows = matrix_rows;
  evidence.chol_rows = chol_row;
  evidence.node_incidence = node_incidence;
  evidence.unused_point_ids = unused_point_ids;
  evidence.master_ids = master_ids;
  evidence.master_min = master_min;
  evidence.master_max = master_max;
  evidence.master_group_members = master_group_members;
  evidence.p_zero_support_column_ids = p_zero_support_column_ids;
  evidence.p_entry_modulus_min = p_entry_modulus_min;
  evidence.p_entry_modulus_max = p_entry_modulus_max;
  evidence.partial_factor = partial_factor;
  evidence.chol_call_completed = chol_call_completed;
  evidence.chol_error_identifier = chol_error_identifier;
  evidence.chol_error_message = chol_error_message;
  evidence.chol_flag = chol_flag;
  evidence.matrix_diagnostics = struct( ...
    'full_as_built', full_matrix_diagnostic, ...
    'reduced_as_built', reduced_matrix_diagnostic);
  evidence.pivot_support = pivot_support;
  evidence.measurements_complete = chol_flag_valid;
end

function diagnostic = LOCAL_mass_matrix_diagnostics(matrix_id, matrix)
  matrix_size = size(matrix);
  stored_values = nonzeros(matrix);
  zero_row_ids = find(sum(spones(matrix), 2) == 0);
  zero_column_ids = find(sum(spones(matrix), 1) == 0).';
  diagonal_values = diag(matrix);
  if isempty(diagonal_values)
    diagonal_real_min = NaN;
    diagonal_real_max = NaN;
    diagonal_max_abs_imag = NaN;
  else
    diagonal_real_min = full(min(real(diagonal_values)));
    diagonal_real_max = full(max(real(diagonal_values)));
    diagonal_max_abs_imag = full(max(abs(imag(diagonal_values))));
  end
  hermitian_defect_absolute_1 = norm(matrix - matrix', 1);
  hermitian_defect_normalized_1 = hermitian_defect_absolute_1 / ...
    max(1, norm(matrix, 1));
  diagnostic = struct();
  diagnostic.matrix_id = matrix_id;
  diagnostic.rows = matrix_size(1);
  diagnostic.columns = matrix_size(2);
  diagnostic.nnz = nnz(matrix);
  diagnostic.stored_nonfinite_count = nnz(~isfinite(stored_values));
  diagnostic.zero_row_ids = zero_row_ids;
  diagnostic.zero_column_ids = zero_column_ids;
  diagnostic.diagonal_real_min = diagonal_real_min;
  diagnostic.diagonal_real_max = diagonal_real_max;
  diagnostic.diagonal_max_abs_imag = diagonal_max_abs_imag;
  diagnostic.hermitian_defect_absolute_1 = ...
    hermitian_defect_absolute_1;
  diagnostic.hermitian_defect_normalized_1 = ...
    hermitian_defect_normalized_1;
  diagnostic.csv_row = {matrix_id, matrix_size(1), matrix_size(2), ...
    nnz(matrix), diagnostic.stored_nonfinite_count, ...
    numel(zero_row_ids), LOCAL_integer_list(zero_row_ids), ...
    numel(zero_column_ids), LOCAL_integer_list(zero_column_ids), ...
    diagonal_real_min, diagonal_real_max, diagonal_max_abs_imag, ...
    hermitian_defect_absolute_1, hermitian_defect_normalized_1};
end

function [row, pivot] = LOCAL_chol_pivot_evidence( ...
    mesh, reduced, node_incidence, partial_factor, ...
    chol_call_completed, chol_error_identifier, chol_error_message, ...
    chol_flag, chol_flag_valid)
  partial_values = nonzeros(partial_factor);
  pivot = struct();
  pivot.mapping_kind = 'NATURAL_1_BASED_NO_PERMUTATION';
  pivot.mapping_valid = false;
  pivot.reduced_id = NaN;
  pivot.master_id = NaN;
  pivot.group_size = NaN;
  pivot.full_node_ids = [];
  pivot.triangle_incidences = [];
  pivot.p_column_nnz = NaN;
  pivot.p_support_node_ids = [];
  pivot.reduced_row_nnz = NaN;
  pivot.reduced_column_nnz = NaN;
  pivot.reduced_support_ids = [];
  pivot.full_mass_support_node_ids = [];
  pivot.diagonal_real = NaN;
  pivot.diagonal_imag = NaN;
  pivot.row_nonfinite_count = NaN;
  pivot.column_nonfinite_count = NaN;

  if chol_flag_valid && chol_flag >= 1
    pivot_id = double(chol_flag);
    pivot.mapping_valid = true;
    pivot.reduced_id = pivot_id;
    pivot.master_id = pivot_id;
    pivot.full_node_ids = find(mesh.periodic.master_index == pivot_id);
    pivot.group_size = numel(pivot.full_node_ids);
    pivot.triangle_incidences = node_incidence(pivot.full_node_ids);
    pivot.p_support_node_ids = find(reduced.prolongation(:, pivot_id));
    pivot.p_column_nnz = numel(pivot.p_support_node_ids);
    reduced_row_support = find(reduced.mass(pivot_id, :));
    reduced_column_support = find(reduced.mass(:, pivot_id));
    pivot.reduced_row_nnz = numel(reduced_row_support);
    pivot.reduced_column_nnz = numel(reduced_column_support);
    pivot.reduced_support_ids = union( ...
      reduced_row_support(:), reduced_column_support(:));
    if ~isempty(pivot.full_node_ids)
      full_row_support = find(any(spones( ...
        mesh.mass_full(pivot.full_node_ids, :)), 1));
      full_column_support = find(any(spones( ...
        mesh.mass_full(:, pivot.full_node_ids)), 2));
      pivot.full_mass_support_node_ids = union( ...
        full_row_support(:), full_column_support(:));
    end
    pivot_diagonal = full(reduced.mass(pivot_id, pivot_id));
    pivot.diagonal_real = real(pivot_diagonal);
    pivot.diagonal_imag = imag(pivot_diagonal);
    pivot.row_nonfinite_count = nnz(~isfinite( ...
      nonzeros(reduced.mass(pivot_id, :))));
    pivot.column_nonfinite_count = nnz(~isfinite( ...
      nonzeros(reduced.mass(:, pivot_id))));
  end

  row = {chol_call_completed, chol_error_identifier, chol_error_message, ...
    chol_flag, size(partial_factor, 1), size(partial_factor, 2), ...
    nnz(partial_factor), nnz(~isfinite(partial_values)), ...
    pivot.reduced_id, pivot.master_id, pivot.group_size, ...
    LOCAL_integer_list(pivot.full_node_ids), ...
    LOCAL_integer_sequence(pivot.triangle_incidences), ...
    pivot.p_column_nnz, LOCAL_integer_list(pivot.p_support_node_ids), ...
    pivot.reduced_row_nnz, pivot.reduced_column_nnz, ...
    LOCAL_integer_list(pivot.reduced_support_ids), ...
    LOCAL_integer_list(pivot.full_mass_support_node_ids), ...
    pivot.diagonal_real, pivot.diagonal_imag, ...
    pivot.row_nonfinite_count, pivot.column_nonfinite_count};
end

function text_value = LOCAL_integer_list(values)
  values = sort(unique(values(:).'));
  text_value = LOCAL_integer_sequence(values);
end

function text_value = LOCAL_integer_sequence(values)
  if isempty(values)
    text_value = '';
    return;
  end
  pieces = arrayfun(@(value) sprintf('%d', value), values(:).', ...
    'UniformOutput', false);
  text_value = strjoin(pieces, ';');
end

%% ==================== Zero-eigensolve representation diagnostic ====================
% Sections 22.12--22.14 audit representation correctness and formal overhead.

function LOCAL_run_representation_diagnostic(diagnostic_id)
  diagnostic_clock = tic;
  entry_dir = fileparts(mfilename('fullpath'));
  diagnostic_dir = fullfile(entry_dir, 'diagnostics', diagnostic_id);
  if exist(diagnostic_dir, 'dir') || exist(diagnostic_dir, 'file')
    error('I4A:DiagnosticCollision', ...
      'DIAGNOSTIC_COLLISION: diagnostics/%s already exists.', diagnostic_id);
  end
  [made_diagnostic, diagnostic_message] = mkdir(diagnostic_dir);
  if ~made_diagnostic
    error('I4A:OutputUnavailable', ...
      'Cannot create representation diagnostic directory: %s', ...
      diagnostic_message);
  end
  temporary_work_dir = tempname;
  [made_work, work_message] = mkdir(temporary_work_dir);
  if ~made_work
    LOCAL_write_representation_terminal_stub( ...
      diagnostic_id, diagnostic_dir, diagnostic_clock, ...
      'EXECUTION_UNAVAILABLE', work_message);
    error('I4A:OutputUnavailable', ...
      'Cannot create representation diagnostic work directory: %s', ...
      work_message);
  end
  cleanup_work = onCleanup( ...
    @() LOCAL_remove_diagnostic_work(temporary_work_dir)); %#ok<NASGU>

  spec = LOCAL_spec();
  summary = LOCAL_initial_representation_summary(spec, diagnostic_id);
  resource_rows = cell(0, 17);
  probe_rows = cell(0, 16);
  partition_rows = cell(0, 7);
  rewrite_rows = cell(0, 11);
  forecast_rows = cell(0, 27);
  progress_rows = cell(0, 4);
  mesh_rows = cell(0, 36);
  seam_rows = cell(0, 12);
  mesh_artifacts = struct('mesh_rows', {mesh_rows}, ...
    'seam_rows', {seam_rows});
  bulk_artifacts = struct('bulk_rows', {cell(0, 10)}, ...
    'bulk_gap_rows', {cell(0, 14)});
  operator_ledger = LOCAL_initial_operator_ledger( ...
    spec, diagnostic_dir, 'REPRESENTATION_DIAGNOSTIC');

  try
    LOCAL_write_bulk_artifacts(bulk_artifacts, diagnostic_dir);
    LOCAL_write_operator_representation(operator_ledger);
    progress_rows = LOCAL_representation_progress(progress_rows, ...
      diagnostic_dir, diagnostic_clock, 'HEADER_FIRST', 'COMPLETE');
    LOCAL_check_environment(spec);

    schedule = LOCAL_mesh_schedule();
    mesh_ids = {'bulk-s24-g48', 'defect-N5-s24-g48'};
    meshes = cell(1, 2);
    for mesh_index = 1:2
      schedule_index = find(strcmp({schedule.id}, mesh_ids{mesh_index}));
      if numel(schedule_index) ~= 1
        error('I4A:RepresentationDiagnosticSpec', ...
          'Diagnostic mesh identity is not unique.');
      end
      [mesh, mesh_diagnostic] = LOCAL_build_mesh(spec, ...
        schedule(schedule_index), mesh_rows, seam_rows, diagnostic_dir);
      mesh_rows(end + 1, :) = LOCAL_mesh_diagnostic_row( ...
        schedule(schedule_index), mesh_diagnostic, ...
        'REPRESENTATION_DIAGNOSTIC_MESH_COMPLETE', '', ''); %#ok<AGROW>
      meshes{mesh_index} = mesh;
      mesh_artifacts.mesh_rows = mesh_rows;
      mesh_artifacts.seam_rows = seam_rows;
      LOCAL_write_mesh_artifacts(mesh_artifacts, diagnostic_dir);
    end
    bulk_mesh = meshes{1};
    defect_mesh = meshes{2};
    progress_rows = LOCAL_representation_progress(progress_rows, ...
      diagnostic_dir, diagnostic_clock, 'SOURCE_MESH_REBUILD', 'COMPLETE');

    phase_specs = {bulk_mesh, pi / 4, 'bulk-alpha', ...
      'representation-largest-bulk-pi4'; ...
      defect_mesh, pi / 4, 'defect-theta', ...
      'representation-finest-defect-pi4'; ...
      defect_mesh, 0, 'defect-theta', ...
      'representation-finest-defect-theta0'};
    phase_pairs = cell(3, 1);
    raw_pairs = cell(3, 1);
    endpoint_phase_elapsed = 0;
    for phase_index = 1:3
      mesh = phase_specs{phase_index, 1};
      phase = phase_specs{phase_index, 2};
      phase_kind = phase_specs{phase_index, 3};
      solve_id = phase_specs{phase_index, 4};
      phase_clock = tic;
      [raw_reduced, phase_diagnostic] = LOCAL_phase_reduce( ...
        spec, mesh, phase, 'representation-diagnostic');
      raw_pairs{phase_index} = raw_reduced;
      seam_rows(end + 1, :) = LOCAL_seam_row( ...
        mesh.id, phase_kind, phase, phase_diagnostic); %#ok<AGROW>
      mesh_artifacts.mesh_rows = mesh_rows;
      mesh_artifacts.seam_rows = seam_rows;
      LOCAL_write_mesh_artifacts(mesh_artifacts, diagnostic_dir);
      [phase_pairs{phase_index}, operator_ledger] = ...
        LOCAL_prepare_primary_pair(spec, raw_reduced, mesh.id, ...
        phase_kind, phase, solve_id, 'REPRESENTATION_DIAGNOSTIC_PRIMARY', ...
        operator_ledger);
      if phase_index == 3
        endpoint_phase_elapsed = toc(phase_clock);
      end
    end
    progress_rows = LOCAL_representation_progress(progress_rows, ...
      diagnostic_dir, diagnostic_clock, 'THREE_PRIMARY_PAIRS', 'COMPLETE');

    sample_names = {'largest-bulk', 'finest-defect'};
    for sample_index = 1:2
      raw_reduced = raw_pairs{sample_index};
      operator_pair = phase_pairs{sample_index};
      contract_id = operator_pair.operator_contract_id;
      raw_stats = LOCAL_measure_repeated( ...
        @() LOCAL_probe_primary_raw(raw_reduced));
      canonical_stats = LOCAL_measure_repeated( ...
        @() LOCAL_probe_primary_canonical(raw_reduced));
      factor_stats = LOCAL_measure_repeated( ...
        @() LOCAL_probe_primary_factor(operator_pair.mass));
      sample_stats = {raw_stats, canonical_stats, factor_stats};
      paths = {'primary-raw-diagnostics', ...
        'primary-canonical-construction', 'primary-mass-factorization'};
      for component_index = 1:3
        probe_rows(end + 1, :) = LOCAL_probe_cost_row( ...
          diagnostic_id, sample_names{sample_index}, ...
          paths{component_index}, [], ...
          contract_id, '', sample_stats{component_index}); %#ok<AGROW>
      end
      input_bytes = LOCAL_value_bytes(raw_reduced.stiffness) + ...
        LOCAL_value_bytes(raw_reduced.mass);
      canonical_bytes = LOCAL_value_bytes(operator_pair.stiffness) + ...
        LOCAL_value_bytes(operator_pair.mass) + ...
        LOCAL_value_bytes(operator_pair.mass_factor);
      resource_rows(end + 1, :) = LOCAL_representation_resource_row( ...
        diagnostic_id, sample_names{sample_index}, ...
        phase_specs{sample_index, 1}.id, phase_specs{sample_index, 3}, ...
        phase_specs{sample_index, 2}, 'primary-pair-timing', [], [], [], ...
        sum(cellfun(@(item) item.conservative_seconds, sample_stats)), ...
        input_bytes, input_bytes + canonical_bytes, canonical_bytes, ...
        0, 48, 'formal-primary-proxy', ...
        'two warmups and five timed repetitions per component'); %#ok<AGROW>
    end

    widths = 1:48;
    path_names = {'global', 'restricted-center', 'restricted-core', ...
      'restricted-tail', 'endpoint-parity', 'common-core'};
    conservative_costs = zeros(6, 48);
    timing_spreads = zeros(6, 48);
    endpoint_setup_elapsed = endpoint_phase_elapsed;
    endpoint_setup_bytes = 0;
    for width = widths
      defect_initial = LOCAL_deterministic_probe_basis( ...
        defect_mesh, phase_pairs{2}, width);
      global_action = @() LOCAL_probe_global_path( ...
        spec, phase_pairs{2}, defect_initial);
      global_stats = LOCAL_measure_repeated(global_action);
      [~, defect_full, global_bytes] = LOCAL_probe_global_path( ...
        spec, phase_pairs{2}, defect_initial);
      global_contract = LOCAL_derived_contract_id( ...
        phase_pairs{2}.operator_contract_id, 'global-probe', ...
        sprintf('width-%d', width));
      [probe_rows, resource_rows, conservative_costs, timing_spreads] = ...
        LOCAL_record_width_probe(diagnostic_id, probe_rows, resource_rows, ...
        conservative_costs, timing_spreads, 1, width, 'global', ...
        global_contract, ...
        phase_pairs{2}.operator_contract_id, global_stats, global_bytes, ...
        defect_mesh.id, pi / 4, 'defect-theta');

      restricted_masses = {defect_mesh.mass_center, ...
        defect_mesh.mass_core, defect_mesh.mass_tail};
      for restricted_index = 1:3
        stats = LOCAL_measure_repeated(@() LOCAL_probe_restricted_path( ...
          spec, defect_full, restricted_masses{restricted_index}));
        path_index = restricted_index + 1;
        object_id = ['probe-' path_names{path_index}];
        contract_id = LOCAL_derived_contract_id( ...
          phase_pairs{2}.operator_contract_id, object_id, ...
          sprintf('width-%d', width));
        probe_bytes = LOCAL_probe_restricted_path( ...
          spec, defect_full, restricted_masses{restricted_index});
        [probe_rows, resource_rows, conservative_costs, timing_spreads] = ...
          LOCAL_record_width_probe(diagnostic_id, probe_rows, resource_rows, ...
          conservative_costs, timing_spreads, path_index, width, ...
          path_names{path_index}, contract_id, ...
          phase_pairs{2}.operator_contract_id, stats, probe_bytes, ...
          defect_mesh.id, pi / 4, 'defect-theta');
      end

      common_stats = LOCAL_measure_repeated(@() LOCAL_probe_common_core_path( ...
        spec, defect_mesh, defect_full));
      common_contract = LOCAL_derived_contract_id( ...
        phase_pairs{2}.operator_contract_id, 'common-core-probe', ...
        sprintf('width-%d', width));
      common_bytes = LOCAL_probe_common_core_path( ...
        spec, defect_mesh, defect_full);
      [probe_rows, resource_rows, conservative_costs, timing_spreads] = ...
        LOCAL_record_width_probe(diagnostic_id, probe_rows, resource_rows, ...
        conservative_costs, timing_spreads, 6, width, 'common-core', ...
        common_contract, phase_pairs{2}.operator_contract_id, ...
        common_stats, common_bytes, defect_mesh.id, pi / 4, 'defect-theta');

      endpoint_setup_clock = tic;
      endpoint_initial = LOCAL_deterministic_probe_basis( ...
        defect_mesh, phase_pairs{3}, width);
      [~, endpoint_full, endpoint_bytes] = LOCAL_probe_global_path( ...
        spec, phase_pairs{3}, endpoint_initial);
      endpoint_setup_bytes = max(endpoint_setup_bytes, endpoint_bytes);
      endpoint_setup_elapsed = endpoint_setup_elapsed + ...
        toc(endpoint_setup_clock);
      parity_stats = LOCAL_measure_repeated(@() LOCAL_probe_parity_path( ...
        spec, defect_mesh, endpoint_full, ...
        phase_pairs{3}.operator_contract_id, width));
      parity_contract = LOCAL_derived_contract_id( ...
        phase_pairs{3}.operator_contract_id, 'parity-probe', ...
        sprintf('width-%d', width));
      parity_bytes = LOCAL_probe_parity_path( ...
        spec, defect_mesh, endpoint_full, ...
        phase_pairs{3}.operator_contract_id, width);
      [probe_rows, resource_rows, conservative_costs, timing_spreads] = ...
        LOCAL_record_width_probe(diagnostic_id, probe_rows, resource_rows, ...
        conservative_costs, timing_spreads, 5, width, 'endpoint-parity', ...
        parity_contract, phase_pairs{3}.operator_contract_id, ...
        parity_stats, parity_bytes, defect_mesh.id, 0, 'defect-theta');
    end
    resource_rows(end + 1, :) = LOCAL_representation_resource_row( ...
      diagnostic_id, 'finest-defect-theta0', defect_mesh.id, ...
      'defect-theta', 0, 'endpoint-parity-phase-and-global-setup', ...
      [], [], [], endpoint_setup_elapsed, 0, endpoint_setup_bytes, ...
      endpoint_setup_bytes, 0, 48, 'diagnostic-own-budget-only', ...
      'excluded from formal additive forecast'); %#ok<AGROW>

    [row_stats, padding_rows, padding_bytes] = ...
      LOCAL_measure_row_preparation(spec);
    resource_rows(end + 1, :) = LOCAL_representation_resource_row( ...
      diagnostic_id, 'operator-ledger', '', '', [], 'row-preparation', ...
      [], spec.operator_row_upper_count, 36, row_stats.conservative_seconds, ...
      0, padding_bytes, padding_bytes, 0, 0, ...
      'formal-additive-once', ...
      sprintf(['exact 10414-by-36 container;serialization excluded;' ...
      'warmup=2;repeat=5;min=%.17g;mean=%.17g;max=%.17g;cv=%.17g;q=%.17g'], ...
      row_stats.repeat_min_seconds, row_stats.repeat_mean_seconds, ...
      row_stats.repeat_max_seconds, row_stats.coefficient_of_variation, ...
      row_stats.quantization_floor_seconds)); %#ok<AGROW>

    [rewrite_rows, rewrite_seconds, rewrite_peak_bytes] = ...
      LOCAL_benchmark_growing_writer(diagnostic_id, spec, ...
      padding_rows, temporary_work_dir);
    resource_rows(end + 1, :) = LOCAL_representation_resource_row( ...
      diagnostic_id, 'operator-ledger', '', '', [], 'growing-rewrite', ...
      [], spec.operator_row_upper_count, 36, rewrite_seconds, ...
      padding_bytes, max(padding_bytes, rewrite_peak_bytes), ...
      max(0, rewrite_peak_bytes - padding_bytes), 0, 0, ...
      'formal-additive-once', 'one empty warmup plus exact cumulative trial'); ...
      %#ok<AGROW>

    primary_bulk = sum(cell2mat(probe_rows(1:3, 13)));
    primary_defect = sum(cell2mat(probe_rows(4:6, 13)));
    primary_bulk_spread = sum(cell2mat(probe_rows(1:3, 10)) - ...
      cell2mat(probe_rows(1:3, 8)));
    primary_defect_spread = sum(cell2mat(probe_rows(4:6, 10)) - ...
      cell2mat(probe_rows(4:6, 8)));
    family_costs = [conservative_costs(1, :); ...
      sum(conservative_costs(2:4, :), 1); conservative_costs(5, :); ...
      conservative_costs(6, :)];
    family_spreads = [timing_spreads(1, :); ...
      sum(timing_spreads(2:4, :), 1); timing_spreads(5, :); ...
      timing_spreads(6, :)];
    [partition_rows, partition_costs, partition_spreads] = ...
      LOCAL_partition_evidence(family_costs, family_spreads);
    global_40 = 42 * partition_costs(1, 1);
    global_48 = 5 * partition_costs(1, 2);
    restricted_40 = 42 * partition_costs(2, 1);
    restricted_48 = 5 * partition_costs(2, 2);
    parity_40 = 12 * partition_costs(3, 1);
    parity_48 = 2 * partition_costs(3, 2);
    common_40 = 42 * partition_costs(4, 1);
    common_48 = 5 * partition_costs(4, 2);
    additive_seconds = 72 * primary_bulk + 47 * primary_defect + ...
      global_40 + global_48 + restricted_40 + restricted_48 + ...
      parity_40 + parity_48 + common_40 + common_48 + ...
      row_stats.conservative_seconds + rewrite_seconds;
    baseline_seconds = 29.8 * 60;
    forecast_seconds = baseline_seconds + additive_seconds;
    spread_bound = 72 * primary_bulk_spread + ...
      47 * primary_defect_spread + ...
      42 * partition_spreads(1, 1) + 5 * partition_spreads(1, 2) + ...
      42 * partition_spreads(2, 1) + ...
      5 * partition_spreads(2, 2) + ...
      12 * partition_spreads(3, 1) + 2 * partition_spreads(3, 2) + ...
      42 * partition_spreads(4, 1) + 5 * partition_spreads(4, 2) + ...
      (row_stats.repeat_max_seconds - row_stats.repeat_min_seconds);
    timing_pass = all(cell2mat(probe_rows(:, 14))) && ...
      row_stats.gate_pass && ...
      isfinite(spread_bound) && ...
      (1800 - forecast_seconds) > max(1, spread_bound);
    incremental_peak_bytes = max([cell2mat(resource_rows(:, 13)); ...
      padding_bytes; rewrite_peak_bytes]);
    baseline_peak_bytes = spec.design_peak_estimate_gib * 1024 ^ 3;
    forecast_peak_bytes = baseline_peak_bytes + incremental_peak_bytes;
    wall_pass = forecast_seconds < 1800;
    peak_pass = forecast_peak_bytes <= 1.5 * 1024 ^ 3;
    if strcmp(diagnostic_id, 'representation-gate-003')
      internal_pass = wall_pass && peak_pass && timing_pass;
    elseif strcmp(diagnostic_id, 'representation-gate-002')
      internal_pass = wall_pass && timing_pass;
    else
      internal_pass = wall_pass && peak_pass && timing_pass;
    end
    if internal_pass
      forecast_failure_code = '';
      forecast_failure_reason = '';
    else
      if strcmp(diagnostic_id, 'representation-gate-002')
        forecast_failure_code = 'RESOURCE_BUDGET_UNAVAILABLE';
        forecast_failure_reason = ...
          'Strict wall, CV, timing, or propagated-spread gate failed.';
      elseif strcmp(diagnostic_id, 'representation-gate-003')
        forecast_failure_code = 'ADVISORY_RESOURCE_SCREEN_FALSE';
        forecast_failure_reason = sprintf([ ...
          'OBSERVATION_ONLY_NOT_EXECUTION_FAILURE;' ...
          'wall_pass=%s;forecast_at_most_1p5_gib=%s;timing_pass=%s'], ...
          LOCAL_boolean_text(wall_pass), LOCAL_boolean_text(peak_pass), ...
          LOCAL_boolean_text(timing_pass));
      else
        forecast_failure_code = 'RESOURCE_BUDGET_UNAVAILABLE';
        forecast_failure_reason = ...
          'Strict wall, array-peak, CV, or propagated-spread gate failed.';
      end
    end
    forecast_rows = {baseline_seconds, 72, primary_bulk, 47, ...
      primary_defect, global_40, global_48, restricted_40, ...
      restricted_48, parity_40, parity_48, common_40, common_48, ...
      row_stats.conservative_seconds, rewrite_seconds, additive_seconds, ...
      forecast_seconds, forecast_seconds / 60, wall_pass, ...
      baseline_peak_bytes, incremental_peak_bytes, forecast_peak_bytes, ...
      forecast_peak_bytes / 1024 ^ 3, peak_pass, internal_pass, ...
      forecast_failure_code, forecast_failure_reason};

    LOCAL_write_representation_ledgers(diagnostic_dir, resource_rows, ...
      probe_rows, partition_rows, rewrite_rows, forecast_rows);
    progress_rows = LOCAL_representation_progress(progress_rows, ...
      diagnostic_dir, diagnostic_clock, 'INTERNAL_BENCHMARK', 'COMPLETE');
    summary.primary_rows = size(operator_ledger.rows, 1);
    [summary.correctness_pass, completion_reason] = ...
      LOCAL_representation_completion_gate(spec, diagnostic_dir, ...
      summary, mesh_rows, seam_rows, bulk_artifacts, operator_ledger, ...
      resource_rows, probe_rows, partition_rows, rewrite_rows, ...
      forecast_rows, padding_rows, progress_rows);
    summary.internal_benchmark_complete = summary.correctness_pass;
    summary.internal_forecast_seconds = forecast_seconds;
    summary.internal_array_peak_bytes = forecast_peak_bytes;
    if summary.correctness_pass && ...
        strcmp(diagnostic_id, 'representation-gate-003')
      summary.status = ...
        'REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW';
    elseif summary.correctness_pass && internal_pass
      summary.status = ...
        'REPRESENTATION_GATE_COMPLETE_PENDING_EXTERNAL_RESOURCE_REVIEW';
    elseif summary.correctness_pass
      summary.status = 'REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL';
      summary.failure_code = 'RESOURCE_BUDGET_UNAVAILABLE';
      summary.failure_reason = forecast_failure_reason;
    else
      summary.status = 'REPRESENTATION_GATE_INCOMPLETE';
      summary.failure_code = summary.status;
      summary.failure_reason = completion_reason;
    end
  catch caught
    [failure_code, failure_reason] = LOCAL_decode_failure(caught);
    summary.status = 'REPRESENTATION_GATE_INCOMPLETE';
    summary.primary_rows = size(operator_ledger.rows, 1);
    summary.failure_code = failure_code;
    summary.failure_reason = failure_reason;
    try
      LOCAL_write_representation_ledgers(diagnostic_dir, resource_rows, ...
        probe_rows, partition_rows, rewrite_rows, forecast_rows);
    catch publication_caught
      summary.failure_reason = sprintf('%s;ledger_publication=%s', ...
        summary.failure_reason, publication_caught.message);
    end
  end
  summary.elapsed_seconds = toc(diagnostic_clock);
  LOCAL_write_representation_summary(summary, diagnostic_dir);
  fprintf('Representation diagnostic status: %s\n', summary.status);
  if strcmp(summary.status, 'REPRESENTATION_GATE_INCOMPLETE')
    error('I4A:RepresentationDiagnosticIncomplete', '%s|%s', ...
      summary.failure_code, summary.failure_reason);
  elseif strcmp(summary.status, ...
      'REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL')
    error('I4A:RepresentationDiagnosticResourceFail', '%s|%s', ...
      summary.failure_code, summary.failure_reason);
  end
end

function [pass, reason] = LOCAL_representation_completion_gate( ...
    spec, diagnostic_dir, summary, mesh_rows, seam_rows, bulk_artifacts, ...
    operator_ledger, resource_rows, probe_rows, partition_rows, ...
    rewrite_rows, forecast_rows, padding_rows, progress_rows)
  pass = false;
  reason = '';
  try
    LOCAL_assert_scalar_rows(resource_rows, 17, ...
      'representation-resource.csv');
    LOCAL_assert_scalar_rows(probe_rows, 16, ...
      'representation-probe-costs.csv');
    LOCAL_assert_scalar_rows(partition_rows, 7, ...
      'representation-partition-bounds.csv');
    LOCAL_assert_scalar_rows(rewrite_rows, 11, ...
      'representation-rewrite-benchmark.csv');
    LOCAL_assert_scalar_rows(forecast_rows, 27, ...
      'representation-forecast.csv');
    if ~isequal(size(padding_rows), [spec.operator_row_upper_count, 36])
      error('I4A:RepresentationEvidence', ...
        'Prepared padding container has the wrong dimensions.');
    end
    LOCAL_assert_operator_rows(padding_rows, LOCAL_operator_header());
    LOCAL_validate_padding_contract(padding_rows, spec);
    operator_payload = LOCAL_prepare_operator_payload(operator_ledger);
  catch caught
    reason = sprintf('Completion schema gate failed: %s', caught.message);
    return;
  end
  primary_pairs_valid = true;
  for pair_index = 1:3
    row_indices = (2 * pair_index - 1):(2 * pair_index);
    primary_pairs_valid = primary_pairs_valid && ...
      strcmp(operator_ledger.rows{row_indices(1), 9}, 'reduced-stiffness') && ...
      strcmp(operator_ledger.rows{row_indices(2), 9}, 'reduced-mass') && ...
      strcmp(operator_ledger.rows{row_indices(1), 7}, ...
      operator_ledger.rows{row_indices(2), 7}) && ...
      isempty(operator_ledger.rows{row_indices(1), 8}) && ...
      isempty(operator_ledger.rows{row_indices(2), 8});
  end
  required_names = {'mesh-ledger.csv', 'seam-checks.csv', ...
    'bulk-bands.csv', 'bulk-gaps.csv', 'operator-representation.csv', ...
    'operator-representation.mat', 'progress.csv', ...
    'representation-resource.csv', 'representation-probe-costs.csv', ...
    'representation-partition-bounds.csv', ...
    'representation-rewrite-benchmark.csv', 'representation-forecast.csv'};
  required_present = true;
  for name_index = 1:numel(required_names)
    final_path = fullfile(diagnostic_dir, required_names{name_index});
    required_present = required_present && exist(final_path, 'file') == 2 && ...
      exist([final_path '.partial'], 'file') ~= 2;
  end
  forbidden_names = {'reference-collection.mat', 'fields.mat', ...
    'spectrum-inventory.csv'};
  forbidden_absent = true;
  for name_index = 1:numel(forbidden_names)
    forbidden_absent = forbidden_absent && ...
      exist(fullfile(diagnostic_dir, forbidden_names{name_index}), ...
      'file') ~= 2;
  end
  no_partial_files = isempty(dir(fullfile(diagnostic_dir, '*.partial')));
  operator_mirror_pass = operator_payload.column_count == 36 && ...
    operator_payload.row_count == 6 && ...
    isequal(operator_payload.header, LOCAL_operator_header()) && ...
    isequal(operator_payload.rows, operator_ledger.rows) && ...
    numel(operator_payload.primary_contract_inventory) == 3 && ...
    isempty(operator_payload.derived_parent_inventory) && ...
    operator_payload.completed_checkpoint_count == 4 && ...
    isempty(operator_payload.first_failure.code) && primary_pairs_valid;
  exact_counts = size(mesh_rows, 1) == 2 && size(seam_rows, 1) == 3 && ...
    size(operator_ledger.rows, 1) == 6 && size(resource_rows, 2) == 17 && ...
    size(probe_rows, 1) == 294 && size(partition_rows, 1) == 8 && ...
    size(rewrite_rows, 1) == 261 && isequal(size(forecast_rows), [1, 27]) && ...
    isequal(size(padding_rows), [10414, 36]) && ~isempty(progress_rows);
  isolation_pass = isempty(bulk_artifacts.bulk_rows) && ...
    isempty(bulk_artifacts.bulk_gap_rows) && ...
    summary.completed_eigensolves == 0 && ~summary.reference_exported && ...
    forbidden_absent;
  pass = required_present && no_partial_files && operator_mirror_pass && ...
    exact_counts && isolation_pass;
  if ~pass
    reason = ['Exact pending-summary gate failed: required/schema/count/' ...
      'inventory/header-only/isolation/no-partial evidence is incomplete.'];
  end
end

function summary = LOCAL_initial_representation_summary(spec, diagnostic_id)
  summary = struct();
  summary.diagnostic_id = diagnostic_id;
  summary.status = 'RUNNING';
  summary.input_kind = 'SOURCE_REBUILD_CURRENT_REPRESENTATION_SPEC_V2';
  if strcmp(diagnostic_id, 'representation-gate-003')
    summary.expected_dispatch = ...
      'run_i4_1a(''representation-gate-003'',''representation-diagnostic'')';
  elseif strcmp(diagnostic_id, 'representation-gate-002')
    summary.expected_dispatch = ...
      'run_i4_1a(''representation-gate-002'',''representation-diagnostic'')';
  else
    summary.expected_dispatch = ...
      'run_i4_1a(''representation-gate-001'',''representation-diagnostic'')';
  end
  summary.completed_eigensolves = 0;
  summary.reference_exported = false;
  summary.operator_schema_version = spec.operator_schema_version;
  summary.primary_rows = 0;
  summary.derived_row_upper_count = 10176;
  summary.rewrite_checkpoint_upper_count = 261;
  summary.correctness_pass = false;
  summary.internal_benchmark_complete = false;
  summary.internal_forecast_seconds = NaN;
  summary.internal_array_peak_bytes = NaN;
  summary.elapsed_seconds = NaN;
  summary.failure_code = '';
  summary.failure_reason = '';
  summary.claim_boundary = ...
    'ZERO_EIGENSOLVE_REPRESENTATION_AND_RESOURCE_EVIDENCE_ONLY';
  summary.external_resource_review_status = ...
    'PENDING_SAME_SKEPTIC_POST_EXIT_REVIEW';
end

function LOCAL_write_representation_terminal_stub( ...
    diagnostic_id, diagnostic_dir, diagnostic_clock, code, reason)
  spec = LOCAL_spec();
  summary = LOCAL_initial_representation_summary(spec, diagnostic_id);
  summary.status = 'REPRESENTATION_GATE_INCOMPLETE';
  summary.elapsed_seconds = toc(diagnostic_clock);
  summary.failure_code = code;
  summary.failure_reason = reason;
  LOCAL_write_representation_summary(summary, diagnostic_dir);
end

function rows = LOCAL_representation_progress( ...
    rows, output_dir, diagnostic_clock, stage, status)
  rows(end + 1, :) = {size(rows, 1) + 1, stage, status, ...
    toc(diagnostic_clock)}; %#ok<AGROW>
  LOCAL_write_csv(fullfile(output_dir, 'progress.csv'), ...
    {'sequence', 'stage', 'status', 'elapsed_seconds'}, rows);
end

function LOCAL_probe_primary_raw(reduced)
  LOCAL_raw_operator_diagnostics(reduced.stiffness);
  LOCAL_raw_operator_diagnostics(reduced.mass);
end

function LOCAL_probe_primary_canonical(reduced)
  stiffness = LOCAL_canonical_hermitian(reduced.stiffness);
  mass = LOCAL_canonical_hermitian(reduced.mass);
  stiffness_delta = norm(stiffness - reduced.stiffness, 1); %#ok<NASGU>
  mass_delta = norm(mass - reduced.mass, 1); %#ok<NASGU>
  LOCAL_diagonal_diagnostics(stiffness);
  LOCAL_diagonal_diagnostics(mass);
  invalid = any(~isfinite(nonzeros(stiffness))) || ...
    any(~isfinite(nonzeros(mass))) || ...
    ~isequal(stiffness, stiffness') || ~isequal(mass, mass') || ...
    norm(stiffness - stiffness', 1) ~= 0 || ...
    norm(mass - mass', 1) ~= 0;
  if invalid
    error('I4A:RepresentationProbe', ...
      'Primary canonical construction is not exactly Hermitian.');
  end
end

function LOCAL_probe_primary_factor(canonical_mass)
  [~, factorization_flag] = chol(canonical_mass);
  if factorization_flag ~= 0
    error('I4A:RepresentationProbe', ...
      'Canonical mass factorization probe failed.');
  end
end

function initial_reduced = LOCAL_deterministic_probe_basis( ...
    mesh, operator_pair, width)
  master_rows = accumarray(mesh.periodic.master_index, ...
    (1:size(mesh.points, 1)).', [], @min);
  coordinates = mesh.points(master_rows, :);
  reduced_dof = size(operator_pair.mass, 1);
  if size(coordinates, 1) ~= reduced_dof || width > reduced_dof
    error('I4A:RepresentationProbe', ...
      'Deterministic probe basis has incompatible dimensions.');
  end
  source = zeros(reduced_dof, width);
  for column_index = 1:width
    source(:, column_index) = ...
      exp(1i * ((0.173 + 0.019 * column_index) * coordinates(:, 1) + ...
      (0.257 + 0.023 * column_index) * coordinates(:, 2))) + ...
      (0.31 + 0.001 * column_index) * cos( ...
      (0.491 + 0.031 * column_index) * coordinates(:, 1) - ...
      (0.337 + 0.029 * column_index) * coordinates(:, 2));
  end
  [initial_reduced, factor] = qr(source, 0);
  if any(~isfinite(initial_reduced), 'all') || ...
      any(abs(diag(factor)) <= eps(max(1, norm(source, 2))))
    error('I4A:RepresentationProbe', ...
      'Deterministic analytic probe basis is rank deficient.');
  end
end

function [normalized_reduced, normalized_full, array_bytes] = ...
    LOCAL_probe_global_path(spec, operator_pair, initial_reduced)
  raw_gram = initial_reduced' * operator_pair.mass * initial_reduced;
  [evaluation, canonical_gram, normalizer] = ...
    LOCAL_evaluate_canonical_object(spec, raw_gram, 'chol');
  if ~evaluation.pass
    error('I4A:RepresentationProbe', ...
      'Global probe canonical Gram gate failed: %s', ...
      evaluation.failure_reason);
  end
  normalized_reduced = initial_reduced / normalizer;
  normalized_full = operator_pair.prolongation * normalized_reduced;
  mass_defect = norm(normalized_reduced' * operator_pair.mass * ...
    normalized_reduced - eye(size(initial_reduced, 2)), 2);
  synchronization_defect = norm(normalized_full - ...
    operator_pair.prolongation * normalized_reduced, 2);
  if mass_defect > spec.orthogonality_tolerance || ...
      synchronization_defect > 1e-12 * max(1, norm(normalized_full, 2))
    error('I4A:RepresentationProbe', ...
      'Global probe normalization or reduced/full synchronization failed.');
  end
  array_bytes = LOCAL_value_bytes(raw_gram) + ...
    LOCAL_value_bytes(canonical_gram) + LOCAL_value_bytes(normalizer) + ...
    LOCAL_value_bytes(normalized_reduced) + ...
    LOCAL_value_bytes(normalized_full);
end

function array_bytes = LOCAL_probe_restricted_path( ...
    spec, subspace, restricted_mass)
  raw_gram = subspace' * restricted_mass * subspace;
  [evaluation, canonical_gram, ~] = ...
    LOCAL_evaluate_canonical_object(spec, raw_gram, 'none');
  if ~evaluation.pass
    error('I4A:RepresentationProbe', ...
      'Restricted Gram representation gate failed: %s', ...
      evaluation.failure_reason);
  end
  values = eig(canonical_gram);
  if any(~isfinite(values))
    error('I4A:RepresentationProbe', ...
      'Restricted Gram probe returned nonfinite eigenvalues.');
  end
  array_bytes = LOCAL_value_bytes(raw_gram) + ...
    LOCAL_value_bytes(canonical_gram) + LOCAL_value_bytes(values);
end

function array_bytes = LOCAL_probe_parity_path( ...
    spec, mesh, subspace, parent_contract_id, width)
  metadata = struct('stage', 'REPRESENTATION_PARITY_PROBE', ...
    'solve_id', 'representation-finest-defect-theta0', ...
    'mesh_id', mesh.id, 'phase_kind', 'defect-theta', 'phase', 0, ...
    'parent_operator_contract_id', parent_contract_id);
  context_key = sprintf('width-%d', width);
  [evaluation, canonical_parity, ~, ~, prepare_bytes] = ...
    LOCAL_prepare_parity_object(spec, mesh, subspace, metadata, ...
    context_key, 'parity-probe', 'diagnostic-parity-probe');
  if ~evaluation.pass
    error('I4A:RepresentationProbe', ...
      'Parity compression representation gate failed: %s', ...
      evaluation.failure_reason);
  end
  [~, consume_bytes] = LOCAL_consume_parity_object(canonical_parity);
  array_bytes = prepare_bytes + consume_bytes;
end

function array_bytes = LOCAL_probe_common_core_path(spec, mesh, subspace)
  [samples, weights] = LOCAL_sample_subspace(spec, mesh, subspace);
  raw_gram = samples' * (weights .* samples);
  [evaluation, canonical_gram, factor] = ...
    LOCAL_evaluate_canonical_object(spec, raw_gram, 'chol');
  if ~evaluation.pass
    error('I4A:RepresentationProbe', ...
      'Common-core self-Gram representation gate failed: %s', ...
      evaluation.failure_reason);
  end
  array_bytes = LOCAL_value_bytes(samples) + LOCAL_value_bytes(weights) + ...
    LOCAL_value_bytes(raw_gram) + LOCAL_value_bytes(canonical_gram) + ...
    LOCAL_value_bytes(factor);
end

function stats = LOCAL_measure_repeated(action)
  warmup_count = 2;
  repeat_count = 5;
  for warmup_index = 1:warmup_count
    action();
  end
  repetitions = zeros(repeat_count, 1);
  for repeat_index = 1:repeat_count
    repeat_clock = tic;
    action();
    repetitions(repeat_index) = toc(repeat_clock);
  end
  if any(~isfinite(repetitions)) || any(repetitions < 0)
    error('I4A:RepresentationTiming', ...
      'Repeated timing contains a nonfinite or negative value.');
  end
  repeat_mean = mean(repetitions);
  if repeat_mean > 0
    coefficient_of_variation = std(repetitions, 0) / repeat_mean;
  else
    coefficient_of_variation = Inf;
  end
  quantization_floor = 1e-4;
  conservative_seconds = max(quantization_floor, ...
    quantization_floor * ceil(max(repetitions) / quantization_floor));
  stats = struct('warmup_count', warmup_count, ...
    'repeat_count', repeat_count, 'repeat_min_seconds', min(repetitions), ...
    'repeat_mean_seconds', repeat_mean, ...
    'repeat_max_seconds', max(repetitions), ...
    'coefficient_of_variation', coefficient_of_variation, ...
    'quantization_floor_seconds', quantization_floor, ...
    'conservative_seconds', conservative_seconds, ...
    'gate_pass', isfinite(coefficient_of_variation) && ...
    coefficient_of_variation <= 0.25);
end

function row = LOCAL_probe_cost_row(diagnostic_id, sample_id, path, width, ...
    contract_id, parent_contract_id, stats)
  if stats.gate_pass
    failure_code = '';
    failure_reason = '';
  else
    if strcmp(diagnostic_id, 'representation-gate-003')
      failure_code = 'ADVISORY_TIMING_VARIABILITY';
      failure_reason = [ ...
        'OBSERVATION_ONLY_NOT_EXECUTION_FAILURE;' ...
        'coefficient_of_variation_exceeds_0p25=true'];
    else
      failure_code = 'RESOURCE_BUDGET_UNAVAILABLE';
      failure_reason = 'Timing coefficient of variation exceeds 0.25.';
    end
  end
  row = {sample_id, path, width, contract_id, parent_contract_id, ...
    stats.warmup_count, stats.repeat_count, stats.repeat_min_seconds, ...
    stats.repeat_mean_seconds, stats.repeat_max_seconds, ...
    stats.coefficient_of_variation, stats.quantization_floor_seconds, ...
    stats.conservative_seconds, stats.gate_pass, failure_code, ...
    failure_reason};
end

function [probe_rows, resource_rows, costs, spreads] = ...
    LOCAL_record_width_probe(diagnostic_id, probe_rows, resource_rows, ...
    costs, spreads, path_index, width, path, contract_id, ...
    parent_contract_id, stats, array_bytes, mesh_id, phase, phase_kind)
  probe_rows(end + 1, :) = LOCAL_probe_cost_row( ...
    diagnostic_id, 'finest-defect', path, width, contract_id, ...
    parent_contract_id, stats);
  resource_rows(end + 1, :) = LOCAL_representation_resource_row( ...
    diagnostic_id, 'finest-defect', mesh_id, phase_kind, phase, ...
    [path '-probe'], width, [], [], stats.conservative_seconds, ...
    0, array_bytes, array_bytes, 0, width, 'formal-partition-proxy', ...
    'full-height width-indexed representation path');
  costs(path_index, width) = stats.conservative_seconds;
  spreads(path_index, width) = ...
    stats.repeat_max_seconds - stats.repeat_min_seconds;
end

function row = LOCAL_representation_resource_row(diagnostic_id, sample_id, ...
    mesh_id, phase_kind, phase, component, width, row_count, column_count, ...
    elapsed_seconds, bytes_before, bytes_peak, bytes_increment, ...
    solve_count, nev, partition_role, notes)
  row = {diagnostic_id, sample_id, mesh_id, phase_kind, phase, ...
    component, width, row_count, column_count, elapsed_seconds, ...
    bytes_before, bytes_peak, bytes_increment, solve_count, nev, ...
    partition_role, notes};
end

function bytes = LOCAL_value_bytes(value)
  information = whos('value');
  bytes = information.bytes;
end

function text_value = LOCAL_boolean_text(value)
  if value
    text_value = 'true';
  else
    text_value = 'false';
  end
end

function [stats, rows, row_bytes] = LOCAL_measure_row_preparation(spec)
  for warmup_index = 1:2
    LOCAL_prepare_padding_rows(spec);
  end
  repetitions = zeros(5, 1);
  rows = cell(0, 36);
  for repeat_index = 1:5
    repeat_clock = tic;
    rows = LOCAL_prepare_padding_rows(spec);
    repetitions(repeat_index) = toc(repeat_clock);
  end
  if any(~isfinite(repetitions)) || any(repetitions < 0)
    error('I4A:RepresentationBenchmark', ...
      'Row-preparation timing is nonfinite or negative.');
  end
  repeat_mean = mean(repetitions);
  if repeat_mean > 0
    coefficient_of_variation = std(repetitions, 0) / repeat_mean;
  else
    coefficient_of_variation = Inf;
  end
  quantization_floor = 1e-4;
  stats = struct('warmup_count', 2, 'repeat_count', 5, ...
    'repeat_min_seconds', min(repetitions), ...
    'repeat_mean_seconds', repeat_mean, ...
    'repeat_max_seconds', max(repetitions), ...
    'coefficient_of_variation', coefficient_of_variation, ...
    'quantization_floor_seconds', quantization_floor, ...
    'conservative_seconds', max(quantization_floor, ...
    quantization_floor * ceil(max(repetitions) / quantization_floor)), ...
    'gate_pass', isfinite(coefficient_of_variation) && ...
    coefficient_of_variation <= 0.25);
  row_bytes = LOCAL_value_bytes(rows);
end

function rows = LOCAL_prepare_padding_rows(spec)
  rows = LOCAL_build_padding_rows(spec);
  if size(rows, 1) ~= spec.operator_row_upper_count || size(rows, 2) ~= 36
    error('I4A:RepresentationBenchmark', ...
      'Row-preparation benchmark did not form exactly 10414-by-36 cells.');
  end
  LOCAL_assert_operator_rows(rows, LOCAL_operator_header());
  LOCAL_validate_padding_contract(rows, spec);
end

function LOCAL_validate_padding_contract(rows, spec)
  primary_row_count = 2 * spec.planned_solves;
  derived_start = primary_row_count + 1;
  expected_primary_objects = repmat( ...
    {'reduced-stiffness'; 'reduced-mass'}, spec.planned_solves, 1);
  primary_valid = primary_row_count == 238 && ...
    all(cellfun(@isempty, rows(1:primary_row_count, 8))) && ...
    isequal(rows(1:primary_row_count, 9), expected_primary_objects) && ...
    all(startsWith(rows(1:primary_row_count, 7), 'OP2|'));
  derived_valid = size(rows, 1) - primary_row_count == 10176 && ...
    all(~cellfun(@isempty, rows(derived_start:end, 8))) && ...
    all(startsWith(rows(derived_start:end, 7), 'DRV2|')) && ...
    all(startsWith(rows(derived_start:end, 8), 'OP2|'));
  if ~primary_valid || ~derived_valid
    error('I4A:RepresentationBenchmark', ...
      'Padding rows violate the frozen 238-primary/10176-derived contract.');
  end
end

function rows = LOCAL_build_padding_rows(spec)
  primary_row_count = 2 * spec.planned_solves;
  derived_row_count = spec.operator_row_upper_count - primary_row_count;
  if primary_row_count ~= 238 || derived_row_count ~= 10176
    error('I4A:RepresentationBenchmark', ...
      'Frozen primary/derived padding counts are inconsistent.');
  end
  rows = cell(spec.operator_row_upper_count, 36);
  for row_index = 1:spec.operator_row_upper_count
    if row_index <= primary_row_count
      pair_index = ceil(row_index / 2);
      contract_id = sprintf('OP2|BENCHMARK|padding-mesh-%03d|bulk-alpha|%s', ...
        pair_index, lower(num2hex(double(pair_index))));
      parent_contract_id = '';
      phase_kind = 'bulk-alpha';
      if mod(row_index, 2) == 1
        object_id = 'reduced-stiffness';
        factorization_kind = 'none';
        factorization_flag = [];
        consumer_contract = 'eigs|residual';
      else
        object_id = 'reduced-mass';
        factorization_kind = 'chol';
        factorization_flag = 0;
        consumer_contract = ...
          'chol|eigs|normalization|orthogonality|residual';
      end
      solve_id = sprintf('padding-primary-%03d', pair_index);
    else
      derived_index = row_index - primary_row_count;
      pair_index = mod(derived_index - 1, spec.planned_solves) + 1;
      parent_contract_id = sprintf( ...
        'OP2|BENCHMARK|padding-mesh-%03d|defect-theta|%s', ...
        pair_index, lower(num2hex(double(pair_index))));
      object_id = 'BENCHMARK_PADDING_NO_SCIENTIFIC_OBJECT';
      contract_id = LOCAL_derived_contract_id(parent_contract_id, ...
        object_id, sprintf('slot-%05d', derived_index));
      factorization_kind = 'none';
      factorization_flag = [];
      consumer_contract = 'BENCHMARK_PADDING_NO_SCIENTIFIC_OBJECT';
      solve_id = sprintf('padding-derived-%05d', derived_index);
      phase_kind = 'defect-theta';
    end
    mesh_id = sprintf('padding-mesh-%03d', pair_index);
    phase = double(pair_index);
    rows(row_index, :) = {row_index, 'BENCHMARK_PADDING', solve_id, ...
      mesh_id, phase_kind, phase, contract_id, ...
      parent_contract_id, object_id, ...
      'BENCHMARK_PADDING_NO_SCIENTIFIC_OBJECT', 'EVALUATED_PASS', ...
      1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, true, 1, 1, 0, 1, 1, 0, ...
      factorization_kind, factorization_flag, consumer_contract, ...
      true, '', ''};
  end
end

function [rows, total_seconds, peak_bytes] = ...
    LOCAL_benchmark_growing_writer(diagnostic_id, spec, padding_rows, ...
    temporary_work_dir)
  benchmark_dir = fullfile(temporary_work_dir, 'representation-rewrite');
  [made_benchmark, message] = mkdir(benchmark_dir);
  if ~made_benchmark
    error('I4A:RepresentationBenchmark', ...
      'Cannot create rewrite benchmark workspace: %s', message);
  end
  benchmark_ledger = LOCAL_initial_operator_ledger( ...
    spec, benchmark_dir, 'BENCHMARK_PADDING');
  LOCAL_write_operator_representation(benchmark_ledger);
  delete(fullfile(benchmark_dir, 'operator-representation.mat'));
  delete(fullfile(benchmark_dir, 'operator-representation.csv'));

  additions = [0, 2 * ones(1, 119), ...
    LOCAL_distribute_rows(1920, 47), LOCAL_distribute_rows(6336, 47), ...
    LOCAL_distribute_rows(1920, 47)];
  kinds = [{'header'}, repmat({'primary-pair'}, 1, 119), ...
    repmat({'global-normalization'}, 1, 47), ...
    repmat({'restricted-parity'}, 1, 47), ...
    repmat({'common-core'}, 1, 47)];
  if numel(additions) ~= spec.operator_checkpoint_upper_count || ...
      sum(additions) ~= spec.operator_row_upper_count
    error('I4A:RepresentationBenchmark', ...
      'Frozen 10414-row/261-checkpoint schedule is inconsistent.');
  end
  rows = cell(numel(additions), 11);
  cumulative_rows = 0;
  cumulative_seconds = 0;
  peak_bytes = LOCAL_value_bytes(padding_rows);
  for checkpoint_index = 1:numel(additions)
    rows_before = cumulative_rows;
    cumulative_rows = cumulative_rows + additions(checkpoint_index);
    benchmark_ledger.rows = padding_rows(1:cumulative_rows, :);
    benchmark_ledger.completed_checkpoint_count = checkpoint_index;
    timings = LOCAL_write_operator_representation(benchmark_ledger);
    mat_path = fullfile(benchmark_dir, 'operator-representation.mat');
    csv_path = fullfile(benchmark_dir, 'operator-representation.csv');
    mat_seconds = timings.mat_seconds;
    csv_seconds = timings.csv_seconds;
    checkpoint_seconds = timings.total_seconds;
    cumulative_seconds = cumulative_seconds + checkpoint_seconds;
    mat_record = dir(mat_path);
    csv_record = dir(csv_path);
    rows(checkpoint_index, :) = {checkpoint_index, ...
      kinds{checkpoint_index}, rows_before, additions(checkpoint_index), ...
      cumulative_rows, mat_seconds, csv_seconds, checkpoint_seconds, ...
      mat_record.bytes, csv_record.bytes, cumulative_seconds};
    peak_bytes = max(peak_bytes, LOCAL_value_bytes(benchmark_ledger.rows) + ...
      mat_record.bytes + csv_record.bytes);
  end
  LOCAL_validate_rewrite_rows(diagnostic_id, rows, additions, spec);
  total_seconds = cumulative_seconds;
  delete(fullfile(benchmark_dir, 'operator-representation.mat'));
  delete(fullfile(benchmark_dir, 'operator-representation.csv'));
end

function LOCAL_validate_rewrite_rows(diagnostic_id, rows, additions, spec)
  expected_checkpoint = (1:spec.operator_checkpoint_upper_count).';
  expected_after = cumsum(additions(:));
  expected_before = [0; expected_after(1:(end - 1))];
  timing_values = cell2mat(rows(:, 6:8));
  byte_values = cell2mat(rows(:, 9:10));
  cumulative_values = cell2mat(rows(:, 11));
  exact_schedule = isequal(cell2mat(rows(:, 1)), expected_checkpoint) && ...
    isequal(cell2mat(rows(:, 3)), expected_before) && ...
    isequal(cell2mat(rows(:, 4)), additions(:)) && ...
    isequal(cell2mat(rows(:, 5)), expected_after) && ...
    expected_after(end) == spec.operator_row_upper_count;
  finite_nonnegative = all(isfinite(timing_values), 'all') && ...
    all(timing_values >= 0, 'all') && all(isfinite(byte_values), 'all') && ...
    all(byte_values >= 0, 'all') && all(isfinite(cumulative_values)) && ...
    all(cumulative_values >= 0) && all(diff(cumulative_values) >= 0);
  timing_consistency = all(timing_values(:, 3) + eps >= ...
    timing_values(:, 1) + timing_values(:, 2)) && ...
    all(abs(cumulative_values - cumsum(timing_values(:, 3))) <= ...
    16 * eps(max(1, cumulative_values)));
  if strcmp(diagnostic_id, 'representation-gate-003')
    rewrite_pass = exact_schedule && finite_nonnegative;
  else
    rewrite_pass = exact_schedule && finite_nonnegative && timing_consistency;
  end
  if ~rewrite_pass
    error('I4A:RepresentationBenchmark', ...
      'Growing rewrite timing or monotone checkpoint gate failed.');
  end
end

function additions = LOCAL_distribute_rows(total_rows, batch_count)
  additions = floor(total_rows / batch_count) * ones(1, batch_count);
  additions(1:mod(total_rows, batch_count)) = ...
    additions(1:mod(total_rows, batch_count)) + 1;
end

function [rows, costs, spreads] = ...
    LOCAL_partition_evidence(path_costs, path_spreads)
  path_names = {'global', 'restricted', 'endpoint-parity', 'common-core'};
  root_counts = [40, 48];
  solve_counts = [42, 5; 42, 5; 12, 2; 42, 5];
  rows = cell(0, 7);
  costs = zeros(4, 2);
  spreads = zeros(4, 2);
  for path_index = 1:4
    for root_index = 1:2
      root_count = root_counts(root_index);
      [cost, partition] = LOCAL_partition_bound( ...
        path_costs(path_index, :), root_count);
      [spread, ~] = LOCAL_partition_bound( ...
        path_spreads(path_index, :), root_count);
      costs(path_index, root_index) = cost;
      spreads(path_index, root_index) = spread;
      solve_count = solve_counts(path_index, root_index);
      rows(end + 1, :) = {path_names{path_index}, root_count, ...
        LOCAL_integer_sequence(partition), numel(partition), cost, ...
        solve_count, solve_count * cost}; %#ok<AGROW>
    end
  end
end

function [bound, partition] = LOCAL_partition_bound(costs, root_count)
  dynamic_cost = -inf(1, root_count + 1);
  last_width = zeros(1, root_count + 1);
  dynamic_cost(1) = 0;
  for count = 1:root_count
    for width = 1:min(48, count)
      candidate = costs(width) + dynamic_cost(count - width + 1);
      if candidate > dynamic_cost(count + 1)
        dynamic_cost(count + 1) = candidate;
        last_width(count + 1) = width;
      end
    end
  end
  bound = dynamic_cost(root_count + 1);
  partition = zeros(0, 1);
  remaining = root_count;
  while remaining > 0
    width = last_width(remaining + 1);
    if width < 1
      error('I4A:RepresentationBenchmark', ...
        'Dynamic-programming partition reconstruction failed.');
    end
    partition(end + 1, 1) = width; %#ok<AGROW>
    remaining = remaining - width;
  end
end

function LOCAL_write_representation_ledgers(output_dir, resource_rows, ...
    probe_rows, partition_rows, rewrite_rows, forecast_rows)
  LOCAL_assert_scalar_rows(resource_rows, 17, 'representation-resource.csv');
  LOCAL_assert_scalar_rows(probe_rows, 16, 'representation-probe-costs.csv');
  LOCAL_assert_scalar_rows(partition_rows, 7, ...
    'representation-partition-bounds.csv');
  LOCAL_assert_scalar_rows(rewrite_rows, 11, ...
    'representation-rewrite-benchmark.csv');
  LOCAL_assert_scalar_rows(forecast_rows, 27, 'representation-forecast.csv');
  LOCAL_write_csv(fullfile(output_dir, 'representation-resource.csv'), ...
    {'diagnostic_id', 'sample_id', 'mesh_id', 'phase_kind', 'phase', ...
    'component', 'width', 'row_count', 'column_count', 'elapsed_seconds', ...
    'array_bytes_before', 'array_bytes_peak', 'array_increment_bytes', ...
    'solve_count', 'nev', 'partition_role', 'notes'}, resource_rows);
  LOCAL_write_csv(fullfile(output_dir, 'representation-probe-costs.csv'), ...
    {'sample_id', 'path', 'width', 'operator_contract_id', ...
    'parent_operator_contract_id', 'warmup_count', 'repeat_count', ...
    'repeat_min_seconds', 'repeat_mean_seconds', 'repeat_max_seconds', ...
    'coefficient_of_variation', 'quantization_floor_seconds', ...
    'conservative_seconds', 'gate_pass', 'failure_code', ...
    'failure_reason'}, probe_rows);
  LOCAL_write_csv(fullfile(output_dir, ...
    'representation-partition-bounds.csv'), ...
    {'path', 'nev', 'maximizing_partition', 'cluster_count', ...
    'bound_seconds', 'solve_count', 'total_seconds'}, partition_rows);
  LOCAL_write_csv(fullfile(output_dir, ...
    'representation-rewrite-benchmark.csv'), ...
    {'checkpoint_index', 'checkpoint_kind', 'rows_before', 'rows_added', ...
    'rows_after', 'mat_seconds', 'csv_seconds', 'total_seconds', ...
    'mat_bytes', 'csv_bytes', 'cumulative_seconds'}, rewrite_rows);
  LOCAL_write_csv(fullfile(output_dir, 'representation-forecast.csv'), ...
    {'baseline_seconds', 'largest_bulk_primary_count', ...
    'largest_bulk_primary_seconds', 'finest_defect_primary_count', ...
    'finest_defect_primary_seconds', 'global_40_total_seconds', ...
    'global_48_total_seconds', 'restricted_40_total_seconds', ...
    'restricted_48_total_seconds', 'parity_40_total_seconds', ...
    'parity_48_total_seconds', 'common_core_40_total_seconds', ...
    'common_core_48_total_seconds', 'row_preparation_seconds', ...
    'rewrite_seconds', 'additive_seconds', 'forecast_seconds', ...
    'forecast_minutes_unrounded', 'forecast_strictly_below_30', ...
    'baseline_peak_bytes', 'incremental_array_peak_bytes', ...
    'forecast_peak_bytes', 'forecast_peak_gib', ...
    'forecast_at_most_1p5_gib', 'internal_gate_pass', ...
    'failure_code', 'failure_reason'}, forecast_rows);
end

function LOCAL_assert_scalar_rows(rows, expected_width, ledger_name)
  if ~iscell(rows) || size(rows, 2) ~= expected_width
    error('I4A:RepresentationEvidence', ...
      '%s does not have its frozen schema width.', ledger_name);
  end
  for row_index = 1:size(rows, 1)
    for column_index = 1:size(rows, 2)
      value = rows{row_index, column_index};
      valid = isempty(value) || ischar(value) || ...
        ((isnumeric(value) || islogical(value)) && isscalar(value) && ...
        ~issparse(value)) || (isstring(value) && isscalar(value));
      if ~valid
        error('I4A:RepresentationEvidence', ...
          '%s contains a nonscalar or unsupported cell.', ledger_name);
      end
    end
  end
end

function LOCAL_write_representation_summary(summary, output_dir)
  row = {summary.diagnostic_id, summary.status, summary.input_kind, ...
    summary.expected_dispatch, summary.completed_eigensolves, ...
    summary.reference_exported, summary.operator_schema_version, ...
    summary.primary_rows, summary.derived_row_upper_count, ...
    summary.rewrite_checkpoint_upper_count, summary.correctness_pass, ...
    summary.internal_benchmark_complete, summary.internal_forecast_seconds, ...
    summary.internal_array_peak_bytes, summary.elapsed_seconds, ...
    summary.failure_code, summary.failure_reason, summary.claim_boundary, ...
    summary.external_resource_review_status};
  LOCAL_atomic_save(fullfile(output_dir, 'diagnostic-summary.mat'), summary);
  LOCAL_write_csv(fullfile(output_dir, 'diagnostic-summary.csv'), ...
    {'diagnostic_id', 'status', 'input_kind', 'expected_dispatch', ...
    'completed_eigensolves', 'reference_exported', ...
    'operator_schema_version', 'primary_rows', ...
    'derived_row_upper_count', 'rewrite_checkpoint_upper_count', ...
    'correctness_pass', 'internal_benchmark_complete', ...
    'internal_forecast_seconds', 'internal_array_peak_bytes', ...
    'elapsed_seconds', 'failure_code', 'failure_reason', ...
    'claim_boundary', 'external_resource_review_status'}, row);
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
  spec.canonical_preflight_floor_gib = 1.3;
  spec.operator_schema_version = 'i4a-operator-representation-v2-36';
  spec.operator_row_upper_count = 10414;
  spec.operator_checkpoint_upper_count = 261;
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
    'repair_unresolved_triangle_count', 'connectivity_area_defect', ...
    'unpaired_constraint_count', 'unpaired_triangle_count', ...
    'material_pair_mismatch_count', 'duplicate_triangle_count', ...
    'invalid_edge_incidence_count', 'nonmanifold_edge_count', ...
    'boundary_edge_count', 'expected_boundary_edge_count', ...
    'interior_free_boundary_count', 'missing_outer_boundary_count', ...
    'nonincident_edge_intersection_count', 'triangle_component_count', ...
    'planar_complex_pass', ...
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
  mesh_rows = cell(0, 36);
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
    mesh_rows{end, 34} = 'MESH_AND_SEAM_COMPLETE';
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
  [reflection_index, reflection_coordinate_defect] = ...
    LOCAL_reflection_map(points, spec.coordinate_tolerance);
  if reflection_coordinate_defect > spec.coordinate_tolerance
    failure_reason = sprintf( ...
      '%s reflection node tie-resolution prerequisite failed.', mesh_spec.id);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'REFLECTION_NODE_TIE_RESOLUTION', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end
  unpaired_constraint_count = LOCAL_unpaired_constraint_count( ...
    constraints, reflection_index);
  mesh_diagnostic.unpaired_constraint_count = unpaired_constraint_count;
  if unpaired_constraint_count > 0
    failure_reason = sprintf( ...
      '%s has %d constraints without a reflected partner.', ...
      mesh_spec.id, unpaired_constraint_count);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'CONSTRAINT_REFLECTION_CLOSURE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end
  [triangles, repair_diagnostic] = LOCAL_reflection_closed_triangles( ...
    spec, mesh_spec.id, points, triangles, reflection_index);
  mesh_diagnostic.triangles = size(triangles, 1);
  mesh_diagnostic.repair_unresolved_triangle_count = ...
    repair_diagnostic.unresolved_triangle_count;
  mesh_diagnostic.connectivity_area_defect = ...
    repair_diagnostic.area_defect;
  mesh_diagnostic.duplicate_triangle_count = ...
    repair_diagnostic.duplicate_triangle_count;
  if ~repair_diagnostic.pass
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'CONNECTIVITY_TIE_RESOLUTION', ...
      'MESH_QUALITY_UNRESOLVED', repair_diagnostic.reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', repair_diagnostic.reason);
  end
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

  planar_diagnostic = LOCAL_planar_complex_diagnostics( ...
    points, triangles, constraints, xmin, xmax, ymin, ymax, ...
    spec.constraint_tolerance);
  constraint_missing_count = planar_diagnostic.constraint_missing_count;
  mesh_diagnostic.constraint_missing_count = constraint_missing_count;
  mesh_diagnostic.duplicate_triangle_count = ...
    planar_diagnostic.duplicate_triangle_count;
  mesh_diagnostic.invalid_edge_incidence_count = ...
    planar_diagnostic.invalid_edge_incidence_count;
  mesh_diagnostic.nonmanifold_edge_count = ...
    planar_diagnostic.nonmanifold_edge_count;
  mesh_diagnostic.boundary_edge_count = ...
    planar_diagnostic.boundary_edge_count;
  mesh_diagnostic.expected_boundary_edge_count = ...
    planar_diagnostic.expected_boundary_edge_count;
  mesh_diagnostic.interior_free_boundary_count = ...
    planar_diagnostic.interior_free_boundary_count;
  mesh_diagnostic.missing_outer_boundary_count = ...
    planar_diagnostic.missing_outer_boundary_count;
  mesh_diagnostic.nonincident_edge_intersection_count = ...
    planar_diagnostic.nonincident_edge_intersection_count;
  mesh_diagnostic.triangle_component_count = ...
    planar_diagnostic.triangle_component_count;
  mesh_diagnostic.planar_complex_pass = planar_diagnostic.pass;
  if constraint_missing_count > 0
    failure_reason = sprintf('%s lost %d constrained edges.', ...
      mesh_spec.id, constraint_missing_count);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'CONSTRAINT_EDGE_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end
  if ~planar_diagnostic.pass
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'PLANAR_COMPLEX_ORACLE', ...
      'MESH_QUALITY_UNRESOLVED', planar_diagnostic.reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', planar_diagnostic.reason);
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
  [unpaired_triangle_count, material_pair_mismatch_count] = ...
    LOCAL_triangle_reflection_diagnostics( ...
    triangles, material_inside, reflection_index);
  mesh_diagnostic.unpaired_triangle_count = unpaired_triangle_count;
  mesh_diagnostic.material_pair_mismatch_count = ...
    material_pair_mismatch_count;
  if unpaired_triangle_count > 0 || material_pair_mismatch_count > 0
    failure_reason = sprintf([ ...
      '%s pre-assembly reflection closure failed: unpaired %d, ' ...
      'material mismatches %d.'], mesh_spec.id, unpaired_triangle_count, ...
      material_pair_mismatch_count);
    LOCAL_checkpoint_mesh_failure(prior_mesh_rows, prior_seam_rows, ...
      mesh_spec, mesh_diagnostic, 'PREASSEMBLY_REFLECTION_CLOSURE', ...
      'MESH_QUALITY_UNRESOLVED', failure_reason, output_dir);
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', failure_reason);
  end
  [stiffness_full, mass_full, mass_center, mass_core, mass_tail] = ...
    LOCAL_assemble_p1(spec, mesh_spec, points, triangles, centroids, ...
    material_inside);
  mesh_diagnostic.nnz_stiffness = nnz(stiffness_full);
  mesh_diagnostic.nnz_mass = nnz(mass_full);

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
  mesh.repair_unresolved_triangle_count = ...
    mesh_diagnostic.repair_unresolved_triangle_count;
  mesh.connectivity_area_defect = mesh_diagnostic.connectivity_area_defect;
  mesh.unpaired_constraint_count = ...
    mesh_diagnostic.unpaired_constraint_count;
  mesh.unpaired_triangle_count = mesh_diagnostic.unpaired_triangle_count;
  mesh.material_pair_mismatch_count = ...
    mesh_diagnostic.material_pair_mismatch_count;
  mesh.duplicate_triangle_count = mesh_diagnostic.duplicate_triangle_count;
  mesh.invalid_edge_incidence_count = ...
    mesh_diagnostic.invalid_edge_incidence_count;
  mesh.nonmanifold_edge_count = mesh_diagnostic.nonmanifold_edge_count;
  mesh.boundary_edge_count = mesh_diagnostic.boundary_edge_count;
  mesh.expected_boundary_edge_count = ...
    mesh_diagnostic.expected_boundary_edge_count;
  mesh.interior_free_boundary_count = ...
    mesh_diagnostic.interior_free_boundary_count;
  mesh.missing_outer_boundary_count = ...
    mesh_diagnostic.missing_outer_boundary_count;
  mesh.nonincident_edge_intersection_count = ...
    mesh_diagnostic.nonincident_edge_intersection_count;
  mesh.triangle_component_count = mesh_diagnostic.triangle_component_count;
  mesh.planar_complex_pass = mesh_diagnostic.planar_complex_pass;
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
  mesh_diagnostic.repair_unresolved_triangle_count = NaN;
  mesh_diagnostic.connectivity_area_defect = NaN;
  mesh_diagnostic.unpaired_constraint_count = NaN;
  mesh_diagnostic.unpaired_triangle_count = NaN;
  mesh_diagnostic.material_pair_mismatch_count = NaN;
  mesh_diagnostic.duplicate_triangle_count = NaN;
  mesh_diagnostic.invalid_edge_incidence_count = NaN;
  mesh_diagnostic.nonmanifold_edge_count = NaN;
  mesh_diagnostic.boundary_edge_count = NaN;
  mesh_diagnostic.expected_boundary_edge_count = NaN;
  mesh_diagnostic.interior_free_boundary_count = NaN;
  mesh_diagnostic.missing_outer_boundary_count = NaN;
  mesh_diagnostic.nonincident_edge_intersection_count = NaN;
  mesh_diagnostic.triangle_component_count = NaN;
  mesh_diagnostic.planar_complex_pass = NaN;
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
    mesh_diagnostic.reflection_mass_defect, ...
    mesh_diagnostic.repair_unresolved_triangle_count, ...
    mesh_diagnostic.connectivity_area_defect, ...
    mesh_diagnostic.unpaired_constraint_count, ...
    mesh_diagnostic.unpaired_triangle_count, ...
    mesh_diagnostic.material_pair_mismatch_count, ...
    mesh_diagnostic.duplicate_triangle_count, ...
    mesh_diagnostic.invalid_edge_incidence_count, ...
    mesh_diagnostic.nonmanifold_edge_count, ...
    mesh_diagnostic.boundary_edge_count, ...
    mesh_diagnostic.expected_boundary_edge_count, ...
    mesh_diagnostic.interior_free_boundary_count, ...
    mesh_diagnostic.missing_outer_boundary_count, ...
    mesh_diagnostic.nonincident_edge_intersection_count, ...
    mesh_diagnostic.triangle_component_count, ...
    mesh_diagnostic.planar_complex_pass, reached_boundary, ...
    failure_code, failure_reason};
end

function LOCAL_checkpoint_mesh_failure(prior_mesh_rows, seam_rows, ...
    mesh_spec, mesh_diagnostic, reached_boundary, failure_code, ...
    failure_reason, output_dir)
  failure_mesh_rows = prior_mesh_rows;
  if ~isempty(failure_mesh_rows)
    failure_mesh_rows(:, 35) = {failure_code};
    failure_mesh_rows(:, 36) = {failure_reason};
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

function diagnostic = LOCAL_planar_complex_diagnostics( ...
    points, triangles, constraints, xmin, xmax, ymin, ymax, tolerance)
  canonical_triangles = sort(triangles, 2);
  duplicate_triangle_count = size(canonical_triangles, 1) - ...
    size(unique(canonical_triangles, 'rows'), 1);
  triangle_count = size(triangles, 1);
  triangle_edges = [triangles(:, [1, 2]); triangles(:, [2, 3]); ...
    triangles(:, [3, 1])];
  triangle_edges = sort(triangle_edges, 2);
  edge_triangle_index = repmat((1:triangle_count).', 3, 1);
  if isempty(triangle_edges)
    unique_edges = zeros(0, 2);
    edge_index = zeros(0, 1);
    edge_incidence = zeros(0, 1);
  else
    [unique_edges, ~, edge_index] = unique(triangle_edges, 'rows');
    edge_incidence = accumarray(edge_index, 1, ...
      [size(unique_edges, 1), 1]);
  end

  invalid_edge_incidence_count = nnz( ...
    edge_incidence ~= 1 & edge_incidence ~= 2);
  nonmanifold_edge_count = nnz(edge_incidence > 2);
  boundary_edges = unique_edges(edge_incidence == 1, :);
  expected_boundary_edges = LOCAL_outer_boundary_edges( ...
    points, xmin, xmax, ymin, ymax, tolerance);
  interior_free_boundary_count = nnz(~ismember( ...
    boundary_edges, expected_boundary_edges, 'rows'));
  missing_outer_boundary_count = nnz(~ismember( ...
    expected_boundary_edges, boundary_edges, 'rows'));
  canonical_constraints = sort(constraints, 2);
  constraint_missing_count = nnz(~ismember( ...
    canonical_constraints, unique_edges, 'rows'));
  nonincident_edge_intersection_count = ...
    LOCAL_nonincident_edge_intersection_count( ...
    points, unique_edges, tolerance);
  triangle_component_count = LOCAL_triangle_component_count( ...
    triangle_count, edge_index, edge_triangle_index);

  diagnostic = struct();
  diagnostic.duplicate_triangle_count = duplicate_triangle_count;
  diagnostic.invalid_edge_incidence_count = ...
    invalid_edge_incidence_count;
  diagnostic.nonmanifold_edge_count = nonmanifold_edge_count;
  diagnostic.boundary_edge_count = size(boundary_edges, 1);
  diagnostic.expected_boundary_edge_count = ...
    size(expected_boundary_edges, 1);
  diagnostic.interior_free_boundary_count = ...
    interior_free_boundary_count;
  diagnostic.missing_outer_boundary_count = ...
    missing_outer_boundary_count;
  diagnostic.nonincident_edge_intersection_count = ...
    nonincident_edge_intersection_count;
  diagnostic.triangle_component_count = triangle_component_count;
  diagnostic.constraint_missing_count = constraint_missing_count;
  diagnostic.pass = duplicate_triangle_count == 0 && ...
    invalid_edge_incidence_count == 0 && ...
    nonmanifold_edge_count == 0 && ...
    interior_free_boundary_count == 0 && ...
    missing_outer_boundary_count == 0 && ...
    nonincident_edge_intersection_count == 0 && ...
    triangle_component_count == 1 && constraint_missing_count == 0;

  if duplicate_triangle_count > 0
    diagnostic.reason = sprintf( ...
      'Planar complex has %d duplicate unordered triangles.', ...
      duplicate_triangle_count);
  elseif nonmanifold_edge_count > 0
    diagnostic.reason = sprintf( ...
      'Planar complex has %d edges with incidence above two.', ...
      nonmanifold_edge_count);
  elseif invalid_edge_incidence_count > 0
    diagnostic.reason = sprintf( ...
      'Planar complex has %d edges with incidence outside one or two.', ...
      invalid_edge_incidence_count);
  elseif interior_free_boundary_count > 0 || ...
      missing_outer_boundary_count > 0
    diagnostic.reason = sprintf([ ...
      'Planar boundary mismatch: %d interior free edges and ' ...
      '%d missing outer segments.'], interior_free_boundary_count, ...
      missing_outer_boundary_count);
  elseif nonincident_edge_intersection_count > 0
    diagnostic.reason = sprintf( ...
      'Planar complex has %d intersecting nonincident edge pairs.', ...
      nonincident_edge_intersection_count);
  elseif triangle_component_count ~= 1
    diagnostic.reason = sprintf( ...
      'Triangle adjacency has %d connected components, expected one.', ...
      triangle_component_count);
  elseif constraint_missing_count > 0
    diagnostic.reason = sprintf( ...
      'Planar complex lost %d frozen constraint segments.', ...
      constraint_missing_count);
  else
    diagnostic.reason = 'PASS';
  end
end

function boundary_edges = LOCAL_outer_boundary_edges( ...
    points, xmin, xmax, ymin, ymax, tolerance)
  side_definitions = {1, xmin, 2; 1, xmax, 2; ...
    2, ymin, 1; 2, ymax, 1};
  boundary_edges = zeros(0, 2);
  for side_index = 1:size(side_definitions, 1)
    fixed_coordinate = side_definitions{side_index, 1};
    fixed_value = side_definitions{side_index, 2};
    varying_coordinate = side_definitions{side_index, 3};
    side_nodes = find(abs(points(:, fixed_coordinate) - fixed_value) <= ...
      tolerance);
    [~, node_order] = sort(points(side_nodes, varying_coordinate));
    side_nodes = side_nodes(node_order);
    if numel(side_nodes) >= 2
      boundary_edges = [boundary_edges; ...
        side_nodes(1:(end - 1)), side_nodes(2:end)]; %#ok<AGROW>
    end
  end
  boundary_edges = unique(sort(boundary_edges, 2), 'rows');
end

function count = LOCAL_nonincident_edge_intersection_count( ...
    points, mesh_edges, tolerance)
  first = points(mesh_edges(:, 1), :);
  second = points(mesh_edges(:, 2), :);
  edge_box_lower = min(first, second);
  edge_box_upper = max(first, second);
  [~, sweep_edge_order] = sortrows([edge_box_lower, edge_box_upper]);
  count = 0;
  for ordered_index = 1:numel(sweep_edge_order)
    first_edge_index = sweep_edge_order(ordered_index);
    candidate_index = ordered_index + 1;
    while candidate_index <= numel(sweep_edge_order)
      second_edge_index = sweep_edge_order(candidate_index);
      if edge_box_lower(second_edge_index, 1) > ...
          edge_box_upper(first_edge_index, 1) + tolerance
        break;
      end
      first_nodes = mesh_edges(first_edge_index, :);
      second_nodes = mesh_edges(second_edge_index, :);
      shares_node = any(first_nodes(1) == second_nodes) || ...
        any(first_nodes(2) == second_nodes);
      y_boxes_overlap = edge_box_lower(second_edge_index, 2) <= ...
        edge_box_upper(first_edge_index, 2) + tolerance && ...
        edge_box_lower(first_edge_index, 2) <= ...
        edge_box_upper(second_edge_index, 2) + tolerance;
      if ~shares_node && y_boxes_overlap && LOCAL_segments_intersect( ...
          first(first_edge_index, :), second(first_edge_index, :), ...
          first(second_edge_index, :), second(second_edge_index, :), ...
          tolerance)
        count = count + 1;
      end
      candidate_index = candidate_index + 1;
    end
  end
end

function intersects = LOCAL_segments_intersect( ...
    first_start, first_end, second_start, second_end, tolerance)
  orientation_1 = LOCAL_cross_2d( ...
    first_end - first_start, second_start - first_start);
  orientation_2 = LOCAL_cross_2d( ...
    first_end - first_start, second_end - first_start);
  orientation_3 = LOCAL_cross_2d( ...
    second_end - second_start, first_start - second_start);
  orientation_4 = LOCAL_cross_2d( ...
    second_end - second_start, first_end - second_start);
  proper_crossing = ((orientation_1 > 0 && orientation_2 < 0) || ...
    (orientation_1 < 0 && orientation_2 > 0)) && ...
    ((orientation_3 > 0 && orientation_4 < 0) || ...
    (orientation_3 < 0 && orientation_4 > 0));
  touches = ...
    (abs(orientation_1) <= tolerance && LOCAL_point_on_segment( ...
    second_start, first_start, first_end, tolerance)) || ...
    (abs(orientation_2) <= tolerance && LOCAL_point_on_segment( ...
    second_end, first_start, first_end, tolerance)) || ...
    (abs(orientation_3) <= tolerance && LOCAL_point_on_segment( ...
    first_start, second_start, second_end, tolerance)) || ...
    (abs(orientation_4) <= tolerance && LOCAL_point_on_segment( ...
    first_end, second_start, second_end, tolerance));
  intersects = proper_crossing || touches;
end

function value = LOCAL_cross_2d(first, second)
  value = first(1) * second(2) - first(2) * second(1);
end

function inside = LOCAL_point_on_segment(point, first, second, tolerance)
  inside = all(point >= min(first, second) - tolerance) && ...
    all(point <= max(first, second) + tolerance);
end

function component_count = LOCAL_triangle_component_count( ...
    triangle_count, edge_index, edge_triangle_index)
  if triangle_count == 0
    component_count = 0;
    return;
  end
  [sorted_edge_index, incidence_edge_order] = sort(edge_index);
  incidence_group_start = [1; find(diff(sorted_edge_index) ~= 0) + 1];
  incidence_group_end = [incidence_group_start(2:end) - 1; ...
    numel(sorted_edge_index)];
  adjacency_start = zeros(max(0, numel(edge_index) - ...
    numel(incidence_group_start)), 1);
  adjacency_end = zeros(size(adjacency_start));
  link_count = 0;
  for group_index = 1:numel(incidence_group_start)
    group_triangles = edge_triangle_index(incidence_edge_order( ...
      incidence_group_start(group_index):incidence_group_end(group_index)));
    if numel(group_triangles) > 1
      new_links = numel(group_triangles) - 1;
      link_range = link_count + (1:new_links);
      adjacency_start(link_range) = group_triangles(1);
      adjacency_end(link_range) = group_triangles(2:end);
      link_count = link_count + new_links;
    end
  end
  adjacency_start = adjacency_start(1:link_count);
  adjacency_end = adjacency_end(1:link_count);
  adjacency = sparse([adjacency_start; adjacency_end], ...
    [adjacency_end; adjacency_start], ones(2 * link_count, 1), ...
    triangle_count, triangle_count);

  visited = false(triangle_count, 1);
  queue = zeros(triangle_count, 1);
  component_count = 0;
  for triangle_index = 1:triangle_count
    if visited(triangle_index)
      continue;
    end
    component_count = component_count + 1;
    queue_head = 1;
    queue_tail = 1;
    queue(1) = triangle_index;
    visited(triangle_index) = true;
    while queue_head <= queue_tail
      neighbors = find(adjacency(queue(queue_head), :));
      neighbors = neighbors(:);
      neighbors = neighbors(~visited(neighbors));
      if ~isempty(neighbors)
        visited(neighbors) = true;
        queue(queue_tail + (1:numel(neighbors))) = neighbors;
        queue_tail = queue_tail + numel(neighbors);
      end
      queue_head = queue_head + 1;
    end
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

%% ==================== Canonical representation evidence ====================
% Section 22 records each allowlisted Hermitian object before its first use.

function ledger = LOCAL_initial_operator_ledger(spec, output_dir, stage)
  ledger = struct();
  ledger.output_dir = output_dir;
  ledger.schema_version = spec.operator_schema_version;
  ledger.header = LOCAL_operator_header();
  ledger.rows = cell(0, numel(ledger.header));
  ledger.completed_checkpoint_count = 1;
  ledger.first_failure = struct('code', '', 'reason', '', ...
    'owner_object_id', '', 'owner_sequence', []);
  ledger.model_id = spec.model_id;
  ledger.model_digest = spec.model_digest;
  ledger.planned_solves = spec.planned_solves;
  ledger.row_upper_count = spec.operator_row_upper_count;
  ledger.checkpoint_upper_count = spec.operator_checkpoint_upper_count;
  ledger.default_stage = stage;
end

function header = LOCAL_operator_header()
  header = {'sequence', 'stage', 'solve_id', 'mesh_id', 'phase_kind', ...
    'phase', 'operator_contract_id', 'parent_operator_contract_id', ...
    'object_id', 'object_role', 'evaluation_status', 'rows', 'columns', ...
    'raw_nnz', 'canonical_nnz', 'raw_nonfinite_count', ...
    'canonical_nonfinite_count', 'raw_hermitian_defect_absolute_1', ...
    'raw_hermitian_defect_normalized_1', 'canonical_delta_absolute_1', ...
    'canonical_delta_normalized_1', ...
    'canonical_hermitian_defect_absolute_1', ...
    'canonical_hermitian_defect_normalized_1', ...
    'canonical_exact_hermitian', 'raw_diagonal_real_min', ...
    'raw_diagonal_real_max', 'raw_diagonal_max_abs_imag', ...
    'canonical_diagonal_real_min', 'canonical_diagonal_real_max', ...
    'canonical_diagonal_max_abs_imag', 'factorization_kind', ...
    'canonical_factorization_flag', 'consumer_contract', 'gate_pass', ...
    'first_failure_code', 'first_failure_reason'};
end

function contract_id = LOCAL_primary_contract_id( ...
    spec, mesh_id, phase_kind, phase)
  if ~any(strcmp(phase_kind, {'bulk-alpha', 'defect-theta'}))
    error('I4A:OperatorContract', 'Invalid OP2 phase kind: %s.', phase_kind);
  end
  contract_id = sprintf('OP2|%s|%s|%s|%s', spec.model_digest, ...
    mesh_id, phase_kind, lower(num2hex(phase)));
end

function contract_id = LOCAL_derived_contract_id( ...
    parent_contract_id, object_id, context_key)
  contract_id = sprintf('DRV2|%s|%s|%s', parent_contract_id, ...
    object_id, context_key);
end

function [pair, ledger] = LOCAL_prepare_primary_pair(spec, reduced, ...
    mesh_id, phase_kind, phase, solve_id, stage, ledger)
  contract_id = LOCAL_primary_contract_id(spec, mesh_id, phase_kind, phase);
  [stiffness_eval, stiffness_canonical, ~] = ...
    LOCAL_evaluate_canonical_object(spec, reduced.stiffness, 'none');
  stiffness_row = LOCAL_operator_row(stiffness_eval, stage, solve_id, ...
    mesh_id, phase_kind, phase, contract_id, '', 'reduced-stiffness', ...
    'primary-reduced-operator', 'eigs|residual');
  if ~stiffness_eval.pass
    stiffness_row{11} = 'EVALUATED_FAIL';
    stiffness_row{35} = stiffness_eval.failure_code;
    stiffness_row{36} = stiffness_eval.failure_reason;
    mass_raw = LOCAL_raw_operator_diagnostics(reduced.mass);
    mass_row = LOCAL_blocked_operator_row(mass_raw, stage, solve_id, ...
      mesh_id, phase_kind, phase, contract_id, 'reduced-mass', ...
      'primary-reduced-operator', 'chol', ...
      'chol|eigs|normalization|orthogonality|residual');
    ledger = LOCAL_checkpoint_operator_rows(ledger, ...
      [stiffness_row; mass_row]);
    LOCAL_raise(LOCAL_primary_terminal(stiffness_eval.failure_code), ...
      stiffness_eval.failure_reason);
  end

  [mass_eval, mass_canonical, mass_factor] = ...
    LOCAL_evaluate_canonical_object(spec, reduced.mass, 'chol');
  mass_row = LOCAL_operator_row(mass_eval, stage, solve_id, mesh_id, ...
    phase_kind, phase, contract_id, '', 'reduced-mass', ...
    'primary-reduced-operator', ...
    'chol|eigs|normalization|orthogonality|residual');
  if ~mass_eval.pass
    mass_row{11} = 'EVALUATED_FAIL';
    mass_row{35} = mass_eval.failure_code;
    mass_row{36} = mass_eval.failure_reason;
  end
  ledger = LOCAL_checkpoint_operator_rows(ledger, ...
    [stiffness_row; mass_row]);
  if ~mass_eval.pass
    LOCAL_raise(LOCAL_primary_terminal(mass_eval.failure_code), ...
      mass_eval.failure_reason);
  end
  pair = struct('stiffness', stiffness_canonical, ...
    'mass', mass_canonical, 'mass_factor', mass_factor, ...
    'prolongation', reduced.prolongation, ...
    'operator_contract_id', contract_id);
end

function terminal_code = LOCAL_primary_terminal(failure_code)
  if any(strcmp(failure_code, ...
      {'RAW_OPERATOR_NONFINITE', 'RAW_HERMITIAN_DEFECT'}))
    terminal_code = 'QUASIPERIODIC_SEAM_UNRESOLVED';
  else
    terminal_code = 'SPECTRUM_INVENTORY_TRUNCATED';
  end
end

function [evaluation, canonical, factor, contract_id, row] = ...
    LOCAL_evaluate_derived_row(spec, raw, metadata, object_id, ...
    object_role, context_key, factorization_kind, consumer_contract)
  contract_id = LOCAL_derived_contract_id( ...
    metadata.parent_operator_contract_id, object_id, context_key);
  [evaluation, canonical, factor] = LOCAL_evaluate_canonical_object( ...
    spec, raw, factorization_kind);
  row = LOCAL_operator_row(evaluation, metadata.stage, metadata.solve_id, ...
    metadata.mesh_id, metadata.phase_kind, metadata.phase, contract_id, ...
    metadata.parent_operator_contract_id, object_id, object_role, ...
    consumer_contract);
  if ~evaluation.pass
    row{11} = 'EVALUATED_FAIL';
    row{35} = evaluation.failure_code;
    row{36} = evaluation.failure_reason;
  end
end

function [evaluation, canonical_parity, contract_id, row, prepare_bytes] = ...
    LOCAL_prepare_parity_object(spec, mesh, subspace, metadata, context_key, ...
    object_id, object_role)
  reflection = sparse((1:size(mesh.points, 1)).', mesh.reflection_index, 1, ...
    size(mesh.points, 1), size(mesh.points, 1));
  raw_parity = subspace' * mesh.mass_full * reflection * subspace;
  [evaluation, canonical_parity, ~, contract_id, row] = ...
    LOCAL_evaluate_derived_row(spec, raw_parity, metadata, object_id, ...
    object_role, context_key, 'none', 'endpoint-parity-eig');
  if nargout >= 5
    prepare_bytes = LOCAL_value_bytes(reflection) + ...
      LOCAL_value_bytes(raw_parity) + LOCAL_value_bytes(canonical_parity);
  else
    prepare_bytes = [];
  end
end

function [parity_values, consume_bytes] = ...
    LOCAL_consume_parity_object(canonical_parity)
  parity_values = real(eig(canonical_parity));
  if any(~isfinite(parity_values))
    LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
      'Post-checkpoint parity compression returned nonfinite eigenvalues.');
  end
  consume_bytes = LOCAL_value_bytes(parity_values);
end

function [evaluation, canonical, factor] = ...
    LOCAL_evaluate_canonical_object(spec, raw, factorization_kind)
  evaluation = LOCAL_raw_operator_diagnostics(raw);
  canonical = [];
  factor = [];
  evaluation.canonical_nnz = [];
  evaluation.canonical_nonfinite_count = [];
  evaluation.canonical_delta_absolute_1 = [];
  evaluation.canonical_delta_normalized_1 = [];
  evaluation.canonical_hermitian_defect_absolute_1 = [];
  evaluation.canonical_hermitian_defect_normalized_1 = [];
  evaluation.canonical_exact_hermitian = [];
  evaluation.canonical_diagonal_real_min = [];
  evaluation.canonical_diagonal_real_max = [];
  evaluation.canonical_diagonal_max_abs_imag = [];
  evaluation.factorization_kind = factorization_kind;
  evaluation.factorization_flag = [];
  evaluation.pass = false;
  evaluation.failure_code = '';
  evaluation.failure_reason = '';
  if evaluation.raw_nonfinite_count ~= 0 || ...
      evaluation.rows ~= evaluation.columns
    evaluation.failure_code = 'RAW_OPERATOR_NONFINITE';
    evaluation.failure_reason = ...
      'Raw operator is nonsquare or contains nonfinite entries.';
    return;
  end
  if evaluation.raw_hermitian_defect_normalized_1 > ...
      spec.hermitian_tolerance
    evaluation.failure_code = 'RAW_HERMITIAN_DEFECT';
    evaluation.failure_reason = sprintf( ...
      'Raw Hermitian defect %.17g exceeds %.17g.', ...
      evaluation.raw_hermitian_defect_normalized_1, ...
      spec.hermitian_tolerance);
    return;
  end
  canonical = LOCAL_canonical_hermitian(raw);
  canonical_values = nonzeros(canonical);
  evaluation.canonical_nnz = nnz(canonical);
  evaluation.canonical_nonfinite_count = nnz(~isfinite(canonical_values));
  delta = canonical - raw;
  evaluation.canonical_delta_absolute_1 = norm(delta, 1);
  evaluation.canonical_delta_normalized_1 = ...
    evaluation.canonical_delta_absolute_1 / max(1, norm(raw, 1));
  evaluation.canonical_hermitian_defect_absolute_1 = ...
    norm(canonical - canonical', 1);
  evaluation.canonical_hermitian_defect_normalized_1 = ...
    evaluation.canonical_hermitian_defect_absolute_1 / ...
    max(1, norm(canonical, 1));
  evaluation.canonical_exact_hermitian = isequal(canonical, canonical');
  [evaluation.canonical_diagonal_real_min, ...
    evaluation.canonical_diagonal_real_max, ...
    evaluation.canonical_diagonal_max_abs_imag] = ...
    LOCAL_diagonal_diagnostics(canonical);
  if evaluation.canonical_nonfinite_count ~= 0 || ...
      ~evaluation.canonical_exact_hermitian || ...
      evaluation.canonical_hermitian_defect_absolute_1 ~= 0
    evaluation.failure_code = 'CANONICAL_OPERATOR_INVALID';
    evaluation.failure_reason = ...
      'Canonical operator is nonfinite or not exactly Hermitian.';
    return;
  end
  if strcmp(factorization_kind, 'chol')
    canonical_diagonal = diag(canonical);
    if any(~isfinite(canonical_diagonal)) || ...
        any(imag(canonical_diagonal) ~= 0) || ...
        any(real(canonical_diagonal) <= 0)
      evaluation.failure_code = 'CANONICAL_MASS_DIAGONAL_INVALID';
      evaluation.failure_reason = ...
        'Canonical mass/self-Gram diagonal is not finite, real, and positive.';
      return;
    end
    [factor, evaluation.factorization_flag] = chol(canonical);
    if evaluation.factorization_flag ~= 0
      evaluation.failure_code = 'CANONICAL_FACTORIZATION_FAILED';
      evaluation.failure_reason = sprintf( ...
        'Canonical Cholesky factorization failed at natural pivot %d.', ...
        evaluation.factorization_flag);
      return;
    end
  end
  evaluation.pass = true;
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

function diagnostics = LOCAL_raw_operator_diagnostics(raw)
  diagnostics = struct();
  diagnostics.rows = size(raw, 1);
  diagnostics.columns = size(raw, 2);
  diagnostics.raw_nnz = nnz(raw);
  if issparse(raw)
    raw_values = nonzeros(raw);
  else
    raw_values = raw(:);
  end
  diagnostics.raw_nonfinite_count = nnz(~isfinite(raw_values));
  if diagnostics.rows == diagnostics.columns
    diagnostics.raw_hermitian_defect_absolute_1 = norm(raw - raw', 1);
    diagnostics.raw_hermitian_defect_normalized_1 = ...
      diagnostics.raw_hermitian_defect_absolute_1 / max(1, norm(raw, 1));
    [diagnostics.raw_diagonal_real_min, ...
      diagnostics.raw_diagonal_real_max, ...
      diagnostics.raw_diagonal_max_abs_imag] = ...
      LOCAL_diagonal_diagnostics(raw);
  else
    diagnostics.raw_hermitian_defect_absolute_1 = NaN;
    diagnostics.raw_hermitian_defect_normalized_1 = NaN;
    diagnostics.raw_diagonal_real_min = NaN;
    diagnostics.raw_diagonal_real_max = NaN;
    diagnostics.raw_diagonal_max_abs_imag = NaN;
  end
end

function [minimum_real, maximum_real, maximum_abs_imaginary] = ...
    LOCAL_diagonal_diagnostics(matrix)
  diagonal_values = diag(matrix);
  if isempty(diagonal_values)
    minimum_real = NaN;
    maximum_real = NaN;
    maximum_abs_imaginary = NaN;
  else
    minimum_real = full(min(real(diagonal_values)));
    maximum_real = full(max(real(diagonal_values)));
    maximum_abs_imaginary = full(max(abs(imag(diagonal_values))));
  end
end

function row = LOCAL_operator_row(evaluation, stage, solve_id, mesh_id, ...
    phase_kind, phase, contract_id, parent_contract_id, object_id, ...
    object_role, consumer_contract)
  row = {[], stage, solve_id, mesh_id, phase_kind, phase, contract_id, ...
    parent_contract_id, object_id, object_role, 'EVALUATED_PASS', ...
    evaluation.rows, evaluation.columns, evaluation.raw_nnz, ...
    evaluation.canonical_nnz, evaluation.raw_nonfinite_count, ...
    evaluation.canonical_nonfinite_count, ...
    evaluation.raw_hermitian_defect_absolute_1, ...
    evaluation.raw_hermitian_defect_normalized_1, ...
    evaluation.canonical_delta_absolute_1, ...
    evaluation.canonical_delta_normalized_1, ...
    evaluation.canonical_hermitian_defect_absolute_1, ...
    evaluation.canonical_hermitian_defect_normalized_1, ...
    evaluation.canonical_exact_hermitian, ...
    evaluation.raw_diagonal_real_min, evaluation.raw_diagonal_real_max, ...
    evaluation.raw_diagonal_max_abs_imag, ...
    evaluation.canonical_diagonal_real_min, ...
    evaluation.canonical_diagonal_real_max, ...
    evaluation.canonical_diagonal_max_abs_imag, ...
    evaluation.factorization_kind, evaluation.factorization_flag, ...
    consumer_contract, evaluation.pass, '', ''};
end

function row = LOCAL_blocked_operator_row(raw, stage, solve_id, mesh_id, ...
    phase_kind, phase, contract_id, object_id, object_role, ...
    factorization_kind, consumer_contract)
  row = {[], stage, solve_id, mesh_id, phase_kind, phase, contract_id, '', ...
    object_id, object_role, 'RAW_ONLY_BLOCKED_BY_PRIOR_OBJECT', ...
    raw.rows, raw.columns, raw.raw_nnz, [], raw.raw_nonfinite_count, [], ...
    raw.raw_hermitian_defect_absolute_1, ...
    raw.raw_hermitian_defect_normalized_1, [], [], [], [], [], ...
    raw.raw_diagonal_real_min, raw.raw_diagonal_real_max, ...
    raw.raw_diagonal_max_abs_imag, [], [], [], factorization_kind, [], ...
    consumer_contract, [], '', ''};
end

function ledger = LOCAL_checkpoint_operator_rows(ledger, new_rows)
  if isempty(new_rows)
    return;
  end
  LOCAL_assert_operator_rows(new_rows, ledger.header);
  if size(ledger.rows, 1) + size(new_rows, 1) > ledger.row_upper_count || ...
      ledger.completed_checkpoint_count + 1 > ledger.checkpoint_upper_count
    error('I4A:OperatorEvidence', ...
      'Operator evidence exceeded the frozen row/checkpoint upper bound.');
  end
  for row_index = 1:size(new_rows, 1)
    sequence = size(ledger.rows, 1) + 1;
    new_rows{row_index, 1} = sequence;
    if isempty(ledger.first_failure.code) && ...
        ~isempty(new_rows{row_index, 35})
      ledger.first_failure.code = new_rows{row_index, 35};
      ledger.first_failure.reason = new_rows{row_index, 36};
      ledger.first_failure.owner_object_id = new_rows{row_index, 9};
      ledger.first_failure.owner_sequence = sequence;
    elseif ~isempty(new_rows{row_index, 35}) && ...
        ~strcmp(new_rows{row_index, 35}, ledger.first_failure.code)
      error('I4A:OperatorEvidence', ...
        'Operator ledger attempted to publish a second first failure.');
    end
    ledger.rows(end + 1, :) = new_rows(row_index, :); %#ok<AGROW>
  end
  ledger.completed_checkpoint_count = ledger.completed_checkpoint_count + 1;
  LOCAL_write_operator_representation(ledger);
end

function LOCAL_assert_operator_rows(rows, header)
  if size(rows, 2) ~= 36 || numel(header) ~= 36
    error('I4A:OperatorEvidence', ...
      'Operator representation must have exactly 36 columns.');
  end
  allowed_status = {'EVALUATED_PASS', 'EVALUATED_FAIL', ...
    'RAW_ONLY_BLOCKED_BY_PRIOR_OBJECT'};
  for row_index = 1:size(rows, 1)
    if ~any(strcmp(rows{row_index, 11}, allowed_status))
      error('I4A:OperatorEvidence', ...
        'Operator representation has an invalid evaluation status.');
    end
    for column_index = 1:size(rows, 2)
      value = rows{row_index, column_index};
      valid = isempty(value) || ischar(value) || ...
        ((isnumeric(value) || islogical(value)) && isscalar(value) && ...
        ~issparse(value)) || (isstring(value) && isscalar(value));
      if ~valid
        error('I4A:OperatorEvidence', ...
          'Operator representation contains an unsupported cell value.');
      end
    end
  end
end

function timings = LOCAL_write_operator_representation(ledger)
  publication_clock = tic;
  mat_clock = tic;
  payload = LOCAL_prepare_operator_payload(ledger);
  LOCAL_atomic_save(fullfile(ledger.output_dir, ...
    'operator-representation.mat'), payload);
  timings.mat_seconds = toc(mat_clock);
  csv_clock = tic;
  LOCAL_write_csv(fullfile(ledger.output_dir, ...
    'operator-representation.csv'), ledger.header, ledger.rows);
  timings.csv_seconds = toc(csv_clock);
  timings.total_seconds = toc(publication_clock);
end

function payload = LOCAL_prepare_operator_payload(ledger)
  LOCAL_assert_operator_rows(ledger.rows, ledger.header);
  primary_mask = cellfun(@isempty, ledger.rows(:, 8));
  primary_contract_inventory = unique(ledger.rows(primary_mask, 7), 'stable');
  derived_rows = ledger.rows(~primary_mask, [7, 8]);
  if isempty(derived_rows)
    derived_parent_inventory = cell(0, 2);
  else
    derived_keys = strcat(derived_rows(:, 1), '|PARENT|', derived_rows(:, 2));
    [~, stable_indices] = unique(derived_keys, 'stable');
    derived_parent_inventory = derived_rows(stable_indices, :);
  end
  payload = struct();
  payload.schema_version = ledger.schema_version;
  payload.column_count = 36;
  payload.header = ledger.header;
  payload.rows = ledger.rows;
  payload.row_count = size(ledger.rows, 1);
  payload.primary_contract_inventory = primary_contract_inventory;
  payload.derived_parent_inventory = derived_parent_inventory;
  payload.completed_checkpoint_count = ledger.completed_checkpoint_count;
  payload.first_failure = ledger.first_failure;
  payload.model_id = ledger.model_id;
  payload.model_digest = ledger.model_digest;
  payload.planned_solves = ledger.planned_solves;
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
    stiffness_canonical = LOCAL_canonical_hermitian(reduced.stiffness);
    mass_canonical = LOCAL_canonical_hermitian(reduced.mass);
    reduced_nnz = nnz(stiffness_canonical) + nnz(mass_canonical);
    symbolic_pattern = spones(stiffness_canonical) + ...
      spones(mass_canonical) + speye(size(stiffness_canonical, 1));
    symbolic_counts = symbfact(symbolic_pattern);
    symbolic_factor_nnz = sum(symbolic_counts);
    file_record = dir(registry(mesh_index).path);
    cache_bytes = file_record.bytes;
    workspace_40_bytes = LOCAL_workspace_bytes(size(stiffness_canonical, 1), ...
      size(mesh.points, 1), reduced_nnz, symbolic_factor_nnz, 40, 80, ...
      bytes_per_complex, bytes_per_sparse_entry);
    workspace_48_bytes = LOCAL_workspace_bytes(size(stiffness_canonical, 1), ...
      size(mesh.points, 1), reduced_nnz, symbolic_factor_nnz, 48, 96, ...
      bytes_per_complex, bytes_per_sparse_entry);
    mesh_details(end + 1) = struct('id', registry(mesh_index).id, ...
      'reduced_dof', size(stiffness_canonical, 1), ...
      'reduced_nnz', reduced_nnz, ...
      'symbolic_factor_nnz', symbolic_factor_nnz, ...
      'workspace_40_bytes', workspace_40_bytes, ...
      'workspace_48_bytes', workspace_48_bytes, ...
      'cache_bytes', cache_bytes); %#ok<AGROW>
    mesh_peak = max(workspace_40_bytes, workspace_48_bytes) + ...
      cache_bytes + runtime_baseline_bytes + csv_buffer_bytes;
    max_peak_bytes = max(max_peak_bytes, mesh_peak);
    total_mesh_cache_bytes = total_mesh_cache_bytes + cache_bytes;
    max_dof = max(max_dof, size(stiffness_canonical, 1));
    max_nnz = max(max_nnz, reduced_nnz);
    max_symbolic_factor_nnz = max(max_symbolic_factor_nnz, ...
      symbolic_factor_nnz);
    rows(end + 1, :) = {registry(mesh_index).id, 'mesh-symbolic', 0, ...
      0, 1, runtime_safety_factor, 0, mesh_peak, cache_bytes, ...
      sprintf('dof=%d;reduced_nnz=%d;symbolic_factor_nnz=%d;ws40=%d;ws48=%d', ...
      size(stiffness_canonical, 1), reduced_nnz, symbolic_factor_nnz, ...
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
    spec.canonical_preflight_floor_gib * 1024 ^ 3);

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

function [spectrum, phase_diagnostic, operator_ledger] = LOCAL_low_spectrum( ...
    spec, mesh, phase_x, tolerance, requested_nev, role, bounds, ...
    solve_id, phase_kind, operator_ledger)
  [reduced, phase_diagnostic] = LOCAL_phase_reduce( ...
    spec, mesh, phase_x, role);
  [operator_pair, operator_ledger] = LOCAL_prepare_primary_pair( ...
    spec, reduced, mesh.id, phase_kind, phase_x, solve_id, ...
    'PRIMARY_REDUCED_OPERATOR', operator_ledger);
  reduced_dof = size(operator_pair.stiffness, 1);
  if reduced_dof <= requested_nev + 2
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s has only %d reduced DOF for %d requested roots.', ...
      mesh.id, reduced_dof, requested_nev));
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
    operator_pair.stiffness, operator_pair.mass, requested_nev, ...
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
    mass_norm = real(vectors_reduced(:, root_index)' * operator_pair.mass * ...
      vectors_reduced(:, root_index));
    if ~isfinite(mass_norm) || mass_norm <= 0
      LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
        sprintf('%s phase %.17g has invalid mass norm.', mesh.id, phase_x));
    end
    vectors_reduced(:, root_index) = vectors_reduced(:, root_index) / ...
      sqrt(mass_norm);
  end
  stiffness_norm = norm(operator_pair.stiffness, 1);
  mass_norm = norm(operator_pair.mass, 1);
  residuals = zeros(requested_nev, 1);
  for root_index = 1:requested_nev
    vector = vectors_reduced(:, root_index);
    residuals(root_index) = norm(operator_pair.stiffness * vector - ...
      eigenvalues(root_index) * operator_pair.mass * vector, 2) / ...
      ((stiffness_norm + abs(eigenvalues(root_index)) * mass_norm) * ...
      norm(vector, 2));
  end
  frequencies = sqrt(eigenvalues);
  cluster_ids = LOCAL_cluster_ids(spec, frequencies, residuals);
  normalization_contract_ids = cell(max(cluster_ids), 1);
  vectors_full = operator_pair.prolongation * vectors_reduced;
  if strcmp(phase_kind, 'defect-theta')
    [vectors_reduced, vectors_full, normalization_contract_ids, ...
      operator_ledger] = LOCAL_normalize_defect_clusters(spec, mesh, ...
      phase_x, solve_id, operator_pair, vectors_reduced, cluster_ids, ...
      operator_ledger);
  end
  orthogonality_defect = norm(vectors_reduced' * operator_pair.mass * ...
    vectors_reduced - eye(requested_nev), 2);
  if orthogonality_defect > spec.orthogonality_tolerance
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g M-orthogonality defect %.17g.', ...
      mesh.id, phase_x, orthogonality_defect));
  end

  residuals = zeros(requested_nev, 1);
  for root_index = 1:requested_nev
    vector = vectors_reduced(:, root_index);
    residuals(root_index) = norm(operator_pair.stiffness * vector - ...
      eigenvalues(root_index) * operator_pair.mass * vector, 2) / ...
      ((stiffness_norm + abs(eigenvalues(root_index)) * mass_norm) * ...
      norm(vector, 2));
  end
  if any(residuals > spec.residual_tolerance)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', sprintf( ...
      '%s phase %.17g has algebraic residual %.17g.', ...
      mesh.id, phase_x, max(residuals)));
  end
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

  verified_cluster_ids = LOCAL_cluster_ids(spec, frequencies, residuals);
  if ~isequal(verified_cluster_ids, cluster_ids)
    LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
      'Canonical cluster normalization changed cluster bookkeeping.');
  end
  multiplicities = accumarray(cluster_ids, 1);
  if sum(multiplicities) ~= requested_nev
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'Cluster multiplicities do not sum to the requested count.');
  end
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
  spectrum.operator_contract_id = operator_pair.operator_contract_id;
  spectrum.normalization_contract_ids = normalization_contract_ids;
end

function [vectors_reduced, vectors_full, normalization_contract_ids, ...
    operator_ledger] = LOCAL_normalize_defect_clusters(spec, mesh, phase, ...
    solve_id, operator_pair, vectors_reduced, cluster_ids, operator_ledger)
  cluster_numbers = unique(cluster_ids).';
  normalization_contract_ids = cell(max(cluster_ids), 1);
  pending_rows = cell(0, 36);
  prepared = struct('cluster_id', {}, 'root_indices', {}, ...
    'initial_reduced', {}, 'normalizer', {}, 'contract_id', {});
  % Prepare every global Gram and factor before the per-solve checkpoint.
  for cluster_index = 1:numel(cluster_numbers)
    cluster_id = cluster_numbers(cluster_index);
    root_indices = find(cluster_ids == cluster_id);
    initial_reduced = vectors_reduced(:, root_indices);
    raw_gram = initial_reduced' * operator_pair.mass * initial_reduced;
    metadata = struct('stage', 'CLUSTER_GLOBAL_NORMALIZATION', ...
      'solve_id', solve_id, 'mesh_id', mesh.id, ...
      'phase_kind', 'defect-theta', 'phase', phase, ...
      'parent_operator_contract_id', operator_pair.operator_contract_id);
    context_key = sprintf('solve-%s|cluster-%d', solve_id, cluster_id);
    [evaluation, ~, normalizer, contract_id, row] = ...
      LOCAL_evaluate_derived_row(spec, raw_gram, metadata, ...
      'cluster-global-mass-gram', 'derived-global-mass-gram', ...
      context_key, 'chol', ...
      ['cluster-chol|cluster-normalization|restricted-gram-basis|' ...
      'continuation-basis']);
    pending_rows(end + 1, :) = row; %#ok<AGROW>
    if ~evaluation.pass
      operator_ledger = LOCAL_checkpoint_operator_rows( ...
        operator_ledger, pending_rows);
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        evaluation.failure_reason);
    end
    prepared(end + 1) = struct('cluster_id', cluster_id, ...
      'root_indices', root_indices, 'initial_reduced', initial_reduced, ...
      'normalizer', normalizer, 'contract_id', contract_id); %#ok<AGROW>
  end
  operator_ledger = LOCAL_checkpoint_operator_rows( ...
    operator_ledger, pending_rows);
  % Consume only after the complete global batch is durably published.
  for cluster_index = 1:numel(prepared)
    item = prepared(cluster_index);
    normalized_reduced = item.initial_reduced / item.normalizer;
    normalized_full = operator_pair.prolongation * normalized_reduced;
    mass_defect = norm(normalized_reduced' * operator_pair.mass * ...
      normalized_reduced - eye(numel(item.root_indices)), 2);
    synchronization_defect = norm(normalized_full - ...
      operator_pair.prolongation * normalized_reduced, 2);
    synchronization_limit = 1e-12 * max(1, norm(normalized_full, 2));
    if mass_defect > spec.orthogonality_tolerance || ...
        synchronization_defect > synchronization_limit
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'Post-checkpoint canonical cluster synchronization gate failed.');
    end
    vectors_reduced(:, item.root_indices) = normalized_reduced;
    normalization_contract_ids{item.cluster_id} = item.contract_id;
  end
  vectors_full = operator_pair.prolongation * vectors_reduced;
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
      [spectrum, phase_diagnostic, artifacts.operator_ledger] = ...
        LOCAL_low_spectrum(spec, mesh, ...
        level.alphas(phase_index), level.tol, spec.bulk_main_nev, ...
        'bulk-main', bounds, solve_id, 'bulk-alpha', ...
        artifacts.operator_ledger);
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
    [sentinel, phase_diagnostic, artifacts.operator_ledger] = ...
      LOCAL_low_spectrum(spec, mesh, alpha, 1e-11, spec.count_nev, ...
      'bulk-count', bounds, solve_id, 'bulk-alpha', ...
      artifacts.operator_ledger);
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
    [spectrum, phase_diagnostic, artifacts.operator_ledger] = ...
      LOCAL_low_spectrum(spec, mesh, item.theta, item.tol, item.nev, ...
      item.role, bounds, item.id, 'defect-theta', ...
      artifacts.operator_ledger);
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
      [configurations.(field_name), build_failure, ...
        artifacts.operator_ledger] = LOCAL_build_configuration( ...
        spec, name, defect_inventory, bulk_inventory.target_gap, registry, ...
        work_dir, artifacts.operator_ledger);
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

function [config, failure, operator_ledger] = LOCAL_build_configuration( ...
    spec, name, defect_inventory, target_gap, registry, work_dir, ...
    operator_ledger)
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
      [clusters, operator_ledger] = LOCAL_gap_clusters(spec, spectrum, ...
        target_gap, mesh, entries(slice_index).id, operator_ledger);
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

function [clusters, operator_ledger] = LOCAL_gap_clusters( ...
    spec, spectrum, target_gap, mesh, solve_id, operator_ledger)
  raw = target_gap.raw;
  in_raw = spectrum.frequencies > raw(1) & spectrum.frequencies < raw(2);
  cluster_numbers = unique(spectrum.cluster_ids(in_raw)).';
  clusters = struct('cluster_id', {}, 'root_indices', {}, 'dimension', {}, ...
    'frequencies', {}, 'envelope', {}, 'subspace', {}, 'L0_min', {}, ...
    'Lcore_min', {}, 'tail_max', {}, 'parity_spectrum', {}, ...
    'parity_ambiguous', {}, 'operator_contract_id', {}, ...
    'normalization_contract_id', {}, 'common_core_samples', {}, ...
    'common_core_weights', {});
  prepared = struct('cluster_id', {}, 'root_indices', {}, 'subspace', {}, ...
    'normalization_contract_id', {}, 'canonical_restricted', {}, ...
    'canonical_parity', {}, 'parity_values', {}, ...
    'parity_ambiguous', {}, 'common_samples', {}, ...
    'common_weights', {}, 'common_factor', {});
  pending_restricted_rows = cell(0, 36);
  % Prepare all restricted/parity objects without consuming their spectra.
  for local_index = 1:numel(cluster_numbers)
    cluster_id = cluster_numbers(local_index);
    root_indices = find(spectrum.cluster_ids == cluster_id);
    if any(~in_raw(root_indices))
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'A frequency cluster straddles a raw observed gap edge.');
    end
    subspace = spectrum.vectors_full(:, root_indices);
    normalization_contract_id = ...
      spectrum.normalization_contract_ids{cluster_id};
    if isempty(normalization_contract_id)
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'A gap cluster lacks its canonical reduced normalization contract.');
    end
    metadata = struct('stage', 'RESTRICTED_CLUSTER_GRAMS', ...
      'solve_id', solve_id, 'mesh_id', mesh.id, ...
      'phase_kind', 'defect-theta', 'phase', spectrum.phase, ...
      'parent_operator_contract_id', spectrum.operator_contract_id);
    context_key = sprintf('solve-%s|cluster-%d', solve_id, cluster_id);
    restricted_mass = {mesh.mass_center, mesh.mass_core, mesh.mass_tail};
    restricted_ids = {'center-mass-gram', ...
      'core-mass-gram', 'tail-mass-gram'};
    restricted_consumers = {'localization-center-eig', ...
      'localization-core-eig', 'localization-tail-eig'};
    canonical_restricted_matrices = cell(1, 3);
    for restricted_index = 1:3
      raw_restricted = subspace' * restricted_mass{restricted_index} * subspace;
      [evaluation, canonical_restricted_matrix, ~, ~, row] = ...
        LOCAL_evaluate_derived_row(spec, raw_restricted, metadata, ...
        restricted_ids{restricted_index}, 'derived-restricted-mass-gram', ...
        context_key, 'none', restricted_consumers{restricted_index});
      pending_restricted_rows(end + 1, :) = row; %#ok<AGROW>
      if ~evaluation.pass
        operator_ledger = LOCAL_checkpoint_operator_rows( ...
          operator_ledger, pending_restricted_rows);
        LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
          evaluation.failure_reason);
      end
      canonical_restricted_matrices{restricted_index} = ...
        canonical_restricted_matrix;
    end
    endpoint_phase = spectrum.phase == 0 || spectrum.phase == pi;
    if endpoint_phase
      [evaluation, canonical_parity, ~, row] = ...
        LOCAL_prepare_parity_object(spec, mesh, subspace, metadata, ...
        context_key, 'parity-compression', 'derived-parity-compression');
      pending_restricted_rows(end + 1, :) = row; %#ok<AGROW>
      if ~evaluation.pass
        operator_ledger = LOCAL_checkpoint_operator_rows( ...
          operator_ledger, pending_restricted_rows);
        LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
          evaluation.failure_reason);
      end
    else
      canonical_parity = [];
    end
    prepared(end + 1) = struct('cluster_id', cluster_id, ...
      'root_indices', root_indices, 'subspace', subspace, ...
      'normalization_contract_id', normalization_contract_id, ...
      'canonical_restricted', {canonical_restricted_matrices}, ...
      'canonical_parity', canonical_parity, 'parity_values', [], ...
      'parity_ambiguous', false, 'common_samples', [], ...
      'common_weights', [], 'common_factor', []); %#ok<AGROW>
  end
  operator_ledger = LOCAL_checkpoint_operator_rows( ...
    operator_ledger, pending_restricted_rows);
  % Consume restricted/parity spectra only after their batch checkpoint.
  for local_index = 1:numel(prepared)
    restricted_values = cell(1, 3);
    for restricted_index = 1:3
      restricted_values{restricted_index} = real(eig( ...
        prepared(local_index).canonical_restricted{restricted_index}));
      if any(~isfinite(restricted_values{restricted_index}))
        LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
          'Post-checkpoint restricted Gram returned nonfinite eigenvalues.');
      end
    end
    prepared(local_index).canonical_restricted = restricted_values;
    if ~isempty(prepared(local_index).canonical_parity)
      [parity_values, ~] = LOCAL_consume_parity_object( ...
        prepared(local_index).canonical_parity);
      prepared(local_index).parity_values = parity_values;
      prepared(local_index).parity_ambiguous = ...
        any(abs(parity_values) < spec.parity_threshold);
    end
  end

  pending_common_rows = cell(0, 36);
  % Prepare and factor all common-core self-Grams before normalization.
  for local_index = 1:numel(prepared)
    item = prepared(local_index);
    [common_samples, common_weights] = LOCAL_sample_subspace( ...
      spec, mesh, item.subspace);
    raw_common_gram = common_samples' * ...
      (common_weights .* common_samples);
    metadata = struct('stage', 'COMMON_CORE_SELF_GRAM', ...
      'solve_id', solve_id, 'mesh_id', mesh.id, ...
      'phase_kind', 'defect-theta', 'phase', spectrum.phase, ...
      'parent_operator_contract_id', spectrum.operator_contract_id);
    context_key = sprintf('solve-%s|cluster-%d', ...
      solve_id, item.cluster_id);
    [evaluation, ~, common_factor, ~, row] = ...
      LOCAL_evaluate_derived_row(spec, raw_common_gram, metadata, ...
      'common-core-self-gram', 'derived-common-core-self-gram', ...
      context_key, 'chol', 'common-core-normalization|cross-gram');
    pending_common_rows(end + 1, :) = row; %#ok<AGROW>
    if ~evaluation.pass
      operator_ledger = LOCAL_checkpoint_operator_rows( ...
        operator_ledger, pending_common_rows);
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        evaluation.failure_reason);
    end
    prepared(local_index).common_samples = common_samples;
    prepared(local_index).common_weights = common_weights;
    prepared(local_index).common_factor = common_factor;
  end
  operator_ledger = LOCAL_checkpoint_operator_rows( ...
    operator_ledger, pending_common_rows);
  % Consume common-core factors only after the complete batch checkpoint.
  for local_index = 1:numel(prepared)
    item = prepared(local_index);
    common_samples = item.common_samples / item.common_factor;
    common_weights = item.common_weights;
    common_orthogonality_defect = norm(common_samples' * ...
      (common_weights .* common_samples) - eye(numel(item.root_indices)), 2);
    if common_orthogonality_defect > spec.orthogonality_tolerance
      LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
        'Post-checkpoint common-core normalization recheck failed.');
    end
    restricted_values = item.canonical_restricted;
    center_values = restricted_values{1};
    core_values = restricted_values{2};
    tail_values = restricted_values{3};
    clusters(end + 1) = struct('cluster_id', item.cluster_id, ...
      'root_indices', item.root_indices, ...
      'dimension', numel(item.root_indices), ...
      'frequencies', spectrum.frequencies(item.root_indices), ...
      'envelope', [min(spectrum.frequencies(item.root_indices)), ...
      max(spectrum.frequencies(item.root_indices))], ...
      'subspace', item.subspace, ...
      'L0_min', min(center_values), 'Lcore_min', min(core_values), ...
      'tail_max', max(tail_values), ...
      'parity_spectrum', item.parity_values, ...
      'parity_ambiguous', item.parity_ambiguous, ...
      'operator_contract_id', spectrum.operator_contract_id, ...
      'normalization_contract_id', item.normalization_contract_id, ...
      'common_core_samples', common_samples, ...
      'common_core_weights', common_weights); %#ok<AGROW>
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
        fine_cluster = finest.branches(fine_index).clusters{fine_slice};
        other_cluster = other.branches(other_index).clusters{other_slice};
        slice_scores(phase_index) = LOCAL_common_core_overlap( ...
          fine_cluster, other_cluster);
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

function overlap = LOCAL_common_core_overlap(first_cluster, second_cluster)
  first_samples = first_cluster.common_core_samples;
  weights = first_cluster.common_core_weights;
  second_samples = second_cluster.common_core_samples;
  second_weights = second_cluster.common_core_weights;
  if numel(weights) ~= numel(second_weights) || ...
      max(abs(weights - second_weights)) > 1e-14
    LOCAL_raise('REFERENCE_SET_COVERAGE_UNRESOLVED', ...
      'Common-core diagnostic weights differ across meshes.');
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
