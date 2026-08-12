# Complex-wavenumber root readiness (`k-ready`)

This I1.4 experiment asks whether the fixed-$M=48$ I1.3 dip at
$k_*=1.8327703475952146$ belongs to one sampled, branch-anchored,
fixed-coordinate analytic finite-dimensional family. It does not run a
locator, contour method, Newton iteration, root isolation, derivative
qualification, or estimator.

## Current verdict

The combined verdict is
`I1_4_PASS_WITH_CONDITIONS / SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS`.
[V4](output/v4-a1/report.md) passed every positive node, factor, branch, QZ,
closure, and Cauchy--Riemann gate, but remains an immutable failure because the
physical `transmission_swap` negative is not identifiable in the homogeneous
left--right symmetric model. [V5](output/v5-a1/report.md) imports the frozen V4
artifacts and sources, preserves that exact failure pattern, and re-executes an
identifiable asymmetric assembly oracle. V5 therefore closes only the assembly
ordering question; it does not retroactively mark the symmetric physical
negative as passed.

The result supports a separately frozen empirical root-isolation experiment
on the same fixed-$M=48$ family. It does not establish a root, eigenvalue,
trace-order convergence, production QZ separation, absence of unsampled poles,
or a production $A_{\mathrm{def}}'(k)$.

## Preserved experiment lineage

- [plan.md](plan.md) and [pilot V1](output/pilot-a1/report.md): failed the
  original proxy score-parity gate.
- [plan-v2.md](plan-v2.md) and [pilot V2](output/pilot-a2/report.md): failed an
  incorrect lift-identity gate.
- [plan-v3.md](plan-v3.md) and [pilot V3](output/pilot-a3/report.md): corrected
  the lift identity and passed. The source-race run in
  `output/full-a1/attempt-1/` is non-authoritative.
- V3 full attempts [one](output/full-a2/attempt-1/report.md),
  [two](output/full-a2/attempt-2/report.md), and
  [three](output/full-a2/attempt-3/report.md) remain immutable failures at the
  first CR node. The separate [CR diagnostic](output/cr-diag/report.md)
  identifies subtractive cancellation at the radius-scaled steps but does not
  change those verdicts.
- [plan-v4.md](plan-v4.md) and [V4](output/v4-a1/report.md): separately frozen
  full sampled-disk run. All positive gates and 21 of 22 identifiable negative
  rows pass; the sole ordinary-negative failure is the symmetry-inapplicable
  transmission swap.
- [plan-v5.md](plan-v5.md) and [V5](output/v5-a1/report.md): authoritative
  negative closure and final I1.4 verdict.

The V5 output imports and hashes all V4 evidence, but does not hash its own
plan and runner. Their recorded SHA-256 values are
`5651a37179b0a8a0710d57dbdb3024849a9d9612e8b0a0a9007f269e0ed74d47`
and
`348a6713230e38f1dc060b1135b5476fa279ca6d2ea44a0e27d1933895dcec15`.
The frozen V5 output is not rewritten.

## Reproduction entry points

The scientific lineage is append-only. A fresh campaign must use a new output
tag rather than overwrite an existing directory. From the repository root,
the final two stages were invoked in MATLAB as:

```matlab
addpath('test/i1/k-ready');
run_v4();
run_v5();
```

The evaluator uses only experiment-local anchored constructors and the frozen
I1.3 input lineage. Package MATLAB files are unchanged. No explicit auxiliary
matrix larger than the physical proxy/BIE/QZ/graph systems is formed.
