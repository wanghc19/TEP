# I5.1e independent review

## Pre-run verdict

`GO` for the library-independent zero-centre fallback defined by
(ZF-1)--(ZF-13), subject to literal implementation of all fail-closed gates.

The first review requested three repairs, all now made:

1. the block-power formula starts at $n=0$ and owns every side cell; no
   separately retained or low-cell term remains;
2. the generic $p=2$ local high tail includes the identity, because finite
   parameter-Fourier support does not imply finite arclength-Fourier support
   for a general curve;
3. the KR-15 constants are density- and Jacobian-inclusive and are not
   multiplied by a density mass a second time.

The current even $N_\eta$ density grid uses the declared half-open Fourier
representatives $-N_\eta/2,\ldots,N_\eta/2-1$.  The Nyquist representative is
audited directly; no strict $N_\eta>2M_\eta$ claim is made.

The code review must verify the directional use of every upper and lower
input; identity ownership once; strict retained/high separation; Ewald
M-R/M-I/M-T/M-L ownership once; outgoing/non-Wood and reciprocal gates;
positive-distance tails; induced-$1$ block contraction; multiplication by
the lifting weight; composition with each $G_s$ once; zero forbidden solves;
and the absence of unqualified library primitives from the governing path.

The final verdict and post-run findings will be appended after inspecting the
implementation and persisted attempt.

## Attempt 1 and attempt 2 post-run correction

`STOP` for a complete reliable numerator claim from attempts 1 and 2.  Their
material modules instantiate the zero-centre and mode-dependent bounds, but
the wall normal module consumed historical `Jplus`/`Jminus` rows and the wall
lifting module consumed stored center mismatches.  Those historical finite
actions did not carry the special-function and quadrature evaluation
enclosures required by the present standard.  Taking their magnitudes as
zero-centre radii does not prove that they enclose the corresponding exact
actions.  The attempt-2 material-interface diagnostics are unaffected, but
its displayed complete numerator is conditional.

The direct-wall theorem (ZF-19)--(ZF-28) passed mathematical review.  The
review confirmed the density sign $\zeta=-\sigma$, normalized Rayleigh basis,
source arclength factor, wall-normal cancellation of $1/\gamma_m$, the flat
normal jump factor $1/2$, and the left/right side signs.  It also required
that the two normal actions meeting one wall be joined before squaring, while
the distinct value-lifting collars remain separate.

## Attempt 3 pre-run review

The first code review returned `REVISE`: the exterior-density check was a
tautology and $h_{\mathrm{tr}}=1/2$ was not yet bound to the actual wall
spacing.  The bounded repair added literal frozen-data checks

$$
\rho_e=1,\qquad \mu_h=\widehat k^2\rho_e,
$$

and

$$
h_{\mathrm{tr}}>0,\qquad
2h_{\mathrm{tr}}\le L_x,\qquad
2h_{\mathrm{tr}}\le X_R-X_L.
$$

Both checks enter the direct-wall certificate, the builder structural gate,
and the evaluator required-true list.  The final pre-run verdict was `GO`.
The exact wall-input map uses literal `isequal`.  The $G_\pm$ block-product
comparison is diagnostic only; stored $D_\pm$ and $G_\pm$ enter their
respective governing formulas directly, so no approximate equality is used
as an identity.

## Attempt 3 post-run verdict

`GO` with high confidence for a structurally reliable,
ordinary-roundoff-excluded fallback.  The persisted result is

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(4438.1851473412171,
71520151.044302881,
478442999.20147264,
549967588.43092287).
$$

The finite/tail squares reconstruct all three displayed module bounds and
their sum.  The global lifting factor two is applied once in the evaluator.
The wall sets $-256{:}255$, the curve-only $m=256$ term, and the two-sided
$|m|\ge257$ tail are disjoint.  Center and lead singletons are each present
once; all side sequences start at $n=0$ in one block-power certificate.
Historical wall residuals occur only in a forbidden-source audit string and
do not enter the governing calculation.  All required-true, required-false,
finite/nonnegative and zero-solve checks passed.

The tightness verdict is separately `FAIL`: the preallocated omission
tolerance did not pass, and the material lifting finite square remains the
dominant term.  This does not invalidate the finite theorem majorant, but the
result must remain labelled `NON_CERTIFIED_ROUNDOFF_EXCLUDED` and must not be
called an outward-rounded certificate, an eigenvalue enclosure, or a
tolerance-achieving result.

## Attempt 4 post-run verdict

`GO` with high confidence for the $p=4$ local-tail refinement of the same
ordinary-roundoff-excluded fallback.  The fourth-derivative formula was
checked independently before coding: its variable-speed chain rule contains
all $w=1/v$ derivative terms, while the current constant-speed circle adapter
reduces it to $2\pi_+H_4/v^3$.  The retained local radius takes the minimum of
the complete-action, $p=2$, and $p=4$ alternatives coefficient by coefficient;
the omitted tail takes the minimum of the complete $p=2$ and $p=4$ tail
squares.  No partial pieces from two alternatives are mixed.

Run 01 completed with

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(4438.1851473412171,
71331709.25287348,
357633982.24127114,
428970129.67929196).
$$

All reliability, structural, branch, Ewald, propagation, direct-wall,
finite/nonnegative and zero-solve gates passed.  The local normal tail square
fell from $20.00747$ to $9.2941904149294434\,10^{-11}$ and the local value
tail square from $2.4835931862157036\,10^{12}$ to
$3.2842665557204094$.  The retained material lifting finite square is still
$3.1975516080759204\,10^{16}$, so the separate tightness gate remains
`FAIL`.  The result is therefore a valid theorem upper in the exact-frozen,
ordinary-roundoff-excluded model, but not an outward-rounded certificate or a
tolerance-achieving estimate.

## Attempt 5 review and final verdict

The coefficientwise finite-density DFT-ball theorem (ZF-35)--(ZF-41) passed
mathematical review.  Its directed half-angle bounds, negative root-of-unity
sign, sharp-ball product recurrence, half-open $-128{:}127$ support, single
negative Nyquist representative, and $1/N_\eta$ normalization were checked
independently.  The density centres are auxiliary coefficient centres only;
their radii enter $A_{E,q}$ once and do not become residual-action centres.

The first implementation review found one blocker after run 01: the builder
computed the selected derivative as the minimum of the DFT-ball and uniform
triangle uppers, but the equality-to-minimum assertion was not fail closed.
The bounded repair retains both raw arrays, checks the componentwise minimum
with literal `isequal`, exposes a named gate, and routes it through the builder
structural conjunction and evaluator required-true list.  A second static
review returned `GO` for run 02.

The canonical post-run verdict is `GO` with high confidence for a
structurally reliable, ordinary-roundoff-excluded fallback:

$$
\boxed{
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(890.89926907414088,
74125.153022206607,
476735.95267418399,
551752.0049654647).}
$$

The three square reconstructions, the global lifting factor two, every
required-true and required-false field, the density selected-minimum gate,
and all zero-solve counts pass.  Run 02 completed in 12.01 seconds with
maximum RSS 816,562,176 bytes.  The separate tightness verdict remains
`FAIL`: the selected $L=65536$ has lifting tail square
$1.4276064568391097\,10^{-5}>10^{-6}$.  This does not invalidate the finite
majorant, but the result is not outward rounded and is not a certified
eigenvalue enclosure or a tolerance-achieving estimate.

## Attempt 6 final verdict

`GO` with high confidence.  Increasing the fixed Newton count from 8 to 32
does not alter (ZF-35)--(ZF-41); it tightens the directed root rectangle while
leaving the dyadic padding, support, ownership, selected-minimum and all
inherited gates unchanged.  Static pre-run review and independent post-run
review found no blocker.  Run 01 reports

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(890.77256474677949,
29403.228836857772,
59680.487911794531,
89974.489313399084).
$$

All required-true values are true, all required-false values are false, all
solve counts are zero, and both reliability and tightness gates pass.  The
claim boundary remains `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Attempt 7 final verdict

`GO` with high confidence.  The 64-step, $2^{-48}$ directed root enclosure
retains every theorem and fail-closed gate.  The persisted hashes, square
reconstructions, outer lifting factor, required gates and zero solve counts
were checked independently.  Run 01 gives

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M)
=(890.77255515519369,
28500.152577876961,
58518.118987325186,
87909.044120357343).
$$

Reliability and tightness both pass.  The result remains a continuous
residual-numerator bound only, with ordinary floating-point roundoff excluded.
