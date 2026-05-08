function [result, coarse, history] = scan_then_refine(objective, interval, opts)
% SCAN_THEN_REFINE Coarsely scan a scalar objective and refine one dip.
%
% Purpose:
%   Run the standard workflow of sampling a full interval, finding candidate
%   dip intervals, choosing one candidate, and refining only that selected
%   subinterval.
%
% Input:
%   objective:
%     Function handle accepting one scalar x and returning value or
%     [value, info].
%   interval:
%     Two-entry real numeric vector [a,b] for the initial coarse scan.
%   opts:
%     Optional scan options.  If omitted, scan.default_options is used.
%
% Output:
%   result:
%     Result struct returned by scan.refine_interval, augmented with coarse
%     scan and selected dip metadata.
%   coarse:
%     Struct containing x_grid, values, infos, dips, selected_dip, and
%     selected_dip_idx.
%   history:
%     Refinement history returned by scan.refine_interval.
%
% Notes:
%   This function implements one high-level strategy for one selected dip.
%   Broader workflows can reuse scan.find_dip_intervals and call
%   scan.refine_interval on several candidate intervals.

  if nargin < 3 || isempty(opts)
    opts = scan.default_options();
  end
  if ~(isnumeric(interval) && isreal(interval) && numel(interval) == 2 && ...
      isfinite(interval(1)) && isfinite(interval(2)) && interval(2) > interval(1))
    error('scan:scan_then_refine:InvalidInterval', ...
      'interval must be a finite increasing two-entry real vector.');
  end

  x_grid = linspace(interval(1), interval(2), opts.num_initial_points);
  [values, infos] = scan.eval_grid(objective, x_grid, opts);
  dips = scan.find_dip_intervals(x_grid, values, opts);

  coarse.x_grid = x_grid;
  coarse.values = values;
  coarse.infos = infos;
  coarse.dips = dips;
  coarse.selected_dip = [];
  coarse.selected_dip_idx = [];

  if isempty(dips)
    result = LOCAL_failed_result(opts, coarse, ...
      'No dip candidates were found in the coarse scan.');
    history = result.history;
    return;
  end

  [selected_dip, selected_dip_idx] = scan.choose_dip_interval(dips, opts);
  coarse.selected_dip = selected_dip;
  coarse.selected_dip_idx = selected_dip_idx;

  [result, history] = scan.refine_interval(objective, selected_dip.interval, opts);
  result.coarse = coarse;
  result.selected_dip = selected_dip;
  result.selected_dip_idx = selected_dip_idx;

end

function result = LOCAL_failed_result(opts, coarse, message)

  result.best_x = NaN;
  result.best_value = NaN;
  result.best_level = NaN;
  result.best_interval = [];
  result.history = struct([]);
  result.success = false;
  result.message = message;
  result.opts = opts;
  result.coarse = coarse;
  result.selected_dip = [];
  result.selected_dip_idx = [];

end
