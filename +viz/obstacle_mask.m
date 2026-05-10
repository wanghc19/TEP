function mask = obstacle_mask(Xcell, Ycell, flag_geom, q, opts, varargin)
% OBSTACLE_MASK Build an obstacle mask on a reference-cell grid.
%
% Purpose:
%   Build a logical mask for points inside the obstacle associated with one
%   reference cell. This helper is intended to be called only for the
%   canonical left, center, and right reference cells, and the resulting
%   masks can then be reused by translation for all cells in the same
%   region.
%
% Input:
%   Xcell, Ycell - Grid coordinates on one reference cell.
%   flag_geom    - Geometry flag, currently delegated to geom.is_inside.
%   q            - Obstacle center in the same reference cell as Xcell/Ycell.
%   opts         - Option struct reserved for future mask behavior.
%   varargin     - Optional geometry parameters forwarded to geom.is_inside.
%
% Output:
%   mask         - Logical array of the same size as Xcell/Ycell.
%
% Notes:
%   IMPORTANT: Xcell and Ycell must be generated from the same reference
%   cell that q and flag_geom describe. In the column-lattice workflow,
%   this means using viz.cell_grid on one of plot_geom.Cminus, plot_geom.C0,
%   or plot_geom.Cplus, together with the corresponding col_lat.<region>.q
%   and col_lat.<region>.flag_geom. This function does not check that the
%   grid actually comes from the matching reference cell.

  if ~isequal(size(Xcell), size(Ycell))
    error('viz:obstacle_mask:SizeMismatch', ...
      'Xcell and Ycell must have the same size.');
  end

  if nargin < 5 || isempty(opts)
    opts = struct();
  end
  if ~isstruct(opts)
    error('viz:obstacle_mask:InvalidOptions', ...
      'opts must be a struct.');
  end

  q = q(:);
  if length(q) ~= 2 || ~isnumeric(q) || ~isreal(q) || any(~isfinite(q))
    error('viz:obstacle_mask:InvalidCenter', ...
      'q must contain two finite real numbers.');
  end

  flag_geom = LOCAL_normalize_flag_geom(flag_geom);
  if strcmp(flag_geom, 'none')
    mask = false(size(Xcell));
    return;
  end

  xloc = Xcell - q(1);
  yloc = Ycell - q(2);
  mask = geom.is_inside(xloc, yloc, flag_geom, varargin{:});
  mask = logical(mask);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function flag_geom = LOCAL_normalize_flag_geom(flag_geom)
% LOCAL_NORMALIZE_FLAG_GEOM Convert a geometry flag to a char row.

  if isstring(flag_geom)
    if ~isscalar(flag_geom)
      error('viz:obstacle_mask:InvalidFlagGeom', ...
        'flag_geom must be a character vector or string scalar.');
    end
    flag_geom = char(flag_geom);
  elseif ~ischar(flag_geom)
    error('viz:obstacle_mask:InvalidFlagGeom', ...
      'flag_geom must be a character vector or string scalar.');
  end

  if ~isrow(flag_geom)
    error('viz:obstacle_mask:InvalidFlagGeom', ...
      'flag_geom must be a character vector or string scalar.');
  end
  flag_geom = lower(strtrim(flag_geom));

end
