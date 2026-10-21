# I5.1d conditional signed regular-image diagnostic

This experiment replaces only the zero-centered regular-image contribution in
the I5.1c material-normal assembly.  It evaluates the retained reciprocal,
nonzero-image, and branch-free local Ewald sums with their physical signs,
keeps the M-R, M-I, M-T, and M-L remainders separate, and recomputes the
nonlinear retained and low-cell material bounds.  The I5.1c lifting result is
carried through unchanged.

The finite `Faddeeva_erfc`, `expint`, and exponential evaluations are assumed
exact.  Therefore every result is a conditional diagnostic labelled
`FINITE_SPECIAL_FUNCTION_EVAL_ASSUMED_EXACT`; it is not a reliable finite
evaluation enclosure and cannot restore a certified or roundoff-inclusive
claim.

The explicit workflow is

```matlab
build_residual_numerator_input_v3( ...
  v2_input_path, artifact_path, v3_input_path);
residual_numerator_v3( ...
  v3_input_path, v2_input_path, same_run_v2_output_path, v3_output_path);
```

`residual_numerator_v2` and its genuine MATLAB dependencies must already be on
the MATLAB path.  The v2 result path is a new create-once target generated in
the same invocation; no historical output is read.  The v3 evaluator validates
the explicit v2 input against the contract embedded by the builder and obtains
the baseline result directly from the v2 function return value.

One complete run is planned for at most 15 minutes and 1.7 GiB peak memory.
The signed Ewald assembly streams target blocks and does not retain dense
coordinate-kernel matrices in the generated input.

## Canonical attempt result

Run-01 failed during restricted-sandbox MATLAB startup before the builder and
created no scientific artifacts.  The same attempt's run-02 completed the
builder, a fresh same-run I5.1c baseline, and the I5.1d evaluator.  Its wall
time was 18.21 s and maximum RSS was 978993152 bytes; Code Analyzer reported
zero issues for both v3 MATLAB files.

Run-02 used $L=256$ and $N=514$.  The persisted conditional diagnostic is

| module | finite square | tail square | bound |
|---|---:|---:|---:|
| artificial wall | $3.5088928806097918\times10^{-20}$ | $1.2402726533962042\times10^{-63}$ | $1.8732039079101324\times10^{-10}$ |
| material normal | $1.9215047644499741$ | $1.1504505415838253$ | $1.7526994340256401$ |
| lifting, unchanged from fresh I5.1c return | not recomputed here | not recomputed here | $748498.34329471563$ |

Hence

$$
\widehat{\mathcal M}=748500.0959941498.
$$

The regular unit-row radius separates into source quadrature
$6.4335982057355448\times10^{-42}$, target quadrature
$7.661073710189474\times10^{-20}$, M-R
$8.2910496824456709\times10^{-25}$, M-I
$3.4914778993599262\times10^{-11}$, M-T
$2.0529395015278222\times10^{-29}$, and M-L
$8.9951561629918053\times10^{-12}$, for a maximum total
$4.3909935233202631\times10^{-11}$.  The finite-evaluation radius is zero
only under `FINITE_SPECIAL_FUNCTION_EVAL_ASSUMED_EXACT`.

The canonical artifacts are `input/residual-numerator-v3.mat` and
`output/residual-numerator-a1/result.mat`.  The same output directory contains
the fresh baseline, run diary, audit, resource record, and the run-01 startup
failure record.  These values are `NON_CERTIFIED_ROUNDOFF_EXCLUDED` and
conditional; `reliable_eval_enclosure_pass=false` and
`total_reliable_pass=false` remain the governing conclusion.
