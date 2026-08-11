function value = Faddeeva_erfc(z)
%FADDEEVA_ERFC Octave-only compatibility wrapper for the Ewald benchmark.
%
% Purpose:
%   Let qpgreen_ewald_xperiodic_bench call Octave's complex erfc when the
%   repository's optional Faddeeva_erfc MEX is unavailable.
%
% Notes:
%   run_i4_extract_oracles adds this directory only in Octave and only when
%   which('Faddeeva_erfc') is empty.  MATLAB validation should use the
%   benchmark's normal Faddeeva implementation instead.

  value = erfc(z);
end
