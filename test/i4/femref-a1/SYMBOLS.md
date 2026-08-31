# I4.1a diagnostic-ranking symbol ledger

Authority:
[[research/projects/eig-apost/implementation/i4/design-4-1a#36. 2026-08-31 run-007 diagnostic-ranking reference revision|design §36]]
and [[research/projects/eig-apost/implementation/i4/design-4-1a#37. 2026-08-31 §AX candidate-domain and lifecycle clarification|design §37]].
The exact completed values follow
[[research/projects/eig-apost/implementation/i4/review-4-1a#BB. `run-007/execution-001` post-run artifact/resource/claim review|review §BB]].
Only the minimal consumed `run-007/execution-001` interface is listed.

| Canonical code name | Kind / scope | Source meaning | Type / shape / units | Defined / consumed |
|---|---|---|---|---|
| `run_id` / `$RUN_ID` | fixed identity | exact consumed `run-007` scientific identity | text scalar | MATLAB/runner |
| `execution_id` / `$EXECUTION_ID` | fixed identity | completed create-once `execution-001` leaf; no retry | text scalar | MATLAB/runner |
| `output_dir`, `work_dir` | paths | current execution authority and caches | paths | MATLAB/runner |
| `spec` | immutable struct | Sections 36--37 model, schedules, diagnostics, ranking | scalar struct | `LOCAL_spec`; all science |
| `period`, `radius`, `q_inside`, `q_outside`, `missing_column`, `beta` | spec fields | unchanged continuous model | scalars | mesh/weak form |
| `cue_interval`, `guard_interval`, `search_windows` | spec fields | initial cue, former guard, and $W_0$--$W_3$ | $2$-vectors / $4\times2$ | diagnostic search |
| `bulk_alpha_17`, `bulk_alpha_33`, `count_phases` | spec fields | frozen bulk phase grids | row vectors, radians | bulk schedule |
| `theta_5`, `theta_9`, `theta_17` | spec fields | frozen defect twist grids | row vectors, radians | defect/tracking |
| `bulk_main_nev`, `count_nev`, `defect_main_nev`, `defect_expand_nev` | root counts | 40, 48, 48, conditional 60 | integers | eigensolver schedule |
| `planned_bulk_solves`, `planned_defect_solves`, `planned_base_solves`, `maximum_solves` | schedule counts | 72, 47, 119, 136 | integers | orchestration/summary |
| `attempted_solves`, `completed_solves`, `planned_solves` | run state | completed values 119, 119, 119; no 60-root expansion | integers | MATLAB/summary |
| `points`, `triangles`, `material_inside`, `periodic` | mesh fields | fitted $P_1$ mesh, material, and periodic maps | arrays/struct | mesh/reduction/fields |
| `stiffness_full`, `mass_full`, `mass_center`, `mass_core`, `mass_tail` | mesh fields | full $P_1$ forms and restricted mass forms | sparse matrices | assembly/field diagnostics |
| `prolongation`, `stiffness_raw`, `mass_raw`, `stiffness`, `mass` | phase objects | quasiperiodic reduction and canonical Hermitian pair | sparse matrices | reduction/eigensolver |
| `eigenvalues`, `frequencies`, `vectors_full`, `residuals`, `cluster_ids` | spectrum fields | $\lambda_j$, $k_j$, fields, residuals, multiplicity groups | vectors/matrices | spectra/candidates |
| `bulk_inventory`, `gap_diagnostic`, `count_sentinels` | run objects | 72-solve bulk evidence and non-cancelling diagnostics | structs | classification/publication |
| `defect_inventory.entries` | run objects | 47 base and optional 17 expansion solve records | struct array | candidate generation |
| `root_coverage` | diagnostic | per-configuration ceilings, margins, and covered windows | struct | ranking/classification |
| `object_id`, `seed_candidate_id` | object identities | permanent current-run W3 object and assignment tie identities | positive integers | tracking |
| `subspace`, `common_core_samples`, `common_core_weights` | object fields | mass-normalized field space and overlap representation | complex matrices/vector | tracking/fields |
| `L0_min`, `Lcore_min`, `tail_max`, `parity_label` | object diagnostics | localization, tail, and parity evidence | scalars/text | ranking/classification |
| `edges` | tracking object | maximum-total-overlap one-to-one continuation records | struct array | components/persistence |
| `candidate_id`, `realization_ids` | component identity | 16 rankable components; winner candidate 7 | integer/vector | ranking/publication |
| `n_axes`, `n_config`, `n_theta` | persistence counts | Section 37.1 continuation evidence beyond anchor | nonnegative integers | rank key |
| `delta_fem`, `delta_supercell`, `delta_twist`, `delta_algebraic` | candidate fields | winner values 0.0019799758723477723, $3.3059115711608911\times10^{-5}$, $3.0119180025600656\times10^{-6}$, 0 | frequencies | rank/publication |
| `delta_ref_obs` | candidate field | winner empirical sum 0.0020160469060619413; not certified | frequency | publication |
| `rank_key`, `ordered_candidate_ids` | selection objects | exact projected lexicographic order with no native `NaN` comparison | numeric row / integer vector | selection |
| `publication` | selected realization | `fine`, $\theta=0$, root 11, multiplicity one; eigenvalue envelope $[3.3697100442273502,3.3697321598980357]$, wavenumber envelope $[1.8356769988827963,1.8356830227188015]$ | scalar struct | canonical/fields |
| `lambda_ref_fem`, `k_ref_fem` | selected scalars | 3.3697211020626927 and 1.8356800108032698 | positive scalars | canonical/fields/summary |
| `classification`, `candidate_status`, `resolution_status` | selected labels | cue member, gap-edge/safe-buffer, weakly localized, stable parity, complete empirical resolution, W3 covered; unresolved bulk gap | text/cell | canonical/summary |
| `scientific-result.mat` | single authority | READY result, 119 solves, 16 candidates, winner 7 | MAT v7.3 | MATLAB/postreview |
| `fields.mat` | conditional artifact | winner-7 mass-normalized field on `defect-N5-s24-g48` | MAT v7.3 | MATLAB/postreview |
| `matlab-terminal.tsv` | transient handoff | minimal terminal/count/scalar data | key/value TSV | MATLAB/runner |
| `$WALL_LIMIT_SECONDS`, `$RSS_LIMIT_BYTES` | hard uppers | 2700 s and 2147483648 bytes | integer scalars | runner |
| `$start`, `$deadline`, `$peak_rss_bytes`, `$controller_terminal` | controller state | one absolute deadline, aggregate peak, terminal | seconds/bytes/text | runner |
| `resource.tsv`, `run-summary.csv` | terminal artifacts | natural exit; 140.273679 s and 1353826304 bytes | TSV/CSV | runner/postreview |
