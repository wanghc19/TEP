function [result, history] = refine_interval(objective, interval, opts)
% REFINE_INTERVAL Refine a scalar objective minimum inside one interval.
%
% Purpose:
%   Repeatedly sample a scalar objective on an interval, locate the smallest
%   sampled value, and shrink the next interval to neighboring grid points
%   around that sample.
%
% Input:
%   objective:
%     Function handle accepting one scalar x and returning value or
%     [value, info].
%   interval:
%     Two-entry real numeric vector [a,b].
%   opts:
%     Optional scan options.  If omitted, scan.default_options is used.
%
% Output:
%   result:
%     Struct containing the best sampled x/value, status, options, and
%     history.
%   history:
%     Struct array with one entry per completed refinement level.
%
% Notes:
%   This function refines only the interval supplied by the caller.  It does
%   not do a wider coarse scan and does not choose among multiple dips.

  if nargin < 3 || isempty(opts)
    opts = scan.default_options();
  end
  LOCAL_validate_refine_inputs(objective, interval, opts);

  max_level = opts.max_refine_level;
  min_level = opts.min_refine_level;
  history = repmat(LOCAL_empty_history_entry(), max_level, 1);
  current_interval = interval(:).';
  completed_levels = 0;

  for level = 1:max_level
    x_grid = linspace(current_interval(1), current_interval(2), ...
      opts.num_refine_points);
    [values, infos] = scan.eval_grid(objective, x_grid, opts);
    [value_min, idx_min] = LOCAL_min_finite(values);

    entry = LOCAL_make_history_entry(level, current_interval, x_grid, ...
      values, infos, idx_min, value_min, history);
    history(level) = entry;
    completed_levels = level;

    if isnan(idx_min)
      break;
    end

    if level >= min_level && LOCAL_should_stop(entry, opts)
      break;
    end

    if level < max_level
      current_interval = scan.build_refined_interval(x_grid, idx_min);
    end
  end

  history = history(1:completed_levels);
  result = LOCAL_build_result(history, opts);

end

function LOCAL_validate_refine_inputs(objective, interval, opts)

  if ~isa(objective, 'function_handle')
    error('scan:refine_interval:InvalidObjective', ...
      'objective must be a function handle.');
  end
  if ~(isnumeric(interval) && isreal(interval) && numel(interval) == 2 && ...
      isfinite(interval(1)) && isfinite(interval(2)) && interval(2) > interval(1))
    error('scan:refine_interval:InvalidInterval', ...
      'interval must be a finite increasing two-entry real vector.');
  end
  if opts.min_refine_level < 1 || opts.min_refine_level ~= floor(opts.min_refine_level)
    error('scan:refine_interval:InvalidMinRefineLevel', ...
      'opts.min_refine_level must be a positive integer.');
  end
  if opts.max_refine_level < opts.min_refine_level || ...
      opts.max_refine_level ~= floor(opts.max_refine_level)
    error('scan:refine_interval:InvalidMaxRefineLevel', ...
      'opts.max_refine_level must be an integer at least min_refine_level.');
  end
  if opts.num_refine_points < 2 || opts.num_refine_points ~= floor(opts.num_refine_points)
    error('scan:refine_interval:InvalidNumRefinePoints', ...
      'opts.num_refine_points must be an integer at least 2.');
  end

end

function entry = LOCAL_empty_history_entry()

  entry = struct( ...
    'level', [], ...
    'interval', [], ...
    'interval_width', [], ...
    'x_grid', [], ...
    'values', [], ...
    'infos', [], ...
    'idx_min', [], ...
    'x_min', [], ...
    'value_min', [], ...
    'endpoint_hit', '', ...
    'rel_improvement', []);

end

function entry = LOCAL_make_history_entry(level, interval, x_grid, values, ...
    infos, idx_min, value_min, history)

  entry = LOCAL_empty_history_entry();
  entry.level = level;
  entry.interval = interval;
  entry.interval_width = interval(2) - interval(1);
  entry.x_grid = x_grid;
  entry.values = values;
  entry.infos = infos;
  entry.idx_min = idx_min;
  entry.value_min = value_min;

  if isnan(idx_min)
    entry.x_min = NaN;
    entry.endpoint_hit = 'none';
  else
    entry.x_min = x_grid(idx_min);
    if idx_min == 1
      entry.endpoint_hit = 'left';
    elseif idx_min == numel(x_grid)
      entry.endpoint_hit = 'right';
    else
      entry.endpoint_hit = 'none';
    end
  end

  if level == 1 || ~isfinite(history(level - 1).value_min) || ...
      ~isfinite(value_min)
    entry.rel_improvement = NaN;
  else
    prev_value = history(level - 1).value_min;
    entry.rel_improvement = (prev_value - value_min) / prev_value;
  end

end

function [value_min, idx_min] = LOCAL_min_finite(values)

  finite_idx = find(isfinite(values(:)));
  if isempty(finite_idx)
    value_min = NaN;
    idx_min = NaN;
    return;
  end
  flat_values = values(:);
  [value_min, local_idx] = min(flat_values(finite_idx));
  idx_min = finite_idx(local_idx);

end

function tf = LOCAL_should_stop(entry, opts)

  tf = false;
  if isfield(opts, 'stop_interval_width') && ~isempty(opts.stop_interval_width) && ...
      entry.interval_width <= opts.stop_interval_width
    tf = true;
  end
  if isfield(opts, 'stop_rel_improvement') && ~isempty(opts.stop_rel_improvement) && ...
      isfinite(entry.rel_improvement) && entry.rel_improvement <= opts.stop_rel_improvement
    tf = true;
  end

end

function result = LOCAL_build_result(history, opts)

  result = struct();
  result.history = history;
  result.opts = opts;

  if isempty(history)
    result.best_x = NaN;
    result.best_value = NaN;
    result.best_level = NaN;
    result.best_interval = [];
    result.success = false;
    result.message = 'No refinement levels were completed.';
    return;
  end

  best_values = NaN(length(history), 1);
  for j = 1:length(history)
    best_values(j) = history(j).value_min;
  end
  [best_value, best_level_idx] = LOCAL_min_finite(best_values);

  if isnan(best_level_idx)
    result.best_x = NaN;
    result.best_value = NaN;
    result.best_level = NaN;
    result.best_interval = [];
    result.success = false;
    result.message = 'All evaluated values were NaN.';
    return;
  end

  result.best_x = history(best_level_idx).x_min;
  result.best_value = best_value;
  result.best_level = history(best_level_idx).level;
  result.best_interval = history(best_level_idx).interval;
  result.success = true;
  result.message = 'Refinement completed.';
  if any(isnan(best_values))
    result.message = 'Refinement completed with at least one all-NaN level.';
  end

end
