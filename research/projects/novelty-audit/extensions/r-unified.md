# Prior-art audit of a unified BIE--Bloch-trace formulation

## What “unified” would have to mean

A defensible unification must preserve more than symbols. It should use the
same line-defect geometry, central Müller representation, periodic-lead Cauchy
data object, operator-valued nonlinear equation, field reconstruction, and
root certification. Guided modes should occur as real-sheet zeros, resonances
as outgoing-sheet zeros, and a threshold as a degeneration/branch point of the
lead relation rather than as an ordinary third label.

Four levels must be distinguished:

1. **formal:** the same block matrix can be written after substituting different
   bases;
2. **operator-theoretic:** the blocks are restrictions/limits of one Fredholm or
   meromorphic relation family;
3. **numerical:** one implementation tracks the correct sheets and remains
   stable;
4. **radiation-condition:** the selected solution agrees with the physical LAP.

The current project has a plausible formal skeleton, but not levels 2--4.

## Candidate relation

Let `C_+(k,beta)` denote the Cauchy data at the right port that extend to the
physical half-guide. A desired family would have four regimes:

- inside a projected gap: the stable trace subspace, a graph when its Dirichlet
  projection is invertible;
- in a regular propagation band: outgoing propagating traces selected by flux
  plus evanescent stable traces;
- at complex frequency: the continuation of that physical subspace from an
  absorptive/passive base point on a declared sheet;
- at a threshold: a limiting linear relation containing generalized or
  polynomial Bloch traces.

Writing a Cauchy/Calderón subspace or linear relation is preferable to forcing a
single-valued DtN map. It survives a singular Dirichlet projection and makes
basis changes harmless. Nevertheless, it does not automatically exist or vary
analytically at a branch point.

## Closest prior art and remaining gap

- Fliss and successors give exact periodic-outlet DtN/RtR truncations and
  real-frequency radiation conditions, chiefly under gap or nondegeneracy
  assumptions.
- Hohage--Soussi and Zhang supply generalized Floquet/Jordan decompositions and
  meromorphic multiplier-plane contour representations.
- Shipman--Venakides use analytic second-kind boundary-integral projections to
  put real slab bound states and complex slab resonances on one dispersion set.
- Li--Lu and later fiber/waveguide BIE papers compute leaky modes with exact
  boundary maps or second-kind BIEs.
- Nazarov supplies a true threshold/virtual-level classification with weighted
  spaces and polynomially growing almost-standing waves.
- Bykov--Doskolovich, Beyn, Binkowski, Mai--Lu, and Perrussel--Poirier show that
  contour/rational solution of photonic/scattering/BEM NEPs is established.

No verified source in the present search combines all of these in the current
infinite periodic-half-lead line-defect geometry. Conversely, almost every
component is established, so an overly broad title has a high “assembly of
known tools” risk.

## What cannot be globally unified without cases

- Rayleigh points `gamma_m=0` and Bloch multiplier collisions are branch points,
  not ordinary isolated eigenvalues.
- A passive QNM under `exp(-i omega t)` has `Im omega<0` and can grow spatially;
  a decaying `|lambda|<1` rule can select the wrong sheet.
- Fixed-real-`beta`/complex-`omega` and fixed-real-`omega`/complex-propagation
  problems are different slices. A complex propagation constant can describe a
  laterally decaying complex mode rather than a leaky mode.
- Different absorption models can select different LAP limits unless the
  material/time model and nondegeneracy hypotheses are fixed.
- A contour NEP needs a holomorphic/meromorphic matrix inside the contour. A
  contour crossing a branch cut or an adaptive SVD/pseudoinverse is not covered
  by Beyn-type theory.

## Minimal provable version

The smallest credible unification excludes exact thresholds and Wood points.
Fix real `beta`, the `exp(-i omega t)` convention, and a simply connected
complex-`k` domain on one outgoing sheet. Prove that:

1. the central Müller block and a relation-valued periodic-lead projector form
   a Fredholm analytic/meromorphic pencil;
2. its real zeros in a projected gap reconstruct guided modes;
3. its lower-half-plane zeros reconstruct outgoing resonant states;
4. representation and cell poles are separated from physical zeros by field
   reconstruction and residue tests;
5. a contour method finds all zeros in a branch-free domain.

The threshold is then a boundary/limiting study in a second paper. A third paper
could add the exact limiting relation and guided-to-resonance continuation.

## Prior-art verdict

The exact advertised title is **not verified as already solved**, but it is also
**not safe as a single-paper novelty claim**. The closest overlap is
Shipman--Venakides for unified BIE bound/resonant slab modes, Li--Lu for leaky
photonic-crystal waveguides, and Fliss/Hohage/Zhang/Nazarov for periodic-lead
and threshold theory. Novelty, if any, must be stated as the branch-consistent
periodic-half-lead relation plus spurious-free coupling and certification—not
as the first BIE, first leaky-mode solver, or first unified dispersion equation.

