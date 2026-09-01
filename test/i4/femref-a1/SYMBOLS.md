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

## Prospective run-008 additions

These names are source-level interfaces from design §§43--44. They have not
produced numerical values.

| Canonical code name | Kind / scope | Source meaning | Type / shape / units | Defined / consumed |
|---|---|---|---|---|
| `run_i4_1a_refine`, `run_refine_formal.pl` | fixed entries | isolated `run-008` MATLAB entry and no-argument controller | source files | MATLAB/runner |
| `run_id`, `execution_id` | fixed identities | `run-008`, first create-once `execution-001` | text scalars | MATLAB/runner |
| `mesh_spec` | mesh definition | $(N,s,g)=(5,30,60)$, ID `defect-N5-s30-g60` | scalar struct | mesh builder |
| `theta_5` / $\Theta_5$ | twist schedule | $(0,\pi/4,\pi/2,3\pi/4,\pi)$ in fixed order | $1\times5$, radians | spectrum schedule/tracking |
| `requested_nev` | root count | exactly 48 generalized eigenpairs per twist | positive integer | eigensolver |
| `solve_ledger` | current-run inventory | five solve identities, validity, ceiling, coverage, and compact spectra | $1\times5$ struct | science/fields/summary |
| `raw_subspace`, `subspace` | W3 object fields | whole-cluster source field and full-mass-normalized field | complex matrices | object/fields |
| `common_core_samples`, `common_core_weights` | W3 object fields | fixed-grid samples and positive quadrature weights | complex matrix / real vector | assignment/fields |
| `n_twists`, `n_edges` | persistence fields | represented twists and adjacent continuation edges | nonnegative integers | rank key |
| `missing_refinement_count`, `finite_drift_sum` | projected refinement fields | four absent cross-configuration changes give 4 and 0 | integer / frequency | rank key |
| `covered_slices`, `ceiling_margin` | coverage diagnostics | component twists whose 48th root covers $W_3$ and their minimum margin | integer / frequency | rank/classification |
| `rank_key` | total-order key | §43.2 pure-FEM lexicographic projection with explicit missing-value mapping | numeric row | candidate selection |
| `publication.lambda_envelope` / $\Lambda_{30}$ | winning envelope | all valid eigenvalues in the first-ranked component | positive interval / set | canonical publication |
| `lambda_30`, `k_30` | winning scalars | $(\min\Lambda_{30}+\max\Lambda_{30})/2$ and $\sqrt{\lambda_{30}}$ | positive scalars | canonical/fields/summary |
| `scientific-result.mat` | canonical authority | frozen spec, solve ledger, compact W3 inventory, tracking, rank, winner | MAT v7.3 | MATLAB/postreview |
| `fields.mat` | field authority | all retained W3 full subspaces and common-core data at the five twists | MAT v7.3 | MATLAB/identity review |
| `$WALL_LIMIT_SECONDS`, `$RSS_LIMIT_BYTES` | hard uppers | 2700 s and 3221225472 bytes, inclusive | integer scalars | `run_refine_formal.pl` |

## Prospective reviewer identity-audit additions

These names follow design §§46--54 and review §BO. `identity-001` and
`identity-002` are immutable consumed operational failures with no identity
result; `identity-003` is prospective and has not been created or executed.

| Canonical code name | Kind / scope | Source meaning | Type / shape / units | Defined / consumed |
|---|---|---|---|---|
| `OLD_SCHEMA`, `NEW_SCHEMA`, `NEW_FIELDS_SCHEMA`, `AUDIT_SCHEMA`, `AUDIT_ID` | schema identities | exact allowlisted MATLAB inputs, RFC 8259 output, and fixed prospective `identity-003` authority | text constants | `identity_audit.py` |
| `TARGET_THETA_INDICES`, `TARGET_SOLVE_IDS`, `TARGET_PHASES` | candidate-7 selection | old fine indices $(1,5,9,13,17)$, exact caches, and phases $(0,\pi/4,\pi/2,3\pi/4,\pi)$ | five-element tuples | decoder/audit |
| `interpolation`, `old_weights` | common-grid representation | deterministic $P_1$ barycentric map and positive $q$-weighted trapezoid rule on the retained $161\times65$ grid | row map / positive vector | old field reconstruction |
| `gram`, `lower`, `normalized` | linear-algebra objects | $G=S^*WS$, its positive Cholesky factor, and right-normalized sample space | complex square matrices / sample matrix | overlap calculation |
| `overlaps`, `singular_values`, `distances` | per-twist evidence | $O_{ij}=\min\sigma(\widehat S_i^*W\widehat S_j)$, full principal values, and frequency tie distances | real matrices / nested vectors | assignment/JSON |
| `costs`, `assignment`, `total_cost` | matching objects | complete dummy-augmented six-component costs and lexicographically minimum componentwise sum | tuple matrix / permutation / six-vector | assignment/JSON |
| `candidate7_identity_status`, `selection_relation` | audit decisions | exact §§46--47 identity and canonical-selection relation vocabularies | text | `identity-audit.json` |
| `lambda30_candidate7`, `k30_candidate7` | conditional derived values | midpoint of the matched five-realization eigenvalue envelope and its positive square root | positive scalars or JSON `null` | `identity-audit.json` |
| `$AUDIT_WALL_LIMIT_SECONDS`, `$RSS_LIMIT_BYTES` | only audit resource uppers | 2637.027949 s remaining and 3221225472 bytes aggregate process-tree RSS, inclusive | positive scalars | `run_identity_audit.pl` |
| `$SCIENTIFIC_WALL_SECONDS`, `$REVIEW_WALL_SECONDS`, `$IDENTITY001_WALL_SECONDS`, `$IDENTITY002_WALL_SECONDS` | consumed wall charges | 35.917169 s, 25.000000 s, 0.001110 s, and 2.053772 s included before current `identity-003` wall | seconds | `resource.tsv` |
| `$SCIENTIFIC_PEAK_RSS_BYTES`, `$REVIEW_PEAK_RSS_BYTES`, `$IDENTITY001_PEAK_RSS_BYTES`, `$IDENTITY002_PEAK_RSS_BYTES`, `$peak_rss_bytes` | five-stage peak accounting | scientific, review, consumed identity peaks 0 and 966656 bytes, and current `identity-003` peak combined by maximum | bytes | `resource.tsv` |

## Prospective profile-001 additions

These names implement design §56 and review §BR. `profile-001` has not been
created or executed.

| Canonical code name | Kind / scope | Source meaning | Type / shape / units | Defined / consumed |
|---|---|---|---|---|
| `s_values`, `k_values` | frozen inputs | $s=(12,18,24,30)$ and the four candidate-7 identity-component FEM scalars | $1\times4$ integer / frequency rows | `profile_postprocess.m` |
| `k30_prediction`, `k_bie_late`, `old_distance` | frozen inputs | pre-registered prediction, late positional scalar, and old comparison distance | frequency scalars | direct diagnostics |
| `signed_drifts`, `absolute_drifts` | direct diagnostics | finer-minus-coarser $d_{12\to18},d_{18\to24},d_{24\to30}$ and their magnitudes | $1\times3$ frequency rows | JSON |
| `ratio_1`, `ratio_2` | direct diagnostics | successive absolute-drift ratios with explicit zero-denominator status | scalar structs | JSON |
| `start_x_values`, `fit_ledger` | profile state | seven fixed $x_0$ values and economy-QR/fminsearch endpoints | $1\times7$ row / struct array | selection/JSON |
| `design_matrix`, `Q`, `R`, `coefficients`, `SSE` | variable projection | $A=[\mathbf 1,s^{-p}]$, economy QR, $(k_\infty,C)$, and residual sum of squares | real matrices/vectors/scalar | `LOCAL_fit_at_x` |
| `winner_start_index`, `winner`, `fit_status` | profile result | lexicographic minimum by $(\mathrm{SSE},p,\text{start index})$ and resolved/unresolved status | integer or null / struct / text | JSON |
| `late_bie_distance` | positional diagnostic | $|k_{30}^{(7)}-k_{\mathrm{BIE}}|$ used only in the strict comparison with `old_distance` | frequency | JSON |
| `$PROFILE_ID`, `$PRIOR_WALL_SECONDS`, `$PROFILE_WALL_LIMIT_SECONDS` | fixed lifecycle/wall state | `profile-001`, 92.655067 s prior charge, and 2607.344933 s remaining | text / seconds | MATLAB/runner/resource |
| `$PRIOR_PEAK_RSS_BYTES`, `$RSS_LIMIT_BYTES`, `$peak_rss_bytes` | resource state | 1073594368-byte prior peak, 3221225472-byte hard upper, and current aggregate peak | bytes | runner/resource |
