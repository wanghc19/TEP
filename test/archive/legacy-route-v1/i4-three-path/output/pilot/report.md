# I4 three-path experiment

- Mode: `pilot`
- Status: `PILOT_TIMING_ONLY`
- Started: `2026-08-09 21:33:05`
- Finished: `2026-08-09 21:33:08`
- Total wall time: `3.127007 s`
- Wood distance $\min_m |\gamma_m|$: `1.7919193743411763e+00`
- Circle-to-wall clearance: `2.9999999999999999e-01`

## Frozen conventions

The local Linton helper consumes physical separations $(X,Y)=(x_t-x_s,y_t-y_s)$ directly, with $Y$ periodic. Only the package first-coordinate-periodic MFS wrapper uses `[y;x]`. Linton uses source $+\delta$ and free kernel $-\mathrm{i}H_0^{(1)}/4$; the project uses source $-\delta$ and free kernel $+\mathrm{i}H_0^{(1)}/4$. Therefore $G_{\mathrm{project}}=-G_{\mathrm{Linton}}$. Both use the $\exp(-\mathrm{i}\omega t)$ outgoing convention and a target shift by $+d$ has factor $\exp(+\mathrm{i}\beta d)$.

The branch ledger is `Rayleigh gamma=sqrt(k^2-beta_m^2), Im(gamma)>=0; Linton q=sqrt(beta_m^2-k^2), evanescent q>0 and propagating q=-i gamma`. The SLP-D field is $u=-\int G\rho\,ds$, consistent with `eta=[tau;-sigma]`. The local Ewald path exposes real-space and reciprocal-space contributions and has no Rayleigh fallback.

## Gates

| Gate | Value | Tolerance | Pass | Mandatory |
|---|---:|---:|---:|---:|
| pilot_no_scientific_verdict | NaN | NaN | 1 | 0 |

## Decision matrix

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| pilot | IMPORTANT CAVEAT | PILOT_TIMING_ONLY | 1 | Use the estimate before any full SLP-D wall evaluation. |
| pilot_triangle_observation | IMPORTANT CAVEAT | TIMING_ONLY_TRIANGLE_OBSERVATION | 0 | E-P=4.692e-08, E-R=1.346e-16, P-R=4.692e-08; E-R closes while base P differs, but pilot resolution cannot certify a path. |
| SLP-N/DLP-D/DLP-N | IMPORTANT CAVEAT | NOT_RUN_PREREQUISITE | 0 | Derivative layers remain stopped. |

## Pilot interpretation

Pilot uses `ntot=32`, `Ny=64`, and `M=12`. It is a timing-only run and supplies no scientific verdict. The full ladder central estimate is `524.4 s` with a simple pilot scaling range of `419.5--786.6 s`. See `runtime-estimate.md`.

Later SLP-N/DLP-D/DLP-N stages are not run in this delivery unless separately implemented after SLP-D certification.
