function [proxy, proxy_A, proxy_b, info] = ...
    kproxy_v2(pars1, pars2, branch_gamma, ...
    proxy_chart, point_set)
%KPROXY_V2 Assemble and solve one affine-anchored proxy system.
%
% Purpose:
%   Preserve the V1 proxy assembly exactly while replacing its homogeneous
%   reduced solve by a seed-local affine correction.
%
% Input:
%   pars1, pars2 - Frozen proxy parameters.
%   branch_gamma - Anchored proxy-order values in native order.
%   proxy_chart - Empty for assembly-only, or a seed chart containing
%     A0, b0, c0, U, V, and r. An optional rcond_min may only strengthen
%     the frozen 1e-8 reduced-factor threshold.
%   point_set - 'collocation' or 'shifted'.
%
% Output:
%   proxy - Public q/Z/H/C_up/C_down struct, empty for assembly-only.
%   proxy_A, proxy_b - Branch-injected system assembled by kproxy.
%   info - Assembly metadata and affine-solve diagnostics.
%
% Main algorithm:
%   With d=(b-b0)-(A-A0)c0, solve
%     (U'*A*V) z = U'*d,  c = c0 + V*z.
%   The reduced factor is rejected before the solve when its reciprocal
%   condition estimate is below the frozen threshold.
%
% Based on:
%   test/i1/k-ready/kproxy.m.
%
% Main changes:
%   V2 delegates only V1's assembly-only path, then applies the supplied
%   seed chart. It performs no rank selection or adaptive least-squares
%   solve.
%
% Numerical goal:
%   Reproduce c0 at the seed and retain a fixed affine proxy chart off seed.

  if nargin < 4
    proxy_chart = [];
  end
  if nargin < 5 || isempty(point_set)
    point_set = 'collocation';
  end
  if isstring(point_set)
    point_set = char(point_set);
  end

  % kproxy returns before its solve when the chart is empty. This call is the
  % single source of assembly arithmetic for both V1 and V2.
  [~, proxy_A, proxy_b, info] = ...
    kproxy(pars1, pars2, branch_gamma, [], point_set);
  proxy = struct();

  info.available = false;
  info.failure_reason = '';
  info.proxy_rank = NaN;
  info.proxy_reduced_coefficients = [];
  info.proxy_affine_correction = [];
  info.proxy_coefficients = [];
  info.proxy_projected_residual = NaN;
  info.proxy_projected_backward = NaN;
  info.proxy_full_residual = NaN;
  info.proxy_seed_anchor_relative_error = NaN;
  info.proxy_factor_rcond = NaN;
  info.proxy_factor_rcond_threshold = 1e-8;

  if isempty(proxy_chart)
    return;
  end
  if ~strcmp(point_set, 'collocation')
    error('kready:ShiftedSolveForbidden', ...
      'The shifted system is diagnostic-only and must not be solved.');
  end

  required = {'A0', 'b0', 'c0', 'U', 'V', 'r'};
  for idx = 1:length(required)
    if ~isfield(proxy_chart, required{idx})
      error('kready:InvalidProxyChartV2', ...
        'proxy_chart must contain A0, b0, c0, U, V, and r.');
    end
  end

  frozen_rcond_min = 1e-8;
  rcond_min = frozen_rcond_min;
  if isfield(proxy_chart, 'rcond_min')
    supplied_min = proxy_chart.rcond_min;
    if ~isscalar(supplied_min) || ~isreal(supplied_min) || ...
        ~isfinite(supplied_min) || supplied_min < frozen_rcond_min
      error('kready:InvalidProxyThresholdV2', ...
        'rcond_min must be a finite real scalar at least 1e-8.');
    end
    rcond_min = supplied_min;
  end
  info.proxy_factor_rcond_threshold = rcond_min;

  r = proxy_chart.r;
  chart_size_ok = isscalar(r) && isreal(r) && isfinite(r) && ...
    r == floor(r) && r >= 1 && ...
    isequal(size(proxy_chart.A0), size(proxy_A)) && ...
    isequal(size(proxy_chart.b0), size(proxy_b)) && ...
    isequal(size(proxy_chart.c0), [size(proxy_A, 2), 1]) && ...
    size(proxy_chart.U, 1) == size(proxy_A, 1) && ...
    size(proxy_chart.V, 1) == size(proxy_A, 2) && ...
    size(proxy_chart.U, 2) >= r && size(proxy_chart.V, 2) >= r;
  if ~chart_size_ok
    info.failure_reason = 'REPRESENTATION_DRIFT';
    return;
  end
  chart_finite = all(isfinite(proxy_chart.A0), 'all') && ...
    all(isfinite(proxy_chart.b0), 'all') && ...
    all(isfinite(proxy_chart.c0), 'all') && ...
    all(isfinite(proxy_chart.U(:, 1:r)), 'all') && ...
    all(isfinite(proxy_chart.V(:, 1:r)), 'all');
  if ~chart_finite
    info.failure_reason = 'REPRESENTATION_DRIFT';
    return;
  end

  proxy_U = proxy_chart.U(:, 1:r);
  proxy_V = proxy_chart.V(:, 1:r);
  affine_rhs = (proxy_b - proxy_chart.b0) - ...
    (proxy_A - proxy_chart.A0) * proxy_chart.c0;
  reduced_A = proxy_U' * proxy_A * proxy_V;
  reduced_b = proxy_U' * affine_rhs;
  info.proxy_factor_rcond = rcond(reduced_A);
  info.proxy_rank = r;
  if ~isfinite(info.proxy_factor_rcond) || ...
      info.proxy_factor_rcond < rcond_min
    info.failure_reason = 'PROXY_COMPRESSION_POLE';
    return;
  end

  % This is the sole V2 solve. The factor gate above is deliberately before
  % the backslash so an unsafe chart cannot trigger a solver fallback.
  proxy_reduced_coefficients = reduced_A \ reduced_b;
  affine_correction = proxy_V * proxy_reduced_coefficients;
  proxy_coefficients = proxy_chart.c0 + affine_correction;
  reduced_residual = ...
    reduced_A * proxy_reduced_coefficients - reduced_b;

  info.proxy_reduced_coefficients = proxy_reduced_coefficients;
  info.proxy_affine_correction = affine_correction;
  info.proxy_coefficients = proxy_coefficients;
  info.proxy_projected_residual = norm(reduced_residual, 2) / ...
    max(1, norm(reduced_b, 2));
  info.proxy_projected_backward = norm(reduced_residual, 2) / max(1, ...
    norm(reduced_A, 2) * norm(proxy_reduced_coefficients, 2) + ...
    norm(reduced_b, 2));
  info.proxy_full_residual = ...
    norm(proxy_A * proxy_coefficients - proxy_b, 2) / ...
    max(1, norm(proxy_b, 2));
  info.proxy_seed_anchor_relative_error = ...
    norm(proxy_coefficients - proxy_chart.c0, 2) / ...
    max(1, norm(proxy_chart.c0, 2));

  info.available = all(isfinite(proxy_coefficients)) && ...
    isfinite(info.proxy_projected_residual) && ...
    isfinite(info.proxy_projected_backward) && ...
    isfinite(info.proxy_full_residual) && ...
    isfinite(info.proxy_seed_anchor_relative_error);
  if ~info.available
    info.failure_reason = 'PROXY_COMPRESSION_POLE';
    return;
  end

  n_proxy = info.n_proxy;
  n_pw = info.n_pw;
  proxy.q = proxy_coefficients(1:n_proxy).';
  proxy.Z = info.Z_proxy.';
  proxy.H = info.H;
  proxy.C_up = proxy_coefficients(n_proxy + (1:n_pw));
  proxy.C_down = proxy_coefficients(n_proxy + n_pw + (1:n_pw));
end
