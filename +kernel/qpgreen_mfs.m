function u = qpgreen_mfs(src, trg, pars1, pars2, varargin)
% QPGREEN_MFS Evaluate the quasi-periodic Green function by augmented MFS.
%
% Purpose:
%   Evaluates the quasi-periodic Green's function, gradient, and Hessian
%   using proxy sources inside the proxy box and plane-wave expansions in the
%   non-periodic computational direction.
%
% Input:
%   src   - Source coordinate as a 2-by-1 vector.
%   trg   - Target coordinates as a 2-by-nt array.
%   pars1 - Physical parameter struct with fields d, beta, and k.  Optional
%           field periodic_axis selects the physical periodic direction.
%   pars2 - Proxy/plane-wave coefficient struct with fields q, Z, H,
%           C_up, and C_down.
%   varargin - Optional periodic axis override, either 'x' or 'y'.
%
% Output:
%   u - Struct with fields pot (1-by-nt), grad (2-by-nt), and hess
%       (3-by-nt) at the target points.
%
% Notes:
%   The default is physical x-periodicity, matching the original behavior.
%   When periodic_axis = 'y', physical coordinates are swapped internally:
%   x_comp = y_phys and y_comp = x_phys.  This maps the physical y-periodic
%   problem to the existing first-coordinate-periodic computational kernel.
%
%   The proxy precomputation in kernel.precomp_proxy still interprets pars1.d
%   and pars2.H in computational coordinates only; it does not know about
%   physical x/y periodic directions.  For periodic_axis = 'y', pars1.d is
%   the physical y-period, and pars2.H is the half-width in the exchanged
%   computational non-periodic direction, namely the physical x half-width.
%
%   Derivatives are returned in physical coordinates.  For y-periodicity the
%   computed derivatives are remapped as
%     grad_phys = [G_{x_phys}; G_{y_phys}]
%               = [G_{y_comp}; G_{x_comp}],
%   and
%     hess_phys = [G_{x_phys x_phys}; G_{x_phys y_phys}; G_{y_phys y_phys}]
%               = [G_{y_comp y_comp}; G_{x_comp y_comp}; G_{x_comp x_comp}].

  periodic_axis = LOCAL_parse_periodic_axis(pars1, varargin{:});

  if strcmp(periodic_axis, 'x')
    u = LOCAL_qpgreen_mfs_xperiodic(src, trg, pars1, pars2);
    return;
  end

  src_comp = src([2 1], :);
  trg_comp = trg([2 1], :);
  u = LOCAL_qpgreen_mfs_xperiodic(src_comp, trg_comp, pars1, pars2);
  u = LOCAL_remap_yperiodic_output(u);

end

function u = LOCAL_qpgreen_mfs_xperiodic(src, trg, pars1, pars2)

  d = pars1.d;        % Period in the computational first coordinate
  beta = pars1.beta;  % Bloch wavevector in the computational first coordinate
  k = pars1.k;        % Free space wavenumber

  q = pars2.q;        % Proxy source strengths
  Z = pars2.Z;        % Proxy source locations as a 2-by-N_proxy array
  H = pars2.H;        % Height of the fundamental domain
  C_up = pars2.C_up;      % Plane wave coefficients for top boundary
  C_down = pars2.C_down;  % Plane wave coefficients for bottom boundary

  nt = size(trg, 2);
  
  % Preallocate outputs
  u.pot  = zeros(1, nt);
  u.grad = zeros(2, nt);
  u.hess = zeros(3, nt);

  % Relative coordinates
  X = trg(1, :) - src(1, :);
  Y = trg(2, :) - src(2, :);

  % 1. Fold X into the central fundamental domain [-d/2, d/2]
  % round(X/d) finds the nearest integer shift.
  m_shift = round(X / d);
  X0 = X - m_shift * d;
  
  % Bloch phase shift corresponding to the translation
  phase_shift = exp(1i * beta * m_shift * d);

  % 2. Identify the evaluation regions based on Y
  idx_in = abs(Y) <= H;
  idx_up = Y > H;
  idx_dn = Y < -H;

  % =========================================================================
  % REGION A: Inside the proxy box (|Y| <= H)
  % Field = Primary Source + Proxy Sources
  % =========================================================================
  if any(idx_in)
    T_in = [X0(idx_in); Y(idx_in)];
    
    % Primary source located at (0,0) in the relative coordinate system
    [pot0, grad0, hess0] = kernel.h2d_directch(k, [0; 0], 1, T_in);
    
    % Proxy sources
    [potP, gradP, hessP] = kernel.h2d_directch(k, Z, q, T_in);
    
    % Sum primary and proxy fields, then apply the Bloch phase
    u.pot(idx_in)      = (pot0 + potP) .* phase_shift(idx_in);
    u.grad(1, idx_in)  = (grad0(1, :) + gradP(1, :)) .* phase_shift(idx_in);
    u.grad(2, idx_in)  = (grad0(2, :) + gradP(2, :)) .* phase_shift(idx_in);
    u.hess(1, idx_in)  = (hess0(1, :) + hessP(1, :)) .* phase_shift(idx_in);
    u.hess(2, idx_in)  = (hess0(2, :) + hessP(2, :)) .* phase_shift(idx_in);
    u.hess(3, idx_in)  = (hess0(3, :) + hessP(3, :)) .* phase_shift(idx_in);
  end

  % =========================================================================
  % PREPARE PLANE WAVES (If any target points are outside the box)
  % =========================================================================
  if any(idx_up) || any(idx_dn)
    N_pw_total = length(C_up);
    M_pw = (N_pw_total - 1) / 2;
    m_vec = (-M_pw : M_pw).';
    
    beta_m = beta + m_vec * (2 * pi / d);
    
    % Define vertical wavenumber gamma_m with the outgoing/decaying branch.
    % For real k this keeps propagating modes on the positive real branch
    % and evanescent modes on the positive imaginary branch.  For complex k
    % it avoids invalid complex comparisons such as k^2 - beta_m^2 >= 0.
    gamma_m = sqrt(k^2 - beta_m.^2);
    flip = imag(gamma_m) < 0;
    gamma_m(flip) = -gamma_m(flip);

    % =======================================================================
    % REGION B: Top Region (Y > H) -> Upward Plane Waves
    % =======================================================================
    if any(idx_up)
      X_up = X0(idx_up);
      Y_up = Y(idx_up);
      
      % Evaluate basis: exp(i*beta_m*X) * exp(i*gamma_m*(Y - H))
      % phase_X is (N_pw x nt_up), phase_Y is (N_pw x nt_up)
      phase_X = exp(1i * beta_m * X_up); 
      phase_Y = exp(1i * gamma_m * (Y_up - H));
      basis = phase_X .* phase_Y;
      
      % Implicit expansion to multiply coefficients and sum over m
      u.pot(idx_up)      = sum(C_up .* basis, 1) .* phase_shift(idx_up);
      u.grad(1, idx_up)  = sum(C_up .* basis .* (1i * beta_m), 1) .* phase_shift(idx_up);
      u.grad(2, idx_up)  = sum(C_up .* basis .* (1i * gamma_m), 1) .* phase_shift(idx_up);
      u.hess(1, idx_up)  = sum(C_up .* basis .* (-beta_m.^2), 1) .* phase_shift(idx_up);
      u.hess(2, idx_up)  = sum(C_up .* basis .* (-beta_m .* gamma_m), 1) .* phase_shift(idx_up);
      u.hess(3, idx_up)  = sum(C_up .* basis .* (-gamma_m.^2), 1) .* phase_shift(idx_up);
    end

    % =======================================================================
    % REGION C: Bottom Region (Y < -H) -> Downward Plane Waves
    % =======================================================================
    if any(idx_dn)
      X_dn = X0(idx_dn);
      Y_dn = Y(idx_dn);
      
      % Evaluate basis: exp(i*beta_m*X) * exp(-i*gamma_m*(Y + H))
      phase_X = exp(1i * beta_m * X_dn);
      phase_Y = exp(-1i * gamma_m * (Y_dn + H));
      basis = phase_X .* phase_Y;
      
      % Apply derivations taking care of the -1i*gamma_m for Y-derivatives
      u.pot(idx_dn)      = sum(C_down .* basis, 1) .* phase_shift(idx_dn);
      u.grad(1, idx_dn)  = sum(C_down .* basis .* (1i * beta_m), 1) .* phase_shift(idx_dn);
      u.grad(2, idx_dn)  = sum(C_down .* basis .* (-1i * gamma_m), 1) .* phase_shift(idx_dn);
      u.hess(1, idx_dn)  = sum(C_down .* basis .* (-beta_m.^2), 1) .* phase_shift(idx_dn);
      u.hess(2, idx_dn)  = sum(C_down .* basis .* (beta_m .* gamma_m), 1) .* phase_shift(idx_dn);
      u.hess(3, idx_dn)  = sum(C_down .* basis .* (-gamma_m.^2), 1) .* phase_shift(idx_dn);
    end
  end

end

function periodic_axis = LOCAL_parse_periodic_axis(pars1, varargin)

  periodic_axis = 'x';
  if isfield(pars1, 'periodic_axis') && ~isempty(pars1.periodic_axis)
    periodic_axis = LOCAL_normalize_periodic_axis(pars1.periodic_axis);
  end

  if numel(varargin) > 1
    error('kernel:qpgreen_mfs:InvalidPeriodicAxis', ...
      'Pass at most one periodic axis override.');
  end

  if numel(varargin) == 1
    periodic_axis = LOCAL_normalize_periodic_axis(varargin{1});
  end

end

function periodic_axis = LOCAL_normalize_periodic_axis(periodic_axis)

  if isstring(periodic_axis)
    if ~isscalar(periodic_axis)
      error('kernel:qpgreen_mfs:InvalidPeriodicAxis', ...
        'periodic_axis must be either ''x'' or ''y''.');
    end
    periodic_axis = char(periodic_axis);
  elseif ~ischar(periodic_axis)
    error('kernel:qpgreen_mfs:InvalidPeriodicAxis', ...
      'periodic_axis must be either ''x'' or ''y''.');
  end

  periodic_axis = lower(strtrim(periodic_axis));
  if ~strcmp(periodic_axis, 'x') && ~strcmp(periodic_axis, 'y')
    error('kernel:qpgreen_mfs:InvalidPeriodicAxis', ...
      'periodic_axis must be either ''x'' or ''y''.');
  end

end

function u = LOCAL_remap_yperiodic_output(u)

  if isfield(u, 'grad') && size(u.grad, 1) >= 2
    u.grad = u.grad([2 1], :);
  end

  if isfield(u, 'hess') && size(u.hess, 1) >= 3
    u.hess = u.hess([3 2 1], :);
  end

end
