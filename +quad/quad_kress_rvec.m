function rvec = quad_kress_rvec(N)
% QUAD_KRESS_RVEC Build Kress logarithmic quadrature weights.
%
% Purpose:
%   Computes the periodic logarithmic quadrature correction vector used by
%   Kress Nyström discretizations on an even grid.
%
% Input:
%   N - Even number of periodic quadrature nodes.
%
% Output:
%   rvec - 1-by-N vector of logarithmic quadrature weights.
%
% Notes:
%   The formula is the shared implementation used by the root-level Kress
%   demonstration and CFIE comparison scripts.

  if mod(N, 2) ~= 0
    error('Kress Nystrom method requires N to be even.');
  end

  rvec = zeros(1, N);
  mvec = 0:(N - 1);
  for m = mvec
    accum = 0;
    for n = 1:(N / 2 - 1)
      accum = accum + (1 / n) * cos(2 * pi * n * m / N);
    end
    accum = accum + (1 / N) * cos(pi * m);
    rvec(m + 1) = -(4 * pi / N) * accum;
  end

end
