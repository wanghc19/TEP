# Example 1 with deliberately perturbed candidates

**All 11 distinct perturbations stopped before the verifier issued an interval.** Nine stopped while printing an outward-rounded defect term. Two stopped because a published trace constant was too small at the new frequency. The counts per perturbation are 0 pass, 0 wrong, 0 partial overlap and 11 safe failures. Including the first memory-limited attempt gives 12 verifier stops. A separate MATLAB driver setup error occurred before verification.

Perturb-v1 means perturbation campaign, version 1. BIE means boundary integral equation. FEM means finite element method.

## Purpose and falsification criterion

Does the package still enclose the example 1 eigenvalue when the trial field or its wavenumber is inaccurate? The reference is the closed $k$ interval $I_{\rm ref}=[1.5584378941776960035929265,1.5584378941864799995494084]$ in `release/bie-enclosure-sisc/reference/ex1/results.json`. A completed interval containing this entire interval passes. A disjoint interval inside the isolation window counts as a wrong result under the example 1 isolation assumptions. Partial overlap is inconclusive. A numerical check that stops verification gives a safe failure.

The BIE result gives existence for the reference interval. Uniqueness in $\mu\in(1.7424,5.6169)$ uses the separate FEM result and its finite-rounding estimates. Transferring that count also assumes the one $2^{-56}$ difference in a geometry coefficient between implementations preserves the count. See the package README, its FEM README, and `fem/reference/ex1/isolation.json`. An interval outside that uniqueness window alone cannot falsify the spectral-distance theorem.

## Wavenumber dependence

Family A gives a legitimate piecewise Helmholtz trial field for all six shifts. Section 5 of `draft/bie-siam/sec-bound.tex` requires the equation in each piece, ordinary traces, and square integrability. Any mismatch in the matching equations contributes to the interface jumps. Here the curves, source positions, finite Fourier modes, and lead propagation matrices stay fixed. The verification procedure recomputes residuals, lead tails, disk mass, trace constants, and gap containment in sequence.

| Stored data in example 1 | Dependence on the solve at $k$ | What the verifier does at $\hat k$ |
|---|---|---|
| `fixed-input.k`, `model.k0` | Frequency of the exported field and its construction setting | Set both to the same binary64 word. Residuals, disk integrals and interval assembly read the first. The contract checks the physical model in the second file. |
| `incident` | Center incoming amplitudes from matching | Hold the amplitudes fixed. Each Rayleigh wave uses the new longitudinal wavenumber $\sqrt{\hat k^2-(\beta+2\pi m/d)^2}$. |
| `rayleigh_modes`, each piece's `modes`, `native_nodes` | Truncation and Fourier indices are fixed discretization choices | The same finite set defines waves and smooth trigonometric densities. |
| All three pairs `tau_coeff,zeta_coeff` | Center Fourier densities and lead density maps were solved at $k$ | Use the saved coefficients in exact layer integrals with exterior kernel at $\hat k$ and interior kernel at $\hat k\sqrt{\rho}$. |
| Lead `G,c,P` | Incoming-amplitude map, first state and propagation matrix came from the solve and lead decomposition | Use $P^jc$, incident amplitudes $GP^jc$, and density maps times those amplitudes. Intercell mismatch enters the jumps. The contraction and infinite tails are checked. |
| `Z`, `B_center,B_negative,B_positive` in `coefficients.json` | Positions are geometric. The strengths and two maps were fitted at $k$. | With the same exterior source positions, the new Green functions solve the new equation. Lead strengths are $BP^jc$. |
| `proxy_Z,proxy_c` at top level and per piece, `proxy_equal` | Positions are geometric. The old proxy strengths belong to candidate construction. The Boolean records equality between copies. | The production expansion uses near images and the fitted B sources. Its kernels temporarily replace the old charge list. The disk integrals use only the interior densities. |
| `phase,phase_minus`, `beta,d` | Transverse phases depend on $\beta,d$ alone | The verifier forms $e^{\pm i\beta d}$ from the exact inputs. Longitudinal phases are recomputed with $\hat k$. |
| `H,curve_parameters`, piece names, shapes and `arg`, disk and band inputs, remaining model settings | Geometry, material, sampling and solver settings | Keep these fixed. The material interfaces, source separation, phase partition and operator remain those of example 1. |

Implementation sources under `release/bie-enclosure-sisc/` are `src/matlab/field/field_export.m` for construction, `src/python/residual/{group_setup,expansion,panel,extended,tail_bound}.py` for field evaluation, `src/python/mass/disks.py` for mass, and `scripts/{validate_data,verify}.py` for the contract and run stages.

## Cases specified before execution

The A and B writers start from the six canonical example 1 JSON files. All cases use the package verifier and the same interval criterion. The reference verification took 679 s and 1.92 GiB. Allow about 12 minutes and 2 GiB per verification, one at a time, with a 30-minute soft limit and hard limits of 40 minutes and 3 GiB. Each listed sign and magnitude defines a separate case.

| Data set | Input and suspicion | Predicted observation | Falsification criterion |
|---|---|---|---|
| 001 | A, $+10^{-9}$. Small frequency error might be missed. | Radius grows and interval covers reference, or a guard stops. | A returned interval disjoint from the reference within the isolation window. |
| 002 | A, $-10^{-7}$. Lower frequency might expose asymmetric underestimation. | Radius grows, with a possible fixed-threshold rejection. | Same. |
| 003 | A, $+10^{-7}$. Compare growth with 001. | Radius rises roughly in proportion to candidate displacement if both return one. | Same. |
| 004 | A, $-10^{-9}$. Compare growth with 002. | Radius covers the smaller downward shift. | Same. |
| 005, 006 | A, $+10^{-5},-10^{-5}$. The largest shifts stress the fixed certificate thresholds. | Wider enclosures or an explicit rejection. | Same. |
| 007, 008 | B, density coefficients only at $10^{-8},10^{-6}$, seed 7101. Independent coefficient errors may escape the jump calculation. | Radius grows with amplitude, or a guard stops. | Same interval criterion. No growth is a diagnostic. |
| 009, 010 | B, old proxy strengths and fitted B coefficients together at $10^{-8},10^{-6}$, seed 7102. Errors in the exterior smooth field may escape the jumps. | Radius grows with amplitude, or a guard stops. | Same interval criterion. The interior disk field is unchanged. |

The family C case (runs 012 and 013) calls the linear solve and B fit at the exact $+10^{-7}$ frequency of data set 003. A re-solve can reduce interface errors and expose an underestimated radius closer to $\Delta$. Predict a smaller radius than the corresponding fixed-coefficient run or a numerical rejection. The disjointness criterion above applies. Dependencies are the package's MATLAB `field_export`, its B fit, MATLAB R2023b, FMM2D in `vendor/fmm2d/matlab`, and the usual verifier. The reference field stage took 20.3 s and 1.19 GiB (`reference/ex1/stage-times.json`). Allow 17–23 minutes and about 2.2 GiB for both stages under a single outer monitor.

The first eight-worker execution of data set 001 reached the 3 GiB monitor limit during the residual stage. Its 385 s, 3.010 GiB peak and stop reason appear in `output/run-001/end-to-end.json`. The residual subprocess in its own process group survived the outer monitor and was stopped before the next run. Runs 002 through 011 use data sets 001 through 010 in order and four residual workers. The observed worker peaks under eight-way execution suggest about 2.2 GiB at four workers. Allow 16–22 minutes, with the same hard limits. The scientific inputs, precision, quadrature, state count and comparisons stay as specified above. The family C verifier also uses four workers.

Run 012 stopped before field construction because the local driver omitted the package's `examples/` directory from MATLAB's path. Run 013 repeats the same predeclared fixed-frequency case with that directory supplied, within the same estimated resources. The error and original command are in `output/run-012/run.log`.

After the verifier runs, replay any `terms_upper` conversion failure with the original `assemble.directed` function, using each run's saved five group bounds and the package's two precisions. The suspicion is an ambiguous integer in decimal conversion. The check fails to explain the stop if it cannot reproduce the exception. It requires only Python and python-flint and takes seconds.

## Reproduction

Run from the repository root with Python 3.14.4, python-flint 0.9.0 (FLINT 3.6.0), NumPy 2.5.4 and SciPy 1.18.1. Use new data and output directories for a repetition. The perturbed data sets in `data/` are not tracked in Git; the commands below regenerate them (sets 001–010 bit for bit from the seeds, set 012 by a new MATLAB solve and fit). The package verifies its own inputs without reading the reference. The comparison reads the reference only after verification.

```sh
PYTHON=<Python with the packages above>
MATLAB=<MATLAB R2023b executable>
PKG="$PWD/release/bie-enclosure-sisc"
CAM="$PWD/redteam/perturb-v1"
export BIE_STORAGE_ROOT="$CAM"
write_case() {
  id=$1
  shift
  "$PYTHON" -B -I "$CAM/perturb.py" --source "$PKG/data/ex1" --output "$CAM/data/$id" "$@"
}
write_case zero --shift 0
write_case 001 --shift=+1e-9
write_case 002 --shift=-1e-7
write_case 003 --shift=+1e-7
write_case 004 --shift=-1e-9
write_case 005 --shift=+1e-5
write_case 006 --shift=-1e-5
write_case 007 --group density --epsilon 1e-8 --seed 7101
write_case 008 --group density --epsilon 1e-6 --seed 7101
write_case 009 --group sources --epsilon 1e-8 --seed 7102
write_case 010 --group sources --epsilon 1e-6 --seed 7102
# Historical run 001 called verify.py with --workers 8 on data/001.
# Four-worker series, with run number followed by data set number.
sh "$CAM/verify-series.sh" "$PYTHON" "$PKG" "$CAM" 4 002:001 003:002 004:003 005:004 006:005 007:006 008:007 009:008 010:009 011:010
```

For any single case, the equivalent package command and comparison are

```sh
id=001
run=002
"$PYTHON" -B -I "$PKG/scripts/verify.py" --example ex1 --workers 4 --data "$CAM/data/$id" --output "$CAM/output/run-$run"
"$PYTHON" -B -I "$CAM/compare.py" --run "$CAM/output/run-$run" --data "$CAM/data/$id" --reference "$PKG/reference/ex1/results.json"
```

For family C, run the following after the serial series. The outer monitor includes MATLAB startup, the fixed-frequency solve and fit, and the entire verification.

```sh
sh "$CAM/refit.sh" "$PYTHON" "$PKG" "$CAM" "$MATLAB" "$PWD/vendor/fmm2d/matlab" "$PWD/redteam/tmp/perturb-v1"
"$PYTHON" -B -I "$CAM/compare.py" --run "$CAM/output/run-013/verify" --data "$CAM/data/012" --reference "$PKG/reference/ex1/results.json"
```

The writer evaluates $k(1+s\delta)$ as a rational and rounds once to binary64. In family B each selected complex coefficient receives its own multiplier $1+\epsilon(X+iY)/\sqrt{2}$ with independent standard real normals from Python's seeded generator. Both amplitudes in a group use the same draws. Array entries follow the saved column-major order. The repeated copies of the old proxy coefficients receive identical updates. Only the fitted B strengths enter the verified source field.

In a density perturbation the two stored Nyquist modes also receive independent draws. Both entries remain explicit terms in the finite Fourier series defining the trial field. Array shapes, order, modes and the sign convention $D\tau-S\zeta$ are preserved.

## Results

A dash in the interval column means the verifier returned no $k$ interval. The displacement is $\Delta=\max(0,a^2-\hat{k}^2,\hat{k}^2-b^2)$ for $I_{\rm ref}=[a,b]$. The squares and differences are exact for the saved binary64 candidate and the printed reference endpoints. The ratio is undefined at $\Delta=0$. On a stopped run, *italic* entries are diagnostic. They use the saved five residual bounds, the five published trace constants and the nominal $U=1.23587$ in the radius formula. A failed trace or mass check invalidates the use of those constants in a certificate. The value after the slash is the disk mass lower bound rounded down to nine decimal places. Each `output/run-NNN/comparison.json` records the verdict and cost. Each `formula.json` records the separate arithmetic and the full disk readback when available.

To reproduce the diagnostic calculation, save the output of `compare.py` as `comparison.json`, then run

```sh
"$PYTHON" -B -I "$CAM/components.py" --package "$PKG" --run "$CAM/output/run-$run" \
  --data "$CAM/data/$id" --comparison "$CAM/output/run-$run/comparison.json"
```

| Run | Family, perturbation | $\hat k$ (hex) | $k$ interval | $Q$ | $U$ used / disk lower | $R$ | $\Delta$ | $R/\Delta$ | Verdict | s | GiB |
|---|---|---|---|---|---|---|---|---|---|---:|---:|
| 001 | A, +1e-9 | `3ff8ef5c9330d784` | — | — | — | — | 4.84376781E-9 | — | verifier stopped | 384.9 | 3.010 |
| 002 | A, +1e-9 | `3ff8ef5c9330d784` | — | *2.2693400304E-8* | *1.23587* / 1.235871208 | *8.9194030214E-8* | 4.84376781E-9 | *18.414180* | verifier stopped | 766.0 | 2.175 |
| 003 | A, −1e-7 | `3ff8ef5c68f03e40` | — | *2.2693354380E-6* | *1.23587* / 1.235871193 | *8.9193993840E-6* | 4.85732020E-7 | *18.362800* | verifier stopped | 756.8 | 1.891 |
| 004 | A, +1e-7 | `3ff8ef5cbc9b4020` | — | *2.2693357430E-6* | *1.23587* / 1.235871224 | *8.9194041508E-6* | 4.85732069E-7 | *18.362810* | verifier stopped | 767.2 | 1.898 |
| 005 | A, −1e-9 | `3ff8ef5c925aa6dc` | — | *2.2693307749E-8* | *1.23587* / 1.235871208 | *8.9193666079E-8* | 4.84376780E-9 | *18.414110* | verifier stopped | 775.8 | 1.351 |
| 006 | A, +1e-5 | `3ff8ef6cea2c1ceb` | — | *2.2693461012E-4* | *1.23587* / 1.235872747 | *8.9212432385E-4* | 4.85748026E-5 | *18.365990* | verifier stopped | 779.9 | 1.466 |
| 007 | A, −1e-5 | `3ff8ef4c3b5f6175` | — | *2.2693248484E-4* | *1.23587* / 1.235869670 | *8.9208028352E-4* | 4.85743168E-5 | *18.365270* | verifier stopped | 768.9 | 1.556 |
| 008 | B, density 1e-8 | `3ff8ef5c92c5bf30` | — | *1.5610142022E-7* | *1.23587* / 1.235871216 | *6.1354032802E-7* | 0 | — | verifier stopped | 789.3 | 1.444 |
| 009 | B, density 1e-6 | `3ff8ef5c92c5bf30` | — | *1.5610141903E-5* | *1.23587* / 1.235871951 | *6.1354799554E-5* | 0 | — | verifier stopped | 746.3 | 1.943 |
| 010 | B, sources 1e-8 | `3ff8ef5c92c5bf30` | — | *8.3666374145E-9* | *1.23587* / 1.235871208 | *3.2884190567E-8* | 0 | — | verifier stopped | 746.6 | 1.666 |
| 011 | B, sources 1e-6 | `3ff8ef5c92c5bf30` | — | *8.3665590475E-7* | *1.23587* / 1.235871208 | *3.2883904593E-6* | 0 | — | verifier stopped | 741.1 | 1.597 |
| 012 | C, +1e-7 | `3ff8ef5cbc9b4020` | — | — | — | — | 4.85732069E-7 | — | driver setup stop | 19.8 | 0.852 |
| 013 | C, +1e-7 | `3ff8ef5cbc9b4020` | — | *1.9681433715E-6* | *1.23587* / 1.235870752 | *7.7355948467E-6* | 4.85732069E-7 | *15.925640* | verifier stopped | 789.1 | 1.665 |

## Checks

1. Writer round trip passed. All 711,618 decoded binary64 words matched bit for bit across the six files, including signed zeros. All remaining JSON values also matched. See `data/zero/perturbation.json`.
2. For the two smallest positive shifts (002 and 004), neither verification issued a radius. Evaluating the same formula independently from the saved residual sums gives a radius ratio of 100.000013 for a displacement ratio of 100.279800. For the negative shifts (005 and 003), the formula ratio is 100.000367 and the displacement ratio is 100.279790. Both comparisons use exact rational radii and displacements before display rounding (`output/scaling.json`). The requested scaling check on verifier-issued radii was unavailable for both signs.
3. The table below identifies the first stop in every execution. All 11 scientific cases passed `validate_data.py`. None stopped on a data-contract check.
4. Runs 002–007 cover both signs at each of $10^{-9}$, $10^{-7}$ and $10^{-5}$.

| Runs | First failed check | Role |
|---|---|---|
| 001 | The package monitor saw 3.010 GiB in the residual stage and reported `RSS_LIMIT`. | Operational memory limit. Run 002 used the same input. |
| 002, 004–006, 008–011, 013 | `enclosure/assemble.py:67` calls `directed(v,30,True)` on each group product. At line 21, the scaled Arb ceiling contained more than one possible integer. `unique_fmpz()` returned `None`, and `int(None)` raised `TypeError`. | Outward decimal reporting. The residual audit, disk mass, first trace-constant calculation, and rational radius cross-check had succeeded before printing stopped. |
| 003 | `assemble.py:46` requires the calculated trace constant to be strictly below the published cap. For the negative lead, cap squared minus the calculated squared constant is $-1.2416851784\times10^{-7}$. | Reliability guard on the constants used in $Q$. See `output/run-003/formula.json`. |
| 007 | The same assertion first fails for the center. Its squared margin is $-1.8014369764\times10^{-4}$. The disk mass bound also falls below 1.23587. The trace check stopped execution first. | Reliability guard. See `output/run-007/formula.json`. |
| 012 | MATLAB could not resolve `ex1()` in `pilot_config.m:13` because the local driver omitted the package examples directory. | Driver setup. Run 013 supplied the missing path and completed the solve. |

Replaying only the failing decimal conversion reproduced all nine exceptions at 192 bits. In run 002 the exact number $10^{30}(2.490254)(2.414223120577913\times10^{-9})$ is the integer 6012028782911630159902. The ball calculation could not select a unique ceiling for printing. The first affected group was center in 002, 006, 009 and 011, positive lead in 004 and 005, and walls in 008, 010 and 013. The stage tracebacks are in `06-enclosure/run.log` under each verifier output. The inputs and first failing terms are in `output/rounding.json`.

```sh
set -- "$CAM/output/run-002" "$CAM/output/run-004" "$CAM/output/run-005" "$CAM/output/run-006" \
  "$CAM/output/run-008" "$CAM/output/run-009" "$CAM/output/run-010" "$CAM/output/run-011" \
  "$CAM/output/run-013/verify"
"$PYTHON" -B -I "$PKG/scripts/monitor.py" "$CAM/output/decimal-replay" \
  "$PYTHON" -B -I "$CAM/rounding.py" --package "$PKG" --output "$CAM/output/rounding.json" "$@"
```

## Interpretation and remaining cases

Containment remains unresolved for every perturbed input because the verifier returned no interval. The reproducible defect is in the availability of the published calculation. No run produced a counterexample to the spectral-distance theorem.

At fixed $k$, increasing the noise by a factor of 100 raised the diagnostic radius from $6.1354\times10^{-7}$ to $6.1355\times10^{-5}$ for densities and from $3.2884\times10^{-8}$ to $3.2884\times10^{-6}$ for source strengths. The canonical radius is $1.36893121609235\times10^{-11}$.

At the same $+10^{-7}$ frequency, rebuilding the field reduced the diagnostic radius from $8.91940415\times10^{-6}$ (004) to $7.73559485\times10^{-6}$ (013). In 013 the wall defect was $1.90056916\times10^{-6}$ and the other four defect bounds were at most $1.262\times10^{-12}$. The smallest diagnostic $R/\Delta$ was 15.925642 in 013. The verifier never issued that radius.

All six planned fixed-coefficient shifts and both noise amplitudes for both coefficient groups were tested. Only the $+10^{-7}$ shift was tested with a new linear solve. The legacy proxy strengths were changed together with the fitted B coefficients. A legacy-proxy-only execution and other random seeds were outside this series.
