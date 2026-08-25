function cfg = zoom_cfg()
%ZOOM_CFG Return the frozen M=48 nested-grid zoom experiment settings.
% Purpose:
%   Extend the confirmed real-axis candidate with a bounded dyadic grid while
%   preserving the I1-K-SCAN-V1 model, tolerances, and parent artifacts.

  cfg = scan_cfg();
  cfg.zoom_schema = 'TEP_MC_ZOOM_V1';
  cfg.zoom_experiment_id = 'I1-K-SCAN-ZOOM-V1';
  cfg.parent_stage = 'confirm48';
  cfg.parent_status = 'M48_DISCRETE_REAL_AXIS_CANDIDATE_RECORDED';
  cfg.parent_candidate_k = 1.83125;
  cfg.pivot_seed_k = 1.8375;
  cfg.initial_bracket = [1.825,1.83125,1.8375];
  cfg.initial_h = 0.00625;
  cfg.zoom_M = 48;
  cfg.max_levels = 11;
  cfg.score_match_tol = 1e-10;
  cfg.near_zero_tol = 1e-5;
  cfg.ideal_tol = 1e-6;
  cfg.r12_zoom_max = 0.1;
  cfg.score_ratio_max = 2.0;
  cfg.nonmonotone_relative_tol = 1e-6;
  cfg.plateau_improvement_max = 0.1;
  cfg.hard_seconds = 600;
end
