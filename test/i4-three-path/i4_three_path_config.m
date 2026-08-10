function config = i4_three_path_config()
%I4_THREE_PATH_CONFIG Return frozen settings for the I4 three-path experiment.
%
% Purpose:
%   Centralize the physical conventions, Linton checkpoints, independent
%   Ewald refinements, manufactured densities, wall grids, package-MFS
%   proxy levels, acceptance gates, and output paths.
%
% Output:
%   config - Struct containing every user-adjustable experimental setting.
%
% Notes:
%   Physical coordinates are (x,y), with y periodic.  Linton's separation
%   coordinates are (X,Y) = (x_t-x_s,y_t-y_s), with Y periodic, so the local
%   Ewald helper consumes physical separations directly.  Only the package
%   first-coordinate-periodic MFS wrapper swaps physical points to [y;x].

  here = fileparts(mfilename('fullpath'));
  config.here = here;
  config.repo_root = fileparts(fileparts(here));
  config.output_root = fullfile(here, 'output');

  % Canonical physical problem and convention ledger.
  config.k = 1.8603695988;
  config.beta = 0.5;
  config.d = 1.0;
  config.R = 0.2;
  config.X_L = -0.5;
  config.X_R = 0.5;
  config.clearance = min(abs([config.X_L, config.X_R])) - config.R;
  config.time_convention = 'exp(-i omega t)';
  config.free_project = '+i/4 H0^(1)';
  config.free_linton = '-i/4 H0^(1)';
  config.pde_project = '-delta';
  config.pde_linton = '+delta';
  config.coordinate_map = [ ...
    'Linton (X,Y)=(dx_phys,dy_phys); package MFS first-coordinate ', ...
    'wrapper uses [y_phys;x_phys]'];
  config.bloch_translation = 'G(y+d)=exp(+i beta d) G(y)';
  config.branch_convention = [ ...
    'Rayleigh gamma=sqrt(k^2-beta_m^2), Im(gamma)>=0; ', ...
    'Linton q=sqrt(beta_m^2-k^2), evanescent q>0 and propagating q=-i gamma'];

  % Canonical and phase-holdout circle densities.
  config.density(1).label = 'canonical';
  config.density(1).ell = [0; 1; 3];
  config.density(1).coeff = [1; -0.35 + 0.20i; 0.20 - 0.15i];
  config.density(2).label = 'phase_holdout';
  config.density(2).ell = [-2; 0; 1; 3];
  config.density(2).coeff = [0.13 + 0.09i; 0.72 - 0.11i; ...
    -0.24 + 0.31i; 0.08 - 0.19i];

  % Canonical point displacements and two frozen off-axis holdouts.
  delta = [0.30, 0.20, 0.10];
  for j = 1:length(delta)
    config.points(j).label = sprintf('canonical_delta_%.1f', delta(j));
    config.points(j).dx_transverse = delta(j);
    config.points(j).dy_periodic = -0.066;
    config.points(j).is_holdout = false;
  end
  config.points(4).label = 'holdout_A';
  config.points(4).dx_transverse = 0.263;
  config.points(4).dy_periodic = 0.173;
  config.points(4).is_holdout = true;
  config.points(5).label = 'holdout_B';
  config.points(5).dx_transverse = -0.217;
  config.points(5).dy_periodic = 0.287;
  config.points(5).is_holdout = true;

  % Linton Tables 2--5.  Table values use Linton's opposite Green sign.
  config.linton(1) = LOCAL_linton_case('T2', 2, sqrt(2), 0, 0.01, ...
    -0.4595298795 - 0.3509130869i);
  config.linton(2) = LOCAL_linton_case('T3', 10, 5 * sqrt(2), 0, 0.01, ...
    -0.3538172307 - 0.1769332383i);
  config.linton(3) = LOCAL_linton_case('T4', 2, 3, 0, 0.01, ...
    -0.7617463954 - 0.0006387129177i);
  config.linton(4) = LOCAL_linton_case('T5_X0.1', 2, sqrt(2), 0.1, 0.5, ...
    0.3306805081 - 0.1778394385i);
  config.linton(5) = LOCAL_linton_case('T5_X0.5', 2, sqrt(2), 0.5, 0.5, ...
    0.3596087433 - 0.04626396800i);

  % Linton Eq. (2.65) qualification levels.
  config.ewald.base = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 28);
  config.ewald.M1 = struct('a', 2, 'M1', 34, 'M2', 18, 'N', 28);
  config.ewald.M2 = struct('a', 2, 'M1', 26, 'M2', 24, 'N', 28);
  config.ewald.N = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 36);
  config.ewald.joint = struct('a', 2, 'M1', 34, 'M2', 24, 'N', 36);
  config.ewald.a_values = [1.5, 2.0, 2.5];
  config.ewald.wall_a = struct('a', 2.5, 'M1', 26, 'M2', 18, 'N', 28);

  % Rayleigh and wall/boundary grids.
  config.rayleigh_M = [12, 24, 48];
  config.qualification_rayleigh_M = 96;
  config.ntot.authority = 128;
  config.ntot.boundary_ref = 256;
  config.Ny.authority = 256;
  config.Ny.wall_ref = 512;
  config.pilot.ntot = 32;
  config.pilot.Ny = 64;
  config.pilot.M = 12;

  % Package proxy base, four single-axis refinements, and joint diagnostic.
  common.H = config.X_R + config.R + 0.4;
  common.proxy_dist = 0.7;
  config.proxy.base = LOCAL_proxy_level(common, 120, 120, 64, 24);
  config.proxy.Nside = LOCAL_proxy_level(common, 160, 120, 64, 24);
  config.proxy.Ntop = LOCAL_proxy_level(common, 120, 160, 64, 24);
  config.proxy.Nedge = LOCAL_proxy_level(common, 120, 120, 80, 24);
  config.proxy.Mpw = LOCAL_proxy_level(common, 120, 120, 64, 32);
  config.proxy.joint = LOCAL_proxy_level(common, 160, 160, 80, 32);

  % Frozen gates; pilot records them but never issues a scientific verdict.
  config.gate.linton_abs = 5e-10;
  config.gate.ewald_axis_change = 2e-9;
  config.gate.ewald_a_spread = 2e-9;
  config.gate.ewald_rayleigh = 5e-12;
  config.gate.translation = 5e-12;
  config.gate.reciprocity = 5e-12;
  config.gate.projection = 1e-12;
  config.gate.self_change = 2e-9;
  config.gate.coefficient_abs = 1e-8;
  config.gate.rayleigh_retained = 5e-14;
  config.relative_floor_abs = 1e-14;
  config.relative_floor_scale = 1e-12;

  % Full SLP ladder for a later, explicitly authorized run.
  config.slp.ewald_labels = {'base', 'a', 'M1', 'M2', 'N', 'joint'};
  config.slp.proxy_labels = {'base', 'Nside', 'Ntop', 'Nedge', 'Mpw', 'joint'};
end

function c = LOCAL_linton_case(label, kd, betad, X, Y, reference)
  c = struct('label', label, 'd', 1, 'k', kd, 'beta', betad, ...
    'X', X, 'Y', Y, 'reference', reference);
end

function level = LOCAL_proxy_level(common, Nside, Ntop, Nedge, Mpw)
  level = common;
  level.N_side = Nside;
  level.N_top = Ntop;
  level.N_proxy_edge = Nedge;
  level.M_pw = Mpw;
end
