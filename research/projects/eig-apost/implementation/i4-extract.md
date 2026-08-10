# I4 spectral extraction closure

- Date: 2026-08-09
- Stage: I4 Full Analytic Complex-$k$ Root-readiness
- Model: square cell, centered sharp disk, $d=L=1$, $\beta=0.5$
- Canonical point: $R=0.2$, $\delta=0.3$, $k=1.8603695988$
- Package-source changes: none
- Historical modal-integral evidence: `test/i4-extract/output/canonical/`
- Three-path value evidence: `test/i4-three-path/output/qualification/` and
  `test/i4-three-path/output/canonical/`

## Interpretation correction

The Bessel closed-form calculation, direct angular quadrature, and package
`farfield_extractors` path all use a Rayleigh mode as the boundary integration
kernel.  Their agreement checks the same modal integral by different algebra
and quadrature; it does not independently establish the qpgreen Rayleigh
representation, justify expanding before boundary integration, or identify the
Fourier coefficients of a full BIE wall field.  The conditional proposition
below remains a valid statement once the spectral Green formula is assumed,
but the old Bessel--extractor numerical agreement is no longer described as an
independent spectral-representation closure.

## Question being resolved

The far-field extractor starts from the spectral representation in draft
equation (16), differentiates it with respect to the source normal, and
integrates the resulting modal coefficient over the inclusion boundary. The
missing mathematical step is whether the infinite Rayleigh series may be
integrated term by term, and whether the same is true after taking the wall
$x$-derivative needed for the Cauchy trace.

This question is separate from the numerical choice of the retained order
$M$, the boundary trapezoidal rule, and the accuracy of the augmented-MFS
evaluation used by the direct-wall comparison.

## Proposition: separated-wall spectral extraction

Let $\Gamma$ be a finite-length rectifiable closed curve with a fixed bounded
measurable representative of its almost-everywhere defined unit normal
$\nu=(\nu_x,\nu_y)$. Let
$X_{\mathrm L}<X_{\mathrm R}$ and suppose that, for some $\delta>0$,

$$
x_s-X_{\mathrm L}\geq\delta,
\qquad
X_{\mathrm R}-x_s\geq\delta,
\qquad s=(x_s,y_s)\in\Gamma.
$$

Fix $d>0$ and real $k,\beta$. Define

$$
\beta_m=\beta+\frac{2\pi m}{d},
\qquad
\gamma_m^2=k^2-\beta_m^2,
\qquad m\in\mathbb Z,
$$

using the outgoing branch, and assume $\gamma_m\neq0$ for every $m$. Suppose
$\sigma,\tau\in L^1(\Gamma)$. Conditional on the spectral Green formula

$$
G_{\mathrm{QP}}^{(k)}(x,y;x_s,y_s)
=\frac{\mathrm{i}}{2d}
\sum_{m\in\mathbb Z}
\frac{e^{\mathrm{i}\beta_m(y-y_s)}
e^{\mathrm{i}\gamma_m|x-x_s|}}{\gamma_m},
$$

the following statements hold.

1. On either wall, the series for $G_{\mathrm{QP}}^{(k)}$, its source-normal
   derivative, its target $x$-derivative, and the mixed derivative
   $\partial_x\partial_{\nu_s}G_{\mathrm{QP}}^{(k)}$ converge absolutely and
   uniformly for $y\in[0,d]$ and almost every $s\in\Gamma$.
2. The series may be integrated term by term against $\sigma$ or $\tau$.
   The wall $x$-derivative may also be interchanged with the series and the
   boundary integral.
3. With

   $$
   \psi_m(y)=\frac{1}{\sqrt d}e^{\mathrm{i}\beta_my},
   $$

   the single-layer coefficient on either wall is

   $$
   a_{m,w}^{\mathcal S}
   =\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
   \int_\Gamma \Phi_m^w(s)\sigma(s)\,\mathrm{d}s,
   $$

   where

   $$
   \Phi_m^{\mathrm L}(s)
   =e^{-\mathrm{i}\beta_my_s
   +\mathrm{i}\gamma_m(x_s-X_{\mathrm L})},
   \qquad
   \Phi_m^{\mathrm R}(s)
   =e^{-\mathrm{i}\beta_my_s
   -\mathrm{i}\gamma_m(x_s-X_{\mathrm R})}.
   $$

   The double-layer coefficients are

   $$
   a_{m,\mathrm L}^{\mathcal D}
   =\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
   \int_\Gamma
   \mathrm{i}(\gamma_m\nu_x-\beta_m\nu_y)
   \Phi_m^{\mathrm L}(s)\tau(s)\,\mathrm{d}s,
   $$

   $$
   a_{m,\mathrm R}^{\mathcal D}
   =\frac{\mathrm{i}}{2\sqrt d\,\gamma_m}
   \int_\Gamma
   -\mathrm{i}(\gamma_m\nu_x+\beta_m\nu_y)
   \Phi_m^{\mathrm R}(s)\tau(s)\,\mathrm{d}s.
   $$

These are exactly the scattered-field rows assembled by
`bloch.farfield_extractors`. The package convention
$\eta=[\tau; -\sigma]$ and the matrix row `[dgdn,-g]` give
$\mathcal D[\tau]+\mathcal S[\sigma]$.

### Proof

For all sufficiently large $|m|$, the mode is evanescent and

$$
\gamma_m=\mathrm{i}\alpha_m,
\qquad
\alpha_m=\sqrt{\beta_m^2-k^2}.
$$

There are positive constants $c_1,c_2$ and an integer $m_0$, depending only
on $d,k,\beta$, such that

$$
c_1|m|\leq\alpha_m\leq c_2|m|,
\qquad |m|\geq m_0.
$$

On the left wall, $x_s-X_{\mathrm L}\geq\delta$; on the right wall,
$X_{\mathrm R}-x_s\geq\delta$. Hence on either wall

$$
|\Phi_m^w(s)|\leq e^{-\alpha_m\delta}.
$$

The $m$th Green term therefore has a uniform bound of the form

$$
C|m|^{-1}e^{-c_1\delta|m|}.
$$

Taking the source-normal derivative multiplies the term by one of
$\mathrm{i}(\gamma_m\nu_x-\beta_m\nu_y)$ and
$-\mathrm{i}(\gamma_m\nu_x+\beta_m\nu_y)$. Since
$|\gamma_m|$ and $|\beta_m|$ are both of order $|m|$, the factor cancels
the $1/|\gamma_m|$ prefactor and gives the bound

$$
Ce^{-c_1\delta|m|}.
$$

The target $x$-derivative has the same bound. More precisely, the positive
clearance leaves an open strip of width smaller than $\delta/2$ around each
wall and an open horizontal neighborhood of the source curve that remain
separated by at least $\delta/2$. The same estimates hold on these
neighborhoods after replacing $\delta$ by $\delta/2$. The mixed derivative
contains both source and target factors and has the bound

$$
C|m|e^{-c_1\delta|m|}.
$$

All four scalar majorants are summable. The finitely many modes with
$|m|<m_0$ are finite because the parameter is not at a Wood anomaly. The
Weierstrass test proves absolute uniform convergence of the four series.

For any of the four modal kernels $K_m$ and either density $\rho=\sigma$ or
$\rho=\tau$,

$$
\sum_m\int_\Gamma |K_m(s)\rho(s)|\,\mathrm{d}s
\leq
\|\rho\|_{L^1(\Gamma)}
\sum_m\mathop{\mathrm{ess\,sup}}_{s\in\Gamma}|K_m(s)|<\infty.
$$

Tonelli's theorem therefore permits the sum and the boundary integral to be
interchanged. On the open wall strips just described, the original series
converges at every point and the target-$x$ derivative series converges
uniformly. The standard term-by-term differentiation criterion therefore
identifies the derivative of the summed field with the sum of the modal
derivatives; Tonelli then also interchanges that derivative series with the
boundary integral. Finally, writing
$e^{\mathrm{i}\beta_my}=\sqrt d\,\psi_m(y)$ gives the displayed single- and
double-layer coefficients. This proves all three statements.

## Quantitative tails

Let $m_0$ be large enough that every mode with $|m|\geq m_0$ is evanescent.
For every such mode,

$$
|a_{m,w}^{\mathcal S}|
\leq
\frac{\|\sigma\|_{L^1(\Gamma)}}
{2\sqrt d\,|\gamma_m|}e^{-\alpha_m\delta},
$$

$$
|a_{m,w}^{\mathcal D}|
\leq
\frac{\|\tau\|_{L^1(\Gamma)}}{2\sqrt d}
\left(1+\frac{|\beta_m|}{|\gamma_m|}\right)
e^{-\alpha_m\delta}.
$$

If $b_{m,w}$ denotes the coefficient of the wall $x$-derivative, then

$$
b_{m,\mathrm L}=-\mathrm{i}\gamma_ma_{m,\mathrm L},
\qquad
b_{m,\mathrm R}=+\mathrm{i}\gamma_ma_{m,\mathrm R},
$$

and consequently

$$
|b_{m,w}^{\mathcal S}|
\leq
\frac{\|\sigma\|_{L^1(\Gamma)}}{2\sqrt d}
e^{-\alpha_m\delta},
$$

$$
|b_{m,w}^{\mathcal D}|
\leq
\frac{\|\tau\|_{L^1(\Gamma)}}{2\sqrt d}
(|\gamma_m|+|\beta_m|)e^{-\alpha_m\delta}.
$$

Let $\langle\beta_m\rangle=\sqrt{1+|\beta_m|^2}$. For $M\geq m_0$, the
weighted Cauchy tails obey the computable bounds

$$
(T_M^{\mathcal S})^2
\leq
\frac{\|\sigma\|_{L^1(\Gamma)}^2}{4d}
\sum_{|m|>M}e^{-2\alpha_m\delta}
\left(
\frac{\langle\beta_m\rangle}{|\gamma_m|^2}
+\frac{1}{\langle\beta_m\rangle}
\right),
$$

$$
(T_M^{\mathcal D})^2
\leq
\frac{\|\tau\|_{L^1(\Gamma)}^2}{4d}
\sum_{|m|>M}e^{-2\alpha_m\delta}
\left[
\langle\beta_m\rangle
\left(1+\frac{|\beta_m|}{|\gamma_m|}\right)^2
+\frac{(|\gamma_m|+|\beta_m|)^2}
{\langle\beta_m\rangle}
\right].
$$

Asymptotically, with $q=2\pi\delta/d$, the tail shapes are:

| Layer | wall coefficient | $x$-derivative coefficient | weighted Cauchy tail |
|---|---|---|---|
| $\mathcal S$ | $|m|^{-1}e^{-q|m|}$ | $e^{-q|m|}$ | $M^{-1/2}e^{-qM}$ |
| $\mathcal D$ | $e^{-q|m|}$ | $|m|e^{-q|m|}$ | $M^{1/2}e^{-qM}$ |

This is a worst-case envelope for a fixed $L^1$ density. It is not an
$M_{\mathrm{trace}}$ theorem for the solved BIE response. The physical BIE
density can have additional regularity or cancellation, and it changes with
the incident channel, frequency, resolution, and conditioning.

For scale only, ignoring constants and polynomial factors, the equation
$e^{-2\pi\delta M/d}=10^{-8}$ gives approximately $M=10,15,30$ for
$\delta=0.3,0.2,0.1$ when $d=1$. Thus a worst-case estimate of several tens
at small clearance is compatible with an observed physical-response tail
crossing at a smaller order.

## What changing $M$ does

For a fixed density and a fixed branch, each output order is computed by a
separate boundary integral. Increasing $M$ only appends output rows. It does
not approximate an existing low-order coefficient by a longer partial sum.
Therefore retained low-order coefficients must be unchanged when $M$ grows.
Any retained-row change indicates branch drift, a recomputed density, or an
implementation inconsistency.

The order $M$ in `bloch.farfield_extractors` is also different from the
plane-wave order `M_pw` inside the augmented-MFS Green evaluator. The former
selects artificial-wall trace coefficients; the latter is part of the proxy
construction used for the near-field Green representation.

## Complex-$k$ disk

Let $\mathcal K\subset\mathbb C$ be a compact disk. The same argument is
uniform on $\mathcal K$ if there is a common simply connected open set
$U\supset\mathcal K$ such that:

1. $U$ contains no point $k=\pm\beta_m$;
2. every $\gamma_m(k)$ uses the analytic square-root branch continued from
   the real anchor to $U$ along a path avoiding all such branch points;
3. for all sufficiently large $|m|$ and every $k\in\mathcal K$,

   $$
   \operatorname{Im}\gamma_m(k)\geq c_{\mathcal K}|\beta_m|,
   \qquad
   c_1|\beta_m|\leq|\gamma_m(k)|\leq c_2|\beta_m|;
   $$

4. the densities are uniformly bounded in $L^1(\Gamma)$; to conclude that
   the extracted coefficients are holomorphic, the densities must also be
   $L^1(\Gamma)$-valued holomorphic functions of $k$.

These conditions give a uniform Weierstrass test on the disk. The package
routine `bloch.rayleigh_channels` chooses square roots point by point and
flips them according to the sign of the imaginary part. That rule is not an
analytic branch chart on a two-sided complex disk. The I4 complex evaluator
must continue to inject the frozen anchored branch into the otherwise
algebraic extractor.

## Failure modes

- If $\delta=0$, the exponential majorant disappears. The single-layer
  kernel is only of order $1/|m|$, the double-layer and
  $\partial_x\mathcal S$ terms are generally of constant order, and
  $\partial_x\mathcal D$ can grow like $|m|$. Ordinary absolute-uniform
  convergence no longer justifies the operation. A touching or crossing
  wall additionally requires singular integration and jump relations.
- At a Wood anomaly, one finite denominator $\gamma_j$ is zero. Near a Wood
  anomaly the corresponding coefficient can be amplified like
  $1/|\gamma_j|$. This is a finite-mode pole, not a high-mode tail effect.
- If a source curve crosses a wall, the sign of $|x-x_s|$ changes along the
  curve. The fixed left/right coefficient formulas are then invalid even if
  a conditional series happens to exist.

## Static implementation audit

The scattered single- and double-layer phases, normal signs,
$1/\sqrt d$ normalization, and $\eta=[\tau; -\sigma]$ convention agree
between draft equations (34)--(35) and `bloch.farfield_extractors`.

Two adjacent issues are not errors in this coefficient derivation:

1. Draft equation (35) displays only the scattered contribution
   $F_{\mathrm R}\eta_n$. Total transmission also contains

   $$
   e^{\mathrm{i}\gamma_n(X_{\mathrm R}-X_{\mathrm L})}\delta_{mn}.
   $$

   `bloch.construct_S` already adds this term. The manuscript formula must be
   relabeled or completed before publication, but it does not block the
   current computation.
2. `op.construct_A_QP` returns the similarity-scaled matrix
   $D A_{\mathrm{phys}}D^{-1}$ with
   $D=\operatorname{diag}\sqrt{h|z'|}$. A general contour requires the
   compatible interfaces $B_s=DB_{\mathrm{phys}}$ and
   $F_s=F_{\mathrm{phys}}D^{-1}$. The current circle has constant speed, so
   $D$ is scalar and the omission in `bloch.construct_S` has no effect on the
   canonical I4 result. This becomes a blocker before any nonconstant-speed
   contour is promoted.

## Frozen numerical closure

The new experiment `test/i4-extract/` separates the following gates:

1. pure Rayleigh wall projection and left/right derivative signs;
2. circle Fourier-density Bessel coefficients versus direct angular
   quadrature and `bloch.farfield_extractors`;
3. retained-row invariance for $M=5,10,20,70$;
4. boundary and exact-wall Fourier refinement;
5. augmented-MFS wall values versus the continuous Bessel coefficients;
6. point Green values from a spectral partial sum, an Ewald reference, and
   the augmented-MFS evaluator;
7. descriptive $\delta$-dependent high-mode slopes and explicit negative
   metadata at $\delta=0$ and near a Wood anomaly.

The formula and quadrature checks cannot certify the direct-wall reference.
The current blocker closes only if the augmented-MFS reference error and its
two-level change are each at most $2\times10^{-9}$, the legacy extractor
comparison is at most $10^{-8}$, and the four-layer error budget is at most
$10^{-8}$.

## Canonical Octave result

The frozen run completed with exit code zero in $2450.63$ seconds. The gates
separate the spectral extractor from the augmented-MFS reference as follows.

| Gate | Observed value | Tolerance | Result |
|---|---:|---:|---|
| pure left/right Dirichlet/Neumann projection | $2.65\times10^{-16}$ | $10^{-12}$ | pass |
| Bessel formula versus angular quadrature | $5.50\times10^{-16}$ | $5\times10^{-13}$ | pass |
| package extractor versus continuous coefficient | $4.65\times10^{-16}$ | $10^{-11}$ | pass |
| retained rows for $M=5,10,20,70$ | $4.74\times10^{-16}$ | $5\times10^{-14}$ | pass |
| boundary refinement, $n=256\to512$ | $1.17\times10^{-11}$ | $2\times10^{-10}$ | pass |
| exact-wall refinement, $N_y=1024\to2048$ | $1.20\times10^{-15}$ | $2\times10^{-10}$ | pass |
| MFS wall refinement, $N_y=512\to1024$ | $1.10\times10^{-11}$ | $2\times10^{-9}$ | pass |
| higher-proxy wall reference error | $1.42\times10^{-8}$ | $2\times10^{-9}$ | fail |
| high-to-higher proxy wall change | $5.88\times10^{-8}$ | $2\times10^{-9}$ | fail |
| higher-proxy point error versus Ewald | $8.20\times10^{-9}$ | $2\times10^{-9}$ | fail |
| high-to-higher proxy point change | $5.08\times10^{-8}$ | $2\times10^{-9}$ | fail |

At resolved orders, the spectral point Green value agrees with the Ewald
value at approximately $10^{-16}$. The fitted high-mode slopes for
$\delta=0.3,0.2,0.1$ agree with $-2\pi\delta/d$ to relative error at most
$2.95\times10^{-4}$. The largest higher-proxy wall row is the single-layer,
left-wall, Dirichlet coefficient at $m=0$, with error
$1.42\times10^{-8}$; this is not a high-Rayleigh-mode tail.

Thus the conditional sum--integral argument, coefficient formula, package
implementation, retained-row behavior, boundary quadrature, and wall Fourier
projection all pass in the canonical real non-Wood setting. The failed
`existing_extractor` gate is a downstream comparison with the same inaccurate
augmented-MFS wall field, not a second independent failure of the extractor.
The remaining error changes by roughly $5\times10^{-8}$ when the proxy level
changes, while $n$ and $N_y$ refinement changes are only about $10^{-11}$.
The numerical blocker is therefore localized to the augmented-MFS/proxy
construction, although the present two-level experiment does not yet decide
whether the cause is the proxy basis, collocation parameters, or the
least-squares solver cutoff.

## Cheap proxy-solver diagnosis

The follow-up `test/i4-extract/proxy-solver/` rebuilds the two canonical
least-squares systems exactly, without a wall grid or `pairmat` call. The
systems have sizes $720\times354$ and $960\times450$. Spectral and Ewald
references at the three canonical point separations agree to
$1.11\times10^{-16}$.

The source-identical test-local assembly reproduces the package coefficients
and point fields exactly, and two repeated package and test-local solves also
agree exactly. An intentionally recorded preliminary attempt used an
algebraically factored free-space Green derivative. The resulting matrix and
right-hand-side changes were only of order $10^{-16}$, but the default
pseudoinverse point fields changed by as much as $6.57\times10^{-8}$. This is
direct evidence that the proxy solve is extremely sensitive to roundoff-level
assembly changes.

For Octave 10.3, the documented default pseudoinverse tolerance and observed
ranks are

$$
t_{\mathrm{default}}
=\max(\operatorname{size}A)\|A\|_2\epsilon,
\qquad
r_{\mathrm{high}}=183,
\qquad
r_{\mathrm{higher}}=213.
$$

The default `pinv(A)` and explicit `pinv(A,t_default)` fields agree exactly,
confirming the default backend. A manual economy-SVD truncation at relative
$\tau=3\times10^{-16}$ retains ranks $225$ and $273$ and gives point errors
$3.95\times10^{-12}$ and $2.51\times10^{-12}$, with two-level change
$5.26\times10^{-12}$. It therefore closes only the three frozen point values.
However, `pinv(A,tau*norm(A))` at the same nominal threshold and ranks gives
point error $5.98\times10^{-5}$ and two-level change $7.93\times10^{-5}$.
Thus the improvement is not a cutoff-only intervention: it also depends on
the SVD computation/reconstruction path. The active decision is
`PROXY_SOLVER_DIAGNOSTIC_UNRESOLVED`, and no expensive improved-proxy wall
validation is justified yet.

## Current classification

### BLOCKER

- `QPGREEN AUGMENTED-MFS/PROXY CLOSURE`: the higher-proxy wall and point
  errors are $1.42\times10^{-8}$ and $8.20\times10^{-9}$, and the two-level
  changes are about $5\times10^{-8}$. The economy-SVD path closes three
  selected point values, but the same-threshold `pinv` path fails and no
  derivative or wall result exists. This blocks an eligible direct-wall
  reference and hence still blocks certified $M_{\mathrm{trace}}$.
- The anchored complex-$k$ branch remains a separate blocker before the root
  disk is promoted; the real-axis proof does not close it.

### IMPORTANT CAVEAT

- The theorem is conditional on draft equation (16); lattice-sum/spectral
  equivalence has not been re-proved here.
- The natural $H^{-1/2}\times H^{1/2}$ layer-density version has not been
  optimized; the stated $L^1$ result is sufficient for the smooth test.
- The numerical clearance is limited to the canonical real, non-Wood circle.
  It does not certify $\delta=0$, Wood points, a complex-$k$ disk, a solved
  BIE density, or a general curve.
- The canonical artifacts precede post-run logging/timing-only edits to the
  runner. The numerical configuration was unchanged, but a future formal run
  must save code hashes and the complete solver backend with its artifacts.
- The economy-SVD point result uses the same three locations that select the
  solver policy. Hold-out values and analytic point derivatives are required
  before promoting that path to an expensive wall validation.
- The nonconstant-speed density-scaling interface must be repaired before
  reusing the current `construct_S` path on ellipses or general contours.
- Draft equation (35) must include or explicitly exclude the direct
  transmission phase.

### MINOR CAVEAT

- Input validation does not currently enforce positive period, wall ordering,
  unit-normal orientation, or a quantitative Wood distance. The canonical
  experiment supplies all four conditions explicitly.
- The finest resolved spectral truncation is present in the point ledger but
  is not a separate mandatory gate in the canonical report.

## Proof workflow record

- Task mode: `Proof from scratch`.
- Source statement: draft equation (16) and the extraction operations leading
  to draft equations (34)--(35).
- Target environment: this file, section `Proposition: separated-wall spectral
  extraction` and its `Proof` subsection.
- External theorem citations used in the proof: none.
- Remaining proof gap: equality of the lattice-sum and spectral definitions,
  which is outside the conditional proposition.
- Independent review verdict: `PASS WITH CONDITIONS`; the required open-strip,
  almost-everywhere normal, evanescent-cutoff, and common complex-branch-domain
  qualifications are incorporated above.
- Status: `Conditional proof complete for the stated separated-wall spectral
  formula; literature verification of that formula's lattice-sum equivalence
  remains incomplete.`

## Three-path value audit

The follow-up experiment uses three computation paths on identical circle
nodes, quadrature weights, manufactured densities, walls, and final Fourier
basis.  It does not solve three BIEs.

1. The Ewald path implements the real/reciprocal split in Linton equation
   (2.65) locally under `test/`; it does not call a Rayleigh evaluator.
2. The MFS path calls the package qpgreen evaluator and applies the same frozen
   density.
3. The Rayleigh path calls `bloch.farfield_extractors` directly.

The convention mapping is explicit.  Linton's separation coordinates are
$(X,Y)=(x_t-x_s,y_t-y_s)$, so the local Ewald helper consumes the physical
separations directly.  Only the package first-coordinate-periodic MFS wrapper
uses $(x,y)\mapsto(y,x)$.  Linton uses $(\Delta+k^2)G=\delta$ and
$-\mathrm{i}H_0^{(1)}/4$; the project uses
$(\Delta+k^2)G=-\delta$ and $+\mathrm{i}H_0^{(1)}/4$.  Hence

$$
G_{\mathrm{project}}=-G_{\mathrm{Linton}}.
$$

Both conventions use the outgoing $\exp(-\mathrm{i}\omega t)$ time factor,
the target translation is $G(y+d)=\exp(\mathrm{i}\beta d)G(y)$, and no
$\beta\mapsto-\beta$ replacement is made.  The Ewald qualification reproduces
all five values from Linton Tables 2--5 with maximum absolute error
$5.07\times10^{-11}$.  Independent changes in the Ewald splitting parameter,
$M_1$, $M_2$, and $N$ pass the frozen $2\times10^{-9}$ reference-change gate;
the project point Ewald--Rayleigh difference is $1.11\times10^{-16}$.  At the
same five printed Linton points, package MFS differs from the qualified Ewald
values by as much as $6.01\times10^{-8}$.

For the frozen single-layer Dirichlet action at $k=1.8603695988$,
$\beta=0.5$, $d=1$, radius $0.2$, and wall clearance $0.3$, the full Ewald
kernel is first integrated on the circle and then projected on each wall.  Its
coefficients agree with the direct Rayleigh extractor to
$6.10\times10^{-16}$.  Thus using a Rayleigh mode as the boundary kernel is a
value-level `PASS WITH CONDITIONS` for these parameters, densities, and
retained modes.  It is
not a theorem-level or complex-$k$ certification.

The reported retained-row change of zero is an index-consistency check, not a
Rayleigh-tail convergence result: each extractor row is constructed
independently, so increasing output $M$ leaves an existing row unchanged.
Tail control and $M_{\mathrm{trace}}$ remain open.

The MFS triangle fails independently.  The largest point error on three
canonical and two hold-out points is $4.89\times10^{-8}$, and the same-path
error on the five Linton points is $6.01\times10^{-8}$; the largest SLP--D
coefficient error in either pair containing MFS is $4.69\times10^{-8}$.
Changing only $N_{\mathrm{side}}$, $N_{\mathrm{top}}$,
$N_{\mathrm{proxy,edge}}$, or $M_{\mathrm{pw}}$ changes coefficients by
$7.52\times10^{-8}$, $5.99\times10^{-8}$, $3.72\times10^{-8}$, and
$4.45\times10^{-8}$, respectively.  Boundary and wall quadrature changes are
only about $2.8\times10^{-11}$.  The decision is therefore
`OCTAVE_AUGMENTED_MFS_PROXY_SOLVER_PATH_BLOCKED`, not a spectral/extractor failure.

The canonical Octave run uses the package fallback `pinv(A) * b` branch because
`lsqminnorm` is unavailable.  The package interface does not expose the exact
rank, cutoff, coefficient norm, or residual in this run.  Consequently the
triangle isolates the package MFS computation path, but does not by itself
separate the pseudoinverse backend from proxy basis or collocation error; no
MATLAB solver inference is made.

Because SLP--D does not pass the mandatory $10^{-8}$ coefficient and
$2\times10^{-9}$ self-change gates, SLP--N, DLP--D, and DLP--N are
`NOT_RUN_PREREQUISITE`.  Linton function-value agreement does not certify
Ewald gradients or Hessians; these derivatives remain a downstream blocker.
