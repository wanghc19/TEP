function weights = i32v2_lift_mode_weights(kind, N, Ng, cert)
%I32V2_LIFT_MODE_WEIGHTS Return frozen cubic-lift volume-source weights.
% Purpose:
%   Provide one audited implementation of the wall-strip and circle-collar
%   mode weights to boundary-action and lifting modules.
% Input:
%   kind - `wall` or `circle`.
%   N    - even number of retained boundary residual modes.
%   Ng   - preregistered Gauss order.
%   cert - frozen certificate scalar/geometry struct.
% Output:
%   weights - N-by-1 positive row multipliers including gamma^(-1/2).
% Notes:
%   Circle weights include the r/R area Jacobian and rho^(-1/2) source norm.

N = double(N);
Ng = double(Ng);
if ~(isscalar(N) && isfinite(N) && N >= 2.0 && N == fix(N) && ...
    mod(N, 2.0) == 0.0 && isscalar(Ng) && isfinite(Ng) && ...
    Ng >= 1.0 && Ng == fix(Ng))
  error('I32V2:LiftWeightOrder', 'Lift mode and Gauss orders are invalid.');
end
[t, wg] = LOCAL_gauss_legendre(Ng, 0, 1);
chi = 1 - 3 * t.^2 + 2 * t.^3;
chi1 = -6 * t + 6 * t.^2;
chi2 = -6 + 12 * t;
orders = (-N / 2:N / 2 - 1).';

switch char(kind)
  case 'wall'
    alpha = cert.beta + 2 * pi * orders / double(cert.d);
    source = -chi2.' / cert.delta_w^2 + ...
      (alpha.^2 - cert.mu_h) .* chi.';
    weights_squared = cert.delta_w * (abs(source).^2 * wg);
  case 'circle'
    weights_squared = zeros(N, 1);
    r_out = cert.R + cert.delta_c * t;
    h_out = -0.5 * chi;
    h1_out = -0.5 * chi1 / cert.delta_c;
    h2_out = -0.5 * chi2 / cert.delta_c^2;
    for j = 1:Ng
      source = -h2_out(j) - h1_out(j) / r_out(j) + ...
        (orders.^2 / r_out(j)^2 - cert.mu_h) * h_out(j);
      weights_squared = weights_squared + cert.delta_c * wg(j) * ...
        (r_out(j) / cert.R) * abs(source).^2;
    end

    r_in = cert.R - cert.delta_c * t;
    h_in = 0.5 * chi;
    h1_in = -0.5 * chi1 / cert.delta_c;
    h2_in = 0.5 * chi2 / cert.delta_c^2;
    rho = double(cert.rho_disk);
    for j = 1:Ng
      source = -h2_in(j) - h1_in(j) / r_in(j) + ...
        (orders.^2 / r_in(j)^2 - cert.mu_h * rho) * h_in(j);
      weights_squared = weights_squared + cert.delta_c * wg(j) * ...
        (r_in(j) / cert.R) * abs(source).^2 / rho;
    end
  otherwise
    error('I32V2:LiftWeightKind', 'Lift weight kind must be wall or circle.');
end

if ~all(isfinite(weights_squared)) || any(weights_squared < 0) || ...
    ~(isfinite(cert.gamma) && cert.gamma > 0)
  error('I32V2:LiftWeightUnavailable', ...
    'A required lift weight is nonpositive or nonfinite.');
end
weights = sqrt(max(0, weights_squared)) / sqrt(cert.gamma);
end

%% ==================== Gauss--Legendre quadrature ====================
% Golub--Welsch nodes avoid external quadrature dependencies.

function [nodes, weights] = LOCAL_gauss_legendre(N, lower, upper)
indices = (1:N - 1).';
offdiag = indices ./ sqrt(4 * indices.^2 - 1);
J = diag(offdiag, 1) + diag(offdiag, -1);
[vectors, values] = eig(J, 'vector');
[values, order] = sort(values);
vectors = vectors(:, order);
nodes = (upper - lower) * (values + 1) / 2 + lower;
weights = (upper - lower) * vectors(1, :).^2 / 2;
weights = weights(:);
end
