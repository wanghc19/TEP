# I5.1c signed-center residual-numerator experiment

This version instantiates the real-variable bounds (KR-15)--(KR-32) for the
frozen reconstruction without changing the shape-general theorem. The circle
is used only as an explicit geometry-and-series certificate for this instance.
It is separate from v1 and the historical unversioned experiments and never
overwrites their inputs or outputs.

The portable explicit-I/O sequence is:

```matlab
build_residual_numerator_input_v2( ...
  artifact_path, curve_contract_path, wall_finite_squared, ...
  wall_tail_squared, input_path, wall_provenance_label);
residual_numerator_v2(input_path, output_path);
```

The builder loads only the explicit frozen artifact and curve contract. The
accepted wall squares are numeric arguments; the optional provenance label is
descriptive and cannot authorize a value. Runtime evaluation reads only the
self-contained generated input. No executable reads Markdown, Git state, a
repository-relative path, or a historical experiment output.

The local center is the signed retained polynomial Kress action plus the value
or normal identity exactly once. Its radius is the disjoint sum of the
complete-integrand source product-rule remainder, the identity-inclusive
target DFT remainder, and the tail-only kernel-series remainder. The
regular-image action keeps a zero center. Its retained $|\ell|<L$ full-action
radius uses the real-axis Ewald enclosure, while its $|\ell|\ge L$ target
Fourier tail alone uses the width-$0.2$ complex-strip enclosure. These index
sets are disjoint and the two bounds are never added to the same coefficient.
The retained off-surface Rayleigh action has a signed nonzero center and a
separate target-quadrature radius. Local and physical-sign off-surface centers
are combined before absolute values, trace or lifting weights, and propagation
tail summation.

For the exact constant-speed parameterization certificate, each retained local
target row uses the smaller of the KR-19 radius and a direct DFT alias radius

$$
\frac{Q_2P^{3/2}}{4\pi^2}
\sum_{q\ne0}|\ell+qN|^{-2}.
$$

The alias sum keeps the first 64 positive and negative aliases explicitly. For
each omitted side beginning at $q=65$, it uses the first term plus the integral
of the decreasing inverse-square function. This avoids a cancellation-prone
cosecant identity and remains fail-closed unless $|\ell|<N/2$, the constant
speed gate holds, and $Q_2$ is finite.

The builder first chooses $L$ from the predeclared $32,64,128,256$ complete
local-plus-regular-plus-off-surface omission-tail schedule. If no tolerance
passes, it selects the final finite candidate and records the failed tightness
allocation. It then considers $N_0,2N_0,4N_0$, where
$N_0=2\max\{L,M_\eta\}+2$. A candidate is selected only from analytic
retained-row radii. If the $N$-independent regular-image radius already exceeds
the tolerance, the first candidate is retained and the tightness failure is
reported instead of spending memory on ineffective refinement. No grid drift,
convergence plateau, Richardson extrapolation, or empirical safety factor
participates in either decision.

Generated inputs belong in `input/`; the first scientific attempt writes only
under `output/residual-numerator-a1/`. The planned complete run budget is at
most 8 minutes and 1.6 GiB peak memory. MATLAB must not be run before the
independent pre-run review returns `GO`.

Every ordinary floating-point output is labelled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`. Eigenpair, density, QZ, and propagation solve
counts must all remain zero.

## Completed scientific attempt

`output/residual-numerator-a1/` contains one scientific attempt with three
bounded implementation revisions.  All used the same frozen candidate,
density, QZ-selected states, propagation matrices, Rayleigh data, and accepted
wall scalars.  They did not solve any of those problems again.

The final `result-run-03.mat` and `audit-run-03.txt` select $L=256$ and
$N=514$ and report

| component | bound |
|---|---:|
| $\widehat B_{\Gamma_\pm}$ | $1.8732039079101324\times10^{-10}$ |
| $\widehat B_\Upsilon$ | $3006.7225021204808$ |
| $\widehat B_{\mathrm{lift}}$ | $748498.34329471563$ |
| $\widehat{\mathcal M}$ | $751505.06579683628$ |

The material finite and tail squares are $9040379.054306915$ and
$1.1504507314502783$.  The lifting finite and tail squares are
$140060464291.15997$ and $1978187.5735129558$.  All 33 required-true gates and
all four required-false gates pass, all solve counts are zero, and the audit
finds no nonfinite value or negative radius among 205830 checked entries.

The run is mathematically and numerically valid but not tight: retained-radius,
material-tail, and lifting-tail allocations all fail.  The priority status is
`RETAINED_RADIUS_TOLERANCE_FAILED_ORDINARY`.  The dominant retained floor is
the zero-centered regular-image normal radius $1094.7813067510401$, so merely
increasing $N$ is not a valid remedy.

Run-01, run-02, and their inputs and audits are retained for provenance.  A
read-only run-02 diagnostic initially queried a nonexistent field; the failed
`audit-run-02.txt` and corrected `audit-run-02-corrected.txt` are both kept.
The underlying run-02 result was successful.  Cross-run changes are diagnostic
only and are not stopping or reliability evidence.
