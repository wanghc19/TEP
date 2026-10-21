# I5.1e reliable zero-centre fallback

## Purpose and theorem-to-code contract

I5.1e instantiates (ZF-1)--(ZF-13) in `s-kress-real.md`.  It is a new version
because the theorem-to-code contract changes materially: every retained
finite action is zero-centred, all side cells are covered in one block-power
sum beginning at $n=0$, and every scalar upper is evaluated without an
unqualified special-function library call.  I5.1e does not replace or rewrite
the signed-centre I5.1c/I5.1d diagnostics.

The governing curve theorem covers a regular, injective, single-chart
$C^{p+2}$ closed curve.  A programmatic geometry certificate supplies
perimeter, speed, chord--arc, reach, curvature, wall-clearance and, where
used, complex-strip bounds.  The frozen circular instance supplies one such
certificate; no Fourier--Bessel diagonalization enters the bound.

## Complete fallback assembly

For $\chi\in\{\mathrm{val},\mathrm{nor}\}$, the retained unit-state radius is

$$
r_\ell^\chi
=r_{\mathrm{self}}^\chi+r_{\mathrm{reg}}^\chi
+r_{\mathrm{off}}^\chi,
\qquad |\ell|<L.
$$

The local radius contains the identity once as a separate $J_0^\chi$ term
and the complete continuous Kress action through $C_{1,0}^\chi$ and
$C_{2,0}^\chi$.  The regular radius contains the retained elementary Ewald
whole-action upper and M-R/M-I/M-L once; its nonzero-image whole-action bound
absorbs M-T, so no separate M-T term is added.  The off-surface radius contains the complete
finite frozen Rayleigh action.  No sampled Kress centre, target DFT centre,
or finite special-function centre is used, so source and target quadrature
errors are absent rather than silently zero.

The side-state factor uses the induced matrix $1$-norm block certificate

$$
\sum_{n=0}^\infty\|G_sP_s^nc_s\|_1^2
\le \|G_s\|_1^2\|c_s\|_1^2
\frac{\sum_{r=0}^{b-1}\|P_s^r\|_1^2}
{1-\|P_s^b\|_1^2}.
$$

It owns all $n\ge0$ side cells.  I5.1e therefore has no separately retained
side cells and no low-cell tail.  The centre-cell singleton is separate.

The material finite energies multiply the normal radius by the reciprocal of
a certified trace-weight lower bound and the value radius by a certified
lifting-weight upper bound.  The same-collar local, regular and off-surface
high-mode sequence norms are added before squaring.  Artificial-wall normal
and value terms are rebuilt from the exact frozen Rayleigh coefficient rows
through zero-centred entrywise triangle bounds: phase moduli, inverse
wavenumbers and curve-to-wall actions are bounded explicitly.  A previously
computed finite mismatch is never treated as an enclosure.
Positive-distance formulas own only the omitted modes.

## Primitive evaluation contract

The governing upper-bound path uses exact finite arithmetic with ordinary
floating-point rounding excluded.  It uses the rational constants
$3<\pi<22/7$, the finite Newton square-root bracket (ZF-1), the exponential
bounds (ZF-2),
the logarithm and hyperbolic bounds (ZF-3), factorial recurrence, and
entrywise $|\operatorname{Re}|+|\operatorname{Im}|$ norms.  Calls to
`sqrt`, `exp`, `log`, `gammaln`, trigonometric/hyperbolic functions, `norm`,
or `fft` are forbidden in the governing path.  Every exponential ratio,
positive denominator, branch/non-Wood margin, Ewald tail, positive distance,
trace/lift weight, block contraction and finite-value condition fails closed.

## Cutoff, ownership and failure semantics

$L$ is selected from a finite predeclared schedule using only the proved
local $p=2$, regular-image, off-surface and wall omission formulas.  The
generic local tail includes the identity even though the input density has
finite parameter-Fourier support.  The sets $|\ell|<L$ and $|\ell|\ge L$ are
strictly disjoint.  The finite-density gate records its explicit half-open
representative set, including the one even-grid Nyquist representative; it is
not used to delete the generic arclength identity tail.

`total_reliable_pass` is the conjunction of every primitive, geometry,
density, branch, Ewald, tail, propagation, finite and zero-solve gate.
Tightness gates are recorded separately.  A finite but wide result remains a
valid fallback when the reliability conjunction passes.  Any failed
reliability gate persists the numerical decomposition as `FAILED` or
conditional and prevents a reliable claim.

## Resource plan and provenance

The planned canonical attempt is
`test/i5/residual-numerator-v4/output/attempt-1/`.  Its plan is at most
20 minutes and 1.7 GiB, below the task limits of 45 minutes and 3 GiB.  The
builder reads only explicit frozen artifact and geometry-contract paths and
writes a self-contained input snapshot.  The evaluator reads only that
snapshot and writes a create-once result.  All eigenpair, BIE-density, QZ and
propagation solve counts are zero.

Run commands, measured resources, gates and numerical results are appended
only after a canonical run completes.

## Mode-dependent retained rows and direct wall repair

Attempt 2 used the same zero-centre theorem with the coefficient-wise
corollary (ZF-14)--(ZF-18).  For each retained material mode it takes the
minimum of the whole-action radius and the available algebraic or strip
radius separately for local, regular-image and off-surface actions.  Only
then are the three physical actions added and weighted.  The zero mode never
uses the algebraic $Q_2/|\ell|^2$ expression, and retained $|\ell|<L$ remains
disjoint from the high tail $|\ell|\ge L$.

Post-run review found that attempts 1 and 2 still consumed historical finite
wall rows and stored wall mismatches without enclosing their evaluation
errors.  Their material-interface value and normal numbers remain useful
diagnostics, but their complete numerator status was withdrawn.

Attempt 3 replaces those wall terms by (ZF-19)--(ZF-28).  For
$w\in\{L,R\}$ it bounds the exact curve-to-wall value and normal actions by
the positive-distance density-mass estimate and bounds the normalized flat
Rayleigh terms term by term.  The normal rows are

$$
a_{+,m}=q_{R,m}(G_+)+q_{L,m}(G_+P_+),\qquad
a_{-,m}=q_{L,m}(G_-)+q_{R,m}(G_-P_-).
$$

The two contributions meeting one normal wall are combined before squaring.
The value rows combine the shared trace, flat Rayleigh action and curve
action within each collar; different left/right collars are squared
separately.  Center and lead singletons are separate from the $n\ge0$
block-power sequences.

The independent wall cutoff is $M_w=256$.  Frozen flat and direct-input
support is exactly $-256{:}255$; the $m=256$ extension is zero for those
parts but the curve action is retained.  Both positive-distance tails begin
at $|m|=257$.  Frozen $D_\pm$ are used directly for central traces and
frozen $G_\pm$ directly for side sequences.  The identities
$G_+=[D_+;D_+P_+]$ and $G_-=[D_-P_-;D_-]$ are recorded only as diagnostics,
so an approximate floating-point identity is not promoted to exact algebra.

The direct-wall gates additionally require the exact normalized wall-input
map, normalized $d^{-1/2}$ Rayleigh basis, density coordinate
$\eta=(\tau,\zeta)^{\mathsf T}$ with $\zeta=-\sigma$, non-Wood retained
modes, the first omitted modes to be evanescent, positive clearance, exterior
$\rho_e=1$ together with the literal frozen-data identity
$\mu_h=\widehat k^2\rho_e$, and $h_{\mathrm{tr}}=1/2$ fitting both the
declared cell width and $X_R-X_L$.  Historical `Jplus`, `Jminus`, center
jumps and center mismatches do not enter a governing calculation.

## Attempt records

All runs used the explicit frozen I3 artifact
`test/i3/e-cap/input/fbie-a1-certificate.mat` and the explicit circle adapter
`test/i5/wall-curve-a1/input/circle-contract-a1.mat`.  They performed zero
eigenpair, BIE-density, QZ and propagation solves.

Attempt 1 runs 01 and 02 were operational failures in the same scientific
attempt: a MATLAB structure-array assignment in the cutoff diagnostics
failed before any input or result was saved.  The cell-array repair did not
change the theorem.  Run 03 completed in 11.77 seconds with maximum resident
set size 826,458,112 bytes.  It selected $L=256$ and displayed

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(1.5258789063950686\times10^{-5},
8.4359854948513657\times10^{10},
4.8405666247769712\times10^{16},
4.8405750607624664\times10^{16}).
$$

Attempt 2 run 01 completed in 12.48 seconds with maximum resident set size
805,175,296 bytes.  The mode-dependent corollary selected $L=65536$ and
displayed

$$
(2.5769594543501116\,10^{-10},
7.1520151044302881\,10^7,
4.7844299920147043\,10^8,
5.4996315024577332\,10^8).
$$

Its material normal square split was
$5.115132005399565\times10^{15}+3.3413568860514403\times10^2$ and its material
lifting split was
$5.7185448281477344\times10^{16}+4.1477357069542797\times10^{13}$.
Independent post-run review classified the complete result as conditional,
because its old wall assembly lacked an evaluation enclosure.

Attempt 3 run 01 used the direct-wall repair and completed in 11.85 seconds
with maximum resident set size 796,344,320 bytes.  It selected $L=65536$ and
reported

$$
\boxed{
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(4438.1851473412171,
71520151.044302881,
478442999.20147264,
549967588.43092287).}
$$

The square decompositions are

| module | finite square | omission-tail square |
|---|---:|---:|
| artificial-wall normal | $1.9697487402080186\times10^7$ | $3.097936084230613\times10^{-91}$ |
| material normal | $5.115132005399565\times10^{15}$ | $3.3413568860514403\times10^2$ |
| material lifting | $5.7185448281477344\times10^{16}$ | $4.1477357069542797\times10^{13}$ |
| artificial-wall lifting | $2.3267819897458243\times10^8$ | $1.4870931981989942\times10^{-89}$ |

All structural gates and zero-solve gates passed.  The preallocated tail
tolerance did not pass, so the status is
`RELIABLE_FALLBACK_TIGHTNESS_FAILED_ORDINARY`.  This separates tightness from
reliability: the displayed value remains a theorem upper in the exact-frozen,
ordinary-roundoff-excluded model, but it is not an outward-rounded numerical
certificate.  Every displayed attempt value is labelled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Attempt 5 coefficientwise density DFT-ball

Attempt 5 keeps the zero-centre residual-action theorem, wall repair,
regular-image/off-surface ownership, propagation sum, and all earlier
attempt records unchanged.  Its only new finite centre is the auxiliary
density-coefficient centre in (ZF-39); this is enclosed before it is consumed
as a density derivative upper and is not a centre for any residual action.
The governing theorem is (ZF-35)--(ZF-41) in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-kress-real]].

For each of the two frozen no-midpoint nodal maps $E=\tau$ and
$E=\zeta=-\sigma$, the builder must:

1. audit $N_\eta=256$ and the exact half-open support
   $\mathcal I_\eta=\{-128,\ldots,127\}$, with $-128$ as the single
   Nyquist representative;
2. construct an interval for
   $\omega=e^{-\mathrm i\pi/128}$ by the six half-angle steps (ZF-36),
   starting from the exact $\cos(\pi/2)=0$ and $\sin(\pi/2)=1$;
3. form $(\omega_c,\rho_\omega)$ by (ZF-37) and all 256 power balls by
   (ZF-38), using only the approved square-root bounds and
   $|x+\mathrm iy|_\#=|x|+|y|$;
4. form the componentwise centres and radii in (ZF-39), the induced row
   uppers $b_m^E$ in (ZF-40), and
   $A_{E,q}=\sum_m|m|^qb_m^E$ for $0\le q\le5$;
5. replace each old uniform density derivative upper by the smaller of that
   upper and $A_{E,q}$, then rebuild the density-inclusive KR-15 constants,
   identity bounds, $H_q$, $Q_2$, and, when enabled, $Q_4$.

The root and power tables are finite analytic enclosures.  Governing code
must not call `fft`, `sin`, or `cos`; any such computation is diagnostic
only.  No density remainder is added to a residual row: the coefficient
balls first prove an upper for the same exact frozen finite density, and only
that upper is consumed by KR-15.  Source Jacobian, local kernel factors,
identity, trace/lift weights, local Fourier tail, Ewald/off-surface tail, and
block-power propagation therefore retain their previous mutually exclusive
owners.

Attempt 5 fails closed if any of the following fails: frozen node phase or
support equality; unique Nyquist ownership; ordered nonnegative half-angle
square-root intervals; finite nonnegative $\rho_\omega$, power radii,
coefficient radii, or derivative sums; modular indices in
$\{0,\ldots,255\}$; the density sign $\zeta=-\sigma$; density inclusion
exactly once in KR-15; or any inherited geometry, primitive, tail,
trace/lift, propagation, wall, finite-value, or zero-solve gate.  Ordinary
floating-point rounding remains excluded, so every eventual number retains
the label `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

Attempt 4 run 01 instantiated the $p=4$ certificate in 13.59 seconds with
maximum RSS 820,019,200 bytes.  It passed all reliability gates and gave

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(4438.1851473412171,
71331709.25287348,
357633982.24127114,
428970129.67929196).
$$

Attempt 5 run 01 exposed one review-only acceptance defect: the code selected
the minimum of two valid density derivative bounds, but the equality-to-minimum
audit had not been wired into the fail-closed conjunction.  The formula and
displayed numbers were unchanged.  The repair retains both raw bound arrays,
tests their componentwise minimum by literal `isequal`, and routes the named
gate through the builder structural conjunction and evaluator required-true
list.  Run 02 is therefore the canonical attempt-5 result.  It completed in
12.01 seconds with maximum RSS 816,562,176 bytes, selected $L=65536$, and gave

$$
\boxed{
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(890.89926907414088,
74125.153022206607,
476735.95267418399,
551752.0049654647).}
$$

The finite/tail squares are

| module | finite square | omission-tail square |
|---|---:|---:|
| artificial-wall normal | $7.9370150763683836\,10^5$ | $3.097936084230613\,10^{-91}$ |
| material normal | $5.4945383105655451\,10^9$ | $4.2235898773392754\,10^{-16}$ |
| material lifting | $5.6811295864185249\,10^{10}$ | $1.4276064568391097\,10^{-5}$ |
| artificial-wall lifting | $7.9962788551792055\,10^6$ | $1.4870931981989942\,10^{-89}$ |

All required-true and required-false gates, including the selected-minimum
gate, passed and all forbidden solve counts were zero.  The requested tail
tolerance did not pass.  The result is therefore a structurally reliable
upper in the exact-frozen, ordinary-roundoff-excluded model, labelled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`; it is not an outward-rounded certificate
or a tolerance-achieving result.

Attempt 6 changes no theorem or ownership rule.  It fixes the root-square
Newton iteration count at 32 before the run, keeps the dyadic padding
$2^{-40}$, and reuses every attempt-5 fail-closed gate.  Canonical run 01
completed in 13.94 seconds with maximum RSS 807,059,456 bytes and gave

$$
\boxed{
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(890.77256474677949,
29403.228836857772,
59680.487911794531,
89974.489313399084).}
$$

The root-of-unity ball radius was
$1.4477610082996861\,10^{-11}$.  Every reliability gate and the preallocated
omission-tail tolerance passed; the forbidden solve counts remained zero.
This is the smallest completed reliable attempt in the present exact-frozen,
ordinary-roundoff-excluded model.

Attempt 7 is the final predeclared parameter tightening.  It uses 64 Newton
steps and dyadic padding $2^{-48}$ in the same root-ball theorem; no residual
formula, ownership rule, or acceptance gate changes.  Run 01 completed in
12.89 seconds with maximum RSS 817,594,368 bytes and gave

$$
\boxed{
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(890.77255515519369,
28500.152577876961,
58518.118987325186,
87909.044120357343).}
$$

Both reliability and tightness pass.  This supersedes attempt 6 as the
smallest completed reliable result, still with ordinary rounding excluded.
