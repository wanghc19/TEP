function config = refine_i102_config(group)
%REFINE_I102_CONFIG Freeze every input of one I10.2 solve-discretization group.
% Purpose: Supply the physical model, the explicit group mesh (s, n_Gamma),
%   the bounded I9.5b mesh repair (deletion rounds plus local edge flips), the
%   three field orders, the primary/check/extra integration rules, the root,
%   prediction, Stein, derivative and location contracts, the declared
%   evaluation budgets and the resource limits of design-10-2a (D1).
%   Nothing here is read from documents, historical outputs or Git.
% Input: group is 'g12' (s=12, n=80), 'g24' (s=24, n=160) or 'g48' (s=48,
%   n=320). There is no smoke or sizing mode.
% Output: config struct consumed by refine_i102.
% Based on: test/i10/enrich-v1/enrich_i101_config.m (I10.1 D2; every model,
%   rule, gate and budget value copied unchanged) and
%   test/i9/fem-dtn-v1/fem_dtn_i95b_config.m (flip limits).
% Main changes: explicit group selection; mesh_rules.repair_seconds and
%   mesh_rules.flip from I9.5b D2; group-specific identity reference counts.
  assert(nargin==1 && any(strcmp(group,{'g12','g24','g48'})),'i102:Group', ...
    'Group must be g12, g24 or g48.');
  config.schema = 'I102_REFINE_V1';
  config.mode = 'formal';
  config.group = group;
  % Physical model (identical to I9.5b): beta-quasi-periodic in y, d = L = 1,
  % centre five-lobe star rho=4 (unscaled), left/right different trilobes
  % rho=17, background rho=1.
  config.model = struct('beta',0.5,'d',1,'L',1,'star_scale',1, ...
    'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
    'a_negative',0.12,'a_positive',0.20,'radius',0.2);
  % Given original candidate (I9.5b attempt-1/run-02 fine-q12), explicit scalar.
  config.k0 = 1.558438079544167;
  config.mu0 = config.k0^2;
  config.k0_source = 'I9.5b fem-dtn-v1 attempt-1 run-02 fine-q12 candidate, explicit scalar';
  config.window = config.k0 + [-0.01,0.01];      % fixed total search window in k
  % Group mesh (design-10-2a 2.1): background subdivisions s per unit cell
  % side and analytic interface segments n_Gamma per curve; mesh rules copied
  % from I9.5b/I10.1.
  table = struct('g12',[12,80],'g24',[24,160],'g48',[48,320]);
  sn = table.(group);
  config.mesh = struct('subdivisions',sn(1),'interface_segments',sn(2));
  config.mesh_rules = struct('ring_scale',0.15,'coordinate_tolerance',1e-11, ...
    'interface_clearance_fraction',0.30,'ring_clearance_fraction',0.10, ...
    'det_ratio_max',20,'repair_rounds',3,'curve_samples',33);
  % Bounded local edge flip (I9.5b D2, design-10-2a 2.2), used only when the
  % deletion rounds leave bad elements: at most 32 candidate checks and 16
  % accepted flips; all deletion/flip repair and re-checks share 30 s.
  % Convexity: every turn of abcd exceeds 1e-12*ell^2; curved-edge crossing
  % roots within 1e-9 of a decision boundary are rejected as undecidable.
  config.mesh_rules.repair_seconds = 30;
  config.mesh_rules.flip = struct('max_checks',32,'max_flips',16, ...
    'convex_factor',1e-12,'crossing_tolerance',1e-9);
  % Identity reference counts of earlier builds of the same (s, n_Gamma);
  % compared and recorded only, never used to authorize execution.
  refs = struct( ...
    'g12',struct('triangles',2200,'p2_nodes',4497,'free_dofs_p2',[1504,1464,1504], ...
      'source','I10.1 enrich-v1 smoke-03 (s12-n80)'), ...
    'g24',struct('triangles',6102,'p2_nodes',12397,'free_dofs_p2',[4148,4080,4120], ...
      'source','I9.5b fem-dtn-v1 run-02 coarse (s24-n160, one flip)'), ...
    'g48',struct('triangles',19132,'p2_nodes',38649,'free_dofs_p2',[12916,12756,12880], ...
      'source','I9.5b fem-dtn-v1 run-02 fine (s48-n320)'));
  config.expected_mesh = refs.(group);
  % Field orders shared by all three templates (design 3.1).
  config.orders = [2,3,4];
  % Integration rules (design 3.3): volume Gauss-Duffy order (points per
  % direction), equal t-subsegments per analytic interface segment, and the
  % tensor Gauss points per subsegment in t and tau (tau in [0,1] unsplit).
  config.rules = struct('name',{'primary','check','extra'},'volume_order',{12,16,20}, ...
    'band_subsegments',{2,4,8},'band_points',{8,12,16});
  % Declared evaluation budgets E (mu units) and saturation constant q.
  config.epsilon = [1e-10,1e-10,1e-10];          % epsilon_2, epsilon_3, epsilon_4
  config.q = 0.5;
  config.extra_trigger_factor = 1/4;             % extra iff |mu_primary-mu_check| > eps_p/4
  config.ratio_floor_factor = 10;                % q_obs only if d23 > 10(eps2+eps3)
  % Nested-matrix and basis checks (design 3.1).
  config.nested_tol = 1e-10;
  % D2 3.2: two-sided shared-edge geometry/trace check at edge parameters
  % 0,1/4,1/2,3/4,1 (numerical tolerance, not a certification).
  config.edge_tol = 1e-10;
  % Point location in the curved FE mesh (design D2 3.2): acceptance window
  % r_K/h_K <= residual and b_K >= barycentric_min; one owner per point by
  % (-b_K, r_K/h_K, global element id). Dual-owner basis differences are
  % recorded only (the D1 1e-10 dual veto is withdrawn by D2).
  config.location = struct('newton_steps',30,'halvings',8,'residual',1e-12, ...
    'barycentric_min',-1e-10,'aabb_pad',1e-12,'batch',20000);
  % Per-frequency cell/DtN gates (I9.5b design 3.3, unchanged).
  config.gates = struct('cell_backward',1e-10,'cell_condest',1e12, ...
    'qz_degenerate_factor',100,'unit_gap',1e-6,'z0_rcond',1e-10, ...
    'invariance',1e-8,'riccati',1e-8,'dtn_hermitian',1e-8, ...
    'dtn_consistency',1e-8,'consistency_rcond',1e-12,'pairing_band',1e6, ...
    'matrix_hermitian',1e-10,'qp_defect',1e-12,'h_hermitian',1e-8);
  % Branch and root contract (design 4.2). Stop requires k bracket <= 2e-12,
  % mu bracket <= eps_p/8, |theta| <= 1e-10 and uncondensed residual <= 1e-9.
  config.root = struct('half_widths',[2e-6,2e-5,2e-4,1e-3,1e-2],'overlap_min',0.90, ...
    'select_corr_min',0.90,'gap_factor',1e-8,'max_halvings',8, ...
    'max_frequencies',40,'k_width',2e-12,'mu_width_factor',1/8,'theta_abs',1e-10, ...
    'center_residual',1e-9,'nearest_count',5);
  % Cross-layer same-mode evidence on 201 physical wall samples.
  config.same_mode = struct('trace_points',201,'corr_min',0.99);
  % Stein doubling (design 4.1): tail <= 1e-11*max(||X||_F,1), at most 30 rounds;
  % prediction truncation cost |theta| t_M / m_j^2 <= eps_3/8.
  config.stein = struct('tail_rel',1e-11,'max_rounds',30,'prediction_factor',1/8);
  % Central-difference derivative diagnostic at P3/check/mu0.
  config.derivative = struct('dmu',1e-5,'rel_tol',1e-6);
  % Delivery checks (I9.5b design 6).
  config.delivery = struct('display_cells',4,'recovery_residual',1e-10, ...
    'continuity',1e-10,'qp',1e-12,'load_balance',1e-8);
  % Linear algebra and resources: multi-RHS blocks of 32 columns, 11 threads,
  % internal memory gate below the 3e9-byte process-tree hard limit.
  config.solver = struct('rhs_block',32,'lu_fill_allowance',4);
  config.resources = struct('threads',11,'rss_bytes',3e9,'warn_bytes',2.7e9, ...
    'internal_gate_bytes',2.9e9,'soft_seconds',1800,'grace_seconds',600, ...
    'hard_seconds',2400,'save_estimate_seconds',60);
end
