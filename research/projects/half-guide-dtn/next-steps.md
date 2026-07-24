# Next Steps

## Immediate Recovery Steps

1. Extend the current source inventory to the exact center-cell trace operators
   needed for `Pi_l,D/N` and `Pi_h,D/N`.
2. Design the first periodic-obstacle local-cell DtN block prototype under
   `attempt/prototype/`, without modifying package files.
3. Continue network/source lookup and record URLs in
   `attempt/literature/source_log.md`.
4. Add QZ/stable-invariant-subspace construction for non-diagonal finite
   matrices and compare it with Riccati/Newton ideas.
5. Extend `attempt/prototype/run_all.m` or add a second entry point for simple
   periodic-lead validation.

## Candidate Commands

Repeat the current rough Octave sanity check, if needed:

```bash
conda run -n octave octave --no-gui --quiet --eval "addpath(genpath(pwd)); run('attempt/prototype/run_all.m')"
```

Manual MATLAB validation for the current homogeneous prototype:

```matlab
addpath(genpath(pwd));
run('attempt/prototype/run_all.m');
```

## Completed First Outcome

The homogeneous lead test now reports that the computed project DtN matches the
analytic Rayleigh-basis diagonal DtN to roundoff away from cutoffs. Outputs:

- `attempt/experiments/homogeneous_dtn_validation.csv`
- `attempt/experiments/homogeneous_dtn_validation.md`
- `attempt/experiments/experiment_summary.md`

## Next Expected Outcome

The next successful milestone should produce a simple periodic-obstacle lead
DtN diagnostic with:

- local cell block dimensions;
- QZ-selected stable branch count;
- Riccati or invariant-subspace residual;
- comparison against `bloch.solve_modes` outgoing traces where the Dirichlet
  trace block is well-conditioned;
- explicit failure reporting near bad mode counts or ill-conditioned graph
  representations.

