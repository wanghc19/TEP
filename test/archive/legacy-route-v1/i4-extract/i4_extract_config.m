function config = i4_extract_config()
%I4_EXTRACT_CONFIG Return the frozen settings for the i4 extraction oracles.
%
% Purpose:
%   Centralize the canonical geometry, manufactured densities, independent
%   refinement levels, fixed acceptance gates, and output locations used by
%   run_i4_extract_oracles.
%
% Output:
%   config - Struct containing all physical and numerical settings.
%
% Notes:
%   The Researcher gate fixes d = 1, beta = 0.5, k = 1.8603695988,
%   R = 0.2, and walls x = +/-0.5.  The two proxy levels are exactly
%   (120,120,64,24) and (160,160,80,32).

  here = fileparts(mfilename('fullpath'));
  config.here = here;
  config.repo_root = fileparts(fileparts(here));
  config.output_root = fullfile(here, 'output');

  % Canonical physical parameters.
  config.d = 1.0;
  config.beta = 0.5;
  config.k = 1.8603695988;
  config.R = 0.2;
  config.X_L = -0.5;
  config.X_R = 0.5;
  config.L = config.X_R - config.X_L;
  config.M = 70;
  config.nested_M = [5, 10, 20, 70];

  % The nonnegative harmonics avoid any negative-order Bessel convention.
  config.density_ell = [0; 1; 3];
  config.density_coeff = [1.0; -0.35 + 0.20i; 0.20 - 0.15i];
  config.boundary_ntot = [128, 256, 512];
  config.formula_ntheta = 4096;

  % Pure/exact wall projections and MFS single-variable refinements.
  config.pure_modes = (-3:3).';
  config.pure_coeff_L = (0.17 + 0.03i) * exp(0.19i * config.pure_modes);
  config.pure_coeff_R = (-0.11 + 0.07i) * exp(-0.13i * config.pure_modes);
  config.pure_Ny = [64, 128];
  config.exact_wall_Ny = [512, 1024, 2048];
  config.mfs_Ny = [512, 1024];

  % After the physical y-periodic axis swap, H is a physical x half-width.
  proxy_common.H = config.X_R + config.R + 0.4;
  proxy_common.proxy_dist = 0.7;
  config.proxy_high = proxy_common;
  config.proxy_high.N_side = 120;
  config.proxy_high.N_top = 120;
  config.proxy_high.N_proxy_edge = 64;
  config.proxy_high.M_pw = 24;
  config.proxy_higher = proxy_common;
  config.proxy_higher.N_side = 160;
  config.proxy_higher.N_top = 160;
  config.proxy_higher.N_proxy_edge = 80;
  config.proxy_higher.M_pw = 32;

  % Point-value oracle: physical source-to-right-wall distances.
  config.point_delta = [0.30, 0.20, 0.10];
  config.point_source_y = 0.137;
  config.point_target_y = 0.071;
  config.point_spectral_M = [12, 24, 48, 96];
  config.slope_modes = (8:18).';
  config.ewald_low = struct('a', 2, 'M1', 18, 'M2', 12, 'N', 20);
  config.ewald_high = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 28);

  % Frozen gates.  No gate is relaxed automatically in Octave.
  config.gate.pure_projection = 1e-12;
  config.gate.formula_code = 5e-13;
  config.gate.resolved_action = 1e-11;
  config.gate.nested_retained = 5e-14;
  config.gate.boundary_refinement = 2e-10;
  config.gate.exact_wall_refinement = 2e-10;
  config.gate.mfs_reference = 2e-9;
  config.gate.mfs_two_level_change = 2e-9;
  config.gate.existing_extractor = 1e-8;
  config.gate.four_layer_budget = 1e-8;
  config.gate.slope_relative = 0.05;
  config.resolved_floor = 1e-12;

  config.expected_runtime_seconds = [2100, 2700];
end
