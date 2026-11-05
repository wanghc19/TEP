# Cell kernel reliable evaluation version 1

cellrel means cell kernel reliable evaluation. BIE means boundary integral equation; CM compressed source moments; RSS resident set size; CPU central processing unit; JSON JavaScript Object Notation. Arb/Acb are real/complex ball arithmetic.

Purpose: reliable whole central B curve and finite actual-state lead-column pilot, with the same saved field coefficients. Copied cellfit-v1 helpers retain their mathematics. Inputs are explicit and byte-identical copies under output/input. No fit or eigenvalue solve is run.

Plan: compute central source moments/near-image/fixed-proxy expansions and self source grid once in the parent, then share by a forked dynamic queue. Workers have one FLINT thread. Source caches are read-only; each target has its own arithmetic context and polynomial. The queue uses the existing L/domain/split rule. Run-001 two-panel reproduction forecast 40–60 s, below .6 GiB. Run-002 provisional eight-worker 16-panel pilot: 50–90 s, below 2.5 GiB. Full curve will be forecast after the pilot.

run-001 stopped at the panel-1 exact scalar reproduction. The queue constructed its parameter ball at 128 bits; the copied serial path constructed panel 1 after a 192-bit conversion. The self-domain envelope changed e_I by 4.4515e-28 (the requested displayed upper was unchanged). The input and smooth terms agreed. The parameter precision is now explicit and preserves that serial path; no bound formula or acceptance threshold changed. run-002 repeats the two-panel check with the same 60 s / .6 GiB forecast.

run-002 reproduced both unrounded e_I values exactly (33.171 s, .157 GiB). run-003 is the eight-worker, 16-panel queue pilot, forecast 50–90 s and below 2.5 GiB. Public expansion setup is performed once before fork; no serialized floating approximation replaces coefficient balls. The monitor sums all process RSS, including shared-page accounting.

run-003 passed 16/16 targets: 34.259 s monitored, .273 GiB peak tree RSS, 4.276 s queue after one shared setup. run-004 full-curve forecast: 100–140 s, below 1.0 GiB, W=8; no pilot panel substitutes for a full-run panel. Remaining central-result budget comfortably exceeds the forecast. All 192 independent polynomial Gauss checks are retained.

run-004 completed 192/192 in 82.015 s monitored (.249 GiB). run-005 audit forecast 5 s / .2 GiB: independently re-add every displayed upper as a decimal ball, verify exact leaf coverage and two polynomial Gauss integrals. This explicitly pays scalar serialization; it does not re-evaluate any expensive field.

run-006 lead forecast: 450–700 s, below 1.5 GiB. It computes whole-right-lead envelope tails without a residual map, chooses the least depth at the stated scan-weight budget, reproduces the full map, then builds actual N and N+10 columns. It also compares one-column junction and N+1-column interior-wall models with the full map. Source and regular-model caches remain in memory, and the monitor covers the complete process.

run-006 passed the full 194-column material reproduction, N=59 and N+10=69 actual-state comparisons, and the one-column junction comparison. It stopped at the optional interior-wall setup: the cached harmonic-table key encoded a different current-precision string for the same geometric ball. The compatibility check correctly rejected reuse. run-007 recomputes that small point table instead (about .1 s), without weakening the check or changing any formula. Forecast 450–700 s / 1.5 GiB remains; all run-006 evidence is retained.

run-007 completed all comparisons in 267.994 s, .513 GiB peak RSS. The full material upper exactly reproduced the prior unrounded value. The N=59/69 column models and one-column junction agreed with their full-map references; an interior wall with 60 actual columns also passed. run-008 forecast 5 s / .2 GiB: independent scalar Arb audit of the N+10 residual-norm intervals, contraction-rate comparison, and all contribution ratios.

## Accepted results

All upper bounds below use the exact-input B field and the CK/SI analytic-domain assumptions checked by the copied routines. They cover residual groups or segments; reliable trace constants and a band-gap certificate are outside this experiment. Printed upper bounds in this README are rounded upward. CSV means comma-separated values; `cf` in code means polynomial coefficients, `Ct/Cz` the double/single-layer Fourier coefficient matrices, and `G/P` the port-state map/lead propagation matrix. `audit` entry points perform independent scalar and polynomial checks.

| Quantity | Result |
|---|---:|
| Central panels covered | 192/192 |
| Central RE16 upper | 1.261590321446559e-12 |
| Ratio to floating B value 1.2610675455e-12 | <= 1.0004145504 |
| Panel 0 / 1 e_I, exact baseline scalar reproduction | 2.4032764279321695e-18 / 3.312527089399887e-18 |
| Largest central e_I | 2.127453808502669e-17 |
| Full 194-column material segment upper | 7.888339401529e-15 |
| Actual-state N=59 material segment upper | 7.888336094596e-15 |
| Actual-state N=69 material segment upper | 7.888336091199e-15 |
| N=59 / N=69 material tail squared | 5.36031e-38 / 2.59633e-46 |
| Junction full / one-column finite upper | 4.044824800010e-14 / 4.044824800008e-14 |
| Interior wall full / 60-column upper, including tail | 7.393821691633e-15 / 7.393821691540e-15 |

The central queue raised self-interpolation L to 41 on panels 10,27,92,93,94,97,98,99,164,181; to 42 on 6,95,96,185; to 43 on 89,102. It needed no smaller radius, split, high-self-error flag or omitted panel. The median e_I is about 4.011e-18. `output/curve-panels.csv` lists each panel's data. Panel epsilon upper min/median/max are 2.84898945467e-15 / 2.48394127535e-14 / 4.18898811110e-13. Each worker processed 24 panels, taking 49.33–49.64 CPU seconds. No affinity was set; performance and efficiency cores cannot be identified from these records.

## Actual-state method and tail

`lead_pilot.py` first reproduces the full map, then forms `Ct*W`, `Cz*W`, and `B_positive*V`, with columns V_j=P^j c and W_j=G V_j. These are ball matrices, retained through source moments, self-interaction, local terms and regular expansions. `column_models.py` carries a separate analytic and arithmetic error for each column. CK18 uses the joint Euclidean error for the sum of finite squared norms. No finite model is recovered from the full residual map. Parsing/caching the local Fourier matrices is shared by both paths: the full-map local price is .537 s here, versus 4.13 s in the earlier code; this improvement is separate from reducing columns.

`tail_bound.py` builds global right-lead bounds from Fourier row norms, CK20 point-source rows, ordinary layer envelopes, and self Kress envelopes on all 64 material parameter domains. It does not form a full residual map. Let r=||P||_F and b_N=||P^N c||/sqrt(1-r^2). The tail norm for a whole group is bounded by B_g*b_N. The material operator bound is sqrt(2*pi) times a uniform parameter-space bound; a material segment of length 2*pi/64 therefore receives B_mat^2*b_N^2/64 in its squared tail. A wall segment has length 1/16 and receives B_wall^2*b_N^2/16. The two-face wall envelope uses (1+r); the seam uses both traces.

The certified contraction uses p=1, r<=.386733374894634. The global bounds are B_mat<=5.784415e6, B_wall<=2.512755e6, B_seam<=3.623992e6. The scan constants 1.2336397935832015 and 1.0355521263049683 are floating inputs used only to select the tail depth. Their weighted sum of whole-group tail norms is 1.12513504313e-17 at N=58 and 4.31979470949e-18 at N=59. Thus 59 is the smallest depth for these envelopes and this scan-weight criterion. This is a right-lead result; the left lead is not certified by substituting this depth.

Increasing N to 69 reduces the tail norm by 6.9596046453e-5, compared with r^10=7.4837027793e-5. Independent scalar Arb reconstruction gives overlapping segment-norm intervals; their intersection has width at least 3.28750081197e-22. The finite squared-norm difference for N=59 versus the full map acting on the same states is <=1.344e-53, within the 1.1483e-34 allowance. Junction and interior-wall differences are <=8.900e-52 and <=2.503e-53, within 5.4136e-36 and 1.0245e-38. All three contribution ratios differ from one by less than 1%.

The interior pilot uses exactly N+1=60 state columns for N consecutive walls. It restricts the already required 69-column source data, while retaining a conservative source envelope. Its region formation is timed at 60 columns. Optional rank compression was not needed.

## Timing

Times are measurements in seconds. Nested subtimers describe their parent, and must not be added a second time. The material totals include source/expansion preparation, self/local/nodes/algebra and norm evaluation; the later full-map comparison is validation outside these totals.

| Material component | Full 194 | State 59 | State 69 |
|---|---:|---:|---:|
| Source preparation, total | 37.704 | 17.354 | 20.293 |
| — source geometry | 10.712 | 10.630 | 10.620 |
| — source matrix contraction | 12.841 | 2.125 | 4.405 |
| Near-image setup | 13.857 | 2.432 | 4.996 |
| Fixed-point expansion setup | .486 | .787 | .480 |
| Self, total | 4.893 | 2.886 | 3.014 |
| — self column algebra | 2.060 | .601 | .698 |
| Local terms | .537 | .346 | .401 |
| Regular nodes | 2.955 | 1.177 | 1.362 |
| Polynomial algebra | .535 | .254 | .300 |
| Norm | .350 | .118 | .132 |
| Total material model | 61.407 | 25.812 | 31.492 |

The N=59 material total improves by 2.38x; self column algebra by 3.43x. Actual timing need not scale linearly with the number of columns (in particular the 59/69 near contraction prices differ). The common source geometry and scalar self kernels remain fixed work.

| Boundary component | Full map | Actual columns |
|---|---:|---:|
| Junction region setup | 23.007 | .615 (one column) |
| Junction nodes | 4.268 | .300 |
| Interior two-region setup | 45.844 | 14.635 (60 columns) |
| Interior nodes | 8.718 | 4.180 |

The junction has a common central source/region setup of 28.608 s. Its standalone one-column source setup costs 11.094 s; a production pipeline can use the first column of its lead-state source cache. The global tail envelope costs 4.687 s.

The central run computes one shared setup (28.548 s), then forks read-only coefficient/cache pages. The 192-panel queue takes 52.359 s; enclosing internal time is 80.909 s, with .003 s scheduling/output remainder. The external 82.015 s includes 1.106 s startup/monitor/output overhead. Adding the independent 1.185 s audit gives 83.200 s wall, 424.692 s summed Python CPU, and .249 GiB peak process-tree RSS. All workers use one FLINT thread. Shared-page RSS is summed by the monitor; no large cache is written to disk.

| Run | Purpose | Monitored wall s | Peak tree GiB | Outcome |
|---|---|---:|---:|---|
| 001 | Two-panel reproduction | 33.089 | .1944 | Parameter precision mismatch, retained |
| 002 | Two-panel reproduction | 33.171 | .1563 | Pass |
| 003 | 8-worker, 16-panel pilot | 34.259 | .2724 | Pass |
| 004 | Whole central curve | 82.015 | .2485 | Pass |
| 005 | Independent central audit | 1.185 | sampled .00051 | Pass; too short for a useful peak sample |
| 006 | Lead pilot | 192.559 | .4466 | Optional cache-key rejection, retained |
| 007 | Lead pilot including interior wall | 267.994 | .5125 | Pass |
| 008 | Independent lead audit | 1.184 | sampled .00033 | Pass; too short for a useful peak sample |

Total monitored time including the two stopped runs: 645.456 s. Peak .513 GiB. Run-007 internal wall/CPU are 266.662/265.032 s; startup/output/monitor accounts for 1.332 s externally. Individual model, tail and common-setup timers are in its summary; validation/dispatch/output is the enclosing remainder.

## Cost projection and scope

`cost_projection.py` uses actual single-worker central panels from run-002 and the run-004 queue: parallel efficiency .7807604, equivalent to 6.24608 single workers. Counts: 192 central material, 128 lead material, 48 central boundary faces, 96 lead boundary faces. The right N=59 costs are used for both leads, with lead shared setup scaled by 60/59 for interior walls. Center boundary prices, B-fit 3.010 s, mass allowance 34.7 s and controls 14.995 s are historical cellfit inputs, explicitly separate from new measurements.

| Policy | Predicted wall minutes |
|---|---:|
| Serial | 34.2773 |
| Eight workers, region setup serial | 17.9847 |
| Eight workers, region setup distributed | 7.1607 |

The last two policies distribute target work at measured central efficiency; only the second also distributes boundary-region setup. Source/shared setup and the historical allowances remain explicit. Lead region work alone is about 702.501 serial seconds. These are residual-evaluation projections against FEM's 67-minute reference wall time, not measurements of the full five-group pipeline. Left-lead depth, all target domains, full lead parallel memory, reliable C_g and band-gap certification remain unmeasured; candidate search is outside the boundary. No end-to-end speed ratio is asserted.

## Reproduction

From the repository working directory, use explicit inputs and a fresh run number. The launcher copies no inputs, imports only this experiment's monitor, launches isolated Conda Python, and records process-tree RSS and the 30/40-minute, 3-GiB limits. The following reproduce the accepted runs; use new run numbers rather than overwrite them.

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellrel-v1/launch_arb.py --output test/bie-bound/cellrel-v1/output/run-004 --conda /Users/whc/opt/miniconda3/condabin/conda --script curve_queue.py --forecast 140 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/cellrel-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/cellrel-v1/output/input/coefficients.json --count 192 --workers 8
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellrel-v1/launch_arb.py --output test/bie-bound/cellrel-v1/output/run-005 --conda /Users/whc/opt/miniconda3/condabin/conda --script audit_curve.py --forecast 5 -- --run /Users/whc/Documents/Work/dot-research/test/bie-bound/cellrel-v1/output/run-004
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellrel-v1/launch_arb.py --output test/bie-bound/cellrel-v1/output/run-007 --conda /Users/whc/opt/miniconda3/condabin/conda --script lead_pilot.py --forecast 700 -- --input /Users/whc/Documents/Work/dot-research/test/bie-bound/cellrel-v1/output/input/fixed-input.json --coefficients /Users/whc/Documents/Work/dot-research/test/bie-bound/cellrel-v1/output/input/coefficients.json
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/cellrel-v1/launch_arb.py --output test/bie-bound/cellrel-v1/output/run-008 --conda /Users/whc/opt/miniconda3/condabin/conda --script audit_lead.py --forecast 5 -- --run /Users/whc/Documents/Work/dot-research/test/bie-bound/cellrel-v1/output/run-007
python3 test/bie-bound/cellrel-v1/cost_projection.py --baseline test/bie-bound/cellrel-v1/output/run-002 --curve test/bie-bound/cellrel-v1/output/run-004 --lead test/bie-bound/cellrel-v1/output/run-007 --prior test/bie-bound/cellfit-v1/output/run-004 --output test/bie-bound/cellrel-v1/output/cost-projection.json
```

For the reproduction pilot use `curve_queue.py --count 2 --workers 1`; for the parallel pilot use `--count 16 --workers 8`. Forecasts are recorded above. The numerical entry points do not read research documents, old experimental outputs or repository metadata. The cost-only postprocessor explicitly reads the selected prior timing record.

Raw deliverables: `output/input/copy-check.json`, run-004 per-worker/per-panel records and summary, run-005 audited scalar sum, run-007 source/region/column/tail ledgers and summary, run-008 scalar checks, `output/curve-panels.csv`, `output/results.json`, `output/cost-projection.json`. Input copies are identical to the two user-specified files. All retained output is small; no field or matrix cache is saved.
