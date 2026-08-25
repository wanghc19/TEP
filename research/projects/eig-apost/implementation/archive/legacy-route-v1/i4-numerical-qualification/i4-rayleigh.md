# I4 Rayleigh budget screening

- Date: 2026-08-08
- Stage: I4 Full Analytic Complex-Wavenumber Root-readiness, port-budget diagnostic
- Model: square cell with $L=d=1$, centered sharp disk, $n=\sqrt{17}$, and $\beta=0.5$
- Canonical point: $\delta=0.30$, $R=0.20$, and $k=1.8603695988$
- Verdict: `SCREENING COMPLETE / TRACE_EXTRACTOR_BLOCKED / NO CERTIFIED INTERVAL`
- Root isolation: not authorized
- Evidence: `test/i4-rayleigh-budget/output/batch-all/`

## Purpose and scope

This experiment separates two questions that the previous affine Bloch-mode path
conflated:

1. how many wall Rayleigh orders are required to represent the BIE Cauchy trace;
2. how many orders the half-guide map construction can use without losing an
   interpretable stable/unstable deflating subspace.

The experiment is diagnostic rather than theorem-level certification. It does not
assemble the final balanced $A_{\mathrm{def}}$, run a real-axis locator, freeze a
complex disk, or compute a root, eigenvalue, estimator, or effectivity.

All new code and outputs are isolated under `test/i4-rayleigh-budget/`. No package
source was modified.

## Frozen meanings

The certified trace order $M_{\mathrm{trace}}$ is the smallest persistent order
whose fixed $|m|\leq5$ physical probes satisfy the weighted wall Cauchy tail and
reconstruction gates. The norm is

$$
\sum_m \left(\langle\xi_m\rangle |D_m|^2+
\langle\xi_m\rangle^{-1}|N_m|^2\right),
\qquad
\langle\xi_m\rangle=\sqrt{1+|\beta+2\pi m/d|^2}.
$$

The target tail is $10^{-8}$, the direct-versus-spectral extractor gate is
$10^{-8}$, and the independent reference-change gate is $2\times10^{-9}$.
Because the latter two gates do not close, the strict value remains
`M_trace=NA`. The first persistent crossing of the spectral path alone is recorded
separately as `M_trace_spec_candidate`.

The map diagnostics also keep three meanings separate:

- `map_pass_through` is the largest order, starting at $M=5$, for which all tested
  same-$M$ QZ, graph/Riccati, doubling, conditioning, and perturbation gates pass.
  Reaching $M=20$ is a right-censored observation, not a discovered upper limit.
- `M_action_onset` is the first order whose weighted QZ-to-$M=20$ action difference
  then remains below tolerance.
- `ntot_action_onset` is the analogous onset for the low/high discretization pair.

The descriptive required order is the maximum of the spectral trace candidate and
the two action onsets. An overlap with `map_pass_through` is called an observed
candidate window. It is not a certified $[M_{\mathrm{trace}},M_{\mathrm{stable}}]$
interval while the trace/extractor reference remains open.

Raw transmission-block rank is a ledger only. High evanescent channels naturally
carry factors of the size $\exp(-|\gamma_m|L)$, so their singular values may be far
below floating-point rank thresholds without invalidating the projective pencil.

## Workload and reproducibility

The low grid contains

$$
\delta\in\{0.30,0.20,0.10\},
\qquad
k\in\{1.45,1.65,1.8603695988,2.05,2.25\},
$$

plus the scale controls $k\in\{0.1,1,4\}$ at $\delta=0.30$. The three high pairs
use $k=1.8603695988$ and the same three clearances. Every case tests $M=0{:}20$
with an outgoing extractor through $M_{\mathrm{out}}=70$.

Octave completed all 21 cases with exit code 0. The sum of the recorded case times
is $1653.191542$ seconds, or $27.5532$ minutes, below the preregistered 90-minute
cap. The final aggregate-only rebuild reused every stored `results.mat` and did not
recompute a case.

## Results

| $\delta$ | $R$ | extractor error | spectral low/high change | spectral candidate | action onset | low/high onset | map pass-through | observed candidate window |
|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 0.30 | 0.20 | $1.4991\times10^{-7}$ | $1.73\times10^{-15}$ | 5 | 5 | 5 | 20, right-censored | $[5,20]$, right-censored |
| 0.20 | 0.30 | $4.2815\times10^{-8}$ | $3.70\times10^{-14}$ | 7 | unavailable | unavailable | unavailable | none |
| 0.10 | 0.40 | $1.4384\times10^{-7}$ | $6.51\times10^{-12}$ | 10 | 5 | 19 | 20, right-censored | $[19,20]$, right-censored |

Across the five core wavenumbers, the low-resolution spectral candidates are

- $5,5,5,5,6$ for $\delta=0.30$;
- $7,7,7,7,7$ for $\delta=0.20$;
- $10,10,10,11,10$ for $\delta=0.10$.

Thus clearance is the dominant variable in this grid, while the tested wavenumber
has a smaller effect. The observed increase from approximately 5 to 10 orders as
the disk approaches the wall agrees with the expected near-field burden and
directly rejects a universal choice $M=5$.

For $\delta=0.30$ and $0.10$, the ordered QZ pencil has the required equal stable
and unstable dimensions, no neutral pairs, defining residuals near machine
precision, and same-$M$ map checks through $M=20$. At $M=20$, the raw transmission
block has numerical rank 7 at relative tolerance $10^{-10}$ although its dimension
is 41; nevertheless the projective map gates remain available. Transmission rank
loss is therefore not evidence of lost physical trace dimension and is retired as
a stopping gate.

The published per-$M$ low/high action ledger makes the narrow $\delta=0.10$
onset auditable. Its maximum weighted action changes are $1.0275\times10^{-7}$ at
$M=18$, $9.7919\times10^{-8}$ at $M=19$, and $9.3504\times10^{-8}$ at $M=20$,
against the frozen $10^{-7}$ gate. Thus $M=18$ fails while 19 and 20 pass. The
window start is close to the tolerance and remains an important numerical caveat,
not a robust certified threshold.

For $\delta=0.20$, both low and high runs contain two neutral generalized
eigenvalues at every audited order. At $M=20$ the distance from the unit-circle
threshold is approximately $3.05\times10^{-9}$. The decaying/growing ordered maps
are consequently unavailable. This is consistent with the selected $(R,k)$ lying
in a projected band rather than a gap; it is not classified as a projective-QZ
algorithm failure. It blocks a DtN decay split for that parameter point, but does
not block the canonical $R=0.20$ route.

## Fail-closed interpretation

The spectral tails are extremely stable under the selected low/high refinements,
but that is same-path consistency. The independent direct-wall reconstruction has
a discretization-dependent floor near $10^{-8}$, and all three high extractor
errors exceed the required $10^{-8}$ threshold. Therefore

- `M_trace=NA (TRACE_REFERENCE_UNCERTIFIED)`;
- `M_stable=NA (UPSTREAM_EXTRACTOR_BLOCKED)`;
- `certified_interval=NOT_CERTIFIED`;
- no real-axis dip from the current wall map is yet interpretable as a root seed;
- contour root isolation remains unauthorized.

The positive result is narrower: the projective ordered-QZ/doubling core removes
the previous affine/transmission-rank obstruction and yields useful right-censored
candidate windows for the canonical and small-clearance gap cases.

## Classification

### BLOCKER

- The independent direct-wall/extractor reference does not close at $10^{-8}$, so
  neither $M_{\mathrm{trace}}$ nor the complete upstream-qualified
  $M_{\mathrm{stable}}$ can be certified.
- The block-balanced $A_{\mathrm{def}}$ and actual scanner have not yet been wired
  to the projective map, so a real-axis locator would still be structurally
  ambiguous.
- The anchored complex-$k$ branch, fixed chart/rank, disk, factor/pole ledger, and
  full-matrix Cauchy--Riemann checks remain pending before contour root isolation.

### IMPORTANT CAVEAT

- The windows $[5,20]$ and $[19,20]$ are observed candidates whose upper ends are
  right-censored, not certified stability intervals.
- The $\delta=0.10$ low/high action onset at $M=19$ has only about a two-percent
  margin below its $10^{-7}$ gate and needs the extractor/reference closure before
  it can support a production choice.
- The $\delta=0.20$ point is in or extremely near a projected band and cannot use
  the same decaying/growing DtN split. This is parameter-specific and must be
  screened before selecting a root-search interval.
- The smooth Fliss finite-difference candidate and the sharp-disk BIE model are
  distinct problems. The former guides scales and search intervals but is not a
  reference eigenvalue for the latter.

### MINOR CAVEAT

- Raw transmission rank remains useful diagnostic metadata only.
- The batch runtime demonstrates that the diagnostic is affordable and
  restartable, not that its mathematical result is certified.

## Cheapest next experiment

Freeze only the canonical point $\delta=0.30$, $R=0.20$, and
$k=1.8603695988$. Reuse or cache the high-resolution BIE response and run an
extractor-only closure; do not rerun the $M=0{:}20$ QZ grid. Separate Dirichlet
and Neumann components, left and right walls, incident modes, and total/scattered
field conventions. Add one-variable proxy and wall-quadrature refinements, a
withheld-wall reconstruction check, and a homogeneous-cell exact Rayleigh oracle.

Only after direct-versus-spectral error is at most $10^{-8}$ and the independent
reference change is at most $2\times10^{-9}$ should the three high pairs be
repeated. The next computation after that is the block-balanced
$A_{\mathrm{def}}$ integration and a bounded real-axis locator on the canonical
sharp-disk model.
