function channels = LOCAL_anchored_rayleigh_channels( ...
    k, beta, d, M, L, branch_gamma, branch_fingerprint)
% LOCAL_ANCHORED_RAYLEIGH_CHANNELS Build channels from frozen branch values.
%
% Purpose:
%   Construct the Rayleigh channel record used by every I4 port consumer
%   without recomputing a pointwise square root.
%
% Input:
%   k, beta, d, M, L - Frozen physical and truncation parameters.
%   branch_gamma - Anchored gamma values in native order m=-M:M.
%   branch_fingerprint - Stable identifier for the common branch provider.
%
% Output:
%   channels - Package-compatible channel struct with the anchored values.
%
% Based on:
%   +bloch/rayleigh_channels.m and eig-apost-i4-readiness-v1.0.
%
% Main changes:
%   The square root and pointwise sign correction are removed. The caller
%   must supply the already continued branch values.
%
% Numerical goal:
%   Prevent hidden branch recreation in incident, far-field, and phase data.

  if ~(isscalar(M) && isfinite(M) && M >= 0 && M == floor(M))
    error('analytic_readiness:InvalidRayleighOrder', ...
      'M must be a nonnegative integer scalar.');
  end
  if ~(isscalar(k) && isnumeric(k) && isfinite(k))
    error('analytic_readiness:InvalidWavenumber', ...
      'k must be a finite numeric scalar.');
  end
  if ~(isscalar(beta) && isfinite(beta) && isscalar(d) && ...
      isfinite(d) && d ~= 0 && isscalar(L) && isfinite(L) && L ~= 0)
    error('analytic_readiness:InvalidChannelParameters', ...
      'beta, d, and L must be finite, with d and L nonzero.');
  end

  branch_orders = (-M:M).';
  branch_beta_m = beta + 2 * pi * branch_orders / d;
  branch_gamma = branch_gamma(:);
  if length(branch_gamma) ~= 2 * M + 1 || any(~isfinite(branch_gamma))
    error('analytic_readiness:InvalidAnchoredBranch', ...
      'branch_gamma must contain 2*M+1 finite native-order values.');
  end
  if isempty(branch_fingerprint)
    error('analytic_readiness:MissingBranchFingerprint', ...
      'A nonempty branch_fingerprint is required.');
  end

  channels.k = k;
  channels.beta = beta;
  channels.d = d;
  channels.L = L;
  channels.M = M;
  channels.K = 2 * M + 1;
  channels.m = branch_orders;
  channels.beta_m = branch_beta_m;
  channels.gamma_m = branch_gamma;
  channels.phase = exp(1i * branch_gamma * L);
  channels.branch_fingerprint = branch_fingerprint;
  channels.branch_source = 'SOURCE_DERIVED_BRANCH_INJECTED_TEST_EVALUATOR';
end
