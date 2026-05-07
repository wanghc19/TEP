% Convergence driver for the smallest singular value near one candidate
% transmission eigenvalue.
%
% Purpose:
%   This variant is derived from tep_conv_local.m and keeps the same
%   convergence-study workflow, parameters, reporting, and plotting logic.
%   Only the Muller matrix assembly is changed: all four operator blocks are
%   assembled by Kress split formulas.
%
% Main algorithm:
%   For each ntot and sampled k, build the boundary geometry, precompute the
%   quasi-periodic proxy representation, assemble A with Kress discretization
%   for S, D, D', and Tdiff, then record sigma_min(A).
%
% Based on:
%   tep_conv_local.m.
%
% Main changes:
%   LOCAL_construct_A uses Kress split assembly for all four blocks.  The
%   driver structure is otherwise unchanged.
%
% Numerical goal:
%   Check ntot-convergence of the smallest singular value near one candidate
%   transmission eigenvalue when all Muller blocks use Kress assembly.
%
% Original context:
%   This script is derived from demoeigen5.m, but it is not a full adaptive
% search over all dips in a broad k-interval.  Instead, it focuses on one
% known candidate eigenvalue and studies how the discretized minimum
% singular value changes as the boundary discretization ntot is increased.
%
% Two operating modes are supported.  In scan_interval mode, each ntot starts
% from k_interval_initial, samples sigma_min(A_N(k)) on a local grid, and
% adaptively shrinks the interval until the relative improvement in the
% sampled minimum is small, an endpoint is hit, or max_refine_level is
% reached.  The script records k_best(N), sigma_best(N), interval widths,
% stopping reasons, and optional fixed-k values.
%
% In fixed_k mode, the interval scan is skipped entirely.  The script
% directly evaluates sigma_min(A_N(k_fixed_ref)) for each ntot, which is the
% intended workflow once an accurate limiting eigenvalue k* is already known.
%
% The main numerical questions are whether k_best(N) stabilizes under
% refinement, and more importantly how sigma_min(A_N(k*)) appears to
% converge to zero as ntot grows.  The matrix assembly and singular-value
% evaluation formulas are kept close to the trusted implementation in
% demoeigen5.m; this file mainly changes the driver logic, reporting, and
% convergence diagnostics.
format long;
clear;

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
k_mode = 'fixed_k';          % Options: 'scan_interval' or 'fixed_k'
k_interval_initial = [2.65350974, 2.65351408];
min_refine_level = 6;
max_refine_level = 8;
tol_rel_improve = 1e-8;
nrefine = max_refine_level;        % Legacy alias for fixed-depth runs
ngrid_refine = 11;                 % Keep it odd
k_fixed_ref = 2.6535116672544254;

flag_print_level_details = true;
flag_plot_sigma = true;
flag_plot_kbest = true;
flag_plot_kerror = true;

if ~strcmp(k_mode, 'scan_interval') && ~strcmp(k_mode, 'fixed_k')
  error('k_mode must be either ''scan_interval'' or ''fixed_k''.');
end
if strcmp(k_mode, 'fixed_k') && (isempty(k_fixed_ref) || ~isscalar(k_fixed_ref) || ~isfinite(k_fixed_ref))
  error('fixed_k mode requires a finite scalar k_fixed_ref.');
end
if strcmp(k_mode, 'scan_interval')
  if mod(ngrid_refine, 2) ~= 1
    error('ngrid_refine must be odd.');
  end
  if min_refine_level < 1
    error('min_refine_level must be at least 1.');
  end
  if max_refine_level < min_refine_level
    error('max_refine_level must be greater than or equal to min_refine_level.');
  end
  if tol_rel_improve < 0
    error('tol_rel_improve must be nonnegative.');
  end
  if isempty(k_interval_initial) || numel(k_interval_initial) ~= 2 || ...
      any(~isfinite(k_interval_initial)) || k_interval_initial(1) >= k_interval_initial(2)
    error('scan_interval mode requires a finite increasing two-entry k_interval_initial.');
  end
end

fprintf('ntot-convergence study for sigma_min(k)\n');
fprintf('  Geometry            : %s\n', flag_geom);
fprintf('  k mode              : %s\n', k_mode);
if strcmp(k_mode, 'scan_interval')
  fprintf('  Initial interval    : [%.8f, %.8f]\n', k_interval_initial(1), k_interval_initial(2));
else
  fprintf('  Initial interval    : skipped in fixed_k mode\n');
end
fprintf('  ntot list           : [%s]\n', num2str(ntot_list));
if strcmp(k_mode, 'scan_interval')
  fprintf('  Min refine levels   : %d\n', min_refine_level);
  fprintf('  Max refine levels   : %d\n', max_refine_level);
  fprintf('  Rel improve tol     : %.3e\n', tol_rel_improve);
  fprintf('  Local grid size     : %d\n', ngrid_refine);
else
  fprintf('  Refinement          : skipped in fixed_k mode\n');
end
if isempty(k_fixed_ref)
  fprintf('  Fixed-k study       : skipped\n');
else
  fprintf('  Fixed-k study       : k = %.16f\n', k_fixed_ref);
end

results = LOCAL_run_ntot_convergence_study(flag_geom, iprec, nref, pars1, pars2, ...
  ntot_list, k_mode, k_interval_initial, min_refine_level, max_refine_level, ...
  tol_rel_improve, ngrid_refine, k_fixed_ref, flag_print_level_details);

LOCAL_print_convergence_summary(results);
LOCAL_plot_convergence_results(results, flag_plot_sigma, flag_plot_kbest, flag_plot_kerror);

fprintf('\nntot-convergence study completed successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function results = LOCAL_run_ntot_convergence_study(flag_geom, iprec, nref, pars1, pars2, ...
    ntot_list, k_mode, k_interval_initial, min_refine_level, max_refine_level, ...
    tol_rel_improve, ngrid_refine, k_fixed_ref, flag_print_level_details)

  geometry_cache = geom.build_geometry_cache(ntot_list, flag_geom);
  ncases = length(ntot_list);

  records = repmat(struct( ...
    'ntot', [], ...
    'k_best', [], ...
    'k_eval', [], ...
    'sigma_best', [], ...
    'interval_left', [], ...
    'interval_right', [], ...
    'interval_width', [], ...
    'sigma_fixed', [], ...
    'endpoint_hit', false, ...
    'level_count', [], ...
    'final_rel_improve', [], ...
    'stop_reason', '', ...
    'history', []), ncases, 1);

  for j = 1:ncases
    ntot = ntot_list(j);
    if strcmp(k_mode, 'scan_interval')
      [record, history] = LOCAL_refine_interval_for_one_ntot(ntot, geometry_cache, nref, iprec, ...
        pars1, pars2, k_interval_initial, min_refine_level, max_refine_level, ...
        tol_rel_improve, ngrid_refine);
      record.k_eval = record.k_best;
    else
      record = LOCAL_make_fixed_k_record(ntot, k_fixed_ref);
      history = [];
    end

    if ~isempty(k_fixed_ref)
      [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
      record.sigma_fixed = LOCAL_get_sigma_min(k_fixed_ref, nref, C, iprec, pars1, pars2, curvelen);
      if strcmp(k_mode, 'fixed_k')
        record.k_eval = k_fixed_ref;
      end
    else
      record.sigma_fixed = NaN;
    end

    record.history = history;
    records(j) = record;

    if flag_print_level_details
      LOCAL_print_one_ntot_progress(record);
    end
  end

  results.flag_geom = flag_geom;
  results.k_mode = k_mode;
  results.iprec = iprec;
  results.nref = nref;
  results.pars1 = pars1;
  results.pars2 = pars2;
  results.ntot_list = ntot_list(:);
  results.k_interval_initial = k_interval_initial;
  results.min_refine_level = min_refine_level;
  results.max_refine_level = max_refine_level;
  results.tol_rel_improve = tol_rel_improve;
  results.ngrid_refine = ngrid_refine;
  results.k_fixed_ref = k_fixed_ref;
  results.records = records;
  results.histories = cell(ncases, 1);
  for j = 1:ncases
    results.histories{j} = records(j).history;
  end

  k_best_all = [records.k_best].';
  k_eval_all = [records.k_eval].';
  sigma_best_all = [records.sigma_best].';
  sigma_fixed_all = [records.sigma_fixed].';

  results.k_best_all = k_best_all;
  results.k_eval_all = k_eval_all;
  results.sigma_best_all = sigma_best_all;
  results.sigma_fixed_all = sigma_fixed_all;
  if strcmp(k_mode, 'scan_interval')
    results.k_inf_last = k_best_all(end);
    results.k_limit_fit = LOCAL_fit_k_limit(ntot_list(:), k_best_all);
    if results.k_limit_fit.success
      results.k_inf_fit = results.k_limit_fit.k_inf;
      results.k_inf = results.k_inf_fit;
      results.k_inf_source = 'fit';
    else
      results.k_inf_fit = NaN;
      results.k_inf = results.k_inf_last;
      results.k_inf_source = 'largest_ntot';
    end
    results.k_error_all = abs(k_best_all - results.k_inf);
    results.fit_best = LOCAL_power_law_fit(ntot_list(:), sigma_best_all);
  else
    results.k_inf_last = NaN;
    results.k_limit_fit = LOCAL_empty_k_limit_fit('Skipped in fixed_k mode.');
    results.k_inf_fit = NaN;
    results.k_inf = NaN;
    results.k_inf_source = 'not_used';
    results.k_error_all = NaN(size(k_best_all));
    results.fit_best = [];
  end
  if isempty(k_fixed_ref)
    results.fit_fixed = [];
  else
    results.fit_fixed = LOCAL_power_law_fit(ntot_list(:), sigma_fixed_all);
  end

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [record, history] = LOCAL_refine_interval_for_one_ntot(ntot, geometry_cache, nref, iprec, ...
    pars1, pars2, k_interval_initial, min_refine_level, max_refine_level, ...
    tol_rel_improve, ngrid_refine)

  [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);
  current_interval = k_interval_initial;

  history = repmat(struct( ...
    'level', [], ...
    'interval', [], ...
    'k_grid', [], ...
    'sigma_vals', [], ...
    'idx_min', [], ...
    'k_min', [], ...
    'sigma_min', [], ...
    'rel_improve', [], ...
    'endpoint_hit', false, ...
    'stop_reason', ''), max_refine_level, 1);

  endpoint_hit = false;
  k_best = NaN;
  sigma_best = NaN;
  sigma_prev = NaN;
  final_rel_improve = NaN;
  level_count = 0;
  stop_reason = 'max_refine_reached';

  for level = 1:max_refine_level
    k_grid = linspace(current_interval(1), current_interval(2), ngrid_refine);
    sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);
    [sigma_best, idx_min] = min(sigma_vals);
    k_best = k_grid(idx_min);
    if isfinite(sigma_prev) && sigma_prev > 0
      rel_improve = (sigma_prev - sigma_best) / sigma_prev;
    else
      rel_improve = NaN;
    end

    history(level).level = level;
    history(level).interval = current_interval;
    history(level).k_grid = k_grid;
    history(level).sigma_vals = sigma_vals;
    history(level).idx_min = idx_min;
    history(level).k_min = k_best;
    history(level).sigma_min = sigma_best;
    history(level).rel_improve = rel_improve;
    history(level).endpoint_hit = (idx_min == 1) || (idx_min == ngrid_refine);

    level_count = level;
    final_rel_improve = rel_improve;
    next_interval = scan.build_refined_interval(k_grid, idx_min);

    if history(level).endpoint_hit
      endpoint_hit = true;
      stop_reason = 'endpoint_hit';
      history(level).stop_reason = stop_reason;
      fprintf(['  ntot = %d, level = %d: minimizer reached a refinement-grid endpoint ', ...
        '(idx = %d of %d).\n'], ntot, level, idx_min, ngrid_refine);
      current_interval = next_interval;
      break;
    end

    if (level >= min_refine_level) && isfinite(rel_improve) && (rel_improve < tol_rel_improve)
      stop_reason = 'rel_improve_below_tol';
      history(level).stop_reason = stop_reason;
      current_interval = next_interval;
      break;
    end

    if level == max_refine_level
      stop_reason = 'max_refine_reached';
      history(level).stop_reason = stop_reason;
    end

    sigma_prev = sigma_best;
    current_interval = next_interval;
  end

  history = history(1:level_count);
  record.ntot = ntot;
  record.k_best = k_best;
  record.sigma_best = sigma_best;
  record.interval_left = current_interval(1);
  record.interval_right = current_interval(2);
  record.interval_width = current_interval(2) - current_interval(1);
  record.sigma_fixed = NaN;
  record.endpoint_hit = endpoint_hit;
  record.level_count = level_count;
  record.final_rel_improve = final_rel_improve;
  record.stop_reason = stop_reason;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function record = LOCAL_make_fixed_k_record(ntot, k_fixed_ref)

  record.ntot = ntot;
  record.k_best = NaN;
  record.k_eval = k_fixed_ref;
  record.sigma_best = NaN;
  record.interval_left = NaN;
  record.interval_right = NaN;
  record.interval_width = NaN;
  record.sigma_fixed = NaN;
  record.endpoint_hit = false;
  record.level_count = 0;
  record.final_rel_improve = NaN;
  record.stop_reason = 'fixed_k';
  record.history = [];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fit = LOCAL_power_law_fit(xdata, ydata)

  fit = struct( ...
    'success', false, ...
    'npts', 0, ...
    'C', NaN, ...
    'p', NaN, ...
    'indices', [], ...
    'message', '');

  xdata = xdata(:);
  ydata = ydata(:);
  valid = isfinite(xdata) & isfinite(ydata) & (xdata > 0) & (ydata > 0);

  if nnz(valid) < 2
    fit.message = 'Too few positive data points for log-log fitting.';
    return;
  end

  idx_valid = find(valid);
  nuse = min(3, length(idx_valid));
  idx_use = idx_valid(end - nuse + 1:end);

  if length(idx_use) < 2
    fit.message = 'Too few tail points for log-log fitting.';
    return;
  end

  logx = log(xdata(idx_use));
  logy = log(ydata(idx_use));
  coeffs = polyfit(logx, logy, 1);

  fit.success = true;
  fit.npts = length(idx_use);
  fit.C = exp(coeffs(2));
  fit.p = -coeffs(1);
  fit.indices = idx_use;
  fit.message = sprintf('Used the last %d positive data points.', fit.npts);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fit = LOCAL_fit_k_limit(ntot_list, k_best_all)

  fit = LOCAL_empty_k_limit_fit('');

  ntot_list = ntot_list(:);
  k_best_all = k_best_all(:);
  valid = isfinite(ntot_list) & isfinite(k_best_all) & (ntot_list > 0);

  if nnz(valid) < 3
    fit.message = 'Too few finite k_best values for tail extrapolation.';
    return;
  end

  idx_valid = find(valid);
  nuse = min(3, length(idx_valid));
  idx_use = idx_valid(end - nuse + 1:end);
  ntail = ntot_list(idx_use);
  ktail = k_best_all(idx_use);

  q_grid = linspace(0.5, 12, 232);
  best_resnorm = Inf;
  best_coeffs = [NaN; NaN];
  best_q = NaN;

  for j = 1:length(q_grid)
    q = q_grid(j);
    basis = ntail.^(-q);
    V = [ones(size(ntail)), basis];
    if rcond(V.' * V) < 1e-14
      continue;
    end

    coeffs = V \ ktail;
    residual = ktail - V * coeffs;
    resnorm = norm(residual);
    if isfinite(resnorm) && (resnorm < best_resnorm)
      best_resnorm = resnorm;
      best_coeffs = coeffs;
      best_q = q;
    end
  end

  if ~isfinite(best_resnorm) || ~isfinite(best_coeffs(1)) || ~isfinite(best_q)
    fit.message = 'Tail extrapolation was numerically unstable.';
    return;
  end

  fit.success = true;
  fit.k_inf = best_coeffs(1);
  fit.C = best_coeffs(2);
  fit.q = best_q;
  fit.indices = idx_use;
  fit.resnorm = best_resnorm;
  fit.message = sprintf('Used the last %d finite k_best values.', nuse);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fit = LOCAL_empty_k_limit_fit(message)

  fit = struct( ...
    'success', false, ...
    'k_inf', NaN, ...
    'C', NaN, ...
    'q', NaN, ...
    'indices', [], ...
    'resnorm', NaN, ...
    'message', message);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_convergence_summary(results)

  records = results.records;

  fprintf('\nConvergence summary (%s mode):\n', results.k_mode);
  if strcmp(results.k_mode, 'fixed_k')
    fprintf('  %-8s %-22s %-20s\n', 'ntot', 'k_fixed_ref', 'sigma_fixed');
    for j = 1:length(records)
      record = records(j);
      fprintf('  %-8d %-22.16f %-20.12e\n', ...
        record.ntot, record.k_eval, record.sigma_fixed);
    end

    fprintf('\nDiagnostics:\n');
    fprintf('  Fixed k             = %.16f\n', results.k_fixed_ref);
    LOCAL_print_power_law_fit('sigma_fixed', results.fit_fixed);
    return;
  end

  k_inf = results.k_inf;
  if isempty(results.k_fixed_ref)
    fprintf(['  %-8s %-22s %-20s %-22s %-22s %-16s %-8s %-14s %-24s %-16s\n'], ...
      'ntot', 'k_best', 'sigma_best', 'interval_left', 'interval_right', ...
      'width', 'levels', 'rel_improve', 'stop_reason', '|k_best-k_inf|');
  else
    fprintf(['  %-8s %-22s %-20s %-22s %-22s %-16s %-20s %-8s %-14s %-24s %-16s\n'], ...
      'ntot', 'k_best', 'sigma_best', 'interval_left', 'interval_right', ...
      'width', 'sigma_fixed', 'levels', 'rel_improve', 'stop_reason', '|k_best-k_inf|');
  end

  for j = 1:length(records)
    record = records(j);
    if isempty(results.k_fixed_ref)
      fprintf(['  %-8d %-22.16f %-20.12e %-22.16f %-22.16f %-16.8e %-8d %-14.6e %-24s %-16.8e\n'], ...
        record.ntot, record.k_best, record.sigma_best, record.interval_left, ...
        record.interval_right, record.interval_width, record.level_count, ...
        record.final_rel_improve, record.stop_reason, abs(record.k_best - k_inf));
    else
      fprintf(['  %-8d %-22.16f %-20.12e %-22.16f %-22.16f %-16.8e %-20.12e %-8d %-14.6e %-24s %-16.8e\n'], ...
        record.ntot, record.k_best, record.sigma_best, record.interval_left, ...
        record.interval_right, record.interval_width, record.sigma_fixed, ...
        record.level_count, record.final_rel_improve, record.stop_reason, ...
        abs(record.k_best - k_inf));
    end
  end

  fprintf('\nDiagnostics:\n');
  fprintf('  k_inf fallback       = %.16f (largest ntot)\n', results.k_inf_last);
  if results.k_limit_fit.success
    fprintf('  k_inf fit            = %.16f\n', results.k_limit_fit.k_inf);
    fprintf('  k fit exponent q     = %.6f\n', results.k_limit_fit.q);
    fprintf('  k fit residual norm  = %.6e\n', results.k_limit_fit.resnorm);
    fprintf('  k fit message        = %s\n', results.k_limit_fit.message);
  else
    fprintf('  k_inf fit            = unavailable (%s)\n', results.k_limit_fit.message);
  end
  fprintf('  k_inf used           = %.16f (%s)\n', k_inf, results.k_inf_source);
  fprintf('  sigma_best(end)      = %.16e\n', results.sigma_best_all(end));
  fprintf('  Any endpoint hit     = %d\n', any([records.endpoint_hit]));

  LOCAL_print_power_law_fit('sigma_best', results.fit_best);
  if ~isempty(results.k_fixed_ref)
    LOCAL_print_power_law_fit('sigma_fixed', results.fit_fixed);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_power_law_fit(label, fit)

  if fit.success
    fprintf('  %s fit              : %s\n', label, fit.message);
    fprintf('  %s ~ C * ntot^{-p}  : C = %.6e, p = %.6f\n', label, fit.C, fit.p);
  else
    fprintf('  %s fit              : %s\n', label, fit.message);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_one_ntot_progress(record)

  if strcmp(record.stop_reason, 'fixed_k')
    fprintf('\nCompleted ntot = %d: k_eval = %.16f, sigma_fixed = %.12e\n', ...
      record.ntot, record.k_eval, record.sigma_fixed);
  else
    fprintf(['\nCompleted ntot = %d: k_best = %.16f, sigma_best = %.12e, ', ...
      'levels = %d, final width = %.8e, stop = %s\n'], ...
      record.ntot, record.k_best, record.sigma_best, record.level_count, ...
      record.interval_width, record.stop_reason);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_convergence_results(results, flag_plot_sigma, flag_plot_kbest, flag_plot_kerror)

  ntot = results.ntot_list;
  k_best = results.k_best_all;
  sigma_best = results.sigma_best_all;
  sigma_fixed = results.sigma_fixed_all;
  k_error = results.k_error_all;

  if strcmp(results.k_mode, 'fixed_k')
    if flag_plot_sigma
      valid_fixed = isfinite(sigma_fixed) & (sigma_fixed > 0);
      if any(valid_fixed)
        figure('Name', 'Fixed-k Sigma Convergence', 'Color', 'w');
        loglog(ntot(valid_fixed), sigma_fixed(valid_fixed), 's-', 'LineWidth', 1.2, 'MarkerSize', 7);
        grid on;
        xlabel('ntot', 'FontSize', 11);
        ylabel('\sigma_{min}', 'FontSize', 11);
        title(sprintf('Fixed-k convergence at k = %.16f', results.k_fixed_ref), 'FontSize', 12);
      else
        fprintf('No positive finite sigma_fixed values are available for plotting.\n');
      end
    end
    return;
  end

  if flag_plot_sigma
    figure('Name', 'Sigma Convergence', 'Color', 'w');
    loglog(ntot, sigma_best, 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
    hold on;
    if ~isempty(results.k_fixed_ref)
      valid_fixed = isfinite(sigma_fixed) & (sigma_fixed > 0);
      loglog(ntot(valid_fixed), sigma_fixed(valid_fixed), 's--', 'LineWidth', 1.2, 'MarkerSize', 7);
      legend({'sigma\_best', 'sigma\_fixed'}, 'Location', 'best');
    else
      legend({'sigma\_best'}, 'Location', 'best');
    end
    grid on;
    xlabel('ntot', 'FontSize', 11);
    ylabel('\sigma_{min}', 'FontSize', 11);
    title('Convergence of minimum singular values', 'FontSize', 12);
  end

  if flag_plot_kbest
    figure('Name', 'Best k Versus ntot', 'Color', 'w');
    plot(ntot, k_best, 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
    grid on;
    xlabel('ntot', 'FontSize', 11);
    ylabel('k_{best}', 'FontSize', 11);
    title('Refined minimizer location versus ntot', 'FontSize', 12);
  end

  if flag_plot_kerror
    valid_error = k_error > 0;
    if any(valid_error)
      figure('Name', 'k Error Versus ntot', 'Color', 'w');
      semilogy(ntot(valid_error), k_error(valid_error), 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
      grid on;
      xlabel('ntot', 'FontSize', 11);
      ylabel('|k_{best} - k_{\infty}|', 'FontSize', 11);
      title(sprintf('Convergence of refined minimizer location (%s k_{\\infty})', ...
        results.k_inf_source), 'FontSize', 12);
    else
      fprintf('All |k_best - k_inf| values are zero on the sampled grid; skipping the semilogy error plot.\n');
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
