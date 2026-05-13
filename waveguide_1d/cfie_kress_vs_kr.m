function cfie_kress_vs_kr

% Purpose:
%   Compare Kress product quadrature and Kapur-Rokhlin corrected trapezoid
%   quadrature for an exterior Dirichlet Helmholtz CFIE point-source test.
%
% Main algorithm:
%   Build one smooth star-shaped obstacle using the same contour layout as
%   archive/demobie1.m, prescribe exact Dirichlet data from one fixed
%   interior Helmholtz point source using the same source-placement rule as
%   that demo, solve the exterior combined-field boundary integral equation
%   with Kress and Kapur-Rokhlin Nystrom matrices at the same ntot, and
%   compare the resulting exterior fields on a target circle.
%
% Based on:
%   archive/demobie1.m for the boundary geometry and point-source test idea,
%   quad_note.md for the Kress split and Nystrom convention, and
%   quad_demo_7_1_kress.m for quad.quad_kress_rvec.
%
% Main changes:
%   This standalone script uses the physical combined-field representation
%   instead of the older pure double-layer example, and it compares Kress
%   product quadrature against sixth- and tenth-order Kapur-Rokhlin
%   corrections without modifying any reference file.
%
% Numerical goal:
%   Demonstrate that, for a smooth obstacle and the same ntot, the Kress
%   product quadrature eventually gives clearly higher exterior-field
%   accuracy than the Kapur-Rokhlin corrected trapezoid rules.

format long e;
clear;
close all;

% Helmholtz wavenumber and combined-field coupling.  eta = k is a standard
% robust choice for exterior Dirichlet combined-field integral equations.
k = 5;
eta = k;

% Even discretization sizes used for the direct quadrature comparison.
N_list = [32 48 64 96 128 192 256];

% Set this to true when PNG files should be written.  When false, the script
% opens visible figure windows for inspection and does not overwrite files.
save_figures = false;
figure_visibility = 'on';
if save_figures
  figure_visibility = 'off';
end

% Single contour resolution used for the geometry plot and deterministic
% source/target placement, matching the default ntot in archive/demobie1.m.
plot_ntot = 200;
geom_plot = LOCAL_boundary_geom(plot_ntot);
geom_check = geom_plot;

% Fixed interior point source used to generate exact Dirichlet boundary data.
% The radius 0.6*rmin follows archive/demobie1.m; only the angle is fixed
% here so the test is deterministic.
source_angle = -pi / 8;
y0 = LOCAL_fixed_source_point(geom_check, source_angle);
source_strength = 1;

% Exterior target circle.  The radius follows the exterior-target radius
% convention in archive/demobie1.m but uses deterministic target angles.
R_target = 1.5 * max(sqrt(sum(geom_check.z.^2, 2)));
n_target = 64;
theta_target = (2 * pi / n_target) * (0:(n_target - 1)).';
x_target = R_target * [cos(theta_target), sin(theta_target)];
u_exact = LOCAL_ref_field(x_target, y0, source_strength, k);
u_exact_scale = max(abs(u_exact));

fig_geom = figure('Name', 'CFIE geometry', 'Color', 'w', 'Visible', figure_visibility);
hold on;
plot(geom_plot.C(1,[1:plot_ntot,1]), geom_plot.C(4,[1:plot_ntot,1]), 'k.-', ...
  y0(1), y0(2), 'r.', ...
  x_target(:,1), x_target(:,2), 'b.');
legend('Contour C', 'Source points xxt', 'Target points xxs', 'Location', 'best');
axis equal;
grid on;
title(sprintf('CFIE test geometry, ntot = %d', plot_ntot), 'FontSize', 12);
hold off;
if save_figures
  saveas(fig_geom, 'cfie_kress_vs_kr_geometry.png');
end

fprintf('Exterior CFIE point-source quadrature comparison\n');
fprintf('  k                  : %.6g\n', k);
fprintf('  eta                : %.6g\n', eta);
fprintf('  save figures       : %d\n', save_figures);
fprintf('  geometry plot ntot : %d\n', plot_ntot);
fprintf('  source point y0    : (%.16e, %.16e)\n', y0(1), y0(2));
fprintf('  target radius      : %.6g\n', R_target);
fprintf('  ntot list          : [%s]\n', num2str(N_list));
if save_figures
  fprintf('  geometry plot file : cfie_kress_vs_kr_geometry.png\n');
end

source_inside = inpolygon(y0(1), y0(2), geom_check.z(:,1), geom_check.z(:,2));
boundary_rmax = max(sqrt(sum(geom_check.z.^2, 2)));
fprintf('  source in polygon  : %d\n', source_inside);
fprintf('  max boundary radius: %.16e\n', boundary_rmax);
if ~source_inside
  warning('The selected source point is not inside the sampled boundary.');
end
if R_target <= 1.25 * boundary_rmax
  warning('The target radius may not be safely outside the obstacle.');
end

nN = length(N_list);
err_kress = NaN(nN, 1);
err_kr6 = NaN(nN, 1);
err_kr10 = NaN(nN, 1);
res_kress = NaN(nN, 1);
res_kr6 = NaN(nN, 1);
res_kr10 = NaN(nN, 1);

for idx = 1:nN
  ntot = N_list(idx);
  geom = LOCAL_boundary_geom(ntot);
  f = LOCAL_ref_field(geom.C([1,4],:).', y0, source_strength, k);
  rhs = 2 * f;
  I = eye(ntot);

  A_kress = LOCAL_build_cfie_kress(ntot, k, eta);
  sigma_kress = (I - A_kress) \ rhs;
  res_kress(idx) = norm((I - A_kress) * sigma_kress - rhs, inf) / norm(rhs, inf);
  u_kress = LOCAL_eval_combined_field(x_target, geom, sigma_kress, k, eta);
  err_kress(idx) = max(abs(u_kress - u_exact)) / u_exact_scale;

  A_kr6 = LOCAL_build_cfie_kr(ntot, k, eta, 6);
  sigma_kr6 = (I - A_kr6) \ rhs;
  res_kr6(idx) = norm((I - A_kr6) * sigma_kr6 - rhs, inf) / norm(rhs, inf);
  u_kr6 = LOCAL_eval_combined_field(x_target, geom, sigma_kr6, k, eta);
  err_kr6(idx) = max(abs(u_kr6 - u_exact)) / u_exact_scale;

  A_kr10 = LOCAL_build_cfie_kr(ntot, k, eta, 10);
  sigma_kr10 = (I - A_kr10) \ rhs;
  res_kr10(idx) = norm((I - A_kr10) * sigma_kr10 - rhs, inf) / norm(rhs, inf);
  u_kr10 = LOCAL_eval_combined_field(x_target, geom, sigma_kr10, k, eta);
  err_kr10(idx) = max(abs(u_kr10 - u_exact)) / u_exact_scale;
end

fprintf('\nConvergence table:\n');
fprintf('  %-8s %-18s %-18s %-18s\n', 'ntot', 'Kress_error', 'KR6_error', 'KR10_error');
for idx = 1:nN
  fprintf('  %-8d %-18.10e %-18.10e %-18.10e\n', ...
    N_list(idx), err_kress(idx), err_kr6(idx), err_kr10(idx));
end

fprintf('\nMaximum relative matrix solve residuals:\n');
fprintf('  Kress : %.16e\n', max(res_kress));
fprintf('  KR6   : %.16e\n', max(res_kr6));
fprintf('  KR10  : %.16e\n', max(res_kr10));
if max([res_kress; res_kr6; res_kr10]) > 1e-9
  warning('At least one matrix solve residual is larger than expected.');
end

if ~(err_kress(end) < 0.1 * min(err_kr6(end), err_kr10(end)))
  warning(['Kress is not clearly more accurate at the finest ntot. Check: ', ...
    '1. sign of the double-layer kernel; ', ...
    '2. exterior jump sign; ', ...
    '3. diagonal formula for L2; ', ...
    '4. diagonal formula for M2; ', ...
    '5. indexing of the Kress weights; ', ...
    '6. whether the boundary normal is outward for a counter-clockwise curve.']);
end

fig = figure('Name', 'CFIE Kress vs KR', 'Color', 'w', 'Visible', figure_visibility);
semilogy(N_list, err_kress, 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
hold on;
semilogy(N_list, err_kr6, 's-', 'LineWidth', 1.2, 'MarkerSize', 7);
semilogy(N_list, err_kr10, '^-', 'LineWidth', 1.2, 'MarkerSize', 7);
hold off;
grid on;
xlabel('ntot', 'FontSize', 11);
ylabel('relative maximum error', 'FontSize', 11);
title('Exterior CFIE point-source test', 'FontSize', 12);
legend('Kress', 'KR6', 'KR10', 'Location', 'southwest');
if save_figures
  saveas(fig, 'cfie_kress_vs_kr.png');
  fprintf('\nSaved convergence plot to cfie_kress_vs_kr.png\n');
end

end

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function geom = LOCAL_boundary_geom(ntot)
% Return the star-shaped contour C from archive/demobie1.m as geometry arrays.

  [C, curvelen] = LOCAL_construct_cont(ntot, 'star');
  geom.t = (curvelen / ntot) * (0:(ntot - 1)).';
  geom.h = curvelen / ntot;
  geom.C = C;
  geom.z = [C(1,:).', C(4,:).'];
  geom.zp = [C(2,:).', C(5,:).'];
  geom.zpp = [C(3,:).', C(6,:).'];
  geom.speed = sqrt(sum(geom.zp.^2, 2));
  geom.nu = [geom.zp(:,2), -geom.zp(:,1)];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [C, curvelen] = LOCAL_construct_cont(ntot, flag_geom)
% Build the contour matrix C using the same row convention as demobie1.m.

  if mod(ntot, 2) ~= 0
    error('ntot must be even.');
  end

  if strcmp(flag_geom, 'star')
    r = 0.3;
    kstar = 5;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) = 1.5 * cos(tt) ...
      + (r / 2) * cos((kstar + 1) * tt) ...
      + (r / 2) * cos((kstar - 1) * tt);
    C(2,:) = -1.5 * sin(tt) ...
      - (r / 2) * (kstar + 1) * sin((kstar + 1) * tt) ...
      - (r / 2) * (kstar - 1) * sin((kstar - 1) * tt);
    C(3,:) = -1.5 * cos(tt) ...
      - (r / 2) * (kstar + 1) * (kstar + 1) * cos((kstar + 1) * tt) ...
      - (r / 2) * (kstar - 1) * (kstar - 1) * cos((kstar - 1) * tt);
    C(4,:) = sin(tt) ...
      + (r / 2) * sin((kstar + 1) * tt) ...
      - (r / 2) * sin((kstar - 1) * tt);
    C(5,:) = cos(tt) ...
      + (r / 2) * (kstar + 1) * cos((kstar + 1) * tt) ...
      - (r / 2) * (kstar - 1) * cos((kstar - 1) * tt);
    C(6,:) = -sin(tt) ...
      - (r / 2) * (kstar + 1) * (kstar + 1) * sin((kstar + 1) * tt) ...
      + (r / 2) * (kstar - 1) * (kstar - 1) * sin((kstar - 1) * tt);

    scale = 0.15;
    C = C * scale;
    curvelen = 2 * pi;
  else
    error('This option for the geometry is not implemented.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_build_cfie_kress(ntot, k, eta)
% Build the Kress product-quadrature matrix for K = L + i eta M.

  geom = LOCAL_boundary_geom(ntot);
  [K1, K2] = LOCAL_cfie_kress_split(geom, k, eta);
  rvec = quad.quad_kress_rvec(ntot);
  offset_idx = mod((0:ntot-1) - (0:ntot-1).', ntot) + 1;
  R = rvec(offset_idx);
  A = R .* K1 + geom.h * K2;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_build_cfie_kr(ntot, k, eta, order)
% Build a periodic Kapur-Rokhlin corrected trapezoid matrix for K = L+i eta M.

  geom = LOCAL_boundary_geom(ntot);
  K = LOCAL_cfie_full_kernel(geom, k, eta);
  gamma = LOCAL_kr_gamma(order);
  width = length(gamma);

  [JJ, II] = meshgrid(1:ntot, 1:ntot);
  Loff = JJ - II;
  Loff(Loff > ntot / 2) = Loff(Loff > ntot / 2) - ntot;
  Loff(Loff <= -ntot / 2) = Loff(Loff <= -ntot / 2) + ntot;
  abs_l = abs(Loff);

  W = geom.h * ones(ntot, ntot);
  for ell = 1:width
    W(abs_l == ell) = geom.h * (1 + gamma(ell));
  end
  W(abs_l == 0) = 0;
  A = W .* K;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_combined_field(x_target, geom, sigma, k, eta)
% Evaluate the physical combined-field potential away from the boundary.

  dx = x_target(:,1) - geom.z(:,1).';
  dy = x_target(:,2) - geom.z(:,2).';
  rho = sqrt(dx.^2 + dy.^2);
  dot_nu = dx .* geom.nu(:,1).' + dy .* geom.nu(:,2).';

  d_kernel = 1i * k / 4 * besselh(1, 1, k * rho) .* dot_nu ./ rho;
  s_kernel = 1i / 4 * besselh(0, 1, k * rho) .* geom.speed.';
  u = geom.h * ((d_kernel - 1i * eta * s_kernel) * sigma);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function y0 = LOCAL_fixed_source_point(geom, source_angle)
% Place one deterministic interior source using demobie1.m's 0.6*rmin rule.

  rmin = sqrt(min(geom.C(1,:).^2 + geom.C(4,:).^2));
  y0 = 0.6 * rmin * [cos(source_angle), sin(source_angle)];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_ref_field(x, y0, source_strength, k)
% Evaluate the fixed-source Dirichlet data used on the contour.

  rho = sqrt((x(:,1) - y0(1)).^2 + (x(:,2) - y0(2)).^2);
  u = source_strength * 1i / 4 * besselh(0, 1, k * rho);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function K = LOCAL_cfie_full_kernel(geom, k, eta)
% Return off-diagonal values of the parameter kernel K = L + i eta M.

  ntot = length(geom.t);
  [L, M] = LOCAL_cfie_full_parts(geom, k);
  K = L + 1i * eta * M;
  K(1:(ntot + 1):end) = 0;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [K1, K2] = LOCAL_cfie_kress_split(geom, k, eta)
% LOCAL_CFIE_KRESS_SPLIT Build the Kress split for the CFIE parameter kernel.
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

function gamma = LOCAL_kr_gamma(order)
% Return periodic Kapur-Rokhlin merged weights gamma_l + gamma_-l.

  if order == 6
    gamma = [
      4.967362978287758e+00
     -1.620501504859126e+01
      2.585153761832639e+01
     -2.222599466791883e+01
      9.930104998037539e+00
     -1.817995878141594e+00
    ];
  elseif order == 10
    gamma = [
      7.832432020568779e+00
     -4.565161670374749e+01
      1.452168846354677e+02
     -2.901348302886379e+02
      3.870862162579900e+02
     -3.523821383570681e+02
      2.172421547519342e+02
     -8.707796087382991e+01
      2.053584266072635e+01
     -2.166984103403823e+00
    ];
  else
    error('Unsupported Kapur-Rokhlin order %d. Use 6 or 10.', order);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
