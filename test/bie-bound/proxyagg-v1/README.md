# Proxy source aggregation version 1

`proxyagg` means proxy source aggregation. CM means compressed source moments; MFS means method of fundamental solutions; DCT means discrete cosine transform; RSS means resident set size. Arb is real ball arithmetic and Acb is complex ball arithmetic.

This experiment keeps the old wrapped kernel's central, zero-wrap branch. It aggregates 160 source panels at the physical origin, then interpolates 48 real target nodes. No density solve or new kernel is used.

## Forecast and checks

run-001: copied old panels 0/1 plus a four-source aggregation timing pilot and all domain checks. Forecast 60–100 s, below 0.8 GiB. Old e_I must reproduce 2.015114157818781e-15 / 2.582298610633771e-15 exactly. New settings: R=.41, M=576, source degree72 and radius .055, J=14, L=48, rho=4.5; source series capacity at least73. Full aggregation forecast will follow the pilot.

Commands, completed checks and measured results are below.

Pilot result: run-001 completed in 47.311 s, peak 0.237 GiB. Both old e_I values reproduced exactly. Four-source aggregation took 2.138 s, giving an 85.52 s forecast for 160 sources. Domain certificates pass with B<1.575472e11 and separation margin>0.0130861.

run-002 forecast: 180–300 s including all 160 sources, two self/proxy/local polynomials, six independent 192-bit direct source-CM control values, independent self controls, and one M=544 panel. Expected peak below 0.8 GiB. The lower-M test reuses the common source-generated coefficient prefix; it recomputes real nodes, tails and the residual polynomial, with n=72 unchanged. No source setting is silently changed.

run-002 stopped in Conda argument parsing before Python started: `--n` was ambiguous with Conda's `--name` and `--no-capture-output`. The numerical entry now uses full parameter names. run-003 has the same 180–300 s / 0.8 GiB forecast and unchanged numerical settings.

## Reproduction

Run from `/Users/whc/Documents/Work/dot-research`. The sole scientific input is the explicit binary64 JSON. Its experiment copy is byte-identical to `test/bie-bound/central-rel-v1/input/fixed-input.json`. No numerical entry reads research documents, repository metadata, or prior results. The comparison postprocessor reads only the explicit result directories supplied to it.

Use fresh output directories; the launcher rejects existing ones. The following are the executed commands (run-002 is retained as the operational failure above):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/proxyagg-v1/launch.py --input test/bie-bound/proxyagg-v1/output/input/fixed-input.json --output test/bie-bound/proxyagg-v1/output/run-001 --conda /Users/whc/opt/miniconda3/condabin/conda --forecast 100 --script run_probe.py -- --sources 4
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/proxyagg-v1/launch.py --input test/bie-bound/proxyagg-v1/output/input/fixed-input.json --output test/bie-bound/proxyagg-v1/output/run-003 --conda /Users/whc/opt/miniconda3/condabin/conda --forecast 300 --script run_full.py -- --physical-degree 576 --source-degree 72 --source-panels 160 --real-node-count 48 --basis-order 14 --bits 128
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/proxyagg-v1/summarize.py --baseline test/bie-bound/proxyagg-v1/output/run-001 --full test/bie-bound/proxyagg-v1/output/run-003 --output test/bie-bound/proxyagg-v1/output/run-003/comparison.json
```

Launches use escalated permission, the copied `monitor_arb.py`, Conda environment `octave`, isolated Python and one FLINT thread. Limits are 1800/2400 seconds and 3 GiB process-tree RSS. No MATLAB run is needed. `run_probe.py` is the baseline and timing probe; `run_full.py` runs aggregation, two panels, independent controls and the lower-order check. `domains.py`, `aggregation.py`, and `real_panels.py` contain the new numerical parts. Other numerical helpers were copied from central-rel-v1. `summarize.py` does ordinary scalar bookkeeping; it generates no new reliable bound.

## Results

All error entries below are upper bounds for the exact binary64 input under the executed PA10–PA13, self-domain and interpolation checks. PA denotes proxy-accel equations, RE the residual-evaluation formulas, SI the self-interaction formulas. D1 means source-cache reuse and D2 means separately bounded self/proxy/local polynomials. Times and memory are measured; full-chain times are predictions.

| Quantity | Panel 0 | Panel 1 |
|---|---:|---:|
| Old e_I, reproduced exactly | 2.015114157818781e-15 | 2.582298610633771e-15 |
| New e_proxy | 2.660159808033599e-19 | 2.660159808033599e-19 |
| New e_I | 2.6495208364838675e-18 | 3.558771497506436e-18 |
| New V midpoint | 1.5421950864740522546623570172895477780e-30 | 1.9938136006493928470556461505983262278e-30 |
| V relative midpoint change | +9.35153e-23 | +9.65744e-23 |
| RE12 contribution upper | 1.2423307743574153e-15 | 1.4126684287872844e-15 |
| Self seconds | 1.47162 | 1.46589 |
| Regular-node seconds | 0.33605 | 0.34200 |
| Basis-conversion seconds | 0.00537 | 0.00551 |
| Local seconds | 0.13250 | 0.13112 |
| Envelopes / combination seconds | 0.000018 / 0.00231 | 0.000013 / 0.00228 |
| Non-self online seconds | 0.47626 | 0.48091 |
| Production seconds | 1.94791 | 1.94683 |
| Extra independent controls seconds | 46.36446 | 46.42647 |

Aggregation is 70.88467 s: moment basis 0.39722, moments 0.50066, source geometry 19.54303, source contraction 0.12227, harmonics 47.13119, harmonic contraction 3.03094, normalization 0.00267, other aggregation accounting 0.15670. Domains/input objects add 0.17830 s, self cache 0.01027 s. The enclosing output/orchestration remainder is 0.03526 s, conservatively charged to setup in forecasts: **71.10851 s** total. The in-memory field is reused at both panels and the lower-order check.

The run-003 timer reconciles as setup components 71.07325 + panel processing 48.31703 + 48.37594 + lower-order processing 1.91323 + output/orchestration remainder 0.03526 = **169.71470 s**. Startup/monitor/final-output overhead is **0.93251 s**, giving **170.64721 s** monitored. Python CPU is **167.38331 s**. Controls evaluate the same input independently and do not alter the production polynomial. The online price excludes those one-time refactor checks; PA21 retains the original independent-control budget.

| Run | Purpose | Monitored seconds | Peak RSS GiB | Status |
|---|---|---:|---:|---|
| 001 | Exact old-error reproduction, four-source pilot | 47.31111 | 0.23683 | Pass |
| 002 | Full launch, Conda short-option parsing | 1.19843 | 0.00021 | Operational failure, retained |
| 003 | Full aggregation, panels 0/1, M=544 comparison | 170.64721 | 0.17537 | Pass |

### Checks and saved evidence

- `domains.json`: positive speed-square bounds, all source/proxy separations, zero-wrap and internal branch, real radius <0.360003535636, complex target radius <0.371972218, trace norm <2.428357748, B<1.575471486731e11.
- `setup.json`: every source-moment error and global coefficient radius; `coefficients.json`: global coefficient balls. Weighted pure-coefficient radius <6.698011e-35. Source matrices are released after contraction.
- `new-panel-*-M576.json`: all error components, exact midpoint polynomials, ball V, RE12, gates, controls and timers. Physical/source tails are 7.230685e-21 / 9.028877e-21; actual basis tail <4.423e-42. Node, conversion and local-combination gates pass.
- Independent 192-bit direct source-CM controls at normalized coordinates -0.7, 0, 0.7 agree with the new proxy field: maximum difference <1.111e-37 against radius sum >2.528e-20. The controls use source contractions but no global physical expansion. Self controls use 3072 source nodes. Independent polynomial Gauss integration gives relative V difference <1.497e-38.
- `new-panel-0-M544.json`: common coefficient prefix, fresh node/interpolation/norm calculation. The physical tail grows by 64.16037618, exactly the PA5 predicted ratio within 1e-20 relative; source tail is unchanged. e_I=7.100811488181221e-18 passes the same acceptance gate.
- `summary.json`, `comparison.json`: compact raw scalar results, disjoint enclosing times and explicit historical forecast assumptions. `monitor.json`, `resource.csv`, `command.json` and logs retain process-tree resource evidence.

### Cost interpretation

The PA21 prediction replaces only central non-self work:
`95.07649*60 - 3510.823 + 71.10850958 + 192*0.47858402`, giving **39.27938 minutes serial**. Source setup amortized over 192 targets gives **0.84894 s/target** non-self (71.10850958/192 + 0.47858402). Keeping 183.19823729 s shared work and the new setup serial, then applying the historical eight-worker efficiency 0.7751952721 to the remainder gives **9.88879 minutes parallel wall**. Shared work includes the 148.463619 s switch pipeline once. Coefficient distribution is not measured; this stage has no new parallel run.

Both predictions are below the FEM 67-minute, 11-thread wall reference. They retain the PA21 historical lead/wall counts and prices; they are not a full BIE pipeline measurement. Full new-center validation, other-group domains/prices, lead-state algebra, wall subdivisions/tails, C_g and band-gap certification remain outside this probe. The two-panel accuracy and speed gates support continuing the global scheme, with no ten-region fallback needed.
