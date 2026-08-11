function results = run_i4_dlp_trace(mode)
%RUN_I4_DLP_TRACE Run sequential DLP and four-action trace certification.
%
% Purpose:
%   Qualify DLP-D, then DLP-N, then M_trace=48 with independent Ewald,
%   public package-MFS, and direct Rayleigh paths.
%
% Input:
%   mode - 'pilot' (no wall matrix) or 'full' (strict staged wall run).
%
% Output:
%   results - Result struct also saved as MAT/CSV/Markdown/log artifacts.
%
% Main algorithm:
%   Pilot locks MATLAB/package/upstream authorities and tests DLP-D point,
%   finite-difference, rank, residual, and proxy-axis predictions. Full mode
%   gates DLP-D walls, then DLP-N points/walls, then all four M_trace actions.
%
% Based on:
%   test/i4-three-path-derivatives/run_i4_three_path_derivatives.m and
%   test/i4-proxy-rule/run_i4_proxy_rule.m.
%
% Numerical goal:
%   Close DLP actions without changing proxy_dist or solver, then determine
%   whether physical wall bandwidth 48 is indistinguishable from 96.

  if nargin < 1 || isempty(mode)
    mode = 'pilot';
  end
  mode = char(lower(string(mode)));
  if ~any(strcmp(mode, {'pilot', 'full'}))
    error('run_i4_dlp_trace:InvalidMode', ...
      'mode must be ''pilot'' or ''full''.');
  end
  config = i4_dlp_trace_config();
  addpath(config.repo_root);
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
    error('run_i4_dlp_trace:LogOpenFailed', 'Could not open run.log.');
  end
  log_cleanup = onCleanup(@() fclose(log_fid));
  ledgers = LOCAL_empty_ledgers();
  started = datestr(now, 31);
  total_token = tic;
  LOCAL_log(log_fid, 'I4 DLP trace mode=%s started=%s\n', mode, started);

  [preflight_pass, ledgers] = LOCAL_preflight(config, ledgers);
  [pilot, cache, ledgers] = LOCAL_pilot(config, preflight_pass, ...
    ledgers, log_fid);
  LOCAL_write_runtime_estimate(output_dir, config, pilot);
  if strcmp(mode, 'pilot')
    summary = pilot;
  elseif ~pilot.pass
    summary = struct('status', 'DLP_D_PILOT_BLOCKER', 'pass', false, ...
      'stop_after', 'pilot');
    ledgers = LOCAL_not_run(ledgers, {'DLP-D wall', 'DLP-N', 'M_trace'}, ...
      'DLP-D pilot prerequisite failed.');
  else
    [summary, ledgers] = LOCAL_full(config, cache, ledgers, log_fid);
  end
  total_seconds = toc(total_token);
  ledgers.timing.rows(end + 1, :) = {'total', total_seconds, ...
    'measured wall-clock time'};
  results = struct('mode', mode, 'status', summary.status, ...
    'pass', summary.pass, 'started', started, ...
    'finished', datestr(now, 31), 'total_seconds', total_seconds, ...
    'config', config, 'summary', summary, 'ledgers', ledgers, ...
    'provenance', LOCAL_provenance());
  LOCAL_write_artifacts(output_dir, results);
  LOCAL_log(log_fid, 'status=%s seconds=%.6f\n', ...
    results.status, total_seconds);
  clear log_cleanup;
end

%% ==================== Preflight and pilot ====================
% These helpers fail closed before any wall matrix is allocated.

function [pass, ledgers] = LOCAL_preflight(config, ledgers)
  is_matlab = exist('OCTAVE_VERSION', 'builtin') == 0;
  solver = which('lsqminnorm');
  expected = {fullfile(config.repo_root, '+kernel', 'precomp_proxy.m'), ...
    fullfile(config.repo_root, '+kernel', 'qpgreen_mfs_pairmat.m'), ...
    fullfile(config.repo_root, '+bloch', 'farfield_extractors.m')};
  observed = {which('kernel.precomp_proxy'), ...
    which('kernel.qpgreen_mfs_pairmat'), which('bloch.farfield_extractors')};
  hashes = {config.package.precomp_hash, config.package.pairmat_hash, ...
    config.package.farfield_hash};
  package_pass = is_matlab && ~isempty(solver);
  for j = 1:3
    actual_hash = LOCAL_sha256(expected{j});
    row_pass = strcmp(expected{j}, observed{j}) && ...
      strcmp(actual_hash, hashes{j});
    package_pass = package_pass && row_pass;
    ledgers.metadata.rows(end + 1, :) = {sprintf('package_%d', j), ...
      observed{j}, expected{j}, actual_hash, hashes{j}, row_pass};
  end
  authority_paths = {config.derivative_point_oracle, ...
    config.derivative_derivation};
  authority_hashes = {config.derivative_point_oracle_hash, ...
    config.derivative_derivation_hash};
  derivative_pass = true;
  for j = 1:2
    actual_hash = LOCAL_sha256(authority_paths{j});
    row_pass = strcmp(actual_hash, authority_hashes{j});
    derivative_pass = derivative_pass && row_pass;
    ledgers.metadata.rows(end + 1, :) = {sprintf('derivative_%d', j), ...
      authority_paths{j}, authority_paths{j}, actual_hash, ...
      authority_hashes{j}, row_pass};
  end
  slp_pass = false;
  if exist(config.slp_prerequisite, 'file') && ...
      exist(config.slp_report, 'file')
    mat_hash = LOCAL_sha256(config.slp_prerequisite);
    report_hash = LOCAL_sha256(config.slp_report);
    frozen = load(config.slp_prerequisite, 'results');
    slp_pass = strcmp(mat_hash, config.slp_prerequisite_hash) && ...
      strcmp(report_hash, config.slp_report_hash) && ...
      isfield(frozen, 'results') && frozen.results.pass && ...
      strcmp(frozen.results.status, ...
      'SLP_D_N_CERTIFIED_PROXY_RATIO_0P2');
    ledgers.metadata.rows(end + 1, :) = {'SLP_prerequisite', ...
      config.slp_prerequisite, config.slp_report, mat_hash, ...
      config.slp_prerequisite_hash, slp_pass};
  else
    ledgers.metadata.rows(end + 1, :) = {'SLP_prerequisite', ...
      'missing', config.slp_prerequisite, '', ...
      config.slp_prerequisite_hash, false};
  end
  pass = package_pass && derivative_pass && slp_pass;
  ledgers.decision.rows(end + 1, :) = {'preflight', 'BLOCKER', ...
    LOCAL_status(pass, 'MATLAB_PACKAGE_SLP_AUTHORITIES_VERIFIED', ...
    'MATLAB_PACKAGE_SLP_AUTHORITIES_UNCERTIFIED'), pass, ...
    'Requires MATLAB lsqminnorm, exact package hashes, derivative authority, and certified p=0.2 SLP.'};
end

function [summary, cache, ledgers] = LOCAL_pilot( ...
    config, preflight_pass, ledgers, log_fid)
  cache = struct();
  if ~preflight_pass
    summary = struct('status', 'DLP_D_PILOT_PREFLIGHT_UNCERTIFIED', ...
      'pass', false);
    ledgers.decision.rows(end + 1, :) = {'DLP-D pilot', 'BLOCKER', ...
      summary.status, 0, 'No proxy was built after preflight failure.'};
    return;
  end
  pars = LOCAL_pars(config);
  source = [0; 0];
  target = [[config.point.X]; [config.point.Y]];
  labels = config.proxy.labels;
  point_pass = true;
  rank_pass = true;
  duplicate_pass = true;
  for il = 1:length(labels)
    label = labels{il};
    level = config.proxy.(label);
    token = tic;
    proxy = kernel.precomp_proxy(pars, level);
    cache.proxy.(label) = proxy;
    [G, Gx, Gy, Gxx, Gxy, Gyy] = ...
      kernel.qpgreen_mfs_pairmat(source, target, pars, proxy);
    cache.point.(label) = struct('G', G(:), 'Gx', Gx(:), ...
      'Gy', Gy(:), 'Gxx', Gxx(:), 'Gxy', Gxy(:), 'Gyy', Gyy(:));
    ledgers.timing.rows(end + 1, :) = {['pilot_', label], toc(token), ...
      'public precomp and three-point package tuple'};
    [A, b] = LOCAL_assemble_proxy_system(pars, level);
    c = [proxy.q(:); proxy.C_up(:); proxy.C_down(:)];
    singular_values = svd(A, 'econ');
    tolerance = max(size(A)) * eps(singular_values(1));
    numerical_rank = sum(singular_values > tolerance);
    rank_row_pass = numerical_rank == config.proxy.expected_rank(il);
    rank_pass = rank_pass && rank_row_pass;
    q_gate = config.q_duplicate_factor * eps * max(1, norm(proxy.q));
    q_error = abs(proxy.q(1) - proxy.q(end));
    q_row_pass = q_error <= q_gate;
    duplicate_pass = duplicate_pass && q_row_pass;
    ledgers.solver.rows(end + 1, :) = {label, size(A, 1), size(A, 2), ...
      singular_values(1), singular_values(end), tolerance, ...
      numerical_rank, config.proxy.expected_rank(il), rank_row_pass, ...
      norm(A * c - b) / max(norm(b), eps), norm(c), q_error, q_gate, ...
      q_row_pass};
    reference = LOCAL_ewald_points(config, config.ewald.authority);
    for ip = 1:length(config.point)
      for component_cell = {'Gx', 'Gy'}
        component = component_cell{1};
        error_value = abs(cache.point.(label).(component)(ip) - ...
          reference.(component)(ip));
        mandatory = strcmp(label, 'base');
        row_pass = error_value <= config.gate.point;
        point_pass = point_pass && (~mandatory || row_pass);
        ledgers.point.rows(end + 1, :) = {'DLP-D', label, ...
          config.point(ip).label, component, ...
          real(cache.point.(label).(component)(ip)), ...
          imag(cache.point.(label).(component)(ip)), ...
          real(reference.(component)(ip)), ...
          imag(reference.(component)(ip)), error_value, ...
          config.gate.point, row_pass, mandatory, 'Ewald analytic'};
      end
    end
  end
  self_pass = LOCAL_point_self(config, cache.point, {'Gx', 'Gy'}, ...
    'DLP-D', ledgers);
  ledgers = self_pass.ledgers;
  controls = LOCAL_pilot_controls(config, cache, ledgers);
  ledgers = controls.ledgers;
  pass = point_pass && self_pass.pass && controls.pass && ...
    rank_pass && duplicate_pass;
  status = LOCAL_status(pass, 'DLP_D_PILOT_CERTIFIED', ...
    'DLP_D_PILOT_UNCERTIFIED');
  ledgers.decision.rows(end + 1, :) = {'DLP-D pilot', 'BLOCKER', status, ...
    pass, 'Gx/Gy point, four-axis self, FD/sign/parity/nonmirror, rank, and q duplicate gates.'};
  summary = struct('status', status, 'pass', pass, ...
    'point_pass', point_pass, 'self_pass', self_pass.pass, ...
    'control_pass', controls.pass, 'rank_pass', rank_pass, ...
    'duplicate_pass', duplicate_pass);
  LOCAL_log(log_fid, 'pilot status=%s\n', status);
end

function output = LOCAL_point_self(config, point, components, action, ledgers)
  pass = true;
  labels = config.proxy.labels;
  for il = 2:length(labels)
    label = labels{il};
    maximum = 0;
    for component_cell = components
      component = component_cell{1};
      maximum = max(maximum, max(abs(point.base.(component) - ...
        point.(label).(component))));
    end
    row_pass = maximum <= config.gate.self;
    pass = pass && row_pass;
    ledgers.self.rows(end + 1, :) = {action, 'point', label, maximum, ...
      config.gate.self, row_pass, strjoin(components, '+')};
  end
  output = struct('pass', pass, 'ledgers', ledgers);
end

function output = LOCAL_pilot_controls(config, cache, ledgers)
  pars = LOCAL_pars(config);
  proxy = cache.proxy.base;
  source = [0; 0];
  pass = true;
  tuple = cache.point.base;
  signs = struct('Gx', -1, 'Gy', 1);
  for component_cell = {'Gx', 'Gy'}
    component = component_cell{1};
    error_value = abs(tuple.(component)(2) - ...
      signs.(component) * tuple.(component)(1));
    row_pass = error_value <= config.gate.sign;
    pass = pass && row_pass;
    ledgers.control.rows(end + 1, :) = {'transverse_parity', ...
      component, error_value, config.gate.sign, row_pass, ...
      'negative/positive mirror control'};
  end
  for ip = 1:length(config.point)
    point = config.point(ip);
    h = config.fd_h(end);
    offsets = -2:2;
    weights = [1, -8, 0, 8, -1] / (12 * h);
    tx = [point.X + offsets * h; point.Y * ones(1, 5)];
    ty = [point.X * ones(1, 5); point.Y + offsets * h];
    [Gx_values, ~] = kernel.qpgreen_mfs_pairmat(source, tx, pars, proxy);
    [Gy_values, ~] = kernel.qpgreen_mfs_pairmat(source, ty, pars, proxy);
    fd_x = weights * Gx_values(:);
    fd_y = weights * Gy_values(:);
    [~, Gx0, Gy0] = kernel.qpgreen_mfs_pairmat(source, ...
      [point.X; point.Y], pars, proxy);
    errors = [abs(fd_x - Gx0), abs(fd_y - Gy0)];
    names = {'Gx_value_FD', 'Gy_value_FD'};
    for j = 1:2
      row_pass = errors(j) <= config.gate.sign;
      pass = pass && row_pass;
      ledgers.control.rows(end + 1, :) = {config.point(ip).label, ...
        names{j}, errors(j), config.gate.sign, row_pass, ...
        'five-point derivative of package values only'};
    end
    sx = [offsets * h; zeros(1, 5)];
    G_source_x = LOCAL_source_sweep(sx, [point.X; point.Y], ...
      pars, proxy, 'G');
    source_fd = weights * G_source_x(:);
    sign_error = abs(source_fd + Gx0);
    row_pass = sign_error <= config.gate.sign;
    pass = pass && row_pass;
    ledgers.control.rows(end + 1, :) = {config.point(ip).label, ...
      'source_target_x_sign', sign_error, config.gate.sign, row_pass, ...
      'source finite difference equals negative target derivative'};
    sy = [zeros(1, 5); offsets * h];
    G_source_y = LOCAL_source_sweep(sy, [point.X; point.Y], ...
      pars, proxy, 'G');
    source_fd_y = weights * G_source_y(:);
    sign_error_y = abs(source_fd_y + Gy0);
    row_pass = sign_error_y <= config.gate.sign;
    pass = pass && row_pass;
    ledgers.control.rows(end + 1, :) = {config.point(ip).label, ...
      'source_target_y_sign', sign_error_y, config.gate.sign, row_pass, ...
      'source finite difference equals negative target derivative'};
  end
  output = struct('pass', pass, 'ledgers', ledgers);
end

function values = LOCAL_source_sweep(sources, target, pars, proxy, component)
  values = zeros(size(sources, 2), 1);
  for j = 1:size(sources, 2)
    [G, Gx] = kernel.qpgreen_mfs_pairmat( ...
      sources(:, j), target, pars, proxy);
    if strcmp(component, 'G')
      values(j) = G;
    elseif strcmp(component, 'Gx')
      values(j) = Gx;
    else
      error('run_i4_dlp_trace:InvalidSourceSweepComponent', ...
        'Source sweep component must be G or Gx.');
    end
  end
end

%% ==================== Sequential full workflow ====================
% Scientific decisions are appended only when their prerequisites pass.

function [summary, ledgers] = LOCAL_full(config, cache, ledgers, log_fid)
  token = tic;
  base = LOCAL_wall_all(config, cache.proxy.base, config.ewald.authority, ...
    true, true, log_fid, false);
  ledgers.timing.rows(end + 1, :) = {'base_wall_authority', toc(token), ...
    'E/P/R, four cached actions, Mref=96'};
  axes = struct();
  for il = 2:length(config.proxy.labels)
    label = config.proxy.labels{il};
    token = tic;
    axes.(label) = LOCAL_wall_all(config, cache.proxy.(label), ...
      config.ewald.authority, false, true, log_fid, false);
    ledgers.timing.rows(end + 1, :) = {['P_wall_', label], toc(token), ...
      'P-only one-axis wall data'};
  end

  [dlp_d_pass, ledgers] = LOCAL_action_gate(config, base, axes, ...
    'DLP-D', ledgers);
  ledgers = LOCAL_append_samples(config, base, 'DLP-D', ledgers, false);
  if ~dlp_d_pass
    status = 'DLP_D_WALL_UNCERTIFIED';
    ledgers.decision.rows(end + 1, :) = {'DLP-D wall', 'BLOCKER', ...
      status, 0, 'Coefficient triangle or package one-axis self failed.'};
    ledgers = LOCAL_not_run(ledgers, {'DLP-N', 'M_trace'}, ...
      'Stopped at DLP-D wall gate.');
    summary = struct('status', status, 'pass', false, ...
      'stop_after', 'DLP-D');
    return;
  end
  ledgers.decision.rows(end + 1, :) = {'DLP-D wall', 'BLOCKER', ...
    'DLP_D_WALL_CERTIFIED', 1, ...
    'E/P/R coefficient triangles and all four P axes passed.'};

  dlp_n_self = LOCAL_point_self(config, cache.point, {'Gxx', 'Gxy'}, ...
    'DLP-N', ledgers);
  ledgers = dlp_n_self.ledgers;
  [dlp_n_point_pass, ledgers] = LOCAL_dlp_n_point_gate(config, cache, ledgers);
  [mixed_pass, ledgers] = LOCAL_mixed_controls(config, cache, ledgers);
  if ~(dlp_n_self.pass && dlp_n_point_pass && mixed_pass)
    status = 'DLP_N_POINT_UNCERTIFIED';
    ledgers.decision.rows(end + 1, :) = {'DLP-N point', 'BLOCKER', ...
      status, 0, 'Gxx/Gxy Ewald, axis self, or mixed-Hessian control failed.'};
    ledgers = LOCAL_not_run(ledgers, {'DLP-N wall', 'M_trace'}, ...
      'Stopped at DLP-N point gate.');
    summary = struct('status', status, 'pass', false, ...
      'stop_after', 'DLP-N point');
    return;
  end
  ledgers.decision.rows(end + 1, :) = {'DLP-N point', 'BLOCKER', ...
    'DLP_N_POINT_CERTIFIED', 1, ...
    'Gxx/Gxy point/self and mixed-Hessian controls passed.'};

  [dlp_n_pass, ledgers] = LOCAL_action_gate(config, base, axes, ...
    'DLP-N', ledgers);
  ledgers = LOCAL_append_samples(config, base, 'DLP-N', ledgers, false);
  if ~dlp_n_pass
    status = 'DLP_N_WALL_UNCERTIFIED';
    ledgers.decision.rows(end + 1, :) = {'DLP-N wall', 'BLOCKER', ...
      status, 0, 'Coefficient triangle or package one-axis self failed.'};
    ledgers = LOCAL_not_run(ledgers, {'M_trace'}, ...
      'Stopped at DLP-N wall gate.');
    summary = struct('status', status, 'pass', false, ...
      'stop_after', 'DLP-N wall');
    return;
  end
  ledgers.decision.rows(end + 1, :) = {'DLP-N wall', 'BLOCKER', ...
    'DLP_N_WALL_CERTIFIED', 1, ...
    'E/P/R coefficient triangles and all four P axes passed.'};
  ledgers.decision.rows(end + 1, :) = {'auxiliary_ntot_Ny_Ewald_ladders', ...
    'IMPORTANT CAVEAT', 'NOT_RUN_RUNTIME_SCOPE', 0, ...
    'The decisive p=0.2 axes and independent half-grid M_trace are run; extra ntot128/Ny256/Ewald ladders are deferred to stay within 90--180 s.'};

  token = tic;
  holdout = LOCAL_wall_all(config, cache.proxy.base, ...
    config.ewald.authority, true, true, log_fid, true);
  ledgers.timing.rows(end + 1, :) = {'half_grid_holdout', toc(token), ...
    'independent E/P direct wall samples; R remains coefficient authority'};
  [trace_pass, ledgers] = LOCAL_trace_gate(config, base, holdout, ledgers);
  if trace_pass
    status = 'DLP_D_N_MTRACE48_CERTIFIED';
  else
    status = 'MTRACE48_UNCERTIFIED';
  end
  ledgers.decision.rows(end + 1, :) = {'M_trace', 'BLOCKER', status, ...
    trace_pass, 'All four actions, three paths, five levels, half-grid E/P reconstruction.'};
  summary = struct('status', status, 'pass', trace_pass, ...
    'stop_after', LOCAL_ternary(trace_pass, '', 'M_trace'));
end

%% ==================== Wall actions and trace metrics ====================
% These helpers cache common matrices but keep scientific gates sequential.

function data = LOCAL_wall_all( ...
    config, proxy, ewald_level, run_E, run_R, log_fid, holdout)
  pars = LOCAL_pars(config);
  [circle, source, weights] = LOCAL_circle(config, config.ntot);
  if holdout
    y = config.d * ((0:config.Ny - 1) + 0.5) / config.Ny;
  else
    y = config.d * (0:config.Ny - 1) / config.Ny;
  end
  targets = {[config.X_L * ones(1, config.Ny); y], ...
    [config.X_R * ones(1, config.Ny); y]};
  sides = {'L', 'R'};
  normals = [-1, 1];
  channels = LOCAL_channels(config, config.M_reference);
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
      LOCAL_log(log_fid, 'E wall side=%s holdout=%d seconds=%.6f\n', ...
        sides{is}, holdout, toc(token));
    end
    token = tic;
    [G, Gx, Gy, Gxx, Gxy] = kernel.qpgreen_mfs_pairmat( ...
      source, targets{is}, pars, proxy);
    P{is} = LOCAL_action_matrices(G, Gx, Gy, Gxx, Gxy, ...
      circle.nx, circle.ny, normals(is));
    LOCAL_log(log_fid, 'P wall side=%s holdout=%d seconds=%.6f\n', ...
      sides{is}, holdout, toc(token));
  end
  for id = 1:length(config.density)
    density_label = config.density(id).label;
    rho = LOCAL_density(config.density(id), config.ntot);
    weighted = rho .* weights;
    eta_S = [zeros(config.ntot, 1); rho];
    eta_D = [rho; zeros(config.ntot, 1)];
    for is = 1:2
      for action_cell = config.actions
        action = action_cell{1};
        field = strrep(action, '-', '_');
        if run_E
          E_wall = E{is}.(field) * weighted;
          data.(field).(density_label).(sides{is}).E_wall = E_wall;
          data.(field).(density_label).(sides{is}).E = ...
            LOCAL_fourier_project(config, channels, y, E_wall);
        end
        P_wall = P{is}.(field) * weighted;
        data.(field).(density_label).(sides{is}).P_wall = P_wall;
        data.(field).(density_label).(sides{is}).P = ...
          LOCAL_fourier_project(config, channels, y, P_wall);
        if run_R
          if strncmp(action, 'SLP', 3)
            raw = F{is} * eta_S;
          else
            raw = F{is} * eta_D;
          end
          if action(end) == 'N'
            raw = (1i * channels.gamma_m) .* raw;
          end
          data.(field).(density_label).(sides{is}).R = raw;
          data.(field).(density_label).(sides{is}).R_wall = ...
            LOCAL_reconstruct(config, channels, raw, y, ...
            config.M_reference);
        end
      end
    end
  end
  data.channels = channels;
  data.y = y;
  data.holdout = holdout;
end

function [pass, ledgers] = LOCAL_action_gate( ...
    config, base, axes, action, ledgers)
  [triangle_pass, ledgers] = LOCAL_append_triangle( ...
    config, base, action, ledgers, true);
  pass = triangle_pass;
  field = strrep(action, '-', '_');
  for il = 2:length(config.proxy.labels)
    label = config.proxy.labels{il};
    maximum = 0;
    for id = 1:length(config.density)
      density = config.density(id).label;
      for side_cell = {'L', 'R'}
        side = side_cell{1};
        a = base.(field).(density).(side).P;
        b = axes.(label).(field).(density).(side).P;
        maximum = max(maximum, max(abs(a - b)));
      end
    end
    row_pass = maximum <= config.gate.self;
    pass = pass && row_pass;
    ledgers.self.rows(end + 1, :) = {action, 'wall', label, maximum, ...
      config.gate.self, row_pass, 'all densities/walls/modes through 96'};
  end
end

function [pass, ledgers] = LOCAL_append_triangle( ...
    config, data, action, ledgers, enforced)
  field = strrep(action, '-', '_');
  pairs = {'E', 'P'; 'E', 'R'; 'P', 'R'};
  pass = true;
  for id = 1:length(config.density)
    density = config.density(id).label;
    for side_cell = {'L', 'R'}
      side = side_cell{1};
      for im = 1:length(data.channels.m)
        m = data.channels.m(im);
        for ip = 1:3
          left_path = pairs{ip, 1};
          right_path = pairs{ip, 2};
          left = data.(field).(density).(side).(left_path)(im);
          right = data.(field).(density).(side).(right_path)(im);
          absolute_error = abs(left - right);
          relative_error = absolute_error / max([abs(left), abs(right), ...
            config.relative_floor]);
          row_pass = absolute_error <= config.gate.coefficient;
          pass = pass && (~enforced || row_pass);
          ledgers.coefficient.rows(end + 1, :) = {action, density, side, ...
            m, left_path, right_path, real(left), imag(left), ...
            real(right), imag(right), absolute_error, relative_error, ...
            config.gate.coefficient, row_pass, enforced};
        end
      end
    end
  end
end

function ledgers = LOCAL_append_samples( ...
    config, data, action, ledgers, holdout)
  field = strrep(action, '-', '_');
  for id = 1:length(config.density)
    density = config.density(id).label;
    for side_cell = {'L', 'R'}
      side = side_cell{1};
      for path_cell = {'E', 'P', 'R'}
        path = path_cell{1};
        wall_field = [path, '_wall'];
        if ~isfield(data.(field).(density).(side), wall_field)
          continue;
        end
        values = data.(field).(density).(side).(wall_field);
        for jy = 1:length(data.y)
          ledgers.wall_sample.rows(end + 1, :) = {action, density, side, ...
            path, LOCAL_ternary(holdout, 'half_grid', 'training_grid'), ...
            jy, data.y(jy), real(values(jy)), imag(values(jy)), ...
            config.ntot, config.Ny};
        end
      end
    end
  end
end

function [pass, ledgers] = LOCAL_trace_gate(config, base, holdout, ledgers)
  pass = true;
  for action_cell = config.actions
    action = action_cell{1};
    if strncmp(action, 'SLP', 3)
      [triangle_pass, ledgers] = LOCAL_append_triangle( ...
        config, base, action, ledgers, true);
      pass = pass && triangle_pass;
      ledgers = LOCAL_append_samples(config, base, action, ledgers, false);
    end
    field = strrep(action, '-', '_');
    for id = 1:length(config.density)
      density = config.density(id).label;
      for side_cell = {'L', 'R'}
        side = side_cell{1};
        for path_cell = {'E', 'P', 'R'}
          path = path_cell{1};
          coefficients = base.(field).(density).(side).(path);
          reference_wall = LOCAL_reconstruct(config, base.channels, ...
            coefficients, holdout.y, config.M_reference);
          if any(strcmp(path, {'E', 'P'}))
            direct_wall = holdout.(field).(density).(side).([path, '_wall']);
          else
            direct_wall = reference_wall;
          end
          for M = config.M_values
            omitted = abs(base.channels.m) > M;
            if any(omitted)
              omitted_max = max(abs(coefficients(omitted)));
              omitted_energy = norm(coefficients(omitted));
            else
              omitted_max = 0;
              omitted_energy = 0;
            end
            uM = LOCAL_reconstruct(config, base.channels, coefficients, ...
              holdout.y, M);
            direct_change = max(abs(uM - direct_wall));
            enforced = M == config.M_candidate;
            omitted_max_pass = ~enforced || ...
              omitted_max <= config.gate.tail;
            omitted_energy_pass = ~enforced || ...
              omitted_energy <= config.gate.tail;
            direct_pass = ~enforced || ...
              direct_change <= config.gate.reconstruction;
            pass = pass && omitted_max_pass && ...
              omitted_energy_pass && direct_pass;
            ledgers.trace.rows(end + 1, :) = {action, path, density, side, ...
              M, 'omitted_max', omitted_max, config.gate.tail, ...
              omitted_max_pass, enforced, 'Mref=96'};
            ledgers.trace.rows(end + 1, :) = {action, path, density, side, ...
              M, 'omitted_energy', omitted_energy, config.gate.tail, ...
              omitted_energy_pass, enforced, ...
              'l2 coefficient energy on M<abs(m)<=96'};
            ledgers.trace.rows(end + 1, :) = {action, path, density, side, ...
              M, 'direct_half_grid_reconstruction', direct_change, ...
              config.gate.reconstruction, direct_pass, enforced, ...
              LOCAL_ternary(strcmp(path, 'R'), ...
              'sampled-grid finite screen against u96', ...
              'independent direct half-grid wall samples')};
          end
          for ib = 1:size(config.M_bands, 1)
            low = config.M_bands(ib, 1);
            high = config.M_bands(ib, 2);
            band = abs(base.channels.m) > low & ...
              abs(base.channels.m) <= high;
            band_max = max(abs(coefficients(band)));
            band_enforced = low >= config.M_candidate;
            band_pass = ~band_enforced || band_max <= config.gate.tail;
            pass = pass && band_pass;
            ledgers.trace.rows(end + 1, :) = {action, path, density, side, ...
              high, sprintf('terminal_band_%d_%d', low, high), band_max, ...
              config.gate.tail, band_pass, band_enforced, 'raw coefficients'};
          end
          u48 = LOCAL_reconstruct(config, base.channels, coefficients, ...
            holdout.y, 48);
          u64 = LOCAL_reconstruct(config, base.channels, coefficients, ...
            holdout.y, 64);
          u96 = reference_wall;
          changes = [max(abs(u64 - u48)), max(abs(u96 - u64))];
          change_levels = [64, 96];
          names = {'reconstruction_48_to_64', 'reconstruction_64_to_96'};
          for j = 1:2
            row_pass = changes(j) <= config.gate.reconstruction;
            pass = pass && row_pass;
            ledgers.trace.rows(end + 1, :) = {action, path, density, side, ...
              change_levels(j), names{j}, changes(j), ...
              config.gate.reconstruction, row_pass, true, ...
              'half-grid reconstruction change'};
          end
        end
      end
    end
  end
  for action_cell = config.actions
    ledgers = LOCAL_append_samples(config, holdout, action_cell{1}, ...
      ledgers, true);
  end
end

function [pass, ledgers] = LOCAL_dlp_n_point_gate(config, cache, ledgers)
  reference = LOCAL_ewald_points(config, config.ewald.authority);
  pass = true;
  for ip = 1:length(config.point)
    for component_cell = {'Gxx', 'Gxy'}
      component = component_cell{1};
      value = cache.point.base.(component)(ip);
      error_value = abs(value - reference.(component)(ip));
      row_pass = error_value <= config.gate.point;
      pass = pass && row_pass;
      ledgers.point.rows(end + 1, :) = {'DLP-N', 'base', ...
        config.point(ip).label, component, real(value), imag(value), ...
        real(reference.(component)(ip)), imag(reference.(component)(ip)), ...
        error_value, config.gate.point, row_pass, true, 'Ewald analytic'};
    end
  end
  parity_components = {'Gxx', 'Gxy'};
  parity_signs = [1, -1];
  for j = 1:2
    component = parity_components{j};
    error_value = abs(cache.point.base.(component)(2) - ...
      parity_signs(j) * cache.point.base.(component)(1));
    row_pass = error_value <= config.gate.sign;
    pass = pass && row_pass;
    ledgers.control.rows(end + 1, :) = {'DLP-N mirror pair', ...
      [component, '_parity'], error_value, config.gate.sign, row_pass, ...
      'even Gxx and odd Gxy transverse parity'};
  end
end

function [pass, ledgers] = LOCAL_mixed_controls(config, cache, ledgers)
  pars = LOCAL_pars(config);
  proxy = cache.proxy.base;
  source = [0; 0];
  h = config.fd_h(end);
  offsets = -2:2;
  weights = [1, -8, 0, 8, -1] / (12 * h);
  pass = true;
  for ip = 1:length(config.point)
    point = config.point(ip);
    tx = [point.X + offsets * h; point.Y * ones(1, 5)];
    ty = [point.X * ones(1, 5); point.Y + offsets * h];
    [~, Gx_x, Gy_x] = kernel.qpgreen_mfs_pairmat(source, tx, pars, proxy);
    [~, Gx_y] = kernel.qpgreen_mfs_pairmat(source, ty, pars, proxy);
    fd_xx = weights * Gx_x(:);
    fd_xy_yGx = weights * Gx_y(:);
    fd_xy_xGy = weights * Gy_x(:);
    expected_xx = cache.point.base.Gxx(ip);
    expected_xy = cache.point.base.Gxy(ip);
    values = [abs(fd_xx - expected_xx), ...
      abs(fd_xy_yGx - expected_xy), ...
      abs(fd_xy_xGy - expected_xy), ...
      abs(fd_xy_yGx - fd_xy_xGy)];
    names = {'Gxx_from_Gx', 'Gxy_from_yGx', 'Gxy_from_xGy', ...
      'mixed_derivative_symmetry'};
    for j = 1:4
      row_pass = values(j) <= config.gate.sign;
      pass = pass && row_pass;
      ledgers.control.rows(end + 1, :) = {point.label, names{j}, ...
        values(j), config.gate.sign, row_pass, ...
        'public lsqminnorm coefficients; no alternate solver'};
    end
    sx = [offsets * h; zeros(1, 5)];
    sy = [zeros(1, 5); offsets * h];
    Gx_source_x = LOCAL_source_sweep(sx, [point.X; point.Y], ...
      pars, proxy, 'Gx');
    Gx_source_y = LOCAL_source_sweep(sy, [point.X; point.Y], ...
      pars, proxy, 'Gx');
    source_errors = [abs(weights * Gx_source_x(:) + expected_xx), ...
      abs(weights * Gx_source_y(:) + expected_xy)];
    source_names = {'source_target_Gxx_sign', 'source_target_Gxy_sign'};
    for j = 1:2
      row_pass = source_errors(j) <= config.gate.sign;
      pass = pass && row_pass;
      ledgers.control.rows(end + 1, :) = {point.label, source_names{j}, ...
        source_errors(j), config.gate.sign, row_pass, ...
        'source derivative of target Gx has the opposite sign'};
    end
  end
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

function [circle, source, weights] = LOCAL_circle(config, ntot)
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  x = config.R * cos(theta);
  y = config.R * sin(theta);
  circle = struct('x', x, 'y', y, 'dxdt', -config.R * sin(theta), ...
    'dydt', config.R * cos(theta), 'speed', config.R * ones(ntot, 1), ...
    'nx', cos(theta), 'ny', sin(theta));
  source = [x.'; y.'];
  weights = (2 * pi / ntot) * config.R * ones(ntot, 1);
end

function density = LOCAL_density(item, ntot)
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  density = zeros(ntot, 1);
  for j = 1:length(item.ell)
    density = density + item.coeff(j) * exp(1i * item.ell(j) * theta);
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

function coefficients = LOCAL_fourier_project(config, channels, y, values)
  basis = (1 / sqrt(config.d)) * exp(-1i * (channels.beta_m * y));
  coefficients = (config.d / length(y)) * basis * values(:);
end

function values = LOCAL_reconstruct(config, channels, coefficients, y, M)
  band = abs(channels.m) <= M;
  basis = (1 / sqrt(config.d)) * ...
    exp(1i * (y(:) * channels.beta_m(band).'));
  values = basis * coefficients(band);
end

%% ==================== Independent analytic Ewald path ====================
% These helpers differentiate the qualified Linton split analytically.

function tuple = LOCAL_ewald_points(config, level)
  X = [config.point.X];
  Y = [config.point.Y];
  tuple = LOCAL_project_kernel(config, X, Y, level);
  fields = fieldnames(tuple);
  for j = 1:length(fields)
    tuple.(fields{j}) = tuple.(fields{j})(:);
  end
end

function matrices = LOCAL_ewald_pair_matrices( ...
    config, source, target, nsx, nsy, ntx, level)
  DX = target(1, :).'- source(1, :);
  DY = target(2, :).'- source(2, :);
  if any(DX(:) == 0)
    error('run_i4_dlp_trace:EwaldWallZeroSeparation', ...
      'A wall/source pair has zero transverse separation.');
  end
  names = {'G', 'Gx', 'Gy', 'Gxx', 'Gxy'};
  for j = 1:length(names)
    tuple.(names{j}) = zeros(size(DX));
  end
  total = numel(DX);
  for first = 1:config.chunk_size:total
    last = min(total, first + config.chunk_size - 1);
    index = first:last;
    values = LOCAL_project_kernel(config, DX(index), DY(index), level);
    for j = 1:length(names)
      temporary = tuple.(names{j});
      temporary(index) = values.(names{j});
      tuple.(names{j}) = temporary;
    end
  end
  matrices = LOCAL_action_matrices(tuple.G, tuple.Gx, tuple.Gy, ...
    tuple.Gxx, tuple.Gxy, nsx, nsy, ntx);
end

function physical = LOCAL_project_kernel(config, X_signed, Y, level)
  if any(X_signed(:) == 0)
    error('run_i4_dlp_trace:ZeroEwaldSeparation', ...
      'Ewald derivatives require nonzero transverse separation.');
  end
  sx = sign(X_signed(:).');
  magnitude = LOCAL_linton_kernel(config, abs(X_signed(:).'), ...
    Y(:).', level);
  fields = fieldnames(magnitude);
  for j = 1:length(fields)
    magnitude.(fields{j}) = config.project_sign * magnitude.(fields{j});
  end
  physical.G = magnitude.G;
  physical.Gx = sx .* magnitude.GX;
  physical.Gy = magnitude.GY;
  physical.Gxx = magnitude.GXX;
  physical.Gxy = sx .* magnitude.GXY;
  physical.Gyy = magnitude.GYY;
end

function out = LOCAL_linton_kernel(config, X, Y, level)
  reciprocal = LOCAL_linton_reciprocal(config, X, Y, level);
  real_space = LOCAL_linton_real(config, X, Y, level);
  names = {'G', 'GX', 'GY', 'GXX', 'GXY', 'GYY'};
  for j = 1:length(names)
    out.(names{j}) = reciprocal.(names{j}) + real_space.(names{j});
  end
end

function out = LOCAL_linton_reciprocal(config, X, Y, level)
  m = (-level.M1:level.M1).';
  beta_m = config.beta + 2 * pi * m / config.d;
  q = LOCAL_linton_branch(config.k, beta_m);
  h = level.a / config.d;
  c = q * config.d / (2 * level.a);
  z_plus = bsxfun(@plus, c, h * X);
  z_minus = bsxfun(@minus, c, h * X);
  erfc_plus = LOCAL_complex_erfc(z_plus);
  erfc_minus = LOCAL_complex_erfc(z_minus);
  chi_plus = -(2 / sqrt(pi)) * exp(-(z_plus .^ 2));
  chi_minus = -(2 / sqrt(pi)) * exp(-(z_minus .^ 2));
  chi2_plus = -2 * z_plus .* chi_plus;
  chi2_minus = -2 * z_minus .* chi_minus;
  exp_plus = exp(bsxfun(@times, q, X));
  exp_minus = exp(bsxfun(@times, -q, X));
  Fp = exp_plus .* erfc_plus;
  Fm = exp_minus .* erfc_minus;
  FXp = exp_plus .* bsxfun(@plus, q .* erfc_plus, h * chi_plus);
  FXm = -exp_minus .* bsxfun(@plus, q .* erfc_minus, h * chi_minus);
  FXXp = exp_plus .* (bsxfun(@times, q .^ 2, erfc_plus) + ...
    bsxfun(@times, 2 * h * q, chi_plus) + h ^ 2 * chi2_plus);
  FXXm = exp_minus .* (bsxfun(@times, q .^ 2, erfc_minus) + ...
    bsxfun(@times, 2 * h * q, chi_minus) + h ^ 2 * chi2_minus);
  F = Fp + Fm;
  FX = FXp + FXm;
  FXX = FXXp + FXXm;
  phase = exp(1i * bsxfun(@times, beta_m, Y));
  base = bsxfun(@rdivide, phase, q);
  scale = -1 / (4 * config.d);
  out.G = scale * sum(base .* F, 1);
  out.GX = scale * sum(base .* FX, 1);
  out.GY = scale * sum(bsxfun(@times, 1i * beta_m, base) .* F, 1);
  out.GXX = scale * sum(base .* FXX, 1);
  out.GXY = scale * sum(bsxfun(@times, 1i * beta_m, base) .* FX, 1);
  out.GYY = scale * sum(bsxfun(@times, -(beta_m .^ 2), base) .* F, 1);
end

function out = LOCAL_linton_real(config, X, Y, level)
  m = (-level.M2:level.M2).';
  image_Y = bsxfun(@minus, Y, m * config.d);
  alpha = (level.a / config.d) ^ 2;
  z = alpha * bsxfun(@plus, X .^ 2, image_Y .^ 2);
  exp_neg = exp(-z);
  E_nm1 = exp_neg .* (1 ./ z + 1 ./ (z .^ 2));
  E_n = exp_neg ./ z;
  E_np1 = expint(z);
  S = zeros(size(z));
  Sz = zeros(size(z));
  Szz = zeros(size(z));
  for n = 0:level.N
    coefficient = (config.k * config.d / (2 * level.a)) ^ (2 * n) / ...
      factorial(n);
    S = S + coefficient * E_np1;
    Sz = Sz - coefficient * E_n;
    Szz = Szz + coefficient * E_nm1;
    if n < level.N
      E_nm1 = E_n;
      E_n = E_np1;
      E_np1 = (exp_neg - z .* E_n) / (n + 1);
    end
  end
  zX = 2 * alpha * X;
  zY = 2 * alpha * image_Y;
  phase = exp(1i * config.beta * m * config.d);
  scale = -1 / (4 * pi);
  out.G = scale * sum(bsxfun(@times, phase, S), 1);
  out.GX = scale * sum(bsxfun(@times, phase, ...
    bsxfun(@times, Sz, zX)), 1);
  out.GY = scale * sum(bsxfun(@times, phase, Sz .* zY), 1);
  out.GXX = scale * sum(bsxfun(@times, phase, ...
    bsxfun(@times, Szz, zX .^ 2) + 2 * alpha * Sz), 1);
  out.GXY = scale * sum(bsxfun(@times, phase, ...
    bsxfun(@times, Szz .* zY, zX)), 1);
  out.GYY = scale * sum(bsxfun(@times, phase, ...
    Szz .* (zY .^ 2) + 2 * alpha * Sz), 1);
end

function q = LOCAL_linton_branch(k, beta_m)
  difference = beta_m .^ 2 - k ^ 2;
  q = zeros(size(beta_m));
  evanescent = difference >= 0;
  q(evanescent) = sqrt(difference(evanescent));
  q(~evanescent) = -1i * sqrt(-difference(~evanescent));
end

function value = LOCAL_complex_erfc(z)
  if isempty(which('Faddeeva_erfc'))
    error('run_i4_dlp_trace:FaddeevaMissing', ...
      'Qualified MATLAB Faddeeva_erfc is required.');
  end
  value = Faddeeva_erfc(z);
end

%% ==================== Exact proxy system ====================
% This copied assembly is diagnostic only; it never replaces lsqminnorm.

function [A, b] = LOCAL_assemble_proxy_system(pars, level)
  d = pars.d;
  beta = pars.beta;
  k = pars.k;
  H = level.H;
  Ns = level.N_side;
  Nt = level.N_top;
  Ne = level.N_proxy_edge;
  Mpw = level.M_pw;
  ys = linspace(-H, H, Ns).';
  xt = linspace(-d / 2, d / 2, Nt).';
  pL = [-d / 2 * ones(Ns, 1), ys];
  pR = [d / 2 * ones(Ns, 1), ys];
  pT = [xt, H * ones(Nt, 1)];
  pB = [xt, -H * ones(Nt, 1)];
  xmin = -d / 2 - level.proxy_dist;
  xmax = d / 2 + level.proxy_dist;
  ymin = -H - level.proxy_dist;
  ymax = H + level.proxy_dist;
  tx = linspace(xmin, xmax, Ne + 1).';
  tx(end) = [];
  ty = linspace(ymin, ymax, Ne + 1).';
  ty(end) = [];
  Z = [[tx; repmat(xmax, Ne, 1); flipud(tx); repmat(xmin, Ne, 1)], ...
    [repmat(ymin, Ne, 1); ty; repmat(ymax, Ne, 1); flipud(ty)]];
  Np = size(Z, 1);
  m = (-Mpw:Mpw).';
  beta_m = beta + 2 * pi * m / d;
  gamma_m = LOCAL_rayleigh_branch(k, beta_m);
  Nw = length(m);
  A = zeros(2 * Ns + 4 * Nt, Np + 2 * Nw);
  b = zeros(size(A, 1), 1);
  LRv = 1:Ns;
  LRd = Ns + (1:Ns);
  Tv = 2 * Ns + (1:Nt);
  Td = 2 * Ns + Nt + (1:Nt);
  Bv = 2 * Ns + 2 * Nt + (1:Nt);
  Bd = 2 * Ns + 3 * Nt + (1:Nt);
  cq = 1:Np;
  cu = Np + (1:Nw);
  cd = Np + Nw + (1:Nw);
  phase = exp(1i * beta * d);
  [sL, sxL, ~] = LOCAL_free_space(k, pL, [0, 0]);
  [sR, sxR, ~] = LOCAL_free_space(k, pR, [0, 0]);
  b(LRv) = -(sR - phase * sL);
  b(LRd) = -(sxR - phase * sxL);
  [sT, ~, syT] = LOCAL_free_space(k, pT, [0, 0]);
  [sB, ~, syB] = LOCAL_free_space(k, pB, [0, 0]);
  b(Tv) = -sT;
  b(Td) = -syT;
  b(Bv) = -sB;
  b(Bd) = -syB;
  [qL, qxL, ~] = LOCAL_free_space(k, pL, Z);
  [qR, qxR, ~] = LOCAL_free_space(k, pR, Z);
  A(LRv, cq) = qR - phase * qL;
  A(LRd, cq) = qxR - phase * qxL;
  [qT, ~, qyT] = LOCAL_free_space(k, pT, Z);
  [qB, ~, qyB] = LOCAL_free_space(k, pB, Z);
  A(Tv, cq) = qT;
  A(Td, cq) = qyT;
  A(Bv, cq) = qB;
  A(Bd, cq) = qyB;
  PWt = exp(1i * pT(:, 1) * beta_m.');
  PWb = exp(1i * pB(:, 1) * beta_m.');
  A(Tv, cu) = -PWt;
  A(Td, cu) = -(PWt .* (1i * gamma_m.'));
  A(Bv, cd) = -PWb;
  A(Bd, cd) = -(PWb .* (-1i * gamma_m.'));
end

function [G, Gx, Gy] = LOCAL_free_space(k, target, source)
  dx = target(:, 1) - source(:, 1).';
  dy = target(:, 2) - source(:, 2).';
  distance = sqrt(dx .^ 2 + dy .^ 2);
  G = (1i / 4) * besselh(0, 1, k * distance);
  factor = -(1i * k / 4) * besselh(1, 1, k * distance) ./ distance;
  Gx = factor .* dx;
  Gy = factor .* dy;
end

%% ==================== Ledgers and artifacts ====================
% These helpers preserve complete data and explicit first-failure decisions.

function pars = LOCAL_pars(config)
  pars = struct('k', config.k, 'beta', config.beta, 'd', config.d, ...
    'periodic_axis', 'y');
end

function ledgers = LOCAL_not_run(ledgers, stages, note)
  for j = 1:length(stages)
    ledgers.decision.rows(end + 1, :) = {stages{j}, 'BLOCKER', ...
      'NOT_RUN_PREREQUISITE', 0, note};
  end
end

function ledgers = LOCAL_empty_ledgers()
  ledgers.metadata = LOCAL_ledger({'key', 'observed_path', ...
    'expected_path', 'observed_hash', 'expected_hash', 'pass'});
  ledgers.point = LOCAL_ledger({'action', 'level', 'point', 'component', ...
    'value_re', 'value_im', 'reference_re', 'reference_im', ...
    'absolute_error', 'gate', 'pass', 'mandatory', 'reference'});
  ledgers.self = LOCAL_ledger({'action', 'scope', 'level', ...
    'maximum_change', 'gate', 'pass', 'note'});
  ledgers.control = LOCAL_ledger({'point_or_identity', 'control', ...
    'error', 'gate', 'pass', 'note'});
  ledgers.solver = LOCAL_ledger({'level', 'equations', 'unknowns', ...
    'sigma_max', 'sigma_min', 'rank_tolerance', 'rank', ...
    'expected_rank', 'rank_pass', 'relative_residual', ...
    'coefficient_norm', 'q_first_last_error', 'q_gate', 'q_pass'});
  ledgers.coefficient = LOCAL_ledger({'action', 'density', 'side', 'm', ...
    'left_path', 'right_path', 'left_re', 'left_im', 'right_re', ...
    'right_im', 'absolute_error', 'floored_relative_error', 'gate', ...
    'pass', 'enforced'});
  ledgers.wall_sample = LOCAL_ledger({'action', 'density', 'side', ...
    'path', 'grid', 'index', 'y', 'value_re', 'value_im', 'ntot', 'Ny'});
  ledgers.trace = LOCAL_ledger({'action', 'path', 'density', 'side', ...
    'M', 'metric', 'value', 'gate', 'pass', 'enforced', 'note'});
  ledgers.decision = LOCAL_ledger({'stage', 'classification', 'status', ...
    'pass', 'note'});
  ledgers.timing = LOCAL_ledger({'stage', 'seconds', 'note'});
end

function ledger = LOCAL_ledger(headers)
  ledger = struct('headers', {headers}, ...
    'rows', {cell(0, length(headers))});
end

function status = LOCAL_status(pass, pass_status, fail_status)
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

function hash = LOCAL_sha256(path)
  if ~exist(path, 'file')
    hash = '';
    return;
  end
  quoted = strrep(path, '"', '\"');
  [status, output] = system(sprintf('shasum -a 256 "%s"', quoted));
  token = regexp(lower(output), '[0-9a-f]{64}', 'match', 'once');
  if status ~= 0 || isempty(token)
    error('run_i4_dlp_trace:SHA256Failed', ...
      'Could not compute SHA-256 for %s.', path);
  end
  hash = token;
end

function provenance = LOCAL_provenance()
  provenance.runtime = LOCAL_ternary( ...
    exist('OCTAVE_VERSION', 'builtin') == 0, 'MATLAB', 'Octave');
  provenance.version = version;
  provenance.lsqminnorm = which('lsqminnorm');
  provenance.precomp_proxy = which('kernel.precomp_proxy');
  provenance.pairmat = which('kernel.qpgreen_mfs_pairmat');
  provenance.farfield = which('bloch.farfield_extractors');
  provenance.Faddeeva_erfc = which('Faddeeva_erfc');
end

function LOCAL_write_runtime_estimate(output_dir, config, pilot)
  fid = fopen(fullfile(output_dir, 'runtime-estimate.md'), 'w');
  if fid < 0
    error('run_i4_dlp_trace:EstimateOpenFailed', ...
      'Could not write runtime estimate.');
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# Full-run estimate\n\n');
  fprintf(fid, '- Pilot wall matrices: `0`.\n');
  fprintf(fid, '- Estimated full cost: `%.0f--%.0f s`.\n', ...
    config.runtime.low_seconds, config.runtime.high_seconds);
  fprintf(fid, '- Pilot prerequisite pass: `%d`.\n', pilot.pass);
  fprintf(fid, ['- Full ordering: DLP-D wall, DLP-N point/wall, then ', ...
    'four-action half-grid M_trace.\n']);
  clear cleanup;
end

function LOCAL_write_artifacts(output_dir, results)
  names = fieldnames(results.ledgers);
  for j = 1:length(names)
    name = names{j};
    LOCAL_write_csv(fullfile(output_dir, [strrep(name, '_', '-'), ...
      '.csv']), results.ledgers.(name).headers, ...
      results.ledgers.(name).rows);
  end
  save(fullfile(output_dir, 'results.mat'), 'results');
  LOCAL_write_report(fullfile(output_dir, 'report.md'), results);
end

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_dlp_trace:CSVOpenFailed', 'Could not write %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  LOCAL_write_csv_row(fid, headers);
  for j = 1:size(rows, 1)
    LOCAL_write_csv_row(fid, rows(j, :));
  end
  clear cleanup;
end

function LOCAL_write_csv_row(fid, row)
  for j = 1:length(row)
    if j > 1
      fprintf(fid, ',');
    end
    value = row{j};
    if islogical(value)
      fprintf(fid, '%d', value);
    elseif isnumeric(value)
      fprintf(fid, '%.17g', value);
    else
      text = strrep(char(string(value)), '"', '""');
      fprintf(fid, '"%s"', text);
    end
  end
  fprintf(fid, '\n');
end

function LOCAL_write_report(path, results)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_dlp_trace:ReportOpenFailed', ...
      'Could not write report.md.');
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# I4 DLP and trace report\n\n');
  fprintf(fid, '- Mode: `%s`\n', results.mode);
  fprintf(fid, '- Status: `%s`\n', results.status);
  fprintf(fid, '- Pass: `%d`\n', results.pass);
  fprintf(fid, '- Runtime: `%.6f s`\n', results.total_seconds);
  fprintf(fid, '- Backend: `%s %s`\n\n', ...
    results.provenance.runtime, results.provenance.version);
  fprintf(fid, '## Decisions\n\n');
  fprintf(fid, '| Stage | Classification | Status | Pass | Note |\n');
  fprintf(fid, '|---|---|---|---:|---|\n');
  rows = results.ledgers.decision.rows;
  for j = 1:size(rows, 1)
    fprintf(fid, '| %s | %s | %s | %d | %s |\n', ...
      rows{j, 1}, rows{j, 2}, rows{j, 3}, rows{j, 4}, rows{j, 5});
  end
  fprintf(fid, '\n## Reproduction\n\n```matlab\n');
  fprintf(fid, 'addpath(fullfile(pwd,''test'',''i4-dlp-trace''));\n');
  fprintf(fid, 'run_i4_dlp_trace(''%s'');\n', results.mode);
  fprintf(fid, '```\n');
  clear cleanup;
end

function LOCAL_log(fid, varargin)
  fprintf(fid, varargin{:});
  fprintf(varargin{:});
end
