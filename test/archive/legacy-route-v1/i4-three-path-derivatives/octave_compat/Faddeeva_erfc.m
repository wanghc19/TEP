function value = Faddeeva_erfc(z)
%FADDEEVA_ERFC Evaluate complex erfc in Octave compatibility checks.
%
% Purpose:
%   Provide the optional Faddeeva_erfc name when Octave's built-in erfc is
%   the available complex complementary-error-function backend.

  value = erfc(z);
end
