function out = cfg_v4()
%CFG_V4 Return the frozen one-shot I1.4 V4 settings.
% Purpose:
%   Preserve V3 while replacing only its cancellation-dominated CR ladder.
% Output:
%   out - Immutable V4 disk, CR, domain, output, and claim settings.

  out = full_cfg();
  out.schema = 'TEP_I1_K_READY_V4';
  out.experiment_id = 'I1-K-READY-V4';
  out.claim_boundary = 'SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS';
  out.v4_radius = out.r0;
  out.v4_cr_h = out.r0*[4,2,1];
  out.v4_cr_change_tol = out.cr_tol;
  out.v4_max_shift = 4.5*out.r0;
  orders = unique([(-out.M:out.M).'; ...
    (-out.levels(1).M_pw:out.levels(1).M_pw).'; ...
    (-out.levels(2).M_pw:out.levels(2).M_pw).']);
  beta_m = out.beta+2*pi*orders/out.d;
  out.v4_branch_distance = min([abs(out.kstar-beta_m); ...
    abs(out.kstar+beta_m)]);
  out.v4_branch_factor = 8;
  out.v4_branch_domain_pass = out.v4_branch_distance > ...
    out.v4_branch_factor*out.v4_max_shift;
  out.output_name = 'v4-a1';
  out.output_relative = fullfile('output',out.output_name);
  out.target_seconds_per_attempt = 1500;
  out.hard_seconds_per_run = 1800;
  out.locator_authorized = false;
  out.contour_authorized = false;
  out.root_authorized = false;
  out.derivative_authorized = false;
  out.estimator_authorized = false;
end
