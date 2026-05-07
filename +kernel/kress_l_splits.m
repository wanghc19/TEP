function [L1, L2, Ls1, Ls2] = kress_l_splits(k, t, geom_data)
% KRESS_L_SPLITS Build bare Kress L and L* kernel splits.
%
% Purpose:
%   Return the Kress logarithmic split matrices for the bare source-normal
%   double-layer kernel L and the target-normal adjoint kernel L* used in
%   the all-Kress TEP discretizations.
%
% Input:
%   k         - Helmholtz wavenumber.
%   t         - N-by-1 equidistant periodic nodes.
%   geom_data - Struct with fields z, zp, zpp, and speed, where z, zp, zpp
%               are N-by-2 arrays and speed is an N-by-1 vector.
%
% Output:
%   L1, L2   - Split of L^(k) = L1*g + L2 for source-normal D.
%   Ls1, Ls2 - Split of L^(k)* = Ls1*g + Ls2 for target-normal D'.

  ntot = length(t);
  offdiag = ~eye(ntot);

  dx = geom_data.z(:,1) - geom_data.z(:,1).';
  dy = geom_data.z(:,2) - geom_data.z(:,2).';
  rho = sqrt(dx.^2 + dy.^2);
  rho_safe = rho;
  rho_safe(~offdiag) = 1;

  tdiff = t - t.';
  logterm = log(4 * sin(0.5 * tdiff).^2);

  src_nu_x = geom_data.zp(:,2).';
  src_nu_y = -geom_data.zp(:,1).';
  q_src = bsxfun(@times, dx, src_nu_x) + bsxfun(@times, dy, src_nu_y);

  nx = geom_data.zp(:,2) ./ geom_data.speed;
  ny = -geom_data.zp(:,1) ./ geom_data.speed;
  speed_src = repmat(geom_data.speed.', ntot, 1);
  q_tgt = (bsxfun(@times, nx, dx) + bsxfun(@times, ny, dy)) .* speed_src;

  ratio_src = q_src ./ rho_safe;
  ratio_tgt = q_tgt ./ rho_safe;
  L_full = 1i * k / 4 * ratio_src .* besselh(1, 1, k * rho_safe);
  Ls_full = -1i * k / 4 * ratio_tgt .* besselh(1, 1, k * rho_safe);

  L1 = -k / (4 * pi) * ratio_src .* besselj(1, k * rho_safe);
  Ls1 = k / (4 * pi) * ratio_tgt .* besselj(1, k * rho_safe);
  L2 = zeros(ntot, ntot);
  Ls2 = zeros(ntot, ntot);
  L2(offdiag) = L_full(offdiag) - L1(offdiag) .* logterm(offdiag);
  Ls2(offdiag) = Ls_full(offdiag) - Ls1(offdiag) .* logterm(offdiag);

  chi = (geom_data.zp(:,1) .* geom_data.zpp(:,2) ...
    - geom_data.zp(:,2) .* geom_data.zpp(:,1)) ./ (geom_data.speed.^2);
  diag_limit = -1 / (4 * pi) * chi;
  L1(~offdiag) = 0;
  Ls1(~offdiag) = 0;
  L2(~offdiag) = diag_limit;
  Ls2(~offdiag) = diag_limit;

end
