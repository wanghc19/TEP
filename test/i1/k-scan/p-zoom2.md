# I1-K-SCAN-ZOOM-V2 Preregistered Plan

## Material passport

- Experiment ID: `I1-K-SCAN-ZOOM-V2`
- Scientific parent: authoritative `output/confirm48/result.mat`
- Entry point: `tep_mc_zoom2(stage)` with `pilot` and `full`
- Outputs: `output/zoom2-pilot/` and `output/zoom2/`
- Claim boundary: M48 discrete nested-grid diagnostics only
- Prohibited claims: locator, root, derivative, estimator, or eigenvalue

## Frozen computation

The calculation uses $M=48$ and starts from
$I_0=[1.825,1.8375]$. At every level, including levels 0 through 14, the
current interval is divided into four equal subintervals and evaluated at its
five ordered nodes. The fixed plus/minus row selectors and the separate
coarse/fine scalar seed scales are constructed once at the pivot $k=1.8375$
and reused at every point and level. Physical weights continue to vary with
$\gamma(k)$.

Each spatial level must have exactly one strict interior global minimum of the
physical score $s_1=\sigma_1/\sigma_{\max}$. The coarse and fine minimum
indices may differ by at most one and their wavenumbers by at most the current
spacing $h$. The next interval is exactly the two-neighbor interval around the
fine minimum. There is no interval extension, fitting, interpolation, Newton
step, or solver substitution. Cached points are not recomputed.

After a level is evaluated and its gates are checked, interval width below
`1e-6` completes the run normally. Reaching the end of level 14 without this
condition fails with `MAX_LEVEL`. The wall-time limit is `600 s`.

## Frozen hard gates

Every unique point retains the existing M48 coarse/fine solve, block, pencil,
ordered-QZ, 97/97/0/0 count, regular-infinity, Wood-distance, fixed-row, chart,
DtN, A-def, Schur, wall-label, basis-mutation, and scalar-mutation gates. The
run additionally requires adjacent QZ-subspace overlap at least `0.9`,
coarse/fine minimum score ratio at most `2`, raw-versus-physical minimum index
difference at most one at each spatial level, coarse/fine minimum left and
right singular-vector overlaps at least `0.9`, and `r12 <= 0.1`.

The only hard failure codes are `SCIENTIFIC_GATE`, `UNBRACKETED_ENDPOINT`,
`NONUNIQUE_MINIMUM`, `COARSE_FINE_DRIFT`, `MAX_LEVEL`, and `HARD_TIME`.
Prominence is not a gate. Both immediate-neighbor prominence and prominence
relative to the fixed initial endpoint shoulders are diagnostic only and may
not stop the run or change the selected interval.

## Completion diagnostics

At normal completion, report $q$, the larger of the coarse and fine minimum
physical scores. The last three $q$ values produce exactly two adjacent
relative changes, $|q_{L-1}-q_{L-2}|/|q_{L-2}|$ and
$|q_L-q_{L-1}|/|q_{L-1}|$; the three-level plateau diagnostic is true only
when both are at most `10%`. The diagnostic classification is exactly
`LE_1E3_MAGNITUDE` when $q_L\le 10^{-3}$,
`GT_1E3_THREE_LEVEL_PLATEAU` when all final three values exceed $10^{-3}$ and
both relative changes are at most `10%`, and `GT_1E3_UNSETTLED` otherwise.
These diagnostics do not affect PASS.

Dense node state uses a rolling cache. Level 0 holds the pivot seed and four
new nodes. After each passing evaluation, only the fine minimum and its two
neighbors are retained, and the following level adds exactly two new nodes.
The active dense node count must never exceed five, and the estimated active
state must remain below the frozen `512 MiB` engineering-memory gate. Flattened
CSV ledgers may accumulate across all evaluated points and levels.

## Lineage and fail-closed execution

The scientific parent is the confirm48 lineage token
`d11ecd7a69f85f07f481177219cee926a64527a5b792ce0f570a3084820a43c2`.
The pilot validates the parent schema, status, authorization, candidate,
source/config hashes, and lineage token, then recomputes the pivot point and
parent score. The full run requires a source-current passing v2 pilot; its
lineage parent is the v2 pilot token, while the scientific-parent token remains
recorded separately. MATLAB `lsqminnorm`, zero fallback count, and zero silent
rank switch are mandatory.

Run the pilot first. Run full only after pilot review within this authorized
run. A hard failure is preserved and not silently retried.
