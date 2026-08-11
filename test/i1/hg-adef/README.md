# Half-guide to A-def joint verification

This test-local I1.2 experiment implements the manufactured empty-center assembly
oracles and the low-order real half-guide chain authorized by sections 6--15 of
`research/projects/eig-apost/implementation/i1/design.md`. It contains no locator,
root claim, estimator, or production constructor.

Run from the repository root with:

```text
conda run -n octave octave --quiet --no-gui --eval "addpath('test/i1/hg-adef'); r=run_hg_adef('pilot');"
```

The qualified real arm is MATLAB-only:

```text
matlab -nodesktop -batch "addpath(fullfile(pwd,'test','i1','hg-adef')); r=run_hg_adef('real');"
```

The deterministic manufactured case uses `K=3`,
`tol_alg=1e3*K*eps`, and requires every negative mutation to exceed `1e-8`.
It checks matrix dimensions, left/right Cauchy signs, graph-to-DtN Schur
equivalence, graph-basis invariance, retention of a nearly vertical graph,
projective pair acceptance/rejection, and five assembly mutations. No `inv` or
`pinv` call is permitted.

The authoritative run is `output/real/report.md`. Here `M=5` is the central
restriction of the generated `M=8` master blocks, while both low/high package
discretizations are compared at each fixed `M`. The `M=5,8` result is a
low-order mechanism qualification only; it does not replace the frozen
production `M_trace=48` evidence and does not authorize I1.3 by itself.

The direct-bandwidth extension uses `make_prod.m` and `run_prod.m`. The current
authoritative static command constructs and checks direct `M=48`, `K=97`
coarse/fine maps:

```text
matlab -nodesktop -batch "addpath(fullfile(pwd,'test','i1','hg-adef')); make_prod('full'); r=run_prod('full');"
```

The static production gate intentionally does not form or apply a dense or
matrix-free generalized-Sylvester separation operator. It uses direct block
changes, original/reversed QZ counts and residuals, coarse/fine subspace
projectors, algebraic chart checks, DtN action stability, and graph/DtN Schur
equivalence. Missing production separation is an important caveat rather than
a blocker for this empirical frozen-`k` gate. It remains open for stronger
perturbation or theorem-level claims.

`output/prod-pilot/report.md` is a **NON-AUTHORITATIVE MATRIX-FREE
EXPLORATION**. Its first run contained a chart-argument wiring error and its
later overwritten numbers used the now-retired separation policy. It must not
certify `M=48`, chart perturbation safety, or the current I1.2 verdict.

The real branch is fail-closed. `input/cell.mat` must exist and satisfy the full
physical, two-level, block, mode-order, wall-label, residual, solver, source-hash,
and zero-fallback provenance contract checked by `LOCAL_preflight`. If that
contract is not met, the pilot emits `CELL_INPUT_PROVENANCE_FAIL`; all real QZ,
graph, DtN, and A-def gates are `NOT_RUN_PREREQ`. `derivative_available` is
always false in this pilot.

`make_cell.m` is a MATLAB-only input generator and is not run by the pilot. It
hard-fails outside MATLAB or when the public `lsqminnorm` path is unavailable.
Both spatial levels are generated once at `M_master=8`; the declared `M=5`
level is the frozen central principal restriction, not a separate BIE solve.
Run it manually from the repository root only when the frozen low/high cell
artifact is requested. The pre-run budget was 7--18 minutes with a 30-minute
cap; the frozen input generation took about 2.62 seconds and the final MATLAB
joint chain took about 1.75 seconds on the recorded host.

Artifacts are written below `output/<run-label>/`.
