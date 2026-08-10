# I4 full analytic root-readiness review

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: validate
- Origin Date: 2026-08-07
- Verification Status: VERIFIED
- Version Label: eig-apost-i4-review-v1.0
- Reviewed Result: [[research/projects/eig-apost/implementation/i4-result|I4 result]]

## Verdict

**Evidence: `PASS WITH CONDITIONS`. Scientific stage: `STOP`. I5: `NOT AUTHORIZED`.**

The published STOP is valid, interpretable, and exactly reproduced. The stage did not
reach its positive target because the frozen real locator produced no admissible seed.

## BLOCKER

The sole observed scientific blocker is `NO_SCREENED_DIP`. All 29 samples were
available, but $s(k)$ decreased strictly across $[0.04,0.18]$, ending at
$s(0.18)=0.035393668501939167$. There is no strict interior minimum, and the smallest
sample is still about $35.4$ times the frozen $10^{-3}$ threshold.

Consequently no seed SVD, fixed chart, candidate disk, factor ledger, full-$F$ CR test,
or complete negative matrix could run. The analytic-domain and negative-coverage parts
of I4 remain unresolved and directly block root isolation.

## IMPORTANT CAVEATS

1. The generated report and gate table do not print the stable
   `NO_SCREENED_DIP` label; it is reconstructed from the complete locator, zero selected
   rows, empty downstream ledgers, and `NOT_RUN_UPSTREAM_STOP` negative statuses.
2. Downstream G2--G7 `FAIL` entries mean upstream-unavailable, not independently observed
   chart, branch, factor, CR, or falsification failures.
3. The negative result applies only to the frozen 29-point interval and discretization.
   It does not exclude a dip between nodes, above $0.18$, across the Wood point at
   $k=0.2$, or for another physical family.
4. The direct-call manifest is not a transitive dependency manifest, MATLAB parity has
   not been run, and the evaluator remains source-derived rather than a direct
   production-internal-array observation.

## MINOR CAVEATS

- Only the upstream-independent N1, N2, N5, and N10 controls ran. The other seven
  negative fixtures remain untested rather than failed.
- Octave and the Perl-backed SHA utility repeatedly printed locale warnings and Octave's
  exit cleanup warning; both authoritative commands nevertheless returned exit code 0,
  and the markers and hashes validated.

## What survived review

- All 29 locator samples are present and available.
- Baseline/repeat publication, locks, markers, and 13-artifact hashes are sound.
- The scientific evidence tables reproduce exactly; aggregate numeric difference is 0.
- `PHYSICAL_ROOT_READY=STOP`, hidden-pole disclosure, and unavailable pole-free claim
  were preserved.
- No root, estimator, or certification computation was silently performed.

## Smallest next action

Close this frozen I4 attempt as `REPRODUCIBLE STOP / NO_SCREENED_DIP`. If work continues,
freeze a separate locator-only experiment with the same model, normalization, $j=3$
assembly, dip threshold, and neighbor ratio. The observed endpoint trend supports one
predeclared interval immediately above $0.18$ but strictly below the Wood point
$k=0.2$. That experiment must stop after its declared attempt; serial post-result
interval hunting is not allowed.

If it finds a screened dip, rerun the complete I4 protocol from a fresh frozen bundle.
Do not splice the new locator into this published output. The open items and statuses
are centralized in
[[research/projects/eig-apost/implementation/open-problems#I4|the I4 ledger]].

