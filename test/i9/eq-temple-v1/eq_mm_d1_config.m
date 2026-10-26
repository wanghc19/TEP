function config = eq_mm_d1_config(mode)
%EQ_MM_D1_CONFIG Frozen parameters of the plan-D.1 fixed-tail flux comparison.
% Purpose: Supply every scientific and runtime parameter of eq_mm_d1: the
%   frozen I9.5 run-03 finite-tail field, the reused unweighted_s0.5 flux, one
%   pure L2 projection diagnostic, at most three smoothed MM steps and the
%   paired direct Q10/Q8 evaluation. No FEM solve, candidate search or sweep.
% Notes: mode 'smoke' only shrinks quadrature/subdivision for a debugging
%   probe; smoke output is never a scientific result.
  if nargin == 0, mode = 'formal'; end
  config.mode = mode;
  % --- frozen candidate and model (I9.3 run-02, I9.5 run-03) ---
  config.k_h = 1.5584630910866906;            % frozen I9.3 candidate
  config.mu_h = config.k_h*config.k_h;
  config.beta = 0.5;
  config.rho_min = 1;
  config.candidate_index = 1;
  config.s = config.mu_h/2;                     % shift s = mu_h/2, as run-03 best
  config.tail = [1,12];                         % glue_cell, tail_cells of run-03
  config.expected_elements = 20264;
  config.expected_ndof = 212808;
  % Residual parameter m of the cache, MM and direct evaluation: the run-03
  % same-rule Rayleigh quotient. The final formulas pay |mu_R-m| by C3 (12).
  config.m_residual = 2.4287910444662266;
  config.baseline_name = 'unweighted_s0.5';
  config.lambda_plus = 2.1875^2;                % only gap end, H+ unverified
  config.radius_reference = [0.01,1e-4];        % reading scales, not stop gates
  % --- quadrature and true-material classification (unchanged from I9.5) ---
  config.cache_order = 10;                      % same reference-leaf Q10 for all MM blocks
  config.evaluation_order = 10;                 % direct two-pass evaluation
  config.check_order = 8;                       % paired sensitivity pass
  config.end_order = 20;                        % artificial end Gauss order with Q10
  config.check_end_order = 16;                  % with Q8, as the I9.5 quadrature check
  config.curve_segments = 8192;
  config.maximum_subdivision = 6;
  config.batch_size = 16384;                    % direct evaluation batch (as I9.5)
  config.cache_batch = 2048;                    % leaves per cache batch (2 GiB tree limit)
  config.material_candidates = [1,4,17];
  % --- smoothed MM, p-next Section 5 ---
  config.smoothing_factor = 1e-6;               % eps_sm = factor*max(F(p0),1e-12)
  config.mm_max_solves = 3;                     % at most three quadratic solves
  config.backtrack = [1,1/2,1/4,1/8];           % full step, then finite backtracking
  config.solve_tolerance = 1e-8;                % relative algebraic residual gate
  % --- recovery gates (identity of the frozen object, not tuning) ---
  config.field_tolerance = 1e-12;               % relative, rebuilt vs saved tail field
  config.geometry_tolerance = 1e-14;            % absolute, mapx/mapy and leaves
  config.history_tolerance = 1e-9;              % relative, baseline direct Q10 vs run-03
  config.threads = 11;
  config.status = 'UNCERTIFIED_ORDINARY_ARITHMETIC_ESTIMATE';
  config.classification_rule = ['IMPROVED_RESOLVED only if the selected flux lowers ', ...
    'R_linear(mu_h) in both Q10 and Q8 by more than the larger Q10-Q8 difference ', ...
    'of either flux; otherwise UNRESOLVED (or NO_CHANGE / WORSE).'];
  if strcmp(mode,'smoke')
    config.cache_order = 4;
    config.evaluation_order = 4;
    config.check_order = 3;
    config.maximum_subdivision = 2;
    config.curve_segments = 2048;
  else
    assert(strcmp(mode,'formal'),'d1:Mode','Mode must be formal or smoke.');
  end
end
