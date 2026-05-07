% Purpose:
%   Run an ultra-local perturbation diagnostic around one prescribed
%   reference wavenumber k_star.
%
% Main algorithm:
%   For each boundary discretization in ntot_list, build the same geometry
%   cache used by tep_conv_local.m, then evaluate sigma_min(A_N(k)) at the
%   prescribed points k = k_star + delta for every delta in delta_list.
%   The smallest tested value, its perturbation, and the improvement ratio
%   sigma_min(A_N(k_star)) / min_delta sigma_min(A_N(k_star + delta)) are
%   reported for each ntot.
%
% Based on:
%   tep_conv_local.m.
%
% Main changes:
%   This file removes interval scanning, adaptive refinement, k_best
%   extrapolation, and ntot convergence fitting.  It keeps only the repeated
%   singular-value evaluation path needed for a fixed ultra-local k-perturbation
%   study.
%
% Numerical goal:
%   Diagnose whether a fixed-k singular-value plateau is explained by a
%   slightly inaccurate k_star, or whether tiny perturbations near k_star do
%   not significantly lower the computed singular value.
format long;
clear;

% --- 1. Parameter Setup ---
flag_geom = 'ellipse';             % Geometry type used by the boundary parametrization: 'star' or 'ellipse'
iprec = 10;                        % Alpert correction order used in the boundary integral quadrature
er = 13;                           % Relative permittivity; nref = sqrt(er) is the interior refractive index
nref = sqrt(er);
d = 1.0;                           % Period length of the waveguide cell
beta = 0.5 * 2 * pi / d;           % Fixed Bloch phase for the quasi-periodic exterior Green function

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.5 * pars1.d;           % Half-height of the fundamental domain [-H, H]
pars2.proxy_dist = 0.2 * pars1.d;  % Proxy-source offset used by precomp_proxy
pars2.N_side = 50;                 % Collocation points on each vertical side wall
pars2.N_top = 50;                  % Collocation points on each horizontal top/bottom wall
pars2.N_proxy_edge = 30;           % Proxy sources per proxy-boundary edge
pars2.M_pw = 10;                   % Plane-wave truncation order for modes -M_pw:M_pw

ntot_list = [150, 200, 250];       % Boundary discretizations used for the perturbation diagnostic
k_star = 2.6535097381199977;       % Reference wavenumber around which ultra-local shifts are tested

% Explicit perturbations added to k_star.  The default spans several tiny
% scales around zero and is sorted below before evaluation.
delta_list = [0, ...
  -1e-12, 1e-12, ...
  -3e-12, 3e-12, ...
  -1e-11, 1e-11, ...
  -3e-11, 3e-11, ...
  -1e-10, 1e-10, ...
  -3e-10, 3e-10, ...
  -1e-9, 1e-9];

flag_plot_signed_delta = true;
flag_plot_abs_delta = true;
flag_plot_best_sigma = true;

delta_list = sort(unique(delta_list(:).'));
if ~any(delta_list == 0)
  delta_list = sort([delta_list, 0]);
  fprintf('delta_list did not include zero; added delta = 0 for sigma_zero diagnostics.\n');
end

LOCAL_validate_kpert_inputs(ntot_list, k_star, delta_list);

fprintf('Ultra-local k-perturbation study for sigma_min(k)\n');
fprintf('  Geometry            : %s\n', flag_geom);
fprintf('  ntot list           : [%s]\n', num2str(ntot_list));
fprintf('  k_star              : %.16f\n', k_star);
fprintf('  delta list          : [%s]\n', num2str(delta_list, ' %.3e'));
fprintf('  Number of deltas    : %d\n', length(delta_list));

results = LOCAL_run_kpert_experiment(flag_geom, iprec, nref, pars1, pars2, ...
  ntot_list, k_star, delta_list);

LOCAL_print_kpert_summary(results);
LOCAL_plot_kpert_results(results, flag_plot_signed_delta, flag_plot_abs_delta, flag_plot_best_sigma);

fprintf('\nUltra-local k-perturbation study completed successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function results = LOCAL_run_kpert_experiment(flag_geom, iprec, nref, pars1, pars2, ...
    ntot_list, k_star, delta_list)

  ntot_list = ntot_list(:);
  delta_list = delta_list(:).';
  ncases = length(ntot_list);
  ndelta = length(delta_list);

  geometry_cache = geom.build_geometry_cache(ntot_list, flag_geom);
  k_eval_mat = repmat(k_star + delta_list, ncases, 1);
  sigma_mat = NaN(ncases, ndelta);

  for i = 1:ncases
    ntot = ntot_list(i);
    [C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);

    fprintf('\nEvaluating ntot = %d (%d perturbations)\n', ntot, ndelta);
    for j = 1:ndelta
      k_eval = k_eval_mat(i, j);
      sigma_mat(i, j) = LOCAL_get_sigma_min(k_eval, nref, C, iprec, pars1, pars2, curvelen);
      fprintf('  delta = %+.3e, k = %.16f, sigma_min = %.12e\n', ...
        delta_list(j), k_eval, sigma_mat(i, j));
    end
  end

  zero_idx = find(delta_list == 0, 1, 'first');
  [best_sigma_per_ntot, best_idx] = min(sigma_mat, [], 2);
  best_delta_per_ntot = delta_list(best_idx);
  best_delta_per_ntot = best_delta_per_ntot(:);
  sigma_at_zero_per_ntot = sigma_mat(:, zero_idx);
  improvement_ratio_per_ntot = sigma_at_zero_per_ntot ./ best_sigma_per_ntot;

  results.flag_geom = flag_geom;
  results.iprec = iprec;
  results.nref = nref;
  results.pars1 = pars1;
  results.pars2 = pars2;
  results.ntot_list = ntot_list;
  results.k_star = k_star;
  results.delta_list = delta_list;
  results.k_eval_mat = k_eval_mat;
  results.sigma_mat = sigma_mat;
  results.best_delta_per_ntot = best_delta_per_ntot;
  results.best_sigma_per_ntot = best_sigma_per_ntot;
  results.sigma_at_zero_per_ntot = sigma_at_zero_per_ntot;
  results.improvement_ratio_per_ntot = improvement_ratio_per_ntot;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_kpert_inputs(ntot_list, k_star, delta_list)

  if isempty(ntot_list) || any(~isfinite(ntot_list(:))) || ...
      any(ntot_list(:) <= 0) || any(abs(ntot_list(:) - round(ntot_list(:))) > 0)
    error('ntot_list must contain positive finite integer values.');
  end

  if ~isscalar(k_star) || ~isfinite(k_star)
    error('k_star must be a finite scalar.');
  end

  if isempty(delta_list) || any(~isfinite(delta_list(:)))
    error('delta_list must contain finite perturbation values.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_kpert_summary(results)

  fprintf('\nUltra-local perturbation summary:\n');
  fprintf('  k_star = %.16f\n', results.k_star);

  for i = 1:length(results.ntot_list)
    ntot = results.ntot_list(i);
    fprintf('\nntot = %d\n', ntot);
    fprintf('  %-16s %-22s %-20s\n', 'delta', 'k_eval', 'sigma_min');
    for j = 1:length(results.delta_list)
      fprintf('  %+16.6e %-22.16f %-20.12e\n', ...
        results.delta_list(j), results.k_eval_mat(i, j), results.sigma_mat(i, j));
    end

    fprintf('  Diagnostics:\n');
    fprintf('    sigma_zero        = %.16e\n', results.sigma_at_zero_per_ntot(i));
    fprintf('    sigma_best        = %.16e\n', results.best_sigma_per_ntot(i));
    fprintf('    best_delta        = %+.16e\n', results.best_delta_per_ntot(i));
    fprintf('    improvement_ratio = %.16e\n', results.improvement_ratio_per_ntot(i));
  end

  fprintf('\nInterpretation guide:\n');
  fprintf('  improvement_ratio close to 1 means tiny local k-shifts do not help much.\n');
  fprintf('  a large improvement_ratio means the fixed-k plateau may be caused by a slightly inaccurate k_star.\n');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_kpert_results(results, flag_plot_signed_delta, flag_plot_abs_delta, flag_plot_best_sigma)

  ntot = results.ntot_list;
  delta = results.delta_list;
  sigma = results.sigma_mat;

  if flag_plot_signed_delta
    figure('Name', 'Signed k Perturbation Diagnostic', 'Color', 'w');
    hold on;
    for i = 1:length(ntot)
      semilogy(delta, sigma(i, :), 'o-', 'LineWidth', 1.2, 'MarkerSize', 7, ...
        'DisplayName', sprintf('ntot = %d', ntot(i)));
    end
    grid on;
    xlabel('\delta = k - k_*', 'FontSize', 11);
    ylabel('\sigma_{min}', 'FontSize', 11);
    title(sprintf('Ultra-local signed perturbations near k_* = %.16f', results.k_star), 'FontSize', 12);
    legend('Location', 'best');
  end

  if flag_plot_abs_delta
    nonzero = abs(delta) > 0;
    if any(nonzero)
      figure('Name', 'Absolute k Perturbation Diagnostic', 'Color', 'w');
      hold on;
      for i = 1:length(ntot)
        loglog(abs(delta(nonzero)), sigma(i, nonzero), 'o-', 'LineWidth', 1.2, ...
          'MarkerSize', 7, 'DisplayName', sprintf('ntot = %d', ntot(i)));
      end
      grid on;
      xlabel('|\delta|', 'FontSize', 11);
      ylabel('\sigma_{min}', 'FontSize', 11);
      title('Absolute perturbation scale, excluding \delta = 0', 'FontSize', 12);
      legend('Location', 'best');
    else
      fprintf('No nonzero perturbations are available for the absolute-delta plot.\n');
    end
  end

  if flag_plot_best_sigma
    valid_best = isfinite(results.best_sigma_per_ntot) & (results.best_sigma_per_ntot > 0);
    if any(valid_best)
      figure('Name', 'Best Tested Sigma Versus ntot', 'Color', 'w');
      loglog(ntot(valid_best), results.best_sigma_per_ntot(valid_best), 's-', ...
        'LineWidth', 1.2, 'MarkerSize', 7);
      grid on;
      xlabel('ntot', 'FontSize', 11);
      ylabel('best tested \sigma_{min}', 'FontSize', 11);
      title('Best singular value over tested perturbations', 'FontSize', 12);
    else
      fprintf('No positive finite best sigma values are available for plotting versus ntot.\n');
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function smin = LOCAL_get_sigma_min(kh, nref, C, iprec, pars1, pars2, curvelen)

  pars1.k = kh;
  proxy = kernel.precomp_proxy(pars1, pars2);
  A = LOCAL_construct_A(C, iprec, kh * nref, pars1, proxy, curvelen);
  s = svd(A);
  smin = s(end);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = LOCAL_construct_A(C, iprec, khint, pars1, proxy, curvelen)

  ntot = size(C, 2);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  speed = sqrt(dxdt.^2 + dydt.^2);
  nx1 = (dydt ./ speed).';
  nx2 = (-dxdt ./ speed).';
  ny1 = nx1.';
  ny2 = nx2.';
  src_weight = h * speed;

  [jj, ii] = meshgrid(1:ntot, 1:ntot);
  L = jj - ii;
  L(L > ntot / 2) = L(L > ntot / 2) - ntot;
  L(L <= -ntot / 2) = L(L <= -ntot / 2) + ntot;
  offdiag = L ~= 0;

  if iprec == 2
    MU = [0.7518812338640025 + 0.1073866830872157e1; ...
      -0.7225370982867850 - 0.6032109664493744];
    width = 2;
  elseif iprec == 6
    MU = [0.2051970990601250e1 + 0.2915391987686505e1; ...
      -0.7407035584542865e1 - 0.8797979464048396e1; ...
       0.1219590847580216e2 + 0.1365562914252423e2; ...
      -0.1064623987147282e2 - 0.1157975479644601e2; ...
       0.4799117710681772e1 + 0.5130987287355766e1; ...
      -0.8837770983721025   - 0.9342187797694916];
    width = 6;
  elseif iprec == 10
    MU = [0.3256353919777872D+01 + 0.4576078100790908D+01; ...
      -0.2096116396850468D+02 - 0.2469045273524281D+02; ...
       0.6872858265408605D+02 + 0.7648830198138171D+02; ...
      -0.1393153744796911D+03 - 0.1508194558089468D+03; ...
       0.1874446431742073D+03 + 0.1996415730837827D+03; ...
      -0.1715855846429547D+03 - 0.1807965537141134D+03; ...
       0.1061953812152787D+03 + 0.1110467735366555D+03; ...
      -0.4269031893958787D+02 - 0.4438764193424203D+02; ...
       0.1009036069527147D+02 + 0.1044548196545488D+02; ...
      -0.1066655310499552D+01 - 0.1100328792904271D+01];
    width = 10;
  else
    error('Unsupported iprec value.');
  end

  corr = ones(ntot, ntot);
  near_mask = offdiag & (abs(L) <= width);
  corr(near_mask) = 1 + MU(abs(L(near_mask)));

  xdiff = x.' - x;
  ydiff = y.' - y;
  rr = xdiff.^2 + ydiff.^2;
  rr(~offdiag) = 1;
  r = sqrt(rr);
  z = khint * r;
  ima4inv = 1i / 4;

  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
  cdd = -h1 .* (khint * ima4inv ./ r);
  cdd2 = (khint * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 .* h1;

  hf1 = h2z .* xdiff .* xdiff - rr .* h1;
  hf2 = h2z .* xdiff .* ydiff;
  hf3 = h2z .* ydiff .* ydiff - rr .* h1;

  pot_int = h0 * ima4inv;
  gradx_int = cdd .* xdiff;
  grady_int = cdd .* ydiff;
  hessxx_int = cdd2 .* hf1;
  hessxy_int = cdd2 .* hf2;
  hessyy_int = cdd2 .* hf3;

  pot_int(~offdiag) = 0;
  gradx_int(~offdiag) = 0;
  grady_int(~offdiag) = 0;
  hessxx_int(~offdiag) = 0;
  hessxy_int(~offdiag) = 0;
  hessyy_int(~offdiag) = 0;

  [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    kernel.qpgreen_mfs_pairmat([x; y], [x; y], pars1, proxy);

  pot_ext(~offdiag) = 0;
  gradx_ext(~offdiag) = 0;
  grady_ext(~offdiag) = 0;
  hessxx_ext(~offdiag) = 0;
  hessxy_ext(~offdiag) = 0;
  hessyy_ext(~offdiag) = 0;

  nx1ny1 = nx1 * ny1;
  nx1ny2_nx2ny1 = nx1 * ny2 + nx2 * ny1;
  nx2ny2 = nx2 * ny2;
  nx1mat = repmat(nx1, 1, ntot);
  nx2mat = repmat(nx2, 1, ntot);
  ny1mat = repmat(ny1, ntot, 1);
  ny2mat = repmat(ny2, ntot, 1);
  weight_mat = repmat(src_weight, ntot, 1);

  A11 = ((gradx_int - gradx_ext) .* ny1mat + (grady_int - grady_ext) .* ny2mat) .* weight_mat;
  A12 = (pot_int - pot_ext) .* weight_mat;
  A21 = ((hessxx_int - hessxx_ext) .* nx1ny1 + ...
         (hessxy_int - hessxy_ext) .* nx1ny2_nx2ny1 + ...
         (hessyy_int - hessyy_ext) .* nx2ny2) .* weight_mat;
  A22 = ((gradx_int - gradx_ext) .* nx1mat + (grady_int - grady_ext) .* nx2mat) .* weight_mat;

  A11 = A11 .* corr;
  A12 = A12 .* corr;
  A21 = A21 .* corr;
  A22 = A22 .* corr;

  A = eye(2 * ntot, 2 * ntot);
  A(1:ntot, 1:ntot) = A(1:ntot, 1:ntot) + A11;
  A(1:ntot, ntot + 1:end) = A12;
  A(ntot + 1:end, 1:ntot) = A21;
  A(ntot + 1:end, ntot + 1:end) = A(ntot + 1:end, ntot + 1:end) + A22;

  scale_row = sqrt(h * [speed, speed]).';
  scale_col = sqrt((1 / h) ./ [speed, speed]);
  A = bsxfun(@times, bsxfun(@times, A, scale_col), scale_row);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

