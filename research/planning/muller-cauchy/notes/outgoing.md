# Outgoing Cauchy relations

## Primary object

For a half-guide,

\[
\mathcal C_{\rm out}=\{(\gamma_Du,\gamma_Nu):u\in\mathcal U_{\rm out}\}
\subset H^{1/2}_\beta\times H^{-1/2}_\beta.
\]

This closed subspace is coordinate-free. A DtN map exists only when the Dirichlet projection is bijective. An RtR map exists when a Robin projection is bijective. Thus a Dirichlet pole is a chart singularity, while a failure of the full relation is a more serious physical/spectral issue.

## Closedness routes

- **Estimate route:** show trace convergence gives uniform local `H^1` estimates, pass to a weak half-guide solution, then use uniqueness to obtain strong trace closure.
- **Riesz route:** after P1, write `\mathcal C_{\rm out}=\operatorname{ran}Q`; a bounded-below Riesz synthesis has closed range.

The Riesz route is cleaner but depends on adapting Hohage--Soussi. The estimate route should be retained to avoid circularity.

## Coordinate charts

If `\pi_D|_\mathcal C` is invertible,

\[
\Lambda=\pi_N(\pi_D|_\mathcal C)^{-1},\qquad
\mathcal C=\operatorname{graph}\Lambda.
\]

For Robin data `r_\pm=\gamma_Nu\pm i\eta\gamma_Du`, an RtR operator maps an incoming chart to an outgoing chart. Neither representation changes the underlying subspace.

## What must be proved for coupling

1. `Q^\pm` synthesizes complete Cauchy pairs, not only Dirichlet traces.
2. It is injective or its coefficient kernel is quotiented.
3. Left/right outward-normal conventions are embedded consistently.
4. The relation is stable under the fixed regular parameter assumptions.

