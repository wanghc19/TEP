% RUN_QPGREEN_TABLE2_GRID_ERROR Plot grid error for the y-quasiperiodic Green function.
%
% Purpose:
%   Uses the Table 2 parameter choice from Linton (1998) to compare the
%   y-quasiperiodic MFS Green function against an Ewald reference on a
%   two-dimensional grid.
%
% Main algorithm:
%   Builds a grid in the physical y-periodic cell, evaluates the MFS Green
%   function and an Ewald reference away from the source singularity, computes
%   \(|G_{\mathrm{MFS}}-G_{\mathrm{Ewald}}|\), and saves a log-error image.
%
% Based on:
%   draft/examples/run_qpgreen_linton_tables.m and
%   benchmark/qpgreen/qpgreen_mfs_vs_ewald_grid.m.
%
% Main changes:
%   This manuscript script uses physical y-periodicity, compares against the
%   shared Ewald benchmark evaluator, and writes a fixed figure file under
%   draft/figs for inclusion in Section 6.1.
%
% Numerical goal:
%   Show the spatial distribution of the MFS/Ewald pointwise error for the
%   Table 2 parameter set.

% --- stage 1: set paths and output file ---
script_dir = fileparts(mfilename('fullpath'));
draft_dir = fileparts(script_dir);
repo_root = fileparts(draft_dir);
bench_dir = fullfile(repo_root, 'benchmark', 'qpgreen');
fig_dir = fullfile(draft_dir, 'figs');

addpath(repo_root);
addpath(bench_dir);

if ~exist(fig_dir, 'dir')
  mkdir(fig_dir);
end

fig_path = fullfile(fig_dir, 'qpgreen_table2_grid_logerr.png');

% --- stage 2: set Table 2, MFS, Ewald, and grid parameters ---
d = 1;
kd = 2;
betad = sqrt(2);
k = kd / d;
beta = betad / d;
src = [0; 0];

H = 0.6;                 % Half-width in the non-periodic physical x direction.
M = 16;                  % Rayleigh half-truncation.
N_proxy = 160;           % Total proxy sources on the enclosing proxy box.
proxy_dist = 0.15;       % Offset from the matching box to the proxy box.
N_side = 160;            % Collocation points on each periodic boundary.
N_top = 160;             % Collocation points on each artificial vertical boundary.

ewald = struct();
ewald.a = 2;
ewald.M1 = 3;
ewald.M2 = 2;
ewald.N = 7;
ewald.grazing_tol = 1e-12;

Nx = 101;                % Grid points in physical x.
Ny = 81;                 % Grid points in physical y.
rel_floor = 1e-14;

% --- stage 3: build the physical y-periodic grid ---
x = linspace(-H, H, Nx);
y = linspace(-d/2, d/2, Ny);
[X, Y] = meshgrid(x, y);

dx = X - src(1);
dy_periodic = Y - src(2);
dy_periodic = dy_periodic - round(dy_periodic / d) * d;
source_distance = sqrt(dx.^2 + dy_periodic.^2);
source_exclusion_radius = 0.25 * min(LOCAL_grid_step(x), LOCAL_grid_step(y));
valid_mask = source_distance > source_exclusion_radius;

trg = [X(valid_mask).'; Y(valid_mask).'];

% --- stage 4: evaluate MFS and Ewald on nonsingular grid points ---
pars1_mfs = struct();
pars1_mfs.k = k;
pars1_mfs.beta = beta;
pars1_mfs.d = d;
pars1_mfs.periodic_axis = 'y';

pars2_mfs = struct();
pars2_mfs.H = H;
pars2_mfs.proxy_dist = proxy_dist;
pars2_mfs.N_side = N_side;
pars2_mfs.N_top = N_top;
pars2_mfs.N_proxy_edge = ceil(N_proxy / 4);
pars2_mfs.M_pw = M;

t_precomp = tic;
proxy = kernel.precomp_proxy(pars1_mfs, pars2_mfs);
mfs_precomp_time = toc(t_precomp);

t_mfs_eval = tic;
mfs_data = kernel.qpgreen_mfs(src, trg, pars1_mfs, proxy);
mfs_eval_time = toc(t_mfs_eval);

pars1_ewald = struct('k', k, 'beta', beta, 'd', d);
src_comp = src([2 1], :);
trg_comp = trg([2 1], :);
t_ewald = tic;
[ewald_valid, ~] = qpgreen_ewald_xperiodic_bench(src_comp, trg_comp, ...
  pars1_ewald, ewald);
ewald_time = toc(t_ewald);

mfs_grid = NaN(size(X));
ewald_grid = NaN(size(X));
mfs_grid(valid_mask) = mfs_data.pot;
ewald_grid(valid_mask) = ewald_valid;

abs_error = abs(mfs_grid - ewald_grid);
rel_error = abs_error ./ max(abs(ewald_grid), rel_floor);
finite_error = isfinite(abs_error) & valid_mask;

max_abs_error = max(abs_error(finite_error));
median_abs_error = median(abs_error(finite_error));
rms_abs_error = sqrt(mean(abs_error(finite_error).^2));
max_rel_error = max(rel_error(finite_error));

% --- stage 5: save the log-error figure ---
fig = figure('Visible', 'off', 'Color', 'w');
imagesc(x, y, LOCAL_safe_log10(abs_error));
set(gca, 'YDir', 'normal');
axis image;
colormap(parula);
cb = colorbar;
cb.Label.String = 'log_{10}|G_{MFS}-G_{Ewald}|';
xlabel('x');
ylabel('y');
title('Table 2 y-quasiperiodic Green function grid error');
hold on;
plot(src(1), src(2), 'kx', 'MarkerSize', 8, 'LineWidth', 1.2);
hold off;
exportgraphics(fig, fig_path, 'Resolution', 240);
close(fig);

fprintf('\nTable 2 y-quasiperiodic qpgreen grid error\n');
fprintf('  figure: %s\n', fig_path);
fprintf('  valid grid points      : %d\n', nnz(finite_error));
fprintf('  excluded source points : %d\n', numel(valid_mask) - nnz(valid_mask));
fprintf('  max abs error          : %.6e\n', max_abs_error);
fprintf('  median abs error       : %.6e\n', median_abs_error);
fprintf('  RMS abs error          : %.6e\n', rms_abs_error);
fprintf('  max rel error          : %.6e\n', max_rel_error);
fprintf('  Ewald time             : %.6f s\n', ewald_time);
fprintf('  MFS time               : %.6f s (precomp %.6f s, eval %.6f s)\n', ...
  mfs_precomp_time + mfs_eval_time, mfs_precomp_time, mfs_eval_time);

%% ==================== Local helpers ====================
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
