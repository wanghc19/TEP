# I8 symbol and variable ledger

## Scope

This ledger applies to `test/i8/flow-v1/`, `test/i8/locate-v1/`, `test/i8/check-v1/`,
`test/i8/estimate-v1/`,
[[research/projects/eig-apost/implementation/i8/design-8-1a|I8.1]], and
[[research/projects/eig-apost/implementation/i8/design-8-1b|I8.1 local location]], and
[[research/projects/eig-apost/implementation/i8/design-8-2a|I8.2 fixed-point checks]], and
[[research/projects/eig-apost/implementation/i8/design-8-3a|I8.3 frozen-field estimate]]. It maps the equal-area
star flow, its independent local locator, the five-configuration fixed-point checks, and the fresh frozen-field
estimate without changing the historical I6/I7 meanings. All `*_num` quantities are ordinary numerical values
unless an individual field explicitly says otherwise.

| Code name | Mathematical object | Meaning and shape | Defined / consumed |
|---|---|---|---|
| `beta` | $\beta$ | fixed quasiperiodic parameter $0.5$ | model / every stage |
| `k` | $k$ | current real scan or evaluation point | scan / point evaluator |
| `kmin`, `dk`, `nk` | $k_{\min},\Delta k,n_k$ | explicit first node, requested spacing and node count for one locator call | `locate_i8` input |
| `scan.k` | $(k_j)_{j=0}^{n_k-1}$ | actual binary64 grid; authoritative for span and spacing | locator output / manual next round |
| derived `full_span` | $W=k_{n_k-1}-k_0$ | actual completed-round width; a grid scale, not a position error | location ledger |
| derived `neighbor_width` | $w=k_{j+1}-k_{j-1}$ | actual full neighbor width at an interior winner | location ledger / next interval |
| `selected.k` | $k_0$ | final valid baseline `aphys_ratio` argmin | scan / checks and raw field |
| `shoulders(1:2)` | $k_L,k_R$ | last valid neighbors of $k_0$ | scan / inertia |
| `halfwidth` | $h_k$ | I8.2 stage-local wavenumber halfwidth; initially $10^{-5}$, distinct from the I8.1 collar $h$ | fixed-point check input |
| `configs.id` = `B,N384,N512` | $B,N_{384},N_{512}$ | baseline and boundary-order ladder at $M=48$ | I8.2 points / comparisons |
| `configs.id` = `M56,M64` | $M_{56},M_{64}$ | Rayleigh-order ladder at `ntot=256` | I8.2 points / comparisons |
| exact binary64 input `k0` | $\widehat k_0$ | exact dyadic real represented by the frozen input double | I8.3 model convention |
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
| `Cnum*epsilon_num` | $Q_{\rm num}$ | $C_{\rm num}\varepsilon_{\rm num}$ | final scalar; left expanded in code |
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
