# I8 symbol and variable ledger

## Scope

This ledger applies to `test/i8/flow-v1/`, `test/i8/locate-v1/`, `test/i8/check-v1/`,
`test/i8/estimate-v1/`, `test/i8/fmm-est-v1/`, `test/i8/pipeline-v1/`,
[[research/projects/eig-apost/implementation/i8/design-8-1a|I8.1]], and
[[research/projects/eig-apost/implementation/i8/design-8-1b|I8.1 local location]], and
[[research/projects/eig-apost/implementation/i8/design-8-2a|I8.2 fixed-point checks]], and
[[research/projects/eig-apost/implementation/i8/design-8-3a|I8.3 frozen-field estimate]], and
[[research/projects/eig-apost/implementation/i8/design-8-4a|I8.4 FMM location and fixed-field estimate]], and
[[research/projects/eig-apost/implementation/i8/design-8-4b|I8.4 independent direct/FMM pipelines]]. It maps the equal-area
star flow, its independent local locator, the five-configuration fixed-point checks, the fresh frozen-field
estimate, the independent FMM wide locator, and its newly authorized fixed-field evaluator comparison without changing the historical I6/I7 meanings. All `*_num`
quantities are ordinary numerical values unless an individual field explicitly says otherwise.

| Code name | Mathematical object | Meaning and shape | Defined / consumed |
|---|---|---|---|
| `beta` | $\beta$ | fixed quasiperiodic parameter $0.5$ | model / every stage |
| `k` | $k$ | current real scan or evaluation point | scan / point evaluator |
| `kmin`, `dk`, `nk` | $k_{\min},\Delta k,n_k$ | explicit first node, requested spacing and node count for one locator call | `locate_i8` input |
| `scan.k` | $(k_j)_{j=0}^{n_k-1}$ | actual binary64 grid; authoritative for span and spacing | locator output / manual next round |
| derived `full_span` | $W=k_{n_k-1}-k_0$ | actual completed-round width; a grid scale, not a position error | location ledger |
| derived `neighbor_width` | $w=k_{j+1}-k_{j-1}$ | actual full neighbor width at an interior winner | location ledger / next interval |
| `round_index`, `round_kind` | $r$, round type | zero-based round order and `wide`, `refine`, or endpoint-recovery role | I8.4a point and round ledgers |
| `node_index`, `evaluation_index` | node / execution order | index within an actual grid and stable global evaluation order | I8.4a point ledger / tie resolution |
| `valid` | successful-point flag | true only when the complete FMM point output and all four metrics are finite | I8.4a point ledger / cumulative selection |
| `outer_seconds`, `point_seconds` | measured wall times | launcher-side point wall time and evaluator-reported complete-point time | I8.4a point ledger / runtime account |
| `requested_step` | $\Delta k_{\rm req}$ | requested binary64 step used to generate one grid; not a substitute for actual spacings | I8.4a grid construction / round ledger |
| `actual_first_k`, `actual_last_k`, `actual_W` | $k_0,k_{n-1},W$ | actual first/last nodes and $W=k_{n-1}-k_0$ of a completed grid | I8.4a round ledger / width gate |
| `spacing`, `min_spacing`, `max_spacing` | $(h_i),\min h_i,\max h_i$ | full actual spacing vector $h_i=k_{i+1}-k_i$ and its extrema | I8.4a round ledger / grid audit |
| `winner_index`, `winner_k` | $j,k_j$ | wide-grid interior-dip winner or local-grid stable first minimum used for the next grid; only the wide winner may differ from the all-row round minimum | I8.4a round ledger / next grid |
| `left_k`, `right_k` | $k_{j-1},k_{j+1}$ | actual neighbors of an interior bracket winner | I8.4a round ledger / next grid |
| `left_gap`, `right_gap`, `neighbor_w` | $h_L,h_R,w$ | actual winner gaps and $w=h_L+h_R$ | I8.4a round ledger / grid scale |
| `round_best` | $b_r$ | stable first minimum `aphys_ratio` over every successful row in the current grid, including endpoints | I8.4a round ledger / diagnostics |
| `prior_cumulative_best`, `cumulative_best` | $c_{r-1},c_r$ | stable first minimum over all successful I8.4a evaluation rows through the indicated point; old I8.1 data are excluded | I8.4a round ledger / final candidate |
| `relative_improvement` | $I_r$ | $(c_{r-1}-c_r)/c_{r-1}$, with an explicit exact-zero branch | I8.4a platform ledger |
| `below_5pct`, `below_5pct_streak` | platform flags/count | strict $I_r<0.05$ flag and consecutive completed-transition count | I8.4a platform ledger |
| `platform_candidate`, `platform_confirmation` | platform state | three-transition candidate and the next-transition confirmation; records evidence and never stops the width refinement by itself | I8.4a platform ledger |
| `strict_dip` | local-dip flag | whether the bracket winner is strictly below its two actual neighbors | I8.4a round ledger / selection audit |
| `stop_reason` | terminal/status code | actual width, range, binary64, resource, or execution reason; platform is not substituted for a stop reason | I8.4a round ledger / audit |
| `selected.k` | $k_0$ | final valid baseline `aphys_ratio` argmin | scan / checks and raw field |
| `shoulders(1:2)` | $k_L,k_R$ | last valid neighbors of $k_0$ | scan / inertia |
| `halfwidth` | $h_k$ | I8.2 stage-local wavenumber halfwidth; initially $10^{-5}$, distinct from the I8.1 collar $h$ | fixed-point check input |
| `configs.id` = `B,N384,N512` | $B,N_{384},N_{512}$ | baseline and boundary-order ladder at $M=48$ | I8.2 points / comparisons |
| `configs.id` = `M56,M64` | $M_{56},M_{64}$ | Rayleigh-order ladder at `ntot=256` | I8.2 points / comparisons |
| exact binary64 input `k0` | $\widehat k_0$ | exact dyadic real represented by the frozen input double; I8.4 stage 2 uses literal `1.7562818500073423` | I8.3 / I8.4 stage-2 model convention |
| documented exact-real square | $\mu=\widehat k_0^2$ | mathematical spectral parameter; not a separately rounded code input | I8.3 interpretation |
| `mu_num` (`flow-v1`: `mu`) | $\mu_{\rm num}=\operatorname{fl}(k_0k_0)$ | ordinary-double scalar used in numerical T9/F14 formulas | raw result / `Cnum`, `Rnum` |
| `rho_center` | $\rho_c=2$ | center-star relative material coefficient | model / center cell |
| `rho_lead` | $\rho_\ell=17$ | lead-circle relative material coefficient | model / half-guides |
| `star_scale` | $s_*$ | $\sqrt{0.04/0.0618}$ applied to all six contour rows | geometry / center constructor |
| `C` | $C_*$ | equal-area star positions and first/second derivatives | center constructor / all actions |
| `curvelen` | $2\pi$ | contour-parameter interval length; not the geometric perimeter | boundary quadrature spacing |
| `speed` | $v$ | star parameter speed | geometry / weights and normal |
| `nx`, `ny` | $\nu$ | outward normal $(y',-x')/v$ | geometry / layer actions |
| `curvature` | $\kappa$ | signed star curvature | geometry diagnostic |
| `geometry.curvature_max` | $K_*$ | sampled $\max|\kappa|$ | geometry / `geometry.theta` |
| `collar_h` | $h$ | numerical collar half-width $0.004$ | geometry / `C_num` |
| `arc_band` | $b_{\rm arc}$ | numerical T12 diagonal-band arclength $0.01$ | geometry diagnostic |
| `geometry.theta` | $1-hK_*$ | sampled positive Jacobian margin | geometry / `Cnum` |
| `Nover` in `LOCAL_Cnum` | $N_{\rm ov}$ | sampled collar overlap count, fixed to one after geometry gates | geometry / `Cnum` |
| `cfg` | configuration | `ntot,nside,ntop,nproxy,mpw,M` | all matrix evaluations |
| `center_ntot`, `lead_ntot` | $n_c,n_\ell$ | independent center/lead boundary-node counts; I8.3 continuation uses $(512,256)$ | hybrid raw-field construction |
| `config.id = C512L256` | $(n_c,n_\ell)=(512,256)$ | continuation configuration with center and lead node counts kept explicit | result / audit |
| `cfgB`, `cfgN`, `cfgM` | $B,N,M_{\rm cfg}$ | baseline, boundary-axis and Rayleigh-axis configurations | stability stage |
| `K` | $2M+1$ | Rayleigh channel count per wall | config / matrices |
| `cellmap` | $R_L,T_{RL},T_{LR},R_R$ | center scattering blocks | center solve / matching |
| `H_L`, `H_R` | density maps | physical $[\tau;\zeta]$ maps, $\zeta=-\sigma$ | corrected `construct_S` / raw field |
| `q` | $[a^L;b^R]$ | incoming center amplitudes after column-weight recovery, then one common unit-norm/phase convention per frozen field | SVD / traces and raw field |
| `T` | $T$ | amplitude-to-physical-Dirichlet-trace map | matching / inertia and mode checks |
| `trace` | $d=Tq$ | physical left/right wall Fourier trace | mode identity |
| `Adef` | $A_{\rm def}$ | unweighted center/half-guide matching matrix | point evaluator |
| `rowwt`, `colwt` | $D_r,D_c$ | I7 physical matching weights | point evaluator |
| `Aphys` | $A_{\rm phys}$ | $D_rA_{\rm def}D_c$ | candidate score and mode |
| `adef_sigma` | $\sigma_{\min}(A_{\rm def})$ | unweighted smallest singular value | scan result |
| `adef_ratio` | singular-value ratio | $\sigma_{\min}/\sigma_{\max}$ of `Adef` | scan result |
| `aphys_sigma` | $\sigma_{\min}(A_{\rm phys})$ | weighted smallest singular value | scan result |
| `aphys_ratio` | singular-value ratio | $\sigma_{\min}/\sigma_{\max}$ of `Aphys`; selection score | scan result |
| `N0`, `L` | $N_0,L$ | independent center normal map and block DtN | inertia assembly |
| `H`, `Hsym` | $H,H_{\rm sym}$ | physical-trace right solve and Hermitian part | inertia count |
| `inertia.*.dH`, `inertia.*.scale` | $d_H,s_H$ | anti-Hermitian defect and Hermitian-part scale | inertia bands |
| `inertia.*.eta` | $\eta_c$ | count exclusion band; not a layer density | inertia count only |
| `comparisons.gap_a`, `comparisons.gap_b` | $g_H$ or $g_A$ | same-object nearest-$|\lambda|$ or smallest-singular-value competition gaps | I8.2 mode identity |
| `comparisons.delta_a`, `comparisons.delta_b` | $\delta_H$ or $\delta_A$ | same-object machine-scale near-degeneracy thresholds | I8.2 simple/cluster switch |
| `center_density` | $\eta_{n_c}=[\tau;\zeta]$ | fresh frozen center physical density for one invocation; continuation uses its own $n_c=512$ array | raw stage |
| `evaluation.material_nodes`, `evaluation.wall_nodes` | $N=512,768$ | evaluator grids applied to one frozen field; $N=512$ is native only for the continuation center-512 material action, while $N=768$ is the primary result | I8.3 material / walls |
| `levels.center_material_native` | native-grid flag | true only when $N=n_c$; it prevents a collocation residual from being presented as an independent evaluator check | I8.3 level result / audit |
| `node_ledger` | dimension ledger | actual center, lead, density, matching and port dimensions for the hybrid configuration | I8.3 result / audit |
| `evaluation.disk_grid` | $(16,32),(32,64)$ | coarse and half-angle-shifted fine safe-disk quadratures | I8.3 mass |
| `Gplus`, `Gminus` | $G_\pm$ | lead incoming-state maps | propagation / material and walls |
| `Pplus`, `Pminus` | $P_\pm$ | full lead propagation matrices | propagation / finite cells |
| `cplus`, `cminus` | $c_\pm$ | near-center lead stable coefficients | propagation / finite cells |
| `tail_*_candidate` | observed tail | finite geometric continuation from cell 41; not a bound | raw diagnostic |
| `components.value_squared`, `components.normal_squared` | $E_v,E_n$ | ordinary total value/normal jump squares | raw components / `epsilon_num` |
| `epsilon_num` | $\varepsilon_{\rm num}$ | ordinary boundary-defect formula value | raw components / final scalar |
| `mass.center`, `mass.radius` | $(0.375,0),0.0625$ | safe-disk geometry in center background | mass quadrature |
| `U_num` | $U_{\rm num}$ | fine same-field disk-mass quadrature square root | mass / final scalar |
| `Cnum` | $C_{\rm num}$ | T9 formula with sampled star geometry | geometry / final scalar |
| `Cnum*epsilon_num`; I8.4 `Q` | $Q_{\rm num}$ | $C_{\rm num}\varepsilon_{\rm num}$ | final scalar; `result.Q`, `levels.Q`, `direct.Q` in I8.4 stage 2 |
| `denominator` | $D_{\rm num}$ | $U_{\rm num}-Q_{\rm num}$ | finite-formula gate |
| `Rnum` | $R_{\rm num}$ | conditional F14 numerical value | final output; never certified |

The symbol $\eta$ without a suffix is reserved for physical layer density. `inertia.*.eta` is confined to the inertia
record and is never passed to a boundary operator. `cfgM` names the Rayleigh-axis configuration so that its `M`
field remains the cutoff. `Cnum`, `U_num`, `epsilon_num`, and `Rnum` must not be aliased to certified
overbar/underbar quantities.
The `(256,256)`, `(384,384)`, and continuation `(512,256)` invocations each normalize their own `q`; their
densities and component arrays must never be mixed or interpreted as samples of one shared frozen field. Only
the first and third hold `lead_ntot=256` fixed, and even that pair is a two-point sensitivity comparison rather
than a convergence sequence.


## I8.4 stage-2 evaluator ledger

These names apply only to `test/i8/fmm-est-v1/fmm_est_i8.m`; the completed search and historical
I8.3 files retain their own schemas. The source-field construction is FMM-assisted once, while both
postprocessing backends act on precisely the same stored field. No notation below denotes certification.

| Code name | Mathematical object | Meaning and shape | Defined / consumed |
|---|---|---|---|
| `result.fmm_eps` | $\varepsilon_{\rm fmm}$ | fixed request `1e-12`, not a matrix, jump, or spectral error bound | smooth-proxy callback / provenance |
| `cellmap.i8_pars.h2d_evaluator` | smooth-proxy evaluation rule | FMM for construction/main evaluation; copied cellmaps use direct for the fixed-field comparison | public pair matrix callback only |
| `direct_center`, `direct_lead` | same stored cell fields | copies with only the callback replaced; physical density maps, proxy coefficients and channels retained | direct evaluation / invariance audit |
| `result.levels(1:2)` | 512 / 768 numerical records | main FMM-assisted postprocessing, with 512 native center diagnostic and 768 primary result | complete jumps, disk mass and scalar assembly |
| `result.direct` | direct-proxy 768 numerical record | complete fixed-field direct material, wall, tail and fine-disk reevaluation; no new density solve | comparison / output |
| `evidence.direct.center_action`, `lead_action` | signed material raw actions | direct-proxy matrices and actions on the frozen density/interpolant | independent recomposition |
| `evidence.direct.lead_sum`, `wall` | full finite sums and tail candidates | left/right 40-cell material and internal-wall contributions plus interface walls and observed tails | independent component audit |
| `evidence.direct.center_maps`, `lead_maps` | direct wall evaluation maps | physical values and $x$ derivatives on the same 768 wall grid | wall recomposition |
| `evidence.direct.mass` | same-field disk samples | direct-proxy $32\times64$ half-angle-shifted samples and gradients on $B((3/8,0),1/16)$ | $U_{\rm num}$ and audit |
| `result.fixed_field.*_unchanged` | exact invariance flags | stored $q$, center density, cell maps and propagation remain equal across evaluation backends | no-resolve evidence |
| `result.comparison.*.absolute` | absolute difference | $\lvert x_{\rm fmm}-x_{\rm direct}\rvert$ for scalar totals and component records | sensitivity reporting |
| `result.comparison.*.relative` | relative difference | absolute difference divided by $\max(\lvert x_{\rm fmm}\rvert,\lvert x_{\rm direct}\rvert)$; both zero gives zero | sensitivity reporting alongside absolute scales |
| `result.proxy_calls` | callback ledger | `method,stage,ns,nt,batches,ier,seconds`; callback source/target counts are proxy-pair counts, not density node counts | coverage and timing audit |
| `result.batches` | fixed processing sizes | wall targets 64, mass targets 32, direct callback targets 512, FMM one call per callback | resource and reproducibility record |
| `pair_targets`, `result.singleton_target_handling` | singleton diagnostic handling | duplicate one physical target into two columns before the unchanged public pair routine, then retain the first result row; shared by FMM/direct, absent from multi-target mass quadrature | center-point cone diagnostic / operational repair record |
| `result.timing` | stage wall ledger | geometry, field, FMM jumps/mass/assembly-audit, direct jumps/mass/assembly-comparison, save | runtime description, not a historical speedup |

The direct comparator may recompute evaluation matrices, quadrature samples and tail ratios; it must not
recompute $q$, physical densities, propagation, Rayleigh coefficients or normalization. In particular,
`result.direct` is not a direct-constructed new field and cannot exclude FMM field-construction error.
The old and new candidate fields have distinct $k_0$ and independent normalizations; their saved arrays
must never be mixed. $Q_{\rm num}$ is retained because it is the explicit denominator subtraction term,
while certified upper/lower-bound notation remains excluded.

## I8.4 independent pipeline ledger

This section applies only to `test/i8/pipeline-v1/` and
[[research/projects/eig-apost/implementation/i8/design-8-4b|design-8-4b]]. The historical stage-2
`result.direct` above remains a same-field evaluator control. Here each backend owns its search,
candidate, fresh source field, normalization, and complete 768 evaluation. No array is shared between
the two backend results. Code field spelling below is the implementation interface freeze; runtime
verification and result-schema reconciliation are recorded in the new design after implementation.

| Code name / owner | Mathematical object | Meaning and scope |
|---|---|---|
| `pipeline_i8_config` | shared scientific configuration | Sole MATLAB constants source; common `model`, `discretization`, `evaluation`, `search`, `backend`, and `resources` settings; numerical entry locally calls `discretization` its `cfg` |
| `pipeline_i8_numeric(action,k0,backend)` | one backend numerical call | `point` constructs a complete new search point; `estimate` constructs one additional fresh field and evaluates its unique 768 level |
| `pipeline_i8_batch(request_path)` | explicit batch input transport | Serial launcher-supplied requests; does not choose scientific parameters from historical output or human documentation |
| `run_pipeline.py` | search and execution controller | Owns current-run search state, actual nodes, deterministic selection, process timing and resource monitoring |
| `requested_config`, `science_config` | explicit-input/configuration equality check | Launcher request and fresh MATLAB configuration, both excluding resource controls and JSON-normalized, must be equal before numerical execution |
| `actual_nodes` | actual binary64 batch nodes | Validated finite, strictly increasing, exact-distinct nodes; a refinement batch also checks the preceding selected point is interior and its node vector is not a repeated grid |
| `point_seconds`, `export_seconds` | point / export batch sums | Accumulators for evaluator-reported complete-point time and separate point/progress/aggregate JSON writing; exported as `search_point` and `save_export` |
| `environment` | observed execution environment | MATLAB version/release, computer, thread settings, and resolved numerical entry/public-package/FMM paths; does not identify the agent's runtime model |
| controller `--resume` | optional current-attempt continuation | May reuse only a verified completed batch whose request matches exactly; no old experiment inputs, deadline reset, or implicit claim that this option was used |
| `backend` | direct / FMM rule | Smooth-proxy callback selection only; all public singular quadrature, matching and raw-field formulas remain common |
| `cfg.ntot_center`, `cfg.ntot_lead` | $n_c=512,n_\ell=256$ | Fixed from the first wide-search point through the additional final field |
| `model.L` in geometry `lead_gap` | longitudinal neighbor-center translation | Frozen $L=1=X_R-X_L$; the same star-to-circle clearance uses centers $(\pm L,0)$, while `model.d` is the transverse $y$ period |
| `evaluation.material_nodes`, `evaluation.wall_nodes` | $N=768$ | Exactly one postprocessing layer per independent field, non-native for both source orders |
| `evaluation.disk_grid`, `evaluation.disk_shift` | $(32,64),1/2$ | Unique safe-disk quadrature; no coarse layer or third field/evaluator comparison |
| per-backend cumulative candidate | $k_{*,\rm direct},k_{*,\rm fmm}$ | First executed row attaining the exact minimum ratio among all that backend's successful new samples, including endpoints and recovery |
| per-backend final-round winner | final bracket center | Stable-first round winner used for the final interior-width gate; may differ from the formal cumulative candidate |
| `actual_W` | $W$ | Actual last-minus-first binary64 node of a complete valid 11-point round; successful stopping also requires an interior winner |
| per-backend search count | $N_{\rm direct},N_{\rm fmm}$ | Actual complete-point search invocation counts; allowed to differ and never replaced by a common assumed count |
| final fresh-field count | one per backend | Additional complete construction at that backend's cumulative candidate, charged separately from search |
| fresh `q`, density and propagation arrays | independent source fields | Each backend uses one consistent normalization and phase throughout its own jump, trace, mass and observed-tail computations |
| `mu_num` | $\operatorname{fl}(k_*k_*)$ | Backend-specific rounded square; not the exact-real square or a shared scalar |
| `Cnum`, `epsilon_num`, `U_num`, `Q`, `denominator`, `Rnum` | $C_{\rm num},\varepsilon_{\rm num},U_{\rm num},Q_{\rm num},D_{\rm num},R_{\rm num}$ | Same I8.3 scalar formulas, separately recomputed from each backend's own source field and candidate |
| main timing ledger | disjoint stage wall times | Search calls, search controller, extra field, jumps, mass, geometry/assembly/audit, saving, process startup/shutdown and orchestration |
| callback timing ledger | nested diagnostic wall times | Smooth-proxy call time and counts are already inside their owning numerical stages and are not added again |
| full pipeline wall time | total measured backend cost | Includes all backend batches, required saves and startup/shutdown; differs from pure numerical stage sum |
| `summarize_pipeline.py` | current-attempt postprocessing | Reads the two completed pipeline results and exports `summary.json/csv`, `rounds.csv`, `components.csv`, and `callbacks.csv` into the supplied run directory by default; launches no numerical solves |
| `candidate_*`, `fresh_*` | four matching metrics at two call sites | Search-candidate row and the independently rebuilt final-field point; both contain `adef_sigma`, `adef_ratio`, `aphys_sigma`, `aphys_ratio` |
| `candidate_round/evaluation_index/node`, `final_winner_round/evaluation_index/node` | provenance indices | Separate first cumulative-minimum row and final-round selected row; allow the reported formal candidate to be traced to an actual evaluation |
| `search_point_min/median/max` | measured point-duration summary | Distribution of complete per-point calls within each backend; actual point counts remain separate |
| `unclassified_process_overhead` | monitored residual process time | Successful process wall minus disjoint numerical timers and explicitly timed saves; includes startup/shutdown/preflight/cleanup/wrapper work without claiming a finer measured split |
| `stage_speedups` | direct/FMM stage-time ratios | Descriptive ratios for this sequential run, not profiler fractions or universal acceleration factors |
| `successful_process_speedup`, `elapsed_pipeline_speedup` | direct/FMM total-time ratios | Respectively use summed successful process walls and measured backend pipeline elapsed time; callback subsets are never added |
| `setup_wall`, `failed_wall`, `launcher_wall` | shared setup, failures, and full controller cost | Common configuration export and operational failures are disclosed separately from successful backend ratios; launcher time includes both backend executions |
| summary/component `relative_to_direct` | $\lvert x_{\rm fmm}-x_{\rm direct}\rvert/\lvert x_{\rm direct}\rvert$ | Descriptive reference-relative difference alongside signed and absolute differences; both zero gives zero, zero direct with nonzero FMM is undefined |

The only new mathematical subscripts identify backend ownership and actual work counts. They do not
introduce a new estimator or notation for certified bounds. `LOCAL_*` numerical helper names copied
from `fmm_est_i8.m` retain the source meanings within the new function file; its two-level audit is
adapted to the single 768 layer, and refinement/comparison helpers are excluded. A successful finite
formula remains `UNCERTIFIED_RNUM` with `certified=false`. Differences between independent pipeline
results conflate candidate changes and field-construction/evaluator changes; they do not isolate
FMM kernel error.

## I8.5 two-resolution multidip search ledger

This section applies only to `test/i8/scan-v1/` and
[[research/projects/eig-apost/implementation/i8/design-8-5a|design-8-5a]]. No spectral-distance
quantity is evaluated in this experiment. Historical I8.4 candidate and field schemas remain unchanged.

| Code name / responsibility | Mathematical object | Meaning and scope |
|---|---|---|
| `scan_i8_config()` | one scientific configuration | Sole source for shared model, auxiliary parameters, two resolutions, search rules and FMM request |
| `resolution_id` | coarse / fine spatial order | Coarse means center/lead $(256,128)$; fine means $(512,256)$; independent of the refinement `round` |
| `scan_i8_point(k,resolution_id,config)` | complete finite matching evaluation | Computes four metrics and status without choosing grids, branches or stopping conditions |
| `scan_i8_search(output_dir,mode)` | current-run manager | Owns grid scheduling, interval lineage, refinement, successful-point cache and terminal records |
| `point_id`, `k_hex` | point identity / binary64 input | Stable current-run identifier and exact `num2hex(k)` encoding; no decimal rounding for cache identity |
| scientific config + resolution + `k_hex` | cache identity | Same successful point can serve overlapping branches; coarse and fine values never share an entry |
| `source_ids`, `parent_id` | search lineage | Every coarse dip or pending region retains all descendant or terminal destinations |
| `interval.pending_groups` | internal dips observed during expansion | Stores bounds, exact anchor IDs, source history and destination; same anchors can refer to the current group, otherwise a recovery child preserves the observation |
| `edge_records`, `pending_edge_count` | unresolved edge trends | A nonwinning descending endpoint stays `NONWINNING_EDGE_PENDING`; it is never silently called covered by its parent |
| `round` | local refinement iteration | Not a spatial order; each full fine grid has eleven actual nodes |
| raw minima / saddle / prominence | finite-grid dip evidence | Every strict minimum and exact plateau is retained before numerical ambiguity grouping |
| `ambiguity` threshold | $\tau=64\,\mathrm{eps}\max(1,\max_j|y_j|)$ | Fine-branch proliferation guard only; not an error bound, a coarse-dip filter or a stopping threshold |
| ambiguity cluster | unresolved neighboring minima | All constituent extrema and saddles remain recorded; next window covers the whole cluster with outer neighbors |
| actual whole-round width | $W=k_{11}-k_1$ | Completion requires a full valid fine round, $W\le2\times10^{-14}$ and an interior winner |
| winner neighbor width | $w=k_{j+1}-k_{j-1}$ | Distinct from $W$ and requested step; uses actual binary64 neighbors |
| formal candidate | final-round first argmin | First minimum `aphys_ratio` in a normally completed fine round; it has recorded two-sided grid support |
| cumulative fine best | first supported all-history argmin | Separate diagnostic that may differ from the formal candidate; never substitutes for the width gate |
| cache bypass confirmation | fresh complete fine point | Recomputes each terminal fine best/candidate and records four absolute/relative differences without overwriting the cached record |
| requested / new / hit / bypass counts | scheduling workload | Request references, actual missing-point calls, successful cache reuses and fresh confirmation calls are reported separately |
| `checkpoint.mat` | current-run evidence | Saved state only; this implementation has no resume input and regenerates all points from an empty output directory |

All four singular-value metrics keep the earlier I8 definitions. Neither a small score nor a small final
window certifies a continuous eigenvalue, uniqueness, full-window coverage or a spectral-distance bound.
