<!-- Post-experiment Researcher analysis of the Root-readiness controlled diagnostic -->

# Root-readiness controlled diagnostic result

> **Reader precedence:** Section I is the current provenance-closure result. The
> `STALE` passport and `REVISE-BLOCKED` verdict below apply to the earlier controlled
> diagnostic retained in Sections A--H; Section I has its own current passport, evidence
> lock, and claim boundary.

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: post-experiment-analysis
- Origin Date: 2026-08-07
- Verification Status: STALE
- Review Status: SKEPTIC DELTA REVIEW PASS FOR EVIDENCE SEMANTICS /
  ROOT READINESS REVISE-BLOCKED
- Staleness Note: the two authoritative runs reproduced each other, but the frozen design
  later received a post-experiment status-only note; the current design hash therefore no
  longer equals the run manifest. Numerical evidence and frozen gates were not changed.
- Version Label: eig-apost-root-result-v1.1-delta-final
- Repro Lock: unchanged-source rerun reported relative numeric difference `0` at tolerance
  `1e-13`, identical direct-call source manifests, and identical projector fingerprints
- Git Base: `d699ae9ffa2d9f9a23c0d1cdd58fffc00357162b`
- Design Authority:
  [[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness|Root-readiness design]]
- Pre-implementation Review:
  [[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness_review|Root-readiness review]]
- Downstream Theory:
  [[research/projects/eig-apost/phase3-analysis/s-root|Root qualification]] and
  [[research/projects/eig-apost/phase3-analysis/s-estimator|Candidate estimator]]

## A. Context and question

The controlled experiment asks only whether the current proxy construction admits a
fixed, source-aware numerical representation that can later support a complex-$k$
augmented-BIE evaluator. Its frozen success conditions include exact production-path
reproduction, common matrix and residual inputs, a hard $10^{-5}$ downstream object
compatibility gate, independent off-collocation evidence, and an unchanged-source repeat.

The authoritative numerical materials are the corrective rerun artifacts under
`test/root-ready/output/`, especially `gate.csv`, `solver-comparison.csv`,
`off-collocation.csv`, `resolution.csv`, `downstream-mismatch.csv`,
`projector-fingerprint.csv`, `report.md`, and `reproducibility.txt`. Interpretation also
uses
`test/root-ready/root_ready_diagnostic.m` and `+kernel/precomp_proxy.m` to determine what
was actually compared.

Excluded from this analysis are all discarded interactive pilot values. The experiment
did not run a candidate scan, complex disk, Cauchy--Riemann test, contour count, bordered
Newton solve, eigenvalue computation, adjacent-level correction, or estimator. It
therefore cannot establish a guided eigenvalue or its error.

## B. Result at a glance

**Decision: `REVISE` for the controlled diagnostic; `STOP` for entry into root search.**

The evidence bundle completed and reproduced exactly. The corrective implementation now
enforces the frozen $10^{-5}$ object-compatibility gate: all 78 downstream/object rows and
all 3 resolution rows pass, with aggregate maximum $1.898508\times10^{-9}$. However, the
diagnostic still does **not** meet all frozen expected outcomes. Three $10^{-11}$
mirrored-constructor output gates fail, and the production helper's actual internal
$A_{\mathrm{pr}},b_{\mathrm{pr}}$ remain
`NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. Hence root readiness is
`BLOCKED_UPSTREAM_PROVENANCE`, sampled-discrete GO remains `0`, and physical root
readiness remains `STOP`.

This is not evidence that the proxy-generated field is unusable. The field, refined-grid,
and downstream differences are small. They instead show that coefficient identity,
observable compatibility, and provenance are different questions and must not be merged
into a single “exact constructor” claim.

## C. Findings

### C.1 Structural constructor agreement is not captured constructor identity

**BLOCKED.** The test-local `LOCAL_build_proxy_system` follows the same visible assembly
recipe as `kernel.precomp_proxy`, and the source-provenance gate passes. However,
`kernel.precomp_proxy` returns only the solved proxy data. The diagnostic independently
rebuilds $A_{\mathrm{pr}},b_{\mathrm{pr}}$ and compares the resulting `pinv(A)*b` output
with the production coefficients; it does not instrument or serialize the exact matrix
and right-hand side consumed inside the production call.

Therefore the following are distinct:

1. **ESTABLISHED:** source hashes were recorded, and the test-local recipe visibly mirrors
   the production source at the inspected revision;
2. **REFUTED at the frozen tolerance:** output coefficients, sampled proxy fields, and
   common residuals did not agree within $10^{-11}$;
3. **BLOCKED:** bytewise or entrywise identity of the production-consumed and
   test-reconstructed $A_{\mathrm{pr}},b_{\mathrm{pr}}$ was not measured.

The corrective implementation now names these quantities accurately: internal identity
is an unavailable gate, while coefficient, proxy-field, and residual comparisons are
separate `mirrored_constructor_*_output_reproduction` gates. None is a direct
$A_{\mathrm{pr}},b_{\mathrm{pr}}$ identity norm.

### C.2 Coefficient representation is numerically unstable relative to field observables

**ESTABLISHED for these sampled systems.** The maximum default-`pinv` coefficient
difference from production is $2.798540\times10^{-7}$, exceeding the frozen
$10^{-11}$ gate. The corresponding maximum sampled proxy-field difference is only
$5.531552\times10^{-10}$, though it also exceeds that gate. The maximum common-residual
difference is $1.250388\times10^{-9}$ and likewise fails.

The seed-frozen ratio-rank chart makes the separation even clearer. At base resolution,
its coefficient difference from production is about $0.936$; at refined resolution it is
about $0.995$. Nevertheless its sampled proxy-field difference stays below
$1.972\times10^{-10}$ in the refined rows and below $3.490\times10^{-11}$ in the base
rows. This behavior is consistent with large coefficient motion in weakly observable
singular directions, but the present experiment does not prove a nullspace quotient or
continuous kernel--field equivalence.

Thus coefficient equality is neither observed nor presently justified as a surrogate for
field equality. Conversely, small sampled field differences cannot establish that all
downstream fields agree on the physical domain.

### C.3 Frozen field, resolution, and downstream compatibility gate passes

**ESTABLISHED for the frozen sampled objects.** The ratio-rank chart has maximum full
collocation residual
$3.261485\times10^{-8}$ and maximum shifted, densified off-collocation residual
$5.911454\times10^{-8}$ at base resolution. At refined resolution, the selected
off-collocation residual lies between $8.708215\times10^{-9}$ and
$9.492662\times10^{-9}$.

All 3 resolution rows pass the frozen $10^{-5}$ object gate. Base-to-refined sampled Green
differences have maxima
$1.898508\times10^{-9}$ for potential, $4.200301\times10^{-10}$ for gradient, and
$9.447412\times10^{-12}$ for Hessian. Production-to-ratio-rank downstream differences
are at most $1.670932\times10^{-9}$ across the 78 tested proxy Green,
defect/bulk $A_{\mathrm{QP}}$, and scattering rows. Every one of those 78 rows is `PASS`.
The associated BIE solves report reciprocal condition estimates between approximately
$0.248$ and $0.365$ and residuals below $7\times10^{-16}$. The combined resolution and
downstream aggregate is $1.898508\times10^{-9}$, so
`object_compatibility_resolution`, `object_compatibility_downstream`, and
`object_compatibility_all` all pass.

This establishes compatibility only for the frozen real frequencies, finite probes,
base/refined discretizations, and named downstream objects. Off-collocation readiness
still has no frozen threshold and remains `PENDING_REVIEW`; the pass does not extend to a
complex search disk or continuous kernel--field equivalence.

### C.4 Reproducibility includes the frozen projectors

**ESTABLISHED within the recorded scope.** The corrective unchanged-source rerun has
relative numeric difference `0`, direct-call source-manifest equality, and
`projector_fingerprints_equal=1`. The base rank-126 left/right projector hashes are
`10e9b38c...dfa97df1` and `6d97a495...149b3d2`; the refined rank-144 hashes are
`fa88c445...84167d` and `59358366...573f94`. This closes deterministic reproduction of
the selected reduced subspaces in the current Octave workflow.

The manifest scope is explicitly `DIRECT_PROJECT_CALLS_ONLY`. It covers the diagnostic,
wrapper, design, and listed directly called project helpers, including
`+geom/construct_cont.m`; it does not reliably enumerate transitive dependencies.
Projector hash reproduction and direct-manifest equality therefore strengthen local
reproducibility but do not prove environment-wide or MATLAB parity.

### C.5 Historical deviation corrected; production-system provenance remains open

1. **Historical design deviation — `CORRECTED`.** The first implementation demoted the
   frozen $10^{-5}$ object gate to `PREVIOUS_PROPOSAL_NOT_AUTHORITY`. That historical
   finding remains part of the audit trail and must not be rewritten as an earlier pass.
   The corrective implementation restores the reviewed threshold, emits individual rows,
   and obtains 78/78 downstream/object passes plus 3/3 resolution passes. The current gate
   result is therefore valid for the corrective rerun, not retroactive evidence for the
   superseded run.
2. **Production-consumed system not captured — `BLOCKED`.** The design requires proof
   that every solver consumes a byte- or entrywise identical
   $A_{\mathrm{pr}},b_{\mathrm{pr}}$. The diagnostic compares a local reconstruction with
   production outputs but never obtains production's internal matrix and right-hand side.
   Output agreement cannot substitute for this provenance requirement, especially when
   the output agreement gates fail.

The corrective status `BLOCKED_MIRRORED_CONSTRUCTOR_OUTPUT_REPRODUCTION` and the explicit
`NOT_OBSERVABLE_WITH_CURRENT_INTERFACE` gate now expose this boundary. The durable
decision nevertheless remains `REVISE`, not GO.

## D. Frozen expected outcomes

| Expected outcome | Evidence | Status |
|---|---:|---|
| Complete controlled evidence bundle | All listed CSV/MAT/log/report outputs present | `ESTABLISHED` |
| Unchanged-source repeat | Relative numeric difference $0$; direct manifest and projector fingerprints equal | `ESTABLISHED` |
| Production coefficient reproduction within $10^{-11}$ | $2.798540\times10^{-7}$ | `REFUTED` |
| Production sampled-field reproduction within $10^{-11}$ | $5.531552\times10^{-10}$ | `REFUTED` |
| Common-residual identity within $10^{-11}$ | $1.250388\times10^{-9}$ | `REFUTED` |
| Direct identity of production-consumed $A_{\mathrm{pr}},b_{\mathrm{pr}}$ | `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE` | `BLOCKED` |
| Frozen $10^{-5}$ downstream/object rows | 78/78 pass; maximum $1.670932\times10^{-9}$ | `ESTABLISHED` |
| Frozen $10^{-5}$ resolution rows | 3/3 pass; maximum $1.898508\times10^{-9}$ | `ESTABLISHED` |
| Aggregate frozen object compatibility | Maximum $1.898508\times10^{-9}$ | `ESTABLISHED / PASS` |
| Off-collocation readiness | Recorded; threshold remains undefined | `PROVISIONAL` |
| Root-readiness domain, analyticity, and pole gates | Not run | `NOT EVALUATED` |

The controlled diagnostic therefore closes the frozen sampled-object gate but still fails
the complete acceptance gate because internal constructor identity is unavailable and all
three $10^{-11}$ observable output-reproduction gates fail.

## E. Falsification and surviving hypothesis

The corrective data falsify the claim that independently reconstructed
production-equivalent solves
reproduce production coefficients, sampled fields, and residuals to $10^{-11}$. They do
not falsify the weaker hypothesis that a canonical proxy chart can preserve the physical
field and downstream augmented-BIE action to the frozen $10^{-5}$ tolerance. For the 81
frozen object rows, that weaker hypothesis now passes.

The strongest competing explanations are:

1. the independently assembled system is not entrywise identical to the production
   system;
2. it is identical, but `pinv`/SVD behavior in nearly discarded singular directions
   produces solver-path-dependent coefficients;
3. the sampled field vector and downstream blocks do not probe a harmful coefficient
   direction;
4. the current base/refined agreement is local to $k=0.095,0.100,0.105$ and need not
   persist on a complex search disk.

Explanations 1 and 2 cannot be separated without capturing the production-consumed
$A_{\mathrm{pr}},b_{\mathrm{pr}}$. Explanation 3 requires broader field/operator probes,
and explanation 4 requires the still-dormant analytic-disk experiment. What survives is
only the **PROVISIONAL** representation-invariant hypothesis, not root readiness.

## F. Smallest next experiment

The smallest useful next gate is an **instrumented constructor-identity and
output-reproduction rerun**, not a root scan.

1. With explicit authorization for a non-behavior-changing production diagnostic
   interface, expose or serialize the exact $A_{\mathrm{pr}},b_{\mathrm{pr}}$, solver path,
   tolerance, and rank used inside `kernel.precomp_proxy`. Preserve the existing one-output
   interface and numerical behavior.
2. Feed those captured arrays, rather than a second constructor, to every comparison
   solver and residual calculation. Record entrywise hashes and relative matrix/right-hand
   side differences.
3. Retain the now-correct $10^{-5}$ object gate unchanged and preserve the rank-126/144
   projector fingerprints as part of the reproducibility lock.
4. Re-run the same three real frequencies and the unchanged-source reproduction. Diagnose
   coefficient differences by singular-direction projection, while retaining field and
   downstream comparisons as separate gates.
5. Obtain the mandatory post-result Skeptic verdict before activating any complex-disk or
   root code.

Without authorization to expose the production arrays, a test-local cloned constructor
can provide more diagnostics but cannot close the byte-consumption provenance gap. In
that case root search should remain stopped.

## G. Distance to a genuine two-dimensional example

From the present `REVISE` state, the best estimate is **five major experimental stages**
to a credible real-case eigenvalue plus an empirical a posteriori estimator. This count
is a planning estimate, not a mathematical guarantee.

| Remaining stage | Required result | What becomes available |
|---|---|---|
| 1. Proxy provenance closure | Captured common system and reconciliation of the three failed output gates; retain the already passed frozen object gate and projector lock | A defensible proxy chart; no root yet |
| 2. Full analytic root-readiness | Anchored branches, fixed-dimensional full $F_{j,h}(k)$, locator, disk/CR, pole and factor ledger, sensitivity and mutation gates | Authorization for root isolation |
| 3. Real root isolation | Real-axis screening only as locator, count-one complex contour, bordered Newton, simple-root qualification and adjacent-level matching | First qualified discrete eigenvalue candidate for the actual double-ellipse model |
| 4. Empirical correction | Matched $k_{j,h}$ sequence, stable derivative, projected map correction, next-level shift consistency and effectivity against $k_{\infty,h}^{\mathrm{ref}}$ | Conditional/empirical tail estimator |
| 5. Real-case validation | Independent proxy/BIE/port refinement, resolved half-guide reference, independent benchmark where feasible, MATLAB parity, and representative modes | Credible genuine two-dimensional eigenvalue-and-estimator case study |

The five-stage estimate is unchanged: the corrective rerun closed part of Stage 1 but not
its decisive production-system provenance requirement. The earliest qualified
**discrete** root could therefore appear after about three more
stages. A defensible statement about a real two-dimensional line-defect eigenvalue and an
empirical estimator requires all five, because a root of one fixed experimental
discretization is not yet independent reference truth.

Certification is separate. Beyond the empirical program, at least three major
theory/validation gates remain:

1. continuous center-BIE kernel--field equivalence, injectivity, and a pole-free analytic
   neighborhood;
2. a justified half-guide map convergence/saturation constant and a computable correction
   remainder;
3. validated control of root solve, matrix evaluation, spatial/port discretization, and
   reference uncertainty sufficient for a reliable interval.

These gates include proofs and validated numerics, not merely additional smoke tests.
Passing the five empirical stages would still justify only a `conditional/empirical`
estimator until the certification gates close.

## H. Review handoff

1. **Claim:** the controlled bundle completed and reproduced unchanged-source outputs.
   **Status:** `ESTABLISHED`. **Weakest step:** reproduction is internal to the Octave
   workflow, the manifest covers direct project calls only, and there is no MATLAB parity.
2. **Claim:** the frozen diagnostic acceptance conditions were not met.
   **Status:** `ESTABLISHED`. **Weakest step:** none for the three recorded output-gate
   failures; internal $A_{\mathrm{pr}},b_{\mathrm{pr}}$ identity is unavailable rather
   than observed to fail.
3. **Claim:** coefficient variation is much larger than sampled field and downstream
   variation. **Status:** `ESTABLISHED` on the sampled systems only. **Weakest step:** the
   field probes are finite and may miss harmful directions.
4. **Claim:** the frozen object-compatibility gate passes 81/81 rows.
   **Status:** `ESTABLISHED`. **Weakest step:** it covers three real frequencies and does
   not test a complex disk or continuous equivalence.
5. **Claim:** a representation-invariant proxy chart remains viable.
   **Status:** `PROVISIONAL`. **Weakest step:** no continuous quotient/injectivity result
   and no complex-disk evidence. If this fails, downgrade to proxy-chart `STOP` and revisit
   the Green representation before augmented-BIE root work.
6. **Claim:** five further empirical stages are a reasonable distance estimate.
   **Status:** `PROVISIONAL RECOMMENDATION`. **Weakest step:** stages 2--4 may split if
   branch, pole, or root-matching failures require separate repairs.

The smallest reviewer decision is whether the proposed instrumented capture truly closes
the production-system provenance gap and explains or resolves the three failed observable
output gates. The $10^{-5}$ gate is now correctly reinstated and passed, but it cannot
override those blockers. The correct action boundary remains `REVISE / ROOT SEARCH STOP`.

## I. Provenance-closure post-experiment update

### I.1 Update passport and authority

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: validate / post-experiment analysis
- Origin Date: 2026-08-07
- Verification Status: ANALYZED — RESEARCHER OPERATIONAL-PROVENANCE PASS /
  INDEPENDENT SKEPTIC REVIEW PENDING
- Version Label: eig-apost-provenance-closure-result-v1.1
- Frozen Design:
  [[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness|Root-readiness design]],
  specifically the `eig-apost-provenance-closure-v1.1` addendum
- Symbol Authority:
  [[research/projects/eig-apost/implementation/SYMBOL|Symbol and code-variable ledger]]
- Evidence Root: `test/root-ready/provenance-closure/output/`

Sections A--H above are retained as the historical analysis of the earlier mirrored-
constructor diagnostic. They are not rewritten as passes. This section analyzes the new
source-exact-copy baseline/repeat bundle and is the current Researcher result for the
operational provenance question only.

### I.2 Question, exclusions, and method

The provenance-closure experiment asks whether a test-local copy of the frozen
`kernel.precomp_proxy` executable body can expose its already existing local arrays
$A_{\mathrm{pr}}^{\mathrm{copy}}(k)$ and
$b_{\mathrm{pr}}^{\mathrm{copy}}(k)$, reproduce the unmodified package public output in
the same process, and make those returned arrays the single shared input to all five
comparison solvers. It does **not** ask whether the unmodified production call exposes
its internal arrays.

The analysis compared the published baseline and repeat artifacts against the frozen
v1.1 gates. It checked completion-marker hashes, exact row coverage, the direct-call
manifest, source/body hashes, shared-array fingerprints, solver outputs, sampled object
compatibility, the synthetic negative, and unchanged-source reproduction. No numerical
experiment was rerun during this analysis.

As required by the frozen design, the experiment excludes a complex-$k$ chart, branch
continuation, candidate disk, Cauchy--Riemann test, contour count, Newton iteration,
root/eigenvalue, adjacent-level correction, estimator, and effectivity calculation.

### I.3 Numerical evidence

| Evidence item | Observation | Status |
|---|---:|---|
| Transactional artifacts | baseline marker covers 13 non-marker artifacts; repeat marker covers 27; all recorded SHA-256 values independently match the published files | `ESTABLISHED` |
| Runtime | baseline $6.4742$ s; repeat $6.6299$ s; frozen limit $3600$ s | `PASS` |
| Package source lock | `3a168250...2f9a60` | `PASS` |
| Source-exact executable body | package/copy body hash `eb116bc9...bd82c`; raw body-byte equality `1` | `PASS` |
| Source-copy controls | context-independence, copy-structure, and synthetic mutation rejection all equal `1` | `PASS` |
| Direct-call manifest | exactly 11 expected names, 11 valid recorded source hashes, and exact set equality | `PASS` |
| Shared-system coverage | 6 constructor rows, 5 exact solver labels per row, 30 solver rows total; one $A$ and one $b$ fingerprint per group | `PASS` |
| Package/copy public output | bitwise equality at all six base/refined-frequency systems | `PASS` |
| Copy coefficient extraction | bitwise equality between returned `coeffs` and flattened copied proxy output | `PASS` |
| Three copied-output reproduction gates | maximum coefficient, proxy-field, and common-residual differences are all exactly $0$ | `PASS` |
| Ratio-chart ranks | base/refined ranks $126/144$, reproduced projector fingerprints | `PASS` |
| Resolution compatibility | maximum $1.898507\times10^{-9}<10^{-5}$; 3/3 rows pass | `PASS` |
| Downstream compatibility | maximum $1.670931\times10^{-9}<10^{-5}$; 78/78 rows pass | `PASS` |
| Selected ratio-chart off-collocation diagnostic | maximum recorded gate value $5.911454\times10^{-8}$; no frozen pass threshold | `PENDING_REVIEW / NON-GATING` |
| Unchanged-source repeat | relative numeric difference $0<10^{-13}$; manifests, source/body records, shared fingerprints, and current projector fingerprints agree | `REPRODUCED` |
| Historical projectors | ranks and dimensions agree, but left/right projectors differ by about $10^{-10}$; declared non-gating | `DIFFERENT / NON-GATING` |
| Production-internal system identity | not returned by the unmodified interface | `NOT_DIRECTLY_OBSERVED` |

The baseline correctly records `PENDING_REPEAT` and an operational blocked label because
the repeat did not yet exist. The repeat then records
`SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS`, `FINAL_COMPLETE_PASS`, and a reproduced
bundle. This baseline-to-repeat state change is required by the two-run protocol; it is
not numerical disagreement.

### I.4 Mathematical claim boundary

**ESTABLISHED:** `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS` is supported for the frozen
source, inputs, and recorded Octave process. It means precisely that:

1. the copied executable arithmetic has the frozen raw body bytes;
2. the unmodified package and copied implementation return bitwise-equal public proxy
   data at the six sampled systems;
3. all comparison solvers consume one copy-returned pair
   $A_{\mathrm{pr}}^{\mathrm{copy}},b_{\mathrm{pr}}^{\mathrm{copy}}$ per system, with
   reproduced raw-array fingerprints; and
4. the sampled resolution and downstream objects satisfy the unchanged $10^{-5}$ gate.

**ESTABLISHED UNAVAILABLE:**
`production_internal_A_b_identity=NOT_DIRECTLY_OBSERVED`, with reason
`NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. Source-exact copied arithmetic and bitwise
public-output equality do not turn the copy-returned arrays into direct observations of
the arrays consumed inside the unmodified package call. In particular, this result must
not be restated as
$A_{\mathrm{pr}}^{\mathrm{copy}}=A_{\mathrm{pr}}^{\mathrm{production}}$ or
$b_{\mathrm{pr}}^{\mathrm{copy}}=b_{\mathrm{pr}}^{\mathrm{production}}$ by measurement.

**NOT ESTABLISHED:** three real frequencies do not imply a holomorphic complex-$k$
family, a pole-free disk, continuous kernel--field equivalence, representation
injectivity, or absence of spurious roots. No root, guided eigenvalue, error correction,
estimator, effectivity index, reliable interval, or certification claim follows from
this pass.

### I.5 Operational blocker decision

**CONDITIONAL GO TO THE NEXT DESIGN GATE.** The new evidence resolves the narrower
**operational source-derived shared-system provenance blocker** that the v1.1 addendum
was designed to test. It does not resolve, and does not claim to resolve, the unavailable
production-internal identity question.

The published files intentionally retain
`ROOT_READINESS=BLOCKED_UPSTREAM_PROVENANCE`,
`ROOT_READINESS_SAMPLED_DISCRETE_GO=0`, and `PHYSICAL_ROOT_READY=STOP`, because the
frozen transaction required those labels to remain unchanged until post-result
Researcher/Skeptic review. The Researcher evidence supports lifting the operational
provenance blocker only if the independent Skeptic accepts the bundle and this claim
boundary. Even after that acceptance, authorization extends only to a separate full
analytic root-readiness design and implementation. It does not extend to root isolation.

### I.6 Work still required for a real root and estimator

1. **Complex-$k$ analytic consistency:** one anchored square-root chart must be injected
   into every port, proxy, Green, center-BIE, and lead-BIE path; the compression and
   dimensions must remain fixed on a candidate disk; factor, branch, mutation, and
   full-matrix Cauchy--Riemann gates must pass.
2. **Discrete root qualification:** after analytic readiness, a separate frozen-disk
   experiment must establish a count-one contour, converge bordered Newton, qualify a
   simple transverse root, and match it across levels. Real-axis minima alone are not
   roots.
3. **Empirical a posteriori correction:** matched adjacent-level roots, a stable
   projected derivative, map/root corrections, next-level shift agreement, and
   effectivity against an independently resolved $k_{\infty,h}^{\mathrm{ref}}$ remain
   uncomputed.
4. **Real-case validation and certification:** independent proxy/BIE/port refinement,
   a resolved half-guide reference, MATLAB parity, and representative modes are still
   required. Continuous kernel--field equivalence, saturation, correction remainder,
   and validated numerical-error bounds remain separate theory/validated-numerics gates.

### I.7 Exact next stage

The next stage is **Full analytic root-readiness**, beginning with a separately reviewed
and frozen experiment design extracted from the dormant re-entry protocol in the v1.1
design. Its target is the double-ellipse case with $\beta=0.8$, scan interval
$[0.04,0.18]$, $n_{\mathrm{ref}}=3$, levels $j=0,3,4$, and the accepted
source-derived proxy chart. The stage must, without post-result retuning:

1. anchor every $\gamma_m(k)$ branch at one real seed and inject the same continuation
   through all square-root consumers, with branch algebra and continuation errors at
   most $10^{-12}$;
2. run the 29-point real locator at $j=3$, require a strict interior dip with
   $s(k)\le10^{-3}$ and neighboring values at least $1.5s(k)$, then perform two
   nine-point refinements using one frozen compression;
3. require center participation at least $10^{-3}$ and refinement overlap at least
   $0.9$;
4. test the three base ranks $r_{\mathrm{seed}}-2$, $r_{\mathrm{seed}}-1$,
   $r_{\mathrm{seed}}$ and the predeclared 48/48/28/order-10 proxy refinement, including
   the frozen chart-spread and boundary-separation conditions;
5. test disk radii $r_0,r_0/2,r_0/4$ in that order on nested 16/32 boundary nodes, the
   center, and eight half-radius nodes, recording every branch, proxy, BIE, doubling,
   terminal, far-block, $K_{ee}$, representation, and separation ledger at
   $j=0,3,4$;
6. run the full-matrix Cauchy--Riemann stencils at $j=0,4$ and require the final defects
   and derivative spreads to be at most $10^{-6}$ with the prescribed refinement trend;
   and
7. pass all mandatory branch, adaptive-solve/compression, antiholomorphic, singular-
   factor, hidden-pole, representation-nullspace, and circle-fallback negatives.

The maximum positive outcome of this next stage is
`ROOT_READINESS_SAMPLED_DISCRETE_GO`, while `PHYSICAL_ROOT_READY=STOP` remains. Any
missing path, representation drift, material chart spread, unavailable sampled node, or
failed Cauchy--Riemann/negative gate stops the program before contour integration. Only
after this stage passes may a separate discrete root-isolation experiment be frozen.

### I.8 Updated distance estimate

Subject to a Skeptic pass, provenance closure completes the former first remaining
empirical stage. Approximately **four major empirical stages** remain to a credible
real-case eigenvalue plus an empirical estimator: full analytic root-readiness, discrete
root isolation, empirical adjacent-level correction, and real-case validation. The
earliest qualified discrete root is therefore two stages away. Reliable certification
remains farther because the continuous and validated-numerics gates in I.6 are not
included in that four-stage empirical count.

### I.9 Review handoff

1. **Claim:** the v1.1 source-derived operational provenance gates pass.
   **Status:** `ESTABLISHED`. **Weakest step:** source-exactness is revision- and
   process-specific; the manifest is direct-call only and MATLAB parity was not tested.
2. **Claim:** the operational upstream provenance blocker can be lifted.
   **Status:** `CONDITIONAL` on independent Skeptic acceptance. **Smallest downgrade:**
   retain `BLOCKED_UPSTREAM_PROVENANCE` if marker integrity, source-copy independence,
   shared-array coverage, or the aggregate logic is found defective.
3. **Claim:** production-internal $A_{\mathrm{pr}},b_{\mathrm{pr}}$ identity was observed.
   **Status:** `REFUTED AS A DESCRIPTION OF THIS EXPERIMENT`; the correct status is
   `NOT_DIRECTLY_OBSERVED`.
4. **Claim:** the object evidence supports a complex analytic chart or root.
   **Status:** `NOT ESTABLISHED`. **Smallest next falsification:** execute the separately
   frozen analytic-readiness positives and mandatory negatives before any contour code.
5. **Claim:** four empirical stages remain to the requested real eigenvalue-and-estimator
   case.
   **Status:** `PROVISIONAL RECOMMENDATION`; failures of branch continuation, chart
   sensitivity, contour isolation, or level matching may split those stages.
