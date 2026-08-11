# Coordinate-mapping correction

The numerical arrays in this canonical run are unchanged.  The original
report sentence described the `[y;x]` swap as part of the local Linton Ewald
helper.  Static inspection confirms the actual implementation:

- local Ewald consumes Linton separations
  $(X,Y)=(x_t-x_s,y_t-y_s)$ directly, with $Y$ periodic;
- only `kernel.qpgreen_mfs_pairmat(..., periodic_axis='y')` swaps physical
  points to `[y;x]` for its internal first-coordinate-periodic evaluator;
- `bloch.farfield_extractors` uses the physical $(x,y)$ geometry with $y$
  periodic.

The runner, configuration, README, canonical report, and research handoff have
been corrected.  The stale convention string inside the already generated
`results.mat` is metadata only; the Ewald/MFS/Rayleigh values were computed
with the mapping above.
