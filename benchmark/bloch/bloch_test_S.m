% Purpose:
%   Test whether bloch.construct_S builds a single-cell scattering matrix
%   that maps incoming Rayleigh amplitudes to outgoing Rayleigh amplitudes,
%   and whether the resulting total wall Dirichlet traces agree with direct
%   layer-potential reconstruction and Rayleigh projection.
%
% Tested function:
%   S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
%     rayleighchan, X_L, X_R).
%
% Three comparison routes:
%   For incoming amplitudes
%
%     q_{in} = [a_L; b_R],
%
%   Route 1 uses the scattering blocks
%
%     [ b_L ]   [ R_L    T_RL ] [ a_L ],
%     [ a_R ] = [ T_LR   R_R  ] [ b_R ],
%
%   and forms
%
%     D_L^{pred} = a_L + b_L, \qquad
%     D_R^{pred} = a_R + b_R.
%
%   Route 2 reconstructs the scattered field from the S_cell density maps
%
%     eta = H_L a_L + H_R b_R,
%     eta = [tau; mu] = [tau; -sigma],
%     u_{sc} = D_{QP}[tau] - S_{QP}[mu],
%
%   then projects u_{sc} on the walls to obtain D_L^{sc,wall} and
%   D_R^{sc,wall}.
%
%   Route 3 builds fresh incident boundary data directly from Rayleigh
%   formulas, solves
%
%     eta_{fresh} = -(A_{QP}^{fresh} \ B_{inc}),
%
%   and projects the reconstructed scattered field on the walls.  The fresh
%   route does not use S_cell.H_L, S_cell.H_R, or bloch.incident_rhs.  Both
%   wall reconstruction routes use only
%   Dirichlet projection, not Neumann projection.
%
% Main mathematical formulas:
%   Since bloch.construct_S includes the direct cell phase
%
%     E = \operatorname{diag}(\exp(i \gamma_m L))
%
%   in the transmission blocks, the incident Dirichlet coefficients on the
%   walls are
%
%     D_L^{inc} = a_L + E b_R, \qquad
%     D_R^{inc} = E a_L + b_R.
%
%   The wall-projected total Dirichlet traces are therefore
%
%     D_L^{wall} = a_L + E b_R + D_L^{sc,wall},
%     D_R^{wall} = E a_L + b_R + D_R^{sc,wall}.
%
%   In the fresh route, for
%
%     \psi_m(y) = {1 \over \sqrt d}\exp(i\beta_m y),
%
%   the directly constructed incident fields are
%
%     u_m^{L,inc}(x,y) =
%       \exp(i\gamma_m(x-X_L))\psi_m(y),
%     \partial_\nu u_m^{L,inc} =
%       i(\gamma_m\nu_x + \beta_m\nu_y)u_m^{L,inc},
%
%     u_m^{R,inc}(x,y) =
%       \exp(-i\gamma_m(x-X_R))\psi_m(y),
%     \partial_\nu u_m^{R,inc} =
%       i(-\gamma_m\nu_x + \beta_m\nu_y)u_m^{R,inc}.
%
%   Then
%
%     B_{inc} =
%       [\sum_m a_L(m)u_m^{L,inc} +
%        \sum_m b_R(m)u_m^{R,inc};
%        \sum_m a_L(m)\partial_\nu u_m^{L,inc} +
%        \sum_m b_R(m)\partial_\nu u_m^{R,inc} ].
%
% Expected result:
%   The scattering prediction and the direct Dirichlet wall reconstruction
%   routes should agree:
%
%     D_L^{pred} \approx D_L^{wall}, \qquad
%     D_R^{pred} \approx D_R^{wall}, \qquad
%     D_L^{pred} \approx D_L^{fresh}, \qquad
%     D_R^{pred} \approx D_R^{fresh}.

clear;

% --- stage 1: set parameters ---

% Boundary and wall quadrature sizes chosen for a quick Octave smoke test.
ntot = 64;
Ny_wall = 256;

% Circle geometry parameter passed directly to geom.construct_cont.
flag_geom = 'circle';
radius = 0.3;

% Exterior/interior wavenumbers, refractive index ratio, y-periodic Bloch
% parameter, Rayleigh truncation half-width, and x-period of the cell.
kext = 1.3 + 1i * 1e-4;
n = 1.5;
kint = n * kext;
beta = 0.4;
d = 2 * pi;
M = 2;
L = 2.0;
X_L = -L / 2;
X_R = L / 2;

% Practical tolerance for wall projection and proxy Green function errors.
tol = 1e-6;

% Quasi-periodic Green parameters.  With physical y-periodicity, the proxy
% half-width H is interpreted in the swapped computational coordinates as a
% physical x half-width.
pars1.k = kext;
pars1.beta = beta;
pars1.d = d;
pars1.periodic_axis = 'y';
pars2.H = L / 2 + radius + 0.4;
pars2.proxy_dist = 0.7;
pars2.N_side = 80;
pars2.N_top = 80;
pars2.N_proxy_edge = 40;
pars2.M_pw = 12;

% --- stage 2: build geometry, proxy, and Rayleigh channels ---

[C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0, radius);
proxy = kernel.precomp_proxy(pars1, pars2);
rayleighchan = bloch.rayleigh_channels(kext, beta, d, M, L);

K = rayleighchan.K;
Nbd = size(C, 2);
x = C(1, :).';
y = C(4, :).';
dxdt = C(2, :).';
dydt = C(5, :).';
speed = sqrt(dxdt.^2 + dydt.^2);
nx = dydt ./ speed;
ny = -dxdt ./ speed;
weights = (curvelen / Nbd) * speed;

% --- stage 3: construct the cell scattering matrix ---

S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
  rayleighchan, X_L, X_R);

R_L = S_cell.R_L;
T_LR = S_cell.T_LR;
T_RL = S_cell.T_RL;
R_R = S_cell.R_R;
H_L = S_cell.H_L;
H_R = S_cell.H_R;
E = diag(rayleighchan.phase(:));

% --- stage 4: generate random incoming amplitudes ---

rng(2);
a_L = randn(K, 1) + 1i * randn(K, 1);
b_R = randn(K, 1) + 1i * randn(K, 1);
a_L = a_L / max(1, norm(a_L));
b_R = b_R / max(1, norm(b_R));

% --- stage 5: predict wall Dirichlet traces from S_cell ---

b_L = R_L * a_L + T_RL * b_R;
a_R = T_LR * a_L + R_R * b_R;
D_L_pred = a_L + b_L;
D_R_pred = a_R + b_R;

eta = H_L * a_L + H_R * b_R;
tau = eta(1:Nbd);
mu = eta(Nbd + 1:2 * Nbd);

% --- stage 6: reconstruct scattered field on cell walls ---

yq = d * (0:Ny_wall - 1) / Ny_wall;
trg_L = [X_L * ones(1, Ny_wall); yq];
trg_R = [X_R * ones(1, Ny_wall); yq];
src = [x.'; y.'];

[pot_L, gradx_L, grady_L] = ...
  kernel.qpgreen_mfs_pairmat(src, trg_L, pars1, proxy);
[pot_R, gradx_R, grady_R] = ...
  kernel.qpgreen_mfs_pairmat(src, trg_R, pars1, proxy);

tau_w = tau .* weights;
mu_w = mu .* weights;

% qpgreen_mfs_pairmat returns target-coordinate gradients.  For
% G = G(target - source), the source-normal derivative used by the
% double-layer potential is
%
%   \partial_{\nu_z} G =
%     -(\partial_x G \nu_x + \partial_y G \nu_y).
%
% With eta = [tau; mu] = [tau; -sigma], the scattered Dirichlet field is
%
%   u_{sc} =
%     \sum_j \partial_{\nu_z}G(\cdot,z_j) tau_j w_j
%     - \sum_j G(\cdot,z_j) mu_j w_j.
dGdnu_L = -bsxfun(@times, gradx_L, nx.') - bsxfun(@times, grady_L, ny.');
dGdnu_R = -bsxfun(@times, gradx_R, nx.') - bsxfun(@times, grady_R, ny.');

u_sc_L = dGdnu_L * tau_w - pot_L * mu_w;
u_sc_R = dGdnu_R * tau_w - pot_R * mu_w;

% --- stage 7: project wall fields and compare ---

dy = d / Ny_wall;
psi = (1 / sqrt(d)) * exp(1i * (rayleighchan.beta_m(:) * yq));
D_L_sc_wall = dy * (conj(psi) * u_sc_L);
D_R_sc_wall = dy * (conj(psi) * u_sc_R);

D_L_wall = a_L + E * b_R + D_L_sc_wall;
D_R_wall = E * a_L + b_R + D_R_sc_wall;

err_L_D = norm(D_L_pred - D_L_wall) / max(1, norm(D_L_pred));
err_R_D = norm(D_R_pred - D_R_wall) / max(1, norm(D_R_pred));

% --- stage 8: fresh BIE solve from direct incident boundary data ---

beta_m = rayleighchan.beta_m(:);
gamma_m = rayleighchan.gamma_m(:);
psi_bd = exp(1i * y * beta_m.') / sqrt(d);
U_L = exp(1i * (x - X_L) * gamma_m.') .* psi_bd;
U_R = exp(-1i * (x - X_R) * gamma_m.') .* psi_bd;
dU_L = 1i * (nx * gamma_m.' + ny * beta_m.') .* U_L;
dU_R = 1i * (-nx * gamma_m.' + ny * beta_m.') .* U_R;

u_inc = U_L * a_L + U_R * b_R;
dn_u_inc = dU_L * a_L + dU_R * b_R;
B_inc = [u_inc; dn_u_inc];

A_QP_fresh = full(complex(op.construct_A_QP(C, kext, kint, pars1, ...
  proxy, curvelen)));
eta_fresh = -(A_QP_fresh \ B_inc);
tau_fresh = eta_fresh(1:Nbd);
mu_fresh = eta_fresh(Nbd + 1:2 * Nbd);

tau_fresh_w = tau_fresh .* weights;
mu_fresh_w = mu_fresh .* weights;
u_sc_L_fresh = dGdnu_L * tau_fresh_w - pot_L * mu_fresh_w;
u_sc_R_fresh = dGdnu_R * tau_fresh_w - pot_R * mu_fresh_w;

D_L_sc_fresh = dy * (conj(psi) * u_sc_L_fresh);
D_R_sc_fresh = dy * (conj(psi) * u_sc_R_fresh);

% The direct incident fields from the opposite side also reach each wall
% with phase E; this matches the transmission-block convention in S_cell.
D_L_fresh = a_L + E * b_R + D_L_sc_fresh;
D_R_fresh = E * a_L + b_R + D_R_sc_fresh;

err_L_D_fresh = norm(D_L_pred - D_L_fresh) / max(1, norm(D_L_pred));
err_R_D_fresh = norm(D_R_pred - D_R_fresh) / max(1, norm(D_R_pred));
fresh_solve_relative_residual = norm(A_QP_fresh * eta_fresh + B_inc) / ...
  max(1, norm(B_inc));

if isfield(S_cell, 'solve_relative_residual_norm')
  res_solve = S_cell.solve_relative_residual_norm;
else
  rhs_all = [S_cell.B_L, S_cell.B_R];
  H_all = [S_cell.H_L, S_cell.H_R];
  res_solve = norm(S_cell.A_QP * H_all + rhs_all, 'fro') / ...
    max(1, norm(rhs_all, 'fro'));
end

fprintf('bloch_test_S\n');
fprintf('ntot = %d, Ny_wall = %d, K = %d, M = %d\n', ...
  ntot, Ny_wall, K, M);
fprintf('flag_geom = %s, radius = %.16g\n', flag_geom, radius);
fprintf('kext = %.16g%+.16gi\n', real(kext), imag(kext));
fprintf('kint = %.16g%+.16gi, n = %.16g\n', real(kint), imag(kint), n);
fprintf('beta = %.16g, d = %.16g, L = %.16g\n', beta, d, L);
fprintf('X_L = %.16g, X_R = %.16g\n', X_L, X_R);
fprintf('periodic_axis = %s\n', pars1.periodic_axis);

fprintf('\nerrors:\n');
fprintf('  err_L_D = %.16e\n', err_L_D);
fprintf('  err_R_D = %.16e\n', err_R_D);
fprintf('  err_L_D_fresh = %.16e\n', err_L_D_fresh);
fprintf('  err_R_D_fresh = %.16e\n', err_R_D_fresh);
fprintf('  solve_relative_residual_norm = %.16e\n', res_solve);
fprintf('  fresh_solve_relative_residual = %.16e\n', ...
  fresh_solve_relative_residual);
fprintf('  tol = %.16e\n', tol);

if err_L_D < tol && err_R_D < tol && ...
    err_L_D_fresh < tol && err_R_D_fresh < tol
  fprintf('\nPASS\n');
else
  fprintf('\nFAIL\n');
end
