# I3.1 lead-aware continuous strong residual

This experiment implements
[[research/projects/eig-apost/implementation/i3/design-3-1b|the frozen I3.1-B design]].
It evaluates only the saved candidate

$$
\widehat k_h=1.832770289108157
$$

at the fine $n_{\mathrm{tot}}=256$, $M=48$ discretization. It does not scan or
refine $k$.

## Numerical object

The code recovers the right and left whole-subspace propagation actions from
the frozen QZ bases, then builds one smooth finite Fourier--Hermite/bubble
trial across every material cell. Interior and exterior BIE fields supply
fixed training data; they are not spliced together to define the trial.

The main computed quantity is

$$
\frac{\|(A-\widehat k_h^2)u_h^{\mathrm c}\|_{L^2(B,\rho)}}
{\|u_h^{\mathrm c}\|_{L^2(B,\rho)}}.
$$

The implementation uses $\rho=1$ outside each disk and $\rho=17$ inside;
the residual integral therefore carries the corresponding $\rho^{-1}$ weight.
It retains the stored-double center dispersion
$\beta_m^2+\gamma_m^2-\widehat k_h^2$, and sums both infinite leads by
whole-matrix doubling. All quadrature and tail margins use ordinary double
precision, so any interval is a computed diagnostic rather than a certified
enclosure.

## Entry points and dependencies

- check_g_resid.m is the sole experiment entry.
- i31_bie_fit.m is the only scientific helper. It owns the free/QP D and
  minus-S oracle, BIE sample maps, Fourier projection, fixed QR fit, holdout,
  and raw-field diagnostics.
- Runtime dependencies are MATLAB, the unique eval_i21/i21_kproxy evaluator
  on the normal MATLAB path, and its required package functions.
- The code does not inspect Git, Markdown, manifests, hashes, or historical
  output and does not search for a repository root.

The completed Revision B command was:

    matlab -batch "addpath(fullfile(pwd,'test','i3','g-resid'),fullfile(pwd,'test','i2','k-count')); check_g_resid('lead-a3');"

The append-only output directory is:

    test/i3/g-resid/output/lead-a3/

Only result.mat and report.md may be written there.

## Attempt and startup history

| Attempt/check | Scope | Result | Artifacts and interpretation |
|---|---|---|---|
| `lead-a1` | Sandboxed MATLAB startup | Consumed after 3.3 seconds with exit code 137 | The runner was not entered, evaluator calls were zero, no output directory was created, and all scientific gates remain `NOT_REACHED`. This is a startup/preflight failure, not a numerical or memory-gate result. |
| Startup smoke | Outside-sandbox command `/Applications/MATLAB_R2023b.app/bin/matlab -batch "disp(version);"` | Exit 0 after 17.470671 seconds; `R2023b 23.2.0.2365128` | Confirms that MATLAB can start in the outside-sandbox environment; it does not run the experiment. |
| `lead-a2` | Revision A experiment attempt | Consumed implementation failure after 17.421279875 seconds; shell exit 0 but producer status `I3_1_EXECUTION_UNAVAILABLE` | `finite_input.pass=1`; together with the frozen control flow, this reconstructs two completed evaluator calls, rather than reading a producer call-count field. The density oracle then failed with `MATLAB:UndefinedFunction` because a local matrix variable named `pi` shadowed the built-in constant. The preserved artifacts are `output/lead-a2/result.mat` and `report.md`; the density gate is `NOT_DETERMINED` and all later scientific gates are `NOT_REACHED`. Peak active-object memory was 61.1546688079834 MiB and `retry_count=0`. |
| `lead-a3` | Revision B formal numerical attempt | Producer status `I3_1_CONFORMING_RECONSTRUCTION_UNRESOLVED` after 373.254082 seconds | Finite input, density representation, and propagation passed. The fixed BIE-informed fit failed its preregistered holdout gate; center, Gram, quadrature, tail, residual-ratio, and interval gates are `NOT_REACHED`. Peak active-object memory was 62.706804 MiB and `retry_count=0`. The output directory contains only `result.mat` and `report.md`. |

The exact captured `lead-a1` terminal output was:

```text
2026-08-16 22:14:20.956 MATLAB_maca64[1211:15409342] XType: Using static font registry.
Could not create on-disk crash report: failed opening file: Operation not permitted: unspecified iostream_category error

MATLAB is exiting because of fatal error
```

## Formal numerical result

The finite input passed with physical score $5.6553167\times10^{-11}$, raw
residual $3.1457643\times10^{-10}$, backward error
$5.2067133\times10^{-13}$, and minimum factor rcond
$1.0481727\times10^{-8}$. Rebuilt-$A_{\mathrm{QP}}$, density sign/scaling,
manufactured potential, and frozen-$Z$ propagation checks also passed. The two
propagation actions had rank 97, rcond about $0.497733$, and invariant residuals
below $6.3\times10^{-16}$.

The first failing gate was the fixed BIE-informed fit:

| Bubble order | Left holdout error | Right holdout error | Frozen limit |
|---:|---:|---:|---:|
| $J=4$ | $4.5224212$ | $4.5224212$ | diagnostic coarse level |
| $J=8$ | $5.1380284$ | $5.1380284$ | at most $0.20$ and no worse than $J=4$ |

Both fit matrices had full rank; their rcond values were $0.268165$ and
$0.068181$ for $J=4,8$. Thus the failure is not a rank-gate failure. It is a
valid negative result: the frozen pipeline did not establish the quality of its
BIE-informed reconstruction.

The training and holdout targets were only $4.2207\times10^{-5}$ and
$5.3152\times10^{-5}$ from the material circle. These are about $0.86\%$ and
$1.08\%$ of the $N=256$ source-panel arc scale $4.91\times10^{-3}$. Direct
layer-potential close evaluation was not separately qualified, so the large
holdout error cannot be attributed solely to the bubble basis or fit metric.
No new attempt is authorized by this result.

## Frozen gates and resources

- Circle scaling and rebuilt-$A_{\mathrm{QP}}$ identity: $10^{-13}$.
- Manufactured D/minus-S jump errors: finest at most $0.25$ and at most
  $0.75$ of the coarsest; global-$x$ derivative errors at most $10^{-5}$.
- Frozen-$Z$ action rcond at least $10^{-8}$ and invariant residual at most
  $10^{-10}$.
- Fine BIE holdout error at most $0.20$ and no worse than the coarse bubble
  order.
- Center correction/raw $H^2$ ratio at most $0.10$.
- Coarse/fine full-waveguide field, residual, ratio, and $H^2$ changes at
  most $10^{-5}$; $J=4/8$ ratio change at most $0.10$.
- Each field/residual/$H^2$ tail share at most $10^{-6}$ after a computed
  whole-matrix contraction margin.
- Soft/hard wall time: $900/1800$ seconds. Active-object limit: $512$ MiB.
  Expected cost is 2--15 minutes and 200--400 MiB.

## Interpretation

`lead-a3` stopped at the first scientific failure required by the frozen
precedence. It did not produce a qualified whole-waveguide trial or a continuous
strong-residual estimator candidate. It therefore cannot provide a reliable
numerical enclosure, establish the projected gap, identify a continuous
eigenvalue, or enter I3.2. The accepted interpretation is
`VALID NEGATIVE / CONFORMING_RECONSTRUCTION_UNRESOLVED`; the close-evaluation
versus basis/metric cause remains unresolved.

The independent post-run review is
[[research/projects/eig-apost/implementation/i3/review-3-1b|review-3-1b]].
