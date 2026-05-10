function scat_edc_lead_in()
% Purpose:
%   Solve an empty-defect forced scattering problem driven by an incoming
%   Bloch mode from one half-lead.  The center cell is homogeneous background
%   medium, and the two half-leads are identical periodic arrays of dielectric
%   cylinders.  The unknown scattered response is captured through outgoing
%   Bloch trace spaces, together with the center-cell homogeneous Rayleigh
%   expansion.
%
% Mathematical problem:
%   The center empty cell occupies X0_minus <= x <= X0_plus and is expanded
%   in the y-quasiperiodic Rayleigh basis.  This is a scattering / forced
%   problem, not a TEP and not a homogeneous cavity eigenproblem.  The center
%   field is
%
%     u_0 = u_h,
%
%   where u_h is a homogeneous Rayleigh expansion in the empty center cell.
%
% Unknown vector:
%   The unknown is
%
%     unknown = [c^+; c^-; a_s^-; a_s^+].
%
%   The coefficients c^+ and c^- are center-cavity Rayleigh right-going and
%   left-going coefficients.  The coefficients a_s^- and a_s^+ multiply
%   outgoing Bloch trace bases in the negative and positive half-leads.
%
% Matrix formula:
%   Let K = 2*M + 1, Gamma = diag(gamma_m),
%
%     E = diag(exp(1i*gamma_m*L0)),  E_inv = diag(exp(-1i*gamma_m*L0)),
%     L0 = X0_plus - X0_minus.
%
%   The trace-matching system is
%
%     A_trmatch * unknown = rhs_in,
%
%   where
%
%     A_trmatch =
%       [ I,            I,             -D_out^-,   0;
%        -1i*Gamma,    1i*Gamma,      -N_out^-,   0;
%         E,           E_inv,          0,         -D_out^+;
%         1i*Gamma*E, -1i*Gamma*E_inv, 0,         -N_out^+ ].
%
%   If incident_port = '-', then
%
%     rhs_in = [D_in^- p_in^-; N_in^- p_in^-; zeros(K,1); zeros(K,1)].
%
%   If incident_port = '+', the roles are swapped.
%
% Expected check:
%   For a well-conditioned solve, the reported relative residual
%   norm(A_trmatch*unknown - rhs_in) / max(1, norm(rhs_in)) should be small.

  format long;

  % --- stage 1: set user parameters ---

  % y-quasiperiodic parameter and y-period used by the Rayleigh basis.
  beta = 0.4;
  d = 2 * pi;

  % x-period of one lead cell and the matching-port coordinates for the empty
  % center defect cell.
  L = 2.0;
  X0_minus = -L / 2;
  X0_plus = L / 2;

  % Exterior/background wavenumber.  eps_k adds a small absorption that avoids
  % real-axis degeneracies in this prototype scattering calculation.
  k_real = 1.3;
  eps_k = 1e-4;
  kext = k_real + 1i * eps_k;

  % Refractive-index ratio for the dielectric cylinders in each lead cell.
  % The center defect cell itself is empty and uses only kext.
  n = 1.5;
  kint = n * kext;

  % Boundary discretization and geometry selector for each periodic lead
  % cylinder.  radius is passed to geom.construct_cont for circle geometry.
  ntot = 40;
  flag_geom = 'circle';
  radius = 0.3;

  % Rayleigh truncation half-width.  M = 3 gives K = 7.
  M = 3;

  % Proxy-source parameters used by kernel.precomp_proxy for the lead-cell
  % quasi-periodic Green representation.
  pars1.k = kext;
  pars1.beta = beta;
  pars1.d = d;
  pars1.periodic_axis = 'y';
  pars2.H = L / 2 + radius + 0.4;
  pars2.proxy_dist = 0.7;
  pars2.N_side = 40;
  pars2.N_top = 40;
  pars2.N_proxy_edge = 24;
  pars2.M_pw = 8;

  % Mode-selection tolerance for outgoing half-lead trace spaces.
  opts.lambda_tol = 1e-8;

  % Incoming port selection.  incident_port controls whether the incident
  % Bloch mode enters from the negative half-lead ('-') or the positive
  % half-lead ('+').
  incident_port = '-';

  % incident_mode_policy selects which incoming Bloch mode to use:
  %   'least_decay' — sort by abs(abs(lambda)-1) ascending, pick the
  %     incident_mode_index-th mode (default 1 = least decaying).
  % incident_mode_index picks which mode in the sorted list.
  incident_mode_policy = 'least_decay';
  incident_mode_index = 1;

  % Optional trace-magnitude plot for the incoming and outgoing traces.
  do_plot_trace = false;

  % Solution contour plotting controls.  The plotted field is the total
  % exterior field: u_h in the empty center cell, and the incoming +
  % outgoing Bloch response in the two leads.  Interior cylinder fields are
  % not reconstructed and are masked in plots.
  do_plot_solution = true;
  x_plot_min = -5.0;
  x_plot_max = 5.0;
  y_plot_min = -2 * d;
  y_plot_max = 2 * d;
  nx_plot = 100;
  ny_plot = 90;
  ncontour = 40;

  % Column-lattice decoration controls.  The reference y cell is centered
  % around zero because field evaluation folds y into [-d/2,d/2).
  col_lat.C0 = [X0_minus, X0_plus; -d / 2, d / 2];
  col_lat.left.Lx = L;
  col_lat.left.flag_geom = flag_geom;
  col_lat.left.q = [X0_minus - L / 2; 0];
  col_lat.left.geom_args = {radius};
  col_lat.center.flag_geom = 'none';
  col_lat.center.q = [0; 0];
  col_lat.right.Lx = L;
  col_lat.right.flag_geom = flag_geom;
  col_lat.right.q = [X0_plus + L / 2; 0];
  col_lat.right.geom_args = {radius};

  col_lat_opts.nt_contour = 160;
  col_lat_opts.cell_lines = 'center';
  col_lat_opts.contour_line_spec = 'k-';
  col_lat_opts.contour_line_width = 0.9;
  col_lat_opts.cell_line_spec = 'k--';
  col_lat_opts.cell_line_width = 1.1;
  col_lat_opts.apply_axis_format = true;

  % --- stage 2: build lead geometry, proxy, and Bloch modes ---

  [C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0, radius);
  proxy = kernel.precomp_proxy(pars1, pars2);

  rayleighchan = bloch.rayleigh_channels(kext, beta, d, M, L);
  K = rayleighchan.K;

  S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
    rayleighchan, X0_minus, X0_plus);
  modes = bloch.solve_modes(S_cell);
  traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);

  % --- stage 3: select incoming and outgoing port trace spaces ---

  [D_out_plus, N_out_plus, selected_plus] = ...
    bloch.select_port_traces(modes, traces, '+', opts);
  [D_out_minus, N_out_minus, selected_minus] = ...
    bloch.select_port_traces(modes, traces, '-', opts);

  K_out_minus = selected_minus.numSelected;
  K_out_plus = selected_plus.numSelected;

  if K_out_minus == 0 || K_out_plus == 0
    warning('scat_edc_lead_in:NoOutgoingModes', ...
      'At least one outgoing port trace space is empty.');
  end
  if K_out_minus ~= K || K_out_plus ~= K
    warning('scat_edc_lead_in:UnexpectedModeCount', ...
      'Selected outgoing mode counts [%d,%d] differ from K = %d.', ...
      K_out_minus, K_out_plus, K);
  end

  in_opts.lambda_tol = opts.lambda_tol;
  in_opts.policy = incident_mode_policy;
  in_opts.mode_index = incident_mode_index;
  [D_in_minus, N_in_minus, selected_in_minus] = ...
    LOCAL_select_incoming_port_traces(modes, traces, '-', in_opts);
  [D_in_plus, N_in_plus, selected_in_plus] = ...
    LOCAL_select_incoming_port_traces(modes, traces, '+', in_opts);

  % --- stage 4: assemble trace-matching system ---

  A_trmatch = LOCAL_construct_A_trmatch(rayleighchan, D_out_minus, ...
    N_out_minus, D_out_plus, N_out_plus, X0_minus, X0_plus);

  expected_size = [4 * K, 2 * K + K_out_minus + K_out_plus];
  if ~isequal(size(A_trmatch), expected_size)
    warning('scat_edc_lead_in:UnexpectedMatrixSize', ...
      'A_trmatch size is [%d,%d], expected [%d,%d].', ...
      size(A_trmatch, 1), size(A_trmatch, 2), ...
      expected_size(1), expected_size(2));
  end
  if size(A_trmatch, 1) ~= size(A_trmatch, 2)
    warning('scat_edc_lead_in:RectangularSystem', ...
      'A_trmatch is rectangular; MATLAB/Octave backslash returns a least-squares solution.');
  end

  [rhs_in, p_in_active, lambda_in_active] = LOCAL_construct_rhs_in( ...
    D_in_minus, N_in_minus, D_in_plus, N_in_plus, ...
    selected_in_minus, selected_in_plus, incident_port, ...
    incident_mode_policy, incident_mode_index);

  % --- stage 5: solve forced scattering system ---

  sol = A_trmatch \ rhs_in;

  c_plus = sol(1:K);
  c_minus = sol(K + 1:2 * K);
  a_s_minus = sol(2 * K + 1:2 * K + K_out_minus);
  a_s_plus = sol(2 * K + K_out_minus + 1:end);

  res_vec = A_trmatch * sol - rhs_in;
  relative_residual = norm(res_vec) / max(1, norm(rhs_in));

  % --- stage 6: report diagnostics ---

  fprintf('scat_edc_lead_in\n');
  fprintf('  beta = %.16g, d = %.16g, L = %.16g\n', beta, d, L);
  fprintf('  kext = %.16g%+.16gi, n = %.16g\n', real(kext), imag(kext), n);
  fprintf('  ntot = %d, geometry = %s, radius = %.16g\n', ...
    ntot, flag_geom, radius);
  fprintf('  M = %d, K = %d\n', M, K);
  fprintf('  incident_port = %s\n', incident_port);
  fprintf('  incident_mode_policy = %s\n', incident_mode_policy);
  fprintf('  incident_mode_index = %d\n', incident_mode_index);
  if ~isempty(lambda_in_active)
    fprintf('  lambda_incoming = %.16g%+.16gi\n', ...
      real(lambda_in_active), imag(lambda_in_active));
  end
  fprintf('  selected_minus.numSelected = %d\n', selected_minus.numSelected);
  fprintf('  selected_plus.numSelected = %d\n', selected_plus.numSelected);
  fprintf('  selected_in_minus.numSelected = %d\n', ...
    selected_in_minus.numSelected);
  fprintf('  selected_in_plus.numSelected = %d\n', ...
    selected_in_plus.numSelected);
  fprintf('  A_trmatch size = [%d, %d]\n', size(A_trmatch, 1), size(A_trmatch, 2));
  fprintf('  relative_residual = %.16e\n', relative_residual);
  fprintf('  norm(c_plus) = %.16e\n', norm(c_plus));
  fprintf('  norm(c_minus) = %.16e\n', norm(c_minus));
  fprintf('  norm(a_s_minus) = %.16e\n', norm(a_s_minus));
  fprintf('  norm(a_s_plus) = %.16e\n', norm(a_s_plus));

  if do_plot_trace
    figure('Name', 'Incoming/outgoing trace coefficients', 'Color', 'w');
    subplot(2, 1, 1);
    stem(rayleighchan.m, abs(D_in_plus), 'DisplayName', '|D_{in}^+|'); hold on;
    stem(rayleighchan.m, abs(N_in_plus), 'DisplayName', '|N_{in}^+|');
    title('Positive port: incoming trace');
    xlabel('Rayleigh index m'); ylabel('magnitude');
    legend('Location', 'best'); grid on;
    subplot(2, 1, 2);
    stem(rayleighchan.m, abs(D_out_plus), 'DisplayName', '|D_{out}^+|'); hold on;
    stem(rayleighchan.m, abs(N_out_plus), 'DisplayName', '|N_{out}^+|');
    title('Positive port: outgoing trace');
    xlabel('Rayleigh index m'); ylabel('magnitude');
    legend('Location', 'best'); grid on;
  end

  % --- stage 7: evaluate field on plotting window ---

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

    plot_state = LOCAL_build_plot_state_in(C, curvelen, S_cell, modes, ...
      selected_minus, selected_plus, a_s_minus, a_s_plus, ...
      selected_in_minus, selected_in_plus, p_in_active, ...
      c_plus, c_minus, incident_port, X0_minus);

    tile_plan = LOCAL_build_tile_plan_in(plot_window, plot_geom, col_lat, L, d);

    % --- stage 8: draw contour plots ---

    LOCAL_draw_solution_tiles_in(tile_plan, plot_state, rayleighchan, ...
      pars1, proxy, X0_minus, X0_plus, col_lat_opts, incident_port, ...
      lambda_in_active);
  end

end

%% ==================== Incoming trace and RHS helpers ====================
% These helpers select incoming Bloch trace bases and assemble rhs_in.

function [D_in, N_in, selected] = LOCAL_select_incoming_port_traces( ...
    modes, traces, portSign, opts)
% LOCAL_SELECT_INCOMING_PORT_TRACES Select incoming Bloch-mode port traces.
%
% Purpose:
%   Select the incoming Bloch-mode Dirichlet and outward-normal trace
%   matrices for a given center defect port.  This is the inverse of
%   bloch.select_port_traces: it picks modes that are incoming toward the
%   center cell.
%
% Selection rule:
%   portSign='-': |lambda| < 1 - tol  (wave enters from left)
%      D_in = D_R(:,idx),  N_in = -N_R(:,idx)
%   portSign='+': |lambda| > 1 + tol  (wave enters from right)
%      D_in = D_L(:,idx),  N_in =  N_L(:,idx)
%
% Sorting:
%   If opts.policy='least_decay', modes are sorted by abs(abs(lambda)-1)
%   ascending so that the least evanescent (most propagating) modes come
%   first.

  if nargin < 4 || isempty(opts)
    opts = struct();
  end
  if ~isfield(opts, 'lambda_tol') || isempty(opts.lambda_tol)
    opts.lambda_tol = 1e-8;
  end
  if ~isfield(opts, 'policy') || isempty(opts.policy)
    opts.policy = 'least_decay';
  end
  if ~isfield(opts, 'mode_index') || isempty(opts.mode_index)
    opts.mode_index = 1;
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
      error('scat_edc_lead_in:InvalidPortSign', ...
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

  n_selected = length(lam_raw);
  selected.lambda = lam_raw;
  selected.idx = idx;
  selected.idx_order = idx_order(:);
  selected.numSelected = n_selected;
  selected.portSign = portSign;
  selected.tol = tol;
  selected.policy = opts.policy;

  D_in = D_raw;
  N_in = N_raw;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rhs, p_in, lam_active] = LOCAL_construct_rhs_in(D_in_minus, ...
    N_in_minus, D_in_plus, N_in_plus, selected_in_minus, ...
    selected_in_plus, incident_port, policy, mode_index)
% LOCAL_CONSTRUCT_RHS_IN Build the RHS from incoming trace bases.
%
% Purpose:
%   Construct the right-hand side vector rhs_in for the empty-defect
%   scattering system driven by a single incoming Bloch mode.

  if isempty(selected_in_minus.lambda) && isempty(selected_in_plus.lambda)
    error('scat_edc_lead_in:NoIncomingModes', ...
      'No incoming modes available on either port.');
  end

  K = size(D_in_minus, 1);

  switch incident_port
    case '-'
      if selected_in_minus.numSelected == 0
        error('scat_edc_lead_in:NoIncomingMinus', ...
          'No incoming modes available on the negative port.');
      end
      n_in_minus = selected_in_minus.numSelected;
      if mode_index < 1 || mode_index > n_in_minus
        error('scat_edc_lead_in:InvalidIncomingIndex', ...
          'incident_mode_index = %d exceeds available incoming modes (%d).', ...
          mode_index, n_in_minus);
      end
      p_in = zeros(size(D_in_minus, 2), 1);
      p_in(mode_index) = 1;
      lam_active = selected_in_minus.lambda(mode_index);
      rhs = [D_in_minus * p_in; N_in_minus * p_in; ...
        zeros(K, 1); zeros(K, 1)];

    case '+'
      if selected_in_plus.numSelected == 0
        error('scat_edc_lead_in:NoIncomingPlus', ...
          'No incoming modes available on the positive port.');
      end
      n_in_plus = selected_in_plus.numSelected;
      if mode_index < 1 || mode_index > n_in_plus
        error('scat_edc_lead_in:InvalidIncomingIndex', ...
          'incident_mode_index = %d exceeds available incoming modes (%d).', ...
          mode_index, n_in_plus);
      end
      p_in = zeros(size(D_in_plus, 2), 1);
      p_in(mode_index) = 1;
      lam_active = selected_in_plus.lambda(mode_index);
      rhs = [zeros(K, 1); zeros(K, 1); ...
        D_in_plus * p_in; N_in_plus * p_in];

    otherwise
      error('scat_edc_lead_in:InvalidIncidentPort', ...
        'incident_port must be either ''+'' or ''-''.');
  end

end

%% ==================== Trace-matching matrix helper ====================
% This helper builds the empty-defect block matrix used by the solve.

function A_trmatch = LOCAL_construct_A_trmatch(rayleighchan, D_out_minus, ...
    N_out_minus, D_out_plus, N_out_plus, X0_minus, X0_plus)
% LOCAL_CONSTRUCT_A_TRMATCH Assemble the empty-defect trace-matching matrix.
%
% Purpose:
%   Build the linear map for the forced empty-defect scattering unknown
%   unknown = [c^+; c^-; a^-; a^+].
%
% Matrix formula:
%   For L0 = X0_plus - X0_minus,
%
%     E = diag(exp(1i*gamma_m*L0)),
%     E_inv = diag(exp(-1i*gamma_m*L0)),
%     Gamma = diag(gamma_m).
%
%   The center homogeneous traces are
%
%     D_h^- = c^+ + c^-,
%     N_h^- = -1i*Gamma*(c^+ - c^-),
%     D_h^+ = E*c^+ + E_inv*c^-,
%     N_h^+ = 1i*Gamma*(E*c^+ - E_inv*c^-).
%
%   Matching to outgoing Bloch trace spaces gives
%
%     A_trmatch =
%       [ I,            I,             -D_out_minus,   0;
%        -1i*Gamma,    1i*Gamma,      -N_out_minus,   0;
%         E,           E_inv,          0,             -D_out_plus;
%         1i*Gamma*E, -1i*Gamma*E_inv, 0,             -N_out_plus ].

  K = rayleighchan.K;
  gamma_m = rayleighchan.gamma_m(:);
  L0 = X0_plus - X0_minus;

  K_out_minus = size(D_out_minus, 2);
  K_out_plus = size(D_out_plus, 2);

  if size(D_out_minus, 1) ~= K || size(N_out_minus, 1) ~= K || ...
      size(D_out_plus, 1) ~= K || size(N_out_plus, 1) ~= K
    error('scat_edc_lead_in:TraceRowMismatch', ...
      'Outgoing trace matrices must have K rows.');
  end
  if size(N_out_minus, 2) ~= K_out_minus || ...
      size(N_out_plus, 2) ~= K_out_plus
    error('scat_edc_lead_in:TraceColumnMismatch', ...
      'D_out and N_out matrices must have matching column counts.');
  end

  Gamma = diag(gamma_m);
  E = diag(exp(1i * gamma_m * L0));
  E_inv = diag(exp(-1i * gamma_m * L0));
  I_K = eye(K);
  Z_minus = zeros(K, K_out_minus);
  Z_plus = zeros(K, K_out_plus);

  A_trmatch = [
    I_K, I_K, -D_out_minus, Z_plus;
    -1i * Gamma, 1i * Gamma, -N_out_minus, Z_plus;
    E, E_inv, Z_minus, -D_out_plus;
    1i * Gamma * E, -1i * Gamma * E_inv, Z_minus, -N_out_plus
  ];

end

%% ==================== Plot state and tile setup helpers ====================
% These helpers collect reconstruction data and build reusable viz tile inputs.

function plot_state = LOCAL_build_plot_state_in(C, curvelen, S_cell, ...
    modes, selected_minus, selected_plus, a_s_minus, a_s_plus, ...
    selected_in_minus, selected_in_plus, p_in_active, ...
    c_plus, c_minus, incident_port, X0_minus)
% LOCAL_BUILD_PLOT_STATE_IN Collect data needed for field reconstruction.
%
% Purpose:
%   Store the single-cell layer-potential data, the selected outgoing Bloch
%   mode amplitudes, and the incoming Bloch mode data for both half-leads.
%   Used by LOCAL_eval_field_points_in during tile-wise plotting.

  Nbd = size(C, 2);
  x_bd = C(1, :).';
  y_bd = C(4, :).';
  dxdt = C(2, :).';
  dydt = C(5, :).';
  speed = sqrt(dxdt.^2 + dydt.^2);
  nx = dydt ./ speed;
  ny = -dxdt ./ speed;
  weights = (curvelen / Nbd) * speed;

  idx_minus = selected_minus.idx;
  idx_plus = selected_plus.idx;

  plot_state.src = [x_bd.'; y_bd.'];
  plot_state.nx = nx;
  plot_state.ny = ny;
  plot_state.weights = weights;
  plot_state.H_L = S_cell.H_L;
  plot_state.H_R = S_cell.H_R;
  plot_state.Nbd = Nbd;
  plot_state.c_plus = c_plus;
  plot_state.c_minus = c_minus;
  plot_state.X0_minus = X0_minus;

  plot_state.minus.a_L = modes.a_L(:, idx_minus);
  plot_state.minus.b_R = modes.b_R(:, idx_minus);
  plot_state.minus.lambda = modes.lambda(idx_minus);
  plot_state.minus.coeff = a_s_minus;

  plot_state.plus.a_L = modes.a_L(:, idx_plus);
  plot_state.plus.b_R = modes.b_R(:, idx_plus);
  plot_state.plus.lambda = modes.lambda(idx_plus);
  plot_state.plus.coeff = a_s_plus;

  idx_in_minus = selected_in_minus.idx_order;
  plot_state.minus_in.a_L = modes.a_L(:, idx_in_minus);
  plot_state.minus_in.b_R = modes.b_R(:, idx_in_minus);
  plot_state.minus_in.lambda = modes.lambda(idx_in_minus);
  if strcmp(incident_port, '-')
    plot_state.minus_in.coeff = p_in_active;
  else
    plot_state.minus_in.coeff = zeros(length(idx_in_minus), 1);
  end

  idx_in_plus = selected_in_plus.idx_order;
  plot_state.plus_in.a_L = modes.a_L(:, idx_in_plus);
  plot_state.plus_in.b_R = modes.b_R(:, idx_in_plus);
  plot_state.plus_in.lambda = modes.lambda(idx_in_plus);
  if strcmp(incident_port, '+')
    plot_state.plus_in.coeff = p_in_active;
  else
    plot_state.plus_in.coeff = zeros(length(idx_in_plus), 1);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tile_plan = LOCAL_build_tile_plan_in(plot_window, plot_geom, col_lat, L, d)
% LOCAL_BUILD_TILE_PLAN_IN Build reusable tile grids and masks.
%
% Purpose:
%   Keep the user-facing nx_plot/ny_plot controls as approximate total
%   window resolution while producing the reference grids, reference masks,
%   and translated tile metadata used by the plotting helper.

  ncell_x = max(1, ceil((plot_window.x_max - plot_window.x_min) / L));
  ncell_y = max(1, ceil((plot_window.y_max - plot_window.y_min) / d));
  ngridx = max(8, ceil(plot_window.nx / ncell_x));
  ngridy = max(8, ceil(plot_window.ny / ncell_y));

  grid_spec.ngridx = ngridx;
  grid_spec.ngridy = ngridy;
  grid_spec.x_frac = [0, 1];
  grid_spec.y_frac = [0, 1];

  tile_grid_spec.left = grid_spec;
  tile_grid_spec.center = grid_spec;
  tile_grid_spec.right = grid_spec;

  [ref_grid.left.X, ref_grid.left.Y] = viz.cell_grid( ...
    plot_geom.Cminus, tile_grid_spec.left);
  [ref_grid.center.X, ref_grid.center.Y] = viz.cell_grid( ...
    plot_geom.C0, tile_grid_spec.center);
  [ref_grid.right.X, ref_grid.right.Y] = viz.cell_grid( ...
    plot_geom.Cplus, tile_grid_spec.right);

  left_geom_args = {};
  if isfield(col_lat.left, 'geom_args') && ~isempty(col_lat.left.geom_args)
    left_geom_args = col_lat.left.geom_args;
    if ~iscell(left_geom_args)
      left_geom_args = {left_geom_args};
    end
  end
  right_geom_args = {};
  if isfield(col_lat.right, 'geom_args') && ~isempty(col_lat.right.geom_args)
    right_geom_args = col_lat.right.geom_args;
    if ~iscell(right_geom_args)
      right_geom_args = {right_geom_args};
    end
  end

  ref_mask.left = viz.obstacle_mask(ref_grid.left.X, ref_grid.left.Y, ...
    col_lat.left.flag_geom, col_lat.left.q, struct(), left_geom_args{:});
  ref_mask.center = viz.obstacle_mask(ref_grid.center.X, ...
    ref_grid.center.Y, col_lat.center.flag_geom, col_lat.center.q, ...
    struct());
  ref_mask.right = viz.obstacle_mask(ref_grid.right.X, ref_grid.right.Y, ...
    col_lat.right.flag_geom, col_lat.right.q, struct(), right_geom_args{:});

  tile_plan = viz.build_col_lat_tiles(plot_geom, ref_grid, ref_mask);

end

%% ==================== Field evaluation helpers ====================
% These helpers evaluate the center and lead fields on arbitrary tile grids.

function U = LOCAL_eval_field_points_in(X, Y, plot_state, rayleighchan, ...
    pars1, proxy, X0_minus, X0_plus)
% LOCAL_EVAL_FIELD_POINTS_IN Evaluate the plotted total exterior field.
%
% Purpose:
%   Evaluate the total field (center homogeneous Rayleigh + lead incoming +
%   outgoing Bloch combinations) at arbitrary plotting points.  Obstacle
%   masks are applied by the tile drawing helper, not here.

  x_vec = X(:);
  y_vec = Y(:);

  [y_base, y_phase] = LOCAL_apply_y_quasiperiodic_shift(y_vec, ...
    rayleighchan.beta, rayleighchan.d);

  idx_center = x_vec >= X0_minus & x_vec <= X0_plus;
  idx_minus = x_vec < X0_minus;
  idx_plus = x_vec > X0_plus;

  u_vec = NaN(size(x_vec));

  if any(idx_center)
    u_vec(idx_center) = y_phase(idx_center) .* LOCAL_eval_center_homogeneous( ...
      x_vec(idx_center), y_base(idx_center), plot_state, rayleighchan);
  end

  if any(idx_minus)
    u_vec(idx_minus) = y_phase(idx_minus) .* LOCAL_eval_lead_field_in( ...
      x_vec(idx_minus), y_base(idx_minus), plot_state, rayleighchan, ...
      pars1, proxy, X0_minus, X0_plus, '-');
  end

  if any(idx_plus)
    u_vec(idx_plus) = y_phase(idx_plus) .* LOCAL_eval_lead_field_in( ...
      x_vec(idx_plus), y_base(idx_plus), plot_state, rayleighchan, ...
      pars1, proxy, X0_minus, X0_plus, '+');
  end

  U = reshape(u_vec, size(X));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [y_base, phase] = LOCAL_apply_y_quasiperiodic_shift(y, beta, d)
% LOCAL_APPLY_Y_QUASIPERIODIC_SHIFT Fold y and return Bloch phase factors.
%
% Purpose:
%   Map arbitrary y-coordinates to the centered fundamental strip
%   [-d/2,d/2) and return the phase needed to reconstruct the original field.

  n_shift = floor((y + d / 2) / d);
  y_base = y - n_shift * d;
  phase = exp(1i * beta * n_shift * d);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_center_homogeneous(x, y_base, plot_state, rayleighchan)
% LOCAL_EVAL_CENTER_HOMOGENEOUS Evaluate the center cell homogeneous Rayleigh field.
%
% Purpose:
%   Compute the homogeneous Rayleigh expansion in the empty defect cell
%   from the known c_plus and c_minus coefficients.

  beta_m = rayleighchan.beta_m(:);
  gamma_m = rayleighchan.gamma_m(:);
  d = rayleighchan.d;
  X0_minus = plot_state.X0_minus;

  psi = exp(1i * beta_m * y_base.') / sqrt(d);
  phase_plus = exp(1i * gamma_m * (x(:).' - X0_minus));
  phase_minus = exp(-1i * gamma_m * (x(:).' - X0_minus));
  coeff = plot_state.c_plus .* phase_plus + plot_state.c_minus .* phase_minus;
  u = sum(coeff .* psi, 1).';

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_lead_field_in(x, y_base, plot_state, rayleighchan, ...
    pars1, proxy, X0_minus, X0_plus, portSign)
% LOCAL_EVAL_LEAD_FIELD_IN Evaluate incoming + outgoing Bloch response in one half-lead.
%
% Purpose:
%   Reconstruct the exterior field in lead cells by combining selected
%   incoming and outgoing Bloch modes.  Each physical target point is
%   mapped into the canonical single lead cell before evaluating the
%   incident Rayleigh waves and the scattered layer-potential response.

  x = x(:);
  y_base = y_base(:);
  u = zeros(size(x));
  L = rayleighchan.L;

  switch portSign
    case '+'
      lead_data = plot_state.plus;
      lead_data_in = plot_state.plus_in;
      distance = x - X0_plus;
      cell_index = floor(distance / L);
      x_local = -L / 2 + (distance - cell_index * L);
      factor_fun = @(lambda, q) lambda .^ q;
    case '-'
      lead_data = plot_state.minus;
      lead_data_in = plot_state.minus_in;
      distance = X0_minus - x;
      cell_index = floor(distance / L);
      x_local = L / 2 - (distance - cell_index * L);
      factor_fun = @(lambda, q) lambda .^ (-q);
    otherwise
      error('scat_edc_lead_in:InvalidPortSign', ...
        'portSign must be either ''+'' or ''-''.');
  end

  unique_cells = unique(cell_index(:)).';
  for q = unique_cells
    idx = cell_index == q;
    has_out = ~isempty(lead_data.coeff) && any(lead_data.coeff(:));
    has_in = ~isempty(lead_data_in.coeff) && any(lead_data_in.coeff(:));

    a_L_total = zeros(size(lead_data.a_L, 1), 1);
    b_R_total = zeros(size(lead_data.b_R, 1), 1);

    if has_out
      mode_factor = factor_fun(lead_data.lambda(:), q);
      coeff_q = lead_data.coeff(:) .* mode_factor;
      a_L_total = lead_data.a_L * coeff_q;
      b_R_total = lead_data.b_R * coeff_q;
    end

    if has_in
      mode_factor_in = factor_fun(lead_data_in.lambda(:), q);
      coeff_in_q = lead_data_in.coeff(:) .* mode_factor_in;
      a_L_total = a_L_total + lead_data_in.a_L * coeff_in_q;
      b_R_total = b_R_total + lead_data_in.b_R * coeff_in_q;
    end

    if ~has_out && ~has_in
      u(idx) = 0;
      continue;
    end

    u(idx) = LOCAL_eval_single_cell_total_field(x_local(idx), y_base(idx), ...
      a_L_total, b_R_total, plot_state, rayleighchan, pars1, proxy);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_single_cell_total_field(x_local, y_base, a_L, b_R, ...
    plot_state, rayleighchan, pars1, proxy)
% LOCAL_EVAL_SINGLE_CELL_TOTAL_FIELD Evaluate one lead-cell exterior field.
%
% Purpose:
%   Evaluate the total field in the canonical single-cell scattering problem
%   generated by incoming Rayleigh amplitudes a_L and b_R.
%
% Formula:
%   The incident part is
%
%     u_inc = sum_m a_L(m) exp(i*gamma_m*(x-X_L))*psi_m(y)
%           + sum_m b_R(m) exp(-i*gamma_m*(x-X_R))*psi_m(y).
%
%   The scattered part is reconstructed from eta = H_L*a_L + H_R*b_R.

  x_local = x_local(:);
  y_base = y_base(:);
  gamma_m = rayleighchan.gamma_m(:);
  beta_m = rayleighchan.beta_m(:);
  d = rayleighchan.d;
  L = rayleighchan.L;
  X_L = -L / 2;
  X_R = L / 2;

  psi = exp(1i * beta_m * y_base.') / sqrt(d);
  U_L = exp(1i * gamma_m * (x_local.' - X_L)) .* psi;
  U_R = exp(-1i * gamma_m * (x_local.' - X_R)) .* psi;
  u_inc = (a_L.' * U_L + b_R.' * U_R).';

  eta = plot_state.H_L * a_L + plot_state.H_R * b_R;
  tau = eta(1:plot_state.Nbd);
  mu = eta(plot_state.Nbd + 1:2 * plot_state.Nbd);
  tau_w = tau .* plot_state.weights;
  mu_w = mu .* plot_state.weights;

  trg = [x_local.'; y_base.'];
  [pot, gradx, grady] = kernel.qpgreen_mfs_pairmat( ...
    plot_state.src, trg, pars1, proxy);
  dGdnu = -bsxfun(@times, gradx, plot_state.nx.') - ...
    bsxfun(@times, grady, plot_state.ny.');
  u_s = dGdnu * tau_w - pot * mu_w;

  u = u_inc + u_s;

end

%% ==================== Tile contour drawing helpers ====================
% These helpers draw real, imaginary, and magnitude contours from tile data.

function LOCAL_draw_solution_tiles_in(tile_plan, plot_state, rayleighchan, ...
    pars1, proxy, X0_minus, X0_plus, col_lat_opts, incident_port, lam_active)
% LOCAL_DRAW_SOLUTION_TILES_IN Draw tile-wise field contours.
%
% Purpose:
%   Draw the total exterior field (incoming + outgoing + center) using the
%   reusable tile metadata from viz.build_col_lat_tiles.  This helper remains
%   script-local because the field evaluation depends on this scattering
%   prototype's Bloch/Rayleigh reconstruction data.

  tile_data = LOCAL_evaluate_solution_tiles(tile_plan, plot_state, ...
    rayleighchan, pars1, proxy, X0_minus, X0_plus);

  real_levels = LOCAL_contour_levels(tile_data, 'real', ...
    tile_plan.window.ncontour);
  imag_levels = LOCAL_contour_levels(tile_data, 'imag', ...
    tile_plan.window.ncontour);
  abs_levels = LOCAL_contour_levels(tile_data, 'abs', ...
    tile_plan.window.ncontour);

  figure('Name', 'scat_edc_lead_in total field: real/imag', 'Color', 'w');

  subplot(1, 2, 1);
  LOCAL_contour_tiles(gca, tile_data, real_levels, 'real');
  colorbar;
  title(sprintf('real(u)  incident %s, |\\lambda_{in}|=%.4f', ...
    incident_port, abs(lam_active)));
  viz.overlay_col_lat_geom(gca, tile_plan, col_lat_opts);

  subplot(1, 2, 2);
  LOCAL_contour_tiles(gca, tile_data, imag_levels, 'imag');
  colorbar;
  title(sprintf('imag(u)  incident %s, |\\lambda_{in}|=%.4f', ...
    incident_port, abs(lam_active)));
  viz.overlay_col_lat_geom(gca, tile_plan, col_lat_opts);

  figure('Name', 'scat_edc_lead_in total field: abs', 'Color', 'w');
  LOCAL_contour_tiles(gca, tile_data, abs_levels, 'abs');
  colorbar;
  title(sprintf('abs(u)  incident %s, |\\lambda_{in}|=%.4f', ...
    incident_port, abs(lam_active)));
  viz.overlay_col_lat_geom(gca, tile_plan, col_lat_opts);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tile_data = LOCAL_evaluate_solution_tiles(tile_plan, plot_state, ...
    rayleighchan, pars1, proxy, X0_minus, X0_plus)
% LOCAL_EVALUATE_SOLUTION_TILES Evaluate and mask each visible tile.

  tile_data = struct('X', {}, 'Y', {}, 'real', {}, 'imag', {}, 'abs', {});

  for k = 1:numel(tile_plan.cells)
    tile = tile_plan.cells(k);
    r = tile.ref_name;
    Xcell = tile_plan.ref_grid.(r).X + tile.dx;
    Ycell = tile_plan.ref_grid.(r).Y + tile.dy;
    Ucell = LOCAL_eval_field_points_in(Xcell, Ycell, plot_state, ...
      rayleighchan, pars1, proxy, X0_minus, X0_plus);

    mask = tile_plan.ref_mask.(r);
    Ucell(mask) = NaN + 1i * NaN;
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

function levels = LOCAL_contour_levels(tile_data, value_kind, ncontour)
% LOCAL_CONTOUR_LEVELS Build common contour levels across all tiles.

  vals = [];
  for k = 1:numel(tile_data)
    Z = tile_data(k).(value_kind);
    vals = [vals; Z(isfinite(Z))]; %#ok<AGROW>
  end

  if isempty(vals)
    levels = linspace(0, 1, max(2, ncontour));
    return;
  end

  vmin = min(vals);
  vmax = max(vals);
  if vmin == vmax
    span = max(1, abs(vmin));
    vmin = vmin - 1e-6 * span;
    vmax = vmax + 1e-6 * span;
  end
  levels = linspace(vmin, vmax, max(2, ncontour));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_contour_tiles(ax, tile_data, levels, value_kind)
% LOCAL_CONTOUR_TILES Draw all tile values on one axes.

  hold_was_on = ishold(ax);
  hold(ax, 'on');
  for k = 1:numel(tile_data)
    Z = tile_data(k).(value_kind);
    contourf(ax, tile_data(k).X, tile_data(k).Y, Z, levels, ...
      'LineColor', 'none');
  end
  if numel(levels) >= 2
    caxis(ax, [levels(1), levels(end)]);
  end
  if ~hold_was_on
    hold(ax, 'off');
  end
end
