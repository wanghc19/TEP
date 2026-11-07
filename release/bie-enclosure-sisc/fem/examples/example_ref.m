function e=example_ref()
% Source: test/fem-goerisch/pipeline-v1/examples/example_ref.m. Reference parameters retained.
  % EXAMPLE_REF Reference line-defect waveguide. ref means reference.
  % Input
  %   None. Change only model.rho_center in a caller for the supported family.
  % Output
  %   Explicit model, windows, discretization, tolerances and resource struct.
  e.model=struct('beta',.5,'d',1,'L',1,'star_scale',1, ...
    'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
    'a_negative',.12,'a_positive',.20,'radius',.2,'gamma',1);
  e.model.core=struct('cell_indices',0,'x_interval',[-.5,.5],'y_interval',[-.5,.5]);
  e.model.ports=[-.5,.5];
  e.model.leads=struct('left',struct('template','left','inward_sign',-1), ...
    'right',struct('template','right','inward_sign',1));
  % These Fourier data and derivative bounds are valid only for these curves.
  e.model.curves.center=struct('kind','star','radius',.2,'scale',1, ...
    'lobes',5,'amplitude',.3,'axes',[1.5,1],'center',[0,0], ...
    'omega',[1,-1,6,-4],'amp',[.25,.05,.03,.03], ...
    'C3',8.7,'area',pi*.2^2*(1.5+.3^2/2));
  for side={'left','right'}
    a=.12;if strcmp(side{1},'right'),a=.20;end
    R=.2/sqrt(1+a^2/2);
    e.model.curves.(side{1})=struct('kind','trilobe','radius',.2,'a',a, ...
      'lobes',3,'center',[0,0],'omega',[1,4,-2],'amp',R*[1,a/2,a/2], ...
      'C3',R*(1+a/2*(4^3+2^3)),'area',pi*.2^2);
  end
  e.model.taper=struct('lead_cells',13,'first_cell',12,'start',11.5,'width',2,'end',13.5);
  e.windows=struct('search_k',[1.4509999999999998,2.2490000000000001], ...
    'alpha_minus',1.32^2,'alpha_plus',2.37^2,'local_halfwidth',.01);
  e.discretization.search=LOCAL_search(e.model,e.windows.search_k);
  e.discretization.native=LOCAL_native(e.model,'g48');
  e.discretization.search=rmfield(e.discretization.search,'model');
  e.discretization.native=rmfield(e.discretization.native,'model');
  e.discretization.trial_degree=3;e.discretization.flux_degree=3;
  e.discretization.orders=[16,24];e.discretization.band_orders=[10,16];
  e.discretization.block=48;e.discretization.curve_taylor_order=18;
  e.discretization.polynomial_degree=12;e.discretization.series_order=16;
  e.discretization.original=struct('tol',1e-13/(3*640),'sliver_panels',4,'inverse_iterations',18,'measure',false);
  e.discretization.fast=struct('tol',1e-10/(3*640),'sliver_panels',1,'inverse_iterations',6,'measure',false);
  e.tolerances=struct('E_rational',1e-12,'S_common_rational',1e-16, ...
    'mass_halfwidth',1e-13,'taper_S',1e-21,'quadrature_fraction',.01, ...
    'area',1e-12,'trace',1e-10,'quotient',1e-12);
  e.resources=struct('threads',11,'soft_seconds',1800,'hard_seconds',2400,'rss_gib',3);
end
function config=LOCAL_search(model,window)
  % Input: explicit model and search window. Output: copied P2 search options.
  mode='formal';
  config.schema = 'I93_CURVED_P2_V1';
  config.model = model;
  config.window = window;
  config.mesh = struct('half_cells',6,'subdivisions',12,'interface_segments',80, ...
    'quadrature_order',8,'coordinate_tolerance',1e-11,'ring_scale',0.15, ...
    'grid_clearance_fraction',0.30);
  config.solver = struct('shift_count',3,'requested',12,'tolerance',1e-10, ...
    'max_iterations',1000,'subspace',40,'seed',193,'imaginary_tolerance',1e-10);
  mu_window = config.window.^2;
  config.solver.shifts_mu = mu_window(1) + ((1:3)-0.5)/3*diff(mu_window);
  config.selection = struct('residual_max',1e-8,'center_mass_min',0.15, ...
    'core_mass_min',0.60,'end_mass_max',0.02,'end_cells',2, ...
    'dedup_k',1e-6,'dedup_overlap',0.90);
  config.resources = struct('hard_seconds',2400,'rss_bytes',3e9, ...
    'sample_seconds',1,'threads',11);
  config.mode = mode;
end

function config=LOCAL_native(model,group)
  % Input: explicit model and mesh group. Output: copied FEM/DtN options.
  config.schema = 'I102_REFINE_V1';
  config.mode = 'formal';
  config.group = group;
  % Physical model (identical to I9.5b): beta-quasi-periodic in y, d = L = 1,
  % centre five-lobe star rho=4 (unscaled), left/right different trilobes
  % rho=17, background rho=1.
  config.model = model;
  % Given original candidate (I9.5b attempt-1/run-02 fine-q12), explicit scalar.
  config.k0 = NaN;
  config.mu0 = config.k0^2;
  config.k0_source = 'in-memory wide-window P2 result';
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
  config.expected_mesh = struct();
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
