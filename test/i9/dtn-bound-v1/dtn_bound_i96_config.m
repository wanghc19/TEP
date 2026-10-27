function config = dtn_bound_i96_config(mode)
%DTN_BOUND_I96_CONFIG Freeze every input of the I9.6a source-reconstruction bound run.
% Purpose: Supply the physical model, the frozen I9.5b fine-Q12 native
%   configuration and candidate k, the control/main evaluation levels, the
%   reliable-evaluation engine and the resource limits of design-9-6a D2.
%   Nothing here is read from documents or historical outputs.
% Input: mode is 'formal' (design Section 2/6 table) or 'smoke' (operational
%   probe on a small mesh and small levels; never a scientific result).
% Output: config struct consumed by dtn_bound_i96.
% Based on: test/i9/fem-dtn-v1/fem_dtn_i95b_config.m (model, mesh rules,
%   per-frequency DtN gates, delivery thresholds, resources).
% Main changes: one frozen native configuration (fine-Q12) at one frozen k,
%   16 lead cells per side, two Fourier/rectangle levels, budget rules;
%   D2: the first-batch proxy gate is removed, the reference-domain engine,
%   the main-level pilot, Taylor-norm and storage options are added.
  if nargin == 0, mode = 'formal'; end
  assert(any(strcmp(mode,{'formal','smoke'})),'i96:Mode','Mode must be formal or smoke.');
  config.schema = 'I96A_DTN_BOUND_D2';
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
  % strip_columns = rectangle columns per x-strip (one prediction pass per
  % strip; coefficients and Fourier moments are written once per strip).
  config.levels = struct('name',{'control','main'},'N',{256,512},'M',{128,256}, ...
    'strip_columns',{32,32});
  % Ordinary prediction: 5x5 Duffy rule (degree 8) on clipped affine pieces, 3x3
  % Gauss on full rectangles, chord->arc sliver (n_tau x n_t Gauss per
  % rectangle-split t-interval), true-material sliver (n_tau x n_t), Newton
  % inversion of curved P2 maps.
  config.integration = struct('sliver_tau',6,'sliver_t',8,'true_tau',4,'true_t',8, ...
    'newton_iterations',8,'newton_tolerance',1e-14,'min_piece_area_fraction',0, ...
    'norm_gauss',12,'norm_block_columns',1024);
  % Evaluation-uncertainty budget b = budget_relative * U0 (design D2 Section 6):
  % moment term + eps_alg <= b; widths of delta_u, E_v, D0 <= b each;
  % c_R width(E_R) <= b; width(E_y)/b_M <= b.
  config.budget_relative = 1e-8;
  % Precision-resolution target (design 1): R_k <= 1e-6.
  config.resolution_target_k = 1e-6;
  % Reference-domain engine (design 4.1-4.3, 7.2): special elements are
  % quadrisected to start_level (the level-3 "nodes" carry the Bernstein
  % bounds); F-type items are refined by score until the source-moment target,
  % level_limit, piece_limit terminal pieces per template per level or the
  % engine deadline. Every fallback_every-th round all pending items of the
  % coarsest level are refined. Chords of the true curve: S0*2^level at item
  % level (level-0 tube for the census). Duffy n x n rules: duffy_F (degree
  % 2n-2 = 10 >= deg |g|^2 J), duffy_P (degree 18 >= deg |p|^2 J).
  % chunk_items bounds the items clipped at once (memory).
  config.engine = struct('start_level',3,'level_limit',30,'piece_limit',2e6, ...
    'refine_fraction',0.9,'fallback_every',4,'duffy_F',6,'duffy_P',10,'S0',320, ...
    'chunk_items',1e5,'target_fraction',1.0,'control_engine_share',0.25, ...
    'coverage_tolerance',1e-10);
  % Main-level pilot (design 6.3, 7.2): one centre-template strip (with its
  % neighbour strips for complete coefficients of every intersecting element),
  % at most pilot_seconds; mandatory-flow prediction with safety factor 2 and
  % at most two future refinement rounds of extrapolation.
  config.pilot = struct('seconds',90,'safety',2,'max_future_rounds',2);
  % Mode-batched norms (design 5): batch_modes modes per batch read from the
  % strip files; Taylor degree taylor_n (taylor_n_max if the Taylor part of
  % the D0/E_v widths exceeds taylor_budget_fraction*b).
  config.norms = struct('batch_modes',32,'taylor_n',24,'taylor_n_max',32, ...
    'taylor_budget_fraction',0.25,'check_gauss',12);
  % Time plan (seconds, design 7.2 allocation): reserve per level for the
  % mode norms and per run for figures/save; used for engine deadlines.
  config.plan = struct('norms_reserve',[30,120],'stageA_reserve',[20,60], ...
    'save_reserve',90);
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
      'strip_columns',{16,16});
    config.engine.piece_limit = 2e5; config.pilot.seconds = 30;
    config.resources.soft_seconds = 600;
    config.continue_on_mismatch = true;
  end
end
