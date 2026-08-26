function result = check_e_cap_v4(attempt, certificate_path, retry_ordinal)
%CHECK_E_CAP_V4 Run the coupled-sequence shifted-trace I3.2 experiment.
% Purpose:
%   Evaluate four coupled boundary levels of one frozen all-boundary trial,
%   replace the cubic lifting by shifted H^{1/2} trace factors, fit scalar
%   residual sequences, and publish an empirical nominal interval.
% Input:
%   attempt          - Must be `ecap-v4-a1`.
%   certificate_path - Explicit frozen fbie-a1 certificate MAT-file.
%   retry_ordinal    - Optional positive integer, default 1.
% Output:
%   result - Compact EMPIRICAL / UNQUALIFIED result struct.
% Main algorithm:
%   Read a double numerical view of the frozen certificate, dispatch four
%   coupled layer-potential actions, build shifted trace factors, contract
%   complete P matrices, fit B_inf+C*N^(-p), and write checkpoints.
% Based on:
%   research/projects/eig-apost/implementation/i3/design-3-2e.md.
% Main changes:
%   No geometric nested-difference gate and no cubic strong-source lifting.
% Numerical goal:
%   Return every independently finite fit/cap row under 1800 s and 2048 MiB.

if nargin < 3 || isempty(retry_ordinal)
  retry_ordinal = 1.0;
end
if ~(ischar(attempt) || (isstring(attempt) && isscalar(attempt))) || ...
    ~strcmp(char(attempt), 'ecap-v4-a1')
  error('I32V4:Attempt', 'The registered attempt is ecap-v4-a1.');
end
if ~(isnumeric(retry_ordinal) && isscalar(retry_ordinal) && ...
    isfinite(retry_ordinal) && retry_ordinal >= 1.0 && ...
    retry_ordinal == fix(retry_ordinal))
  error('I32V4:RetryOrdinal', 'retry_ordinal must be a positive integer.');
end

cfg = LOCAL_config(char(attempt), double(retry_ordinal));
entry_tic = tic;
output_dir = fullfile(fileparts(mfilename('fullpath')), 'output', cfg.attempt);
if ~isfolder(output_dir)
  mkdir(output_dir);
end
result = LOCAL_result(cfg, certificate_path, output_dir);
resource = struct('start_tic', entry_tic, ...
  'hard_s', cfg.resource.hard_s, ...
  'memory_mib_max', cfg.resource.memory_mib_max, ...
  'publication_mib', cfg.resource.publication_reserve_mib, ...
  'retained_mib', 0.0);

try
  % --- stage 1: frozen numerical view ---
  [certificate, anchor, input_public] = LOCAL_input(certificate_path, cfg);
  result.modules.input = input_public;
  result.state = 'INPUT_READY';
  result.elapsed_s = toc(entry_tic);
  i32v4_output(output_dir, result);

  % --- stage 2: four coupled layer-potential boundary actions ---
  boundary = i32v4_boundary_sequence(certificate, cfg, resource);
  LOCAL_require(boundary, 'BOUNDARY');
  result.modules.boundary = LOCAL_public(boundary);
  result.state = 'BOUNDARY_READY';
  result.elapsed_s = toc(entry_tic);
  i32v4_output(output_dir, result);

  % --- stage 3: shifted H^{1/2} trace right inverse ---
  hhalf = i32v4_hhalf_lift(certificate, boundary, cfg, resource);
  LOCAL_require(hhalf, 'HHALF');
  result.modules.hhalf = LOCAL_public(hhalf);
  result.state = 'HHALF_READY';
  result.elapsed_s = toc(entry_tic);
  i32v4_output(output_dir, result);

  % --- stage 4: full-P contractions, scalar fits, and interval ---
  cap = i32v4_fit_cap(certificate, anchor, boundary, hhalf, cfg, resource);
  LOCAL_require(cap, 'CAP');
  result.modules.cap = LOCAL_public(cap);
  result.sequence = cap.data.sequence;
  result.fit = cap.data.fit;
  result.caps = cap.data.caps;
  result.field = cap.data.field;
  result.estimator = cap.data.estimator;
  result.warnings = unique([LOCAL_warnings(result.modules), ...
    cap.warnings], 'stable');
  result.unresolved = cap.data.unresolved;
  result.status = 'COMPLETE';
  result.state = 'COMPLETE';
catch err
  result.status = 'PARTIAL';
  result.state = 'BLOCKED';
  result.first_blocker = LOCAL_identifier(err);
  result.blocker_message = err.message;
end

result.elapsed_s = toc(entry_tic);
result.resource = struct('elapsed_s', result.elapsed_s, ...
  'hard_s', cfg.resource.hard_s, ...
  'memory_mib_max', cfg.resource.memory_mib_max, ...
  'module_memory_is_proxy', true, 'os_rss_peak_measured', false);
result.warnings = unique([result.warnings, LOCAL_warnings(result.modules)], ...
  'stable');
i32v4_output(output_dir, result);
end

%% ==================== Frozen configuration ====================
% The design fixes every numerical level and empirical rule below.

function cfg = LOCAL_config(attempt, retry_ordinal)
cfg.schema = 'TEP_I3_2_ECAP_V4_HHALF_FIT_V1';
cfg.attempt = attempt;
cfg.retry_ordinal = retry_ordinal;
cfg.claim_label = 'EMPIRICAL / UNQUALIFIED';
cfg.physics = struct('beta', 0.5, 'd', 1.0, 'R', 0.2, ...
  'rho_disk', 17.0, 'M', 48.0, 'K', 97.0);
cfg.levels = struct('circle', [1024.0, 1280.0, 1536.0, 2048.0], ...
  'wall', [2048.0, 2560.0, 3072.0, 4096.0], ...
  'fullp', [8.0, 16.0, 32.0]);
cfg.gqp = struct('H', 1.1, 'proxy_distance', 0.2, ...
  'Nside', 160.0, 'Ntop', 160.0, 'Nedge', 80.0, 'Mpw', 32.0, ...
  'table_n', 2049.0, 'table_x_bounds', [-0.5, 0.5], ...
  'table_y_bounds', [-1.0, 1.0], 'table_panel', 512.0, ...
  'relative_uncertainty', 1.0e-10);
cfg.panel = struct('target_max', 128.0, 'source_max', 256.0);
cfg.normal = struct('circle_riccati_steps', 2048.0);
cfg.fit = struct('s_grid_count', 4095.0, 'rcond_min', 1.0e-12, ...
  'fmin_tol', 1.0e-12, 'fmin_iterations', 300.0);
cfg.ode = struct('steps', 8192.0, 'oracle_mode', 7.0);
cfg.lift = struct('delta_circle', 0.04, 'delta_wall', 0.04);
cfg.threshold = struct('recombination', 1.0e-12, ...
  'single_mode', 1.0e-10, 'interval_width', 1.0e-6);
cfg.roundoff = struct('multiplier', 100.0, 'eps', eps('double'));
cfg.resource = struct('hard_s', 1800.0, 'memory_mib_max', 2048.0, ...
  'publication_reserve_mib', 64.0);
cfg.flags = struct('reliability', false, 'outward_enclosure', false, ...
  'projected_gap', false, 'existence', false, ...
  'independent_reference', false, 'reliable_interval', false);
end

%% ==================== Frozen certificate input ====================
% Only the scientific certificate and ordinary field anchor are read.

function [c, a, public] = LOCAL_input(path, cfg)
if ~(ischar(path) || (isstring(path) && isscalar(path))) || ...
    ~isfile(char(path))
  error('I32V4:CertificateMissing', 'The explicit certificate is missing.');
end
loaded = load(char(path), 'staged');
if ~isfield(loaded, 'staged') || ~isstruct(loaded.staged) || ...
    ~all(isfield(loaded.staged, {'certificate', 'ordinary_anchor'}))
  error('I32V4:CertificateSchema', 'The staged certificate schema is missing.');
end
c = LOCAL_double_numeric(loaded.staged.certificate);
a = LOCAL_double_numeric(loaded.staged.ordinary_anchor);
clear loaded
LOCAL_validate_input(c, a, cfg);
public = struct('status', 'COMPLETE', 'available', true, ...
  'fixed_trial', true, 'source_attempt', c.source_attempt, ...
  'numeric_class', 'double', 'M_role', ...
  'artificial-wall prescribed Dirichlet trace order only', ...
  'density_resolve_count', 0.0, 'image_sum_calls', 0.0, ...
  'old_experiment_helper_calls', 0.0);
end

function value = LOCAL_double_numeric(value)
if isnumeric(value)
  value = double(value);
elseif isstruct(value)
  names = fieldnames(value);
  for item_idx = 1:numel(value)
    for name_idx = 1:numel(names)
      value(item_idx).(names{name_idx}) = ...
        LOCAL_double_numeric(value(item_idx).(names{name_idx}));
    end
  end
elseif iscell(value)
  for item_idx = 1:numel(value)
    value{item_idx} = LOCAL_double_numeric(value{item_idx});
  end
end
end

function LOCAL_validate_input(c, a, cfg)
required = {'source_attempt', 'khat', 'mu_h', 'gamma', 'beta', 'd', ...
  'R', 'rho_disk', 'X_L', 'X_R', 'M', 'K', 'delta_c', 'delta_w', ...
  'q_center', 'Pplus', 'Pminus', 'cplus', 'cminus', 'Gplus', ...
  'Gminus', 'eta_unit_256', 'xi_left_unit_512', ...
  'xi_right_unit_512', 'wall_orders_512', 'center_wall_jumps'};
anchor_required = {'N_tilde', 'lead_field_factor_plus', ...
  'lead_field_factor_minus'};
if ~isstruct(c) || ~all(isfield(c, required)) || ...
    ~isstruct(a) || ~all(isfield(a, anchor_required))
  error('I32V4:CertificateSchema', 'A required frozen field is missing.');
end
frozen_scalars = [c.d, c.beta, c.R, c.rho_disk, c.M, c.K, ...
  c.delta_c, c.delta_w];
expected = [cfg.physics.d, cfg.physics.beta, cfg.physics.R, ...
  cfg.physics.rho_disk, cfg.physics.M, cfg.physics.K, ...
  cfg.lift.delta_circle, cfg.lift.delta_wall];
if ~strcmp(c.source_attempt, 'fbie-a1') || ~isequal(frozen_scalars, expected)
  error('I32V4:CertificateSemantics', 'A frozen scalar semantic drifted.');
end
sizes_ok = isequal(size(c.q_center), [194, 1]) && ...
  isequal(size(c.Pplus), [97, 97]) && ...
  isequal(size(c.Pminus), [97, 97]) && ...
  isequal(size(c.cplus), [97, 1]) && ...
  isequal(size(c.cminus), [97, 1]) && ...
  isequal(size(c.Gplus), [194, 97]) && ...
  isequal(size(c.Gminus), [194, 97]) && ...
  isequal(size(c.eta_unit_256), [512, 194]) && ...
  isequal(size(c.xi_left_unit_512), [512, 194]) && ...
  isequal(size(c.xi_right_unit_512), [512, 194]) && ...
  isequal(size(a.lead_field_factor_plus), [97, 97]) && ...
  isequal(size(a.lead_field_factor_minus), [97, 97]);
if ~sizes_ok
  error('I32V4:CertificateDimension', 'A frozen array has the wrong size.');
end
values = {c.khat, c.mu_h, c.gamma, c.q_center, c.Pplus, c.Pminus, ...
  c.cplus, c.cminus, c.Gplus, c.Gminus, c.eta_unit_256, ...
  c.xi_left_unit_512, c.xi_right_unit_512, a.N_tilde, ...
  a.lead_field_factor_plus, a.lead_field_factor_minus};
for value_idx = 1:numel(values)
  if ~isa(values{value_idx}, 'double') || ...
      any(~isfinite(values{value_idx}(:)))
    error('I32V4:CertificateNonfinite', ...
      'A required numerical object is non-double or nonfinite.');
  end
end
if ~isequal(c.wall_orders_512(:), (-256.0:255.0).')
  error('I32V4:WallOrdering', 'The wall density ordering drifted.');
end
end

%% ==================== Compact publication ====================
% Partial artifacts keep the first true blocker without hiding finite stages.

function result = LOCAL_result(cfg, certificate_path, output_dir)
result = struct('schema', 'I32V4_RESULT_V1', 'attempt', cfg.attempt, ...
  'retry_ordinal', cfg.retry_ordinal, 'claim_label', cfg.claim_label, ...
  'status', 'INITIALIZED', 'state', 'ENTRY', 'first_blocker', '', ...
  'blocker_message', '', 'certificate_path', char(certificate_path), ...
  'output_dir', output_dir, 'elapsed_s', 0.0, 'modules', struct(), ...
  'sequence', struct(), 'fit', struct(), 'caps', struct(), ...
  'field', struct(), 'estimator', struct(), 'warnings', {{}}, ...
  'unresolved', {{}}, 'resource', struct(), 'flags', cfg.flags, ...
  'frozen', struct('M', cfg.physics.M, 'M_role', ...
  'artificial-wall prescribed Dirichlet trace order only', ...
  'levels_circle', cfg.levels.circle, 'levels_wall', cfg.levels.wall, ...
  'density_resolve_count', 0.0, 'image_sum_calls', 0.0, ...
  'cubic_lifting_calls', 0.0, 'gauss_lifting_calls', 0.0));
end

function LOCAL_require(module, label)
if ~isstruct(module) || ~isfield(module, 'available') || ~module.available
  identifier = ['I32V4:', label, 'Unavailable'];
  if isstruct(module) && isfield(module, 'first_blocker') && ...
      ~isempty(module.first_blocker)
    identifier = module.first_blocker;
  end
  error(identifier, 'The %s module is unavailable.', label);
end
end

function value = LOCAL_public(value)
if isstruct(value) && isfield(value, 'private')
  value = rmfield(value, 'private');
end
end

function warnings = LOCAL_warnings(modules)
warnings = {};
names = fieldnames(modules);
for name_idx = 1:numel(names)
  module = modules.(names{name_idx});
  if isstruct(module) && isfield(module, 'warnings') && ...
      iscell(module.warnings)
    warnings = [warnings, module.warnings]; %#ok<AGROW>
  end
end
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V4:UNIDENTIFIED_BLOCKER';
end
end
