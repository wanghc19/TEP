BIE = boundary integral equation, QZ = generalized Schur decomposition, FMM = fast multipole method, MFS = method of fundamental solutions, RMS = root mean square, RSS = resident set size. W3 denotes a guide with three missing rows, I9 identifies the inherited cell implementation and v1 means version 1. In filenames, det means determinant, config configuration, ex1 Example 1, CSV comma-separated values and JSON JavaScript Object Notation.

# Split-window search at Wood frequencies

Measure real-frequency search coverage and candidate accuracy on both sides of a known Wood frequency. Every excluded open band is unsearched.

## Working exclusion rule

For these two models, use the square-root coordinate and start with an exclusion half-width of 0.001. Both variables completed all 24 phase/grid cases there. The median cumulative determinant time was 26.15 s for the square-root route and 37.15 s for plain interpolation, including the measured outer panels in each total. If the band is narrowed, preserve verified outer intervals and report any new unfinished strip. In the separate near-branch scan the entire retained side is interpolated in one initial square-root panel. A narrow newly admitted strip can have a different relative interpolation error.

For a desired absolute root error $\varepsilon$, the empirical starting rule is $\delta\ge\max(10^{-3},5\times10^{-14}/\varepsilon)$ in these frequency units. The first term comes from completion on both models and both grids. The second rounds up the measured maximum of $t|k_{192}-k_{\rm ref}|$ (Example 1, $4.07\times10^{-14}$ rounded upward, and W3, $5.69\times10^{-15}$). The nominal detuning ranges are $10^{-4}\le t\le 10^{-1}$ in Example 1 and $10^{-4}\le t\le 10^{-2}$ on the tracked W3 branch. The second W3 root lies at $t=0.01983$. Local Newton comparisons supply the smallest detunings. The reference changes the shared Green fit but still uses the fine BIE discretization. This rule estimates accuracy over the sampled range. For a narrower exclusion, require the interpolation and two-grid physical checks to pass and record incomplete strips. An exclusion of 0.02 or larger uses up the whole half-window.

## Predictions recorded before the runs and their outcomes

1. **Plain interpolation.** The prediction was completion at 0.01, then more subdivisions or timeouts at 0.0001. **Held for the search outcome.** At the positive $10^{-4}$ Example 1 phase the coarse plain search went from 2 panels, 38 evaluations and 15.74 s to 6 panels, 308 evaluations and 122.15 s. The nested runs also encountered timeouts. These measurements do not isolate the branch as the sole cause.
2. **Square-root interpolation.** The prediction was completion at 0.0001 and 0.00001 with few panels. **Partly held.** At the same Example 1 phase an independent search at 0.0001 used 2 panels and 56 evaluations on each grid (21.33 and 31.11 s). At positive detuning 0.01, reusing the outer panels and tightening to 0.0001 finished on the coarse grid in 106.10 cumulative seconds and timed out on the fine grid at 150.57 s. The matching fine plain strip finished in 119.25 cumulative seconds. At 0.00001 the coarse search reached 150 s. On W3 even the square-root coordinate reached depth eight. The coefficient-tail and off-grid gates failed with a valid chart. On the coarse W3 0.00001 strip the last relative off-grid discrepancy was $3.0\times10^{-9}$ against $10^{-9}$. Subdivision can expose variations at the level of the shared Green fit.
3. **Shared Green error.** The predicted root error was of order $10^{-14}/t$ times sensitivity, about $10^{-10}$ near $t=10^{-4}$, underestimated by the grid difference. **Partly held.** At $t\simeq\pm1.2\times10^{-4}$ the fine returned roots differed from the changed-Green roots by $(6.27,6.47)\times10^{-11}$, against grid differences of $(3.82,3.99)\times10^{-12}$. At the positive $10^{-4}$ Example 1 phase the changed fit reduced the pointwise Green discrepancy from about $1.2\times10^{-10}$ to $7.1\times10^{-15}$. Individual root shifts vary at nearby phases. The local-fit slopes and ranges are below.
4. **Missed modes.** The prediction was that only modes in the unsearched band are missed, with no false root near either edge. **Held on all 15 Example 1 phases** at $\delta=10^{-4}$. Ten paired roots followed the interpolated branch, five interpolated modes lay in the excluded band, and zero extra roots appeared. The five inferred detunings have magnitude at most $8.01\times10^{-5}$. Replacing the four-point interpolation by two bracketing points changed any scan prediction by at most $5.44\times10^{-9}$. Both grids completed every retained window. This count uses the known branch to identify missed modes.

<!-- measured tables -->
## Measurements

The [search ledger](results/searches.csv) gives each grid, every frequency proposal and paired return, the closest cell evaluation, and the new and cumulative counts. The [coverage ledger](results/planned-grid.csv) names all 144 requested width/grid/phase combinations and their records. An inherited incomplete outer panel is listed separately from a fresh timeout. The [expected-mode ledger](results/expected-modes.csv) locates the independent reference relative to the exclusion, including cases at the band boundary.

| Protocol | Variable | $\delta$ | Complete | Timed out | Depth limit | Outer incomplete | Total panels | Total determinant calls | New s | Cumulative s |
|---|---|---|---|---|---|---|---|---|---|---|
| branch scan | sqrt | 0.0001 | 30 | 0 | 0 | 0 | 2 | 54–78 | 16.9–38.3 | 16.9–38.3 |
| independent | plain | 0.01 | 4 | 0 | 0 | 0 | 2 | 38–40 | 8.4–22.7 | 8.4–22.7 |
| independent | plain | 0.0001 | 1 | 0 | 0 | 0 | 6 | 308 | 122.1 | 122.1 |
| independent | sqrt | 0.001 | 2 | 0 | 0 | 0 | 2 | 41–44 | 7.3–11.6 | 7.3–11.6 |
| independent | sqrt | 0.0001 | 4 | 0 | 0 | 0 | 2 | 44–56 | 8.6–31.1 | 8.6–31.1 |
| independent | sqrt | 1e-05 | 0 | 1 | 0 | 0 | 8 | 391 | 150.3 | 150.3 |
| nested | plain | 0.01 | 20 | 0 | 0 | 0 | 2 | 38–43 | 6.5–23.0 | 6.5–23.0 |
| nested | plain | 0.001 | 24 | 0 | 0 | 0 | 4 | 108–124 | 11.8–40.7 | 18.3–62.4 |
| nested | plain | 0.0001 | 1 | 4 | 1 | 0 | 6–15 | 218–813 | 57.3–124.8 | 119.2–150.5 |
| nested | sqrt | 0.001 | 22 | 0 | 0 | 0 | 4 | 76–106 | 6.4–34.3 | 12.9–57.3 |
| nested | sqrt | 0.0001 | 1 | 4 | 1 | 0 | 7–15 | 279–781 | 70.5–129.6 | 106.1–150.6 |
| nested | sqrt | 1e-05 | 0 | 3 | 1 | 5 | 6–12 | 272–685 | 43.9–137.2 | 129.6–150.5 |

### Returned-root accuracy

Each row shows one completed, physically paired search at the stated phase, preferring the smallest completed exclusion. An empty return has its independently seeded local root shift in the last column. The [root table](results/roots.csv) gives the three error quantities for every paired return, including roots retained when a later strip timed out. [All physical proposals](results/proposals.csv) and [local reference shifts](results/local-references.csv) are separate records.

| Model | Signed nominal $t$ | Search and $\delta$ | Fine returned $k$ | Two-grid difference | Fine minus reference | Predicted scale | Local fine minus reference |
|---|---|---|---|---|---|---|---|
| ex1 | 0.1 | sqrt 0.0001 | 1.9117673817423038 | 2.22e-16 | -1.8e-13 | 1.94e-13 | -1.65e-13 |
| ex1 | 0.01 | sqrt 0.001 | 1.9743542511171162 | 6e-15 | 1.77e-12 | 1.95e-12 | 1.77e-12 |
| ex1 | 0.001 | sqrt 0.001 | 1.980823322340659 | 0 | 7.61e-12 | 1.95e-11 | 8.32e-12 |
| ex1 | 0.0001 | —  | — | — | — | 2.05e-10 | 7.21e-11 |
| ex1 | -0.0001 | —  | — | — | — | 1.86e-10 | -8.63e-11 |
| ex1 | -0.001 | sqrt 0.001 | 1.9822651530044606 | 7.04e-14 | -8.3e-12 | 1.95e-11 | -8.24e-12 |
| ex1 | -0.01 | sqrt 0.001 | 1.9887716011465046 | 0 | -1.08e-12 | 1.96e-12 | -1.08e-12 |
| ex1 | -0.1 | sqrt 0.0001 | 2.0549852982808585 | 3.55e-15 | -3.82e-14 | 1.99e-13 | -3.69e-14 |
| w3 | 0.01 | sqrt 0.0001 | 2.9715833878705067 | 4.44e-16 | 8.04e-14 | 1.57e-13 | 7.99e-14 |
| w3 | 0.0001 | —  | — | — | — | 1.77e-11 | 2.98e-11 |
| w3 | -0.0001 | —  | — | — | — | 1.78e-11 | -2.83e-11 |
| w3 | -0.01 | sqrt 0.001 | 2.977933513171231 | 0 | -1.9e-13 | 1.99e-13 | -1.89e-13 |
| w3 (second) | 0.0198 | sqrt 0.001 | 3.0077650604414727 | 4.44e-16 | 2.86e-13 | 1.39e-13 | 2.87e-13 |

### Branch scan

The expected detuning is a leave-one-out interpolation of the nearest four neighboring observed branch locations (the independent local references at larger detunings supply outer anchors). The search never uses this prediction. The [branch table](results/branch.csv) includes the interpolation phases and any off-branch return within twice the exclusion radius.

| $\beta$ | Interpolated $k_*-k_W$ | Returned $k$ | Grid difference | Fine minus reference | Predicted scale | Both complete | Branch verdict | Additional near-edge roots |
|---|---|---|---|---|---|---|---|---|
| 1.9806836386983033 | 0.0005 | 1.9811836384883061 | 1.67e-13 | 8.1e-11 | 3.91e-11 | True | on branch | — |
| 1.9808557132006104 | 0.0004 | 1.981255713043814 | 4.75e-13 | 1.01e-10 | 4.89e-11 | True | on branch | — |
| 1.9810277914588226 | 0.0003 | 1.9813277912834861 | 2.08e-12 | 3.13e-11 | 6.52e-11 | True | on branch | — |
| 1.981199873478221 | 0.0002 | 1.981399873379891 | 2.69e-13 | 4.27e-11 | 9.83e-11 | True | on branch | — |
| 1.9813375418053396 | 0.00012 | 1.9814575417863407 | 3.82e-12 | 6.27e-11 | 1.68e-10 | True | on branch | — |
| 1.9814063768736936 | 8e-05 | — | — | — | — | True | missed in excluded band | — |
| 1.9814752125456958 | 4e-05 | — | — | — | — | True | missed in excluded band | — |
| 1.9815440488216824 | 1.40468e-11 | — | — | — | — | True | missed in excluded band | — |
| 1.9816128857019928 | -4e-05 | — | — | — | — | True | missed in excluded band | — |
| 1.9816817231869635 | -8e-05 | — | — | — | — | True | missed in excluded band | — |
| 1.9817505612769335 | -0.00012 | 1.9816305613218432 | 3.99e-12 | -6.47e-11 | 1.58e-10 | True | on branch | — |
| 1.981888239273218 | -0.0002 | 1.9816882393935886 | 1.01e-12 | -4.88e-11 | 9.71e-11 | True | on branch | — |
| 1.9820603401777055 | -0.0003 | 1.9817603403729607 | 2.14e-12 | -3.82e-11 | 6.5e-11 | True | on branch | — |
| 1.9822324448750477 | -0.0004 | 1.9818324451309295 | 7.24e-14 | -2.5e-11 | 4.88e-11 | True | on branch | — |
| 1.9824045533705177 | -0.0005 | 1.9819045536606805 | 1.32e-13 | -2.26e-11 | 3.91e-11 | True | on branch | — |

### Rate fits and cost

| Quantity | Model | Side | Phases | Detuning range | $\log$–$\log$ slope | RMS log residual |
|---|---|---|---|---|---|---|
| local reference shift | ex1 | -1 | 4 | 0.0001–0.1 | -1.1 | 0.316 |
| local reference shift | ex1 | 1 | 4 | 0.0001–0.1 | -0.859 | 0.169 |
| local reference shift | w3 | -1 | 2 | 0.0001–0.01 | -1.09 | 0 |
| local reference shift | w3 | 1 | 2 | 0.0001–0.01 | -1.29 | 0 |
| interior returned root reference shift | ex1 | -1 | 7 | 0.00012–0.1 | -1.11 | 0.27 |
| interior returned root reference shift | ex1 | 1 | 7 | 0.00012–0.1 | -0.937 | 0.637 |

Fits use absolute fine-grid differences from the changed-Green reference. The two W3 distances determine a two-point slope. For the returned-root fit each phase contributes once, using complete searches whose reported root clears the exclusion boundary by more than the measured error. The raw root table flags boundary cases.

Measured 20 monitored runs, 5357.9 s total and 1.123 GiB maximum process-tree RSS. The [monitor ledger](results/cost.csv) lists every run. Requested ladder rows: 45 TODO, 79 complete, 5 outer_incomplete, 12 timed_out, 3 unresolved.
<!-- end measured tables -->

## Forecasts and boundaries

The [launch forecasts](plans/forecasts.md) give wall time and peak memory before each numerical block. MATLAB used five computational threads and a 2 GiB process-tree limit. The $k_W\pm0.02$ windows omit the two Example 1 modes with $|k_*-k_W|=0.1$. Those windows were searched. Additional windows of half-width 0.002 around the two detuned frequencies supply the away-from-Wood control.

For the width ladder, search first with $\delta=0.01$. On reducing $\delta$, reuse completed outer panels and their physically checked proposals. Apply the route under test only on the two newly admitted strips. Charge the measured outer determinant time against the 150 s cap. The table gives the extra and cumulative cost separately. The independent pilots and the 15-phase scan search the full retained intervals directly.

## Fallback algorithm and accuracy reference

1. Enumerate all background orders for which $k_W=|\beta+2\pi m/d|/\sqrt{\rho_e}$ is in the window or its exclusion overlaps the window. Subtract their open bands. Round retained floating-point endpoints away from Wood if subtraction rounded inward. List the bands as **unsearched**. A prior branch expected in a band is **missed in the excluded band**.
2. Search each retained component separately. At two neighboring Wood bands divide the intervening interval between their two closest edges. For the square-root route, use $u=\operatorname{sign}(k-k_W)\sqrt{|k-k_W|}$ and map the Lobatto nodes back to $k$. Children inherit the coordinate of their parent. A fresh ordered-QZ reference frame and fixed row and column scales are taken at the panel's coordinate midpoint. Each actual lead evaluation checks the common gap.
3. Use degrees 8, 16, 32 and 64. The maximum of the last three Chebyshev coefficients divided by the maximum coefficient must be below 1e-10. Both independent off-grid errors in the sampled maximum-modulus normalization must be below 1e-9. The old overlap and tiny-node checks apply. Polish candidate zeros by real Newton steps in physical $k$, clipped to the retained panel. Stop an unresolved chart or interpolant at depth eight or at the time cap. A cap or incomplete outer panel leaves open the rest of the requested window.
4. Pair proposals across the two grids within 1e-8. Both the four-wall RMS jump and the off-node material jump must be below 0.005 on both grids. Each fine jump must be at most the larger of 0.8 times its coarse jump and 1e-11. Tables distinguish incomplete coverage, unpaired proposals, and paired physical roots.

Search time covers matrix evaluations, interpolation and Newton polishing for one grid. A sample begun before the time cap can finish just after it. Off-node field checks and startup are charged to the monitored total. A reused interval keeps its original measured search time and panel count. Incremental timings cover only fresh work. Counts include new anchor determinants. The physical tests use the same candidate frequencies. The common port density and period equal one. Example 1 uses ports at $x=\pm1/2$ and its original star and two different leads. W3 has two staggered circular rows in each lead period and an empty center.

For the frequency comparison we changed the auxiliary Green problem independently of the search. At $Y=\pm H$ the outgoing homogeneous-background Fourier series converges exponentially. We prescribed its values and normal-coordinate derivatives (the first 65 orders) and matched quasi-periodicity on the side walls, fitting 96 proxies per edge against 192 side/top collocation points. The production fit has 80/160 and solves for the outward plane waves as unknowns. The reference uses the factored square root $\sqrt{(k-|\beta_m|)(k+|\beta_m|)}$ in its boundary data and 1e-14 FMM tolerance. The BIE port orders, geometry and QZ closure are the same. At physical displacement $(-0.4,-0.17)$, test each fit against the spectral sum through $|m|=80$. This point test measures a change in the shared Green error. The resulting frequency difference is an error estimate on the fine discretization.

At nominal detunings $+10^{-4}$ and $-10^{-4}$, increasing the changed-Green fit again from 192/96 to 224/112 boundary points/proxies per edge shifted the reference roots by 1.58e-14, 1.71e-12 for Example 1 and 2.22e-15, 1.17e-12 for W3, in that sign order. The largest shift was $1.71\times10^{-12}$. [Reference checks](output/run-020).

The reference root uses fresh local matrices and the real Newton correction computed from the left and right smallest singular vectors in one anchored chart. The prior branch records supply seeds only for this diagnostic. To predict the frequency shift, perturb the reference Green function by $b\exp(i\beta X)\cos(\gamma_0Y)$, with $X$ the periodic coordinate. Apply $b=10^{-6}$ and $i10^{-6}$ separately. Divide the projected matrix changes by the projected $k$ derivative and take the real parts. Multiply the Euclidean norm of these two measured directional sensitivities by $1.3\times10^{-14}/t$. This predicts a scale for grazing-mode error. Other spatial error components and the phase of the actual discrepancy can change the observed frequency shift.


## Sources and reproduction

The numerical copies from pole-free-v1 are `border_search.m` (unchanged regression), `border_matrix.m`, `border_data.m`, `log_det.m`, `border_field.m`, `physical_checks.m`, `jump_pair.m`, `probe_config.m`, `example_config.m`, `example_parameters.m`, and `search_i9_{config,geometry,physics,classify}.m`. The launcher and resource sampler also come from that experiment. `split_search.m` adapts its interpolation and polishing code. `fast_proxy.m` follows the geometry, collocation equations and source ordering of `kernel.precomp_proxy`. Its reference branch prescribes the remote-wall data described above. The shared MATLAB boundary-integral, Bloch, quadrature, geometry and FMM2D routines are loaded through explicit paths.

From the repository directory, choose a fresh output parent. The two CSV inputs are the explicitly supplied prior branch measurements. Scientific launches take the model parameters from the JSON plans and read only explicitly named same-experiment handoffs.

```sh
E=test/bie-bound/wood-fallback-v1
R="$E/output/replay"
P="$R/plans"
mkdir -p "$P"
cp "$E"/plans/*.json "$P/"
python3 -B "$E/make_plans.py" --fixed test/bie-bound/failure-probe-v1/results/wood-fixed.csv --branches test/bie-bound/failure-probe-v1/results/wood-branches.csv --output "$P"
python3 -B "$E/stage_plans.py" --plans "$P" --output "$R"
run_one() {
  python3 -B "$E/launch.py" --package-root . --fmm vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --plan "$P/$1.json" --output "$R/run-$2"
}
run_series() {
  python3 -B "$E/series.py" --package-root . --fmm vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --sequence "$P/$1.json" --output "$R"
}
run_one regression 001
run_one pilot 002
run_one proxycheck 003
run_one regular 004
run_series first-series
run_series nested-pilots
run_series measured-widths
python3 -B "$E/summarize.py" --runs "$R" --tables "$R/tables" --scan "$P/scan-phases.json" --plans "$P"
python3 -B "$E/audit.py" --runs "$R" --tables "$R/tables"
```

Earlier direct controls used the original outgoing precomputation. Its coefficient comparison with the distance-reuse implementation is in run-003. The run-004 controls also recorded energy and seam diagnostics. Later search decisions require only the two unchanged physical jump integrals. The explicit measured-widths sequence selects the width and phase blocks used here. The launcher sets each handoff root to the chosen replay directory. A new replay also enforces the 5400 s allowance. A blank cross-grid decision in the proposal CSV identifies a grid with no partner under that timing protocol. The [frequency audit](results/checks.json) reads the frequency logs independently of the search and checks the arithmetic of the retained outer-panel times and counts.

## Unfinished coverage and limits

The 20 monitored runs used 89.30 of the allowed 90 minutes. The remaining 42.1 s could not cover another width test at its forecast. Of the 144 requested width/grid/phase combinations, 45 remain TODO, all at $10^{-4}$ or $10^{-5}$. Of the remaining 99, 79 completed, 12 reached the time cap, three reached the depth limit and five inherited incomplete outer coverage. The 15-phase branch scan and both away controls are separate from these 144 rows.

At exact Wood the existing cell representation still divides by the vanishing normal wavenumber. The fallback can describe the coverage of the retained intervals and return physically checked numerical roots there. A branch inferred inside the exclusion is recorded as missed. Without independent branch information its count is unknown. At an exclusion boundary a numerical root and its changed-Green reference may fall on opposite sides within the frequency error. Enlarging the exclusion improves clearance and removes a larger part of the search window. Changing variables preserves the shared Green-function error.

For the 15-phase scan, the two grids can request the same exterior Green fit. They share exact-frequency proxy coefficients in memory for that phase (the density node count and the port cutoff do not enter the proxy fit). The physical cell matrices, determinant charts, off-grid tests and Newton iterations are still recomputed on each grid. Each scan row records the numbers of cache hits and builds. The independent-window pilots and width ladder use their original per-frequency assembly timing.


## Checks

- The coarse bordered search gave 1.5584378941820876. The guarded implementation gave 1.5584378941820878 at the same phase and resolution, within 2e-14 of 1.558437894182088. The three proxy-fit controls gave coefficient infinity-norm differences of zero. [Original search](output/run-001/regression.json) and [guarded search](output/run-003/check.json).
- At the two detunings of magnitude 0.1, both variables returned the branch on both grids in the separate control windows. The maximum difference between routes was 1.67e-14 against the predeclared 1e-13 tolerance. The paired jumps also passed.
- The independent [audit](results/checks.json) checks determinant and physical evaluation frequencies, compares retained panel unions to the requested complement, and reconstructs cumulative counts and times. It found zero excluded-band calls among 12,498 determinant cell evaluations and 64 physical checks. The largest retained-endpoint discrepancy across 117 completed windows was $4.45\times10^{-16}$ rounded upward. The multi-line synthetic test covered both separate and overlapping exclusions.
- Every slope in [rates.csv](results/rates.csv) has its fit range, sample count and log residual. The earlier 1.3e-14/t scale came from a fixed-point Green comparison. The wood-probe-v1 experiment fitted the Green discrepancy over 1e-7 to 0.001. Root comparisons in this experiment use the ranges shown in the frequency table.

The negative 0.01 W3 window has a second returned candidate near 3.007765060441473. The fine off-node wall and material jumps were 5.79e-12 and 2.64e-14. The changed-Green root was 3.007765060441187, a difference of $2.86\times10^{-13}$. Frequency errors use the corresponding reference at each root.
