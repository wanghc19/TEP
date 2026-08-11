function [proxy, proxy_A, proxy_b, info] = ...
    LOCAL_precomp_proxy_anchored(pars1, pars2, branch_gamma, ...
    proxy_chart, point_set)
% LOCAL_PRECOMP_PROXY_ANCHORED Assemble and solve one anchored proxy system.
%
% Purpose:
%   Return the branch-injected proxy collocation arrays and, only when a
%   seed-frozen chart is supplied, solve the fixed Petrov--Galerkin system.
%
% Input:
%   pars1, pars2 - Frozen proxy parameters.
%   branch_gamma - Anchored proxy-order values in native order.
%   proxy_chart - Empty for assembly-only, or a struct with U, V, and rank.
%   point_set - 'collocation' or 'shifted'.
%
% Output:
%   proxy - Public q/Z/H/C_up/C_down struct, empty for assembly-only.
%   proxy_A, proxy_b - Unsolved branch-injected system.
%   info - Row metadata and fixed-chart residual diagnostics.
%
% Based on:
%   +kernel/precomp_proxy.m and the I3 shifted residual constructor.
%
% Main changes:
%   Pointwise square roots and adaptive least-squares solves are removed.
%   The only solve is in caller-supplied, seed-frozen coordinates.
%
% Numerical goal:
%   Provide one analytic proxy representation throughout the I4 disk.

  if nargin < 4
    proxy_chart = [];
  end
  if nargin < 5 || isempty(point_set)
    point_set = 'collocation';
  end
  if isstring(point_set)
    point_set = char(point_set);
  end

  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;
  H = pars2.H;
  proxy_dist = pars2.proxy_dist;
  n_side = pars2.N_side;
  n_top = pars2.N_top;
  n_proxy_edge = pars2.N_proxy_edge;
  m_pw = pars2.M_pw;

  if strcmp(point_set, 'collocation')
    y_side = linspace(-H, H, n_side).';
    x_top = linspace(-d / 2, d / 2, n_top).';
  elseif strcmp(point_set, 'shifted')
    n_side = 2 * n_side;
    n_top = 2 * n_top;
    y_side = -H + ((0:n_side - 1).' + 0.5) * (2 * H / n_side);
    x_top = -d / 2 + ((0:n_top - 1).' + 0.5) * (d / n_top);
  else
    error('analytic_readiness:InvalidProxyPointSet', ...
      'point_set must be collocation or shifted.');
  end

  p_L = [-d / 2 * ones(n_side, 1), y_side];
  p_R = [ d / 2 * ones(n_side, 1), y_side];
  p_T = [x_top, H * ones(n_top, 1)];
  p_B = [x_top, -H * ones(n_top, 1)];
  x_min = -d / 2 - proxy_dist;
  x_max = d / 2 + proxy_dist;
  y_min = -H - proxy_dist;
  y_max = H + proxy_dist;
  tx = linspace(x_min, x_max, n_proxy_edge + 1).';
  ty = linspace(y_min, y_max, n_proxy_edge + 1).';
  tx(end) = [];
  ty(end) = [];
  px = [tx; repmat(x_max, n_proxy_edge, 1); flipud(tx); ...
    repmat(x_min, n_proxy_edge, 1)];
  py = [repmat(y_min, n_proxy_edge, 1); ty; ...
    repmat(y_max, n_proxy_edge, 1); flipud(ty)];
  Z_proxy = [px, py];
  n_proxy = size(Z_proxy, 1);

  m_vec = (-m_pw:m_pw).';
  beta_m = beta + m_vec * (2 * pi / d);
  branch_gamma = branch_gamma(:);
  n_pw = length(m_vec);
  if length(branch_gamma) ~= n_pw || any(~isfinite(branch_gamma))
    error('analytic_readiness:ProxyBranchSize', ...
      'branch_gamma must match the proxy native order.');
  end

  n_eqs = 2 * n_side + 4 * n_top;
  n_unknowns = n_proxy + 2 * n_pw;
  proxy_A = zeros(n_eqs, n_unknowns);
  proxy_b = zeros(n_eqs, 1);
  idx_LR_v = 1:n_side;
  idx_LR_d = n_side + (1:n_side);
  idx_T_v = 2 * n_side + (1:n_top);
  idx_T_d = 2 * n_side + n_top + (1:n_top);
  idx_B_v = 2 * n_side + 2 * n_top + (1:n_top);
  idx_B_d = 2 * n_side + 3 * n_top + (1:n_top);
  col_proxy = 1:n_proxy;
  col_pw_T = n_proxy + (1:n_pw);
  col_pw_B = n_proxy + n_pw + (1:n_pw);

  qp_phase = exp(1i * beta * d);
  src = [0, 0];
  [V_sL, dVdx_sL, ~] = LOCAL_eval_G(k, p_L, src);
  [V_sR, dVdx_sR, ~] = LOCAL_eval_G(k, p_R, src);
  proxy_b(idx_LR_v) = -(V_sR - qp_phase * V_sL);
  proxy_b(idx_LR_d) = -(dVdx_sR - qp_phase * dVdx_sL);
  [V_sT, ~, dVdy_sT] = LOCAL_eval_G(k, p_T, src);
  [V_sB, ~, dVdy_sB] = LOCAL_eval_G(k, p_B, src);
  proxy_b(idx_T_v) = -V_sT;
  proxy_b(idx_T_d) = -dVdy_sT;
  proxy_b(idx_B_v) = -V_sB;
  proxy_b(idx_B_d) = -dVdy_sB;

  [V_pL, dVdx_pL, ~] = LOCAL_eval_G(k, p_L, Z_proxy);
  [V_pR, dVdx_pR, ~] = LOCAL_eval_G(k, p_R, Z_proxy);
  proxy_A(idx_LR_v, col_proxy) = V_pR - qp_phase * V_pL;
  proxy_A(idx_LR_d, col_proxy) = dVdx_pR - qp_phase * dVdx_pL;
  [V_pT, ~, dVdy_pT] = LOCAL_eval_G(k, p_T, Z_proxy);
  [V_pB, ~, dVdy_pB] = LOCAL_eval_G(k, p_B, Z_proxy);
  proxy_A(idx_T_v, col_proxy) = V_pT;
  proxy_A(idx_T_d, col_proxy) = dVdy_pT;
  proxy_A(idx_B_v, col_proxy) = V_pB;
  proxy_A(idx_B_d, col_proxy) = dVdy_pB;
  PW_T = exp(1i * p_T(:, 1) * beta_m.');
  PW_B = exp(1i * p_B(:, 1) * beta_m.');
  proxy_A(idx_T_v, col_pw_T) = -PW_T;
  proxy_A(idx_T_d, col_pw_T) = ...
    -PW_T .* (1i * branch_gamma.');
  proxy_A(idx_B_v, col_pw_B) = -PW_B;
  proxy_A(idx_B_d, col_pw_B) = ...
    -PW_B .* (-1i * branch_gamma.');

  info.point_set = point_set;
  info.indices = {idx_LR_v, idx_LR_d, idx_T_v, ...
    idx_T_d, idx_B_v, idx_B_d};
  info.Z_proxy = Z_proxy;
  info.H = H;
  info.n_proxy = n_proxy;
  info.n_pw = n_pw;
  info.beta_m = beta_m;
  info.branch_gamma = branch_gamma;
  info.available = false;
  info.failure_reason = '';
  info.proxy_rank = NaN;
  info.proxy_reduced_coefficients = [];
  info.proxy_coefficients = [];
  info.proxy_projected_residual = NaN;
  info.proxy_projected_backward = NaN;
  info.proxy_full_residual = NaN;
  info.proxy_factor_rcond = NaN;
  proxy = struct();

  if isempty(proxy_chart)
    return;
  end
  if ~strcmp(point_set, 'collocation')
    error('analytic_readiness:ShiftedSolveForbidden', ...
      'The shifted system is diagnostic-only and must not be solved.');
  end
  required = {'U', 'V', 'rank'};
  for idx = 1:length(required)
    if ~isfield(proxy_chart, required{idx})
      error('analytic_readiness:InvalidProxyChart', ...
        'proxy_chart must contain U, V, and rank.');
    end
  end
  r = proxy_chart.rank;
  if r < 1 || size(proxy_chart.U, 2) < r || size(proxy_chart.V, 2) < r || ...
      size(proxy_chart.U, 1) ~= size(proxy_A, 1) || ...
      size(proxy_chart.V, 1) ~= size(proxy_A, 2)
    info.failure_reason = 'REPRESENTATION_DRIFT';
    return;
  end
  proxy_U = proxy_chart.U(:, 1:r);
  proxy_V = proxy_chart.V(:, 1:r);
  reduced_A = proxy_U' * proxy_A * proxy_V;
  reduced_b = proxy_U' * proxy_b;
  info.proxy_factor_rcond = rcond(reduced_A);
  if ~isfinite(info.proxy_factor_rcond) || info.proxy_factor_rcond == 0
    info.failure_reason = 'PROXY_COMPRESSION_POLE';
    return;
  end
  proxy_reduced_coefficients = reduced_A \ reduced_b;
  proxy_coefficients = proxy_V * proxy_reduced_coefficients;
  projected = proxy_U' * (proxy_A * proxy_coefficients - proxy_b);
  info.proxy_projected_residual = norm(projected, 2) / ...
    max(1, norm(proxy_b, 2));
  info.proxy_projected_backward = norm(projected, 2) / max(1, ...
    norm(reduced_A, 2) * norm(proxy_reduced_coefficients, 2) + ...
    norm(reduced_b, 2));
  info.proxy_full_residual = ...
    norm(proxy_A * proxy_coefficients - proxy_b, 2) / ...
    max(1, norm(proxy_b, 2));
  info.proxy_rank = r;
  info.proxy_reduced_coefficients = proxy_reduced_coefficients;
  info.proxy_coefficients = proxy_coefficients;
  info.available = all(isfinite(proxy_coefficients));
  if ~info.available
    info.failure_reason = 'PROXY_COMPRESSION_POLE';
    return;
  end
  proxy.q = proxy_coefficients(1:n_proxy).';
  proxy.Z = Z_proxy.';
  proxy.H = H;
  proxy.C_up = proxy_coefficients(n_proxy + (1:n_pw));
  proxy.C_down = proxy_coefficients(n_proxy + n_pw + (1:n_pw));
end

%% ==================== Free-space kernel ====================
% This helper assembles the nonperiodic Hankel source terms only.

function [V, dVdx, dVdy] = LOCAL_eval_G(k, pt, ps)
  dx = pt(:, 1) - ps(:, 1).';
  dy = pt(:, 2) - ps(:, 2).';
  rho = sqrt(dx.^2 + dy.^2);
  V = (1i / 4) * besselh(0, 1, k * rho);
  coefficient = -(1i * k / 4) * besselh(1, 1, k * rho) ./ rho;
  dVdx = coefficient .* dx;
  dVdy = coefficient .* dy;
end
