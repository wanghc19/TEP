function [result, negative_cases] = i4_fd_track(config, runtime)
% I4_FD_TRACK Run the exact smooth-profile finite-difference control.
%
% Purpose:
%   Reproduce the Fliss 2013 material profile on a sparse finite-difference
%   grid, estimate fixed-beta projected bands, and solve finite-strip
%   positive controls with 8- and 12-cell tails.
%
% Input:
%   config  - Full experiment configuration from i4_fliss_config.
%   runtime - Struct with start_token and max_seconds fields.
%
% Output:
%   result         - Exact-track band, strip, residual, and tail diagnostics.
%   negative_cases - Required no-defect and localization negative controls.
%
% Main algorithm:
%   Discretize -Delta*u = omega^2*rho*u with second-order centered
%   differences.  Perfect-cell calculations impose Bloch phases in x and y;
%   strip calculations impose homogeneous Dirichlet conditions at finite x
%   ends and the fixed beta phase in y.  The mass-normalized Hermitian matrix
%   rho^(-1/2)*K*rho^(-1/2) is passed to eigs.
%
% Based on:
%   Fliss 2013, Section 5, for the smooth material profile and the two
%   published guided-mode controls.
%
% Main changes:
%   Use an independent sparse finite-difference positive control rather than
%   the paper's FEM/DtN discretization.
%
% Numerical goal:
%   Establish an independent positive control for the exact smooth medium.
%   This is not a certified infinite-guide eigenvalue computation.

  cfg = config.exact;
  LOCAL_check_deadline(runtime, 'Track A start');

  result.model_id = cfg.model_id;
  result.claim_scope = cfg.claim_scope;
  result.profile = config.profile;
  result.discretization = 'second-order sparse finite differences';
  result.band_edge_uncertainty_scope = ...
    ['baseline maximum over N80-local versus N40-local, N80 standard, ', ...
    'and N80 shifted grids; pilot gate unavailable'];
  result.contrast_continuation = struct('status', 'not-run', ...
    'reason', ['Track A implements the exact s=1 Fliss profile only; ', ...
    'no smooth-profile contrast continuation was run.']);
  result.cases = repmat(LOCAL_empty_case(), length(cfg.beta), 1);

  for icase = 1:length(cfg.beta)
    LOCAL_check_deadline(runtime, sprintf('Track A case %d band scan', icase));
    one = LOCAL_empty_case();
    one.case_id = icase;
    one.case_name = cfg.case_name{icase};
    one.control_role = cfg.control_role{icase};
    one.beta = cfg.beta(icase);
    one.reference_omega2 = cfg.reference_omega2(icase);
    one.band = LOCAL_band_scan(cfg, one.beta, one.reference_omega2, runtime);

    one.strips = repmat(LOCAL_empty_strip(), ...
      length(cfg.tail_cells_each_side), 1);
    for itail = 1:length(cfg.tail_cells_each_side)
      tail = cfg.tail_cells_each_side(itail);
      LOCAL_check_deadline(runtime, sprintf( ...
        'Track A case %d tail %d solve', icase, tail));
      one.strips(itail) = LOCAL_strip_solve(cfg, one.beta, ...
        one.reference_omega2, tail, true, runtime);
    end

    one.tail_comparison = LOCAL_tail_comparison(one.strips, ...
      one.reference_omega2, cfg.primary_tail_relative_shift_tolerance, ...
      cfg.tail_mass_overlap_tolerance(icase), icase == 1);
    fine = one.strips(end).selected;
    one.positive_control.reference_relative_error = ...
      abs(fine.omega2 - one.reference_omega2) / one.reference_omega2;
    one.positive_control.reference_pass = ...
      one.positive_control.reference_relative_error <= ...
      cfg.reference_relative_tolerance(icase);
    one.positive_control.residual_pass = ...
      fine.normalized_residual <= cfg.residual_tolerance;
    one.positive_control.localization_pass = ...
      fine.center_fraction >= cfg.minimum_center_fraction(icase) && ...
      fine.end_fraction <= cfg.maximum_end_fraction(icase);
    one.positive_control.discrete_gap_pass = ...
      one.band.gap.baseline_gate_pass;
    one.positive_control.scientific_eligible = icase == 1 && ...
      strcmp(config.profile, 'baseline');
    one.positive_control.pass = one.positive_control.reference_pass && ...
      one.positive_control.residual_pass && ...
      one.positive_control.localization_pass && ...
      one.positive_control.discrete_gap_pass && ...
      one.tail_comparison.pass;
    result.cases(icase) = one;
  end

  % --- required negative controls ---

  LOCAL_check_deadline(runtime, 'Track A no-defect negative control');
  no_defect = LOCAL_strip_solve(cfg, cfg.beta(1), ...
    cfg.reference_omega2(1), cfg.negative_tail_cells, false, runtime);
  center_values = [no_defect.modes.center_fraction];
  max_center = max(center_values);
  negative_cases = repmat(LOCAL_empty_negative(), 2, 1);
  negative_cases(1).track = 'A';
  negative_cases(1).name = 'no-defect-center-localization';
  negative_cases(1).value = max_center;
  negative_cases(1).threshold = cfg.no_defect_center_fraction_max;
  negative_cases(1).pass = max_center <= cfg.no_defect_center_fraction_max;
  negative_cases(1).detail = ...
    'Perfect strip must not create a strongly center-localized control mode.';

  manufactured = LOCAL_manufactured_end_control(cfg);
  negative_cases(2).track = 'A';
  negative_cases(2).name = 'manufactured-end-localization';
  negative_cases(2).value = manufactured.end_fraction;
  negative_cases(2).threshold = 0.9;
  negative_cases(2).pass = manufactured.end_fraction >= 0.9 && ...
    manufactured.center_fraction <= 1e-12;
  negative_cases(2).detail = ...
    'An end-supported vector must be classified as end-localized, not centered.';

  result.negative_no_defect = no_defect;
  result.negative_manufactured = manufactured;
  result.completed = true;
  result.scientific_pass = ...
    result.cases(1).positive_control.scientific_eligible && ...
    result.cases(1).positive_control.pass;
  result.negative_controls_pass = all([negative_cases.pass]);
end

%% ==================== Perfect-cell bands ====================
% These helpers construct fixed-beta Bloch bands and edge uncertainties.

function band = LOCAL_band_scan(cfg, beta, reference_omega2, runtime)
  if isfield(cfg, 'spatial_coarse_points_per_cell')
    theta_step = 2 * pi / cfg.theta_count;
    theta_standard = -pi + (0:cfg.theta_count - 1).' * theta_step;
    theta_shifted = theta_standard + theta_step / 2;
    standard = LOCAL_theta_spectrum(cfg.points_per_cell, theta_standard, ...
      cfg, beta, runtime, 'N80 standard');
    shifted = LOCAL_theta_spectrum(cfg.points_per_cell, theta_shifted, ...
      cfg, beta, runtime, 'N80 shifted');
    combined_theta = [theta_standard; theta_shifted];
    combined_omega2 = [standard.omega2; shifted.omega2];
    local_theta = LOCAL_target_refinement_thetas(combined_theta, ...
      combined_omega2, reference_omega2, theta_step / 2);
    local_fine = LOCAL_theta_spectrum(cfg.points_per_cell, local_theta, ...
      cfg, beta, runtime, 'N80 local');

    coarse_standard = LOCAL_theta_spectrum( ...
      cfg.spatial_coarse_points_per_cell, theta_standard, cfg, beta, ...
      runtime, 'N40 standard');
    coarse_local_theta = LOCAL_target_refinement_thetas(theta_standard, ...
      coarse_standard.omega2, reference_omega2, theta_step);
    coarse_local = LOCAL_theta_spectrum( ...
      cfg.spatial_coarse_points_per_cell, coarse_local_theta, cfg, beta, ...
      runtime, 'N40 local');

    fine_all = [standard.omega2; shifted.omega2; local_fine.omega2];
    coarse_all = [coarse_standard.omega2; coarse_local.omega2];
    band.fine_theta = [theta_standard; theta_shifted; local_theta];
    band.omega2 = fine_all;
    band.normalized_residual = [standard.residual; shifted.residual; ...
      local_fine.residual];
    band.eigs_flag = [standard.eigs_flag; shifted.eigs_flag; ...
      local_fine.eigs_flag];
    band.lower = min(fine_all, [], 1);
    band.upper = max(fine_all, [], 1);
    band.standard_lower = min(standard.omega2, [], 1);
    band.standard_upper = max(standard.omega2, [], 1);
    band.shifted_lower = min(shifted.omega2, [], 1);
    band.shifted_upper = max(shifted.omega2, [], 1);
    band.spatial_coarse_lower = min(coarse_all, [], 1);
    band.spatial_coarse_upper = max(coarse_all, [], 1);
    band.lower_uncertainty = max([ ...
      abs(band.lower - band.standard_lower); ...
      abs(band.lower - band.shifted_lower); ...
      abs(band.lower - band.spatial_coarse_lower)], [], 1);
    band.upper_uncertainty = max([ ...
      abs(band.upper - band.standard_upper); ...
      abs(band.upper - band.shifted_upper); ...
      abs(band.upper - band.spatial_coarse_upper)], [], 1);
    band.edge_gate_available = true;
    band.edge_uncertainty_method = ...
      'N80 local versus N40 local, N80 standard, and N80 shifted';
  else
    theta = linspace(-pi, pi, cfg.theta_count).';
    fine = LOCAL_theta_spectrum(cfg.points_per_cell, theta, cfg, beta, ...
      runtime, 'pilot nested theta');
    coarse_idx = 1:2:length(theta);
    band.fine_theta = theta;
    band.omega2 = fine.omega2;
    band.normalized_residual = fine.residual;
    band.eigs_flag = fine.eigs_flag;
    band.lower = min(fine.omega2, [], 1);
    band.upper = max(fine.omega2, [], 1);
    band.standard_lower = band.lower;
    band.standard_upper = band.upper;
    band.shifted_lower = NaN(size(band.lower));
    band.shifted_upper = NaN(size(band.upper));
    band.spatial_coarse_lower = NaN(size(band.lower));
    band.spatial_coarse_upper = NaN(size(band.upper));
    nested_lower = min(fine.omega2(coarse_idx, :), [], 1);
    nested_upper = max(fine.omega2(coarse_idx, :), [], 1);
    band.lower_uncertainty = abs(band.lower - nested_lower);
    band.upper_uncertainty = abs(band.upper - nested_upper);
    band.edge_gate_available = false;
    band.edge_uncertainty_method = ...
      'pilot nested-theta diagnostic only; spatial/local gate unavailable';
  end
  band.max_normalized_residual = max(band.normalized_residual(:));
  band.gap = LOCAL_gap_diagnostic(reference_omega2, band, cfg);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function spectrum = LOCAL_theta_spectrum(n, theta, cfg, beta, runtime, label)
  h = cfg.period_x / n;
  x = -cfg.period_x / 2 + (0:n - 1).' * h;
  y = -cfg.period_y / 2 + (0:n - 1).' * h;
  [X, Y] = ndgrid(x, y);
  rho = LOCAL_smooth_profile(X, Y, cfg, false);
  invsqrt_rho = 1 ./ sqrt(rho(:));
  mass_scale = spdiags(invsqrt_rho, 0, n * n, n * n);
  Dy = LOCAL_qp_second_difference(n, h, beta * cfg.period_y);
  Iy = speye(n);
  Ix = speye(n);
  omega2 = NaN(length(theta), cfg.num_bands);
  residual = NaN(length(theta), cfg.num_bands);
  eigs_flag = NaN(length(theta), 1);

  for j = 1:length(theta)
    LOCAL_check_deadline(runtime, sprintf( ...
      'Track A %s theta %d of %d', label, j, length(theta)));
    Dx = LOCAL_qp_second_difference(n, h, theta(j) * cfg.period_x);
    K = kron(Iy, Dx) + kron(Dy, Ix);
    A = mass_scale * K * mass_scale;
    opts = LOCAL_eigs_options(size(A, 1), cfg);
    [W, D, flag] = eigs(A, cfg.num_bands, -1e-7, opts);
    lambda = real(diag(D));
    [lambda, order] = sort(lambda, 'ascend');
    W = W(:, order);
    omega2(j, :) = lambda.';
    eigs_flag(j) = flag;
    for m = 1:length(lambda)
      u = invsqrt_rho .* W(:, m);
      residual(j, m) = LOCAL_evp_residual(K, rho(:), u, lambda(m));
    end
    LOCAL_check_deadline(runtime, sprintf( ...
      'Track A band theta %d complete', j));
  end

  spectrum.theta = theta;
  spectrum.omega2 = omega2;
  spectrum.residual = residual;
  spectrum.eigs_flag = eigs_flag;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function theta_local = LOCAL_target_refinement_thetas(theta, omega2, ...
    reference_omega2, theta_spacing)
  lower = min(omega2, [], 1);
  upper = max(omega2, [], 1);
  [~, lower_band] = min(abs(upper - reference_omega2));
  [~, upper_band] = min(abs(lower - reference_omega2));
  target_bands = unique([lower_band, upper_band]);
  theta_local = [];
  for j = 1:length(target_bands)
    b = target_bands(j);
    [~, idx_min] = min(omega2(:, b));
    [~, idx_max] = max(omega2(:, b));
    centers = [theta(idx_min), theta(idx_max)];
    theta_local = [theta_local; centers(:) - theta_spacing / 2; ...
      centers(:) + theta_spacing / 2]; %#ok<AGROW>
  end
  theta_local = unique(LOCAL_wrap_theta(theta_local));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function theta = LOCAL_wrap_theta(theta)
  theta = mod(theta + pi, 2 * pi) - pi;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function gap = LOCAL_gap_diagnostic(reference_omega2, band, cfg)
  expanded_lower = band.lower - band.lower_uncertainty;
  expanded_upper = band.upper + band.upper_uncertainty;
  inside = reference_omega2 >= expanded_lower & ...
    reference_omega2 <= expanded_upper;
  lower_indices = find(expanded_upper < reference_omega2);
  upper_indices = find(expanded_lower > reference_omega2);

  gap.in_expanded_band = any(inside);
  gap.reference_omega2 = reference_omega2;
  gap.lower_edge = NaN;
  gap.upper_edge = NaN;
  gap.lower_band_index = NaN;
  gap.upper_band_index = NaN;
  if ~isempty(lower_indices)
    [gap.lower_edge, local_index] = max(expanded_upper(lower_indices));
    gap.lower_band_index = lower_indices(local_index);
  end
  if ~isempty(upper_indices)
    [gap.upper_edge, local_index] = min(expanded_lower(upper_indices));
    gap.upper_band_index = upper_indices(local_index);
  end
  if gap.in_expanded_band
    gap.margin = 0;
  else
    distances = [abs(reference_omega2 - gap.lower_edge), ...
      abs(gap.upper_edge - reference_omega2)];
    distances = distances(isfinite(distances));
    if isempty(distances)
      gap.margin = NaN;
    else
      gap.margin = min(distances);
    end
  end
  gap.maximum_edge_uncertainty = max([band.lower_uncertainty, ...
    band.upper_uncertainty]);
  gap.maximum_adjacent_edge_uncertainty = NaN;
  gap.width = NaN;
  gap.adjacent_edges_available = isfinite(gap.lower_band_index) && ...
    isfinite(gap.upper_band_index);
  if gap.adjacent_edges_available
    adjacent_uncertainties = [ ...
      band.upper_uncertainty(gap.lower_band_index), ...
      band.lower_uncertainty(gap.upper_band_index)];
    gap.maximum_adjacent_edge_uncertainty = max(adjacent_uncertainties);
    gap.width = gap.upper_edge - gap.lower_edge;
  end
  gap.edge_uncertainty_pass = gap.adjacent_edges_available && ...
    gap.maximum_adjacent_edge_uncertainty <= ...
    cfg.maximum_adjacent_edge_uncertainty;
  gap.width_pass = gap.adjacent_edges_available && gap.width > ...
    cfg.minimum_gap_uncertainty_factor * ...
    gap.maximum_adjacent_edge_uncertainty;
  gap.margin_pass = gap.adjacent_edges_available && isfinite(gap.margin) && ...
    gap.margin >= cfg.minimum_margin_uncertainty_factor * ...
    gap.maximum_adjacent_edge_uncertainty;
  gap.baseline_gate_pass = band.edge_gate_available && ...
    ~gap.in_expanded_band && gap.edge_uncertainty_pass && ...
    gap.width_pass && gap.margin_pass;
end

%% ==================== Finite-strip controls ====================
% These helpers solve finite strips and compute localization diagnostics.

function strip = LOCAL_strip_solve(cfg, beta, reference_omega2, ...
    tail_cells, has_defect, runtime)
  ppc = cfg.points_per_cell;
  h = 1 / ppc;
  num_cells = 2 * tail_cells + 1;
  x_left = -num_cells / 2;
  nx = num_cells * ppc - 1;
  ny = ppc;
  x = x_left + (1:nx).' * h;
  y = -0.5 + (0:ny - 1).' * h;
  [X, Y] = ndgrid(x, y);
  rho = LOCAL_smooth_profile(X, Y, cfg, has_defect);

  Dx = LOCAL_dirichlet_second_difference(nx, h);
  Dy = LOCAL_qp_second_difference(ny, h, beta * cfg.period_y);
  K = kron(speye(ny), Dx) + kron(Dy, speye(nx));
  invsqrt_rho = 1 ./ sqrt(rho(:));
  mass_scale = spdiags(invsqrt_rho, 0, nx * ny, nx * ny);
  A = mass_scale * K * mass_scale;
  opts = LOCAL_eigs_options(size(A, 1), cfg);
  [W, D, flag] = eigs(A, cfg.strip_nev, reference_omega2 + 1e-7, opts);
  lambda = real(diag(D));
  [lambda, order] = sort(lambda, 'ascend');
  W = W(:, order);

  center_mask = abs(X(:)) < 0.5;
  end_mask = abs(X(:)) > (num_cells / 2 - 1);
  modes = repmat(LOCAL_empty_mode(), length(lambda), 1);
  for j = 1:length(lambda)
    u = invsqrt_rho .* W(:, j);
    mass_norm = sqrt(max(real(u' * (rho(:) .* u)), 0));
    if mass_norm > 0
      u = u / mass_norm;
    end
    metric = LOCAL_localization_metrics(u, rho(:), center_mask, end_mask);
    modes(j).mode_index = j;
    modes(j).omega2 = lambda(j);
    modes(j).normalized_residual = ...
      LOCAL_evp_residual(K, rho(:), u, lambda(j));
    modes(j).center_fraction = metric.center_fraction;
    modes(j).end_fraction = metric.end_fraction;
    modes(j).center_end_ratio = metric.center_end_ratio;
  end

  [~, selected_idx] = min(abs(lambda - reference_omega2));
  selected_u = invsqrt_rho .* W(:, selected_idx);
  selected_mass_norm = sqrt(max(real(selected_u' * ...
    (rho(:) .* selected_u)), 0));
  if selected_mass_norm > 0
    selected_u = selected_u / selected_mass_norm;
  end
  strip.tail_cells_each_side = tail_cells;
  strip.num_cells = num_cells;
  strip.num_unknowns = nx * ny;
  strip.has_defect = has_defect;
  strip.eigs_flag = flag;
  strip.modes = modes;
  strip.selected_index = selected_idx;
  strip.selected = modes(selected_idx);
  strip.selected_mass_vector = sqrt(rho(:)) .* selected_u;
  strip.x = x;
  strip.ny = ny;
  strip.maximum_normalized_residual = max([modes.normalized_residual]);
  LOCAL_check_deadline(runtime, sprintf( ...
    'Track A tail %d completed', tail_cells));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function comparison = LOCAL_tail_comparison(strips, reference_omega2, ...
    relative_tolerance, overlap_tolerance, gate_available)
  if length(strips) ~= 2
    error('i4_fd_track:TailCount', ...
      'The frozen experiment requires exactly two tail lengths.');
  end
  coarse = strips(1).selected;
  fine = strips(2).selected;
  comparison.tail_coarse = strips(1).tail_cells_each_side;
  comparison.tail_fine = strips(2).tail_cells_each_side;
  comparison.omega2_shift = fine.omega2 - coarse.omega2;
  comparison.absolute_shift = abs(comparison.omega2_shift);
  comparison.relative_shift = comparison.absolute_shift / ...
    max(abs(reference_omega2), eps);
  comparison.relative_shift_tolerance = relative_tolerance;
  comparison.relative_shift_gate_available = gate_available;
  comparison.relative_shift_pass = gate_available && ...
    comparison.relative_shift <= relative_tolerance;
  comparison.center_fraction_change = ...
    fine.center_fraction - coarse.center_fraction;
  comparison.end_fraction_change = fine.end_fraction - coarse.end_fraction;
  coarse_q = reshape(strips(1).selected_mass_vector, [], strips(1).ny);
  fine_q = reshape(strips(2).selected_mass_vector, [], strips(2).ny);
  common = abs(strips(2).x) <= max(abs(strips(1).x)) + 10 * eps;
  fine_q = fine_q(common, :);
  comparison.mass_vector_overlap = abs(coarse_q(:)' * fine_q(:)) / ...
    max(norm(coarse_q(:)) * norm(fine_q(:)), eps);
  comparison.mass_vector_overlap_tolerance = overlap_tolerance;
  comparison.mass_vector_overlap_pass = ...
    comparison.mass_vector_overlap >= overlap_tolerance;
  comparison.diagnostic_pass = ...
    fine.end_fraction <= max(coarse.end_fraction, 1e-12) * 1.25 && ...
    comparison.mass_vector_overlap_pass;
  comparison.pass = comparison.relative_shift_pass && ...
    comparison.diagnostic_pass;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function metric = LOCAL_manufactured_end_control(cfg)
  tail = cfg.negative_tail_cells;
  ppc = cfg.points_per_cell;
  num_cells = 2 * tail + 1;
  nx = num_cells * ppc - 1;
  ny = ppc;
  h = 1 / ppc;
  x = -num_cells / 2 + (1:nx).' * h;
  y = -0.5 + (0:ny - 1).' * h;
  [X, ~] = ndgrid(x, y);
  center_mask = abs(X(:)) < 0.5;
  end_mask = abs(X(:)) > (num_cells / 2 - 0.5);
  u = complex(zeros(nx * ny, 1));
  u(end_mask) = 1;
  metric = LOCAL_localization_metrics(u, ones(size(u)), ...
    center_mask, end_mask);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function metric = LOCAL_localization_metrics(u, rho, center_mask, end_mask)
  density = rho(:) .* abs(u(:)).^2;
  total = sum(density);
  if total <= 0
    metric.center_fraction = NaN;
    metric.end_fraction = NaN;
    metric.center_end_ratio = NaN;
    return;
  end
  metric.center_fraction = sum(density(center_mask)) / total;
  metric.end_fraction = sum(density(end_mask)) / total;
  metric.center_end_ratio = metric.center_fraction / ...
    max(metric.end_fraction, eps);
end

%% ==================== Discretization helpers ====================
% These helpers construct profiles, difference matrices, and residuals.

function rho = LOCAL_smooth_profile(X, Y, cfg, has_defect)
  x_local = mod(X + 0.5, 1) - 0.5;
  y_local = mod(Y + 0.5, 1) - 0.5;
  rho = 1 + cfg.gaussian_amplitude * exp( ...
    -(x_local.^2 + y_local.^2) / cfg.gaussian_width^2);
  if has_defect
    rho(abs(X) < 0.5) = 1;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function D = LOCAL_qp_second_difference(n, h, phase)
  e = ones(n, 1);
  D = spdiags([-e, 2 * e, -e], -1:1, n, n) / h^2;
  D(1, n) = -exp(-1i * phase) / h^2;
  D(n, 1) = -exp(1i * phase) / h^2;
  D = sparse(D);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function D = LOCAL_dirichlet_second_difference(n, h)
  e = ones(n, 1);
  D = spdiags([-e, 2 * e, -e], -1:1, n, n) / h^2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function opts = LOCAL_eigs_options(n, cfg)
  opts.issym = true;
  opts.isreal = false;
  opts.tol = cfg.eigs_tolerance;
  opts.maxit = cfg.eigs_max_iterations;
  opts.disp = 0;
  opts.v0 = ones(n, 1) / sqrt(n);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_evp_residual(K, rho, u, lambda)
  Ku = K * u;
  Mu = rho(:) .* u;
  residual = Ku - lambda * Mu;
  value = norm(residual) / max(norm(Ku) + abs(lambda) * norm(Mu), eps);
end

%% ==================== Runtime and schema helpers ====================
% These helpers enforce the runtime cap and initialize stable output schemas.

function LOCAL_check_deadline(runtime, label)
  elapsed = toc(runtime.start_token);
  if elapsed >= runtime.max_seconds
    error('i4_fd_track:RuntimeCap', ...
      'Runtime cap reached after %.1f seconds before %s.', elapsed, label);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function one = LOCAL_empty_case()
  one = struct('case_id', [], 'case_name', '', 'beta', [], ...
    'control_role', '', 'reference_omega2', [], 'band', [], 'strips', [], ...
    'tail_comparison', [], 'positive_control', []);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function strip = LOCAL_empty_strip()
  strip = struct('tail_cells_each_side', [], 'num_cells', [], ...
    'num_unknowns', [], 'has_defect', [], 'eigs_flag', [], 'modes', [], ...
    'selected_index', [], 'selected', [], ...
    'selected_mass_vector', [], 'x', [], 'ny', [], ...
    'maximum_normalized_residual', []);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mode = LOCAL_empty_mode()
  mode = struct('mode_index', [], 'omega2', [], ...
    'normalized_residual', [], 'center_fraction', [], ...
    'end_fraction', [], 'center_end_ratio', []);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_empty_negative()
  row = struct('track', '', 'name', '', 'value', [], 'threshold', [], ...
    'pass', false, 'detail', '');
end
