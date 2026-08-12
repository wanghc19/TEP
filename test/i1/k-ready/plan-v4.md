# I1.4 V4 frozen CR-repair plan

## Status and claim boundary

V3 remains immutably `I1_4_FAIL`: all three registered radii failed the
center full-matrix CR gate because their steps entered a measured $1/h$
cancellation regime.  The later four-shift diagnostic at $h=r_0$ passed all
four $10^{-6}$ CR gates and only diagnoses that failure; it does not change
V3.

V4 is one new, separately frozen experiment.  It changes only the CR step
ladder and its convergence test.  It keeps the V3 model, parent, affine proxy
chart, branch, QZ continuation, fixed rows, Dirichlet charts, largest disk,
sampling tree, factor gates, coarse/fine gates, participation gates, and all
16 negatives.  A pass means sampled fixed-$M=48$ discrete root readiness,
not a root, eigenvalue, pole-free theorem, production derivative, or estimator.

## One allowed run

- Center: $k_*=1.8327703475952146$.
- Disk radius: $r_0=3.8146972647368216\times10^{-7}$.
- Nodes: center, eight half-radius nodes, nested 16/32 boundary nodes, and the
  same four alternate-parent cardinal closures.
- Only `output/v4-a1/` may be produced.  There is no smaller-radius fallback,
  alternate step ladder, or threshold change.

## CR repair

At the center and all eight half-radius nodes, use exactly

$$
h\in\{4r_0,2r_0,r_0\}.
$$

For both spatial levels and both full unbalanced matrices
$A_{\mathrm{def}}^D,A_{\mathrm{def}}^G$, form

$$
D_x(h)=\frac{A(k+h)-A(k-h)}{2h},\qquad
D_y(h)=\frac{A(k+\mathrm{i}h)-A(k-\mathrm{i}h)}{2\mathrm{i}h}.
$$

Every one of the three normalized CR defects must be at most $10^{-6}$.
For each of $D_x,D_y$, both adjacent normalized changes
$4r_0\to2r_0$ and $2r_0\to r_0$ must also be at most $10^{-6}$.  The V3
monotone-defect clause is removed because it is invalid in the independently
observed roundoff regime; no numerical threshold is relaxed, and V4 requires
all three defects plus both adjacent changes rather than only a final pair.

Every shifted evaluation must independently pass the unchanged level and
coarse/fine gates.  The maximum stencil distance from $k_*$ is $4.5r_0$.
Before running, require it to be less than one eighth of the nearest port or
proxy square-root branch-point distance.

## Negatives and stop rule

Only after all positive gates pass, run the same 16 ordered negatives.  The
anti-holomorphic and $k$-dependent-weight negatives are additionally evaluated
over the complete V4 step ladder, and their minimum rejection signal must
exceed the unchanged threshold.  Any positive or negative failure gives
`I1_4_V4_FAIL`; there is no retry.

Locator, contour, root, Newton, derivative qualification, and estimator calls
remain zero.  Production spectral separation, unsampled-pole exclusion,
continuous spectral approximation, and trace-order convergence remain explicit
non-blocking caveats for this empirical readiness claim.
