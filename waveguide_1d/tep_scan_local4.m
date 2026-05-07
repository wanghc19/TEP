% Remark: Earlier tests suggested that removing K-R corrections from the
%         S, D, and D' blocks lowered the error by about one order of
%         magnitude.  Since log(h) is not large enough to explain the
%         remaining instability, this variant targets the T block.

% Purpose:
%   Variant of tep_scan_local2.m for testing the Kress A+BD assembly of the
%   hypersingular Muller difference block.
%
% Main algorithm:
%   Keep the recursive local k-scan workflow from tep_scan_local2.m.  The
%   S, D, and D' blocks are inherited from tep_scan_local2.m, while the
%   hypersingular Tdiff block is assembled as a free-space Kress A+BD
%   discretization plus a smooth proxy correction.
%
% Based on:
%   tep_scan_local.m.
%
% Main changes:
%   LOCAL_construct_A now separates the singular center image Phi_k from the
%   regular proxy/MFS remainder R_k when filling the S, D, and D' diagonals.
%   The T-type block is replaced by the free-space Kress A+BD construction
%   plus the smooth quasi-periodic proxy correction.
%
% Numerical goal:
%   Test whether replacing only the Tdiff block improves the local
%   singular-value scan while preserving the rest of the tep_scan_local2.m
%   experiment.

function tep_scan_local4

format long;

% Diagnostic Script: Recursive Singular Value Dip Refinement for Fixed Beta
%
% Use kernel.qpgreen_mfs_pairmat to vectorize LOCAL_construct_A.
%
% At step 3 we scan the k on the given interval 'initial_interval', note that this interval is chosen to contain
% one dip.
%
% ellipse: ntot = 150, sigma_min = 8.958144500080e-09 at k = 2.6535116121356430
% star: ntot = 150, 3.243565254004e-07 at k = 2.1301287071711603

% --- 1. Parameter Setup ---
ntot = 100;                            % Single boundary point count for dip refinement
flag_geom = 'ellipse';                % Geometry type: 'star' or 'ellipse'
iprec = 10;
er = 13;
nref = sqrt(er);
d = 1.0;
beta = 0.5 * 2 * pi / d;          % Fixed Bloch phase

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.5 * pars1.d;          % Height of the fundamental domain [-H, H]
pars2.proxy_dist = 0.2 * pars1.d; % Distance of proxy boundary from the domain
pars2.N_side = 50;                % Number of collocation points on Left/Right walls
pars2.N_top = 50;                 % Number of collocation points on Top/Bottom walls
pars2.N_proxy_edge = 30;          % Number of proxy sources per edge
pars2.M_pw = 10;                  % Truncation order for plane waves (-M_pw to M_pw)

num_k = 31;                       % MUST be odd to ensure a center point!
max_refine_level = 4;
initial_interval = [2.64525090, 2.65989423]; % for ellipse
% initial_interval = [2.12983082, 2.13084070]; % for star

% Start the recursive refinement process

fprintf('Running recursive singular value scan (beta = %.8f, ntot = %d)\n', beta, ntot);
fprintf('Initial interval = [%.8f, %.8f], num_k = %d, max_refine_level = %d\n', ...
  initial_interval(1), initial_interval(2), num_k, max_refine_level);

% --- 2. Geometry Setup ---
[C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0);

% --- 3. Recursive Dip Refinement ---
history = LOCAL_recursive_dip_refine(initial_interval, num_k, max_refine_level, ...
  nref, C, iprec, pars1, pars2, curvelen);

LOCAL_print_refine_summary(history);
[best_sigma, best_k, best_level] = LOCAL_get_best_result(history);
fprintf('\nFinal best result: level %d, k = %.16f, sigma_min = %.16e\n', ...
  best_level, best_k, best_sigma);

% --- 4. Plot All Refinement Levels ---
% LOCAL_plot_refine_history(history, ntot);

fprintf('\nFinished recursive dip scan successfully.\n');

end

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function history = LOCAL_recursive_dip_refine(initial_interval, num_k, max_refine_level, ...
    nref, C, iprec, pars1, pars2, curvelen)

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
      nref, C, iprec, pars1, pars2, curvelen);
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
    nref, C, iprec, pars1, pars2, curvelen)

  k_grid = linspace(interval(1), interval(2), num_k);
  sigma_vals = zeros(size(k_grid));

  for j = 1:length(k_grid)
    sigma_vals(j) = LOCAL_get_sigma_min(k_grid(j), nref, C, iprec, pars1, pars2, curvelen);
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
  diag_idx = 1:(ntot + 1):(ntot * ntot);

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

  % The non-hypersingular Muller differences are continuous at x = y.
  % Their diagonals must use only the regular remainder R_k in
  % G_ext_qp = Phi_k + R_k, not the singular center image Phi_k.
  [R_diag, gradR_diag, hessR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy);
  A21 = LOCAL_assemble_Tdiff_qp(C, khint, pars1, hessxx_ext, hessxy_ext, ...
    hessyy_ext, hessR_diag, curvelen);

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
  A22 = ((gradx_int - gradx_ext) .* nx1mat + (grady_int - grady_ext) .* nx2mat) .* weight_mat;

  A12(diag_idx) = (-log(khint / pars1.k) / (2 * pi) - R_diag) .* src_weight;
  % Since R_k is represented in target-minus-source coordinates near the
  % diagonal, -d/dn_y R_k is grad_x R_k dot n_y.
  A11(diag_idx) = (gradR_diag(1) .* ny1 + gradR_diag(2) .* ny2) .* src_weight;
  A22(diag_idx) = -(gradR_diag(1) .* nx1.' + gradR_diag(2) .* nx2.') .* src_weight;

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
