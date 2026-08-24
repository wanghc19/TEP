# I3.1 full-boundary cell-BIE residual

Status: formal `fbie-a1` completed and consumed; post-run verdict
`PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED`; no rerun.

This directory implements
[[research/projects/eig-apost/implementation/i3/design-3-1f|design-3-1f]].
The append-only output contains `result.mat` and `report.md`.  The independent
scientific interpretation is
[[research/projects/eig-apost/implementation/i3/review-3-1f|review-3-1f]].

Source boundaries:

- `check_fb_resid.m`: frozen candidate/QZ state, runtime guards, result
  schema, status, and report;
- `i31_full_bie.m`: full-order wall single layers, circle Müller Schur solve,
  common-grid actions, and independent actual-$\Delta T$ reference.
- `i31_bdry_est.m`: boundary weights, value-lift factors, positive Grams,
  full-matrix tails, the indicator candidate, and phase/scale repeat.

Consumed command (audit record only; do not rerun):

```text
matlab -batch "addpath(fullfile(pwd,'test','i3','fb-resid'),fullfile(pwd,'test','i2','k-count')); check_fb_resid('fbie-a1');"
```

The producer computed $q=1.0318643108971929\times10^{-10}$ and the ordinary
nominal interval `[1.83277028891904, 1.8327702892972739]`.  The sole internal
qualification failure is the circle-action 256--512 ratio
`0.77408786032496468 > 0.20`; all reliability and existence flags remain false.
`M=48` defines input wall traces only.  All 512 computed circle modes enter the
residual, and the angular-tail gate passed; the descriptive outside-$M$ share is
`0.036178900402764308`.  Uncomputed Fourier tails remain unenclosed for I3.3.

Artifact SHA-256:

- `result.mat`: `276d1c52ed4ca6f522c47359e22771a63d23a8d9b5b5ca0443d32f66417b1592`;
- `report.md`: `f4983741c39f44be3edf3e1d75c239cbbb5a182c9c2690f85350549679e11f63`.
