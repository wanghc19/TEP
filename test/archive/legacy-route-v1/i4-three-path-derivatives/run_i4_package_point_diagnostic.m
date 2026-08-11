function results = run_i4_package_point_diagnostic()
%RUN_I4_PACKAGE_POINT_DIAGNOSTIC Diagnose package-MFS point derivatives.
%
% Purpose:
%   Run a cheap MATLAB-only, no-wall diagnostic for the package-MFS point
%   value, gradient, and Hessian at holdout_B and its transverse mirror.
%
% Output:
%   results - Staged diagnostic result, also written to CSV, MAT, Markdown,
%             and a text log under output/package-point-diagnostic.
%
% Main algorithm:
%   1. Reproduce the base proxy result through two package evaluation APIs.
%   2. Check the y-periodic wrapper against a manually swapped x-periodic
%      call and enforce the even/odd transverse parity of all six fields.
%   3. Compare returned derivatives with the frozen h7:h10, R9-authority
%      five-point differences of package values and gradients.
%   4. Assemble the exact package A,b once and compare lsqminnorm, QR, and
%      three fixed relative-tolerance economy-SVD solver outputs.
%   5. Record the complete base/single-axis/joint proxy ladder against the
%      analytic Ewald tuple, then gate four second single-axis refinements.
%
% Based on:
%   kernel.precomp_proxy, kernel.qpgreen_mfs_pairmat, and the analytic
%   Linton Eq. (2.65) implementation in this experiment directory.
%
% Main changes:
%   This entry is point-only, owns a separate output directory, never builds
%   wall matrices, and stops at the first failed mandatory stage.
%
% Numerical goal:
%   Isolate wrapper, pairmat derivative, solver, and proxy-truncation effects
%   without changing or tuning the package implementation.

  config = i4_three_path_derivatives_config();
  addpath(config.repo_root);
  output_dir = fullfile(config.output_root, 'package-point-diagnostic');
  if ~exist(output_dir, 'dir')
    mkdir(output_dir);
  end
  log_fid = fopen(fullfile(output_dir, 'run.log'), 'w');
  if log_fid < 0
    error('run_i4_package_point_diagnostic:LogOpenFailed', ...
      'Could not open the diagnostic log.');
  end
  log_cleanup = onCleanup(@() fclose(log_fid));
  started = datestr(now, 31);
  LOCAL_log(log_fid, 'package point diagnostic started=%s\n', started);
  ledgers = LOCAL_empty_ledgers();
  provenance = LOCAL_provenance(config);
  ledgers = LOCAL_append_provenance(ledgers, provenance);
  total_token = tic;

  if ~provenance.pass
    status = 'MATLAB_LSQMINNORM_PROVENANCE_BLOCKER';
    ledgers.decision.rows(end + 1, :) = {'preflight', 'BLOCKER', ...
      status, 0, provenance.note};
    ledgers = LOCAL_stop_later(ledgers, 1, status);
  else
    pars_y = struct('k', config.k, 'beta', config.beta, 'd', config.d, ...
      'periodic_axis', 'y');
    token = tic;
    proxy_base = kernel.precomp_proxy(pars_y, config.proxy.base);
    ledgers.timings.rows(end + 1, :) = {'base_precomp', toc(token), ...
      'one fixed base proxy reused through stages 0--3'};
    [stage0_pass, ledgers] = LOCAL_stage0_base( ...
      config, proxy_base, pars_y, ledgers);
    if ~stage0_pass
      status = 'DIAGNOSTIC_PREREQUISITE_MISMATCH';
      ledgers = LOCAL_stop_later(ledgers, 1, status);
    else
      [stage1_pass, ledgers] = LOCAL_stage1_wrapper_parity( ...
        config, proxy_base, pars_y, ledgers);
      if ~stage1_pass
        status = 'NEGATIVE_DX_WRAPPER_UNCERTIFIED';
        ledgers = LOCAL_stop_later(ledgers, 2, status);
      else
        [stage2_pass, ledgers] = LOCAL_stage2_package_fd( ...
          config, proxy_base, pars_y, ledgers);
        if ~stage2_pass
          status = 'PAIRMAT_FORMULA_UNCERTIFIED';
          ledgers = LOCAL_stop_later(ledgers, 3, status);
        else
          [stage3_pass, ledgers] = LOCAL_stage3_solvers( ...
            config, proxy_base, pars_y, ledgers);
          if ~stage3_pass
            status = 'SOLVER_SENSITIVITY_UNCERTIFIED';
            ledgers = LOCAL_stop_later(ledgers, 4, status);
          else
            [stage4_pass, ledgers, status] = LOCAL_stage4_proxy_ladder( ...
              config, pars_y, ledgers, log_fid);
            if stage4_pass
              status = 'PACKAGE_POINT_DIAGNOSTIC_CERTIFIED';
            end
          end
        end
      end
    end
  end

  total_seconds = toc(total_token);
  ledgers.timings.rows(end + 1, :) = {'total', total_seconds, ...
    'measured diagnostic wall-clock time'};
  results = struct('status', status, 'pass', ...
    strcmp(status, 'PACKAGE_POINT_DIAGNOSTIC_CERTIFIED'), ...
    'started', started, 'finished', datestr(now, 31), ...
    'total_seconds', total_seconds, 'config', config, ...
    'provenance', provenance, 'ledgers', ledgers);
  LOCAL_write_artifacts(output_dir, results);
  LOCAL_log(log_fid, 'status=%s seconds=%.6f\n', status, total_seconds);
  clear log_cleanup;
end

%% ==================== Staged diagnostic ====================
% These helpers implement strict first-failure stopping without wall data.

function [pass, ledgers] = LOCAL_stage0_base(config, proxy, pars_y, ledgers)
  points = LOCAL_mirror_points(config);
  source = [0; 0];
  target = [[points.X]; [points.Y]];
  pair = LOCAL_pair_tuple(source, target, pars_y, proxy);
  single = kernel.qpgreen_mfs(source, target, pars_y, proxy);
  other = struct('G', single.pot(:), 'Gx', single.grad(1, :).', ...
    'Gy', single.grad(2, :).', 'Gxx', single.hess(1, :).', ...
    'Gxy', single.hess(2, :).', 'Gyy', single.hess(3, :).');
  pass = true;
  for ip = 1:length(points)
    for component_cell = LOCAL_components()
      component = component_cell{1};
      error_value = abs(pair.(component)(ip) - other.(component)(ip));
      row_pass = error_value <= config.gate.point;
      ledgers.diagnostic.rows(end + 1, :) = {'stage0_base_reproduction', ...
        points(ip).label, component, 'pairmat', 'qpgreen_mfs', ...
        real(pair.(component)(ip)), imag(pair.(component)(ip)), ...
        real(other.(component)(ip)), imag(other.(component)(ip)), ...
        error_value, config.gate.point, row_pass, 'within_gate', ...
        row_pass, 0};
    end
  end
  for ip = 1:length(points)
    reference = LOCAL_ewald_tuple(config, points(ip).X, points(ip).Y, ...
      config.ewald.authority);
    for component_cell = LOCAL_components()
      component = component_cell{1};
      error_value = abs(pair.(component)(ip) - reference.(component)) / ...
        max(1, abs(reference.(component)));
      row_pass = error_value <= config.gate.point;
      mandatory = ip == 1;
      if any(strcmp(component, {'G', 'Gx', 'Gy'}))
        expectation = 'within_gate';
        matched = row_pass;
      else
        expectation = 'outside_gate_known_failure';
        matched = ~row_pass;
      end
      pass = pass && (~mandatory || matched);
      ledgers.diagnostic.rows(end + 1, :) = {'stage0_known_failure', ...
        points(ip).label, component, 'package_base', 'Ewald_joint', ...
        real(pair.(component)(ip)), imag(pair.(component)(ip)), ...
        real(reference.(component)), imag(reference.(component)), ...
        error_value, config.gate.point, row_pass, expectation, matched, ...
        mandatory};
    end
  end
  ledgers.decision.rows(end + 1, :) = {'stage0_base', 'MANDATORY', ...
    LOCAL_status(pass, 'DIAGNOSTIC_PREREQUISITE_REPRODUCED', ...
    'DIAGNOSTIC_PREREQUISITE_MISMATCH'), pass, ...
    'B- value/gradient pass and all three Hessians reproduce known failure.'};
end

function [pass, ledgers] = LOCAL_stage1_wrapper_parity( ...
    config, proxy, pars_y, ledgers)
  points = LOCAL_mirror_points(config);
  source = [0; 0];
  target = [[points.X]; [points.Y]];
  physical = LOCAL_pair_tuple(source, target, pars_y, proxy);
  pars_x = rmfield(pars_y, 'periodic_axis');
  pars_x.periodic_axis = 'x';
  computational = LOCAL_pair_tuple(source([2 1], :), target([2 1], :), ...
    pars_x, proxy);
  remapped = struct('G', computational.G, 'Gx', computational.Gy, ...
    'Gy', computational.Gx, 'Gxx', computational.Gyy, ...
    'Gxy', computational.Gxy, 'Gyy', computational.Gxx);
  wrapper_pass = true;
  for ip = 1:length(points)
    for component_cell = LOCAL_components()
      component = component_cell{1};
      error_value = abs(physical.(component)(ip) - remapped.(component)(ip));
      row_pass = error_value <= config.gate.point;
      wrapper_pass = wrapper_pass && row_pass;
      ledgers.identity.rows(end + 1, :) = {'wrapper_manual_swap', ...
        points(ip).label, component, real(physical.(component)(ip)), ...
        imag(physical.(component)(ip)), real(remapped.(component)(ip)), ...
        imag(remapped.(component)(ip)), error_value, ...
        config.gate.point, row_pass, 1};
    end
  end
  parity_pass = true;
  parity_sign = struct('G', 1, 'Gx', -1, 'Gy', 1, ...
    'Gxx', 1, 'Gxy', -1, 'Gyy', 1);
  for component_cell = LOCAL_components()
    component = component_cell{1};
    expected = parity_sign.(component) * physical.(component)(1);
    observed = physical.(component)(2);
    error_value = abs(observed - expected);
    row_pass = error_value <= config.gate.point;
    parity_pass = parity_pass && row_pass;
    ledgers.identity.rows(end + 1, :) = {'transverse_parity', ...
      'holdout_B_mirror_pair', component, real(observed), imag(observed), ...
      real(expected), imag(expected), error_value, config.gate.point, ...
      row_pass, 0};
  end
  ledgers.decision.rows(end + 1, :) = {'stage1_wrapper_parity', 'MANDATORY', ...
    LOCAL_status(wrapper_pass, 'NEGATIVE_DX_WRAPPER_CERTIFIED', ...
    'NEGATIVE_DX_WRAPPER_UNCERTIFIED'), wrapper_pass, ...
    'Physical y wrapper against the manually swapped x-periodic call.'};
  ledgers.decision.rows(end + 1, :) = {'stage1_transverse_parity', ...
    'IMPORTANT', LOCAL_status(parity_pass, ...
    'TRANSVERSE_PARITY_CERTIFIED', 'UP_DOWN_APPROXIMATION_ASYMMETRY'), ...
    parity_pass, ...
    'Diagnostic only: parity failure does not implicate the wrapper or stop.'};
  pass = wrapper_pass;
end

function [pass, ledgers] = LOCAL_stage2_package_fd( ...
    config, proxy, pars_y, ledgers)
  points = LOCAL_mirror_points(config);
  source = [0; 0];
  target = [[points.X]; [points.Y]];
  analytic = LOCAL_pair_tuple(source, target, pars_y, proxy);
  pass = true;
  estimate_names = {'Gx', 'Gy', 'Gxx', 'Gxy_dyGx', 'Gxy_dxGy', 'Gyy'};
  reference_names = {'Gx', 'Gy', 'Gxx', 'Gxy', 'Gxy', 'Gyy'};
  for ip = 1:length(points)
    raw = cell(1, length(config.fd_h));
    for ih = 1:length(config.fd_h)
      raw{ih} = LOCAL_package_fd_raw(source, points(ip), pars_y, proxy, ...
        config.fd_h(ih));
    end
    richardson = cell(1, 3);
    for ir = 1:3
      richardson{ir} = LOCAL_richardson(raw{ir}, raw{ir + 1});
    end
    for ie = 1:length(estimate_names)
      estimate_name = estimate_names{ie};
      reference = analytic.(reference_names{ie})(ip);
      for ih = 1:length(raw)
        value = raw{ih}.(estimate_name);
        error_value = abs(value - reference) / max(1, abs(reference));
        row_pass = error_value <= config.gate.point;
        ledgers.fd.rows(end + 1, :) = {points(ip).label, estimate_name, ...
          'raw', config.fd_exponents(ih), config.fd_exponents(ih), ...
          'trend', real(value), imag(value), real(reference), ...
          imag(reference), error_value, config.gate.point, row_pass, 0};
      end
      for ir = 1:3
        value = richardson{ir}.(estimate_name);
        error_value = abs(value - reference) / max(1, abs(reference));
        mandatory = ir == 3;
        role = LOCAL_richardson_role(ir);
        row_pass = error_value <= config.gate.point;
        pass = pass && (~mandatory || row_pass);
        ledgers.fd.rows(end + 1, :) = {points(ip).label, estimate_name, ...
          'richardson', config.fd_exponents(ir), ...
          config.fd_exponents(ir + 1), role, real(value), imag(value), ...
          real(reference), imag(reference), error_value, config.gate.point, ...
          row_pass, mandatory};
      end
      self_error = abs(richardson{3}.(estimate_name) - ...
        richardson{2}.(estimate_name)) / max(1, ...
        abs(richardson{3}.(estimate_name)));
      self_pass = self_error <= config.gate.point;
      pass = pass && self_pass;
      ledgers.fd.rows(end + 1, :) = {points(ip).label, estimate_name, ...
        'richardson_self', 8, 10, 'R8_vs_R9', ...
        real(richardson{3}.(estimate_name)), ...
        imag(richardson{3}.(estimate_name)), ...
        real(richardson{2}.(estimate_name)), ...
        imag(richardson{2}.(estimate_name)), self_error, ...
        config.gate.point, self_pass, 1};
    end
    helmholtz = analytic.Gxx(ip) + analytic.Gyy(ip) + ...
      config.k ^ 2 * analytic.G(ip);
    helmholtz_error = abs(helmholtz) / max(1, abs(analytic.Gxx(ip)) + ...
      abs(analytic.Gyy(ip)) + config.k ^ 2 * abs(analytic.G(ip)));
    helmholtz_pass = helmholtz_error <= config.gate.point;
    pass = pass && helmholtz_pass;
    ledgers.identity.rows(end + 1, :) = {'package_Helmholtz', ...
      points(ip).label, 'Gxx+Gyy+k2G', real(helmholtz), ...
      imag(helmholtz), 0, 0, helmholtz_error, config.gate.point, ...
      helmholtz_pass, 1};
  end
  ledgers.decision.rows(end + 1, :) = {'stage2_package_fd', 'MANDATORY', ...
    LOCAL_status(pass, 'PAIRMAT_FORMULA_CERTIFIED', ...
    'PAIRMAT_FORMULA_UNCERTIFIED'), pass, ...
    'Package value/gradient FD, R9 authority, R8--R9 self, Helmholtz.'};
  if ~pass
    ledgers = LOCAL_append_h2d_decomposition( ...
      config, proxy, pars_y, points, analytic, ledgers);
  end
end

function ledgers = LOCAL_append_h2d_decomposition( ...
    config, proxy, pars_y, points, package_tuple, ledgers)
  if ~strcmp(pars_y.periodic_axis, 'y')
    error('run_i4_package_point_diagnostic:DecompositionAxis', ...
      'The decomposition assumes the physical y-periodic wrapper.');
  end
  for ip = 1:length(points)
    if abs(points(ip).X) > proxy.H
      error('run_i4_package_point_diagnostic:UnexpectedPlaneWaveBranch', ...
        'The frozen diagnostic point is not in the proxy-box branch.');
    end
    target_comp = [points(ip).Y; points(ip).X];
    [p0, g0, h0] = kernel.h2d_directch(config.k, [0; 0], 1, target_comp);
    [pP, gP, hP] = kernel.h2d_directch( ...
      config.k, proxy.Z, proxy.q, target_comp);
    primary = LOCAL_remap_h2d(p0, g0, h0);
    proxy_part = LOCAL_remap_h2d(pP, gP, hP);
    for component_cell = LOCAL_components()
      component = component_cell{1};
      aggregate = primary.(component) + proxy_part.(component);
      package_value = package_tuple.(component)(ip);
      error_value = abs(aggregate - package_value);
      ledgers.decomposition.rows(end + 1, :) = {points(ip).label, ...
        component, real(primary.(component)), imag(primary.(component)), ...
        real(proxy_part.(component)), imag(proxy_part.(component)), ...
        real(aggregate), imag(aggregate), real(package_value), ...
        imag(package_value), error_value, ...
        'idx_in=true; no C_down plane-wave branch'};
    end
  end
end

function tuple = LOCAL_remap_h2d(potential, gradient, hessian)
  tuple = struct('G', potential(1), 'Gx', gradient(2, 1), ...
    'Gy', gradient(1, 1), 'Gxx', hessian(3, 1), ...
    'Gxy', hessian(2, 1), 'Gyy', hessian(1, 1));
end

function [pass, ledgers] = LOCAL_stage3_solvers( ...
    config, package_proxy, pars_y, ledgers)
  [A, b, assembly] = LOCAL_assemble_proxy_system(pars_y, config.proxy.base);
  points = LOCAL_mirror_points(config);
  source = [0; 0];
  target = [[points.X]; [points.Y]];
  package_value = LOCAL_pair_tuple(source, target, pars_y, package_proxy);
  solver_names = {'lsqminnorm', 'backslash', 'svd_1e-14', ...
    'svd_1e-13', 'svd_1e-12'};
  coefficients = cell(1, length(solver_names));
  coefficients{1} = lsqminnorm(A, b);
  coefficients{2} = A \ b;
  tolerances = [1e-14, 1e-13, 1e-12];
  [U, S, V] = svd(A, 'econ');
  singular_values = diag(S);
  for it = 1:length(tolerances)
    keep = singular_values > tolerances(it) * singular_values(1);
    coefficients{it + 2} = V(:, keep) * ...
      ((U(:, keep)' * b) ./ singular_values(keep));
  end
  values = cell(1, length(solver_names));
  for is = 1:length(solver_names)
    proxy = LOCAL_proxy_from_coefficients(coefficients{is}, assembly);
    values{is} = LOCAL_pair_tuple(source, target, pars_y, proxy);
  end
  pass = true;
  for is = 1:length(solver_names)
    residual = norm(A * coefficients{is} - b) / max(1, norm(b));
    for ip = 1:length(points)
      for component_cell = LOCAL_components()
        component = component_cell{1};
        reference = package_value.(component)(ip);
        value = values{is}.(component)(ip);
        error_value = abs(value - reference) / max(1, abs(reference));
        row_pass = error_value <= config.gate.point;
        pass = pass && row_pass;
        ledgers.solver.rows(end + 1, :) = {solver_names{is}, ...
          LOCAL_solver_tau(solver_names{is}), points(ip).label, component, ...
          real(value), imag(value), real(reference), imag(reference), ...
          error_value, residual, config.gate.point, row_pass, 1};
      end
    end
  end
  spread = 0;
  for ia = 1:length(values)
    for ib = ia + 1:length(values)
      for component_cell = LOCAL_components()
        component = component_cell{1};
        spread = max(spread, max(abs(values{ia}.(component) - ...
          values{ib}.(component))));
      end
    end
  end
  spread_pass = spread <= config.gate.point;
  pass = pass && spread_pass;
  ledgers.identity.rows(end + 1, :) = {'solver_output_spread', ...
    'holdout_B_mirror_pair', 'six_tuple', real(spread), 0, 0, 0, ...
    spread, config.gate.point, spread_pass, 1};
  ledgers.decision.rows(end + 1, :) = {'stage3_solver_sensitivity', ...
    'MANDATORY', LOCAL_status(pass, 'SOLVER_SENSITIVITY_CERTIFIED', ...
    'SOLVER_SENSITIVITY_UNCERTIFIED'), pass, ...
    'One exact A,b; package closure, lsqminnorm, QR, and fixed SVD cuts.'};
end

function [pass, ledgers, status] = LOCAL_stage4_proxy_ladder( ...
    config, pars_y, ledgers, log_fid)
  points = LOCAL_all_diagnostic_points(config);
  first = LOCAL_first_proxy_levels(config);
  first_labels = fieldnames(first);
  values = struct();
  for il = 1:length(first_labels)
    label = first_labels{il};
    LOCAL_log(log_fid, 'proxy ladder level=%s\n', label);
    token = tic;
    proxy = kernel.precomp_proxy(pars_y, first.(label));
    ledgers.timings.rows(end + 1, :) = {['proxy_', label], toc(token), ...
      'package precomp_proxy'};
    values.(label) = LOCAL_proxy_level_rows( ...
      config, pars_y, proxy, first.(label), label, points, ledgers.proxy);
    ledgers.proxy = values.(label).ledger;
  end
  joint_pass = LOCAL_proxy_rows_pass(ledgers.proxy.rows, 'joint');
  ledgers.decision.rows(end + 1, :) = {'stage4_joint_proxy', 'MANDATORY', ...
    LOCAL_status(joint_pass, 'JOINT_PROXY_CERTIFIED', ...
    'PROXY_TRUNCATION_UNCERTIFIED'), joint_pass, ...
    'Base and all first-axis levels recorded; only preregistered joint gates.'};
  if ~joint_pass
    pass = false;
    status = 'PROXY_TRUNCATION_UNCERTIFIED';
    ledgers.decision.rows(end + 1, :) = {'stage4_second_proxy_axes', ...
      'MANDATORY', 'NOT_RUN_PREREQUISITE', 0, ...
      'Joint proxy did not pass all six-component Ewald gates.'};
    return;
  end
  second = LOCAL_second_proxy_levels(config);
  second_labels = fieldnames(second);
  joint_tuple = values.joint.tuple;
  self_pass = true;
  for il = 1:length(second_labels)
    label = second_labels{il};
    token = tic;
    proxy = kernel.precomp_proxy(pars_y, second.(label));
    ledgers.timings.rows(end + 1, :) = {['proxy_', label], toc(token), ...
      'second single-axis refinement'};
    level_data = LOCAL_proxy_level_rows(config, pars_y, proxy, ...
      second.(label), label, points, ledgers.proxy);
    ledgers.proxy = level_data.ledger;
    change = LOCAL_tuple_max_change(level_data.tuple, joint_tuple);
    row_pass = change <= config.gate.self;
    self_pass = self_pass && row_pass;
    ledgers.identity.rows(end + 1, :) = {'proxy_second_axis_self', ...
      label, 'six_tuple_all_points', real(change), 0, 0, 0, change, ...
      config.gate.self, row_pass, 1};
    if ~row_pass
      pass = false;
      status = 'PROXY_SECOND_AXIS_UNCERTIFIED';
      ledgers.decision.rows(end + 1, :) = { ...
        'stage4_second_proxy_axes', 'MANDATORY', status, 0, ...
        ['First failed second-axis level: ', label, '.']};
      for later = il + 1:length(second_labels)
        ledgers.decision.rows(end + 1, :) = {second_labels{later}, ...
          'MANDATORY', 'NOT_RUN_PREREQUISITE', 0, ...
          ['Stopped after ', label, ' failure.']};
      end
      return;
    end
  end
  pass = self_pass;
  status = LOCAL_status(pass, 'PACKAGE_POINT_DIAGNOSTIC_CERTIFIED', ...
    'PROXY_SECOND_AXIS_UNCERTIFIED');
  ledgers.decision.rows(end + 1, :) = {'stage4_second_proxy_axes', ...
    'MANDATORY', status, pass, ...
    'Nside2, Ntop2, Nedge2, and Mpw2 each compared with joint.'};
end

%% ==================== Point and finite-difference helpers ====================
% These helpers evaluate package tuples and fixed five-point differences.

function components = LOCAL_components()
  components = {'G', 'Gx', 'Gy', 'Gxx', 'Gxy', 'Gyy'};
end

function points = LOCAL_mirror_points(config)
  negative = config.points(strcmp({config.points.label}, 'holdout_B'));
  points(1) = negative;
  points(1).label = 'holdout_B_negative';
  points(2) = negative;
  points(2).label = 'holdout_B_positive';
  points(2).X = abs(negative.X);
end

function points = LOCAL_all_diagnostic_points(config)
  points = config.points;
  mirror = config.points(strcmp({config.points.label}, 'holdout_B'));
  mirror.label = 'holdout_B_positive_mirror';
  mirror.X = abs(mirror.X);
  points(end + 1) = mirror;
end

function tuple = LOCAL_pair_tuple(source, target, pars, proxy)
  [G, Gx, Gy, Gxx, Gxy, Gyy] = kernel.qpgreen_mfs_pairmat( ...
    source, target, pars, proxy);
  tuple = struct('G', G(:), 'Gx', Gx(:), 'Gy', Gy(:), ...
    'Gxx', Gxx(:), 'Gxy', Gxy(:), 'Gyy', Gyy(:));
end

function raw = LOCAL_package_fd_raw(source, point, pars, proxy, h)
  if 2 * h >= abs(point.X)
    error('run_i4_package_point_diagnostic:FDStencilClearance', ...
      'The package five-point stencil crosses dx=0.');
  end
  offsets = -2:2;
  w1 = [1, -8, 0, 8, -1];
  target_x = [point.X + offsets * h; point.Y * ones(1, 5)];
  target_y = [point.X * ones(1, 5); point.Y + offsets * h];
  x_data = LOCAL_pair_tuple(source, target_x, pars, proxy);
  y_data = LOCAL_pair_tuple(source, target_y, pars, proxy);
  raw.Gx = (w1 * x_data.G) / (12 * h);
  raw.Gy = (w1 * y_data.G) / (12 * h);
  raw.Gxx = (w1 * x_data.Gx) / (12 * h);
  raw.Gxy_dyGx = (w1 * y_data.Gx) / (12 * h);
  raw.Gxy_dxGy = (w1 * x_data.Gy) / (12 * h);
  raw.Gyy = (w1 * y_data.Gy) / (12 * h);
end

function output = LOCAL_richardson(coarse, fine)
  names = fieldnames(coarse);
  for j = 1:length(names)
    output.(names{j}) = (16 * fine.(names{j}) - coarse.(names{j})) / 15;
  end
end

function role = LOCAL_richardson_role(index)
  roles = {'trend', 'self_reference', 'authority'};
  role = roles{index};
end

%% ==================== Exact local proxy assembly ====================
% This group reproduces package A,b once so only the solver branch varies.

function [A, b, assembly] = LOCAL_assemble_proxy_system(pars1, pars2)
  d = pars1.d;
  beta = pars1.beta;
  k = pars1.k;
  H = pars2.H;
  N_side = pars2.N_side;
  N_top = pars2.N_top;
  N_proxy_edge = pars2.N_proxy_edge;
  M_pw = pars2.M_pw;
  y_side = linspace(-H, H, N_side).';
  p_L = [-d / 2 * ones(N_side, 1), y_side];
  p_R = [d / 2 * ones(N_side, 1), y_side];
  x_top = linspace(-d / 2, d / 2, N_top).';
  p_T = [x_top, H * ones(N_top, 1)];
  p_B = [x_top, -H * ones(N_top, 1)];
  x_min = -d / 2 - pars2.proxy_dist;
  x_max = d / 2 + pars2.proxy_dist;
  y_min = -H - pars2.proxy_dist;
  y_max = H + pars2.proxy_dist;
  tx = linspace(x_min, x_max, N_proxy_edge + 1).';
  tx(end) = [];
  ty = linspace(y_min, y_max, N_proxy_edge + 1).';
  ty(end) = [];
  px = [tx; repmat(x_max, N_proxy_edge, 1); flipud(tx); ...
    repmat(x_min, N_proxy_edge, 1)];
  py = [repmat(y_min, N_proxy_edge, 1); ty; ...
    repmat(y_max, N_proxy_edge, 1); flipud(ty)];
  Z_proxy = [px, py];
  N_proxy = size(Z_proxy, 1);
  m = (-M_pw:M_pw).';
  beta_m = beta + 2 * pi * m / d;
  gamma_m = sqrt(complex(k ^ 2 - beta_m .^ 2));
  flip = imag(gamma_m) < 0;
  gamma_m(flip) = -gamma_m(flip);
  N_pw = length(m);
  A = zeros(2 * N_side + 4 * N_top, N_proxy + 2 * N_pw);
  b = zeros(size(A, 1), 1);
  idx_LR_v = 1:N_side;
  idx_LR_d = (1:N_side) + N_side;
  idx_T_v = (1:N_top) + 2 * N_side;
  idx_T_d = (1:N_top) + 2 * N_side + N_top;
  idx_B_v = (1:N_top) + 2 * N_side + 2 * N_top;
  idx_B_d = (1:N_top) + 2 * N_side + 3 * N_top;
  col_proxy = 1:N_proxy;
  col_up = (1:N_pw) + N_proxy;
  col_down = (1:N_pw) + N_proxy + N_pw;
  phase = exp(1i * beta * d);
  source = [0, 0];
  [V_sL, dVdx_sL, ~] = LOCAL_free_space(k, p_L, source);
  [V_sR, dVdx_sR, ~] = LOCAL_free_space(k, p_R, source);
  b(idx_LR_v) = -(V_sR - phase * V_sL);
  b(idx_LR_d) = -(dVdx_sR - phase * dVdx_sL);
  [V_sT, ~, dVdy_sT] = LOCAL_free_space(k, p_T, source);
  [V_sB, ~, dVdy_sB] = LOCAL_free_space(k, p_B, source);
  b(idx_T_v) = -V_sT;
  b(idx_T_d) = -dVdy_sT;
  b(idx_B_v) = -V_sB;
  b(idx_B_d) = -dVdy_sB;
  [V_pL, dVdx_pL, ~] = LOCAL_free_space(k, p_L, Z_proxy);
  [V_pR, dVdx_pR, ~] = LOCAL_free_space(k, p_R, Z_proxy);
  A(idx_LR_v, col_proxy) = V_pR - phase * V_pL;
  A(idx_LR_d, col_proxy) = dVdx_pR - phase * dVdx_pL;
  [V_pT, ~, dVdy_pT] = LOCAL_free_space(k, p_T, Z_proxy);
  [V_pB, ~, dVdy_pB] = LOCAL_free_space(k, p_B, Z_proxy);
  A(idx_T_v, col_proxy) = V_pT;
  A(idx_T_d, col_proxy) = dVdy_pT;
  A(idx_B_v, col_proxy) = V_pB;
  A(idx_B_d, col_proxy) = dVdy_pB;
  PW_T = exp(1i * p_T(:, 1) * beta_m.');
  A(idx_T_v, col_up) = -PW_T;
  A(idx_T_d, col_up) = -(PW_T .* (1i * gamma_m.'));
  PW_B = exp(1i * p_B(:, 1) * beta_m.');
  A(idx_B_v, col_down) = -PW_B;
  A(idx_B_d, col_down) = -(PW_B .* (-1i * gamma_m.'));
  assembly = struct('N_proxy', N_proxy, 'N_pw', N_pw, ...
    'Z', Z_proxy.', 'H', H);
end

function [G, Gx, Gy] = LOCAL_free_space(k, target, source)
  dx = target(:, 1) - source(:, 1).';
  dy = target(:, 2) - source(:, 2).';
  distance = sqrt(dx .^ 2 + dy .^ 2);
  G = (1i / 4) * besselh(0, 1, k * distance);
  factor = -(1i * k / 4) * besselh(1, 1, k * distance) ./ distance;
  Gx = factor .* dx;
  Gy = factor .* dy;
end

function proxy = LOCAL_proxy_from_coefficients(coefficients, assembly)
  N_proxy = assembly.N_proxy;
  N_pw = assembly.N_pw;
  proxy.q = coefficients(1:N_proxy).';
  proxy.Z = assembly.Z;
  proxy.H = assembly.H;
  proxy.C_up = coefficients(N_proxy + (1:N_pw), 1);
  proxy.C_down = coefficients(N_proxy + N_pw + (1:N_pw), 1);
end

function tau = LOCAL_solver_tau(name)
  tau = NaN;
  if strcmp(name, 'svd_1e-14')
    tau = 1e-14;
  elseif strcmp(name, 'svd_1e-13')
    tau = 1e-13;
  elseif strcmp(name, 'svd_1e-12')
    tau = 1e-12;
  end
end

%% ==================== Proxy ladders ====================
% These helpers record every preregistered level without selecting a winner.

function levels = LOCAL_first_proxy_levels(config)
  levels.base = config.proxy.base;
  levels.Nside = config.proxy.Nside;
  levels.Ntop = config.proxy.Ntop;
  levels.Nedge = config.proxy.Nedge;
  levels.Mpw = config.proxy.Mpw;
  common = config.proxy.base;
  levels.joint = LOCAL_proxy_level(common, 160, 160, 80, 32);
end

function levels = LOCAL_second_proxy_levels(config)
  common = config.proxy.base;
  levels.Nside2 = LOCAL_proxy_level(common, 200, 160, 80, 32);
  levels.Ntop2 = LOCAL_proxy_level(common, 160, 200, 80, 32);
  levels.Nedge2 = LOCAL_proxy_level(common, 160, 160, 96, 32);
  levels.Mpw2 = LOCAL_proxy_level(common, 160, 160, 80, 40);
end

function level = LOCAL_proxy_level(common, Nside, Ntop, Nedge, Mpw)
  level = common;
  level.N_side = Nside;
  level.N_top = Ntop;
  level.N_proxy_edge = Nedge;
  level.M_pw = Mpw;
end

function data = LOCAL_proxy_level_rows( ...
    config, pars, proxy, level, label, points, ledger)
  source = [0; 0];
  target = [[points.X]; [points.Y]];
  tuple = LOCAL_pair_tuple(source, target, pars, proxy);
  mandatory = strcmp(label, 'joint');
  for ip = 1:length(points)
    reference = LOCAL_ewald_tuple(config, points(ip).X, points(ip).Y, ...
      config.ewald.authority);
    for component_cell = LOCAL_components()
      component = component_cell{1};
      value = tuple.(component)(ip);
      expected = reference.(component);
      error_value = abs(value - expected) / max(1, abs(expected));
      row_pass = error_value <= config.gate.point;
      ledger.rows(end + 1, :) = {label, level.N_side, level.N_top, ...
        level.N_proxy_edge, level.M_pw, points(ip).label, component, ...
        real(value), imag(value), real(expected), imag(expected), ...
        error_value, config.gate.point, row_pass, mandatory};
    end
  end
  data = struct('tuple', tuple, 'ledger', ledger);
end

function pass = LOCAL_proxy_rows_pass(rows, label)
  pass = true;
  for j = 1:size(rows, 1)
    if strcmp(rows{j, 1}, label) && rows{j, 15}
      pass = pass && rows{j, 14};
    end
  end
end

function change = LOCAL_tuple_max_change(left, right)
  change = 0;
  for component_cell = LOCAL_components()
    component = component_cell{1};
    change = max(change, max(abs(left.(component) - right.(component))));
  end
end

%% ==================== Analytic Ewald reference ====================
% These helpers independently reproduce the signed physical Linton tuple.

function physical = LOCAL_ewald_tuple(config, X_signed, Y, level)
  if X_signed == 0
    error('run_i4_package_point_diagnostic:ZeroSeparation', ...
      'Derivative references require nonzero transverse separation.');
  end
  X = abs(X_signed);
  sx = sign(X_signed);
  reciprocal = LOCAL_ewald_reciprocal(config, X, Y, level);
  real_space = LOCAL_ewald_real(config, X, Y, level);
  names = {'G', 'GX_abs', 'GY', 'GXX_abs', 'GXY_abs', 'GYY'};
  for j = 1:length(names)
    magnitude.(names{j}) = config.project_sign * ...
      (reciprocal.(names{j}) + real_space.(names{j}));
  end
  physical = struct('G', magnitude.G, 'Gx', sx * magnitude.GX_abs, ...
    'Gy', magnitude.GY, 'Gxx', magnitude.GXX_abs, ...
    'Gxy', sx * magnitude.GXY_abs, 'Gyy', magnitude.GYY);
end

function out = LOCAL_ewald_reciprocal(config, X, Y, level)
  m = (-level.M1:level.M1).';
  beta_m = config.beta + 2 * pi * m / config.d;
  q = LOCAL_linton_branch(config.k, beta_m);
  h = level.a / config.d;
  b = q * config.d / (2 * level.a);
  u_plus = b + h * X;
  u_minus = b - h * X;
  erfc_plus = LOCAL_complex_erfc(u_plus);
  erfc_minus = LOCAL_complex_erfc(u_minus);
  chi_plus = -(2 / sqrt(pi)) * exp(-(u_plus .^ 2));
  chi_minus = -(2 / sqrt(pi)) * exp(-(u_minus .^ 2));
  chi_prime_plus = -2 * u_plus .* chi_plus;
  chi_prime_minus = -2 * u_minus .* chi_minus;
  exp_plus = exp(q * X);
  exp_minus = exp(-q * X);
  F_plus = exp_plus .* erfc_plus;
  F_minus = exp_minus .* erfc_minus;
  FX_plus = exp_plus .* (q .* erfc_plus + h * chi_plus);
  FX_minus = -exp_minus .* (q .* erfc_minus + h * chi_minus);
  FXX_plus = exp_plus .* (q .^ 2 .* erfc_plus + ...
    2 * q * h .* chi_plus + h ^ 2 * chi_prime_plus);
  FXX_minus = exp_minus .* (q .^ 2 .* erfc_minus + ...
    2 * q * h .* chi_minus + h ^ 2 * chi_prime_minus);
  phase = exp(1i * beta_m * Y);
  base = phase ./ q;
  scale = -1 / (4 * config.d);
  F = F_plus + F_minus;
  FX = FX_plus + FX_minus;
  FXX = FXX_plus + FXX_minus;
  out.G = scale * sum(base .* F);
  out.GX_abs = scale * sum(base .* FX);
  out.GY = scale * sum((1i * beta_m) .* base .* F);
  out.GXX_abs = scale * sum(base .* FXX);
  out.GXY_abs = scale * sum((1i * beta_m) .* base .* FX);
  out.GYY = scale * sum(-(beta_m .^ 2) .* base .* F);
end

function out = LOCAL_ewald_real(config, X, Y, level)
  m = (-level.M2:level.M2).';
  image_Y = Y - m * config.d;
  alpha = (level.a / config.d) ^ 2;
  z = alpha * (X ^ 2 + image_Y .^ 2);
  exp_neg_z = exp(-z);
  E_minus_one = exp_neg_z .* (1 ./ z + 1 ./ (z .^ 2));
  E_zero = exp_neg_z ./ z;
  E_one = expint(z);
  H = zeros(size(z));
  H_z = zeros(size(z));
  H_zz = zeros(size(z));
  E_nm1 = E_minus_one;
  E_n = E_zero;
  E_np1 = E_one;
  for n = 0:level.N
    coefficient = (config.k * config.d / (2 * level.a)) ^ (2 * n) / ...
      factorial(n);
    H = H + coefficient * E_np1;
    H_z = H_z - coefficient * E_n;
    H_zz = H_zz + coefficient * E_nm1;
    if n < level.N
      E_nm1 = E_n;
      E_n = E_np1;
      E_np1 = (exp_neg_z - z .* E_n) / (n + 1);
    end
  end
  z_X = 2 * alpha * X;
  z_Y = 2 * alpha * image_Y;
  phase = exp(1i * config.beta * m * config.d);
  scale = -1 / (4 * pi);
  out.G = scale * sum(phase .* H);
  out.GX_abs = scale * sum(phase .* H_z * z_X);
  out.GY = scale * sum(phase .* H_z .* z_Y);
  out.GXX_abs = scale * sum(phase .* ...
    (H_zz * z_X ^ 2 + 2 * alpha * H_z));
  out.GXY_abs = scale * sum(phase .* (H_zz .* z_Y * z_X));
  out.GYY = scale * sum(phase .* ...
    (H_zz .* z_Y .^ 2 + 2 * alpha * H_z));
end

function q = LOCAL_linton_branch(k, beta_m)
  difference = beta_m .^ 2 - k ^ 2;
  q = zeros(size(beta_m));
  evanescent = difference >= 0;
  q(evanescent) = sqrt(difference(evanescent));
  q(~evanescent) = -1i * sqrt(-difference(~evanescent));
end

function value = LOCAL_complex_erfc(z)
  if ~isempty(which('Faddeeva_erfc'))
    value = Faddeeva_erfc(z);
  else
    value = erfc(z);
  end
end

%% ==================== Ledgers, provenance, and artifacts ====================
% These helpers preserve complete evidence even when a stage stops early.

function ledgers = LOCAL_empty_ledgers()
  ledgers.backend = LOCAL_ledger({'key', 'value', 'note'});
  ledgers.diagnostic = LOCAL_ledger({'stage', 'point', 'component', ...
    'left_method', 'right_method', 'left_re', 'left_im', 'right_re', ...
    'right_im', 'error', 'gate', 'pass', 'expected_relation', ...
    'matched_expectation', 'mandatory'});
  ledgers.identity = LOCAL_ledger({'identity', 'point', 'component', ...
    'observed_re', 'observed_im', 'expected_re', 'expected_im', ...
    'error', 'gate', 'pass', 'mandatory'});
  ledgers.fd = LOCAL_ledger({'point', 'estimate', 'estimate_kind', ...
    'r_coarse', 'r_fine', 'role', 'value_re', 'value_im', ...
    'reference_re', 'reference_im', 'error', 'gate', 'pass', 'mandatory'});
  ledgers.solver = LOCAL_ledger({'solver', 'tau_rel', 'point', ...
    'component', 'value_re', 'value_im', 'package_re', 'package_im', ...
    'output_error', 'system_residual', 'gate', 'pass', 'mandatory'});
  ledgers.proxy = LOCAL_ledger({'level', 'Nside', 'Ntop', 'Nedge', ...
    'Mpw', 'point', 'component', 'value_re', 'value_im', 'ewald_re', ...
    'ewald_im', 'ewald_error', 'gate', 'pass', 'mandatory'});
  ledgers.decomposition = LOCAL_ledger({'point', 'component', ...
    'primary_re', 'primary_im', 'proxy_re', 'proxy_im', 'aggregate_re', ...
    'aggregate_im', 'package_re', 'package_im', 'closure_error', 'note'});
  ledgers.decision = LOCAL_ledger( ...
    {'stage', 'classification', 'status', 'pass', 'note'});
  ledgers.timings = LOCAL_ledger({'stage', 'seconds', 'note'});
end

function ledger = LOCAL_ledger(headers)
  ledger = struct('headers', {headers}, 'rows', {cell(0, length(headers))});
end

function provenance = LOCAL_provenance(config)
  provenance.runtime = 'MATLAB';
  if exist('OCTAVE_VERSION', 'builtin') ~= 0
    provenance.runtime = 'Octave';
  end
  provenance.version = version;
  provenance.lsqminnorm_exist = exist('lsqminnorm', 'file');
  provenance.lsqminnorm = which('lsqminnorm');
  provenance.precomp_proxy = which('kernel.precomp_proxy');
  provenance.pairmat = which('kernel.qpgreen_mfs_pairmat');
  provenance.qpgreen_mfs = which('kernel.qpgreen_mfs');
  provenance.h2d_directch = which('kernel.h2d_directch');
  provenance.Faddeeva_erfc = which('Faddeeva_erfc');
  provenance.scientific_authority = strcmp(provenance.runtime, 'MATLAB');
  expected_precomp = fullfile(config.repo_root, '+kernel', 'precomp_proxy.m');
  expected_pairmat = fullfile(config.repo_root, '+kernel', ...
    'qpgreen_mfs_pairmat.m');
  expected_single = fullfile(config.repo_root, '+kernel', 'qpgreen_mfs.m');
  expected_h2d = fullfile(config.repo_root, '+kernel', 'h2d_directch.m');
  provenance.pass = strcmp(provenance.runtime, 'MATLAB') && ...
    provenance.lsqminnorm_exist ~= 0 && ...
    strcmp(provenance.precomp_proxy, expected_precomp) && ...
    strcmp(provenance.pairmat, expected_pairmat) && ...
    strcmp(provenance.qpgreen_mfs, expected_single) && ...
    strcmp(provenance.h2d_directch, expected_h2d);
  provenance.note = ['runtime=', provenance.runtime, ...
    '; solver=lsqminnorm; exact package paths required'];
end

function ledgers = LOCAL_append_provenance(ledgers, provenance)
  names = fieldnames(provenance);
  for j = 1:length(names)
    value = provenance.(names{j});
    if isnumeric(value) || islogical(value)
      value = num2str(value);
    end
    ledgers.backend.rows(end + 1, :) = {names{j}, value, ...
      'captured before package precomputation'};
  end
end

function ledgers = LOCAL_stop_later(ledgers, failed_stage, status)
  names = {'stage1_wrapper_parity', 'stage2_package_fd', ...
    'stage3_solver_sensitivity', 'stage4_proxy_ladder'};
  for j = failed_stage:length(names)
    ledgers.decision.rows(end + 1, :) = {names{j}, 'MANDATORY', ...
      'NOT_RUN_PREREQUISITE', 0, ['Stopped after ', status, '.']};
  end
end

function value = LOCAL_status(pass, pass_value, fail_value)
  if pass
    value = pass_value;
  else
    value = fail_value;
  end
end

function LOCAL_write_artifacts(output_dir, results)
  names = fieldnames(results.ledgers);
  for j = 1:length(names)
    name = names{j};
    LOCAL_write_csv(fullfile(output_dir, [name, '.csv']), ...
      results.ledgers.(name).headers, results.ledgers.(name).rows);
  end
  save(fullfile(output_dir, 'results.mat'), 'results');
  LOCAL_write_report(fullfile(output_dir, 'report.md'), results);
end

function LOCAL_write_csv(path, headers, rows)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_package_point_diagnostic:CSVOpenFailed', ...
      'Could not write %s.', path);
  end
  cleanup = onCleanup(@() fclose(fid));
  LOCAL_csv_row(fid, headers);
  for j = 1:size(rows, 1)
    LOCAL_csv_row(fid, rows(j, :));
  end
  clear cleanup;
end

function LOCAL_csv_row(fid, row)
  for j = 1:length(row)
    if j > 1
      fprintf(fid, ',');
    end
    value = row{j};
    if isnumeric(value) || islogical(value)
      if isempty(value)
        value = '';
      elseif isnan(value)
        value = 'NaN';
      else
        value = sprintf('%.17g', value);
      end
    else
      value = char(value);
    end
    value = strrep(value, '"', '""');
    fprintf(fid, '"%s"', value);
  end
  fprintf(fid, '\n');
end

function LOCAL_write_report(path, results)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_package_point_diagnostic:ReportOpenFailed', ...
      'Could not write report.');
  end
  cleanup = onCleanup(@() fclose(fid));
  fprintf(fid, '# I4 package point diagnostic\n\n');
  fprintf(fid, '- Status: `%s`\n', results.status);
  fprintf(fid, '- Scientific authority: `%d`\n', ...
    results.provenance.scientific_authority);
  fprintf(fid, '- Runtime: `%s %s`\n', ...
    results.provenance.runtime, results.provenance.version);
  fprintf(fid, '- Gate: $2\\times10^{-9}$\n');
  fprintf(fid, '- Wall matrices built: `0`\n\n');
  fprintf(fid, ['- Frozen points satisfy `idx_in=true`: after manual swap ', ...
    'their nonperiodic coordinate is $\\pm0.217$ and $H=1.1$; ', ...
    'the `C_down` branch is not used.\n\n']);
  fprintf(fid, '## Decisions\n\n');
  fprintf(fid, '| Stage | Classification | Status | Pass | Note |\n');
  fprintf(fid, '|---|---|---|---:|---|\n');
  rows = results.ledgers.decision.rows;
  for j = 1:size(rows, 1)
    fprintf(fid, '| %s | %s | %s | %g | %s |\n', ...
      rows{j, 1}, rows{j, 2}, rows{j, 3}, rows{j, 4}, rows{j, 5});
  end
  fprintf(fid, '\n## Reproduction\n\n```matlab\n');
  fprintf(fid, ['addpath(fullfile(pwd,''test'',', ...
    '''i4-three-path-derivatives''));\n']);
  fprintf(fid, 'run_i4_package_point_diagnostic();\n```\n');
  clear cleanup;
end

function LOCAL_log(fid, varargin)
  fprintf(fid, varargin{:});
  fprintf(varargin{:});
end
