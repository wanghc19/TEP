# Guided-mode eigenvalue enclosures by boundary integral equations: reproduction and verification

This package accompanies the paper *Reliable enclosures of guided-mode eigenvalues in periodic waveguides with a line defect by boundary integral equations*. For each of five examples it constructs a trial field from a boundary integral equation (BIE) discretization and proves, with ball arithmetic, that a narrow interval $I_k$ contains at least one guided-mode wavenumber at fixed Bloch parameter $\beta$. No uniqueness claim is made.

Abbreviations used below: BIE = boundary integral equation; FMM = fast multipole method; SVD = singular value decomposition; RSS = resident set size; LDL* = lower-triangular/diagonal/conjugate-transpose factorization. File-name abbreviations of the source code are expanded in [src/README.md](src/README.md).

## Layout

| Path | Content |
|---|---|
| `scripts/` | Entry points `reproduce.py` and `verify.py`, the resource monitor, data validation and promotion |
| `src/` | MATLAB code for search, densities and the B fit; Python code for the reliable evaluation |
| `examples/` | Parameters of the five examples |
| `data/<example>/` | Canonical field of each example (exact binary64 coefficients, JSON); dictionary in [data/README.md](data/README.md) |
| `reference/<example>/` | Reference results, group bounds, tail records, band margins, timings and validation records |
| `tests/` | Smoke test, path scan, read check, reproduction comparison, failing control |
| `environment/` | Tested versions, FMM2D source revision and build notes, third-party licenses |

## Two layers

- **verify** (Python only) reads one canonical data set and recomputes every reliable certificate from it: continuous residual bounds of the five defect groups with lead tails, mass bounds, trace constants, the interval assembly, and the common-gap test of both leads. It does not use MATLAB, FMM2D, search results, or saved residual, mass or trace bounds. Comparison with `reference/` happens after the recomputation.
- **reproduce** (MATLAB and Python) starts from an empty directory and the example parameters: gap exploration and determinant search, densities, B fit, then the same reliable evaluation as verify.

The canonical coefficient files define the field that is checked; the accuracy of the search or of a linear solve is not part of the claim. A new SVD fit may give slightly different coefficients and bounds; to check such a field, pass its own data directory to verify.

## Requirements

Tested on macOS 14 (Apple M3 Pro, 18 GiB) with Python 3.14.4, python-flint 0.9.0 (FLINT 3.6.0), NumPy 2.5.4 and SciPy 1.18.1; reproduce also needs MATLAB R2023b (base MATLAB only) and an FMM2D MATLAB build. POSIX `ps`, process groups and Python `fork` are required. The scripts install nothing. Details are in [environment/README.md](environment/README.md).

## Commands

Set `PKG` to the absolute path of this package, `PYTHON` to a Python with the packages above, and `EXAMPLE` to one of `ex1`, `ex2-L1`, `ex2-L1.6`, `ex2-L1.9`, `ex2-L2`. `<RUN>` and `<VERIFY_RUN>` are distinct empty or nonexistent directories; `<MATLAB>` is the MATLAB executable and `<FMM_ROOT>` the directory containing `hfmm2d.m` and the matching FMM2D MEX file.

```sh
# Quick checks (seconds)
"$PYTHON" -B -I "$PKG/tests/smoke.py" --data "$PKG/data/$EXAMPLE" --reference "$PKG/reference/$EXAMPLE"
"$PYTHON" -B -I "$PKG/tests/paths.py" --package "$PKG"

# Verify the canonical field (10-18 min)
"$PYTHON" -B -I "$PKG/scripts/verify.py" --example "$EXAMPLE" \
  --data "$PKG/data/$EXAMPLE" --reference "$PKG/reference/$EXAMPLE" \
  --output "<VERIFY_RUN>"

# Reproduce from the parameters (14-26 min)
"$PYTHON" -B -I "$PKG/scripts/reproduce.py" --example "$EXAMPLE" \
  --output "<RUN>" --python "$PYTHON" --matlab "<MATLAB>" --fmm-root "<FMM_ROOT>"
```

Both drivers refuse a nonempty output directory, run each stage in its own monitored process with explicit inputs, and keep failure logs. The monitor stops the whole run once it exceeds 40 minutes of wall time (`HARD_LIMIT`), 3 GiB process-tree RSS, 200 MB of package size, or 1.99 GB of disk use under `BIE_STORAGE_ROOT` (default: the current directory). Passing 30 minutes does not stop the run; it only sets `soft_limit_exceeded` in the stage's `monitor.json`. MATLAB starts with a reset path that contains only `src/matlab` and `<FMM_ROOT>`. For `ex1`, `verify.py --workers N` sets the number of residual processes (default 8); the other examples use the counts in the table below.

`scripts/promote.py --example NAME --run RUN --data DATA --reference REF` converts a completed reproduce run into a data set and reference tables. This is a maintenance step; no numerical stage reads earlier outputs.

## Examples

All examples use transverse period $d=1$ and $\beta=0.5$. Both leads hold three-lobe rods of radius 0.2 and density 17, with deformation 0.12 on the left and 0.20 on the right. In `ex1` (Section 6.1 of the paper) both lead periods are 1 and the center cell of width 1 holds a star-shaped rod of density 4. In the `ex2-L*` family (Section 6.2, Table 3) the center of width $L_0$ is empty, and the right lead has period 0.85 and its rod is rotated by 0.13. Geometry numbers are rounded to binary64 as described in the data dictionary. Each reproduce run selects the lowest confirmed candidate in the window and uses no saved frequency.

| Example | $L_0$ | Tail-square target | States left/right | Residual processes | Gap-test window | Cold run s / GiB | Verify s / GiB |
|---|---:|---:|---:|---:|---|---:|---:|
| `ex1` | 1, star | $10^{-6}$ | 80/80 | 8 | (1.318, 2.375) | 851 / 1.74 | 679 / 1.92 |
| `ex2-L1` | 1, empty | $10^{-6}$ | 80/80 | 8 | (1.46, 2.37) | 1076 / 1.79 | 575 / 2.11 |
| `ex2-L1.6` | 1.6, empty | $10^{-2}$ | 100/100 | 6 | (1.46, 2.37) | 1194 / 1.69 | 719 / 1.96 |
| `ex2-L1.9` | 1.9, empty | 0.1 | 80/160 | 5 | (1.46, 2.37) | 1353 / 1.75 | 854 / 1.95 |
| `ex2-L2` | 2, empty | 0.1 | 80/230 | 5 | (1.45, 2.37) | 1532 / 2.49 | 1063 / 2.18 |

Times and peaks were measured on the tested machine (MATLAB with 11 threads). For `ex2-L2` a second candidate near $k=2.2156$ lies in the window; it is recorded and **not treated**.

Numerical settings of `ex1`: center/left/right boundary nodes 512/256/256; Rayleigh cutoff 48; proxy collocation 160/160 with 80 proxy sources per edge and 32 auxiliary plane waves during candidate construction; FMM tolerance $10^{-12}$. The B fit uses 480 point sources, margin 0.35, 240 points per fit side, a 1440-by-610 scaled SVD system and cutoff $10^{-14}$. The reliable evaluation uses 192 center panels, 64 per lead-material curve, 16 segments per junction or interior-wall type and 8 pairs per seam type; 48 Chebyshev nodes, local models of degree 52, source degree 80, adaptive Kress self-interaction with 1152 sources, and 128-bit main and 192-bit combination arithmetic. Eight mass disks use order-30 source integration; trace certificates use 192 and 160 bits. The band test uses 169 plane waves, 2048 source nodes and 118 phase panels per lead. The settings of the other examples are in `examples/<name>.json` and `reference/<name>/summary.json`.

## Reference results and tolerances

$Q$ and $U$ are the defect bound and the mass lower bound of the spectral-distance theorem, $R$ the radius of the spectral-distance bound in $\mu=k^2$, and the width is $2R$. Upper bounds are rounded upward and interval endpoints outward. The width is computed as $2R$, so it can be slightly smaller than the difference of the displayed endpoints.

| Example | Candidate (binary64) | $k$ interval | Width in $\mu$ | $Q$ | $U$ | $R$ |
|---|---|---|---:|---:|---:|---:|
| `ex1` | `3ff8ef5c92c5bf30` | [1.5584378941776960035929265, 1.5584378941864799995494084] | $2.7378624321847\times10^{-11}$ | $3.482935419894950973\times10^{-12}$ | 1.23587 | $1.36893121609235\times10^{-11}$ |
| `ex2-L1` | `3ffe44632bf7ef62` | [1.8916961400523295383424295, 1.8916961400531453646534362] | $3.0865909669693\times10^{-12}$ | $1.39283748129089527\times10^{-13}$ | 0.645928 | $1.5432954834847\times10^{-12}$ |
| `ex2-L1.6` | `3ff94d9906573195` | [1.5814447639149828628460134, 1.5814447639169911052734138] | $6.3518489429721\times10^{-12}$ | $4.12005038116436373\times10^{-13}$ | 0.648889 | $3.1759244714861\times10^{-12}$ |
| `ex2-L1.9` | `3ff7af4780d78b48` | [1.4802928002243211293798036, 1.4802928002260829574343560] | $5.2160427687771\times10^{-12}$ | $3.86031222574658415\times10^{-13}$ | 0.648689 | $2.6080213843886\times10^{-12}$ |
| `ex2-L2` | `3ff749f64edc3fa4` | [1.4555571632831174015135430, 1.4555571632859188354333414] | $8.1552944188614\times10^{-12}$ | $6.23450945472772564\times10^{-13}$ | 0.647860 | $4.0776472094307\times10^{-12}$ |

Further quantities (group bounds, trace constants, tail depths, band margins, $\|\mathsf P_+\|_2$ bounds) are in `reference/<example>/`; `reference/r2-summary.csv` collects the `ex2-L*` rows.

- **verify** on the canonical data, in the tested environment, must reproduce every printed defect bound, mass certificate, assembly value and band minimum exactly. Timings and the order of worker records are not compared.
- **reproduce** must give the same candidate bits, and the width and each group bound within 1% of the reference. This allows a new floating-point SVD fit to define a slightly different field.

## What verify checks

| Check | Implementation |
|---|---|
| Residual bounds | `src/python/residual/`: continuous defects of all five groups with analytic-domain, branch, positivity and remainder checks |
| Coverage and group sums | `audit_groups.py`: separate pass over all targets, partitions, finite sums and tails |
| Polynomial integration | Coefficient integration compared with independent Gauss integration, at least one target per group |
| Lead tails | Per side and kind operator envelopes, smallest accepted depth, contraction and $N+10$ overlap checks; for `ex2-L*` also the $p=2$ bound on the actual states |
| Mass | `src/python/mass/`: direct interior layer integration, geometric disk certificates and Bessel bounds |
| Trace constants | Two precision and initial-cover configurations, complete curvature covers and scalar extrema |
| Assembly | Ball arithmetic at two precisions compared with exact rational arithmetic |
| Common gap | Ball Rayleigh test and positive-subspace test, separate LDL* inertia checks (4 for `ex1`, 8 for `ex2-L*`), 472 and 944 phase-sign tests; a deliberately invalid threshold must be rejected |
| Two-sided traces (`ex1`) | `direct_traces.py`: exterior and interior traces formed separately with direct near-image and point-source sums, compared with the production interpolation models |

The two-sided trace check is an independent representation check that shares geometry, the Kress split formulas and the ball library with the main evaluation; it is not an independently developed library. For `ex1` it uses the analytic reflection and conjugation symmetry to cover the full phase range from half-phase tests; the `ex2-L*` examples, which have no such symmetry, test the full phase range directly.

## Scope and conditions

The interval refers to the binary64 target geometry and the exact saved field coefficients. Its reliability rests on the piecewise Helmholtz representation of the trial field, positive source separation, continuous densities, certified lead contraction and tails, the five defect certificates, disjoint interior mass disks, valid trace collars, and the common-gap certificate; all of these are checked by verify. Together they place a point-spectrum eigenvalue in the interval (Theorem 5.2 of the paper). The search and the B fit use ordinary floating point; all final bounds are recomputed in ball arithmetic. Only the five listed parameter sets and the tested dependency versions are supported; `scripts/validate_data.py` rejects other model or band inputs.

The mathematics is in Section 5 of the paper (trial field, grouped trace estimate, lead tails, spectral-distance theorem) and in the supplementary materials (rounding-inclusive evaluation). The package reads no manuscript file at run time.

## License

The code and data of this package are released under the MIT License (`LICENSE`; the copyright holder is a placeholder until publication). Third-party components keep their own licenses and are not bundled: MATLAB, FMM2D (Apache-2.0, `environment/FMM2D-LICENSE`), and the Python packages listed in `environment/`.

## Finite element comparison

The [finite element comparison](fem/README.md) supplies separate reproduce and verify entry points for example 1, using a finite element method (FEM), a Dirichlet-to-Neumann (DtN) map and a Lehmann–Goerisch flux. It computes the independent first-order spectral-intersection interval and the four-corner interval, and packages the band, half-line surface, DtN and core-count computations that establish the isolation hypothesis (H). The mesh comparison uses P3 fields and RT3 fluxes at h=1/24,1/36,1/48. Truncation errors are bounded by the original certificates; finite arithmetic rounding is only estimated, unlike the ball-arithmetic BIE certificates.

The two implementations differ by 2^-56 in one binary geometry Fourier coefficient. Containment of the BIE interval inside the FEM interval is therefore a numerical cross-check of these implementations. The FEM subtree needs MATLAB for both layers and does not need FMM2D. Its commands, canonical-data boundary, measured costs and verification results are in its own README. Its two large field/flux arrays (about 75 MB) are not tracked in Git; that README gives the regeneration command.
