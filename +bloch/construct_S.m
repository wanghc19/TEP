function S_cell = construct_S(geom, kext, kint, pars1, proxy, curvelen, rayleighchan, X_L, X_R)
% Purpose:
%   Construct the Rayleigh scattering matrix for one periodic cell by
%   gluing together the existing A_QP assembly, incident right-hand sides,
%   far-field extractors, and one multi-RHS BIE solve.  The exterior
%   wavenumber kext may be denoted omega in the notes; this code uses
%   kext/kint.
%
% Inputs:
%   geom, kext, kint, pars1, proxy, curvelen:
%     Inputs passed through to op.construct_A_QP.
%   rayleighchan:
%     Rayleigh channel struct containing at least K, gamma_m, and phase.
%     The phase vector stores exp(1i*gamma_m*L) for the cell length used
%     when the channels were built.
%   X_L, X_R:
%     x-coordinates of the left and right vertical walls of this cell.
%
% Outputs:
%   S_cell:
%     Struct containing the scattering blocks, the full matrix, and debug
%     data from the BIE solve and far-field extraction.
%
% Notes:
%   L/R denotes the left/right vertical walls of one cell, not positive or
%   negative half-axis leads, and a^* denote right-going, b^* denote left-going.
%   With incoming amplitudes a^L and b^R, and outgoing amplitudes b^L and a^R,
%
%     [ b^L ]   [ R_L   T_RL ] [ a^L ]
%     [ a^R ] = [ T_LR  R_R  ] [ b^R ].
%
%   The BIE systems are
%
%     A_QP * H_L = -B_L,
%     A_QP * H_R = -B_R,
%
%   solved together as
%
%     H_all = -(A_QP \ [B_L, B_R]).
%
%   The far-field extractors map eta = [tau; -sigma] to scattered outgoing
%   coefficients only.  Therefore the direct one-cell phase contribution is
%   added only to the transmission blocks:
%
%     R_L  = F_L * H_L,
%     T_LR = E + F_R * H_L,
%     T_RL = E + F_L * H_R,
%     R_R  = F_R * H_R,
%
%   where E = diag(rayleighchan.phase).

  if ~(isstruct(rayleighchan) && isfield(rayleighchan, 'K') && ...
      isfield(rayleighchan, 'gamma_m') && isfield(rayleighchan, 'phase'))
    error('construct_S:InvalidRayleighChannels', ...
      'rayleighchan must contain K, gamma_m, and phase.');
  end
  if ~(isscalar(X_L) && isfinite(X_L))
    error('construct_S:InvalidLeftWall', ...
      'X_L must be a finite scalar.');
  end
  if ~(isscalar(X_R) && isfinite(X_R))
    error('construct_S:InvalidRightWall', ...
      'X_R must be a finite scalar.');
  end
  if ~(isscalar(rayleighchan.K) && isfinite(rayleighchan.K) && ...
      rayleighchan.K >= 0 && rayleighchan.K == floor(rayleighchan.K))
    error('construct_S:InvalidChannelCount', ...
      'rayleighchan.K must be a nonnegative integer scalar.');
  end

  K = rayleighchan.K;
  phase = rayleighchan.phase(:);
  if length(phase) ~= K
    error('construct_S:PhaseSizeMismatch', ...
      'rayleighchan.phase must be a K-by-1 or 1-by-K vector.');
  end
  if length(rayleighchan.gamma_m(:)) ~= K
    error('construct_S:GammaSizeMismatch', ...
      'rayleighchan.gamma_m must have length rayleighchan.K.');
  end
  if any(~isfinite(phase))
    error('construct_S:InvalidPhase', ...
      'rayleighchan.phase must contain only finite values.');
  end

  L_cell = X_R - X_L;
  if isfield(rayleighchan, 'L') && isfinite(rayleighchan.L)
    L_tol = 1e-10 * max([1, abs(L_cell), abs(rayleighchan.L)]);
    if abs(L_cell - rayleighchan.L) > L_tol
      warning('construct_S:CellLengthMismatch', ...
        'X_R - X_L differs from rayleighchan.L; direct phase may be inconsistent.');
    end
  elseif isfield(rayleighchan, 'L')
    warning('construct_S:InvalidChannelLength', ...
      'rayleighchan.L exists but is not finite; skipping length consistency check.');
  end

  A_QP = full(complex(op.construct_A_QP(geom, kext, kint, pars1, proxy, curvelen)));
  if size(A_QP, 1) ~= size(A_QP, 2)
    error('construct_S:NonSquareMatrix', ...
      'A_QP must be square.');
  end

  [B_L, B_R] = bloch.incident_rhs(geom, rayleighchan, X_L, X_R);
  B_L = full(complex(B_L));
  B_R = full(complex(B_R));
  if size(B_L, 2) ~= K || size(B_R, 2) ~= K
    error('construct_S:IncidentColumnMismatch', ...
      'B_L and B_R must have K columns.');
  end
  if size(A_QP, 1) ~= size(B_L, 1) || size(A_QP, 1) ~= size(B_R, 1)
    error('construct_S:IncidentRowMismatch', ...
      'size(A_QP,1) must match size(B_L,1) and size(B_R,1).');
  end

  [F_L, F_R, far_aux] = bloch.farfield_extractors(geom, rayleighchan, X_L, X_R, curvelen);
  F_L = full(complex(F_L));
  F_R = full(complex(F_R));
  if size(F_L, 1) ~= K || size(F_R, 1) ~= K
    error('construct_S:ExtractorRowMismatch', ...
      'F_L and F_R must have K rows.');
  end
  if size(F_L, 2) ~= size(A_QP, 1) || size(F_R, 2) ~= size(A_QP, 1)
    error('construct_S:ExtractorColumnMismatch', ...
      'size(F_L,2) and size(F_R,2) must match size(A_QP,1).');
  end

  rhs_all = [B_L, B_R];
  H_all = -(A_QP \ rhs_all);
  H_all = full(complex(H_all));
  H_L = H_all(:, 1:K);
  H_R = H_all(:, K + 1:2 * K);

  res = A_QP * H_all + rhs_all;
  solve_residual_norm = norm(res, 'fro');
  solve_relative_residual_norm = solve_residual_norm / max(1, norm(rhs_all, 'fro'));
  if ~isfinite(solve_residual_norm) || ~isfinite(solve_relative_residual_norm)
    error('construct_S:InvalidResidual', ...
      'The BIE solve residual is NaN or Inf.');
  end

  E = diag(phase);
  R_L = full(complex(F_L * H_L));
  T_LR = full(complex(E + F_R * H_L));
  T_RL = full(complex(E + F_L * H_R));
  R_R = full(complex(F_R * H_R));
  S = full(complex([R_L, T_RL; T_LR, R_R]));

  S_cell.R_L = R_L;
  S_cell.T_LR = T_LR;
  S_cell.T_RL = T_RL;
  S_cell.R_R = R_R;
  S_cell.S = S;
  S_cell.A_QP = A_QP;
  S_cell.B_L = B_L;
  S_cell.B_R = B_R;
  S_cell.F_L = F_L;
  S_cell.F_R = F_R;
  S_cell.H_L = H_L;
  S_cell.H_R = H_R;
  S_cell.phase = phase;
  S_cell.channels = rayleighchan;
  S_cell.K = K;
  S_cell.X_L = X_L;
  S_cell.X_R = X_R;
  S_cell.curvelen = curvelen;
  S_cell.far_aux = far_aux;
  S_cell.solve_residual_norm = solve_residual_norm;
  S_cell.solve_relative_residual_norm = solve_relative_residual_norm;
  S_cell.E = E;
  S_cell.L_cell = L_cell;

end
