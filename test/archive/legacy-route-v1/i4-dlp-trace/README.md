# I4 DLP and trace certification

This MATLAB R2023b experiment is the strict successor to the common
`proxy_dist/d=0.2` SLP qualification. It does not change package code and it
does not run DtN or a root locator.

The scientific sequence is fixed:

1. pilot qualification of DLP-D point components and proxy/rank sanity;
2. DLP-D Ewald/package/Rayleigh wall coefficient and one-axis gates;
3. DLP-N point, derivative, and rank sanity;
4. DLP-N wall gates;
5. only after both DLP actions pass, four-action `M_trace` certification.

No DLP-N or `M_trace` decision row is emitted before its prerequisite. Arrays
may be cached from one common set of Green matrices, but cached data have no
scientific status until unblinded by the sequential gate.

## Reproduction

From the repository root:

```matlab
addpath(fullfile(pwd,'test','i4-dlp-trace'));
run_i4_dlp_trace('pilot');
run_i4_dlp_trace('full');
```

Pilot mode builds no wall matrix. Full mode is preregistered at 90--180 s and
uses first-failure stopping. Outputs are written separately to `output/pilot`
and `output/canonical` as CSV, MAT, Markdown, and text logs.

## Canonical result

MATLAB R2023b completed the final full run in `95.539849 s` with status
`DLP_D_N_MTRACE48_CERTIFIED`.  DLP-D and DLP-N passed all Ewald/package/
Rayleigh coefficient triangles and the four package single-axis self gates.
The four-action half-grid reconstruction and omitted-coefficient tests also
certified the preregistered finite candidate `M_trace=48` against `Mref=96`.

See `output/canonical/report.md` for the generated decision table and
`output/canonical/audit-summary.md` for the decisive maxima, row counts,
classification, and claim boundary.
