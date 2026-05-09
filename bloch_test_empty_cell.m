% Purpose:
%   Test bloch.solve_modes and bloch.mode_traces against the analytic
%   empty-cell Bloch multipliers.
%
% Simplified problem:
%   No scatterer is present in the cell, so the synthetic single-cell
%   scattering blocks are
%
%     R_L = 0, \quad R_R = 0, \quad T_{LR} = E, \quad T_{RL} = E,
%     E = \operatorname{diag}(\exp(i \gamma_m L)).
%
% Expected analytic result:
%   The Bloch multipliers are the union of right-going and left-going
%   free-propagation phases,
%
%     \lambda_m^{right} = \exp(i \gamma_m L), \qquad
%     \lambda_m^{left}  = \exp(-i \gamma_m L).
%
% What is checked:
%   The script compares the computed lambda set with
%
%     \{ \exp(i \gamma_m L) \}_m \cup
%     \{ \exp(-i \gamma_m L) \}_m,
%
%   checks the generalized eigenpair residual
%
%     A_{sc} V_j - \lambda_j B_{sc} V_j,
%
%   and checks Bloch trace consistency
%
%     D_R(:,j) = \lambda_j D_L(:,j), \qquad
%     N_R(:,j) = \lambda_j N_L(:,j).

clear;

% Wavenumber.  A small imaginary part checks that complex gamma_m and
% non-unit propagation phases are handled correctly.
k = 1.3 + 1i * 1e-4;

% Transverse quasiperiodicity, transverse period, Rayleigh truncation
% half-width, and x-period of the empty cell.
beta = 0.4;
d = 2 * pi;
M = 2;
L = 1.7;

% Diagnostic tolerance used for set matching, eigenpair residuals, and trace
% consistency checks.
tol = 1e-10;

rayleighchan = bloch.rayleigh_channels(k, beta, d, M, L);
K = rayleighchan.K;
E = diag(rayleighchan.phase);

Z = zeros(K);
S_cell.R_L = Z;
S_cell.R_R = Z;
S_cell.T_LR = E;
S_cell.T_RL = E;
S_cell.S = [S_cell.R_L, S_cell.T_RL; ...
            S_cell.T_LR, S_cell.R_R];
S_cell.channels = rayleighchan;
S_cell.K = K;

modes = bloch.solve_modes(S_cell);
traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);

lambda_expected = [rayleighchan.phase; 1 ./ rayleighchan.phase];
lambda_computed = modes.lambda(:);

fprintf('bloch_test_empty_cell\n');
fprintf('K = %d, M = %d\n', K, M);
fprintf('k = %.16g%+.16gi\n', real(k), imag(k));
fprintf('beta = %.16g, d = %.16g, L = %.16g\n', beta, d, L);

fprintf('\nexpected lambda values:\n');
for j = 1:length(lambda_expected)
  fprintf('  %2d: %.16e%+.16ei\n', ...
    j, real(lambda_expected(j)), imag(lambda_expected(j)));
end

fprintf('\ncomputed lambda values:\n');
for j = 1:length(lambda_computed)
  fprintf('  %2d: %.16e%+.16ei\n', ...
    j, real(lambda_computed(j)), imag(lambda_computed(j)));
end

if length(lambda_computed) ~= length(lambda_expected)
  error('bloch_test_empty_cell:ModeCountMismatch', ...
    'Expected %d modes but computed %d modes.', ...
    length(lambda_expected), length(lambda_computed));
end
if size(modes.V, 1) ~= 2 * K || size(modes.V, 2) ~= length(lambda_computed)
  error('bloch_test_empty_cell:EigenvectorSizeMismatch', ...
    'modes.V must be 2K-by-number_of_modes.');
end

% --- Check 1: eigenvalue set matching ---
match_err_expected_to_computed = zeros(length(lambda_expected), 1);
for j = 1:length(lambda_expected)
  match_err_expected_to_computed(j) = min(abs(lambda_computed - lambda_expected(j)));
end
max_match_err_expected_to_computed = max(match_err_expected_to_computed);

match_err_computed_to_expected = zeros(length(lambda_computed), 1);
for j = 1:length(lambda_computed)
  match_err_computed_to_expected(j) = min(abs(lambda_expected - lambda_computed(j)));
end
max_match_err_computed_to_expected = max(match_err_computed_to_expected);

% --- Check 2: generalized eigenpair residual A_sc*V - lambda*B_sc*V ---
eigenpair_residual = zeros(length(lambda_computed), 1);
for j = 1:length(lambda_computed)
  residual_vec = modes.A_sc * modes.V(:, j) - ...
    lambda_computed(j) * modes.B_sc * modes.V(:, j);
  scale = norm(modes.A_sc * modes.V(:, j)) + ...
    abs(lambda_computed(j)) * norm(modes.B_sc * modes.V(:, j)) + eps;
  eigenpair_residual(j) = norm(residual_vec) / scale;
end
max_eigenpair_residual = max(eigenpair_residual);

% --- Check 3: Bloch trace consistency D_R = lambda*D_L, N_R = lambda*N_L ---
trace_consistency_error = zeros(length(lambda_computed), 1);
for j = 1:length(lambda_computed)
  residual_D = traces.D_R(:, j) - lambda_computed(j) * traces.D_L(:, j);
  residual_N = traces.N_R(:, j) - lambda_computed(j) * traces.N_L(:, j);
  scale_D = norm(traces.D_R(:, j)) + ...
    abs(lambda_computed(j)) * norm(traces.D_L(:, j)) + eps;
  scale_N = norm(traces.N_R(:, j)) + ...
    abs(lambda_computed(j)) * norm(traces.N_L(:, j)) + eps;
  trace_consistency_error(j) = max(norm(residual_D) / scale_D, ...
    norm(residual_N) / scale_N);
end
max_trace_consistency_error = max(trace_consistency_error);

fprintf('\nmax_match_err_expected_to_computed = %.16e\n', ...
  max_match_err_expected_to_computed);
fprintf('max_match_err_computed_to_expected = %.16e\n', ...
  max_match_err_computed_to_expected);
fprintf('max_eigenpair_residual = %.16e\n', max_eigenpair_residual);
fprintf('max_trace_consistency_error = %.16e\n', ...
  max_trace_consistency_error);

if max_match_err_expected_to_computed < tol && ...
    max_match_err_computed_to_expected < tol && ...
    max_eigenpair_residual < tol && ...
    max_trace_consistency_error < tol
  fprintf('\nPASS\n');
else
  fprintf('\nFAIL\n');
end
