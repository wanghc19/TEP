function cfg = zoom2_cfg()
%ZOOM2_CFG Return the frozen I1-K-SCAN-ZOOM-V2 experiment settings.
% Purpose:
%   Define the independent quarter-grid zoom contract without changing v1.

  cfg = scan_cfg();
  cfg.zoom2_schema = 'TEP_MC_ZOOM_V2';
  cfg.zoom2_experiment_id = 'I1-K-SCAN-ZOOM-V2';
  cfg.scientific_parent_stage = 'confirm48';
  cfg.scientific_parent_status = ...
    'M48_DISCRETE_REAL_AXIS_CANDIDATE_RECORDED';
  cfg.scientific_parent_token = ...
    'd11ecd7a69f85f07f481177219cee926a64527a5b792ce0f570a3084820a43c2';
  cfg.parent_candidate_k = 1.83125;
  cfg.pivot_seed_k = 1.8375;
  cfg.initial_interval = [1.825,1.8375];
  cfg.initial_width = 0.0125;
  cfg.zoom_M = 48;
  cfg.first_level = 0;
  cfg.max_level = 14;
  cfg.width_tol = 1e-6;
  cfg.parent_score_match_tol = 1e-10;
  cfg.score_ratio_max = 2.0;
  cfg.r12_zoom_max = 0.1;
  cfg.magnitude_tol = 1e-3;
  cfg.plateau_relative_tol = 0.1;
  cfg.prominence_is_gate = false;
  cfg.hard_seconds = 600;
  cfg.active_node_limit = 5;
  cfg.active_memory_mib = 512;
  cfg.failure_allowlist = {'SCIENTIFIC_GATE','UNBRACKETED_ENDPOINT', ...
    'NONUNIQUE_MINIMUM','COARSE_FINE_DRIFT','MAX_LEVEL','HARD_TIME'};
end
