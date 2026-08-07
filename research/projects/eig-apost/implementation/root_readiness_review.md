<!-- Corrected independent pre-implementation review of the Root-readiness gate -->

# Root-readiness gate skeptic review

> **Correction:** the previous `STOP` finding based on a corrupted interactive proxy
> reconstruction is retracted; this replacement verdict governs.
>
> **Reader precedence:** Section K is the current corrective delta verdict. Earlier
> `PENDING` states and Section J's first-run implementation findings are retained as audit
> history. A post-run status-only note later changed the design file hash, so this review
> is marked `STALE` for manifest freshness; the frozen gates and reviewed numerical values
> were not changed.

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: pre-implementation-review
- Origin Date: 2026-08-07
- Verification Status: STALE
- Review Status: CORRECTIVE DELTA PASS / ROOT READINESS REVISE-BLOCKED
- Version Label: eig-apost-root-readiness-review-v1.2-handoff
- Repro Lock: null
- Audit Target:
  [[research/projects/eig-apost/implementation/root_readiness|Root-readiness design]]

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
