# Self-interaction version 1

`selfint` means self-interaction. BIE is boundary integral equation, FEM finite element method, CM compressed source moments, DCT discrete cosine transform, RSS resident set size, JSON JavaScript Object Notation. Arb/Acb denote real/complex ball arithmetic. CPU means central processing unit. `monitor_arb.py` monitors Arb computations; `reproduce.py` reproduces prior domain bounds, `audit.py` independently integrates residual polynomials, and `cost.py` makes conditional cost projections. SI labels equations in selfint-accel. RE labels equations in reliable-eval-design. Q3 labels the entire radial expansions in reliable-bound.

**The decisive panels 0 and 1 pass.** Self-interaction takes 1.4941/1.4698 s, with reliable uniform errors below 2.34278e-18/3.26423e-18. D1 reuse completed panels 0–5, but panel 6 exceeded the 1e-16 interpolation-error threshold. The numerical experiment stopped there. Parallel measurement is unrun.

## Input and method

The explicit binary64 field is copied unchanged from matrel-v1 run-001. Byte equality was checked before computing. No MATLAB rerun or new field is used. Exact phase and dispersion, densities, wave number, normals, source Jacobians and Müller signs retain the previous conventions. The copied domain routine reproduces both old H_A and H_B with zero relative difference (`run-001/reproduce/comparison.json`). `material.py`, `self_interaction.py`, `panel.py` and the monitoring/audit helpers originate in matrel-v1; original files remain unchanged.

Target panels 192, source panels 160, proxy degree 40, other degree 52. A3 uses 40 real Chebyshev roots, 1152 Kress nodes, source strip 0.08, ellipse parameter 4.5 and target disk radius 0.04. Node arithmetic uses 128 bits; DCT and power-basis conversion use 192 bits. Each node ball contains the exact cosine node and finite Q3 truncation uncertainty. Its exact binary midpoint is the only sample supplied to conversion. SI5, node radii, interpolation remainder and conversion radii enter SI8 once each. Conversion coefficient midpoints are padded to degree 52 and added with the signed other contributions. D2 pays the target tail only for M_local + M_proxy. The second raw Müller row is negated to form the flux jump.

`chebyshev.py` recomputes both analytic domains: the radius-h disk/source strip 0.08 for SI5, and radius-0.04 disk/source strip 0.0625 for M_self. Every retained tile verifies positive real parts of both squared speeds and the divided-chord square, plus |q| < 2 for Q3. The ellipse semimajor axis is bounded by 0.038633591 < 0.04. Branch checks and material non-wrapping are executed. Reliable bounds include ball rounding for the exact exported field under these verified analytic-domain conditions.

Independent controls use x = -0.7, 0, 0.7, 192 bits, 3072 sources, and their SI5 bound. These controls inspect function values, not equality of two different polynomial constructions. Independent 53-node Gauss integration checks each decisive polynomial's squared norm. Explicitly supplied old floating samples serve only as a sign/reference comparison.

`cached.py` prepares source jets, moments and Kress geometry once at 128 bits. Full exact input, density, geometry, wave number, partition, orders and precision enter the equality key. Changing the source count is rejected. Target kernels and analytic envelopes are always recomputed. The serial batch evaluated cache mismatch rejection before its panel loop. The failed batch did not flush that flag separately; its successful continuation and unchanged outputs are retained. Code now writes cache timing/flags immediately and writes a failure record before re-raising; this reporting-only change was not rerun. The in-memory numerical computations are unchanged.

## Reproduction

Run from the repository with the approved escalation channel. No dependencies are installed. The input path is always explicit. `launch.py` uses the copied monitor, with shared 1800 s soft / 2400 s hard and 3 GiB process-tree RSS limits. Conda's octave environment is used for Python only. FLINT uses one computational thread per batch worker. Data caches remain in memory.

```sh
exp=/Users/whc/Documents/Work/dot-research/test/bie-bound/selfint-v1
conda_bin=/Users/whc/opt/miniconda3/condabin/conda
input="$exp/output/run-001/export/fixed-input.json"

python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-004/reproduce" \
  --conda "$conda_bin" --script reproduce.py --forecast 3
python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-004/decisive" \
  --conda "$conda_bin" --forecast 65 -- --stage panels --first 0 --count 2
python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-004/audit" \
  --conda "$conda_bin" --script audit.py --forecast 3 -- \
  --panels "$exp/output/run-004/decisive/panel-0.json" "$exp/output/run-004/decisive/panel-1.json" \
  --samples /Users/whc/Documents/Work/dot-research/test/bie-bound/matrel-v1/output/run-001/floating-direct/floating-samples.csv
python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-004/serial" \
  --conda "$conda_bin" --script batch.py --forecast 180 -- --count 8 --workers 1
```

The final command reproduces the panel-6 acceptance failure. Stop after a failed numerical check. The implemented multi-process option is `batch.py --workers 4`; it was not executed. A fresh experiment should reassess that step after resolving the failed analytic envelope. The current stage has not changed strip, node count, interpolation degree or remainder to bypass the failure. No B, C or D3 method is introduced.

The copied input can be regenerated using matrel-v1's documented `export_fixed.m` command into an explicitly authorized new output location. The original exported defining data are retained here, so this stage can run independently of the old MAT files. Prior JSON and floating samples are comparison inputs only; they do not supply the new certificates.

## Results and checks

Complete ball polynomials, per-source domain margins, moment radii, signed coefficient errors and cost ledgers are in `run-002/decisive/`. `summary.json` retains compact decisive, cache, failure and projection records.

| Quantity | Panel 0 | Panel 1 |
|---|---:|---:|
| SI5 source bound | 2.608605e-19 | 3.591377e-19 |
| Node-ball bound | 4.217654e-36 | 5.263320e-36 |
| Exact-function interpolation remainder | 2.419614e-20 | 7.214023e-20 |
| Conversion bound | 2.002393e-41 | 1.980524e-41 |
| Self uniform bound | 2.342775e-18 | 3.264226e-18 |
| Other target tail | 7.553783e-18 | 9.655355e-18 |
| Signed coefficient-ball bound | 6.657996e-36 | 7.589313e-36 |
| New e_I / old e_I | 2.015115e-15 / 5.921601e-15 | 2.582299e-15 / 1.463142e-14 |
| New panel epsilon upper | 1.606387e-15 | 1.879164e-15 |
| Self time, including domains/grid/conversion | 1.494087 s | 1.469763 s |
| Complete panel, excluding independent controls | 23.276353 s | 23.504616 s |
| Extra controls | 0.497725 s | 0.509834 s |

The squared-polynomial Gauss check has relative discrepancies 5.612e-35 and 2.300e-35; balls overlap. Control-point difference upper bounds are below 6.720e-33 and 7.911e-33, versus allowances 2.343e-18 and 3.265e-18. The same-arc floating comparator is 2.4491864342092313e-15. The new reliable partial upper is 2.472191623491365e-15. Floating samples contain cancellation rounding and are not lower bounds on the exact-input residual.

All decisive acceptance items pass: <3 s self time; <=1e-16 self error; <=4e-18 node error; <=1e-18 conversion error; independent controls and residual norm; unchanged fixed input and signed operators. Cached and uncached panel 0/1 polynomials, V, coefficient radii, error components and final upper bounds are exactly identical in their stored representations (`output/projections.json`).

| Cached target | Production s | With controls s | e_I upper |
|---|---:|---:|---:|
| 0 | 19.3032 | 20.0171 | 2.015115e-15 |
| 1 | 19.9699 | 20.4720 | 2.582299e-15 |
| 2 | 19.5120 | 20.0293 | 2.996441e-15 |
| 3 | 19.8745 | 20.3814 | 3.168426e-15 |
| 4 | 19.6489 | 20.1402 | 3.117788e-15 |
| 5 | 19.7935 | 20.2871 | 2.944654e-15 |

Targets after the first average 19.7598 s production, 20.2620 s with controls. Every target reuses 160 source jets, 160 source moments and 1152 Kress geometry points. Peak monitored RSS is 0.268891 GiB. The six completed panels use 119.260013 s summed process CPU time. This excludes the failed target and initial cache work; full-process CPU time was not flushed. Cache construction was timed in memory but not written before the failure. Its combined cache/startup/IO/failure remainder is 6.849636 s; no standalone cache construction number is claimed.

Panel 6: large-domain chord-square real-part lower >3.2786e-5, M_self <=3.991896922e9, interpolation remainder <=1.527156e-16, e_self <=1.559287e-16. The source error, node balls and conversion pass. The self-error threshold fails. Its raw `self-6.json` and traceback are retained. No parallel wall time or speedup is measured. Mac15,6 has 5 performance and 6 efficiency cores, verified with sysctl; processes were not pinned and actual core placement is unmeasured.

## Forecasts, monitored costs and projections

Forecasts were recorded before launch:

| Launch | Forecast s / GiB | Monitored s / peak GiB | Outcome |
|---|---:|---:|---|
| run-001/reproduce | 3 / 0.3 | 1.1416 / 0.0024 | Both old domain bounds reproduced |
| run-001/decisive | 65 / 0.6 | 1.0968 / 0.0026 | Conda rejected redundant `--n 40`; no arithmetic |
| run-002/decisive | 65 / 0.6 | 49.3504 / 0.1645 | Two complete accepted panels |
| run-002/audit | 3 / 0.3 | 1.0916 / 0.0026 | Independent norm and sign check passed |
| run-003/serial | 180 / 0.7 | 129.6345 / 0.2689 | Six targets completed; target 6 failed SI8 threshold |
| four-process follow-up | 65 / 2.2, conditional | not run | Stopped after the failed numerical check |

Total monitored time 182.314919749 s. Short jobs can end between RSS samples. No MATLAB stage was needed. Failed logs are retained. Stage-3 source-cache timing was not flushed; early cache/failure persistence has been added for future reproductions without changing the numerical path.

`cost.py` uses the five completed warm targets, charges source setup once per curve with the observed combined remainder as a conservative setup allowance, and adds the old switch pipeline 148.463619 s exactly once, plus the old mass and incremental export costs. All values are explicit inputs to the postprocessor; the scientific evaluator reads no documents or old results.

```sh
python3 "$exp/cost.py" --serial "$exp/output/run-003/serial" \
  --decisive "$exp/output/run-002/decisive" \
  --old-cost /Users/whc/Documents/Work/dot-research/test/bie-bound/matrel-v1/output/run-001/cost.json \
  --output "$exp/output/projections.json"
```

At current central counts, center 192x160 projects to 64.95 min; both lead materials at design counts total 20.29 min, six walls 6.78 min, shared stages 3.05 min. Total **95.08 min serial**, compared with FEM's **67 min on 11 threads**. Historical 15360-generation counts give 40.27 min, but the 64-target central domain has no certificate. These are conditional cost projections, assuming remaining domains/orders pass at the measured prices. Current fixed settings fail target 6. Remaining lead-state algebra, wall subdivision, group tails, trace constants and gap certification are unmeasured. No parallel projection is justified by the stopped run.

TODO: resolve the panel-6 large-domain interpolation envelope in a separate authorized step; then measure the same accepted panel batch in parallel and record standalone cache construction plus full CPU time. No full-curve residual is extrapolated.
