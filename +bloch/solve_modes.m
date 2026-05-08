function modes = solve_modes(S_cell, opts)
% Purpose:
%   Solve the generalized eigenvalue problem for all Bloch modes of one
%   cell from an already constructed Rayleigh scattering matrix.  This
%   function outputs all finite cell Bloch modes.  It does not select
%   outgoing modes for a left or right lead, does not compute flux/group
%   velocity, and does not call BIE or scattering construction routines.
%
% Inputs:
%   S_cell:
%     Struct containing the scattering blocks R_L, T_LR, T_RL, R_R and
%     channels.gamma_m.  The scattering matrix convention is
%
%       [ b^L ]   [ R_L   T_RL ] [ a^L ]
%       [ a^R ] = [ T_LR  R_R  ] [ b^R ].
%
%   opts:
%     Optional struct.  Supported fields are lambda_tol and normalize.
%     Defaults are lambda_tol = 1e-8 and normalize = 'V'.
%
% Outputs:
%   modes:
%     Struct containing all retained finite multipliers, eigenvectors,
%     wall amplitudes, trace coefficients, generalized eigenproblem
%     matrices, preliminary classification indices, and copied channel data.
%     Its fields are:
%
%       modes.lambda:
%         nb-by-1 retained finite Floquet multipliers.
%       modes.V:
%         2K-by-nb retained generalized eigenvectors, ordered by columns as
%         [a_L; b_L] and normalized according to opts.normalize.
%       modes.a_L:
%         K-by-nb right-going Rayleigh amplitudes at the left wall.
%       modes.b_L:
%         K-by-nb left-going Rayleigh amplitudes at the left wall.
%       modes.a_R:
%         K-by-nb right-going Rayleigh amplitudes at the right wall,
%         computed as lambda .* a_L.
%       modes.b_R:
%         K-by-nb left-going Rayleigh amplitudes at the right wall,
%         computed as lambda .* b_L.
%       modes.D_L:
%         K-by-nb Dirichlet trace coefficients at the left wall.
%       modes.Dx_L:
%         K-by-nb x-derivative trace coefficients at the left wall.
%       modes.D_R:
%         K-by-nb Dirichlet trace coefficients at the right wall.
%       modes.Dx_R:
%         K-by-nb x-derivative trace coefficients at the right wall.
%       modes.A_sc:
%         2K-by-2K left matrix in A_sc*v = lambda*B_sc*v.
%       modes.B_sc:
%         2K-by-2K right matrix in A_sc*v = lambda*B_sc*v.
%       modes.idx:
%         Struct of preliminary logical classifications for retained modes:
%         finite, right_decay, left_decay, and neutral.
%       modes.channels:
%         Copy of S_cell.channels.
%       modes.K:
%         Number of Rayleigh channels.
%       modes.raw_lambda:
%         Raw eigenvalues returned by eig(A_sc,B_sc), before filtering.
%       modes.raw_V:
%         Raw generalized eigenvectors returned by eig(A_sc,B_sc), before
%         filtering.
%       modes.raw_keep:
%         Logical vector marking which raw eigenpairs survived finite and
%         nonzero-vector filtering.
%       modes.opts:
%         Options struct actually used by this routine after defaults.
%
% Notes:
%   The Bloch condition is
%
%     a^R = lambda a^L,
%     b^R = lambda b^L.
%
%   With a = a^L and b = b^L, the generalized eigenvalue problem is
%
%     A_sc [a; b] = lambda B_sc [a; b],
%
%   where
%
%     A_sc = [ -R_L    I
%               T_LR   0 ],
%
%     B_sc = [  0      T_RL
%               I     -R_R ].
%
%   Trace coefficients are computed from gamma_m = channels.gamma_m(:):
%
%     D_L  = a_L + b_L,
%     Dx_L = 1i * gamma_m .* (a_L - b_L),
%     a_R  = lambda .* a_L,
%     b_R  = lambda .* b_L,
%     D_R  = a_R + b_R,
%     Dx_R = 1i * gamma_m .* (a_R - b_R).
%
%   The |lambda|-based right_decay/left_decay/neutral flags are only a
%   preliminary classification relative to the positive x-direction cell
%   multiplier.  They are not final lead outgoing-mode selection.

  if nargin < 2 || isempty(opts)
    opts = struct();
  end
  if ~isfield(opts, 'lambda_tol') || isempty(opts.lambda_tol)
    opts.lambda_tol = 1e-8;
  end
  if ~isfield(opts, 'normalize') || isempty(opts.normalize)
    opts.normalize = 'V';
  end
  if ~(isscalar(opts.lambda_tol) && isfinite(opts.lambda_tol) && opts.lambda_tol >= 0)
    error('solve_modes:InvalidLambdaTol', ...
      'opts.lambda_tol must be a nonnegative finite scalar.');
  end
  if ~(ischar(opts.normalize) && ...
      (strcmp(opts.normalize, 'V') || strcmp(opts.normalize, 'trace_L')))
    error('solve_modes:InvalidNormalizeOption', ...
      'opts.normalize must be either ''V'' or ''trace_L''.');
  end

  required_blocks = {'R_L', 'T_LR', 'T_RL', 'R_R'};
  for j = 1:length(required_blocks)
    if ~isstruct(S_cell) || ~isfield(S_cell, required_blocks{j})
      error('solve_modes:MissingScatteringBlock', ...
        'S_cell must contain R_L, T_LR, T_RL, and R_R.');
    end
  end
  if ~(isfield(S_cell, 'channels') && isfield(S_cell.channels, 'gamma_m'))
    error('solve_modes:MissingChannels', ...
      'S_cell.channels.gamma_m is required.');
  end

  R_L = full(complex(S_cell.R_L));
  T_LR = full(complex(S_cell.T_LR));
  T_RL = full(complex(S_cell.T_RL));
  R_R = full(complex(S_cell.R_R));

  K = size(R_L, 1);
  block_sizes_ok = size(R_L, 2) == K && isequal(size(T_LR), [K, K]) && ...
    isequal(size(T_RL), [K, K]) && isequal(size(R_R), [K, K]);
  if ~block_sizes_ok
    error('solve_modes:InvalidBlockSize', ...
      'R_L, T_LR, T_RL, and R_R must be square K-by-K blocks of the same size.');
  end
  if isfield(S_cell, 'K') && S_cell.K ~= K
    error('solve_modes:ChannelCountMismatch', ...
      'S_cell.K does not agree with the scattering block size.');
  end

  gamma_m = S_cell.channels.gamma_m(:);
  if length(gamma_m) ~= K
    error('solve_modes:GammaSizeMismatch', ...
      'length(S_cell.channels.gamma_m) must equal K.');
  end
  if any(~isfinite(gamma_m))
    error('solve_modes:InvalidGamma', ...
      'S_cell.channels.gamma_m must contain only finite values.');
  end

  A_sc = full(complex([-R_L, eye(K); T_LR, zeros(K)]));
  B_sc = full(complex([zeros(K), T_RL; eye(K), -R_R]));

  [raw_V, raw_Lam] = eig(A_sc, B_sc);
  raw_lambda = diag(raw_Lam);
  raw_V = full(complex(raw_V));
  raw_lambda = raw_lambda(:);

  finite_lambda = isfinite(raw_lambda);
  finite_vectors = all(isfinite(raw_V), 1).';
  raw_norms = LOCAL_column_norms(raw_V);
  nonzero_vectors = isfinite(raw_norms) & raw_norms > 0;
  keep = finite_lambda & finite_vectors & nonzero_vectors;

  lambda = raw_lambda(keep);
  V = raw_V(:, keep);
  if isempty(lambda)
    modes = LOCAL_empty_modes(K, S_cell, A_sc, B_sc, raw_lambda, raw_V, keep, opts);
    return;
  end

  if strcmp(opts.normalize, 'V')
    scale = LOCAL_column_norms(V).';
    keep_norm = isfinite(scale) & scale > 0;
    lambda = lambda(keep_norm);
    V = V(:, keep_norm);
    scale = scale(keep_norm);
    V = bsxfun(@rdivide, V, scale);
  end

  [a_L, b_L, a_R, b_R, D_L, Dx_L, D_R, Dx_R] = ...
    LOCAL_amplitudes_and_traces(V, lambda, gamma_m, K);

  if strcmp(opts.normalize, 'trace_L')
    trace_scale = LOCAL_column_norms([D_L; Dx_L]).';
    keep_trace = isfinite(trace_scale) & trace_scale > 0;
    lambda = lambda(keep_trace);
    V = V(:, keep_trace);
    a_L = a_L(:, keep_trace);
    b_L = b_L(:, keep_trace);
    a_R = a_R(:, keep_trace);
    b_R = b_R(:, keep_trace);
    D_L = D_L(:, keep_trace);
    Dx_L = Dx_L(:, keep_trace);
    D_R = D_R(:, keep_trace);
    Dx_R = Dx_R(:, keep_trace);
    trace_scale = trace_scale(keep_trace);

    V = bsxfun(@rdivide, V, trace_scale);
    a_L = bsxfun(@rdivide, a_L, trace_scale);
    b_L = bsxfun(@rdivide, b_L, trace_scale);
    a_R = bsxfun(@rdivide, a_R, trace_scale);
    b_R = bsxfun(@rdivide, b_R, trace_scale);
    D_L = bsxfun(@rdivide, D_L, trace_scale);
    Dx_L = bsxfun(@rdivide, Dx_L, trace_scale);
    D_R = bsxfun(@rdivide, D_R, trace_scale);
    Dx_R = bsxfun(@rdivide, Dx_R, trace_scale);
  end

  abs_lambda = abs(lambda);
  idx.finite = true(size(lambda));
  idx.right_decay = abs_lambda < 1 - opts.lambda_tol;
  idx.left_decay = abs_lambda > 1 + opts.lambda_tol;
  idx.neutral = abs(abs_lambda - 1) <= opts.lambda_tol;

  modes.lambda = lambda;
  modes.V = V;
  modes.a_L = a_L;
  modes.b_L = b_L;
  modes.a_R = a_R;
  modes.b_R = b_R;
  modes.D_L = D_L;
  modes.Dx_L = Dx_L;
  modes.D_R = D_R;
  modes.Dx_R = Dx_R;
  modes.A_sc = A_sc;
  modes.B_sc = B_sc;
  modes.idx = idx;
  modes.channels = S_cell.channels;
  modes.K = K;
  modes.raw_lambda = raw_lambda;
  modes.raw_V = raw_V;
  modes.raw_keep = keep;
  modes.opts = opts;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [a_L, b_L, a_R, b_R, D_L, Dx_L, D_R, Dx_R] = ...
    LOCAL_amplitudes_and_traces(V, lambda, gamma_m, K)

  a_L = V(1:K, :);
  b_L = V(K + 1:2 * K, :);
  a_R = bsxfun(@times, a_L, lambda.');
  b_R = bsxfun(@times, b_L, lambda.');

  D_L = a_L + b_L;
  Dx_L = 1i * bsxfun(@times, gamma_m, a_L - b_L);
  D_R = a_R + b_R;
  Dx_R = 1i * bsxfun(@times, gamma_m, a_R - b_R);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function norms = LOCAL_column_norms(A)

  norms = zeros(size(A, 2), 1);
  for j = 1:size(A, 2)
    norms(j) = norm(A(:, j), 2);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function modes = LOCAL_empty_modes(K, S_cell, A_sc, B_sc, raw_lambda, raw_V, keep, opts)

  modes.lambda = zeros(0, 1);
  modes.V = zeros(2 * K, 0);
  modes.a_L = zeros(K, 0);
  modes.b_L = zeros(K, 0);
  modes.a_R = zeros(K, 0);
  modes.b_R = zeros(K, 0);
  modes.D_L = zeros(K, 0);
  modes.Dx_L = zeros(K, 0);
  modes.D_R = zeros(K, 0);
  modes.Dx_R = zeros(K, 0);
  modes.A_sc = A_sc;
  modes.B_sc = B_sc;
  modes.idx.finite = false(0, 1);
  modes.idx.right_decay = false(0, 1);
  modes.idx.left_decay = false(0, 1);
  modes.idx.neutral = false(0, 1);
  modes.channels = S_cell.channels;
  modes.K = K;
  modes.raw_lambda = raw_lambda;
  modes.raw_V = raw_V;
  modes.raw_keep = keep;
  modes.opts = opts;

end
