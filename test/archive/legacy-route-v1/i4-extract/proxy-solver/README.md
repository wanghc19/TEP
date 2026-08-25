# i4 Proxy Solver Diagnostic

This experiment rebuilds the two canonical `kernel.precomp_proxy` least-
squares systems locally and changes only the linear solver. Package files,
older tests, BIE assembly, wall grids, gradients, and Hessians remain outside
scope.

The physical problem has $y$-periodicity with $d=1$, $\beta=0.5$ and
$k=1.8603695988$. The package proxy system is formulated in computational
$x$-periodic coordinates. Therefore the physical point displacement

$$
(x_t-x_s,y_t-y_s)=(\delta,-0.066)
$$

is passed to the benchmark convention as

$$
(X,Y)=(-0.066,\delta),\qquad \delta\in\{0.30,0.20,0.10\}.
$$

The tested systems are `high=(120,120,64,24)`, with size $720\times354$,
and `higher=(160,160,80,32)`, with size $960\times450$. The tuple entries are
`(N_side,N_top,N_proxy_edge,M_pw)`.

Solvers comprise the observable package output, Octave's default
`pinv(A)*b`, its explicit-default counterpart
`pinv(A,max(size(A))*norm(A)*eps)*b`, the selected same-backend solve
`pinv(A,3e-16*norm(A))*b`, `A\b`, and manual thin-SVD truncations retaining
$s_j>\tau s_1$ for the frozen 12-value $\tau$ list. The documented default
rank and the selected-tau rank are counted from those exact absolute
thresholds. Point values are compared
with Rayleigh sums at $M=48,96$ and two value-only Ewald levels after the
coordinate swap. No density or layer-potential sign enters this point-source
test.

The runner prints an estimated runtime below 60 seconds and a hard 300-second
limit before starting. Run the Octave sanity check with

```sh
conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-extract/proxy-solver'); results=run_i4_proxy_solver();"
```

For MATLAB final validation, run

```matlab
addpath('/Users/whc/Documents/Work/epost/test/i4-extract/proxy-solver');
results = run_i4_proxy_solver();
```

Artifacts are written to `../output/proxy-solver/`. The causal cutoff label
requires the same-backend default/explicit-default field match and the
selected-tau point and cross-level gates; the manual SVD sweep remains a
separate ledger. Both lower- and upper-neighbor changes are recorded for an
interior manual cutoff. A closed result remains point-value-only and makes no
derivative, Hessian, wall-projection, layer-density, BIE, or root-readiness
claim.

The active Octave result is `PROXY_SOLVER_DIAGNOSTIC_UNRESOLVED`. Default and
explicit-default `pinv` agree exactly, but
`pinv(A,3e-16*norm(A))*b` fails the point and cross-level gates. Only the
manual thin-SVD application at the same threshold passes the point gates, so
that result is manual-SVD-only evidence and does not establish cutoff
causality. Consequently the prepared wall D/N validation was not created or
launched.
