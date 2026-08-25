# I3.2 same-certificate evaluation cap (`ecap-a2` Revision E)

Status: both formal attempts are consumed. `ecap-a1` is an implementation
failure; `ecap-a2` is a valid resource-limited negative result with status
`I3_2_RESOURCE_BUDGET_UNAVAILABLE / EMPIRICAL_CAP_UNRESOLVED`. The staged
input and both output directories are immutable. No rerun is authorized by
this file.

## Purpose

This experiment re-evaluates the immutable `fbie-a1` finite certificate at
pre-registered nested action levels. It never re-solves the candidate, QZ
state, propagation coordinates, wall density, circle density, Schur system,
or proxy chart. Its best possible result is an ordinary same-trial empirical
evaluation cap and `EMPIRICAL_NOMINAL_TRANSFORM`; every rigorous, reliable,
existence, gap, and independent-reference flag remains false.

`M=48` defines only the 97 retained QZ wall-input modes. The fixed wall
density has 512 coefficients; fresh wall outputs use 1024/2048/4096 modes.

## Files

- `stage_fbie_input.py`: separately authorized non-MATLAB host-side whitelist
  extractor. It may read the immutable historical result, but formal numerical
  code never calls it.
- `check_e_cap.m`: sole formal entry, runtime contract, schema, resource
  ledger, exact integer-storage normalization, statuses, and report.
- `i32_same_eval.m`: fixed-density harmonic-image and wall/circle actions,
  lift factors, actual fixed-density $T_{\mathrm o}^{QP}-T_{\mathrm i}$
  action/decomposition records, finite-image physical Bloch checks, and
  analytic qualification oracles. The Linton mixed-normal reference contracts
  its analytic physical Hessian and does not use a target finite difference.
- `i32_cap_tail.m`: canonical positive factors, full-matrix contractions,
  empirical remainder rules, and nominal transform.

## Consumed host staging

The source and target paths were explicit host inputs. The successful retry is
consumed and must not be rerun; the staged target now exists and is immutable.
The command below is historical and illustrative only. Its append-only outcome
is governed by
[[research/projects/eig-apost/implementation/i3/amend-3-2b-d|the staging-success event contract]];
rerunning it is forbidden.

```console
python3 test/i3/e-cap/stage_fbie_input.py \
  --source test/i3/fb-resid/output/fbie-a1/result.mat \
  --target test/i3/e-cap/input/fbie-a1-certificate.mat
```

The isolated host environment provided SciPy after the first dependency
failure. The extractor converts the branch classification to a fixed `int8`
encoding, rejects any source whose SHA-256 differs from the consumed `fbie-a1`
artifact, and publishes the target without overwrite. It stages the raw `J`,
`QL/QR`, circle value-jump, circle normal-jump, and common-wall maps needed for
final-coordinate remapping; already weighted lead factors are audit anchors,
not substitutes for raw maps. Host provenance is a separate MAT variable;
the formal entry loads only `staged` and therefore never reads provenance.

## Consumed Revision E formal command

The command below is a historical audit record. It consumed `ecap-a2` and
must not be run again.

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','e-cap')); check_e_cap('ecap-a2',fullfile(pwd,'test','i3','e-cap','input','fbie-a1-certificate.mat'));"
```

The formal entry reads only the explicit staged input. It does not read or
hash historical output, Git, Markdown, manifests, or repository metadata.
The consumed `ecap-a1` attempt saved an execution-unavailable result after an
integer/double identity-arithmetic failure; its later unsupported report-open
permission caused shell exit 1, so its report is absent. Revision E uses schema
`TEP_I3_2_SAME_TRIAL_EVALUATION_CAP_REV_E`, records that exact prior history,
and changes no scientific configuration. Its immutable outputs are
`output/ecap-a2/result.mat` and `output/ecap-a2/report.md`.

Frozen levels are circle 512/1024/2048, symmetric images
32/48/64/96/128/192/256, wall outputs 1024/2048/4096, Riccati
512/1024/2048, radial Gauss 32/64/128, and full-P 8/16/32. Expected runtime is
13--23 minutes. Preflight refuses estimates above 25 minutes or 520 MiB;
soft/hard limits are 1500/1800 seconds and 640 MiB.

## Post-run outcome

`ecap-a2` passed certificate identity and completed the same-trial evaluation
levels, but retained active memory reached 664.47068214416504 MiB and exceeded
the 640 MiB hard limit before cap assembly. Full-P contraction, empirical cap,
$q$, and interval were not reached. The completed evaluation also recorded
three nonblocking qualification failures:

- actual fixed-density Delta-T image contraction ratio
  2.2946515117026931 versus 0.80;
- finite-image physical Bloch value/flux maximum ratio
  0.071741947137921119 versus $10^{-10}$;
- analytic-kernel oracle aggregate `Inf`, including an unavailable Linton
  oracle and failed free-singular/high-order recurrence checks.

The top-level coverage and no-resolve summaries remain their early-stop
defaults. Audit reached work from `evaluation.record` and `call_counters`, not
those defaults. This attempt produced no empirical evaluation cap, nominal
transform, strict cap, reliable enclosure, spectral interval, independent
reference, effectivity result, or eigenvalue-existence claim. The independent
post-run review is
[[research/projects/eig-apost/implementation/i3/review-3-2b|review-3-2b]].
