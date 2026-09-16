# I5.1j real-variable material value-jump lifting design

## Scope, authority, and output

I5.1j implements (RI-1)--(RI-19) in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-real-interpolation]].
It replaces only the material value-jump Fourier evaluation in the lifting
module.  It does not change the frozen reconstruction, material-normal or
wall-normal residuals, propagation matrices, minimum-energy jump convention,
or artificial-wall Rayleigh evaluation.  The governing output is

$$
\boxed{
\mathcal M_{\mathrm{RI,ideal}}
=B_{\Gamma_\pm}+B_\Upsilon
+\left(
E_{\mathrm{mat,fin}}^{\mathrm{RI}}
+E_{\mathrm{mat,cell}}^{\mathrm{RI}}
+E_{\mathrm{wall}}
\right)^{1/2}.}
\tag{I5.1j-1}
$$

The corresponding conditional statement is

$$
\|R\|_{\mu,*}
\le
\mathcal M_{\mathrm{RI,ideal}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}.
\tag{I5.1j-2}
$$

Both deltas remain `UNRESOLVED`.  The instance label is therefore
`CONDITIONAL_IDEAL_MAJORANT_COMPLETE_SF_FP_UNRESOLVED`.  No material
value-jump Fourier coefficient, $L_0$, $L_1$, material Fourier tail, material
target DFT, or material target FFT is a runtime object.  Artificial-wall
Rayleigh modes remain the sole Fourier-mode exception.

The method is shape general for one closed, simple
$C_{\mathrm{per}}^{p+2}$ chart.  A circle adapter may generate the current
frozen geometry inputs, but no circular Fourier--Bessel diagonalization or
finite-support self-action is part of this design.

## Owner ledger

| owner | center | analytic radius or tail | forbidden overlap |
|---|---|---|---|
| identity | frozen value identity row | its exact row-evaluation enclosure | never repeated in regular/off rows |
| local | diagonal-safe Kress value action | source product-rule and kernel-series remainders | no target DFT or material high-mode tail |
| regular image | retained exact-QP Ewald action | M-R/M-I/M-T/M-L and finite evaluation remainders | no off-surface action |
| off surface | finite wall-to-boundary Rayleigh action | off-surface and finite evaluation remainder | no regular-image term |
| real target value | continuous piecewise-linear complete-row center | $R_0$ in (I5.1j-8) | applied after the physical row is combined |
| real target derivative | derivative of the same piecewise-linear center | $R_1$ in (I5.1j-8) | no independent derivative center in $Q_1$ |
| cell propagation | none | one block-power tail per side | never applied inside a row and again outside it |
| artificial wall | existing wall Rayleigh centers | existing wall high/cell tails | unchanged from (ME-21)--(ME-30) |

## Frozen inputs and generated certificates

The evaluator reads the existing frozen candidate, density coefficients, QZ
state maps, propagation matrices, starting states, Rayleigh data, material
parameters, and reconstruction signs.  It does not solve for any of them.
The following new certificate data are generated from the authoritative
geometry and frozen density representation:

1. perimeter, arclength map, speed lower bound, chord--arc bound, reach,
   curvature and component/wall/periodic-copy clearances;
2. one selected even $N>2M_\eta$ and the periodic arclength partition
   $0=s_0<\cdots<s_N=P$ generated from those same nodes;
3. complete signed endpoint row balls $(c_j,r_j)$ and complete signed
   first-arclength-derivative panel balls with $d_j=0$ and $r'_j$ equal to a
   complete exact-action derivative upper;
4. the real-interpolation matrices and scalars
   $Q_0,Q_1,R_0,R_1,H,\mathcal R$;
5. the existing block-power constants and the unchanged wall lifting energy.

The periodic seam is stored once and reused: $c_N=c_0$.
Every row radius is an operator/row $2$-norm enclosure in the complete frozen
state space, not an entrywise or sampled maximum.

## Complete physical row producer

For every endpoint and derivative panel, first form

$$
A=A^{\mathrm{id}}+A^{\mathrm{loc}}
+A^{\mathrm{reg}}+A^{\mathrm{off}}
\tag{I5.1j-3}
$$

with the physical value-jump signs.  Sum centers with those signs; add
analytic radii.  The source density coordinates, source Jacobian, and normal
are included in each component row.  The current adapter returns this base
pre-$G_\varsigma$ row and applies $G_\varsigma$ once during finite/cell
assembly.

The component producers must provide:

1. diagonal-safe Kress zeroth and first target derivatives, with complete
   source quadrature and kernel-series remainders;
2. regular-image coordinate derivatives through total order two, including
   every retained Ewald term and M-R/M-I/M-T/M-L tail;
3. the first target arclength derivative of the finite off-surface Rayleigh
   action and its remainder;
4. the identity row and its first arclength derivative exactly once.

For a non-arclength chart use
$\partial_s=|z'|^{-1}\partial_t$ with the certified positive speed lower
bound.  One sufficient local source interface is

$$
S_{j,p}^{(q)}
\ge
\sup_{t\text{ in target panel}}
\int_0^{2\pi}
\left|
\partial_u^p(\partial_t+\partial_u)^q
K_j^{\mathrm{val}}(t,u)
\right|\,du,
\qquad q\in\{0,1\}.
\tag{I5.1j-4}
$$

The current $p=4$ real-variable source theorem is sufficient.  A sampled
maximum, panel-to-panel drift, or finite-difference derivative is not an
enclosure.

The current adapter uses the specialization

$$
d_j=0,
\qquad
r'_j\ge\sup_{s\in[s_j,s_{j+1}]}
\|A'(s)\|_{\mathrm{op}}.
\tag{I5.1j-4a}
$$

The bound $r'_j$ is assembled from the complete exact-action derivative of
(I5.1j-3).  It is an analytic admissibility gate evaluated only after $N$ is
selected; it is not an $N$-selector and no derivative center is computed.

## Real-interpolation assembly

For $h_j=s_{j+1}-s_j$, compute

$$
b_j=\frac{c_{j+1}-c_j}{h_j},
\qquad
L_j=\|d_j\|_2+r'_j,
\qquad
\eta_j=\|d_j-b_j\|_2+r'_j.
\tag{I5.1j-5}
$$

The derivative center in the finite-element Gram matrix is $b_j$, not
$d_j$.  For $0\le\theta\le1$ define

$$
\rho_j(\theta)
=(1-\theta)r_j+\theta r_{j+1}
+2h_j\theta(1-\theta)L_j.
\tag{I5.1j-6}
$$

Assemble the Hermitian state matrices

$$
Q_0
=\sum_jh_j\left[
\frac{c_j^*c_j+c_{j+1}^*c_{j+1}}3
+\frac{c_j^*c_{j+1}+c_{j+1}^*c_j}{6}
\right],
\qquad
Q_1=\sum_jh_jb_j^*b_j,
\tag{I5.1j-7}
$$

and squared error scalars

$$
\begin{aligned}
R_0
&=\sum_j\left[
\frac{h_j}{3}(r_j^2+r_jr_{j+1}+r_{j+1}^2)
+\frac{h_j^2L_j}{3}(r_j+r_{j+1})
+\frac{2h_j^3L_j^2}{15}\right],\\
R_1&=\sum_jh_j\eta_j^2.
\end{aligned}
\tag{I5.1j-8}
$$

The coefficients in (I5.1j-7)--(I5.1j-8) are exact polynomial integrals,
not quadrature rules.

From the existing collar certificate read $W_0,W_1$ in (ME-13)--(ME-14).
Freeze one positive inverse-length input $\alpha$ before evaluating row
centers.  The current frozen instance uses $\alpha=\sqrt{\mu}$, implemented
as `sqrt(mu_shift)`.  A different explicitly stored positive shift is
admissible in a later instance, but it must not be selected by comparing
computed row centers.  Set

$$
a_0=W_0+\frac{W_1\alpha}{2},
\qquad
a_1=\frac{W_1}{2\alpha},
\tag{I5.1j-9}
$$

$$
H=a_0Q_0+a_1Q_1,
\qquad
\mathcal R=\sqrt{a_0R_0+a_1R_1},
\qquad
\Phi(x)=\sqrt{x^*Hx}+\mathcal R\|x\|_2.
\tag{I5.1j-10}
$$

Equations (I5.1j-9)--(I5.1j-10), not the optional ME-15a norm comparison,
are the governing estimator.

## Finite and propagated states

The current adapter returns the base density-coordinate row before the
frozen density-to-state map $G_\varsigma$.  It therefore uses

$$
x_{\varsigma,n}=G_\varsigma P_\varsigma^nc_\varsigma
\tag{I5.1j-11}
$$

in every finite term and no later $G_\varsigma$ factor is permitted.  For
the block tail, transform the base-row certificate once by

$$
H\longmapsto G_\varsigma^*HG_\varsigma,
\qquad
\mathcal R\longmapsto\mathcal R\|G_\varsigma\|_2.
\tag{I5.1j-12}
$$

If a future helper instead certifies a precomposed row, it omits this
transformation.  It may not apply $G_\varsigma$ both inside and outside the
row.

For the current convention, write

$$
\Phi_{\Lambda}^{\mathrm{base}}(y)
=\sqrt{y^*H_{\Lambda}^{\mathrm{base}}y}
+\mathcal R_{\Lambda}^{\mathrm{base}}\|y\|_2.
$$

For the finite singleton set $\mathscr S_\Lambda$ and the two propagated
sides,

$$
E_{\mathrm{mat,fin}}^{\mathrm{RI}}
=\sum_\Lambda\left[
\sum_{r\in\mathscr S_\Lambda}\Phi_{\Lambda,r}(x_{\Lambda,r})^2
+\sum_{\varsigma\in\{-,+\}}
\sum_{n=0}^{J_{\mathrm{cell}}-1}
\Phi_{\Lambda}^{\mathrm{base}}
(G_\varsigma P_\varsigma^nc_\varsigma)^2
\right].
\tag{I5.1j-13}
$$

If

$$
\sum_{n\ge J_{\mathrm{cell}}}
\|P_\varsigma^nc_\varsigma\|_2^2
\le
K_\varsigma
\|P_\varsigma^{J_{\mathrm{cell}}}c_\varsigma\|_2^2,
$$

then the single cell-tail owner is

$$
E_{\mathrm{mat,cell}}^{\mathrm{RI}}
=\sum_{\Lambda,\varsigma}
\left(\sqrt{\|H_{\Lambda,\varsigma}\|_2}
+\mathcal R_{\Lambda,\varsigma}\right)^2
K_\varsigma
\|P_\varsigma^{J_{\mathrm{cell}}}c_\varsigma\|_2^2.
\tag{I5.1j-14}
$$

Read $E_{\mathrm{wall}}$ without alteration from the paired physical wall
jumps and Rayleigh retained/high/cell owners in (ME-21)--(ME-30).  The
pairwise-disjoint comparison supports make the three energies in
(I5.1j-1) add in squares.  The factor-one product Cauchy--Schwarz inequality
is applied only after this one global simultaneous comparison correction is
formed.

## Selection and stopping

Before a run, freeze:

1. one even schedule $\mathcal N$, every member of which satisfies
   $N>2M_\eta$;
2. one strict allocation for the complete zeroth-order node source,
   kernel-series, and Ewald analytic radius;
3. $\alpha=\sqrt{\mu}$, $J_{\mathrm{cell}}$, block size, and memory limit.

For each $N\in\mathcal N$, the preselector computes no center.  It evaluates
only

$$
\epsilon_N^{(0),\mathrm{sel}}
=\epsilon_N^{\mathrm{source},0}
+\epsilon_N^{\mathrm{series},0}
+\epsilon_N^{\mathrm{Ewald},0},
\tag{I5.1j-15}
$$

together with the candidate-independent analytic admissibility gates.  It
selects the first strict radius-pass $N$.  This same $N$ is then both the
source-rule size and the number of material interpolation panels.  There is
no independent target-panel schedule, material target DFT, or material target
FFT.

Only after selection does the evaluator form the complete signed centers,
the $d_j=0$ derivative uppers in (I5.1j-4a), and the matrices/scalars in
(I5.1j-7)--(I5.1j-10).  A failed or nonfinite derivative upper is an analytic
failure and returns `STOP_NO_MAJORANT`.  Finite $R_0,R_1$, cell-tail and
tightness values enter the reported majorant or diagnostics, but failure of
their preassigned *performance* thresholds does not invalidate the finite
conditional majorant; it sets a route-upgrade flag.  No center, complete
$B_{\mathrm{lift}}$, $R$ value, cell-tail value, or inter-level drift feeds
back into selection.

If no $N$ passes (I5.1j-15), or if a preselection analytic admissibility gate
fails for every candidate, return `STOP_NO_MAJORANT`.  Never substitute
neighboring-grid agreement for a failed remainder.

## Streaming algorithm and resources

Process target panels and source nodes in blocks.  Prefer rank updates of
$Q_0,Q_1,R_0,R_1$ while retaining only the endpoint and panel balls needed by
(I5.1j-5).  For the selected partition, the current small-$N$ adapter may
persist one combined $N\times m$ physical center matrix.  It must not retain
separate dense local, regular-image, and off-surface center matrices at the
same time.  No code path calls a target DFT or FFT for the material value
jump.

For state dimension $m$, selected size $N$, and block size $b$, the intended
work and memory are

$$
O(N^2m),
\qquad
O(m^2+Nm+bN+bm).
\tag{I5.1j-16}
$$

For the current $m=194$, a preliminary plan with
$N\le4096$ and $b\le16$ is expected to remain below $1$ GiB and complete in
minutes.  This is a pre-run estimate, not a measured result.  A future
experiment must still record its own plan, watchdog, elapsed time, and peak
memory under `test/AGENTS.md`.

## Fail-closed gates and persisted output

Persist and require:

1. the broken energy-square-summable Hilbert direct-sum gate, zero outer-rim
   traces, and pairwise disjointness of every material and artificial-wall
   collar;
2. complete geometry, collar, arclength-map, partition-cover, positive-panel,
   periodic-seam, and $N>2M_\eta$ gates;
3. complete signed row centers and row/operator $2$-norm radii for every
   endpoint and first-derivative panel;
4. local diagonal cancellation and the $q=0$ source remainder, the complete
   $q=1$ whole-action derivative upper, regular-image coordinate-order-two
   Ewald gates, off-surface derivative gates, and one identity owner;
5. automatic direct-field equality binding of every reused module to the
   current frozen artifact, curve parametrization and orientation, material
   parameters, and collar scientific identity; no free user Boolean may
   substitute for this binding;
6. finite nonnegative radii and Hermitian positive-semidefinite enclosures for
   $Q_0,Q_1,H$;
7. exact state-map ownership, block-power certificates, paired wall owners,
   and the factor-one global assembly;
8. explicit zero counts for material Fourier coefficients, material cutoffs,
   material Fourier tails, material target DFT calls, and material target FFT
   calls;
9. zero guided-mode, density, QZ, propagation-matrix, and Rayleigh solves;
10. the unresolved special-function and floating-point labels in
   (I5.1j-2).

The report must separate centers, local/regular/off/source/interpolation
radii, propagated cell energy, and unchanged wall energy.  Ordinary
floating-point outputs are `NON_CERTIFIED_ROUNDOFF_EXCLUDED`; they are not a
certified enclosure.

## Current gate

The theorem and design received independent `PASS WITH CONDITIONS / GO`.
The reviewed frozen run 04 selects $N=514$ and reports

$$
\begin{gathered}
\epsilon_N^{(0),\mathrm{sel}}=6.0278441945300462\,10^{-6},
\quad L_{\mathrm{total}}=1624.2467206052913,\\
R_0=2.642100809251934,
\quad R_1=3315231.5072913063,
\quad \mathcal R=744.24301691330515,\\
E_{\mathrm{mat,fin}}^{\mathrm{RI}}=1609125.8284670974,
\quad E_{\mathrm{mat,cell}}^{\mathrm{RI}}
=6.0667993516236794\,10^{-10},\\
E_{\mathrm{wall}}=5.9767862107677079\,10^{-30},
\quad B_{\mathrm{lift}}^{\mathrm{RI}}=1268.5132354323696,\\
\mathcal M_{\mathrm{RI,ideal}}=1268.5132360299708.
\end{gathered}
\tag{I5.1j-17}
$$

Here $L_{\mathrm{total}}$ is the complete exact-action derivative upper in
(I5.1j-4a), not a sampled maximum.

This is a `PASS WITH CONDITIONS` conditional ideal majorant and a tightness
`STOP`.  It is not fully reliable because $\Delta_{\mathrm{sf}}$ and
$\Delta_{\mathrm{fp}}$ remain unresolved.  No material Fourier tail or target
FFT enters the result.  The dominant term is the global first-derivative
radius created by $d_j=0$; increasing $N$ is not the recommended next route.
The shortest repair is a nonzero signed derivative center with complete
panel balls, leaving the selector and owner ledger unchanged.
