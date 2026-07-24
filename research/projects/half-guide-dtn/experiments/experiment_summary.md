# Experiment Summary

## Experiment 1: Homogeneous Lead DtN

- Entry point: `attempt/prototype/run_all.m`
- CSV data: `/Users/whc/Documents/Work/TEP/attempt/experiments/homogeneous_dtn_validation.csv`
- Markdown report: `/Users/whc/Documents/Work/TEP/attempt/experiments/homogeneous_dtn_validation.md`

### Latest Diagnostics

| eps_abs | max Riccati residual | project DtN relerr | stable count |
| ---: | ---: | ---: | ---: |
| 0.000e+00 | 7.109e-16 | 3.783e-17 | 16/34 |
| 1.000e-03 | 1.302e-15 | 3.554e-17 | 17/34 |
| 5.000e-02 | 1.017e-15 | 3.810e-17 | 17/34 |

### Conclusion

The homogeneous sign/order test supports the conversion `Lambda_TEP = -(T00 + T01*R) = diag(1i*gamma_m)` for the right-port cell orientation used in the derivation notes. This is only a homogeneous validation; periodic obstacle leads and center Muller-DtN coupling remain unvalidated.
