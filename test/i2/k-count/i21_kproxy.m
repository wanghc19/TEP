function [proxy, proxy_A, proxy_b, info] = ...
    i21_kproxy(pars1, pars2, branch_gamma, proxy_chart, point_set)
%I21_KPROXY Assemble and solve the frozen affine proxy representation.
% Purpose:
%   Expose the actual reduced factor used by I2.1 while preserving the I1.4
%   affine proxy arithmetic and fail-closed solve policy.
% Input:
%   pars1, pars2, branch_gamma, proxy_chart, point_set - See the I1.4
%   kproxy_v2 contract.
% Output:
%   proxy, proxy_A, proxy_b - I1.4-compatible values.
%   info - I1.4 diagnostics plus the actual reduced_A factor.
% Main algorithm:
%   Assemble through the unchanged test-local I1 kproxy helper, then solve
%   U' A V z = U'[(b-b0)-(A-A0)c0] in the frozen affine chart.
% Based on:
%   test/i1/k-ready/kproxy_v2.m.
% Main changes:
%   Return reduced_A for factor-aware determinant accounting; no numerical
%   formula, rank choice, or solver is changed.
% Numerical goal:
%   Distinguish a proxy-factor pole from a defect determinant zero.

  if nargin < 4, proxy_chart = []; end
  if nargin < 5 || isempty(point_set), point_set = 'collocation'; end
  if isstring(point_set), point_set = char(point_set); end

  [~,proxy_A,proxy_b,info] = ...
    kproxy(pars1,pars2,branch_gamma,[],point_set);
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
  info.reduced_A = [];

  if isempty(proxy_chart), return; end
  if ~strcmp(point_set,'collocation')
    error('i21:ShiftedSolveForbidden', ...
      'The shifted proxy system is diagnostic-only.');
  end
  required = {'A0','b0','c0','U','V','r'};
  for j = 1:numel(required)
    if ~isfield(proxy_chart,required{j})
      error('i21:InvalidProxyChart','Missing proxy chart field %s.',required{j});
    end
  end

  r = proxy_chart.r;
  shape_ok = isscalar(r) && isreal(r) && isfinite(r) && r == floor(r) && ...
    r >= 1 && isequal(size(proxy_chart.A0),size(proxy_A)) && ...
    isequal(size(proxy_chart.b0),size(proxy_b)) && ...
    isequal(size(proxy_chart.c0),[size(proxy_A,2),1]) && ...
    size(proxy_chart.U,1) == size(proxy_A,1) && ...
    size(proxy_chart.V,1) == size(proxy_A,2) && ...
    size(proxy_chart.U,2) >= r && size(proxy_chart.V,2) >= r;
  if ~shape_ok
    info.failure_reason = 'REPRESENTATION_DRIFT';
    return;
  end
  finite_ok = all(isfinite(proxy_chart.A0),'all') && ...
    all(isfinite(proxy_chart.b0),'all') && ...
    all(isfinite(proxy_chart.c0),'all') && ...
    all(isfinite(proxy_chart.U(:,1:r)),'all') && ...
    all(isfinite(proxy_chart.V(:,1:r)),'all');
  if ~finite_ok
    info.failure_reason = 'REPRESENTATION_DRIFT';
    return;
  end

  U = proxy_chart.U(:,1:r); V = proxy_chart.V(:,1:r);
  affine_rhs = (proxy_b-proxy_chart.b0)- ...
    (proxy_A-proxy_chart.A0)*proxy_chart.c0;
  reduced_A = U'*proxy_A*V;
  reduced_b = U'*affine_rhs;
  info.reduced_A = reduced_A;
  info.proxy_factor_rcond = rcond(reduced_A);
  info.proxy_rank = r;
  if ~isfinite(info.proxy_factor_rcond) || ...
      info.proxy_factor_rcond < info.proxy_factor_rcond_threshold
    info.failure_reason = 'PROXY_COMPRESSION_POLE';
    return;
  end

  reduced_coefficients = reduced_A\reduced_b;
  correction = V*reduced_coefficients;
  coefficients = proxy_chart.c0+correction;
  reduced_residual = reduced_A*reduced_coefficients-reduced_b;
  info.proxy_reduced_coefficients = reduced_coefficients;
  info.proxy_affine_correction = correction;
  info.proxy_coefficients = coefficients;
  info.proxy_projected_residual = norm(reduced_residual,2)/ ...
    max(1,norm(reduced_b,2));
  info.proxy_projected_backward = norm(reduced_residual,2)/max(1, ...
    norm(reduced_A,2)*norm(reduced_coefficients,2)+norm(reduced_b,2));
  info.proxy_full_residual = norm(proxy_A*coefficients-proxy_b,2)/ ...
    max(1,norm(proxy_b,2));
  info.proxy_seed_anchor_relative_error = ...
    norm(coefficients-proxy_chart.c0,2)/max(1,norm(proxy_chart.c0,2));
  info.available = all(isfinite(coefficients)) && ...
    isfinite(info.proxy_projected_residual) && ...
    isfinite(info.proxy_projected_backward) && ...
    isfinite(info.proxy_full_residual) && ...
    isfinite(info.proxy_seed_anchor_relative_error);
  if ~info.available
    info.failure_reason = 'PROXY_COMPRESSION_POLE';
    return;
  end

  np = info.n_proxy; nw = info.n_pw;
  proxy.q = coefficients(1:np).';
  proxy.Z = info.Z_proxy.';
  proxy.H = info.H;
  proxy.C_up = coefficients(np+(1:nw));
  proxy.C_down = coefficients(np+nw+(1:nw));
end
