<!-- Post-experiment Researcher analysis of the Root-readiness controlled diagnostic -->

# Root-readiness controlled diagnostic result

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
  [[research/projects/eig-apost/implementation/root_readiness|Root-readiness design]]
- Pre-implementation Review:
  [[research/projects/eig-apost/implementation/root_readiness_review|Root-readiness review]]
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
