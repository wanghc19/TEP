% Purpose:
%   Validate the explicit differentiation matrix for even-node
%   trigonometric interpolation before using the same derivative operator
%   for density interpolation in later Kress/Muller TEP experiments.
%
% Main algorithm:
%   Build the equidistant even grid and cotangent differentiation matrix
%   with utils.triginterp, then test Fourier-mode exactness, the Nyquist
%   cosine mode, and rapid convergence for an analytic periodic function.
%
% Based on:
%   This is Experiment 1 before applying Kress quadrature to the TEP code.
%   It is a standalone validation script and does not call or modify any
%   existing Kress quadrature functions.
%
% Main changes:
%   This new script isolates the trigonometric interpolation derivative
%   operator that will later approximate the density derivative phi'(t_j)
%   in the T_{k_1} - T_{k_2} block.
%
% Numerical goal:
%   Confirm that the explicit even-node differentiation matrix satisfies
%   the expected Fourier exactness properties up to roundoff and gives
%   rapid convergence for analytic periodic data.
%
% Mathematical setup:
%   The even-node interpolation grid is
%
%     N=2n,\qquad t_j=\frac{2\pi j}{N},\qquad j=0,\dots,N-1.
%
%   The interpolation space is
%
%     \mathcal T_N=
%     \operatorname{span}\{1,\cos t,\sin t,\dots,\cos((n-1)t),
%     \sin((n-1)t),\cos(nt)\}.
%
%   The explicit differentiation matrix is
%
%     D_{mj}=
%     \begin{cases}
%     \dfrac12(-1)^{m+j}\cot\dfrac{t_m-t_j}{2}, & m\ne j,\\[1ex]
%     0, & m=j.
%     \end{cases}
%
%   For samples phi(t_j), the interpolant derivative is approximated by
%
%     \varphi_n'(t_m)=\sum_{j=0}^{N-1}D_{mj}\varphi(t_j).
%
%   Because N is even, the interpolation space includes the Nyquist cosine
%   mode cos(nt). There is no independent Nyquist sine mode, since
%   sin(nt_j) = 0 at all grid nodes.
%
%   This test validates the derivative operator later used for density
%   interpolation in Kress/Muller experiments.
format long;
clear;

fprintf('Even-node trigonometric interpolation differentiation demo\n');
fprintf('Validating explicit cotangent differentiation matrix D.\n\n');

N_list = [16 32 64 128 256];
N_list_conv = [16 24 32 48 64 96 128 192 256 384 512];
N_table = unique([N_list N_list_conv]);

fourier_err = NaN(size(N_table));
nyquist_err = NaN(size(N_table));
analytic_rel_err = NaN(size(N_table));

for idx_N = 1:length(N_table)
  N = N_table(idx_N);
  [t, D] = utils.triginterp(N);
  n = N / 2;

  modes = unique([0 1 2 3 min(5, n - 1) n - 1]);
  mode_max_err = 0;
  for idx_mode = 1:length(modes)
    mode = modes(idx_mode);

    phi_cos = cos(mode * t);
    dphi_cos = -mode * sin(mode * t);
    abs_err = norm(D * phi_cos - dphi_cos, inf);
    scale = norm(dphi_cos, inf);
    if scale == 0
      test_err = abs_err;
    else
      test_err = abs_err / scale;
    end
    mode_max_err = max(mode_max_err, test_err);

    if mode > 0
      phi_sin = sin(mode * t);
      dphi_sin = mode * cos(mode * t);
      abs_err = norm(D * phi_sin - dphi_sin, inf);
      scale = norm(dphi_sin, inf);
      if scale == 0
        test_err = abs_err;
      else
        test_err = abs_err / scale;
      end
      mode_max_err = max(mode_max_err, test_err);
    end
  end
  fourier_err(idx_N) = mode_max_err;

  phi_nyq = cos(n * t);
  nyquist_err(idx_N) = norm(D * phi_nyq, inf);

  phi_analytic = exp(cos(t) + 0.3 * sin(2 * t));
  dphi_analytic = phi_analytic .* (-sin(t) + 0.6 * cos(2 * t));
  analytic_rel_err(idx_N) = norm(D * phi_analytic - dphi_analytic, inf) ...
    / norm(dphi_analytic, inf);
end

fprintf('Error table:\n');
fprintf('  %-8s %-18s %-18s %-18s\n', ...
  'N', 'FourierMaxErr', 'NyquistErr', 'AnalyticRelErr');
for idx_N = 1:length(N_table)
  fprintf('  %-8d %-18.10e %-18.10e %-18.10e\n', ...
    N_table(idx_N), fourier_err(idx_N), nyquist_err(idx_N), ...
    analytic_rel_err(idx_N));
end

moderate_mask = N_table <= 128;
if any(fourier_err(moderate_mask) > 1e-9)
  warning('quad_demo_triginterp:FourierExactness', ...
    ['Fourier exactness error exceeds 1e-9 for a moderate N. ', ...
     'Check indexing, sign, or parity in D.']);
end

figure('Name', 'Even-node trigonometric differentiation convergence', ...
  'Color', 'w', 'Visible', 'on');
semilogy(N_table, analytic_rel_err, 'o-', 'LineWidth', 1.2, ...
  'MarkerSize', 7);
grid on;
xlabel('N', 'FontSize', 11);
ylabel('relative infinity error', 'FontSize', 11);
title('Analytic function derivative convergence', 'FontSize', 12);
% saveas(gcf, 'quad_demo_triginterp.png');

fprintf('\nPlot saved to quad_demo_triginterp.png\n');
fprintf(['If Fourier and Nyquist errors are near roundoff and analytic errors ', ...
  'decay rapidly, the explicit even-node trigonometric differentiation ', ...
  'matrix is validated.\n']);
