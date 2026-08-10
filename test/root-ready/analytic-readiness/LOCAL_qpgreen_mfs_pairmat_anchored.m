function [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    LOCAL_qpgreen_mfs_pairmat_anchored( ...
    src, trg, pars1, proxy, branch_gamma, varargin)
% LOCAL_QPGREEN_MFS_PAIRMAT_ANCHORED Evaluate QP Green pair matrices.
%
% Purpose:
%   Preserve the package MFS evaluation while supplying, rather than
%   recreating, the anchored outer plane-wave branch.
%
% Input:
%   src, trg, pars1, proxy - Package-compatible Green inputs.
%   branch_gamma - Anchored proxy-order values.
%   varargin - Optional periodic-axis override.
%
% Output:
%   Potential, gradient, and Hessian pair matrices.
%
% Based on:
%   +kernel/qpgreen_mfs_pairmat.m.
%
% Main changes:
%   The outer-region square root and sign correction are removed.
%
% Numerical goal:
%   Ensure off-box Green evaluation uses the common I4 branch provider.

  periodic_axis = LOCAL_parse_periodic_axis(pars1, varargin{:});
  if strcmp(periodic_axis, 'x')
    [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
      LOCAL_xperiodic(src, trg, pars1, proxy, branch_gamma);
    return;
  end

  src_comp = src([2, 1], :);
  trg_comp = trg([2, 1], :);
  [pot_ext, gradx_comp, grady_comp, hessxx_comp, hessxy_ext, hessyy_comp] = ...
    LOCAL_xperiodic(src_comp, trg_comp, pars1, proxy, branch_gamma);
  gradx_ext = grady_comp;
  grady_ext = gradx_comp;
  hessxx_ext = hessyy_comp;
  hessyy_ext = hessxx_comp;
end

%% ==================== Anchored evaluator ====================
% This helper implements the x-periodic arithmetic in computational axes.

function [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    LOCAL_xperiodic(src, trg, pars1, proxy, branch_gamma)
  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;
  q = proxy.q;
  Z = proxy.Z;
  H = proxy.H;
  C_up = proxy.C_up(:);
  C_down = proxy.C_down(:);
  ns = size(src, 2);
  nt = size(trg, 2);
  X = trg(1, :).'- src(1, :);
  Y = trg(2, :).'- src(2, :);
  m_shift = round(X / d);
  X0 = X - m_shift * d;
  phase_shift = exp(1i * beta * m_shift * d);
  pot_ext = zeros(nt, ns);
  gradx_ext = zeros(nt, ns);
  grady_ext = zeros(nt, ns);
  hessxx_ext = zeros(nt, ns);
  hessxy_ext = zeros(nt, ns);
  hessyy_ext = zeros(nt, ns);
  idx_in = abs(Y) <= H;
  idx_up = Y > H;
  idx_dn = Y < -H;

  if any(idx_in(:))
    T_in = [X0(idx_in).'; Y(idx_in).'];
    [pot0, grad0, hess0] = kernel.h2d_directch(k, [0; 0], 1, T_in);
    [potP, gradP, hessP] = kernel.h2d_directch(k, Z, q, T_in);
    pot_ext(idx_in) = (pot0 + potP) .* phase_shift(idx_in).';
    gradx_ext(idx_in) = (grad0(1, :) + gradP(1, :)) .* phase_shift(idx_in).';
    grady_ext(idx_in) = (grad0(2, :) + gradP(2, :)) .* phase_shift(idx_in).';
    hessxx_ext(idx_in) = (hess0(1, :) + hessP(1, :)) .* phase_shift(idx_in).';
    hessxy_ext(idx_in) = (hess0(2, :) + hessP(2, :)) .* phase_shift(idx_in).';
    hessyy_ext(idx_in) = (hess0(3, :) + hessP(3, :)) .* phase_shift(idx_in).';
  end

  if any(idx_up(:)) || any(idx_dn(:))
    n_pw = length(C_up);
    m_pw = (n_pw - 1) / 2;
    m_vec = (-m_pw:m_pw).';
    beta_m = beta + m_vec * (2 * pi / d);
    branch_gamma = branch_gamma(:);
    if length(branch_gamma) ~= n_pw || any(~isfinite(branch_gamma))
      error('analytic_readiness:OuterBranchSize', ...
        'branch_gamma must match proxy.C_up/C_down.');
    end
    if any(idx_up(:))
      X_up = X0(idx_up).';
      Y_up = Y(idx_up).';
      basis = exp(1i * beta_m * X_up) .* ...
        exp(1i * branch_gamma * (Y_up - H));
      phase_up = phase_shift(idx_up).';
      pot_ext(idx_up) = sum(C_up .* basis, 1) .* phase_up;
      gradx_ext(idx_up) = sum(C_up .* basis .* (1i * beta_m), 1) .* phase_up;
      grady_ext(idx_up) = sum(C_up .* basis .* (1i * branch_gamma), 1) .* phase_up;
      hessxx_ext(idx_up) = sum(C_up .* basis .* (-beta_m.^2), 1) .* phase_up;
      hessxy_ext(idx_up) = ...
        sum(C_up .* basis .* (-beta_m .* branch_gamma), 1) .* phase_up;
      hessyy_ext(idx_up) = ...
        sum(C_up .* basis .* (-branch_gamma.^2), 1) .* phase_up;
    end
    if any(idx_dn(:))
      X_dn = X0(idx_dn).';
      Y_dn = Y(idx_dn).';
      basis = exp(1i * beta_m * X_dn) .* ...
        exp(-1i * branch_gamma * (Y_dn + H));
      phase_dn = phase_shift(idx_dn).';
      pot_ext(idx_dn) = sum(C_down .* basis, 1) .* phase_dn;
      gradx_ext(idx_dn) = ...
        sum(C_down .* basis .* (1i * beta_m), 1) .* phase_dn;
      grady_ext(idx_dn) = ...
        sum(C_down .* basis .* (-1i * branch_gamma), 1) .* phase_dn;
      hessxx_ext(idx_dn) = ...
        sum(C_down .* basis .* (-beta_m.^2), 1) .* phase_dn;
      hessxy_ext(idx_dn) = ...
        sum(C_down .* basis .* (beta_m .* branch_gamma), 1) .* phase_dn;
      hessyy_ext(idx_dn) = ...
        sum(C_down .* basis .* (-branch_gamma.^2), 1) .* phase_dn;
    end
  end
end

%% ==================== Axis parsing ====================
% This helper preserves the package periodic-axis convention.

function periodic_axis = LOCAL_parse_periodic_axis(pars1, varargin)
  periodic_axis = 'x';
  if isfield(pars1, 'periodic_axis') && ~isempty(pars1.periodic_axis)
    periodic_axis = pars1.periodic_axis;
  end
  if ~isempty(varargin)
    periodic_axis = varargin{1};
  end
  if isstring(periodic_axis)
    periodic_axis = char(periodic_axis);
  end
  periodic_axis = lower(strtrim(periodic_axis));
  if ~strcmp(periodic_axis, 'x') && ~strcmp(periodic_axis, 'y')
    error('analytic_readiness:InvalidPeriodicAxis', ...
      'periodic_axis must be x or y.');
  end
end
