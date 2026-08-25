# Fixed-family root count (`k-count`)

## Material Passport

- Experiment ID: `I2-K-COUNT-M1B-V1`
- Stage: I2.1, same-discrete-object single-root isolation
- Design ID: `I2.1-M1B-RIESZ-COUNT-V1`
- Runtime: MATLAB with the public `lsqminnorm` implementation
- Current status: `I2_1_PASS_WITH_CONDITIONS / M1-A1 REVIEWED`
- Scientific status: `CONDITIONAL EMPIRICAL FINE-M48 COUNT ONE`
- Authoritative design: [I2.1 frozen design](../../../research/projects/eig-apost/implementation/i2/design.md)

## Question and claim boundary

This experiment asks whether the I1 dip disk contains exactly one determinant
zero of the same frozen fine, $M=48$ finite-dimensional family.  The primary
object is the unbalanced $194\times194$ matrix $A_{\mathrm{def}}^D(k)$ from the
I1.4 evaluator contract.  The disk has

$$
k_c=1.8327703475952146,
\qquad
r_0=3.8146972647368216\times10^{-7}.
$$

The count is not allowed to conflate a defect zero with a proxy, BIE,
generalized-pencil resolvent, fixed-section, or Dirichlet-factor zero.  Method
1B therefore records each true inverse factor separately and uses a
gauge-free Riesz-projector screen to qualify the fixed-row QZ section before
interpreting the main winding.

Even a complete pass supports only this conditional empirical statement:

> Under the frozen fine-$M=48$ evaluator and the sampled analytic/fixed-chart
> qualification in the design, the specified disk contains one zero of
> $\det A_{\mathrm{def}}^D(k)$, counted with algebraic multiplicity.

It does not locate the zero, prove geometric or derivative-qualified
simplicity, reconstruct a continuous guided mode, establish a continuous
physical eigenvalue, or produce a posterior error estimator.

## Reviewed result

The append-only `m1-a1` full run and its independent post-run audit support the
stated conditional claim.  The 32- and 64-node windings of the primary matrix
were respectively `1` and `0.99999999999999967`, both rounding to one, while
all 72 non-primary inverse/section factors had nested zero winding.  All 26
registered gates passed and no failure row was produced.

The strongest numerical margins that must travel with this result are:

- the largest primary phase-edge guard was `0.23553908737844675 < pi/2`;
- the largest sampled zeta-arc guard was `0.15228769229139186 < 0.5`;
- the largest bidirectional k-edge ratio was `8.850952770931059e-8 < 0.25`;
- the smallest boundary `AdefD` reciprocal condition estimate was
  `4.142158060143257e-9`, about 96 times its frozen lower bound;
- the proxy reduced factor was much tighter: its minimum reciprocal condition
  estimate was `1.0481727407734721e-8`, only about 4.82 percent above the
  frozen `1e-8` gate;
- the largest Riesz range difference was `6.989264130329236e-8 < 1e-7`.

The sampled arc screens and nested agreement are deliberately empirical.  In
particular, they do not prove a continuum supremum bound or exclude every
possible unsampled narrow excursion.  This is an important claim-boundary
caveat, not a blocker for the reviewed finite-dimensional I2.1 result.

## Frozen method and non-circular checks

- The 64-point counterclockwise $k$ contour contains a strict 32-point nested
  subset; the 32-point unit-circle Riesz quadrature contains a strict 16-point
  nested subset.
- Stable complex-LU phase data include permutation parity, log magnitude,
  reconstruction residual, reciprocal condition estimate, and every closure
  edge.  A raw determinant is never formed.
- The true inverse factors are the affine proxy reduced matrix, $A_{QP}$,
  original/reversed unit-circle resolvents, the fixed-section matrices
  $C_{\pm,16/32}$, and the two normalized Dirichlet matrices.
- Sampled Neumann guards resolve both the $\zeta$ direction and both directions
  of every adjacent $k$ edge.  They are empirical resolution checks, not a
  continuum no-pole theorem.
- Before any physical evaluator call, the production counting and Riesz cores
  must pass manufactured cases with analytically known counts $0$, $+1$,
  $-1$, and $2$, a boundary-singular failure, and an exact original/reversed
  $2\times2$ Riesz range.  This prevents the expected physical answer from
  defining success.

## Source layout

| File | Responsibility |
|---|---|
| `cfg_i21.m` | Frozen object, contours, thresholds, lineage, output tags, and resource limits |
| `run_i21.m` | Append-only campaign runner, gate order, streaming ledgers, and mechanical report |
| `count_core.m` | Shared LU, solve-residual, phase, closure, and winding arithmetic |
| `riesz_core.m` | Shared weighted Riesz actions, fixed-section parity, and two-axis guards |
| `eval_i21.m` | Fine-only I1.4 evaluator exposing the exact factors used by Method 1B |
| `i21_kproxy.m` | I1.4 affine proxy helper with the actual reduced factor exposed |
| `kproxy.m`, `kchan.m`, `kgreen.m`, `kbie.m` | Test-local anchored I1.4 construction helpers |

Dense matrices are transient.  The runner retains only the current endpoint,
the previous endpoint, and the first endpoint needed for contour closure; it
does not form a Sylvester/Kronecker auxiliary problem.

## Authorization and run sequence

The first append-only smoke, `smoke-a1`, stopped at the seed with
`i21:ProxyGate`; it is preserved as a failure and supports no root count.
Post-run review found a numerically unstable but exact-arithmetic-equivalent
projector-repeat transcription and an incomplete failure-log contract.  The
same-Method-1B Revision 1 fixed only those implementation/evidence issues.
Its append-only `smoke-a2` passed independent pre-run and post-run review.  It
supports implementation and resource readiness only, not a root count.

Revision 2 separates the accepted smoke artifact hash, its producer digest,
and the full-run freeze.  After an independent Revision 2 pre-run review, the
sole registered full command from the repository root was:

```sh
matlab -batch "addpath(fullfile(pwd,'test','i2','k-count')); run_i21('full');"
```

The accepted `smoke-a2` attempt ran the shared manufactured cores and seed plus four physical
cardinal nodes.  It also timed the three successive cardinal connections and
their closure, then scaled the mean edge cost to all 64 full-run edges.  These
non-adjacent cardinal edges are workload/interface probes only: they are not
written to the scientific k-arc ledger and their 0.25 ratios are not
interpreted.  The smoke produces no
scientific winding verdict.  It completed in 34.740040375 s, projected full at
425.46625704166667 s, and measured 180.33086967468262 MiB across 13 checkpoints.
That command was run once for `m1-a1` and returned successfully.  It is a
preserved reproduction command, not authorization to rerun the append-only
tag.  Any future experiment requires a new design, review, and output tag.

Existing output directories are a hard failure; retries require a separately
reviewed new append-only tag.  No run may silently change the radius, nodes,
thresholds, object, solver, rank, chart, branch, or method.

## Resource contract

| Run | Target | Hard stop | Current use |
|---|---:|---:|---|
| smoke | 120 s | 300 s | `smoke-a1` failed at 2.8188827916666668 s; `smoke-a2` passed at 34.740040375 s |
| full | 1200 s | 1800 s | `m1-a1` passed at 412.089480375 s; peak 197.61942958831787 MiB |
| all formal I2.1 runs | -- | 7200 s total | 450.64840354166665 s, including the approximately 1 s startup failure |

The largest square matrix is $512\times512$.  The collocation proxy array is
$960\times450$, while the diagnostic-only shifted proxy residual array is the
actual largest rectangular dense array at $1920\times450$; both shapes are
checked in the runtime object contract.  The frozen streaming memory bound is
512 MiB.  A smoke projection above 1500 s stops the campaign before full.  Its
projection records fixed, physical-node, and 64-edge components separately.

## Evidence organization

The registered output tags are the preserved `output/smoke-a1/` failure,
the accepted `output/smoke-a2/` readiness run, and the reviewed
`output/m1-a1/` full run. Each attempt, including a failure or resource stop, must
preserve a compact `result.mat`, mechanical `report.md`, `run.log`, raw CSV
ledgers, source hashes, configuration/object ledgers, lineage, and the first
failure.  Outputs are never overwritten or hand-edited.

| Output tag | Role | Status |
|---|---|---|
| `smoke-a1` | Preserved first smoke | `FAIL: EVALUATOR_FAILURE / i21:ProxyGate` |
| `smoke-a2` | Revision 1 smoke | `PASS WITH CONDITIONS: READINESS ONLY / NO ROOT COUNT` |
| `m1-a1` | Full 64-node factor-aware root count | `PASS WITH CONDITIONS: CONDITIONAL EMPIRICAL COUNT ONE` |

Authoritative evidence entry points:

- [`smoke-a1` report](output/smoke-a1/report.md): preserved evaluator failure;
- [`smoke-a2` report](output/smoke-a2/report.md): accepted readiness-only smoke;
- [`m1-a1` report](output/m1-a1/report.md): reviewed full count and resource summary.

The first attempted MATLAB launch, before `smoke-a1`, exited with code 137 at
the sandbox startup layer after approximately one second and did not enter the
runner or create an output directory.  It is retained in the campaign history
and formal time budget, but no durable runner artifact exists for that startup
failure.  The later `smoke-a1` failure, its implementation-drift diagnosis,
the accepted `smoke-a2`, and `m1-a1` have not been overwritten or removed.

The implementation summary and review documents link only to this page, not
to individual code, CSV, MAT, or log files.

The source manifest records the producer-time README hash for provenance, while
the executable implementation digest excludes later README-only status edits.  The
accepted smoke artifact and its producer digest remain immutable parent
evidence.  Before `m1-a1` ran, any Revision 2 design, MATLAB, configuration, or
helper edit would have invalidated that pre-full review and required a new
freeze.  The reviewed `m1-a1` artifact and its producer freeze are now kept
immutable.

## Frozen I1 lineage

The runner verifies the recorded SHA-256 values of the I1.3 `zoom2` candidate,
the I1.4 affine/QZ pilot, the V4 positive sampled-disk parent, and the V5
conditional negative closure before using their row selectors or readiness
claims.  I1 remains `PASS WITH CONDITIONS`; no I1 artifact is modified or
retroactively reinterpreted as a root count.

## Static freeze

The implementation submitted for the independent pre-run consistency review
is identified by the SHA-256 digest printed below.  Any source edit invalidates
the review and requires a new digest; this is not a run result or an
authorization.

- Revision 2 implementation freeze digest: `4b60840ea14210d51754f7fbe3f839266eab8a399ff7682202326c61c2d913c4`
- Freeze manifest: `freeze.sha256` (design plus all MATLAB sources; README and
  the manifest itself are excluded to avoid a circular digest)
- Freeze date: `2026-08-13`
- Preserved MATLAB/Octave command attempts for I2.1: `4 / 0`
  (one startup-layer exit 137 before the runner, one failed smoke, one accepted
  smoke, and one reviewed full run)
- Reviewed `m1-a1/result.mat` SHA-256:
  `da1cd8097e9c22c0a4cdd3600f37454bbf2e50274604f894e51d3a54b19bac79`
