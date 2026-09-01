# I4.1b quadratic fitted-FEM experiment

This directory contains the reviewed I4.1b method frozen in
[[research/projects/eig-apost/implementation/i4/design-4-1b|design-4-1b]]
and finally assessed in
[[research/projects/eig-apost/implementation/i4/review-4-1b#AE. Final post-run review of run-002/execution-002|review §AE]].

Status: **FORMAL COMPLETE / EMPIRICAL P2 REFERENCE CANDIDATE / POST-RUN
PASS WITH CONDITIONS**. Create-once `run-002/execution-002` completed and is
consumed; it must not be rerun. All earlier preflight/formal executions remain
immutable historical evidence.

## Final reviewed authority

The eight canonical leaves are `preliminary-result.mat`,
`preliminary-fields.mat`, `refinement-result.mat`, `refinement-fields.mat`,
`run.log`, `resource.tsv`, summary-last `run-summary.csv`, and
`work/terminal.tsv`. The formal run completed $61/61$ planned solves; all five anchor
spectra used `roots-48` authority and no conditional 60-root extension was triggered. It returned

$$
\lambda_{\mathrm{pre}}=3.3672400220423246,
\qquad
k_{\mathrm{pre}}=1.8350040931949783.
$$

The selected simple root-9 field track is object IDs
`[8,32,55,78,101]`; its four adjacent common-grid overlaps are at least
$0.99999991258811038$, selected residuals are at most
$1.1334890039602699\times10^{-16}$, localization is available at all twists,
and endpoint parity is empirically even. The five observed components are

$$
(\delta_h,\delta_g,\delta_N,\delta_\vartheta,\delta_{\mathrm{tol}})
=(7.2025200175129811\times10^{-5},
2.7115316763854924\times10^{-3},
3.1239311426567440\times10^{-7},0,0),
$$

with

$$
\Delta_{\mathrm{ref}}^{\mathrm{obs}}
=0.0027838692696748879.
$$

Whole-command wall was $232.450046$ s and aggregate peak RSS was
$1055391744$ B. Review §AE gives `PASS WITH CONDITIONS`: this is a
field-bearing, non-certified empirical P2 reference candidate with complete
frozen resolution axes. The geometry component dominates; the sampled bulk
diagnostic, field localization and parity do not certify a continuous gap,
guided-mode existence or reference-error upper bound. No estimator effectivity
comparison was performed or authorized.

Design §31 and review §X govern the consumed
`resource-preflight-002/execution-003`; design §36 and review §§AC--AE govern
the consumed formal continuation. Earlier executions remain immutable and
unread.

- `run_preflight_002.pl` performs four actual P2 mesh/phase reductions and
  SPD factorizations, records the factor `nnz`, clears each factor immediately,
  and returns before every `eig`, `eigs`, or `svd` path.
- Each mesh retains its untouched constrained-Delaunay connectivity, with only
  positive orientation and deterministic row ordering. The full conforming,
  fitted, periodic, assembly, Hermitian and SPD acceptance chain remains hard.
- Mesh-node reflection is not required. Endpoint parity is the empirical
  weighted compression of actual complex P2 samples on the paired common grid;
  pairing, normalization or compression failure is an unavailable caveat and
  does not remove a valid field object.
- Formal assignment refinement first rejects only suffixes whose all-finite
  tuple graph has no deterministic perfect matching; every feasible suffix
  still uses the unchanged tuple-valued Hungarian optimizer.
- `run_formal_002.pl` computed five anchor slices and atomically published
  immutable preliminary result/field MAT files. Only then did it attempt the
  fixed 61-call refinement/bulk schedule, with five conditional 60-root anchor
  calls for a maximum of 66.
- Each conditional 60-root slice is checked cluster-by-cluster against its
  immutable 48-root spectrum using ordered boundaries, multiplicities,
  frequency defects, and exact-mass principal subspace overlaps. The
  preliminary result publishes both compact evidences and an explicit
  per-slice `roots-48`/`roots-60` authority and coverage table; only the active
  authority supplies objects and fields.
- Both fixed no-argument controllers use only the inclusive epoch deadline
  `1788266751` and aggregate MATLAB-process-tree RSS limit 3,221,225,472 B.
- The active core reads no historical output, Markdown, Git, BIE/QZ, density,
  estimator, or reference artifact. Its result remains empirical,
  non-certified, and cannot establish effectivity or continuous existence.

The exact historical commands were:

```sh
/usr/bin/perl ./run_preflight_002.pl
/usr/bin/perl ./run_formal_002.pl
```

Both `resource-preflight-002/execution-003` and
`run-002/execution-002` are consumed. These commands are recorded only for
reproducibility and are not authorized for rerun.

## Fixed interface and scope

- `run_i4_1b.m` has exactly two allowlisted pairs:
  `run_i4_1b('run-001','execution-001')` and the zero-eigensolve
  `run_i4_1b('resource-preflight-001','execution-002')`.
- `run_formal.pl` is a no-argument controller and literally launches MATLAB
  R2023b with that call.
- `run_preflight.pl` is the fixed no-argument representation/resource
  controller; it launches only the alternate identity above.
- The continuation carries 18.226698 s prior wall time, so its sole current
  wall deadline is 2,681.773302 s, equivalently cumulative wall time at least
  2,700 s. Memory uses the cumulative maximum of prior 1,084,440,576 B and
  current aggregate MATLAB-process-tree RSS, with the sole 3,221,225,472 B
  inclusive hard stop.
- Active MATLAB reads only literal source constants and current-execution
  caches. It does not read Markdown, Git, historical output, BIE/QZ data,
  densities, estimators, or a reference result.
- This is an empirical, non-certified FEM candidate workflow. It performs no
  effectivity comparison.

The sole prospective formal command is:

```sh
cd /Users/whc/Documents/Work/epost/test/i4/femref-a2
/usr/bin/perl ./run_formal.pl
```

It has not been run.

The separately gated preflight command was:

```sh
cd /Users/whc/Documents/Work/epost/test/i4/femref-a2
/usr/bin/perl ./run_preflight.pl
```

It was run once for each reviewed create-once execution. Its call graph
returns before every `eig`, `eigs`, `svd`, spectrum, object, tracking,
ranking, field, or reference-scalar path. Neither execution may be rerun.

## Reviewed preflight outcome

- `execution-001` ended `MATLAB_EXIT_NONZERO` after 18.226698 s with aggregate
  peak RSS 1,084,440,576 B. It completed two bulk representations and first
  failed at the `bulk-s18-g48` midpoint-reflection lookup. The implementation
  was repaired without changing the P2 method.
- `execution-002` ended `RSS_HARD_LIMIT_REACHED`. Its current execution used
  38.368379 s, so cumulative wall time is 56.595077 s. Its current and
  cumulative aggregate peak RSS is 3,471,147,008 B, above the
  3,221,225,472 B hard limit. It completed all three bulk representations and
  first exceeded the limit during the broad
  `mesh-defect-N5-s12-g36` construction/phase-reduction stage.
- Both executions made zero eigensolver calls. No defect eigenpair, field,
  P2 reference, P1--P2 drift, empirical uncertainty, or effectivity result
  exists.
- The final independent review verdict in
  [[research/projects/eig-apost/implementation/i4/review-4-1b#P. Final static review of Section 22|review §P]]
  is **`BLOCKED`**. The evidence blocks the current implementation lifecycle
  under this round's budget; it does not establish that fitted P2 FEM itself
  intrinsically requires more than 3 GiB.

## Frozen mathematical path

The continuous problem, fitted sharp-interface polygonal geometry, material
coefficient, quasiperiodic parameters, and relation $\lambda=k^2$ are those in
[[research/projects/eig-apost/implementation/i4/method-4-1|method-4-1]] and the
I4.1b design. Each active P1 triangle receives globally shared edge-midpoint
DOFs in the fixed local order $(v_1,v_2,v_3,e_{12},e_{23},e_{31})$. P2 forms
use the frozen seven-point degree-five rule; independently assembled P1 forms
provide the phase-compatible embedding, ordered Ritz check, and non-ranking
current-run companion evidence.

The P2 reflection permutation maps vertices by the validated vertex
permutation and maps each midpoint by exact lookup of its sorted reflected
endpoint edge in the sorted unique active-edge table. Coordinates independently
validate this combinatorial permutation; they never select a midpoint partner.

The base schedule contains 72 P2 bulk solves, 47 P2 defect solves, and five P1
companion solves, hence 124 calls. If any of the 17 anchor 48th-root ceilings
does not cover $W_3=[0.45,3.25]$ plus the 0.10 upper sentinel, all 17 anchor
slices receive the 60-root rung, for a maximum of 141 calls. The literal
Arnoldi pairs are $(\mathrm{nev},p)=(40,80),(48,96),(60,100)$.

Every finite, positive, residual-valid, field-bearing whole P2 cluster that
intersects $W_3$ remains rankable. Gap, localization, parity, overlap strength,
coverage, refinement behavior, births/deaths, and dimension changes are
diagnostics, not candidate-cancelling gates. The canonical rank is formed from
P2 objects before the five P1 companions are solved or assigned.

## Minimal artifacts

Within the current execution only:

- `work/` owns one mesh cache per reached mesh and one immutable cache per
  attempted valid spectrum;
- `scientific-result.mat` owns compact schedules, spectra, objects,
  assignments, rank, winner, six observed sensitivities, terminal, and claim;
- `fields.mat` owns P2 connectivity/midpoints, anchor and winner P2 subspaces,
  current-run P1 companion fields, common-grid samples, and assignments;
- `run.log` is concise and append-only;
- the controller opens `resource.tsv` as an append-only terminal-event ledger
  and atomically commits `run-summary.csv` last under the same absolute
  deadline.

READY is `P2_FEM_CANDIDATE_READY` under
`EMPIRICAL_P2_FEM_REFERENCE_CANDIDATE_NO_EFFECTIVITY`. Missing diagnostics or
missing empirical sensitivity components remain caveats. A true scientific
failure preserves the reached current-run compact state; an operational or
resource failure cannot fabricate READY.

## Static mesh/resource model

The following are source-derived expected topology counts, not executed mesh
measurements. They follow the deterministic point/constraint construction,
$E=(3T+B)/2$, $n_{2,\mathrm{full}}=V+E$, and the periodic-torus identity
$n_{2,\mathrm{red}}=2T$. MATLAB's constrained Delaunay/reflection-closure
output must still be confirmed by a separately authorized zero-eigensolve mesh
preflight before launch; that preflight must also report exact full/reduced
`nnz(K)` and `nnz(M)`. The last column is the assembly upper
$36T$, not an asserted measured `nnz`.

| Mesh | $V$ | $T$ | $B$ | $E$ | full P2 DOF | reduced P2 DOF | each-form `nnz` upper $36T$ | applicable $(\mathrm{nev},p)$ |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| `bulk-s12-g36` | 269 | 488 | 48 | 756 | 1,025 | 976 | 17,568 | $(40,80)$ |
| `bulk-s18-g36` | 461 | 848 | 72 | 1,308 | 1,769 | 1,696 | 30,528 | $(40,80)$ |
| `bulk-s18-g48` | 497 | 920 | 72 | 1,416 | 1,913 | 1,840 | 33,120 | $(40,80),(48,96)$ |
| `defect-N5-s12-g36` | 2,729 | 5,168 | 288 | 7,896 | 10,625 | 10,336 | 186,048 | $(48,96)$ |
| `defect-N5-s15-g36` | 3,576 | 6,790 | 360 | 10,365 | 13,941 | 13,580 | 244,440 | $(48,96)$ |
| `defect-N5-s18-g36` | 4,781 | 9,128 | 432 | 13,908 | 18,689 | 18,256 | 328,608 | $(48,96)$ |
| `defect-N5-s18-g24` | 4,421 | 8,408 | 432 | 12,828 | 17,249 | 16,816 | 302,688 | $(48,96)$ |
| `defect-N5-s18-g48` | 5,141 | 9,848 | 432 | 14,988 | 20,129 | 19,696 | 354,528 | $(48,96),(60,100)$ and P1 $(48,96)$ |
| `defect-N4-s18-g48` | 4,185 | 8,008 | 360 | 12,192 | 16,377 | 16,016 | 288,288 | $(48,96)$ |

The static lifetime model uses the observed I4.1a MATLAB/process baseline of
1,353,826,304 B only as a conservative planning datum. At the largest reduced
dimension, a complex 100-vector Arnoldi basis is 31,513,600 B and one 60-vector
return is 18,908,160 B. A 768 MiB factor allowance plus a 50 MB operator/map
allowance gives a solve-stage estimate of about 2.260 GB.

For the deliberately pessimistic field stage, retaining all 48 roots from all
47 base defect calls would occupy 635,322,624 B; their common-grid samples
would occupy 377,744,640 B; five P1 returns occupy 19,741,440 B. Adding the
baseline and operator allowance gives about 2.437 GB. A separate 512 MiB
serialization/publication allowance gives the largest modeled stage total,
about 2.973 GB, below 3,221,225,472 B but with a small enough margin that the
actual preflight table remains mandatory.

The implemented create-once preflight writes only `mesh-operators.tsv`,
`residency.tsv`, `preflight.log`, `resource.tsv`, and summary-last
`preflight-summary.tsv`. It measures actual full/reduced operator sparsity and
commits a simultaneous P1-companion lifetime containing the retained P2
fields/samples, four prior plus one current P1 field, P1 full/reduced forms and
factor, $p=96$/48-vector workspaces, and companion metadata. A distinct
publication lifetime retains the P2 fields/samples, all five P1 fields, compact
candidate/companion payload, and the 512 MiB publication copy. Its external
controller records the largest
individual MATLAB-tree process and the authoritative deduplicated aggregate
process-tree RSS by stage. The continuation has only the cumulative inclusive
2,700 s and 3,221,225,472 B predicates above. Its `resource.tsv` and summary
record prior, current, and cumulative wall values plus prior, current, and
cumulative-maximum RSS. Both controllers retain their absolute deadline
through summary-last: `resource.tsv` records provisional, terminal, and any
later wall/canonical-publication event, while a wall crossing prevents summary
commit and forces nonzero exit. After post-preflight review, its measured
wall/peak values must be frozen mechanically into `run_formal.pl`; until that
shared-budget update is reviewed, formal execution remains blocked.

Streaming/clear points are visible in the call graph: each mesh is cached and
released before the next; each eigensolver pair/factor and full non-defect
spectrum is released on return; bulk caches omit fields; candidate construction
loads one defect cache at a time; the fields publication payload leaves scope
before the compact scientific payload is created. No all-mesh factorization is
simultaneously resident.
