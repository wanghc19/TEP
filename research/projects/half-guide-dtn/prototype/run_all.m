function results = run_all()
% RUN_ALL Run the first isolated homogeneous DtN validation.
%
% Purpose:
%   Validate the local-cell Riccati sign convention for homogeneous periodic
%   half-guides before introducing obstacle BIE blocks or center-cell Muller
%   coupling.
%
% Main algorithm:
%   The script builds analytic Rayleigh-channel local cell DtN blocks, checks
%   the Joly Riccati residual for the exact propagation factors, converts the
%   local-cell outward-normal blocks to the project port convention
%   N^+ = +partial_x u and N^- = -partial_x u, and compares the result with
%   the analytic homogeneous half-guide DtN diag(1i*gamma_m).
%
% Based on:
%   This is a new standalone prototype based on the sign conventions read from
%   +bloch/rayleigh_channels.m, +bloch/mode_traces.m,
%   +bloch/select_port_traces.m, and Joly-Li-Fliss 2006.
%
% Main changes:
%   No existing package code is modified. All outputs are written under
%   attempt/experiments.
%
% Numerical goal:
%   Produce a reproducible sanity check for the homogeneous lead. Away from
%   cutoffs and local cell Dirichlet resonances, the converted DtN matrix should
%   match diag(1i*gamma_m) to roundoff, while the absorbing case should move the
%   propagation spectrum strictly inside the unit disk.

  attempt_root = fileparts(fileparts(mfilename('fullpath')));
  output_dir = fullfile(attempt_root, 'experiments');
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end

  % --- stage 1: set user-adjustable validation parameters ---
  params = struct();
  params.d = 1.0;       % y-period of the homogeneous guide.
  params.L = 0.73;      % x-period length of one local lead cell.
  params.M = 8;         % Rayleigh truncation half-width, using m=-M:M.
  params.k0 = 2.4;      % real reference wavenumber before optional absorption.
  params.beta = 0.35;   % y-quasiperiodicity parameter.
  params.eps_values = [0, 1e-3, 5e-2];  % absorption in k^2 -> k0^2 + i*eps.
  params.cutoff_tol = 1e-10;            % tolerance for detecting gamma_m near 0.
  params.cell_resonance_tol = 1e-10;    % tolerance for detecting sin(gamma_m*L).
  params.output_dir = output_dir;

  % --- stage 2: run homogeneous DtN checks for each absorption value ---
  results = struct();
  results.params = params;
  results.cases = repmat(LOCAL_empty_case(), numel(params.eps_values), 1);
  for j = 1:numel(params.eps_values)
    results.cases(j) = LOCAL_run_homogeneous_case(params, params.eps_values(j));
  end

  % --- stage 3: save structured text outputs for recovery and comparison ---
  csv_path = fullfile(output_dir, 'homogeneous_dtn_validation.csv');
  md_path = fullfile(output_dir, 'homogeneous_dtn_validation.md');
  LOCAL_write_csv(csv_path, results);
  LOCAL_write_markdown(md_path, results);
  LOCAL_update_experiment_summary(fullfile(output_dir, 'experiment_summary.md'), ...
    csv_path, md_path, results);

  fprintf('\nHomogeneous DtN validation complete.\n');
  fprintf('  CSV: %s\n', csv_path);
  fprintf('  Markdown: %s\n', md_path);
  for j = 1:numel(results.cases)
    c = results.cases(j);
    fprintf(['  eps = %.3e, max Riccati residual = %.3e, ', ...
      'project DtN relerr = %.3e, stable count = %d/%d\n'], ...
      c.eps_abs, c.max_riccati_residual, c.project_dtn_relative_error, ...
      c.stable_count, c.K);
  end

end

%% ==================== Homogeneous validation helper ====================
% This helper builds analytic local-cell blocks and compares DtN formulas.

function case_result = LOCAL_run_homogeneous_case(params, eps_abs)

  case_result = LOCAL_empty_case();
  case_result.eps_abs = eps_abs;
  case_result.k_squared = params.k0^2 + 1i * eps_abs;
  case_result.k = sqrt(case_result.k_squared);

  m = (-params.M:params.M).';
  beta_m = params.beta + 2 * pi * m / params.d;
  gamma_m = sqrt(case_result.k_squared - beta_m.^2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);

  z = gamma_m * params.L;
  near_cutoff = abs(gamma_m) < params.cutoff_tol;
  near_cell_resonance = abs(sin(z)) < params.cell_resonance_tol;
  if any(near_cutoff)
    error('run_all:CutoffChannel', ...
      'At least one homogeneous channel is too close to cutoff.');
  end
  if any(near_cell_resonance)
    error('run_all:CellDirichletResonance', ...
      'At least one channel is too close to a local cell Dirichlet resonance.');
  end

  T00 = gamma_m .* cot(z);
  T01 = -gamma_m ./ sin(z);
  T10 = T01;
  T11 = T00;
  R_diag = exp(1i * gamma_m * params.L);

  riccati_diag = T10 .* R_diag.^2 + (T00 + T11) .* R_diag + T01;
  joly_K_diag = T00 + T10 .* R_diag;
  project_lambda_diag = -(T00 + T01 .* R_diag);
  analytic_lambda_diag = 1i * gamma_m;

  qep_lambda = LOCAL_scalar_qep_eigenvalues(T10, T00 + T11, T01);
  stable_mask = abs(qep_lambda) < 1 - 1e-10;

  case_result.K = numel(m);
  case_result.m_min = min(m);
  case_result.m_max = max(m);
  case_result.num_propagating_lossless = nnz(abs(real(beta_m)) < params.k0);
  case_result.max_abs_gamma_imag = max(abs(imag(gamma_m)));
  case_result.max_abs_phase = max(abs(R_diag));
  case_result.min_abs_phase = min(abs(R_diag));
  case_result.max_riccati_residual = max(abs(riccati_diag));
  case_result.project_dtn_relative_error = norm(project_lambda_diag - ...
    analytic_lambda_diag) / max(1, norm(analytic_lambda_diag));
  case_result.joly_sign_relative_error = norm(joly_K_diag + ...
    analytic_lambda_diag) / max(1, norm(analytic_lambda_diag));
  case_result.stable_count = nnz(stable_mask);
  case_result.qep_eigenvalue_count = numel(qep_lambda);
  case_result.max_qep_pairing_error = LOCAL_pairing_error(qep_lambda);
  case_result.status = 'ok';

  if any(~isfinite([case_result.max_riccati_residual, ...
      case_result.project_dtn_relative_error, ...
      case_result.joly_sign_relative_error, ...
      case_result.max_qep_pairing_error]))
    error('run_all:InvalidDiagnostic', ...
      'A homogeneous DtN diagnostic is NaN or Inf.');
  end

end

function lambda = LOCAL_scalar_qep_eigenvalues(A, B, C)

  lambda = zeros(2 * numel(A), 1);
  out = 0;
  for j = 1:numel(A)
    companion_A = [0, 1; -C(j), -B(j)];
    companion_B = [1, 0; 0, A(j)];
    vals = eig(companion_A, companion_B);
    lambda(out + (1:2)) = vals(:);
    out = out + 2;
  end

end

function err = LOCAL_pairing_error(lambda)

  finite_lambda = lambda(isfinite(lambda) & abs(lambda) > 0);
  if isempty(finite_lambda)
    err = NaN;
    return;
  end

  err = 0;
  for j = 1:numel(finite_lambda)
    target = 1 / finite_lambda(j);
    scale = max(1, abs(target));
    err = max(err, min(abs(finite_lambda - target)) / scale);
  end

end

function case_result = LOCAL_empty_case()

  case_result = struct( ...
    'eps_abs', NaN, ...
    'k_squared', NaN, ...
    'k', NaN, ...
    'K', NaN, ...
    'm_min', NaN, ...
    'm_max', NaN, ...
    'num_propagating_lossless', NaN, ...
    'max_abs_gamma_imag', NaN, ...
    'max_abs_phase', NaN, ...
    'min_abs_phase', NaN, ...
    'max_riccati_residual', NaN, ...
    'project_dtn_relative_error', NaN, ...
    'joly_sign_relative_error', NaN, ...
    'stable_count', NaN, ...
    'qep_eigenvalue_count', NaN, ...
    'max_qep_pairing_error', NaN, ...
    'status', 'unset');

end

%% ==================== Output helper ====================
% These helpers persist experiment data in simple text formats.

function LOCAL_write_csv(csv_path, results)

  fid = fopen(csv_path, 'w');
  if fid < 0
    error('run_all:CsvOpenFailed', 'Could not open CSV output file.');
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, ['eps_abs,k_squared_real,k_squared_imag,k_real,k_imag,K,', ...
    'm_min,m_max,num_propagating_lossless,max_abs_gamma_imag,', ...
    'min_abs_phase,max_abs_phase,max_riccati_residual,', ...
    'project_dtn_relative_error,joly_sign_relative_error,', ...
    'stable_count,qep_eigenvalue_count,max_qep_pairing_error,status\n']);
  for j = 1:numel(results.cases)
    c = results.cases(j);
    fprintf(fid, ['%.16e,%.16e,%.16e,%.16e,%.16e,%d,%d,%d,%d,', ...
      '%.16e,%.16e,%.16e,%.16e,%.16e,%.16e,%d,%d,%.16e,%s\n'], ...
      c.eps_abs, real(c.k_squared), imag(c.k_squared), real(c.k), imag(c.k), ...
      c.K, c.m_min, c.m_max, c.num_propagating_lossless, ...
      c.max_abs_gamma_imag, c.min_abs_phase, c.max_abs_phase, ...
      c.max_riccati_residual, c.project_dtn_relative_error, ...
      c.joly_sign_relative_error, c.stable_count, c.qep_eigenvalue_count, ...
      c.max_qep_pairing_error, c.status);
  end

end

function LOCAL_write_markdown(md_path, results)

  fid = fopen(md_path, 'w');
  if fid < 0
    error('run_all:MarkdownOpenFailed', 'Could not open Markdown output file.');
  end
  cleaner = onCleanup(@() fclose(fid));

  p = results.params;
  fprintf(fid, '# Homogeneous DtN Validation\n\n');
  fprintf(fid, 'Generated by `attempt/prototype/run_all.m`.\n\n');
  fprintf(fid, '## Parameters\n\n');
  fprintf(fid, '- `d = %.16g`\n', p.d);
  fprintf(fid, '- `L = %.16g`\n', p.L);
  fprintf(fid, '- `M = %d`, so `K = %d`\n', p.M, 2 * p.M + 1);
  fprintf(fid, '- `k0 = %.16g`\n', p.k0);
  fprintf(fid, '- `beta = %.16g`\n', p.beta);
  fprintf(fid, '- absorption convention: `k^2 = k0^2 + 1i*eps_abs`\n\n');

  fprintf(fid, '## Formula Check\n\n');
  fprintf(fid, ['For a homogeneous channel, the cell outward-normal blocks are ', ...
    '`T00=T11=gamma*cot(gamma*L)` and `T01=T10=-gamma*csc(gamma*L)`. ', ...
    'The project port DtN is `-(T00+T01*R)` and should equal `1i*gamma`.\n\n']);

  fprintf(fid, '## Results\n\n');
  fprintf(fid, ['| eps_abs | max Riccati residual | project DtN relerr | ', ...
    'Joly sign relerr | min abs phase | max abs phase | stable count |\n']);
  fprintf(fid, '| ---: | ---: | ---: | ---: | ---: | ---: | ---: |\n');
  for j = 1:numel(results.cases)
    c = results.cases(j);
    fprintf(fid, '| %.3e | %.3e | %.3e | %.3e | %.6g | %.6g | %d/%d |\n', ...
      c.eps_abs, c.max_riccati_residual, c.project_dtn_relative_error, ...
      c.joly_sign_relative_error, c.min_abs_phase, c.max_abs_phase, ...
      c.stable_count, c.qep_eigenvalue_count);
  end

  fprintf(fid, '\n## Interpretation\n\n');
  fprintf(fid, ['The converted project DtN should match `diag(1i*gamma_m)`. ', ...
    'The Joly-style coefficient has the opposite sign in this homogeneous ', ...
    'right-port convention because it appears naturally in a boundary ', ...
    'condition `partial_x u + K u = 0`.\n\n']);
  fprintf(fid, ['In the lossless case, propagating channels have unit-modulus ', ...
    'multipliers and therefore are not selected by the absorbing criterion ', ...
    '`rho(R)<1`. Adding absorption moves those multipliers inside the unit ', ...
    'disk and makes stable selection unambiguous away from thresholds.\n']);

end

function LOCAL_update_experiment_summary(summary_path, csv_path, md_path, results)

  fid = fopen(summary_path, 'w');
  if fid < 0
    error('run_all:SummaryOpenFailed', ...
      'Could not open experiment summary file.');
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, '# Experiment Summary\n\n');
  fprintf(fid, '## Experiment 1: Homogeneous Lead DtN\n\n');
  fprintf(fid, '- Entry point: `attempt/prototype/run_all.m`\n');
  fprintf(fid, '- CSV data: `%s`\n', csv_path);
  fprintf(fid, '- Markdown report: `%s`\n\n', md_path);
  fprintf(fid, '### Latest Diagnostics\n\n');
  fprintf(fid, ['| eps_abs | max Riccati residual | project DtN relerr | ', ...
    'stable count |\n']);
  fprintf(fid, '| ---: | ---: | ---: | ---: |\n');
  for j = 1:numel(results.cases)
    c = results.cases(j);
    fprintf(fid, '| %.3e | %.3e | %.3e | %d/%d |\n', ...
      c.eps_abs, c.max_riccati_residual, c.project_dtn_relative_error, ...
      c.stable_count, c.qep_eigenvalue_count);
  end

  fprintf(fid, '\n### Conclusion\n\n');
  fprintf(fid, ['The homogeneous sign/order test supports the conversion ', ...
    '`Lambda_TEP = -(T00 + T01*R) = diag(1i*gamma_m)` for the right-port ', ...
    'cell orientation used in the derivation notes. This is only a ', ...
    'homogeneous validation; periodic obstacle leads and center Muller-DtN ', ...
    'coupling remain unvalidated.\n']);

end
