# I4.1a symbol and code-variable ledger

Scope: `test/i4/femref-a1/run_i4_1a.m` only.  This ledger extends, but does not
modify, the project ledger at
`research/projects/eig-apost/implementation/SYMBOL.md`.  Exact source locators
refer to `design-4-1a.md` unless stated otherwise.

## Physical and discretization objects

| Canonical code name | Kind and scope | Draft symbol / source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `spec` | immutable struct, run-wide | Sections 2--12 and 15.2 | Complete source-owned physical, numerical, gate, schema, and budget specification | `LOCAL_spec`; all stages |
| `spec.period` | real scalar | ordinary-cell period, Section 2 | Period $1$, length unit | `LOCAL_spec`; mesh builders |
| `spec.radius` | real scalar | $R$, Section 2 | Exact disk radius $0.2$, length unit | `LOCAL_spec`; mesh/model checks |
| `spec.q_inside` | real scalar | $q_{\mathrm{in}}$, Sections 2, 8.1 | Disk mass coefficient $17$ | `LOCAL_spec`; `LOCAL_assemble_p1` |
| `spec.q_outside` | real scalar | $q_{\mathrm{out}}$, Sections 2, 8.1 | Background mass coefficient $1$ | same |
| `spec.beta` | real scalar | $\beta$, Sections 2, 3.3 | Transverse quasiperiodic phase $0.5$, radians | `LOCAL_spec`; `LOCAL_phase_reduce` |
| `spec.cue_interval` | real $1\times2$ | $I_{\mathrm{cue}}$, Section 4.1 | Frozen broad gap-identification cue $[1.65,2.05]$, frequency | `LOCAL_spec`; bulk gap gate |
| `spec.guard_interval` | real $1\times2$ | $I_{\mathrm{guard}}$, Section 4.1 | Solver/gap guard $[1.25,2.45]$, frequency | same |
| `spec.parity_threshold` | real scalar | parity ambiguity threshold, Section 5.3 | Frozen absolute compressed-parity cutoff $0.80$ | `LOCAL_spec`; `LOCAL_gap_clusters`; branch signatures |
| `mesh_spec` | struct, one mesh level | Sections 3.1--3.2, 5.2 | `kind`, supercell half-width `N`, subdivisions `s`, polygon segments `n_gamma`, and stable ID | mesh schedule; mesh builder |
| `mesh` | struct, one mesh | $\Omega_N$ and fitted $P_1$ mesh, Sections 3.1--3.2 | nodes `points` ($n\times2$), triangles `triangles` ($n_T\times3$), material labels, constraints, periodic/reflection maps, region masses, full sparse forms | `LOCAL_build_mesh`; solve/label stages |
| `reflection_index` | integer vector, one mesh | node involution $\rho$, Section 15.3 | Unique node index induced by $(x,y)\mapsto(-x,y)$ | `LOCAL_reflection_map`; connectivity repair, material-pair and matrix oracles |
| `original_triangles` | integer $n_T\times3$ | constrained-Delaunay connectivity before tie resolution, Section 15.3 | Connectivity returned on the frozen points and constraint multiset; retained only as repair input | `LOCAL_reflection_closed_triangles` |
| `paired_original` | logical vector | Section 15.3 tie-resolution implementation | Original triangles whose unordered reflected partner already exists and is preserved unchanged | `LOCAL_reflection_closed_triangles` |
| `centroid_x` | real vector, one pre-repair mesh | Section 15.3 deterministic tie resolution | Triangle-centroid $x$ coordinate used only to choose the negative-side representative of a missing-partner orbit | `LOCAL_reflection_closed_triangles` |
| `unpaired_left`, `unpaired_right`, `unpaired_center` | logical vectors | Section 15.3 tie-resolution implementation | Missing-partner tie triangles partitioned by centroid sign; negative-centroid representatives generate the repaired pair, while centered or unbalanced inventories fail | `LOCAL_reflection_closed_triangles` |
| `repaired_triangles` | integer $n_T\times3$ | reflection-closed connectivity, Section 15.3 | Existing closed orbits plus negative-centroid missing-partner representatives and their reflected copies, deterministically row ordered | `LOCAL_reflection_closed_triangles`; `LOCAL_build_mesh` |
| `repair_diagnostic` | per-mesh struct | Sections 15.3, 15.5 | Unresolved tie count, duplicate count, relative rectangular coverage-area defect, pass flag, and failure reason | `LOCAL_reflection_closed_triangles`; mesh gates/ledger |
| `reflected_partner` | integer vector, one mesh | unique reflected-triangle pairing, Section 15.3 | Row index of each unordered triangle's reflected partner | `LOCAL_triangle_reflection_diagnostics` |
| `unpaired_constraint_count` | nonnegative integer | Sections 15.3, 15.5 | Number of frozen constraint segments missing a reflected partner under $\rho$ | pre-assembly gate; mesh/diagnostic ledgers |
| `unpaired_triangle_count` | nonnegative integer | Sections 15.3, 15.5 | Number of triangles missing a unique reflected partner | pre-assembly gate; mesh/diagnostic ledgers |
| `material_pair_mismatch_count` | nonnegative integer | Sections 15.3, 15.5 | Number of unique reflected triangle pairs whose frozen polygon-inside flags differ | pre-assembly gate; mesh/diagnostic ledgers |
| `connectivity_area_defect` | nonnegative real scalar | Sections 15.3, 16.3 coverage-area check | Relative difference between repaired triangle area and rectangular supercell area; not by itself a no-hole/no-overlap proof | tie-resolution gate; mesh/diagnostic ledgers |
| `planar_diagnostic` | per-mesh struct | Section 16.3 planar-complex oracle | Preassembly uniqueness, edge-incidence, exact outer-boundary, nonincident-edge-intersection, triangle-connectivity, and frozen-constraint evidence | `LOCAL_planar_complex_diagnostics`; `LOCAL_build_mesh` |
| `canonical_triangles` | integer $n_T\times3$ | Section 16.3 unordered-triangle uniqueness | Sorted vertex IDs for each triangle | planar-complex oracle |
| `triangle_edges`, `unique_edges` | integer edge arrays | Section 16.3 edge-incidence complex | Three unordered edges per triangle and their unique mesh-edge set | planar-complex oracle and its subchecks |
| `edge_triangle_index`, `edge_index`, `edge_incidence` | integer vectors | Section 16.3 edge-incidence complex | Triangle owner of each edge occurrence, unique-edge ID of each occurrence, and incidence count of each unique edge | planar-complex and adjacency oracles |
| `canonical_constraints` | integer edge array | Section 16.3 frozen-constraint check | Canonical frozen constraint-segment set | planar-complex constraint oracle |
| `duplicate_triangle_count` | nonnegative integer | Section 16.3 uniqueness gate | Number of repeated unordered triangle rows | repair and planar-complex ledgers |
| `invalid_edge_incidence_count` | nonnegative integer | Section 16.3 incidence gate | Number of mesh edges whose triangle incidence is neither one nor two | planar-complex ledger/gate |
| `nonmanifold_edge_count` | nonnegative integer | Section 16.3 incidence gate | Number of mesh edges with triangle incidence greater than two | planar-complex ledger/gate |
| `boundary_edges`, `expected_boundary_edges` | integer edge arrays | Section 16.3 rectangular-boundary equality | Actual incidence-one mesh edges and the consecutive segmentation induced by all frozen outer-rectangle nodes | planar-complex boundary oracle |
| `side_definitions`, `side_nodes` | mixed $4\times3$ cell array and integer vector | Section 16.3 rectangular-boundary equality | Four fixed/varying coordinate specifications and ordered nodes on one outer side | `LOCAL_outer_boundary_edges` |
| `boundary_edge_count`, `expected_boundary_edge_count` | nonnegative integers | Section 16.3 rectangular-boundary equality | Sizes of the actual and frozen outer-boundary edge sets | mesh/diagnostic ledgers |
| `interior_free_boundary_count` | nonnegative integer | Section 16.3 rectangular-boundary equality | Incidence-one mesh edges not belonging to the frozen outer segmentation | planar-complex ledger/gate |
| `missing_outer_boundary_count` | nonnegative integer | Section 16.3 rectangular-boundary equality | Frozen outer segments absent from the incidence-one mesh boundary | planar-complex ledger/gate |
| `nonincident_edge_intersection_count` | nonnegative integer | Section 16.3 straight-edge conformity | Intersecting geometric edge pairs that share no node, found by deterministic $x$-ordered bounding-box sweep and orientation tests | planar-complex ledger/gate |
| `edge_box_lower`, `edge_box_upper`, `sweep_edge_order` | real $n_E\times2$ arrays and integer permutation | Section 16.3 nonincident-edge intersection algorithm | Edge bounding-box corners and deterministic lower-$x$ sweep order used to prune exact segment-pair checks | `LOCAL_nonincident_edge_intersection_count` |
| `orientation_1`--`orientation_4`, `proper_crossing`, `touches` | real scalars and logical scalars, one edge pair | Section 16.3 nonincident-edge intersection algorithm | Four signed 2D orientation products, exact-sign proper crossing, and tolerance-closed touching classifications | `LOCAL_segments_intersect` |
| `adjacency` | sparse real $n_T\times n_T$ | Section 16.3 connected triangle adjacency | Binary-support triangle graph joined across every shared mesh edge | `LOCAL_triangle_component_count` |
| `sorted_edge_index`, `incidence_edge_order`, `incidence_group_start`, `incidence_group_end` | integer vectors | Section 16.3 connected triangle adjacency | Grouping of edge occurrences by unique edge for deterministic adjacency construction | `LOCAL_triangle_component_count` |
| `adjacency_start`, `adjacency_end`, `visited`, `queue` | integer vectors and logical vector | Section 16.3 connected triangle adjacency | Sparse triangle-adjacency endpoints and deterministic breadth-first traversal state | `LOCAL_triangle_component_count` |
| `triangle_component_count` | nonnegative integer | Section 16.3 connected-domain gate | Number of connected components in triangle adjacency; must equal one | planar-complex ledger/gate |
| `planar_complex_pass` | logical scalar | Section 16.3 aggregate oracle | True exactly when all topology/conformity and frozen-constraint subchecks pass | mesh/diagnostic ledgers; all-nine closure |
| `h` | real scalar, local | $h=1/s$, Sections 3.2, 4.2 | Background spacing, length unit | `LOCAL_build_mesh` |
| `n_gamma` | integer scalar | $n_\Gamma$, Sections 3.2, 4.2 | Inscribed regular-polygon segment count | `mesh_spec`; geometry diagnostics |
| `area_deficit` | nonnegative scalar | $\epsilon_{\mathrm{area}}$, Section 3.2 | Relative polygon area deficit | mesh ledger |
| `hausdorff_defect` | nonnegative scalar | $\epsilon_{\mathrm H}$, Section 3.2 | Circle-to-chord sagitta, length unit | mesh gate/ledger |
| `stiffness_full` | real sparse $n\times n$ | $K$, Sections 3.3, 9.2 | Full nodal matrix for $\int\nabla u\cdot\nabla\bar v$ | `LOCAL_assemble_p1`; phase reduction |
| `mass_full` | real sparse $n\times n$ | $M$, Sections 3.3, 9.2; Section 18.2 as-built diagnostic | Full nodal matrix for $\int q u\bar v$ | `LOCAL_assemble_p1`; phase reduction, normalization/overlaps, mass diagnostic |
| `mass_center` | real sparse $n\times n$ | $M_{C_0}$, Sections 5.3, 6.1 | Restricted weighted mass on $C_0$ | `LOCAL_assemble_p1`; mode labels |
| `mass_core` | real sparse $n\times n$ | $M_{|x|<3/2}$, Section 6.1 | Restricted weighted mass on the frozen localization core | same |
| `mass_tail` | real sparse $n\times n$ | $M_{|x|>N-3/2}$, Section 6.1 | Restricted weighted outer-tail mass | same |
| `phase_prolongation` | complex sparse $n\times n_r$ | $P$, Section 3.3; Section 18.2 | Maps master nodal values to full values with right/top phase factors | `LOCAL_phase_reduce`; solves and mass diagnostic |
| `stiffness_reduced` | complex sparse $n_r\times n_r$ | raw $K_\phi=P^*KP$, Sections 3.3, 22.3 | As-built quasiperiodic stiffness before the raw representation gate; never overwritten | `LOCAL_phase_reduce`; canonical gate/preflight |
| `mass_reduced` | complex sparse $n_r\times n_r$ | raw $M_\phi=P^*MP$, Sections 3.3, 18.2, 22.3 | As-built quasiperiodic mass before the canonical representation gate; retained unchanged for raw evidence and the mass diagnostics | `LOCAL_phase_reduce`; canonical gate, `LOCAL_mass_gate_diagnostics` |
| `phase_x` | real scalar, solve-local | $\alpha$ or $\vartheta$, Section 3.1 | Longitudinal Bloch/supercell phase, radians | solve schedules; phase reduction |
| `strict_upper` | sparse or dense square matrix | $\operatorname{triu}(A_{\mathrm{raw}},1)$, Sections 22.2, 22.12 | Sole retained off-diagonal authority in the proof-backed canonical construction | `LOCAL_canonical_hermitian` |
| `canonical` / `stiffness_canonical` / `mass_canonical` | sparse or dense square matrix | $\mathcal H(A)=U+U^*+\operatorname{diag}(\operatorname{Re}\operatorname{diag}A)$, Sections 22.2, 22.12 | Strict-upper/real-diagonal canonical object; no adjoint averaging, thresholding, shift, or post-symmetrization | `LOCAL_canonical_hermitian`; canonical gates/consumers |
| `operator_pair` | solve-local struct | canonical $(K_{\phi,\mathrm H},M_{\phi,\mathrm H})$, Sections 22.5, 22.12.1 | One in-memory pair plus $P_\phi$, mass factor, and OP2 identity; the same matrices feed `chol`, `eigs`, normalization, orthogonality, and residuals | `LOCAL_prepare_primary_pair`; `LOCAL_low_spectrum` |
| `mass_factor` | upper-triangular matrix | $R$ from $R^*R=M_{\phi,\mathrm H}$, Sections 22.4, 22.12 | Output of the primary mass object's sole two-output `chol` gate | `LOCAL_evaluate_canonical_object`; primary pair/diagnostic |
| `evaluation` | scalar struct, one allowlisted object | Sections 22.3--22.7, 22.12.3 | Raw/canonical dimensions, sparsity, finite/diagonal/Hermitian/delta fields, factorization flag, gate and immutable first-failure evidence | canonical evaluation and v2-36 row builders |
| `raw_gram`, `canonical_gram` | dense $m\times m$ | $V_0^*M_{\phi,\mathrm H}V_0$ and $\mathcal H(G_{\mathrm{raw}})$, Section 22.12.1 | Cluster/probe Gram before and after the same proof-backed rule | cluster normalization and representation probes |
| `normalized_reduced`, `normalized_full` | complex $n_r\times m$ and $n\times m$ | $V_C=V_C^{(0)}/R_C$, $U_C=P_\phi V_C$, Section 22.12.1 | Canonical-metric reduced cluster basis and its synchronously regenerated full basis | `LOCAL_normalize_defect_clusters`; downstream Gram consumers |
| `normalization_contract_ids` | cell vector per defect spectrum | Section 22.12.2 DRV2 linkage | Global cluster-normalization DRV2 indexed by source cluster ID; reduced bases are not persisted | `LOCAL_normalize_defect_clusters`; `spectrum`, `LOCAL_gap_clusters` |
| `common_core_samples`, `common_core_weights` | complex sample matrix and positive real vector | Sections 5.3, 22.6, 22.12.4 | Once-normalized sampled cluster basis and frozen quadrature weights; its canonical self-Gram is factored once per configuration/phase/cluster | `LOCAL_gap_clusters`; `LOCAL_common_core_overlap` |

## Spectrum, branch, and resolution objects

| Canonical code name | Kind and scope | Draft symbol / source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `spectrum` | struct, one solve | $(\lambda_j,u_j)$, Sections 5.1, 22.12.1--22.12.2 | Ordered eigenobjects, normalized full fields, residuals, clusters, immutable parent OP2, and per-cluster normalization DRV2; no persistent reduced eigenvector copy | `LOCAL_low_spectrum`; current-run caches/inventories/tracking |
| `eigenvalue` | positive real scalar | $\lambda_j$, Sections 2, 5.1 | Generalized FEM eigenvalue, frequency squared | eigensolver; ledgers |
| `frequency` | positive real scalar | $k_j=\sqrt{\lambda_j}$ | Positive frequency | inventories, envelopes |
| `algebraic_residual` | nonnegative scalar | $r_{\mathrm{alg}}$, Section 5.1 | Scale-normalized generalized eigen-residual | eigensolver hard gate |
| `cluster` | struct, one slice | multiplicity-$m$ cluster, Sections 5.1, 5.3, 22.12.1 | Ordered roots, envelope, synchronized full canonical-metric subspace, OP2/normalization DRV2, endpoint-only parity, and cached common-core normalized samples | `LOCAL_gap_clusters`; continuation/labels |
| `branch` | struct, one configuration | observed branch/cluster $j$, Sections 5.3--7 | Dimension-stable across-twist cluster with slice envelopes, fields, Gram spectra, parity, and continuation records | `LOCAL_track_twists`; coverage/resolution |
| `restricted_gram` | dense $m\times m$ raw/canonical pair | $G_D(U)=U^*M_DU$, Sections 5.3, 6.1, 22.6 | Basis-covariant regional compression formed from the synchronized $U_C$, raw-gated and canonicalized before extremal eigenvalues enter gates | `LOCAL_gap_clusters` |
| `parity_spectrum` | real length-$m$ vector or empty | $\operatorname{spec}(\mathcal H(U^*M\mathcal R_xU))$, Sections 5.3, 22.6, 22.13.5 | Basis-invariant parity multiset only at $\vartheta=0,\pi$; interior caches are empty and nonambiguous | `LOCAL_gap_clusters`; endpoint branch aggregate |
| `principal_overlap` | scalar in $[0,1]$ | minimum singular value, Section 5.3 | Phase/basis-invariant common-core subspace overlap | `LOCAL_common_core_overlap`; matching |
| `spectral_envelope` | real $1\times2$ | $E_j=[k_j^{\min},k_j^{\max}]$, Sections 6.2, 7 | Basis-invariant cluster/twist frequency interval | branch/resolution stages |
| `envelope_distance` | nonnegative scalar | $d_E$, Section 7 | Maximum endpoint distance between two envelopes, frequency | `LOCAL_envelope_distance`; resolution |
| `delta_fem` | nonnegative scalar | $\delta_{\mathrm{FEM},j}^{\mathrm{obs}}$, Section 7 | Last visible FEM/geometry envelope change | `LOCAL_resolution` |
| `delta_supercell` | nonnegative scalar | $\delta_{N,j}^{\mathrm{obs}}$, Section 7 | Fine $N$ change plus fine/medium interaction | same |
| `delta_twist` | nonnegative scalar | $\delta_{\mathrm{twist},j}^{\mathrm{obs}}$, Section 7 | Finest half-width plus twist-sampling change | same |
| `delta_algebraic` | nonnegative scalar | $\delta_{\mathrm{alg},j}^{\mathrm{obs}}$, Section 7 | Maximum tight/loose slice-envelope change | same |
| `delta_reference` | nonnegative scalar | $\Delta_{\mathrm{ref},j}^{\mathrm{obs}}$, Section 7 | Sum of four observed components; not an error bound | same; blinded export |
| `reference_frequency` | positive scalar | $k_{\mathrm{ref},j}$, Section 7 | Center of finest $\Theta_{17}$ spectral envelope | collection export |
| `reference_collection` | struct array | $\mathcal K_{\mathrm{ref}}^{\mathrm{obs}}$, Sections 1, 7, 8 | Complete qualified finite empirical collection, or empty on failure | `LOCAL_export_terminal` |

## Execution and artifact roles

| Canonical code name | Kind and scope | Source | Meaning | Defined / consumed |
|---|---|---|---|---|
| `run_id` | input character vector | Sections 8.3, 10.1 | Explicit artifact label only; never changes science | entry function; output path |
| `mode` | optional diagnostic input | Sections 15.5, 18.2, 20.3, 22.12.5 | Exact registered mesh, mass, or representation diagnostic mode; one-input formal semantics remain unchanged | entry dispatch |
| `diagnostic_id`, `diagnostic_mode` | character vectors, dispatch-local | Sections 15.5, 18.2, 20.3, 22.12.5, 23.2, 25.2; reviews §§AM, AS | Validated exact diagnostic pair; create-once `representation-gate-001`, `representation-gate-002`, and `representation-gate-003` are all consumed, with 003 complete after natural exit; each accepts only `representation-diagnostic`, without widening arbitrary path input | entry dispatch; diagnostic runners |
| `allowed_ids` | two-entry cell array, mass-runner local | Section 20.3 exact allowlist | Exactly `mass-gate-001` and `mass-gate-002`; prevents arbitrary IDs before path construction | `LOCAL_run_mass_diagnostic` |
| `diagnostic_dir` | create-once local path | Sections 15.5, 18.2, 20.3, 22.12.5, 23.2, 25.2 | Fixed namespace for the selected diagnostic; collision checks only that selected path before evidence access, and 003 never inspects or reuses 001/002 history | diagnostic runners and writers |
| `temporary_work_dir` | disposable system-temporary path | Sections 15.5, 16.4 no-reuse/publication contract | Current diagnostic's mesh caches used only to form the resource forecast; successfully created before the final create-once path is claimed and removed on exit | diagnostic preflight; `LOCAL_remove_diagnostic_work` |
| `summary` | diagnostic result struct | Section 15.5 | Mesh count, zero eigensolves, elapsed time, formal resource forecast, fail-closed status, no-reference flag, and claim boundary | `LOCAL_run_mesh_diagnostic`; diagnostic summary artifacts |
| `closure_pass` | diagnostic logical scalar | Sections 15.5, 16.3 | True only for all nine meshes with zero tie/reflection/material defects and full planar-complex validity | `LOCAL_run_mesh_diagnostic`; diagnostic summary CSV/MAT |
| `diagnostic_summary` | mass-diagnostic lifecycle struct | Sections 18.3--18.6, 20.2--20.3 | Exact selected identity, status, zero-eigensolve/no-reference gates, row counts, resource forecast, first failure, claim boundary, and publication state; its audited MAT is written after all evidence and its audited CSV is the final commit marker | `LOCAL_run_mass_diagnostic`; `LOCAL_write_mass_diagnostic_summary` |
| `mass_artifacts` | mass-diagnostic row bundle | Section 18.3 | Exact 9-, 7-, 14-, and 23-column node, master, matrix, and Cholesky-pivot ledgers; initially header-only and later atomically replaced with reached evidence | `LOCAL_empty_mass_artifacts`; `LOCAL_write_mass_artifacts` |
| `bulk_artifacts` | mass-diagnostic header bundle | Sections 18.3--18.4 | Empty 10-column bulk-band and 14-column bulk-gap row sets; hard-gated to zero data rows | `LOCAL_run_mass_diagnostic`; `LOCAL_write_bulk_artifacts` |
| `node_incidence`, `unused_point_ids` | integer vectors, one mass diagnostic | Section 18.3 item 5 | Triangle incidence per full node from repaired `mesh.triangles(:)`, and ascending IDs with zero incidence | `LOCAL_mass_gate_diagnostics`; node/summary CSV and MAT payload |
| `master_ids`, `master_group_members` | integer vector and cell array | Section 18.3 item 6 | Unique periodic master IDs and the full-node members of each equivalence group | `LOCAL_mass_gate_diagnostics`; master/summary CSV and MAT payload |
| `p_row_support`, `p_column_support`, `p_zero_support_column_ids` | integer vectors | Section 18.3 items 5--6, 9; Section 20.2 | Sparse nonzero support counts of exact $P$ rows/columns and ascending empty-column IDs; only a selected row count crosses the CSV boundary as a full scalar | `LOCAL_mass_gate_diagnostics`; node/master/summary evidence |
| `p_row_nnz` | ordinary full numeric scalar | Section 20.2 exact normalization | Value-preserving `full(p_row_support(node_id))`; never a dense copy of $P$ | `LOCAL_mass_gate_diagnostics`; node incidence CSV row |
| `p_entry_modulus`, `p_entry_modulus_min`, `p_entry_modulus_max` | real vectors/scalars | Section 18.3 | Moduli of stored exact $P$ entries, globally and per master column | `LOCAL_mass_gate_diagnostics`; node/master/summary evidence |
| `full_matrix_diagnostic`, `reduced_matrix_diagnostic` | structs, one raw matrix each | Section 18.3 item 7; Section 20.2 | Dimensions, `nnz`, stored nonfinite values, zero rows/columns, diagonal ranges, and absolute/normalized 1-norm Hermitian defects of the as-built matrices; only three diagonal reductions are converted to full scalars | `LOCAL_mass_matrix_diagnostics`; matrix CSV and MAT payload |
| `diagonal_real_min`, `diagonal_real_max`, `diagonal_max_abs_imag` | ordinary full numeric scalars | Section 20.2 exact normalization | Value-preserving `full` of the three reductions of the sparse diagonal; the matrix and full diagonal remain sparse/as-built | `LOCAL_mass_matrix_diagnostics`; matrix CSV/MAT evidence |
| `partial_factor`, `chol_flag`, `chol_call_completed` | sparse matrix, natural integer flag, logical | Sections 18.2--18.4 | Outputs and completion state of the diagnostic's one raw `[partial_factor,chol_flag]=chol(reduced.mass)` call; no permutation or repaired matrix | `LOCAL_mass_gate_diagnostics`; pivot/summary evidence |
| `pivot_support` | mass-diagnostic struct | Section 18.3 item 8; Section 20.2 | For valid positive `chol_flag`, the same natural 1-based reduced/master ID and its group, incidence, $P$, reduced-mass, and full-mass supports; flag zero leaves pivot-only fields empty or `NaN` | `LOCAL_chol_pivot_evidence`; pivot CSV and MAT payload |
| `pivot_diagonal` | ordinary full complex scalar | Section 20.2 exact normalization | Value-preserving full scalar copy of only `reduced.mass(pivot_id,pivot_id)` before real/imag publication | `LOCAL_chol_pivot_evidence`; pivot CSV/MAT evidence |
| `mass_summary`, `mass_payload` | scalar ledger struct and exact-array payload | Section 18.3 items 9--10 | Frozen identity and evidence counts plus exact points, triangles, incidence, groups, $P$, full/reduced masses, partial factor, matrix diagnostics, and pivot identity | `LOCAL_run_mass_diagnostic`; mass-summary CSV/MAT |
| `pre_summary_artifacts_present`, `required_artifacts_present` | logical scalars | Sections 18.3--18.4 | First verifies mesh/seam, empty bulk, and four mass ledgers before mass-summary publication; second additionally verifies both mass-summary files. Both require no `.partial` peer | `LOCAL_required_mass_artifacts_present`; mass and terminal evidence gates |
| `rows`, `ledger_name`, `expected_columns` | diagnostic publication gate inputs | Section 20.2 | Nonmutating CSV cell matrix, stable ledger identity, and frozen schema width to audit before any mass-related writer | `LOCAL_assert_mass_csv_rows`; mass/summary writers |
| `cell_value`, `safe_value` | one-cell value and logical predicate | Section 20.2 and review §Y.4 | Accepts only nonsparse scalar or empty numeric/logical values, row character strings, or optional scalar MATLAB strings; rejects sparse, nonscalar numeric/logical, multidimensional character, and unsupported objects | `LOCAL_assert_mass_csv_rows` |
| `run_state` | run-wide struct | Sections 9--12 | Stage, terminal status, first failure, solve counts, elapsed time, progress and warnings | main; record/export helpers |
| `output_dir` | path local to entry | Sections 8.1, 10.1 | New `output/<run_id>/`; collision fails without overwrite | entry; writers |
| `work_dir` | current-run subdirectory | implementation responsibility | Atomic per-mesh and per-solve machine cache; never used as historical input | mesh/solve stages only |
| `bulk_inventory` | struct | Sections 4.2, 9.2 | All bulk levels, bands, observed target gap, edge changes, sentinels | bulk stage; defect gates |
| `defect_inventory` | struct | Sections 5.1--5.2, 9.2 | Frozen union of 47 complete defect solves | defect/branch stages |
| `coverage_result` | struct | Section 6.3 | Every-object inclusion/exclusion/unresolved ledger and fail-closed verdict | `LOCAL_coverage_gate`; export |
| `resolution_result` | struct | Section 7 | Branch-wise four-axis components, gates, and collection | `LOCAL_resolution`; export |
| `failure_code` | character vector | Section 11 | First scientific or operational terminal cause | failure helpers; artifacts |
| `first_failure_code`, `first_failure_reason` | character columns on reached-stage ledgers | Sections 9.1, 10.2, 11 | Immutable first scientific mesh- or branch-stage failure attached to every reached row before the same code is rethrown | `LOCAL_checkpoint_mesh_failure`; `LOCAL_mark_branch_failure`; mesh and branch/coverage CSVs |
| `stage_failure` | local result struct | Sections 5.3, 6.3, 11 | Explicit `failed/code/reason` return from twist continuation; prevents partial local rows from being lost through MATLAB value semantics | `LOCAL_track_twists`; `LOCAL_branch_and_coverage` |
| `reached_anchor_fields` | failure-publication struct array | Sections 10.2, 11; review §J.2/J.6 | Every anchor subspace belonging to a fully formed branch at the failure boundary, with configuration, mesh ID, multiplicity, optional phase-fixed simple vector, and unqualified branch status; raw untracked clusters are excluded | `LOCAL_reached_anchor_fields`; `LOCAL_export_failure_fields`; `fields.mat` |
| `field_meshes` | failure-publication struct array | Section 10.2; review §J.2/J.6 | Unique current-run fitted meshes needed to interpret `reached_anchor_fields`; each entry contains mesh ID, points, triangles, and material labels | `LOCAL_failure_field_meshes`; `fields.mat` |
| `primary_mesh` | failure-publication mesh struct | Section 10.2 | Finest reached `fine` mesh when available, otherwise the first completed configuration mesh; preserves the legacy top-level mesh fields while `field_meshes` covers all reached anchors | `LOCAL_export_failure_fields`; `fields.mat` |
| `sentinel_machine` | current-run spectrum struct | Sections 4.2, 5.1 | Ordered 48-root bulk sentinel with frequencies, eigenvalues, residuals, cluster ledger, and no retained bulk field matrix; saved before mismatch verdict | `LOCAL_bulk_inventory`; current-run `work/` cache |
| `fields.artifact_status` | character field | Sections 7, 10.2, 13.4 | Either `QUALIFIED / REFERENCE_COLLECTION_READY` or `UNQUALIFIED / FAILURE_ARTIFACT`; the latter preserves reached branch anchors after a later coverage/collapse/resolution failure without promoting them | success/failure field exporters |
| `planned_solves` | integer scalar | Sections 5.2, 12.1 | Frozen total $72+47=119$ | spec/preflight/progress |
| `completed_solves` | integer scalar | Sections 9.1, 12.2 | Number of completed eigensolves in current run | state/progress |
| `wall_estimate_minutes` | nonnegative scalar | Section 12.1 | Complete-command forecast: elapsed environment/mesh audit plus safety-scaled 67/5/20/27 solve categories and postprocess/export, with the 29.8-minute design floor | resource gate |
| `peak_estimate_gib` | nonnegative scalar | Sections 12.1, 22.10 | Safety-scaled canonical symbolic-fill/workspace/cache/export estimate with the repaired 1.3-GiB formal floor; not measured RSS | resource gate |
| `symbolic_factor_nnz` | nonnegative integer per mesh | Section 12.1 implementation preflight | `sum(symbfact(spones(K)+spones(M)+I))`; symbolic sparse-factor fill estimate, not measured numeric fill | `LOCAL_resource_preflight`; resource artifacts |
| `workspace_40_bytes`, `workspace_48_bytes` | nonnegative scalars per mesh | Sections 5.1, 12.1 | Complex sparse-pair, symbolic factor, Arnoldi basis, requested eigenvectors, and full-field workspace estimates for the frozen 40/48-root solves | `LOCAL_workspace_bytes`; resource artifacts |
| `runtime_safety_factor` | real scalar | Section 12 implementation audit | Frozen implementation accounting factor `1.25`, applied to category wall and memory estimates before the design floors | `LOCAL_resource_preflight` |
| `resource_preflight` | run-wide struct | Sections 9.1, 12, 13.3 | Pre-eigensolve audit containing every mesh fill estimate, 72/47 category wall ledger, current-run cache/export costs, forecast, and pass flag | `LOCAL_preflight_audit`; `resource-preflight.mat`, `run-summary.mat` |
| `mesh_diagnostic` | per-mesh publication struct | Sections 9.1, 10.2, 15.3, 15.5; review §O.4 | Incrementally reached mesh counts, geometry/connectivity/material diagnostics, assembly nonzero counts, and reflection defects; unavailable later-stage values remain `NaN` | `LOCAL_initial_mesh_diagnostic`; `LOCAL_build_mesh`; `LOCAL_mesh_diagnostic_row` |
| `prior_mesh_rows`, `prior_seam_rows` | stage-local checkpoint inputs | Sections 9.1, 10.2; review §O.4 | Completed current-run mesh and seam rows carried across a later mesh failure so MATLAB value semantics cannot discard them | `LOCAL_mesh_oracles`; `LOCAL_build_mesh`; mesh checkpoint helpers |
| `reached_boundary` | mesh-ledger character column | Sections 9.1, 10.2; review §O.4 | Last completed diagnostic boundary for a success or expected mesh failure, such as `REFLECTION_MATRIX_ORACLE` | `LOCAL_mesh_diagnostic_row`; `mesh-ledger.csv` |
| `failure_mesh_rows` | stage-local cell matrix | Sections 9.1, 10.2; review §O.4 | Completed rows plus the current partial failure row, all carrying the immutable first mesh failure code/reason | `LOCAL_checkpoint_mesh_failure`; `mesh-ledger.csv` |
| `required_functions` | environment-audit cell array | Section 13.1 operational dependency gate | Ordinary base-MATLAB functions checked with `exist(...,'file'/'builtin')`; excludes class constructors and class methods | `LOCAL_check_environment` |
| `required_classes` | environment-audit cell array | Section 13.1 operational dependency gate | Required geometry classes checked with `exist(...,'class')` | `LOCAL_check_environment` |
| `triangulation_methods` | environment-audit cell array | Section 13.1 operational dependency gate | Public method inventory for the `triangulation` class; must include the actually used `pointLocation` method | `LOCAL_check_environment` |

## Representation evidence and benchmark objects

| Canonical code name | Kind and scope | Draft symbol / source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `operator_ledger` | run/diagnostic struct | Sections 22.7, 22.12.2--22.12.4 | Exact v2-36 header/rows, schema version, model identity, 10414-row/261-checkpoint caps, primary/derived inventories, and immutable first-failure owner | `LOCAL_initial_operator_ledger`; canonical checkpoints/writer |
| `contract_id` / `operator_contract_id` | character identity | OP2 and DRV2, Section 22.12.2 | Deterministic primary mesh/phase identity or derived object/context identity; independent of tolerance, `nev`, run ID, history, and numerical ranking | contract helpers; spectrum/cluster/probe rows |
| `parent_operator_contract_id` | character identity or empty | Section 22.12.2 | Empty for primary K/M; exact parent OP2 for every derived Gram/probe | derived v2 rows and probe-cost ledger |
| `pending_rows`, `pending_restricted_rows`, `pending_common_rows` | three solve-local derived-row batches | Sections 22.12.4, 22.15.2 | Schema-valid global, restricted/parity, and common-core rows, each atomically committed before its first normalization, dense eigendecomposition, or common-core sample consumer | `LOCAL_normalize_defect_clusters`; `LOCAL_gap_clusters`; `LOCAL_checkpoint_operator_rows` |
| `prepared` | solve-local struct array | Section 22.15.2 prepare/checkpoint/consume contract | Canonical matrices/factors and source subspaces held between preparation and post-checkpoint consumption; consumer failures never mutate committed rows | `LOCAL_normalize_defect_clusters`; `LOCAL_gap_clusters` |
| `canonical_restricted_matrices`, `canonical_parity` | dense square matrices per reached cluster | Sections 22.6, 22.12.1, 22.15.2 | Canonical center/core/tail compressed masses and endpoint-only parity compression prepared before their batch checkpoint, then consumed without row mutation | `LOCAL_gap_clusters`; shared parity helpers |
| `prepare_bytes`, `consume_bytes` | nonnegative byte scalars, diagnostic-only output | Sections 22.14.1, 22.15.2 | Array evidence for the shared parity preparation and consumption paths; omitted by the four-output formal prepare call | `LOCAL_prepare_parity_object`; `LOCAL_consume_parity_object`; parity probe |
| `primary_contract_inventory`, `derived_parent_inventory` | cell inventories | Section 22.12.2 MAT mirror | Unique OP2 set and stable DRV2-parent pairs reconstructed by the shared pure payload preparation; contain no matrices or solver cache | `LOCAL_prepare_operator_payload`; formal/benchmark shared writer |
| `payload`, `primary_mask`, `derived_rows`, `derived_keys`, `stable_indices` | publication-local struct, masks, and identity lists | Sections 22.12.2--22.12.4, 22.15.2 | Pure v2 MAT payload and stable OP2/DRV2-parent inventory construction used unchanged by formal and benchmark writers | `LOCAL_prepare_operator_payload`; `LOCAL_write_operator_representation` |
| `timings`, `publication_clock`, `mat_clock`, `csv_clock` | publication timing struct and monotone clocks | Sections 22.14.2, 22.15.2 | Per-checkpoint preparation-plus-MAT, CSV, and end-to-end elapsed fields; the outer clock begins before shared preparation and ends after both atomic moves | shared operator writer; growing-writer benchmark |
| `first_failure` | immutable ledger struct | Section 22.12.3 | Failure code/reason plus owner object and sequence; stiffness owns a stiffness-first phase failure and mass then remains raw-only evidence | operator checkpoint/writer |
| `raw_stats`, `canonical_stats`, `factor_stats` | timing structs | Sections 22.13.2, 22.14.3 | Two discarded warmups and five repeats for primary raw diagnostics, canonical construction, and mass factorization | representation diagnostic probe ledger |
| `conservative_costs`, `timing_spreads` | real $6\times48$ arrays | Sections 22.13.2--22.14.3 | Quantized conservative seconds and max-minus-min spread for global, three restricted, endpoint parity, and common-core width paths | width probes; family aggregation |
| `family_costs`, `family_spreads` | real $4\times48$ arrays | Section 22.13.3 and review §AE | Frozen $g_m,d_m,p_m,c_m$ families; $d_m$ is the sum of all three restricted paths before partition DP | `LOCAL_partition_evidence`; forecast/spread gates |
| `dynamic_cost`, `last_width`, `partition` | DP arrays/vector | $C_a(n)=\max_m(a_m+C_a(n-m))$, Section 22.13.3 | Exact maximizing positive-integer cluster-width partition for `nev` 40 or 48 and its conservative component sum | `LOCAL_partition_bound`; partition ledger |
| `padding_rows` | $10414\times36$ cell matrix | Sections 22.12.4, 22.14.2, 22.15.2 | Deterministic schema-safe container with exactly 238 parent-empty `reduced-stiffness`/`reduced-mass` primary-shaped rows and 10176 nonempty-parent DRV2-shaped rows; every warmup/repeat applies dimension, type, width, and parent-shape gates | `LOCAL_prepare_padding_rows`; growing-writer benchmark; completion gate |
| `expected_primary_objects`, `primary_valid`, `derived_valid` | padding-contract cell vector and logical gates | Sections 22.7, 22.15.2 | Alternating frozen primary object vocabulary and exact 238-primary/10176-derived parent-shape assertions | `LOCAL_validate_padding_contract` |
| `additions`, `kinds` | length-261 numeric/cell schedules | Sections 22.12.4, 22.14.2 | Header, 119 primary-pair, 47 global, 47 restricted/parity, and 47 common-core cumulative checkpoint schedule totaling 10414 rows | `LOCAL_benchmark_growing_writer` |
| `resource_rows` | 17-column cell ledger | Section 22.14.2 | Component timing, exact row dimensions, array-byte before/peak/increment, solve/`nev`, partition role, and notes | representation resource writer/forecast |
| `probe_rows` | 294-by-16 cell ledger on completion | Sections 22.14.1, 22.14.3, 25.7 | Six primary component rows plus six width-indexed paths for widths 1--48, with OP2/DRV2, repeat statistics, CV, quantization and gate; a false 003 timing gate is recorded as advisory rather than execution failure | representation diagnostic |
| `partition_rows` | 8-by-7 cell ledger on completion | Section 22.13.3 | Four families times `nev` 40/48 with maximizing partition and scheduled contribution | representation diagnostic |
| `rewrite_rows` | exactly 261-by-11 cell ledger on completion | Sections 22.12.4, 22.14.2, 22.15.2 | One untimed empty-writer warmup followed by the exact cumulative schedule through 10414 rows; each checkpoint times shared payload/assert/inventory preparation through atomic MAT and CSV moves and must pass finite, nonnegative, identity, and cumulative-monotonicity gates | `LOCAL_benchmark_growing_writer`; `LOCAL_validate_rewrite_rows` |
| `timing_consistency`, `rewrite_pass` | logical scalars | Sections 22.14.2, 22.15.3, 25.7 | Raw rewrite clock-nesting observation and dispatch-local hard gate; 003 preserves timing columns but hard-gates only exact schedule and finite nonnegative evidence | `LOCAL_validate_rewrite_rows` |
| `forecast_rows` | one 27-column row | Sections 22.13.3--22.14.3, 23.5, 25.7 | 29.8-minute baseline plus nonoverlapping primary/DP/row/writer costs, propagated spread gate, and 1.2-GiB internal array baseline plus peak increment; the existing resource fields are observation-only for 003 | representation diagnostic summary gate |
| `wall_pass`, `peak_pass`, `timing_pass`, `internal_pass` | logical scalars, representation diagnostic | Sections 22.13.3--22.14.3, 23.5, 25.7 | Strict sub-30-minute forecast, at-most-1.5-GiB forecast observation, repeated-timing stability, and dispatch-local historical screen; 001 keeps its three-way terminal conjunction, 002 uses wall/timing, and 003 records the three-way value without consuming it in terminal selection | representation forecast row and terminal status |
| `representation_summary` / representation `summary` | 19-field terminal struct | Sections 22.13.1, 22.13.4, 22.15.3, 23.5--23.6, 25.7; review §AS | Exact current diagnostic ID/dispatch, count/schema, operator-inventory mirror, header-only bulk, zero-scientific-eigensolve/no-reference, required-file, and no-partial completion state; the 003 runtime terminal correctly remained pending external review, and §AS records that review as complete with the exact limited claim boundary | `LOCAL_representation_completion_gate`; summary-last MAT/CSV commit |

## Gate-003 watchdog objects

| Canonical code name | Kind and scope | Source | Meaning | Defined / consumed |
|---|---|---|---|---|
| `DIAGNOSTIC_ID`, `MATLAB_PATH`, `MATLAB_BATCH` | fixed controller constants | Sections 25.2, 25.4 | Exact create-once ID, MATLAB executable, and list-form batch invocation; no runtime path or argument substitution | watchdog startup; child `exec` |
| `WALL_LIMIT_SECONDS`, `RSS_LIMIT_BYTES` | fixed resource constants | Sections 25.3, 26.4, 27.1 | The only resource uppers: 1800 target-active seconds and 2,147,483,648 aggregate RSS bytes | alarm, loop and aggregate comparison |
| `SAMPLE_INTERVAL_SECONDS` | positive observation interval | Sections 25.4, 26.4 | Nominal 1-second RSS observation spacing; never a pass/fail or stop predicate | watchdog loop sleep |
| `experiment_dir`, `science_dir`, `watchdog_parent`, `external_dir` | fixed absolute paths derived from script location | Sections 25.2, 25.4--25.5, 26.8 | Current experiment directory, MATLAB-owned science namespace, mechanical watchdog parent, and atomically claimed external create-once leaf | collision checks and external writers |
| `samples_partial`, `samples_final`, `summary_final`, `stdout_path`, `stderr_path` | fixed external artifact paths | Sections 25.5, 26.8 | Exact controller-only TSV and child-log artifacts; no file enters the MATLAB science namespace | controller publication and child redirection |
| `exec_status_read`, `exec_status_write`, `exec_release_read`, `exec_release_write`, `release_sent` | anonymous pipe endpoints and logical release state | Sections 26.2--26.3, 27.1, 28.4 | CLOEXEC exec confirmation and `PGID_READY`/`EXEC_GO` release barrier; the release write is adjacent to the sole wall-clock origin, and `release_sent` distinguishes a released but not yet cleanly confirmed target that still requires guarded group cleanup | parent/child handshake and exception cleanup |
| `child_pid`, `dedicated_pgid`, `supervisor_pgid`, `dedicated_pgid_was_verified` | process identity and guard scalars | Sections 26.3, 26.6, 27.2 | MATLAB root PID, equal dedicated group ID, external supervisor group, and immutable two-sided verification flag | release gate, signal handler, guarded group kill |
| `target_start`, `deadline`, `remaining`, `target_stop_time`, `target_dead_time`, `ledger_finalized_time` | monotonic seconds | Sections 26.7, 26.9, 27.1 | One `EXEC_GO`-anchored timestamp, immutable `target_start + 1800` deadline, its positive post-exec remainder, first kill/natural-stop time, separately confirmed target-dead time, and external-ledger completion time; the deadline is never reset or replenished | release, one-shot alarm, inclusive loop comparison, summary and audit stderr |
| `wall_alarm_fired`, `wall_alarm_time`, `alarm_group_kill_sent`, `alarm_guard_failed` | signal-shared controller state | Sections 26.6--26.7, 27.1 | One-shot wall-trigger evidence and guarded immediate group-kill outcome | `SIGALRM` handler and main loop |
| `PS_COMMAND`, `PS_ROW_PATTERN`, `table` | fixed command, grammar and full-table snapshot | Sections 25.3--25.4, 26.4 | Exact `/bin/ps` inventory and unambiguous PID/PPID/PGID/RSS/start/state/command parser | `LOCAL_process_table`; authority and confirmation |
| `root_start_identity`, `known_identity`, `pid_reuse_excluded`, `descendant`, `current_target` | stable-identity inventories | Sections 26.4--26.5, 27.2 | Original root identity, append-only known target identities, explicitly excluded reused PID identities, recursive descendant set, and PID-deduplicated descendant/group/known union | aggregate, PGID invariant, positive cleanup and dead confirmation |
| `aggregate`, `aggregate_peak` | arbitrary-precision byte integers | Sections 25.3, 26.4 | Current full-union RSS and maximum valid observed RSS, computed from KiB with no lower proxy or wrapper substitution | sample rows and summary |
| `final_status`, `stop_reason`, `child_reaped`, `child_blocking_reap_safe`, `child_wait_status`, `child_exit_code`, `child_signal` | terminal controller fields and reap guards | Sections 25.5, 26.2, 26.6, 26.8, 28.4 | External-only lifecycle classification, exact direct-child wait outcome, and the invariant that blocking reap is entered only after the child is already reaped or its exact positive `SIGKILL` was accepted/observed absent; none is interpreted as a representation PASS | target cleanup, nonblocking fail-closed fallback and summary-last commit |
| `sample_header`, `summary_header`, `sample_count`, `unavailable_sample_count` | schema and count state | Sections 25.5, 26.8 | Frozen 11- and 18-column external schemas and their reached row counts | sidecar/stdout mirror and summary |

The §AM postdiagnostic audit records `representation-gate-002` as executed
exactly once and consumed with primary-only reached evidence. Its preserved
external aggregate peak RSS was 1,227,096,064 bytes, below the 2,147,483,648-byte
memory limit. The failure classification is external monitor cadence
noncompliance plus whole-command `real 139.74` seconds exceeding the 120-second
hard wall. It is not a memory or scientific-method failure, creates no retry or
new-ID authority, and does not authorize `run-006`, reference, or effectivity
claims.

The §AS postdiagnostic audit records `representation-gate-003` as executed
exactly once, complete, naturally exited, and permanently consumed. Its external
ledger contains 737 valid samples and zero unavailable samples, target-active
time 761.486755 seconds, and authoritative PID-deduplicated aggregate peak RSS
1,296,187,392 bytes. The exact claim boundary is
`ZERO_EIGENSOLVE_REPRESENTATION_AND_RESOURCE_EVIDENCE_ONLY`: zero scientific
eigensolves and no reference export. The 44.53-minute future-formal forecast and
timing variability remain advisory caveats; `run-006`, retry, reference, and
effectivity work are not authorized.

`LOCAL_preflight_audit` is the explicit preflight-only equivalent path.  It is
an internal stage of the sole formal command, executes no eigensolve, and uses
the same `run_state.start_clock`; it is not a second budget-resetting launcher.

Obvious loop indices, file handles, row counters, and one-expression throwaway
temporaries are intentionally omitted.  The code never uses `i` or `j` as the
imaginary unit; all phase factors use `1i`.
