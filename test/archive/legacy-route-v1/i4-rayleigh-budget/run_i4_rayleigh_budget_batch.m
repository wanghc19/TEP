function batch = run_i4_rayleigh_budget_batch(selection, aggregate_only)
% RUN_I4_RAYLEIGH_BUDGET_BATCH Run the bounded frozen I4 evidence grid.
%
% Purpose:
%   Execute or resume the low-resolution core grid, low-resolution scale
%   controls, and the three prioritized high-resolution central-k cases.
%   Write provisional per-case Rayleigh budgets while keeping every global
%   certified interval fail-closed until the reference error is closed.
%
% Input:
%   selection - One of 'all', 'all-endpoints', 'core-low',
%               'scale-controls', or 'hi-three'.  Default: 'all'.
%   aggregate_only - If true, load existing case results and mark missing
%                    cases without executing them.  Default: false.
%
% Output:
%   batch - Manifest, per-case provisional summaries, global fail-closed
%           status, elapsed time, and output directory.
%
% Main algorithm:
%   Build each physical case with disk radius R=0.5-delta.  Low core cases
%   use ntot=80/100/120 for delta=0.30/0.20/0.10, respectively, Ny=512,
%   and the low proxy.  Scale controls use the delta=0.30 low grid.  High
%   cases use ntot=160/170/180, Ny=2048, and proxy (120,120,64,24), only at
%   k=1.8603695988.  Existing results.mat files are reused for restartability.
%
% Numerical goal:
%   Finish beneath a 5400-second batch cap.  Output a provisional spectral
%   M_trace and conditional QZ/doubling M_stable for diagnosis.  Low-only
%   cases remain DESCRIPTIVE/REFERENCE_UNCERTIFIED, and even low/high pairs
%   remain INCONCLUSIVE until separate ntot, Ny, withheld, and oracle
%   reference components close the prescribed error envelope.

  if nargin < 1 || isempty(selection)
    selection = 'all';
  end
  if nargin < 2 || isempty(aggregate_only)
    aggregate_only = false;
  end
  if isstring(selection)
    selection = char(selection);
  end
  allowed = {'all', 'all-endpoints', 'core-low', ...
    'scale-controls', 'hi-three'};
  if ~ischar(selection) || ~any(strcmp(selection, allowed))
    error('run_i4_rayleigh_budget_batch:InvalidSelection', ...
      'Unknown batch selection.');
  end
  if ~(islogical(aggregate_only) && isscalar(aggregate_only))
    error('run_i4_rayleigh_budget_batch:InvalidAggregateOnly', ...
      'aggregate_only must be a logical scalar.');
  end

  here = fileparts(mfilename('fullpath'));
  batch_dir = fullfile(here, 'output', ['batch-', selection]);
  if exist(batch_dir, 'dir') ~= 7
    mkdir(batch_dir);
  end
  batch_token = tic;
  batch_cap_seconds = 5400;
  manifest = LOCAL_manifest(selection);
  summaries = repmat(LOCAL_empty_summary(), length(manifest), 1);
  run_results = cell(length(manifest), 1);
  for j = 1:length(manifest)
    summaries(j) = LOCAL_summary_from_case(manifest(j));
  end
  LOCAL_write_manifest(manifest, batch_dir);

  for j = 1:length(manifest)
    remaining = batch_cap_seconds - toc(batch_token);
    if remaining <= 1
      summaries(j).case_id = manifest(j).case_id;
      summaries(j).group = manifest(j).group;
      summaries(j).status = 'NOT_RUN_BATCH_CAP_REACHED';
      break;
    end
    fprintf('Batch case %d/%d: %s (remaining %.1f s).\n', ...
      j, length(manifest), manifest(j).case_id, remaining);
    [summaries(j), run_results{j}] = LOCAL_run_or_load_case( ...
      manifest(j), here, floor(remaining), aggregate_only);
    [summaries, run_results] = LOCAL_update_pair_summaries( ...
      summaries, run_results, manifest);
    batch = LOCAL_batch_record(selection, manifest, summaries, ...
      toc(batch_token), batch_cap_seconds, batch_dir, run_results);
    LOCAL_write_batch(batch);
    save(fullfile(batch_dir, 'batch-results.mat'), 'batch');
    if strcmp(summaries(j).status, 'FAILED_RUNTIME_CAP')
      break;
    end
  end

  [summaries, run_results] = LOCAL_update_pair_summaries( ...
    summaries, run_results, manifest); %#ok<ASGLU>
  batch = LOCAL_batch_record(selection, manifest, summaries, ...
    toc(batch_token), batch_cap_seconds, batch_dir, run_results);
  LOCAL_write_batch(batch);
  save(fullfile(batch_dir, 'batch-results.mat'), 'batch');
end

%% ==================== Frozen batch manifest ====================
% These helpers encode the approved physical and discretization grids.

function manifest = LOCAL_manifest(selection)
  manifest = repmat(LOCAL_empty_case(), 0, 1);
  include_core = any(strcmp(selection, {'all', 'all-endpoints', 'core-low'}));
  include_controls = any(strcmp(selection, ...
    {'all', 'all-endpoints', 'scale-controls'}));
  include_hi = any(strcmp(selection, {'all', 'all-endpoints', 'hi-three'}));
  if include_core
    deltas = [0.30, 0.20, 0.10];
    wavenumbers = [1.45, 1.65, 1.8603695988, 2.05, 2.25];
    ntot_values = [80, 100, 120];
    for d = 1:length(deltas)
      for k = 1:length(wavenumbers)
        manifest(end + 1, 1) = LOCAL_case('core-low', deltas(d), ...
          wavenumbers(k), 'low', ntot_values(d), 512); %#ok<AGROW>
      end
    end
  end
  if include_controls
    control_k = [0.1, 1, 4];
    for k = 1:length(control_k)
      manifest(end + 1, 1) = LOCAL_case('scale-control', 0.30, ...
        control_k(k), 'low', 80, 512); %#ok<AGROW>
    end
  end
  if include_hi
    hi_deltas = [0.30, 0.10, 0.20];
    hi_ntot = [160, 180, 170];
    if strcmp(selection, 'all-endpoints')
      hi_deltas = hi_deltas(1:2);
      hi_ntot = hi_ntot(1:2);
    end
    for d = 1:length(hi_deltas)
      manifest(end + 1, 1) = LOCAL_case('central-hi', hi_deltas(d), ...
        1.8603695988, 'high', hi_ntot(d), 2048); %#ok<AGROW>
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function item = LOCAL_case(group, delta, k, resolution, ntot, Ny_wall)
  item = LOCAL_empty_case();
  item.group = group;
  item.delta = delta;
  item.radius = 0.5 - delta;
  item.k = k;
  item.resolution = resolution;
  item.ntot = ntot;
  item.Ny_wall = Ny_wall;
  item.case_id = LOCAL_case_id(group, delta, k, resolution);
  item.output_label = ['batch-case-', item.case_id];
  if strcmp(resolution, 'high')
    item.proxy_N_side = 120;
    item.proxy_N_top = 120;
    item.proxy_N_proxy_edge = 64;
    item.proxy_M_pw = 24;
  else
    item.proxy_N_side = 80;
    item.proxy_N_top = 80;
    item.proxy_N_proxy_edge = 44;
    item.proxy_M_pw = 16;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function case_id = LOCAL_case_id(group, delta, k, resolution)
  delta_text = strrep(sprintf('%.2f', delta), '.', 'p');
  k_text = strrep(sprintf('%.10g', k), '.', 'p');
  k_text = strrep(k_text, '+', 'p');
  case_id = sprintf('%s-d%s-k%s-%s', group, delta_text, k_text, resolution);
end

%% ==================== Restartable case execution ====================
% These helpers call the single-master runner and preserve partial progress.

function [summary, results] = LOCAL_run_or_load_case(item, here, remaining, ...
    aggregate_only)
  summary = LOCAL_summary_from_case(item);
  results = [];
  result_path = fullfile(here, 'output', item.output_label, 'results.mat');
  try
    if exist(result_path, 'file') == 2
      saved = load(result_path, 'results');
      results = saved.results;
      summary.execution = 'REUSED_EXISTING_RESULT';
    elseif aggregate_only
      summary.status = 'MISSING_RESULT_AGGREGATE_ONLY';
      summary.execution = 'NOT_EXECUTED';
      return;
    else
      overrides.delta = item.delta;
      overrides.radius = item.radius;
      overrides.k = item.k;
      overrides.ntot = item.ntot;
      overrides.Ny_wall = item.Ny_wall;
      overrides.M_in = 20;
      overrides.M_out = 70;
      overrides.square_M_values = 0:20;
      overrides.square_reference_M = 20;
      overrides.doubling_levels = 0:8;
      overrides.max_runtime_seconds = max(1, remaining);
      overrides.proxy.N_side = item.proxy_N_side;
      overrides.proxy.N_top = item.proxy_N_top;
      overrides.proxy.N_proxy_edge = item.proxy_N_proxy_edge;
      overrides.proxy.M_pw = item.proxy_M_pw;
      overrides.proxy.H = 0.5 + item.radius + 0.4;
      results = run_i4_rayleigh_budget('core', overrides, ...
        item.output_label);
      summary.execution = 'EXECUTED';
    end
    summary = LOCAL_summarize_result(summary, results);
  catch ME
    summary.status = 'FAILED';
    if strcmp(ME.identifier, 'run_i4_rayleigh_budget:RuntimeCap')
      summary.status = 'FAILED_RUNTIME_CAP';
    end
    summary.error_id = ME.identifier;
    summary.error_message = strrep(ME.message, sprintf('\n'), ' ');
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function summary = LOCAL_summarize_result(summary, results)
  summary.status = 'COMPLETED_REFERENCE_UNCERTIFIED';
  summary.elapsed_seconds = results.elapsed_seconds;
  summary.extractor_validation_error = ...
    results.rectangular.extractor_validation_error;
  summary.extractor_validation_pass = ...
    results.rectangular.extractor_validation_pass;
  summary.provisional_M_trace = LOCAL_provisional_M_trace(results);
  summary.M_trace_spec_candidate = summary.provisional_M_trace;
  if isnan(summary.provisional_M_trace)
    summary.provisional_M_trace_status = ...
      'PROVISIONAL_SPECTRAL_TAIL_NOT_REACHED';
  else
    summary.provisional_M_trace_status = ...
      'PROVISIONAL_SPECTRAL_ONLY_REFERENCE_UNCERTIFIED';
  end
  [summary.map_pass_through, summary.map_pass_through_status, ...
    summary.map_pass_through_right_censored] = ...
    LOCAL_map_pass_through(results);
  [summary.M_action_onset, summary.M_action_onset_status] = ...
    LOCAL_action_onset(results);
  summary.prefix_protocol_M_stable = ...
    LOCAL_single_run_M_stable(results);
  summary.single_run_conditional_M_stable = ...
    summary.prefix_protocol_M_stable;
  summary.conditional_M_stable = summary.prefix_protocol_M_stable;
  if isnan(summary.conditional_M_stable)
    summary.conditional_M_stable_status = ...
      'PREFIX_PROTOCOL_OUTCOME_NA_NO_ALGORITHM_FAILURE_CLAIM';
  else
    summary.conditional_M_stable_status = ...
      'PREFIX_PROTOCOL_SINGLE_RESOLUTION_ONLY';
  end
  if strcmp(summary.group, 'scale-control')
    summary.reference_status = 'SCALE_CONTROL_REFERENCE_UNCERTIFIED';
  elseif strcmp(summary.resolution, 'low')
    summary.reference_status = 'DESCRIPTIVE/REFERENCE_UNCERTIFIED';
  else
    summary.reference_status = 'REFERENCE_PAIR_NOT_AVAILABLE';
  end
  summary.ntot_action_onset_status = 'NTOT_ACTION_PAIR_NOT_AVAILABLE';
  summary.usable_window_status = ...
    'NOT_OBSERVED_NTOT_ACTION_ONSET_UNAVAILABLE';
end

%% ==================== Provisional budget diagnostics ====================
% These helpers compute explicitly non-certified per-case summaries.

function M_trace = LOCAL_provisional_M_trace(results)
  M_trace = NaN;
  tails = results.rectangular.tail;
  for j = 1:length(tails)
    if tails(j).spectral_tail_max <= results.config.trace_tail_tolerance
      M_trace = tails(j).M;
      return;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pass_through, status, right_censored] = ...
    LOCAL_map_pass_through(results)
  available_M = [results.square.M];
  gates = false(size(available_M));
  for j = 1:length(results.square)
    gates(j) = LOCAL_same_M_gate(results.square(j), results.config);
  end
  [pass_through, reached_limit] = LOCAL_prefix_pass_through( ...
    available_M, gates);
  right_censored = reached_limit && ~isnan(pass_through);
  if isnan(pass_through)
    status = 'NO_PASS_THROUGH_M5_FAILED_OR_UNAVAILABLE';
  elseif right_censored
    status = 'RIGHT_CENSORED_PASS_THROUGH_TESTED_UPPER_BOUND';
  else
    status = 'PASS_THROUGH_ENDS_BEFORE_FIRST_SAME_M_FAILURE';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [onset, status] = LOCAL_action_onset(results)
  available_M = [results.square.M];
  gates = false(size(available_M));
  for j = 1:length(results.square)
    gates(j) = LOCAL_action_reference_gate(results.square(j), ...
      results.config);
  end
  upper_index = find(available_M == max(available_M), 1);
  upper_same_M_pass = ~isempty(upper_index) && ...
    LOCAL_same_M_gate(results.square(upper_index), results.config);
  onset = LOCAL_sustained_onset(available_M, gates, upper_same_M_pass);
  if isnan(onset)
    status = 'ACTION_ONSET_NOT_OBSERVED';
  else
    status = 'ACTION_ONSET_OBSERVED_TO_TESTED_UPPER_BOUND';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function M_stable = LOCAL_single_run_M_stable(results)
  M_stable = NaN;
  available_M = [results.square.M];
  if ~any(available_M >= 5)
    return;
  end
  for M = 5:max(available_M)
    index = find(available_M == M, 1);
    if isempty(index) || ...
        ~LOCAL_prefix_protocol_gate(results.square(index), results.config)
      return;
    end
    M_stable = M;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_same_M_gate(sample, config)
  q = sample.qz;
  final = LOCAL_last_doubling(sample.doubling);
  perturbation_pass = ~isempty(sample.perturbation) && ...
    all([sample.perturbation.pass]);
  qz_residual = max([q.stable.residual_A, q.stable.residual_B, ...
    q.unstable.residual_A, q.unstable.residual_B, ...
    q.graph_residual_plus, q.graph_residual_minus, ...
    q.fixed_residual_plus, q.fixed_residual_minus, ...
    q.fixed_solve_plus, q.fixed_solve_minus, ...
    q.cayley_residual_plus, q.cayley_residual_minus]);
  final_action = max([final.DtN_action_error_right, ...
    final.DtN_action_error_left, final.reflection_error_right, ...
    final.reflection_error_left]);
  final_residual = max([final.cayley_residual_right, ...
    final.cayley_residual_left]);
  pass = strcmp(sample.status, ...
    'TIMING_EVIDENCE_RECORDED_NO_M_STABLE_DECISION') && ...
    sample.cell_solve_relative_residual <= config.BIE_residual_tolerance && ...
    q.available && q.stable_count == sample.K && ...
    q.unstable_count == sample.K && q.neutral_count == 0 && ...
    q.indeterminate_count == 0 && ...
    qz_residual <= config.qz_residual_tolerance && ...
    min(q.rcond_A_stable, q.rcond_B_unstable) >= config.qz_rcond_floor && ...
    final_action <= config.doubling_action_tolerance && ...
    final_residual <= config.qz_residual_tolerance && perturbation_pass;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_action_reference_gate(sample, config)
  reference_action = max([sample.qz_reference_DtN_action_error_plus, ...
    sample.qz_reference_DtN_action_error_minus]);
  pass = sample.qz_reference_available && ...
    reference_action <= config.doubling_action_tolerance;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pass = LOCAL_prefix_protocol_gate(sample, config)
  pass = LOCAL_same_M_gate(sample, config) && ...
    LOCAL_action_reference_gate(sample, config);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [pass_through, reached_limit] = LOCAL_prefix_pass_through( ...
    available_M, gates)
  pass_through = NaN;
  reached_limit = false;
  if ~any(available_M >= 5)
    return;
  end
  upper_M = max(available_M);
  for M = 5:upper_M
    index = find(available_M == M, 1);
    if isempty(index) || ~gates(index)
      return;
    end
    pass_through = M;
  end
  reached_limit = ~isnan(pass_through) && pass_through == upper_M;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function onset = LOCAL_sustained_onset(available_M, gates, upper_gate)
  onset = NaN;
  if ~upper_gate || ~any(available_M >= 5)
    return;
  end
  upper_M = max(available_M);
  for candidate = 5:upper_M
    pass = true;
    for M = candidate:upper_M
      index = find(available_M == M, 1);
      if isempty(index) || ~gates(index)
        pass = false;
        break;
      end
    end
    if pass
      onset = candidate;
      return;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_last_doubling(rows)
  row = struct('DtN_action_error_right', NaN, ...
    'DtN_action_error_left', NaN, 'reflection_error_right', NaN, ...
    'reflection_error_left', NaN, 'cayley_residual_right', NaN, ...
    'cayley_residual_left', NaN);
  if ~isempty(rows)
    row = rows(end);
  end
end

%% ==================== Low/high pair comparison ====================
% These helpers add combined-resolution evidence but never certify it.

function [summaries, run_results] = LOCAL_update_pair_summaries( ...
    summaries, run_results, manifest)
  for j = 1:length(manifest)
    if ~strcmp(manifest(j).resolution, 'high') || isempty(run_results{j})
      continue;
    end
    low_index = find(strcmp({manifest.resolution}, 'low') & ...
      strcmp({manifest.group}, 'core-low') & ...
      abs([manifest.delta] - manifest(j).delta) <= 10 * eps & ...
      abs([manifest.k] - manifest(j).k) <= 10 * eps, 1);
    if isempty(low_index) || isempty(run_results{low_index})
      continue;
    end
    low = run_results{low_index};
    high = run_results{j};
    summaries(j).M_trace_spec_candidate = max([ ...
      summaries(low_index).M_trace_spec_candidate, ...
      summaries(j).M_trace_spec_candidate]);
    if isnan(summaries(low_index).M_action_onset) || ...
        isnan(summaries(j).M_action_onset)
      summaries(j).M_action_onset = NaN;
      summaries(j).M_action_onset_status = ...
        'PAIRED_ACTION_ONSET_NOT_OBSERVED';
    else
      summaries(j).M_action_onset = max([ ...
        summaries(low_index).M_action_onset, summaries(j).M_action_onset]);
      summaries(j).M_action_onset_status = ...
        'PAIRED_ACTION_ONSET_OBSERVED_TO_TESTED_UPPER_BOUND';
    end
    summaries(j).combined_spectral_tail_change = ...
      LOCAL_trace_tail_change(low, high);
    [paired_M, prefix_endpoint_change, grid_change, ntot_onset, ...
      paired_pass_through, paired_right_censored] = ...
      LOCAL_pair_M_stable(low, high);
    summaries(j).paired_conditional_M_stable = paired_M;
    summaries(j).prefix_protocol_M_stable = paired_M;
    summaries(j).paired_action_change_at_prefix_endpoint = ...
      prefix_endpoint_change;
    summaries(j).paired_action_change_max_grid = grid_change;
    summaries(j).ntot_action_onset = ntot_onset;
    summaries(j).ntot_action_change_at_onset = ...
      LOCAL_pair_action_change_at_M(low, high, ntot_onset);
    if isnan(ntot_onset)
      summaries(j).ntot_action_onset_status = ...
        'NTOT_ACTION_ONSET_NOT_OBSERVED';
    else
      summaries(j).ntot_action_onset_status = ...
        'NTOT_ACTION_ONSET_OBSERVED_TO_TESTED_UPPER_BOUND';
    end
    summaries(j).map_pass_through = paired_pass_through;
    summaries(j).map_pass_through_right_censored = paired_right_censored;
    if isnan(paired_pass_through)
      summaries(j).map_pass_through_status = ...
        'PAIRED_NO_PASS_THROUGH_M5_FAILED_OR_UNAVAILABLE';
    elseif paired_right_censored
      summaries(j).map_pass_through_status = ...
        'PAIRED_RIGHT_CENSORED_PASS_THROUGH_TESTED_UPPER_BOUND';
    else
      summaries(j).map_pass_through_status = ...
        'PAIRED_PASS_THROUGH_ENDS_BEFORE_FIRST_SAME_M_FAILURE';
    end
    summaries(j).conditional_M_stable = paired_M;
    if isnan(paired_M)
      summaries(j).conditional_M_stable_status = ...
        'PREFIX_PROTOCOL_OUTCOME_NA_NO_ALGORITHM_FAILURE_CLAIM';
    else
      summaries(j).conditional_M_stable_status = ...
        'PREFIX_PROTOCOL_LOW_HIGH_PAIR_REFERENCE_UNCERTIFIED';
    end
    summaries(j) = LOCAL_add_usable_window(summaries(j));
    summaries(j).ntot_action_change_at_M_req_candidate = ...
      LOCAL_pair_action_change_at_M(low, high, ...
      summaries(j).M_req_candidate);
    summaries(j).reference_status = ...
      'REFERENCE_NOT_CLOSED_INCONCLUSIVE';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function change = LOCAL_trace_tail_change(low, high)
  change = NaN;
  low_M = [low.rectangular.tail.M];
  high_M = [high.rectangular.tail.M];
  [common, low_indices] = ismember(high_M, low_M);
  if ~all(common)
    return;
  end
  low_values = [low.rectangular.tail(low_indices).spectral_tail_max];
  high_values = [high.rectangular.tail.spectral_tail_max];
  change = max(abs(high_values - low_values));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [M_stable, change_at_prefix_endpoint, max_grid_change, ntot_onset, ...
    paired_pass_through, paired_right_censored] = ...
    LOCAL_pair_M_stable(low, high)
  M_stable = NaN;
  change_at_prefix_endpoint = NaN;
  max_grid_change = NaN;
  ntot_onset = NaN;
  paired_pass_through = NaN;
  paired_right_censored = false;
  low_M = [low.square.M];
  high_M = [high.square.M];
  [common, low_indices] = ismember(high_M, low_M);
  if ~all(common)
    return;
  end
  gates = false(length(high.square), 1);
  same_M_gates = false(length(high.square), 1);
  ntot_gates = false(length(high.square), 1);
  changes = NaN(length(high.square), 1);
  for j = 1:length(high.square)
    low_sample = low.square(low_indices(j));
    high_sample = high.square(j);
    if ~(low_sample.qz.available && high_sample.qz.available)
      continue;
    end
    actions = LOCAL_actions(high_sample.channels, ...
      high.config.action_column_count);
    plus_change = LOCAL_weighted_action_error(high_sample.qz.DtN_plus, ...
      low_sample.qz.DtN_plus, actions, high_sample.channels);
    minus_change = LOCAL_weighted_action_error(high_sample.qz.DtN_minus, ...
      low_sample.qz.DtN_minus, actions, high_sample.channels);
    changes(j) = max(plus_change, minus_change);
    classification_preserved = ...
      low_sample.qz.stable_count == high_sample.qz.stable_count && ...
      low_sample.qz.unstable_count == high_sample.qz.unstable_count && ...
      low_sample.qz.neutral_count == high_sample.qz.neutral_count && ...
      low_sample.qz.indeterminate_count == ...
      high_sample.qz.indeterminate_count;
    same_M_gates(j) = LOCAL_same_M_gate(low_sample, low.config) && ...
      LOCAL_same_M_gate(high_sample, high.config);
    ntot_gates(j) = classification_preserved && ...
      changes(j) <= high.config.ntot_action_tolerance;
    gates(j) = same_M_gates(j) && ntot_gates(j) && ...
      LOCAL_action_reference_gate(low_sample, low.config) && ...
      LOCAL_action_reference_gate(high_sample, high.config);
  end
  finite_changes = changes(isfinite(changes));
  if ~isempty(finite_changes)
    max_grid_change = max(finite_changes);
  end
  [paired_pass_through, paired_right_censored] = ...
    LOCAL_prefix_pass_through(high_M, same_M_gates);
  upper_index = find(high_M == max(high_M), 1);
  upper_same_M_pass = ~isempty(upper_index) && same_M_gates(upper_index);
  ntot_onset = LOCAL_sustained_onset(high_M, ntot_gates, ...
    upper_same_M_pass);
  [M_stable, ~] = LOCAL_prefix_pass_through(high_M, gates);
  if ~isnan(M_stable)
    index = find(high_M == M_stable, 1);
    change_at_prefix_endpoint = changes(index);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function change = LOCAL_pair_action_change_at_M(low, high, M)
  change = NaN;
  if isnan(M)
    return;
  end
  low_index = find([low.square.M] == M, 1);
  high_index = find([high.square.M] == M, 1);
  if isempty(low_index) || isempty(high_index)
    return;
  end
  low_sample = low.square(low_index);
  high_sample = high.square(high_index);
  if ~(low_sample.qz.available && high_sample.qz.available)
    return;
  end
  actions = LOCAL_actions(high_sample.channels, ...
    high.config.action_column_count);
  plus_change = LOCAL_weighted_action_error(high_sample.qz.DtN_plus, ...
    low_sample.qz.DtN_plus, actions, high_sample.channels);
  minus_change = LOCAL_weighted_action_error(high_sample.qz.DtN_minus, ...
    low_sample.qz.DtN_minus, actions, high_sample.channels);
  change = max(plus_change, minus_change);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function summary = LOCAL_add_usable_window(summary)
  components = [summary.M_trace_spec_candidate, ...
    summary.M_action_onset, summary.ntot_action_onset];
  if any(isnan(components))
    summary.M_req_candidate = NaN;
    summary.usable_window_status = ...
      'NOT_OBSERVED_REQUIRED_ONSET_UNAVAILABLE';
    return;
  end
  summary.M_req_candidate = max(components);
  if isnan(summary.map_pass_through) || ...
      summary.M_req_candidate > summary.map_pass_through
    summary.usable_window_status = ...
      'NOT_OBSERVED_REQUIREMENT_EXCEEDS_PASS_THROUGH';
    return;
  end
  summary.usable_window_observed = true;
  summary.usable_window_start = summary.M_req_candidate;
  summary.usable_window_end = summary.map_pass_through;
  if summary.map_pass_through_right_censored
    summary.usable_window_status = ...
      'OBSERVED_TO_RIGHT_CENSORED_TESTED_UPPER_BOUND';
  else
    summary.usable_window_status = ...
      'OBSERVED_BEFORE_FIRST_SAME_M_FAILURE';
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function actions = LOCAL_actions(channels, count)
  K = channels.K;
  index = (0:K - 1).';
  xi_weight = sqrt(1 + abs(channels.beta_m(:)) .^ 2);
  actions = zeros(K, count);
  for j = 1:count
    column = exp(2i * pi * j * index / max(K, 1));
    weighted_norm = sqrt(sum(xi_weight .* abs(column) .^ 2));
    actions(:, j) = column / max(weighted_norm, eps);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function value = LOCAL_weighted_action_error(actual, reference, ...
    actions, channels)
  xi_weight = sqrt(1 + abs(channels.beta_m(:)) .^ 2);
  difference = bsxfun(@rdivide, (actual - reference) * actions, ...
    sqrt(xi_weight));
  reference_action = bsxfun(@rdivide, reference * actions, ...
    sqrt(xi_weight));
  value = norm(difference, 'fro') / max(1, norm(reference_action, 'fro'));
end

%% ==================== Batch outputs ====================
% These helpers keep the partial batch resumable and machine-readable.

function batch = LOCAL_batch_record(selection, manifest, summaries, ...
    elapsed, cap, batch_dir, run_results)
  batch.selection = selection;
  batch.manifest = manifest;
  batch.cases = summaries;
  completed = strcmp({summaries.status}, ...
    'COMPLETED_REFERENCE_UNCERTIFIED');
  completed_seconds = [summaries(completed).elapsed_seconds];
  batch.summed_case_seconds = sum(completed_seconds(isfinite( ...
    completed_seconds)));
  batch.aggregation_elapsed_seconds = elapsed;
  batch.max_runtime_seconds = cap;
  batch.completed_count = sum(completed);
  batch.M_trace = NaN;
  batch.M_trace_status = 'NOT_CERTIFIED_REFERENCE_NOT_CLOSED';
  batch.M_stable = NaN;
  batch.M_stable_status = 'NOT_CERTIFIED_REFERENCE_NOT_CLOSED';
  batch.global_interval_status = 'NOT_CERTIFIED';
  batch.ntot_action_ledger = LOCAL_ntot_action_ledger(manifest, run_results);
  batch.ntot_action_tolerance = NaN;
  if ~isempty(batch.ntot_action_ledger)
    tolerances = [batch.ntot_action_ledger.ntot_action_tolerance];
    batch.ntot_action_tolerance = tolerances(1);
    agreement_scale = max(1, abs(batch.ntot_action_tolerance));
    if any(abs(tolerances - batch.ntot_action_tolerance) > ...
        10 * eps(agreement_scale))
      error('run_i4_rayleigh_budget_batch:NtotToleranceMismatch', ...
        'Paired case configurations disagree on ntot_action_tolerance.');
    end
  end
  batch.ntot_pair_count = length(unique( ...
    {batch.ntot_action_ledger.high_output_label}));
  batch.ntot_pair_provenance = ...
    'ntot-action-ledger.csv:low_output_label->high_output_label';
  batch.ntot_action_tolerance_source = 'paired_high_case_config';
  batch.output_dir = batch_dir;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ledger = LOCAL_ntot_action_ledger(manifest, run_results)
  ledger = repmat(LOCAL_empty_ntot_row(), 0, 1);
  for j = 1:length(manifest)
    if ~strcmp(manifest(j).resolution, 'high') || isempty(run_results{j})
      continue;
    end
    low_index = find(strcmp({manifest.resolution}, 'low') & ...
      strcmp({manifest.group}, 'core-low') & ...
      abs([manifest.delta] - manifest(j).delta) <= 10 * eps & ...
      abs([manifest.k] - manifest(j).k) <= 10 * eps, 1);
    if isempty(low_index) || isempty(run_results{low_index})
      continue;
    end
    low = run_results{low_index};
    high = run_results{j};
    [common, low_indices] = ismember([high.square.M], [low.square.M]);
    if ~all(common)
      continue;
    end
    for q = 1:length(high.square)
      low_sample = low.square(low_indices(q));
      high_sample = high.square(q);
      row = LOCAL_empty_ntot_row();
      row.case_id = manifest(j).case_id;
      row.delta = manifest(j).delta;
      row.k = manifest(j).k;
      row.M = high_sample.M;
      row.low_output_label = manifest(low_index).output_label;
      row.high_output_label = manifest(j).output_label;
      row.low_ntot = low.config.ntot;
      row.high_ntot = high.config.ntot;
      row.low_Ny_wall = low.config.Ny_wall;
      row.high_Ny_wall = high.config.Ny_wall;
      row.ntot_action_tolerance = high.config.ntot_action_tolerance;
      row.classification_preserved = ...
        low_sample.qz.stable_count == high_sample.qz.stable_count && ...
        low_sample.qz.unstable_count == high_sample.qz.unstable_count && ...
        low_sample.qz.neutral_count == high_sample.qz.neutral_count && ...
        low_sample.qz.indeterminate_count == ...
        high_sample.qz.indeterminate_count;
      row.low_same_M_gate_pass = ...
        LOCAL_same_M_gate(low_sample, low.config);
      row.high_same_M_gate_pass = ...
        LOCAL_same_M_gate(high_sample, high.config);
      row.same_M_gates_pass = row.low_same_M_gate_pass && ...
        row.high_same_M_gate_pass;
      row.qz_maps_available_both = low_sample.qz.available && ...
        high_sample.qz.available;
      if row.qz_maps_available_both
        actions = LOCAL_actions(high_sample.channels, ...
          high.config.action_column_count);
        row.plus_action_change = LOCAL_weighted_action_error( ...
          high_sample.qz.DtN_plus, low_sample.qz.DtN_plus, ...
          actions, high_sample.channels);
        row.minus_action_change = LOCAL_weighted_action_error( ...
          high_sample.qz.DtN_minus, low_sample.qz.DtN_minus, ...
          actions, high_sample.channels);
        row.max_action_change = max(row.plus_action_change, ...
          row.minus_action_change);
      end
      row.ntot_action_pass = row.qz_maps_available_both && ...
        row.classification_preserved && ...
        row.max_action_change <= row.ntot_action_tolerance;
      row.combined_pair_gate_pass = row.same_M_gates_pass && ...
        row.ntot_action_pass;
      ledger(end + 1, 1) = row; %#ok<AGROW>
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_manifest(manifest, batch_dir)
  fid = LOCAL_open(fullfile(batch_dir, 'manifest.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case_id,group,resolution,delta,radius,k,ntot,Ny_wall,', ...
    'M_in,M_out,proxy_N_side,proxy_N_top,proxy_N_proxy_edge,proxy_M_pw,', ...
    'output_label\n']);
  for j = 1:length(manifest)
    m = manifest(j);
    LOCAL_csv_row(fid, {m.case_id, m.group, m.resolution, m.delta, ...
      m.radius, m.k, m.ntot, m.Ny_wall, 20, 70, m.proxy_N_side, ...
      m.proxy_N_top, m.proxy_N_proxy_edge, m.proxy_M_pw, m.output_label});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_batch(batch)
  fid = LOCAL_open(fullfile(batch.output_dir, 'case-summary.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case_id,group,resolution,delta,radius,k,ntot,Ny_wall,', ...
    'status,execution,elapsed_seconds,extractor_validation_error,', ...
    'extractor_validation_pass,provisional_M_trace,', ...
    'provisional_M_trace_status,M_trace_spec_candidate,', ...
    'map_pass_through,map_pass_through_status,', ...
    'map_pass_through_right_censored,M_action_onset,', ...
    'M_action_onset_status,ntot_action_onset,ntot_action_onset_status,', ...
    'prefix_protocol_M_stable,single_run_conditional_M_stable,', ...
    'paired_conditional_M_stable,conditional_M_stable,', ...
    'conditional_M_stable_status,combined_spectral_tail_change,', ...
    'paired_action_change_at_prefix_endpoint,', ...
    'ntot_action_change_at_onset,', ...
    'ntot_action_change_at_M_req_candidate,', ...
    'paired_action_change_max_grid,', ...
    'M_req_candidate,usable_window_observed,usable_window_start,', ...
    'usable_window_end,usable_window_status,', ...
    'reference_status,output_label,error_id,error_message\n']);
  for j = 1:length(batch.cases)
    c = batch.cases(j);
    LOCAL_csv_row(fid, {c.case_id, c.group, c.resolution, c.delta, ...
      c.radius, c.k, c.ntot, c.Ny_wall, c.status, c.execution, ...
      c.elapsed_seconds, c.extractor_validation_error, ...
      c.extractor_validation_pass, c.provisional_M_trace, ...
      c.provisional_M_trace_status, c.M_trace_spec_candidate, ...
      c.map_pass_through, c.map_pass_through_status, ...
      c.map_pass_through_right_censored, c.M_action_onset, ...
      c.M_action_onset_status, c.ntot_action_onset, ...
      c.ntot_action_onset_status, c.prefix_protocol_M_stable, ...
      c.single_run_conditional_M_stable, ...
      c.paired_conditional_M_stable, c.conditional_M_stable, ...
      c.conditional_M_stable_status, c.combined_spectral_tail_change, ...
      c.paired_action_change_at_prefix_endpoint, ...
      c.ntot_action_change_at_onset, ...
      c.ntot_action_change_at_M_req_candidate, ...
      c.paired_action_change_max_grid, c.M_req_candidate, ...
      c.usable_window_observed, c.usable_window_start, ...
      c.usable_window_end, c.usable_window_status, c.reference_status, ...
      c.output_label, c.error_id, c.error_message});
  end
  clear cleanup;
  LOCAL_write_ntot_action_ledger(batch);
  LOCAL_write_gate_summary(batch);
  fid = LOCAL_open(fullfile(batch.output_dir, 'global-summary.txt'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'selection=%s\n', batch.selection);
  fprintf(fid, 'completed_count=%d\n', batch.completed_count);
  fprintf(fid, 'planned_count=%d\n', length(batch.manifest));
  fprintf(fid, 'summed_case_seconds=%.17g\n', ...
    batch.summed_case_seconds);
  fprintf(fid, 'summed_case_minutes=%.17g\n', ...
    batch.summed_case_seconds / 60);
  fprintf(fid, 'aggregation_elapsed_seconds=%.17g\n', ...
    batch.aggregation_elapsed_seconds);
  fprintf(fid, ['numerical_batch_wall_seconds=', ...
    'NOT_RETAINED_USE_SUMMED_CASE_SECONDS\n']);
  fprintf(fid, 'max_runtime_seconds=%d\n', batch.max_runtime_seconds);
  fprintf(fid, 'ntot_action_tolerance=%.16e\n', ...
    batch.ntot_action_tolerance);
  fprintf(fid, 'ntot_action_tolerance_source=%s\n', ...
    batch.ntot_action_tolerance_source);
  fprintf(fid, 'ntot_pair_count=%d\n', batch.ntot_pair_count);
  fprintf(fid, 'ntot_pair_provenance=%s\n', ...
    batch.ntot_pair_provenance);
  fprintf(fid, 'M_trace=NaN\n');
  fprintf(fid, 'M_trace_status=%s\n', batch.M_trace_status);
  fprintf(fid, 'M_stable=NaN\n');
  fprintf(fid, 'M_stable_status=%s\n', batch.M_stable_status);
  fprintf(fid, 'global_interval_status=%s\n', ...
    batch.global_interval_status);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_ntot_action_ledger(batch)
  fid = LOCAL_open(fullfile(batch.output_dir, 'ntot-action-ledger.csv'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, ['case_id,delta,k,M,low_output_label,high_output_label,', ...
    'low_ntot,high_ntot,low_Ny_wall,high_Ny_wall,', ...
    'plus_action_change,minus_action_change,max_action_change,', ...
    'ntot_action_tolerance,qz_maps_available_both,', ...
    'classification_preserved,low_same_M_gate_pass,', ...
    'high_same_M_gate_pass,same_M_gates_pass,ntot_action_pass,', ...
    'combined_pair_gate_pass\n']);
  for j = 1:length(batch.ntot_action_ledger)
    row = batch.ntot_action_ledger(j);
    LOCAL_csv_row(fid, {row.case_id, row.delta, row.k, row.M, ...
      row.low_output_label, row.high_output_label, row.low_ntot, ...
      row.high_ntot, row.low_Ny_wall, row.high_Ny_wall, ...
      row.plus_action_change, row.minus_action_change, ...
      row.max_action_change, row.ntot_action_tolerance, ...
      row.qz_maps_available_both, row.classification_preserved, ...
      row.low_same_M_gate_pass, row.high_same_M_gate_pass, ...
      row.same_M_gates_pass, row.ntot_action_pass, ...
      row.combined_pair_gate_pass});
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_write_gate_summary(batch)
  fid = LOCAL_open(fullfile(batch.output_dir, 'gate-summary.txt'));
  cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
  fprintf(fid, 'ntot_action_tolerance=%.16e\n', ...
    batch.ntot_action_tolerance);
  fprintf(fid, 'ntot_action_tolerance_source=%s\n', ...
    batch.ntot_action_tolerance_source);
  fprintf(fid, 'ntot_pair_count=%d\n', batch.ntot_pair_count);
  fprintf(fid, 'ntot_pair_provenance=%s\n', ...
    batch.ntot_pair_provenance);
  labels = unique({batch.ntot_action_ledger.high_output_label});
  for j = 1:length(labels)
    index = find(strcmp({batch.ntot_action_ledger.high_output_label}, ...
      labels{j}), 1);
    row = batch.ntot_action_ledger(index);
    fprintf(fid, 'pair_%d=%s->%s\n', j, row.low_output_label, ...
      row.high_output_label);
  end
  fprintf(fid, ['ntot_action_pass_definition=', ...
    'qz_maps_available_both&&classification_preserved&&', ...
    'max_action_change<=ntot_action_tolerance\n']);
  fprintf(fid, ['combined_pair_gate_pass_definition=', ...
    'same_M_gates_pass&&ntot_action_pass\n']);
end

%% ==================== Schemas and CSV helpers ====================
% These helpers provide stable partial rows after interruption or failure.

function item = LOCAL_empty_case()
  item = struct('case_id', '', 'group', '', 'resolution', '', ...
    'delta', NaN, 'radius', NaN, 'k', NaN, 'ntot', NaN, ...
    'Ny_wall', NaN, 'proxy_N_side', NaN, 'proxy_N_top', NaN, ...
    'proxy_N_proxy_edge', NaN, 'proxy_M_pw', NaN, 'output_label', '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function summary = LOCAL_summary_from_case(item)
  summary = LOCAL_empty_summary();
  names = {'case_id', 'group', 'resolution', 'delta', 'radius', 'k', ...
    'ntot', 'Ny_wall', 'output_label'};
  for j = 1:length(names)
    summary.(names{j}) = item.(names{j});
  end
  summary.status = 'NOT_RUN';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function summary = LOCAL_empty_summary()
  summary = struct('case_id', '', 'group', '', 'resolution', '', ...
    'delta', NaN, 'radius', NaN, 'k', NaN, 'ntot', NaN, ...
    'Ny_wall', NaN, 'status', 'NOT_RUN', 'execution', '', ...
    'elapsed_seconds', NaN, 'extractor_validation_error', NaN, ...
    'extractor_validation_pass', false, 'provisional_M_trace', NaN, ...
    'provisional_M_trace_status', '', 'M_trace_spec_candidate', NaN, ...
    'map_pass_through', NaN, 'map_pass_through_status', '', ...
    'map_pass_through_right_censored', false, 'M_action_onset', NaN, ...
    'M_action_onset_status', '', 'ntot_action_onset', NaN, ...
    'ntot_action_onset_status', '', 'prefix_protocol_M_stable', NaN, ...
    'single_run_conditional_M_stable', NaN, ...
    'paired_conditional_M_stable', NaN, 'conditional_M_stable', NaN, ...
    'conditional_M_stable_status', '', ...
    'combined_spectral_tail_change', NaN, ...
    'paired_action_change_at_prefix_endpoint', NaN, ...
    'ntot_action_change_at_onset', NaN, ...
    'ntot_action_change_at_M_req_candidate', NaN, ...
    'paired_action_change_max_grid', NaN, 'M_req_candidate', NaN, ...
    'usable_window_observed', false, 'usable_window_start', NaN, ...
    'usable_window_end', NaN, 'usable_window_status', '', ...
    'reference_status', '', ...
    'output_label', '', 'error_id', '', 'error_message', '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function row = LOCAL_empty_ntot_row()
  row = struct('case_id', '', 'delta', NaN, 'k', NaN, 'M', NaN, ...
    'low_output_label', '', 'high_output_label', '', 'low_ntot', NaN, ...
    'high_ntot', NaN, 'low_Ny_wall', NaN, 'high_Ny_wall', NaN, ...
    'plus_action_change', NaN, 'minus_action_change', NaN, ...
    'max_action_change', NaN, 'ntot_action_tolerance', NaN, ...
    'qz_maps_available_both', false, ...
    'classification_preserved', false, 'low_same_M_gate_pass', false, ...
    'high_same_M_gate_pass', false, 'same_M_gates_pass', false, ...
    'ntot_action_pass', false, 'combined_pair_gate_pass', false);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_csv_row(fid, values)
  encoded = cell(size(values));
  for j = 1:length(values)
    value = values{j};
    if ischar(value)
      encoded{j} = ['"', strrep(value, '"', '""'), '"'];
    elseif islogical(value) && isscalar(value)
      encoded{j} = sprintf('%d', value);
    elseif isnumeric(value) && isscalar(value)
      encoded{j} = sprintf('%.17g', value);
    else
      error('run_i4_rayleigh_budget_batch:CsvValue', ...
        'CSV values must be character strings or numeric scalars.');
    end
  end
  fprintf(fid, '%s\n', strjoin(encoded, ','));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fid = LOCAL_open(path)
  fid = fopen(path, 'w');
  if fid < 0
    error('run_i4_rayleigh_budget_batch:OutputOpen', ...
      'Could not open output file %s.', path);
  end
end
