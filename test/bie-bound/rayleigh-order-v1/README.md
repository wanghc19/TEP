# Rayleigh order study version 1

BIE = boundary integral equation; DtN = Dirichlet-to-Neumann; QZ = generalized Schur decomposition; SVD = singular-value decomposition; FMM = fast multipole method; RSS = resident set size; RMS = root mean square; JSON = JavaScript Object Notation; CSV = comma-separated values; W3 = three missing rows. $M$ is the Rayleigh half-width and $K=2M+1$.

## Purpose

Measure candidate-root truncation versus $M$ and cut position, then test cell flux conservation, stable-space neutrality and multiplier counts. All results are floating-point diagnostics. The root rate is independent of the tested cuts and faster than the proposed conservative strip rate. Flux conservation and a raw count of $K$ do not by themselves identify a gap.

## Predictions recorded before the runs

The manager predicts an exchanged evanescent order across a homogeneous scatterer-to-scatterer strip of width $w$ to decay as $e^{-|\gamma_m|w}$, independently of the port position inside the strip. Thus
$$\operatorname{err}(M)\approx C e^{-|\gamma_{M+1}|w_{\min}},\qquad |\gamma_m|\approx2\pi|m|/d.$$
The rival one-sided prediction uses the rod-to-port distance $\delta$ instead of $w_{\min}$ and changes with the cut position.

For example 1, the supplied extents are star $[-0.305,0.360]$, left rod $[-1.176,-0.777]$, right rod $[0.828,1.238]$. The supplied strip widths are 0.468 on the right, 0.472 on the left, and about 0.59/0.60 between lead rods. The predicted conservative reduction per unit $M$ is $e^{-6.3(0.468)}\approx1/19$. Earlier solver-cost data give errors $1.47\times10^{-9}$ at $M=2$, $4.5\times10^{-11}$ at $M=3$ (about $1/33$), and $M=4$ inside its reference interval. These are predictions/background, not measurements of this experiment.

The draft dimension argument predicts a $J$-neutral decaying space with dimension $K$ in a gap. Possible failure settings are bands, Wood points, omitted propagating orders and discretization error larger than the cluster separation. The tested diagnostic is normalized flux defect versus radial distance to the unit circle. Neutrality alone gives an upper limit of $K$; equality also needs a regular stable/growing dichotomy.

## Geometry and fixed settings

Analytic boundary sampling at 65,536 parameters gives the following $x$ strip widths. All periods have $d=1$. Example 1 has the unrotated star, density 4 inside, and left/right trilobes with parameters 0.12/0.20, density 17 inside. Example 2 has an empty center, $L_-=1$, $L_+=0.85$, and right rotation 0.13. Its strip across the empty center extends between the two first rods. W3 has circular rods of radius 0.2 and density 9, $h=\sqrt3/2$, an empty center of width $3h$, and a two-row lead period $2h$.

| Geometry | Center strip(s) | Left/right lead row strips | $w_{\min}$ |
|---|---|---|---|
| Example 1 | 0.4713147404 / 0.4684758621 | 0.6006160480 / 0.5908404518 | 0.4684758621 |
| Example 2 | 1.5171029692 | 0.6006160480 / 0.4288674892 | 0.4288674892 |
| W3 | 3.0641016151 | $h-0.4=0.4660254038$ at both row joins | 0.4660254038 |

W3 intact rows have centers $(\pm2h,-1/4)$, $(\pm3h,+1/4)$ and then alternate. Using a single rod per period would miss the internal row join. Example-1 star extrema are $[-0.3054873310,0.36]$. Left and right local rod extrema are $[-0.1761860234,0.2231979286]$ and $[-0.1715241379,0.2376354103]$; the rotated example-2 right extrema are $[-0.1846991022,0.2364334086]$. Source: [geometry.json](output/run-001/geometry.json).

The baseline density counts are 128/64/64 (center/left/right); W3 has 64 nodes on each rod of each two-row lead, and empty centers have no density unknowns. Example 1 is also run at 192/96/96. The respective Bloch parameters are 0.5, 0.5 and 1.67541. Proxy side/top counts 160/160, proxy edge count 80, plane-wave parameter 32 and requested FMM tolerance $10^{-12}$ stay fixed. Each $M$ recomputes the field at that fixed density discretization.

The numerical source files named in [copied-sources.json](copied-sources.json) were copied from `test/bie-bound/failure-probe-v1/`. The cell, geometry, scattering and classification formulas are unchanged. `study.m` adds the ladders and flux diagnostics; the local monitor enforces 2 GiB. The launcher supplies package and FMM paths explicitly. It does not configure science from documentation or previous results.

## Part 1: roots and rates

Local determinant Newton steps use a centered derivative with step $10^{-6}$, at most eight iterations, starting from the three documented candidates. A real step below $5\times10^{-16}$ or an unchanged binary64 value stops the iteration; the final scaled singular-value ratio confirms the root. All 63 roots have ratio at most $6.474\times10^{-14}$. These are local candidate continuations, not new searches for every possible root.

Reference roots at $M=24$, with the same density, are:

| Geometry / density | $k_{24}$ |
|---|---|
| Example 1 / 128/64/64 | 1.5584378941820891 |
| Example 1 / 192/96/96 | 1.5584378941820873 |
| Example 2 / 128/64/64 | 1.8916961400527357 |
| W3 / 128/64/64 | 2.0106210217581520 |

The table gives $|k_M-k_{24}|$ for each configuration's own reference. A zero means equality of the returned binary64 values, not zero mathematical error.

| Model / nodes / cut | M1 | M2 | M3 | M4 | M5 | M6 | M7 | M8 |
|---|---|---|---|---|---|---|---|---|
| ex1 / 128 / +0.00 | 9.0509e-07 | 1.47737e-09 | 4.94522e-11 | 5.4845e-13 | 2.22045e-15 | 0 | 0 | 0 |
| ex1 / 192 / +0.00 | 9.0509e-07 | 1.47737e-09 | 4.9454e-11 | 5.4956e-13 | 3.9968e-15 | 1.33227e-15 | 6.66134e-16 | 2.22045e-16 |
| ex2 / 128 / +0.00 | 1.01043e-06 | 1.40552e-09 | 1.33749e-11 | 6.27054e-13 | 1.42109e-14 | 4.44089e-16 | 2.22045e-16 | 2.22045e-16 |
| w3 / 128 / +0.00 | 5.20166e-06 | 1.30031e-08 | 3.91571e-11 | 1.30118e-13 | 2.22045e-15 | 0 | 0 | 0 |
| ex1 / 128 / -0.04 | 9.0509e-07 | 1.47737e-09 | 4.94538e-11 | 5.4956e-13 | 3.33067e-15 | 4.44089e-16 | 2.22045e-16 | 8.88178e-16 |
| ex1 / 128 / +0.06 | 9.0509e-07 | 1.47737e-09 | 4.94527e-11 | 5.4845e-13 | 2.66454e-15 | 4.44089e-16 | 6.66134e-16 | 0 |
| ex1 / 128 / +0.16 | 9.0509e-07 | 1.47737e-09 | 4.94538e-11 | 5.49338e-13 | 3.10862e-15 | 2.22045e-16 | 1.33227e-15 | 2.22045e-16 |

Fit the natural logarithm of the error against $M$. The preselected floor is 20 binary64 spacings of $k_{24}$. For example 1, also require the error to exceed ten times both paired-density differences, at $M$ and at 24. This gives a floor of $1.7764\times10^{-14}$ for example 1. The maximum paired-density difference is $1.7764\times10^{-15}$; at each retained point the root error exceeds both density differences by at least a factor 308.7. The fixed-density comparisons for example 2 and W3 do not measure their remaining density error.

Set $w_{\rm eff}=-\mathrm{slope}/(2\pi)$. All points above the floor are used, without selecting points for a straighter fit. RMS and maximum residuals are in natural-log units.

| Model / N / cut | M used | effective width | strip width | per-order ratio | RMS log residual | max log residual |
|---|---|---|---|---|---|---|
| ex1 / 128 / +0.00 | [1, 2, 3, 4] | 0.737625 | 0.468476 | 0.00970965 | 0.664985 | 1.09784 |
| ex1 / 192 / +0.00 | [1, 2, 3, 4] | 0.737528 | 0.468476 | 0.00971557 | 0.665194 | 1.09805 |
| ex2 / 128 / +0.00 | [1, 2, 3, 4, 5] | 0.698279 | 0.428867 | 0.0124328 | 0.942044 | 1.26166 |
| w3 / 128 / +0.00 | [1, 2, 3, 4] | 0.92814 | 0.466025 | 0.00293316 | 0.0718346 | 0.0843189 |
| ex1 / 128 / -0.04 | [1, 2, 3, 4] | 0.737528 | 0.468476 | 0.00971557 | 0.665194 | 1.09805 |
| ex1 / 128 / +0.06 | [1, 2, 3, 4] | 0.737625 | 0.468476 | 0.00970965 | 0.664985 | 1.09784 |
| ex1 / 128 / +0.16 | [1, 2, 3, 4] | 0.737547 | 0.468476 | 0.00971439 | 0.665152 | 1.09801 |

Example 1 excludes $M=5$–8; example 2 excludes 6–8; W3 excludes 5–8. The root reduction is not uniform: example-1 successive error ratios for $M=1\to2$, $2\to3$, $3\to4$ are about $1/613$, $1/29.9$, $1/90.2$. A single exponential is only an effective description of four or five resolved points. In particular, omitting $M=1$ changes the fitted widths:

| Geometry, baseline density | Retained $M$ in sensitivity fit | $w_{\rm eff}$ | RMS log residual |
|---|---|---|---|
| ex1 | [2, 3, 4] | 0.628557 | 0.260370 |
| ex2 | [2, 3, 4, 5] | 0.597879 | 0.338285 |
| w3 | [2, 3, 4] | 0.916116 | 0.023209 |

The resolved errors fall faster than the conservative $w_{\min}$ prediction in all three geometries. They do not establish that the sharp exponent equals $w_{\min}$. W3 is close to $2w_{\min}$; a round-trip or quadratic sensitivity could explain this, but this experiment does not derive that mechanism. Fourier-density decay, mode coupling and cancellation also affect the root error. Individual fit residuals and all sensitivity fits are saved in [fits.csv](results/fits.csv), [late-fits.csv](results/late-fits.csv) and [tables.md](results/tables.md).

### Cut-position test

Only the center–right-lead port moves; scatterers remain at their physical positions, and the right periodic cell is reanchored consistently. The left port remains at $x=-1/2$. The following singular values use orthonormal stable bases and $\mathsf D=Z_a+Z_b$. Values at roots are minima over $M=1$–8 and 24; the I9-window column uses $M=6$ and 41 frequencies in $[1.451,2.249]$.

| Right shift | Port $x$ | Center clearance $\delta$ | Right-rod clearance | $w_{\rm eff}$ | Minimum $\sigma_{\min}(\mathsf D_-)$ at roots | Minimum $\sigma_{\min}(\mathsf D_+)$ at roots | Right minimum on I9 grid | Maximum root change from reference cut |
|---|---|---|---|---|---|---|---|---|
| -0.04 | 0.46 | 0.10 | 0.368476 | 0.737528 | 0.589335 | 0.653974 | 0.493963 | 1.554e-15 |
| +0.00 | 0.50 | 0.14 | 0.328476 | 0.737625 | 0.589335 | 0.578219 | 0.420451 | 0.000e+00 |
| +0.06 | 0.56 | 0.20 | 0.268476 | 0.737625 | 0.589335 | 0.460316 | 0.307424 | 6.661e-16 |
| +0.16 | 0.66 | 0.30 | 0.168476 | 0.737547 | 0.589335 | 0.253863 | 0.112996 | 1.332e-15 |

Full-precision left/right singular values are in [roots.csv](results/roots.csv); the left cut is unchanged. All root ladders are unchanged within $1.56\times10^{-15}$ while $\delta$ changes threefold. This supports the cut-independent strip prediction and contradicts using center-to-port $\delta$ as the root-rate exponent. Diagonal reanchoring of a fixed retained Fourier space already explains why moving a cut need not change the finite-$M$ root.

The copied `find_cut.m` reproduces an exceptional right shift 0.2771873742063102 at the candidate, with $\sigma_{\min}(\mathsf D_+)=3.25\times10^{-14}$. The selected shifts are regular on the sampled I9 window and at the roots. This is not a statement of regularity over the entire physical common gap. An additional 81-point scan over $[1.317514080243,2.380744148165]$ found small singular values below I9's lower search endpoint. Local minimization and a DtN sign reversal give:

| Shift | Approximate pole frequency | Minimum trace singular value found | Extreme DtN eigenvalue at $k-10^{-6}$ / $k+10^{-6}$ |
|---|---|---|---|
| +0.06 | 1.3265390342 | 2.659e-09 | 3.017e+05 / -3.020e+05 |
| +0.16 | 1.3853510940 | 1.658e-08 | 9.059e+05 / -9.207e+05 |

These poles do not affect the local root ladders or the sampled I9 window. Thus the requested clearance range is usable there, while shifts $+0.06$ and $+0.16$ are unsuitable for a single DtN determinant across the wider physical common gap without splitting at the poles. A finite scan cannot exclude an unobserved narrow pole. Sources: [cut-window.csv](results/cut-window.csv), [cut-full-gap.csv](results/cut-full-gap.csv), [cut-poles.json](output/run-006/cut-poles.json).

### Port-coefficient tails

At each candidate, normalize the incident vector $q=(a_{\rm L},b_{\rm R})$ to $\|q\|_2=1$. Recover $b_{\rm L}=R_{\rm L}a_{\rm L}+T_{\rm RL}b_{\rm R}$ and $a_{\rm R}=T_{\rm LR}a_{\rm L}+R_{\rm R}b_{\rm R}$. The table uses the envelope $A_M=(|a_{-M}|^2+|a_M|^2)^{1/2}$, and similarly for $B_M$, at the truncation order itself. Signed-order magnitudes for both $|m|=M$ and $M-1$, for every ladder, are in [tails.csv](results/tails.csv).

| Geometry | $M$ | $A_{\rm L,M}$ | $B_{\rm L,M}$ | $A_{\rm R,M}$ | $B_{\rm R,M}$ | Root error |
|---|---|---|---|---|---|---|
| ex1 | 2 | 2.035e-04 | 3.098e-04 | 5.410e-04 | 1.343e-04 | 1.477e-09 |
| ex1 | 4 | 2.578e-07 | 6.885e-06 | 1.447e-05 | 2.072e-07 | 5.485e-13 |
| ex1 | 6 | 5.805e-10 | 9.446e-08 | 7.434e-07 | 1.752e-10 | 0.000e+00 |
| ex1 | 8 | 9.772e-13 | 4.668e-09 | 4.914e-08 | 7.049e-13 | 0.000e+00 |
| ex2 | 2 | 2.733e-05 | 2.345e-09 | 1.036e-10 | 3.688e-04 | 1.406e-09 |
| ex2 | 4 | 6.850e-07 | 3.914e-18 | 1.184e-17 | 2.233e-07 | 6.271e-13 |
| ex2 | 6 | 5.054e-09 | 3.641e-25 | 2.984e-25 | 6.517e-09 | 4.441e-16 |
| ex2 | 8 | 3.928e-11 | 2.006e-32 | 7.971e-33 | 1.025e-10 | 2.220e-16 |
| w3 | 2 | 9.129e-04 | 7.527e-16 | 7.527e-16 | 9.129e-04 | 1.300e-08 |
| w3 | 4 | 1.465e-06 | 6.139e-33 | 6.139e-33 | 1.465e-06 | 1.301e-13 |
| w3 | 6 | 3.370e-09 | 8.727e-50 | 8.727e-50 | 3.370e-09 | 0.000e+00 |
| w3 | 8 | 9.040e-12 | 1.504e-66 | 1.504e-66 | 9.040e-12 | 0.000e+00 |

The tail is not a root-error estimate: example-1 $A_{\rm R,8}$ is still about $10^{-8}$ after the root has reached its numerical floor. Empty-center propagation makes two amplitude families much smaller than the incoming families in example 2 and W3.

On each $M=24$ reference field, fit the combined $\pm m$ right-port envelope over the same orders $m=3$–8, using its natural logarithm. This gives a fair comparison between cuts; each entry below gives the width and its RMS log residual. All six points are retained in each fit.

| Shift | Center clearance | $a_{\rm R}$ tail width (RMS) | $b_{\rm R}$ tail width (RMS) | Sum of tail widths | Root width |
|---|---|---|---|---|---|
| -0.04 | 0.10 | 0.192124 (0.090732) | 0.521522 (0.500428) | 0.713646 | 0.737528 |
| +0.00 | 0.14 | 0.232217 (0.090969) | 0.481704 (0.497355) | 0.713921 | 0.737625 |
| +0.06 | 0.20 | 0.292355 (0.091322) | 0.421982 (0.492867) | 0.714337 | 0.737625 |
| +0.16 | 0.30 | 0.392581 (0.091903) | 0.322454 (0.485870) | 0.715036 | 0.737547 |

Moving the cut by 0.10 changes the two individual tail widths by approximately $+0.10$ and $-0.10$, as predicted by $a\mapsto e^{i\gamma\ell}a$, $b\mapsto e^{-i\gamma\ell}b$. Their sum stays near 0.714, while the root rate stays fixed. The offsets between the individual widths and the geometric clearances show additional decay in the source coefficients. They support a two-sided interaction interpretation, without identifying a sharp universal root exponent. The longer tail fits (orders 3–10 where amplitude exceeds $10^{-14}$), with every fitted order and residual, are in [tail-fits.csv](results/tail-fits.csv); the fixed-order cut fits are in [cut-tail-fits.csv](results/cut-tail-fits.csv).

## Part 2: flux and dimension

At an anchored wall, the code uses $\psi_m=d^{-1/2}e^{i\beta_my}$, $u_m=a_m+b_m$ and $(\partial_xu)_m=i\gamma_m(a_m-b_m)$. Therefore the flux $\operatorname{Im}\int\bar u\partial_xu$ has the proposed blocks: $\gamma\operatorname{diag}(1,-1)$ for real $\gamma$, and $\kappa\left[\begin{smallmatrix}0&-i\\i&0\end{smallmatrix}\right]$ for $\gamma=i\kappa$. In the code's all-$a$, then all-$b$ ordering,
$$J=\begin{bmatrix}\operatorname{diag}(\operatorname{Re}\gamma)&-i\operatorname{diag}(\operatorname{Im}\gamma)\\ i\operatorname{diag}(\operatorname{Im}\gamma)&-\operatorname{diag}(\operatorname{Re}\gamma)\end{bmatrix}.$$
Both walls use the same $+x$ flux convention; the cell conservation form is $J\oplus(-J)$. For an incoming vector $(a_{\rm L},b_{\rm R})$, form the solution graph
$$G=\begin{bmatrix}I&0\\R_{\rm L}&T_{\rm RL}\\T_{\rm LR}&R_{\rm R}\\0&I\end{bmatrix},\qquad X=\operatorname{qr}(G).$$
The two reported defects are $F=\|X^*(J\oplus-J)X\|_2/\|J\|_2$ and $N=\|Z_s^*JZ_s\|_2/\|J\|_2$. The left stable basis uses the reciprocal pencil. Reorder QZ with every strict $|\zeta|<1$ multiplier; never force its count to $K$. In band cases $Z_s$ may thus have 12 or 14 columns. Define $s=\min||\zeta|-1|$. Also record the count below $1-10^{-8}$ and the number in $||\zeta|-1|\le10^{-8}$, so a rounding displacement of a propagating multiplier is visible.

The empty-cell propagation map has $F=8.24\times10^{-17}$. An independent 1024-point wall quadrature gives flux agreement $4.85\times10^{-16}$. One right rod cell at $k=1.5584378941820891$ has $F=1.94\times10^{-15}$, $N=1.86\times10^{-15}$, 13 stable multipliers, maximum stable modulus 0.383936 and minimum outside modulus 2.604603. This validates the normalization and signs before using them on the scans. Sources: [empty-flux.json](output/run-001/empty-flux.json), [rod-flux.json](output/run-001/rod-flux.json).

All scans use example 1 at 128/64/64 and $M=6$, hence $K=13$. The 47 frequencies give 94 lead cases:

- (a): 21 equally spaced points from 1.318414080243 to 2.379844148165, $\beta=0.5$.
- (b): the common lower/upper edges 1.317414080243 / 2.380844148165, approached from the gap by $10^{-2},10^{-3},10^{-4}$. There are six frequencies per lead.
- (b-extra): also approach the left lead's own edges 1.312557304887 / 2.395219092458. Some of these frequencies are inside the right lead's bands; they are separated from the common-gap rows.
- (c): $\beta=1.98154$, $k-\beta=\pm10^{-1},\pm10^{-2},\pm10^{-3},\pm10^{-4}$. The exact Wood point is excluded.
- (d): $k=1.30,1.31,1.316,2.382,2.39,2.40$, $\beta=0.5$. Each frequency is in at least one lead's band, not necessarily both.

Table entries for defects are maxima and entries for $s$ and $\min|\gamma|$ are minima over each row. L/R mean negative/positive physical leads.

| Location / lead | Frequencies | Strict inside counts | Near-unit cases | Maximum $F$ | Maximum $N$ | Minimum $s$ | Minimum $|\gamma|$ |
|---|---|---|---|---|---|---|---|
| a / L | 21 | [13] | 0 | 2.099e-15 | 4.292e-15 | 1.517e-01 | 1.219924 |
| a / R | 21 | [13] | 0 | 2.075e-15 | 1.043e-14 | 6.531e-02 | 1.219924 |
| b-common / L | 6 | [13] | 0 | 9.929e-16 | 4.292e-15 | 1.405e-01 | 1.218952 |
| b-common / R | 6 | [13] | 0 | 1.012e-15 | 2.470e-14 | 2.114e-02 | 1.218952 |
| b-extra / L | 6 | [13] | 0 | 1.040e-15 | 2.697e-14 | 2.131e-02 | 1.213701 |
| b-extra / R | 6 | [12, 13, 14] | 5 | 1.171e-15 | 6.324e-02 | 1.998e-15 | 1.213701 |
| c / L | 8 | [13] | 0 | 7.930e-15 | 3.772e-13 | 8.107e-01 | 0.019907 |
| c / R | 8 | [13] | 0 | 7.922e-15 | 3.204e-13 | 8.054e-01 | 0.019907 |
| d / L | 6 | [12, 13] | 3 | 1.007e-15 | 5.592e-03 | 1.110e-15 | 1.200000 |
| d / R | 6 | [13, 14] | 6 | 1.012e-15 | 6.340e-02 | 2.220e-16 | 1.200000 |

The ranges of the largest strict-inside modulus and smallest strict-outside modulus are:

| Location / lead | Range of $\max_{|\zeta|<1}|\zeta|$ | Range of $\min_{|\zeta|\ge1}|\zeta|$ |
|---|---|---|
| a / L | 0.290154039 – 0.848310337 | 1.17881388 – 3.44644521 |
| a / R | 0.297028739 – 0.934688768 | 1.06987484 – 3.36667759 |
| b-common / L | 0.662243102 – 0.859515817 | 1.16344572 – 1.5100195 |
| b-common / R | 0.768397938 – 0.978861694 | 1.02159478 – 1.30140901 |
| b-extra / L | 0.765835569 – 0.978694137 | 1.02176968 – 1.30576333 |
| b-extra / R | 0.0187788735 – 1 | 1 – 52.349321 |
| c / L | 0.174722912 – 0.189342686 | 5.28142924 – 5.72334785 |
| c / R | 0.180203422 – 0.194611239 | 5.13844939 – 5.54928419 |
| d / L | 0.0191948238 – 1 | 1 – 1.35799659 |
| d / R | 1 – 1 | 1 – 51.7726161 |

The wide extrema in band rows arise when the strict count places both near-unit multipliers on the same side. They must be read together with the annulus count. Full per-frequency records, including every multiplier modulus, are in [dimension.json](output/run-003/dimension.json); scalar columns are in [dimension.csv](results/dimension.csv). The solution-graph constraint residual is at most $1.53\times10^{-16}$ and its orthogonality defect at most $1.12\times10^{-15}$. Every sampled $J$ has signature $(13,13)$. All propagating Rayleigh orders are retained in these tests.

### Does flux defect versus cluster distance separate the counts?

No. It holds in all gap-interior, gap-edge and nonzero Wood-offset cases, where every count is $K$. It also holds in four band cases whose strict counts differ from $K$, and fails in one band case whose strict count happens to be $K$:

| Location / lead / $k$ | Strict count | $F$ | $s$ | $F<s$ |
|---|---|---|---|---|
| b-extra / R / 2.385219092458 | 12 | 1.001e-15 | 7.550e-15 | yes |
| b-extra / R / 2.394219092458 | 14 | 5.039e-16 | 1.998e-15 | yes |
| b-extra / R / 2.395119092458 | 12 | 1.171e-15 | 1.066e-14 | yes |
| d / R / 2.390000000000 | 13 | 5.062e-16 | 2.220e-16 | no |
| d / L / 2.400000000000 | 12 | 3.137e-16 | 1.110e-15 | yes |

Here the near-unit displacements and $F$ are both at rounding scale. This comparison is not a pencil perturbation test and does not include multiplier conditioning. The annulus test flags all band rows with such multipliers. Small neutrality alone also fails as a dimension test: a 12-dimensional stable space in a band can be neutral to rounding. Conversely a strict count of 13 can include a propagating multiplier and have neutrality defect about $10^{-2}$.

Approaching the Wood crossing to a nonzero distance $10^{-4}$ preserves the count and separation in this example; neutrality degrades to $3.78\times10^{-13}$ and $\min|\gamma|$ falls to 0.0199072. This does not test the degenerate flux form at the exact Wood point. No test omits a propagating order. These conclusions are diagnostics of the sampled discretization, not a proof of the draft dimension argument.

## Prediction verdicts

- Exponential convergence before the numerical floor: supported, with substantial non-single-exponential behavior in examples 1 and 2. The strip widths give conservative scales; the measured effective widths are larger.
- Cut-independent root rate: supported. The one-sided center clearance changes from 0.10 to 0.30 while all pre-floor root ladders agree to rounding. Individual coefficient tails do track the cut.
- A $K$-dimensional neutral decaying cluster in the sampled common gap: supported down to the tested $10^{-4}$ edge distance and at all tested nonzero Wood offsets.
- “Flux defect below cluster distance” as a separator for count $K$: contradicted by the band rows. It is an ancillary check, not a replacement for annulus separation and an actual count.

## Reproduction

From the repository directory, use an empty output directory for each launch. The following commands reproduce the five successful runs, with run-007 and onward replacing the original output numbering so retained records are untouched. `launch.py` copies the used numerical source into each run's `inputs/`, supplies paths explicitly, sets MATLAB and OpenMP to five threads with `OMP_DYNAMIC=FALSE`, and calls the copied memory monitor. The commands need the usual permission for MATLAB startup and process-tree monitoring.

```sh
python3 -B test/bie-bound/rayleigh-order-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/rayleigh-order-v1/output/run-007 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode pilot
python3 -B test/bie-bound/rayleigh-order-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/rayleigh-order-v1/output/run-008 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode part1
python3 -B test/bie-bound/rayleigh-order-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/rayleigh-order-v1/output/run-009 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode part2
python3 -B test/bie-bound/rayleigh-order-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/rayleigh-order-v1/output/run-010 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode cutcheck
python3 -B test/bie-bound/rayleigh-order-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/rayleigh-order-v1/output/run-011 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode cutpoles
python3 -B test/bie-bound/rayleigh-order-v1/summarize.py --pilot test/bie-bound/rayleigh-order-v1/output/run-001 --ladder test/bie-bound/rayleigh-order-v1/output/run-002 --dimension test/bie-bound/rayleigh-order-v1/output/run-003 --cutcheck test/bie-bound/rayleigh-order-v1/output/run-004 --output test/bie-bound/rayleigh-order-v1/results
env OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 conda run -n octave python -I test/bie-bound/rayleigh-order-v1/verify.py --experiment test/bie-bound/rayleigh-order-v1
```

The `summarize.py` command regenerates tables from retained runs; substitute run-007/008/009/010 for a fresh numerical rerun. The final `verify.py` command independently checks the retained results. Pole data are produced directly by `cutpoles` and do not enter the rate fits.

## Checks

1. **Pass.** Example 1, $\beta=0.5$, 128/64/64, $M=6$, reference cut: $k=1.5584378941820891$, difference $1.11\times10^{-15}$ from 1.558437894182088, relative difference $7.13\times10^{-16}$, inside $2\times10^{-14}$.
2. **Pass.** The full example-1 ladder was repeated at 192/96/96. Paired differences are at most $1.78\times10^{-15}$. Only $M=1$–4 are fitted at either density; the smallest retained error is $5.48\times10^{-13}$. Every retained error exceeds the paired-density differences by more than the factor-ten rule. Excluded points are listed above.
3. **Pass.** The empty-cell defect $8.24\times10^{-17}$ and independent wall-flux difference $4.85\times10^{-16}$ pass the preselected $10^{-13}$ test. The rod-cell flux and neutrality defects are $1.94\times10^{-15}$ and $1.86\times10^{-15}$ at a qualified gap frequency.
4. **Pass.** Every root fit, sensitivity fit and tail fit records its orders and RMS log residual; per-point log residuals are in the CSV/JSON files. No point at the prescribed root floor is fitted. An independent NumPy least-squares calculation reproduces all root and sensitivity widths and RMS residuals within $10^{-13}$; see [checks.json](results/checks.json).

## Cost

Estimates were recorded before each launch: pilot 30–120 s / 1.2 GiB; Part 1 5–15 min / 1.5 GiB after the pilot; Part 2 2–6 min / 1.2 GiB; full-gap cut scan 30–60 s / 1.0 GiB; pole location 30–120 s / 1.0 GiB. All runs have 30/40 min soft/hard time limits, 2 GiB process-tree RSS limit and five computational threads.

| Run | Work | Monitored wall seconds | Peak process-tree RSS (GiB) | Outcome |
|---|---|---|---|---|
| 001 | Regression, geometry, empty/rod flux | 18.33 | 0.787 | completed |
| 002 | 63 roots and I9 cut scan | 327.46 | 0.790 | completed |
| 003 | 94 lead diagnostics | 29.20 | 0.868 | completed |
| 004 | Full-gap cut scan | 44.43 | 0.735 | completed |
| 005 | Pole locator, initial implementation | 20.08 | 0.733 | stopped on missing field |
| 006 | Corrected pole locator | 21.44 | 0.860 | completed |

Run-005 referenced an unavailable propagation field. Its failure log and source are retained; the corrected locator obtains multipliers from the cell pencil. Total monitored time including that failure is 460.94 s, peak RSS 0.868 GiB. There are no field MAT files. These timings are resource records under concurrent machine use and support no cost comparison.

## Choosing the order and checking the dimension

For these smooth geometries, $M=4$ already gives fixed-density root differences of about $10^{-13}$–$10^{-12}$, and $M=5$ reaches the observed floor. Choose $M$ by a short ladder at fixed density, use the narrowest scatterer-to-scatterer strip as a conservative starting scale, and confirm density convergence separately. A small coefficient at one port is insufficient because its magnitude changes with the anchor. For the lead dimension, check the actual ordered-QZ count, a unit-circle exclusion annulus, pencil residuals and flux neutrality together; the scalar comparison $F<s$ does not separate band counts from gap counts. The tested finite Wood offsets remain usable, but the exact Wood point, omitted propagating orders, sharper root-rate mechanisms and continuous exclusion of DtN poles remain outside these diagnostics.
