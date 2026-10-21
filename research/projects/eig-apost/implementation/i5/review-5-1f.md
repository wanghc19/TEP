# I5.1f independent signed-centre review

## Scope and review boundary

This review concerns only the v5 oracle-model residual numerator.  Both
`delta_sf` and `delta_fp` remain `UNRESOLVED`.  A conditional implementation
`GO` is not a reliable, certified, or outward-rounded result.  The independent
Skeptic reviews the mathematical contract before implementation and the code
and canonical result afterward.

## Artificial-wall pre-code review

The Skeptic returned `GO` with high confidence for the signed-wall candidate,
subject to the following fail-closed ownership checks.

- The exact curve rows use (G-row), (G-analytic), and (ZF-19)--(ZF-22), with
  the stored coordinate $\eta=(\tau,\zeta)^{\mathsf T}$, $\zeta=-\sigma$.
  The value row is the outward-normal row divided by $\mathrm i\gamma_m$;
  its quadrature radius is divided by $|\gamma_m|$.
- The normal side rows combine the two adjacent outward-normal actions before
  taking absolute values.  The center/first-cell normal singletons are
  separate from every $n\ge0$ internal sequence.
- The four sequences in (ZF-28) plus the two first-lead value collars
  $V_LG_+c_+$ and $V_RG_-c_-$ are exactly equivalent to both value walls of
  every lead cell, each starting at $n=0$.  The implementation uses the latter
  form and must not append the first-lead collars again.  The two central
  mismatches from (ZF-27) remain separate.
- Flat and shared supports are $-256{:}255$, extended by zero at $m=256$.
  Retained $|m|\le256$ and high $|m|\ge257$ do not overlap.  The high normal
  bound is the existing positive-distance sum.  The new high value bound
  uses $b_0=2\pi\,257/d-|\beta|>2\widehat k$,
  $\kappa_m\ge|\beta_m|/2$, and two-sided geometric moments of degree at most
  two.  Its prefactor $1/(2d)$ already includes both signs of the omitted mode.
- Explicit cells stop at $J-1$; the retained-mode cell tail starts at
  $P_\varsigma^Jc_\varsigma$ and uses a whole-matrix block-power certificate.
  Every matrix, trace, clearance, and finite/nonnegative gate must pass.
- Historical stored wall residuals and mismatches are excluded.  The global
  lifting factor two is deferred to the final evaluator and used once.

These checks concern the conditional analytic enclosure.  They do not close
finite special-function or floating-point errors.

## Complete mathematical contract: pre-code review

The independent Skeptic returned `PASS WITH CONDITIONS / GO` for the complete
oracle-model design after one bounded revision.  The conditions are the
explicit finite geometry/density/propagation inputs and the unresolved
$\Delta_{\mathrm{sf}}$, $\Delta_{\mathrm{fp}}$; they are not hidden numerical
certification claims.  The review checked the following points.

- Physical value centers add self, raw regular, and raw off-surface rows;
  physical normal centers subtract the latter two.  Identity terms occur
  only in the local action.  Cotangent and hypersingular common terms are
  canceled before absolute bounds.
- Local fourth-order source bounds contain full density derivatives,
  including the fifth derivative of the Maue density.  The fourth-order
  composition and Leibniz constants are explicit.  Target bounds may take
  the minimum of two bounds for the same target error.  They may not replace
  a center-plus-radius enclosure by the minimum of unrelated whole-action
  quantities.
- Local high-mode alternatives bound the complete identity-inclusive
  action on $|\ell|\ge L$.  Retained source, target, and series errors own
  only $|\ell|<L$.  The final tail uses the same certified trace slope as
  the cutoff selection.
- The regular-image source strip moves only the source; its density bound
  includes exponential Fourier growth.  The target strip moves only the
  target and uses real-source density mass.  A common conservative box is
  permitted only when certified on the union of those two domains, not on
  an unproved simultaneous product strip.
- $L$ is selected first from analytic tails, then fixed while selecting an
  even $N>2\max\{L,M_\eta\}$.  Allocation failures are tightness failures;
  a finite, structurally valid upper bound must still be reported.

## Helper implementation reviews before the canonical run

The wall helper received final static `GO`.  The regular-image and
off-surface helpers received final static `GO` after explicit fail-closed
domain, orientation, finite/nonnegative, ownership, and center-evaluated
gates were added.  Their raw center signs and derivative contractions were
independently checked.  M-R/M-I/M-T/M-L, source, and target errors are distinct.

The local helper's mathematical formulas received `GO`; its final adapter
gates additionally require the certified current circle geometry, exact
frozen support $-128{:}127$, $\zeta=-\sigma$, positive trace/tube constants,
and real finite nonnegative component radii.  The shape-general theorem is
not a claim that this particular geometry adapter accepts arbitrary curves.
No Fourier--Bessel operator diagonalization is used.

These are static reviews.  The final builder/evaluator and the canonical
run still require separate review before an instance conclusion is made.

The Skeptic also returned `PASS` for the final-scalar semantic clarification:
the exact analytic majorant, the expression with library primitive values,
and the ordinary computed scalar are three distinct quantities.  Their two
differences are owned by $\Delta_{\mathrm{sf}}$ and $\Delta_{\mathrm{fp}}$.
Thus the ordinary output named `M_ideal` is not itself claimed to bound the
continuous residual.  The exact governing kernel has zero piecewise volume
residual, so no fourth volume-defect module is missing.

## Integrated pre-run review: bounded correction

The first integrated review returned `REVISE`, before any MATLAB run.

1. **Important caveat / blocking the declared selection contract:** the
   local high-tail selector reused the preliminary $L=32$ trace slope for
   later cutoff candidates, while final assembly used the selected-$L$
   slope.  The preliminary slope was conservative, but this did not satisfy
   the declared same-constant selection contract.  The required correction
   passes each candidate slope explicitly, persists the array, and checks
   selected-slope equality in the final audit.
2. **Important caveat / blocking the phase-decision diagnostic:** the wall
   high-mode tails were present in the governing numerator but absent from
   the regular/wall tightness allocation.  The required correction includes
   their normal and globally scaled lifting contributions in that allocation,
   so a later special-function-dominance decision cannot overlook them.

The same bounded patch must also fail closed on cutoff/evaluation-selection
gates, selected $L,N$ consistency, and finite nonnegative final module totals.
The review found no new signed-center, quadrature, kernel, or propagation
formula error.  A post-correction `GO` is required before the canonical run.

The bounded recheck returned final pre-run `PASS / GO` with high static
confidence.  It explicitly checked candidate/final trace consistency,
selection indices and configuration, wall-high diagnostic ownership, all
final positivity/finite gates, and both unresolved evaluation labels.

## Canonical attempt-1 operational record

`run-01` stopped at MATLAB parsing, before any scientific computation.  The
builder's nested output/gate structure at line 687 lacked one closing
parenthesis.  The retained log records MATLAB R2023b
`23.2.0.2365128`, 19.20 seconds wall time, and 702464000 bytes peak RSS;
the watchdog observed 21 seconds including launch/monitor overhead and
783920 KiB maximum process-tree RSS.  No input or result MAT was produced.
This is an operational failure, not a failed scientific method.  Its three
logs are retained and the one-character repair is followed by `run-02` in
the same attempt; no formula, parameter strategy, or version changes.

## Run-02 independent post-run review

The mechanical repair received pre-run `GO`.  The correct canonical run then
completed in 44.12 seconds with 1083392000 bytes peak RSS.  The watchdog
observed 45 seconds and 1113152 KiB maximum process-tree RSS.  A separate
read-only extraction took 14.50 seconds and 670760960 bytes peak RSS.

The independent Skeptic returned **`PASS / Phase 2 GO` under branch 1**.
Reassembly from persisted squared components agrees with

| ideal module | ordinary computed value |
|---|---:|
| $\widehat B_{\Gamma_\pm}$ | $1.8732085926745556\,10^{-10}$ |
| $\widehat B_\Upsilon$ | $9.6716125459265295\,10^{-6}$ |
| $\widehat B_{\mathrm{lift}}$ | $0.056438633545021551$ |
| $\mathcal M_{\mathrm{ideal}}$ | $0.056448305344888337$ |

All 20 required-true gates and four required-false conditions pass, as do
selection, final assembly, zero-solves, and all four tightness allocations.
The first passing $L$ is 512 and the first passing $N$ is 2048, with
$2048>2\max\{512,128\}$.  The included local high-mode lifting tail is
the dominant contribution.  This phase-2 authorization does not require a
special-function-dominance finding because the first threshold is satisfied.

**Important caveat:** both final-functional evaluation errors are unresolved;
no reliable or certified conclusion follows.  A future total below one needs
$\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}<0.9435516946551117$.
**Minor caveat:** the displayed wall quadrature-radius norm is zero because
tiny positive radii underflow when squared.  It is not an analytic zero and
belongs to the unresolved floating-point remainder.  Individual centers
undergo strong cancellation, but their relative error is not the acceptance
criterion; phase 2 must bound the final-functional increment.

## Restricted phase-2 theorem and implementation review

The independent Skeptic reviewed (I5.1f-23)--(I5.1f-37) and the separate
`special_function_sensitivity_v5.m` entry point before its run.  The final
pre-run verdict was `PASS WITH CONDITIONS / GO` for **partial Faddeeva/$E_1$
sensitivity only**.  The following ownership points were material to that
verdict.

- The telescope replaces only Faddeeva and $E_1$ returns at the actual fixed
  library arguments.  All other primitive returns are held fixed.  Their
  errors, including errors moving the arguments, remain in
  $\Delta_{\mathrm{sf,rest}}$.
- The coordinate derivative gains retain every outgoing $q$, reciprocal
  denominator, normal contraction and source Jacobian.  Actual library
  phase magnitudes are used; they are not assumed exactly one.
- Faddeeva and $E_1$ occur only in retained regular-image centres in this
  implementation.  Their errors are not added again to the analytic Ewald,
  source, target or high-mode tails.  Other primitive errors in those tails
  are still unresolved, not discarded.
- The final gain uses the matched split-cell factor $S_J$: explicit states
  for $n<J$ plus the same block-power envelope for $n\ge J$ as the canonical
  computed majorant.  A bound for the unsplit physical state sum alone would
  not justify a bound on the difference of these two computed majorants.
- Value gains multiply the lifting weights, with the global factor two
  once.  No relative accuracy in the strongly cancelled centre is assumed.

The correct restricted run took 18.04 seconds and 983793664 bytes peak RSS.
It enumerated gains but made no Faddeeva/$E_1$ call and did not re-evaluate
the phase-1 centres.  It consumed the explicit frozen artifact and the
phase-1 input, not a historical result.  All restricted gates and all four
zero-solve counters passed.  Its create-once files are
`test/i5/residual-numerator-v5/output/attempt-1/sensitivity-run-01.mat`,
`sensitivity-run-01-log.txt` and `sensitivity-run-01-resource.txt`.

The independent post-run verdict was
**`PASS WITH CONDITIONS / PARTIAL FEASIBILITY GO`**.  The Skeptic independently
recomputed the following scalars from the persisted inputs and formulae:

| quantity | ordinary evaluated value |
|---|---:|
| matched $S_J$ | $2.9050958701919547$ |
| $A_F$ | $30944383.348174293$ |
| $A_E$ | $242617.37348658184$ |
| sufficient uniform absolute Faddeeva error for allocation $0.00125$ | $4.0395052825434619\,10^{-11}$ |
| sufficient uniform absolute $E_1$ error for allocation $0.00125$ | $5.1521454627779673\,10^{-9}$ |
| corresponding sufficient exact-relative Faddeeva error | $1.5512180321649638\,10^{-11}$ |
| corresponding sufficient exact-relative $E_1$ error | $3.1313719876758819\,10^{-8}$ |

The theorem is

$$
|\mathcal M_{\mathrm{an}}-\mathcal M_{\mathrm{lib}}|
\le A_F\varepsilon_F+A_E\varepsilon_E
+\Delta_{\mathrm{sf,rest}}.
$$

**Blocker to a complete finite-evaluation claim:** no actual uniform error
contract for either library implementation has been supplied, the remaining
primitive-family increment has not been enclosed, and the gains themselves
were evaluated without outward rounding.  Thus neither displayed threshold
is an observed error or a certificate.  In particular, the ordinary argument
extrema must be replaced by a complete outward argument cover before using
an interval oracle contract.

**Important caveat:** the two relative precision targets do not suggest an
unrealistic precision requirement, but they establish only partial
feasibility.  They do not show that the current MATLAB/MEX implementation
meets those targets or that all other primitive paths have comparable
conditioning.  No high-precision comparison or empirical agreement was used
as an error bound.  The complete result continues to carry
`delta_sf=UNRESOLVED`, `delta_fp=UNRESOLVED` and all reliable/certified gates
false.

## Inventory audit

The canonical regular helper recorded 75497472 scalar Faddeeva arguments and
16777216 scalar $E_1$ arguments.  The restricted run matched both complete
sets.  Their observed ranges are respectively
$\Re a\in[-0.8,7.1917836710782446]$,
$\Im a\in[-0.44081224267237612,0]$ and $z\in[1.44,23.04]$.
The predeclared positive-real $E_1$ box is $[1.44,23.68]$.

The experiment README additionally records direct, uninstrumented local
`gammaln` occurrences and corrects the interpretation of partial elementary
call counters.  Those supplemental static counts do not alter the canonical
MAT or any governing numerical term.  Bessel/Hankel and black-box `qpgreen`
library calls are absent; finite local kernel series and explicit Ewald sums
replace them.  Exponential, logarithm, gamma-log, phase and branch primitive
errors are not therefore absent: they are still owned by the unresolved
remaining-family telescope.

## Numerical decomposition and comparison

The entries below are norms, not squared energies.  Both value rows are
**before** the one outer lifting factor two.  The finite column is assembled
coefficientwise from centre plus radius, so it is not replaced by the sum of
the two separately tabulated norms.  Cell and omitted-mode columns own
disjoint index sets and enter the governing module in quadrature.

| action | signed-centre norm | retained analytic-radius norm | finite centre-plus-radius norm | cell tail norm | high-mode tail norm |
|---|---:|---:|---:|---:|---:|
| wall normal | $1.8732085926745556\,10^{-10}$ | underflow display; not analytic zero | $1.8732085926745556\,10^{-10}$ | $1.336010334254234\,10^{-23}$ | $2.6231136952706752\,10^{-154}$ |
| material normal | $2.3145063233504801\,10^{-13}$ | $1.2102208029805689\,10^{-6}$ | $1.2102209193727943\,10^{-6}$ | $1.7540787687016713\,10^{-13}$ | $9.5955955815590672\,10^{-6}$ |
| wall value | $8.1889350004714866\,10^{-15}$ | underflow display; not analytic zero | $8.1889350004714866\,10^{-15}$ | $2.3332771885645611\,10^{-23}$ | $2.2048028217063094\,10^{-154}$ |
| material value | $2.2172674840364707\,10^{-11}$ | $2.5943801308683665\,10^{-4}$ | $2.5943802574954021\,10^{-4}$ | $3.7602618235584041\,10^{-11}$ | $2.8218124158386274\,10^{-2}$ |

Material normal and value cancellation ratios are respectively
$9.574177419829729\,10^{-14}$ and $9.3424372366343\,10^{-13}$, using the
norm of the signed physical centre divided by the norm of the three
componentwise absolute centres.  Wall normal and value ratios are
$3.9101993715954521\,10^{-11}$ and $2.8331415996056879\,10^{-16}$.
These ratios describe retained finite centres only; none certifies an error
or substitutes for a quadrature/tail radius.

The ideal scalar is about $1.557337\,10^6$ times smaller than the supplied v4
zero-centre baseline $87909.044120357343$.  Its mathematical changes are the
signed same-defect centre-plus-radius inequality, the actual signed wall
rows, and the explicit fourth-order local source/target/high-mode bounds.
The new $L=512,N=2048$ were selected from those analytic bounds, not from
agreement with a previous run.  The principal remaining ideal width is the
local high-mode lifting tail.  No cancellation across the three residual
modules or between a centre and an error radius is permitted.

## Bounded backend feasibility check

The finite-function targets above are absolute summand-error requirements;
they do not demand $10^{-13}$ relative accuracy in the cancelled residual.
Ordinary higher-precision or independent-formula agreement could diagnose
sensitivity, but would not prove either uniform oracle contract.  No such
comparison was run here.

As a source-verified implementation possibility, the official
[FLINT complex hypergeometric documentation](https://flintlib.org/doc/acb_hypgeom.html)
provides `acb_hypgeom_erfc` and `acb_hypgeom_expint`; the latter computes
$E_s(z)$, so $s=1$ with the present positive-real argument box matches the
required $E_1$ branch.  FLINT's
[ball-arithmetic documentation](https://flintlib.org/doc/using.html)
describes finite-expression error propagation and precision refinement based
on output radii.  This establishes availability of a relevant backend, not
its runtime, tightness or successful integration for this experiment.

A prospective implementation must enclose the input arguments, evaluate the
named function balls, and enclose the final gain sums as well.  An explicit
series alternative must retain its analytic remainder and branch conditions.
Neither approach has been implemented or timed in this round.  The opaque
existing Faddeeva MEX binary has not acquired an accuracy certificate from
this API check.  Whole-graph elementary-family and floating-point replays
remain separate obligations.

## Local positive-certificate sensitivity

The independent Skeptic returned `PASS / GO` for the narrow theorem
(I5.1f-47)--(I5.1f-54), then `GO` for
`local_certificate_sensitivity_v5.m` before its run.  The main adversarial
check was the selected minimum: a generic additive bound for the two
alternatives does not bound their minimum by the same relative constant.
The common **bilateral** positive-term enclosure does, even if the selected
alternative changes.  The high-mode argument applies at amplitude level,
before squaring.  Identity addends remain fixed, positive and counted once.

The code uses $S_J$ for retained radii and independently recomputes
$S_\infty$ for high modes.  It verifies the stored source/target/series sum
and the selected p2/p4 minima with exact structural comparisons.  It does not
re-evaluate the signed local centre.  Integer gamma-log arguments $1{:}34$
and the 1064 immediately following positive exponential returns per local
invocation are checked separately from the certificate gain.

The create-once `local-certificate-sensitivity-run-01` completed in 14.52
seconds and 779403264 bytes peak RSS; the helper itself took 0.3170750833
seconds.  All its gates passed, all solve counters were zero, and the
ordinary values were

$$
S_\infty=9490.921169744874,\qquad
D_{\mathrm{nor}}=9.671596964464973\,10^{-6},\qquad
D_{\mathrm{val}}=0.02821931665775703,
$$

$$
D_{\mathrm{loc}}=0.05644830491247853.
$$

Allocating $0.00125$ to this subchain gives the prospective caps
$\varepsilon_\Gamma=0.002737816682536592$ and
$\eta_e=0.010891519908669904$.  The code's
`realized_library_allocation=0.0012499999999999983` means only its ordinary
evaluation of the prospective cap identity, **not a realized oracle error**.
The coefficient-log argument range was
$[-236.34714592546482,8.5053895855888]$ and all tested finite returns were
positive and nonunderflowing.  The wider five-invocation inventory contains
5320 such returns; only the final governing local certificate enters
$D_{\mathrm{loc}}$.

The local p4 derivative/tail certificate therefore does not impose a severe
precision target for this isolated family.  This does not bound regular
gamma-log paths or any other exponential/logarithm/geometry path.  The
actual local oracle contracts, all of $\Delta_{\mathrm{sf,rest2}}$, and
$\Delta_{\mathrm{fp}}$ are still `UNRESOLVED`.

The independent local post-run verdict was **`PASS / GO` as this declared
partial result**.  The Skeptic independently reconstructed both state factors,
the gain, prospective caps and their scalar allocation, checked the complete
integer/positive-return ledger and confirmed that all unresolved labels
remained in place.  There was no mathematical or implementation blocker to
this restricted conclusion.

## Bounded regular gamma-log composite review

The first narrow proposal to extend the local factor to regular-image gamma
calls was insufficient: gamma-dependent source and target bounds enter later
`log` and `exp` calls.  Those nodes cannot be omitted or silently replaced by
an algebraically simpler exact quotient when discussing the run-02 library
graph.  The repaired candidate therefore adds explicit affected-log absolute
error and outer-exponential relative-error contracts.

The independent initial review returned `REVISE` for a concrete lower-factor
error.  The factor $e^{-3\varepsilon_\Gamma}/(1+\eta_i)^2$ is not a common
lower bound when a library exponential occurs in a denominator.  The bounded
repair uses

$$
l_0=e^{-3\varepsilon_\Gamma}(1-\eta_i)^2,
\qquad u_0=l_0^{-1},
$$

and the corresponding symmetric safe downstream factors.  It also replaces
unit-phase and $\sqrt P$ shortcuts by actual fixed-library source/target
quadrature masses and a complete finite-call-set maximum for the canonical
exponential factor.  The positive polynomial triangle is formed before
combining signed coefficients; it does not multiply a small cancelled centre
by a relative factor.

After this one bounded repair, the theorem recheck returned **`GO`**.  The
Skeptic verified the static owner list in `signed_regular_image_v5.m`:
local-canonical finite/tail certificates, signed canonical coefficients,
the retained-image Taylor first-omitted term, and the affected source/target
logarithm and outer exponential nodes.  High-mode amplitudes use $S_\infty$,
retained/cell effects use $S_J$, and all other primitive paths and finite
arithmetic remain unresolved.  This is a theorem verdict only; any numerical
helper and output require separate pre-run and post-run review.

## Final regular implementation and post-run verdict

The first implementation review returned `REVISE` because a canonical-only
gamma-log ledger stopped at integer 19, omitting first-omitted terms at 20
and the named downstream call sites.  A count-only patch was also insufficient
to check positive nonunderflowing returns.  Before any run, the completed
patch added the full final-invocation count/range contract, a finite positive
factorial-exponential superset, the Taylor first-omitted return, positive
source/target actions and scale, finite affected log returns, and positive
stored source/target outer returns.  It also evaluates the small inflation
factors with `expm1`/`log1p`, with no safety factor.  The final independent
pre-run verdict was `GO`.

`regular-gamma-sensitivity-run-01` completed in 14.87 seconds and 839712768
bytes peak RSS.  It passed all gates, used zero prohibited solves and did not
re-evaluate a signed centre or operator.  Its first passing prospective
common cap was $t=2^{-30}$, giving $0.0005727677356781513$; the preceding
$2^{-29}$ gave $0.0011455354742368328>0.000625$.  The explicit bound itself,
not the difference between these values, selected the cap.

The independent post-run verdict was **`PASS WITH CONDITIONS / GO` for the
declared partial result, and `STOP` against a full reliable numerator claim**.
The reviewer reproduced the state factors, value/normal decomposition,
first-pass selection, complete finite-call and named-owner ledgers,
positive-return gates, resource measurements and unresolved labels.

The reporting-only linear corollary (I5.1f-71)--(I5.1f-73) also passed review.
For errors at most $1/16$, ordinary scalar evaluation of that corollary gives:

| named regular-image error | coefficient multiplying its error parameter |
|---|---:|
| absolute gamma-log error, integer arguments $1{:}20$ | $A_\Gamma\approx506427.55483400373$ |
| relative immediate factorial-exp error | $A_i\approx360126.26121529157$ |
| absolute affected source/target log error | $A_{\log}\approx3.90574471668751\,10^{-8}$ |
| relative affected source/target outer-exp error | $A_o\approx4.166127697800011\,10^{-8}$ |

These four scalar coefficients were derived for reporting from the saved
gain values and the displayed formula, not from an additional scientific run.
The dyadic cap uses the tighter nonlinear formula (I5.1f-67)--(I5.1f-68),
not this more conservative linear corollary.  The named parameter domains
and positive-return values are retained in the result's owner audits; no
contract is inferred from agreement between resolutions or precisions.

If all named Faddeeva/$E_1$, local and regular oracle contracts were met,
and their gain evaluations enclosed, their partial subtotal would be

$$
\|R\|_{\mu,*}\le0.06077107308056649
+\Delta_{\mathrm{sf,rest3}}+\Delta_{\mathrm{fp}}.
$$

This is an implication, not a newly certified result.  In particular the
remaining context-tagged elementary functions, branch/argument changes,
geometry/density/weight primitive evaluations, constants and finite
arithmetic still need their disjoint complete-graph enclosures.  The smallest
remaining obligation is the numerical segment-hull/ball replay in
(I5.1f-38)--(I5.1f-41), after removing the now-isolated named call sites.
Actual errors for the isolated sites also have not been supplied.  The
precision requirements found here support **partial feasibility**, not an
assertion that MATLAB double precision already satisfies the full budget.

## Final resource and preservation audit

There was one scientific attempt and no `attempt-2`.  The only operational
failure was the retained `run-01` parse error.  Correct canonical and
sensitivity outputs are create-once; no earlier result was overwritten.
The recorded MATLAB process wall times total 125.25 seconds: 19.20 parse
failure, 44.12 canonical, 14.50 read-only extraction, 18.04 Faddeeva/$E_1$
sensitivity, 14.52 local sensitivity and 14.87 regular sensitivity.
The largest process RSS was 1083392000 bytes; the canonical watchdog's
largest process-tree RSS was 1113152 KiB.  Each was below the authorized
45-minute/3-GiB limit.  Exact or reproducible equivalent command payloads,
individual logs and resources are documented in the experiment README.

MATLAB R2023b completed every post-repair run without NaN/Inf, dimension,
index, sign, weight or ownership failures.  Canonical `checkcode` emitted
nonblocking notices, including an unused-input notice; the sensitivity checks emitted
no diagnostics.  No changes were made to TEP, frozen artifacts, earlier
I5 versions or historical outputs.  No eigenpair, BIE-density, QZ or
propagation solve, denominator/effectivity calculation, commit or push was
performed.  The final working-tree checks cover tracked and new source
files separately.

The task started at 2026-09-13 09:47:26 CST.  The final artifact audit at
12:39:02 CST recorded 2 hours 51 minutes 36 seconds elapsed, before the
12:47:26 hard deadline; only final documentation and chat handoff followed.
