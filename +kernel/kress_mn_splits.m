function [M1, M2, N1, N2] = kress_mn_splits(k, t, geom_data)
% KRESS_MN_SPLITS Build bare Kress M and N kernel splits.
%
% Purpose:
%   Return the Kress logarithmic split matrices for the bare single-layer
%   parameter kernel M and the tangential-derivative auxiliary kernel N used
%   in the all-Kress TEP discretizations.
%
% Input:
%   k         - Helmholtz wavenumber.
%   t         - N-by-1 equidistant periodic nodes.
%   geom_data - Struct with fields z, zp, zpp, and speed, where z, zp, zpp
%               are N-by-2 arrays and speed is an N-by-1 vector.
%
% Output:
%   M1, M2 - Split of M^(k) = M1*g + M2, where
%            M^(k)(t,tau) = Phi_k(z(t),z(tau)) |z'(tau)|.
%   N1, N2 - Split of the auxiliary kernel
%            N^(k)(t,tau) used in the A+BD hypersingular construction.

  eulerc = 0.57721566490153286060;
  ntot = length(t);
  offdiag = ~eye(ntot);

  dx = geom_data.z(:,1) - geom_data.z(:,1).';
  dy = geom_data.z(:,2) - geom_data.z(:,2).';
  rho = sqrt(dx.^2 + dy.^2);
  rho_safe = rho;
  rho_safe(~offdiag) = 1;

  tdiff = t - t.';
  logterm = log(4 * sin(0.5 * tdiff).^2);
  cotterm = cot(0.5 * tdiff);

  speed_src = repmat(geom_data.speed.', ntot, 1);
  zp_dot_diff = bsxfun(@times, geom_data.zp(:,1), dx) ...
    + bsxfun(@times, geom_data.zp(:,2), dy);
  zp_dot_zpp = geom_data.zp(:,1) .* geom_data.zpp(:,1) ...
    + geom_data.zp(:,2) .* geom_data.zpp(:,2);

  M_full = 1i / 4 * besselh(0, 1, k * rho_safe) .* speed_src;
  M1 = -1 / (4 * pi) * besselj(0, k * rho_safe) .* speed_src;
  M2 = zeros(ntot, ntot);
  M2(offdiag) = M_full(offdiag) - M1(offdiag) .* logterm(offdiag);
  M1(~offdiag) = -1 / (4 * pi) * geom_data.speed;
  M2(~offdiag) = 0.5 * (1i / 2 - eulerc / pi ...
    - 1 / (2 * pi) * log((k^2 / 4) * geom_data.speed.^2)) ...
    .* geom_data.speed;

  ratio = zp_dot_diff ./ rho_safe;
  N_full = -1i * k / 4 * ratio .* besselh(1, 1, k * rho_safe);
  N1 = k / (4 * pi) * ratio .* besselj(1, k * rho_safe);
  N2 = zeros(ntot, ntot);
  N2(offdiag) = N_full(offdiag) - 1 / (4 * pi) * cotterm(offdiag) ...
    - N1(offdiag) .* logterm(offdiag);
  N1(~offdiag) = 0;
  N2(~offdiag) = 1 / (4 * pi) * zp_dot_zpp ./ (geom_data.speed.^2);

end
