# I5.1j independent review: real-interpolation lifting bridge

## Verdict

- Theorem: **PASS WITH CONDITIONS**.
- Implementation: **PASS**.
- Frozen numerical instance: **PASS WITH CONDITIONS** as a finite analytic
  ideal majorant, but **STOP** for tightness.
- Complete reliability/certification: **STOP** because
  $\Delta_{\mathrm{sf}}$ and $\Delta_{\mathrm{fp}}$ remain unresolved.

The governing run is v8 `output/attempt-1/run-04`.  Its result is not an
outward-rounded or fully certified residual bound.

## Theorem and ownership audit

The review confirms the RI direct ME-13 bridge, the Hermitian Gram formulas,
the squared interpolation remainders, and the factor-one global product
Cauchy--Schwarz step.  The implementation checks pairwise disjoint material and
wall collars (including cell and transverse copies), zero comparison rims, the
complete three-interface list, and the broken-energy direct sum before it adds
material and wall lifting energies in squares.

The complete signed value row is formed as local plus regular-image plus
off-surface before applying state maps.  The identity occurs once.  The base
row is pre-$G$: finite side states use $G_\pm P_\pm^n c_\pm$ once, and the cell
tail uses $G_\pm^*HG_\pm$ and $\mathcal R\lVert G_\pm\rVert_2$ once.  The
scientific artifact, curve and inherited wall/material-normal constants are
content- and geometry-bound.  The runtime reads no historical result.

The active material value path has two FFT calls only to recover the frozen
density's source coefficients.  It has zero material target FFT/DFT calls and
no material Fourier cutoff or high-mode tail.  Source selection uses no
centres and no inter-level drift.  The selected $N$ is used directly as the
real interpolation partition; $q=1$ uses the complete whole-action derivative
upper rather than a target Fourier or quadrature selector.

## Run record

Runs 01--03 were operational/debugging failures in the same attempt and
created no scientific input or result:

1. run-01 exposed an unnamed final builder gate;
2. run-02 identified `bridge_RI_5_16`;
3. run-03 identified the bitwise Hermitian Gram gate.

Before run-04 the mathematically Hermitian $Q_0,Q_1$ were explicitly
symmetrized.  This is neutral in exact arithmetic; its ordinary floating-point
effect remains owned by unresolved $\Delta_{\mathrm{fp}}$.

Run-04 completed with exit status zero.  The selector chose
$N=514$ and node radius
$6.0278441945300462\,10^{-6}$; its analytic and tightness gates passed, all
candidate centres were absent, and inter-level drift was zero.  The builder's
29 required-true gates and evaluator's 17 required-true gates passed.  Solve
counts were all zero.

The component derivative bounds were

$$
L_{\mathrm{local}}=530.70702734127553,
\quad L_{\mathrm{regular}}=1071.7879642715245,
\quad L_{\mathrm{off}}=21.751728992491312,
$$

so $L_A=1624.2467206052913$.  With derivative centre $d_j=0$, the
interpolant chord derivatives are only about $10^{-12}$ but every
$\sigma_j$ is about $L_A$.  Here $R_0,R_1$ denote the squared error integrals
stored as `R0_squared` and `R1_squared`.  Consequently

$$
R_0=2.642100809251934,
\qquad
R_1=3315231.5072913063,
\qquad
\mathcal R=744.24301691330515.
$$

The final energy decomposition is

$$
E_{\mathrm{mat,fin}}=1609125.8284670974,
\quad
E_{\mathrm{mat,cell}}=6.0667993516236794\,10^{-10},
\quad
E_{\mathrm{wall}}=5.9767862107677079\,10^{-30}.
$$

Thus

$$
\widehat B_{\mathrm{lift}}^{\mathrm{ideal}}
=1268.5132354323696,
\qquad
\mathcal M_{\mathrm{ideal}}=1268.5132360299708.
$$

Run-04 used 15.01 seconds of wall time by `/usr/bin/time`, with maximum RSS
964214784 bytes.  The process-tree watchdog recorded 17 seconds and 1076960
KiB.  Both are within the run contract.

## Findings and next obligation

The large number is not explained by a Fourier tail, cell tail, wall term, or
double counting.  It is the unavoidable output of the current zero-centred
global first-derivative ball.  Increasing $N$ will not materially reduce
$R_1$ and is not a useful next step.

The shortest potentially useful continuation is a complete signed nonzero
derivative-centre/panel-ball producer.  It must combine local, regular-image
and off-surface derivatives before taking norms and must retain explicit
source, Ewald and evaluation radii.  Until that object exists, v8 should stop
at this finite but very wide conditional majorant.
