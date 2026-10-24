function config = fem_bound_i94_config()
%FEM_BOUND_I94_CONFIG Frozen nonzero RT2 witness evaluation, theory B.1 (9),(15).
% No FEM solve, candidate search, BIE field, flux optimization or mesh change.
  config.k_h = 1.5584630910866906;
  config.mu_h = config.k_h*config.k_h;
  config.s = config.mu_h;
  config.beta = 0.5;
  config.rho_min = 1;
  config.candidate_index = 1;
  config.edge_moment_order = 12;
  config.volume_moment_order = 8;
  config.evaluation_orders = [8,10];
  config.curve_segments = 8192;
  config.maximum_subdivision = 6;
  config.batch_size = 1024;
  config.material_candidates = [1,4,17];
  config.bulk_uncertainty_goal = 1.8e-7;
  config.end_uncertainty_goal = 1e-10;
  config.radius_reference = 0.01;
  config.radius_fine_reference = 1e-4;
  config.threads = 11;
  config.status = 'UNCERTIFIED_SPECTRAL_DISTANCE_FORMULA_ESTIMATE';
end
