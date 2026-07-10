function run_tep_fixed_beta_timing
% RUN_TEP_FIXED_BETA_TIMING Time one-sample A_QP assembly and SVD costs.
%
% Purpose:
%   Measures the per-sample computational cost used by the fixed-beta
%   one-dimensional periodic waveguide scan in Section 6.2 of the draft.
%
% Main algorithm:
%   For one representative pair \((k,\beta)\), and for several boundary
%   discretizations \(N_{\partial\Omega}\), this function builds the star
%   geometry, precomputes the MFS proxy representation, assembles
%   \(\mathcal A=A_{\mathrm{QP}}\), and computes its singular values.  The
%   timing is repeated several times and summarized by medians.
%
% Based on:
%   draft/examples/run_tep_fixed_beta_k_scan.m and op.construct_A_QP.
%
% Main changes:
%   This timing script does not scan or refine k.  It isolates the cost of
%   one k-sample in the scan: proxy precomputation, A_QP assembly, and SVD.
%
% Numerical goal:
%   Estimate how the cost of one sigma_min(A_QP(k,beta)) evaluation scales
%   with the boundary discretization size used in the fixed-beta scan.

format long;

% --- stage 1: set paths and benchmark parameters ---
script_dir = fileparts(mfilename('fullpath'));
draft_dir = fileparts(script_dir);
repo_root = fileparts(draft_dir);
output_dir = fullfile(script_dir, 'output');

addpath(repo_root);

if ~exist(output_dir, 'dir')
  mkdir(output_dir);
end

flag_geom = 'star';                 % Inclusion geometry used in Section 6.2.
er = 13;                            % Refractive-index squared ratio.
nref = sqrt(er);                    % Interior wavenumber factor kint = nref*k.
d = 1.0;                            % Period length in the y direction of the cell.
beta = pi / d;                      % Fixed Bloch phase used in the scan.
k_test = 2.1301282065163130;        % Representative refined candidate from Table 6.2.
ntot_list = [40, 60, 80, 100];      % Boundary discretizations to time.
nrepeat = 3;                        % Repetitions per ntot; medians are reported.

pars1 = struct();
pars1.beta = beta;
pars1.d = d;

pars2 = struct();
pars2.H = 0.6 * d;                  % Half-height of the MFS matching box.
pars2.proxy_dist = 0.15 * d;        % Offset from the matching box to the proxy box.
pars2.N_side = 160;                 % Collocation points on each periodic wall.
pars2.N_top = 160;                  % Collocation points on each artificial wall.
pars2.N_proxy_edge = 40;            % Proxy sources per proxy-box edge; total 160.
pars2.M_pw = 16;                    % Rayleigh half-truncation.

mat_path = fullfile(output_dir, 'tep_fixed_beta_timing.mat');
md_path = fullfile(output_dir, 'tep_fixed_beta_timing.md');
tex_path = fullfile(output_dir, 'tep_fixed_beta_timing_table.tex');

LOCAL_validate_parameters(ntot_list, nrepeat, k_test, beta);

% --- stage 2: time one sigma_min sample for each discretization ---
rows = repmat(LOCAL_empty_row(), numel(ntot_list), 1);
for j = 1:numel(ntot_list)
  ntot = ntot_list(j);
  [C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0);
  row = LOCAL_time_one_ntot(ntot, C, curvelen, nref, pars1, pars2, ...
    k_test, nrepeat);
  rows(j) = row;
end

% --- stage 3: save and print reports ---
results = struct();
results.rows = rows;
results.flag_geom = flag_geom;
results.er = er;
results.nref = nref;
results.d = d;
results.beta = beta;
results.k_test = k_test;
results.ntot_list = ntot_list;
results.nrepeat = nrepeat;
results.pars1 = pars1;
results.pars2 = pars2;
results.note = ['Times are medians over repeated evaluations. ', ...
  'The total per-sample time excludes geometry construction.'];

save(mat_path, 'results');
LOCAL_print_rows(rows, results);
LOCAL_write_markdown(md_path, rows, results);
LOCAL_write_latex_table(tex_path, rows);

fprintf('\nSaved timing MAT file: %s\n', mat_path);
fprintf('Saved timing summary : %s\n', md_path);
fprintf('Saved LaTeX table    : %s\n', tex_path);

end

%% ==================== Timing helpers ====================
% These helpers isolate proxy, A_QP assembly, and SVD costs.

function row = LOCAL_time_one_ntot(ntot, C, curvelen, nref, pars1_base, pars2, ...
    k_test, nrepeat)

  t_proxy = zeros(nrepeat, 1);
  t_assembly = zeros(nrepeat, 1);
  t_svd = zeros(nrepeat, 1);
  sigma_min = zeros(nrepeat, 1);
  matrix_size = NaN;

  for rep = 1:nrepeat
    pars1 = pars1_base;
    pars1.k = k_test;
    kint = nref * k_test;

    timer = tic;
    proxy = kernel.precomp_proxy(pars1, pars2);
    t_proxy(rep) = toc(timer);

    timer = tic;
    A_QP = op.construct_A_QP(C, k_test, kint, pars1, proxy, curvelen);
    t_assembly(rep) = toc(timer);

    matrix_size = size(A_QP, 1);
    timer = tic;
    svals = svd(full(complex(A_QP)));
    t_svd(rep) = toc(timer);
    sigma_min(rep) = svals(end);
  end

  row = LOCAL_empty_row();
  row.ntot = ntot;
  row.matrix_size = matrix_size;
  row.proxy_time = median(t_proxy);
  row.assembly_time = median(t_assembly);
  row.svd_time = median(t_svd);
  row.total_time = median(t_proxy + t_assembly + t_svd);
  row.sigma_min = median(sigma_min);
end

function row = LOCAL_empty_row()
  row = struct('ntot', [], 'matrix_size', [], 'proxy_time', [], ...
    'assembly_time', [], 'svd_time', [], 'total_time', [], 'sigma_min', []);
end

%% ==================== Reporting helpers ====================
% These helpers print the timing output and create manuscript table snippets.

function LOCAL_print_rows(rows, results)
  fprintf('\nFixed-beta A_QP timing benchmark\n');
  fprintf('  geometry : %s\n', results.flag_geom);
  fprintf('  beta     : %.16f\n', results.beta);
  fprintf('  k        : %.16f\n', results.k_test);
  fprintf('  repeats  : %d\n\n', results.nrepeat);
  fprintf('  %-8s %-8s %-13s %-13s %-13s %-13s %-13s\n', ...
    'ntot', 'size', 'proxy', 'assembly', 'svd', 'total', 'sigma_min');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf('  %-8d %-8d %-13.6e %-13.6e %-13.6e %-13.6e %-13.6e\n', ...
      r.ntot, r.matrix_size, r.proxy_time, r.assembly_time, r.svd_time, ...
      r.total_time, r.sigma_min);
  end
end

function LOCAL_write_markdown(md_path, rows, results)
  fid = fopen(md_path, 'w');
  if fid < 0
    warning('run_tep_fixed_beta_timing:SummaryOpenFailed', ...
      'Could not open %s for writing.', md_path);
    return;
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, '# Fixed-beta A_QP Timing Benchmark\n\n');
  fprintf(fid, '- Geometry: `%s`\n', results.flag_geom);
  fprintf(fid, '- beta: `%.16f`\n', results.beta);
  fprintf(fid, '- k: `%.16f`\n', results.k_test);
  fprintf(fid, '- Repeats: `%d`\n', results.nrepeat);
  fprintf(fid, '- Note: %s\n\n', results.note);
  fprintf(fid, '| ntot | matrix size | proxy time | A_QP assembly | SVD | total | sigma_min |\n');
  fprintf(fid, '|---:|---:|---:|---:|---:|---:|---:|\n');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf(fid, '| %d | %d | %.12g | %.12g | %.12g | %.12g | %.12g |\n', ...
      r.ntot, r.matrix_size, r.proxy_time, r.assembly_time, r.svd_time, ...
      r.total_time, r.sigma_min);
  end
end

function LOCAL_write_latex_table(tex_path, rows)
  fid = fopen(tex_path, 'w');
  if fid < 0
    warning('run_tep_fixed_beta_timing:LatexOpenFailed', ...
      'Could not open %s for writing.', tex_path);
    return;
  end
  cleaner = onCleanup(@() fclose(fid));

  fprintf(fid, '\\begin{tabular}{c c c c c c c}\n');
  fprintf(fid, '  \\hline\n');
  fprintf(fid, '  $N_{\\partial\\Omega}$ & matrix size & proxy & assembly & SVD & total & $\\sigma_{\\min}$ \\\\\\n');
  fprintf(fid, '  \\hline\n');
  for j = 1:numel(rows)
    r = rows(j);
    fprintf(fid, '  %d & %d & $%.4g$ & $%.4g$ & $%.4g$ & $%.4g$ & $%.4g$ \\\\\\n', ...
      r.ntot, r.matrix_size, r.proxy_time, r.assembly_time, r.svd_time, ...
      r.total_time, r.sigma_min);
  end
  fprintf(fid, '  \\hline\n');
  fprintf(fid, '\\end{tabular}\n');
end

%% ==================== Validation helpers ====================
% These helpers catch invalid benchmark settings before timing begins.

function LOCAL_validate_parameters(ntot_list, nrepeat, k_test, beta)
  if isempty(ntot_list) || any(~isfinite(ntot_list)) || any(ntot_list <= 0) ...
      || any(mod(ntot_list, 2) ~= 0)
    error('run_tep_fixed_beta_timing:InvalidNtot', ...
      'ntot_list must contain positive even integers.');
  end
  if ~isscalar(nrepeat) || nrepeat < 1 || mod(nrepeat, 1) ~= 0
    error('run_tep_fixed_beta_timing:InvalidRepeat', ...
      'nrepeat must be a positive integer.');
  end
  if ~isscalar(k_test) || ~isfinite(k_test) || k_test <= 0
    error('run_tep_fixed_beta_timing:InvalidK', ...
      'k_test must be a positive finite scalar.');
  end
  if ~isscalar(beta) || ~isfinite(beta) || beta <= 0
    error('run_tep_fixed_beta_timing:InvalidBeta', ...
      'beta must be a positive finite scalar.');
  end
end
