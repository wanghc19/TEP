function Jp = besselj_deriv(order, z)
% BESSELJ_DERIV Evaluate the derivative of J_m(z) with respect to z.
%
% Purpose:
%   Provides a small reusable wrapper for the derivative of the Bessel
%   function J_m with respect to its full argument z.
%
% Main algorithm:
%   Uses the standard recurrence
%
%     J_0'(z) = -J_1(z),
%     J_m'(z) = (J_{m-1}(z) - J_{m+1}(z))/2,  m > 0.
%
% Input:
%   order - Nonnegative integer Bessel order m.
%   z     - Argument of the Bessel function. May be scalar or array.
%
% Output:
%   Jp - Derivative J_m'(z), with the same size as z.

  LOCAL_validate_order(order);

  if order == 0
    Jp = -besselj(1, z);
  else
    Jp = 0.5 * (besselj(order - 1, z) - besselj(order + 1, z));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_order(order)

  if ~isscalar(order) || ~isnumeric(order) || ~isreal(order) ...
      || ~isfinite(order) || order < 0 || order ~= fix(order)
    error('utils:besselj_deriv:InvalidOrder', ...
      'Bessel order must be a nonnegative integer scalar.');
  end

end
