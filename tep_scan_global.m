format long;
clear;

% Adaptive scan of all detected local minima (dips) of sigma_min(k).
% The script first performs a global coarse scan on the full k-interval with
% a cheap boundary discretization, then detects all candidate dips, and
% finally refines each candidate on shrinking local intervals while the
% boundary discretization becomes finer.

% --- 1. Parameter Setup ---
flag_geom = 'ellipse';             % Geometry type: 'star' or 'ellipse'
iprec = 10;
er = 13;
nref = sqrt(er);
d = 1.0;
beta = 0.5 * 2 * pi / d;

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.5 * pars1.d;
pars2.proxy_dist = 0.2 * pars1.d;
pars2.N_side = 50;
pars2.N_top = 50;
pars2.N_proxy_edge = 30;
pars2.M_pw = 10;

ntot_list = [60, 80, 100, 120, 150];
ngrid = 201;                       % Global coarse scan size
nrefine = 11;                      % Local refinement grid size, keep it odd
max_refine_level = 6;              % Maximum local refinement steps per dip, >= 0.
full_interval = [0.01 * beta, 0.99 * beta];

if mod(nrefine, 2) ~= 1
  error('nrefine must be odd.');
end

fprintf('Adaptive dip scan for sigma_min(k)\n');
fprintf('  Geometry          : %s\n', flag_geom);
fprintf('  Full interval     : [%.8f, %.8f]\n', full_interval(1), full_interval(2));
fprintf('  ntot list         : [%s]\n', num2str(ntot_list));
fprintf('  Global grid size  : %d\n', ngrid);
fprintf('  Local grid size   : %d\n', nrefine);
fprintf('  Max refine level  : %d\n', max_refine_level);

geometry_cache = geom.build_geometry_cache(ntot_list, flag_geom);

% --- 2. Global Coarse Scan ---
global_scan = LOCAL_global_scan(full_interval, ngrid, ntot_list(1), geometry_cache, ...
  nref, iprec, pars1, pars2);

candidate_dips = LOCAL_find_candidate_dips(global_scan.k_grid, global_scan.sigma_vals);
if isempty(candidate_dips)
  fprintf('No strict local minima found on the coarse grid. Falling back to the global minimum.\n');
  [~, idx_min_global] = min(global_scan.sigma_vals);
  candidate_dips = LOCAL_make_fallback_dip(global_scan.k_grid, global_scan.sigma_vals, idx_min_global);
end

fprintf('Detected %d candidate dips from the global coarse scan.\n', length(candidate_dips));
LOCAL_print_candidate_summary(candidate_dips);

% --- 3. Local Adaptive Refinement For All Dips ---
[scan_records, dip_summaries] = LOCAL_refine_all_dips(candidate_dips, ntot_list, ...
  nrefine, max_refine_level, geometry_cache, nref, iprec, pars1, pars2, global_scan);

% --- 4. Merge Nonuniform Samples ---
[k_plot, sigma_plot, point_meta] = LOCAL_merge_scan_records(scan_records);

% --- 5. Reporting ---
LOCAL_print_refined_summary(dip_summaries);
[best_sigma, best_k, best_dip_id, best_ntot] = LOCAL_get_best_dip_result(dip_summaries);
fprintf('\nFinal best sample across all dips:\n');
fprintf('  dip_id    = %d\n', best_dip_id);
fprintf('  ntot      = %d\n', best_ntot);
fprintf('  k         = %.16f\n', best_k);
fprintf('  sigma_min = %.16e\n', best_sigma);

% --- 6. Final Plot ---
LOCAL_plot_adaptive_scan(k_plot, sigma_plot, point_meta, dip_summaries, flag_geom);

fprintf('\nAdaptive scan completed successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================

function global_scan = LOCAL_global_scan(interval, ngrid, ntot, geometry_cache, ...
    nref, iprec, pars1, pars2)

  k_grid = linspace(interval(1), interval(2), ngrid);
  [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
  sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);

  global_scan.interval = interval;
  global_scan.k_grid = k_grid;
  global_scan.sigma_vals = sigma_vals;
  global_scan.ntot = ntot;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen)

  sigma_vals = zeros(size(k_grid));
  for j = 1:length(k_grid)
    sigma_vals(j) = LOCAL_get_sigma_min(k_grid(j), nref, C, iprec, pars1, pars2, curvelen);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidate_dips = LOCAL_find_candidate_dips(k_grid, sigma_vals)

  candidate_dips = struct('dip_id', {}, 'idx', {}, 'k', {}, 'sigma', {}, 'interval', {});
  dip_count = 0;
  nk = length(k_grid);

  for j = 1:nk
    is_candidate = false;
    if nk == 1
      is_candidate = true;
    elseif j == 1
      is_candidate = sigma_vals(1) < sigma_vals(2);
    elseif j == nk
      is_candidate = sigma_vals(nk) < sigma_vals(nk - 1);
    else
      is_candidate = (sigma_vals(j) < sigma_vals(j - 1)) && (sigma_vals(j) < sigma_vals(j + 1));
    end

    if is_candidate
      dip_count = dip_count + 1;
      candidate_dips(dip_count).dip_id = dip_count;
      candidate_dips(dip_count).idx = j;
      candidate_dips(dip_count).k = k_grid(j);
      candidate_dips(dip_count).sigma = sigma_vals(j);
      candidate_dips(dip_count).interval = scan.build_refined_interval(k_grid, j);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function candidate_dip = LOCAL_make_fallback_dip(k_grid, sigma_vals, idx_min)

  candidate_dip = struct( ...
    'dip_id', 1, ...
    'idx', idx_min, ...
    'k', k_grid(idx_min), ...
    'sigma', sigma_vals(idx_min), ...
    'interval', scan.build_refined_interval(k_grid, idx_min));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_candidate_summary(candidate_dips)

  fprintf('\nCandidate dips from the global scan:\n');
  fprintf('  %-6s %-22s %-20s %-28s\n', 'dip_id', 'k', 'sigma_min', 'initial interval');
  for j = 1:length(candidate_dips)
    dip = candidate_dips(j);
    fprintf('  %-6d %-22.16f %-20.12e [%.8f, %.8f]\n', ...
      dip.dip_id, dip.k, dip.sigma, dip.interval(1), dip.interval(2));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scan_records, dip_summaries] = LOCAL_refine_all_dips(candidate_dips, ntot_list, ...
    nrefine, max_refine_level, geometry_cache, nref, iprec, pars1, pars2, global_scan)

  scan_records = LOCAL_make_scan_records(global_scan.k_grid, global_scan.sigma_vals, ...
    global_scan.ntot, 0, 0, global_scan.interval);
  dip_summaries = repmat(struct( ...
    'dip_id', [], ...
    'coarse_k', [], ...
    'coarse_sigma', [], ...
    'best_k', [], ...
    'best_sigma', [], ...
    'best_ntot', [], ...
    'final_interval', [], ...
    'history', []), length(candidate_dips), 1);

  for j = 1:length(candidate_dips)
    [dip_records, dip_summary] = LOCAL_refine_one_dip(candidate_dips(j), ntot_list, ...
      nrefine, max_refine_level, geometry_cache, nref, iprec, pars1, pars2);
    scan_records = [scan_records; dip_records(:)]; %#ok<AGROW>
    dip_summaries(j) = dip_summary;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [scan_records, dip_summary] = LOCAL_refine_one_dip(candidate_dip, ntot_list, ...
    nrefine, max_refine_level, geometry_cache, nref, iprec, pars1, pars2)

  scan_records = struct('k', {}, 'sigma', {}, 'ntot', {}, 'level', {}, 'dip_id', {}, 'interval', {});
  current_interval = candidate_dip.interval;
  best_k = candidate_dip.k;
  best_sigma = candidate_dip.sigma;
  best_ntot = ntot_list(1);

  history = repmat(struct( ...
    'level', [], ...
    'ntot', [], ...
    'interval', [], ...
    'k_grid', [], ...
    'sigma_vals', [], ...
    'idx_min', [], ...
    'k_min', [], ...
    'sigma_min', []), max(max_refine_level, 1), 1);

  if max_refine_level == 0
    history = history([]);
  end

  for level = 1:max_refine_level
    ntot = ntot_list(min(level + 1, length(ntot_list)));
    k_grid = linspace(current_interval(1), current_interval(2), nrefine);
    [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
    sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);
    [sigma_min, idx_min] = min(sigma_vals);
    k_min = k_grid(idx_min);

    scan_records = [scan_records; LOCAL_make_scan_records(k_grid, sigma_vals, ntot, ...
      level, candidate_dip.dip_id, current_interval)]; %#ok<AGROW>

    history(level).level = level;
    history(level).ntot = ntot;
    history(level).interval = current_interval;
    history(level).k_grid = k_grid;
    history(level).sigma_vals = sigma_vals;
    history(level).idx_min = idx_min;
    history(level).k_min = k_min;
    history(level).sigma_min = sigma_min;

    if sigma_min < best_sigma
      best_sigma = sigma_min;
      best_k = k_min;
      best_ntot = ntot;
    end

    current_interval = scan.build_refined_interval(k_grid, idx_min);
  end

  dip_summary.dip_id = candidate_dip.dip_id;
  dip_summary.coarse_k = candidate_dip.k;
  dip_summary.coarse_sigma = candidate_dip.sigma;
  dip_summary.best_k = best_k;
  dip_summary.best_sigma = best_sigma;
  dip_summary.best_ntot = best_ntot;
  dip_summary.final_interval = current_interval;
  dip_summary.history = history;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function scan_records = LOCAL_make_scan_records(k_grid, sigma_vals, ntot, level, dip_id, interval)

  npts = length(k_grid);
  scan_records = repmat(struct( ...
    'k', [], ...
    'sigma', [], ...
    'ntot', [], ...
    'level', [], ...
    'dip_id', [], ...
    'interval', []), npts, 1);

  for j = 1:npts
    scan_records(j).k = k_grid(j);
    scan_records(j).sigma = sigma_vals(j);
    scan_records(j).ntot = ntot;
    scan_records(j).level = level;
    scan_records(j).dip_id = dip_id;
    scan_records(j).interval = interval;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [k_sorted_unique, sigma_sorted_unique, point_meta] = LOCAL_merge_scan_records(scan_records)

  if isempty(scan_records)
    k_sorted_unique = [];
    sigma_sorted_unique = [];
    point_meta = struct('ntot', [], 'level', [], 'dip_id', [], 'raw_count', 0);
    return;
  end

  k_all = [scan_records.k].';
  sigma_all = [scan_records.sigma].';
  ntot_all = [scan_records.ntot].';
  level_all = [scan_records.level].';
  dip_id_all = [scan_records.dip_id].';

  [k_sorted, idx_sort] = sort(k_all);
  sigma_sorted = sigma_all(idx_sort);
  ntot_sorted = ntot_all(idx_sort);
  level_sorted = level_all(idx_sort);
  dip_id_sorted = dip_id_all(idx_sort);

  [k_sorted_unique, ~, group_idx] = unique(k_sorted, 'stable');
  sigma_sorted_unique = zeros(size(k_sorted_unique));
  ntot_unique = zeros(size(k_sorted_unique));
  level_unique = zeros(size(k_sorted_unique));
  dip_id_unique = zeros(size(k_sorted_unique));

  for j = 1:length(k_sorted_unique)
    idx_group = find(group_idx == j);
    [sigma_sorted_unique(j), idx_local] = min(sigma_sorted(idx_group));
    keep_idx = idx_group(idx_local);
    ntot_unique(j) = ntot_sorted(keep_idx);
    level_unique(j) = level_sorted(keep_idx);
    dip_id_unique(j) = dip_id_sorted(keep_idx);
  end

  point_meta.ntot = ntot_unique;
  point_meta.level = level_unique;
  point_meta.dip_id = dip_id_unique;
  point_meta.raw_count = length(k_all);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_refined_summary(dip_summaries)

  fprintf('\nRefined dip summary:\n');
  fprintf('  %-6s %-22s %-20s %-22s %-20s %-8s\n', ...
    'dip_id', 'coarse k', 'coarse sigma', 'best k', 'best sigma', 'ntot');
  for j = 1:length(dip_summaries)
    dip = dip_summaries(j);
    fprintf('  %-6d %-22.16f %-20.12e %-22.16f %-20.12e %-8d\n', ...
      dip.dip_id, dip.coarse_k, dip.coarse_sigma, dip.best_k, dip.best_sigma, dip.best_ntot);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [best_sigma, best_k, best_dip_id, best_ntot] = LOCAL_get_best_dip_result(dip_summaries)

  sigma_all = [dip_summaries.best_sigma];
  [best_sigma, idx_best] = min(sigma_all);
  best_k = dip_summaries(idx_best).best_k;
  best_dip_id = dip_summaries(idx_best).dip_id;
  best_ntot = dip_summaries(idx_best).best_ntot;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_adaptive_scan(k_plot, sigma_plot, point_meta, dip_summaries, flag_geom)

  figure('Name', 'Adaptive Scan Of All Dips', 'Position', [120, 120, 1100, 760], 'Color', 'w');
  semilogy(k_plot, sigma_plot, 'b.-', 'LineWidth', 1.0, 'MarkerSize', 8);
  hold on;

  best_k_all = [dip_summaries.best_k];
  best_sigma_all = [dip_summaries.best_sigma];
  semilogy(best_k_all, best_sigma_all, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

  grid on;
  xlabel('Wavenumber k', 'FontSize', 11);
  ylabel('\sigma_{min}', 'FontSize', 11);
  title(sprintf('Adaptive scan of all local dips (%s geometry)', flag_geom), 'FontSize', 12);
  legend({'All sampled points', 'Refined dip minima'}, 'Location', 'best');

  fprintf('\nMerged sample summary:\n');
  fprintf('  total raw samples    = %d\n', point_meta.raw_count);
  fprintf('  total plotted points = %d\n', length(k_plot));

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

  ntot = size(C, 2);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  speed = sqrt(dxdt.^2 + dydt.^2);
  nx1 = (dydt ./ speed).';
  nx2 = (-dxdt ./ speed).';
  ny1 = nx1.';
  ny2 = nx2.';
  src_weight = h * speed;

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;
  offdiag = L ~= 0;

  if iprec == 2
    MU = [0.7518812338640025 + 0.1073866830872157e1; ...
      -0.7225370982867850 - 0.6032109664493744];
    width = 2;
  elseif iprec == 6
    MU = [0.2051970990601250e1 + 0.2915391987686505e1; ...
      -0.7407035584542865e1 - 0.8797979464048396e1; ...
       0.1219590847580216e2 + 0.1365562914252423e2; ...
      -0.1064623987147282e2 - 0.1157975479644601e2; ...
       0.4799117710681772e1 + 0.5130987287355766e1; ...
      -0.8837770983721025   - 0.9342187797694916];
    width = 6;
  elseif iprec == 10
    MU = [0.3256353919777872D+01 + 0.4576078100790908D+01; ...
      -0.2096116396850468D+02 - 0.2469045273524281D+02; ...
       0.6872858265408605D+02 + 0.7648830198138171D+02; ...
      -0.1393153744796911D+03 - 0.1508194558089468D+03; ...
       0.1874446431742073D+03 + 0.1996415730837827D+03; ...
      -0.1715855846429547D+03 - 0.1807965537141134D+03; ...
       0.1061953812152787D+03 + 0.1110467735366555D+03; ...
      -0.4269031893958787D+02 - 0.4438764193424203D+02; ...
       0.1009036069527147D+02 + 0.1044548196545488D+02; ...
      -0.1066655310499552D+01 - 0.1100328792904271D+01];
    width = 10;
  else
    error('Unsupported iprec value.');
  end

  corr = ones(ntot, ntot);
  near_mask = offdiag & (abs(L) <= width);
  corr(near_mask) = 1 + MU(abs(L(near_mask)));

  xdiff = x.' - x;
  ydiff = y.' - y;
  rr = xdiff.^2 + ydiff.^2;
  rr(~offdiag) = 1;
  r = sqrt(rr);
  z = khint * r;
  ima4inv = 1i / 4;

  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
  cdd = -h1 .* (khint * ima4inv ./ r);
  cdd2 = (khint * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 .* h1;

  hf1 = h2z .* xdiff .* xdiff - rr .* h1;
  hf2 = h2z .* xdiff .* ydiff;
  hf3 = h2z .* ydiff .* ydiff - rr .* h1;

  pot_int = h0 * ima4inv;
  gradx_int = cdd .* xdiff;
  grady_int = cdd .* ydiff;
  hessxx_int = cdd2 .* hf1;
  hessxy_int = cdd2 .* hf2;
  hessyy_int = cdd2 .* hf3;

  pot_int(~offdiag) = 0;
  gradx_int(~offdiag) = 0;
  grady_int(~offdiag) = 0;
  hessxx_int(~offdiag) = 0;
  hessxy_int(~offdiag) = 0;
  hessyy_int(~offdiag) = 0;

  [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    kernel.qpgreen_mfs_pairmat([x; y], [x; y], pars1, proxy);

  pot_ext(~offdiag) = 0;
  gradx_ext(~offdiag) = 0;
  grady_ext(~offdiag) = 0;
  hessxx_ext(~offdiag) = 0;
  hessxy_ext(~offdiag) = 0;
  hessyy_ext(~offdiag) = 0;

  nx1ny1 = nx1 * ny1;
  nx1ny2_nx2ny1 = nx1 * ny2 + nx2 * ny1;
  nx2ny2 = nx2 * ny2;
  nx1mat = repmat(nx1, 1, ntot);
  nx2mat = repmat(nx2, 1, ntot);
  ny1mat = repmat(ny1, ntot, 1);
  ny2mat = repmat(ny2, ntot, 1);
  weight_mat = repmat(src_weight, ntot, 1);

  A11 = ((gradx_int - gradx_ext) .* ny1mat + (grady_int - grady_ext) .* ny2mat) .* weight_mat;
  A12 = (pot_int - pot_ext) .* weight_mat;
  A21 = ((hessxx_int - hessxx_ext) .* nx1ny1 + ...
         (hessxy_int - hessxy_ext) .* nx1ny2_nx2ny1 + ...
         (hessyy_int - hessyy_ext) .* nx2ny2) .* weight_mat;
  A22 = ((gradx_int - gradx_ext) .* nx1mat + (grady_int - grady_ext) .* nx2mat) .* weight_mat;

  A11 = A11 .* corr;
  A12 = A12 .* corr;
  A21 = A21 .* corr;
  A22 = A22 .* corr;

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

