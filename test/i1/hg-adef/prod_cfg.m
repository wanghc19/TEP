function cfg = prod_cfg()
%PROD_CFG Return the frozen direct-cell empirical I1.2 settings.
% Purpose:
  %   Keep the non-authoritative M=12 history and the direct M=48 static
  %   half-guide validation parameters explicit.

  cfg.k = 1.8603695988;
  cfg.beta = 0.5;
  cfg.d = 1.0;
  cfg.R = 0.2;
  cfg.X_L = -0.5;
  cfg.X_R = 0.5;
  cfg.s = 1.0;
  cfg.proxy_dist = 0.2;
  cfg.H = 1.1;
  cfg.pilot_M = 12;
  cfg.prod_M = 48;
  cfg.coarse = struct('ntot',160,'N_side',120,'N_top',120, ...
    'N_proxy_edge',64,'M_pw',24);
  cfg.fine = struct('ntot',256,'N_side',160,'N_top',160, ...
    'N_proxy_edge',80,'M_pw',32);

  cfg.qz_tol = 1e-10;
  cfg.coeff_tol = 1e-8;
  cfg.self_tol = 2e-9;
  cfg.graph_tol = 1e-9;
  cfg.projector_tol = 1e-7;
  cfg.chart_tol = 1e-9;
  cfg.mutation_tol = 1e-8;
  cfg.rel_floor = 1e-14;
end
