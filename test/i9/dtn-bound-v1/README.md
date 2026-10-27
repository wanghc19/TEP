# I9.6a — FEM+DtN source-reconstruction spectral-distance estimate (`dtn-bound-v1`)

Implementation and runs of `research/projects/eig-apost/implementation/i9/design-9-6a.md`
(theory: `phase3-analysis/fem-bound/s-dtn-bound.md`). Fixed input: the frozen I9.5b fine-Q12
FEM+DtN candidate $k = 1.558438079544167$, $\mu = k^2$, shift $s = \mu$. There is no root
search, no new native $N$, no BIE and no parameter sweep.

**D2 status (2026-10-27, run-03): `VALID_BOUND_EVALUATION_NOT_RESOLVED`.** D2 of the design
(reliable evaluation success path) is implemented in `dtn_bound_i96.m`. The formal run-03
completed with a complete finite enclosure on both levels. The resulting radius is an
`EXACT_ARITHMETIC_UPPER_BOUND`: every non-rounding error is in the intervals, but floating-point
rounding is not certified. It is far above the target, and the evaluation budgets are not met.
The D1 sections below (run-01/02) are kept as history. The D1 review status was
REVISE / UPPER_BOUND_DELIVERY_INCOMPLETE ([review](../../../research/projects/eig-apost/implementation/i9/review-9-6a.md)).

## Files

| file | role |
|---|---|
| `dtn_bound_i96_config.m` | all frozen inputs: model, native configuration, levels, engine, pilot, norms, plan reserves, budgets, resources (`formal` / `smoke`) |
| `dtn_bound_i96.m` | entry `result = dtn_bound_i96(config, native, output_dir)` with `native = []` (adapter) or an explicit native struct |
| `run_bound.py` | launcher: serial-MATLAB check, process-tree RSS sampling, soft/grace/hard limits, killpg cleanup |
| `summarize_bound.py` | post-run machine summary (`summary.json`, `summary.md`) |
| `output/attempt-1/` | D1: `smoke-01..08`, `run-01` (operational stop), `run-02` (ordinary diagnostic path only). D2: `smoke-09..11`, formal **`run-03`** |

Reproduce (from this directory; run-03 used `conda run -n octave python`, absolute output path):

```
python3 run_bound.py --mode formal --matlab /Applications/MATLAB_R2023b.app/bin/matlab \
  --output $PWD/output/attempt-1/run-XX
```

MATLAB receives only the config mode and the output path. It reads no Markdown, Git or historical outputs.
D2 smoke: `--mode smoke --soft-seconds 600 --grace-seconds 0 --hard-seconds 900`. The launcher copies the
four launched sources to `<output>/source/` before MATLAB starts.

## D2 implementation (design-9-6a D2, theory §11)

The candidate, native configuration and both levels are unchanged: control N=256/M=128, main N=512/M=256, $b=10^{-8}U_0$.
Order: self-test → native adapter (same as D1) → pilot (≤90 s) → control → main → combine → save.
Every stage writes its record (`selftest.json`, `pilot.json`, `progress.json`, `partial-result.json`) before the next one starts.

| design item | implementation (`dtn_bound_i96.m`) |
|---|---|
| geometry ownership (4.1) | Elements are *special* if curved, or if their quadratic control net meets a tube around the true curve; all others are clipped exactly against the grid with background-certified material (`LOCAL_stageA`). Special elements are handled in reference coordinates. Each sub-triangle $T$ gets its vertex-affine map $L_T$ and Bernstein bounds $\eta_d$. Pieces are clipped by grid lines $\pm\eta_d$, and the chord tube is thickened by the $\eta$ projection (`LOCAL_eng_clip`). Only pieces whose whole image is certified in one rectangle and one material are integrated exactly; the rest are kept as records over every possible rectangle and material. Pieces outside the tube take their material from the polyline winding; pieces inside the tube keep {1,4} or {1,17}. |
| curve tubes (4.1.5) | Full closed curves are used, with chord count $S_0 2^{\ell}$ ($S_0=320$) synchronised with the item level $\ell$, $\epsilon=M_2\Delta\theta^2/8$, end caps, and a local sector index. There is no dense point × segment matrix. |
| source moments (4.2) | Per possible rectangle and material, $g=\alpha u-\tilde f$ is formed after subtracting coefficients. Degree-10 integrands use Duffy 6×6, which is exact. Uncertain strips get the Bernstein supremum times area as real/imaginary intervals, and the distance of each interval to 0 enters $e_{Rab}$ (`LOCAL_eng_aggregate`, `LOCAL_moments`). |
| direct defects | $\lvert u-v_R\rvert^2$ uses P type: curved-flag elements at node level 3, degree 18, Duffy 10×10. $\lvert g\rvert^2$ uses F type, the same pieces as the moments. Affine non-special parts use the exact bulk rules of stage A. |
| correction | $\tilde c'=\tilde c+\mathrm{mid}\,D$ on special rectangles, so $D'=D-\Delta$ exactly. $I_f$ is updated by the Gram identity and re-aggregated. Decision: $T_0\le b$ → NOT_NEEDED; $T_1\le b$ → REGULAR; $T_1<T_0$ → FINAL_INTERVAL; otherwise NOT_APPLIED. The Fourier change is written to `*_corr.mat`. |
| norm remainders (5) | D2.8 analytic Yukawa sweeps, Taylor-24 exponential remainders and 12-point Gauss with an enclosure check. Series remainders go into the F/V radii, so $\varepsilon_{alg}=0$. Parseval tails are kept raw; a wholly negative interval → `EVALUATION_INCONSISTENCY`. |
| engine control | Refines items carrying a `refine_fraction` 0.9 share of the score, plus a fallback pass over the coarsest level every 4th round. Working limits: $2\times10^6$ terminal pieces per template and level (predictive check before each round), quadrisection level 30. The deadline is derived from the soft limit minus reserves; the control level gets a 0.25 share. |
| pilot gate (6) | One 32-column strip of the main level, all special elements in it. Pass = complete finite enclosure + measured tightening + predicted mandatory flow ≤ soft limit. The closure prediction (≤2 future rounds) is reported only. The pilot's time counts in the run, but its result is not reused. |
| retention (7) | `native.mat`, `blocks/<level>/<template>_s%04d.mat` (strip F/V coefficients and Fourier factors), `*_corr.mat`, `special_<template>.mat` (pieces, records, groups), a block index in `integration.json`, `modes.csv`, `cells.csv`, `levels.csv`, `pilot.csv`, `source/`, timings, RSS and cleanup records. |

**D1 review items addressed by D2:**
- The reliable success path exists.
- Rectangle and material identity are guaranteed by tubes, so sliver midpoint attribution is no longer used.
- Norm remainders are controlled.
- Coefficients are retained.
- The startup source copy is kept.
- Strips replace the six repeated full projections (mode blocks).
- The launcher now records survivor commands (change made after run-03; the run-03 copy in `source/` is the launched version).

**Interpretations to review:**
1. Duffy tensor rules are used instead of Dunavant.
2. Bernstein bounds are taken on node-level nets.
3. $\eta$-tube thickening uses the normal/tangential projection.
4. $S_0=320$, with the curve level equal to the item level.
5. The P type is fixed at node level 3 and is not adaptive; this sets the width of $\delta_u$.
6. The correction is applied on special rectangles only.
7. Norm enclosures use Taylor + Gauss.
8. Meaning of the pilot gate, and the pilot is not reused.
9. The ordinary column uses the uncorrected prediction $E_R$ and $\delta_u$.

**Self-test (all pass, 2.6 s):**
- Duffy 6/10 exactness $\le3\times10^{-15}$.
- Engine coverage defect $\sim10^{-13}$.
- Affine $I_f$/moments/$I_u$ vs exact clipping $\le3\times10^{-11}$.
- Brute-force reference for a curved element (800² reference subdivision, pointwise exact material/rectangle) lies inside the $I_f$, $I_u$ and moment enclosures.
- Tube material/rectangle violations 0.
- Correction identity $4\times10^{-16}$; Fourier factors $2\times10^{-15}$; D2.8 $1.7\times10^{-14}$; Taylor/Gauss enclosures hold.
- All status branches; Q attribution.

## D2 results (run-03)

Native field identical to run-02: all qualification gates pass, $\lambda=-6.706\times10^{-12}$, 33 cells, $U_0=1$.

**Pilot:** pass in 19.8 s.
- Strip 96 (180 elements), 7 rounds; score $2.42\times10^{-4}\to2.68\times10^{-7}$ (×0.32 per round).
- Predicted mandatory flow 1413 s ≤ 1800 s.
- Closure `PREDICTION_EVIDENCE_INSUFFICIENT` (6 more rounds needed > 2).

| level | $D_0^-$ | $\delta_u$ interval | $E_v$ | $c_RE_R^+$ | moment term | $E_y^+/b_M$ | $\varepsilon_0^+$ | $R_\mu$ | $R_k$ | ordinary $R_k$ |
|---|---|---|---|---|---|---|---|---|---|---|
| control | 1.000000024 | [1.608, 1.682]e-7 | 3.1497e-6 | 9.07e-7 | 6.81e-6 | 3.81e-7 | 8.10e-6 | 1.210e-4 | **3.88e-5** | 1.56e-5 |
| main | 1.000000035 | [0.519, 0.825]e-7 | 3.1450e-6 | 1.63e-7 | 3.85e-5 | 6.82e-8 | 3.88e-5 | 4.451e-4 | **1.428e-4** | 1.17e-5 |

Both levels: `VALID_BOUND_EVALUATION_NOT_RESOLVED` with a complete enclosure and a positive denominator.

**Budgets ($b=10^{-8}$):**

| budget | control | main |
|---|---|---|
| moment term $+\varepsilon_{alg}$ | 6.81e-6 | 3.85e-5 |
| width($\delta_u$) | 7.4e-9 (passes) | 3.06e-8 |
| $c_R$ width($E_R$) | 5e-11 | 2e-10 |
| widths of $E_v$, $D_0$, $E_y/b_M$ | 0 (passes) | 0 (passes) |

**Correction and engine:**
- The correction lowered $T$ by only 2–3 % ($T_0\to T_1$: 7.00e-6→6.81e-6 control, 3.92e-5→3.85e-5 main) → FINAL_INTERVAL.
- All six template-levels stopped at `PIECE_LIMIT` (predictive 2e6 check) after 17–24 s each:
  - control: level ≤7, 1.19–1.35 M terminal pieces;
  - main: level ≤6, 0.76–0.88 M terminal pieces.
- Most of the engine deadline (control 411 s, main 1590 s) was unused.

Contributions to $R_\mu$ (main):

| term | contribution |
|---|---|
| moment term | 4.08e-4 (92 %) |
| $E_v$ | 3.33e-5 |
| $c_RE_R$ | 1.7e-6 |
| $\delta_u$ | 8.8e-7 |
| $E_y/b_M$ | 7.2e-7 |

The optional lower bound $\max\{0,E_v^--\delta_u^+-\varepsilon_0^+\}=0$ on both levels.

**Reading:**
- Main is looser than control: it has about 4× the special rectangles (13954–21840 vs 3752–5880) under the same piece limit, so it reaches one level fewer.
- Both radii are valid exact-arithmetic upper bounds for the same candidate, so $\min=3.88\times10^{-5}$ is also one; this is an observation, not the design's main-level deliverable.
- Even with a zero moment term, $E_v\approx3.1\times10^{-6}$ alone gives $R_k\approx1.1\times10^{-5}$ > $10^{-6}$.

**Checks (both levels):**
- Coverage F/P relative defects ≤ $9.1\times10^{-11}$ against tolerance $10^{-10}$ (small margin: roundoff over about $10^6$ pieces).
- Template area defects ≤ $4.4\times10^{-15}$.
- Non-special material mismatch 0.
- Main level: 242 negative raw $T_v$ column tails (roundoff), kept unclipped; the $T_v^2$ interval is positive.

**Costs (run-03):**
- Wall 302.6 s; MATLAB function 276.4 s.
  - self-test 2.6, adapter 2.6, pilot 19.8;
  - stage A 74.9, engine 121.5, aggregation 18.9, correction 6.2, norms 15.0;
  - level saves 6.8, figures 4.9, save 2.9.
- Peak process-tree RSS 2.713 GB. The 2.7 GB warning was crossed at 158.6 s (main stage A); the hard limit was not reached.
- Soft limit not reached; no grace.
- Disk 3.5 GB (blocks 3.4 GB, `native.mat` 128 MB).
- One PID (50418) of the MATLAB tree was still listed at the first cleanup check. It no longer existed when checked later; its command was not recorded (this is why the launcher change above was made).

## D1 history: method (run-01/02)

1. **Adapter** (`FIXED_FREQUENCY_RECONSTRUCTION`). Copied I9.5b code builds the joint mesh, the three templates and one complete DtN/centre response at the frozen $k$. It takes the branch closest to $0$ and recovers the centre plus 16 lead cells per side. All I9.5b qualification gates are applied to every cell. The field is normalised in the unweighted $L^2$ norm over the 33-cell box, with the phase fixed at the max-modulus node. It records $\|P^j g\|$, cell masses, eq. (27), 33-point curve deviations and the raw QZ blocks (saved to `native.mat`).
2. **First-batch integration feasibility proxy** (per level and template), applied to elements within 0.012 of $c(\theta=0)$:
   - reference bisection to depth 14 with Bernstein control-net boxes;
   - an analytic chord tube of the true curve;
   - width proxies for source/field moments and direct defects, compared with $b = 10^{-8}U_0$.
   A log-linear fit over the last 4 depths extrapolates depth, piece count and time for this proxy. It is not a necessary-cost lower bound or a completed reliable enclosure. Limits are depth 30, $2\times10^6$ terminal pieces and the remaining soft time; the implementation's cumulative piece-count prediction is not the same counting convention.
3. **Ordinary integration**:
   - exact Sutherland–Hodgman clipping of straight triangles (3×3 Gauss on full rectangles, Dunavant-8 on fan pieces);
   - signed chord→arc slivers of curved P2 elements;
   - signed P2-edge→true-curve material slivers.
   Q1 source and Q2 field Legendre moments are taken per rectangle. The direct terms $|f-f_R|^2$ and $|u-v_R|^2$ are evaluated on the same points. Analytic single-rectangle $y$-Fourier factors are summed with the FFT. Parseval column tails give $E_y$ and $T_v$.
4. **Analytic Yukawa sweeps**: per mode $-w''+a_m^2w=f_m$, piecewise affine in $x$. Norms use 12-point Gauss with a closed-form interior Green representation, plus exterior tails $T_d$; no quadrature remainder is supplied. Ordinary assembly uses the form of eq. (18a), without the moment-error term or reliable norm enclosures (see caveats).
   - $R_\mu = C_\rho(\delta_u+E_v+\varepsilon_0)/(D_0-\varepsilon_0)$
   - $R_k = \max(k-\sqrt{\mu-R_\mu},\ \sqrt{\mu+R_\mu}-k)$

**Memory control.** `mode_blocks` (main level: 6) re-runs the deterministic projection once per Fourier-mode block and keeps only that block's arrays. The Parseval tails are computed as column energy minus the summed block energies. smoke-08 vs smoke-07 is identical for every term except $T_v$ ($5\times10^{-8}$ relative, a cancellation quantity).

**Launcher note.** The VS Code MATLAB language-server process tree (`mathworks.language-matlab`, an editor service) is recorded in `preflight.json` and excluded from the serial/concurrency check. Every other MATLAB still refuses or stops the run.

## Run ledger

| run | outcome |
|---|---|
| smoke-01..05 | operational fixes: `repelem` shape, integrand shape, spherical-Bessel switch moved to $\lvert x\rvert<1$, Lebesgue table blocked (it hit the 3 GB hard stop) |
| smoke-06..08 | complete operational probes (s12-n80 mesh, which is `NATIVE_FIELD_MISMATCH` by construction); smoke-08 checks the mode blocks |
| run-01 | formal; control level complete; internal memory gate stopped the main level (RSS 2.18 GB + 0.97 GB predicted > 2.9 GB); `failure.json` |
| **run-02** | **formal, ordinary diagnostic path completed; upper-bound delivery incomplete**: 204 s wall, peak sampled MATLAB process-tree RSS 2.865 GB (2.7 GB warning crossed at 73 s; hard limit not reached), soft limit not reached, no grace |
| smoke-09 | D2 operational: row-oriented `alpha_true` broadcast to a 10⁵×10⁵ array in stage A |
| smoke-10 | D2 operational: struct-array field mismatch (`corr_files`) in the correction |
| smoke-11 | D2 complete operational probe (smoke mesh, `NATIVE_FIELD_MISMATCH` by construction), 44.6 s, 1.71 GB |
| **run-03** | **formal D2, complete: `VALID_BOUND_EVALUATION_NOT_RESOLVED`**, 302.6 s, 2.713 GB |

The implementation handoff reports that only the `% Main algorithm:` header comment of `dtn_bound_i96.m` was edited after run-02 (mode blocks). Its current bytes differ from the startup provenance; the startup source copy was not retained, so the review could not independently establish that the difference was comment-only. The other three source files match the saved provenance.

## D1 history: results (run-02)

**Final status `RESOURCE_OR_INTEGRATION_UNRESOLVED`.** Input identity is `FIXED_FREQUENCY_RECONSTRUCTION`. The ordinary column is `ORDINARY_ESTIMATE` / `INTEGRATION_CONTROL_UNRESOLVED`.

The reliable radius is empty. Even if the gate passed, the current code would return
`NOT_IMPLEMENTED_AFTER_SUPPORTED_GATE`: the success path has not been implemented.
Missing source-moment and norm error control is not merely missing floating-point
roundoff certification. The ordinary values below are neither established continuous
spectral-distance upper bounds nor actual eigenvalue errors.

**Native field.** All qualification gates pass.
- $\lambda=-6.706106864977353\times10^{-12}$, identical to the I9.5b reference; dimensions match.
- Centre residual $1.03\times10^{-12}$; branch gap $4.772$.
- Lead recovery $\le 2.7\times10^{-14}$; load balance $\le 1.1\times10^{-12}$.
- Spectral radii $0.377/0.384$.
- eq. (27) tails $3.5\times10^{-15}$ (left) and $6.2\times10^{-15}$ (right); last-two-cell masses about $2\times10^{-13}$.
- Curve deviation: max $5.1\times10^{-7}$ (centre), $5.6\times10^{-8}$ and $8.9\times10^{-8}$ (leads).

**Gate.** It fails on both levels and all templates. Proxy widths at depth 14 are $10^{4.5}$–$10^{7}\,b$ and tighten by about $e^{-0.25}$ per depth. The proxy extrapolates depth 92–98 and $10^{18}$–$10^{19}$ pieces, against limits of 30 and $2\times10^6$ terminal pieces. These are heuristic predictions for this proxy, not necessary depths or complexity bounds for reliable integration. The EXACT column is unresolved, and its success path is separately unimplemented.

**Ordinary terms.**

| level | $D_0$ | $\delta_u$ | $E_v$ | $c_RE_R$ | $E_y/b_M$ | $\varepsilon_0$ | $R_\mu$ | $R_k$ |
|---|---|---|---|---|---|---|---|---|
| control (N=256, M=128) | 1.00000002 | 1.61e-7 | 3.150e-6 | 9.07e-7 | 3.81e-7 | 1.29e-6 | 4.88e-5 | 1.56e-5 |
| main (N=512, M=256) | 1.00000002 | 5.17e-8 | 3.145e-6 | 1.62e-7 | 6.82e-8 | 2.31e-7 | 3.63e-5 | **1.17e-5** |

Both levels are `ORDINARY_R_K_ABOVE_TARGET` (target $R_k\le10^{-6}$).

**Dominant sources (main level, contribution to $R_\mu$ = $C_\rho/(D_0-\varepsilon_0)\times$ term, $C_\rho=10.603$):**

1. **Finite proxy vs reconstruction, $E_v$: $3.33\times10^{-5}$ (92 % of ordinary $R_\mu$).** Its ordinary value changes little between the two levels (3.150e-6 → 3.145e-6). This suggests a persistent fixed-field contribution, but shared evaluation bias has not been excluded; the cause is unresolved.
   - In-box $\|v_R-w_d\|$ supplies almost all of it ($9.87\times10^{-12}$ squared); $T_d=1.2\times10^{-7}$ and $T_v=1.0\times10^{-7}$.
   - The squared defect divided by mass is about 28 times larger in the lead cells than in the centre; the corresponding norm ratio is about 5.3.
   - The main-level in-box defect squared has about 30.788 % in $|m|\le3$ and 33.369 % in the bands $\bigl||m|-48j\bigr|\le3$, $j=1,\ldots,5$. The first 48-band alone contributes 31.145 %; there $\|v_R-w_d\|/\|v_R\|\approx0.630$ and $\|w_d\|/\|v_R\|\approx0.809$, so the reconstructed field is not negligible. These observations are consistent with a native-grid imprint but do not establish its cause or separate FEM, geometry and evaluation errors.
2. Source Q1, $c_RE_R$: $1.72\times10^{-6}$.
3. Mode truncation, $E_y/b_M$: $7.2\times10^{-7}$.
4. Q2 proxy, $\delta_u$: $5.5\times10^{-7}$.
5. Integration/coefficient evaluation: **not bounded** (the gate failed and the reliable success path is unimplemented).

**Interpretation.** Substituting the current ordinary $E_v$ alone gives a formula scale of about $1.07\times10^{-5}$ in $k$; this is not an established floor for the estimator, spectral distance or eigenvalue error. With the current ordinary denominator and constants, the target $R_k\le10^{-6}$ corresponds to a total defect budget of about $2.9\times10^{-7}$. The ordinary $E_v$ is about 11 times that scale, and the other included terms total about $2.8\times10^{-7}$. These are diagnostic comparisons only: missing source-moment and evaluation errors prevent a reliable conclusion. The current evidence does not establish that the native FEM must be refined.

**Integration checks (main).**
- Mass $1$ to $7\times10^{-16}$; template area defect $\le4.6\times10^{-15}$.
- P2 inclusion area defect $\le5\times10^{-16}$; true inclusion area defect $\le1.1\times10^{-16}$.
- Newton residual $1.4\times10^{-15}$; node consistency $1.5\times10^{-16}$.
- Self-tests: Dunavant $2\times10^{-15}$, clip $1.4\times10^{-16}$, Yukawa vs direct quadrature $3\times10^{-14}$.

**Costs (MATLAB exclusive, s).** Adapter 2.6, gates 4.9, projection 167.7 (main: 6 passes × 26 s), Yukawa/norms 6.8, figures 4.6, save 2.3; 191 s in the function. 9.4 M (control) and 23.0 M (main, per pass) quadrature points.

The monitored wall time of 203.6542 s measures the ordinary diagnostic path, not a completed reliable estimate. The complete cost of reliable evaluation remains unknown.

## D1 history: caveats

- The ordinary $\varepsilon_0$ omits the moment-error term $\min\{\delta_c/(s+\beta^2),\overline C_G\delta_1\}$. Reliable source-moment, direct-defect and norm enclosures remain unimplemented; multiplying an ordinary norm by $1-10^{-12}$ does not establish a lower enclosure.
- True-material sliver points are assigned to auxiliary rectangles using the P2 boundary segment midpoint, without ensuring that the actual sliver stays in that rectangle. The review identifies an algorithmic gap; its occurrence and contribution in this run have not been quantified. Area and mass checks do not resolve it.
- The 12-point norm quadrature has no remainder control, and projection/mode coefficients were not retained for independent reconstruction of $E_v$. The saved data support scalar and energy aggregation, not a complete evaluation-error audit.
- Raw negative records: on the main level, 198 columns have negative $T_v$ Parseval tails, with minimum $-8.7\times10^{-19}$ (roundoff against column energies of order $10^{-3}$). They are kept unclipped; the total $T_v^2=1.04\times10^{-14}$ is positive.
- Gate width proxies use conservative amplitude/area estimates and heuristic scaling; not all ingredients are proved enclosures. Their failure does not prove that every reliable integration strategy is infeasible.
- Peak RSS 2.865 GB is above the 2.7 GB warning. The MATLAB baseline is about 1.8 GB after start-up and 2.3 GB after the adapter.
- The recorded status contains a survivor PID whose identity was not retained; complete process cleanup was not established. RSS sampling covers the MATLAB process tree, not the outer launcher and summary processes.
- Continuing full ordinary evaluation after gate failure and using mode blocks larger than 32 departed from D1. The diagnostic results are retained, but this is not a claim of full compliance with the original design.

## Outputs per run

D2 (run-03):
- results and records: `result.json`, `integration.json` (with block index), `partial-result.json`, `progress.json`, `selftest.json`, `pilot.json`;
- tables: `pilot.csv`, `levels.csv`, `cells.csv`, `modes.csv`;
- data: `native.mat`, `blocks/<level>/*.mat`;
- figures: `figures/{cells,engine,modes,terms}.png`;
- `source/`;
- launcher records: `config.json`, `command.json`, `provenance.json`, `preflight.json`, `resources.csv`, `run.log`, `status.json`, `summary.{json,md}`.

D1 runs additionally have `gate.csv` and `figures/gate.png`.
