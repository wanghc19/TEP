# I5.1d signed regular-image normal diagnostic

## Claim boundary

I5.1d replaces only the zero-centered regular-image contribution in the
I5.1c material-normal assembly.  It evaluates a nonzero signed retained Ewald
center and recomputes the affected retained and low-cell nonlinear sums.  The
artificial-wall module, local Kress center, off-surface center, high-mode
groups, and lifting module are inherited from a fresh same-run I5.1c return.

The result is conditional on exact finite special-function evaluation:
`FINITE_SPECIAL_FUNCTION_EVAL_ASSUMED_EXACT`.  No enclosure for that
condition is implemented, so `reliable_eval_enclosure_pass=false` and
`total_reliable_pass=false`.  The numerical output is therefore a
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` conditional diagnostic, not a reliable or
roundoff-inclusive continuous residual bound.

## Repaired RNC theorem mapping

The governing result is (RNC-1)--(RNC-9) in `s-kress-real.md`.  Its geometric
argument uses the holomorphic speed branch
$s_c=(z_1'^2+z_2'^2)^{1/2}$, separate source and target strips, and the
arclength Fourier phase.  The present circle is only an instance adapter; the
theorem does not use circle Fourier/Bessel diagonalization.

| theorem item | implementation object | ownership |
|---|---|---|
| (RNC-1), (RNC-2) | `LOCAL_ewald_signed_coordinates`, source/target normal contractions, `raw_normal_rows` | retained raw regular-image normal center |
| physical sign after (RNC-9) | `physical_normal_rows=-raw_normal_rows` | regular action is subtracted exactly once from the material defect |
| (RNC-4) | `source_quadrature_row_radius` | source trapezoid error only |
| (RNC-5) | `target_quadrature_row_radius` | target DFT/trapezoid error only |
| (RNC-6) | `finite_special_function_eval_row_radius` | set to zero only under the named conditional assumption |
| (RNC-7) | `M_R_row_radius`, `M_I_row_radius`, `M_T_row_radius`, `M_L_row_radius` | reciprocal, image, retained-image Taylor, and local-canonical omissions |
| (RNC-8) | `total_retained_row_radius` | sum of the four disjoint telescope radii |
| retained assembly | `material_delta.finite_*` | state-scaled signed center and radius |
| propagated low cells | `material_delta.low_cell` | complete center row map and regular unit radius composed with each frozen side map |

The exact implemented telescope is

$$
\begin{split}
d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}
-\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}
={}&\mathcal D_\ell\mathcal A(K^{\mathrm{nor}}-K_Q^{\mathrm{nor}})\\
&+(\mathcal D_\ell-\mathcal D_{N_t,\ell})\mathcal A K_Q^{\mathrm{nor}}\\
&+\mathcal D_{N_t,\ell}(\mathcal A-Q_{N_s})K_Q^{\mathrm{nor}}\\
&+\bigl(\mathcal D_{N_t,\ell}Q_{N_s}K_Q^{\mathrm{nor}}
-\widetilde d_{\ell,\mathrm{reg}}^{\mathrm{raw,nor}}\bigr).
\end{split}
$$

The four lines are assigned respectively to the M-R/M-I/M-T/M-L Ewald
omission, target quadrature, source quadrature, and finite evaluation.  They
are not reused in the high target-Fourier tail.  In the current run the last
radius is zero by assumption, not by a proved enclosure.  This is the only
reliability blocker introduced by the nonzero regular center.

## Implementation architecture and gates

The builder
`test/i5/residual-numerator-v3/build_residual_numerator_input_v3.m` consumes
the explicit self-contained I5.1c input and the frozen I3 artifact.  It
revalidates the frozen scalar, density, state, cutoff, branch, and propagation
contracts; streams the signed reciprocal, nonzero-image, and branch-free local
finite sums; and writes one create-once v3 input.  It reads no historical
result.

The evaluator
`test/i5/residual-numerator-v3/residual_numerator_v3.m` obtains a fresh I5.1c
baseline by function return in the same invocation.  It replaces the regular
material center and radius, recomputes all retained material summands and the
$n\ge J$ low-cell block-power term, and carries the index-disjoint material
high groups and complete lifting result unchanged.  All four solve counts are
zero.

The structural gates require the artifact match, outgoing/non-Wood reciprocal
branch, signed raw row, one physical minus sign, separate positive source and
target strips, the holomorphic speed branch, finite nonnegative M-R/M-I/M-T/M-L
tails, disjoint ownership, and complete retained/low-cell recomputation.  The
diagnostic also records that sampled maxima, inter-level drift, and empirical
safety factors were not used.  Its conclusion is deliberately split as

- `conditional_assumption_pass=true` and
  `conditional_diagnostic_pass=true`;
- `FINITE_SPECIAL_FUNCTION_EVAL_ASSUMED_EXACT=true`;
- `reliable_eval_enclosure_pass=false` and
  `total_reliable_pass=false`.

The shortest route to reliability is a finite, outward enclosure of every
retained `Faddeeva_erfc`, `expint`, exponential, geometry, density, speed, and
phase node contribution through coordinate derivative order two, propagated
by (RNC-6).  Ordinary library evaluation cannot discharge this obligation.

## Canonical attempt, command, and resources

The explicit data inputs were

- `test/i5/residual-numerator-v2/input/residual-numerator-v2-run-03.mat`;
- `test/i3/e-cap/input/fbie-a1-certificate.mat`;
- the geometry, wall squares, and other frozen contracts already embedded in
  the self-contained I5.1c input.

The canonical command had the following reproducible core:

```text
/usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch "addpath(repo); addpath(v2_experiment); addpath(v3_experiment); checkcode(v3_builder,'-id'); checkcode(v3_evaluator,'-id'); build_residual_numerator_input_v3(v2_input,artifact,v3_input); residual_numerator_v3(v3_input,v2_input,same_run_v2_output,v3_output);"
```

The planned budget was at most 15 minutes and 1.7 GiB.  Run-01 failed during
restricted-sandbox MATLAB startup before the builder and created no scientific
artifacts.  The same attempt's canonical run-02 completed in 18.21 s with
maximum RSS 978993152 bytes; its internal evaluator time before save was
1.3035255 s and its workspace proxy was 99.4485102 MiB.  MATLAB Code Analyzer
reported zero issues in both v3 files.

Canonical paths are

- input: `test/i5/residual-numerator-v3/input/residual-numerator-v3.mat`;
- fresh same-run baseline:
  `test/i5/residual-numerator-v3/output/residual-numerator-a1/baseline-v2-run-01.mat`;
- result: `test/i5/residual-numerator-v3/output/residual-numerator-a1/result.mat`;
- diary, audit, and resources: `run-02.log`, `audit-run-02.txt`, and
  `resource-run-02.txt` in the same output directory.

## Run-02 numerical decomposition

All numbers below exclude floating-point rounding certification and retain the
finite-special-function assumption.

| quantity | finite square | tail square | module bound |
|---|---:|---:|---:|
| artificial wall | $3.5088928806097918\times10^{-20}$ | $1.2402726533962042\times10^{-63}$ | $1.8732039079101324\times10^{-10}$ |
| material normal | $1.9215047644499741$ | $1.1504505415838253$ | $1.7526994340256401$ |
| lifting, carried unchanged | not recomputed by v3 | not recomputed by v3 | $748498.34329471563$ |

Thus the conditional diagnostic numerator is

$$
\widehat{\mathcal M}=748500.0959941498.
$$

For the material-normal module, the finite norm is
$1.3861835248083041$, the signed combined-center weighted norm is
$2.3193123719893792\times10^{-13}$, and the total retained-radius weighted
norm is $1.3861835248081846$.  The material tail separates into
$1.1504505415837849$ from the unchanged same-defect high groups and
$4.0365507134498529\times10^{-14}$ from the recomputed low-cell term.

The regular retained row has signed-center Frobenius norm
$0.93831111557998581$.  Its physical retained weighted norm is
$0.6063210583687928$.  The maximum unit-row radii are

| owner | maximum radius |
|---|---:|
| source quadrature | $6.4335982057355448\times10^{-42}$ |
| target quadrature | $7.661073710189474\times10^{-20}$ |
| finite special-function evaluation | $0$ under the explicit assumption |
| M-R | $8.2910496824456709\times10^{-25}$ |
| M-I | $3.4914778993599262\times10^{-11}$ |
| M-T | $2.0529395015278222\times10^{-29}$ |
| M-L | $8.9951561629918053\times10^{-12}$ |
| total regular retained radius | $4.3909935233202631\times10^{-11}$ |

The fresh same-run I5.1c baseline had
$\widehat B_\Upsilon=3006.7225021204808$.  The reduction to
$1.7526994340256401$ is diagnostic evidence about the signed center, not a
reliable-enclosure claim, because (RNC-6) remains open.
