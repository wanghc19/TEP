# Stage 2 augmented BIE discrete-algebra report

- Decision: `STAGE2_DISCRETE_ALGEBRA_GO`
- Root readiness: `STOP`
- Actual case label: `UNSCREENED_CENTER_BIE_INTERFACE_SMOKE`
- Overall pass: `1`

## Scope

This bundle checks the frozen finite-dimensional block algebra, density-coordinate scaling, conditional Schur reduction, and shared availability gates. It does not perform a root search, call a modal solver, or make physical kernel-field or multiplicity claims.

## Manufactured oracles

- A1 augmented residual: `1.769533e-17`
- A1 raw/reduced Schur error: `4.350819e-16`
- A1 literal transmission-swap residuals: `2.276906e-02, 1.137638e-02, 2.545306e-02`
- The original identity-transmission fixture could not detect a literal `T_LR`/`T_RL` swap; the frozen fixture therefore uses the nontrivial transmission blocks recorded in `results.mat`.
- A2 scaled/physical scattering error: `1.203224e-16`
- A2 wrong-coordinate mismatch: `7.215582e-02`

## Actual interface smoke

The ellipse center uses `B=D_h B_phys` and `E=E_phys/D_h`; the variable-speed raw `construct_S` result is not treated as physical truth. The constant-speed circle is used as the allowed oracle.

| level | N | raw Schur error | forbidden delta ratio |
|---:|---:|---:|---:|
| 0 | 1 | 3.150246e-17 | 0.000000e+00 |
| 1 | 2 | 2.613591e-17 | 0.000000e+00 |
| 2 | 4 | 3.076285e-18 | 0.000000e+00 |
| 3 | 8 | 6.398414e-19 | 0.000000e+00 |
| 4 | 16 | 1.020109e-18 | 0.000000e+00 |
| 5 | 32 | 1.617558e-18 | 0.000000e+00 |
| 6 | 64 | 7.655820e-19 | 0.000000e+00 |

## Computed availability propagation

Unavailable derived matrices are stored as fixed-size `NaN` sentinels. Raw `F_aug` and `K_ee` are retained whenever primitive dimensions and fingerprints pass.

| case | F_aug | S_c | Rhat- | Rhat+ | F_red | raw Schur | equivalence | root |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| WOOD_K_0P2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | STOP |
| DOUBLING_EXACT_POLE | 0 | 0 | 0 | 0 | 0 | 0 | 0 | STOP |
| CENTER_EXACT_POLE | 1 | 0 | 1 | 1 | 0 | 0 | 0 | STOP |
| ZERO_FIELD_EXACT | 1 | 0 | 1 | 1 | 0 | 0 | 0 | STOP |
| LEFT_TERMINAL_EXACT | 1 | 1 | 0 | 1 | 0 | 0 | 0 | STOP |
| RIGHT_TERMINAL_EXACT | 1 | 1 | 1 | 0 | 0 | 0 | 0 | STOP |
| REP_CHANGED_DH | 0 | 0 | 0 | 0 | 0 | 0 | 0 | STOP |

## Reproducibility

- Status: `REPRODUCED`
- Relative difference: `0.000000e+00`
- The source hash manifest covers the specification, symbol appendix, all four reused BIE helpers, the experiment, and its wrapper.
