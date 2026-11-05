# Enclosure version 1

Enclosure means the final reliable spectral-distance enclosure. BIE is boundary integral equation; FEM is finite element method; CG denotes the grouped trace constant; FFT is fast Fourier transform; Arb/Acb are real/complex ball arithmetic; JSON is JavaScript Object Notation; CSV is comma-separated values; RSS is resident set size. The helper names self_interaction, lead_self and cell_operator refer to the material self-interaction, its lead version and the cell Müller operator. lead_double uses double precision; lead_balls uses ball arithmetic.

## Result and scope

The reliable spectral-distance radius is at most 1.37428011943968e-11, using five certified residual groups, five certified trace constants and U >= 1.23587. The decimal mu interval is [2.4287286700089671153321457, 2.4287286700364527177209394]. Its endpoint difference is 2.74856023887937e-11. The k interval is [1.5584378941776817290675347, 1.5584378941865000472345282].

The interval meets the spectrum under the accepted field and residual certificates. Interpreting its spectral point as an isolated finite-multiplicity eigenvalue cites the existing band certificate A, whose finite matrix tests exclude rounding. No uniqueness assumption is used. The code does not rerun A.

The right-lead discrepancy is predominantly double-precision normal-jump evaluation noise. At 256 identical curve targets, maximum floating versus Arb midpoint differences are 2.26750e-15 for the value and 9.72357e-14 for the normal jump. Unsummed components reach 0.72708 and 2.41303. This diagnosis concerns the right lead; the same explanation for the left lead is an inference.

## Explicit inputs and copied code

All large inputs are under output/input. Copy:
- fixed-input.json from test/bie-bound/cellfit-v1/output/input/fixed-input.json;
- coefficients.json from test/bie-bound/cellfit-v1/output/run-002/coefficients.json;
- groups.json from test/bie-bound/grouprel-v1/output/run-007/groups.json;
- disks.json from test/bie-bound/matrel-v1/output/run-001/mass-refined/disks.json.

The first input is also byte-identical to matrel-v1/output/run-001/export/fixed-input.json. output/input-identity.json records this comparison and equality of each piece. Source inputs are unchanged.

trace_constants.py copies the numerical reference from tmp/cg-cert/reference.py; assemble.py calls its geometry and scalar functions without reading tmp or a scan record. The fixed model is beta=1/2, d=L=1, materials 1/4/17/17, unreflected shapes, cells bounded by +/-1/2. The delta/eta values are the exact binary64 numbers in cg-cert table 3.1; curvature caps and published constants are exact decimal rationals. Model restrictions and full integer-panel coverage are asserted.

The MATLAB cell_* helpers and pilot_geometry are copied from cellfit-v1; shared kernel, quadrature, utilities and Bloch routines are resolved only through the explicitly supplied package path. The Arb helpers are copied from grouprel-v1. Runtime reads explicit numerical inputs, never documents or metadata.

## Entry points and formulas

- assemble.py: two curvature/trace configurations (192 bits/256 initial panels; 160 bits/512). Parse khat as an exact binary64 rational, square it in Arb, read epsilon decimal uppers exactly, check the saved eight-disk lower bound exceeds 1.23587. Compute Q=sum(C*epsilon), R=2*mu*Q/(U-Q), both intervals and the margins to 1.318^2 and 2.375^2. Check the rational formula independently and round decimal endpoints outward.
- lead_double.m: the same 1536-node cellfit material operator, exact exported Fourier polynomial evaluated by inverse FFT, full port action followed by G and c, plus the saved B field. Save every sixth target (256 total), both jumps and the alternative early-state projection. The normal jump is minus the second raw Müller row.
- lead_balls.py: the same first actual state, exact dispersion, source moments and B coefficients. Evaluate the continuous Müller difference at those same indexed angles 2*pi*j/1536 with 1152 Kress sources and 192-bit arithmetic. Strip off the square-root arclength factor and reverse the second row. Three points additionally use 2304 sources and independent proxy sums.
- diagnose_point.py: preserves the small diagnosis of the coincident-node failure.

## Reproduction

Use a fresh run number if a directory already exists. Set the following explicit paths:
~~~sh
exp=/Users/whc/Documents/Work/dot-research/test/bie-bound/enclosure-v1
repo=/Users/whc/Documents/Work/dot-research
conda_bin=/Users/whc/opt/miniconda3/condabin/conda
inp="$exp/output/input"
~~~

The successful commands were:
~~~sh
PYTHONDONTWRITEBYTECODE=1 python3 "$exp/launch_arb.py" --output "$exp/output/run-001" --conda "$conda_bin" --script assemble.py --forecast 10 -- --input "$inp/fixed-input.json" --groups "$inp/groups.json" --disks "$inp/disks.json"
PYTHONDONTWRITEBYTECODE=1 python3 "$exp/launch_double.py" --output "$exp/output/run-002" --input "$inp/fixed-input.json" --fits "$inp/coefficients.json" --package-root "$repo" --matlab /Applications/MATLAB_R2023b.app/bin/matlab
PYTHONDONTWRITEBYTECODE=1 python3 "$exp/launch_arb.py" --output "$exp/output/run-006" --conda "$conda_bin" --script lead_balls.py --forecast 180 -- --input "$inp/fixed-input.json" --fits "$inp/coefficients.json" --floating "$exp/output/run-002/double.csv"
~~~

The launchers use copied monitors. MATLAB has 11 computational/OpenMP threads, OMP_DYNAMIC=FALSE. Arb uses one process and one FLINT thread. Limits are 30/40 minutes and 3 GiB.

## Forecasts, measurements and checks

| Run | Forecast seconds/GiB | Measured wall seconds/peak GiB | Outcome |
|---|---:|---:|---|
| 001 | 10 / .2 | 1.2341 / .08086 self-reported | Both trace configurations, decimal readbacks, two precisions and exact rational assembly passed |
| 002 | 120 / 2.2 | 20.3939 / 1.63673 | Floating operator and 256 target export completed |
| 003 | 180 / .4 | 25.9365 / .20531 | Coincident-source real-ball power returned NaN |
| 004 | 5 / .2 | 1.2271 / peak missed by sampler | Isolated the signed-zero-containing distance-square operation |
| 005 | 180 / .4 | 43.8854 / .17601 | Arb comparison at printed CSV angles completed |
| 006 | 180 / .4 | 44.0500 / .18330 | Final exact-indexed-angle comparison completed |

For run-001 the one-second monitor missed the short worker's peak; the process itself reported 86,818,816 bytes. Full monitor records preserve the sampled values rather than substituting the self-reported number into them. The stage used 136.72691 monitored seconds, including failures.

At a coincident source, a real interval for x-u contains both signs and the copied real-ball power returned NaN. Only the squared-distance expression in copied lead_self.py now uses multiplication instead of power. This is the same polynomial interval expression; the radial-domain assertion remains unchanged. Runs 003/004 preserve the failure. Existing upstream code is untouched.

Trace constants: both configurations give C upper endpoints 2.490253373242827 / 1.1815829449939497 / 1.2339406067375382 / 1.0355521263049687 / 1.0355521263049687. The published decimal caps are strictly larger. Complete leaf covers are 270/282/286 and 522/522/526. Star-shaped collars, Jacobians, copy separation and finite stationary-point tests all pass.

Assembly: Q <= 3.496544492949122436e-12; U-Q >= 1.2358699999965034555070508. R's printed upper endpoint is identical at both precisions and for the exact rational formula. The band margins are >= 0.691604670008967115332145 and 3.211896329963547282279060. Every epsilon decimal agrees with the supplied upper; the saved U ball is >1.23587. All eight disks pass the readback geometry inequalities. Detailed certificates are in run-001/result.json.

Diagnostic: the floating 40-cell square sum is 4.044058650172081e-27, near the earlier 4.047e-27. On the common 256 first-cell points, floating and Arb-midpoint trapezoid square sums are 3.296879196618267e-27 and 2.309861663835707e-27; the latter agrees in scale with the reliable panel integral upper 2.309824585634470e-27. These sample sums are diagnostic estimates. The normal maximum is 1.06682e-13 in double and 4.44011e-14 in Arb. Projecting the state early changes a double normal value by up to 2.10253e-14 but does not remove the noise. Three independent source-doubling differences are below 2.07e-37; proxy direct/expansion differences are below 3.83e-47.

## Cost boundary

output/cost-ledger.json gives exact raw stage times and their sources. Candidate science process 642.986955 s; density rebuild 3.397437 s; B fit 3.009847 s; five-group reliable run 517.672462 s (8 processes); eight-disk mass 20.990072 s; this trace/assembly run 1.234070 s. Sum: 1189.290843 s (19.8215 minutes).

This sum combines recorded stages and excludes an unmeasured unified startup/export/disk-selection total and the cited band certificate. It is not a measured cold end-to-end run. Historical I9.2's full 96.084 s includes the older floating residual and mass evaluation and is not added again. The present floating/Arb diagnosis is additional investigation, not part of the enclosure's production cost.

Final same-node check run-006: forecast 180 seconds / .4 GiB, measured 44.0500 seconds / .18330 GiB. Exact indexed angles 2*pi*j/1536 replace 15-digit CSV angles. Relative to run-005, value/normal midpoints change by at most 3.33e-28 / 3.09e-27 (output/angle-check.json); the discrepancy is unchanged. The final point records are in run-006.
