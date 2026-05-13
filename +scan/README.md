# +scan package

## Purpose

The `+scan` package provides generic one-dimensional scalar objective scanning and local refinement utilities.  It samples real scalar inputs, detects candidate dips, chooses one refinement interval, recursively refines that interval, and prints concise scan summaries without assuming any objective-specific physics.

## Public functions

`scan.default_options(varargin)` builds the option struct used by the scan and refinement routines.  It accepts either name-value overrides or one override struct and returns fields controlling coarse-grid size, refinement levels, dip selection, endpoint handling, NaN handling, verbosity, and stopping criteria.

`scan.eval_grid(objective, x_grid, opts)` evaluates a scalar objective on a prescribed real grid.  It returns numeric `values` and cell-array `infos` with the same size as `x_grid`, catches pointwise objective failures, and stores failed values as `NaN`.

`scan.find_dip_intervals(x_grid, values, opts)` identifies sampled local dip candidates and their neighboring refinement intervals.  It returns a struct array `dips`; endpoint candidates are controlled by `opts.include_endpoint_dips` and `opts.endpoint_interval_points`.

`scan.choose_dip_interval(dips, opts)` selects one dip candidate from the output of `scan.find_dip_intervals`.  It returns the selected `dip` and its index, using `opts.dip_select = 'global_min'`, `'index'`, or `'nearest'`.

`scan.build_refined_interval(x_grid, idx_min)` returns the next interval around a selected grid minimum.  It uses the neighboring grid samples around `idx_min`, with first/last grid-cell handling for endpoint minima.

`scan.refine_interval(objective, interval, opts)` repeatedly samples one interval and shrinks around the best sampled value.  It returns a `result` struct and per-level `history`; it does not run a coarse scan or choose among multiple candidate dips.

`scan.scan_then_refine(objective, interval, opts)` runs the high-level workflow: coarse scan, dip detection, dip selection, and local refinement of the selected interval.  It returns the augmented `result`, the `coarse` scan metadata, and the refinement `history`.

`scan.print_summary(result, history, label)` prints a generic summary for a scan/refinement result.  It reports success status, best sampled point/value, best level, best interval, and a per-level refinement table; it does not inspect objective-specific info payloads.

## Main data structures

`objective` is a function handle accepting one real scalar `x`.  It may return either `value` or `[value, info]`, where `value` must be a real scalar numeric quantity and `info` may contain objective-specific metadata.

`opts` is the option struct returned by `scan.default_options`.  Current default fields include `min_refine_level`, `max_refine_level`, `num_initial_points`, `num_refine_points`, `dip_select`, `dip_index`, `target_x`, `include_endpoint_dips`, `endpoint_interval_points`, `ignore_nan`, `verbose`, `stop_interval_width`, and `stop_rel_improvement`.

`values` is a numeric array of sampled objective values matching the shape of `x_grid`.  Failed objective calls are stored as `NaN`.

`infos` is a cell array matching the shape of `x_grid`.  Successful one-output objectives receive a generic `status = 'ok'` info struct, while failed samples receive `status = 'failed'` with error identifier and message fields.

`dips` is the candidate-dip struct array returned by `scan.find_dip_intervals`.  Each entry stores `idx_center`, `x_center`, `value_center`, `interval`, `left_idx`, `right_idx`, `is_endpoint`, and `endpoint_side`.

`coarse` is returned by `scan.scan_then_refine`.  It stores the coarse `x_grid`, `values`, `infos`, all detected `dips`, and the selected dip metadata.

`history` is the per-level struct array returned by `scan.refine_interval`.  Each entry stores the refinement `level`, sampled `interval`, `interval_width`, `x_grid`, `values`, `infos`, `idx_min`, `x_min`, `value_min`, `endpoint_hit`, and `rel_improvement`.

`result` is returned by `scan.refine_interval` and `scan.scan_then_refine`.  It stores `best_x`, `best_value`, `best_level`, `best_interval`, `success`, `message`, `opts`, and `history`; the high-level workflow also attaches `coarse`, `selected_dip`, and `selected_dip_idx`.

## Conventions

- The package is generic: do not add assumptions about eigenvalues, singular values, residuals, or other objective-specific meanings to these routines.
- The scan variable is a real scalar.  `interval` must be a finite increasing two-entry real vector `[a,b]`.
- Objective values must be real scalar numeric values.  Complex, vector, matrix, or nonnumeric objective outputs are treated as pointwise failures by `scan.eval_grid`.
- Objective failures at individual grid points should not abort a whole scan; failed points are recorded as `NaN` with error metadata in `infos`.
- Dip detection is based on sampled values only.  An interior dip satisfies `values(j) <= values(j-1)` and `values(j) <= values(j+1)`.
- `scan.refine_interval` refines only the interval supplied by the caller.  Use `scan.scan_then_refine` when a coarse scan and dip selection are desired.
- `scan.build_refined_interval` assumes the supplied `x_grid` is the ordered grid used for the current refinement level.
- `opts.dip_select` should stay as one of the existing character/string selector values: `'global_min'`, `'index'`, or `'nearest'`.
- `history.rel_improvement` is computed from the previous level's best value and is `NaN` when the comparison is not finite or unavailable.
- `scan.print_summary` is a reporting helper only; it should not be used as validation of objective-specific correctness.

## Typical workflow

```matlab
objective = @(x) (x - 1.25).^2 + 0.05 * sin(20 * x);
interval = [0, 2];

opts = scan.default_options( ...
  'num_initial_points', 41, ...
  'num_refine_points', 31, ...
  'max_refine_level', 4, ...
  'dip_select', 'global_min', ...
  'verbose', true);

[result, coarse, history] = scan.scan_then_refine(objective, interval, opts);
scan.print_summary(result, history, 'example scalar scan');

% Lower-level workflows can reuse the pieces directly.
[values, infos] = scan.eval_grid(objective, coarse.x_grid, opts);
dips = scan.find_dip_intervals(coarse.x_grid, values, opts);
[dip, dip_idx] = scan.choose_dip_interval(dips, opts);
[local_result, local_history] = scan.refine_interval(objective, dip.interval, opts);
```
