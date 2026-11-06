# Example 2 version 1

BIE means boundary integral equation; DtN means Dirichlet-to-Neumann; PWE means plane-wave expansion; QZ means generalized Schur factorization; RSS means resident set size; FMM means fast multipole method; MFS means method of fundamental solutions; CSV means comma-separated values; JSON means JavaScript Object Notation. I9 is the inherited experiment-series identifier.

Purpose: reliable BIE enclosure for an empty-center, unequal-period, non-reflection-symmetric waveguide. B2 is complete in run-015: mu width <=3.0865909832205e-12, cold wall1058.142398792 s, peak2.237457275 GiB. The real-ball power bug was repaired without changing the radial validity gate or error formula. Historical forecasts and failed runs below are retained; use the final run-015 result section for the current outcome.

Source: search and field helpers are copied from pipeline-v1 and I9 search-v1. All scientific inputs are explicit example structs. The reference path retains the original arithmetic. Empty center uses exactly zero reflection and diagonal free propagation, with zero density rows.

B1 prelaunch forecast: reference regression 4–7 min, 2 GiB; initial geometry search 3–8 min, 2 GiB; two-resolution full-phase plane-wave bands 1–5 min, 1 GiB. Per run 30/40 min and 3 GiB. Global worktree headroom is about 130 MB; retain compact exports, no MAT fields.

Results and reproduction commands are given below.

Run-001 found the exact reference frequency, then stopped in the comparison reader: MATLAB decoded heterogeneous piece records as a cell array. This is an output-reader error; no numerical assertion failed. The reader now accepts either cell or struct arrays. Run-002 repeats the complete regression with the same 4–7 min / 2 GiB forecast. Large completed run-001 JSONs are retained with lossless gzip compression.

Run-002 passes reference regression: candidate hex exactly matches, all six tau/zeta coefficient-array relative differences are zero. Next run-003: full Bloch phase [-pi,pi], two PWE cutoffs 6 and 8, 129 phase nodes plus local extremum searches, both leads. Forecast 1–5 min, <1 GiB; no other numerical run overlaps.

Run-003: cutoffs 6/8 give common first-gap edges about 1.4410 and 2.3957; maximum edge change across both leads is 6.33e-4. The right second band differs at opposite phases by 0.00369, so no half-phase reduction is used. Run-004 starts the inherited wide-window search from model parameters alone (1.45 to 2.25 coarse grid, with original gap extension if needed). Forecast 3–8 min and 2 GiB; reference output is compressed only after its monitor has exited.

Run-004 completes: one candidate 1.8916961400527375, relative physical singular value 7.53e-15; propagation Frobenius norms .295318/.334367. No alternate geometry was needed. Run-005 independently polishes the same-experiment candidate with 384 nodes per lead (versus 256), fixed M=48, then rebuilds/exports that field. Forecast 1–3 min, 2 GiB. It receives the run-004 frequency explicitly; no reference frequency or old experiment output enters the solve.

Before closure, the reference-name configuration shortcut was removed: the reference example now goes through the same explicit side-width/rotation/configuration plumbing as the new example (with empty_center=false, equal widths and zero angles). Run-006 repeats the reference regression after this change, forecast 3–5 min / 1.5 GiB from run-002. This tests the generalized parameter path rather than only the inherited reference dispatch. Runs 004/005 already used this generalized path and are unchanged.

## Accepted B1 result

Use run-004 (256 lead nodes) as the B2 starting discretization, with run-005 (384 nodes) as the independent node-count check. Both give k=1.8916961400527375, binary64 `3ffe44632bf7ef62`, at beta=.5, d=1, L0=Lminus=1, Lplus=.85, right rotation=.13 rad. The center has no material boundary and no density rows. The original star entries retained in the legacy parameter vector are unused compatibility metadata; the explicit example and piece shape govern the new path.

The common first gap is approximately (1.441,2.396) in k. Both complete phase ranges were sampled, without symmetry reduction; maximum change of the band edges from PWE cutoff6 to8 is6.3264e-4. Candidate distances to the finer-grid edges are .450715/.503998. Root probes at k±1e-7 have determinant phase change -3.14159255594. Minimum background |gamma_m|=1.82442, so there is no Wood channel at this candidate.

| Run | Purpose | Wall seconds | Peak GiB | Result |
|---|---|---:|---:|---|
| 001 | Original reference regression attempt | 200.219557 | 1.142746 | Output-reader error, preserved |
| 002 | Reference regression | 194.780615 | 1.126770 | Exact frequency bits and zero density differences |
| 003 | Two full-phase band discretizations | 6.301809 | .162201 | Both sides; no half-range shortcut |
| 004 | New example search and field | 422.771473 | 1.000290 | sigma_min2.15325e-14, sigma_second1.351706 |
| 005 | 384-node root/field | 34.467263 | 1.159897 | Same frequency bits; sigma_min1.98543e-14 |
| 006 | Reference through final shared parameter path | 201.270365 | 1.128738 | Exact frequency bits and all six density differences zero |

Propagation Frobenius norms are .2953179563 and .3343673410; spectral norms .2951755061 and .3337221056. All B1 numerical checks pass. Total monitored wall across all six runs is1059.811082 s, including the preserved operational failure and all regressions. These six runs constitute B1; the later B2 runs are recorded below.

## Reproduction

Run from the repository directory with an explicitly supplied fresh output path. `launch.py` performs ps preflight and invokes the copied monitor. MATLAB runs use11 computational/OpenMP threads, OMP_DYNAMIC=FALSE; the band calculation uses one thread. Escalated permission is needed for MATLAB and process-tree monitoring in this environment.

```sh
BASE=/Users/whc/Documents/Work/dot-research
python3 "$BASE/test/bie-bound/example2-v1/launch.py" --mode search --output "$OUT" --center-width 1 --right-period .85 --rotation .13 --nodes 256 --package-root "$BASE" --fmm-root "$BASE/vendor/fmm2d/matlab" --matlab /Applications/MATLAB_R2023b.app/bin/matlab
```

Other modes use a different fresh run number and the same explicit path arguments:
- `--mode regression`: first-example regression, fresh search and both original/generalized density rebuilds.
- `--mode bands --conda /Users/whc/opt/miniconda3/condabin/conda --cutoffs 6 8`: full-phase PWE comparison.
- `--mode confirm --nodes 384 --candidate 1.8916961400527375`: local refinement from the run-004 candidate. No older experiment's output is opened.

`example_parameters.m` defines the scientific geometry; `example_config.m` and `example_field_config.m` plumb it into the inherited algorithms. `confirm_root.m` uses a normalized log determinant and centered derivative with h=1e-6; it does not substitute a known eigenvalue. `bands.py` includes 1/(L*d), scaled x wave numbers, and rotated source geometry. The shared BIE port basis keeps its 1/sqrt(d) normalization and own wall phase origins.

## Handoffs and B2 work

`reference-results.json` contains all headline scalars/checks; `geometry.csv` and `cells.csv` are drawing data; `code-inventory.csv` gives138 source positions in34 files with changes or remaining work. Rebuild the inventory with:

```sh
python3 test/bie-bound/example2-v1/inventory_build.py --source-root /Users/whc/Documents/Work/dot-research --output test/bie-bound/example2-v1/code-inventory.csv
```

The B1 exports contain exact binary64 densities, incidents, side propagation matrices/states, widths and rotations; their B fit was `TODO_B2` and disk table empty. The current B2 exporter computes the B fit and exports three proposed background mass disks. Large completed JSON exports are retained as lossless `.json.gz`; decompress only into a new owned output directory when B2 needs an explicit input. No large MAT output exists.

The original B1 work list was to handle zero central source/self terms, rotate analytic geometry and divided chords, use side-specific boundary coordinates/seam lengths/tail distances, fit the B field (zero center coefficient), select new mass disks including background disks if useful, reverify trace constants and certify both full Bloch phase ranges with the 1/(L*d) factor. The original fit's .5 is a y-period half-length and H=1.1 is a fit-box extent; neither should be replaced mechanically by Lplus/2. The report forecasts14–22 minutes and1.5–2.5 GiB for B2 after these changes; no Q/width is inferred from root stability.

## B2 plan and first feasibility check

The generalized full-phase band pilot uses four phase panels per lead (the two
extreme panels and both neighbours of zero), at 128 bits, including independent
LDL inertia and a failing control. Forecast: 25–50 s, below 0.5 GiB; no field
or B1 output is read. This was the prelaunch forecast; outcomes follow below. New reliable stages are copied into band/residual/mass/
enclosure. The band pilot's script is `band_pilot.py OUTPUT`.

B2 run-008 forecast: full original-example regression through the generalized
source path, 14–17 minutes, 1.9–2.3 GiB. It includes search, field/B fit, all
five residual groups, mass, two trace-constant configurations, rational assembly
and 944 full-phase sign tests. Retained output forecast 35 MB. The old scientific
outputs are not read; literal scalar references are checked after assembly.

Run-008 passed the full regression: identical candidate bits, all five epsilon
values, Q and interval width. Wall time 929.860 s; peak process-tree RSS 1.992 GiB.
The full-phase extension passed all 944 tests. After that run, the band comparison
was extended to an independent NumPy boundary integral, and the driver gained an
explicit geometry/proxy/Wood-conditions stage (no change to residual arithmetic).

B2 run-009 forecast: empty-center cold start, 17–24 minutes, 2.0–2.5 GiB.
Search forecast 420–500 s; field/B fit 20–30 s; four residual groups 350–650 s;
conditions, mass, trace constants and audits under 20 s; full-phase band 150–180 s.
Retained output forecast 30 MB. One driver shares 30/40 minute limits across stages.

```sh
python3 test/bie-bound/example2-v1/run_pipeline.py --example empty-rotated --output /Users/whc/Documents/Work/dot-research/test/bie-bound/example2-v1/output/run-009 --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --conda /Users/whc/opt/miniconda3/condabin/conda
```

## B2 measured outcome and checks

| Run | Purpose | Wall seconds | Peak process-tree GiB | Status |
|---|---|---:|---:|---|
| 007 | Second-example band pilot, 4 phase panels per lead | 7.646710 | .198715 | 16 sign tests, independent inertia and failing control passed; incomplete phase coverage |
| 008 | Full reference cold-start regression | 929.860486 | 1.992004 | Same candidate bits, five residual bounds, Q and width; 944 band sign tests passed |
| 009 | Second-example cold start | 829.398968 | 2.147995 | Stopped at right material panel 14; partial result only |

Run-009 rebuilt candidate `1.8916961400527375` (`3ffe44632bf7ef62`), densities,
propagation and B coefficients without B1 output inputs. Geometry/proxy/Wood gates
passed. Arb Frobenius contraction bounds with p=1 are .2953179563264368 (left)
and .3343673410111507 (right). Center material is exactly empty; the center seam
is exactly zero for the finite Rayleigh representation.

The failure is preserved in
`output/run-009/03-residuals/target-material-2-14.json`:
`lead_self.compute -> kernel -> self_interaction.free_blocks -> Radial.eval`.
The check is abs(q)<2 for q=(xt-xs)^2+(yt-ys)^2 at a real Chebyshev node.
The failed q ball and source/node indices were not logged. The actual real-curve
radius is below .24, so real chord squared is at most .2304; the record alone
cannot distinguish a nonfinite ball, interval overestimation or an implementation
error. No subsequent diagnostic run or gate change was made.

Of 217 planned tasks, 125 records were retained after pending work was cancelled:
124 passed and one failed. Successful material panels: left18/64, right17/64;
all64 wall and24 seam target records completed. These are partial per-target
certificates, not complete group bounds. The independent left full-map/state-column
finite sum difference is 3.0464703687349103e-53, within 2.889922706770419e-37;
completed independent Gauss comparisons have maximum relative difference
2.648643995951462e-51. Full residual coverage, N+10 summary, mass, trace constants,
assembly and the second-example full-phase band certificate remain TODO.

Run-009 driver stage times: search463.874657292 s; field/B fit20.870251083 s;
conditions1.261399375 s; residual partial run342.051931916 s; scheduling/remainder
1.340728459 s. Total829.398968125 s includes failure handling. Residual CPU time
2037.805983 s. These times describe an incomplete pipeline and are not a total
cost comparison with the completed first example.

`b2-results.json` contains the compact scalar handoff. Completed large JSON
artifacts are retained as lossless `.json.gz`. Some completed run-008 residual
paths contain a small JSON pointer with `archive`, `encoding`, `original_format`;
the named gzip contains the original JSON. Failure logs and the failed target
remain directly readable. `port_b2.py` and `port_b2_checks.py` are one-time source
editing records, not scientific entry points and must not be rerun. Reproduction
uses `run_pipeline.py` with a fresh output directory; it refuses a nonempty one.

## Stage 20b continuation

Run-010 isolates right material panel14 using explicit run-009 field/fit inputs.
It records target/source balls and the failed gate operand without changing the
gate or radial error formula. Forecast90–150 s, .6 GiB, under1 MB new outputs.
The later cold start will regenerate every scientific input.

Run-011 scalar-operation diagnosis: forecast under5 s, .1 GiB. Compare integer power and multiplication on the recorded zero-containing real balls.

Run-010 reproduced the failure (70.662 s, .476 GiB): node24 equals source261;
delta balls contain zero at about1e-38. Run-011 found arb **2 returns NaN while
explicit multiplication gives a finite enclosure below4.72e-76. The repair uses
dx*dx+dy*dy only in the real-node lead kernel; Radial.eval and its tail stay unchanged.
Run-012 fixed-panel forecast90–150 s, .6 GiB. Run-013 reference material-panel14
plus full assembly forecast90–160 s, .6 GiB; acceptance relative change1e-6
in the panel bound and identical printed assembly, since only local arithmetic changed.

Run-012 passed: 56,448 q checks, maximum upper bound .17380187642187205;
panel e_I=1.3976264016865075e-18. Wall74.707438 s, peak.457520 GiB.
Run-014 planned full cold start:18–24 min, peak2.0–2.5 GiB, retained output
about30–35 MB, against current total about952 MB. Search and every handoff are
regenerated; no earlier B1/B2 output is a scientific input. One monitored driver
shares the30/40 min and3 GiB limits across all stages.

Run-013 passed reference panel14: finite_upper7.212735066690878e-15,
relative change0.0; maximum q upper.17380180748594121 over55,296 calls.
The two trace-constant configurations and exact-rational assembly reproduce
all printed Q/R/interval/width/T1.5 values. Wall102.986412 s, peak.430740 GiB.
Run-014 is the fresh second-example full pipeline after this repair.

Run-014 completed all217 target computations and the internal N+10 checks, but
the outer monitor stopped at WORKTREE_DISK_LIMIT before independent audit.
Wall886.095 s, peak1.923 GiB; logs and exact outputs are preserved.
Run-015 is a corrected cold rerun. Completed historical JSON is losslessly
archived; identical archived contents use experiment-local links. New residual
JSON omits whitespace, and completed search artifacts are archived after their
last scientific read. These are output-only changes. Forecast18–24 min,2.5 GiB,
under35 MB retained growth, with at least55 MB prelaunch headroom.

## Final B2 result: run-015

All217 tasks passed:216 coverage records (including8 exactly zero center seams)
and one independent port/state map check. All944 full-phase band sign tests pass
on k in(1.46,2.37); eight independent LDL checks give1 negative and168 positive
pivots, and the deliberately failing control is rejected. No target splits occurred.

| Quantity | Reliable result |
|---|---|
| Candidate k | 1.8916961400527375, binary64 3ffe44632bf7ef62 |
| mu interval | [3.5785142862888827713753245,3.5785142862919693623585451] |
| k interval | [1.8916961400523295383402818,1.8916961400531453646555839] |
| Mathematical full width upper | 3.0865909832205e-12 |
| Printed endpoint difference | 3.0865909832206e-12 |
| Q upper / U used lower | 1.39283748862432820e-13 / .645928 |
| R upper | 1.5432954916103e-12 |
| Epsilon center/left/right/walls/seams | 0 / 2.071592951936118e-14 / 2.304042346921608e-14 / 7.757931370382122e-14 / 8.900234823729722e-15 |
| C center/left/right/walls/seams | 0 / 1.135325 / 1.173284 / 1.026040 / 1.026040 |
| Band lower/upper minimum, left | 2.921868330851555 / .2374690346658532 |
| Band lower/upper minimum, right | .4370127110390786 / 1.1990155902279804 |

The exact input field is piecewise Helmholtz, with continuous source densities,
three explicit images,480 fixed external point sources, and finite Rayleigh terms.
The center has no material boundary. All real-ball operations, analytic integration
remainders, lead tails, mass disks, trace constants and full-phase band checks
are included. The interval contains at least one point-spectrum eigenvalue;
uniqueness is not asserted.

Tail depths (material/interior wall/seam) are42/44/45 on the left and52/51/52
on the right. Each tail-squared/finite-squared ratio is below1e-6; all N+10
comparisons overlap. The left full-map/state finite sum difference3.046471e-53
is below its allowance2.889922e-37. Independent Gauss relative difference is at
most2.648644e-51. Two trace configurations and160/192-bit plus exact-rational
assemblies give identical printed endpoints. Candidate and interval containment
checks pass. Raw values are in `output/run-015/` and `b2-results.json`.

| Stage | Driver seconds | Stage peak GiB | Resources |
|---|---:|---:|---|
| Gap classification and determinant search |453.182348500|1.007156|MATLAB11 threads|
| Field/density export and B fit |18.417133708|1.054932|MATLAB11 threads|
| Representation conditions |1.275166833|.000473*|Arb1 process|
| Reliable groups and tails |434.121112041|2.223877|Arb8 workers|
| Independent residual audit |1.281506709|.000412*|Arb1 process|
| Three background mass disks |1.323836333|.004227*|Arb1 process|
| Trace constants and assembly |1.333536834|.003143*|Arb1 process|
| Full-phase band certificate |145.405745500|.337067|Arb1 process|
| Parent/startup/output/orchestration remainder |1.802012334|—|—|
| End to end |1058.142398792|2.237457275|Whole process tree|

Short stages marked* can fall between RSS samples; use the whole-tree peak.
The disjoint stage sum1056.340386458 plus remainder1.802012334 equals the measured
wall time. Residual setup66.312261417 s and queue366.403867334 s are already in
that stage; summed residual CPU2773.666267 s. The successful run retained about
29.3 MB. Historical diagnostic and failed-run costs are separate:

| Run | Status | Monitor seconds | Peak GiB |
|---|---|---:|---:|
|010|Recorded original panel14 NaN|70.661634417|.476211548|
|011|Scalar real-ball power/product comparison|1.271614917|sample too short|
|012|Repaired panel14 pass|74.707437708|.457519531|
|013|Reference panel and full assembly pass|102.986411917|.430740356|
|014|All targets completed; output-space guard stopped handoff|886.095406500|1.922958374|
|015|Complete cold result|1058.142398792|2.237457275|

### Reproduction and compact summary

Set OUT to a new empty directory (the existing run numbers refuse reuse).
The driver runs the process preflight and monitor; use the approved escalated
execution channel for this environment.

```sh
python3 test/bie-bound/example2-v1/run_pipeline.py --example empty-rotated --output "$OUT" --package-root /Users/whc/Documents/Work/dot-research --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --conda /Users/whc/opt/miniconda3/condabin/conda
python3 test/bie-bound/example2-v1/summarize_b2.py --run "$OUT" --output test/bie-bound/example2-v1/b2-results.json
```

The diagnostic entry is `diagnose_panel.py --input FIELD --coefficients FIT
--output OUT --side 2 --panel 14`, under the copied monitor. It logs q operands
if a gate fails and otherwise its maximum over calls. `scalar_probe.py OUT`
reproduces the power/product issue. `regression_local.py` takes explicit field,
fit, panel-reference, groups, disks and assembly-reference paths; its actual
run-013 command is retained in `output/run-013/command.json`.

Completed JSON files may be represented by an `archive` pointer to a lossless
`.json.gz`; byte-identical decompressed contents may share an experiment-local
symbolic link. No numerical cold-start stage reads these historical outputs.
`scientific-inputs.json` and stage file-access records identify the new run's
handoffs. The former code-inventory B2 TODOs are implemented in the local
field/residual/mass/enclosure/band directories; the final cold run exercises them.
