# Spectral approximation (future work only)

## Three-parameter family

The future lifted operator `\mathcal A_{N,M,h}(k,\beta)` combines boundary Nyström size `N`, Rayleigh cutoff `M`, and a cell/stable-subspace discretization `h`. Convergence of each part must be measured in compatible continuous spaces before a matrix singular value is interpreted spectrally.

## Required convergence ladder

1. boundary operators converge in norm or collectively compact sense;
2. Rayleigh traces converge in weighted norms;
3. stable Riesz projections converge in subspace gap;
4. quotient/side constraints converge without creating near-null algebraic directions;
5. reconstructed fields and six physical residuals converge;
6. analytic operator convergence is uniform on a contour around an isolated root.

Then an operator-valued Rouché/Riesz-projection argument can preserve total algebraic multiplicity. A pointwise plot of `\sigma_{\min}` proves none of these steps.

## No-pollution certificate

A candidate sequence must have normalized nonzero reconstructed fields and residuals tending to zero for: matrix equation, physical PDE/interface, axial quasiperiodicity, both port relations, and cellwise decay. Compactness plus K1 can then identify any regular accumulation point as physical. Representation poles must be excluded or removed before the argument.

## Edge-dependent constants

Expect blow-up proportional to resolvent separation and inverse decay rates. Track at least

\[
\delta_{\rm edge}^{-1},\qquad
\operatorname{sep}(\sigma_s,\sigma_u)^{-1},\qquad
\big(\min_j|\log|\lambda_j||\big)^{-1},\qquad
\delta_{\rm Wood}^{-1}.
\]

No uniform theorem is planned at a threshold or band edge.

