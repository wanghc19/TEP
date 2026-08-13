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

## 2026-08-13 — Continuous real spectrum, not finite exact Hermitian structure, governs the search axis

- **Primary spectral object.** The target remains the positive real guided eigenvalue of the
  self-adjoint continuous physical operator. The numerical matrices approximate that problem;
  they do not decide whether the physical search is allowed to use real $k$.
- **Route correction.** The I2.2 endpoint experiment correctly returned
  `inertia=UNAVAILABLE`: without an exact finite Hermitian identity, the signs of a finite
  matrix spectrum and an endpoint inertia jump have no theorem-level meaning. This limitation
  applies to the inertia route only. It no longer blocks a derivative-free, bounded real-axis
  search for an approximation to the continuous real eigenvalue.
- **Default numerical route.** Reuse the I1.3/I2.1 local interval and the original unbalanced
  $A_{\mathrm{def}}^D(k)$. Do not repeat a wide scan. Unless a separately qualified signed
  scalar is available, use one-dimensional bounded minimization of
  $\sigma_{\min}(A_{\mathrm{def}}^D(k))$, not a sign-changing bracket or an inertia surrogate.
- **Qualification.** A real-axis minimizer is initially a constrained discrete approximation,
  not automatically an exact zero of the non-Hermitian finite determinant. Qualification must
  return to the original matrix and record left/right residuals, backward error, near-kernel
  separation, all factor health, full-graph/Schur parity, nonzero field participation, boundary
  matching, reproducibility, and a candidate-location/evaluator/solve uncertainty ledger. It is
  called root uncertainty only after the I2.4 candidate-to-zero and slope gates pass.
- **Role of structure diagnostics.** The observed finite Hermitian, reciprocity, and Lagrangian
  defects are uncalibrated structure-consistency diagnostics and uncertainty-ledger components.
  Converting them into root error requires refinement evidence, a nonzero derivative denominator,
  and the continuous--discrete bridge. Exact finite
  structure remains useful only if endpoint inertia is later revived as an optional
  corroboration; it is not a prerequisite for the main root or estimator route.
- **Fallback.** A local complex refinement inside the already isolated I2.1 disk is triggered
  only if a persistent real-axis residual floor, candidate shifts inconsistent with the
  evaluator/structure uncertainty ledger, or anomalous left/right near-kernel phase diagnostics
  cannot be explained. Off-axis displacement is then measured by that diagnostic rather than
  presumed from real-axis data. Broad complex-plane scanning remains out of
  scope.
- **Estimator mainline.** The active dependency is now
  `continuous real eigenvalue -> discrete real-axis approximation -> consistency/discretization
  error -> a posteriori eigenvalue correction and effectivity`. Continuous projected-gap,
  half-guide, BIE kernel--field, regular-approximation, and no-pollution obligations still govern
  promotion to a physical eigenvalue or a theorem-level bound; they do not prevent the next
  qualified discrete computation.
- **Candidate-to-zero gate.** A constrained real-axis minimizer does not directly enter the NEP
  simple-root correction. Before I3 it must either be connected to a nearby qualified finite
  simple zero with a controlled root correction (and any imaginary displacement), or be supplied
  with a separately derived perturbation formula for constrained minimizers.

The earlier I2.2 decision and its post-run verdict remain an immutable history of the inertia
branch. This section supersedes only their use as the current root-search authorization.

## 2026-08-13 — Candidate and continuous-error estimation supersede exact-discrete-root goals

- **Only final goals.** The project now has only two final goals: propose a numerical candidate
  for the continuous physical eigenvalue, and estimate the distance from that candidate to the
  true continuous eigenvalue, ultimately seeking a computable upper bound.
- **Candidate status.** A finite-precision candidate is not expected to equal either the true
  continuous eigenvalue or an exact zero of a chosen finite matrix. Residual, structure,
  discretization and representation discrepancies are error sources to identify and control,
  not conceptual defects that must all vanish before a candidate may be reported.
- **I2.2 role.** I2.2 reuses only the already selected I1.3 dip endpoints and checks whether a
  consistently defined endpoint sign count exhibits an inertia-like jump. This is numerical
  corroboration of candidate credibility. It neither repeats the scan nor proves a finite real
  zero. The historical `inertia=UNAVAILABLE` result remains authoritative for a theorem-level
  inertia claim; exact finite Hermitian structure is now OPTIONAL unless a later rigorous signed
  crossing or enclosure specifically needs it.
- **I2 handoff.** I2.3 aggregates the minimum anti-artifact evidence for the candidate. I2.4
  records the error sources, uncertainties and comparable refinement data that I3 can consume.
  Neither milestone has an exact-discrete-root exit condition.
- **I3 mainline.** I3 follows
  `candidate -> error sources -> computable estimate -> independent-truth validation ->
  upper-bound feasibility`. A derivative, adjoint, transported mode or simple-root denominator
  becomes mandatory only if the selected estimator formula actually consumes it.
- **Upper-bound boundary.** A level difference is only an indicator or next-level correction.
  It becomes an empirical eigenvalue-error estimator only after comparison with an independent
  continuous-problem reference carrying its own uncertainty. It becomes a computable upper
  bound only after an independently justified continuous--discrete bridge and remainder,
  stability, saturation or enclosure control. Otherwise the required verdict is
  `UPPER_BOUND_UNAVAILABLE`.
- **Stage discipline.** Each main stage should have four formal milestones and must never exceed
  five. Helpful checks that do not block the next necessary deliverable are `OPTIONAL` rather
  than new stages.

This decision supersedes the previous section's bounded-real-axis locator and candidate-to-zero
requirements as the current project plan. It does not rewrite the I2.1 count result, the I2.2
structure diagnostic, or any append-only numerical evidence.

## 2026-08-13 — I2 is compressed to three independent numerical milestones

- **Milestone count is not a target.** Four milestones remain a useful default for many stages,
  but they are not a minimum. A stage must not invent a handoff milestone merely to reach four;
  five remains the absolute maximum.
- **I2.1 and I2.2 remain unchanged.** I2.1 retains the conditional finite-dimensional count-one
  result. I2.2 retains the planned endpoint surrogate sign-count diagnostic and all historical
  `NaN/UNAVAILABLE` inertia evidence.
- **New I2.3.** The only remaining I2 experiment compares the same physical mode at
  preregistered discretization orders. It freezes the physical object, level tuples, primary
  refinement axis, candidate definition/localization rule and a common representation for mode
  identity. It reports each candidate, signed and absolute drift, localization uncertainty and
  the minimum residual, factor, field, boundary, reproducibility and mode-identity diagnostics.
- **Interpretation.** Large, small, nonmonotone or unresolved drift are all valid outcomes.
  Drift that cannot be separated from localization uncertainty is `DRIFT_UNRESOLVED`, not zero
  drift or convergence. A mode swap or unresolved mode identity prevents interpretation as a
  same-mode drift sequence.
- **I2.4 is deleted from the active plan.** I2.3 output is the direct I3 input; no separate
  error-ledger or handoff milestone is needed.
- **I3 owns error analysis.** Identification and decomposition of spatial, trace, half-guide,
  BIE/QZ, finite-structure, solve/localization and continuous--discrete errors now begin in I3,
  together with estimator selection, independent-truth validation and upper-bound feasibility.

This decision supersedes the immediately preceding decision's I2.3/I2.4 split and four-milestone
stage rule. It changes planning only and does not modify historical designs, reviews, code or
append-only outputs.
