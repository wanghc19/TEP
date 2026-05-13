# +geom package

## Purpose

The `+geom` package provides shared geometry utilities for TEP and waveguide experiments.  It constructs boundary contours, tests simple inside predicates, and caches contour data for repeated scans over discretization sizes.

## Public functions

`geom.construct_cont(ntot, flag_geom, nint, next, varargin)` constructs a periodic obstacle contour and optional random interior/exterior sample points.  It returns the 6-by-`ntot` contour matrix `C`, the parameter interval length `curvelen`, and sample arrays `xxint`, `xxext`; it currently supports `flag_geom = 'star'`, `'ellipse'`, and `'circle'`, with an optional circle radius.

`geom.is_inside(x, y, flag_geom, varargin)` tests whether local points lie inside a supported geometry.  It returns a logical array matching `x` and `y`; it currently supports `flag_geom = 'none'` and `'circle'`, with an optional circle radius.

`geom.build_geometry_cache(ntot_list, flag_geom)` precomputes contour data for the unique values in `ntot_list`.  It returns a struct array with cached `ntot`, `C`, and `curvelen` fields and does not retain random interior or exterior sample points.

`geom.get_geometry_from_cache(ntot, geometry_cache)` retrieves one cached contour from a struct array produced by `geom.build_geometry_cache`.  It returns `C` and `curvelen`, and raises an error if the requested `ntot` is absent.

## Main data structures

`C` is the standard contour matrix returned by `geom.construct_cont`.  Rows 1 and 4 store `x` and `y`, rows 2 and 5 store first derivatives with respect to the periodic parameter, and rows 3 and 6 store second derivatives.

`curvelen` is the parameter interval length used with the trapezoid rule.  For the currently implemented contours it is `2*pi`.

`xxint` and `xxext` are optional random sample point arrays returned by `geom.construct_cont`.  They have sizes `2`-by-`nint` and `2`-by-`next`, respectively, and are generated only for direct contour construction.

`flag_geom` is the geometry selector passed through the project.  In this package, `geom.construct_cont` accepts `'star'`, `'ellipse'`, and `'circle'`, while `geom.is_inside` accepts `'none'` and `'circle'`.

`geometry_cache` is the struct array returned by `geom.build_geometry_cache`.  Each element stores one discretization size and its contour data in the fields `ntot`, `C`, and `curvelen`.

## Conventions

- Keep `flag_geom` as the existing character vector or string scalar selector; do not replace it with a struct such as `flag_geom.kind`.
- `geom.construct_cont` returns contours centered at the local origin.  Callers that place obstacles in cells should translate the coordinates externally.
- The `C` matrix row convention must stay compatible with existing BIE, Bloch, and visualization code: `x = C(1,:)`, `dx/dt = C(2,:)`, `d2x/dt2 = C(3,:)`, `y = C(4,:)`, `dy/dt = C(5,:)`, and `d2y/dt2 = C(6,:)`.
- The outward unit normal used by downstream code is derived from the tangent as `nu = (dy/dt, -dx/dt) / sqrt((dx/dt)^2 + (dy/dt)^2)`.
- The optional circle radius is passed directly as the first extra argument to `geom.construct_cont` or `geom.is_inside`, for example `geom.construct_cont(ntot, 'circle', 0, 0, radius)`.
- `geom.build_geometry_cache` intentionally calls `geom.construct_cont(ntot, flag_geom, 0, 0)` and stores only contour data.  Use direct `geom.construct_cont` calls when optional geometry parameters or random sample points are needed.
- Do not assume that every geometry supported by `geom.construct_cont` has a matching `geom.is_inside` predicate; currently only `'none'` and `'circle'` are implemented for inside tests.

## Typical workflow

```matlab
ntot_list = [80, 120, 160, 160];
flag_geom = 'star';

geometry_cache = geom.build_geometry_cache(ntot_list, flag_geom);

ntot = 120;
[C, curvelen] = geom.get_geometry_from_cache(ntot, geometry_cache);

radius = 0.35;
[C_circle, curvelen_circle, ~, ~] = geom.construct_cont( ...
  ntot, 'circle', 0, 0, radius);

[X, Y] = meshgrid(linspace(-0.5, 0.5, 80), linspace(-0.5, 0.5, 80));
inside_circle = geom.is_inside(X, Y, 'circle', radius);
```
