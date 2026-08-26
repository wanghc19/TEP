function result = check_e_cap_v3(attempt, certificate_path, retry_ordinal)
%CHECK_E_CAP_V3 Run the minimal I3.2 fixed-MFS empirical-cap experiment.
% Purpose:
%   Dispatch the seven-file e-cap-v3 experiment and publish a readable
%   complete or partial artifact after every scientific stage.
% Input:
%   attempt          - Must be `ecap-v3-a1`.
%   certificate_path - Explicit frozen fbie-a1 certificate MAT-file.
%   retry_ordinal    - Optional positive integer recorded in the artifact.
% Output:
%   result - Compact EMPIRICAL / UNQUALIFIED result struct.
% Main algorithm:
%   Build one immutable configuration, read the frozen trial, build the one
%   MFS table, evaluate boundary actions, lift value defects, and contract
%   the complete P matrices.  No scientific parameter is adapted.
% Based on:
%   design-3-2d Section 13 (`ecap-v3-a1` minimal contract).
% Numerical goal:
%   Form independently publishable wall, circle, volume, denominator, and
%   nominal-interval rows under the 1800 s / 2048 MiB hard resource gates.

if nargin < 3 || isempty(retry_ordinal)
  retry_ordinal = 1.0;
end
if ~(ischar(attempt) || (isstring(attempt) && isscalar(attempt))) || ...
    ~strcmp(char(attempt), 'ecap-v3-a1')
  error('I32V3:Attempt', 'The only registered attempt is ecap-v3-a1.');
end
if ~(isnumeric(retry_ordinal) && isscalar(retry_ordinal) && ...
    isfinite(retry_ordinal) && retry_ordinal >= 1.0 && ...
    retry_ordinal == fix(retry_ordinal))
  error('I32V3:RetryOrdinal', 'retry_ordinal must be a positive integer.');
end

cfg = LOCAL_config(char(attempt), double(retry_ordinal));
entry_tic = tic;
output_dir = fullfile(fileparts(mfilename('fullpath')), 'output', cfg.attempt);
if ~isfolder(output_dir)
  mkdir(output_dir);
end
result = LOCAL_result(cfg, certificate_path);
result.output_dir = output_dir;
resource = struct('start_tic', entry_tic, 'soft_s', cfg.resource.soft_s, ...
  'hard_s', cfg.resource.hard_s, ...
  'memory_mib_max', cfg.resource.memory_mib_max, ...
  'publication_mib', cfg.resource.publication_reserve_mib, ...
  'retained_mib', 0.0);

try
  % --- stage 1: frozen certificate ---
  input = i32v3_input(certificate_path, cfg);
  result.modules.input = LOCAL_public(input);
  LOCAL_require_available(input, 'certificate');
  trial = input.private;
  clear input
  resource.retained_mib = LOCAL_workspace_mib();
  result.state = 'CERTIFICATE_READY';
  result.elapsed_s = toc(entry_tic);
  i32v3_output(output_dir, result);

  % --- stage 2: one fixed MFS table ---
  gqp = i32v3_gqp('build', trial.certificate, cfg, resource);
  result.modules.gqp = LOCAL_public(gqp);
  LOCAL_require_available(gqp, 'GQP');
  resource.retained_mib = LOCAL_workspace_mib();
  result.state = 'GQP_READY';
  result.elapsed_s = toc(entry_tic);
  i32v3_output(output_dir, result);

  % --- stage 3: all boundary actions ---
  boundary = i32v3_boundary(trial.certificate, gqp, cfg, resource);
  result.modules.boundary = LOCAL_public(boundary);
  LOCAL_require_available(boundary, 'boundary');
  resource.retained_mib = LOCAL_workspace_mib();
  result.state = 'BOUNDARY_READY';
  result.elapsed_s = toc(entry_tic);
  i32v3_output(output_dir, result);

  % The 2049^2 kernel table is dead after all boundary actions.
  clear gqp
  resource.retained_mib = LOCAL_workspace_mib();

  % --- stage 4: value-only boundary lifting ---
  lifting = i32v3_lifting('run', trial.certificate, boundary, cfg, resource);
  result.modules.lifting = LOCAL_public(lifting);
  LOCAL_require_available(lifting, 'lifting');
  resource.retained_mib = LOCAL_workspace_mib();
  result.state = 'LIFTING_READY';
  result.elapsed_s = toc(entry_tic);
  i32v3_output(output_dir, result);

  % --- stage 5: full-P contractions and empirical caps ---
  cap = i32v3_cap(trial, boundary, lifting, ...
    result.modules.gqp, cfg, resource);
  result.modules.cap = LOCAL_public(cap);
  LOCAL_require_available(cap, 'cap');
  result.estimator = cap.data.estimator;
  result.caps = cap.data.caps;
  result.field = cap.data.field;
  result.component = cap.data.component;
  result.warnings = LOCAL_warnings(result.modules);
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
result.resource.elapsed_s = result.elapsed_s;
result.resource.hard_s = cfg.resource.hard_s;
result.resource.memory_mib_max = cfg.resource.memory_mib_max;
result.resource.final_workspace_mib = LOCAL_workspace_mib();
result.resource.soft_time_exceeded = result.elapsed_s > cfg.resource.soft_s;
result.warnings = unique([result.warnings, LOCAL_warnings(result.modules)], ...
  'stable');
i32v3_output(output_dir, result);
end

%% ==================== Frozen configuration ====================
% Every numerical parameter below is fixed by design-3-2d Section 13.

function cfg = LOCAL_config(attempt, retry_ordinal)
cfg.schema = 'TEP_I3_2_ECAP_V3_FIXED_MFS_V1';
cfg.attempt = attempt;
cfg.retry_ordinal = retry_ordinal;
cfg.claim_label = 'EMPIRICAL / UNQUALIFIED';
cfg.physics = struct('beta', 0.5, 'd', 1.0, 'R', 0.2, ...
  'rho_disk', 17.0, 'M', 48.0, 'K', 97.0);
cfg.levels = struct('circle_source', [512.0, 1024.0, 2048.0], ...
  'circle_target', [512.0, 1024.0, 2048.0], ...
  'wall_source', [1024.0, 2048.0, 4096.0], ...
  'wall_target', [1024.0, 2048.0, 4096.0], ...
  'riccati', [512.0, 1024.0, 2048.0], ...
  'lift_gauss', [32.0, 64.0, 128.0], ...
  'fullp', [8.0, 16.0, 32.0]);
cfg.gqp = struct('H', 1.1, 'proxy_distance', 0.2, ...
  'Nside', 160.0, 'Ntop', 160.0, 'Nedge', 80.0, 'Mpw', 32.0, ...
  'table_n', 2049.0, 'table_x_bounds', [-0.5, 0.5], ...
  'table_y_bounds', [-1.0, 1.0], 'table_panel', 512.0, ...
  'relative_uncertainty', 1.0e-10, 'spot_count', 12.0, ...
  'spot_tolerance', 1.0e-10);
cfg.panel = struct('target_max', 128.0, 'source_max', 256.0);
cfg.threshold = struct('refinement_contraction', 0.5, ...
  'absolute_floor', 1.0e-10, 'phase', 1.0e-10, ...
  'recombination', 1.0e-12, 'interval_width', 1.0e-6, ...
  'gram', 1.0e-12, 'single_mode', 1.0e-10);
cfg.roundoff = struct('multiplier', 100.0, 'eps', eps('double'));
cfg.lift = struct('delta_circle', 0.04, 'delta_wall', 0.04);
cfg.resource = struct('soft_s', 1500.0, 'hard_s', 1800.0, ...
  'memory_mib_max', 2048.0, 'publication_reserve_mib', 64.0);
cfg.bands = [0.0, 31.0; 32.0, 63.0; 64.0, 127.0; ...
  128.0, 255.0; 256.0, 511.0; 512.0, Inf];
cfg.flags = struct('reliability', false, ...
  'outward_enclosure', false, 'projected_gap', false, ...
  'existence', false, 'independent_reference', false, ...
  'certified_tail', false, 'reliable_interval', false);
end

%% ==================== Entry contracts ====================
% These helpers publish compact checkpoints and preserve fail-open science.

function result = LOCAL_result(cfg, certificate_path)
result = struct('schema', 'I32V3_RESULT_V1', 'attempt', cfg.attempt, ...
  'retry_ordinal', cfg.retry_ordinal, 'claim_label', cfg.claim_label, ...
  'status', 'INITIALIZED', 'state', 'ENTRY', 'first_blocker', '', ...
  'blocker_message', '', 'certificate_path', char(certificate_path), ...
  'elapsed_s', 0.0, 'modules', struct(), 'warnings', {{}}, ...
  'unresolved', {{}}, 'estimator', struct(), 'caps', struct(), ...
  'field', struct(), 'component', struct(), 'resource', struct(), ...
  'flags', cfg.flags, 'frozen', struct('M_role', ...
  'wall Dirichlet trace order only', 'M', cfg.physics.M, ...
  'density_resolve_count', 0.0, 'image_sum_calls', 0.0, ...
  'rayleigh_field_calls', 0.0, 'levels', cfg.levels));
end

function LOCAL_require_available(module, label)
if ~isstruct(module) || ~isfield(module, 'available') || ~module.available
  blocker = ['I32V3:', upper(label), 'Unavailable'];
  if isstruct(module) && isfield(module, 'first_blocker') && ...
      ~isempty(module.first_blocker)
    blocker = module.first_blocker;
  end
  error(blocker, 'The %s stage did not return a usable object.', label);
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
for j = 1:numel(names)
  module = modules.(names{j});
  if isstruct(module) && isfield(module, 'warnings') && iscell(module.warnings)
    warnings = [warnings, module.warnings]; %#ok<AGROW>
  end
end
end

function mib = LOCAL_workspace_mib()
items = whos;
mib = sum([items.bytes]) / 2^20;
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V3:UNIDENTIFIED_BLOCKER';
end
end
