# Group reliable evaluation version 1

grouprel means group reliable evaluation. BIE: boundary integral equation; CM: compressed moments; CPU: central processing unit; RSS: resident set size; JSON: JavaScript Object Notation; CSV: comma-separated values. Arb/Acb perform real/complex ball arithmetic.

Purpose: five residual groups for the saved B field, with actual lead state columns. All inputs are explicit identical copies; no refit or eigenvalue solve.

Plan: prepare central and both lead source data once, fork a dynamic queue with independent region setups. Keep up to 80 actual states initially, then select the smallest depth from the per-column finite integrals and group tail envelopes, using a 1e-6 squared-tail/finite criterion without C_g. The N+10 check uses additional already computed actual columns, not a fitted full map. A separate one-target full-map comparison checks the left evaluator. Right reproduction uses the original 59-state path inside the same full process.

Initial pilot forecast: 180–420 s, eight workers, below 2.5 GiB; covers both materials, junction/interior walls, center/lead seams and central panels 0/1. Full-run provisional 7–18 min, below 3 GiB, to be revised from the pilot. Numerical outputs are not launched until this forecast is checked against setup sizes.

Accepted outcome: run-007 completes all five reliable residual groups after the envelope repair; run-008 independently audits the sums and coverage. Historical failures are retained below.

run-001 stopped in setup: the scan-based tail loop was removed but its BL assignment was accidentally removed too. No target ran. Restore the named envelope list and repeat as run-002, unchanged 180–420 s / 2.5 GiB forecast.

run-002 pilot passed all 13 targets: 128.864 s monitored, 245.055 summed Python CPU seconds, .930 GiB peak process-tree RSS. Shared setup is 96.741 s. Eight-worker task prices: central 2.34–2.39 s; lead material 8.95–9.17 s; junction 3.28–3.35 s; interior wall 28.61–28.62 s; lead seam 27.65–27.70 s; center seam 3.82 s. All sampled independent polynomial Gauss checks passed. Left/right contraction bounds are .381407974/.386733375.

run-003 full-run forecast: 8–12 minutes (including source setup, all targets and separate reference checks), below 2.4 GiB, W=8. Keep 80 finite states plus one adjacent state; choose actual N by the groupwise squared-tail rule after prefix integration. The 59-state material and original wall reference checks are computed inside the run as validation, not substituted for production targets. Region setup is in the target jobs. The full run does not reuse any pilot model.

## Mathematical and cost boundaries

The lead source arrays contain 80 finite states plus the adjacent state for interior walls. The full run constructs those columns once for each lead. After evaluation, each lead/material, lead/interior-wall and lead/seam component selects its smallest N with certified tail square <=1e-6 of the lower enclosure of its finite squared norm. This separate-component rule is stronger than a test against the combined wall/seam group. N+10 uses the additional actual columns already evaluated, with no discarded column approximated by zero. This first run pays the 80-column preparation; it is not a benchmark optimized to the selected depth.

Each source/target polynomial has an individual column error. The finite bound sums `(sqrt(V_j)+sqrt(panel_length)*e_j)^2` over columns, then RE16 sums over panels. Tail bounds use the full group envelope and verified propagation contraction. Incident plane waves cancel analytically in the horizontal seam; remaining seam signs are `q*bottom-top` for value and `top_y-q*bottom_y` for derivative. The left junction uses center x=-.5 and lead x=.5; the left interior joins the current left face to the next cell's right face.

There are 408 production target tasks: 192 central materials, 128 lead materials, 32 junction-wall segments, 32 interior-wall segments and 24 top/bottom seam pairs. Boundary regions are generated within each task. The 32 junction tasks form extra scalar first-state regions rather than retrieving a full multi-column region. Thus the timing includes 48 central boundary faces, 96 multi-column lead faces, and 32 additional scalar junction-lead faces. A separate reference task reproduces the old right targets and forms the independent left full port map. It runs inside the same monitored process tree and is included in total wall/CPU.

Shared source and regular material expansions are computed once in the parent, then inherited by fork. Workers only read shared objects; temporary region models and node matrices are private. Every worker uses one FLINT thread. Output contains scalar ledgers and central polynomial coefficients, no large source/field cache. `Ct/Cz` mean double/single-layer Fourier coefficient matrices; `G/P` mean port-state/propagation matrices; `V_I` is the polynomial squared integral; `e_I` is its uniform model-error allowance.

## Historical run-003 stop at a nonfinite local envelope

run-003 stopped on right material panels 7 and 8. `material_group.build` returned from the self-interaction call, but the local analytic rectangle evaluation `lb=local(...,box)` supplied nonfinite interpolation envelopes to `column_models.models`; `material.up` rejected `nan`. Target centers are 15*pi/64 and 17*pi/64, half-length pi/64, local rectangle radius parameter .12. No narrower domain or altered error rule was tried after the failure. The exact offending square root/division has not been isolated. The next bounded diagnostic is those two local rectangles, rather than another full queue.

The worker experiment rule requires stopping after a failed numerical check. Pending work was cancelled; already executing tasks finished and wrote their records. There are 91 persisted task records: 89 successful (including the reference task), 2 failed. The main summary contains 74 returns before it observed the failure, so use the complete per-target files when counting completed work.

| Group | Successful targets | Whole bound / ratio / tail |
|---|---:|---|
| Central material | 10/192 | TODO |
| Left material | 9/64 | TODO |
| Right material | 7/64, two failed | TODO |
| Vertical walls | Junction 18/32, interior 20/32 | TODO |
| Horizontal seams | 24/24 pairs | Targets complete; tail selection and aggregation TODO |

At the run-003 stop, no old group result filled a missing target and no mixed Q or width was computed. The completed follow-up and audit are recorded below.

## Historical run-003 checks and costs

Inside run-003, the original right material, junction and interior checks give 7.888336094595634e-15, 4.044824800007654e-14 and 7.393821691539888e-15. Relative differences to the specified printed references are 4.6411e-14, 8.5542e-14 and 1.5198e-14, below the 1e-12 reproduction check. Central panels 0/1 reproduce their unrounded e_I values exactly.

The independent left full-map versus actual-state finite squared norm is approximately 5.477448570199071e-29; their difference is bounded by 4.34945301709e-53, within 2.10318043952e-37. Independent polynomial Gauss comparisons cover at least one target of each requested group and pass 1e-12 relative. The largest sampled wall difference is below 2.77e-51. Group tail-depth selection and the left N+10 group check were not reached.

Left/right contraction p=1 with upper norms .381407973117701 / .386733374894634. Global envelopes (material,wall,seam) are bounded by (272325.757090536,1320006.171728654,1911102.581447435) and (5784414.46859585,2512754.739185999,3623991.150248219). These are tail-envelope certificates, not residual-group certificates.

run-003 monitored wall=318.361583792 s, summed Python CPU=1635.893989 s, peak process-tree RSS=1.8149261475 GiB. Shared setup=95.784715792 s, queue=221.472573834 s, enclosing internal wall=317.258803250 s, leaving .001513624 s internal dispatch/output. External startup/monitor/output adds 1.102780542 s. The accepted pilot cost is 128.863811083 s wall, 245.055138 CPU s, .929916382 GiB. All three launches including the setup failure cost 481.537418375 monitored seconds. No resource limit was hit. These failed full-run costs do not establish the full five-group price against 7.16 or 67 minutes.

## Reproduction and files

From the repository working directory, the following are the executed commands. Use fresh run numbers to preserve these records; the launcher refuses to overwrite an existing output directory. Scientific inputs are explicit; no document or prior result is read as a hidden dependency.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/grouprel-v1/launch_arb.py --output test/bie-bound/grouprel-v1/output/run-002 --conda /Users/whc/opt/miniconda3/condabin/conda --script groups.py --forecast 420 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/coefficients.json --workers 8 --states 80 --pilot
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/grouprel-v1/launch_arb.py --output test/bie-bound/grouprel-v1/output/run-003 --conda /Users/whc/opt/miniconda3/condabin/conda --script groups.py --forecast 720 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/coefficients.json --workers 8 --states 80
```

Entry points: `groups.py` (shared setup, dynamic queue, tail selection, aggregation); `group_setup.py` (source and state caches); `material_group.py` (lead material models); `boundary_group.py` (junction/interior/seam models); `group_norms.py` (per-column finite integrals); `audit_groups.py` (unrun independent completed-group audit); `launch_arb.py` and `monitor_arb.py` (monitored isolated Python).

Evidence: `output/input/copy-check.json`; run-002/003 `setup.json`, `summary.json`, `target-*.json`, `monitor.json`, `resource.csv`, `run.log`; run-003 `reference-checks.json`; and `output/failure-summary.json`. Failed target records retain full tracebacks and timings. No large field caches are saved.

## Authorized envelope repair

The follow-up authorizes diagnosing and repairing the nonfinite local envelope while retaining run-003. run-004 forecast: 5–30 s, below .3 GiB. It records each geometry/speed/normal operation on the original rectangle, then checks a 16x16 covering subdivision for all 128 lead-material rectangles, at 192-bit ball precision. Positive real speed squared on every covering tile excludes a true zero and supplies the principal-square-root branch check. No field model is produced by this diagnostic.

run-004 certifies positive real speed squared on all 128 covering 16x16 subdivisions. On right panels 7/8 the coarse speed ball contains zero and the first nonfinite operation is normal_x=dy/speed (normal_y also fails), while all preceding quantities remain finite. Fine covering lower bounds are .0281571396793 / .0227806891980. This is interval overestimation, not an actual zero on either rectangle.

Repair: `envelope_gate.rectangle` recursively bisects the same rectangle, takes the maximum column norm over covering sub-boxes, and checks positive real speed squared at each accepted material box. No radius, interpolation degree or remainder formula is changed when subdivision succeeds. Nonfinite analytic inputs/nodes raise a typed finite gate for every target class. If covering subdivision cannot resolve it, material/boundary target panels split up to two levels, with their radii and half-lengths reduced together and analytic checks rerun. Central targets use their existing split mechanism, extended to the same finite gate. A persistent failure is retained and stops the queue.

run-005 forecast: 120–180 s, below 1.2 GiB, two workers. It rebuilds the shared data and evaluates only right material panels 7/8, with repaired local envelopes and all normal target checks. The full rectangle scan was completed in run-004; no prior field or target is reused.

run-005 passed right panels 7/8: e_I=1.4559198372999226e-22 / 1.4656549671735633e-22. Each local envelope used four covering sub-boxes (depth two), with positive real speed-squared lower bounds .01309270968 / .00894422849; no target split or radius change. Independent polynomial integral relative differences are below 3.742e-39. Monitored wall 102.694 s, CPU 106.642 s, peak .482 GiB.

run-006 full-run forecast from run-003: 95.785 shared seconds + (221.473 queue seconds)*(409/89) = 1113.563 seconds, about 18.56 minutes. Reserve 1200 seconds (20 minutes), below 2.4 GiB, eight workers. Including the rectangle diagnostic, repaired two-panel pilot and a small final audit remains below the fresh 30-minute soft compute budget. Region setup stays distributed; all inputs and all 409 jobs are recomputed in this run. The 128-rectangle scan found 20 nonfinite coarse right rectangles and none on the left, all resolved by covering zero-exclusion.

run-006 completed all 409 tasks in 528.682 s with 2.352 GiB peak RSS. Before accepting the final certificate, the generic wall-incident envelope was enlarged from the inherited imaginary-direction segment to the full complex rectangle (real and imaginary half-width R). This explicitly covers the interpolation ellipse without relying on cancellation along a center line. Field nodes and deterministic polynomials are unchanged; only an envelope is enlarged. The old wall pilot remains a numerical reproduction check.

run-007 repeats the whole pipeline with this conservative domain coverage. Forecast from run-006: 530–650 s, below 2.6 GiB, eight workers. The entire fresh result, including run-004/005/006, this repeat and a small audit, is forecast below 1400 monitored seconds, within the 30-minute soft budget. Both complete runs are retained and counted.

run-007 passed all 409 jobs in 517.672 s monitored, CPU 3283.416 s, peak 2.171 GiB. Enlarging the wall-incident envelope leaves all five displayed group uppers unchanged from run-006. run-008 independent aggregation forecast: 5 s, below .2 GiB. It reads run-007 explicitly, checks complete target/leaf coverage, re-adds decimal outward bounds in Arb and recomputes mixed Q/width. It performs no field re-evaluation.

## Accepted five-group certificate

The final result is run-007, independently aggregated by run-008. All 408 production targets and the additional same-run reference task passed. The following decimals are outward displays of the residual upper bounds. Analytic-domain, source-remainder and finite-ball errors are included under the CK/SI field definitions; scan trace constants are used only in the separately labelled mixed assembly.

| Group | Reliable epsilon upper | Floating B reference | Ratio | Tail-square upper | Targets |
|---|---:|---:|---:|---:|---:|
| Central material | 1.261590321446559e-12 | 1.2610675455e-12 | 1.0004145504 | 0 | 192 |
| Left material | 5.097297221126972e-14 | 6.0997763730e-14 | .8356531305 | 7.668602e-34 | 64 |
| Right material | 5.201040519675871e-14 | 6.3616652364e-14 | .8175596053 | 1.071072e-33 | 64 |
| Vertical walls | 2.155517374256269e-13 | 2.1561016159e-13 | .9997290288 | 5.664832e-34 | 32 junction + 32 interior |
| Horizontal seams | 6.993684954824288e-15 | 7.0953614059e-15 | .9856700110 | 2.458058e-35 | 24 pairs |

All ratios pass <=1.05. The two lead uppers are below their floating references; the references are not treated as exact values or lower bounds. The independent state/full-map comparison and polynomial integrations passed.

| Lead/component | First accepted N | Tail square | Tail / finite-square lower | Tail norm ratio at N+10 |
|---|---:|---:|---:|---:|
| Left material | 52 | 7.668602e-34 | 2.951457e-7 | 5.815972e-5 |
| Left interior walls | 54 | 3.643675e-34 | 2.423771e-7 | 5.815972e-5 |
| Left seams | 56 | 1.544560e-35 | 7.985279e-7 | 5.815972e-5 |
| Right material | 56 | 1.071072e-33 | 3.959499e-7 | 6.959605e-5 |
| Right interior walls | 56 | 2.021157e-34 | 2.267817e-7 | 6.959605e-5 |
| Right seams | 58 | 9.134986e-36 | 3.975076e-7 | 6.959605e-5 |

Both contraction powers are p=1. The verified upper r values are .381407973117701 and .386733374894634; r^10 upper values are 6.514749e-5 and 7.483703e-5. All six residual-norm intervals overlap their N+10 intervals. Full prior-depth choices, lower enclosures and positive overlap widths are in `run-007/groups.json`. The per-lead/component criterion is stronger than a combined wall/seam criterion. These selected depths do not remove the measured cost of preparing 80 finite columns plus one adjacent state.

Right material panels 7–13,22–24,39–41,50–56 needed local envelope subdivisions (two or four boxes). All original rectangles were certified by the independent 16x16 cover. Central self L increased to 41 on 10,27,92,93,94,97,98,99,164,181; 42 on 6,95,96,185; 43 on 89,102. No actual target split, smaller radius, omitted panel or high-self-error flag occurred. Generic nonfinite fallbacks remain bounded to two target-split levels.

## Final checks

1. Central whole-curve upper reproduces the earlier outward display; unrounded relative difference to the supplied decimal is below 1e-14. Central panels 0/1 e_I reproduce exactly. Same-run old-path right material/junction/interior outputs are 7.888336094595634e-15 / 4.044824800007654e-14 / 7.393821691539888e-15, within 8.56e-14 relative of the requested printed values. These are numerical baseline checks; the final group certificates use the repaired complete-domain envelopes.
2. Left actual-column versus full-map finite V difference <=4.350e-53, allowance >=2.103e-37. Every group has independent polynomial Gauss checks. The maximum sampled noncentral relative discrepancy is <2.77e-51; every central target also passed its independent integral. The audit verifies exact 408-target coverage and all central leaf partitions.
3. The N+10 tests pass for both leads and all three components: positive interval overlap and tail upper-norm ratios below the contraction tenth powers. No scan C_g enters the depth test.
4. Enlarging the wall-incident domain from a line to the full rectangle preserved all 216 noncentral polynomial-integral strings and all five displayed uppers (`output/domain-enlargement-check.json`).

## Final measured costs and mixed result

| Run-007 enclosing stage | Wall seconds |
|---|---:|
| Shared source/state/expansion setup | 95.670197708 |
| Distributed target queue, including reference task | 420.439780708 |
| Aggregation and internal output remainder | .082746334 |
| Internal total | 516.192724750 |
| Startup/monitor/external output | 1.479737000 |
| Monitored total | 517.672461750 |

CPU sum=3283.415788 s; peak process-tree RSS=2.170288086 GiB. Worker task CPU by kind: central 401.184858, lead material 977.330053, junction 96.504225, interior 1020.360052, seams 530.540091, references 161.542129 seconds. These overlap in wall time. The source/setup and dispatch CPU occupy the remaining total. Worker counts range 46–57; CPU per worker task sum is 397.68–399.07 s. No affinity was set; performance/efficiency core assignment is unknown.

Accepted full-run wall=8.628 min versus the earlier 7.16-min prediction and FEM's 67-min reference wall on 11 threads. This implementation pays 80-column preparation, actual left/right templates and same-run reference checks; it is not an optimized selected-depth benchmark. The boundary is saved defining field to residual certificates, excluding refit, candidate search, reliable trace constants and band-certificate computation.

Independent scalar audit run-008 adds 1.140443166 monitored seconds (.069724 CPU seconds). Its very short sampled RSS is not a useful tight peak estimate. The fresh result's diagnostic, repair pilot, two full runs and audit total 1151.420215541 monitored seconds (19.190 min); peak across them is 2.351669312 GiB. Earlier run-001/002/003 costs remain in the historical record and were not reset or erased.

With exact decimal scan inputs (2.490,1.181,1.234,1.036,1.036) and supplied reliable mass lower U=1.23587, outward arithmetic gives Q_mix<=3.496296878182387e-12 and full width 4*mu*Q_mix/(U-Q_mix)<=2.748365594108275e-11. This mixed width is not reliable until the trace constants are certified. No gap calculation is performed here.

## Follow-up reproduction commands

The accepted full run uses the same explicit input copies as the earlier commands. Use fresh output numbers for a rerun.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/grouprel-v1/launch_arb.py --output test/bie-bound/grouprel-v1/output/run-004 --conda /Users/whc/opt/miniconda3/condabin/conda --script rectangle_diagnostic.py --forecast 30 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/fixed-input.json --tiles 16
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/grouprel-v1/launch_arb.py --output test/bie-bound/grouprel-v1/output/run-005 --conda /Users/whc/opt/miniconda3/condabin/conda --script groups.py --forecast 180 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/coefficients.json --workers 2 --states 80 --repair-pilot
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/grouprel-v1/launch_arb.py --output test/bie-bound/grouprel-v1/output/run-007 --conda /Users/whc/opt/miniconda3/condabin/conda --script groups.py --forecast 650 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/input/coefficients.json --workers 8 --states 80
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/grouprel-v1/launch_arb.py --output test/bie-bound/grouprel-v1/output/run-008 --conda /Users/whc/opt/miniconda3/condabin/conda --script audit_groups.py --forecast 5 -- --run /Users/whc/Documents/Work/dot-research/test/bie-bound/grouprel-v1/output/run-007
python3 test/bie-bound/grouprel-v1/summarize_run.py --full test/bie-bound/grouprel-v1/output/run-007 --audit test/bie-bound/grouprel-v1/output/run-008 --diagnostic test/bie-bound/grouprel-v1/output/run-004 --repair test/bie-bound/grouprel-v1/output/run-005 --other-full test/bie-bound/grouprel-v1/output/run-006 --output test/bie-bound/grouprel-v1/output
```

`output/final-summary.json` is the compact final handoff; `output/targets.csv` indexes production/validation targets. It includes pointers through explicit run names to raw bounds, depth choices, per-worker times, exceptions and monitor records. `rectangle_diagnostic.py` records the exact failed operation and the covering nonzero tests; `envelope_gate.py` implements the shared finite/domain fallback. All earlier failed evidence remains available.
