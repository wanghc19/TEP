# Band certificate reliable version 1

Bandrel means band certificate reliable. Arb/Acb are real/complex ball arithmetic; LDL* is lower-triangular, real-diagonal, conjugate-transpose factorization; RSS is resident set size. This experiment adds rounding inclusion to periodic-band certificate A. The certification space is 169 plane waves; it uses no defect eigenvalue solve.

## Method and inputs

`band_certificate.py` takes the explicit geometry export, output directory, pilot/full setting, precision, and an optional enclosure JSON. It uses 128-bit Arb/Acb, one computational thread. `floating.py` reproduces the original arithmetic with per-lead records; `original_reference.py` is the unchanged original reproduction script copied from `test/numerical-directions/rounding-estimate-v1/band/h-band-reproduce.py`. `launch_arb.py` and `monitor_arb.py` are copied from enclosure-v1.

The lead model is fixed: unit periods, beta=1/2, background/inclusion densities 1/17, original trefoil orientation. The radius and shape parameter balls contain both the exact decimals R=1/5, a=3/25 or 1/5 and their exact binary64 export values. Thus the separate CG6 geometry-transfer estimate is unnecessary. Source densities and the defect are unused. The optional copied enclosure is used only after the band tests to check T1.5, never to choose a test or basis.

For every matrix coefficient the 2048-point trapezoid is evaluated in Acb. The strip envelope is checked uniformly over the geometry balls: 2.69105 and 6.40695 are below the bound 8 used in A. The zero coefficient is pi R². The analytic entry error `32*pi/(exp(J/10)-1)` is kept separate from the quadrature ball and propagated through A's EPS_M and EPS_G formulas, so it is counted once. The matrices I+16B and 256(B-B²), phase midpoints/radii, thresholds, complement denominator and error corrections are all enclosed. Hermitian symmetrization preserves the enclosure of the exact Hermitian matrix.

Lower test: a floating eigenvector only chooses an exact binary64 vector v. Its squared norm is checked positive, and Arb evaluates `v* (K-low M) v / (v*v) + low EPS_M < 0`. The Rayleigh principle supplies an upper bound on the first eigenvalue.

Upper test: write `H=K-high M-high² G/den-upper_error I`. A floating eigensystem only chooses a 169-by-168 exact binary64 matrix W. Arb forms C=W*HW and D=W*W. Let g be the minimum diagonal-minus-off-diagonal row sum of C, and d be the maximum diagonal-plus-off-diagonal row sum of D; the minimum row bound of D must also be positive. Hermitian diagonal dominance gives C>=g I and 0<D<=d I. For g>0, W has rank 168 and every Rayleigh quotient on its range is at least g/d. Finite-dimensional min–max therefore gives lambda_2(H)>=g/d>0. No accuracy assumption about the floating eigenvectors enters this argument.

Four cases also use a separate Arb no-pivot LDL* recursion. Every diagonal pivot excludes zero; Sylvester's inertia law gives one negative and 168 positive directions. The failing control raises `high` to 10 on the left first panel: two independent negative directions are enclosed, and the positive-subspace checker rejects it.

The existing Theorem A.1 (Fourier complement) and Lemma A.2 (Bloch phase modulus), `research/explorations/numerical-directions/h-cert-proof.md` §2, extend the midpoint tests. The 118 consecutive integer-endpoint panels cover [0,pi]; y-reflection with conjugation covers [-pi,0] at fixed beta. Both full periodic leads have no spectrum in [1.318²,2.375²]. This does not count defect eigenvalues.

## Forecasts and measured costs

Before launch: run-001 forecast 120 s / .5 GiB, two panels per lead, full B assembly and floating reproduction. It measured 6.812684291 s / .207763672 GiB. The observed upper-test cost was .254–.300 s per panel. Run-002 forecast 90 s / .3 GiB including all 472 signs, four LDL* checks and the failing control. Pilot plus full forecast was below 100 s against the shared 30/40-minute result budget.

| Run | Scope | Monitor wall s | Scientific wall s | CPU s | Peak tree RSS GiB |
|---|---|---:|---:|---:|---:|
| run-001 | Pilot, 8 signs | 6.812684291 | 4.942477667 | 4.885976 | .207763672 |
| run-002 | Full, 472 signs | 76.902068917 | 74.985568541 | 74.836403 | .225967407 |

Full-run recorded components: both B assemblies .777648292 s; 236 upper checks 61.858839954 s; four LDL* checks 1.299027916 s; per-lead floating reproduction 1.303675584 s. Remaining scientific time includes the independent original-script reproduction, lower tests, scalar/matrix formation, JSON output and the failing control. Monitor wall includes Conda/interpreter startup and monitor sampling. Total monitored compute over both runs is 83.714753208 s. All runs completed without a resource stop.

## Results and checks

Raw sources: `output/run-002/result.json`, `floating.json`, `monitor.json`; the pilot has corresponding files under run-001. All 472 finite signs pass. Panel indices below are zero-based.

| Lead / test | Original floating minimum | Arb certified lower bound on margin | Panel |
|---|---:|---:|---:|
| a=.12, lower negative | .09265249740885617 | .0926524974089423 | 67 |
| a=.12, upper positive | .1785391993996978 | .17853919938633886 | 25 |
| a=.20, lower negative | .0001397223838884971 | .0001397223842868989 | 67 |
| a=.20, upper positive | .007520504511856631 | .007520504497007234 | 25 |

- Original-script reproduction: all eight common printed scalar outputs agree exactly in this execution, including coefficient, mass and G errors. Their Arb counterparts are enclosed; the analytic entry error is about 1.144959057965013e-87.
- B comparison: Acb encloses the difference from each exact binary64 floating matrix. Maximum entry-error bounds, including the analytic remainder, are 2.535803433106611e-17 and 3.868828487335091e-17; both pass the stated 1e-12 entry-comparison tolerance. This is an enclosure of floating B's error, not an assertion that every floating entry lies in the smaller quadrature ball. Corresponding norm bounds are 4.285507801950173e-15 and 6.538320143596303e-15.
- Independent upper certification: both leads, panels 0 and 117, pass both subspace and LDL* tests; all four inertias are (1 negative,168 positive). Minimum pivot absolute lower bounds are .7144233488946832, 2.501734200578449, 1.071896084771549, 2.2458871161217537. Across all subspace tests the Gram eigenvalues lie within [.9999999999989486,1.000000000001053].
- Deliberate failure: high=10 gives floating second eigenvalue -12.299831785784946, and a two-dimensional compression has certified negative row upper bound -12.299831785784727. The checker returns false as required.
- T1.5: the copied outward-rounded mu interval `[2.4287286700089671153321457,2.4287286700364527177209394]` has positive certified distances exceeding .6916046700089671 and 3.211896329963547 from the common band endpoints. This closes A's finite-arithmetic rounding condition for that interval, retaining the field/residual/mass and theorem hypotheses of enclosure-v1.

## Reproduction

From the repository working directory, through the approved escalated execution channel (use a fresh run directory):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/bandrel-v1/launch_arb.py \
  --output test/bie-bound/bandrel-v1/output/run-003 \
  --conda /Users/whc/opt/miniconda3/condabin/conda \
  --script band_certificate.py --forecast 90 -- \
  --input /Users/whc/Documents/Work/dot-research/test/bie-bound/bandrel-v1/output/input/fixed-input.json \
  --enclosure /Users/whc/Documents/Work/dot-research/test/bie-bound/bandrel-v1/output/input/enclosure.json \
  --mode full
```

`output/input/fixed-input.json` is an unchanged copy of cellfit-v1/output/input/fixed-input.json; `enclosure.json` is an unchanged copy of enclosure-v1/output/run-001/result.json. To repeat the pilot use `--mode pilot` and omit `--enclosure`. The launcher sets OMP/BLAS to one thread and OMP_DYNAMIC=FALSE. No matrices or fields are retained; outputs contain all panel scalars, certified margins, controls and monitors. Earlier experiments remain read-only.
