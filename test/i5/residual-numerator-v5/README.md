# I5.1f signed-centre oracle experiment

This experiment evaluates the frozen residual numerator with signed local,
regular-image, off-surface, and artificial-wall centres.  Its governing
contract is `design-5-1f.md`.  The current circle supplies only a geometry
adapter; no Fourier--Bessel operator diagonalization is used.

The numerical result is `CONDITIONAL_ON_EXACT_SPECIAL_FUNCTION_EVALUATION`;
finite arithmetic is not enclosed either.  The strings `delta_sf=UNRESOLVED` and
`delta_fp=UNRESOLVED` are persisted instead of numerical zero radii.  Every
analytic source, target, series, Ewald, Fourier, trace/lift, and propagation
remainder remains in the ideal majorant.  Therefore no result from this
directory is a reliable or outward-rounded certificate.

The portable entry points are

```matlab
build_residual_numerator_input_v5(artifact_path, curve_contract_path, input_path);
residual_numerator_v5(input_path, output_path);
```

The bounded launcher `run_residual_numerator_v5.sh` accepts nine explicit
paths (repository package root, experiment source directory, frozen artifact,
curve contract, input target, result target, run log, resource log, and audit
log).  Invoke it with `zsh`; it applies the authorized 45-minute and 3-GiB
hard stops to the exact MATLAB process tree.  The planned run is at most
30 minutes and 2 GiB.  Its first create-once targets are
`input/residual-numerator-v5-run-01.mat` and
`output/attempt-1/{result-run-01.mat,run-01-log.txt,resource-run-01.txt,audit-run-01.txt}`.

The builder reads only the explicit frozen artifact and curve contract.  It
does not read historical outputs, Markdown, Git state, or repository layout.
The caller supplies the experiment and required package sources through the
MATLAB path.  All solve counts remain zero.

The first run uses `output/attempt-1/`.  One complete builder/evaluator run is
planned for at most 30 minutes and 2 GiB, below the authorized hard limits of
45 minutes and 3 GiB.  No run is authorized before the independent code
review returns `GO`.

## Local code ledger

| code object | governing object | role |
|---|---|---|
| `density.tau_coeff`, `density.zeta_coeff` | finite Fourier coefficients of $\eta=(\tau,\zeta)^{\mathsf T}$, $\zeta=-\sigma$ | ideal centres and row-2 derivative sums; finite DFT arithmetic remains unresolved |
| `local.center.val/nor` | (I5.1f-6) | signed Kress centre with one identity |
| `local.radius.*` | (I5.1f-7)--(I5.1f-11) | source, target, and series analytic radii |
| `regular.raw_center.val/nor` | (I5.1f-12)--(I5.1f-14) | signed retained Ewald rows |
| `regular.radius.*` | (I5.1f-15)--(I5.1f-16) | source, target, and M-R/M-I/M-T/M-L radii |
| `off_surface.raw_center.val/nor` | (I5.1f-18) | frozen finite Rayleigh action |
| `wall` | (I5.1f-19)--(I5.1f-22) | signed wall-normal and wall-value modules |
| `material` | (I5.1f-2)--(I5.1f-5) | retained and block-power normal/lifting assembly |
| `delta_sf`, `delta_fp` | (I5.1f-1) | unresolved finite-evaluation obligations |
| `special_function_sensitivity_v5` | (I5.1f-23)--(I5.1f-37) | partial Faddeeva/E1 unit-error gains with matched finite/cell propagation |
| `local_certificate_sensitivity_v5` | (I5.1f-47)--(I5.1f-54) | narrow local log-gamma/exponential certificate sensitivity; no center re-evaluation |
| `regular_gamma_sensitivity_v5` | reviewed regular composite after (I5.1f-54) | partial regular gamma/downstream-log/exponential sensitivity; no signed-center re-evaluation |

## Canonical attempt-1 record

The exact launch used for the successful `run-02` was

```text
zsh /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/run_residual_numerator_v5.sh /Users/whc/Documents/Work/epost /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5 /Users/whc/Documents/Work/epost/test/i3/e-cap/input/fbie-a1-certificate.mat /Users/whc/Documents/Work/epost/test/i5/wall-curve-a1/input/circle-contract-a1.mat /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/input/residual-numerator-v5-run-02.mat /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/output/attempt-1/result-run-02.mat /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/output/attempt-1/run-02-log.txt /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/output/attempt-1/resource-run-02.txt /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/output/attempt-1/audit-run-02.txt
```

`run-01` was an operational parse failure before the builder performed any
scientific computation.  Its logs remain in `output/attempt-1/`.  The watchdog
observed 21 seconds and 783920 KiB maximum process-tree RSS; `/usr/bin/time -l`
recorded 19.20 seconds and 702464000 bytes maximum RSS.  The missing closing
parenthesis was repaired without changing the formula or method, and `run-02`
reused the same attempt.

The canonical MATLAB R2023b `run-02` completed in 44.12 seconds with
1083392000 bytes maximum RSS.  The watchdog observed 45 seconds and 1113152
KiB maximum process-tree RSS, well below the 45-minute and 3-GiB hard limits.
It selected $L=512$ and $N=2048$, so
$2048>2\max\{512,128\}$.  All four predeclared tightness allocations of 0.1
passed: high mode $0.056445843912354104$, retained local
$0.029725446625692306$, regular/wall analytic
$1.4325771221170876\,10^{-6}$, and cell tail
$7.5380644348098281\,10^{-11}$.

The largest retained local source/target/series radii were respectively
$3.245447133364849\,10^{-8}$, $1.1958720964772491\,10^{-9}$, and
$3.66896675098091\,10^{-60}$ for `val`, and
$4.2223419812958876\,10^{-7}$, $8.1816076420694372\,10^{-9}$, and
$1.9361895931756628\,10^{-59}$ for `nor`.  The material finite-state
cancellation ratios were $9.5741774198297291\,10^{-14}$ for `nor` and
$9.3424372366343\,10^{-13}$ for `val`/lifting.  These are diagnostics only:
acceptance concerns the propagated final-functional increment, not relative
accuracy of the small signed centre.  The wall radius displayed as zero after
squaring tiny positive terms; this is floating-point underflow, not an
analytic zero.

The ordinary computed ideal modules were

| quantity | value |
|---|---:|
| $\widehat B_{\Gamma_\pm}$ | $1.8732085926745556\,10^{-10}$ |
| $\widehat B_\Upsilon$ | $9.6716125459265295\,10^{-6}$ |
| $\widehat B_{\mathrm{lift}}$ | $0.056438633545021551$ |
| $\mathcal M_{\mathrm{ideal}}$ | $0.056448305344888337$ |

The source artifact was
`test/i3/e-cap/input/fbie-a1-certificate.mat`; the independent geometry
contract was `test/i5/wall-curve-a1/input/circle-contract-a1.mat`.  The run
performed zero eigenpair, BIE-density, QZ, and propagation-matrix solves and
read no historical output.  All numerical values above remain
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.  Both `delta_sf` and `delta_fp` are still
`UNRESOLVED`, so the table is a conditional ideal diagnostic and not a
reliable residual-numerator bound.

### Supplemental call-inventory audit

The regular-image helper routes every recorded primitive through its local
oracle wrapper, so its wrapper counts and parameter extrema are actual for the
named invocation.  The cutoff-preselection invocation made no
`Faddeeva_erfc` or `expint` call.  The final governing invocation made 1152
vectorized `Faddeeva_erfc` calls over 75497472 scalar arguments and 256
vectorized `expint` calls over 16777216 scalar arguments.  It also recorded
25495 `gammaln` wrapper calls over 25905 scalar arguments.  Bessel, Hankel, and
black-box quasi-periodic Green-function calls were zero.  The exact argument
ranges remain in `result.sf_ledger.regular_final.calls`.

The local helper also calls `gammaln` directly while constructing its p4
entire-series certificates, so those calls are absent from the persisted
wrapper ledger.  With series cutoff 32, one material wavenumber uses 189
retained-plus-first-omitted J records, 188 Y records, and 155 shifted-J
records.  Each record evaluates three scalar `gammaln` terms.  Thus one local
invocation uses 1596 scalar calls per wavenumber, or 3192 for the exterior and
interior pair.  The cutoff preselection, three N candidates, and final center
make five local invocations: 15960 additional scalar calls with integer
arguments in $1{:}34$.  Including the regular preselection (497 scalar
arguments) and final regular call (25905) gives 42362 `gammaln` scalar
arguments overall and 41542 MATLAB call sites/vectorized calls overall.

The local ledger is not a complete elementary-call counter.  In particular,
`finite_exp_scalar_count` was formed as
$256N+2(2L-1)N$ even when `evaluate_centers=false`; the second term belongs to
the two target transforms and is then not executed.  The actual density-phase
exponential argument counts for the four no-center local invocations were
131584 at $(L,N)=(32,514)$, then 262656, 524288, and 1048576 at
$(L,N)=(512,1026)$, $(512,2048)$, and $(512,4096)$.  The final center invocation
at $(512,2048)$ did execute both target transforms, so its density-plus-target
phase count was 4714496.  These numbers cover those phase matrices only.

Likewise, the local `finite_sin_cos_scalar_count=3N^2` covers the three
geometry arrays in the block Kress assembly but omits the $N^2/2$ scalar
cosine evaluations inside `quad.quad_kress_rvec`.  Including that known term
gives 924686, 3684366, 14680064, and 58720256 trigonometric scalar arguments
at $N=514,1026,2048,4096$, respectively.  The field
`finite_log_scalar_count=3` records nominal argument roles, not the number of
runtime calls: derivative-tail construction and blockwise split evaluation
also call elementary functions directly.  Off-surface and wall ledgers are
similarly explicit partial inventories.  Thus the persisted
`higher_special_function_calls_complete=true` is accurate for the explicitly
instrumented Faddeeva, $E_1$, Bessel, Hankel, and black-box quasi-periodic
Green families, but must not be read as a whole-run non-elementary inventory
because the direct local `gammaln` calls were not instrumented.
`elementary_call_inventory_complete` correctly remains false.  This audit
changes no governing center, radius, tail, or result.

## Restricted phase-2 sensitivity entry point

After the independently reviewed phase-1 result opened branch 1, the separate
create-once entry point

```matlab
special_function_sensitivity_v5(artifact_path, input_path, output_path);
```

implements (I5.1f-23)--(I5.1f-37).  It enumerates the complete fixed run-02
Faddeeva and $E_1$ argument sets without calling either special function,
streams their unit absolute-error coordinate gains through density, normals,
Jacobians and retained target rows, and then applies the matched finite/cell
state factor $S_J$.  All other primitive library values are held fixed.

Its output status is `PARTIAL_FADDEEVA_E1_SENSITIVITY_ONLY` with claim scope
`PARTIAL_IDEAL_SENSITIVITY`.  It reports $A_F,A_E$ and the sufficient
per-family requirements for the initial allocations
$\tau_F=\tau_E=0.00125$.  It also reports the exact-relative corollary from
(I5.1f-37a)--(I5.1f-37b); its denominator is the exact function magnitude,
not the ordinary library return.  It does not change
$\mathcal M_{\mathrm{ideal}}$, and it leaves
`delta_sf_rest=UNRESOLVED`, `delta_sf=UNRESOLVED`, and
`delta_fp=UNRESOLVED`.  Hence even a successful restricted run is not a
complete special-function or residual-numerator certificate.

### Restricted phase-2 run-01 record

After the independent pre-run `GO`, the following equivalent command
reproduces the same create-once computation and prints its key scalars (the
canonical run log instead printed the complete result as JSON):

```text
/usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch "addpath('/Users/whc/Documents/Work/epost'); addpath('/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5'); issues=checkcode('/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/special_function_sensitivity_v5.m','-id'); disp(issues); result=special_function_sensitivity_v5('/Users/whc/Documents/Work/epost/test/i3/e-cap/input/fbie-a1-certificate.mat','/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/input/residual-numerator-v5-run-02.mat','/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/output/attempt-1/sensitivity-run-01.mat'); fprintf('AF=%.17g AE=%.17g epsF=%.17g epsE=%.17g etaF=%.17g etaE=%.17g\\n',result.A_F,result.A_E,result.required_uniform_absolute_error.Faddeeva_erfc,result.required_uniform_absolute_error.expint_E1,result.required_uniform_exact_relative_error.Faddeeva_erfc,result.required_uniform_exact_relative_error.expint_E1);"
```

Standard output and `/usr/bin/time -l` output are retained as
`output/attempt-1/sensitivity-run-01-log.txt` and
`output/attempt-1/sensitivity-run-01-resource.txt`.  MATLAB R2023b exited
successfully.  The helper itself took 3.2600221666666669 seconds; the complete
process took 18.04 seconds and reached 983793664 bytes maximum RSS, below the
45-minute and 3-GiB hard limits.  It read the explicit frozen artifact and the
self-contained phase-1 input, did not read a phase-1 result or other historical
output, and performed zero eigenpair, density, QZ, or propagation solves.

All restricted gates passed.  The matched state energy was
$S_J=2.9050958701919547$, and the resulting final-functional gains and initial
per-family error requirements were

| quantity | value |
|---|---:|
| $A_F$ | $30944383.348174293$ |
| $A_E$ | $242617.37348658184$ |
| required uniform absolute Faddeeva error | $4.0395052825434619\,10^{-11}$ |
| required uniform absolute $E_1$ error | $5.1521454627779673\,10^{-9}$ |
| required exact-relative Faddeeva error | $1.5512180321649638\,10^{-11}$ |
| required exact-relative $E_1$ error | $3.1313719876758819\,10^{-8}$ |

The allocations are $\tau_F=\tau_E=0.00125$ and
$\tau_{\mathrm{rest}}=0.0025$.  Consequently the reported partial implication
is $\mathcal M_{\mathrm{ideal}}+\tau_F+\tau_E
=0.05894830534488834$ only if the two named uniform Faddeeva/$E_1$ contracts
hold.  This does not consume or close $\tau_{\mathrm{rest}}$:
`delta_sf_rest`, `delta_sf`, and `delta_fp` all remain `UNRESOLVED`.  The run
therefore remains `PARTIAL_FADDEEVA_E1_SENSITIVITY_ONLY` with scope
`PARTIAL_IDEAL_SENSITIVITY`; it does not establish a complete reliable
residual-numerator bound.

## Narrow local log-gamma--exponential sensitivity

The separate create-once entry point

```matlab
local_certificate_sensitivity_v5(artifact_path, input_path, output_path);
```

implements only (I5.1f-47)--(I5.1f-54).  It reads the explicit frozen
artifact and self-contained phase-1 input, verifies that each stored local
radius is exactly its source-plus-target-plus-series sum and that the selected
high tail is the p2/p4 minimum, and reuses those positive certificate values.
It evaluates neither a signed center nor a true numerical operator.

For $\chi\in\{\mathrm{nor},\mathrm{val}\}$ it reports

$$
D_\chi^2
=S_J\sum_{|\ell|<L}w_\ell^\chi(r_{\ell,\mathrm{loc}}^\chi)^2
+S_\infty h_{\mathrm{loc},\chi}^2,
\qquad D_{\mathrm{loc}}=D_{\mathrm{nor}}+2D_{\mathrm{val}}.
$$

Here $S_J$ is recomputed from the exact $n<J$ states and their block-power
tail, while $S_\infty$ is independently recomputed from the frozen
$q_0,G_\pm,P_\pm,c_\pm$ data and the saved propagation caps.  The helper
checks the fixed run-02 graph, integer `gammaln` arguments $1{:}34$, positive
nonunderflowing immediate exponential returns, and the absence of sampling.

The prospective caps reserve $0.00125$ for this subchain and retain another
$0.00125$ as `delta_sf_rest2=UNRESOLVED`:

$$
g=\log\!\left(1+\frac{0.00125}{D_{\mathrm{loc}}}\right),\qquad
\varepsilon_\Gamma=\frac g8,\qquad
\eta_e=1-e^{-g/2}.
$$

These ordinary floating-point values are targets for a future uniform oracle
contract, not measured errors or outward enclosures.  A successful run must
remain `PARTIAL_LOCAL_LOGGAMMA_EXP_SENSITIVITY` with scope
`PARTIAL_IDEAL_SENSITIVITY`; `delta_sf_rest2`, `delta_sf`, and `delta_fp`
remain `UNRESOLVED`.

After independent pre-run `GO`, the create-once run used the following MATLAB
payload with standard output and `/usr/bin/time -l` output retained in
`output/attempt-1/local-certificate-sensitivity-run-01-log.txt` and
`output/attempt-1/local-certificate-sensitivity-run-01-resource.txt`:

```text
/usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch "addpath('/Users/whc/Documents/Work/epost'); addpath('/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5'); fprintf('MATLAB=%s\\n',version); issues=checkcode('/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/local_certificate_sensitivity_v5.m','-id'); disp(issues); result=local_certificate_sensitivity_v5('/Users/whc/Documents/Work/epost/test/i3/e-cap/input/fbie-a1-certificate.mat','/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/input/residual-numerator-v5-run-02.mat','/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/output/attempt-1/local-certificate-sensitivity-run-01.mat'); disp(jsonencode(result));"
```

MATLAB R2023b exited successfully.  The helper took 0.31707508333333334
seconds and reported a 108.19108772277832-MiB workspace proxy; the complete
process took 14.52 seconds and reached 779403264 bytes maximum RSS.  All gates
passed, and the ordinary partial-sensitivity values were

| quantity | value |
|---|---:|
| $S_J$ | $2.9050958701919547$ |
| $S_\infty$ | $9490.921169744874$ |
| $D_{\mathrm{val}}$ | $0.02821931665775703$ |
| $D_{\mathrm{nor}}$ | $9.671596964464973\,10^{-6}$ |
| $D_{\mathrm{loc}}$ | $0.05644830491247853$ |
| prospective $\varepsilon_\Gamma$ | $0.002737816682536592$ |
| prospective $\eta_e$ | $0.010891519908669904$ |

The ordinary recomputation gave
$c_{\Gamma e}D_{\mathrm{loc}}=0.0012499999999999983$; the exact theorem
identity is $0.00125$.  The helper also verified the complete integer argument
set $1{:}34$, 1064 positive immediate exponential returns per local
invocation, and 5320 across the five frozen phase-1 local invocations.  It
performed no center/operator re-evaluation and no eigenpair, density, QZ, or
propagation solve.  These targets do not supply either oracle contract, so the
status and unresolved terms stated above are unchanged.

## Regular gamma-composite sensitivity

The independently reviewed create-once helper

```matlab
regular_gamma_sensitivity_v5(artifact_path, input_path, output_path);
```

replays only the positive regular-certificate graph at the fixed run-02
library data.  It uses the complete source density phases, target phases and
real canonical call set to form the reviewed $P^\sharp,Q^\sharp,B_r$ and
$b_{pq}$ gains.  It then combines the induced center/radius changes with the
same $S_J,S_\infty$, stored regular radii, and regular high-mode owner.  It
does not evaluate a signed center or numerical operator.

The run used the following MATLAB payload; its JSON and resource records are
`output/attempt-1/regular-gamma-sensitivity-run-01-log.txt` and
`output/attempt-1/regular-gamma-sensitivity-run-01-resource.txt`:

```text
/usr/bin/time -l /Applications/MATLAB_R2023b.app/bin/matlab -batch "addpath('/Users/whc/Documents/Work/epost'); addpath('/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5'); fprintf('MATLAB=%s\\n',version); issues=checkcode('/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/regular_gamma_sensitivity_v5.m','-id'); disp(issues); result=regular_gamma_sensitivity_v5('/Users/whc/Documents/Work/epost/test/i3/e-cap/input/fbie-a1-certificate.mat','/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/input/residual-numerator-v5-run-02.mat','/Users/whc/Documents/Work/epost/test/i5/residual-numerator-v5/output/attempt-1/regular-gamma-sensitivity-run-01.mat'); disp(jsonencode(result));"
```

MATLAB R2023b exited successfully.  The helper took 0.699462 seconds and
reported a 108.357-MiB workspace proxy; the complete process took 14.87
seconds and reached 839712768 bytes maximum RSS.  All gates passed.  The
ordinary partial values were

| quantity | value |
|---|---:|
| $D_{\mathrm{center,val}}$ | $61441.61931393947$ |
| $D_{\mathrm{center,nor}}$ | $117.69570987302981$ |
| $D_{\mathrm{radius,val}}$ | $1.2469612186700654\,10^{-8}$ |
| $D_{\mathrm{radius,nor}}$ | $1.2441093650389572\,10^{-10}$ |
| selected common dyadic cap | $2^{-30}=9.313225746154785\,10^{-10}$ |
| propagated increment | $0.0005727677356781513$ |

The cap applies prospectively and uniformly to the four named errors
$(\varepsilon_\Gamma,\eta_i,\varepsilon_{\log},\eta_o)$; it is not a measured
oracle error.  The complete ledgers contained 4194304 real canonical
arguments in $[0,0.6400000000000003]$, 524288 source-phase arguments, and
2095104 target-phase arguments.  The final regular `gammaln` owner also
matched 25495 vectorized calls, 25905 scalar arguments, and integer arguments
$1{:}20$.  The result remains
`PARTIAL_REGULAR_GAMMA_COMPOSITE_SENSITIVITY` with scope
`PARTIAL_IDEAL_SENSITIVITY`: the four oracle contracts are unsupplied,
`delta_sf_rest3`, `delta_sf`, and `delta_fp` remain `UNRESOLVED`, and no
reliable residual-numerator certificate follows.  The helper performed zero
eigenpair, density, QZ, or propagation solve.
