# Numerical TODO placeholder

No experiment, MATLAB run, solver implementation, or parameter scan was performed for this roadmap. Every item below begins only after the linked continuous obligation is stable.

## Experiment Group 1 — representation nullspace tests

- **Validates:** L9, L10, T1, L13; risks R1/R6/R7.
- **Inputs:** random smooth densities and Rayleigh coefficients; parameter paths through suspected empty/auxiliary resonances.
- **Compare:** full Müller--Rayleigh block versus Schur complement; physical and complementary fields.
- **Metrics:** algebraic residual, local physical-field norm, jump residual, complementary-field norm, smallest singular vectors, projector/side-constraint residual.
- **Decision:** a nonzero algebraic vector with zero physical field enters `\mathcal N_{\rm rep}`; it is never counted as a guided mode.
- **Interface needs:** routines returning field samples/norms separately from matrix residuals and exposing every representation component.

## Experiment Group 2 — stable Cauchy relation

- **Validates:** L4, L5, P1, P2, future FL3.
- **Cases:** repeated multipliers, constructed near-defective clusters, parameters approaching but not reaching the edge.
- **Compare:** direct eig versus ordered QZ; ordinary vectors versus cluster/Jordan-aware basis; DtN, RtR and relation charts.
- **Metrics:** principal angles/subspace gap, stable/unstable separation, trace reconstruction error, chart condition numbers, repeated-cell decay.
- **Decision:** select clusters by contour/order, never by fragile individual eigenvector labels.
- **Interface needs:** return generalized Schur factors and full Cauchy trace bases, not only multipliers.

## Experiment Group 3 — guided-mode benchmark

- **Validates:** K1 at the discrete level, FL4, later FT1.
- **Geometries:** Fliss line-defect geometry; circular and noncircular smooth rods; identical leads first.
- **References:** published FEM/DtN or converged supercell values, with source and tolerance recorded.
- **Metrics:** eigenvalue drift under `N,M,h`, reconstructed-field agreement, interface/port residuals, decay exponent, symmetry checks.
- **Decision:** a root is benchmarked only if all physical certificates converge together.
- **Interface needs:** a reproducible parameter manifest and export of reconstructed fields/traces.

## Experiment Group 4 — spurious-root certification

- **Validates:** L10/L13 operationally and future FT2; risk R8.
- **Required residual vector:** matrix residual; physical field norm/normalization; material-interface transmission residual; axial quasiperiodic residual; left/right port relation residual; cell-to-cell decay ratio.
- **Stress tests:** QP Green pole, auxiliary resonance, raw Schur-complement minimum, deliberately overcomplete stable basis.
- **Decision:** raw `\sigma_{\min}` is a candidate generator only; failure of any physical residual labels the point representation/coordinate-induced.
- **Interface needs:** structured certificate record with tolerances and refinement history.

## Experiment Group 5 — near-band-edge study

- **Validates:** L4 quantitative envelope and future FT3.
- **Continuation:** approach a fixed projected edge from within the gap while recording edge distance.
- **Metrics:** fitted decay exponent, `\min|\log|\lambda||`, stable/unstable separation, BIE error, Rayleigh-tail error, relation-subspace gap, comparison with supercell truncation.
- **Expected behavior:** error constants and required lead/supercell lengths deteriorate; no uniform edge claim.
- **Stop:** do not cross into a threshold/unit-circle case within the first paper.
- **Interface needs:** separate error budgets rather than a single total error.

## Experiment Group 6 — future contour solver

- **Validates:** C1 and future FT1--FT2.
- **Pre-audit:** verify analytic dependence of every matrix block on the contour; list Green, Wood, representation and stable-projection poles.
- **Tasks:** mode/root counting; contour refinement; pole subtraction or augmented representation; comparison against interval scanning; no-missed-root cross-check.
- **Metrics:** contour moment stability, total algebraic multiplicity, reconstructed-field certificate for every extracted root.
- **Stop:** no contour may enclose an unidentified operator pole.
- **Interface needs:** matrix evaluator exposing analyticity metadata and pole locations/types.

## Refinement protocol reserved for future use

Run nested refinements that vary one of `N`, `M`, `h` at a time before coupled refinement. Record all residual components and subspace gaps. The final convergence table must distinguish boundary quadrature, Rayleigh truncation, stable-relation discretization and nonlinear root-finding errors.

