# I7.1 mathematical symbol ledger

The authoritative formulas are in
`research/projects/eig-apost/implementation/i7/design-7-1a.md`; the direct
baseline is main commit `54eeb12b8223e6dcb6a5b91d3e2ccb3c12b564eb`.
Ordinary loop indices, file handles, timers, path strings, process-monitor
temporaries, and one-use formatting values are omitted.

| Canonical code name | Kind and scope | Source and mathematical meaning | Type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `beta` | model/result scalar | $\beta=0.5$, design section 2 | real, inverse length | `scan_i7` / `model`, `out` |
| `k` | point/result scalar | exterior wavenumber; design sections 2 and 5 | real, inverse length | scan grids / all constructors, `out` |
| `model.d`, `model.XL`, `model.XR` | model fields | period $d=1$ and walls $X_L=-0.5$, $X_R=0.5$ | real scalars, length | `scan_i7` / channels and scattering |
| `model.R`, `flag_geom` | lead geometry | circular lead radius $0.2$ and selector `circle` | real length, char | `scan_i7`, `LOCAL_cellsub` |
| `model.flag_geom`, `model.ellipse_axes` | center geometry | selector `ellipse` and semi-axes $(0.25,0.16)$ | char, real $1\times2$ length | `scan_i7` / `LOCAL_center` |
| `model.epsrel`, `kint` | lead material/derived scalar | circular-lead relative permittivity $17$ and $k_{\mathrm{int}}=\sqrt{17}k$ | real scalars | model / `LOCAL_cellsub` |
| `model.epsrel_center`, `kint` | center material/derived scalar | attempt 2 overrides the center permittivity to $2$, with $k_{\mathrm{int}}=\sqrt{2}k$ | real scalars | model / `LOCAL_center` |
| `model.H`, `model.pdist`, `mfscfg`, `proxy` | proxy data | frozen proxy box parameters and public precomputation | scalars/structs | model/config / `construct_S` |
| `coarse`, `final`, `cfg` | spatial configuration | coarse $(160,120,120,64,24)$ and final $(256,160,160,80,32)$ | scalar structs | entry / point constructors |
| `M`, `K` | channel orders | Rayleigh half-order and $K=2M+1$ | integers | scan layers / channels and QZ |
| `pars`, `chans` | package inputs | quasiperiodic parameters and Rayleigh channels | scalar structs | cell helpers / public packages |
| `C`, `curvelen` | contour data | public circle or ellipse samples and parameter length | real $6\times n_{\mathrm{tot}}$, scalar | `construct_cont` / `construct_S` |
| `cellmap.R_L`, `cellmap.T_RL`, `cellmap.T_LR`, `cellmap.R_R` | scattering blocks | $[b^L;a^R]=[R_L,T_{RL};T_{LR},R_R][a^L;b^R]$, design section 3 | complex $K\times K$ | `construct_S` / pencil and center matching |
| `A`, `B` | lead pencil | approved blocks from main `projgap`/`betagmode` | complex $2K\times2K$ | `LOCAL_cellsub` / `LOCAL_qzsub` |
| `alpha`, `theta`, `scale`, `an`, `tn` | projective QZ data | normalized homogeneous eigenvalue pairs | complex/real $2K$ columns | `LOCAL_qzsub` / classification |
| `indet`, `infinite`, `neutral`, `stable`, `unstable` | QZ masks | fail-closed projective classifications | logical $2K$ columns | `LOCAL_qzsub` / qualification and `ordqz` |
| `Zp`, `Zm`, `Zs` | subspaces | qualified right/left stable Schur bases | complex $2K\times K$ | `LOCAL_qzsub` / `LOCAL_dtn` |
| `bm`, `gamma`, `phase` | channel vectors | $\beta_m$, $\gamma_m$, and $e^{\mathrm{i}\gamma_mL}$ | complex $K$ columns | channels / weights and DtN |
| `Ap`, `Bp`, `Am`, `Bm`; `Dp`, `Np`, `Dm`, `Nm` | Cauchy blocks | amplitude blocks and half-guide Dirichlet/center-outward Neumann traces | complex $K\times K$ | `LOCAL_dtn` |
| `Lp`, `Lm` | DtN maps | $\Lambda_+$ and $\Lambda_-$, design section 3 | complex $K\times K$, inverse length | `LOCAL_dtn` / `Adef` |
| `G`, `E` | diagonal operators | $\operatorname{diag}(\gamma_m)$ and empty-cell phase diagonal | complex $K\times K$ | point/regression / matching matrices |
| `Adef` | defect matrix | four center-scattering blocks in design section 3 | complex $2K\times2K$ | `LOCAL_point` / SVD |
| `b`, `rowwt`, `ampwt`, `colwt` | physical weights | $b_m=\sqrt{1+|\beta_m|^2}$ and design-section-4 row/column weights | positive real $K$/$2K$ columns | `LOCAL_point` / `Aphys` |
| `Aphys` | weighted matrix | $D_rA_{\mathrm{def}}D_c$ with no overall normalization | complex $2K\times2K$ | `LOCAL_point` / SVD |
| `asig`, `arat`, `psig`, `prat` | point outputs | min singular values and min/max ratios of `Adef`/`Aphys` | nonnegative real scalars | `LOCAL_point` / record and `out` |
| `gap_k`, `gap_valid`, `gap_windows` | gap scan state | main `projgap` grid, classifications, and midpoint windows | real/logical rows, number of windows by 2 | stage 1 / later scan layers |
| `pilot_k`, `screen_k`, `candidate_k` | scan nodes | widest-gap midpoint, $0.025$ screen grid, and retained seeds | real rows/scalars | stages 1--3 / final cache |
| `cache.k`, `cache.record`, `level_trace`, `history` | audit state | unique final nodes/results, every level request, and actual evaluations | numeric/struct arrays | stages 1--4 / `scan.mat`, CSV |
| `valid`, `valid_index`, `best`, `repeat` | selection state | valid-only global final argmin and independent winner repeat | logical/index/record data | stage 4 / `out` and repeat gate |
| `out` | return artifact | seven scalar fields required by design section 7 | scalar struct | `scan_i7` / caller, `out.mat` |
| `h2d_evaluator` | optional package field | Scheme 2 hook for the proxy-source term; missing/empty preserves the public evaluator | scalar function handle | `qpgreen_mfs_pairmat` / I7 `pars` |
| `wavek`, `sources`, `charge`, `targ` | bounded-kernel inputs | unchanged public `kernel.h2d_directch` interface | scalar, $2\times n_s$, $1\times n_s$, $2\times n_t$ | QP hook / `LOCAL_h2d_chunked_public` |
| `target_batch`, `first`, `index` | batching state | contiguous groups of at most 512 target columns; sources and charges remain whole | integer scalar/range | `LOCAL_h2d_chunked_public` / public kernel calls |
| `pot`, `grad`, `hess` | bounded-kernel outputs | public potential, gradient, Hessian ordering, concatenated in original target order | complex $1\times n_t$, $2\times n_t$, $3\times n_t$ | local helper / QP assembly |
| `kernel_check` | regression result | public paths and direct/QP relative differences across a batch boundary | scalar struct | `LOCAL_kernel_check` / `scan`, checkpoint |

`asig`, `arat`, `psig`, and `prat` are permitted short local aliases for the
fully named `out` and history fields; they do not denote different objects.


## Local uniform locator

`locate_i7` uses the same model, final spatial configuration, matrix formulas,
and public target-batched kernel as `scan_i7`. Its local names are:

| Code name | Meaning | Type and scope |
|---|---|---|
| `kmin`, `dk`, `nk` | First node, positive grid spacing, number of points | Scalar inputs to `locate_i7` |
| `cfg`, `M` | Fixed final tuple $(256,160,160,80,32)$ and $M=48$ | Local constants |
| `k` | Uniform nodes `kmin+(0:nk-1)'*dk` | `nk`-by-1 column |
| `scan` | This call's `k`, `adef_sigma`, `adef_ratio`, `aphys_sigma`, `aphys_ratio` | Five-column table; distinct from the metadata struct in `scan_i7` |
| `out` | Same seven scalar fields; metrics at this call's minimum `aphys_ratio` | Scalar struct; `runtime` measures this call |

For a strict interior minimum, the nominal full interval between its two
neighbors is `2*dk`; reported widths use the stored endpoint difference. This
sampling scale is not an eigenvalue or minimizer error bound.

## Density-coordinate correction

The corrected cell solve follows `review-7-3a.md` section D.6. Here `A_raw`
means the unscaled BIE matrix and is distinct from the I7 matching matrix
`Aphys` above.

| Code name | Meaning | Type and scope |
|---|---|---|
| `far_aux.weights` | Physical trapezoid weights $w_j=h|z'(t_j)|$ | Positive real `ntot` column from `farfield_extractors` |
| `density_scale` | Diagonal of $D=\operatorname{diag}(\sqrt{[w;w]})$ | Positive real `2*ntot` column in `construct_S` and the diagnostic |
| `rhs_all`, `rhs_scaled` | Physical incident data $B$ and scaled data $DB$ | Complex `2*ntot`-by-`2*K` matrices |
| `H_scaled`, `H_all` | Scaled solution $\xi$ and physical density $\eta=D^{-1}\xi$ | Complex `2*ntot`-by-`2*K`; `H_L/H_R` remain physical |
| `A_raw` | Independent diagnostic reconstruction $D^{-1}A_sD$ | Complex `2*ntot` square matrix in `check_density_scaling` only |
| `density_independent` | Independent physical solve $-A_{\rm raw}^{-1}B$ | Complex `2*ntot`-by-`2*K` diagnostic matrix |
| `public_left`, `public_right` | Scattered outgoing Rayleigh coefficients $F_L\eta$ and $F_R\eta$ on the two walls | Complex `K`-by-`2*K` diagnostic matrices; direct phase is excluded |
| `Hmatch`, `Hsym`, `dH` | $A_{\rm def}T^{-1}$, its Hermitian part, and $\|H_{\rm match}-H_{\rm sym}\|_2$ | Complex `2*K` matrices and real diagnostic scalar |
| `validation_tolerance` | Frozen coordinate-comparison threshold $10^{-11}$ | Positive real scalar used by the before/after gates |
| `result.points` | Per-$k$ public/correct four metrics, $d_H$, sign-count diagnostic, coordinate defects, and timing | Struct array returned by `check_density_scaling` |
