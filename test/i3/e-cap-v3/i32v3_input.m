function out = i32v3_input(certificate_path, cfg)
%I32V3_INPUT Read the frozen fbie-a1 certificate without historical maps.
% Purpose:
%   Load only the finite certificate and ordinary denominator anchor needed
%   to define the unchanged all-boundary layer-potential trial.
% Input:
%   certificate_path - Explicit MAT-file containing `staged`.
%   cfg              - Frozen v3 numerical configuration.
% Output:
%   out.private - Double-valued certificate and ordinary anchor.
% Main algorithm:
%   Whitelist the two scientific structs, convert numerical leaves to double,
%   and apply only necessary schema, size, finiteness, and no-resolve checks.
% Based on:
%   design-3-2d Section 13 frozen-object contract.
% Notes:
%   No hash, Git metadata, historical output, or raw diagnostic map is read.

timer = tic;
out = LOCAL_empty();
out.audit.symbol_ledger = struct( ...
  'q_center', 'frozen 194-by-1 wall-pair state', ...
  'eta_unit_256', 'frozen [tau;zeta] circle response density', ...
  'xi_left_unit_512', 'frozen left-wall density coefficients', ...
  'xi_right_unit_512', 'frozen right-wall density coefficients', ...
  'Pplus', 'complete right propagation matrix', ...
  'Pminus', 'complete left propagation matrix');
try
  if ~(ischar(certificate_path) || ...
      (isstring(certificate_path) && isscalar(certificate_path))) || ...
      ~isfile(char(certificate_path))
    error('I32V3:CertificateMissing', ...
      'The explicit certificate path is invalid or missing.');
  end
  loaded = load(char(certificate_path), 'staged');
  if ~isfield(loaded, 'staged') || ~isstruct(loaded.staged) || ...
      ~all(isfield(loaded.staged, {'certificate', 'ordinary_anchor'}))
    error('I32V3:CertificateSchema', 'The staged certificate schema is missing.');
  end
  c = LOCAL_double_numeric(loaded.staged.certificate);
  a = LOCAL_double_numeric(loaded.staged.ordinary_anchor);
  clear loaded
  LOCAL_validate(c, a, cfg);
  out.private = struct('certificate', c, 'ordinary_anchor', a);
  out.audit.source_attempt = c.source_attempt;
  out.audit.fixed_trial = true;
  out.audit.raw_certificate_unchanged = true;
  out.audit.numeric_view_class = 'double';
  out.audit.M_role = 'wall Dirichlet trace order only';
  out.audit.forbidden_fields_read = 0.0;
  out.counters = struct('candidate_solves', 0.0, 'qz_solves', 0.0, ...
    'propagation_solves', 0.0, 'bie_solves', 0.0, ...
    'density_solves', 0.0, 'old_ecap_calls', 0.0, ...
    'image_sum_calls', 0.0, 'rayleigh_field_calls', 0.0);
  out.available = true;
  out.status = 'COMPLETE';
catch err
  out.status = 'BLOCKED';
  out.first_blocker = LOCAL_identifier(err);
  out.audit.exception_message = err.message;
end
info = whos('out');
out.memory = struct('retained_mib', info.bytes / 2^20, ...
  'largest_object', 'frozen certificate numerical view');
out.audit.elapsed_s = toc(timer);
end

%% ==================== Numerical view ====================
% Conversion changes classes only; it does not reinterpret any frozen value.

function value = LOCAL_double_numeric(value)
if isnumeric(value)
  value = double(value);
elseif isstruct(value)
  names = fieldnames(value);
  for k = 1:numel(value)
    for j = 1:numel(names)
      value(k).(names{j}) = LOCAL_double_numeric(value(k).(names{j}));
    end
  end
elseif iscell(value)
  for j = 1:numel(value)
    value{j} = LOCAL_double_numeric(value{j});
  end
end
end

function LOCAL_validate(c, a, cfg)
required = {'source_attempt', 'khat', 'mu_h', 'gamma', 'beta', 'd', ...
  'R', 'rho_disk', 'X_L', 'X_R', 'M', 'K', 'delta_c', 'delta_w', ...
  'q_center', 'Pplus', 'Pminus', 'cplus', 'cminus', 'Gplus', ...
  'Gminus', 'eta_unit_256', 'xi_left_unit_512', ...
  'xi_right_unit_512', 'wall_orders_512', 'center_wall_jumps'};
anchor_required = {'N_tilde', 'lead_field_factor_plus', ...
  'lead_field_factor_minus'};
if ~isstruct(c) || ~all(isfield(c, required)) || ...
    ~isstruct(a) || ~all(isfield(a, anchor_required))
  error('I32V3:CertificateSchema', 'A required frozen field is missing.');
end
if ~strcmp(c.source_attempt, 'fbie-a1') || ...
    ~isequal([c.d, c.beta, c.R, c.rho_disk, c.M, c.K], ...
    [cfg.physics.d, cfg.physics.beta, cfg.physics.R, ...
    cfg.physics.rho_disk, cfg.physics.M, cfg.physics.K]) || ...
    c.delta_c ~= cfg.lift.delta_circle || c.delta_w ~= cfg.lift.delta_wall
  error('I32V3:CertificateIdentity', 'Frozen scalar semantics drifted.');
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
  error('I32V3:CertificateDimension', 'A frozen array has the wrong size.');
end
values = {c.khat, c.mu_h, c.gamma, c.q_center, c.Pplus, c.Pminus, ...
  c.cplus, c.cminus, c.Gplus, c.Gminus, c.eta_unit_256, ...
  c.xi_left_unit_512, c.xi_right_unit_512, a.N_tilde, ...
  a.lead_field_factor_plus, a.lead_field_factor_minus};
for j = 1:numel(values)
  if ~isa(values{j}, 'double') || any(~isfinite(values{j}(:)))
    error('I32V3:CertificateNonfinite', ...
      'A required numerical object is non-double or nonfinite.');
  end
end
if ~isequal(c.wall_orders_512(:), (-256.0:255.0).')
  error('I32V3:CertificateOrdering', 'Wall negative-Nyquist ordering drifted.');
end
end

function out = LOCAL_empty()
out = struct('schema', 'I32V3_INPUT_V1', 'status', 'INITIALIZED', ...
  'available', false, 'warnings', {{}}, 'first_blocker', '', ...
  'audit', struct(), 'counters', struct(), 'memory', struct(), ...
  'private', struct());
end

function identifier = LOCAL_identifier(err)
identifier = err.identifier;
if isempty(identifier)
  identifier = 'I32V3:UNIDENTIFIED_BLOCKER';
end
end
