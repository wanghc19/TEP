function proxy = precomp_proxy(pars1,pars2)
% PRECOMP_PROXY Precompute proxy and plane-wave coefficients for MFS.
%
% Purpose:
%   Solves the augmented method-of-fundamental-solutions least-squares
%   system used to represent the quasi-periodic Green's function.
%
% Input:
%   pars1 - Physical parameter struct with fields d, beta, and k.
%   pars2 - Discretization parameter struct with fields H, proxy_dist,
%           N_side, N_top, N_proxy_edge, and M_pw.
%
% Output:
%   proxy - Struct containing proxy source strengths and plane-wave data:
%           q, Z, H, C_up, and C_down.
%
% Notes:
%   This package function preserves the active logic of the former
%   root-level precomp_proxy.m implementation.

% --- 1. Configurable Parameters ---
d = pars1.d;        % Periodicity along x
beta = pars1.beta;  % Bloch wavevector
k = pars1.k;        % Free space wavenumber

H = pars2.H;                        % Height of the fundamental domain[-H, H]
proxy_dist = pars2.proxy_dist;      % Distance of proxy boundary from the domain
N_side = pars2.N_side;              % Number of collocation points on Left/Right walls
N_top = pars2.N_top;                % Number of collocation points on Top/Bottom walls
N_proxy_edge = pars2.N_proxy_edge;  % Number of proxy sources per edge
M_pw = pars2.M_pw;                  % Truncation order for plane waves (-M_pw to M_pw) 

src = [0, 0];

% --- 2. Generate Collocation Points (Domain Boundaries) ---
% Left and Right boundaries: x = -d/2 and x = d/2
y_side = linspace(-H, H, N_side).';
p_L =[-d/2 * ones(N_side, 1), y_side];
p_R =[ d/2 * ones(N_side, 1), y_side];

% Top and Bottom boundaries: y = H and y = -H
x_top = linspace(-d/2, d/2, N_top).';
p_T = [x_top,  H * ones(N_top, 1)];
p_B =[x_top, -H * ones(N_top, 1)];

% --- 3. Generate Proxy Sources (Bounding Box) ---
x_min = -d/2 - proxy_dist; x_max = d/2 + proxy_dist;
y_min = -H - proxy_dist;   y_max = H + proxy_dist;

tx = linspace(x_min, x_max, N_proxy_edge + 1).'; tx(end) =[];
ty = linspace(y_min, y_max, N_proxy_edge + 1).'; ty(end) =[];

% Assemble the proxy bounding box
px =[tx; repmat(x_max, N_proxy_edge, 1); flipud(tx); repmat(x_min, N_proxy_edge, 1)];
py =[repmat(y_min, N_proxy_edge, 1); ty; repmat(y_max, N_proxy_edge, 1); flipud(ty)];
Z_proxy =[px, py];
N_proxy = size(Z_proxy, 1);

% --- 4. Plane Wave Expansion Parameters ---
m_vec = (-M_pw : M_pw).';
N_pw_total = length(m_vec);
beta_m = beta + m_vec * (2 * pi / d);

% Branch cut for gamma_m: must be positive real or positive imaginary
% MATLAB's sqrt(-x) yields +i*sqrt(x) automatically, matching radiation condition.
gamma_m = sqrt(k^2 - beta_m.^2);

% --- 5. Matrix Assembly A * c = b ---
% Unknowns:[c_proxy (N_proxy); C_up (N_pw_total); C_down (N_pw_total)]
N_unknowns = N_proxy + 2 * N_pw_total;
N_eqs = 2 * N_side + 4 * N_top;

A = zeros(N_eqs, N_unknowns);
b = zeros(N_eqs, 1);

% Row indices
idx_LR_v = 1 : N_side;                       % Left-Right Value Match
idx_LR_d = (1 : N_side) + N_side;            % Left-Right X-Derivative Match
idx_T_v  = (1 : N_top) + 2*N_side;           % Top Value Match
idx_T_d  = (1 : N_top) + 2*N_side + N_top;   % Top Y-Derivative Match
idx_B_v  = (1 : N_top) + 2*N_side + 2*N_top; % Bottom Value Match
idx_B_d  = (1 : N_top) + 2*N_side + 3*N_top; % Bottom Y-Derivative Match

% Column indices
col_proxy = 1 : N_proxy;
col_pw_T  = (1 : N_pw_total) + N_proxy;
col_pw_B  = (1 : N_pw_total) + N_proxy + N_pw_total;

phase = exp(1i * beta * d);

% --- Helper inline function for Green's function evaluations ---
% Returns Matrices of size (N_targets x N_sources)
eval_G = @(pt, ps) deal(...
  (1i/4) * besselh(0, 1, k * sqrt((pt(:,1)-ps(:,1).').^2 + (pt(:,2)-ps(:,2).').^2)), ... % Value
  -(1i*k/4) * besselh(1, 1, k * sqrt((pt(:,1)-ps(:,1).').^2 + (pt(:,2)-ps(:,2).').^2)) .* ((pt(:,1)-ps(:,1).') ./ sqrt((pt(:,1)-ps(:,1).').^2 + (pt(:,2)-ps(:,2).').^2)), ... % d/dx
  -(1i*k/4) * besselh(1, 1, k * sqrt((pt(:,1)-ps(:,1).').^2 + (pt(:,2)-ps(:,2).').^2)) .* ((pt(:,2)-ps(:,2).') ./ sqrt((pt(:,1)-ps(:,1).').^2 + (pt(:,2)-ps(:,2).').^2))  ... % d/dy
);

% --- Fill RHS (Primary Source Contributions) ---
[V_sL, dVdx_sL, ~] = eval_G(p_L, src);
[V_sR, dVdx_sR, ~] = eval_G(p_R, src);
b(idx_LR_v) = -(V_sR - phase * V_sL);
b(idx_LR_d) = -(dVdx_sR - phase * dVdx_sL);

[V_sT, ~, dVdy_sT] = eval_G(p_T, src);
b(idx_T_v) = -V_sT;
b(idx_T_d) = -dVdy_sT;

[V_sB, ~, dVdy_sB] = eval_G(p_B, src);
b(idx_B_v) = -V_sB;
b(idx_B_d) = -dVdy_sB;

% --- Fill Matrix A ---
% Block 1: Proxy points -> boundaries
[V_pL, dVdx_pL, ~] = eval_G(p_L, Z_proxy);
[V_pR, dVdx_pR, ~] = eval_G(p_R, Z_proxy);
A(idx_LR_v, col_proxy) = V_pR - phase * V_pL;
A(idx_LR_d, col_proxy) = dVdx_pR - phase * dVdx_pL;

[V_pT, ~, dVdy_pT] = eval_G(p_T, Z_proxy);
A(idx_T_v, col_proxy) = V_pT;
A(idx_T_d, col_proxy) = dVdy_pT;

[V_pB, ~, dVdy_pB] = eval_G(p_B, Z_proxy);
A(idx_B_v, col_proxy) = V_pB;
A(idx_B_d, col_proxy) = dVdy_pB;

% Block 2: Plane waves -> Top boundary
% u_up = C^+ * exp(i*beta_m*x) * exp(i*gamma_m*(y-H))
PW_T_val = exp(1i * p_T(:,1) * beta_m.');
PW_T_der = PW_T_val .* (1i * gamma_m.');
A(idx_T_v, col_pw_T) = -PW_T_val;
A(idx_T_d, col_pw_T) = -PW_T_der;

% Block 3: Plane waves -> Bottom boundary
% u_down = C^- * exp(i*beta_m*x) * exp(-i*gamma_m*(y+H))
PW_B_val = exp(1i * p_B(:,1) * beta_m.');
PW_B_der = PW_B_val .* (-1i * gamma_m.');
A(idx_B_v, col_pw_B) = -PW_B_val;
A(idx_B_d, col_pw_B) = -PW_B_der;

% --- 6. Solve the System ---
% Using backslash for the overdetermined least-squares system
% coeffs = A \ b;
% coeffs = lsqminnorm(A, b); 
if exist('lsqminnorm', 'file')
  coeffs = lsqminnorm(A, b);
else
  coeffs = pinv(A) * b;
end

% --- 7. Extract Proxy Coefficients ---
proxy.q = coeffs(1:N_proxy).';
proxy.Z = Z_proxy.';
proxy.H = H;
proxy.C_up = coeffs(N_proxy+1:N_proxy+N_pw_total);
proxy.C_down = coeffs(N_proxy+N_pw_total+1:end);
end
