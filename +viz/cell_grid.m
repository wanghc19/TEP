function [Xcell, Ycell, xcell, ycell] = cell_grid(cell_box, grid_spec)
% CELL_GRID Generate a cell-centered tensor grid inside one cell box.
%
% Purpose:
%   Build a tensor-product grid whose points lie strictly inside a requested
%   subrectangle of a complete cell box.  The grid is cell-centered, so even
%   the default full fractions [0,1] do not place nodes on cell boundaries.
%
% Input:
%   cell_box:
%     2-by-2 array [x_min, x_max; y_min, y_max] describing the full cell.
%
%   grid_spec:
%     Struct with fields:
%       grid_spec.ngridx - Number of x grid points, positive integer.
%       grid_spec.ngridy - Number of y grid points, positive integer.
%       grid_spec.x_frac - Optional [a,b] fraction of the x interval.
%       grid_spec.y_frac - Optional [a,b] fraction of the y interval.
%     Fractions must satisfy 0 <= a < b <= 1.  Missing x_frac/y_frac default
%     to [0,1].
%
% Output:
%   Xcell, Ycell:
%     Meshgrid arrays of size ngridy-by-ngridx.
%   xcell, ycell:
%     One-dimensional cell-centered grid vectors.
%
% Notes:
%   The one-dimensional nodes are
%
%     x = xlo + ((1:ngridx) - 0.5)/ngridx * (xhi - xlo),
%
%   and analogously for y, after applying x_frac and y_frac to cell_box.

  if ~isequal(size(cell_box), [2, 2]) || any(~isfinite(cell_box(:))) || ...
      cell_box(1, 2) <= cell_box(1, 1) || ...
      cell_box(2, 2) <= cell_box(2, 1)
    error('viz:cell_grid:InvalidCellBox', ...
      'cell_box must be [x_min,x_max; y_min,y_max] with increasing limits.');
  end
  if nargin < 2 || ~isstruct(grid_spec)
    error('viz:cell_grid:InvalidGridSpec', ...
      'grid_spec must be a struct.');
  end
  if ~isfield(grid_spec, 'ngridx') || ~isfield(grid_spec, 'ngridy')
    error('viz:cell_grid:MissingGridSize', ...
      'grid_spec.ngridx and grid_spec.ngridy are required.');
  end

  ngridx = grid_spec.ngridx;
  ngridy = grid_spec.ngridy;
  if ~(isscalar(ngridx) && isfinite(ngridx) && ngridx >= 1 && ...
      ngridx == floor(ngridx))
    error('viz:cell_grid:InvalidGridSize', ...
      'grid_spec.ngridx must be a positive integer.');
  end
  if ~(isscalar(ngridy) && isfinite(ngridy) && ngridy >= 1 && ...
      ngridy == floor(ngridy))
    error('viz:cell_grid:InvalidGridSize', ...
      'grid_spec.ngridy must be a positive integer.');
  end

  if ~isfield(grid_spec, 'x_frac') || isempty(grid_spec.x_frac)
    x_frac = [0, 1];
  else
    x_frac = grid_spec.x_frac(:).';
  end
  if ~isfield(grid_spec, 'y_frac') || isempty(grid_spec.y_frac)
    y_frac = [0, 1];
  else
    y_frac = grid_spec.y_frac(:).';
  end
  LOCAL_validate_frac(x_frac, 'x_frac');
  LOCAL_validate_frac(y_frac, 'y_frac');

  x0 = cell_box(1, 1);
  x1 = cell_box(1, 2);
  y0 = cell_box(2, 1);
  y1 = cell_box(2, 2);

  xlo = x0 + x_frac(1) * (x1 - x0);
  xhi = x0 + x_frac(2) * (x1 - x0);
  ylo = y0 + y_frac(1) * (y1 - y0);
  yhi = y0 + y_frac(2) * (y1 - y0);

  xcell = xlo + ((1:ngridx) - 0.5) / ngridx * (xhi - xlo);
  ycell = ylo + ((1:ngridy) - 0.5) / ngridy * (yhi - ylo);
  [Xcell, Ycell] = meshgrid(xcell, ycell);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_frac(frac, name)
% LOCAL_VALIDATE_FRAC Validate a two-entry fraction vector.

  if length(frac) ~= 2 || any(~isfinite(frac)) || ...
      frac(1) < 0 || frac(2) > 1 || frac(1) >= frac(2)
    error('viz:cell_grid:InvalidFraction', ...
      'grid_spec.%s must satisfy 0 <= frac(1) < frac(2) <= 1.', name);
  end

end
