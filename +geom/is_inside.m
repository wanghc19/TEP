function inside = is_inside(x, y, flag_geom, varargin)
% IS_INSIDE Test whether local points lie inside a supported geometry.
%
% Purpose:
%   Return a logical mask indicating whether points in local coordinates
%   lie inside a simple geometry. This is intended as the low-level
%   geometry predicate used later by visualization mask helpers.
%
% Input:
%   x, y      - Local point coordinates relative to the default geometry
%               center used by geom.construct_cont.
%   flag_geom - Geometry selector. Currently supports 'none' and 'circle'.
%   varargin  - Optional geometry parameters. For 'circle', varargin{1}
%               may specify the radius. The default radius is 1.
%
% Output:
%   inside    - Logical array of the same size as x and y.
%
% Notes:
%   This function intentionally does not build visualization masks by
%   itself. It only provides the mathematical inside predicate. Plotting
%   masks will be handled later by viz.obstacle_mask.

  if ~isequal(size(x), size(y))
    error('geom:is_inside:SizeMismatch', ...
      'x and y must have the same size.');
  end

  flag_geom = LOCAL_normalize_flag_geom(flag_geom);

  switch flag_geom
    case 'none'
      inside = false(size(x));

    case 'circle'
      radius = LOCAL_parse_circle_radius(varargin{:});
      tol = 10 * eps(max(1, radius));
      inside = x.^2 + y.^2 <= radius^2 + tol;

    otherwise
      error('geom:is_inside:UnsupportedGeometry', ...
        'geom.is_inside currently supports only ''none'' and ''circle''.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function flag_geom = LOCAL_normalize_flag_geom(flag_geom)
% LOCAL_NORMALIZE_FLAG_GEOM Convert a geometry flag to a char row.

  if isstring(flag_geom)
    if ~isscalar(flag_geom)
      error('geom:is_inside:InvalidFlagGeom', ...
        'flag_geom must be a character vector or string scalar.');
    end
    flag_geom = char(flag_geom);
  elseif ~ischar(flag_geom)
    error('geom:is_inside:InvalidFlagGeom', ...
      'flag_geom must be a character vector or string scalar.');
  end

  if ~isrow(flag_geom)
    error('geom:is_inside:InvalidFlagGeom', ...
      'flag_geom must be a character vector or string scalar.');
  end
  flag_geom = lower(strtrim(flag_geom));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function radius = LOCAL_parse_circle_radius(varargin)
% LOCAL_PARSE_CIRCLE_RADIUS Parse and validate the optional circle radius.

  radius = 1.0;
  if ~isempty(varargin)
    radius = varargin{1};
  end

  if ~isscalar(radius) || ~isnumeric(radius) || ~isreal(radius) || ...
      ~isfinite(radius) || radius <= 0
    error('geom:is_inside:InvalidCircleRadius', ...
      'Circle radius must be a positive real scalar.');
  end

end
