function [t, D] = triginterp(N)
% TRIGINTERP Build even-node trigonometric interpolation nodes and D matrix.
%
% Purpose:
%   Construct the equidistant even-node periodic grid and the explicit
%   cotangent spectral differentiation matrix for trigonometric
%   interpolation.
%
% Main algorithm:
%   For N = 2n nodes t_j = 2*pi*j/N, j = 0,...,N-1, assemble
%   the matrix
%
%     D_{mj} =
%       1/2 (-1)^{m+j} cot((t_m - t_j)/2),  m ~= j,
%       0,                                  m = j.
%
%   MATLAB indices are 1-based, so the parity factor uses the mathematical
%   zero-based indices (row_index - 1) + (col_index - 1).
%
% Input:
%   N - Positive even integer number of equidistant nodes.
%
% Output:
%   t - N-by-1 vector of grid nodes t_j = 2*pi*j/N.
%   D - N-by-N explicit even-node trigonometric differentiation matrix.
%
% Notes:
%   This function intentionally does not use FFTs. It is meant to validate
%   the closed-form differentiation matrix before the same derivative
%   operator is used in later Kress/Muller density interpolation tests.

  if ~isscalar(N) || ~isnumeric(N) || ~isreal(N) || ~isfinite(N) ...
      || N <= 0 || N ~= fix(N)
    error('utils:triginterp:InvalidN', ...
      'N must be a scalar positive integer.');
  end
  if mod(N, 2) ~= 0
    error('utils:triginterp:OddN', ...
      'Even-node trigonometric interpolation requires N to be even.');
  end

  idx = (0:N - 1).';
  t = 2 * pi * idx / N;

  Tdiff = t - t.';
  D = zeros(N, N);
  mask = ~eye(N);
  parity = (-1).^(idx + idx.');
  D(mask) = 0.5 * parity(mask) .* cot(0.5 * Tdiff(mask));

  D(1:N + 1:end) = 0;
  D = real(D);

end
