function tep_construct_A_benchmark
% Purpose:
%   Benchmark the optimized vectorized matrix assembly against the loop-based
%   reference assembly for the TEP Muller system.
%
% Main algorithm:
%   Build one boundary discretization, precompute the quasi-periodic proxy
%   coefficients, assemble the matrix with the optimized path, assemble the
%   same matrix with the loop reference path, compute singular values for both
%   matrices, and report timing plus consistency differences.  Both assembly
%   paths use the same tep_scan_local.m off-diagonal formula and the same
%   diagonal correction so that the comparison controls all variables except
%   vectorized versus loop-based evaluation.
%
% Based on:
%   The former LOCAL_construct_A_loop and LOCAL_check_construct_A_optimized
%   helpers in tep_scan_local.m, tep_scan_local2.m, and tep_scan_global.m.
%   This file uses tep_scan_local.m as the canonical off-diagonal assembly
%   source, with an explicit diagonal correction applied identically in both
%   optimized and loop-based paths.
%
% Main changes:
%   Matrix-assembly benchmarking is separated from the production scan
%   scripts.  The scan scripts keep only their active LOCAL_construct_A
%   implementations, while this benchmark owns the loop assembly and timing
%   comparison workflow.
%
% Numerical goal:
%   Measure the speedup from vectorized matrix assembly, quantify the cost of
%   proxy precomputation and SVD, and verify under controlled variables that
%   the optimized and loop-based assemblies agree up to normal floating-point
%   roundoff for the selected benchmark parameters.
format long;
clear;

% --- 1. Benchmark Parameter Setup ---
benchmark_ntot = 60;                % Boundary point count used in the benchmark
flag_geom = 'ellipse';              % Geometry type: 'star' or 'ellipse'
iprec = 10;                         % Kapur-Rokhlin correction order
er = 13;                            % Interior dielectric coefficient
nref = sqrt(er);                    % Interior refractive index
d = 1.0;                            % Period in the x-direction
beta = 0.5 * 2 * pi / d;            % Fixed Bloch phase
benchmark_k = 0.73 * beta;          % Wavenumber used for the comparison

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.5 * pars1.d;            % Height of the fundamental domain [-H, H]
pars2.proxy_dist = 0.2 * pars1.d;   % Distance of proxy boundary from the domain
pars2.N_side = 50;                  % Collocation points on left/right walls
pars2.N_top = 50;                   % Collocation points on top/bottom walls
pars2.N_proxy_edge = 30;            % Proxy sources per edge of the proxy box
pars2.M_pw = 10;                    % Plane-wave truncation order (-M_pw to M_pw)

LOCAL_check_construct_A_optimized(benchmark_ntot, flag_geom, iprec, ...
  benchmark_k, nref, pars1, pars2);

end

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function LOCAL_check_construct_A_optimized(check_ntot, flag_geom, iprec, check_k, ...
    nref, pars1, pars2)

  t_total_start = tic;

  [Ccheck, curvelen_check, ~, ~] = geom.construct_cont(check_ntot, flag_geom, 0, 0);
  pars1_check = pars1;
  pars1_check.k = check_k;

  t_start = tic;
  proxy_check = kernel.precomp_proxy(pars1_check, pars2);
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
  t_total = toc(t_total_start);

  fprintf('Construct_A benchmark and consistency check:\n');
  fprintf('  geometry = %s, ntot = %d, k = %.8f\n', flag_geom, check_ntot, check_k);
  fprintf('  assembly formula        = tep_scan_local off-diagonal + shared diagonal correction\n');
  fprintf('  precomp_proxy time      = %.6f s\n', t_proxy);
  fprintf('  optimized assembly time = %.6f s\n', t_opt);
  fprintf('  loop assembly time      = %.6f s\n', t_ref);
  fprintf('  optimized svd time      = %.6f s\n', t_svd_opt);
  fprintf('  loop svd time           = %.6f s\n', t_svd_ref);
  fprintf('  total workflow time     = %.6f s\n', t_total);
  fprintf('  max abs difference      = %.3e\n', max_abs_diff);
  fprintf('  max rel difference      = %.3e\n', rel_diff);
  fprintf('  max singular-value diff = %.3e\n', sv_diff);

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

  % The diagonal correction is applied in both optimized and loop paths so
  % that this benchmark changes only the implementation strategy.
  [R_diag, gradR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy);

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

  A12(diag_idx) = (-log(khint / pars1.k) / (2 * pi) - R_diag) .* src_weight;
  % Since R_k is represented in target-minus-source coordinates near the
  % diagonal, -d/dn_y R_k is grad_x R_k dot n_y.
  A11(diag_idx) = (gradR_diag(1) .* ny1 + gradR_diag(2) .* ny2) .* src_weight;
  A22(diag_idx) = -(gradR_diag(1) .* nx1.' + gradR_diag(2) .* nx2.') .* src_weight;

  % The off-diagonal correction follows the tep_scan_local.m assembly path.
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

function [R_diag, gradR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy)

  % At x = y, the singular center image Phi_k is omitted.  The proxy/MFS
  % sources represent the regular remainder R_k in the local cell.
  [R_diag, gradR_diag, ~] = kernel.h2d_directch(pars1.k, proxy.Z, proxy.q, [0; 0]);
  R_diag = R_diag(1);
  gradR_diag = gradR_diag(:, 1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_construct_A_loop(C, iprec, khint, pars1, proxy, curvelen)

  ntot = size(C, 2);
  A = eye(2 * ntot, 2 * ntot);
  h = curvelen / ntot;
  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;

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

  [R_diag, gradR_diag] = LOCAL_qpgreen_regular_diagonal(pars1, proxy);

  for ix = 1:ntot
    for iy = 1:ntot
      l = L(ix, iy);
      speedx = sqrt(C(2, ix)^2 + C(5, ix)^2);
      speedy = sqrt(C(2, iy)^2 + C(5, iy)^2);
      nx1 =  C(5, ix) / speedx;
      nx2 = -C(2, ix) / speedx;
      ny1 =  C(5, iy) / speedy;
      ny2 = -C(2, iy) / speedy;

      if l == 0
        A(ix, iy) = A(ix, iy) + (gradR_diag(1) * ny1 + gradR_diag(2) * ny2) * h * speedy;
        A(ix, iy + ntot) = (-log(khint / pars1.k) / (2 * pi) - R_diag) * h * speedy;
        A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) - ...
          (gradR_diag(1) * nx1 + gradR_diag(2) * nx2) * h * speedy;
        continue;
      end

      [pot, grad, hess] = kernel.h2d_directch(khint, C([1, 4], iy), 1, C([1, 4], ix));
      A(ix, iy) = (ny1 * grad(1) + ny2 * grad(2)) * h * speedy;
      A(ix, iy + ntot) = pot * h * speedy;
      A(ix + ntot, iy) = (nx1 * ny1 * hess(1) + (nx1 * ny2 + nx2 * ny1) * hess(2) + nx2 * ny2 * hess(3)) * h * speedy;
      A(ix + ntot, iy + ntot) = (nx1 * grad(1) + nx2 * grad(2)) * h * speedy;

      u = kernel.qpgreen_mfs(C([1, 4], iy), C([1, 4], ix), pars1, proxy);
      pot = u.pot;
      grad = u.grad;
      hess = u.hess;
      A(ix, iy) = A(ix, iy) - (ny1 * grad(1) + ny2 * grad(2)) * h * speedy;
      A(ix, iy + ntot) = A(ix, iy + ntot) - pot * h * speedy;
      A(ix + ntot, iy) = A(ix + ntot, iy) - ...
        (nx1 * ny1 * hess(1) + (nx1 * ny2 + nx2 * ny1) * hess(2) + nx2 * ny2 * hess(3)) * h * speedy;
      A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) - (nx1 * grad(1) + nx2 * grad(2)) * h * speedy;

      if abs(l) <= width
        A(ix, iy) = A(ix, iy) * (1 + MU(abs(l)));
        A(ix, iy + ntot) = A(ix, iy + ntot) * (1 + MU(abs(l)));
        A(ix + ntot, iy) = A(ix + ntot, iy) * (1 + MU(abs(l)));
        A(ix + ntot, iy + ntot) = A(ix + ntot, iy + ntot) * (1 + MU(abs(l)));
      end
    end
  end

  speed = sqrt(C(2,:).^2 + C(5,:).^2);
  W = sqrt(h * diag([speed, speed]));
  Winv = sqrt((1 / h) * diag(1 ./ [speed, speed]));
  A = W * A * Winv;

end
