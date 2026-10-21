function result = search_fmm_i8(output_dir)
%SEARCH_FMM_I8 Run the frozen I8.4 wide-to-local FMM candidate search.
% Purpose:
%   Locate the finite-grid minimum of the frozen I8.1 physical matching
%   ratio, beginning from the authorized wide interval and refining only
%   through observed adjacent grid nodes.
% Input:
%   output_dir - Directory for checkpoints, complete curves, and summaries.
% Output:
%   result     - Complete point and round ledgers plus the cumulative winner.
% Main algorithm:
%   Evaluate 33 points from 1.45 through 2.25, prefer the best strict
%   interior dip, then repeatedly evaluate 11 points between the winner's
%   actual neighboring nodes.  Recover endpoint winners with a deterministic
%   overlapping in-domain shift.  Stop after a complete interior round has
%   actual span at most 2e-14.  Platform diagnostics never stop the search.
% Based on:
%   research/projects/eig-apost/implementation/i8/design-8-4a.md.
% Main changes:
%   Orchestrate existing fmm_i8_point calls at eps=1e-12.  This file changes
%   neither the frozen point evaluator nor any mathematical formula.
% Numerical goal:
%   Produce an independent FMM finite-grid candidate and a new-process
%   confirmation literal without using the historical direct candidate.

  if nargin ~= 1 || ~(ischar(output_dir) || ...
      (isstring(output_dir) && isscalar(output_dir)))
    error('i8fmmsearch:Arguments','Pass one scalar output directory path.');
  end
  output_dir = char(output_dir);
  if ~isfolder(output_dir)
    mkdir(output_dir);
  end
  required = {'fmm_i8_point','hfmm2d','fmm2d'};
  for j = 1:numel(required)
    if isempty(which(required{j}))
      error('i8fmmsearch:MissingDependency', ...
        'Required function %s is not on the MATLAB path.',required{j});
    end
  end

  % --- stage 1: freeze the search contract and runtime environment ---
  requested_eps = 1e-12;
  width_target = 2e-14;
  max_refinement_rounds = 40;
  wide_first = 1.45;
  wide_step = 0.025;
  wide_count = 33;
  refine_count = 11;
  domain_first = wide_first;
  domain_last = wide_first+(wide_count-1)*wide_step;
  environment = LOCAL_environment(requested_eps,width_target, ...
    max_refinement_rounds,wide_first,wide_step,wide_count,refine_count);
  LOCAL_write_json(fullfile(output_dir,'environment.json'),environment);

  evaluation_rows = repmat(LOCAL_empty_evaluation(),0,1);
  round_rows = repmat(LOCAL_empty_round(),0,1);
  platform_state = struct('streak',0,'awaiting_confirmation',false, ...
    'confirmed',false);
  window_history = cell(0,1);
  status = 'running';
  stop_reason = '';

  % --- stage 2: evaluate the fixed 33-point wide scan ---
  wide_k = wide_first+(0:wide_count-1).'*wide_step;
  LOCAL_validate_grid(wide_k,wide_count);
  window_history{end+1,1} = wide_k;
  [wide_rows,evaluation_rows] = LOCAL_evaluate_grid( ...
    output_dir,0,'wide',wide_k,requested_eps,evaluation_rows);
  [wide_round,wide_decision] = LOCAL_summarize_round( ...
    0,'wide',wide_step,wide_rows,evaluation_rows,NaN,NaN,NaN,0, ...
    platform_state,0);
  [next_k,next_kind,next_requested_step,next_reason] = LOCAL_next_grid( ...
    wide_round,wide_rows,wide_decision,window_history,refine_count, ...
    domain_first,domain_last);
  if isempty(next_k)
    status = 'blocked';
    stop_reason = next_reason;
    wide_round.stop_reason = stop_reason;
  end
  round_rows(end+1,1) = wide_round;
  LOCAL_save_checkpoint(output_dir,evaluation_rows,round_rows, ...
    status,stop_reason);
  LOCAL_save_curve(output_dir,wide_round,wide_rows);

  % --- stage 3: refine only through actual neighboring grid nodes ---
  refinement_index = 0;
  prior_cumulative_best = wide_round.cumulative_best;
  prior_round_best = wide_round.round_best;
  prior_actual_W = wide_round.actual_W;
  while strcmp(status,'running')
    refinement_index = refinement_index+1;
    if refinement_index > max_refinement_rounds
      status = 'guard_stop';
      stop_reason = 'RESOURCE_GUARD_MAX_REFINEMENT_ROUNDS';
      if ~isempty(round_rows)
        round_rows(end).stop_reason = stop_reason;
      end
      break;
    end

    requested_step = next_requested_step;
    refine_k = next_k;
    round_kind = next_kind;
    LOCAL_validate_grid(refine_k,refine_count);
    window_history{end+1,1} = refine_k;
    [current_rows,evaluation_rows] = LOCAL_evaluate_grid( ...
      output_dir,refinement_index,round_kind,refine_k, ...
      requested_eps,evaluation_rows);

    [repeat_count,repeat_bitwise,repeat_max_abs,repeat_metric_abs] = ...
      LOCAL_repeat_evidence(evaluation_rows,current_rows);
    [current_round,decision] = LOCAL_summarize_round( ...
      refinement_index,round_kind,requested_step,current_rows, ...
      evaluation_rows,prior_cumulative_best,prior_round_best, ...
      prior_actual_W,repeat_count, ...
      platform_state,repeat_max_abs);
    current_round.repeat_metrics_bitwise = repeat_bitwise;
    current_round.repeat_adef_sigma_max_abs = repeat_metric_abs(1);
    current_round.repeat_adef_ratio_max_abs = repeat_metric_abs(2);
    current_round.repeat_aphys_sigma_max_abs = repeat_metric_abs(3);
    current_round.repeat_aphys_ratio_max_abs = repeat_metric_abs(4);

    if current_round.is_width_shrinking_transition
      [platform_state,platform_event] = LOCAL_update_platform( ...
        platform_state,current_round.below_5pct);
      current_round.platform_transition_counted = true;
    else
      platform_event = struct('candidate',false, ...
        'confirmation','not_counted_nonshrinking');
    end
    current_round.below_5pct_streak = platform_state.streak;
    current_round.platform_candidate = platform_event.candidate;
    current_round.platform_confirmation = platform_event.confirmation;
    prior_cumulative_best = current_round.cumulative_best;
    prior_round_best = current_round.round_best;
    prior_actual_W = current_round.actual_W;

    if current_round.actual_W <= width_target
      status = 'complete';
      stop_reason = 'ACTUAL_WIDTH_TARGET_MET';
      current_round.stop_reason = stop_reason;
    else
      [next_k,next_kind,next_requested_step,next_reason] = LOCAL_next_grid( ...
        current_round,current_rows,decision,window_history,refine_count, ...
        domain_first,domain_last);
      if isempty(next_k)
        status = 'blocked';
        stop_reason = next_reason;
        current_round.stop_reason = stop_reason;
      end
    end
    round_rows(end+1,1) = current_round; %#ok<AGROW>
    LOCAL_save_checkpoint(output_dir,evaluation_rows,round_rows, ...
      status,stop_reason);
    LOCAL_save_curve(output_dir,current_round,current_rows);
  end

  % --- stage 4: freeze the cumulative winner and final artifacts ---
  [winner,cumulative_tie_distinct_k_count] = ...
    LOCAL_cumulative_winner(evaluation_rows);
  if platform_state.confirmed
    platform_status = 'confirmed';
  elseif platform_state.awaiting_confirmation
    platform_status = 'pending_unconfirmed';
  else
    platform_status = 'not_confirmed';
  end
  LOCAL_save_checkpoint(output_dir,evaluation_rows,round_rows, ...
    status,stop_reason);
  result = struct('status',status,'stop_reason',stop_reason, ...
    'environment',environment,'evaluation_rows',evaluation_rows, ...
    'round_rows',round_rows,'platform_status',platform_status, ...
    'cumulative_tie_distinct_k_count',cumulative_tie_distinct_k_count, ...
    'winner',winner);
  save(fullfile(output_dir,'result.mat'),'result','-v7.3');
  LOCAL_write_json(fullfile(output_dir,'result.json'),result);
  LOCAL_write_evaluations(fullfile(output_dir,'evaluations.csv'), ...
    evaluation_rows);
  LOCAL_write_rounds(fullfile(output_dir,'rounds.csv'),round_rows);
  LOCAL_write_literal(fullfile(output_dir,'winner-literal.txt'),winner);
  LOCAL_write_summary(fullfile(output_dir,'summary.txt'),result);
  fprintf(1,'SEARCH_STATUS=%s\n',status);
  fprintf(1,'STOP_REASON=%s\n',stop_reason);
  fprintf(1,'FINAL_K_LITERAL=%.17g\n',winner.k);
  fprintf(1,'FINAL_APHYS_RATIO=%.17g\n',winner.aphys_ratio);
end

%% ==================== Grid evaluation ====================
% These helpers time complete existing point calls and preserve every node.

function [round_rows,all_rows] = LOCAL_evaluate_grid( ...
    output_dir,round_index,round_kind,k_values,requested_eps,all_rows)
  round_rows = repmat(LOCAL_empty_evaluation(),numel(k_values),1);
  for node_index = 1:numel(k_values)
    k = k_values(node_index);
    row = LOCAL_empty_evaluation();
    row.evaluation_index = numel(all_rows)+1;
    row.round_index = round_index;
    row.round_kind = round_kind;
    row.node_index = node_index;
    row.k = k;
    try
      outer_timer = tic;
      point = fmm_i8_point(k,'fmm',requested_eps,false);
      row.outer_seconds = toc(outer_timer);
      row.point_seconds = point.point_seconds;
      row.adef_sigma = point.metrics.adef_sigma;
      row.adef_ratio = point.metrics.adef_ratio;
      row.aphys_sigma = point.metrics.aphys_sigma;
      row.aphys_ratio = point.metrics.aphys_ratio;
      row.valid = true;
      values = [row.adef_sigma,row.adef_ratio, ...
        row.aphys_sigma,row.aphys_ratio,row.outer_seconds,row.point_seconds];
      if any(~isfinite(values))
        error('i8fmmsearch:NonfinitePoint', ...
          'k=%.17g produced a nonfinite metric or time.',k);
      end
      clear point;
    catch caught
      row.valid = false;
      row.error_id = caught.identifier;
      row.error_message = caught.message;
      round_rows(node_index) = row;
      partial_rows = [all_rows;row]; %#ok<NASGU>
      save(fullfile(output_dir,'failed-partial.mat'), ...
        'partial_rows','caught','-v7.3');
      LOCAL_write_evaluations( ...
        fullfile(output_dir,'failed-partial.csv'),partial_rows);
      rethrow(caught);
    end
    round_rows(node_index) = row;
    all_rows(end+1,1) = row; %#ok<AGROW>
    fprintf(1,['point evaluation=%d round=%d node=%d k=%.17g ', ...
      'outer=%.6f aphys_ratio=%.17g\n'],row.evaluation_index, ...
      round_index,node_index,k,row.outer_seconds,row.aphys_ratio);
  end
end

function LOCAL_validate_grid(k_values,expected_count)
  if numel(k_values) ~= expected_count || any(~isfinite(k_values)) || ...
      any(diff(k_values) <= 0) || numel(unique(k_values)) ~= expected_count
    error('i8fmmsearch:InvalidGrid', ...
      'Grid must contain the requested finite, strictly increasing doubles.');
  end
end

%% ==================== Round decisions ====================
% These helpers implement the frozen finite-grid winner and platform rules.

function [record,decision] = LOCAL_summarize_round( ...
    round_index,round_kind,requested_step,rows,all_rows, ...
    prior_cumulative_best,prior_round_best,prior_actual_W, ...
    repeat_count,platform_state,repeat_max_abs)
  scores = [rows.aphys_ratio].';
  [round_best,global_winner_index] = min(scores);
  global_tied_indices = find(scores == round_best);
  strict_dip_indices = find(scores(2:end-1) < scores(1:end-2) & ...
    scores(2:end-1) < scores(3:end))+1;
  if ~strcmp(round_kind,'wide')
    winner_index = global_winner_index;
    selection_mode = 'stable_first_global_minimum';
    strict_dip = winner_index > 1 && winner_index < numel(rows) && ...
      scores(winner_index) < scores(winner_index-1) && ...
      scores(winner_index) < scores(winner_index+1);
  elseif ~isempty(strict_dip_indices)
    [~,dip_offset] = min(scores(strict_dip_indices));
    winner_index = strict_dip_indices(dip_offset);
    selection_mode = 'best_strict_interior_dip';
    strict_dip = true;
  else
    interior_global = global_tied_indices( ...
      global_tied_indices > 1 & global_tied_indices < numel(rows));
    if ~isempty(interior_global)
      winner_index = interior_global(1);
      selection_mode = 'first_interior_global_minimum';
    else
      winner_index = global_winner_index;
      selection_mode = 'endpoint_global_minimum';
    end
    strict_dip = false;
  end
  strict_interior = winner_index > 1 && winner_index < numel(rows);
  k_values = [rows.k].';
  spacing = diff(k_values);
  [cumulative_winner,cumulative_tie_distinct_k_count] = ...
    LOCAL_cumulative_winner(all_rows);
  cumulative_best = cumulative_winner.aphys_ratio;
  if isnan(prior_cumulative_best)
    relative_improvement = NaN;
    below_5pct = false;
    prior_cumulative_exact_zero = false;
  elseif prior_cumulative_best == 0
    relative_improvement = 0;
    below_5pct = true;
    prior_cumulative_exact_zero = true;
  else
    relative_improvement = ...
      (prior_cumulative_best-cumulative_best)/prior_cumulative_best;
    below_5pct = relative_improvement >= 0 && ...
      relative_improvement < 0.05;
    prior_cumulative_exact_zero = false;
  end
  if isnan(prior_round_best)
    round_best_abs_improvement = NaN;
    round_best_relative_change = NaN;
  elseif prior_round_best == 0
    round_best_abs_improvement = prior_round_best-round_best;
    round_best_relative_change = NaN;
  else
    round_best_abs_improvement = prior_round_best-round_best;
    round_best_relative_change = ...
      round_best_abs_improvement/prior_round_best;
  end
  cumulative_abs_improvement = ...
    prior_cumulative_best-cumulative_best;

  record = LOCAL_empty_round();
  record.round_index = round_index;
  record.round_kind = round_kind;
  record.node_count = numel(rows);
  record.requested_step = requested_step;
  record.actual_first_k = k_values(1);
  record.actual_last_k = k_values(end);
  record.actual_W = k_values(end)-k_values(1);
  record.spacing = spacing.';
  record.min_spacing = min(spacing);
  record.max_spacing = max(spacing);
  record.winner_index = winner_index;
  record.winner_k = k_values(winner_index);
  record.winner_aphys_sigma = rows(winner_index).aphys_sigma;
  record.winner_aphys_ratio = scores(winner_index);
  record.selection_mode = selection_mode;
  record.strict_dip_indices = strict_dip_indices.';
  record.strict_dip_count = numel(strict_dip_indices);
  record.global_winner_index = global_winner_index;
  record.global_winner_k = k_values(global_winner_index);
  record.global_best = round_best;
  record.round_best_aphys_sigma = rows(global_winner_index).aphys_sigma;
  record.global_tie_indices = global_tied_indices.';
  record.global_tie_distinct_k_count = numel(unique(k_values(global_tied_indices)));
  record.endpoint_left_score = scores(1);
  record.endpoint_right_score = scores(end);
  record.endpoint_lower_than_winner = ...
    min(scores([1,end])) < scores(winner_index);
  record.round_best = round_best;
  record.prior_round_best = prior_round_best;
  record.round_best_abs_improvement = round_best_abs_improvement;
  record.round_best_relative_change = round_best_relative_change;
  record.prior_cumulative_best = prior_cumulative_best;
  record.cumulative_best = cumulative_best;
  record.cumulative_abs_improvement = cumulative_abs_improvement;
  record.cumulative_winner_k = cumulative_winner.k;
  record.relative_improvement = relative_improvement;
  record.prior_cumulative_exact_zero = prior_cumulative_exact_zero;
  record.below_5pct = below_5pct;
  record.below_5pct_streak = platform_state.streak;
  record.platform_candidate = false;
  record.platform_confirmation = 'none';
  record.is_width_shrinking_transition = ...
    ~isnan(prior_actual_W) && record.actual_W < prior_actual_W && ...
    strcmp(round_kind,'refinement');
  record.platform_transition_counted = false;
  record.strict_dip = strict_dip;
  record.cumulative_tie_distinct_k_count = ...
    cumulative_tie_distinct_k_count;
  record.curve_strict_decrease_left = ...
    strict_interior && all(diff(scores(1:winner_index)) < 0);
  record.curve_strict_increase_right = ...
    strict_interior && all(diff(scores(winner_index:end)) > 0);
  record.repeat_k_count = repeat_count;
  record.repeat_metrics_bitwise = true;
  record.repeat_max_abs_diff = repeat_max_abs;
  if strict_interior
    record.left_k = k_values(winner_index-1);
    record.right_k = k_values(winner_index+1);
    record.left_gap = record.winner_k-record.left_k;
    record.right_gap = record.right_k-record.winner_k;
    record.neighbor_w = record.right_k-record.left_k;
    record.left_aphys_ratio = scores(winner_index-1);
    record.right_aphys_ratio = scores(winner_index+1);
  end

  decision = struct('action','','direction','','reason','');
  if strict_interior
    decision.action = 'refine';
  elseif winner_index == 1
    decision.action = 'recover';
    decision.direction = 'left';
  else
    decision.action = 'recover';
    decision.direction = 'right';
  end
end

function [next_k,next_kind,requested_step,reason] = LOCAL_next_grid( ...
    record,rows,decision,window_history,refine_count,domain_first,domain_last)
  next_k = [];
  next_kind = '';
  requested_step = NaN;
  reason = '';
  if record.round_index == 0 && strcmp(decision.action,'recover')
    reason = 'RANGE_LIMIT_WIDE_DOMAIN_ENDPOINT';
    return;
  end
  if strcmp(decision.action,'refine')
    left_k = rows(record.winner_index-1).k;
    right_k = rows(record.winner_index+1).k;
    requested_step = (right_k-left_k)/(refine_count-1);
    next_k = left_k+(0:refine_count-1).'*requested_step;
    next_k(end) = right_k;
    next_kind = 'refinement';
  else
    requested_step = record.requested_step;
    full_span = requested_step*(refine_count-1);
    if strcmp(decision.direction,'left')
      requested_first = record.actual_first_k-5*requested_step;
    else
      requested_first = record.actual_first_k+5*requested_step;
    end
    requested_first = max(domain_first, ...
      min(requested_first,domain_last-full_span));
    requested_last = requested_first+full_span;
    if requested_last > domain_last
      requested_last = domain_last;
      requested_first = requested_last-full_span;
    end
    next_k = requested_first+(0:refine_count-1).'*requested_step;
    next_k(end) = requested_last;
    next_kind = 'recovery';
  end
  try
    LOCAL_validate_grid(next_k,refine_count);
  catch caught
    if strcmp(caught.identifier,'i8fmmsearch:InvalidGrid')
      next_k = [];
      reason = 'BINARY64_GRID_FAILURE';
      return;
    end
    rethrow(caught);
  end
  for j = 1:numel(window_history)
    if isequal(next_k,window_history{j})
      next_k = [];
      reason = 'RANGE_LIMIT_REPEATED_WINDOW';
      return;
    end
  end
end

function [state,event] = LOCAL_update_platform(state,below_5pct)
  event = struct('candidate',false,'confirmation','none');
  if state.confirmed
    event.confirmation = 'confirmed_prior';
    return;
  end
  if state.awaiting_confirmation
    if below_5pct
      state.streak = state.streak+1;
      state.awaiting_confirmation = false;
      state.confirmed = true;
      event.confirmation = 'confirmed';
    else
      state.streak = 0;
      state.awaiting_confirmation = false;
      event.confirmation = 'rejected';
    end
    return;
  end
  if below_5pct
    state.streak = state.streak+1;
  else
    state.streak = 0;
  end
  if state.streak >= 3
    state.awaiting_confirmation = true;
    event.candidate = true;
    event.confirmation = 'pending';
  end
end

function [winner,tie_distinct_k_count] = LOCAL_cumulative_winner(rows)
  scores = [rows.aphys_ratio].';
  [best_score,best_index] = min(scores);
  tied_indices = find(scores == best_score);
  tied_k = unique([rows(tied_indices).k]);
  tie_distinct_k_count = numel(tied_k);
  source = rows(best_index);
  winner = struct('evaluation_index',source.evaluation_index, ...
    'round_index',source.round_index,'node_index',source.node_index, ...
    'k',source.k,'adef_sigma',source.adef_sigma, ...
    'adef_ratio',source.adef_ratio,'aphys_sigma',source.aphys_sigma, ...
    'aphys_ratio',source.aphys_ratio);
end

function [repeat_count,all_bitwise,max_abs_diff,metric_max_abs] = ...
    LOCAL_repeat_evidence(all_rows,current_rows)
  first_current = current_rows(1).evaluation_index;
  prior_rows = all_rows(1:first_current-1);
  repeat_count = 0;
  all_bitwise = true;
  max_abs_diff = 0;
  metric_max_abs = zeros(1,4);
  for j = 1:numel(current_rows)
    matches = find([prior_rows.k] == current_rows(j).k);
    if isempty(matches)
      continue;
    end
    repeat_count = repeat_count+1;
    current_values = LOCAL_metric_vector(current_rows(j));
    for m = matches
      prior_values = LOCAL_metric_vector(prior_rows(m));
      all_bitwise = all_bitwise && isequal(current_values,prior_values);
      differences = abs(current_values-prior_values);
      metric_max_abs = max(metric_max_abs,differences);
      max_abs_diff = max(max_abs_diff,max(differences));
    end
  end
end

function values = LOCAL_metric_vector(row)
  values = [row.adef_sigma,row.adef_ratio, ...
    row.aphys_sigma,row.aphys_ratio];
end

%% ==================== Evidence export ====================
% These helpers write exact-value ledgers and non-authoritative curve images.

function LOCAL_save_checkpoint(output_dir,evaluation_rows,round_rows, ...
    status,stop_reason)
  save(fullfile(output_dir,'checkpoint.mat'),'evaluation_rows','round_rows', ...
    'status','stop_reason','-v7.3');
  checkpoint = struct('status',status,'stop_reason',stop_reason, ...
    'evaluation_rows',evaluation_rows,'round_rows',round_rows);
  LOCAL_write_json(fullfile(output_dir,'checkpoint.json'),checkpoint);
  LOCAL_write_evaluations(fullfile(output_dir,'evaluations.csv'), ...
    evaluation_rows);
  LOCAL_write_rounds(fullfile(output_dir,'rounds.csv'),round_rows);
  current = round_rows(end);
  round_rows_current = evaluation_rows( ...
    [evaluation_rows.round_index] == current.round_index); %#ok<NASGU>
  round_record = current; %#ok<NASGU>
  save(fullfile(output_dir,sprintf('round-%02d.mat',current.round_index)), ...
    'round_record','round_rows_current','-v7.3');
  LOCAL_write_evaluations(fullfile(output_dir, ...
    sprintf('round-%02d.csv',current.round_index)),round_rows_current);
  LOCAL_write_json(fullfile(output_dir, ...
    sprintf('round-%02d.json',current.round_index)), ...
    struct('round',round_record,'points',round_rows_current));
end

function LOCAL_save_curve(output_dir,record,rows)
  k_values = [rows.k].';
  scores = [rows.aphys_ratio].';
  offset = k_values-record.winner_k;
  figure_handle = figure('Visible','off','Color','w');
  cleanup = onCleanup(@() close(figure_handle));
  semilogy(offset,scores,'o-','LineWidth',1.2,'MarkerSize',4);
  grid on;
  xlabel(sprintf('k - %.17g',record.winner_k),'Interpreter','none');
  ylabel('aphys ratio','Interpreter','none');
  title(sprintf('round %d: %s',record.round_index,record.round_kind), ...
    'Interpreter','none');
  exportgraphics(figure_handle,fullfile(output_dir, ...
    sprintf('curve-%02d.png',record.round_index)),'Resolution',160);
  clear cleanup;
end

function LOCAL_write_evaluations(path,rows)
  stream = fopen(path,'w');
  if stream < 0
    error('i8fmmsearch:Output','Could not open %s.',path);
  end
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['evaluation_index,round_index,round_kind,node_index,k,', ...
    'valid,outer_seconds,point_seconds,adef_sigma,adef_ratio,', ...
    'aphys_sigma,aphys_ratio,error_id,error_message\n']);
  for j = 1:numel(rows)
    row = rows(j);
    fprintf(stream,'%d,%d,%s,%d,%.17g,%d,%.17g,%.17g,', ...
      row.evaluation_index,row.round_index,LOCAL_csv_text(row.round_kind), ...
      row.node_index,row.k,row.valid,row.outer_seconds,row.point_seconds);
    fprintf(stream,'%.17g,%.17g,%.17g,%.17g,%s,%s\n', ...
      row.adef_sigma,row.adef_ratio,row.aphys_sigma,row.aphys_ratio, ...
      LOCAL_csv_text(row.error_id),LOCAL_csv_text(row.error_message));
  end
  clear cleanup;
end

function LOCAL_write_rounds(path,rows)
  stream = fopen(path,'w');
  if stream < 0
    error('i8fmmsearch:Output','Could not open %s.',path);
  end
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,['round_index,round_kind,node_count,requested_step,', ...
    'actual_first_k,actual_last_k,actual_W,spacing,min_spacing,max_spacing,', ...
    'winner_index,winner_k,selection_mode,strict_dip_indices,', ...
    'winner_aphys_sigma,winner_aphys_ratio,strict_dip_count,', ...
    'global_winner_index,global_winner_k,global_best,', ...
    'round_best_aphys_sigma,', ...
    'global_tie_indices,global_tie_distinct_k_count,endpoint_left_score,', ...
    'endpoint_right_score,endpoint_lower_than_winner,left_k,right_k,', ...
    'left_gap,right_gap,neighbor_w,left_aphys_ratio,right_aphys_ratio,', ...
    'round_best,prior_round_best,round_best_abs_improvement,', ...
    'round_best_relative_change,prior_cumulative_best,cumulative_best,', ...
    'cumulative_abs_improvement,cumulative_winner_k,', ...
    'cumulative_tie_distinct_k_count,', ...
    'relative_improvement,prior_cumulative_exact_zero,below_5pct,', ...
    'below_5pct_streak,platform_candidate,platform_confirmation,', ...
    'is_width_shrinking_transition,platform_transition_counted,', ...
    'strict_dip,curve_strict_decrease_left,curve_strict_increase_right,', ...
    'repeat_k_count,repeat_metrics_bitwise,repeat_max_abs_diff,', ...
    'repeat_adef_sigma_max_abs,repeat_adef_ratio_max_abs,', ...
    'repeat_aphys_sigma_max_abs,repeat_aphys_ratio_max_abs,stop_reason\n']);
  for j = 1:numel(rows)
    row = rows(j);
    fprintf(stream,'%d,%s,%d,%.17g,%.17g,%.17g,%.17g,%s,%.17g,%.17g,', ...
      row.round_index,LOCAL_csv_text(row.round_kind),row.node_count, ...
      row.requested_step,row.actual_first_k,row.actual_last_k,row.actual_W, ...
      LOCAL_csv_vector(row.spacing),row.min_spacing,row.max_spacing);
    fprintf(stream,'%d,%.17g,%s,%s,%.17g,%.17g,%d,%d,%.17g,%.17g,%.17g,%s,%d,', ...
      row.winner_index,row.winner_k,LOCAL_csv_text(row.selection_mode), ...
      LOCAL_csv_vector(row.strict_dip_indices),row.winner_aphys_sigma, ...
      row.winner_aphys_ratio,row.strict_dip_count, ...
      row.global_winner_index,row.global_winner_k,row.global_best, ...
      row.round_best_aphys_sigma, ...
      LOCAL_csv_vector(row.global_tie_indices), ...
      row.global_tie_distinct_k_count);
    fprintf(stream,'%.17g,%.17g,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,%.17g,', ...
      row.endpoint_left_score,row.endpoint_right_score, ...
      row.endpoint_lower_than_winner,row.left_k,row.right_k,row.left_gap, ...
      row.right_gap,row.neighbor_w,row.left_aphys_ratio, ...
      row.right_aphys_ratio);
    fprintf(stream,[repmat('%.17g,',1,8) '%d,%.17g,%d,%d,%d,%d,%s,%d,%d,'], ...
      row.round_best,row.prior_round_best,row.round_best_abs_improvement, ...
      row.round_best_relative_change,row.prior_cumulative_best, ...
      row.cumulative_best,row.cumulative_abs_improvement, ...
      row.cumulative_winner_k, ...
      row.cumulative_tie_distinct_k_count, ...
      row.relative_improvement,row.prior_cumulative_exact_zero, ...
      row.below_5pct,row.below_5pct_streak,row.platform_candidate, ...
      LOCAL_csv_text(row.platform_confirmation), ...
      row.is_width_shrinking_transition,row.platform_transition_counted);
    fprintf(stream,'%d,%d,%d,%d,%d,%.17g,%.17g,%.17g,%.17g,%.17g,%s\n', ...
      row.strict_dip,row.curve_strict_decrease_left, ...
      row.curve_strict_increase_right,row.repeat_k_count, ...
      row.repeat_metrics_bitwise,row.repeat_max_abs_diff, ...
      row.repeat_adef_sigma_max_abs,row.repeat_adef_ratio_max_abs, ...
      row.repeat_aphys_sigma_max_abs,row.repeat_aphys_ratio_max_abs, ...
      LOCAL_csv_text(row.stop_reason));
  end
  clear cleanup;
end

function text = LOCAL_csv_vector(values)
  if isempty(values)
    text = '""';
    return;
  end
  parts = arrayfun(@(value) sprintf('%.17g',value),values, ...
    'UniformOutput',false);
  text = ['"' strjoin(parts,';') '"'];
end

function text = LOCAL_csv_text(value)
  value = char(value);
  value = strrep(value,'"','""');
  text = ['"' value '"'];
end

function LOCAL_write_literal(path,winner)
  stream = fopen(path,'w');
  if stream < 0
    error('i8fmmsearch:Output','Could not open %s.',path);
  end
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,'%.17g\n',winner.k);
  clear cleanup;
end

function LOCAL_write_summary(path,result)
  stream = fopen(path,'w');
  if stream < 0
    error('i8fmmsearch:Output','Could not open %s.',path);
  end
  cleanup = onCleanup(@() fclose(stream));
  fprintf(stream,'status=%s\n',result.status);
  fprintf(stream,'stop_reason=%s\n',result.stop_reason);
  fprintf(stream,'platform_status=%s\n',result.platform_status);
  fprintf(stream,'evaluation_count=%d\n',numel(result.evaluation_rows));
  fprintf(stream,'round_count=%d\n',numel(result.round_rows));
  fprintf(stream,'winner_k=%.17g\n',result.winner.k);
  fprintf(stream,'winner_adef_sigma=%.17g\n',result.winner.adef_sigma);
  fprintf(stream,'winner_adef_ratio=%.17g\n',result.winner.adef_ratio);
  fprintf(stream,'winner_aphys_sigma=%.17g\n',result.winner.aphys_sigma);
  fprintf(stream,'winner_aphys_ratio=%.17g\n',result.winner.aphys_ratio);
  clear cleanup;
end

function LOCAL_write_json(path,value)
  stream = fopen(path,'w');
  if stream < 0
    error('i8fmmsearch:Output','Could not open %s.',path);
  end
  cleanup = onCleanup(@() fclose(stream));
  fwrite(stream,jsonencode(value,'PrettyPrint',true),'char');
  fwrite(stream,newline,'char');
  clear cleanup;
end

%% ==================== Records and environment ====================
% These helpers define stable artifact schemas and runtime metadata.

function row = LOCAL_empty_evaluation()
  row = struct('evaluation_index',0,'round_index',0,'round_kind','', ...
    'node_index',0,'k',NaN,'valid',false,'outer_seconds',NaN, ...
    'point_seconds',NaN,'adef_sigma',NaN,'adef_ratio',NaN, ...
    'aphys_sigma',NaN,'aphys_ratio',NaN,'error_id','', ...
    'error_message','');
end

function row = LOCAL_empty_round()
  row = struct('round_index',0,'round_kind','','node_count',0, ...
    'requested_step',NaN,'actual_first_k',NaN,'actual_last_k',NaN, ...
    'actual_W',NaN,'spacing',[],'min_spacing',NaN,'max_spacing',NaN, ...
    'winner_index',0,'winner_k',NaN,'left_k',NaN,'right_k',NaN, ...
    'left_gap',NaN,'right_gap',NaN,'neighbor_w',NaN, ...
    'left_aphys_ratio',NaN,'right_aphys_ratio',NaN, ...
    'winner_aphys_sigma',NaN,'winner_aphys_ratio',NaN, ...
    'selection_mode','','strict_dip_indices',[],'strict_dip_count',0, ...
    'global_winner_index',0,'global_winner_k',NaN,'global_best',NaN, ...
    'round_best_aphys_sigma',NaN, ...
    'global_tie_indices',[],'global_tie_distinct_k_count',0, ...
    'endpoint_left_score',NaN,'endpoint_right_score',NaN, ...
    'endpoint_lower_than_winner',false, ...
    'round_best',NaN,'prior_round_best',NaN, ...
    'round_best_abs_improvement',NaN,'round_best_relative_change',NaN, ...
    'prior_cumulative_best',NaN,'cumulative_best',NaN, ...
    'cumulative_abs_improvement',NaN,'cumulative_winner_k',NaN, ...
    'cumulative_tie_distinct_k_count',0,'relative_improvement',NaN, ...
    'prior_cumulative_exact_zero',false,'below_5pct',false, ...
    'below_5pct_streak',0,'platform_candidate',false, ...
    'platform_confirmation','none', ...
    'is_width_shrinking_transition',false, ...
    'platform_transition_counted',false,'strict_dip',false, ...
    'curve_strict_decrease_left',false, ...
    'curve_strict_increase_right',false,'repeat_k_count',0, ...
    'repeat_metrics_bitwise',true,'repeat_max_abs_diff',0, ...
    'repeat_adef_sigma_max_abs',0,'repeat_adef_ratio_max_abs',0, ...
    'repeat_aphys_sigma_max_abs',0,'repeat_aphys_ratio_max_abs',0, ...
    'stop_reason','');
end

function environment = LOCAL_environment(requested_eps,width_target, ...
    max_refinement_rounds,wide_first,wide_step,wide_count,refine_count)
  thread_limit = NaN;
  try
    thread_limit = maxNumCompThreads;
  catch
  end
  environment = struct( ...
    'generated_utc',char(datetime('now','TimeZone','UTC', ...
      'Format','yyyy-MM-dd''T''HH:mm:ss''Z''')), ...
    'matlab_version',version,'matlab_release',version('-release'), ...
    'computer',computer,'computer_arch',computer('arch'), ...
    'max_num_comp_threads',thread_limit, ...
    'omp_num_threads',getenv('OMP_NUM_THREADS'), ...
    'omp_dynamic',getenv('OMP_DYNAMIC'), ...
    'omp_proc_bind',getenv('OMP_PROC_BIND'), ...
    'hfmm2d_path',which('hfmm2d'),'fmm2d_path',which('fmm2d'), ...
    'fmm_i8_point_path',which('fmm_i8_point'), ...
    'requested_eps',requested_eps,'width_target',width_target, ...
    'max_refinement_rounds',max_refinement_rounds, ...
    'wide_first',wide_first,'wide_step',wide_step, ...
    'wide_count',wide_count,'refine_count',refine_count, ...
    'frozen_config',struct('beta',0.5,'ntot',256,'nside',160, ...
      'ntop',160,'nproxy',80,'mpw',32,'M',48));
end
