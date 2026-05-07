function Hp = besselh_deriv(order, z)
% BESSELH_DERIV Evaluate the derivative of H_m^{(1)}(z) with respect to z.
%
% Purpose:
%   Provides a small reusable wrapper for the derivative of the Hankel
%   function of the first kind H_m^{(1)} with respect to its full argument z.
%
% Main algorithm:
%   Uses the standard recurrence
%
%     (H_0^{(1)})'(z) = -H_1^{(1)}(z),
%     (H_m^{(1)})'(z) =
%       (H_{m-1}^{(1)}(z) - H_{m+1}^{(1)}(z))/2,  m > 0.
%
% Input:
%   order - Nonnegative integer Hankel order m.
%   z     - Argument of the Hankel function. May be scalar or array.
%
% Output:
%   Hp - Derivative (H_m^{(1)})'(z), with the same size as z.

  LOCAL_validate_order(order);

  if order == 0
    Hp = -besselh(1, 1, z);
  else
    Hp = 0.5 * (besselh(order - 1, 1, z) - besselh(order + 1, 1, z));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_order(order)

  if ~isscalar(order) || ~isnumeric(order) || ~isreal(order) ...
      || ~isfinite(order) || order < 0 || order ~= fix(order)
    error('utils:besselh_deriv:InvalidOrder', ...
      'Hankel order must be a nonnegative integer scalar.');
  end

end
