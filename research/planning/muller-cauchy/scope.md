# Frozen first-phase scope

## Research question

For a fixed real pair `(k,beta)` in a strict projected gap, can the central-cell
Müller representation and the two outgoing generalized-Bloch Cauchy relations
be coupled so that algebraic kernel classes are in one-to-one correspondence
with global guided fields, with no representation-induced physical roots?

The phrase **spurious-free** means a theorem about the reconstruction map. It
does not follow merely from a second-kind matrix, a small singular value, or a
successful field plot.

## Included

- two-dimensional scalar Helmholtz transmission problem;
- TM polarization: `u` and its physical normal derivative are continuous;
- real, positive, piecewise-constant refractive index;
- finitely many smooth inclusions in the center cell and smooth inclusions in
  the periodic lead cell;
- inclusion boundaries of class at least `C^{2,alpha}` and separated from cell
  walls by a positive distance;
- one fixed real quasiperiodicity `beta` in a chosen Brillouin zone;
- one real spectral parameter `k>0` at a time;
- `k^2` strictly inside a fixed-`beta` projected spectral gap of the lead;
- no Rayleigh/Wood anomaly;
- stable and unstable multiplier clusters uniformly separated from the unit
  circle and from each other;
- identical left/right leads in the first proof package;
- a finite center defect region with homogeneous collars around the ports;
- generalized Bloch modes and Jordan chains wherever multipliers are
  defective;
- a relation-valued exterior object as primary; DtN is only a regular graph
  coordinate.

## Excluded

- exact band edges, zero group velocity, or `|lambda|=1`;
- complex frequency, leaky resonances, resolvent sheets, and BICs;
- Wood anomalies and grazing Rayleigh channels;
- three-dimensional/full-vector Maxwell equations;
- nonsmooth corners, touching inclusions, and high-contrast limit processes;
- material loss, gain, or dispersive refractive indices;
- different left/right periodic leads in the first theorem;
- numerical implementation or new MATLAB experiments.

These exclusions control the first paper. They do not assert that excluded
problems are unimportant or impossible.

## Three theorem levels

### Level A0: quotient-safe kernel--field equivalence

On a declared regular set, the reconstruction map induces a natural linear
isomorphism

```latex
\ker \mathcal A_{\rm rel}(k,\beta)
/\mathcal N_{\rm rep}(k,\beta)
\cong
\mathcal G(k,\beta).
```

This is the first hard deliverable. It separates physical soundness from
density uniqueness.

### Level A1: unquotiented spurious-free equivalence

If the complementary/swapped transmission problem is uniquely solvable and
the generalized trace coordinates are injective, prove

```latex
\ker \mathcal A_{\rm rel}(k,\beta)
\cong
\mathcal G(k,\beta).
```

This preserves geometric multiplicity at fixed `(k,beta)`. Nonlinear algebraic
multiplicity is not claimed at this stage.

### Level B: Fredholm enhancement

After choosing a square quotient/test-space realization, prove Fredholm index
zero. This is desirable for isolation and perturbation theory, but it is not
logically necessary for the fixed-parameter kernel isomorphism.

### Level C: future spectral correctness

Plan high-order Nyström, Rayleigh, and stable-subspace approximation with
convergence of isolated roots and no spectral pollution. This level is a
future project, not a completion condition for the continuous roadmap.

## Novelty boundary

Directly citable ingredients include Fliss global/bounded equivalence,
Hohage--Soussi generalized Floquet/Jordan bases, Zhang generalized-mode DtN
approximation, classical Müller/Calderón mapping, and Barnett--Greengard's
quasiperiodic representation architecture. The potentially new intersection
is a rigorously reconstructed, relation-valued, interface-only center--lead
kernel theorem in the line-defect geometry, including an explicit
representation-nullspace audit. Priority is conditional on the renewed
multitrace/Calderón search in `open-questions.md`.
