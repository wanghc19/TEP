function [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    qpgreen_mfs_pairmat(src, trg, pars1, proxy, varargin)
% QPGREEN_MFS_PAIRMAT Evaluate quasi-periodic Green data for all point pairs.
%
% Purpose:
%   Builds dense target-by-source matrices for the augmented MFS
%   quasi-periodic Green's function and its first and second derivatives.
%
% Input:
%   src   - Source coordinates as a 2-by-ns array.
%   trg   - Target coordinates as a 2-by-nt array.
%   pars1 - Physical parameter struct with fields d, beta, and k.  Optional
%           field periodic_axis selects the physical periodic direction.
%   proxy - Precomputed proxy/plane-wave struct from kernel.precomp_proxy.
%   varargin - Optional periodic axis override, either 'x' or 'y'.
%
% Output:
%   pot_ext    - Potential matrix of size nt-by-ns.
%   gradx_ext  - x-derivative matrix of size nt-by-ns.
%   grady_ext  - y-derivative matrix of size nt-by-ns.
%   hessxx_ext - xx Hessian matrix of size nt-by-ns.
%   hessxy_ext - xy Hessian matrix of size nt-by-ns.
%   hessyy_ext - yy Hessian matrix of size nt-by-ns.
%
% Notes:
%   This pairwise matrix routine uses the same periodic_axis convention as
%   kernel.qpgreen_mfs.  The default is physical x-periodicity, matching the
%   original behavior.  When periodic_axis = 'y', physical coordinates are
%   swapped internally so that the existing first-coordinate-periodic
%   computational kernel can be reused.
%
%   The proxy precomputation in kernel.precomp_proxy still interprets pars1.d
%   and proxy.H in computational coordinates only; it does not know about
%   physical x/y periodic directions.  For periodic_axis = 'y', pars1.d is
%   the physical y-period, and proxy.H is the half-width in the exchanged
%   computational non-periodic direction, namely the physical x half-width.
%
%   Derivatives are returned in physical coordinates.  For y-periodicity the
%   computed matrices are remapped as
%     G_{x_phys} = G_{y_comp},  G_{y_phys} = G_{x_comp},
%   and
%     G_{x_phys x_phys} = G_{y_comp y_comp},
%     G_{x_phys y_phys} = G_{x_comp y_comp},
%     G_{y_phys y_phys} = G_{x_comp x_comp}.

  periodic_axis = LOCAL_parse_periodic_axis(pars1, varargin{:});

  if strcmp(periodic_axis, 'x')
    [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
      LOCAL_qpgreen_mfs_pairmat_xperiodic(src, trg, pars1, proxy);
    return;
  end

  src_comp = src([2 1], :);
  trg_comp = trg([2 1], :);
  [pot_ext, gradx_comp, grady_comp, hessxx_comp, hessxy_ext, hessyy_comp] = ...
    LOCAL_qpgreen_mfs_pairmat_xperiodic(src_comp, trg_comp, pars1, proxy);

  gradx_ext = grady_comp;
  grady_ext = gradx_comp;
  hessxx_ext = hessyy_comp;
  hessyy_ext = hessxx_comp;

end

function [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    LOCAL_qpgreen_mfs_pairmat_xperiodic(src, trg, pars1, proxy)

  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;

  q = proxy.q;
  Z = proxy.Z;
  H = proxy.H;
  C_up = proxy.C_up;
  C_down = proxy.C_down;

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
    N_pw_total = length(C_up);
    M_pw = (N_pw_total - 1) / 2;
    m_vec = (-M_pw:M_pw).';
    beta_m = beta + m_vec * (2 * pi / d);

    diff_sq = k^2 - beta_m.^2;
    gamma_m = zeros(size(beta_m));
    mask_prop = diff_sq >= 0;
    mask_eva = diff_sq < 0;
    gamma_m(mask_prop) = sqrt(diff_sq(mask_prop));
    gamma_m(mask_eva) = 1i * sqrt(-diff_sq(mask_eva));

    if any(idx_up(:))
      X_up = X0(idx_up).';
      Y_up = Y(idx_up).';
      phase_X = exp(1i * beta_m * X_up);
      phase_Y = exp(1i * gamma_m * (Y_up - H));
      basis = phase_X .* phase_Y;
      phase_up = phase_shift(idx_up).';

      pot_ext(idx_up) = sum(C_up .* basis, 1) .* phase_up;
      gradx_ext(idx_up) = sum(C_up .* basis .* (1i * beta_m), 1) .* phase_up;
      grady_ext(idx_up) = sum(C_up .* basis .* (1i * gamma_m), 1) .* phase_up;
      hessxx_ext(idx_up) = sum(C_up .* basis .* (-beta_m.^2), 1) .* phase_up;
      hessxy_ext(idx_up) = sum(C_up .* basis .* (-beta_m .* gamma_m), 1) .* phase_up;
      hessyy_ext(idx_up) = sum(C_up .* basis .* (-gamma_m.^2), 1) .* phase_up;
    end

    if any(idx_dn(:))
      X_dn = X0(idx_dn).';
      Y_dn = Y(idx_dn).';
      phase_X = exp(1i * beta_m * X_dn);
      phase_Y = exp(-1i * gamma_m * (Y_dn + H));
      basis = phase_X .* phase_Y;
      phase_dn = phase_shift(idx_dn).';

      pot_ext(idx_dn) = sum(C_down .* basis, 1) .* phase_dn;
      gradx_ext(idx_dn) = sum(C_down .* basis .* (1i * beta_m), 1) .* phase_dn;
      grady_ext(idx_dn) = sum(C_down .* basis .* (-1i * gamma_m), 1) .* phase_dn;
      hessxx_ext(idx_dn) = sum(C_down .* basis .* (-beta_m.^2), 1) .* phase_dn;
      hessxy_ext(idx_dn) = sum(C_down .* basis .* (beta_m .* gamma_m), 1) .* phase_dn;
      hessyy_ext(idx_dn) = sum(C_down .* basis .* (-gamma_m.^2), 1) .* phase_dn;
    end
  end

end

function periodic_axis = LOCAL_parse_periodic_axis(pars1, varargin)

  periodic_axis = 'x';
  if isfield(pars1, 'periodic_axis') && ~isempty(pars1.periodic_axis)
    periodic_axis = LOCAL_normalize_periodic_axis(pars1.periodic_axis);
  end

  if numel(varargin) > 1
    error('kernel:qpgreen_mfs_pairmat:InvalidPeriodicAxis', ...
      'Pass at most one periodic axis override.');
  end

  if numel(varargin) == 1
    periodic_axis = LOCAL_normalize_periodic_axis(varargin{1});
  end

end

function periodic_axis = LOCAL_normalize_periodic_axis(periodic_axis)

  if isstring(periodic_axis)
    if ~isscalar(periodic_axis)
      error('kernel:qpgreen_mfs_pairmat:InvalidPeriodicAxis', ...
        'periodic_axis must be either ''x'' or ''y''.');
    end
    periodic_axis = char(periodic_axis);
  elseif ~ischar(periodic_axis)
    error('kernel:qpgreen_mfs_pairmat:InvalidPeriodicAxis', ...
      'periodic_axis must be either ''x'' or ''y''.');
  end

  periodic_axis = lower(strtrim(periodic_axis));
  if ~strcmp(periodic_axis, 'x') && ~strcmp(periodic_axis, 'y')
    error('kernel:qpgreen_mfs_pairmat:InvalidPeriodicAxis', ...
      'periodic_axis must be either ''x'' or ''y''.');
  end

end
