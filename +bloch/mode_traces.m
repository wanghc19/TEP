function traces = mode_traces(lambda, V, rayleighchan)
% Purpose:
%   Compute Dirichlet and x-derivative trace coefficients on the left and
%   right walls of one cell from Bloch generalized eigenvectors.  This is a
%   pure linear algebra post-processing routine.  It does not call BIE, does
%   not construct A_QP or a scattering matrix, does not solve an eigenvalue
%   problem, and does not select outgoing modes.
%
% Inputs:
%   lambda:
%     nb-by-1 vector of Floquet multipliers.  It is converted to a column
%     vector internally.
%   V:
%     2K-by-nb generalized eigenvector matrix.  Each column is ordered as
%     V(:,j) = [a_L(:,j); b_L(:,j)], where a_L are right-going Rayleigh
%     amplitudes at the cell left wall and b_L are left-going Rayleigh
%     amplitudes at the cell left wall.
%   rayleighchan:
%     Struct returned by bloch.rayleigh_channels.  It must contain K and
%     gamma_m.
%
% Outputs:
%   traces:
%     Struct with fields lambda, a_L, b_L, a_R, b_R, D_L, N_L, D_R, N_R,
%     K, and channels.
%
% Notes:
%   L/R denotes the cell left/right wall, not positive/negative half-axis
%   leads.  This function uses N_L and N_R for x-derivative trace
%   coefficients, not outward normal derivatives for a semi-infinite lead.
%
%   For the j-th Bloch mode,
%
%     V(:,j) = [a_L(:,j); b_L(:,j)].
%
%   The left-wall Dirichlet trace is
%
%     u_j(X_L,y) = sum_m D_L(m,j) psi_m(y),
%     D_L(m,j) = a_L(m,j) + b_L(m,j).
%
%   The left-wall x-derivative trace is
%
%     partial_x u_j(X_L,y) = sum_m N_L(m,j) psi_m(y),
%     N_L(m,j) = 1i*gamma_m(m)*(a_L(m,j) - b_L(m,j)).
%
%   The right-wall amplitudes are given by the Bloch condition:
%
%     a_R(m,j) = lambda(j)*a_L(m,j),
%     b_R(m,j) = lambda(j)*b_L(m,j).
%
%   The right-wall Dirichlet trace is
%
%     u_j(X_R,y) = sum_m D_R(m,j) psi_m(y),
%     D_R(m,j) = a_R(m,j) + b_R(m,j).
%
%   The right-wall x-derivative trace is
%
%     partial_x u_j(X_R,y) = sum_m N_R(m,j) psi_m(y),
%     N_R(m,j) = 1i*gamma_m(m)*(a_R(m,j) - b_R(m,j)).
%
%   If these traces are later used for a right half-axis lead, the outward
%   normal is +e_x, so the normal derivative equals the x-derivative trace
%   at the chosen wall.  If they are used for a left half-axis lead, an
%   outward normal convention may introduce a minus sign.  Do not handle that
%   sign here.

  if ~(isstruct(rayleighchan) && isfield(rayleighchan, 'K') && ...
      isfield(rayleighchan, 'gamma_m'))
    error('mode_traces:InvalidRayleighChannels', ...
      'rayleighchan must contain K and gamma_m.');
  end
  if ~(isvector(lambda) && isnumeric(lambda))
    error('mode_traces:InvalidLambda', ...
      'lambda must be a numeric vector.');
  end
  if ~(ismatrix(V) && isnumeric(V))
    error('mode_traces:InvalidEigenvectors', ...
      'V must be a numeric 2K-by-nb matrix.');
  end
  if ~(isscalar(rayleighchan.K) && isfinite(rayleighchan.K) && ...
      rayleighchan.K >= 0 && rayleighchan.K == floor(rayleighchan.K))
    error('mode_traces:InvalidChannelCount', ...
      'rayleighchan.K must be a nonnegative integer scalar.');
  end

  K = rayleighchan.K;
  lambda = lambda(:);
  gamma_m = rayleighchan.gamma_m(:);
  nb = length(lambda);

  if length(gamma_m) ~= K
    error('mode_traces:GammaSizeMismatch', ...
      'length(rayleighchan.gamma_m) must equal rayleighchan.K.');
  end
  if size(V, 1) ~= 2 * K
    error('mode_traces:EigenvectorRowMismatch', ...
      'V must have 2K rows.');
  end
  if size(V, 2) ~= nb
    error('mode_traces:ModeCountMismatch', ...
      'length(lambda) must equal size(V,2).');
  end

  V = full(complex(V));
  lambda = full(complex(lambda));
  gamma_m = full(complex(gamma_m));

  a_L = V(1:K, :);
  b_L = V(K + 1:2 * K, :);
  a_R = bsxfun(@times, a_L, lambda.');
  b_R = bsxfun(@times, b_L, lambda.');

  D_L = a_L + b_L;
  N_L = 1i * bsxfun(@times, gamma_m, a_L - b_L);
  D_R = a_R + b_R;
  N_R = 1i * bsxfun(@times, gamma_m, a_R - b_R);

  traces.lambda = lambda;
  traces.a_L = full(complex(a_L));
  traces.b_L = full(complex(b_L));
  traces.a_R = full(complex(a_R));
  traces.b_R = full(complex(b_R));
  traces.D_L = full(complex(D_L));
  traces.N_L = full(complex(N_L));
  traces.D_R = full(complex(D_R));
  traces.N_R = full(complex(N_R));
  traces.K = K;
  traces.channels = rayleighchan;

end
