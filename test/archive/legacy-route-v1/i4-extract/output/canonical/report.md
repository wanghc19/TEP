# i4 Extraction Oracle Report

- Runtime: `Octave 10.3.0`
- Ewald erfc backend: `Octave complex erfc compatibility shim`
- Total seconds: `2450.629474`
- Mandatory overall pass: `0`
- Mandatory gates passed: `7/13`

## Frozen gates

| Gate | Value | Tolerance | Pass | Mandatory |
|---|---:|---:|---:|---:|
| pure_projection | 2.651348e-16 | 1.000000e-12 | 1 | 1 |
| formula_code | 5.495324e-16 | 5.000000e-13 | 1 | 1 |
| resolved_action | 4.652682e-16 | 1.000000e-11 | 1 | 1 |
| nested_retained_row | 4.742875e-16 | 5.000000e-14 | 1 | 1 |
| boundary_refinement | 1.170935e-11 | 2.000000e-10 | 1 | 1 |
| exact_wall_refinement | 1.198642e-15 | 2.000000e-10 | 1 | 1 |
| mfs_reference | 1.423883e-08 | 2.000000e-09 | 0 | 1 |
| mfs_two_level_change | 5.876755e-08 | 2.000000e-09 | 0 | 1 |
| existing_extractor | 1.423883e-08 | 1.000000e-08 | 0 | 1 |
| four_layer_budget | 1.425054e-08 | 1.000000e-08 | 0 | 1 |
| ewald_two_level | 0.000000e+00 | 2.000000e-09 | 1 | 1 |
| point_mfs_reference | 8.204029e-09 | 2.000000e-09 | 0 | 1 |
| point_mfs_two_level | 5.081011e-08 | 2.000000e-09 | 0 | 1 |
| delta_M_slope_sanity | 2.947943e-04 | 5.000000e-02 | 1 | 0 |

## Interpretation

The Bessel formula is checked independently by angular quadrature. The exact-wall rows synthesize retained Rayleigh modes and therefore isolate Fourier projection. MFS rows use the same manufactured boundary density but evaluate the package Green function.

The point Ewald comparison is value-only. Physical y-periodicity is mapped to the benchmark x-periodic coordinates by swapping `(x,y)` to `(y,x)`.

## Observed refinement diagnosis

- Finest boundary change: `1.170935e-11`
- Finest exact-wall change: `1.198642e-15`
- MFS wall Ny change: `1.102635e-11`
- MFS wall high-to-higher proxy change: `5.876755e-08`
- Higher-proxy wall reference error: `1.423883e-08`
- Higher-proxy point reference error: `8.204029e-09`

`delta_zero` and `near_wood` are negative metadata only. Neither row makes a root-convergence or uniform-error claim.
