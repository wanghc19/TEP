function cfg = config()
%CONFIG Return the frozen settings for the I1.2 half-guide assembly pilot.
% Purpose:
%   Keep the small manufactured oracle deterministic and make its algebraic
%   and mutation tolerances explicit.

  cfg.K = 3;
  cfg.W = 0.43;
  cfg.tol_alg = 1e3 * cfg.K * eps;
  cfg.tol_mutation = 1e-8;
  cfg.graph_error = 1e-18;
  cfg.unsafe_D_scale = 1e-12;
  cfg.derivative_available = false;
  cfg.future_real_runtime_minutes = [7, 18];
  cfg.future_real_cap_minutes = 30;

  cfg.real.schema = 'HG_ADEF_CELL_V1';
  cfg.real.k = 1.8603695988;
  cfg.real.beta = 0.5;
  cfg.real.d = 1.0;
  cfg.real.R = 0.2;
  cfg.real.X_L = -0.5;
  cfg.real.X_R = 0.5;
  cfg.real.s = 1.0;
  cfg.real.M_master = 8;
  cfg.real.available_M = [5, 8];
  cfg.real.level_kind = 'MASTER_M8_CENTRAL_RESTRICTION';
  cfg.real.wall_labels = {'LEFT_CELL_WALL', 'RIGHT_CELL_WALL'};
  cfg.real.solve_residual_max = 1e-10;
  cfg.real.qz_residual_max = 1e-10;
  cfg.real.graph_error_max = 1e-9;
  cfg.real.level_change_max = 1e-7;
  cfg.real.schur_factor = 1e3;
  cfg.real.proxy_dist = 0.2;
  cfg.real.proxy_H = 1.1;
  cfg.real.low = struct('ntot', 80, 'N_side', 80, 'N_top', 80, ...
    'N_proxy_edge', 44, 'M_pw', 16);
  cfg.real.high = struct('ntot', 160, 'N_side', 120, 'N_top', 120, ...
    'N_proxy_edge', 64, 'M_pw', 24);
end
