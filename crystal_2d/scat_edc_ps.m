function scat_edc_ps()
% Purpose:
%   Prototype an empty-defect forced scattering problem driven by a
%   y-quasiperiodic point source placed in the center cell.
%
% Mathematical problem:
%   The center cell is empty and the two half-leads are identical periodic
%   arrays of dielectric cylinders.  This is a scattering / forced problem,
%   not a TEP and not a homogeneous cavity eigenproblem.  The center field is
%
%     u_0 = u_p + u_h,
%
%   where u_p is the known point-source particular solution and u_h is an
%   unknown homogeneous Rayleigh expansion in the empty center cell.
%
% Unknown vector:
%   The unknown is
%
%     unknown = [c^+; c^-; a^-; a^+].
%
%   The coefficients c^+ and c^- are center-cavity Rayleigh right-going and
%   left-going coefficients.  They do not denote positive/negative leads.
%   The coefficients a^- and a^+ multiply outgoing Bloch trace bases in the
%   negative and positive half-leads.
%
% Matrix formula:
%   With E = diag(exp(1i*gamma_m*L0)), E_inv = diag(exp(-1i*gamma_m*L0)),
%   and Gamma = diag(gamma_m), the trace-matching system is
%
%     A_trmatch * unknown = rhs_p,
%
%   where
%
%     A_trmatch =
%       [ I,            I,             -D_out^-,   0;
%        -1i*Gamma,    1i*Gamma,      -N_out^-,   0;
%         E,           E_inv,          0,         -D_out^+;
%         1i*Gamma*E, -1i*Gamma*E_inv, 0,         -N_out^+ ].
%
%   The matrix N_out^- has already been converted by
%   bloch.select_port_traces to the center negative-port outward-normal
%   trace, whose normal direction is -e_x.
%
% Point-source forcing:
%   The forcing trace is the y-quasiperiodic Green function trace at the two
%   center ports.  The right-hand side is
%
%     rhs_p = -[D_p^-; N_p^-; D_p^+; N_p^+].
%
% Expected check:
%   For a well-conditioned prototype solve, the reported relative residual
%   norm(A_trmatch*unknown - rhs_p) / max(1, norm(rhs_p)) should be small.

% --- stage 1: set user parameters ---

% y-quasiperiodic parameter and y-period used by the Rayleigh basis.
beta = 0.4;
d = pi;

% x-period of one lead cell and the matching-port coordinates for the empty
% center defect cell.
L = 2.0;
X0_minus = -L / 2;
X0_plus = L / 2;

% Point-source position inside the empty center cell.  The default source is
% centered in x and placed halfway through one y-period.
x_src = 0;
y_src = 0;

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

% Rayleigh truncation selection controls.  M is increased until the first
% omitted point-source evanescent tail has size at most tol_M, or until
% M_max is reached.
tol_M = 1e-8;
M_max = 80;

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

% Optional lightweight plot of the solved center-port particular trace
% magnitudes.
do_plot_trace = false;

% Solution contour plotting controls.  The plotted field is the total
% exterior field currently represented by this script: u_p + u_h in the
% empty center cell, and the outgoing Bloch response in the two leads.
% Interior cylinder fields are not reconstructed and are masked in plots.
do_plot_solution = true;
x_plot_min = -5.0;
x_plot_max = 5.0;
y_plot_min = -2 * d;
y_plot_max = 2 * d;
nx_plot = 100;
ny_plot = 90;
ncontour = 40;

% Column-lattice visualization controls.  The reference y cell is centered
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

% --- stage 2: choose Rayleigh truncation ---

delta_minus = x_src - X0_minus;
delta_plus = X0_plus - x_src;
delta = min(delta_minus, delta_plus);
[M, M_info] = LOCAL_choose_M_point_source(kext, beta, d, delta, tol_M, M_max);

rayleighchan = bloch.rayleigh_channels(kext, beta, d, M, L);
K = rayleighchan.K;

% --- stage 3: build lead geometry and proxy data ---

[C, curvelen, ~, ~] = geom.construct_cont(ntot, flag_geom, 0, 0, radius);
proxy = kernel.precomp_proxy(pars1, pars2);

% --- stage 4: construct lead Bloch outgoing trace spaces ---

S_cell = bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, ...
  rayleighchan, X0_minus, X0_plus);
modes = bloch.solve_modes(S_cell);
traces = bloch.mode_traces(modes.lambda, modes.V, rayleighchan);

[D_out_minus, N_out_minus, selected_minus] = ...
  bloch.select_port_traces(modes, traces, '-', opts);
[D_out_plus, N_out_plus, selected_plus] = ...
  bloch.select_port_traces(modes, traces, '+', opts);

K_out_minus = selected_minus.numSelected;
K_out_plus = selected_plus.numSelected;

if K_out_minus == 0 || K_out_plus == 0
  warning('scat_edc_ps:NoOutgoingModes', ...
    'At least one outgoing port trace space is empty.');
end
if K_out_minus ~= K || K_out_plus ~= K
  warning('scat_edc_ps:UnexpectedModeCount', ...
    'Selected outgoing mode counts [%d,%d] differ from K = %d.', ...
    K_out_minus, K_out_plus, K);
end

% --- stage 5: build point-source forcing traces ---

forcing = LOCAL_point_source_traces(rayleighchan, X0_minus, X0_plus, ...
  x_src, y_src);

% --- stage 6: assemble trace-matching matrix ---

A_trmatch = LOCAL_construct_A_trmatch(rayleighchan, D_out_minus, ...
  N_out_minus, D_out_plus, N_out_plus, X0_minus, X0_plus);

expected_size = [4 * K, 2 * K + K_out_minus + K_out_plus];
if ~isequal(size(A_trmatch), expected_size)
  warning('scat_edc_ps:UnexpectedMatrixSize', ...
    'A_trmatch size is [%d,%d], expected [%d,%d].', ...
    size(A_trmatch, 1), size(A_trmatch, 2), ...
    expected_size(1), expected_size(2));
end
if size(A_trmatch, 1) ~= size(A_trmatch, 2)
  warning('scat_edc_ps:RectangularSystem', ...
    'A_trmatch is rectangular; MATLAB/Octave backslash returns a least-squares solution.');
end

% --- stage 7: solve forced scattering system ---

sol = A_trmatch \ forcing.rhs_p;

c_plus = sol(1:K);
c_minus = sol(K + 1:2 * K);
a_minus = sol(2 * K + 1:2 * K + K_out_minus);
a_plus = sol(2 * K + K_out_minus + 1:end);

res_vec = A_trmatch * sol - forcing.rhs_p;
relative_residual = norm(res_vec) / max(1, norm(forcing.rhs_p));

% --- stage 8: report diagnostics ---

fprintf('scat_edc_ps\n');
fprintf('  beta = %.16g, d = %.16g, L = %.16g\n', beta, d, L);
fprintf('  kext = %.16g%+.16gi, n = %.16g\n', real(kext), imag(kext), n);
fprintf('  source = (%.16g, %.16g)\n', x_src, y_src);
fprintf('  ntot = %d, geometry = %s, radius = %.16g\n', ...
  ntot, flag_geom, radius);
fprintf('  M = %d, K = %d\n', M, K);
fprintf('  M_info.delta = %.16e\n', M_info.delta);
fprintf('  M_info.alpha_tail = %.16e\n', M_info.alpha_tail);
fprintf('  M_info.tail_decay = %.16e\n', M_info.tail_decay);
fprintf('  M_info.success = %d\n', M_info.success);
fprintf('  selected_minus.numSelected = %d\n', selected_minus.numSelected);
fprintf('  selected_plus.numSelected = %d\n', selected_plus.numSelected);
fprintf('  A_trmatch size = [%d, %d]\n', size(A_trmatch, 1), size(A_trmatch, 2));
fprintf('  relative_residual = %.16e\n', relative_residual);
fprintf('  norm(c_plus) = %.16e\n', norm(c_plus));
fprintf('  norm(c_minus) = %.16e\n', norm(c_minus));
fprintf('  norm(a_minus) = %.16e\n', norm(a_minus));
fprintf('  norm(a_plus) = %.16e\n', norm(a_plus));

if do_plot_trace
  figure('Name', 'Empty-defect point-source scattering trace', 'Color', 'w');
  plot(rayleighchan.m, abs(forcing.D_p_minus), 'o-', ...
    rayleighchan.m, abs(forcing.D_p_plus), 's-', 'LineWidth', 1.1);
  grid on;
  xlabel('Rayleigh index m');
  ylabel('Dirichlet trace coefficient magnitude');
  legend('|D_p^-|', '|D_p^+|', 'Location', 'best');
  title('Point-source particular trace magnitudes');
end

% --- stage 9: evaluate field on plotting window ---

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
  plot_state = LOCAL_build_plot_state(C, curvelen, S_cell, modes, ...
    selected_minus, selected_plus, a_minus, a_plus, c_plus, c_minus, ...
    X0_minus);

  tile_plan = LOCAL_build_tile_plan_ps(plot_window, plot_geom, col_lat, L, d);

  % --- stage 10: draw contour plots ---

  LOCAL_draw_solution_tiles(tile_plan, plot_state, rayleighchan, pars1, ...
    proxy, X0_minus, X0_plus, x_src, y_src, col_lat_opts, radius);
end

end

%% ==================== Rayleigh truncation helper ====================
% This helper selects the point-source Rayleigh truncation order.

function [M, M_info] = LOCAL_choose_M_point_source(k, beta, d, delta, tol_M, M_max)
% LOCAL_CHOOSE_M_POINT_SOURCE Choose Rayleigh truncation for point forcing.
%
% Purpose:
%   Select the smallest nonnegative truncation half-width M whose first
%   omitted positive/negative Rayleigh orders have enough evanescent decay
%   from the point source to the nearest port.
%
% Main algorithm:
%   Starting from M = 0, test
%
%     exp(-alpha_tail(M)*delta) <= tol_M,
%
%   with
%
%     alpha_tail(M) =
%       min(imag(gamma_{M+1}), imag(gamma_{-(M+1)})),
%
%   where gamma_m = sqrt(k^2 - beta_m^2),
%   beta_m = beta + 2*pi*m/d, and the outgoing branch is chosen so that
%   imag(gamma_m) >= 0.
%
% Output:
%   M_info records delta, tol_M, tail_decay, alpha_tail, M_max, and success.

  if ~(isscalar(delta) && isfinite(delta) && delta > 0)
    error('scat_edc_ps:InvalidDelta', ...
      'delta must be a positive finite scalar.');
  end
  if ~(isscalar(tol_M) && isfinite(tol_M) && tol_M > 0)
    error('scat_edc_ps:InvalidTolM', ...
      'tol_M must be a positive finite scalar.');
  end
  if ~(isscalar(M_max) && isfinite(M_max) && M_max >= 0 && ...
      M_max == floor(M_max))
    error('scat_edc_ps:InvalidMMax', ...
      'M_max must be a nonnegative integer scalar.');
  end

  M_info.delta = delta;
  M_info.tol_M = tol_M;
  M_info.tail_decay = NaN;
  M_info.alpha_tail = NaN;
  M_info.M_max = M_max;
  M_info.success = false;

  for M = 0:M_max
    mp = M + 1;
    beta_tail = beta + 2 * pi * [mp; -mp] / d;
    gamma_tail = sqrt(k^2 - beta_tail.^2);
    flip = imag(gamma_tail) < 0;
    gamma_tail(flip) = -gamma_tail(flip);

    alpha_tail = min(imag(gamma_tail));
    tail_decay = exp(-alpha_tail * delta);

    M_info.tail_decay = tail_decay;
    M_info.alpha_tail = alpha_tail;

    if tail_decay <= tol_M
      M_info.success = true;
      return;
    end
  end

  M = M_max;
  warning('scat_edc_ps:MMaxReached', ...
    'M_max = %d reached before tail_decay <= tol_M.', M_max);

end

%% ==================== Trace-matching and forcing helpers ====================
% These helpers assemble the scattering matrix and point-source forcing.

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
%   Matching D_h^\pm + D_p^\pm and N_h^\pm + N_p^\pm to outgoing Bloch
%   trace spaces gives
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
    error('scat_edc_ps:TraceRowMismatch', ...
      'Outgoing trace matrices must have K rows.');
  end
  if size(N_out_minus, 2) ~= K_out_minus || ...
      size(N_out_plus, 2) ~= K_out_plus
    error('scat_edc_ps:TraceColumnMismatch', ...
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function forcing = LOCAL_point_source_traces(rayleighchan, X0_minus, ...
    X0_plus, x_src, y_src)
% LOCAL_POINT_SOURCE_TRACES Build center-cell point-source forcing traces.
%
% Purpose:
%   Evaluate the Rayleigh coefficients of the y-quasiperiodic Green
%   particular solution at the negative and positive center ports.
%
% Mathematical formula:
%   With psi_m(y) = 1/sqrt(d) * exp(1i*beta_m*y), the point-source
%   particular Dirichlet trace coefficients are
%
%     D_p^+(m) =
%       1i/(2*sqrt(d)*gamma_m) * exp(-1i*beta_m*y_src)
%       * exp(1i*gamma_m*(X0_plus - x_src)),
%
%     D_p^-(m) =
%       1i/(2*sqrt(d)*gamma_m) * exp(-1i*beta_m*y_src)
%       * exp(1i*gamma_m*(x_src - X0_minus)).
%
%   The port outward-normal traces are
%
%     N_p^+(m) = 1i*gamma_m*D_p^+(m),
%     N_p^-(m) = 1i*gamma_m*D_p^-(m).
%
% Notes:
%   N_p^- is the center negative-port outward-normal trace, not the
%   partial_x trace.  The formula already includes the outward normal -e_x.

  d = rayleighchan.d;
  beta_m = rayleighchan.beta_m(:);
  gamma_m = rayleighchan.gamma_m(:);

  source_y_phase = exp(-1i * beta_m * y_src);
  source_scale = 1i ./ (2 * sqrt(d) * gamma_m);

  D_p_plus = source_scale .* source_y_phase .* ...
    exp(1i * gamma_m * (X0_plus - x_src));
  D_p_minus = source_scale .* source_y_phase .* ...
    exp(1i * gamma_m * (x_src - X0_minus));

  N_p_plus = 1i * gamma_m .* D_p_plus;
  N_p_minus = 1i * gamma_m .* D_p_minus;

  forcing.D_p_minus = D_p_minus;
  forcing.N_p_minus = N_p_minus;
  forcing.D_p_plus = D_p_plus;
  forcing.N_p_plus = N_p_plus;
  forcing.rhs_p = -[D_p_minus; N_p_minus; D_p_plus; N_p_plus];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ==================== Plot state and tile setup helpers ====================
% These helpers collect reconstruction data and build reusable viz tile inputs.

function plot_state = LOCAL_build_plot_state(C, curvelen, S_cell, modes, ...
    selected_minus, selected_plus, a_minus, a_plus, c_plus, c_minus, ...
    X0_minus)
% LOCAL_BUILD_PLOT_STATE Collect data needed for field reconstruction.
%
% Purpose:
%   Store the single-cell layer-potential data and the selected outgoing
%   Bloch mode amplitudes used by LOCAL_eval_field_points.
%
% Notes:
%   Lead fields are reconstructed mode-by-mode through the incoming
%   amplitudes [a_L; b_R] of each selected Bloch mode.  For a linear
%   combination, the corresponding density is
%
%     eta = H_L*a_L + H_R*b_R.

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
  plot_state.minus.coeff = a_minus;

  plot_state.plus.a_L = modes.a_L(:, idx_plus);
  plot_state.plus.b_R = modes.b_R(:, idx_plus);
  plot_state.plus.lambda = modes.lambda(idx_plus);
  plot_state.plus.coeff = a_plus;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tile_plan = LOCAL_build_tile_plan_ps(plot_window, plot_geom, col_lat, L, d)
% LOCAL_BUILD_TILE_PLAN_PS Build reusable tile grids and masks.
%
% Purpose:
%   Convert the window grid controls into canonical cell-centered grids,
%   build one obstacle mask per reference cell, and let viz.build_col_lat_tiles
%   organize the translated visible cells.

  ncell_x = max(1, ceil((plot_window.x_max - plot_window.x_min) / L));
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
% These helpers evaluate the point-source total field on arbitrary tile grids.

function U = LOCAL_eval_field_points(X, Y, plot_state, rayleighchan, ...
    pars1, proxy, X0_minus, X0_plus, x_src, y_src)
% LOCAL_EVAL_FIELD_POINTS Evaluate the plotted total exterior field.
%
% Purpose:
%   Evaluate the field represented by the solved point-source scattering
%   system at arbitrary plotting points.  Obstacle masks and source masks are
%   applied by the tile drawing helper, not here.

  x_vec = X(:);
  y_vec = Y(:);

  [y_base, y_phase] = LOCAL_apply_y_quasiperiodic_shift(y_vec, ...
    rayleighchan.beta, rayleighchan.d);

  idx_center = x_vec >= X0_minus & x_vec <= X0_plus;
  idx_minus = x_vec < X0_minus;
  idx_plus = x_vec > X0_plus;

  u_vec = NaN(size(x_vec));

  if any(idx_center)
    u_vec(idx_center) = y_phase(idx_center) .* LOCAL_eval_center_field( ...
      x_vec(idx_center), y_base(idx_center), plot_state, rayleighchan, ...
      pars1, proxy, x_src, y_src);
  end

  if any(idx_minus)
    u_vec(idx_minus) = y_phase(idx_minus) .* LOCAL_eval_lead_field( ...
      x_vec(idx_minus), y_base(idx_minus), plot_state, rayleighchan, ...
      pars1, proxy, X0_minus, X0_plus, '-');
  end

  if any(idx_plus)
    u_vec(idx_plus) = y_phase(idx_plus) .* LOCAL_eval_lead_field( ...
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
%
% Formula:
%   If y = y_base + n*d, then
%
%     u(x,y) = exp(1i*beta*n*d) u(x,y_base).

  n_shift = floor((y + d / 2) / d);
  y_base = y - n_shift * d;
  phase = exp(1i * beta * n_shift * d);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_center_field(x, y_base, plot_state, rayleighchan, ...
    pars1, proxy, x_src, y_src)
% LOCAL_EVAL_CENTER_FIELD Evaluate u_p + u_h in the empty center cell.
%
% Purpose:
%   Compute the particular point-source field plus the homogeneous Rayleigh
%   response in the empty defect cell.

  beta_m = rayleighchan.beta_m(:);
  gamma_m = rayleighchan.gamma_m(:);
  d = rayleighchan.d;
  X0_minus = plot_state.X0_minus;

  psi = exp(1i * beta_m * y_base.') / sqrt(d);
  phase_plus = exp(1i * gamma_m * (x(:).' - X0_minus));
  phase_minus = exp(-1i * gamma_m * (x(:).' - X0_minus));
  coeff = plot_state.c_plus .* phase_plus + plot_state.c_minus .* phase_minus;
  u_h = sum(coeff .* psi, 1).';

  u_p = zeros(size(x(:)));
  y_source_shift = round((y_base(:) - y_src) / rayleighchan.d);
  y_source_nearest = y_src + y_source_shift * rayleighchan.d;
  dist_to_source = sqrt((x(:) - x_src).^2 + ...
    (y_base(:) - y_source_nearest).^2);
  idx_eval = dist_to_source > 1e-12;
  if any(idx_eval)
    trg = [x(idx_eval).'; y_base(idx_eval).'];
    src = [x_src; y_src];
    green_data = kernel.qpgreen_mfs(src, trg, pars1, proxy);
    u_p(idx_eval) = green_data.pot(:);
  end
  u_p(~idx_eval) = NaN;

  u = u_p + u_h;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u = LOCAL_eval_lead_field(x, y_base, plot_state, rayleighchan, ...
    pars1, proxy, X0_minus, X0_plus, portSign)
% LOCAL_EVAL_LEAD_FIELD Evaluate outgoing Bloch response in one half-lead.
%
% Purpose:
%   Reconstruct the exterior field in lead cells by combining selected
%   outgoing Bloch modes.  Each physical target point is mapped into the
%   canonical single lead cell before evaluating the incident Rayleigh waves
%   and the scattered layer-potential response of that cell.

  x = x(:);
  y_base = y_base(:);
  u = zeros(size(x));
  L = rayleighchan.L;

  switch portSign
    case '+'
      lead_data = plot_state.plus;
      distance = x - X0_plus;
      cell_index = floor(distance / L);
      x_local = -L / 2 + (distance - cell_index * L);
      factor_fun = @(lambda, q) lambda .^ q;
    case '-'
      lead_data = plot_state.minus;
      distance = X0_minus - x;
      cell_index = floor(distance / L);
      x_local = L / 2 - (distance - cell_index * L);
      factor_fun = @(lambda, q) lambda .^ (-q);
    otherwise
      error('scat_edc_ps:InvalidPortSign', ...
        'portSign must be either ''+'' or ''-''.');
  end

  unique_cells = unique(cell_index(:)).';
  for q = unique_cells
    idx = cell_index == q;
    if isempty(lead_data.coeff)
      u(idx) = 0;
      continue;
    end
    mode_factor = factor_fun(lead_data.lambda(:), q);
    coeff_q = lead_data.coeff(:) .* mode_factor;
    a_L = lead_data.a_L * coeff_q;
    b_R = lead_data.b_R * coeff_q;
    u(idx) = LOCAL_eval_single_cell_total_field(x_local(idx), y_base(idx), ...
      a_L, b_R, plot_state, rayleighchan, pars1, proxy);
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ==================== Tile contour drawing helpers ====================
% These helpers draw real, imaginary, and magnitude contours from tile data.

function LOCAL_draw_solution_tiles(tile_plan, plot_state, rayleighchan, pars1, ...
    proxy, X0_minus, X0_plus, x_src, y_src, col_lat_opts, radius)
% LOCAL_DRAW_SOLUTION_TILES Draw tile-wise field contours.
%
% Purpose:
%   Draw the point-source total exterior field using reusable tile metadata
%   from viz.build_col_lat_tiles.  This helper remains script-local because
%   the field evaluation depends on this point-source scattering prototype.

  source_mask_radius = max(radius / 8, 1e-3);
  tile_data = LOCAL_evaluate_solution_tiles(tile_plan, plot_state, ...
    rayleighchan, pars1, proxy, X0_minus, X0_plus, x_src, y_src, ...
    source_mask_radius);

  figure('Name', 'scat_edc_ps total exterior field: real/imag', 'Color', 'w');

  subplot(1, 2, 1);
  LOCAL_draw_tile_contour_axes(gca, tile_data, tile_plan, 'real', ...
    'real(total exterior field)', col_lat_opts, x_src, y_src, rayleighchan.d);

  subplot(1, 2, 2);
  LOCAL_draw_tile_contour_axes(gca, tile_data, tile_plan, 'imag', ...
    'imag(total exterior field)', col_lat_opts, x_src, y_src, rayleighchan.d);

  figure('Name', 'scat_edc_ps total exterior field: abs', 'Color', 'w');
  LOCAL_draw_tile_contour_axes(gca, tile_data, tile_plan, 'abs', ...
    'abs(total exterior field)', col_lat_opts, x_src, y_src, rayleighchan.d);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tile_data = LOCAL_evaluate_solution_tiles(tile_plan, plot_state, ...
    rayleighchan, pars1, proxy, X0_minus, X0_plus, x_src, y_src, ...
    source_mask_radius)
% LOCAL_EVALUATE_SOLUTION_TILES Evaluate and mask each visible tile.

  tile_data = struct('X', {}, 'Y', {}, 'real', {}, 'imag', {}, 'abs', {});

  for k = 1:numel(tile_plan.cells)
    tile = tile_plan.cells(k);
    r = tile.ref_name;
    Xcell = tile_plan.ref_grid.(r).X + tile.dx;
    Ycell = tile_plan.ref_grid.(r).Y + tile.dy;
    Ucell = LOCAL_eval_field_points(Xcell, Ycell, plot_state, ...
      rayleighchan, pars1, proxy, X0_minus, X0_plus, x_src, y_src);

    obstacle_mask = tile_plan.ref_mask.(r);
    source_mask = LOCAL_point_source_mask(Xcell, Ycell, x_src, y_src, ...
      rayleighchan.d, source_mask_radius);
    Ucell(obstacle_mask | source_mask) = NaN + 1i * NaN;
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
    title_text, col_lat_opts, x_src, y_src, d)
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
  if tile_plan.window.x_min <= 0 && tile_plan.window.x_max >= 0
    line(ax, [0, 0], tile_plan.window.ylim, 'Color', 'k', ...
      'LineStyle', ':', 'LineWidth', 1.0);
  end
  LOCAL_plot_source_markers(ax, x_src, y_src, d, tile_plan.window);
  if ~hold_was_on
    hold(ax, 'off');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mask = LOCAL_point_source_mask(X, Y, x_src, y_src, d, radius)
% LOCAL_POINT_SOURCE_MASK Mask small disks around point-source copies.

  mask = false(size(X));
  p_min = floor((min(Y(:)) - y_src - radius) / d);
  p_max = ceil((max(Y(:)) - y_src + radius) / d);
  for p = p_min:p_max
    y_copy = y_src + p * d;
    mask = mask | ((X - x_src).^2 + (Y - y_copy).^2 < radius^2);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_plot_source_markers(ax, x_src, y_src, d, plot_window)
% LOCAL_PLOT_SOURCE_MARKERS Mark visible quasiperiodic point-source copies.

  p_min = floor((plot_window.y_min - y_src) / d);
  p_max = ceil((plot_window.y_max - y_src) / d);
  for p = p_min:p_max
    y_copy = y_src + p * d;
    if y_copy >= plot_window.y_min && y_copy <= plot_window.y_max && ...
        x_src >= plot_window.x_min && x_src <= plot_window.x_max
      plot(ax, x_src, y_copy, 'wo', 'MarkerSize', 5, 'LineWidth', 1.2, ...
        'MarkerFaceColor', 'k');
    end
  end

end
