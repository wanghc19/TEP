# Problem statement and source reconstruction

## Source and context

The source is `draft/draft.tex`, especially the model in lines 75--180, the
homogeneous Rayleigh discussion in lines 486--522, and the single-cell
representation in lines 523--622.  The conjecture is used immediately before a
Muller-type interface equation and subsequent matching of the two vertical-port
Cauchy traces to outgoing Bloch trace spaces.

The project model is the scalar two-dimensional Helmholtz equation for the TM
polarization.  The background index is 1, the inclusion index in the center
cell is denoted by `n` (elsewhere `n^0`), and both the field and its ordinary
normal derivative are continuous across the material interface.  The cell is

```text
C = [X_L,X_R] x [0,d],   Omega compactly contained in C,
```

with Bloch phase `exp(i beta d)` across the horizontal sides.  No condition is
imposed on the vertical sides in Conjecture 1.

## Exact Conjecture 1 as written

The following is a transcription of `draft/draft.tex`, lines 583--622, with
only Markdown/LaTeX delimiter changes:

> **Conjecture (Exact and unique single-cell representation).** Let
> \(\mathcal C=[X_\mathrm{L},X_\mathrm{R}]\times[0,d]\) be a periodic cell
> containing an inclusion \(\Omega\), and assume that \((k,\beta)\) is not at
> a Wood anomaly.
>
> Every sufficiently regular field \(u\) satisfying
> \[
> \begin{cases}
> \Delta u+k^2u=0 & \text{in }\mathcal C\setminus\overline\Omega,\\
> \Delta u+(nk)^2u=0 & \text{in }\Omega,\\
> u|_{y=d}=e^{i\beta d}u|_{y=0},\quad
> \partial_yu|_{y=d}=e^{i\beta d}\partial_yu|_{y=0},\\
> u,\ u_\nu\text{ are continuous across }\partial\Omega,
> \end{cases}
> \]
> with no boundary condition imposed on the vertical boundaries
> \(\Gamma_L\) and \(\Gamma_R\), admits a unique representation
> \[
> u(x)=
> \begin{cases}
> S_{\rm QP}^{(k)}[\sigma](x)+D_{\rm QP}^{(k)}[\tau](x)+u_h[\xi](x),
> &x\in\mathcal C\setminus\overline\Omega,\\
> S^{(nk)}[\sigma](x)+D^{(nk)}[\tau](x),&x\in\Omega,
> \end{cases}
> \]
> where the Rayleigh--Bloch series defining \(u_h[\xi]\) converges in the
> appropriate \(H^1\) sense.

Immediately before the conjecture, the source defines

\[
u_h[\xi](x,y)=\sum_{m\in\mathbb Z}\xi_m^\rightarrow
e^{i\gamma_m(x-X^-)}\psi_m(y)
+\sum_{m\in\mathbb Z}\xi_m^\leftarrow
e^{-i\gamma_m(x-X^+)}\psi_m(y),
\]

where \(\beta_m=\beta+2\pi m/d\),
\(\psi_m=d^{-1/2}e^{i\beta_my}\), and
\(\gamma_m^2=k^2-\beta_m^2\) with \(\operatorname{Im}\gamma_m\geq0\).
The source calls \(\gamma_m=0\) a Wood anomaly.  It defines the layer kernels
using \(G_k=(i/4)H_0^{(1)}(k|x-y|)\), the normal at the source point, and the
vertical-periodic quasiperiodic image sum.

## Unresolved meanings in the source statement

The source does not yet specify:

1. the regularity and topology of `Omega` and whether it stays a positive
   distance from all four cell sides;
2. whether `k`, `n`, and `beta` are real, positive, or possibly complex;
3. the precise piecewise Sobolev solution space and the weak meaning of the
   Neumann trace;
4. whether the displayed quasiperiodic kernel uses the phase consistent with
   the field convention in both source and target variables;
5. the density spaces for `sigma` and `tau`;
6. the precise trace and normal-derivative jump convention;
7. whether the same two densities and the same signs in the exterior and
   interior are intentional or only shorthand for a Muller ansatz;
8. which weighted sequence space makes the two-sided Rayleigh series converge
   in `H^1` on the whole closed cell;
9. whether uniqueness means uniqueness of the physical field, the pair of
   component fields, the density pair, or the coefficient pair;
10. whether frequencies causing interior layer-potential nullspaces or loss of
    invertibility of the forced Muller operator are excluded;
11. how the claim treats `Omega = emptyset`, for which only `u_h` remains; and
12. whether a threshold mode at `gamma_m=0` is to be represented by the correct
    ODE basis `1` and `x`, rather than by two coincident exponentials.

## Precise questions to be decided

The investigation will separate the following maps and claims:

- **Field existence:** every admissible transmission field belongs to the sum
  of the homogeneous-background field space and the interface-potential field
  space.
- **Directness of the sum:** the two field spaces have zero intersection.
- **Density injectivity:** a layer-potential field determines `(sigma,tau)`.
- **Rayleigh-coordinate injectivity:** a homogeneous field determines `xi`.
- **Muller equivalence:** the common-density ansatz is equivalent to the PDE
  problem, rather than merely sufficient for producing some PDE solutions.

The word "unique" in the original conjecture is not accepted until all five
questions have been answered separately.

