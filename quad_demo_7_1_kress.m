% Purpose:
%   Solve the simplest periodic logarithmic-kernel test from Section 7.1
%   using only the Kress Nyström method.
%
% Main algorithm:
%   Discretize the second-kind periodic integral equation on uniform
%   trapezoid nodes, build the dense Kress circulant logarithmic weight
%   matrix, assemble the constant-coefficient Nyström matrix, solve the
%   resulting linear system, and compare several coarse solutions against a
%   fine Kress reference solution.
%
% Based on:
%   quad_note.md and the Section 6.2-6.3 Kress formulas requested in the
%   prompt.
%
% Main changes:
%   This file implements only the Kress method for the Section 7.1 kernel.
%   It does not include Kapur-Rokhlin, Alpert, modified Gaussian, or any
%   unrelated abstractions.
%
% Numerical goal:
%   Demonstrate convergence of the Kress Nyström discretization for the
%   periodic second-kind integral equation with logarithmic kernel
%   k(x,x') = (1/2) log|sin((x-x')/2)|.
format long;
clear;

% --- 1. Parameter Setup ---
Nlist = 20 * 2.^(0:6);             % Coarse discretizations used in the convergence experiment
Nref = 2560;                        % Fine Kress reference discretization for error estimation
Ncond = 160;                        % Optional condition-number sample size

fprintf('Section 7.1 Kress quadrature demo\n');
fprintf('  N list              : [%s]\n', num2str(Nlist));
fprintf('  Reference N         : %d\n', Nref);

[xref, uref] = LOCAL_quad_solve_7_1_kress(Nref);

errors = NaN(length(Nlist), 1);
for j = 1:length(Nlist)
  N = Nlist(j);
  [x, u] = LOCAL_quad_solve_7_1_kress(N);
  stride = Nref / N;
  if abs(stride - round(stride)) > 0
    error('N = %d does not divide Nref = %d.', N, Nref);
  end
  stride = round(stride);

  xref_sampled = xref(stride:stride:end);
  uref_sampled = uref(stride:stride:end);
  if max(abs(x - xref_sampled)) > 1e-12
    error('Reference sampling mismatch for N = %d.', N);
  end

  errors(j) = norm(u - uref_sampled, inf) / norm(uref_sampled, inf);
end

idx_cond = find(Nlist == Ncond, 1, 'first');
if isempty(idx_cond)
  cond_est = NaN;
else
  [~, ~, Acond] = LOCAL_quad_solve_7_1_kress(Ncond);
  cond_est = cond(eye(Ncond) + Acond);
end

fprintf('\nConvergence table:\n');
fprintf('  %-8s %-18s\n', 'N', 'relinf_error');
for j = 1:length(Nlist)
  fprintf('  %-8d %-18.10e\n', Nlist(j), errors(j));
end
if isfinite(cond_est)
  fprintf('\nOptional sanity check:\n');
  fprintf('  cond(I + A) at N = %d : %.10e\n', Ncond, cond_est);
end

figure('Name', 'Section 7.1 Kress Convergence', 'Color', 'w');
loglog(Nlist, errors, 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
grid on;
xlabel('N', 'FontSize', 11);
ylabel('relative infinity error', 'FontSize', 11);
title('Section 7.1 convergence with the Kress method', 'FontSize', 12);

fprintf('\nSection 7.1 Kress demo setup completed.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function rvec = LOCAL_quad_kress_rvec(N)

  if mod(N, 2) ~= 0
    error('Kress Nyström method requires N to be even.');
  end

  rvec = zeros(1, N);
  mvec = 0:(N - 1);
  for m = mvec
    accum = 0;
    for n = 1:(N / 2 - 1)
      accum = accum + (1 / n) * cos(2 * pi * n * m / N);
    end
    accum = accum + (1 / N) * cos(pi * m);
    rvec(m + 1) = -(4 * pi / N) * accum;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x, u, A] = LOCAL_quad_solve_7_1_kress(N)

  if mod(N, 2) ~= 0
    error('Kress Nyström method requires N to be even.');
  end

  h = 2 * pi / N;
  x = (2 * pi / N) * (1:N).';

  rvec = LOCAL_quad_kress_rvec(N);
  offset_idx = mod((0:N-1) - (0:N-1).', N) + 1;
  R = rvec(offset_idx);

  A = 0.25 * R - (h * log(2) / 2) * ones(N, N);
  f = LOCAL_quad_rhs(x);
  u = (eye(N) + A) \ f;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function f = LOCAL_quad_rhs(x)

  f = sin(3 * x) .* exp(cos(5 * x));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
