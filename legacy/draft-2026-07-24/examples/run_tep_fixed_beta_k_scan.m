function run_tep_fixed_beta_k_scan
% RUN_TEP_FIXED_BETA_K_SCAN Fixed-beta global k scan for TEP candidates.
%
% Purpose:
%   Runs a fixed-beta scan of sigma_min(A_QP(k,beta)) for the periodic
%   waveguide transmission eigenvalue problem, using the current all-Kress
%   Muller matrix discretization.
%
% Main algorithm:
%   The function samples sigma_min(A_QP(k,beta)) on a coarse global k-grid,
%   detects strict local dips, keeps a loose candidate set, refines each
%   candidate at a mid resolution, and then refines the retained candidates
%   at a final resolution.
%
% Based on:
%   waveguide_1d/tep_scan_global2.m, which combines the all-Kress matrix
%   assembly used in tep_scan_local4_2.m with the fixed-beta scanning style
%   of tep_scan_global.m.
%
% Main changes:
%   This draft example writes outputs under draft/examples/output and
%   draft/figs, and it replaces the older MFS parameters by the parameter set
%   used in Section 6.1:
%   \(H=0.6\), \(\delta_{\rm proxy}=0.15\), \(N_{\rm side}=160\),
%   \(N_{\rm top}=160\), \(N_{\rm proxy}=160\), and \(M_{\rm pw}=16\).
%
% Numerical goal:
%   Find all local sigma_min dips for one fixed beta on a user-selected
%   k-interval and save the refined eigenvalue candidates.

format long;

% --- stage 1: set paths and user-editable parameters ---
script_dir = fileparts(mfilename('fullpath'));
draft_dir = fileparts(script_dir);
repo_root = fileparts(draft_dir);
output_dir = fullfile(script_dir, 'output');
fig_dir = fullfile(draft_dir, 'figs');

addpath(repo_root);

if ~exist(output_dir, 'dir')
  mkdir(output_dir);
end
if ~exist(fig_dir, 'dir')
  mkdir(fig_dir);
end

flag_geom = 'star';                % Geometry type: 'star', 'ellipse', or 'circle'
iprec = 10;                        % Kept for interface compatibility with local scan scripts
er = 13;                           % Refractive-index squared ratio used by existing TEP scripts
nref = sqrt(er);                   % Interior wavenumber factor k_in = nref * k_out
d = 1.0;                           % Period length in the x direction
beta = pi/d;                       % Fixed Bloch phase for this global scan

kmin = 0.01*beta;                  % Left endpoint of the scanned k interval
kmax = 0.99*beta;                  % Right endpoint of the scanned k interval
k_interval = [kmin, kmax];         % User-editable global scan interval

ntot_coarse = 40;                  % Cheap boundary discretization for detecting global dips.
ntot_mid = 60;                     % Mid-resolution boundary discretization for every coarse candidate.
ntot_final = 100;                  % Final boundary discretization for retained candidates.

ngrid_global = 400;                % Number of k samples in the coarse global scan.
ngrid_refine = 11;                 % Local refinement grid size; keep odd.

min_refine_level = 6;              % Do not stop before this many refinement levels.
max_refine_level = 8;              % Maximum local refinement levels per candidate.
tol_rel_improve = 1e-8;            % Optional stopping tolerance after min_refine_level.

candidate_keep_factor = 100;       % Keep local dips no larger than this times the best dip.
candidate_abs_thresh = inf;        % Optional loose absolute threshold for coarse candidates.
max_candidates = 20;               % Maximum number of candidates passed to refinement.
merge_tol = 1e-11;                 % Merge final candidates closer than this in k.

flag_plot_global = true;           % Optional fixed-beta scan plot.
result_file = fullfile(output_dir, 'tep_fixed_beta_k_scan_results.mat');
figure_file = fullfile(fig_dir, 'tep_fixed_beta_k_scan.png');

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.6 * pars1.d;           % Half-height of the MFS matching box [-H, H].
pars2.proxy_dist = 0.15 * pars1.d; % Offset from the matching box to the proxy box.
pars2.N_side = 160;                % Collocation points on each left/right periodic wall.
pars2.N_top = 160;                 % Collocation points on each top/bottom artificial wall.
pars2.N_proxy_edge = 40;           % Proxy sources per proxy-box edge; total N_proxy = 160.
pars2.M_pw = 16;                   % Rayleigh plane-wave half-truncation (-M_pw to M_pw).

LOCAL_validate_parameters(k_interval, ntot_coarse, ntot_mid, ntot_final, ...
  ngrid_global, ngrid_refine, min_refine_level, max_refine_level, ...
  tol_rel_improve, candidate_keep_factor, max_candidates);

fprintf('Fixed-beta global TEP scan with all-Kress assembly\n');
fprintf('  Geometry             : %s\n', flag_geom);
fprintf('  beta                 : %.16f\n', beta);
fprintf('  k interval           : [%.8f, %.8f]\n', k_interval(1), k_interval(2));
fprintf('  ntot coarse/mid/final: %d / %d / %d\n', ntot_coarse, ntot_mid, ntot_final);
fprintf('  global grid size     : %d\n', ngrid_global);
fprintf('  refine grid size     : %d\n', ngrid_refine);
fprintf('  refine levels        : min %d, max %d\n', min_refine_level, max_refine_level);
fprintf('  MFS H/proxy_dist     : %.6f / %.6f\n', pars2.H, pars2.proxy_dist);
fprintf('  MFS Nside/Ntop/Nproxy: %d / %d / %d\n', ...
  pars2.N_side, pars2.N_top, 4 * pars2.N_proxy_edge);

geometry_cache = geom.build_geometry_cache([ntot_coarse, ntot_mid, ntot_final], flag_geom);

% --- stage 2: run coarse global scan ---
global_scan = LOCAL_global_scan(k_interval, ngrid_global, ntot_coarse, ...
  geometry_cache, nref, iprec, pars1, pars2);
global_k_grid = global_scan.k_grid;
global_sigma = global_scan.sigma_vals;

candidates = LOCAL_find_candidate_dips(global_k_grid, global_sigma, ...
  candidate_keep_factor, candidate_abs_thresh, max_candidates);
if isempty(candidates)
  fprintf('No strict local dips survived the coarse criteria. Falling back to the global minimum.\n');
  candidates = LOCAL_make_global_minimum_candidate(global_k_grid, global_sigma);
end

LOCAL_print_global_candidate_summary(candidates);

% --- stage 3: refine coarse candidates at mid resolution ---
mid_results = LOCAL_refine_candidate_list(candidates, ntot_mid, geometry_cache, ...
  k_interval, nref, iprec, pars1, pars2, ngrid_refine, min_refine_level, ...
  max_refine_level, tol_rel_improve, 'mid');

% --- stage 4: refine retained candidates at final resolution ---
mid_results_sorted = LOCAL_sort_results_by_sigma(mid_results);
n_final = min(max_candidates, length(mid_results_sorted));
final_seed = mid_results_sorted(1:n_final);
final_results_raw = LOCAL_refine_candidate_list(final_seed, ntot_final, geometry_cache, ...
  k_interval, nref, iprec, pars1, pars2, ngrid_refine, min_refine_level, ...
  max_refine_level, tol_rel_improve, 'final');
final_results = LOCAL_merge_duplicate_results(final_results_raw, merge_tol);
final_results = LOCAL_sort_results_by_sigma(final_results);

LOCAL_print_final_results(beta, final_results);

% --- stage 5: save numerical output and optional plot ---
save(result_file, 'beta', 'k_interval', 'global_k_grid', 'global_sigma', ...
  'candidates', 'mid_results', 'final_results', 'pars1', 'pars2');
fprintf('\nSaved global scan results to %s\n', result_file);

if flag_plot_global
  LOCAL_plot_global_scan(global_k_grid, global_sigma, final_results, beta, figure_file);
  fprintf('Saved global scan plot to %s\n', figure_file);
end

fprintf('\nFixed-beta global scan completed successfully.\n');

end

%% =========================================================================
%  GLOBAL SCAN AND CANDIDATE HELPERS
%  =========================================================================

function LOCAL_validate_parameters(k_interval, ntot_coarse, ntot_mid, ntot_final, ...
    ngrid_global, ngrid_refine, min_refine_level, max_refine_level, ...
    tol_rel_improve, candidate_keep_factor, max_candidates)

  if numel(k_interval) ~= 2 || any(~isfinite(k_interval)) || k_interval(1) >= k_interval(2)
    error('k_interval must be a finite increasing two-entry vector.');
  end
  if any(mod([ntot_coarse, ntot_mid, ntot_final], 2) ~= 0)
    error('All ntot values must be even for even-node Kress/trigonometric formulas.');
  end
  if ngrid_global < 3
    error('ngrid_global must be at least 3.');
  end
  if mod(ngrid_refine, 2) ~= 1 || ngrid_refine < 3
    error('ngrid_refine must be an odd integer at least 3.');
  end
  if min_refine_level < 1 || max_refine_level < min_refine_level
    error('Require 1 <= min_refine_level <= max_refine_level.');
  end
  if tol_rel_improve < 0
    error('tol_rel_improve must be nonnegative.');
  end
  if candidate_keep_factor <= 0 || max_candidates < 1
    error('candidate_keep_factor must be positive and max_candidates must be at least 1.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function global_scan = LOCAL_global_scan(interval, ngrid, ntot, geometry_cache, ...
    nref, iprec, pars1, pars2)

  fprintf('\nStage 1: coarse global scan at ntot = %d\n', ntot);
  k_grid = linspace(interval(1), interval(2), ngrid);
  [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
  sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);

  global_scan.interval = interval;
  global_scan.k_grid = k_grid;
  global_scan.sigma_vals = sigma_vals;
  global_scan.ntot = ntot;

  fprintf('  Completed %d global samples.  Best coarse sigma = %.12e\n', ...
    ngrid, min(sigma_vals));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidates = LOCAL_find_candidate_dips(k_grid, sigma_vals, ...
    candidate_keep_factor, candidate_abs_thresh, max_candidates)

  candidates = struct('candidate_id', {}, 'idx', {}, 'k0', {}, 'sigma0', {}, ...
    'bracket', {}, 'stage', {});
  nk = length(k_grid);
  local_idx = [];
  for j = 2:(nk - 1)
    if sigma_vals(j) < sigma_vals(j - 1) && sigma_vals(j) < sigma_vals(j + 1)
      local_idx(end + 1) = j; %#ok<AGROW>
    end
  end

  if isempty(local_idx)
    return;
  end

  local_sigma = sigma_vals(local_idx);
  best_sigma = min(local_sigma);
  keep_thresh = candidate_keep_factor * max(best_sigma, realmin);
  keep = (local_sigma <= keep_thresh) & (local_sigma <= candidate_abs_thresh);
  local_idx = local_idx(keep);
  local_sigma = sigma_vals(local_idx);

  [~, order] = sort(local_sigma, 'ascend');
  local_idx = local_idx(order);
  n_keep = min(max_candidates, length(local_idx));

  for q = 1:n_keep
    j = local_idx(q);
    candidates(q).candidate_id = q;
    candidates(q).idx = j;
    candidates(q).k0 = k_grid(j);
    candidates(q).sigma0 = sigma_vals(j);
    candidates(q).bracket = [k_grid(j - 1), k_grid(j + 1)];
    candidates(q).stage = 'coarse';
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidate = LOCAL_make_global_minimum_candidate(k_grid, sigma_vals)

  [sigma_min, idx_min] = min(sigma_vals);
  candidate.candidate_id = 1;
  candidate.idx = idx_min;
  candidate.k0 = k_grid(idx_min);
  candidate.sigma0 = sigma_min;
  candidate.bracket = scan.build_refined_interval(k_grid, idx_min);
  candidate.stage = 'coarse_fallback';

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_global_candidate_summary(candidates)

  fprintf('\nGlobal scan candidate summary:\n');
  fprintf('  %-12s %-22s %-20s %-22s %-22s\n', ...
    'candidate_id', 'k0', 'sigma0', 'bracket_left', 'bracket_right');
  for j = 1:length(candidates)
    c = candidates(j);
    fprintf('  %-12d %-22.16f %-20.12e %-22.16f %-22.16f\n', ...
      c.candidate_id, c.k0, c.sigma0, c.bracket(1), c.bracket(2));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function results = LOCAL_refine_candidate_list(candidates, ntot, geometry_cache, ...
    k_bounds, nref, iprec, pars1, pars2, ngrid_refine, min_refine_level, ...
    max_refine_level, tol_rel_improve, stage_name)

  results = repmat(LOCAL_empty_refine_result(), length(candidates), 1);
  fprintf('\nStage %s refinement at ntot = %d for %d candidate(s)\n', ...
    stage_name, ntot, length(candidates));

  for j = 1:length(candidates)
    fprintf('\nCandidate %d (%s): initial bracket [%.16f, %.16f]\n', ...
      candidates(j).candidate_id, stage_name, candidates(j).bracket(1), candidates(j).bracket(2));
    results(j) = LOCAL_refine_one_candidate(candidates(j), ntot, geometry_cache, ...
      k_bounds, nref, iprec, pars1, pars2, ngrid_refine, min_refine_level, ...
      max_refine_level, tol_rel_improve, stage_name);
    LOCAL_print_refinement_history(results(j).history);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function result = LOCAL_refine_one_candidate(candidate, ntot, geometry_cache, k_bounds, ...
    nref, iprec, pars1, pars2, ngrid_refine, min_refine_level, ...
    max_refine_level, tol_rel_improve, stage_name)

  [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
  current_interval = candidate.bracket;
  history = repmat(LOCAL_empty_history_entry(), max_refine_level, 1);
  sigma_prev = NaN;
  best_sigma = Inf;
  best_k = NaN;
  final_width = current_interval(2) - current_interval(1);
  endpoint_flag = false;
  stop_reason = 'max_refine_reached';

  for level = 1:max_refine_level
    k_grid = linspace(current_interval(1), current_interval(2), ngrid_refine);
    sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);
    [sigma_min, idx_min] = min(sigma_vals);
    k_min = k_grid(idx_min);
    endpoint = LOCAL_endpoint_label(idx_min, ngrid_refine);
    endpoint_hit = ~strcmp(endpoint, 'none');
    endpoint_flag = endpoint_flag || endpoint_hit;

    if isfinite(sigma_prev) && sigma_prev > 0
      rel_improve = (sigma_prev - sigma_min) / sigma_prev;
    else
      rel_improve = NaN;
    end

    history(level).level = level;
    history(level).interval = current_interval;
    history(level).interval_width = current_interval(2) - current_interval(1);
    history(level).k_grid = k_grid;
    history(level).sigma_vals = sigma_vals;
    history(level).idx_min = idx_min;
    history(level).k_min = k_min;
    history(level).sigma_min = sigma_min;
    history(level).rel_improve = rel_improve;
    history(level).endpoint = endpoint;

    if sigma_min < best_sigma
      best_sigma = sigma_min;
      best_k = k_min;
    end

    next_interval = scan.build_refined_interval(k_grid, idx_min);
    if endpoint_hit
      fprintf('  Warning: candidate %d hit the %s endpoint at level %d.\n', ...
        candidate.candidate_id, endpoint, level);
      next_interval = LOCAL_expand_endpoint_interval(current_interval, k_grid, idx_min, k_bounds);
    end

    final_width = next_interval(2) - next_interval(1);
    if (level >= min_refine_level) && isfinite(rel_improve) ...
        && (rel_improve < tol_rel_improve) && ~endpoint_hit
      stop_reason = 'rel_improve_below_tol';
      history(level).stop_reason = stop_reason;
      history = history(1:level);
      current_interval = next_interval;
      break;
    end

    if level == max_refine_level
      stop_reason = 'max_refine_reached';
      history(level).stop_reason = stop_reason;
      history = history(1:level);
      current_interval = next_interval;
      break;
    end

    sigma_prev = sigma_min;
    current_interval = next_interval;
  end

  result.candidate_id = candidate.candidate_id;
  result.stage = stage_name;
  result.ntot_used = ntot;
  result.k0 = LOCAL_get_candidate_k0(candidate);
  result.sigma0 = LOCAL_get_candidate_sigma0(candidate);
  result.initial_bracket = candidate.bracket;
  result.k_best = best_k;
  result.sigma_best = best_sigma;
  result.final_interval = current_interval;
  result.final_width = final_width;
  result.endpoint_flag = endpoint_flag;
  result.stop_reason = stop_reason;
  result.history = history;
  result.bracket = current_interval;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function result = LOCAL_empty_refine_result()

  result = struct('candidate_id', [], 'stage', '', 'ntot_used', [], ...
    'k0', [], 'sigma0', [], 'initial_bracket', [], 'k_best', [], ...
    'sigma_best', [], 'final_interval', [], 'final_width', [], ...
    'endpoint_flag', false, 'stop_reason', '', 'history', [], 'bracket', []);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function entry = LOCAL_empty_history_entry()

  entry = struct('level', [], 'interval', [], 'interval_width', [], ...
    'k_grid', [], 'sigma_vals', [], 'idx_min', [], 'k_min', [], ...
    'sigma_min', [], 'rel_improve', [], 'endpoint', '', 'stop_reason', '');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function label = LOCAL_endpoint_label(idx_min, ngrid)

  if idx_min == 1
    label = 'left';
  elseif idx_min == ngrid
    label = 'right';
  else
    label = 'none';
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function next_interval = LOCAL_expand_endpoint_interval(current_interval, k_grid, idx_min, k_bounds)

  width = current_interval(2) - current_interval(1);
  if idx_min == 1
    next_interval = [max(k_bounds(1), current_interval(1) - width), k_grid(2)];
  elseif idx_min == length(k_grid)
    next_interval = [k_grid(end - 1), min(k_bounds(2), current_interval(2) + width)];
  else
    next_interval = scan.build_refined_interval(k_grid, idx_min);
  end
  if next_interval(1) >= next_interval(2)
    next_interval = scan.build_refined_interval(k_grid, idx_min);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function k0 = LOCAL_get_candidate_k0(candidate)

  if isfield(candidate, 'k0')
    k0 = candidate.k0;
  else
    k0 = candidate.k_best;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sigma0 = LOCAL_get_candidate_sigma0(candidate)

  if isfield(candidate, 'sigma0')
    sigma0 = candidate.sigma0;
  else
    sigma0 = candidate.sigma_best;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_refinement_history(history)

  fprintf('  %-5s %-28s %-14s %-22s %-20s %-16s %-10s\n', ...
    'Level', 'Interval', 'Width', 'k_min', 'sigma_min', 'RelImprove', 'Endpoint');
  for level = 1:length(history)
    entry = history(level);
    if isnan(entry.rel_improve)
      rel_str = 'N/A';
    else
      rel_str = sprintf('%.6e', entry.rel_improve);
    end
    interval_str = sprintf('[%.8f, %.8f]', entry.interval(1), entry.interval(2));
    fprintf('  %-5d %-28s %-14.6e %-22.16f %-20.12e %-16s %-10s\n', ...
      entry.level, interval_str, entry.interval_width, entry.k_min, ...
      entry.sigma_min, rel_str, entry.endpoint);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sorted_results = LOCAL_sort_results_by_sigma(results)

  if isempty(results)
    sorted_results = results;
    return;
  end
  [~, order] = sort([results.sigma_best], 'ascend');
  sorted_results = results(order);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function merged = LOCAL_merge_duplicate_results(results, merge_tol)

  results = LOCAL_sort_results_by_sigma(results);
  merged = repmat(LOCAL_empty_refine_result(), 0, 1);
  for j = 1:length(results)
    duplicate = false;
    for q = 1:length(merged)
      if abs(results(j).k_best - merged(q).k_best) < merge_tol
        duplicate = true;
        break;
      end
    end
    if ~duplicate
      merged(end + 1, 1) = results(j); %#ok<AGROW>
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_final_results(beta, final_results)

  fprintf('\nFinal global scan results for beta = %.16f\n', beta);
  fprintf('  %-6s %-22s %-20s %-16s %-12s %-14s\n', ...
    'rank', 'k_best', 'sigma_best', 'final_width', 'ntot_final', 'endpoint_flag');
  for j = 1:length(final_results)
    fprintf('  %-6d %-22.16f %-20.12e %-16.8e %-12d %-14d\n', ...
      j, final_results(j).k_best, final_results(j).sigma_best, ...
      final_results(j).final_width, final_results(j).ntot_used, ...
      final_results(j).endpoint_flag);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_global_scan(k_grid, sigma_vals, final_results, beta, figure_file)

  fig = figure('Name', 'Fixed-beta Global Scan', 'Color', 'w', 'Visible', 'off');
  semilogy(k_grid, sigma_vals, 'b.-', 'LineWidth', 1.0, 'MarkerSize', 7);
  hold on;
  if ~isempty(final_results)
    semilogy([final_results.k_best], [final_results.sigma_best], ...
      'ro', 'MarkerSize', 7, 'MarkerFaceColor', 'r');
  end
  grid on;
  xlabel('k', 'FontSize', 11);
  ylabel('\sigma_{min}', 'FontSize', 11);
  title(sprintf('Fixed-beta global scan, beta = %.8f', beta), 'FontSize', 12);
  legend({'coarse scan', 'final candidates'}, 'Location', 'best');
  exportgraphics(fig, figure_file, 'Resolution', 240);
  close(fig);

end

%% =========================================================================
%  ALL-KRESS MATRIX ASSEMBLY
%  =========================================================================

function sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen)

  sigma_vals = zeros(size(k_grid));
  for j = 1:length(k_grid)
    sigma_vals(j) = LOCAL_get_sigma_min(k_grid(j), nref, C, iprec, pars1, pars2, curvelen);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function smin = LOCAL_get_sigma_min(kh, nref, C, iprec, pars1, pars2, curvelen)

  pars1.k = kh;
  proxy = kernel.precomp_proxy(pars1, pars2);
  A = LOCAL_construct_A(C, iprec, kh * nref, pars1, proxy, curvelen);
  s = svd(A);
  smin = s(end);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_construct_A(C, iprec, khint, pars1, proxy, curvelen)

  %#ok<INUSD> iprec is kept to preserve the local scan helper interface.
  ntot = size(C, 2);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  speed = sqrt(dxdt.^2 + dydt.^2);

  [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    kernel.qpgreen_mfs_pairmat([x; y], [x; y], pars1, proxy);

  [R_diag, gradR_diag, hessR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy);
  [A11, A22] = LOCAL_assemble_D_blocks_kress(C, khint, pars1.k, ...
    gradx_ext, grady_ext, gradR_diag, curvelen);
  A12 = LOCAL_assemble_Sdiff_kress(C, khint, pars1.k, pot_ext, R_diag, curvelen);
  A21 = LOCAL_assemble_Tdiff_qp(C, khint, pars1, hessxx_ext, hessxy_ext, ...
    hessyy_ext, hessR_diag, curvelen);

  A = eye(2 * ntot, 2 * ntot);
  A(1:ntot, 1:ntot) = A(1:ntot, 1:ntot) + A11;
  A(1:ntot, ntot + 1:end) = A12;
  A(ntot + 1:end, 1:ntot) = A21;
  A(ntot + 1:end, ntot + 1:end) = A(ntot + 1:end, ntot + 1:end) + A22;

  scale_row = sqrt(h * [speed, speed]).';
  scale_col = sqrt((1 / h) ./ [speed, speed]);
  A = bsxfun(@times, bsxfun(@times, A, scale_col), scale_row);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [R_diag, gradR_diag, hessR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy)

  % At x = y, the singular center image Phi_k is omitted.  The proxy/MFS
  % sources represent the regular remainder R_k in the local cell.
  [R_diag, gradR_diag, hessR_diag] = kernel.h2d_directch(pars1.k, proxy.Z, proxy.q, [0; 0]);
  R_diag = R_diag(1);
  gradR_diag = gradR_diag(:, 1);
  hessR_diag = hessR_diag(:, 1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [A11, A22] = LOCAL_assemble_D_blocks_kress(C, kin, kout, ...
    gradx_qp, grady_qp, gradR_diag, curvelen)

  ntot = size(C, 2);
  if mod(ntot, 2) ~= 0
    error('Kress D-block assembly requires an even number of boundary nodes.');
  end

  [t, ~] = utils.triginterp(ntot);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  speed = sqrt(dxdt.^2 + dydt.^2);

  geom_data.z = [x.', y.'];
  geom_data.zp = [dxdt.', dydt.'];
  geom_data.zpp = [C(3,:).', C(6,:).'];
  geom_data.speed = speed.';

  R = LOCAL_kress_matrix(ntot);
  [L1_in, L2_in, Ls1_in, Ls2_in] = kernel.kress_l_splits(kin, t, geom_data);
  [L1_out, L2_out, Ls1_out, Ls2_out] = kernel.kress_l_splits(kout, t, geom_data);

  A11_free = R .* (L1_out - L1_in) + h * (L2_out - L2_in);
  A22_free = R .* (Ls1_in - Ls1_out) + h * (Ls2_in - Ls2_out);

  [gradx_free, grady_free] = LOCAL_free_gradient_matrices(kout, x, y);
  gradx_proxy = gradx_qp - gradx_free;
  grady_proxy = grady_qp - grady_free;
  diag_idx = 1:(ntot + 1):(ntot * ntot);
  gradx_proxy(diag_idx) = gradR_diag(1);
  grady_proxy(diag_idx) = gradR_diag(2);

  nx1 = (dydt ./ speed).';
  nx2 = (-dxdt ./ speed).';
  ny1mat = repmat(nx1.', ntot, 1);
  ny2mat = repmat(nx2.', ntot, 1);
  nx1mat = repmat(nx1, 1, ntot);
  nx2mat = repmat(nx2, 1, ntot);
  weight_mat = repmat(h * speed, ntot, 1);

  % Source-normal derivatives of P are minus target gradients for kernels
  % represented in target-minus-source coordinates.
  A11_proxy = -((gradx_proxy .* ny1mat + grady_proxy .* ny2mat) .* weight_mat);
  A22_proxy = -((gradx_proxy .* nx1mat + grady_proxy .* nx2mat) .* weight_mat);

  A11 = A11_free + A11_proxy;
  A22 = A22_free + A22_proxy;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [gradx, grady] = LOCAL_free_gradient_matrices(k, x, y)

  ntot = length(x);
  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  offdiag = ii ~= jj;

  xdiff = x.' - x;
  ydiff = y.' - y;
  rho = sqrt(xdiff.^2 + ydiff.^2);
  rho(~offdiag) = 1;
  coeff = -1i * k / 4 * besselh(1, 1, k * rho) ./ rho;

  gradx = coeff .* xdiff;
  grady = coeff .* ydiff;
  gradx(~offdiag) = 0;
  grady(~offdiag) = 0;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A12 = LOCAL_assemble_Sdiff_kress(C, kin, kout, pot_qp, R_diag, curvelen)

  ntot = size(C, 2);
  if mod(ntot, 2) ~= 0
    error('Kress Sdiff assembly requires an even number of boundary nodes.');
  end

  [t, ~] = utils.triginterp(ntot);
  h = curvelen / ntot;
  geom_data.z = [C(1,:).', C(4,:).'];
  geom_data.zp = [C(2,:).', C(5,:).'];
  geom_data.zpp = [C(3,:).', C(6,:).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));

  R = LOCAL_kress_matrix(ntot);
  [M1_in, M2_in] = kernel.kress_mn_splits(kin, t, geom_data);
  [M1_out, M2_out] = kernel.kress_mn_splits(kout, t, geom_data);

  A12_free = R .* (M1_in - M1_out) + h * (M2_in - M2_out);
  A12_proxy = LOCAL_assemble_S_proxy(C, kout, pot_qp, R_diag, h);
  A12 = A12_free + A12_proxy;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A12_proxy = LOCAL_assemble_S_proxy(C, kout, pot_qp, R_diag, h)

  ntot = size(C, 2);
  x = C(1, :);
  y = C(4, :);
  speed = sqrt(C(2, :).^2 + C(5, :).^2);

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  offdiag = ii ~= jj;

  xdiff = x.' - x;
  ydiff = y.' - y;
  rho = sqrt(xdiff.^2 + ydiff.^2);
  rho(~offdiag) = 1;

  pot_free = 1i / 4 * besselh(0, 1, kout * rho);
  pot_proxy = zeros(ntot, ntot);
  pot_proxy(offdiag) = pot_qp(offdiag) - pot_free(offdiag);
  pot_proxy(1:ntot + 1:end) = R_diag;

  A12_proxy = -pot_proxy .* repmat(h * speed, ntot, 1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Tdiff = LOCAL_assemble_Tdiff_qp(C, khint, pars1, hessxx_qp, ...
    hessxy_qp, hessyy_qp, hessR_diag, curvelen)

  ntot = size(C, 2);
  if mod(ntot, 2) ~= 0
    error('Kress Tdiff assembly requires an even number of boundary nodes.');
  end

  [t, D] = utils.triginterp(ntot);
  h = curvelen / ntot;
  geom_data.z = [C(1,:).', C(4,:).'];
  geom_data.zp = [C(2,:).', C(5,:).'];
  geom_data.zpp = [C(3,:).', C(6,:).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));

  Tdiff_free = LOCAL_assemble_Tdiff_free(t, D, geom_data, pars1.k, khint);
  Tdiff_proxy = LOCAL_assemble_Tdiff_proxy(C, pars1.k, hessxx_qp, ...
    hessxy_qp, hessyy_qp, hessR_diag, h);
  Tdiff = Tdiff_free + Tdiff_proxy;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Tdiff_free = LOCAL_assemble_Tdiff_free(t, D, geom_data, k1, k2)

  ntot = length(t);
  h = 2 * pi / ntot;
  R = LOCAL_kress_matrix(ntot);
  G = (geom_data.zp * geom_data.zp.') ./ (geom_data.speed * geom_data.speed.');

  [M1_k1, M2_k1, N1_k1, N2_k1] = kernel.kress_mn_splits(k1, t, geom_data);
  [M1_k2, M2_k2, N1_k2, N2_k2] = kernel.kress_mn_splits(k2, t, geom_data);

  delta_M1 = k1^2 * M1_k1 - k2^2 * M1_k2;
  delta_M2 = k1^2 * M2_k1 - k2^2 * M2_k2;
  delta_N1 = N1_k1 - N1_k2;
  delta_N2 = N2_k1 - N2_k2;

  A = (R .* delta_M1 + h * delta_M2) .* G;
  B_unscaled = R .* delta_N1 + h * delta_N2;
  B = bsxfun(@rdivide, B_unscaled, geom_data.speed);
  Tdiff_free = A + B * D;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function R = LOCAL_kress_matrix(ntot)

  rvec = quad.quad_kress_rvec(ntot);
  offset_idx = mod((0:ntot - 1) - (0:ntot - 1).', ntot) + 1;
  R = rvec(offset_idx);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Tdiff_proxy = LOCAL_assemble_Tdiff_proxy(C, k, hessxx_qp, ...
    hessxy_qp, hessyy_qp, hessR_diag, h)

  ntot = size(C, 2);
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  speed = sqrt(dxdt.^2 + dydt.^2);
  nx1 = (dydt ./ speed).';
  nx2 = (-dxdt ./ speed).';
  ny1 = nx1.';
  ny2 = nx2.';

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  offdiag = ii ~= jj;

  [hessxx_free, hessxy_free, hessyy_free] = LOCAL_free_hessian_matrices(k, x, y, offdiag);
  hessxx_proxy = zeros(ntot, ntot);
  hessxy_proxy = zeros(ntot, ntot);
  hessyy_proxy = zeros(ntot, ntot);
  hessxx_proxy(offdiag) = hessxx_qp(offdiag) - hessxx_free(offdiag);
  hessxy_proxy(offdiag) = hessxy_qp(offdiag) - hessxy_free(offdiag);
  hessyy_proxy(offdiag) = hessyy_qp(offdiag) - hessyy_free(offdiag);

  diag_idx = 1:(ntot + 1):(ntot * ntot);
  hessxx_proxy(diag_idx) = hessR_diag(1);
  hessxy_proxy(diag_idx) = hessR_diag(2);
  hessyy_proxy(diag_idx) = hessR_diag(3);

  nx1ny1 = nx1 * ny1;
  nx1ny2_nx2ny1 = nx1 * ny2 + nx2 * ny1;
  nx2ny2 = nx2 * ny2;
  weight_mat = repmat(h * speed, ntot, 1);

  % qpgreen_mfs_pairmat returns target-coordinate Hessians.  For kernels
  % represented in target-minus-source coordinates, the mixed x-y Hessian
  % in d/dn_x d/dn_y is the negative target Hessian.
  Tdiff_proxy = -((hessxx_proxy .* nx1ny1 + ...
                   hessxy_proxy .* nx1ny2_nx2ny1 + ...
                   hessyy_proxy .* nx2ny2) .* weight_mat);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [hessxx, hessxy, hessyy] = LOCAL_free_hessian_matrices(k, x, y, offdiag)

  xdiff = x.' - x;
  ydiff = y.' - y;
  rr = xdiff.^2 + ydiff.^2;
  rr(~offdiag) = 1;
  rho = sqrt(rr);
  z = k * rho;
  ima4inv = 1i / 4;

  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
  cdd2 = (k * ima4inv ./ rho) ./ rr;
  h2z = -z .* h0 + 2 .* h1;

  hessxx = cdd2 .* (h2z .* xdiff .* xdiff - rr .* h1);
  hessxy = cdd2 .* (h2z .* xdiff .* ydiff);
  hessyy = cdd2 .* (h2z .* ydiff .* ydiff - rr .* h1);
  hessxx(~offdiag) = 0;
  hessxy(~offdiag) = 0;
  hessyy(~offdiag) = 0;

end
