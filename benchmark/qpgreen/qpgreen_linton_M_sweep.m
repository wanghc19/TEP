function results = qpgreen_linton_M_sweep(varargin)
% QPGREEN_LINTON_M_SWEEP Sweep Rayleigh truncation on one Linton benchmark.
%
% Purpose:
%   Tests how the Rayleigh-Bloch half-truncation M affects the augmented-MFS
%   quasi-periodic Green function error on a single lightweight Linton table
%   comparison.
%
% Main algorithm:
%   Uses the Table 4 point from Linton (1998), converted to the project
%   x-periodic coordinate convention, computes one Ewald reference value,
%   then repeats the MFS precomputation/evaluation for
%     M = [4, 5, 6, 7, 8, 10, 12, 16, 25].
%   The proxy source placement, total proxy count, matching height, and
%   collocation placement are held fixed except for quantities implied by M.
%
% Based on:
%   benchmark/qpgreen_linton_tables.m, benchmark/qpgreen_mfs_eval_bench.m,
%   benchmark/qpgreen_ewald_xperiodic_bench.m, and Linton1998.pdf Table 4.
%
% Main changes:
%   This benchmark-only entry point narrows the Linton table comparison to a
%   small M-sweep study.  It does not change package qpgreen routines or the
%   mathematical model.
%
% Numerical goal:
%   Determine whether the previous default M = 25 is necessary for the
%   d = 1, H = 0.5 single-point benchmark, and export a compact CSV/MAT
%   summary plus a Beamer-ready PDF error curve.

  bench_dir = fileparts(mfilename('fullpath'));
  repo_root = fileparts(bench_dir);
  addpath(repo_root);
  addpath(bench_dir);

  opts = LOCAL_parse_options(varargin{:});
  if ~exist(opts.OutputRoot, 'dir')
    mkdir(opts.OutputRoot);
  end
  figure_dir = fileparts(opts.FigurePath);
  if ~exist(figure_dir, 'dir')
    mkdir(figure_dir);
  end

  c = LOCAL_linton_table4_case();
  case_opts = opts;
  case_opts.k = c.kd / c.d;
  case_opts.beta = c.betad / c.d;
  case_opts.d = c.d;
  case_opts.H = 0.5;
  case_opts.Nproxy = 320;

  src = [0; 0];
  trg = [c.Y_linton * c.d; c.X_linton * c.d];

  ewald_pars1 = struct('k', case_opts.k, 'beta', case_opts.beta, ...
    'd', case_opts.d);
  ewald_pars2 = c.ewald;
  ewald_pars2.grazing_tol = opts.GrazingTolerance;
  t_ewald = tic;
  [ewald_value, ewald_aux] = qpgreen_ewald_xperiodic_bench(src, trg, ...
    ewald_pars1, ewald_pars2);
  ewald_time = toc(t_ewald);

  nM = numel(opts.MList);
  rows = repmat(LOCAL_empty_row(), 1, nM);

  fprintf('\nLinton Table 4 M-sweep benchmark\n');
  fprintf('Fixed case: kd = %.12g, beta*d = %.12g, d = %.12g, H = %.12g\n', ...
    c.kd, c.betad, case_opts.d, case_opts.H);
  fprintf('Fixed point map: (X_Linton,Y_Linton) = (%.12g, %.12g) -> (dx,dy) = (%.12g, %.12g)\n', ...
    c.X_linton, c.Y_linton, c.Y_linton, c.X_linton);
  fprintf('Fixed N_proxy = %d; Ewald reference = %s; Ewald time = %.6f s\n\n', ...
    case_opts.Nproxy, LOCAL_cplx(ewald_value), ewald_time);

  for j = 1:nM
    M = opts.MList(j);
    this_opts = case_opts;
    this_opts.M = M;

    t_mfs = tic;
    [mfs_value, mfs_aux] = qpgreen_mfs_eval_bench(src, trg, this_opts);
    runtime_seconds = toc(t_mfs);

    abs_error = abs(mfs_value - ewald_value);
    rel_error = abs_error / max(abs(ewald_value), opts.RelFloor);

    rows(j).M = M;
    rows(j).N_proxy = mfs_aux.diagnostics.number_of_proxy_sources;
    rows(j).number_of_rayleigh_modes = mfs_aux.number_of_rayleigh_modes;
    rows(j).number_of_unknowns = mfs_aux.number_of_unknowns;
    rows(j).number_of_collocation_equations = ...
      mfs_aux.number_of_collocation_equations;
    rows(j).abs_error_against_reference = abs_error;
    rows(j).rel_error_against_reference = rel_error;
    rows(j).least_squares_residual = mfs_aux.least_squares_residual;
    rows(j).relative_least_squares_residual = ...
      mfs_aux.relative_least_squares_residual;
    rows(j).cond_estimate = mfs_aux.cond_estimate;
    rows(j).rcond_estimate = mfs_aux.rcond_estimate;
    rows(j).runtime_seconds = runtime_seconds;
    rows(j).precomp_time = mfs_aux.precomp_time;
    rows(j).eval_time = mfs_aux.eval_time;
    rows(j).mfs_value = mfs_value;
  end

  LOCAL_print_rows(rows);

  results = struct();
  results.timestamp = datestr(now, 'yyyymmdd_HHMMSS');
  results.description = 'Linton Table 4 single-point M-sweep for x-periodic qpgreen MFS.';
  results.options = opts;
  results.case = c;
  results.ewald_value = ewald_value;
  results.ewald_time = ewald_time;
  results.ewald_aux = ewald_aux;
  results.rows = rows;
  results.mat_path = fullfile(opts.OutputRoot, 'linton_M_sweep_results.mat');
  results.csv_path = fullfile(opts.OutputRoot, 'linton_M_sweep_results.csv');
  results.figure_path = opts.FigurePath;

  save(results.mat_path, 'results');
  LOCAL_write_csv(results.csv_path, rows);
  LOCAL_write_figure(results.figure_path, rows);

  fprintf('\nSaved MAT results: %s\n', results.mat_path);
  fprintf('Saved CSV results: %s\n', results.csv_path);
  fprintf('Saved PDF figure:  %s\n\n', results.figure_path);
end

%% ==================== Option helper ====================
% These helpers parse benchmark options while adding M-sweep controls.

function opts = LOCAL_parse_options(varargin)
  bench_dir = fileparts(mfilename('fullpath'));
  repo_root = fileparts(bench_dir);
  MList = [4, 5, 6, 7, 8, 10, 12, 16, 25];
  FigurePath = fullfile(repo_root, 'pre', 'pre3', 'figures', ...
    'linton_M_sweep_error.pdf');
  bench_args = {};

  if mod(numel(varargin), 2) ~= 0
    error('qpgreen_linton_M_sweep:InvalidInput', ...
      'Options must be supplied as name-value pairs.');
  end

  for j = 1:2:numel(varargin)
    name = varargin{j};
    value = varargin{j + 1};
    key = LOCAL_normalize_name(name);
    switch key
      case 'mlist'
        MList = value;
      case 'figurepath'
        FigurePath = value;
      otherwise
        bench_args(end+1:end+2) = varargin(j:j+1);
    end
  end

  opts = qpgreen_bench_defaults(bench_args{:});
  opts.MList = MList;
  opts.FigurePath = FigurePath;
  opts.MList = reshape(opts.MList, 1, []);
end

function key = LOCAL_normalize_name(name)
  if isstring(name)
    name = char(name);
  end
  if ~ischar(name)
    error('qpgreen_linton_M_sweep:InvalidOptionName', ...
      'Option names must be character vectors or strings.');
  end
  key = lower(strrep(strrep(strtrim(name), '_', ''), '-', ''));
end

%% ==================== Linton case helper ====================
% This helper stores the lightweight single-point case used for the sweep.

function c = LOCAL_linton_table4_case()
  c = struct();
  c.table = 4;
  c.d = 1;
  c.kd = 2;
  c.betad = 3;
  c.X_linton = 0;
  c.Y_linton = 0.01;
  c.reference = -0.7617463954 - 0.0006387129177i;
  c.ewald = struct('a', 2, 'M1', 3, 'M2', 2, 'N', 7);
end

%% ==================== Reporting helper ====================
% These helpers print and save compact tabular outputs.

function row = LOCAL_empty_row()
  row = struct('M', NaN, 'N_proxy', NaN, ...
    'number_of_rayleigh_modes', NaN, 'number_of_unknowns', NaN, ...
    'number_of_collocation_equations', NaN, ...
    'abs_error_against_reference', NaN, ...
    'rel_error_against_reference', NaN, ...
    'least_squares_residual', NaN, ...
    'relative_least_squares_residual', NaN, ...
    'cond_estimate', NaN, 'rcond_estimate', NaN, ...
    'runtime_seconds', NaN, 'precomp_time', NaN, ...
    'eval_time', NaN, 'mfs_value', NaN);
end

function LOCAL_print_rows(rows)
  fprintf('%5s %8s %8s %8s %8s %14s %14s %14s %12s %12s\n', ...
    'M', 'Nproxy', 'Nmodes', 'Nunk', 'Neq', 'abs err', 'rel err', ...
    'LS residual', 'rcond', 'time(s)');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf('%5d %8d %8d %8d %8d %14.6e %14.6e %14.6e %12.3e %12.6f\n', ...
      r.M, r.N_proxy, r.number_of_rayleigh_modes, r.number_of_unknowns, ...
      r.number_of_collocation_equations, r.abs_error_against_reference, ...
      r.rel_error_against_reference, r.least_squares_residual, ...
      r.rcond_estimate, r.runtime_seconds);
  end
end

function LOCAL_write_csv(csv_path, rows)
  fid = fopen(csv_path, 'w');
  if fid < 0
    error('qpgreen_linton_M_sweep:CsvOpenFailed', ...
      'Could not write CSV file %s.', csv_path);
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, ['M,N_proxy,number_of_rayleigh_modes,number_of_unknowns,', ...
    'number_of_collocation_equations,abs_error_against_reference,', ...
    'rel_error_against_reference,least_squares_residual,', ...
    'relative_least_squares_residual,cond_estimate,rcond_estimate,', ...
    'runtime_seconds,precomp_time,eval_time,real_mfs_value,imag_mfs_value\n']);
  for j = 1:numel(rows)
    r = rows(j);
    fprintf(fid, ['%d,%d,%d,%d,%d,%.16e,%.16e,%.16e,%.16e,', ...
      '%.16e,%.16e,%.16e,%.16e,%.16e,%.16e,%.16e\n'], ...
      r.M, r.N_proxy, r.number_of_rayleigh_modes, r.number_of_unknowns, ...
      r.number_of_collocation_equations, r.abs_error_against_reference, ...
      r.rel_error_against_reference, r.least_squares_residual, ...
      r.relative_least_squares_residual, r.cond_estimate, ...
      r.rcond_estimate, r.runtime_seconds, r.precomp_time, r.eval_time, ...
      real(r.mfs_value), imag(r.mfs_value));
  end

  clear cleaner;
end

function LOCAL_write_figure(figure_path, rows)
  M = [rows.M];
  abs_error = [rows.abs_error_against_reference];
  residual = [rows.least_squares_residual];

  fig = figure('Visible', 'off');
  semilogy(M, abs_error, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
  hold on;
  semilogy(M, residual, '--s', 'LineWidth', 1.1, 'MarkerSize', 4);
  hold off;
  grid on;
  xlabel('Rayleigh half-truncation M');
  ylabel('error / residual');
  legend({'|G_{MFS}-G_{Ewald}|', 'least-squares residual'}, ...
    'Location', 'northeast');
  title('Linton Table 4 M-sweep, N_{proxy}=320');
  print(fig, figure_path, '-dpdf');
  close(fig);
  LOCAL_make_pdf_compatible(figure_path);
end

function s = LOCAL_cplx(z)
  s = sprintf('%.10g%+.10gi', real(z), imag(z));
end

function LOCAL_make_pdf_compatible(figure_path)
  [status, ~] = system('command -v gs');
  if status ~= 0
    return;
  end

  tmp_path = [tempname(), '.pdf'];
  cmd = sprintf(['gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite ', ...
    '-dCompatibilityLevel=1.5 -sOutputFile="%s" "%s"'], ...
    tmp_path, figure_path);
  status = system(cmd);
  if status == 0 && exist(tmp_path, 'file')
    movefile(tmp_path, figure_path, 'f');
  elseif exist(tmp_path, 'file')
    delete(tmp_path);
  end
end
