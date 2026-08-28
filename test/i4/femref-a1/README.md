# I4.1a fitted-FEM reference experiment

Status: `IMPLEMENTED / FORMAL RUN NOT AUTHORIZED`.

This directory is the single active attempt `femref-a1` for the blinded I4.1a
reference experiment.  The governing specification is
`research/projects/eig-apost/implementation/i4/design-4-1a.md`; the method and
claim boundary are fixed by `method-4-1.md` and `method-review.md` in the same
I4 directory.

The implementation is self-contained base MATLAB.  It assembles the volume
$P_1$ stiffness and weighted mass matrices on deterministic polygon-interface
conforming meshes, applies the two quasiperiodic phases by a nodal
prolongation, inventories the frozen bulk and defect spectra, and forms the
basis-invariant coverage and four-axis empirical-resolution ledgers.  It does
not import the BIE/QZ chain or accept a current candidate, estimator, density,
field, or historical output.

Files:

- `run_i4_1a.m`: sole scientific entry point and all `LOCAL_` helpers;
- `SYMBOLS.md`: I4.1a symbol-to-variable ledger.

The only runtime input is an explicit artifact label such as `run-001`.
Outputs are created below `output/<run-id>/`, relative to the entry function.
Each MAT artifact contains one top-level `payload` struct; CSV artifacts retain
the scalar audit ledgers with 17-digit numeric serialization.

Before the first `eigs` call, `run_i4_1a` enters the explicit non-scientific
`LOCAL_preflight_audit` path.  That path performs only environment, mesh,
symbolic-factor-fill, workspace, current-run cache/export, wall-category, and
memory accounting.  It atomically publishes `resource-preflight.csv` and
`resource-preflight.mat`, then fails closed if the forecast exceeds 30 minutes
or 1.5 GiB.  This is deliberately embedded in the one formal command: its
elapsed time starts from the same run clock and is included in the complete
119-solve forecast, so there is no second command that can reset the budget.
The scientific entry remains `run_i4_1a(run_id)` and `run_id` remains only an
artifact label.
The preregistered first formal command is recorded in the design and must not
be executed until the Researcher theory-to-code and Skeptic spec-to-code gates
both pass.  This implementation stage has not run MATLAB, Octave, or any
guided-mode computation.

The constrained mesh includes vertical half-integer cell-boundary constraints
in addition to the required outer and disk constraints.  They do not change
the conforming $P_1$ space; they make the restricted-mass regions
$C_0$, $|x|<3/2$, and $|x|>N-3/2$ exact unions of triangles.  Reflection is
never assumed from point symmetry alone: node and assembled-matrix reflection
oracles fail closed before any eigensolve.

The B3 bulk level is an explicit ledger alias of the odd B4 phase indices.  It
adds `B3-reuse-B4-*` rows with role `alias-reuse-no-solve` and never increments
the solve counter.

Failure publication is fail-closed and append-preserving:

- the mesh-oracle stage atomically checkpoints `mesh-ledger.csv` and the
  header-complete `seam-checks.csv` before and after every reached seam oracle;
  an expected mesh failure appends the current partial diagnostic row with its
  exact reached boundary and first failure code/reason before rethrowing that
  same failure;
- a partial mesh audit never creates `resource-preflight.csv` or
  `resource-preflight.mat`; those artifacts remain conditional on completion of
  the full frozen mesh schedule;
- branch/coverage/continuation/collapse gates return an explicit scientific
  failure result to the entry function; it atomically checkpoints
  `branch-edges.csv`, `branch-inventory.csv`, and `coverage-ledger.csv` before
  rethrowing the same first failure code;
- all three ledgers carry `first_failure_code` and `first_failure_reason`, plus
  a terminal `FAILURE_MARKER`; already reached raw clusters and subspaces remain
  visible even when later continuation fails;
- if coverage, cross-configuration matching, collapse, no-localized-branch, or
  resolution gates fail after branches have formed, `fields.mat` preserves every
  reached branch anchor with its configuration and mesh identity, embeds the
  corresponding current-run meshes, and labels the payload
  `UNQUALIFIED / FAILURE_ARTIFACT`;
- every bulk 48-root sentinel is saved to the current-run machine cache and
  appended to bulk/seam CSVs before its mismatch gate is evaluated;
- no untracked raw cluster is promoted to a branch field, and no failure field
  can be mistaken for a reference collection.
