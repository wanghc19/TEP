# I3.2 empirical cap v2 review

## Researcher--Engineer design agreement

Date: 2026-08-26.

Researcher and Engineer independently audited the frozen certificate, the
full-boundary trial formulas, the project MFS chain, the available Kress
helpers, the absent rectangular/off-grid helper, the source/target density
coordinates, full-$P$ indexing, and the resource boundary. Neither role
edited implementation files or ran a formal experiment.

The renewed joint verdict is `RESEARCHER--ENGINEER AGREED` for the frozen
revision of
[[research/projects/eig-apost/implementation/i3/design-3-2d|design-3-2d]].
The agreement freezes:

- all-layer lead/material-cell evaluation, unchanged analytic-center terms,
  and recomputed first-lead singleton terms;
- MFS-only GQP evaluation with zero image-sum/Rayleigh-trial paths;
- the combined-high proxy, nonperiodic smooth-remainder tables, fold/phase,
  and the $65/129/257$ interpolation ladder;
- rectangular/off-grid Kress action, midpoint origins, jump signs, and the
  actual hypersingular difference;
- independent source and target axes with no density re-solve;
- componentwise empirical caps, one-time GQP propagation, trace-only field
  lower, full nonnormal $P_\pm$, and all false reliability flags;
- diagnostic-to-finest empirical GQP mapping on circle $512\times512$, wall
  $1024\times1024$, and the corresponding mixed cross grids, with the
  mandatory `GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL` warning;
- compact scientific modules, the 1500/1800 second gates, 2048 MiB hard
  memory gate, append-only `ecap-v2-a1`, and readable partial artifacts.

The center clause is an explicit scientific boundary. If the user requires a
new wall-layer representation of the analytic empty connector $C_0$, the
frozen certificate is insufficient and the correct result is
`CENTER_LAYER_DENSITY_NOT_IN_FROZEN_CERTIFICATE`; no new solve is authorized.

The renewed agreement follows two bounded repairs. Researcher verified that
the smooth periodic local coordinate $q$ restores the physical Bloch phase in
the wall self logarithmic coefficient without changing the frozen density or
trial. Engineer verified that the GQP return schema retains the production
$65/129/257$ tables and all five $129$ proxy-variant tables until the three
componentwise GQP diagnostics are formed, and then releases them at the
declared death point. Both roles found no remaining design blocker and neither
role edited code or ran an experiment.

## Skeptic DESIGN review

The first Skeptic review returned `DESIGN REVISE`. It required an explicit
analytic-center/recomputed-first-lead split, executable seam/tie/phase and
derivative rules, literal rectangular Kress and hypersingular-difference
contracts, mechanical GQP scales and arithmetic ledgers, typed MFS solver
counters, and enforceable module return/death/memory checkpoints. Those
findings were incorporated before the renewed Researcher--Engineer agreement
above.

A second Skeptic review returned `DESIGN REVISE` with three bounded findings:
runtime source/path authorization violated the test portability contract, the
denominator cap lacked one unique mechanical formula, and the agreement
summary conflated analytic-center and first-lead singleton terms. The repaired
design now uses normal MATLAB function resolution plus the typed MFS call
ledger, accepts an explicit certificate by schema/digest/semantic identity,
and fixes $N_h^\star$, every observed downward term, both arithmetic
allowances, and the one-sided $\epsilon_N^{\rm emp}$ formula. Researcher and
Engineer independently rechecked these repairs and again returned
`RESEARCHER--ENGINEER AGREED`.

The final Skeptic verdict is `SKEPTIC DESIGN PASS`. The review verified the
MFS-only and self-quadrature contracts, the analytic-center/first-lead split,
source-versus-target refinement, one-time GQP propagation, full-$P$ and field
lower formulas, runtime portability, module ownership, resource gates, and
partial-artifact semantics. This pass authorizes implementation only. It does
not authorize a formal run before the separate spec-to-code gate.

### Design amendment: four orthogonal wall-strip lift blocks

During implementation ownership auditing, the lifting singleton was found to
have four orthogonal wall-strip blocks: left/right center-side lifts and
left/right first-lead-side lifts. Each block has at most 4096 coordinates, so
the literal maximum is 16384 rather than the 8192 mistakenly written in the
memory table. Researcher traced all four blocks to the frozen `design-3-1f`
value-lift and first-lead association; combining them pairwise would introduce
nonphysical cross terms between disjoint cell strips. The lifting formula was
therefore left unchanged, while the memory-table and recursive return-audit
shape limits were corrected to 16384.

Skeptic returned `DESIGN AMENDMENT PASS`. The amendment changes only the
permitted retained shape. It does not change the trial, residual norm,
majorant, full-$P$ association, numerical levels, resource gates, or failure
semantics.

### Design amendment: paired full-boundary source axes and checkpoint wording

The first implementation mapping review found that a target-family action
contains both boundary-source families, while the draft source-axis wording
did not say explicitly that both source grids change together. Researcher
and Engineer identified the same minimal interpretation: at fixed finest
targets, the source axis must use the paired triples
$(N_{s,\Gamma},N_{s,W})=(512,1024),(1024,2048),(2048,4096)$. This observes
both self- and cross-source quadrature changes without adding a cap row or
changing the trial, densities, levels, thresholds, or finest action.

The same audit exposed two wording/implementation boundaries. First, the two
circle-normal GQP scale pieces are the complete exterior QP operator pieces,
including analytic free primary plus MFS remainder; `regular` had referred to
the regularized M\"uller action, not to a remainder-only kernel. The possible
within-piece cancellation remains an empirical limitation. Second, a
publication-safe partial projection must retain completed scalar/Gram
metrics, progress indices, operation ledgers, and resource rows while
deleting dense tables, factors, raw arrays, and incomplete panels.

Researcher and Engineer independently returned
`DESIGN AMENDMENT AGREED`. They verified that the clarification is mechanical,
does not change the frozen finest trial or cap incidence, and resolves the
earlier `regular` terminology conflict. Skeptic then returned
`DESIGN AMENDMENT PASS`: the paired source row is one coupled empirical axis,
the complete-QP scale does not cancel across operator pieces, and the partial
projection preserves only completed compact objects. The possible
within-axis and within-piece cancellations remain disclosed
`EMPIRICAL / UNQUALIFIED` limitations. This amendment pass does not imply a
spec-to-code pass. No formal attempt has been created.

## Researcher--Engineer implementation mapping agreement

Researcher first returned `RESEARCHER MAPPING REVISE` because completed
circle/wall axis Gram metrics existed only in local variables and would have
been lost if a later GQP panel met a resource blocker. The repaired modules
write completed axis metrics and ordinary weights immediately to
publication-safe `partial_metrics`, update that checkpoint after the aggregate
GQP Grams are formed, replace it with nonduplicated final data on success, and
reconstruct failure returns from compact partial metrics only. A deterministic
late-GQP failure injection confirms that both boundary modules retain the
completed axis metrics while returning no finest action maps or other dense
objects.

After this repair, Researcher returned `RESEARCHER MAPPING PASS` and Engineer
returned `ENGINEER IMPLEMENTATION AGREED`. Their independent final mappings
cover the frozen trial digest and zero density re-solves, paired full-boundary
source counts, MFS-only GQP gateway and `6/6/0/0` typed call ledger,
rectangular/off-grid Kress actions and jump conventions, the actual
hypersingular difference, one-time GQP-cap propagation, full nonnormal
$P_\pm$ contraction, the field-lower dependency audit, compact publication,
and all false certification flags. The returned field name
`source_axis_counts` deliberately avoids the recursive return audit's
forbidden `pair` token while retaining the three preregistered paired source
counts and their semantics.

The nonformal implementation evidence before spec-to-code review is:

- all 21 MATLAB files report zero `checkcode` issues;
- the manufactured rectangular Kress, boundary action, jump, and
  hypersingular-difference selftest passes;
- the four diagnostic full-$P$ Fourier-shell rows pass and contribute exactly
  zero additional cap;
- the mandatory MFS/Kress preflight passes with zero image-sum, Rayleigh-field,
  old-evaluator, and formal-attempt counters;
- an early hard-memory injection returns a compact GQP checkpoint with no
  incomplete dense table; and
- a deterministic late-GQP injection preserves completed circle/wall axis
  metrics and passes the recursive compact-return audit.

These are implementation checks only. No formal output directory has been
created, and the result remains pending the independent Skeptic gate.

### Frozen external numerical-identity repair

The first spec-to-code audit returned `SKEPTIC SPEC-TO-CODE REVISE`. The
certificate loader had computed a digest of the object supplied at runtime
and then checked only that this object did not mutate during that invocation.
It did not compare against an independently preregistered numerical identity,
so a different finite, same-shape certificate could have consumed the unique
formal tag.

The repaired configuration freezes the expected numerical trial digest in
MATLAB code. The certificate helper compares the whitelisted numerical object
against this value before publishing `out.data` or invoking any scientific
module. The digest serialization reads no source file, path, Git metadata,
documentation, manifest, or historical output. The entry records checks at
initial load, after GQP, after circle, after wall, immediately before dense
certificate release, after lifting, and after full-$P$; after the release
death point it verifies the already authenticated pre-release stamp.

A new negative selftest changes one finite entry of `q_center` without
changing any shape. The common expected-digest gate returns the typed blocker
`I32V2:CertificateNumericalIdentity` before any scientific-module call. The
complete nonformal regression remains passing, and all 22 MATLAB files report
zero `checkcode` issues.

Researcher returned `RESEARCHER MAPPING PASS` and Engineer returned
`ENGINEER IMPLEMENTATION AGREED` for this repair. Both verified that the
expected digest is an external numerical anchor, the staged ledger follows
the registered death contract, and no forbidden runtime provenance was added.
No formal attempt has been created.

## Skeptic spec-to-code review

The first audit returned `SKEPTIC SPEC-TO-CODE REVISE` for the missing
external numerical-identity anchor described above. After the repair and the
renewed Researcher--Engineer agreement, Skeptic returned
`SKEPTIC SPEC-TO-CODE PASS`.

The pass confirms that the certificate is compared against the
preregistered numerical identity before any scientific module, complete data
are rechecked through the pre-release death point, and the authenticated stamp
is checked after release. It also confirms that the negative same-shape
mutation test reaches the same typed gate, while the identity mechanism reads
no forbidden runtime provenance. The pass authorizes exactly one append-only
formal invocation. It does not predict numerical completion and does not
qualify any empirical cap or interval.

One nonblocking reporting caveat remains: if a released-stamp check were to
fail, the top-level `trial_unchanged` scalar could retain its earlier
pre-release value, but the failed ledger row, typed first blocker, and blocked
status would still expose the failure. This does not affect the identity gate.

## Formal result review

The unique append-only invocation `ecap-v2-a1` was run only after the final
spec-to-code pass. It produced readable `result.mat` and `report.md` artifacts
with the required label `EMPIRICAL / UNQUALIFIED`. The saved status is
`BLOCKED`, elapsed time is approximately $9.9331$ seconds, retained result
memory is approximately $0.0689$ MiB, and the maximum recorded memory proxy is
approximately $186.1442$ MiB.

The certificate and GQP modules completed. The GQP module used
$H=1.1$, proxy distance $0.2$, and production tuple
$(160,160,80,32)$, with the required MFS/`lsqminnorm`/fallback/outer ledger
$(6,6,0,0)$. The Bloch oracle passed with defect approximately
$2.03\times10^{-16}$. The interpolation oracle did not pass: its maximum
relative defect was approximately $8.55\times10^{-8}$, saved as the
nonblocking `GQP_INTERPOLATION_ORACLE_WARNING`. The global runtime counters
for image-sum calls, Rayleigh/Fourier field actions, old-evaluator calls, and
density re-solves are all zero.

The circle module then blocked before completing its first boundary action,
panel, or target row. The first saved blocker is `MATLAB:mixedClasses`, with
the underlying message that integers may only be combined with integers of
the same class or scalar doubles. Read-only post-run diagnosis reproduced the
failure in the frozen wall-density wavenumber expression: the certificate
stores $d$ as `int64`, while the expression combines a double Fourier-order
array with division by this integer. The same diagnosis also showed that
`int64(1)/4096` evaluates in integer arithmetic to zero. Thus the first real
blocker is an unnormalized frozen scalar class in the circle wall-source
action, not a Green-kernel pole, a resource limit, or a refinement warning.
The append-only attempt was not retried or overwritten.

Only the initial and after-GQP numerical-identity rows were reached, and both
match the preregistered frozen identity. Later digest rows are false because
their stages were not executed, not because a drift was observed. Wall,
lifting, full-$P$, field-lower, and cap modules were not started. Consequently
every empirical numerator-cap component, both denominator-cap fields, the
field lower, $q_{\rm emp}$, and the nominal interval are `NaN`; the width-below
$10^{-6}$ flag is false. The other saved warning is
`GQP_COARSE_TO_FINE_COMPONENT_MAPPING_EMPIRICAL`, and the only unresolved
item is `MATLAB:mixedClasses`.

All reliability, outward-residual, outward-field-lower, outward-tail,
certified-tail, projected-gap, independent-reference, reliable-interval, and
continuous-eigenvalue-existence flags remain false. This run supplies no
reliable or certified interval, no strict error upper bound, and no spectral
existence conclusion.

Skeptic returned `SKEPTIC RESULT AUDIT PASS` after a read-only comparison of
the MAT artifact, Markdown report, and this result review. The audit confirmed
the saved timing, memory, module states, warnings, unresolved item, unavailable
caps, unexecuted digest rows, and all false claim flags. It also confirmed that
the mixed-class explanation is stated as a read-only reproduction of the
circle wall-source class root cause rather than as an unavailable saved inner
stack frame. No attempt was retried or overwritten.

## `ecap-v2-a2` type-repair review

### Researcher--Engineer DESIGN AGREED

The actual frozen certificate type audit found `d`, `rho_disk`, `M`, and `K`
stored as `int64`, wall orders stored as `int16`, and several audit-only
indices stored as `uint8` or `int64`. Continuous fields, state matrices,
densities, and traces are double. Read-only MATLAB probes reproduced both the
saved mixed-class wavenumber failure and the zero integer spacing
`int64(1)/4096`.

Researcher and Engineer independently returned `DESIGN AGREED` for the
append-only type contract in Section 12 of the design. The agreed repair keeps
the raw object unchanged for the external identity gate, constructs one
canonical double computation view in the formal entry, and makes every
scientific module consume only that view through one shared stage validator.
They also agreed that the actual-certificate preflight must build production
MFS tables and execute the production-shared 128-target by streamed
4096-source circle wall action, rather than relying on a parallel formula
probe.

The agreement explicitly adopts the user's new retry authority. Only the
exact `ecap-v2-a2` directory may be replaced; `ecap-v2-a1` and all other
history remain immutable. Retry history is appended here and reported by a
static ordinal, while historical artifacts never feed back into the frozen
science.

### Skeptic DESIGN review

Pending. No implementation or formal `a2` run is authorized by the
Researcher--Engineer agreement alone.

### `ecap-v2-a2` retry ledger

| ordinal | command status | first blocker | repair/status |
|---:|---|---|---|
| 1 | preregistered, not run | none | type-repair implementation pending |

### Canonical-equivalence design repair

Skeptic first returned `SKEPTIC DESIGN REVISE` because a canonical digest
generated from the current conversion output would be self-consistent but not
externally anchored. The repaired design freezes a unique pure recursive
numeric-class conversion, requires exhaustive raw-to-canonical leaf
equivalence before raw release, and compares the result with an independently
preregistered expected canonical digest stored in MATLAB source. Module gates
accept only the resulting authenticated canonical stamp.

An independent temporary design-time oracle applied the frozen rule before
production implementation. It found 83 numeric leaves, converted 21 inherited
integer-class leaves, preserved seven logical leaves, verified exact
elementwise equivalence, and confirmed that the raw digest was unchanged. The
temporary oracle was removed after recording this non-secret aggregate
evidence; runtime code will not read it or any documentation.

Researcher--Engineer re-review and the renewed Skeptic DESIGN verdict are
pending. No MATLAB implementation or formal `a2` run has been authorized.

Researcher and Engineer subsequently returned `DESIGN AGREED`. They confirmed
that the canonical stamp must bind the verified schema and expected digest,
not merely carry a self-asserted Boolean or freely copied string. The
design-time oracle counts remain evidence only and do not replace either
runtime gate.

Skeptic then returned `SKEPTIC DESIGN PASS`. The pass confirms the pure
conversion, exhaustive leaf equivalence, independently preregistered expected
canonical digest, authenticated module stamp, and both negative-test
requirements. It authorizes implementation only; spec-to-code review remains
mandatory before any formal `a2` invocation.

### Released-view identity repair

During implementation, Researcher returned `DESIGN REVISE` because the first
post-wall release helper generated a digest from its own compact object and
stored that value in the same mutable authentication struct. That construction
could detect accidental drift but could not provide an external identity
anchor. The same inspection also caught an interface mismatch between the
released field set and a validator that still expected the pre-release wall
order.

The accepted repair freezes a single post-wall projection containing only the
state, geometry, lift parameters, center jumps, and ordinary field-lower
anchors actually consumed by lifting/full-$P$. The full-view validator owns
the $M=48$ gate before release; the compact view no longer carries $M$ because
it is not used after the density death point. Two independent design-time
literals will anchor the compact numerical object and a manifest that binds
the parent full digest, both view schemas, exact projection field lists, and
the death point. Runtime-generated source stamps remain audit information and
are not identity authority.

No scientific formula, density, level, threshold, resource gate, or claim
flag changed. Engineer accepted the revision. Renewed Researcher agreement and
Skeptic DESIGN PASS for this repaired release contract remain required before
implementation can be accepted; formal `a2` remains uncreated.

Researcher subsequently returned `RESEARCHER--ENGINEER DESIGN AGREED` after a
read-only code mapping review. The three independent literals, exact ordered
projection, live child and manifest recomputation, parent binding, stage
mutual exclusion, and density death point all match Section 12.5. Source
stamps are audit-only, and no formal bypass exists. Skeptic DESIGN review and
the later spec-to-code review remain the only authorization gates before the
formal run.

Skeptic then returned `SKEPTIC DESIGN PASS`. The independent released and
manifest literals close the post-wall identity boundary; the live child,
parent lineage, exact projection, stage exclusion, and density-death checks
are sufficient. No additional design test was requested. This pass does not
replace the required spec-to-code review.

### Type-repair implementation agreement and preflight

Researcher returned `RESEARCHER IMPLEMENTATION AGREED` and Engineer returned
`ENGINEER IMPLEMENTATION AGREED` after read-only mapping of the thin entry,
all five modules, the full/released identity validators, and the actual-data
preflight. The formal ownership sequence is raw identity, authenticated full
double view, GQP/circle/wall, independently anchored released view, then
lifting/full-$P$. The raw object and full density view die at their registered
points; no module receives an inherited integer certificate.

MATLAB `checkcode` reported zero messages over all 30 files in
`test/i3/e-cap-v2`. The single combined actual-certificate preflight passed in
approximately 13.4867 seconds. It constructed the production MFS GQP object,
used 128 actual circle targets and the unchanged 4096-source wall action with
256-column source panels, evaluated an actual rectangular Kress and
$T_{\rm out}-T_{\rm in}$ panel, formed registered lift weights and actual
$P_\pm c_\pm$ products, and entered the wall, lifting, and full-$P$ type gates.
It verified positive finite double spacings, zero density re-solves, unchanged
raw identity, the released identity chain, and in-memory mutation blockers.
It did not create or alter a formal attempt.

No additional manufactured migration or expanded exception framework was
added. Skeptic spec-to-code review is now the sole remaining gate before the
formal `ecap-v2-a2` command.

Skeptic returned `SKEPTIC SPEC-TO-CODE PASS`. The audit found no decisive
mapping blocker in the raw/full/released ownership chain, module entry gates,
independent identity literals, compact publication, frozen science, resource
gates, or all-false claim flags. The pass authorizes the formal
`ecap-v2-a2` invocation and does not predict numerical completion.

### `ecap-v2-a2` formal result

The authorized command ran once with retry ordinal 1 and no prior `a2`
retry. It did not replace an existing directory. Both `result.mat` and
`report.md` are readable. The saved status is `COMPLETE`, elapsed time is
approximately 681.9434 seconds, retained result memory is approximately
53.0241 MiB, and the maximum internal memory proxy is approximately
1266.3166 MiB. The first execution blocker is empty.

The raw identity, canonical identity at every completed stage, released
identity, and release manifest all match their independent literals. Raw
`d` is `int64`, canonical `d` is `double`, and the formal numerical path used
`d=1.0`. Density re-solves, old-evaluator calls, image-sum calls, and
Rayleigh/Fourier field actions are all zero. The production MFS ledger is
`6/6/0/0`; the Bloch oracle passes, while the interpolation oracle defect of
approximately $8.5512\times10^{-8}$ remains a nonblocking warning.

The empirical numerator rows are:

- wall: target $1.2379093\times10^{-11}$, source
  $1.2328374\times10^{-11}$, weight/Gauss $0$, full-$P$
  $5.4961796\times10^{-14}$, GQP $0.031432908503887$, arithmetic
  $5.4961796\times10^{-14}$, Fourier ledger $0$, total
  $0.031432908528704$;
- circle: target $5.1489682\times10^{-12}$, source and Riccati unresolved,
  full-$P$ $4.1064858\times10^{-14}$, GQP $0.014007932248595$,
  arithmetic $4.1064858\times10^{-14}$, Fourier ledger $0$, total
  unresolved; and
- volume: target, source, and Gauss rows unresolved, full-$P$
  $2.6868708\times10^{-10}$, GQP $13.470400707702249$, arithmetic
  $2.6868708\times10^{-10}$, Fourier ledger $0$, total unresolved.

Thus the aggregated empirical GQP component is $13.515841548454731$, while
the total empirical numerator cap is unresolved. The ordinary majorant center
is $5.6784915634\times10^{-6}$. The field-lower value is
$4.9591118106757941$ and the empirical denominator cap is
$1.0320473565707022\times10^{-5}$, with zero GQP denominator component.
Because the numerator cap is unresolved, $q_{\rm emp}$, both nominal interval
endpoints, and the width are `NaN`; the width-below-$10^{-6}$ flag is false.

The saved warnings are the empirical GQP mapping label, the GQP interpolation
oracle warning, unresolved Gauss lifting, unresolved wall and both volume
Fourier-shell diagnostics, unresolved circle and volume caps, and unresolved
$q_{\rm emp}$. The saved unresolved list contains the latter seven scientific
items. There is no true execution blocker; the first scientific nonclosure is
`LIFT_GAUSS_REFINEMENT_UNRESOLVED`, which is a fail-open diagnostic rather than
a blocker.

All reliability, outward residual/field/tail, certified tail, projected gap,
independent reference, reliable interval, and spectral-existence flags remain
false. The result is `EMPIRICAL / UNQUALIFIED`: it is not a reliable or
certified interval, a strict error upper bound, or a spectral-existence
conclusion.

### `ecap-v2-a2` retry-ledger continuation

| ordinal | command status | first blocker | repair/status |
|---:|---|---|---|
| 1 | complete, no retry | none | readable empirical artifact; circle/volume caps unresolved |
