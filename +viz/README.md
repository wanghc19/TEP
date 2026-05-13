# +viz package

## Purpose

The `+viz` package provides visualization support for column-lattice geometry in periodic waveguide experiments.  Its functions build plot-ready geometry metadata, reference-cell grids, obstacle masks, translated tile plans, and optional geometry overlays on MATLAB axes.

## Public functions

`viz.build_col_lat_geom(plot_window, col_lat, opts)` builds the visible column-lattice geometry for a plotting window.  It returns a `plot_geom` struct containing canonical reference cells, visible full cell boxes, translated obstacle boundary instances, and optional vertical cell-line positions; it constructs data only and does not draw or mask fields.

`viz.cell_grid(cell_box, grid_spec)` generates a cell-centered tensor grid inside a full cell box or a fractional subrectangle of that box.  It returns meshgrid arrays `Xcell`, `Ycell` and one-dimensional vectors `xcell`, `ycell`; it constructs grid data only and does not draw.

`viz.obstacle_mask(Xcell, Ycell, flag_geom, q, opts, varargin)` builds a logical mask for points inside one obstacle on a reference-cell grid.  It delegates geometry classification to `geom.is_inside`, returns a logical array matching `Xcell` and `Ycell`, and does not draw.

`viz.build_col_lat_tiles(plot_geom, ref_grid, ref_mask)` builds translated tile metadata for all visible cells in a `plot_geom`.  It returns a `tile_plan` struct that records which canonical reference grid and mask each cell uses, together with its translation offsets; it organizes data only and does not evaluate or plot fields.

`viz.overlay_col_lat_geom(ax, plot_geom, opts)` draws obstacle boundaries and vertical cell lines from an existing `plot_geom`.  It uses MATLAB axes graphics, can apply axis formatting, and does not construct geometry, masks, or field values.

## Main data structures

`plot_window` describes the visible plotting window.  `viz.build_col_lat_geom` accepts either `plot_window.xlim` / `plot_window.ylim` or compatibility fields `x_min`, `x_max`, `y_min`, `y_max`, and normalizes both forms into the returned `plot_geom.window`.

`col_lat` describes the column lattice.  It contains `C0` for the center reference cell, `left.Lx` and `right.Lx` for horizontal periods, and `left`, `center`, and `right` region structs with `flag_geom`, `q`, and optional `geom_args` fields.

`plot_geom` is the main geometry metadata struct returned by `viz.build_col_lat_geom`.  It contains `Cminus`, `C0`, `Cplus`, `x_period_minus`, `x_period_plus`, `y_period`, `cells`, `cell_lines`, `window`, and `opts`.

`plot_geom.cells(k)` describes one visible full cell.  Its fields are `region`, `ix`, `iy`, `box`, `flag_geom`, and `instance`, where `instance` is empty for `flag_geom = 'none'` and otherwise stores the translated obstacle `center` and boundary coordinates `xy`.

`grid_spec` controls `viz.cell_grid`.  It requires positive integer `ngridx` and `ngridy` fields and may include `x_frac` and `y_frac` to restrict the grid to a fractional subrectangle of the cell.

`ref_grid` stores canonical reference grids for the three regions.  `viz.build_col_lat_tiles` expects `ref_grid.left.X`, `ref_grid.left.Y`, `ref_grid.center.X`, `ref_grid.center.Y`, `ref_grid.right.X`, and `ref_grid.right.Y`.

`ref_mask` stores canonical obstacle masks for the same three regions.  `viz.build_col_lat_tiles` expects `ref_mask.left`, `ref_mask.center`, and `ref_mask.right`, each matching the corresponding reference grid size.

`tile_plan` is returned by `viz.build_col_lat_tiles`.  It stores `ref_grid`, `ref_mask`, translated `cells`, canonical boxes `Cminus`, `C0`, `Cplus`, and any copied `window`, `cell_lines`, and `opts` fields from `plot_geom`.

## Conventions

- `plot_geom.cells(k).box` is always the complete global cell box and must not be clipped to the plot window; plotting limits should handle visual clipping.
- `plot_geom.Cminus`, `plot_geom.C0`, and `plot_geom.Cplus` are the canonical reference cells for the left, center, and right regions.
- `plot_geom.cells(k).instance.center` is the obstacle center, while the center of `plot_geom.cells(k).box` is the cell center; these are different concepts and should not be conflated.
- `flag_geom` follows the existing project style: keep it as a character vector/string geometry flag and pass it directly to `geom.construct_cont` or `geom.is_inside`; do not replace it with a struct such as `flag_geom.kind`.
- Reference grids and masks must be built from the matching canonical cell and region parameters: left uses `Cminus`, center uses `C0`, and right uses `Cplus`.
- `viz.obstacle_mask` expects `Xcell`, `Ycell`, `q`, and `flag_geom` to describe the same reference cell; it does not verify that correspondence.
- `viz.build_col_lat_tiles` only records translations and reference-data reuse.  Field evaluation and mask application are performed by caller code.

## Typical workflow

The example below shows the basic order; if a region uses `geom_args`, pass
those arguments after the `struct()` options argument in `viz.obstacle_mask`.

```matlab
plot_window.xlim = [-4, 4];
plot_window.ylim = [-1, 2];

geom_opts.nt_contour = 160;
geom_opts.cell_lines = 'center';
plot_geom = viz.build_col_lat_geom(plot_window, col_lat, geom_opts);

grid_spec.ngridx = 80;
grid_spec.ngridy = 80;

[ref_grid.left.X, ref_grid.left.Y] = viz.cell_grid(plot_geom.Cminus, grid_spec);
[ref_grid.center.X, ref_grid.center.Y] = viz.cell_grid(plot_geom.C0, grid_spec);
[ref_grid.right.X, ref_grid.right.Y] = viz.cell_grid(plot_geom.Cplus, grid_spec);

ref_mask.left = viz.obstacle_mask(ref_grid.left.X, ref_grid.left.Y, ...
  col_lat.left.flag_geom, col_lat.left.q, struct());
ref_mask.center = viz.obstacle_mask(ref_grid.center.X, ref_grid.center.Y, ...
  col_lat.center.flag_geom, col_lat.center.q, struct());
ref_mask.right = viz.obstacle_mask(ref_grid.right.X, ref_grid.right.Y, ...
  col_lat.right.flag_geom, col_lat.right.q, struct());

tile_plan = viz.build_col_lat_tiles(plot_geom, ref_grid, ref_mask);

figure;
ax = axes();
viz.overlay_col_lat_geom(ax, plot_geom, struct());
```
