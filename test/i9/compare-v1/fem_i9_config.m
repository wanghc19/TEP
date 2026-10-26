function config = fem_i9_config(mode)
%FEM_I9_CONFIG Freeze the one I9.3 FEM configuration and an implementation probe.
% Purpose: Supply every physical, spatial, solver, filter and resource input.
% Based on: I9.1 model and I4.1c curved-P2 weak-form conventions.
% Main changes: independent trilobe leads; finite Dirichlet truncation; no BIE.
  if nargin == 0, mode = 'formal'; end
  config.schema = 'I93_CURVED_P2_V1';
  config.model = struct('beta',0.5,'d',1,'L',1,'star_scale',1, ...
    'rho_center',4,'rho_negative',17,'rho_positive',17,'rho_background',1, ...
    'a_negative',0.12,'a_positive',0.20,'radius',0.2);
  config.window = [1.4509999999999998,2.2490000000000001];
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
  if startsWith(mode,'e2')
    % I9.5 design 6.2 (E.2): jointly refined native FEM, one local shift.
    % N=8 cells per side, h=1/24, 160 interface segments; other mesh rules,
    % quadrature, gates and seed are unchanged. 'e2smoke' is a debug probe only.
    k_old = 1.5584630910866906;               % historical I9.3 candidate
    config.mesh.half_cells = 8;
    config.mesh.subdivisions = 24;
    config.mesh.interface_segments = 160;
    config.solver.shifts_mu = k_old^2+0.01;    % sigma = k_old^2 + 0.01
    config.solver.shift_count = 1;
    config.solver.requested = 3;
    config.solver.subspace = 20;
    if strcmp(mode,'e2smoke')
      config.mesh.half_cells = 2;              % smallest domain holding the tail reference cells
      config.mesh.subdivisions = 6;
      config.mesh.interface_segments = 40;
      config.selection.center_mass_min = 0;    % locality gates relaxed for the probe only
      config.selection.core_mass_min = 0;
      config.selection.end_mass_max = 1;
    else
      assert(strcmp(mode,'e2'),'i93:Mode','E.2 modes are e2 or e2smoke.');
    end
  elseif strcmp(mode,'preflight')
    config.mesh.half_cells = 1;
    config.mesh.subdivisions = 6;
    config.mesh.interface_segments = 40;
    config.solver.shifts_mu = mean(mu_window);
    config.solver.shift_count = 1;
    config.solver.requested = 3;
    config.solver.subspace = 20;
  else
    assert(strcmp(mode,'formal'),'i93:Mode','Mode must be formal or preflight.');
  end
end
