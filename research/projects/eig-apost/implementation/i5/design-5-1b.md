# I5.1b design: real-variable Kress residual-numerator instance

## Scope, authority, and current pre-run state

This experiment instantiates the conditional theorem in
[[research/projects/eig-apost/phase3-analysis/residual-bound/s-kress-real]].
It evaluates only the frozen reconstruction and does not solve an eigenvalue,
a BIE density, a QZ subspace, or a propagation matrix.  It does not evaluate
the estimator denominator or effectivity.  The governing decomposition is

$$
\|R\|_{\mu,*}
\le \widehat B_{\Gamma_\pm}+\widehat B_\Upsilon
+\widehat B_{\mathrm{lift}}.
$$

The old `residual-numerator-a1` source is read-only evidence.  Its complex
product-strip/P32 radius and its coupled values $N=512$, $L=256$ are not
inputs to I5.1b.  I5.1b uses the real-variable bounds (KR-15)--(KR-25), fixes
$L$ before $N$, and requires

$$
N>2\max\{L,M_\eta\}.
$$

The builder tests the predeclared increasing schedule
$L\in\{32,64,128,256\}$.  It selects the first value whose complete local,
regular-image, and off-surface angular tails meet both allocations; if none
does, it selects $L=256$ so that the finite result can still report the failed
tolerance.  Only after freezing $L$ does it set the smallest admissible even
$N=2\max\{L,M_\eta\}+2$.  Thus $N_\eta=256$ and $M_\eta=128$ remain frozen,
whereas $L$ and $N$ have separate stopping roles.

The builder now constructs the KR-15 circle-instance certificate itself,
including the second source derivatives of
$C_{\kappa_e,2}^{\mathrm{tan}}-C_{\kappa_i,2}^{\mathrm{tan}}$ and
$D_{\kappa_e,2}^*-D_{\kappa_i,2}^*$.  It also constructs conservative
zero-center bounds for the complete local operator, regular-image Ewald
action, and finite off-surface Rayleigh action.  The pre-run state is
`GO`, as recorded in `review-5-1b.md`; ordinary sampled maxima cannot create
or override a gate.

## Explicit interfaces

The versioned experiment lives in `test/i5/residual-numerator-v1/`.  Its two
entry points are

```matlab
experiment_input = build_residual_numerator_input_v1( ...
  artifact_path, curve_contract_path, wall_finite_squared, ...
  wall_tail_squared, input_path, wall_provenance_label)

result = residual_numerator_v1(input_path, output_path)
```

The two paths are explicit.  The builder reads the frozen I3 artifact and the
accepted circle curve contract.  It receives the accepted wall finite and tail
squares as explicit nonnegative numeric inputs; the optional provenance label
does not authorize those values.  Thus no executable depends on a historical
experiment output.  The builder writes the self-contained I5.1b enclosure
bundle, and the evaluator reads only that new input.  Neither function reads
Markdown, Git metadata, historical outputs, or repository-relative paths, and
both refuse to overwrite an existing file.  The ordinary
floating-point experiment remains labelled
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`; it does not claim outward-rounded floating
point containment.

## Formula-to-code map

| code field | theory object | defining formula | role |
|---|---|---|---|
| `source_node_count` | $N_\eta$ | frozen density representation | immutable density provenance |
| `density_fourier_degree` | $M_\eta$ | maximum $|n|$ in the frozen coefficient map | strict separation gate |
| `configuration.residual_mode_cutoff` | $L$ | $|\ell|<L$ | retained/tail partition |
| `configuration.evaluation_node_count` | $N$ | even target and source grid | Kress and DFT evaluation |
| `local_real_derivative_certificate.*.source_L1_p` | $(S_{1,p},S_{2,p})$ | (KR-15) | density-inclusive source product-rule radius |
| `local_real_derivative_certificate.*.target_diagonal_sup` | $C_{j,q}$, $j=1,2$, $q=0,1,2$ | (KR-15) | complete-action derivative bound |
| `local_real_derivative_certificate.*.identity_derivative_upper` | $\|J^{(q)}\|_\infty$ | (KR-18) | identity included once |
| `local_rows.*.center_policy` | identity-only local center | (KR-21) | no operator-series center is evaluated |
| `local_rows.*.series_delta_*_upper` | $\Delta_{j,iq}$ | (KR-21) | whole discrete operator action about zero, including series tails |
| `retained.*_regular_radius` | $\epsilon_\ell^{\mathrm{reg}}$ | (KR-26) | Ewald finite and omitted terms |
| `retained.*_off_surface_radius` | $\epsilon_\ell^{\mathrm{off}}$ | (KR-26) | positive-distance action remainder |
| `tail_assembly.*` | square-root tail norms sharing one defect | (KR-28), (KR-31) | add norms before squaring |
| `disjoint_tail_squared` | disjoint cell/collar tail squares | (KR-28), (KR-31) | add after squaring |
| `wall_module` | $\overline F_{\Gamma_\pm}^2,T_{\Gamma_\pm}^2$ | (KR-32) | explicit accepted wall scalars and non-authorizing provenance label |

The MATLAB package names `M1`, `M2`, `L1`, `L2`, `Ls1`, `Ls2`, `N1`, and
`N2` remain API names only.  The theory objects are respectively
$S_{\kappa,j}$, $D_{\kappa,j}$, $D_{\kappa,j}^*$, and
$C_{\kappa,j}^{\mathrm{tan}}$.  The normal action keeps the explicit
$T_e-T_i$ split.  It uses $T_i-T_e=-(T_e-T_i)$, and the common cotangent term
must be cancelled before any absolute bound.

## KR-15 enclosure construction

For the current circle adapter, the shape-general theorem is not changed.
The adapter may simplify the general cancellation-safe quantities to

$$
q=4R^2\sin^2\frac{h}{2},\qquad c=R^2,\qquad
p_n=\frac q2,\qquad p_T=R^2\sin h,
$$

only to certify this frozen geometry.  It must not diagonalize the layer
operators in a circle Fourier/Bessel basis.  It instead evaluates the same
Kress split as the general theorem by finite $J_\kappa$ and
$Y_\kappa^{\mathrm{reg}}$ power series with the (P14) factorial tails.

For every density coordinate and $0\le r\le3$, the finite coefficients give

$$
A_{\eta,r}=\sum_n |n|^r\|C_{\eta,n}\|_2.
$$

If a scalar convolution factor has certified derivative bounds
$f_0,f_1,f_2$, then the complete source second derivative is bounded by

$$
f_2A_{\eta,0}+2f_1A_{\eta,1}+f_0A_{\eta,2}.
$$

For the Maue term containing $\tau'$, the last three density bounds are
$A_{\tau,1},A_{\tau,2},A_{\tau,3}$.  Simultaneous differentiation
$\partial_t+\partial_u$ kills the convolution factor and acts only on the
finite density.  These finite Leibniz bounds supply every number in (KR-15).

The required smooth diagonal differences are evaluated through (KR-13):

$$
C_{\kappa_e,2}^{\mathrm{tan}}
-C_{\kappa_i,2}^{\mathrm{tan}}=p_TW,
\qquad
D_{\kappa_e,2}^*-D_{\kappa_i,2}^*=p_nW.
$$

The certificate includes the value and first two $h$-derivative bounds of
both products.  A grid maximum without a derivative or analytic remainder is
rejected.  The implementation deliberately takes the integral-operator
center to be zero: the complete absolute $J/Y$ series sums, including their
factorial tails, are propagated through the Kress weights and normalized DFT
as $\epsilon_\ell^{\mathrm{series}}$.  The value and normal identity rows are
the only local centers.

## Source, target, and Fourier remainders

For $p=2$, the evaluator computes the explicit constants in (KR-17), then

$$
\epsilon^{\mathrm{src}}
\le \frac{2\pi s_+}{\sqrt P}
\left(S_{1,2}C_{2,N}^K+S_{2,2}C_{2,N}^T\right).
$$

This is the supremum version of (KR-20), not a sampled target maximum.  From
the KR-15 simultaneous derivatives it forms $\mathcal H_q$ by (KR-18) and
computes each $\epsilon_\ell^{\mathrm{tgt}}$ by (KR-19).  The retained local
radius is exactly

$$
\epsilon_\ell^{\mathrm{self}}
=\epsilon_\ell^{\mathrm{src}}
+\epsilon_\ell^{\mathrm{tgt}}
+\epsilon_\ell^{\mathrm{series}}.
$$

The identity is contained in the retained local center and target derivative
bound once.  It has no source or zero-center operator radius.  The omitted local
normal and lifting tails are computed from (KR-22)--(KR-25) over
$|\ell|\ge L$; the positive and negative Nyquist aliases are therefore not
retained rows.

## Assembly and non-overlap gates

For each already-expanded singleton or finite-cell retained row, the
enclosure bundle supplies the complex combined center and the regular-image
and off-surface radii.  The evaluator adds the local, regular-image, and
off-surface centers before taking an absolute value, then adds their radii by
the triangle inequality.  Trace or lifting weights are applied afterward.

The bundle records tail norms in physical-defect groups.  Local Fourier,
regular-image/Ewald, and off-surface tail norms in the same group are added
before squaring; cell/collar terms known to be disjoint are supplied as
separate nonnegative squares.  The following Boolean gates must all pass:

1. frozen density sign and Fourier-support audit;
2. $|\ell|<L$ retained and $|\ell|\ge L$ omitted, with no Nyquist row;
3. even $N$ and $N>2\max\{L,M_\eta\}$;
4. KR-13 diagonal cancellation and KR-15 full-torus enclosure;
5. source, target, and series radii present separately;
6. identity included exactly once in each local defect;
7. outgoing branch, non-Wood, all finite $1/\gamma_m$, and Ewald ratio gates;
8. off-surface clearance and quadrature enclosure;
9. wall theorem gate and both propagation block-power or Lyapunov gates;
10. tail-budget and finite-value gates; and
11. all eigenpair, density, QZ, and propagation solve counts equal zero.

No cancellation among omission radii is used.  No source, target, series,
Fourier, Ewald, off-surface, or cell tail may occur in two groups.

The circle adapter uses $x=4R^2\sin^2(h/2)$ only to instantiate the
shape-general factors.  In particular, the KR-11 quantity is assembled as

$$
W=2\left(|\log R^2|\,|\Delta J'|
  +|\Delta j_{\mathrm{shift}}|+|\Delta\mathfrak c'|\right),
$$

so the three coefficient families carry respectively the factors
$1/(2\pi)$, $2|c_\kappa|$, and $1/\pi$; none is missing the factor two.
The accepted curve contract is independently reproduced with
`geom.construct_cont`, and its CCW orientation, outward
$(y',-x')/|z'|$ normal, and unshifted density-node phase are gates.

For the regular image the center is zero.  The retained reciprocal and image
terms and finite local canonical series are bounded by elementary absolute
formulas; reciprocal, omitted-image, and local factorial tails are stored
separately.  No Faddeeva or exponential-integral library value is used.  The
kernel ordering is `K00`, `K01-source`, `K10-target`, `K11`.  The finite
Rayleigh off-surface action also has zero center and is enclosed by its frozen
finite support, outgoing branch, non-Wood margin, and positive distance.
Matrix-power sums use Frobenius norms as explicit upper bounds for the
spectral norm.  Artificial-wall value lifts retain the frozen flat-wall
finite rows and enclose the circle-to-wall action by its full positive-distance
radius; their high modes and cells are disjoint tail squares.

## Stopping and failure semantics

The builder checks $L=32,64,128,256$ in order and freezes the first passing
value, or the last value for a finite failed-tolerance report.  It then chooses
the smallest even $N$ satisfying the strict separation gate.  Because the
zero-center operator radius need not decrease with $N$, a failed retained-row
allocation is reported rather than triggering meaningless refinement.  The
cell cutoff is changed
only through its Lyapunov or block-power remainder.

Missing fields, NaN or Inf, a nonpositive bound that must be strict, a branch
or index mismatch, a failed factorial ratio, or a repeated ownership label is
an operational fail-closed condition.  A finite explicit remainder above its
budget is a scientific stopping failure and must be reported numerically; it
is not replaced by an empirical safety factor.  Inter-level differences,
plateaus, Richardson extrapolation, MFS fitting residuals, and FEM/BIE
agreement are neither computed nor accepted as gates.

## Planned run and provenance record

One complete run consists of certificate generation, input construction,
the evaluator, Code Analyzer, and the post-run audit.  Planned resources are
at most 25 minutes and 1.25 GiB peak memory; the default soft limits are
30 minutes and 2 GiB, with a 40-minute hard stop.  Dense $N\times N$ local
matrices must be processed one kernel family at a time and released before
the next family.  No second attempt is created for an operational repair.

## Attempt 1 run record

The independent pre-run review returned `GO`.  The first execution inside the
single scientific attempt used MATLAB R2023b with the following inputs:

- frozen artifact:
  `test/i3/e-cap/input/fbie-a1-certificate.mat`;
- curve contract:
  `test/i5/wall-curve-a1/input/circle-contract-a1.mat`;
- historical accepted wall result, subsequently rejected as an executable
  dependency by the post-run portability audit:
  `test/i5/wall-curve-a1/output/attempt-1/result.mat`.

The generated self-contained input is
`test/i5/residual-numerator-v1/input/residual-numerator-v1.mat`, and the result
is `test/i5/residual-numerator-v1/output/residual-numerator-a1/result.mat`.
The compact shell-command record for `run-01` and `run-02` is

```text
/usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch
  "addpath(repo_root); addpath(exp_dir); checkcode(builder,'-id');
   checkcode(evaluator,'-id');
   build_residual_numerator_input_v1(artifact_path,curve_contract_path,
     wall_result_path,input_path);
   residual_numerator_v1(input_path,output_path); print summary"
```

with standard error written to `resource-run-0N.txt`.  Thus the MATLAB
scientific sequence was Code Analyzer followed by

```matlab
build_residual_numerator_input_v1( ...
  artifact_path, curve_contract_path, wall_result_path, input_path);
residual_numerator_v1(input_path, output_path);
```

All launches belong to `output/residual-numerator-a1/`.  `run-01` was an
operational sandbox launch failure before any scientific result.  `run-02`
completed the builder and evaluator in 19.24 seconds with a measured maximum
resident set size of 927,629,312 bytes; only its subsequent console-summary
expression used the nonexistent field `density_fourier_degree`.  `run-03`
was therefore a read-only extraction from the already completed result, not a
new scientific method or attempt.  It took 12.79 seconds and 743,571,456 bytes
maximum resident set size.  Its compact command was the same
`/usr/bin/time -l ... matlab -batch` wrapper, loading only the self-contained
input, result, and Code Analyzer MAT files and writing the detailed field
summary to `run-03-postprocess-log.txt` and resource data to
`resource-run-03-postprocess.txt`.  The persisted Code Analyzer report contains five
builder performance/style messages and zero evaluator messages; none is a
correctness error.

The explicit tail schedule selected $L=256$ after none of
$32,64,128,256$ met both allocations.  The strict separation construction
then selected $N=514$ for $N_\eta=256$ and $M_\eta=128$, so
$514>2\max\{256,128\}$.  Every structural gate passed, including the branch,
non-Wood, geometry, diagonal-cancellation, KR-15, KR-21, Ewald,
off-surface, propagation, wall, identity, index-partition, and disjoint-tail
gates.  The four solve counts are zero.

The ordinary roundoff-excluded result is

$$
\widehat B_{\Gamma_\pm}=1.8732039079101324\times10^{-10},
\qquad
\widehat B_\Upsilon=7256.776268586179,
$$

$$
\widehat B_{\mathrm{lift}}=2296548.3364069569,
\qquad
\widehat{\mathcal M}=2303805.1126755434.
$$

The finite/tail squares are respectively

| module | finite square | tail square | share of total majorant |
|---|---:|---:|---:|
| $\Gamma_\pm$ | $3.5088928806097918\times10^{-20}$ | $1.2402726533962042\times10^{-63}$ | $8.1309130603268403\times10^{-17}$ |
| $\Upsilon$ | $5.2660800661863901\times10^7$ | $1.1504516472771662$ | $0.0031499089174945277$ |
| lift | $1.318531587175792\times10^{12}$ | $1.9781875982693783\times10^6$ | $0.99685009108250533$ |

The retained-radius maximum is 3642.1532330519526 against the prescribed
$10^{-6}$ allocation.  The material and lifting tail allocations also fail.
Consequently the status is
`RETAINED_RADIUS_TOLERANCE_FAILED_ORDINARY`, and
`ordinary_complete=false`.  These failures mean that the displayed finite
majorant is too loose for the requested instance-level `GO`; they do not make
it NaN, infinite, or empirically selected.  Increasing $N$ is not an allowed
repair for the nonshrinking identity-only zero-center radius.  Every displayed
number remains `NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

### Bounded post-run portability repair

The post-run Skeptic identified one contract blocker: `test/AGENTS.md` forbids
an executable from requiring a historical experiment output.  The numerical
values above therefore remain evidence only and do not receive a post-run
verdict.  Their original files were preserved, without overwrite, as
`input/residual-numerator-v1-run-02-historical-wall.mat` and
`output/residual-numerator-a1/result-run-02-historical-wall.mat`.

The builder interface was repaired in the same attempt to

```matlab
build_residual_numerator_input_v1( ...
  artifact_path, curve_contract_path, ...
  3.5088928806097918e-20, 1.2402726533962042e-63, ...
  input_path, wall_provenance_label);
```

The two accepted wall squares are now explicit numeric inputs.  They are
validated as finite and nonnegative and copied into the self-contained input.
`wall_provenance_label` is optional descriptive text and is persisted with
`provenance_authorizes_value=false`; it is never read as authority.  The
canonical create-once `input/residual-numerator-v1.mat` and
`output/residual-numerator-a1/result.mat` paths were left free for the
coordinated same-attempt rerun.  No scientific formula, center, remainder,
cutoff, or frozen field changed in this repair.

After an independent static `GO`, `run-04` rebuilt the canonical input from
the explicit wall scalars and completed the evaluator with exit code zero.
The compact command was the `run-02` command above with the repaired builder
signature and without any historical wall-result path.  Its wall time was
16.68 seconds and its measured maximum resident set size was 959,922,176
bytes; the MATLAB-timed evaluator portion was 0.504627 seconds and the
reported MATLAB workspace was 65.844640 MiB.  Code Analyzer again reported
five builder performance warnings and zero evaluator messages.  The selected
$L=256$, $N=514$, all three module bounds, the total majorant, every structural
gate, and every failed numerical allocation were identical to the run-02
evidence recorded above.  `run-04` is the canonical contract-conforming
scientific result; `run-02` is retained only to document the repaired
operational history, and `run-03` remains a read-only extraction.

The independent post-run verdict is `GO` for this contract-conforming,
roundoff-excluded finite majorant.  This verdict certifies the formula and
explicit-remainder assembly in the stated arithmetic model; it does not turn
the three failed tightness allocations into passes and does not claim an
outward-rounded certificate.
