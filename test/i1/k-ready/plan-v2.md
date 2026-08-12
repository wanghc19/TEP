# I1.4 V2 frozen plan

## Claim boundary and inheritance

V2 tests the same sampled discrete root-readiness claim, frozen parent,
geometry, branch continuation, BIE--DtN model, QZ cluster continuation,
fixed-row charts, disk, node tree, CR protocol, stop rule, negative controls,
resource limits, and verdict vocabulary as `plan.md`.  V2 changes only the
proxy-coordinate construction described below.  Every V1 gate not explicitly
replaced here remains unchanged.  Locator, contour, Newton, root-isolation,
estimator, and production flags remain false.

## Frozen affine proxy chart

For each coarse/fine spatial level, assemble the local seed arrays
$A_0=A_{\rm pr}(k_*)$ and $b_0=b_{\rm pr}(k_*)$ using the same anchored
logarithmic branch as every other consumer.  Call `lsqminnorm(A0,b0)` exactly
once per level and freeze its result as $c_0$.  The seed-only thin SVD freezes
$U_r,V_r,r$ with the V1 relative threshold
$\sigma_j/\sigma_1\geq10^{-8}$ and the unchanged V1 rank-stability gate.  The
complete immutable chart also records its deterministic SHA-256 hash and the
frozen coefficient-complement norm

$$
\eta_\perp=\|(I-V_rV_r^*)c_0\|_2.
$$

Thus the chart is

$$
\mathcal C_{\rm pr}=(A_0,b_0,c_0,U_r,V_r,r,h_{\rm chart},\eta_\perp).
$$

Both collocation and shifted arrays must be assembled arithmetic-identically
to `kproxy.m`: the same statements, operation order, point ordering, native
mode ordering, and branch values are used.  No off-seed SVD, `lsqminnorm`,
`pinv`, rank selection, chart change, or solver switch is permitted.

At every sampled $k$, including the seed, define

$$
d(k)=[b(k)-b_0]-[A(k)-A_0]c_0,
$$

solve only

$$
[U_r^*A(k)V_r]z(k)=U_r^*d(k),
$$

and set

$$
c(k)=c_0+V_rz(k).
$$

The reduced factor must be tested before backslash and must have `rcond` at
least $10^{-8}$.  Failure stops the node as `PROXY_COMPRESSION_POLE`; no
fallback is allowed.  Record the affine correction $V_rz$, the final
coefficients $c$, the reduced projected residual, reduced backward error, full
collocation residual, and seed anchoring relative error.

## V2 proxy gates

- The reduced projected residual and backward error remain bounded by
  $10^{-11}$.
- The full collocation residual of $c(k)$ is a hard gate at $10^{-5}$ on every
  evaluated node.
- The shifted residual uses the same collocation coefficients $c(k)$ on the
  independently assembled shifted system and is a hard gate at $10^{-5}$ on
  every evaluated node.  The shifted system is never solved.
- At $k_*$, require
  $\|c(k_*)-c_0\|/\max(1,\|c_0\|)\leq10^{-12}$.
- Runtime/provenance counters must show exactly one seed `lsqminnorm` call per
  level and zero off-seed SVD, `lsqminnorm`, `pinv`, rank changes, or solver
  fallbacks.

The anchor score comparison is an anchoring-identity gate: at the seed,
$A=A_0$, $b=b_0$, hence $d=0$ and the frozen affine formula must reproduce
$c_0$ to the tolerance above.  Score parity against the frozen I1.3 parent is
checked from that coefficient identity.  It is independent of, and does not
replace or derive from, the separately retained block, pencil, DtN, and
$A_{\mathrm{def}}$ action-parity gates.

## Isolated pilot output

The first V2 pilot writes only to `output/pilot-a2/`.  It must not overwrite,
rename, delete, or reinterpret any V1 file or V1 output.  A failed V2 attempt
is preserved append-only with its provenance and named failing gate.
