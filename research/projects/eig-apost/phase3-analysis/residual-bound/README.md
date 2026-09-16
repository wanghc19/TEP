# Continuous residual-numerator bounds

## Scope and authority

This directory studies reliable upper bounds for the continuous residual dual
norm of one reconstruction determined by frozen finite data.  The frozen data
include the candidate wavenumber, BIE density coefficients, selected QZ
subspaces, propagation matrices, Rayleigh coefficients, reconstruction rule,
geometry, and material parameters.  Their generation and proximity to an
unknown exact eigenfunction are outside the present question.

The only target is the numerator $\|R\|_{\mu,*}$.  The following are excluded:
the reconstructed-field lower bound, the quotient $q$, spectral gaps,
essential spectrum, multiplicity or mode counting, target-eigenvalue
identification, floating-point outward rounding, effectivity, FEM-reference
accuracy, and a complete eigenvalue enclosure.

The notation below is a one-time textual snapshot of the requested Chinese
draft as inspected on 2026-09-06.  It is copied and frozen here: this directory
has no live link to that draft, and later draft changes do not change these
symbols.  The notation governs only this `residual-bound/` directory.  It does
not redefine notation elsewhere in Phase 3 or in historical implementation
files.  A module may introduce local symbols only after saying so explicitly;
it may not silently redefine the common symbols below.

## Common symbols

| symbol | meaning |
|---|---|
| $B=\mathbb R\times(-d/2,d/2)$ | infinite strip with transverse quasiperiod $d$ |
| $K$ | one material subregion used in broken integration by parts |
| $d_x=X_R-X_L$ | longitudinal cell width; code artifact field `z.L` is unchanged |
| $\Gamma_-,\Gamma_+$ | center artificial interfaces; their $d_x$-translates give all artificial interfaces |
| $\Sigma$ | one generic artificial interface, counted once |
| $\Upsilon$ | union of all material interfaces |
| $\beta$ | fixed transverse Bloch parameter |
| $\widehat k$ | frozen candidate wavenumber |
| $\mu=\widehat k^2$ | shifted energy parameter; I5 code alias `mu_shift` |
| $\rho$ | frozen piecewise-constant material coefficient |
| $\beta_m=\beta+2\pi m/d$ | transverse wavenumber of Rayleigh order $m$ |
| $\psi_m(y)=d^{-1/2}e^{\mathrm i\beta_my}$ | normalized Rayleigh/Fourier trace basis |
| $\gamma_m^2=\widehat k^2\rho_e-\beta_m^2$ | outgoing/decaying longitudinal Rayleigh wavenumber; I5 code alias `rayleigh_wavenumber` |
| $V_\beta=H^1_\beta(B)$ | quasiperiodic energy test space |
| $\|v\|_\mu^2=a(v,v)+\mu b(v,v)$ | shifted energy norm, with $a(u,v)=\int_B\nabla u\cdot\nabla\overline v$ and $b(u,v)=\int_B\rho u\overline v$ |
| $u_{h,M}$ | broken exact-kernel field defined by the frozen finite coefficients |
| $e$ | fixed value-defect correction formed by the chosen trace right inverses |
| $\widehat u=u_{h,M}+e$ | continuous compatible reconstructed field |
| $P_\varsigma,c_\varsigma$ | full propagation matrix and starting state, $\varsigma\in\{-,+\}$ |
| $\eta=(\tau,-\sigma)^{\mathsf T}$ | double- and single-layer density coordinate |
| $N_\eta$ | original node count used to represent the frozen density |
| $M_\eta$ | largest absolute Fourier degree present in the frozen density |
| $L$ | residual Fourier cutoff: retained rows satisfy $|\ell|<L$ |
| $N$ | Kress and target-DFT evaluation node count, with $N>2\max\{L,M_\eta\}$ |
| $g(t-u)=\log(4\sin^2((t-u)/2))$ | periodic Kress logarithm for a $2\pi$ parameter |
| $K^\chi=K_1^\chi g+K_2^\chi$, $\chi\in\{\mathrm{val},\mathrm{nor}\}$ | complete density- and Jacobian-inclusive Kress integrand for the value or normal defect |
| $S_{\kappa,j}$ | bare single-layer Kress factor, $j\in\{1,2\}$ |
| $D_{\kappa,j}$, $D_{\kappa,j}^*$ | bare source-normal and target-normal Kress factors |
| $C_{\kappa,j}^{\mathrm{tan}}$ | bare Maue tangential auxiliary Kress factor |
| $K_j^{T_e-T_i}$ | complete Maue-regularized split of $T_e-T_i$; the normal residual uses $T_i-T_e=-(T_e-T_i)$ |

The common cotangent term is cancelled in the exterior-minus-interior Maue
split before absolute values are taken.  The symbols above name theory
objects only; existing MATLAB function and field names are unchanged and are
mapped in `implementation/i5/SYMBOL.md`.

For $v\in V_\beta$, define

$$
R(v)=a(\widehat u,v)-\mu b(\widehat u,v),
$$

and

$$
\|R\|_{\mu,*}
=\sup_{0\ne v\in V_\beta}\frac{|R(v)|}{\|v\|_\mu}.
$$

The exact finite input convention never removes later evaluation errors.
Quadrature, special-function truncation, omitted Fourier or angular modes,
half-guide tails, and lifting constants must each receive an explicit bound.
Ordinary floating-point results are labelled non-certified because outward
rounding is outside the present scope.

All theorems in this continuation are formulated for separated regular
parameter curves and do not use circular Fourier/Bessel diagonalization,
radial collars, or finite-support self-action.  Numerical evaluation is
intentionally restricted to the existing circular frozen instance near
$\widehat k=1.85$; no star-shaped test instance or star density is generated.

## Strong residual components

The raw exact-kernel construction satisfies, in every material subregion,

$$
r_K=(-\Delta-\mu\rho_K)u_{h,M}=0.
$$

Choose the two outward normals of cells adjacent to $\Sigma$.  On each
material interface let $\nu$ point from its interior to its exterior, and write
$u^{\mathrm{in}},u^{\mathrm{out}}$ for the corresponding traces.  The normal
defects are

$$
j_\Sigma
=\partial_{\nu_1}u_{h,M}^{(1)}|_\Sigma
+\partial_{\nu_2}u_{h,M}^{(2)}|_\Sigma,
$$

$$
j_\Upsilon
=\partial_\nu u_{h,M}^{\mathrm{in}}|_\Upsilon
-\partial_\nu u_{h,M}^{\mathrm{out}}|_\Upsilon.
$$

If $g_\Sigma$ is the frozen shared Dirichlet trace, define the two artificial
interface value defects and the material value defect by

$$
a_{\Sigma,r}=u_{h,M}^{(r)}|_\Sigma-g_\Sigma,
\qquad r\in\{1,2\},
$$

$$
a_\Upsilon
=u_{h,M}^{\mathrm{out}}|_\Upsilon
-u_{h,M}^{\mathrm{in}}|_\Upsilon.
$$

The fixed correction $e$ cancels all these defects.  Integrating only
$u_{h,M}$ by parts gives

$$
R(v)
=\sum_\Sigma\langle j_\Sigma,v|_\Sigma\rangle
+\sum_\Upsilon\langle j_\Upsilon,v|_\Upsilon\rangle
+R_{\mathrm{lift}}(v),
$$

where

$$
R_{\mathrm{lift}}(v)=a(e,v)-\mu b(e,v).
$$

The corresponding three control quantities are $B_{\Gamma_\pm}$,
$B_\Upsilon$, and $B_{\mathrm{lift}}$.  The complete correction form belongs
to $B_{\mathrm{lift}}$; derivatives of $e$ are not counted again in either
normal-defect module.  Thus

$$
\|R\|_{\mu,*}
\le\mathcal M
:=B_{\Gamma_\pm}+B_\Upsilon+B_{\mathrm{lift}}.
$$

No cancellation between the three terms is used to reduce this majorant.

## Closure status and reading order

| module | current status | precise boundary |
|---|---|---|
| artificial-interface normal defect $B_{\Gamma_\pm}$ | frozen instance `GO` in the roundoff-excluded fallback | I5.1e attempt 7 rebuilds every wall row directly and gives $890.77255515519369$; historical evaluated wall residuals do not enter the bound |
| material-interface normal defect $B_\Upsilon$ | frozen instance `GO`; tightness `PASS` in the roundoff-excluded fallback; smaller signed-centre value conditional | the coefficientwise-density, mode-dependent zero-centre I5.1e bound is $28500.152577876961$; streamed I5.1h gives the conditional ideal value $5.9741385647183627\,10^{-7}$ |
| value-defect correction $B_{\mathrm{lift}}$ | minimum-energy theorem `GO`; two-band fallback `GO`; frozen signed-centre instance conditional | I5.1g proves the factor-one comparison; I5.1h gives the conditional ideal value $8.7769248875529515\,10^{-6}$, while $\Delta_{\mathrm{sf}}$ and $\Delta_{\mathrm{fp}}$ remain unresolved and the reliable roundoff-excluded fallback remains I5.1e at $58518.118987325186$ |

The resulting smallest reviewed fallback is
$\mathcal M=87909.044120357343$.  It is a theorem upper for the exact frozen
inputs with ordinary arithmetic rounding excluded, not an outward-rounded
certificate; its preallocated omission-tail tightness tolerance passes.

Read [[research/projects/eig-apost/phase3-analysis/residual-bound/s-wall-tail|the
artificial-interface module]] first, then
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail|the
lifting module]], and
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail|the
material-normal module]].  The shared shape-general free-space self-action is
proved separately in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-local-panel|the
local-panel theorem]].  The accepted replacement for the failed P32
target-strip step, together with
the assembled conditional numerator theorem, is
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-kress-real|the
real-variable Kress bound]].  Its shape-general nonzero regular-image theorem
is instantiated conditionally by
[[research/projects/eig-apost/implementation/i5/design-5-1d|I5.1d]].  The
library-independent zero-centre fallback, its mode-dependent refinement, the
direct wall reconstruction, and the first complete roundoff-excluded reliable
frozen-instance majorant are recorded in
[[research/projects/eig-apost/implementation/i5/design-5-1e|I5.1e]], with
the independent verdict in
[[research/projects/eig-apost/implementation/i5/review-5-1e|review-5-1e]].
The I5.1e tightness allocation fails, so that result is reliable but very
wide.  The cross-stage context remains
[[research/projects/eig-apost/phase3-analysis/s-estimator]] and
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain]].

The frozen-instance implementation, numerical decomposition, run provenance,
diagnostic interval map, and the later P32 audit that supersedes the earlier
instance-level `PASS` are recorded in
[[research/projects/eig-apost/implementation/i5/design-5-1]].  Every displayed
number remains `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.  The failed P32 product-strip
route is not an obligation of the replacement theorem.  The I5.1c
nonzero-center theorem, implementation choices, and current frozen-instance
numbers are recorded in
[[research/projects/eig-apost/implementation/i5/design-5-1c|design-5-1c]],
with the independent review in
[[research/projects/eig-apost/implementation/i5/review-5-1c|review-5-1c]].
Those results instantiate the finite inequality only under the documented
real-arithmetic primitive-enclosure assumptions.  They are neither
outward-rounded certificates nor evidence that the predeclared tightness
allocations pass.

### I5.1f conditional signed-centre continuation

The separately reviewed
[[research/projects/eig-apost/implementation/i5/design-5-1f|I5.1f design]] and
[[research/projects/eig-apost/implementation/i5/review-5-1f|independent review]]
retain all analytic omissions while restoring signed physical centers.
The v5 canonical run selects $L=512$, $N=2048$ from explicit remainders and
gives the ordinary computed scalar $\mathcal M_{\mathrm{ideal}}
=0.056448305344888337$.  This is
`CONDITIONAL_ON_EXACT_SPECIAL_FUNCTION_EVALUATION`, not a replacement for
the reliable fallback: the governing conclusion is only
$\|R\|_{\mu,*}\le\mathcal M_{\mathrm{ideal}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$, with both deltas `UNRESOLVED`.
The independent post-run review passes the user's first phase-2 gate
$\mathcal M_{\mathrm{ideal}}<1$.  No denominator or eigenvalue statement is
made.  The failed P32 argument is not used.

The subsequent restricted sensitivity replay bounds the final-functional
increment from retained Faddeeva/$E_1$ errors by
$A_F\varepsilon_F+A_E\varepsilon_E$, with ordinary gains
$A_F=3.0944383348174293\,10^7$ and $A_E=2.4261737348658184\,10^5$.
The review verdict is `PASS WITH CONDITIONS / PARTIAL FEASIBILITY GO`:
actual oracle errors, the remaining primitive-family increment, and
floating-point errors are still unresolved.  This partial replay does not
upgrade the v5 conditional scalar to a reliable numerator bound.

Two further independently reviewed replays isolate the local positive
gamma-log/exponential certificate and the regular-image gamma-log composite,
including its affected downstream logarithms and exponentials.  Their
prospective contracts give the conditional subtotal
$0.06077107308056649+\Delta_{\mathrm{sf,rest3}}+\Delta_{\mathrm{fp}}$.
No actual oracle-error contract or complete remaining-family enclosure has
been supplied.  The final review therefore passes the partial results and
explicitly stops any claim of a complete reliable numerator certificate.

### I5.1g minimum-energy lifting continuation

The shape-general minimum-energy lifting theorem is proved in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail|the
lifting module]] and mapped to code in
[[research/projects/eig-apost/implementation/i5/design-5-1g|I5.1g]].  It uses
one simultaneous jump map, a single product-space Cauchy--Schwarz inequality,
and two-sided harmonic comparison weights.  Thus the old outer factor two is
replaced by one, while the estimator is independent of an arbitrarily fixed
lifting profile.  The general-curve weight has linear high-mode growth and
does not use circular Fourier--Bessel diagonalization.

The v6 canonical run selected $L=256$, $N=1024$ solely from explicit
remainder allocations and obtained

$$
\widehat B_{\Gamma_\pm}=1.8732119857082978\,10^{-10},\quad
\widehat B_\Upsilon=1.5565169597620056\,10^{-4},\quad
\widehat B_{\mathrm{lift}}^{\mathrm{ME}}=0.033621248621896728,
$$

and $\mathcal M_{\mathrm{ideal}}=0.033776900505194128$.  This is a
`CONDITIONAL_IDEAL_MAJORANT_COMPLETE_SF_FP_UNRESOLVED` result:

$$
\|R\|_{\mu,*}\le
\mathcal M_{\mathrm{ideal}}+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}.
$$

Both deltas remain unresolved.  The independent
[[research/projects/eig-apost/implementation/i5/review-5-1g|I5.1g review]]
therefore returns `PASS WITH CONDITIONS / GO` for the conditional ideal
result and `STOP` for a reliable or certified claim.  The complete persisted
decomposition is in `test/i5/residual-numerator-v6/README.md`.

### I5.1h signed-band recapture continuation

The full signed-jump $p=6/8$ theorem and the fail-safe two-band $p=4$
substitution are proved in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail|the
lifting module]] and implemented by
[[research/projects/eig-apost/implementation/i5/design-5-1h|I5.1h]].  The
current full-$p=6$ instance remains blocked at the first missing order-six
regular-image Ewald derivative/tail certificate.  The two-band fallback does
not use that missing certificate: it retains $|\ell|<256$, computes the
signed band $256\le|\ell|<L_1$, and applies the existing componentwise $p=4$
tail only to $|\ell|\ge L_1$.

The streamed v7 attempt 3 selects $(L_1,N)=(1024,16384)$ solely from explicit
far-tail and retained-radius allocations and obtains

$$
(\widehat B_{\Gamma_\pm},\widehat B_\Upsilon,
\widehat B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})
=(1.8732040521480924\,10^{-10},
5.9741385647183627\,10^{-7},
8.7769248875529515\,10^{-6},
9.3745260644300025\,10^{-6}).
$$

The independent
[[research/projects/eig-apost/implementation/i5/review-5-1h|I5.1h review]]
returns `PASS` for the theorem and implementation, `PASS WITH CONDITIONS / GO`
for this conditional ideal instance, and `STOP` for a reliable or certified
claim.  The governing statement remains
$\|R\|_{\mu,*}\le\mathcal M_{\mathrm{ideal}}
+\Delta_{\mathrm{sf}}+\Delta_{\mathrm{fp}}$, with both deltas unresolved.

### I5.1j real-variable lifting continuation

The independently reviewed
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-real-interpolation|real-variable interpolation theorem]]
replaces only the material value-jump Fourier evaluation by a shape-general
piecewise-linear $H^1$ comparison bound.  Its implementation contract is
[[research/projects/eig-apost/implementation/i5/design-5-1j|I5.1j]].  No
material value-jump Fourier coefficient, material cutoff, material Fourier
tail, target DFT, or target FFT occurs in the new evaluator; the artificial-
wall Rayleigh representation is unchanged.  The theorem is `GO` under exact
signed endpoint and first-derivative panel row balls.  The reviewed run 04
selects $N=514$ and gives
$B_{\mathrm{lift}}^{\mathrm{RI}}=1268.5132354323696$ and
$\mathcal M_{\mathrm{RI,ideal}}=1268.5132360299708$.  This is a
`PASS WITH CONDITIONS` conditional ideal majorant and a tightness `STOP`, not
a fully reliable bound: $\Delta_{\mathrm{sf}}$ and
$\Delta_{\mathrm{fp}}$ remain unresolved.  The dominant term is the
$d_j=0$ global first-derivative radius, so increasing $N$ is not recommended;
the shortest next step is a nonzero signed derivative center with complete
panel balls.
