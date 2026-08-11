# eig-apost experiments

The current eig-apost implementation route starts at I1. Experiment IDs are stable even if a
directory later moves; this index and current-facing README files then follow the new path, while
frozen outputs retain their recorded paths and hashes.

## I1-HG-ADEF-V1

| Field | Value |
|---|---|
| Experiment ID | `I1-HG-ADEF-V1` |
| Stage | I1.2 |
| Purpose | Joint manufactured, low-order, and direct $M=48$ half-guide-to-$A_{\mathrm{def}}$ verification |
| Current path | `test/i1/hg-adef/` |
| Entry point | `make_prod('full')`, then `run_prod('full')` in MATLAB |
| Authoritative report | [[test/i1/hg-adef/output/prod-full/report|MATLAB M48 static report]] |
| Status | `I1_2_M48_PASS_WITH_CONDITIONS / EMPIRICAL I1.3 READY` |
| Implementation summary | [[research/projects/eig-apost/implementation/i1/README|current I1 guide]] |

Future current-route experiments belong under `test/i1/` and receive an index entry only after
they are designed and authorized. A legacy verdict never becomes a current stage gate.

The complete former I0--I4 experiment bundle, including its original index, scripts, configurations,
reports and frozen outputs, is preserved at
[[test/archive/legacy-route-v1/README|legacy route v1 experiment index]]. Historical paths, hashes
and manifests inside that archive remain unchanged.
