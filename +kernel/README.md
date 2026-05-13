# +kernel package

## Purpose

The `+kernel` package provides Helmholtz kernel evaluation utilities used by the TEP boundary-integral and waveguide scripts.  It includes free-space single-layer kernel derivatives, augmented-MFS quasi-periodic Green data, proxy precomputation, and bare Kress split kernel matrices used by all-Kress discretizations.

## Public functions

`kernel.h2d_directch(wavek, sources, charge, targ)` evaluates the two-dimensional free-space Helmholtz single-layer potential and its first and second target derivatives.  It returns `pot`, `grad`, and `hess` arrays for distinct source and target points.

`kernel.precomp_proxy(pars1, pars2)` solves the augmented MFS least-squares system for one quasi-periodic Green function setup.  It returns a `proxy` struct containing proxy source strengths, proxy source locations, the computational half-height, and upward/downward plane-wave coefficients.

`kernel.qpgreen_mfs(src, trg, pars1, pars2, varargin)` evaluates the augmented-MFS quasi-periodic Green function for one source and many targets.  It returns a struct with `pot`, `grad`, and `hess`; an optional periodic-axis selector allows physical `x`- or `y`-periodicity through coordinate swapping.

`kernel.qpgreen_mfs_pairmat(src, trg, pars1, proxy, varargin)` evaluates dense target-by-source matrices for the augmented-MFS quasi-periodic Green function and its derivatives.  It returns potential, gradient, and Hessian component matrices and uses the same periodic-axis convention as `kernel.qpgreen_mfs`.

`kernel.kress_l_splits(k, t, geom_data)` builds Kress logarithmic split matrices for the bare source-normal double-layer kernel `L` and target-normal adjoint kernel `L*`.  It returns `L1`, `L2`, `Ls1`, and `Ls2`, where the split has the form `kernel = split_1*g + split_2`.

`kernel.kress_mn_splits(k, t, geom_data)` builds Kress logarithmic split matrices for the bare single-layer parameter kernel `M` and the tangential-derivative auxiliary kernel `N`.  It returns `M1`, `M2`, `N1`, and `N2` for use in Kress product-quadrature assembly.

## Main data structures

`pars1` stores physical quasi-periodic parameters.  The current kernel routines use fields such as `d`, `beta`, and `k`; `qpgreen_mfs` and `qpgreen_mfs_pairmat` also accept optional `pars1.periodic_axis`.

`pars2` stores proxy and plane-wave discretization parameters for `kernel.precomp_proxy`.  Required fields include `H`, `proxy_dist`, `N_side`, `N_top`, `N_proxy_edge`, and `M_pw`.

`proxy` is returned by `kernel.precomp_proxy` and passed to the quasi-periodic Green evaluators.  Its fields are `q`, `Z`, `H`, `C_up`, and `C_down`.

`src`, `sources`, `trg`, and `targ` are point-coordinate arrays.  Source and target coordinates are stored as 2-by-`n` arrays, with rows representing physical `x` and `y`.

`pot`, `grad`, and `hess` are the free-space or quasi-periodic Green outputs.  `grad` is ordered as `[du/dx; du/dy]`, while `hess` is ordered as `[d2u/dx2; d2u/dxdy; d2u/dy2]`.

`geom_data` is the boundary geometry struct used by the Kress split routines.  It must contain `z`, `zp`, `zpp`, and `speed`, where `z`, `zp`, and `zpp` are `N`-by-2 arrays and `speed` is an `N`-by-1 vector.

`t` is the equidistant periodic parameter grid used by the Kress split routines.  The split functions build the logarithmic factor `g(t,tau) = log(4*sin^2((t-tau)/2))` internally.

## Conventions

- `kernel.precomp_proxy` is formulated in computational coordinates with first-coordinate periodicity.  Axis selection for physical `x` or `y` periodicity is handled by `kernel.qpgreen_mfs` and `kernel.qpgreen_mfs_pairmat`.
- For physical `y`-periodicity, callers should set `pars1.d` to the physical `y` period and choose `pars2.H` as the computational non-periodic half-width after swapping coordinates.
- The optional periodic-axis selector should remain the existing character/string scalar `'x'` or `'y'`.
- `kernel.h2d_directch` assumes source and target points are distinct; it does not regularize self interactions.
- Helmholtz outgoing waves use `besselh(order, 1, z)`.
- The Kress split routines construct kernel coefficient matrices only.  They do not build the quadrature weight matrix; callers currently combine them with `quad.quad_kress_rvec`.
- `geom_data` must use the same counter-clockwise tangent convention as the rest of the project, with normals derived from `zp` as `(dy/dt, -dx/dt)/speed`.
- `kress_l_splits` and `kress_mn_splits` are bare free-space kernel splits.  Periodic or proxy corrections are assembled by caller code such as `op.construct_A_QP`.

## Typical workflow

```matlab
pars1.d = d;
pars1.beta = beta;
pars1.k = kext;

pars2.H = H;
pars2.proxy_dist = proxy_dist;
pars2.N_side = N_side;
pars2.N_top = N_top;
pars2.N_proxy_edge = N_proxy_edge;
pars2.M_pw = M_pw;

proxy = kernel.precomp_proxy(pars1, pars2);

[pot_ext, gradx_ext, grady_ext, hessxx_ext, hessxy_ext, hessyy_ext] = ...
  kernel.qpgreen_mfs_pairmat(src, trg, pars1, proxy);

[R_diag, gradR_diag, hessR_diag] = ...
  kernel.h2d_directch(pars1.k, proxy.Z, proxy.q, [0; 0]);

[t, ~] = utils.triginterp(ntot);
geom_data.z = [C(1,:).', C(4,:).'];
geom_data.zp = [C(2,:).', C(5,:).'];
geom_data.zpp = [C(3,:).', C(6,:).'];
geom_data.speed = sqrt(sum(geom_data.zp.^2, 2));

[L1, L2, Ls1, Ls2] = kernel.kress_l_splits(kext, t, geom_data);
[M1, M2, N1, N2] = kernel.kress_mn_splits(kext, t, geom_data);
```
