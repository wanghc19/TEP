# I5.1h two-band p4 fallback

This experiment instantiates the established fallback
(ME-P4.17)--(ME-P4.22) from
`s-lift-tail.md`.  It rebuilds all data from the explicit frozen I3
artifact and circle contract; it reads no v1--v6 input or output and performs
no eigenvalue, BIE, QZ, or propagation solve.

## Governing split

The core cutoff is fixed at $L_0=256$.  The first analytic
$L_1\in\{512,1024\}$ satisfying the far-tail budget is frozen.  With this
$L_1$, the first strict $N\in\{4096,8192\}$ satisfying
$N>2\max\{L_1,M_\eta\}$ and the middle-band radius budget is frozen.
Candidate centers are never evaluated.  The final signed center is evaluated
once after selection.

The material lifting square is the sum of four disjoint owners:

1. core finite rows, $|\ell|<L_0$;
2. the core block-power cell tail;
3. the signed recapture band, $L_0\le|\ell|<L_1$, with one whole-state
   envelope;
4. the p4 component triangle on $|\ell|\ge L_1$, with one whole-state
   envelope.

There is no band cell term, and the old material value tail beginning at
$L_0$ is not added.  Material normal and paired-wall modules retain the v6
formulas.

## Five-edge radius ledger

| field | sole owner |
|---|---|
| `source` | `local.radius.val.source` |
| `target` | local, regular, and off-surface target radii, added once |
| `series` | `local.radius.val.series` |
| `Ewald` | regular source plus M-R/M-I/M-T/M-L |
| `off_analytic` | zero only when `source_quadrature_used=false` |

Finite special-function evaluation and floating-point errors remain
`UNRESOLVED`; all results are conditional ideal diagnostics marked
`NON_CERTIFIED_ROUNDOFF_EXCLUDED`.

## Planned attempt 1

- Planned wall time: at most 30 minutes.
- Planned peak memory: at most 2 GiB.
- Hard stops: 45 minutes and 3 GiB.
- Outputs are create-once under `output/attempt-1/`.

After independent pre-run approval, the exact launch form is:

```text
zsh run_residual_numerator_v7_attempt1.sh REPO EXP ARTIFACT CURVE INPUT RESULT LOG RESOURCE AUDIT
```

The nine arguments are explicit absolute paths.  The runner checks MATLAB
sources, builds one self-contained input, evaluates one selected center, and
writes only the requested attempt-1 targets.

## Canonical attempt-1 result

After the independent pre-run `GO`, canonical run 01 used:

```text
zsh /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/run_residual_numerator_v7_attempt1.sh \
  /Users/whc/Documents/Work/epost \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7 \
  /Users/whc/Documents/Work/epost/test/i3/e-cap/input/fbie-a1-certificate.mat \
  /Users/whc/Documents/Work/epost/test/i5/wall-curve-a1/input/circle-contract-a1.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-1/input-run-01.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-1/result-run-01.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-1/run-01-log.txt \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-1/resource-run-01.txt \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-1/audit-run-01.txt
```

Both $L_1$ candidates were analytically admissible.  Their propagated far
norms were $6.8805380479899163\mathbin{\cdot}10^{-5}$ and
$8.5549626823059993\mathbin{\cdot}10^{-6}$, so the selector froze the
first budget-passing value $L_1=512$.  At this cutoff, both $N$ candidates
were analytically admissible: the band-radius contributions were
$1.6676740323102459\mathbin{\cdot}10^{-4}$ for $N=4096$ and
$1.1371908078258733\mathbin{\cdot}10^{-5}$ for $N=8192$.  Only the
second met the preregistered retained-radius budget, hence the final pair was
$(L_0,L_1,N)=(256,512,8192)$.  No candidate center was evaluated.

The conditional ideal module values are:

| quantity | value |
|---|---:|
| $\widehat B_{\Gamma_\pm}$ | $1.8732052703226799\mathbin{\cdot}10^{-10}$ |
| $\widehat B_\Upsilon$ | $9.5955972563422753\mathbin{\cdot}10^{-6}$ |
| $\widehat B_{\mathrm{lift}}$ | $6.9738911755431085\mathbin{\cdot}10^{-5}$ |
| $\mathcal M_{\mathrm{ideal}}$ | $7.9334696332300397\mathbin{\cdot}10^{-5}$ |

The material squared decomposition is:

| owner | squared value |
|---|---:|
| retained normal, $|\ell|<L_1$ | $3.2141087539620648\mathbin{\cdot}10^{-17}$ |
| core retained value, $|\ell|<L_0$ | $1.3169091615375451\mathbin{\cdot}10^{-14}$ |
| normal block-power cell tail | $6.7517066305076514\mathbin{\cdot}10^{-31}$ |
| core value block-power cell tail | $2.7664543679042261\mathbin{\cdot}10^{-28}$ |
| normal high tail, $|\ell|\ge L_1$ | $9.2075454564835880\mathbin{\cdot}10^{-11}$ |
| signed middle band | $1.2932226075649907\mathbin{\cdot}10^{-10}$ |
| far p4 tail | $4.7341803829836888\mathbin{\cdot}10^{-9}$ |
| complete material value high owner | $4.8635026437401875\mathbin{\cdot}10^{-9}$ |

The whole-state factor is
$S_{\mathrm{state}}=9490.9211697448736$.  The band-radius square is
$1.2932029334036624\mathbin{\cdot}10^{-10}$, the final far row norm is
$7.0626586671994589\mathbin{\cdot}10^{-7}$, and the core/band masks
contain 511 and 512 retained modes.  The band cell owner is exactly absent.
The maximum five-edge row radii were
$1.4889299517518105\mathbin{\cdot}10^{-10}$ (source),
$4.6274551161217038\mathbin{\cdot}10^{-14}$ (target),
$3.6689666973604618\mathbin{\cdot}10^{-60}$ (series),
$1.6068545365344641\mathbin{\cdot}10^{-12}$ (Ewald), and zero for the
authorized off-surface analytic edge; their maximum total was
$1.5054612426287673\mathbin{\cdot}10^{-10}$.

The wall normal finite, propagation, high, and total squares were
$3.5088979847646642\mathbin{\cdot}10^{-20}$,
$1.7919748144268924\mathbin{\cdot}10^{-46}$,
$6.8807254583165772\mathbin{\cdot}10^{-308}$, and
$3.5088979847646642\mathbin{\cdot}10^{-20}$.  The corresponding lifting
squares were $1.0921538896743705\mathbin{\cdot}10^{-29}$,
$4.9949932705007924\mathbin{\cdot}10^{-47}$, floating-point zero, and
$1.0921538896743705\mathbin{\cdot}10^{-29}$.  The zero is an ordinary
floating-point underflow, not an analytic assertion.

The material value/normal and wall value/normal cancellation ratios were,
respectively, $1.8054808700693492\mathbin{\cdot}10^{-14}$,
$9.5796553804640902\mathbin{\cdot}10^{-14}$,
$1.2938462142842348\mathbin{\cdot}10^{-16}$, and
$3.9101924364050703\mathbin{\cdot}10^{-11}$.  These are diagnostics and
do not shrink any radius.

All 49 required-true evaluator gates, all four required-false gates, the
selection contract, finite/nonnegative assembly, and zero-solve audit passed.
The input contains 49 true gates and the four intentionally false
`sampled_maximum_used`, `inter_level_drift_used`, `Richardson_used`,
and `empirical_safety_factor_used` fields.  The route-upgrade gate is false.
The full-p6 branch remains blocked.

MATLAB R2023b completed run 01 with exit status zero.  The builder took
165.06537108333333 s and the evaluator 0.12176208333333334 s.  The complete
run took 181.78 s; `/usr/bin/time -l` recorded 1,508,376,576 bytes maximum
RSS, while the watchdog recorded 1,567,968 KiB over 183 s.  This is within
the 30-minute/2-GiB plan and 45-minute/3-GiB hard limits.  There was no
canonical operational failure or repair run.

The persisted result status is
`CONDITIONAL_TWO_BAND_P4_MAJORANT_SF_FP_UNRESOLVED`.
`delta_sf` and `delta_fp` remain `UNRESOLVED`; the total-reliable gate
is false.  Run 01 therefore remains a
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` conditional ideal diagnostic.

For comparison, v6 attempt 1 reported
$B_{\mathrm{lift}}=3.3621248621896728\mathbin{\cdot}10^{-2}$ and
$\mathcal M_{\mathrm{ideal}}=3.3776900505194128\mathbin{\cdot}10^{-2}$;
v6 attempt 2 reported $5.5685129828202118\mathbin{\cdot}10^{-4}$ and
$7.1156194372467858\mathbin{\cdot}10^{-4}$.  The v7 values reduce
$B_{\mathrm{lift}}$ by $99.7925748905411\%$ and $87.4762055919440\%$
relative to those two runs, and reduce $\mathcal M_{\mathrm{ideal}}$ by
$99.7651214435140\%$ and $88.8506268453563\%$.  These comparisons concern
conditional ideal values only.

The post-run scalar extraction loaded only the two persisted v7 MAT files,
did not invoke a builder or evaluator, and changed no artifact.  Its first
sandboxed launch failed before loading because MATLAB could not create its
crash-report file; the approved read-only retry took 7.95 s with
776,421,376 bytes maximum RSS.

## Planned attempt 2

Attempt 2 keeps the I5.1h `two-band-p4-fallback` theorem, the preregistered
$L_1\in\{512,1024\}$ and $N\in\{4096,8192\}$ schedules, and the same
selector/fallback semantics.  It changes only the two analytic allocations to

$$
\tau_{\mathrm{high}}=\tau_{\mathrm{ret}}
=\frac{6.9738911755431085\mathbin{\cdot}10^{-5}}{4}
=1.7434727938857771\mathbin{\cdot}10^{-5}.
$$

The far-only selector must therefore freeze $L_1=1024$; this is an explicit
fail-closed instance gate.  With $L_1$ fixed, the strict even-$N$ selector
continues to use only the middle-band analytic radius.  If neither admissible
$N$ meets the new allocation, it freezes the largest analytically valid
candidate, reports the finite conditional majorant, and sets the method-upgrade
route.  No center drift is used.  The post-selection
`far_lifting_square_fraction` is also diagnostic only; a value at least one
half sets `next_method_required` without feeding back into either selector.

Attempt-2 create-once artifacts will be supplied as nine explicit absolute
arguments to the existing runner and stored only under `output/attempt-2/`.
The plan remains at most 30 minutes and 2 GiB, with hard stops at 45 minutes
and 3 GiB.

## Canonical attempt-2 result

Canonical run 01 used the reviewed nine-argument runner with the same explicit
frozen artifact and curve contract as attempt 1, and with all generated files
under `output/attempt-2/`:

```text
zsh /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/run_residual_numerator_v7_attempt1.sh \
  /Users/whc/Documents/Work/epost \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7 \
  /Users/whc/Documents/Work/epost/test/i3/e-cap/input/fbie-a1-certificate.mat \
  /Users/whc/Documents/Work/epost/test/i5/wall-curve-a1/input/circle-contract-a1.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-2/input-run-01.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-2/result-run-01.mat \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-2/run-01-log.txt \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-2/resource-run-01.txt \
  /Users/whc/Documents/Work/epost/test/i5/residual-numerator-v7/output/attempt-2/audit-run-01.txt
```

The far-only candidates remained
$[6.8805380479899163\mathbin{\cdot}10^{-5},
8.5549626823059993\mathbin{\cdot}10^{-6}]$.  Both analytic gates passed,
and the tightened allocation selected $L_1=1024$ as required by the
attempt-2 assertion.  At fixed $L_1$, the strict $N$ candidates had
middle-band radius contributions
$[3.7303224274521529\mathbin{\cdot}10^{-4},
2.5435393003395238\mathbin{\cdot}10^{-5}]$.  Both were analytically valid,
but neither met $\tau_{\mathrm{ret}}$; the documented fallback therefore
froze $N=8192$, evaluated one center, and preserved a false tightness gate.

The conditional ideal modules were

$$
(B_{\Gamma_\pm},B_\Upsilon,B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})
=(1.8732052703226799\times10^{-10},
5.9744219320296460\times10^{-7},
2.6836233016607903\times10^{-5},
2.7433862530337900\times10^{-5}).
$$

The material squared decomposition was:

| owner | squared value |
|---|---:|
| retained normal, $|\ell|<L_1$ | $3.4120166769828190\times10^{-17}$ |
| core retained value, $|\ell|<L_0$ | $1.3169091615375451\times10^{-14}$ |
| normal block-power cell tail | $7.1674559499430504\times10^{-31}$ |
| core value block-power cell tail | $2.7664543679042261\times10^{-28}$ |
| normal high tail, $|\ell|\ge L_1$ | $3.5690305405239873\times10^{-13}$ |
| signed middle band | $6.4698284693441235\times10^{-10}$ |
| far p4 tail | $7.3187386495648263\times10^{-11}$ |
| complete material value high owner | $7.2017023343006064\times10^{-10}$ |

Here $S_{\mathrm{state}}=9490.9211697448736$, the stored band-radius square
is $6.4695921723716748\times10^{-10}$, the far row norm is
$8.7814035638401509\times10^{-8}$, and the core/band masks contain 511 and
1536 modes.  The band cell owner is exactly absent.  The five edge maxima
are $1.4889299517518105\times10^{-10}$ (source),
$5.1526930540456002\times10^{-14}$ (target),
$3.6689666973604618\times10^{-60}$ (series),
$1.6068545365344641\times10^{-12}$ (Ewald), and zero for the authorized
off-surface analytic edge; the maximum combined row radius is
$1.5055137664225597\times10^{-10}$.

The wall normal finite, propagation, high, and total squares were
$3.5088979847646642\times10^{-20}$,
$1.7919748144268924\times10^{-46}$,
$6.8807254583165772\times10^{-308}$, and
$3.5088979847646642\times10^{-20}$.  Wall lifting gave
$1.0921538896743705\times10^{-29}$,
$4.9949932705007924\times10^{-47}$, floating-point zero, and
$1.0921538896743705\times10^{-29}$, respectively.  The zero is ordinary
floating-point underflow, not an analytic zero.

The retained material value and normal cancellation-ratio ranges were
$[7.8848303787095844\times10^{-15},0.93826703944399159]$ and
$[1.0927565551457388\times10^{-14},0.96750122420448814]$; wall normal and
value ratios were $3.9101924364050703\times10^{-11}$ and
$1.2938462142842348\times10^{-16}$.  These remain diagnostics only.

All 54 required-true and four required-false evaluator gates passed, as did
schema, exact attempt-2 provenance, strict index, selection-contract,
finite/nonnegative, and zero-solve checks.  The far-tail, regular/wall, and
cell allocations passed; only the retained-band allocation failed.  The
post-selection far lifting-square fraction was
$0.10162326185161630<0.5$.  Thus `next_method_required=true` solely because
the radius-only $N$ selector used its analytic fallback; neither the final
center nor the far-fraction diagnostic fed back into selection.

The builder and evaluator took 165.93983816666668 s and
0.18981666666666666 s.  Complete wall time was 183.19 s with
1,958,985,728 bytes maximum RSS; the watchdog observed 185 s and
1,740,992 KiB.  The run met the planned and hard resource budgets.  It made
zero eigenpair, BIE-density, QZ, and propagation solves.

The persisted status is
`CONDITIONAL_TWO_BAND_P4_MAJORANT_SF_FP_UNRESOLVED`.
Both evaluation-error terms remain `UNRESOLVED`, and the reliable and
outward-rounding gates remain false.  The result is therefore a
`NON_CERTIFIED_ROUNDOFF_EXCLUDED` conditional ideal diagnostic.

For scale comparison:

| run | $B_{\mathrm{lift}}$ | $\mathcal M_{\mathrm{ideal}}$ |
|---|---:|---:|
| v6 attempt 1 | $3.3621248621896728\times10^{-2}$ | $3.3776900505194128\times10^{-2}$ |
| v6 attempt 2 | $5.5685129828202118\times10^{-4}$ | $7.1156194372467858\times10^{-4}$ |
| v7 attempt 1 | $6.9738911755431085\times10^{-5}$ | $7.9334696332300397\times10^{-5}$ |
| v7 attempt 2 | $2.6836233016607903\times10^{-5}$ | $2.7433862530337900\times10^{-5}$ |

One post-run extraction loaded only the persisted input/result and printed
scalars; it did not invoke the builder/evaluator or modify an artifact.  Its
first sandboxed launch failed before loading because MATLAB could not create a
crash report.  The approved read-only retry took 12.27 s with 812,957,696
bytes maximum RSS.

## Planned attempt 3

Attempt 3 keeps $L_1=1024$ and the attempt-2 allocations, and tests the
strict radius-only schedule $N\in\{8192,16384\}$.  It changes only memory
organization: regular-image target rows are transformed in blocks; off-surface
source Rayleigh modes and target rows are both streamed; and the shared block
size is 16.  The fail-closed instance assertion requires $N=16384$ after the
unchanged selector/fallback rule.  The planned peak is at most 2.5 GiB and the
planned wall time at most 30 minutes, with the unchanged 3-GiB/45-minute hard
stops.

## Canonical attempt-3 result

Canonical run 01 used the same reviewed nine-argument runner with all generated
targets under `output/attempt-3/`.  The explicit authoritative inputs remained
the I3 frozen certificate and accepted circle contract used by attempts 1--2;
no historical experiment output was read.

Both far candidates remained analytically valid, and their contributions were
$[6.8805380479899163\times10^{-5},8.5549626823059993\times10^{-6}]$.
The far-only selector therefore froze $L_1=1024$.  At this fixed cutoff, the
strict radius-only $N\in\{8192,16384\}$ candidates were
$[2.5435393003395238\times10^{-5},1.9609816903680077\times10^{-6}]$.
Both analytic gates passed and the second candidate met the tightened
allocation, giving $(L_0,L_1,N)=(256,1024,16384)$.  No candidate center was
evaluated.

The conditional ideal modules were

$$
(B_{\Gamma_\pm},B_\Upsilon,B_{\mathrm{lift}},\mathcal M_{\mathrm{ideal}})
=(1.8732040521480924\times10^{-10},
5.9741385647183627\times10^{-7},
8.7769248875529515\times10^{-6},
9.3745260644300025\times10^{-6}).
$$

The material squared decomposition was:

| owner | squared value |
|---|---:|
| retained normal, $|\ell|<L_1$ | $2.6185215306824859\times10^{-19}$ |
| core retained value, $|\ell|<L_0$ | $7.8280676297689059\times10^{-17}$ |
| normal block-power cell tail | $5.4986154468560517\times10^{-33}$ |
| core value block-power cell tail | $1.6444125623459840\times10^{-30}$ |
| normal high tail, $|\ell|\ge L_1$ | $3.5690305405239873\times10^{-13}$ |
| signed middle band | $3.8469457054218476\times10^{-12}$ |
| far p4 tail | $7.3187386495648263\times10^{-11}$ |
| complete material value high owner | $7.7034332201070105\times10^{-11}$ |

The state factor was $9490.9211697448736$, the band-radius square was
$3.8454491899585693\times10^{-12}$, and the far row norm was
$8.7814035638401509\times10^{-8}$.  The 511 core and 1536 band modes exhaust
the retained value split, and the band-cell owner remained exactly absent.
The five edge maxima were $9.9970429796913347\times10^{-12}$ (source),
$2.8923645969746982\times10^{-15}$ (target),
$3.6689666946896284\times10^{-60}$ (series),
$1.6068545365344641\times10^{-12}$ (Ewald), and zero for the authorized
off-surface analytic edge.  Their maximum total was
$1.1606789880822773\times10^{-11}$.

Wall normal finite, propagation, high, and total squares were
$3.5088934209840330\times10^{-20}$,
$1.7796094859778989\times10^{-46}$,
$6.8807254583165772\times10^{-308}$, and
$3.5088934209840330\times10^{-20}$.  Wall lifting gave
$5.9767862107677079\times10^{-30}$,
$3.0231854444972179\times10^{-47}$, floating-point zero, and
$5.9767862107677079\times10^{-30}$.  The zero is ordinary underflow.  Small
changes from attempt 2 are caused by the permitted floating-point summation
reordering in the streamed implementation and remain inside the unresolved
$\Delta_{\mathrm{fp}}$ scope.

The material value and normal cancellation-ratio ranges were
$[6.7351253326055290\times10^{-15},0.96727233161608794]$ and
$[1.0914470670524350\times10^{-14},0.97373383444984729]$; the wall normal
and value ratios were $3.9101898935459753\times10^{-11}$ and
$9.5713809463184552\times10^{-17}$.  They are diagnostics only.

All 55 required-true and four required-false evaluator gates passed, together
with schema, provenance, strict index, selection, finite/nonnegative,
streaming, and zero-solve checks.  Both selector allocations passed, so
`route_upgrade_required=false`.  The post-selection far lifting-square
fraction was $0.95006096675446483$; consequently
`next_method_required=true` solely through the independent one-half
far-dominance gate.  This post-selection decision did not feed back into
$L_1$, $N$, or the majorant.

The builder/evaluator times were 601.30727670833335 s and
0.19272141666666667 s.  Complete wall time was 618.57 s, maximum RSS was
1,503,281,152 bytes, and the watchdog observed 619 s and 1,501,632 KiB.
Despite doubling $N$, streaming reduced `/usr/bin/time` maximum RSS by
455,704,576 bytes (about 23.3 percent) relative to attempt 2; the watchdog
peak fell by 239,360 KiB.  The longer run still met the 30-minute/2.5-GiB
plan and 45-minute/3-GiB hard limits.  All solve counts were zero.

The status remains
`CONDITIONAL_TWO_BAND_P4_MAJORANT_SF_FP_UNRESOLVED`; special-function and
floating-point errors, reliable evaluation, total reliability, and outward
rounding remain unresolved or false.

Updated scale comparison:

| run | $B_{\mathrm{lift}}$ | $\mathcal M_{\mathrm{ideal}}$ |
|---|---:|---:|
| v6 attempt 1 | $3.3621248621896728\times10^{-2}$ | $3.3776900505194128\times10^{-2}$ |
| v6 attempt 2 | $5.5685129828202118\times10^{-4}$ | $7.1156194372467858\times10^{-4}$ |
| v7 attempt 1 | $6.9738911755431085\times10^{-5}$ | $7.9334696332300397\times10^{-5}$ |
| v7 attempt 2 | $2.6836233016607903\times10^{-5}$ | $2.7433862530337900\times10^{-5}$ |
| v7 attempt 3 | $8.7769248875529515\times10^{-6}$ | $9.3745260644300025\times10^{-6}$ |

The post-run extraction loaded only the two persisted MAT files and printed
scalars.  It invoked no builder/evaluator and modified no artifact; it took
8.49 s with 809,172,992 bytes maximum RSS.
