# Bloch translation operator

## Continuous definition before matrices

Translate a half-guide solution by one transverse cell and then take the next-cell Cauchy trace. Through a trace isomorphism this defines `T^\pm` on a Hilbert trace space. A one-cell propagation operator, scattering pencil, transfer matrix, or ordered-QZ pair is a realization of this object, not its definition.

## Strict-gap implication

If a multiplier `\lambda=e^{i\alpha L}` lies on the unit circle, `\alpha` is real and produces a propagating/bounded Bloch solution of the perfect lead. Therefore a genuine fixed-`\beta` projected gap excludes such multipliers, subject to matching the operator's spectrum to the Bloch dispersion relation. Riesz contours then define

\[
P_s=\frac{1}{2\pi i}\int_{\Gamma_s}(z-T)^{-1}\,dz.
\]

The separation constant controls all later conditioning and must remain explicit.

## Jordan chains

For a chain `v_0,\dots,v_{m-1}`, translation is a Jordan block, so cell dependence includes polynomial factors multiplying `\lambda^n`. If `|\lambda|<1`, these still decay exponentially after a slightly weakened rate. Omitting associated vectors makes the expansion incomplete at defective multipliers.

Hohage--Soussi Theorem 2.2 supplies the target Riesz basis statement, including a trace basis when the boundary trace problem is well posed. The adaptation audit must match coefficient regularity, wall/axial quasiperiodicity, transmission interfaces, and the chosen two-component trace.

## Numerical consequence (planning only)

Ordered QZ should select a cluster, not individual eigenvectors. Accuracy is measured by principal angles/gaps of stable subspaces. Repeated or near-defective multipliers are stress tests, not cases to discard.

