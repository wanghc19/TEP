% Purpose:
%   Minimal smoke test for the qpgreen_mfs physical y-periodic wrapper.
%
% Main algorithm:
%   Precompute the existing augmented MFS proxy data in the computational
%   first-coordinate-periodic convention, then compare
%
%     G_y(src_phys, trg_phys)
%
%   against
%
%     G_x(R src_phys, R trg_phys),  R(x,y) = (y,x).
%
% Based on:
%   The temporary validation need for kernel.qpgreen_mfs periodic_axis
%   support.
%
% Main changes:
%   This file adds no project functionality.  It is a small, deterministic
%   validation script and does not modify kernel.precomp_proxy or any
%   production assembly code.
%
% Numerical goal:
%   Check that potential values agree under the coordinate swap and that the
%   returned physical-coordinate gradient/Hessian components from
%   qpgreen_mfs(..., 'y') match the remapped x-periodic derivatives.

format long e;

tol = 1e-10;

% Small, cheap parameters.  d = 1.0 follows the local TEP scripts and keeps
% beta_m = beta + 2*pi*m/d away from the k = 1.3 threshold for low orders.
d = 1.0;
beta = 0.7;
k = 1.3;

pars1_base.d = d;
pars1_base.beta = beta;
pars1_base.k = k;

% Keep proxy dimensions small; they only need to be large enough for
% qpgreen_mfs to evaluate a deterministic axis-swap consistency check.
pars2.H = 0.5 * d;
pars2.proxy_dist = 0.2 * d;
pars2.N_side = 12;
pars2.N_top = 12;
pars2.N_proxy_edge = 8;
pars2.M_pw = 3;

% precomp_proxy intentionally sees only computational first-coordinate
% periodicity.  The physical axis choice is passed only to qpgreen_mfs.
proxy = kernel.precomp_proxy(pars1_base, pars2);

src_phys = [0.13; -0.17];
trg_phys = [ ...
   0.22, -0.31,  0.62, -0.68,  0.08,  0.45, -0.52,  0.17; ...
   0.11,  0.29, -0.33,  0.41, -0.72,  0.64,  0.58, -0.02];

u_y = kernel.qpgreen_mfs(src_phys, trg_phys, pars1_base, proxy, 'y');
u_x_swapped = kernel.qpgreen_mfs( ...
  src_phys([2 1], :), trg_phys([2 1], :), pars1_base, proxy, 'x');

fprintf('qpgreen_mfs axis-swap consistency test\n');
fprintf('  d = %.16g, beta = %.16g, k = %.16g\n', d, beta, k);
fprintf('  source = [%.16g; %.16g], num_targets = %d\n', ...
  src_phys(1), src_phys(2), size(trg_phys, 2));
fprintf('  tolerance = %.3e\n', tol);

max_abs_pot_diff = max(abs(u_y.pot(:) - u_x_swapped.pot(:)));
fprintf('  max_abs_pot_diff  = %.16e\n', max_abs_pot_diff);

test_passed = max_abs_pot_diff <= tol;

if isfield(u_y, 'grad') && isfield(u_x_swapped, 'grad')
  grad_ref = u_x_swapped.grad([2 1], :);
  max_abs_grad_diff = max(abs(u_y.grad(:) - grad_ref(:)));
  fprintf('  max_abs_grad_diff = %.16e\n', max_abs_grad_diff);
  test_passed = test_passed && (max_abs_grad_diff <= tol);
else
  fprintf('  grad field missing; skipping gradient check.\n');
end

if isfield(u_y, 'hess') && isfield(u_x_swapped, 'hess')
  hess_ref = u_x_swapped.hess([3 2 1], :);
  max_abs_hess_diff = max(abs(u_y.hess(:) - hess_ref(:)));
  fprintf('  max_abs_hess_diff = %.16e\n', max_abs_hess_diff);
  test_passed = test_passed && (max_abs_hess_diff <= tol);
else
  fprintf('  hess field missing; skipping Hessian check.\n');
end

if test_passed
  fprintf('RESULT: PASS - qpgreen_mfs y-periodic axis swap is consistent.\n');
else
  fprintf('RESULT: FAIL - at least one axis-swap difference exceeds tolerance.\n');
  error('test_qpgreen_axis_swap:Failed', ...
    'qpgreen_mfs axis-swap consistency check failed.');
end
