function [u, aux] = qpgreen_mfs_eval_bench(src, trg, opts)
% QPGREEN_MFS_EVAL_BENCH Evaluate project MFS qpgreen for benchmark targets.
%
% Purpose:
%   Provides a thin benchmark wrapper around kernel.precomp_proxy and
%   kernel.qpgreen_mfs for x-periodic quasi-periodic Green values.
%
% Main algorithm:
%   Builds the proxy-source and Rayleigh-plane-wave least-squares system
%   once for the supplied parameters, evaluates all nonsingular target
%   points, and returns NaN at source-image singularities.
%
% Based on:
%   +kernel/precomp_proxy.m and +kernel/qpgreen_mfs.m.
%
% Main changes:
%   This file only adapts benchmark name-value options to the existing
%   package API; it does not change package interfaces or mathematical
%   conventions.
%
% Numerical goal:
%   Make MFS-vs-Ewald comparisons reproducible while keeping all tunable
%   MFS parameters near the benchmark entry points.

  if size(src, 1) ~= 2 || size(src, 2) ~= 1
    error('qpgreen_mfs_eval_bench:InvalidSource', ...
      'src must be a 2-by-1 source point.');
  end
  if size(trg, 1) ~= 2
    error('qpgreen_mfs_eval_bench:InvalidTarget', ...
      'trg must be a 2-by-nt target array.');
  end

  pars1 = struct();
  pars1.k = opts.k;
  pars1.beta = opts.beta;
  pars1.d = opts.d;
  pars1.periodic_axis = 'x';

  pars2 = LOCAL_build_proxy_options(opts);

  t_precomp = tic;
  proxy = kernel.precomp_proxy(pars1, pars2);
  precomp_time = toc(t_precomp);

  nt = size(trg, 2);
  u = NaN(1, nt);
  valid = LOCAL_nonsingular_mask(src, trg, opts.d);

  t_eval = tic;
  if any(valid)
    green_data = kernel.qpgreen_mfs(src, trg(:, valid), pars1, proxy);
    u(valid) = green_data.pot;
  end
  eval_time = toc(t_eval);

  aux = struct();
  aux.precomp_time = precomp_time;
  aux.eval_time = eval_time;
  aux.total_time = precomp_time + eval_time;
  aux.pars1 = pars1;
  aux.pars2 = pars2;
  aux.proxy = proxy;
  aux.n_valid = nnz(valid);
  aux.n_singular = nt - nnz(valid);
  aux.diagnostics = LOCAL_proxy_system_diagnostics(pars1, pars2, proxy);
  aux.number_of_rayleigh_modes = aux.diagnostics.number_of_rayleigh_modes;
  aux.number_of_unknowns = aux.diagnostics.number_of_unknowns;
  aux.number_of_collocation_equations = ...
    aux.diagnostics.number_of_collocation_equations;
  aux.least_squares_residual = aux.diagnostics.least_squares_residual;
  aux.relative_least_squares_residual = ...
    aux.diagnostics.relative_least_squares_residual;
  aux.cond_estimate = aux.diagnostics.cond_estimate;
  aux.rcond_estimate = aux.diagnostics.rcond_estimate;
end

%% ==================== MFS option helper ====================
% This helper translates benchmark options to kernel.precomp_proxy fields.

function pars2 = LOCAL_build_proxy_options(opts)
  M = opts.M;
  N_proxy_edge = max(1, ceil(opts.Nproxy / 4));
  N_proxy_total = 4 * N_proxy_edge;
  N_pw_total = 2 * M + 1;
  N_unknowns = N_proxy_total + 2 * N_pw_total;
  automatic_collocation = max([N_pw_total, 2 * N_proxy_edge, ...
    ceil(1.2 * N_unknowns / 6)]);

  pars2 = struct();
  pars2.H = opts.H;
  pars2.proxy_dist = opts.ProxyDist;
  pars2.N_proxy_edge = N_proxy_edge;
  pars2.M_pw = M;

  if isempty(opts.NSide)
    pars2.N_side = automatic_collocation;
  else
    pars2.N_side = opts.NSide;
  end

  if isempty(opts.NTop)
    pars2.N_top = automatic_collocation;
  else
    pars2.N_top = opts.NTop;
  end
end

%% ==================== Source singularity helper ====================
% This helper removes points that coincide with any periodic source image.

function valid = LOCAL_nonsingular_mask(src, trg, d)
  dx_periodic = trg(1, :) - src(1);
  dx_periodic = dx_periodic - round(dx_periodic / d) * d;
  dy_transverse = trg(2, :) - src(2);
  radius = sqrt(dx_periodic.^2 + dy_transverse.^2);
  singular_tol = max(10*eps(max(1, abs(d))), 1e-14);
  valid = radius > singular_tol;
end

%% ==================== Least-squares diagnostic helper ====================
% These helpers rebuild the benchmark-only collocation system for reporting.

function diag = LOCAL_proxy_system_diagnostics(pars1, pars2, proxy)
  [A, b] = LOCAL_rebuild_proxy_system(pars1, pars2);
  coeffs = [proxy.q(:); proxy.C_up(:); proxy.C_down(:)];
  residual = A * coeffs - b;
  residual_norm = norm(residual);
  rhs_norm = norm(b);

  cond_estimate = NaN;
  rcond_estimate = NaN;
  if ~isempty(A)
    singular_values = svd(A, 0);
    if ~isempty(singular_values) && singular_values(end) > 0
      cond_estimate = singular_values(1) / singular_values(end);
      rcond_estimate = 1 / cond_estimate;
    end
  end

  diag = struct();
  diag.least_squares_residual = residual_norm;
  diag.relative_least_squares_residual = residual_norm / max(rhs_norm, eps);
  diag.cond_estimate = cond_estimate;
  diag.rcond_estimate = rcond_estimate;
  diag.number_of_proxy_sources = size(proxy.Z, 2);
  diag.number_of_rayleigh_modes = numel(proxy.C_up);
  diag.number_of_unknowns = size(A, 2);
  diag.number_of_collocation_equations = size(A, 1);
  diag.N_side = pars2.N_side;
  diag.N_top = pars2.N_top;
  diag.N_proxy_edge = pars2.N_proxy_edge;
end

function [A, b] = LOCAL_rebuild_proxy_system(pars1, pars2)
  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;

  H = pars2.H;
  proxy_dist = pars2.proxy_dist;
  N_side = pars2.N_side;
  N_top = pars2.N_top;
  N_proxy_edge = pars2.N_proxy_edge;
  M_pw = pars2.M_pw;

  src = [0, 0];

  y_side = linspace(-H, H, N_side).';
  p_L = [-d/2 * ones(N_side, 1), y_side];
  p_R = [ d/2 * ones(N_side, 1), y_side];

  x_top = linspace(-d/2, d/2, N_top).';
  p_T = [x_top,  H * ones(N_top, 1)];
  p_B = [x_top, -H * ones(N_top, 1)];

  x_min = -d/2 - proxy_dist;
  x_max =  d/2 + proxy_dist;
  y_min = -H - proxy_dist;
  y_max =  H + proxy_dist;

  tx = linspace(x_min, x_max, N_proxy_edge + 1).';
  tx(end) = [];
  ty = linspace(y_min, y_max, N_proxy_edge + 1).';
  ty(end) = [];

  px = [tx; repmat(x_max, N_proxy_edge, 1); ...
    flipud(tx); repmat(x_min, N_proxy_edge, 1)];
  py = [repmat(y_min, N_proxy_edge, 1); ty; ...
    repmat(y_max, N_proxy_edge, 1); flipud(ty)];
  Z_proxy = [px, py];
  N_proxy = size(Z_proxy, 1);

  m_vec = (-M_pw:M_pw).';
  N_pw_total = length(m_vec);
  beta_m = beta + m_vec * (2 * pi / d);
  gamma_m = sqrt(k^2 - beta_m.^2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);

  N_unknowns = N_proxy + 2 * N_pw_total;
  N_eqs = 2 * N_side + 4 * N_top;
  A = zeros(N_eqs, N_unknowns);
  b = zeros(N_eqs, 1);

  idx_LR_v = 1:N_side;
  idx_LR_d = (1:N_side) + N_side;
  idx_T_v  = (1:N_top) + 2 * N_side;
  idx_T_d  = (1:N_top) + 2 * N_side + N_top;
  idx_B_v  = (1:N_top) + 2 * N_side + 2 * N_top;
  idx_B_d  = (1:N_top) + 2 * N_side + 3 * N_top;

  col_proxy = 1:N_proxy;
  col_pw_T = (1:N_pw_total) + N_proxy;
  col_pw_B = (1:N_pw_total) + N_proxy + N_pw_total;

  phase = exp(1i * beta * d);

  [V_sL, dVdx_sL, ~] = LOCAL_eval_free_value_grad(k, p_L, src);
  [V_sR, dVdx_sR, ~] = LOCAL_eval_free_value_grad(k, p_R, src);
  b(idx_LR_v) = -(V_sR - phase * V_sL);
  b(idx_LR_d) = -(dVdx_sR - phase * dVdx_sL);

  [V_sT, ~, dVdy_sT] = LOCAL_eval_free_value_grad(k, p_T, src);
  b(idx_T_v) = -V_sT;
  b(idx_T_d) = -dVdy_sT;

  [V_sB, ~, dVdy_sB] = LOCAL_eval_free_value_grad(k, p_B, src);
  b(idx_B_v) = -V_sB;
  b(idx_B_d) = -dVdy_sB;

  [V_pL, dVdx_pL, ~] = LOCAL_eval_free_value_grad(k, p_L, Z_proxy);
  [V_pR, dVdx_pR, ~] = LOCAL_eval_free_value_grad(k, p_R, Z_proxy);
  A(idx_LR_v, col_proxy) = V_pR - phase * V_pL;
  A(idx_LR_d, col_proxy) = dVdx_pR - phase * dVdx_pL;

  [V_pT, ~, dVdy_pT] = LOCAL_eval_free_value_grad(k, p_T, Z_proxy);
  A(idx_T_v, col_proxy) = V_pT;
  A(idx_T_d, col_proxy) = dVdy_pT;

  [V_pB, ~, dVdy_pB] = LOCAL_eval_free_value_grad(k, p_B, Z_proxy);
  A(idx_B_v, col_proxy) = V_pB;
  A(idx_B_d, col_proxy) = dVdy_pB;

  PW_T_val = exp(1i * p_T(:, 1) * beta_m.');
  PW_T_der = PW_T_val .* (1i * gamma_m.');
  A(idx_T_v, col_pw_T) = -PW_T_val;
  A(idx_T_d, col_pw_T) = -PW_T_der;

  PW_B_val = exp(1i * p_B(:, 1) * beta_m.');
  PW_B_der = PW_B_val .* (-1i * gamma_m.');
  A(idx_B_v, col_pw_B) = -PW_B_val;
  A(idx_B_d, col_pw_B) = -PW_B_der;
end

function [value, grad_x, grad_y] = LOCAL_eval_free_value_grad(k, trg, src)
  dx = trg(:, 1) - src(:, 1).';
  dy = trg(:, 2) - src(:, 2).';
  r = sqrt(dx.^2 + dy.^2);
  value = (1i / 4) * besselh(0, 1, k * r);
  grad_factor = -(1i * k / 4) * besselh(1, 1, k * r) ./ r;
  grad_x = grad_factor .* dx;
  grad_y = grad_factor .* dy;
end
