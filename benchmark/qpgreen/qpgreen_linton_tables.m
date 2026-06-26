function results = qpgreen_linton_tables(varargin)
% QPGREEN_LINTON_TABLES Reproduce Linton Table 2-4 qpgreen checkpoints.
%
% Purpose:
%   Compares the project x-periodic MFS quasi-periodic Green function with a
%   benchmark Ewald implementation at the three single-point test cases used
%   in Linton (1998), Tables 2, 3, and 4.
%
% Main algorithm:
%   For each table case, converts Linton's coordinates
%     (X_Linton, Y_Linton)
%   to the project x-periodic separation
%     (dx_periodic, dy_transverse) = (Y_Linton, X_Linton),
%   evaluates Ewald and MFS values, compares MFS against Ewald, and reports
%   the Linton reference value as a sign-convention diagnostic.
%
% Based on:
%   Linton1998.pdf Tables 2-4, waveguide_1d/archive/qpgreen_ewald.m, and
%   +kernel/qpgreen_mfs.m.
%
% Main changes:
%   This is a new benchmark entry point only.  It does not modify the
%   package qpgreen routines or the mathematical model.
%
% Numerical goal:
%   Check that the MFS qpgreen agrees with an Ewald reference and document
%   whether the project convention i/4 H_0^{(1)} differs by a global sign
%   from Linton's printed Green function values.

  bench_dir = fileparts(mfilename('fullpath'));
  repo_root = fileparts(bench_dir);
  addpath(repo_root);
  addpath(bench_dir);

  opts = qpgreen_bench_defaults(varargin{:});
  timestamp = datestr(now, 'yyyymmdd_HHMMSS');
  output_dir = opts.OutputRoot;
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end

  cases = LOCAL_linton_cases();
  use_table_ewald = LOCAL_should_use_table_ewald(opts, varargin{:});

  fprintf('\nqpgreen Linton Table 2-4 benchmark\n');
  fprintf('Project convention: x-periodic, free-space kernel i/4 H_0^(1).\n');
  fprintf('Coordinate map: (X_Linton,Y_Linton) -> (dx_periodic,dy_transverse) = (Y_Linton,X_Linton).\n\n');

  ncase = numel(cases);
  rows = repmat(struct(), 1, ncase);
  ewald_values = zeros(1, ncase);
  mfs_values = zeros(1, ncase);
  linton_values = zeros(1, ncase);

  % --- stage 1: evaluate all Linton table cases ---
  for icase = 1:ncase
    c = cases(icase);
    case_opts = opts;
    case_opts.k = c.kd / c.d;
    case_opts.beta = c.betad / c.d;
    case_opts.d = c.d;

    if use_table_ewald
      ewald_pars2 = c.ewald;
    else
      ewald_pars2 = struct('a', opts.EwaldA, 'M1', opts.EwaldM1, ...
        'M2', opts.EwaldM2, 'N', opts.EwaldN);
    end
    ewald_pars2.grazing_tol = opts.GrazingTolerance;

    src = [0; 0];
    trg = [c.Y_linton * c.d; c.X_linton * c.d];

    ewald_pars1 = struct('k', case_opts.k, 'beta', case_opts.beta, ...
      'd', case_opts.d);
    t_ewald = tic;
    [ewald_value, ewald_aux] = qpgreen_ewald_xperiodic_bench(src, trg, ...
      ewald_pars1, ewald_pars2);
    ewald_time = toc(t_ewald);

    t_mfs = tic;
    [mfs_value, mfs_aux] = qpgreen_mfs_eval_bench(src, trg, case_opts);
    mfs_time = toc(t_mfs);

    abs_err_mfs_ewald = abs(mfs_value - ewald_value);
    rel_err_mfs_ewald = abs_err_mfs_ewald / max(abs(ewald_value), opts.RelFloor);

    rows(icase).table = c.table;
    rows(icase).kd = c.kd;
    rows(icase).betad = c.betad;
    rows(icase).X_linton_over_d = c.X_linton;
    rows(icase).Y_linton_over_d = c.Y_linton;
    rows(icase).dx_periodic_over_d = c.Y_linton;
    rows(icase).dy_transverse_over_d = c.X_linton;
    rows(icase).linton_reference = c.reference;
    rows(icase).ewald_project = ewald_value;
    rows(icase).mfs_project = mfs_value;
    rows(icase).abs_err_mfs_vs_ewald = abs_err_mfs_ewald;
    rows(icase).rel_err_mfs_vs_ewald = rel_err_mfs_ewald;
    rows(icase).ewald_time = ewald_time;
    rows(icase).mfs_time = mfs_time;
    rows(icase).mfs_precomp_time = mfs_aux.precomp_time;
    rows(icase).mfs_eval_time = mfs_aux.eval_time;
    rows(icase).ewald_params = ewald_pars2;
    rows(icase).mfs_params = mfs_aux.pars2;
    rows(icase).ewald_aux = ewald_aux;

    ewald_values(icase) = ewald_value;
    mfs_values(icase) = mfs_value;
    linton_values(icase) = c.reference;
  end

  % --- stage 2: diagnose sign convention against Linton references ---
  direct_linton_error = norm(ewald_values - linton_values);
  flipped_linton_error = norm(-ewald_values - linton_values);
  green_sign = +1;
  sign_note = 'Ewald project values are closer to Linton references without sign flip.';
  if flipped_linton_error < direct_linton_error
    green_sign = -1;
    sign_note = ['Linton references are closer to -1 times the project ', ...
      'Ewald values; this is consistent with an opposite free-space Green sign.'];
  end

  for icase = 1:ncase
    rows(icase).green_sign_for_linton_match = green_sign;
    rows(icase).abs_err_ewald_vs_linton_signed = ...
      abs(green_sign * rows(icase).ewald_project - rows(icase).linton_reference);
    rows(icase).abs_err_mfs_vs_linton_signed = ...
      abs(green_sign * rows(icase).mfs_project - rows(icase).linton_reference);
  end

  % --- stage 3: print, save, and summarize outputs ---
  LOCAL_print_rows(rows, green_sign, direct_linton_error, flipped_linton_error, ...
    sign_note, use_table_ewald);

  results = struct();
  results.options = opts;
  results.timestamp = timestamp;
  results.coordinate_note = ['Linton periodic direction is Y; project ', ...
    'x-periodic coordinates use dx_periodic = Y_Linton and dy_transverse = X_Linton.'];
  results.green_sign = green_sign;
  results.sign_note = sign_note;
  results.direct_linton_error = direct_linton_error;
  results.flipped_linton_error = flipped_linton_error;
  results.rows = rows;

  mat_path = fullfile(output_dir, ['qpgreen_linton_tables_', timestamp, '.mat']);
  summary_path = fullfile(output_dir, ['qpgreen_linton_tables_', timestamp, '.md']);
  save(mat_path, 'results');
  LOCAL_write_summary(summary_path, rows, results, use_table_ewald);

  fprintf('\nSaved MAT results: %s\n', mat_path);
  fprintf('Saved summary:     %s\n\n', summary_path);

  results.mat_path = mat_path;
  results.summary_path = summary_path;
end

%% ==================== Linton table data helper ====================
% This helper stores the single-point values extracted from Linton Tables 2-4.

function cases = LOCAL_linton_cases()
  cases = repmat(struct(), 1, 3);

  cases(1).table = 2;
  cases(1).d = 1;
  cases(1).kd = 2;
  cases(1).betad = sqrt(2);
  cases(1).X_linton = 0;
  cases(1).Y_linton = 0.01;
  cases(1).reference = -0.4595298795 - 0.3509130869i;
  cases(1).ewald = struct('a', 2, 'M1', 3, 'M2', 2, 'N', 7);

  cases(2).table = 3;
  cases(2).d = 1;
  cases(2).kd = 10;
  cases(2).betad = 5 * sqrt(2);
  cases(2).X_linton = 0;
  cases(2).Y_linton = 0.01;
  cases(2).reference = -0.3538172307 - 0.1769332383i;
  cases(2).ewald = struct('a', 2, 'M1', 4, 'M2', 2, 'N', 28);

  cases(3).table = 4;
  cases(3).d = 1;
  cases(3).kd = 2;
  cases(3).betad = 3;
  cases(3).X_linton = 0;
  cases(3).Y_linton = 0.01;
  cases(3).reference = -0.7617463954 - 0.0006387129177i;
  cases(3).ewald = struct('a', 2, 'M1', 3, 'M2', 2, 'N', 7);
end

%% ==================== Reporting helper ====================
% These helpers format command-line and Markdown summaries.

function LOCAL_print_rows(rows, green_sign, direct_err, flipped_err, sign_note, ...
    use_table_ewald)
  if use_table_ewald
    ewald_mode = 'per-table Linton Ewald parameters';
  else
    ewald_mode = 'global user Ewald parameters';
  end
  fprintf('Ewald parameter mode: %s\n', ewald_mode);
  fprintf('Sign diagnostic: green_sign = %+d\n', green_sign);
  fprintf('  norm(Ewald - Linton)  = %.6e\n', direct_err);
  fprintf('  norm(-Ewald - Linton) = %.6e\n', flipped_err);
  fprintf('  %s\n\n', sign_note);

  fprintf('%5s %10s %12s %8s %8s %24s %24s %24s %11s %11s %9s %9s\n', ...
    'Table', 'kd', 'beta*d', 'X_L/d', 'Y_L/d', 'Linton ref', ...
    'Ewald project', 'MFS project', 'abs M-E', 'rel M-E', 'tEwald', 'tMFS');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf('%5d %10.6g %12.6g %8.3g %8.3g %24s %24s %24s %11.3e %11.3e %9.3f %9.3f\n', ...
      r.table, r.kd, r.betad, r.X_linton_over_d, r.Y_linton_over_d, ...
      LOCAL_cplx(r.linton_reference), LOCAL_cplx(r.ewald_project), ...
      LOCAL_cplx(r.mfs_project), r.abs_err_mfs_vs_ewald, ...
      r.rel_err_mfs_vs_ewald, r.ewald_time, r.mfs_time);
  end
end

function LOCAL_write_summary(summary_path, rows, results, use_table_ewald)
  fid = fopen(summary_path, 'w');
  if fid < 0
    warning('qpgreen_linton_tables:SummaryOpenFailed', ...
      'Could not write summary file %s.', summary_path);
    return;
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, '# qpgreen Linton Table Benchmark\n\n');
  fprintf(fid, '- Timestamp: `%s`\n', results.timestamp);
  fprintf(fid, '- green_sign for matching Linton convention: `%+d`\n', ...
    results.green_sign);
  fprintf(fid, '- Direct Linton norm error: `%.16e`\n', results.direct_linton_error);
  fprintf(fid, '- Flipped Linton norm error: `%.16e`\n', results.flipped_linton_error);
  fprintf(fid, '- Ewald parameter mode: `%d` (`1` means table-specific)\n\n', ...
    use_table_ewald);
  fprintf(fid, '%s\n\n', results.sign_note);
  fprintf(fid, '| Table | kd | beta*d | X_L/d | Y_L/d | Linton | Ewald project | MFS project | abs(MFS-Ewald) | rel(MFS-Ewald) | Ewald time (s) | MFS total time (s) | MFS precomp (s) | MFS eval (s) | MFS/Ewald time |\n');
  fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf(fid, '| %d | %.12g | %.12g | %.12g | %.12g | `%s` | `%s` | `%s` | %.16e | %.16e | %.6f | %.6f | %.6f | %.6f | %.3f |\n', ...
      r.table, r.kd, r.betad, r.X_linton_over_d, r.Y_linton_over_d, ...
      LOCAL_cplx(r.linton_reference), LOCAL_cplx(r.ewald_project), ...
      LOCAL_cplx(r.mfs_project), r.abs_err_mfs_vs_ewald, ...
      r.rel_err_mfs_vs_ewald, r.ewald_time, r.mfs_time, ...
      r.mfs_precomp_time, r.mfs_eval_time, r.mfs_time / r.ewald_time);
  end

  clear cleaner;
end

function s = LOCAL_cplx(z)
  s = sprintf('%.10g%+.10gi', real(z), imag(z));
end

%% ==================== Option diagnostic helper ====================
% This helper decides whether user-supplied Ewald values override table data.

function use_table_ewald = LOCAL_should_use_table_ewald(opts, varargin)
  use_table_ewald = opts.UseTableEwaldParams;
  for j = 1:2:numel(varargin)
    name = varargin{j};
    if isstring(name)
      name = char(name);
    end
    if ischar(name)
      key = lower(strrep(strrep(strtrim(name), '_', ''), '-', ''));
      if any(strcmp(key, {'ewalda', 'a', 'ewaldm1', 'm1', 'ewaldm2', 'm2', ...
          'ewaldn', 'n'}))
        use_table_ewald = false;
      end
    end
  end
end
