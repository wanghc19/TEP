# Reliable switch-line bound, version 1

BIE means boundary integral equation; MFS means method of fundamental solutions; FMM means fast multipole method; RSS means resident set size. `rel` means reliable. Arb/Acb are real/complex ball arithmetic. Q5 is the historical single-disk mass check. IEEE binary64 is the double-precision input format; JSON is the compact exchange format.

The completed self-contained run is **output/run-010/**. It gives
`Q_switch <= 4.8485230e-11`, at most 1.136045 times the floating switch estimate.
The mixed budget margins exceed 1.210063 and 13.309029. The grouped residual outside the switch term remains floating point.

## Method and inputs

`export_fixed.m` builds the same fixed field as budget-v1 and switch-v1, once per run, with 11 MATLAB threads. It copies their field-building helpers, uses the shared packages read-only, and exports exact `num2hex` arrays. The center density is a fixed trigonometric polynomial. Lead density Fourier maps have 194 incident-coordinate columns; the exported G map sends the 97-dimensional lead state to those coordinates. The state in cell j is the exact-input ball product P^j c. Each Nyquist coefficient is split equally between its positive and negative frequencies, matching interpft.

`fixed-input.json` contains shapes and column-major real/imaginary IEEE hexadecimal arrays for k, beta, d, H, both phases, proxy positions/coefficients, density Fourier coefficients, G, P and c. `curve_parameters` is ordered as radius 0.2, modulation 0.3, x elongation 1.5, y elongation 1, star scale, left/right trilobe modulation, and lead area radius. These parameters define the analytic curves; radius normalization and Fourier combinations are evaluated in Arb. Smooth incident waves and free-space interior layers have zero switch term and do not need an export for this calculation.

`reliable_switch.py` uses python-flint 0.9.0, 128 bits, one arithmetic thread. IEEE decoding is exact; all subsequent bounds use Arb/Acb. Integer panel-selection guesses are checked and widened by ball comparisons. Output decimal upper bounds are increased until the decimal itself is strictly above the ball upper endpoint. Exact zeros remain zero.

- 64 Y panels cover [-7/8,7/8]; each uses 40 Chebyshev root nodes and Bernstein parameter 4. Ellipse envelopes sum separate term magnitudes. Every complex distance square has positive real part; all proxies are separated from the closed box.
- Both cut orientations are enclosed. A phase-difference radius also covers exact exp(i beta d), in addition to the stored binary64 phase.
- The full-cell crude bound uses global jump suprema. The refined line bound integrates the moment matrix conj(g_i)g_j on 4096 uniform Y subpanels, using interval enclosures rather than a floating quadrature rule.
- Every curve has 2048 source-angle panels. Density midpoint values use direct Fourier ball dot products plus a derivative-sum remainder. Curve positions/derivatives use Fourier Taylor bounds. Curve regularity, orientation, height clearance and Y coverage are checked throughout each panel.
- Both leads use 40 cells plus SW26/SW27 tails. Frobenius contraction succeeds at p=1. Line squares are summed across cells before square root; endpoint magnitudes are summed across cells directly.
- Constants use SW10 with delta=0.2 and eta=1.165764, and EP4/EP11 with alpha=10 and 1000 Fourier modes on either side. The source bounds cover the switch term under Theorem SW's stated operator/field hypotheses. Full residual certification is outside this experiment.

The complete elementary interpolation/source-bound derivation is in [interpolation-proof.md](interpolation-proof.md). The code does not read that file or old outputs.

## Entry points and reproduction

Run from the worktree with the monitoring launcher through the authorized escalated-permission channel. Use a fresh output directory, e.g. run-011:

```sh
python3 test/bie-bound/switch-rel-v1/launch_all.py \
  --output /Users/whc/Documents/Work/dot-research/test/bie-bound/switch-rel-v1/output/run-011 \
  --package-root /Users/whc/Documents/Work/dot-research \
  --fmm-root /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab \
  --matlab /Applications/MATLAB_R2023b.app/bin/matlab \
  --conda /Users/whc/opt/miniconda3/condabin/conda
```

This first calls MATLAB `export_fixed(out,pilot_config())`, then
`conda run -n octave python -I reliable_switch.py --stage all --input <same-run>/matlab/fixed-input.json --output <same-run>/arb --sources 2048 --micro 4096`.
The exact commands are retained in each stage's `command.json`. `monitor.py` is copied unchanged; `monitor_arb.py` uses its same resource checks with an explicit Python command. The launcher subtracts MATLAB time from the remaining Python limit. Environment: OMP_NUM_THREADS=11, OMP_DYNAMIC=FALSE, MKL/VECLIB/OPENBLAS thread limits 11.

For a reporting-only summary:

```sh
python3 test/bie-bound/switch-rel-v1/summarize.py \
  --experiment test/bie-bound/switch-rel-v1 \
  --final test/bie-bound/switch-rel-v1/output/run-010
```

`arb_pilot.py`, `launch_export.py`, and the `pilot`, `kernel`, `integrate` modes reproduce the explicit development stages. Only the final `all` command is the complete same-run recipe. No source moments, MAT fields, or large caches are saved.

## Final results and checks

All figures below come from run-010. Printed upper bounds are rounded upward. Floating comparators are switch-v1 run-002 plus switch-line-proof section 12.

| Quantity | Floating value | Reliable upper bound |
|---|---:|---:|
| Line contribution | 2.2271410616e-11 | 2.6181330e-11 |
| Endpoint contribution | 2.0407595417e-11 | 2.2303900e-11 |
| Total switch term | 4.2679006033e-11 | 4.8485230e-11 |
| Crude full-cell switch bound | — | 5.5226580e-10 |
| Mixed total, adding floating Q_grp=4.008815436e-12 | — | 5.2494046e-11 |

| Piece | Line upper | Endpoint upper | p | Frobenius contraction upper |
|---|---:|---:|---:|---:|
| Center | 1.5943889e-11 | 1.2377354e-11 | — | — |
| Left lead | 4.9487175e-12 | 4.5798330e-12 | 1 | 0.381407974 |
| Right lead | 5.2887241e-12 | 5.3467131e-12 | 1 | 0.386733375 |

Q5=0.12339611507515838, relative difference from the baseline 0. All six off-grid direct-Arb kernel comparisons are contained in the interpolation balls. The minimum proxy separation exceeds 0.1999999999999999. Source-panel checks give positive speeds and orientation; minimum quarter-height clearance is above 0.00080999. The largest required |Y| is below 0.860005<0.875<H. All assertion checks pass. Both reliable lead tails together contribute less than 1e-26 to Q.

The binary64 phase has |q|^2-1 approximately 7.97046131e-17; the stored-phase/exact-phase difference is enclosed rather than set to zero. The switch constant is at most 1.035552126305; the improved point factor is at most 0.401253395449.

## Cost and forecasts

Final whole-pipeline wall time: **148.463619 s**, process-tree peak **1.350815 GiB**. Python/Arb peak is 0.230607 GiB. Unit cost at Y=1/8: two branches, including all proxies, potential and gradient, 0.0481975 s; mean per branch 0.02409875 s. A two-branch evaluation makes 1284 Hankel evaluations. No FMM is used in the certificate.

| Disjoint component | Seconds | Hankel evaluations |
|---|---:|---:|
| Fixed-field generation | 3.501432 | 0 |
| Q5 check and export | 0.761662 | 0 |
| Kernel interpolation/envelopes | 121.245175 | 3,370,500 |
| Source preparation, contractions, integration, checks | 7.112393 | 7,704 |
| Startup, IO and monitor remainder | 15.842956 | 0 |
| Total | 148.463619 | 3,378,204 |

Within the 7.112393 s stage, preparation/contraction takes 0.771687 s and source integration 5.437204 s; the remaining 0.903502 s covers constants, kernel micro-panel construction, direct-kernel checks and reporting. These nested values are not added again to the whole-pipeline total.

Forecasts were recorded before launches. All stages share the result budget; the total monitored time including failed/development runs is **322.766897 s**, highest sampled RSS 1.410935 GiB. The final recipe alone takes the time above.

| Run | Purpose/settings | Forecast seconds / GiB | Measured seconds / GiB | Result |
|---|---|---:|---:|---|
| 001 | 128-bit Hankel timing | <10 / 0.2 | 1.161 / very short sample | 47.8 microseconds per Hankel in the arithmetic loop |
| 002 | Field export | <30 / 1.3 | 18.541 / 1.371 | Missing copied LOCAL_piece_field helper; preserved failure |
| 003 | Field export with helper | <30 / 1.4 | 13.080 / 1.411 | Q5 exact reproduction; export retained |
| 004 | One kernel panel | 15 / 0.3 | 1.099 / startup sample | Proxy row-vector indexing error; preserved failure |
| 005 | One panel after orientation fix | 15 / 0.3 | 3.294 / 0.133 | Finite ellipse envelopes |
| 006 | 64 kernel panels | 150 / 0.2 | 120.820 / 0.137 | Completed kernel table |
| 007 | 512 source / 1024 Y panels | 180 / 0.8 | 5.436 / 0.214 | Horner ball wrapping made the center bound useless |
| 008 | Direct Fourier dot product, 512/1024 | 30 / 0.8 | 3.270 / 0.209 | Exploratory bound 6.52095e-11 |
| 009 | 2048/4096 and off-grid checks | 15 / 0.8 | 7.604 / 0.226 | 4.8485230e-11; explicit upper-endpoint maximum reduction |
| 010 | Complete same-run recipe | 150 / 1.5 | 148.464 / 1.351 | Accepted final result |

The degree-512 Horner failure was interval overestimation, not a large physical residual. Direct Fourier dot products avoid that radius amplification. Old failure records and preliminary outputs are retained; the final numerical path is the reproducible path above. The final bound and the source/cell tail formulas need no empirical convergence assumption.

## Deliverables

- `matlab/fixed-input.json`: exact input arrays and dimensions; `export-summary.json`: reproduction and generation time.
- `arb/kernel.json`: per-panel coefficient balls, analytic remainders, envelopes, counts and time.
- `arb/kernel-checks.json`: direct off-grid values and containing interpolation balls.
- `arb/bounds.json`: constants, geometry checks, contraction/tail values, per-piece bounds and mixed margins.
- Each stage's `command.json`, `resource.csv`, `run.log`, `monitor.json`; parent `pipeline.json`; experiment `summary.json`.

The remaining obstacle to a full reliable (B0) is certification of the other residual groups and mass inputs. The switch contribution itself fits both stated mixed allowances with the margins above.
