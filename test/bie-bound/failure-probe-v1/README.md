# Failure probe version 1

BIE = boundary integral equation. DtN = Dirichlet-to-Neumann. QZ = generalized Schur decomposition. QR = orthogonal–triangular factorization. FMM2D = two-dimensional fast multipole method. SVD = singular value decomposition. PWE = plane-wave expansion. RSS = resident set size. W3 = three missing rows. I9 is the inherited numerical search identifier.

Determine which solver difficulties change the outcome of a candidate search, and measure the effect on the field or root. All results are floating-point diagnostics on the stated windows.

## Manager predictions recorded before any run

1. Wood points are real. In example 1 the $m=0$ Wood line $k=|\beta|$ crosses the common gap for $\beta$ between about 1.45 and 2.25. The guided branch probably meets it and the current solver refuses or loses accuracy there.
2. Dirichlet exceptional values are absent in the reference window at $\beta=0.5$, as suggested by the surface-state certificate. Moving the cut inside a lead cell will introduce a pole near a root and disturb determinant search.
3. The center representation gives no spurious roots on the existing examples.
4. QZ gives no failure. Individual eigenvectors degrade only very close to a gap edge.

## Results

| Probe | Observed on | Search or field symptom |
|---|---|---|
| P1 Wood threshold | The first common stop band in all three claddings. Branches of example 1 and W3 approach the threshold from both sides. | At exact equality the lead solve fails before center matching. Near equality the port conditioning and the confirmation ratio deteriorate. |
| P2 Dirichlet pole | Example 1 with the right cut displaced by +0.2761873742. Rods, materials, beta and the physical eigenvalue are unchanged. | The fallback accepts a false frequency 0.00218764 below the mode. Direct matching of lead subspaces removes the false minimum on both grids. |
| P3 Spurious center root | Six reference modes and the quarter-scale star with 0.01 clearance to its right wall. | The six reference modes have nonzero fields and small refined jumps. The false pole has a substantial wall jump on both grids. |
| P4 Stable subspace | Four lead gap edges and an empty-center mode tuned to within 1e-8 of the lower edge. | Principal angles increase near the edge. The QZ and eigenvector root estimates differ by at most 2.0e-15 in the tuned cases. |

All numbers below are floating measurements or approximations. The following counts use a real-frequency uniform scan independent of the determinant interpolation. It finds each sampled local minimum of the weighted singular-value ratio, minimizes locally, interpolates the square, and applies the same $10^{-11}$ confirmation cutoff. The two searches share the BIE discretization. Neither sampled list proves completeness.

P1 and P2 occurred. P3 held on the tested center representations. For P4 the QZ prediction held and the angle increased only near the edge. We did not observe an eigenvector-based root failure.

## P1. Wood thresholds

The background port density and tangential period equal one. The Wood lines are $k=|\beta+2\pi m|$. We followed the gap between the first and second bands of the two example leads and the folded second and third bands of W3. A Fourier bulk calculation uses 33 tangential phases in $[0,\pi]$, 25 normal phases across the full Brillouin zone and bracketed root finding for the Wood crossing using fresh band evaluations.

| Model | Beta interval containing the $m=0$ threshold, Fourier cutoff 4 | Cutoff 6 |
|---|---:|---:|
| Example 1 | (1.38393, 2.43383) | (1.38359, 2.43149) |
| Example 2, including width 2 | (1.49473, 2.40360) | (1.49440, 2.40144) |
| W3 | (1.96787, 3.02940) | (1.96709, 3.02214) |

The $m=-1$ line had no intersection on the tested range. All remaining orders lie higher. At beta 1.95, 1.90 and 2.95 respectively, all six lead computations (two grids per guide) classified points at detunings $\pm10^{-10}$ as gap points. At exact equality, division by $\gamma_0=0$ in the far-field extractor produced a nonfinite pencil scale in examples 1 and 2. W3 stopped one step earlier at its two-row join, whose reciprocal condition was NaN. The positive-side extractor norms in example 1 were about 10,400 and 8,500 at detuning $10^{-10}$.

A continuation in signed $k-\beta$ reached $\pm0.1,\pm0.01,\pm0.001,\pm0.0001$ on the example-1 and W3 branches. Interpolating between the closest two detunings gives crossing estimates 1.98154 and 2.97503 in beta. For example 1, decreasing the positive detuning from 0.1 to 0.0001 raises the condition number of the traveling-wave to Cauchy-data map from 65 to 1,991, and lowers the right lead / center BIE reciprocal conditions from 0.0103 / 0.0170 to 0.000633 / 0.000465. At the smallest positive detuning, the real Newton estimate changed by $6.41\times10^{-12}$ under joint density and Rayleigh refinement in example 1 and by $2.65\times10^{-12}$ in W3. A zero change can mean both estimates stopped at the same supplied continuation seed. An exact guided frequency at these phases is unavailable.

Example 2 had no confirmed minimum on the 39-point $k-\beta=0.012$ scan, beta 1.51–2.38, or the two 97-point scans over 1.48–2.42 at detunings −0.012 and +0.0001. The best refined ratios in the latter scans were 5.51e-5 and 4.66e-6, near the lower gap boundary. The bulk crossing alone does not locate a guided branch. [Full sampled bands](output/run-002/bands.csv) · [Branch conditioning](results/wood-branches.csv) · [Fixed-beta roots, refinement and search status](results/wood-fixed.csv) · [Exact and nearby point tests](results/point-checks.csv)

A search can split at a known Wood line to avoid evaluating a zero denominator. To compute a mode exactly there, the field formulation must separate the grazing contribution and retain two independent threshold data, for example the constant and linear normal-coordinate solutions at zero normal wavenumber. Regularizing only the final matching determinant leaves the observed lead failure in place.

| Branch | k − beta | Beta | Coarse / fine minimum ratio in independent scan | Scan counts | Production observation, coarse / fine |
|---|---:|---:|---:|---:|---|
| ex1 | +0.0001 | 1.981371959 | 1.064e-11 / 1.044e-11 | 0 / 0 | incomplete at 130 / 130 s |
| ex1 | -0.0001 | 1.981716142 | 9.119e-12 / 9.134e-12 | 1 / 1 | incomplete at 130 / 130 s |
| w3 | +0.0001 | 2.974897616 | 2.802e-11 / 2.822e-11 | 0 / 0 | incomplete at 90 / 90 s |
| w3 | -0.0001 | 2.975160775 | 3.711e-11 / 3.559e-11 | 0 / 0 | incomplete at 90 / 90 s |

All eight closest one-sided searches exhausted their stated observation time. Their count is open. At +0.01 in W3 the same search finished with one mode. At +0.0001 in W3 a fine-grid real Newton iterate gave 2.95e-12, while the independent minimum search at a frequency only a few trillionths away returned 2.82e-11. The table reports the individual outcomes because the confirmation decision is sensitive at this scale.

In the symmetric windows of half-width 0.001 at the positive 0.0001 branch phases, every determinant search refused at its very first, exact-Wood evaluation. The independent 41-point scan skipped that invalid sample. It returned zero in example 1 and one in W3 on both grids. For W3 the confirmed ratios were 3.13e-12 and 3.00e-12. The change from the narrower scan was caused by different sample and minimizer locations only about 1.4e-12 apart in k. The full-grid records include both minima.

Minimal plans are `exact-wood128.json` and `exact-wood192.json` for the lead failure, and `wood-ex1.json` and `wood-w3.json` for the branch traces.

## P2. Moving the Dirichlet pole

| Guide and beta | Frequency window | Uniform samples | Determinant / scan counts | Minimum left / right Dirichlet trace singular values | Minimum center BIE reciprocal condition |
|---|---|---:|---:|---:|---:|
| Example 1, 0.5 | 1.451–2.249 | 101 | 1 / 1 | 0.433 / 0.420 | 0.0462 |
| Example 2, 0.5 | 1.451–2.249 | 101 | 1 / 1 | 0.433 / 0.0997 | homogeneous center |
| Example 2, width 2, 0.5 | 1.451–2.249 | 101 | 2 / 2 | 0.433 / 0.0997 | homogeneous center |
| W3, 1.67541 | 1.9729202–2.0483184 | 65 | 1 / 1 | 0.0762 / 0.0762 | homogeneous center |
| W3, 0.2 | 2.0797343–2.1048671 | 65 | 1 / 1 | 0.582 / 0.582 | homogeneous center |
| Small star, 0.5 | 1.451–2.249 | 101 | 1 / 1 | same leads as example 1 | 0.1731 |

Each reference count uses 128 center nodes (where applicable), 64 per lead row and 13 Rayleigh channels. W3 uses two staggered rows in each lead period. The fine 101-point scan also found one small-star root. The small-star candidate moves by $3.8\times10^{-15}$ on increasing to 192/96 nodes and 25 channels. All windows, frequencies, statuses and singular-value ratios appear in [counts.csv](results/counts.csv). [Window scans](results/window-grid.csv) give the conditioning against frequency. [Cut locations](results/cuts.csv) give the admissible interval and the minimizing displacement at the reference frequencies.


At a moved cut the physical inclusions stay fixed. A phase translation reanchors the scattering matrices for the cut scan. The subsequent solver runs rebuild the cell matrices at the displaced ports. At the example-1 reference root we scanned 151 admissible cuts on each side, then minimized the smallest singular value of $D=Z_{\rm top}+Z_{\rm bottom}$. On the right the reference values were 0.578 on both grids. The minima below $4\times10^{-14}$ occurred at shifts +0.277187374206313 and +0.277187374080433. The same physical shift +0.277187374206313 was used in both searches. With the center width 2, the low root also admits exceptional displacements −0.22596 on the left and +0.06132 on the right. For the two W3 modes the displacements are approximately $\mp0.09877$ and $\mp0.20323$. For the width-1 empty center the optimized trace stayed above 0.16 at its root over the tested admissible cuts.

| Example-1 right shift | Frequency | Coarse / fine smallest singular values of weighted match | Coarse / fine relative singular values | Interpretation |
|---:|---:|---:|---:|---|
| +0.2761873742 | 1.55625025815 / 1.55625025840 | 0.01961 / 0.01956 | 4.47e-16 / 4.66e-16 | False pole, freshly confirmed by fallback |
| +0.2761873742 | 1.558437894182088 | 1.46e-13 / 1.44e-13 | 2.26e-16 / 2.23e-16 | Physical mode |
| +0.2771873742 | 1.558437894182088 | 2.04e-4 / 2.75e-8 | 4.81e-18 / 5.36e-18 | Numerically singular Dirichlet coordinates at the mode |

In the offset-cut window $k_*\pm0.003$ the uniform 83-point scan found both the pole and the mode at both resolutions. The direct polish checks the Dirichlet reciprocal condition as well as the singular-value ratio. The fallback checks a completed local bracket and the freshly recomputed ratio (see [direct confirmation](detsearch.m#L100) and [fallback confirmation](detsearch.m#L150)). At the pole its largest singular value rose above $2.2\times10^{13}$. The coarse production search refused after an unresolved fallback. The fine fallback marked the pole complete twice and was stopped during a third fallback. Its global list is incomplete. Replaying the production fallback on the respective localized pole with half-width $8\times10^{-15}$, eleven distinct nodes and fresh confirmation reproduced the false branch acceptance on both grids. The coarse replay retained unresolved edge bookkeeping. The fine replay finished. At the aligned cut both broad searches refused. The minima of the divided-matrix ratio shifted from the physical frequency by $1.40\times10^{-10}$ and $3.30\times10^{-10}$.

The tested repair stacks $(I-Z_s Z_s^*)Y_s$ at the two ports, where $Y_s$ maps the center incident amplitudes to its full port amplitudes and $Z_s$ spans the decaying modes. It uses the same center density solve and lead subspaces and avoids division by $D_s$. All four 41-point shifted-cut scans returned only 1.5584378941820890–1.5584378941820891. Their minimized ratios were 2.90e-14–3.11e-14. At the false pole this test gives 0.00402225 on both grids. At the aligned cut, reconstructing the physical mode by projecting directly onto the lead amplitudes reduced the four-wall jump from 0.00605 to 4.53e-5 on the coarse grid and from 8.67e-7 to 1.63e-7 on the fine grid. A production repair should use this matching equation when a Dirichlet trace approaches singularity and apply it to the fallback confirmations. The projected test here is a real-frequency singular-value scan. Retaining complex determinant interpolation would additionally require a regular choice of subspace coordinates across the pole. [Cut ranges and minima](results/cuts.csv) · [Fallback replay](results/fallback-replay.csv) · [Minimum-by-minimum scans](results/scan-minima.csv)

A separate effect occurs at the safe cut +0.1. Placing the physical mode at the first Chebyshev midpoint produced a coarse degree-64 coefficient tail of 6.8e-14 but a sampled log-determinant span of 25.96 (limit 18). Both resolutions exhausted the 130 s observation allowance. Shifting the entire window by +0.00037 kept the same detected mode and reduced search time to 5.17 / 7.64 s. An independently confirmed simple zero at an interpolation node should be distinguished from a pole when interpreting the log span.

Minimal plans are `cut-locate.json`, `cut128-near.json`, `cut192-near.json`, `pole-replay.json` and `chart.json`.

## P3. Physical fields and independent candidate counts

The two grids use 128/64/64 nodes with $M=6$ and 192/96/96 with $M=12$. For each field we integrate $|\nabla u|^2+k^2\rho |u|^2$ over the center and the nearest complete lead period on each side. The first normalization uses the Euclidean norm squared of center density samples and incident amplitudes. The second weights the density samples by arclength. The example-1 mass ratios with two volume quadrature orders were 0.013506 and 0.013514. The energy ratios were 0.0641 and 0.0690. The energy is a diagnostic integral. The material jump uses values and normal derivatives at the midpoints of the native curve parameter intervals. The four-wall jump uses 40 shifted points per wall. The seam uses 24 shifted points and the Bloch phase. W3 also checks its internal row joins.

| Mode (k) | Three-cell energy / squared Euclidean norm, coarse → fine | Same with density arclength weights | Material jump | Four-wall jump |
|---|---:|---:|---:|---:|
| Example 1 (1.558438) | 0.0641 → 0.0428 | 3.05 → 3.05 | 1.89e-4 → 6.77e-6 | 4.30e-6 → 4.19e-9 |
| Example 2 (1.891696) | 18.4 → 18.4 | 18.4 → 18.4 | 1.10e-5 → 3.21e-8 | 1.17e-6 → 3.93e-11 |
| Width 2 (1.455557) | 17.0 → 17.0 | 17.0 → 17.0 | 1.01e-5 → 2.33e-8 | 6.15e-7 → 1.85e-11 |
| Width 2 (2.215620) | 40.3 → 40.3 | 40.3 → 40.3 | 1.44e-5 → 5.60e-8 | 2.33e-6 → 8.04e-11 |
| W3 (2.010621) | 31.8 → 31.8 | 31.8 → 31.8 | 8.5e-15 → 8.7e-15 | 1.08e-8 → 9.39e-13 |
| W3 (2.089311) | 40.9 → 40.9 | 40.9 → 40.9 | 7.2e-15 → 7.9e-15 | 6.55e-9 → 1.16e-13 |
| Small star (1.820610) | 0.0551 → 0.0368 | 7.75 → 7.75 | 2.71e-4 → 1.19e-5 | 1.89e-3 → 4.80e-4 |

For W3 the material jump is at its floating evaluation floor on both grids. Its peak internal row jump falls from 2.14e-8 to 9.27e-13 for the first mode and from 1.59e-8 to 1.17e-13 for the second. In example 1 the raw squared norm sums the density samples without quadrature weights and grows with the number of nodes. The weighted ratio is stable. [Full physical checks](results/fields.csv) include three separate cell energies, masses, seam checks and energy-normalized jumps.

At the false pole the three-cell energy / weighted norm was 3.119 / 3.123, close to 3.092 at the true root with that cut. Its four-wall jump was **0.05246 / 0.06053** on refinement, against **4.33e-5 / 1.50e-7** at the true root. The material jump decreased at both frequencies. A nonzero field and a small material jump alone do not distinguish the pole from the mode.

The energy criterion also depends on distance to Wood. In example 1 the energy divided by the arclength-weighted squared norm decreases from 1.554 at positive detuning 0.1 to 0.00695 at 0.0001. At the latter phase the value agrees across the two grids, the material jump falls from 1.16e-5 to 4.55e-7, and the wall jump falls from 1.61e-7 to 1.56e-10. The coalescing traveling waves make small absolute field energy an unreliable standalone rejection rule near the threshold.

Minimal plans are `physical.json` for the six reference fields and `cut192-on.json` for the two admitted false-pole fields.

<details>
<summary>Two-grid physical checks for every returned or disputed frequency</summary>

Case numbers are shared with the window comparison. Each pair gives coarse / fine. Frequencies from different searches at the same geometry are grouped within 1e-12. Exact source frequencies, the frequency checked on each grid, left/center/right energies and seam and internal-row jumps are in the CSV files. Local continuation estimates that missed the production gate are included.

| Case | Geometry and beta | k | Energy / squared Euclidean norm | Material jump | Four-wall jump |
|---:|---|---:|---:|---:|---:|
| 0 | ex1, 0.5 | 1.5584378941821 | 0.0641 / 0.0428 | 0.000189 / 6.77e-06 | 4.3e-06 / 4.19e-09 |
| 1 | ex2, 0.5 | 1.8916961400527 | 18.4 / 18.4 | 1.1e-05 / 3.21e-08 | 1.17e-06 / 3.93e-11 |
| 2 | edge L=2, 0.5 | 1.4555571632845 | 17 / 17 | 1.01e-05 / 2.33e-08 | 6.15e-07 / 1.85e-11 |
| 3 | edge L=2, 0.5 | 2.2156203475845 | 40.3 / 40.3 | 1.44e-05 / 5.6e-08 | 2.33e-06 / 8.04e-11 |
| 4 | w3, 1.67541 | 2.0106210217582 | 31.8 / 31.8 | 8.5e-15 / 8.7e-15 | 1.08e-08 / 9.39e-13 |
| 5 | w3, 0.2 | 2.0893110383209 | 40.9 / 40.9 | 7.15e-15 / 7.9e-15 | 6.55e-09 / 1.16e-13 |
| 6 | ex1 small star, 0.5 | 1.8206100861079 | 0.0551 / 0.0368 | 0.000271 / 1.19e-05 | 0.00189 / 0.00048 |
| 7 | ex1 cut 0.2761874, 0.5 | 1.5562502581484 | 0.0656 / 0.0437 | 0.00019 / 6.79e-06 | 0.0208 / 0.0203 |
| 8 | ex1 cut 0.2761874, 0.5 | 1.5584378941820 | 0.065 / 0.0434 | 0.000189 / 6.75e-06 | 4.33e-05 / 1.5e-07 |
| 9 | ex1 cut 0.2761874, 0.5 | 1.5562502584027 | 0.0655 / 0.0438 | 0.00019 / 6.79e-06 | 0.0203 / 0.0605 |
| 10 | ex1 cut 0.2771874, 0.5 | 1.5584378941821 | 0.065 / 0.0434 | 0.000189 / 6.75e-06 | 0.00605 / 8.67e-07 |
| 11 | edge L=2.0227098, 0.5 | 1.4509148602637 | 17.2 / 17.2 | 1.03e-05 / 2.35e-08 | 6.1e-07 / 1.82e-11 |
| 12 | edge L=2.0227098, 0.5 | 1.4509148602637 | 17.2 / 17.2 | 1.03e-05 / 2.35e-08 | 6.1e-07 / 1.82e-11 |
| 13 | edge L=2.0958833, 0.5 | 1.4410148602637 | 18.2 / 18.2 | 1.11e-05 / 2.51e-08 | 5.9e-07 / 1.69e-11 |
| 14 | edge L=2.0958833, 0.5 | 1.4410148602637 | 18.2 / 18.2 | 1.11e-05 / 2.51e-08 | 5.9e-07 / 1.69e-11 |
| 15 | edge L=2.1009434, 0.5 | 1.4409158602637 | 18.3 / 18.3 | 1.12e-05 / 2.54e-08 | 5.89e-07 / 2.74e-11 |
| 16 | edge L=2.1009434, 0.5 | 1.4409158602637 | 18.3 / 18.3 | 1.12e-05 / 2.54e-08 | 5.89e-07 / 2.73e-11 |
| 17 | edge L=2.1014263, 0.5 | 1.4409148702637 | 18.3 / 18.3 | 1.12e-05 / 2.54e-08 | 5.88e-07 / 2.18e-10 |
| 18 | edge L=2.1014263, 0.5 | 1.4409148702637 | 18.3 / 18.3 | 1.12e-05 / 2.54e-08 | 5.88e-07 / 2.17e-10 |
| 19 | ex1 cut 0.2771874, 0.5 | 1.5584378943219 | 0.065 / 0.0434 | 0.000189 / 6.75e-06 | 4.54e-05 / 3.31e-06 |
| 20 | ex1 cut 0.2771874, 0.5 | 1.5584378945125 | 0.065 / 0.0434 | 0.000189 / 6.75e-06 | 4.54e-05 / 1.37e-05 |
| 21 | ex1 cut 0.1, 0.5 | 1.5584378941821 | 0.0645 / 0.043 | 0.000189 / 6.77e-06 | 2.11e-07 / 5.32e-11 |
| 22 | ex1, 1.81176738 | 1.9117673817423 | 0.0356 / 0.0238 | 0.000301 / 1.18e-05 | 4.12e-06 / 3.94e-09 |
| 23 | ex1, 1.96435425 | 1.9743542511171 | 0.0324 / 0.022 | 0.000113 / 4.45e-06 | 1.57e-06 / 1.49e-09 |
| 24 | ex1, 1.97982332 | 1.9808233223414 | 0.0228 / 0.0171 | 3.65e-05 / 1.44e-06 | 5.05e-07 / 4.82e-10 |
| 25 | ex1, 1.98137196 | 1.9814719592638 | 0.00578 / 0.00533 | 1.16e-05 / 4.55e-07 | 1.61e-07 / 1.56e-10 |
| 26 | ex1, 1.98137196 | 1.9814719592703 | 0.00578 / 0.00533 | 1.16e-05 / 4.55e-07 | 1.61e-07 / 1.56e-10 |
| 27 | ex1, 1.98171614 | 1.9816161421563 | 0.00587 / 0.0054 | 1.17e-05 / 4.59e-07 | 1.62e-07 / 1.6e-10 |
| 28 | ex1, 1.98326515 | 1.9822651530046 | 0.0232 / 0.0173 | 3.77e-05 / 1.48e-06 | 5.21e-07 / 4.98e-10 |
| 29 | ex1, 1.9987716 | 1.9887716011465 | 0.0324 / 0.0219 | 0.000129 / 5.06e-06 | 1.78e-06 / 1.7e-09 |
| 30 | ex1, 2.1549853 | 2.0549852982808 | 0.0323 / 0.0215 | 0.000607 / 2.4e-05 | 8.57e-06 / 8.14e-09 |
| 31 | w3, 2.78032297 | 2.8803229713290 | 74.9 / 74.9 | 5.38e-14 / 7.88e-14 | 7.04e-08 / 2e-12 |
| 32 | w3, 2.96158339 | 2.9715833878705 | 109 / 109 | 5.22e-14 / 4.84e-14 | 2.06e-07 / 1.04e-11 |
| 33 | w3, 2.97371071 | 2.9747107114691 | 110 / 110 | 1.46e-13 / 1.32e-13 | 2.18e-07 / 4.2e-11 |
| 34 | w3, 2.97489762 | 2.9749976157430 | 111 / 111 | 4.61e-13 / 4.27e-13 | 2.2e-07 / 2.42e-10 |
| 35 | w3, 2.97489762 | 2.9749976157402 | 111 / 111 | 4.57e-13 / 4.01e-13 | 2.2e-07 / 2.07e-10 |
| 36 | w3, 2.97516077 | 2.9750607748926 | 108 / 108 | 4.44e-13 / 3.92e-13 | 2.17e-07 / 2.33e-10 |
| 37 | w3, 2.97634234 | 2.9753423374650 | 101 / 101 | 1.24e-13 / 1.11e-13 | 2.12e-07 / 3.43e-11 |
| 38 | w3, 2.98793351 | 2.9779335131712 | 84.2 / 84.2 | 1.38e-13 / 7.15e-14 | 2.02e-07 / 7.48e-12 |
| 39 | w3, 3.09021882 | 2.9902188246684 | 58.7 / 58.7 | 3.46e-14 / 3.41e-14 | 2.29e-07 / 1.03e-12 |

[All paired checks](results/candidate-checks.csv) · [Cell-by-cell measurements](results/fields.csv) · [Complete frequency provenance](results/candidate-map.json)

</details>

## P4. Decaying subspaces

The example-1 gap edges were 1.31741408 and 2.38084415. The unequal-period edges were 1.44091486 and 2.39521909 at beta 0.5. We bisected the qualification transitions and approached them on the gap side at six distances from 1e-2 down to 1e-12. Over 96 decaying subspaces (two grids, both leads), the smallest distance to the unit circle was 2.83e-6 and the smallest stable-to-unstable complex separation was 5.66e-6. A separate evaluation of the stable multipliers alone gave exactly the same nearest distance at all 96 samples. [Stable-only distances](results/stable-distances.csv). The maximum condition number of the normalized decaying eigenvector columns was 1.31633 and the largest principal-angle sine to the ordered QZ space was 1.89e-10. All column ranks were full. The code qualifies an annulus around the unit circle, so the smallest offsets are relative to its qualification boundary.

At the original example-1 and two width-2 roots, $M=6,12,24,48$ gave full ranks through 97 and a largest angle sine below 1.2e-14. For a root test close to the edge, we tuned the empty width and ran the QZ and eigenvector matching solves from different seeds in the gap. Their largest frequency difference was $2.00\times10^{-15}$ on the eight cases. The eigenvector route forms a QR basis and retains the production gap qualification. [Edge distances, separations, ranks and angles](results/edge-subspaces.csv) · [Original roots](results/root-routes.csv) · [Tuned widths and roots](results/edge-roots.csv)

| Distance in k above lower edge | Tuned empty width | Right stable distance to unit circle | Stable/growing separation | Largest root difference over the two grids |
|---:|---:|---:|---:|---:|
| 0.01 | 2.022709790 | 0.18386 | 0.40914 | 6.66e-16 |
| 0.0001 | 2.095883286 | 0.020175 | 0.040766 | 2.00e-15 |
| 1e-06 | 2.100943378 | 0.0020361 | 0.0040764 | 1.33e-15 |
| 1e-08 | 2.101426271 | 0.00020382 | 0.00040768 | 2.22e-16 |

The independent frequency scans found one candidate at each of the four tuned widths on the coarse grid and at the closest width on the fine grid. The largest absolute difference from the local QZ result was 4.5e-13. At distance 1e-8, both full determinant searches remained incomplete after 25 s even though both local subspace solves and both independent scans located the mode. This timing observation does not separate the two subspace algorithms.

Minimal plans are `edges.json` for the subspaces and `edge-modes.json` for the perturbed-seed root comparison.

## Checks and cost

The example-1 regression returned 1.558437894182088, binary64 `3ff8ef5c92c5bf30`, with zero difference from the reference and tolerance 2e-14. The five reference windows gave six modes by each method, with a maximum paired frequency difference of 7.99e-15. Both small-star grids gave one mode by each method. The threshold failures, false fallback confirmation and the off-node transmission discrepancy were each tested at two resolutions. A stopped or refused search leaves its global count open. [Window-by-window comparison and physical case IDs](results/comparison.csv).

Runs 012/013 stopped their diagnostic continuation before the Newton correction because a nested MATLAB function overwrote a finite-difference sample. Runs 017/018 repeated it with distinct variables and saved every update. Run-023 was stopped after two confirmations of the same pole. In runs 031/032 the 130 s timer fired in the safe-cut control, and a local exception variable shadowed the timeout reporter. The stack identifies both as timed observations. Subsequent capped searches use an explicitly constructed timeout exception. All of these runs enter the cost ledger.

There were 31 matched determinant/scan windows. Ten returned complete lists, and all ten agreed. Seven searches refused, thirteen reached a timed observation limit, and one was stopped after duplicate provisional confirmations. Each such row names the scan count and links its returned or neighboring branch frequencies by physical case ID. All 40 frequency/geometry cases have two physical checks (80 fields). At exact Wood there is no computed field. A skew straddling-window search that avoids an exact Wood sample was left unmeasured because its forecast of 125 s exceeded the remaining 64 s. The results distinguish exact-sample refusal from the measured one-sided stalls.

The 45 serial monitored runs took **7,135.66 s (118.93 min)** in total, including the stopped run and diagnostic repeats. Peak process-tree RSS was **1.009 GiB**. All preflights found the machine free of other numerical jobs. The experiment occupies about 8.63 MB and contains no field MAT files. [Audit values and exceptions](results/audit.json) · [Cost by run](results/cost.csv)

## Reproduction

From the repository root, supply the solver, FMM2D and interpreter paths explicitly. Choose a fresh run number for each command. The plan JSON contains the physical parameters, window, nodes and Rayleigh width. The monitor ledger lists the plans actually run. Each MATLAB case uses R2023b with 11 computational threads. The proxy uses 160 side and top samples, 80 proxy sources per edge and 32 plane-wave orders. Density/Rayleigh refinements keep those settings and the 1e-12 FMM tolerance fixed.

```sh
root="$PWD"
exp="$root/test/bie-bound/failure-probe-v1"
matlab=/Applications/MATLAB_R2023b.app/bin/matlab
fmm="$root/vendor/fmm2d/matlab"
python3 -B "$exp/launch.py" --package-root "$root" --fmm "$fmm" --matlab "$matlab" --plan "$exp/plans/regression.json" --output "$exp/output/run-NNN"
```

Replace `regression.json` with the chosen plan. To reproduce the bulk calculation use `bands.json` and add `--bands-python /path/to/python` (NumPy and SciPy). The independent cut test is `chart.json`, the confirmed-pole fallback replay is `pole-replay.json`, and `edges.json` gives the approach to both band edges. Each output directory contains its exact plan, command, preflight, process-tree monitor and per-case scalar results. The physical cases can be selected individually by passing a JSON array with one element.

`detsearch.m` and `i9_adapter.m` come from solver-cost-v1. The geometry, two-row scattering, example parameters, search controls, lead classification and physics come from litbench-v1 and its example2-v1 source. The launcher and monitor follow litbench-v1. The Fourier indicator integral in `bands.py` follows example2-v1. Off-surface layer evaluation in `physical_checks.m` uses the signs and densities of budget-v1. The added code changes port coordinates, records condition numbers, constructs physical tests and provides the alternative subspace routes. The determinant search saves each provisional confirmation and can stop at an explicit observation-time limit. The singular-value, rank, conditioning and branch acceptance thresholds are the production settings.

The paired field runs use `fields-00.json` through `fields-04.json`. Run-023 was intentionally stopped after its second provisional pole confirmation. For the final edge audit use `edge-count-audit.json --max-wall 188` (the option follows the plan argument). From the experiment directory, rebuild the tables and check the joins with

```sh
python3 -B plan_followups.py fields output results
python3 -B tables.py output results
python3 -B wood_table.py output results/wood-fixed.csv
python3 -B compare.py results/counts.csv results/comparison.csv --case-map results/candidate-map.json
python3 -B field_table.py results/candidate-map.json results/fields.csv results/candidate-checks.csv
python3 -B audit.py output results results/candidate-map.json results/audit.json
```

The target plans and raw records contain more digits than the rounded tables.

[Prelaunch forecasts and observation limits](forecasts.md) · [Per-run monitor costs](results/cost.csv)
