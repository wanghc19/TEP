function out = cfg_v2()
%CFG_V2 Return the frozen I1.4 affine-proxy V2 pilot settings.
% Purpose:
%   Keep the V2 affine proxy anchor, two pilot nodes, parent lineage, and
%   fail-closed thresholds explicit without changing the completed V1 pilot.
% Output:
%   out - Immutable settings for run_pilot_v2 and eval_k_v2.

  out.schema = 'TEP_I1_K_READY_PILOT_V2';
  out.experiment_id = 'I1-K-READY-PILOT-V2';
  out.claim_boundary = 'SAMPLED_DISCRETE_READINESS_PILOT_ONLY';
  out.parent_token = ...
    '8b72c9c67c7feb5c0cc204ee02287d61fcba7752395102db13e10b0ae1d8e969';
  out.kstar = 1.8327703475952146;
  out.r0 = 3.8146972647368216e-7;
  out.nodes = [out.kstar, out.kstar + 1i*out.r0];
  out.node_labels = {'seed','cardinal_plus_i'};

  % The model and spatial levels are identical to the frozen I1.3 parent.
  out.beta = 0.5;
  out.d = 1.0;
  out.R = 0.2;
  out.s = 1.0;
  out.X_L = -0.5;
  out.X_R = 0.5;
  out.H = 1.1;
  out.proxy_dist = 0.2;
  out.M = 48;
  out.K = 2*out.M+1;
  out.level_names = {'coarse','fine'};
  out.levels(1) = struct('name','coarse','ntot',160, ...
    'N_side',120,'N_top',120,'N_proxy_edge',64,'M_pw',24);
  out.levels(2) = struct('name','fine','ntot',256, ...
    'N_side',160,'N_top',160,'N_proxy_edge',80,'M_pw',32);

  % V2 freezes an affine proxy chart around one local seed solution per level.
  out.proxy_rank_ratio = 1e-8;
  out.proxy_rank_gap_min = 2;
  out.proxy_projector_repeat_tol = 1e-10;
  out.proxy_rcond_min = 1e-8;
  out.proxy_projected_tol = 1e-11;
  out.proxy_full_residual_max = 1e-5;
  out.proxy_shifted_residual_max = 1e-5;
  out.proxy_seed_identity_tol = 1e-12;
  out.branch_tol = 1e-12;
  out.qz_residual_tol = 1e-10;
  out.qz_overlap_min = 0.9;
  out.cross_cluster_margin_min = 100*out.K*eps;

  % Existing I1 algebraic, factor, and real-anchor gates remain unchanged.
  out.block_abs_tol = 1e-8;
  out.action_tol = 2e-9;
  out.score_abs_tol = 1e-10;
  out.vector_overlap_min = 0.9;
  out.subspace_tol = 1e-7;
  out.chart_margin_min = 100*out.K*eps;
  out.chart_condition_eps_tol = 1e-9;
  out.small_solve_residual_tol = 1e3*out.K*eps;
  out.bie_rcond_min = 1e-8;
  out.bie_residual_tol = 1e-10;
  out.factor_rcond_min = 100*out.K*eps;
  out.schur_tol = 1e3*out.K*eps;
  out.dirichlet_rcond_min = 1e-8;
  out.participation_min = 1e-3;
  out.lift_residual_tol = 1e-10;
  out.cr_tol = 1e-6;

  % The V2 pilot is still limited to two prescribed nodes.
  out.pilot_seconds_max = 300;
  out.pilot_memory_mib = 512;
  out.pilot_node_limit = 2;
  out.full_sample_nodes_per_attempt = 41;
  out.full_cr_evaluations_per_attempt = 9*3*4;
  out.full_attempt_limit = 3;
  out.full_negative_evaluation_allowance = 16;
  out.full_seconds_budget = 3*3600;
  out.full_authorized = false;
  out.locator_authorized = false;
  out.contour_authorized = false;
  out.root_authorized = false;
  out.derivative_authorized = false;
  out.estimator_authorized = false;
end
