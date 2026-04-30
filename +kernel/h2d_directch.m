function [pot, grad, hess] = h2d_directch(wavek, sources, charge, targ)
% H2D_DIRECTCH Evaluate the 2D Helmholtz single-layer kernel and derivatives.
%
% Purpose:
%   Computes the free-space Helmholtz Green's function, its gradient, and
%   its Hessian for point sources with complex strengths evaluated at target
%   points.
%
% Input:
%   wavek   - Scalar Helmholtz wavenumber.
%   sources - Source coordinates as a 2-by-ns array.
%   charge  - Source strengths as a vector with ns entries.
%   targ    - Target coordinates as a 2-by-nt array.
%
% Output:
%   pot  - Potential values at targets as a 1-by-nt row vector.
%   grad - Gradient values [du/dx; du/dy] as a 2-by-nt array.
%   hess - Hessian values [d2u/dx2; d2u/dxdy; d2u/dy2] as a 3-by-nt array.
%
% Notes:
%   This routine assumes source and target points are distinct. It uses the
%   outgoing Hankel function branch selected by besselh(order, 1, z).

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

  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
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
