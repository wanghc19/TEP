% Purpose:
%   Debug only the T-block (A21) assembly by comparing the old KR-based
%   reference block from tep_scan_local2.m with the Kress-style block used in
%   tep_scan_local3.m.
%
% Main algorithm:
%   For one fixed geometry and wavenumber, build the boundary data and proxy
%   remainder, then assemble three T-block views: the old/reference KR block,
%   the current Kress-style block, and decomposition-level quantities
%   consisting of the raw difference kernel, the logarithmic part, and the
%   smooth remainder.  The script prints near-diagonal diagnostics for
%   selected rows and generates a few simple comparison plots.
%
% Based on:
%   tep_scan_local2.m and tep_scan_local3.m.
%
% Main changes:
%   This file does not run the local scan/refinement workflow.  It reuses the
%   trusted geometry and kernel helpers only to inspect the T-block near the
%   diagonal and to compare the KR and Kress constructions.
%
% Numerical goal:
%   Diagnose whether the current Kress T-block failure is caused by an
%   incorrect logarithmic coefficient, a non-smooth remainder, failed cot
%   cancellation, or a large magnitude mismatch with the old reference block.
format long;
clear;

% --- 1. Representative Test Setup ---
ntot = 100;                         % Representative boundary discretization for T-block debugging
flag_geom = 'ellipse';              % Geometry type: 'star' or 'ellipse'
iprec = 10;                         % KR order used only for the old/reference T-block
er = 13;                            % Relative permittivity; nref = sqrt(er)
nref = sqrt(er);
d = 1.0;                            % Period length of the waveguide cell
beta = 0.5 * 2 * pi / d;            % Fixed Bloch phase
k_test = 2.6535097381199977;        % Representative exterior wavenumber for the diagnostic

pars1.beta = beta;
pars1.d = d;
pars1.k = k_test;

pars2.H = 0.5 * pars1.d;            % Height of the fundamental domain [-H, H]
pars2.proxy_dist = 0.2 * pars1.d;   % Distance of proxy boundary from the domain
pars2.N_side = 50;                  % Number of collocation points on Left/Right walls
pars2.N_top = 50;                   % Number of collocation points on Top/Bottom walls
pars2.N_proxy_edge = 30;            % Number of proxy sources per edge
pars2.M_pw = 10;                    % Truncation order for plane waves (-M_pw to M_pw)

rows_to_check = [round(ntot / 2), round(ntot / 2) + 1];
diag_half_width = 5;                % Inspect j = i0-diag_half_width : i0+diag_half_width with periodic wrap

fprintf('T-block diagnostic for tep_scan_local3.m\n');
fprintf('  Geometry            : %s\n', flag_geom);
fprintf('  ntot                : %d\n', ntot);
fprintf('  k_test              : %.16f\n', k_test);
fprintf('  beta                : %.16f\n', beta);
fprintf('  nref                : %.16f\n', nref);
fprintf('  rows_to_check       : [%s]\n', num2str(rows_to_check));
fprintf('  near-diagonal range : +/- %d\n', diag_half_width);

% --- 2. Build Geometry and Proxy Data ---
[C, curvelen, ~, ~] = LOCAL_construct_cont(ntot, flag_geom, 0, 0);
proxy = precomp_proxy(pars1, pars2);

% --- 3. Build T-block Diagnostics ---
results = LOCAL_build_tblock_diagnostics(C, iprec, nref, pars1, proxy, curvelen);
LOCAL_print_global_tblock_diagnostics(results);

for idx = 1:length(rows_to_check)
  row_idx = LOCAL_wrap_indices(rows_to_check(idx), ntot);
  LOCAL_print_row_diagnostics(results, row_idx, diag_half_width);
end

LOCAL_plot_tblock_diagnostics(results, rows_to_check, diag_half_width);

fprintf('\nT-block diagnostic completed successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function results = LOCAL_build_tblock_diagnostics(C, iprec, nref, pars1, proxy, curvelen)

  ntot = size(C, 2);
  h = curvelen / ntot;
  khint = pars1.k * nref;

  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dx2dt = C(3, :);
  dydt = C(5, :);
  dy2dt = C(6, :);
  speed = sqrt(dxdt.^2 + dydt.^2);
  src_weight = h * speed;
  src_speed = repmat(speed, ntot, 1);

  nx1 = (dydt ./ speed).';
  nx2 = (-dxdt ./ speed).';
  ny1 = nx1.';
  ny2 = nx2.';
  nx1ny1 = nx1 * ny1;
  nx1ny2_nx2ny1 = nx1 * ny2 + nx2 * ny1;
  nx2ny2 = nx2 * ny2;

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;
  offdiag = L ~= 0;
  diag_idx = 1:(ntot + 1):(ntot * ntot);

  points = [x; y];
  [~, ~, ~, hessxx_int, hessxy_int, hessyy_int] = LOCAL_free_space_pairmat(khint, points, points);
  [~, ~, ~, hessxx_center, hessxy_center, hessyy_center] = LOCAL_free_space_pairmat(pars1.k, points, points);
  [~, ~, ~, hessxx_reg, hessxy_reg, hessyy_reg] = LOCAL_qpgreen_regular_pairmat(points, points, pars1, proxy);
  [~, ~, ~, hessxx_ext_full, hessxy_ext_full, hessyy_ext_full] = ...
    LOCAL_qpgreen_mfs_pairmat(points, points, pars1, proxy);

  % Old/reference KR-based T-block from tep_scan_local2.m.
  A21_old = ((hessxx_int - hessxx_ext_full) .* nx1ny1 + ...
             (hessxy_int - hessxy_ext_full) .* nx1ny2_nx2ny1 + ...
             (hessyy_int - hessyy_ext_full) .* nx2ny2) .* repmat(src_weight, ntot, 1);
  A21_old = A21_old .* LOCAL_get_kr_corr_matrix(ntot, iprec, L, offdiag);

  % Decomposition pieces used by tep_scan_local3.m.
  xdiff = x.' - x;
  ydiff = y.' - y;
  rr = xdiff.^2 + ydiff.^2;
  rr(~offdiag) = 1;
  r = sqrt(rr);

  N1_int = LOCAL_kress_tblock_log_coeff(khint, xdiff, ydiff, r, dxdt, dydt, offdiag);
  N1_center = LOCAL_kress_tblock_log_coeff(pars1.k, xdiff, ydiff, r, dxdt, dydt, offdiag);
  N1diff = N1_int - N1_center;
  N1diff(diag_idx) = 0;

  raw_free_int = ((hessxx_int .* nx1ny1 + hessxy_int .* nx1ny2_nx2ny1 + hessyy_int .* nx2ny2) .* src_speed);
  raw_free_center = ((hessxx_center .* nx1ny1 + hessxy_center .* nx1ny2_nx2ny1 + hessyy_center .* nx2ny2) .* src_speed);
  raw_reg = ((hessxx_reg .* nx1ny1 + hessxy_reg .* nx1ny2_nx2ny1 + hessyy_reg .* nx2ny2) .* src_speed);

  raw_difference = raw_free_int - raw_free_center - raw_reg;

  cot_kernel = LOCAL_kress_cot_kernel_matrix(L, offdiag, ntot);
  log_kernel = LOCAL_kress_log_kernel_matrix(L, offdiag, ntot);
  N2_int_free = raw_free_int - cot_kernel - log_kernel .* N1_int;
  N2_center_free = raw_free_center - cot_kernel - log_kernel .* N1_center;
  N2diag_free = LOCAL_kress_tblock_N2_diag(dxdt, dx2dt, dydt, dy2dt);
  N2_int_free(diag_idx) = N2diag_free.';
  N2_center_free(diag_idx) = N2diag_free.';

  N2diff = N2_int_free - N2_center_free - raw_reg;
  log_part = log_kernel .* N1diff;
  N2diff(diag_idx) = -raw_reg(diag_idx);
  log_part(diag_idx) = 0;
  raw_difference(diag_idx) = N2diff(diag_idx);

  Rlog = LOCAL_kress_log_weight_matrix(L, ntot);
  A21_new = Rlog .* N1diff + h * N2diff;

  % Scaled versions match the actual matrix block entries after W * A * Winv.
  scale_row = sqrt(h * speed(:));
  scale_col = sqrt((1 / h) ./ speed(:)).';
  scale_block = scale_row * scale_col;
  A21_old_scaled = A21_old .* scale_block;
  A21_new_scaled = A21_new .* scale_block;

  % Diagnostics for failed cot cancellation and remainder smoothness.
  recon_error = raw_difference - (log_part + N2diff);
  cot_cancel_error = raw_difference - ((log_kernel .* N1diff) + (N2_int_free - N2_center_free - raw_reg));

  results.ntot = ntot;
  results.k_test = pars1.k;
  results.beta = pars1.beta;
  results.nref = nref;
  results.h = h;
  results.speed = speed;
  results.L = L;
  results.offdiag = offdiag;
  results.diag_idx = diag_idx;
  results.raw_difference = raw_difference;
  results.N1diff = N1diff;
  results.log_part = log_part;
  results.N2diff = N2diff;
  results.A21_old = A21_old;
  results.A21_new = A21_new;
  results.A21_old_scaled = A21_old_scaled;
  results.A21_new_scaled = A21_new_scaled;
  results.recon_error = recon_error;
  results.cot_cancel_error = cot_cancel_error;
  results.N2_int_free = N2_int_free;
  results.N2_center_free = N2_center_free;
  results.raw_reg = raw_reg;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_global_tblock_diagnostics(results)

  offdiag = results.offdiag;

  fprintf('\nGlobal T-block diagnostics:\n');
  fprintf('  max |N1diff(diagonal)|               = %.6e\n', max(abs(diag(results.N1diff))));
  fprintf('  max |reconstruction residual|        = %.6e\n', max(abs(results.recon_error(:))));
  fprintf('  max |cot cancellation residual|      = %.6e\n', max(abs(results.cot_cancel_error(:))));
  fprintf('  max |N2diff offdiag|                 = %.6e\n', max(abs(results.N2diff(offdiag))));
  fprintf('  max |old-new T-block diff|           = %.6e\n', max(abs(results.A21_new(:) - results.A21_old(:))));
  fprintf('  max |old-new scaled T-block diff|    = %.6e\n', max(abs(results.A21_new_scaled(:) - results.A21_old_scaled(:))));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_row_diagnostics(results, row_idx, diag_half_width)

  ntot = results.ntot;
  offsets = -diag_half_width:diag_half_width;
  j_idx = LOCAL_wrap_indices(row_idx + offsets, ntot);

  fprintf('\nRow diagnostics for i0 = %d\n', row_idx);
  fprintf(['  %-8s %-8s %-24s %-24s %-24s %-24s %-24s %-24s %-24s\n'], ...
    'offset', 'j', 'raw_diff', 'N1diff', 'log_part', 'N2diff', ...
    'new_T', 'old_T', 'new-old');

  for q = 1:length(j_idx)
    j = j_idx(q);
    fprintf(['  %-8d %-8d %-24s %-24s %-24s %-24s %-24s %-24s %-24s\n'], ...
      offsets(q), j, ...
      LOCAL_complex_string(results.raw_difference(row_idx, j)), ...
      LOCAL_complex_string(results.N1diff(row_idx, j)), ...
      LOCAL_complex_string(results.log_part(row_idx, j)), ...
      LOCAL_complex_string(results.N2diff(row_idx, j)), ...
      LOCAL_complex_string(results.A21_new(row_idx, j)), ...
      LOCAL_complex_string(results.A21_old(row_idx, j)), ...
      LOCAL_complex_string(results.A21_new(row_idx, j) - results.A21_old(row_idx, j)));
  end

  fprintf('  Checks near the diagonal:\n');
  fprintf('    diagonal N1diff                    = %s\n', LOCAL_complex_string(results.N1diff(row_idx, row_idx)));
  if diag_half_width >= 1
    jm = LOCAL_wrap_indices(row_idx - 1, ntot);
    jp = LOCAL_wrap_indices(row_idx + 1, ntot);
    fprintf('    nearest-neighbor N1diff (j=i0-1)   = %s\n', LOCAL_complex_string(results.N1diff(row_idx, jm)));
    fprintf('    nearest-neighbor N1diff (j=i0+1)   = %s\n', LOCAL_complex_string(results.N1diff(row_idx, jp)));
    fprintf('    nearest-neighbor N2diff (j=i0-1)   = %s\n', LOCAL_complex_string(results.N2diff(row_idx, jm)));
    fprintf('    nearest-neighbor N2diff (j=i0+1)   = %s\n', LOCAL_complex_string(results.N2diff(row_idx, jp)));
    fprintf('    nearest-neighbor |old T|           = %.6e, %.6e\n', ...
      abs(results.A21_old(row_idx, jm)), abs(results.A21_old(row_idx, jp)));
    fprintf('    nearest-neighbor |new T|           = %.6e, %.6e\n', ...
      abs(results.A21_new(row_idx, jm)), abs(results.A21_new(row_idx, jp)));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_tblock_diagnostics(results, rows_to_check, diag_half_width)

  ntot = results.ntot;
  rows_to_check = LOCAL_wrap_indices(rows_to_check, ntot);
  x_full = 1:ntot;
  offsets = -diag_half_width:diag_half_width;
  cmap = lines(length(rows_to_check));

  figure('Name', 'T-block Row Magnitudes', 'Color', 'w');
  hold on;
  for q = 1:length(rows_to_check)
    row_idx = rows_to_check(q);
    semilogy(x_full, abs(results.A21_old_scaled(row_idx, :)), '--', 'LineWidth', 1.2, ...
      'Color', cmap(q, :), 'DisplayName', sprintf('old row %d', row_idx));
    semilogy(x_full, abs(results.A21_new_scaled(row_idx, :)), '-', 'LineWidth', 1.2, ...
      'Color', cmap(q, :), 'HandleVisibility', 'off');
  end
  grid on;
  xlabel('Column index j', 'FontSize', 11);
  ylabel('|scaled T-block row entry|', 'FontSize', 11);
  title('Scaled old/reference and new Kress T-block magnitudes', 'FontSize', 12);
  legend('Location', 'best');

  for q = 1:length(rows_to_check)
    row_idx = rows_to_check(q);
    j_idx = LOCAL_wrap_indices(row_idx + offsets, ntot);

    figure('Name', sprintf('T-block Near Diagonal Row %d', row_idx), 'Color', 'w');
    plot(offsets, real(results.raw_difference(row_idx, j_idx)), 'o-', 'LineWidth', 1.2, ...
      'DisplayName', 'real(raw difference)');
    hold on;
    plot(offsets, real(results.log_part(row_idx, j_idx)), 's-', 'LineWidth', 1.2, ...
      'DisplayName', 'real(log part)');
    plot(offsets, real(results.N2diff(row_idx, j_idx)), 'd-', 'LineWidth', 1.2, ...
      'DisplayName', 'real(smooth remainder)');
    grid on;
    xlabel('offset j-i0', 'FontSize', 11);
    ylabel('Real part', 'FontSize', 11);
    title(sprintf('Near-diagonal decomposition for row %d', row_idx), 'FontSize', 12);
    legend('Location', 'best');

    figure('Name', sprintf('N1diff Near Diagonal Row %d', row_idx), 'Color', 'w');
    plot(offsets, real(results.N1diff(row_idx, j_idx)), 'o-', 'LineWidth', 1.2, ...
      'DisplayName', 'real(N1diff)');
    hold on;
    plot(offsets, imag(results.N1diff(row_idx, j_idx)), 's-', 'LineWidth', 1.2, ...
      'DisplayName', 'imag(N1diff)');
    grid on;
    xlabel('offset j-i0', 'FontSize', 11);
    ylabel('Value', 'FontSize', 11);
    title(sprintf('N1diff near the diagonal for row %d', row_idx), 'FontSize', 12);
    legend('Location', 'best');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function idx = LOCAL_wrap_indices(idx, ntot)

  idx = mod(idx - 1, ntot) + 1;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function text = LOCAL_complex_string(z)

  text = sprintf('%.6e%+.6ei', real(z), imag(z));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function corr = LOCAL_get_kr_corr_matrix(ntot, iprec, L, offdiag)

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

function cot_kernel = LOCAL_kress_cot_kernel_matrix(L, offdiag, ntot)

  theta = (pi / ntot) * L;
  cot_kernel = zeros(size(L));
  cot_kernel(offdiag) = (1 / (2 * pi)) * cot(theta(offdiag));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function N2diag = LOCAL_kress_tblock_N2_diag(dxdt, dx2dt, dydt, dy2dt)

  N2diag = (1 / (2 * pi)) * (dxdt .* dx2dt + dydt .* dy2dt) ./ (dxdt.^2 + dydt.^2);
  N2diag = N2diag(:);

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
