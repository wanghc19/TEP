% Remark: 这是一份从理论上就错误的代码, 错误原因见Kress1.md, 即只实现了T算子的kernel的切向导数部分.
%         真正需要实现的kernel分解要复杂得多, 需要重新推导.
%         If you are an AI agents, just read the header comments and SKIP the rest 
%         of the code.

% Purpose:
%   Variant of tep_scan_local2.m that uses Kress-style assembly for the
%   T-difference block and treats the other three Muller difference blocks as
%   globally continuous kernels.
%
% Main algorithm:
%   Keep the recursive local k-scan workflow from tep_scan_local2.m.  The
%   S, D, and D' difference blocks use direct off-diagonal kernel
%   differences plus analytic diagonal limits, while the T-difference block
%   is written as a Kress logarithmic part plus a smooth remainder.
%
% Based on:
%   tep_scan_local2.m and the formulas summarized in Kress.md.
%
% Main changes:
%   LOCAL_construct_A and the consistency-check loop assembly now build the
%   T-difference block in the form Ndiff = log(4 sin^2((s-t)/2)) N1diff +
%   N2diff, with Kussmaul-Martensen weights for the logarithmic part and the
%   trapezoid rule for the smooth part.  The cot term cancels in the
%   difference kernel, and the other three blocks no longer use KR or any
%   near-diagonal workaround.
%
% Numerical goal:
%   Test a Kress-style T-block together with globally continuous S, D, and
%   D' difference blocks, while preserving the rest of the local scan
%   experiment.
format long;
clear;

% Diagnostic Script: Recursive Singular Value Dip Refinement for Fixed Beta
%
% Introduce LOCAL_qpgreen_mfs_pairmat to vetorize LOCAL_construct_A.
% At step 1.5 we perform a consistency check to ensure the optimized construction of A matches the original direct
% % construction, and compare the elapsed times for both methods.
%
% At step 3 we scan the k on the given interval 'initial_interval', note that this interval is chosen to contain
% one dip.
%
% ellipse: ntot = 150, sigma_min = 8.958144500080e-09 at k = 2.6535116121356430
% star: ntot = 150, 3.243565254004e-07 at k = 2.1301287071711603

% --- 1. Parameter Setup ---
ntot = 60;                            % Single boundary point count for dip refinement
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

% --1.5 Consistency check for the optimized construction of A--
flag_check_construct_A = true;
check_construct_A_ntot = 60;
check_construct_A_k = 0.73 * beta;
if flag_check_construct_A
  LOCAL_check_construct_A_optimized(check_construct_A_ntot, flag_geom, iprec, ...
    check_construct_A_k, nref, pars1, pars2);
end
% return
% Start the recursive refinement process

fprintf('Running recursive singular value scan (beta = %.8f, ntot = %d)\n', beta, ntot);
fprintf('Initial interval = [%.8f, %.8f], num_k = %d, max_refine_level = %d\n', ...
  initial_interval(1), initial_interval(2), num_k, max_refine_level);

% --- 2. Geometry Setup ---
[C, curvelen, ~, ~] = LOCAL_construct_cont(ntot, flag_geom, 0, 0);

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
      current_interval = LOCAL_build_refined_interval(k_grid, idx_min);
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

function interval = LOCAL_build_refined_interval(k_grid, idx_min)
  nk = length(k_grid);
  if nk < 2
    error('Need at least two k-samples to define a refined interval.');
  end

  if idx_min <= 1
    interval = [k_grid(1), k_grid(2)];
  elseif idx_min >= nk
    interval = [k_grid(nk - 1), k_grid(nk)];
  else
    interval = [k_grid(idx_min - 1), k_grid(idx_min + 1)];
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
  proxy = precomp_proxy(pars1, pars2);
  A = LOCAL_construct_A(C, iprec, kh * nref, pars1, proxy, curvelen);
  s = svd(A);
  smin = s(end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [C, curvelen, xxint, xxext] = LOCAL_construct_cont(ntot, flag_geom, nint, next)

  if strcmp(flag_geom, 'star')
    r = 0.3;
    k = 5;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =   1.5 * cos(tt) + (r / 2) *            cos((k + 1) * tt) + (r / 2) *            cos((k - 1) * tt);
    C(2,:) = - 1.5 * sin(tt) - (r / 2) * (k + 1) * sin((k + 1) * tt) - (r / 2) * (k - 1) * sin((k - 1) * tt);
    C(3,:) = - 1.5 * cos(tt) - (r / 2) * (k + 1) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * (k - 1) * cos((k - 1) * tt);
    C(4,:) =       sin(tt) + (r / 2) *            sin((k + 1) * tt) - (r / 2) *            sin((k - 1) * tt);
    C(5,:) =       cos(tt) + (r / 2) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * cos((k - 1) * tt);
    C(6,:) = -     sin(tt) - (r / 2) * (k + 1) * (k + 1) * sin((k + 1) * tt) + (r / 2) * (k - 1) * (k - 1) * sin((k - 1) * tt);
    C = C .* 0.2;
    curvelen = 2 * pi;
    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.6 * [rmax * cos(ttext); rmax * sin(ttext)];
  elseif strcmp(flag_geom, 'ellipse')
    a = 0.4;
    b = 0.4;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =  a * cos(tt);
    C(2,:) = -a * sin(tt);
    C(3,:) = -a * cos(tt);
    C(4,:) =  b * sin(tt);
    C(5,:) =  b * cos(tt);
    C(6,:) = -b * sin(tt);
    curvelen = 2 * pi;

    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.4 * [rmax * cos(ttext); rmax * sin(ttext)];
  else
    error('This option for the geometry is not implemented.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_construct_A(C, iprec, khint, pars1, proxy, curvelen)

  ntot = size(C, 2);
  [A11, A12, A21, A22, h, speed] = LOCAL_build_mueller_blocks(C, iprec, khint, pars1, proxy, curvelen);

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

function [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    LOCAL_qpgreen_mfs_pairmat(src, trg, pars1, proxy)

  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;

  q = proxy.q;
  Z = proxy.Z;
  H = proxy.H;
  C_up = proxy.C_up;
  C_down = proxy.C_down;

  ns = size(src, 2);
  nt = size(trg, 2);

  X = trg(1, :).'- src(1, :);
  Y = trg(2, :).'- src(2, :);

  m_shift = round(X / d);
  X0 = X - m_shift * d;
  phase_shift = exp(1i * beta * m_shift * d);

  pot_ext = zeros(nt, ns);
  gradx_ext = zeros(nt, ns);
  grady_ext = zeros(nt, ns);
  hessxx_ext = zeros(nt, ns);
  hessxy_ext = zeros(nt, ns);
  hessyy_ext = zeros(nt, ns);

  idx_in = abs(Y) <= H;
  idx_up = Y > H;
  idx_dn = Y < -H;

  if any(idx_in(:))
    T_in = [X0(idx_in).'; Y(idx_in).'];
    [pot0, grad0, hess0] = LOCAL_h2d_directch(k, [0; 0], 1, T_in);
    [potP, gradP, hessP] = LOCAL_h2d_directch(k, Z, q, T_in);

    pot_ext(idx_in) = (pot0 + potP) .* phase_shift(idx_in).';
    gradx_ext(idx_in) = (grad0(1, :) + gradP(1, :)) .* phase_shift(idx_in).';
    grady_ext(idx_in) = (grad0(2, :) + gradP(2, :)) .* phase_shift(idx_in).';
    hessxx_ext(idx_in) = (hess0(1, :) + hessP(1, :)) .* phase_shift(idx_in).';
    hessxy_ext(idx_in) = (hess0(2, :) + hessP(2, :)) .* phase_shift(idx_in).';
    hessyy_ext(idx_in) = (hess0(3, :) + hessP(3, :)) .* phase_shift(idx_in).';
  end

  if any(idx_up(:)) || any(idx_dn(:))
    N_pw_total = length(C_up);
    M_pw = (N_pw_total - 1) / 2;
    m_vec = (-M_pw:M_pw).';
    beta_m = beta + m_vec * (2 * pi / d);

    diff_sq = k^2 - beta_m.^2;
    gamma_m = zeros(size(beta_m));
    mask_prop = diff_sq >= 0;
    mask_eva = diff_sq < 0;
    gamma_m(mask_prop) = sqrt(diff_sq(mask_prop));
    gamma_m(mask_eva) = 1i * sqrt(-diff_sq(mask_eva));

    if any(idx_up(:))
      X_up = X0(idx_up).';
      Y_up = Y(idx_up).';
      phase_X = exp(1i * beta_m * X_up);
      phase_Y = exp(1i * gamma_m * (Y_up - H));
      basis = phase_X .* phase_Y;
      phase_up = phase_shift(idx_up).';

      pot_ext(idx_up) = sum(C_up .* basis, 1) .* phase_up;
      gradx_ext(idx_up) = sum(C_up .* basis .* (1i * beta_m), 1) .* phase_up;
      grady_ext(idx_up) = sum(C_up .* basis .* (1i * gamma_m), 1) .* phase_up;
      hessxx_ext(idx_up) = sum(C_up .* basis .* (-beta_m.^2), 1) .* phase_up;
      hessxy_ext(idx_up) = sum(C_up .* basis .* (-beta_m .* gamma_m), 1) .* phase_up;
      hessyy_ext(idx_up) = sum(C_up .* basis .* (-gamma_m.^2), 1) .* phase_up;
    end

    if any(idx_dn(:))
      X_dn = X0(idx_dn).';
      Y_dn = Y(idx_dn).';
      phase_X = exp(1i * beta_m * X_dn);
      phase_Y = exp(-1i * gamma_m * (Y_dn + H));
      basis = phase_X .* phase_Y;
      phase_dn = phase_shift(idx_dn).';

      pot_ext(idx_dn) = sum(C_down .* basis, 1) .* phase_dn;
      gradx_ext(idx_dn) = sum(C_down .* basis .* (1i * beta_m), 1) .* phase_dn;
      grady_ext(idx_dn) = sum(C_down .* basis .* (-1i * gamma_m), 1) .* phase_dn;
      hessxx_ext(idx_dn) = sum(C_down .* basis .* (-beta_m.^2), 1) .* phase_dn;
      hessxy_ext(idx_dn) = sum(C_down .* basis .* (beta_m .* gamma_m), 1) .* phase_dn;
      hessyy_ext(idx_dn) = sum(C_down .* basis .* (-gamma_m.^2), 1) .* phase_dn;
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [R_diag, gradR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy)

  % At x = y, the singular center image Phi_k is omitted.  The proxy/MFS
  % sources represent the regular remainder R_k in the local cell.
  [R_diag, gradR_diag, ~] = LOCAL_h2d_directch(pars1.k, proxy.Z, proxy.q, [0; 0]);
  R_diag = R_diag(1);
  gradR_diag = gradR_diag(:, 1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [A11, A12, A21, A22, h, speed] = LOCAL_build_mueller_blocks(C, iprec, khint, pars1, proxy, curvelen)

  LOCAL_validate_iprec(iprec);

  ntot = size(C, 2);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dx2dt = C(3, :);
  dydt = C(5, :);
  dy2dt = C(6, :);
  speed = sqrt(dxdt.^2 + dydt.^2);
  src_speed = repmat(speed, ntot, 1);
  src_weight = h * speed;

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;
  offdiag = L ~= 0;
  diag_idx = 1:(ntot + 1):(ntot * ntot);

  xdiff = x.' - x;
  ydiff = y.' - y;
  rr = xdiff.^2 + ydiff.^2;
  rr(~offdiag) = 1;
  r = sqrt(rr);

  points = [x; y];
  [pot_int, gradx_int, grady_int, hessxx_int, hessxy_int, hessyy_int] = ...
    LOCAL_free_space_pairmat(khint, points, points);
  [pot_center, gradx_center, grady_center, hessxx_center, hessxy_center, hessyy_center] = ...
    LOCAL_free_space_pairmat(pars1.k, points, points);
  [pot_reg, gradx_reg, grady_reg, hessxx_reg, hessxy_reg, hessyy_reg] = ...
    LOCAL_qpgreen_regular_pairmat(points, points, pars1, proxy);

  nx1 = (dydt ./ speed).';
  nx2 = (-dxdt ./ speed).';
  ny1 = nx1.';
  ny2 = nx2.';
  nx1ny1 = nx1 * ny1;
  nx1ny2_nx2ny1 = nx1 * ny2 + nx2 * ny1;
  nx2ny2 = nx2 * ny2;
  nx1mat = repmat(nx1, 1, ntot);
  nx2mat = repmat(nx2, 1, ntot);
  ny1mat = repmat(ny1, ntot, 1);
  ny2mat = repmat(ny2, ntot, 1);
  weight_mat = repmat(src_weight, ntot, 1);

  % The S, D, and D' blocks are continuous globally: direct kernel
  % differences off-diagonal and analytic limits on the diagonal.
  A11 = ((gradx_int - gradx_center - gradx_reg) .* ny1mat + ...
         (grady_int - grady_center - grady_reg) .* ny2mat) .* weight_mat;
  A12 = (pot_int - pot_center - pot_reg) .* weight_mat;
  A22 = ((gradx_int - gradx_center - gradx_reg) .* nx1mat + ...
         (grady_int - grady_center - grady_reg) .* nx2mat) .* weight_mat;

  [R_diag, gradR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy);
  A12(diag_idx) = (-log(khint / pars1.k) / (2 * pi) - R_diag) .* src_weight;
  A11(diag_idx) = (gradR_diag(1) .* ny1 + gradR_diag(2) .* ny2) .* src_weight;
  A22(diag_idx) = -(gradR_diag(1) .* nx1.' + gradR_diag(2) .* nx2.') .* src_weight;

  % Kress / Maue form for the T-difference kernel:
  % Ndiff = log(4 sin^2((s-t)/2)) N1diff + N2diff, with no cot term.
  N1diff = LOCAL_kress_tblock_log_coeff(khint, xdiff, ydiff, r, dxdt, dydt, offdiag) - ...
    LOCAL_kress_tblock_log_coeff(pars1.k, xdiff, ydiff, r, dxdt, dydt, offdiag);

  Nparam_int = ((hessxx_int .* nx1ny1 + hessxy_int .* nx1ny2_nx2ny1 + hessyy_int .* nx2ny2) .* src_speed);
  Nparam_center = ((hessxx_center .* nx1ny1 + hessxy_center .* nx1ny2_nx2ny1 + hessyy_center .* nx2ny2) .* src_speed);
  Nparam_reg = ((hessxx_reg .* nx1ny1 + hessxy_reg .* nx1ny2_nx2ny1 + hessyy_reg .* nx2ny2) .* src_speed);

  log_kernel = LOCAL_kress_log_kernel_matrix(L, offdiag, ntot);
  N2diff = Nparam_int - Nparam_center - Nparam_reg - log_kernel .* N1diff;
  N2diag_free = LOCAL_kress_tblock_N2_diag(dxdt, dx2dt, dydt, dy2dt);
  N1diff(diag_idx) = 0;
  % The free-space Kress diagonal term cancels in the difference kernel, so
  % only the regular exterior remainder contributes here.
  N2diff(diag_idx) = (N2diag_free.' - N2diag_free.') - Nparam_reg(diag_idx);

  A21 = LOCAL_kress_log_weight_matrix(L, ntot) .* N1diff + h * N2diff;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_iprec(iprec)

  if ~ismember(iprec, [2, 6, 10])
    error('Unsupported iprec value.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pot, gradx, grady, hessxx, hessxy, hessyy] = LOCAL_free_space_pairmat(wavek, src, trg)

  xdiff = trg(1, :).'- src(1, :);
  ydiff = trg(2, :).'- src(2, :);
  rr = xdiff.^2 + ydiff.^2;
  offdiag = rr ~= 0;
  rr(~offdiag) = 1;
  r = sqrt(rr);
  z = wavek * r;
  ima4inv = 1i / 4;

  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
  cdd = -h1 .* (wavek * ima4inv ./ r);
  cdd2 = (wavek * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 .* h1;

  hf1 = h2z .* xdiff .* xdiff - rr .* h1;
  hf2 = h2z .* xdiff .* ydiff;
  hf3 = h2z .* ydiff .* ydiff - rr .* h1;

  pot = h0 * ima4inv;
  gradx = cdd .* xdiff;
  grady = cdd .* ydiff;
  hessxx = cdd2 .* hf1;
  hessxy = cdd2 .* hf2;
  hessyy = cdd2 .* hf3;

  pot(~offdiag) = 0;
  gradx(~offdiag) = 0;
  grady(~offdiag) = 0;
  hessxx(~offdiag) = 0;
  hessxy(~offdiag) = 0;
  hessyy(~offdiag) = 0;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pot_reg, gradx_reg, grady_reg, hessxx_reg, hessxy_reg, hessyy_reg] = ...
    LOCAL_qpgreen_regular_pairmat(src, trg, pars1, proxy)

  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;

  q = proxy.q;
  Z = proxy.Z;
  H = proxy.H;
  C_up = proxy.C_up;
  C_down = proxy.C_down;

  ns = size(src, 2);
  nt = size(trg, 2);

  X = trg(1, :).'- src(1, :);
  Y = trg(2, :).'- src(2, :);

  m_shift = round(X / d);
  X0 = X - m_shift * d;
  phase_shift = exp(1i * beta * m_shift * d);

  pot_reg = zeros(nt, ns);
  gradx_reg = zeros(nt, ns);
  grady_reg = zeros(nt, ns);
  hessxx_reg = zeros(nt, ns);
  hessxy_reg = zeros(nt, ns);
  hessyy_reg = zeros(nt, ns);

  idx_in = abs(Y) <= H;
  idx_up = Y > H;
  idx_dn = Y < -H;

  if any(idx_in(:))
    T_in = [X0(idx_in).'; Y(idx_in).'];
    [potP, gradP, hessP] = LOCAL_h2d_directch(k, Z, q, T_in);

    pot_reg(idx_in) = potP .* phase_shift(idx_in).';
    gradx_reg(idx_in) = gradP(1, :) .* phase_shift(idx_in).';
    grady_reg(idx_in) = gradP(2, :) .* phase_shift(idx_in).';
    hessxx_reg(idx_in) = hessP(1, :) .* phase_shift(idx_in).';
    hessxy_reg(idx_in) = hessP(2, :) .* phase_shift(idx_in).';
    hessyy_reg(idx_in) = hessP(3, :) .* phase_shift(idx_in).';
  end

  if any(idx_up(:)) || any(idx_dn(:))
    N_pw_total = length(C_up);
    M_pw = (N_pw_total - 1) / 2;
    m_vec = (-M_pw:M_pw).';
    beta_m = beta + m_vec * (2 * pi / d);

    diff_sq = k^2 - beta_m.^2;
    gamma_m = zeros(size(beta_m));
    mask_prop = diff_sq >= 0;
    mask_eva = diff_sq < 0;
    gamma_m(mask_prop) = sqrt(diff_sq(mask_prop));
    gamma_m(mask_eva) = 1i * sqrt(-diff_sq(mask_eva));

    if any(idx_up(:))
      X_up = X0(idx_up).';
      Y_up = Y(idx_up).';
      phase_X = exp(1i * beta_m * X_up);
      phase_Y = exp(1i * gamma_m * (Y_up - H));
      basis = phase_X .* phase_Y;
      phase_up = phase_shift(idx_up).';

      pot_reg(idx_up) = sum(C_up .* basis, 1) .* phase_up;
      gradx_reg(idx_up) = sum(C_up .* basis .* (1i * beta_m), 1) .* phase_up;
      grady_reg(idx_up) = sum(C_up .* basis .* (1i * gamma_m), 1) .* phase_up;
      hessxx_reg(idx_up) = sum(C_up .* basis .* (-beta_m.^2), 1) .* phase_up;
      hessxy_reg(idx_up) = sum(C_up .* basis .* (-beta_m .* gamma_m), 1) .* phase_up;
      hessyy_reg(idx_up) = sum(C_up .* basis .* (-gamma_m.^2), 1) .* phase_up;
    end

    if any(idx_dn(:))
      X_dn = X0(idx_dn).';
      Y_dn = Y(idx_dn).';
      phase_X = exp(1i * beta_m * X_dn);
      phase_Y = exp(-1i * gamma_m * (Y_dn + H));
      basis = phase_X .* phase_Y;
      phase_dn = phase_shift(idx_dn).';

      pot_reg(idx_dn) = sum(C_down .* basis, 1) .* phase_dn;
      gradx_reg(idx_dn) = sum(C_down .* basis .* (1i * beta_m), 1) .* phase_dn;
      grady_reg(idx_dn) = sum(C_down .* basis .* (-1i * gamma_m), 1) .* phase_dn;
      hessxx_reg(idx_dn) = sum(C_down .* basis .* (-beta_m.^2), 1) .* phase_dn;
      hessxy_reg(idx_dn) = sum(C_down .* basis .* (beta_m .* gamma_m), 1) .* phase_dn;
      hessyy_reg(idx_dn) = sum(C_down .* basis .* (-gamma_m.^2), 1) .* phase_dn;
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function N1 = LOCAL_kress_tblock_log_coeff(wavek, xdiff, ydiff, r, dxdt, dydt, offdiag)

  ntot = length(dxdt);
  dxdt_t = repmat(dxdt(:), 1, ntot);
  dydt_t = repmat(dydt(:), 1, ntot);

  N1 = zeros(ntot, ntot);
  zprime_dot_diff = dxdt_t .* xdiff + dydt_t .* ydiff;
  N1(offdiag) = -(wavek / (2 * pi)) * (zprime_dot_diff(offdiag) ./ r(offdiag)) .* ...
    besselj(1, wavek * r(offdiag));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Rlog = LOCAL_kress_log_weight_matrix(L, ntot)

  if mod(ntot, 2) ~= 0
    error('Kress logarithmic weights require an even ntot.');
  end

  theta = (2 * pi / ntot) * L;
  Rlog = zeros(size(L));
  for m = 1:(ntot / 2 - 1)
    Rlog = Rlog - (2 / m) * cos(m * theta);
  end
  Rlog = Rlog - (2 / ntot) * cos((ntot / 2) * theta);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function log_kernel = LOCAL_kress_log_kernel_matrix(L, offdiag, ntot)

  theta = (pi / ntot) * L;
  log_kernel = zeros(size(L));
  log_kernel(offdiag) = log(4 * sin(theta(offdiag)).^2);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function N2diag = LOCAL_kress_tblock_N2_diag(dxdt, dx2dt, dydt, dy2dt)

  N2diag = (1 / (2 * pi)) * (dxdt .* dx2dt + dydt .* dy2dt) ./ (dxdt.^2 + dydt.^2);
  N2diag = N2diag(:);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_construct_A_loop(C, iprec, khint, pars1, proxy, curvelen)

  ntot = size(C, 2);
  A = eye(2 * ntot, 2 * ntot);
  [A11, A12, A21, A22, h, speed] = LOCAL_build_mueller_blocks(C, iprec, khint, pars1, proxy, curvelen);

  for ix = 1:ntot
    for iy = 1:ntot
      A(ix, iy) = A(ix, iy) + A11(ix, iy);
      A(ix, iy + ntot) = A12(ix, iy);
      A(ix + ntot, iy) = A21(ix, iy);
      A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) + A22(ix, iy);
    end
  end

  W = sqrt(h * diag([speed, speed]));
  Winv = sqrt((1 / h) * diag(1 ./ [speed, speed]));
  A = W * A * Winv;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_check_construct_A_optimized(check_ntot, flag_geom, iprec, check_k, ...
    nref, pars1, pars2)

  [Ccheck, curvelen_check, ~, ~] = LOCAL_construct_cont(check_ntot, flag_geom, 0, 0);
  pars1_check = pars1;
  pars1_check.k = check_k;

  t_start = tic;
  proxy_check = precomp_proxy(pars1_check, pars2);
  t_proxy = toc(t_start);

  t_start = tic;
  A_opt = LOCAL_construct_A(Ccheck, iprec, check_k * nref, pars1_check, proxy_check, curvelen_check);
  t_opt = toc(t_start);

  t_start = tic;
  A_ref = LOCAL_construct_A_loop(Ccheck, iprec, check_k * nref, pars1_check, proxy_check, curvelen_check);
  t_ref = toc(t_start);

  t_start = tic;
  s_opt = svd(A_opt);
  t_svd_opt = toc(t_start);

  t_start = tic;
  s_ref = svd(A_ref);
  t_svd_ref = toc(t_start);

  max_abs_diff = max(abs(A_opt(:) - A_ref(:)));
  rel_diff = max_abs_diff / max(1, max(abs(A_ref(:))));
  sv_diff = max(abs(s_opt(:) - s_ref(:)));

  fprintf('Consistency check for LOCAL_construct_A:\n');
  fprintf('  ntot = %d, k = %.8f\n', check_ntot, check_k);
  fprintf('  precomp_proxy time      = %.6f s\n', t_proxy);
  fprintf('  optimized assembly time = %.6f s\n', t_opt);
  fprintf('  loop assembly time      = %.6f s\n', t_ref);
  fprintf('  optimized svd time      = %.6f s\n', t_svd_opt);
  fprintf('  loop svd time           = %.6f s\n', t_svd_ref);
  fprintf('  max abs difference = %.3e\n', max_abs_diff);
  fprintf('  max rel difference = %.3e\n', rel_diff);
  fprintf('  max singular value difference = %.3e\n', sv_diff);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pot, grad, hess] = LOCAL_h2d_directch(wavek, sources, charge, targ)

  ns = size(sources, 2);
  nt = size(targ, 2);
  charge = reshape(charge, 1, []);
  if length(charge) ~= ns
    error('charge must have one entry per source.');
  end

  ima4inv = 1i / 4;
  xdiff = bsxfun(@minus, targ(1, :).', sources(1, :));
  ydiff = bsxfun(@minus, targ(2, :).', sources(2, :));
  rr = xdiff.^2 + ydiff.^2;
  r = sqrt(rr);
  z = wavek * r;

  h0 = besselh(0, z);
  h1 = besselh(1, z);
  cdd = -h1 .* (wavek * ima4inv ./ r);
  cdd2 = (wavek * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 * h1;
  hf1 = h2z .* xdiff .* xdiff - rr .* h1;
  hf2 = h2z .* xdiff .* ydiff;
  hf3 = h2z .* ydiff .* ydiff - rr .* h1;

  weighted_h0 = bsxfun(@times, h0, charge);
  weighted_cdd = bsxfun(@times, cdd, charge);
  weighted_cdd2 = bsxfun(@times, cdd2, charge);

  pot = ima4inv * sum(weighted_h0, 2).';
  grad = zeros(2, nt);
  grad(1, :) = sum(weighted_cdd .* xdiff, 2).';
  grad(2, :) = sum(weighted_cdd .* ydiff, 2).';

  hess = zeros(3, nt);
  hess(1, :) = sum(weighted_cdd2 .* hf1, 2).';
  hess(2, :) = sum(weighted_cdd2 .* hf2, 2).';
  hess(3, :) = sum(weighted_cdd2 .* hf3, 2).';

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
