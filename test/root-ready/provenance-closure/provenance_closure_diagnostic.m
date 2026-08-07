function results = provenance_closure_diagnostic(run_label)
% PROVENANCE_CLOSURE_DIAGNOSTIC Audit source-derived shared A,b provenance.
%
% Purpose:
%   Compare an unmodified package proxy output with a source-exact test-local
%   copy that returns its existing A, b, and coeffs locals. Preserve one
%   baseline and one unchanged-source repeat without running any root stage.
%
% Input:
%   run_label - Exactly 'baseline' or 'repeat'.
%
% Output:
%   results - Source, shared-system, solver, object, gate, and repeat evidence.
%
% Main algorithm:
%   1. Lock package path/hash and byte-check the copied executable body.
%   2. Reject the frozen in-memory arithmetic-token mutation.
%   3. Compare package/copy public outputs in one process.
%   4. Feed one returned A,b pair to all collocation comparison solvers.
%   5. Recheck shifted residuals and the frozen 1e-5 object comparisons.
%   6. Compare the preserved repeat with the preserved baseline.
%
% Based on:
%   research/projects/eig-apost/implementation/root_readiness.md,
%   pre-execution provenance-closure addendum v1.1.
%
% Main changes:
%   Unlike test/root-ready/root_ready_diagnostic.m, primary collocation
%   arithmetic is not independently reconstructed. The old experiment and
%   its outputs remain untouched.
%
% Numerical goal:
%   Establish only SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS when every
%   frozen provenance, numerical, object, negative, and repeat gate passes.

  if nargin ~= 1 || ...
      ~(strcmp(run_label, 'baseline') || strcmp(run_label, 'repeat'))
    error('provenance_closure_diagnostic:RunLabel', ...
      'run_label must be exactly baseline or repeat.');
  end

  started = tic;
  here = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(fileparts(here)));
  output_root = fullfile(here, 'output');
  staging_output_root = fullfile(here, 'output.inprogress');
  output_dir = fullfile(staging_output_root, run_label);
  if exist(output_dir, 'dir') ~= 7 || exist(output_root, 'dir') == 7
    error('provenance_closure_diagnostic:TransactionState', ...
      'Wrapper must prepare only the in-progress run directory.');
  end
  result_path = fullfile(output_dir, 'results.mat');
  if exist(result_path, 'file') == 2
    error('provenance_closure_diagnostic:PreserveRun', ...
      'Refusing to overwrite preserved result %s.', result_path);
  end

  baseline = struct();
  if strcmp(run_label, 'repeat')
    baseline_path = fullfile(staging_output_root, 'baseline', 'results.mat');
    if exist(baseline_path, 'file') ~= 2
      error('provenance_closure_diagnostic:MissingBaseline', ...
        'Repeat requires preserved baseline %s.', baseline_path);
    end
    loaded = load(baseline_path);
    baseline = loaded.results;
    if ~LOCAL_validate_completion_marker( ...
        baseline, fullfile(staging_output_root, 'baseline'), ...
        staging_output_root)
      error('provenance_closure_diagnostic:InvalidBaselineMarker', ...
        'Repeat requires a baseline marker with matching artifact hashes.');
    end
  end

  cfg = LOCAL_config(repo_root, here, staging_output_root, ...
    output_dir, output_root);
  source = LOCAL_source_audit(cfg);
  mutation = LOCAL_mutation_negative(source.copy_body_bytes, cfg);
  source_ready = source.package_source_lock_pass && ...
    source.source_exact_copy_body_pass && ...
    source.source_copy_context_independence_pass && ...
    source.execution_manifest_complete_pass && ...
    mutation.synthetic_source_mutation_rejected_pass;

  if source_ready
    numeric = LOCAL_run_numeric(cfg, started);
  else
    numeric = LOCAL_empty_numeric();
  end

  core_gates = LOCAL_core_gates(cfg, source, mutation, numeric, source_ready);
  source_record = rmfield(source, ...
    {'package_body_bytes', 'copy_body_bytes'});
  results.cfg = cfg;
  results.run_label = run_label;
  results.source_copy = source_record;
  results.synthetic_source_mutation = mutation;
  results.shared_system = numeric.shared_system;
  results.solver_comparison = numeric.solver_comparison;
  results.off_collocation = numeric.off_collocation;
  results.projector_fingerprints = numeric.projector_fingerprints;
  results.projectors = numeric.projectors;
  results.historical_projector_comparison = ...
    numeric.historical_projector_comparison;
  results.resolution = numeric.resolution;
  results.downstream_mismatch = numeric.downstream_mismatch;
  results.gates = core_gates;
  results.status = 'PROVENANCE_CLOSURE_DIAGNOSTIC_COMPLETE';
  results.root_readiness = 'BLOCKED_UPSTREAM_PROVENANCE';
  results.root_readiness_sampled_discrete_go = false;
  results.physical_root_ready = 'STOP';
  results.production_internal_A_b_identity = 'NOT_DIRECTLY_OBSERVED';
  results.not_run = { ...
    'candidate_scan', 'candidate_disk', 'full_F_CR', 'root_count', ...
    'bordered_Newton', 'eigenvalue', 'adjacent_level_matching', 'estimator'};
  results.repro_vector = LOCAL_repro_vector(results);

  if strcmp(run_label, 'baseline')
    reproducibility = LOCAL_pending_reproducibility();
    repeat_gate = LOCAL_gate('two_run_reproducibility', 1, NaN, ...
      false, false, 'PENDING_REPEAT');
  else
    reproducibility = LOCAL_compare_runs(baseline, results);
    repeat_gate = LOCAL_gate('two_run_reproducibility', 1, ...
      reproducibility.pass, reproducibility.pass, true, ...
      LOCAL_reason(reproducibility.pass, ...
        'PROVENANCE_REPRODUCIBILITY_FAILURE'));
  end
  results.reproducibility = reproducibility;
  results.gates(end + 1) = repeat_gate;
  results.gates(end + 1) = LOCAL_gate('artifact_bundle_complete', 1, ...
    false, false, false, 'PENDING_FINALIZATION');

  required = { ...
    'package_source_lock', 'source_exact_copy_body', ...
    'source_copy_context_independence', 'execution_manifest_complete', ...
    'package_copy_public_output_bitwise', 'copy_coefficients_bitwise', ...
    'shared_A_b_raw_fingerprints', ...
    'mirrored_constructor_coefficient_output_reproduction', ...
    'mirrored_constructor_proxy_field_output_reproduction', ...
    'mirrored_constructor_residual_output_reproduction', ...
    'object_compatibility_resolution', ...
    'object_compatibility_downstream', 'object_compatibility_all', ...
    'synthetic_source_mutation_rejected', 'two_run_reproducibility', ...
    'artifact_bundle_complete'};
  results.required_gate_names = required;
  results.source_derived_shared_A_b_provenance_pass = false;
  results.operational_label = ...
    'SOURCE_DERIVED_SHARED_A_B_PROVENANCE_BLOCKED';
  results.finalization_state = 'PROVISIONAL_BLOCKED';
  results.completion_marker_required = true;
  results.completion_marker_relative_path = ...
    [run_label, '/completion.marker'];
  results.completion_marker_path = fullfile( ...
    output_root, run_label, 'completion.marker');
  transient_marker_path = fullfile(output_dir, 'completion.marker');
  results.completion_marker_contract = ...
    'MUST_EXIST_AND_LIST_FINAL_ARTIFACT_SHA256';
  results.log_closed = false;
  results.artifact_bundle = struct('pass', false, ...
    'contract', 'COMPLETION_MARKER_HASHES_ARE_AUTHORITATIVE');
  results.elapsed_seconds = toc(started);

  LOCAL_write_outputs(results, output_dir);
  save(result_path, 'results', '-v7');
  if strcmp(run_label, 'repeat')
    LOCAL_write_reproducibility(results, ...
      fullfile(staging_output_root, 'reproducibility.txt'));
  end
  diary('off');
  results.log_closed = true;

  artifact_bundle = LOCAL_verify_artifact_bundle( ...
    output_dir, staging_output_root, run_label, false);
  if artifact_bundle.pass
    results.artifact_bundle = struct('pass', true, ...
      'contract', 'COMPLETION_MARKER_HASHES_ARE_AUTHORITATIVE');
  else
    results.artifact_bundle = struct('pass', false, ...
      'contract', 'COMPLETION_MARKER_HASHES_ARE_AUTHORITATIVE');
  end
  artifact_gate = find(strcmp( ...
    {results.gates.gate}, 'artifact_bundle_complete'));
  results.gates(artifact_gate) = LOCAL_gate( ...
    'artifact_bundle_complete', 1, artifact_bundle.pass, ...
    artifact_bundle.pass, true, LOCAL_reason(artifact_bundle.pass, ...
      'ARTIFACT_BUNDLE_INCOMPLETE'));
  results.source_derived_shared_A_b_provenance_pass = ...
    LOCAL_required_gates_pass(results.gates, required);
  if results.source_derived_shared_A_b_provenance_pass
    results.operational_label = ...
      'SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS';
    results.finalization_state = 'FINAL_COMPLETE_PASS';
  elseif artifact_bundle.pass
    results.finalization_state = 'FINAL_COMPLETE_BLOCKED';
  else
    results.finalization_state = 'FINAL_INCOMPLETE_BLOCKED';
  end
  results.elapsed_seconds = toc(started);

  LOCAL_write_outputs(results, output_dir);
  save(result_path, 'results', '-v7');
  if strcmp(run_label, 'repeat')
    LOCAL_write_reproducibility(results, ...
      fullfile(staging_output_root, 'reproducibility.txt'));
  end
  final_bundle = LOCAL_verify_artifact_bundle( ...
    output_dir, staging_output_root, run_label, true);
  if ~final_bundle.pass
    results.artifact_bundle = struct('pass', false, ...
      'contract', 'COMPLETION_MARKER_HASHES_ARE_AUTHORITATIVE');
    results.gates(artifact_gate) = LOCAL_gate( ...
      'artifact_bundle_complete', 1, false, false, true, ...
      'ARTIFACT_BUNDLE_INCOMPLETE');
    results.source_derived_shared_A_b_provenance_pass = false;
    results.operational_label = ...
      'SOURCE_DERIVED_SHARED_A_B_PROVENANCE_BLOCKED';
    results.finalization_state = 'FINAL_INCOMPLETE_BLOCKED';
    LOCAL_write_outputs(results, output_dir);
    save(result_path, 'results', '-v7');
    if strcmp(run_label, 'repeat')
      LOCAL_write_reproducibility(results, ...
        fullfile(staging_output_root, 'reproducibility.txt'));
    end
    error('provenance_closure_diagnostic:ArtifactBundle', ...
      'Final artifact validation failed; no marker or publication written.');
  end
  try
    LOCAL_check_runtime(started, cfg.runtime_limit_seconds);
    LOCAL_write_completion_marker(results, output_dir, ...
      staging_output_root, transient_marker_path, started, ...
      cfg.runtime_limit_seconds);
  catch runtime_error
    if strcmp(runtime_error.identifier, ...
        'provenance_closure_diagnostic:RuntimeLimit')
      results = LOCAL_write_timeout_blocked(results, artifact_gate, ...
        output_dir, result_path, staging_output_root, ...
        transient_marker_path, started);
    end
    rethrow(runtime_error);
  end
  if strcmp(run_label, 'repeat')
    try
      LOCAL_check_runtime(started, cfg.runtime_limit_seconds);
    catch runtime_error
      if exist(transient_marker_path, 'file') == 2
        delete(transient_marker_path);
      end
      results = LOCAL_write_timeout_blocked(results, artifact_gate, ...
        output_dir, result_path, staging_output_root, ...
        transient_marker_path, started);
      rethrow(runtime_error);
    end
    [published, message] = movefile(staging_output_root, output_root);
    if ~published
      error('provenance_closure_diagnostic:AtomicPublish', ...
        'Atomic publication failed: %s', message);
    end
  end

  fprintf('Status: %s\n', results.status);
  fprintf('Operational label: %s\n', results.operational_label);
  fprintf('Production internal A,b: %s\n', ...
    results.production_internal_A_b_identity);
  fprintf('Root readiness: %s; physical root ready: %s\n', ...
    results.root_readiness, results.physical_root_ready);
  fprintf('Elapsed seconds: %.6f\n', results.elapsed_seconds);
end

%% ==================== Configuration ====================
% These helpers freeze inputs, thresholds, paths, and the direct-source manifest.

function cfg = LOCAL_config( ...
    repo_root, here, staging_output_root, output_dir, output_root)
  cfg.version = 'eig-apost-provenance-closure-v1.1';
  cfg.repo_root = repo_root;
  cfg.here = here;
  cfg.staging_output_root = staging_output_root;
  cfg.output_root = output_root;
  cfg.staging_output_dir = output_dir;
  cfg.package_path = fullfile(repo_root, '+kernel', 'precomp_proxy.m');
  cfg.copy_path = fullfile(here, 'LOCAL_precomp_proxy_instrumented.m');
  cfg.expected_package_sha256 = ...
    '3a16825064e5762f3486373fee702e94c34fa3cfdfb3b774f78f3b27eb2f9a60';
  cfg.expected_body_sha256 = ...
    'eb116bc9a359b9a50d6804891939cdfeb2b6a17eacb8a6a2a3a8e7d29bebd82c';
  cfg.k_nodes = [0.095, 0.100, 0.105];
  cfg.k_seed = 0.100;
  cfg.beta = 0.8;
  cfg.d = 2 * pi;
  cfg.primary_source = [0, 0];
  cfg.green_sources = [-0.15, 0.10, 0.22; 0.07, -0.13, 0.18];
  cfg.green_targets = [0.25, -0.20, 0.05, -0.10; ...
    -0.11, 0.17, 0.24, -0.20];
  cfg.nref = 3;
  cfg.periodic_axis = 'y';
  cfg.ratio_rank_threshold = 1e-8;
  cfg.constructor_tol = 1e-11;
  cfg.object_compatibility_tol = 1e-5;
  cfg.reproducibility_tol = 1e-13;
  cfg.bulk_axes = [0.40, 0.30];
  cfg.defect_axes = [0.28, 0.21];
  cfg.ntot = 60;
  cfg.rayleigh_M = 7;
  cfg.L = 2;
  cfg.walls = [-1, 1];
  cfg.channel_order = 'RAYLEIGH_NATIVE_ORDER';
  cfg.density_scaling = [ ...
    'h=curvelen/size(C,2);speed=sqrt(C(2,:).^2+C(5,:).^2);', ...
    'density_scale=sqrt(h*[speed,speed]).'''];
  cfg.scattering_block_order = 'R_L,T_LR,T_RL,R_R';
  cfg.off_collocation_densification = 2;
  cfg.off_collocation_rule = 'SHIFTED_DENSIFIED_MIDPOINT_2X';
  cfg.expected_solver_labels = { ...
    'package_public_anchor', 'copy_production', 'pinv_default', ...
    'explicit_svd_pinv_tol', 'ratio_rank_rseed'};
  cfg.expected_shared_rows = 6;
  cfg.expected_solver_rows_per_system = 5;
  cfg.expected_solver_rows = 30;
  cfg.required_artifacts = { ...
    'config.txt', 'source-copy.csv', 'shared-system.csv', ...
    'solver-comparison.csv', 'off-collocation.csv', ...
    'projector-fingerprint.csv', 'historical-projector.csv', ...
    'resolution.csv', 'downstream-mismatch.csv', 'gate.csv', ...
    'results.mat', 'run.log', 'report.md', 'completion.marker'};
  cfg.expected_aggregate_artifact = 'reproducibility.txt';
  cfg.historical_results_path = fullfile(repo_root, 'test', 'root-ready', ...
    'output', 'results.mat');
  cfg.runtime_limit_seconds = 3600;
  cfg.manifest_scope = 'DIRECT_PROJECT_CALLS_ONLY';
  cfg.command_baseline = [ ...
    'conda run -n octave octave --quiet --no-gui --eval ', ...
    '"addpath(''test/root-ready/provenance-closure''); ', ...
    'run_provenance_closure(''baseline'');"'];
  cfg.command_repeat = [ ...
    'conda run -n octave octave --quiet --no-gui --eval ', ...
    '"addpath(''test/root-ready/provenance-closure''); ', ...
    'run_provenance_closure(''repeat'');"'];

  cfg.proxy(1) = LOCAL_proxy_config('base', 40, 40, 24, 8, cfg);
  cfg.proxy(2) = LOCAL_proxy_config('refined', 48, 48, 28, 10, cfg);

  paths = { ...
    fullfile(here, 'provenance_closure_diagnostic.m'), ...
    fullfile(here, 'run_provenance_closure.m'), cfg.copy_path, ...
    cfg.package_path, ...
    fullfile(repo_root, 'research', 'projects', 'eig-apost', ...
      'implementation', 'root_readiness.md'), ...
    fullfile(repo_root, '+kernel', 'qpgreen_mfs_pairmat.m'), ...
    fullfile(repo_root, '+geom', 'construct_cont.m'), ...
    fullfile(repo_root, '+op', 'construct_A_QP.m'), ...
    fullfile(repo_root, '+bloch', 'rayleigh_channels.m'), ...
    fullfile(repo_root, '+bloch', 'incident_rhs.m'), ...
    fullfile(repo_root, '+bloch', 'farfield_extractors.m')};
  names = { ...
    'driver', 'wrapper', 'instrumented_copy', 'precomp_proxy', 'design', ...
    'qpgreen_pairmat', 'construct_cont', 'construct_A_QP', ...
    'rayleigh_channels', 'incident_rhs', 'farfield_extractors'};
  cfg.expected_manifest_names = names;
  for idx = 1:length(paths)
    cfg.source_hashes.(names{idx}).path = paths{idx};
    cfg.source_hashes.(names{idx}).sha256 = LOCAL_source_hash(paths{idx});
  end
end

function pcfg = LOCAL_proxy_config(label, n_side, n_top, n_proxy_edge, m_pw, cfg)
  pcfg.label = label;
  pcfg.beta = cfg.beta;
  pcfg.d = cfg.d;
  pcfg.H = 1.8;
  pcfg.proxy_dist = 0.7;
  pcfg.N_side = n_side;
  pcfg.N_top = n_top;
  pcfg.N_proxy_edge = n_proxy_edge;
  pcfg.M_pw = m_pw;
end

function pars1 = LOCAL_pars1(k, cfg)
  pars1.k = k;
  pars1.beta = cfg.beta;
  pars1.d = cfg.d;
  pars1.periodic_axis = cfg.periodic_axis;
end

function pars2 = LOCAL_pars2(pcfg)
  pars2.H = pcfg.H;
  pars2.proxy_dist = pcfg.proxy_dist;
  pars2.N_side = pcfg.N_side;
  pars2.N_top = pcfg.N_top;
  pars2.N_proxy_edge = pcfg.N_proxy_edge;
  pars2.M_pw = pcfg.M_pw;
end

%% ==================== Source provenance ====================
% These helpers enforce the frozen source lock before numerical evaluation.

function audit = LOCAL_source_audit(cfg)
  resolved = which('kernel.precomp_proxy');
  package_text = LOCAL_read_bytes(cfg.package_path);
  copy_text = LOCAL_read_bytes(cfg.copy_path);
  package_body_bytes = LOCAL_extract_body(package_text);
  copy_body_bytes = LOCAL_extract_body(copy_text);
  package_sha = LOCAL_source_hash(cfg.package_path);
  copy_sha = LOCAL_source_hash(cfg.copy_path);
  package_body_sha = LOCAL_text_sha256(package_body_bytes);
  copy_body_sha = LOCAL_text_sha256(copy_body_bytes);

  forbidden = { ...
    'mfilename', 'nargout', 'nargin', 'dbstack', 'eval(', 'evalin', ...
    'assignin', 'persistent', 'global', 'rand(', 'randn(', 'rng('};
  found = {};
  package_body_text = char(package_body_bytes(:).');
  for idx = 1:length(forbidden)
    if ~isempty(strfind(package_body_text, forbidden{idx})) %#ok<STREMP>
      found{end + 1} = forbidden{idx}; %#ok<AGROW>
    end
  end
  if exist('lsqminnorm', 'file')
    branch = 'lsqminnorm';
  else
    branch = 'pinv';
  end

  audit.package_path = cfg.package_path;
  audit.resolved_package_path = resolved;
  audit.copy_path = cfg.copy_path;
  audit.package_source_sha256 = package_sha;
  audit.copy_source_sha256 = copy_sha;
  audit.package_body_sha256 = package_body_sha;
  audit.copy_body_sha256 = copy_body_sha;
  audit.expected_package_sha256 = cfg.expected_package_sha256;
  audit.expected_body_sha256 = cfg.expected_body_sha256;
  audit.body_byte_equal = isequal(package_body_bytes, copy_body_bytes);
  audit.copy_structure_pass = LOCAL_copy_structure_pass( ...
    copy_text, copy_body_bytes);
  audit.forbidden_constructs = LOCAL_join(found, ';');
  audit.minimum_norm_solver_branch = branch;
  audit.package_source_lock_pass = strcmp(resolved, cfg.package_path) && ...
    strcmp(package_sha, cfg.expected_package_sha256);
  audit.source_exact_copy_body_pass = audit.body_byte_equal && ...
    audit.copy_structure_pass && ...
    strcmp(package_body_sha, cfg.expected_body_sha256) && ...
    strcmp(copy_body_sha, cfg.expected_body_sha256);
  audit.source_copy_context_independence_pass = isempty(found);
  audit.execution_manifest_complete_pass = ...
    LOCAL_execution_manifest_complete( ...
      cfg.source_hashes, cfg.expected_manifest_names);
  audit.source_transform = ...
    'DECLARATION_OUTPUT_LIST_ONLY_PLUS_NONEXECUTABLE_HELP_TEXT';
  audit.package_body_bytes = package_body_bytes;
  audit.copy_body_bytes = copy_body_bytes;
end

function pass = LOCAL_execution_manifest_complete( ...
    source_hashes, expected_names)
  names = fieldnames(source_hashes);
  pass = length(names) == 11 && ...
    length(expected_names) == 11 && ...
    isequal(sort(names), sort(expected_names(:)));
  paths = cell(size(names));
  for idx = 1:length(names)
    item = source_hashes.(names{idx});
    paths{idx} = item.path;
    info = dir(item.path);
    regular = length(info) == 1 && ~info.isdir;
    absolute = ~isempty(item.path) && item.path(1) == filesep;
    valid_digest = ~isempty(regexp( ...
      item.sha256, '^[0-9a-f]{64}$', 'once'));
    pass = pass && absolute && regular && valid_digest;
  end
  pass = pass && length(unique(paths)) == length(paths);
end

function pass = LOCAL_copy_structure_pass(copy_text, copy_body_bytes)
  copy_text_view = char(copy_text(:).');
  copy_body_view = char(copy_body_bytes(:).');
  starts = strfind(copy_text_view, copy_body_view);
  pass = length(starts) == 1;
  if ~pass
    return;
  end
  prefix = char(copy_text(1:starts(1) - 1));
  suffix = char(copy_text(starts(1) + length(copy_body_bytes):end));
  lines = strsplit(prefix, sprintf('\n'));
  expected_first = 'function [proxy,A,b,coeffs] = ...';
  expected_second = '  LOCAL_precomp_proxy_instrumented(pars1,pars2)';
  pass = length(lines) >= 2 && strcmp(lines{1}, expected_first) && ...
    strcmp(lines{2}, expected_second) && strcmp(strtrim(suffix), 'end');
  for idx = 3:length(lines)
    item = strtrim(lines{idx});
    pass = pass && (isempty(item) || item(1) == '%');
  end
end

function mutation = LOCAL_mutation_negative(copy_body_bytes, cfg)
  target = uint8('(1i/4)');
  replacement = uint8('(1i/5)');
  locations = strfind( ...
    char(copy_body_bytes(:).'), char(target(:).'));
  mutation.target = target;
  mutation.replacement = replacement;
  mutation.target_count = length(locations);
  mutation.executed = false;
  mutation.mutated_body_sha256 = '';
  mutation.verifier_failure_reason = '';
  if length(locations) == 1
    first = locations(1);
    mutated = [copy_body_bytes(1:first - 1), replacement, ...
      copy_body_bytes(first + length(target):end)];
    mutation.mutated_body_sha256 = LOCAL_text_sha256(mutated);
    if ~isequal(mutated, copy_body_bytes) && ...
        ~strcmp(mutation.mutated_body_sha256, cfg.expected_body_sha256)
      mutation.verifier_failure_reason = 'SOURCE_COPY_BODY_MISMATCH';
    end
  end
  mutation.synthetic_source_mutation_rejected_pass = ...
    mutation.target_count == 1 && ...
    strcmp(mutation.verifier_failure_reason, 'SOURCE_COPY_BODY_MISMATCH');
end

function body = LOCAL_extract_body(text_value)
  start_marker = uint8('% --- 1. Configurable Parameters ---');
  end_marker = uint8( ...
    'proxy.C_down = coeffs(N_proxy+N_pw_total+1:end);');
  text_view = char(text_value(:).');
  starts = strfind(text_view, char(start_marker));
  stops = strfind(text_view, char(end_marker));
  if length(starts) ~= 1 || length(stops) ~= 1 || stops(1) < starts(1)
    error('provenance_closure_diagnostic:BodyMarkers', ...
      'Expected exactly one ordered executable-body marker pair.');
  end
  last = stops(1) + length(end_marker) - 1;
  if last < length(text_value) && text_value(last + 1) == uint8(10)
    last = last + 1;
  end
  body = text_value(starts(1):last);
end

function value = LOCAL_text_sha256(text_value)
  value = hash('sha256', char(text_value(:).'));
end

function bytes = LOCAL_read_bytes(path)
  fid = fopen(path, 'rb');
  if fid < 0
    error('provenance_closure_diagnostic:BinaryRead', ...
      'Could not open binary source file %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  bytes = fread(fid, Inf, '*uint8').';
end

%% ==================== Shared-system numerical audit ====================
% These helpers use only copy-returned collocation arrays for comparison rows.

function numeric = LOCAL_run_numeric(cfg, started)
  numeric = LOCAL_empty_numeric();
  seed = struct([]);
  solver_cache = struct([]);
  template = struct('config', '', 'k', NaN, 'pars1', struct(), ...
    'pars2', struct(), 'proxy_package', struct(), 'proxy_copy', struct(), ...
    'A_shared', [], 'b_shared', [], 'coeffs_copy', []);
  system_cache = repmat(template, length(cfg.proxy), length(cfg.k_nodes));

  for ic = 1:length(cfg.proxy)
    pcfg = cfg.proxy(ic);
    pars2 = LOCAL_pars2(pcfg);
    for ik = 1:length(cfg.k_nodes)
      LOCAL_check_runtime(started, cfg.runtime_limit_seconds);
      k = cfg.k_nodes(ik);
      pars1 = LOCAL_pars1(k, cfg);
      proxy_package = kernel.precomp_proxy(pars1, pars2);
      [proxy_copy, A_shared, b_shared, coeffs_copy] = ...
        LOCAL_precomp_proxy_instrumented(pars1, pars2);
      system_cache(ic, ik) = struct('config', pcfg.label, 'k', k, ...
        'pars1', pars1, 'pars2', pars2, ...
        'proxy_package', proxy_package, 'proxy_copy', proxy_copy, ...
        'A_shared', A_shared, 'b_shared', b_shared, ...
        'coeffs_copy', coeffs_copy);
    end
  end

  seed_matches = find(abs(cfg.k_nodes - cfg.k_seed) < 10 * eps);
  if length(seed_matches) ~= 1
    error('provenance_closure_diagnostic:SeedIndex', ...
      'Expected one frozen k_seed entry in k_nodes.');
  end
  seed_index = seed_matches(1);
  for ic = 1:length(cfg.proxy)
    pcfg = cfg.proxy(ic);
    cached_seed = system_cache(ic, seed_index);
    [U_seed, S_seed, V_seed] = svd(cached_seed.A_shared, 'econ');
    s_seed = diag(S_seed);
    ratio_rank = sum(s_seed / s_seed(1) >= cfg.ratio_rank_threshold);
    U_r = U_seed(:, 1:ratio_rank);
    V_r = V_seed(:, 1:ratio_rank);
    P_left = U_r * U_r';
    P_right = V_r * V_r';
    seed(ic).U = U_seed;
    seed(ic).V = V_seed;
    seed(ic).s = s_seed;
    seed(ic).rank = ratio_rank;
    seed(ic).meta = LOCAL_proxy_meta(cached_seed.proxy_copy);
    numeric.projector_fingerprints(end + 1) = struct( ...
      'config', pcfg.label, 'rank', ratio_rank, ...
      'left_rows', size(P_left, 1), 'left_cols', size(P_left, 2), ...
      'right_rows', size(P_right, 1), 'right_cols', size(P_right, 2), ...
      'left_trace', real(trace(P_left)), ...
      'right_trace', real(trace(P_right)), ...
      'left_idempotence', LOCAL_relmat(P_left * P_left, P_left), ...
      'right_idempotence', LOCAL_relmat(P_right * P_right, P_right), ...
      'left_sha256', LOCAL_raw_fingerprint(P_left), ...
      'right_sha256', LOCAL_raw_fingerprint(P_right));
    numeric.projectors(end + 1) = struct( ...
      'config', pcfg.label, 'rank', ratio_rank, ...
      'left', P_left, 'right', P_right);
  end

  for ic = 1:length(cfg.proxy)
    pcfg = cfg.proxy(ic);
    for ik = 1:length(cfg.k_nodes)
      LOCAL_check_runtime(started, cfg.runtime_limit_seconds);
      cached = system_cache(ic, ik);
      k = cached.k;
      pars1 = cached.pars1;
      pars2 = cached.pars2;
      proxy_package = cached.proxy_package;
      proxy_copy = cached.proxy_copy;
      A_shared = cached.A_shared;
      b_shared = cached.b_shared;
      coeffs_copy = cached.coeffs_copy;
      meta = LOCAL_proxy_meta(proxy_copy);
      coeffs_package = LOCAL_proxy_coefficients(proxy_package);
      coeffs_from_proxy_copy = LOCAL_proxy_coefficients(proxy_copy);
      package_field = LOCAL_field_vector(pars1, proxy_package, cfg);
      copy_field = LOCAL_field_vector(pars1, proxy_copy, cfg);
      A_shared_sha256 = LOCAL_raw_fingerprint(A_shared);
      b_shared_sha256 = LOCAL_raw_fingerprint(b_shared);
      package_residual = norm(A_shared * coeffs_package - b_shared, 2) / ...
        max(1, norm(b_shared, 2));
      copy_residual = norm(A_shared * coeffs_copy - b_shared, 2) / ...
        max(1, norm(b_shared, 2));

      public_equal = LOCAL_proxy_bitwise_equal(proxy_package, proxy_copy);
      coefficient_equal = LOCAL_numeric_bitwise_equal( ...
        coeffs_copy, coeffs_from_proxy_copy);
      [~, ~, endian] = computer();
      numeric.shared_system(end + 1) = struct( ...
        'config', pcfg.label, 'k', k, ...
        'A_rows', size(A_shared, 1), 'A_cols', size(A_shared, 2), ...
        'b_rows', size(b_shared, 1), 'b_cols', size(b_shared, 2), ...
        'numeric_class', class(A_shared), 'endianness', endian, ...
        'A_shared_sha256', A_shared_sha256, ...
        'b_shared_sha256', b_shared_sha256, ...
        'package_copy_public_output_bitwise', public_equal, ...
        'copy_coefficients_bitwise', coefficient_equal, ...
        'coefficient_output_error', LOCAL_relmat( ...
          coeffs_copy, coeffs_package), ...
        'proxy_field_output_error', LOCAL_relmat(copy_field, package_field), ...
        'residual_output_error', abs(copy_residual - package_residual));

      [U_now, S_now, V_now] = svd(A_shared, 'econ');
      s_now = diag(S_now);
      pinv_tol = max(size(A_shared)) * s_now(1) * eps;
      evals = LOCAL_solver_evaluations(A_shared, b_shared, meta, ...
        coeffs_package, coeffs_copy, U_now, s_now, V_now, ...
        seed(ic).U, seed(ic).V, seed(ic).rank, pinv_tol, pars1, ...
        cfg, A_shared_sha256, b_shared_sha256);
      [off_A, off_b, off_meta] = LOCAL_build_off_collocation_system( ...
        k, pars1, pars2, proxy_copy, cfg);
      for ie = 1:length(evals)
        numeric.solver_comparison(end + 1) = LOCAL_solver_row( ...
          pcfg.label, k, evals(ie));
        numeric.off_collocation(end + 1) = LOCAL_off_row( ...
          pcfg.label, k, evals(ie), off_A, off_b, off_meta);
      end
      solver_cache(ic, ik).config = pcfg.label;
      solver_cache(ic, ik).k = k;
      solver_cache(ic, ik).package = LOCAL_find_evaluation( ...
        evals, 'package_public_anchor');
      solver_cache(ic, ik).selected = LOCAL_find_evaluation( ...
        evals, 'ratio_rank_rseed');
    end
  end

  numeric.resolution = LOCAL_resolution_rows(cfg, solver_cache, ...
    numeric.off_collocation, seed);
  numeric.downstream_mismatch = LOCAL_downstream_rows(cfg, solver_cache);
  numeric.historical_projector_comparison = ...
    LOCAL_historical_projector_comparison(cfg, numeric.projectors);
  LOCAL_check_runtime(started, cfg.runtime_limit_seconds);
  numeric.package_copy_public_output_bitwise_pass = ...
    all([numeric.shared_system.package_copy_public_output_bitwise]);
  numeric.copy_coefficients_bitwise_pass = ...
    all([numeric.shared_system.copy_coefficients_bitwise]);
  numeric.shared_A_b_raw_fingerprints_pass = ...
    LOCAL_shared_fingerprints_pass(numeric.shared_system, ...
      numeric.solver_comparison, cfg);
end

function LOCAL_check_runtime(started, limit_seconds)
  if toc(started) > limit_seconds
    error('provenance_closure_diagnostic:RuntimeLimit', ...
      'Runtime exceeded the frozen %d second limit.', limit_seconds);
  end
end

function numeric = LOCAL_empty_numeric()
  numeric.shared_system = struct('config', {}, 'k', {}, ...
    'A_rows', {}, 'A_cols', {}, 'b_rows', {}, 'b_cols', {}, ...
    'numeric_class', {}, 'endianness', {}, ...
    'A_shared_sha256', {}, 'b_shared_sha256', {}, ...
    'package_copy_public_output_bitwise', {}, ...
    'copy_coefficients_bitwise', {}, 'coefficient_output_error', {}, ...
    'proxy_field_output_error', {}, 'residual_output_error', {});
  numeric.solver_comparison = LOCAL_empty_solver_rows();
  numeric.off_collocation = LOCAL_empty_off_rows();
  numeric.projector_fingerprints = struct( ...
    'config', {}, 'rank', {}, 'left_rows', {}, 'left_cols', {}, ...
    'right_rows', {}, 'right_cols', {}, 'left_trace', {}, ...
    'right_trace', {}, 'left_idempotence', {}, 'right_idempotence', {}, ...
    'left_sha256', {}, 'right_sha256', {});
  numeric.projectors = struct('config', {}, 'rank', {}, ...
    'left', {}, 'right', {});
  numeric.resolution = struct('k', {}, 'base_rank', {}, ...
    'refined_rank', {}, 'base_full_residual', {}, ...
    'refined_full_residual', {}, 'base_off_residual', {}, ...
    'refined_off_residual', {}, 'green_pot_diff', {}, ...
    'green_grad_diff', {}, 'green_hess_diff', {}, 'status', {});
  numeric.downstream_mismatch = struct('k', {}, 'geometry', {}, ...
    'quantity', {}, 'solver_a', {}, 'solver_b', {}, ...
    'relative_difference', {}, 'rcond', {}, 'solve_residual', {}, ...
    'status', {});
  numeric.historical_projector_comparison = ...
    LOCAL_empty_historical_projector_comparison();
  numeric.package_copy_public_output_bitwise_pass = false;
  numeric.copy_coefficients_bitwise_pass = false;
  numeric.shared_A_b_raw_fingerprints_pass = false;
end

function meta = LOCAL_proxy_meta(proxy)
  meta.Z_proxy = proxy.Z.';
  meta.H = proxy.H;
  meta.n_proxy = numel(proxy.q);
  meta.n_pw = numel(proxy.C_up);
end

function evaluations = LOCAL_solver_evaluations(A, b, meta, ...
    package_coeffs, copy_coeffs, U_now, s_now, V_now, ...
    U_seed, V_seed, ratio_rank, pinv_tol, pars1, cfg, A_hash, b_hash)
  evaluations = LOCAL_empty_evaluations();
  rank_pinv = sum(s_now > pinv_tol);
  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'package_public_anchor', package_coeffs, NaN, pinv_tol, rank_pinv, ...
    A, b, meta, pars1, cfg, A_hash, b_hash, ...
    'unmodified package public coefficients on copy-returned A,b');
  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'copy_production', copy_coeffs, NaN, pinv_tol, rank_pinv, ...
    A, b, meta, pars1, cfg, A_hash, b_hash, ...
    'source-exact copy production coefficients');

  c_pinv = pinv(A) * b;
  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'pinv_default', c_pinv, NaN, pinv_tol, rank_pinv, ...
    A, b, meta, pars1, cfg, A_hash, b_hash, 'pinv(A)*b');

  keep = s_now > pinv_tol;
  c_svd = V_now(:, keep) * ((U_now(:, keep)' * b) ./ s_now(keep));
  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'explicit_svd_pinv_tol', c_svd, NaN, pinv_tol, sum(keep), ...
    A, b, meta, pars1, cfg, A_hash, b_hash, ...
    'explicit thin-SVD minimum-norm coefficients');

  U_r = U_seed(:, 1:ratio_rank);
  V_r = V_seed(:, 1:ratio_rank);
  reduced_A = U_r' * A * V_r;
  reduced_b = U_r' * b;
  a_r = reduced_A \ reduced_b;
  c_r = V_r * a_r;
  projected = norm(reduced_A * a_r - reduced_b, 2) / ...
    max(1, norm(reduced_b, 2));
  note = sprintf('seed-frozen two-sided chart;factor_rcond=%.17g', ...
    rcond(reduced_A));
  evaluations(end + 1) = LOCAL_make_evaluation( ...
    'ratio_rank_rseed', c_r, projected, NaN, ratio_rank, ...
    A, b, meta, pars1, cfg, A_hash, b_hash, note);
end

function ev = LOCAL_make_evaluation(name, coefficients, projected, tolerance, ...
    rank_value, A, b, meta, pars1, cfg, A_hash, b_hash, note)
  residual = A * coefficients - b;
  denominator = max(1, ...
    norm(A, 2) * norm(coefficients, 2) + norm(b, 2));
  proxy = LOCAL_proxy_from_coefficients(coefficients, meta);
  ev.name = name;
  ev.available = true;
  ev.tolerance = tolerance;
  ev.rank = rank_value;
  ev.coefficients = coefficients;
  ev.coefficient_norm = norm(coefficients, 2);
  ev.projected_residual = projected;
  ev.full_residual = norm(residual, 2) / max(1, norm(b, 2));
  ev.full_system_backward = norm(residual, 2) / denominator;
  ev.A_shared_sha256 = A_hash;
  ev.b_shared_sha256 = b_hash;
  ev.proxy = proxy;
  ev.field = LOCAL_field_vector(pars1, proxy, cfg);
  ev.status = 'COMPUTED';
  ev.note = note;
end

function ev = LOCAL_find_evaluation(evaluations, name)
  found = find(strcmp({evaluations.name}, name));
  if length(found) ~= 1
    error('provenance_closure_diagnostic:EvaluationLookup', ...
      'Expected one evaluation named %s.', name);
  end
  ev = evaluations(found);
end

function row = LOCAL_solver_row(config, k, ev)
  row = struct('config', config, 'k', k, 'solver', ev.name, ...
    'available', ev.available, 'tolerance', ev.tolerance, ...
    'rank', ev.rank, 'coefficient_norm', ev.coefficient_norm, ...
    'projected_residual', ev.projected_residual, ...
    'full_residual', ev.full_residual, ...
    'full_system_backward', ev.full_system_backward, ...
    'A_shared_sha256', ev.A_shared_sha256, ...
    'b_shared_sha256', ev.b_shared_sha256, ...
    'status', ev.status, 'note', ev.note);
end

function pass = LOCAL_shared_fingerprints_pass(shared_rows, solver_rows, cfg)
  expected_shared = length(cfg.proxy) * length(cfg.k_nodes);
  expected_solver = expected_shared * length(cfg.expected_solver_labels);
  pass = length(shared_rows) == expected_shared && ...
    length(solver_rows) == expected_solver;
  for ic = 1:length(cfg.proxy)
    for ik = 1:length(cfg.k_nodes)
      label = cfg.proxy(ic).label;
      k = cfg.k_nodes(ik);
      shared_mask = strcmp({shared_rows.config}, label) & ...
        abs([shared_rows.k] - k) < 10 * eps;
      solver_mask = strcmp({solver_rows.config}, label) & ...
        abs([solver_rows.k] - k) < 10 * eps;
      pass = pass && sum(shared_mask) == 1 && ...
        sum(solver_mask) == cfg.expected_solver_rows_per_system;
      if sum(shared_mask) == 1
        shared = shared_rows(shared_mask);
        rows = solver_rows(solver_mask);
        pass = pass && ...
          isequal(sort({rows.solver}), sort(cfg.expected_solver_labels)) && ...
          all(strcmp({rows.A_shared_sha256}, ...
            shared.A_shared_sha256)) && ...
          all(strcmp({rows.b_shared_sha256}, ...
            shared.b_shared_sha256));
      end
    end
  end
  for idx = 1:length(solver_rows)
    row = solver_rows(idx);
    mask = strcmp({shared_rows.config}, row.config) & ...
      abs([shared_rows.k] - row.k) < 10 * eps;
    solver_mask = strcmp({solver_rows.config}, row.config) & ...
      abs([solver_rows.k] - row.k) < 10 * eps & ...
      strcmp({solver_rows.solver}, row.solver);
    pass = pass && sum(mask) == 1 && ...
      sum(solver_mask) == 1;
  end
end

function rows = LOCAL_empty_solver_rows()
  rows = struct('config', {}, 'k', {}, 'solver', {}, ...
    'available', {}, 'tolerance', {}, 'rank', {}, ...
    'coefficient_norm', {}, 'projected_residual', {}, ...
    'full_residual', {}, 'full_system_backward', {}, ...
    'A_shared_sha256', {}, 'b_shared_sha256', {}, ...
    'status', {}, 'note', {});
end

function rows = LOCAL_empty_evaluations()
  rows = struct('name', {}, 'available', {}, 'tolerance', {}, ...
    'rank', {}, 'coefficients', {}, 'coefficient_norm', {}, ...
    'projected_residual', {}, 'full_residual', {}, ...
    'full_system_backward', {}, 'A_shared_sha256', {}, ...
    'b_shared_sha256', {}, 'proxy', {}, 'field', {}, ...
    'status', {}, 'note', {});
end

function coefficients = LOCAL_proxy_coefficients(proxy)
  coefficients = [proxy.q(:); proxy.C_up(:); proxy.C_down(:)];
end

function proxy = LOCAL_proxy_from_coefficients(coefficients, meta)
  nq = meta.n_proxy;
  npw = meta.n_pw;
  proxy.q = coefficients(1:nq).';
  proxy.Z = meta.Z_proxy.';
  proxy.H = meta.H;
  proxy.C_up = coefficients(nq + (1:npw));
  proxy.C_down = coefficients(nq + npw + (1:npw));
end

function field = LOCAL_field_vector(pars1, proxy, cfg)
  [pot, gradx, grady, hessxx, hessxy, hessyy] = ...
    kernel.qpgreen_mfs_pairmat( ...
      cfg.green_sources, cfg.green_targets, pars1, proxy);
  field = [pot(:); gradx(:); grady(:); hessxx(:); hessxy(:); hessyy(:)];
end

function equal = LOCAL_proxy_bitwise_equal(a, b)
  fields = {'q', 'Z', 'H', 'C_up', 'C_down'};
  equal = true;
  for idx = 1:length(fields)
    name = fields{idx};
    equal = equal && LOCAL_numeric_bitwise_equal(a.(name), b.(name));
  end
end

function equal = LOCAL_numeric_bitwise_equal(a, b)
  if ~strcmp(class(a), class(b)) || ~isequal(size(a), size(b))
    equal = false;
    return;
  end
  equal = isequal(LOCAL_raw_payload(a), LOCAL_raw_payload(b));
end

function digest = LOCAL_raw_fingerprint(A)
  digest = hash('sha256', char(LOCAL_raw_payload(A)));
end

function payload = LOCAL_raw_payload(A)
  [~, ~, endian] = computer();
  dims = sprintf('%d,', size(A));
  header = sprintf('class=%s;dims=%s;endian=%s;', class(A), dims, endian);
  real_bytes = reshape(typecast(real(A(:)), 'uint8'), 1, []);
  imag_bytes = reshape(typecast(imag(A(:)), 'uint8'), 1, []);
  payload = [uint8(header), real_bytes, imag_bytes];
end

%% ==================== Independent residual and object diagnostics ====================
% Shifted arithmetic is diagnostic-only; object comparisons retain frozen metrics.

function [A, b, meta] = LOCAL_build_off_collocation_system( ...
    k, pars1, pars2, proxy_copy, cfg)
  d = pars1.d;
  beta = pars1.beta;
  H = pars2.H;
  n_side = cfg.off_collocation_densification * pars2.N_side;
  n_top = cfg.off_collocation_densification * pars2.N_top;
  m_pw = pars2.M_pw;
  y_side = -H + ((0:n_side - 1).' + 0.5) * (2 * H / n_side);
  x_top = -d / 2 + ((0:n_top - 1).' + 0.5) * (d / n_top);
  p_L = [-d / 2 * ones(n_side, 1), y_side];
  p_R = [ d / 2 * ones(n_side, 1), y_side];
  p_T = [x_top, H * ones(n_top, 1)];
  p_B = [x_top, -H * ones(n_top, 1)];
  Z_proxy = proxy_copy.Z.';
  n_proxy = size(Z_proxy, 1);
  m_vec = (-m_pw:m_pw).';
  n_pw = length(m_vec);
  beta_m = beta + m_vec * (2 * pi / d);
  gamma_m = sqrt(k^2 - beta_m.^2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);

  A = zeros(2 * n_side + 4 * n_top, n_proxy + 2 * n_pw);
  b = zeros(2 * n_side + 4 * n_top, 1);
  idx_LR_v = 1:n_side;
  idx_LR_d = n_side + (1:n_side);
  idx_T_v = 2 * n_side + (1:n_top);
  idx_T_d = 2 * n_side + n_top + (1:n_top);
  idx_B_v = 2 * n_side + 2 * n_top + (1:n_top);
  idx_B_d = 2 * n_side + 3 * n_top + (1:n_top);
  col_proxy = 1:n_proxy;
  col_pw_T = n_proxy + (1:n_pw);
  col_pw_B = n_proxy + n_pw + (1:n_pw);
  phase = exp(1i * beta * d);
  src = cfg.primary_source;

  [V_sL, dVdx_sL, ~] = LOCAL_eval_G(k, p_L, src);
  [V_sR, dVdx_sR, ~] = LOCAL_eval_G(k, p_R, src);
  b(idx_LR_v) = -(V_sR - phase * V_sL);
  b(idx_LR_d) = -(dVdx_sR - phase * dVdx_sL);
  [V_sT, ~, dVdy_sT] = LOCAL_eval_G(k, p_T, src);
  [V_sB, ~, dVdy_sB] = LOCAL_eval_G(k, p_B, src);
  b(idx_T_v) = -V_sT;
  b(idx_T_d) = -dVdy_sT;
  b(idx_B_v) = -V_sB;
  b(idx_B_d) = -dVdy_sB;

  [V_pL, dVdx_pL, ~] = LOCAL_eval_G(k, p_L, Z_proxy);
  [V_pR, dVdx_pR, ~] = LOCAL_eval_G(k, p_R, Z_proxy);
  A(idx_LR_v, col_proxy) = V_pR - phase * V_pL;
  A(idx_LR_d, col_proxy) = dVdx_pR - phase * dVdx_pL;
  [V_pT, ~, dVdy_pT] = LOCAL_eval_G(k, p_T, Z_proxy);
  [V_pB, ~, dVdy_pB] = LOCAL_eval_G(k, p_B, Z_proxy);
  A(idx_T_v, col_proxy) = V_pT;
  A(idx_T_d, col_proxy) = dVdy_pT;
  A(idx_B_v, col_proxy) = V_pB;
  A(idx_B_d, col_proxy) = dVdy_pB;
  PW_T = exp(1i * p_T(:, 1) * beta_m.');
  PW_B = exp(1i * p_B(:, 1) * beta_m.');
  A(idx_T_v, col_pw_T) = -PW_T;
  A(idx_T_d, col_pw_T) = -PW_T .* (1i * gamma_m.');
  A(idx_B_v, col_pw_B) = -PW_B;
  A(idx_B_d, col_pw_B) = -PW_B .* (-1i * gamma_m.');
  meta.indices = {idx_LR_v, idx_LR_d, idx_T_v, ...
    idx_T_d, idx_B_v, idx_B_d};
end

function [V, dVdx, dVdy] = LOCAL_eval_G(k, pt, ps)
  dx = pt(:, 1) - ps(:, 1).';
  dy = pt(:, 2) - ps(:, 2).';
  rho = sqrt(dx.^2 + dy.^2);
  V = (1i / 4) * besselh(0, 1, k * rho);
  coefficient = -(1i * k / 4) * besselh(1, 1, k * rho) ./ rho;
  dVdx = coefficient .* dx;
  dVdy = coefficient .* dy;
end

function row = LOCAL_off_row(config, k, ev, A, b, meta)
  residual = A * ev.coefficients - b;
  values = zeros(1, 6);
  for idx = 1:6
    indices = meta.indices{idx};
    values(idx) = norm(residual(indices), 2) / ...
      max(1, norm(b(indices), 2));
  end
  row = struct('config', config, 'k', k, 'solver', ev.name, ...
    'point_set', 'shifted_densified', ...
    'qp_value_residual', values(1), ...
    'qp_derivative_residual', values(2), ...
    'top_value_residual', values(3), ...
    'top_derivative_residual', values(4), ...
    'bottom_value_residual', values(5), ...
    'bottom_derivative_residual', values(6), ...
    'combined_residual', norm(residual, 2) / max(1, norm(b, 2)), ...
    'status', 'COMPUTED');
end

function rows = LOCAL_empty_off_rows()
  rows = struct('config', {}, 'k', {}, 'solver', {}, ...
    'point_set', {}, 'qp_value_residual', {}, ...
    'qp_derivative_residual', {}, 'top_value_residual', {}, ...
    'top_derivative_residual', {}, 'bottom_value_residual', {}, ...
    'bottom_derivative_residual', {}, 'combined_residual', {}, ...
    'status', {});
end

function rows = LOCAL_empty_historical_projector_comparison()
  labels = {'base', 'refined'};
  rows = struct('config', {}, 'available', {}, 'historical_path', {}, ...
    'historical_file_sha256', {}, 'historical_rank', {}, ...
    'current_rank', {}, 'historical_left_rows', {}, ...
    'historical_left_cols', {}, 'historical_right_rows', {}, ...
    'historical_right_cols', {}, 'current_left_rows', {}, ...
    'current_left_cols', {}, 'current_right_rows', {}, ...
    'current_right_cols', {}, 'left_relative_difference', {}, ...
    'right_relative_difference', {}, 'left_equal', {}, ...
    'right_equal', {}, 'state', {}, 'note', {});
  for idx = 1:length(labels)
    rows(end + 1) = struct('config', labels{idx}, ...
      'available', false, 'historical_path', '', ...
      'historical_file_sha256', '', 'historical_rank', NaN, ...
      'current_rank', NaN, 'historical_left_rows', NaN, ...
      'historical_left_cols', NaN, 'historical_right_rows', NaN, ...
      'historical_right_cols', NaN, 'current_left_rows', NaN, ...
      'current_left_cols', NaN, 'current_right_rows', NaN, ...
      'current_right_cols', NaN, ...
      'left_relative_difference', NaN, ...
      'right_relative_difference', NaN, 'left_equal', false, ...
      'right_equal', false, 'state', 'UNAVAILABLE', ...
      'note', 'HISTORICAL_COMPARISON_NOT_ATTEMPTED');
  end
end

function rows = LOCAL_historical_projector_comparison(cfg, current)
  rows = LOCAL_empty_historical_projector_comparison();
  for idx = 1:length(rows)
    rows(idx).historical_path = cfg.historical_results_path;
  end
  if exist(cfg.historical_results_path, 'file') ~= 2
    for idx = 1:length(rows)
      rows(idx).note = 'HISTORICAL_RESULTS_MISSING_NON_GATING';
    end
    return;
  end
  historical_sha = LOCAL_source_hash(cfg.historical_results_path);
  try
    loaded = load(cfg.historical_results_path);
  catch
    for idx = 1:length(rows)
      rows(idx).historical_file_sha256 = historical_sha;
      rows(idx).note = 'HISTORICAL_RESULTS_LOAD_FAILED_NON_GATING';
    end
    return;
  end
  if ~isfield(loaded, 'results') || ...
      ~isfield(loaded.results, 'projectors')
    for idx = 1:length(rows)
      rows(idx).historical_file_sha256 = historical_sha;
      rows(idx).note = 'HISTORICAL_PROJECTORS_UNAVAILABLE_NON_GATING';
    end
    return;
  end
  old = loaded.results.projectors;
  for idx = 1:length(rows)
    label = rows(idx).config;
    old_found = find(strcmp({old.config}, label));
    new_found = find(strcmp({current.config}, label));
    rows(idx).historical_file_sha256 = historical_sha;
    if length(old_found) ~= 1 || length(new_found) ~= 1
      rows(idx).note = 'HISTORICAL_PROJECTOR_LABEL_MISMATCH_NON_GATING';
      continue;
    end
    rows(idx).available = true;
    old_row = old(old_found);
    new_row = current(new_found);
    rows(idx).historical_rank = old_row.rank;
    rows(idx).current_rank = new_row.rank;
    rows(idx).historical_left_rows = size(old_row.left, 1);
    rows(idx).historical_left_cols = size(old_row.left, 2);
    rows(idx).historical_right_rows = size(old_row.right, 1);
    rows(idx).historical_right_cols = size(old_row.right, 2);
    rows(idx).current_left_rows = size(new_row.left, 1);
    rows(idx).current_left_cols = size(new_row.left, 2);
    rows(idx).current_right_rows = size(new_row.right, 1);
    rows(idx).current_right_cols = size(new_row.right, 2);
    if isequal(size(new_row.left), size(old_row.left))
      rows(idx).left_relative_difference = ...
        LOCAL_relmat(new_row.left, old_row.left);
    else
      rows(idx).left_relative_difference = Inf;
    end
    if isequal(size(new_row.right), size(old_row.right))
      rows(idx).right_relative_difference = ...
        LOCAL_relmat(new_row.right, old_row.right);
    else
      rows(idx).right_relative_difference = Inf;
    end
    rows(idx).left_equal = strcmp(LOCAL_raw_fingerprint(old_row.left), ...
      LOCAL_raw_fingerprint(new_row.left));
    rows(idx).right_equal = strcmp(LOCAL_raw_fingerprint(old_row.right), ...
      LOCAL_raw_fingerprint(new_row.right));
    if rows(idx).left_equal && rows(idx).right_equal
      rows(idx).state = 'EQUAL';
    else
      rows(idx).state = 'DIFFERENT';
    end
    rows(idx).note = 'NON_GATING_HISTORICAL_DIAGNOSTIC';
  end
end

function rows = LOCAL_resolution_rows(cfg, cache, off_rows, seed)
  rows = struct('k', {}, 'base_rank', {}, 'refined_rank', {}, ...
    'base_full_residual', {}, 'refined_full_residual', {}, ...
    'base_off_residual', {}, 'refined_off_residual', {}, ...
    'green_pot_diff', {}, 'green_grad_diff', {}, ...
    'green_hess_diff', {}, 'status', {});
  for ik = 1:length(cfg.k_nodes)
    base = cache(1, ik).selected;
    refined = cache(2, ik).selected;
    base_off = LOCAL_off_lookup(off_rows, 'base', cfg.k_nodes(ik));
    refined_off = LOCAL_off_lookup(off_rows, 'refined', cfg.k_nodes(ik));
    [pot_diff, grad_diff, hess_diff] = LOCAL_field_component_diffs( ...
      base.field, refined.field);
    observed = max([pot_diff, grad_diff, hess_diff]);
    rows(end + 1) = struct('k', cfg.k_nodes(ik), ...
      'base_rank', seed(1).rank, 'refined_rank', seed(2).rank, ...
      'base_full_residual', base.full_residual, ...
      'refined_full_residual', refined.full_residual, ...
      'base_off_residual', base_off.combined_residual, ...
      'refined_off_residual', refined_off.combined_residual, ...
      'green_pot_diff', pot_diff, 'green_grad_diff', grad_diff, ...
      'green_hess_diff', hess_diff, ...
      'status', LOCAL_pass_status( ...
        observed <= cfg.object_compatibility_tol));
  end
end

function row = LOCAL_off_lookup(rows, config, k)
  mask = strcmp({rows.config}, config) & ...
    strcmp({rows.solver}, 'ratio_rank_rseed') & ...
    abs([rows.k] - k) < 10 * eps;
  found = find(mask);
  if length(found) ~= 1
    error('provenance_closure_diagnostic:OffLookup', ...
      'Expected one selected shifted residual row.');
  end
  row = rows(found);
end

function [pot_diff, grad_diff, hess_diff] = LOCAL_field_component_diffs(a, b)
  n_pot = 12;
  n_grad = 24;
  pot_diff = LOCAL_relmat(a(1:n_pot), b(1:n_pot));
  grad_diff = LOCAL_relmat(a(n_pot + (1:n_grad)), ...
    b(n_pot + (1:n_grad)));
  hess_diff = LOCAL_relmat(a(n_pot + n_grad + 1:end), ...
    b(n_pot + n_grad + 1:end));
end

function rows = LOCAL_downstream_rows(cfg, cache)
  rows = struct('k', {}, 'geometry', {}, 'quantity', {}, ...
    'solver_a', {}, 'solver_b', {}, 'relative_difference', {}, ...
    'rcond', {}, 'solve_residual', {}, 'status', {});
  [defect_geom, defect_length] = geom.construct_cont(cfg.ntot, ...
    'ellipse', 0, 0, cfg.defect_axes);
  [bulk_geom, bulk_length] = geom.construct_cont(cfg.ntot, ...
    'ellipse', 0, 0, cfg.bulk_axes);
  for ic = 1:length(cfg.proxy)
    for ik = 1:length(cfg.k_nodes)
      k = cfg.k_nodes(ik);
      pars1 = LOCAL_pars1(k, cfg);
      channels = bloch.rayleigh_channels(k, cfg.beta, cfg.d, ...
        cfg.rayleigh_M, cfg.L);
      solver_a = sprintf('%s:package_public_anchor', cfg.proxy(ic).label);
      solver_b = sprintf('%s:ratio_rank_rseed', cfg.proxy(ic).label);
      rows = LOCAL_add_proxy_downstream(rows, k, ...
        cache(ic, ik).package.field, cache(ic, ik).selected.field, ...
        solver_a, solver_b, cfg);
      rows = LOCAL_add_geometry_downstream(rows, 'defect', defect_geom, ...
        defect_length, k, pars1, channels, cache(ic, ik).package.proxy, ...
        cache(ic, ik).selected.proxy, solver_a, solver_b, cfg);
      rows = LOCAL_add_geometry_downstream(rows, 'bulk', bulk_geom, ...
        bulk_length, k, pars1, channels, cache(ic, ik).package.proxy, ...
        cache(ic, ik).selected.proxy, solver_a, solver_b, cfg);
    end
  end
end

function rows = LOCAL_add_proxy_downstream(rows, k, field_a, field_b, ...
    solver_a, solver_b, cfg)
  [pot_diff, grad_diff, hess_diff] = LOCAL_field_component_diffs( ...
    field_a, field_b);
  quantities = {'green_pot', 'green_grad', 'green_hess'};
  differences = [pot_diff, grad_diff, hess_diff];
  for idx = 1:length(quantities)
    rows(end + 1) = struct('k', k, 'geometry', 'proxy', ...
      'quantity', quantities{idx}, 'solver_a', solver_a, ...
      'solver_b', solver_b, 'relative_difference', differences(idx), ...
      'rcond', NaN, 'solve_residual', NaN, ...
      'status', LOCAL_pass_status( ...
        differences(idx) <= cfg.object_compatibility_tol));
  end
end

function rows = LOCAL_add_geometry_downstream(rows, geometry_name, C, ...
    curvelen, k, pars1, channels, proxy_a, proxy_b, solver_a, solver_b, cfg)
  a = LOCAL_scaled_scattering(C, curvelen, k, pars1, channels, proxy_a, cfg);
  b = LOCAL_scaled_scattering(C, curvelen, k, pars1, channels, proxy_b, cfg);
  quantities = {'A_QP', 'R_L', 'T_LR', 'T_RL', 'R_R'};
  for idx = 1:length(quantities)
    name = quantities{idx};
    difference = LOCAL_relmat(a.(name), b.(name));
    rows(end + 1) = struct('k', k, 'geometry', geometry_name, ...
      'quantity', name, 'solver_a', solver_a, 'solver_b', solver_b, ...
      'relative_difference', difference, ...
      'rcond', min(a.A_rcond, b.A_rcond), ...
      'solve_residual', max(a.solve_residual, b.solve_residual), ...
      'status', LOCAL_pass_status( ...
        difference <= cfg.object_compatibility_tol));
  end
end

function data = LOCAL_scaled_scattering(C, curvelen, k, pars1, ...
    channels, proxy, cfg)
  A_QP = full(complex(op.construct_A_QP(C, k, cfg.nref * k, ...
    pars1, proxy, curvelen)));
  [B_L_physical, B_R_physical] = bloch.incident_rhs( ...
    C, channels, cfg.walls(1), cfg.walls(2));
  [E_L_physical, E_R_physical] = bloch.farfield_extractors( ...
    C, channels, cfg.walls(1), cfg.walls(2), curvelen);
  h = curvelen / size(C, 2);
  speed = sqrt(C(2, :).^2 + C(5, :).^2);
  density_scale = sqrt(h * [speed, speed]).';
  B_L = bsxfun(@times, B_L_physical, density_scale);
  B_R = bsxfun(@times, B_R_physical, density_scale);
  E_L = bsxfun(@rdivide, E_L_physical, density_scale.');
  E_R = bsxfun(@rdivide, E_R_physical, density_scale.');
  rhs = -[B_L, B_R];
  H_all = A_QP \ rhs;
  data.solve_residual = norm(A_QP * H_all - rhs, 'fro') / ...
    max(1, norm(rhs, 'fro'));
  p = channels.K;
  H_L = H_all(:, 1:p);
  H_R = H_all(:, p + 1:2 * p);
  phase = diag(channels.phase);
  data.A_QP = A_QP;
  data.R_L = E_L * H_L;
  data.T_LR = phase + E_R * H_L;
  data.T_RL = phase + E_L * H_R;
  data.R_R = E_R * H_R;
  data.A_rcond = rcond(A_QP);
end

function status = LOCAL_pass_status(pass)
  if pass
    status = 'PASS';
  else
    status = 'FAIL';
  end
end

%% ==================== Frozen gates and repeat comparison ====================
% Gate order and labels follow the provenance-closure addendum exactly.

function rows = LOCAL_core_gates(cfg, source, mutation, numeric, source_ready)
  rows = struct('gate', {}, 'threshold', {}, 'observed', {}, ...
    'pass', {}, 'availability', {}, 'failure_reason', {});
  rows(end + 1) = LOCAL_gate('package_source_lock', 1, ...
    source.package_source_lock_pass, source.package_source_lock_pass, true, ...
    LOCAL_reason(source.package_source_lock_pass, 'PACKAGE_SOURCE_DRIFT'));
  rows(end + 1) = LOCAL_gate('source_exact_copy_body', 1, ...
    source.source_exact_copy_body_pass, ...
    source.source_exact_copy_body_pass, true, ...
    LOCAL_reason(source.source_exact_copy_body_pass, ...
      'SOURCE_COPY_BODY_MISMATCH'));
  rows(end + 1) = LOCAL_gate('source_copy_context_independence', 1, ...
    source.source_copy_context_independence_pass, ...
    source.source_copy_context_independence_pass, true, ...
    LOCAL_reason(source.source_copy_context_independence_pass, ...
      'SOURCE_COPY_CONTEXT_DEPENDENCE'));
  rows(end + 1) = LOCAL_gate('execution_manifest_complete', 1, ...
    source.execution_manifest_complete_pass, ...
    source.execution_manifest_complete_pass, true, ...
    LOCAL_reason(source.execution_manifest_complete_pass, ...
      'EXECUTION_MANIFEST_INCOMPLETE'));

  if source_ready
    rows(end + 1) = LOCAL_gate('package_copy_public_output_bitwise', 1, ...
      numeric.package_copy_public_output_bitwise_pass, ...
      numeric.package_copy_public_output_bitwise_pass, true, ...
      LOCAL_reason(numeric.package_copy_public_output_bitwise_pass, ...
        'PACKAGE_COPY_PUBLIC_OUTPUT_MISMATCH'));
    rows(end + 1) = LOCAL_gate('copy_coefficients_bitwise', 1, ...
      numeric.copy_coefficients_bitwise_pass, ...
      numeric.copy_coefficients_bitwise_pass, true, ...
      LOCAL_reason(numeric.copy_coefficients_bitwise_pass, ...
        'COPY_COEFFICIENT_EXTRACTION_MISMATCH'));
    rows(end + 1) = LOCAL_gate('shared_A_b_raw_fingerprints', 1, ...
      numeric.shared_A_b_raw_fingerprints_pass, ...
      numeric.shared_A_b_raw_fingerprints_pass, true, ...
      LOCAL_reason(numeric.shared_A_b_raw_fingerprints_pass, ...
        'SHARED_A_B_FINGERPRINT_MISMATCH'));

    coefficient_observed = max( ...
      [numeric.shared_system.coefficient_output_error]);
    field_observed = max([numeric.shared_system.proxy_field_output_error]);
    residual_observed = max([numeric.shared_system.residual_output_error]);
    coefficient_pass = coefficient_observed <= cfg.constructor_tol;
    field_pass = field_observed <= cfg.constructor_tol;
    residual_pass = residual_observed <= cfg.constructor_tol;
    rows(end + 1) = LOCAL_gate( ...
      'mirrored_constructor_coefficient_output_reproduction', ...
      cfg.constructor_tol, coefficient_observed, coefficient_pass, true, ...
      LOCAL_reason(coefficient_pass, ...
        'MIRRORED_CONSTRUCTOR_COEFFICIENT_OUTPUT_REPRODUCTION_FAILURE'));
    rows(end + 1) = LOCAL_gate( ...
      'mirrored_constructor_proxy_field_output_reproduction', ...
      cfg.constructor_tol, field_observed, field_pass, true, ...
      LOCAL_reason(field_pass, ...
        'MIRRORED_CONSTRUCTOR_PROXY_FIELD_OUTPUT_REPRODUCTION_FAILURE'));
    rows(end + 1) = LOCAL_gate( ...
      'mirrored_constructor_residual_output_reproduction', ...
      cfg.constructor_tol, residual_observed, residual_pass, true, ...
      LOCAL_reason(residual_pass, ...
        'MIRRORED_CONSTRUCTOR_RESIDUAL_OUTPUT_REPRODUCTION_FAILURE'));

    resolution_values = [[numeric.resolution.green_pot_diff], ...
      [numeric.resolution.green_grad_diff], ...
      [numeric.resolution.green_hess_diff]];
    resolution_observed = max(resolution_values);
    resolution_pass = resolution_observed <= cfg.object_compatibility_tol && ...
      all(strcmp({numeric.resolution.status}, 'PASS'));
    rows(end + 1) = LOCAL_gate('object_compatibility_resolution', ...
      cfg.object_compatibility_tol, resolution_observed, ...
      resolution_pass, true, LOCAL_reason(resolution_pass, ...
        'OBJECT_COMPATIBILITY_RESOLUTION_FAILURE'));
    downstream_observed = max( ...
      [numeric.downstream_mismatch.relative_difference]);
    downstream_pass = downstream_observed <= cfg.object_compatibility_tol && ...
      all(strcmp({numeric.downstream_mismatch.status}, 'PASS'));
    rows(end + 1) = LOCAL_gate('object_compatibility_downstream', ...
      cfg.object_compatibility_tol, downstream_observed, ...
      downstream_pass, true, LOCAL_reason(downstream_pass, ...
        'OBJECT_COMPATIBILITY_DOWNSTREAM_FAILURE'));
    all_observed = max(resolution_observed, downstream_observed);
    all_pass = resolution_pass && downstream_pass;
    rows(end + 1) = LOCAL_gate('object_compatibility_all', ...
      cfg.object_compatibility_tol, all_observed, all_pass, true, ...
      LOCAL_reason(all_pass, 'OBJECT_COMPATIBILITY_FAILURE'));
  else
    upstream_reason = LOCAL_first_source_failure(source, mutation);
    dependent = { ...
      'package_copy_public_output_bitwise', ...
      'copy_coefficients_bitwise', 'shared_A_b_raw_fingerprints', ...
      'mirrored_constructor_coefficient_output_reproduction', ...
      'mirrored_constructor_proxy_field_output_reproduction', ...
      'mirrored_constructor_residual_output_reproduction', ...
      'object_compatibility_resolution', ...
      'object_compatibility_downstream', 'object_compatibility_all'};
    thresholds = [1, 1, 1, cfg.constructor_tol, cfg.constructor_tol, ...
      cfg.constructor_tol, cfg.object_compatibility_tol, ...
      cfg.object_compatibility_tol, cfg.object_compatibility_tol];
    for idx = 1:length(dependent)
      rows(end + 1) = LOCAL_gate(dependent{idx}, thresholds(idx), ...
        NaN, false, false, upstream_reason);
    end
  end

  rows(end + 1) = LOCAL_gate('synthetic_source_mutation_rejected', 1, ...
    mutation.synthetic_source_mutation_rejected_pass, ...
    mutation.synthetic_source_mutation_rejected_pass, true, ...
    LOCAL_reason(mutation.synthetic_source_mutation_rejected_pass, ...
      'SOURCE_MUTATION_NOT_REJECTED'));
  rows(end + 1) = LOCAL_gate('production_internal_A_b_identity', ...
    NaN, NaN, false, false, 'NOT_OBSERVABLE_WITH_CURRENT_INTERFACE');
  if source_ready
    selected = numeric.off_collocation(strcmp( ...
      {numeric.off_collocation.solver}, 'ratio_rank_rseed'));
    off_observed = max([selected.combined_residual]);
  else
    off_observed = NaN;
  end
  rows(end + 1) = LOCAL_gate('off_collocation_readiness', ...
    NaN, off_observed, false, false, 'PENDING_REVIEW');
end

function reason = LOCAL_first_source_failure(source, mutation)
  if ~source.package_source_lock_pass
    reason = 'PACKAGE_SOURCE_DRIFT';
  elseif ~source.source_exact_copy_body_pass
    reason = 'SOURCE_COPY_BODY_MISMATCH';
  elseif ~source.source_copy_context_independence_pass
    reason = 'SOURCE_COPY_CONTEXT_DEPENDENCE';
  elseif ~source.execution_manifest_complete_pass
    reason = 'EXECUTION_MANIFEST_INCOMPLETE';
  elseif ~mutation.synthetic_source_mutation_rejected_pass
    reason = 'SOURCE_MUTATION_NOT_REJECTED';
  else
    reason = '';
  end
end

function row = LOCAL_gate(name, threshold, observed, pass, availability, reason)
  row = struct('gate', name, 'threshold', threshold, ...
    'observed', observed, 'pass', pass, ...
    'availability', availability, 'failure_reason', reason);
end

function reason = LOCAL_reason(pass, failure_reason)
  if pass
    reason = '';
  else
    reason = failure_reason;
  end
end

function pass = LOCAL_required_gates_pass(rows, required)
  pass = true;
  for idx = 1:length(required)
    found = find(strcmp({rows.gate}, required{idx}));
    pass = pass && length(found) == 1 && ...
      rows(found).availability && rows(found).pass;
  end
end

function results = LOCAL_write_timeout_blocked(results, artifact_gate, ...
    output_dir, result_path, staging_output_root, transient_marker_path, ...
    started)
  if exist(transient_marker_path, 'file') == 2
    delete(transient_marker_path);
  end
  results.gates(artifact_gate) = LOCAL_gate( ...
    'artifact_bundle_complete', 1, false, false, true, ...
    'ARTIFACT_BUNDLE_INCOMPLETE');
  results.source_derived_shared_A_b_provenance_pass = false;
  results.operational_label = ...
    'SOURCE_DERIVED_SHARED_A_B_PROVENANCE_BLOCKED';
  results.finalization_state = 'RUNTIME_LIMIT_BLOCKED';
  results.elapsed_seconds = toc(started);
  results.artifact_bundle = struct('pass', false, ...
    'contract', 'COMPLETION_MARKER_HASHES_ARE_AUTHORITATIVE');
  LOCAL_write_outputs(results, output_dir);
  save(result_path, 'results', '-v7');
  if strcmp(results.run_label, 'repeat')
    LOCAL_write_reproducibility(results, ...
      fullfile(staging_output_root, 'reproducibility.txt'));
  end
end

function repro = LOCAL_pending_reproducibility()
  repro.status = 'PENDING_REPEAT';
  repro.pass = false;
  repro.relative_difference = NaN;
  repro.tolerance = 1e-13;
  repro.manifest_equal = false;
  repro.execution_manifest_complete = false;
  repro.baseline_artifact_bundle_complete = false;
  repro.source_copy_equal = false;
  repro.shared_fingerprints_equal = false;
  repro.projector_fingerprints_equal = false;
end

function repro = LOCAL_compare_runs(baseline, current)
  repro.tolerance = current.cfg.reproducibility_tol;
  repro.relative_difference = LOCAL_numeric_vector_difference( ...
    baseline.repro_vector, current.repro_vector);
  repro.manifest_equal = LOCAL_manifest_equal( ...
    baseline.cfg.source_hashes, current.cfg.source_hashes);
  repro.execution_manifest_complete = ...
    baseline.source_copy.execution_manifest_complete_pass && ...
    current.source_copy.execution_manifest_complete_pass;
  baseline_artifact_gate = find(strcmp( ...
    {baseline.gates.gate}, 'artifact_bundle_complete'));
  repro.baseline_artifact_bundle_complete = ...
    length(baseline_artifact_gate) == 1 && ...
    baseline.gates(baseline_artifact_gate).availability && ...
    baseline.gates(baseline_artifact_gate).pass;
  repro.source_copy_equal = LOCAL_source_records_equal( ...
    baseline.source_copy, current.source_copy);
  repro.shared_fingerprints_equal = LOCAL_shared_rows_equal( ...
    baseline.shared_system, current.shared_system);
  repro.projector_fingerprints_equal = LOCAL_projector_rows_equal( ...
    baseline.projector_fingerprints, current.projector_fingerprints);
  repro.pass = repro.relative_difference <= repro.tolerance && ...
    repro.manifest_equal && repro.execution_manifest_complete && ...
    repro.baseline_artifact_bundle_complete && ...
    repro.source_copy_equal && ...
    repro.shared_fingerprints_equal && repro.projector_fingerprints_equal;
  if repro.pass
    repro.status = 'REPRODUCED';
  else
    repro.status = 'PROVENANCE_REPRODUCIBILITY_FAILURE';
  end
end

function difference = LOCAL_numeric_vector_difference(old, new)
  old = old(:);
  new = new(:);
  if length(old) ~= length(new)
    difference = Inf;
    return;
  end
  finite = isfinite(old) & isfinite(new);
  nonfinite_equal = all(isnan(old(~finite)) == isnan(new(~finite))) && ...
    all(isinf(old(~finite)) == isinf(new(~finite)));
  if ~nonfinite_equal
    difference = Inf;
  elseif any(finite)
    difference = LOCAL_relmat(old(finite), new(finite));
  else
    difference = 0;
  end
end

function equal = LOCAL_manifest_equal(a, b)
  names_a = sort(fieldnames(a));
  names_b = sort(fieldnames(b));
  equal = isequal(names_a, names_b);
  if ~equal
    return;
  end
  for idx = 1:length(names_a)
    left = a.(names_a{idx});
    right = b.(names_a{idx});
    equal = equal && strcmp(left.path, right.path) && ...
      strcmp(left.sha256, right.sha256);
  end
end

function equal = LOCAL_source_records_equal(a, b)
  fields = {'package_source_sha256', 'copy_source_sha256', ...
    'package_body_sha256', 'copy_body_sha256', ...
    'minimum_norm_solver_branch', 'source_transform'};
  equal = true;
  for idx = 1:length(fields)
    equal = equal && strcmp(a.(fields{idx}), b.(fields{idx}));
  end
  equal = equal && a.body_byte_equal == b.body_byte_equal && ...
    a.copy_structure_pass == b.copy_structure_pass && ...
    a.execution_manifest_complete_pass == ...
      b.execution_manifest_complete_pass;
end

function equal = LOCAL_shared_rows_equal(a, b)
  equal = length(a) == length(b);
  if ~equal
    return;
  end
  for idx = 1:length(a)
    equal = equal && strcmp(a(idx).config, b(idx).config) && ...
      a(idx).k == b(idx).k && ...
      strcmp(a(idx).A_shared_sha256, b(idx).A_shared_sha256) && ...
      strcmp(a(idx).b_shared_sha256, b(idx).b_shared_sha256);
  end
end

function equal = LOCAL_projector_rows_equal(a, b)
  equal = length(a) == length(b);
  if ~equal
    return;
  end
  for idx = 1:length(a)
    equal = equal && strcmp(a(idx).config, b(idx).config) && ...
      a(idx).rank == b(idx).rank && ...
      strcmp(a(idx).left_sha256, b(idx).left_sha256) && ...
      strcmp(a(idx).right_sha256, b(idx).right_sha256);
  end
end

function vector = LOCAL_repro_vector(results)
  vector = [];
  for idx = 1:length(results.shared_system)
    r = results.shared_system(idx);
    vector = [vector; r.k; r.A_rows; r.A_cols; r.b_rows; r.b_cols; ...
      r.package_copy_public_output_bitwise; r.copy_coefficients_bitwise; ...
      r.coefficient_output_error; r.proxy_field_output_error; ...
      r.residual_output_error]; %#ok<AGROW>
  end
  for idx = 1:length(results.solver_comparison)
    r = results.solver_comparison(idx);
    vector = [vector; r.k; r.available; r.tolerance; r.rank; ...
      r.coefficient_norm; r.projected_residual; r.full_residual; ...
      r.full_system_backward]; %#ok<AGROW>
  end
  for idx = 1:length(results.off_collocation)
    r = results.off_collocation(idx);
    vector = [vector; r.k; r.qp_value_residual; ...
      r.qp_derivative_residual; r.top_value_residual; ...
      r.top_derivative_residual; r.bottom_value_residual; ...
      r.bottom_derivative_residual; r.combined_residual]; %#ok<AGROW>
  end
  for idx = 1:length(results.projector_fingerprints)
    r = results.projector_fingerprints(idx);
    vector = [vector; r.rank; r.left_rows; r.left_cols; ...
      r.right_rows; r.right_cols; r.left_trace; r.right_trace; ...
      r.left_idempotence; r.right_idempotence]; %#ok<AGROW>
  end
  for idx = 1:length(results.resolution)
    r = results.resolution(idx);
    vector = [vector; r.k; r.base_rank; r.refined_rank; ...
      r.base_full_residual; r.refined_full_residual; ...
      r.base_off_residual; r.refined_off_residual; ...
      r.green_pot_diff; r.green_grad_diff; r.green_hess_diff]; %#ok<AGROW>
  end
  for idx = 1:length(results.downstream_mismatch)
    r = results.downstream_mismatch(idx);
    vector = [vector; r.k; r.relative_difference; r.rcond; ...
      r.solve_residual]; %#ok<AGROW>
  end
end

%% ==================== Deterministic evidence outputs ====================
% These helpers serialize each preserved run and the aggregate repeat verdict.

function LOCAL_write_outputs(results, output_dir)
  LOCAL_write_config(results, fullfile(output_dir, 'config.txt'));
  LOCAL_write_source_copy(results, fullfile(output_dir, 'source-copy.csv'));
  LOCAL_write_shared(results.shared_system, ...
    fullfile(output_dir, 'shared-system.csv'));
  LOCAL_write_solver(results.solver_comparison, ...
    fullfile(output_dir, 'solver-comparison.csv'));
  LOCAL_write_off(results.off_collocation, ...
    fullfile(output_dir, 'off-collocation.csv'));
  LOCAL_write_projectors(results.projector_fingerprints, ...
    fullfile(output_dir, 'projector-fingerprint.csv'));
  LOCAL_write_historical_projectors( ...
    results.historical_projector_comparison, ...
    fullfile(output_dir, 'historical-projector.csv'));
  LOCAL_write_resolution(results.resolution, ...
    fullfile(output_dir, 'resolution.csv'));
  LOCAL_write_downstream(results.downstream_mismatch, ...
    fullfile(output_dir, 'downstream-mismatch.csv'));
  LOCAL_write_gates(results.gates, fullfile(output_dir, 'gate.csv'));
  LOCAL_write_report(results, fullfile(output_dir, 'report.md'));
end

function LOCAL_write_config(results, path)
  fid = LOCAL_open(path);
  cfg = results.cfg;
  fprintf(fid, 'version=%s\n', cfg.version);
  fprintf(fid, 'run_label=%s\n', results.run_label);
  fprintf(fid, 'status=%s\n', results.status);
  fprintf(fid, 'operational_label=%s\n', results.operational_label);
  fprintf(fid, 'finalization_state=%s\n', results.finalization_state);
  fprintf(fid, 'completion_marker_required=%d\n', ...
    results.completion_marker_required);
  fprintf(fid, 'completion_marker_path=%s\n', ...
    results.completion_marker_path);
  fprintf(fid, 'staging_output_root=%s\n', cfg.staging_output_root);
  fprintf(fid, 'output_root=%s\n', cfg.output_root);
  fprintf(fid, 'source_derived_shared_A_b_provenance_pass=%d\n', ...
    results.source_derived_shared_A_b_provenance_pass);
  fprintf(fid, 'production_internal_A_b_identity=%s\n', ...
    results.production_internal_A_b_identity);
  fprintf(fid, 'production_internal_A_b_reason=%s\n', ...
    'NOT_OBSERVABLE_WITH_CURRENT_INTERFACE');
  fprintf(fid, 'root_readiness=%s\n', results.root_readiness);
  fprintf(fid, 'root_readiness_sampled_discrete_go=%d\n', ...
    results.root_readiness_sampled_discrete_go);
  fprintf(fid, 'physical_root_ready=%s\n', results.physical_root_ready);
  fprintf(fid, 'package_expected_sha256=%s\n', ...
    cfg.expected_package_sha256);
  fprintf(fid, 'body_expected_sha256=%s\n', cfg.expected_body_sha256);
  fprintf(fid, 'k_nodes=%.17g,%.17g,%.17g\n', cfg.k_nodes);
  fprintf(fid, 'k_seed=%.17g\n', cfg.k_seed);
  fprintf(fid, 'beta=%.17g\n', cfg.beta);
  fprintf(fid, 'd=%.17g\n', cfg.d);
  fprintf(fid, 'primary_source=%.17g,%.17g\n', cfg.primary_source);
  fprintf(fid, ['green_sources=%.17g,%.17g,%.17g;', ...
    '%.17g,%.17g,%.17g\n'], cfg.green_sources.');
  fprintf(fid, ['green_targets=%.17g,%.17g,%.17g,%.17g;', ...
    '%.17g,%.17g,%.17g,%.17g\n'], cfg.green_targets.');
  fprintf(fid, 'periodic_axis=%s\n', cfg.periodic_axis);
  fprintf(fid, 'bulk_axes=%.17g,%.17g\n', cfg.bulk_axes);
  fprintf(fid, 'defect_axes=%.17g,%.17g\n', cfg.defect_axes);
  fprintf(fid, 'ntot=%d\n', cfg.ntot);
  fprintf(fid, 'nref=%d\n', cfg.nref);
  fprintf(fid, 'rayleigh_M=%d\n', cfg.rayleigh_M);
  fprintf(fid, 'L=%.17g\n', cfg.L);
  fprintf(fid, 'walls=%.17g,%.17g\n', cfg.walls);
  fprintf(fid, 'channel_order=%s\n', cfg.channel_order);
  fprintf(fid, 'density_scaling=%s\n', cfg.density_scaling);
  fprintf(fid, 'scattering_block_order=%s\n', ...
    cfg.scattering_block_order);
  fprintf(fid, 'off_collocation_densification=%d\n', ...
    cfg.off_collocation_densification);
  fprintf(fid, 'off_collocation_rule=%s\n', cfg.off_collocation_rule);
  fprintf(fid, 'expected_solver_labels=%s\n', ...
    LOCAL_join(cfg.expected_solver_labels, ','));
  fprintf(fid, 'expected_shared_rows=%d\n', cfg.expected_shared_rows);
  fprintf(fid, 'expected_solver_rows_per_system=%d\n', ...
    cfg.expected_solver_rows_per_system);
  fprintf(fid, 'expected_solver_rows=%d\n', cfg.expected_solver_rows);
  fprintf(fid, 'required_artifacts=%s\n', ...
    LOCAL_join(cfg.required_artifacts, ','));
  fprintf(fid, 'expected_aggregate_artifact=%s\n', ...
    cfg.expected_aggregate_artifact);
  fprintf(fid, 'minimum_norm_solver_branch=%s\n', ...
    results.source_copy.minimum_norm_solver_branch);
  fprintf(fid, 'historical_results_path=%s\n', ...
    cfg.historical_results_path);
  for idx = 1:length(cfg.proxy)
    p = cfg.proxy(idx);
    fprintf(fid, 'proxy.%s.H=%.17g\n', p.label, p.H);
    fprintf(fid, 'proxy.%s.proxy_dist=%.17g\n', p.label, p.proxy_dist);
    fprintf(fid, 'proxy.%s.N_side=%d\n', p.label, p.N_side);
    fprintf(fid, 'proxy.%s.N_top=%d\n', p.label, p.N_top);
    fprintf(fid, 'proxy.%s.N_proxy_edge=%d\n', ...
      p.label, p.N_proxy_edge);
    fprintf(fid, 'proxy.%s.M_pw=%d\n', p.label, p.M_pw);
  end
  fprintf(fid, 'ratio_rank_threshold=%.17g\n', cfg.ratio_rank_threshold);
  fprintf(fid, 'constructor_threshold=%.17g\n', cfg.constructor_tol);
  fprintf(fid, 'object_compatibility_threshold=%.17g\n', ...
    cfg.object_compatibility_tol);
  fprintf(fid, 'reproducibility_threshold=%.17g\n', ...
    cfg.reproducibility_tol);
  fprintf(fid, 'runtime_limit_seconds=%d\n', cfg.runtime_limit_seconds);
  fprintf(fid, 'manifest_scope=%s\n', cfg.manifest_scope);
  fprintf(fid, 'expected_manifest_names=%s\n', ...
    LOCAL_join(cfg.expected_manifest_names, ','));
  fprintf(fid, 'command_baseline=%s\n', cfg.command_baseline);
  fprintf(fid, 'command_repeat=%s\n', cfg.command_repeat);
  fprintf(fid, 'elapsed_seconds=%.17g\n', results.elapsed_seconds);
  names = sort(fieldnames(cfg.source_hashes));
  for source_idx = 1:length(names)
    item = cfg.source_hashes.(names{source_idx});
    fprintf(fid, 'source.%s.path=%s\n', names{source_idx}, item.path);
    fprintf(fid, 'source.%s.sha256=%s\n', ...
      names{source_idx}, item.sha256);
  end
  fclose(fid);
end

function LOCAL_write_source_copy(results, path)
  fid = LOCAL_open(path);
  s = results.source_copy;
  m = results.synthetic_source_mutation;
  fprintf(fid, ['package_path,resolved_package_path,copy_path,', ...
    'package_source_sha256,copy_source_sha256,package_body_sha256,', ...
    'copy_body_sha256,body_byte_equal,package_source_lock_pass,', ...
    'source_exact_copy_body_pass,source_copy_context_independence_pass,', ...
    'copy_structure_pass,execution_manifest_complete_pass,', ...
    'minimum_norm_solver_branch,forbidden_constructs,mutation_target_count,', ...
    'mutation_executed,mutation_failure_reason,mutation_rejected_pass\n']);
  fprintf(fid, [ ...
    '%s,%s,%s,%s,%s,%s,%s,%d,%d,%d,%d,%d,%d,%s,%s,%d,%d,%s,%d\n'], ...
    LOCAL_csv_text(s.package_path), ...
    LOCAL_csv_text(s.resolved_package_path), ...
    LOCAL_csv_text(s.copy_path), s.package_source_sha256, ...
    s.copy_source_sha256, s.package_body_sha256, s.copy_body_sha256, ...
    s.body_byte_equal, s.package_source_lock_pass, ...
    s.source_exact_copy_body_pass, ...
    s.source_copy_context_independence_pass, ...
    s.copy_structure_pass, s.execution_manifest_complete_pass, ...
    s.minimum_norm_solver_branch, ...
    LOCAL_csv_text(s.forbidden_constructs), m.target_count, m.executed, ...
    m.verifier_failure_reason, m.synthetic_source_mutation_rejected_pass);
  fclose(fid);
end

function LOCAL_write_shared(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,k,A_rows,A_cols,b_rows,b_cols,numeric_class,', ...
    'endianness,A_shared_sha256,b_shared_sha256,', ...
    'package_copy_public_output_bitwise,copy_coefficients_bitwise,', ...
    'coefficient_output_error,proxy_field_output_error,', ...
    'residual_output_error\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, ['%s,%.17g,%d,%d,%d,%d,%s,%s,%s,%s,%d,%d,', ...
      '%.17g,%.17g,%.17g\n'], r.config, r.k, r.A_rows, r.A_cols, ...
      r.b_rows, r.b_cols, r.numeric_class, r.endianness, ...
      r.A_shared_sha256, r.b_shared_sha256, ...
      r.package_copy_public_output_bitwise, r.copy_coefficients_bitwise, ...
      r.coefficient_output_error, r.proxy_field_output_error, ...
      r.residual_output_error);
  end
  fclose(fid);
end

function LOCAL_write_solver(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,k,solver,available,tolerance,rank,coefficient_norm,', ...
    'projected_residual,full_residual,full_system_backward,', ...
    'A_shared_sha256,b_shared_sha256,status,note\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, ['%s,%.17g,%s,%d,%.17g,%d,%.17g,%.17g,%.17g,', ...
      '%.17g,%s,%s,%s,%s\n'], r.config, r.k, r.solver, ...
      r.available, r.tolerance, r.rank, r.coefficient_norm, ...
      r.projected_residual, r.full_residual, r.full_system_backward, ...
      r.A_shared_sha256, r.b_shared_sha256, r.status, ...
      LOCAL_csv_text(r.note));
  end
  fclose(fid);
end

function LOCAL_write_off(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,k,solver,point_set,qp_value_residual,', ...
    'qp_derivative_residual,top_value_residual,top_derivative_residual,', ...
    'bottom_value_residual,bottom_derivative_residual,combined_residual,', ...
    'status\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, ['%s,%.17g,%s,%s,%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%.17g,%s\n'], r.config, r.k, r.solver, ...
      r.point_set, r.qp_value_residual, r.qp_derivative_residual, ...
      r.top_value_residual, r.top_derivative_residual, ...
      r.bottom_value_residual, r.bottom_derivative_residual, ...
      r.combined_residual, r.status);
  end
  fclose(fid);
end

function LOCAL_write_projectors(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,rank,left_rows,left_cols,right_rows,right_cols,', ...
    'left_trace,right_trace,left_idempotence,right_idempotence,', ...
    'left_sha256,right_sha256\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, ['%s,%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,', ...
      '%s,%s\n'], r.config, r.rank, r.left_rows, r.left_cols, ...
      r.right_rows, r.right_cols, r.left_trace, r.right_trace, ...
      r.left_idempotence, r.right_idempotence, ...
      r.left_sha256, r.right_sha256);
  end
  fclose(fid);
end

function LOCAL_write_historical_projectors(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['config,available,historical_path,historical_file_sha256,', ...
    'historical_rank,current_rank,historical_left_rows,', ...
    'historical_left_cols,historical_right_rows,historical_right_cols,', ...
    'current_left_rows,current_left_cols,current_right_rows,', ...
    'current_right_cols,', ...
    'left_relative_difference,right_relative_difference,left_equal,', ...
    'right_equal,state,note\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, [ ...
      '%s,%d,%s,%s,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%d,%d,%s,%s\n'], ...
      r.config, r.available, LOCAL_csv_text(r.historical_path), ...
      r.historical_file_sha256, r.historical_rank, r.current_rank, ...
      r.historical_left_rows, r.historical_left_cols, ...
      r.historical_right_rows, r.historical_right_cols, ...
      r.current_left_rows, r.current_left_cols, ...
      r.current_right_rows, r.current_right_cols, ...
      r.left_relative_difference, r.right_relative_difference, ...
      r.left_equal, r.right_equal, r.state, r.note);
  end
  fclose(fid);
end

function LOCAL_write_resolution(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['k,base_rank,refined_rank,base_full_residual,', ...
    'refined_full_residual,base_off_residual,refined_off_residual,', ...
    'green_pot_diff,green_grad_diff,green_hess_diff,status\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, ['%.17g,%d,%d,%.17g,%.17g,%.17g,%.17g,', ...
      '%.17g,%.17g,%.17g,%s\n'], r.k, r.base_rank, r.refined_rank, ...
      r.base_full_residual, r.refined_full_residual, ...
      r.base_off_residual, r.refined_off_residual, ...
      r.green_pot_diff, r.green_grad_diff, r.green_hess_diff, r.status);
  end
  fclose(fid);
end

function LOCAL_write_downstream(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, ['k,geometry,quantity,solver_a,solver_b,relative_difference,', ...
    'rcond,solve_residual,status\n']);
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%.17g,%s,%s,%s,%s,%.17g,%.17g,%.17g,%s\n', ...
      r.k, r.geometry, r.quantity, r.solver_a, r.solver_b, ...
      r.relative_difference, r.rcond, r.solve_residual, r.status);
  end
  fclose(fid);
end

function LOCAL_write_gates(rows, path)
  fid = LOCAL_open(path);
  fprintf(fid, 'gate,threshold,observed,pass,availability,failure_reason\n');
  for idx = 1:length(rows)
    r = rows(idx);
    fprintf(fid, '%s,%.17g,%.17g,%d,%d,%s\n', ...
      r.gate, r.threshold, r.observed, r.pass, ...
      r.availability, r.failure_reason);
  end
  fclose(fid);
end

function LOCAL_write_report(results, path)
  fid = LOCAL_open(path);
  fprintf(fid, '# Provenance-closure diagnostic: %s\n\n', results.run_label);
  fprintf(fid, '- Status: `%s`\n', results.status);
  fprintf(fid, '- Operational label: `%s`\n', results.operational_label);
  fprintf(fid, '- Finalization state: `%s`\n', ...
    results.finalization_state);
  fprintf(fid, '- Artifact bundle complete: `%d`\n', ...
    results.artifact_bundle.pass);
  fprintf(fid, '- Root readiness: `%s`\n', results.root_readiness);
  fprintf(fid, '- Sampled discrete GO: `%d`\n', ...
    results.root_readiness_sampled_discrete_go);
  fprintf(fid, '- Physical root ready: `%s`\n\n', ...
    results.physical_root_ready);
  fprintf(fid, '## Claim boundary\n\n');
  fprintf(fid, ['The package-internal collocation arrays remain ', ...
    '`NOT_DIRECTLY_OBSERVED` with reason ', ...
    '`NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. A positive operational ', ...
    'label establishes only source-derived shared-system provenance.\n\n']);
  fprintf(fid, '## Source audit\n\n');
  fprintf(fid, '- Package source lock: `%d`\n', ...
    results.source_copy.package_source_lock_pass);
  fprintf(fid, '- Source-exact copied body: `%d`\n', ...
    results.source_copy.source_exact_copy_body_pass);
  fprintf(fid, '- Context independence: `%d`\n', ...
    results.source_copy.source_copy_context_independence_pass);
  fprintf(fid, '- Execution manifest complete: `%d`\n', ...
    results.source_copy.execution_manifest_complete_pass);
  fprintf(fid, '- Minimum-norm branch: `%s`\n', ...
    results.source_copy.minimum_norm_solver_branch);
  fprintf(fid, '- Synthetic mutation rejected without execution: `%d`\n\n', ...
    results.synthetic_source_mutation.synthetic_source_mutation_rejected_pass);
  if ~isempty(results.shared_system)
    coefficient_error = max( ...
      [results.shared_system.coefficient_output_error]);
    field_error = max([results.shared_system.proxy_field_output_error]);
    residual_error = max([results.shared_system.residual_output_error]);
    resolution_max = max([[results.resolution.green_pot_diff], ...
      [results.resolution.green_grad_diff], ...
      [results.resolution.green_hess_diff]]);
    downstream_max = max( ...
      [results.downstream_mismatch.relative_difference]);
    fprintf(fid, '## Numerical evidence\n\n');
    fprintf(fid, '- Shared-system rows: `%d`\n', ...
      length(results.shared_system));
    fprintf(fid, '- Selected ranks (base/refined): `%d/%d`\n', ...
      results.projector_fingerprints(1).rank, ...
      results.projector_fingerprints(2).rank);
    fprintf(fid, '- Maximum coefficient-output error: `%.6e`\n', ...
      coefficient_error);
    fprintf(fid, '- Maximum proxy-field-output error: `%.6e`\n', ...
      field_error);
    fprintf(fid, '- Maximum residual-output error: `%.6e`\n', ...
      residual_error);
    fprintf(fid, '- Maximum base/refined Green difference: `%.6e`\n', ...
      resolution_max);
    fprintf(fid, '- Maximum downstream object difference: `%.6e`\n\n', ...
      downstream_max);
  else
    fprintf(fid, '## Numerical evidence\n\n');
    fprintf(fid, 'Unavailable because a pre-numerical source gate failed.\n\n');
  end
  fprintf(fid, '## Historical projector diagnostic (non-gating)\n\n');
  for idx = 1:length(results.historical_projector_comparison)
    h = results.historical_projector_comparison(idx);
    fprintf(fid, ['- `%s`: available `%d`, state `%s`, ranks `%.0f/%.0f`, ', ...
      'left/right relative differences `%.6e/%.6e`, ', ...
      'left/right bitwise equal `%d/%d`, note `%s`.\n'], ...
      h.config, h.available, h.state, h.historical_rank, h.current_rank, ...
      h.left_relative_difference, h.right_relative_difference, ...
      h.left_equal, h.right_equal, h.note);
  end
  fprintf(fid, '\n');
  fprintf(fid, '## Reproducibility\n\n');
  fprintf(fid, '- Status: `%s`\n', results.reproducibility.status);
  fprintf(fid, '- Numeric relative difference: `%.6e`\n', ...
    results.reproducibility.relative_difference);
  fprintf(fid, '- Manifest equal: `%d`\n', ...
    results.reproducibility.manifest_equal);
  fprintf(fid, '- Execution manifest complete in both runs: `%d`\n', ...
    results.reproducibility.execution_manifest_complete);
  fprintf(fid, '- Baseline artifact bundle complete: `%d`\n', ...
    results.reproducibility.baseline_artifact_bundle_complete);
  fprintf(fid, '- Shared fingerprints equal: `%d`\n', ...
    results.reproducibility.shared_fingerprints_equal);
  fprintf(fid, '- Projector fingerprints equal: `%d`\n\n', ...
    results.reproducibility.projector_fingerprints_equal);
  fprintf(fid, ['No scan, complex disk, Cauchy--Riemann test, contour count, ', ...
    'Newton solve, eigenvalue, adjacent-level correction, or estimator ', ...
    'was run.\n']);
  fclose(fid);
end

function LOCAL_write_reproducibility(results, path)
  fid = LOCAL_open(path);
  r = results.reproducibility;
  fprintf(fid, 'status=%s\n', r.status);
  fprintf(fid, 'pass=%d\n', r.pass);
  fprintf(fid, 'relative_difference=%.17g\n', r.relative_difference);
  fprintf(fid, 'tolerance=%.17g\n', r.tolerance);
  fprintf(fid, 'manifest_equal=%d\n', r.manifest_equal);
  fprintf(fid, 'execution_manifest_complete=%d\n', ...
    r.execution_manifest_complete);
  fprintf(fid, 'baseline_artifact_bundle_complete=%d\n', ...
    r.baseline_artifact_bundle_complete);
  fprintf(fid, 'source_copy_equal=%d\n', r.source_copy_equal);
  fprintf(fid, 'shared_fingerprints_equal=%d\n', ...
    r.shared_fingerprints_equal);
  fprintf(fid, 'projector_fingerprints_equal=%d\n', ...
    r.projector_fingerprints_equal);
  fprintf(fid, 'operational_label=%s\n', results.operational_label);
  fprintf(fid, 'root_readiness=%s\n', results.root_readiness);
  fprintf(fid, 'physical_root_ready=%s\n', results.physical_root_ready);
  fclose(fid);
end

function bundle = LOCAL_verify_artifact_bundle( ...
    output_dir, output_root, run_label, require_final_state)
  [names, paths] = LOCAL_artifact_paths(output_dir, output_root, run_label);
  files = struct('name', {}, 'path', {}, 'bytes', {}, 'nonempty', {});
  pass = true;
  for idx = 1:length(paths)
    info = dir(paths{idx});
    nonempty = length(info) == 1 && info.bytes > 0;
    if isempty(info)
      bytes = 0;
    else
      bytes = info(1).bytes;
    end
    files(end + 1) = struct('name', names{idx}, ...
      'path', paths{idx}, 'bytes', bytes, 'nonempty', nonempty);
    pass = pass && nonempty;
  end
  result_path = fullfile(output_dir, 'results.mat');
  try
    loaded = load(result_path);
    r = loaded.results;
    pass = pass && strcmp(r.run_label, run_label) && ...
      r.source_copy.execution_manifest_complete_pass && ...
      r.source_copy.source_exact_copy_body_pass && ...
      LOCAL_shared_fingerprints_pass(r.shared_system, ...
        r.solver_comparison, r.cfg) && ...
      LOCAL_projector_records_valid(r.projectors, ...
        r.projector_fingerprints);
    pass = pass && LOCAL_csv_bundle_valid(output_dir, r);
    if require_final_state
      artifact_gate = find(strcmp( ...
        {r.gates.gate}, 'artifact_bundle_complete'));
      pass = pass && r.log_closed && length(artifact_gate) == 1 && ...
        r.gates(artifact_gate).availability && ...
        r.gates(artifact_gate).pass && ...
        r.artifact_bundle.pass;
      if r.source_derived_shared_A_b_provenance_pass
        pass = pass && strcmp(r.operational_label, ...
          'SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS');
      else
        pass = pass && strcmp(r.operational_label, ...
          'SOURCE_DERIVED_SHARED_A_B_PROVENANCE_BLOCKED');
      end
    end
  catch
    pass = false;
  end
  bundle.pass = pass;
  bundle.files = files;
end

function pass = LOCAL_projector_records_valid(projectors, fingerprints)
  pass = length(projectors) == 2 && length(fingerprints) == 2;
  for idx = 1:length(projectors)
    found = find(strcmp({fingerprints.config}, projectors(idx).config));
    pass = pass && length(found) == 1 && ...
      strcmp(LOCAL_raw_fingerprint(projectors(idx).left), ...
        fingerprints(found).left_sha256) && ...
      strcmp(LOCAL_raw_fingerprint(projectors(idx).right), ...
        fingerprints(found).right_sha256);
  end
end

function pass = LOCAL_csv_bundle_valid(output_dir, results)
  filenames = { ...
    'source-copy.csv', 'shared-system.csv', 'solver-comparison.csv', ...
    'off-collocation.csv', 'projector-fingerprint.csv', ...
    'historical-projector.csv', 'resolution.csv', ...
    'downstream-mismatch.csv', 'gate.csv'};
  headers = { ...
    ['package_path,resolved_package_path,copy_path,package_source_sha256,', ...
      'copy_source_sha256,package_body_sha256,copy_body_sha256,', ...
      'body_byte_equal,package_source_lock_pass,', ...
      'source_exact_copy_body_pass,source_copy_context_independence_pass,', ...
      'copy_structure_pass,execution_manifest_complete_pass,', ...
      'minimum_norm_solver_branch,forbidden_constructs,', ...
      'mutation_target_count,mutation_executed,mutation_failure_reason,', ...
      'mutation_rejected_pass'], ...
    ['config,k,A_rows,A_cols,b_rows,b_cols,numeric_class,endianness,', ...
      'A_shared_sha256,b_shared_sha256,', ...
      'package_copy_public_output_bitwise,copy_coefficients_bitwise,', ...
      'coefficient_output_error,proxy_field_output_error,', ...
      'residual_output_error'], ...
    ['config,k,solver,available,tolerance,rank,coefficient_norm,', ...
      'projected_residual,full_residual,full_system_backward,', ...
      'A_shared_sha256,b_shared_sha256,status,note'], ...
    ['config,k,solver,point_set,qp_value_residual,', ...
      'qp_derivative_residual,top_value_residual,', ...
      'top_derivative_residual,bottom_value_residual,', ...
      'bottom_derivative_residual,combined_residual,status'], ...
    ['config,rank,left_rows,left_cols,right_rows,right_cols,left_trace,', ...
      'right_trace,left_idempotence,right_idempotence,left_sha256,', ...
      'right_sha256'], ...
    ['config,available,historical_path,historical_file_sha256,', ...
      'historical_rank,current_rank,historical_left_rows,', ...
      'historical_left_cols,historical_right_rows,historical_right_cols,', ...
      'current_left_rows,current_left_cols,current_right_rows,', ...
      'current_right_cols,left_relative_difference,', ...
      'right_relative_difference,', ...
      'left_equal,right_equal,state,note'], ...
    ['k,base_rank,refined_rank,base_full_residual,', ...
      'refined_full_residual,base_off_residual,refined_off_residual,', ...
      'green_pot_diff,green_grad_diff,green_hess_diff,status'], ...
    ['k,geometry,quantity,solver_a,solver_b,relative_difference,rcond,', ...
      'solve_residual,status'], ...
    'gate,threshold,observed,pass,availability,failure_reason'};
  counts = [1, length(results.shared_system), ...
    length(results.solver_comparison), length(results.off_collocation), ...
    length(results.projector_fingerprints), ...
    length(results.historical_projector_comparison), ...
    length(results.resolution), length(results.downstream_mismatch), ...
    length(results.gates)];
  pass = true;
  for idx = 1:length(filenames)
    path = fullfile(output_dir, filenames{idx});
    [header, data_rows] = LOCAL_csv_shape(path);
    pass = pass && strcmp(header, headers{idx}) && data_rows == counts(idx);
  end
  if ~isempty(results.shared_system)
    pass = pass && length(results.shared_system) == ...
      results.cfg.expected_shared_rows && ...
      length(results.solver_comparison) == ...
        results.cfg.expected_solver_rows && ...
      length(results.off_collocation) == results.cfg.expected_solver_rows;
  end
end

function [header, data_rows] = LOCAL_csv_shape(path)
  fid = fopen(path, 'r');
  if fid < 0
    header = '';
    data_rows = -1;
    return;
  end
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  header = fgetl(fid);
  data_rows = 0;
  while ischar(fgetl(fid))
    data_rows = data_rows + 1;
  end
end

function [names, paths] = LOCAL_artifact_paths( ...
    output_dir, output_root, run_label)
  names = { ...
    'config', 'source_copy', 'shared_system', 'solver_comparison', ...
    'off_collocation', 'projector_fingerprint', ...
    'historical_projector', 'resolution', 'downstream_mismatch', ...
    'gate', 'report', 'results_mat', 'run_log'};
  filenames = { ...
    'config.txt', 'source-copy.csv', 'shared-system.csv', ...
    'solver-comparison.csv', 'off-collocation.csv', ...
    'projector-fingerprint.csv', 'historical-projector.csv', ...
    'resolution.csv', 'downstream-mismatch.csv', 'gate.csv', ...
    'report.md', 'results.mat', 'run.log'};
  paths = cell(size(filenames));
  for idx = 1:length(filenames)
    paths{idx} = fullfile(output_dir, filenames{idx});
  end
  if strcmp(run_label, 'repeat')
    names{end + 1} = 'aggregate_reproducibility';
    paths{end + 1} = fullfile(output_root, 'reproducibility.txt');
  end
end

function LOCAL_write_completion_marker( ...
    results, output_dir, output_root, transient_marker_path, ...
    started, runtime_limit_seconds)
  bundle = LOCAL_verify_artifact_bundle( ...
    output_dir, output_root, results.run_label, true);
  if ~bundle.pass
    error('provenance_closure_diagnostic:ArtifactFinalization', ...
      'Final artifact verification failed; completion marker not written.');
  end
  if strcmp(results.run_label, 'repeat')
    loaded = load(fullfile(output_root, 'baseline', 'results.mat'));
    if ~LOCAL_validate_completion_marker(loaded.results, ...
        fullfile(output_root, 'baseline'), output_root)
      error('provenance_closure_diagnostic:BaselineMarkerChanged', ...
        'Baseline marker or its hashed artifacts changed during repeat.');
    end
  end
  marker_text = LOCAL_completion_marker_text(results, output_root);
  LOCAL_check_runtime(started, runtime_limit_seconds);
  fid = LOCAL_open(transient_marker_path);
  fprintf(fid, '%s', marker_text);
  fclose(fid);
  if ~LOCAL_validate_completion_marker(results, output_dir, output_root)
    error('provenance_closure_diagnostic:CompletionMarker', ...
      'Completion marker verification failed; tree not published.');
  end
  LOCAL_check_runtime(started, runtime_limit_seconds);
end

function text_value = LOCAL_completion_marker_text(results, output_root)
  [relative_paths, absolute_paths] = LOCAL_marker_artifact_paths( ...
    results.run_label, output_root);
  text_value = sprintf('version=%s\n', results.cfg.version);
  text_value = [text_value, sprintf('run_label=%s\n', ...
    results.run_label)];
  text_value = [text_value, 'artifact_bundle_complete=1', sprintf('\n')];
  text_value = [text_value, sprintf('operational_label=%s\n', ...
    results.operational_label)];
  text_value = [text_value, sprintf('artifact_count=%d\n', ...
    length(absolute_paths))];
  for idx = 1:length(absolute_paths)
    text_value = [text_value, sprintf('artifact.%03d.path=%s\n', ...
      idx, relative_paths{idx})]; %#ok<AGROW>
    text_value = [text_value, sprintf('artifact.%03d.sha256=%s\n', ...
      idx, LOCAL_source_hash(absolute_paths{idx}))]; %#ok<AGROW>
  end
  text_value = [text_value, 'marker_written_last=1', sprintf('\n')];
end

function [relative_paths, absolute_paths] = ...
    LOCAL_marker_artifact_paths(run_label, output_root)
  relative_paths = {};
  absolute_paths = {};
  labels = {'baseline'};
  if strcmp(run_label, 'repeat')
    labels{end + 1} = 'repeat';
  end
  for ilabel = 1:length(labels)
    label = labels{ilabel};
    run_dir = fullfile(output_root, label);
    [~, paths] = LOCAL_artifact_paths(run_dir, output_root, label);
    if strcmp(label, 'repeat')
      paths = paths(1:end - 1);
    end
    for idx = 1:length(paths)
      [~, name, extension] = fileparts(paths{idx});
      relative_paths{end + 1} = ...
        [label, '/', name, extension]; %#ok<AGROW>
      absolute_paths{end + 1} = paths{idx}; %#ok<AGROW>
    end
  end
  if strcmp(run_label, 'repeat')
    relative_paths{end + 1} = 'reproducibility.txt';
    absolute_paths{end + 1} = ...
      fullfile(output_root, 'reproducibility.txt');
  end
end

function pass = LOCAL_validate_completion_marker( ...
    results, output_dir, output_root)
  marker_path = fullfile(output_dir, 'completion.marker');
  if exist(marker_path, 'file') ~= 2
    pass = false;
    return;
  end
  actual = fileread(marker_path);
  expected = LOCAL_completion_marker_text(results, output_root);
  pass = strcmp(actual, expected);
end

function fid = LOCAL_open(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('provenance_closure_diagnostic:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end

function value = LOCAL_csv_text(value)
  value = strrep(value, '"', '""');
  value = ['"', value, '"'];
end

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

function value = LOCAL_relmat(actual, expected)
  value = norm(actual - expected, 'fro') / max(1, norm(expected, 'fro'));
end

function value = LOCAL_join(items, separator)
  if isempty(items)
    value = '';
    return;
  end
  value = items{1};
  for idx = 2:length(items)
    value = [value, separator, items{idx}]; %#ok<AGROW>
  end
end
