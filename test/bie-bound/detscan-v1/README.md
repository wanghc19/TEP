# detscan-v1: Fredholm determinant scan version 1

BIE = boundary integral equation; DtN = Dirichlet-to-Neumann; LU = lower–upper factorization; QZ = generalized Schur factorization; FMM = fast multipole method; RSS = resident set size; I9 is the inherited experiment identifier. The finite matrix determinant is used as a floating search function.

Purpose: compare nested Chebyshev determinant interpolation with the I9 singular-value scan. Read-only physics is supplied by an explicit search path. No density or matrix outputs are retained. Numerical inputs are explicit source settings; no documents, old outputs, or metadata are read at runtime.

Prelaunch estimate for bracket: 33 nested nodes, 3 off-grid points, at most 4 polish calls and 2 fresh comparison calls; 2–4 minutes, peak 1.8 GiB, five threads. The complete search result shares a 30-minute soft / 40-minute hard scientific budget across the bracket and window processes. Window estimate will be added after the bracket.

Results: bracket degree 16 / window degree 64 reach a relative coefficient plateau around 1e-14. The window returns one near-real root; real-axis polish gives 1.5584378941820887, 2.22e-15 below I9. The window uses 71 evaluations (65 interpolation, 3 off-grid, 3 polish), 222.42 seconds science, 236.09 seconds process, peak 1.05806 GiB. The bracket diagnostic uses 37 cached evaluations plus 2 fresh comparison calls, 121.70 seconds science, 138.59 seconds process, peak 1.08449 GiB. Together: 374.68 seconds process. Original I9 search: 213 calls, 548.12 seconds science.

Checks: LU versus singular-value log modulus agrees within 4.55e-13; fixed row/column determinant scaling agrees within 2.56e-13 in log modulus and 9.77e-15 in phase. Window off-grid error is at most 1.75e-13 of the nodal amplitude. Untrimmed NumPy and trimmed MATLAB colleague roots agree to 1.19e-14 and have the same single root in Bernstein ellipse rho < 1.1. Minimum rcond of positive/negative DtN denominators over both runs: 0.0897127 / 0.0380306. These are numerical sampled checks.

Recommendation: replace the coarse/fine search with adaptive determinant interpolation, keeping sigma_min at accepted roots and as a fallback for poor coefficient decay, ill-conditioned DtN denominators, or failed off-grid checks. The prototype retains every original singular-value computation, so its measured improvement comes from fewer calls. Two original complete fine evaluations at five threads take 3.11330 and 3.18408 seconds.

Reproduction (use fresh numbered output directories):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/detscan-v1/launch.py \
  --output /Users/whc/Documents/Work/dot-research/test/bie-bound/detscan-v1/output/run-003 \
  --package-root /Users/whc/Documents/Work/dot-research \
  --search-path /Users/whc/Documents/Work/dot-research/test/i9/search-v1 \
  --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab --mode bracket
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/detscan-v1/launch.py \
  --output /Users/whc/Documents/Work/dot-research/test/bie-bound/detscan-v1/output/run-004 \
  --package-root /Users/whc/Documents/Work/dot-research \
  --search-path /Users/whc/Documents/Work/dot-research/test/i9/search-v1 \
  --fmm-root /Users/whc/Documents/Work/epost/test/i8/fmm-v1/vendor/fmm2d/matlab --mode window
PYTHONDONTWRITEBYTECODE=1 python3 test/bie-bound/detscan-v1/analyze.py \
  test/bie-bound/detscan-v1/output/run-003 test/bie-bound/detscan-v1/output/run-004
PYTHONDONTWRITEBYTECODE=1 conda run -n octave python -I test/bie-bound/detscan-v1/audit.py \
  test/bie-bound/detscan-v1/output/run-003 test/bie-bound/detscan-v1/output/run-004
```

Run-001 retained the bracket source in its inputs directory. It reused points within four ulps, including sub-ulp polish updates; the window and current entry point use exact-k cache equality and stop identical updates. Thus a fresh bracket rerun may use a few extra polish evaluations. Root reproduction tolerance is 2e-13; coefficient plateaus and timing may vary with concurrent load. The run-specific MATLAB source is retained under each run's inputs directory. No historical outputs are runtime prerequisites.

The local Zhao2015 PDF is the arXiv:1406.5252v3 preprint; section 5 on pages 10–11 describes degree doubling and a Laurent companion matrix. Here a Chebyshev colleague matrix gives the same interpolant roots. The read-only source is catalogued as Zhao–Barnett, SIAM Journal on Numerical Analysis 53(4), 1984–2007 (2015), DOI 10.1137/140973992.

Bracket progress gives about 3.11 seconds per leads-plus-match call and 16-degree coefficients near 1e-14. Prelaunch estimate for the window: 65 global nested nodes plus 3 off-grid checks, about 215 seconds. If the global fit has not converged or spans more than 18 log units, use four panels up to degree 64: worst case about 335 calls, 18 minutes, peak 1.8 GiB. Including the bracket remains below the shared 30-minute soft budget. This extra range criterion protects root extraction when the determinant has a large dynamic range.
