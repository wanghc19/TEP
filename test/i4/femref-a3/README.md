# I4.1c curved P2-FEM experiment

This is the only active experiment directory for the I4.1c curved
isoparametric P2 reference. Its scientific authority is
[[../../../research/projects/eig-apost/implementation/i4/design-4-1c]];
[[../../../research/projects/eig-apost/implementation/i4/review-4-1c]] records
the Researcher--Engineer--Skeptic gates. The code is based mechanically on
`../femref-a2/` but neither reads nor modifies that directory or its output.

## Frozen model and implementation

The core solves

$$
-\Delta u=\lambda q u,\qquad \lambda=k^2,
$$

with the frozen defect/supercell materials and quasiperiodic phases. Six-node
conforming P2 triangles use the isoparametric map

$$
F_T(\widehat x)=\sum_{a=1}^6 X_aN_a(\widehat x).
$$

Interface midpoint nodes lie at true circular-arc angle midpoints. Element
assembly evaluates the varying Jacobian at Duffy quadrature nodes. The exact
quadratic determinant minimum, same-map P1-in-P2 identity, seam phases on
vertices and midpoints, and nonlinear inverse-map field reconstruction are
validated before an eigenpair can become authoritative.

The active source set is deliberately small:

- `run_i4_1c_core.m`: representation, assembly, eigensolve, FEM-only branch
  tracking, preliminary-first publication, and refinement artifacts;
- `run_preflight.pl`: create-once representation preflight controller;
- `run_formal.pl`: create-once formal controller;
- `inspect_i4_1c_artifacts.m`: read-only current-run schema and numerical
  evidence inspector (no solve and no scientific publication);
- `run_artifact_review.pl`: create-once monitored inspector controller;
- `SYMBOLS.md`: canonical mathematics-to-code ledger.

## Identities and resource contract

- Preserved operational failure: `resource-preflight-001/execution-001`.
- Preserved fixture failure: `resource-preflight-001/execution-002`.
- Active preflight retry: `resource-preflight-001/execution-003`.
- Formal: `run-001/execution-001`.
- Read-only artifact review: `artifact-review-001/execution-001`.
- Per execution: at most 2700 seconds and aggregate process-tree RSS strictly
  below 3,221,225,472 bytes.
- Lifecycle hard deadline: epoch 1788280898.

The controllers create `output/<run-id>/<execution-id>/` exactly once, sample
aggregate process-tree RSS, and stop at either hard limit. They implement no
lower forecast, stall, guard, or capacity gate.

## Gate and claims

Neither controller may be launched until the theory-to-code and spec-to-code
reviews are recorded in `review-4-1c.md`. The formal program reads no Markdown,
Git state, BIE/QZ values, estimator data, or historical reference output. It
publishes a Q6 preliminary leaf before attempting the independently assembled
Q8 final leaf. Any reported reference, drift, or uncertainty is empirical and
non-certified; this experiment performs no effectivity comparison.
