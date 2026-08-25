# I4 three-path experiment

- Mode: `slp`
- Status: `SLP_D_UNCERTIFIED`
- Started: `2026-08-09 21:08:54`
- Finished: `2026-08-09 21:17:45`
- Total wall time: `531.181285 s`
- Wood distance $\min_m |\gamma_m|$: `1.7919193743411763e+00`
- Circle-to-wall clearance: `2.9999999999999999e-01`

## Frozen conventions

The local Linton helper consumes physical separations $(X,Y)=(x_t-x_s,y_t-y_s)$ directly, with $Y$ periodic. Only the package first-coordinate-periodic MFS wrapper uses `[y;x]`. Linton uses source $+\delta$ and free kernel $-\mathrm{i}H_0^{(1)}/4$; the project uses source $-\delta$ and free kernel $+\mathrm{i}H_0^{(1)}/4$. Therefore $G_{\mathrm{project}}=-G_{\mathrm{Linton}}$. Both use the $\exp(-\mathrm{i}\omega t)$ outgoing convention and a target shift by $+d$ has factor $\exp(+\mathrm{i}\beta d)$.

The branch ledger is `Rayleigh gamma=sqrt(k^2-beta_m^2), Im(gamma)>=0; Linton q=sqrt(beta_m^2-k^2), evanescent q>0 and propagating q=-i gamma`. The SLP-D field is $u=-\int G\rho\,ds$, consistent with `eta=[tau;-sigma]`. The local Ewald path exposes real-space and reciprocal-space contributions and has no Rayleigh fallback.

## Gates

| Gate | Value | Tolerance | Pass | Mandatory |
|---|---:|---:|---:|---:|
| slp_self_change | 7.523317e-08 | 2.000000e-09 | 0 | 1 |
| slp_pairwise_coefficients | 4.687119e-08 | 1.000000e-08 | 0 | 1 |
| rayleigh_retained_rows | 0.000000e+00 | 5.000000e-14 | 1 | 1 |

## Decision matrix

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| SLP-D | BLOCKER | SLP_D_UNCERTIFIED | 0 | E-R closes while both pairs containing P fail; the current Octave P path is isolated, but its internal cause remains unresolved. |
| SLP-N/DLP-D/DLP-N | IMPORTANT CAVEAT | NOT_RUN_PREREQUISITE | 0 | SLP-D failed, so derivative layers are stopped. |

## SLP-D interpretation

All E-P, E-R, and P-R rows remain explicit in `coefficient-comparison.csv`; weighted aggregation is supplemental and does not replace per-mode maxima. The weighted aggregate is `2.6283625566538629e-11`.

Later SLP-N/DLP-D/DLP-N stages are not run in this delivery unless separately implemented after SLP-D certification.
