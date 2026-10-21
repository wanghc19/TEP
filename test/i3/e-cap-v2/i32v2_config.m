function cfg = i32v2_config()
%I32V2_CONFIG Return the preregistered I3.2 e-cap-v2 configuration.
% Purpose:
%   Centralize numerical levels, gates, resource limits, and claim flags for
%   the MFS/Kress same-trial empirical-cap experiment.
% Output:
%   cfg - immutable configuration struct consumed by every v2 module.
% Notes:
%   No field in this function is adapted after numerical results are seen.

cfg.schema = 'TEP_I3_2_ECAP_V2_MFS_KRESS_V1';
cfg.attempt = 'ecap-v2-a2';
cfg.provenance = 'I32_ECAP_V2_A2_CANONICAL_DOUBLE_TYPE_REPAIR';
cfg.claim_label = 'EMPIRICAL / UNQUALIFIED';
cfg.retry.ordinal = 1;
cfg.retry.retries_before = 0;
cfg.retry.exact_overwrite_authorized = true;
cfg.retry.prior_attempt = struct('tag', 'ecap-v2-a1', ...
  'status', 'BLOCKED', 'first_blocker', 'MATLAB:mixedClasses', ...
  'overwritten', false);

% --- stage 1: frozen physics and evaluation levels ---
cfg.physics.beta = 0.5;
cfg.physics.d = 1.0;
cfg.physics.R = 0.2;
cfg.physics.rho_disk = 17.0;
cfg.physics.M = 48;
cfg.physics.K = 97;
cfg.identity.digest_algorithm = 'SHA-256 deterministic numerical serialization';
cfg.identity.expected_trial_digest = ...
  'd2ca762b25a6eca78b2c33f1bd91eda89f030533f3ef59fde64a145bc5cc9f87';
cfg.identity.expected_canonical_digest = ...
  'd5707e0462d9be2fd9cdc1432bfccd3570ddabff85729dd0caac1b37cde9cf55';
cfg.identity.expected_released_digest = ...
  'a61be0b93be1d4a76327b0f408977cbc015c6cfe07a0b50f48bd3d69d0e6e620';
cfg.identity.expected_release_manifest_digest = ...
  '4b105f92910ba423f1915df3bf5ed80c6681e8cf2eb481e86ac3afb86a1a7d9a';

cfg.levels.circle_source = [512, 1024, 2048];
cfg.levels.circle_target = [512, 1024, 2048];
cfg.levels.wall_source = [1024, 2048, 4096];
cfg.levels.wall_target = [1024, 2048, 4096];
cfg.levels.riccati = [512, 1024, 2048];
cfg.levels.lift_gauss = [32, 64, 128];
cfg.levels.fullp = [8, 16, 32];
cfg.levels.gqp_interp = [65, 129, 257];

% --- stage 2: MFS-only quasi-periodic kernel ---
cfg.gqp.proxy_H = 1.1;
cfg.gqp.proxy_distance = 0.2;
cfg.gqp.production = struct('Nside', 160, 'Ntop', 160, ...
  'Nedge', 80, 'Mpw', 32);
cfg.gqp.base = struct('Nside', 120, 'Ntop', 120, ...
  'Nedge', 64, 'Mpw', 24);
cfg.gqp.variant_names = {'base', 'Nside', 'Ntop', 'Nedge', 'Mpw'};
cfg.gqp.relative_floor = 2e-9;
cfg.gqp.interp_contraction = 0.5;
cfg.gqp.table_x_bounds = [-0.5, 0.5];
cfg.gqp.table_y_bounds = [-1, 1];
cfg.gqp.table_panel_targets = 512;

% --- stage 3: quadrature, cap, and qualification gates ---
cfg.panel.target_max = 128;
cfg.panel.source_max = 256;
cfg.threshold.refinement_contraction = 0.5;
cfg.threshold.refinement_relative = 0.20;
cfg.threshold.phase = 1e-10;
cfg.threshold.recombination = 1e-12;
cfg.threshold.kress_aligned = 1e-14;
cfg.threshold.kress_offgrid = 5e-13;
cfg.threshold.gram = 1e-12;
cfg.threshold.interval_width = 1e-6;
cfg.roundoff.multiplier = 100.0;
cfg.roundoff.eps = eps('double');

% --- stage 4: lifting, tail, and resource contract ---
cfg.lift.delta_circle = 0.04;
cfg.lift.delta_wall = 0.04;
cfg.fullp.tail_share_max = 1e-6;
cfg.resource.soft_s = 1500;
cfg.resource.hard_s = 1800;
cfg.resource.memory_mib_max = 2048;
cfg.resource.publication_reserve_mib = 64;

% --- stage 5: claims that remain false in I3.2 ---
cfg.flags.reliability = false;
cfg.flags.outward_residual_upper = false;
cfg.flags.outward_field_lower = false;
cfg.flags.outward_tail_enclosure = false;
cfg.flags.certified_tail = false;
cfg.flags.certified_projected_gap = false;
cfg.flags.independent_reference = false;
cfg.flags.reliable_spectral_interval = false;
cfg.flags.continuous_eigenvalue_exists = false;

% --- stage 6: flat aliases for scientific-module interface stability ---
cfg.gqp_H = cfg.gqp.proxy_H;
cfg.gqp_proxy_dist = cfg.gqp.proxy_distance;
cfg.gqp_production = [cfg.gqp.production.Nside, cfg.gqp.production.Ntop, ...
  cfg.gqp.production.Nedge, cfg.gqp.production.Mpw];
cfg.gqp_variants = [120, 120, 64, 24; 160, 120, 64, 24; ...
  120, 160, 64, 24; 120, 120, 80, 24; 120, 120, 64, 32];
cfg.gqp_interp_levels = cfg.levels.gqp_interp;
cfg.gqp_direct_block = cfg.gqp.table_panel_targets;
cfg.gqp_interp_oracle_tol = cfg.gqp.relative_floor;
cfg.gqp_bloch_oracle_tol = cfg.threshold.phase;
cfg.circle_levels = cfg.levels.circle_source;
cfg.wall_levels = cfg.levels.wall_source;
cfg.boundary_target_panel = cfg.panel.target_max;
cfg.boundary_source_panel = cfg.panel.source_max;
cfg.identity_tol = cfg.threshold.phase;
end
