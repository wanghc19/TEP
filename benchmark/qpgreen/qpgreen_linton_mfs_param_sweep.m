function results = qpgreen_linton_mfs_param_sweep(varargin)
% QPGREEN_LINTON_MFS_PARAM_SWEEP Tune MFS parameters on one Linton case.
%
% Purpose:
%   Runs a lightweight parameter sweep for the x-periodic MFS
%   quasi-periodic Green function using one single-point Linton table
%   comparison as the reference problem.
%
% Main algorithm:
%   Selects one Linton table case, converts Linton's y-periodic coordinates
%   to the project x-periodic convention, evaluates one Ewald reference, and
%   then loops over candidate MFS parameters:
%     H, M, Nproxy, proxy_dist, N_side, and N_top.
%   Each parameter combination is evaluated at the same source/target point,
%   and the absolute error against the Ewald reference is written to CSV and
%   Markdown summaries.
%
% Based on:
%   benchmark/qpgreen/qpgreen_linton_tables.m,
%   benchmark/qpgreen/qpgreen_mfs_eval_bench.m,
%   benchmark/qpgreen/qpgreen_ewald_xperiodic_bench.m, and Linton1998.pdf.
%
% Main changes:
%   This benchmark-only script adds a multi-parameter tuning sweep without
%   changing package qpgreen routines or the mathematical model.  The sweep
%   uses direct kernel.precomp_proxy/kernel.qpgreen_mfs calls to avoid the
%   extra SVD diagnostics used by slower reporting wrappers.
%
% Numerical goal:
%   Record all tested MFS discretization/proxy parameters and their
%   single-point absolute errors, then identify the best parameter
%   combination for the chosen Linton table case.

  bench_dir = fileparts(mfilename('fullpath'));
  repo_root = fileparts(fileparts(bench_dir));
  addpath(repo_root);
  addpath(bench_dir);

  opts = LOCAL_parse_options(varargin{:});
  if ~exist(opts.OutputRoot, 'dir')
    mkdir(opts.OutputRoot);
  end

  cases = LOCAL_linton_cases();
  case_index = find([cases.table] == opts.Table, 1);
  if isempty(case_index)
    error('qpgreen_linton_mfs_param_sweep:UnknownTable', ...
      'Table must be one of 2, 3, or 4.');
  end
  c = cases(case_index);

  src = [0; 0];
  trg = [c.Y_linton * c.d; c.X_linton * c.d];
  pars1 = struct('k', c.kd / c.d, 'beta', c.betad / c.d, ...
    'd', c.d, 'periodic_axis', 'x');
  ewald_pars2 = c.ewald;
  ewald_pars2.grazing_tol = opts.GrazingTolerance;

  t_ewald = tic;
  [ewald_value, ewald_aux] = qpgreen_ewald_xperiodic_bench(src, trg, ...
    pars1, ewald_pars2);
  ewald_time = toc(t_ewald);

  combos = LOCAL_build_combinations(opts);
  ncombo = numel(combos);
  rows = repmat(LOCAL_empty_row(), 1, ncombo);

  fprintf('\nLinton Table %d MFS parameter sweep\n', c.table);
  fprintf('Reference case: kd = %.12g, beta*d = %.12g, d = %.12g\n', ...
    c.kd, c.betad, c.d);
  fprintf('Coordinate map: (X_Linton,Y_Linton) = (%.12g, %.12g) -> (dx,dy) = (%.12g, %.12g)\n', ...
    c.X_linton, c.Y_linton, c.Y_linton, c.X_linton);
  fprintf('Ewald reference = %s, Ewald time = %.6f s\n', ...
    LOCAL_cplx(ewald_value), ewald_time);
  fprintf('Total MFS combinations = %d\n\n', ncombo);

  for j = 1:ncombo
    row = LOCAL_eval_combo(j, combos(j), pars1, src, trg, ewald_value, opts);
    rows(j) = row;
    if opts.ProgressEvery > 0 && (mod(j, opts.ProgressEvery) == 0 || j == ncombo)
      fprintf('  finished %d / %d, current abs err = %.6e\n', ...
        j, ncombo, row.abs_error_against_reference);
    end
  end

  [best_row, best_index] = LOCAL_best_row(rows);
  timestamp = datestr(now, 'yyyymmdd_HHMMSS');
  output_prefix = sprintf('%s_table%d', opts.OutputPrefix, c.table);
  csv_path = fullfile(opts.OutputRoot, [output_prefix, '.csv']);
  md_path = fullfile(opts.OutputRoot, [output_prefix, '.md']);
  mat_path = fullfile(opts.OutputRoot, [output_prefix, '.mat']);

  results = struct();
  results.timestamp = timestamp;
  results.description = 'Single-point Linton table MFS parameter sweep.';
  results.options = opts;
  results.case = c;
  results.coordinate_note = ['Linton periodic direction is Y; project ', ...
    'x-periodic coordinates use dx_periodic = Y_Linton and dy_transverse = X_Linton.'];
  results.ewald_value = ewald_value;
  results.ewald_time = ewald_time;
  results.ewald_aux = ewald_aux;
  results.rows = rows;
  results.best_index = best_index;
  results.best_row = best_row;
  results.csv_path = csv_path;
  results.md_path = md_path;
  results.mat_path = mat_path;

  LOCAL_print_summary(rows, best_row);
  LOCAL_write_csv(csv_path, rows);
  LOCAL_write_markdown(md_path, results);
  if opts.SaveMat
    save(mat_path, 'results');
  end

  fprintf('\nSaved CSV results: %s\n', csv_path);
  fprintf('Saved Markdown:    %s\n', md_path);
  if opts.SaveMat
    fprintf('Saved MAT results: %s\n', mat_path);
  end
  fprintf('\n');
end

%% ==================== Option helper ====================
% These helpers parse local sweep controls and shared benchmark options.

function opts = LOCAL_parse_options(varargin)
  local = struct();
  local.Table = 4;
  local.MList = [6, 8, 10, 12, 16, 25];
  local.HList = [0.45, 0.5, 0.6];
  local.NproxyList = [160, 240, 320];
  local.ProxyDistList = [0.15, 0.2, 0.3];
  local.CollocationList = [120, 160];
  local.NSideList = [];
  local.NTopList = [];
  local.OutputPrefix = 'linton_mfs_param_sweep';
  local.ProgressEvery = 25;
  local.SaveMat = true;

  bench_args = {};
  saw_nside_list = false;
  saw_ntop_list = false;
  if mod(numel(varargin), 2) ~= 0
    error('qpgreen_linton_mfs_param_sweep:InvalidInput', ...
      'Options must be supplied as name-value pairs.');
  end

  for j = 1:2:numel(varargin)
    name = varargin{j};
    value = varargin{j + 1};
    key = LOCAL_normalize_name(name);
    switch key
      case 'table'
        local.Table = value;
      case 'mlist'
        local.MList = value;
      case 'hlist'
        local.HList = value;
      case {'nproxylist', 'nproxytotallist'}
        local.NproxyList = value;
      case {'proxydistlist', 'proxydistancelist'}
        local.ProxyDistList = value;
      case {'collocationlist', 'ncollocationlist'}
        local.CollocationList = value;
      case {'nsidelist', 'ncollocationsidelist'}
        local.NSideList = value;
        saw_nside_list = true;
      case {'ntoplist', 'ncollocationtoplist'}
        local.NTopList = value;
        saw_ntop_list = true;
      case 'outputprefix'
        local.OutputPrefix = value;
      case 'progressevery'
        local.ProgressEvery = value;
      case {'savemat', 'keepmat'}
        local.SaveMat = value;
      otherwise
        bench_args(end+1:end+2) = varargin(j:j+1);
    end
  end

  opts = qpgreen_bench_defaults(bench_args{:});
  fields = fieldnames(local);
  for j = 1:numel(fields)
    opts.(fields{j}) = local.(fields{j});
  end

  opts.Table = double(opts.Table);
  opts.MList = LOCAL_row_vector(opts.MList);
  opts.HList = LOCAL_row_vector(opts.HList);
  opts.NproxyList = LOCAL_row_vector(opts.NproxyList);
  opts.ProxyDistList = LOCAL_row_vector(opts.ProxyDistList);
  opts.CollocationList = LOCAL_row_vector(opts.CollocationList);
  opts.NSideList = LOCAL_row_vector(opts.NSideList);
  opts.NTopList = LOCAL_row_vector(opts.NTopList);

  if ~saw_nside_list && ~saw_ntop_list
    opts.CollocationPairs = [opts.CollocationList; opts.CollocationList].';
  else
    if isempty(opts.NSideList)
      opts.NSideList = opts.CollocationList;
    end
    if isempty(opts.NTopList)
      opts.NTopList = opts.CollocationList;
    end
    [side_grid, top_grid] = ndgrid(opts.NSideList, opts.NTopList);
    opts.CollocationPairs = [side_grid(:), top_grid(:)];
  end
end

function key = LOCAL_normalize_name(name)
  if isstring(name)
    name = char(name);
  end
  if ~ischar(name)
    error('qpgreen_linton_mfs_param_sweep:InvalidOptionName', ...
      'Option names must be character vectors or strings.');
  end
  key = lower(strrep(strrep(strtrim(name), '_', ''), '-', ''));
end

function x = LOCAL_row_vector(x)
  if isempty(x)
    x = [];
  else
    x = reshape(x, 1, []);
  end
end

%% ==================== Sweep construction helper ====================
% These helpers build and evaluate the Cartesian parameter grid.

function combos = LOCAL_build_combinations(opts)
  ncombo = numel(opts.MList) * numel(opts.HList) * ...
    numel(opts.NproxyList) * numel(opts.ProxyDistList) * ...
    size(opts.CollocationPairs, 1);
  combos = repmat(struct('M', NaN, 'H', NaN, 'Nproxy', NaN, ...
    'ProxyDist', NaN, 'NSide', NaN, 'NTop', NaN), 1, ncombo);

  idx = 0;
  for H = opts.HList
    for M = opts.MList
      for Nproxy = opts.NproxyList
        for ProxyDist = opts.ProxyDistList
          for icolloc = 1:size(opts.CollocationPairs, 1)
            idx = idx + 1;
            combos(idx).M = M;
            combos(idx).H = H;
            combos(idx).Nproxy = Nproxy;
            combos(idx).ProxyDist = ProxyDist;
            combos(idx).NSide = opts.CollocationPairs(icolloc, 1);
            combos(idx).NTop = opts.CollocationPairs(icolloc, 2);
          end
        end
      end
    end
  end
end

function row = LOCAL_eval_combo(index, combo, pars1, src, trg, ewald_value, opts)
  row = LOCAL_empty_row();
  row.index = index;
  row.M = combo.M;
  row.H = combo.H;
  row.Nproxy_requested = combo.Nproxy;
  row.ProxyDist = combo.ProxyDist;
  row.N_side = combo.NSide;
  row.N_top = combo.NTop;
  row.status = 'ok';
  row.message = '';

  pars2 = LOCAL_build_proxy_options(combo);
  row.N_proxy_edge = pars2.N_proxy_edge;
  row.N_proxy_actual = 4 * pars2.N_proxy_edge;
  row.number_of_rayleigh_modes = 2 * combo.M + 1;
  row.number_of_unknowns = row.N_proxy_actual + 2 * row.number_of_rayleigh_modes;
  row.number_of_collocation_equations = 2 * combo.NSide + 4 * combo.NTop;

  try
    t_precomp = tic;
    proxy = kernel.precomp_proxy(pars1, pars2);
    row.precomp_time = toc(t_precomp);

    t_eval = tic;
    green_data = kernel.qpgreen_mfs(src, trg, pars1, proxy);
    row.eval_time = toc(t_eval);

    row.runtime_seconds = row.precomp_time + row.eval_time;
    row.mfs_value = green_data.pot;
    row.abs_error_against_reference = abs(row.mfs_value - ewald_value);
    row.rel_error_against_reference = row.abs_error_against_reference / ...
      max(abs(ewald_value), opts.RelFloor);
  catch ME
    row.status = 'failed';
    row.message = ME.message;
    row.runtime_seconds = NaN;
    row.precomp_time = NaN;
    row.eval_time = NaN;
    row.mfs_value = NaN;
    row.abs_error_against_reference = NaN;
    row.rel_error_against_reference = NaN;
  end
end

function pars2 = LOCAL_build_proxy_options(combo)
  pars2 = struct();
  pars2.H = combo.H;
  pars2.proxy_dist = combo.ProxyDist;
  pars2.N_proxy_edge = max(1, ceil(combo.Nproxy / 4));
  pars2.M_pw = combo.M;
  pars2.N_side = combo.NSide;
  pars2.N_top = combo.NTop;
end

%% ==================== Linton case helper ====================
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
% These helpers write CSV and Markdown summaries of the full sweep.

function row = LOCAL_empty_row()
  row = struct('index', NaN, 'M', NaN, 'H', NaN, ...
    'Nproxy_requested', NaN, 'N_proxy_edge', NaN, ...
    'N_proxy_actual', NaN, 'ProxyDist', NaN, ...
    'N_side', NaN, 'N_top', NaN, ...
    'number_of_rayleigh_modes', NaN, ...
    'number_of_unknowns', NaN, ...
    'number_of_collocation_equations', NaN, ...
    'mfs_value', NaN, 'abs_error_against_reference', NaN, ...
    'rel_error_against_reference', NaN, ...
    'runtime_seconds', NaN, 'precomp_time', NaN, ...
    'eval_time', NaN, 'status', '', 'message', '');
end

function [best_row, best_index] = LOCAL_best_row(rows)
  errors = [rows.abs_error_against_reference];
  errors(~isfinite(errors)) = Inf;
  [~, best_index] = min(errors);
  best_row = rows(best_index);
end

function LOCAL_print_summary(rows, best_row)
  ok_count = sum(strcmp({rows.status}, 'ok'));
  fprintf('\nSweep summary\n');
  fprintf('  successful runs: %d / %d\n', ok_count, numel(rows));
  fprintf('  best abs error:  %.6e\n', best_row.abs_error_against_reference);
  fprintf('  best rel error:  %.6e\n', best_row.rel_error_against_reference);
  fprintf(['  best params: M=%d, H=%.6g, Nproxy=%d, proxy_dist=%.6g, ', ...
    'N_side=%d, N_top=%d\n'], best_row.M, best_row.H, ...
    best_row.Nproxy_requested, best_row.ProxyDist, ...
    best_row.N_side, best_row.N_top);

  [~, order] = sort([rows.abs_error_against_reference]);
  nshow = min(10, numel(order));
  fprintf('\nTop %d parameter combinations by absolute error\n', nshow);
  fprintf('%5s %5s %8s %8s %9s %7s %7s %14s %12s\n', ...
    'rank', 'M', 'H', 'Nproxy', 'pdist', 'Nside', 'Ntop', ...
    'abs err', 'time(s)');
  for j = 1:nshow
    r = rows(order(j));
    fprintf('%5d %5d %8.3g %8d %9.3g %7d %7d %14.6e %12.6f\n', ...
      j, r.M, r.H, r.Nproxy_requested, r.ProxyDist, ...
      r.N_side, r.N_top, r.abs_error_against_reference, ...
      r.runtime_seconds);
  end
end

function LOCAL_write_csv(csv_path, rows)
  fid = fopen(csv_path, 'w');
  if fid < 0
    error('qpgreen_linton_mfs_param_sweep:CsvOpenFailed', ...
      'Could not write CSV file %s.', csv_path);
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, ['index,status,M,H,Nproxy_requested,N_proxy_edge,', ...
    'N_proxy_actual,ProxyDist,N_side,N_top,number_of_rayleigh_modes,', ...
    'number_of_unknowns,number_of_collocation_equations,', ...
    'abs_error_against_reference,rel_error_against_reference,', ...
    'runtime_seconds,precomp_time,eval_time,real_mfs_value,', ...
    'imag_mfs_value,message\n']);
  for j = 1:numel(rows)
    r = rows(j);
    fprintf(fid, ['%d,%s,%d,%.16g,%d,%d,%d,%.16g,%d,%d,%d,%d,%d,', ...
      '%.16e,%.16e,%.16e,%.16e,%.16e,%.16e,%.16e,%s\n'], ...
      r.index, r.status, r.M, r.H, r.Nproxy_requested, ...
      r.N_proxy_edge, r.N_proxy_actual, r.ProxyDist, r.N_side, ...
      r.N_top, r.number_of_rayleigh_modes, r.number_of_unknowns, ...
      r.number_of_collocation_equations, ...
      r.abs_error_against_reference, r.rel_error_against_reference, ...
      r.runtime_seconds, r.precomp_time, r.eval_time, ...
      real(r.mfs_value), imag(r.mfs_value), LOCAL_csv_string(r.message));
  end

  clear cleaner;
end

function LOCAL_write_markdown(md_path, results)
  fid = fopen(md_path, 'w');
  if fid < 0
    error('qpgreen_linton_mfs_param_sweep:MarkdownOpenFailed', ...
      'Could not write Markdown file %s.', md_path);
  end
  cleaner = onCleanup(@() fclose(fid));

  c = results.case;
  b = results.best_row;
  rows = results.rows;

  fprintf(fid, '# Linton Table %d MFS Parameter Sweep\n\n', c.table);
  fprintf(fid, '- Timestamp: `%s`\n', results.timestamp);
  fprintf(fid, '- Reference: Ewald x-periodic benchmark value `%s`\n', ...
    LOCAL_cplx(results.ewald_value));
  fprintf(fid, '- Linton table point: `X_L/d = %.12g`, `Y_L/d = %.12g`\n', ...
    c.X_linton, c.Y_linton);
  fprintf(fid, '- Project point: `dx_periodic/d = %.12g`, `dy_transverse/d = %.12g`\n', ...
    c.Y_linton, c.X_linton);
  fprintf(fid, '- Successful runs: `%d / %d`\n\n', ...
    sum(strcmp({rows.status}, 'ok')), numel(rows));

  fprintf(fid, '## Best Combination\n\n');
  fprintf(fid, '| parameter | value |\n');
  fprintf(fid, '|---|---:|\n');
  fprintf(fid, '| M | %d |\n', b.M);
  fprintf(fid, '| H | %.16g |\n', b.H);
  fprintf(fid, '| Nproxy requested | %d |\n', b.Nproxy_requested);
  fprintf(fid, '| Nproxy actual | %d |\n', b.N_proxy_actual);
  fprintf(fid, '| proxy distance | %.16g |\n', b.ProxyDist);
  fprintf(fid, '| N_side | %d |\n', b.N_side);
  fprintf(fid, '| N_top | %d |\n', b.N_top);
  fprintf(fid, '| Rayleigh modes | %d |\n', b.number_of_rayleigh_modes);
  fprintf(fid, '| unknowns | %d |\n', b.number_of_unknowns);
  fprintf(fid, '| collocation equations | %d |\n', ...
    b.number_of_collocation_equations);
  fprintf(fid, '| abs error | %.16e |\n', b.abs_error_against_reference);
  fprintf(fid, '| rel error | %.16e |\n', b.rel_error_against_reference);
  fprintf(fid, '| runtime seconds | %.6f |\n\n', b.runtime_seconds);

  [~, order] = sort([rows.abs_error_against_reference]);
  nshow = min(15, numel(order));
  fprintf(fid, '## Top %d Rows\n\n', nshow);
  fprintf(fid, '| rank | M | H | Nproxy | proxy_dist | N_side | N_top | abs error | rel error | time (s) |\n');
  fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
  for j = 1:nshow
    r = rows(order(j));
    fprintf(fid, '| %d | %d | %.6g | %d | %.6g | %d | %d | %.16e | %.16e | %.6f |\n', ...
      j, r.M, r.H, r.Nproxy_requested, r.ProxyDist, ...
      r.N_side, r.N_top, r.abs_error_against_reference, ...
      r.rel_error_against_reference, r.runtime_seconds);
  end

  fprintf(fid, '\nFull row data are in `%s`.\n', results.csv_path);
  clear cleaner;
end

function s = LOCAL_cplx(z)
  s = sprintf('%.10g%+.10gi', real(z), imag(z));
end

function s = LOCAL_csv_string(s)
  s = strrep(s, '"', '""');
  s = ['"', s, '"'];
end
