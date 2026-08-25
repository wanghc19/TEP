# I3.2 REV_F paused-state record

Date: 2026-08-25

Status: **PAUSED BY USER / NO FORMAL ATTEMPT RUN**

This file records the complete restart state after the user requested that the
current work stop. It is a handoff record only. It does not amend the frozen
scientific design, authorize an experiment, or constitute a review PASS.

## 1. Attempt and execution state

- The reserved attempt is `ecap-a3`.
- `test/i3/e-cap/output/ecap-a3` is absent.
- The attempt tag has not been consumed.
- No MATLAB, Octave, smoke, `checkcode`, or formal experiment was run for REV_F.
- Historical design, review, implementation, and `pbie-a1`/`pbie-a2`/`ecap-a1`/`ecap-a2`
  outputs were not changed or rerun.
- The Engineer was interrupted before the requested repair produced any file
  change. All implementation hashes remain those of the second freeze below.

## 2. Authority and gate state

- Researcher--Engineer design agreement: complete.
- Skeptic DESIGN PASS: complete for the exact design hash below.
- Second-freeze Researcher implementation mapping: **REVISE**.
- Skeptic SPEC-TO-CODE review: not started.
- Formal run authorization: absent.
- `review-3-2c.md`: not created because no formal result exists.

The exact frozen design is

```text
design-3-2c.md
SHA-256 1ba6b4cd2a291492deb2924511ea67adec221c0f0f3df42617a9480126c45bba
lines   994
```

## 3. Second-freeze implementation inventory

```text
check_e_cap_stream.m       f7c652d9a3fb0c734e5a56056e3ec8b7fde9a7bccc32f0d46744f1654c00a084  1579
i32_certificate_input.m    f257e746163556e228149bd4d3ad93693c913595c503440e5b614f2ba90f73fa   883
i32_lifting_quadrature.m   7cab043753f133692ea44d4149bd3049accb8852d712d01756590f3708126709   332
i32_wall_module.m          b528af5c0f429ace9eda9c5d25a5f2d1a2e02ff3ddfb0a13aed018063db4efd7   624
i32_circle_module.m        12d2f5bf70fe9e36de21c8812c3da70d9fb2c9284ce8393dbb2e9dda1b3eff5a  1687
i32_fullp_cap.m            d71d2450e99463fae3ee63b5fccb6fc221782c44770ea5d3fcbd8bda713057c6  2088
i32_result_output.m        9cb795ab30811194e30b357a2352919f88f0641a586c6100c56f13c1c437743c   212
```

These files and `design-3-2c.md` are untracked workspace files at the pause
point. Existing tracked files are unchanged.

## 4. Open implementation blockers

The Researcher found exactly three blockers in the reviewed static scope.

1. Parity helpers call the full-$P$ tail routine again instead of reusing the
   live projected action blocks and tail slots. The successful path therefore
   has 88 unrecorded tail sequences in addition to the frozen 292-sequence
   ledger. The first real blocker is this contraction drift.
2. Cap parity evidence is deduplicated before the duplicate gate. Consequently,
   a reported zero duplicate count is not falsifiable. A canonical ownership
   registry must be formed and its raw records audited without pre-deduplication.
3. Public shapes are path-checked, but `audit_summary` and private wall/circle
   cap signatures still use global terminal-name unions. Their schema must be
   restricted by module, top branch, immediate child, and object kind so that a
   known field at the wrong path fails closed.

The requested repair was deliberately not completed after the stop request.
No spec-to-code claim applies to the present files.

## 5. Static items already established

The second mapping found no drift in the frozen certificate, trial, levels,
thresholds, actual-$\Delta T$ action, finite-image Bloch checks, kernel oracles,
main cap formulas, combined-volume Gram-before-tail rule, field candidate,
$q_{\rm emp}$ formula, or false reliability/certification flags. It also found
the 292 category table, 274 small-Gram eig calls, 6 Golub--Welsch eig calls, and
280 allowlisted eig calls represented in the declared ledgers. These are static
mapping observations, not runtime validation.

## 6. Feasibility of one-cap experiment units

It is scientifically and computationally feasible to estimate one empirical
cap at a time, but that would be a new execution contract rather than a run of
the frozen REV_F entry. A future split should use independently reviewable
units such as:

| Unit | Primary empirical output | Required scientific work |
|---|---|---|
| wall | $\epsilon_{\mathrm w}^{\rm emp}$ | frozen wall trace evaluation, wall nested differences, wall action and quadrature diagnostics |
| circle | $\epsilon_{\Gamma}^{\rm emp}$ | circle value/normal nested differences plus the frozen actual-$\Delta T$, Bloch, and kernel-oracle gates |
| lifting/volume | $\epsilon_{\mathrm{vol}}^{\rm emp}$ | frozen lifting/quadrature levels and the required compact wall/circle value factors |
| full-$P$ | $\epsilon_P^{\rm emp}$ | frozen $P_\pm$ actions and compact endpoint/pair factors; the 292 contraction ledger and parity gates remain mandatory |
| field lower | $\epsilon_N^{\rm emp}$ and the field-lower candidate | the frozen field factors and nested field evaluation only |

The wall and circle units can run cold from the immutable staged certificate.
The lifting/volume, full-$P$, and field-lower units depend on compact factors
derived from wall or circle data. There are two defensible execution models:

1. Each unit reloads the frozen certificate and recomputes only its required
   predecessors. This minimizes peak memory and keeps attempts independent, but
   duplicates some CPU work.
2. Producer units publish immutable compact handoff artifacts containing only
   audited finest factors, compact metrics, source hashes, and gate summaries.
   Consumer units then load those exact artifacts. This saves repeated work but
   requires a new handoff schema, source/result hashes, consumer rules, and
   append-only attempt tags. It is incompatible with silently reusing the
   current REV_F output contract.

The preferred direction for limiting both peak memory and wall-clock failure
risk is the second model, with one append-only attempt per scientific unit and
an optional final aggregation attempt that performs no dense reconstruction.
It must be specified in a new design/review cycle before any run. No new tag is
allocated by this pause record.

## 7. Exact restart gate

If REV_F is resumed unchanged, repair the three blockers, freeze new hashes,
obtain a Researcher mapping PASS and a Skeptic SPEC-TO-CODE PASS, optionally run
read-only `checkcode`, confirm `output/ecap-a3` is still absent, and only then
consider the unique formal command in `design-3-2c.md`.

If the one-cap split is selected instead, leave REV_F and `ecap-a3` untouched,
create a new design with new append-only tags and explicit compact handoff
contracts, repeat the Researcher--Engineer--Skeptic gates, and run only the
selected empirical-cap unit.
