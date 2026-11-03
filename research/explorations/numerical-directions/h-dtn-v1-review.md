# Review of the all-trace lower Dirichlet-to-Neumann certificates

Scope and files inspected: Review only of claim (C), with the stated $K_+$ and $K_-$ accepted and rounding excluded; inspected `h-cert-proof.md` §§4.1, 4.2, 4.4–4.5, the two final derivations in `test/numerical-directions/h-dtn-v1/README.md`, `integration-proof.md`, `dtn_native.m`, `dtn_flux.m`, `dtn_integrate.m`, `dtn_run.m`, `dtn_bounds.m`, supporting `dtn_geometry.m`, `dtn_tools.m`, `exact_rt3_basis.m`, `exact_trace_check.py`, `report_dtn.py`, `analysis-input.json`, both certificate JSON files and their run-006/run-008 source records, and `fem-pipeline-v1/direct_native.m` for the physical geometry. Here `h-dtn-v1` denotes version 1 of the Dirichlet-to-Neumann certificates for isolation hypothesis (H).

Result: **0 blockers, 0 important caveats, 0 minor caveats.** The reviewed argument and implementation establish claim (C) under the supplied premises and the exclusion of floating-point rounding.

| Item | Verdict | Check |
|---|---|---|
| §4.1: form inverse and (4.1)–(4.2) | correct | The spectral multiplier $(t+1)/(t-\lambda)$ gives the stated one-sided bounds on the weighted energy space. |
| §4.2: residual definitions (4.3) | correct | The second residual has the required plus sign and its Gram uses the weight $1/\rho$. |
| §4.2: Theorem C.1, (4.4)–(4.5) | correct | Extension orthogonality and the residual Riesz vector give the quadratic error with the stated lower and upper signs. |
| §4.4: high lift, trace and flux admissibility | correct | The cutoff joins have continuous first derivative, and the Fourier bounds extend the construction to every high trace in $H^{1/2}_{\beta_0}$. |
| §4.4: $a_H$, (4.10) | correct | The mode energy is $\kappa_k$ plus a nonnegative cutoff term, and division by $q_k$ gives the stated minimum. |
| §4.4: $b_H^2$, (4.11) | correct | The cutoff derivative bounds, $q_k\ge\kappa_k$, and monotonicity in $\kappa_k$ give the stated residual constant. |
| §4.5: combined field and (4.12), (4.16) | correct | The high residual is $-f_H$, so expansion gives the cross term with $u_c+K_+r_{2,c}$. |
| §4.5: Theorem C.3, (4.13)–(4.15) | correct | The port pairing vanishes by Fourier separation, and completing the square with $A_H>0$ proves the all-trace inequality. |
| §4.5: enclosure directions (4.17) | correct | A lower enclosure of $Q$ and upper enclosures of $R,Z$ give a lower matrix with the stated positive penalty coefficients. |
| New derivation: noncompact Green identity | correct | Compact longitudinal test functions followed by cutoff approximation give the identity for $H^1$ fields and $H(\operatorname{div})$ fluxes without a far boundary term. |
| New derivation: geometric-series tail | correct | Grouping powers into blocks of length $L$ gives the factor $\eta^2/(1-\eta^2)$, including for indefinite Hermitian $H$. |
| New derivation: integration-error amplification | correct | Applying the same sum to $H=I$ bounds the accumulated Loewner error of every per-cell matrix enclosure. |
| New derivation: exact port correction | correct | At the port the correction cancels the actual piecewise polynomial trace; its cutoff and transverse matching preserve $H^1$ conformity. |
| New derivation: $E_H,R_H,Z_H$ beyond the first cell | correct | Fourier orthogonality after uniform material bounds gives the three stated operator bounds for the retained analytic columns. |
| New derivation: uncomputed cross blocks | correct | Energy and residual Cauchy–Schwarz estimates give the stated errors; the factor $\lambda$ in the energy estimate is valid at $\lambda=5.6169>1$. |
| New derivation: replacing $Z_J$ by $Z_\Omega$ | correct | Restriction decreases the Gram in Loewner order, so the full-domain upper enclosure gives a safe lower DtN matrix. |
| New derivation: analytic curve remainder | correct | Midpoint Taylor subtraction and endpoint interpolation give the stated bounds for $\delta,\delta'$ and their exponential-series tails. |
| New derivation: complex Jacobian bounds | correct | The relative deformation bound below one gives the determinant, inverse and Jacobian bounds on the product ellipses. |
| New derivation: global injectivity | correct | The continuous displacement, zero on cell boundaries, extends to a global contraction perturbation of the identity. |
| New derivation: clipping and polynomial exactness | correct | The affine pieces partition the correction regions, while uncorrected affine-cell densities have degree at most eight. |
| New derivation: complex field and matrix bounds | correct | The barycentric, exponential, polynomial and Piola bounds control whole row norms and hence matrix operator norms. |
| New derivation: conjugation and Gauss remainder | correct | Reflection-conjugation gives analytic factors; the tensor Gauss error is bounded by the stated conservative $32M2^{-2q}$. |
| `dtn_native.m`: endpoint field map and cell matching | correct | The wall values $[I;P]$ imply that successive $UP^n w$ fields have identical polynomial traces on their shared wall. |
| `dtn_flux.m`: first and repeated cell flux matching | correct | The fixed edge coefficients impose $N_0=N_bG$ and $F_b=N_bP$ in a common wall orientation. |
| `dtn_flux.m`, `dtn_tools.m`: RT3 orientation and transverse phase | correct | The edge reversal factor $(-1)^{m+1}$ and top-to-bottom factor $e^{0.5\mathrm i}$ enforce the required normal continuity. |
| `exact_rt3_basis.m`: normal traces | correct | All 72 edge/column identities pass an integer-arithmetic check, including zero normal traces of interior columns. |
| `dtn_integrate.m`: $r_1,r_2,z$ and Grams | correct | Residuals and $z=u+K_+r_2$ are formed before the Grams, with the correct material weights and analytic-column residuals. |
| `dtn_integrate.m`: port correction and clipping | correct | The correction uses the actual wall-node polynomial and splits at $\xi=1/8$ and its transverse polynomial intervals. |
| `dtn_integrate.m`: per-element remainders | correct | `LOCAL_uniform` supplies the required complex matrix bounds, including child Jacobians, and all nonpolynomial pieces receive explicit Gauss errors. |
| `dtn_run.m`: `LOCAL_sum` and amplification | correct | Doubling produces matching finite sums and powers; the omitted series and per-cell errors use the stated norm bounds. |
| `dtn_run.m`: $\varepsilon_Q,\varepsilon_R,\varepsilon_Z$ | correct | The first-cell errors, repeated-cell errors, high-column tails and omitted cross blocks are added in safe directions. |
| `dtn_bounds.m`: geometry constants | correct | The implemented curve, Jacobian and displacement bounds match the derivation and enforce the correction-band clearance. |
| High-lift constants $a_H,b_H^2,A_H$ | correct | These constants are assembled in `dtn_run.m` with $M=16$ and $a=L=1/8$; the stored $A_H$ is positive. |
| Assembly of $\widehat\Lambda$ | correct | The code uses $Q-\varepsilon_QI-K_+(R+\varepsilon_RI)-(b_H^2/A_H)(Z+\varepsilon_ZI)$. |
| JSON export: matrix, trace normalization and index order | correct | Both exports retain the source lower matrix unchanged, with unscaled coefficients ordered from $-16$ to $16$ and $\beta_i=0.5+2\pi i$. |
| Physical geometry: orientation, ports and collar | correct | The curve matches `direct_native.m`; translating cells preserves orientation, and $R(1+a)<1/4$ leaves the required homogeneous collar at both walls. |
| Claim (C) for both stored matrices | correct | The admissible exact-trace fields, matrix enclosures and all-trace completion apply to the stated left and right physical half-leads. |

There are no objections to enumerate. All requested items were reviewed.

Checks performed: the 72 exact integer RT trace identities, source-to-export equality for both certificates, matrix assembly, Fourier ordering, and recorded scalar conditions. These were small read-only checks; no MATLAB experiment was rerun.

Review literature verification completed. The supplied resolvent constants were treated as premises. The proof and implementation files were not modified; only this review file was written.
