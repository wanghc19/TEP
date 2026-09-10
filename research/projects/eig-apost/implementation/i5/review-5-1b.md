# I5.1b pre-run Skeptic review

## A. Audit frame

This is an independent proof-and-static-code audit of the proposed ordinary,
roundoff-excluded frozen-instance estimate

$$
\|R\|_{\mu,*}\le
\widehat B_{\Gamma_\pm}+\widehat B_\Upsilon
+\widehat B_{\mathrm{lift}}.
$$

The acceptance criterion at this stage is narrower than an instance-level
mathematical `GO`: the design and executable dependency chain must be complete,
fail closed on a missing theorem input, and be suitable for the first MATLAB
run without using sampled maxima, inter-level drift, Richardson extrapolation,
or an empirical safety factor.  Floating-point outward rounding is excluded.

The governing authority is `s-kress-real.md`, equations (KR-15)--(KR-32),
with the signs and bare splits in `+kernel/kress_mn_splits.m`,
`+kernel/kress_l_splits.m`, and
`legacy/notes/implementation/kress_scheme.md`.  I inspected
`design-5-1b.md`, `SYMBOL.md`, the versioned experiment README, the complete
builder and evaluator, the accepted wall interfaces, and the historical
unversioned evaluator only as sign/index evidence.  The local Kress product
rule was also checked against the locally archived Kress (1991) paper at
journal pages 233--235.  No numerical program was run during this review.

## B. Verdict

**`GO` for the first scientific run (medium-high confidence).**

The previous pre-run blockers have been repaired.  The builder now generates
the density-inclusive KR-15 certificate, evaluates a predetermined $L$
schedule from explicit angular tails, fixes an even $N$ only afterward,
constructs zero-center enclosures for the complete local, regular-image, and
off-surface actions, assembles material-normal and both material/artificial-wall
lifting contributions, and wires the propagated-cell tails.  Required
structural conditions feed the fail-closed preflight.  This verdict authorizes
the run; it is not a post-run verdict and does not predict that the allocated
tail or retained-row tolerances will pass.

## C. Strongest challenge

The strongest remaining failure mode is extreme looseness of the zero-center
enclosures.  In particular, the exact-Kress-to-zero contribution encloses the
whole local integral operator and normally does not decrease with $N$.
Consequently the retained-row allocation may fail even when every formula and
ratio gate is finite.  This cannot invalidate the resulting finite upper bound,
but the output must then remain
`RETAINED_RADIUS_TOLERANCE_FAILED_ORDINARY`; it must not be promoted to an
instance-level `GO` and increasing $N$ must not be advertised as a repair for
that nonshrinking term.

## D. Findings

1. **IMPORTANT CAVEAT -- pre-run `GO` is not instance-level acceptance.**
   Location: evaluator status and `theorem_gate`.  Evidence: the retained,
   material-tail, and lifting-tail tests are evaluated only after the frozen
   MAT input is built.  Consequence: a correct run may legitimately return a
   finite majorant with a failed allocation.  Cheapest decisive check: inspect
   all three Boolean outcomes and the separately persisted source, target,
   zero-center-series, Fourier, Ewald, off-surface, wall, and cell values.

2. **IMPORTANT CAVEAT -- ordinary arithmetic excludes roundoff containment.**
   Location: FFTs, Frobenius norms, factorial sums, branch margins, and every
   persisted scalar.  Evidence: there is no outward-rounded backend, and the
   code consistently labels the result `NON_CERTIFIED_ROUNDOFF_EXCLUDED` with
   `reliability_certified=false`.  Consequence: even a complete ordinary result
   is not a roundoff-inclusive certificate.  Cheapest resolution is disclosure;
   no additional computation is required for the present claim.

3. **MINOR CAVEAT -- `series_radius` has deliberately broader semantics than
   a truncation-only radius.**  Location: `LOCAL_empty_operator_rows` and
   `LOCAL_series_radius`.  Evidence: it bounds $Q_N(F)-0$ using the complete
   density-inclusive $K_1,K_2$ bounds, while the center contains only the
   identity.  Consequence: the label is conservative but can be misread.
   Cheapest check: retain `full_operator_enclosed_in_series_radius=true` and
   report the zero-center policy beside the numerical value.

No unresolved `BLOCKER` remains in the pre-run artifact.

## E. Implementation audit

- **Local signs and cancellation.**  The stored coordinate is
  $\eta=(\tau,-\sigma)^{\mathsf T}$.  The normal identity row is therefore
  `-eta_second`, i.e. $+\sigma$.  The KR-15 normal bounds keep
  $T_i-T_e=-(T_e-T_i)$, include $\tau'''$ in the Maue source derivative, and
  record cancellation of the common cotangent principal term before absolute
  values.  The diagonal-safe $W$ expression includes the required factor two.
- **Identity and telescope.**  Value and normal identities occur once in the
  retained center.  The source radius compares the exact source integral with
  the exact-kernel Kress rule, the target radius compares the continuous row
  with the DFT of those exact Kress samples, and the zero-center radius compares
  those samples with zero.  These are successive differences; the identity is
  absent from source and zero-center radii but present in the target derivative
  bound.
- **Index partition.**  Retained target rows are exactly
  $-L+1,\ldots,L-1$ and omitted rows satisfy $|\ell|\ge L$.  The builder checks
  $L\in\{32,64,128,256\}$ in increasing order, uses the last value only for a
  finite failed-tolerance report, and then sets
  $N=2\max\{L,M_\eta\}+2$.  Thus the target has no Nyquist row, while the
  single positive Nyquist representative occurs only inside the Kress alias
  constant.
- **Regular and off-surface actions.**  The regular kernel order is
  `[K00,K01-source,K10-target,K11]`; value uses $K_{01}\tau+K_{00}\eta_2$
  in absolute norm and normal uses $K_{11}\tau+K_{10}\eta_2$.  The retained
  reciprocal, nonzero-image, and branch-free local canonical parts are fully
  enclosed about zero.  Retained nonzero images use the full
  $H_{\chi_E}$ bound, so M-T is explicitly absorbed and is not added again.
  Reciprocal, omitted-image, and local-factorial tails remain separate.  The
  off-surface action uses the frozen finite Rayleigh support with outgoing,
  non-Wood, inverse-$\gamma_m$, normal-weight, and positive-distance checks.
- **Propagation and tail ownership.**  Center plus cells $0\le n<J$ are in
  retained rows.  For $n\ge J$, the material and material-lift low-angular
  tails use whole-matrix Frobenius block-power bounds.  High-angular tails use
  the all-cell state bound and are disjoint from the low-angular cell tail.
  Artificial-wall value rows follow the audited center/singleton/left/right
  convention; their retained, high-mode, and cell pieces are separate from the
  material collar.  Same-defect local/regular/off-surface norms are added before
  squaring, while disjoint wall/collar squares are added afterward.
- **Finite inputs and gates.**  Scalar consistency, circle-contract
  reproduction, CCW/outward orientation, density phase/support, factorial
  ratios, finite derivative arrays, exact retained/tail mode sets, Ewald gates,
  wall provenance, and both block contractions feed the preflight.  The circle
  $q/c$ identities instantiate the current geometry only; no circular
  Fourier/Bessel diagonalization is used to prove the governing theorem.

## F. What survived

The full chain from KR-15 through KR-32 is now executable without a sampled
maximum.  The conservative local exact-action radius is mathematically valid;
its overlap with the source radius is avoided by the explicit three-step
telescope.  Bounding the full retained nonzero-image Ewald action by the
elementary $e^{\chi_E}$ estimate is loose but valid and does not duplicate an
M-T tail because that tail is set to zero/absorbed.  The retained/omitted
Fourier boundary, the two Nyquist roles, the source/target normal distinction,
the two identity jumps, and the factor two in $B_{\mathrm{lift}}$ all survive
static scrutiny.

## G. Authorized run and mandatory post-run checks

The following existing inputs are eligible:

- frozen artifact:
  `test/i3/e-cap/input/fbie-a1-certificate.mat`;
- curve contract:
  `test/i5/wall-curve-a1/input/circle-contract-a1.mat`;
- accepted wall result:
  `test/i5/wall-curve-a1/output/attempt-1/result.mat`.

The create-once targets are
`test/i5/residual-numerator-v1/input/residual-numerator-v1.mat` and
`test/i5/residual-numerator-v1/output/residual-numerator-a1/result.mat`.
With the repository root on the MATLAB path, the authorized scientific
sequence is

```matlab
build_residual_numerator_input_v1( ...
  artifact_path, curve_contract_path, wall_result_path, input_path);
residual_numerator_v1(input_path, output_path);
```

The attempt must also run Code Analyzer and preserve its log in the same
attempt.  Before any instance claim, the post-run Skeptic must verify:

1. `gate_audit.pass`, the four zero solve counts, and all finite/nonnegative
   component arrays;
2. selected $L$, the complete cutoff table, even $N$, and
   $N>2\max\{L,M_\eta\}$;
3. every local factorial ratio, Ewald ratio, outgoing/non-Wood/clearance gate,
   and both block norms below one;
4. retained source, target, and zero-center radii separately, including their
   allocation outcome;
5. local-Fourier, regular/Ewald, off-surface, low-cell, wall high-mode, and
   wall cell tails exactly once;
6. finite values of $\widehat B_{\Gamma_\pm}$, $\widehat B_\Upsilon$,
   $\widehat B_{\mathrm{lift}}$, and their sum; and
7. measured wall time below 30 minutes planned/40 minutes hard and peak-memory
   evidence below 2 GiB.

## H. Open-problem handoff

| stage | category | blocking scope | cheapest next check | suggested ledger status |
|---|---|---|---|---|
| post-run instance audit | IMPORTANT CAVEAT | instance-level `GO` only | inspect persisted gates, radii, tails, and status | keep in `review-5-1b.md` |
| outward arithmetic | IMPORTANT CAVEAT | roundoff-inclusive certification only | retain present qualifier | no new ledger entry |

The pre-run review is complete.  The next allowed action is the single
versioned attempt under the declared 30-minute/2-GiB plan and 40-minute hard
stop, followed by an independent post-run review.

## Post-run audit 1: bounded revision required

**Verdict: `REVISE` (high confidence).**  The scientific evaluator completed
and the persisted numbers are internally consistent, but the run is not yet
acceptable under the repository execution contract.  The builder reads
`test/i5/wall-curve-a1/output/attempt-1/result.mat` and makes execution
conditional on fields in that historical output.  `test/AGENTS.md` expressly
forbids executable MATLAB from requiring a historical output.  Calling that
file an accepted wall result does not create an exception.

This is a bounded implementation-contract blocker, not a defect in the wall
theorem or a reason to discard the numerical evidence.  The smallest repair
is to remove `wall_result_path` from the executable dependency chain and pass
the already accepted wall finite and tail squares as explicit nonnegative
numeric function inputs.  A provenance label may also be passed, but it must
not authorize the calculation or be parsed as a path.  The builder must
validate and persist the two scalars, then the same `-a1` attempt must be rerun.

Subject to that blocker, the result file and `run-03-postprocess-log.txt`
survive the numerical audit:

| quantity | persisted ordinary value |
|---|---:|
| $L,N,M_\eta$ | $256,514,128$ |
| $\widehat B_{\Gamma_\pm}$ | $1.8732039079101324\times10^{-10}$ |
| $\widehat B_\Upsilon$ | $7256.776268586179$ |
| $\widehat B_{\mathrm{lift}}$ | $2296548.3364069569$ |
| total majorant | $2303805.1126755434$ |
| maximum retained-row radius | $3642.1532330519526$ |

All reported structural gates pass and all four solve counts are zero.  The
material and lifting tail allocations both fail, as does the retained-row
allocation.  This is expected to be reported rather than hidden: the material
tail square is $1.1504516472771662$ and the lifting tail square is
$1978187.5982693783$.  The lifting tail is dominated by the local value
Fourier norm $1406.4805617464724$; Ewald and off-surface tail norms are below
$4\times10^{-16}$ and $7\times10^{-18}$ respectively.  The retained failure
is likewise not a resolution issue: the local normal target and zero-center
radii are approximately $1053.9823$ and $1141.3289$.

The same-defect arithmetic is consistent with the persisted totals.  The
material angular square at the selected cutoff is
$1.1504505415837845$, to which the low-cell square
$1.1056933812664968\times10^{-6}$ is added.  The lifting angular square is
$1978187.5705706722$, to which the material low-cell square
$0.027698705637745218$ and the disjoint artificial-wall square
$4.7237321401724473\times10^{-11}$ are added.  This supports, rather than
contradicts, the declared non-overlap partition.

The corrected scientific run used 19.24 seconds and a maximum resident set of
927629312 bytes, below the 30-minute/2-GiB plan and 40-minute hard stop.  Code
Analyzer reports five builder warnings, four `AGROW` and one unused-input
warning, and zero evaluator warnings; they are performance/documentation
issues only.  An earlier MATLAB startup crash and a reporting-field typo are
preserved as `run-01`/`run-02` evidence and were repaired within the same
attempt.  They do not consume a new scientific attempt.

After the explicit-scalar wall repair, the decisive recheck is cheap: verify
that no versioned MATLAB source contains or loads the historical wall-result
path; compare the two persisted wall squares with the accepted values; rerun;
and confirm the same structural, resource, status, and decomposition checks.

### Bounded-revision static recheck

**Rerun verdict: `GO`.**  The repaired builder takes
`wall_finite_squared` and `wall_tail_squared` as explicit numeric arguments,
checks that both are finite nonnegative scalars, and persists them with
`source_kind='explicit_numeric_arguments'`.  The optional provenance text is
stored with `provenance_authorizes_value=false`.  The builder now loads only
the user-authorized frozen artifact and curve-contract inputs; neither
versioned MATLAB entry point contains or loads the historical wall-result
path.  The run-02 evidence has been preserved under descriptive noncanonical
filenames and the canonical create-once targets are free.

This repair changes only the input interface, not a scientific formula or
number.  A same-attempt rerun is authorized with wall squares
$3.5088928806097918\times10^{-20}$ and
$1.2402726533962042\times10^{-63}$.  Post-rerun acceptance requires equality
of those persisted inputs, the full gate/decomposition check already listed,
and a new resource record within the same limits.

## Post-run audit 2: final verdict

**Final verdict: `GO` for the completed roundoff-excluded finite-bound
experiment (high confidence).**  The contract-conforming `run-04` exited zero
and recreated the canonical input and result from explicit wall scalars.  No
versioned executable reads a historical output.  Its main values agree exactly
with the earlier scientific calculation, `gate_audit.pass=1`, and all four
solve counts remain zero.  There is no blocker to reporting the finite
inequality

$$
\|R\|_{\mu,*}
\le 1.8732039079101324\times10^{-10}
+7256.776268586179
+2296548.3364069569
=2303805.1126755434,
$$

under the stipulated exact-finite-input, roundoff-excluded interpretation.
This `GO` accepts a correctly executed and interpretable negative tightness
result.  It does **not** override the persisted instance status
`RETAINED_RADIUS_TOLERANCE_FAILED_ORDINARY`: the retained-row, material-tail,
and lifting-tail allocations all fail, so the instance does not pass the
preassigned stopping tolerances and the number is not a useful tight residual
estimate.

The retained/tail partition remains the same: $L=256$, $N=514$,
$M_\eta=128$, with $514>2\max\{256,128\}$.  The component squares and tail
ownership audited in post-run audit 1 therefore apply unchanged.  The output
does not use an inter-level comparison, platform, Richardson extrapolation, or
safety factor.  Its large size is driven by the proved local real-variable
bounds, principally the lifting local-Fourier tail and the local normal target
and zero-center radii, rather than by Ewald or off-surface tails.

The full `run-04` batch used 16.68 seconds and 959922176 bytes maximum resident
set, below both limits.  The evaluator itself recorded 0.504627 seconds and a
65.844640 MiB workspace proxy.  Code Analyzer again reported only four
preallocation warnings and one unused-input warning in the builder, with zero
evaluator warnings.  These do not affect the mathematical interpretation.

### Final classifications and handoff

1. **IMPORTANT CAVEAT -- all three accuracy allocations fail.**  Consequence:
   the present identity-only zero-center method is accepted as a finite upper
   bound but not as an instance-level stopping success.  The cheapest
   mathematically meaningful future repair is a nonzero, enclosed local Kress
   center with a tail-only series radius, together with a sharper proved local
   value Fourier tail; increasing $N$ alone cannot repair the dominant terms.
2. **IMPORTANT CAVEAT -- roundoff remains excluded.**  Every displayed value
   must retain `NON_CERTIFIED_ROUNDOFF_EXCLUDED`; it is not a fully certified
   enclosure.
3. **MINOR CAVEAT -- builder Code Analyzer warnings are performance-only.**
   They may be cleaned later without a new scientific method or attempt.

No unresolved `BLOCKER` remains.  The final result may be promoted only as the
ordinary, no-empirical-refinement finite majorant above and as evidence that
the current conservative enclosure fails its preset tightness gates.
