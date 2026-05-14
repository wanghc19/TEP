function [pot, grad, hess, aux] = qpgreen2d(src, trg, pars2d, proxy2d)
% QPGREEN2D Evaluate a doubly-quasiperiodic 2D Green function by proxy MFS.
%
% Purpose:
%   Evaluates the two-dimensional doubly-quasiperiodic Helmholtz Green
%   function for one physical source point and many target points.
%
% Main algorithm:
%   The approximation keeps the physical singular source explicitly and
%   represents only the regular quasiperiodic correction by proxy sources:
%
%     G_QP^{(omega)}(x,y)
%       approx G^{(omega)}(x,y)
%              + sum_l q_l(y) G^{(omega)}(x,z_l).
%
%   The proxy strengths solve
%
%     A_proxy q(y) = -d_free(y),
%
%   where d_free(y) is the free-space source discrepancy on the left/right
%   and top/bottom cell walls:
%
%     G(X_+,s;y) - lambda G(X_-,s;y),
%     G_x(X_+,s;y) - lambda G_x(X_-,s;y),
%     G(t,Y_+;y) - exp(1i beta d) G(t,Y_-;y),
%     G_y(t,Y_+;y) - exp(1i beta d) G_y(t,Y_-;y).
%
% Based on:
%   kernel.qpgreen_mfs and notes/implementation/mfs2d.md, but with the
%   open-direction plane-wave expansion removed.
%
% Main changes:
%   This function is genuinely two-direction quasiperiodic in the cell and
%   does not reuse the one-dimensional idx_in/idx_up/idx_dn Rayleigh logic.
%
% Numerical goal:
%   Supply target values, target gradients, target Hessians, and proxy
%   residual diagnostics for manufactured-solution and BIE validation tests.
%
% Input:
%   src     - 2-by-1 source point.
%   trg     - 2-by-nt target points.
%   pars2d  - Parameter struct with at least k, beta, lambda, and cell
%             fields.  It is accepted for interface clarity; proxy2d stores
%             the precomputed values used by this routine.
%   proxy2d - Struct returned by kernel.precomp_proxy2d.
%
% Output:
%   pot  - 1-by-nt potential values.
%   grad - 2-by-nt target gradient values [G_x; G_y].
%   hess - 3-by-nt target Hessian values [G_xx; G_xy; G_yy].
%   aux  - Struct with proxy strengths, source-derivative strengths, and
%          discrepancy residual information.

  if nargin < 4 || isempty(proxy2d)
    proxy2d = kernel.precomp_proxy2d(pars2d, struct());
  end

  if size(src, 1) ~= 2 || size(src, 2) ~= 1
    error('kernel:qpgreen2d:InvalidSource', ...
      'src must be a 2-by-1 source coordinate.');
  end
  if size(trg, 1) ~= 2
    error('kernel:qpgreen2d:InvalidTargets', ...
      'trg must be a 2-by-nt target coordinate array.');
  end

  k = proxy2d.k;

  [d_free, d_srcx, d_srcy] = LOCAL_free_discrepancy(proxy2d, src);
  q = LOCAL_solve_proxy(proxy2d, -d_free);
  q_srcx = LOCAL_solve_proxy(proxy2d, -d_srcx);
  q_srcy = LOCAL_solve_proxy(proxy2d, -d_srcy);

  [G0, grad0, hess0] = LOCAL_free_pair_all(k, trg, src);
  [GP, gradP, hessP] = LOCAL_free_pair_all(k, trg, proxy2d.Z);

  pot_mat = G0 + GP * q;
  gradx_mat = grad0.x + gradP.x * q;
  grady_mat = grad0.y + gradP.y * q;
  hessxx_mat = hess0.xx + hessP.xx * q;
  hessxy_mat = hess0.xy + hessP.xy * q;
  hessyy_mat = hess0.yy + hessP.yy * q;

  pot = pot_mat.';
  grad = [gradx_mat.'; grady_mat.'];
  hess = [hessxx_mat.'; hessxy_mat.'; hessyy_mat.'];

  residual = proxy2d.A_proxy * q + d_free;
  aux = struct();
  aux.q = q;
  aux.q_srcx = q_srcx;
  aux.q_srcy = q_srcy;
  aux.proxy_residual = residual;
  aux.proxy_residual_norm = norm(residual);
  aux.proxy_relative_residual = norm(residual) / max(norm(d_free), eps);
  aux.discrepancy_rhs_norm = norm(d_free);
  aux.srcgradx = (-grad0.x + GP * q_srcx).';
  aux.srcgrady = (-grad0.y + GP * q_srcy).';

end

%% ==================== Discrepancy helper ====================
% This helper builds d_free and its source-coordinate derivatives.

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
% This helper returns pair matrices and sets coincident singular entries to zero.

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
% This helper applies the factorization stored by precomp_proxy2d.

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
