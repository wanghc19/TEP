function config = i4_three_path_derivatives_config()
%I4_THREE_PATH_DERIVATIVES_CONFIG Return frozen derivative experiment settings.
%
% Purpose:
%   Centralize the I4 physical problem, analytic Ewald truncations, finite-
%   difference and Rayleigh qualification levels, circle densities, wall
%   grids, package-MFS proxy refinements, gates, and output paths.
%
% Output:
%   config - Struct containing every frozen experimental setting.
%
% Based on:
%   test/i4-three-path/i4_three_path_config.m.
%
% Main changes:
%   Adds analytic gradient/Hessian qualification and the four raw wall
%   actions SLP-D, SLP-N, DLP-D, and DLP-N.  No setting is tuned from MFS.

  here = fileparts(mfilename('fullpath'));
  config.here = here;
  config.repo_root = fileparts(fileparts(here));
  config.output_root = fullfile(here, 'output');

  % Physical geometry and sign conventions.
  config.k = 1.8603695988;
  config.beta = 0.5;
  config.d = 1.0;
  config.R = 0.2;
  config.X_L = -0.5;
  config.X_R = 0.5;
  config.project_sign = -1;
  config.clearance = min(abs([config.X_L, config.X_R])) - config.R;
  config.time_convention = 'exp(-i omega t)';
  config.project_free = '+i/4 H0^(1)';
  config.linton_free = '-i/4 H0^(1)';
  config.bloch_translation = 'G(y+d)=exp(+i beta d)G(y)';
  config.eta_convention = 'eta=[tau;mu]=[tau;-sigma]';
  config.normal_convention = 'nu_L=(-1,0), nu_R=(+1,0)';

  % Manufactured densities share the frozen circle nodes and weights.
  config.density(1).label = 'canonical';
  config.density(1).ell = [0; 1; 3];
  config.density(1).coeff = [1; -0.35 + 0.20i; 0.20 - 0.15i];
  config.density(2).label = 'phase_holdout';
  config.density(2).ell = [-2; 0; 1; 3];
  config.density(2).coeff = [0.13 + 0.09i; 0.72 - 0.11i; ...
    -0.24 + 0.31i; 0.08 - 0.19i];

  % Frozen off-axis derivative points; none is used to tune truncations.
  config.points(1) = LOCAL_point('canonical_A', 0.30, -0.066, false);
  config.points(2) = LOCAL_point('canonical_B', 0.20, -0.066, false);
  config.points(3) = LOCAL_point('canonical_C', 0.10, -0.066, false);
  config.points(4) = LOCAL_point('holdout_A', 0.263, 0.173, true);
  config.points(5) = LOCAL_point('holdout_B', -0.217, 0.287, true);

  % Published Linton value checkpoints use the opposite Green sign.
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

  % Linton Eq. (2.65) base and independent single-axis refinements.
  config.ewald.base = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 28);
  config.ewald.M1 = struct('a', 2, 'M1', 34, 'M2', 18, 'N', 28);
  config.ewald.M2 = struct('a', 2, 'M1', 26, 'M2', 24, 'N', 28);
  config.ewald.N = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 36);
  config.ewald.joint = struct('a', 2, 'M1', 34, 'M2', 24, 'N', 36);
  config.ewald.a15 = struct('a', 1.5, 'M1', 34, 'M2', 24, 'N', 36);
  config.ewald.a25 = struct('a', 2.5, 'M1', 34, 'M2', 24, 'N', 36);
  config.ewald.labels = {'base', 'M1', 'M2', 'N', ...
    'joint', 'a15', 'a25'};
  config.ewald.authority = config.ewald.joint;

  % Point derivative qualification.
  config.fd_exponents = [7, 8, 9, 10];
  config.fd_h = config.d * 2 .^ (-config.fd_exponents);
  config.fd_richardson_authority = 'R9';
  config.rayleigh_point_M = [24, 48, 96];
  config.components = {'G', 'Gx', 'Gy', 'Gxx', 'Gxy', 'Gyy'};

  % Pilot and full wall grids.
  config.pilot.ntot = 32;
  config.pilot.Ny = 64;
  config.pilot.M = 24;
  config.full.ntot = [128, 256];
  config.full.Ny = [256, 512];
  config.full.M = [24, 48];
  config.actions = {'SLP-D', 'SLP-N', 'DLP-D', 'DLP-N'};

  % Package proxy base and four independent single-axis refinements.
  common.H = config.X_R + config.R + 0.4;
  common.proxy_dist = 0.7;
  config.proxy.base = LOCAL_proxy(common, 120, 120, 64, 24);
  config.proxy.Nside = LOCAL_proxy(common, 160, 120, 64, 24);
  config.proxy.Ntop = LOCAL_proxy(common, 120, 160, 64, 24);
  config.proxy.Nedge = LOCAL_proxy(common, 120, 120, 80, 24);
  config.proxy.Mpw = LOCAL_proxy(common, 120, 120, 64, 32);
  config.proxy.labels = {'base', 'Nside', 'Ntop', 'Nedge', 'Mpw'};

  % Mandatory gates.  Raw Neumann coefficients are never divided by gamma.
  config.gate.point = 2e-9;
  config.gate.linton = 5e-10;
  config.gate.self = 2e-9;
  config.gate.coefficient = 1e-8;
  config.gate.projection = 1e-12;
  config.relative_floor_abs = 1e-14;
  config.relative_floor_scale = 1e-12;
  config.chunk_size = 4096;
end

function item = LOCAL_linton_case(label, kd, betad, X, Y, reference)
  item = struct('label', label, 'd', 1, 'k', kd, 'beta', betad, ...
    'X', X, 'Y', Y, 'reference', reference);
end

function point = LOCAL_point(label, X, Y, holdout)
  point = struct('label', label, 'X', X, 'Y', Y, 'holdout', holdout);
end

function level = LOCAL_proxy(common, Nside, Ntop, Nedge, Mpw)
  level = common;
  level.N_side = Nside;
  level.N_top = Ntop;
  level.N_proxy_edge = Nedge;
  level.M_pw = Mpw;
end
