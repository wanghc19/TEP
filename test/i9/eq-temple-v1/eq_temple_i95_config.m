function config = eq_temple_i95_config(mode)
%EQ_TEMPLE_I95_CONFIG Frozen parameters for s-eq-temple steps 0-1 on the I9.3 field.
% Purpose: Supply every scientific and runtime parameter; no FEM solve or search.
% Notes: mode 'smoke' only shrinks quadrature/subdivision for a debugging probe.
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
  else
    assert(strcmp(mode,'formal'),'i95:Mode','Mode must be formal or smoke.');
  end
end
