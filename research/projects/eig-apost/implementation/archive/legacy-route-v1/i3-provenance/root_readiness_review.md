<!-- Corrected independent pre-implementation review of the Root-readiness gate -->

# Root-readiness gate skeptic review

> **Correction:** the previous `STOP` finding based on a corrupted interactive proxy
> reconstruction is retracted; this replacement verdict governs.
>
> **Reader precedence:** Section L is the current provenance-closure post-run verdict.
> Earlier `PENDING` states, Section J's first-run findings, and Section K's corrective
> delta are retained as audit history. The `STALE` passport below applies to that earlier
> controlled-diagnostic review; Section L has its own current passport and evidence lock.

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: pre-implementation-review
- Origin Date: 2026-08-07
- Verification Status: STALE
- Review Status: CORRECTIVE DELTA PASS / ROOT READINESS REVISE-BLOCKED
- Version Label: eig-apost-root-readiness-review-v1.2-handoff
- Repro Lock: null
- Audit Target:
  [[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness|Root-readiness design]]

## A. Audit frame

The audit target is `root_readiness.md` v1.1 plus the proxy-chart preflight used to choose
a fixed analytic discretization. The question is whether the exact current proxy system
and its solver variants have been reconstructed with common inputs and normalization
before any double-ellipse domain/root-readiness claim. Authority remains
[[research/projects/eig-apost/phase3-analysis/s-root|Phase 3 root qualification]],
[[research/projects/eig-apost/phase3-analysis/s-estimator|the Phase 3 estimator]], the
Phase 4 method, and accepted Stage 1/2 evidence. No root count, eigenvalue, estimator,
continuous injectivity, or pole-free theorem is under review.

## B. Verdict

**REVISE — PENDING CONTROLLED DIAGNOSTIC, high confidence.** Root-readiness is neither
`GO` nor evidence-based `STOP` yet. The earlier interactive reconstruction that produced
residuals `0.283` and `7.18e-4`, and the downstream mismatch values derived from it, was
corrupted and is formally retracted. An exact reconstruction now reports production
`pinv` residual `2.7323e-8` and coefficient norm `1.50169`, matching
`kernel.precomp_proxy`; this correction invalidates the previous `STOP` rationale but
does not by itself validate a frozen complex chart. A minimal, source-aware diagnostic
comparing solver/rank variants on one identical exact $A,b$ is authorized. Full
disk/domain/root implementation remains unauthorized until that evidence is reviewed.

## C. Strongest challenge

The decisive risk is now **provenance ambiguity in the proxy oracle**, not a demonstrated
bad proxy chart. If solver variants are compared using nonidentical or incorrectly
reconstructed $A,b$, apparent analyticity, residual improvement, or mismatch can be
entirely artificial. Every later $F(k)$ claim depends on resolving this first.

## D. Findings

1. **CRITICAL, RETRACTED EVIDENCE:** all conclusions based on the corrupted interactive
   `0.283/7.18e-4` reconstruction are void. They must not appear as solver results,
   thresholds, or failure evidence. Preserve them only as
   `DISCARDED_CORRUPTED_RECONSTRUCTION` provenance.
2. **MAJOR, OPEN:** the origin of the previously reported `7.18e-4` must be identified or
   marked unresolved by running production actual, default `pinv`, explicit SVD
   tolerances/ranks, and reduced charts on byte-identical $A,b$ with one residual
   definition.
3. **MAJOR, OPEN:** off-collocation quasiperiodicity and proxy-resolution sensitivity are
   needed; small collocation residual alone can coexist with large coefficients and
   cancellation.
4. **MAJOR, CONTAINED:** anchored branches and fixed $U_r,V_r,r$ can define a meromorphic
   finite-dimensional family, but recomputed SVD/`pinv`, pointwise propagating branch
   selection, and inactive outer-path tests remain invalid substitutes. The corrected
   mandatory mutations remain required only after proxy provenance closes.
5. **OBSERVATION:** finite sampled conditioning/CR can at most support sampled discrete
   readiness; physical readiness remains `STOP` regardless.

## E. Implementation audit

Authorize only a `test/root-ready/` proxy diagnostic using one shared exact $A,b$
constructor. It must first reproduce production proxy coefficients and fields, serialize
the singular spectrum, actual solver tolerance/rank, coefficient norms, common full,
projected, and backward residuals, independent off-collocation residuals,
base/refined-proxy comparisons, and limited $A_{\mathrm{QP}}$/scattering differences. No
complex disk, contour, root, estimator, adaptive tuning, or production-code modification
is authorized.

Required interim state:

- `PROXY_DIAGNOSTIC_COMPLETE` or failure;
- `ROOT_READINESS_SAMPLED_DISCRETE_GO=0`;
- `PHYSICAL_ROOT_READY=STOP`;
- root-readiness verdict `PENDING_REVIEW`, not `STOP` inferred from retracted data.

## F. What survived

Stage 2 block, scaling, and availability evidence survives. The fixed two-sided
Petrov--Galerkin construction remains mathematically viable in principle. The corrected
propagating-branch, inconsistent-tall-system, explicit antiholomorphic full-matrix,
hidden-pole, and representation negatives remain sound design requirements. None
establishes which proxy discretization is adequate.

## G. Minimal resolution

Run the controlled diagnostic with unchanged-source reproduction. Then correct
`root_readiness.md` using only authoritative results, freeze one proxy representation and
thresholds before any formal domain run, and obtain a second Skeptic verdict.

## H. Open gaps

Exact solver-variant reconciliation, selected rank, coefficient amplification,
off-collocation error, proxy refinement, analytic full-$F$ evaluator, sampled disk, factor
ledger, continuous representation bridge, root, correction, reference truth, and MATLAB
parity are all unverified.

## I. Corrected-design delta review

**PASS WITH CONDITIONS for controlled diagnostic implementation only, high confidence.**
Root-readiness itself remains `BLOCKED_PENDING_DIAGNOSTIC`, and physical readiness remains
`STOP`. The corrected v1.1 design retracts the corrupted pilot values, makes no claim about
an actual selected rank or residual, separates the current exact-constructor diagnostic
from the dormant domain/CR/root protocol, defines solver and object-comparison gates, and
forbids fabricated downstream outputs.

Implementation conditions are:

1. exact reproduction of the production proxy coefficients must be at most $10^{-11}$;
2. every solver variant must consume identical $A,b$ and identical residual formulas;
3. the frozen $10^{-5}$ object-consistency gate may not be relaxed;
4. no scan, candidate disk, contour, root, or estimator code may run;
5. an unchanged-source repeat must close the reproducibility gate;
6. the executed evidence requires a mandatory post-result Skeptic review.

## J. Mandatory post-result Skeptic review

### A. Audit frame

The audited artifact is the Root-readiness controlled proxy diagnostic: its design,
MATLAB/Octave implementation, source manifest, reproducibility record, and all emitted
CSV evidence. Success required exact shared-$A,b$ provenance, the frozen compatibility
gates, unchanged-source reproduction, and absence of unauthorized root or estimator
computations.

### B. Verdict

**REVISE -- high confidence.** The controlled diagnostic completed reproducibly, but
Root-readiness did not pass. The mandatory constructor-reproduction conditions fail, and
production and candidate paths do not actually consume one shared returned $A,b$. The
evidence is useful negative-gate evidence, not authorization for a candidate scan,
complex disk, root solve, or estimator.

### C. Strongest challenge

`LOCAL_build_proxy_system` independently reconstructs $A,b$, while
`kernel.precomp_proxy` separately assembles and solves its own internal matrices. Because
production does not return the matrices it consumed, bytewise or entrywise identity is
not demonstrated. In an ill-conditioned proxy system, small assembly-order differences
can produce materially different pseudoinverse coordinates and potentially alter a later
nonlinear root evaluator.

### D. Gate evidence

| Check | Observed | Frozen threshold | Result |
|---|---:|---:|---|
| production coefficient reproduction | $2.79854\times10^{-7}$ | $10^{-11}$ | FAIL |
| production proxy-field reproduction | $5.53155\times10^{-10}$ | $10^{-11}$ | FAIL |
| common residual identity | $1.25039\times10^{-9}$ | $10^{-11}$ | FAIL |
| unchanged-source numeric repeat | $0$ | $10^{-13}$ | PASS |
| source-manifest equality | 1 | 1 | PASS |
| production-to-selected proxy field | $1.97156\times10^{-10}$ | $10^{-5}$ | numerically within gate |
| maximum downstream mismatch | $2.32268\times10^{-10}$ | $10^{-5}$ | numerically within gate |
| selected off-collocation residual | $5.91145\times10^{-8}$ | none frozen | diagnostic only |
| base/refined Green difference | $1.89851\times10^{-9}$ | none frozen | diagnostic only |

### E. Findings and implementation audit

1. **CRITICAL -- exact shared-$A,b$ provenance is unproved and its numerical gates
   fail.** Candidate solvers share the test-local reconstruction, but production does
   not consume that returned object. The decisive repair is structural sharing of the
   constructor, not relaxation of $10^{-11}$.
2. **MAJOR -- the frozen $10^{-5}$ compatibility gate was incorrectly demoted.**
   `root_readiness.md` and the pre-review define it as a hard per-object gate, whereas
   `gate.csv` records `PREVIOUS_PROPOSAL_NOT_AUTHORITY`, `pass=0`, and `availability=0`.
   Upstream constructor failure may block the overall decision, but it cannot revoke a
   preregistered sub-gate. The computed field and downstream objects satisfy $10^{-5}$
   and should be recorded as available/pass while the aggregate verdict remains blocked.
3. **MAJOR -- the fixed-chart fingerprint is incomplete.** The frozen $U_r,V_r$
   projectors are neither serialized nor included directly in the reproducibility
   vector, despite the design requiring projector reproduction. Exact repetition of
   downstream scalars does not replace this check.
4. **MINOR -- source provenance is internally consistent but not dependency-complete.**
   All nine recorded hashes match the current files, and the second run reproduces
   exactly. However, downstream dependencies such as `geom.construct_cont` are used but
   absent from the manifest.
5. **OBSERVATION -- scope control passed.** No candidate scan, complex-disk test,
   Cauchy--Riemann test, contour count, Newton solve, eigenvalue, or estimator was
   executed.

### F. What survived

The reduced chart remains mathematically plausible. Large changes in proxy coefficients
coexist with small Green-field and downstream changes, consistent with nearly null
proxy-coordinate directions. The sampled reduced factors remain nonsingular,
off-collocation residuals are small, and the experiment is exactly reproducible. These
establish useful compatibility evidence, not physical truth or complex-domain
analyticity.

### G. Minimal resolution

Expose or otherwise structurally share one exact $A_{\mathrm{pr}},b_{\mathrm{pr}}$
constructor between the production-equivalent solve and every comparison path; rerun
without changing the frozen tolerances; restore the authoritative per-object $10^{-5}$
ledger; serialize the fixed projectors and verify their unchanged-source reproduction.

### H. Authorization and open gaps

Set the reviewed state to `ROOT_READINESS_BLOCKED_EXACT_CONSTRUCTOR_MISMATCH` and retain
`PHYSICAL_ROOT_READY=STOP`. Only the repair-and-rerun cycle is authorized. The dormant
scan/disk/branch/CR/root stage is not authorized. Continuous kernel--field equivalence,
physical-root exclusion, adjacent-level correction, reference truth, and the posterior
estimator remain unverified.

## K. Corrective delta review

**Corrective-delta verdict: PASS. Root-readiness verdict: REVISE / BLOCKED, high
confidence.** The revised evidence now represents the diagnostic faithfully, but it does
not change the failed scientific gate.

- Production-internal $A,b$ identity is correctly labeled
  `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`; no entrywise or bytewise identity is claimed.
- The three frozen $10^{-11}$ output checks remain unchanged and fail: coefficient
  $2.79854\times10^{-7}$, proxy field $5.53155\times10^{-10}$, and residual difference
  $1.25039\times10^{-9}$.
- The frozen $10^{-5}$ object gate is now enforced: all 78 downstream rows and all 3
  resolution rows pass. Their maxima are $1.67093\times10^{-9}$ and
  $1.89851\times10^{-9}$, respectively; the aggregate maximum is
  $1.89851\times10^{-9}$ and passes.
- Fixed projector fingerprints are recorded for ranks 126 and 144. Both left/right
  SHA-256 pairs reproduce exactly, and `projector_fingerprints_equal=1`.
- All ten direct project-call source hashes match the current files, including
  `geom.construct_cont`. The manifest is correctly limited to
  `DIRECT_PROJECT_CALLS_ONLY` and makes no unsupported transitive-completeness claim.
- The unchanged-source repeat reports zero numerical difference, equal source manifest,
  equal projector fingerprints, and `REPRODUCED`.
- Static inspection and the run ledger confirm that no candidate scan, complex disk,
  Cauchy--Riemann test, contour/root count, Newton solve, eigenvalue, or estimator
  computation ran.
- The report correctly treats object compatibility as a discrete consistency result, not
  physical truth, and explicitly prevents it from overriding the failed provenance/output
  gates.

The authoritative state should remain `ROOT_READINESS=BLOCKED_UPSTREAM_PROVENANCE`,
`ROOT_READINESS_SAMPLED_DISCRETE_GO=0`, and `PHYSICAL_ROOT_READY=STOP`. The next
root-search stage is not authorized. Only a structural interface/provenance repair that
makes the consumed production $A,b$ observable or genuinely shared, followed by an
unchanged-threshold rerun and review, is authorized.

## L. Provenance-closure post-run review

### Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: post-run independent validation
- Origin Date: 2026-08-07
- Verification Status: CURRENT / ARTIFACTS AND DATA FLOW INDEPENDENTLY INSPECTED / NOT
  INDEPENDENTLY RERUN
- Review Status: PASS WITH CONDITIONS / GO TO FULL ANALYTIC COMPLEX-K ROOT-READINESS ONLY
- Version Label: eig-apost-provenance-closure-post-run-review-v1.0
- Repro Lock: `eig-apost-provenance-closure-v1.1`; package SHA-256
  `3a16825064e5762f3486373fee702e94c34fa3cfdfb3b774f78f3b27eb2f9a60`; executable-body
  SHA-256 `eb116bc9a359b9a50d6804891939cdfeb2b6a17eacb8a6a2a3a8e7d29bebd82c`
- Audit Target:
  `test/root-ready/provenance-closure/output/`, its implementation, and the
  [[research/projects/eig-apost/implementation/archive/i3-provenance/root_readiness#Pre-execution provenance-closure addendum|frozen provenance-closure addendum]]
- Claim Boundary: source-derived shared-system provenance at six frozen real-axis
  samples; no direct production-internal $A,b$, complex-$k$ analyticity, root,
  eigenvalue, correction, or estimator claim

### L.A. Audit frame

The question is whether the completed provenance-closure experiment supports the narrow
label `SOURCE_DERIVED_SHARED_A_B_PROVENANCE_PASS` strongly enough to enter a separately
designed full analytic complex-$k$ root-readiness experiment. The claimed contribution
is test infrastructure: a source-exact copy exposes the already existing collocation
arrays, every comparison solver receives the same copy-returned pair, and the old
numerical tolerances are retained. It is not a change to the mathematical model in
[[research/projects/eig-apost/implementation/archive/i0-manufactured/design|the frozen algorithm design]].

Success requires the frozen source/body locks, same-process bitwise public-output
agreement, exact solver-row coverage by shared-array fingerprints, all three
$10^{-11}$ gates, all three $10^{-5}$ object gates, the mutation negative, two-run
reproduction, and complete marked artifacts. It also requires that off-collocation and
historical-projector results remain non-gating and that no root-stage computation ran.
The authoritative materials examined were the provenance addendum, the package source,
the instrumented copy, `provenance_closure_diagnostic.m`, both completed output trees,
their markers, `reproducibility.txt`, and the historical controlled-diagnostic findings
in Sections J--K.

The reconstructed dependency chain is

$$
\text{source/body lock}
\Longrightarrow \text{source-exact copied arithmetic}
\Longrightarrow \text{bitwise public-output match}
\Longrightarrow \text{one cached copy-returned }(A,b)\text{ per sample}
\Longrightarrow \text{five fingerprint-matched solver rows}
\Longrightarrow \text{frozen numerical gates}
\Longrightarrow \text{narrow operational provenance label}.
$$

The final implication stops there. It does not imply a holomorphic complex-$k$ family,
a pole-free disk, a guided root, or a posteriori error control.

### L.B. Verdict

**PASS WITH CONDITIONS; gate decision: `GO -- FULL_ANALYTIC_COMPLEX_K_ROOT_READINESS
ONLY`, high confidence for the frozen Octave artifact and moderate confidence outside
that environment.** The source-derived operational claim is defensible: the copied body
is byte-exact, the package and copy public outputs agree bitwise at all six frozen
samples, the implementation caches six returned systems and records exactly five
fingerprint-matched solver rows per system, every retained numerical gate passes, and
the two completed runs reproduce. `GO` authorizes only the next analytic-readiness
design and experiment. It does not authorize root isolation and does not mean that an
eigenvalue or estimator exists.

### L.C. Strongest challenge

The manifest, marker, and repeat checks are generated and validated largely by the same
driver, so they cannot independently establish mathematical correctness. Two identical
runs can reproduce the same mistake. This does not overturn the narrow verdict because
an independent post-run inspection rehashed the frozen package/body and all eleven
direct-call manifest files, validated all 13 baseline and 27 repeat marker entries,
checked the cache-to-solver data flow, and found the baseline/repeat tabular evidence
identical. It remains decisive against any stronger claim: only an independently
specified complex-$k$ test can establish the next analytic property.

### L.D. Findings

1. **MAJOR -- operational provenance is defensible only with its frozen scope.**
   Location: the addendum's “Question and operational claim,” the instrumented copy,
   `output/repeat/source-copy.csv`, and `output/repeat/report.md`. Evidence: the package
   and copy executable spans are byte-identical with the frozen body hash; the allowed
   transform changes only the declaration/output list and help text; forbidden
   context-sensitive constructs are absent; the common solver branch is `pinv`; and all
   six package/copy public outputs are bitwise equal. Consequence: the copy is a valid
   source-derived oracle for this frozen experiment, but
   `production_internal_A_b_identity` remains unavailable with reason
   `NOT_OBSERVABLE_WITH_CURRENT_INTERFACE`. Uncertainty: MATLAB parity, another package
   revision, or another process environment is untested. Decisive test for the stronger
   claim: expose and fingerprint the arrays from the package call itself; until then the
   stronger claim must remain prohibited.

2. **MAJOR -- manifest/marker/repeat evidence is integrity evidence, not a proof of the
   mathematics.** Location: both `completion.marker` files,
   `output/reproducibility.txt`, and the driver's finalization helpers. Evidence: the
   repeat reports zero relative difference, equal manifests, shared-array and projector
   fingerprints, and complete bundles; independent digest checks match all marker
   entries and all eleven current direct-call sources. Consequence: stale, partial, or
   accidentally mixed output is ruled out, while a common-mode algorithmic error is
   not. Uncertainty: the manifest is intentionally `DIRECT_PROJECT_CALLS_ONLY`, not
   transitive. Decisive test: keep an external read-only verifier or a second independent
   implementation for the future analytic gate.

3. **OBSERVATION -- the five solver rows genuinely use one returned $A,b$ value per
   sample.** Location: `provenance_closure_diagnostic.m`, the six rows of
   `output/repeat/shared-system.csv`, and the thirty rows of
   `output/repeat/solver-comparison.csv`. Evidence: each package/copy pair is called once
   and cached; the seed SVD uses the cached seed; all five solver evaluations receive the
   cached `A_shared,b_shared`; bidirectional validation enforces the exact five-label set
   and the unique matching fingerprints. No hash mismatch, duplicate, missing, or extra
   row was found. Consequence: the previous independently reconstructed-system defect is
   not present in this comparison path. Decisive falsifier: any solver-row fingerprint
   differing from its unique shared-system row.

4. **OBSERVATION -- the old tolerances were preserved and passed on the new path.**
   Location: `output/repeat/gate.csv`. Evidence: the three constructor-output thresholds
   remain $10^{-11}$ and have observed error zero; the resolution, downstream, and
   aggregate object thresholds remain $10^{-5}$ with maxima
   $1.8985069017516266\times10^{-9}$,
   $1.6709312536070531\times10^{-9}$, and
   $1.8985069017516266\times10^{-9}$. Consequence: no post-result tolerance relaxation
   explains the pass. The older failures in Sections J--K remain valid for the older,
   independently reconstructed arithmetic path and are not rewritten as passes.

5. **OBSERVATION -- off-collocation and historical projectors were not promoted to
   gates.** Location: `gate.csv`, `off-collocation.csv`, and
   `historical-projector.csv`. Evidence: off-collocation has no threshold,
   `availability=0`, and `PENDING_REVIEW` despite the reported maximum
   $5.9114540325227302\times10^{-8}$; historical base/refined projectors are labeled
   `DIFFERENT` and `NON_GATING_HISTORICAL_DIAGNOSTIC` and do not enter the required-gate
   vector. Consequence: neither diagnostic is being used to manufacture the provenance
   pass. Decisive falsifier: either quantity appearing in the aggregate required-gate
   conjunction without a new preregistered review.

6. **MINOR -- raw-array hashes prove equality of recorded values, not physical memory
   identity.** Location: shared-system fingerprint generation and solver-row checks.
   Evidence: the driver passes the cached variables into all solver evaluations and
   records matching class/dimension/endianness-aware hashes. Consequence: “same $A,b$”
   is defensible as the same returned numeric values and data lineage, which is the
   relevant mathematical meaning; it should not be described as an address-level alias.
   Decisive test: none is needed unless a future claim depends on memory aliasing.

7. **OBSERVATION -- the paper's mathematical logic and notation were not changed.**
   The experiment changes only how a pre-existing proxy collocation system is observed
   in test code. The superscript in
   $A_{\mathrm{pr}}^{\mathrm{copy}},b_{\mathrm{pr}}^{\mathrm{copy}}$ is necessary to
   prevent conflation with unobserved production internals; no historical projector or
   diagnostic residual is inserted into the estimator theory.

8. **OBSERVATION -- ARS statistical-fallacy scan completed 11/11.** Simpson's paradox,
   ecological fallacy, Berkson's paradox, collider bias, base-rate neglect, regression
   to the mean, survivorship bias, correlation/causation, and reverse causality are not
   applicable because this deterministic gate makes no grouped, population, causal, or
   probabilistic inference. Look-elsewhere and garden-of-forking-paths risks are
   contained here by frozen samples, thresholds, and the explicit absence of a search;
   they become live risks when the complex domain and root-search region are chosen.

### L.E. Implementation audit

No specification-to-code mismatch was found in the audited provenance gates. The source
verifier uses binary reads and exact byte spans; the driver checks the resolved package
path, unique manifest paths, digest syntax, the mutation negative, exact solver-row
coverage, artifact headers/counts, and write-last markers before publication. The output
retains all required rows, and no `output.inprogress/` tree is presented as final
evidence.

The remaining numerical risks are outside this gate: pointwise square-root sign
correction need not define a holomorphic branch on a complex disk; a frozen real-axis
rank need not remain separated on that disk; small sampled object mismatches do not give
continuous kernel--field equivalence; and Octave bitwise agreement does not establish
MATLAB agreement. Untested edge cases include branch thresholds, proxy-rank changes,
near-singular reduced factors, complex frequencies, and a disk touching a pole or a
Rayleigh threshold.

### L.F. What survived

The following claims remain defensible:

1. the source-exact copy implements the frozen package arithmetic at the audited body
   level and reproduces the package's public result at all six frozen samples;
2. all test-local solver variants are compared on one cache-derived pair per sample;
3. the unchanged $10^{-11}$ and $10^{-5}$ gates pass on that path;
4. the two published runs and their recorded fingerprints reproduce; and
5. the result is a narrow plumbing/provenance advance that leaves the proposed
   eigenvalue search and estimator mathematics unchanged.

### L.G. Minimal resolution and next gate

No further provenance repair is required before the next stage. The smallest authorized
next step is a separately frozen full analytic complex-$k$ root-readiness experiment
that:

1. rechecks the package/body and environment locks on every run;
2. preregisters the complex disk, outgoing Rayleigh branch continuation, fixed rank and
   projectors, pole/factor ledger, and stop conditions before sampling;
3. establishes factor conditioning and a pole-free admissible domain;
4. passes full-matrix Cauchy--Riemann/derivative checks and mandatory antiholomorphic and
   branch-breaking negatives; and
5. receives a new skeptic review before any contour count, Newton solve, or root claim.

This is a `GO` to analytic root-readiness, not to root isolation.

### L.H. Open gaps and blockers

There is **no remaining blocker to entering the full analytic complex-$k$
root-readiness stage under the conditions above**. The following remain blockers to a
real eigenvalue-and-estimator case: direct production-internal $A,b$ observation if that
stronger provenance claim is demanded; transitive-dependency and MATLAB parity checks;
a validated analytic branch and pole-free complex domain; stable chart/rank and
conditioned factors throughout that domain; a reviewed contour count and isolated
guided root; adjacent-level matching and empirical correction; independent reference
truth; and estimator reliability/effectivity evidence. The current output explicitly
ran none of the scan, disk, Cauchy--Riemann, contour, Newton, eigenvalue, correction, or
estimator stages.

## Open-problem handoff

Current goal-relative classifications, blocking scopes, and cheapest follow-up checks are
maintained in
[[research/projects/eig-apost/implementation/open-problems#I3|the I3 open-problem ledger]]
and
[[research/projects/eig-apost/implementation/open-problems#I4|the next-stage I4 ledger]].
Section L remains the authoritative historical verdict for the completed provenance gate;
the ledger controls prioritization, not a retroactive change of evidence.
