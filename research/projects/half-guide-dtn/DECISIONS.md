# Decisions And Assumptions

## D1: Isolation

All new files, notes, prototypes, results, and reports are kept under
`attempt/`. Existing package files are not modified during this research attempt.

## D2: First Validation Problem

The first numerical experiment is the homogeneous lead. In Rayleigh basis, the
right outgoing field has modes

```text
exp(i beta_m y) exp(i gamma_m (x - x0))
```

and the left outgoing field has modes

```text
exp(i beta_m y) exp(-i gamma_m (x - x0)).
```

With the project convention

```text
N^+ = +partial_x u on Gamma^+,
N^- = -partial_x u on Gamma^-,
```

both outward half-guide DtN maps are expected to be diagonal with entries
`i * gamma_m` for the same outgoing branch convention. This sign must be
rechecked against the code's `gamma_m` branch and any Joly outward-normal
convention.

## D3: Coupling Priority

The first central-cell coupling option to analyze is Scheme A:

```text
unknowns = (eta, xi)
Muller row = A_QP eta + B_{partial Omega^0} xi
port rows = Pi_N eta/xi - Lambda Pi_D eta/xi
```

This is closest to current code and gives the clearest comparison with
trace-matching. Schemes B and C remain important alternatives for the report.

## D4: Evidence Labels

Every major claim should be labeled as one of:

- literature result;
- derivation;
- numerical observation;
- conjecture;
- implementation assumption.

## D5: Joly Coefficient Versus Project DtN Sign

For the homogeneous right-port orientation checked in the first prototype,
Joly's cell-block boundary coefficient satisfies

```text
K_Joly = T00 + T10*R = -1i*gamma
```

whereas the project outward-normal DtN is

```text
Lambda_TEP = -(T00 + T01*R) = 1i*gamma
```

This distinction must be preserved in all later obstacle-lead formulas.

## D6: Scattering-To-DtN Is A Diagnostic, Not The Main Replacement

The quotient `N_out / D_out` can compare signs and conditioning when the
outgoing Dirichlet block is square and nonsingular. It should not be treated as
the main new formulation because it still depends on the Bloch outgoing trace
basis that the research task is trying to avoid.
