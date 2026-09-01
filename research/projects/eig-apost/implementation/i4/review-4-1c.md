# I4.1c curved isoparametric P2 FEM review

Status: **`SKEPTIC DESIGN REVIEW COMPLETE / PASS WITH CONDITIONS / IMPLEMENTATION AUTHORIZED / EXECUTION NOT AUTHORIZED`**.

## Material Passport

- Origin Skill: `academic-research-suite / experiment-agent`
- Origin Mode: `validate / independent design review`
- Origin Date: `2026-09-01`
- Verification Status: `ANALYZED / DESIGN ONLY`
- Audited Artifact: [[research/projects/eig-apost/implementation/i4/design-4-1c|design-4-1c]]
- Governing Method: [[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]]
- Prior Numerical Boundary: [[research/projects/eig-apost/implementation/i4/review-4-1b#AE. Final post-run review of run-002/execution-002|review-4-1b §AE]]

## A. Audit frame

| Item | Review frame |
|---|---|
| Exact question | Does the frozen six-node isoparametric curved-$P_2$ design define the same guided-mode problem, a mathematically valid curved Galerkin discretization, a reproducible FEM-only selector and a feasible preliminary-first computation? |
| Claimed contribution | At least one field-bearing empirical curved-$P_2$ reference, followed when available by six observed refinement components. |
| Current stage | Design review. No `femref-a3` code, preflight, spectrum or result existed at the reviewed freeze. |
| Intended output | Engineering/numerical empirical reference evidence, not a theorem, certified enclosure or effectivity result. |
| Assumptions | The inherited constrained vertex topology is legal; every curved element passes the global determinant-minimum test; the nonlinear inverse map covers every required sample. |
| Exclusions | No BIE/QZ-guided selection, estimator read, historical-output input, rational geometry, package/main edit, continuous existence claim or certified error bound. |
| Success criterion | A legal curved mesh, finite Hermitian forms with SPD mass, residual-valid field-bearing eigenobjects, FEM-only branch identity, create-once preliminary/final authority and truthful empirical claim boundary. |

The audit used the repository, research and test `AGENTS.md` files; the accepted I4.1 method and
method review; the I4.1a/I4.1b design and review chains; the final `femref-a2` core, controllers,
text artifacts and post-run Section AE; the I4 guide and project status; and the complete frozen
I4.1c design. No MATLAB, Octave, Python or numerical experiment was run in this design review.

## B. Verdict

**Verdict: `PASS WITH CONDITIONS`. Confidence: high for the mathematical design and information
isolation; medium-high for prospective resource feasibility.**

No unresolved `BLOCKER` was found. The design changes only the interface geometry representation,
uses the correct variable-Jacobian isoparametric forms, supplies an exhaustive quadratic
determinant-minimum check, preserves one global midpoint DOF per physical edge, and forbids affine
field reconstruction. Its preliminary-first order can deliver a reviewable eigenpair before the
optional axes, while incomplete refinement cannot erase that result. The planned dimensions and
71/76-call schedule do not provide objective evidence of a 2700 s, 3 GiB or lifecycle impossibility.

Three implementation-stage conditions remain material: the nonlinear inverse map must demonstrate
complete and unambiguous coverage of the required physical grid; the quadrature ladder must publish
an explicit resolved/unresolved interpretation rather than treating $Q=8$ as adequate by name;
and the global determinant minimizer, Bernstein boxes and curved trace ownership must be mapped
exactly in source. These conditions restrict interpretation or the next execution gate, but they
do not prevent bounded implementation or justify withholding a valid preliminary eigenpair.

## C. Strongest challenge

The strongest failure mode is a sampler that converges to a numerically small residual in the
wrong curved element, or misses points in the region between a chord and its curved trace. Such a
defect can leave the eigenproblem itself valid while corrupting common-grid subspace overlaps,
localization, parity, branch continuation and therefore the canonical FEM-only rank. The design
substantially addresses this risk by requiring Bernstein-control-point bounding boxes, multiple
deterministic seeds, positive determinant, reference-domain membership, forward/inverse residuals
and fail-closed required-grid coverage. Exact spec-to-code review must verify those predicates and
include a curved-versus-affine counterexample before any preflight or formal run.

## D. Classified findings

### 1. `IMPORTANT CAVEAT`: quadrature adequacy has evidence fields but no explicit status rule

- **Location:** design Sections 5.1, 8 and 10.
- **Evidence:** the Duffy rules and monomial tests are mathematically sound; $Q=4$ exactly resolves
  the degree-six mass integrand in exact arithmetic, while stiffness is rational and is compared
  over $Q=4,6,8$. The design nevertheless calls $Q=8$ the final authority whenever it is otherwise
  valid and says that stiffness changes have no cancellation threshold.
- **Consequence:** a large or noncontracting $Q=6\to8$ stiffness/eigenpair drift would not invalidate
  a residual-valid $Q=8$ discrete eigenpair, but it would make the phrase “quadrature-resolved final
  reference” indefensible.
- **Cheapest decisive condition:** publish both operator changes, the matched $Q=4,6,8$ branch
  scalars and field overlaps, and one explicit `QUADRATURE_RESOLUTION_OBSERVED` or
  `QUADRATURE_RESOLUTION_UNAVAILABLE` status. An unresolved status must downgrade the deliverable
  to preliminary empirical evidence; it must not suppress the eigenpair or trigger a result-tuned
  quadrature order.
- **Uncertainty:** no numerical quadrature evidence exists yet.

### 2. `IMPORTANT CAVEAT`: nonlinear inverse-map completeness is a result-critical implementation condition

- **Location:** design Sections 5.2(10), 7.1, 12 and 15.
- **Evidence:** the proposed Bernstein convex-hull box is conservative, and accepted inverse
  coordinates must satisfy residual, reference-triangle and positive-determinant tests. The design
  also requires complete required-grid reconstruction and rejects affine/P1 sampling.
- **Consequence:** any missed or wrongly owned sample can change overlap-based component assignment
  and ranking. This is not merely a parity/localization diagnostic issue.
- **Cheapest decisive condition:** before the first spectrum, test fixed reference points on both
  sides of a curved interface, including points between the chord and the quadratic trace; require
  forward/inverse recovery and deterministic boundary ownership. During field publication require
  every retained common-grid row to be covered exactly once, except deliberate shared traces, and
  publish maximum residual and uncovered/ambiguous counts.
- **Uncertainty:** the algorithm is well specified prospectively but unimplemented.

### 3. `IMPORTANT CAVEAT`: formal eigensolver and field memory remain unmeasured

- **Location:** design Section 12.
- **Evidence:** inherited topology gives at most about 7,232 reduced DOFs; the straight-sided
  61-call run used 232.450046 s and 1,055,391,744 B. Curved assembly increases quadrature work but
  not the sparse pattern or Arnoldi dimension. The 600--1200 s and 1.1--1.6 GiB ranges are
  planning inferences.
- **Consequence:** unexpected quadrature-assembly temporaries or retained curved-field samples may
  consume more resources than forecast. No present measurement or lower bound shows that the
  preliminary five-slice solve cannot fit.
- **Cheapest decisive condition:** the actual-only preflight must report stage RSS and actual
  operator/factor sizes; the subsequent pre-run review must inspect simultaneous live objects and
  refresh the remaining absolute lifecycle time. Only the exact 2700 s/3 GiB/lifecycle predicates
  may stop execution.
- **Uncertainty:** prospective only; not a resource blocker.

### 4. `MINOR CAVEAT`: determinant positivity is a binary64 validation, not a certificate

- **Location:** design Section 4.3.
- **Evidence:** the coefficient formulas for $F_T$ are correct, and vertices, edge stationary
  points and an interior stationary point exhaust minima of a quadratic on a triangle. The stated
  tolerance guards roundoff but is not directed interval arithmetic.
- **Consequence:** it supports a numerically legal curved mesh at the strength claimed, but not a
  certified geometric bijectivity theorem.
- **Cheapest decisive condition:** source fixtures should include an interior negative-minimum
  quadratic whose quadrature samples remain positive and a singular-Hessian case whose minimum is
  attained on an edge. No theorem-level extension is required.

### 5. `MINOR CAVEAT`: curved geometry remains polynomial and geometry-biased

- **Location:** design Sections 4.1, 10 and 15.
- **Evidence:** endpoints and angular midpoints lie on the true circle, but the interpolating
  quadratic arc is not rationally exact. The design correctly keeps $g$ as a separate axis.
- **Consequence:** $h$, $g$ and $Q$ changes can share a pre-asymptotic geometry bias;
  $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ cannot be an upper bound.
- **Cheapest decisive condition:** retain the radial-trace defect and $g=16,24,32$ field-matched
  ladder in the final caveat inventory. No method change is needed.

## E. Mathematical and implementation audit

### E.1 Same continuous problem and isoparametric forms

The coefficient, missing column, phases, normalization, supercell period, weak form and
$\lambda=k^2$ relation match the accepted FEM route. Moving only interface midpoints changes the
geometry approximation without introducing BIE/QZ objects or another polarization. With
$F_T=\sum_aX_aN_a$, the stated gradient pullback $J_T^{-\mathsf T}\widehat\nabla N_a$ and positive
$\det J_T$ factor are correct. Elementwise $q_T\in\{1,17\}$ remains legitimate because every
curved interface edge has two incident elements with opposite material labels.

### E.2 Geometry conformity and determinant test

One sorted global edge owner gives the same geometry midpoint and field DOF to both incident
triangles. The two trace polynomials are therefore identical after edge-orientation reversal.
Putting only constrained interface-edge midpoints at angular circle midpoints avoids curving
unrelated interior or periodic edges. The polynomial coefficients in Section 4.3 expand the six
Lagrange functions correctly. Since $\det J_T$ is quadratic, the frozen vertex/edge/interior
candidate set is sufficient for its global minimum, provided the implementation handles singular
stationary systems by relying on the boundary candidates rather than inventing an inverse.

Positive element Jacobians, common edge traces, simple nonintersecting interface loops and the
unchanged straight outer boundary are enough for the declared numerical curved mesh. The design
does not overclaim exact circular geometry or certified global invertibility.

### E.3 Quadrature and curved P1 embedding

Under the Duffy map, a total-degree-$d$ triangle polynomial becomes degree at most $d+1$ in the
first tensor coordinate and at most $d$ in the second. Thus the $Q=4$ Gauss product resolves the
degree-six mass integrand in exact arithmetic. The stiffness integrand is rational after
$J_T^{-1}$ and properly receives a numerical ladder instead of an affine exactness assertion.

The reference-linear functions are a true subspace of the six-node reference $P_2$ space. Their
midpoint values are the endpoint averages encoded by $E_T$, so the local and reduced
$E^*K_2E=K_1$, $E^*M_2E=M_1$ checks on the same curved map and quadrature are mathematically valid.
They test basis, geometry and phase implementation without importing a P1 eigenpair.

### E.4 Phase, field identity and information isolation

All outer boundary edges remain straight, so vertex and midpoint periodic pairing and the corner
product phase retain the reviewed P2 semantics. The branch inventory, complete subspace overlap,
three-consecutive-twist rule and lexicographic rank use only current-run FEM fields. Parity remains
an empirical symmetric-grid compression and cannot delete a valid object. The $Q=6$ preliminary
authority is immutable before $Q=8$ or any other axis, and a different $Q=8$ canonical component
must be reported rather than silently matched by frequency.

Active MATLAB is explicitly barred from historical FEM output, BIE/QZ objects, densities,
estimators, Markdown and Git. The BIE scalar is admitted only in a post-freeze read-only review,
where it yields a positional distance and cannot select or rerun a root. This ordering is
sufficient for the declared numerical independence.

### E.5 Lifecycle, artifacts and resources

The create-once preflight/formal identities, same-attempt operational repair, preliminary-first
MAT publication, append-only resource evidence and summary-last controller preserve failure truth.
The sole command limits are 2700 s, the absolute lifecycle endpoint and inclusive aggregate
process-tree RSS 3,221,225,472 B. The design introduces no lower gate. A failed optional axis
continues the legal suffix and leaves `NaN`; it cannot erase a committed field-bearing preliminary
reference.

The preflight's five topologies and six $Q$/mesh rows target the largest assembly and geometry
cases without capacity simulation. Its zero-guided-eigensolve scope is appropriate. Exact source,
controller and artifact review remains required before execution.

## F. What survived scrutiny

1. The continuous problem, coefficient placement, phases and $\lambda=k^2$ are unchanged.
2. The six-node isoparametric map, variable-Jacobian forms and shared global edge ownership are
   mathematically correct.
3. The determinant-minimum test can reject an inverted element missed by quadrature sampling.
4. The $Q=4,6,8$ Duffy ladder separates exact mass-polynomial behavior from rational stiffness
   quadrature sensitivity.
5. Curved-map P1 embedding, Hermitian/SPD, seam and residual checks protect the discrete object.
6. Nonlinear six-function field reconstruction and complete-subspace overlaps support FEM-owned
   mode identity without affine or historical-field leakage.
7. Preliminary-first publication and refinement downgrade semantics prioritize at least one
   interpretable eigenpair.
8. The six axes remain empirical; no drift or extrapolation is called a certified error bound.
9. The prospective schedule is larger than I4.1b but has no demonstrated resource impossibility.
10. Late BIE distance is isolated from selection and is explicitly not effectivity.

## G. Minimal resolution and next gate

The same Engineer may create only `test/i4/femref-a3/` and implement the frozen curved-$P_2$
design. Before any execution, the same Researcher must provide an exact theory-to-code map and the
same Skeptic must verify:

1. one global interface midpoint owner and correct angular-midpoint handling across the angle cut;
2. variable $J_T$, $J_T^{-1}$ and positive determinant use in every form;
3. exhaustive quadratic determinant minimization, including singular-Hessian fixtures;
4. Duffy-rule monomial validation and explicit quadrature-resolution status publication;
5. same-map/same-rule curved P1 embedding and phase commutation;
6. conservative Bernstein boxes, nonlinear inverse residuals, curved-versus-affine fixture and
   complete common-grid coverage;
7. exact 71/76 call graph, preliminary/final authorities, FEM-only rank and six empirical axes;
8. current-run-only inputs, create-once artifacts and the two hard resource predicates plus the
   lifecycle endpoint.

After that review, at most the exact actual-representation preflight may be authorized. Its
post-preflight review precedes formal execution. This design PASS does **not** authorize MATLAB,
the preflight controller, formal science, output creation, BIE distance calculation, project
status synchronization or effectivity comparison.

## H. Open-problem handoff

| Stage | Category | Item | Blocking scope | Cheapest next check | Suggested status |
|---|---|---|---|---|---|
| I4.1c implementation | `IMPORTANT CAVEAT` | Curved inverse-map coverage may fail or choose a wrong element | Blocks formal field interpretation only if unresolved in source/fixtures | Bernstein-box and curved-versus-affine forward/inverse fixture plus full-grid coverage counts | `SCHEDULED` |
| I4.1c result | `IMPORTANT CAVEAT` | $Q=8$ stiffness quadrature may remain empirically unresolved | Does not block a preliminary eigenpair; blocks calling quadrature resolved | Publish $Q=4,6,8$ operator/branch/field ladder and downgrade status if unresolved | `SCHEDULED` |
| I4.1c resource | `IMPORTANT CAVEAT` | Formal eigensolver/field peak is unmeasured | Blocks only on measured hard-limit evidence or quantitative impossibility | Actual-only preflight, then refreshed simultaneous-lifetime review | `SCHEDULED` |
| I4.1c geometry | `MINOR CAVEAT` | Polynomial curved arcs are not exact circles | Limits empirical reference strength; no next-stage blocker | Retain $g$ ladder and radial-trace evidence | `OPEN` |

Final design decision: **`PASS WITH CONDITIONS / GO TO ENGINEER IMPLEMENTATION / NO EXECUTION`**.
There is no unresolved blocker.

## I. Initial exact spec-to-code and resource review

### I.1 Audit frame -- 2026-09-01T12:43:00Z

Target: the first Engineer source set in `test/i4/femref-a3/`, inspected statically after the
Researcher theory-to-code audit in `design-4-1c.md` Section 16.1.  The current success criterion is
only whether `resource-preflight-001/execution-001` may run.  No MATLAB or controller was executed,
and no numerical result is asserted here.

The audit traced the continuous constants, curved topology, $F_T/J_T/\det J_T$, Duffy rules,
same-map $P_1\subset P_2$ checks, phase reduction, nonlinear locator, field reconstruction,
FEM-only rank, publication paths and both Perl controllers.  `perl -c` passes for both controllers.
Static searches found no active read of Markdown, Git, BIE/QZ, estimator or historical FEM output,
and no absolute repository path in the MATLAB call graph.

### I.2 Verdict

**`REVISE / NO PREFLIGHT EXECUTION`** with high confidence.  The curved assembly, determinant
minimum, shared-edge ownership, nonlinear locator and hard-resource controllers are substantially
traceable to the frozen design, but two required preflight protections are not yet reviewable: the
curved-field fixture does not exercise both physical sides of the displaced interface, and the
create-once preflight leaves discard most of the validation evidence that the run is meant to
establish.  Two further exact-spec deviations are local and do not change the method.  All four
repairs are bounded; there is no mathematical-method or objective-resource impossibility.

### I.3 Strongest challenge

The strongest failure mode is a nonlinear point locator that succeeds for a point lying on the
quadratic trace but fails or selects the wrong incident element in the physical sliver between the
straight chord and curved trace.  That error can leave the existing on-trace fixture green while
corrupting common-grid fields, overlap and parity.  The cheapest decisive test is the frozen
curved-versus-affine fixture with fixed interior points on both sides of one displaced interface,
including one point in that sliver, followed by zero uncovered and zero multiply-interior common-grid
counts.

### I.4 Findings

1. **`BLOCKER` -- the mandatory two-sided curved-field fixture is absent.**
   `run_i4_1c_core.m` `LOCAL_curved_affine_fixture` maps and inverts one reference point on a curved
   edge; it proves a curved coordinate differs from the affine coordinate but does not test fixed
   physical points on both sides or the chord--curve sliver required by the frozen implementation
   gate.  Consequence: the preflight cannot yet close the principal field-interpretation failure
   mechanism identified in Section C.  Minimal repair: add the fixed two-sided fixture to the same
   helper, require correct owning-side reconstruction and finite inverse residual, and publish its
   maximum defect/status.  No eigensolve or new method is needed.

2. **`BLOCKER` -- preflight and canonical leaves do not preserve the evidence required for independent
   review.**  `representation.tsv` currently keeps counts, determinant minimum, midpoint/trace and
   inverse residual plus factor `nnz`, but omits the already computed Duffy defects, $Q=4,6,8$
   operator/physical-monomial changes, local/global curved embedding defects, seam residual, phase
   factor check, loop status and field coverage/ambiguity counts.  `preliminary-result.mat` similarly
   omits mesh geometry, map, quadrature, embedding and field-map validation, while the field MAT
   leaves omit the exact `spec`.  Consequence: a successful run would not provide the frozen
   post-preflight/post-run review chain and some canonical claims could not be audited without rerun.
   Minimal repair: serialize compact versions of those existing structures/diagnostics in the
   preflight table or one allowed preflight leaf and in each relevant MAT authority; do not add a
   broad ledger or recompute anything.

3. **`IMPORTANT CAVEAT` -- the curved embedding threshold differs from the frozen value.**
   `LOCAL_spec` uses `embedding_tolerance=1e-12`, whereas design Section 5.3 freezes $10^{-11}$.
   The stricter value cannot make a passing identity less trustworthy, but it can create an
   unauthorized false stop.  Minimal repair: use exactly $10^{-11}$ before preflight.

4. **`IMPORTANT CAVEAT` -- the formal quadrature uncertainty component has the wrong first
   difference.**  The current call `LOCAL_axis_delta(k_ref,scalars.q4,scalars.q6)` evaluates
   $\max\{|k_{Q8}-k_{Q4}|,|k_{Q6}-k_{Q8}|\}$, not the frozen
   $\max\{|k_{Q6}-k_{Q4}|,|k_{Q8}-k_{Q6}|\}$.  This does not affect a representation-only
   preflight, but would misstate later empirical uncertainty.  Minimal repair: compute the two
   adjacent differences explicitly before any formal run.

5. **`MINOR CAVEAT` -- quadrature resolution remains empirical.**  The source correctly computes
   $Q=4,6,8$ mass, stiffness and physical-monomial ladders and labels Q8 stiffness resolution
   `OBSERVED` only when the second stiffness change does not exceed the first.  This is a diagnostic,
   not proof of quadrature error or a filter on a valid preliminary eigenpair.  Preserve the raw
   values and downgrade the interpretation if contraction is absent.

### I.5 Implementation and resource audit

- Interface midpoints are owned by one global sorted constrained edge, recognized only when both
  endpoints lie on the same circle; each has two incident elements with opposite material labels.
  The true angular midpoint, shared trace probes, loop edge count and nonincident-trace checks are
  present.
- The map coefficients and quadratic determinant coefficients agree with the frozen formulas.  The
  minimum candidates include vertices, all three edge stationary points and the nonsingular interior
  stationary point.  A fixture catches a negative interior minimum missed by sampled Duffy points;
  assembly requires finite $\det J_T>\tau_{\det}$ globally and checks it again at every quadrature
  point.
- The Duffy generator checks interval monomials through degree $2Q-1$ and barycentric triangle
  monomials through degree $2Q-2$.  Weighted mass uses the variable determinant; stiffness uses the
  variable inverse Jacobian.  Mass invariance and physical-monomial/stiffness ladders are computed.
- Bernstein boxes use the correct interpolatory-to-Bernstein edge controls
  $2X_{ij}-(X_i+X_j)/2$.  The locator uses affine, centroid, nodal and Q4 Duffy seeds with damped
  Newton; it rejects uncovered or multiply-interior common-grid points.  P2 field values use the
  recovered nonlinear barycentric coordinates and all six shape functions.
- The Cholesky factor is cleared immediately and is not stored in a pair.  No objective evidence
  shows that the smallest meaningful preflight or preliminary eigenpair cannot fit the remaining
  lifecycle or 3 GiB.
- Both controllers use only
  $\min\{T_{\mathrm{run}}+2700\ \mathrm{s},T_{\mathrm{end}}\}$ and the inclusive predicate
  `aggregate RSS >= 3221225472`; process-group and measurement availability checks merely make those
  hard limits enforceable.  There is no lower wall/RSS, forecast, stall, guard or capacity stop.
  Execution leaves are claimed with create-once directory and `O_EXCL` publication semantics.

### I.6 What survived

The continuous problem and constants, conforming shared midpoint topology, variable-Jacobian weak
forms, determinant positivity mechanism, quadrature ladder, P1 embedding construction, vertex and
midpoint phases, residual-bearing generalized eigensolve, preliminary-first FEM-only selection,
current-run information isolation and controller hard limits all survive static scrutiny.  The
unresolved issues are local implementation/publication defects rather than evidence against curved
$P_2$ FEM.

### I.7 Minimal resolution and next gate

The same Engineer should make only the four bounded repairs above in the existing five-file source
set.  The Researcher should re-audit the exact repaired lines.  This Skeptic will then append a
focused re-review of the two-sided fixture, preserved validation schema, exact embedding tolerance
and adjacent-$Q$ formula.  Only a re-review with no blocker may authorize the create-once preflight;
formal execution remains separately gated after its artifacts are reviewed.

### I.8 Open-problem handoff

| Stage | Category | Item | Blocking scope | Cheapest next check | Suggested status |
|---|---|---|---|---|---|
| I4.1c implementation | `BLOCKER` | Two-sided curved inverse-map fixture absent | Preflight execution | Add and statically trace fixed owning-side/sliver probes | `IN REPAIR` |
| I4.1c publication | `BLOCKER` | Validation evidence discarded by allowed leaves | Preflight execution and later canonical interpretation | Serialize compact existing validation values, then schema inspection | `IN REPAIR` |
| I4.1c implementation | `IMPORTANT CAVEAT` | Embedding tolerance and adjacent-$Q$ formula differ from design | False preflight stop / later uncertainty only | Exact literal/formula inspection after patch | `IN REPAIR` |

Initial source decision: **`REVISE / NO PREFLIGHT EXECUTION`**.

## J. Focused spec-to-code and resource re-review

### J.1 Scope -- 2026-09-01T12:50:00Z

This append-only re-review inspected only the four repairs identified in Section I, their immediate
callers and the unchanged resource/isolation boundary.  It also checked the Researcher re-audit in
`design-4-1c.md` Section 16.2.  No MATLAB or controller was run.

### J.2 Repair closure

1. **Two-sided nonlinear fixture -- closed.**  `LOCAL_curved_affine_fixture` now constructs the
   quadratic trace at a fixed parameter, forms the nonzero chord-to-trace bulge, and tests the
   between-chord-and-trace point, the opposite-side point and the trace point through the same
   conservative-box/nonlinear locator used by fields.  It requires opposite material owners,
   deterministic trace ownership, positive recovered Jacobians, small round-trip residual and a
   quantitatively nonzero failure of affine-triangle membership for the sliver point.  The full
   retained common grid still requires zero uncovered and zero multiply-interior points.
2. **Validation evidence -- closed for the preflight gate.**  Each `representation.tsv` row now
   preserves Duffy defects, local/full/reduced curved-$P_1$ embedding defects, phase commutation,
   seam residual, matrix/factor counts, determinant, endpoint/midpoint/trace/radial defects and
   nonlinear coverage counts.  The preliminary and final result payloads now carry compact element,
   embedding, quadrature, mapping, geometry and field-map structures.  These are the already
   computed mathematical values, not a new audit ledger.
3. **Embedding tolerance -- closed.**  The single local/global threshold is exactly the frozen
   $10^{-11}$.
4. **Adjacent quadrature drift -- closed.**  `LOCAL_quadrature_delta(q4,q6,q8)` computes exactly
   $\max\{|k_{Q6}-k_{Q4}|,|k_{Q8}-k_{Q6}|\}$ and returns `NaN` when any member is unavailable.

### J.3 Resource, identity and isolation recheck

Both no-argument controllers remain fixed to the intended create-once identity.  The only numerical
resource predicates are

$$
\min\{T_{\mathrm{run}}+2700\ \mathrm{s},T_{\mathrm{end}}\}
$$

and inclusive aggregate process-tree RSS `>= 3221225472`.  Process-group and `ps` availability
checks are necessary enforcement conditions, not lower scientific/resource gates.  Static searches
again found no active read of Markdown, Git, BIE/QZ, estimator, density, `femref-a1`, `femref-a2`,
historical output or an absolute repository path.  Both Perl controllers pass `perl -c`, and
`git diff --check` passes.

### J.4 Findings and caveats

There is **no unresolved `BLOCKER`** for the representation preflight.

1. **`IMPORTANT CAVEAT` -- all curved numerical properties remain unverified by execution.**  The
   static source now contains the correct checks, but determinant margins, inverse-map residuals,
   field coverage, embedding defects, factor fill and peak RSS are unknown until the preflight.
   Cheapest decisive check: the now-authorized six-row actual-only preflight and immediate artifact
   review.
2. **`IMPORTANT CAVEAT` -- formal eigensolver and field memory remain unmeasured.**  A successful
   preflight establishes representation feasibility only.  It cannot authorize formal science;
   simultaneous lifetimes and remaining lifecycle must be reviewed after preflight.
3. **`MINOR CAVEAT` -- MAT authority is distributed across companion result and field leaves.**
   The result leaf contains `spec`, validation, selection/rank and scalar, while the companion field
   leaf contains the complete selected subspace and mesh.  The pair is sufficient within one
   create-once execution, though duplicating all metadata into every field leaf is neither necessary
   for this preflight nor a reason to enlarge the runtime schema.

### J.5 Verdict and exact authorization

**`PASS WITH CONDITIONS / AUTHORIZE RESOURCE PREFLIGHT ONLY`**, high confidence from static source
inspection.  The four Section I deviations are repaired without changing the continuous problem,
curved-$P_2$ weak form, schedule, FEM-only rank or claim boundary.

The exact authorized next command is only the create-once
`resource-preflight-001/execution-001` controller.  Formal `run-001/execution-001`, BIE distance,
effectivity, result promotion and project-status synchronization remain blocked.  The preflight
artifacts and measured resource markers require immediate same-Skeptic review before any refreshed
formal gate.

## K. Preflight `execution-001` failure and retry gate

### K.1 Immutable execution facts -- 2026-09-01T12:55:00Z

The create-once leaf `resource-preflight-001/execution-001` is consumed and preserved.  Its
authoritative artifacts report:

| Fact | Observed value |
|---|---:|
| controller terminal | `RSS_ENFORCEMENT_UNAVAILABLE` |
| scientific terminal | `UNAVAILABLE` |
| whole-command wall | $0.001963$ s |
| aggregate peak RSS | $0$ B |
| MATLAB exit/signal | $0/9$ |
| representation rows | none |

`run.log` is empty, and neither `representation.tsv` nor any scientific MAT artifact exists.  The
controller killed the child before MATLAB startup because its `/bin/ps` process-tree measurement
could not be obtained.  A direct read-only `/bin/ps` probe in the same restricted execution context
also returns `operation not permitted`.  Therefore this is an **operational controller/environment
failure**, not a mesh, mapping, quadrature, memory or curved-$P_2$ scientific failure.  Peak RSS of
zero is only the controller's pre-start observation and says nothing about scientific resource use.

### K.2 Focused retry patch review

The repair changes only the prospective preflight identity:

- `run_preflight.pl` now claims `resource-preflight-001/execution-002` and passes that exact pair to
  MATLAB;
- `run_i4_1c_core.m` accepts that pair only for preflight;
- formal remains exactly `run-001/execution-001`;
- the README records the preserved failure and active retry; and
- `resource-preflight-001/execution-002` is absent before launch.

No mathematical constant, mesh, map, quadrature, validation, branch, artifact schema, wall/RSS
predicate or formal identity changed.  The preflight controller still fails closed if process-tree
RSS measurement is unavailable; the retry must therefore be launched in an execution context where
the already-required `/bin/ps` measurement is permitted.  This is not a relaxation of the 3 GiB
limit.  Perl syntax and `git diff --check` pass.

### K.3 Findings and verdict

There is no unresolved scientific or source `BLOCKER` for the retry.

1. **`IMPORTANT CAVEAT` -- execution permission is part of the operational precondition.**  Reusing
   the restricted context would deterministically reproduce `RSS_ENFORCEMENT_UNAVAILABLE` before
   MATLAB.  Cheapest decisive action: launch the same reviewed controller in the authorized context
   that permits `/bin/ps`; do not bypass or weaken RSS monitoring.
2. **`MINOR CAVEAT` -- `execution-001` contains no resource estimate.**  Its $0$ B value cannot update
   the prospective formal memory assessment.

Verdict: **`PASS WITH CONDITIONS / AUTHORIZE PREFLIGHT EXECUTION-002 ONLY`**.  The exact authorized
next identity is `resource-preflight-001/execution-002`, with the unchanged 2700 s/lifecycle and
inclusive 3,221,225,472 B process-tree predicates.  Formal science, BIE distance, effectivity and
result promotion remain blocked pending immediate post-preflight artifact/resource review.

Timestamp correction: the Section K.1 header's `12:55:00Z` is a transcription error; the focused
artifact and retry review completed at `2026-09-01T12:40:03Z`.

## L. Post-preflight review of `execution-002`

### L.1 Artifact and resource facts -- 2026-09-01T12:43:06Z

The immutable `resource-preflight-001/execution-002` leaf reached MATLAB and completed one of the
six planned rows before a fail-closed representation diagnostic stopped the fixed suffix:

| Fact | Observed value |
|---|---:|
| controller terminal | `PREFLIGHT_OUTPUT_INCOMPLETE` |
| scientific terminal | `CURVED_FIELD_RECONSTRUCTION_INVALID` |
| whole-command wall | $75.731769$ s |
| aggregate peak process-tree RSS | $914{,}505{,}728$ B |
| MATLAB exit/signal | $0/0$ |
| completed representation rows | $1/6$ |
| guided eigensolves | $0$ |

The complete bulk row is numerically valid at $(s,g,Q)=(9,24,8)$: $V=160$, $T=282$, $E=441$,
full/reduced DOF $601/564$, `nnz(K)=nnz(M)=6486`, valid fill-reduced permutation,
factor `nnz` $13291$, seam residual zero and global determinant minimum
$5.5471598555610212\times10^{-4}$.  Its largest reported Duffy defect is
$7.77\times10^{-15}$, local/global/reduced embedding defects are at most
$1.13\times10^{-15}$, interface endpoint/midpoint/shared-trace defects are at roundoff, and the
quadratic-arc radial trace defect is $1.3723246503338782\times10^{-6}$.  Bulk field-map values are
not applicable and remain `NaN` by design.

The first failed object is `p2-anchor` with $(N,s,g,Q)=(4,9,24,6)`.  Its topology and assembly
markers completed; the failure occurred inside `FIELD_MAP_BEGIN` at the newly added two-sided
fixture, before the row, phase reduction or SPD values were published.  The retained message is
`The deterministic two-sided curved-interface fixture failed.`  No preliminary/formal eigenpair,
field, branch or reference was attempted.

### L.2 Classification

This is a **bounded implementation-diagnostic failure**, not evidence that the curved map, weak
form, eigensolver or method is scientifically invalid.  The bulk representation passed, the anchor
reached field reconstruction, and both wall/RSS values are far below the hard limits.  However, the
current artifact does not log which compound predicate failed or its raw owners, material labels,
coverage counts and residuals.  It therefore cannot distinguish a genuine nonlinear-location
defect from an over-specified fixture predicate.

1. **`BLOCKER` -- failure predicate is not yet attributable.**  Formal science and another retry are
   blocked until the exact first false condition and raw values are preserved.  Cheapest repair:
   add one concise raw predicate line before raising, then correct only the demonstrated fixture
   implementation error without weakening full-grid coverage, positive-Jacobian or two-sided
   ownership checks.
2. **`IMPORTANT CAVEAT` -- anchor validation evidence is partial.**  Its mesh counts and assembly
   matrices existed transiently but the failure row intentionally contains zeros/`NaN`; they cannot
   be promoted as passed representation evidence.
3. **`MINOR CAVEAT` -- stage-resolved RSS is sparsely sampled.**  The whole-tree peak of
   $914{,}505{,}728$ B is authoritative; zero-valued short stage rows only mean the 0.25 s controller
   poll did not observe those brief intervals.

### L.3 Verdict and bounded next gate

Verdict: **`REVISE / NO FORMAL / NO EXECUTION-003 YET`**.  Preserve all `execution-002` artifacts.
The same Engineer may modify only the two-sided fixture diagnostic/logic, add its concise raw
predicate evidence, and switch the create-once preflight identity to
`resource-preflight-001/execution-003`.  The continuous model, curved discretization, all global
field-coverage checks and resource predicates remain frozen.  Researcher and same-Skeptic focused
source review must precede that retry.

## M. Focused fixture-repair review for `execution-003`

### M.1 Root-cause check -- 2026-09-01T12:44:14Z

The `execution-002` failure is traceable to the fixture, not the frozen locator.  The locator ranks
multiple accepted elements by the maximum recovered minimum barycentric coordinate and uses the
smallest triangle ID only inside its $5\times10^{-15}$ numerical tie set.  The old fixture instead
required the trace owner to equal the smallest incident triangle ID unconditionally.  A shared trace
with a small inverse-coordinate asymmetry can therefore be deterministically and correctly owned by
the other incident element while failing the old assertion.

The patch removes only that contradictory assertion.  The trace owner must now belong to the two
incident elements, and a repeated identical trace query must return exactly the same owner and
barycentric coordinates to `coordinate_tolerance`.  It retains:

- distinct owners for the two physical sides;
- material-inside ownership for the chord--curve sliver and material-outside ownership on the other
  side;
- zero uncovered and zero multiply-interior fixture points plus a shared-trace observation;
- positive recovered Jacobians and forward-map residual tolerance; and
- a nonzero affine-membership counterexample for the sliver point.

Before any fixture predicate can raise, `CURVED_FIXTURE_RAW` now appends owners, material flags,
incident IDs, barycentric minima, shared count, maximum inverse residual and repeated-query values.
This is sufficient to attribute a future failure without changing the locator, field samples or
scientific acceptance rules.

### M.2 Identity/resource review and findings

The active identity is exactly `resource-preflight-001/execution-003`; `execution-001` and
`execution-002` remain immutable, `execution-003` is absent, and formal remains exactly
`run-001/execution-001`.  The continuous model, curved map/forms, mesh, quadrature, common grid,
branch logic, artifacts and hard resource predicates are unchanged.  Perl syntax and
`git diff --check` pass.

There is **no unresolved `BLOCKER`** for this retry.

1. **`IMPORTANT CAVEAT` -- repaired predicate remains unverified by MATLAB.**  The raw line and
   six-row artifacts must be inspected immediately after execution; any remaining failure stays an
   implementation diagnostic and may not be relabeled scientific without its raw values.
2. **`IMPORTANT CAVEAT` -- the host process-observation condition remains mandatory.**  The retry
   must run where `/bin/ps` can enforce aggregate process-tree RSS; monitoring may not be bypassed.

Verdict: **`PASS WITH CONDITIONS / AUTHORIZE PREFLIGHT EXECUTION-003 ONLY`**, high confidence from
the frozen owner rule and focused diff.  Formal science, BIE comparison, effectivity, result
promotion and status synchronization remain blocked pending a complete preflight and immediate
same-Skeptic artifact/resource review.

## N. Post-preflight artifact/resource review of `execution-003`

### N.1 Completeness and measured resources -- 2026-09-01T12:52:16Z

All four allowed preflight artifacts exist under the immutable
`resource-preflight-001/execution-003` leaf.  The controller and scientific terminals are
respectively `NATURAL_EXIT` and `PREFLIGHT_COMPLETE`; MATLAB exited $0/0$.  The whole command used
$310.361142$ s and peak aggregate process-tree RSS $978{,}026{,}496$ B.  Both are measured values,
well below the per-run hard predicates.  `representation.tsv` contains its header plus exactly six
PASS rows covering five distinct topologies and both anchor quadratures.  No guided eigensolve ran.

| Representation | $Q$ | Full/reduced DOF | $\min\det J_T$ | Max inverse residual |
|---|---:|---:|---:|---:|
| bulk $s9,g24$ | 8 | $601/564$ | $5.5472\times10^{-4}$ | not applicable |
| anchor $N4,s9,g24$ | 6 | $5017/4836$ | $5.5472\times10^{-4}$ | $4.07\times10^{-13}$ |
| anchor $N4,s9,g24$ | 8 | $5017/4836$ | $5.5472\times10^{-4}$ | $4.07\times10^{-13}$ |
| mesh $N4,s12,g24$ | 8 | $7473/7232$ | $3.7306\times10^{-4}$ | $1.74\times10^{-12}$ |
| geometry $N4,s9,g32$ | 8 | $5785/5604$ | $4.1813\times10^{-4}$ | $1.67\times10^{-12}$ |
| supercell $N5,s9,g24$ | 8 | $6181/5964$ | $5.5472\times10^{-4}$ | $4.06\times10^{-13}$ |

Every determinant minimum is positive by a margin many orders above its roundoff-scale threshold.
Every Duffy defect is below $7.8\times10^{-15}$; the maximum local/global/reduced curved-$P_1$
embedding defect is below $1.5\times10^{-15}$; every seam residual is at most
$1.25\times10^{-16}$; all fill-reduced permutations and SPD factorizations pass.  Every defect
common grid has zero uncovered and zero multiply-interior points.  Endpoint/midpoint radius and
shared-trace defects are at roundoff.  The observed quadratic-arc radial defect decreases from
$1.3723\times10^{-6}$ at $g=24$ to $4.3475\times10^{-7}$ at $g=32$; this is empirical geometry
evidence, not a certified circle-error bound.

### N.2 Fixture and artifact integrity

Each defect build records one `CURVED_FIXTURE_RAW` line.  In every case the two off-trace points have
distinct inside/outside owners, the trace owner belongs to the two incident elements, the repeated
trace query returns the same owner and barycentric minimum, shared count is one and the maximum raw
inverse residual is at most $1.74\times10^{-12}$.  The values directly confirm that the
`execution-002` minimum-ID assertion was the fixture defect and that the repaired locator contract
is internally consistent on all four tested defect topologies.

The summary, representation table, log and append-only resource ledger agree on identity, terminal,
wall and peak RSS.  Brief stages with a zero sampled peak reflect 0.25 s polling; the whole-command
peak and nonzero long-stage markers remain authoritative.  Prior `execution-001` and
`execution-002` artifacts are preserved unchanged.

### N.3 Findings and post-preflight verdict

There is **no unresolved `BLOCKER`** in the actual representation preflight.

1. **`IMPORTANT CAVEAT` -- preflight does not measure eigensolver/selected-field coexistence.**  Its
   $978{,}026{,}496$ B peak establishes all planned mesh, curved assembly, nonlinear field-map,
   reduction and Cholesky representations below 3 GiB, but formal peak must still be monitored.
2. **`IMPORTANT CAVEAT` -- polynomial geometry remains approximate.**  The $g$-dependent radial
   trace defect contracts but is not a certified bound on the exact-circle eigenvalue error.
3. **`MINOR CAVEAT` -- Q6/Q8 preflight equality concerns representation only.**  Identical topology,
   DOF and sparsity do not establish eigenvalue quadrature resolution; formal branch values and the
   $Q=4,6,8$ ladder must carry that empirical assessment.

Post-preflight verdict: **`PASS / CURVED REPRESENTATION AND RESOURCE PREFLIGHT COMPLETE`**, high
confidence from mutually consistent artifacts.  This closes the representation gate but does not by
itself authorize formal MATLAB.  The formal identity `run-001/execution-001` is absent and remains
blocked until the refreshed Researcher theory-to-code and same-Skeptic exact formal spec/resource
review are recorded.

## O. Refreshed formal spec-to-code and resource gate

### O.1 Audit frame -- 2026-09-01T12:53:39Z

This gate combines the successful actual-representation evidence in Section N with the unchanged
formal source and the Researcher refresh in `design-4-1c.md` Section 16.7.  The prospective identity
`run-001/execution-001` is absent.  No formal MATLAB has run.

The formal dependency chain is traceable as follows:

1. the reviewed $Q=6$ anchor is built, reduced and solved at exactly five frozen twists with 48
   roots, with a single 60-root extension only if coverage or three-consecutive branch selection
   requires it;
2. finite positive eigenvalues, generalized residuals, mass orthogonality and whole numerical
   clusters precede construction of any field-bearing object;
3. nonlinear six-function common-grid fields feed overlap, localization and parity, and the
   preliminary winner is chosen by the frozen FEM-only total rank;
4. preliminary result and field leaves are atomically committed before $Q=8$ or any refinement can
   run;
5. the $Q=8$ anchor is independently assembled and ranked; its overlap with the preliminary branch
   is reported but cannot replace its canonical FEM-only winner;
6. the legal suffix is the fixed $h,g,N,\vartheta,Q$, solver-tolerance and bulk schedule, yielding
   exactly 71 calls or 76 only after the one preliminary extension; and
7. all drift is observed/empirical, missing axes remain explicit, and no artifact asserts a
   continuous existence theorem, certified bound or estimator effectivity.

Static isolation remains intact: the formal source has no read of historical output, `femref-a1`,
`femref-a2`, Markdown, Git, BIE/QZ, densities or the estimator.  Its controller admits only
`run-001/execution-001`, claims the directory once, and retains the same lifecycle epoch, 2700 s
command cap and inclusive aggregate RSS predicate 3,221,225,472 B.

### O.2 Resource judgment

The preflight exercised every largest prescribed topology, variable-Jacobian assembly, nonlinear
field locator, phase reduction and fill-reduced Cholesky.  The largest observed dimension/factor was
$7232/230867$ nonzeros and the measured peak was $978{,}026{,}496$ B, leaving
$2{,}243{,}198{,}976$ B below the hard predicate.  It did not exercise Arnoldi vectors or retained
selected fields, so this is not a formal peak upper bound.  Nevertheless there is no measured lower
bound suggesting the five-slice preliminary anchor cannot fit, and the controller will stop the
whole process tree at the authorized limits.

The source retains the already published preliminary mesh while constructing the final anchor.
This is unnecessary residence and may raise the peak, but the two anchors share the tested
$5017/4836$ size and the measured headroom is more than twice the complete preflight peak.  Without
evidence of resource impossibility it is an `IMPORTANT CAVEAT`, not a blocker or a new lower gate.

### O.3 Findings and formal verdict

There is **no unresolved `BLOCKER`** for the formal execution.

1. **`IMPORTANT CAVEAT` -- formal eigensolver coexistence is unmeasured.**  Peak RSS and elapsed time
   must be taken only from the external controller; a hard stop after preliminary publication must
   preserve that authority and be reviewed as partial, not rerun by altering science.
2. **`IMPORTANT CAVEAT` -- preliminary and final components may differ.**  Such a difference must be
   reported with both FEM rankings and cross-overlap; it cannot be repaired by choosing the root
   closest to BIE.
3. **`IMPORTANT CAVEAT` -- quadrature/geometry/refinement evidence remains empirical.**  Absent
   contraction or a missing optional axis downgrades interpretation but cannot erase a valid
   residual-bearing field branch.
4. **`MINOR CAVEAT` -- the preliminary mesh remains resident into final-anchor construction.**  This
   is a memory-efficiency issue only under current evidence; it does not change the mathematical
   result and is governed by the hard process-tree monitor.

Formal gate verdict: **`PASS WITH CONDITIONS / AUTHORIZE run-001/execution-001`**, high confidence
for specification conformance and moderate confidence for completing the full optional suffix
inside one command.  The run must use the approved host process-observation context and unchanged
hard predicates.  No BIE distance, effectivity, result promotion or project-status synchronization
is authorized until the same Skeptic has reviewed formal artifacts, budgets, retry ledger,
eigenpair/field identity, refinement evidence and claim boundary.

## P. Read-only formal-artifact inspector gate

### P.1 Audit frame -- 2026-09-01T13:15:02Z

The formal controller has reported a natural, complete `run-001/execution-001`, but the six MAT
leaves must be inspected before the post-run scientific verdict.  Because these are MATLAB v7.3
artifacts, the Engineer added a read-only MATLAB inspector and a separate create-once monitored
controller.  This gate reviews only those two prospective sources; it does not accept the formal
result in advance.

The inspector is fixed to the current `run-001/execution-001` leaf.  It loads the preliminary,
final and refinement result/field pairs, but calls neither the FEM core nor `eigs` and writes no
canonical data.  It cross-checks summary, terminal and resource authority; verifies
$\lambda=k^2$; prints the FEM-selected objects, tracking edges, residual, localization, parity and
coverage records; prints element, embedding, quadrature, geometry, map and nonlinear field
diagnostics; prints all six empirical refinement components; and independently recomputes
matched-axis common-grid subspace overlaps from the stored curved-$P_2$ fields.  Missing duplicated
metadata in a field leaf is explicitly downgraded to `SCHEMA_CAVEAT`, while a disagreement in
scientific authority, a nonfinite or empty field, incompatible field grids or a failed invariant
terminates the inspector.

### P.2 Isolation, identity and resource review

The separate controller admits only `artifact-review-001/execution-001`, whose directory is absent
at this gate.  It uses relative current-attempt paths, create-once publication, a dedicated process
group, process-tree RSS measurement and the actual deadline

$$
\min(T_{\mathrm{review}}+2700\ \mathrm{s},T_{\mathrm{end}}),
$$

with the unchanged inclusive $3{,}221{,}225{,}472$ B predicate.  It publishes only a log, resource
ledger and summary-last review leaf.  It reads no Markdown, Git, BIE/QZ, density, estimator or
historical FEM attempt.  In particular, it neither computes nor imports the BIE distance; that
scalar remains a later Skeptic-side calculation after the FEM winner has been verified as frozen.
Perl syntax and `git diff --check` pass.

There is **no unresolved `BLOCKER`** for this read-only diagnostic.

1. **`IMPORTANT CAVEAT` -- recomputed overlaps are artifact checks, not new selection evidence.**
   The inspector may confirm that stored matched-axis fields overlap the frozen final fields, but
   must not use those recomputations to replace the canonical FEM-only ranking or alter an axis
   scalar.
2. **`MINOR CAVEAT` -- some field-leaf metadata may be intentionally nonduplicated.**  The inspector
   reports such omissions instead of treating an absent duplicate as corruption.  Scalar/result
   authority and nonempty finite fields remain mandatory.
3. **`MINOR CAVEAT` -- the diagnostic consumes lifecycle and per-command resources.**  Its measured
   wall/RSS must be reported, even though it performs no eigensolve.

Verdict: **`PASS WITH CONDITIONS / AUTHORIZE artifact-review-001/execution-001 ONLY`**, high
confidence.  The exact next action is the monitored, read-only inspector.  Formal result promotion,
BIE distance, effectivity and project-status synchronization remain blocked until its create-once
artifacts and the formal canonical leaves receive the post-run review below.

## Q. Formal post-run artifact, resource and claim review

### Q.1 Audit frame and authority -- 2026-09-01T13:18:37Z

**Target.**  This audit asks whether the frozen curved isoparametric $P_2$ method produced a
numerically valid, field-bearing FEM branch and an interpretable empirical reference inside the
authorized resources.  The intended output is a numerical reference artifact, not a theorem,
certified bound, continuous guided-mode existence proof or estimator-effectivity result.

**Materials.**  I independently checked the create-once formal summary, work terminal, resource
ledger and log; the six canonical MAT leaves through the monitored read-only inspector; the three
inspector artifacts; the successful representation preflight; and the frozen design/source map.
The Researcher Section 16.9 assessment was treated as a claim and agrees with those raw records.
The current-stage success criterion is a legal curved mesh, finite Hermitian forms with SPD mass, a
converged residual-bearing field branch selected only by FEM data, canonical publication and an
honest empirical-resolution claim.

### Q.2 Execution, publication and resource facts

`run-001/execution-001` ended `NATURAL_EXIT` with scientific terminal
`CURVED_P2_EMPIRICAL_REFERENCE_REFINEMENT_COMPLETE`.  Its summary, work terminal and terminal
resource row agree on 71 attempted/completed/planned solves, $669.387044$ s wall and peak aggregate
process-tree RSS $1{,}171{,}079{,}168$ B.  The largest observed peak occurred at the end of the bulk
eigensolver.  MATLAB exited $0/0$; all preliminary, final and refinement result/field pairs were
committed before the summary-last leaf.  The run stayed $2{,}050{,}146{,}304$ B below the inclusive
3 GiB predicate and far below its 2700 s command cap.

The independent `artifact-review-001/execution-001` ended `NATURAL_EXIT` with terminal
`PASS_WITH_SCHEMA_CAVEATS`; it used $13.887655$ s and peak RSS $919{,}322{,}624$ B.  It verified
text/scalar authority, loaded all six MAT leaves, checked finite nonempty field payloads and
recomputed the stored cross-configuration field overlaps.  The earlier successful representation
preflight used $310.361142$ s and $978{,}026{,}496$ B.  The two prior failed preflights remain
preserved and are correctly classified in Sections K--M as controller/fixture implementation
failures, not additional scientific attempts.

### Q.3 Canonical branch and field identity

The immutable final authority is

$$
k_{\mathrm{ref}}^{\mathrm{curved},P_2}=1.8328570940899811,
\qquad
\lambda_{\mathrm{ref}}^{\mathrm{curved},P_2}=3.3593651273559701,
$$

and the inspector independently confirms $\lambda_{\mathrm{ref}}=k_{\mathrm{ref}}^2$ to roundoff.
Both independently ranked $Q=6$ and $Q=8$ anchors select object IDs
`[8, 32, 55, 78, 101]`: root 9, dimension one, at the five frozen twists
$0,\pi/4,\pi/2,3\pi/4,\pi$.  The final component has four real continuation edges, minimum
within-branch overlap $0.99999991179010128$ and maximum normalized generalized residual
$1.167537059550097\times10^{-16}$.  The preliminary/final same-phase match is at least
$0.99999999999999978$.

All five selected subspaces and nonlinear common-grid samples are finite and nonempty.  The anchor
field leaf has $1300$ vertices, $2418$ triangles, $3717$ shared edges and $5017$ full $P_2$ DOFs;
the validated reduction has $4836$ DOFs.  Every selected object is strongly localized on the
registered diagnostics: $L_{\mathrm{core}}\ge0.96429178406871063$ and tail
$\le0.0030561968315734531$.  Endpoint fields are empirically even, with parity-invariance defect
about $5.15\times10^{-4}$; parity at non-endpoint twists is correctly marked unavailable.  All five
48-root slices cover the frozen $W_3$ window, so no 60-root extension was invoked.

The defensible mode label is **field-tracked, strongly localized, endpoint-even, noncertified**.
The canonical scalar is the frozen midpoint of the selected branch's eigenvalue envelope; it is
supported by five discrete eigenfunctions but is not asserted to equal one particular finite-cell
Ritz root.  For example, the central-twist stored root has
$k=1.8328570963406079$, only $2.25\times10^{-9}$ away.  Thus the artifacts support a
field-bearing branch reference, but the pair $(\lambda_{\mathrm{ref}},u)$ must not be described as
an exact single-twist discrete eigenpair without naming one of the stored branch fields.

### Q.4 Discretization and refinement evidence

The final anchor has minimum $\det J=5.5471598555598828\times10^{-4}$ against a
$1.14\times10^{-13}$ determinant tolerance, determinant-polynomial defect
$7.79\times10^{-16}$, finite nonlinear inverse residual $4.07\times10^{-13}$, no uncovered or
multiply-interior retained-grid points and a passing two-sided curved-interface fixture.  Circle
endpoints and arc midpoints are on the exact radius to roundoff, adjacent traces agree exactly, and
the quadratic-arc radial trace defect is $1.3723246506114339\times10^{-6}$.  Local, full and reduced
$P_1\subset P_2$ form defects are below $1.4\times10^{-15}$; seam error is at most
$1.25\times10^{-16}$ in the preflight.  Stiffness change contracts from
$5.8950813762003697\times10^{-9}$ at $Q=4\to6$ to
$1.6511941432603152\times10^{-14}$ at $Q=6\to8$; mass and low-monomial changes are at roundoff.

The field-matched ladder is:

| Axis | Coarse | Anchor | Fine |
|---|---:|---:|---:|
| mesh $s$ | $1.8329271291562377$ ($s=6$) | $1.8328570940899811$ ($s=9$) | $1.8328176106479204$ ($s=12$) |
| circle segments $g$ | $1.8328849181855693$ ($g=16$) | $1.8328570940899811$ ($g=24$) | $1.8328473278767723$ ($g=32$) |
| supercell $N$ | $1.8328567990799984$ ($N=3$) | $1.8328570940899811$ ($N=4$) | $1.8328570969854137$ ($N=5$) |
| quadrature $Q$ | $1.8328570940913185$ ($Q=4$) | $1.8328570940899886$ ($Q=6$) | $1.8328570940899811$ ($Q=8$) |

The added-twist and loose-tolerance scalars equal the final scalar at stored precision.  The ten
stored matched-configuration field groups have minimum common-grid overlaps between
$0.99998210429072887$ ($N=3$) and unity to roundoff.  The frozen observed components are

$$
(\delta_h,\delta_g,\delta_N,\delta_{\vartheta},\delta_Q,\delta_{\mathrm{tol}})
=(7.0035066256579626\times10^{-5},
2.7824095588213638\times10^{-5},
2.9500998266485112\times10^{-7},0,
1.3298251388960125\times10^{-12},0),
$$

with

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}
=9.8154173157283253\times10^{-5}.
$$

All 17 sampled bulk slices returned 40 finite roots.  This is a complete sampled inventory, but its
reported frequency ranges do not establish a continuous bulk gap or distinguish gap, edge and
embedded status.  The correct current bulk relation is therefore **unclassified by this run**;
that does not negate the independently tracked finite-supercell field branch.

### Q.5 Late BIE distance and claim boundary

Only after the FEM winner and field leaves were frozen, I evaluated the authorized review-side
constant and obtained

$$
d_{\mathrm{BIE}}
=\left|1.8328570940899811-1.832770289108157\right|
=8.6804981824117888\times10^{-5}.
$$

This positional distance is smaller than, but of the same scale as,
$\Delta_{\mathrm{ref}}^{\mathrm{obs}}$.  It is evidence of numerical consistency only.  It is not
an error estimate, certified bound, root-selection input or estimator-effectivity comparison.

### Q.6 Strongest challenge and findings

The strongest challenge is **overinterpreting the apparent BIE agreement**.  Both $h$ and $g$
ladders cross the anchor rather than establish one-sided asymptotic convergence, the observed sum
is dominated by those axes, and $d_{\mathrm{BIE}}<\Delta_{\mathrm{ref}}^{\mathrm{obs}}$.  These facts
support an empirical reference near the BIE value but cannot establish which value is more accurate
or bound their common bias.

There is **no unresolved `BLOCKER`** for accepting the current empirical curved-$P_2$ reference.

1. **`IMPORTANT CAVEAT` -- non-asymptotic, non-certified uncertainty.**  Location: refinement MAT
   pair and inspector `REFINEMENT` rows.  Evidence: sign changes about the anchor on both $s$ and
   $g$, with only three points per axis.  Consequence: the finite sum is a sensitivity scale, not an
   upper bound.  Uncertainty: common mesh/geometry bias is unbounded.  Cheapest decisive future
   check: one preregistered out-of-sample $s$ or $g$ point, without BIE-guided root choice.
2. **`IMPORTANT CAVEAT` -- 13 documented artifact-schema omissions.**  Location: companion field
   leaves and refinement leaves.  Evidence: `spec`, validation, selection, spectrum authority,
   scalar and interface metadata are not duplicated in every MAT leaf, contrary to the literal
   all-leaf wording of Design Section 13.1.  Consequence: individual leaves are not independently
   self-describing, although paired result/field identities, object IDs, scalars and fields all
   cross-check.  Cheapest resolution: disclose the paired-file requirement and preserve the
   create-once files; do not overwrite them.
3. **`IMPORTANT CAVEAT` -- canonical scalar is a branch representative.**  Location:
   `LOCAL_component_scalar` and final selected objects.  Evidence: $k_{\mathrm{ref}}$ is computed
   from the component envelope, while each stored eigenfunction has its own twist-specific root.
   Consequence: future work must compare against the branch scalar by the frozen rule or name an
   exact stored phase/root when claiming an eigenpair.  Cheapest resolution: wording only; no rerun
   or post hoc root replacement is justified.
4. **`IMPORTANT CAVEAT` -- continuous spectral status is unresolved.**  Location: 17-slice bulk
   inventory.  Evidence: all slices are valid, but no certified gap or continuous-existence
   argument is present.  Consequence: the result is a localized empirical finite-supercell mode,
   not a proved guided mode in a continuous gap.  Cheapest future check: analyze sampled band
   neighbors as a diagnostic; a continuous claim would require a separate certified stage.
5. **`MINOR CAVEAT` -- actual topology metadata is incomplete for three coarse refinement meshes.**
   Location: formal refinement fields and preflight table.  Evidence: actual $V,T,E$ and
   reduced-DOF rows exist for the anchor, $s=12$, $g=32$, $N=5$ and bulk meshes, but not for
   $s=6$, $g=16$ or $N=3$; only their pre-run DOF expectations remain.  Consequence: the numerical
   scalar/field comparison is interpretable, but the final mesh inventory must label those counts
   as unavailable rather than promote expectations to measurements.  Cheapest resolution: report
   the omission; the immutable run must not be rewritten.
6. **`MINOR CAVEAT` -- MATLAB ignored the redundant numeric-matrix `eigs` `issym` option.**
   Location: formal `run.log`.  Evidence: the warning repeats on each solve, while explicit
   Hermitian, SPD, residual and orthogonality checks all passed.  Consequence: log noise only under
   current evidence.  Cheapest future repair: remove the ignored option in a future attempt, not
   from this immutable run.

### Q.7 What survived, minimal resolution and verdict

The same continuous model and curved-$P_2$ weak discretization survive scrutiny; actual curved
geometry, variable-Jacobian quadrature, seam reduction, SPD/Hermitian algebra, nonlinear field
reconstruction, FEM-only branch tracking, multi-axis persistence, resource monitoring and
create-once publication all have direct evidence.  No BIE/QZ, density, estimator or historical
reference entered the formal run or selected the component.

**Final verdict: `PASS WITH CONDITIONS`**, high confidence for numerical validity and branch
identity, moderate confidence for resolution beyond the observed ladder.  Accept the reported
numbers only as a **noncertified empirical curved-$P_2$ branch reference with complete finite-axis
inventory**.  No rerun or artifact rewrite is needed for this stage.  The minimal handoff is to
preserve all artifacts, disclose the six caveats above, keep bulk/existence and certification as
future work, and prohibit any estimator-effectivity claim from this result alone.

Open-problem handoff: asymptotic mesh/geometry resolution (`future refinement`, important,
nonblocking now); continuous bulk-gap/existence status (`future certification`, important,
nonblocking now); and paired-leaf schema completeness (`future implementation`, minor,
nonblocking now).  The project owner, not this review, decides whether to enter any of these in the
central ledger.
