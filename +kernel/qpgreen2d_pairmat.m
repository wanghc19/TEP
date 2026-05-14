function [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext, aux] = ...
    qpgreen2d_pairmat(src, trg, pars2d, proxy2d)
% QPGREEN2D_PAIRMAT Build pair matrices for the 2D quasiperiodic Green function.
%
% Purpose:
%   Evaluates dense target-by-source matrices for the doubly-quasiperiodic
%   Helmholtz Green function in a two-dimensional perfect periodic crystal.
%
% Main algorithm:
%   For each source point y_j, solve the proxy system
%
%     A_proxy q(y_j) = -d_free(y_j),
%
%   and form
%
%     G_QP(x_i,y_j) approx G(x_i,y_j)
%       + sum_l G(x_i,z_l) q_l(y_j).
%
%   The target derivatives are assembled with the same proxy strengths.
%   Source derivatives are assembled by differentiating the proxy system:
%
%     A_proxy q_{,r}(y_j) = -d_{free,r}(y_j),
%
%   so that
%
%     partial_{y_r} G_QP(x_i,y_j)
%       = partial_{y_r} G(x_i,y_j)
%         + sum_l G(x_i,z_l) q_{l,r}(y_j).
%
% Based on:
%   kernel.qpgreen_mfs_pairmat and notes/implementation/mfs2d.md.
%
% Main changes:
%   This routine does not use one-direction strip folding or Rayleigh
%   expansions.  It returns source-derivative data in aux because
%   double-layer BIE blocks require partial_{nu_y} G_QP, and the proxy
%   strengths depend on the source point.
%
% Numerical goal:
%   Provide the single-layer value matrix and source-normal derivative
%   ingredients needed by the 2D Dirichlet exterior BIE manufactured test.
%
% Input:
%   src     - 2-by-ns source points.
%   trg     - 2-by-nt target points.
%   pars2d  - Parameter struct accepted for interface clarity; proxy2d
%             stores the precomputed numerical data used here.
%   proxy2d - Struct returned by kernel.precomp_proxy2d.
%
% Output:
%   pot_ext    - nt-by-ns value matrix.
%   gradx_ext  - nt-by-ns target x-derivative matrix.
%   grady_ext  - nt-by-ns target y-derivative matrix.
%   hessxx_ext - nt-by-ns target xx-derivative matrix.
%   hessxy_ext - nt-by-ns target xy-derivative matrix.
%   hessyy_ext - nt-by-ns target yy-derivative matrix.
%   aux        - Struct with source derivatives, mixed target-source
%                derivatives, proxy strengths, residuals, and regular
%                diagonal values for singular quadrature assembly.

  if nargin < 4 || isempty(proxy2d)
    proxy2d = kernel.precomp_proxy2d(pars2d, struct());
  end

  if size(src, 1) ~= 2 || size(trg, 1) ~= 2
    error('kernel:qpgreen2d_pairmat:InvalidInput', ...
      'src and trg must both be 2-by-N coordinate arrays.');
  end

  k = proxy2d.k;
  ns = size(src, 2);

  [d_free, d_srcx, d_srcy] = LOCAL_free_discrepancy(proxy2d, src);
  Q = LOCAL_solve_proxy(proxy2d, -d_free);
  Q_srcx = LOCAL_solve_proxy(proxy2d, -d_srcx);
  Q_srcy = LOCAL_solve_proxy(proxy2d, -d_srcy);

  [G0, grad0, hess0] = LOCAL_free_pair_all(k, trg, src);
  [GP, gradP, hessP] = LOCAL_free_pair_all(k, trg, proxy2d.Z);

  pot_ext = G0 + GP * Q;
  gradx_ext = grad0.x + gradP.x * Q;
  grady_ext = grad0.y + gradP.y * Q;
  hessxx_ext = hess0.xx + hessP.xx * Q;
  hessxy_ext = hess0.xy + hessP.xy * Q;
  hessyy_ext = hess0.yy + hessP.yy * Q;

  aux = struct();
  aux.proxy_strengths = Q;
  aux.proxy_strengths_srcx = Q_srcx;
  aux.proxy_strengths_srcy = Q_srcy;
  aux.proxy_residual = proxy2d.A_proxy * Q + d_free;
  aux.proxy_residual_norm = norm(aux.proxy_residual, 'fro');
  aux.proxy_relative_residual = aux.proxy_residual_norm / max(norm(d_free, 'fro'), eps);
  aux.discrepancy_rhs_norm = norm(d_free, 'fro');

  aux.srcgradx = -grad0.x + GP * Q_srcx;
  aux.srcgrady = -grad0.y + GP * Q_srcy;
  aux.trgsrc_xx = -hess0.xx + gradP.x * Q_srcx;
  aux.trgsrc_xy = -hess0.xy + gradP.x * Q_srcy;
  aux.trgsrc_yx = -hess0.xy + gradP.y * Q_srcx;
  aux.trgsrc_yy = -hess0.yy + gradP.y * Q_srcy;

  [G_src_proxy, ~, ~] = LOCAL_free_pair_all(k, src, proxy2d.Z);
  aux.regdiag = struct();
  aux.regdiag.pot = zeros(1, ns);
  aux.regdiag.srcgradx = zeros(1, ns);
  aux.regdiag.srcgrady = zeros(1, ns);
  for j = 1:ns
    aux.regdiag.pot(j) = G_src_proxy(j, :) * Q(:, j);
    aux.regdiag.srcgradx(j) = G_src_proxy(j, :) * Q_srcx(:, j);
    aux.regdiag.srcgrady(j) = G_src_proxy(j, :) * Q_srcy(:, j);
  end

end

%% ==================== Discrepancy helper ====================
% This helper builds batch free-space wall discrepancies and source derivatives.

function [d_free, d_srcx, d_srcy] = LOCAL_free_discrepancy(proxy2d, src)

  k = proxy2d.k;
  lambda = proxy2d.lambda;
  phase_y = proxy2d.phase_y;

  [G_L, grad_L, hess_L] = LOCAL_free_pair_all(k, proxy2d.check_L, src);
  [G_R, grad_R, hess_R] = LOCAL_free_pair_all(k, proxy2d.check_R, src);
  [G_B, grad_B, hess_B] = LOCAL_free_pair_all(k, proxy2d.check_B, src);
  [G_T, grad_T, hess_T] = LOCAL_free_pair_all(k, proxy2d.check_T, src);

  d_free = [G_R - lambda * G_L; ...
            grad_R.x - lambda * grad_L.x; ...
            G_T - phase_y * G_B; ...
            grad_T.y - phase_y * grad_B.y];

  d_srcx = [-(grad_R.x - lambda * grad_L.x); ...
            -(hess_R.xx - lambda * hess_L.xx); ...
            -(grad_T.x - phase_y * grad_B.x); ...
            -(hess_T.xy - phase_y * hess_B.xy)];

  d_srcy = [-(grad_R.y - lambda * grad_L.y); ...
            -(hess_R.xy - lambda * hess_L.xy); ...
            -(grad_T.y - phase_y * grad_B.y); ...
            -(hess_T.yy - phase_y * hess_B.yy)];

end

%% ==================== Free-space kernel helper ====================
% This helper returns pair matrices and leaves coincident entries as regular-only slots.

function [pot, grad, hess] = LOCAL_free_pair_all(k, trg, src)

  xdiff = bsxfun(@minus, trg(1, :).', src(1, :));
  ydiff = bsxfun(@minus, trg(2, :).', src(2, :));
  rr = xdiff.^2 + ydiff.^2;
  singular = rr == 0;
  rr(singular) = 1;
  r = sqrt(rr);
  z = k * r;

  ima4inv = 1i / 4;
  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
  cdd = -h1 .* (k * ima4inv ./ r);
  cdd2 = (k * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 * h1;

  pot = ima4inv * h0;
  grad = struct();
  grad.x = cdd .* xdiff;
  grad.y = cdd .* ydiff;
  hess = struct();
  hess.xx = cdd2 .* (h2z .* xdiff .* xdiff - rr .* h1);
  hess.xy = cdd2 .* (h2z .* xdiff .* ydiff);
  hess.yy = cdd2 .* (h2z .* ydiff .* ydiff - rr .* h1);

  pot(singular) = 0;
  grad.x(singular) = 0;
  grad.y(singular) = 0;
  hess.xx(singular) = 0;
  hess.xy(singular) = 0;
  hess.yy(singular) = 0;

end

%% ==================== Proxy solve helper ====================
% This helper applies the reusable factorization built by precomp_proxy2d.

function x = LOCAL_solve_proxy(proxy2d, rhs)

  fact = proxy2d.factorization;
  if strcmp(fact.solver, 'svd')
    keep = fact.keep;
    if ~any(keep)
      x = zeros(size(proxy2d.A_proxy, 2), size(rhs, 2));
    else
      Ut_rhs = fact.U(:, keep)' * rhs;
      x = fact.V(:, keep) * bsxfun(@rdivide, Ut_rhs, fact.singular_values(keep));
    end
  elseif strcmp(fact.solver, 'qr')
    x = fact.R \ (fact.Q' * rhs);
  else
    x = proxy2d.A_proxy \ rhs;
  end

end
