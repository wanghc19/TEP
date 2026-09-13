# I5.1d independent review

## Verdict

The pre-run verdict was `GO` for an explicitly conditional diagnostic only.
The post-run verdict is also `GO` for that conditional diagnostic and `STOP`
for any reliable or certified claim.  The missing blocker is (RNC-6): the
complete weighted finite summand has no outward evaluation enclosure for the
retained Faddeeva, exponential-integral, elementary-function, geometry,
density, speed, phase, and derivative evaluations.

The output must therefore retain all of
`FINITE_SPECIAL_FUNCTION_EVAL_ASSUMED_EXACT`,
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`,
`reliable_eval_enclosure_pass=false`, `total_reliable_pass=false`, and
`reliability_certified=false`.

## Pre-run mathematical and code audit

The review checked the following points independently.

- The source Jacobian and the signs are correct.  With the stored second
  density coordinate equal to $-\sigma$, the code evaluates the raw action as
  `mixed_normal*tau-target_normal*eta_second`, then negates that raw regular
  row exactly once in the physical self-minus-regular-minus-off-surface
  defect.
- Source quadrature contains one factor of the source speed.  The target DFT
  uses $P/N/\sqrt P$ for the audited constant-speed circle adapter.  The
  $P$ and $\sqrt P$ factors in the source, target, and Ewald radii agree with
  (RNC-4), (RNC-5), and (RNC-7).
- Reciprocal $|m|<N_R$, nonzero-image $0<|j|<N_I$ with Taylor orders through
  $N_E$, and the retained branch-free local series form the signed center.
  M-R, M-I, M-T, and M-L are separate omissions; M-T begins at $N_E+1$ and
  occurs once.
- The source and target radii use separate one-variable strip arguments.  The
  current circle supplies an exact adapter for the shape-general holomorphic
  speed and arclength hypotheses; no Fourier--Bessel diagonalization enters
  the governing method.
- Retained rows are $|\ell|<L$.  The inherited complete-action strip tail owns
  $|\ell|\ge L$, and the strict $N>2\max\{L,M_\eta\}$ gate excludes a
  Nyquist row.
- The old whole-action zero-center regular radius is removed.  Both the
  nonlinear retained sum and the low-cell row are recomputed after inserting
  the signed regular center.  The high-mode groups and lifting output are
  carried unchanged from a fresh same-run I5.1c function return; no historical
  output is read.

## Post-run audit

The canonical run used $L=256$ and $N=514$, so
$514>2\max\{256,128\}=512$.  Its retained rows are
$-255,\ldots,255$.  The reported regular unit-state radii are

| owner | radius |
|---|---:|
| source quadrature | $6.4335982057355448\times10^{-42}$ |
| target DFT, maximum over retained rows | $7.661073710189474\times10^{-20}$ |
| finite evaluation | $0$ under the explicit conditional assumption |
| M-R | $8.2910496824456709\times10^{-25}$ |
| M-I | $3.4914778993599262\times10^{-11}$ |
| M-T | $2.0529395015278222\times10^{-29}$ |
| M-L | $8.9951561629918053\times10^{-12}$ |
| total, maximum over retained rows | $4.3909935233202631\times10^{-11}$ |

Their stored componentwise sum defect is zero at ordinary floating-point
precision, and every checked radius is finite and nonnegative.  The weighted
regular-center norm is $0.6063210583687928$.  After the local, regular, and
off-surface signed centers are combined within the same material defect, the
weighted center norm is $2.3193123719893792\times10^{-13}$.  This is permitted
same-defect cancellation; it is not cancellation between residual modules.
Because both roundoff and the finite evaluation enclosure are excluded, this
small value is diagnostic rather than certified.

The recomputed material finite and tail squares are

$$
1.9215047644499741,
\qquad
1.1504505415838253,
$$

and hence the conditional diagnostic is

$$
\widehat B_\Upsilon=1.7526994340256401.
$$

The fresh same-run I5.1c value is $3006.7225021204808$, a diagnostic reduction
factor of $1715.4809568315841$.  This reduction is not itself evidence of
reliability and does not enter any stopping rule.

The complete run took $18.21$ seconds and reported a maximum resident set of
$978993152$ bytes, below the planned 15 minutes and 1.7 GiB and the hard
40-minute and 2-GiB limits.  `checkcode` found no issue in either v3 MATLAB
entry.  The persisted audit records unchanged lifting and high-mode groups,
zero forbidden solve counts, false reliable gates, and no historical-output
read.

## Remaining obligation

To promote the conditional diagnostic, implement an outward interval,
Taylor-model, contour, or equivalent enclosure for every finite node summand
in (RNC-6), including all retained special functions and coordinate
derivatives through order two, and repeat an independent review.  Until then
the number above is not a reliable bound, a certified enclosure, or an
instance-level `GO`.
