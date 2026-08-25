function out = cfg_i21(mode)
%CFG_I21 Return the frozen I2.1 Method 1B configuration.
% Purpose:
%   Centralize the fine-M48 object, two contour grids, independent gates,
%   parent hashes, evidence names, and engineering budgets frozen in the
%   reviewed I2.1 design.
% Input:
%   mode - 'smoke' or 'full'.
% Output:
%   out - Immutable configuration consumed by run_i21 and its shared cores.
% Based on:
%   test/i1/k-ready/cfg_v2.m and implementation/i2/design.md.
% Main changes:
%   Retain only the fine level and add factor-aware winding and Riesz-chart
%   qualification without authorizing a locator, derivative, or estimator.
% Numerical goal:
%   Decide one conditional empirical finite-dimensional root count.

  if nargin ~= 1
    error('i21:ConfigMode','cfg_i21 requires smoke or full.');
  end
  mode = lower(char(mode));
  if ~ismember(mode,{'smoke','full'})
    error('i21:ConfigMode','mode must be smoke or full.');
  end

  out.schema = 'TEP_I2_1_M1B_V3';
  out.experiment_id = 'I2-K-COUNT-M1B-V1';
  out.design_id = 'I2.1-M1B-RIESZ-COUNT-V1';
  out.revision_id = 'I2.1-M1B-REVISION-2026-08-13-B';
  out.design_status = ...
    'FROZEN METHOD 1B REVISION 2 / PRE-FULL SKEPTIC REVIEW PENDING';
  out.claim_boundary = ...
    'CONDITIONAL_EMPIRICAL_FINE_M48_FINITE_DIMENSIONAL_ROOT_COUNT';
  out.mode = mode;

  % --- frozen parent artifacts and lineage ---
  out.parent_token = ...
    '8b72c9c67c7feb5c0cc204ee02287d61fcba7752395102db13e10b0ae1d8e969';
  out.parents = struct( ...
    'role',{ ...
      'I1_3_ROW_SELECTORS_CANDIDATE', ...
      'I1_4_AFFINE_QZ_PILOT', ...
      'I1_4_POSITIVE_SAMPLED_DISK', ...
      'I1_4_CONDITIONAL_NEGATIVE_CLOSURE'}, ...
    'relative_path',{ ...
      'test/i1/k-scan/output/zoom2/result.mat', ...
      'test/i1/k-ready/output/pilot-a3/result.mat', ...
      'test/i1/k-ready/output/v4-a1/result.mat', ...
      'test/i1/k-ready/output/v5-a1/result.mat'}, ...
    'sha256',{ ...
      'e168638af0536f2671f0fd9d34a37432926953a5b722cbef6da3eaa1fe96678a', ...
      '6a4044934f29de74c53684ecb1fb42d64eac0888d21a16c925c28a05deb85857', ...
      'c4730ba11fb6b8bee5ff72513279b1db0869e752953be86a79694a42c3a1ab34', ...
      'c250c4cef7ffe5bd51c1465d339663c975db6f7fe7375da0096736efdedaf928'});

  % --- frozen model and fine spatial level ---
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
  out.level = struct('name','fine','ntot',256, ...
    'N_side',160,'N_top',160,'N_proxy_edge',80,'M_pw',32);
  out.expected = struct('proxy_rows',960,'proxy_columns',450, ...
    'proxy_shifted_rows',1920,'proxy_shifted_columns',450, ...
    'proxy_rank',260,'bie_order',512,'pencil_order',194, ...
    'chart_order',97,'adef_order',194,'graph_order',388);

  % --- frozen k and zeta contours ---
  out.kstar = 1.8327703475952146;
  out.r0 = 3.8146972647368216e-7;
  out.Nk_full = 64;
  out.Nk_nested = 32;
  out.Nzeta_full = 32;
  out.Nzeta_nested = 16;
  out.k_nodes = out.kstar+out.r0*exp(2i*pi*(0:out.Nk_full-1)/out.Nk_full);
  out.k_nested_indices = 1:2:out.Nk_full;
  out.zeta_nodes = exp(2i*pi*(0:out.Nzeta_full-1)/out.Nzeta_full);
  out.zeta_nested_indices = 1:2:out.Nzeta_full;
  out.cardinal_indices = [1,17,33,49];
  out.smoke_edge_probe_count = 4;
  out.full_edge_count = out.Nk_full;
  % This flag makes the reviewed Revision 2 candidate executable.  It is not
  % a substitute for the independent pre-full review required by design.md.
  out.full_authorized = true;
  out.smoke_parent_relative = fullfile('output','smoke-a2','result.mat');
  out.smoke_parent_sha256 = ...
    '85b6e4b1ffa41d6dd4a3f2daba354a56f1db8749a42ac9a4577d69dd6b0c61ca';
  out.smoke_parent_schema = 'TEP_I2_1_M1B_V2';
  out.smoke_parent_design_id = 'I2.1-M1B-RIESZ-COUNT-V1';
  out.smoke_parent_revision_id = 'I2.1-M1B-REVISION-2026-08-13-A';
  out.smoke_parent_status = 'I2_1_M1B_SMOKE_PASS';
  out.smoke_parent_implementation_digest = ...
    'c8cbc69e72595171a69df181d7fdf0825c7b84411a73d1538163df69f33127b6';
  out.external_startup_seconds = 1.0;
  out.failed_smoke_seconds = 2.8188827916666668;
  out.accepted_smoke_seconds = 34.740040375;
  out.formal_prior_seconds = 38.558923166666666;
  if strcmp(mode,'smoke')
    out.physical_indices = out.cardinal_indices;
    out.output_relative = fullfile('output','smoke-a2');
    out.target_seconds = 120;
    out.hard_seconds = 300;
  else
    out.physical_indices = 1:out.Nk_full;
    out.output_relative = fullfile('output','m1-a1');
    out.target_seconds = 1200;
    out.hard_seconds = 1800;
  end

  % --- inherited I1.4 representation and solve gates ---
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
  out.chart_margin_min = 100*out.K*eps;
  out.chart_condition_eps_tol = 1e-9;
  out.small_solve_residual_tol = 1e3*out.K*eps;
  out.bie_rcond_min = 1e-8;
  out.bie_residual_tol = 1e-10;
  out.schur_tol = 1e3*out.K*eps;
  out.dirichlet_rcond_min = 1e-8;
  out.participation_min = 1e-3;
  out.lift_residual_tol = 1e-10;

  % --- Method 1B factor, phase, and two-axis gates ---
  out.factor_rcond_min = 1e-8;
  out.resolvent_rcond_min = 1e3*out.expected.pencil_order*eps;
  out.adef_rcond_min = out.resolvent_rcond_min;
  out.resolvent_solve_residual_max = out.resolvent_rcond_min;
  out.integer_residual_max = 1e-6;
  out.phase_uncertainty_max = 1e-2;
  out.edge_phase_guard = pi/2;
  out.zeta_arc_guard = 0.5;
  out.k_arc_guard = 0.25;
  out.zeta_half_chord = 2*sin(pi/(2*out.Nzeta_full));
  out.c_quadrature_guard = 0.5;
  out.projector_tol = 1e-7;
  out.oracle_tol = 1e-12;
  out.oracle_negative_min = 0.5;

  % --- resource and evidence contract ---
  out.total_formal_seconds = 7200;
  out.full_projection_stop_seconds = 1500;
  out.memory_mib_max = 512;
  out.maximum_square_order = 512;
  out.maximum_rectangular_shape = [1920,450];
  out.output_must_not_exist = true;
  out.locator_authorized = false;
  out.root_solver_authorized = false;
  out.derivative_authorized = false;
  out.estimator_authorized = false;
  out.method_switches = 0;
end
