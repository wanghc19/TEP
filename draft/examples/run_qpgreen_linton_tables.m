% RUN_QPGREEN_LINTON_TABLES Compare y-quasiperiodic MFS and Ewald values.
%
% Purpose:
%   Runs the three single-point quasiperiodic Green-function checks using
%   the parameter choices from Tables 2--4 of Linton (1998).
%
% Main algorithm:
%   Evaluates the physical y-quasiperiodic Green function by the project MFS
%   implementation.  The Ewald reference is evaluated by swapping physical
%   coordinates into the existing x-periodic Ewald benchmark helper.
%
% Based on:
%   +kernel/qpgreen_mfs.m, +kernel/precomp_proxy.m, and
%   benchmark/qpgreen/qpgreen_ewald_xperiodic_bench.m.
%
% Main changes:
%   Provides a draft/examples entry point for the manuscript.  It does not
%   modify the qpgreen implementation, benchmark parameters, or mathematical
%   model.
%
% Numerical goal:
%   Reproduce the single-point y-quasiperiodic MFS checks reported in
%   Section 6.1.

% --- stage 1: set paths and benchmark parameters ---
script_dir = fileparts(mfilename('fullpath'));
draft_dir = fileparts(script_dir);
repo_root = fileparts(draft_dir);
bench_dir = fullfile(repo_root, 'benchmark', 'qpgreen');
output_dir = fullfile(script_dir, 'output');

addpath(repo_root);
addpath(bench_dir);

if ~exist(output_dir, 'dir')
  mkdir(output_dir);
end

mfs_opts = struct();
mfs_opts.H = 0.6;
mfs_opts.M = 16;
mfs_opts.Nproxy = 160;
mfs_opts.ProxyDist = 0.15;
mfs_opts.NSide = 160;
mfs_opts.NTop = 160;
mfs_opts.RelFloor = 1e-14;

cases = LOCAL_linton_cases();
rows = repmat(struct(), 1, numel(cases));

% --- stage 2: evaluate MFS and Ewald values at the three table points ---
for icase = 1:numel(cases)
  c = cases(icase);

  pars1_mfs = struct();
  pars1_mfs.k = c.kd / c.d;
  pars1_mfs.beta = c.betad / c.d;
  pars1_mfs.d = c.d;
  pars1_mfs.periodic_axis = 'y';

  pars2_mfs = LOCAL_mfs_options(mfs_opts);
  src = [0; 0];
  trg = [c.X_linton * c.d; c.Y_linton * c.d];

  t_precomp = tic;
  proxy = kernel.precomp_proxy(pars1_mfs, pars2_mfs);
  mfs_precomp_time = toc(t_precomp);

  t_mfs_eval = tic;
  mfs_data = kernel.qpgreen_mfs(src, trg, pars1_mfs, proxy);
  mfs_eval_time = toc(t_mfs_eval);
  mfs_value = mfs_data.pot;

  pars1_ewald = struct('k', pars1_mfs.k, 'beta', pars1_mfs.beta, ...
    'd', pars1_mfs.d);
  pars2_ewald = c.ewald;
  pars2_ewald.grazing_tol = 1e-12;

  src_comp = src([2 1], :);
  trg_comp = trg([2 1], :);
  t_ewald = tic;
  [ewald_value, ewald_aux] = qpgreen_ewald_xperiodic_bench(src_comp, ...
    trg_comp, pars1_ewald, pars2_ewald);
  ewald_time = toc(t_ewald);

  abs_err = abs(mfs_value - ewald_value);
  rel_err = abs_err / max(abs(ewald_value), mfs_opts.RelFloor);

  rows(icase).table = c.table;
  rows(icase).kd = c.kd;
  rows(icase).betad = c.betad;
  rows(icase).X_linton_over_d = c.X_linton;
  rows(icase).Y_linton_over_d = c.Y_linton;
  rows(icase).mfs_value = mfs_value;
  rows(icase).ewald_value = ewald_value;
  rows(icase).abs_err_mfs_vs_ewald = abs_err;
  rows(icase).rel_err_mfs_vs_ewald = rel_err;
  rows(icase).ewald_time = ewald_time;
  rows(icase).mfs_precomp_time = mfs_precomp_time;
  rows(icase).mfs_eval_time = mfs_eval_time;
  rows(icase).mfs_total_time = mfs_precomp_time + mfs_eval_time;
  rows(icase).mfs_params = pars2_mfs;
  rows(icase).ewald_params = c.ewald;
  rows(icase).ewald_aux = ewald_aux;
end

% --- stage 3: print and save a compact report ---
LOCAL_print_rows(rows);

results = struct();
results.rows = rows;
results.mfs_options = mfs_opts;
results.timestamp = datestr(now, 'yyyymmdd_HHMMSS');
results.note = ['Physical y-quasiperiodic MFS values are compared with ', ...
  'an Ewald reference obtained by coordinate swapping.'];

mat_path = fullfile(output_dir, ['qpgreen_linton_tables_', ...
  results.timestamp, '.mat']);
md_path = fullfile(output_dir, ['qpgreen_linton_tables_', ...
  results.timestamp, '.md']);
save(mat_path, 'results');
LOCAL_write_markdown(md_path, rows, results);

fprintf('\nSaved MAT results: %s\n', mat_path);
fprintf('Saved summary:     %s\n', md_path);

%% ==================== Table data helper ====================
% This helper stores the parameter choices from Linton Tables 2--4.

function cases = LOCAL_linton_cases()
  cases = repmat(struct(), 1, 3);

  cases(1).table = 2;
  cases(1).d = 1;
  cases(1).kd = 2;
  cases(1).betad = sqrt(2);
  cases(1).X_linton = 0;
  cases(1).Y_linton = 0.01;
  cases(1).ewald = struct('a', 2, 'M1', 3, 'M2', 2, 'N', 7);

  cases(2).table = 3;
  cases(2).d = 1;
  cases(2).kd = 10;
  cases(2).betad = 5 * sqrt(2);
  cases(2).X_linton = 0;
  cases(2).Y_linton = 0.01;
  cases(2).ewald = struct('a', 2, 'M1', 4, 'M2', 2, 'N', 28);

  cases(3).table = 4;
  cases(3).d = 1;
  cases(3).kd = 2;
  cases(3).betad = 3;
  cases(3).X_linton = 0;
  cases(3).Y_linton = 0.01;
  cases(3).ewald = struct('a', 2, 'M1', 3, 'M2', 2, 'N', 7);
end

%% ==================== MFS parameter helper ====================
% This helper translates manuscript parameters to kernel.precomp_proxy fields.

function pars2 = LOCAL_mfs_options(opts)
  pars2 = struct();
  pars2.H = opts.H;
  pars2.proxy_dist = opts.ProxyDist;
  pars2.N_side = opts.NSide;
  pars2.N_top = opts.NTop;
  pars2.N_proxy_edge = ceil(opts.Nproxy / 4);
  pars2.M_pw = opts.M;
end

%% ==================== Reporting helper ====================
% These helpers print and save compact benchmark summaries.

function LOCAL_print_rows(rows)
  fprintf('\ny-quasiperiodic Green function: Linton parameter points\n');
  fprintf('%5s %10s %12s %10s %10s %13s %13s %10s %10s\n', ...
    'Table', 'kd', 'beta*d', 'X/d', 'Y/d', 'abs err', 'rel err', ...
    'tEwald', 'tMFS');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf('%5d %10.6g %12.6g %10.4g %10.4g %13.6e %13.6e %10.4g %10.4g\n', ...
      r.table, r.kd, r.betad, r.X_linton_over_d, r.Y_linton_over_d, ...
      r.abs_err_mfs_vs_ewald, r.rel_err_mfs_vs_ewald, ...
      r.ewald_time, r.mfs_total_time);
  end
end

function LOCAL_write_markdown(md_path, rows, results)
  fid = fopen(md_path, 'w');
  if fid < 0
    warning('run_qpgreen_linton_tables:SummaryOpenFailed', ...
      'Could not write summary file %s.', md_path);
    return;
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, '# qpgreen Linton Parameter Benchmark\n\n');
  fprintf(fid, '- Timestamp: `%s`\n', results.timestamp);
  fprintf(fid, '- %s\n\n', results.note);
  fprintf(fid, '| Table | kd | beta*d | X/d | Y/d | MFS value | Ewald value | abs(MFS-Ewald) | rel(MFS-Ewald) | Ewald time (s) | MFS total time (s) | MFS precomp (s) | MFS eval (s) |\n');
  fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf(fid, '| %d | %.12g | %.12g | %.12g | %.12g | `%s` | `%s` | %.16e | %.16e | %.6f | %.6f | %.6f | %.6f |\n', ...
      r.table, r.kd, r.betad, r.X_linton_over_d, r.Y_linton_over_d, ...
      LOCAL_cplx(r.mfs_value), LOCAL_cplx(r.ewald_value), ...
      r.abs_err_mfs_vs_ewald, r.rel_err_mfs_vs_ewald, ...
      r.ewald_time, r.mfs_total_time, r.mfs_precomp_time, r.mfs_eval_time);
  end

  clear cleaner;
end

function s = LOCAL_cplx(z)
  s = sprintf('%.10g%+.10gi', real(z), imag(z));
end
