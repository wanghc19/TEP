function result = check_e_cap_v2(attempt, certificate_path)
%CHECK_E_CAP_V2 Run the I3.2 MFS/Kress same-trial empirical-cap experiment.
% Purpose:
%   Provide a thin formal entry that dispatches independent scientific
%   modules, enforces resource/identity gates, and publishes a readable
%   complete or partial append-only artifact.
% Input:
%   attempt          - must be the preregistered tag `ecap-v2-a2`.
%   certificate_path - explicit frozen fbie-a1 certificate MAT file.
% Output:
%   result - empirical, unqualified result or a typed partial blocker record.
% Main algorithm:
%   Load a compact certificate, build the MFS-only GQP representation, apply
%   circle and wall Kress actions, form value lifts, contract full P powers,
%   combine empirical caps, and publish result.mat/report.md.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-2d.md.
% Main changes:
%   This v2 entry does not call any field evaluator from test/i3/e-cap.
% Numerical goal:
%   Estimate componentwise empirical evaluation caps for one frozen trial.

cfg = i32v2_config();
run_tic = tic;
result = LOCAL_initial_result(attempt, cfg);
output_dir = '';
published = false;

try
  % --- stage 1: append-only guard and output ownership ---
  if ~(ischar(attempt) || (isstring(attempt) && isscalar(attempt)))
    error('I32V2:AttemptType', 'Attempt must be text.');
  end
  attempt = char(attempt);
  if ~strcmp(attempt, cfg.attempt)
    error('I32V2:AttemptMismatch', 'Only the preregistered attempt is accepted.');
  end
  experiment_dir = fileparts(mfilename('fullpath'));
  output_root = fullfile(experiment_dir, 'output');
  output_dir = fullfile(output_root, attempt);
  exact_a2 = fullfile(output_root, 'ecap-v2-a2');
  if ~strcmp(output_dir, exact_a2)
    error('I32V2:AttemptPathMismatch', ...
      'The resolved output is not the exact authorized a2 directory.');
  end
  replaced_existing = false;
  if isfolder(output_dir)
    [ok, message] = rmdir(output_dir, 's');
    if ~ok
      error('I32V2:ExactAttemptRemove', '%s', message);
    end
    replaced_existing = true;
  elseif isfile(output_dir)
    error('I32V2:ExactAttemptIsFile', ...
      'The exact a2 output path exists but is not a directory.');
  end
  if ~isfolder(output_root)
    [ok, message] = mkdir(output_root);
    if ~ok
      error('I32V2:OutputRootCreate', '%s', message);
    end
  end
  [ok, message] = mkdir(output_dir);
  if ~ok
    error('I32V2:OutputAttemptCreate', '%s', message);
  end
  result.state = 'ATTEMPT_CONSUMED';
  result.audit.retry.replaced_existing_exact_a2 = replaced_existing;

  resource = struct('start_tic', run_tic, ...
    'soft_s', cfg.resource.soft_s, ...
    'hard_s', cfg.resource.hard_s, ...
    'memory_mib_max', cfg.resource.memory_mib_max);

  % --- stage 2: frozen certificate and initial identity ---
  cert = i32v2_certificate_input(certificate_path, cfg);
  result.certificate = LOCAL_strip_data(cert);
  LOCAL_require_available(cert, 'CERTIFICATE_UNAVAILABLE');
  frozen_digest = cert.audit.identity_digest;
  result.audit.initial_identity_digest = frozen_digest;
  result.audit.expected_identity_digest = cfg.identity.expected_trial_digest;
  result.audit.trial_digest_ledger = struct( ...
    'initial', frozen_digest, 'after_gqp', '', 'after_circle', '', ...
    'after_wall', '', 'pre_release', '', 'after_lifting', '', ...
    'after_fullp', '');
  result.audit.trial_unchanged = true;
  result.audit.wall_trace_order_M = double(cert.data.certificate.M);
  result.audit.M_role = cert.data.input_contract.M_role;
  result.audit.refinement_levels = cfg.levels;
  result.audit.refinement_changes_trial = false;
  result.audit.raw_numeric_types = struct( ...
    'd', class(cert.data.certificate.d), ...
    'rho_disk', class(cert.data.certificate.rho_disk), ...
    'M', class(cert.data.certificate.M), ...
    'K', class(cert.data.certificate.K), ...
    'wall_orders', class(cert.data.certificate.wall_orders_512));
  [view, computation_view_audit] = ...
    i32v2_computation_view(cert.data, cfg);
  result.audit.computation_view = computation_view_audit;
  result.audit.canonical_numeric_types = struct( ...
    'd', class(view.data.certificate.d), ...
    'rho_disk', class(view.data.certificate.rho_disk), ...
    'M', class(view.data.certificate.M), ...
    'K', class(view.data.certificate.K), ...
    'wall_orders', class(view.data.certificate.wall_orders_512));
  result.audit.expected_canonical_digest = ...
    cfg.identity.expected_canonical_digest;
  result.audit.canonical_digest_ledger = struct( ...
    'initial', computation_view_audit.canonical_digest, ...
    'after_gqp', '', 'after_circle', '', 'after_wall', '', ...
    'pre_release', '', 'after_lifting', '', 'after_fullp', '');
  result.audit.trial_digest_ledger.initial = ...
    computation_view_audit.canonical_digest;
  result.audit.raw_identity_at_death = ...
    computation_view_audit.raw_digest_after;
  if ~strcmp(frozen_digest, result.audit.raw_identity_at_death)
    error('I32V2:RawCertificateMutation', ...
      'The raw certificate changed before its registered death point.');
  end
  result.state = 'CERTIFICATE_READY';
  resource = LOCAL_resource_context(resource, {cert, view});
  result.resources.modules.certificate = LOCAL_module_memory(cert, resource);
  result.resources.modules.certificate.entry_mib = 0;
  result.resources.modules.certificate.cow_mib = 0;
  result.resources.modules.certificate.proxy_mib = ...
    result.resources.modules.certificate.local_peak_mib + ...
    result.resources.modules.certificate.publication_mib;
  result.resources.peak_mib = max(result.resources.peak_mib, ...
    result.resources.modules.certificate.proxy_mib);
  LOCAL_resource_gate(run_tic, cfg, resource, 'after certificate');
  clear cert
  result.audit.raw_certificate_released_before_scientific_modules = true;

  % --- stage 3: MFS-only GQP tables and kernel oracles ---
  resource = LOCAL_resource_context(resource, {view});
  module_resource = resource;
  gqp = i32v2_gqp_module(view, cfg, resource);
  result.gqp = LOCAL_strip_data(gqp);
  result = LOCAL_absorb_module(result, gqp);
  result.resources.modules.gqp = LOCAL_module_memory(gqp, module_resource);
  LOCAL_require_available(gqp, 'GQP_UNAVAILABLE');
  result.audit.canonical_digest_ledger.after_gqp = ...
    LOCAL_assert_view(view, cfg, 'gqp');
  result.audit.trial_digest_ledger.after_gqp = ...
    result.audit.canonical_digest_ledger.after_gqp;
  result.state = 'GQP_READY';
  resource = LOCAL_resource_context(resource, {view, gqp});
  LOCAL_resource_gate(run_tic, cfg, resource, 'after GQP');

  % --- stage 4: independent circle and wall boundary actions ---
  resource = LOCAL_resource_context(resource, {view, gqp});
  module_resource = resource;
  circle = i32v2_circle_module(view, gqp, cfg, resource);
  result.circle = LOCAL_strip_data(circle);
  result = LOCAL_absorb_module(result, circle);
  result.resources.modules.circle = LOCAL_module_memory(circle, module_resource);
  LOCAL_require_available(circle, 'CIRCLE_ACTION_UNAVAILABLE');
  result.audit.canonical_digest_ledger.after_circle = ...
    LOCAL_assert_view(view, cfg, 'circle');
  result.audit.trial_digest_ledger.after_circle = ...
    result.audit.canonical_digest_ledger.after_circle;
  result.state = 'CIRCLE_READY';
  resource = LOCAL_resource_context(resource, {view, gqp, circle});
  LOCAL_resource_gate(run_tic, cfg, resource, 'after circle');

  resource = LOCAL_resource_context(resource, {view, gqp, circle});
  module_resource = resource;
  wall = i32v2_wall_module(view, gqp, cfg, resource, circle);
  result.wall = LOCAL_strip_data(wall);
  result = LOCAL_absorb_module(result, wall);
  result.resources.modules.wall = LOCAL_module_memory(wall, module_resource);
  LOCAL_require_available(wall, 'WALL_ACTION_UNAVAILABLE');
  result.audit.canonical_digest_ledger.after_wall = ...
    LOCAL_assert_view(view, cfg, 'wall');
  result.audit.trial_digest_ledger.after_wall = ...
    result.audit.canonical_digest_ledger.after_wall;
  result.state = 'WALL_READY';
  result.audit.canonical_digest_ledger.pre_release = ...
    LOCAL_assert_view(view, cfg, 'wall');
  result.audit.trial_digest_ledger.pre_release = ...
    result.audit.canonical_digest_ledger.pre_release;
  result.audit.identity_at_density_death = ...
    result.audit.canonical_digest_ledger.pre_release;
  result.audit.trial_unchanged = strcmp( ...
    cfg.identity.expected_canonical_digest, ...
    result.audit.identity_at_density_death);
  if ~result.audit.trial_unchanged
    error('I32V2:FrozenTrialIdentityDrift', ...
      'The frozen certificate changed before the density-map death point.');
  end

  [released_view, release_audit] = ...
    i32v2_release_computation_view(view, cfg);
  result.audit.released_computation_view = release_audit;
  result.audit.expected_released_digest = ...
    cfg.identity.expected_released_digest;
  result.audit.expected_release_manifest_digest = ...
    cfg.identity.expected_release_manifest_digest;
  clear view

  % Production GQP tables and canonical density maps die after all wall and
  % circle actions. Only the independently anchored released view remains.
  gqp = LOCAL_gqp_after_wall(gqp);
  result.audit.after_wall_death = LOCAL_live_audit( ...
    struct('released_view', released_view, 'gqp', gqp, ...
    'circle', circle, 'wall', wall));
  LOCAL_require_return_audit(result.audit.after_wall_death);
  resource = LOCAL_resource_context(resource, ...
    {released_view, gqp, circle, wall});
  LOCAL_resource_gate(run_tic, cfg, resource, 'after wall');

  % --- stage 5: value-only lifting and combined volume factor ---
  resource = LOCAL_resource_context(resource, ...
    {released_view, gqp, circle, wall});
  module_resource = resource;
  lifting = i32v2_lifting_module( ...
    released_view, circle, wall, gqp, cfg, resource);
  result.lifting = LOCAL_strip_data(lifting);
  result = LOCAL_absorb_module(result, lifting);
  result.resources.modules.lifting = LOCAL_module_memory(lifting, module_resource);
  LOCAL_require_available(lifting, 'LIFTING_UNAVAILABLE');
  result.audit.canonical_digest_ledger.after_lifting = ...
    LOCAL_assert_view(released_view, cfg, 'lifting');
  result.audit.trial_digest_ledger.after_lifting = ...
    result.audit.canonical_digest_ledger.after_lifting;
  result.state = 'LIFTING_READY';
  circle = LOCAL_circle_after_lifting(circle);
  wall = LOCAL_wall_after_lifting(wall);
  clear gqp
  result.audit.after_lifting_death = LOCAL_live_audit( ...
    struct('released_view', released_view, 'circle', circle, ...
    'wall', wall, 'lifting', lifting));
  LOCAL_require_return_audit(result.audit.after_lifting_death);
  resource = LOCAL_resource_context(resource, ...
    {released_view, circle, wall, lifting});
  LOCAL_resource_gate(run_tic, cfg, resource, 'after lifting');

  % --- stage 6: full-P, empirical caps, and nominal transform ---
  resource = LOCAL_resource_context(resource, ...
    {released_view, circle, wall, lifting});
  module_resource = resource;
  cap = i32v2_fullp_cap_module( ...
    released_view, circle, wall, lifting, cfg, resource);
  result.cap_module = LOCAL_strip_data(cap);
  result = LOCAL_absorb_module(result, cap);
  result.resources.modules.fullp = LOCAL_module_memory(cap, module_resource);
  LOCAL_require_available(cap, 'FULLP_CAP_UNAVAILABLE');
  result.audit.canonical_digest_ledger.after_fullp = ...
    LOCAL_assert_view(released_view, cfg, 'fullp');
  result.audit.trial_digest_ledger.after_fullp = ...
    result.audit.canonical_digest_ledger.after_fullp;
  result.caps = cap.data.caps;
  result.estimator = cap.data.estimator;
  result.field_lower_diagnostic = cap.data.field;
  result.state = 'NUMERICAL_OBJECTS_COMPLETE';
  result.audit.final_identity_digest = ...
    result.audit.trial_digest_ledger.after_fullp;
  result.audit = LOCAL_final_audit(result.audit, ...
    result.gqp, result.certificate, circle, wall, lifting);
  clear circle wall lifting released_view
  result.audit.after_fullp_death = LOCAL_live_audit(struct('cap', cap));
  LOCAL_require_return_audit(result.audit.after_fullp_death);
  result.unresolved = LOCAL_collect_unresolved(result.warnings, ...
    result.unresolved);
  result.status = 'COMPLETE';
  result.state = 'READY_TO_PUBLISH';
catch err
  result.status = 'BLOCKED';
  result.state = 'PARTIAL_READY_TO_PUBLISH';
  if isempty(result.first_blocker)
    result.first_blocker = LOCAL_identifier(err);
  end
  result.unresolved = LOCAL_append_unique(result.unresolved, result.first_blocker);
  result.audit.exception_message = err.message;
  result.audit.exception_stack = LOCAL_stack(err);
end

% --- stage 7: publication, including blocker-preserving partial output ---
result.resources.elapsed_s = toc(run_tic);
memory = LOCAL_memory_probe(result, cfg);
result.resources.retained_mib = memory.retained_mib;
result.resources.peak_mib = max(result.resources.peak_mib, memory.proxy_mib);
result.claim_label = cfg.claim_label;
result.flags = cfg.flags;
result.flags.reliability = false;

if ~isempty(output_dir) && isfolder(output_dir)
  try
    i32v2_result_output(result, output_dir);
    published = true;
  catch output_err
    result.status = 'BLOCKED';
    if isempty(result.first_blocker)
      result.first_blocker = LOCAL_identifier(output_err);
    end
    result.unresolved = LOCAL_append_unique(result.unresolved, ...
      'PRIMARY_PUBLICATION_FAILED');
    LOCAL_emergency_output(result, output_dir, output_err);
    published = isfile(fullfile(output_dir, 'result.mat')) && ...
      isfile(fullfile(output_dir, 'report.md'));
  end
end
if ~published && ~strcmp(result.first_blocker, 'I32V2:AttemptAlreadyConsumed')
  warning('I32V2:ArtifactUnavailable', ...
    'No readable artifact could be published for this invocation.');
end
end

%% ==================== Entry state and resource gates ====================
% These helpers keep orchestration separate from scientific modules.

function result = LOCAL_initial_result(attempt, cfg)
result.schema = cfg.schema;
result.attempt = char(string(attempt));
result.provenance = cfg.provenance;
result.claim_label = cfg.claim_label;
result.status = 'INITIALIZED';
result.state = 'NOT_STARTED';
result.first_blocker = '';
result.warnings = {'GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL'};
result.unresolved = {};
result.flags = cfg.flags;
result.audit = struct('trial_unchanged', false, 'density_solves', 0, ...
  'old_ecap_calls', 0, 'image_sum_calls', 0, ...
  'rayleigh_field_calls', 0, ...
  'expected_identity_digest', cfg.identity.expected_trial_digest, ...
  'trial_digest_ledger', struct('initial', '', 'after_gqp', '', ...
  'after_circle', '', 'after_wall', '', 'pre_release', '', ...
  'after_lifting', '', 'after_fullp', ''));
result.audit.retry = struct('ordinal', cfg.retry.ordinal, ...
  'retries_before', cfg.retry.retries_before, ...
  'exact_overwrite_authorized', cfg.retry.exact_overwrite_authorized, ...
  'replaced_existing_exact_a2', false, ...
  'prior_attempt', cfg.retry.prior_attempt);
result.resources = struct('elapsed_s', 0, 'peak_mib', 0, ...
  'retained_mib', 0, 'memory_mib_max', cfg.resource.memory_mib_max, ...
  'soft_s', cfg.resource.soft_s, 'hard_s', cfg.resource.hard_s);
result.gqp = struct();
result.circle = struct();
result.wall = struct();
result.lifting = struct();
result.cap_module = struct();
result.caps = LOCAL_empty_caps();
result.estimator = LOCAL_empty_estimator();
result.field_lower_diagnostic = struct();
end

function LOCAL_resource_gate(run_tic, cfg, resource, location)
elapsed_s = toc(run_tic);
if elapsed_s > cfg.resource.hard_s
  error('I32V2:HARD_TIME_LIMIT', ...
    'Hard time gate exceeded %s.', location);
end
if elapsed_s > cfg.resource.soft_s
  error('I32V2:SOFT_TIME_PREVENTED_NEXT_MODULE', ...
    'Soft time gate prevents a new module %s.', location);
end
proxy_mib = resource.retained_mib + resource.cow_mib + ...
  cfg.resource.publication_reserve_mib;
if proxy_mib > cfg.resource.memory_mib_max
  error('I32V2:HARD_MEMORY_LIMIT', ...
    'Active-memory proxy exceeded the preregistered gate %s.', location);
end
end

function resource = LOCAL_resource_context(resource, owners)
bytes = zeros(1, numel(owners));
for k = 1:numel(owners)
  bytes(k) = LOCAL_value_bytes(owners{k});
end
resource.retained_mib = sum(bytes) / 2^20;
resource.cow_mib = max([0, bytes]) / 2^20;
resource.publication_mib = 64;
end

function memory = LOCAL_module_memory(module, resource)
memory.entry_mib = resource.retained_mib;
memory.local_peak_mib = LOCAL_nested_number(module, ...
  {'memory', 'local_peak_mib'}, 0);
memory.retained_mib = LOCAL_value_bytes(module) / 2^20;
memory.cow_mib = resource.cow_mib;
memory.publication_mib = resource.publication_mib;
memory.proxy_mib = memory.entry_mib + memory.local_peak_mib + ...
  memory.cow_mib + memory.publication_mib;
memory.largest_object = LOCAL_nested_text(module, ...
  {'memory', 'largest_object'}, 'UNAVAILABLE');
end

function memory = LOCAL_memory_probe(value, cfg)
held = value; %#ok<NASGU>
info = whos('held');
memory.retained_mib = info.bytes / 2^20;
memory.proxy_mib = memory.retained_mib + cfg.resource.publication_reserve_mib;
end

function LOCAL_require_available(module, blocker)
if ~isstruct(module) || ~isfield(module, 'available') || ~module.available
  if isstruct(module) && isfield(module, 'first_blocker') && ...
      ~isempty(module.first_blocker)
    error(module.first_blocker, '%s', blocker);
  end
  error(['I32V2:', blocker], '%s', blocker);
end
end

function digest = LOCAL_assert_view(view, cfg, stage)
validation = i32v2_validate_computation_view(view, cfg, stage);
digest = validation.canonical_digest;
end

%% ==================== Compact result aggregation ====================
% Publication keeps completed metrics but removes every dense consumer object.

function compact = LOCAL_strip_data(module)
compact = module;
if ~isfield(compact, 'data') || ~isstruct(compact.data)
  return
end
switch LOCAL_nested_text(module, {'schema'}, '')
  case {'I32V2_CIRCLE_MODULE_V1', 'I32V2_WALL_MODULE_V1'}
    keep = {'ordinary_weights', 'axis_metrics', 'gqp_metrics', ...
      'value_gqp_metrics', 'checkpoint', 'partial_metrics'};
  case 'I32V2_LIFTING_V1'
    keep = {'axis_metrics', 'gqp_metrics', 'checkpoint', 'partial_metrics'};
  case 'I32V2_FULLP_CAP_V1'
    keep = {'caps', 'estimator', 'component', 'field', ...
      'fourier_shell', 'checkpoint', 'partial_metrics'};
  case 'I32V2_GQP_MODULE_V1'
    keep = {'checkpoint', 'partial_metrics'};
  otherwise
    keep = {'checkpoint', 'partial_metrics'};
end
names = intersect(fieldnames(compact.data), keep, 'stable');
projected = struct('schema', 'I32V2_PUBLICATION_SAFE_COMPACT_DATA_V1');
for k = 1:numel(names)
  projected.(names{k}) = compact.data.(names{k});
end
compact.data = projected;
compact.audit.publication_projection = struct( ...
  'completed_compact_metrics_retained', true, ...
  'dense_tables_factors_raw_arrays_retained', false, ...
  'retained_fields', {names});
end

function result = LOCAL_absorb_module(result, module)
if isfield(module, 'warnings')
  for k = 1:numel(module.warnings)
    result.warnings = LOCAL_append_unique(result.warnings, module.warnings{k});
  end
end
if isfield(module, 'first_blocker') && ~isempty(module.first_blocker) && ...
    isempty(result.first_blocker)
  result.first_blocker = module.first_blocker;
end
if isfield(module, 'memory')
  if isfield(module.memory, 'proxy_mib')
    result.resources.peak_mib = max(result.resources.peak_mib, ...
      module.memory.proxy_mib);
  elseif isfield(module.memory, 'local_peak_mib')
    result.resources.peak_mib = max(result.resources.peak_mib, ...
      module.memory.local_peak_mib);
  elseif isfield(module.memory, 'peak_mib')
    result.resources.peak_mib = max(result.resources.peak_mib, ...
      module.memory.peak_mib);
  end
end
end

function audit = LOCAL_final_audit(audit, gqp, cert, circle, wall, lifting)
modules = {gqp, cert, circle, wall, lifting};
audit.density_solves = 0;
audit.old_ecap_calls = 0;
audit.image_sum_calls = 0;
audit.rayleigh_field_calls = 0;
for k = 1:numel(modules)
  audit.density_solves = audit.density_solves + ...
    LOCAL_counter(modules{k}, 'density_solves') + ...
    LOCAL_counter(modules{k}, 'density_resolve_count');
  audit.old_ecap_calls = audit.old_ecap_calls + ...
    LOCAL_counter(modules{k}, 'old_ecap_calls');
  audit.image_sum_calls = audit.image_sum_calls + ...
    LOCAL_counter(modules{k}, 'image_sum_calls');
  audit.rayleigh_field_calls = audit.rayleigh_field_calls + ...
    LOCAL_counter(modules{k}, 'rayleigh_field_calls') + ...
    LOCAL_counter(modules{k}, 'rayleigh_trial_eval_calls');
end
end

function compact = LOCAL_gqp_after_wall(gqp)
compact = gqp;
if isfield(compact, 'data')
  compact.data = struct('schema', 'I32V2_GQP_TABLES_RELEASED_AFTER_WALL');
end
end

function compact = LOCAL_circle_after_lifting(circle)
compact = circle;
if isfield(compact, 'data') && isfield(compact.data, 'finest')
  compact.data.finest = rmfield(compact.data.finest, ...
    intersect(fieldnames(compact.data.finest), {'value_plus', 'value_minus'}));
end
compact = LOCAL_remove_fields(compact, {'value_gqp_metrics'});
if isfield(compact, 'data') && isfield(compact.data, 'axis_metrics')
  compact.data.axis_metrics = LOCAL_remove_axis_value(compact.data.axis_metrics);
end
end

function compact = LOCAL_wall_after_lifting(wall)
compact = wall;
if isfield(compact, 'data') && isfield(compact.data, 'finest')
  names = {'value_left_plus', 'value_right_plus', ...
    'value_left_minus', 'value_right_minus'};
  compact.data.finest = rmfield(compact.data.finest, ...
    intersect(fieldnames(compact.data.finest), names));
end
compact = LOCAL_remove_fields(compact, {'value_gqp_metrics'});
if isfield(compact, 'data') && isfield(compact.data, 'axis_metrics')
  compact.data.axis_metrics = LOCAL_remove_axis_value(compact.data.axis_metrics);
end
end

function value = LOCAL_remove_fields(value, names)
if isfield(value, 'data')
  value.data = rmfield(value.data, intersect(fieldnames(value.data), names));
end
end

function axis = LOCAL_remove_axis_value(axis)
for name = {'target', 'source'}
  key = name{1};
  if isfield(axis, key) && isfield(axis.(key), 'value')
    axis.(key) = rmfield(axis.(key), 'value');
  end
end
end

function summary = LOCAL_live_audit(value)
raw = i32v2_return_audit(value, {});
summary.pass = raw.pass;
summary.retained_bytes = raw.retained_bytes;
summary.entry_count = numel(raw.entries);
summary.forbidden_paths = raw.forbidden_paths;
end

function LOCAL_require_return_audit(audit)
if ~audit.pass
  error('I32V2:RETURNED_DENSE_REFERENCE_RETAINED', ...
    'A forbidden dense reference survived a declared death point.');
end
end

function bytes = LOCAL_value_bytes(value)
held = value; %#ok<NASGU>
info = whos('held');
bytes = info.bytes;
end

function value = LOCAL_nested_number(root, path, fallback)
value = root;
for k = 1:numel(path)
  if ~isstruct(value) || ~isfield(value, path{k})
    value = fallback;
    return
  end
  value = value.(path{k});
end
if ~(isnumeric(value) && isscalar(value) && isfinite(value))
  value = fallback;
end
end

function value = LOCAL_nested_text(root, path, fallback)
value = root;
for k = 1:numel(path)
  if ~isstruct(value) || ~isfield(value, path{k})
    value = fallback;
    return
  end
  value = value.(path{k});
end
if isstring(value) && isscalar(value)
  value = char(value);
elseif ~ischar(value)
  value = fallback;
end
end

function value = LOCAL_counter(module, name)
value = 0;
if isstruct(module) && isfield(module, 'counters') && ...
    isfield(module.counters, name)
  value = double(module.counters.(name));
end
end

function caps = LOCAL_empty_caps()
blank = struct('target', NaN, 'source', NaN, 'weight_or_gauss', NaN, ...
  'fullp', NaN, 'gqp', NaN, 'arithmetic', NaN, 'fourier', 0, ...
  'fourier_diagnostic', struct(), 'total', NaN);
caps.wall = blank;
caps.circle = blank;
caps.volume = blank;
caps.epsilon_GQP_emp = NaN;
caps.epsilon_M_emp = NaN;
caps.epsilon_N_emp = NaN;
caps.epsilon_N_GQP_emp = NaN;
end

function estimator = LOCAL_empty_estimator()
estimator.B_wall = NaN;
estimator.B_circle = NaN;
estimator.B_volume = NaN;
estimator.M_h = NaN;
estimator.field_lower = NaN;
estimator.q_emp = NaN;
estimator.k_interval = struct('lower', NaN, 'upper', NaN, ...
  'width', NaN, 'width_below_1e6', false);
end

function values = LOCAL_append_unique(values, value)
if isstring(value) && isscalar(value)
  value = char(value);
end
if ~ischar(value) || isempty(value)
  return
end
if ~any(strcmp(values, value))
  values{end + 1} = value;
end
end

function unresolved = LOCAL_collect_unresolved(warnings, unresolved)
for k = 1:numel(warnings)
  value = warnings{k};
  if ischar(value) && (contains(value, 'UNRESOLVED') || ...
      contains(value, 'UNAVAILABLE'))
    unresolved = LOCAL_append_unique(unresolved, value);
  end
end
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V2:UNIDENTIFIED_BLOCKER';
end
end

function stack = LOCAL_stack(err)
stack = struct('file', {}, 'name', {}, 'line', {});
for k = 1:numel(err.stack)
  stack(k).file = err.stack(k).file;
  stack(k).name = err.stack(k).name;
  stack(k).line = err.stack(k).line;
end
end

function LOCAL_emergency_output(result, output_dir, output_err)
result.audit.publication_exception = output_err.message;
save(fullfile(output_dir, 'result.mat'), 'result', '-v7.3');
fid = fopen(fullfile(output_dir, 'report.md'), 'wt');
if fid >= 0
  fprintf(fid, '# I3.2 empirical epsilon experiment v2\n\n');
  fprintf(fid, '- Label: `EMPIRICAL / UNQUALIFIED`\n');
  fprintf(fid, '- Status: `%s`\n', result.status);
  fprintf(fid, '- First blocker: `%s`\n', result.first_blocker);
  fprintf(fid, '- Publication warning: `PRIMARY_PUBLICATION_FAILED`\n');
  fclose(fid);
end
end
