# Manufactured NEP experiment report

- Version: `eig-apost-manufactured-v1`
- Estimator status: `conditional/empirical`
- Overall result: **FAIL**

## Question and method

This experiment tests the fixed-dimensional contour, bordered-Newton, root-qualification, and projected-correction pipeline on the pre-registered 2-by-2 analytic hierarchy. It does not test a physical BIE or DtN map.

## Positive hierarchy

| j | root error | consistency | tail effectivity | status |
|---:|---:|---:|---:|---|
| 0 | NaN | NaN | NaN | ROOT_QUALIFICATION_FAILED |
| 1 | 1.154632e-14 | 1.218700e-02 | 0.949677353 | PASS |
| 2 | 1.332268e-14 | 7.800293e-04 | 0.996873777 | PASS |
| 3 | 1.776357e-15 | 3.051746e-06 | 0.999987793 | PASS |

## Negative cases

| case | expected | observed | pass |
|---|---|---|---:|
| real-axis dip without a real root | `REAL_AXIS_DIP_ONLY` | `REAL_AXIS_DIP_ONLY` | 1 |
| level-dependent scaling | `LEVEL_SCALING_REJECTED` | `LEVEL_SCALING_REJECTED` | 1 |
| contour misses target root | `CONTOUR_COUNT_NOT_ONE` | `CONTOUR_COUNT_NOT_ONE` | 1 |
| deterministic root pollution | `ROOT_ERROR_DOMINATES` | `ROOT_ERROR_DOMINATES` | 1 |

## Interpretation

Passing results support only the manufactured finite-dimensional algorithm and the conditional empirical effectivity trend. Tail and total errors coincide here. No certified interval, BIE mapping, branch chart, pole ledger, half-guide convergence, or physical guided mode has been validated.
