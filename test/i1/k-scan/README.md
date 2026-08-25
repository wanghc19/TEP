# I1-K-SCAN-V1 Real-Wavenumber Scan for the TEP Missing-Column Model

## ARS Material Passport

- Experiment ID: `I1-K-SCAN-V1`
- Type: staged MATLAB numerical experiment
- Status: `CONTINUITY READY; FD MUTATION DIAGNOSTIC FAILED; M48 DISCRETE CANDIDATE RECORDED`
- Command: `matlab -nodesktop -batch "addpath(fullfile(pwd,'test','i1','k-scan')); tep_mc_scan('pilot'); tep_mc_scan('continuity'); tep_mc_scan('full');"`
- Outputs: stage-local scalar-ledger CSV files, `provenance.csv`,
  `lineage.csv`, compact `result.mat`, `report.md`, and `run.log`
- Claim boundary: empirical finite-dimensional continuity and finite-difference evidence only; no locator, root, or eigenvalue claim

This test-local I1.3 experiment continues the frozen sharp-disk, empty-center
model from `test/i1/hg-adef/`. The physical parameters are
$\beta=0.5$, $d=1$, $R=0.2$, $s=1$, $k_{\mathrm{int}}=\sqrt{17}k$,
$X_\pm=\pm0.5$, proxy distance $0.2$, and proxy height $1.1$.
The implementation evaluates the unchanged relation
$k_{\mathrm{int}}=\sqrt{1+16s}\,k$; with the frozen $s=1$, this is exactly
$\sqrt{17}k$. The coarse and fine spatial levels are unchanged from I1.2.

The staged entry point is `tep_mc_scan(stage)`. `pilot` checks the MATLAB
runtime, public minimum-norm solver, source hashes, declared dimensions, and a
single inexpensive $M=12$ coarse point. `continuity` evaluates the seven
ordered $M=48$ nodes around $k_0=1.8603695988$, freezes the seed row selector,
checks adjacent principal overlaps, compares coarse/fine actions, verifies the
three centered finite differences, and applies deterministic basis and scalar
mutations. The authorized `full` run then executes `screen`, `refine24`, and
`confirm48` in sequence and stops automatically if a prerequisite is absent.

The authoritative candidate score uses physical coefficient Gram maps that
vary with $\gamma(k)$ at each sampled wavenumber. Only the scalar normalization
is frozen at the stage seed. Raw unbalanced singular values are saved alongside
the score. A screen point is eligible only at a strict interior dip with
prominence at least `1.25` and `r12 <= 0.5`; the stronger `2.0` and `0.1`
thresholds are clarity metadata. $M=12$ is screening only; $M=24$ and $M=48$
may later be described only as discrete real-axis candidates.

Artifacts are written only below `output/<stage>/`. CSV, Markdown reports,
provenance, lineage, and logs are the authoritative audit trail. MAT files are
compact convenience summaries containing configuration, gates, provenance,
flags, candidates, and scalar per-point ledgers; they intentionally omit dense
per-node operators and nested full-stage results. For numerical audit, the
authoritative continuity MAT retains only the final-half-step coarse/fine
derivative matrices for $A_{\mathrm{def}}$ and $\Lambda_\pm$. The `confirm48`
MAT retains only the candidate's coarse/fine unbalanced
$A_{\mathrm{def}}.D$, normalized minimum singular vectors, physical weights,
and seed scales. Production analytic derivatives remain unavailable; the
derivative rows are labelled `EMPIRICAL_FD_DERIVATIVE`.

The authoritative continuity verdict is `PASS WITH CONDITIONS`. Here, pass
means that the continuity and candidate-tracking contract is satisfied; it
does not mean that every gate passes. The finite-difference graph-basis mutation
diagnostic remains failed because its recorded change is above `1e-12`, so
`fd_derivative_ready=false`. The absolute finite-difference convergence and
coarse/fine action gates passed only after sequential expansion through
$h=0.000625$. Candidate screening is authorized independently by the continuity
track. This does not authorize a production derivative.

The staged candidate outputs are: M12 screen $k=1.85$, M24 discrete real-axis
candidate $k=1.8375$, and M48 discrete real-axis candidate $k=1.83125$. The M48
point has `s1=0.002164075629`, `r12=0.004234567839`, prominence
`3.111652914`, and passes the stronger clarity metadata. These are discrete
samples, not a locator, root, or eigenvalue. The value $k^2=3.3534765625$ is
stored only as scalar metadata and is not an eigenvalue claim.

The authoritative reports are `output/pilot/report.md`,
`output/continuity/report.md`, `output/screen/report.md`,
`output/refine24/report.md`, `output/confirm48/report.md`, and
`output/full/report.md`. `output/continuity-initial/` and
`output/continuity-mutation/` preserve non-authoritative intermediate
fail-closed evidence with their historical source hashes. Their MAT summaries
are also compact; their CSV, report, provenance, and log files preserve the
historical evidence.

Recorded MATLAB wall time for the final source-current authoritative path is
`187.132 s`: `1.78579 s` pilot, `83.2495 s` continuity, and `102.097 s` full
candidate pipeline. The two preserved diagnostic repeats took `56.2523 s` and
`106.545 s`, so the requested five-run accounting totals `349.930 s`.
A separate bounded compact-audit implementation attempt ran for approximately
`110 s` by its log timestamps, then hard-failed during `confirm48` before
saving confirm/full results. That repaired engineering attempt, static-check
sessions, and other superseded runs are excluded from the scientific-stage
total.

## Historical M48 zoom v1 stop

The bounded follow-up command was
`matlab -nodesktop -batch "addpath(fullfile(pwd,'test','i1','k-scan')); tep_mc_zoom('pilot'); tep_mc_zoom('full');"`.
Its authoritative reports are `output/zoom-pilot/report.md` and
`output/zoom/report.md`. The pilot passed in `9.106 s`, verifying the parent
lineage and reproducing the pivot score to `6.814e-15`. The preregistered full
run then stopped scientifically after `38.366 s` with
`ZOOM_SCORE_GATE_FAIL / NESTED_SCORE_GATE`.

The first five-point level had its unique coarse and fine minimum at
$k=1.83125$, with $q=2.16407562921445\times10^{-3}$. Pointwise scientific,
QZ/count, chart, transport, coarse/fine drift, score-ratio, singular-vector,
raw/physical-index, and `r12` gates passed. The only failed gate was prominence:
`1.05562039273045 < 1.25`. The result is therefore
`STOP / DESIGN-GATE-INCONCLUSIVE`: near-zero was not established, no zoom
candidate was recorded, and the run did not diagnose a plateau because it
stopped at the first level. It does not authorize a locator, root, derivative,
or estimator claim.

## Authoritative M48 width-driven zoom v2

The independent preregistered plan is `p-zoom2.md`; the MATLAB entry points are
`tep_mc_zoom2('pilot')` and `tep_mc_zoom2('full')`. The v2 runner leaves all v1
sources and outputs unchanged, keeps one pivot-selected frame, and uses a rolling
five-node dense state. Local and fixed-shoulder prominence are metadata only.
Normal completion is determined solely by the already evaluated interval width
falling below `1e-6`; all scientific gates are checked first.

The source-current pilot passed in `8.62536 s`. The full run then evaluated 15
levels and 33 unique wavenumbers in `227.244 s`, with all 167 hard gates passing.
It completed normally at width `7.629394529473643e-7` and spacing
`1.907348632368411e-7`. The final coarse and fine minima coincide at
$k=1.8327703475952146$. Their physical normalized minimum singular values are
$8.32008721372168\times10^{-8}$ and
$8.320088623219309\times10^{-8}$; the corresponding physical minimum singular
values are approximately $1.119833\times10^{-8}$.

The final three robust scores are $3.54716\times10^{-7}$,
$1.88314\times10^{-7}$, and $8.32009\times10^{-8}$. Their adjacent relative
changes are `0.4691` and `0.5582`, so the result is not a three-level plateau and
is not an order-$10^{-3}$ platform. The authoritative report is
`output/zoom2/report.md`. This remains an `M48_DISCRETE_NESTED_GRID_ONLY`
candidate: locator, root, derivative, and estimator authorization flags are all
false.
