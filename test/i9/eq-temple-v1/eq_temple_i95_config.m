function config = eq_temple_i95_config(mode)
%EQ_TEMPLE_I95_CONFIG Frozen parameters for s-eq-temple steps 0-1 on the I9.3 field.
% Purpose: Supply every scientific and runtime parameter; no FEM solve or search.
% Notes: mode 'smoke' only shrinks quadrature/subdivision for a debugging probe.
%   Modes 'e2'/'e2smoke' configure the I9.5 design-6 joint-refinement chain.
  if nargin == 0, mode = 'formal'; end
  config.mode = mode;
  config.k_h = 1.5584630910866906;          % frozen I9.3 candidate
  config.mu_h = config.k_h*config.k_h;
  config.beta = 0.5;
  config.rho_min = 1;
  config.candidate_index = 1;
  config.s_factors = [0.5,1,2];             % s = factor*mu_h, s-eq-temple Section 4.4
  config.theta = 1;                          % (x+y)^2 <= (1+theta)x^2+(1+1/theta)y^2
  config.gamma_factor = 2;                   % gamma = gamma_factor*C_end^2
  config.lambda_plus = [2.1875^2,4,3];       % one-sided gap upper ends, Section 6.4
  config.lambda_minus = 1.4509999999999998^2;% lower window edge, Corollary C2 diagnostic
  config.edge_moment_order = 12;             % I9.4 witness interpolation
  config.volume_moment_order = 8;
  config.element_order = 10;                 % smooth element Grams (Duffy)
  config.assembly_leaf_order = 4;            % true-material leaf data for assembly only
  config.evaluation_order = 10;              % formal direct Theorem B evaluation
  config.check_order = 8;                    % quadrature diagnostic of the main flux
  config.end_order = 20;
  config.curve_segments = 8192;
  config.maximum_subdivision = 6;
  config.batch_size = 16384;
  config.material_candidates = [1,4,17];
  config.radius_reference = [0.01,1e-4];
  config.threads = 11;
  config.status = 'UNCERTIFIED_ORDINARY_ARITHMETIC_ESTIMATE';
  if strcmp(mode,'smoke')
    config.s_factors = 1;
    config.element_order = 6;
    config.assembly_leaf_order = 3;
    config.evaluation_order = 4;
    config.check_order = 3;
    config.maximum_subdivision = 2;
    config.curve_segments = 2048;
  elseif startsWith(mode,'e2')
    config=LOCAL_e2(config,mode);
  else
    assert(strcmp(mode,'formal'),'i95:Mode','Mode must be formal, smoke, e2 or e2smoke.');
  end
end

function config=LOCAL_e2(config,mode)
% I9.5 design 6 (E.2): one new FEM candidate, new-frequency finite tail, one
% unweighted condensed RT2 flux at m=mu_h^new, s=m/2, direct Q10 and Q8 passes.
% The candidate k_h, mu_h and s are filled at run time from the new FEM result.
  config.k_h = NaN; config.mu_h = NaN;
  config.k_old = 1.5584630910866906;          % historical I9.3 candidate (reference only)
  config.candidate_k_window = 0.01;           % unique gated root with |k-k_old|<=0.01
  config.fem = struct('half_cells',8,'subdivisions',24,'interface_segments',80*2);
  config.tail = [1,12];                       % glue_cell, tail_cells per side (x=+-13.5)
  config.s_factors = 0.5;                     % s = m/2
  config.gamma_factor = 2;                    % gamma = 2*C_end^2 (end flux kept and paid)
  config.lambda_plus = 2.1875^2;              % conditional Temple only; H+ unverified
  config.element_order = 10;                  % smooth element blocks (flux construction)
  config.assembly_leaf_order = 4;             % true-material leaf blocks (flux construction)
  config.evaluation_order = 10;               % final direct two-pass evaluation
  config.check_order = 8;                     % paired direct two-pass check
  config.end_order = 20; config.check_end_order = 16;
  config.curve_segments = 8192; config.maximum_subdivision = 6;
  config.batch_size = 4096;                   % final leaf batch (memory only)
  config.element_block = 2048;                % element block for partition/assembly (memory only)
  config.trace_tolerance = 1e-10;             % scaled internal/QP normal-trace defect gate
  config.tail_tolerance = 1e-10;              % scaled tail match/merge gate
  config.condensed_tolerance = 1e-8;          % condensed solve and recovered residual gate
  config.condense_check = false;              % uncondensed comparison (smoke only)
  config.rss_warning_bytes = 2.7e9;           % refuse factorization above this estimate
  % Historical baselines (I9.5 run-03 LS and D.1 run-01 MM; comparison only).
  config.history = struct('R_ls_q10',0.015193834057524306,'R_ls_q8',0.015192472910847151, ...
    'R_mm_q10',0.015155221757483163,'R_mm_q8',0.015153489645599538, ...
    'x_T_mm_q10',1.592524246670335e-04,'k_bie',1.5584378941820909);
  if strcmp(mode,'e2smoke')
    config.fem = struct('half_cells',2,'subdivisions',6,'interface_segments',40);
    config.element_order = 6; config.assembly_leaf_order = 3;
    config.evaluation_order = 4; config.check_order = 3;
    config.maximum_subdivision = 2; config.curve_segments = 2048;
    config.condense_check = true;
    config.candidate_k_window = 0.2;          % coarse probe mesh only
  else
    assert(strcmp(mode,'e2'),'i95:Mode','E.2 modes are e2 or e2smoke.');
  end
end
