# I7.3 corrected-density fixed-point refinement experiment

This directory contains the six-configuration fixed-point experiment described
in the [I7.3 design](../../../research/projects/eig-apost/implementation/i7/design-7-3a.md)
and summarized in the [I7 status page](../../../research/projects/eig-apost/implementation/i7/README.md).
The current corrected-density rerun compares the frozen points `kL=1.753125`,
`k0=1.755995740875`, and `kR=1.75625` for these `(ntot,M)` pairs:

| ID | `ntot` | `M` |
|---|---:|---:|
| B | 256 | 48 |
| M56 | 256 | 56 |
| M64 | 256 | 64 |
| N384 | 384 | 48 |
| N512 | 512 | 48 |
| J | 512 | 64 |

All configurations use `(nside,ntop,nproxy,mpw)=(160,160,80,32)`, lead
`epsrel=17`, and center ellipse `epsrel=2` with axes `(0.25,0.16)`.

The 2026-09-26 `run-04`/`run-06` results below predate the density-coordinate
fix in public `bloch.construct_S`. They are retained as historical evidence and
are not inputs to the current rerun. The current order is a fresh 18-point
fixed run followed by a fresh 66-point local run; the local grid is
`k0+(-5:5)*1e-5`. Endpoint sign gates apply only at `kL` and `kR`. A center
`Hsym` unresolved diagnostic does not fail the center `Aphys` object.

## Entry and reproduction

`check_i7_refinement(checkpoint_dir)` runs the fixed three-point experiment.
`check_i7_refinement(checkpoint_dir,'local')` runs only the common 11-point
grid `k0+(-5:5)*1e-5`. Both modes save a unique checkpoint after every
completed or classified invalid point. The entry does not read documentation,
Git metadata, or historical results.

Run both stages in one monitored MATLAB process so that the 1800-second budget
is shared. `run-09` below must be unused; the launcher refuses overwrite. The
fixed evidence is cleared before the local stage to release large matrices.
The full production command, including JSON/CSV, source snapshots, and plots,
is archived in [run-08/command.txt](output/attempt-1/run-08/command.txt).

```bash
cd /Users/whc/Documents/Work/epost
MATLAB_BIN=/Applications/MATLAB_R2023b.app/bin/matlab \
I73_WALL_LIMIT_SECONDS=1800 I73_RSS_LIMIT_BYTES=2300000000 \
bash test/i7/refine-v1/run_matlab_monitored.sh \
test/i7/refine-v1/output/attempt-1/run-09 \
"repo=pwd; exp_dir=fullfile(repo,'test','i7','refine-v1'); run_dir=fullfile(exp_dir,'output','attempt-1','run-09'); addpath(repo); addpath(exp_dir); assert(strcmp(which('check_i7_refinement'),fullfile(exp_dir,'check_i7_refinement.m'))); assert(strcmp(which('bloch.construct_S'),fullfile(repo,'+bloch','construct_S.m'))); fixed_dir=fullfile(run_dir,'fixed'); mkdir(fixed_dir); fixed_cp=fullfile(fixed_dir,'checkpoints'); mkdir(fixed_cp); [result,evidence]=check_i7_refinement(fixed_cp,'fixed'); save(fullfile(fixed_dir,'scientific.mat'),'result','evidence','-v7.3'); audit=audit_i7_refinement(result,evidence); save(fullfile(fixed_dir,'audit.mat'),'audit'); assert(result.execution_pass&&audit.pass); clear result evidence audit; local_dir=fullfile(run_dir,'local'); mkdir(local_dir); local_cp=fullfile(local_dir,'checkpoints'); mkdir(local_cp); [result,evidence]=check_i7_refinement(local_cp,'local'); save(fullfile(local_dir,'scientific.mat'),'result','evidence','-v7.3'); audit=audit_i7_local(result,evidence); save(fullfile(local_dir,'audit.mat'),'audit'); assert(result.execution_pass&&audit.pass);"
```

## Current corrected-density evidence

Stage A is saved under [attempt-1/run-08/fixed](output/attempt-1/run-08/fixed/).
All 18 points were valid. All endpoint count bands gave `negative=0` at `kL`
and `negative=1` at `kR`, with no endpoint unresolved counts. All 18
same-object edges passed, so the fixed-stage outcome is `STABLE_SAME_MODE`.
The center `Hsym` diagnostic had one unresolved eigenvalue in each of the
three bands for every configuration;
this is outside the endpoint count gate and all center `Aphys` object gates
passed.

The following tables are copied from the saved
[points.csv](output/attempt-1/run-08/fixed/points.csv). The `pos/neg/unres`
triples shown for `c=100` were identical at `c=50,100,200`; thus they record
all three count bands compactly. At every point both QZ directions had `K`
stable, `K` unstable, zero neutral, and zero indeterminate channels, with no
numerical solve warning. `L/C/R` mean `kL/k0/kR`.

| Config | Point | `rcond(T)` | assembly error | solve error |
|---|---|---:|---:|---:|
| B | L | `0.51702058265282613` | `5.4553954713536217e-19` | `3.7747494080452222e-19` |
| B | C | `0.51699568185647415` | `6.7368233287598983e-19` | `3.694124348655895e-19` |
| B | R | `0.5169934488000496` | `5.7764643426271877e-19` | `2.8012171613030743e-19` |
| M56 | L | `0.51702058265282613` | `5.9142428731793824e-19` | `2.9297397954257162e-19` |
| M56 | C | `0.51699568185647404` | `3.7475843063756724e-19` | `2.2413422346222814e-19` |
| M56 | R | `0.51699344880004949` | `5.368347877481281e-19` | `1.9918265726705781e-19` |
| M64 | L | `0.51702058265282591` | `3.6239364287208044e-19` | `2.2261481214314912e-19` |
| M64 | C | `0.51699568185647404` | `3.9123244861352736e-19` | `2.4027234734630411e-19` |
| M64 | R | `0.51699344880004949` | `4.1788139314040232e-19` | `1.5273924016130189e-19` |
| N384 | L | `0.51702058265282602` | `4.5801233856542691e-19` | `3.7742637103245984e-19` |
| N384 | C | `0.51699568185647393` | `6.803874700569183e-19` | `3.6929721442067819e-19` |
| N384 | R | `0.5169934488000496` | `8.292434072996824e-19` | `2.7992257469039994e-19` |
| N512 | L | `0.51702058265282602` | `7.7099034467331665e-19` | `3.7753556599388049e-19` |
| N512 | C | `0.51699568185647382` | `5.8374917040483181e-19` | `3.693850406014533e-19` |
| N512 | R | `0.5169934488000496` | `7.2977893916524708e-19` | `2.7974447404272309e-19` |
| J | L | `0.51702058265282602` | `3.5182194636115587e-19` | `2.2254154578458183e-19` |
| J | C | `0.51699568185647382` | `2.7224736529926725e-19` | `2.4007940657536498e-19` |
| J | R | `0.51699344880004949` | `4.0136244728736536e-19` | `1.5285632482754929e-19` |

| Config | Point | `s` | `dH` | `eta50` | `eta100` | `eta200` | `minabs` | `pos/neg/unres` |
|---|---|---:|---:|---:|---:|---:|---:|---|
| B | L | `604.17561555534041` | `2.053125626861299e-13` | `1.3014984904175209e-09` | `2.6027916682723556e-09` | `5.2053780239820255e-09` | `0.021226887785565883` | `194/0/0` |
| B | C | `604.17558220816011` | `1.871889938530571e-13` | `1.3014802950244414e-09` | `2.6027734010550295e-09` | `5.2053596131162065e-09` | `8.7214472117181015e-11` | `193/0/1` |
| B | R | `604.17557925199787` | `2.1757952844695718e-13` | `1.3015106791919563e-09` | `2.6028037788554658e-09` | `5.2053899781824847e-09` | `0.0018805683718730109` | `193/1/0` |
| M56 | L | `704.70803184638612` | `1.7896837769818797e-13` | `1.7683647350404456e-09` | `3.5365505017031929e-09` | `7.0729220350286875e-09` | `0.021226887785421193` | `226/0/0` |
| M56 | C | `704.7080032564561` | `1.9172994658335886e-13` | `1.7683774248742217e-09` | `3.5365631198018599e-09` | `7.0729345096571365e-09` | `8.7262702709246849e-11` | `225/0/1` |
| M56 | R | `704.7080007220153` | `1.9315029336600774e-13` | `1.7683788388618287e-09` | `3.5365645274302916e-09` | `7.0729359045672167e-09` | `0.001880568371647726` | `225/1/0` |
| M64 | L | `805.24008573801461` | `2.3525238369337333e-13` | `2.3067451479103894e-09` | `4.6132550434370852e-09` | `9.2262748344904761e-09` | `0.021226887785575573` | `258/0/0` |
| M64 | C | `805.24006071746237` | `2.3794185534017812e-13` | `2.3067477657137816e-09` | `4.6132575895722228e-09` | `9.2262772372891052e-09` | `8.7070399180741853e-11` | `257/0/1` |
| M64 | R | `805.24005849944001` | `2.3575573002234417e-13` | `2.3067455732352151e-09` | `4.6132553907404079e-09` | `9.2262750257507936e-09` | `0.0018805683719292587` | `257/1/0` |
| N384 | L | `604.17561555534019` | `1.4283760109372483e-13` | `1.3014360154559278e-09` | `2.6027291933107619e-09` | `5.2053155490204302e-09` | `0.021226887785630998` | `194/0/0` |
| N384 | C | `604.17558220815954` | `1.8811741184239117e-13` | `1.3014812234424296e-09` | `2.602774329473017e-09` | `5.2053605415341911e-09` | `8.6994508228904249e-11` | `193/0/1` |
| N384 | R | `604.17557925199753` | `1.9819400640600291e-13` | `1.3014912936699148e-09` | `2.6027843933334236e-09` | `5.2053705926604413e-09` | `0.0018805683717872089` | `193/1/0` |
| N512 | L | `604.17561555534098` | `1.9066299996174268e-13` | `1.3014838408547976e-09` | `2.6027770187096333e-09` | `5.2053633744193049e-09` | `0.02122688778573183` | `194/0/0` |
| N512 | C | `604.17558220816045` | `2.5928725310748363e-13` | `1.3015523932836965e-09` | `2.6028454993142857e-09` | `5.2054317113754643e-09` | `8.6835168830521385e-11` | `193/0/1` |
| N512 | R | `604.17557925199776` | `1.6814498580484897e-13` | `1.3014612446493141e-09` | `2.6027543443128232e-09` | `5.2053405436398417e-09` | `0.0018805683719025504` | `193/1/0` |
| J | L | `805.24008573801609` | `2.6280010581193412e-13` | `2.3067726956325119e-09` | `4.6132825911592123e-09` | `9.2263023822126123e-09` | `0.02122688778547719` | `258/0/0` |
| J | C | `805.24006071746317` | `2.0972564666324206e-13` | `2.3067195495051069e-09` | `4.613229373363551e-09` | `9.2262490210804375e-09` | `8.6918624231377736e-11` | `257/0/1` |
| J | R | `805.24005849943899` | `2.0255191613586635e-13` | `2.3067123694213253e-09` | `4.6132221869265148e-09` | `9.2262418219368947e-09` | `0.0018805683716851909` | `257/1/0` |

| Config | `adef_sigma` | `adef_ratio` | `aphys_sigma` | `aphys_ratio` |
|---|---:|---:|---:|---:|
| B | `1.0113801620671046e-10` | `1.6739838415360665e-13` | `5.0025687287374273e-11` | `1.7513129037661042e-11` |
| M56 | `1.0113337297569616e-10` | `1.4351103224081291e-13` | `5.0023479271823017e-11` | `1.7512356049555016e-11` |
| M64 | `1.0113895968614702e-10` | `1.2560100350202761e-13` | `5.0026179341700115e-11` | `1.7513301297381378e-11` |
| N384 | `1.0113517695200213e-10` | `1.6739368476688536e-13` | `5.0024383566187489e-11` | `1.7512672627392381e-11` |
| N512 | `1.0113424612739088e-10` | `1.6739214411440174e-13` | `5.0023755495118554e-11` | `1.7512452750559667e-11` |
| J | `1.0113861394426398e-10` | `1.2560057413704718e-13` | `5.0026350871172081e-11` | `1.7513361346886731e-11` |

The smallest primary overlap was `0.9999999999999994`, the largest
primary-competitor cross-overlap was `5.1934739087163063e-14`, and the largest
total squared tail above `|m|=48` was `1.1929356645472612e-30`. The six
`aphys_ratio` values span only `1.0052973317143901e-15`; automatic plot-axis
scaling must not be read as a significant dip change or a convergence rate.
The entry runtime was `350.80521704166665` seconds and the fixed stage wall
time was `358.846955` seconds. The saved-data
[audit](output/attempt-1/run-08/fixed/audit.json) passed all 18 points and 18
comparisons.

The old and current endpoint wavenumbers are identical, so their `dH` values
can be compared directly: the old approximately `6.94e-3`/`6.98e-3` values
fall to `1.43e-13`--`2.63e-13`, while the `0 -> 1` count jump remains. The
center metrics are evaluated at different sampled points: old
`k0=1.7545053299700002` and current `k0=1.755995740875`, separated by
`1.4904109049997949e-3`. Their roughly `5.75e-8` before/after ratio is not a
same-wavenumber regression and must not be called a six-configuration drift.

Stage B is saved under [attempt-1/run-08/local](output/attempt-1/run-08/local/).
All 66 points were valid and passed their point diagnostics. The actual double
interval was `[1.7559457408749999,1.7560457408750001]` with nominal spacing
`1e-5`. All six `aphys_ratio` winners and all six independent `aphys_sigma`
sampled argmins were grid index 6, `k=1.755995740875`.

| Config | valid bracket | full neighbor spacing | left ratio gap | right ratio gap |
|---|---|---:|---:|---:|
| B | `[1.755985740875,1.756005740875]` | `2.0000000000131024e-5` | `1.4870276308128473e-5` | `1.4870251468814921e-5` |
| M56 | `[1.755985740875,1.756005740875]` | `2.0000000000131024e-5` | `1.4870276308333567e-5` | `1.4870251470121332e-5` |
| M64 | `[1.755985740875,1.756005740875]` | `2.0000000000131024e-5` | `1.4870276307434020e-5` | `1.4870251469271948e-5` |
| N384 | `[1.755985740875,1.756005740875]` | `2.0000000000131024e-5` | `1.4870276307207669e-5` | `1.4870251468980830e-5` |
| N512 | `[1.755985740875,1.756005740875]` | `2.0000000000131024e-5` | `1.4870276308077021e-5` | `1.4870251469884793e-5` |
| J | `[1.755985740875,1.756005740875]` | `2.0000000000131024e-5` | `1.4870276307492001e-5` | `1.4870251468153824e-5` |

At the repeated `k0`, all four metrics for every configuration matched Stage A
exactly in double precision. All 66 same-wavenumber hard-edge comparisons were
`SIMPLE_VECTOR / SAME_MODE`; minimum primary overlap was
`0.9999999999999994`, maximum cross-overlap was
`3.6251735206506948e-14`, and maximum total squared tail above `|m|=48` was
`8.5821055331273043e-32`. The [local audit](output/attempt-1/run-08/local/audit.json)
passed all six winners and 66 comparisons; its metric and comparison maximum
absolute discrepancies were `4.5047767089100715e-18` and
`3.3306690738754696e-16`.

The result is `NO_DRIFT_RESOLVED_AT_SPACING_1E-5`: this common finite grid did
not resolve a configuration-dependent sampled-winner shift. It is not a
sub-grid location, error bound, continuous minimum, or convergence statement.
The local entry runtime was `1255.9446958333333` seconds and stage wall time
was `1259.272412` seconds. The single monitored A+B run used
`1630.584183` seconds wall time and peaked at `1,505,230,848` bytes for both
task-tree and all-MATLAB RSS; it exited 0 with no external MATLAB root. No AUX
or additional refinement was run.

The independent review records `PASS WITH CONDITIONS`: the result is accepted
as finite-dimensional, fixed-auxiliary-parameter, finite-grid evidence subject
to the interpretation limits above.

## Historical evidence before the density-coordinate fix

The successful formal run is [attempt-1/run-04](output/attempt-1/run-04/):

- 18 of 18 evaluations were valid.
- All six configurations gave the same endpoint count change, with the main
  band negative count changing from 0 at `kL` to 1 at `kR`.
- All 18 prescribed edge/object comparisons passed the frozen same-mode rule.
- The recorded outcome is `STABLE_SAME_MODE`. This is finite-dimensional
  numerical stability evidence, not a continuous eigenvalue certificate.
- The independent saved-data [audit](output/attempt-1/run-04/audit.json)
  passed all 18 points and 18 comparisons.

The main artifacts are
[scientific.mat](output/attempt-1/run-04/scientific.mat),
[result.json](output/attempt-1/run-04/result.json),
[points.csv](output/attempt-1/run-04/points.csv), and
[refinement-summary.png](output/attempt-1/run-04/refinement-summary.png).

The experiment runtime was 340.255368 seconds. The monitored wall time was
365.178545 seconds, and peak task-tree and MATLAB-union RSS were both
1,943,863,296 bytes, below the 2,300,000,000-byte early-stop threshold.
Including the 1-second failed preflight and the 12.888699-second parse-failure
run, total conservative MATLAB wall usage was 380 seconds.

The successful local scan is [attempt-1/run-06](output/attempt-1/run-06/):

- All 66 evaluations were valid and passed their finite-object diagnostics.
- Every configuration selected the fresh `k0` sample (grid index 6). Each
  winner was strictly below both neighbors; the full neighbor spacing was
  `2.0000000000131e-5` and ratio gaps were about `3.6404e-7` on each side.
- All 66 same-wavenumber edge comparisons passed the frozen same-mode rule.
- `NO_DRIFT_RESOLVED_AT_SPACING_1E-5` means only that this grid did not
  resolve configuration-dependent movement. It is not location convergence
  or an error bound.
- The saved-data [local audit](output/attempt-1/run-07/audit.json) passed six
  winners and 66 comparisons. Its largest reported discrepancy was
  `3.33066907387547e-16`.

The local numerical entry took 1236.527470 seconds; monitored wall time was
1250.057854 seconds and peak RSS was 1,606,238,208 bytes. Saved-data audit and
plotting took 13.889967 seconds with peak RSS 1,238,335,488 bytes. Including
all starts, failures, fixed and local runs, total conservative MATLAB wall
usage was 1699.729068 seconds.

## Preserved failures and static notes

- `run-01` is the unmonitored failed preflight; it performed no scientific
  evaluation.
- `run-02/monitor-selftest` preserves non-MATLAB RSS, signal cleanup, lock,
  and actual preflight rejection of existing external MATLAB processes.
  The attempted dynamic foreign-process injection did not yield a valid
  test; its evidence is retained, and that branch was inspected statically.
- `run-03` preserves the MATLAB parse failure caused by using the reserved
  word `otherwise` as a local helper argument. The corrected source renames
  that argument to `fallback` without changing behavior.
- Formal `checkcode` reported two advisories: stale suppression `MSNU` at the
  checkpoint assignment and `NASGU` for the warning guard that is explicitly
  cleared to trigger its `onCleanup` restoration. Neither affected execution.
- `run-05` preserves a 56.714003-second stopped local run after the independent
  review required stronger invalid-point and diagnostic-state wording.
- `run-06` is the complete local scan. `run-07` is its saved-data-only audit
  and [local scan figure](output/attempt-1/run-07/local-scan.png).
- Current local-source `checkcode` advisories are two stale `MSNU`
  suppressions and the intentional warning-guard `NASGU`; the audit has no
  advisories, and the plot has one stale `MSNU` suppression.
