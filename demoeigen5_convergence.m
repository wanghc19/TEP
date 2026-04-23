% Convergence driver for the smallest singular value near one candidate
% transmission eigenvalue.
%
% This script is derived from demoeigen5.m, but it is not a full adaptive
% search over all dips in a broad k-interval.  Instead, it focuses on one
% known candidate eigenvalue and studies how the discretized minimum
% singular value changes as the boundary discretization ntot is increased.
%
% Two operating modes are supported.  In scan_interval mode, each ntot starts
% from k_interval_initial, samples sigma_min(A_N(k)) on a local grid, and
% adaptively shrinks the interval until the relative improvement in the
% sampled minimum is small, an endpoint is hit, or max_refine_level is
% reached.  The script records k_best(N), sigma_best(N), interval widths,
% stopping reasons, and optional fixed-k values.
%
% In fixed_k mode, the interval scan is skipped entirely.  The script
% directly evaluates sigma_min(A_N(k_fixed_ref)) for each ntot, which is the
% intended workflow once an accurate limiting eigenvalue k* is already known.
%
% The main numerical questions are whether k_best(N) stabilizes under
% refinement, and more importantly how sigma_min(A_N(k*)) appears to
% converge to zero as ntot grows.  The matrix assembly and singular-value
% evaluation formulas are kept close to the trusted implementation in
% demoeigen5.m; this file mainly changes the driver logic, reporting, and
% convergence diagnostics.
format long;
clear;

% --- 1. Parameter Setup ---
flag_geom = 'ellipse';             % Geometry type: 'star' or 'ellipse'
iprec = 10;
er = 13;
nref = sqrt(er);
d = 1.0;
beta = 0.5 * 2 * pi / d;

pars1.beta = beta;
pars1.d = d;

pars2.H = 0.5 * pars1.d;
pars2.proxy_dist = 0.2 * pars1.d;
pars2.N_side = 50;
pars2.N_top = 50;
pars2.N_proxy_edge = 30;
pars2.M_pw = 10;

ntot_list = [60, 80, 100, 120, 150];
k_mode = 'scan_interval';          % Options: 'scan_interval' or 'fixed_k'
k_interval_initial = [2.64525090, 2.65989423];
min_refine_level = 2;
max_refine_level = 8;
tol_rel_improve = 1e-8;
nrefine = max_refine_level;        % Legacy alias for fixed-depth runs
ngrid_refine = 11;                 % Keep it odd
k_fixed_ref = 2.6535097381199999;

flag_print_level_details = true;
flag_plot_sigma = true;
flag_plot_kbest = true;
flag_plot_kerror = true;

if ~strcmp(k_mode, 'scan_interval') && ~strcmp(k_mode, 'fixed_k')
  error('k_mode must be either ''scan_interval'' or ''fixed_k''.');
end
if strcmp(k_mode, 'fixed_k') && (isempty(k_fixed_ref) || ~isscalar(k_fixed_ref) || ~isfinite(k_fixed_ref))
  error('fixed_k mode requires a finite scalar k_fixed_ref.');
end
if strcmp(k_mode, 'scan_interval')
  if mod(ngrid_refine, 2) ~= 1
    error('ngrid_refine must be odd.');
  end
  if min_refine_level < 1
    error('min_refine_level must be at least 1.');
  end
  if max_refine_level < min_refine_level
    error('max_refine_level must be greater than or equal to min_refine_level.');
  end
  if tol_rel_improve < 0
    error('tol_rel_improve must be nonnegative.');
  end
  if isempty(k_interval_initial) || numel(k_interval_initial) ~= 2 || ...
      any(~isfinite(k_interval_initial)) || k_interval_initial(1) >= k_interval_initial(2)
    error('scan_interval mode requires a finite increasing two-entry k_interval_initial.');
  end
end

fprintf('ntot-convergence study for sigma_min(k)\n');
fprintf('  Geometry            : %s\n', flag_geom);
fprintf('  k mode              : %s\n', k_mode);
if strcmp(k_mode, 'scan_interval')
  fprintf('  Initial interval    : [%.8f, %.8f]\n', k_interval_initial(1), k_interval_initial(2));
else
  fprintf('  Initial interval    : skipped in fixed_k mode\n');
end
fprintf('  ntot list           : [%s]\n', num2str(ntot_list));
if strcmp(k_mode, 'scan_interval')
  fprintf('  Min refine levels   : %d\n', min_refine_level);
  fprintf('  Max refine levels   : %d\n', max_refine_level);
  fprintf('  Rel improve tol     : %.3e\n', tol_rel_improve);
  fprintf('  Local grid size     : %d\n', ngrid_refine);
else
  fprintf('  Refinement          : skipped in fixed_k mode\n');
end
if isempty(k_fixed_ref)
  fprintf('  Fixed-k study       : skipped\n');
else
  fprintf('  Fixed-k study       : k = %.16f\n', k_fixed_ref);
end

results = LOCAL_run_ntot_convergence_study(flag_geom, iprec, nref, pars1, pars2, ...
  ntot_list, k_mode, k_interval_initial, min_refine_level, max_refine_level, ...
  tol_rel_improve, ngrid_refine, k_fixed_ref, flag_print_level_details);

LOCAL_print_convergence_summary(results);
LOCAL_plot_convergence_results(results, flag_plot_sigma, flag_plot_kbest, flag_plot_kerror);

fprintf('\nntot-convergence study completed successfully.\n');

%% =========================================================================
%  LOCAL HELPERS
%  =========================================================================
function results = LOCAL_run_ntot_convergence_study(flag_geom, iprec, nref, pars1, pars2, ...
    ntot_list, k_mode, k_interval_initial, min_refine_level, max_refine_level, ...
    tol_rel_improve, ngrid_refine, k_fixed_ref, flag_print_level_details)

  geometry_cache = LOCAL_build_geometry_cache(ntot_list, flag_geom);
  ncases = length(ntot_list);

  records = repmat(struct( ...
    'ntot', [], ...
    'k_best', [], ...
    'k_eval', [], ...
    'sigma_best', [], ...
    'interval_left', [], ...
    'interval_right', [], ...
    'interval_width', [], ...
    'sigma_fixed', [], ...
    'endpoint_hit', false, ...
    'level_count', [], ...
    'final_rel_improve', [], ...
    'stop_reason', '', ...
    'history', []), ncases, 1);

  for j = 1:ncases
    ntot = ntot_list(j);
    if strcmp(k_mode, 'scan_interval')
      [record, history] = LOCAL_refine_interval_for_one_ntot(ntot, geometry_cache, nref, iprec, ...
        pars1, pars2, k_interval_initial, min_refine_level, max_refine_level, ...
        tol_rel_improve, ngrid_refine);
      record.k_eval = record.k_best;
    else
      record = LOCAL_make_fixed_k_record(ntot, k_fixed_ref);
      history = [];
    end

    if ~isempty(k_fixed_ref)
      [C, curvelen] = LOCAL_get_geometry_from_cache(ntot, geometry_cache);
      record.sigma_fixed = LOCAL_get_sigma_min(k_fixed_ref, nref, C, iprec, pars1, pars2, curvelen);
      if strcmp(k_mode, 'fixed_k')
        record.k_eval = k_fixed_ref;
      end
    else
      record.sigma_fixed = NaN;
    end

    record.history = history;
    records(j) = record;

    if flag_print_level_details
      LOCAL_print_one_ntot_progress(record);
    end
  end

  results.flag_geom = flag_geom;
  results.k_mode = k_mode;
  results.iprec = iprec;
  results.nref = nref;
  results.pars1 = pars1;
  results.pars2 = pars2;
  results.ntot_list = ntot_list(:);
  results.k_interval_initial = k_interval_initial;
  results.min_refine_level = min_refine_level;
  results.max_refine_level = max_refine_level;
  results.tol_rel_improve = tol_rel_improve;
  results.ngrid_refine = ngrid_refine;
  results.k_fixed_ref = k_fixed_ref;
  results.records = records;
  results.histories = cell(ncases, 1);
  for j = 1:ncases
    results.histories{j} = records(j).history;
  end

  k_best_all = [records.k_best].';
  k_eval_all = [records.k_eval].';
  sigma_best_all = [records.sigma_best].';
  sigma_fixed_all = [records.sigma_fixed].';

  results.k_best_all = k_best_all;
  results.k_eval_all = k_eval_all;
  results.sigma_best_all = sigma_best_all;
  results.sigma_fixed_all = sigma_fixed_all;
  if strcmp(k_mode, 'scan_interval')
    results.k_inf_last = k_best_all(end);
    results.k_limit_fit = LOCAL_fit_k_limit(ntot_list(:), k_best_all);
    if results.k_limit_fit.success
      results.k_inf_fit = results.k_limit_fit.k_inf;
      results.k_inf = results.k_inf_fit;
      results.k_inf_source = 'fit';
    else
      results.k_inf_fit = NaN;
      results.k_inf = results.k_inf_last;
      results.k_inf_source = 'largest_ntot';
    end
    results.k_error_all = abs(k_best_all - results.k_inf);
    results.fit_best = LOCAL_power_law_fit(ntot_list(:), sigma_best_all);
  else
    results.k_inf_last = NaN;
    results.k_limit_fit = LOCAL_empty_k_limit_fit('Skipped in fixed_k mode.');
    results.k_inf_fit = NaN;
    results.k_inf = NaN;
    results.k_inf_source = 'not_used';
    results.k_error_all = NaN(size(k_best_all));
    results.fit_best = [];
  end
  if isempty(k_fixed_ref)
    results.fit_fixed = [];
  else
    results.fit_fixed = LOCAL_power_law_fit(ntot_list(:), sigma_fixed_all);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [record, history] = LOCAL_refine_interval_for_one_ntot(ntot, geometry_cache, nref, iprec, ...
    pars1, pars2, k_interval_initial, min_refine_level, max_refine_level, ...
    tol_rel_improve, ngrid_refine)

  [C, curvelen] = LOCAL_get_geometry_from_cache(ntot, geometry_cache);
  current_interval = k_interval_initial;

  history = repmat(struct( ...
    'level', [], ...
    'interval', [], ...
    'k_grid', [], ...
    'sigma_vals', [], ...
    'idx_min', [], ...
    'k_min', [], ...
    'sigma_min', [], ...
    'rel_improve', [], ...
    'endpoint_hit', false, ...
    'stop_reason', ''), max_refine_level, 1);

  endpoint_hit = false;
  k_best = NaN;
  sigma_best = NaN;
  sigma_prev = NaN;
  final_rel_improve = NaN;
  level_count = 0;
  stop_reason = 'max_refine_reached';

  for level = 1:max_refine_level
    k_grid = linspace(current_interval(1), current_interval(2), ngrid_refine);
    sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen);
    [sigma_best, idx_min] = min(sigma_vals);
    k_best = k_grid(idx_min);
    if isfinite(sigma_prev) && sigma_prev > 0
      rel_improve = (sigma_prev - sigma_best) / sigma_prev;
    else
      rel_improve = NaN;
    end

    history(level).level = level;
    history(level).interval = current_interval;
    history(level).k_grid = k_grid;
    history(level).sigma_vals = sigma_vals;
    history(level).idx_min = idx_min;
    history(level).k_min = k_best;
    history(level).sigma_min = sigma_best;
    history(level).rel_improve = rel_improve;
    history(level).endpoint_hit = (idx_min == 1) || (idx_min == ngrid_refine);

    level_count = level;
    final_rel_improve = rel_improve;
    next_interval = LOCAL_build_refined_interval(k_grid, idx_min);

    if history(level).endpoint_hit
      endpoint_hit = true;
      stop_reason = 'endpoint_hit';
      history(level).stop_reason = stop_reason;
      fprintf(['  ntot = %d, level = %d: minimizer reached a refinement-grid endpoint ', ...
        '(idx = %d of %d).\n'], ntot, level, idx_min, ngrid_refine);
      current_interval = next_interval;
      break;
    end

    if (level >= min_refine_level) && isfinite(rel_improve) && (rel_improve < tol_rel_improve)
      stop_reason = 'rel_improve_below_tol';
      history(level).stop_reason = stop_reason;
      current_interval = next_interval;
      break;
    end

    if level == max_refine_level
      stop_reason = 'max_refine_reached';
      history(level).stop_reason = stop_reason;
    end

    sigma_prev = sigma_best;
    current_interval = next_interval;
  end

  history = history(1:level_count);
  record.ntot = ntot;
  record.k_best = k_best;
  record.sigma_best = sigma_best;
  record.interval_left = current_interval(1);
  record.interval_right = current_interval(2);
  record.interval_width = current_interval(2) - current_interval(1);
  record.sigma_fixed = NaN;
  record.endpoint_hit = endpoint_hit;
  record.level_count = level_count;
  record.final_rel_improve = final_rel_improve;
  record.stop_reason = stop_reason;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function record = LOCAL_make_fixed_k_record(ntot, k_fixed_ref)

  record.ntot = ntot;
  record.k_best = NaN;
  record.k_eval = k_fixed_ref;
  record.sigma_best = NaN;
  record.interval_left = NaN;
  record.interval_right = NaN;
  record.interval_width = NaN;
  record.sigma_fixed = NaN;
  record.endpoint_hit = false;
  record.level_count = 0;
  record.final_rel_improve = NaN;
  record.stop_reason = 'fixed_k';
  record.history = [];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fit = LOCAL_power_law_fit(xdata, ydata)

  fit = struct( ...
    'success', false, ...
    'npts', 0, ...
    'C', NaN, ...
    'p', NaN, ...
    'indices', [], ...
    'message', '');

  xdata = xdata(:);
  ydata = ydata(:);
  valid = isfinite(xdata) & isfinite(ydata) & (xdata > 0) & (ydata > 0);

  if nnz(valid) < 2
    fit.message = 'Too few positive data points for log-log fitting.';
    return;
  end

  idx_valid = find(valid);
  nuse = min(3, length(idx_valid));
  idx_use = idx_valid(end - nuse + 1:end);

  if length(idx_use) < 2
    fit.message = 'Too few tail points for log-log fitting.';
    return;
  end

  logx = log(xdata(idx_use));
  logy = log(ydata(idx_use));
  coeffs = polyfit(logx, logy, 1);

  fit.success = true;
  fit.npts = length(idx_use);
  fit.C = exp(coeffs(2));
  fit.p = -coeffs(1);
  fit.indices = idx_use;
  fit.message = sprintf('Used the last %d positive data points.', fit.npts);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fit = LOCAL_fit_k_limit(ntot_list, k_best_all)

  fit = LOCAL_empty_k_limit_fit('');

  ntot_list = ntot_list(:);
  k_best_all = k_best_all(:);
  valid = isfinite(ntot_list) & isfinite(k_best_all) & (ntot_list > 0);

  if nnz(valid) < 3
    fit.message = 'Too few finite k_best values for tail extrapolation.';
    return;
  end

  idx_valid = find(valid);
  nuse = min(3, length(idx_valid));
  idx_use = idx_valid(end - nuse + 1:end);
  ntail = ntot_list(idx_use);
  ktail = k_best_all(idx_use);

  q_grid = linspace(0.5, 12, 232);
  best_resnorm = Inf;
  best_coeffs = [NaN; NaN];
  best_q = NaN;

  for j = 1:length(q_grid)
    q = q_grid(j);
    basis = ntail.^(-q);
    V = [ones(size(ntail)), basis];
    if rcond(V.' * V) < 1e-14
      continue;
    end

    coeffs = V \ ktail;
    residual = ktail - V * coeffs;
    resnorm = norm(residual);
    if isfinite(resnorm) && (resnorm < best_resnorm)
      best_resnorm = resnorm;
      best_coeffs = coeffs;
      best_q = q;
    end
  end

  if ~isfinite(best_resnorm) || ~isfinite(best_coeffs(1)) || ~isfinite(best_q)
    fit.message = 'Tail extrapolation was numerically unstable.';
    return;
  end

  fit.success = true;
  fit.k_inf = best_coeffs(1);
  fit.C = best_coeffs(2);
  fit.q = best_q;
  fit.indices = idx_use;
  fit.resnorm = best_resnorm;
  fit.message = sprintf('Used the last %d finite k_best values.', nuse);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fit = LOCAL_empty_k_limit_fit(message)

  fit = struct( ...
    'success', false, ...
    'k_inf', NaN, ...
    'C', NaN, ...
    'q', NaN, ...
    'indices', [], ...
    'resnorm', NaN, ...
    'message', message);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_convergence_summary(results)

  records = results.records;

  fprintf('\nConvergence summary (%s mode):\n', results.k_mode);
  if strcmp(results.k_mode, 'fixed_k')
    fprintf('  %-8s %-22s %-20s\n', 'ntot', 'k_fixed_ref', 'sigma_fixed');
    for j = 1:length(records)
      record = records(j);
      fprintf('  %-8d %-22.16f %-20.12e\n', ...
        record.ntot, record.k_eval, record.sigma_fixed);
    end

    fprintf('\nDiagnostics:\n');
    fprintf('  Fixed k             = %.16f\n', results.k_fixed_ref);
    LOCAL_print_power_law_fit('sigma_fixed', results.fit_fixed);
    return;
  end

  k_inf = results.k_inf;
  if isempty(results.k_fixed_ref)
    fprintf(['  %-8s %-22s %-20s %-22s %-22s %-16s %-8s %-14s %-24s %-16s\n'], ...
      'ntot', 'k_best', 'sigma_best', 'interval_left', 'interval_right', ...
      'width', 'levels', 'rel_improve', 'stop_reason', '|k_best-k_inf|');
  else
    fprintf(['  %-8s %-22s %-20s %-22s %-22s %-16s %-20s %-8s %-14s %-24s %-16s\n'], ...
      'ntot', 'k_best', 'sigma_best', 'interval_left', 'interval_right', ...
      'width', 'sigma_fixed', 'levels', 'rel_improve', 'stop_reason', '|k_best-k_inf|');
  end

  for j = 1:length(records)
    record = records(j);
    if isempty(results.k_fixed_ref)
      fprintf(['  %-8d %-22.16f %-20.12e %-22.16f %-22.16f %-16.8e %-8d %-14.6e %-24s %-16.8e\n'], ...
        record.ntot, record.k_best, record.sigma_best, record.interval_left, ...
        record.interval_right, record.interval_width, record.level_count, ...
        record.final_rel_improve, record.stop_reason, abs(record.k_best - k_inf));
    else
      fprintf(['  %-8d %-22.16f %-20.12e %-22.16f %-22.16f %-16.8e %-20.12e %-8d %-14.6e %-24s %-16.8e\n'], ...
        record.ntot, record.k_best, record.sigma_best, record.interval_left, ...
        record.interval_right, record.interval_width, record.sigma_fixed, ...
        record.level_count, record.final_rel_improve, record.stop_reason, ...
        abs(record.k_best - k_inf));
    end
  end

  fprintf('\nDiagnostics:\n');
  fprintf('  k_inf fallback       = %.16f (largest ntot)\n', results.k_inf_last);
  if results.k_limit_fit.success
    fprintf('  k_inf fit            = %.16f\n', results.k_limit_fit.k_inf);
    fprintf('  k fit exponent q     = %.6f\n', results.k_limit_fit.q);
    fprintf('  k fit residual norm  = %.6e\n', results.k_limit_fit.resnorm);
    fprintf('  k fit message        = %s\n', results.k_limit_fit.message);
  else
    fprintf('  k_inf fit            = unavailable (%s)\n', results.k_limit_fit.message);
  end
  fprintf('  k_inf used           = %.16f (%s)\n', k_inf, results.k_inf_source);
  fprintf('  sigma_best(end)      = %.16e\n', results.sigma_best_all(end));
  fprintf('  Any endpoint hit     = %d\n', any([records.endpoint_hit]));

  LOCAL_print_power_law_fit('sigma_best', results.fit_best);
  if ~isempty(results.k_fixed_ref)
    LOCAL_print_power_law_fit('sigma_fixed', results.fit_fixed);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_power_law_fit(label, fit)

  if fit.success
    fprintf('  %s fit              : %s\n', label, fit.message);
    fprintf('  %s ~ C * ntot^{-p}  : C = %.6e, p = %.6f\n', label, fit.C, fit.p);
  else
    fprintf('  %s fit              : %s\n', label, fit.message);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_print_one_ntot_progress(record)

  if strcmp(record.stop_reason, 'fixed_k')
    fprintf('\nCompleted ntot = %d: k_eval = %.16f, sigma_fixed = %.12e\n', ...
      record.ntot, record.k_eval, record.sigma_fixed);
  else
    fprintf(['\nCompleted ntot = %d: k_best = %.16f, sigma_best = %.12e, ', ...
      'levels = %d, final width = %.8e, stop = %s\n'], ...
      record.ntot, record.k_best, record.sigma_best, record.level_count, ...
      record.interval_width, record.stop_reason);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_convergence_results(results, flag_plot_sigma, flag_plot_kbest, flag_plot_kerror)

  ntot = results.ntot_list;
  k_best = results.k_best_all;
  sigma_best = results.sigma_best_all;
  sigma_fixed = results.sigma_fixed_all;
  k_error = results.k_error_all;

  if strcmp(results.k_mode, 'fixed_k')
    if flag_plot_sigma
      valid_fixed = isfinite(sigma_fixed) & (sigma_fixed > 0);
      if any(valid_fixed)
        figure('Name', 'Fixed-k Sigma Convergence', 'Color', 'w');
        loglog(ntot(valid_fixed), sigma_fixed(valid_fixed), 's-', 'LineWidth', 1.2, 'MarkerSize', 7);
        grid on;
        xlabel('ntot', 'FontSize', 11);
        ylabel('\sigma_{min}', 'FontSize', 11);
        title(sprintf('Fixed-k convergence at k = %.16f', results.k_fixed_ref), 'FontSize', 12);
      else
        fprintf('No positive finite sigma_fixed values are available for plotting.\n');
      end
    end
    return;
  end

  if flag_plot_sigma
    figure('Name', 'Sigma Convergence', 'Color', 'w');
    loglog(ntot, sigma_best, 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
    hold on;
    if ~isempty(results.k_fixed_ref)
      valid_fixed = isfinite(sigma_fixed) & (sigma_fixed > 0);
      loglog(ntot(valid_fixed), sigma_fixed(valid_fixed), 's--', 'LineWidth', 1.2, 'MarkerSize', 7);
      legend({'sigma\_best', 'sigma\_fixed'}, 'Location', 'best');
    else
      legend({'sigma\_best'}, 'Location', 'best');
    end
    grid on;
    xlabel('ntot', 'FontSize', 11);
    ylabel('\sigma_{min}', 'FontSize', 11);
    title('Convergence of minimum singular values', 'FontSize', 12);
  end

  if flag_plot_kbest
    figure('Name', 'Best k Versus ntot', 'Color', 'w');
    plot(ntot, k_best, 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
    grid on;
    xlabel('ntot', 'FontSize', 11);
    ylabel('k_{best}', 'FontSize', 11);
    title('Refined minimizer location versus ntot', 'FontSize', 12);
  end

  if flag_plot_kerror
    valid_error = k_error > 0;
    if any(valid_error)
      figure('Name', 'k Error Versus ntot', 'Color', 'w');
      semilogy(ntot(valid_error), k_error(valid_error), 'o-', 'LineWidth', 1.2, 'MarkerSize', 7);
      grid on;
      xlabel('ntot', 'FontSize', 11);
      ylabel('|k_{best} - k_{\infty}|', 'FontSize', 11);
      title(sprintf('Convergence of refined minimizer location (%s k_{\\infty})', ...
        results.k_inf_source), 'FontSize', 12);
    else
      fprintf('All |k_best - k_inf| values are zero on the sampled grid; skipping the semilogy error plot.\n');
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function geometry_cache = LOCAL_build_geometry_cache(ntot_list, flag_geom)

  ntot_unique = unique(ntot_list, 'stable');
  geometry_cache = struct('ntot', cell(length(ntot_unique), 1), ...
    'C', cell(length(ntot_unique), 1), ...
    'curvelen', cell(length(ntot_unique), 1));

  for j = 1:length(ntot_unique)
    [C, curvelen, ~, ~] = LOCAL_construct_cont(ntot_unique(j), flag_geom, 0, 0);
    geometry_cache(j).ntot = ntot_unique(j);
    geometry_cache(j).C = C;
    geometry_cache(j).curvelen = curvelen;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [C, curvelen] = LOCAL_get_geometry_from_cache(ntot, geometry_cache)

  idx = find([geometry_cache.ntot] == ntot, 1, 'first');
  if isempty(idx)
    error('Geometry for ntot = %d was not found in the cache.', ntot);
  end

  C = geometry_cache(idx).C;
  curvelen = geometry_cache(idx).curvelen;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sigma_vals = LOCAL_scan_sigma_on_grid(k_grid, nref, C, iprec, pars1, pars2, curvelen)

  sigma_vals = zeros(size(k_grid));
  for j = 1:length(k_grid)
    sigma_vals(j) = LOCAL_get_sigma_min(k_grid(j), nref, C, iprec, pars1, pars2, curvelen);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function interval = LOCAL_build_refined_interval(k_grid, idx_min)

  nk = length(k_grid);
  if nk < 2
    error('Need at least two k-samples to define a refined interval.');
  end

  if idx_min <= 1
    interval = [k_grid(1), k_grid(2)];
  elseif idx_min >= nk
    interval = [k_grid(nk - 1), k_grid(nk)];
  else
    interval = [k_grid(idx_min - 1), k_grid(idx_min + 1)];
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function smin = LOCAL_get_sigma_min(kh, nref, C, iprec, pars1, pars2, curvelen)

  pars1.k = kh;
  proxy = precomp_proxy(pars1, pars2);
  A = LOCAL_construct_A(C, iprec, kh * nref, pars1, proxy, curvelen);
  s = svd(A);
  smin = s(end);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [C, curvelen, xxint, xxext] = LOCAL_construct_cont(ntot, flag_geom, nint, next)

  if strcmp(flag_geom, 'star')
    r = 0.3;
    k = 5;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =   1.5 * cos(tt) + (r / 2) *            cos((k + 1) * tt) + (r / 2) *            cos((k - 1) * tt);
    C(2,:) = - 1.5 * sin(tt) - (r / 2) * (k + 1) * sin((k + 1) * tt) - (r / 2) * (k - 1) * sin((k - 1) * tt);
    C(3,:) = - 1.5 * cos(tt) - (r / 2) * (k + 1) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * (k - 1) * cos((k - 1) * tt);
    C(4,:) =       sin(tt) + (r / 2) *            sin((k + 1) * tt) - (r / 2) *            sin((k - 1) * tt);
    C(5,:) =       cos(tt) + (r / 2) * (k + 1) * cos((k + 1) * tt) - (r / 2) * (k - 1) * cos((k - 1) * tt);
    C(6,:) = -     sin(tt) - (r / 2) * (k + 1) * (k + 1) * sin((k + 1) * tt) + (r / 2) * (k - 1) * (k - 1) * sin((k - 1) * tt);
    C = C .* 0.2;
    curvelen = 2 * pi;
    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.6 * [rmax * cos(ttext); rmax * sin(ttext)];
  elseif strcmp(flag_geom, 'ellipse')
    a = 0.4;
    b = 0.4;
    tt = linspace(0, 2 * pi * (1 - 1 / ntot), ntot);
    C = zeros(6, ntot);
    C(1,:) =  a * cos(tt);
    C(2,:) = -a * sin(tt);
    C(3,:) = -a * cos(tt);
    C(4,:) =  b * sin(tt);
    C(5,:) =  b * cos(tt);
    C(6,:) = -b * sin(tt);
    curvelen = 2 * pi;

    rmin = sqrt(min(C(1,:).^2 + C(4,:).^2));
    rmax = sqrt(max(C(1,:).^2 + C(4,:).^2));
    ttint = 2 * pi * rand(1, nint);
    xxint = 0.6 * [rmin * cos(ttint); rmin * sin(ttint)];
    ttext = 2 * pi * rand(1, next);
    xxext = 1.4 * [rmax * cos(ttext); rmax * sin(ttext)];
  else
    error('This option for the geometry is not implemented.');
  end

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
    LOCAL_qpgreen_mfs_pairmat([x; y], [x; y], pars1, proxy);

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

function [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
    LOCAL_qpgreen_mfs_pairmat(src, trg, pars1, proxy)

  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;

  q = proxy.q;
  Z = proxy.Z;
  H = proxy.H;
  C_up = proxy.C_up;
  C_down = proxy.C_down;

  ns = size(src, 2);
  nt = size(trg, 2);

  X = trg(1, :).'- src(1, :);
  Y = trg(2, :).'- src(2, :);

  m_shift = round(X / d);
  X0 = X - m_shift * d;
  phase_shift = exp(1i * beta * m_shift * d);

  pot_ext = zeros(nt, ns);
  gradx_ext = zeros(nt, ns);
  grady_ext = zeros(nt, ns);
  hessxx_ext = zeros(nt, ns);
  hessxy_ext = zeros(nt, ns);
  hessyy_ext = zeros(nt, ns);

  idx_in = abs(Y) <= H;
  idx_up = Y > H;
  idx_dn = Y < -H;

  if any(idx_in(:))
    T_in = [X0(idx_in).'; Y(idx_in).'];
    [pot0, grad0, hess0] = LOCAL_h2d_directch(k, [0; 0], 1, T_in);
    [potP, gradP, hessP] = LOCAL_h2d_directch(k, Z, q, T_in);

    pot_ext(idx_in) = (pot0 + potP) .* phase_shift(idx_in).';
    gradx_ext(idx_in) = (grad0(1, :) + gradP(1, :)) .* phase_shift(idx_in).';
    grady_ext(idx_in) = (grad0(2, :) + gradP(2, :)) .* phase_shift(idx_in).';
    hessxx_ext(idx_in) = (hess0(1, :) + hessP(1, :)) .* phase_shift(idx_in).';
    hessxy_ext(idx_in) = (hess0(2, :) + hessP(2, :)) .* phase_shift(idx_in).';
    hessyy_ext(idx_in) = (hess0(3, :) + hessP(3, :)) .* phase_shift(idx_in).';
  end

  if any(idx_up(:)) || any(idx_dn(:))
    N_pw_total = length(C_up);
    M_pw = (N_pw_total - 1) / 2;
    m_vec = (-M_pw:M_pw).';
    beta_m = beta + m_vec * (2 * pi / d);

    diff_sq = k^2 - beta_m.^2;
    gamma_m = zeros(size(beta_m));
    mask_prop = diff_sq >= 0;
    mask_eva = diff_sq < 0;
    gamma_m(mask_prop) = sqrt(diff_sq(mask_prop));
    gamma_m(mask_eva) = 1i * sqrt(-diff_sq(mask_eva));

    if any(idx_up(:))
      X_up = X0(idx_up).';
      Y_up = Y(idx_up).';
      phase_X = exp(1i * beta_m * X_up);
      phase_Y = exp(1i * gamma_m * (Y_up - H));
      basis = phase_X .* phase_Y;
      phase_up = phase_shift(idx_up).';

      pot_ext(idx_up) = sum(C_up .* basis, 1) .* phase_up;
      gradx_ext(idx_up) = sum(C_up .* basis .* (1i * beta_m), 1) .* phase_up;
      grady_ext(idx_up) = sum(C_up .* basis .* (1i * gamma_m), 1) .* phase_up;
      hessxx_ext(idx_up) = sum(C_up .* basis .* (-beta_m.^2), 1) .* phase_up;
      hessxy_ext(idx_up) = sum(C_up .* basis .* (-beta_m .* gamma_m), 1) .* phase_up;
      hessyy_ext(idx_up) = sum(C_up .* basis .* (-gamma_m.^2), 1) .* phase_up;
    end

    if any(idx_dn(:))
      X_dn = X0(idx_dn).';
      Y_dn = Y(idx_dn).';
      phase_X = exp(1i * beta_m * X_dn);
      phase_Y = exp(-1i * gamma_m * (Y_dn + H));
      basis = phase_X .* phase_Y;
      phase_dn = phase_shift(idx_dn).';

      pot_ext(idx_dn) = sum(C_down .* basis, 1) .* phase_dn;
      gradx_ext(idx_dn) = sum(C_down .* basis .* (1i * beta_m), 1) .* phase_dn;
      grady_ext(idx_dn) = sum(C_down .* basis .* (-1i * gamma_m), 1) .* phase_dn;
      hessxx_ext(idx_dn) = sum(C_down .* basis .* (-beta_m.^2), 1) .* phase_dn;
      hessxy_ext(idx_dn) = sum(C_down .* basis .* (beta_m .* gamma_m), 1) .* phase_dn;
      hessyy_ext(idx_dn) = sum(C_down .* basis .* (-gamma_m.^2), 1) .* phase_dn;
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pot, grad, hess] = LOCAL_h2d_directch(wavek, sources, charge, targ)

  ns = size(sources, 2);
  nt = size(targ, 2);
  charge = reshape(charge, 1, []);
  if length(charge) ~= ns
    error('charge must have one entry per source.');
  end

  ima4inv = 1i / 4;
  xdiff = bsxfun(@minus, targ(1, :).', sources(1, :));
  ydiff = bsxfun(@minus, targ(2, :).', sources(2, :));
  rr = xdiff.^2 + ydiff.^2;
  r = sqrt(rr);
  z = wavek * r;

  h0 = besselh(0, z);
  h1 = besselh(1, z);
  cdd = -h1 .* (wavek * ima4inv ./ r);
  cdd2 = (wavek * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 * h1;
  hf1 = h2z .* xdiff .* xdiff - rr .* h1;
  hf2 = h2z .* xdiff .* ydiff;
  hf3 = h2z .* ydiff .* ydiff - rr .* h1;

  weighted_h0 = bsxfun(@times, h0, charge);
  weighted_cdd = bsxfun(@times, cdd, charge);
  weighted_cdd2 = bsxfun(@times, cdd2, charge);

  pot = ima4inv * sum(weighted_h0, 2).';
  grad = zeros(2, nt);
  grad(1, :) = sum(weighted_cdd .* xdiff, 2).';
  grad(2, :) = sum(weighted_cdd .* ydiff, 2).';

  hess = zeros(3, nt);
  hess(1, :) = sum(weighted_cdd2 .* hf1, 2).';
  hess(2, :) = sum(weighted_cdd2 .* hf2, 2).';
  hess(3, :) = sum(weighted_cdd2 .* hf3, 2).';

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
