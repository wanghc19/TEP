function u = qpgreen_mfs(src, trg, pars1, pars2)
% QPGREEN_MFS Evaluate the quasi-periodic Green function by augmented MFS.
%
% Purpose:
%   Evaluates the quasi-periodic Green's function, gradient, and Hessian
%   using proxy sources inside the proxy box and plane-wave expansions above
%   and below it.
%
% Input:
%   src   - Source coordinate as a 2-by-1 vector.
%   trg   - Target coordinates as a 2-by-nt array.
%   pars1 - Physical parameter struct with fields d, beta, and k.
%   pars2 - Proxy/plane-wave coefficient struct with fields q, Z, H,
%           C_up, and C_down.
%
% Output:
%   u - Struct with fields pot (1-by-nt), grad (2-by-nt), and hess
%       (3-by-nt) at the target points.
%
% Notes:
%   This package version calls kernel.h2d_directch for free-space Helmholtz
%   evaluations instead of keeping a duplicated local kernel helper.

  d = pars1.d;        % Periodicity along x
  beta = pars1.beta;  % Bloch wavevector
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
    
    % Define vertical wavenumber gamma_m (branch cut tracking)
    diff_sq = k^2 - beta_m.^2;
    gamma_m = zeros(size(beta_m));
    mask_prop = diff_sq >= 0;
    mask_eva  = diff_sq < 0;
    
    gamma_m(mask_prop) = sqrt(diff_sq(mask_prop));
    gamma_m(mask_eva)  = 1i * sqrt(-diff_sq(mask_eva)); % Positive imaginary

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
