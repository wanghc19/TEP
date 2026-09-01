function run_i4_1b_core(run_id, execution_id)
%RUN_I4_1B_CORE Run the Section 23 coarse-core P2 FEM lifecycle.
% Purpose:
%   Build an independent fitted P2 representation preflight or compute the
%   frozen preliminary P2 field branch followed by five empirical axes.
% Input:
%   run_id - Exactly 'resource-preflight-002' or 'run-002'.
%   execution_id - Exactly 'execution-003' for preflight or
%   'execution-002' for formal science.
% Output:
%   Preflight publishes four representation/resource leaves. Formal science
%   publishes immutable preliminary leaves before any refinement leaves.
% Main algorithm:
%   Assemble straight-interface P2 forms, impose quasiperiodic phases, release
%   each fill-reduced mass factor immediately, solve the 61/66 fixed schedule,
%   and rank field branches by the Section 23 pure-P2 tuple.
% Based on:
%   run_i4_1b.m mesh, basis, quadrature, phase, and field-evaluation formulas.
% Main changes:
%   Uses the Section 23 coarse mesh ladder, no P1 eigensolver, no capacity
%   simulation, no historical input, and an immutable preliminary-first result.
% Numerical goal:
%   Produce a non-certified empirical P2 reference candidate and observed
%   refinement components without any effectivity or existence claim.

  if nargin ~= 2 || ~(ischar(run_id) || ...
      (isstring(run_id) && isscalar(run_id))) || ...
      ~(ischar(execution_id) || ...
      (isstring(execution_id) && isscalar(execution_id)))
    error('I4C:InvalidIdentity', 'Two fixed text identities are required.');
  end
  run_id = char(run_id);
  execution_id = char(execution_id);
  is_preflight = strcmp(run_id, 'resource-preflight-002') && ...
    strcmp(execution_id, 'execution-003');
  is_formal = strcmp(run_id, 'run-002') && ...
    strcmp(execution_id, 'execution-002');
  if ~is_preflight && ~is_formal
    error('I4C:InvalidIdentity', 'The identity is outside the exact allowlist.');
  end
  output_dir = fullfile(fileparts(mfilename('fullpath')), ...
    'output', run_id, execution_id);
  if ~exist(output_dir, 'dir')
    error('I4C:OutputUnavailable', ...
      'The fixed controller must claim the execution directory first.');
  end
  spec = LOCAL_spec();
  if is_preflight
    LOCAL_preflight(spec, output_dir);
  else
    LOCAL_formal(spec, output_dir);
  end
end

%% ==================== Frozen source and lifecycle ====================
% Design Section 23 defines the only active constants, meshes, and schedules.

function spec = LOCAL_spec()
  spec = struct();
  spec.design_id = 'I4.1B-COARSE-CORE-P2-V1';
  spec.model_id = 'scalar-laplace-q17-r0p2-beta0p5-missing0-v1';
  spec.period = 1;
  spec.radius = 0.2;
  spec.q_inside = 17;
  spec.q_outside = 1;
  spec.missing_column = 0;
  spec.beta = 0.5;
  spec.w3 = [0.45, 3.25];
  spec.cue_interval = [1.65, 2.05];
  spec.coverage_ceiling = 3.35;
  spec.theta_5 = linspace(0, pi, 5);
  spec.theta_9 = linspace(0, pi, 9);
  spec.theta_9_added = spec.theta_9(2:2:8);
  spec.bulk_alpha_17 = linspace(0, pi, 17);
  spec.defect_nev = 48;
  spec.expanded_nev = 60;
  spec.bulk_nev = 40;
  spec.eigs_maxit = 800;
  spec.eigs_subspace_40 = 80;
  spec.eigs_subspace_48 = 96;
  spec.eigs_subspace_60 = 100;
  spec.tight_tolerance = 1e-10;
  spec.loose_tolerance = 1e-8;
  spec.bulk_tolerance = 1e-9;
  spec.residual_tolerance = 1e-9;
  spec.orthogonality_tolerance = 1e-7;
  spec.imaginary_tolerance = 1e-10;
  spec.hermitian_tolerance = 5e-13;
  spec.coordinate_tolerance = 1e-13;
  spec.seam_tolerance = 1e-12;
  spec.constraint_tolerance = 2e-12;
  spec.cluster_frequency_tolerance = 1e-6;
  spec.cluster_residual_factor = 20;
  spec.localization_center_min = 0.15;
  spec.localization_core_min = 0.60;
  spec.tail_max = 0.02;
  spec.simple_overlap_min = 0.90;
  spec.cluster_overlap_min = 0.80;
  spec.parity_threshold = 0.80;
  spec.nodal_tolerance = 5e-14;
  spec.partition_gradient_tolerance = 5e-13;
  spec.monomial_tolerance = 2e-13;
  spec.embedding_tolerance = 1e-12;
  spec.expansion_frequency_tolerance = 1e-8;
  spec.expansion_overlap_tolerance = 1e-8;
  spec.core_grid_x = linspace(-2.5, 2.5, 161);
  spec.core_grid_y = linspace(-0.5, 0.5, 65);
  spec.preliminary_claim = ...
    'P2_PRELIMINARY_EMPIRICAL_REFERENCE_CANDIDATE / NONCERTIFIED / NO CONTINUOUS EXISTENCE CLAIM / NO EFFECTIVITY';
  spec.partial_claim = ...
    'P2_EMPIRICAL_REFERENCE_REFINEMENT_PARTIAL / NONCERTIFIED / NO CONTINUOUS EXISTENCE CLAIM / NO EFFECTIVITY';
  spec.complete_claim = ...
    'P2_EMPIRICAL_REFERENCE_REFINEMENT_COMPLETE / NONCERTIFIED / NO CONTINUOUS EXISTENCE CLAIM / NO EFFECTIVITY';
end

function item = LOCAL_mesh_item(id, kind, N, s, n_gamma)
  item = struct('id', id, 'kind', kind, 'N', N, ...
    's', s, 'n_gamma', n_gamma);
end

function item = LOCAL_named_mesh(name)
  switch name
    case 'bulk-s9-g24'
      item = LOCAL_mesh_item(name, 'bulk', 0, 9, 24);
    case 'p2-h0'
      item = LOCAL_mesh_item(name, 'defect', 4, 6, 24);
    case 'p2-anchor'
      item = LOCAL_mesh_item(name, 'defect', 4, 9, 24);
    case {'p2-h2', 'defect-N4-s12-g24'}
      item = LOCAL_mesh_item(name, 'defect', 4, 12, 24);
    case 'p2-g0'
      item = LOCAL_mesh_item(name, 'defect', 4, 9, 16);
    case {'p2-g2', 'defect-N4-s9-g32'}
      item = LOCAL_mesh_item(name, 'defect', 4, 9, 32);
    case 'p2-N3'
      item = LOCAL_mesh_item(name, 'defect', 3, 9, 24);
    case {'p2-N5', 'defect-N5-s9-g24'}
      item = LOCAL_mesh_item(name, 'defect', 5, 9, 24);
    otherwise
      LOCAL_raise('MESH_INVALID', sprintf('Unknown mesh %s.', name));
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

function LOCAL_marker(output_dir, mesh_id, marker)
  LOCAL_log(output_dir, sprintf('CORE_MARKER\t%s\t%s', mesh_id, marker));
end

function LOCAL_raise(code, message)
  error(['I4C:' code], '%s', message);
end

function [code, message] = LOCAL_decode_failure(caught)
  message = caught.message;
  prefix = 'I4C:';
  if startsWith(caught.identifier, prefix)
    code = extractAfter(caught.identifier, prefix);
  else
    code = 'EXECUTION_UNAVAILABLE';
  end
end

function yes = LOCAL_is_scientific_failure(code)
  yes = any(strcmp(code, {'MESH_INVALID', 'MESH_QUALITY_UNRESOLVED', ...
    'DISCRETE_IMPLEMENTATION_INVALID', 'QUASIPERIODIC_MAP_INVALID', ...
    'QUASIPERIODIC_SEAM_UNRESOLVED', 'MASS_NOT_SPD', ...
    'SPECTRUM_INVENTORY_TRUNCATED', 'NUMERICAL_OBJECT_INVALID', ...
    'TRACKING_DIAGNOSTIC_UNAVAILABLE'}));
end

function LOCAL_atomic_save(path, payload)
  temporary = [path '.partial'];
  if exist(path, 'file') || exist(temporary, 'file')
    LOCAL_raise('OUTPUT_COLLISION', sprintf('%s already exists.', path));
  end
  save(temporary, '-struct', 'payload', '-v7.3');
  [moved, message] = movefile(temporary, path);
  if ~moved
    LOCAL_raise('OUTPUT_UNAVAILABLE', message);
  end
end

%% ==================== Actual-only representation preflight ====================
% Section 23.4 builds four real extrema and performs zero eig/eigs/svd calls.

function LOCAL_preflight(spec, output_dir)
  table_path = fullfile(output_dir, 'representation.tsv');
  if exist(table_path, 'file')
    LOCAL_raise('OUTPUT_COLLISION', 'representation.tsv already exists.');
  end
  table_id = fopen(table_path, 'w');
  if table_id < 0
    LOCAL_raise('OUTPUT_UNAVAILABLE', 'Cannot create representation.tsv.');
  end
  cleanup = onCleanup(@() fclose(table_id)); %#ok<NASGU>
  fprintf(table_id, ['mesh_id\tV\tT\tE\tfull_dof\treduced_dof\t' ...
    'nnz_K\tnnz_M\tpermutation_valid\tfactor_nnz\tstatus\n']);
  names = {'bulk-s9-g24', 'defect-N4-s12-g24', ...
    'defect-N4-s9-g32', 'defect-N5-s9-g24'};
  phases = [pi / 2, pi / 4, pi / 4, pi / 4];
  terminal = 'PREFLIGHT_COMPLETE';
  for index = 1:numel(names)
    try
      LOCAL_marker(output_dir, names{index}, 'BUILD_BEGIN');
      mesh = LOCAL_build_mesh(spec, LOCAL_named_mesh(names{index}));
      LOCAL_marker(output_dir, names{index}, 'BUILD_END');
      [pair, diagnostic] = LOCAL_preflight_pair( ...
        spec, mesh, phases(index), output_dir);
      fprintf(table_id, '%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\tPASS:%s/%s\n', ...
        names{index}, size(mesh.points, 1), size(mesh.triangles, 1), ...
        size(mesh.edges, 1), size(mesh.p2_points, 1), ...
        size(pair.mass, 1), nnz(pair.stiffness), nnz(pair.mass), ...
        diagnostic.permutation_valid, diagnostic.factor_nnz, ...
        mesh.connectivity_authority, mesh.parity_authority);
      LOCAL_log(output_dir, sprintf( ...
        'REPRESENTATION_AUTHORITY\t%s\t%s\t%s\t%s', names{index}, ...
        mesh.connectivity_authority, ...
        mesh.parity_authority, mesh.geometry_reflection_status));
      clear pair mesh
      LOCAL_marker(output_dir, names{index}, 'RELEASED');
    catch caught
      [code, message] = LOCAL_decode_failure(caught);
      fprintf(table_id, '%s\t0\t0\t0\t0\t0\t0\t0\t0\t0\t%s\n', ...
        names{index}, code);
      LOCAL_log(output_dir, sprintf('PREFLIGHT_FAILURE\t%s\t%s', ...
        code, message));
      terminal = code;
      break;
    end
  end
  LOCAL_log(output_dir, sprintf('PREFLIGHT_TERMINAL\t%s', terminal));
end

function [pair, diagnostic] = LOCAL_preflight_pair( ...
    spec, mesh, phase_x, output_dir)
  [prolongation, phases] = LOCAL_phase_prolongation( ...
    mesh.periodic, phase_x, spec.beta);
  LOCAL_check_seam(spec, mesh, prolongation, phase_x);
  LOCAL_marker(output_dir, mesh.id, 'REDUCE_K_BEGIN');
  stiffness = LOCAL_checked_operator(spec, ...
    prolongation' * mesh.stiffness_full * prolongation, ...
    'DISCRETE_IMPLEMENTATION_INVALID');
  LOCAL_marker(output_dir, mesh.id, 'REDUCE_K_END');
  LOCAL_marker(output_dir, mesh.id, 'REDUCE_M_BEGIN');
  mass = LOCAL_checked_operator(spec, ...
    prolongation' * mesh.mass_full * prolongation, ...
    'DISCRETE_IMPLEMENTATION_INVALID');
  LOCAL_marker(output_dir, mesh.id, 'REDUCE_M_END');
  LOCAL_marker(output_dir, mesh.id, 'SPD_BEGIN');
  spd = LOCAL_mass_spd(mass, 'MASS_NOT_SPD');
  LOCAL_marker(output_dir, mesh.id, 'SPD_END');
  pair = struct('stiffness', stiffness, 'mass', mass, ...
    'prolongation', prolongation);
  diagnostic = struct('permutation_valid', spd.permutation_valid, ...
    'factor_nnz', spd.factor_nnz, 'phase_factor_min', min(abs(phases)), ...
    'phase_factor_max', max(abs(phases)));
end

%% ==================== Preliminary-first formal orchestration ====================
% Sections 23.3--23.7 freeze the winner before any refinement is attempted.

function LOCAL_formal(spec, output_dir)
  work_dir = fullfile(output_dir, 'work');
  if exist(work_dir, 'dir') || exist(work_dir, 'file')
    LOCAL_raise('OUTPUT_COLLISION', 'The current-run work directory exists.');
  end
  [made, message] = mkdir(work_dir);
  if ~made
    LOCAL_raise('OUTPUT_UNAVAILABLE', message);
  end
  state = struct('attempted_solves', 0, 'completed_solves', 0, ...
    'planned_solves', 61, 'maximum_solves', 66, ...
    'failures', struct('stage', {}, 'phase', {}, 'code', {}, 'reason', {}));
  preliminary_published = false;
  try
    LOCAL_validate_assignment_fixtures();
    LOCAL_log(output_dir, 'CORE_STAGE\tPRELIMINARY\tBEGIN');
    anchor_mesh = LOCAL_build_mesh(spec, LOCAL_named_mesh('p2-anchor'));
    [entries, state] = LOCAL_solve_slices(spec, anchor_mesh, ...
      spec.theta_5, spec.tight_tolerance, spec.defect_nev, ...
      'PRELIMINARY', state);
    entries = LOCAL_prepare_primary_authority(spec, entries);
    [objects, slices] = LOCAL_collect_objects( ...
      spec, anchor_mesh, entries, 'p2-anchor', 1);
    [selection, tracking] = LOCAL_preliminary_selection(spec, objects, slices, entries);
    needs_extension = LOCAL_needs_extension(spec, entries) || isempty(selection);
    if needs_extension
      LOCAL_log(output_dir, 'CORE_STAGE\tPRELIMINARY_EXTENSION\tBEGIN');
      state.planned_solves = 66;
      [expanded, state] = LOCAL_solve_slices(spec, anchor_mesh, ...
        spec.theta_5, spec.tight_tolerance, spec.expanded_nev, ...
        'PRELIMINARY_EXTENSION', state);
      [entries, state] = LOCAL_apply_extension( ...
        spec, anchor_mesh, entries, expanded, state);
      clear expanded
      [objects, slices] = LOCAL_collect_objects( ...
        spec, anchor_mesh, entries, 'p2-anchor', 1);
      [selection, tracking] = ...
        LOCAL_preliminary_selection(spec, objects, slices, entries);
    end
    if isempty(selection)
      LOCAL_write_terminal(work_dir, state, ...
        'NO_THREE_CONSECUTIVE_PRELIMINARY_BRANCH', ...
        'SCIENTIFIC_NEGATIVE', NaN, NaN);
      LOCAL_log(output_dir, ...
        'CORE_STAGE\tPRELIMINARY\tSCIENTIFIC_NEGATIVE');
      return;
    end
    [lambda_pre, k_pre] = LOCAL_component_scalar(objects, ...
      selection.object_ids);
    LOCAL_publish_preliminary(output_dir, spec, anchor_mesh, entries, ...
      objects, tracking, selection, lambda_pre, k_pre);
    preliminary_published = true;
    LOCAL_log(output_dir, 'CORE_STAGE\tPRELIMINARY\tPUBLISHED');

    reference_objects = objects(selection.object_ids);
    reference_selection = selection;
    reference_selection.object_ids = 1:numel(reference_objects);
    clear objects slices tracking entries selection
    refinement = LOCAL_refinement_schedule(spec, output_dir, ...
      anchor_mesh, reference_objects, reference_selection, reference_objects, ...
      k_pre, state);
    state = refinement.state;
    LOCAL_publish_refinement(output_dir, spec, refinement);
    if strcmp(refinement.resolution_status, 'EMPIRICAL_RESOLUTION_COMPLETE')
      terminal = 'P2_EMPIRICAL_REFERENCE_REFINEMENT_COMPLETE';
      claim = spec.complete_claim;
    else
      terminal = 'P2_EMPIRICAL_REFERENCE_REFINEMENT_PARTIAL';
      claim = spec.partial_claim;
    end
    LOCAL_write_terminal(work_dir, state, terminal, claim, lambda_pre, k_pre);
    LOCAL_log(output_dir, sprintf('CORE_TERMINAL\t%s', terminal));
  catch caught
    [code, reason] = LOCAL_decode_failure(caught);
    LOCAL_log(output_dir, sprintf('CORE_FAILURE\t%s\t%s', code, reason));
    if ~LOCAL_is_scientific_failure(code)
      LOCAL_write_terminal(work_dir, state, code, ...
        'OPERATIONAL_OR_RESOURCE_FAILURE', NaN, NaN);
      rethrow(caught);
    end
    LOCAL_write_terminal(work_dir, state, code, ...
      'SCIENTIFIC_NEGATIVE / NONCERTIFIED / NO CONTINUOUS EXISTENCE CLAIM / NO EFFECTIVITY', ...
      NaN, NaN);
    if preliminary_published
      LOCAL_log(output_dir, ...
        'CORE_TERMINAL\tPRELIMINARY_PRESERVED_REFINEMENT_FAILED');
    end
  end
end

function [entries, state] = LOCAL_solve_slices( ...
    spec, mesh, phases, tolerance, requested_nev, stage, state)
  entries = repmat(struct('phase', 0, 'valid', false, 'spectrum', [], ...
    'code', '', 'reason', '', 'roots_48_evidence', struct([]), ...
    'roots_60_evidence', struct([]), 'agreement', struct([]), ...
    'active_authority', 'none', 'active_root_count', 0, ...
    'coverage_classification', 'SPECTRUM_COVERAGE_PARTIAL'), ...
    1, numel(phases));
  for index = 1:numel(phases)
    entries(index).phase = phases(index);
    state.attempted_solves = state.attempted_solves + 1;
    try
      entries(index).spectrum = LOCAL_low_spectrum( ...
        spec, mesh, phases(index), tolerance, requested_nev, stage);
      entries(index).valid = true;
      state.completed_solves = state.completed_solves + 1;
    catch caught
      [code, reason] = LOCAL_decode_failure(caught);
      if ~LOCAL_is_scientific_failure(code)
        rethrow(caught);
      end
      entries(index).code = code;
      entries(index).reason = reason;
      state.failures(end + 1) = struct('stage', stage, ...
        'phase', phases(index), 'code', code, 'reason', reason); %#ok<AGROW>
    end
  end
end

function entries = LOCAL_prepare_primary_authority(spec, entries)
  for index = 1:numel(entries)
    entries(index).roots_48_evidence = LOCAL_spectrum_evidence(entries(index));
    entries(index).roots_60_evidence = LOCAL_empty_spectrum_evidence();
    entries(index).agreement = LOCAL_empty_expansion_agreement(spec);
    entries(index).agreement.primary_valid = entries(index).valid;
    if entries(index).valid
      entries(index).active_authority = 'roots-48';
      entries(index).active_root_count = spec.defect_nev;
      entries(index).coverage_classification = LOCAL_coverage_classification( ...
        spec, entries(index).spectrum);
      entries(index).agreement.active_authority = 'roots-48';
      entries(index).agreement.active_root_count = spec.defect_nev;
      entries(index).agreement.coverage_classification = ...
        entries(index).coverage_classification;
    end
  end
end

function yes = LOCAL_needs_extension(spec, entries)
  yes = false;
  for index = 1:numel(entries)
    if entries(index).valid && ...
        entries(index).spectrum.frequencies(end) < spec.coverage_ceiling
      yes = true;
      return;
    end
  end
end

function [entries, state] = LOCAL_apply_extension( ...
    spec, mesh, entries, expanded, state)
  for index = 1:numel(entries)
    entries(index).roots_60_evidence = ...
      LOCAL_spectrum_evidence(expanded(index));
    primary_evidence = entries(index).roots_48_evidence;
    expansion_evidence = entries(index).roots_60_evidence;
    agreement = LOCAL_empty_expansion_agreement(spec);
    agreement.attempted = true;
    agreement.primary_valid = entries(index).valid;
    agreement.expansion_valid = expanded(index).valid;
    if agreement.primary_valid
      [agreement.primary_cluster_boundaries, ...
        agreement.primary_cluster_multiplicities] = ...
        LOCAL_cluster_partition(entries(index).spectrum.cluster_ids);
    end
    if agreement.expansion_valid
      [agreement.expansion_cluster_boundaries, ...
        agreement.expansion_cluster_multiplicities] = ...
        LOCAL_cluster_partition(expanded(index).spectrum.cluster_ids( ...
        1:spec.defect_nev));
    end
    if ~entries(index).valid
      agreement.status = 'SPECTRUM_EXPANSION_INCONSISTENT';
      agreement.active_authority = 'none';
      agreement.coverage_classification = 'SPECTRUM_COVERAGE_PARTIAL';
      entries(index).agreement = agreement;
      entries(index).coverage_classification = ...
        'SPECTRUM_COVERAGE_PARTIAL';
      state = LOCAL_record_expansion_status(state, entries(index).phase, ...
        'The immutable 48-root primary spectrum is invalid.');
      continue;
    end
    if ~expanded(index).valid
      agreement.status = 'SPECTRUM_EXPANSION_INCONSISTENT';
      agreement.active_authority = 'roots-48';
      agreement.active_root_count = spec.defect_nev;
      agreement.coverage_classification = 'SPECTRUM_COVERAGE_PARTIAL';
      entries(index).agreement = agreement;
      entries(index).active_authority = 'roots-48';
      entries(index).active_root_count = spec.defect_nev;
      entries(index).coverage_classification = ...
        'SPECTRUM_COVERAGE_PARTIAL';
      entries(index).code = 'SPECTRUM_EXPANSION_INCONSISTENT';
      entries(index).reason = sprintf('60-root solve invalid: %s %s', ...
        expanded(index).code, expanded(index).reason);
      state = LOCAL_record_expansion_status( ...
        state, entries(index).phase, entries(index).reason);
      continue;
    end
    old = entries(index).spectrum;
    new = expanded(index).spectrum;
    agreement.frequency_max_abs_defect = max(abs(old.frequencies - ...
      new.frequencies(1:spec.defect_nev)));
    agreement.cluster_membership_match = isequal( ...
      old.cluster_ids, new.cluster_ids(1:spec.defect_nev)) && ...
      isequal(agreement.primary_cluster_boundaries, ...
      agreement.expansion_cluster_boundaries) && ...
      isequal(agreement.primary_cluster_multiplicities, ...
      agreement.expansion_cluster_multiplicities);
    if agreement.cluster_membership_match
      cluster_count = size(agreement.primary_cluster_boundaries, 1);
      agreement.cluster_min_principal_overlaps = NaN(cluster_count, 1);
      for cluster_index = 1:cluster_count
        roots = agreement.primary_cluster_boundaries(cluster_index, 1): ...
          agreement.primary_cluster_boundaries(cluster_index, 2);
        singular_values = svd(old.vectors_full(:, roots)' * ...
          mesh.mass_full * new.vectors_full(:, roots));
        agreement.cluster_min_principal_overlaps(cluster_index) = ...
          min(singular_values);
      end
      agreement.minimum_principal_overlap = ...
        min(agreement.cluster_min_principal_overlaps);
    end
    agreement.pass = agreement.frequency_max_abs_defect <= ...
      spec.expansion_frequency_tolerance && ...
      agreement.cluster_membership_match && ...
      agreement.minimum_principal_overlap >= ...
      1 - spec.expansion_overlap_tolerance;
    if agreement.pass
      entries(index) = expanded(index);
      entries(index).roots_48_evidence = primary_evidence;
      entries(index).roots_60_evidence = expansion_evidence;
      entries(index).active_authority = 'roots-60';
      entries(index).active_root_count = spec.expanded_nev;
      entries(index).coverage_classification = ...
        LOCAL_coverage_classification(spec, new);
      agreement.status = 'SPECTRUM_EXPANSION_CONSISTENT';
      agreement.active_authority = 'roots-60';
      agreement.active_root_count = spec.expanded_nev;
      agreement.coverage_classification = ...
        entries(index).coverage_classification;
    else
      entries(index).active_authority = 'roots-48';
      entries(index).active_root_count = spec.defect_nev;
      entries(index).coverage_classification = ...
        'SPECTRUM_COVERAGE_PARTIAL';
      entries(index).code = 'SPECTRUM_EXPANSION_INCONSISTENT';
      entries(index).reason = sprintf( ...
        'frequency %.3e, cluster match %d, minimum overlap %.3e', ...
        agreement.frequency_max_abs_defect, ...
        agreement.cluster_membership_match, ...
        agreement.minimum_principal_overlap);
      agreement.status = 'SPECTRUM_EXPANSION_INCONSISTENT';
      agreement.active_authority = 'roots-48';
      agreement.active_root_count = spec.defect_nev;
      agreement.coverage_classification = 'SPECTRUM_COVERAGE_PARTIAL';
      state = LOCAL_record_expansion_status( ...
        state, entries(index).phase, entries(index).reason);
    end
    entries(index).agreement = agreement;
    clear old new singular_values
  end
end

function evidence = LOCAL_empty_spectrum_evidence()
  evidence = struct('valid', false, 'failure_code', 'NOT_ATTEMPTED', ...
    'failure_reason', '', 'summary', struct([]));
end

function evidence = LOCAL_spectrum_evidence(entry)
  evidence = LOCAL_empty_spectrum_evidence();
  evidence.valid = entry.valid;
  evidence.failure_code = entry.code;
  evidence.failure_reason = entry.reason;
  if entry.valid
    evidence.summary = entry.spectrum;
    evidence.summary = rmfield(evidence.summary, 'vectors_full');
  end
end

function agreement = LOCAL_empty_expansion_agreement(spec)
  agreement = struct('attempted', false, 'primary_valid', false, ...
    'expansion_valid', false, 'pass', false, ...
    'frequency_max_abs_defect', NaN, ...
    'frequency_tolerance', spec.expansion_frequency_tolerance, ...
    'primary_cluster_boundaries', zeros(0, 2), ...
    'expansion_cluster_boundaries', zeros(0, 2), ...
    'primary_cluster_multiplicities', zeros(0, 1), ...
    'expansion_cluster_multiplicities', zeros(0, 1), ...
    'cluster_membership_match', false, ...
    'cluster_min_principal_overlaps', zeros(0, 1), ...
    'minimum_principal_overlap', NaN, ...
    'minimum_overlap_required', 1 - spec.expansion_overlap_tolerance, ...
    'status', 'NOT_ATTEMPTED', 'active_authority', 'none', ...
    'active_root_count', 0, ...
    'coverage_classification', 'SPECTRUM_COVERAGE_PARTIAL');
end

function [boundaries, multiplicities] = LOCAL_cluster_partition(cluster_ids)
  cluster_ids = cluster_ids(:);
  starts = [1; find(diff(cluster_ids) ~= 0) + 1];
  stops = [starts(2:end) - 1; numel(cluster_ids)];
  boundaries = [starts, stops];
  multiplicities = stops - starts + 1;
end

function classification = LOCAL_coverage_classification(spec, spectrum)
  if spectrum.frequencies(end) >= spec.coverage_ceiling
    classification = 'SPECTRUM_COVERED_THROUGH_W3';
  else
    classification = 'SPECTRUM_COVERAGE_PARTIAL';
  end
end

function state = LOCAL_record_expansion_status(state, phase, reason)
  state.failures(end + 1) = struct('stage', 'PRELIMINARY_EXTENSION', ...
    'phase', phase, 'code', 'SPECTRUM_EXPANSION_INCONSISTENT', ...
    'reason', reason);
end

function [objects, slices] = LOCAL_collect_objects( ...
    spec, mesh, entries, configuration, first_object_id)
  objects = LOCAL_empty_objects();
  slices = repmat(struct('phase', 0, 'object_ids', []), 1, numel(entries));
  next_id = first_object_id;
  for index = 1:numel(entries)
    slices(index).phase = entries(index).phase;
    if ~entries(index).valid
      continue;
    end
    current = LOCAL_objects_from_spectrum( ...
      spec, mesh, entries(index).spectrum, configuration, index);
    for object_index = 1:numel(current)
      current(object_index).object_id = next_id;
      slices(index).object_ids(end + 1) = next_id; %#ok<AGROW>
      objects(end + 1) = current(object_index); %#ok<AGROW>
      next_id = next_id + 1;
    end
  end
end

function objects = LOCAL_objects_from_spectrum( ...
    spec, mesh, spectrum, configuration, theta_index)
  objects = LOCAL_empty_objects();
  cluster_numbers = unique(spectrum.cluster_ids).';
  for cluster_id = cluster_numbers
    roots = find(spectrum.cluster_ids == cluster_id);
    envelope = [min(spectrum.frequencies(roots)), ...
      max(spectrum.frequencies(roots))];
    if envelope(2) < spec.w3(1) || envelope(1) > spec.w3(2)
      continue;
    end
    try
      subspace = spectrum.vectors_full(:, roots);
      gram = LOCAL_checked_operator(spec, ...
        subspace' * mesh.mass_full * subspace, 'NUMERICAL_OBJECT_INVALID');
      if norm(gram - eye(numel(roots)), 2) > spec.orthogonality_tolerance
        LOCAL_raise('NUMERICAL_OBJECT_INVALID', ...
          'A W3 field cluster is not mass normalized.');
      end
      [samples, weights, parity_grid] = ...
        LOCAL_sample_subspace(spec, mesh, subspace);
      sample_gram = LOCAL_checked_operator(spec, ...
        samples' * (weights .* samples), 'NUMERICAL_OBJECT_INVALID');
      factor = chol(sample_gram);
      samples = samples / factor;
      clear factor
      localization = [NaN, NaN, NaN];
      localization_status = 'UNAVAILABLE';
      try
        center = eig(LOCAL_checked_operator(spec, ...
          subspace' * mesh.mass_center * subspace, ...
          'LOCALIZATION_DIAGNOSTIC_UNAVAILABLE'));
        core = eig(LOCAL_checked_operator(spec, ...
          subspace' * mesh.mass_core * subspace, ...
          'LOCALIZATION_DIAGNOSTIC_UNAVAILABLE'));
        tail = eig(LOCAL_checked_operator(spec, ...
          subspace' * mesh.mass_tail * subspace, ...
          'LOCALIZATION_DIAGNOSTIC_UNAVAILABLE'));
        localization = [min(real(center)), min(real(core)), max(real(tail))];
        localization_status = 'AVAILABLE';
      catch caught
        [localization_code, ~] = LOCAL_decode_failure(caught);
        if ~strcmp(localization_code, ...
            'LOCALIZATION_DIAGNOSTIC_UNAVAILABLE')
          rethrow(caught);
        end
      end
      parity_label = 'parity-unavailable';
      parity_status = 'UNAVAILABLE';
      parity_values = [];
      parity_invariance_defect = NaN;
      parity_reason = parity_grid.reason;
      if abs(spectrum.phase) < 1e-13 || abs(spectrum.phase - pi) < 1e-13
        try
          [parity_values, parity_invariance_defect] = ...
            LOCAL_common_grid_parity(spec, samples, weights, parity_grid);
          parity_label = LOCAL_parity_label( ...
            parity_values, spec.parity_threshold);
          parity_status = 'AVAILABLE';
          parity_reason = 'EMPIRICAL_COMMON_GRID_PARITY';
        catch caught
          [parity_code, parity_message] = LOCAL_decode_failure(caught);
          if ~strcmp(parity_code, 'PARITY_DIAGNOSTIC_UNAVAILABLE')
            rethrow(caught);
          end
          parity_reason = parity_message;
        end
      else
        parity_reason = 'NOT_ENDPOINT_TWIST';
      end
      object = LOCAL_empty_object();
      object.configuration = configuration;
      object.theta_index = theta_index;
      object.phase = spectrum.phase;
      object.cluster_id = cluster_id;
      object.root_index = roots(1);
      object.root_indices = roots;
      object.dimension = numel(roots);
      object.eigenvalues = spectrum.eigenvalues(roots);
      object.frequencies = spectrum.frequencies(roots);
      object.lambda_envelope = [min(object.eigenvalues), ...
        max(object.eigenvalues)];
      object.k_envelope = envelope;
      object.residual_max = max(spectrum.residuals(roots));
      object.subspace = subspace;
      object.common_core_samples = samples;
      object.common_core_weights = weights;
      object.L0_min = localization(1);
      object.Lcore_min = localization(2);
      object.tail_max = localization(3);
      object.localization_status = localization_status;
      object.parity_label = parity_label;
      object.parity_status = parity_status;
      object.parity_values = parity_values;
      object.parity_invariance_defect = parity_invariance_defect;
      object.parity_grid_status = parity_grid.status;
      object.parity_method = 'EMPIRICAL_COMMON_GRID_PARITY';
      object.parity_reason = parity_reason;
      objects(end + 1) = object; %#ok<AGROW>
    catch caught
      [code, ~] = LOCAL_decode_failure(caught);
      if ~LOCAL_is_scientific_failure(code)
        rethrow(caught);
      end
      % A numerically invalid field object is excluded without cancelling peers.
    end
  end
end

function objects = LOCAL_empty_objects()
  objects = struct('object_id', {}, 'configuration', {}, ...
    'theta_index', {}, 'phase', {}, 'cluster_id', {}, 'root_index', {}, ...
    'root_indices', {}, 'dimension', {}, 'eigenvalues', {}, ...
    'frequencies', {}, 'lambda_envelope', {}, 'k_envelope', {}, ...
    'residual_max', {}, 'subspace', {}, 'common_core_samples', {}, ...
    'common_core_weights', {}, 'L0_min', {}, 'Lcore_min', {}, ...
    'tail_max', {}, 'localization_status', {}, 'parity_label', {}, ...
    'parity_status', {}, 'parity_values', {}, ...
    'parity_invariance_defect', {}, 'parity_grid_status', {}, ...
    'parity_method', {}, 'parity_reason', {});
end

function object = LOCAL_empty_object()
  empty = LOCAL_empty_objects();
  object = struct();
  names = fieldnames(empty);
  for index = 1:numel(names)
    object.(names{index}) = [];
  end
end

function [selection, tracking] = LOCAL_preliminary_selection( ...
    spec, objects, slices, entries)
  selection = [];
  edges = LOCAL_empty_edges();
  for index = 2:numel(slices)
    edges = [edges, LOCAL_assign_sets(objects, ...
      slices(index - 1).object_ids, slices(index).object_ids, ...
      'twist')]; %#ok<AGROW>
  end
  if isempty(objects)
    tracking = struct('edges', edges, 'components', struct([]));
    return;
  end
  tracking = LOCAL_tracking_components(objects, edges);
  missing_ceiling = sum(arrayfun(@(entry) ~entry.valid || ...
    entry.spectrum.frequencies(end) < spec.coverage_ceiling, entries));
  candidates = struct('object_ids', {}, 'rank_key', {}, ...
    'classification', {});
  for index = 1:numel(tracking.components)
    ids = tracking.components(index).realization_ids;
    theta = sort(unique([objects(ids).theta_index]));
    if LOCAL_longest_consecutive(theta) < 3
      continue;
    end
    component_edges = edges([edges.real_pair] & ...
      ismember([edges.source_object_id], ids) & ...
      ismember([edges.target_object_id], ids));
    if numel(component_edges) < 2
      continue;
    end
    overlap_values = [component_edges.overlap];
    overlap_values = overlap_values(isfinite(overlap_values));
    if isempty(overlap_values)
      overlap_min = -Inf;
    else
      overlap_min = min(overlap_values);
    end
    residual_max = max([objects(ids).residual_max]);
    core = [objects(ids).Lcore_min];
    core = core(isfinite(core));
    if isempty(core)
      core_min = -Inf;
    else
      core_min = min(core);
    end
    parity_penalty = LOCAL_component_parity_penalty(objects(ids));
    lambda_envelope = [min(cellfun(@min, {objects(ids).eigenvalues})), ...
      max(cellfun(@max, {objects(ids).eigenvalues}))];
    rank_key = [-numel(theta), -numel(component_edges), -overlap_min, ...
      residual_max, missing_ceiling, -core_min, parity_penalty, ...
      diff(lambda_envelope), min([objects(ids).object_id])];
    classification = LOCAL_component_classification(spec, ...
      objects(ids), overlap_min);
    candidates(end + 1) = struct('object_ids', ids, ...
      'rank_key', rank_key, 'classification', {classification}); %#ok<AGROW>
  end
  if isempty(candidates)
    return;
  end
  keys = vertcat(candidates.rank_key);
  [~, order] = sortrows(keys, 1:size(keys, 2));
  selection = candidates(order(1));
end

function count = LOCAL_longest_consecutive(values)
  if isempty(values)
    count = 0;
    return;
  end
  count = 1;
  current = 1;
  for index = 2:numel(values)
    if values(index) == values(index - 1) + 1
      current = current + 1;
      count = max(count, current);
    else
      current = 1;
    end
  end
end

function penalty = LOCAL_component_parity_penalty(objects)
  endpoint = objects(abs([objects.phase]) < 1e-13 | ...
    abs([objects.phase] - pi) < 1e-13);
  if isempty(endpoint) || any(~strcmp({endpoint.parity_status}, 'AVAILABLE'))
    penalty = 2;
    return;
  end
  labels = unique({endpoint.parity_label});
  if numel(labels) == 1 && any(strcmp(labels{1}, {'even', 'odd'}))
    penalty = 0;
  else
    penalty = 1;
  end
end

function labels = LOCAL_component_classification(spec, objects, overlap_min)
  labels = {'field-tracked', 'noncertified', 'no-effectivity'};
  core = [objects.Lcore_min];
  if isempty(core) || any(~isfinite(core))
    labels{end + 1} = 'localization-unavailable';
  elseif min(core) < spec.localization_core_min
    labels{end + 1} = 'weak-localization';
  end
  if ~isfinite(overlap_min) || overlap_min < spec.cluster_overlap_min
    labels{end + 1} = 'weak-overlap';
  end
  if LOCAL_component_parity_penalty(objects) == 2
    labels{end + 1} = 'parity-unavailable';
  end
end

function [lambda_value, k_value] = LOCAL_component_scalar(objects, ids)
  lower = min(cellfun(@min, {objects(ids).eigenvalues}));
  upper = max(cellfun(@max, {objects(ids).eigenvalues}));
  lambda_value = (lower + upper) / 2;
  k_value = sqrt(lambda_value);
end

function edges = LOCAL_empty_edges()
  edges = struct('source_object_id', {}, 'target_object_id', {}, ...
    'axis', {}, 'overlap', {}, 'frequency_distance', {}, ...
    'real_pair', {}, 'assignment_kind', {}, 'cost_tuple', {}, ...
    'exact_tie', {});
end

function edges = LOCAL_assign_sets(objects, source_ids, target_ids, axis)
  edges = LOCAL_empty_edges();
  if isempty(source_ids) || isempty(target_ids)
    return;
  end
  overlap = NaN(numel(source_ids), numel(target_ids));
  distance = NaN(size(overlap));
  for first = 1:numel(source_ids)
    for second = 1:numel(target_ids)
      overlap(first, second) = LOCAL_common_core_overlap( ...
        objects(source_ids(first)), objects(target_ids(second)));
      distance(first, second) = LOCAL_envelope_distance( ...
        objects(source_ids(first)).k_envelope, ...
        objects(target_ids(second)).k_envelope);
    end
  end
  [assignment, costs, exact_tie] = LOCAL_maximum_overlap_assignment( ...
    objects, source_ids, target_ids, overlap, distance);
  for row = 1:numel(assignment)
    column = assignment(row);
    real_pair = row <= numel(source_ids) && column <= numel(target_ids);
    source_id = 0;
    target_id = 0;
    pair_overlap = NaN;
    pair_distance = NaN;
    if real_pair
      source_id = source_ids(row);
      target_id = target_ids(column);
      pair_overlap = overlap(row, column);
      pair_distance = distance(row, column);
      kind = 'REAL_PAIR';
    elseif row <= numel(source_ids)
      source_id = source_ids(row);
      kind = 'DEATH';
    elseif column <= numel(target_ids)
      target_id = target_ids(column);
      kind = 'BIRTH';
    else
      kind = 'DUMMY_DUMMY';
    end
    edges(end + 1) = struct('source_object_id', source_id, ...
      'target_object_id', target_id, 'axis', axis, ...
      'overlap', pair_overlap, 'frequency_distance', pair_distance, ...
      'real_pair', real_pair, 'assignment_kind', kind, ...
      'cost_tuple', reshape(costs(row, column, :), 1, []), ...
      'exact_tie', exact_tie); %#ok<AGROW>
  end
end

function overlap = LOCAL_common_core_overlap(first_object, second_object)
  if numel(first_object.common_core_weights) ~= ...
      numel(second_object.common_core_weights) || ...
      max(abs(first_object.common_core_weights - ...
      second_object.common_core_weights)) > 1e-14
    LOCAL_raise('TRACKING_DIAGNOSTIC_UNAVAILABLE', ...
      'Common-grid weights differ.');
  end
  singular_values = svd(first_object.common_core_samples' * ...
    (first_object.common_core_weights .* ...
    second_object.common_core_samples));
  dimension = min(first_object.dimension, second_object.dimension);
  overlap = sum(singular_values(1:dimension) .^ 2) / dimension;
end

function LOCAL_publish_preliminary(output_dir, spec, mesh, entries, ...
    objects, tracking, selection, lambda_pre, k_pre)
  compact_objects = LOCAL_compact_objects(objects);
  compact_entries = LOCAL_compact_entries(entries);
  spectrum_authority = LOCAL_spectrum_authority_table(entries);
  if any(strcmp({spectrum_authority.coverage_classification}, ...
      'SPECTRUM_COVERAGE_PARTIAL'))
    coverage_classification = 'SPECTRUM_COVERAGE_PARTIAL';
  else
    coverage_classification = 'SPECTRUM_COVERED_THROUGH_W3';
  end
  result = struct('spec', spec, 'entries', compact_entries, ...
    'spectrum_authority', spectrum_authority, ...
    'coverage_classification', coverage_classification, ...
    'objects', compact_objects, 'tracking', tracking, ...
    'selection', selection, 'lambda_pre', lambda_pre, 'k_pre', k_pre, ...
    'claim_boundary', spec.preliminary_claim);
  LOCAL_atomic_save(fullfile(output_dir, 'preliminary-result.mat'), result);
  selected = objects(selection.object_ids);
  fields = struct('mesh_id', mesh.id, 'points', mesh.points, ...
    'triangles', mesh.triangles, 'edges', mesh.edges, ...
    'triangle_p2', mesh.triangle_p2, 'p2_points', mesh.p2_points, ...
    'objects', selected, 'claim_boundary', spec.preliminary_claim);
  LOCAL_atomic_save(fullfile(output_dir, 'preliminary-fields.mat'), fields);
end

function table = LOCAL_spectrum_authority_table(entries)
  table = struct('phase', {}, 'primary_valid', {}, ...
    'expansion_attempted', {}, 'expansion_valid', {}, ...
    'agreement_status', {}, 'frequency_max_abs_defect', {}, ...
    'primary_cluster_boundaries', {}, ...
    'expansion_cluster_boundaries', {}, ...
    'primary_cluster_multiplicities', {}, ...
    'expansion_cluster_multiplicities', {}, ...
    'cluster_membership_match', {}, ...
    'cluster_min_principal_overlaps', {}, ...
    'minimum_principal_overlap', {}, 'active_authority', {}, ...
    'active_root_count', {}, 'coverage_classification', {});
  for index = 1:numel(entries)
    agreement = entries(index).agreement;
    table(end + 1) = struct('phase', entries(index).phase, ...
      'primary_valid', agreement.primary_valid, ...
      'expansion_attempted', agreement.attempted, ...
      'expansion_valid', agreement.expansion_valid, ...
      'agreement_status', agreement.status, ...
      'frequency_max_abs_defect', agreement.frequency_max_abs_defect, ...
      'primary_cluster_boundaries', agreement.primary_cluster_boundaries, ...
      'expansion_cluster_boundaries', ...
      agreement.expansion_cluster_boundaries, ...
      'primary_cluster_multiplicities', ...
      agreement.primary_cluster_multiplicities, ...
      'expansion_cluster_multiplicities', ...
      agreement.expansion_cluster_multiplicities, ...
      'cluster_membership_match', agreement.cluster_membership_match, ...
      'cluster_min_principal_overlaps', ...
      agreement.cluster_min_principal_overlaps, ...
      'minimum_principal_overlap', agreement.minimum_principal_overlap, ...
      'active_authority', entries(index).active_authority, ...
      'active_root_count', entries(index).active_root_count, ...
      'coverage_classification', ...
      entries(index).coverage_classification); %#ok<AGROW>
  end
end

function compact = LOCAL_compact_entries(entries)
  compact = entries;
  for index = 1:numel(compact)
    if compact(index).valid
      compact(index).spectrum = rmfield(compact(index).spectrum, 'vectors_full');
    end
  end
end

function compact = LOCAL_compact_objects(objects)
  compact = objects;
  for index = 1:numel(compact)
    compact(index).subspace = [];
    compact(index).common_core_samples = [];
    compact(index).common_core_weights = [];
  end
end

%% ==================== Fixed refinement and bulk continuation ====================
% Refinement failures are local and cannot change the preliminary winner.

function refinement = LOCAL_refinement_schedule(spec, output_dir, ...
    anchor_mesh, anchor_objects, selection, ...
    reference_objects, k_pre, state)
  scalars = struct('h0', NaN, 'h2', NaN, 'g0', NaN, 'g2', NaN, ...
    'N3', NaN, 'N5', NaN, 'theta9', NaN, 'loose', NaN);
  matched_fields = struct('configuration', {}, 'objects', {});
  configurations = {'p2-h0', 'p2-h2', 'p2-g0', 'p2-g2', 'p2-N3', 'p2-N5'};
  scalar_names = {'h0', 'h2', 'g0', 'g2', 'N3', 'N5'};
  for index = 1:numel(configurations)
    LOCAL_log(output_dir, sprintf('CORE_STAGE\t%s\tBEGIN', ...
      upper(configurations{index})));
    try
      mesh = LOCAL_build_mesh(spec, LOCAL_named_mesh(configurations{index}));
      [entries, state] = LOCAL_solve_slices(spec, mesh, spec.theta_5, ...
        spec.tight_tolerance, spec.defect_nev, ...
        upper(configurations{index}), state);
      [objects, ~] = LOCAL_collect_objects( ...
        spec, mesh, entries, configurations{index}, 1);
      [scalars.(scalar_names{index}), matched] = ...
        LOCAL_matched_scalar(reference_objects, objects);
      if ~isempty(matched)
        matched_fields(end + 1) = struct('configuration', ...
          configurations{index}, 'objects', matched); %#ok<AGROW>
      end
    catch caught
      [code, reason] = LOCAL_decode_failure(caught);
      if ~LOCAL_is_scientific_failure(code)
        rethrow(caught);
      end
      state.failures(end + 1) = struct('stage', configurations{index}, ...
        'phase', NaN, 'code', code, 'reason', reason); %#ok<AGROW>
    end
  end

  LOCAL_log(output_dir, 'CORE_STAGE\tTWIST_REFINEMENT\tBEGIN');
  try
    [added_entries, state] = LOCAL_solve_slices(spec, anchor_mesh, ...
      spec.theta_9_added, spec.tight_tolerance, spec.defect_nev, ...
      'TWIST_REFINEMENT', state);
    [added_objects, ~] = LOCAL_collect_objects( ...
      spec, anchor_mesh, added_entries, 'p2-anchor', ...
      numel(anchor_objects) + 1);
    [scalars.theta9, twist_objects] = LOCAL_twist_scalar( ...
      anchor_objects, added_objects, selection.object_ids);
    if ~isempty(twist_objects)
      matched_fields(end + 1) = struct('configuration', ...
        'p2-anchor-theta9', 'objects', twist_objects); %#ok<AGROW>
    end
  catch caught
    [code, reason] = LOCAL_decode_failure(caught);
    if ~LOCAL_is_scientific_failure(code)
      rethrow(caught);
    end
    state.failures(end + 1) = struct('stage', 'TWIST_REFINEMENT', ...
      'phase', NaN, 'code', code, 'reason', reason); %#ok<AGROW>
  end

  LOCAL_log(output_dir, 'CORE_STAGE\tALGEBRAIC_REFINEMENT\tBEGIN');
  try
    [loose_entries, state] = LOCAL_solve_slices(spec, anchor_mesh, ...
      spec.theta_5, spec.loose_tolerance, spec.defect_nev, ...
      'ALGEBRAIC_REFINEMENT', state);
    [loose_objects, ~] = LOCAL_collect_objects( ...
      spec, anchor_mesh, loose_entries, 'p2-loose', 1);
    [scalars.loose, loose_matched] = ...
      LOCAL_matched_scalar(reference_objects, loose_objects);
    if ~isempty(loose_matched)
      matched_fields(end + 1) = struct('configuration', ...
        'p2-loose', 'objects', loose_matched); %#ok<AGROW>
    end
  catch caught
    [code, reason] = LOCAL_decode_failure(caught);
    if ~LOCAL_is_scientific_failure(code)
      rethrow(caught);
    end
    state.failures(end + 1) = struct('stage', 'ALGEBRAIC_REFINEMENT', ...
      'phase', NaN, 'code', code, 'reason', reason); %#ok<AGROW>
  end

  bulk = struct('phase', {}, 'valid', {}, 'frequencies', {}, ...
    'code', {}, 'reason', {});
  LOCAL_log(output_dir, 'CORE_STAGE\tBULK_DIAGNOSTIC\tBEGIN');
  try
    bulk_mesh = LOCAL_build_mesh(spec, LOCAL_named_mesh('bulk-s9-g24'));
    [bulk_entries, state] = LOCAL_solve_slices(spec, bulk_mesh, ...
      spec.bulk_alpha_17, spec.bulk_tolerance, spec.bulk_nev, ...
      'BULK_DIAGNOSTIC', state);
    for index = 1:numel(bulk_entries)
      frequencies = [];
      if bulk_entries(index).valid
        frequencies = bulk_entries(index).spectrum.frequencies;
      end
      bulk(end + 1) = struct('phase', bulk_entries(index).phase, ...
        'valid', bulk_entries(index).valid, 'frequencies', frequencies, ...
        'code', bulk_entries(index).code, ...
        'reason', bulk_entries(index).reason); %#ok<AGROW>
    end
  catch caught
    [code, reason] = LOCAL_decode_failure(caught);
    if ~LOCAL_is_scientific_failure(code)
      rethrow(caught);
    end
    state.failures(end + 1) = struct('stage', 'BULK_DIAGNOSTIC', ...
      'phase', NaN, 'code', code, 'reason', reason); %#ok<AGROW>
  end

  deltas = [LOCAL_axis_delta(k_pre, scalars.h0, scalars.h2), ...
    LOCAL_axis_delta(k_pre, scalars.g0, scalars.g2), ...
    LOCAL_axis_delta(k_pre, scalars.N3, scalars.N5), ...
    LOCAL_pair_delta(k_pre, scalars.theta9), ...
    LOCAL_pair_delta(k_pre, scalars.loose)];
  finite = isfinite(deltas);
  if any(finite)
    delta_ref_obs = sum(deltas(finite));
  else
    delta_ref_obs = NaN;
  end
  if all(finite)
    resolution_status = 'EMPIRICAL_RESOLUTION_COMPLETE';
  else
    resolution_status = 'EMPIRICAL_RESOLUTION_PARTIAL';
  end
  refinement = struct('state', state, 'scalars', scalars, ...
    'delta_h', deltas(1), 'delta_g', deltas(2), ...
    'delta_N', deltas(3), 'delta_theta', deltas(4), ...
    'delta_tol', deltas(5), 'Delta_ref_obs', delta_ref_obs, ...
    'finite_components', finite, 'resolution_status', resolution_status, ...
    'bulk', bulk, 'matched_fields', matched_fields);
end

function [k_value, matched] = LOCAL_matched_scalar(reference, objects)
  k_value = NaN;
  matched = LOCAL_empty_objects();
  if isempty(reference) || isempty(objects)
    return;
  end
  for index = 1:numel(objects)
    objects(index).object_id = index;
  end
  internal_edges = LOCAL_empty_edges();
  for theta_index = 2:5
    source = find([objects.theta_index] == theta_index - 1);
    target = find([objects.theta_index] == theta_index);
    internal_edges = [internal_edges, LOCAL_assign_sets( ...
      objects, source, target, 'twist')]; %#ok<AGROW>
  end
  tracking = LOCAL_tracking_components(objects, internal_edges);
  combined = [objects, reference];
  for index = 1:numel(combined)
    combined(index).object_id = index;
  end
  cross_edges = LOCAL_empty_edges();
  for theta_index = 1:5
    source = find([objects.theta_index] == theta_index);
    target = numel(objects) + ...
      find([reference.theta_index] == theta_index);
    if isempty(source) || isempty(target)
      continue;
    end
    cross_edges = [cross_edges, LOCAL_assign_sets( ...
      combined, source, target, 'cross-configuration')]; %#ok<AGROW>
  end
  candidates = struct('ids', {}, 'rank', {});
  real_cross = cross_edges([cross_edges.real_pair]);
  for index = 1:numel(tracking.components)
    ids = tracking.components(index).realization_ids;
    connected = real_cross(ismember([real_cross.source_object_id], ids));
    theta = sort(unique([objects([connected.source_object_id]).theta_index]));
    if LOCAL_longest_consecutive(theta) < 3
      continue;
    end
    overlap = [connected.overlap];
    candidates(end + 1) = struct('ids', ids, ...
      'rank', [-numel(theta), -sum(overlap(isfinite(overlap))), ...
      min(ids)]); %#ok<AGROW>
  end
  if isempty(candidates)
    return;
  end
  [~, order] = sortrows(vertcat(candidates.rank), 1:3);
  matched = objects(candidates(order(1)).ids);
  lower = min(cellfun(@min, {matched.eigenvalues}));
  upper = max(cellfun(@max, {matched.eigenvalues}));
  k_value = sqrt((lower + upper) / 2);
end

function [k_value, additions] = LOCAL_twist_scalar( ...
    anchor_objects, added_objects, selected_ids)
  k_value = NaN;
  additions = LOCAL_empty_objects();
  combined = [anchor_objects, added_objects];
  for index = 1:numel(combined)
    combined(index).object_id = index;
  end
  phase_grid = sort(unique([combined.phase]));
  edges = LOCAL_empty_edges();
  for index = 2:numel(phase_grid)
    source = find(abs([combined.phase] - phase_grid(index - 1)) < 1e-13);
    target = find(abs([combined.phase] - phase_grid(index)) < 1e-13);
    edges = [edges, LOCAL_assign_sets(combined, source, target, 'twist')]; %#ok<AGROW>
  end
  tracking = LOCAL_tracking_components(combined, edges);
  component_ids = [];
  best_key = [Inf, Inf];
  for index = 1:numel(tracking.components)
    ids = tracking.components(index).realization_ids;
    shared = intersect(ids, selected_ids, 'stable');
    theta = sort(unique([combined(shared).theta_index]));
    if LOCAL_longest_consecutive(theta) >= 3
      key = [-numel(shared), min(ids)];
      if isempty(component_ids) || LOCAL_lex_less(key, best_key)
        best_key = key;
        component_ids = ids;
      end
    end
  end
  if ~isempty(component_ids)
    added_ids = component_ids(component_ids > numel(anchor_objects));
    if isempty(added_ids)
      component_ids = [];
    end
  end
  if isempty(component_ids)
    return;
  end
  lower = min(cellfun(@min, {combined(component_ids).eigenvalues}));
  upper = max(cellfun(@max, {combined(component_ids).eigenvalues}));
  k_value = sqrt((lower + upper) / 2);
  additions = combined(component_ids(component_ids > numel(anchor_objects)));
end

function value = LOCAL_axis_delta(anchor, coarse, fine)
  if all(isfinite([anchor, coarse, fine]))
    value = max(abs(anchor - coarse), abs(fine - anchor));
  else
    value = NaN;
  end
end

function value = LOCAL_pair_delta(first, second)
  if all(isfinite([first, second]))
    value = abs(first - second);
  else
    value = NaN;
  end
end

function LOCAL_publish_refinement(output_dir, spec, refinement)
  fields = refinement.matched_fields;
  compact = refinement;
  compact.matched_fields = [];
  compact.state = refinement.state;
  compact.claim_boundary = spec.partial_claim;
  if strcmp(refinement.resolution_status, 'EMPIRICAL_RESOLUTION_COMPLETE')
    compact.claim_boundary = spec.complete_claim;
  end
  LOCAL_atomic_save(fullfile(output_dir, 'refinement-result.mat'), compact);
  if ~isempty(fields)
    payload = struct('matched_axes', fields, ...
      'claim_boundary', compact.claim_boundary);
    LOCAL_atomic_save(fullfile(output_dir, 'refinement-fields.mat'), payload);
  end
end

function LOCAL_write_terminal(work_dir, state, terminal, claim, ...
    lambda_value, k_value)
  path = fullfile(work_dir, 'terminal.tsv');
  if exist(path, 'file')
    LOCAL_raise('OUTPUT_COLLISION', 'terminal.tsv already exists.');
  end
  file_id = fopen(path, 'w');
  if file_id < 0
    LOCAL_raise('OUTPUT_UNAVAILABLE', 'Cannot create terminal.tsv.');
  end
  cleanup = onCleanup(@() fclose(file_id)); %#ok<NASGU>
  fprintf(file_id, 'scientific_terminal\t%s\n', terminal);
  fprintf(file_id, 'claim_boundary\t%s\n', claim);
  fprintf(file_id, 'attempted_solves\t%d\n', state.attempted_solves);
  fprintf(file_id, 'completed_solves\t%d\n', state.completed_solves);
  fprintf(file_id, 'planned_solves\t%d\n', state.planned_solves);
  fprintf(file_id, 'lambda_pre\t%.17g\n', lambda_value);
  fprintf(file_id, 'k_pre\t%.17g\n', k_value);
end

%% ==================== P2 reduction and eigensolver ====================
% Section 23.2 stores only K, M, and P after immediate SPD-factor release.

function [pair, diagnostic] = LOCAL_phase_reduce(spec, mesh, phase_x)
  [prolongation, phases] = LOCAL_phase_prolongation( ...
    mesh.periodic, phase_x, spec.beta);
  seam_residual = LOCAL_check_seam(spec, mesh, prolongation, phase_x);
  stiffness = LOCAL_checked_operator(spec, ...
    prolongation' * mesh.stiffness_full * prolongation, ...
    'SPECTRUM_INVENTORY_TRUNCATED');
  mass = LOCAL_checked_operator(spec, ...
    prolongation' * mesh.mass_full * prolongation, ...
    'SPECTRUM_INVENTORY_TRUNCATED');
  spd = LOCAL_mass_spd(mass, 'MASS_NOT_SPD');
  pair = struct('stiffness', stiffness, 'mass', mass, ...
    'prolongation', prolongation);
  diagnostic = struct('seam_residual', seam_residual, ...
    'permutation_valid', spd.permutation_valid, ...
    'factor_nnz', spd.factor_nnz, ...
    'phase_factor_min', min(abs(phases)), ...
    'phase_factor_max', max(abs(phases)));
end

function seam_residual = LOCAL_check_seam(spec, mesh, prolongation, phase_x)
  x_residual = norm(prolongation(mesh.periodic.right_nodes, :) - ...
    exp(1i * phase_x) * prolongation(mesh.periodic.left_nodes, :), inf);
  y_residual = norm(prolongation(mesh.periodic.top_nodes, :) - ...
    exp(1i * spec.beta) * prolongation(mesh.periodic.bottom_nodes, :), inf);
  seam_residual = max(x_residual, y_residual);
  if mesh.periodic.coordinate_mismatch > spec.coordinate_tolerance || ...
      seam_residual > spec.seam_tolerance
    LOCAL_raise('QUASIPERIODIC_SEAM_UNRESOLVED', ...
      sprintf('%s phase %.17g fails seam identities.', mesh.id, phase_x));
  end
end

function canonical = LOCAL_checked_operator(spec, raw, terminal_code)
  if size(raw, 1) ~= size(raw, 2) || any(~isfinite(nonzeros(raw)))
    LOCAL_raise(terminal_code, 'A required operator is nonsquare or nonfinite.');
  end
  defect = norm(raw - raw', 1) / max(1, norm(raw, 1));
  if ~isfinite(defect) || defect > spec.hermitian_tolerance
    LOCAL_raise(terminal_code, 'A raw Hermitian defect exceeds tolerance.');
  end
  canonical = LOCAL_canonical_hermitian(raw);
  if ~isequal(canonical, canonical') || any(~isfinite(nonzeros(canonical)))
    LOCAL_raise(terminal_code, 'Canonical Hermitian construction failed.');
  end
end

function diagnostic = LOCAL_mass_spd(mass, terminal_code)
  if any(real(diag(mass)) <= 0)
    LOCAL_raise(terminal_code, 'The reduced mass has nonpositive diagonal.');
  end
  permutation = symamd(spones(mass + mass'));
  dimension = size(mass, 1);
  permutation_valid = isequal(sort(permutation(:)), (1:dimension).');
  if ~permutation_valid
    LOCAL_raise(terminal_code, 'symamd did not return a permutation.');
  end
  [factor, flag] = chol(mass(permutation, permutation));
  factor_nnz = nnz(factor);
  clear factor
  if flag ~= 0
    LOCAL_raise(terminal_code, 'The reduced mass is not positive definite.');
  end
  diagnostic = struct('permutation_valid', permutation_valid, ...
    'factor_nnz', factor_nnz);
end

function spectrum = LOCAL_low_spectrum( ...
    spec, mesh, phase_x, tolerance, requested_nev, role)
  [pair, phase_diagnostic] = LOCAL_phase_reduce(spec, mesh, phase_x);
  subspace_dimension = LOCAL_eigs_subspace(spec, requested_nev);
  if size(pair.mass, 1) <= subspace_dimension
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'The reduced space is too small for the frozen eigensolver call.');
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
  [vectors, diagonal, solver_flag] = eigs(pair.stiffness, pair.mass, ...
    requested_nev, 'smallestabs', options);
  values = diag(diagonal);
  if solver_flag ~= 0 || numel(values) ~= requested_nev || ...
      any(~isfinite(values)) || any(~isfinite(vectors), 'all')
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'The frozen eigensolver call returned an incomplete inventory.');
  end
  relative_imaginary = abs(imag(values)) ./ max(1, abs(real(values)));
  if any(relative_imaginary > spec.imaginary_tolerance) || ...
      any(real(values) <= 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'A generalized eigenvalue is nonpositive or nonreal.');
  end
  [eigenvalues, order] = sort(real(values), 'ascend');
  vectors = vectors(:, order);
  for index = 1:requested_nev
    mass_norm = real(vectors(:, index)' * pair.mass * vectors(:, index));
    if ~isfinite(mass_norm) || mass_norm <= 0
      LOCAL_raise('NUMERICAL_OBJECT_INVALID', 'Invalid eigenvector mass norm.');
    end
    vectors(:, index) = vectors(:, index) / sqrt(mass_norm);
  end
  frequencies = sqrt(eigenvalues);
  stiffness_norm = norm(pair.stiffness, 1);
  mass_operator_norm = norm(pair.mass, 1);
  residuals = zeros(requested_nev, 1);
  for index = 1:requested_nev
    vector = vectors(:, index);
    residuals(index) = norm(pair.stiffness * vector - ...
      eigenvalues(index) * pair.mass * vector, 2) / ...
      ((stiffness_norm + eigenvalues(index) * mass_operator_norm) * ...
      norm(vector, 2));
  end
  cluster_ids = LOCAL_cluster_ids(spec, frequencies, residuals);
  vectors = LOCAL_normalize_clusters(spec, pair.mass, vectors, cluster_ids);
  for index = 1:requested_nev
    vector = vectors(:, index);
    residuals(index) = norm(pair.stiffness * vector - ...
      eigenvalues(index) * pair.mass * vector, 2) / ...
      ((stiffness_norm + eigenvalues(index) * mass_operator_norm) * ...
      norm(vector, 2));
  end
  vectors_full = pair.prolongation * vectors;
  orthogonality_defect = norm(vectors' * pair.mass * vectors - ...
    eye(requested_nev), 2);
  if any(residuals > spec.residual_tolerance) || ...
      orthogonality_defect > spec.orthogonality_tolerance || ...
      any(diff(frequencies) < 0)
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'Residual, orthogonality, or ordering validation failed.');
  end
  spectrum = struct('mesh_id', mesh.id, 'phase', phase_x, ...
    'role', role, 'requested_nev', requested_nev, ...
    'solver_flag', solver_flag, 'eigenvalues', eigenvalues, ...
    'frequencies', frequencies, 'residuals', residuals, ...
    'cluster_ids', cluster_ids, 'vectors_full', vectors_full, ...
    'orthogonality_defect', orthogonality_defect, ...
    'phase_diagnostic', phase_diagnostic);
end

function dimension = LOCAL_eigs_subspace(spec, requested_nev)
  if requested_nev == 40
    dimension = spec.eigs_subspace_40;
  elseif requested_nev == 48
    dimension = spec.eigs_subspace_48;
  elseif requested_nev == 60
    dimension = spec.eigs_subspace_60;
  else
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      'The requested root count is outside the exact schedule.');
  end
end

function vectors = LOCAL_normalize_clusters(spec, mass, vectors, cluster_ids)
  for cluster_id = unique(cluster_ids).'
    roots = find(cluster_ids == cluster_id);
    gram = LOCAL_checked_operator(spec, ...
      vectors(:, roots)' * mass * vectors(:, roots), ...
      'NUMERICAL_OBJECT_INVALID');
    factor = chol(gram);
    vectors(:, roots) = vectors(:, roots) / factor;
    clear factor
  end
end

%% ==================== Mesh and mathematical helpers ====================
% The remaining helpers preserve the reviewed fitted-P2 formulas.
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
  [geometry_reflection_index, geometry_reflection_defect] = ...
    LOCAL_reflection_map(points, spec.coordinate_tolerance);
  geometry_constraint_mismatch = Inf;
  geometry_reflection_status = 'REFLECTION_CONNECTIVITY_UNAVAILABLE';
  if isfinite(geometry_reflection_defect) && ...
      numel(unique(geometry_reflection_index)) == size(points, 1) && ...
      isequal(geometry_reflection_index(geometry_reflection_index), ...
      (1:size(points, 1)).')
    geometry_constraint_mismatch = LOCAL_unpaired_constraint_count( ...
      constraints, geometry_reflection_index);
    if geometry_reflection_defect <= spec.coordinate_tolerance && ...
        geometry_constraint_mismatch == 0
      geometry_reflection_status = 'GEOMETRY_REFLECTION_AVAILABLE';
    end
  end
  [triangles, connectivity_reason] = LOCAL_validate_original_connectivity( ...
    spec, points, triangles, constraints, disk_centers, angles, ...
    xmin, xmax, ymin, ymax);
  if ~strcmp(connectivity_reason, 'PASS')
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', sprintf( ...
      '%s original constrained-Delaunay connectivity: %s', ...
      mesh_spec.id, connectivity_reason));
  end
  centroids = (points(triangles(:, 1), :) + ...
    points(triangles(:, 2), :) + points(triangles(:, 3), :)) / 3;
  material_inside = LOCAL_material_labels( ...
    centroids, disk_centers, spec.radius, angles);
  cross_interface_count = LOCAL_cross_interface_count( ...
    points, triangles, disk_centers, spec.radius, spec.constraint_tolerance);
  if cross_interface_count > 0
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s fails its fitted-interface check.', mesh_spec.id));
  end
  [edges, triangle_p2, p2_points, edge_incidence, boundary_edge_count] = ...
    LOCAL_p2_topology(points, triangles);
  element_validation = LOCAL_validate_p2_element(spec);
  [stiffness_full, mass_full, mass_center, mass_core, mass_tail, ...
    embedding_validation] = LOCAL_assemble_p2(spec, mesh_spec, points, ...
    triangles, triangle_p2, centroids, material_inside);
  if any(~isfinite(nonzeros(stiffness_full))) || ...
      any(~isfinite(nonzeros(mass_full)))
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      sprintf('%s assembly contains nonfinite entries.', mesh_spec.id));
  end
  stiffness_full = LOCAL_checked_operator( ...
    spec, stiffness_full, 'MESH_QUALITY_UNRESOLVED');
  mass_full = LOCAL_checked_operator( ...
    spec, mass_full, 'MESH_QUALITY_UNRESOLVED');
  vertex_periodic = LOCAL_periodic_maps( ...
    points, xmin, xmax, ymin, ymax, spec.coordinate_tolerance);
  periodic = LOCAL_periodic_maps( ...
    p2_points, xmin, xmax, ymin, ymax, spec.coordinate_tolerance);
  LOCAL_validate_midpoint_periodicity(spec, points, edges, edge_incidence, ...
    periodic, vertex_periodic);
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
    'mass_tail', mass_tail, ...
    'periodic', periodic, 'reduced_dof', max(periodic.master_index), ...
    'element_validation', element_validation, ...
    'embedding_validation', embedding_validation, ...
    'area_deficit', 1 - mesh_spec.n_gamma * ...
    sin(2 * pi / mesh_spec.n_gamma) / (2 * pi), ...
    'hausdorff_defect', hausdorff_defect, ...
    'connectivity_authority', 'original-constrained-delaunay', ...
    'parity_authority', 'sample-grid-parity', ...
    'geometry_reflection_status', geometry_reflection_status, ...
    'geometry_reflection_defect', geometry_reflection_defect, ...
    'geometry_constraint_mismatch', geometry_constraint_mismatch, ...
    'cross_interface_count', cross_interface_count, ...
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

function [triangles, reason] = LOCAL_validate_original_connectivity( ...
    spec, points, triangles, constraints, ...
    disk_centers, angles, xmin, xmax, ymin, ymax)
  reason = 'PASS';
  if isempty(triangles) || any(~isfinite(points), 'all') || ...
      any(~isfinite(triangles), 'all') || any(triangles(:) < 1) || ...
      any(triangles(:) > size(points, 1))
    reason = 'invalid or nonfinite triangle vertex inventory';
    return;
  end
  signed_area = LOCAL_signed_twice_area(points, triangles);
  flipped = signed_area < 0;
  triangles(flipped, [2, 3]) = triangles(flipped, [3, 2]);
  signed_area = LOCAL_signed_twice_area(points, triangles);
  canonical = sort(triangles, 2);
  [canonical, order] = sortrows(canonical);
  triangles = triangles(order, :);
  if any(signed_area <= 0) || ...
      size(unique(canonical, 'rows'), 1) ~= size(canonical, 1)
    reason = 'nonpositive-area or duplicate canonical triangle';
    return;
  end
  if ~isequal(unique(triangles(:)), (1:size(points, 1)).')
    reason = 'candidate does not use every frozen mesh point';
    return;
  end
  edges_by_triangle = sort([triangles(:, [1, 2]); ...
    triangles(:, [2, 3]); triangles(:, [3, 1])], 2);
  [edges, ~, edge_ids] = unique(edges_by_triangle, 'rows');
  incidence = accumarray(edge_ids, 1, [size(edges, 1), 1]);
  if any(incidence < 1 | incidence > 2)
    reason = 'active-edge incidence is not one or two';
    return;
  end
  if LOCAL_has_invalid_edge_intersection( ...
      points, edges, spec.constraint_tolerance)
    reason = 'nonadjacent crossing or collinear interior edge overlap';
    return;
  end
  boundary_edges = edges(incidence == 1, :);
  expected_boundary = LOCAL_outer_constraint_edges( ...
    points, constraints, xmin, xmax, ymin, ymax, ...
    spec.coordinate_tolerance);
  if size(boundary_edges, 1) ~= size(expected_boundary, 1) || ...
      any(~ismember(boundary_edges, expected_boundary, 'rows')) || ...
      any(~ismember(expected_boundary, boundary_edges, 'rows'))
    reason = 'incidence-one edges do not equal the segmented outer boundary';
    return;
  end
  domain_area = (xmax - xmin) * (ymax - ymin);
  area = sum(LOCAL_signed_twice_area(points, triangles)) / 2;
  if abs(area - domain_area) > ...
      spec.constraint_tolerance * max(1, domain_area)
    reason = 'triangle area does not equal the rectangular domain area';
    return;
  end
  used_points = points(unique(triangles(:)), :);
  if any(used_points(:, 1) < xmin - spec.coordinate_tolerance) || ...
      any(used_points(:, 1) > xmax + spec.coordinate_tolerance) || ...
      any(used_points(:, 2) < ymin - spec.coordinate_tolerance) || ...
      any(used_points(:, 2) > ymax + spec.coordinate_tolerance)
    reason = 'triangle interior cannot be contained in the rectangle';
    return;
  end
  if any(~ismember(constraints, edges, 'rows'))
    reason = 'a frozen required constraint is absent';
    return;
  end
  centroids = (points(triangles(:, 1), :) + ...
    points(triangles(:, 2), :) + points(triangles(:, 3), :)) / 3;
  material = LOCAL_material_labels( ...
    centroids, disk_centers, spec.radius, angles);
  coefficients = spec.q_outside + ...
    (spec.q_inside - spec.q_outside) * double(material);
  if any(~isfinite(coefficients))
    reason = 'a triangle has no finite deterministic material coefficient';
    return;
  end
  if LOCAL_cross_interface_count(points, triangles, disk_centers, ...
      spec.radius, spec.constraint_tolerance) > 0
    reason = 'a triangle crosses the fitted material interface';
    return;
  end
end

function material = LOCAL_material_labels( ...
    centroids, disk_centers, radius, angles)
  material = false(size(centroids, 1), 1);
  for center_index = 1:numel(disk_centers)
    polygon = [disk_centers(center_index) + radius * cos(angles), ...
      radius * sin(angles)];
    material = material | inpolygon(centroids(:, 1), centroids(:, 2), ...
      polygon(:, 1), polygon(:, 2));
  end
end

function boundary = LOCAL_outer_constraint_edges( ...
    points, constraints, xmin, xmax, ymin, ymax, tolerance)
  first = points(constraints(:, 1), :);
  second = points(constraints(:, 2), :);
  outer = (abs(first(:, 1) - xmin) <= tolerance & ...
    abs(second(:, 1) - xmin) <= tolerance) | ...
    (abs(first(:, 1) - xmax) <= tolerance & ...
    abs(second(:, 1) - xmax) <= tolerance) | ...
    (abs(first(:, 2) - ymin) <= tolerance & ...
    abs(second(:, 2) - ymin) <= tolerance) | ...
    (abs(first(:, 2) - ymax) <= tolerance & ...
    abs(second(:, 2) - ymax) <= tolerance);
  boundary = sort(constraints(outer, :), 2);
  boundary = unique(boundary, 'rows');
end

function invalid = LOCAL_has_invalid_edge_intersection(points, edges, tolerance)
  first = points(edges(:, 1), :);
  second = points(edges(:, 2), :);
  minimum_x = min(first(:, 1), second(:, 1));
  maximum_x = max(first(:, 1), second(:, 1));
  minimum_y = min(first(:, 2), second(:, 2));
  maximum_y = max(first(:, 2), second(:, 2));
  [minimum_x, order] = sort(minimum_x);
  maximum_x = maximum_x(order);
  minimum_y = minimum_y(order);
  maximum_y = maximum_y(order);
  edges = edges(order, :);
  invalid = false;
  for first_index = 1:size(edges, 1)
    second_index = first_index + 1;
    while second_index <= size(edges, 1) && ...
        minimum_x(second_index) <= maximum_x(first_index) + tolerance
      if minimum_y(second_index) <= maximum_y(first_index) + tolerance && ...
          minimum_y(first_index) <= maximum_y(second_index) + tolerance && ...
          LOCAL_edge_pair_invalid(points, edges(first_index, :), ...
          edges(second_index, :), tolerance)
        invalid = true;
        return;
      end
      second_index = second_index + 1;
    end
  end
end

function invalid = LOCAL_edge_pair_invalid(points, first_edge, second_edge, tolerance)
  first_a = points(first_edge(1), :);
  first_b = points(first_edge(2), :);
  second_a = points(second_edge(1), :);
  second_b = points(second_edge(2), :);
  orientations = [LOCAL_orientation(first_a, first_b, second_a), ...
    LOCAL_orientation(first_a, first_b, second_b), ...
    LOCAL_orientation(second_a, second_b, first_a), ...
    LOCAL_orientation(second_a, second_b, first_b)];
  shared = intersect(first_edge, second_edge);
  if all(abs(orientations) <= tolerance)
    direction = first_b - first_a;
    if abs(direction(1)) >= abs(direction(2))
      first_interval = sort([first_a(1), first_b(1)]);
      second_interval = sort([second_a(1), second_b(1)]);
    else
      first_interval = sort([first_a(2), first_b(2)]);
      second_interval = sort([second_a(2), second_b(2)]);
    end
    overlap = min(first_interval(2), second_interval(2)) - ...
      max(first_interval(1), second_interval(1));
    invalid = overlap > tolerance;
    return;
  end
  if ~isempty(shared)
    invalid = false;
    return;
  end
  proper = orientations(1) * orientations(2) < -tolerance^2 && ...
    orientations(3) * orientations(4) < -tolerance^2;
  touching = (abs(orientations(1)) <= tolerance && ...
    LOCAL_point_on_segment(second_a, first_a, first_b, tolerance)) || ...
    (abs(orientations(2)) <= tolerance && ...
    LOCAL_point_on_segment(second_b, first_a, first_b, tolerance)) || ...
    (abs(orientations(3)) <= tolerance && ...
    LOCAL_point_on_segment(first_a, second_a, second_b, tolerance)) || ...
    (abs(orientations(4)) <= tolerance && ...
    LOCAL_point_on_segment(first_b, second_a, second_b, tolerance));
  invalid = proper || touching;
end

function value = LOCAL_orientation(first, second, third)
  value = (second(1) - first(1)) * (third(2) - first(2)) - ...
    (second(2) - first(2)) * (third(1) - first(1));
end

function yes = LOCAL_point_on_segment(point, first, second, tolerance)
  yes = point(1) >= min(first(1), second(1)) - tolerance && ...
    point(1) <= max(first(1), second(1)) + tolerance && ...
    point(2) >= min(first(2), second(2)) - tolerance && ...
    point(2) <= max(first(2), second(2)) + tolerance;
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
    periodic, vertex_periodic)
  boundary_edges = find(incidence == 1);
  endpoint_classes = sort([ ...
    vertex_periodic.master_index(edges(boundary_edges, 1)), ...
    vertex_periodic.master_index(edges(boundary_edges, 2))], 2);
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
        suffix_costs = costs(remaining_rows, remaining_columns, :);
        finite_edges = all(isfinite(suffix_costs), 3);
        if ~LOCAL_has_perfect_matching(finite_edges)
          continue;
        end
        suffix = LOCAL_lexicographic_hungarian( ...
          suffix_costs);
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
  suffix_costs = Inf(3, 3, 7);
  finite_edges = [1, 1; 1, 2; 2, 1; 2, 3; 3, 3];
  for edge_index = 1:size(finite_edges, 1)
    suffix_costs(finite_edges(edge_index, 1), ...
      finite_edges(edge_index, 2), :) = 0;
  end
  [assignment, exact_tie] = LOCAL_lexicographic_assignment(suffix_costs);
  if ~isequal(assignment, [2; 1; 3]) || exact_tie
    LOCAL_raise('TRACKING_IMPLEMENTATION_FAILURE', ...
      'The suffix-feasibility assignment fixture failed.');
  end
end

function feasible = LOCAL_has_perfect_matching(finite_edges)
  row_count = size(finite_edges, 1);
  column_count = size(finite_edges, 2);
  if row_count == 0 && column_count == 0
    feasible = true;
    return;
  end
  if row_count ~= column_count
    feasible = false;
    return;
  end
  column_row = zeros(column_count, 1);
  for row = 1:row_count
    visited_columns = false(column_count, 1);
    [augmented, column_row, ~] = LOCAL_augment_finite_matching( ...
      row, finite_edges, column_row, visited_columns);
    if ~augmented
      feasible = false;
      return;
    end
  end
  feasible = true;
end

function [augmented, column_row, visited_columns] = ...
    LOCAL_augment_finite_matching( ...
    row, finite_edges, column_row, visited_columns)
  augmented = false;
  for column = 1:size(finite_edges, 2)
    if ~finite_edges(row, column) || visited_columns(column)
      continue;
    end
    visited_columns(column) = true;
    if column_row(column) == 0
      column_row(column) = row;
      augmented = true;
      return;
    end
    previous_row = column_row(column);
    [rerouted, column_row, visited_columns] = ...
      LOCAL_augment_finite_matching( ...
      previous_row, finite_edges, column_row, visited_columns);
    if rerouted
      column_row(column) = row;
      augmented = true;
      return;
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

function [samples, weights, parity_grid] = ...
    LOCAL_sample_subspace(spec, mesh, subspace)
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
  full_grid_pairing = LOCAL_common_grid_reflection( ...
    query, weights, spec.coordinate_tolerance);
  if strcmp(full_grid_pairing.status, 'AVAILABLE')
    on_circle = on_circle | ...
      on_circle(full_grid_pairing.reflection_index);
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
  parity_grid = LOCAL_common_grid_reflection( ...
    query, weights, spec.coordinate_tolerance);
  if ~strcmp(full_grid_pairing.status, 'AVAILABLE')
    parity_grid = full_grid_pairing;
  end
end

function grid = LOCAL_common_grid_reflection(query, weights, tolerance)
  grid = struct('status', 'UNAVAILABLE', 'reason', '', ...
    'reflection_index', zeros(0, 1), 'coordinate_defect', Inf, ...
    'weight_defect', Inf);
  if isempty(query) || any(~isfinite(query), 'all') || ...
      any(~isfinite(weights)) || any(weights <= 0)
    grid.reason = 'Common-grid coordinates or weights are invalid.';
    return;
  end
  point_keys = round(query / tolerance);
  if size(unique(point_keys, 'rows'), 1) ~= size(query, 1)
    grid.reason = 'Common-grid coordinate keys are not unique.';
    return;
  end
  reflected_keys = round([-query(:, 1), query(:, 2)] / tolerance);
  [found, reflection_index] = ismember(reflected_keys, point_keys, 'rows');
  if any(~found) || numel(unique(reflection_index)) ~= size(query, 1) || ...
      ~isequal(reflection_index(reflection_index), ...
      (1:size(query, 1)).')
    grid.reason = ...
      'Interface-pair removal did not leave a bijective reflection grid.';
    return;
  end
  coordinate_defect = max(abs(query(reflection_index, :) - ...
    [-query(:, 1), query(:, 2)]), [], 'all');
  weight_defect = max(abs(weights(reflection_index) - weights));
  grid.reflection_index = reflection_index;
  grid.coordinate_defect = coordinate_defect;
  grid.weight_defect = weight_defect;
  if ~isfinite(coordinate_defect) || coordinate_defect > tolerance || ...
      ~isfinite(weight_defect) || weight_defect > tolerance
    grid.reason = 'Common-grid reflection coordinates or weights do not match.';
    return;
  end
  grid.status = 'AVAILABLE';
  grid.reason = 'EMPIRICAL_COMMON_GRID_PARITY';
end

function [values, invariance_defect] = ...
    LOCAL_common_grid_parity(spec, samples, weights, grid)
  if ~strcmp(grid.status, 'AVAILABLE')
    LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', grid.reason);
  end
  gram = samples' * (weights .* samples);
  if size(gram, 1) ~= size(gram, 2) || ...
      any(~isfinite(gram), 'all')
    LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', ...
      'The common-grid sample Gram is invalid.');
  end
  gram_defect = norm(gram - gram', 1) / max(1, norm(gram, 1));
  if gram_defect > spec.hermitian_tolerance
    LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', ...
      'The common-grid sample Gram is not Hermitian.');
  end
  gram = (gram + gram') / 2;
  [factor, flag] = chol(gram);
  if flag ~= 0
    LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', ...
      'The common-grid sample Gram is not positive definite.');
  end
  normalized = samples / factor;
  reflected = normalized(grid.reflection_index, :);
  compression = normalized' * (weights .* reflected);
  hermitian_compression = (compression + compression') / 2;
  values = sort(real(eig(hermitian_compression))).';
  residual = reflected - normalized * compression;
  numerator = real(trace(residual' * (weights .* residual)));
  denominator = real(trace(normalized' * (weights .* normalized)));
  if ~isfinite(numerator) || ~isfinite(denominator) || denominator <= 0
    LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', ...
      'The weighted common-grid parity norm is invalid.');
  end
  invariance_defect = sqrt(max(0, numerator) / denominator);
  if any(~isfinite(values)) || ~isfinite(invariance_defect)
    LOCAL_raise('PARITY_DIAGNOSTIC_UNAVAILABLE', ...
      'The common-grid parity compression is nonfinite.');
  end
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
