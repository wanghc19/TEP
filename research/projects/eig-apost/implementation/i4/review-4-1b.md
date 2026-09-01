# I4.1b quadratic FEM design review

Status: **`SKEPTIC DESIGN REVIEW COMPLETE / REVISE / IMPLEMENTATION AND RUN NOT AUTHORIZED`**.

## Material Passport

- Origin Skill: `academic-research-suite / experiment-agent`
- Origin Mode: `validate / independent design review`
- Origin Date: `2026-09-01`
- Verification Status: `ANALYZED / DESIGN BLOCKERS FOUND`
- Audited Artifact: [[research/projects/eig-apost/implementation/i4/design-4-1b|design-4-1b]]
- Governing Method: [[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]]
- Prior Evidence Boundary: [[research/projects/eig-apost/implementation/i4/review-4-1a|review-4-1a]]

## A. Audit frame

| Item | Review frame |
|---|---|
| Exact question | Does the frozen straight-sided conforming $P_2$ design uniquely define a numerically valid, reproducible and resource-feasible independent FEM experiment, while keeping the canonical $P_2$ selector blind to P1 history and BIE/QZ information? |
| Claimed contribution | A purely $P_2$ canonical FEM candidate, five internal observed sensitivity axes plus non-ranking current-run P1--P2 drift, and a separately gated post-run old-P1-target field audit. |
| Current stage | Design review. `test/i4/femref-a2/` does not exist; there is no implementation, output or run. |
| Intended output | Engineering/numerical empirical reference evidence, not a theorem or certified enclosure. |
| Success criterion | The local/global $P_2$ space, spectrum authority, component graph, total rank, field publication, failure semantics and hard budget must be mechanically unique before implementation. |
| Assumptions | The inherited fitted polygon meshes remain conforming and phase-compatible; $q$ is constant per fitted triangle; the maximum implemented mesh remains within the stated P1-derived size bracket. |
| Exclusions | No effectivity, estimator read, BIE/QZ selection, historical-target input to the formal run, exact-circle certification or continuous-existence claim. |

Materials examined include the repository, research and test `AGENTS.md` files; the complete I4.1 method and method review; the I4.1a design/review authority chain; the final `run-007`, `run-008`, `identity-003` and `profile-001` records; `femref-a1/README.md` and `SYMBOLS.md`; and the complete I4.1b design. This review did not modify any P1/Researcher artifact and did not run MATLAB, Octave, Python or a numerical program.

## B. Verdict

**Verdict: `REVISE`. Confidence: high for the two specification blockers; medium-high for the prospective resource assessment.**

The six-node $P_2$ element, degree-five quadrature, nested P1 embedding, quasiperiodic vertex/midpoint space, refinement axes, information isolation, empirical claim boundary and create-once lifecycle are scientifically coherent. The stated 124/141-call schedule and the 2,120 s/2.65 GiB planning estimate do not presently demonstrate an unavoidable budget overrun.

Two unresolved specification gaps nevertheless make the canonical numerical deliverable non-unique before any code exists:

1. the cross-configuration component graph and unmatched/dummy assignment semantics are not frozen; and
2. the exact generalized eigensolver/subspace contract and the authority relation between the 48- and conditional 60-root anchor spectra are not frozen.

Either gap can change the set of components, their rank keys, the canonical winner, stored fields and resource use. They are therefore publication/numerical blockers rather than optional robustness details. No Engineer implementation is authorized until a bounded Researcher revision closes both and the same Skeptic re-reviews it.

## C. Strongest challenge

The strongest counterexample is a branch crossing across $H_0,H_1,H_2$ or $G_0,G_1,G_2$. Suppose an $H_1$ object has nearly equal principal overlap with two objects on the next level. A graph containing only consecutive refinement edges, a graph also containing direct coarse-to-fine edges, and a graph whose assignment permits an unmatched dummy at low overlap can respectively keep, merge or split the same objects into different connected components. Because the rank explicitly rewards represented axes, linked configurations and linked twists, these three currently legal implementation choices can select different canonical $P_2$ winners without reading any forbidden BIE/P1 information. The design must therefore make the graph and assignment total order part of the scientific specification, not leave them to Engineer judgment.

## D. Classified findings

### 1. `BLOCKER`: the exact configuration graph and assignment completion are unspecified

- **Location:** design Sections 6 and 8, especially the phrases “every adjacent pair”, “maximum-total-overlap one-to-one assignment” and “each connected component”.
- **Evidence:** the design lists configurations but does not enumerate the allowed directed cross-configuration edges, source/target orientation, common-twist correspondence, whether direct nonconsecutive edges exist, or the dummy/birth/death tuple and total-cost aggregation used when inventory sizes differ. Tie terms are listed only for real pairs.
- **Failure mechanism:** different legal edge sets or unmatched-object costs change connected components, persistence counts, missing-resolution counts, candidate IDs and the first lexicographic component. That makes the canonical science and publication non-reproducible.
- **Smallest repair:** freeze one exact graph table and prohibit unlisted edges. At minimum it must settle the $H_0\to H_1\to H_2(=G_1)$, $G_0\to G_1\to G_2(=A)$, $N4\to A$, loose-to-tight and within-configuration twist edges; specify their direction and common twist indices; define the complete dummy-augmented assignment objective, summed lexicographic tuple, real/dummy pair semantics, object-ID allocation order and component-ID order. Current-run P1 companion edges must remain outside the canonical graph.
- **Decisive next check:** after the bounded text revision, a two-object crossing/dummy fixture must have one mechanically determined assignment and component set under the stated graph.

### 2. `BLOCKER`: the spectrum solver and 48-to-60 authority are not mechanically frozen

- **Location:** design Sections 4.2, 5.2 and 12.
- **Evidence:** root counts and tolerances are specified, and the resource discussion assumes a 100-vector workspace, but the design does not freeze the `eigs` target (`smallestabs` or otherwise), `maxit`, exact Arnoldi subspace dimension for 40/48/60 roots, deterministic start vector on vertex-plus-midpoint masters, or symmetry/complex options. If the conditional 60-root rung is entered, the design also does not require its first 48 ordered roots/clusters to reproduce the already stored 48-root spectrum, nor state whether the 60-root result replaces or augments the 48-root anchor authority.
- **Failure mechanism:** different admissible eigensolver modes/subspaces can change convergence flags, returned multiplicities, $W_3$ coverage and fields. An inconsistent 60-root recomputation could silently replace lower roots and alter the canonical inventory solely because the coverage rung was triggered. The missing subspace size also prevents an exact pre-run memory audit.
- **Smallest repair:** freeze the exact generalized `eigs` call, `maxit`, 40/48/60 subspace dimensions and deterministic vertex/midpoint-master start vector. Freeze a cluster-preserving first-48 agreement tolerance for every 60-root anchor solve and its failure status, and state exactly which spectrum is authoritative for inventory/publication after agreement.
- **Decisive next check:** static source review must recover one call signature for each root count and one unambiguous 48/60 merge-or-replacement path, with no result-dependent shift or retry.

### 3. `IMPORTANT CAVEAT`: global phase/embedding and P2 parity checks need exact implementation locators

- **Location:** design Sections 3.3, 4.1 and 7.
- **Evidence:** local $E_T$ is exact, and vertex/midpoint seam plus corner-product rules are strong. However, the “one coarse and one anchor mesh/twist” global P1-embedding checks do not name the phases or the global embedding construction. Endpoint P2 reflection parity is used in the canonical rank but its midpoint reflection map/compressed-mass formula is only inherited implicitly from I4.1a.
- **Consequence:** choosing only zero $x$ phase would weaken the intended phase validation; an inconsistent parity implementation could change a tie in the total rank. The existing seam, corner and local checks make this a bounded implementation condition rather than a demonstrated invalid discretization.
- **Required condition:** the Researcher revision or later theory-to-code map must identify at least one exact nontrivial bulk phase and one exact nontrivial defect twist for the reduced P1-embedding identity, define the global embedding through both prolongations, and state the P2 edge-midpoint reflection/permutation used for endpoint parity. Parity failure remains a caveat, not a spectrum stop.

### 4. `IMPORTANT CAVEAT`: resource feasibility is plausible but must be closed with actual static mesh/storage data

- **Location:** design Section 12.
- **Evidence:** the time estimate has a reproducible planning calculation, but the new nine unique P2 meshes do not yet exist, so their actual $V,T,B,n_{2,\mathrm{red}}$ and sparse-factor/storage graph are unavailable. The 3 GiB margin over 2.65 GiB is only 0.35 GiB.
- **Consequence:** this uncertainty does not itself prove an overrun and is not a design blocker. It becomes a pre-run blocker only if the implemented mesh/call graph predicts at least 2700 s or 3,221,225,472 B without reducing the frozen science.
- **Required condition:** before execution, the theory/spec-to-code review must publish a static table for every planned mesh with $V,T,B,E$, full/reduced P2 DOFs, `nnz` for full/reduced stiffness and mass, exact 40/48/60 eigensolver subspace, largest simultaneously resident fields/samples, sparse-factor allowance and publication-copy allowance. Streaming and clearing points must be visible in the call graph.

### 5. `MINOR CAVEAT`: diagnostic and resolution labels remain empirical

Bulk gap, edge buffer, localization, parity, continuation strength, incomplete axes and non-contracting refinement correctly remain caveats. The six-component $\Delta_{P_2}^{\mathrm{obs}}$ includes the separately non-ranking current-run P1--P2 drift, but it is not an error bound or confidence interval. This limitation is already stated and does not require a new scientific gate.

## E. Detailed mathematical and implementation audit

### E.1 Local $P_2$ element and quadrature

The vertex/midpoint basis is the standard complete quadratic Lagrange basis on an affine triangle. A sorted global edge key gives one midpoint DOF shared by all incident elements. With no curved mapping, $\nabla\phi_i\cdot\nabla\phi_j$ has degree at most 2 and $q_T\phi_i\phi_j$ degree at most 4. The stated positive seven-point rule has weights summing to one up to approximately $10^{-15}$ and degree five, so it is sufficient for both forms. The barycentric monomial identity

$$
\int_T\ell_1^a\ell_2^b\ell_3^c
=2|T|\frac{a!b!c!}{(a+b+c+2)!}
$$

is correct. Nodal identity, partition of unity, gradient sum, monomial checks and the local P1 embedding collectively test the intended element rather than a surrogate.

### E.2 Global P2 space and same-geometry Ritz semantics

Pairing both boundary vertices and the associated boundary-edge midpoint is sufficient to match a quadratic trace. The unique corner factor and order-independent $x/y$ mapping correctly address the only doubly identified P2 trace node, the corner vertex. Requiring one unit-modulus prolongation entry per full DOF and support in every reduced column is the right global-space invariant.

For the same straight polygonal mesh and phase, the reduced P1 space is nested in the reduced P2 space when the global embedding commutes with the prolongations. Exact Rayleigh--Ritz monotonicity is therefore $\lambda_j^{(2)}\le\lambda_j^{(1)}$ for the ordered discrete eigenvalues. The stated residual/roundoff allowance is a one-sided implementation diagnostic, not a mode matcher; the design correctly forbids using index-$j$ Ritz agreement to identify the old P1 target.

### E.3 Refinement axes, field evaluation and information isolation

The design contains three independent $h$ levels, three segmentation levels, a same-geometry $N=4\to5$ comparison, nested $\Theta_5/\Theta_9/\Theta_{17}$ twist evidence and tight/loose algebraic evidence. The $h$ and $g$ axes are not conflated. Quadratic common-grid evaluation uses all six basis functions, while companion/old P1 fields retain linear evaluation; the shared positive physical weights make cross-order Gram and principal-overlap calculations meaningful.

The canonical rank uses only P2 objects and the five P2-internal changes. Current-run companion P1 assignment occurs after the canonical order is frozen, and the historical target remains absent until a separately reviewed post-run audit. That audit identifies by candidate/realization and fields, never by frequency or BIE proximity, and cannot replace the canonical winner. This information-isolation sequence survives scrutiny.

### E.4 Artifacts, failure truth and lifecycle

The `scientific-result.mat`/`fields.mat` split, current-run work caches, append-only log, controller resource record and summary-last row are sufficient to review spectra, complete subspaces, assignments, rank and partial scientific states. Complete solve caches precede later failures; a scientific negative preserves reached compact evidence, while operational/resource interruption cannot fabricate READY. A single legal slice failure does not erase other valid fields. The create-once `run-001/execution-001` lifecycle and same-attempt operational recovery are consistent with `test/AGENTS.md`.

The successful terminal properly requires only one valid field-bearing $W_3$ component and a deterministic canonical rank. Gap, localization, parity, coverage and refinement behavior remain interpretation caveats rather than hidden stops. Element/phase/Ritz invalidity, no surviving valid object, hard resources and publication failure remain legitimate blockers.

## F. Resource recomputation

### F.1 DOF and sparse assembly scale

For a conforming triangle mesh,

$$
E=\frac{3T+B}{2},\qquad
n_{2,\mathrm{full}}=V+E,qquad
n_{2,\mathrm{red}}=n_{1,\mathrm{red}}+\frac{3T}{2},
$$

because periodic boundary midpoint pairing removes $B/2$ edge DOFs. The three accepted same-mesh checks recompute as:

| P1 evidence mesh | $T$ | $n_{1,\mathrm{red}}$ | recomputed $n_{2,\mathrm{red}}$ | at most $36T$ local entries per P2 form |
|---|---:|---:|---:|---:|
| $N5,s12,g24$ | 4,448 | 2,224 | 8,896 | 160,128 |
| $N5,s18,g36$ | 9,128 | 4,564 | 18,256 | 328,608 |
| $N5,s24,g48$ | 14,992 | 7,496 | 29,984 | 539,712 |

Thus the arithmetic in design Section 5.1 is correct. The proposed $s=18,g=48$ anchor is plausibly below the $s=24,g=48$ planning upper, but only the implemented mesh can establish its exact count. The mandatory pre-run table must cover the three bulk and six defect P2 meshes; the companion P1 uses the anchor geometry and does not add another mesh.

### F.2 Solve/root work

The schedule recomputes exactly:

$$
67\times40+5\times48=2920\quad\text{bulk roots},
$$

$$
47\times48=2256\quad\text{base P2 defect roots},
\qquad 5\times48=240\quad\text{P1 companion roots}.
$$

Hence the base is 124 calls and 5,416 requested roots. The single conditional rung adds
$17\times60=1020$ roots, giving 141 calls and 6,436 requested roots. These counts are correct, subject to Finding 2's missing eigensolver and 48/60 authority rules.

### F.3 Time and memory

The stated time estimate is reproducible:

$$
140.273679\times8\times\frac{6436}{5176}\times1.3
=1813.97\ \mathrm{s},
$$

which rounds conservatively to 1,820 s. Adding the prospective 300 s audit charge gives 2,120 s and leaves 580 s below the 2,700 s hard upper. This is planning evidence, not a runtime gate.

Using the conservative $n=29{,}984$ planning dimension, 60 roots and 17 anchor twists gives about 489,338,880 B for all complex full anchor vectors. The corresponding $10465\times60\times17$ complex common-grid samples require about 170,788,800 B. A 100-vector complex Arnoldi basis would require about 47,974,400 B; one 60-vector return about 28,784,640 B; five upper-bracket companion-P1 returns about 28,784,640 B; and two complex P2 forms at the $36T$ entry upper require about 25,906,176 B of value/index payload. This explicit-array subtotal is approximately 0.74 GiB before MATLAB baseline, sparse factors, temporary QR/normalization arrays, HDF5 publication and copy-on-write duplication.

The I4.1a peak of 1,353,826,304 B and the explicit-array subtotal make 2.65 GiB plausible, not proven. Because only about 0.35 GiB remains to the 3 GiB upper, the implementation-stage static storage/factor model in Finding 4 is mandatory. There is no current evidence of an inevitable overrun, so the resource question is a pre-run condition rather than a present blocker.

The design correctly retains only the inclusive hard predicates

$$
T\ge2700\ \mathrm{s},\qquad R_{\mathrm{RSS}}\ge3221225472\ \mathrm{B},
$$

with no lower resource stop, forecast gate, stall rule, reserve or grace period.

## G. What survived scrutiny

1. The continuous model, $q\in\{1,17\}$, $\beta=0.5$, $\lambda=k^2$ and fitted straight-interface variational crime are unchanged.
2. The six-node $P_2$ basis, shared global midpoint topology, degree-five quadrature and P1 embedding are mathematically correct.
3. Vertex, midpoint, seam and corner phase requirements define the intended quasiperiodic conforming space, subject only to the exact validation locator in Finding 3.
4. The three-level $h$ axis and independent $g,N,\vartheta,$ algebraic and P1--P2 axes are scientifically visible.
5. Quadratic field evaluation, weighted subspace overlap, cluster preservation and diagnostic downgrade semantics are appropriate.
6. Canonical P2 ranking is isolated from companion P1, historical target, BIE/QZ and estimator information.
7. The post-run P1-target audit can produce field-identity evidence and a candidate-specific P1--P2 drift without overwriting the canonical P2 winner.
8. Minimal artifacts, partial-state truthfulness, create-once lifecycle and empirical/non-certified claim boundaries are adequate.
9. The prospective wall/RSS evidence is tight but not presently contradictory to the authorized hard limits.

## H. Minimal resolution and authorization boundary

The smallest next action is a bounded Researcher revision of `design-4-1b.md` that closes Findings 1 and 2 and records the exact validation locators in Finding 3. It must not change the continuous problem, P2 basis, mesh axes, 124/141 solve schedule, empirical formulas, information isolation, artifacts, hard resource uppers or claim boundary merely to resolve those deterministic omissions.

After that revision, the same Skeptic must perform a focused design re-review. Only a verdict with no unresolved blocker may authorize one Engineer to create `test/i4/femref-a2/` with the four minimal files listed in design Section 13. Even after such authorization, execution remains blocked until Researcher theory-to-code and same-Skeptic exact spec-to-code/resource reviews pass, including Finding 4's actual mesh/storage table.

Current authorization is therefore:

**`NO ENGINEER IMPLEMENTATION / NO femref-a2 DIRECTORY / NO CODE / NO OUTPUT / NO MATLAB OR RUNNER EXECUTION`.**

## I. Open-problem handoff

This table is for the parent agent to merge into the existing project ledger; the read-only scientific ledger is not modified here.

| Stage | Category | Item | Blocking scope | Cheapest next check | Suggested status |
|---|---|---|---|---|---|
| I4.1b design | `BLOCKER` | Exact P2 configuration graph and dummy assignment total order are absent | Blocks deterministic component/rank/publication | Bounded graph/assignment table plus same-Skeptic re-review | `OPEN` |
| I4.1b design | `BLOCKER` | Exact eigensolver/subspace and 48/60 spectrum authority are absent | Blocks reproducible spectrum and resource contract | Freeze call signatures/agreement rule plus same-Skeptic re-review | `OPEN` |
| I4.1b implementation | `IMPORTANT CAVEAT` | Actual nine-mesh counts, factor/workspace and publication peak are unavailable | Does not block design repair; may block formal launch | Static per-mesh/storage model after implementation | `SCHEDULED` |
| I4.1b interpretation | `MINOR CAVEAT` | All resolution and late target-identity quantities remain empirical | Does not block implementation or run | Preserve labels in artifact and post-run review | `OPEN / NON-BLOCKING` |

## J. Focused delta re-review of design Section 15

Review scope: only the two blockers in Findings 1--2 and the exact-locator/resource conditions in Findings 3--4 were reopened. The continuous problem, quadratic element, scientific schedule, empirical claim boundary and prior non-blocking caveats were not re-litigated. This append-only verdict supersedes the earlier `REVISE` verdict for prospective I4.1b work; the historical findings above remain intact.

### J.1 Delta verdict

**Verdict: `PASS`. Confidence: high on closure of both design blockers; medium-high on the prospective resource condition.**

There is no unresolved design blocker. Section 15 makes the canonical component construction and spectrum authority mechanically unique without introducing P1, historical FEM, BIE/QZ or estimator information. The actual nine-mesh/storage calculation remains mandatory after implementation and before any launch, but the present evidence does not demonstrate an inevitable 2700 s or 3,221,225,472 B overrun.

### J.2 Blocker closure audit

1. **Finding 1 closed.** Section 15.1 fixes every allowed directed edge, twist correspondence and prohibited direct/reverse/diagonal edge. It also makes $\Theta_5$ and $\Theta_9$ literal views of $\Theta_{17}$, so views cannot duplicate objects, edges or persistence counts. Current-run P1 companion matching occurs only after the pure-P2 graph, rank and winner are frozen and remains in a separate non-ranking graph.
2. **The dummy construction is complete and implementable.** For $n$ sources and $m$ targets, the $(n+m)$-square construction always admits a perfect assignment: unmatched sources use their own deaths, unmatched targets use their own births, and birth rows for matched targets use the remaining death columns. Summing the seven-component costs and then minimizing lexicographically defines maximum total overlap before unmatched count and frequency; the fixed row/column order and final column-vector tie-break make binary64 ties unique. Only real pairs create component edges. The crossing, $2\to1$, $1\to2$ and exact-tie fixtures are sufficient static counterexamples for the previously ambiguous cases, and component IDs are fixed by minimum immutable `object_id` rather than traversal or frequency.
3. **Finding 2 closed.** Section 15.3 freezes the literal generalized `eigs` call, `smallestabs` target, `p=80/96/100`, `maxit=800`, complex-Hermitian flags, per-family tolerances and one deterministic nonzero `v0` ordered by master ID. Result-dependent shifts, random starts, fallback, changed subspaces and retries are excluded.
4. **Conditional-spectrum authority is unambiguous.** A 60-root anchor slice must reproduce the first 48 frequencies, frozen cluster boundaries/multiplicities and exact-mass field subspaces. Agreement makes 60 the sole active authority; disagreement preserves 48 as sole authority, rejects 60 from candidates and records partial coverage without deleting valid fields or stopping ranking. The explicit per-slice authority table prevents mixed or duplicate 48/60 objects.

### J.3 Locator and resource conditions

- **Finding 3 closed.** Section 15.5 defines the global vertex-to-midpoint embedding, the prolongation commutator and reduced stiffness/mass identities at one named nontrivial bulk phase and named coarse/anchor defect twists. It also defines the vertex/edge-midpoint reflection permutation, involution/mass checks and the compressed cluster-parity operator. Parity failure remains a caveat rather than a spectrum stop.
- **Finding 4 remains an `IMPORTANT CAVEAT` and mandatory pre-run condition, not a current blocker.** Section 15.6 requires actual counts for exactly the three bulk and six defect meshes, including $V,T,B,E$, full/reduced DOFs, operator `nnz`, applicable `nev/p`, simultaneous-live bytes, factor/workspace allowances, field/sample retention, serialization/publication copies and explicit clearing points. The full 124/141-call graph must be recomputed. A prediction at or above either hard upper must fail closed as `RESOURCE_BUDGET_UNAVAILABLE`; no lower stop, reserve, forecast, stall or grace rule is permitted.

### J.4 Strongest remaining challenge and what survived

The strongest remaining counterexample is implementation drift: an assignment routine that scalarizes the tuple approximately, or a conditional 60-root path that merges rather than replaces the 48-root inventory, could still change components and the winner. That is now a spec-to-code question, not a design ambiguity; the mandatory fixtures, call signatures and authority table provide decisive static checks. The directed graph, singleton/birth/death behavior, pure-P2 information isolation, phase-compatible P1 embedding, endpoint P2 parity and empirical/non-certified publication boundary otherwise survive this focused review.

### J.5 Authorization boundary

The same Engineer is authorized only to create `test/i4/femref-a2/` and implement the four minimal files frozen in design Section 13:

- `run_i4_1b.m`;
- `run_formal.pl`;
- `README.md`;
- `SYMBOLS.md`.

This authorization does not permit MATLAB, Octave, Python or runner execution; creation of output or a `run-001` namespace; implementation of the later historical-target audit; modification of `femref-a1`, P1 artifacts, package/main code or I1--I3; or any estimator/effectivity step. After implementation, the Researcher must complete theory-to-code mapping and the same Skeptic must complete exact spec-to-code/resource review, including the nine-mesh simultaneous-live table, before any formal command can be authorized.

## K. Sections 16--17 preflight spec-to-code/resource review

### K.1 Audit frame and verdict

Target: the four bounded source corrections, exact zero-eigensolve preflight dispatch, five-leaf publication and prospective shared-budget evidence in design Sections 16--17. Success requires a reachable representation-only path whose measured residency covers the maximum formal simultaneous-live classes and whose controller cannot publish a false under-budget terminal. No source, design or output was modified or executed during this review.

**Verdict: `REVISE`. Confidence: high.** The four Section 16.2 implementation discrepancies are closed, the preflight is isolated from every scientific eigensolver/object path, and its identity/artifact allowlists are exact. Two bounded resource/publication defects nevertheless prevent this preflight from supporting its declared launch decision. Neither requires a scientific-method change or a new artifact type.

### K.2 Strongest challenge

The formal top-level retains `candidate_inventory` while `LOCAL_companion_inventory` performs the five P1 eigensolves (`run_i4_1b.m:99-114,2210-2280`). Thus accumulated P2 subspaces/common-grid samples coexist with a current P1 reduced pair/factor, Arnoldi workspace, returned vectors and prior companion objects. The preflight instead clears its factor/Arnoldi/return stage before allocating retained field/sample/companion capacity (`run_i4_1b.m:315-342,344-380`). A passing peak from these disjoint stages therefore need not upper-bound the actual formal peak, precisely where the static 2.973 GB model is already close to the 3 GiB hard upper.

### K.3 Classified findings

1. **`BLOCKER` -- the residency schedule omits a reachable formal simultaneous-live peak.**
   - **Evidence:** design Section 15.6 requires the maximum sum of simultaneously live objects, not a sum over disjoint stages. Formal candidate objects remain live across the companion solves; there is no intervening `clear` or serialization boundary. Preflight `solver-capacity` contains the anchor factor plus $p=100$/60-vector buffers but no retained P2 fields/samples, while `retained-capacity` contains fields/samples/companions but no current factor/Arnoldi/return.
   - **Consequence:** `R_pf` can understate the formal resource requirement and could incorrectly support launch below 3,221,225,472 B. This invalidates the primary resource purpose of the preflight, although it does not question the P2 mathematics.
   - **Smallest repair/test:** within the existing preflight and five-leaf schema, add one committed, representation-only stage matching the actual companion-solve lifetime: pessimistic retained P2 field/sample capacity plus prior/current P1-companion capacity, largest relevant reduced pair/factor, $p=96$ Arnoldi workspace and one 48-vector return held simultaneously. It must still call no `eig`, `eigs` or `svd`. The external controller's aggregate RSS for this stage is the decisive check.

2. **`BLOCKER` -- the whole-command wall terminal can become stale during final publication.**
   - **Evidence:** `run_preflight.pl:157-160` performs its last deadline check and freezes `final_terminal/final_elapsed`; lines 161--165 then write `residency.tsv`, `resource.tsv` and summary-last. The armed alarm handler only sets `wall_reached` after killing a child (`run_preflight.pl:23-28`). If the absolute deadline is crossed during these writes after MATLAB has exited, the controller can continue, publish `NATURAL_EXIT` with the earlier elapsed value and exit zero.
   - **Consequence:** the exact command can exceed the inclusive 2700 s hard limit while claiming success, and the later frozen $T_{pf}$ can undercharge the non-resetting formal deadline. This is a hard-resource and publication-integrity failure.
   - **Smallest repair/test:** keep the same single absolute deadline armed through summary-last and make any post-freeze alarm fail closed without publishing a false natural terminal. Record elapsed only after all pre-summary work that can be included, and ensure a wall crossing during publication leaves an honest nonzero/partial operational record rather than `NATURAL_EXIT`. Do not introduce a reserve, lower threshold, grace period or another resource upper.

3. **`IMPORTANT CAVEAT` -- formal execution remains intentionally unbudgeted until post-preflight review.** The current `run_formal.pl` still owns the full 2700 s deadline and does not contain reviewed $T_{pf},R_{pf}$ scalars. This is correct at the present gate: after a successful preflight, those values must be reviewed and mechanically frozen into the remaining-time/cumulative-peak contract before formal execution can be considered.

4. **`MINOR CAVEAT` -- stage-local individual-process RSS is descriptive only.** `matlab_peak_rss_bytes` is the largest individual target process, not necessarily the MATLAB root. The deduplicated aggregate tree RSS is correctly the sole memory authority, so the label does not block preflight once the two resource defects above are repaired.

### K.4 Implementation audit: what survived

- All four Section 16.2 corrections survive static inspection: object allocation order is independent of rank priority; midpoint reflection compares columnized vectors; formal resource/summary use one frozen terminal; and `MESH_INVALID` is mesh-local while generic source/output faults still rethrow.
- The exact MATLAB allowlist admits only `run-001/execution-001` and `resource-preflight-001/execution-001`. The latter returns from `LOCAL_resource_preflight` before work caches or formal inventory creation.
- The reachable preflight graph constructs exactly the three bulk and six defect meshes, scans their frozen phase sets, records $V,T,B,E$, P1/P2 full/reduced DOFs and full/reduced `nnz`, and performs representation checks and sparse Cholesky only. Every source call to `eig`, `eigs` or `svd`, as well as W3 inventory, tracking, ranking, fields and reference scalars, is downstream of the formal-only path.
- The exact create-once namespace is absent. The only reachable leaves are `mesh-operators.tsv`, `residency.tsv`, `preflight.log`, `resource.tsv` and summary-last `preflight-summary.tsv`; no MAT, spectrum, field, candidate or result leaf is reachable.
- `run_preflight.pl` is no-argument and fixes the exact MATLAB R2023b call. Aggregate RSS is deduplicated over the root/recursive-descendant/dedicated-PGID union; the only numerical resource predicates are elapsed $\ge2700$ s and aggregate RSS $\ge3221225472$ B. Process/RSS authority loss is correctly operational fail-closed, not a lower resource gate.
- Documentation states that formal science remains blocked pending post-preflight resource review and a non-resetting shared-budget patch. No historical output, BIE/QZ datum, estimator, Markdown or Git input enters active MATLAB.

### K.5 Minimal resolution and authorization boundary

The same Engineer may make only the two bounded preflight/controller repairs above in the existing `femref-a2` sources and mechanically synchronize README/SYMBOLS. The same Researcher must then update the theory-to-code delta, followed by this same Skeptic's focused static re-review.

Current authorization is:

**`NO PREFLIGHT EXECUTION / NO FORMAL EXECUTION / NO OUTPUT NAMESPACE / NO EIGENSOLVE`.**

In particular, `/usr/bin/perl ./run_preflight.pl` is **not authorized** by this verdict. No change to the continuous model, schedules, scientific graph/rank, five artifact names, exact identity, 2700 s/3 GiB hard uppers or later shared-budget rule is warranted.

## L. Focused static re-review of Sections 18--19

### L.1 Audit frame and verdict

This delta re-review reopened only the two Section K blockers: the missing simultaneous companion-solve residency and the stale wall terminal during publication. It also rechecked the preflight-only call graph, exact identity, five-leaf lifecycle, hard resource predicates and the still-blocked shared-budget formal path. No program or controller was executed and no output namespace was created.

**Verdict: `PASS`. Confidence: high for static closure; measured resource feasibility remains for post-preflight review.** No unresolved numerical, implementation, resource-enforcement or publication blocker prevents the zero-eigensolve preflight.

### L.2 Blocker closure

1. **Section K Finding 1 is closed.** `field_capacity` and `sample_capacity` are allocated before `companion-simultaneous-capacity`. In one uninterrupted MATLAB scope, the stage then holds the anchor full P1 forms, reduced P1 pair/prolongation/Cholesky factor, four prior full P1 returns, the current full and reduced 48-vector returns, a $p=96$ Arnoldi buffer, companion metadata and the retained P2 fields/samples (`run_i4_1b.m:344-393`). The first relevant `clear` occurs only after the stage's second marker and one-second observation pause (`run_i4_1b.m:395-396`). Therefore the former disjoint-stage underestimate is no longer reachable.
2. **The publication lifetime is separately preserved.** After releasing solver-only objects, the source retains P2 fields/samples and all five P1 full returns while adding the candidate/companion payload and 512 MiB publication-copy capacity (`run_i4_1b.m:397-423`). The marker and pause precede the final clear. This is the larger post-solve publication set; it is not substituted for the companion-solve set.
3. **Section K Finding 2 is closed.** Both controllers open `resource.tsv` as a create-once event ledger, append a `PUBLICATION_PENDING` target-exit row, prepare and synchronize all pre-summary evidence under the original alarm, take fresh inclusive deadline checks, append/synchronize the whole-command terminal, then atomically rename the summary last. Before the rename, the alarm appends a superseding wall event when possible and exits nonzero; explicit wall/publication failures also prohibit summary commit. After the rename, summary presence is the completion latch. A previously frozen `NATURAL_EXIT` can no longer survive a pre-commit deadline event as authoritative success.

### L.3 Rechecked implementation boundaries

- The exact allowlist remains `run-001/execution-001` and `resource-preflight-001/execution-001`; the no-argument preflight runner launches only the latter with MATLAB R2023b. Both create-once namespaces remain absent.
- The preflight branch returns before formal work-directory creation. Its reachable graph contains mesh construction, P1/P2 assembly and phase reduction, representation checks, Cholesky factors, committed capacity buffers and preflight writers, but no call to `eig`, `eigs`, `svd`, spectrum/W3 construction, tracking, ranking, fields, candidate or reference-scalar publication.
- It still constructs exactly the three bulk and six defect meshes and records actual $V,T,B,E$, P1/P2 full/reduced DOFs, full-form `nnz`, maximum reduced-form `nnz` over each frozen phase set and applicable $(\mathrm{nev},p)$.
- The five authoritative preflight leaves remain `mesh-operators.tsv`, `preflight.log`, `residency.tsv`, append-only `resource.tsv` and atomically committed summary-last `preflight-summary.tsv`. A `.partial` summary on failure is explicitly non-authoritative debris, not a sixth result artifact.
- The only numerical hard stops are inclusive elapsed $\ge2700$ s and deduplicated aggregate MATLAB-process-tree RSS $\ge3221225472$ B. The 0.25 s samples and one-second stage holds are observations, not lower gates; process-table or dedicated-PGID authority loss remains an operational fail-closed state.
- The Section 18 patch changes no continuous constant, mesh, solve count, root/subspace size, scientific graph/rank, uncertainty rule, P1 isolation or claim boundary.

### L.4 Caveats and mandatory post-preflight gate

1. **`IMPORTANT CAVEAT`: resource feasibility is still empirical.** A natural preflight is not by itself formal authorization. Post-preflight review must verify all nine mesh rows, both simultaneous residency rows, nonzero observation coverage, the authoritative aggregate peak, ordered terminal-event ledger, absence of unauthorized leaves/partials and consistency of summary-last. A hard-resource terminal is a valid negative resource result, not grounds to reduce the frozen science.
2. **`IMPORTANT CAVEAT`: the shared budget is prospective.** Formal `run-001/execution-001` remains blocked. Only after post-preflight review may the measured $T_{\mathrm{pf}}$ and $R_{\mathrm{pf}}$ be mechanically frozen into `run_formal.pl` as remaining deadline $2700-T_{\mathrm{pf}}$ and cumulative peak $\max(R_{\mathrm{pf}},R_{\mathrm{formal}})$, followed by another Researcher/Skeptic static review.
3. **`MINOR CAVEAT`: individual-process RSS is descriptive.** The largest individual target-process value is not the memory authority; only the deduplicated aggregate tree peak may support the resource decision.

### L.5 Authorization boundary

Exactly one create-once preflight command is now authorized:

```text
cwd: /Users/whc/Documents/Work/epost/test/i4/femref-a2
/usr/bin/perl ./run_preflight.pl
```

This authorization is only for `resource-preflight-001/execution-001`. It does **not** authorize `/usr/bin/perl ./run_formal.pl`, `run-001/execution-001`, any eigensolve, historical-target audit, BIE/QZ or estimator read, effectivity comparison, retry, alternate execution ID or additional artifact. Post-preflight artifact/resource review is mandatory before any shared-budget source patch or formal-run decision.

## M. Post-preflight review of `resource-preflight-001/execution-001`

### M.1 Audit frame and verdict

The consumed create-once execution was reviewed from its four immutable leaves: `preflight.log`, `residency.tsv`, `resource.tsv` and summary-last `preflight-summary.tsv`, together with the exact source failure locator. No artifact, source or design was modified and no program was run.

**Post-preflight verdict: `REVISE / BOUNDED OPERATIONAL IMPLEMENTATION FAILURE`. Confidence: high.** The execution is not a FEM-method failure and not a resource failure. It stopped during construction of the third representation, before the nine-mesh table, capacity stages or any eigensolve. The evidence supports a bounded P2 midpoint-reflection mapping repair within the same method, followed by the already frozen operational lifecycle for `execution-002`.

### M.2 Artifact and resource consistency

- `resource.tsv` is a well-formed two-event ledger: event 1 records `TARGET_EXIT/PUBLICATION_PENDING` at 18.226193 s with MATLAB exit code 1 and signal 0; event 2 records `WHOLE_COMMAND_TERMINAL/MATLAB_EXIT_NONZERO` at 18.226698 s.
- `preflight-summary.tsv` matches the authoritative last event exactly: run/execution IDs, `MATLAB_EXIT_NONZERO`, 18.226698 s and aggregate peak RSS 1,084,440,576 B. Its empty `preflight_terminal` honestly reflects the absence of `PREFLIGHT_COMPLETE`.
- `residency.tsv` is an honest reached-prefix ledger. It records startup, completed `bulk-s12-g36`, completed `bulk-s18-g36`, and the started `bulk-s18-g48` stage. The aggregate stage peaks are respectively 731,217,920 B, 989,741,056 B, 1,084,440,576 B and 1,053,917,184 B; the global peak is therefore traceable to the completed `bulk-s18-g36` representation.
- The root contains no unauthorized leaf and no summary `.partial`. `mesh-operators.tsv` is absent because source publication occurs only after all nine mesh rows exist. The incomplete four-leaf tree is valid partial evidence under the five-name allowlist; it is not a completed preflight.
- Both resource uppers were respected. The execution used 18.226698 s, leaving 2,681.773302 s of the user-required non-resetting 2,700 s budget, and its 1,084,440,576 B peak is below 3,221,225,472 B. This terminal must not be relabeled as a wall or memory failure.

### M.3 Failure classification and strongest challenge

`preflight.log` completes the first two bulk representations and then reports:

```text
bulk-s18-g48 has an invalid P2 reflection map.
run_i4_1b>LOCAL_build_mesh (line 896)
```

The source reaches this check only after the vertex reflection map, reflected constraints, reflection-closed triangles, positive/nonduplicate triangles, fitted material/interface checks, P1/P2 assembly and matrix finiteness/SPD checks (`run_i4_1b.m:820-890`). It then reconstructs the P2 vertex-plus-midpoint reflection by applying a coordinate-quantized lookup to `p2_points` (`run_i4_1b.m:891-898`) before the separate endpoint-induced edge-map validator (`run_i4_1b.m:1295-1306`).

For a reflection-closed triangle graph, every active edge has a reflected active edge and its P2 midpoint is determined combinatorially by the reflected endpoints. A tolerance-bucket lookup can nevertheless fail when two mathematically paired midpoint coordinates straddle adjacent rounding buckets. The strongest remaining counterexample is that the active edge graph itself is not reflection closed; the cheapest decisive repair check is therefore to construct the midpoint permutation from the already verified vertex permutation and sorted reflected-edge lookup, require every edge to have exactly one partner, require the resulting P2 permutation to be bijective/involutive, and independently retain the coordinate-defect check. This resolves either case without changing the mesh, basis, weak form or scientific schedule.

The failure is consequently a **`BLOCKER` for another preflight execution**, but only a bounded representation-index implementation blocker. No spectral, branch, candidate, uncertainty or resource-method claim was reached. Static reachability plus the absence of MAT/spectrum/field leaves confirms zero calls to the formal `eig`/`eigs`/`svd` paths.

### M.4 Partial-result and claim boundary

This execution establishes only that the first two bulk P1/P2 representations passed their reached construction/phase checks and supplies partial RSS evidence through the third-mesh start. It does **not** establish:

- the `bulk-s18-g48` representation or any of the six defect meshes;
- the nine-row mesh/`nnz` table;
- either simultaneous companion/publication capacity peak;
- whole-preflight resource feasibility;
- any eigenvalue, eigenfield, branch, candidate, empirical reference or effectivity conclusion.

The current formal `run-001/execution-001` namespace remains absent and unauthorized.

### M.5 Budget and retry ledger

`resource-preflight-001/execution-001` is immutable and consumed. Under the user's explicit non-resetting instruction, a later reviewed `execution-002` must carry:

$$
T_{\mathrm{prior}}=18.226698\ \mathrm{s},
\qquad
T_{\mathrm{remaining}}=2700-18.226698=2681.773302\ \mathrm{s},
$$

$$
R_{\mathrm{prior}}=1084440576\ \mathrm{B},
\qquad
R_{\mathrm{cum}}=\max\{1084440576,R_{002}\}.
$$

Memory is a peak maximum, not a subtractive allowance; the same inclusive 3,221,225,472 B hard predicate remains. No lower wall/RSS stop may be introduced.

### M.6 Minimal next gate and authorization

The same Researcher is authorized to freeze only:

1. the bounded combinatorial P2 midpoint-reflection-map repair and its invariant checks;
2. exact `resource-preflight-001/execution-002` create-once identity plumbing; and
3. the source-owned prior wall/peak and remaining/cumulative budget arithmetic above.

After that bounded design update, the same Engineer may implement it only following the normal Researcher-to-Engineer gate; the same Researcher must then complete theory-to-code mapping and this same Skeptic must perform exact pre-execution review. This verdict does **not** authorize `execution-002` to run, does not authorize formal science, and does not permit changing the continuous model, P2 basis, meshes, schedule, capacity stages, five authoritative leaf names or claim boundary.

## N. Focused pre-execution re-review of Sections 20--21

### N.1 Audit frame and verdict

This re-review reopened only the Section M midpoint-reflection blocker and the exact
`execution-002` continuation contract. It inspected design Sections 20--21, the current MATLAB
reflection path, the no-argument preflight controller, mechanical README/SYMBOLS mappings and the
existing output namespaces. No program was run and no output artifact was created or modified.

**Verdict: `PASS`. Confidence: high for static closure.** No unresolved numerical,
implementation, resource-enforcement or publication blocker prevents exactly one reviewed
zero-eigensolve `execution-002` preflight.

### N.2 Blocker closure and strongest challenge

The Section M rounding-bucket failure is no longer reachable for a P2 midpoint. The mesh builder
first obtains the validated vertex involution, maps each integer endpoint pair through it, sorts the
pair and performs an exact row lookup in the sorted unique active-edge table. It requires every
edge to be found, requires the resulting edge map to be a permutation and involution, and then
forms the full P2 permutation by concatenating the vertex and shifted edge permutations
(`run_i4_1b.m:891-915`). Only after this identity is fixed does it check the reflected-coordinate
defect, the independently recomputed endpoint-induced midpoint map, and the stiffness/mass
reflection defects (`run_i4_1b.m:916-935,1321-1333`). The only remaining
`LOCAL_reflection_map` call selects vertices, not midpoints.

The strongest counterexample is now a genuinely non-reflection-closed active-edge graph. That case
cannot produce a silent or nearest-coordinate pairing: the exact edge lookup fails before the P2
permutation is used and reports a representation failure. Thus the bounded repair preserves the
mesh, six-node P2 basis, weak form and scientific schedule while making the previous failure
mechanism distinguishable from a true topology defect.

### N.3 Identity, artifact and resource audit

- MATLAB admits exactly formal `run-001/execution-001` and preflight
  `resource-preflight-001/execution-002`; the latter returns from
  `LOCAL_resource_preflight` before formal work-directory creation and every source occurrence of
  `eig`, `eigs`, `svd`, spectrum, field, branch, rank or reference construction.
- The controller fixes `resource-preflight-001/execution-002`, accepts no arguments, and rejects a
  pre-existing execution directory before launch. `execution-002` and formal `run-001` are absent.
  The consumed `execution-001` remains the same four-leaf immutable partial tree. No active source
  reads, copies, hashes or reuses it; its reviewed resource values appear only as source literals.
- The only authoritative preflight leaves remain `mesh-operators.tsv`, `preflight.log`,
  `residency.tsv`, append-only `resource.tsv` and atomically committed summary-last
  `preflight-summary.tsv`. A summary `.partial` remains non-authoritative failure debris.
- The controller freezes
  $T_{\mathrm{prior}}=18.226698\ \mathrm{s}$ and uses the single current absolute deadline
  $T_{002}=2681.773302\ \mathrm{s}$, equivalently the sole cumulative wall predicate
  $18.226698+T_{002}\ge2700\ \mathrm{s}$. It reports prior, current and cumulative wall values.
- Each process-tree sample uses
  $R_{\mathrm{cum}}=\max\{1084440576,R_{002}\}$ and stops only when that cumulative peak is at
  least $3221225472\ \mathrm{B}$. Memory is not subtracted. The 0.25 s sampling sleep is
  observational; there is no reserve, forecast, stall, grace period or lower RSS/wall gate.
- The already reviewed event-ledger/summary-last state machine remains armed through publication.
  The simultaneous companion and publication capacity stages and all nine representation rows are
  unchanged. Formal `run_formal.pl` remains outside this authorization and still requires a
  post-preflight shared-budget patch and review.

### N.4 Findings and authorization boundary

There is no unresolved `BLOCKER`.

1. **`IMPORTANT CAVEAT` -- closure is static until the preflight completes.** A new topology,
   coordinate, matrix-reflection or resource terminal would be an honest negative preflight result,
   not permission to weaken the checks. Post-preflight review must verify all nine mesh rows, both
   simultaneous-capacity stages, the five-leaf lifecycle, current/cumulative resource fields and
   summary-last consistency.
2. **`IMPORTANT CAVEAT` -- formal science remains blocked.** Neither the present PASS nor a natural
   preflight directly authorizes an eigensolve. Reviewed $T_{002}$ and $R_{002}$ must first be
   incorporated into the non-resetting formal controller contract and pass the Researcher/Skeptic
   gate.

Exactly one create-once command is authorized:

```text
cwd: /Users/whc/Documents/Work/epost/test/i4/femref-a2
/usr/bin/perl ./run_preflight.pl
```

This authorization is only for `resource-preflight-001/execution-002`. It does **not** authorize
formal `run-001/execution-001`, any eigensolve, retry or further execution ID, historical-output or
BIE/QZ/estimator read, effectivity comparison, or a change to the method, schedules, five canonical
leaf names, 2700 s/3 GiB total limits or claim boundary.

## O. Post-preflight review of `resource-preflight-001/execution-002`

### O.1 Audit frame and verdict

The consumed execution was reviewed from its four create-once leaves, the unchanged
`execution-001` evidence, and the reachable representation/phase-reduction lifetimes in
`run_i4_1b.m`. No source, design or artifact was modified and no program was run.

**Post-preflight verdict: `BLOCKED FOR EXECUTION / BOUNDED IMPLEMENTATION-LIFETIME DIAGNOSIS
AUTHORIZED`. Confidence: high for the hard resource terminal; medium-high for the bounded
implementation classification.** The present implementation cannot enter formal science under the
frozen 3 GiB limit. The available evidence does not establish that fitted P2 FEM itself is
intrinsically over budget, because the failing stage combines several source lifetimes and the code
retains a large non-scientific factor that is not consumed by the eigensolver.

### O.2 Artifact and resource consistency

- `resource.tsv` has exactly two ordered rows. `TARGET_EXIT/PUBLICATION_PENDING` records current
  38.368028 s, cumulative 56.594726 s, MATLAB signal 9 and peak 3,471,147,008 B. The authoritative
  `WHOLE_COMMAND_TERMINAL/RSS_HARD_LIMIT_REACHED` row records current 38.368379 s and cumulative
  56.595077 s with the same peak and signal.
- Summary-last reproduces the exact run/execution IDs, empty scientific preflight terminal,
  `RSS_HARD_LIMIT_REACHED`, prior/current/cumulative wall fields and prior/current/cumulative RSS
  fields. The empty preflight terminal is truthful because `PREFLIGHT_COMPLETE` was never reached.
- `residency.tsv` and `preflight.log` agree on the reached prefix: startup and all three bulk
  representations completed; `mesh-defect-N5-s12-g36` began but emitted no completion marker.
  Its sampled MATLAB-process peak is 3,360,882,688 B and its authoritative aggregate process-tree
  peak is 3,471,147,008 B. The latter exceeds 3,221,225,472 B by 249,921,536 B, so signal 9 and the
  RSS terminal are consistent with the controller's inclusive hard predicate.
- The directory contains only `preflight.log`, `residency.tsv`, `resource.tsv` and
  `preflight-summary.tsv`, with no `.partial`, mesh table, MAT, spectrum or field leaf. The missing
  `mesh-operators.tsv` is consistent with termination before all nine rows. `execution-001` remains
  unchanged. No eigensolve or formal result was reached.

### O.3 Strongest challenge and failure classification

The residency label does **not** prove that mesh construction alone requires 3.47 GB. One marker
covers `LOCAL_build_mesh` and every P2/P1 phase reduction; the end marker is written only after all
frozen phases (`run_i4_1b.m:250-301`). Therefore the hard stop could occur in geometry/assembly,
sparse phase reduction, Cholesky validation, or an overlap between consecutive pair lifetimes.

There is concrete source evidence for an avoidable implementation lifetime. Every phase reduction
computes and returns a sparse Cholesky `mass_factor` inside `pair`
(`run_i4_1b.m:1479-1488,1558-1582`), and the preflight overwrites `p2_pair`/`p1_pair` across phases
without a substage boundary (`run_i4_1b.m:262-270`). The factor is not read by either `eigs` call;
outside preflight byte reporting, the only source uses of `mass_factor` are its construction and
retention in the returned pair. Thus an old returned factor can remain live while a new pair is
constructed, and MATLAB allocator retention can further keep RSS high. This object is an SPD
implementation check, not a field, spectrum, branch object or required scientific output.

The strongest alternative is that even a single necessary sparse factor or assembly transient for
the first defect representation exceeds 3 GiB. The current combined marker cannot decide that
alternative. Consequently this is a **resource `BLOCKER` for the present implementation and every
formal launch**, but not yet a demonstrated method-intrinsic resource failure. The cheapest
decisive resolution is a bounded static live-object audit that separates mesh assembly, each P2/P1
phase-reduction lifetime and factor retention, and proves which factor/data must coexist for the
frozen mathematics. No new numerical method or experiment is needed for that diagnosis.

### O.4 Cumulative budget and claim boundary

Both preflight executions are consumed. Under the frozen non-resetting contract,

$$
T_{\mathrm{cum}}=18.226698+38.368379=56.595077\ \mathrm{s},
\qquad
T_{\mathrm{remaining}}=2643.404923\ \mathrm{s},
$$

and

$$
R_{\mathrm{cum}}=\max\{1084440576,3471147008\}
=3471147008\ \mathrm{B}>3221225472\ \mathrm{B}.
$$

Because this cumulative maximum already exceeds the hard cap, no further execution can be declared
passing under the current lifecycle merely by using less memory later. Any future treatment of an
implementation-fault run under the repository's operational-failure rule requires a new explicit,
reviewed lifecycle decision; this review does not make that decision.

The partial artifacts support only the three completed bulk representations and a resource prefix
through the first defect stage. They support no defect representation, nine-row resource model,
simultaneous-capacity stage, eigenpair, field, branch, P2 reference, uncertainty or effectivity
claim.

### O.5 Findings and bounded handoff

1. **`BLOCKER` -- formal and further execution are resource-blocked.** The authoritative aggregate
   RSS exceeded the frozen hard limit before the first defect representation completed. Formal
   `run-001/execution-001`, another preflight execution and every eigensolve remain unauthorized.
2. **`IMPORTANT CAVEAT` -- exact peak substage is unresolved.** The current marker coalesces build
   and phase-reduction work; it cannot support a publication claim that P2 assembly itself caused
   the peak.
3. **`IMPORTANT CAVEAT` -- method-level closure would be premature.** The unused returned
   `mass_factor` and overlapping phase-pair lifetime are specific, bounded implementation suspects.
   A correctly implemented frozen method has not yet been shown unable to fit 3 GiB.

The same Researcher may perform a **design/static-only bounded memory-lifetime diagnosis** limited
to the active P2/P1 pair/factor lifetimes, preservation of the SPD gate, and separation of required
scientific objects from disposable validation temporaries. The diagnosis may propose the smallest
implementation repair but may not change the continuous model, P2 forms, meshes, phases, schedules,
hard limits, five-leaf schema or claim boundary. It does not authorize an Engineer change, a new
execution ID, any runner/MATLAB invocation, formal science or effectivity comparison. A subsequent
execution requires explicit lifecycle authority and fresh Researcher--Skeptic gates.

## P. Final static review of Section 22

### P.1 Audit frame and final verdict

This review checks only whether Section 22 faithfully closes the present round: artifact facts,
source facts, conditional attribution, consumed hard budget and the status of future repair
candidates. No implementation or scientific path was reopened.

**Final post-run verdict for this round: `BLOCKED`. Confidence: high.** Section 22 correctly
preserves the authoritative hard-resource failure and does not overstate it as an intrinsic failure
of fitted P2 FEM. Formal science cannot proceed under the consumed lifecycle; the proposed
memory-lifetime repairs remain explicitly unimplemented and unvalidated.

### P.2 Evidence/inference and budget audit

- The established artifact statements agree with Section O: three bulk representations completed;
  the first defect broad stage has only a start marker; aggregate RSS reached 3,471,147,008 B and
  the controller stopped with signal 9 and `RSS_HARD_LIMIT_REACHED`.
- The source facts are accurately separated from inference. The broad marker encloses mesh build
  and P2/P1 reductions, returned reduced-mass factors are retained although neither generalized
  eigensolver reads them, and old/new pair overlap or allocator retention is only a conditional
  explanation. Section 22 neither assigns the peak uniquely to that mechanism nor claims its
  removal would be sufficient.
- The hard budget remains consumed exactly as reviewed:

$$
T_{\mathrm{cum}}=56.595077\ \mathrm{s},\qquad
T_{\mathrm{remaining}}=2643.404923\ \mathrm{s},
$$

$$
R_{\mathrm{cum}}=3471147008\ \mathrm{B}>3221225472\ \mathrm{B}.
$$

  Section 22 does not reset either execution or imply that a later lower peak could erase this
  cumulative maximum.
- The four listed repair/diagnostic ideas are properly labeled provisional, unimplemented and
  unvalidated. They preserve the SPD statement and frozen mathematical objects on paper, but do
  not yet constitute an accepted source change or evidence of resource feasibility.

### P.3 Findings, surviving boundary and handoff

1. **`BLOCKER` -- the active lifecycle has exceeded its hard RSS budget.** No formal run, further
   preflight identity, eigensolve or Engineer implementation is authorized. Advancing requires an
   explicit future lifecycle decision followed by full Researcher--Engineer--Skeptic gates.
2. **`IMPORTANT CAVEAT` -- peak attribution remains unmeasured.** The evidence cannot distinguish
   one necessary sparse factorization from avoidable pair overlap, assembly temporaries or allocator
   retention. This uncertainty limits root-cause language but does not weaken the hard-stop fact.
3. **`IMPORTANT CAVEAT` -- repair sufficiency is unknown.** Discarding unused factors, changing
   lifetime order, applying a fill-reducing permutation or adding substage markers are candidates,
   not demonstrated fixes.

What survives is limited but defensible: the three bulk representation prefixes, the truthful
resource terminal, and a bounded source-level implementation hypothesis. There is **no** defect
eigenpair or field, no eigensolve, no empirical P2 reference, no current-run P1--P2 drift, no
uncertainty estimate and no effectivity result. Project synchronization, if any, may state only this
blocked resource outcome and claim boundary; it may not publish a reference scalar or scientific
validation result.
