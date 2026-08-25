function cfg = scan_cfg()
%SCAN_CFG Return the frozen I1.3 real-wavenumber experiment settings.
% Purpose:
%   Keep the sharp-disk model, spatial levels, real-k stages, and empirical
%   acceptance gates explicit and immutable within the test-local study.

  cfg.schema = 'TEP_MC_SCAN_V1';
  cfg.experiment_id = 'I1-K-SCAN-V1';
  cfg.k0 = 1.8603695988;
  cfg.beta = 0.5;
  cfg.d = 1.0;
  cfg.R = 0.2;
  cfg.s = 1.0;  % Frozen contrast parameter: kint = sqrt(1+16*s)*k.
  cfg.X_L = -0.5;
  cfg.X_R = 0.5;
  cfg.proxy_dist = 0.2;
  cfg.H = 1.1;
  cfg.coarse = struct('ntot',160,'N_side',120,'N_top',120, ...
    'N_proxy_edge',64,'M_pw',24);
  cfg.fine = struct('ntot',256,'N_side',160,'N_top',160, ...
    'N_proxy_edge',80,'M_pw',32);

  cfg.pilot_M = 12;
  cfg.continuity_M = 48;
  cfg.continuity_k = sort(cfg.k0 + [0,-0.02,0.02,-0.01,0.01,-0.005,0.005]);
  cfg.fd_h = [0.02,0.01,0.005];
  cfg.fd_h_extra = [0.0025,0.00125,0.000625];

  cfg.screen_M = 12;
  cfg.screen_k = 1.55:0.05:2.15;
  cfg.screen_extra_k = [1.45,1.50,2.20,2.25];
  cfg.refine_M = 24;
  cfg.refine_offsets = (-4:4)*0.0125;
  cfg.confirm_M = 48;
  cfg.confirm_offsets = (-2:2)*0.00625;
  cfg.max_refine_candidates = 2;

  cfg.solve_tol = 1e-10;
  cfg.block_abs_tol = 1e-8;
  cfg.action_tol = 2e-9;
  cfg.subspace_tol = 1e-7;
  cfg.neighbor_overlap_min = 0.9;
  cfg.subspace_half_ratio_tol = 0.55;
  cfg.chart_condition_eps_tol = 1e-9;
  cfg.fd_change_tol = 1e-6;
  cfg.fd_ratio_tol = 0.35;
  cfg.fd_level_tol = 1e-6;
  cfg.basis_mutation_tol = 1e-12;
  cfg.score_mutation_tol = 1e-12;
  cfg.prominence_min = 1.25;
  cfg.r12_max = 0.5;
  cfg.clear_prominence = 2.0;
  cfg.clear_r12 = 0.1;
  cfg.rel_floor = 1e-14;
  cfg.serial_memory_mib = 512;
  cfg.full_time_minutes = 30;
  cfg.scalar_mutations = [1e-8,exp(0.37i),1e8];
end
