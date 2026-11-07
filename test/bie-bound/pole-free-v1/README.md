# Pole-free port matching, version 1

BIE = boundary integral equation. DtN = Dirichlet-to-Neumann. QZ = generalized Schur decomposition. SVD = singular value decomposition. FMM = fast multipole method. RSS = resident set size. RMS = root mean square. LU = lower–upper factorization. QP = quasi-periodic. In filenames, det means determinant and config means configuration. W3 denotes three missing rows. I9 identifies the inherited search implementation.

**Yes.** On the nine distinct cases the bordered search returned every expected physical candidate at both resolutions, with no pole accepted and no refusal. All 18 independent scan counts agreed. The 10 coarse/fine root pairs passed the physical jump tests, including both modes in the width-2 guide.

The final coarse reference root was 1.5584378941820876, an absolute difference of 4.44e-16 from 1.558437894182088 (tolerance 2e-14). On the six regular cases the largest grid-matched old/new difference was 8.44e-15. The largest difference between a bordered determinant root and the corresponding independently minimized singular value frequency was 3.55e-15. [Independent scalar checks](results/checks.json).

## Cases and results

The regular reference, empty-center, width-2 and small-star windows span 1.451–2.249 at beta 0.5 (the reference plan gives the exact input). The three shifted-cut windows are centered at 1.558437894182088 with half-width 0.003. The offset, aligned and node cases move the right port by +0.276187374206313, +0.277187374206313 and +0.1 respectively. W3 at beta 1.67541 uses 1.9729201864543902–2.048318410140545. W3 at beta 0.2 uses 2.0797343366764434–2.1048670779051615. All cases have tangential period one. The width-2 example and the gapedge $L_0=2$ point are the same physical configuration.

A grid label gives center node count $N$ and Rayleigh half-width $M$. Each lead row has $N/2$ density nodes. A row of the table describes one accepted physical root. The dense count refers to the complete window. The old search column gives the legacy singular-value ratio at its own candidate. The next ratio column evaluates the divided matrix at the new candidate. Counts stay open for refused and timed old searches. Prior coarse comparisons are identified in [baselines.csv](baselines.csv).

| Case and grid | Old search, k (ratio) | New accepted k | DtN ratio at new k | Four-wall jump | Material jump | Bordered minimum singular value | Dense count |
|---|---|---:|---:|---:|---:|---:|---:|
| reference, 128/6 | complete, 1.558437894182088 (3.01e-14) | 1.5584378941820876 | 3.25e-14 | 4.3e-06 | 0.000189 | 1.42e-14 | 1 |
| reference, 192/12 | complete, 1.5584378941820884 (3.07e-14) | 1.5584378941820889 | 3.13e-14 | 4.19e-09 | 6.77e-06 | 1.39e-14 | 1 |
| offset, 128/6 | refused, no returned root | 1.5584378941820884 | 2.42e-16 | 4.33e-05 | 0.000189 | 1.38e-14 | 1 |
| offset, 192/12 | timed observation, 1.5562502584026721 (4.66e-16) provisional | 1.5584378941820887 | 2.14e-16 | 1.5e-07 | 6.75e-06 | 1.27e-14 | 1 |
| aligned, 128/6 | refused, no returned root | 1.5584378941820889 | 4.61e-18 | 4.53e-05 | 0.000189 | 1.35e-14 | 1 |
| aligned, 192/12 | refused, no returned root | 1.5584378941820887 | 3.29e-18 | 1.63e-07 | 6.75e-06 | 1.26e-14 | 1 |
| node, 128/6 | timed observation, 1.558437894182088 (2.71e-14) provisional | 1.5584378941820891 | 2.65e-14 | 2.11e-07 | 0.000189 | 1.29e-14 | 1 |
| node, 192/12 | timed observation, no returned root | 1.5584378941820889 | 2.87e-14 | 5.32e-11 | 6.77e-06 | 1.39e-14 | 1 |
| example2, 128/6 | prior complete, 1.8916961400527379 (8.08e-15) | 1.8916961400527355 | 6.34e-15 | 1.17e-06 | 1.1e-05 | 5.36e-15 | 1 |
| example2, 192/12 | complete, 1.8916961400527388 (9.28e-15) | 1.8916961400527352 | 6.61e-15 | 3.93e-11 | 3.21e-08 | 5.58e-15 | 1 |
| width2, 128/6 | prior complete, 1.455557163284519 (1.55e-14), 2.2156203475844976 (1.89e-14) | 1.4555571632845183 | 1.5e-14 | 6.15e-07 | 1.01e-05 | 2.42e-14 | 2 |
| width2, 128/6 | same list | 2.2156203475844891 | 4.29e-15 | 2.33e-06 | 1.44e-05 | 3.56e-15 | 2 |
| width2, 192/12 | complete, 1.455557163284519 (1.53e-14), 2.2156203475844984 (1.85e-14) | 1.4555571632845177 | 1.55e-14 | 1.85e-11 | 2.33e-08 | 2.51e-14 | 2 |
| width2, 192/12 | same list | 2.2156203475844900 | 4.22e-15 | 8.04e-11 | 5.6e-08 | 3.35e-15 | 2 |
| w3-1.67541, 128/6 | prior complete, 2.0106210217581522 (5.74e-14) | 2.0106210217581517 | 5.71e-14 | 1.08e-08 | 8.57e-15 | 5.34e-14 | 1 |
| w3-1.67541, 192/12 | complete, 2.0106210217581526 (5.83e-14) | 2.0106210217581522 | 5.86e-14 | 6.67e-13 | 9.17e-15 | 5.46e-14 | 1 |
| w3-0.2, 128/6 | prior complete, 2.0893110383208939 (1.95e-14) | 2.0893110383208944 | 2.05e-14 | 6.55e-09 | 7.05e-15 | 1.69e-14 | 1 |
| w3-0.2, 192/12 | complete, 2.0893110383208939 (1.95e-14) | 2.0893110383208939 | 1.95e-14 | 9.85e-14 | 8.56e-15 | 1.6e-14 | 1 |
| small-star, 128/6 | prior complete, 1.8206100861078613 (1.36e-14) | 1.8206100861078669 | 1.1e-14 | 0.00189 | 0.000271 | 7.4e-15 | 1 |
| small-star, 192/12 | complete, 1.8206100861078576 (1.19e-14) | 1.8206100861078578 | 1.72e-14 | 0.00048 | 1.19e-05 | 1.14e-14 | 1 |

Run-001 reproduced the old reference root exactly. Its localized old fallback confirmed the false frequencies 1.5562502581483555 and 1.5562502584026721 with ratios 4.47e-16 and 4.66e-16. In the full offset-cut window the coarse old search refused. The fine old fallback confirmed the pole twice before its 520 s observation ended. Its global list is incomplete.

The fine old aligned-cut search first reached a 180 s observation limit. With the same settings and a 480 s allowance it refused with an unresolved fallback after 194.5 s. Both old node-centered observations reached 130 s. The coarse observation had already confirmed the physical root provisionally.

## Physical acceptance

The physical test normalizes the incident amplitudes to unit Euclidean norm. On each grid require the four-wall RMS and the material jump norm to be below 0.005. Each fine jump must also be at most max(0.8 times its coarse value, 1e-11), allowing the circular-rod quadrature floor. Prior measured true jumps include 0.00189 at the small star. The false pole gave wall jumps 0.0525 and 0.0605. A root must recur at both resolutions (matching tolerance 1e-8). The singular-value ratio of the old matrix is diagnostic only. The reference case must match within 2e-14 on the coarse grid. Require complex determinant identity error below 1e-10 at each of five regular frequencies.

## Equations and variables

Let $K=2M+1$ and $n=2N$ for a center with an inclusion sampled at $N$ nodes. An empty center has $n=0$. The solver assembles the full $(n+4K)$-square matrix in traveling-wave amplitude coordinates. Write $W$ for the diagonal square roots of the boundary quadrature weights repeated for both densities, $u=W\eta$, and $a=(a_L,b_R)$ for the incident coefficients. Its column order is $(u,a,c_-,c_+)$.

| Mathematical object | MATLAB quantity | Computation |
|---|---|---|
| Center transmission equations $J$ | `b.J` | $[A_{\rm QP}, W B_L, W B_R]$ from the center Müller equation and incident Cauchy data |
| Left amplitude map $Y_-$ | `b.YL` | $(a_L,F_L W^{-1}u+Eb_R)$ |
| Right amplitude map $Y_+$ | `b.YR` | $(F_R W^{-1}u+Ea_L,b_R)$ |
| Propagation $E$ | `raw.E` or empty-center transmission | $\operatorname{diag}(e^{i\gamma_m L_0})$ |
| Raw decaying spaces $Z_s$ | `b.ZL, b.ZR` | Ordered QZ of the reciprocal pencil on the left and the forward pencil on the right |
| Panel overlap $O_s$ and chart frame $Z_s^a$ | `ol, orr` and `zl, zr` | $O_s=Z_s(k_{\rm mid})^*Z_s(k)$, $Z_s^a=Z_s/O_s$ |
| Matched field | `border_field.m` | Smallest right singular vector of the raw full matrix. Normalize $\lVert a\rVert_2=1$, recover the physical density $W^{-1}u$ and propagate the two lead-coordinate blocks. |

The rows of the bordered matrix are

$$
H=\begin{bmatrix}J&0&0\\Y_-&-Z_-^a&0\\Y_+&0&-Z_+^a\end{bmatrix}.
$$

The new center path assembles its BIE rows and far-field extractors before any density solve. It retains the original scattering solves for each periodic lead. At a polished frequency the field is reconstructed in the raw orthonormal lead frames. The chart change is invertible, so the full system has the same physical null states. Only the old-ratio diagnostic uses the old closure at a proposed frequency, after the bordered field has been determined.

Each panel uses fixed left and right diagonal scales. The reciprocal row norms at its midpoint give `dr`, then the reciprocal column norms of the row-scaled midpoint matrix give `dc`. The same `dr` and `dc` multiply $H(k)$ throughout that panel. The overlap gate is $\sigma_{\min}(O_s)\ge0.05$ and $\operatorname{cond}_2(O_s)\le20$ on both sides. The lower singular-value gate also detects a uniformly small overlap with a modest condition number. A failed gate splits the panel. Over the measured panels the smallest overlap singular value was 0.89538 and the largest condition number was 1.11684. Four broad panels split once on the interpolation tests (the empty center at widths 1 and 2, on both grids). All chart checks passed. A change of raw basis $Z_s\mapsto Z_s U$ cancels in $Z_s^a$ wherever the overlap is invertible.

### Simple zeros at sampled nodes

The scalar interpolant uses complex LU phase and log modulus, normalized to the largest sampled modulus on the level. The value at a zero node can therefore enter as zero. The degree doubles from 8 through 64. The last three coefficient magnitudes relative to the largest must be below $10^{-10}$ and two fresh off-grid values must agree to $10^{-9}$. A failed interpolation check leads to bisection. The sampled log span is recorded on every level. It does not veto an otherwise resolved polynomial.

At nodes with relative modulus below $10^{-8}$, two nearby differences compare slopes using a step of 0.001 panel half-width. A relative slope change below 0.02 and a node value less than $10^{-5}$ times step times slope give an additional simple-zero proposal. The node stays in the interpolant. Its finite near-zero value preserves the samples used to locate other roots on the same panel. A real Newton correction projects the complex scalar step onto the frequency axis. Polished proposals within $2\times10^{-12}$ are merged. Final acceptance uses the independently reconstructed field jumps on both grids. On each material curve, Fourier-interpolate the actual densities to twice the native node count and evaluate the transmission residual at the interleaved off-node points. The arclength norm includes the value and normal derivative. For walls, compare the two reconstructed traces and their physical x derivatives at 40 shifted points on each of two junction walls and two adjacent lead walls. The output also records horizontal seam and internal W3 row checks. The paired absolute and refinement gates apply to the material norm and the four-wall RMS.

### Shifted-cut and node controls

At the old pole the raw bordered minimum singular values were 0.001754816 and 0.001754815. The corresponding old divided-matrix ratios were 4.47e-16 and 4.66e-16. Sampling the same physical window gave one bordered zero at the physical mode on each grid. A paired field test at the false frequency gave:

| Field at the old pole | Wall, coarse / fine | Material, coarse / fine | Absolute gate | Refinement gate |
|---|---:|---:|---|---|
| Old DtN singular vector | 0.052459 / 0.060527 | 1.90e-4 / 6.79e-6 | fail | fail |
| Least-singular vector of the full bordered matrix | 0.00352692 / 0.00352665 | 0.00223201 / 0.00222401 | pass | fail |

The two-grid rule rejects both. Reordering and rephasing both raw lead bases changed the anchored matrix by at most 1.34e-16 relative in Frobenius norm. At the aligned cut the largest overlap condition over the two searches was 1.000005, although the Dirichlet trace is nearly singular. [Control fields](output/run-018/control.json) · [Gate values](output/run-018/control-rules.json).

At the +0.1 cut, the root was at the middle interpolation node. The old coarse log span was 25.9576 (limit 18). The new spans were 25.9533 and 25.9640. Both new panels finished at degree 8. The two-slope relative differences were 9.73e-6 on each grid, and the two off-grid interpolation errors were 8.48e-13 and 1.02e-12. The large span came from sampling a physical zero. It persisted after removing the Dirichlet division. [Coarse panel](output/run-012/search-128.json) · [Fine panel](output/run-012/search-192.json).

### Independent scan and determinant comparison

The independent scan samples the absolute smallest singular value of the full unscaled matrix in the raw orthonormal QZ frames. Changing these frames by unitary factors preserves all singular values. The scan minimizes every sampled interior dip, then applies local quadratic updates to the squared singular value. Minima below $10^{-8}$ and endpoints below that threshold count as scan proposals. Its grid and frequency minimization are independent of the determinant interpolation. Both calculations share the physical discretization. A matching tolerance of $10^{-8}$ is used only to compare lists. The independent reference for each physical root is in `baselines.csv`. Moving a cut through the empty strip leaves the physical reference frequency unchanged. The comparison tolerance is $2\times10^{-14}$ for example 1 at the reference cut on the coarse grid and $10^{-12}$ for the remaining comparisons.

The old code stores $A_{\rm def}=N_0-\operatorname{diag}(\Lambda_-,\Lambda_+)T_0$ **after** center-density elimination, using physical Cauchy data. A comparison of full complex determinants in the implemented coordinates consequently includes the center-block determinant and the amplitude-to-Cauchy coordinate determinant. With $G=\operatorname{diag}(\gamma_m)$, $D_s=[I,I] Z_s$ in the raw frames, the tested identity is

$$
\det H=
\frac{(-1)^K\det A_{\rm QP}\det D_-\det D_+\det A_{\rm def}}
{\det(4G^2)\det O_-\det O_+}.
$$

The empty center contributes a factor of one. The sign corresponds to regrouping the two value blocks and the two outward-derivative blocks. The two port transforms have determinants $\det(2iG)$ and $\det(-2iG)$. The test uses the unscaled bordered matrix. The determinant of the equilibrated search matrix additionally includes the products of the fixed row and column scales. The identity check uses separate LU factorizations and the old solver's independently assembled $A_{\rm def}$. Its tolerance applies to the modulus of the complex determinant ratio minus one, including phase.


| k | Relative complex determinant mismatch | Smaller overlap singular value |
|---:|---:|---:|
| 1.48 | 2.134e-14 | 0.935803 |
| 1.63 | 1.001e-14 | 0.979156 |
| 1.78 | 2.450e-14 | 0.997928 |
| 1.95 | 2.501e-14 | 0.995610 |
| 2.16 | 5.676e-15 | 0.950940 |

All five frequencies passed. The maximum was 2.5013e-14 against 1e-10. The individual amplitude, phase and transformation factors are in [identity.json](output/run-003/identity.json).

The copied experiment helpers are `detsearch.m`, `i9_adapter.m`, `physical_checks.m`, `probe_config.m`, `example_config.m`, `example_parameters.m`, `search_i9_config.m`, `search_i9_geometry.m`, `search_i9_classify.m`, `search_i9_physics.m` and `search_config.m` from failure-probe-v1. Its `probe.m` supplies the old-route dispatcher. Its launcher and monitor supply process-tree sampling and the MATLAB launch command. The copies set five threads, permit the concurrent experiment and enforce the 2 GiB limit. The new physics path adds uneliminated center blocks. The field evaluator uses the density from the bordered singular vector. The inherited lead, kernel and quadrature routines are shared read-only dependencies.

## Measured cost

The 26 serial monitored launches accounted for 3,989.60 s (66.49 min) in total, with peak process-tree RSS 0.899 GiB. Paired runs include the independent dense scans and off-node fields. Old-route replays, timed observations, and the initial regression are included. MATLAB R2023b and OpenMP were limited to five threads. Another experiment could share the machine.

The regular fine-grid old comparisons were rerun. Run-004 used the raw reference frame at the midpoint, equivalent to the normalized frame in exact arithmetic. Run-025 repeats the reference with the overlap solve applied at the midpoint as everywhere else. The result table uses run-025. Both runs appear in the cost table.

<details>
<summary>Per-run wall time and peak memory</summary>

| Run | Plan | Monitored wall (s) | Peak RSS (GiB) |
|---:|---|---:|---:|
| run-001 | old-reference, pole-128, pole-192 | 44.1 | 0.811 |
| run-002 | old-pole-128 | 184.8 | 0.800 |
| run-003 | identity | 16.4 | 0.822 |
| run-004 | reference | 279.2 | 0.859 |
| run-005 | old-pole-192 | 534.5 | 0.879 |
| run-006 | old-aligned-128 | 134.6 | 0.894 |
| run-007 | old-aligned-192 | 193.3 | 0.896 |
| run-008 | old-node-128 | 144.8 | 0.896 |
| run-009 | old-node-192 | 143.7 | 0.865 |
| run-010 | offset | 163.0 | 0.877 |
| run-011 | aligned | 164.1 | 0.853 |
| run-012 | node | 158.8 | 0.864 |
| run-013 | example2 | 210.2 | 0.899 |
| run-014 | width2 | 244.1 | 0.884 |
| run-015 | w3-1.67541 | 128.8 | 0.870 |
| run-016 | w3-0.2 | 114.1 | 0.854 |
| run-017 | small-star | 268.1 | 0.829 |
| run-018 | false-pole-control | 67.6 | 0.852 |
| run-019 | old-reference-192 | 36.2 | 0.855 |
| run-020 | old-example2-192 | 98.0 | 0.859 |
| run-021 | old-width2-192 | 99.9 | 0.871 |
| run-022 | old-w3-1.67541-192 | 28.2 | 0.830 |
| run-023 | old-w3-0.2-192 | 18.6 | 0.847 |
| run-024 | old-small-star-192 | 35.1 | 0.880 |
| run-025 | reference | 271.6 | 0.888 |
| run-026 | old-aligned-192 | 207.9 | 0.859 |

</details>

<details>
<summary>Prelaunch forecasts</summary>

The old reference and two localized fallback replays are forecast at 1–4 min and 0.8–1.4 GiB. The six original-window old-route observations use 130–520 s observation limits, based on failure-probe-v1, and are forecast below 1.5 GiB each. Keep provisional confirmations distinct from completed global lists. The old replay at the observed pole uses the same narrow brackets as the prior experiment. It tests the actual fallback confirmation independently of how long a full search spends reaching it.



The identity pilot is forecast at 10–35 s and below 1.3 GiB. Each new paired search includes fresh Chebyshev evaluations, 65–101 independent uniform SVD samples per grid, local minimum refinement and physical fields. Forecast 2–8 min for a narrow window, 3–12 min for a broad one, below 1.6 GiB (largest matrix 484 square). A second physical process may affect wall time. No timing comparison is intended.

The serial sequence in `plans/series.json` records each complete-run forecast in seconds. For runs 005–009 the forecasts are 565, 220, 220, 175 and 175 s. For the eight remaining paired cases they are 360, 360, 360, 550, 680, 390, 390 and 600 s. The false-pole field control on both grids and both representations is forecast at 115 s. Each forecast is below 1.6 GiB. The monitor enforces 2 GiB on the process tree.

The regular fine-grid old searches were forecast at 90–190 s each. The final paired regression was forecast at 370 s, and the extended old fine aligned-cut observation at 200–500 s. Each was forecast below 1.5 GiB.

</details>

## Reproduction

From the repository root, pass the shared packages, FMM2D installation, MATLAB executable and plan explicitly. Choose an empty output directory for every launch.

```sh
p="$PWD/test/bie-bound/pole-free-v1"
matlab=/Applications/MATLAB_R2023b.app/bin/matlab
fmm="$PWD/vendor/fmm2d/matlab"
python3 -B "$p/launch.py" --package-root "$PWD" --matlab "$matlab" --fmm "$fmm" --plan "$p/plans/identity.json" --output "$p/output/run-NNN"
```

For a paired new search, use a plan named `reference`, `offset`, `aligned`, `node`, `example2`, `width2`, `w3-1.67541`, `w3-0.2` or `small-star`, with suffix `.json`. For the old route pass `--old` and its `old-*.json` plan. The `control.json` plan evaluates both field representations at the old pole. The serial manifest has the complete plans and forecasts for the main runs. Execution uses MATLAB R2023b, five computational threads, five OpenMP threads and disabled OpenMP dynamic scheduling. Times include startup and exit. Timing was recorded while concurrent numerical work was permitted.

The scalar tables can be regenerated without a solver run. From this directory use

```sh
python3 -B summarize.py output baselines.csv results
python3 -B render_tables.py output results baselines.csv results/tables.md
python3 -B check_results.py output baselines.csv results/checks.json
```

The last command independently reapplies the physical gates to both field records, compares the sorted frequency lists and checks the complex identity factors and the original pole confirmations. Scientific entry points receive their numerical configuration from the plan. Historical results are comparison inputs to the postprocessor.

For the extended old aligned-cut comparison use the old-aligned-192-long plan. The measured windows and exact inputs are also saved in each run directory.

## Remaining limits

The lead scattering calculation still uses Rayleigh extractors containing $1/\gamma_m$, so the exact Wood-point failure occurs upstream of the bordered system. Gap qualification also requires a separated decaying cluster. The earlier [Wood probe](../failure-probe-v1/README.md) records that failure. The reported results concern isolated real candidates on the specified grids. Close or multiple zeros, panel charts that fail after eight bisections, and a field with vanishing incident norm are outside the demonstrated range. The physical thresholds are empirical and the uniform scan does not certify a count between samples.
