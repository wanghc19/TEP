function results = bie_pc_ps_extdir()
% BIE_PC_PS_EXTDIR Test a 2D perfect-crystal exterior Dirichlet QP BIE.
%
% Purpose:
%   Runs a point-source manufactured-solution test for the exterior
%   Dirichlet problem in one doubly-quasiperiodic perfect-crystal cell.
%
% Main algorithm:
%   Let U = [X_-,X_+] x [Y_-,Y_+], L = X_+ - X_-, and d = Y_+ - Y_-.
%   Let Omega be a smooth obstacle in U and Sigma = partial Omega.  Choose
%   a source point y_s inside Omega and solve in
%
%     D = U \ overline{Omega}
%
%   the manufactured exterior Dirichlet problem
%
%     (Delta + omega^2) u = 0              in D,
%     u = g                                on Sigma,
%     u(x + L e_x) = lambda u(x),
%     u(x + d e_y) = exp(1i beta d) u(x),
%
%   with boundary data and exact solution
%
%     g(x)    = G_QP^{(omega)}(x,y_s),  x in Sigma,
%     u_ex(x) = G_QP^{(omega)}(x,y_s),  x in D.
%
%   The exterior representation is the combined field
%
%     u_N(x) = D_QP^{(omega)}[tau](x)
%              - 1i eta_cfie S_QP^{(omega)}[tau](x),
%
%   where eta_cfie is chosen as omega.  Taking the exterior Dirichlet trace
%   gives the boundary integral equation
%
%     (1/2 I + D_QP,Sigma^{(omega)}
%      - 1i eta_cfie S_QP,Sigma^{(omega)}) tau = g.
%
%   This script calls the matrix on the left B_dir and solves B_dir tau = g.
%   For target points x_l in D it evaluates
%
%     u_N(x_l) = integral_Sigma [
%       partial_{nu_y} G_QP^{(omega)}(x_l,y)
%       - 1i eta_cfie G_QP^{(omega)}(x_l,y)] tau(y) ds_y
%
%   and compares against u_ex(x_l) = G_QP^{(omega)}(x_l,y_s).
%
% Based on:
%   crystal_2d/README.md Step 2a goals and notes/implementation/mfs2d.md.
%
% Main changes:
%   This is a new manufactured-solution check for the new two-dimensional
%   proxy kernel.  It is not a transmission scattering calculation and does
%   not use lead incoming/outgoing mode logic.
%
% Numerical goal:
%   Verify that kernel.precomp_proxy2d, kernel.qpgreen2d, and
%   kernel.qpgreen2d_pairmat can assemble and evaluate a Dirichlet exterior
%   combined-field BIE in one perfect two-dimensional periodic cell.

  % --- stage 1: set parameters ---
  k = 2.35;                 % Helmholtz wavenumber omega used by G_QP.
  beta = 0.19;              % y-quasimomentum; phase_y = exp(1i*beta*d).
  lambda = exp(1i * 0.37);  % x-direction Floquet multiplier.

  X_minus = -pi;            % Left side of the unit cell.
  X_plus = pi;              % Right side of the unit cell, so L = X_plus-X_minus.
  Y_minus = -pi;            % Bottom side of the unit cell.
  Y_plus = pi;              % Top side of the unit cell, so d = Y_plus-Y_minus.

  ellipse_a = 0.62;         % x semi-axis of the elliptic obstacle Omega.
  ellipse_b = 0.45;         % y semi-axis of the elliptic obstacle Omega.
  obstacle_center = [0; 0]; % Center of the obstacle inside the cell.
  source_inside = [0.13; -0.11]; % Manufactured point source y_s inside Omega.
  ntot = 72;                % Even number of boundary nodes on Sigma.
  target_grid_n = 17;       % Cartesian grid size used before exterior filtering.
  target_clearance = 0.22;  % Minimum distance from targets to Sigma.
  wall_clearance = 0.20;    % Keeps test targets away from cell walls.
  eta_cfie = k;             % Combined-field coupling parameter.

  proxy_opts = struct();
  proxy_opts.N_proxy = 128;             % Number of proxy sources on the circle.
  proxy_opts.N_check_x = 72;            % Check points on bottom/top walls.
  proxy_opts.N_check_y = 72;            % Check points on left/right walls.
  proxy_opts.proxy_radius_factor = 1.8; % Radius relative to the cell half diagonal.
  proxy_opts.solver = 'svd';            % Reusable least-squares factorization.

  pars2d = struct();
  pars2d.k = k;
  pars2d.beta = beta;
  pars2d.lambda = lambda;
  pars2d.X_minus = X_minus;
  pars2d.X_plus = X_plus;
  pars2d.Y_minus = Y_minus;
  pars2d.Y_plus = Y_plus;

  % --- stage 2: build proxy data and obstacle geometry ---
  proxy2d = kernel.precomp_proxy2d(pars2d, proxy_opts);
  [C, curvelen, ~, ~] = geom.construct_cont(ntot, 'ellipse', 0, 0, ellipse_a, ellipse_b);
  C(1, :) = C(1, :) + obstacle_center(1);
  C(4, :) = C(4, :) + obstacle_center(2);
  [t, ~] = utils.triginterp(ntot);
  geom_data = struct();
  geom_data.t = t;
  geom_data.h = curvelen / ntot;
  geom_data.z = [C(1, :).', C(4, :).'];
  geom_data.zp = [C(2, :).', C(5, :).'];
  geom_data.zpp = [C(3, :).', C(6, :).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));
  geom_data.normal = [geom_data.zp(:, 2) ./ geom_data.speed, ...
    -geom_data.zp(:, 1) ./ geom_data.speed];

  xbd = geom_data.z(:, 1).';
  ybd = geom_data.z(:, 2).';
  bd = [xbd; ybd];
  nx = geom_data.normal(:, 1);
  ny = geom_data.normal(:, 2);
  weights = geom_data.h * geom_data.speed;

  % --- stage 3: build manufactured Dirichlet data ---
  [g_row, ~, ~, aux_source] = kernel.qpgreen2d(source_inside, bd, pars2d, proxy2d);
  g = g_row(:);

  % --- stage 4: assemble and solve the boundary integral equation ---
  [pot_bd, ~, ~, ~, ~, ~, aux_bd] = ...
    kernel.qpgreen2d_pairmat(bd, bd, pars2d, proxy2d);
  B_dir = LOCAL_assemble_dirichlet_cfie(geom_data, k, eta_cfie, pot_bd, aux_bd, ...
    nx, ny, weights);
  tau = B_dir \ g;
  boundary_residual = norm(B_dir * tau - g) / max(norm(g), eps);

  % --- stage 5: evaluate the exterior field and compare with the exact solution ---
  trg = LOCAL_select_exterior_targets(X_minus, X_plus, Y_minus, Y_plus, ...
    obstacle_center, ellipse_a, ellipse_b, target_grid_n, target_clearance, wall_clearance);
  [pot_t, ~, ~, ~, ~, ~, aux_t] = ...
    kernel.qpgreen2d_pairmat(bd, trg, pars2d, proxy2d);
  dGdnu_t = bsxfun(@times, aux_t.srcgradx, nx.') + ...
    bsxfun(@times, aux_t.srcgrady, ny.');
  u_num = (dGdnu_t - 1i * eta_cfie * pot_t) * (tau .* weights);
  [u_ex_row, ~, ~, ~] = kernel.qpgreen2d(source_inside, trg, pars2d, proxy2d);
  u_ex = u_ex_row(:);

  err = u_num - u_ex;
  rel_max_error = max(abs(err)) / max(max(abs(u_ex)), eps);
  rel_l2_error = norm(err) / max(norm(u_ex), eps);

  % --- stage 6: report diagnostics ---
  fprintf('\n2D QP exterior Dirichlet point-source manufactured test\n');
  fprintf('  omega k                         : %.16g\n', k);
  fprintf('  beta                            : %.16g\n', beta);
  fprintf('  lambda                          : %.8g%+.8gi\n', real(lambda), imag(lambda));
  fprintf('  phase_y                         : %.8g%+.8gi\n', real(proxy2d.phase_y), imag(proxy2d.phase_y));
  fprintf('  proxy discrepancy residual src  : %.3e\n', aux_source.proxy_relative_residual);
  fprintf('  proxy discrepancy residual bd   : %.3e\n', aux_bd.proxy_relative_residual);
  fprintf('  boundary equation residual      : %.3e\n', boundary_residual);
  fprintf('  relative max error              : %.3e\n', rel_max_error);
  fprintf('  relative l2 error               : %.3e\n', rel_l2_error);
  fprintf('  N boundary nodes                : %d\n', ntot);
  fprintf('  N target points                 : %d\n', size(trg, 2));
  fprintf('  N proxy sources                 : %d\n', proxy_opts.N_proxy);
  fprintf('  N check x / y                   : %d / %d\n', ...
    proxy_opts.N_check_x, proxy_opts.N_check_y);

  results = struct();
  results.proxy_source_residual = aux_source.proxy_relative_residual;
  results.proxy_boundary_residual = aux_bd.proxy_relative_residual;
  results.boundary_residual = boundary_residual;
  results.rel_max_error = rel_max_error;
  results.rel_l2_error = rel_l2_error;
  results.ntot = ntot;
  results.n_targets = size(trg, 2);
  results.n_proxy = proxy_opts.N_proxy;
  results.n_check_x = proxy_opts.N_check_x;
  results.n_check_y = proxy_opts.N_check_y;
  results.tau = tau;
  results.targets = trg;
  results.u_num = u_num;
  results.u_ex = u_ex;

end

%% ==================== BIE assembly helper ====================
% This helper combines Kress free-space quadrature with smooth proxy corrections.

function B_dir = LOCAL_assemble_dirichlet_cfie(geom, k, eta_cfie, pot_qp, ...
    aux_qp, nx, ny, weights)

  ntot = length(geom.t);
  R = LOCAL_kress_matrix(ntot);
  [M1, M2] = kernel.kress_mn_splits(k, geom.t, geom);
  [L1, L2] = kernel.kress_l_splits(k, geom.t, geom);

  S_free = R .* M1 + geom.h * M2;
  D_free = R .* L1 + geom.h * L2;

  [pot_free, grad_free, ~] = LOCAL_free_pair_all(k, geom.z.', geom.z.');
  srcgradx_free = -grad_free.x;
  srcgrady_free = -grad_free.y;
  dGdnu_qp = bsxfun(@times, aux_qp.srcgradx, nx.') + ...
    bsxfun(@times, aux_qp.srcgrady, ny.');
  dGdnu_free = bsxfun(@times, srcgradx_free, nx.') + ...
    bsxfun(@times, srcgrady_free, ny.');

  S_reg_kernel = pot_qp - pot_free;
  D_reg_kernel = dGdnu_qp - dGdnu_free;

  diag_idx = 1:ntot + 1:ntot * ntot;
  S_reg_kernel(diag_idx) = aux_qp.regdiag.pot;
  D_reg_kernel(diag_idx) = aux_qp.regdiag.srcgradx .* nx.' + ...
    aux_qp.regdiag.srcgrady .* ny.';

  S_reg = bsxfun(@times, S_reg_kernel, weights.');
  D_reg = bsxfun(@times, D_reg_kernel, weights.');

  S_qp = S_free + S_reg;
  D_qp = D_free + D_reg;
  B_dir = 0.5 * eye(ntot) + D_qp - 1i * eta_cfie * S_qp;

end

%% ==================== Target helper ====================
% This helper chooses cell targets in D that stay away from Sigma and the walls.

function trg = LOCAL_select_exterior_targets(X_minus, X_plus, Y_minus, Y_plus, ...
    obstacle_center, ellipse_a, ellipse_b, target_grid_n, target_clearance, wall_clearance)

  xs = linspace(X_minus + wall_clearance, X_plus - wall_clearance, target_grid_n);
  ys = linspace(Y_minus + wall_clearance, Y_plus - wall_clearance, target_grid_n);
  [xx, yy] = meshgrid(xs, ys);
  inside_buffered_obstacle = geom.is_inside(xx - obstacle_center(1), ...
    yy - obstacle_center(2), 'ellipse', ellipse_a + target_clearance, ...
    ellipse_b + target_clearance);
  keep = ~inside_buffered_obstacle;
  trg = [xx(keep).'; yy(keep).'];

end

%% ==================== Quadrature helper ====================
% This helper expands the periodic Kress logarithmic weights into a matrix.

function R = LOCAL_kress_matrix(ntot)

  rvec = quad.quad_kress_rvec(ntot);
  offset_idx = mod((0:ntot - 1) - (0:ntot - 1).', ntot) + 1;
  R = rvec(offset_idx);

end

%% ==================== Free-space helper ====================
% This helper builds nonsingular off-diagonal free-space pair matrices.

function [pot, grad, hess] = LOCAL_free_pair_all(k, trg, src)

  xdiff = bsxfun(@minus, trg(1, :).', src(1, :));
  ydiff = bsxfun(@minus, trg(2, :).', src(2, :));
  rr = xdiff.^2 + ydiff.^2;
  singular = rr == 0;
  rr(singular) = 1;
  r = sqrt(rr);
  z = k * r;

  ima4inv = 1i / 4;
  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
  cdd = -h1 .* (k * ima4inv ./ r);
  cdd2 = (k * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 * h1;

  pot = ima4inv * h0;
  grad = struct();
  grad.x = cdd .* xdiff;
  grad.y = cdd .* ydiff;
  hess = struct();
  hess.xx = cdd2 .* (h2z .* xdiff .* xdiff - rr .* h1);
  hess.xy = cdd2 .* (h2z .* xdiff .* ydiff);
  hess.yy = cdd2 .* (h2z .* ydiff .* ydiff - rr .* h1);

  pot(singular) = 0;
  grad.x(singular) = 0;
  grad.y(singular) = 0;
  hess.xx(singular) = 0;
  hess.xy(singular) = 0;
  hess.yy(singular) = 0;

end
