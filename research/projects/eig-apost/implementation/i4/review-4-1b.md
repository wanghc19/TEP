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

## Q. Design review of Section 23 independent repair lifecycle

### Q.1 Audit frame and verdict

The target is the separately authorized coarse-core P2 lifecycle in design Section 23, not a
reinterpretation of the two consumed preflights. Success at this gate means that the design can
produce a deterministic, reviewable preliminary empirical P2 reference candidate while preserving
the continuous problem, and that neither its fixed schedule nor its controllers are already shown
to violate the absolute five-hour/3 GiB limits.

**Verdict: `PASS WITH CONDITIONS`. Confidence: medium-high.** No unresolved mathematical,
implementation-feasibility, resource or publication `BLOCKER` prevents bounded implementation.
The remaining conditions concern honest weak-identity and partial-uncertainty publication plus the
mandatory measured preflight gate; they do not authorize execution.

### Q.2 Mathematical and schedule audit

- The continuous coefficient, fitted polygonal geometry, fixed $\beta=0.5$, quasiperiodic phase
  constraints, six-node P2 basis, P2 weak forms and relation $\lambda=k^2$ are explicitly unchanged.
  P1 survives only as the local nodal/bilinear embedding identity; no P1 eigensolver, historical
  target or P1 field can enter selection.
- The three-level axes are identifiable and non-confounded at their anchors:
  $s=6,9,12$ at $(N,g)=(4,24)$; $g=16,24,32$ at $(N,s)=(4,9)$; and
  $N=3,4,5$ at $(s,g)=(9,24)$. $\Theta_5\to\Theta_9$ adds four exact midpoint twists without
  repeating the shared five, and $10^{-10}\to10^{-8}$ supplies an algebraic axis. These are
  sufficient for preliminary empirical sensitivity; they are not an asymptotic or certified
  error analysis.
- The call count is correct:
  $5+10+10+10+4+5+17=61$, with exactly five optional 60-root primary recomputations and hard cap
  66. The extension rule is fixed by the 3.35 coverage sentinel or absence of a preliminary branch,
  applies to all five primary slices, and retains 48-root authority on failed 48/60 agreement.
  No refinement or bulk slice has a result-dependent extension.
- A complete cluster intersecting $W_3$ must have finite positive eigenvalues, flag zero, bounded
  residual/orthogonality and a finite full P2 subspace. Whole-cluster preservation, true quadratic
  common-grid evaluation and the normalized principal-subspace overlap make the tracked objects
  field-bearing and basis invariant. The assignment, graph directions, object/component IDs and
  rank tuple are deterministic and use only current-run P2 information; frequency is a later
  assignment tie-break, not a BIE-nearest-root selector.

### Q.3 SPD, resource and lifecycle audit

- For a permutation $p$, $M_\phi$ is positive definite if and only if
  $M_\phi(p,p)$ is positive definite. `symamd` on the symmetrized sparsity pattern, an explicit
  permutation check, sparse `chol`, and immediate factor discard therefore preserve the exact SPD
  statement while removing the previously unused returned-factor lifetime. Recording factor
  `nnz` before release does not make the factor a scientific object.
- The preflight uses only four actual extrema that occur in the science graph; no science
  configuration combines their independent maxima. Fine-grained build/reduce/SPD/release markers
  and actual matrices directly address the unresolved Section O attribution. It performs no
  capacity simulation, eigensolve, SVD, spectrum, field, branch or rank construction. Its four
  authoritative leaves and summary-last boundary are sufficient for a post-preflight resource
  decision.
- The prospective 5,000--8,000 reduced-DOF and 2.4--2.8 GB figures are planning inferences, not
  proof of fit. They are nevertheless materially smaller than the failed 10,336-DOF retained-factor
  path, and the design streams configurations and retains only canonical branch fields. No present
  evidence forces the new path over 3 GiB. Actual preflight success remains necessary but does not
  itself authorize science.
- Both controllers have only the absolute epoch predicate
  $t_{\mathrm{UTC}}\ge1788266751$ and inclusive aggregate-tree predicate
  $R_{\mathrm{tree}}\ge3221225472\ \mathrm{B}$. Implementation, reviews, preflight, science and
  publication share that same non-pausing lifecycle. There is no lower resource gate, reserve,
  forecast stop, stall rule or grace period.
- The exact create-once identities are `resource-preflight-002/execution-001` and
  `run-002/execution-001`. Active source must reject every old identity and read no historical
  artifact, BIE/QZ datum, estimator, Markdown or Git state. The old sources, controllers and two
  consumed trees remain immutable.

### Q.4 Strongest challenge and findings

The strongest scientific challenge is that the mandatory three-twist track can have weak overlap
or weak localization and still be ranked. This can produce a deterministic P2 component without
strong evidence that it is the intended localized guided mode. It does not invalidate the
preliminary, non-certified candidate deliverable because the full subspaces, $O_{\min}$,
localization, parity and classification are published and no threshold failure is allowed to be
silently converted into a stronger identity claim.

There is no unresolved `BLOCKER`.

1. **`IMPORTANT CAVEAT` -- preliminary identity may be weak.** A weak-overlap, delocalized,
   embedded or parity-unavailable winner remains a candidate, not a confirmed same guided mode.
   The exact diagnostics and fields must remain visible in stage-one artifacts and the final label
   must retain `NONCERTIFIED / NO CONTINUOUS EXISTENCE CLAIM / NO EFFECTIVITY`.
2. **`IMPORTANT CAVEAT` -- science memory remains unmeasured.** The actual-only preflight measures
   representation/factor feasibility, not eigensolver workspaces or field publication. Formal
   launch therefore requires post-preflight review, exact theory-to-code/spec-to-code review and a
   still-positive absolute-time margin; preflight success alone is insufficient.
3. **`IMPORTANT CAVEAT` -- a partial observed sum can underestimate missing axes.** Every
   unavailable component must remain `NaN` and the finite-component inventory must be published.
   If no component is finite, `Delta_ref_obs` must not be exposed as numerical zero; this is a
   bounded publication-semantic condition for pre-execution review, not a reason to suppress an
   otherwise valid preliminary candidate.
4. **`MINOR CAVEAT` -- the 900 s and 7,200 s allowances are estimates only.** They create no
   controller threshold and shrink automatically as implementation/review consumes the fixed UTC
   lifecycle.

### Q.5 Authorization boundary

The same Engineer is authorized only to implement the Section 23.8 bounded source/docs delta in
the existing `test/i4/femref-a2/` directory: add `run_i4_1b_core.m`, fixed no-argument
`run_preflight_002.pl` and `run_formal_002.pl`, and mechanically update README/SYMBOLS. The
implementation must preserve the exact P2 mathematics, 61/66 graph, immediate factor release,
pure-P2 rank, current-run-only information boundary, four-leaf preflight schema, create-once IDs
and the two hard resource predicates.

This verdict does **not** authorize either controller, MATLAB/Octave/Python, output creation,
preflight, eigensolve or science. After implementation, the same Researcher must supply an exact
theory-to-code audit and this same Skeptic must complete pre-execution spec/resource review before
the single preflight command can be considered. Formal science remains separately blocked until
successful preflight post-review.

## R. Preflight spec-to-code review of Sections 23--25

### R.1 Audit frame and verdict

This review maps Sections 23--25 to `run_i4_1b_core.m`, both new controllers and the mechanical
README/SYMBOLS delta. The immediate acceptance target is only the zero-eigensolve
`resource-preflight-002/execution-001`; formal science remains outside authorization.

**Verdict: `REVISE`. Confidence: high.** The mathematical core, preflight call graph, conditional
60-root authority repair and information isolation pass static inspection. One publication/resource
blocker remains in both controllers and is reachable in the preflight command.

### R.2 What passed static inspection

- The exact identities are `resource-preflight-002/execution-001` and
  `run-002/execution-001`. The core rejects every other pair and constructs paths only below its own
  experiment directory. Neither new namespace exists. No active read of historical output,
  Markdown, Git, BIE/QZ data, density, estimator or prior reference was found.
- `LOCAL_spec`, the named meshes, fitted P2 topology, seven-point degree-five assembly, reflection
  map, quasiperiodic prolongation, finite/raw-Hermitian/canonical checks and $\lambda=k^2$ path
  preserve the Section 23 mathematics. P1 eigensolvers and historical-target logic are absent.
- `LOCAL_mass_spd` verifies the `symamd(spones(M+M'))` permutation, performs Cholesky on
  $M(p,p)$, records factor `nnz` and clears the factor before returning. Retained pairs contain only
  stiffness, mass and prolongation.
- Preflight reaches exactly four actual named extrema and, for each, the ordered
  `BUILD`, `REDUCE_K`, `REDUCE_M`, `SPD`, and `RELEASED` stages. It returns before every source
  `eig`, `eigs`, `svd`, spectrum, field, object, assignment and rank path. Its authoritative schema
  is exactly `representation.tsv`, `run.log`, `resource.tsv` and summary-last
  `preflight-summary.tsv`.
- The formal source counts five primary calls, optional five-call extension, 30 mesh-axis calls,
  four added twists, five algebraic calls and 17 bulk calls: 61 or 66. `eigs` options, deterministic
  start vector, full W3 clusters, true P2 common-grid samples, dummy-augmented lexicographic
  assignment, graph/component IDs, preliminary rank and finite-component/`NaN` uncertainty
  semantics match the design.
- The Section 25 authority delta is auditable. Compact 48 and attempted 60 evidence are separate;
  first-48 cluster boundaries and multiplicities must match; each corresponding cluster uses the
  exact full-mass cross-Gram and minimum principal overlap. A pass gives sole 60-root object/field
  authority. Invalid or inconsistent expansion retains valid 48-root authority and explicitly
  publishes `SPECTRUM_EXPANSION_INCONSISTENT` plus `SPECTRUM_COVERAGE_PARTIAL`; invalid 48 has no
  active authority. The per-slice table exposes the complete decision without duplicating inactive
  fields.
- Aggregate RSS is deduplicated over the root/recursive-descendant/dedicated-PGID union. The only
  numerical resource predicates in source are inclusive UTC/monotonic arrival at epoch
  `1788266751` and aggregate RSS at least 3,221,225,472 B. The 0.25 s polling interval is not a
  lower gate.

### R.3 Blocker: hard-deadline publication can commit a false terminal

The alarm handler in `run_preflight_002.pl:26-30` only sets `wall_reached` and kills the MATLAB
group; it does not terminate or latch the controller publication path. After MATLAB is reaped, the
controller freezes `terminal` and `elapsed`, publishes `resource.tsv`, then publishes the atomic
summary, with deadline checks only between/after those operations
(`run_preflight_002.pl:129-143,233-260`). If the alarm fires during `write_resource` or
`write_summary`, the write can finish and rename its `.partial`; in particular the authoritative
summary can record the earlier `NATURAL_EXIT` after the hard epoch. The subsequent check may exit
nonzero, but it cannot retract the already committed false summary or correct the frozen resource
terminal. A smaller race remains between the last check and `alarm(0)`.

The same defect exists in `run_formal_002.pl`, although formal is not presently authorized. It
violates the Section 23 rule that publication shares the absolute epoch and that a hard stop cannot
fabricate READY. This is a concrete publication/resource `BLOCKER`, not optional robustness.

The smallest repair is to use one explicit publication-completion latch under the same absolute
deadline: before summary commit, an alarm/deadline event must abort publication and make an
authoritative wall terminal or leave only clearly non-authoritative partial evidence; no frozen
natural/READY summary may be renamed. Summary rename may be the final completion point only after
fresh UTC and monotonic checks, and the alarm handler must fail closed before that point. The same
repair should be applied mechanically to both controllers without adding a reserve, grace period,
earlier deadline, lower RSS threshold or new artifact.

### R.4 Other findings and authorization boundary

1. **`BLOCKER` -- deadline/publication state is not fail-closed.** Repair and focused static
   Researcher/Skeptic re-review are required before any new controller runs.
2. **`IMPORTANT CAVEAT` -- MATLAB parse/runtime remains unverified.** Static reading found no
   specific parse defect. This absence of execution evidence is not itself a blocker; a correctly
   published zero-eigensolve preflight is the bounded next check after the controller repair.
3. **`IMPORTANT CAVEAT` -- formal memory/publication remains a later gate.** Preflight cannot
   authorize eigensolver or field lifetimes, and the formal refinement loop's exact live-object
   behavior must be reviewed before science even after a successful preflight.
4. **`MINOR CAVEAT` -- README authorization wording is intentionally stale until this gate
   passes.** Documentation does not control execution and should be synchronized only after the
   blocker is repaired.

Current authorization is **`NO PREFLIGHT / NO FORMAL / NO OUTPUT / NO EIGENSOLVE`**. In particular,
`/usr/bin/perl ./run_preflight_002.pl` is not authorized by this verdict. The same Engineer may make
only the bounded controller publication-latch repair above after the same Researcher freezes and
audits it; no mathematical, schedule, authority, identity, artifact-schema or resource-limit change
is warranted.

## S. Focused controller re-review of Sections 26--27

### S.1 Audit frame and verdict

This delta review reopens only the Section R publication-latch blocker in
`run_preflight_002.pl` and its mechanically parallel formal controller. It does not reopen the P2
mathematics, configuration graph, conditional 60-root authority or information-isolation findings
that already passed Section R. The immediate success criterion is that the zero-eigensolve
preflight cannot publish a natural/complete summary after the absolute deadline; formal science
remains outside this gate.

**Verdict: `PASS`. Confidence: high.** Sections 26--27 and the current controllers close the sole
Section R blocker. No new numerical, implementation, resource or publication blocker was found.

### S.2 Decisive publication-state audit

- Both controllers keep one alarm armed from the positive remainder to the immutable epoch
  `1788266751`. The only RSS predicate remains aggregate target-tree RSS
  `>=3221225472` B; no reserve, lower limit, grace period or second resource gate was introduced.
- Before canonical publication, `resource.tsv` is opened create-once and receives synchronized,
  monotonically indexed stage and `PUBLICATION_PENDING` events. Summary content is first written
  and synchronized under the exact final name plus `.partial`; the whole-command terminal event is
  then appended and synchronized.
- Fresh UTC/monotonic inclusive checks occur after the pending ledger, after summary preparation,
  and immediately before atomic rename. At any alarm before commit, the handler latches
  `publication_aborted`, kills any still-live target, appends and synchronizes a
  `WALL_HARD_LIMIT_REACHED` correction when the ledger descriptor exists, and exits nonzero. Thus a
  previously observed `NATURAL_EXIT` or preliminary scientific terminal cannot be renamed as an
  authoritative success after that event.
- Atomic rename is the sole completion latch. During the narrow rename/latch interval, existence
  of the exact final summary is the specified completion witness; otherwise
  `summary_committed` is set only after successful rename, and only then is the alarm disarmed.
  Write, sync, close or rename failure instead appends a publication-failure correction when
  possible and leaves no authoritative final summary.
- The repaired preflight identity is still exactly
  `resource-preflight-002/execution-001`, and that namespace is absent. Its allowed leaves remain
  `representation.tsv`, `run.log`, `resource.tsv` and summary-last `preflight-summary.tsv`.
  `resource-preflight-001` executions remain untouched. The parallel formal controller retains
  `run-002/execution-001`, but this review does not authorize it.

### S.3 Findings, surviving claims and next gate

There are no unresolved `BLOCKER` findings. MATLAB parse/runtime remains an **`IMPORTANT CAVEAT`**
because it has not been exercised; the bounded zero-eigensolve preflight is precisely the next
decisive check and must receive independent post-preflight artifact/resource review. Formal
eigensolves, field publication and science-memory feasibility remain a later
**`IMPORTANT CAVEAT`** and are not implied by preflight success.

The controller repair is source-local and preserves the already-defensible continuous model, P2
weak form, 61/66 schedule, spectrum-authority semantics, current-run-only information boundary,
create-once artifact contract and two hard resource predicates.

### S.4 Exact authorization boundary

One and only one command is authorized, from
`/Users/whc/Documents/Work/epost/test/i4/femref-a2`:

`/usr/bin/perl ./run_preflight_002.pl`

This authorization is only for the create-once zero-eigensolve
`resource-preflight-002/execution-001`. It does not authorize `run_formal_002.pl`, any formal
science, `eig`/`eigs`, retry, a new execution label, effectivity comparison or historical-output
reuse. Post-preflight review is mandatory before any later execution decision.

## T. Post-preflight review of `resource-preflight-002/execution-001`

### T.1 Audit frame and verdict

This review audits only the consumed zero-eigensolve preflight execution and the reached failure
locator. Its success criterion was completion of all four actual representation/reduction/SPD
objects under the continuing absolute lifecycle, with no `eig`, `eigs` or scientific claim.

**Verdict: `REVISE`. Confidence: high.** The execution is internally consistent and fail-closed,
but it did not complete the preflight. The reached failure is a concrete mesh-implementation
`BLOCKER` for the next computation, not evidence that the frozen continuous model or P2 FEM method
is intrinsically invalid or over budget.

### T.2 Artifact and resource evidence

- The create-once directory contains exactly the four Section 23 authoritative leaves:
  `representation.tsv`, `run.log`, `resource.tsv` and summary-last `preflight-summary.tsv`. No
  partial file is present. The four observed SHA-256 identities were recorded during this review;
  the artifacts must now remain immutable.
- `representation.tsv` contains its header and one truthful failure row for `bulk-s9-g24`, with no
  fabricated mesh/operator counts. `run.log` records `BUILD_BEGIN`, then
  `MESH_QUALITY_UNRESOLVED` with the exact locator `bulk-s9-g24 lost a required constraint.`, and
  the same scientific terminal. There is no `BUILD_END`, reduction, SPD, release, eigensolve or
  spectrum marker.
- The resource ledger is ordered and summary-consistent: stage peak
  `bulk-s9-g24/BUILD`, `PUBLICATION_PENDING`, then `PREFLIGHT_OUTPUT_INCOMPLETE`; the final elapsed
  time is `14.131975` s and aggregate peak RSS is `843153408` B. The canonical summary repeats
  controller `PREFLIGHT_OUTPUT_INCOMPLETE`, scientific `MESH_QUALITY_UNRESOLVED`, the same elapsed
  time and the same RSS. This is well below `3221225472` B and occurred before the fixed epoch
  `1788266751`; it is not a resource failure.
- MATLAB returned without a signal after publishing its scientific-negative terminal, while the
  controller correctly refused to classify that as `PREFLIGHT_COMPLETE`. Therefore the
  publication latch passed its first live fail-closed test. The execution supplies no evidence for
  the other three mesh representations or for formal eigensolver/field memory.

### T.3 Strongest challenge and findings

The strongest challenge is whether a reflection-closed triangulation can preserve every required
outer, cell and material-interface constraint on the frozen mesh. The current source first asks
`delaunayTriangulation(points,constraints)` for a constrained mesh, then
`LOCAL_reflection_closed_triangles` replaces the unpaired-right connectivity by reflections of the
unpaired-left connectivity. Only afterward does it compare the required constraints with the new
active-edge graph. The first bulk object fails exactly that comparison. This establishes that the
current connectivity-rewrite implementation does not preserve its own required-edge invariant; it
does not establish that no valid fitted, reflection-compatible mesh exists.

1. **`BLOCKER` -- required constraints are lost by the reached mesh implementation.** Location:
   `LOCAL_build_mesh` after `LOCAL_reflection_closed_triangles` and before P2 topology. Consequence:
   no frozen P2 representation can be assembled or reviewed, so formal science cannot start. The
   cheapest decisive repair/check is to expose the exact missing-edge inventory in a bounded
   mesh-only implementation diagnostic, make the reflection tie resolution preserve the fixed
   constraint set, and require all four named preflight meshes to pass constraint, area,
   reflection and material-interface checks. No continuous parameter, mesh schedule, P2 basis or
   weak form needs to change.
2. **`IMPORTANT CAVEAT` -- resource feasibility remains only partially observed.** The measured
   first-build peak is favorable, but no complete mesh, reduction or Cholesky factor was reached.
   It cannot support a formal-memory inference until a corrected preflight finishes.
3. **`MINOR CAVEAT` -- controller/scientific terminal names differ by design.**
   `PREFLIGHT_OUTPUT_INCOMPLETE` is the correct fail-closed controller classification of the more
   specific MATLAB terminal `MESH_QUALITY_UNRESOLVED`; this is not contradictory evidence.

### T.4 What survived and minimal next gate

The continuous coefficients and geometry, six-node P2 weak form, quadrature, phase conventions,
61/66 prospective schedule, current-run-only information boundary, zero-eigensolve dispatch,
create-once publication and sole hard limits all survive this execution. No reference candidate,
P1--P2 drift, field identity, convergence, effectivity or certified conclusion was produced.

`execution-001` is consumed and immutable, but this bounded code/configuration failure does not
consume the `femref-a2` method attempt. The same Researcher may freeze only a constraint-preserving
mesh repair and the mechanical continuation identity. After design review, the same Engineer may
repair the existing core and mechanically change the exact preflight pair to the smallest unused
`resource-preflight-002/execution-002`, without reading, overwriting or reusing `execution-001`.
The corrected source must then pass a fresh Researcher theory-to-code audit and same-Skeptic
spec-to-code/resource review.

This review does **not** authorize `execution-002` to run. A later PASS may authorize exactly one
updated no-argument `/usr/bin/perl ./run_preflight_002.pl` invocation for that create-once ID. The
new execution must remain under the same non-reset absolute epoch `1788266751` and the sole
`3221225472` B RSS limit; the observed `14.131975` s execution remains in the lifecycle ledger.
Formal science, `eig`/`eigs`, new attempt creation, historical-output reads and effectivity remain
unauthorized.

## U. Focused design review of Section 28

### U.1 Audit frame and verdict

This review reopens only the Section T constraint-loss blocker and the proposed create-once
continuation. The acceptance criterion is a deterministic, reflection-closed connectivity choice
that cannot drop a frozen constraint or alter the P2 problem, followed by an implementation-only
handoff; no execution is in scope.

**Verdict: `PASS`. Confidence: high.** Section 28 gives a bounded and falsifiable mesh repair. No
unresolved mathematical, mesh-legality or resource blocker prevents implementation.

### U.2 Strongest challenge and decisive checks

The strongest counterexample is that choosing one side of a constrained-Delaunay reflection tie
could close the triangle inventory while silently deleting a constraint, introducing a crossing or
creating an overlap/gap. Section 28 now rejects exactly those outcomes rather than assuming that
reflection closure implies a valid triangulation:

- the two candidates are finite, deterministic and individually reflection-closed; fixed
  left-then-right order is independent of eigenvalues, fields, BIE/QZ data, estimators, historical
  output and resource observations;
- positive area, unique triangles, exact reflected partners, incidence-one/two, planar-edge,
  segmented-boundary, total-area and rectangle-containment checks jointly make coverage and
  non-overlap testable;
- every original outer, cell and polygonal-interface constraint must remain an exact active edge,
  while fitted-interface crossing and reflected material-label agreement remain mandatory; and
- periodic vertex/midpoint, P2 reflection, finite/Hermitian, SPD and seam checks remain downstream
  gates. If neither candidate passes, the implementation fails closed with both reasons rather
  than weakening a constraint.

The implementation should interpret the planar-edge condition strictly: any two distinct edges
may intersect only at a shared endpoint, and positive-length collinear overlap is invalid even when
the edges share one endpoint. This is a **`MINOR CAVEAT`** suitable for exact spec-to-code review,
not a design blocker, because Section 28 already forbids collinear interior overlap and shortened
constraints.

### U.3 Continuation and resource audit

`resource-preflight-002/execution-002` is the exact smallest unused continuation and is presently
absent. Section 28 keeps `execution-001` immutable and outside the active MATLAB input graph;
preflight allowlist, controller constant, literal batch call, collision check and output directory
must move together to `execution-002`. Any complete, scientific-negative, resource or publication
terminal consumes that label.

The fixed epoch remains `1788266751`; the previous `14.131975` s observation is not reset. The
only memory upper remains aggregate process-tree RSS `3221225472` B. The repaired preflight still
has zero `eig`/`eigs`/`svd` calls and exactly four canonical leaves. Hence the repair introduces no
new scientific work or lower resource gate. Complete resource feasibility remains an
**`IMPORTANT CAVEAT`** to be resolved only by a later reviewed preflight, not a reason to block
this bounded implementation.

### U.4 Authorization boundary

The same Engineer is authorized only to implement the Section 28 connectivity candidate
constructor/validator inside the existing mesh helper, mechanically switch the preflight identity
and controller dispatch to `resource-preflight-002/execution-002`, and synchronize the minimal
README/SYMBOLS text. The Engineer must not change points, constraints, $(N,s,g)$ values, P2 basis,
quadrature, weak form, coefficient, phases, schedule, ranking, uncertainty or artifact names.

This PASS does **not** authorize `/usr/bin/perl ./run_preflight_002.pl`, MATLAB, output creation,
formal science, `eig`/`eigs`, retry, new attempt creation or effectivity. A Researcher
theory-to-code audit and same-Skeptic exact spec-to-code/resource review remain mandatory before
any `execution-002` launch.

## V. Final preflight review of Sections 28--30

### V.1 Audit frame and verdict

This focused review maps the frozen Section 28 repair and Sections 29--30 delta to the current mesh
helper, preflight controller and minimal documentation. The sole acceptance target is one
create-once zero-eigensolve `resource-preflight-002/execution-002`; formal science is excluded.

**Verdict: `PASS`. Confidence: high.** The constraint-loss and orphan-point failure mechanisms are
closed in source. No unresolved mathematical, mesh, resource or publication blocker prevents the
bounded preflight.

### V.2 Exact mesh and identity audit

- `LOCAL_reflection_closed_triangles` partitions the original constrained-Delaunay rows into
  paired, unpaired-left, unpaired-right and forbidden zero-centroid inventories. It constructs
  exactly the left-authority and right-authority candidates, tests them in that fixed order, and
  selects no candidate from spectral, BIE/QZ, estimator, history or resource information.
- Each candidate is positively oriented and canonically ordered before use. The validator rejects
  nonfinite/duplicate/nonpositive triangles and now requires
  `unique(triangles(:)) == (1:size(points,1))'`; thus the Section 29 orphan-point path cannot reach
  P2 topology or SPD while suppressing consideration of the second authority.
- Reflection partners are checked bijectively and involutively. Active-edge incidence, exact
  segmented outer boundary, domain area, rectangle containment and the full frozen constraint set
  are checked before material/P2 construction. The edge-pair predicate rejects proper/touching
  nonvertex intersections and positive-length collinear overlap even for edges sharing an
  endpoint. Fitted-interface crossings, reflected material labels and edge-derived P2 midpoint
  reflection remain mandatory. Neither candidate can pass by deleting a point or constraint.
- On success, the existing representation/log leaves expose the chosen authority and both bounded
  candidate reasons. On failure, the preflight remains scientific-negative and fail-closed; it
  does not fabricate representation counts or continue to reduction/eigensolve.
- MATLAB accepts only exact preflight `resource-preflight-002/execution-002` or formal
  `run-002/execution-001`. The no-argument preflight controller fixes the same new ID and literal
  batch call, rejects collision, and the namespace is absent. It does not read
  `execution-001`. The prior tree remains immutable.

### V.3 Resource, publication and claim boundary

The one armed controller deadline remains absolute epoch `1788266751`; the sole memory stop is
inclusive aggregate target-tree RSS `3221225472` B. There is no lower gate or reset. The Section 27
publication latch remains unchanged: append-only resource events, synchronized summary partial,
fresh deadline checks and atomic summary-last rename. The preflight call graph still builds exactly
four real representation/reduction/SPD objects and returns before every `eig`, `eigs`, `svd`,
spectrum, field or reference path.

Complete four-mesh runtime and factor memory remain an **`IMPORTANT CAVEAT`**, because the prior
execution ended during the first build. That empirical uncertainty is the purpose of this
preflight and does not block it. No additional caveat changes the authorization decision.

### V.4 Exact authorization boundary

One and only one command is authorized, from
`/Users/whc/Documents/Work/epost/test/i4/femref-a2`:

`/usr/bin/perl ./run_preflight_002.pl`

It may create only `resource-preflight-002/execution-002` and must receive independent post-run
artifact/resource review. This PASS does not authorize `run_formal_002.pl`, formal science,
`eig`/`eigs`, retry, another execution label, a new attempt, historical-output reads, reference
publication or effectivity comparison.

## W. Post-preflight review of `resource-preflight-002/execution-002`

### W.1 Audit frame and verdict

This review audits the consumed second zero-eigensolve preflight and asks whether failure of both
forced reflection-closed connectivity candidates invalidates the P2 FEM, exceeds the resource
budget, or identifies a bounded representation implementation problem.

**Verdict: `REVISE`. Confidence: high.** The current preflight remains blocked, but the evidence
does not show a P2 mathematical or resource failure. It shows that exact reflection closure of the
triangle connectivity is an overconstraining implementation path for the present constrained-
Delaunay tie inventory. A bounded Researcher study of retaining the original conforming fitted
connectivity and moving parity to common-grid field samples is authorized.

### W.2 Artifact and resource audit

- The create-once tree contains exactly `representation.tsv`, `run.log`, `resource.tsv` and
  summary-last `preflight-summary.tsv`, with no partial. These leaves and their observed hashes are
  now immutable.
- `run.log` records only `bulk-s9-g24/BUILD_BEGIN`, followed by the exact bounded reasons
  `left-authority: active-edge incidence is not one or two` and
  `right-authority: active-edge incidence is not one or two`, then
  `MESH_QUALITY_UNRESOLVED`. `representation.tsv` truthfully publishes one zero-count failure row.
  No build completion, reduction, SPD check, eigensolve, spectrum, field or reference exists.
- Resource and summary artifacts agree exactly: controller
  `PREFLIGHT_OUTPUT_INCOMPLETE`, scientific terminal `MESH_QUALITY_UNRESOLVED`, wall
  `13.620530` s and aggregate peak RSS `808861696` B. The ordered ledger ends with the same
  terminal. This is neither the fixed wall deadline nor the `3221225472` B RSS stop.
- Across the two consumed `resource-preflight-002` executions, the observed debugging wall is
  `27.752505` s and observed maximum peak RSS is `843153408` B. These observations do not reset the
  continuing epoch `1788266751`, and they still provide no complete four-mesh or formal-resource
  evidence.

### W.3 Strongest challenge and classified findings

The strongest challenge is that abandoning mesh-level reflection closure could corrupt parity or
mode identity. That would be a real issue only if exact reflection of the connectivity were part of
the continuous problem or P2 weak form. It is not: the continuous geometry/coefficient are
reflection symmetric, while a conforming fitted finite-element mesh may break that symmetry by
Delaunay tie choice without changing the Galerkin space's mathematical validity. Parity can be
evaluated after solving by reflecting physical sample locations and comparing the P2 fields or
field subspaces on a fixed symmetric common grid.

1. **`BLOCKER` -- forced connectivity reflection closure is not feasible for the reached mesh.**
   Both deterministic authorities fail the same active-edge incidence invariant before any P2
   object exists. This blocks the current implementation, but not the P2 formulation. The cheapest
   resolution is to determine whether the untouched constrained-Delaunay connectivity passes the
   standard conforming/fitted legality checks; if so, retain it instead of synthesizing a
   reflection-closed triangle set.
2. **`IMPORTANT CAVEAT` -- parity must remain an honest field diagnostic.** If mesh-level
   reflection is removed, vertex/edge permutation parity cannot be silently retained. The
   Researcher must specify P2 evaluation at paired common-grid points, weights, normalization and
   scalar/subspace reflection comparison. Unavailable or weak parity remains a diagnostic caveat
   and must not delete an otherwise valid field-bearing FEM candidate.
3. **`IMPORTANT CAVEAT` -- the original connectivity has not yet passed the full frozen check
   chain.** It must still use every frozen point and constraint, have positive unique triangles,
   incidence one/two, no edge crossing/overlap, exact segmented outer boundary and domain cover,
   zero fitted-interface crossing, correct material labels, valid periodic vertex/midpoint maps,
   finite/Hermitian assembly and SPD mass. Evidence is presently unavailable, not presumed.
4. **`MINOR CAVEAT` -- resource feasibility remains partial.** The low first-build wall/RSS is
   encouraging but cannot predict four reductions/factors or formal eigensolver storage.

### W.4 What survived and minimal next gate

The continuous model, physical parameters, six-node P2 basis, quadrature, weak form,
$\lambda=k^2$, quasiperiodic phases, spectrum schedule, ranking, uncertainty and information
isolation survive. The execution produced no reference, P1--P2 drift, parity result, eigenpair,
effectivity or existence claim. `execution-002` is consumed; the `femref-a2` method attempt is not.

The same Researcher is authorized only to investigate and freeze the following bounded repair:

1. retain the original constrained-Delaunay connectivity exactly when it passes the full
   conforming/fitted/periodic/assembly legality chain, without deleting points or constraints;
2. remove exact triangle/edge reflection closure as a mesh-acceptance requirement only if it is
   replaced by a precisely defined reviewer-auditable P2 common-grid field/subspace reflection
   diagnostic at the parity-eligible phases; and
3. preserve parity as classification evidence rather than a filter, with no BIE/QZ, estimator,
   historical output or current-root proximity involved.

This is research/design authorization only. It does not authorize source edits, a new execution
ID, MATLAB, preflight, formal science, `eig`/`eigs`, output creation or effectivity. Any frozen
repair must return through design review, Engineer implementation, Researcher theory-to-code and
same-Skeptic exact pre-execution review under the same absolute epoch and 3 GiB upper.

## X. Focused design review of Sections 31 and 31.4

### X.1 Audit frame and verdict

This review asks whether the untouched constrained-Delaunay connectivity can support the same
straight-sided fitted P2 Galerkin problem without exact mesh reflection, and whether the proposed
sample-space parity diagnostic is mathematically and operationally determined. The next output is
implementation only; no execution is in scope.

**Verdict: `PASS`. Confidence: high.** The original-connectivity acceptance chain is sufficient
for the declared straight-sided P2 discretization, conditional on all listed checks passing. The
weighted projected-reflection diagnostic is well defined and truthfully downgraded from exact
discrete symmetry to empirical common-grid parity. No unresolved mathematical, implementation,
resource or publication blocker prevents bounded implementation.

### X.2 Straight-sided P2 mathematical audit

The retained object is exactly `delaunayTriangulation(points,constraints).ConnectivityList`, with
orientation/order changes only. Finite positive unique triangles, complete frozen-point use,
edge incidence, planar conformity, exact segmented outer boundary, total-area/containment,
complete frozen constraints and zero interface crossing jointly ensure a conforming fitted
triangulation of the frozen polygonal geometry. The centroid material rule then assigns one
piecewise-constant coefficient per element.

Unique global active edges provide one shared midpoint DOF per edge, so the six-node P2 traces
agree on every interior edge. The retained element interpolation, partition/gradient, degree-five
quadrature tests, P1 embedding/bilinear consistency, periodic vertex/midpoint and corner checks,
finite/raw-Hermitian assembly, mass SPD and seam checks are sufficient to detect a wrong P2
topology or phase reduction before eigensolve. This preserves the same weak form; it does not
claim curved-circle geometry or erase the existing segmentation error.

For exact implementation, the existing planar-edge validator must continue to reject a
nonadjacent endpoint touching another edge interior, in addition to proper crossings and positive-
length collinear overlap. This is a **`MINOR CAVEAT`** in the prose wording, not a blocker, because
the current source already implements that stricter conforming test and Section 31 retains the
existing checks.

### X.3 Sample-space parity audit

At $\vartheta=0,\pi$, paired removal of interface samples leaves a symmetric ordered grid with
positive material-weighted trapezoidal weights. The coordinate rule uniquely determines a
bijective involution $J$ and verifies weight pairing, so $J$ is unitary in the $W$ inner product.
For a complete sampled cluster $S$, $H=S^*WS$ positive definite and
$\widehat S=S\operatorname{chol}(H)^{-1}$ give $\widehat S^*W\widehat S=I$. Therefore

$$
A_R=\widehat S^*WJ\widehat S
$$

is the weighted compression of reflected samples, while

$$
d_R=\frac{\lVert J\widehat S-\widehat S A_R\rVert_W}
{\lVert\widehat S\rVert_W}
$$

measures failure of the sampled subspace to be reflection invariant. Ordering the eigenvalues of
$(A_R+A_R^*)/2$ makes the existing even/odd/mixed threshold rule deterministic for complex-valued
fields and multi-dimensional clusters. The exact row convention for $J$ and the pair-preserving
interface mask must be exposed in the theory-to-code map, but both are already uniquely specified
by Section 31; this is not an unresolved ambiguity.

The parity tuple position and penalties $0/1/2$ remain unchanged. Numerical labels may differ from
the abandoned mesh-permutation diagnostic, as expected for the empirical replacement, but parity
still cannot invalidate a field or reference candidate. Publishing $d_R$, pairing/normalization
status and `EMPIRICAL_COMMON_GRID_PARITY` prevents an empirical compression from being mistaken
for exact discrete or continuous symmetry. This is an **`IMPORTANT CAVEAT`** on interpretation,
not a blocker.

### X.4 Identity, isolation, resource and authorization

The only next preflight identity is absent create-once
`resource-preflight-002/execution-003`; executions 001--002 remain immutable and unread. The
absolute epoch `1788266751`, inclusive aggregate RSS limit `3221225472` B, zero-eigensolve
preflight schema and publication latch remain unchanged. There is no lower resource gate. The
continuous model, weak form, information isolation, branch graph, lexicographic rank fields,
uncertainty and claim boundary are not changed. Section 31 supersedes only mesh-reflection
acceptance and parity evaluation; its legacy schedule wording cannot alter the exact Section 23
61/66 call graph.

The same Engineer is authorized only to modify the active `run_i4_1b_core.m` mesh/parity paths,
mechanically switch `run_preflight_002.pl` to exact `execution-003`, and synchronize the minimal
README/SYMBOLS mapping. Exact triangle/edge/P2 reflection fields that no longer exist must be
removed or explicitly downgraded; the formal controller identity remains unchanged.

This PASS does **not** authorize MATLAB, `/usr/bin/perl ./run_preflight_002.pl`, output creation,
formal science, `eig`/`eigs`, another execution ID, a new attempt, historical-output reads,
reference publication or effectivity. Researcher theory-to-code and same-Skeptic exact
spec-to-code/resource review remain mandatory before any run.

## Y. Preflight spec-to-code/resource review of Sections 31--33

### Y.1 Audit frame and verdict

This review maps the original-connectivity and sample-parity revision to the current active core,
preflight controller and four-leaf publication contract. The only executable target considered is
one zero-eigensolve `resource-preflight-002/execution-003`.

**Verdict: `PASS`. Confidence: high.** The original mesh legality chain, parity error routing,
exact identity, resource predicates and publication latch match Sections 31--33. No unresolved
numerical, implementation, resource or publication blocker prevents the preflight.

### Y.2 Mesh and parity implementation audit

- `LOCAL_build_mesh` retains `dt.ConnectivityList` and passes it through
  `LOCAL_validate_original_connectivity`; no authority-side triangle deletion, insertion or
  reflection rewrite remains. The validator positively orients and deterministically orders the
  rows, then checks finite/positive/unique triangles, every frozen point, incidence one/two,
  crossings/touching/collinear overlap, exact segmented boundary, area/containment, every frozen
  constraint, finite material coefficients and zero fitted-interface crossing.
- The accepted triangles alone generate the shared-edge P2 topology. Nodal/partition/quadrature
  checks, P1-in-P2 bilinear identities, finite/raw-Hermitian assembly, periodic vertex/midpoint and
  corner maps, seam checks and fill-reduced mass SPD remain downstream hard checks. Mesh point and
  constraint reflection is now explicitly diagnostic; absence of a triangle/edge reflection
  permutation cannot cancel an otherwise legal P2 mesh.
- `LOCAL_sample_subspace` constructs the frozen symmetric grid and positive trapezoidal/material
  weights, performs pair-preserving interface removal and rebuilds the coordinate-defined
  bijective/involutive reflection permutation. `LOCAL_common_grid_parity` checks the weighted Gram,
  Hermitian defect, Cholesky normalization, reflected compression, Hermitian-compression values and
  weighted invariance defect before publication.
- The endpoint parity catch decodes the exception and downgrades only exact
  `PARITY_DIAGNOSTIC_UNAVAILABLE`. Every other indexing, shape, helper, source, resource or
  operational exception is rethrown through the outer fail-closed path. Available and unavailable
  objects publish the method, grid status, values/defect and reason consistently; parity retains
  its existing finite tuple penalty and never becomes a field-validity gate.

### Y.3 Identity, reachability, resources and artifacts

The MATLAB allowlist, no-argument controller constants and literal batch call agree exactly on
`resource-preflight-002/execution-003`; that namespace is absent. Executions 001--002 are present
only as immutable artifacts and are not read, loaded, hashed or copied by active MATLAB. No
Markdown, Git, BIE/QZ, estimator, prior reference or historical output read was found.

The preflight dispatch builds only the four named mesh/reduction/SPD representations and returns
before every source `eig`, `eigs`, `svd`, spectrum, field, branch, rank or reference path. It may
publish only `representation.tsv`, `run.log`, `resource.tsv` and summary-last
`preflight-summary.tsv`.

The controller arms one deadline from the remaining time to absolute epoch `1788266751`; aggregate
target-tree RSS `>=3221225472` B is the sole memory stop. There is no lower limit or reset. The
append-only resource ledger, abort latch, synchronized summary partial, fresh inclusive deadline
checks and atomic summary-last rename are unchanged. Complete four-mesh time/factor memory remain
an **`IMPORTANT CAVEAT`** to be measured by this preflight, not an execution blocker.

### Y.4 Exact authorization boundary

One and only one command is authorized, from
`/Users/whc/Documents/Work/epost/test/i4/femref-a2`:

`/usr/bin/perl ./run_preflight_002.pl`

It may create only the create-once `resource-preflight-002/execution-003`. Independent post-run
artifact/resource review is mandatory. This PASS does not authorize `run_formal_002.pl`, formal
science, `eig`/`eigs`, retry, another execution label, a new attempt, reference publication,
historical-output reads or effectivity comparison.

## Z. Post-preflight review of `resource-preflight-002/execution-003`

### Z.1 Audit frame and verdict

This review audits the completed create-once original-connectivity preflight. Acceptance requires
all four named P2 representations to pass mesh/reduction/SPD/release under the absolute resource
contract, with internally consistent summary-last artifacts and zero eigensolve/reference work.

**Verdict: `PASS WITH CONDITIONS`. Confidence: high.** The preflight completed its exact declared
scope with no artifact, mesh, implementation, resource or publication blocker. It supports a
formal pre-run theory-to-code/resource mapping, but it does not itself authorize or establish the
resource feasibility of formal eigensolves and retained fields.

### Z.2 Create-once artifacts and representation evidence

The execution contains exactly four authoritative leaves and no partial:
`representation.tsv`, `run.log`, `resource.tsv` and summary-last `preflight-summary.tsv`. Their
observed hashes are fixed review evidence; `execution-003` is consumed and must remain immutable.

`representation.tsv` records four successful
`original-constrained-delaunay/sample-grid-parity` rows:

| Mesh | $V$ | $T$ | $E$ | Full P2 DOF | Reduced DOF | $\operatorname{nnz}K$ | $\operatorname{nnz}M$ | Factor nnz |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `bulk-s9-g24` | 160 | 282 | 441 | 601 | 564 | 6,266 | 6,486 | 13,291 |
| `defect-N4-s12-g24` | 1,929 | 3,616 | 5,544 | 7,473 | 7,232 | 79,754 | 83,168 | 230,867 |
| `defect-N4-s9-g32` | 1,492 | 2,802 | 4,293 | 5,785 | 5,604 | 62,150 | 64,446 | 145,291 |
| `defect-N5-s9-g24` | 1,600 | 2,982 | 4,581 | 6,181 | 5,964 | 65,972 | 68,586 | 160,544 |

Every row has `permutation_valid=1`. `run.log` gives the ordered
`BUILD`--`REDUCE_K`--`REDUCE_M`--`SPD`--`RELEASED` sequence for each mesh, reports
`original-constrained-delaunay`, `sample-grid-parity` and
`GEOMETRY_REFLECTION_AVAILABLE`, and ends `PREFLIGHT_COMPLETE`. No failure, eigensolve, spectrum,
field, branch, reference or effectivity marker appears.

### Z.3 Resource and publication audit

The summary and last resource event agree exactly:

- controller `NATURAL_EXIT` and scientific terminal `PREFLIGHT_COMPLETE`;
- whole-command wall `15.572655` s;
- aggregate peak RSS `916848640` B;
- MATLAB exit code/signal `0/0`.

The peak is `2304376832` B below the inclusive `3221225472` B upper, and publication completed
before absolute epoch `1788266751`. The resource ledger is append-only, ordered through
`PUBLICATION_PENDING` and `WHOLE_COMMAND_TERMINAL`, and the final summary was committed last. The
three consumed `resource-preflight-002` runs total `43.325160` s of observed debugging/preflight
wall with maximum observed peak `916848640` B; the absolute lifecycle is not reset.

Several very short reduction/SPD stage rows have sampled peak `0`. This is an
**`IMPORTANT CAVEAT`** about stage attribution, not contradictory resource evidence: the 0.25 s
external monitor can miss a short stage, while the global aggregate peak and completed factor
`nnz` rows remain authoritative. No stage-local zero may be used as a formal-memory estimate.

### Z.4 Claim boundary and next gate

The successful preflight establishes that the four actual conforming fitted P2
representation/reduction/SPD objects fit the controller budget and that immediate factor release
works on those objects. It does not establish eigensolver workspace, 48/60-root spectra, retained
field/subspace memory, sample-parity values, a guided-mode reference, refinement, P1--P2 drift,
effectivity, certification or continuous existence.

No `BLOCKER` remains for the next static gate. The same Researcher is authorized to perform only a
formal pre-run theory-to-code/resource mapping. That mapping must reconcile the exact Section 23
61/66 schedule, actual DOF/nnz/factor evidence, live eigs/vector/field lifetimes, preliminary-first
publication, sample-parity error routing, conditional 48/60 authority, remaining absolute-time
margin, 3 GiB aggregate upper and create-once formal `run-002/execution-001` contract.

This verdict does **not** authorize source changes, `/usr/bin/perl ./run_formal_002.pl`, MATLAB,
formal `eig`/`eigs`, output creation, retry, another preflight ID, reference publication or
effectivity. The Researcher mapping and a same-Skeptic exact formal spec-to-code/resource review
must precede any formal-run decision.

## AA. Final formal spec-to-code/resource review of Sections 34--35

### AA.1 Audit frame and verdict

This review audits the exact prospective `run-002/execution-001` formal command against the
Section 34 theory-to-code/resource map and the Section 35 localization repair. Its success
criterion is narrower than a scientific result: the frozen P2 computation must be executable
once under its create-once and resource contract, preserve preliminary-first publication, and
fail closed on implementation or operational errors. No numerical execution is part of this
review.

**Verdict: `PASS`. Confidence: high.** No unresolved mathematical, implementation, resource or
publication blocker remains. The formal source implements the exact 61-call schedule with only
the frozen five-call 60-root extension, the diagnostic catches now distinguish intended
unavailability from source/shape/resource failures, and the controller enforces the only two
resource uppers through summary-last publication.

### AA.2 Scientific and error-routing audit

- `LOCAL_formal` initializes `planned_solves=61` and `maximum_solves=66`. Its reachable graph is
  the five anchor slices, six five-slice $h/g/N$ configurations, four added twists, five
  loose-tolerance slices and seventeen bulk phases. Only initial 48-root coverage insufficiency or
  absence of a preliminary branch launches the five frozen 60-root anchor solves.
- The fixed generalized calls use `smallestabs`, root counts $40/48/60$, subspace dimensions
  $80/96/100$, deterministic starts and the frozen tolerances. The 60-root result becomes active
  only after the ordered frequency, cluster/multiplicity and exact-mass subspace agreement checks;
  otherwise 48-root authority and partial coverage remain explicit.
- The preliminary winner is selected only from P2 FEM spectra and common-grid fields. Its scalar,
  complete selected subspaces, mesh and topology are atomically published before the refinement
  schedule. The five empirical components may remain partial without replacing that winner, and
  every published claim remains non-certified, without a continuous-existence or effectivity
  assertion.
- The repaired localization catch downgrades only exact
  `LOCALIZATION_DIAGNOSTIC_UNAVAILABLE`; every other exception is rethrown. The endpoint parity
  catch analogously downgrades only exact `PARITY_DIAGNOSTIC_UNAVAILABLE`. Neither code is in the
  general scientific-failure allowlist. Thus an index, dimension, helper, memory, source or
  operational failure cannot silently alter the localization/parity rank components.

### AA.3 Preflight, resource and publication evidence

The consumed `resource-preflight-002/execution-003` provides the required representation evidence:
all four meshes passed original constrained-Delaunay legality, sample-grid parity preparation,
quasiperiodic reduction and mass SPD. The largest observed object had 7,232 reduced DOFs,
$\operatorname{nnz}M=83{,}168$ and factor nnz $230{,}867$; the authoritative aggregate peak was
916,848,640 B. At the final static check, epoch `1788266751` retained 10,844 s, so even the 66-call
cap retained about 164 s per call on average. Sparse `eigs` workspace and retained-field cost were
not measured by the zero-eigensolve preflight, but the measured size and 2,304,376,832 B memory
headroom provide reasonable prospective evidence; this is an **`IMPORTANT CAVEAT`**, not a
demonstrated resource failure.

The no-argument controller fixes the literal MATLAB call and absent namespace
`run-002/execution-001`. It derives one monotonic deadline from the absolute epoch and uses only
inclusive aggregate target-tree RSS `>=3221225472` B as the memory stop; no lower limit, reserve,
forecast or stall gate is reachable. The alarm remains armed through resource-ledger and atomic
summary-last publication. Hard-stop or publication failure cannot create a READY summary;
previously committed preliminary leaves remain authoritative, while any `.partial` leaf remains
non-authoritative and the create-once execution is consumed.

### AA.4 Isolation, findings and authorization

The active MATLAB path creates and reads only its current execution tree. The controller reads
only the current `work/terminal.tsv`. No historical output, Markdown, Git, BIE/QZ field or density,
estimator, P1 target, existing reference or effectivity datum is an active input. The exact formal
namespace is absent, and `/usr/bin/perl -c run_formal_002.pl` passes.

The strongest remaining challenge is an unexpectedly large sparse-eigensolver or retained-field
working set. It is bounded operationally by the inclusive 3 GiB controller and does not make the
present launch uninterpretable. No `BLOCKER` and no additional `MINOR CAVEAT` were found. The one
`IMPORTANT CAVEAT` is the unmeasured formal `eigs`/field resource increment above the successful
representation preflight; the cheapest decisive evidence is the authorized create-once formal
run itself followed by independent artifact/resource review. No new open-problem entry is needed
before that gate.

One and only one command is authorized, from
`/Users/whc/Documents/Work/epost/test/i4/femref-a2`:

`/usr/bin/perl ./run_formal_002.pl`

It may create only `run-002/execution-001`. A same-Skeptic post-run artifact, resource, numerical
result and claim-boundary review is mandatory before any project-status synchronization. This
PASS does not authorize retry, another execution ID, a new attempt, historical-output reads,
reference promotion, P1 comparison or effectivity comparison.

## AB. Immediate post-run review of consumed `run-002/execution-001`

### AB.1 Audit frame and verdict

This review determines whether the consumed formal execution failed because of the frozen P2
method, resource budget or a bounded implementation defect, and whether its preliminary-first
artifacts remain truthful. It does not interpret the preliminary eigenpair or promote it to an
I4.1b reference.

**Verdict: `REVISE / BOUNDED ASSIGNMENT IMPLEMENTATION FAILURE`. Confidence: high.** The formal
execution is a consumed, immutable operational failure. It completed the preliminary five solves,
published both preliminary MAT leaves, completed all six five-slice $h/g/N$ configurations and
the four added-twist solves, then failed inside lexicographic assignment refinement. No evidence
implicates the P2 weak form, mesh representation, eigensolver validity gates or the 3 GiB/absolute-
deadline resource contract.

### AB.2 Artifact and resource evidence

The execution contains exactly six authoritative files and no `.partial` leaf:
`preliminary-result.mat`, `preliminary-fields.mat`, `run.log`, `resource.tsv`, summary-last
`run-summary.csv` and `work/terminal.tsv`. The log records `PRELIMINARY PUBLISHED` before the first
`P2-H0` stage. The two committed MATLAB v7.3 files are 2,166,760 B and 1,385,455 B respectively;
their observed hashes are fixed evidence for this consumed execution. Neither refinement MAT leaf
exists.

The log contains 39 completed solver dispatches in the frozen order: five preliminary solves,
$6\times5=30$ $h/g/N$ solves and four added-twist solves. It then records
`TRACKING_IMPLEMENTATION_FAILURE` at `LOCAL_twist_scalar`, before algebraic or bulk refinement.
The controller and terminal agree on `MATLAB_EXIT_NONZERO`, MATLAB exit/signal `1/0`, scientific
terminal `TRACKING_IMPLEMENTATION_FAILURE` and claim
`OPERATIONAL_OR_RESOURCE_FAILURE`. Whole-command wall was 206.490910 s and authoritative aggregate
peak RSS was 1,000,374,272 B, leaving 2,220,851,200 B below the inclusive 3,221,225,472 B upper.
Neither resource predicate fired.

The summary's `attempted_solves=5`, `completed_solves=5` is not the actual execution count. The
exception exits `LOCAL_refinement_schedule` before its updated value-copy `state` returns to
`LOCAL_formal`, so the outer terminal retains the preliminary 5/5 state. The stage-ordered log
decisively establishes the later 34 solves. This undercount is an **`IMPORTANT CAVEAT`** on the
failed-run ledger, but it does not make the failure cause ambiguous and must not be presented as a
five-solve execution. Likewise summary `lambda_pre=NaN` and `k_pre=NaN` describe the operational
terminal, not absence of the already committed preliminary winner.

### AB.3 Failure mechanism and classification

The full dummy-augmented assignment first obtains a finite optimum. During deterministic
row-by-row tie refinement, `LOCAL_lexicographic_assignment` tries each finite current edge and
calls `LOCAL_lexicographic_hungarian` on the remaining suffix. Some such trial edges need not admit
a perfect suffix matching. The current code converts that local infeasibility into
`TRACKING_IMPLEMENTATION_FAILURE` instead of rejecting only that trial and continuing to the next
column. The observed stack is exactly this path: suffix Hungarian reports “no finite completion”
from the candidate trial at source lines 2279/2374.

This is a **`BLOCKER`** to completing the current formal result, because refinement and its
terminal cannot be published. It is nevertheless a bounded assignment-controller defect: the
birth/death dummy construction, objective tuple, pure-P2 branch definition and preliminary
selection need not change. The decisive repair test is a frozen Hall-deficient suffix fixture in
which one finite trial has no completion but a later trial preserves the known global optimum;
the tie refinement must skip the former and reproduce the latter. Initial full-problem
infeasibility and loss of the previously computed optimum must remain fail-closed.

No P2 mathematical blocker and no resource blocker is established. The repeated MATLAB warning
that `issym` is ignored for explicit matrices is a **`MINOR CAVEAT`** only: it did not stop a solve,
and finite-spectrum, residual and mass-orthogonality checks remain the numerical authorities.

### AB.4 What survived and minimal next gate

The consumed execution demonstrates preliminary-first create-once publication and provides
immutable field-bearing preliminary artifacts, but those artifacts have not undergone numerical
post-review and are **not** a promoted reference, empirical resolution result, P1--P2 comparison
or effectivity validation. The continuous model, P2 discretization, scientific schedule,
information isolation, rank objective and claim boundary survive this failure.

Under `test/AGENTS.md`, an assignment implementation failure does not consume the `femref-a2`
scientific-method attempt, but `run-002/execution-001` itself is consumed and must never be
overwritten or reused. The same Researcher is authorized only to freeze:

1. the bounded suffix-infeasibility semantics and a decisive deterministic fixture, without
   changing assignment costs, branch criteria, ranking or any FEM object;
2. an exact unused create-once formal execution ID and the corresponding mechanical controller,
   MATLAB allowlist and documentation mapping; and
3. truthful treatment of the immutable 5/5 summary as a known failed-run undercount, without
   rewriting its artifacts.

The repair must return through same-Researcher theory-to-code and same-Skeptic exact pre-execution
review. This section authorizes no source edit, MATLAB, rerun, new output, reference promotion,
P1 comparison or effectivity comparison.

## AC. Focused design review of Section 36

### AC.1 Audit frame and verdict

This review reopens only the consumed execution-001 assignment blocker: whether the proposed
finite-edge perfect-matching precheck rejects exactly infeasible suffix trials while preserving
the frozen summed seven-tuple optimum, deterministic tie policy, fail-closed boundaries and
create-once resource lifecycle.

**Verdict: `PASS`. Confidence: high.** No unresolved numerical, implementation, resource or
publication blocker prevents bounded implementation. The Boolean precheck is a feasibility
predicate only; every feasible suffix still uses the original tuple-valued Hungarian solver and
the unchanged global-optimum equality test.

### AC.2 Objective, tie and fixture audit

For a fixed current row and column, a finite completion exists exactly when the suffix Boolean
graph, whose edges are the tuples finite in every component, has a perfect matching. Skipping a
trial that fails this test cannot remove a feasible assignment or change the minimum summed
seven-tuple. Conversely, the precheck does not select among feasible completions: a feasible
suffix is passed unchanged to `LOCAL_lexicographic_hungarian`, mapped back to the unchanged
available-column order, and retained only if its full original tuple equals the already computed
global optimum exactly.

The final smallest-current-column rule and the existing `exact_tie` meaning are therefore
preserved. Ascending row/column visitation makes the feasibility result reproducible but has no
scientific selection authority. The helper cannot alter an overlap, distance, birth/death cost,
object ID, branch, rank or field.

The proposed $3\times3$ fixture is decisive. Trial $(1,1)$ leaves rows $2,3$ both dependent on
column 3 and must be skipped; trial $(1,2)$ leaves the unique completion $(2,1),(3,3)$. Hence the
only full assignment is $(2,1,3)^T$, with no exact tie. This fixture distinguishes the intended
repair from both the observed false global failure and a greedy suffix choice, while the existing
crossing, birth/death and all-zero-tie fixtures retain their prior coverage.

### AC.3 Fail-closed, identity, resource and isolation audit

The initial full Hungarian call remains authoritative and fail closed. A Hungarian failure after
a proven finite perfect matching, loss of the frozen optimum, or absence of an optimum-preserving
trial still raises `TRACKING_IMPLEMENTATION_FAILURE`. Only a Boolean-proven infeasible candidate
trial is continued locally. These boundaries close the Section AB blocker without converting a
source or optimizer defect into a caveat.

The exact prospective identity `run-002/execution-002` is absent. Section 36 requires the MATLAB
allowlist, controller ID, literal batch call, collision target and minimal docs to change
together; consumed execution-001 remains immutable and is not read, copied, hashed or used as a
seed. Execution-002 must independently rebuild and solve the five-slice preliminary stage.

The absolute epoch remains `1788266751` and the only memory upper remains inclusive aggregate
MATLAB-tree RSS `3221225472` B. There is no reset, lower gate, reserve, forecast or stall rule.
The helper adds no eigensolve, artifact or retained FEM object; its finite matching work is bounded
by the existing assignment sizes. The 206.490910 s and 1,000,374,272 B execution-001 observations
remain historical evidence only.

### AC.4 Authorization boundary

No `BLOCKER`, `IMPORTANT CAVEAT` or new goal-relevant `MINOR CAVEAT` remains at this design gate.
The same Engineer is authorized only to implement the Section 36 suffix-feasibility helper and
fixture, mechanically switch the formal identity to exact `run-002/execution-002`, and synchronize
the minimal README/SYMBOLS mapping. The assignment costs, objective, tie rule, FEM formulation,
scientific schedule, publication schema and resource predicates must otherwise remain unchanged.

Researcher theory-to-code and same-Skeptic exact spec-to-code/resource review remain mandatory.
This PASS does not authorize `/usr/bin/perl ./run_formal_002.pl`, MATLAB, output creation, another
execution ID, retry, reference promotion, P1 comparison or effectivity comparison.

## AD. Exact pre-run review of the Section 36 implementation

### AD.1 Audit frame and verdict

This review maps Section 36 and the Researcher Section 37 audit to the active MATLAB core,
no-argument formal controller and exact prospective `run-002/execution-002` namespace. Acceptance
requires the bounded assignment repair to preserve the optimizer, all cross-file identities to
agree, execution-001 to remain immutable and unread, and the original resource/publication
contract to remain enforceable.

**Verdict: `PASS / PRE-EXECUTION`. Confidence: high.** No unresolved mathematical,
implementation, resource or publication blocker remains. The current source closes the observed
suffix failure without changing any assignment tuple, scientific object or run schedule.

### AD.2 Assignment implementation and fixture audit

`LOCAL_lexicographic_assignment` retains the initial full tuple-valued Hungarian call and frozen
global optimum. For each current edge it still requires all seven tuple components finite, forms
the exact suffix tensor, and sets the Boolean graph with
`all(isfinite(suffix_costs),3)`. A Hall-deficient graph skips only that trial. A graph with a
perfect matching is passed unchanged to the original Hungarian solver, mapped through the
unchanged available-column inventory and accepted only when the full original summed tuple equals
the frozen optimum exactly.

`LOCAL_has_perfect_matching` handles the empty graph as feasible, rejects nonsquare graphs, visits
rows and columns in ascending order and gives each augmenting search a fresh visited-column set.
`LOCAL_augment_finite_matching` changes an occupied-column assignment only after a successful
reroute. The initial full-problem failure, a Hungarian failure after proven suffix feasibility and
an empty optimum-preserving trial set all remain fail-closed as
`TRACKING_IMPLEMENTATION_FAILURE`.

The new $3\times3\times7$ fixture has finite all-zero tuples exactly at the five frozen edges and
requires assignment $(2,1,3)^T$ with `exact_tie=false`. It directly exercises the observed
infeasible-column-first path. Existing crossing, birth/death and all-zero exact-tie fixtures remain
present. No reachable code changes the seven-tuple objective, smallest-column policy, overlap,
branch identity, rank or FEM field.

### AD.3 Identity, resource, publication and isolation audit

The MATLAB allowlist, controller `EXECUTION_ID`, literal batch call and create-once collision leaf
all agree on `run-002/execution-002`; that namespace is absent. The consumed
`run-002/execution-001` tree remains present and immutable. Active MATLAB derives only its current
execution directory and has no load/read/hash/copy path to execution-001 or any historical output,
Markdown, Git, BIE/QZ datum, density, estimator or prior reference.

The controller retains the single absolute epoch `1788266751` and sole inclusive aggregate
MATLAB-tree RSS upper `3221225472` B. It has no lower limit, reserve, forecast or stall gate.
Process-tree monitoring, kill behavior, append-only resource ledger, preliminary-first MATLAB
publication, synchronized summary partial, repeated deadline checks and atomic summary-last rename
are unchanged. At static review the deadline retained 9,829 s; execution-001's 206.490910 s wall
and 1,000,374,272 B peak remain prospective evidence, not an input or reset. The matching helper
adds no eigensolve or retained FEM object. `/usr/bin/perl -c run_formal_002.pl` passes, and the
reviewed source/doc diff passes `git diff --check`.

### AD.4 Findings and exact authorization

No `BLOCKER` or new goal-relevant caveat was found. The known execution-001 5/5 terminal-state
undercount remains confined to that immutable failed-run review and is not copied into the new
execution. Any execution-002 scientific, resource, operational or publication terminal consumes
that new identity and requires independent post-run interpretation.

One and only one command is authorized, from
`/Users/whc/Documents/Work/epost/test/i4/femref-a2`:

`/usr/bin/perl ./run_formal_002.pl`

It may create only `run-002/execution-002`. Same-Skeptic post-run artifact, resource, numerical
result and claim-boundary review is mandatory. This PASS does not authorize automatic retry,
another execution ID, a new attempt, execution-001 reads, reference promotion, P1 comparison or
effectivity comparison.

## AE. Final post-run review of `run-002/execution-002`

### AE.1 Audit frame and verdict

This review audits the consumed formal execution's canonical artifacts, numerical field identity,
five-axis empirical resolution, bulk diagnostic, resources and claim boundary. Read-only MATLAB
inspection loaded only the four current execution-002 MAT leaves; it performed no `eig`/`eigs`,
wrote no experiment output and read no execution-001, BIE/QZ, density or estimator artifact.

**Verdict: `PASS WITH CONDITIONS`. Confidence: high.** The frozen P2 formal run completed all
61 planned solves, produced a coherent simple field track and all five finite empirical resolution
components, and committed internally consistent preliminary/refinement artifacts under budget.
It supports the declared **non-certified empirical P2 reference candidate**. It does not certify
the reference error, a continuous bulk gap, guided-mode existence or effectivity.

### AE.2 Canonical artifacts, terminal and resources

The create-once execution contains exactly eight authoritative files and no `.partial` leaf:
four MATLAB v7.3 result/field files, `run.log`, `resource.tsv`, summary-last `run-summary.csv` and
`work/terminal.tsv`. The log records preliminary publication before every refinement stage, then
all six $h/g/N$ configurations, four added twists, five loose-tolerance solves and seventeen bulk
solves before the final scientific terminal. All eight files were hashed successfully before and
after read-only inspection without displaying hash values in project documentation.

Summary, terminal, log and final resource event agree on:

- controller `NATURAL_EXIT`, MATLAB exit/signal `0/0`;
- scientific terminal `P2_EMPIRICAL_REFERENCE_REFINEMENT_COMPLETE`;
- attempted/completed/planned solves $61/61/61$ and no recorded failure;
- $\lambda_{\mathrm{pre}}=3.3672400220423246$ and
  $k_{\mathrm{pre}}=1.8350040931949783$;
- whole-command wall 232.450046 s and aggregate peak RSS 1,055,391,744 B.

The run stayed 2,165,833,728 B below the inclusive 3 GiB upper and well before the absolute
deadline. Four successful reviewer-side read-only loads plus one sandbox-denied startup added
46.36 s; their maximum RSS was 762,691,584 B. Even under the conservative shared accounting, the
observed wall is 278.810046 s and the overall peak remains the formal run's 1,055,391,744 B. No
resource, publication or artifact-integrity blocker is present. `run-002/execution-002` is consumed
and no retry is justified by these artifacts.

### AE.3 Anchor, spectrum authority and field identity

The stored continuous/discrete parameters remain the frozen values: period $1$, radius $0.2$,
material coefficients $17/1$, missing column $0$, $\beta=0.5$, $W_3=[0.45,3.25]$ and the
five twists from $0$ to $\pi$. The anchor straight-sided fitted P2 mesh has
$V/T/E=1300/2418/3717$, 5,017 full P2 DOFs and 4,836 quasiperiodically reduced DOFs. Its domain is
$[-4.5,4.5]\times[-0.5,0.5]$. All five stored phase reductions have unit-modulus phases, valid SPD
permutations, factor nnz 129,192 and seam residual at most $1.241\times10^{-16}$.

The pure-P2 winner is the ordered object track
`[8,32,55,78,101]`: simple cluster/root 9 at each of the five twists. Its frequency envelopes run
from 1.8349700143886414 to 1.8350381713684318. The four consecutive common-grid overlaps are at
least 0.99999991258811038; the selected-field file contains exactly those five IDs. Every selected
subspace and common-grid sample matrix is finite, has one column, and the reviewed weighted sample
Gram defect is at most $2.220\times10^{-16}$.

Selected relative residuals are at most $1.1334890039602699\times10^{-16}$. Localization is
available at all twists, with minimum core mass 0.9643879792938318 and maximum tail mass
0.0030448880137896625. Endpoint parity is empirically even, with compression values approximately
0.9999998701 and invariance defects at most $5.0971621916615919\times10^{-4}$; non-endpoint parity
is explicitly unavailable by design rather than falsely inferred.

Every anchor spectrum used `roots-48`, solver flag zero and coverage
`SPECTRUM_COVERED_THROUGH_W3`; the 48th frequencies are about 4.582 and exceed the $W_3$ ceiling,
so no conditional 60-root expansion was triggered. Spectrum residual maxima are below
$9.04\times10^{-16}$ and mass-orthogonality defects below $5.46\times10^{-15}$. The result contains
117 field objects, 24 tracking components and 187 assignment edges before the frozen rank selects
the stated track. This is field-based identity evidence, not nearest-BIE-root selection.

### AE.4 Refinement, empirical uncertainty and bulk evidence

All eight matched field groups are present: six $h/g/N$ configurations, the four added twists and
the loose-tolerance configuration. Their selected branches remain simple and residual-valid. The
stored scalar ladder is:

| Axis | Observed scalar values | Frozen component |
|---|---|---:|
| $h$ | 1.8350761183951534, 1.8350040931949783, 1.8349657172908562 | $7.2025200175129811\times10^{-5}$ |
| geometry $g$ | 1.8377156248713638, 1.8350040931949783, 1.8340556021949563 | $2.7115316763854924\times10^{-3}$ |
| supercell $N$ | 1.835003780801864, 1.8350040931949783, 1.8350040962481873 | $3.1239311426567440\times10^{-7}$ |
| added twists | 1.8350040931949783 versus anchor | $0$ |
| algebraic tolerance | 1.8350040931949783 versus anchor | $0$ |

All five `finite_components` flags are true, and the stored sum is

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}=0.0027838692696748879.
$$

The zero twist/tolerance components mean only that the frozen scalar did not change at binary64
precision under those variations. The geometry component dominates and remains an empirical
resolution limitation; “complete” means all five frozen components were observed, not that an
asymptotic regime or upper bound was established.

All seventeen bulk phases are valid with forty frequencies each and no failure code. At the
sampled phases, the maximum lower bulk root is 1.3144106549969781 and the minimum upper root is
2.4150743324660522, so the selected $k_{\mathrm{pre}}$ lies in the observed sampled interval at
every phase. This supports the field classification, but finite phase sampling and discretization
do not establish a certified continuous bulk gap.

### AE.5 Findings, claim boundary and allowed handoff

No `BLOCKER` was found.

1. **`IMPORTANT CAVEAT` -- empirical, geometry-dominated resolution.**
   $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ is a finite-component diagnostic dominated by $g$; it
   is not a certified $\varepsilon_{\mathrm{ref}}$ and must accompany every downstream comparison.
2. **`IMPORTANT CAVEAT` -- sampled bulk evidence only.** The seventeen-phase bracket and strong
   localization do not prove a continuous gap or eigenvalue existence.
3. **`MINOR CAVEAT` -- deterministic assignment ties.** The selected real edges carry the frozen
   exact-tie flag, although the simple root-9 track has near-unit field overlaps. The object-ID
   policy makes publication deterministic but does not assert uniqueness of the full
   dummy-augmented assignment.
4. **`MINOR CAVEAT` -- solver-option warning.** MATLAB ignored `issym` for explicit matrices on all
   61 calls; zero flags and the independent residual, orthogonality, Hermitian and SPD checks are
   the numerical authorities.

The artifact claim strings correctly remain
`NONCERTIFIED / NO CONTINUOUS EXISTENCE CLAIM / NO EFFECTIVITY`. Minimal status/I4/test-document
synchronization may record the exact terminal, scalar, five components, bulk sampled evidence and
these caveats. It may call the result an empirical P2 reference candidate with complete frozen
resolution axes. It may not call $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ an error bound, claim
certified existence/gap, perform or report effectivity, or overwrite either formal execution.
