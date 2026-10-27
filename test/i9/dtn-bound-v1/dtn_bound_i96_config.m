function config = dtn_bound_i96_config(mode)
%DTN_BOUND_I96_CONFIG Freeze every input of the I9.6a source-reconstruction bound run.
% Purpose: Supply the physical model, the frozen I9.5b fine-Q12 native
%   configuration and candidate k, the control/main evaluation levels, the
%   integration/gate rules and the resource limits of design-9-6a (D1).
%   Nothing here is read from documents or historical outputs.
% Input: mode is 'formal' (design Section 2/6 table) or 'smoke' (operational
%   probe on a small mesh and small levels; never a scientific result).
% Output: config struct consumed by dtn_bound_i96.
% Based on: test/i9/fem-dtn-v1/fem_dtn_i95b_config.m (model, mesh rules,
%   per-frequency DtN gates, delivery thresholds, resources).
% Main changes: one frozen native configuration (fine-Q12) at one frozen k,
%   16 lead cells per side, two Fourier/rectangle levels, gate and budget rules.
  if nargin == 0, mode = 'formal'; end
  assert(any(strcmp(mode,{'formal','smoke'})),'i96:Mode','Mode must be formal or smoke.');
  config.schema = 'I96A_DTN_BOUND_V1';
  config.mode = mode;
  % Physical model (identical to I9.5b): beta-quasi-periodic in y, d = L = 1,
  % star centre rho=4, trilobe leads rho=17 (a-=0.12, a+=0.20), background 1.
  config.model = struct('beta',0.5,'d',1,'L',1,'star_scale',1, ...
    'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
    'a_negative',0.12,'a_positive',0.20,'radius',0.2);
  % Frozen candidate (explicit scalar, never updated): I9.5b fine-Q12 root.
  config.k = 1.558438079544167;
  config.k_source = 'I9.5b fine-q12 candidate (fem-dtn-v1 attempt-1 run-02), explicit scalar';
  % Frozen native discretisation: fine mesh s=48, n=320 curved-P2, Q12 assembly.
  config.native = struct('name','fine-q12','subdivisions',48,'interface_segments',320, ...
    'quadrature_order',12,'mesh_key','s48-n320');
  % Reference scalars of the I9.5b fine-q12 delivery (explicit constants used
  % only for identity diagnostics; the qualification gates are below).
  config.native_reference = struct('lambda',-6.706106864977353e-12, ...
    'center_residual',1.0367412655984304e-12,'wall_dofs',96, ...
    'free_dofs',[12916,12756,12880],'triangles',19132,'p2_nodes',38649);
  % Mesh rules (identical to I9.5b D2).
  config.mesh_rules = struct('ring_scale',0.15,'coordinate_tolerance',1e-11, ...
    'interface_clearance_fraction',0.30,'ring_clearance_fraction',0.10, ...
    'det_ratio_max',20,'repair_rounds',3,'curve_samples',33);
  config.mesh_rules.repair_seconds = 30;
  config.mesh_rules.flip = struct('max_checks',32,'max_flips',16, ...
    'convex_factor',1e-12,'crossing_tolerance',1e-9);
  % Per-frequency cell/DtN gates (identical to I9.5b design 3.3).
  config.gates = struct('cell_backward',1e-10,'cell_condest',1e12, ...
    'qz_degenerate_factor',100,'unit_gap',1e-6,'z0_rcond',1e-10, ...
    'invariance',1e-8,'riccati',1e-8,'dtn_hermitian',1e-8, ...
    'dtn_consistency',1e-8,'consistency_rcond',1e-12,'pairing_band',1e6, ...
    'matrix_hermitian',1e-10,'qp_defect',1e-12,'h_hermitian',1e-8);
  % Native qualification (I9.5b root/delivery thresholds): |lambda| <= eig_abs,
  % isolated branch gap >= gap_factor*max(1,||H||), raw-D centre residual,
  % interior recovery, wall continuity, QP and weak-load balance on all cells.
  config.root = struct('eig_abs',1e-10,'center_residual',1e-9,'gap_factor',1e-8);
  config.delivery = struct('recovery_residual',1e-10,'continuity',1e-10,'qp',1e-12, ...
    'load_balance',1e-8,'curve_samples',33);
  % Finite source field: centre plus cells_per_side lead cells on each side,
  % zero outside [-(N+1/2),N+1/2]; unweighted L2 norm over the box set to 1.
  config.field = struct('cells_per_side',16,'tail_power_max',64);
  % Evaluation levels: rectangle width h = 1/N in x and y, Fourier |m| <= M = N/2.
  % strip_columns = rectangle columns per x-strip; mode_blocks = number of
  % Fourier-mode blocks, each re-running the projection and keeping only its
  % modes' arrays (memory control only; results equal up to roundoff).
  config.levels = struct('name',{'control','main'},'N',{256,512},'M',{128,256}, ...
    'strip_columns',{32,32},'mode_blocks',{1,6});
  % Ordinary integration: Dunavant degree-8 rule on clipped affine pieces, 3x3
  % Gauss on full rectangles, chord->arc sliver (n_tau x n_t Gauss per
  % rectangle-split t-interval), true-material sliver (n_tau x n_t), Newton
  % inversion of curved P2 maps.
  config.integration = struct('sliver_tau',6,'sliver_t',8,'true_tau',4,'true_t',8, ...
    'newton_iterations',8,'newton_tolerance',1e-14,'min_piece_area_fraction',1e-16, ...
    'norm_gauss',12,'norm_block_columns',1024);
  % Evaluation-uncertainty budget b = budget_relative * U0 per item (design 4.1);
  % squared-integral widths must satisfy width <= b^2 (square-root conversion).
  config.budget_relative = 1e-8;
  % Precision-resolution target (design 1): R_k <= 1e-6.
  config.resolution_target_k = 1e-6;
  % First-batch reliable-integration gate (design 4.1/6): per template a batch of
  % elements within batch_radius of the curve point at theta = 0 (material-cut
  % and rectangle-cut pieces), reference-triangle bisection with Bernstein
  % control-net boxes and an analytic chord tube of the true curve. At least
  % min_refinements refinements; the last fit_levels levels give the tightening
  % rate. Limits: leaf_limit terminal leaves per template per level, depth_limit.
  config.gate = struct('batch_radius',0.012,'max_depth',14,'min_refinements',3, ...
    'fit_levels',4,'leaf_limit',2e6,'depth_limit',30,'seconds_cap',90, ...
    'theta_window',0.35,'tube_fraction',0.01,'integration_order',6, ...
    'lebesgue_samples',4001);
  % After a gate failure the ORDINARY column is still evaluated once per level
  % as the design's ordinary diagnostic (labelled INTEGRATION_CONTROL_UNRESOLVED);
  % the EXACT column is then RESOURCE_OR_INTEGRATION_UNRESOLVED.
  config.ordinary_after_gate_failure = true;
  config.continue_on_mismatch = false;
  config.solver = struct('rhs_block',32,'lu_fill_allowance',4);
  config.resources = struct('threads',11,'rss_bytes',3e9,'warn_bytes',2.7e9, ...
    'internal_gate_bytes',2.9e9,'soft_seconds',1800,'grace_seconds',600, ...
    'hard_seconds',2400,'save_estimate_seconds',60);
  if strcmp(mode,'smoke')
    % Operational probe only: s=12/n=80 mesh (k is then not a root of this mesh,
    % so the qualification failure is recorded but does not stop the probe),
    % 4 lead cells per side and N = 32/64 levels.
    config.native = struct('name','smoke-q12','subdivisions',12,'interface_segments',80, ...
      'quadrature_order',12,'mesh_key','s12-n80');
    config.field.cells_per_side = 4;
    config.levels = struct('name',{'control','main'},'N',{32,64},'M',{16,32}, ...
      'strip_columns',{16,16},'mode_blocks',{1,2});
    config.gate.max_depth = 10; config.gate.seconds_cap = 30;
    config.continue_on_mismatch = true;
  end
end
