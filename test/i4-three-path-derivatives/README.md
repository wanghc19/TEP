# I4 three-path analytic-derivative experiment

This directory is a self-contained experiment for qualifying the analytic
first and second derivatives of the local Linton Eq. (2.65) implementation,
then comparing four raw wall actions across independent Ewald (`E`), package
MFS (`P`), and direct Rayleigh (`R`) paths. It does not modify or depend on the
older experiment's output directory.

## Entry point

Run from the repository root in MATLAB:

```matlab
addpath(fullfile(pwd, 'test', 'i4-three-path-derivatives'));
run_i4_three_path_derivatives('qualification');
run_i4_three_path_derivatives('pilot');
run_i4_three_path_derivatives('full');
```

The modes have deliberately different costs:

- `qualification` runs analytic Ewald, five-point finite-difference, direct
  Rayleigh, identity, projection, and mutation checks. It does not run MFS.
- `pilot` first repeats qualification, verifies that the current MATLAB
  process will use `lsqminnorm`, and then runs a small four-action comparison.
  It also writes `runtime-estimate.md`.
- `full` repeats all prerequisites and runs the frozen `ntot`, `Ny`, Rayleigh,
  Ewald, and MFS refinement ladders. This is the expensive authority run.

Do not use Octave for a scientific certification. A successful compatibility
run is labeled `OCTAVE_SANITY_PASS` with `scientific_authority=0`. Any `P`
stage is a hard blocker unless the same process is MATLAB,
`kernel.precomp_proxy` selects `lsqminnorm`, and all package paths match this
repository exactly.

## Frozen gates and staging

Point-oracle and self-refinement gates are $2\times10^{-9}$. Raw coefficient
pair gates are $10^{-8}$. The raw finite-difference ladder is always
$h_r=d\,2^{-r}$ for $r=7,8,9,10$. Its preregistered Richardson estimates are
$R_r=(16D_{r+1}-D_r)/15$: $R_9$ is the sole authority and the $R_8$ to $R_9$
change is mandatory. Raw values and $R_7$ remain visible as trend rows; no step
or extrapolation is selected after seeing the result.

Stages are strictly ordered: value, gradient, Hessian, SLP-D, SLP-N, DLP-D,
and DLP-N. The first failed mandatory stage prevents later stages from emitting
scientific coefficient rows. A package-MFS failure cannot yield a full
three-path certification.

Package point prerequisites are consumed per action rather than as one global
six-component gate:

- SLP-D requires $G$.
- SLP-N requires $G_x$.
- DLP-D requires $G_x$ and $G_y$.
- DLP-N requires $G_{xx}$ and $G_{xy}$.

$G_{yy}$ is always retained as a diagnostic. Therefore a package Hessian
failure cannot block SLP-D, SLP-N, or DLP-D; it stops DLP-N only when one of
the two components actually used by DLP-N is outside the frozen point gate.

## Output contract

Each mode writes under `output/<mode>/`; full mode uses `output/canonical/`.
The directory contains:

- `results.mat`, `report.md`, and `run.log`;
- backend and solver provenance in `backend-metadata.csv`;
- formula convergence, point oracles, identities, projection, and mutations;
- action refinements, raw coefficient comparisons, wall point comparisons,
  gates, decisions, and timings as separate CSV ledgers.

All Neumann comparisons are raw. The direct Rayleigh oracle on either wall is
$(\mathrm{i}\gamma_m)D_m$. Rows divided by $\mathrm{i}\gamma_m$, when present,
are explicitly supplemental and never participate in a gate.

See [derivation.md](derivation.md) for the derivative and action formulas.

## MATLAB package point diagnostic

The separate no-wall diagnostic never overwrites pilot output:

```matlab
addpath(fullfile(pwd, 'test', 'i4-three-path-derivatives'));
run_i4_package_point_diagnostic();
```

It writes to `output/package-point-diagnostic/` and stops at the first failed
stage. Stage 0 must first reproduce the known base signature at negative
`holdout_B`: package value and gradient are within $2\times10^{-9}$ of the
joint Ewald tuple, while all three returned Hessian components are outside the
gate. Stage 1 uses manual axis swapping as its mandatory wrapper gate.
Transverse parity is a separate `IMPORTANT` diagnostic: a failure is labeled
`UP_DOWN_APPROXIMATION_ASYMMETRY` and does not stop the run. Stage 2 checks the
package gradient and Hessian with the frozen raw/Richardson ladder. Only then
may the fixed-$A,b$ solver sensitivity and preregistered proxy ladders run.

For both signs of `holdout_B`, the manual computational target is
$(0.287,\pm0.217)$. Since the proxy half-width is $H=1.1$, both points have
`idx_in=true`; this diagnostic does not enter the `C_down` plane-wave branch.
It emits separate diagnostic, identity, FD, solver, proxy, conditional
primary/proxy decomposition, decision, timing, provenance, MAT, report, and log
artifacts. No level is selected after observing its error.
