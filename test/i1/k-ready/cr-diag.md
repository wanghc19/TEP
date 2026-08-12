# I1.4 CR diagnostic plan

This is an out-of-protocol causal diagnostic after the immutable three-attempt
V3 failure.  It cannot pass or alter the frozen I1.4 verdict.

- Use the same frozen parent, affine proxy chart, branches, QZ seed clusters,
  fixed rows, Dirichlet charts, model, and coarse/fine levels.
- Evaluate only the four center shifts at
  $h=r_0=3.8146972647368216\times10^{-7}$.
- Form the full unbalanced $A_{\mathrm{def}}^D$ and
  $A_{\mathrm{def}}^G$ central-difference CR defects for both levels.
- Require every shifted point to pass the existing point and coarse/fine
  comparison gates.
- Interpretation frozen before running:
  - if all four CR defects are at most $10^{-6}$, classify the V3 CR failure
    as finite-difference cancellation dominated;
  - otherwise classify the cause as mixed or unresolved.
- Predicted from the observed $1/h$ law: about $10^{-7}$ for
  $A_{\mathrm{def}}^D$ and $5\times10^{-7}$ for
  $A_{\mathrm{def}}^G$.
- Estimated cost: one seed plus four coarse/fine points, below one minute and
  512 MiB.  Largest arrays remain `960 x 450`, `512 x 512`, `194 x 194`, and
  `388 x 388`.
- Locator, contour, root isolation, derivative qualification, and estimator
  calls remain forbidden.
