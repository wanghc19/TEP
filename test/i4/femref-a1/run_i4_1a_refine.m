function run_i4_1a_refine(run_id)
%RUN_I4_1A_REFINE Produce the frozen I4.1a out-of-sample s=30 FEM candidate.
% Purpose:
%   Solve only the independent fitted-P1 defect problem on the preregistered
%   (N,s,g)=(5,30,60) mesh at five fixed twists.
% Input:
%   run_id - Must be exactly 'run-008'; it changes no scientific parameter.
% Output:
%   scientific-result.mat, fields.mat, run.log, and a transient terminal draft
%   below output/run-008/execution-001/.
% Main algorithm:
%   Build one fitted mesh, compute five 48-root spectra, retain every valid
%   field-bearing W3 cluster, track adjacent twists by maximum common-core
%   overlap, and rank every component using only current-run FEM quantities.
% Based on:
%   research/projects/eig-apost/implementation/i4/design-4-1a.md, Sections
%   43--44, and the reviewed mathematical helpers in run_i4_1a.m.
% Main changes:
%   No bulk solve, historical artifact, old FEM scalar, BIE/QZ value, estimator,
%   60-root expansion, identity audit, profile fit, or effectivity comparison
%   enters the active call graph.
% Numerical goal:
%   Freeze lambda_30 and k_30 for the deterministic first-ranked pure-FEM
%   component whenever any valid field-bearing W3 object exists.

  if nargin ~= 1 || ~(ischar(run_id) || (isstring(run_id) && isscalar(run_id)))
    error('I4R:InvalidRunId', 'The formal entry requires one run ID.');
  end
  run_id = char(run_id);
  if ~strcmp(run_id, 'run-008')
    error('I4R:InvalidRunId', 'The formal entry is fixed to run-008.');
  end
  execution_id = 'execution-001';
  entry_dir = fileparts(mfilename('fullpath'));
  output_dir = fullfile(entry_dir, 'output', run_id, execution_id);
  if ~exist(output_dir, 'dir')
    error('I4R:OutputUnavailable', ...
      'The fixed runner must create output/run-008/execution-001 first.');
  end
  work_dir = fullfile(output_dir, 'work');
  if exist(work_dir, 'dir') || exist(work_dir, 'file')
    error('I4R:OutputCollision', 'The current-run work directory exists.');
  end
  if exist(fullfile(output_dir, 'scientific-result.mat'), 'file') || ...
      exist(fullfile(output_dir, 'fields.mat'), 'file') || ...
      exist(fullfile(output_dir, 'resource.tsv'), 'file') || ...
      exist(fullfile(output_dir, 'run-summary.csv'), 'file')
    error('I4R:OutputCollision', 'A terminal execution-001 artifact exists.');
  end
  [made_work, work_message] = mkdir(work_dir);
  if ~made_work
    error('I4R:OutputUnavailable', 'Cannot create work: %s', work_message);
  end

  spec = LOCAL_spec();
  run_state = LOCAL_initial_state(run_id, execution_id, spec);
  mesh_descriptor = struct([]);
  solve_ledger = LOCAL_empty_solve_ledger();
  candidate_inventory = LOCAL_empty_inventory();
  tracking = struct('edges', LOCAL_empty_tracking_edges(), ...
    'components', struct('candidate_id', {}, 'realization_ids', {}));
  selected_candidate = struct([]);
  terminal_class = 'OPERATIONAL_FAILURE';
  terminal_status = 'RUNNING';
  first_failure = '';
  fprintf('I4.1a out-of-sample fitted-FEM run %s/%s\n', ...
    run_id, execution_id);
  try
    LOCAL_check_environment(spec);
    LOCAL_log(output_dir, 'stage=mesh');
    mesh_spec = struct('id', 'defect-N5-s30-g60', ...
      'kind', 'defect', 'N', 5, 's', 30, 'n_gamma', 60);
    mesh = LOCAL_build_mesh(spec, mesh_spec);
    mesh_cache = fullfile(work_dir, 'mesh-defect-N5-s30-g60.mat');
    LOCAL_atomic_save(mesh_cache, mesh);
    mesh_descriptor = LOCAL_mesh_descriptor(mesh);

    LOCAL_log(output_dir, 'stage=five-48-root-spectra');
    for theta_index = 1:numel(spec.theta_5)
      solve_id = sprintf('s30-p%02d', theta_index);
      [entry, run_state] = LOCAL_run_spectrum_item(spec, mesh, work_dir, ...
        output_dir, run_state, solve_id, spec.theta_5(theta_index), ...
        theta_index);
      solve_ledger(end + 1) = entry; %#ok<AGROW>
    end

    LOCAL_log(output_dir, 'stage=pure-fem-ranking');
    [candidate_inventory, tracking] = LOCAL_candidate_inventory( ...
      spec, mesh, solve_ledger);
    if isempty(candidate_inventory.objects)
      LOCAL_raise('NO_VALID_FIELD_BEARING_W3_EIGENOBJECT', ...
        'The five-twist schedule contains no valid field-bearing W3 object.');
    end
    [candidate_inventory, selected_candidate] = LOCAL_rank_candidates( ...
      spec, solve_ledger, candidate_inventory, tracking);
    LOCAL_publish_fields(output_dir, spec, mesh, solve_ledger, ...
      candidate_inventory, selected_candidate);
    terminal_class = 'SCIENTIFIC_READY';
    terminal_status = 'OUT_OF_SAMPLE_FEM_CANDIDATE_READY';
    LOCAL_publish_scientific(output_dir, spec, run_state, mesh_descriptor, ...
      solve_ledger, candidate_inventory, tracking, selected_candidate, ...
      terminal_class, terminal_status, first_failure);
  catch caught
    [failure_code, failure_message] = LOCAL_decode_failure(caught);
    terminal_status = failure_code;
    first_failure = failure_message;
    if LOCAL_is_scientific_terminal(failure_code)
      terminal_class = 'SCIENTIFIC_NEGATIVE';
      if ~strcmp(failure_code, 'CANONICAL_PUBLICATION_FAILURE')
        try
          LOCAL_publish_scientific(output_dir, spec, run_state, ...
            mesh_descriptor, solve_ledger, candidate_inventory, tracking, ...
            struct([]), terminal_class, terminal_status, first_failure);
        catch publication_failure
          [publication_code, publication_message] = ...
            LOCAL_decode_failure(publication_failure);
          if ~strcmp(publication_code, 'CANONICAL_PUBLICATION_FAILURE')
            rethrow(publication_failure);
          end
          terminal_status = publication_code;
          first_failure = publication_message;
        end
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
% Design Sections 43--44 define the complete current-run model and schedule.

function spec = LOCAL_spec()
  spec = struct();
  spec.design_id = 'I4.1A-OUT-OF-SAMPLE-S30-V1';
  spec.model_id = 'scalar-laplace-q17-r0p2-beta0p5-missing0-v1';
  spec.period = 1;
  spec.radius = 0.2;
  spec.q_inside = 17;
  spec.q_outside = 1;
  spec.missing_column = 0;
  spec.beta = 0.5;
  spec.cue_interval = [1.65, 2.05];
  spec.guard_interval = [1.25, 2.45];
  spec.theta_5 = [0, pi / 4, pi / 2, 3 * pi / 4, pi];
  spec.requested_nev = 48;
  spec.solve_tolerance = 1e-11;
  spec.eigs_maxit = 800;
  spec.eigs_subspace_main = 80;
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
  spec.upper_sentinel_margin = 0.10;
  spec.localization_center_min = 0.15;
  spec.localization_core_min = 0.60;
  spec.tail_max = 0.02;
  spec.simple_overlap_min = 0.90;
  spec.cluster_overlap_min = 0.80;
  spec.parity_threshold = 0.80;
  spec.core_grid_x = linspace(-2.5, 2.5, 161);
  spec.core_grid_y = linspace(-0.5, 0.5, 65);
  spec.search_windows = [1.65, 2.05; 1.25, 2.45; ...
    0.85, 2.85; 0.45, 3.25];
  spec.planned_solves = 5;
  spec.random_seed = 4101;
  spec.claim_boundary = ...
    'EMPIRICAL_OUT_OF_SAMPLE_FEM_CANDIDATE_NO_EFFECTIVITY';
end

%% ==================== Run state and create-once artifacts ====================
% The runner owns resource.tsv and publishes run-summary.csv last.

function run_state = LOCAL_initial_state(run_id, execution_id, spec)
  run_state = struct('run_id', run_id, 'execution_id', execution_id, ...
    'attempted_solves', 0, 'completed_solves', 0, ...
    'planned_solves', spec.planned_solves, 'start_clock', tic);
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
  if spec.period ~= 1 || spec.radius ~= 0.2 || spec.q_inside ~= 17 || ...
      spec.q_outside ~= 1 || spec.beta ~= 0.5 || ...
      spec.missing_column ~= 0 || spec.planned_solves ~= 5 || ...
      spec.requested_nev ~= 48 || numel(spec.theta_5) ~= 5 || ...
      any(abs(spec.theta_5 - [0, pi / 4, pi / 2, 3 * pi / 4, pi]) > 1e-14)
    LOCAL_raise('CONTINUOUS_MODEL_MISMATCH', ...
      'The source model or five-solve schedule changed.');
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

function payload = LOCAL_load_current(path)
  loaded = load(path, 'payload');
  payload = loaded.payload;
end

function LOCAL_write_terminal_draft(output_dir, run_state, terminal_class, ...
    terminal_status, first_failure, selected_candidate)
  collection_size = 0;
  lambda_30 = NaN;
  k_30 = NaN;
  if ~isempty(selected_candidate)
    collection_size = selected_candidate.collection_size;
    lambda_30 = selected_candidate.lambda_30;
    k_30 = selected_candidate.k_30;
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
  fprintf(file_id, 'lambda_30\t%.17g\n', lambda_30);
  fprintf(file_id, 'k_30\t%.17g\n', k_30);
  fprintf(file_id, 'first_failure\t%s\n', ...
    strrep(strrep(first_failure, sprintf('\n'), ' '), sprintf('\t'), ' '));
  fprintf(file_id, 'matlab_elapsed_seconds\t%.9f\n', ...
    toc(run_state.start_clock));
  fprintf(file_id, 'claim_boundary\t%s\n', ...
    'EMPIRICAL_OUT_OF_SAMPLE_FEM_CANDIDATE_NO_EFFECTIVITY');
end

function yes = LOCAL_is_scientific_terminal(code)
  terminals = {'MESH_QUALITY_UNRESOLVED', ...
    'QUASIPERIODIC_SEAM_UNRESOLVED', ...
    'NO_VALID_FIELD_BEARING_W3_EIGENOBJECT', ...
    'CANONICAL_PUBLICATION_FAILURE'};
  yes = any(strcmp(terminals, code));
end

function LOCAL_raise(code, message)
  error(['I4R:' code], '%s', message);
end

function [code, message] = LOCAL_decode_failure(caught)
  if startsWith(caught.identifier, 'I4R:')
    code = caught.identifier(5:end);
  else
    code = 'EXECUTION_UNAVAILABLE';
  end
  message = caught.message;
end

function descriptor = LOCAL_mesh_descriptor(mesh)
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
end

function ledger = LOCAL_empty_solve_ledger()
  ledger = struct('solve_id', {}, 'theta', {}, 'theta_index', {}, ...
    'requested_nev', {}, 'valid', {}, 'cache_file', {}, 'path', {}, ...
    'failure_code', {}, 'failure_reason', {}, 'ceiling', {}, ...
    'coverage_margin', {}, 'w3_covered', {}, 'summary', {});
end

function inventory = LOCAL_empty_inventory()
  inventory = struct('objects', LOCAL_empty_objects(), ...
    'invalid_objects', struct('solve_id', {}, 'cluster_id', {}, ...
    'code', {}, 'reason', {}), ...
    'slices', struct('theta', {}, 'theta_index', {}, ...
    'object_ids', {}, 'solve_id', {}, 'valid', {}, ...
    'failure_reason', {}), ...
    'candidates', struct([]), 'ordered_candidate_ids', zeros(0, 1));
end

function [entry, run_state] = LOCAL_run_spectrum_item( ...
    spec, mesh, work_dir, output_dir, run_state, solve_id, theta, theta_index)
  valid = false;
  spectrum = struct([]);
  path = fullfile(work_dir, [solve_id '.mat']);
  code = '';
  reason = '';
  try
    [spectrum, phase_diagnostic] = LOCAL_low_spectrum(spec, mesh, theta, ...
      spec.solve_tolerance, spec.requested_nev, 'out-of-sample-s30', ...
      'defect-theta');
    spectrum.phase_diagnostic = phase_diagnostic;
    LOCAL_atomic_save(path, spectrum);
    valid = true;
  catch caught
    [code, reason] = LOCAL_decode_failure(caught);
    recordable = strcmp(code, 'MESH_QUALITY_UNRESOLVED') || ...
      strcmp(code, 'QUASIPERIODIC_SEAM_UNRESOLVED') || ...
      strcmp(code, 'SPECTRUM_INVENTORY_TRUNCATED') || ...
      strcmp(code, 'NUMERICAL_OBJECT_INVALID');
    if strcmp(code, 'EXECUTION_UNAVAILABLE') || startsWith(code, 'OUTPUT_') || ...
        ~recordable
      rethrow(caught);
    end
  end
  run_state.attempted_solves = run_state.attempted_solves + 1;
  if valid
    run_state.completed_solves = run_state.completed_solves + 1;
    solve_status = 'VALID';
    summary = spectrum;
    summary.vectors_full = [];
    ceiling = spectrum.frequencies(end);
    coverage_margin = ceiling - spec.search_windows(4, 2);
    w3_covered = coverage_margin >= spec.upper_sentinel_margin;
    cache_file = [solve_id '.mat'];
  else
    solve_status = 'INVALID';
    summary = struct([]);
    ceiling = NaN;
    coverage_margin = NaN;
    w3_covered = false;
    cache_file = '';
  end
  LOCAL_log(output_dir, sprintf( ...
    'attempt=%d/5 completed=%d id=%s status=%s', ...
    run_state.attempted_solves, run_state.completed_solves, solve_id, ...
    solve_status));
  entry = struct('solve_id', solve_id, 'theta', theta, ...
    'theta_index', theta_index, 'requested_nev', spec.requested_nev, ...
    'valid', valid, 'cache_file', cache_file, 'path', path, ...
    'failure_code', code, 'failure_reason', reason, 'ceiling', ceiling, ...
    'coverage_margin', coverage_margin, 'w3_covered', w3_covered, ...
    'summary', summary);
end

%% ==================== Pure-FEM W3 objects ====================
% Every numerically valid field-bearing whole cluster intersecting W3 is kept.

function [inventory, tracking] = LOCAL_candidate_inventory(spec, mesh, ledger)
  inventory = LOCAL_empty_inventory();
  objects = LOCAL_empty_objects();
  invalid_objects = inventory.invalid_objects;
  slices = inventory.slices;
  next_object_id = 1;
  for theta_index = 1:numel(ledger)
    entry = ledger(theta_index);
    object_ids = zeros(0, 1);
    failure_reason = entry.failure_reason;
    if entry.valid
      try
        spectrum = LOCAL_load_current(entry.path);
        [clusters, invalid] = LOCAL_w3_clusters(spec, mesh, spectrum);
        for invalid_index = 1:numel(invalid)
          invalid_objects(end + 1) = struct( ...
            'solve_id', entry.solve_id, ...
            'cluster_id', invalid(invalid_index).cluster_id, ...
            'code', invalid(invalid_index).code, ...
            'reason', invalid(invalid_index).reason); %#ok<AGROW>
        end
        for cluster_index = 1:numel(clusters)
          object = clusters(cluster_index);
          object.object_id = next_object_id;
          object.seed_candidate_id = next_object_id;
          object.solve_id = entry.solve_id;
          object.mesh_id = mesh.id;
          object.theta = entry.theta;
          object.theta_index = entry.theta_index;
          objects(end + 1) = object; %#ok<AGROW>
          object_ids(end + 1, 1) = next_object_id; %#ok<AGROW>
          next_object_id = next_object_id + 1;
        end
      catch caught
        [code, failure_reason] = LOCAL_decode_failure(caught);
        if ~strcmp(code, 'NUMERICAL_OBJECT_INVALID')
          rethrow(caught);
        end
        invalid_objects(end + 1) = struct('solve_id', entry.solve_id, ...
          'cluster_id', NaN, 'code', code, ...
          'reason', failure_reason); %#ok<AGROW>
      end
    end
    slices(end + 1) = struct('theta', entry.theta, ...
      'theta_index', entry.theta_index, 'object_ids', object_ids, ...
      'solve_id', entry.solve_id, 'valid', entry.valid, ...
      'failure_reason', failure_reason); %#ok<AGROW>
  end
  edges = LOCAL_empty_tracking_edges();
  for theta_index = 2:numel(slices)
    adjacent = LOCAL_assign_object_sets(spec, objects, ...
      slices(theta_index - 1).object_ids, slices(theta_index).object_ids, ...
      'twist', 'adjacent-twist');
    edges = [edges, adjacent]; %#ok<AGROW>
  end
  tracking = LOCAL_tracking_components(objects, edges);
  inventory.objects = objects;
  inventory.invalid_objects = invalid_objects;
  inventory.slices = slices;
end

function objects = LOCAL_empty_objects()
  objects = struct('object_id', {}, 'seed_candidate_id', {}, ...
    'solve_id', {}, 'mesh_id', {}, 'theta', {}, 'theta_index', {}, ...
    'cluster_id', {}, 'root_index', {}, 'root_indices', {}, ...
    'dimension', {}, 'eigenvalues', {}, 'frequencies', {}, ...
    'lambda_envelope', {}, 'k_envelope', {}, ...
    'raw_subspace', {}, 'subspace', {}, 'residual_max', {}, ...
    'L0_min', {}, 'Lcore_min', {}, 'tail_max', {}, ...
    'localization_status', {}, 'localization_reason', {}, ...
    'parity_values', {}, 'parity_label', {}, ...
    'parity_status', {}, 'parity_reason', {}, ...
    'common_core_samples', {}, 'common_core_weights', {}, ...
    'common_core_valid', {}, 'common_core_reason', {}, ...
    'window_label', {}, 'window_edge_straddle', {});
end

function [clusters, invalid] = LOCAL_w3_clusters(spec, mesh, spectrum)
  clusters = LOCAL_empty_objects();
  invalid = struct('cluster_id', {}, 'code', {}, 'reason', {});
  w3 = spec.search_windows(4, :);
  cluster_numbers = unique(spectrum.cluster_ids).';
  reflection = sparse((1:size(mesh.points, 1)).', ...
    mesh.reflection_index, 1, size(mesh.points, 1), size(mesh.points, 1));
  restricted_mass = {mesh.mass_center, mesh.mass_core, mesh.mass_tail};
  for cluster_index = 1:numel(cluster_numbers)
    cluster_id = cluster_numbers(cluster_index);
    roots = find(spectrum.cluster_ids == cluster_id);
    k_envelope = [min(spectrum.frequencies(roots)), ...
      max(spectrum.frequencies(roots))];
    if k_envelope(2) < w3(1) || k_envelope(1) > w3(2)
      continue;
    end
    try
      raw_subspace = spectrum.vectors_full(:, roots);
      if isempty(raw_subspace) || any(~isfinite(raw_subspace), 'all')
        LOCAL_raise('NUMERICAL_OBJECT_INVALID', ...
          'A W3 cluster has no finite field subspace.');
      end
      [~, field_factor] = LOCAL_checked_hermitian(spec, ...
        raw_subspace' * mesh.mass_full * raw_subspace, true, ...
        'NUMERICAL_OBJECT_INVALID');
      subspace = raw_subspace / field_factor;
      field_gram = subspace' * mesh.mass_full * subspace;
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
        [~, common_factor] = LOCAL_checked_hermitian(spec, ...
          common_samples' * (common_weights .* common_samples), true, ...
          'TRACKING_DIAGNOSTIC_UNAVAILABLE');
        common_samples = common_samples / common_factor;
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
      object.raw_subspace = raw_subspace;
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
      clusters(end + 1) = object; %#ok<AGROW>
    catch caught
      [code, reason] = LOCAL_decode_failure(caught);
      if ~strcmp(code, 'NUMERICAL_OBJECT_INVALID')
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

%% ==================== Adjacent-twist tracking ====================
% Maximum-total-overlap assignment keeps births, deaths, and singletons.

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
  minimum_object_id = zeros(numel(roots), 1);
  for root_index = 1:numel(roots)
    members = find(labels == roots(root_index));
    minimum_object_id(root_index) = min([objects(members).object_id]);
  end
  [~, order] = sort(minimum_object_id);
  components = struct('candidate_id', {}, 'realization_ids', {});
  for candidate_id = 1:numel(order)
    members = find(labels == roots(order(candidate_id)));
    components(end + 1) = struct('candidate_id', candidate_id, ...
      'realization_ids', members); %#ok<AGROW>
  end
  tracking = struct('edges', edges, 'components', components);
end

%% ==================== Pure-FEM ranking and publication ====================
% Section 43.2 defines the single-configuration projected total order.

function [inventory, selected] = LOCAL_rank_candidates( ...
    spec, ledger, inventory, tracking)
  candidates = struct([]);
  for component_index = 1:numel(tracking.components)
    candidate = LOCAL_candidate_record(spec, ledger, inventory.objects, ...
      tracking.edges, tracking.components(component_index));
    if isempty(candidates)
      candidates = candidate;
    else
      candidates(end + 1) = candidate; %#ok<AGROW>
    end
  end
  rank_matrix = vertcat(candidates.rank_key);
  [~, order] = sortrows(rank_matrix, 1:size(rank_matrix, 2));
  inventory.candidates = candidates;
  inventory.ordered_candidate_ids = [candidates(order).candidate_id].';
  selected = candidates(order(1));
  selected.collection_size = numel(candidates);
end

function candidate = LOCAL_candidate_record( ...
    spec, ledger, objects, edges, component)
  ids = component.realization_ids;
  member_edge = false(1, numel(edges));
  for edge_index = 1:numel(edges)
    member_edge(edge_index) = ...
      ismember(edges(edge_index).source_object_id, ids) && ...
      ismember(edges(edge_index).target_object_id, ids);
  end
  linked_edges = edges(member_edge);
  n_twists = numel(unique([objects(ids).theta]));
  n_edges = numel(linked_edges);
  missing_count = 4;
  finite_drift_sum = 0;
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
  [covered_slices, ceiling_margin] = ...
    LOCAL_candidate_coverage(ledger, objects(ids));
  anchor_keys = [[objects(ids).theta_index].', ...
    [objects(ids).root_index].', [objects(ids).object_id].'];
  [~, anchor_order] = sortrows(anchor_keys, 1:3);
  anchor = objects(ids(anchor_order(1)));
  publication = LOCAL_publication_realization(objects, ids);
  classification = LOCAL_candidate_classification(spec, publication, ...
    n_twists, n_edges, localization_center, localization_core, tail_max, ...
    parity_rank, covered_slices, ceiling_margin, objects(ids));
  rank_key = [-n_twists, -n_edges, missing_count, finite_drift_sum, ...
    LOCAL_nan_min(residual_max), ...
    LOCAL_nan_negative(localization_center), ...
    LOCAL_nan_negative(localization_core), LOCAL_nan_min(tail_max), ...
    parity_rank, -covered_slices, LOCAL_nan_negative(ceiling_margin), ...
    anchor.theta_index, anchor.root_index, anchor.object_id, ...
    component.candidate_id];
  if n_twists == 1 && n_edges == 0
    tracking_status = 'UNTRACKED_SINGLE_CONFIGURATION';
  elseif n_twists < 5 || n_edges < 4
    tracking_status = 'PARTIAL_TWIST_CONTINUATION';
  else
    tracking_status = 'FULL_FIVE_TWIST_CONTINUATION';
  end
  candidate = struct('candidate_id', component.candidate_id, ...
    'realization_ids', ids, 'n_twists', n_twists, 'n_edges', n_edges, ...
    'tracking_status', tracking_status, ...
    'delta_fem', NaN, 'delta_supercell', NaN, ...
    'delta_twist', NaN, 'delta_algebraic', NaN, ...
    'delta_ref_obs', NaN, ...
    'missing_refinement_count', missing_count, ...
    'finite_drift_sum', finite_drift_sum, ...
    'resolution_status', 'EMPIRICAL_RESOLUTION_PARTIAL', ...
    'residual_max', residual_max, ...
    'localization_center', localization_center, ...
    'localization_core', localization_core, 'tail_max', tail_max, ...
    'parity_rank', parity_rank, 'covered_slices', covered_slices, ...
    'ceiling_margin', ceiling_margin, 'rank_key', rank_key, ...
    'classification', {classification}, ...
    'candidate_status', ...
    'EMPIRICAL_OUT_OF_SAMPLE_FEM_CANDIDATE_WITH_CAVEATS', ...
    'publication', publication, ...
    'lambda_30', publication.lambda_30, 'k_30', publication.k_30);
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

function [covered_slices, margin] = ...
    LOCAL_candidate_coverage(ledger, objects)
  theta_indices = unique([objects.theta_index]);
  covered_slices = nnz([ledger(theta_indices).w3_covered]);
  margins = [ledger(theta_indices).coverage_margin];
  margins = margins(isfinite(margins));
  if isempty(margins)
    margin = NaN;
  else
    margin = min(margins);
  end
end

function publication = LOCAL_publication_realization(objects, ids)
  lambda_values = vertcat(objects(ids).lambda_envelope);
  k_values = vertcat(objects(ids).k_envelope);
  lambda_envelope = [min(lambda_values(:, 1)), max(lambda_values(:, 2))];
  k_envelope = [min(k_values(:, 1)), max(k_values(:, 2))];
  lambda_30 = mean(lambda_envelope);
  k_30 = sqrt(lambda_30);
  anchor_keys = [[objects(ids).theta_index].', ...
    [objects(ids).root_index].', [objects(ids).object_id].'];
  [~, anchor_order] = sortrows(anchor_keys, 1:3);
  anchor = objects(ids(anchor_order(1)));
  simple_vector = [];
  basis_status = 'MASS_NORMALIZED_SUBSPACE';
  if anchor.dimension == 1
    [~, pivot] = max(abs(anchor.subspace(:, 1)));
    phase = exp(-1i * angle(anchor.subspace(pivot, 1)));
    simple_vector = anchor.subspace(:, 1) * phase;
    basis_status = 'PHASE_FIXED_MASS_NORMALIZED_VECTOR';
  end
  publication = struct('realization_ids', ids, ...
    'valid_twist_count', numel(unique([objects(ids).theta])), ...
    'anchor_object_id', anchor.object_id, ...
    'anchor_mesh_id', anchor.mesh_id, 'anchor_theta', anchor.theta, ...
    'anchor_theta_index', anchor.theta_index, ...
    'anchor_root_index', anchor.root_index, ...
    'multiplicity', anchor.dimension, ...
    'lambda_envelope', lambda_envelope, 'k_envelope', k_envelope, ...
    'lambda_30', lambda_30, 'k_30', k_30, ...
    'subspace', anchor.subspace, 'simple_vector', simple_vector, ...
    'basis_status', basis_status, 'window_label', anchor.window_label);
end

function labels = LOCAL_candidate_classification( ...
    spec, publication, n_twists, n_edges, center, core, tail, ...
    parity_rank, covered_slices, margin, objects)
  labels = {publication.window_label, 'BULK_GAP_NOT_COMPUTED'};
  if n_twists < 5 || n_edges < 4
    labels{end + 1} = 'PARTIAL_TWIST_CONTINUATION';
  else
    labels{end + 1} = 'FULL_FIVE_TWIST_CONTINUATION';
  end
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
  labels{end + 1} = 'empirical-resolution-partial';
  if covered_slices == 5
    labels{end + 1} = 'spectrum-covered-through-W3';
  else
    labels{end + 1} = 'spectrum-coverage-partial';
  end
  if any([objects.window_edge_straddle])
    labels{end + 1} = 'WINDOW_EDGE_STRADDLE';
  end
  labels{end + 1} = sprintf( ...
    'coverage-slices-%d-margin-%.17g', covered_slices, margin);
end

%% ==================== Canonical scientific publication ====================
% The canonical MAT is the only ranking authority; fields contains all W3 fields.

function LOCAL_publish_scientific(output_dir, spec, run_state, ...
    mesh_descriptor, solve_ledger, candidate_inventory, tracking, ...
    selected_candidate, terminal_class, terminal_status, first_failure)
  payload = struct('schema_version', 'i4a-s30-refinement-v1', ...
    'run_id', run_state.run_id, 'execution_id', run_state.execution_id, ...
    'terminal_class', terminal_class, ...
    'scientific_terminal', terminal_status, ...
    'first_failure', first_failure, ...
    'attempted_solves', run_state.attempted_solves, ...
    'completed_solves', run_state.completed_solves, ...
    'planned_solves', run_state.planned_solves, ...
    'claim_boundary', spec.claim_boundary, 'spec', spec, ...
    'mesh_descriptor', mesh_descriptor, ...
    'solve_ledger', LOCAL_compact_ledger(solve_ledger), ...
    'candidate_inventory', ...
    LOCAL_compact_candidate_inventory(candidate_inventory), ...
    'tracking', tracking, ...
    'selected_candidate', LOCAL_compact_selected(selected_candidate));
  try
    LOCAL_atomic_save(fullfile(output_dir, 'scientific-result.mat'), payload);
  catch caught
    LOCAL_raise('CANONICAL_PUBLICATION_FAILURE', caught.message);
  end
end

function LOCAL_publish_fields(output_dir, spec, mesh, solve_ledger, ...
    inventory, selected)
  payload = struct('schema_version', 'i4a-s30-fields-v1', ...
    'run_id', 'run-008', 'execution_id', 'execution-001', ...
    'claim_boundary', spec.claim_boundary, ...
    'mesh_id', mesh.id, 'points', mesh.points, ...
    'triangles', mesh.triangles, ...
    'material_inside', mesh.material_inside, ...
    'theta_5', spec.theta_5, ...
    'solve_ledger', LOCAL_compact_ledger(solve_ledger), ...
    'objects', inventory.objects, ...
    'winner_candidate_id', selected.candidate_id, ...
    'lambda_30', selected.lambda_30, 'k_30', selected.k_30);
  try
    LOCAL_atomic_save(fullfile(output_dir, 'fields.mat'), payload);
  catch caught
    LOCAL_raise('CANONICAL_PUBLICATION_FAILURE', caught.message);
  end
end

function compact = LOCAL_compact_ledger(ledger)
  compact = ledger;
  if ~isempty(compact)
    compact = rmfield(compact, 'path');
  end
end

function compact = LOCAL_compact_candidate_inventory(inventory)
  compact = inventory;
  if isempty(compact) || ~isfield(compact, 'objects')
    return;
  end
  for object_index = 1:numel(compact.objects)
    compact.objects(object_index).raw_subspace = [];
    compact.objects(object_index).subspace = [];
    compact.objects(object_index).common_core_samples = [];
    compact.objects(object_index).common_core_weights = [];
  end
  for candidate_index = 1:numel(compact.candidates)
    compact.candidates(candidate_index).publication = ...
      LOCAL_compact_publication( ...
      compact.candidates(candidate_index).publication);
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


%% ==================== Geometry-fitted P1 mesh ====================
% These reviewed helpers construct and verify the single sharp-interface mesh.

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
  try
    dt = delaunayTriangulation(points, constraints);
  catch caught
    LOCAL_raise('MESH_QUALITY_UNRESOLVED', ...
      ['The fitted triangulation could not be constructed: ' caught.message]);
  end
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
    'hausdorff_accuracy_pass', mesh_spec.n_gamma < 48 || ...
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

%% ==================== Quasiperiodic spectra ====================
% These reviewed helpers assemble and verify each 48-root generalized spectrum.

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
  try
    [vectors_reduced, diagonal_values, solver_flag] = eigs( ...
      pair.stiffness, pair.mass, requested_nev, 'smallestabs', options);
  catch caught
    LOCAL_raise('SPECTRUM_INVENTORY_TRUNCATED', ...
      ['The generalized eigensolver failed: ' caught.message]);
  end
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

%% ==================== Deterministic overlap assignment ====================
% These reviewed helpers implement adjacent-twist maximum-total-overlap matching.

function edges = LOCAL_empty_tracking_edges()
  edges = struct('source_object_id', {}, 'target_object_id', {}, ...
    'axis', {}, 'kind', {}, 'overlap', {}, ...
    'frequency_distance', {}, 'low_overlap', {}, ...
    'dimension_changed', {}, 'mutual_best', {});
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

function root = LOCAL_find_parent(parent, node)
  root = node;
  while parent(root) ~= root
    root = parent(root);
  end
end

%% ==================== Field diagnostics and scalar helpers ====================
% These reviewed helpers define parity, common-core samples, and rank projections.

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
