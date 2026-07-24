# Layer potentials and representation nullspaces

## Operators and jumps

For Helmholtz fundamental solution `G_k`, define single and double layers `S_k\sigma` and `D_k\tau`. With one fixed outward normal, their Dirichlet and Neumann traces have the standard `\pm\frac12I` jumps; `D^*_k` and the hypersingular operator `T_k` fill the remaining Calderón blocks. Exact signs must be derived once from the convention used in code/draft.

On a smooth interface,

\[
S_k:H^{-1/2}\to H^{1/2},\quad
D_k:H^{1/2}\to H^{1/2},\quad
D_k^*:H^{-1/2}\to H^{-1/2},\quad
T_k:H^{1/2}\to H^{-1/2}.
\]

At non-Wood regular parameters the QP kernel has the same diagonal singularity as the free-space kernel; their difference is smooth, hence the corresponding boundary-operator difference is compact/smoothing.

## Corrected complementary representation

For matrix wavenumber `k` and inclusion wavenumber `nk`, the exterior representation uses `S^{(k)}` and `D^{(k)}`; the interior uses `S^{(nk)}` and `D^{(nk)}`. The current appendix's use of `D^{(nk)}` in the exterior pair is a model-breaking mismatch and cannot be inherited. The complementary proof swaps the physical roles only in the deliberately constructed auxiliary field, not term-by-term inside one physical representation.

## Three distinct uniqueness questions

1. **Physical PDE uniqueness:** do fixed Cauchy data determine the field?
2. **Field decomposition uniqueness:** is the split into homogeneous Rayleigh and layer fields unique?
3. **Density uniqueness:** can different densities reconstruct the same field?

Only the first is routine. The safe algebra is

\[
\mathcal X_{\rm center}/\ker\mathcal R_{\rm field}
\cong\operatorname{ran}\mathcal R_{\rm field}.
\]

## Nullspace attack

Assume the physical reconstruction is zero. Use jumps to infer relations among densities, construct the complementary swapped-wavenumber fields, and place the boundary vector in intersections/ranges of Calderón projectors. Auxiliary transmission eigenvalues or empty-cell poles may leave a nonzero nullspace. Options are: exclude a discrete set, quotient it, or impose a bounded Calderón side constraint. A small singular value is not proof of a physical mode; Hiptmair--Moiola--Spence show the analogous quasi-resonance danger.

