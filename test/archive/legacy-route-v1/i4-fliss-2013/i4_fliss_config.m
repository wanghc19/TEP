function config = i4_fliss_config(profile)
% I4_FLISS_CONFIG Return the frozen dual-track experiment configuration.
%
% Purpose:
%   Define separate parameter namespaces for the exact smooth Fliss finite-
%   difference control and the sharp-disk boundary-integral diagnostic.
%
% Input:
%   profile - Either 'pilot' or 'baseline'.
%
% Output:
%   config - Frozen parameters, tolerances, runtime cap, and model labels.
%
% Notes:
%   The two model_id values deliberately differ.  Downstream code must not
%   pool their numerical errors or describe the BIE diagnostic as a
%   reproduction of the smooth Fliss medium.

  if nargin < 1 || isempty(profile)
    profile = 'pilot';
  end
  if isstring(profile)
    profile = char(profile);
  end
  if ~ischar(profile) || ...
      ~(strcmp(profile, 'pilot') || strcmp(profile, 'baseline'))
    error('i4_fliss_config:InvalidProfile', ...
      'profile must be either ''pilot'' or ''baseline''.');
  end

  config.experiment_id = 'i4-fliss-2013-dual-track-v1';
  config.profile = profile;
  config.schema_version = 1;
  config.random_seed = 0;
  config.max_runtime_seconds = 10800;
  config.command = sprintf([ ...
    'perl -e ''alarm shift; exec @ARGV'' %d conda run -n octave ', ...
    'octave --quiet --no-gui --eval "addpath(''%%s''); ', ...
    'results=run_i4_fliss_experiment(''%s'');"'], ...
    config.max_runtime_seconds, profile);

  % --- exact smooth finite-difference track ---

  exact.model_id = 'fliss-smooth-fd-v1';
  exact.claim_scope = 'discrete-positive-control';
  exact.period_x = 1;
  exact.period_y = 1;
  exact.gaussian_amplitude = 16;
  exact.gaussian_width = 0.2;
  exact.beta = [0.5, 1.42];
  exact.case_name = {'strong-control', 'weak-control'};
  exact.control_role = {'primary-paper-gate', 'diagnostic-only'};
  exact.reference_omega2 = [3.465, 10.46];
  exact.prose_beta_conflict = 1.9;
  exact.tail_cells_each_side = [8, 12];
  exact.negative_tail_cells = 8;
  exact.reference_relative_tolerance = [0.02, 0.20];
  exact.minimum_center_fraction = [0.08, 0.025];
  exact.maximum_end_fraction = [0.08, 0.16];
  exact.no_defect_center_fraction_max = 0.25;
  exact.primary_tail_relative_shift_tolerance = 1e-3;
  exact.tail_mass_overlap_tolerance = [0.95, 0.90];
  exact.maximum_adjacent_edge_uncertainty = 1e-3;
  exact.minimum_gap_uncertainty_factor = 20;
  exact.minimum_margin_uncertainty_factor = 10;
  exact.eigs_max_iterations = 1500;
  exact.contrast_continuation_run = false;

  if strcmp(profile, 'pilot')
    exact.points_per_cell = 24;
    exact.theta_count = 25;
    exact.num_bands = 12;
    exact.strip_nev = 6;
    exact.eigs_tolerance = 1e-8;
    exact.residual_tolerance = 5e-7;
  else
    exact.points_per_cell = 80;
    exact.spatial_coarse_points_per_cell = 40;
    exact.theta_count = 81;
    exact.num_bands = 18;
    exact.strip_nev = 8;
    exact.eigs_tolerance = 1e-10;
    exact.residual_tolerance = 5e-8;
  end
  config.exact = exact;

  % --- sharp-disk BIE diagnostic track ---

  bie.model_id = 'sharp-disk-bie-diagnostic-v1';
  bie.claim_scope = 'real-axis-singular-value-diagnostic-only';
  bie.root_claim_allowed = false;
  bie.period_x = 1;
  bie.period_y = 1;
  bie.radius = 0.2;
  bie.beta = exact.beta;
  bie.case_name = exact.case_name;
  bie.reference_omega2 = exact.reference_omega2;
  bie.reference_k = sqrt(exact.reference_omega2);
  bie.k_windows = [1.55, 2.15; 2.90, 3.55];
  % Contrast homotopy: n(s)^2 = 1 + 16*s.  The required continuation starts
  % at s=1 and proceeds toward weaker contrast; s=0 is a negative control.
  if strcmp(profile, 'pilot')
    bie.s_values = [1, 0.5];
    bie.ntot = 32;
    bie.M = 6;
    bie.num_k = 17;
    bie.num_refine = 7;
    bie.proxy.N_side = 32;
    bie.proxy.N_top = 32;
    bie.proxy.N_proxy_edge = 20;
    bie.proxy.M_pw = 8;
  else
    bie.s_values = [1, 0.75, 0.5, 0.25];
    bie.ntot = 60;
    bie.M = 10;
    bie.num_k = 49;
    bie.num_refine = 9;
    bie.proxy.N_side = 60;
    bie.proxy.N_top = 60;
    bie.proxy.N_proxy_edge = 36;
    bie.proxy.M_pw = 14;
  end
  bie.eps_k = 0;
  bie.unit_tol = 1e-4;
  bie.lambda_tol = 1e-9;
  bie.proxy.proxy_dist = 0.7;
  bie.proxy.padding = 0.4;
  bie.normalized_sigma_warning = 1e-8;
  bie.bloch_residual_tolerance = 1e-8;
  config.bie = bie;

  config.comparison_scope = 'side-by-side-only';
end
