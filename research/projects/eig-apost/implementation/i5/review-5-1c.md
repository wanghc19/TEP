# I5.1c independent review

## Review frame

This review audits the nonzero-center theorem, the v2 builder and evaluator,
and the canonical `residual-numerator-a1` output.  The required distinction is
between structural validity of the finite majorant and success of the optional
tightness allocations.  The independent Skeptic remained read-only; this file
persists its supplied findings without changing their verdict.

## Pre-run verdict

**Verdict: `GO` (high confidence).**  No blocker prevented the canonical run.

The pre-run audit confirmed:

1. the signed local center, $T_i-T_e$ sign, and one copy of each identity;
2. the tail-only series difference and the $h_N/\sqrt P$ scale of (KR-21b);
3. the physical minus sign applied to the raw off-surface normal row;
4. the regular-image zero center with a complete finite-plus-Ewald radius and
   the absorbed M-T term counted once;
5. retained rows $|\ell|<L$, even $N>2\max\{L,M_\eta\}$, and no Nyquist row;
6. the material factor $1/b_\ell$ and lifting factor
   $e_{\ell,\mathrm{val}}$ applied after combining each center and radius;
7. the complete low-cell row map, with $G_\pm$ composed exactly once; and
8. the block-power bounds and zero solve counts enforced fail closed.

One `minor caveat` in the design table called the off-surface high omission a
Rayleigh-index tail.  It is instead the target-boundary Fourier set
$|\ell|\ge L$ over the complete frozen finite Rayleigh source support.  The
wording was corrected before the run; the code already used the correct
partition.

## Canonical run-01 audit

**Post-run verdict: `GO` for the finite theorem-valid inequality in the
declared `NON_CERTIFIED_ROUNDOFF_EXCLUDED` scope.  Tightness gates fail.**

The canonical run selected $L=256$ and $N=514$.  Its component bounds are

$$
\widehat B_{\Gamma_\pm}
=1.8732039079101324\mathbin\times10^{-10},
$$

$$
\widehat B_\Upsilon=4065.2721546834186,
\qquad
\widehat B_{\mathrm{lift}}=1471254.9074650614,
$$

$$
\widehat{\mathcal M}=1475320.1796197451.
$$

The persisted decomposition is arithmetically consistent:

| quantity | run-01 value |
|---|---:|
| material finite square | $16526436.541193478$ |
| material tail square | $1.150450888697657$ |
| lifting finite square | $541145772497.42468$ |
| lifting tail square | $1978187.58193865$ |
| final lifting factor | $2$, applied once |

All 28 required-true gates and all four required-false gates passed.  The
audit covered 205830 numerical entries and found no nonfinite value or
negative radius.  Eigenpair, density, QZ, and propagation solve counts were
all zero.  Source, target, tail-only series, target-Fourier, Ewald,
off-surface, and cell-tail ownership remained disjoint.

The status
`RETAINED_RADIUS_TOLERANCE_FAILED_ORDINARY` is required.  The largest retained
radius was $2476.4406876485091$ against a tolerance of $10^{-6}$, and its
$N$-independent regular-image floor was $1421.9904464646568$.  The material
tail norm was about $1.07259$ and the lifting local Fourier-tail norm about
$1406.48$, so neither tail allocation passed.  These are `important caveats`
about usefulness, not evidence against the finite inequality.

Compared with I5.1b, the total ordinary majorant decreased from about
$2.303805\mathbin\times10^6$ to
$1.475320\mathbin\times10^6$.  The change is explained by the signed nonzero
local and off-surface centers.  This comparison is not used as a reliability
criterion.

The complete run took 17.81 seconds and reached a maximum resident set size of
1023131648 bytes, below the 30-minute and 2 GiB limits.  MATLAB Code Analyzer
reported eight performance or style notices (unnecessary brackets, unused
temporary values, dynamic growth, and one unused argument); none changes the
evaluated formulas.

## Findings and boundary

- `blocker`: none for the finite, roundoff-excluded inequality.
- `important caveat`: retained-radius and both tail tightness allocations
  fail, so this is not an instance-level `COMPLETE` result.
- `important caveat`: no outward-rounded backend was used; no number includes
  floating-point or library-evaluation rounding certification.
- `minor caveat`: the eight Code Analyzer notices are nonsemantic.

The shortest route to remove the dominant run-01 floor is a rigorously
enclosed nonzero regular-image center.  Merely increasing $N$ cannot remove
the zero-center floor.  A bounded follow-up may instead separate the real-axis
regular full-action radius used for retained target rows from the complex-strip
bound used only for high target-Fourier rows; that change requires its own
static and post-run review.

## Bounded revision and run-02 review

**Verdict: `GO` for the revised finite inequality; tightness gates still
fail.**

The retained/high regular-image split uses the real-axis full-action bound
only on $|\ell|<L$ and the width-$0.2$ strip bound only on
$|\ell|\ge L$.  These target-index sets are disjoint, and the M-T contribution
is absorbed once in each applicable full-action bound.  The revision therefore
does not duplicate the regular-image action or weaken its high-mode proof.

Run-02 gave

$$
\widehat B_\Upsilon=3173.4763600536294,
\qquad
\widehat B_{\mathrm{lift}}=1217476.8489956486,
$$

$$
\widehat{\mathcal M}=1220650.3253557023.
$$

The material finite and tail squares were $10070951.05736848$ and
$1.1504507530997474$; the lifting squares were $370560491272.51489$ and
$1978187.5783551245$.  All 31 required-true gates and four required-false
gates passed, with zero solves and no nonfinite or negative radius.  The
retained regular-image value and normal radii were $136.37489934999303$ and
$1094.7813067510401$, so the largest radius remained $2149.2315$ before the
target-alias refinement.

The scientific run took 17.37 seconds and 1063583744 bytes maximum RSS.  One
later read-only audit requested a nonexistent report field.  Its failure and
the corrected audit are both preserved; the scientific result was unaffected.

## Final run-03 review

**Final Skeptic verdict: `GO` for the structural finite theorem-valid
inequality in the `NON_CERTIFIED_ROUNDOFF_EXCLUDED` scope.  Tightness and
stopping verdict: `FAIL`.**

For $L=256$ and $N=514$, the final values are

$$
\widehat B_{\Gamma_\pm}=1.8732039079101324\mathbin\times10^{-10},
$$

$$
\widehat B_\Upsilon=3006.7225021204808,
\qquad
\widehat B_{\mathrm{lift}}=748498.34329471563,
$$

$$
\widehat{\mathcal M}=751505.06579683628.
$$

The material finite and tail squares are $9040379.054306915$ and
$1.1504507314502783$; the lifting finite and tail squares are
$140060464291.15997$ and $1978187.5735129558$.  The factor two in
$\widehat B_{\mathrm{lift}}=2\sqrt{\overline F_{\mathrm{lift}}^2+
T_{\mathrm{lift}}^2}$ is applied once, and the lifting energy multiplies by
$e_{\ell,\mathrm{val}}$.

The constant-speed alias construction is an alternative bound for the same
target error, so the evaluator takes its minimum with (KR-19) and does not add
the two.  Its largest used value and normal radii are
$0.0074369915644510592$ and $0.063607714304987059$.  The explicit alias cutoff
is 64 and the first omitted index is 65; both alias gates pass.

All 33 required-true gates and four required-false gates pass.  All four solve
counts are zero, and 205830 audited numerical entries contain no nonfinite
value or negative radius.  The real-axis retained set, complex-strip high set,
and single M-T ownership gates pass.  The run took 18.27 seconds and
1010253824 bytes maximum RSS.

The following are `important caveats`, not omitted gates:

1. The retained radius $1095.3128606361292$ exceeds $10^{-6}$.
2. The material omission-tail allocation fails.
3. The lifting omission-tail allocation fails.
4. The status string reports only the first of these failures.

The $N$-independent regular-image normal zero-center radius
$1094.7813067510401$ is the dominant retained floor.  Increasing $N$ cannot
remove it.  A strictly enclosed nonzero regular-image normal center is the
shortest remaining tightening obligation.  Comparisons among v1 and runs
01--03 are diagnostic only and are nowhere used as a reliability or stopping
criterion.  No outward-rounded backend was used, so this review does not call
the result a fully certified enclosure or an instance-level `COMPLETE` result.
