# I3.1 compact-support strong residual

This experiment implements the frozen I3.1 center-column baseline. At the
saved candidate it reconstructs the finite Fourier field in the homogeneous
empty center column, multiplies it by the fixed compact cutoff
$\chi(x)=\cos^2(\pi x)$, extends the result by zero, and computes the strong
residual norm ratio using three composite-Simpson levels.

## Entry point and completed attempt

`check_s_resid.m` is the only MATLAB entry point. The reviewed append-only tag
`center-a1` completed and wrote only:

```text
output/center-a1/result.mat
output/center-a1/report.md
```

The completed command was:

```matlab
matlab -batch "addpath(fullfile(pwd,'test','i3','s-resid'),fullfile(pwd,'test','i2','k-count')); check_s_resid('center-a1');"
```

The entry point depends on the unique `eval_i21` implementation and its
numerical package dependencies on the normal MATLAB path. It does not read Git
state, documentation, manifests, hashes, or historical outputs.

## Frozen numerical object

- Saved candidate: $\widehat k_h=1.832770289108157$.
- Fine discretization: $n_{\mathrm{tot}}=256$, $M=48$, $K=97$.
- Evaluator calls: one frozen I2.1 seed and one point at the saved candidate.
- Quadrature intervals: $N_x=512,1024,2048$.
- Internal Simpson and phase/scale relative gates: $10^{-10}$ and $10^{-12}$.
- Preregistered future frequency resolution: $10^{-6}$; gap fraction: $0.1$.
- Soft/hard runtime: $60/180$ seconds; active-object limit: $256$ MiB.

The implementation retains the double-precision dispersion term
$\beta_m^2+\gamma_m^2-\widehat k_h^2$ in the total residual. It separately
reports the two cutoff components and the dispersion component, while forming
the total residual before taking its norm.

## Result and interpretation boundary

The machine status is `I3_1_CONTINUOUS_STRONG_RESIDUAL_ESTIMATOR_CANDIDATE`. The
field norm was $0.840017038309255$, the strong residual norm was
$18.848991951433035$, and the computed $\lambda$-scale ratio was
$22.43882099031153$. The $512,1024,2048$ Simpson values reached a finest
relative change of $1.285108\times10^{-11}$; the phase/scale defect was zero.

The two cutoff-component norms were $17.144386396694575$ and
$4.9283050359497285$, whereas the stored-$\gamma$ dispersion component was only
$1.2992598309180477\times10^{-17}$. The fixed cutoff therefore dominates the
result. The run took $12.783586$ seconds with an $85.503675$ MiB peak
active-object snapshot. It had zero retries.

Composite-Simpson refinement
does not provide a rigorous quadrature enclosure, and the current sharp-disk
continuous projected essential gap is not established. Consequently this
experiment cannot certify an interval containing a continuous discrete
eigenvalue, identify a target mode, or bound the candidate's error to a
continuous eigenvalue.

The fixed one-cell cutoff is part of the frozen object. Its derivative terms do
not vanish as the I2 discretization is refined, so an order-one residual is a
valid result rather than permission to widen the cutoff or change the field in
the same attempt.

The first unavailable strict condition is
`RELIABLE_NUMERICAL_ENCLOSURE_UNAVAILABLE`. The current scientific interpretation
adds `FIXED_CELL_CUTOFF_RESOLUTION_INSUFFICIENT`: the nominal, non-certified
$\lambda$ interval crosses zero and is far wider than the preregistered frequency
resolution. This interpretation does not alter the append-only machine fields.

Design authority: [[research/projects/eig-apost/implementation/i3/design-3-1|I3.1 frozen design]].
Independent review: [[research/projects/eig-apost/implementation/i3/review-3-1|I3.1 review]].
