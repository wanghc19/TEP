# I4.1b P2 FEM symbol ledger

Authority: [[research/projects/eig-apost/implementation/i4/design-4-1b#20. Bounded Section M operational repair and preflight continuation|design §20]] and
[[research/projects/eig-apost/implementation/i4/review-4-1b#M. Post-preflight review of resource-preflight-001/execution-001|review §M]].
Formal `run-001/execution-001` remains prospective and blocked. Preflight
`execution-001` and `execution-002` are both immutable consumed evidence; the
latter ended at the 3 GiB hard RSS stop before any eigensolve.

| Canonical code name | Kind / scope | Draft object and meaning | Type / shape / units | Defined / consumed |
|---|---|---|---|---|
| `run_id`, `$RUN_ID` | fixed identity | formal `run-001` or exact alternate `resource-preflight-001` | text scalar | MATLAB/controllers |
| `execution_id`, `$EXECUTION_ID` | fixed identity | formal `execution-001` or create-once preflight continuation `execution-002`; preflight `execution-001` is not an active input | text scalar | MATLAB/controllers |
| `output_dir`, `work_dir` | current-run paths | execution authority and current-run caches | paths | MATLAB/runner |
| `spec` | immutable source struct | design §§1--8, 15 model, tolerances, grids and schedules | scalar struct | `LOCAL_spec`; science |
| `period`, `radius`, `q_inside`, `q_outside`, `missing_column`, `beta` | spec fields | continuous geometry/material and fixed $\beta$ | real scalars | mesh/forms/phase |
| `search_windows`, `cue_interval`, `guard_interval` | spec fields | $W_0$--$W_3$ and diagnostic intervals | $4\times2$, $1\times2$ | inventory/classification |
| `bulk_alpha_17`, `bulk_alpha_33`, `theta_5`, `theta_9`, `theta_17` | phase grids | exact bulk/defect phase views | real rows, radians | schedules/graph |
| `bulk_main_nev`, `count_nev`, `defect_main_nev`, `defect_expand_nev` | root counts | 40, 48, 48, conditional 60 | integers | eigensolver |
| `eigs_subspace_40`, `eigs_subspace_48`, `eigs_subspace_60` | Arnoldi dimensions | design §15.3 $p=80,96,100$ | integers | eigensolver |
| `planned_bulk_solves`, `planned_defect_solves`, `planned_companion_solves`, `planned_base_solves`, `maximum_solves` | schedule counts | $72+47+5=124$, conditional cap 141 | integers | orchestration/summary |
| `object_allocation_order`, `configuration_priority` | immutable orders | design §15.1 object-ID allocation versus independent canonical rank priority | two seven-name cell rows | inventory/rank |
| `points`, `triangles`, `material_inside` | P1 geometry fields | fitted straight triangulation and triangle material | $V\times2$, $T\times3$, $T\times1$ | mesh/forms/fields |
| `edges`, `triangle_p2`, `p2_points`, `edge_incidence` | P2 topology fields | sorted global edges, six-node connectivity, vertex/midpoint coordinates, incidences | integer/real arrays | topology/forms/fields |
| `reflection_index`, `reflected_edges`, `reflected_edges_found`, `edge_reflection_index`, `edge_count`, `vertex_count`, `p2_reflection_index`, `reflected_p2_points`, `p2_reflection_defect` | reflection maps/check | design §20.1 vertex permutation, exact reflected-edge row permutation and existence flags, combined P2 permutation and independent reflected-coordinate defect | integer/logical columns, counts / real coordinates and scalar | mesh construction/reflection checks |
| `p1_periodic`, `periodic` | phase maps | vertex and vertex-plus-midpoint master/slave maps | structs | prolongations |
| `stiffness_full`, `mass_full` | P2 forms | full $K_2,M_2$ from seven-point degree-five quadrature | sparse Hermitian matrices | assembly/reduction |
| `mass_center`, `mass_core`, `mass_tail` | P2 restricted forms | localization Grams on frozen regions | sparse Hermitian matrices | W3 diagnostics |
| `p1_stiffness_full`, `p1_mass_full`, `p1_mass_center`, `p1_mass_core`, `p1_mass_tail` | companion forms | independently assembled analytic P1 forms on the same polygon | sparse matrices | embedding/companion |
| `quadrature_points`, `quadrature_weights` | local P2 rule | design §3.2 seven barycentric points and normalized weights | $7\times3$, $7\times1$ | assembly/monomial check |
| `basis`, `gradients` | local element values | six P2 Lagrange functions and physical gradients | $1\times6$, $2\times6$ | assembly/field evaluation |
| `embedding_full`, `embedding_reduced` | nested-space maps | $E_{\mathrm{full}}$ and phase-compatible $E_{\mathrm{red}}$ | sparse matrices | design §15.5 checks |
| `prolongation`, `phases` | phase objects | $P_2(\phi)$ or $P_1(\phi)$ and unit-modulus row factors | sparse matrix/vector | reduction/eigensolver |
| `stiffness`, `mass`, `mass_factor` | reduced pair | canonical Hermitian $K(\phi),M(\phi)$ and Cholesky factor | sparse matrices | eigensolver/normalization |
| `start_vector`, `subspace_dimension`, `options` | solver objects | design §15.3 deterministic $v_0$, $p$, exact `eigs` options | complex vector/integer/struct | `LOCAL_low_spectrum*` |
| `eigenvalues`, `frequencies`, `vectors_full`, `residuals`, `cluster_ids` | spectrum fields | $\lambda_j$, $k_j$, complete fields, normalized residuals, whole clusters | vectors/matrix | caches/inventory |
| `bulk_inventory`, `defect_inventory`, `companion_inventory` | run inventories | 72 P2 bulk, 47/64 P2 defect, five P1 companion records | structs | diagnostics/candidates/publication |
| `agreement` | 48/60 authority | frequency, cluster and exact-mass field agreement | struct | design §15.4 |
| `object_id`, `root_indices`, `subspace` | P2 object identity | immutable W3 cluster identity, complete roots and mass-normalized field space | integer/vector/complex matrix | graph/rank/fields |
| `common_core_samples`, `common_core_weights` | cross-mesh representation | true P2 or separate P1 samples and positive $q$-weighted grid weights | complex matrix/real vector | principal overlaps |
| `L0_min`, `Lcore_min`, `tail_max`, `parity_status`, `parity_label` | diagnostics | localization/tail and endpoint $R_2$ compression evidence | scalars/text | rank/classification |
| `tracking.edges`, `tracking.components` | pure-P2 graph | design §§15.1--15.2 directed dummy-augmented assignments and connected components | struct arrays | candidate construction |
| `costs`, `assignment`, `cost_tuple`, `exact_tie` | assignment objects | seven-component summed lexicographic objective and binary64 final tie | numeric tensor/vector | tracking/fixtures |
| `candidate_id`, `realization_ids`, `rank_key` | selection objects | immutable component order and pure-P2 total rank | integers/numeric row | canonical selection |
| `delta_h`, `delta_g`, `delta_N`, `delta_twist`, `delta_algebraic` | P2 sensitivity fields | five observed changes in design §8 | frequency scalars or `NaN` | pure-P2 rank/publication |
| `delta_p1p2`, `delta_ref_obs` | post-rank sensitivities | non-ranking current-run P1--P2 drift and six-term observed sum | frequency scalars or `NaN` | publication only |
| `lambda_ref_p2`, `k_ref_p2` | selected scalars | midpoint of winner-level eigenvalue envelope and positive square root | positive scalars | MAT artifacts/summary |
| `scientific-result.mat`, `fields.mat` | canonical artifacts | compact science authority and field authority | MAT v7.3 | MATLAB/postreview |
| `matlab-terminal.tsv` | transient handoff | minimal terminal/count/scalar record | key/value TSV | MATLAB/runner |
| `$TOTAL_WALL_LIMIT_SECONDS`, `$PRIOR_WALL_SECONDS`, `$WALL_LIMIT_SECONDS` | wall budget | design §20.2 exact 2700 s total, consumed 18.226698 s and remaining 2681.773302 s | seconds | preflight controller |
| `$PRIOR_RSS_BYTES`, `$RSS_LIMIT_BYTES`, `$cumulative_rss_bytes` | RSS budget | design §20.2 prior 1,084,440,576 B, cumulative maximum and sole 3,221,225,472 B hard upper | bytes | preflight controller |
| `$start`, `$deadline`, `$peak_rss_bytes`, `$controller_terminal` | controller state | one monotonic deadline, aggregate RSS peak and frozen non-wall terminal | seconds/bytes/text | runner/resource |
| `$resource_handle`, `$resource_event_index`, `$summary_committed`, `$publication_aborted` | publication state | design §18.2 append-only event descriptor and summary-last commit/latch state | file handle/integer/booleans | both controllers |
| `resource.tsv`, `run-summary.csv` | terminal artifacts | append-only controller-event evidence and atomic summary-last row; preflight continuation exposes prior/current/cumulative wall and prior/current/cumulative-maximum RSS | TSV/CSV | runner/postreview |
| `rows`, `mesh-operators.tsv` | preflight mesh evidence | actual nine-mesh $V,T,B,E$, P1/P2 DOFs and full/reduced operator `nnz` | struct array / TSV | preflight/postreview |
| `arnoldi_capacity`, `return_capacity` | preflight capacities | committed complex $p=100$ and 60-vector representation buffers; no eigenpairs | complex columns | preflight RSS stage |
| `field_capacity`, `sample_capacity` | retained P2 capacities | design §18.1 pessimistic P2 field subspaces and common-grid samples | committed complex columns | both simultaneous preflight stages |
| `companion_pair`, `prior_companion_capacity`, `current_companion_full_capacity`, `current_companion_reduced_capacity`, `companion_arnoldi_capacity`, `companion_metadata_capacity` | companion-lifetime capacities | design §18.1 P1 full/reduced forms and factor, four prior plus current full returns, current reduced return, $p=96$ workspace and compact metadata | structs / committed complex columns | companion-simultaneous preflight stage |
| `source_payload_capacity`, `publication_capacity` | publication-lifetime capacities | design §18.1 compact source-side candidate/companion payload and 512 MiB serialization copy | committed complex columns | publication-simultaneous preflight stage |
| `field_count`, `sample_count`, `source_payload_count`, `companion_bytes`, `publication_bytes` | preflight sizing values | design §18.1 deterministic shape counts and simultaneous internal-byte totals; source payload reserves 64 complex words per possible P2/P1 object | integer counts / bytes | preflight markers and allocations |
| `$summary_handle`, `$summary_partial`, `$elapsed_offset`, `$current_elapsed_offset`, `$cumulative_elapsed_offset` | summary commit state | design §§18.2, 20.2 same-directory temporary summary and fixed-width current/cumulative elapsed fields patched at the final monotonic decision | handle/path/byte offsets | controllers |
| `residency.tsv`, `preflight.log`, `preflight-summary.tsv` | preflight leaves | per-stage internal bytes, largest MATLAB-tree process RSS, authoritative aggregate RSS, stage log, and summary-last terminal | TSV/text | MATLAB/controller/postreview |
