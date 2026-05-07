% Purpose:
%   Verify the Kress A+BD discretization of the difference of bare
%   hypersingular operators T^(k1)-T^(k2) on a circle.
%
% Main algorithm:
%   Use the explicit even-node trigonometric differentiation matrix D and
%   scaled Kress logarithmic quadrature weights R_j^(N). Assemble
%
%     \mathbf T_N^\Delta=A+BD.
%
%   The script never evaluates a standalone hypersingular integral.
%
% Based on:
%   The circle-boundary verification section for T^{(k_1)}-T^{(k_2)}
%   in note_Kress.md.
%
% Main changes:
%   This standalone experiment uses the packaged circle geometry, Kress
%   weights, and trigonometric differentiation matrix to check the T-block
%   normalization and the B*D ordering.
%
% Numerical goal:
%   For the circle z(t)=a(cos t,sin t), Fourier modes
%
%     \varphi_m(t)=e^{imt}
%
%   are eigenfunctions of the bare operator
%
%     (T^{(k)}\mu)(x)
%     =
%     \partial_{n_x}
%     \int_\Gamma
%     \partial_{n_y}\Phi_k(x,y)\mu(y)\,ds_y,
%     \qquad
%     \Phi_k(x,y)=\frac{i}{4}H_0^{(1)}(k|x-y|).
%
%   The exact eigenvalue is
%
%     \lambda_m^T(k)
%     =
%     \frac{i\pi a k^2}{2}
%     J_m'(ka)\big(H_m^{(1)}\big)'(ka).
%
%   Therefore
%
%     (T^{(k_1)}-T^{(k_2)})e^{imt}
%     =
%     \left(\lambda_m^T(k_1)-\lambda_m^T(k_2)\right)e^{imt}.

function quad_demo_Tdiff_circle

  format long;

  a = 1.0;                         % Circle radius.
  k1 = 2.3;                         % First Helmholtz wavenumber.
  k2 = 4.7;                         % Second Helmholtz wavenumber.
  modes = [0 1 2 3 5];              % Fourier modes used in the eigenvalue test.
  N_list = [32 48 64 96 128 192 256]; % Even node counts used in the convergence test.
  diagnostic_N = 64;                % Representative N for split and D diagnostics.

  if any(mod(N_list, 2) ~= 0)
    error('quad_demo_Tdiff_circle:OddN', 'All N values must be even.');
  end
  if any(modes >= min(N_list) / 2)
    error('quad_demo_Tdiff_circle:UnresolvedMode', ...
      'All modes must satisfy m < N/2 for every tested N.');
  end

  fprintf('Circle test for Kress discretization of T^(k1)-T^(k2)\n');
  fprintf('  radius a : %.6g\n', a);
  fprintf('  k1, k2   : %.6g, %.6g\n', k1, k2);
  fprintf('  modes    : [%s]\n', num2str(modes));
  fprintf('  N list   : [%s]\n\n', num2str(N_list));

  errors = NaN(length(N_list), length(modes));

  for idx_N = 1:length(N_list)
    N = N_list(idx_N);
    if any(modes >= N / 2)
      error('quad_demo_Tdiff_circle:UnresolvedModeAtN', ...
        'At N = %d, all modes must satisfy m < N/2.', N);
    end

    [t, D] = utils.triginterp(N);
    geom_data = LOCAL_circle_geometry(N, a);

    speed_err = norm(geom_data.speed - a, inf);
    if speed_err > 100 * eps(max(1, a))
      error('quad_demo_Tdiff_circle:CircleSpeedMismatch', ...
        'Circle speed check failed at N = %d: %.3e.', N, speed_err);
    end

    [Tdiff, split_res] = LOCAL_assemble_Tdiff(t, D, geom_data, k1, k2);

    for idx_mode = 1:length(modes)
      mode = modes(idx_mode);
      phi = exp(1i * mode * t);
      lambda_delta = LOCAL_T_eigenvalue(mode, k1, a) ...
        - LOCAL_T_eigenvalue(mode, k2, a);
      num = Tdiff * phi;
      ref = lambda_delta * phi;
      errors(idx_N, idx_mode) = norm(num - ref, inf) / abs(lambda_delta);
    end

    if N == diagnostic_N
      nyquist = (-1).^(0:N - 1).';
      fprintf('Diagnostics at N = %d:\n', N);
      fprintf('  speed max error              : %.10e\n', speed_err);
      fprintf('  M split residual, k1         : %.10e\n', split_res.M_k1);
      fprintf('  M split residual, k2         : %.10e\n', split_res.M_k2);
      fprintf('  N split residual, k1         : %.10e\n', split_res.N_k1);
      fprintf('  N split residual, k2         : %.10e\n', split_res.N_k2);
      fprintf('  Nyquist cosine D-norm        : %.10e\n\n', norm(D * nyquist, inf));
    end
  end

  fprintf('Relative Fourier-mode action errors:\n');
  fprintf('  %-8s', 'N');
  for idx_mode = 1:length(modes)
    fprintf(' %-13s', sprintf('m=%d', modes(idx_mode)));
  end
  fprintf(' %-13s\n', 'maxerr');
  for idx_N = 1:length(N_list)
    fprintf('  %-8d', N_list(idx_N));
    for idx_mode = 1:length(modes)
      fprintf(' %-13.6e', errors(idx_N, idx_mode));
    end
    fprintf(' %-13.6e\n', max(errors(idx_N, :)));
  end

  if max(errors(:)) > 1e-2
    warning('quad_demo_Tdiff_circle:LargeError', ...
      ['Large errors detected. Check the T normalization factor, signs, ', ...
       'diagonal limits, Kress scaling, and the B*D order.']);
  end

  figure('Name', 'Circle Tdiff Fourier-mode errors', ...
    'Color', 'w', 'Visible', 'off');
  semilogy(N_list, errors, 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
  grid on;
  xlabel('N', 'FontSize', 11);
  ylabel('relative eigenvalue-action error', 'FontSize', 11);
  title('Kress A+BD discretization of T^{(k_1)}-T^{(k_2)} on a circle', ...
    'FontSize', 12);
  legend(arrayfun(@(m) sprintf('m=%d', m), modes, 'UniformOutput', false), ...
    'Location', 'southwest');
  saveas(gcf, 'quad_demo_Tdiff_circle.png');

  fprintf('\nPlot saved to quad_demo_Tdiff_circle.png\n');
  fprintf(['If the Fourier-mode errors converge rapidly, the Kress A+BD ', ...
    'discretization of T^(k1)-T^(k2) on the circle is validated.\n']);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function geom_data = LOCAL_circle_geometry(N, a)

  [C, curvelen, ~, ~] = geom.construct_cont(N, 'circle', 0, 0, a);
  if abs(curvelen - 2 * pi) > 10 * eps
    error('quad_demo_Tdiff_circle:UnexpectedCurveLength', ...
      'Circle contour should use parameter interval length 2*pi.');
  end

  geom_data.z = [C(1,:).', C(4,:).'];
  geom_data.zp = [C(2,:).', C(5,:).'];
  geom_data.zpp = [C(3,:).', C(6,:).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Tdiff, split_res] = LOCAL_assemble_Tdiff(t, D, geom_data, k1, k2)

  N = length(t);
  h = 2 * pi / N;

  R = LOCAL_kress_matrix(N);
  G = (geom_data.zp * geom_data.zp.') ./ (geom_data.speed * geom_data.speed.');

  [M1_k1, M2_k1, N1_k1, N2_k1, res_M_k1, res_N_k1] = ...
    LOCAL_kernel_splits(k1, t, geom_data);
  [M1_k2, M2_k2, N1_k2, N2_k2, res_M_k2, res_N_k2] = ...
    LOCAL_kernel_splits(k2, t, geom_data);

  delta_M1 = k1^2 * M1_k1 - k2^2 * M1_k2;
  delta_M2 = k1^2 * M2_k1 - k2^2 * M2_k2;
  delta_N1 = N1_k1 - N1_k2;
  delta_N2 = N2_k1 - N2_k2;

  A = (R .* delta_M1 + h * delta_M2) .* G;
  B_unscaled = R .* delta_N1 + h * delta_N2;
  B = bsxfun(@rdivide, B_unscaled, geom_data.speed);

  Tdiff = A + B * D;

  split_res.M_k1 = res_M_k1;
  split_res.M_k2 = res_M_k2;
  split_res.N_k1 = res_N_k1;
  split_res.N_k2 = res_N_k2;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function R = LOCAL_kress_matrix(N)

  rvec = quad.quad_kress_rvec(N);
  offset_idx = mod((0:N - 1) - (0:N - 1).', N) + 1;
  R = rvec(offset_idx);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [M1, M2, N1, N2, M_res, N_res] = LOCAL_kernel_splits(k, t, geom_data)

  eulerc = 0.57721566490153286060;
  N = length(t);
  offdiag = ~eye(N);

  dx = geom_data.z(:,1) - geom_data.z(:,1).';
  dy = geom_data.z(:,2) - geom_data.z(:,2).';
  rho = sqrt(dx.^2 + dy.^2);
  rho_safe = rho;
  rho_safe(~offdiag) = 1;

  tdiff = t - t.';
  logterm = log(4 * sin(0.5 * tdiff).^2);
  cotterm = cot(0.5 * tdiff);

  speed_src = repmat(geom_data.speed.', N, 1);
  zp_dot_diff = bsxfun(@times, geom_data.zp(:,1), dx) ...
    + bsxfun(@times, geom_data.zp(:,2), dy);
  zp_dot_zpp = geom_data.zp(:,1) .* geom_data.zpp(:,1) ...
    + geom_data.zp(:,2) .* geom_data.zpp(:,2);

  M_full = 1i / 4 * besselh(0, 1, k * rho_safe) .* speed_src;
  M1 = -1 / (4 * pi) * besselj(0, k * rho_safe) .* speed_src;
  M2 = zeros(N, N);
  M2(offdiag) = M_full(offdiag) - M1(offdiag) .* logterm(offdiag);
  M1(~offdiag) = -1 / (4 * pi) * geom_data.speed;
  M2(~offdiag) = 0.5 * (1i / 2 - eulerc / pi ...
    - 1 / (2 * pi) * log((k^2 / 4) * geom_data.speed.^2)) ...
    .* geom_data.speed;

  ratio = zp_dot_diff ./ rho_safe;
  N_full = -1i * k / 4 * ratio .* besselh(1, 1, k * rho_safe);
  N1 = k / (4 * pi) * ratio .* besselj(1, k * rho_safe);
  N2 = zeros(N, N);
  N2(offdiag) = N_full(offdiag) - 1 / (4 * pi) * cotterm(offdiag) ...
    - N1(offdiag) .* logterm(offdiag);
  N1(~offdiag) = 0;
  N2(~offdiag) = 1 / (4 * pi) * zp_dot_zpp ./ (geom_data.speed.^2);

  M_res = max(abs(M_full(offdiag) ...
    - M1(offdiag) .* logterm(offdiag) - M2(offdiag)));
  N_res = max(abs(N_full(offdiag) - 1 / (4 * pi) * cotterm(offdiag) ...
    - N1(offdiag) .* logterm(offdiag) - N2(offdiag)));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function lambda = LOCAL_T_eigenvalue(mode, k, a)

  z = k * a;
  Jp = utils.besselj_deriv(mode, z);
  Hp = utils.besselh_deriv(mode, z);
  lambda = 1i * pi * a * k^2 / 2 * Jp * Hp;

end
