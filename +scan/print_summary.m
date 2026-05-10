function print_summary(result, history, label)
% PRINT_SUMMARY Print a concise scalar scan/refinement summary.
%
% Purpose:
%   Print the best sampled point, best value, best level, final interval, and
%   per-level refinement table for a scan result.
%
% Input:
%   result:
%     Result struct returned by scan.refine_interval or scan.scan_then_refine.
%   history:
%     Optional history struct array.  If omitted or empty, result.history is
%     used when available.
%   label:
%     Optional text label for the printed summary.  Default is 'scan result'.
%
% Output:
%   None.
%
% Notes:
%   This function only prints generic scalar scan metadata.  It does not
%   interpret objective-specific info payloads.

  if nargin < 2 || isempty(history)
    if isfield(result, 'history')
      history = result.history;
    else
      history = struct([]);
    end
  end
  if nargin < 3 || isempty(label)
    label = 'scan result';
  end

  fprintf('\n%s summary:\n', label);
  fprintf('  success    : %d\n', result.success);
  fprintf('  message    : %s\n', result.message);
  fprintf('  best_x     : %.16g\n', result.best_x);
  fprintf('  best_value : %.16e\n', result.best_value);
  fprintf('  best_level : %g\n', result.best_level);
  if isfield(result, 'best_interval') && ~isempty(result.best_interval)
    fprintf('  best_interval: [%.16g, %.16g]\n', ...
      result.best_interval(1), result.best_interval(2));
  end

  if isempty(history)
    return;
  end

  fprintf('\nRefinement summary by level:\n');
  fprintf(['  %-5s %-28s %-14s %-22s %-20s %-16s %-14s\n'], ...
    'Level', 'Interval', 'Width', 'x_min', 'value_min', ...
    'RelImprove', 'Endpoint');

  for level = 1:length(history)
    entry = history(level);
    interval_str = sprintf('[%.8f, %.8f]', entry.interval(1), entry.interval(2));
    if isnan(entry.rel_improvement)
      rel_str = 'N/A';
    else
      rel_str = sprintf('%.6e', entry.rel_improvement);
    end
    if isfinite(entry.value_min)
      x_str = sprintf('%.16f', entry.x_min);
      value_str = sprintf('%.12e', entry.value_min);
    else
      x_str = 'NaN';
      value_str = 'NaN';
    end

    fprintf(['  %-5d %-28s %-14.6e %-22s %-20s %-16s %-14s\n'], ...
      entry.level, interval_str, entry.interval_width, x_str, value_str, ...
      rel_str, entry.endpoint_hit);
  end

end
