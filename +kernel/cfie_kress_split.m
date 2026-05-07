function [K1, K2] = cfie_kress_split(geom, k, eta)
% CFIE_KRESS_SPLIT Build the Kress split for the CFIE parameter kernel.
%
% Purpose:
%   Return K1 and K2 for the combined-field kernel K = L + i*eta*M used in
%   cfie_kress_vs_kr.m, with K = K1*g + K2 and
%   g(t,tau) = log(4*sin^2((t-tau)/2)).
%
% Input:
%   geom - Boundary geometry struct with fields t, z, zp, zpp, speed.
%   k    - Helmholtz wavenumber.
%   eta  - Combined-field coupling parameter.
%
% Output:
%   K1, K2 - Kress logarithmic split matrices for K.

  ntot = length(geom.t);
  [L, M, rho, log_term] = LOCAL_cfie_full_parts(geom, k);
  diag_mask = eye(ntot) == 1;
  off_mask = ~diag_mask;

  xp = geom.zp(:,1).';
  yp = geom.zp(:,2).';
  xt = geom.z(:,1);
  yt = geom.z(:,2);
  xs = geom.z(:,1).';
  ys = geom.z(:,2).';

  L1 = zeros(ntot, ntot);
  L2 = zeros(ntot, ntot);
  M1 = zeros(ntot, ntot);
  M2 = zeros(ntot, ntot);
  rho_safe = rho;
  rho_safe(diag_mask) = 1;

  L1_full = k / (2 * pi) ...
    * (yp .* (xt - xs) - xp .* (yt - ys)) ...
    ./ rho_safe .* besselj(1, k * rho_safe);
  L1(off_mask) = L1_full(off_mask);
  M1(off_mask) = -1 / (2 * pi) * besselj(0, k * rho(off_mask)) ...
    .* LOCAL_expand_source_row(geom.speed, ntot, off_mask);

  L2(off_mask) = L(off_mask) - L1(off_mask) .* log_term(off_mask);
  M2(off_mask) = M(off_mask) - M1(off_mask) .* log_term(off_mask);

  Ldiag = 1 / (2 * pi) ...
    * (geom.zp(:,1) .* geom.zpp(:,2) - geom.zp(:,2) .* geom.zpp(:,1)) ...
    ./ (geom.speed.^2);
  M1diag = -1 / (2 * pi) * geom.speed;
  euler_const = 0.57721566490153286060;
  M2diag = (1i / 2 - euler_const / pi ...
    - 1 / (2 * pi) * log(k^2 / 4 * geom.speed.^2)) .* geom.speed;

  L1(diag_mask) = 0;
  L2(diag_mask) = Ldiag;
  M1(diag_mask) = M1diag;
  M2(diag_mask) = M2diag;

  K1 = L1 + 1i * eta * M1;
  K2 = L2 + 1i * eta * M2;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [L, M, rho, log_term] = LOCAL_cfie_full_parts(geom, k)

  ntot = length(geom.t);
  diag_mask = eye(ntot) == 1;
  off_mask = ~diag_mask;

  xt = geom.z(:,1);
  yt = geom.z(:,2);
  xs = geom.z(:,1).';
  ys = geom.z(:,2).';
  xp = geom.zp(:,1).';
  yp = geom.zp(:,2).';
  speed_src = geom.speed.';

  dx = xs - xt;
  dy = ys - yt;
  rho = sqrt(dx.^2 + dy.^2);
  rho_safe = rho;
  rho_safe(diag_mask) = 1;
  dt = geom.t - geom.t.';
  log_term = log(4 * sin(dt / 2).^2);

  L = zeros(ntot, ntot);
  M = zeros(ntot, ntot);
  num_L = yp .* dx - xp .* dy;
  L_full = 1i * k / 2 * num_L ./ rho_safe .* besselh(1, 1, k * rho_safe);
  speed_mat = speed_src(ones(ntot, 1), :);
  M_full = 1i / 2 * besselh(0, 1, k * rho_safe) .* speed_mat;
  L(off_mask) = L_full(off_mask);
  M(off_mask) = M_full(off_mask);

  L(diag_mask) = 0;
  M(diag_mask) = 0;
  rho(diag_mask) = 1;
  log_term(diag_mask) = 0;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function values = LOCAL_expand_source_row(source_values, ntot, mask)

  source_row = source_values(:).';
  source_mat = source_row(ones(ntot, 1), :);
  values = source_mat(mask);

end
