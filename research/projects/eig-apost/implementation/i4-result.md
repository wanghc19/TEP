# I4 full analytic root-readiness result

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: validate
- Origin Date: 2026-08-07
- Verification Status: VERIFIED FOR REPRODUCIBLE STOP
- Version Label: eig-apost-i4-result-v1.0
- Governing Design: [[research/projects/eig-apost/implementation/i4-readiness|I4 readiness design]]
- Repro Lock: baseline/repeat direct-source manifest and worktree lock

## Result

The frozen I4 experiment completed in Octave and published a valid baseline/repeat
bundle. Its evidence verdict is `PASS WITH CONDITIONS`, but its scientific decision is

`ROOT_READINESS_SAMPLED_DISCRETE_STOP / NO_SCREENED_DIP`.

This is a valid negative answer for the frozen locator, not an execution failure. It
does not authorize root isolation.

## Frozen run

The two commands were executed from the repository root:

```text
perl -e 'alarm shift; exec @ARGV' 3600 conda run -n octave octave --quiet --no-gui --eval "addpath('test/root-ready/analytic-readiness'); run_analytic_readiness('baseline');"
perl -e 'alarm shift; exec @ARGV' 3600 conda run -n octave octave --quiet --no-gui --eval "addpath('test/root-ready/analytic-readiness'); run_analytic_readiness('repeat');"
```

Both numerical runs returned exit code 0. An earlier baseline invocation stopped before
sampling because the transaction wrapper parsed the first `git status --porcelain`
line incorrectly. The one-line parser repair was made before any staging directory was
created; the reviewed self-test and source lock were then rerun before the authoritative
baseline/repeat pair.

The published output is
`test/root-ready/analytic-readiness/output/`. Each run has a completion marker covering
13 non-marker artifacts. The repeat was published only after marker, schema, manifest,
gate, `results.mat`, and reproducibility validation.

## Locator evidence

All 29 real locator nodes on $[0.04,0.18]$ at $j=3$ were available. No row was omitted.
The relative smallest singular value

$$
  s(k)=\frac{\sigma_{\min}(F_{3,h}^{\mathrm{aug}}(k))}
  {\max(1,\lVert F_{3,h}^{\mathrm{aug}}(k)\rVert_2)}
$$

decreased strictly from

$$
  s(0.04)=0.20830914493786493
$$

to

$$
  s(0.18)=0.035393668501939167.
$$

The sampled minimum is the right endpoint rather than a strict interior minimum and is
about $35.4$ times the frozen $10^{-3}$ threshold. The correct stable interpretation is
`NO_SCREENED_DIP`.

## Gate interpretation

| Gate group | Result | Interpretation |
|---|---|---|
| locator | `FAIL` | No admissible interior dip; this is the decisive upstream blocker. |
| fixed charts, sampled disk, branch, factors, full-$F$ CR | `NOT RUN UPSTREAM` | No seed or disk existed. These are not observed numerical defects. |
| mandatory negatives | `INCOMPLETE` | N1, N2, N5, and N10 passed; N3, N4, N6--N9, and N11 were `NOT_RUN_UPSTREAM_STOP`. |
| artifact bundle | `PASS` | Both runs have validated transactional evidence. |
| reproducibility | `PASS` | Numeric relative difference is 0 and every equality flag is 1. |

The generated `gate.csv` uses generic `FAIL` for downstream gates. The empty ledgers and
the negative-case statuses make the upstream-stop semantics unambiguous; no downstream
failure should be inferred.

## Reproducibility

`reproducibility.txt` records `REPRODUCED`, numeric relative difference 0, and equality
for the manifest, branch and projector identifiers, selected disk, scientific gates,
locator, disks, sampled rows, factors, branch rows, CR rows, charts, and negatives. The
baseline and repeat locator CSVs are byte-identical. The source manifest contains 19
`DIRECT_PROJECT_CALLS_ONLY` entries.

This verifies deterministic reproduction at the declared direct-source scope. It does
not establish transitive-dependency completeness, MATLAB parity, or production-internal
$A_{\mathrm{pr}},b_{\mathrm{pr}}$ identity.

## Decision boundary

- I4 did not reach `ROOT_READINESS_SAMPLED_DISCRETE_GO`.
- `PHYSICAL_ROOT_READY=STOP` remains in force.
- No candidate disk, contour count, root, eigenvalue, correction, estimator, or
  effectivity value was produced.
- I5 root isolation is not authorized.

The result closes only the historical question for the frozen interval: that locator
has no screened dip. The unresolved work is maintained in
[[research/projects/eig-apost/implementation/open-problems#I4|the I4 ledger]].

## ARS validation and fallacy scan

Overall confidence is `SOLID` for the narrow claim “the frozen locator reproducibly
returned no screened dip” and `RED FLAG` for any claim that I4 passed, that no root
exists globally, or that root isolation is authorized.

Coverage is 11/11. Simpson's paradox, ecological fallacy, Berkson's paradox, collider
bias, base-rate neglect, regression to the mean, correlation/causation, and reverse
causality are not applicable to this deterministic single-configuration experiment.
Survivorship bias was checked: all locator nodes were retained. No look-elsewhere or
forking-path issue occurred in the published frozen run; both become important risks if
future intervals are extended serially, so the next locator attempt must be separately
preregistered and retain every point.

