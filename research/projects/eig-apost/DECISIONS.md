# Eigenvalue a posteriori decision record

## 2026-08-11 — Continuous DtN/BIE method supersedes finite-tail formulation

- **Current spectral object.** The exact left/right DtN operators are defined by the
  corresponding semi-infinite boundary-value problems. The physical center variational pencil
  $\mathcal F(k)$ is defined before BIE representation, Fourier truncation, QZ, doubling, or any
  matrix. A real guided eigenvalue is a nontrivial kernel point of this physical pencil.
- **BIE status.** The continuous BIE block schema is a candidate realization of
  $\mathcal F(k)$, not a second definition of the physical problem. Representation completeness,
  injectivity, kernel--field equivalence, Fredholm index, and adjoint consistency remain proof
  obligations.
- **QZ status.** Ordered QZ is only a finite-dimensional method for computing stable/unstable
  deflating subspaces of a one-cell generalized pencil. A safe Dirichlet chart gives
  $\Lambda_{h,M}=N_{s,M}D_{s,M}^{-1}$; an unsafe chart retains a Cauchy-data relation or a Robin
  realization with a fixed impedance/Riesz map.
- **Finite-tail status.** The former “finite cells + remote closure + doubling” main method is
  preserved in `phase4-report/legacy-tail.tex` as a superseded formulation. It may be used only as
  a same-cell cross-check, a reference sequence, or an optional tail diagnostic.
- **Convergence correction.** A finite-rank Fourier lift cannot generally converge in full
  $H^{1/2}\to H^{-1/2}$ operator norm to the noncompact first-order DtN. The active alternatives
  are projected DtN consistency plus eigentrace regularity, subtraction of a common principal
  DtN part followed by compact-remainder approximation, or regular Galerkin/graph convergence.
- **Estimator language.** An adjacent-level projected difference is a next-level correction.
  It may be called a remaining-error estimator only after an independent saturation/remainder
  assumption or proof is supplied.
- **Numerical freeze.** I4 numerical work is paused. Assembly of $A_{\mathrm{def}}$, DtN wall
  experiments, locator runs, complex disks, and root isolation are not authorized until
  OP-M0-1--OP-M0-4 in the central ledger are closed.
- **History preservation.** Phase 1--2 files retain their original wording because they already
  record the DtN-first commitment and the distinction between definition and construction.

### 2026-08-12 supersession note

The numerical freeze above governed the 2026-08-11 method reconstruction. Later explicit user
authorization established the current empirical I1 route. I1.1--I1.4 now pass with conditions at
the sampled fixed-$M=48$ discrete level, so a separately preregistered derivative-free I2
contour/root-isolation experiment is allowed. OP-M0-1--OP-M0-4 still block promotion of any
discrete root to a physical eigenvalue or theorem-level claim; production $A_{\mathrm{def}}'$ and
the estimator also remain unavailable.

## 2026-08-13 — I2.2 freezes a fail-close real-axis structure diagnostic

- **Frozen scope.** I2.2 now has a frozen-candidate design, but no run is authorized before the
  independent design--implementation review. It does not authorize a root locator.
- **Default route.** Do not use a broad complex-plane scan as the default. First qualify the
  exact singularity-preserving transformation on the frozen nearest-shoulder interval where $T(k)$ is invertible,
  from the
  frozen $A_{\mathrm{def}}^D$ to its
  Dirichlet-coordinate mismatch, check the real-axis self-adjoint defect and endpoint inertia,
  and use a one-dimensional bracketed solve if those gates pass.
- **Reason.** I2.1 already supplies conditional empirical count one in a real-symmetric disk. A
  reliable real-axis singularity of the same finite matrix therefore identifies the unique disk
  zero without another two-dimensional search.
- **Boundary.** The one-cell unit-circle gap is not a continuous sharp-disk projected-gap theorem,
  and the smooth Fliss Track A gap cannot be transferred to the sharp-disk model. Continuous
  self-adjointness also does not by itself make the unbalanced BIE/QZ matrix Hermitian.
- **Proof verdict.** The $A$--$H$ singularity equivalence, whole-interval $T$ separation and
  empty-center Hermitian identity are proved. The actual MFS/collocation/QZ half-guide graph has
  no established exact Lagrangian identity, so inertia is preregistered as unavailable and the
  only permitted run is a two-endpoint structure diagnostic with NaN counts.
- **Fallback.** Because the finite exact-Hermitian identity is blocked, report that blocker first.
  Any future complex solve stays local
  to the already isolated I2.1 disk; a broad scan is not justified by default.

The frozen reasoning and experiment contract are recorded in
[[research/projects/eig-apost/implementation/i2/design-2-2|I2.2 design]].

### Post-run decision

Revision A completed the two frozen endpoints and received the independent verdict
`PASS WITH CONDITIONS / I2_2_STOP_THEORY_GATE`.  The pointwise $A$--$H$ identities close at
floating-point scale, $T$ is well separated, and raw graph/DtN/$H$ defects are about machine
precision; these quantities remain implementation diagnostics.  Because exact finite
Lagrangian/Hermitian structure and whole-interval same-family continuity are still unproved,
endpoint inertia is `NaN/UNAVAILABLE` and no real-root claim is made.  The project will not keep
expanding this branch merely for theorem-level completeness.  Any next step--either a new
structure-preserving proof route or a local complex refinement confined to the I2.1 disk--is a
method change requiring a new design, freeze and independent review; broad complex scanning
remains rejected as the default.
