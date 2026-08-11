# Manufactured NEP experiment plan

## Material Passport

- Origin Skill: `academic-research-suite/experiment-agent`
- Origin Mode: `plan`
- Origin Date: 2026-08-02
- Verification Status: `UNVERIFIED`
- Version Label: `eig-apost-manufactured-v1.2`
- Repro Lock: `null`

## Experiment question

Can the finite-dimensional algorithm described in `design.md` reliably isolate and solve the
manufactured simple roots, evaluate the three projected corrections in a common
representation, reproduce the analytic effectivity trend, and reject the four prescribed
failure cases?

## Implementation contract

- Source directory: `test/eig-apost-nep/`
- Entry point: `run_manufactured_nep.m`
- Core language: MATLAB/Octave
- Allowed auxiliary output code: local `LOCAL_` helpers in the entry-point function
- Prohibited dependencies: existing `+bloch`, `+op`, BIE, or draft code
- Working directory: `/Users/whc/Documents/Work/epost`
- Hard timeout: 1,800 seconds for each run
- Monitoring interval: 30 seconds
- Expected duration: below 60 seconds

The function file must have the repository-required help sections and English comments with
2-space indentation. It may not write outside its own experiment directory.

## Frozen configuration

| Item | Value |
|---|---:|
| `k_star` | `2.3` |
| `alpha` | `4 + 3i` |
| `curvature_c` | `0.2` |
| `second_diag_slope_q` | `0.1` |
| `theta` | `0.25` |
| `root_levels` | `0:4` |
| `estimator_levels` | `0:3` |
| real scan interval | `[1.8, 2.5]` |
| real scan points | `401` |
| contour center | `k_star` |
| contour radii | `0.4`, `0.32` |
| contour nodes | `128`, `256` |
| Newton tolerance | `1e-12` |
| Newton maximum iterations | `20` |
| complex Newton seed offset | `0.05i` |
| derivative steps | `[1e-3, 5e-4, 2.5e-4]` |

## Pre-registered gates

### Pilot-01 amendment

Pilot-01 failed the unchanged count tolerance at $j=0$, radius $0.32$: 64 nodes gave
`1.000004424832`, a deviation of approximately $4.4\times10^{-6}$, whereas 128 nodes gave
`1.0000000000196` and the boundary relative singular value exceeded $10^{-3}$. The complete
failed run is preserved in `test/eig-apost-nep/pilot-01/`.

Before the formal run, the two quadrature levels were changed uniformly from 64/128 to
128/256. The radii, every other parameter, and the `1e-8` count gate are unchanged. This is
a pre-formal-run resolution increase approved by the Skeptic, not a relaxation of the
acceptance criterion. No further adaptive tuning is allowed if the formal run fails.

### Implementation-audit amendment

After a numerically passing v1.1 run, the Engineer required a stricter implementation
audit. Version v1.2 leaves the matrix model, contour, quadrature, thresholds, and numerical
oracles unchanged. It only:

- routes positive and negative cases through shared contour, representation, bordered-root,
  correction, and root-dominance helpers;
- implements the phase-invariant angle as the norm of the orthogonal component, which is
  exactly the principal-angle sine specified in `SYMBOL.md`;
- expands deterministic diagnostic artifacts and the SVG without changing pass/fail gates.

### Contour

- Every root count satisfies `abs(real(count)-1) <= 1e-8` and
  `abs(imag(count)) <= 1e-8`.
- Counts from the two quadrature sizes and two radii differ by at most `1e-8`.
- The minimum relative singular value on every contour is at least `1e-4`.

Failure labels are `CONTOUR_COUNT_NOT_ONE` and `CONTOUR_NOT_SEPARATED`.

### Root qualification

- Roots obtained from the scan, moment, and complex-perturbed seeds differ by at most
  `1e-10`.
- The error against the analytic branch is at most `1e-10`.
- The relative smallest singular value and both null-vector residuals are at most `1e-11`.
- The second singular value divided by `max(1,norm(F_level,2))` is at least `1e-3`.
- `abs(root_slope) >= 1e-2`.
- The bordered-system reciprocal condition estimate is at least `1e-12`.
- The projected derivative spread is at most `1e-7` and agrees with the exact derivative.
- Both phase-invariant analytic direction errors are at most `1e-8`.

The second-smallest singular value is `singular_values(end-1)` because MATLAB and Octave
return singular values in descending order. Newton stops successfully only when both
`abs(step) <= 1e-12 * max(1,abs(k))` and `abs(implicit_determinant) <= 1e-12`; otherwise it
fails after 20 iterations. For each frozen centered-difference step, the full derivative
must satisfy
`norm(dFdk_fd-dFdk,2) / max(1,norm(dFdk,2)) <= 1e-8`, in addition to the projected spread
gate.

Stable failure labels include `ROOT_NOT_REPEATABLE`, `ROOT_RESIDUAL`,
`MULTIPLE_OR_DEFECTIVE_ROOT`, `SMALL_TRANSVERSE_SLOPE`,
`BORDER_ILL_CONDITIONED`, and `DERIVATIVE_UNSTABLE`.

### Estimator

- `abs(delta_root) <= 0.05 * eta_map` for every accepted positive row.
- If `abs(root_increment) < 100 * eps * max(1,abs(k_root))`, consistency is marked
  `NOISE_FLOOR`; otherwise it is evaluated normally.
- `linearization_consistency` decreases strictly over the evaluated rows and is at most
  `1e-4` in the last row.
- `tail_effectivity` moves toward one and satisfies
  `abs(tail_effectivity(end)-1) <= 1e-3`.
- The signed `delta_map` and signed matched root increment have the same direction.
- Complex `delta_map` agrees with its analytic formula within
  `1e-10 * max(1,abs(delta_map_oracle))`.
- `delta_total` agrees with `delta_root + delta_map`, and with the independent direct
  projection of `F_next`, using the same mixed tolerance.

The output label is always `conditional/empirical`; no certified interval is emitted.

## Negative cases

1. `REAL_AXIS_DIP_ONLY`: use $k_0=1.7$ and $\tau=0.03$. The real scan minimum is
   approximately $\tau$; a contour of radius `0.015` counts zero and a contour of radius
   `0.06` counts one complex root at $k_0-\mathrm{i}\tau$.
2. `LEVEL_SCALING_REJECTED`: replace $F_j$ by $2^jF_j$. Roots remain unchanged within
   `1e-10`, but the forced projected correction is twice the common-representation value
   and the metadata gate rejects the hierarchy. The normal path records `level_scale=1`;
   the negative path records `level_scale=2^j`, while both row and column fingerprints are
   preserved. The shared metadata gate, rather than a hard-coded result assignment, must
   emit the failure label.
3. `CONTOUR_COUNT_NOT_ONE`: apply a radius-`0.1` contour centered at `k_star + 0.6` to
   $F_\infty$; the count is zero and no estimator is reported.
4. `ROOT_ERROR_DOMINATES`: at estimator level 3 use the deterministic polluted point
   $\widetilde k_3=k_3+10^{-4}$; the root correction must exceed `0.05 * eta_map` and the
   map-only interpretation is rejected.

## Output artifacts

All generated artifacts are stored under `test/eig-apost-nep/output/`:

- `config.txt`: frozen parameters, thresholds, representation tag, and theory version;
- `levels.csv`: root and estimator rows with raw diagnostics, complex corrections, and
  gates;
- `contours.csv`: all four contour counts and boundary-separation values at every root
  level;
- `checks.csv`: derivative, direction, oracle, total-correction, and root-dominance checks;
- `negative-cases.csv`: expected and observed negative-case labels;
- `effectivity.svg`: deterministic two-panel effectivity and consistency visualization written
  without GUI plotting;
- `run.log`: deterministic stage log and final status;
- `results.mat`: complete result structure;
- `report.md`: experiment question, method, results table, failures, interpretation, and
  claim boundary.
- `reproducibility.txt`: external exit codes and SHA-256 comparison for the two final runs.

The final stdout line is exactly `ALL TESTS PASS` or `TESTS FAILED`.

`levels.csv` stores every complex root, slope, increment, and correction in separate
`*_real` and `*_imag` columns. Every downstream group also has an `available` column and a
stable status string; unavailable values are written as `NaN`, never as zero. The run
configuration records the Git base and SHA-256 content hashes of the governing theory,
design documents, and experiment source, because the theory working tree is not clean.

## Exact execution command

Run from `/Users/whc/Documents/Work/epost`:

```text
conda run -n octave octave --quiet --no-gui --eval "cd('/Users/whc/Documents/Work/epost'); addpath(pwd); addpath(fullfile(pwd,'test','eig-apost-nep')); results=run_manufactured_nep(); assert(results.all_pass);"
```

The command is non-interactive. The run is stopped if it exceeds 1,800 seconds or if an
upstream gate fails in a way that makes downstream quantities unavailable.

## Reproducibility check

After the first successful run, execute the same command a second time. Compare exact
numeric contents and byte equality for `config.txt`, `levels.csv`, `contours.csv`,
`checks.csv`, `negative-cases.csv`, `effectivity.svg`, `run.log`, and `report.md`.
`results.mat` is checked by reloading its numeric fields because MAT-file metadata need not
be byte-identical. Timing data are not part of the reproducibility comparison. The external
exit codes and final hashes are stored in `reproducibility.txt`.

## Interpretation rules

- Passing roots and gates verifies the implementation only on this analytic polynomial
  hierarchy.
- Decreasing consistency error supports the signed first-order next-level predictor.
- Effectivity approaching one supports the conditional finite-dimensional asymptotic
  formula.
- A failed gate remains a failed result; thresholds are not retuned after inspection.
- No output may claim that BIE map convergence, physical guided modes, branch continuation,
  pole exclusion, saturation, or a reliable interval has been verified.

## Post-experiment analysis

### Evidence reviewed

The Researcher reviewed the frozen design, symbol ledger, experiment plan,
[[research/projects/eig-apost/implementation/archive/i0-manufactured/nep-review|manufactured NEP skeptic review]],
implementation, retained `pilot-01` and `formal-01` evidence, and final numeric artifacts.
No additional computation was performed for this analysis.

The accepted numerical sequence was:

| $j$ | linearization consistency | tail effectivity | root error |
|---:|---:|---:|---:|
| 0 | $4.486237\times10^{-2}$ | $0.794262746$ | $3.81\times10^{-18}$ |
| 1 | $1.218700\times10^{-2}$ | $0.949677353$ | $1.15\times10^{-14}$ |
| 2 | $7.800293\times10^{-4}$ | $0.996873777$ | $1.33\times10^{-14}$ |
| 3 | $3.051746\times10^{-6}$ | $0.999987793$ | $1.78\times10^{-15}$ |

Because $\varepsilon_{j+1}=\varepsilon_j^2$, the finite-level mismatch between
$\delta_j^{\mathrm{map}}$ and the matched increment is a nonzero Taylor remainder. Its
rapid decrease is therefore stronger evidence than an exact algebraic identity. The
effectivity values agree with the analytic manufactured oracle and approach one from below
for the frozen $c$ and $\theta$.

All root levels passed contour, repeated-root, analytic-oracle, bilateral-residual,
analytic-direction, slope, derivative, and bordered-conditioning gates. All four negative
cases produced their pre-registered labels. In particular, level-dependent scaling changed
the correction by the predicted factor two, while the deterministic polluted root produced
a root-to-map ratio of approximately $6.55$ and was rejected.

Pilot-01 remains meaningful negative evidence: the resolution increase was needed for the
nearby radius-$0.32$ contour. `formal-01` separates numerical validity from artifact
validity because its numerical gates passed while its CSV header was malformed. Neither
run was discarded.

### Researcher decision

**GO for closing the manufactured experiment under a narrow claim.** The
fixed-dimensional NEP search and conditional projected-correction pipeline is an initial
Octave prototype. The evidence does not show that the periodic-waveguide BIE/DtN algorithm
has been implemented.

The result remains parameter-dependent: the strict trends use one $2\times2$ triangular
polynomial model, one hierarchy, and contours chosen with exact root knowledge. The model
has no BIE pole, branch discontinuity, representation nullspace, or independent common
discretization error. The left-vector factor also cancels from the projected quotient, so
the direction checks do not test general nonnormal left-vector sensitivity.

The next gate is to close the actual augmented-operator formulation: row-by-row BIE and
lead-block mapping, kernel--field equivalence, level-independent representation, analytic
branch convention, complete pole ledger, and map convergence must precede a physical
effectivity study.
