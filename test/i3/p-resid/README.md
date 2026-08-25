# I3.1 pure-BIE boundary residual

This directory implements the reviewed design
[[research/projects/eig-apost/implementation/i3/design-3-1e|design-3-1e]]. It uses the saved
candidate and shared total wall traces to define a finite-density, exact rectangular
Dirichlet-Green trial. A value-only radial collar repairs the material-circle value jump;
artificial-wall jumps, the remaining circle normal jump, and the collar volume source enter
one ordinary-double residual indicator through a triangle sum.

The implementation has one entry and one scientific helper:

- `check_p_resid.m` owns the frozen candidate, full propagation matrices, boundary factors,
  Riccati circle weights, radial collar quadrature, full-matrix tails, result schema, and report;
- `i31_cell_bie.m` owns the finite rectangular-Green Müller solve, overresolved circle action,
  and wall normal-derivative maps.

No Q1, RT0, or two-dimensional volume mesh is used. The helper split follows the cell-BIE and
global-boundary-estimator objects. After adding the append-only attempt history, the entry has
1024 lines and the scientific helper has 551 lines; no further split is introduced for this
schema-only revision.

## Frozen contract

- Attempt: `pbie-a2` (`pbie-a1` is a consumed implementation failure).
- Schema: `TEP_I3_1_PURE_BIE_BOUNDARY_RESIDUAL_V1_REV_A`.
- Candidate: $\widehat k_h=1.832770289108157$; $n_{\mathrm{tot}}=256$, $M=48$.
- Density/circle nodes: $256/512$.
- Smooth Green orders: $48/64$; wall samples: $256/512$.
- Collar width: $0.04$; radial Gauss rules: $16/32$.
- Riccati steps: $256/512$; full-$P$ depth: $j=0,\ldots,12$.
- Expected cost: 5--10 min and 150--300 MiB.
- Soft/hard time limits: 900/1800 s; hard active-object memory limit: 512 MiB.
- Retry count: zero; prior failed attempts: one.

The completed MATLAB command was:

```bash
matlab -batch "addpath(fullfile(pwd,'test','i3','p-resid'),fullfile(pwd,'test','i2','k-count')); check_p_resid('pbie-a2');"
```

Current state: `POST-RUN PASS WITH CONDITIONS / NUMERICALLY_UNQUALIFIED INDICATOR CANDIDATE`.
The append-only `pbie-a1` output records a valid implementation failure before boundary-Gram
assembly: a fieldless empty warning struct could not accept the first typed warning. Revision A
only gives every warning container the frozen `code/value/blocking` schema and records the prior
attempt; it changes no scientific formula, parameter, threshold, or resource limit. Formal
`pbie-a2` then completed with `retry_count=0`.

The three residual components are wall $1.8732651111819612\times10^{-10}$, circle
$4.2041578545992812\times10^{-14}$, and collar volume
$5.8690572462596622\times10^{-11}$. Their triangle sum is
$2.4605912515933872\times10^{-10}$; the field lower candidate is $2.2269063318145634$, giving
$q=1.1049370224693775\times10^{-10}$. The ordinary-double nominal $k$ interval is
$[1.8327702889056474,1.8327702893106665]$, with width
$4.0501912934587381\times10^{-10}$.

Three nonblocking warnings prevent a qualified interpretation: wall $256\to512$ change
$0.23020558465752644$, manufactured-kernel maximum error $1.4438757363102721$ localized to
nonzero-mode $T$ checks, and circle outside-$M$ share $0.51468601513057144$. All reliability,
continuous-enclosure, projected-gap, and independent-reference flags are false. The result is not a
spectral enclosure, existence claim, continuous-eigenvalue error bound, or I3.2 reference. The
independent interpretation is
[[research/projects/eig-apost/implementation/i3/review-3-1e|review-3-1e]].

Runtime was $117.91992858333333$ s and peak active-object memory was
$242.98618412017822$ MiB. The SHA-256 values are
`06a319f51364a950f018e4210a9e66747d6b34b5fa68552d697f90d30a899b75` for `result.mat` and
`98e0a0e32fd79aa167804451d05f1620f4104eb813c2457a9d0d273d5a263658` for `report.md`.

Any finite $q<1$ will produce only an `UNQUALIFIED` or `NUMERICALLY_UNQUALIFIED` algebraic
interval. All reliability and independent-reference flags remain false; this experiment cannot
serve as I3.2 validation or as a computable error bound.
