function dips = find_dip_intervals(x_grid, values, opts)
% FIND_DIP_INTERVALS Find local dip candidates on a sampled scalar grid.
%
% Purpose:
%   Identify candidate dips in sampled scalar values and return the local
%   intervals that can be used for later refinement.
%
% Input:
%   x_grid:
%     Real numeric vector of sampled x coordinates.
%   values:
%     Numeric vector of sampled scalar values with the same length as x_grid.
%   opts:
%     Optional scan options.  If omitted, scan.default_options is used.
%
% Output:
%   dips:
%     Struct array with candidate dip metadata and refinement intervals.
%
% Notes:
%   An interior sample j is a candidate if values(j) <= values(j-1) and
%   values(j) <= values(j+1).  Endpoint candidates are optional and controlled
%   by opts.include_endpoint_dips.

  if nargin < 3 || isempty(opts)
    opts = scan.default_options();
  end
  x = x_grid(:);
  v = values(:);
  if length(x) ~= length(v)
    error('scan:find_dip_intervals:SizeMismatch', ...
      'x_grid and values must have the same number of elements.');
  end
  if ~(isnumeric(x) && isreal(x) && isnumeric(v))
    error('scan:find_dip_intervals:InvalidInput', ...
      'x_grid must be real numeric and values must be numeric.');
  end

  dips = LOCAL_empty_dips();
  n = length(x);
  if n == 0
    return;
  end

  q = 0;
  if n == 1
    if LOCAL_is_usable(v(1), opts)
      q = q + 1;
      dips(q) = LOCAL_make_dip(1, 1, 1, x, v, true, 'left');
    end
    return;
  end

  if LOCAL_include_endpoints(opts) && LOCAL_is_usable(v(1), opts) && ...
      LOCAL_is_usable(v(2), opts) && v(1) <= v(2)
    right_idx = min(n, max(2, LOCAL_endpoint_points(opts)));
    q = q + 1;
    dips(q) = LOCAL_make_dip(1, 1, right_idx, x, v, true, 'left');
  end

  for j = 2:(n - 1)
    if LOCAL_is_usable(v(j - 1), opts) && LOCAL_is_usable(v(j), opts) && ...
        LOCAL_is_usable(v(j + 1), opts) && v(j) <= v(j - 1) && ...
        v(j) <= v(j + 1)
      q = q + 1;
      dips(q) = LOCAL_make_dip(j, j - 1, j + 1, x, v, false, '');
    end
  end

  if LOCAL_include_endpoints(opts) && LOCAL_is_usable(v(n), opts) && ...
      LOCAL_is_usable(v(n - 1), opts) && v(n) <= v(n - 1)
    left_idx = max(1, n - LOCAL_endpoint_points(opts) + 1);
    left_idx = min(left_idx, n - 1);
    q = q + 1;
    dips(q) = LOCAL_make_dip(n, left_idx, n, x, v, true, 'right');
  end

end

function dips = LOCAL_empty_dips()

  dips = struct( ...
    'idx_center', {}, ...
    'x_center', {}, ...
    'value_center', {}, ...
    'interval', {}, ...
    'left_idx', {}, ...
    'right_idx', {}, ...
    'is_endpoint', {}, ...
    'endpoint_side', {});

end

function dip = LOCAL_make_dip(idx_center, left_idx, right_idx, x, v, ...
    is_endpoint, endpoint_side)

  dip.idx_center = idx_center;
  dip.x_center = x(idx_center);
  dip.value_center = v(idx_center);
  dip.interval = [x(left_idx), x(right_idx)];
  dip.left_idx = left_idx;
  dip.right_idx = right_idx;
  dip.is_endpoint = is_endpoint;
  dip.endpoint_side = endpoint_side;

end

function tf = LOCAL_is_usable(value, opts)

  if isfield(opts, 'ignore_nan') && opts.ignore_nan
    tf = isfinite(value);
  else
    tf = ~isnan(value);
  end

end

function tf = LOCAL_include_endpoints(opts)

  tf = ~isfield(opts, 'include_endpoint_dips') || opts.include_endpoint_dips;

end

function npts = LOCAL_endpoint_points(opts)

  npts = 2;
  if isfield(opts, 'endpoint_interval_points') && ...
      ~isempty(opts.endpoint_interval_points)
    npts = opts.endpoint_interval_points;
  end
  npts = max(2, floor(npts));

end
