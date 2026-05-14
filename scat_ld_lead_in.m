function scat_ld_lead_in()
% Purpose:
%   Solve a lead-incoming scattering problem for a linear-defect
%   configuration whose center cell may contain a dielectric obstacle.
%
% Main algorithm:
%   This script follows the direct BIE + port trace matching formulation in
%   notes/theory/scat_formulation2.md.  The center obstacle density
%   eta = [tau; -sigma] is coupled to center-cell homogeneous Rayleigh
%   coefficients and to outgoing Bloch trace spaces in the two half-leads.
%
% Based on:
%   scat_edc_lead_in.m for incoming/outgoing Bloch mode selection and
%   trace-matching workflow.  The main difference is that the center cell is
%   no longer empty: it has a Muller BIE row A_QP*eta plus center Rayleigh
%   boundary forcing rows H_Sigma^+*c^+ and H_Sigma^-*c^-.
%
% Main changes:
%   The unknown vector is
%
%     unknown = [eta; c^+; c^-; a_s^-; a_s^+],
%
%   where eta is the center obstacle BIE density, c^+/c^- are center-cell
%   Rayleigh right-going/left-going coefficients, and a_s^-/a_s^+ are
%   outgoing scattered Bloch coefficients in the negative/positive half-leads.
%
% Numerical goal:
%   For one fixed beta and k, compute the forced response to one incoming
%   half-lead Bloch mode and report the global, BIE-row, and port-matching
%   residuals.  This is a scattering / forced-response problem, not a TEP,
%   not an eigenvalue search, and not a scan.

  format long;

  % --- stage 1: set user parameters ---

  % y-quasiperiodic parameter and physical y-period.
  beta = 0.4;
  d = 2 * pi;

  % Center-cell wall coordinates.  The y-span must agree with d.
  X_minus = -1.0;
  X_plus = 1.0;
  Y_minus = -d / 2;
  Y_plus = d / 2;

  % x-periods of the negative and positive half-lead reference cells.
  L_minus = 2.0;
  L_plus = 2.0;

  % Exterior/background wavenumber.  eps_k regularizes mode selection near
  % the real axis in this prototype.
  k_real = 1.3;
  eps_k = 1e-4;
  kext = k_real + 1i * eps_k;

  % Refractive-index ratios for the center, negative-lead, and positive-lead
  % obstacles.  The corresponding interior wavenumbers are n_* * kext.
  n_0 = 1.5;
  n_minus = 1.5;
  n_plus = 1.5;
  kint_0 = n_0 * kext;
  kint_minus = n_minus * kext;
  kint_plus = n_plus * kext;

  % Boundary discretization.  Use even values because the Kress quadrature in
  % op.construct_A_QP assumes an even number of samples.
  ntot_0 = 40;
  ntot_minus = 40;
  ntot_plus = 40;

  % Obstacle geometry in the center reference cell C0.  For ellipse geometry,
  % ellipse_a_* and ellipse_b_* are the x/y semi-axes and may be adjusted
  % independently for the three regions.
  flag_geom_0 = 'ellipse';
  ellipse_a_0 = 0.34;
  ellipse_b_0 = 0.22;
  q_0 = [(X_minus + X_plus) / 2; (Y_minus + Y_plus) / 2];

  % Obstacle geometry in the negative lead reference cell
  % [X_minus-L_minus, X_minus] x [Y_minus,Y_plus].
  flag_geom_minus = 'ellipse';
  ellipse_a_minus = 0.32;
  ellipse_b_minus = 0.24;
  q_minus = [X_minus - L_minus / 2; (Y_minus + Y_plus) / 2];

  % Obstacle geometry in the positive lead reference cell
  % [X_plus, X_plus+L_plus] x [Y_minus,Y_plus].
  flag_geom_plus = 'ellipse';
  ellipse_a_plus = 0.28;
  ellipse_b_plus = 0.36;
  q_plus = [X_plus + L_plus / 2; (Y_minus + Y_plus) / 2];

  geom_args_0 = LOCAL_geom_args(flag_geom_0, ellipse_a_0, ellipse_b_0);
  geom_args_minus = LOCAL_geom_args(flag_geom_minus, ellipse_a_minus, ...
    ellipse_b_minus);
  geom_args_plus = LOCAL_geom_args(flag_geom_plus, ellipse_a_plus, ...
    ellipse_b_plus);

  % Rayleigh truncation half-width.  K = 2*M + 1.
  M = 10;

  % Proxy-source parameters used by kernel.precomp_proxy for the physical
  % y-periodic quasi-periodic Green representation.
  pars1.k = kext;
  pars1.beta = beta;
  pars1.d = d;
  pars1.periodic_axis = 'y';
  max_x_width = max([X_plus - X_minus, L_minus, L_plus]);
  max_obstacle_extent = max([ellipse_a_0, ellipse_b_0, ellipse_a_minus, ...
    ellipse_b_minus, ellipse_a_plus, ellipse_b_plus]);
  pars2.H = max_x_width / 2 + max_obstacle_extent + 0.4;
  pars2.proxy_dist = 0.7;
  pars2.N_side = 40;
  pars2.N_top = 40;
  pars2.N_proxy_edge = 24;
  pars2.M_pw = 8;

  % Mode-selection tolerance for outgoing and incoming half-lead traces.
  opts.lambda_tol = 1e-8;

  % Incoming port selection.  incident_port controls whether the incoming
  % Bloch mode enters from the negative half-lead ('-') or positive half-lead
  % ('+').  incident_mode_index selects one sorted incoming mode.
  incident_port = '-';
  incident_mode_policy = 'least_decay';
  incident_mode_index = 1;

  do_plot_trace = false;

  % Solution contour plotting controls.  This first visualization pass draws
  % only exterior fields and masks every dielectric obstacle interior.  The
  % center obstacle interior field is not reconstructed here.
  do_plot_solution = true;
  x_plot_min = X_minus - 2 * L_minus;
  x_plot_max = X_plus + 2 * L_plus;
  y_plot_min = Y_minus - d;
  y_plot_max = Y_plus + d;
  nx_plot = 100;
  ny_plot = 90;
  ncontour = 40;

  % Column-lattice visualization controls.  Each region may use different
  % ellipse semi-axes during this testing stage.
  col_lat.C0 = [X_minus, X_plus; Y_minus, Y_plus];
  col_lat.left.Lx = L_minus;
  col_lat.left.flag_geom = flag_geom_minus;
  col_lat.left.q = q_minus;
  col_lat.left.geom_args = geom_args_minus;
  col_lat.center.flag_geom = flag_geom_0;
  col_lat.center.q = q_0;
  col_lat.center.geom_args = geom_args_0;
  col_lat.right.Lx = L_plus;
  col_lat.right.flag_geom = flag_geom_plus;
  col_lat.right.q = q_plus;
  col_lat.right.geom_args = geom_args_plus;

  col_lat_opts.nt_contour = 160;
  col_lat_opts.cell_lines = 'center';
  col_lat_opts.contour_line_spec = 'k-';
  col_lat_opts.contour_line_width = 0.9;
  col_lat_opts.cell_line_spec = 'k--';
  col_lat_opts.cell_line_width = 1.1;
  col_lat_opts.apply_axis_format = true;

  % --- stage 2: build geometry, proxy, and Rayleigh channels ---

  if abs((Y_plus - Y_minus) - d) > 1e-12 * max(1, abs(d))
    error('scat_ld_lead_in:InconsistentYPeriod', ...
      'Y_plus - Y_minus must equal d for this prototype.');
  end

  [C0, curvelen_0] = LOCAL_construct_shifted_cont(ntot_0, flag_geom_0, ...
    q_0, geom_args_0);
  [C_minus, curvelen_minus] = LOCAL_construct_shifted_cont(ntot_minus, ...
    flag_geom_minus, q_minus, geom_args_minus);
  [C_plus, curvelen_plus] = LOCAL_construct_shifted_cont(ntot_plus, ...
    flag_geom_plus, q_plus, geom_args_plus);

  proxy = kernel.precomp_proxy(pars1, pars2);

  L0 = X_plus - X_minus;
  rayleigh_center = bloch.rayleigh_channels(kext, beta, d, M, L0);
  rayleigh_minus = bloch.rayleigh_channels(kext, beta, d, M, L_minus);
  rayleigh_plus = bloch.rayleigh_channels(kext, beta, d, M, L_plus);
  K = rayleigh_center.K;

  % --- stage 3: construct lead Bloch data ---

  X_L_minus = X_minus - L_minus;
  X_R_minus = X_minus;
  X_L_plus = X_plus;
  X_R_plus = X_plus + L_plus;

  S_cell_minus = bloch.construct_S(C_minus, kext, kint_minus, pars1, ...
    proxy, curvelen_minus, rayleigh_minus, X_L_minus, X_R_minus);
  modes_minus = bloch.solve_modes(S_cell_minus);
  traces_minus = bloch.mode_traces(modes_minus.lambda, modes_minus.V, ...
    rayleigh_minus);

  S_cell_plus = bloch.construct_S(C_plus, kext, kint_plus, pars1, ...
    proxy, curvelen_plus, rayleigh_plus, X_L_plus, X_R_plus);
  modes_plus = bloch.solve_modes(S_cell_plus);
  traces_plus = bloch.mode_traces(modes_plus.lambda, modes_plus.V, ...
    rayleigh_plus);

  % --- stage 4: select incoming and outgoing trace spaces ---

  [D_out_minus, N_out_minus, selected_out_minus] = ...
    bloch.select_port_traces(modes_minus, traces_minus, '-', opts);
  [D_out_plus, N_out_plus, selected_out_plus] = ...
    bloch.select_port_traces(modes_plus, traces_plus, '+', opts);

  in_opts.lambda_tol = opts.lambda_tol;
  in_opts.policy = incident_mode_policy;
  in_opts.mode_index = incident_mode_index;
  [D_in_minus, N_in_minus, selected_in_minus] = ...
    LOCAL_select_incoming_port_traces(modes_minus, traces_minus, '-', in_opts);
  [D_in_plus, N_in_plus, selected_in_plus] = ...
    LOCAL_select_incoming_port_traces(modes_plus, traces_plus, '+', in_opts);

  K_out_minus = selected_out_minus.numSelected;
  K_out_plus = selected_out_plus.numSelected;
  if K_out_minus == 0 || K_out_plus == 0
    warning('scat_ld_lead_in:NoOutgoingModes', ...
      'At least one outgoing port trace space is empty.');
  end

  % --- stage 5: assemble center BIE and coupled trace-matching system ---

  A_QP = full(complex(op.construct_A_QP(C0, kext, kint_0, pars1, proxy, ...
    curvelen_0)));
  [H_sigma_plus, H_sigma_minus] = LOCAL_construct_H_sigma(C0, ...
    rayleigh_center, X_minus);
  [F_minus, F_plus] = bloch.farfield_extractors(C0, rayleigh_center, ...
    X_minus, X_plus, curvelen_0);
  F_minus = full(complex(F_minus));
  F_plus = full(complex(F_plus));

  A_trmatch = LOCAL_construct_A_trmatch(A_QP, H_sigma_plus, H_sigma_minus, ...
    F_minus, F_plus, rayleigh_center, D_out_minus, N_out_minus, ...
    D_out_plus, N_out_plus, X_minus, X_plus);

  [rhs_in, p_in_minus, p_in_plus, lambda_in_active] = LOCAL_construct_rhs_in( ...
    D_in_minus, N_in_minus, D_in_plus, N_in_plus, selected_in_minus, ...
    selected_in_plus, incident_port, incident_mode_index, size(A_QP, 1));

  % --- stage 6: solve forced scattering system ---

  sol = A_trmatch \ rhs_in;

  Neta = size(A_QP, 2);
  eta = sol(1:Neta);
  c_plus = sol(Neta + 1:Neta + K);
  c_minus = sol(Neta + K + 1:Neta + 2 * K);
  a_s_minus = sol(Neta + 2 * K + 1:Neta + 2 * K + K_out_minus);
  a_s_plus = sol(Neta + 2 * K + K_out_minus + 1:end);

  diagnostics = LOCAL_compute_diagnostics(A_trmatch, rhs_in, A_QP, ...
    H_sigma_plus, H_sigma_minus, F_minus, F_plus, rayleigh_center, ...
    D_in_minus, N_in_minus, D_in_plus, N_in_plus, D_out_minus, ...
    N_out_minus, D_out_plus, N_out_plus, eta, c_plus, c_minus, ...
    a_s_minus, a_s_plus, p_in_minus, p_in_plus, X_minus, X_plus);

  % --- stage 7: report diagnostics ---

  fprintf('scat_ld_lead_in\n');
  fprintf('  beta = %.16g, d = %.16g\n', beta, d);
  fprintf('  center cell = [%.16g, %.16g] x [%.16g, %.16g]\n', ...
    X_minus, X_plus, Y_minus, Y_plus);
  fprintf('  L_minus = %.16g, L_plus = %.16g\n', L_minus, L_plus);
  fprintf('  kext = %.16g%+.16gi\n', real(kext), imag(kext));
  fprintf('  n_0 = %.16g, n_minus = %.16g, n_plus = %.16g\n', ...
    n_0, n_minus, n_plus);
  fprintf('  geometry_0 = %s, geometry_minus = %s, geometry_plus = %s\n', ...
    flag_geom_0, flag_geom_minus, flag_geom_plus);
  fprintf('  ellipse axes center = [%.16g, %.16g]\n', ...
    ellipse_a_0, ellipse_b_0);
  fprintf('  ellipse axes minus = [%.16g, %.16g]\n', ...
    ellipse_a_minus, ellipse_b_minus);
  fprintf('  ellipse axes plus = [%.16g, %.16g]\n', ...
    ellipse_a_plus, ellipse_b_plus);
  fprintf('  ntot_0 = %d, ntot_minus = %d, ntot_plus = %d\n', ...
    ntot_0, ntot_minus, ntot_plus);
  fprintf('  M = %d, K = %d\n', M, K);
  fprintf('  incident_port = %s\n', incident_port);
  fprintf('  incident_mode_policy = %s\n', incident_mode_policy);
  fprintf('  incident_mode_index = %d\n', incident_mode_index);
  if ~isempty(lambda_in_active)
    fprintf('  lambda_incoming = %.16g%+.16gi\n', ...
      real(lambda_in_active), imag(lambda_in_active));
  end
  fprintf('  selected_out_minus.numSelected = %d\n', ...
    selected_out_minus.numSelected);
  fprintf('  selected_out_plus.numSelected = %d\n', ...
    selected_out_plus.numSelected);
  fprintf('  selected_in_minus.numSelected = %d\n', ...
    selected_in_minus.numSelected);
  fprintf('  selected_in_plus.numSelected = %d\n', ...
    selected_in_plus.numSelected);
  fprintf('  A_QP size = [%d, %d]\n', size(A_QP, 1), size(A_QP, 2));
  fprintf('  A_trmatch size = [%d, %d]\n', ...
    size(A_trmatch, 1), size(A_trmatch, 2));
  fprintf('  relative_residual = %.16e\n', diagnostics.relative_residual);
  fprintf('  bie_relative_residual = %.16e\n', ...
    diagnostics.bie_relative_residual);
  fprintf('  port_D_minus_relative_residual = %.16e\n', ...
    diagnostics.port_D_minus_relative_residual);
  fprintf('  port_N_minus_relative_residual = %.16e\n', ...
    diagnostics.port_N_minus_relative_residual);
  fprintf('  port_D_plus_relative_residual = %.16e\n', ...
    diagnostics.port_D_plus_relative_residual);
  fprintf('  port_N_plus_relative_residual = %.16e\n', ...
    diagnostics.port_N_plus_relative_residual);
  fprintf('  norm(eta) = %.16e\n', norm(eta));
  fprintf('  norm(c_plus) = %.16e\n', norm(c_plus));
  fprintf('  norm(c_minus) = %.16e\n', norm(c_minus));
  fprintf('  norm(a_s_minus) = %.16e\n', norm(a_s_minus));
  fprintf('  norm(a_s_plus) = %.16e\n', norm(a_s_plus));

  if do_plot_trace
    figure('Name', 'scat_ld_lead_in port trace magnitudes', 'Color', 'w');
    subplot(1, 2, 1);
    stem(rayleigh_center.m, abs(F_minus * eta), 'DisplayName', '|D_s^-|');
    hold on;
    stem(rayleigh_center.m, abs(F_plus * eta), 'DisplayName', '|D_s^+|');
    grid on;
    xlabel('Rayleigh index m');
    ylabel('magnitude');
    title('Center obstacle outgoing trace');
    legend('Location', 'best');
    subplot(1, 2, 2);
    stem(abs(a_s_minus), 'DisplayName', '|a_s^-|');
    hold on;
    stem(abs(a_s_plus), 'DisplayName', '|a_s^+|');
    grid on;
    xlabel('mode index');
    ylabel('magnitude');
    title('Outgoing lead coefficients');
    legend('Location', 'best');
  end

  % --- stage 8: draw exterior field contour plots ---

  if do_plot_solution
    plot_window.x_min = x_plot_min;
    plot_window.x_max = x_plot_max;
    plot_window.y_min = y_plot_min;
    plot_window.y_max = y_plot_max;
    plot_window.xlim = [x_plot_min, x_plot_max];
    plot_window.ylim = [y_plot_min, y_plot_max];
    plot_window.nx = nx_plot;
    plot_window.ny = ny_plot;
    plot_window.ncontour = ncontour;

    plot_geom = viz.build_col_lat_geom(plot_window, col_lat, col_lat_opts);
    tile_plan = LOCAL_build_tile_plan_ld(plot_window, plot_geom, col_lat, ...
      max([L_minus, L0, L_plus]), d);
    plot_state = LOCAL_build_plot_state(C0, curvelen_0, C_minus, ...
      curvelen_minus, C_plus, curvelen_plus, S_cell_minus, S_cell_plus, ...
      modes_minus, modes_plus, selected_out_minus, selected_out_plus, ...
      selected_in_minus, selected_in_plus, eta, c_plus, c_minus, ...
      a_s_minus, a_s_plus, p_in_minus, p_in_plus, X_minus, X_plus, ...
      X_L_minus, X_R_minus, X_L_plus, X_R_plus);

    LOCAL_draw_solution_tiles(tile_plan, plot_state, rayleigh_center, ...
      pars1, proxy, col_lat_opts, incident_port, lambda_in_active);
  end

end

%% ==================== Geometry helpers ====================
% These helpers build shifted obstacle contours in physical cell coordinates.

function geom_args = LOCAL_geom_args(flag_geom, a, b)
% LOCAL_GEOM_ARGS Return construct_cont varargin for supported defaults.

  if strcmp(flag_geom, 'circle')
    geom_args = {a};
  elseif strcmp(flag_geom, 'ellipse')
    geom_args = {a, b};
  else
    geom_args = {};
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [C, curvelen] = LOCAL_construct_shifted_cont(ntot, flag_geom, q, ...
    geom_args)
% LOCAL_CONSTRUCT_SHIFTED_CONT Construct and translate one obstacle boundary.

  if strcmp(flag_geom, 'none')
    error('scat_ld_lead_in:EmptyObstacleNotSupported', ...
      'Use scat_edc_lead_in for an empty center/lead obstacle cell.');
  end
  if nargin < 4
    geom_args = {};
  end
  [C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0, ...
    geom_args{:});
  q = q(:);
  if length(q) ~= 2 || any(~isfinite(q))
    error('scat_ld_lead_in:InvalidObstacleCenter', ...
      'Obstacle center q must be a finite two-entry vector.');
  end
  C(1, :) = C(1, :) + q(1);
  C(4, :) = C(4, :) + q(2);

end

%% ==================== Incoming trace and RHS helpers ====================
% These helpers select incoming Bloch trace bases and assemble rhs_in.

function [D_in, N_in, selected] = LOCAL_select_incoming_port_traces( ...
    modes, traces, portSign, opts)
% LOCAL_SELECT_INCOMING_PORT_TRACES Select incoming Bloch-mode port traces.
%
% Selection rule:
%   portSign='-': |lambda| < 1 - tol, using D_R and center outward -N_R.
%   portSign='+': |lambda| > 1 + tol, using D_L and center outward  N_L.

  if nargin < 4 || isempty(opts)
    opts = struct();
  end
  if ~isfield(opts, 'lambda_tol') || isempty(opts.lambda_tol)
    opts.lambda_tol = 1e-8;
  end
  if ~isfield(opts, 'policy') || isempty(opts.policy)
    opts.policy = 'least_decay';
  end

  lambda = modes.lambda(:);
  tol = opts.lambda_tol;
  abs_lambda = abs(lambda);

  switch portSign
    case '+'
      idx = abs_lambda > 1 + tol;
      D_raw = traces.D_L(:, idx);
      N_raw = traces.N_L(:, idx);
    case '-'
      idx = abs_lambda < 1 - tol;
      D_raw = traces.D_R(:, idx);
      N_raw = -traces.N_R(:, idx);
    otherwise
      error('scat_ld_lead_in:InvalidPortSign', ...
        'portSign must be either ''+'' or ''-''.');
  end

  idx_order = find(idx);
  lam_raw = lambda(idx_order);
  if any(idx) && strcmp(opts.policy, 'least_decay')
    [~, sort_idx] = sort(abs(abs(lam_raw) - 1), 'ascend');
    idx_order = idx_order(sort_idx);
    lam_raw = lam_raw(sort_idx);
    D_raw = D_raw(:, sort_idx);
    N_raw = N_raw(:, sort_idx);
  end

  selected.lambda = lam_raw;
  selected.idx = idx;
  selected.idx_order = idx_order(:);
  selected.numSelected = length(lam_raw);
  selected.portSign = portSign;
  selected.tol = tol;
  selected.policy = opts.policy;

  D_in = D_raw;
  N_in = N_raw;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rhs, p_in_minus, p_in_plus, lam_active] = LOCAL_construct_rhs_in( ...
    D_in_minus, N_in_minus, D_in_plus, N_in_plus, selected_in_minus, ...
    selected_in_plus, incident_port, mode_index, Nbie)
% LOCAL_CONSTRUCT_RHS_IN Build the coupled RHS from incoming trace bases.

  K = size(D_in_minus, 1);
  p_in_minus = zeros(size(D_in_minus, 2), 1);
  p_in_plus = zeros(size(D_in_plus, 2), 1);

  switch incident_port
    case '-'
      if mode_index < 1 || mode_index > selected_in_minus.numSelected
        error('scat_ld_lead_in:InvalidIncomingIndex', ...
          'incident_mode_index exceeds available negative-port incoming modes.');
      end
      p_in_minus(mode_index) = 1;
      lam_active = selected_in_minus.lambda(mode_index);
    case '+'
      if mode_index < 1 || mode_index > selected_in_plus.numSelected
        error('scat_ld_lead_in:InvalidIncomingIndex', ...
          'incident_mode_index exceeds available positive-port incoming modes.');
      end
      p_in_plus(mode_index) = 1;
      lam_active = selected_in_plus.lambda(mode_index);
    otherwise
      error('scat_ld_lead_in:InvalidIncidentPort', ...
        'incident_port must be either ''+'' or ''-''.');
  end

  rhs = [
    zeros(Nbie, 1);
    D_in_minus * p_in_minus;
    N_in_minus * p_in_minus;
    D_in_plus * p_in_plus;
    N_in_plus * p_in_plus
  ];

  if length(rhs) ~= Nbie + 4 * K
    error('scat_ld_lead_in:RhsSizeMismatch', ...
      'Unexpected rhs_in length.');
  end

end

%% ==================== Coupled matrix helpers ====================
% These helpers assemble center BIE and port trace matching blocks.

function [H_sigma_plus, H_sigma_minus] = LOCAL_construct_H_sigma(C0, ...
    rayleighchan, X_minus)
% LOCAL_CONSTRUCT_H_SIGMA Build center Rayleigh Cauchy data on Sigma.
%
% Formula:
%   H_sigma_plus is the Cauchy data of
%     exp(i*gamma_m*(x-X_minus))*psi_m(y),
%   and H_sigma_minus is the Cauchy data of
%     exp(-i*gamma_m*(x-X_minus))*psi_m(y).

  [H_sigma_plus, H_sigma_minus] = bloch.incident_rhs(C0, rayleighchan, ...
    X_minus, X_minus);
  H_sigma_plus = full(complex(H_sigma_plus));
  H_sigma_minus = full(complex(H_sigma_minus));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A_trmatch = LOCAL_construct_A_trmatch(A_QP, H_sigma_plus, ...
    H_sigma_minus, F_minus, F_plus, rayleighchan, D_out_minus, ...
    N_out_minus, D_out_plus, N_out_plus, X_minus, X_plus)
% LOCAL_CONSTRUCT_A_TRMATCH Assemble the linear-defect coupled matrix.
%
% Matrix formula:
%   With unknown = [eta; c^+; c^-; a_s^-; a_s^+],
%
%     A_trmatch =
%       [ A_QP, H^+, H^-, 0, 0;
%         F_-, I, I, -D_out^-, 0;
%         iG F_-, -iG, iG, -N_out^-, 0;
%         F_+, E, E_inv, 0, -D_out^+;
%         iG F_+, iG E, -iG E_inv, 0, -N_out^+ ].

  K = rayleighchan.K;
  gamma_m = rayleighchan.gamma_m(:);
  Gamma = diag(gamma_m);
  L0 = X_plus - X_minus;
  E = diag(exp(1i * gamma_m * L0));
  E_inv = diag(exp(-1i * gamma_m * L0));

  Nbie = size(A_QP, 1);
  if size(A_QP, 2) ~= Nbie
    error('scat_ld_lead_in:NonSquareAQP', ...
      'A_QP must be square.');
  end
  if ~isequal(size(H_sigma_plus), [Nbie, K]) || ...
      ~isequal(size(H_sigma_minus), [Nbie, K])
    error('scat_ld_lead_in:HSigmaSizeMismatch', ...
      'H_sigma_plus/minus must have size size(A_QP,1)-by-K.');
  end
  if ~isequal(size(F_minus), [K, Nbie]) || ~isequal(size(F_plus), [K, Nbie])
    error('scat_ld_lead_in:FarfieldSizeMismatch', ...
      'F_minus/F_plus must have size K-by-size(A_QP,1).');
  end

  K_out_minus = size(D_out_minus, 2);
  K_out_plus = size(D_out_plus, 2);
  I_K = eye(K);

  A_trmatch = [
    A_QP, H_sigma_plus, H_sigma_minus, zeros(Nbie, K_out_minus), ...
      zeros(Nbie, K_out_plus);
    F_minus, I_K, I_K, -D_out_minus, zeros(K, K_out_plus);
    1i * Gamma * F_minus, -1i * Gamma, 1i * Gamma, -N_out_minus, ...
      zeros(K, K_out_plus);
    F_plus, E, E_inv, zeros(K, K_out_minus), -D_out_plus;
    1i * Gamma * F_plus, 1i * Gamma * E, -1i * Gamma * E_inv, ...
      zeros(K, K_out_minus), -N_out_plus
  ];

end

%% ==================== Diagnostic helpers ====================
% These helpers report global, BIE-row, and port matching residuals.

function diagnostics = LOCAL_compute_diagnostics(A_trmatch, rhs_in, A_QP, ...
    H_sigma_plus, H_sigma_minus, F_minus, F_plus, rayleighchan, ...
    D_in_minus, N_in_minus, D_in_plus, N_in_plus, D_out_minus, ...
    N_out_minus, D_out_plus, N_out_plus, eta, c_plus, c_minus, ...
    a_s_minus, a_s_plus, p_in_minus, p_in_plus, X_minus, X_plus)
% LOCAL_COMPUTE_DIAGNOSTICS Compute residuals for the coupled system.

  gamma_m = rayleighchan.gamma_m(:);
  Gamma = diag(gamma_m);
  L0 = X_plus - X_minus;
  E = diag(exp(1i * gamma_m * L0));
  E_inv = diag(exp(-1i * gamma_m * L0));

  r_global = A_trmatch * [eta; c_plus; c_minus; a_s_minus; a_s_plus] - rhs_in;
  r_bie = A_QP * eta + H_sigma_plus * c_plus + H_sigma_minus * c_minus;

  r_D_minus = F_minus * eta + c_plus + c_minus - ...
    D_out_minus * a_s_minus - D_in_minus * p_in_minus;
  r_N_minus = 1i * Gamma * F_minus * eta - 1i * Gamma * c_plus + ...
    1i * Gamma * c_minus - N_out_minus * a_s_minus - ...
    N_in_minus * p_in_minus;
  r_D_plus = F_plus * eta + E * c_plus + E_inv * c_minus - ...
    D_out_plus * a_s_plus - D_in_plus * p_in_plus;
  r_N_plus = 1i * Gamma * F_plus * eta + 1i * Gamma * E * c_plus - ...
    1i * Gamma * E_inv * c_minus - N_out_plus * a_s_plus - ...
    N_in_plus * p_in_plus;

  diagnostics.relative_residual = norm(r_global) / max(1, norm(rhs_in));
  diagnostics.bie_relative_residual = norm(r_bie) / max(1, ...
    norm(A_QP * eta) + norm(H_sigma_plus * c_plus + H_sigma_minus * c_minus));
  diagnostics.port_D_minus_relative_residual = norm(r_D_minus) / max(1, ...
    norm(D_in_minus * p_in_minus));
  diagnostics.port_N_minus_relative_residual = norm(r_N_minus) / max(1, ...
    norm(N_in_minus * p_in_minus));
  diagnostics.port_D_plus_relative_residual = norm(r_D_plus) / max(1, ...
    norm(D_in_plus * p_in_plus));
  diagnostics.port_N_plus_relative_residual = norm(r_N_plus) / max(1, ...
    norm(N_in_plus * p_in_plus));

end

%% ==================== Plot state and tile setup helpers ====================
% These helpers collect reconstruction data and build reusable viz tile inputs.

function plot_state = LOCAL_build_plot_state(C0, curvelen_0, C_minus, ...
    curvelen_minus, C_plus, curvelen_plus, S_cell_minus, S_cell_plus, ...
    modes_minus, modes_plus, selected_out_minus, selected_out_plus, ...
    selected_in_minus, selected_in_plus, eta, c_plus, c_minus, ...
    a_s_minus, a_s_plus, p_in_minus, p_in_plus, X_minus, X_plus, ...
    X_L_minus, X_R_minus, X_L_plus, X_R_plus)
% LOCAL_BUILD_PLOT_STATE Collect data for exterior field reconstruction.

  plot_state.center = LOCAL_boundary_state(C0, curvelen_0);
  plot_state.center.eta = eta;
  plot_state.center.c_plus = c_plus;
  plot_state.center.c_minus = c_minus;
  plot_state.center.X_minus = X_minus;
  plot_state.center.X_plus = X_plus;

  plot_state.minus = LOCAL_lead_plot_state(C_minus, curvelen_minus, ...
    S_cell_minus, modes_minus, selected_out_minus, selected_in_minus, ...
    a_s_minus, p_in_minus, X_L_minus, X_R_minus);
  plot_state.plus = LOCAL_lead_plot_state(C_plus, curvelen_plus, ...
    S_cell_plus, modes_plus, selected_out_plus, selected_in_plus, ...
    a_s_plus, p_in_plus, X_L_plus, X_R_plus);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function state = LOCAL_boundary_state(C, curvelen)
% LOCAL_BOUNDARY_STATE Extract boundary quadrature data.

  Nbd = size(C, 2);
  x_bd = C(1, :).';
  y_bd = C(4, :).';
  dxdt = C(2, :).';
  dydt = C(5, :).';
  speed = sqrt(dxdt.^2 + dydt.^2);

  state.src = [x_bd.'; y_bd.'];
  state.nx = dydt ./ speed;
  state.ny = -dxdt ./ speed;
  state.weights = (curvelen / Nbd) * speed;
  state.Nbd = Nbd;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function state = LOCAL_lead_plot_state(C, curvelen, S_cell, modes, ...
    selected_out, selected_in, a_s, p_in, X_L, X_R)
% LOCAL_LEAD_PLOT_STATE Collect one half-lead field reconstruction state.

  state = LOCAL_boundary_state(C, curvelen);
  state.H_L = S_cell.H_L;
  state.H_R = S_cell.H_R;
  state.X_L = X_L;
  state.X_R = X_R;
  state.L = X_R - X_L;

  idx_out = selected_out.idx;
  state.out.a_L = modes.a_L(:, idx_out);
  state.out.b_R = modes.b_R(:, idx_out);
  state.out.lambda = modes.lambda(idx_out);
  state.out.coeff = a_s;

  idx_in = selected_in.idx_order;
  state.in.a_L = modes.a_L(:, idx_in);
  state.in.b_R = modes.b_R(:, idx_in);
  state.in.lambda = modes.lambda(idx_in);
  state.in.coeff = p_in;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tile_plan = LOCAL_build_tile_plan_ld(plot_window, plot_geom, col_lat, ...
    L_ref, d)
% LOCAL_BUILD_TILE_PLAN_LD Build reusable tile grids and masks.

  ncell_x = max(1, ceil((plot_window.x_max - plot_window.x_min) / L_ref));
  ncell_y = max(1, ceil((plot_window.y_max - plot_window.y_min) / d));
  ngridx = max(8, ceil(plot_window.nx / ncell_x));
  ngridy = max(8, ceil(plot_window.ny / ncell_y));

  grid_spec.ngridx = ngridx;
  grid_spec.ngridy = ngridy;
  grid_spec.x_frac = [0, 1];
  grid_spec.y_frac = [0, 1];

  [ref_grid.left.X, ref_grid.left.Y] = viz.cell_grid(plot_geom.Cminus, ...
    grid_spec);
  [ref_grid.center.X, ref_grid.center.Y] = viz.cell_grid(plot_geom.C0, ...
    grid_spec);
  [ref_grid.right.X, ref_grid.right.Y] = viz.cell_grid(plot_geom.Cplus, ...
    grid_spec);

  left_args = LOCAL_region_geom_args(col_lat.left);
  center_args = LOCAL_region_geom_args(col_lat.center);
  right_args = LOCAL_region_geom_args(col_lat.right);

  ref_mask.left = viz.obstacle_mask(ref_grid.left.X, ref_grid.left.Y, ...
    col_lat.left.flag_geom, col_lat.left.q, struct(), left_args{:});
  ref_mask.center = viz.obstacle_mask(ref_grid.center.X, ...
    ref_grid.center.Y, col_lat.center.flag_geom, col_lat.center.q, ...
    struct(), center_args{:});
  ref_mask.right = viz.obstacle_mask(ref_grid.right.X, ref_grid.right.Y, ...
    col_lat.right.flag_geom, col_lat.right.q, struct(), right_args{:});

  tile_plan = viz.build_col_lat_tiles(plot_geom, ref_grid, ref_mask);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function geom_args = LOCAL_region_geom_args(region)
% LOCAL_REGION_GEOM_ARGS Return optional geometry parameters as a cell array.

  if isfield(region, 'geom_args') && ~isempty(region.geom_args)
    geom_args = region.geom_args;
    if ~iscell(geom_args)
      geom_args = {geom_args};
    end
  else
    geom_args = {};
  end

end

%% ==================== Field evaluation helpers ====================
% These helpers evaluate the exterior field on arbitrary tile grids.

function U = LOCAL_eval_field_points(X, Y, plot_state, rayleighchan, pars1, ...
    proxy)
% LOCAL_EVAL_FIELD_POINTS Evaluate the total exterior field.

  x_vec = X(:);
  y_vec = Y(:);

  [y_base, y_phase] = LOCAL_apply_y_quasiperiodic_shift(y_vec, ...
    rayleighchan.beta, rayleighchan.d);

  X_minus = plot_state.center.X_minus;
  X_plus = plot_state.center.X_plus;
  idx_center = x_vec >= X_minus & x_vec <= X_plus;
  idx_minus = x_vec < X_minus;
  idx_plus = x_vec > X_plus;

  u_vec = NaN(size(x_vec));
  if any(idx_center)
    u_vec(idx_center) = y_phase(idx_center) .* ...
      LOCAL_eval_center_exterior(x_vec(idx_center), y_base(idx_center), ...
      plot_state.center, rayleighchan, pars1, proxy);
  end
  if any(idx_minus)
    u_vec(idx_minus) = y_phase(idx_minus) .* LOCAL_eval_lead_field( ...
      x_vec(idx_minus), y_base(idx_minus), plot_state.minus, ...
      rayleighchan, pars1, proxy, '-');
  end
  if any(idx_plus)
    u_vec(idx_plus) = y_phase(idx_plus) .* LOCAL_eval_lead_field( ...
      x_vec(idx_plus), y_base(idx_plus), plot_state.plus, ...
      rayleighchan, pars1, proxy, '+');
  end

  U = reshape(u_vec, size(X));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [y_base, phase] = LOCAL_apply_y_quasiperiodic_shift(y, beta, d)
% LOCAL_APPLY_Y_QUASIPERIODIC_SHIFT Fold y and return Bloch phase factors.

  n_shift = floor((y + d / 2) / d);
  y_base = y - n_shift * d;
  phase = exp(1i * beta * n_shift * d);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_center_exterior(x, y_base, center_state, rayleighchan, ...
    pars1, proxy)
% LOCAL_EVAL_CENTER_EXTERIOR Evaluate u_h plus exterior layer potential.

  x = x(:);
  y_base = y_base(:);
  beta_m = rayleighchan.beta_m(:);
  gamma_m = rayleighchan.gamma_m(:);
  d = rayleighchan.d;
  X_minus = center_state.X_minus;

  psi = exp(1i * beta_m * y_base.') / sqrt(d);
  phase_plus = exp(1i * gamma_m * (x.' - X_minus));
  phase_minus = exp(-1i * gamma_m * (x.' - X_minus));
  coeff = center_state.c_plus .* phase_plus + ...
    center_state.c_minus .* phase_minus;
  u_h = sum(coeff .* psi, 1).';

  u_s = LOCAL_eval_layer_potential(x, y_base, center_state, pars1, proxy, ...
    center_state.eta);
  u = u_h + u_s;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_lead_field(x, y_base, lead_state, rayleighchan, ...
    pars1, proxy, portSign)
% LOCAL_EVAL_LEAD_FIELD Evaluate incoming + outgoing field in one half-lead.

  x = x(:);
  y_base = y_base(:);
  u = zeros(size(x));
  L = lead_state.L;

  switch portSign
    case '+'
      distance = x - lead_state.X_L;
      cell_index = floor(distance / L);
      x_ref = lead_state.X_L + (distance - cell_index * L);
      factor_fun = @(lambda, q) lambda .^ q;
    case '-'
      distance = lead_state.X_R - x;
      cell_index = floor(distance / L);
      x_ref = lead_state.X_R - (distance - cell_index * L);
      factor_fun = @(lambda, q) lambda .^ (-q);
    otherwise
      error('scat_ld_lead_in:InvalidPortSign', ...
        'portSign must be either ''+'' or ''-''.');
  end

  unique_cells = unique(cell_index(:)).';
  for q = unique_cells
    idx = cell_index == q;
    has_out = ~isempty(lead_state.out.coeff) && any(lead_state.out.coeff(:));
    has_in = ~isempty(lead_state.in.coeff) && any(lead_state.in.coeff(:));
    a_L_total = zeros(size(lead_state.H_L, 2), 1);
    b_R_total = zeros(size(lead_state.H_R, 2), 1);

    if has_out
      mode_factor = factor_fun(lead_state.out.lambda(:), q);
      coeff_q = lead_state.out.coeff(:) .* mode_factor;
      a_L_total = lead_state.out.a_L * coeff_q;
      b_R_total = lead_state.out.b_R * coeff_q;
    end
    if has_in
      mode_factor_in = factor_fun(lead_state.in.lambda(:), q);
      coeff_in_q = lead_state.in.coeff(:) .* mode_factor_in;
      a_L_total = a_L_total + lead_state.in.a_L * coeff_in_q;
      b_R_total = b_R_total + lead_state.in.b_R * coeff_in_q;
    end
    if ~has_out && ~has_in
      continue;
    end
    u(idx) = LOCAL_eval_single_cell_total_field(x_ref(idx), y_base(idx), ...
      a_L_total, b_R_total, lead_state, rayleighchan, pars1, proxy);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_single_cell_total_field(x_ref, y_base, a_L, b_R, ...
    lead_state, rayleighchan, pars1, proxy)
% LOCAL_EVAL_SINGLE_CELL_TOTAL_FIELD Evaluate one lead reference cell field.

  x_ref = x_ref(:);
  y_base = y_base(:);
  gamma_m = rayleighchan.gamma_m(:);
  beta_m = rayleighchan.beta_m(:);
  d = rayleighchan.d;

  psi = exp(1i * beta_m * y_base.') / sqrt(d);
  U_L = exp(1i * gamma_m * (x_ref.' - lead_state.X_L)) .* psi;
  U_R = exp(-1i * gamma_m * (x_ref.' - lead_state.X_R)) .* psi;
  u_inc = (a_L.' * U_L + b_R.' * U_R).';

  eta_cell = lead_state.H_L * a_L + lead_state.H_R * b_R;
  u_s = LOCAL_eval_layer_potential(x_ref, y_base, lead_state, pars1, proxy, ...
    eta_cell);
  u = u_inc + u_s;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_layer_potential(x, y, state, pars1, proxy, eta)
% LOCAL_EVAL_LAYER_POTENTIAL Evaluate exterior layer potential from eta.

  tau = eta(1:state.Nbd);
  mu = eta(state.Nbd + 1:2 * state.Nbd);
  tau_w = tau .* state.weights;
  mu_w = mu .* state.weights;

  trg = [x(:).'; y(:).'];
  [pot, gradx, grady] = kernel.qpgreen_mfs_pairmat(state.src, trg, ...
    pars1, proxy);
  dGdnu = -bsxfun(@times, gradx, state.nx.') - ...
    bsxfun(@times, grady, state.ny.');
  u = dGdnu * tau_w - pot * mu_w;

end

%% ==================== Tile contour drawing helpers ====================
% These helpers draw real, imaginary, and magnitude contours from tile data.

function LOCAL_draw_solution_tiles(tile_plan, plot_state, rayleighchan, pars1, ...
    proxy, col_lat_opts, incident_port, lam_active)
% LOCAL_DRAW_SOLUTION_TILES Draw tile-wise exterior field contours.

  tile_data = LOCAL_evaluate_solution_tiles(tile_plan, plot_state, ...
    rayleighchan, pars1, proxy);

  figure('Name', 'scat_ld_lead_in exterior field: real/imag', 'Color', 'w');

  subplot(1, 2, 1);
  LOCAL_draw_tile_contour_axes(gca, tile_data, tile_plan, 'real', ...
    sprintf('real exterior field  incident %s, |\\lambda_{in}|=%.4f', ...
    incident_port, abs(lam_active)), col_lat_opts);

  subplot(1, 2, 2);
  LOCAL_draw_tile_contour_axes(gca, tile_data, tile_plan, 'imag', ...
    sprintf('imag exterior field  incident %s, |\\lambda_{in}|=%.4f', ...
    incident_port, abs(lam_active)), col_lat_opts);

  figure('Name', 'scat_ld_lead_in exterior field: abs', 'Color', 'w');
  LOCAL_draw_tile_contour_axes(gca, tile_data, tile_plan, 'abs', ...
    sprintf('abs exterior field  incident %s, |\\lambda_{in}|=%.4f', ...
    incident_port, abs(lam_active)), col_lat_opts);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tile_data = LOCAL_evaluate_solution_tiles(tile_plan, plot_state, ...
    rayleighchan, pars1, proxy)
% LOCAL_EVALUATE_SOLUTION_TILES Evaluate and mask each visible tile.

  tile_data = struct('X', {}, 'Y', {}, 'real', {}, 'imag', {}, 'abs', {});
  for k = 1:numel(tile_plan.cells)
    tile = tile_plan.cells(k);
    r = tile.ref_name;
    Xcell = tile_plan.ref_grid.(r).X + tile.dx;
    Ycell = tile_plan.ref_grid.(r).Y + tile.dy;
    Ucell = LOCAL_eval_field_points(Xcell, Ycell, plot_state, ...
      rayleighchan, pars1, proxy);

    Ucell(tile_plan.ref_mask.(r)) = NaN + 1i * NaN;
    value_mask = isnan(real(Ucell)) | isnan(imag(Ucell));

    U_real = real(Ucell);
    U_imag = imag(Ucell);
    U_abs = abs(Ucell);
    U_real(value_mask) = NaN;
    U_imag(value_mask) = NaN;
    U_abs(value_mask) = NaN;

    tile_data(k).X = Xcell; %#ok<AGROW>
    tile_data(k).Y = Ycell; %#ok<AGROW>
    tile_data(k).real = U_real; %#ok<AGROW>
    tile_data(k).imag = U_imag; %#ok<AGROW>
    tile_data(k).abs = U_abs; %#ok<AGROW>
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_draw_tile_contour_axes(ax, tile_data, tile_plan, value_kind, ...
    title_text, col_lat_opts)
% LOCAL_DRAW_TILE_CONTOUR_AXES Draw one real/imag/abs tile contour axes.

  vals = [];
  for k = 1:numel(tile_data)
    Z = tile_data(k).(value_kind);
    vals = [vals; Z(isfinite(Z))]; %#ok<AGROW>
  end
  if isempty(vals)
    levels = linspace(0, 1, max(2, tile_plan.window.ncontour));
  else
    vmin = min(vals);
    vmax = max(vals);
    if vmin == vmax
      span = max(1, abs(vmin));
      vmin = vmin - 1e-6 * span;
      vmax = vmax + 1e-6 * span;
    end
    levels = linspace(vmin, vmax, max(2, tile_plan.window.ncontour));
  end

  hold_was_on = ishold(ax);
  hold(ax, 'on');
  for k = 1:numel(tile_data)
    contourf(ax, tile_data(k).X, tile_data(k).Y, ...
      tile_data(k).(value_kind), levels, 'LineColor', 'none');
  end
  if numel(levels) >= 2
    caxis(ax, [levels(1), levels(end)]);
  end
  colorbar;
  title(title_text);
  viz.overlay_col_lat_geom(ax, tile_plan, col_lat_opts);
  if ~hold_was_on
    hold(ax, 'off');
  end

end
