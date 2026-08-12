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
