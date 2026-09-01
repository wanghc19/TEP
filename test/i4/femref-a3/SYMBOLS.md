# I4.1c code-symbol ledger

This ledger maps every persistent or cross-function name in the active I4.1c
implementation to `design-4-1c.md`. Obvious loop indices and single-expression
temporaries are omitted. All defining and consuming code is in
`run_i4_1c_core.m` unless a controller is named explicitly.

## Continuous model and schedules

| Canonical code name | Kind and scope | Design symbol/source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `spec` | immutable structure | Sections 2, 10, 12, 23 | Complete frozen model, numerical tolerances, schedules, and claim boundary | `LOCAL_spec` / all scientific stages |
| `period` | `spec` scalar | Section 2, $L=1$ | Vertical period; real scalar, length | `LOCAL_spec` / geometry and periodic maps |
| `radius` | `spec` scalar | Section 2, $r=0.2$ | Inclusion radius; real scalar, length | geometry construction and validation |
| `q_inside`, `q_outside` | `spec` scalars | Section 2, $q=17,1$ | Piecewise weighted-mass coefficient; dimensionless | curved assembly |
| `missing_column` | `spec` integer | Section 2 | Removed defect inclusion column | mesh generation |
| `beta` | `spec` scalar | Section 2, $\beta=0.5$ | Vertical quasiperiodic phase; radians | phase prolongation and seam checks |
| `theta_5`, `theta_9`, `theta_9_added` | `spec` row vectors | Sections 10, 23 | Frozen branch/twist phases; radians | formal solve and twist refinement |
| `bulk_alpha_17` | `spec` row vector | Section 23 | Frozen bulk diagnostic phases; radians | bulk continuation |
| `defect_nev`, `expanded_nev`, `bulk_nev` | `spec` integers | Section 23.4 | Requested Ritz roots, respectively 48, 60, 40 | eigensolver schedule |
| `quadrature_orders` | `spec` row vector | Sections 5, 23 | Duffy orders $Q=4,6,8$ | representation validation and assembly |
| `preliminary_quadrature_order`, `final_quadrature_order` | `spec` integers | Sections 5.3, 23.3 | Q6 preliminary and independent Q8 final authority | formal orchestration |
| `core_grid_x`, `core_grid_y` | `spec` row vectors | Section 8.4 | Frozen common-grid physical coordinates; length | nonlinear field locator |
| `inverse_tolerance`, `inverse_max_iterations`, `inverse_line_search_steps` | `spec` scalars | Section 8.4 | Nonlinear inverse-map acceptance and iteration controls | `LOCAL_inverse_map` |
| `tight_tolerance`, `loose_tolerance`, `bulk_tolerance` | `spec` scalars | Sections 10, 12 | Relative eigensolver tolerances | eigensolve and algebraic axis |
| `residual_tolerance`, `orthogonality_tolerance`, `imaginary_tolerance` | `spec` scalars | Sections 7, 10 | Numerical eigenpair validity thresholds | spectrum validation |
| `simple_overlap_min`, `cluster_overlap_min`, `parity_threshold` | `spec` scalars | Section 10 | FEM-only tracking and classification thresholds | branch assignment and ranking |
| `planned_solves`, `maximum_solves` | `state` integers | Section 23.4 | Exact formal call graph, 71 normally and 76 after one extension | formal terminal artifact |

## Mesh, geometry, and element forms

| Canonical code name | Kind and scope | Design symbol/source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `item` | mesh specification | Section 12 | ID, kind, supercell half-width `N`, mesh scale `s`, interface segments `n_gamma`, and `quadrature_order` | `LOCAL_named_mesh` / mesh builder |
| `points` | mesh array | Section 4 | P1 vertex coordinates; real $n_v\times2$, length | generator / curved topology |
| `triangles` | mesh array | Section 4 | Counterclockwise P1 connectivity; integer $n_T\times3$ | generator / topology and assembly |
| `edges` | topology array | Section 4.2 | Sorted global vertex pairs; integer $n_e\times2$ | shared midpoint DOFs and seam maps |
| `interface_edges` | logical vector | Section 4.2 | Edges whose endpoints lie on the same true circular interface | arc midpoint construction and validation |
| `interface_centers` | geometry array | Section 4.2 | Associated disk center per interface edge; real $n_e\times2$, length | arc midpoint construction |
| `p2_points` | mesh array | Sections 3, 4 | Vertex plus globally shared midpoint coordinates; real $(n_v+n_e)\times2$, length | assembly, phase, and field reconstruction |
| `triangle_p2` | mesh array | Sections 3, 4 | Six-node P2 connectivity; integer $n_T\times6$ | all element calculations |
| `nodes` | element array | Section 4.1, $X_a$ | One curved element's six physical nodes; real $6\times2$, length | map, Jacobian, forms, inverse map |
| `barycentric`, `coordinates` | reference coordinates | Sections 3, 8.4 | $(\ell_1,\ell_2,\ell_3)$ or $(\xi,\eta)$; real row vector | P2 basis and nonlinear inverse map |
| `basis`, `gradients_reference` | element arrays | Section 3, $N_a,\widehat\nabla N_a$ | P2 values $6\times1$ and gradients $2\times6$ | curved mapping and assembly |
| `physical`, `jacobian`, `determinant` | map objects | Section 4.1, $F_T,J_T,\det J_T$ | Physical point, $2\times2$ Jacobian, and signed area scale | `LOCAL_map_at`, assembly, inverse map |
| `map_coefficients` | element structure | Section 4.3 | Quadratic coefficients of $x(\xi,\eta),y(\xi,\eta)$ | determinant proof and diagnostics |
| `determinant_coefficients` | element row vector | Section 4.3 | Six coefficients of quadratic $d_T(\xi,\eta)$ | exhaustive global determinant minimum |
| `determinant_minimum` | scalar | Section 4.3, $d_{T,\min}$ | Exact candidate minimum over reference triangle; signed area scale | mapping acceptance |
| `determinant_tolerance` | scalar | Section 4.3, $\tau_{\det,T}$ | Scale-aware positivity tolerance | mapping acceptance |
| `bernstein_controls`, `bernstein_boxes` | arrays | Section 8.4 | Conservative degree-two convex-hull boxes per element | common-grid candidate search |
| `quadrature_points`, `quadrature_weights` | arrays | Section 5 | Tensor Duffy nodes and weights on reference triangle; weights sum to $1/2$ | element assembly and validation |
| `stiffness_full`, `mass_full` | sparse matrices | Sections 2, 5, $K_h,M_h$ | Unreduced P2 Hermitian forms; complex sparse $n_2\times n_2$ | phase reduction/eigensolve |
| `p1_stiffness_full`, `p1_mass_full` | sparse matrices | Section 6 | Same-curved-map reference-linear forms | global P1-in-P2 identity |
| `mass_center`, `mass_core`, `mass_tail` | sparse matrices | Sections 9, 10 | Restricted weighted-mass forms for localization diagnostics | mode objects and ranking |
| `geometry_validation`, `mapping_validation`, `quadrature_validation` | immutable structures | Sections 4--6 | Endpoint/midpoint/trace/loop, determinant, and Q4/Q6/Q8 evidence | preflight and canonical artifacts |

## Phase, eigenpairs, and fields

| Canonical code name | Kind and scope | Design symbol/source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `periodic` | topology structure | Section 7 | Vertex/midpoint master indices, seam node pairs, and coordinate defects | phase prolongation and seam validation |
| `prolongation`, `phases` | sparse matrix / vector | Section 7, $P_{\vartheta,\beta}$ | Full-to-master quasiperiodic map and unit phase factors | reduced operators and eigenfunctions |
| `pair.stiffness`, `pair.mass` | sparse matrices | Section 7 | Phase-reduced $K_{\vartheta},M_{\vartheta}$ | Cholesky check and `eigs` |
| `phase_x` | scalar | Section 7, $\vartheta$ | Current horizontal twist; radians | one slice solve |
| `eigenvalues`, `frequencies` | column vectors | Section 2, $\lambda_j,k_j=\sqrt{\lambda_j}$ | Ordered Ritz values and wavenumbers | spectrum inventory and ranking |
| `vectors`, `vectors_full` | matrices | Sections 7, 9 | Mass-normalized reduced and full P2 eigenvectors | residuals, fields, overlaps |
| `residuals` | column vector | Section 10 | Normalized generalized-eigenpair residuals | numerical validity and ranking |
| `cluster_ids` | integer vector | Section 10 | Frozen numerical multiplicity grouping | subspace tracking |
| `locator` | field-map structure | Section 8.4 | Common-grid owning triangle, nonlinear coordinates, weights, and reflection map | every P2 field/subspace sample |
| `field_locator` | mesh field | Section 8.4 | Cached nonlinear locator for defect meshes | `LOCAL_sample_subspace` |
| `triangle_index`, `barycentric` | locator arrays | Section 8.4 | Deterministically selected element and inverse coordinates per physical query | P2 reconstruction |
| `common_core_samples`, `common_core_weights` | object arrays | Sections 8--10 | Physical P2 field samples and exact-$q$ quadrature weights | cross-mesh/subspace overlap |
| `parity_grid` | integer map | Section 10 | Reflection partner index on the common grid | parity classification |
| `objects`, `entries`, `slices` | current-run structures | Sections 9, 10 | Field-bearing spectral objects, slice spectra, and per-phase inventory | branch continuation and selection |
| `selection`, `tracking` | current-run structures | Section 10 | Independently ranked branch and continuation graph | preliminary/final publication |
| `lambda_pre`, `k_pre` | scalars | Section 23.3 | Create-once Q6 preliminary empirical reference | preliminary artifact and fallback terminal |
| `lambda_ref`, `k_ref` | scalars | Sections 10, 23.3 | Create-once Q8 curved-P2 empirical reference | final/refinement/terminal artifacts |
| `scalars` | refinement structure | Section 12 | Matched $h,g,N,\vartheta,Q,$ and tolerance axis values | observed-resolution calculation |
| `Delta_ref_obs` | scalar | Section 12, $\Delta_{\mathrm{ref}}^{\mathrm{obs}}$ | Sum of available observed axis differences; not an error bound | refinement artifact only |

## Lifecycle and artifact names

| Canonical code name | Kind and scope | Design symbol/source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `run_id`, `execution_id` | immutable text | Section 23.2 and bounded retry record | Exact create-once identity pair; preflight `execution-001` and `execution-002` are preserved and active preflight uses `execution-003`, while formal uses `execution-001` | core entry and both controllers |
| `artifact-review-001/execution-001` | immutable review identity | Post-run artifact review | Create-once read-only inspection of the six current formal MAT leaves and text authority | `run_artifact_review.pl` / `inspect_i4_1c_artifacts.m` |
| `preliminary`, `final`, `refinement` | inspector structures | Sections 8--13 artifact leaves | Read-only loaded current-run result authorities | `inspect_i4_1c_artifacts.m` only |
| `preliminary_fields`, `final_fields`, `refinement_fields` | inspector structures | Sections 8--13 field leaves | Read-only selected subspaces, common-grid samples, and matched axes | `inspect_i4_1c_artifacts.m` only |
| `caveats` | inspector cell array | Section 13.1 schema contract | Missing duplicated metadata reported without altering scientific artifacts | `inspect_i4_1c_artifacts.m` only |
| `output_dir`, `work_dir` | relative paths | Sections 19, 23 | Claimed execution directory and private atomic-publication staging directory | core and controllers |
| `state` | lifecycle structure | Sections 17, 23 | Attempted/completed solve counts and local failure evidence | formal orchestration and terminal |
| `DEADLINE_EPOCH` | controller integer | Section 13 | Lifecycle hard deadline 1788280898; Unix seconds | both Perl controllers |
| `RSS_LIMIT_BYTES` | controller integer | Section 13 | Aggregate process-tree hard limit 3,221,225,472 bytes | both Perl controllers |
| `remaining`, `monotonic_deadline` | controller scalars | Section 13 | $\min(T_{\mathrm{run}}+2700,T_{\mathrm{end}})$ enforcement | both Perl controllers |
| `peak_rss`, `stage_peak` | controller state | Section 13 | Whole-tree and marker-resolved measured RSS; bytes | `resource.tsv` publication |
| `terminal`, `claim` | immutable text | Sections 17, 20 | Scientific state and non-certified claim boundary | terminal and summary leaves |

No alias permits a P1 affine point locator, a straight-edge P2 midpoint on a
material interface, BIE/QZ data, estimator data, or historical reference output
to enter the curved-P2 authority path.
