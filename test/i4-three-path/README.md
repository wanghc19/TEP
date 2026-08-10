# I4 three-path Ewald/MFS/Rayleigh experiment

This experiment compares one manufactured circle single-layer action through
three method-diverse numerical paths.  They are not three independent truths,
because their mathematical representations share Bloch/modal conventions:

- `E`: a test-local implementation of Linton (1998), Eq. (2.65), with
  explicit reciprocal-space and real-space sums;
- `P`: the public package `kernel.qpgreen_mfs_pairmat` evaluator;
- `R`: the public package `bloch.farfield_extractors` operator.

It does not modify package code, benchmark code, older tests, or research
documents. The Ewald helper does not call benchmark Ewald, package Rayleigh
channel construction, or MFS. An independent local Rayleigh point sum is used
only as a qualification oracle.

## Frozen conventions

The canonical problem has $k=1.8603695988$, $\beta=0.5$, $d=1$, circle radius
$R=0.2$, and walls $x=-0.5,0.5$. Physical $y$ is periodic.  Linton's
separations are $(X,Y)=(x_t-x_s,y_t-y_s)$ and are passed directly to the local
Ewald helper.  Only the package MFS wrapper swaps physical points to `[y;x]`
because its internal implementation is periodic in the first coordinate.

Linton's Green function solves the source $+\delta$ convention with free-space
kernel $-\mathrm{i}H_0^{(1)}/4$. The project solves the source $-\delta$
convention with free-space kernel $+\mathrm{i}H_0^{(1)}/4$. Thus

$$
G_{\mathrm{project}}=-G_{\mathrm{Linton}}.
$$

Both use the $\exp(-\mathrm{i}\omega t)$ outgoing convention. A target shift
by $+d$ in the periodic direction has factor $\exp(+\mathrm{i}\beta d)$; no
sign flip of $\beta$ is made. The SLP-D action follows the existing density
ordering $\eta=[\tau;-\sigma]$:

$$
u(x)=-\int_\Gamma G(x,z)\rho(z)\,ds(z).
$$

The canonical density has modes $\ell=0,1,3$ and coefficients
$1$, $-0.35+0.20\mathrm{i}$, and $0.20-0.15\mathrm{i}$. A second frozen,
asymmetric complex density uses modes $\ell=-2,0,1,3$ as a phase holdout.

## Stages

`qualification` reproduces all five Linton Table 2--5 values, checks separate
$M_1$, $M_2$, and $N$ refinements, checks $a=1.5,2,2.5$, compares with a local
Rayleigh point sum at $M=96$, validates Fourier projection, quasi-periodic
translation, and beta reciprocity, and confirms that deliberate sign, axis,
and phase mutations fail. If any mandatory gate fails, its status is
`EWALD_REFERENCE_UNCERTIFIED` and `slp` refuses to start.

`pilot` uses only `ntot=32`, `Ny=64`, `M=12`, and the base proxy. It measures
both Ewald and MFS wall matrices and writes `runtime-estimate.md` by explicit
source-target and proxy-work scaling. It never issues a scientific verdict.

`slp` is the expensive frozen SLP-D ladder. It requires a certified
qualification result and is not part of the automatic qualification/pilot
workflow. The authority grids are `ntot=128`, `Ny=256`; refinements are
`ntot=256`, `Ny=512`; Rayleigh truncations are $M=12,24,48$. Later
SLP-N/DLP-D/DLP-N stages remain stopped in this delivery.

## Canonical outcome

The Octave qualification reproduces the five Linton values with maximum
absolute error $5.07\times10^{-11}$.  At those same Linton points package MFS
differs from Ewald by up to $6.01\times10^{-8}$; at project points the
Ewald--Rayleigh difference is $1.11\times10^{-16}$.  The full SLP--D run takes
$531.181285$ seconds and returns `SLP_D_UNCERTIFIED`: Ewald--Rayleigh closes
to $6.10\times10^{-16}$, while both pairs containing package MFS reach
$4.69\times10^{-8}$.  Every single-axis proxy refinement exceeds the frozen
$2\times10^{-9}$ self-change gate.  The derivative layers are therefore
`NOT_RUN_PREREQUISITE`.

The active Octave package solve is the fallback `pinv(A) * b` branch because
`lsqminnorm` is unavailable.  The canonical runner does not expose its exact
effective rank, cutoff, or residual, so the triangle isolates the package MFS
path but does not yet distinguish solver backend from proxy basis/collocation.
See `output/canonical/solver-backend.md`.

## Commands

Run the permitted Octave sanity stages separately:

```sh
conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-three-path'); results=run_i4_three_path('qualification');"
conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-three-path'); results=run_i4_three_path('pilot');"
```

Do not start full `slp` until the pilot estimate has been reviewed. For later
manual MATLAB validation:

```matlab
addpath('/Users/whc/Documents/Work/epost/test/i4-three-path');
qualification = run_i4_three_path('qualification');
pilot = run_i4_three_path('pilot');
% After reviewing output/pilot/runtime-estimate.md:
slp = run_i4_three_path('slp');
```

Each mode writes the common artifact set under `output/qualification/`,
`output/pilot/`, or `output/canonical/`: `run.log`, `results.mat`, `report.md`,
Ewald tables/convergence, point values, projection oracle, path levels, wall
points, all three coefficient comparisons, gates, decision matrix, and timing
CSV ledgers.  The canonical directory also records the observed Octave MFS
backend in `solver-backend.md`.
