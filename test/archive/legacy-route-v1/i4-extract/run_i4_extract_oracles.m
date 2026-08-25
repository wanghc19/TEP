function results = run_i4_extract_oracles(output_label)
%RUN_I4_EXTRACT_ORACLES Run independent Rayleigh extraction diagnostics.
%
% Purpose:
%   Test four layers separately: exact wall Fourier projection, continuous
%   circle-density coefficients, package far-field extraction, and MFS wall
%   evaluation.  A point-source value test also compares the Rayleigh series,
%   the benchmark Ewald implementation after a coordinate-axis exchange, and
%   qpgreen_mfs_pairmat.
%
% Input:
%   output_label - Optional safe directory label.  Default: 'canonical'.
%
% Output:
%   results - Struct containing configuration, summaries, gates, timings,
%             data ledgers, provenance, and output paths.
%
% Main algorithm:
%   1. Project manufactured finite Rayleigh sums on both walls.
%   2. For rho(theta) = sum_l rho_l exp(i*l*theta), compare direct angular
%      quadrature and bloch.farfield_extractors with the circle identity
%
%        I_l(a,b) = 2*pi*i^l*((a+i*b)/k)^l*J_l(k*R),
%
%      and d_R I_l for the double layer.
%   3. Evaluate the same densities through qpgreen_mfs_pairmat and refine one
%      variable at a time: boundary nodes, wall nodes, then proxy level.
%   4. Compare point Green values with a spectral partial sum and the
%      x-periodic benchmark Ewald routine after swapping physical x and y.
%
% Based on:
%   benchmark/bloch/bloch_test_F.m and
%   test/i4-rayleigh-budget/run_i4_rayleigh_budget.m.
%
% Main changes:
%   Removes the BIE solve and uses analytic/manufactured data so boundary,
%   wall projection, proxy, Hessian, and convention errors are separately
%   visible.  No package or earlier test file is modified.
%
% Numerical goal:
%   Preserve every frozen Researcher gate without automatic relaxation and
%   write CSV/MAT/Markdown/log evidence in output/<label>/.

  if nargin < 1 || isempty(output_label)
    output_label = 'canonical';
  end
  if ~ischar(output_label) || isempty(regexp(output_label, ...
      '^[A-Za-z0-9_-]+$', 'once'))
    error('run_i4_extract_oracles:InvalidOutputLabel', ...
      'output_label must contain only letters, digits, underscores, and hyphens.');
  end

  config = i4_extract_config();
  addpath(config.repo_root);
  addpath(fullfile(config.repo_root, 'benchmark', 'qpgreen'));
  output_dir = fullfile(config.output_root, output_label);
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end

  log_path = fullfile(output_dir, 'run.log');
  log_fid = fopen(log_path, 'w');
  if log_fid < 0
    error('run_i4_extract_oracles:LogOpenFailed', ...
      'Could not open %s.', log_path);
  end
  log_cleanup = onCleanup(@() fclose(log_fid));

  is_octave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
  ewald_backend = 'repository Faddeeva_erfc';
  if is_octave && isempty(which('Faddeeva_erfc'))
    addpath(fullfile(config.here, 'octave_compat'));
    ewald_backend = 'Octave complex erfc compatibility shim';
  end

  LOCAL_log(log_fid, 'i4 extraction oracles\n');
  LOCAL_log(log_fid, 'Output: %s\n', output_dir);
  LOCAL_log(log_fid, ['Frozen runtime budget: %.0f--%.0f seconds ', ...
    '(35--45 minutes)\n'], ...
    config.expected_runtime_seconds(1), config.expected_runtime_seconds(2));
  LOCAL_log(log_fid, 'Ewald erfc backend: %s\n', ewald_backend);

  pars1 = struct('d', config.d, 'beta', config.beta, 'k', config.k, ...
    'periodic_axis', 'y');
  channels = bloch.rayleigh_channels(config.k, config.beta, config.d, ...
    config.M, config.L);

  timings_headers = {'stage', 'seconds'};
  timings_rows = cell(0, length(timings_headers));
  total_token = tic;

  % --- stage 1: pure Rayleigh projection ---
  LOCAL_log(log_fid, 'Stage A: pure Rayleigh wall projection ...\n');
  token = tic;
  [pure_rows, pure_summary] = LOCAL_pure_projection(config, channels);
  timings_rows(end + 1, :) = {'pure_projection', toc(token)};

  % --- stage 2: continuous circle coefficients and package extractor ---
  LOCAL_log(log_fid, 'Stage B: circle Bessel coefficients and extractor ...\n');
  token = tic;
  [circle_rows, nested_rows, circle_summary, exact, package_high] = ...
    LOCAL_circle_coefficients(config, channels);
  timings_rows(end + 1, :) = {'circle_coefficients', toc(token)};

  % --- stage 3: precompute the two frozen proxy levels ---
  LOCAL_log(log_fid, 'Stage C0: proxy precomputations high and higher ...\n');
  token = tic;
  proxy_high = kernel.precomp_proxy(pars1, config.proxy_high);
  proxy_high_seconds = toc(token);
  token = tic;
  proxy_higher = kernel.precomp_proxy(pars1, config.proxy_higher);
  proxy_higher_seconds = toc(token);
  timings_rows(end + 1, :) = {'proxy_high', proxy_high_seconds};
  timings_rows(end + 1, :) = {'proxy_higher', proxy_higher_seconds};

  % --- stage 4: exact and MFS wall projection refinements ---
  LOCAL_log(log_fid, 'Stage C: exact-wall and MFS wall projections ...\n');
  token = tic;
  [wall_rows, wall_summary, wall_case_timings] = LOCAL_wall_oracles( ...
    config, channels, pars1, ...
    proxy_high, proxy_higher, exact, package_high, log_fid);
  for ir = 1:size(wall_case_timings, 1)
    timings_rows(end + 1, :) = wall_case_timings(ir, :);
  end
  timings_rows(end + 1, :) = {'wall_oracles', toc(token)};

  % --- stage 5: point spectral/Ewald/MFS comparison and slopes ---
  LOCAL_log(log_fid, 'Stage D: point Green value and delta-M slope ...\n');
  token = tic;
  [point_rows, slope_rows, point_summary] = LOCAL_point_oracles(config, ...
    pars1, proxy_high, proxy_higher);
  timings_rows(end + 1, :) = {'point_oracles', toc(token)};

  % --- stage 6: negative metadata and frozen gates ---
  negative_headers = {'case_name', 'delta', 'k', 'm', 'min_abs_gamma', ...
    'status', 'root_claim', 'reason'};
  negative_rows = LOCAL_negative_metadata(config);
  [gate_headers, gate_rows, gate_summary] = LOCAL_gates(config, ...
    pure_summary, circle_summary, wall_summary, point_summary);

  total_seconds = toc(total_token);
  timings_rows(end + 1, :) = {'total', total_seconds};

  % --- stage 7: persist audit ledgers ---
  pure_headers = {'Ny', 'side', 'trace', 'm', 'exact_real', 'exact_imag', ...
    'observed_real', 'observed_imag', 'abs_error'};
  circle_headers = {'ntot_low', 'ntot_high', 'layer', 'side', 'm', ...
    'exact_real', 'exact_imag', 'formula_quad_real', 'formula_quad_imag', ...
    'formula_error', 'package_low_error', 'package_high_error', ...
    'boundary_ntot_change', 'resolved', 'resolved_action_pass'};
  nested_headers = {'M_coarse', 'M_fine', 'ntot', 'layer', 'side', 'm', ...
    'coarse_real', 'coarse_imag', 'fine_real', 'fine_imag', ...
    'retained_change'};
  wall_headers = {'family', 'level', 'ntot', 'Ny', 'proxy_level', ...
    'layer', 'side', 'trace', 'm', 'exact_real', 'exact_imag', ...
    'observed_real', 'observed_imag', 'abs_error'};
  point_headers = {'delta', 'spectral_M', 'ewald_low_real', ...
    'ewald_low_imag', 'ewald_high_real', 'ewald_high_imag', ...
    'ewald_two_level_change', 'spectral_real', 'spectral_imag', ...
    'spectral_vs_ewald', 'mfs_high_real', 'mfs_high_imag', ...
    'mfs_higher_real', 'mfs_higher_imag', 'mfs_high_error', ...
    'mfs_higher_error', 'mfs_two_level_change'};
  slope_headers = {'delta', 'branch', 'm_first', 'm_last', ...
    'expected_slope', 'fitted_slope', 'relative_error', 'sanity_pass'};

  LOCAL_write_csv(fullfile(output_dir, 'pure-projection.csv'), ...
    pure_headers, pure_rows);
  LOCAL_write_csv(fullfile(output_dir, 'circle-coefficients.csv'), ...
    circle_headers, circle_rows);
  LOCAL_write_csv(fullfile(output_dir, 'nested-M.csv'), ...
    nested_headers, nested_rows);
  LOCAL_write_csv(fullfile(output_dir, 'wall-projection.csv'), ...
    wall_headers, wall_rows);
  LOCAL_write_csv(fullfile(output_dir, 'point-green.csv'), ...
    point_headers, point_rows);
  LOCAL_write_csv(fullfile(output_dir, 'delta-slope.csv'), ...
    slope_headers, slope_rows);
  LOCAL_write_csv(fullfile(output_dir, 'negative-metadata.csv'), ...
    negative_headers, negative_rows);
  LOCAL_write_csv(fullfile(output_dir, 'gates.csv'), gate_headers, gate_rows);
  LOCAL_write_csv(fullfile(output_dir, 'timings.csv'), ...
    timings_headers, timings_rows);

  results = struct();
  results.config = config;
  results.provenance = struct('runtime', LOCAL_runtime_name(is_octave), ...
    'ewald_backend', ewald_backend, ...
    'ewald_axis_map', 'physical (x,y) -> benchmark (y,x)', ...
    'root_claim_for_negative_controls', false);
  results.pure_summary = pure_summary;
  results.circle_summary = circle_summary;
  results.wall_summary = wall_summary;
  results.point_summary = point_summary;
  results.gate_summary = gate_summary;
  results.pure_rows = pure_rows;
  results.circle_rows = circle_rows;
  results.nested_rows = nested_rows;
  results.wall_rows = wall_rows;
  results.point_rows = point_rows;
  results.slope_rows = slope_rows;
  results.negative_rows = negative_rows;
  results.gate_rows = gate_rows;
  results.timings_rows = timings_rows;
  results.output_dir = output_dir;
  results.total_seconds = total_seconds;
  if is_octave
    save(fullfile(output_dir, 'results.mat'), 'results', '-mat7-binary');
  else
    save(fullfile(output_dir, 'results.mat'), 'results', '-v7');
  end
  LOCAL_write_report(fullfile(output_dir, 'report.md'), results);

  LOCAL_log(log_fid, 'Overall mandatory gate pass: %d\n', ...
    gate_summary.overall_pass);
  LOCAL_log(log_fid, 'Slope sanity pass: %d\n', point_summary.slope_pass);
  LOCAL_log(log_fid, 'Total seconds: %.6f\n', total_seconds);
  LOCAL_log(log_fid, 'Artifacts written to %s\n', output_dir);
  clear log_cleanup;
end

%% ==================== Manufactured projection oracles ====================
% These helpers evaluate finite Rayleigh sums and continuous circle actions.

function [rows, summary] = LOCAL_pure_projection(config, channels)
  rows = cell(0, 9);
  index = LOCAL_mode_indices(channels.m, config.pure_modes);
  beta_m = channels.beta_m(index);
  gamma_m = channels.gamma_m(index);
  max_error = 0;
  level_values = cell(length(config.pure_Ny), 4);

  for iq = 1:length(config.pure_Ny)
    Ny = config.pure_Ny(iq);
    yq = config.d * (0:Ny - 1) / Ny;
    psi = (1 / sqrt(config.d)) * exp(1i * (beta_m * yq));
    u_L = config.pure_coeff_L.' * psi;
    u_R = config.pure_coeff_R.' * psi;
    dx_L = ((-1i * gamma_m) .* config.pure_coeff_L).' * psi;
    dx_R = ((1i * gamma_m) .* config.pure_coeff_R).' * psi;
    D_L = LOCAL_fourier_project(config.d, beta_m, yq, u_L);
    D_R = LOCAL_fourier_project(config.d, beta_m, yq, u_R);
    N_L = -LOCAL_fourier_project(config.d, beta_m, yq, dx_L) ./ ...
      (1i * gamma_m);
    N_R = LOCAL_fourier_project(config.d, beta_m, yq, dx_R) ./ ...
      (1i * gamma_m);
    level_values(iq, :) = {D_L, N_L, D_R, N_R};

    sides = {'L', 'L', 'R', 'R'};
    traces = {'D', 'N', 'D', 'N'};
    refs = {config.pure_coeff_L, config.pure_coeff_L, ...
      config.pure_coeff_R, config.pure_coeff_R};
    values = {D_L, N_L, D_R, N_R};
    for it = 1:4
      for im = 1:length(config.pure_modes)
        err = abs(values{it}(im) - refs{it}(im));
        max_error = max(max_error, err);
        rows(end + 1, :) = {Ny, sides{it}, traces{it}, ...
          config.pure_modes(im), real(refs{it}(im)), imag(refs{it}(im)), ...
          real(values{it}(im)), imag(values{it}(im)), err};
      end
    end
  end

  refinement = 0;
  for it = 1:4
    refinement = max(refinement, max(abs( ...
      level_values{1, it} - level_values{2, it})));
  end
  summary.max_error = max_error;
  summary.refinement_change = refinement;
end

function [rows, nested_rows, summary, exact, package_high] = ...
    LOCAL_circle_coefficients(config, channels)
  rows = cell(0, 15);
  nested_rows = cell(0, 11);
  exact = LOCAL_closed_circle_actions(config, channels);
  package = cell(1, length(config.boundary_ntot));
  for in = 1:length(config.boundary_ntot)
    package{in} = LOCAL_package_circle_actions(config, channels, ...
      config.boundary_ntot(in));
  end
  package_high = package{end};

  formula_max = 0;
  action_max = 0;
  nested_max = 0;
  exact_scale = LOCAL_action_scale(exact);
  layers = {'single', 'double'};
  sides = {'L', 'R'};
  for il = 1:length(layers)
    layer = layers{il};
    for is = 1:length(sides)
      side = sides{is};
      quad = LOCAL_direct_circle_action(config, channels, layer, side);
      for im = 1:channels.K
        ref = exact.(layer).(side)(im);
        low = package{1}.(layer).(side)(im);
        high = package{end}.(layer).(side)(im);
        formula_error = abs(quad(im) - ref);
        low_error = abs(low - ref);
        high_error = abs(high - ref);
        boundary_change = abs(high - low);
        resolved = abs(ref) >= config.resolved_floor * exact_scale;
        action_pass = (~resolved) || ...
          (high_error <= config.gate.resolved_action);
        formula_max = max(formula_max, formula_error);
        if resolved
          action_max = max(action_max, high_error);
        end
        rows(end + 1, :) = {config.boundary_ntot(1), ...
          config.boundary_ntot(end), layer, side, channels.m(im), ...
          real(ref), imag(ref), real(quad(im)), imag(quad(im)), ...
          formula_error, low_error, high_error, boundary_change, ...
          resolved, action_pass};
      end
    end
  end

  nested_actions = cell(1, length(config.nested_M));
  nested_channels = cell(1, length(config.nested_M));
  for iM = 1:length(config.nested_M)
    nested_channels{iM} = bloch.rayleigh_channels(config.k, config.beta, ...
      config.d, config.nested_M(iM), config.L);
    nested_actions{iM} = LOCAL_package_circle_actions(config, ...
      nested_channels{iM}, config.boundary_ntot(end));
  end
  for iM = 1:length(config.nested_M) - 1
    coarse_channels = nested_channels{iM};
    fine_channels = nested_channels{iM + 1};
    fine_index = LOCAL_mode_indices(fine_channels.m, coarse_channels.m);
    for il = 1:length(layers)
      layer = layers{il};
      for is = 1:length(sides)
        side = sides{is};
        coarse = nested_actions{iM}.(layer).(side);
        fine = nested_actions{iM + 1}.(layer).(side)(fine_index);
        for im = 1:coarse_channels.K
          change = abs(fine(im) - coarse(im));
          nested_max = max(nested_max, change);
          nested_rows(end + 1, :) = {config.nested_M(iM), ...
            config.nested_M(iM + 1), config.boundary_ntot(end), layer, ...
            side, coarse_channels.m(im), real(coarse(im)), imag(coarse(im)), ...
            real(fine(im)), imag(fine(im)), change};
        end
      end
    end
  end
  summary.formula_max_error = formula_max;
  summary.resolved_action_max_error = action_max;
  summary.nested_retained_max_change = nested_max;
  summary.action_scale = exact_scale;
end

function exact = LOCAL_closed_circle_actions(config, channels)
  sides = {'L', 'R'};
  for is = 1:2
    side = sides{is};
    [a, b, phase] = LOCAL_side_phase(config, channels, side);
    gscale = 1i ./ (2 * sqrt(config.d) * channels.gamma_m) .* phase;
    single = zeros(channels.K, 1);
    double = zeros(channels.K, 1);
    for ih = 1:length(config.density_ell)
      ell = config.density_ell(ih);
      rho_coeff = config.density_coeff(ih);
      q = (a + 1i * b) / config.k;
      I = 2 * pi * (1i ^ ell) .* (q .^ ell) .* ...
        besselj(ell, config.k * config.R);
      Jprime = 0.5 * (besselj(ell - 1, config.k * config.R) - ...
        besselj(ell + 1, config.k * config.R));
      dI = 2 * pi * (1i ^ ell) .* (q .^ ell) .* config.k .* Jprime;
      single = single - config.R * rho_coeff * gscale .* I;
      double = double + config.R * rho_coeff * gscale .* dI;
    end
    exact.single.(side) = single;
    exact.double.(side) = double;
  end
end

function values = LOCAL_direct_circle_action(config, channels, layer, side)
  theta = 2 * pi * (0:config.formula_ntheta - 1) / ...
    config.formula_ntheta;
  rho = LOCAL_density(theta, config);
  [a, b, phase] = LOCAL_side_phase(config, channels, side);
  values = zeros(channels.K, 1);
  dtheta = 2 * pi / config.formula_ntheta;
  for im = 1:channels.K
    exponential = exp(1i * config.R * ...
      (a(im) * cos(theta) + b(im) * sin(theta)));
    gscale = 1i / (2 * sqrt(config.d) * channels.gamma_m(im)) * phase(im);
    if strcmp(layer, 'single')
      values(im) = -config.R * gscale * dtheta * sum(rho .* exponential);
    else
      radial_factor = 1i * (a(im) * cos(theta) + b(im) * sin(theta));
      values(im) = config.R * gscale * dtheta * ...
        sum(rho .* radial_factor .* exponential);
    end
  end
end

function values = LOCAL_package_circle_actions(config, channels, ntot)
  [C, curvelen] = geom.construct_cont(ntot, 'circle', 0, 0, config.R);
  [F_L, F_R] = bloch.farfield_extractors(C, channels, ...
    config.X_L, config.X_R, curvelen);
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  rho = LOCAL_density(theta, config);
  eta_single = [zeros(ntot, 1); rho];
  eta_double = [rho; zeros(ntot, 1)];
  values.single.L = F_L * eta_single;
  values.single.R = F_R * eta_single;
  values.double.L = F_L * eta_double;
  values.double.R = F_R * eta_double;
end

%% ==================== Direct wall evaluation oracles ====================
% These helpers isolate exact-wall projection and MFS refinement variables.

function [rows, summary, case_timings] = LOCAL_wall_oracles( ...
    config, channels, pars1, ...
    proxy_high, proxy_higher, exact, package_high, log_fid)
  rows = cell(0, 14);
  case_timings = cell(0, 2);
  layers = {'single', 'double'};
  sides = {'L', 'R'};
  traces = {'D', 'N'};

  exact_levels = cell(1, length(config.exact_wall_Ny));
  exact_projection_max = 0;
  for iq = 1:length(config.exact_wall_Ny)
    Ny = config.exact_wall_Ny(iq);
    exact_levels{iq} = LOCAL_exact_wall_coefficients(config, channels, exact, Ny);
    for il = 1:2
      for is = 1:2
        for it = 1:2
          layer = layers{il}; side = sides{is}; trace = traces{it};
          observed = exact_levels{iq}.(layer).(side).(trace);
          ref = exact.(layer).(side);
          for im = 1:channels.K
            err = abs(observed(im) - ref(im));
            exact_projection_max = max(exact_projection_max, err);
            rows(end + 1, :) = {'exact_wall', sprintf('Ny%d', Ny), 0, Ny, ...
              'none', layer, side, trace, channels.m(im), real(ref(im)), ...
              imag(ref(im)), real(observed(im)), imag(observed(im)), err};
          end
        end
      end
    end
  end
  exact_adjacent = zeros(length(exact_levels) - 1, 1);
  for iq = 1:length(exact_levels) - 1
    exact_adjacent(iq) = LOCAL_action_difference( ...
      exact_levels{iq}, exact_levels{iq + 1});
  end
  exact_refinement = exact_adjacent(end);

  cases = { ...
    'boundary_low', config.boundary_ntot(1), config.mfs_Ny(1), ...
      'high', proxy_high; ...
    'boundary_mid', config.boundary_ntot(2), config.mfs_Ny(1), ...
      'high', proxy_high; ...
    'baseline', config.boundary_ntot(end), config.mfs_Ny(1), ...
      'high', proxy_high; ...
    'Ny_refined', config.boundary_ntot(end), config.mfs_Ny(2), ...
      'high', proxy_high; ...
    'proxy_refined', config.boundary_ntot(end), config.mfs_Ny(2), ...
      'higher', proxy_higher};
  mfs = cell(size(cases, 1), 1);
  for ic = 1:size(cases, 1)
    LOCAL_log(log_fid, '  MFS case %-13s ntot=%d Ny=%d proxy=%s\n', ...
      cases{ic, 1}, cases{ic, 2}, cases{ic, 3}, cases{ic, 4});
    case_token = tic;
    mfs{ic} = LOCAL_mfs_circle_actions(config, channels, pars1, ...
      cases{ic, 5}, cases{ic, 2}, cases{ic, 3});
    case_seconds = toc(case_token);
    case_timings(end + 1, :) = {['mfs_', cases{ic, 1}], case_seconds};
    LOCAL_log(log_fid, '    completed in %.6f seconds\n', case_seconds);
    for il = 1:2
      for is = 1:2
        for it = 1:2
          layer = layers{il}; side = sides{is}; trace = traces{it};
          observed = mfs{ic}.(layer).(side).(trace);
          ref = exact.(layer).(side);
          for im = 1:channels.K
            err = abs(observed(im) - ref(im));
            rows(end + 1, :) = {'mfs_wall', cases{ic, 1}, ...
              cases{ic, 2}, cases{ic, 3}, cases{ic, 4}, layer, side, ...
              trace, channels.m(im), real(ref(im)), imag(ref(im)), ...
              real(observed(im)), imag(observed(im)), err};
          end
        end
      end
    end
  end

  summary.exact_projection_max_error = exact_projection_max;
  summary.exact_wall_refinement_change = exact_refinement;
  boundary_adjacent = [LOCAL_action_difference(mfs{1}, mfs{2}); ...
    LOCAL_action_difference(mfs{2}, mfs{3})];
  summary.boundary_refinement_change = boundary_adjacent(end);
  summary.boundary_refinement_max_adjacent = max(boundary_adjacent);
  summary.exact_wall_refinement_max_adjacent = max(exact_adjacent);
  summary.Ny_refinement_change = LOCAL_action_difference(mfs{3}, mfs{4});
  summary.proxy_refinement_change = LOCAL_action_difference(mfs{4}, mfs{5});
  summary.mfs_reference_max_error = LOCAL_action_reference_error(mfs{5}, exact);
  summary.existing_extractor_max_error = ...
    LOCAL_action_reference_error(mfs{5}, package_high);
end

function values = LOCAL_exact_wall_coefficients(config, channels, exact, Ny)
  yq = config.d * (0:Ny - 1) / Ny;
  psi = (1 / sqrt(config.d)) * exp(1i * (channels.beta_m * yq));
  layers = {'single', 'double'};
  sides = {'L', 'R'};
  for il = 1:2
    for is = 1:2
      layer = layers{il}; side = sides{is};
      coeff = exact.(layer).(side);
      u = coeff.' * psi;
      if strcmp(side, 'L')
        dx = ((-1i * channels.gamma_m) .* coeff).' * psi;
      else
        dx = ((1i * channels.gamma_m) .* coeff).' * psi;
      end
      values.(layer).(side).D = ...
        LOCAL_fourier_project(config.d, channels.beta_m, yq, u);
      dx_coeff = LOCAL_fourier_project(config.d, channels.beta_m, yq, dx);
      if strcmp(side, 'L')
        values.(layer).(side).N = -dx_coeff ./ (1i * channels.gamma_m);
      else
        values.(layer).(side).N = dx_coeff ./ (1i * channels.gamma_m);
      end
    end
  end
end

function values = LOCAL_mfs_circle_actions(config, channels, pars1, ...
    proxy, ntot, Ny)
  [C, curvelen] = geom.construct_cont(ntot, 'circle', 0, 0, config.R);
  theta = 2 * pi * (0:ntot - 1).' / ntot;
  rho = LOCAL_density(theta, config);
  x = C(1, :).'; y = C(4, :).';
  dxdt = C(2, :).'; dydt = C(5, :).';
  speed = sqrt(dxdt .^ 2 + dydt .^ 2);
  nx = dydt ./ speed; ny = -dxdt ./ speed;
  weights = (curvelen / ntot) * speed;
  rho_w = rho .* weights;
  yq = config.d * (0:Ny - 1) / Ny;
  src = [x.'; y.'];
  targets = { ...
    [config.X_L * ones(1, Ny); yq], ...
    [config.X_R * ones(1, Ny); yq]};
  sides = {'L', 'R'};
  for is = 1:2
    [pot, gradx, grady, hessxx, hessxy, ~] = ...
      kernel.qpgreen_mfs_pairmat(src, targets{is}, pars1, proxy);
    dGdnu = -bsxfun(@times, gradx, nx.') - ...
      bsxfun(@times, grady, ny.');
    dx_dGdnu = -bsxfun(@times, hessxx, nx.') - ...
      bsxfun(@times, hessxy, ny.');
    fields.single.u = -pot * rho_w;
    fields.single.dx = -gradx * rho_w;
    fields.double.u = dGdnu * rho_w;
    fields.double.dx = dx_dGdnu * rho_w;
    layers = {'single', 'double'};
    for il = 1:2
      layer = layers{il}; side = sides{is};
      values.(layer).(side).D = LOCAL_fourier_project( ...
        config.d, channels.beta_m, yq, fields.(layer).u.');
      dx_coeff = LOCAL_fourier_project(config.d, channels.beta_m, ...
        yq, fields.(layer).dx.');
      if strcmp(side, 'L')
        values.(layer).(side).N = -dx_coeff ./ ...
          (1i * channels.gamma_m);
      else
        values.(layer).(side).N = dx_coeff ./ ...
          (1i * channels.gamma_m);
      end
    end
  end
end

%% ==================== Point Green and slope oracles ====================
% These helpers compare value-only Ewald, spectral, and MFS evaluations.

function [point_rows, slope_rows, summary] = LOCAL_point_oracles(config, ...
    pars1, proxy_high, proxy_higher)
  point_rows = cell(0, 17);
  slope_rows = cell(0, 8);
  ewald_change_max = 0;
  spectral_error_max = 0;
  mfs_high_error_max = 0;
  mfs_higher_error_max = 0;
  mfs_change_max = 0;
  slope_error_max = 0;

  for id = 1:length(config.point_delta)
    delta = config.point_delta(id);
    src = [config.X_R - delta; config.point_source_y];
    trg = [config.X_R; config.point_target_y];
    src_ewald = src([2 1]);
    trg_ewald = trg([2 1]);
    pars_ewald = rmfield(pars1, 'periodic_axis');
    ewald_low = qpgreen_ewald_xperiodic_bench(src_ewald, trg_ewald, ...
      pars_ewald, config.ewald_low);
    ewald_high = qpgreen_ewald_xperiodic_bench(src_ewald, trg_ewald, ...
      pars_ewald, config.ewald_high);
    ewald_change = abs(ewald_high - ewald_low);
    ewald_change_max = max(ewald_change_max, ewald_change);

    [mfs_high, ~, ~, ~, ~, ~] = kernel.qpgreen_mfs_pairmat( ...
      src, trg, pars1, proxy_high);
    [mfs_higher, ~, ~, ~, ~, ~] = kernel.qpgreen_mfs_pairmat( ...
      src, trg, pars1, proxy_higher);
    mfs_high_error = abs(mfs_high - ewald_high);
    mfs_higher_error = abs(mfs_higher - ewald_high);
    mfs_change = abs(mfs_higher - mfs_high);
    mfs_high_error_max = max(mfs_high_error_max, mfs_high_error);
    mfs_higher_error_max = max(mfs_higher_error_max, mfs_higher_error);
    mfs_change_max = max(mfs_change_max, mfs_change);

    for iM = 1:length(config.point_spectral_M)
      M = config.point_spectral_M(iM);
      spectral = LOCAL_qpgreen_spectral_value(config, src, trg, M);
      spectral_error = abs(spectral - ewald_high);
      spectral_error_max = max(spectral_error_max, spectral_error);
      point_rows(end + 1, :) = {delta, M, real(ewald_low), ...
        imag(ewald_low), real(ewald_high), imag(ewald_high), ...
        ewald_change, real(spectral), imag(spectral), spectral_error, ...
        real(mfs_high), imag(mfs_high), real(mfs_higher), ...
        imag(mfs_higher), mfs_high_error, mfs_higher_error, mfs_change};
    end

    expected = -2 * pi * delta / config.d;
    branches = {'positive', 'negative'};
    signs = [1, -1];
    for ib = 1:2
      m = signs(ib) * config.slope_modes;
      beta_m = config.beta + 2 * pi * m / config.d;
      gamma_m = sqrt(config.k ^ 2 - beta_m .^ 2);
      flip = imag(gamma_m) < 0;
      gamma_m(flip) = -gamma_m(flip);
      coefficient = 1i ./ (2 * config.d * gamma_m) .* ...
        exp(1i * gamma_m * delta);
      adjusted = abs(coefficient .* gamma_m * (2 * config.d / 1i));
      fit_data = polyfit(abs(m), log(adjusted), 1);
      fitted = fit_data(1);
      relative_error = abs(fitted - expected) / abs(expected);
      slope_error_max = max(slope_error_max, relative_error);
      slope_rows(end + 1, :) = {delta, branches{ib}, ...
        min(abs(m)), max(abs(m)), expected, fitted, relative_error, ...
        relative_error <= config.gate.slope_relative};
    end
  end
  summary.ewald_two_level_max_change = ewald_change_max;
  summary.spectral_vs_ewald_max_error_all_M = spectral_error_max;
  summary.mfs_high_max_error = mfs_high_error_max;
  summary.mfs_higher_max_error = mfs_higher_error_max;
  summary.mfs_two_level_max_change = mfs_change_max;
  summary.slope_max_relative_error = slope_error_max;
  summary.slope_pass = slope_error_max <= config.gate.slope_relative;
end

function value = LOCAL_qpgreen_spectral_value(config, src, trg, M)
  m = (-M:M).';
  beta_m = config.beta + 2 * pi * m / config.d;
  gamma_m = sqrt(config.k ^ 2 - beta_m .^ 2);
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);
  dx = trg(1) - src(1);
  dy = trg(2) - src(2);
  value = 1i / (2 * config.d) * sum(exp(1i * beta_m * dy) .* ...
    exp(1i * gamma_m * abs(dx)) ./ gamma_m);
end

function rows = LOCAL_negative_metadata(config)
  rows = cell(0, 8);
  rows(end + 1, :) = {'delta_zero', 0, config.k, NaN, NaN, ...
    'NEGATIVE_CONTROL_NO_ROOT_CLAIM', false, ...
    'Source lies on the wall; the point Green value is singular.'};
  wood_m = 0;
  k_near = abs(config.beta + 2 * pi * wood_m / config.d) + 1e-12;
  gamma = sqrt(k_near ^ 2 - ...
    (config.beta + 2 * pi * wood_m / config.d) ^ 2);
  rows(end + 1, :) = {'near_wood', NaN, k_near, wood_m, abs(gamma), ...
    'NEGATIVE_CONTROL_NO_ROOT_CLAIM', false, ...
    'A near-grazing Rayleigh denominator invalidates a uniform root claim.'};
end

%% ==================== Gate aggregation and shared math ====================
% These helpers aggregate frozen decisions without changing tolerances.

function [headers, rows, summary] = LOCAL_gates(config, pure, circle, wall, point)
  headers = {'gate', 'value', 'tolerance', 'pass', 'mandatory', 'note'};
  budget = circle.formula_max_error + wall.boundary_refinement_change + ...
    wall.exact_wall_refinement_change + wall.mfs_reference_max_error;
  rows = { ...
    'pure_projection', pure.max_error, config.gate.pure_projection, ...
      pure.max_error <= config.gate.pure_projection, true, 'L/R and D/N'; ...
    'formula_code', circle.formula_max_error, config.gate.formula_code, ...
      circle.formula_max_error <= config.gate.formula_code, true, ...
      'Bessel closed form versus direct angular quadrature'; ...
    'resolved_action', circle.resolved_action_max_error, ...
      config.gate.resolved_action, ...
      circle.resolved_action_max_error <= config.gate.resolved_action, true, ...
      'package extractor versus continuous coefficient'; ...
    'nested_retained_row', circle.nested_retained_max_change, ...
      config.gate.nested_retained, ...
      circle.nested_retained_max_change <= config.gate.nested_retained, true, ...
      sprintf('fixed ntot=%d; M=[%s]', config.boundary_ntot(end), ...
        sprintf('%d ', config.nested_M)); ...
    'boundary_refinement', wall.boundary_refinement_change, ...
      config.gate.boundary_refinement, ...
      wall.boundary_refinement_change <= config.gate.boundary_refinement, true, ...
      sprintf('MFS wall finest ntot %d to %d at fixed Ny/proxy', ...
        config.boundary_ntot(end - 1), config.boundary_ntot(end)); ...
    'exact_wall_refinement', wall.exact_wall_refinement_change, ...
      config.gate.exact_wall_refinement, ...
      wall.exact_wall_refinement_change <= config.gate.exact_wall_refinement, ...
      true, sprintf('exact retained wall finest Ny %d to %d', ...
        config.exact_wall_Ny(end - 1), config.exact_wall_Ny(end)); ...
    'mfs_reference', wall.mfs_reference_max_error, ...
      config.gate.mfs_reference, ...
      wall.mfs_reference_max_error <= config.gate.mfs_reference, true, ...
      'higher proxy wall D/N versus continuous coefficient'; ...
    'mfs_two_level_change', wall.proxy_refinement_change, ...
      config.gate.mfs_two_level_change, ...
      wall.proxy_refinement_change <= config.gate.mfs_two_level_change, true, ...
      'high to higher proxy at fixed ntot and Ny'; ...
    'existing_extractor', wall.existing_extractor_max_error, ...
      config.gate.existing_extractor, ...
      wall.existing_extractor_max_error <= config.gate.existing_extractor, ...
      true, 'MFS wall versus package extractor'; ...
    'four_layer_budget', budget, config.gate.four_layer_budget, ...
      budget <= config.gate.four_layer_budget, true, ...
      'formula + boundary + exact-wall + MFS reference'; ...
    'ewald_two_level', point.ewald_two_level_max_change, ...
      config.gate.mfs_reference, ...
      point.ewald_two_level_max_change <= config.gate.mfs_reference, true, ...
      'value-only benchmark Ewald reference eligibility'; ...
    'point_mfs_reference', point.mfs_higher_max_error, ...
      config.gate.mfs_reference, ...
      point.mfs_higher_max_error <= config.gate.mfs_reference, true, ...
      'point pairmat higher proxy versus Ewald'; ...
    'point_mfs_two_level', point.mfs_two_level_max_change, ...
      config.gate.mfs_two_level_change, ...
      point.mfs_two_level_max_change <= config.gate.mfs_two_level_change, true, ...
      'point pairmat high to higher proxy'; ...
    'delta_M_slope_sanity', point.slope_max_relative_error, ...
      config.gate.slope_relative, point.slope_pass, false, ...
      'sanity only; excluded from mandatory overall pass'};
  mandatory_pass = true;
  for ir = 1:size(rows, 1)
    if rows{ir, 5}
      mandatory_pass = mandatory_pass && rows{ir, 4};
    end
  end
  summary.overall_pass = mandatory_pass;
  summary.four_layer_budget = budget;
  summary.mandatory_gate_count = sum(cell2mat(rows(:, 5)));
  summary.mandatory_pass_count = sum(cell2mat(rows(:, 4)) & ...
    cell2mat(rows(:, 5)));
end

function rho = LOCAL_density(theta, config)
  rho = zeros(size(theta));
  for ih = 1:length(config.density_ell)
    rho = rho + config.density_coeff(ih) * ...
      exp(1i * config.density_ell(ih) * theta);
  end
end

function [a, b, phase] = LOCAL_side_phase(config, channels, side)
  if strcmp(side, 'L')
    a = channels.gamma_m;
    b = -channels.beta_m;
    phase = exp(-1i * channels.gamma_m * config.X_L);
  else
    a = -channels.gamma_m;
    b = -channels.beta_m;
    phase = exp(1i * channels.gamma_m * config.X_R);
  end
end

function coeff = LOCAL_fourier_project(d, beta_m, yq, field)
  psi = (1 / sqrt(d)) * exp(1i * (beta_m * yq));
  coeff = (d / length(yq)) * (conj(psi) * field(:));
end

function index = LOCAL_mode_indices(all_modes, requested)
  index = zeros(length(requested), 1);
  for im = 1:length(requested)
    match = find(all_modes == requested(im));
    if length(match) ~= 1
      error('run_i4_extract_oracles:MissingMode', ...
        'Requested mode %d does not occur exactly once.', requested(im));
    end
    index(im) = match;
  end
end

function scale = LOCAL_action_scale(values)
  scale = 1;
  layers = {'single', 'double'};
  sides = {'L', 'R'};
  for il = 1:2
    for is = 1:2
      scale = max(scale, max(abs(values.(layers{il}).(sides{is}))));
    end
  end
end

function difference = LOCAL_action_difference(left, right)
  difference = 0;
  layers = {'single', 'double'};
  sides = {'L', 'R'};
  traces = {'D', 'N'};
  for il = 1:2
    for is = 1:2
      for it = 1:2
        difference = max(difference, max(abs( ...
          left.(layers{il}).(sides{is}).(traces{it}) - ...
          right.(layers{il}).(sides{is}).(traces{it}))));
      end
    end
  end
end

function error_max = LOCAL_action_reference_error(observed, reference)
  error_max = 0;
  layers = {'single', 'double'};
  sides = {'L', 'R'};
  traces = {'D', 'N'};
  for il = 1:2
    for is = 1:2
      for it = 1:2
        error_max = max(error_max, max(abs( ...
          observed.(layers{il}).(sides{is}).(traces{it}) - ...
          reference.(layers{il}).(sides{is}))));
      end
    end
  end
end

%% ==================== Persistence and reporting ====================
% These helpers write portable CSV and Markdown evidence without tables.

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_extract_oracles:CsvOpenFailed', 'Could not open %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  for ih = 1:length(headers)
    if ih > 1
      fprintf(fid, ',');
    end
    fprintf(fid, '%s', headers{ih});
  end
  fprintf(fid, '\n');
  for ir = 1:size(rows, 1)
    for ic = 1:size(rows, 2)
      if ic > 1
        fprintf(fid, ',');
      end
      LOCAL_write_csv_value(fid, rows{ir, ic});
    end
    fprintf(fid, '\n');
  end
  clear cleanup;
end

function LOCAL_write_csv_value(fid, value)
  if ischar(value)
    value = strrep(value, '"', '""');
    fprintf(fid, '"%s"', value);
  elseif islogical(value)
    fprintf(fid, '%d', value);
  elseif isnumeric(value) && isscalar(value)
    if isnan(value)
      fprintf(fid, 'NaN');
    else
      fprintf(fid, '%.16e', value);
    end
  else
    error('run_i4_extract_oracles:CsvValue', ...
      'CSV values must be scalar numeric, logical, or char.');
  end
end

function LOCAL_write_report(path, results)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_extract_oracles:ReportOpenFailed', ...
      'Could not open %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# i4 Extraction Oracle Report\n\n');
  fprintf(fid, '- Runtime: `%s`\n', results.provenance.runtime);
  fprintf(fid, '- Ewald erfc backend: `%s`\n', ...
    results.provenance.ewald_backend);
  fprintf(fid, '- Total seconds: `%.6f`\n', results.total_seconds);
  fprintf(fid, '- Mandatory overall pass: `%d`\n', ...
    results.gate_summary.overall_pass);
  fprintf(fid, '- Mandatory gates passed: `%d/%d`\n\n', ...
    results.gate_summary.mandatory_pass_count, ...
    results.gate_summary.mandatory_gate_count);
  fprintf(fid, '## Frozen gates\n\n');
  fprintf(fid, '| Gate | Value | Tolerance | Pass | Mandatory |\n');
  fprintf(fid, '|---|---:|---:|---:|---:|\n');
  for ir = 1:size(results.gate_rows, 1)
    fprintf(fid, '| %s | %.6e | %.6e | %d | %d |\n', ...
      results.gate_rows{ir, 1}, results.gate_rows{ir, 2}, ...
      results.gate_rows{ir, 3}, results.gate_rows{ir, 4}, ...
      results.gate_rows{ir, 5});
  end
  fprintf(fid, '\n## Interpretation\n\n');
  fprintf(fid, ['The Bessel formula is checked independently by angular ', ...
    'quadrature. The exact-wall rows synthesize retained Rayleigh modes ', ...
    'and therefore isolate Fourier projection. MFS rows use the same ', ...
    'manufactured boundary density but evaluate the package Green function.\n\n']);
  fprintf(fid, ['The point Ewald comparison is value-only. Physical ', ...
    'y-periodicity is mapped to the benchmark x-periodic coordinates by ', ...
    'swapping `(x,y)` to `(y,x)`.\n\n']);
  fprintf(fid, '## Observed refinement diagnosis\n\n');
  fprintf(fid, '- Finest boundary change: `%.6e`\n', ...
    results.wall_summary.boundary_refinement_change);
  fprintf(fid, '- Finest exact-wall change: `%.6e`\n', ...
    results.wall_summary.exact_wall_refinement_change);
  fprintf(fid, '- MFS wall Ny change: `%.6e`\n', ...
    results.wall_summary.Ny_refinement_change);
  fprintf(fid, '- MFS wall high-to-higher proxy change: `%.6e`\n', ...
    results.wall_summary.proxy_refinement_change);
  fprintf(fid, '- Higher-proxy wall reference error: `%.6e`\n', ...
    results.wall_summary.mfs_reference_max_error);
  fprintf(fid, '- Higher-proxy point reference error: `%.6e`\n\n', ...
    results.point_summary.mfs_higher_max_error);
  fprintf(fid, ['`delta_zero` and `near_wood` are negative metadata only. ', ...
    'Neither row makes a root-convergence or uniform-error claim.\n']);
  clear cleanup;
end

function LOCAL_log(fid, varargin)
  fprintf(1, varargin{:});
  fprintf(fid, varargin{:});
  if exist('OCTAVE_VERSION', 'builtin') ~= 0
    fflush(1);
    fflush(fid);
  end
end

function name = LOCAL_runtime_name(is_octave)
  if is_octave
    name = ['Octave ', OCTAVE_VERSION];
  else
    name = ['MATLAB ', version];
  end
end
