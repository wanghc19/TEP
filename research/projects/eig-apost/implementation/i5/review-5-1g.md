# Independent review of I5.1g minimum-energy lifting

## Scope and authority

This file records the independent read-only theorem, pre-run, and post-run
reviews of I5.1g.  The governing sources were
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail]]
(ME-1)--(ME-31) and
[[research/projects/eig-apost/implementation/i5/design-5-1g]]
(I5.1g-1)--(I5.1g-24).  The reviewed implementation and canonical run are
documented in
[[test/i5/residual-numerator-v6/README]].  No implementation or theorem was
changed as part of this review.

The accepted scope is a conditional ordinary-arithmetic value of the ideal
residual numerator.  It is not a certified or reliable enclosure because
$\Delta_{\mathrm{sf}}$ and $\Delta_{\mathrm{fp}}$ remain unresolved.

## Theorem review

The first theorem review returned **REVISE** for two blocking defects.

1. The proposed square-summed assembly used separately minimized full-domain
   interface corrections.  Such minimizers need not have disjoint supports, so
   their energies could not be added as claimed.  The required repair was one
   simultaneous global jump quotient on the energy-square-summable broken
   product space, bounded by explicitly constructed pairwise-disjoint,
   zero-rim collar comparisons.
2. The artificial-wall part lacked the quasiperiodic two-sided
   minimum-energy comparison and its complete omitted-mode bound.  The required
   repair was the flat-wall harmonic weight, its affine
   $O(1+|m|)$ upper bound, and a positive-distance high-mode bound for the
   complete actual jump.

The revised theorem received **PASS WITH CONDITIONS / GO**.  The conditions
carried into implementation were: use the global simultaneous quotient; apply
product-space Cauchy--Schwarz once and hence use lifting factor one; certify
pairwise collar disjointness and zero outer-rim trace; form the actual wall
jump before weighting; include the complete wall constant with
$1/(2\sqrt d)$, every density/action term, and the correct exterior
wavenumber $k_e$; and apply each propagation certificate once.  The
shape-general collar weight was accepted only as a comparison upper, not as an
exact diagonal Dirichlet-to-Neumann map for variable curvature.

## Pre-run implementation review

The first integrated pre-run review returned **REVISE** and prohibited a
scientific run for four bounded reasons.

1. Material periodic-copy disjointness checked only the longitudinal cell
   width and omitted the transverse period $d$.  Consequently the advertised
   global direct-sum gate was not fail closed.
2. The separately stored material-side and wall-side gates were computed but
   were not included in the top structural and evaluator conjunctions.
3. The simultaneous-jump completeness gate checked only three hard-coded
   interface labels, rather than the actual retained, cell-tail, and high-tail
   ownership ledgers.
4. An unreachable historical cubic value-lifting branch remained in the wall
   helper, contrary to the no-arbitrary-profile implementation contract.

The bounded revision added the independent transverse check
$2(R+h)\le d$ to the disjointness and broken-direct-sum gates, routed both
side-separation gates to the evaluator, tied simultaneous-jump completeness to
the material and wall ownership ledgers, and removed the historical cubic
branch.  Static re-review found all four repairs correctly routed and returned
**PASS / GO**.  The material harmonic weights, local fourth-order tail,
regular/off-surface weighted tails, wall central and internal signs, paired
radii, wall high-mode normalization and map coverage, factor one, cutoff
partitions, zero-solve contract, and unresolved-error labels otherwise matched
the governing theorem.

## Canonical run-01 post-run review

The canonical persisted input and result were inspected independently.
Analytic selection chose $L=256$ and $N=1024$.  These were the first
candidates below their respective $0.1$
allocations: the selected high-mode contribution was
$0.03377389007214928$, and the selected retained-local contribution was
$0.022275416281249936$.

The reported conditional ideal quantities were:

| quantity | value |
|---|---:|
| $B_{\Gamma_\pm}$ | $1.8732119857082978\mathbin{\cdot}10^{-10}$ |
| $B_\Upsilon$ | $1.5565169597620056\mathbin{\cdot}10^{-4}$ |
| $B_{\mathrm{lift}}^{\mathrm{ME}}$ | $0.033621248621896728$ |
| $\mathcal M_{\mathrm{ideal}}$ | $0.033776900505194128$ |

All 33 required-true gates were true, and all four required-false conditions
had the required false values.  The structural, strict-cutoff, selection,
finite-nonnegative, collar, ownership, factor-one, and conditional diagnostic
gates passed.  Historical output was not read, and the eigenpair, BIE-density,
QZ, and propagation-matrix solve counts were all zero.

The stored squared decomposition reassembled the wall normal and wall lifting
values exactly.  The material-normal square differed from direct reassembly by
$3.31\mathbin{\cdot}10^{-24}$, the total lifting square by
$-2.17\mathbin{\cdot}10^{-19}$, and the final numerator by zero; the two
nonzero discrepancies are ordinary roundoff-scale effects.  The run completed
with exit status zero in 26.25 seconds.  `/usr/bin/time` recorded maximum RSS
of 1,141,817,344 bytes, while the process-tree watchdog recorded 1,209,520 KiB
over 27 seconds.  Both were below the declared hard limits.

One material interpretation caveat remains.  The stored artificial-wall
lifting high tail is numerically zero because the ordinary evaluation
underflowed.  It is not an established analytic zero and must not be reported
as one.  This is consistent with, but not resolved by, the explicit
$\Delta_{\mathrm{fp}}=\mathrm{UNRESOLVED}$ qualifier.

## Final verdict and claim boundary

The canonical I5.1g result receives **PASS WITH CONDITIONS / GO** as a
conditional ideal diagnostic.  Its theorem-to-code mapping, selection,
assembly, gates, and resource record support that limited claim.

Any certified, outward-rounded, or numerically reliable residual-majorant
claim receives **STOP**.  Both
$\Delta_{\mathrm{sf}}=\mathrm{UNRESOLVED}$ and
$\Delta_{\mathrm{fp}}=\mathrm{UNRESOLVED}$ remain governing, the reliable
majorant is unresolved, and the total-reliability and outward-rounding gates
remain false.  The conditional value must not be promoted to a certified
residual or eigenvalue enclosure without resolving both error terms.

## Attempt-2 value-convolution post-run review

The active branch was `current-circle-value-convolution`, limited to the
value-$Q_4$ replacement (I5.1g-36a)--(I5.1g-36d).  Independent pre-run review
first required the analytic-allocation fallback to force the v7 route.  After
that bounded repair, pre-run review returned **PASS / GO**.

The persisted selector ledger contained 20 analytic panel/$L$ candidates and
four strict $N$ candidates; all passed their analytic gates.  It selected
$L=256$, panel pair $(16,32)$, and $N=2048$.  The selected high value-tail
norm was $5.5630101040626736\mathbin{\cdot}10^{-4}$ and the selected retained
value-radius norm was $1.4145708728398299\mathbin{\cdot}10^{-3}$, each below
its preregistered half-target.  The certificate gave
$Q_4^{\rm val,conv}=65041.687340212338$ with
$\Phi_\tau=1.1180249400402444$, $\Phi_\zeta=0.51646395751653551$,
$\mathcal L_{\tau,4}=34.218913351116527$, and
$\mathcal L_{\zeta,4}=867.16019637947136$.

The conditional ideal results were

| quantity | value |
|---|---:|
| $B_{\Gamma_\pm}$ | $1.8732085926745556\mathbin{\cdot}10^{-10}$ |
| $B_\Upsilon$ | $1.5471045812179808\mathbin{\cdot}10^{-4}$ |
| $B_{\rm lift}^{\rm ME}$ | $5.5685129828202118\mathbin{\cdot}10^{-4}$ |
| $\mathcal M_{\rm ideal}$ | $7.1156194372467858\mathbin{\cdot}10^{-4}$ |

All 38 required-true gates, all four required-false gates, the structural and
finite/nonnegative audits, and all zero-solve checks passed.  Both performance
allocations passed.  Nevertheless, the mandatory route gate advances to v7:
the material high-tail fraction was $0.99901178667006518$, above $1/2$.
This does not invalidate the finite conditional majorant.

Run 01 completed in 39.80 seconds with `/usr/bin/time` maximum RSS
1,197,457,408 bytes.  The tree watchdog measured 1,269,456 KiB over 41
seconds.  The numerically zero wall high-mode tail is attributable to ordinary
floating-point underflow and is not an established analytic zero.

The post-run verdict is **PASS WITH CONDITIONS / GO** for the conditional
ideal result and **STOP** for a certified or numerically reliable claim.
$\Delta_{\rm sf}$ and $\Delta_{\rm fp}$ remain `UNRESOLVED`; the
total-reliable and outward-rounding gates remain false.
