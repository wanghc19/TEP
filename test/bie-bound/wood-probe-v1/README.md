# Wood-point probe version 1

BIE = boundary integral equation; QP = quasi-periodic; MFS = method of fundamental solutions; DtN = Dirichlet-to-Neumann; QZ = generalized Schur decomposition; SVD = singular-value decomposition; LU = lower–upper factorization; RSS = resident set size; RMS = root mean square; JSON = JavaScript Object Notation; CSV = comma-separated values. In inherited filenames, `config` means configuration and I9 labels the earlier search implementation.

## Purpose and answer

The anomaly is already present in the outgoing single-cell representation. The Müller matrix norm grows as $1/|\gamma_0|$, before the far-field extractor is called. Its smallest singular value stays nearly constant. The Green term diverges at a fixed physical separation, independently of any port-coordinate conversion. The amplitude cell map has a square-root branch, while its two-wall Cauchy description has a linear response over the resolved detuning range. Converting coordinates after the outgoing solve leaves a shared QP Green-function error that the two density grids largely miss.

All numbers are floating-point estimates. The exact Wood point is skipped. The experiment diagnoses the representation and its evaluation; it leaves the physical guided-mode problem unchanged.

## Predictions recorded before any run, with verdicts

1. **Held.** Prediction: amplitude-coordinate $S_{\rm cell}$ has a square-root branch, including entries outside the grazing row/column. The common-map norm exponents are 0.4956–0.5001 on $10^{-6}\le t\le10^{-3}$. Later entry fits give 0.4812–0.5434 on $10^{-7}\le t\le10^{-4}$; finite corrections are larger in some weak nongrazing entries.
2. **Partly held.** Prediction: a regular Cauchy-coordinate map is smooth, has exponent one and admits one polynomial across both sides; coordinate conversion loses accuracy like machine precision divided by $|\gamma_0|$, or worse. The measured Cauchy norm exponents are 1.0003–1.0026 on $10^{-6}\le t\le10^{-3}$. The lead inter-grid spread grows near Wood, but a common proxy error dominates before the smallest detuning. A joint polynomial reaches this shared error floor rather than the much smaller density-grid spread.
3. **Held.** Prediction: the Müller reciprocal condition scales as $|\gamma_0|$, and the grazing Green term scales as $1/|\gamma_0|$. On $10^{-7}\le t\le10^{-3}$, fine-grid reciprocal-condition exponents are 0.4954–0.5009 and Green-term exponents are −0.5025 to −0.5000. Matrix-norm exponents are −0.5035 to −0.5020; smallest-singular-value exponents lie between −0.0030 and 0.0011.
4. **Partly held.** Prediction: amplitude-coordinate bordered determinants and minimum singular values have algebraic Chebyshev decay across Wood; Cauchy-coordinate versions decay geometrically until conversion loss. Both amplitude determinants have algebraic tails. The Cauchy determinant decreases by about 0.0111 per order initially, then reaches a $4\times10^{-10}$ plateau. Its $\sigma_{\min}$ remains algebraic because the window includes the guided-mode zero; a small singular value has an absolute-value cusp even when the matrix is smooth.

## Fixed model and samples

Use example 1 with $d=1$, background density 1, the unrotated center star of density 4, left/right trilobes with parameters 0.12/0.20 and density 17, periods 1, and ports at $x=\pm1/2$. No curve is reflected. For each $\beta=1.95,1.98154$, evaluate $k=\beta\pm t$ at $t=10^{-1},\ldots,10^{-7}$ on 128/64/64 with $M=6$ and 192/96/96 with $M=12$. Add 192/96/96 with $M=6$ to distinguish density change from the simultaneous change of $M$. All 84 samples have qualified common-gap lead classifications.

Proxy side/top counts 160/160, proxy edge count 80, plane-wave parameter 32, and requested FMM tolerance $10^{-12}$ stay fixed. Thus the density and Rayleigh refinements share the same Green precomputation. The stored cell matrices are small port maps, not field MAT files. [Raw samples](output/run-004/samples.json) and [scalar sample table](results/samples.csv) contain all settings.

Copied sources and local changes are listed in [copied-sources.json](copied-sources.json). The source directory is `test/bie-bound/pole-free-v1/`; the launcher and monitor come from `rayleigh-order-v1/`. The local physics copy adds a center-cell dispatch and an optional direct proxy-evaluation callback. Its cell, density scaling, geometry and lead formulas are unchanged.

## Cauchy-coordinate conversion and symbol map

Use a **two-wall DtN map**, mapping both wall values to both outward normal derivatives. This is an equivalent Cauchy description and avoids inverting an exponentially small high-order transmission block. Write
$$q=(a_L,b_R),\quad o=(b_L,a_R)=Sq,\quad v=(u_L,u_R),\quad n=(-u'_L,u'_R),\quad \Gamma=\operatorname{diag}(\gamma_m),\quad G=\operatorname{diag}(\Gamma,\Gamma).$$
Then
$$T=I+S,\qquad N=iG(S-I),\qquad v=Tq,\quad n=Nq,\qquad D=NT^{-1},$$
and the inverse conversion is
$$S=(iG-D)^{-1}(iG+D).$$
Here $D$ is the **cell two-wall DtN map**, distinct from the half-lead Dirichlet trace block $\mathsf D_\pm$ of the solver notation. Prescribing both wall values describes a finite-cell boundary-value problem, rather than retaining the outgoing-background closure. This experiment obtains the map by conversion after the outgoing BIE solve; it does not assemble a new finite-cell boundary-value solver.

The regular background basis is $\cos(\gamma x)$, $\sin(\gamma x)/\gamma$. In this basis the free-strip Cauchy propagation matrix is
$$P(\ell)=\begin{bmatrix}\cos(\gamma\ell)&\sin(\gamma\ell)/\gamma\\-\gamma\sin(\gamma\ell)&\cos(\gamma\ell)\end{bmatrix}.$$
Its entries have regular limits in $\gamma^2$ at zero. The traveling-wave-to-Cauchy transform at one anchored wall is $C=[I,I;i\Gamma,-i\Gamma]$, which degenerates when $\gamma_0=0$.

| Symbol | Code in `wood_probe.m` | Meaning |
|---|---|---|
| $\gamma_m$ | `g` | Background Rayleigh wavenumbers |
| $G$ | `G` in `LOCAL_cell` | Duplicated diagonal wavenumber matrix |
| $S$ | `S` | $[R_L,T_{RL};T_{LR},R_R]$ |
| $T,N$ | `T,N` | Incident amplitudes to values/outward derivatives |
| $D$ | `D`, and `Dl,Dr,D0` | Two-wall cell map; left lead, right lead, center |
| Inverse conversion | `back` | Recovered scattering matrix |
| $A_c,B_c$ | `A,B` in `LOCAL_space` | Cauchy lead pencil |
| Original / condensed amplitude / Cauchy borders | `all{1:3}` in `LOCAL_matrices` | Three determinant and SVD routes |

For a cell state $(v_j,w_j)$ with $w_j=\partial_xu$, let $D_{rs}$ be the four blocks of $D$. Cell compatibility gives
$$A_c=\begin{bmatrix}-D_{LL}&-I\\D_{RL}&0\end{bmatrix},\quad B_c=\begin{bmatrix}D_{LR}&0\\-D_{RR}&I\end{bmatrix},\qquad A_c(v_j,w_j)^T=B_c(v_{j+1},w_{j+1})^T.$$
Take the stable space of $(A_c,B_c)$ on the right and of $(B_c,A_c)$ on the left. For the center, use $Y_L=[I,0;-D_{LL},-D_{LR}]$, $Y_R=[0,I;D_{RL},D_{RR}]$. The condensed Cauchy border is $[Y_L,-Z_L,0;Y_R,0,-Z_R]$.

## Fitted exponents and grid differences

All fits use the natural logarithm of an absolute difference against $\log t$. For $S_{\rm ref}$, use a joint cubic in the outgoing $\gamma_0$ over both sides at $t=10^{-4},\ldots,10^{-7}$. Separate one-sided cubic extrapolations give selected-entry limits differing by at most $3.56\times10^{-10}$. For $D_{\rm ref}$, use a joint quadratic in signed $t$ at $|t|=10^{-3},10^{-4},10^{-5}$. The main exponents use $t=10^{-3},10^{-4},10^{-5},10^{-6}$ on each side. The later amplitude fits are a sensitivity check, not replacements for the main fits.

Common matrix comparisons retain orders $-6\le m\le6$ on both walls, including when $M=12$. The following table uses Frobenius norms and the 192/96/96, $M=12$ map. Grid differences compare it with 128/64/64, $M=6$ on those common orders; every individual detuning, entry and same-$M$ density difference is saved in [point-errors.csv](results/point-errors.csv).

| $\beta$ | Cell | Side | $S$ exponent (RMS log residual) | $D$ exponent (RMS log residual) | Maximum grid $\|\Delta S\|_F$ in fit | Maximum grid $\|\Delta D\|_F$ in fit |
|---|---|---|---|---|---|---|
| 1.95 | lead | below | 0.495674 (0.00507) | 1.002590 (0.00488) | 4.509e-13 | 1.926e-12 |
| 1.95 | lead | above | 0.500059 (0.00010) | 1.002268 (0.00519) | 1.587e-13 | 3.021e-12 |
| 1.95 | center | below | 0.499551 (0.00029) | 1.000371 (0.00159) | 4.497e-13 | 2.432e-11 |
| 1.95 | center | above | 0.499749 (0.00044) | 1.000839 (0.00099) | 2.861e-13 | 2.433e-11 |
| 1.98154 | lead | below | 0.495618 (0.00513) | 1.002054 (0.00392) | 1.708e-13 | 1.895e-12 |
| 1.98154 | lead | above | 0.500060 (0.00011) | 1.001321 (0.00316) | 2.169e-13 | 4.035e-12 |
| 1.98154 | center | below | 0.499112 (0.00081) | 1.000304 (0.00151) | 4.717e-13 | 2.697e-11 |
| 1.98154 | center | above | 0.499769 (0.00041) | 1.000676 (0.00066) | 6.026e-13 | 2.707e-11 |

The selected-entry exponents below use the later $10^{-7}\le t\le10^{-4}$ range. Indices 0, 1, 2 mean Fourier orders $m=0,+1,+2$. The 11 and 12 entries involve no grazing channel. Every main and later fit, including its range, RMS residual, maximum grid/density difference and minimum signal/grid ratio, is in [exponents.csv](results/exponents.csv) and [late-exponents.csv](results/late-exponents.csv). Pointwise differences at all fitted detunings are in the linked point table.

| $\beta$ | Cell | Side | $(R_L)_{00}$ | $(T_{LR})_{00}$ | $(R_L)_{11}$ | $(T_{LR})_{11}$ | $(R_L)_{12}$ | $(T_{LR})_{12}$ |
|---|---|---|---|---|---|---|---|---|
| 1.95 | lead | below | 0.498698 | 0.497614 | 0.515781 | 0.496417 | 0.540807 | 0.500316 |
| 1.95 | lead | above | 0.500007 | 0.499989 | 0.501017 | 0.499925 | 0.507802 | 0.500175 |
| 1.95 | center | below | 0.481232 | 0.499831 | 0.505709 | 0.502351 | 0.511916 | 0.501787 |
| 1.95 | center | above | 0.501399 | 0.499966 | 0.500081 | 0.499968 | 0.500517 | 0.499955 |
| 1.98154 | lead | below | 0.498670 | 0.497542 | 0.517054 | 0.493029 | 0.543357 | 0.500106 |
| 1.98154 | lead | above | 0.500007 | 0.499989 | 0.501198 | 0.499953 | 0.508913 | 0.500131 |
| 1.98154 | center | below | 0.487641 | 0.499741 | 0.505726 | 0.502267 | 0.512107 | 0.501696 |
| 1.98154 | center | above | 0.500701 | 0.499968 | 0.500084 | 0.499969 | 0.500538 | 0.499955 |

Some main-range entry exponents are as far from one-half as 0.4542 and 0.6062; the later fits move toward one-half. Small leading coefficients and finite-detuning corrections therefore matter when fitting individual entries. [Extrapolated limits](results/limits.json) and [one-sided limit check](results/limit-checks.csv) retain the limit construction.

### One polynomial through both sides

Fit both signs on $10^{-7}\le|t|\le10^{-2}$, using one polynomial in signed $t$. Maximum Frobenius residuals for the fine map are:

| $\beta$ | Cell | Degree | $S$ residual | $D$ residual | $D$ relative residual |
|---|---|---|---|---|---|
| 1.95 | lead | 2 | 5.640e-02 | 3.105e-06 | 2.588e-08 |
| 1.95 | lead | 6 | 4.951e-03 | 3.103e-06 | 2.587e-08 |
| 1.95 | center | 2 | 6.037e-02 | 2.993e-06 | 2.496e-08 |
| 1.95 | center | 6 | 5.286e-03 | 1.313e-06 | 1.095e-08 |
| 1.98154 | lead | 2 | 5.789e-02 | 2.945e-06 | 2.455e-08 |
| 1.98154 | lead | 6 | 5.082e-03 | 2.944e-06 | 2.454e-08 |
| 1.98154 | center | 2 | 5.925e-02 | 3.557e-06 | 2.966e-08 |
| 1.98154 | center | 6 | 5.189e-03 | 1.538e-06 | 1.283e-08 |

The Cauchy residual is much smaller than the amplitude residual, but stops improving around the shared proxy floor. At $\beta=1.98154$, $t=10^{-7}$, the common-order Hermiticity defects $\|D-D^*\|_F$ are $5.36\times10^{-6}$ (lead) and $2.80\times10^{-6}$ (center), while their inter-grid differences are only of order $10^{-11}$. These larger defects and the independent Green comparison below prevent treating the density spread as a complete accuracy estimate.

The grid-spread table below gives spectral-norm relative differences for the requested pair of grids. Its center column includes a density/truncation floor. The same-$M$ control is retained in [samples.csv](results/samples.csv).

| $\beta=1.98154$, signed detuning | Lead $\Delta S/\|S\|$ | Lead $\Delta D/\|D\|$ | Center $\Delta S/\|S\|$ | Center $\Delta D/\|D\|$ |
|---|---|---|---|---|
| -1e-01 | 2.963e-15 | 5.806e-16 | 4.167e-15 | 4.763e-13 |
| -1e-02 | 2.753e-15 | 5.427e-16 | 3.663e-15 | 6.572e-13 |
| -1e-03 | 1.012e-14 | 1.186e-15 | 1.055e-14 | 6.805e-13 |
| -1e-04 | 3.633e-14 | 4.233e-15 | 2.577e-14 | 6.765e-13 |
| -1e-05 | 1.178e-13 | 1.775e-14 | 1.373e-13 | 6.593e-13 |
| -1e-06 | 1.509e-13 | 4.502e-14 | 4.155e-13 | 6.689e-13 |
| -1e-07 | 5.088e-13 | 8.728e-14 | 1.213e-12 | 7.011e-13 |
| +1e-01 | 2.249e-15 | 2.591e-16 | 1.840e-15 | 1.025e-12 |
| +1e-02 | 4.742e-15 | 1.228e-15 | 2.771e-14 | 7.076e-13 |
| +1e-03 | 1.239e-14 | 1.225e-15 | 2.888e-14 | 6.831e-13 |
| +1e-04 | 1.324e-14 | 3.296e-15 | 4.131e-14 | 6.791e-13 |
| +1e-05 | 6.891e-14 | 2.540e-14 | 1.570e-13 | 6.710e-13 |
| +1e-06 | 1.991e-13 | 1.013e-13 | 5.543e-13 | 6.668e-13 |
| +1e-07 | 1.072e-12 | 2.772e-13 | 1.957e-12 | 5.899e-13 |

The lead Cauchy spread grows from $3.30\times10^{-15}$ at positive detuning $10^{-4}$ to $2.77\times10^{-13}$ at $10^{-7}$, an increase of 84 while $1/|\gamma_0|$ increases by 31.6. Its negative-side increase is about 21. The center spread is dominated by an approximately $7\times10^{-13}$ floor. Thus this comparison resolves growth of numerical loss, while shared kernel error is larger.

## Single-cell conditioning and the grazing Green term

The tables give reciprocal one-norm condition estimates, with **coarse / fine** pairs (128/64/64, $M=6$ / 192/96/96, $M=12$). The Green term is evaluated at target minus source $(-0.4,-0.17)$:
$$G_0=\frac{i}{2d\gamma_0}\exp(-0.17i\beta+0.4i\gamma_0).$$
The extractor factor is $i/(2\sqrt d\gamma_m)$ because its port functions have normalization $d^{-1/2}$. The physical Green Fourier coefficient has $d$ in its denominator; both coincide here since $d=1$.

### Phase 1.95

| Signed detuning | $|\gamma_0|$ | Lead reciprocal condition, coarse / fine | Center reciprocal condition, coarse / fine | $|G_0|$ | QP spectral-reference error |
|---|---|---|---|---|---|
| -1e-01 | 0.616441 | 1.261e-02 / 1.294e-02 | 7.371e-03 / 7.340e-03 | 6.339e-01 | 1.743e-14 |
| -1e-02 | 0.197231 | 7.167e-03 / 7.148e-03 | 4.426e-03 / 4.391e-03 | 2.343e+00 | 1.555e-12 |
| -1e-03 | 0.062442 | 2.643e-03 / 2.629e-03 | 1.480e-03 / 1.470e-03 | 7.810e+00 | 1.520e-11 |
| -1e-04 | 0.019748 | 8.658e-04 / 8.673e-04 | 4.722e-04 / 4.693e-04 | 2.512e+01 | 1.249e-10 |
| -1e-05 | 0.006245 | 2.754e-04 / 2.760e-04 | 1.495e-04 / 1.487e-04 | 7.986e+01 | 1.670e-09 |
| -1e-06 | 0.001975 | 8.719e-05 / 8.736e-05 | 4.729e-05 / 4.702e-05 | 2.530e+02 | 1.182e-08 |
| -1e-07 | 0.000624 | 2.758e-05 / 2.763e-05 | 1.495e-05 / 1.487e-05 | 8.004e+02 | 1.321e-07 |
| +1e-01 | 0.632456 | 8.943e-03 / 8.995e-03 | 1.486e-02 / 1.488e-02 | 7.906e-01 | 1.509e-13 |
| +1e-02 | 0.197737 | 7.171e-03 / 7.082e-03 | 4.879e-03 / 4.869e-03 | 2.529e+00 | 2.203e-12 |
| +1e-03 | 0.062458 | 2.671e-03 / 2.678e-03 | 1.509e-03 / 1.501e-03 | 8.005e+00 | 1.388e-11 |
| +1e-04 | 0.019749 | 8.670e-04 / 8.690e-04 | 4.742e-04 / 4.716e-04 | 2.532e+01 | 1.698e-10 |
| +1e-05 | 0.006245 | 2.754e-04 / 2.760e-04 | 1.497e-04 / 1.488e-04 | 8.006e+01 | 1.692e-09 |
| +1e-06 | 0.001975 | 8.718e-05 / 8.735e-05 | 4.730e-05 / 4.703e-05 | 2.532e+02 | 1.187e-08 |
| +1e-07 | 0.000624 | 2.758e-05 / 2.763e-05 | 1.496e-05 / 1.487e-05 | 8.006e+02 | 1.332e-07 |

### Phase 1.98154

| Signed detuning | $|\gamma_0|$ | Lead reciprocal condition, coarse / fine | Center reciprocal condition, coarse / fine | $|G_0|$ | QP spectral-reference error |
|---|---|---|---|---|---|
| -1e-01 | 0.621537 | 1.204e-02 / 1.239e-02 | 7.526e-03 / 7.494e-03 | 6.274e-01 | 3.828e-14 |
| -1e-02 | 0.198824 | 6.791e-03 / 6.773e-03 | 4.359e-03 / 4.324e-03 | 2.323e+00 | 8.691e-13 |
| -1e-03 | 0.062945 | 2.483e-03 / 2.471e-03 | 1.453e-03 / 1.443e-03 | 7.746e+00 | 1.016e-11 |
| -1e-04 | 0.019907 | 8.132e-04 / 8.149e-04 | 4.634e-04 / 4.605e-04 | 2.492e+01 | 1.105e-10 |
| -1e-05 | 0.006295 | 2.587e-04 / 2.593e-04 | 1.467e-04 / 1.458e-04 | 7.922e+01 | 1.651e-09 |
| -1e-06 | 0.001991 | 8.188e-05 / 8.206e-05 | 4.639e-05 / 4.612e-05 | 2.510e+02 | 1.269e-08 |
| -1e-07 | 0.000630 | 2.590e-05 / 2.595e-05 | 1.467e-05 / 1.459e-05 | 7.940e+02 | 1.358e-07 |
| +1e-01 | 0.637423 | 8.200e-03 / 8.251e-03 | 1.440e-02 / 1.442e-02 | 7.844e-01 | 1.614e-13 |
| +1e-02 | 0.199326 | 6.693e-03 / 6.599e-03 | 4.780e-03 / 4.771e-03 | 2.508e+00 | 2.499e-12 |
| +1e-03 | 0.062961 | 2.509e-03 / 2.517e-03 | 1.480e-03 / 1.472e-03 | 7.941e+00 | 1.126e-11 |
| +1e-04 | 0.019908 | 8.145e-04 / 8.165e-04 | 4.652e-04 / 4.625e-04 | 2.512e+01 | 1.180e-10 |
| +1e-05 | 0.006295 | 2.587e-04 / 2.593e-04 | 1.468e-04 / 1.460e-04 | 7.942e+01 | 1.759e-09 |
| +1e-06 | 0.001991 | 8.188e-05 / 8.205e-05 | 4.640e-05 / 4.614e-05 | 2.512e+02 | 1.298e-08 |
| +1e-07 | 0.000630 | 2.590e-05 / 2.595e-05 | 1.467e-05 / 1.459e-05 | 7.942e+02 | 1.361e-07 |

Fine-grid power fits use five detunings on each side, $10^{-7}\le t\le10^{-3}$. They distinguish norm growth from loss of a finite singular value:

| $\beta$ | Cell | Side | Reciprocal-condition exponent | $\|A_{QP}\|_2$ exponent | $\sigma_{\min}(A_{QP})$ exponent | $|G_0|$ exponent |
|---|---|---|---|---|---|---|
| 1.95 | lead | below | 0.495373 | -0.503380 | 0.001004 | -0.502445 |
| 1.95 | lead | above | 0.497081 | -0.502064 | -0.000219 | -0.500012 |
| 1.95 | center | below | 0.498904 | -0.502649 | -0.002978 | -0.502445 |
| 1.95 | center | above | 0.500946 | -0.502163 | 0.000394 | -0.500012 |
| 1.98154 | lead | below | 0.495425 | -0.503520 | 0.001088 | -0.502465 |
| 1.98154 | lead | above | 0.497116 | -0.502026 | -0.000216 | -0.500011 |
| 1.98154 | center | below | 0.498998 | -0.502631 | -0.002810 | -0.502465 |
| 1.98154 | center | above | 0.500931 | -0.502179 | 0.000321 | -0.500011 |

At $\beta=1.98154$, $t=+10^{-7}$, the fine lead matrix has norm 3039.77 and smallest singular value 0.218115; the center has norm 5406.08 and smallest singular value 0.277264. This is an unbounded outgoing representation as the threshold is approached, rather than an observed finite matrix losing uniqueness through a vanishing smallest singular value. Full two-norm ratios, extractor and proxy norms, fits with grid differences and residuals are in [condition-exponents.csv](results/condition-exponents.csv), [green-exponents.csv](results/green-exponents.csv) and the scalar sample table.

### Shared Green error and evaluation controls

For the independent spectral value, sum nonzero Fourier orders through $|m|=60$ and add the stored analytic grazing term. Orders 60 and 80 give the same floating value at every sample. The absolute MFS-versus-spectral discrepancy grows approximately as $t^{-1}$: fitted exponents are −0.985/−0.981 at phase 1.95 and −1.031/−1.021 at phase 1.98154 (below/above), over $10^{-7}\le t\le10^{-3}$. This common error is distinct from the genuine $t^{-1/2}$ Green term.

At phase 1.98154 the backend controls use 128/64/64 and $M=6$. Both retain the same proxy least-squares coefficients. Tight FMM uses tolerance $10^{-14}$; direct evaluation sums the proxy sources with `kernel.h2d_directch`. The table shows the positive side; both signs are in [backend-controls.csv](results/backend-controls.csv).

| Detuning | Baseline Green error | Tight-FMM Green error | Direct Green error | Maximum tight/direct change in center $D$, Frobenius |
|---|---|---|---|---|
| 1e-04 | 1.180e-10 | 1.179e-10 | 1.180e-10 | 3.898e-12 |
| 1e-06 | 1.298e-08 | 1.298e-08 | 1.299e-08 | 3.669e-11 |
| 1e-07 | 1.361e-07 | 1.361e-07 | 1.361e-07 | 1.199e-10 |

At $+10^{-7}$ the Green discrepancy is about $1.36\times10^{-7}$, while changing the evaluator moves it by at most $4.1\times10^{-13}$. The dominant discrepancy is therefore in the shared MFS precomputation/representation, not the requested FMM evaluation tolerance. The unchanged proxy settings explain why changing density grids misses it. The negative-side control gives the same diagnosis. This assay identifies the shared numerical floor, without separating proxy discretization, rank truncation and least-squares roundoff.

## Chebyshev decay across Wood

At $\beta=1.98154$, use 66 Lobatto nodes, degree 65, on $[\beta-0.01,\beta+0.01]$. Odd degree avoids an exact midpoint node; the smallest sampled detuning is $2.4163745\times10^{-4}$. Each route uses fixed row/column scales computed at $k=\beta+0.005$ and fixed overlap anchors there. Determinants are evaluated by LU log modulus and phase, then divided by one fixed maximum modulus per sampled panel. Coefficients are normalized to the largest coefficient.

The three routes are:

- Original uneliminated amplitude border from `pole-free-v1`: dimensions 308 / 484 on coarse / fine grids. It retains the center Müller block and the amplitude extractors.
- Condensed amplitude border: dimensions 52 / 100, using the cell scattering matrices after center-density elimination.
- Condensed Cauchy border: dimensions 52 / 100, using the cell $D$ maps and Cauchy lead pencils above.

The second route isolates density elimination from the coordinate change. All Cauchy pencils had the expected stable count $K$. Overlap singular values stay above 0.994412 for amplitude frames and 0.999983 for Cauchy frames; maximum overlap conditions are 1.00562 and 1.000017.

| Grid | Route | Quantity | $|c_8|/c_{max}$ | $|c_{16}|/c_{max}$ | $|c_{32}|/c_{max}$ | $|c_{48}|/c_{max}$ | Maximum last-eight coefficient |
|---|---|---|---|---|---|---|---|
| 128/6 | original amplitude | determinant | 7.460e-03 | 1.273e-03 | 2.101e-04 | 5.945e-05 | 7.563e-05 |
| 128/6 | original amplitude | sigma_min | 1.212e-02 | 2.054e-03 | 3.378e-04 | 9.549e-05 | 3.358e-05 |
| 128/6 | condensed amplitude | determinant | 7.705e-05 | 6.366e-06 | 5.443e-07 | 1.133e-07 | 9.773e-08 |
| 128/6 | condensed amplitude | sigma_min | 1.209e-02 | 2.065e-03 | 3.407e-04 | 9.639e-05 | 3.390e-05 |
| 128/6 | condensed cauchy | determinant | 7.386e-11 | 7.373e-11 | 2.830e-11 | 3.060e-11 | 3.688e-10 |
| 128/6 | condensed cauchy | sigma_min | 3.154e-02 | 7.637e-03 | 1.715e-03 | 5.552e-04 | 2.025e-04 |
| 192/12 | original amplitude | determinant | 7.460e-03 | 1.273e-03 | 2.101e-04 | 5.945e-05 | 7.563e-05 |
| 192/12 | original amplitude | sigma_min | 1.200e-02 | 2.036e-03 | 3.351e-04 | 9.473e-05 | 3.331e-05 |
| 192/12 | condensed amplitude | determinant | 7.705e-05 | 6.366e-06 | 5.443e-07 | 1.133e-07 | 9.773e-08 |
| 192/12 | condensed amplitude | sigma_min | 1.209e-02 | 2.065e-03 | 3.407e-04 | 9.639e-05 | 3.390e-05 |
| 192/12 | condensed cauchy | determinant | 7.391e-11 | 7.380e-11 | 2.857e-11 | 3.056e-11 | 3.686e-10 |
| 192/12 | condensed cauchy | sigma_min | 3.154e-02 | 7.637e-03 | 1.715e-03 | 5.552e-04 | 2.025e-04 |

For the fine-grid determinant, fitting $\log|c_n|$ against $\log n$ on all orders 8–48 gives powers −2.550 (RMS log residual 0.0983) for the original amplitude border and −3.543 (0.0511) for the condensed amplitude border. Fits against $n$ have larger residuals, 0.2896 and 0.3991. Eliminating the Müller factor improves the tail but leaves the amplitude branch.

The Cauchy determinant coefficients at orders 1–6 are $1$, $1.216\times10^{-2}$, $1.315\times10^{-4}$, $1.468\times10^{-6}$, $1.529\times10^{-8}$, $1.068\times10^{-10}$. The geometric fit on orders 1–5 gives factor 0.01109 per order (RMS log residual 0.0365). From about order 7 onward the envelope fluctuates near $4\times10^{-10}$, consistent with the shared cell-evaluation floor.

The Cauchy $\sigma_{\min}$ coefficients instead have power −2.094 on even orders 8–32 (RMS log residual 0.0143). The local determinant diagnostic reaches $k\approx1.981542352$, detuning $2.352\times10^{-6}$, but stalls at unscaled $\sigma_{\min}\approx1.9\times10^{-8}$. Its saved updates do not establish a fully polished candidate. A simple real root produces a cusp in $\sigma_{\min}$; coordinate regularity does not make that scalar analytic. As a control, the squared Cauchy singular value has a last-eight coefficient maximum $2.02\times10^{-11}$ rather than $2.02\times10^{-4}$. Thus the singular-value part of prediction 4 fails, even while the Cauchy determinant improves sharply.

The two grid determinants have different dimensions and nonzero analytic factors, so their low-order coefficients are not direct estimates of discretization error. The complete coefficient sequences and fit orders are in [chebyshev-coefficients.csv](results/chebyshev-coefficients.csv) and [summary.json](results/summary.json). Raw values and chart diagnostics are in [chebyshev.json](output/run-003/chebyshev.json); the local diagnostic is in [cauchy-root.json](output/run-005/cauchy-root.json).

## First singular code step

The first **explicit division by $\gamma_m$** is `+bloch/farfield_extractors.m:109`, `g_scale = 1i ./ (2*sqrt(d)*gamma_m)`. At exact Wood this expression is undefined.

The earlier cell calculation already carries the singular outgoing Green term. `+kernel/precomp_proxy.m:64` forms the square root; lines 134 and 141 use it in the outgoing plane-wave derivative conditions; line 150 solves the augmented least-squares system. The analytic $m=0$ Fourier term above diverges, and the numerical proxy coefficients carry that dependence implicitly. `+op/construct_A_QP.m:79–101` assembles this Green data into the Müller matrix. In `+bloch/construct_S.m`, that assembly is at line 102, before extraction at line 120 and density solution at line 140. The measured $\|A_{QP}\|_2\sim t^{-1/2}$ is therefore present before the explicit extractor division. The rectangular proxy-system condition itself was not measured in this experiment.

## Checks

1. **Pass.** The copied pipeline at $\beta=0.5$, 128/64/64, $M=6$ returns 1.5584378941820891. Its difference from 1.558437894182088 is $1.11\times10^{-15}$, inside $2\times10^{-14}$. [Regression](output/run-001/regression.json).
2. **Pass.** Every detuning exponent has its range, point count, residual and maximum grid difference in the exponent tables. Per-detuning grid and same-$M$ density differences are in `point-errors.csv` and `samples.csv`. Chebyshev fits state their coefficient orders and residuals separately. The shared proxy error is assessed independently because it cancels from the density comparison.
3. **Pass.** Maximum Cauchy-to-amplitude round-trip defect at $t=0.1$ on either side, either phase and all three grids is $5.3331\times10^{-16}$, below $10^{-12}$. Maximum over the entire ladder is $5.4053\times10^{-16}$. This tests algebraic conversion consistency. An independent SciPy QZ comparison of the amplitude and Cauchy lead pencils gives matching counts 13, with maximum principal-angle sine $4.73\times10^{-15}$ at $t=0.1$ and $1.35\times10^{-12}$ at $t=10^{-7}$; see [pencil-checks.csv](results/pencil-checks.csv).

[checks.json](results/checks.json) records the numerical checks and resource limits. Exact Wood remains intentionally unsampled.

## Reproduction and resources

Use an empty output directory for each launch. From the repository directory, the following commands reproduce the final data with new output numbers. The launcher supplies package and FMM paths explicitly, copies the source used into each run's `inputs/`, and enforces five MATLAB/OpenMP threads, `OMP_DYNAMIC=FALSE`, 2 GiB peak process-tree RSS and 30/40 min soft/hard limits.

```sh
python3 -B test/bie-bound/wood-probe-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/wood-probe-v1/output/run-006 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode pilot
python3 -B test/bie-bound/wood-probe-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/wood-probe-v1/output/run-007 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode samples
python3 -B test/bie-bound/wood-probe-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/wood-probe-v1/output/run-008 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode chebyshev
python3 -B test/bie-bound/wood-probe-v1/launch.py --output /Users/whc/Documents/Work/dot-research/test/bie-bound/wood-probe-v1/output/run-009 --package-root /Users/whc/Documents/Work/dot-research --fmm /Users/whc/Documents/Work/dot-research/vendor/fmm2d/matlab --matlab /Applications/MATLAB_R2023b.app/bin/matlab --mode controls
env OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 conda run -n octave python -I test/bie-bound/wood-probe-v1/analyze.py --samples test/bie-bound/wood-probe-v1/output/run-004 --chebyshev test/bie-bound/wood-probe-v1/output/run-003 --controls test/bie-bound/wood-probe-v1/output/run-005 --output test/bie-bound/wood-probe-v1/results
env OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 conda run -n octave python -I test/bie-bound/wood-probe-v1/verify.py --experiment test/bie-bound/wood-probe-v1 --pilot test/bie-bound/wood-probe-v1/output/run-001 --samples test/bie-bound/wood-probe-v1/output/run-004 --chebyshev test/bie-bound/wood-probe-v1/output/run-003 --controls test/bie-bound/wood-probe-v1/output/run-005 --extra-run test/bie-bound/wood-probe-v1/output/run-002
```

The analysis and verification commands regenerate tables and checks from the explicitly named retained runs. For a fresh rerun substitute run-006/007/008/009 and omit `--extra-run`; that option includes the superseded sampling run in the retained cost ledger.

Forecasts were recorded before each launch: pilot 20–90 s / 1.1 GiB; full sampling 2–5 min / 1.3 GiB; Chebyshev 2–5 min / 1.3 GiB; corrected kernel-phase sampling 60–120 s / 1.1 GiB; backend/root controls 30–120 s / 1.1 GiB.

| Run | Work | Monitored seconds | Peak process-tree RSS (GiB) |
|---|---|---|---|
| 001 | Regression and pilot cells | 21.22 | 0.758 |
| 002 | Initial sampling; kernel-term phase comparison superseded | 76.28 | 0.811 |
| 003 | Three-route Chebyshev sampling | 100.15 | 0.832 |
| 004 | Sampling with consistent Green source/target phase | 80.26 | 0.749 |
| 005 | Direct/tight-FMM controls and local Cauchy diagnostic | 47.95 | 1.527 |

Final detuning tables use run-004. Run-002 is retained because its analytic grazing term originally used the opposite separation phase from its QP value; its cell maps are unaffected. Total monitored time is 325.86 s, peak RSS 1.527 GiB. No field MAT files are written. Times are resource records under possible concurrent machine use and support no cost comparison.

## What a Wood-robust solver must change

The cell construction and the port coordinates both need attention. Use regular wall Cauchy or Robin data, or the $\cos(\gamma x)$ and $\sin(\gamma x)/\gamma$ basis, for matching through the threshold. Before the density solve, remove or explicitly augment the grazing outgoing Green contribution so that the proxy/Müller representation stays bounded and its numerical error can be monitored independently of density refinement. A finite-cell map assembled directly in regular wall variables is another construction to test. Merely replacing the extractor's division leaves the observed $1/|\gamma_0|$ Müller norm growth and shared proxy error. Determinant interpolation should use the smooth coordinate formulation; singular values remain useful for acceptance, with their zero cusp accounted for. This experiment implements the diagnostic conversions, not a Wood-safe replacement cell solver.
