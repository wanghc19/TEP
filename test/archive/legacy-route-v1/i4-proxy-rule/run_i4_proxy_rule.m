function results = run_i4_proxy_rule(mode)
%RUN_I4_PROXY_RULE Run the singularity-aware proxy placement experiment.
%
% Purpose:
%   Diagnose one preregistered package-MFS proxy source placement and test
%   SLP-D/SLP-N wall actions without modifying the package implementation.
%
% Input:
%   mode - 'pilot' for point/system diagnostics without wall matrices, or
%          'full' for the staged SLP-D/SLP-N wall-action ladder.
%
% Output:
%   results - Reproducible result bundle also written as MAT/CSV/Markdown.
%
% Main algorithm:
%   1. Verify immutable Ewald/Rayleigh and point-oracle CSV authorities.
%   2. Call public kernel.precomp_proxy at the sole proxy_dist/d=0.2 levels.
%   3. Reassemble the exact collocation system only for residual, spectrum,
%      coefficient, and shifted hold-out diagnostics; never replace its
%      public lsqminnorm solution.
%   4. In full mode form only SLP-D and SLP-N wall Fourier coefficients,
%      compare the base with frozen E/R rows, then refine one axis at a time.
%
% Based on:
%   kernel.precomp_proxy, test/root-ready/provenance-closure/
%   LOCAL_precomp_proxy_instrumented.m, and the qualified I4 canonical CSVs.
%
% Main changes:
%   Uses one prospective source distance, true midpoint hold-out nodes, and
%   Nedge-first stopping. DLP, DtN, and root-location code are absent.
%
% Numerical goal:
%   Decide whether proxy_dist/d=0.2 closes the 2e-9 SLP-N package action
%   self-convergence blocker while preserving the passed 1e-8 coefficients.

  if nargin < 1 || isempty(mode)
    mode = 'pilot';
  end
  if isstring(mode)
    mode = char(mode);
  end
  mode = lower(strtrim(mode));
  if ~any(strcmp(mode, {'pilot', 'full'}))
    error('run_i4_proxy_rule:InvalidMode', ...
      'mode must be ''pilot'' or ''full''.');
  end

  config = i4_proxy_rule_config();
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
    error('run_i4_proxy_rule:LogOpenFailed', 'Could not open run.log.');
  end
  log_cleanup = onCleanup(@() fclose(log_fid));
  started = datestr(now, 31);
  LOCAL_log(log_fid, 'I4 proxy rule mode=%s started=%s\n', mode, started);
  total_token = tic;

  ledgers = LOCAL_empty_ledgers();
  [preflight_pass, ledgers] = LOCAL_preflight(config, ledgers);
  [authority, ledgers, authority_pass] = ...
    LOCAL_load_authority(config, ledgers);
  [pilot, ledgers, proxies] = LOCAL_pilot(config, authority, ...
    preflight_pass && authority_pass, ledgers, log_fid);
  LOCAL_write_runtime_estimate(output_dir, config, pilot);

  if strcmp(mode, 'pilot')
    summary = pilot;
  elseif ~pilot.pass
    summary = struct('status', 'PROXY_PILOT_BLOCKER', 'pass', false, ...
      'stop_after', 'pilot', 'pilot', pilot);
    ledgers.decision.rows(end + 1, :) = {'wall_actions', 'BLOCKER', ...
      'NOT_RUN_PREREQUISITE', 0, ...
      'Pilot authority or base Gx point gate failed; no wall matrix built.'};
  else
    [summary, ledgers] = LOCAL_full(config, authority, proxies, ...
      pilot, ledgers, log_fid);
  end

  total_seconds = toc(total_token);
  ledgers.timings.rows(end + 1, :) = {'total', total_seconds, ...
    'measured wall-clock time'};
  results = struct('mode', mode, 'status', summary.status, ...
    'pass', summary.pass, 'started', started, ...
    'finished', datestr(now, 31), 'total_seconds', total_seconds, ...
    'config', config, 'summary', summary, 'ledgers', ledgers, ...
    'provenance', LOCAL_provenance(config));
  LOCAL_write_artifacts(output_dir, results);
  LOCAL_log(log_fid, 'status=%s seconds=%.6f output=%s\n', ...
    results.status, total_seconds, output_dir);
  clear log_cleanup;
end

%% ==================== Pilot and public package path ====================
% These helpers run point/system diagnostics without constructing wall matrices.

function [summary, ledgers, proxies] = LOCAL_pilot( ...
    config, authority, authority_pass, ledgers, log_fid)
  proxies = struct();
  if ~authority_pass
    status = 'PILOT_FROZEN_AUTHORITY_UNCERTIFIED';
    summary = struct('status', status, 'pass', false, ...
      'authority_pass', false, 'base_point_pass', false, ...
      'wall_cost_low_seconds', config.runtime.low_seconds, ...
      'wall_cost_high_seconds', config.runtime.high_seconds);
    ledgers.decision.rows(end + 1, :) = {'pilot_point', 'BLOCKER', ...
      status, 0, 'No package calculation was run after authority failure.'};
    return;
  end
  pars = LOCAL_pars(config);
  point_pass = authority_pass;
  level_labels = config.level_order;
  for il = 1:length(level_labels)
    label = level_labels{il};
    level = config.proxy.(label);
    LOCAL_log(log_fid, 'pilot level=%s Nside=%d Ntop=%d Nedge=%d Mpw=%d\n', ...
      label, level.N_side, level.N_top, level.N_proxy_edge, level.M_pw);
    token = tic;
    proxy = kernel.precomp_proxy(pars, level);
    elapsed = toc(token);
    ledgers.timings.rows(end + 1, :) = {['precomp_', label], elapsed, ...
      'public kernel.precomp_proxy using package lsqminnorm path'};
    proxies.(label) = proxy;

    [A, b, assembly] = LOCAL_assemble_proxy_system(pars, level, false);
    coefficients = LOCAL_proxy_coefficients(proxy);
    if length(coefficients) ~= size(A, 2)
      error('run_i4_proxy_rule:CoefficientDimension', ...
        'Public proxy coefficient count does not match copied A.');
    end
    ledgers = LOCAL_system_diagnostics(config, ledgers, label, level, ...
      A, b, assembly, coefficients, 'training');
    [A_hold, b_hold, assembly_hold] = ...
      LOCAL_assemble_proxy_system(pars, level, true);
    ledgers = LOCAL_residual_rows(config, ledgers, label, level, ...
      A_hold, b_hold, assembly_hold.blocks, coefficients, 'holdout');
    ledgers = LOCAL_coefficient_diagnostics(config, ledgers, label, ...
      level, proxy, coefficients);
    ledgers = LOCAL_point_rows(config, authority, ledgers, label, ...
      pars, proxy);
  end

  if authority_pass
    base_rows = strcmp(ledgers.point.rows(:, 1), 'base');
    if any(base_rows)
      base_pass = all(cell2mat(ledgers.point.rows(base_rows, 11)) ~= 0);
    else
      base_pass = false;
    end
  else
    base_pass = false;
  end
  point_pass = point_pass && base_pass;
  point_self_pass = true;
  for il = 2:length(level_labels)
    label = level_labels{il};
    maximum = 0;
    for ip = 1:length(config.point)
      point_label = config.point(ip).label;
      base_select = strcmp(ledgers.point.rows(:, 1), 'base') & ...
        strcmp(ledgers.point.rows(:, 2), point_label);
      axis_select = strcmp(ledgers.point.rows(:, 1), label) & ...
        strcmp(ledgers.point.rows(:, 2), point_label);
      if sum(base_select) ~= 1 || sum(axis_select) ~= 1
        error('run_i4_proxy_rule:PointSelfMultiplicity', ...
          'Expected one base and one %s point row for %s.', ...
          label, point_label);
      end
      base_value = ledgers.point.rows{base_select, 4} + ...
        1i * ledgers.point.rows{base_select, 5};
      axis_value = ledgers.point.rows{axis_select, 4} + ...
        1i * ledgers.point.rows{axis_select, 5};
      maximum = max(maximum, abs(base_value - axis_value));
    end
    axis_pass = maximum <= config.gate.self;
    point_self_pass = point_self_pass && axis_pass;
    ledgers.point_self.rows(end + 1, :) = {label, 'Gx', maximum, ...
      config.gate.self, axis_pass, length(config.point), ...
      'base-to-single-axis change over both frozen points'};
  end
  point_pass = point_pass && point_self_pass;
  if point_pass
    status = 'PILOT_PROXY_POINT_CERTIFIED';
  else
    status = 'PILOT_PROXY_POINT_UNCERTIFIED';
  end
  ledgers.decision.rows(end + 1, :) = {'pilot_point', 'BLOCKER', ...
    status, point_pass, ...
    ['Base Gx Ewald error and every base-to-axis Gx point change are ', ...
    'pilot wall prerequisites.']};
  summary = struct('status', status, 'pass', point_pass, ...
    'authority_pass', authority_pass, 'base_point_pass', base_pass, ...
    'point_self_pass', point_self_pass, ...
    'wall_cost_low_seconds', config.runtime.low_seconds, ...
    'wall_cost_high_seconds', config.runtime.high_seconds);
end

function ledgers = LOCAL_point_rows( ...
    config, authority, ledgers, label, pars, proxy)
  source = [0; 0];
  target = [[config.point.X]; [config.point.Y]];
  [~, Gx] = kernel.qpgreen_mfs_pairmat(source, target, pars, proxy);
  for ip = 1:length(config.point)
    point_label = config.point(ip).label;
    reference = authority.point.(point_label);
    error_value = abs(Gx(ip) - reference) / max(1, abs(reference));
    row_pass = error_value <= config.gate.point;
    mandatory = strcmp(label, 'base');
    ledgers.point.rows(end + 1, :) = {label, point_label, 'Gx', ...
      real(Gx(ip)), imag(Gx(ip)), real(reference), imag(reference), ...
      error_value, abs(Gx(ip) - reference), config.gate.point, row_pass, ...
      config.proxy.(label).N_side, config.proxy.(label).N_top, ...
      config.proxy.(label).N_proxy_edge, config.proxy.(label).M_pw, ...
      mandatory};
  end
end

%% ==================== Exact system and diagnostics ====================
% This group copies package assembly semantics but never supplies a solver.

function [A, b, assembly] = LOCAL_assemble_proxy_system(pars, level, shifted)
  d = pars.d;
  beta = pars.beta;
  k = pars.k;
  H = level.H;
  N_side = level.N_side;
  N_top = level.N_top;
  N_edge = level.N_proxy_edge;
  M_pw = level.M_pw;
  if shifted
    y_side = -H + ((1:N_side).' - 0.5) * (2 * H / N_side);
    x_top = -d / 2 + ((1:N_top).' - 0.5) * (d / N_top);
    y_training = linspace(-H, H, N_side).';
    x_training = linspace(-d / 2, d / 2, N_top).';
    side_distance = min(abs(y_side - y_training.'), [], 'all');
    top_distance = min(abs(x_top - x_training.'), [], 'all');
    if side_distance <= 100 * eps(max(1, H)) || ...
        top_distance <= 100 * eps(max(1, d))
      error('run_i4_proxy_rule:HoldoutNotDisjoint', ...
        'Midpoint hold-out nodes intersect training nodes.');
    end
  else
    y_side = linspace(-H, H, N_side).';
    x_top = linspace(-d / 2, d / 2, N_top).';
  end
  p_L = [-d / 2 * ones(N_side, 1), y_side];
  p_R = [d / 2 * ones(N_side, 1), y_side];
  p_T = [x_top, H * ones(N_top, 1)];
  p_B = [x_top, -H * ones(N_top, 1)];

  x_min = -d / 2 - level.proxy_dist;
  x_max = d / 2 + level.proxy_dist;
  y_min = -H - level.proxy_dist;
  y_max = H + level.proxy_dist;
  tx = linspace(x_min, x_max, N_edge + 1).';
  tx(end) = [];
  ty = linspace(y_min, y_max, N_edge + 1).';
  ty(end) = [];
  px = [tx; repmat(x_max, N_edge, 1); flipud(tx); ...
    repmat(x_min, N_edge, 1)];
  py = [repmat(y_min, N_edge, 1); ty; repmat(y_max, N_edge, 1); ...
    flipud(ty)];
  Z = [px, py];
  N_proxy = size(Z, 1);
  m = (-M_pw:M_pw).';
  beta_m = beta + 2 * pi * m / d;
  gamma_m = LOCAL_rayleigh_branch(k, beta_m);
  N_pw = length(m);

  N_eq = 2 * N_side + 4 * N_top;
  N_unknown = N_proxy + 2 * N_pw;
  A = zeros(N_eq, N_unknown);
  b = zeros(N_eq, 1);
  blocks = LOCAL_blocks(N_side, N_top);
  col_proxy = 1:N_proxy;
  col_up = N_proxy + (1:N_pw);
  col_down = N_proxy + N_pw + (1:N_pw);
  phase = exp(1i * beta * d);
  source = [0, 0];

  [V_sL, dx_sL, ~] = LOCAL_free_space(k, p_L, source);
  [V_sR, dx_sR, ~] = LOCAL_free_space(k, p_R, source);
  b(blocks.LR_value) = -(V_sR - phase * V_sL);
  b(blocks.LR_dx) = -(dx_sR - phase * dx_sL);
  [V_sT, ~, dy_sT] = LOCAL_free_space(k, p_T, source);
  [V_sB, ~, dy_sB] = LOCAL_free_space(k, p_B, source);
  b(blocks.T_value) = -V_sT;
  b(blocks.T_dy) = -dy_sT;
  b(blocks.B_value) = -V_sB;
  b(blocks.B_dy) = -dy_sB;

  [V_pL, dx_pL, ~] = LOCAL_free_space(k, p_L, Z);
  [V_pR, dx_pR, ~] = LOCAL_free_space(k, p_R, Z);
  A(blocks.LR_value, col_proxy) = V_pR - phase * V_pL;
  A(blocks.LR_dx, col_proxy) = dx_pR - phase * dx_pL;
  [V_pT, ~, dy_pT] = LOCAL_free_space(k, p_T, Z);
  [V_pB, ~, dy_pB] = LOCAL_free_space(k, p_B, Z);
  A(blocks.T_value, col_proxy) = V_pT;
  A(blocks.T_dy, col_proxy) = dy_pT;
  A(blocks.B_value, col_proxy) = V_pB;
  A(blocks.B_dy, col_proxy) = dy_pB;
  PW_T = exp(1i * p_T(:, 1) * beta_m.');
  PW_B = exp(1i * p_B(:, 1) * beta_m.');
  A(blocks.T_value, col_up) = -PW_T;
  A(blocks.T_dy, col_up) = -(PW_T .* (1i * gamma_m.'));
  A(blocks.B_value, col_down) = -PW_B;
  A(blocks.B_dy, col_down) = -(PW_B .* (-1i * gamma_m.'));
  assembly = struct('blocks', blocks, 'Z', Z.', 'm', m, ...
    'beta_m', beta_m, 'gamma_m', gamma_m, 'N_proxy', N_proxy, ...
    'N_pw', N_pw, 'N_eq', N_eq, 'N_unknown', N_unknown, ...
    'shifted', shifted);
end

function blocks = LOCAL_blocks(N_side, N_top)
  blocks.LR_value = 1:N_side;
  blocks.LR_dx = N_side + (1:N_side);
  blocks.T_value = 2 * N_side + (1:N_top);
  blocks.T_dy = 2 * N_side + N_top + (1:N_top);
  blocks.B_value = 2 * N_side + 2 * N_top + (1:N_top);
  blocks.B_dy = 2 * N_side + 3 * N_top + (1:N_top);
end

function ledgers = LOCAL_system_diagnostics( ...
    config, ledgers, label, level, A, b, assembly, coefficients, grid)
  ledgers = LOCAL_residual_rows(config, ledgers, label, level, A, b, ...
    assembly.blocks, coefficients, grid);
  singular_values = svd(A, 'econ');
  sigma_max = singular_values(1);
  sigma_min = singular_values(end);
  tolerance = max(size(A)) * eps(sigma_max);
  numerical_rank = sum(singular_values > tolerance);
  for j = 1:length(singular_values)
    ledgers.singular.rows(end + 1, :) = {label, j, ...
      singular_values(j), singular_values(j) / sigma_max, tolerance, ...
      numerical_rank, size(A, 1), size(A, 2)};
  end
  ledgers.spectrum.rows(end + 1, :) = {label, size(A, 1), size(A, 2), ...
    size(A, 1) / size(A, 2), sigma_max, sigma_min, ...
    sigma_min / sigma_max, tolerance, numerical_rank, ...
    numerical_rank / size(A, 2), norm(coefficients), ...
    norm(A * coefficients - b) / max(norm(b), eps), ...
    level.N_side, level.N_top, level.N_proxy_edge, level.M_pw};
end

function ledgers = LOCAL_residual_rows( ...
    ~, ledgers, label, level, A, b, blocks, coefficients, grid)
  residual = A * coefficients - b;
  names = fieldnames(blocks);
  for ib = 1:length(names)
    name = names{ib};
    index = blocks.(name);
    rel_l2 = norm(residual(index)) / max(norm(b(index)), eps);
    abs_inf = max(abs(residual(index)));
    rel_inf = abs_inf / max(max(abs(b(index))), eps);
    ledgers.residual.rows(end + 1, :) = {label, grid, name, ...
      rel_l2, abs_inf, rel_inf, length(index), level.N_side, ...
      level.N_top, level.N_proxy_edge, level.M_pw, ...
      strcmp(grid, 'holdout')};
  end
end

function ledgers = LOCAL_coefficient_diagnostics( ...
    config, ledgers, label, level, proxy, coefficients)
  q = proxy.q(:);
  N_edge = level.N_proxy_edge;
  threshold = ceil((1 - config.proxy_edge_tail_fraction) * N_edge / 2);
  for edge = 1:4
    index = (edge - 1) * N_edge + (1:N_edge);
    spectrum = fftshift(fft(q(index))) / N_edge;
    frequencies = (-floor(N_edge / 2):ceil(N_edge / 2) - 1).';
    tail = abs(frequencies) >= threshold;
    max_tail = max(abs(spectrum(tail)));
    energy_ratio = norm(spectrum(tail)) / max(norm(spectrum), eps);
    ledgers.coefficient_diag.rows(end + 1, :) = {label, ...
      sprintf('proxy_edge_%d', edge), max_tail, energy_ratio, ...
      norm(q(index)), abs(q(1) - q(end)), abs(q(1) + q(end)), ...
      norm(proxy.Z(:, 1) - proxy.Z(:, end)), level.N_side, ...
      level.N_top, N_edge, level.M_pw, norm(coefficients)};
  end
  m = (-level.M_pw:level.M_pw).';
  tail = abs(m) > level.M_pw - config.internal_pw_tail_width;
  for side_cell = {'up', 'down'}
    side = side_cell{1};
    values = proxy.C_up(:);
    if strcmp(side, 'down')
      values = proxy.C_down(:);
    end
    ledgers.coefficient_diag.rows(end + 1, :) = {label, ...
      ['internal_pw_', side], max(abs(values(tail))), ...
      norm(values(tail)) / max(norm(values), eps), norm(values), ...
      abs(q(1) - q(end)), abs(q(1) + q(end)), ...
      norm(proxy.Z(:, 1) - proxy.Z(:, end)), ...
      level.N_side, level.N_top, N_edge, level.M_pw, ...
      norm(coefficients)};
  end
end

function coefficients = LOCAL_proxy_coefficients(proxy)
  coefficients = [proxy.q(:); proxy.C_up(:); proxy.C_down(:)];
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

%% ==================== Staged wall actions ====================
% These helpers form only SLP-D and SLP-N and enforce first-failure stopping.

function [summary, ledgers] = LOCAL_full( ...
    config, authority, proxies, pilot, ledgers, log_fid)
  level_labels = config.level_order;
  wall = struct();
  token = tic;
  wall.base = LOCAL_wall_level(config, proxies.base, 'base', log_fid);
  ledgers.timings.rows(end + 1, :) = {'wall_base', toc(token), ...
    'two package wall matrices, then two densities and two actions'};
  [base_pass, ledgers] = LOCAL_base_wall_gates( ...
    config, authority, wall.base, ledgers);
  if ~base_pass
    status = 'COMMON_PROXY_BASE_UNCERTIFIED';
    ledgers.decision.rows(end + 1, :) = {'wall_base', 'BLOCKER', ...
      status, 0, 'Base coefficient comparison or output tail failed.'};
    summary = struct('status', status, 'pass', false, ...
      'stop_after', 'base', 'pilot', pilot);
    return;
  end

  ledgers.decision.rows(end + 1, :) = {'wall_base', 'BLOCKER', ...
    'COMMON_PROXY_BASE_CERTIFIED', 1, ...
    'Both SLP-D and SLP-N pass frozen E/P/R coefficient and tail gates.'};
  for il = 2:length(level_labels)
    label = level_labels{il};
    token = tic;
    wall.(label) = LOCAL_wall_level(config, proxies.(label), label, log_fid);
    ledgers.timings.rows(end + 1, :) = {['wall_', label], toc(token), ...
      'one preregistered public package single-axis wall level'};
    [axis_pass, ledgers] = LOCAL_axis_wall_gate(config, wall.base, ...
      wall.(label), label, ledgers);
    if ~axis_pass
      status = ['SLP_ACTION_SELF_UNCERTIFIED_', upper(label)];
      ledgers.decision.rows(end + 1, :) = {['wall_', label], 'BLOCKER', ...
        status, 0, 'First failed axis; later wall levels were not run.'};
      for later = il + 1:length(level_labels)
        ledgers.decision.rows(end + 1, :) = { ...
          ['wall_', level_labels{later}], 'BLOCKER', ...
          'NOT_RUN_PREREQUISITE', 0, ['Stopped after ', label, '.']};
      end
      summary = struct('status', status, 'pass', false, ...
        'stop_after', label, 'pilot', pilot);
      return;
    end
    ledgers.decision.rows(end + 1, :) = {['wall_', label], ...
      'BLOCKER', ['SLP_D_N_', upper(label), '_SELF_CERTIFIED'], 1, ...
      'Both densities, both walls, and every retained mode are within gate.'};
  end
  status = 'SLP_D_N_CERTIFIED_PROXY_RATIO_0P2';
  ledgers.decision.rows(end + 1, :) = {'SLP-D/SLP-N', 'BLOCKER', ...
    status, 1, 'One common public package proxy configuration is certified.'};
  summary = struct('status', status, 'pass', true, ...
    'stop_after', '', 'pilot', pilot);
end

function data = LOCAL_wall_level(config, proxy, label, log_fid)
  pars = LOCAL_pars(config);
  [source, weights] = LOCAL_circle(config);
  y = config.d * (0:config.Ny - 1) / config.Ny;
  target_L = [config.X_L * ones(1, config.Ny); y];
  target_R = [config.X_R * ones(1, config.Ny); y];
  channels = LOCAL_channels(config);
  targets = {target_L, target_R};
  sides = {'L', 'R'};
  normals = [-1, 1];
  for is = 1:2
    token = tic;
    [G, Gx] = kernel.qpgreen_mfs_pairmat(source, targets{is}, pars, proxy);
    LOCAL_log(log_fid, 'wall level=%s side=%s pairs=%d seconds=%.6f\n', ...
      label, sides{is}, numel(G), toc(token));
    for id = 1:length(config.density)
      density_label = config.density(id).label;
      rho = LOCAL_density(config.density(id), config.ntot);
      weighted = rho .* weights;
      wall_D = -G * weighted;
      wall_N = -(normals(is) * Gx) * weighted;
      data.SLP_D.(density_label).(sides{is}) = ...
        LOCAL_fourier_project(config, channels, y, wall_D);
      data.SLP_N.(density_label).(sides{is}) = ...
        LOCAL_fourier_project(config, channels, y, wall_N);
    end
  end
  data.label = label;
  data.channels = channels;
end

function [pass, ledgers] = LOCAL_base_wall_gates( ...
    config, authority, data, ledgers)
  pass = true;
  pairs = {'E', 'P'; 'E', 'R'; 'P', 'R'};
  for ia = 1:length(config.actions)
    action = config.actions{ia};
    field = strrep(action, '-', '_');
    action_pair_pass = true;
    for id = 1:length(config.density)
      density = config.density(id).label;
      for side_cell = {'L', 'R'}
        side = side_cell{1};
        P = data.(field).(density).(side);
        for im = 1:length(data.channels.m)
          m = data.channels.m(im);
          E = LOCAL_authority_value(authority.coefficient, action, ...
            density, side, m, 'E');
          R = LOCAL_authority_value(authority.coefficient, action, ...
            density, side, m, 'R');
          values = struct('E', E, 'P', P(im), 'R', R);
          for ip = 1:size(pairs, 1)
            left_path = pairs{ip, 1};
            right_path = pairs{ip, 2};
            left = values.(left_path);
            right = values.(right_path);
            absolute_error = abs(left - right);
            relative_error = absolute_error / max([abs(left), ...
              abs(right), config.relative_floor]);
            row_pass = absolute_error <= config.gate.coefficient;
            action_pair_pass = action_pair_pass && row_pass;
            ledgers.wall.rows(end + 1, :) = {'base', action, density, ...
              side, m, left_path, right_path, real(left), imag(left), ...
              real(right), imag(right), absolute_error, relative_error, ...
              config.gate.coefficient, row_pass, 'coefficient'};
          end
        end
      end
    end
    tail = LOCAL_output_tail(config, data, action);
    tail_pass = tail <= config.gate.output_tail;
    pass = pass && action_pair_pass && tail_pass;
    ledgers.action.rows(end + 1, :) = {action, 'base_pairwise', ...
      LOCAL_max_pair_error(ledgers.wall.rows, action, 'base'), ...
      config.gate.coefficient, action_pair_pass, ...
      'maximum raw coefficient error over E-P, E-R, and P-R'};
    ledgers.action.rows(end + 1, :) = {action, 'output_tail', tail, ...
      config.gate.output_tail, tail_pass, ...
      'maximum P coefficient in 24<abs(m)<=48'};
  end
end

function [pass, ledgers] = LOCAL_axis_wall_gate( ...
    config, base, refined, label, ledgers)
  pass = true;
  for ia = 1:length(config.actions)
    action = config.actions{ia};
    field = strrep(action, '-', '_');
    maximum = 0;
    for id = 1:length(config.density)
      density = config.density(id).label;
      for side_cell = {'L', 'R'}
        side = side_cell{1};
        a = base.(field).(density).(side);
        b = refined.(field).(density).(side);
        for im = 1:length(base.channels.m)
          error_value = abs(a(im) - b(im));
          maximum = max(maximum, error_value);
          relative_error = error_value / max([abs(a(im)), abs(b(im)), ...
            config.relative_floor]);
          row_pass = error_value <= config.gate.self;
          ledgers.wall.rows(end + 1, :) = {label, action, density, ...
            side, base.channels.m(im), 'P_base', ['P_', label], ...
            real(a(im)), imag(a(im)), real(b(im)), imag(b(im)), ...
            error_value, relative_error, config.gate.self, row_pass, ...
            'single_axis_self'};
        end
      end
    end
    action_pass = maximum <= config.gate.self;
    pass = pass && action_pass;
    ledgers.action.rows(end + 1, :) = {action, [label, '_self'], ...
      maximum, config.gate.self, action_pass, ...
      'maximum base-to-axis raw P coefficient change'};
  end
end

function maximum = LOCAL_max_pair_error(rows, action, label)
  maximum = 0;
  for j = 1:size(rows, 1)
    if strcmp(rows{j, 1}, label) && strcmp(rows{j, 2}, action) && ...
        strcmp(rows{j, 16}, 'coefficient')
      maximum = max(maximum, rows{j, 12});
    end
  end
end

function tail = LOCAL_output_tail(config, data, action)
  field = strrep(action, '-', '_');
  band = abs(data.channels.m) > config.output_tail_cutoff & ...
    abs(data.channels.m) <= config.M_trace;
  tail = 0;
  for id = 1:length(config.density)
    density = config.density(id).label;
    for side_cell = {'L', 'R'}
      side = side_cell{1};
      value = data.(field).(density).(side);
      tail = max(tail, max(abs(value(band))));
    end
  end
end

function [source, weights] = LOCAL_circle(config)
  theta = 2 * pi * (0:config.ntot - 1).' / config.ntot;
  source = [config.R * cos(theta).'; config.R * sin(theta).'];
  weights = (2 * pi / config.ntot) * config.R * ones(config.ntot, 1);
end

function density = LOCAL_density(item, ntot)
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  density = zeros(ntot, 1);
  for j = 1:length(item.ell)
    density = density + item.coeff(j) * exp(1i * item.ell(j) * theta);
  end
end

function channels = LOCAL_channels(config)
  channels.m = (-config.M_trace:config.M_trace).';
  channels.beta_m = config.beta + 2 * pi * channels.m / config.d;
  channels.gamma_m = LOCAL_rayleigh_branch(config.k, channels.beta_m);
end

function gamma = LOCAL_rayleigh_branch(k, beta_m)
  gamma = sqrt(complex(k ^ 2 - beta_m .^ 2));
  flip = imag(gamma) < 0 | (imag(gamma) == 0 & real(gamma) < 0);
  gamma(flip) = -gamma(flip);
end

function coefficients = LOCAL_fourier_project(config, channels, y, values)
  basis = (1 / sqrt(config.d)) * ...
    exp(-1i * (channels.beta_m(:) * y));
  coefficients = (config.d / length(y)) * basis * values(:);
end

%% ==================== Frozen authorities and provenance ====================
% These helpers verify and read prior Ewald/Rayleigh and Ewald-point values.

function [authority, ledgers, pass] = LOCAL_load_authority(config, ledgers)
  coefficient_hash = LOCAL_sha256(config.authority.coefficient_csv);
  point_hash = LOCAL_sha256(config.authority.point_csv);
  coefficient_pass = strcmp(coefficient_hash, ...
    config.authority.coefficient_sha256);
  point_pass = strcmp(point_hash, config.authority.point_sha256);
  pass = coefficient_pass && point_pass;
  ledgers.metadata.rows(end + 1, :) = {'coefficient_authority_sha256', ...
    coefficient_hash, config.authority.coefficient_sha256, ...
    coefficient_pass, config.authority.coefficient_csv};
  ledgers.metadata.rows(end + 1, :) = {'point_authority_sha256', ...
    point_hash, config.authority.point_sha256, point_pass, ...
    config.authority.point_csv};
  if ~pass
    authority = struct();
    ledgers.decision.rows(end + 1, :) = {'authority', 'BLOCKER', ...
      'FROZEN_AUTHORITY_HASH_MISMATCH', 0, ...
      'An immutable prior CSV changed; experiment is not interpretable.'};
    return;
  end
  authority.coefficient = readtable(config.authority.coefficient_csv, ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
  point_table = readtable(config.authority.point_csv, ...
    'TextType', 'string', 'VariableNamingRule', 'preserve');
  for ip = 1:length(config.point)
    label = string(config.point(ip).label);
    select = point_table.stage == "stage0_known_failure" & ...
      point_table.point == label & point_table.component == "Gx" & ...
      point_table.right_method == "Ewald_joint";
    if sum(select) ~= 1
      error('run_i4_proxy_rule:PointAuthorityMultiplicity', ...
        'Expected one Ewald Gx reference for %s.', label);
    end
    value = point_table.right_re(select) + 1i * point_table.right_im(select);
    authority.point.(char(label)) = value;
  end
  ledgers.decision.rows(end + 1, :) = {'authority', 'BLOCKER', ...
    'FROZEN_AUTHORITIES_VERIFIED', 1, ...
    'SHA-256 verified before reading E/R coefficients or Ewald Gx points.'};
end

function [pass, ledgers] = LOCAL_preflight(config, ledgers)
  is_matlab = exist('OCTAVE_VERSION', 'builtin') == 0;
  solver_path = which('lsqminnorm');
  solver_pass = is_matlab && ~isempty(solver_path);
  expected_precomp = fullfile(config.repo_root, '+kernel', ...
    'precomp_proxy.m');
  expected_pairmat = fullfile(config.repo_root, '+kernel', ...
    'qpgreen_mfs_pairmat.m');
  observed_precomp = which('kernel.precomp_proxy');
  observed_pairmat = which('kernel.qpgreen_mfs_pairmat');
  path_pass = strcmp(observed_precomp, expected_precomp) && ...
    strcmp(observed_pairmat, expected_pairmat);
  precomp_hash = LOCAL_sha256(expected_precomp);
  pairmat_hash = LOCAL_sha256(expected_pairmat);
  hash_pass = strcmp(precomp_hash, config.package.precomp_proxy_sha256) && ...
    strcmp(pairmat_hash, config.package.pairmat_sha256);
  pass = solver_pass && path_pass && hash_pass;
  ledgers.metadata.rows(end + 1, :) = {'runtime_and_solver', ...
    [LOCAL_runtime_name(), '|', solver_path], 'MATLAB|nonempty lsqminnorm', ...
    solver_pass, 'Octave pinv is forbidden as scientific authority.'};
  ledgers.metadata.rows(end + 1, :) = {'precomp_proxy_path', ...
    observed_precomp, expected_precomp, path_pass, precomp_hash};
  ledgers.metadata.rows(end + 1, :) = {'pairmat_path', observed_pairmat, ...
    expected_pairmat, path_pass, pairmat_hash};
  ledgers.metadata.rows(end + 1, :) = {'package_hashes', ...
    [precomp_hash, '|', pairmat_hash], ...
    [config.package.precomp_proxy_sha256, '|', ...
    config.package.pairmat_sha256], hash_pass, ...
    'Both public package files are locked before the pilot.'};
  ledgers.decision.rows(end + 1, :) = {'runtime_package_preflight', ...
    'BLOCKER', LOCAL_status(pass, 'MATLAB_LSQMINNORM_PACKAGE_VERIFIED', ...
    'MATLAB_LSQMINNORM_PACKAGE_UNCERTIFIED'), pass, ...
    'Requires MATLAB, lsqminnorm, expected package paths, and exact hashes.'};
end

function name = LOCAL_runtime_name()
  if exist('OCTAVE_VERSION', 'builtin') ~= 0
    name = 'Octave';
  else
    name = 'MATLAB';
  end
end

function status = LOCAL_status(pass, pass_status, fail_status)
  if pass
    status = pass_status;
  else
    status = fail_status;
  end
end

function value = LOCAL_authority_value(table_data, action, density, side, m, path)
  layer = string(action(1:3));
  trace = string(action(end));
  select = table_data.level == "authority" & ...
    table_data.density == string(density) & ...
    table_data.layer == layer & table_data.side == string(side) & ...
    table_data.trace == trace & table_data.m == m & ...
    table_data.left_path == "E" & table_data.right_path == "R" & ...
    table_data.normalization == "raw";
  if sum(select) ~= 1
    error('run_i4_proxy_rule:CoefficientAuthorityMultiplicity', ...
      'Expected one E/R row for %s %s %s m=%d.', ...
      action, density, side, m);
  end
  if strcmp(path, 'E')
    value = table_data.left_re(select) + 1i * table_data.left_im(select);
  elseif strcmp(path, 'R')
    value = table_data.right_re(select) + 1i * table_data.right_im(select);
  else
    error('run_i4_proxy_rule:InvalidAuthorityPath', ...
      'Authority path must be E or R.');
  end
end

function hash = LOCAL_sha256(path)
  quoted = strrep(path, '"', '\"');
  [status, output] = system(sprintf('shasum -a 256 "%s"', quoted));
  token = regexp(lower(output), '[0-9a-f]{64}', 'match', 'once');
  if status ~= 0 || isempty(token)
    error('run_i4_proxy_rule:SHA256Failed', ...
      'Could not compute SHA-256 for %s.', path);
  end
  hash = token;
end

function pars = LOCAL_pars(config)
  pars = struct('k', config.k, 'beta', config.beta, 'd', config.d, ...
    'periodic_axis', 'y');
end

function provenance = LOCAL_provenance(config)
  provenance.runtime = 'MATLAB';
  if exist('OCTAVE_VERSION', 'builtin') ~= 0
    provenance.runtime = 'Octave';
  end
  provenance.version = version;
  provenance.lsqminnorm = which('lsqminnorm');
  provenance.precomp_proxy = which('kernel.precomp_proxy');
  provenance.pairmat = which('kernel.qpgreen_mfs_pairmat');
  provenance.driver = mfilename('fullpath');
  provenance.driver_sha256 = LOCAL_sha256([provenance.driver, '.m']);
  provenance.config = which('i4_proxy_rule_config');
  provenance.config_sha256 = LOCAL_sha256(provenance.config);
  provenance.repo_root = config.repo_root;
end

%% ==================== Ledgers and artifacts ====================
% These helpers save complete evidence, reports, logs, and runtime estimates.

function ledgers = LOCAL_empty_ledgers()
  ledgers.metadata = LOCAL_ledger({'key', 'observed', 'expected', ...
    'pass', 'note'});
  ledgers.point = LOCAL_ledger({'level', 'point', 'component', ...
    'value_re', 'value_im', 'reference_re', 'reference_im', ...
    'normalized_error', 'absolute_error', 'gate', 'pass', 'Nside', ...
      'Ntop', 'Nedge', 'Mpw', 'mandatory'});
  ledgers.point_self = LOCAL_ledger({'level', 'component', ...
    'maximum_change', 'gate', 'pass', 'point_count', 'note'});
  ledgers.residual = LOCAL_ledger({'level', 'grid', 'block', ...
    'relative_l2', 'absolute_linf', 'relative_linf', 'row_count', ...
    'Nside', 'Ntop', 'Nedge', 'Mpw', 'independent_holdout'});
  ledgers.spectrum = LOCAL_ledger({'level', 'equations', 'unknowns', ...
    'oversampling_ratio', 'sigma_max', 'sigma_min', 'sigma_ratio', ...
    'rank_tolerance', 'numerical_rank', 'rank_fraction', ...
    'coefficient_norm', 'system_relative_residual', 'Nside', 'Ntop', ...
    'Nedge', 'Mpw'});
  ledgers.singular = LOCAL_ledger({'level', 'index', 'singular_value', ...
    'relative_value', 'rank_tolerance', 'numerical_rank', 'equations', ...
    'unknowns'});
  ledgers.coefficient_diag = LOCAL_ledger({'level', 'block', ...
    'tail_max_abs', 'tail_energy_ratio', 'block_norm', ...
    'q_first_last_difference', 'q_first_plus_last', ...
    'source_first_last_distance', 'Nside', ...
    'Ntop', 'Nedge', 'Mpw', 'full_coefficient_norm'});
  ledgers.wall = LOCAL_ledger({'level', 'action', 'density', 'side', 'm', ...
    'left_path', 'right_path', 'left_re', 'left_im', 'right_re', ...
    'right_im', 'absolute_error', 'floored_relative_error', 'gate', ...
    'pass', 'comparison'});
  ledgers.action = LOCAL_ledger({'action', 'test', 'maximum', 'gate', ...
    'pass', 'note'});
  ledgers.decision = LOCAL_ledger({'stage', 'classification', 'status', ...
    'pass', 'note'});
  ledgers.timings = LOCAL_ledger({'stage', 'seconds', 'note'});
end

function ledger = LOCAL_ledger(headers)
  ledger = struct('headers', {headers}, ...
    'rows', {cell(0, length(headers))});
end

function LOCAL_write_runtime_estimate(output_dir, config, pilot)
  path = fullfile(output_dir, 'runtime-estimate.md');
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_proxy_rule:EstimateOpenFailed', ...
      'Could not write runtime estimate.');
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# Preregistered wall runtime estimate\n\n');
  fprintf(fid, '- Wall matrices constructed in this mode: `0` before full.\n');
  fprintf(fid, '- Estimated full five-level cost: `%.0f--%.0f s`.\n', ...
    config.runtime.low_seconds, config.runtime.high_seconds);
  fprintf(fid, '- First-failure stopping: `%s`\n', config.runtime.stop_rule);
  fprintf(fid, '- Pilot prerequisite pass: `%d`\n', pilot.pass);
  fprintf(fid, ['- Basis of estimate: prior MATLAB R2023b P-wall timings ', ...
    'at the same `ntot=256`, `Ny=512`; no new wall timing was sampled.\n']);
  clear cleanup;
end

function LOCAL_write_artifacts(output_dir, results)
  ledgers = results.ledgers;
  names = fieldnames(ledgers);
  for j = 1:length(names)
    name = names{j};
    filename = [strrep(name, '_', '-'), '.csv'];
    LOCAL_write_csv(fullfile(output_dir, filename), ...
      ledgers.(name).headers, ledgers.(name).rows);
  end
  save(fullfile(output_dir, 'results.mat'), 'results');
  LOCAL_write_report(fullfile(output_dir, 'report.md'), results);
end

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_proxy_rule:CSVOpenFailed', 'Could not write %s.', path);
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
      if isempty(value)
        fprintf(fid, '');
      else
        fprintf(fid, '%.17g', value);
      end
    else
      text = char(string(value));
      text = strrep(text, '"', '""');
      fprintf(fid, '"%s"', text);
    end
  end
  fprintf(fid, '\n');
end

function LOCAL_write_report(path, results)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_proxy_rule:ReportOpenFailed', ...
      'Could not write report.md.');
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# I4 proxy-rule report\n\n');
  fprintf(fid, '- Mode: `%s`\n', results.mode);
  fprintf(fid, '- Status: `%s`\n', results.status);
  fprintf(fid, '- Pass: `%d`\n', results.pass);
  fprintf(fid, '- Runtime: `%.6f s`\n', results.total_seconds);
  fprintf(fid, '- Backend: `%s %s`\n', results.provenance.runtime, ...
    results.provenance.version);
  fprintf(fid, '- Public solver: `%s`\n', results.provenance.lsqminnorm);
  fprintf(fid, '- Driver SHA-256: `%s`\n', ...
    results.provenance.driver_sha256);
  fprintf(fid, '- Config SHA-256: `%s`\n', ...
    results.provenance.config_sha256);
  fprintf(fid, '- Sole proxy ratio: `%.17g`\n', ...
    results.config.proxy_dist / results.config.d);
  fprintf(fid, '- Singularity margin: `%.17g`\n', ...
    results.config.singularity_margin);
  fprintf(fid, '- Wood distance metadata: `%.17g`\n\n', ...
    results.config.wood_distance);
  fprintf(fid, '## Decisions\n\n');
  fprintf(fid, '| Stage | Classification | Status | Pass | Note |\n');
  fprintf(fid, '|---|---|---|---:|---|\n');
  rows = results.ledgers.decision.rows;
  for j = 1:size(rows, 1)
    fprintf(fid, '| %s | %s | %s | %d | %s |\n', ...
      rows{j, 1}, rows{j, 2}, rows{j, 3}, rows{j, 4}, rows{j, 5});
  end
  fprintf(fid, '\n## Reproduction\n\n```matlab\n');
  fprintf(fid, 'addpath(fullfile(pwd,''test'',''i4-proxy-rule''));\n');
  fprintf(fid, 'run_i4_proxy_rule(''%s'');\n', results.mode);
  fprintf(fid, '```\n');
  clear cleanup;
end

function LOCAL_log(fid, varargin)
  fprintf(fid, varargin{:});
  fprintf(varargin{:});
end
