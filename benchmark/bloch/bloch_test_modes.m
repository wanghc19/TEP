% Purpose:
%   Test whether Bloch modes computed from a real single-cell scattering
%   matrix satisfy the Bloch quasi-periodic trace relations between the cell
%   left and right walls.
%
% Tested functions:
%   S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
%     rayleighchan, X_L, X_R);
%   modes = bloch.solve_modes(S_cell);
%   traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);
%
% Mathematical identities being checked:
%   For the j-th generalized eigenvector
%
%     V(:,j) = [a_L(:,j); b_L(:,j)]
%
%   and Floquet multiplier lambda(j), the cell Bloch condition gives
%
%     a_R(m,j) = lambda(j) * a_L(m,j),
%     b_R(m,j) = lambda(j) * b_L(m,j).
%
%   The cell-wall trace coefficients are
%
%     D_L(m,j) = a_L(m,j) + b_L(m,j),
%     N_L(m,j) = 1i * gamma_m(m) * (a_L(m,j) - b_L(m,j)),
%     D_R(m,j) = a_R(m,j) + b_R(m,j),
%     N_R(m,j) = 1i * gamma_m(m) * (a_R(m,j) - b_R(m,j)).
%
%   Hence the identities checked here are
%
%     D_R(m,j) = lambda(j) * D_L(m,j),
%     N_R(m,j) = lambda(j) * N_L(m,j).
%
%   Here N_L and N_R are x-derivative trace coefficients on the cell walls,
%   not outward-normal derivatives for a half-lead.  L/R refer only to the
%   cell left wall and cell right wall; no left-lead or right-lead outgoing
%   mode selection is performed.
%
% Expected result:
%   The maximum Dirichlet trace residual, x-derivative trace residual,
%   generalized eigenpair residual, and scattering relation residual should
%   all be below the tolerance.

clear;

% --- stage 1: set parameters ---

% Boundary size chosen to keep the real-cell scattering matrix construction
% small enough for a quick Octave smoke test.
ntot = 64;

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

% Algebraic checks should be close to machine precision.  The tolerance is
% slightly relaxed to allow Octave/LAPACK variation.
tol = 1e-10;

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

% --- stage 3: construct the cell scattering matrix ---

S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
  rayleighchan, X_L, X_R);

% --- stage 4: solve Bloch generalized eigenproblem ---

modes = bloch.solve_modes(S_cell);

% --- stage 5: compute wall traces from eigenvectors ---

traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);
num_modes = length(modes.lambda);

% --- stage 6: check trace Bloch consistency ---

res_D = zeros(num_modes, 1);
res_N = zeros(num_modes, 1);
eig_res = zeros(num_modes, 1);
scat_res = zeros(num_modes, 1);

for j = 1:num_modes
  lambda_j = modes.lambda(j);

  res_D_vec = traces.D_R(:, j) - lambda_j * traces.D_L(:, j);
  scale_D = max([1, norm(traces.D_R(:, j)), ...
    abs(lambda_j) * norm(traces.D_L(:, j))]);
  res_D(j) = norm(res_D_vec) / scale_D;

  res_N_vec = traces.N_R(:, j) - lambda_j * traces.N_L(:, j);
  scale_N = max([1, norm(traces.N_R(:, j)), ...
    abs(lambda_j) * norm(traces.N_L(:, j))]);
  res_N(j) = norm(res_N_vec) / scale_N;

  lhs_eig = modes.A_sc * modes.V(:, j);
  rhs_eig = lambda_j * modes.B_sc * modes.V(:, j);
  scale_eig = max([1, norm(lhs_eig), norm(modes.B_sc * modes.V(:, j))]);
  eig_res(j) = norm(lhs_eig - rhs_eig) / scale_eig;

  lhs_scat = [traces.b_L(:, j); traces.a_R(:, j)];
  rhs_scat = S_cell.S * [traces.a_L(:, j); traces.b_R(:, j)];
  scale_scat = max([1, norm(lhs_scat), norm(rhs_scat)]);
  scat_res(j) = norm(lhs_scat - rhs_scat) / scale_scat;
end

if isempty(res_D)
  max_res_D = Inf;
  max_res_N = Inf;
  max_eig_res = Inf;
  max_scat_res = Inf;
else
  max_res_D = max(res_D);
  max_res_N = max(res_N);
  max_eig_res = max(eig_res);
  max_scat_res = max(scat_res);
end

% --- stage 7: report diagnostics ---

count_right_decay = NaN;
count_left_decay = NaN;
count_neutral = NaN;
if isfield(modes, 'idx')
  if isfield(modes.idx, 'right_decay')
    count_right_decay = sum(modes.idx.right_decay(:));
  end
  if isfield(modes.idx, 'left_decay')
    count_left_decay = sum(modes.idx.left_decay(:));
  end
  if isfield(modes.idx, 'neutral')
    count_neutral = sum(modes.idx.neutral(:));
  end
end

fprintf('bloch_test_modes\n');
fprintf('ntot = %d, K = %d, M = %d\n', ntot, K, M);
fprintf('flag_geom = %s, radius = %.16g\n', flag_geom, radius);
fprintf('kext = %.16g%+.16gi\n', real(kext), imag(kext));
fprintf('kint = %.16g%+.16gi, n = %.16g\n', real(kint), imag(kint), n);
fprintf('beta = %.16g, d = %.16g, L = %.16g\n', beta, d, L);
fprintf('X_L = %.16g, X_R = %.16g\n', X_L, X_R);
fprintf('periodic_axis = %s\n', pars1.periodic_axis);
fprintf('number_of_modes = %d\n', num_modes);
fprintf('idx.right_decay count = %g\n', count_right_decay);
fprintf('idx.left_decay count = %g\n', count_left_decay);
fprintf('idx.neutral count = %g\n', count_neutral);

fprintf('\nerrors:\n');
fprintf('  max_res_D = %.16e\n', max_res_D);
fprintf('  max_res_N = %.16e\n', max_res_N);
fprintf('  max_eig_res = %.16e\n', max_eig_res);
fprintf('  max_scat_res = %.16e\n', max_scat_res);
fprintf('  tol = %.16e\n', tol);

if max_res_D < tol && max_res_N < tol && ...
    max_eig_res < tol && max_scat_res < tol
  fprintf('\nPASS\n');
else
  fprintf('\nFAIL\n');
end
