# I4.1a symbol and code-variable ledger

Scope: `test/i4/femref-a1/run_i4_1a.m` only.  This ledger extends, but does not
modify, the project ledger at
`research/projects/eig-apost/implementation/SYMBOL.md`.  Exact source locators
refer to `design-4-1a.md` unless stated otherwise.

## Physical and discretization objects

| Canonical code name | Kind and scope | Draft symbol / source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `spec` | immutable struct, run-wide | Sections 2--12 | Complete source-owned physical, numerical, gate, schema, and budget specification | `LOCAL_spec`; all stages |
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
| `h` | real scalar, local | $h=1/s$, Sections 3.2, 4.2 | Background spacing, length unit | `LOCAL_build_mesh` |
| `n_gamma` | integer scalar | $n_\Gamma$, Sections 3.2, 4.2 | Inscribed regular-polygon segment count | `mesh_spec`; geometry diagnostics |
| `area_deficit` | nonnegative scalar | $\epsilon_{\mathrm{area}}$, Section 3.2 | Relative polygon area deficit | mesh ledger |
| `hausdorff_defect` | nonnegative scalar | $\epsilon_{\mathrm H}$, Section 3.2 | Circle-to-chord sagitta, length unit | mesh gate/ledger |
| `stiffness_full` | real sparse $n\times n$ | $K$, Sections 3.3, 9.2 | Full nodal matrix for $\int\nabla u\cdot\nabla\bar v$ | `LOCAL_assemble_p1`; phase reduction |
| `mass_full` | real sparse $n\times n$ | $M$, Sections 3.3, 9.2 | Full nodal matrix for $\int q u\bar v$ | same; normalization/overlaps |
| `mass_center` | real sparse $n\times n$ | $M_{C_0}$, Sections 5.3, 6.1 | Restricted weighted mass on $C_0$ | `LOCAL_assemble_p1`; mode labels |
| `mass_core` | real sparse $n\times n$ | $M_{|x|<3/2}$, Section 6.1 | Restricted weighted mass on the frozen localization core | same |
| `mass_tail` | real sparse $n\times n$ | $M_{|x|>N-3/2}$, Section 6.1 | Restricted weighted outer-tail mass | same |
| `phase_prolongation` | complex sparse $n\times n_r$ | $P$, Section 3.3 | Maps master nodal values to full values with right/top phase factors | `LOCAL_phase_reduce`; solves |
| `stiffness_reduced` | complex sparse $n_r\times n_r$ | $K_\phi=P^*KP$, Section 3.3 | Hermitian quasiperiodic stiffness | `LOCAL_phase_reduce`; `LOCAL_low_spectrum` |
| `mass_reduced` | complex sparse $n_r\times n_r$ | $M_\phi=P^*MP$, Section 3.3 | Hermitian positive-definite quasiperiodic mass | same |
| `phase_x` | real scalar, solve-local | $\alpha$ or $\vartheta$, Section 3.1 | Longitudinal Bloch/supercell phase, radians | solve schedules; phase reduction |

## Spectrum, branch, and resolution objects

| Canonical code name | Kind and scope | Draft symbol / source | Meaning; type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `spectrum` | struct, one solve | $(\lambda_j,u_j)$, Section 5.1 | Ordered requested eigenvalues, frequencies, normalized full fields, residuals, clusters, solver diagnostics | `LOCAL_low_spectrum`; inventories/tracking |
| `eigenvalue` | positive real scalar | $\lambda_j$, Sections 2, 5.1 | Generalized FEM eigenvalue, frequency squared | eigensolver; ledgers |
| `frequency` | positive real scalar | $k_j=\sqrt{\lambda_j}$ | Positive frequency | inventories, envelopes |
| `algebraic_residual` | nonnegative scalar | $r_{\mathrm{alg}}$, Section 5.1 | Scale-normalized generalized eigen-residual | eigensolver hard gate |
| `cluster` | struct, one slice | multiplicity-$m$ cluster, Sections 5.1, 5.3 | Ordered root indices, dimension, frequency envelope, and full $M$-orthonormal subspace | `LOCAL_make_clusters`; continuation/labels |
| `branch` | struct, one configuration | observed branch/cluster $j$, Sections 5.3--7 | Dimension-stable across-twist cluster with slice envelopes, fields, Gram spectra, parity, and continuation records | `LOCAL_track_twists`; coverage/resolution |
| `restricted_gram` | Hermitian $m\times m$ | $G_D(U)=U^*M_DU$, Sections 5.3, 6.1 | Basis-covariant regional mass compression; only eigenvalue extrema enter gates | `LOCAL_label_branch` |
| `parity_spectrum` | real length-$m$ vector | $\operatorname{spec}(U^*M\mathcal R_xU)$, Section 5.3 | Basis-invariant anchor parity multiset | same |
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
| `peak_estimate_gib` | nonnegative scalar | Section 12.1 | Safety-scaled symbolic-fill/workspace/cache/export estimate with the 1.2-GiB design floor; not measured RSS | resource gate |
| `symbolic_factor_nnz` | nonnegative integer per mesh | Section 12.1 implementation preflight | `sum(symbfact(spones(K)+spones(M)+I))`; symbolic sparse-factor fill estimate, not measured numeric fill | `LOCAL_resource_preflight`; resource artifacts |
| `workspace_40_bytes`, `workspace_48_bytes` | nonnegative scalars per mesh | Sections 5.1, 12.1 | Complex sparse-pair, symbolic factor, Arnoldi basis, requested eigenvectors, and full-field workspace estimates for the frozen 40/48-root solves | `LOCAL_workspace_bytes`; resource artifacts |
| `runtime_safety_factor` | real scalar | Section 12 implementation audit | Frozen implementation accounting factor `1.25`, applied to category wall and memory estimates before the design floors | `LOCAL_resource_preflight` |
| `resource_preflight` | run-wide struct | Sections 9.1, 12, 13.3 | Pre-eigensolve audit containing every mesh fill estimate, 72/47 category wall ledger, current-run cache/export costs, forecast, and pass flag | `LOCAL_preflight_audit`; `resource-preflight.mat`, `run-summary.mat` |
| `mesh_diagnostic` | per-mesh publication struct | Sections 9.1, 10.2; review §O.4 | Incrementally reached mesh counts, geometry diagnostics, assembly nonzero counts, and reflection defects; unavailable later-stage values remain `NaN` | `LOCAL_initial_mesh_diagnostic`; `LOCAL_build_mesh`; `LOCAL_mesh_diagnostic_row` |
| `prior_mesh_rows`, `prior_seam_rows` | stage-local checkpoint inputs | Sections 9.1, 10.2; review §O.4 | Completed current-run mesh and seam rows carried across a later mesh failure so MATLAB value semantics cannot discard them | `LOCAL_mesh_oracles`; `LOCAL_build_mesh`; mesh checkpoint helpers |
| `reached_boundary` | mesh-ledger character column | Sections 9.1, 10.2; review §O.4 | Last completed diagnostic boundary for a success or expected mesh failure, such as `REFLECTION_MATRIX_ORACLE` | `LOCAL_mesh_diagnostic_row`; `mesh-ledger.csv` |
| `failure_mesh_rows` | stage-local cell matrix | Sections 9.1, 10.2; review §O.4 | Completed rows plus the current partial failure row, all carrying the immutable first mesh failure code/reason | `LOCAL_checkpoint_mesh_failure`; `mesh-ledger.csv` |
| `required_functions` | environment-audit cell array | Section 13.1 operational dependency gate | Ordinary base-MATLAB functions checked with `exist(...,'file'/'builtin')`; excludes class constructors and class methods | `LOCAL_check_environment` |
| `required_classes` | environment-audit cell array | Section 13.1 operational dependency gate | Required geometry classes checked with `exist(...,'class')` | `LOCAL_check_environment` |
| `triangulation_methods` | environment-audit cell array | Section 13.1 operational dependency gate | Public method inventory for the `triangulation` class; must include the actually used `pointLocation` method | `LOCAL_check_environment` |

`LOCAL_preflight_audit` is the explicit preflight-only equivalent path.  It is
an internal stage of the sole formal command, executes no eigensolve, and uses
the same `run_state.start_clock`; it is not a second budget-resetting launcher.

Obvious loop indices, file handles, row counters, and one-expression throwaway
temporaries are intentionally omitted.  The code never uses `i` or `j` as the
imaginary unit; all phase factors use `1i`.
