function varargout = tep1d_scan_local()
% TEP1D_SCAN_LOCAL Recursively scan a local 1D waveguide objective.
%
% Purpose:
%   Run a local singular-value scan for the 1D periodic waveguide
%   transmission eigenvalue problem at fixed Bloch phase.
%
% Main algorithm:
%   Use the generic +scan package to sample sigma_min(A_QP(k)) on a coarse
%   grid, choose the sampled dip, and recursively refine the selected
%   interval.  The matrix construction and singular-value objective remain
%   local to this script.
%
% Based on:
%   waveguide_1d/tep_scan_local4_2.m.
%
% Main changes:
%   Generic scan, dip selection, refinement bookkeeping, and summary printing
%   are delegated to +scan.  The quasi-periodic Muller matrix construction is
%   still performed by op.construct_A_QP(C, kext, kint, pars1, proxy,
%   curvelen).
%
% Numerical goal:
%   Roughly check the local singular-value dip scan for the y-periodic
%   wrapper while using the packaged A_QP constructor shared by other 1D TEP
%   workflows.

  format long;

  % --- stage 1: set user parameters ---

  ntot = 100;                       % Boundary node count used in the local dip scan.
  flag_geom = 'star';               % Geometry type passed to geom.construct_cont.
  er = 13;                          % Permittivity ratio.
  nref = sqrt(er);                  % Interior/exterior refractive index ratio.
  eps_k = 1e-6;                     % Optional absorption in k = k_real + 1i*eps_k.
  d = 1.0;                          % Period length in the physical y direction.
  beta = 0.5 * 2 * pi / d;          % Fixed Bloch phase.

  pars1.beta = beta;
  pars1.d = d;
  pars1.periodic_axis = 'y';        % Smoke-test the physical y-periodic qpgreen wrapper.

  pars2.H = 0.5 * pars1.d;          % Half-width in physical x after the qpgreen x/y swap.
  pars2.proxy_dist = 0.2 * pars1.d; % Distance of proxy boundary from the domain.
  pars2.N_side = 50;                % Number of collocation points on Left/Right walls.
  pars2.N_top = 50;                 % Number of collocation points on Top/Bottom walls.
  pars2.N_proxy_edge = 30;          % Number of proxy sources per proxy-boundary edge.
  pars2.M_pw = 10;                  % Truncation order for plane waves.

  num_k = 31;                       % Odd k-grid size for coarse and refined scans.
  max_refine_level = 4;             % Number of local refinement levels after coarse selection.
  make_plot = false;                % Set true to plot the coarse scan and all refinement levels.

  % initial_interval = [2.65350974, 2.65351408]; % Local ellipse dip interval.
  % initial_interval = [2.13012810, 2.13012840]; % Local star dip interval for 'x'.
  initial_interval = [2.49881313, 2.49881340]; % Local star dip interval for 'y'.
  % initial_interval = [2.44011590, 2.44104378];

  fprintf('Running physical y-periodic recursive singular value scan (beta = %.8f, ntot = %d)\n', ...
    beta, ntot);
  fprintf('Initial interval = [%.8f, %.8f], num_k = %d, max_refine_level = %d, eps_k = %.6e\n', ...
    initial_interval(1), initial_interval(2), num_k, max_refine_level, eps_k);

  % --- stage 2: build geometry and objective context ---

  [C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0);
  ctx.nref = nref;
  ctx.eps_k = eps_k;
  ctx.C = C;
  ctx.pars1 = pars1;
  ctx.pars2 = pars2;
  ctx.curvelen = curvelen;

  objective = @(k_real) LOCAL_sigma_min_A_QP(k_real, ctx);
  scan_opts = scan.default_options( ...
    'min_refine_level', max_refine_level, ...
    'max_refine_level', max_refine_level, ...
    'num_initial_points', num_k, ...
    'num_refine_points', num_k, ...
    'dip_select', 'global_min', ...
    'include_endpoint_dips', true, ...
    'ignore_nan', true, ...
    'verbose', false);

  % --- stage 3: coarse scan, dip selection, and local refinement ---

  [result, coarse, history] = scan.scan_then_refine(objective, ...
    initial_interval, scan_opts);

  % --- stage 4: report and plot scan result ---

  scan.print_summary(result, history, 'tep1d local scan');
  if result.success
    fprintf('\nFinal best result: level %d, k_real = %.16f, eps_k = %.6e, sigma_min = %.16e\n', ...
      result.best_level, result.best_x, eps_k, result.best_value);
  end

  if make_plot
    LOCAL_plot_scan_result(coarse, history, ntot, eps_k);
  end

  fprintf('\nFinished recursive dip scan successfully.\n');

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

function [smin, info] = LOCAL_sigma_min_A_QP(k_real, ctx)

  kext = k_real + 1i * ctx.eps_k;
  kint = ctx.nref * kext;
  pars1 = ctx.pars1;
  pars1.k = kext;
  proxy = kernel.precomp_proxy(pars1, ctx.pars2);
  A_QP = op.construct_A_QP(ctx.C, kext, kint, pars1, proxy, ctx.curvelen);
  s = svd(A_QP);
  smin = s(end);

  info.status = 'ok';
  info.k_real = k_real;
  info.kext = kext;
  info.matrix_size = size(A_QP);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_scan_result(coarse, history, ntot, eps_k)

  figure('Name', 'Recursive Singular Value Dip Diagnosis', ...
    'Position', [120, 120, 1000, 720], 'Color', 'w');
  hold on;

  semilogy(coarse.x_grid, coarse.values, 'k--', 'LineWidth', 1.0, ...
    'DisplayName', 'Coarse scan');

  cmap = lines(length(history));
  for level = 1:length(history)
    entry = history(level);
    semilogy(entry.x_grid, entry.values, '-', 'LineWidth', 1.5, ...
      'Color', cmap(level, :), 'DisplayName', sprintf('Level %d', level));
    if isfinite(entry.value_min)
      semilogy(entry.x_min, entry.value_min, 'o', 'MarkerSize', 7, ...
        'MarkerFaceColor', cmap(level, :), ...
        'MarkerEdgeColor', cmap(level, :), 'HandleVisibility', 'off');
    end
  end

  grid on;
  xlabel('Real wavenumber k_{real}', 'FontSize', 11);
  ylabel('\sigma_{min}', 'FontSize', 11);
  title(sprintf('Recursive dip refinement for ntot = %d, eps_k = %.3e', ...
    ntot, eps_k), 'FontSize', 12);
  legend('Location', 'best');

end
