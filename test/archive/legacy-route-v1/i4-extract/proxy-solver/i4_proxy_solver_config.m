function config = i4_proxy_solver_config()
%I4_PROXY_SOLVER_CONFIG Return frozen settings for the cheap solver audit.
%
% Purpose:
%   Define the canonical proxy systems, SVD cutoff sweep, independent point
%   references, acceptance gates, and runtime budget without changing the
%   package constructor.
%
% Output:
%   config - Frozen experiment settings.

  here = fileparts(mfilename('fullpath'));
  config.here = here;
  config.extract_root = fileparts(here);
  config.repo_root = fileparts(fileparts(fileparts(here)));
  config.output_dir = fullfile(config.extract_root, 'output', 'proxy-solver');

  config.d = 1.0;
  config.beta = 0.5;
  config.k = 1.8603695988;
  config.H = 1.1;
  config.proxy_dist = 0.7;
  config.X_R = 0.5;
  config.delta = [0.30, 0.20, 0.10];
  config.source_y = 0.137;
  config.target_y = 0.071;

  config.levels(1) = LOCAL_level('high', 120, 120, 64, 24, 720, 354);
  config.levels(2) = LOCAL_level('higher', 160, 160, 80, 32, 960, 450);

  config.tau = [1e-16, 3e-16, 1e-15, 3e-15, 1e-14, 3e-14, ...
    1e-13, 3e-13, 1e-12, 3e-12, 1e-11, 1e-10];
  config.selected_tau = 3e-16;
  config.spectral_M = [48, 96];
  config.ewald_low = struct('a', 2, 'M1', 18, 'M2', 12, 'N', 20);
  config.ewald_high = struct('a', 2, 'M1', 26, 'M2', 18, 'N', 28);

  config.gate.reference_eligibility = 5e-12;
  config.gate.rebuild_reproduction = 5e-13;
  config.gate.same_backend_default = 5e-13;
  config.gate.point_error = 2e-9;
  config.gate.residual_floor = 1e-13;
  config.gate.residual_factor = 1.05;
  config.gate.adjacent_tau_change = 5e-10;
  config.gate.norm_factor = 10;
  config.gate.cross_level_change = 2e-9;
  config.gate.near_solver_agreement = 5e-10;
  config.gate.cutoff_improvement = 20;
  config.gate.contribution_improvement = 5;

  config.expected_runtime_seconds = 60;
  config.hard_runtime_seconds = 300;
end

function level = LOCAL_level(label, n_side, n_top, n_proxy_edge, m_pw, ...
    expected_m, expected_n)
  level.label = label;
  level.N_side = n_side;
  level.N_top = n_top;
  level.N_proxy_edge = n_proxy_edge;
  level.M_pw = m_pw;
  level.expected_m = expected_m;
  level.expected_n = expected_n;
end
