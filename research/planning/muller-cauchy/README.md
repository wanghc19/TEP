# Müller--generalized-Bloch--Cauchy theory roadmap

This project is a theorem-level research plan for a spurious-free,
interface-only formulation of guided modes in a periodic line-defect
waveguide. It is not an implementation branch and does not modify the current
draft or MATLAB code.

## Recommended theorem target

The first hard milestone is a **quotient-safe continuous kernel--field
equivalence**. Let `A_rel(k,beta)` be the central Müller--Rayleigh block coupled
to the left/right outgoing generalized-Bloch Cauchy relations, and let
`N_rep` be the algebraic classes that reconstruct the zero field. The robust
target is

```text
ker(A_rel(k,beta)) / N_rep  ≅  G(k,beta),
```

with a strengthened unquotiented isomorphism only after an auxiliary
transmission uniqueness theorem proves `N_rep={0}`. Fredholm index zero is a
conditional enhancement. Full Nyström--Rayleigh--stable-subspace spectral
exactness is a future theorem package.

## Scope

The first paper is restricted to a scalar two-dimensional TM transmission
problem, smooth piecewise-constant dielectric inclusions, fixed real `beta`,
real `k` in a strict fixed-`beta` projected gap, non-Wood parameters, and a
uniform separation of stable/unstable multiplier clusters from the unit
circle. Exact thresholds, complex resonances, BICs, corners, and 3D Maxwell are
explicitly outside this phase.

## How to use the roadmap

1. Read `scope.md`, `notation.md`, and `assumptions.md` first.
2. Use `p-deps.md` to identify the next unblocked result.
3. Open the matching entry in `p-proofs.md` before starting a proof.
4. Record failed hypotheses immediately in `p-risks.md` and switch using
   `p-fallback.md` rather than silently strengthening assumptions.
5. Update `progress.md` and create a checkpoint at every theorem-package
   decision.

The formal report is in `report/p-theory.pdf`. Detailed learning notes
and future numerical validation contracts are separate so that the proof plan
can be resumed without reading the full report.
