% Purpose:
%   Test whether bloch.farfield_extractors constructs the left and right
%   Rayleigh extraction matrices F_L and F_R correctly.
%
% Tested function:
%   [F_L, F_R] = bloch.farfield_extractors(C, rayleighchan, X_L, X_R, curvelen).
%
% Two comparison methods:
%   For a reproducible random density
%
%     eta = [tau; -sigma] = [tau; mu],
%
%   method 1 applies the extractor matrices directly,
%
%     s_L^F = F_L eta, \qquad s_R^F = F_R eta.
%
%   Method 2 evaluates the scattered field
%
%     u_{sc} = D_{QP}[tau] - S_{QP}[mu]
%
%   on the cell walls and projects it onto the Rayleigh basis.
%
% Main mathematical formulas:
%   On the right wall X_R,
%
%     u_{sc}(X_R,y) = \sum_m s_R(m) \psi_m(y),
%     \partial_x u_{sc}(X_R,y) =
%       \sum_m i \gamma_m s_R(m) \psi_m(y),
%
%   hence
%
%     s_R^D(m) =
%       \int_0^d u_{sc}(X_R,y) \overline{\psi_m(y)}\,dy,
%     s_R^N(m) =
%       {1 \over i \gamma_m}
%       \int_0^d \partial_x u_{sc}(X_R,y)
%       \overline{\psi_m(y)}\,dy.
%
%   On the left wall X_L,
%
%     u_{sc}(X_L,y) = \sum_m s_L(m) \psi_m(y),
%     \partial_x u_{sc}(X_L,y) =
%       \sum_m (-i \gamma_m) s_L(m) \psi_m(y),
%
%   hence
%
%     s_L^D(m) =
%       \int_0^d u_{sc}(X_L,y) \overline{\psi_m(y)}\,dy,
%     s_L^N(m) =
%       -{1 \over i \gamma_m}
%       \int_0^d \partial_x u_{sc}(X_L,y)
%       \overline{\psi_m(y)}\,dy.
%
% Expected result:
%   The direct coefficients s_L^F, s_R^F should agree with the wall
%   projection coefficients s_L^D, s_R^D and s_L^N, s_R^N up to the
%   practical wall quadrature/proxy tolerance used below.

clear;

% --- stage 1: set parameters ---

% Boundary and wall quadrature sizes.  These are intentionally small enough
% for a quick Octave smoke test while retaining spectral trapezoid accuracy.
ntot = 64;
Ny_wall = 256;

% Geometry selector and radius passed directly to geom.construct_cont.
flag_geom = 'circle';
radius = 0.3;

% Wavenumber, transverse quasiperiodicity, y-period, Rayleigh truncation
% half-width, and x-length of the cell.
k = 1.3 + 1i * 1e-4;
beta = 0.4;
d = 2 * pi;
M = 2;
L = 2.0;
X_L = -L / 2;
X_R = L / 2;

% The comparison uses wall projection and an MFS proxy representation of the
% quasi-periodic Green function, so this tolerance is intentionally practical
% rather than close to machine precision.
tol = 1e-6;

% Proxy parameters for the quasi-periodic Green function.  For
% periodic_axis = 'y', H is the physical x half-width used internally after
% the coordinate swap.
pars1.k = k;
pars1.beta = beta;
pars1.d = d;
pars1.periodic_axis = 'y';
pars2.H = L / 2 + radius + 0.4;
pars2.proxy_dist = 0.7;
pars2.N_side = 80;
pars2.N_top = 80;
pars2.N_proxy_edge = 40;
pars2.M_pw = 12;

% --- stage 2: build geometry and Rayleigh channels ---

[C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0, radius);
rayleighchan = bloch.rayleigh_channels(k, beta, d, M, L);
K = rayleighchan.K;
N = size(C, 2);

x = C(1, :).';
y = C(4, :).';
dxdt = C(2, :).';
dydt = C(5, :).';
speed = sqrt(dxdt.^2 + dydt.^2);
nx = dydt ./ speed;
ny = -dxdt ./ speed;
weights = (curvelen / N) * speed;

% --- stage 3: build farfield extractors ---

[F_L, F_R] = bloch.farfield_extractors(C, rayleighchan, X_L, X_R, curvelen);

% The pairwise wall evaluation uses the same physical y-periodic Green
% function convention as the far-field formulas.
proxy = kernel.precomp_proxy(pars1, pars2);

% --- stage 4: generate random density and apply F_L/F_R ---

rng(1);
tau = randn(N, 1) + 1i * randn(N, 1);
mu = randn(N, 1) + 1i * randn(N, 1);
eta = [tau; mu];

s_L_F = F_L * eta;
s_R_F = F_R * eta;

% --- stage 5: evaluate scattered field on cell walls ---

yq = d * (0:Ny_wall - 1) / Ny_wall;
trg_L = [X_L * ones(1, Ny_wall); yq];
trg_R = [X_R * ones(1, Ny_wall); yq];
src = [x.'; y.'];

[pot_L, gradx_L, grady_L, hessxx_L, hessxy_L, ~] = ...
  kernel.qpgreen_mfs_pairmat(src, trg_L, pars1, proxy);
[pot_R, gradx_R, grady_R, hessxx_R, hessxy_R, ~] = ...
  kernel.qpgreen_mfs_pairmat(src, trg_R, pars1, proxy);

tau_w = tau .* weights;
mu_w = mu .* weights;

% qpgreen_mfs_pairmat returns target-coordinate derivatives.  Since
% G = G(target - source), the source-normal derivative is
%
%   \partial_{\nu_z} G = -(\partial_x G \nu_x + \partial_y G \nu_y).
%
% The target x-derivative of this source-normal derivative is
%
%   \partial_x \partial_{\nu_z} G =
%     -(\partial_{xx} G \nu_x + \partial_{xy} G \nu_y).
%
% With eta = [tau; mu] = [tau; -sigma], the scattered field and its
% x-derivative are
%
%   u_{wall} =
%     \sum_j \partial_{\nu_z}G(\cdot,z_j) tau_j w_j
%     - \sum_j G(\cdot,z_j) mu_j w_j,
%
%   \partial_x u_{wall} =
%     \sum_j \partial_x\partial_{\nu_z}G(\cdot,z_j) tau_j w_j
%     - \sum_j \partial_xG(\cdot,z_j) mu_j w_j.
dGdnu_L = -bsxfun(@times, gradx_L, nx.') - bsxfun(@times, grady_L, ny.');
dGdnu_R = -bsxfun(@times, gradx_R, nx.') - bsxfun(@times, grady_R, ny.');
dx_dGdnu_L = -bsxfun(@times, hessxx_L, nx.') - ...
  bsxfun(@times, hessxy_L, ny.');
dx_dGdnu_R = -bsxfun(@times, hessxx_R, nx.') - ...
  bsxfun(@times, hessxy_R, ny.');

u_L = dGdnu_L * tau_w - pot_L * mu_w;
u_R = dGdnu_R * tau_w - pot_R * mu_w;
dx_u_L = dx_dGdnu_L * tau_w - gradx_L * mu_w;
dx_u_R = dx_dGdnu_R * tau_w - gradx_R * mu_w;

% --- stage 6: project wall fields to Rayleigh coefficients ---

dy = d / Ny_wall;
psi = (1 / sqrt(d)) * exp(1i * (rayleighchan.beta_m(:) * yq));
coeff_D_L = dy * (conj(psi) * u_L);
coeff_D_R = dy * (conj(psi) * u_R);
coeff_N_L = dy * (conj(psi) * dx_u_L);
coeff_N_R = dy * (conj(psi) * dx_u_R);

s_L_D = coeff_D_L;
s_R_D = coeff_D_R;
s_L_N = -coeff_N_L ./ (1i * rayleighchan.gamma_m(:));
s_R_N = coeff_N_R ./ (1i * rayleighchan.gamma_m(:));

% --- stage 7: compare and report errors ---

err_L_D = norm(s_L_F - s_L_D) / max(1, norm(s_L_F));
err_R_D = norm(s_R_F - s_R_D) / max(1, norm(s_R_F));
err_L_N = norm(s_L_F - s_L_N) / max(1, norm(s_L_F));
err_R_N = norm(s_R_F - s_R_N) / max(1, norm(s_R_F));

fprintf('bloch_test_F\n');
fprintf('ntot = %d, Ny_wall = %d, K = %d, M = %d\n', ...
  ntot, Ny_wall, K, M);
fprintf('flag_geom = %s, radius = %.16g\n', flag_geom, radius);
fprintf('k = %.16g%+.16gi\n', real(k), imag(k));
fprintf('beta = %.16g, d = %.16g, L = %.16g\n', beta, d, L);
fprintf('X_L = %.16g, X_R = %.16g\n', X_L, X_R);
fprintf('periodic_axis = %s\n', pars1.periodic_axis);

fprintf('\nerrors:\n');
fprintf('  err_L_D = %.16e\n', err_L_D);
fprintf('  err_R_D = %.16e\n', err_R_D);
fprintf('  err_L_N = %.16e\n', err_L_N);
fprintf('  err_R_N = %.16e\n', err_R_N);
fprintf('  tol = %.16e\n', tol);

if err_L_D < tol && err_R_D < tol && err_L_N < tol && err_R_N < tol
  fprintf('\nPASS\n');
else
  fprintf('\nFAIL\n');
end
