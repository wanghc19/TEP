function results = bloch_pc_barnett_scan(user_opts)
% BLOCH_PC_BARNETT_SCAN Compare 2D QP-BIE phase dips with Bloch multipliers.
%
% Purpose:
%   Compare a Barnett-style two-dimensional quasiperiodic BIE phase scan
%   with transfer/Bloch multipliers for the same perfect periodic crystal
%   cell.
%
% Main algorithm:
%   Fix the exterior frequency and y-quasimomentum
%
%     omega = k,    beta,
%
%   where the y-direction phase is exp(1i*beta*d).  The Barnett-style scan
%   samples real x-direction phases
%
%     lambda = exp(1i*a),    a in [-pi,pi),
%
%   assembles a two-dimensional quasiperiodic Muller matrix
%
%     A_QP_2d(omega,beta,lambda),
%
%   and records
%
%     sigma_min(A_QP_2d).
%
%   The transfer/Bloch route uses the existing one-cell lead scattering
%   workflow at the same fixed (omega,beta) to solve directly for Bloch
%   multipliers lambda_j.  Only modes with abs(lambda_j) approximately one
%   are compared, using the phase distance
%
%     min_l |wrapToPi(arg(lambda_j) - a_dip,l)|.
%
%   The script also evaluates the Barnett matrix directly at each selected
%   transfer multiplier:
%
%     sigma_at_lambda_j = sigma_min(A_QP_2d(omega,beta,lambda_j)).
%
% Based on:
%   crystal_2d/README.md Step 2a, notes/implementation/mfs2d.md, the new
%   kernel.precomp_proxy2d/kernel.qpgreen2d_pairmat routines, and the
%   existing bloch.construct_S/bloch.solve_modes workflow.
%
% Main changes:
%   This is a perfect-crystal Bloch phase validation script, not a
%   scattering problem.  It introduces no lead incoming field and uses one
%   centered elliptic dielectric obstacle as the representative periodic
%   cell.
%
% Numerical goal:
%   Check whether the real-phase transfer/Bloch multipliers lie near dips
%   of a Barnett-style two-dimensional quasiperiodic BIE scan.
%
% Input:
%   user_opts - Optional struct for smoke tests or refinement studies.
%               Supported fields override the parameters in stage 1.
%
% Output:
%   results - Struct containing the scan curve, detected dips, transfer
%             multipliers, and phase-distance comparisons.

  if nargin < 1 || isempty(user_opts)
    user_opts = struct();
  end

  % --- stage 1: set parameters ---
  k = LOCAL_get_opt(user_opts, 'k', 2.35);              % Exterior wavenumber omega.
  nref = LOCAL_get_opt(user_opts, 'nref', 1.45);        % Interior refractive index; kint = nref*k.
  beta = LOCAL_get_opt(user_opts, 'beta', 0.19);        % y-quasimomentum used in exp(1i*beta*d).
  L = LOCAL_get_opt(user_opts, 'L', 2 * pi);            % x-period of the perfect crystal cell.
  d = LOCAL_get_opt(user_opts, 'd', 2 * pi);            % y-period of the perfect crystal cell.
  ellipse_a = LOCAL_get_opt(user_opts, 'ellipse_a', 0.62); % x semi-axis of centered ellipse.
  ellipse_b = LOCAL_get_opt(user_opts, 'ellipse_b', 0.45); % y semi-axis of centered ellipse.
  obstacle_center = [0; 0];                             % Center of the representative obstacle.

  ntot = LOCAL_get_opt(user_opts, 'ntot', 56);          % Even boundary nodes on the ellipse.
  M = LOCAL_get_opt(user_opts, 'M', 2);                 % Rayleigh truncation, modes m=-M:M.
  n_scan = LOCAL_get_opt(user_opts, 'n_scan', 45);      % Number of lambda=exp(1i*a) samples.
  n_dips_report = LOCAL_get_opt(user_opts, 'n_dips_report', 8); % Number of smallest local dips printed.
  tol_unit = LOCAL_get_opt(user_opts, 'tol_unit', 5e-2); % Unit-circle tolerance for transfer modes.
  dip_warning_tol = LOCAL_get_opt(user_opts, 'dip_warning_tol', 5e-2); % Warn if all scan minima exceed this size.
  make_plot = LOCAL_get_opt(user_opts, 'make_plot', true); % Draw sigma_min scan and Bloch markers.

  proxy_opts = struct();
  proxy_opts.N_proxy = LOCAL_get_opt(user_opts, 'N_proxy', 112); % Proxy sources for 2D QP Green.
  proxy_opts.N_check_x = LOCAL_get_opt(user_opts, 'N_check_x', 56); % Check points on bottom/top walls.
  proxy_opts.N_check_y = LOCAL_get_opt(user_opts, 'N_check_y', 56); % Check points on left/right walls.
  proxy_opts.proxy_radius_factor = LOCAL_get_opt(user_opts, 'proxy_radius_factor', 1.8);
  proxy_opts.solver = LOCAL_get_opt(user_opts, 'proxy_solver', 'svd');

  pars1 = struct();
  pars1.k = k;                  % Exterior wavenumber for the one-directional proxy precompute.
  pars1.beta = beta;             % y-periodic Bloch parameter for the transfer/Bloch Green function.
  pars1.d = d;                   % y-period used by the existing one-directional QP kernel.
  pars1.periodic_axis = 'y';     % The lead-cell scattering problem is periodic in y and open in x.
  pars2 = struct();
  pars2.H = 0.5 * L + max(ellipse_a, ellipse_b) + 0.4; % Computational half-width after axis swap.
  pars2.proxy_dist = LOCAL_get_opt(user_opts, 'proxy_dist_1d', 0.7);
  pars2.N_side = LOCAL_get_opt(user_opts, 'N_side_1d', 80);
  pars2.N_top = LOCAL_get_opt(user_opts, 'N_top_1d', 80);
  pars2.N_proxy_edge = LOCAL_get_opt(user_opts, 'N_proxy_edge_1d', 40);
  pars2.M_pw = LOCAL_get_opt(user_opts, 'M_pw_1d', 12);

  X_minus = -0.5 * L;
  X_plus = 0.5 * L;
  Y_minus = -0.5 * d;
  Y_plus = 0.5 * d;
  kext = k;
  kint = nref * k;

  % --- stage 2: build the shared cell geometry ---
  if mod(ntot, 2) ~= 0
    error('crystal_2d:bloch_pc_barnett_scan:OddBoundaryGrid', ...
      'ntot must be even for the Kress quadrature used by the Muller matrix.');
  end
  [C, curvelen, ~, ~] = geom.construct_cont(ntot, 'ellipse', 0, 0, ...
    ellipse_a, ellipse_b);
  C(1, :) = C(1, :) + obstacle_center(1);
  C(4, :) = C(4, :) + obstacle_center(2);

  % --- stage 3: run transfer/Bloch mode solve ---
  rayleighchan = bloch.rayleigh_channels(kext, beta, d, M, L);
  proxy1d = kernel.precomp_proxy(pars1, pars2);
  S_cell = bloch.construct_S(C, kext, kint, pars1, proxy1d, curvelen, ...
    rayleighchan, X_minus, X_plus);
  mode_opts = struct();
  mode_opts.lambda_tol = tol_unit;
  mode_opts.normalize = 'trace_L';
  modes = bloch.solve_modes(S_cell, mode_opts);
  transfer_lambda = modes.lambda(:);
  transfer_abs = abs(transfer_lambda);
  unit_idx = abs(transfer_abs - 1) < tol_unit;
  transfer_unit_lambda = transfer_lambda(unit_idx);
  transfer_unit_phase = LOCAL_wrap_to_pi(angle(transfer_unit_lambda));

  % --- stage 4: run Barnett-style 2D quasiperiodic BIE scan ---
  a_values = linspace(-pi, pi, n_scan + 1);
  a_values(end) = [];
  sigma_min = zeros(size(a_values));
  proxy_residual = zeros(size(a_values));
  for ia = 1:numel(a_values)
    lambda = exp(1i * a_values(ia));
    [sigma_min(ia), aux_A] = LOCAL_eval_barnett_sigma(lambda, C, curvelen, ...
      kext, kint, beta, X_minus, X_plus, Y_minus, Y_plus, proxy_opts);
    proxy_residual(ia) = aux_A.proxy_relative_residual;
  end

  % --- stage 5: evaluate transfer multipliers directly and compare phases ---
  dip_idx = LOCAL_find_scan_dips(sigma_min, n_dips_report);
  a_dip = a_values(dip_idx);
  sigma_dip = sigma_min(dip_idx);
  lambda_dip = exp(1i * a_dip);
  [phase_distance, nearest_dip_idx] = LOCAL_compare_transfer_to_dips( ...
    transfer_unit_phase, a_dip);
  sigma_at_lambda = zeros(size(transfer_unit_lambda));
  sigma_at_lambda_proxy_residual = zeros(size(transfer_unit_lambda));
  for j = 1:numel(transfer_unit_lambda)
    [sigma_at_lambda(j), aux_A] = LOCAL_eval_barnett_sigma( ...
      transfer_unit_lambda(j), C, curvelen, kext, kint, beta, ...
      X_minus, X_plus, Y_minus, Y_plus, proxy_opts);
    sigma_at_lambda_proxy_residual(j) = aux_A.proxy_relative_residual;
  end

  % --- stage 6: report diagnostics ---
  fprintf('\n2D perfect-crystal Barnett scan versus transfer/Bloch modes\n');
  fprintf('  omega k                         : %.16g\n', k);
  fprintf('  beta                            : %.16g\n', beta);
  fprintf('  L, d                            : %.16g, %.16g\n', L, d);
  fprintf('  ellipse semi-axes a,b           : %.16g, %.16g\n', ellipse_a, ellipse_b);
  fprintf('  refractive index n              : %.16g\n', nref);
  fprintf('  boundary nodes ntot             : %d\n', ntot);
  fprintf('  Rayleigh truncation M           : %d\n', M);
  fprintf('  lambda scan samples             : %d\n', numel(a_values));
  fprintf('  2D proxy sources/check x/check y: %d / %d / %d\n', ...
    proxy_opts.N_proxy, proxy_opts.N_check_x, proxy_opts.N_check_y);
  fprintf('  max Barnett proxy residual      : %.3e\n', max(proxy_residual));
  fprintf('  transfer solve residual         : %.3e\n', S_cell.solve_relative_residual_norm);

  if isempty(dip_idx)
    fprintf('WARNING: no Barnett sigma_min dips were detected.\n');
  else
    if min(sigma_dip) > dip_warning_tol
      fprintf('WARNING: smallest Barnett dip %.3e is above dip_warning_tol %.3e.\n', ...
        min(sigma_dip), dip_warning_tol);
    end
    fprintf('\nBarnett sigma_min dips:\n');
    fprintf('  %4s  %14s  %24s  %14s\n', 'idx', 'a_dip', 'lambda_dip', 'sigma_min');
    for j = 1:numel(dip_idx)
      fprintf('  %4d  %+.8e  %+.8e%+.8ei  %.8e\n', dip_idx(j), ...
        a_dip(j), real(lambda_dip(j)), imag(lambda_dip(j)), sigma_dip(j));
    end
  end

  fprintf('\nTransfer/Bloch modes with abs(lambda) near one:\n');
  if isempty(transfer_unit_lambda)
    fprintf('WARNING: no transfer/Bloch modes satisfy abs(abs(lambda)-1) < %.3e.\n', ...
      tol_unit);
  else
    fprintf('  %4s  %24s  %14s  %14s  %14s  %14s\n', ...
      'idx', 'lambda_j', 'abs(lambda)', 'arg(lambda)', 'dist_to_dip', ...
      'sigma_at_lambda');
    unit_ids = find(unit_idx);
    for j = 1:numel(transfer_unit_lambda)
      fprintf('  %4d  %+.8e%+.8ei  %.8e  %+.8e  %.8e  %.8e\n', ...
        unit_ids(j), real(transfer_unit_lambda(j)), imag(transfer_unit_lambda(j)), ...
        abs(transfer_unit_lambda(j)), transfer_unit_phase(j), phase_distance(j), ...
        sigma_at_lambda(j));
    end
    fprintf('  sigma_at_lambda min/max/median  : %.3e / %.3e / %.3e\n', ...
      min(sigma_at_lambda), max(sigma_at_lambda), median(sigma_at_lambda));
    fprintf('  max direct-eval proxy residual  : %.3e\n', ...
      max(sigma_at_lambda_proxy_residual));
  end

  if isempty(dip_idx) || isempty(transfer_unit_lambda)
    fprintf('WARNING: phase comparison is incomplete because one side is empty.\n');
  end

  % --- stage 7: plot the comparison ---
  if make_plot
    LOCAL_plot_scan(a_values, sigma_min, transfer_unit_phase, k, beta);
  end

  results = struct();
  results.k = k;
  results.beta = beta;
  results.L = L;
  results.d = d;
  results.ellipse_a = ellipse_a;
  results.ellipse_b = ellipse_b;
  results.nref = nref;
  results.ntot = ntot;
  results.M = M;
  results.dip_warning_tol = dip_warning_tol;
  results.a_values = a_values;
  results.sigma_min = sigma_min;
  results.proxy_residual = proxy_residual;
  results.dip_idx = dip_idx;
  results.a_dip = a_dip;
  results.lambda_dip = lambda_dip;
  results.sigma_dip = sigma_dip;
  results.transfer_lambda = transfer_lambda;
  results.transfer_unit_lambda = transfer_unit_lambda;
  results.transfer_unit_phase = transfer_unit_phase;
  results.phase_distance = phase_distance;
  results.nearest_dip_idx = nearest_dip_idx;
  results.sigma_at_lambda = sigma_at_lambda;
  results.sigma_at_lambda_proxy_residual = sigma_at_lambda_proxy_residual;
  results.S_cell = S_cell;
  results.modes = modes;

end

%% ==================== Option helper ====================
% This helper reads optional user overrides while keeping defaults near the top.

function val = LOCAL_get_opt(opts, name, default_val)

  if isfield(opts, name) && ~isempty(opts.(name))
    val = opts.(name);
  else
    val = default_val;
  end

end

%% ==================== Muller assembly helper ====================
% This helper assembles the Barnett-style two-dimensional QP Muller matrix.

function [sigma_min_val, aux_A] = LOCAL_eval_barnett_sigma(lambda, C, curvelen, ...
    kext, kint, beta, X_minus, X_plus, Y_minus, Y_plus, proxy_opts)

  pars2d = struct();
  pars2d.k = kext;
  pars2d.beta = beta;
  pars2d.lambda = lambda;
  pars2d.X_minus = X_minus;
  pars2d.X_plus = X_plus;
  pars2d.Y_minus = Y_minus;
  pars2d.Y_plus = Y_plus;

  proxy2d = kernel.precomp_proxy2d(pars2d, proxy_opts);
  [A_QP_2d, aux_A] = LOCAL_construct_A_QP_2d(C, kext, kint, pars2d, ...
    proxy2d, curvelen);
  svals = svd(full(complex(A_QP_2d)));
  sigma_min_val = min(svals);

end

function [A_QP, aux] = LOCAL_construct_A_QP_2d(C, kext, kint, pars2d, proxy2d, curvelen)

  ntot = size(C, 2);
  h = curvelen / ntot;
  x = C(1, :);
  y = C(4, :);
  dxdt = C(2, :);
  dydt = C(5, :);
  speed = sqrt(dxdt.^2 + dydt.^2);
  bd = [x; y];

  [pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext, aux_qp] = ...
    kernel.qpgreen2d_pairmat(bd, bd, pars2d, proxy2d);

  geom_data = LOCAL_geom_data_from_C(C, curvelen);
  [free_ext, reg_ext] = LOCAL_split_exterior_qp_regular(kext, bd, pot_ext, ...
    gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext, aux_qp);

  A11 = LOCAL_assemble_D_block(geom_data, kext, kint, reg_ext, free_ext, 'D_ext_minus_D_int');
  A12 = LOCAL_assemble_S_block(geom_data, kext, kint, reg_ext, free_ext);
  A21 = LOCAL_assemble_T_block(geom_data, kext, kint, reg_ext);
  A22 = LOCAL_assemble_Dstar_block(geom_data, kext, kint, reg_ext, free_ext);

  A_QP = eye(2 * ntot, 2 * ntot);
  A_QP(1:ntot, 1:ntot) = A_QP(1:ntot, 1:ntot) + A11;
  A_QP(1:ntot, ntot + 1:end) = A12;
  A_QP(ntot + 1:end, 1:ntot) = A21;
  A_QP(ntot + 1:end, ntot + 1:end) = ...
    A_QP(ntot + 1:end, ntot + 1:end) + A22;

  scale_row = sqrt(h * [speed, speed]).';
  scale_col = sqrt((1 / h) ./ [speed, speed]);
  A_QP = bsxfun(@times, bsxfun(@times, A_QP, scale_col), scale_row);

  aux = struct();
  aux.proxy_relative_residual = aux_qp.proxy_relative_residual;
  aux.reg_ext = reg_ext;
  aux.free_ext = free_ext;

end

function geom_data = LOCAL_geom_data_from_C(C, curvelen)

  ntot = size(C, 2);
  [t, D] = utils.triginterp(ntot);
  geom_data = struct();
  geom_data.t = t;
  geom_data.D = D;
  geom_data.h = curvelen / ntot;
  geom_data.z = [C(1, :).', C(4, :).'];
  geom_data.zp = [C(2, :).', C(5, :).'];
  geom_data.zpp = [C(3, :).', C(6, :).'];
  geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));
  geom_data.normal = [geom_data.zp(:, 2) ./ geom_data.speed, ...
    -geom_data.zp(:, 1) ./ geom_data.speed];

end

function [free_ext, reg_ext] = LOCAL_split_exterior_qp_regular(kext, bd, pot_qp, ...
    gradx_qp, grady_qp, hessxx_qp, hessxy_qp, hessyy_qp, aux_qp)

  ntot = size(bd, 2);
  [pot_free, grad_free, hess_free] = LOCAL_free_pair_all(kext, bd, bd);

  free_ext = struct();
  free_ext.pot = pot_free;
  free_ext.gradx = grad_free.x;
  free_ext.grady = grad_free.y;
  free_ext.hessxx = hess_free.xx;
  free_ext.hessxy = hess_free.xy;
  free_ext.hessyy = hess_free.yy;
  free_ext.srcgradx = -grad_free.x;
  free_ext.srcgrady = -grad_free.y;
  free_ext.trgsrc_xx = -hess_free.xx;
  free_ext.trgsrc_xy = -hess_free.xy;
  free_ext.trgsrc_yx = -hess_free.xy;
  free_ext.trgsrc_yy = -hess_free.yy;

  reg_ext = struct();
  reg_ext.pot = pot_qp - free_ext.pot;
  reg_ext.gradx = gradx_qp - free_ext.gradx;
  reg_ext.grady = grady_qp - free_ext.grady;
  reg_ext.srcgradx = aux_qp.srcgradx - free_ext.srcgradx;
  reg_ext.srcgrady = aux_qp.srcgrady - free_ext.srcgrady;
  reg_ext.trgsrc_xx = aux_qp.trgsrc_xx - free_ext.trgsrc_xx;
  reg_ext.trgsrc_xy = aux_qp.trgsrc_xy - free_ext.trgsrc_xy;
  reg_ext.trgsrc_yx = aux_qp.trgsrc_yx - free_ext.trgsrc_yx;
  reg_ext.trgsrc_yy = aux_qp.trgsrc_yy - free_ext.trgsrc_yy;

  diag_idx = 1:ntot + 1:ntot * ntot;
  reg_ext.pot(diag_idx) = aux_qp.regdiag.pot;
  reg_ext.srcgradx(diag_idx) = aux_qp.regdiag.srcgradx;
  reg_ext.srcgrady(diag_idx) = aux_qp.regdiag.srcgrady;
  reg_ext.gradx(diag_idx) = gradx_qp(diag_idx);
  reg_ext.grady(diag_idx) = grady_qp(diag_idx);
  reg_ext.trgsrc_xx(diag_idx) = aux_qp.trgsrc_xx(diag_idx);
  reg_ext.trgsrc_xy(diag_idx) = aux_qp.trgsrc_xy(diag_idx);
  reg_ext.trgsrc_yx(diag_idx) = aux_qp.trgsrc_yx(diag_idx);
  reg_ext.trgsrc_yy(diag_idx) = aux_qp.trgsrc_yy(diag_idx);

  reg_ext.hessxx = hessxx_qp - free_ext.hessxx;
  reg_ext.hessxy = hessxy_qp - free_ext.hessxy;
  reg_ext.hessyy = hessyy_qp - free_ext.hessyy;

end

function A11 = LOCAL_assemble_D_block(geom_data, kext, kint, reg_ext, free_ext, block_name)

  ntot = length(geom_data.t);
  R = LOCAL_kress_matrix(ntot);
  [L1_in, L2_in] = kernel.kress_l_splits(kint, geom_data.t, geom_data);
  [L1_out, L2_out] = kernel.kress_l_splits(kext, geom_data.t, geom_data);
  D_free_diff = R .* (L1_out - L1_in) + geom_data.h * (L2_out - L2_in);

  nyx = geom_data.normal(:, 1).';
  nyy = geom_data.normal(:, 2).';
  dGdnu_reg = bsxfun(@times, reg_ext.srcgradx, nyx) + ...
    bsxfun(@times, reg_ext.srcgrady, nyy);
  D_reg = bsxfun(@times, dGdnu_reg, (geom_data.h * geom_data.speed).');

  if ~strcmp(block_name, 'D_ext_minus_D_int')
    error('crystal_2d:bloch_pc_barnett_scan:InvalidBlockName', ...
      'Unexpected D block assembly request.');
  end
  A11 = D_free_diff + D_reg;

end

function A12 = LOCAL_assemble_S_block(geom_data, kext, kint, reg_ext, free_ext)

  ntot = length(geom_data.t);
  R = LOCAL_kress_matrix(ntot);
  [M1_in, M2_in] = kernel.kress_mn_splits(kint, geom_data.t, geom_data);
  [M1_out, M2_out] = kernel.kress_mn_splits(kext, geom_data.t, geom_data);
  S_free_diff = R .* (M1_in - M1_out) + geom_data.h * (M2_in - M2_out);
  S_reg = bsxfun(@times, reg_ext.pot, (geom_data.h * geom_data.speed).');
  A12 = S_free_diff - S_reg;

end

function A22 = LOCAL_assemble_Dstar_block(geom_data, kext, kint, reg_ext, free_ext)

  ntot = length(geom_data.t);
  R = LOCAL_kress_matrix(ntot);
  [~, ~, Ls1_in, Ls2_in] = kernel.kress_l_splits(kint, geom_data.t, geom_data);
  [~, ~, Ls1_out, Ls2_out] = kernel.kress_l_splits(kext, geom_data.t, geom_data);
  Dstar_free_diff = R .* (Ls1_in - Ls1_out) + geom_data.h * (Ls2_in - Ls2_out);

  nxx = geom_data.normal(:, 1);
  nxy = geom_data.normal(:, 2);
  dGdnx_reg = bsxfun(@times, reg_ext.gradx, nxx) + ...
    bsxfun(@times, reg_ext.grady, nxy);
  Dstar_reg = bsxfun(@times, dGdnx_reg, (geom_data.h * geom_data.speed).');
  A22 = Dstar_free_diff - Dstar_reg;

end

function A21 = LOCAL_assemble_T_block(geom_data, kext, kint, reg_ext)

  T_free_diff = LOCAL_assemble_Tdiff_free(geom_data, kext, kint);

  nxx = geom_data.normal(:, 1);
  nxy = geom_data.normal(:, 2);
  nyx = geom_data.normal(:, 1).';
  nyy = geom_data.normal(:, 2).';

  mixed_reg = bsxfun(@times, reg_ext.trgsrc_xx, nxx) .* nyx + ...
    bsxfun(@times, reg_ext.trgsrc_xy, nxx) .* nyy + ...
    bsxfun(@times, reg_ext.trgsrc_yx, nxy) .* nyx + ...
    bsxfun(@times, reg_ext.trgsrc_yy, nxy) .* nyy;
  T_reg = bsxfun(@times, mixed_reg, (geom_data.h * geom_data.speed).');
  A21 = T_free_diff + T_reg;

end

function Tdiff_free = LOCAL_assemble_Tdiff_free(geom_data, kext, kint)

  ntot = length(geom_data.t);
  R = LOCAL_kress_matrix(ntot);
  G = (geom_data.zp * geom_data.zp.') ./ (geom_data.speed * geom_data.speed.');

  [M1_ext, M2_ext, N1_ext, N2_ext] = kernel.kress_mn_splits(kext, ...
    geom_data.t, geom_data);
  [M1_int, M2_int, N1_int, N2_int] = kernel.kress_mn_splits(kint, ...
    geom_data.t, geom_data);

  delta_M1 = kext^2 * M1_ext - kint^2 * M1_int;
  delta_M2 = kext^2 * M2_ext - kint^2 * M2_int;
  delta_N1 = N1_ext - N1_int;
  delta_N2 = N2_ext - N2_int;

  A = (R .* delta_M1 + geom_data.h * delta_M2) .* G;
  B_unscaled = R .* delta_N1 + geom_data.h * delta_N2;
  B = bsxfun(@rdivide, B_unscaled, geom_data.speed);
  Tdiff_free = A + B * geom_data.D;

end

function R = LOCAL_kress_matrix(ntot)

  rvec = quad.quad_kress_rvec(ntot);
  offset_idx = mod((0:ntot - 1) - (0:ntot - 1).', ntot) + 1;
  R = rvec(offset_idx);

end

%% ==================== Free-space pair helper ====================
% This helper returns off-diagonal pair matrices for the free Helmholtz kernel.

function [pot, grad, hess] = LOCAL_free_pair_all(k, trg, src)

  xdiff = bsxfun(@minus, trg(1, :).', src(1, :));
  ydiff = bsxfun(@minus, trg(2, :).', src(2, :));
  rr = xdiff.^2 + ydiff.^2;
  singular = rr == 0;
  rr(singular) = 1;
  r = sqrt(rr);
  z = k * r;

  ima4inv = 1i / 4;
  h0 = besselh(0, 1, z);
  h1 = besselh(1, 1, z);
  cdd = -h1 .* (k * ima4inv ./ r);
  cdd2 = (k * ima4inv ./ r) ./ rr;
  h2z = -z .* h0 + 2 * h1;

  pot = ima4inv * h0;
  grad = struct();
  grad.x = cdd .* xdiff;
  grad.y = cdd .* ydiff;
  hess = struct();
  hess.xx = cdd2 .* (h2z .* xdiff .* xdiff - rr .* h1);
  hess.xy = cdd2 .* (h2z .* xdiff .* ydiff);
  hess.yy = cdd2 .* (h2z .* ydiff .* ydiff - rr .* h1);

  pot(singular) = 0;
  grad.x(singular) = 0;
  grad.y(singular) = 0;
  hess.xx(singular) = 0;
  hess.xy(singular) = 0;
  hess.yy(singular) = 0;

end

%% ==================== Dip comparison helper ====================
% These helpers find scan dips and compare them with transfer mode phases.

function dip_idx = LOCAL_find_scan_dips(sigma_min, n_dips_report)

  n = numel(sigma_min);
  local_min = false(size(sigma_min));
  for j = 1:n
    jm = mod(j - 2, n) + 1;
    jp = mod(j, n) + 1;
    local_min(j) = sigma_min(j) <= sigma_min(jm) && sigma_min(j) <= sigma_min(jp);
  end

  candidates = find(local_min & isfinite(sigma_min));
  if isempty(candidates)
    [~, candidates] = min(sigma_min);
  end
  [~, order] = sort(sigma_min(candidates), 'ascend');
  candidates = candidates(order);
  dip_idx = candidates(1:min(n_dips_report, numel(candidates)));

end

function [phase_distance, nearest_dip_idx] = LOCAL_compare_transfer_to_dips(phase, a_dip)

  phase = phase(:);
  phase_distance = zeros(size(phase));
  nearest_dip_idx = zeros(size(phase));
  if isempty(a_dip)
    phase_distance(:) = NaN;
    nearest_dip_idx(:) = NaN;
    return;
  end

  for j = 1:numel(phase)
    dist = abs(LOCAL_wrap_to_pi(phase(j) - a_dip(:)));
    [phase_distance(j), nearest_dip_idx(j)] = min(dist);
  end

end

function theta = LOCAL_wrap_to_pi(theta)

  theta = mod(theta + pi, 2 * pi) - pi;

end

%% ==================== Plotting helper ====================
% This helper draws the Barnett scan and transfer/Bloch real-phase markers.

function LOCAL_plot_scan(a_values, sigma_min, transfer_unit_phase, k, beta)

  try
    figure;
    semilogy(a_values, sigma_min, 'b.-', 'LineWidth', 1.2, 'MarkerSize', 10);
    hold on;
    yl = ylim;
    for j = 1:numel(transfer_unit_phase)
      plot([transfer_unit_phase(j), transfer_unit_phase(j)], yl, 'r--', 'LineWidth', 1.0);
    end
    xlabel('a, lambda = exp(1i*a)');
    ylabel('sigma_min(A_QP_2d)');
    title(sprintf('Barnett 2D QP-BIE scan, k=%.4g, beta=%.4g', k, beta));
    legend('Barnett scan', 'transfer/Bloch unit |lambda|', 'Location', 'best');
    grid on;
    hold off;
  catch plot_err
    warning('crystal_2d:bloch_pc_barnett_scan:PlotFailed', ...
      'Plotting failed: %s', plot_err.message);
  end

end
