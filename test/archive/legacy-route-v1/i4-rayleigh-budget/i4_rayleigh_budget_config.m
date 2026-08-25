function config = i4_rayleigh_budget_config(profile)
% I4_RAYLEIGH_BUDGET_CONFIG Return frozen-grid partial-gate parameters.
%
% Purpose:
%   Centralize the smoke, core, and stress profiles for the I4 Rayleigh-
%   budget experiment.  The smoke grid is frozen, while the unavailable
%   cross-resolution gate keeps decisions disabled.
%
% Input:
%   profile - One of 'smoke', 'core', or 'stress'.
%
% Output:
%   config - Physical parameters, grids, proxy sizes, runtime caps, frozen
%            tolerances, and explicit decision-disable metadata.
%
% Notes:
%   Raw smoke-grid values do not become M_trace or M_stable until every
%   frozen reference and robustness gate is available.

  if nargin < 1 || isempty(profile)
    profile = 'smoke';
  end
  if isstring(profile)
    profile = char(profile);
  end
  valid_profiles = {'smoke', 'core', 'stress'};
  if ~ischar(profile) || ~any(strcmp(profile, valid_profiles))
    error('i4_rayleigh_budget_config:InvalidProfile', ...
      'profile must be ''smoke'', ''core'', or ''stress''.');
  end

  config.experiment_id = 'i4-rayleigh-budget-timing-v1';
  config.profile = profile;
  config.schema_version = 1;
  config.grid_status = 'FROZEN_GRID_PARTIAL_GATE_IMPLEMENTATION';
  config.decision_labels_enabled = false;
  config.M_trace_status = 'INCONCLUSIVE_REFERENCE_LEVEL_PENDING';
  config.M_stable_status = 'INCONCLUSIVE_CROSS_NTOT_GATE_PENDING';

  % --- frozen physical model shared with the sharp-disk I4 diagnostic ---

  config.k = 1.8603695988;
  config.beta = 0.5;
  config.s = 1;
  config.refractive_index = sqrt(1 + 16 * config.s);
  config.period_x = 1;
  config.period_y = 1;
  config.radius = 0.2;
  config.wall_left = -config.period_x / 2;
  config.wall_right = config.period_x / 2;

  % --- upstream validation and projective diagnostic conventions ---

  config.delta = 0.30;
  config.M_probe = 5;
  config.trace_tail_tolerance = 1e-8;
  config.extractor_validation_tolerance = 1e-8;
  config.reference_change_tolerance = 2e-9;
  config.BIE_residual_tolerance = 1e-10;
  config.nonwood_gamma_tolerance = 1e-12;
  config.qz_pair_tolerance = 1e-12;
  config.qz_unit_tolerance = 1e-3;
  config.qz_residual_tolerance = 1e-10;
  config.qz_rcond_floor = 1e-10;
  config.doubling_action_tolerance = 1e-8;
  config.ntot_action_tolerance = 1e-7;
  config.perturbation_epsilons = [1e-12, 1e-10];
  config.perturbation_kappa_limit = 1e4;
  config.doubling_rcond_floor = 1e-10;
  config.action_column_count = 3;

  % --- frozen smoke grid and partially expanded core/stress workloads ---

  switch profile
    case 'smoke'
      config.ntot = 80;
      config.ntot_reference = 120;
      config.Ny_wall = 512;
      config.Ny_wall_reference = 1024;
      config.M_in = 8;
      config.M_out = 70;
      config.square_M_values = 0:8;
      config.square_reference_M = 8;
      config.doubling_levels = 0:6;
      config.max_runtime_seconds = 5400;
      config.expected_runtime_seconds = [180, 900];
      config.proxy.N_side = 80;
      config.proxy.N_top = 80;
      config.proxy.N_proxy_edge = 44;
      config.proxy.M_pw = 16;
    case 'core'
      config.ntot = 80;
      config.ntot_reference = 120;
      config.Ny_wall = 512;
      config.Ny_wall_reference = 1024;
      config.M_in = 20;
      config.M_out = 70;
      config.square_M_values = 0:20;
      config.square_reference_M = 20;
      config.doubling_levels = 0:8;
      config.max_runtime_seconds = 5400;
      config.expected_runtime_seconds = [900, 3600];
      config.proxy.N_side = 80;
      config.proxy.N_top = 80;
      config.proxy.N_proxy_edge = 44;
      config.proxy.M_pw = 16;
    case 'stress'
      config.ntot = 80;
      config.ntot_reference = 120;
      config.Ny_wall = 512;
      config.Ny_wall_reference = 1024;
      config.M_in = 20;
      config.M_out = 70;
      config.square_M_values = 0:20;
      config.square_reference_M = 20;
      config.doubling_levels = 0:8;
      config.max_runtime_seconds = 5400;
      config.expected_runtime_seconds = [900, 5400];
      config.proxy.N_side = 80;
      config.proxy.N_top = 80;
      config.proxy.N_proxy_edge = 44;
      config.proxy.M_pw = 16;
  end

  config.proxy.H = config.period_x / 2 + config.radius + 0.4;
  config.proxy.proxy_dist = 0.7;
  config.command = sprintf([ ...
    'perl -e ''alarm shift; exec @ARGV'' %d conda run -n octave ', ...
    'octave --quiet --no-gui --eval "addpath(''%%s''); ', ...
    'results=run_i4_rayleigh_budget(''%s'');"'], ...
    config.max_runtime_seconds, profile);
end
