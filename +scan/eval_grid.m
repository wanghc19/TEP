function [values, infos] = eval_grid(objective, x_grid, opts)
% EVAL_GRID Evaluate a scalar objective on a prescribed grid.
%
% Purpose:
%   Evaluate objective(x) at each point of x_grid while catching pointwise
%   errors so that one failed sample does not abort the whole scan.
%
% Input:
%   objective:
%     Function handle accepting one scalar x.  It may return either value or
%     [value, info].
%   x_grid:
%     Numeric grid of real scalar sample points.  The output values and infos
%     have the same size as x_grid.
%   opts:
%     Optional scan options.  If omitted, scan.default_options is used.
%
% Output:
%   values:
%     Numeric array with the same size as x_grid.  Failed points are NaN.
%   infos:
%     Cell array with the same size as x_grid.  Each entry stores objective
%     info or a generic status/error struct.
%
% Notes:
%   This function does not inspect or interpret the objective internals.  It
%   only requires each successful value to be a scalar numeric quantity.

  if nargin < 3 || isempty(opts)
    opts = scan.default_options();
  end
  if ~isa(objective, 'function_handle')
    error('scan:eval_grid:InvalidObjective', ...
      'objective must be a function handle.');
  end
  if ~(isnumeric(x_grid) && isreal(x_grid))
    error('scan:eval_grid:InvalidGrid', ...
      'x_grid must be a real numeric array.');
  end

  values = NaN(size(x_grid));
  infos = cell(size(x_grid));
  npts = numel(x_grid);
  nout = nargout(objective);

  if isfield(opts, 'verbose') && opts.verbose
    fprintf('Evaluating scalar objective on %d grid points.\n', npts);
  end

  for j = 1:npts
    x = x_grid(j);
    try
      if nout == 1 || nout == 0
        value = objective(x);
        info = LOCAL_success_info();
      else
        try
          [value, info] = objective(x);
          if isempty(info)
            info = LOCAL_success_info();
          end
        catch ME_two
          if LOCAL_is_too_many_outputs_error(ME_two)
            value = objective(x);
            info = LOCAL_success_info();
          else
            rethrow(ME_two);
          end
        end
      end

      if ~(isnumeric(value) && isreal(value) && isscalar(value))
        error('scan:eval_grid:InvalidObjectiveValue', ...
          'objective must return a real scalar numeric value.');
      end
      values(j) = value;
      infos{j} = info;
    catch ME
      values(j) = NaN;
      infos{j} = LOCAL_error_info(ME);
      if isfield(opts, 'verbose') && opts.verbose
        fprintf('  objective failed at grid index %d: %s\n', j, ME.message);
      end
    end
  end

end

function tf = LOCAL_is_too_many_outputs_error(ME)

  msg = lower(ME.message);
  tf = ~isempty(strfind(msg, 'too many output')) || ...
    ~isempty(strfind(msg, 'undefined in return list')) || ...
    ~isempty(strfind(msg, 'output argument'));

end

function info = LOCAL_success_info()

  info = struct('status', 'ok', 'error_id', '', 'error_message', '');

end

function info = LOCAL_error_info(ME)

  info = struct('status', 'failed', 'error_id', ME.identifier, ...
    'error_message', ME.message);

end
