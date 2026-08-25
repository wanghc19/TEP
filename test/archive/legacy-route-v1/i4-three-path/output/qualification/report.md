# I4 three-path experiment

- Mode: `qualification`
- Status: `EWALD_REFERENCE_CERTIFIED`
- Started: `2026-08-10 10:33:54`
- Finished: `2026-08-10 10:33:55`
- Total wall time: `1.130316 s`
- Wood distance $\min_m |\gamma_m|$: `1.7919193743411763e+00`
- Circle-to-wall clearance: `2.9999999999999999e-01`

## Frozen conventions

The local Linton helper consumes physical separations $(X,Y)=(x_t-x_s,y_t-y_s)$ directly, with $Y$ periodic. Only the package first-coordinate-periodic MFS wrapper uses `[y;x]`. Linton uses source $+\delta$ and free kernel $-\mathrm{i}H_0^{(1)}/4$; the project uses source $-\delta$ and free kernel $+\mathrm{i}H_0^{(1)}/4$. Therefore $G_{\mathrm{project}}=-G_{\mathrm{Linton}}$. Both use the $\exp(-\mathrm{i}\omega t)$ outgoing convention and a target shift by $+d$ has factor $\exp(+\mathrm{i}\beta d)$.

The branch ledger is `Rayleigh gamma=sqrt(k^2-beta_m^2), Im(gamma)>=0; Linton q=sqrt(beta_m^2-k^2), evanescent q>0 and propagating q=-i gamma`. The SLP-D field is $u=-\int G\rho\,ds$, consistent with `eta=[tau;-sigma]`. The local Ewald path exposes real-space and reciprocal-space contributions and has no Rayleigh fallback.

## Gates

| Gate | Value | Tolerance | Pass | Mandatory |
|---|---:|---:|---:|---:|
| linton_tables | 5.074660e-11 | 5.000000e-10 | 1 | 1 |
| ewald_M1_change | 0.000000e+00 | 2.000000e-09 | 1 | 1 |
| ewald_M2_change | 5.551115e-17 | 2.000000e-09 | 1 | 1 |
| ewald_N_change | 0.000000e+00 | 2.000000e-09 | 1 | 1 |
| ewald_a_spread | 1.688306e-16 | 2.000000e-09 | 1 | 1 |
| ewald_vs_rayleigh_M96 | 8.326673e-17 | 5.000000e-12 | 1 | 1 |
| quasiperiodic_translation | 6.206335e-17 | 5.000000e-12 | 1 | 1 |
| beta_reciprocity | 0.000000e+00 | 5.000000e-12 | 1 | 1 |
| pure_projection | 1.005739e-15 | 1.000000e-12 | 1 | 1 |
| mutation_wrong_sign_detected | 1.156387e+00 | 5.000000e-10 | 1 | 1 |
| mutation_wrong_axis_detected | 5.592641e-03 | 5.000000e-10 | 1 | 1 |
| mutation_wrong_phase_detected | 1.127548e-02 | 5.000000e-10 | 1 | 1 |
| mutation_translation_phase_detected | 2.551825e-01 | 5.000000e-12 | 1 | 1 |

## Decision matrix

| Stage | Classification | Status | Pass | Note |
|---|---|---|---:|---|
| qualification | MINOR CAVEAT | EWALD_REFERENCE_CERTIFIED | 1 | Qualification certifies value-only Ewald and projection conventions. |
| SLP-N/DLP-D/DLP-N | IMPORTANT CAVEAT | NOT_RUN_PREREQUISITE | 0 | Derivative layers are outside this qualification stage. |

## Qualification interpretation

This result certifies only value-level Linton Ewald, coordinate/sign/phase conventions, and Fourier projection. MFS point discrepancies are reported but are not used to tune or certify the Ewald implementation. The maximum Ewald--MFS error at the five printed Linton points is `5.004061e-09`.

Later SLP-N/DLP-D/DLP-N stages are not run in this delivery unless separately implemented after SLP-D certification.
