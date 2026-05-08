% Purpose:
%   Run a recursive local singular-value scan for the 1D periodic waveguide
%   transmission eigenvalue problem at fixed Bloch phase.
%
% Main algorithm:
%   Scan sigma_min(A_QP(k)) on an odd uniform k-grid inside a user-selected
%   interval, locate the smallest value, and recursively refine around that
%   dip using scan.build_refined_interval.
%
% Based on:
%   waveguide_1d/tep_scan_local4_2.m.
%
% Main changes:
%   The recursive scan, SVD computation, refinement bookkeeping, optional
%   plotting, and textual output are kept from tep_scan_local4_2.m.  The
%   quasi-periodic Muller matrix construction has been moved to
%   op.construct_A_QP(C, kext, kint, pars1, proxy, curvelen).
%   This smoke-test variant uses physical y-periodicity.  The qpgreen
%   implementation maps this to the existing x-periodic computational
%   coordinates by swapping x and y internally.
%
% Numerical goal:
%   Roughly check the local singular-value dip scan for the y-periodic
%   wrapper while using the packaged A_QP constructor shared by other 1D TEP
%   workflows.

format long;

% Diagnostic Script: Recursive Singular Value Dip Refinement for Fixed Beta
%
% At step 3 we scan k on the given interval initial_interval.  The interval
% should be chosen to contain one singular-value dip.
%
% ellipse: ntot = 120, sigma_min = 8.578334734939e-13 at k = 2.6535116672544254
% star: ntot = 100, 4.113868802806e-13 at k = 2.1301282065155553 for 'x'
% star: ntot = 100, 3.7420523239268711e-13 at k = 2.4988132875946665 for 'y'

% --- 1. Parameter Setup ---
ntot = 100;                       % Boundary node count used in the local dip scan
flag_geom = 'star';               % Geometry type passed to geom.construct_cont: 'star' or 'ellipse'
er = 13;                          % Permittivity ratio; nref = sqrt(er) sets kint = kext*nref
nref = sqrt(er);                  % Interior/exterior refractive index ratio
d = 1.0;                          % Period length in the physical y direction
beta = 0.5 * 2 * pi / d;          % Fixed Bloch phase for the physical y quasi-periodic field

pars1.beta = beta;
pars1.d = d;
pars1.periodic_axis = 'y';        % Smoke-test the physical y-periodic qpgreen wrapper

pars2.H = 0.5 * pars1.d;          % Half-width in physical x after the qpgreen x/y swap
pars2.proxy_dist = 0.2 * pars1.d; % Distance of proxy boundary from the domain
pars2.N_side = 50;                % Number of collocation points on Left/Right walls
pars2.N_top = 50;                 % Number of collocation points on Top/Bottom walls
pars2.N_proxy_edge = 30;          % Number of proxy sources per edge
pars2.M_pw = 10;                  % Truncation order for plane waves (-M_pw to M_pw)

num_k = 31;                       % Odd k-grid size so each refinement has a center point
max_refine_level = 4;             % Number of recursive local refinement levels
% initial_interval = [2.65350974, 2.65351408]; % Local ellipse dip interval
% initial_interval = [2.13012810, 2.13012840]; % Local star dip interval for 'x';
initial_interval = [2.49881313, 2.49881340]; % Local star dip interval for 'y';

fprintf('Running physical y-periodic recursive singular value scan (beta = %.8f, ntot = %d)\n', beta, ntot);
fprintf('Initial interval = [%.8f, %.8f], num_k = %d, max_refine_level = %d\n', ...
  initial_interval(1), initial_interval(2), num_k, max_refine_level);

% --- 2. Geometry Setup ---
[C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0);

% --- 3. Recursive Dip Refinement ---
history = LOCAL_recursive_dip_refine(initial_interval, num_k, max_refine_level, ...
  nref, C, pars1, pars2, curvelen);

LOCAL_print_refine_summary(history);
[best_sigma, best_k, best_level] = LOCAL_get_best_result(history);
fprintf('\nFinal best result: level %d, k = %.16f, sigma_min = %.16e\n', ...
  best_level, best_k, best_sigma);

% --- 4. Plot All Refinement Levels ---
% LOCAL_plot_refine_history(history, ntot);

fprintf('\nFinished recursive dip scan successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function history = LOCAL_recursive_dip_refine(initial_interval, num_k, max_refine_level, ...
    nref, C, pars1, pars2, curvelen)

  history = repmat(struct( ...
    'level', [], ...
    'interval', [], ...
    'interval_width', [], ...
    'k_grid', [], ...
    'sigma_vals', [], ...
    'idx_min', [], ...
    'k_min', [], ...
    'sigma_min', [], ...
    'is_left_endpoint', [], ...
    'is_right_endpoint', [], ...
    'endpoint_hit', '', ...
    'rel_improvement', []), max_refine_level, 1);

  current_interval = initial_interval;

  for level = 1:max_refine_level
    [k_grid, sigma_vals] = LOCAL_scan_sigma_on_grid(current_interval, num_k, ...
      nref, C, pars1, pars2, curvelen);
    [sigma_min, idx_min] = min(sigma_vals);
    k_min = k_grid(idx_min);

    is_left_endpoint = idx_min == 1;
    is_right_endpoint = idx_min == length(k_grid);
    endpoint_hit = 'none';
    if is_left_endpoint
      endpoint_hit = 'left';
    elseif is_right_endpoint
      endpoint_hit = 'right';
    end

    history(level).level = level;
    history(level).interval = current_interval;
    history(level).interval_width = current_interval(2) - current_interval(1);
    history(level).k_grid = k_grid;
    history(level).sigma_vals = sigma_vals;
    history(level).idx_min = idx_min;
    history(level).k_min = k_min;
    history(level).sigma_min = sigma_min;
    history(level).is_left_endpoint = is_left_endpoint;
    history(level).is_right_endpoint = is_right_endpoint;
    history(level).endpoint_hit = endpoint_hit;

    if level == 1
      history(level).rel_improvement = NaN;
    else
      prev_sigma = history(level - 1).sigma_min;
      history(level).rel_improvement = (prev_sigma - sigma_min) / prev_sigma;
    end

    if level < max_refine_level
      current_interval = scan.build_refined_interval(k_grid, idx_min);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [k_grid, sigma_vals] = LOCAL_scan_sigma_on_grid(interval, num_k, ...
    nref, C, pars1, pars2, curvelen)

  k_grid = linspace(interval(1), interval(2), num_k);
  sigma_vals = zeros(size(k_grid));

  for j = 1:length(k_grid)
    sigma_vals(j) = LOCAL_get_sigma_min(k_grid(j), nref, C, pars1, pars2, curvelen);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_refine_summary(history)

  fprintf('\nRefinement summary by level:\n');
  fprintf(['  %-5s %-28s %-14s %-22s %-20s %-16s %-14s\n'], ...
    'Level', 'Interval', 'Width', 'k_min', 'sigma_min', 'RelImprove', 'Endpoint');

  for level = 1:length(history)
    entry = history(level);
    interval_str = sprintf('[%.8f, %.8f]', entry.interval(1), entry.interval(2));

    if isnan(entry.rel_improvement)
      rel_str = 'N/A';
    else
      rel_str = sprintf('%.6e', entry.rel_improvement);
    end

    fprintf(['  %-5d %-28s %-14.6e %-22.16f %-20.12e %-16s %-14s\n'], ...
      entry.level, interval_str, entry.interval_width, entry.k_min, ...
      entry.sigma_min, rel_str, entry.endpoint_hit);

    if entry.is_left_endpoint || entry.is_right_endpoint
      fprintf('  Level %d note: minimum landed at the %s endpoint of the scan interval.\n', ...
        entry.level, entry.endpoint_hit);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [best_sigma, best_k, best_level] = LOCAL_get_best_result(history)

  sigma_all = zeros(length(history), 1);
  for j = 1:length(history)
    sigma_all(j) = history(j).sigma_min;
  end

  [best_sigma, idx_best] = min(sigma_all);
  best_k = history(idx_best).k_min;
  best_level = history(idx_best).level;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_refine_history(history, ntot)

  figure('Name', 'Recursive Singular Value Dip Diagnosis', ...
    'Position', [120, 120, 1000, 720], 'Color', 'w');
  hold on;

  cmap = lines(length(history));
  for level = 1:length(history)
    entry = history(level);
    semilogy(entry.k_grid, entry.sigma_vals, '-', 'LineWidth', 1.5, ...
      'Color', cmap(level, :), 'DisplayName', sprintf('Level %d', level));
    semilogy(entry.k_min, entry.sigma_min, 'o', 'MarkerSize', 7, ...
      'MarkerFaceColor', cmap(level, :), 'MarkerEdgeColor', cmap(level, :), ...
      'HandleVisibility', 'off');
  end

  grid on;
  xlabel('Wavenumber k', 'FontSize', 11);
  ylabel('\sigma_{min}', 'FontSize', 11);
  title(sprintf('Recursive dip refinement for ntot = %d', ntot), 'FontSize', 12);
  legend('Location', 'best');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function smin = LOCAL_get_sigma_min(kh, nref, C, pars1, pars2, curvelen)

  pars1.k = kh;
  proxy = kernel.precomp_proxy(pars1, pars2);
  kext = kh;
  kint = kh * nref;
  A_QP = op.construct_A_QP(C, kext, kint, pars1, proxy, curvelen);
  s = svd(A_QP);
  smin = s(end);

end
