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
| $\Gamma_-,\Gamma_+$ | center artificial interfaces; their $L$-translates give all artificial interfaces |
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
| artificial-interface normal defect $B_{\Gamma_\pm}$ | current circle instance `GO` within the roundoff-excluded scope | every analytic omission has an explicit formula; the persisted ordinary number excludes floating-point outward rounding |
| material-interface normal defect $B_\Upsilon$ | current circle instance `GO` after `residual-numerator-a1` run-06 | exact-QP Ewald, Maue--Kress source/target quadrature, combined angular tail, and block-power omissions all pass; a different curve still needs its own shape-general geometry certificates |
| value-defect correction $B_{\mathrm{lift}}$ | current circle instance `GO` after `residual-numerator-a1` run-06 | material and artificial-wall value lifts, identity-inclusive fallback, combined angular tail, and block-power omissions all pass; a different curve still needs its own certificates |

Read [[research/projects/eig-apost/phase3-analysis/residual-bound/s-wall-tail|the
artificial-interface module]] first, then
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-lift-tail|the
lifting module]], and
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-material-tail|the
material-normal module]].  The shared shape-general free-space self-action is
proved separately in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-local-panel|the
local-panel theorem]].  The cross-stage context remains
[[research/projects/eig-apost/phase3-analysis/s-estimator]] and
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain]].

The frozen-instance implementation, numerical decomposition, run provenance,
diagnostic interval map, and final `PASS` review are recorded in
[[research/projects/eig-apost/implementation/i5/design-5-1]].  Every displayed
number remains `NON_CERTIFIED_ROUNDOFF_EXCLUDED`; instance-level `GO` here does
not mean a certified eigenvalue enclosure.
