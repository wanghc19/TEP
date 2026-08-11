function value = Faddeeva_erfc(z)
%FADDEEVA_ERFC Evaluate complex erfc for the local Linton Ewald formula.
%
% Purpose:
%   Provide the optional Faddeeva_erfc name in Octave, whose built-in erfc
%   already accepts complex arguments.  MATLAB may use its normal function
%   resolution if a compiled Faddeeva implementation is present.

  value = erfc(z);
end
