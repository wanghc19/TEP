function A_QP = LOCAL_construct_A_QP_anchored( ...
    C, kext, kint, pars1, proxy, proxy_gamma, curvelen)
% LOCAL_CONSTRUCT_A_QP_ANCHORED Assemble the I4 anchored Muller matrix.
%
% Purpose:
%   Reproduce the package A_QP assembly while redirecting its quasiperiodic
%   Green evaluation to the test-local anchored pair-matrix function.
%
% Input/Output:
%   Matches op.construct_A_QP, with proxy_gamma added before curvelen.
%
% Based on:
%   +op/construct_A_QP.m.
%
% Main changes:
%   Only the function interface and Green evaluator data flow differ.
%
% Numerical goal:
%   Supply branch-consistent center and bulk BIE matrices for I4.

  pars1.k = kext;
  ntot = size(C, 2);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  speed = sqrt(dxdt.^2 + dydt.^2);

  [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    LOCAL_qpgreen_mfs_pairmat_anchored( ...
    [x; y], [x; y], pars1, proxy, proxy_gamma);
  [R_diag, gradR_diag, hessR_diag] = ...
    LOCAL_qpgreen_regular_diagonal(pars1, proxy);
  [A11, A22] = LOCAL_assemble_D_blocks_kress(C, kint, kext, ...
    gradx_ext, grady_ext, gradR_diag, curvelen);
  A12 = LOCAL_assemble_Sdiff_kress( ...
    C, kint, kext, pot_ext, R_diag, curvelen);
  A21 = LOCAL_assemble_Tdiff_qp(C, kint, pars1, hessxx_ext, ...
    hessxy_ext, hessyy_ext, hessR_diag, curvelen);

  A_QP = eye(2 * ntot, 2 * ntot);
  A_QP(1:ntot, 1:ntot) = A_QP(1:ntot, 1:ntot) + A11;
  A_QP(1:ntot, ntot + 1:end) = A12;
  A_QP(ntot + 1:end, 1:ntot) = A21;
  A_QP(ntot + 1:end, ntot + 1:end) = ...
    A_QP(ntot + 1:end, ntot + 1:end) + A22;
  scale_row = sqrt(h * [speed, speed]).';
  scale_col = sqrt((1 / h) ./ [speed, speed]);
  A_QP = bsxfun(@times, bsxfun(@times, A_QP, scale_col), scale_row);
end

%% ==================== Green diagonal and axis ====================
% These helpers preserve the package regular-diagonal convention.

function [R_diag, gradR_diag, hessR_diag] = ...
    LOCAL_qpgreen_regular_diagonal(pars1, proxy)
  [R_diag, gradR_diag, hessR_diag] = ...
    kernel.h2d_directch(pars1.k, proxy.Z, proxy.q, [0; 0]);
  R_diag = R_diag(1);
  gradR_diag = gradR_diag(:, 1);
  hessR_diag = hessR_diag(:, 1);
  periodic_axis = LOCAL_parse_periodic_axis(pars1);
  if strcmp(periodic_axis, 'y')
    gradR_diag = gradR_diag([2 1]);
    hessR_diag = hessR_diag([3 2 1]);
  end
end

function periodic_axis = LOCAL_parse_periodic_axis(pars1)
  periodic_axis = 'x';
  if isfield(pars1, 'periodic_axis') && ~isempty(pars1.periodic_axis)
    periodic_axis = pars1.periodic_axis;
  end
  if isstring(periodic_axis)
    periodic_axis = char(periodic_axis);
  end
  periodic_axis = lower(strtrim(periodic_axis));
  if ~strcmp(periodic_axis, 'x') && ~strcmp(periodic_axis, 'y')
    error('analytic_readiness:InvalidPeriodicAxis', ...
      'periodic_axis must be x or y.');
  end
end

%% ==================== Muller D blocks ====================
% These helpers assemble the Kress double-layer differences.

function [A11, A22] = LOCAL_assemble_D_blocks_kress(C, kin, kout, ...
    gradx_qp, grady_qp, gradR_diag, curvelen)
  ntot = size(C, 2);
  if mod(ntot, 2) ~= 0
    error('analytic_readiness:OddBoundaryCount', ...
      'Kress assembly requires an even number of nodes.');
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
  geom_data.zpp = [C(3, :).', C(6, :).'];
  geom_data.speed = speed.';
  R = LOCAL_kress_matrix(ntot);
  [L1_in, L2_in, Ls1_in, Ls2_in] = ...
    kernel.kress_l_splits(kin, t, geom_data);
  [L1_out, L2_out, Ls1_out, Ls2_out] = ...
    kernel.kress_l_splits(kout, t, geom_data);
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
  A11_proxy = -((gradx_proxy .* ny1mat + ...
    grady_proxy .* ny2mat) .* weight_mat);
  A22_proxy = -((gradx_proxy .* nx1mat + ...
    grady_proxy .* nx2mat) .* weight_mat);
  A11 = A11_free + A11_proxy;
  A22 = A22_free + A22_proxy;
end

function [gradx, grady] = LOCAL_free_gradient_matrices(k, x, y)
  ntot = length(x);
  [jj, ii] = meshgrid(1:ntot, 1:ntot); %#ok<ASGLU>
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

%% ==================== Muller S block ====================
% These helpers assemble the Kress single-layer difference.

function A12 = LOCAL_assemble_Sdiff_kress( ...
    C, kin, kout, pot_qp, R_diag, curvelen)
  ntot = size(C, 2);
  if mod(ntot, 2) ~= 0
    error('analytic_readiness:OddBoundaryCount', ...
      'Kress assembly requires an even number of nodes.');
  end
  [t, ~] = utils.triginterp(ntot);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  geom_data.z = [x.', y.'];
  geom_data.zp = [dxdt.', dydt.'];
  geom_data.zpp = [C(3, :).', C(6, :).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));
  R = LOCAL_kress_matrix(ntot);
  [M1_in, M2_in] = kernel.kress_mn_splits(kin, t, geom_data);
  [M1_out, M2_out] = kernel.kress_mn_splits(kout, t, geom_data);
  A12_free = R .* (M1_in - M1_out) + h * (M2_in - M2_out);
  A12 = A12_free + LOCAL_assemble_S_proxy(C, kout, pot_qp, R_diag, h);
end

function A12_proxy = LOCAL_assemble_S_proxy(C, kout, pot_qp, R_diag, h)
  ntot = size(C, 2);
  x = C(1, :);
  y = C(4, :);
  speed = sqrt(C(2, :).^2 + C(5, :).^2);
  [jj, ii] = meshgrid(1:ntot, 1:ntot); %#ok<ASGLU>
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

%% ==================== Muller T block ====================
% These helpers assemble the free and proxy hypersingular differences.

function Tdiff = LOCAL_assemble_Tdiff_qp(C, khint, pars1, hessxx_qp, ...
    hessxy_qp, hessyy_qp, hessR_diag, curvelen)
  ntot = size(C, 2);
  if mod(ntot, 2) ~= 0
    error('analytic_readiness:OddBoundaryCount', ...
      'Kress assembly requires an even number of nodes.');
  end
  [t, D] = utils.triginterp(ntot);
  h = curvelen / ntot;
  geom_data.z = [C(1, :).', C(4, :).'];
  geom_data.zp = [C(2, :).', C(5, :).'];
  geom_data.zpp = [C(3, :).', C(6, :).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));
  Tdiff_free = LOCAL_assemble_Tdiff_free( ...
    t, D, geom_data, pars1.k, khint);
  Tdiff_proxy = LOCAL_assemble_Tdiff_proxy(C, pars1.k, hessxx_qp, ...
    hessxy_qp, hessyy_qp, hessR_diag, h);
  Tdiff = Tdiff_free + Tdiff_proxy;
end

function Tdiff_free = LOCAL_assemble_Tdiff_free( ...
    t, D, geom_data, k1, k2)
  ntot = length(t);
  h = 2 * pi / ntot;
  R = LOCAL_kress_matrix(ntot);
  G = (geom_data.zp * geom_data.zp.') ./ ...
    (geom_data.speed * geom_data.speed.');
  [M1_k1, M2_k1, N1_k1, N2_k1] = ...
    kernel.kress_mn_splits(k1, t, geom_data);
  [M1_k2, M2_k2, N1_k2, N2_k2] = ...
    kernel.kress_mn_splits(k2, t, geom_data);
  delta_M1 = k1^2 * M1_k1 - k2^2 * M1_k2;
  delta_M2 = k1^2 * M2_k1 - k2^2 * M2_k2;
  delta_N1 = N1_k1 - N1_k2;
  delta_N2 = N2_k1 - N2_k2;
  A = (R .* delta_M1 + h * delta_M2) .* G;
  B_unscaled = R .* delta_N1 + h * delta_N2;
  B = bsxfun(@rdivide, B_unscaled, geom_data.speed);
  Tdiff_free = A + B * D;
end

function R = LOCAL_kress_matrix(ntot)
  rvec = quad.quad_kress_rvec(ntot);
  offset_idx = mod((0:ntot - 1) - (0:ntot - 1).', ntot) + 1;
  R = rvec(offset_idx);
end

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
  [jj, ii] = meshgrid(1:ntot, 1:ntot); %#ok<ASGLU>
  offdiag = ii ~= jj;
  [hessxx_free, hessxy_free, hessyy_free] = ...
    LOCAL_free_hessian_matrices(k, x, y, offdiag);
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
  Tdiff_proxy = -((hessxx_proxy .* nx1ny1 + ...
    hessxy_proxy .* nx1ny2_nx2ny1 + ...
    hessyy_proxy .* nx2ny2) .* weight_mat);
end

function [hessxx, hessxy, hessyy] = ...
    LOCAL_free_hessian_matrices(k, x, y, offdiag)
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
