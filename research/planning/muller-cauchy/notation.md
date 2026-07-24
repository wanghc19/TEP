# Notation and function spaces

## Geometry

- `d>0`: quasiperiod in the `y` direction.
- `S = R x (0,d)`: infinite strip, with top/bottom identified by phase.
- `C^0 = (X^-,X^+) x (0,d)`: bounded center region.
- `W^+ = (X^+,infinity) x (0,d)` and
  `W^- = (-infinity,X^-) x (0,d)`: periodic half-guides.
- `Gamma^+ = {X^+}x(0,d)`, `Gamma^- = {X^-}x(0,d)`:
  artificial ports.
- `Omega^0`, `Omega^ell`: center and lead inclusions; `Sigma` denotes material
  interfaces.
- `nu`: unit normal pointing out of an inclusion. Port normals point outward
  from the center cell, so `nu_Gamma+=+e_x` and `nu_Gamma-=-e_x`.

The first phase takes identical leads; superscripts `+/-` remain to track port
orientation.

## Quasiperiodic Sobolev spaces

For real `beta`, define

```latex
H^s_\beta(0,d)
=
\{v=e^{i\beta y}\widetilde v:\widetilde v\in H^s_{\rm per}(0,d)\}.
```

Equivalently, with `beta_m=beta+2*pi*m/d`,

```latex
\|v\|_{H^s_\beta}^2
=\sum_{m\in\mathbb Z}(1+|\beta_m|^2)^s|\widehat v_m|^2.
```

`H^1_beta(S)` and its restrictions are defined by the gauge
`u(x,y)=exp(i beta y) u_tilde(x,y)` with periodic `u_tilde`. The global space
already includes `L^2` integrability in `x`; exponential decay is a consequence
of the strict-gap spectral theorem, not part of the definition.

## Weak global guided space

For `q=n^2`,

```latex
\mathcal G(k,\beta)
=\{u\in H^1_\beta(S):
\int_S \nabla u\cdot\nabla\overline v-k^2q u\overline v=0
\ \forall v\in H^1_\beta(S)\}.
```

The piecewise equation and TM interface conditions follow in the weak sense.
The zero field is included so that `G(k,beta)` is a vector space.

## Half-guide solution and trace spaces

```latex
\mathcal U^\pm_{\rm out}(k,\beta)
=\{u\in H^1_\beta(W^\pm):u\text{ solves the homogeneous weak problem}\}.
```

In the strict gap, this `H^1` definition is intended to coincide with the
stable generalized-Bloch subspace and implies exponential decay.

The oriented Cauchy trace is

```latex
\operatorname{Tr}_\pm u
=(\gamma_Du,\gamma_N^\pm u)
\in \mathcal H_\Gamma
:=H^{1/2}_\beta(\Gamma)\times H^{-1/2}_\beta(\Gamma),
```

where the weak Neumann trace is defined through Green's identity and
`gamma_N^+u=+partial_x u`, `gamma_N^-u=-partial_x u` at the center ports.

The outgoing Cauchy relation is

```latex
\mathcal C^\pm_{\rm out}(k,\beta)
=\operatorname{Tr}_\pm \mathcal U^\pm_{\rm out}(k,\beta)
\subset\mathcal H_\Gamma.
```

## Center solution space

`S_ctr(k,beta)` is the space of weak TM transmission solutions in `C^0` with
quasiperiodic top/bottom conditions and no port condition. `B_rel(k,beta)` is
the subspace satisfying
`Tr_±u in C_out^±(k,beta)`.

## Layer-potential spaces

For each smooth interface `Gamma_j=partial Omega_j`, the natural Cauchy-density
pair is

```latex
\eta_j=(\tau_j,\sigma_j)
\in H^{1/2}(\Gamma_j)\times H^{-1/2}(\Gamma_j),
```

where `D tau` and `S sigma` reconstruct fields. For finitely many center
interfaces,

```latex
\mathcal X_\eta
=\prod_j\bigl(H^{1/2}(\Gamma_j)\times H^{-1/2}(\Gamma_j)\bigr).
```

The boundary residual space is ordered as
`X_eta` or its dual-compatible permutation, fixed once the Müller block is
written explicitly.

## Rayleigh data

Let

```latex
\mathfrak h^s_\beta
=\{a=(a_m):\sum_m(1+|\beta_m|^2)^s|a_m|^2<\infty\}.
```

At a non-Wood parameter, `gamma_m=sqrt(k^2-beta_m^2)` is taken with
`Im gamma_m>=0`. A homogeneous background solution in a bounded cell is
parameterized by two sequences in a weighted product
`X_Ray`, chosen so that its two port Cauchy traces lie in `H_Gamma`. The exact
minimal weights are a proof obligation; raw unweighted `ell^2` is not assumed.

## Generalized Bloch coordinates

- `T^±`: one-cell translation/propagation operator on a declared solution or
  trace space.
- `sigma_s(T^+)`: multipliers inside the unit disk for the right lead;
  the left orientation is defined analogously after reversing translation.
- `P_s^±`: Riesz projector around the stable cluster.
- `Q^±: C^± -> H_Gamma`: synthesis map from generalized/Jordan coordinates to
  Cauchy traces. `C^±` is the Riesz-basis coefficient space, not an ordinary
  eigenvector list.

## Reconstruction and coupled operator

- `R_ctr(eta,xi)`: center field reconstructed by Müller layers plus homogeneous
  Rayleigh augmentation.
- `N_rep=ker R_ctr`: representation nullspace.
- `A_rel(k,beta)`: full center--lead relation block.
- `X_alg=X_eta x X_Ray x C^- x C^+`: algebraic domain before quotienting.
- `X_phys=X_alg/N_rep^lift`: physical algebraic classes.

At fixed `(k,beta)`, multiplicity means `dim G(k,beta)` and therefore geometric
multiplicity. Algebraic multiplicity of a root `k_*` is reserved for a later
analytic operator-pencil definition.

