function varargout = empty_defect_scan_local()
% EMPTY_DEFECT_SCAN_LOCAL Recursively scan an empty-defect Bloch matching system.
%
% Purpose:
%   Run a recursive local real-k scan for the missing-column /
%   empty-defect-cell cavity problem.  The center cell is homogeneous
%   background material, and the positive and negative half-leads are
%   identical periodic cells with a circular dielectric inclusion.
%
% Mathematical problem:
%   The center empty cell occupies X0_minus <= x <= X0_plus and is expanded
%   in the y-quasiperiodic Rayleigh basis.  The left/right notation L/R is
%   reserved for the walls of one lead cell.  The port signs +/- denote the
%   center positive/negative ports and the positive/negative half-leads.
%
% Unknown vector:
%   The homogeneous system uses
%
%     [c_plus; c_minus; a_minus; a_plus].
%
%   Here c_plus and c_minus are right-going and left-going Rayleigh
%   coefficients in the center empty cell.  They do not denote positive and
%   negative half-leads.
%
% Matrix formula:
%   Let K = 2*M + 1, Gamma = diag(gamma_m),
%
%     E = diag(exp(1i*gamma_m*L0)),  E_inv = inv(E),
%     L0 = X0_plus - X0_minus.
%
%   The center empty-cell traces are
%
%     D0_minus = c_plus + c_minus,
%     N0_minus = -1i*Gamma*(c_plus - c_minus),
%     D0_plus  = E*c_plus + E_inv*c_minus,
%     N0_plus  = 1i*Gamma*(E*c_plus - E_inv*c_minus).
%
%   Matching these traces to selected outgoing lead traces gives
%
%     D0_minus = D_out_minus*a_minus,
%     N0_minus = N_out_minus*a_minus,
%     D0_plus  = D_out_plus*a_plus,
%     N0_plus  = N_out_plus*a_plus.
%
%   Therefore the assembled matrix is
%
%     A_def =
%       [ I,           I,             -D_out_minus,   0;
%        -1i*Gamma,   1i*Gamma,      -N_out_minus,   0;
%         E,           E_inv,          0,            -D_out_plus;
%         1i*Gamma*E, -1i*Gamma*E_inv, 0,            -N_out_plus ].
%
% Scan target:
%   Use +scan to first sample sigma_min = min(svd(A_def)) on a coarse real-k
%   grid inside [k_margin, beta - k_margin], then select a dip interval and
%   recursively refine it.  Rectangular A_def matrices are allowed and use
%   the same smallest-singular-value definition.

  format long;

  % --- stage 1: set user parameters ---

  params = LOCAL_default_params();
  LOCAL_validate_params(params);
  LOCAL_print_run_header(params);

  % --- stage 2: build lead geometry and objective context ---

  geom_data = LOCAL_build_lead_geometry(params);
  ctx = params;
  ctx.geom_data = geom_data;
  objective = @(k_real) LOCAL_empty_defect_sigma_min(k_real, ctx);

  scan_opts = scan.default_options( ...
    'min_refine_level', params.max_refine_level, ...
    'max_refine_level', params.max_refine_level, ...
    'num_initial_points', params.num_k, ...
    'num_refine_points', params.num_k, ...
    'dip_select', 'global_min', ...
    'include_endpoint_dips', true, ...
    'ignore_nan', true, ...
    'verbose', false);

  % --- stage 3: coarse scan, dip selection, and local refinement ---

  [result, coarse, history] = scan.scan_then_refine(objective, ...
    params.initial_interval, scan_opts);

  % --- stage 6: compute singular values and report candidates ---

  scan.print_summary(result, history, 'empty-defect local scan');
  if result.success
    fprintf('\nFinal best result: level %d, k_real = %.16f, eps_k = %.6e, sigma_min = %.16e\n', ...
      result.best_level, result.best_x, params.eps_k, result.best_value);
  end

  % --- stage 7: plot scan result ---

  LOCAL_plot_scan_result(coarse, history, params);

  fprintf('\nFinished recursive empty-defect scan.\n');

  if nargout > 0
    varargout{1} = result;
  end
  if nargout > 1
    varargout{2} = coarse;
  end
  if nargout > 2
    varargout{3} = history;
  end

end

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================

function params = LOCAL_default_params()

  % Circular inclusion discretization for each periodic lead cell.
  params.ntot = 40;
  params.flag_geom = 'circle';
  params.radius = 0.3;

  % Exterior/background and interior refractive-index ratio for the lead
  % cylinder.  The empty defect cell uses only the exterior/background medium.
  params.n = 1.5;

  % Physical periods.  L is the x-period of one lead cell and d is the
  % y-period used by the quasiperiodic Rayleigh basis.
  params.L = 2.0;
  params.d = 2 * pi;

  % Fixed y-quasiperiodic parameter.  The real-k scan below stays below beta
  % by k_margin to avoid the first light-line endpoint.
  params.beta = 0.4;
  params.k_margin = 1e-3;

  % Future absorption can use kext = k_real + 1i*eps_k.  The present scan is
  % purely real, matching the first local empty-defect smoke test.
  params.eps_k = 0;

  % Rayleigh truncation half-width.  M = 2 gives K = 5.
  params.M = 2;

  % Recursive scan controls.  num_k is kept odd so each refinement level has
  % a clear center sample when the dip is not at an endpoint.
  params.num_k = 9;
  params.max_refine_level = 4;

  % Lead-cell and center-empty-cell wall coordinates.  L/R denotes lead-cell
  % walls only; +/- denotes center ports and half-leads.
  params.X_L = -params.L / 2;
  params.X_R = params.L / 2;
  params.X0_minus = -params.L / 2;
  params.X0_plus = params.L / 2;
  params.L0 = params.X0_plus - params.X0_minus;

  % Quasi-periodic Green parameters.  For physical y-periodicity,
  % precomp_proxy sees the swapped computational coordinates used by
  % kernel.qpgreen_mfs.
  params.pars1.beta = params.beta;
  params.pars1.d = params.d;
  params.pars1.periodic_axis = 'y';
  params.pars2.H = params.L / 2 + params.radius + 0.4;
  params.pars2.proxy_dist = 0.7;
  params.pars2.N_side = 40;
  params.pars2.N_top = 40;
  params.pars2.N_proxy_edge = 24;
  params.pars2.M_pw = 8;

  % Mode-selection tolerance for outgoing half-lead traces.
  params.opts.lambda_tol = 1e-8;

  params.initial_interval = [params.k_margin, params.beta - params.k_margin];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_params(params)

  if params.initial_interval(2) <= params.initial_interval(1)
    error('empty_defect_scan_local:InvalidScanInterval', ...
      'beta must be larger than 2*k_margin.');
  end
  if params.num_k < 2 || params.num_k ~= floor(params.num_k)
    error('empty_defect_scan_local:InvalidNumK', ...
      'num_k must be an integer at least 2.');
  end
  if params.max_refine_level < 1 || ...
      params.max_refine_level ~= floor(params.max_refine_level)
    error('empty_defect_scan_local:InvalidMaxRefineLevel', ...
      'max_refine_level must be a positive integer.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_run_header(params)

  fprintf('Running recursive empty-defect local scan\n');
  fprintf('  beta = %.16g, L = %.16g, d = %.16g\n', ...
    params.beta, params.L, params.d);
  fprintf('  M = %d, ntot = %d, num_k = %d, max_refine_level = %d\n', ...
    params.M, params.ntot, params.num_k, params.max_refine_level);
  fprintf('  k_margin = %.3e, eps_k = %.3e\n', ...
    params.k_margin, params.eps_k);
  fprintf('  initial interval = [%.16g, %.16g]\n', ...
    params.initial_interval(1), params.initial_interval(2));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function geom_data = LOCAL_build_lead_geometry(params)

  [C, curvelen, ~, ~] = geom.construct_cont(params.ntot, ...
    params.flag_geom, 0, 0, params.radius);

  geom_data.C = C;
  geom_data.curvelen = curvelen;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [sigma_min, info] = LOCAL_empty_defect_sigma_min(k_real, ctx)

  info = LOCAL_empty_point_info();
  info.status = 'ok';

  kext = k_real + 1i * ctx.eps_k;
  kint = ctx.n * kext;
  pars1 = ctx.pars1;
  pars1.k = kext;
  proxy = kernel.precomp_proxy(pars1, ctx.pars2);
  rayleighchan = bloch.rayleigh_channels(kext, ctx.beta, ctx.d, ctx.M, ctx.L);
  K = rayleighchan.K;

  % --- stage 4: construct Bloch modes and select port traces ---

  S_cell = bloch.construct_S(ctx.geom_data.C, kext, kint, pars1, proxy, ...
    ctx.geom_data.curvelen, rayleighchan, ctx.X_L, ctx.X_R);
  modes = bloch.solve_modes(S_cell);
  traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);
  [D_out_plus, N_out_plus, selected_plus] = ...
    bloch.select_port_traces(modes, traces, '+', ctx.opts);
  [D_out_minus, N_out_minus, selected_minus] = ...
    bloch.select_port_traces(modes, traces, '-', ctx.opts);

  info.K = K;
  info.K_out_plus = selected_plus.numSelected;
  info.K_out_minus = selected_minus.numSelected;

  if info.K_out_plus == 0 || info.K_out_minus == 0
    info.status = 'empty';
    sigma_min = NaN;
    return;
  end

  if info.K_out_plus ~= K || info.K_out_minus ~= K
    info.status = 'rect';
    warning('empty_defect_scan_local:UnexpectedModeCount', ...
      'k = %.16g selected [%d,%d] outgoing modes instead of [%d,%d].', ...
      k_real, info.K_out_plus, info.K_out_minus, K, K);
  end

  % --- stage 5: assemble empty-defect matrix ---

  A_def = LOCAL_assemble_empty_defect_matrix(rayleighchan, ctx.L0, ...
    D_out_minus, N_out_minus, D_out_plus, N_out_plus);
  expected_size = [4 * K, 2 * K + info.K_out_minus + info.K_out_plus];
  A_size = size(A_def);
  info.A_rows = A_size(1);
  info.A_cols = A_size(2);

  if ~isequal(A_size, expected_size)
    info.status = 'badsize';
    sigma_min = NaN;
    return;
  end

  % --- stage 6: compute singular values and report candidates ---

  s = svd(A_def);
  if isempty(s)
    info.status = 'emptysvd';
    sigma_min = NaN;
  else
    sigma_min = min(s);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A_def = LOCAL_assemble_empty_defect_matrix(rayleighchan, L0, ...
    D_out_minus, N_out_minus, D_out_plus, N_out_plus)

  K = rayleighchan.K;
  K_out_minus = size(D_out_minus, 2);
  K_out_plus = size(D_out_plus, 2);
  Gamma = diag(rayleighchan.gamma_m(:));
  E = diag(exp(1i * rayleighchan.gamma_m(:) * L0));
  E_inv = diag(exp(-1i * rayleighchan.gamma_m(:) * L0));
  I_K = eye(K);
  Z_minus = zeros(K, K_out_minus);
  Z_plus = zeros(K, K_out_plus);

  A_def = [
    I_K, I_K, -D_out_minus, Z_plus;
    -1i * Gamma, 1i * Gamma, -N_out_minus, Z_plus;
    E, E_inv, Z_minus, -D_out_plus;
    1i * Gamma * E, -1i * Gamma * E_inv, Z_minus, -N_out_plus
  ];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function info = LOCAL_empty_point_info()

  info = struct( ...
    'K', NaN, ...
    'K_out_plus', NaN, ...
    'K_out_minus', NaN, ...
    'A_rows', NaN, ...
    'A_cols', NaN, ...
    'status', 'unset');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_scan_result(coarse, history, params)

  figure('Name', 'Empty Defect Recursive Scan', 'Color', 'w');
  hold on;

  semilogy(coarse.x_grid, coarse.values, 'k--', 'LineWidth', 1.0, ...
    'DisplayName', 'Coarse scan');

  cmap = lines(length(history));
  for level = 1:length(history)
    entry = history(level);
    semilogy(entry.x_grid, entry.values, '-o', 'LineWidth', 1.3, ...
      'MarkerSize', 5, 'Color', cmap(level, :), ...
      'DisplayName', sprintf('Level %d', level));
    if isfinite(entry.value_min)
      semilogy(entry.x_min, entry.value_min, 's', 'MarkerSize', 7, ...
        'MarkerFaceColor', cmap(level, :), ...
        'MarkerEdgeColor', cmap(level, :), 'HandleVisibility', 'off');
    end
  end

  grid on;
  xlabel('Real wavenumber k_{real}', 'FontSize', 11);
  ylabel('\sigma_{min}(A_{def})', 'FontSize', 11);
  title(sprintf('Empty defect recursive scan: beta = %.4g, M = %d, ntot = %d, eps_k = %.1e', ...
    params.beta, params.M, params.ntot, params.eps_k), 'FontSize', 12);
  legend('Location', 'best');

end
