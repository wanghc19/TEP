function channels = rayleigh_channels(k, beta, d, M, L)
% Purpose:
%   Construct Rayleigh channel data for a periodic lead cell using explicit
%   formulas only.  This routine does not use geometry, BIE assembly, or a
%   scattering matrix.  The input k is the exterior/background wavenumber,
%   denoted by omega in some notes.
%
% Inputs:
%   k:
%     Exterior/background wavenumber.
%   beta:
%     y-direction quasiperiodic parameter.
%   d:
%     y-direction period.
%   M:
%     Truncation half-width, with Rayleigh modes m = -M:M.
%   L:
%     x-direction period length of the current lead cell.
%
% Outputs:
%   channels:
%     Struct containing channel metadata and the column vectors
%
%       beta_m  = beta + 2*pi*m/d,
%       gamma_m = sqrt(k^2 - beta_m^2),
%       phase_m = exp(1i*gamma_m*L).
%
%     The branch of gamma_m is chosen so that imag(gamma_m) >= 0.  

  if ~(isscalar(M) && isfinite(M) && M >= 0 && M == floor(M))
    error('rayleigh_channels:InvalidM', ...
      'M must be a nonnegative integer scalar.');
  end
  if ~(isscalar(d) && isfinite(d) && d ~= 0)
    error('rayleigh_channels:InvalidPeriod', ...
      'd must be a nonzero finite scalar.');
  end
  if ~(isscalar(L) && isfinite(L) && L ~= 0)
    error('rayleigh_channels:InvalidLength', ...
      'L must be a nonzero finite scalar.');
  end
  if ~(isscalar(k) && isfinite(k))
    error('rayleigh_channels:InvalidWavenumber', ...
      'k must be a finite scalar.');
  end
  if ~(isscalar(beta) && isfinite(beta))
    error('rayleigh_channels:InvalidBeta', ...
      'beta must be a finite scalar.');
  end

  m = (-M:M).';
  beta_m = beta + 2 * pi * m / d;
  gamma_m = sqrt(k^2 - beta_m.^2);

  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);

  phase = exp(1i * gamma_m * L);

  channels.k = k;
  channels.beta = beta;
  channels.d = d;
  channels.L = L;
  channels.M = M;
  channels.K = 2 * M + 1;
  channels.m = m;
  channels.beta_m = beta_m;
  channels.gamma_m = gamma_m;
  channels.phase = phase;

end
