# I4.1a fitted-FEM reference experiment

Status: `REPRESENTATION-GATE-003 CONSUMED / COMPLETE ZERO-EIGENSOLVE REPRESENTATION DIAGNOSTIC / NATURAL EXIT / FORMAL RUN-006 NOT AUTHORIZED`.

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
- `run_representation_gate_003_watchdog.pl`: fixed no-argument external
  controller for the consumed gate-003 diagnostic;
- `SYMBOLS.md`: I4.1a symbol-to-variable ledger.

The formal scientific entry remains the one-input `run_i4_1a(run_id)`, where
`run_id` is only an explicit artifact label. Formal outputs are created below
`output/<run-id>/`, relative to the entry function. Each MAT artifact contains
one top-level `payload` struct; CSV artifacts retain the scalar audit ledgers
with 17-digit numeric serialization.

Design Sections 15--16 additionally define the create-once, two-input diagnostic
dispatch `run_i4_1a('mesh-repair-001','mesh-diagnostic')`. It writes only below
`diagnostics/mesh-repair-001/`, performs zero eigensolves, and its preserved
diagnostic artifact records `PASS`.
It first creates its disposable system-temporary work area and only then claims
the final create-once diagnostic path. The temporary mesh cache exists only
while forming the full resource forecast; it is removed on exit and is never
read by a formal run.

Design Section 18 additionally defines the exact create-once dispatch
`run_i4_1a('mass-gate-001','mass-diagnostic')`. It writes only below
`diagnostics/mass-gate-001/`, rebuilds the single frozen `bulk-s12-g24` source
object at $\alpha=0$ and $\beta=0.5$, and calls the unchanged mesh, periodic-map,
phase-reduction, and mass-assembly helpers. It records per-node incidence,
master-group and prolongation support, exact full/reduced mass diagnostics, and
the natural 1-based pivot identity from exactly one raw two-output `chol` call.
The preserved 001 diagnostic stopped as
`MASS_DIAGNOSTIC_INCOMPLETE / EXECUTION_UNAVAILABLE` while serializing the first
populated mass ledger. It completed zero eigensolves and produced no durable
raw-mass or `chol` verdict; its namespace and `.partial` evidence are immutable.

Design Section 20 defines the sole corrected dispatch
`run_i4_1a('mass-gate-002','mass-diagnostic')`. It uses a separate create-once
`diagnostics/mass-gate-002/` namespace and never reads or reuses 001. The source
objects, one raw two-output `chol`, filenames, schemas, zero-eigensolve boundary,
and no-reference boundary remain unchanged. Only the five enumerated
sparse-derived CSV scalars are converted to ordinary full scalars, after which
a diagnostic-local, nonmutating type/shape gate checks all mass evidence,
mass-summary, and terminal-summary rows before publication. The shared CSV
writer is unchanged. The preserved 002 diagnostic completed with
`MASS_DIAGNOSTIC_COMPLETE_CHOL_FAIL` at natural 1-based `chol_flag=1`, with
zero eigensolves and no reference export. That as-built raw-mass result is the
evidence boundary repaired by the canonical representation path below; it does
not itself authorize a later formal run.

Design Sections 22--22.15 add the proof-backed representation repair. Every
allowlisted theoretical Hermitian reduced operator or square Gram uses the
strict upper triangle of its raw object, its conjugate transpose, and the real
raw diagonal. The code does not average a matrix with its adjoint. Raw full
finite-element operators, quasiperiodic prolongations, restricted full mass
matrices, and rectangular cross-Grams remain unchanged. Each formal phase
publishes stiffness-first OP2 evidence in the exact 36-column representation
ledger before `eigs`; the same in-memory canonical $K/M$ pair is used for mass
factorization, `eigs`, normalization, orthogonality, and residuals. Defect
clusters first prepare every global Gram/factor and representation row, atomically
checkpoint the solve-local batch, and only then normalize and synchronize the
full basis. Restricted/endpoint-parity and common-core objects use the same
prepare/checkpoint/consume ordering in two further solve-local batches; a later
consumer failure cannot rewrite an already committed representation row.

The exact create-once zero-eigensolve dispatch is
`run_i4_1a('representation-gate-001','representation-diagnostic')`. It will
write only below `diagnostics/representation-gate-001/`, rebuild the largest
bulk and finest defect meshes from source, and probe the largest bulk
$\alpha=\pi/4$, finest defect $\vartheta=\pi/4$, and endpoint
$\vartheta=0$ representations. It prepares six primary representation rows,
294 repeated-timing rows, four-family partition bounds, the exact
$10414\times36$ row container with exactly 238 primary-shaped and 10176
DRV2-parent-shaped rows, and the exact 261-checkpoint growing writer. Every row
preparation repetition includes the dimension/type/width gate. Formal and
benchmark checkpoints share the same pure v2 payload/inventory preparation and
atomic MAT/CSV publication path, with each rewrite timer spanning preparation
through both final moves. The endpoint parity probe also shares the formal
parity prepare/consume helpers. Pending status is hard-gated on the exact
partition/rewrite/forecast counts, operator inventory mirrors, header-only bulk
ledgers, zero scientific eigensolves/reference exports, and no partial files.
Its MATLAB summary can only report an internal result pending the same
Skeptic's post-exit wall/RSS review. This diagnostic was executed exactly once
and interrupted at the external 1 GiB RSS gate, so its status is
`INCOMPLETE / EXTERNAL_RESOURCE_BUDGET_UNAVAILABLE`; only primary reached
evidence was preserved. The create-once ID is consumed and must not be rerun or
overwritten, `run-006` remains unauthorized, and no reference or effectivity claim
follows from this diagnostic.

Design Section 23 defines the separate create-once dispatch
`run_i4_1a('representation-gate-002','representation-diagnostic')`. It writes
only below `diagnostics/representation-gate-002/`, rebuilds every input from
current MATLAB source, and neither inspects nor reuses the consumed 001
namespace. Its scientific and benchmark workload, zero-eigensolve boundary,
schemas, counts, canonicalization, timing gates, and 120-second wall stop are
unchanged. The only current-diagnostic memory stop is an external aggregate
process-tree RSS observation reaching exactly 2,147,483,648 bytes; no lower
actual-RSS threshold is permitted. The unchanged
`forecast_at_most_1p5_gib` column remains an honest future-formal preflight
observation, but for 002 only, `internal_gate_pass` is the conjunction of the
strict wall-forecast and timing-stability gates and does not include that
1.5-GiB observation. The formal path retains its 1.5-GiB preflight. The 002
diagnostic was executed exactly once and is now consumed. It stopped with only
primary evidence reached and is classified
`INCOMPLETE / EXTERNAL_MONITOR_PROTOCOL_FAILURE / WALL HARD LIMIT EXCEEDED`:
the preserved external samples were about 40 seconds apart rather than at most
30 seconds apart, and whole-command `real` time was 139.74 seconds, exceeding
the unchanged 120-second hard wall. The preserved aggregate peak RSS was
1,227,096,064 bytes, strictly below 2,147,483,648 bytes, so this is not a memory
failure. The incomplete artifact cannot be retried, completed under another
diagnostic ID, or used to authorize `run-006`, a reference result, or an
effectivity claim.

Design Sections 25--27 define the exact create-once dispatch
`run_i4_1a('representation-gate-003','representation-diagnostic')` and the
fixed no-argument controller `run_representation_gate_003_watchdog.pl`. The
controller atomically claims only
`watchdog/representation-gate-003/`; MATLAB alone may create
`diagnostics/representation-gate-003/`. A CLOEXEC exec-status pipe, release
barrier, and two-sided dedicated-process-group check prevent MATLAB from
starting before group isolation. The controller captures one monotonic
timestamp immediately before sending `EXEC_GO`, fixes the sole wall deadline
at that timestamp plus 1800 seconds, and never resets it. Its only resource
stops are inclusive target-active wall time reaching 1800 seconds and an
authoritative, PID-deduplicated aggregate MATLAB-tree RSS reaching
2,147,483,648 bytes. It samples the exact full `/bin/ps` table, unions recursive
descendants, dedicated-group members, and stable-identity known descendants,
and treats lost process/RSS/logging authority or a known target leaving the
dedicated group as operational-integrity failure rather than a resource-limit
crossing. Group kills are scalar-guarded, followed by identity-verified positive
cleanup, direct-child reap, and target-dead confirmation.

For 003, the existing 16- and 27-column timing/forecast fields remain honest
observations. False CV, spread, 30-minute forecast, or 1.5-GiB forecast screens
use `ADVISORY_*` codes beginning with
`OBSERVATION_ONLY_NOT_EXECUTION_FAILURE`; they cannot stop the diagnostic or
select `REPRESENTATION_GATE_COMPLETE_INTERNAL_RESOURCE_FAIL`. Exact scientific
workload, schemas, canonicalization, zero-eigensolve and information-isolation
rules are unchanged. The exact once-executed outer command was
`/usr/bin/time -lp /usr/bin/perl ./run_representation_gate_003_watchdog.pl`.
Outer `time` maximum RSS is contextual supervisor evidence only, not aggregate
MATLAB RSS authority. Gate 003 was executed exactly once, completed by natural
exit, and is permanently consumed. Its external ledger contains 737 valid
samples and zero unavailable samples, records 761.486755 seconds of target-active
time, and gives an authoritative PID-deduplicated aggregate peak of
1,296,187,392 bytes. The completed internal artifact reports zero scientific
eigensolves, no reference export, and the exact claim boundary
`ZERO_EIGENSOLVE_REPRESENTATION_AND_RESOURCE_EVIDENCE_ONLY`. Its 44.53-minute
future-formal forecast and substantial timing variability remain advisory
caveats. The 001/002 histories remain consumed and immutable; `run-006`, retry,
reference, and effectivity work remain unauthorized.

Before the first `eigs` call, `run_i4_1a` enters the explicit non-scientific
`LOCAL_preflight_audit` path.  That path performs only environment, mesh,
symbolic-factor-fill, workspace, current-run cache/export, wall-category, and
memory accounting.  It atomically publishes `resource-preflight.csv` and
`resource-preflight.mat`, then fails closed if the forecast exceeds 30 minutes
or 1.5 GiB.  This is deliberately embedded in the one formal command: its
elapsed time starts from the same run clock and is included in the complete
119-solve forecast, so there is no second command that can reset the budget.
The canonical-operator repair raises the formal preflight memory floor from
1.2 GiB to 1.3 GiB while preserving the 1.5 GiB fail-closed plan cap.
The scientific entry remains `run_i4_1a(run_id)` and `run_id` remains only an
artifact label.
The preregistered first formal command is recorded in the design and must not
be executed until the Researcher theory-to-code and Skeptic spec-to-code gates
both pass. The preserved `run-005` formal MATLAB attempt stopped fail closed at
the first reduced-mass gate with `0/119` eigensolves; it ran no guided-mode solve.

The constrained mesh includes vertical half-integer cell-boundary constraints
in addition to the required outer and disk constraints.  They do not change
the conforming $P_1$ space; they make the restricted-mass regions
$C_0$, $|x|<3/2$, and $|x|>N-3/2$ exact unions of triangles. Reflection is
never assumed from point symmetry alone. The deterministic tie repair preserves
every already reflection-closed triangle orbit; for each missing-partner tie
orbit it retains the negative-$x$-centroid representative and inserts its
reflection. Zero-centroid or unbalanced tie inventories fail closed. Before
assembly, every constraint and unordered triangle must have one reflected
partner, and every paired material flag must agree.
The relative connectivity-area defect is only a rectangular coverage-area
check. Complete no-hole/no-overlap evidence comes from the additional shared
preassembly planar-complex oracle: unordered triangles must be unique; every
mesh edge must have incidence one or two; incidence-one edges must exactly equal
the frozen segmented outer rectangle; nonincident edges must not intersect;
triangle adjacency must be connected; and every frozen constraint must remain
a mesh edge. The planar, coverage-area, constraint, interface, node, matrix,
seam, and Hermitian oracles remain fail closed before any eigensolve; the local
$P_1$ stiffness and consistent weighted-mass formulas are unchanged. The
preserved nine-mesh `mesh-repair-001` diagnostic passed these source-level
connectivity and reflection gates.

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
