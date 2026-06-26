function results = qpgreen_mfs_vs_ewald_grid(varargin)
% QPGREEN_MFS_VS_EWALD_GRID Compare MFS and Ewald qpgreen on a cell grid.
%
% Purpose:
%   Evaluates the project x-periodic MFS quasi-periodic Green function and a
%   benchmark Ewald implementation on a uniform cell grid, excluding the
%   source singularity, and saves contour plots of values and errors.
%
% Main algorithm:
%   Builds a grid on
%     [-d/2,d/2] x [-H,H],
%   removes targets whose periodic distance to the source is below
%   source_exclusion_radius, evaluates both Green functions at the remaining
%   targets, and computes
%     rel_error = abs(MFS - Ewald) / max(abs(Ewald), rel_floor).
%
% Based on:
%   +kernel/qpgreen_mfs.m, +kernel/precomp_proxy.m, and the benchmark
%   Ewald helper qpgreen_ewald_xperiodic_bench.m.
%
% Main changes:
%   This is a new benchmark entry point only.  It stores generated data and
%   figures under benchmark/output without changing package code.
%
% Numerical goal:
%   Reveal pointwise agreement and spatial error structure between MFS and
%   Ewald quasi-periodic Green function values inside one periodic cell.  By
%   default this benchmark writes only a Markdown report; set SaveMat to true
%   to retain full arrays, or GenerateFigures to true to save contour plots.

  bench_dir = fileparts(mfilename('fullpath'));
  repo_root = fileparts(bench_dir);
  addpath(repo_root);
  addpath(bench_dir);

  opts = qpgreen_bench_defaults(varargin{:});
  timestamp = datestr(now, 'yyyymmdd_HHMMSS');
  output_dir = opts.OutputRoot;
  figure_dir = fullfile(output_dir, 'figures');
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end
  if opts.GenerateFigures && ~exist(figure_dir, 'dir')
    mkdir(figure_dir);
  end

  % --- stage 1: set parameters and build the uniform cell grid ---
  x = linspace(-opts.d/2, opts.d/2, opts.Nx);
  y = linspace(-opts.H, opts.H, opts.Ny);
  [X, Y] = meshgrid(x, y);

  dx_step = LOCAL_grid_step(x);
  dy_step = LOCAL_grid_step(y);
  if isempty(opts.SourceExclusionRadius)
    source_exclusion_radius = max(1e-10, 0.25 * min(dx_step, dy_step));
  else
    source_exclusion_radius = opts.SourceExclusionRadius;
  end

  dx_periodic = X - opts.xs;
  dx_periodic = dx_periodic - round(dx_periodic / opts.d) * opts.d;
  dy_transverse = Y - opts.ys;
  source_distance = sqrt(dx_periodic.^2 + dy_transverse.^2);
  valid_mask = source_distance > source_exclusion_radius;

  src = [opts.xs; opts.ys];
  trg = [X(valid_mask).'; Y(valid_mask).'];

  % --- stage 2: evaluate Ewald and MFS on all nonsingular grid points ---
  pars1 = struct('k', opts.k, 'beta', opts.beta, 'd', opts.d);
  ewald_pars2 = struct('a', opts.EwaldA, 'M1', opts.EwaldM1, ...
    'M2', opts.EwaldM2, 'N', opts.EwaldN, ...
    'grazing_tol', opts.GrazingTolerance);

  t_ewald = tic;
  [ewald_valid, ewald_aux] = qpgreen_ewald_xperiodic_bench(src, trg, pars1, ...
    ewald_pars2);
  ewald_time = toc(t_ewald);

  t_mfs = tic;
  [mfs_valid, mfs_aux] = qpgreen_mfs_eval_bench(src, trg, opts);
  mfs_time = toc(t_mfs);

  ewald_grid = NaN(size(X));
  mfs_grid = NaN(size(X));
  ewald_grid(valid_mask) = ewald_valid;
  mfs_grid(valid_mask) = mfs_valid;

  % --- stage 3: compute absolute and relative error statistics ---
  abs_error = abs(mfs_grid - ewald_grid);
  rel_error = abs_error ./ max(abs(ewald_grid), opts.RelFloor);
  finite_error = isfinite(abs_error) & valid_mask;

  stats = struct();
  stats.max_abs_error = max(abs_error(finite_error));
  stats.median_abs_error = median(abs_error(finite_error));
  stats.rms_abs_error = sqrt(mean(abs_error(finite_error).^2));
  stats.max_rel_error = max(rel_error(finite_error));
  stats.valid_point_count = nnz(finite_error);
  stats.excluded_point_count = numel(valid_mask) - nnz(valid_mask);
  stats.total_point_count = numel(valid_mask);
  stats.ewald_time = ewald_time;
  stats.mfs_time = mfs_time;
  stats.mfs_precomp_time = mfs_aux.precomp_time;
  stats.mfs_eval_time = mfs_aux.eval_time;

  LOCAL_print_stats(opts, source_exclusion_radius, stats);

  % --- stage 4: optionally save contour figures, then write the report ---
  figure_paths = struct();
  if opts.GenerateFigures
    figure_paths.real_ewald = LOCAL_save_contour(X, Y, real(ewald_grid), src, ...
      'real(Ewald)', fullfile(figure_dir, ...
      ['qpgreen_grid_real_ewald_', timestamp, '.png']));
    figure_paths.real_mfs = LOCAL_save_contour(X, Y, real(mfs_grid), src, ...
      'real(MFS)', fullfile(figure_dir, ...
      ['qpgreen_grid_real_mfs_', timestamp, '.png']));
    figure_paths.log_abs_error = LOCAL_save_contour(X, Y, ...
      LOCAL_safe_log10(abs_error), src, 'log10(abs error)', fullfile(figure_dir, ...
      ['qpgreen_grid_logerr_', timestamp, '.png']));
    figure_paths.abs_ewald = LOCAL_save_contour(X, Y, abs(ewald_grid), src, ...
      'abs(Ewald)', fullfile(figure_dir, ...
      ['qpgreen_grid_abs_ewald_', timestamp, '.png']));
    figure_paths.abs_mfs = LOCAL_save_contour(X, Y, abs(mfs_grid), src, ...
      'abs(MFS)', fullfile(figure_dir, ...
      ['qpgreen_grid_abs_mfs_', timestamp, '.png']));
    figure_paths.log_rel_error = LOCAL_save_contour(X, Y, ...
      LOCAL_safe_log10(rel_error), src, 'log10(rel error)', fullfile(figure_dir, ...
      ['qpgreen_grid_logrelerr_', timestamp, '.png']));
  end

  results = struct();
  results.options = opts;
  results.timestamp = timestamp;
  results.source_exclusion_radius = source_exclusion_radius;
  results.x = x;
  results.y = y;
  results.X = X;
  results.Y = Y;
  results.valid_mask = valid_mask;
  results.ewald = ewald_grid;
  results.mfs = mfs_grid;
  results.abs_error = abs_error;
  results.rel_error = rel_error;
  results.stats = stats;
  results.figure_paths = figure_paths;
  results.ewald_aux = ewald_aux;
  results.mfs_params = mfs_aux.pars2;

  summary_path = fullfile(output_dir, ...
    ['qpgreen_mfs_vs_ewald_grid_', timestamp, '.md']);
  LOCAL_write_summary(summary_path, results, ewald_pars2);
  results.summary_path = summary_path;

  mat_path = '';
  if opts.SaveMat
    mat_path = fullfile(output_dir, ...
      ['qpgreen_mfs_vs_ewald_grid_', timestamp, '.mat']);
    save(mat_path, 'results');
    results.mat_path = mat_path;
  else
    results.mat_path = '';
  end

  fprintf('Saved Markdown report: %s\n', summary_path);
  if opts.SaveMat
    fprintf('Saved MAT results: %s\n', mat_path);
  else
    fprintf('MAT results not saved. Set SaveMat=true to retain full arrays.\n');
  end
  if opts.GenerateFigures
    fprintf('Saved figures under: %s\n\n', figure_dir);
  else
    fprintf('Figures not generated. Set GenerateFigures=true to save contour plots.\n\n');
  end
end

%% ==================== Grid helper ====================
% These helpers keep grid spacing and logarithmic error maps well-defined.

function h = LOCAL_grid_step(v)
  if numel(v) < 2
    h = Inf;
  else
    h = min(abs(diff(v)));
  end
end

function zlog = LOCAL_safe_log10(z)
  zlog = NaN(size(z));
  idx = isfinite(z) & z > 0;
  zlog(idx) = log10(max(z(idx), realmin));
end

%% ==================== Reporting helper ====================
% This helper prints the scalar error summary requested by the benchmark.

function LOCAL_print_stats(opts, source_exclusion_radius, stats)
  fprintf('\nqpgreen MFS vs Ewald grid benchmark\n');
  fprintf('  k = %.12g, beta = %.12g, d = %.12g, H = %.12g\n', ...
    opts.k, opts.beta, opts.d, opts.H);
  fprintf('  grid = %d x %d, source = (%.12g, %.12g)\n', ...
    opts.Nx, opts.Ny, opts.xs, opts.ys);
  fprintf('  source_exclusion_radius = %.6e\n', source_exclusion_radius);
  fprintf('  valid points = %d, excluded source-near points = %d, total = %d\n', ...
    stats.valid_point_count, stats.excluded_point_count, stats.total_point_count);
  fprintf('  max abs error    = %.6e\n', stats.max_abs_error);
  fprintf('  median abs error = %.6e\n', stats.median_abs_error);
  fprintf('  RMS abs error    = %.6e\n', stats.rms_abs_error);
  fprintf('  max rel error    = %.6e\n', stats.max_rel_error);
  fprintf('  Ewald runtime    = %.6f s\n', stats.ewald_time);
  fprintf('  MFS runtime      = %.6f s (precomp %.6f s, eval %.6f s)\n\n', ...
    stats.mfs_time, stats.mfs_precomp_time, stats.mfs_eval_time);
end

function LOCAL_write_summary(summary_path, results, ewald_pars2)
  fid = fopen(summary_path, 'w');
  if fid < 0
    warning('qpgreen_mfs_vs_ewald_grid:SummaryOpenFailed', ...
      'Could not write summary file %s.', summary_path);
    return;
  end
  cleaner = onCleanup(@() fclose(fid));

  opts = results.options;
  stats = results.stats;
  mfs_pars = results.mfs_params;
  n_proxy_total = 4 * mfs_pars.N_proxy_edge;
  n_pw_total = 2 * mfs_pars.M_pw + 1;
  n_unknowns = n_proxy_total + 2 * n_pw_total;
  n_equations = 2 * mfs_pars.N_side + 4 * mfs_pars.N_top;

  fprintf(fid, '# qpgreen MFS vs Ewald Grid Benchmark\n\n');
  fprintf(fid, '- Timestamp: `%s`\n', results.timestamp);
  fprintf(fid, '- Output mode: Markdown report only by default\n');
  fprintf(fid, '- SaveMat: `%d`\n', opts.SaveMat);
  fprintf(fid, '- GenerateFigures: `%d`\n\n', opts.GenerateFigures);

  fprintf(fid, '## Reproducibility Parameters\n\n');
  fprintf(fid, '| Parameter | Value |\n');
  fprintf(fid, '|---|---:|\n');
  fprintf(fid, '| k | %.16g |\n', opts.k);
  fprintf(fid, '| beta | %.16g |\n', opts.beta);
  fprintf(fid, '| d | %.16g |\n', opts.d);
  fprintf(fid, '| H | %.16g |\n', opts.H);
  fprintf(fid, '| source x | %.16g |\n', opts.xs);
  fprintf(fid, '| source y | %.16g |\n', opts.ys);
  fprintf(fid, '| Nx | %d |\n', opts.Nx);
  fprintf(fid, '| Ny | %d |\n', opts.Ny);
  fprintf(fid, '| source exclusion radius | %.16e |\n', results.source_exclusion_radius);
  fprintf(fid, '| relative error floor | %.16e |\n\n', opts.RelFloor);

  fprintf(fid, '## Ewald Parameters\n\n');
  fprintf(fid, '| Parameter | Value |\n');
  fprintf(fid, '|---|---:|\n');
  fprintf(fid, '| a | %.16g |\n', ewald_pars2.a);
  fprintf(fid, '| M1 spectral truncation | %d |\n', ewald_pars2.M1);
  fprintf(fid, '| M2 spatial-image truncation | %d |\n', ewald_pars2.M2);
  fprintf(fid, '| N expansion truncation | %d |\n', ewald_pars2.N);
  fprintf(fid, '| grazing tolerance | %.16e |\n\n', ewald_pars2.grazing_tol);

  fprintf(fid, '## MFS Parameters\n\n');
  fprintf(fid, '| Parameter | Value |\n');
  fprintf(fid, '|---|---:|\n');
  fprintf(fid, '| H | %.16g |\n', mfs_pars.H);
  fprintf(fid, '| proxy distance | %.16g |\n', mfs_pars.proxy_dist);
  fprintf(fid, '| requested Nproxy | %d |\n', opts.Nproxy);
  fprintf(fid, '| proxy sources per edge | %d |\n', mfs_pars.N_proxy_edge);
  fprintf(fid, '| actual proxy source count | %d |\n', n_proxy_total);
  fprintf(fid, '| Rayleigh half-truncation M | %d |\n', mfs_pars.M_pw);
  fprintf(fid, '| Rayleigh mode count 2M+1 | %d |\n', n_pw_total);
  fprintf(fid, '| side collocation points N_side | %d |\n', mfs_pars.N_side);
  fprintf(fid, '| top/bottom collocation points N_top | %d |\n', mfs_pars.N_top);
  fprintf(fid, '| least-squares equations | %d |\n', n_equations);
  fprintf(fid, '| least-squares unknowns | %d |\n\n', n_unknowns);

  fprintf(fid, '## Error Summary\n\n');
  fprintf(fid, '| Statistic | Value |\n');
  fprintf(fid, '|---|---:|\n');
  fprintf(fid, '| valid grid points | %d |\n', stats.valid_point_count);
  fprintf(fid, '| source-excluded grid points | %d |\n', stats.excluded_point_count);
  fprintf(fid, '| total grid points | %d |\n', stats.total_point_count);
  fprintf(fid, '| max abs error | %.16e |\n', stats.max_abs_error);
  fprintf(fid, '| median abs error | %.16e |\n', stats.median_abs_error);
  fprintf(fid, '| RMS abs error | %.16e |\n', stats.rms_abs_error);
  fprintf(fid, '| max rel error | %.16e |\n\n', stats.max_rel_error);

  fprintf(fid, '## Runtime Summary\n\n');
  fprintf(fid, '| Timing | Seconds |\n');
  fprintf(fid, '|---|---:|\n');
  fprintf(fid, '| Ewald total evaluation time | %.6f |\n', stats.ewald_time);
  fprintf(fid, '| MFS total time | %.6f |\n', stats.mfs_time);
  fprintf(fid, '| MFS proxy/Rayleigh precomputation time | %.6f |\n', stats.mfs_precomp_time);
  fprintf(fid, '| MFS grid evaluation time after precomputation | %.6f |\n', stats.mfs_eval_time);
  fprintf(fid, '| MFS total / Ewald total | %.6f |\n', stats.mfs_time / stats.ewald_time);
  fprintf(fid, '| MFS eval-only / Ewald total | %.6f |\n', stats.mfs_eval_time / stats.ewald_time);
  fprintf(fid, '| Ewald time per valid point | %.16e |\n', ...
    stats.ewald_time / stats.valid_point_count);
  fprintf(fid, '| MFS eval time per valid point | %.16e |\n\n', ...
    stats.mfs_eval_time / stats.valid_point_count);

  if opts.GenerateFigures
    fprintf(fid, '## Figure Files\n\n');
    figure_names = fieldnames(results.figure_paths);
    for j = 1:numel(figure_names)
      name = figure_names{j};
      fprintf(fid, '- `%s`: `%s`\n', name, results.figure_paths.(name));
    end
    fprintf(fid, '\n');
  end

  clear cleaner;
end

%% ==================== Plotting helper ====================
% This helper creates offscreen contour figures and marks the source point.

function path_out = LOCAL_save_contour(X, Y, Z, src, title_text, path_out)
  fig = figure('Visible', 'off');
  cleaner = onCleanup(@() close(fig));
  contourf(X, Y, Z, 30, 'LineStyle', 'none');
  colorbar;
  hold on;
  plot(src(1), src(2), 'kp', 'MarkerFaceColor', 'w', 'MarkerSize', 9);
  hold off;
  axis equal tight;
  xlabel('x periodic separation');
  ylabel('y transverse separation');
  title(title_text, 'Interpreter', 'none');
  set(gca, 'Layer', 'top');
  print(fig, path_out, '-dpng', '-r180');
  clear cleaner;
end
