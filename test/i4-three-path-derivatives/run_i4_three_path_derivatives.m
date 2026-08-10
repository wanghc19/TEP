function results = run_i4_three_path_derivatives(mode)
%RUN_I4_THREE_PATH_DERIVATIVES Run I4 derivative and four-action diagnostics.
%
% Purpose:
%   Qualify analytic first and second derivatives of the local Linton Ewald
%   split, run a low-cost MATLAB pilot, or run the frozen four-action ladder.
%
% Input:
%   mode - 'qualification', 'pilot', or 'full'.
%
% Output:
%   results - Reproducible result bundle also written to MAT/CSV/Markdown.
%
% Main algorithm:
%   1. Evaluate Linton Eq. (2.65) and all X/Y derivatives, then apply the
%      single global project sign and the signed physical-coordinate mapper.
%   2. Qualify against centered finite differences, independent Rayleigh
%      derivatives, Helmholtz and source/target identities, and refinements.
%   3. Reuse one Ewald or MFS kernel tuple per wall to form SLP-D, SLP-N,
%      DLP-D, and DLP-N.  Raw Neumann coefficients retain i*gamma scaling.
%   4. Gate package point components per action: G; Gx; Gx/Gy; Gxx/Gxy.
%      In full mode, stop at the first failed action gate and write no later
%      scientific coefficient rows. Gyy remains diagnostic only.
%
% Based on:
%   test/i4-three-path/run_i4_three_path.m and Linton (1998), Eq. (2.65).
%
% Main changes:
%   Adds analytic gradients/Hessians, explicit E_0/E_{-1} real-space terms,
%   signed transverse mapping, raw wall-normal actions, and staged stopping.
%
% Numerical goal:
%   Distinguish Ewald, package-MFS, and direct Rayleigh paths per action,
%   side, mode, density, trace, and refinement variable.

  if nargin < 1 || isempty(mode)
    mode = 'qualification';
  end
  if isstring(mode)
    mode = char(mode);
  end
  mode = lower(strtrim(mode));
  if ~any(strcmp(mode, {'qualification', 'pilot', 'full'}))
    error('run_i4_three_path_derivatives:InvalidMode', ...
      'mode must be ''qualification'', ''pilot'', or ''full''.');
  end

  config = i4_three_path_derivatives_config();
  addpath(config.repo_root);
  if LOCAL_is_octave() && isempty(which('Faddeeva_erfc'))
    addpath(fullfile(config.here, 'octave_compat'));
  end
  label = mode;
  if strcmp(mode, 'full')
    label = 'canonical';
  end
  output_dir = fullfile(config.output_root, label);
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end
  log_fid = fopen(fullfile(output_dir, 'run.log'), 'w');
  if log_fid < 0
    error('run_i4_three_path_derivatives:LogOpenFailed', ...
      'Could not open the run log.');
  end
  log_cleanup = onCleanup(@() fclose(log_fid));
  started = datestr(now, 31);
  LOCAL_log(log_fid, 'I4 three-path derivatives mode=%s started=%s\n', ...
    mode, started);

  ledgers = LOCAL_empty_ledgers();
  ledgers = LOCAL_convention_rows(config, ledgers);
  total_token = tic;
  token = tic;
  [qualification, ledgers] = LOCAL_qualification(config, ledgers, log_fid);
  ledgers.timings.rows(end + 1, :) = {'qualification', toc(token), ...
    'analytic derivative qualification'};

  if strcmp(mode, 'qualification')
    summary = qualification;
  elseif ~qualification.pass
    summary = struct('status', 'DERIVATIVE_REFERENCE_UNCERTIFIED', ...
      'pass', false, 'qualification', qualification, ...
      'stop_after', 'qualification');
    ledgers.decision.rows(end + 1, :) = {'wall_actions', 'BLOCKER', ...
      'NOT_RUN_PREREQUISITE', 0, ...
      'Derivative qualification failed before wall evaluation.'};
  elseif strcmp(mode, 'pilot')
    [summary, ledgers] = LOCAL_pilot(config, ledgers, log_fid, output_dir, ...
      qualification);
  else
    [summary, ledgers] = LOCAL_full(config, ledgers, log_fid, qualification);
  end

  total_seconds = toc(total_token);
  ledgers.timings.rows(end + 1, :) = {'total', total_seconds, ...
    'measured wall-clock time'};
  results = struct('mode', mode, 'label', label, 'started', started, ...
    'finished', datestr(now, 31), 'total_seconds', total_seconds, ...
    'status', summary.status, 'summary', summary, 'config', config, ...
    'ledgers', ledgers, 'provenance', LOCAL_provenance());
  LOCAL_write_artifacts(output_dir, results);
  LOCAL_log(log_fid, 'status=%s seconds=%.6f output=%s\n', ...
    results.status, total_seconds, output_dir);
  clear log_cleanup;
end

%% ==================== Analytic Ewald kernel ====================
% These helpers evaluate Linton derivatives before one global project sign.

function physical = LOCAL_project_kernel(config, X_signed, Y, level)
  if any(X_signed(:) == 0)
    error('run_i4_three_path_derivatives:ZeroTransverseSeparation', ...
      'Analytic derivatives require nonzero transverse separation.');
  end
  sx = sign(X_signed(:).');
  magnitude = LOCAL_linton_kernel(config.k, config.beta, config.d, ...
    abs(X_signed(:).'), Y(:).', level);
  fields = fieldnames(magnitude);
  for j = 1:length(fields)
    magnitude.(fields{j}) = config.project_sign * magnitude.(fields{j});
  end
  physical.G = magnitude.G;
  physical.Gx = sx .* magnitude.GX_abs;
  physical.Gy = magnitude.GY;
  physical.Gxx = magnitude.GXX_abs;
  physical.Gxy = sx .* magnitude.GXY_abs;
  physical.Gyy = magnitude.GYY;
  physical.GX_abs = magnitude.GX_abs;
  physical.GXY_abs = magnitude.GXY_abs;
  physical.sx = sx;
end

function out = LOCAL_linton_kernel(k, beta, d, X, Y, level)
  X = X(:).';
  Y = Y(:).';
  [reciprocal, reciprocal_derivatives] = ...
    LOCAL_linton_reciprocal(k, beta, d, X, Y, level);
  [real_space, real_derivatives] = ...
    LOCAL_linton_real_space(k, beta, d, X, Y, level);
  out.G = reciprocal + real_space;
  out.GX_abs = reciprocal_derivatives.GX + real_derivatives.GX;
  out.GY = reciprocal_derivatives.GY + real_derivatives.GY;
  out.GXX_abs = reciprocal_derivatives.GXX + real_derivatives.GXX;
  out.GXY_abs = reciprocal_derivatives.GXY + real_derivatives.GXY;
  out.GYY = reciprocal_derivatives.GYY + real_derivatives.GYY;
end

function [value, derivative] = LOCAL_linton_reciprocal( ...
    k, beta, d, X, Y, level)
  m = (-level.M1:level.M1).';
  beta_m = beta + 2 * pi * m / d;
  q = LOCAL_linton_branch(k, beta_m);
  b = level.a / d;
  c = q * d / (2 * level.a);
  z_plus = bsxfun(@plus, c, b * X);
  z_minus = bsxfun(@minus, c, b * X);
  erfc_plus = LOCAL_complex_erfc(z_plus);
  erfc_minus = LOCAL_complex_erfc(z_minus);
  erfc_prime_plus = -(2 / sqrt(pi)) * exp(-(z_plus .^ 2));
  erfc_prime_minus = -(2 / sqrt(pi)) * exp(-(z_minus .^ 2));
  erfc_second_plus = (4 / sqrt(pi)) * z_plus .* exp(-(z_plus .^ 2));
  erfc_second_minus = (4 / sqrt(pi)) * z_minus .* exp(-(z_minus .^ 2));
  exp_plus = exp(bsxfun(@times, q, X));
  exp_minus = exp(bsxfun(@times, -q, X));

  F_plus = exp_plus .* erfc_plus;
  F_minus = exp_minus .* erfc_minus;
  FX_plus = exp_plus .* bsxfun(@plus, q .* erfc_plus, ...
    b * erfc_prime_plus);
  FX_minus = -exp_minus .* bsxfun(@plus, q .* erfc_minus, ...
    b * erfc_prime_minus);
  FXX_plus = exp_plus .* (bsxfun(@times, q .^ 2, erfc_plus) + ...
    bsxfun(@times, 2 * b * q, erfc_prime_plus) + ...
    b ^ 2 * erfc_second_plus);
  FXX_minus = exp_minus .* (bsxfun(@times, q .^ 2, erfc_minus) + ...
    bsxfun(@times, 2 * b * q, erfc_prime_minus) + ...
    b ^ 2 * erfc_second_minus);

  phase = exp(1i * bsxfun(@times, beta_m, Y));
  scale = -1 / (4 * d);
  base = bsxfun(@rdivide, phase, q);
  F = F_plus + F_minus;
  FX = FX_plus + FX_minus;
  FXX = FXX_plus + FXX_minus;
  value = scale * sum(base .* F, 1);
  derivative.GX = scale * sum(base .* FX, 1);
  derivative.GY = scale * sum(bsxfun(@times, 1i * beta_m, base) .* F, 1);
  derivative.GXX = scale * sum(base .* FXX, 1);
  derivative.GXY = scale * sum(bsxfun(@times, 1i * beta_m, base) .* FX, 1);
  derivative.GYY = scale * sum(bsxfun(@times, -(beta_m .^ 2), base) .* F, 1);
end

function [value, derivative] = LOCAL_linton_real_space( ...
    k, beta, d, X, Y, level)
  m = (-level.M2:level.M2).';
  image_Y = bsxfun(@minus, Y, m * d);
  alpha = (level.a / d) ^ 2;
  z = alpha * bsxfun(@plus, X .^ 2, image_Y .^ 2);
  if any(z(:) == 0)
    error('run_i4_three_path_derivatives:SingularEwaldPair', ...
      'The real-space Ewald sum contains a singular image pair.');
  end
  exp_neg_z = exp(-z);
  E_minus_one = exp_neg_z .* (1 ./ z + 1 ./ (z .^ 2));
  E_zero = exp_neg_z ./ z;
  E_one = expint(z);
  S = zeros(size(z));
  S_z = zeros(size(z));
  S_zz = zeros(size(z));
  E_nm1 = E_minus_one;
  E_n = E_zero;
  E_np1 = E_one;
  for n = 0:level.N
    coefficient = (k * d / (2 * level.a)) ^ (2 * n) / factorial(n);
    S = S + coefficient * E_np1;
    S_z = S_z - coefficient * E_n;
    S_zz = S_zz + coefficient * E_nm1;
    if n < level.N
      E_nm1 = E_n;
      E_n = E_np1;
      E_np1 = (exp_neg_z - z .* E_n) / (n + 1);
    end
  end
  z_X = 2 * alpha * X;
  z_Y = 2 * alpha * image_Y;
  phase = exp(1i * beta * m * d);
  scale = -1 / (4 * pi);
  value = scale * sum(bsxfun(@times, phase, S), 1);
  derivative.GX = scale * sum(bsxfun(@times, phase, ...
    bsxfun(@times, S_z, z_X)), 1);
  derivative.GY = scale * sum(bsxfun(@times, phase, S_z .* z_Y), 1);
  derivative.GXX = scale * sum(bsxfun(@times, phase, ...
    bsxfun(@times, S_zz, z_X .^ 2) + 2 * alpha * S_z), 1);
  derivative.GXY = scale * sum(bsxfun(@times, phase, ...
    bsxfun(@times, S_zz .* z_Y, z_X)), 1);
  derivative.GYY = scale * sum(bsxfun(@times, phase, ...
    S_zz .* (z_Y .^ 2) + 2 * alpha * S_z), 1);
end

function q = LOCAL_linton_branch(k, beta_m)
  difference = beta_m .^ 2 - k ^ 2;
  q = zeros(size(beta_m));
  evanescent = difference >= 0;
  q(evanescent) = sqrt(difference(evanescent));
  q(~evanescent) = -1i * sqrt(-difference(~evanescent));
end

function value = LOCAL_complex_erfc(z)
  if ~isempty(which('Faddeeva_erfc'))
    value = Faddeeva_erfc(z);
  else
    value = erfc(z);
  end
end

%% ==================== Qualification workflow ====================
% These helpers certify physical derivatives without package-MFS reuse.

function ledgers = LOCAL_empty_ledgers()
  ledgers.backend_metadata = LOCAL_ledger( ...
    {'key', 'value', 'note'});
  ledgers.kernel_convergence = LOCAL_ledger( ...
    {'point', 'component', 'level', 'a', 'M1', 'M2', 'N', ...
    'value_re', 'value_im', 'self_change', 'gate', 'pass'});
  ledgers.point_oracle = LOCAL_ledger( ...
    {'point', 'component', 'method', 'rayleigh_M', 'fd_h', ...
    'value_re', 'value_im', 'reference_re', 'reference_im', ...
    'error', 'gate', 'pass', 'estimate_kind', 'r_coarse', 'r_fine', ...
    'role', 'mandatory'});
  ledgers.identity = LOCAL_ledger( ...
    {'point', 'identity', 'residual_re', 'residual_im', 'scale', ...
    'normalized', 'gate', 'pass'});
  ledgers.projection = LOCAL_ledger( ...
    {'trace', 'm', 'expected_re', 'expected_im', 'observed_re', ...
    'observed_im', 'abs_error', 'gate', 'pass', 'note'});
  ledgers.action_level = LOCAL_ledger( ...
    {'action', 'path', 'level', 'ntot', 'Ny', 'M', 'a', 'M1', ...
    'M2', 'N', 'self_change', 'gate', 'pass', 'enforced'});
  ledgers.coefficient = LOCAL_ledger( ...
    {'level', 'density', 'layer', 'side', 'trace', 'm', ...
    'left_path', 'right_path', 'left_re', 'left_im', 'right_re', ...
    'right_im', 'abs_error', 'gate', 'pass', 'enforced', 'normalization'});
  ledgers.wall_point = LOCAL_ledger( ...
    {'level', 'density', 'action', 'side', 'wall_index', 'y', ...
    'E_re', 'E_im', 'P_re', 'P_im', 'abs_error', 'ntot', 'Ny'});
  ledgers.mutation = LOCAL_ledger( ...
    {'mutation', 'point', 'component', 'error', 'gate', ...
    'expected_failure', 'failed_as_expected', 'note'});
  ledgers.decision = LOCAL_ledger( ...
    {'stage', 'classification', 'status', 'pass', 'note'});
  ledgers.timings = LOCAL_ledger({'stage', 'seconds', 'note'});
  ledgers.conventions = LOCAL_ledger({'key', 'value', 'note'});
  ledgers.gates = LOCAL_ledger({'gate', 'value', 'scope'});
end

function ledger = LOCAL_ledger(headers)
  ledger = struct('headers', {headers}, 'rows', {cell(0, length(headers))});
end

function ledgers = LOCAL_convention_rows(config, ledgers)
  rows = { ...
    'time', config.time_convention, 'outgoing convention'; ...
    'project_free_space', config.project_free, 'package convention'; ...
    'linton_free_space', config.linton_free, 'formula convention'; ...
    'project_sign', num2str(config.project_sign), ...
      'applied exactly once after reciprocal plus real sum'; ...
    'signed_mapper', 'Gx=sx*GX_abs; Gxy=sx*GXY_abs', ...
      'sx=sign(x_target-x_source); Xabs=abs(dx)'; ...
    'zero_separation', 'rejected', 'derivative API excludes dx=0'; ...
    'eta', config.eta_convention, 'mu=-sigma'; ...
    'wall_normals', config.normal_convention, 'outward normals'; ...
    'neumann_coefficients', 'raw', ...
      'never divide by i*gamma_m; oracle is i*gamma_m times D'; ...
    'analytic_backend', 'Linton_2_65_closed_form_no_fd_fallback', ...
      'explicit E0 and Eminus1 terms'};
  ledgers.conventions.rows = [ledgers.conventions.rows; rows];
  ledgers.gates.rows = { ...
    'linton', config.gate.linton, 'published value replay'; ...
    'point', config.gate.point, 'analytic/FD/Rayleigh/identity'; ...
    'self', config.gate.self, 'all retained refinement changes'; ...
    'coefficient', config.gate.coefficient, 'absolute raw coefficient pairs'; ...
    'projection', config.gate.projection, 'pure Fourier projection'};
end

function [summary, ledgers] = LOCAL_qualification(config, ledgers, log_fid)
  provenance = LOCAL_provenance();
  ledgers = LOCAL_append_backend(ledgers, provenance);
  [reference_rows, reference_pass] = LOCAL_linton_reference_qualification(config);
  ledgers.point_oracle.rows = [ledgers.point_oracle.rows; reference_rows];
  ledgers.decision.rows(end + 1, :) = {'published_reference', ...
    'MANDATORY', LOCAL_pass_status(reference_pass, ...
    'EWALD_REFERENCE_CERTIFIED', 'EWALD_REFERENCE_UNCERTIFIED'), ...
    reference_pass, 'Published values are checked in Linton sign convention.'};
  if ~reference_pass
    ledgers.decision.rows(end + 1, :) = {'value_gradient_hessian', ...
      'MANDATORY', 'NOT_RUN_PREREQUISITE', 0, ...
      'Published reference replay failed.'};
    summary = struct('status', 'EWALD_REFERENCE_UNCERTIFIED', ...
      'pass', false, 'point_gate', config.gate.point, ...
      'self_gate', config.gate.self);
    return;
  end
  all_pass = true;
  stop_status = '';
  stages = { {'G'}, {'Gx', 'Gy'}, {'Gxx', 'Gxy', 'Gyy'} };
  stage_names = {'value', 'gradient', 'hessian'};
  fail_status = {'EWALD_REFERENCE_UNCERTIFIED', ...
    'EWALD_GRAD_UNCERTIFIED', 'EWALD_HESS_UNCERTIFIED'};

  for istage = 1:length(stages)
    components = stages{istage};
    stage_pass = true;
    stage_failure_status = fail_status{istage};
    LOCAL_log(log_fid, 'qualification stage=%s\n', stage_names{istage});
    for ip = 1:length(config.points)
      point = config.points(ip);
      [values, rows, ewald_pass] = LOCAL_ewald_point_levels( ...
        config, point, components);
      ledgers.kernel_convergence.rows = ...
        [ledgers.kernel_convergence.rows; rows];
      stage_pass = stage_pass && ewald_pass;
      authority = values.authority;
      [oracle_rows, oracle_pass, ~, oracle_failure] = LOCAL_point_oracles( ...
        config, point, components, authority);
      ledgers.point_oracle.rows = [ledgers.point_oracle.rows; oracle_rows];
      stage_pass = stage_pass && oracle_pass;
      if ~oracle_pass && ~isempty(oracle_failure)
        stage_failure_status = oracle_failure;
      end
      [identity_rows, identity_pass] = LOCAL_point_identities( ...
        config, point, components, authority);
      ledgers.identity.rows = [ledgers.identity.rows; identity_rows];
      stage_pass = stage_pass && identity_pass;
    end
    ledgers.decision.rows(end + 1, :) = {stage_names{istage}, ...
      'MANDATORY', LOCAL_pass_status(stage_pass, ...
      ['EWALD_', upper(stage_names{istage}), '_CERTIFIED'], ...
      stage_failure_status), stage_pass, ...
      'Physical signed components only; no abs-coordinate aliases.'};
    if ~stage_pass
      all_pass = false;
      stop_status = stage_failure_status;
      for later = istage + 1:length(stages)
        ledgers.decision.rows(end + 1, :) = {stage_names{later}, ...
          'MANDATORY', 'NOT_RUN_PREREQUISITE', 0, ...
          ['Stopped after ', stage_names{istage}, ' failure.']};
      end
      break;
    end
  end

  if all_pass
    [projection_rows, projection_pass] = LOCAL_projection_qualification(config);
    ledgers.projection.rows = [ledgers.projection.rows; projection_rows];
    [mutation_rows, mutation_pass] = LOCAL_mutation_qualification(config);
    ledgers.mutation.rows = [ledgers.mutation.rows; mutation_rows];
    all_pass = projection_pass && mutation_pass;
    if ~all_pass
      stop_status = 'DERIVATIVE_REFERENCE_UNCERTIFIED';
    end
    ledgers.decision.rows(end + 1, :) = {'projection_and_mutations', ...
      'MANDATORY', LOCAL_pass_status(all_pass, ...
      'ORACLE_CONTROLS_CERTIFIED', stop_status), all_pass, ...
      'Pure Fourier projection and sign/normalization mutations.'};
  end
  if all_pass
    if LOCAL_is_octave()
      stop_status = 'OCTAVE_SANITY_PASS';
      scientific_authority = false;
      ledgers.decision.rows(end + 1, :) = {'runtime_authority', ...
        'IMPORTANT CAVEAT', stop_status, 1, ...
        'Octave is compatibility evidence only; MATLAB remains authoritative.'};
    else
      stop_status = 'DERIVATIVE_REFERENCE_CERTIFIED';
      scientific_authority = true;
      ledgers.decision.rows(end + 1, :) = {'runtime_authority', ...
        'MANDATORY', stop_status, 1, 'MATLAB is the scientific authority.'};
    end
  else
    scientific_authority = false;
  end
  summary = struct('status', stop_status, 'pass', all_pass, ...
    'scientific_authority', scientific_authority, ...
    'point_gate', config.gate.point, 'self_gate', config.gate.self);
end

function [rows, pass] = LOCAL_linton_reference_qualification(config)
  rows = cell(0, 17);
  pass = true;
  for j = 1:length(config.linton)
    item = config.linton(j);
    level = config.ewald.authority;
    value = LOCAL_linton_value_only( ...
      item.k, item.beta, item.d, item.X, item.Y, level);
    error_value = abs(value - item.reference);
    row_pass = error_value <= config.gate.linton;
    pass = pass && row_pass;
    rows(end + 1, :) = {item.label, 'G', 'Linton_published', NaN, ...
      NaN, real(value), imag(value), real(item.reference), ...
      imag(item.reference), error_value, config.gate.linton, row_pass, ...
      'raw', NaN, NaN, 'prerequisite', 1};
  end
end

function [values, rows, pass] = LOCAL_ewald_point_levels( ...
    config, point, components)
  rows = cell(0, 12);
  labels = config.ewald.labels;
  for il = 1:length(labels)
    label = labels{il};
    values.(label) = LOCAL_project_kernel(config, point.X, point.Y, ...
      config.ewald.(label));
  end
  values.authority = values.joint;
  pass = true;
  for ic = 1:length(components)
    component = components{ic};
    reference = values.authority.(component);
    for il = 1:length(labels)
      label = labels{il};
      level = config.ewald.(label);
      value = values.(label).(component);
      if any(strcmp(label, {'M1', 'M2', 'N'}))
        comparison = values.base.(component);
      elseif strcmp(label, 'base') || strcmp(label, 'joint')
        comparison = values.base.(component);
      else
        comparison = reference;
      end
      change = LOCAL_normalized_error(value, comparison);
      row_pass = change <= config.gate.self;
      pass = pass && row_pass;
      rows(end + 1, :) = {point.label, component, label, level.a, ...
        level.M1, level.M2, level.N, real(value), imag(value), ...
        change, config.gate.self, row_pass};
    end
    a_values = [values.a15.(component), values.joint.(component), ...
      values.a25.(component)];
    a_spread = LOCAL_pair_spread(a_values);
    a_pass = a_spread <= config.gate.self;
    pass = pass && a_pass;
    rows(end + 1, :) = {point.label, component, 'a_spread', NaN, ...
      34, 24, 36, real(reference), imag(reference), a_spread, ...
      config.gate.self, a_pass};
  end
end

function [rows, pass, fd_authority, failure_status] = LOCAL_point_oracles( ...
    config, point, components, authority)
  rows = cell(0, 17);
  fd_values = cell(1, length(config.fd_h));
  for ih = 1:length(config.fd_h)
    fd_values{ih} = LOCAL_fd_tuple(config, point.X, point.Y, ...
      config.fd_h(ih), config.ewald.authority);
  end
  richardson = cell(1, length(fd_values) - 1);
  for ir = 1:length(richardson)
    richardson{ir} = LOCAL_richardson_tuple(fd_values{ir}, ...
      fd_values{ir + 1});
  end
  fd_authority = richardson{end};
  rayleigh = cell(1, length(config.rayleigh_point_M));
  for im = 1:length(config.rayleigh_point_M)
    rayleigh{im} = LOCAL_rayleigh_point(config, point.X, point.Y, ...
      config.rayleigh_point_M(im));
  end
  pass = true;
  fd_mandatory_pass = true;
  ray_mandatory_pass = true;
  for ic = 1:length(components)
    component = components{ic};
    reference = authority.(component);
    for ih = 1:length(config.fd_h)
      value = fd_values{ih}.(component);
      error_value = LOCAL_normalized_error(value, reference);
      row_pass = error_value <= config.gate.point;
      rows(end + 1, :) = {point.label, component, 'FD_5point', ...
        NaN, config.fd_h(ih), real(value), imag(value), real(reference), ...
        imag(reference), error_value, config.gate.point, row_pass, ...
        'raw', config.fd_exponents(ih), config.fd_exponents(ih), ...
        'trend', 0};
    end
    for ir = 1:length(richardson)
      value = richardson{ir}.(component);
      error_value = LOCAL_normalized_error(value, reference);
      mandatory = ir == length(richardson);
      if ir == length(richardson)
        role = 'authority';
      elseif ir == length(richardson) - 1
        role = 'self_reference';
      else
        role = 'trend';
      end
      row_pass = error_value <= config.gate.point;
      fd_mandatory_pass = fd_mandatory_pass && (~mandatory || row_pass);
      rows(end + 1, :) = {point.label, component, 'FD_Richardson', ...
        NaN, config.fd_h(ir + 1), real(value), imag(value), ...
        real(reference), imag(reference), error_value, config.gate.point, ...
        row_pass, 'richardson', config.fd_exponents(ir), ...
        config.fd_exponents(ir + 1), role, mandatory};
    end
    fd_self = LOCAL_normalized_error(richardson{end - 1}.(component), ...
      richardson{end}.(component));
    fd_pass = fd_self <= config.gate.point;
    fd_mandatory_pass = fd_mandatory_pass && fd_pass;
    rows(end + 1, :) = {point.label, component, 'FD_R8_vs_R9', ...
      NaN, config.fd_h(end), real(richardson{end}.(component)), ...
      imag(richardson{end}.(component)), ...
      real(richardson{end - 1}.(component)), ...
      imag(richardson{end - 1}.(component)), fd_self, ...
      config.gate.point, fd_pass, 'richardson', ...
      config.fd_exponents(end - 2), config.fd_exponents(end), ...
      'self', 1};
    for im = 1:length(rayleigh)
      value = rayleigh{im}.(component);
      error_value = LOCAL_normalized_error(value, reference);
      enforced = im == length(rayleigh);
      row_pass = error_value <= config.gate.point;
      ray_mandatory_pass = ray_mandatory_pass && (~enforced || row_pass);
      rows(end + 1, :) = {point.label, component, 'Rayleigh_direct', ...
        config.rayleigh_point_M(im), NaN, real(value), imag(value), ...
        real(reference), imag(reference), error_value, ...
        config.gate.point, row_pass, 'raw', NaN, NaN, ...
        LOCAL_ternary(enforced, 'authority', 'trend'), enforced};
    end
    ray_self = LOCAL_normalized_error(rayleigh{end - 1}.(component), ...
      rayleigh{end}.(component));
    ray_pass = ray_self <= config.gate.point;
    ray_mandatory_pass = ray_mandatory_pass && ray_pass;
    rows(end + 1, :) = {point.label, component, ...
      'Rayleigh_M48_vs_M96', config.rayleigh_point_M(end), NaN, ...
      real(rayleigh{end}.(component)), imag(rayleigh{end}.(component)), ...
      real(rayleigh{end - 1}.(component)), ...
      imag(rayleigh{end - 1}.(component)), ray_self, ...
      config.gate.point, ray_pass, 'raw', NaN, NaN, 'self', 1};
  end
  pass = fd_mandatory_pass && ray_mandatory_pass;
  failure_status = '';
  if ~fd_mandatory_pass
    failure_status = 'FD_ORACLE_UNCERTIFIED';
  elseif ~ray_mandatory_pass
    failure_status = 'RAYLEIGH_ORACLE_UNCERTIFIED';
  end
end

function output = LOCAL_richardson_tuple(coarse, fine)
  names = fieldnames(coarse);
  for j = 1:length(names)
    output.(names{j}) = (16 * fine.(names{j}) - coarse.(names{j})) / 15;
  end
end

function tuple = LOCAL_fd_tuple(config, X, Y, h, level)
  if 2 * h >= abs(X)
    error('run_i4_three_path_derivatives:FDStencilClearance', ...
      'The frozen five-point stencil crosses X=0.');
  end
  offsets = -2:2;
  w1 = [1, -8, 0, 8, -1];
  w2 = [-1, 16, -30, 16, -1];
  center = LOCAL_project_value(config, X, Y, level);
  x_values = zeros(1, 5);
  y_values = zeros(1, 5);
  for j = 1:5
    x_values(j) = LOCAL_project_value(config, X + offsets(j) * h, Y, level);
    y_values(j) = LOCAL_project_value(config, X, Y + offsets(j) * h, level);
  end
  mixed = zeros(5, 5);
  for ix = 1:5
    for iy = 1:5
      mixed(ix, iy) = LOCAL_project_value(config, ...
        X + offsets(ix) * h, Y + offsets(iy) * h, level);
    end
  end
  tuple.G = center;
  tuple.Gx = sum(w1 .* x_values) / (12 * h);
  tuple.Gy = sum(w1 .* y_values) / (12 * h);
  tuple.Gxx = sum(w2 .* x_values) / (12 * h ^ 2);
  tuple.Gxy = (w1 * mixed * w1.') / (144 * h ^ 2);
  tuple.Gyx = (w1 * mixed * w1.') / (144 * h ^ 2);
  tuple.Gyy = sum(w2 .* y_values) / (12 * h ^ 2);
end

function value = LOCAL_project_value(config, X_signed, Y, level)
  if any(X_signed(:) == 0)
    error('run_i4_three_path_derivatives:ZeroTransverseSeparation', ...
      'Value-only Ewald stencil reached X=0.');
  end
  value = config.project_sign * LOCAL_linton_value_only( ...
    config.k, config.beta, config.d, abs(X_signed), Y, level);
end

function value = LOCAL_linton_value_only(k, beta, d, X, Y, level)
  X = X(:).';
  Y = Y(:).';
  m = (-level.M1:level.M1).';
  beta_m = beta + 2 * pi * m / d;
  q = LOCAL_linton_branch(k, beta_m);
  h = level.a / d;
  b = q * d / (2 * level.a);
  u_plus = bsxfun(@plus, b, h * X);
  u_minus = bsxfun(@minus, b, h * X);
  F_plus = exp(bsxfun(@times, q, X)) .* LOCAL_complex_erfc(u_plus);
  F_minus = exp(bsxfun(@times, -q, X)) .* LOCAL_complex_erfc(u_minus);
  phase = exp(1i * bsxfun(@times, beta_m, Y));
  reciprocal = -(1 / (4 * d)) * sum( ...
    bsxfun(@rdivide, phase, q) .* (F_plus + F_minus), 1);

  m = (-level.M2:level.M2).';
  image_Y = bsxfun(@minus, Y, m * d);
  z = (level.a / d) ^ 2 * bsxfun(@plus, X .^ 2, image_Y .^ 2);
  if any(z(:) == 0)
    error('run_i4_three_path_derivatives:SingularEwaldPair', ...
      'The value-only Ewald sum contains a singular image pair.');
  end
  exp_neg_z = exp(-z);
  E_np1 = expint(z);
  H = zeros(size(z));
  for n = 0:level.N
    coefficient = (k * d / (2 * level.a)) ^ (2 * n) / factorial(n);
    H = H + coefficient * E_np1;
    if n < level.N
      E_np1 = (exp_neg_z - z .* E_np1) / (n + 1);
    end
  end
  image_phase = exp(1i * beta * m * d);
  real_space = -(1 / (4 * pi)) * ...
    sum(bsxfun(@times, image_phase, H), 1);
  value = reciprocal + real_space;
end

function tuple = LOCAL_rayleigh_point(config, X_signed, Y, M)
  if X_signed == 0
    error('run_i4_three_path_derivatives:ZeroTransverseSeparation', ...
      'Rayleigh derivatives require nonzero transverse separation.');
  end
  m = (-M:M).';
  beta_m = config.beta + 2 * pi * m / config.d;
  gamma_m = LOCAL_rayleigh_branch(config.k, beta_m);
  phase = exp(1i * beta_m * Y + 1i * gamma_m * abs(X_signed));
  sx = sign(X_signed);
  tuple.G = (1i / (2 * config.d)) * sum(phase ./ gamma_m);
  tuple.Gx = -(sx / (2 * config.d)) * sum(phase);
  tuple.Gy = -(1 / (2 * config.d)) * sum((beta_m ./ gamma_m) .* phase);
  tuple.Gxx = -(1i / (2 * config.d)) * sum(gamma_m .* phase);
  tuple.Gxy = -(1i * sx / (2 * config.d)) * sum(beta_m .* phase);
  tuple.Gyy = -(1i / (2 * config.d)) * ...
    sum((beta_m .^ 2 ./ gamma_m) .* phase);
end

function [rows, pass] = LOCAL_point_identities( ...
    config, point, components, authority)
  rows = cell(0, 8);
  pass = true;
  if any(strcmp(components, 'G'))
    residual = authority.Gxx + authority.Gyy + config.k ^ 2 * authority.G;
    scale = max(1, abs(authority.Gxx) + abs(authority.Gyy) + ...
      config.k ^ 2 * abs(authority.G));
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'Helmholtz', residual, scale, config.gate.point);
  end
  if any(strcmp(components, 'Gx'))
    residual = point.X / abs(point.X) * authority.GX_abs - authority.Gx;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'signed_Gx=sx_GX_abs', residual, max(1, abs(authority.Gx)), ...
      config.gate.point);
    source_fd = LOCAL_source_fd_authority(config, point.X, point.Y, ...
      config.ewald.authority);
    residual = source_fd.Gxs + authority.Gx;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'grad_source_x=-grad_target_x', residual, 1, config.gate.point);
    residual = source_fd.Gys + authority.Gy;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'grad_source_y=-grad_target_y', residual, 1, config.gate.point);
    nt = sign(point.X);
    residual = nt * authority.Gx - authority.GX_abs;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'wall_ntx_Gx=GX_abs', residual, max(1, abs(authority.GX_abs)), ...
      config.gate.point);
  end
  if any(strcmp(components, 'Gxy'))
    residual = point.X / abs(point.X) * authority.GXY_abs - authority.Gxy;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'signed_Gxy=sx_GXY_abs', residual, max(1, abs(authority.Gxy)), ...
      config.gate.point);
    mixed_order = LOCAL_mixed_order_authority(config, point.X, point.Y, ...
      config.ewald.authority);
    residual = authority.Gxy - mixed_order.d_y_Gx;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'Gxy_equals_d_y_Gx', residual, max(1, abs(authority.Gxy)), ...
      config.gate.point);
    residual = authority.Gxy - mixed_order.d_x_Gy;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'Gxy_equals_d_x_Gy', residual, max(1, abs(authority.Gxy)), ...
      config.gate.point);
    residual = mixed_order.d_y_Gx - mixed_order.d_x_Gy;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'mixed_order_symmetry', residual, max(1, abs(authority.Gxy)), ...
      config.gate.point);
    source_fd = LOCAL_source_fd_authority(config, point.X, point.Y, ...
      config.ewald.authority);
    residual = source_fd.Hxtxs + authority.Gxx;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'Hts_xx=-Htt_xx', residual, 1, config.gate.point);
    residual = source_fd.Hxtys + authority.Gxy;
    [rows, pass] = LOCAL_add_identity(rows, pass, point.label, ...
      'Hts_xy=-Htt_xy', residual, 1, config.gate.point);
  end
end

function authority = LOCAL_source_fd_authority(config, X, Y, level)
  raw = cell(1, length(config.fd_h));
  for ih = 1:length(config.fd_h)
    raw{ih} = LOCAL_source_fd_tuple(config, X, Y, config.fd_h(ih), level);
  end
  richardson = cell(1, length(raw) - 1);
  for ir = 1:length(richardson)
    richardson{ir} = LOCAL_richardson_tuple(raw{ir}, raw{ir + 1});
  end
  authority = richardson{end};
end

function tuple = LOCAL_source_fd_tuple(config, X, Y, h, level)
  if 4 * h >= abs(X)
    error('run_i4_three_path_derivatives:SourceFDStencilClearance', ...
      'The target/source mixed stencil crosses X=0.');
  end
  offsets = -2:2;
  w1 = [1, -8, 0, 8, -1];
  source_x = zeros(1, 5);
  source_y = zeros(1, 5);
  mixed_xx = zeros(5, 5);
  mixed_xy = zeros(5, 5);
  for js = 1:5
    source_x(js) = LOCAL_project_value(config, ...
      X - offsets(js) * h, Y, level);
    source_y(js) = LOCAL_project_value(config, ...
      X, Y - offsets(js) * h, level);
    for it = 1:5
      mixed_xx(it, js) = LOCAL_project_value(config, ...
        X + offsets(it) * h - offsets(js) * h, Y, level);
      mixed_xy(it, js) = LOCAL_project_value(config, ...
        X + offsets(it) * h, Y - offsets(js) * h, level);
    end
  end
  tuple.Gxs = sum(w1 .* source_x) / (12 * h);
  tuple.Gys = sum(w1 .* source_y) / (12 * h);
  tuple.Hxtxs = (w1 * mixed_xx * w1.') / (144 * h ^ 2);
  tuple.Hxtys = (w1 * mixed_xy * w1.') / (144 * h ^ 2);
end

function authority = LOCAL_mixed_order_authority(config, X, Y, level)
  raw = cell(1, length(config.fd_h));
  offsets = -2:2;
  w1 = [1, -8, 0, 8, -1];
  for ih = 1:length(config.fd_h)
    h = config.fd_h(ih);
    Gx_y = zeros(1, 5);
    Gy_x = zeros(1, 5);
    for j = 1:5
      K_y = LOCAL_project_kernel(config, X, Y + offsets(j) * h, level);
      K_x = LOCAL_project_kernel(config, X + offsets(j) * h, Y, level);
      Gx_y(j) = K_y.Gx;
      Gy_x(j) = K_x.Gy;
    end
    raw{ih}.d_y_Gx = sum(w1 .* Gx_y) / (12 * h);
    raw{ih}.d_x_Gy = sum(w1 .* Gy_x) / (12 * h);
  end
  richardson = cell(1, length(raw) - 1);
  for ir = 1:length(richardson)
    richardson{ir} = LOCAL_richardson_tuple(raw{ir}, raw{ir + 1});
  end
  authority = richardson{end};
end

function [rows, pass] = LOCAL_add_identity( ...
    rows, pass, point, name, residual, scale, gate)
  normalized = abs(residual) / max(1, scale);
  row_pass = normalized <= gate;
  pass = pass && row_pass;
  rows(end + 1, :) = {point, name, real(residual), imag(residual), ...
    scale, normalized, gate, row_pass};
end

function [rows, pass] = LOCAL_projection_qualification(config)
  M = 3;
  channels = LOCAL_channels(config, M);
  y = config.d * (0:255) / 256;
  expected = (1:M * 2 + 1).' .* exp(1i * (0:M * 2).' / 7) / 10;
  basis = (1 / sqrt(config.d)) * exp(1i * channels.beta_m * y);
  D_values = expected.' * basis;
  N_expected = (1i * channels.gamma_m) .* expected;
  N_values = N_expected.' * basis;
  D_observed = LOCAL_fourier_project(config.d, channels.beta_m, y, D_values);
  N_observed = LOCAL_fourier_project(config.d, channels.beta_m, y, N_values);
  rows = cell(0, 10);
  pass = true;
  traces = {'D', 'N_raw'};
  observations = {D_observed, N_observed};
  expectations = {expected, N_expected};
  for it = 1:2
    for im = 1:length(channels.m)
      error_value = abs(observations{it}(im) - expectations{it}(im));
      row_pass = error_value <= config.gate.projection;
      pass = pass && row_pass;
      rows(end + 1, :) = {traces{it}, channels.m(im), ...
        real(expectations{it}(im)), imag(expectations{it}(im)), ...
        real(observations{it}(im)), imag(observations{it}(im)), ...
        error_value, config.gate.projection, row_pass, ...
        'raw N oracle is (i*gamma_m)*D'};
    end
  end
end

function [rows, pass] = LOCAL_mutation_qualification(config)
  point = config.points(end);
  K = LOCAL_project_kernel(config, point.X, point.Y, config.ewald.authority);
  R = LOCAL_rayleigh_point(config, point.X, point.Y, ...
    config.rayleigh_point_M(end));
  mutations = { ...
    'wrong_project_sign', 'G', abs(-K.G - R.G), ...
      'opposite global sign'; ...
    'missing_signed_Gx', 'Gx', abs(K.GX_abs - R.Gx), ...
      'negative-DX holdout kills missing sx'; ...
    'missing_signed_Gxy', 'Gxy', abs(K.GXY_abs - R.Gxy), ...
      'negative-DX holdout kills missing sx'; ...
    'left_wall_normal_flip', 'Gx', 2 * abs(K.GX_abs), ...
      'outward wall normal is mandatory'; ...
    'source_normal_sign', 'Gx', 2 * abs(K.Gx), ...
      'source gradient must be minus target gradient'; ...
    'normalized_as_raw_N', 'N_raw', abs((1i * 1.3 - 1) * K.G), ...
      'raw Neumann must retain i*gamma scaling'};
  rows = cell(0, 8);
  pass = true;
  for j = 1:size(mutations, 1)
    error_value = mutations{j, 3};
    failed = error_value > config.gate.point;
    pass = pass && failed;
    rows(end + 1, :) = {mutations{j, 1}, point.label, ...
      mutations{j, 2}, error_value, config.gate.point, 1, failed, ...
      mutations{j, 4}};
  end
end

function value = LOCAL_pair_spread(values)
  value = 0;
  for i = 1:length(values)
    for j = i + 1:length(values)
      value = max(value, LOCAL_normalized_error(values(i), values(j)));
    end
  end
end

function value = LOCAL_normalized_error(a, b)
  value = max(abs(a(:) - b(:)) ./ max(1, abs(b(:))));
end

function status = LOCAL_pass_status(pass, pass_status, fail_status)
  if pass
    status = pass_status;
  else
    status = fail_status;
  end
end

function value = LOCAL_ternary(condition, true_value, false_value)
  if condition
    value = true_value;
  else
    value = false_value;
  end
end

%% ==================== Four wall actions ====================
% These helpers assemble raw D/N actions from one kernel tuple per wall.

function [summary, ledgers] = LOCAL_pilot( ...
    config, ledgers, log_fid, output_dir, qualification)
  [p_ok, p_note, p_signature] = LOCAL_p_provenance_gate(config);
  ledgers = LOCAL_append_p_signature(ledgers, p_signature, p_ok, p_note);
  if ~p_ok
    status = 'MFS_SOLVER_PROVENANCE_BLOCKER';
    ledgers.decision.rows(end + 1, :) = {'P_preflight', 'BLOCKER', ...
      status, 0, p_note};
    summary = struct('status', status, 'pass', false, ...
      'qualification', qualification, 'stop_after', 'P_preflight');
    return;
  end
  [point_gate, ledgers] = LOCAL_package_point_qualification( ...
    config, ledgers, log_fid, p_signature);
  token = tic;
  [data, wall_rows, timing_rows] = LOCAL_wall_level(config, ...
    config.pilot.ntot, config.pilot.Ny, config.pilot.M, ...
    config.ewald.authority, config.proxy.base, 'pilot', log_fid, ...
    'all', p_signature);
  ledgers.timings.rows = [ledgers.timings.rows; timing_rows];
  elapsed = toc(token);
  [stage, ledgers] = LOCAL_stage_actions(config, ledgers, data, ...
    'pilot', wall_rows, false, point_gate);
  estimate = LOCAL_runtime_estimate(config, elapsed);
  LOCAL_write_runtime_estimate(output_dir, estimate);
  if stage.pass
    status = 'PILOT_ALL_ACTIONS_CERTIFIED';
  else
    status = ['PILOT_', LOCAL_status_token(stage.failed_action), ...
      '_UNCERTIFIED'];
  end
  summary = struct('status', status, 'pass', stage.pass, ...
    'qualification', qualification, 'stage', stage, ...
    'runtime_estimate', estimate);
end

function [summary, ledgers] = LOCAL_full(config, ledgers, log_fid, qualification)
  [p_ok, p_note, p_signature] = LOCAL_p_provenance_gate(config);
  ledgers = LOCAL_append_p_signature(ledgers, p_signature, p_ok, p_note);
  if ~p_ok
    status = 'MFS_SOLVER_PROVENANCE_BLOCKER';
    ledgers.decision.rows(end + 1, :) = {'P_preflight', 'BLOCKER', ...
      status, 0, p_note};
    summary = struct('status', status, 'pass', false, ...
      'qualification', qualification, 'stop_after', 'P_preflight');
    return;
  end
  [point_gate, ledgers] = LOCAL_package_point_qualification( ...
    config, ledgers, log_fid, p_signature);
  ntot_hi = config.full.ntot(end);
  Ny_hi = config.full.Ny(end);
  M_hi = config.full.M(end);
  [authority, wall_rows, timing_rows] = LOCAL_wall_level(config, ...
    ntot_hi, Ny_hi, M_hi, config.ewald.authority, config.proxy.base, ...
    'authority', log_fid, 'all', p_signature);
  ledgers.timings.rows = [ledgers.timings.rows; timing_rows];

  refinements = struct('label', {}, 'path', {}, 'data', {}, ...
    'reference_data', {}, 'enforced', {});
  [data, ~, timing_rows] = LOCAL_wall_level(config, config.full.ntot(1), ...
    Ny_hi, M_hi, config.ewald.authority, config.proxy.base, ...
    'ntot128', log_fid, 'all', p_signature);
  ledgers.timings.rows = [ledgers.timings.rows; timing_rows];
  refinements(end + 1) = struct('label', 'ntot128_to_256', ...
    'path', 'all', 'data', data, 'reference_data', authority, ...
    'enforced', true);
  [data, ~, timing_rows] = LOCAL_wall_level(config, ntot_hi, ...
    config.full.Ny(1), M_hi, config.ewald.authority, config.proxy.base, ...
    'Ny256', log_fid, 'all', p_signature);
  ledgers.timings.rows = [ledgers.timings.rows; timing_rows];
  refinements(end + 1) = struct('label', 'Ny256_to_512', ...
    'path', 'all', 'data', data, 'reference_data', authority, ...
    'enforced', true);
  [data, ~, timing_rows] = LOCAL_wall_level(config, ntot_hi, Ny_hi, ...
    config.full.M(1), config.ewald.authority, config.proxy.base, ...
    'M24', log_fid, 'R', p_signature);
  ledgers.timings.rows = [ledgers.timings.rows; timing_rows];
  refinements(end + 1) = struct( ...
    'label', 'Rayleigh_common_modes_structural', ...
    'path', 'R', 'data', data, 'reference_data', authority, ...
    'enforced', false);

  ewald_labels = config.ewald.labels;
  ewald_data = struct();
  for il = 1:length(ewald_labels)
    label = ewald_labels{il};
    if strcmp(label, 'joint')
      continue;
    end
    [data, ~, timing_rows] = LOCAL_wall_level(config, ntot_hi, Ny_hi, ...
      M_hi, config.ewald.(label), config.proxy.base, ...
      ['E_', label], log_fid, 'E', p_signature);
    ledgers.timings.rows = [ledgers.timings.rows; timing_rows];
    ewald_data.(label) = data;
  end
  refinements(end + 1) = struct('label', 'E_base_to_joint', ...
    'path', 'E', 'data', ewald_data.base, ...
    'reference_data', authority, 'enforced', false);
  for label_cell = {'M1', 'M2', 'N'}
    label = label_cell{1};
    refinements(end + 1) = struct('label', ['E_base_to_', label], ...
      'path', 'E', 'data', ewald_data.(label), ...
      'reference_data', ewald_data.base, 'enforced', true);
  end
  refinements(end + 1) = struct('label', 'E_joint_a15_to_a2', ...
    'path', 'E', 'data', ewald_data.a15, ...
    'reference_data', authority, 'enforced', true);
  refinements(end + 1) = struct('label', 'E_joint_a25_to_a2', ...
    'path', 'E', 'data', ewald_data.a25, ...
    'reference_data', authority, 'enforced', true);
  refinements(end + 1) = struct('label', 'E_joint_a15_to_a25', ...
    'path', 'E', 'data', ewald_data.a15, ...
    'reference_data', ewald_data.a25, 'enforced', true);
  proxy_labels = config.proxy.labels;
  for il = 2:length(proxy_labels)
    label = proxy_labels{il};
    [data, ~, timing_rows] = LOCAL_wall_level(config, ntot_hi, Ny_hi, ...
      M_hi, config.ewald.authority, config.proxy.(label), ...
      ['P_', label], log_fid, 'P', p_signature);
    ledgers.timings.rows = [ledgers.timings.rows; timing_rows];
    refinements(end + 1) = struct('label', ['P_', label, '_to_base'], ...
      'path', 'P', 'data', data, 'reference_data', authority, ...
      'enforced', true);
  end

  [stage, ledgers] = LOCAL_stage_actions(config, ledgers, authority, ...
    'authority', wall_rows, true, point_gate, refinements);
  if stage.pass
    status = 'ALL_FOUR_ACTIONS_CERTIFIED';
  else
    status = [LOCAL_status_token(stage.failed_action), '_UNCERTIFIED'];
  end
  summary = struct('status', status, 'pass', stage.pass, ...
    'qualification', qualification, 'stage', stage);
end

function [point_gate, ledgers] = LOCAL_package_point_qualification( ...
    config, ledgers, log_fid, expected_p_signature)
  [p_ok, p_note, p_signature] = LOCAL_p_provenance_gate(config);
  if ~p_ok || ~strcmp(p_signature.signature, expected_p_signature.signature)
    ledgers.decision.rows(end + 1, :) = {'P_point_kernel', 'BLOCKER', ...
      'MFS_SOLVER_PROVENANCE_BLOCKER', 0, p_note};
    point_gate = struct('provenance_pass', false);
    return;
  end
  pars1 = struct('k', config.k, 'beta', config.beta, 'd', config.d, ...
    'periodic_axis', 'y');
  token = tic;
  proxy = kernel.precomp_proxy(pars1, config.proxy.base);
  ledgers.timings.rows(end + 1, :) = {'P_point_precomp', toc(token), ...
    p_signature.signature};
  source = [0; 0];
  target = [[config.points.X]; [config.points.Y]];
  token = tic;
  [G, Gx, Gy, Gxx, Gxy, Gyy] = kernel.qpgreen_mfs_pairmat( ...
    source, target, pars1, proxy);
  ledgers.timings.rows(end + 1, :) = {'P_point_evaluation', toc(token), ...
    'package physical target gradient and Hessian'};
  observed = struct('G', G, 'Gx', Gx, 'Gy', Gy, ...
    'Gxx', Gxx, 'Gxy', Gxy, 'Gyy', Gyy);
  components = config.components;
  point_gate = struct('provenance_pass', true);
  for ic = 1:length(components)
    point_gate.(components{ic}) = true;
    point_gate.([components{ic}, '_max_error']) = 0;
  end
  for ip = 1:length(config.points)
    point = config.points(ip);
    reference = LOCAL_project_kernel(config, point.X, point.Y, ...
      config.ewald.authority);
    for ic = 1:length(config.components)
      component = config.components{ic};
      value = observed.(component)(ip);
      expected = reference.(component);
      error_value = LOCAL_normalized_error(value, expected);
      row_pass = error_value <= config.gate.point;
      point_gate.(component) = point_gate.(component) && row_pass;
      point_gate.([component, '_max_error']) = max( ...
        point_gate.([component, '_max_error']), error_value);
      ledgers.point_oracle.rows(end + 1, :) = {point.label, component, ...
        'Package_MFS', NaN, NaN, real(value), imag(value), ...
        real(expected), imag(expected), error_value, config.gate.point, ...
        row_pass, 'raw', NaN, NaN, 'P_point_component', 0};
    end
  end
  ledgers.decision.rows(end + 1, :) = {'P_point_kernel', 'DIAGNOSTIC', ...
    'P_POINT_COMPONENTS_RECORDED', 1, ...
    'No global gate; each wall action consumes only its required components.'};
  ledgers.decision.rows(end + 1, :) = {'P_Gyy', 'IMPORTANT', ...
    LOCAL_pass_status(point_gate.Gyy, 'P_Gyy_DIAGNOSTIC_WITHIN_GATE', ...
    'P_Gyy_DIAGNOSTIC_OUTSIDE_GATE'), point_gate.Gyy, ...
    'Gyy is retained for diagnosis and is not a wall-action prerequisite.'};
  LOCAL_log(log_fid, ['P point components G=%d Gx=%d Gy=%d ', ...
    'Gxx=%d Gxy=%d Gyy=%d\n'], point_gate.G, point_gate.Gx, ...
    point_gate.Gy, point_gate.Gxx, point_gate.Gxy, point_gate.Gyy);
end

function [stage, ledgers] = LOCAL_stage_actions( ...
    config, ledgers, authority, level_label, wall_rows, enforce_self, ...
    point_gate, refinements)
  if nargin < 8
    refinements = struct('label', {}, 'path', {}, 'data', {}, ...
      'reference_data', {}, 'enforced', {});
  end
  stage.pass = true;
  stage.failed_action = '';
  stage.pairwise = struct();
  for ia = 1:length(config.actions)
    action = config.actions{ia};
    [point_pass, point_note] = LOCAL_action_point_prerequisite( ...
      action, point_gate);
    token = LOCAL_status_token(action);
    ledgers.decision.rows(end + 1, :) = {[action, '_P_point'], ...
      'MANDATORY', LOCAL_pass_status(point_pass, ...
      [token, '_P_POINT_CERTIFIED'], [token, '_P_POINT_UNCERTIFIED']), ...
      point_pass, point_note};
    if ~point_pass
      stage.pass = false;
      stage.failed_action = action;
      ledgers.decision.rows(end + 1, :) = {action, 'MANDATORY', ...
        [token, '_UNCERTIFIED'], 0, ...
        'Stopped before this action wall/refinement/coefficient rows.'};
      for later = ia + 1:length(config.actions)
        ledgers.decision.rows(end + 1, :) = {config.actions{later}, ...
          'MANDATORY', 'NOT_RUN_PREREQUISITE', 0, ...
          ['Stopped at ', action, ' point prerequisite.']};
      end
      break;
    end
    self_pass = true;
    if enforce_self
      for ir = 1:length(refinements)
        path_names = LOCAL_refinement_paths(refinements(ir).path);
        for ip = 1:length(path_names)
          path = path_names{ip};
          change = LOCAL_action_path_change(config, ...
            refinements(ir).reference_data, refinements(ir).data, ...
            action, path);
          if refinements(ir).enforced
            gate = config.gate.self;
            row_pass = change <= gate;
            self_pass = self_pass && row_pass;
          else
            gate = NaN;
            row_pass = true;
          end
          level = refinements(ir).data;
          ledgers.action_level.rows(end + 1, :) = {action, path, ...
            refinements(ir).label, level.ntot, level.Ny, level.M, ...
            level.ewald_level.a, level.ewald_level.M1, ...
            level.ewald_level.M2, level.ewald_level.N, change, ...
            gate, row_pass, refinements(ir).enforced};
        end
      end
    end
    if enforce_self
      for path_cell = {'E', 'P', 'R'}
        path = path_cell{1};
        tail = LOCAL_action_tail(config, authority, action, path, 24);
        tail_pass = tail <= config.gate.self;
        self_pass = self_pass && tail_pass;
        ledgers.action_level.rows(end + 1, :) = {action, path, ...
          'output_tail_24_lt_abs_m_le_48', authority.ntot, authority.Ny, ...
          authority.M, authority.ewald_level.a, authority.ewald_level.M1, ...
          authority.ewald_level.M2, authority.ewald_level.N, tail, ...
          config.gate.self, tail_pass, 1};
      end
    end
    [pairwise, pair_pass] = LOCAL_action_pairwise(config, authority, action);
    ledgers = LOCAL_append_action_coefficients(config, ledgers, ...
      authority, action, level_label, true);
    action_pass = self_pass && pair_pass;
    stage.pairwise.(token) = pairwise;
    ledgers.decision.rows(end + 1, :) = {action, 'MANDATORY', ...
      LOCAL_pass_status(action_pass, [token, '_CERTIFIED'], ...
      [token, '_UNCERTIFIED']), action_pass, ...
      'Raw D/N coefficient pairs plus all enabled self-refinements.'};
    action_rows = wall_rows(strcmp(wall_rows(:, 3), action), :);
    ledgers.wall_point.rows = [ledgers.wall_point.rows; action_rows];
    if ~action_pass
      stage.pass = false;
      stage.failed_action = action;
      for later = ia + 1:length(config.actions)
        ledgers.decision.rows(end + 1, :) = {config.actions{later}, ...
          'MANDATORY', 'NOT_RUN_PREREQUISITE', 0, ...
          ['Stopped after ', action, ' failure; no coefficient rows emitted.']};
      end
      break;
    end
  end
end

function paths = LOCAL_refinement_paths(selector)
  if strcmp(selector, 'all')
    paths = {'E', 'P', 'R'};
  else
    paths = {selector};
  end
end

function [pass, note] = LOCAL_action_point_prerequisite(action, point_gate)
  if ~isfield(point_gate, 'provenance_pass') || ...
      ~point_gate.provenance_pass
    pass = false;
    note = 'Package provenance changed before point evaluation.';
    return;
  end
  if strcmp(action, 'SLP-D')
    required = {'G'};
  elseif strcmp(action, 'SLP-N')
    required = {'Gx'};
  elseif strcmp(action, 'DLP-D')
    required = {'Gx', 'Gy'};
  elseif strcmp(action, 'DLP-N')
    required = {'Gxx', 'Gxy'};
  else
    error('run_i4_three_path_derivatives:UnknownAction', ...
      'Unknown action %s.', action);
  end
  pass = true;
  pieces = cell(1, length(required));
  for j = 1:length(required)
    component = required{j};
    pass = pass && point_gate.(component);
    pieces{j} = sprintf('%s max_error=%.3e pass=%d', component, ...
      point_gate.([component, '_max_error']), point_gate.(component));
  end
  note = pieces{1};
  for j = 2:length(pieces)
    note = [note, '; ', pieces{j}];
  end
end

function [data, wall_rows, timing_rows] = LOCAL_wall_level( ...
    config, ntot, Ny, M, ewald_level, proxy_level, level_label, ...
    log_fid, path_selector, expected_p_signature)
  run_E = strcmp(path_selector, 'all') || strcmp(path_selector, 'E');
  run_P = strcmp(path_selector, 'all') || strcmp(path_selector, 'P');
  run_R = strcmp(path_selector, 'all') || strcmp(path_selector, 'R');
  [circle, source, weights] = LOCAL_circle_geometry(config, ntot);
  y_wall = config.d * (0:Ny - 1) / Ny;
  targets = {[config.X_L * ones(1, Ny); y_wall], ...
    [config.X_R * ones(1, Ny); y_wall]};
  sides = {'L', 'R'};
  normals = [-1, 1];
  channels = LOCAL_channels(config, M);
  pars1 = struct('k', config.k, 'beta', config.beta, 'd', config.d, ...
    'periodic_axis', 'y');
  timing_rows = cell(0, 3);
  if run_P
    [p_ok, p_note, p_signature] = LOCAL_p_provenance_gate(config);
    if ~p_ok || ~strcmp(p_signature.signature, expected_p_signature.signature)
      error('run_i4_three_path_derivatives:MFSProvenanceChanged', ...
        'P provenance failed or changed before precomp: %s', p_note);
    end
    token = tic;
    proxy = kernel.precomp_proxy(pars1, proxy_level);
    timing_rows(end + 1, :) = {['P_precomp_', level_label], toc(token), ...
      p_signature.signature};
  end
  E = cell(1, 2);
  P = cell(1, 2);
  F = cell(1, 2);
  if run_R
    [F{1}, F{2}] = bloch.farfield_extractors(circle, channels, ...
      config.X_L, config.X_R, 2 * pi);
  end
  for is = 1:2
    if run_E
      token = tic;
      E{is} = LOCAL_ewald_pair_matrices(config, source, targets{is}, ...
        circle.nx, circle.ny, normals(is), ewald_level);
      timing_rows(end + 1, :) = {['E_wall_', level_label, '_', sides{is}], ...
        toc(token), sprintf('%d pairs, six analytic fields', ntot * Ny)};
    end
    if run_P
      token = tic;
      [G, Gx, Gy, Gxx, Gxy, ~] = kernel.qpgreen_mfs_pairmat( ...
        source, targets{is}, pars1, proxy);
      P{is} = LOCAL_action_matrices(G, Gx, Gy, Gxx, Gxy, ...
        circle.nx, circle.ny, normals(is));
      timing_rows(end + 1, :) = {['P_wall_', level_label, '_', sides{is}], ...
        toc(token), sprintf('%d package pair evaluations', ntot * Ny)};
    end
  end
  wall_rows = cell(0, 13);
  for ia = 1:length(config.actions)
    action = config.actions{ia};
    field = LOCAL_action_field(action);
    is_N = action(end) == 'N';
    layer = action(1:3);
    for id = 1:length(config.density)
      density_label = config.density(id).label;
      rho = LOCAL_density_values(config.density(id), ntot);
      weighted = rho .* weights;
      if strcmp(layer, 'SLP')
        eta = [zeros(ntot, 1); rho];
      else
        eta = [rho; zeros(ntot, 1)];
      end
      for is = 1:2
        side = sides{is};
        if run_E
          E_wall = E{is}.(field) * weighted;
          data.(field).(density_label).(side).E = ...
            LOCAL_fourier_project(config.d, channels.beta_m, ...
            y_wall, E_wall.');
          data.(field).(density_label).(side).E_wall = E_wall;
        end
        if run_P
          P_wall = P{is}.(field) * weighted;
          data.(field).(density_label).(side).P = ...
            LOCAL_fourier_project(config.d, channels.beta_m, ...
            y_wall, P_wall.');
          data.(field).(density_label).(side).P_wall = P_wall;
        end
        if run_R
          D_coeff = F{is} * eta;
          if is_N
            R_coeff = (1i * channels.gamma_m) .* D_coeff;
          else
            R_coeff = D_coeff;
          end
          data.(field).(density_label).(side).R = R_coeff;
        end
        if run_E && run_P
          for jy = 1:Ny
            wall_rows(end + 1, :) = {level_label, density_label, ...
              action, side, jy, y_wall(jy), real(E_wall(jy)), ...
              imag(E_wall(jy)), real(P_wall(jy)), imag(P_wall(jy)), ...
              abs(E_wall(jy) - P_wall(jy)), ntot, Ny};
          end
        end
      end
    end
  end
  data.channels = channels;
  data.ntot = ntot;
  data.Ny = Ny;
  data.M = M;
  data.ewald_level = ewald_level;
  data.proxy_level = proxy_level;
end

function matrices = LOCAL_ewald_pair_matrices( ...
    config, source, target, nsx, nsy, ntx, level)
  nt = size(target, 2);
  ns = size(source, 2);
  DX = target(1, :).'- source(1, :);
  DY = target(2, :).'- source(2, :);
  if any(DX(:) == 0)
    error('run_i4_three_path_derivatives:WallZeroSeparation', ...
      'A wall-source pair has dx=0.');
  end
  names = {'G', 'Gx', 'Gy', 'Gxx', 'Gxy'};
  for j = 1:length(names)
    tuple.(names{j}) = zeros(nt, ns);
  end
  total = nt * ns;
  for first = 1:config.chunk_size:total
    last = min(total, first + config.chunk_size - 1);
    index = first:last;
    K = LOCAL_project_kernel(config, DX(index), DY(index), level);
    for j = 1:length(names)
      temporary = tuple.(names{j});
      temporary(index) = K.(names{j});
      tuple.(names{j}) = temporary;
    end
  end
  matrices = LOCAL_action_matrices(tuple.G, tuple.Gx, tuple.Gy, ...
    tuple.Gxx, tuple.Gxy, nsx, nsy, ntx);
end

function matrices = LOCAL_action_matrices( ...
    G, Gx, Gy, Gxx, Gxy, nsx, nsy, ntx)
  source_normal = -(bsxfun(@times, Gx, nsx(:).') + ...
    bsxfun(@times, Gy, nsy(:).'));
  target_normal = ntx * Gx;
  mixed_normal = ntx * (-(bsxfun(@times, Gxx, nsx(:).') + ...
    bsxfun(@times, Gxy, nsy(:).')));
  matrices.SLP_D = -G;
  matrices.SLP_N = -target_normal;
  matrices.DLP_D = source_normal;
  matrices.DLP_N = mixed_normal;
end

function field = LOCAL_action_field(action)
  field = strrep(action, '-', '_');
end

function change = LOCAL_action_path_change(config, authority, other, action, path)
  field = LOCAL_action_field(action);
  change = 0;
  for id = 1:length(config.density)
    density_label = config.density(id).label;
    for side_cell = {'L', 'R'}
      side = side_cell{1};
      if ~isfield(other.(field).(density_label).(side), path)
        continue;
      end
      a = authority.(field).(density_label).(side).(path);
      b = other.(field).(density_label).(side).(path);
      common = intersect(authority.channels.m, other.channels.m);
      for im = 1:length(common)
        ia = find(authority.channels.m == common(im), 1);
        ib = find(other.channels.m == common(im), 1);
        change = max(change, abs(a(ia) - b(ib)));
      end
    end
  end
end

function tail = LOCAL_action_tail(config, data, action, path, cutoff)
  field = LOCAL_action_field(action);
  band = abs(data.channels.m) > cutoff & ...
    abs(data.channels.m) <= data.M;
  if ~any(band)
    error('run_i4_three_path_derivatives:EmptyTailBand', ...
      'The mandatory output-tail band is empty.');
  end
  tail = 0;
  for id = 1:length(config.density)
    density_label = config.density(id).label;
    for side_cell = {'L', 'R'}
      side = side_cell{1};
      value = data.(field).(density_label).(side).(path);
      tail = max(tail, max(abs(value(band))));
    end
  end
end

function [errors, pass] = LOCAL_action_pairwise(config, data, action)
  field = LOCAL_action_field(action);
  pairs = {'E', 'P'; 'E', 'R'; 'P', 'R'};
  errors = zeros(1, 3);
  for ip = 1:3
    for id = 1:length(config.density)
      density_label = config.density(id).label;
      for side_cell = {'L', 'R'}
        side = side_cell{1};
        a = data.(field).(density_label).(side).(pairs{ip, 1});
        b = data.(field).(density_label).(side).(pairs{ip, 2});
        errors(ip) = max(errors(ip), max(abs(a(:) - b(:))));
      end
    end
  end
  pass = all(errors <= config.gate.coefficient);
end

function ledgers = LOCAL_append_action_coefficients( ...
    config, ledgers, data, action, level_label, enforced)
  field = LOCAL_action_field(action);
  layer = action(1:3);
  trace = action(end);
  pairs = {'E', 'P'; 'E', 'R'; 'P', 'R'};
  for id = 1:length(config.density)
    density_label = config.density(id).label;
    for side_cell = {'L', 'R'}
      side = side_cell{1};
      for im = 1:length(data.channels.m)
        for ip = 1:3
          left_path = pairs{ip, 1};
          right_path = pairs{ip, 2};
          left = data.(field).(density_label).(side).(left_path)(im);
          right = data.(field).(density_label).(side).(right_path)(im);
          error_value = abs(left - right);
          pass = error_value <= config.gate.coefficient;
          ledgers.coefficient.rows(end + 1, :) = {level_label, ...
            density_label, layer, side, trace, data.channels.m(im), ...
            left_path, right_path, real(left), imag(left), real(right), ...
            imag(right), error_value, config.gate.coefficient, pass, ...
            enforced, 'raw'};
        end
        if trace == 'N'
          gamma = data.channels.gamma_m(im);
          if abs(gamma) > 0
            raw = data.(field).(density_label).(side).R(im);
            normalized = raw / (1i * gamma);
            ledgers.coefficient.rows(end + 1, :) = {level_label, ...
              density_label, layer, side, trace, data.channels.m(im), ...
              'R_raw', 'R_normalized_supplemental', real(raw), imag(raw), ...
              real(normalized), imag(normalized), NaN, ...
              config.gate.coefficient, 1, 0, 'supplemental_only'};
          end
        end
      end
    end
  end
end

function [circle, source, weights] = LOCAL_circle_geometry(config, ntot)
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  x = config.R * cos(theta);
  y = config.R * sin(theta);
  circle = struct('x', x, 'y', y, ...
    'dxdt', -config.R * sin(theta), 'dydt', config.R * cos(theta), ...
    'speed', config.R * ones(ntot, 1), 'nx', cos(theta), ...
    'ny', sin(theta));
  source = [x.'; y.'];
  weights = (2 * pi / ntot) * config.R * ones(ntot, 1);
end

function density = LOCAL_density_values(density_config, ntot)
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  density = zeros(ntot, 1);
  for j = 1:length(density_config.ell)
    density = density + density_config.coeff(j) * ...
      exp(1i * density_config.ell(j) * theta);
  end
end

function channels = LOCAL_channels(config, M)
  channels.m = (-M:M).';
  channels.beta_m = config.beta + 2 * pi * channels.m / config.d;
  channels.gamma_m = LOCAL_rayleigh_branch(config.k, channels.beta_m);
  channels.d = config.d;
  channels.K = length(channels.m);
end

function gamma = LOCAL_rayleigh_branch(k, beta_m)
  gamma = sqrt(complex(k ^ 2 - beta_m .^ 2));
  flip = imag(gamma) < 0 | (imag(gamma) == 0 & real(gamma) < 0);
  gamma(flip) = -gamma(flip);
end

function coeff = LOCAL_fourier_project(d, beta_m, y, values)
  psi_conjugate = (1 / sqrt(d)) * exp(-1i * (beta_m(:) * y));
  coeff = (d / length(y)) * psi_conjugate * values(:);
end

function token = LOCAL_status_token(action)
  token = strrep(action, '-', '_');
end

%% ==================== Provenance and artifacts ====================
% These helpers make every backend choice and scientific row auditable.

function provenance = LOCAL_provenance()
  provenance.runtime_kind = 'MATLAB';
  if LOCAL_is_octave()
    provenance.runtime_kind = 'Octave';
  end
  provenance.version = version;
  provenance.release = '';
  if ~LOCAL_is_octave()
    try
      provenance.release = version('-release');
    catch
      provenance.release = 'unavailable';
    end
  end
  provenance.computer = computer;
  provenance.arch = computer('arch');
  provenance.Faddeeva_erfc = which('Faddeeva_erfc');
  provenance.mexext = mexext;
  provenance.Faddeeva_is_mex = LOCAL_path_has_extension( ...
    provenance.Faddeeva_erfc, ['.', provenance.mexext]);
  provenance.erfc = which('erfc');
  provenance.expint = which('expint');
  provenance.lsqminnorm_exist = exist('lsqminnorm', 'file');
  provenance.lsqminnorm = which('lsqminnorm');
  provenance.pinv = which('pinv');
  provenance.precomp_proxy = which('kernel.precomp_proxy');
  provenance.qpgreen_mfs_pairmat = which('kernel.qpgreen_mfs_pairmat');
  provenance.farfield_extractors = which('bloch.farfield_extractors');
  provenance.scientific_authority = ~LOCAL_is_octave();
  provenance.erfc_backend_id = LOCAL_erfc_backend_id();
  provenance.analytic_backend = ...
    'Linton_2_65_closed_form_no_fd_fallback';
  provenance.fd_backend = 'value_only_Ewald';
  provenance.rayleigh_backend = 'independent_direct_sum';
end

function ledgers = LOCAL_append_backend(ledgers, provenance)
  names = fieldnames(provenance);
  for j = 1:length(names)
    value = provenance.(names{j});
    if isnumeric(value)
      value = num2str(value);
    end
    ledgers.backend_metadata.rows(end + 1, :) = {names{j}, value, ...
      'captured before any package-MFS precomputation'};
  end
end

function [pass, note, signature] = LOCAL_p_provenance_gate(config)
  p = LOCAL_provenance();
  if p.lsqminnorm_exist ~= 0 && ~isempty(p.lsqminnorm)
    branch = 'lsqminnorm';
  else
    branch = 'pinv';
  end
  signature = struct();
  signature.runtime_kind = p.runtime_kind;
  signature.version = p.version;
  signature.lsqminnorm_exist = p.lsqminnorm_exist;
  signature.lsqminnorm = p.lsqminnorm;
  signature.pinv = p.pinv;
  signature.precomp_proxy = p.precomp_proxy;
  signature.qpgreen_mfs_pairmat = p.qpgreen_mfs_pairmat;
  signature.farfield_extractors = p.farfield_extractors;
  signature.active_solver_branch = branch;
  signature.signature = [p.runtime_kind, '|', p.version, '|', branch, '|', ...
    p.lsqminnorm, '|', p.pinv, '|', p.precomp_proxy, '|', ...
    p.qpgreen_mfs_pairmat, '|', ...
    p.farfield_extractors];
  expected_precomp = fullfile(config.repo_root, '+kernel', 'precomp_proxy.m');
  expected_pairmat = fullfile(config.repo_root, '+kernel', ...
    'qpgreen_mfs_pairmat.m');
  expected_farfield = fullfile(config.repo_root, '+bloch', ...
    'farfield_extractors.m');
  pass = strcmp(p.runtime_kind, 'MATLAB') && strcmp(branch, 'lsqminnorm') && ...
    strcmp(p.precomp_proxy, expected_precomp) && ...
    strcmp(p.qpgreen_mfs_pairmat, expected_pairmat) && ...
    strcmp(p.farfield_extractors, expected_farfield);
  if pass
    note = ['same-process package solver branch=', branch, ...
      '; signature frozen before precomp'];
  else
    note = ['P requires MATLAB lsqminnorm; observed runtime=', ...
      p.runtime_kind, ', branch=', branch, ', precomp=', p.precomp_proxy, ...
      ', expected_precomp=', expected_precomp, ', farfield=', ...
      p.farfield_extractors, ', pairmat=', p.qpgreen_mfs_pairmat];
  end
end

function ledgers = LOCAL_append_p_signature( ...
    ledgers, signature, pass, note)
  names = fieldnames(signature);
  for j = 1:length(names)
    value = signature.(names{j});
    if isnumeric(value)
      value = num2str(value);
    end
    ledgers.backend_metadata.rows(end + 1, :) = {['P_', names{j}], ...
      value, note};
  end
  ledgers.backend_metadata.rows(end + 1, :) = {'P_preflight_pass', ...
    num2str(pass), note};
end

function value = LOCAL_erfc_backend_id()
  if ~isempty(which('Faddeeva_erfc'))
    value = ['Faddeeva_erfc:', which('Faddeeva_erfc')];
  else
    value = ['erfc:', which('erfc')];
  end
end

function tf = LOCAL_path_has_extension(path_value, extension)
  tf = false;
  if length(path_value) >= length(extension)
    tf = strcmp(path_value(end - length(extension) + 1:end), extension);
  end
end

function tf = LOCAL_is_octave()
  tf = exist('OCTAVE_VERSION', 'builtin') ~= 0;
end

function LOCAL_log(fid, varargin)
  fprintf(fid, varargin{:});
  fprintf(varargin{:});
end

function estimate = LOCAL_runtime_estimate(config, pilot_seconds)
  pilot_pairs = config.pilot.ntot * config.pilot.Ny;
  full_pairs = config.full.ntot(end) * config.full.Ny(end);
  matrix_multiplier = full_pairs / pilot_pairs;
  ewald_level_count = length(config.ewald.labels);
  proxy_level_count = length(config.proxy.labels);
  estimate.pilot_seconds = pilot_seconds;
  estimate.pair_multiplier = matrix_multiplier;
  estimate.ewald_level_count = ewald_level_count;
  estimate.proxy_level_count = proxy_level_count;
  estimate.central_seconds = pilot_seconds * matrix_multiplier * ...
    (ewald_level_count + proxy_level_count + 2) / 3;
  estimate.lower_seconds = 0.5 * estimate.central_seconds;
  estimate.upper_seconds = 2.0 * estimate.central_seconds;
  estimate.note = ...
    'Scaling estimate only; MATLAB full run is the runtime authority.';
end

function LOCAL_write_runtime_estimate(output_dir, estimate)
  path = fullfile(output_dir, 'runtime-estimate.md');
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_three_path_derivatives:EstimateOpenFailed', ...
      'Could not write runtime estimate.');
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# Full-run runtime estimate\n\n');
  fprintf(fid, '- Pilot wall time: %.6g s\n', estimate.pilot_seconds);
  fprintf(fid, '- Pair multiplier: %.6g\n', estimate.pair_multiplier);
  fprintf(fid, '- Central estimate: %.6g s\n', estimate.central_seconds);
  fprintf(fid, '- Range: %.6g--%.6g s\n\n', ...
    estimate.lower_seconds, estimate.upper_seconds);
  fprintf(fid, '%s\n', estimate.note);
  clear cleanup;
end

function LOCAL_write_artifacts(output_dir, results)
  ledger_names = fieldnames(results.ledgers);
  file_names = struct( ...
    'backend_metadata', 'backend-metadata.csv', ...
    'kernel_convergence', 'kernel-convergence.csv', ...
    'point_oracle', 'point-oracle.csv', ...
    'identity', 'derivative-identities.csv', ...
    'projection', 'projection-oracle.csv', ...
    'action_level', 'action-levels.csv', ...
    'coefficient', 'coefficient-comparison.csv', ...
    'wall_point', 'wall-point-comparison.csv', ...
    'mutation', 'mutation-cases.csv', ...
    'decision', 'decision-matrix.csv', ...
    'timings', 'timings.csv', ...
    'conventions', 'conventions.csv', ...
    'gates', 'gates.csv');
  for j = 1:length(ledger_names)
    name = ledger_names{j};
    LOCAL_write_csv(fullfile(output_dir, file_names.(name)), ...
      results.ledgers.(name).headers, results.ledgers.(name).rows);
  end
  save(fullfile(output_dir, 'results.mat'), 'results');
  LOCAL_write_report(fullfile(output_dir, 'report.md'), results);
end

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_three_path_derivatives:CSVOpenFailed', ...
      'Could not write %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  LOCAL_write_csv_row(fid, headers);
  for i = 1:size(rows, 1)
    LOCAL_write_csv_row(fid, rows(i, :));
  end
  clear cleanup;
end

function LOCAL_write_csv_row(fid, row)
  for j = 1:length(row)
    if j > 1
      fprintf(fid, ',');
    end
    value = row{j};
    if isnumeric(value) || islogical(value)
      if isempty(value)
        text_value = '';
      elseif isnan(value)
        text_value = 'NaN';
      else
        text_value = sprintf('%.17g', value);
      end
    else
      text_value = char(value);
    end
    text_value = strrep(text_value, '"', '""');
    fprintf(fid, '"%s"', text_value);
  end
  fprintf(fid, '\n');
end

function LOCAL_write_report(path, results)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_three_path_derivatives:ReportOpenFailed', ...
      'Could not write report.');
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# I4 three-path derivative report\n\n');
  fprintf(fid, '- Mode: `%s`\n', results.mode);
  fprintf(fid, '- Status: `%s`\n', results.status);
  fprintf(fid, '- Started: `%s`\n', results.started);
  fprintf(fid, '- Finished: `%s`\n', results.finished);
  fprintf(fid, '- Runtime: %.6g s\n', results.total_seconds);
  fprintf(fid, '- Backend: `%s %s`\n\n', ...
    results.provenance.runtime_kind, results.provenance.version);
  fprintf(fid, '- Scientific authority: `%d`\n\n', ...
    results.provenance.scientific_authority);
  fprintf(fid, '## Frozen semantics\n\n');
  fprintf(fid, ['Internal derivatives use $X=|x_t-x_s|$ and names ', ...
    '`GX_abs`, `GXY_abs`. Physical rows use ', ...
    '$G_x=\\operatorname{sign}(x_t-x_s)G_{X}$ and ', ...
    '$G_{xy}=\\operatorname{sign}(x_t-x_s)G_{XY}$. ', ...
    'The case $x_t-x_s=0$ is rejected.\n\n']);
  fprintf(fid, ['Neumann coefficients are raw: the direct oracle on both ', ...
    'walls is $(\\mathrm{i}\\gamma_m)D_m$. Any normalized values in the ', ...
    'CSV are supplemental and never enforced.\n\n']);
  fprintf(fid, ['Package point prerequisites are action-specific: SLP-D ', ...
    'uses $G$; SLP-N uses $G_x$; DLP-D uses $(G_x,G_y)$; and DLP-N ', ...
    'uses $(G_{xx},G_{xy})$. $G_{yy}$ is diagnostic only.\n\n']);
  fprintf(fid, '## Decisions\n\n');
  fprintf(fid, '| Stage | Classification | Status | Pass | Note |\n');
  fprintf(fid, '|---|---|---|---:|---|\n');
  rows = results.ledgers.decision.rows;
  for j = 1:size(rows, 1)
    fprintf(fid, '| %s | %s | %s | %g | %s |\n', ...
      rows{j, 1}, rows{j, 2}, rows{j, 3}, rows{j, 4}, rows{j, 5});
  end
  fprintf(fid, '\n## Reproduction\n\n');
  fprintf(fid, 'Run in MATLAB from the repository root:\n\n');
  fprintf(fid, '```matlab\n');
  fprintf(fid, ['addpath(fullfile(pwd,''test'',', ...
    '''i4-three-path-derivatives''));\n']);
  fprintf(fid, 'run_i4_three_path_derivatives(''%s'');\n', results.mode);
  fprintf(fid, '```\n');
  clear cleanup;
end
