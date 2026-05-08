function A_QP = construct_A_QP(C, kext, kint, pars1, proxy, curvelen)
% Purpose:
%   Construct the quasi-periodic Muller matrix A_QP for the 1D periodic
%   waveguide transmission eigenvalue problem.
%
% Mathematical form:
%   This function constructs
%
%     A_QP =
%       [ I  0
%         0  I ]
%       +
%       [ D_QP^{(kext)} - D^{(kint)},      S^{(kint)} - S_QP^{(kext)}
%         T_QP^{(kext)} - T^{(kint)},      D^{(kint),*} - D_QP^{(kext),*} ],
%
%   acting on the unknown vector
%
%     eta = [ tau ; -sigma ].
%
%   Here D is the double-layer operator, S is the single-layer operator,
%   T is the hypersingular operator, and D* is the adjoint double-layer
%   operator.  The QP superscript denotes the exterior quasi-periodic
%   Green's function with wavenumber kext.  The non-QP operators use the
%   interior free-space Green's function with wavenumber kint.
%
% Inputs:
%   C:
%     Boundary geometry and discretization data structure used by the
%     existing code.  Rows 1,4 store node coordinates, rows 2,5 store
%     first derivatives, and rows 3,6 store second derivatives.
%   kext:
%     Exterior wavenumber used in the quasi-periodic Green/proxy
%     evaluation and the exterior Kress split kernels.
%   kint:
%     Interior wavenumber used in the free-space Green's function and the
%     interior Kress split kernels.
%   pars1:
%     Quasi-periodic Green/proxy parameter structure used by the existing
%     code.  The field pars1.k is set to kext before calling the existing
%     kernel routines.
%   proxy:
%     Proxy/precomputation data returned by kernel.precomp_proxy for pars1.
%   curvelen:
%     Curve length used to set the trapezoid panel size h = curvelen/ntot.
%
% Output:
%   A_QP:
%     The full Muller matrix including the identity contribution in the
%     (1,1) and (2,2) block positions.
%
% Sign convention:
%   The second density variable in the matrix unknown is -sigma, not sigma.
%   The block signs above and below are interpreted relative to
%   eta = [tau; -sigma].
%
% Based on:
%   waveguide_1d/tep_scan_local4_2.m, specifically LOCAL_construct_A and
%   the local helpers used only to assemble A_QP.
%
% Main changes:
%   Move the A_QP assembly into an op package function while preserving the
%   Kress split quadrature, proxy correction, hypersingular A + B*D block,
%   and original block signs.
%
% Numerical goal:
%   Provide a reusable A_QP constructor for local 1D TEP scans without
%   changing the numerical matrix assembled by tep_scan_local4_2.m.

  pars1.k = kext;

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
  [A11, A22] = LOCAL_assemble_D_blocks_kress(C, kint, kext, ...
    gradx_ext, grady_ext, gradR_diag, curvelen);
  A12 = LOCAL_assemble_Sdiff_kress(C, kint, kext, pot_ext, R_diag, curvelen);
  A21 = LOCAL_assemble_Tdiff_qp(C, kint, pars1, hessxx_ext, hessxy_ext, ...
    hessyy_ext, hessR_diag, curvelen);

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
