# Reconstructed-field Rayleigh quotient

`theta-v1` means the reconstructed-field Rayleigh quotient, version 1. `JSON`
means JavaScript Object Notation; `CSV` means comma-separated values; `RSS`
means resident set size. I9.6 means implementation experiment 9.6.

Purpose: compute the ordinary whole-strip quotient of the saved, corrected
control and main reconstructions from I9.6 formal run-03. Input data are read
in place; only scalar outputs and logs are retained here.

The input is
`/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03/`.
The entry point loads only `F_bNNN`, `dF_bNNN`, and `cols` from its strip files.
It reads cell indices and reference scalar norms from the explicit input's
`result.json`; `native.mat` and the saved proxy variables are unnecessary.

## Method and configuration

The source is assembled in batches of 32 modes, adding the saved correction.
The one-based global column of local zero-based column $j$ in cell $c$ is
$(c+16)N+j+1$. The source and reconstruction formulas follow
`LOCAL_norms_level` and `LOCAL_yukawa_batch` in
[dtn_bound_i96.m](/Users/whc/Documents/Work/dot-research/test/i9/dtn-bound-v1/dtn_bound_i96.m).
The geometry point and derivative functions are copied verbatim from that
file. The model is the formal configuration: $\beta=0.5$, transverse and lead
periods both one, star scale one and density four, lead density 17, shape
parameters 0.12 and 0.20, normalized area radius 0.2, background density one,
and 16 retained cells on each side.

For $q_m=\beta+2\pi m$, $a_m^2=s+q_m^2$, and
$s=\mu_0=1.558438079544167^2$, each column uses
$f_m=A+Bt$ and
$w_m=(A+Bt)/a_m^2+z_-e^{-a_mt}+z_+e^{-a_m(h-t)}$.
The exponential exterior tails are retained analytically. A 12-point Gauss
rule per column evaluates the norm and both numerator formulas:

$$
K_{\rm identity}=\sum_m\operatorname{Re}\int\overline{f_m}w_m-s\|w_d\|_0^2,
\qquad
K_{\rm direct}=\sum_m\int\bigl(|w_m'|^2+q_m^2|w_m|^2\bigr).
$$

Material mass is $\|w_d\|_0^2$ plus three times the star integral and 16 times
each of the 32 lead-inclusion integrals. All crossings of each vertical line
with the true curve are found by inversion on monotone parameter arcs;
the curves have up to four crossings. The x panels split at every grid
boundary and every vertical tangent. On each panel $[l,r]$, the map
$x=l+(r-l)\sin^2(\pi t/2)$ removes the square-root endpoint behaviour.

The production y integral uses the exact finite Fourier autocorrelation:
if $C_\ell=\sum_m w_{m+\ell}\overline{w_m}$, an interval $[y_a,y_b]$ gives
$(y_b-y_a)C_0+2\operatorname{Re}\sum_{\ell>0}C_\ell
\int_{y_a}^{y_b}e^{2\pi\mathrm i\ell y}\,dy$.
Fast Fourier transforms form the autocorrelation, padded to prevent circular
aliasing. Independent Gauss rules also integrate the same trigonometric
polynomial. Final settings are:

| Level | $N$ | $M$ | x orders | Independent y orders |
|---|---:|---:|---|---|
| control | 256 | 128 | 16, 32 | 128, 256 |
| main | 512 | 256 | 16, 32 | 256, 512 |

Exterior inclusion mass is bounded above by $16T_d^2$, where $T_d^2$ is the
whole exterior unweighted mass. This gives an uncertainty of at most
$2.15\times10^{-13}$ in either reported quotient, so treating that tiny mass
as background resolves the requested scale. The ordinary results below use
the fine x rule and exact y integration.

Planned control cost: 1–5 minutes, under 1.6 GiB RSS. Planned main cost: 5–15
minutes, under 2.3 GiB RSS. Each is serial, monitored at one-second intervals,
with a 30-minute soft stop, 40-minute hard limit, and 3 GiB RSS limit.

## Reproduction

Run from `/Users/whc/Documents/Work/dot-research`. These are the commands for
the accepted runs; choose fresh run numbers when repeating them. The monitor
creates the run directory and the MATLAB entry creates its `science` child.
The approved execution context must permit MATLAB startup and `ps` sampling.

```sh
python3 test/numerical-directions/diagnostics-v1/monitor.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-003 \
  "addpath('/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1'); reconstructed_theta('/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03','/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-003/science','control');"

python3 test/numerical-directions/diagnostics-v1/monitor.py \
  /Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-005 \
  "addpath('/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1'); reconstructed_theta('/Users/whc/Documents/Work/epost/test/i9/dtn-bound-v1/output/attempt-1/run-03','/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-005/science','main');"
```

The monitoring code is reused without modification. It samples process-tree
RSS every second and enforces the resource limits above. Scientific settings
are in `reconstructed_theta.m`, with the level as an explicit argument.
Each `science/result.json` contains energies, all checks, configuration,
per-inclusion masses and areas; `science/modes.csv` contains scalar mode
norms and energies. `monitor.json` records wall time and peak RSS.

## Results

Scalar results are in [control result.json](/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-003/science/result.json)
and [main result.json](/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-005/science/result.json).
Resource measurements are in their
[control monitor.json](/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-003/monitor.json)
and [main monitor.json](/Users/whc/Documents/Work/dot-research/test/numerical-directions/theta-v1/output/run-005/monitor.json).

The reference values, computed in binary64 from the stated wave numbers, are
$\mu_{\rm BIE}=2.428728670022710$ and $\mu_0=2.428729247773311$.

| Quantity | Control, run-003 | Main, run-005 |
|---|---:|---:|
| Whole-strip $\|w_d\|_0^2$ | 1.000000047462051 | 1.000000070553025 |
| Saved whole-strip norm squared | 1.0000000474620514 | 1.0000000705530234 |
| Relative norm difference | $4.44\times10^{-16}$ | $1.55\times10^{-15}$ |
| Numerator, energy identity | 6.289626552759938 | 6.289626776495014 |
| Numerator, direct derivatives | 6.289626552759962 | 6.289626776494981 |
| Relative numerator difference | $3.81\times10^{-15}$ | $5.22\times10^{-15}$ |
| Denominator, including background exterior mass | 2.589678523642329 | 2.589678643119736 |
| **$\theta$** | **2.428728699465642** | **2.428728673808740** |
| **$\theta-\mu_{\rm BIE}$** | **$+2.9442933\times10^{-8}$** | **$+3.7860306\times10^{-9}$** |
| $\theta-\mu_0$ | $-5.4830767\times10^{-7}$ | $-5.7396457\times10^{-7}$ |
| x-doubling change in $\theta$ | $-2.66\times10^{-12}$ | $+6.22\times10^{-15}$ |
| y-doubling change in $\theta$ | $+4.44\times10^{-16}$ | zero at displayed precision |
| Fine Gauss y result minus exact y result | $+4.44\times10^{-16}$ | $+4.44\times10^{-16}$ |
| Exterior inclusion uncertainty in $\theta$ | $2.145\times10^{-13}$ | $2.145\times10^{-13}$ |

The level change is
$\theta_{\rm main}-\theta_{\rm control}=-2.5656902\times10^{-8}$.
Main's Rayleigh-center error is about 153 times smaller than the original
candidate's $\mu$ error. It is at the few-$10^{-9}$ scale; control is at the
few-$10^{-8}$ scale. The x/y convergence checks resolve both differences.
The two auxiliary levels still show a visible representation effect.

Area sanity checks use a separate 128-point boundary integral
$\frac12\int(xy'-yx')\,dt$:

| Inclusion template | Boundary area | Control fine slicing area | Main fine slicing area |
|---|---:|---:|---:|
| Left trilobe | 0.12566370614359154 | 0.12566370614359196 | 0.12566370614359162 |
| Center star | 0.19415042599184900 | 0.19415042599184806 | 0.19415042599184915 |
| Right trilobe | 0.12566370614359154 | 0.12566370614359170 | 0.12566370614359176 |

Maximum relative area disagreement is $4.86\times10^{-15}$ for control and
$1.77\times10^{-15}$ for main. Repeated lead cells share their template's
area and crossings, while their complex field amplitudes are evaluated
separately.

For a two-sided Kato–Temple bound on an isolated mode, the inputs would be a
same-field Rayleigh center $\theta$, normalized residual variance $\eta^2$,
and certified lower/upper separating edges $\alpha<\theta<\beta$. The two
corrections are $\eta^2/(\beta-\theta)$ and $\eta^2/(\theta-\alpha)$. The
existing [I9.6 residual bounds](/Users/whc/Documents/Work/dot-research/test/i9/dtn-bound-v1/README.md) at $\mu_0$ are
$R_\mu=1.2104310\times10^{-4}$ (control) and
$4.4511618\times10^{-4}$ (main); for the same field they give
$\eta^2\le R_\mu^2-(\theta-\mu_0)^2$. Those bounds concern the exact source
solution $w$, whereas this diagnostic measures the saved finite $w_d$.
Certification therefore needs a Rayleigh/residual transfer between these
fields, or a separately evaluated residual for $w_d$, in addition to both
separating edges. The small reference errors of the Rayleigh centers support
pursuing that second-order route.

## Runs and cost

| Run | Configuration and outcome | Wall, including startup/exit | Peak process-tree RSS |
|---|---|---:|---:|
| run-001 | Startup failed in the sandbox; no scientific calculation | unavailable | unavailable |
| run-002 | Control, x 8/16 and y 128/256; x change $1.1275\times10^{-8}$ failed the convergence gate | 24.68 s | 1.179 GiB |
| run-003 | Control, x 16/32 and y 128/256; all checks pass | 23.70 s | 1.104 GiB |
| run-004 | Main, x 16/32 and y 128/256; y change $4.8624\times10^{-10}$ exceeded the chosen $10^{-10}$ gate | 57.92 s | 1.450 GiB |
| run-005 | Main, x 16/32 and y 256/512; all checks pass | 91.60 s | 1.373 GiB |

The scientific function took 12.96 s for accepted control and 77.04 s for
accepted main. Runs were serial, and main began after control passed checks
1–3. The failed convergence checks drove only the stated quadrature-order
changes. The final source reproduces accepted run-003 and run-005; the
earlier order choices are recorded above and in each result's parameters.

Run-001's process sampler raised
`PermissionError: [Errno 1] Operation not permitted: 'ps'`. MATLAB reported
`Could not create on-disk crash report: failed opening file: Operation not permitted: unspecified iostream_category error`
and `MATLAB is exiting because of fatal error`. The approved monitored
execution context succeeded without changing MATLAB settings or source data.
The startup record is retained in `output/run-001/failure.json` and `run.log`.
