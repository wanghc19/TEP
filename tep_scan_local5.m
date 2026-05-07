% Purpose:
%   Local eigenvalue scan for the TE boundary-condition transmission
%   eigenvalue problem using the all-Kress Muller discretization.
%
% Boundary conditions:
%   This file solves the TE boundary-condition eigenvalue problem with
%
%     u_out = u_in,
%     (1/epsilon_+) * partial_n u_out
%       = (1/epsilon_-) * partial_n u_in.
%
%   Here epsilon_+ = 1, epsilon_- = n^2, alpha_+ = 1/epsilon_+,
%   and alpha_- = 1/epsilon_-.
%
% Main algorithm:
%   Keep the recursive local k-scan workflow from tep_scan_local4_2.m.
%   Assemble S, D, D', and Tdiff with Kress split discretizations for the
%   free-space differences, plus ordinary trapezoid rules for smooth proxy
%   corrections.  Then apply the TE block coefficients from note_TE_mode.md.
%
% Based on:
%   tep_scan_local4_2.m.
%
% Main changes:
%   LOCAL_construct_A uses TE identity coefficients and scales the D and D'
%   pieces by epsilon_+, epsilon_-, alpha_+, and alpha_-.  The S block and
%   the verified hypersingular Tdiff block are unchanged.
%
% Numerical goal:
%   Refine one local TE eigenvalue candidate for a fixed Bloch phase.

function tep_scan_local5

format long;

% Diagnostic Script: Recursive Singular Value Dip Refinement for Fixed Beta
%
% Use kernel.qpgreen_mfs_pairmat to vectorize LOCAL_construct_A.
%
% At step 3 we scan the k on the given interval 'initial_interval', note that this interval is chosen to contain
% one dip.
%
% star: ntot = 100, 7.4049102209995532e-11 at k = 2.6744223713599999

% --- 1. Parameter Setup ---
ntot = 100;                            % Single boundary point count for dip refinement
flag_geom = 'star';                % Geometry type: 'star' or 'ellipse'
iprec = 10;
er = 13;
nref = sqrt(er);
refr_index = nref;                 % Interior refractive index n
eps_plus = 1;
eps_minus = refr_index^2;
alpha_plus = 1 / eps_plus;
alpha_minus = 1 / eps_minus;
d = 1.0;
beta = 0.5 * 2 * pi / d;          % Fixed Bloch phase

pars1.beta = beta;
pars1.d = d;
pars1.eps_plus = eps_plus;
pars1.eps_minus = eps_minus;
pars1.alpha_plus = alpha_plus;
pars1.alpha_minus = alpha_minus;

pars2.H = 0.5 * pars1.d;          % Height of the fundamental domain [-H, H]
pars2.proxy_dist = 0.2 * pars1.d; % Distance of proxy boundary from the domain
pars2.N_side = 50;                % Number of collocation points on Left/Right walls
pars2.N_top = 50;                 % Number of collocation points on Top/Bottom walls
pars2.N_proxy_edge = 30;          % Number of proxy sources per edge
pars2.M_pw = 10;                  % Truncation order for plane waves (-M_pw to M_pw)

num_k = 31;                       % MUST be odd to ensure a center point!
max_refine_level = 4;
initial_interval = [2.67442222, 2.67442249]; % for star

% Start the recursive refinement process

fprintf('Running TE recursive singular value scan (beta = %.8f, ntot = %d)\n', beta, ntot);
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

  % The non-hypersingular Muller differences are continuous at x = y.
  % Their diagonals must use only the regular remainder R_k in
  % G_ext_qp = Phi_k + R_k, not the singular center image Phi_k.
  [R_diag, gradR_diag, hessR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy);
  [A11, A22] = LOCAL_assemble_D_blocks_kress(C, khint, pars1.k, ...
    gradx_ext, grady_ext, gradR_diag, curvelen, pars1);
  A12 = LOCAL_assemble_Sdiff_kress(C, khint, pars1.k, pot_ext, R_diag, curvelen);
  A21 = LOCAL_assemble_Tdiff_qp(C, khint, pars1, hessxx_ext, hessxy_ext, ...
    hessyy_ext, hessR_diag, curvelen);

  % TE identity coefficients differ from the TM all-Kress baseline.
  A = zeros(2 * ntot, 2 * ntot);
  A(1:ntot, 1:ntot) = 0.5 * (pars1.eps_plus + pars1.eps_minus) ...
    * eye(ntot) + A11;
  A(1:ntot, ntot + 1:end) = A12;
  A(ntot + 1:end, 1:ntot) = A21;
  A(ntot + 1:end, ntot + 1:end) = 0.5 * (pars1.alpha_plus + pars1.alpha_minus) ...
    * eye(ntot) + A22;

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
    gradx_qp, grady_qp, gradR_diag, curvelen, pars1)

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

  % TE D-block coefficients:
  %   A11 operator part = epsilon_+ D_QP - epsilon_- D_in.
  %   A22 operator part = alpha_- D_in^* - alpha_+ D_QP^*.
  A11_free = R .* (pars1.eps_plus * L1_out - pars1.eps_minus * L1_in) ...
    + h * (pars1.eps_plus * L2_out - pars1.eps_minus * L2_in);
  A22_free = R .* (pars1.alpha_minus * Ls1_in - pars1.alpha_plus * Ls1_out) ...
    + h * (pars1.alpha_minus * Ls2_in - pars1.alpha_plus * Ls2_out);

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
  A11_proxy = -pars1.eps_plus ...
    * ((gradx_proxy .* ny1mat + grady_proxy .* ny2mat) .* weight_mat);
  A22_proxy = -pars1.alpha_plus ...
    * ((gradx_proxy .* nx1mat + grady_proxy .* nx2mat) .* weight_mat);

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
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  geom_data.z = [x.', y.'];
  geom_data.zp = [dxdt.', dydt.'];
  geom_data.zpp = [C(3,:).', C(6,:).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));

  R = LOCAL_kress_matrix(ntot);
  [M1_in, M2_in] = kernel.kress_mn_splits(kin, t, geom_data);
  [M1_out, M2_out] = kernel.kress_mn_splits(kout, t, geom_data);

  delta_M1 = M1_in - M1_out;
  delta_M2 = M2_in - M2_out;
  A12_free = R .* delta_M1 + h * delta_M2;

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
