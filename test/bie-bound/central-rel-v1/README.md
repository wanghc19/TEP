# Central material reliable bound version 1

`central-rel` means central material reliable bound. BIE means boundary integral equation; FEM finite element method; CM compressed source moments; DCT discrete cosine transform; CPU central processing unit; RSS resident set size; JSON JavaScript Object Notation; CSV comma-separated values; PID process identifier. Arb/Acb are real/complex ball arithmetic.

The explicit input is byte-identical to selfint-v1. Only the authorized per-panel interpolation degree/domain fallback and dynamic multiprocessing are added. Large source/field caches stay in memory. Source data and prior experiments remain unchanged.

## Forecast before launch

run-001: two-panel reproduction, 55 s / 0.6 GiB. Same cached source coefficients and moments as selfint-v1. Compare deterministic polynomial, error ledger and epsilon exactly with prior panel 0/1 records after the run. Those old records are comparators only.

Parallel pilot: eight workers, sixteen one-panel tasks, forecast 120 s / 2.5 GiB from 20 s per target and 0.27 GiB per process. Choose the full-run worker count after measuring the pilot. Full run provisional forecast 800–1200 s, conditional on pilot and <3 GiB RSS.

## Results

The whole central material curve has reliable epsilon <= **1.265348e-12**, ratio **1.003318** to the floating reference 1.2611637248633255e-12. All 192 targets passed, with no radius fallback, splitting or omitted contribution. Sixteen targets increased L; none exceeded the 1e-16 working self-error goal. The curve computation plus final audit/aggregation took **614.116509417 s**, **4526.849318 s Python CPU**, and **1.710586548 GiB peak process-tree RSS**.

The full pipeline's specified group counts project to **17.57814 min wall** using the observed scheduling efficiency, versus FEM's 67 min on 11 threads. This is a projection for the remaining groups, not a completed full-pipeline benchmark. Lead-state algebra, C_g, band-gap certification, wall refinement/tails and other-template domain/order suitability remain unmeasured.


Run-001 reproduced the fixed polynomial, V, every error component and final upper exactly. An extra bitwise comparison of every internal ball radius failed (max absolute difference 5.207e-54); its evidence is retained. This diagnostic does not change any summed error or required scalar result. Pilot started with the already recorded 120 s / 2.5 GiB forecast.

Pilot passed all 16 panels: 54.4508 s monitored, 407.7495 s total Python CPU, 1.5823 GiB tree RSS. Every worker handled two tasks; cache build 5.04–5.16 s. L increased to 42 at target 6 and 41 at target 10. Full run-003 keeps W=8 (measured throughput and about 1.4 GiB memory margin), forecast 750 s / 2.4 GiB including all 192 targets and checks. No pilot result is substituted for a full-run panel. Remaining shared soft/hard limits are 1700/2300 s after about 95 s already measured. If any panel has no permitted certificate, retain its failure and withhold a whole-curve bound.

## Scientific implementation

`chebyshev.py` uses A2/A3 and D2 from selfint-accel. It first recomputes the large target-disk certificate at R_t=0.04 and source strip 0.0625. If that analytic domain fails, it tries 0.035 and 0.030. For a fallback disk, the strict ellipse inequality has a supremum rather than a largest real rho: the implementation takes a certified lower endpoint of R_t/h + sqrt((R_t/h)^2-1), multiplied by 1-2^-48, and explicitly checks strict inclusion. The original disk retains rho=4.5. The smallest L>=40 satisfying the reliable interpolation remainder <=2e-17 is chosen before evaluating node sums. The full self polynomial degree L-1 is retained even if it exceeds the other degree 52.

The small target disk of radius h uses source strip 0.08, N=1152 real source nodes, 128-bit sums and 192-bit finite interpolation conversion. A valid self error above the 1e-16 working goal is retained and flagged. The other terms retain their independent R_t=0.04 certificates. A self-domain failure recursively bisects the target up to two levels. A failed other-domain check or an uncovered leaf withholds a whole-curve result.

`panel.py` copies signed source-moment compression and the residual polynomial from selfint-v1. No proxy, density, normal, phase, quadrature or remainder formula changes. `cached.py` builds source geometry/moments once per worker; every one-panel task recomputes target-dependent kernels and domain bounds. Internal source moment radii are retained as the maximum per source panel, together with the resulting reliable moment-error bound, rather than saving every radius vector. The complete residual polynomial and coefficient radii are saved.

`queue_run.py` uses a dynamic process-pool queue with individual target tasks. Every worker has one FLINT thread. Cache timers are written before the first panel. The queue records worker CPU/wall time after every task; after all workers exit, parent plus reaped-child CPU is also recorded. The copied monitor samples the same complete process tree as before and now additionally retains per-PID RSS peaks. It enforces the 3 GiB summed limit. No affinity is set; core type cannot be inferred from a process ID or its speed. Load averages are recorded immediately before and after the queue.

`aggregate.py` checks exact dyadic coverage, all required independent controls and direct radial identities, then independently integrates each polynomial using Gauss nodes at 192 bits. The group bound is the square root of the sum of squared per-leaf bounds, computed in Arb. It pays the sum of all outward error components again, so displaying/scalar serialization cannot narrow the final bound. The floating reference is an explicit comparison argument, not a solver input.

## Reproduce

Run from the repository checkout. All paths are explicit. Use a fresh run number and the escalated-permission channel. No MATLAB or dependency installation is needed. The input can also be regenerated with matrel-v1's documented exporter in an authorized new output directory; its defining numbers must match this supplied input.

```sh
exp=/Users/whc/Documents/Work/dot-research/test/bie-bound/central-rel-v1
conda_bin=/Users/whc/opt/miniconda3/condabin/conda
input="$exp/input/fixed-input.json"
python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-004/reproduce" \
  --conda "$conda_bin" --forecast 55 -- --count 2 --workers 1
python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-005/pilot" \
  --conda "$conda_bin" --forecast 120 --soft 1755 --hard 2355 -- --count 16 --workers 8
python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-006/full" \
  --conda "$conda_bin" --forecast 750 --soft 1700 --hard 2300 -- --count 192 --workers 8
python3 "$exp/launch.py" --input "$input" --output "$exp/output/run-006/aggregate" \
  --conda "$conda_bin" --script aggregate.py --forecast 15 -- \
  --run "$exp/output/run-006/full" --floating 1.2611637248633255e-12
```

Forecasts and remaining shared limits should be updated from the preceding monitors before each reproduction. The full run does not reuse pilot certificates. Failed attempts remain in the explicit task records.

Full queue completed all 192 targets in 613.0068 s, peak 1.7106 GiB. Aggregate audit forecast 15 s / 0.5 GiB: exact coverage and independent Gauss norms plus Arb RE16 summation. Remaining shared soft/hard limits 1090/1690 s after 707.58 s of monitored work.

## Completed measurements and checks

| Stage | Forecast s / GiB | Monitored s | Peak total GiB | Result |
|---|---:|---:|---:|---|
| run-001/reproduce | 55 / 0.6 | 40.119560 | 0.293503 | Principal polynomial/ledger outputs exactly reproduced |
| run-002/pilot | 120 / 2.5 | 54.450803 | 1.582245 | 16/16 valid, W=8 |
| run-003/full | 750 / 2.4 | 613.006835 | 1.710587 | 192/192 valid, W=8 |
| run-003/aggregate | 15 / 0.5 | 1.109675 | 0.002442 | Exact coverage and independent norms passed |

Total monitored time is 708.686872417 s. A short audit can finish between RSS samples; its sampled peak is not a tight peak-memory measurement. Full-run per-worker self-reported lifetime RSS maxima range from 0.215516 to 0.222840 GiB; monitor samples range from 0.208542 to 0.213593 GiB. Total process-tree peak is sampled independently, not obtained by summing separate lifetime maxima.

Every worker completed 24 targets. Cache build times range 4.796280–4.896025 s and are saved before any target work. Deducting cache time, worker rates range 0.0395615–0.0401095 panels/s. Full Python CPU is 4526.490200 s, including the parent timed region and reaped children; aggregation adds 0.359118 s. Load averages before/after full computation were [4.575684,4.561035,3.951660] / [11.764648,12.416992,9.139160]. No core affinity was set; actual performance/efficiency-core assignment is unmeasured.

The baseline ideal prediction 192*19.8/8 is 475.2 s; full measured computation is 613.006835 s. Reference parallel efficiency is 0.7751953, and aggregate Python CPU occupancy of eight slots is 0.9230097. These are different quantities: the former uses historical single-process target time, while the latter includes the actual parallel scheduling conditions.

L=41 targets: 10,27,92,93,94,97,98,99,164,181. L=42: 6,95,96,185. L=43: 89,102. All others retain L=40. No analytic radius fallback, split or high-self-error flag occurred. Maximum e_self upper is 2.122157e-17; maximum e_I upper is 5.918678e-15. Target 95 has the largest residual contribution, upper 4.193867e-13. Full per-target data are in `panels.csv`.

Exact dyadic coverage is [0,192], mapped to [0,2*pi]. All 576 independent real control evaluations pass; their maximum difference upper is 1.615840e-31. All direct radial derivative checks pass. Independent Gauss squared-norm relative discrepancy is at most 1.214506e-34. Every final outward error component is included in the aggregate RE16 sum. Source moments and target coefficients retain the same signed conventions as the reproduced panel 0/1 path. Small/large-domain chord real-part lower bounds stay positive throughout the curve.

The scalar aggregate is 1.2653478002962938e-12; its ratio to the ordinary floating reference is 1.0033176306537215. The reference is not a lower bound on the exact-input residual. These values certify the entire central material residual group, not the uncomputed complete grouped residual.

## Cost postprocessor

```sh
python3 "$exp/cost.py" --run "$exp/output/run-003/full" \
  --aggregate "$exp/output/run-003/aggregate" \
  --old-cost /Users/whc/Documents/Work/dot-research/test/bie-bound/matrel-v1/output/run-001/cost.json \
  --output "$exp/output/run-003/cost.json"
```

The measured summed worker durations (including source setup and checks) are mapped to full monitored wall by factor 0.1258397405. Other groups use central per-pair and per-target prices with matrel-v1 counts: center 192x160, two lead materials each 64x64, six walls 96x32. Each other curve pays its source cache setup; extra aggregate costs scale by target count. This models the observed dynamic queue, rather than dividing an old total blindly by eight.

Center is measured at 614.116509417 s including aggregation. Each lead material projects to 96.420418 s before its scaled aggregation; walls to 63.238234 s. Shared historical stages add the switch pipeline 148.463619 s exactly once, mass 20.990072375 s, and incremental disk selection/export 13.744545917 s. Total projected wall is 17.578140631 min. The old 64-target central design has no domain certificate and is excluded from the main projection. No additional claim is made for the other groups' error bounds or unmeasured certification steps.

`summary.json` and `panels.csv` retain compact results outside ignored run folders. The run directory contains exact commands, all leaf certificates, cache/task/worker timing, per-PID and total memory, the independent aggregate, and the cost arithmetic. No large field or matrix cache is written to disk.
