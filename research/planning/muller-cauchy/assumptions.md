# Assumption ledger

Each theorem must cite assumptions by identifier. Assumptions marked
**temporary** are intended to be discharged by earlier roadmap results rather
than hidden in the main theorem.

## Geometry and coefficients

- **A1 (strip geometry):** `S=R x (0,d)` with fixed real quasiperiodicity
  `beta`; the center region is bounded in `x`.
- **A2 (smooth separated interfaces):** every material interface is a finite
  union of disjoint `C^{2,alpha}` closed curves, separated from cell walls and
  from other interfaces by a positive distance.
- **A3 (TM scalar medium):** `q=n^2` is real, positive, bounded, and
  piecewise constant. TM conditions are continuity of `u` and the physical
  normal derivative.
- **A4 (homogeneous port collars):** a positive-width neighborhood of each
  artificial port contains no material interface. This permits standard weak
  traces and local Rayleigh expansions.
- **A5 (identical leads):** left/right periodic media are reflected/translated
  copies for the first package. This can be removed later.

## Spectral regime

- **A6 (real regular parameter):** `k>0` and `beta` are real and fixed.
- **A7 (strict projected gap):** `k^2` lies strictly outside the fixed-`beta`
  spectrum of the full periodic lead operator. In particular, no propagating
  lead solution belongs to the unit circle.
- **A8 (uniform multiplier separation):** the selected translation/propagation
  operator has stable and unstable spectral clusters separated from each other
  and from `|lambda|=1` by a positive contour distance.
- **A9 (non-Wood):** `gamma_m(k,beta) != 0` for every Rayleigh order used in the
  local homogeneous representation.

`A7` does not by itself identify the exact operator realization in `A8`; Lemma
L4 must prove or precisely cite that implication.

## Exterior relation

- **A10 (half-guide weak well-posedness):** the `H^1_beta` half-guide solution
  space has finite multiplicity for its boundary traces.
- **A11 (closed outgoing relation, temporary):**
  `C_out^± subset H_Gamma` is a closed subspace. Proposition P1 should discharge
  this via the Riesz-basis synthesis theorem.
- **A12 (trace-coordinate injectivity, temporary):** generalized stable
  coefficients synthesize zero Cauchy trace only when all coefficients vanish.
  This is not assumed for ordinary eigenvectors; Jordan chains are included.

## Representation regularity

- **A13 (QP kernel regularity):** the quasiperiodic Green function exists at
  `(k,beta)`; its difference from the free-space singular kernel is smooth on
  the center interfaces.
- **A14 (swapped/complementary uniqueness):** the auxiliary transmission
  problem used to prove density injectivity is uniquely solvable. Its precise
  wavenumber placement, radiation condition, and exceptional discrete set must
  be stated before use.
- **A15 (no empty-cell representation pole):** the homogeneous Rayleigh
  augmentation and QP representation do not introduce an unremoved auxiliary
  kernel. If false, the theorem must use a quotient or side constraint.
- **A16 (corrected representation identity):** all interior formulas use the
  interior wavenumber `nk`, all exterior QP formulas use `k`; the current
  Appendix A occurrence of `D_QP^(nk)[v^-]` in the exterior `k` identity is not
  used.

## Fredholm-only assumptions

- **F1 (square realization):** a quotient domain and compatible codomain/test
  space have been chosen so that `A_rel` is a bounded square operator.
- **F2 (reference isomorphism):** the diagonal Calderón/Müller plus trace
  synthesis reference block is an isomorphism.
- **F3 (compact remainder):** material/QP smooth remainders and cross-port
  couplings are compact in the selected Sobolev topology.

These assumptions are not needed for the quotient-safe fixed-parameter
isomorphism. If `F1--F3` cannot be proved, the roadmap falls back to closed
range/finite-kernel or fixed-truncation results.

## Future discretization assumptions

- **D1:** Nyström projections are stable in a Sobolev-equivalent norm.
- **D2:** Rayleigh truncations converge in the port trace norm.
- **D3:** discrete Riesz projectors converge in subspace gap.
- **D4:** the isolated nonlinear root lies in a branch/pole-free real
  neighborhood.

These are placeholders, not current conclusions.

## Exceptional set policy

The regular set is the strict-gap, non-Wood parameter set after removing any
discrete auxiliary transmission, QP representation, or cell Dirichlet poles
actually required by the proof. Every removed set must be named. “Generic
parameter” is not acceptable without a discreteness argument.

