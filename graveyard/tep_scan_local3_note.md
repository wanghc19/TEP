# `tep_scan_local3.m` Assembly Note

`tep_scan_local3.m` keeps the scan/refinement workflow from
`tep_scan_local2.m`, but changes the matrix assembly in two ways:

1. The T-difference block now uses the Kress-style decomposition from
   `Kress.md`
   ```text
   Ndiff(s,t) = log(4 sin^2((s-t)/2)) N1diff(s,t) + N2diff(s,t),
   ```
   with Kussmaul-Martensen logarithmic weights for the log part and the
   periodic trapezoid rule for the smooth part.

2. The S, D, and D' difference blocks are treated globally as continuous
   kernels: direct off-diagonal kernel differences, analytic diagonal
   limits, and no KR correction or bandmask workaround.

For the T-difference block, the cot / principal-value term cancels in the
difference kernel, so it does not appear in the final assembly.  The code
uses
```text
N1diff = N1_{n k} - N1_k,
N2diff = N2_{n k} - N2_k - N_{R_k},
```
with `G_ext_qp = Phi_k + R_k`, so all proxy/MFS terms are absorbed into the
smooth remainder `N2diff`.
