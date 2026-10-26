function config = fem_dtn_i95b_config(mode)
%FEM_DTN_I95B_CONFIG Freeze every input of the I9.5b FEM+DtN candidate run.
% Purpose: Supply the physical model, the frozen coarse/fine/Q configurations,
%   mesh repair rules, per-frequency DtN gates, root-finding contract and
%   resource limits of design-9-5b (D2). Nothing here is read from documents.
% Input: mode is 'formal' (design Section 5 table), 'smoke' (s=6/12 probe),
%   'meshcheck' (formal mesh levels only) or 'smoke-entry' (probe of the D2
%   fine independent-entry path; never a scientific result).
% Output: config struct consumed by fem_dtn_i95b.
% Based on: test/i9/compare-v1/fem_i9_config.m model and mesh rules.
% Main changes: three cell templates (no finite-domain eigensolve), complete
%   discrete stable-subspace DtN, local bracketed root chains, no BIE value;
%   D2 adds the bounded local flip limits and the fine independent-entry rule.
  if nargin == 0, mode = 'formal'; end
  config.schema = 'I95B_FEM_DTN_V1';
  config.mode = mode;
  % Physical model (identical to fem_i9_config): beta-quasi-periodic in y,
  % d = L = 1, star centre rho=4, trilobe leads rho=17, background rho=1.
  config.model = struct('beta',0.5,'d',1,'L',1,'star_scale',1, ...
    'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
    'a_negative',0.12,'a_positive',0.20,'radius',0.2);
  % Local continuation start: E.2 native FEM candidate (explicit scalar input).
  config.k0 = 1.558439927483915;
  config.k0_source = 'E.2 FEM candidate (eq-temple-v1 attempt-3 run-01), explicit scalar';
  config.window = config.k0 + [-0.01,0.01];      % fixed total search window in k
  % Mesh rules: ring_scale, tolerance and 0.30h interface clearance from E.2;
  % 0.10h ring clearance, det-ratio gate and 3 repair rounds from design 5.
  config.mesh_rules = struct('ring_scale',0.15,'coordinate_tolerance',1e-11, ...
    'interface_clearance_fraction',0.30,'ring_clearance_fraction',0.10, ...
    'det_ratio_max',20,'repair_rounds',3,'curve_samples',33);
  % D2 bounded local edge flip (design 5 step 4): per mesh level at most 32
  % candidate patch checks and 16 accepted flips; all deletion/flip repair and
  % geometry re-checks of a level share 30 s. Convexity: every turn of abcd
  % exceeds 1e-12*ell^2 (ell = patch diameter). Curved-edge crossing roots
  % within 1e-9 (parameter/segment units) of a decision boundary are rejected.
  config.mesh_rules.repair_seconds = 30;
  config.mesh_rules.flip = struct('max_checks',32,'max_flips',16, ...
    'convex_factor',1e-12,'crossing_tolerance',1e-9);
  if strcmp(mode,'smoke-entry'), config.mesh_rules.flip.max_checks = 0; end
  % Frozen configurations (design Section 5). parent = initial-value source;
  % 'conditional' chains run only when |k(parent)-k(grandparent)| > q_trigger.
  names = {'coarse','fine-q10','fine-q12','fine-q16'};
  subdivisions = [24,48,48,48];
  segments = [160,320,320,320];
  orders = [10,10,12,16];
  if strcmp(mode,'smoke')
    % Operational probe only (design 7.2): s=6/n=40 coarse, s=12/n=80 fine.
    subdivisions = [6,12,12,12];
    segments = [40,80,80,80];
  elseif strcmp(mode,'smoke-entry')
    % Operational probe of the D2 fine independent-entry code path only: the
    % formal coarse level (one interface-ear bad element) with zero flip checks
    % allowed, so coarse ends LOCAL_REPAIR_LIMIT; fine levels at smoke size.
    subdivisions = [24,12,12,12];
    segments = [160,80,80,80];
  else
    % 'meshcheck': mesh/repair diagnostic of the formal levels only (no solves).
    assert(any(strcmp(mode,{'formal','meshcheck'})),'i95b:Mode', ...
      'Mode must be formal, smoke or meshcheck.');
  end
  parents = {'','coarse','fine-q10','fine-q12'};
  conditional = [false,false,false,true];
  for j = 1:4
    config.configurations(j) = struct('name',names{j},'subdivisions',subdivisions(j), ...
      'interface_segments',segments(j),'quadrature_order',orders(j), ...
      'parent',parents{j},'conditional',conditional(j), ...
      'mesh_key',sprintf('s%d-n%d',subdivisions(j),segments(j)));
  end
  config.q_trigger = 1e-8;                       % run Q16 iff |k12-k10| > 1e-8
  % D2 sole dependency exception (design 4.2): fine-q10 may start from k0 only
  % when coarse ended GEOMETRY_FAILED with a whitelisted failure_kind, passed
  % structural checks, entered the flip stage and never started assembly or a
  % frequency evaluation, and elapsed + remaining_estimate_seconds stays within
  % the soft limit. remaining_estimate_seconds = 620 is the upper end of the
  % design 7.2 rows for fine-q10 (180), fine-q12 (180), fine-q16 (200) and the
  % final checks/figures/output (60). fine-q12 and fine-q16 keep their parents.
  config.fine_entry = struct('chain','fine-q10','coarse','coarse', ...
    'failure_kinds',{{'JACOBIAN_QUALITY_UNRESOLVED','LOCAL_REPAIR_LIMIT'}}, ...
    'initialization_source','E2_AFTER_COARSE_GEOMETRY_FAILURE', ...
    'remaining_estimate_seconds',620);
  % Per-frequency cell/DtN gates (design 3.3).
  config.gates = struct('cell_backward',1e-10,'cell_condest',1e12, ...
    'qz_degenerate_factor',100,'unit_gap',1e-6,'z0_rcond',1e-10, ...
    'invariance',1e-8,'riccati',1e-8,'dtn_hermitian',1e-8, ...
    'dtn_consistency',1e-8,'consistency_rcond',1e-12,'pairing_band',1e6, ...
    'matrix_hermitian',1e-10,'qp_defect',1e-12,'h_hermitian',1e-8);
  % Branch and root contract (design 4.2).
  config.root = struct('half_widths',[2e-4,1e-3,5e-3,1e-2],'overlap_min',0.90, ...
    'select_corr_min',0.90,'gap_factor',1e-8,'max_halvings',8, ...
    'max_frequencies',60,'bracket_width',1e-10,'eig_abs',1e-10, ...
    'center_residual',1e-9,'nearest_count',5);
  % Delivery checks (design 6).
  config.delivery = struct('display_cells',4,'trace_points',201,'same_mode_corr',0.99, ...
    'recovery_residual',1e-10,'continuity',1e-10,'qp',1e-12,'load_balance',1e-8);
  % Linear algebra and resources: multi-RHS blocks of 32 columns, 11 threads,
  % internal memory gate below the 3e9-byte process-tree hard limit.
  config.solver = struct('rhs_block',32,'lu_fill_allowance',4);
  config.resources = struct('threads',11,'rss_bytes',3e9,'warn_bytes',2.7e9, ...
    'internal_gate_bytes',2.9e9,'soft_seconds',1800,'grace_seconds',600, ...
    'hard_seconds',2400,'save_estimate_seconds',30);
end
