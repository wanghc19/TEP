# I1.4 V3 frozen lift-gate plan

V3 inherits the complete V2 model, affine proxy representation, parent,
nodes, thresholds, gates, counters, claim boundary, and authorization flags.
It changes only the graph-lift residual gate below.  V1, V2, `pilot-a1`, and
`pilot-a2` remain immutable evidence.

For each level, let $q$ be the unit right minimum singular vector of
$A_{\mathrm{def}}^D$, and construct the same graph lift
$z=(q,c_-,c_+)$ using the already qualified Dirichlet factors.  With the
fixed row sets

$$
I_D=(1{:}K,\,2K+1{:}3K), \qquad
I_N=(K+1{:}2K,\,3K+1{:}4K),
$$

write $G_D=A_{\mathrm{def}}^G(I_D,:)$ and
$G_N=A_{\mathrm{def}}^G(I_N,:)$.  The only replacement gate is

$$
e_D=\frac{\|G_Dz\|_2}
{\max(1,\|G_D\|_2\|z\|_2)},
$$

$$
e_N=\frac{\|G_Nz-A_{\mathrm{def}}^Dq\|_2}
{\max(1,\|G_N\|_2\|z\|_2+
\|A_{\mathrm{def}}^D\|_2\|q\|_2)}.
$$

Require $\max(e_D,e_N)\leq10^{-10}$.  The V2 quantity

$$
\frac{\|A_{\mathrm{def}}^Gz\|_2}
{\max(1,\|A_{\mathrm{def}}^G\|_F\|z\|_2)}
$$

is retained under the diagnostic name `kernel_defect` and is not a V3 gate.
Every level pass is recomputed from all unchanged V2 gates plus the new lift
gate; the old V2 level pass is not inherited.

The bounded V3 pilot evaluates the same two nodes and writes only to
`output/pilot-a3/`.  It fails closed if that path already exists and does not
run a full disk, CR stencil, negative suite, locator, contour method, root
method, derivative qualification, or estimator.
