# I1.4 full-run estimate

This estimate was re-frozen before the source-closed `full-a2` full-disk
invocation.  The earlier `full-a1/attempt-1` process was interrupted after a
source race and is non-authoritative; no scientific result was produced.

- Campaign/attempt: `full-a2/attempt-1`, radius
  `3.8146972647368216e-7`.
- Work: 41 center/star nodes, 4 alternate-parent closure nodes, 108 CR
  stencil evaluations, and at most 8 evaluator calls in the negative suite.
- Estimated evaluator calls: at most 161 coarse/fine pairs.
- Pilot basis: a complex coarse/fine pair required about 7.5--8.3 seconds.
- Estimated runtime: 20--23 minutes; target 25 minutes; hard limit 30 minutes.
- Largest physical arrays: proxy collocation `960 x 450`, BIE `512 x 512`,
  one-cell/QZ `194 x 194`, and graph `388 x 388`.
- Estimated peak memory: below 512 MiB.
- No locator, contour, root isolation, estimator, or oversized separation
  matrix is authorized by this run.

If attempt 1 fails a scientific gate, it remains immutable.  A smaller
predeclared radius may be evaluated only in a separate MATLAB invocation with
its own estimate and output directory.

## Attempt 2 estimate

- Campaign/attempt: `full-a2/attempt-2`, radius
  `1.9073486323684108e-7`.
- Attempt 1 stopped at the first center CR node after 425.458 seconds.  The
  attempt 2 CR stencil reuses smaller steps, so the expected fail-closed cost
  is 7--10 minutes.
- If it unexpectedly reaches every downstream check, the unchanged worst-case
  estimate remains 20--23 minutes and below 512 MiB.
- Matrix sizes and every scientific threshold are unchanged.

## Attempt 3 estimate

- Campaign/attempt: `full-a2/attempt-3`, radius
  `9.536743161842054e-8`.
- Attempts 1 and 2 stopped at the first center CR node after 425.458 and
  451.964 seconds.  Attempt 3 is expected to stop at the same stage in 7--10
  minutes; its unchanged worst-case estimate is 20--23 minutes.
- Peak memory remains below 512 MiB and all matrix sizes and scientific gates
  remain unchanged.
