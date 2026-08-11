# i4 Extraction Oracles

This experiment isolates Rayleigh coefficient extraction from the full BIE
solve. It does not modify package code, old tests, or the mathematical model.

## Frozen problem

The canonical parameters are $d=1$, $\beta=0.5$,
$k=1.8603695988$, circle radius $R=0.2$, and vertical walls
$X_L=-0.5$, $X_R=0.5$. The manufactured circle density is

$$
\rho(\theta)=1+(-0.35+0.20\mathrm{i})e^{\mathrm{i}\theta}
 +(0.20-0.15\mathrm{i})e^{3\mathrm{i}\theta}.
$$

For $a^2+b^2=k^2$ and nonnegative integer $\ell$, the independent circle
integral used by the oracle is

$$
I_\ell(a,b)=\int_0^{2\pi}e^{\mathrm{i}\ell\theta}
 e^{\mathrm{i}R(a\cos\theta+b\sin\theta)}\,d\theta
 =2\pi\mathrm{i}^{\ell}\left(\frac{a+\mathrm{i}b}{k}\right)^\ell
 J_\ell(kR).
$$

For the manufactured single-layer test, $\rho$ is placed in the second
extractor block $\mu=-\sigma$. Its action is therefore $-R c_m I_\ell$.
If $\rho$ instead denoted the physical single-layer density $\sigma$, the
action would have the opposite sign. The manufactured double-layer action is
$R c_m\partial_R I_\ell$, where $c_m$ is the side-dependent coefficient in
`bloch.farfield_extractors`.

## Oracles and fixed gates

- Pure Rayleigh wall projection, split by left/right and Dirichlet/Neumann:
  $10^{-12}$.
- Bessel formula versus direct angular quadrature and package extractor:
  $5\times10^{-13}$; resolved action: $10^{-11}$; nested retained-row
  change: $5\times10^{-14}$.
- Boundary refinements use `ntot = [128,256,512]`; exact-wall projections use
  `Ny = [512,1024,2048]`. Both refinement gates are $2\times10^{-10}$.
- Extractor output reaches $M_{out}=70$ and the retained rows are compared
  across $M=[5,10,20,70]$.
- MFS error against the continuous coefficient and high-to-higher proxy
  change: $2\times10^{-9}$ each. The legacy extractor comparison is also
  reported at its $10^{-8}$ gate.
- Sum of the four layer maxima: $10^{-8}$.
- The $M$-slope comparison is a 5% sanity check only.

The proxy levels are `(120,120,64,24)` and `(160,160,80,32)` for
`(N_side,N_top,N_proxy_edge,M_pw)`. Negative metadata for `delta=0` and a
near-Wood channel is recorded without making a root-convergence claim.

## Runtime and execution

The frozen high-resolution grids supersede the earlier quick-run estimate.
The console prints a measured **2100--2700 second (35--45 minute)** Octave
budget; the hard upper expectation remains below 90 minutes. The canonical
Octave 10.3.0 run completed in 2450.63 seconds.
From this directory, run the Octave sanity check with

```sh
conda run -n octave octave --quiet --no-gui --eval "addpath(pwd); results=run_i4_extract_oracles('canonical');"
```

For MATLAB final validation, run

```matlab
addpath('/Users/whc/Documents/Work/epost/test/i4-extract');
results = run_i4_extract_oracles('matlab-canonical');
```

Octave does not provide the optional `Faddeeva_erfc` MEX in the current
environment. The runner therefore enables `octave_compat/Faddeeva_erfc.m`
only in Octave and only when the function is otherwise unavailable. This
shim delegates to Octave's complex `erfc`; the report records that provenance.

Each run writes CSV ledgers, `results.mat`, `report.md`, and `run.log` under
`output/<label>/`. A passing run is expected to keep every fixed gate at one;
failures are retained as numerical findings rather than hidden by tolerance
changes.
