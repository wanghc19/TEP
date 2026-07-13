# Benchmark Notes

This directory contains lightweight numerical benchmarks for the TEP project.
Most current scripts under `benchmark/qpgreen/` compare the MFS
quasi-periodic Green function against Ewald or Linton-table reference values.

## Output Policy

Benchmark outputs should stay compact by default.

- Prefer saving only the essential Markdown summary files in `output/`.
- Do not keep large or numerous `.mat` files unless the stored arrays or full
  result structs are needed for later reproduction, plotting, or debugging.
- Do not keep `.csv` files unless tabular post-processing or external plotting
  is needed.
- If a script can optionally save `.mat` or `.csv`, make that behavior
  controlled by an explicit option such as `SaveMat`, `SaveCsv`, or a similarly
  clear name.
- Figures should be saved only when they are used in a report, presentation, or
  diagnostic comparison.

In short: keep `output/` as a report archive, not as a dump of every temporary
numerical run.

## Recommended Practice

For exploratory parameter sweeps, write a concise `.md` report containing:

- the reference case and physical parameters;
- the scanned MFS parameters;
- the best parameter combination;
- the key error and timing metrics;
- the exact command needed to rerun the benchmark.

Keep full `.mat` or `.csv` artifacts only for final, cited, or actively reused
experiments.
