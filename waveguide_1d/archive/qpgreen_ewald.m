function [u, grad] = qpgreen_ewald(src, trg, pars1, pars2)
% QPGREEN Evaluates the Quasi-Periodic Green's function using Ewald Summation.
% (Optimized Vectorized Version)
%
% Inputs:
%   src: source point (2 x 1)
%   trg: target point (2 x 1)
%   pars1.k: wavenumber
%   pars1.beta: Bloch wavenumber
%   pars1.d: periodicity length
%   pars2.a, M1, M2, N: parameters for Ewald summation
% Outputs:
%   u: value of the Green's function
%   grad: gradient of the Green's function (w.r.t. trg)

    k = pars1.k;
    beta = pars1.beta;
    d = pars1.d;
    
    a = pars2.a;
    M1 = pars2.M1;
    M2 = pars2.M2;
    N = pars2.N;
    
    x = trg(1) - src(1);
    y = trg(2) - src(2);
    p = 2*pi/d;
    
    % --- Precomputations for Spectral Sum (-M1 to M1) ---
    % Vectorized generation of beta_m and gamma_m
    m_vec_spec = -M1:M1;
    betam  = beta + m_vec_spec * p;
    gammam = zeros(size(betam)); 
    diff_sq  = betam.^2 - k^2;
    
    idx_eva  = diff_sq >= 0; % Evanescent modes
    idx_prop = diff_sq <  0; % Propagating modes
    
    gammam(idx_eva)  = sqrt(diff_sq(idx_eva));
    gammam(idx_prop) = -1i*sqrt(-diff_sq(idx_prop));
    
    % --- Precomputations for Spatial Sum (-M2 to M2) ---
    m_vec_spatial = -M2:M2;
    % Vector containing distance to all image sources
    x_dist_vec = x - m_vec_spatial*d;
    rm_vec = sqrt(x_dist_vec.^2 + y^2);
    
    % Initialize outputs
    u = 0;
    grad = [0; 0];
    
    % =====================================================================
    % 1. Spectral Summation (Vectorized)
    % =====================================================================
    % No loop over m. Compute all terms simultaneously.
    
    gm = gammam; % Vector (1 x 2*M1+1)
    bm = betam;  % Vector
    
    % Compute arguments for erfc
    arg1 = gm * (d / (2*a)) + (a * y / d);
    arg2 = gm * (d / (2*a)) - (a * y / d);
    
    % Vectorized erfc calls
    erfc1 = LOCAL_erfc(arg1);
    erfc2 = LOCAL_erfc(arg2);
    
    exp_gy = exp(gm * y);
    exp_neg_gy = 1 ./ exp_gy; % Faster than exp(-gm*y)
    
    temp1 = exp_gy .* erfc1;
    temp2 = exp_neg_gy .* erfc2;
    
    sum_temp = temp1 + temp2;
    diff_temp = temp1 - temp2;
    
    phase_spec = exp(1i * bm * x);
    inv_gm_d = 1 ./ (gm * d);
    
    % Accumulate results using dot products or sum
    % u term: 1/4 * phase / (gm*d) * (temp1 + temp2)
    u = u + 0.25 * sum(phase_spec .* inv_gm_d .* sum_temp);
    
    % grad(1) term: 1/4 * i*bm * phase / (gm*d) * (temp1 + temp2)
    grad(1) = grad(1) + 0.25 * sum(1i * bm .* phase_spec .* inv_gm_d .* sum_temp);
    
    % grad(2) term: 1/4 * phase / d * (temp1 - temp2)
    % Note: gm cancels out in the derivative w.r.t y
    grad(2) = grad(2) + 0.25 * sum((phase_spec / d) .* diff_temp);
    
    
    % =====================================================================
    % 2. Spatial Summation (Vectorized Recurrence)
    % =====================================================================
    % We compute contributions for all 'm' simultaneously.
    % We iterate 'n' to update ExpIntegral terms efficiently.
    
    % Precompute argument z for all m: z = (rm * a / d)^2
    z_vec = (rm_vec * a / d).^2;
    exp_neg_z = exp(-z_vec);
    
    % Initialize E_n (E0) and E_{n+1} (E1) for the first step (n=0)
    % E_0(z) = exp(-z) / z
    % E_1(z) = expint(z)
    En_curr = exp_neg_z ./ z_vec;  % Vector corresponding to all m
    En_next = expint(z_vec);       % Vector
    
    % Initialize accumulators for spatial sum
    usummand_vec = zeros(size(m_vec_spatial));
    gsummand_vec_x = zeros(size(m_vec_spatial));
    gsummand_vec_y = zeros(size(m_vec_spatial));
    
    % Constant geometric factors for gradient
    % grad ~ -2*a^2/d^2 * dist * temp * En
    geom_factor = -2 * (a/d)^2;
    
    % Loop over Taylor orders n
    for n = 0:N
        % temp = 1/n! * (k*d/2a)^(2n)
        % Note: factorial(n) can grow large, but term is usually manageable.
        % For extreme efficiency, one could update 'temp' iteratively too,
        % but direct calculation is safe here for small N.
        temp = 1/factorial(n) * (k*d/(2*a))^(2*n);
        
        % Update Accumulators (Vectorized over m)
        % Gradient uses En_curr (which is E_n)
        gsummand_vec_x = gsummand_vec_x + (geom_factor * x_dist_vec) .* temp .* En_curr;
        gsummand_vec_y = gsummand_vec_y + (geom_factor * y)          .* temp .* En_curr;
        
        % Potential uses En_next (which is E_{n+1})
        usummand_vec = usummand_vec + temp * En_next;
        
        % Recurrence Update for next n
        % We need E_{n+2} for the next step of potential, and E_{n+1} for gradient
        % Formula: E_{k+1}(z) = (exp(-z) - z * E_k(z)) / k
        % Here we are going from n+1 to n+2.
        if n < N
            % Shift: Current becomes old Next
            En_curr = En_next;
            
            % Compute new Next: E_{n+2} = (exp(-z) - z * E_{n+1}) / (n+1)
            % Divisor is k = n + 1
            En_next = (exp_neg_z - z_vec .* En_curr) / (n + 1);
        end
    end
    
    % Apply phases and sum over spatial images m
    phase_spatial = exp(1i * beta * m_vec_spatial * d);
    const_spatial = 1 / (4 * pi);
    
    u = u + const_spatial * sum(phase_spatial .* usummand_vec);
    grad(1) = grad(1) + const_spatial * sum(phase_spatial .* gsummand_vec_x);
    grad(2) = grad(2) + const_spatial * sum(phase_spatial .* gsummand_vec_y);
    
end

%  =========================================================================
%  LOCAL HELPER FUNCTIONS
%  =========================================================================

function val = LOCAL_erfc(z)
% LOCAL_ERFC Wrapper for the Faddeeva_erfc function.
% Supports complex vectors.
    val = Faddeeva_erfc(z);
end