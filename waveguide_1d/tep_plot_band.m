% Purpose:
%   Make a Barnett-style fixed-geometry TEP band diagram without branch
%   tracking.  The horizontal axis is beta, the vertical axis is k, and the
%   plotted value is log10(sigma_min(A_QP(k,beta))).
%
% Main algorithm:
%   Sample a coarse tensor-like beta-by-k grid, detect local k-dips for each
%   fixed beta, refine only those dips with deeper Kress discretizations, and
%   collect every evaluated (beta,k,sigma_min) point into one irregular data
%   cloud for scatter and contour-style visualization.
%
% Based on:
%   tep_scan_global2.m for the all-Kress matrix assembly and fixed-beta
%   candidate refinement logic.
%
% Main changes:
%   This script does not choose branches and does not connect bands.  It only
%   visualizes sampled and refined values of log10(sigma_min).
%
% Numerical goal:
%   Reveal likely transmission-eigenvalue bands as low-sigma valleys in the
%   (beta,k) plane while keeping all sampled points visible.

function tep_plot_band

format long;

% --- 1. User-editable parameters ---
quick_test = false;                 % Set true for a small syntax/workflow test

flag_geom = 'ellipse';              % Geometry type: 'star', 'ellipse', or 'circle'
iprec = 10;                         % Kept for compatibility with existing scan helpers
er = 13;                            % Refractive-index squared ratio
nref = sqrt(er);                    % Interior wavenumber factor k_in = nref * k_out
d = 1.0;                            % Period length in the x direction

beta_interval = [0, pi];            % Brillouin-zone beta interval
kmin = 0.00;                        % Nominal left endpoint before beta clipping
kmax = pi;                          % Nominal right endpoint before beta clipping
k_interval = [kmin, kmax];          % Effective scan also enforces 0 < k < beta
k_endpoint_eps = 1e-6;              % Avoid the singular endpoints k = 0 and k = beta

nbeta = 80;                         % Number of beta samples
ngrid_global = 250;                 % Coarse k samples at the largest k interval
min_ngrid_global = 5;               % Minimum coarse k samples for small beta intervals

ntot_list = [40, 60, 100];          % Increasing Kress discretization sizes
refine_effort = 2;                  % Use ntot_list(1:refine_effort)

ngrid_refine = 11;                  % Local refinement grid size; keep odd
min_refine_level = 6;               % Do not stop before this many levels
max_refine_level = 8;               % Maximum refinement levels per dip
tol_rel_improve = 1e-8;             % Optional stopping after min_refine_level

candidate_keep_factor = 50;         % Keep dips within this factor of the best local dip
candidate_abs_thresh = inf;         % Optional loose absolute threshold
max_candidates_per_beta = 20;       % Limit candidate count for each beta

dedup_tol_beta = 0;                 % Exact duplicate merge by default
dedup_tol_k = 0;                    % Exact duplicate merge by default

contour_nbeta = 240;                % Interpolated plot beta-grid size
contour_nk = 280;                   % Interpolated plot k-grid size
marker_size = 8;                    % Overlay marker size for sampled points
color_limits = [-12, 0];            % Robust displayed range for log10 sigma

result_file = 'tep_plot_band_results.mat';
main_plot_file = 'tep_plot_band.png';
scatter_plot_file = 'tep_plot_band_scatter.png';

if quick_test
  nbeta = 5;
  ngrid_global = 30;
  ntot_list = [20, 30];
  refine_effort = 1;
  max_refine_level = 2;
  min_refine_level = 1;
  contour_nbeta = 80;
  contour_nk = 100;
end

refine_effort = min(refine_effort, numel(ntot_list));
ntot_used_list = ntot_list(1:refine_effort);
beta_grid = linspace(beta_interval(1), beta_interval(2), nbeta);

LOCAL_validate_parameters(beta_interval, k_interval, ntot_used_list, ngrid_global, ...
  min_ngrid_global, ngrid_refine, min_refine_level, max_refine_level, ...
  tol_rel_improve, candidate_keep_factor, max_candidates_per_beta, k_endpoint_eps);

pars1.d = d;
pars2.H = 0.5 * pars1.d;           % Height of the fundamental domain [-H, H]
pars2.proxy_dist = 0.2 * pars1.d;  % Distance of proxy boundary from the domain
pars2.N_side = 50;                 % Number of collocation points on Left/Right walls
pars2.N_top = 50;                  % Number of collocation points on Top/Bottom walls
pars2.N_proxy_edge = 30;           % Number of proxy sources per edge
pars2.M_pw = 10;                   % Plane-wave truncation order (-M_pw to M_pw)

fprintf('TEP band-plot data generation with all-Kress assembly\n');
fprintf('  Geometry        : %s\n', flag_geom);
fprintf('  beta interval   : [%.8f, %.8f], nbeta = %d\n', ...
  beta_interval(1), beta_interval(2), nbeta);
fprintf('  k interval      : [%.8f, %.8f], global k grid = %d\n', ...
  k_interval(1), k_interval(2), ngrid_global);
fprintf('  k constraint    : %.3e <= k <= beta - %.3e\n', ...
  k_endpoint_eps, k_endpoint_eps);
fprintf('  ntot used       : [%s]\n', num2str(ntot_used_list));
fprintf('  refine effort   : %d\n', refine_effort);
fprintf('  refine levels   : min %d, max %d\n', min_refine_level, max_refine_level);

geometry_cache = geom.build_geometry_cache(ntot_used_list, flag_geom);

all_beta = [];
all_k = [];
all_sigma = [];
all_stage = [];
all_ntot = [];
beta_k_intervals = NaN(length(beta_grid), 2);
beta_ngrid_global = zeros(length(beta_grid), 1);
final_candidates = repmat(LOCAL_empty_candidate_result(), 0, 1);

for ibeta = 1:length(beta_grid)
  beta = beta_grid(ibeta);
  pars1.beta = beta;
  fprintf('\nbeta index %d/%d, beta = %.16f\n', ibeta, length(beta_grid), beta);

  [beta_k_interval, beta_ngrid] = LOCAL_effective_k_scan(beta, k_interval, ...
    k_endpoint_eps, ngrid_global, min_ngrid_global);
  beta_k_intervals(ibeta,:) = beta_k_interval;
  beta_ngrid_global(ibeta) = beta_ngrid;
  if beta_ngrid == 0
    fprintf('  skipped: no nonempty k interval after enforcing 0 < k < beta\n');
    continue;
  end

  ntot = ntot_used_list(1);
  [global_k_grid, global_sigma] = LOCAL_global_scan(beta_k_interval, beta_ngrid, ...
    ntot, geometry_cache, nref, iprec, pars1, pars2);
  [all_beta, all_k, all_sigma, all_stage, all_ntot] = LOCAL_append_samples( ...
    all_beta, all_k, all_sigma, all_stage, all_ntot, beta, global_k_grid, ...
    global_sigma, 1, ntot);

  candidates = LOCAL_find_candidate_dips(global_k_grid, global_sigma, ...
    candidate_keep_factor, candidate_abs_thresh, max_candidates_per_beta);
  fprintf('  coarse scan done, candidates = %d\n', length(candidates));

  if isempty(candidates)
    fprintf('  refined candidates = 0\n');
    continue;
  end

  if refine_effort == 1
    beta_candidates = LOCAL_coarse_candidates_to_results(beta, candidates, ntot);
  else
    current_candidates = candidates;
    beta_candidates = repmat(LOCAL_empty_candidate_result(), 0, 1);
    for stage = 2:refine_effort
      ntot = ntot_used_list(stage);
      stage_results = LOCAL_refine_candidate_list(beta, current_candidates, ntot, ...
        geometry_cache, beta_k_interval, nref, iprec, pars1, pars2, ngrid_refine, ...
        min_refine_level, max_refine_level, tol_rel_improve, stage);
      [all_beta, all_k, all_sigma, all_stage, all_ntot] = LOCAL_append_records( ...
        all_beta, all_k, all_sigma, all_stage, all_ntot, stage_results.sample_records);
      beta_candidates = stage_results.results;
      current_candidates = LOCAL_results_to_candidates(beta_candidates);
    end
  end

  final_candidates = [final_candidates; beta_candidates(:)]; %#ok<AGROW>
  fprintf('  refined candidates = %d\n', length(beta_candidates));
end

[beta_unique, k_unique, sigma_unique] = LOCAL_deduplicate_samples( ...
  all_beta, all_k, all_sigma, dedup_tol_beta, dedup_tol_k);

LOCAL_make_plots(beta_unique, k_unique, sigma_unique, beta_interval, k_interval, ...
  contour_nbeta, contour_nk, marker_size, color_limits, main_plot_file, scatter_plot_file);

save(result_file, 'beta_interval', 'k_interval', 'beta_grid', 'ntot_list', ...
  'refine_effort', 'all_beta', 'all_k', 'all_sigma', 'all_stage', 'all_ntot', ...
  'beta_k_intervals', 'beta_ngrid_global', 'beta_unique', 'k_unique', ...
  'sigma_unique', 'final_candidates');

fprintf('\nFinal band-plot data:\n');
fprintf('  total samples before dedup = %d\n', length(all_sigma));
fprintf('  total samples after dedup  = %d\n', length(sigma_unique));
fprintf('  number of final candidates = %d\n', length(final_candidates));
fprintf('  best sigma overall         = %.16e\n', min(sigma_unique));
fprintf('  output saved to %s\n', result_file);
fprintf('  figures saved to %s and %s\n', main_plot_file, scatter_plot_file);

end

%% =========================================================================
%  BAND-SCAN HELPERS
%  =========================================================================

function LOCAL_validate_parameters(beta_interval, k_interval, ntot_list, ngrid_global, ...
    min_ngrid_global, ngrid_refine, min_refine_level, max_refine_level, ...
    tol_rel_improve, candidate_keep_factor, max_candidates_per_beta, k_endpoint_eps)

  if numel(beta_interval) ~= 2 || any(~isfinite(beta_interval)) ...
      || beta_interval(1) > beta_interval(2)
    error('beta_interval must be a finite two-entry increasing vector.');
  end
  if numel(k_interval) ~= 2 || any(~isfinite(k_interval)) || k_interval(1) >= k_interval(2)
    error('k_interval must be a finite two-entry increasing vector.');
  end
  if isempty(ntot_list) || any(mod(ntot_list, 2) ~= 0)
    error('ntot_list entries used by Kress assembly must be even.');
  end
  if ngrid_global < 3
    error('ngrid_global must be at least 3.');
  end
  if min_ngrid_global < 3 || min_ngrid_global > ngrid_global
    error('Require 3 <= min_ngrid_global <= ngrid_global.');
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
  if candidate_keep_factor <= 0 || max_candidates_per_beta < 1
    error('candidate_keep_factor must be positive and max_candidates_per_beta must be at least 1.');
  end
  if k_endpoint_eps <= 0 || ~isfinite(k_endpoint_eps)
    error('k_endpoint_eps must be a positive finite scalar.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [effective_interval, effective_ngrid] = LOCAL_effective_k_scan(beta, ...
    k_interval, k_endpoint_eps, ngrid_global, min_ngrid_global)

  lower = max(k_interval(1), k_endpoint_eps);
  upper = min(k_interval(2), beta - k_endpoint_eps);
  if ~isfinite(beta) || upper <= lower
    effective_interval = [NaN, NaN];
    effective_ngrid = 0;
    return;
  end

  effective_interval = [lower, upper];
  nominal_lower = max(k_interval(1), k_endpoint_eps);
  nominal_width = max(k_interval(2) - nominal_lower, eps);
  width = upper - lower;
  effective_ngrid = round(ngrid_global * width / nominal_width);
  effective_ngrid = max(min_ngrid_global, effective_ngrid);
  effective_ngrid = min(ngrid_global, effective_ngrid);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [k_grid, sigma_vals] = LOCAL_global_scan(k_interval, ngrid_global, ...
    ntot, geometry_cache, nref, iprec, pars1, pars2)

  k_grid = linspace(k_interval(1), k_interval(2), ngrid_global);
  [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
  sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidates = LOCAL_find_candidate_dips(k_grid, sigma_vals, ...
    candidate_keep_factor, candidate_abs_thresh, max_candidates)

  candidates = struct('candidate_id', {}, 'idx', {}, 'k0', {}, 'sigma0', {}, 'bracket', {});
  local_idx = [];
  for j = 2:(length(k_grid) - 1)
    if sigma_vals(j) < sigma_vals(j - 1) && sigma_vals(j) < sigma_vals(j + 1)
      local_idx(end + 1) = j; %#ok<AGROW>
    end
  end
  if isempty(local_idx)
    return;
  end

  local_sigma = sigma_vals(local_idx);
  best_sigma = min(local_sigma);
  keep = (local_sigma <= candidate_keep_factor * max(best_sigma, realmin)) ...
    & (local_sigma <= candidate_abs_thresh);
  local_idx = local_idx(keep);
  if isempty(local_idx)
    return;
  end

  [~, order] = sort(sigma_vals(local_idx), 'ascend');
  local_idx = local_idx(order);
  n_keep = min(max_candidates, length(local_idx));
  for q = 1:n_keep
    j = local_idx(q);
    candidates(q).candidate_id = q;
    candidates(q).idx = j;
    candidates(q).k0 = k_grid(j);
    candidates(q).sigma0 = sigma_vals(j);
    candidates(q).bracket = [k_grid(j - 1), k_grid(j + 1)];
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [all_beta, all_k, all_sigma, all_stage, all_ntot] = LOCAL_append_samples( ...
    all_beta, all_k, all_sigma, all_stage, all_ntot, beta, k_vals, sigma_vals, stage, ntot)

  n = numel(k_vals);
  all_beta = [all_beta; beta * ones(n, 1)]; %#ok<AGROW>
  all_k = [all_k; k_vals(:)]; %#ok<AGROW>
  all_sigma = [all_sigma; sigma_vals(:)]; %#ok<AGROW>
  all_stage = [all_stage; stage * ones(n, 1)]; %#ok<AGROW>
  all_ntot = [all_ntot; ntot * ones(n, 1)]; %#ok<AGROW>

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [all_beta, all_k, all_sigma, all_stage, all_ntot] = LOCAL_append_records( ...
    all_beta, all_k, all_sigma, all_stage, all_ntot, records)

  for j = 1:length(records)
    [all_beta, all_k, all_sigma, all_stage, all_ntot] = LOCAL_append_samples( ...
      all_beta, all_k, all_sigma, all_stage, all_ntot, records(j).beta, ...
      records(j).k_grid, records(j).sigma_vals, records(j).stage, records(j).ntot);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function stage_output = LOCAL_refine_candidate_list(beta, candidates, ntot, geometry_cache, ...
    k_bounds, nref, iprec, pars1, pars2, ngrid_refine, min_refine_level, ...
    max_refine_level, tol_rel_improve, stage)

  stage_output.results = repmat(LOCAL_empty_candidate_result(), length(candidates), 1);
  stage_output.sample_records = repmat(LOCAL_empty_sample_record(), 0, 1);
  for j = 1:length(candidates)
    [result, records] = LOCAL_refine_one_candidate(beta, candidates(j), ntot, ...
      geometry_cache, k_bounds, nref, iprec, pars1, pars2, ngrid_refine, ...
      min_refine_level, max_refine_level, tol_rel_improve, stage);
    stage_output.results(j) = result;
    stage_output.sample_records = [stage_output.sample_records; records(:)]; %#ok<AGROW>
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [result, records] = LOCAL_refine_one_candidate(beta, candidate, ntot, ...
    geometry_cache, k_bounds, nref, iprec, pars1, pars2, ngrid_refine, ...
    min_refine_level, max_refine_level, tol_rel_improve, stage)

  [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
  current_interval = candidate.bracket;
  records = repmat(LOCAL_empty_sample_record(), max_refine_level, 1);
  sigma_prev = NaN;
  best_sigma = Inf;
  best_k = NaN;
  endpoint_flag = false;
  final_width = current_interval(2) - current_interval(1);

  for level = 1:max_refine_level
    k_grid = linspace(current_interval(1), current_interval(2), ngrid_refine);
    sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);
    [sigma_min, idx_min] = min(sigma_vals);
    k_min = k_grid(idx_min);
    endpoint_hit = (idx_min == 1) || (idx_min == ngrid_refine);
    endpoint_flag = endpoint_flag || endpoint_hit;

    records(level).beta = beta;
    records(level).stage = stage;
    records(level).level = level;
    records(level).ntot = ntot;
    records(level).k_grid = k_grid;
    records(level).sigma_vals = sigma_vals;

    if sigma_min < best_sigma
      best_sigma = sigma_min;
      best_k = k_min;
    end

    if isfinite(sigma_prev) && sigma_prev > 0
      rel_improve = (sigma_prev - sigma_min) / sigma_prev;
    else
      rel_improve = NaN;
    end

    next_interval = scan.build_refined_interval(k_grid, idx_min);
    if endpoint_hit
      next_interval = LOCAL_expand_endpoint_interval(current_interval, k_grid, idx_min, k_bounds);
    end
    final_width = next_interval(2) - next_interval(1);

    if (level >= min_refine_level) && isfinite(rel_improve) ...
        && (rel_improve < tol_rel_improve) && ~endpoint_hit
      records = records(1:level);
      current_interval = next_interval;
      break;
    end

    if level == max_refine_level
      records = records(1:level);
      current_interval = next_interval;
      break;
    end

    sigma_prev = sigma_min;
    current_interval = next_interval;
  end

  result = LOCAL_empty_candidate_result();
  result.beta = beta;
  result.k_best = best_k;
  result.sigma_best = best_sigma;
  result.final_width = final_width;
  result.ntot_final = ntot;
  result.endpoint_flag = endpoint_flag;
  result.bracket = current_interval;
  result.candidate_id = candidate.candidate_id;

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

function results = LOCAL_coarse_candidates_to_results(beta, candidates, ntot)

  results = repmat(LOCAL_empty_candidate_result(), length(candidates), 1);
  for j = 1:length(candidates)
    results(j).beta = beta;
    results(j).k_best = candidates(j).k0;
    results(j).sigma_best = candidates(j).sigma0;
    results(j).final_width = candidates(j).bracket(2) - candidates(j).bracket(1);
    results(j).ntot_final = ntot;
    results(j).endpoint_flag = false;
    results(j).bracket = candidates(j).bracket;
    results(j).candidate_id = candidates(j).candidate_id;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidates = LOCAL_results_to_candidates(results)

  candidates = struct('candidate_id', {}, 'idx', {}, 'k0', {}, 'sigma0', {}, 'bracket', {});
  for j = 1:length(results)
    candidates(j).candidate_id = results(j).candidate_id;
    candidates(j).idx = NaN;
    candidates(j).k0 = results(j).k_best;
    candidates(j).sigma0 = results(j).sigma_best;
    candidates(j).bracket = results(j).bracket;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function result = LOCAL_empty_candidate_result()

  result = struct('beta', [], 'k_best', [], 'sigma_best', [], ...
    'final_width', [], 'ntot_final', [], 'endpoint_flag', false, ...
    'bracket', [], 'candidate_id', []);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function record = LOCAL_empty_sample_record()

  record = struct('beta', [], 'stage', [], 'level', [], 'ntot', [], ...
    'k_grid', [], 'sigma_vals', []);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [beta_unique, k_unique, sigma_unique] = LOCAL_deduplicate_samples( ...
    all_beta, all_k, all_sigma, dedup_tol_beta, dedup_tol_k)

  if isempty(all_sigma)
    beta_unique = [];
    k_unique = [];
    sigma_unique = [];
    return;
  end

  beta_key = all_beta(:);
  k_key = all_k(:);
  if dedup_tol_beta > 0
    beta_key = round(beta_key / dedup_tol_beta) * dedup_tol_beta;
  end
  if dedup_tol_k > 0
    k_key = round(k_key / dedup_tol_k) * dedup_tol_k;
  end

  [~, ~, group_idx] = unique([beta_key, k_key], 'rows', 'stable');
  ngroups = max(group_idx);
  beta_unique = zeros(ngroups, 1);
  k_unique = zeros(ngroups, 1);
  sigma_unique = zeros(ngroups, 1);
  for g = 1:ngroups
    idx = find(group_idx == g);
    [sigma_unique(g), idx_local] = min(all_sigma(idx));
    idx_keep = idx(idx_local);
    beta_unique(g) = all_beta(idx_keep);
    k_unique(g) = all_k(idx_keep);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_make_plots(beta_unique, k_unique, sigma_unique, beta_interval, k_interval, ...
    contour_nbeta, contour_nk, marker_size, color_limits, main_plot_file, scatter_plot_file)

  log_sigma = log10(max(sigma_unique, realmin));
  log_sigma_clip = min(max(log_sigma, color_limits(1)), color_limits(2));

  figure('Name', 'TEP band diagram scatter', 'Color', 'w');
  scatter(beta_unique, k_unique, marker_size, log_sigma_clip, 'filled');
  colorbar;
  caxis(color_limits);
  xlabel('\beta');
  ylabel('k');
  title('TEP band diagram samples: log_{10} \sigma_{min}');
  axis([beta_interval(1), beta_interval(2), k_interval(1), k_interval(2)]);
  grid on;
  saveas(gcf, scatter_plot_file);

  beta_axis = linspace(beta_interval(1), beta_interval(2), contour_nbeta);
  k_axis = linspace(k_interval(1), k_interval(2), contour_nk);
  [beta_mesh, k_mesh] = meshgrid(beta_axis, k_axis);
  try
    log_mesh = griddata(beta_unique, k_unique, log_sigma_clip, beta_mesh, k_mesh, 'natural');
  catch
    log_mesh = griddata(beta_unique, k_unique, log_sigma_clip, beta_mesh, k_mesh, 'linear');
  end

  figure('Name', 'TEP band diagram contour', 'Color', 'w');
  levels = linspace(color_limits(1), color_limits(2), 49);
  contourf(beta_mesh, k_mesh, log_mesh, levels, 'LineColor', 'none');
  hold on;
  scatter(beta_unique, k_unique, marker_size, log_sigma_clip, 'filled', ...
    'MarkerEdgeColor', 'none');
  colorbar;
  caxis(color_limits);
  xlabel('\beta');
  ylabel('k');
  title('TEP band diagram: log_{10} \sigma_{min}');
  axis([beta_interval(1), beta_interval(2), k_interval(1), k_interval(2)]);
  grid on;
  saveas(gcf, main_plot_file);

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
