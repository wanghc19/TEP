# Proof log

## 2026-07-14: initial reconstruction and risk audit

### Most promising existence route

1. Work first with a smooth inclusion compactly contained in the open cell and
   a piecewise `H^2` field, then extend to piecewise `H^1` by trace theory.
2. Apply Green's second identity separately in the inclusion and in the
   background rectangle with the inclusion removed.
3. Show that the horizontal boundary terms cancel because the field and the
   Green kernel have matching quasiperiodic phases.
4. Keep the two vertical-boundary Cauchy integrals.  Inside the open cell they
   solve the homogeneous background Helmholtz equation and hence possess a
   two-sided Fourier/Rayleigh representation.
5. Compare the two interface formulas carefully.  Direct Green
   representations naturally give opposite interface-density signs on the two
   sides.  The common-density Muller ansatz in the draft therefore needs a
   separate equivalence/invertibility argument; it does not follow merely by
   naming the physical Cauchy data as densities.

### Most dangerous uniqueness issues

1. The field sum may fail to be direct: a nonzero homogeneous background field
   might also be cancellable by a common-density interface field.
2. Even if the component fields are fixed, the pair `(sigma,tau)` may have a
   nullspace at interior Dirichlet/Neumann resonances or at exceptional
   transmission frequencies.
3. At a Wood anomaly, the two exponentials for one Fourier order coalesce; the
   correct ODE solution space is spanned by `1` and `x`.  Thus the displayed
   Rayleigh coordinates are non-injective even before layer potentials enter.
4. Away from Wood anomalies, Rayleigh coefficients are modewise unique for a
   genuinely homogeneous field, but the coefficient norm required for whole-
   cell `H^1` convergence is stronger and depends on the distances to the two
   vertical reference lines.
5. The original statement imposes no vertical Cauchy data.  Thus uniqueness of
   the PDE field itself is not at issue; only uniqueness of coordinates for a
   given field could possibly be meant.

### Candidate decisive tests

- `Omega = emptyset`: existence and non-Wood Rayleigh-coordinate uniqueness
  should reduce to the Fourier ODE theorem.  At Wood, the displayed basis fails
  to represent the linear-in-`x` threshold solution.
- `n = 1`: test whether the common-density ansatz develops a gauge/nullspace or
  whether the forced Muller operator reduces to a transparent identity.
- Interior eigenfrequency: construct Calderon null densities for a single- or
  double-layer representation and check whether the simultaneous exterior-QP
  and interior-free-space ansatz removes or preserves them.
- Difference of two decompositions: derive the exact homogeneous boundary
  system for `(delta sigma, delta tau, delta xi)` and identify it with a
  transmission or interior-transmission problem.

### Literature that must be verified

- Linton (1998): spectral form and threshold failure of the one-dimensional
  quasiperiodic Helmholtz Green function.
- Barnett and Greengard (2010): exact layer representation used for periodic
  transmission cells, its nullspace/spurious-resonance discussion, and the
  role of auxiliary wall/proxy unknowns.
- Kress (1991), or a theorem-level boundary-integral source: mapping properties,
  jump relations, and uniqueness of Muller formulations for penetrable media.
- A trace-space source for `H^{1/2}` Dirichlet and `H^{-1/2}` Neumann data and
  weak Green identities on Lipschitz domains.
- A periodic/quasiperiodic Sobolev source for the Fourier characterization and
  the Rayleigh expansion in a homogeneous strip.

No conclusion is yet assigned to the conjecture.  In particular, the formal
Green decomposition is not being treated as a proof of the common-density
statement, and numerical matrix invertibility will not be used as evidence for
a continuous theorem.

## 2026-07-14: decisive structural result

The source of the same-sign/common-density ansatz was identified in
Barnett--Greengard (2010), equations (15)--(20).  Their Appendix A proves
completeness through a complementary field with the interior and exterior
wavenumbers interchanged.  This resolves the initial sign puzzle: direct Green
formulas produce opposite signs on the two sides, whereas the Muller ansatz is
an indirect representation whose completeness is a transmission theorem.

For the present geometry, the proof separates into two independent steps.

1. In homogeneous collars at the ports, Fourier transformation in `y` gives
   `u_m'' + gamma_m^2 u_m = 0`.  Away from Wood thresholds, the incoming
   coefficient at the left and the incoming coefficient at the right determine
   a unique background field `u_h`.  Subtracting it leaves an outgoing pair of
   piecewise Helmholtz fields.
2. The common-density layer synthesis represents this outgoing pair if and
   only if the associated swapped-wavenumber complementary transmission
   problem has the required Fredholm solvability.  Its uniqueness makes the
   density synthesis injective.  At a complementary eigenfrequency, nonzero
   null densities can represent the zero field, so the original unconditional
   uniqueness claim fails.

The always-valid alternative is the direct Green representation with physical
Cauchy data `(p,q)` and opposite interface signs:

```text
u_e = h_vertical + S_QP(k) q - D_QP(k) p,
u_i =              - S(ki) q + D(ki) p.
```

Top/bottom terms cancel by quasiperiodicity; `h_vertical` is the retained pair
of vertical-boundary Cauchy integrals and has a Fourier/Rayleigh expansion.
This proves a corrected representation without claiming the original Muller
density pair is automatic.

## 2026-07-14: final classification

The original wording is **too strong and incomplete**, rather than a theorem
that can be affirmed as written.  A corrected conditional theorem holds under:

- a `C^2` inclusion separated from the ports;
- piecewise `H^1` weak solutions and trace-space transmission conditions;
- real positive coefficients (or an easier absorbing variant);
- exclusion of Wood thresholds;
- incoming normalization of the two Rayleigh coefficient families; and
- bijectivity/Fredholm solvability of the swapped-wavenumber common-density
  synthesis problem.

Under these assumptions the component fields, Rayleigh coefficients, and
density pair are unique.  Without the complementary spectral condition,
density uniqueness can fail and existence requires an adjoint compatibility
condition.  At Wood thresholds the displayed basis itself is incomplete
because the missing second ODE solution is `x psi_m`.
