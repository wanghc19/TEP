function tile_plan = build_col_lat_tiles(plot_geom, ref_grid, ref_mask)
% BUILD_COL_LAT_TILES Build translated tile metadata for column-lattice cells.
%
% Purpose:
%   Build a reusable tile plan from a column-lattice geometry, reference
%   grids, and reference obstacle masks. The tile plan records how each
%   visible cell is obtained by translating one of the three canonical
%   reference cells: Cminus, C0, or Cplus.
%
% Input:
%   plot_geom - Geometry struct returned by viz.build_col_lat_geom.
%     Required fields:
%       Cminus          - Left reference cell box [x_min, x_max; y_min, y_max].
%       C0              - Center reference cell box [x_min, x_max; y_min, y_max].
%       Cplus           - Right reference cell box [x_min, x_max; y_min, y_max].
%       cells           - Struct array of visible full cells.
%       window          - Plot window struct.
%       cell_lines      - Cell-line metadata.
%
%     Each plot_geom.cells(k) must contain:
%       region          - 'left', 'center', or 'right'.
%       ix              - x-cell index.
%       iy              - y-period index.
%       box             - Full global cell box [x_min, x_max; y_min, y_max].
%       flag_geom       - Geometry flag for the obstacle in this cell.
%       instance        - [] for no obstacle, otherwise obstacle boundary data.
%
%   ref_grid - Reference grid struct with fields:
%       ref_grid.left.X
%       ref_grid.left.Y
%       ref_grid.center.X
%       ref_grid.center.Y
%       ref_grid.right.X
%       ref_grid.right.Y
%
%     These grids should be generated using viz.cell_grid on:
%       plot_geom.Cminus, plot_geom.C0, and plot_geom.Cplus.
%
%   ref_mask - Reference mask struct with fields:
%       ref_mask.left
%       ref_mask.center
%       ref_mask.right
%
%     These masks should be generated using viz.obstacle_mask on the
%     corresponding reference grids.
%
% Output:
%   tile_plan - Struct with fields:
%       ref_grid        - The input reference grids.
%       ref_mask        - The input reference masks.
%       cells           - Struct array of translated tile metadata.
%       Cminus, C0,
%       Cplus           - Canonical reference cell boxes copied from plot_geom.
%       window          - Plot window copied from plot_geom when present.
%       cell_lines      - Cell-line metadata copied from plot_geom when present.
%
%     Each tile_plan.cells(k) contains:
%       region          - 'left', 'center', or 'right'.
%       ix              - x-cell index inherited from plot_geom.cells(k).
%       iy              - y-period index inherited from plot_geom.cells(k).
%       box             - Full global cell box inherited from plot_geom.cells(k).
%       flag_geom       - Geometry flag inherited from plot_geom.cells(k).
%       instance        - Obstacle instance inherited from plot_geom.cells(k).
%       dx              - x-translation from the region reference grid to this cell.
%       dy              - y-translation from the region reference grid to this cell.
%       ref_name        - 'left', 'center', or 'right', usable as a dynamic field name.
%
% Notes:
%   The function does not evaluate fields and does not apply masks to field
%   values. It only organizes grid/mask reuse. For a cell with region r,
%   the physical cell grid is:
%
%     Xcell = tile_plan.ref_grid.(r).X + tile.dx;
%     Ycell = tile_plan.ref_grid.(r).Y + tile.dy;
%     mask  = tile_plan.ref_mask.(r);
%
%   plot_geom.cells(k).box must be the full cell box, not clipped by the
%   plot window. Visual clipping should be handled by xlim/ylim when plotting.

  LOCAL_validate_plot_geom(plot_geom);
  LOCAL_validate_reference_data(ref_grid, ref_mask);

  plot_cells = plot_geom.cells;
  tile_cells = LOCAL_empty_tiles();

  for k = 1:numel(plot_cells)
    cell_k = plot_cells(k);
    ref_name = LOCAL_normalize_region(cell_k.region);
    ref_box = LOCAL_reference_box(plot_geom, ref_name);

    tile_k.region = ref_name;
    tile_k.ix = cell_k.ix;
    tile_k.iy = cell_k.iy;
    tile_k.box = cell_k.box;
    tile_k.flag_geom = cell_k.flag_geom;
    tile_k.instance = cell_k.instance;
    tile_k.dx = cell_k.box(1, 1) - ref_box(1, 1);
    tile_k.dy = cell_k.box(2, 1) - ref_box(2, 1);
    tile_k.ref_name = ref_name;

    tile_cells(end + 1) = tile_k; %#ok<AGROW>
  end

  tile_plan.ref_grid = ref_grid;
  tile_plan.ref_mask = ref_mask;
  tile_plan.cells = tile_cells;
  tile_plan.Cminus = plot_geom.Cminus;
  tile_plan.C0 = plot_geom.C0;
  tile_plan.Cplus = plot_geom.Cplus;

  if isfield(plot_geom, 'window')
    tile_plan.window = plot_geom.window;
  end
  if isfield(plot_geom, 'cell_lines')
    tile_plan.cell_lines = plot_geom.cell_lines;
  end
  if isfield(plot_geom, 'opts')
    tile_plan.opts = plot_geom.opts;
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_plot_geom(plot_geom)
% LOCAL_VALIDATE_PLOT_GEOM Check required geometry fields.

  required = {'Cminus', 'C0', 'Cplus', 'cells'};
  if ~isstruct(plot_geom)
    error('viz:build_col_lat_tiles:MissingField', ...
      'plot_geom must be a struct.');
  end
  for j = 1:numel(required)
    if ~isfield(plot_geom, required{j})
      error('viz:build_col_lat_tiles:MissingField', ...
        'plot_geom.%s is required.', required{j});
    end
  end

  LOCAL_validate_box(plot_geom.Cminus, 'plot_geom.Cminus');
  LOCAL_validate_box(plot_geom.C0, 'plot_geom.C0');
  LOCAL_validate_box(plot_geom.Cplus, 'plot_geom.Cplus');

  cell_required = {'region', 'ix', 'iy', 'box', 'flag_geom', 'instance'};
  for k = 1:numel(plot_geom.cells)
    for j = 1:numel(cell_required)
      if ~isfield(plot_geom.cells(k), cell_required{j})
        error('viz:build_col_lat_tiles:MissingField', ...
          'plot_geom.cells(%d).%s is required.', k, cell_required{j});
      end
    end
    LOCAL_validate_box(plot_geom.cells(k).box, ...
      sprintf('plot_geom.cells(%d).box', k));
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_reference_data(ref_grid, ref_mask)
% LOCAL_VALIDATE_REFERENCE_DATA Check reference grid and mask fields.

  if ~isstruct(ref_grid) || ~isstruct(ref_mask)
    error('viz:build_col_lat_tiles:MissingField', ...
      'ref_grid and ref_mask must be structs.');
  end

  region_names = {'left', 'center', 'right'};
  for j = 1:numel(region_names)
    r = region_names{j};
    if ~isfield(ref_grid, r) || ~isstruct(ref_grid.(r))
      error('viz:build_col_lat_tiles:MissingField', ...
        'ref_grid.%s is required.', r);
    end
    if ~isfield(ref_grid.(r), 'X') || ~isfield(ref_grid.(r), 'Y')
      error('viz:build_col_lat_tiles:MissingField', ...
        'ref_grid.%s.X and ref_grid.%s.Y are required.', r, r);
    end
    if ~isfield(ref_mask, r)
      error('viz:build_col_lat_tiles:MissingField', ...
        'ref_mask.%s is required.', r);
    end

    if ~isequal(size(ref_grid.(r).X), size(ref_grid.(r).Y))
      error('viz:build_col_lat_tiles:SizeMismatch', ...
        'ref_grid.%s.X and ref_grid.%s.Y must have the same size.', r, r);
    end
    if ~isequal(size(ref_mask.(r)), size(ref_grid.(r).X))
      error('viz:build_col_lat_tiles:SizeMismatch', ...
        'ref_mask.%s must match the size of ref_grid.%s.X.', r, r);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function LOCAL_validate_box(box, name)
% LOCAL_VALIDATE_BOX Check a 2-by-2 increasing box.

  if ~isequal(size(box), [2, 2]) || any(~isfinite(box(:))) || ...
      box(1, 2) <= box(1, 1) || box(2, 2) <= box(2, 1)
    error('viz:build_col_lat_tiles:MissingField', ...
      '%s must be [x_min,x_max; y_min,y_max] with increasing limits.', name);
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ref_name = LOCAL_normalize_region(region)
% LOCAL_NORMALIZE_REGION Validate a cell region name.

  if isstring(region)
    if ~isscalar(region)
      error('viz:build_col_lat_tiles:InvalidRegion', ...
        'Cell region must be left, center, or right.');
    end
    region = char(region);
  end
  if ~(ischar(region) && isrow(region))
    error('viz:build_col_lat_tiles:InvalidRegion', ...
      'Cell region must be left, center, or right.');
  end

  ref_name = lower(strtrim(region));
  if ~any(strcmp(ref_name, {'left', 'center', 'right'}))
    error('viz:build_col_lat_tiles:InvalidRegion', ...
      'Cell region must be left, center, or right.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ref_box = LOCAL_reference_box(plot_geom, ref_name)
% LOCAL_REFERENCE_BOX Return the canonical reference box for a region.

  switch ref_name
    case 'left'
      ref_box = plot_geom.Cminus;
    case 'center'
      ref_box = plot_geom.C0;
    case 'right'
      ref_box = plot_geom.Cplus;
    otherwise
      error('viz:build_col_lat_tiles:InvalidRegion', ...
        'Cell region must be left, center, or right.');
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function tiles = LOCAL_empty_tiles()
% LOCAL_EMPTY_TILES Return an empty tile metadata struct array.

  tiles = struct('region', {}, 'ix', {}, 'iy', {}, 'box', {}, ...
    'flag_geom', {}, 'instance', {}, 'dx', {}, 'dy', {}, 'ref_name', {});

end
