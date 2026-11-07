# Solver cost version 1

BIE = boundary integral equation. FEM = finite element method. DtN = Dirichlet-to-Neumann. RSS = resident set size. P2, P3 and P4 denote polynomial degrees. DOF = degree of freedom. M is the Rayleigh half-width. An identifier g12, g24 or g48 gives the background subdivisions per unit cell side. I9 and I10 are inherited experiment identifiers.

FEM reached a distance of $10^{-10}$ in 27.46 s on P4 g24. BIE reached it in 38.81 s on 128/64/64 M6. For a candidate inside the reference interval, the same BIE run was 2.52 times faster than the cheapest qualifying FEM run, P4 g48. These are the cheapest measured cold runs at each tier.

## Accuracy tiers

| Distance in $k$ | Cheapest BIE, s / GiB | Cheapest FEM, s / GiB | BIE/FEM cold time |
|---|---|---|---:|
| 1e-6 | 128/64/64 M2, 38.59 / 0.835 | P4 g12, 16.68 / 1.047 | 2.31 |
| 1e-8 | 128/64/64 M2, 38.59 / 0.835 | P4 g12, 16.68 / 1.047 | 2.31 |
| 1e-10 | 128/64/64 M6, 38.81 / 0.810 | P4 g24, 27.46 / 1.289 | 1.41 |
| inside | 128/64/64 M6, 38.81 / 0.810 | P4 g48, 97.80 / 1.206 | 0.40 |

Times include MATLAB startup and exit. Each configuration was timed once. The reference is the example-1 frequency interval [1.5584378941776960, 1.5584378941864800] from [pipeline-v1](../pipeline-v1/README.md). An inside result receives no finer accuracy claim.

## Task and timing boundary

Return all candidates found in the supplied example-1 window [1.4509999999999998, 2.249], at beta=0.5. Both solvers start in a fresh MATLAB R2023b process with eleven computational and OpenMP threads. Rank eligible measured configurations by monitored wall time, including MATLAB startup, fresh operators, window search, confirmation and scalar output. The reference endpoints are used only in the postprocessor. The candidate count describes the search output. The interval-distance score gives zero to a candidate inside the reference interval without assigning it a smaller resolved error.

The supplied window is the common input. Its original lead classification cost is 28.2315 s plus 8.2481 s for representative/equal-lead checks, common upstream if a user starts from the wider classification grid. The new BIE searches start with an empty lead cache directly on that window. FEM likewise starts on the whole window and refines every retained P2 seed. Neither timed solver needs a separate classifier when the window is supplied.

## Reconciliation before the runs

| Existing measurement | Threads and starting information | Included costs | Use here |
|---|---|---|---|
| detsearch-v1, production 001, 512/256/256 M48 | 11, cold from wider gap grid | 28.23 s classification, 8.25 s representative checks, 111.55/6.49/3.13 s localization/polish/confirmation, 176.27 s process total, 0.943 GiB | Historical search-stage comparison. Classification precedes search in that process. |
| resolution-v1 001/003/006/007/008 | 11, cold from wider grid | Search subprocess including lead classification and checks costs 214.61/128.86/139.08/172.53/187.66 s for 512 M48, 256 M48, 384 M48, 512 M40, 512 M56. Remaining stages evaluate the field. | Historical comparison only. For 256 M48 the three search components total 71.2320 s. |
| i10/refine-v1 g12/g24/g48 | 11, supplied k0 and local window of half-width 0.01 | 9.04/24.38/104.03 s to final candidate across degrees and integration rules. Full process 25.05/39.61/127.84 s includes further estimation/output. Full-run peaks 1.663/1.712/2.509 decimal GB. | Recorded P4/check roots provide the FEM reproduction test. Local search and multidegree costs have different boundaries. |
| fem-goerisch/pipeline-v1 | 11, cold from supplied window | P2 complete-window seeding 1.81–1.96 s within MATLAB. Subsequent stages generate a field and an enclosure. | P2 method and cost reference. |

## Complete configurations

Each of the 21 completed searches returned one candidate. All rows use eleven MATLAB and OpenMP threads. In the BIE table N is the center node count and each lead uses N/2 nodes. The three call counts cover determinant localization, polish and fresh confirmation. Each BIE row below completed without a fallback. The upstream classification has zero incremental cost for both methods with the supplied window.

| Run | N / M | Matching dimension | Candidate $k$ | Reference distance | Gap s | Det / polish / confirm (s) | Calls | Cold s | Peak GiB |
|---|---|---:|---:|---|---:|---|---|---:|---:|
| 022 | 128 / 2 | 10 | 1.5584378956594565 | above 1.4730e-9 | 0 | 27.26 / 1.52 / 0.64 | 35+2+1 | 38.59 | 0.835 |
| 023 | 128 / 3 | 14 | 1.558437894231542 | above 4.5062e-11 | 0 | 29.18 / 1.45 / 0.82 | 35+2+1 | 42.47 | 0.843 |
| 021 | 128 / 4 | 18 | 1.5584378941826371 | inside | 0 | 27.65 / 1.30 / 0.80 | 35+2+1 | 40.06 | 0.873 |
| 020 | 128 / 6 | 26 | 1.558437894182088 | inside | 0 | 27.42 / 1.47 / 0.78 | 35+2+1 | 38.81 | 0.810 |
| 019 | 128 / 8 | 34 | 1.558437894182088 | inside | 0 | 29.58 / 1.66 / 0.65 | 35+2+1 | 42.18 | 0.722 |
| 018 | 128 / 12 | 50 | 1.5584378941820882 | inside | 0 | 26.75 / 1.35 / 0.81 | 35+2+1 | 39.32 | 0.845 |
| 017 | 128 / 16 | 66 | 1.5584378941820882 | inside | 0 | 30.07 / 1.52 / 0.66 | 35+2+1 | 44.13 | 0.747 |
| 014 | 128 / 24 | 98 | 1.558437894182089 | inside | 0 | 29.59 / 1.58 / 0.75 | 35+2+1 | 42.03 | 0.835 |
| 009 | 128 / 32 | 130 | 1.5584378941820884 | inside | 0 | 30.36 / 1.60 / 0.86 | 35+2+1 | 42.71 | 0.871 |
| 011 | 128 / 40 | 162 | 1.5584378941820887 | inside | 0 | 38.81 / 1.67 / 0.77 | 35+2+1 | 51.70 | 0.761 |
| 015 | 192 / 24 | 98 | 1.5584378941820882 | inside | 0 | 38.73 / 1.95 / 0.89 | 35+2+1 | 50.67 | 0.826 |
| 010 | 192 / 32 | 130 | 1.5584378941820882 | inside | 0 | 40.92 / 2.18 / 0.91 | 35+2+1 | 52.03 | 0.815 |
| 012 | 192 / 40 | 162 | 1.5584378941820882 | inside | 0 | 45.47 / 2.29 / 1.00 | 35+2+1 | 56.73 | 0.742 |
| 002 | 256 / 48 | 194 | 1.5584378941820882 | inside | 0 | 56.63 / 2.74 / 1.46 | 35+2+1 | 77.79 | 0.914 |
| 013 | 512 / 48 | 194 | 1.558437894182088 | inside | 0 | 124.80 / 7.84 / 3.99 | 35+2+1 | 150.28 | 0.973 |

Every FEM row starts with the same 19,476-DOF P2 problem and three shifts with 12 Ritz pairs each. Setup includes the local mesh, space checks, true-material point location and matrix assembly. The root and fresh-check times include frequency-dependent lead elimination and DtN computations. The cold wall column also includes scalar output and MATLAB process overhead. On g12, P3 used 5.12 s inside the solver versus 6.88 s for P4. Time outside the science timer was 15.89 versus 9.81 s, which accounts for P4 winning the cold-time comparison on that grid.

| Run | Degree / grid | Local free DOFs, L / core / R | Candidate $k$ | Reference distance | Gap s | P2 / setup / root / confirm (s) | Root + fresh calls | Cold s | Peak GiB |
|---|---|---|---:|---|---:|---|---|---:|---:|
| 004 | P3 g12 | 3366/3276/3366 | 1.5584380284825592 | above 1.3430e-7 | 0 | 2.22 / 1.36 / 1.31 / 0.12 | 9+1 | 21.01 | 0.911 |
| 005 | P4 g12 | 5968/5808/5968 | 1.5584378957008038 | above 1.5143e-9 | 0 | 2.20 / 1.83 / 2.51 / 0.23 | 9+1 | 16.68 | 1.047 |
| 006 | P3 g24 | 9297/9144/9234 | 1.5584378985535452 | above 4.3671e-9 | 0 | 2.10 / 2.78 / 4.67 / 0.44 | 9+1 | 19.84 | 1.004 |
| 003 | P4 g24 | 16496/16224/16384 | 1.5584378942107018 | above 2.4222e-11 | 0 | 2.07 / 3.88 / 8.62 / 0.87 | 9+1 | 27.46 | 1.289 |
| 007 | P3 g48 | 28989/28629/28908 | 1.5584378943984825 | above 2.1200e-10 | 0 | 2.13 / 5.98 / 21.94 / 2.10 | 10+1 | 40.99 | 1.251 |
| 008 | P4 g48 | 51472/50832/51328 | 1.558437894180259 | inside | 0 | 2.19 / 9.18 / 69.43 / 5.78 | 13+1 | 97.80 | 1.206 |

Raw scalar data include every candidate, its signed classification, exact distance from the binary64 root to the decimal interval, and its matching singular-value ratio. The numbered runs retain the full stage ledgers. [Configurations](output/configurations.csv), [candidates](output/candidates.csv), [tier selection](output/tiers.json).

## Coarsening and candidate count

The coarsest completed BIE configuration inside the interval on the tested ladder was **128/64/64 M4**, with $k=1.5584378941826371$. M3 gave a complete root $4.5062\times10^{-11}$ above the interval and M2 was $1.4730\times10^{-9}$ above it. M6 was the cheapest measured inside configuration. The M2 and M6 cold timings differed by only 0.22 s.

The density reduction to 96/48/48 at M24 reached the search stopping condition. Run-016 localized one near-real root. Re-evaluation of the last three distinct polish points from the saved Chebyshev coefficients gives complex step magnitudes $9.75$–$9.79\times10^{-14}$, above the $2\times10^{-14}$ polish threshold. The fallback computed 76 matching evaluations including a fresh confirmation. Its provisional point $k=1.5584378941822121$ was inside with a physical singular-value ratio $1.7860\times10^{-13}$. Its ambiguity cluster stayed at $2.5535\times10^{-14}$ against a $2\times10^{-14}$ width target. The solver returned zero complete candidates and status `AMBIGUITY_UNRESOLVED` for this point. This is a search qualification failure at this discretization. Its measured 95.16 s and 0.828 GiB are included in the study cost and the point is excluded from the tier ranking. [Fallback state](output/run-016/fallback-001/state.json).

## Checks and interpretation

1. **Reproduction.** BIE 256 M48 and 512 M48 both match the respective recorded roots bit for bit. For 256 M48 the three search components took 60.835 s versus 71.232 s previously (−14.6%). For 512 M48 they took 136.621 s versus 121.169 s (+12.8%). Both timing differences meet the 20% check. The revised FEM check passes on the saved run-003. The absolute frequency difference is $1.26121\times10^{-13}$ against $2\times10^{-12}$, and the recorded root lies in the new final bracket. The historical local multidegree computation and current window-only single-degree run have different start and cost boundaries, detailed below.
2. **Distance and refinement.** All completed candidates are inside or above the interval. Reference distance is nonincreasing on every tested density, Fourier, mesh and degree ladder. Checking every comparable pair with both discretization parameters nondecreasing gives zero exceptions. The 96-node provisional point is recorded separately. It cannot establish a passing refinement level.
3. **Count and resources.** All 15 complete BIE and six FEM configurations returned one candidate. All six P2 searches gave zero solver flags at all three shifts. Run-016 is the sole unresolved scientific search. Preflight found no competing numerical job at any launch. The largest measured RSS was 1.289 GiB. All monitored time sums to 1129.37 s (18.82 min), including the unresolved search and run-001’s 0.93 s operational stop. [Checks](output/final-checks.json).
4. **Prediction.** At $10^{-10}$, P4 g24 was 1.41 times faster than the cheapest qualifying BIE configuration, below the predicted factor of three. Relative to 512 M48 (150.28 s), the factor was 5.47. Reducing the BIE discretization therefore changes the comparison substantially. At $10^{-11}$, P4 g24 misses the tier, while the cheapest BIE and FEM measurements coincide with the inside row. For this example the solver paper can report a cold-time advantage for FEM at the first three tiers and for BIE at the inside tier, restricted to these tested configurations.

## Original reproduction check and manager correction

> **The FEM reproduction missed its prescribed tolerance.** P4 g24 differs from the recorded root by 1.26121e−13 against a 1e−13 limit. The BIE reproduction matched bit for bit. The sweep stopped at this check. The available pair establishes the cost of two configurations. The cheapest configuration in each accuracy tier remains open.

FEM P4 g24 returned 1.5584378942107018 against 1.5584378942105757 in [refine-v1](../../i10/refine-v1/README.md). The discrepancy exceeds the requested tolerance by 2.61213e−14. The new final bracket [1.5584378942102526, 1.5584378942107018] contains the old root and has width 4.49196e−13. The unchanged FEM convergence rule allows a bracket as wide as 2e−12. The new solver starts P4/check at the P2 full-window candidate 1.5584630910866906. The old multidegree computation starts its check chain at the P4/primary root, after transfer across degrees (`refine_i102.m`, lines 207–241). These paths can accept different endpoints under the same stopping rule. The bracket evidence is consistent with that mechanism. The new 15.541 s science time includes P2 seeding and a single P4/check root. The historical 24.38 s includes the local multidegree, multirule sequence.

The manager replaced the original absolute threshold with agreement within the allowed FEM stopping width and containment of the old root in the new bracket. The original check was more restrictive than the solver's endpoint selection from different seeds. Both outcomes are retained in [original check](output/comparison.json) and [revised check](output/revised-check.json).

## Forecast and settings

New configuration forecasts include MATLAB startup. BIE 256 M48 reproduction: 75–130 s, <1.5 GiB. BIE 128 and 192 center nodes, half as many per lead, each at M32 and M40: 40–150 s each, <1.5 GiB. FEM g12/g24/g48 with P3 and P4: 15–120 s each, <2.7 GiB. Outputs are scalar records and iteration histories. Limits are 30/40 minutes and 3 GiB per run. Each launch records a process check, checks the experiment size, and uses a new run directory. Predicted configuration ordering from the manager: P4 g24 at least three times faster than prior BIE settings near 1e-10, with the accuracy of reduced BIE settings to be measured.

Run-001 stopped before scientific output (0.93 s). The copied monitor used the previous release task’s absolute worktree cap. The monitor now enforces the current 100 MB experiment limit and stated headroom. Run-002 repeats the 256 M48 forecast.

For the continuation, the g48 estimate was 35–160 s and <2.8 GiB for each degree, based on the earlier maximum of 2.509 decimal GB (2.336 GiB). P3/P4 g12 and P3 g24 were estimated at 12–55 s, <2.0 GiB. The 512 M48 BIE forecast was 100–210 s, <1.7 GiB. Each coarser BIE run was forecast at 25–150 s, <1.6 GiB. Both M32 configurations qualified for M24. Density was then reduced at M24, followed by a Fourier-width ladder at the last passing density through M16,12,8,6,4,2. One M3 measurement resolved the intervening integer between the inside M4 and outside M2 points. Each monitored run retained scalar output and its resource ledger.

## Reproduction

From the checkout, set `ROOT` to its absolute path, `EX` to this experiment directory, `OUT` to a fresh output parent, and `MATLAB` to the R2023b executable. Use a fresh numbered directory for each launch.

```sh
python3 -B "$EX/launch.py" --package-root "$ROOT" --i9 "$ROOT/test/i9/search-v1" --fmm "$ROOT/vendor/fmm2d/matlab" --fem "$ROOT/test/fem-goerisch/pipeline-v1" --matlab "$MATLAB" --solver bie --size 256 --order 48 --output "$OUT/run-002"
python3 -B "$EX/launch.py" --package-root "$ROOT" --i9 "$ROOT/test/i9/search-v1" --fmm "$ROOT/vendor/fmm2d/matlab" --fem "$ROOT/test/fem-goerisch/pipeline-v1" --matlab "$MATLAB" --solver fem --size 24 --order 4 --output "$OUT/run-003"
```

The BIE driver uses the production interpolation, polishing and fresh SVD from resolution-v1/varied/search and the I9 numerical kernels. The copied I9 adapter omits large evidence writes. The FEM driver uses the wide-window search from fem-goerisch/pipeline-v1 and the mesh, matrices and branch solver from its direct_native.m. It assembles the final check quadrature directly (volume order 16, four material-strip subpanels with 12 points per direction). Every P2 seed is refined, followed by a fresh condensed-matrix and center-residual check. The timed code reads only source and explicit settings. No field MAT files are generated.

For the full ladder, use the same output parent and path arguments as in the two single-run examples. Then run the fixed and conditional configurations below in Bash or Zsh. The controller supplies explicit size and order to each cold driver and checks machine idleness before each run.

```bash
args=(--package-root "$ROOT" --i9 "$ROOT/test/i9/search-v1" --fmm "$ROOT/vendor/fmm2d/matlab" --fem "$ROOT/test/fem-goerisch/pipeline-v1" --matlab "$MATLAB" --output "$OUT")
python3 -B "$EX/ladder.py" "${args[@]}" --first 4 fem,12,3 fem,12,4 fem,24,3 fem,48,3 fem,48,4 bie,128,32 bie,192,32 bie,128,40 bie,192,40 bie,512,48
python3 -B "$EX/coarsen.py" "${args[@]}" --first 14
python3 -B "$EX/ladder.py" "${args[@]}" --first 23 bie,128,3
python3 -B "$EX/summarize.py" --output "$OUT" --tables
```
