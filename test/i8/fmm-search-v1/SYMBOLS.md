# I8.4 FMM search symbol ledger

The governing source is
`research/projects/eig-apost/implementation/i8/design-8-4a.md`.  Types and
shapes below describe MATLAB values unless stated otherwise.

| Code name | Kind and scope | Source / meaning | Type, shape, units | Defined / consumed |
|---|---|---|---|---|
| `k` | point input | finite-grid wavenumber | real scalar | `confirm_fmm_i8.m`; `fmm_i8_point` |
| `requested_eps` | frozen parameter | requested FMM2D tolerance | positive scalar | both MATLAB entries |
| `wide_first`, `wide_step`, `wide_count` | frozen search parameters | 33-node wide grid from 1.45 to 2.25 | scalars; wavenumber/count | `search_fmm_i8.m` |
| `refine_count` | frozen search parameter | nodes in each local closed grid | integer scalar | `search_fmm_i8.m` |
| `width_target` | stopping parameter | accepted complete-round actual span | scalar, wavenumber | `search_fmm_i8.m` |
| `max_refinement_rounds` | resource guard | fault guard, not a scientific platform rule | integer scalar | `search_fmm_i8.m` |
| `evaluation_rows` | point ledger | all I8.4 evaluations in execution order | structure vector | search and output artifacts |
| `outer_seconds` | point field | wall time around the complete `fmm_i8_point` call | nonnegative scalar, seconds | both MATLAB entries |
| `point_seconds` | point field | internal frozen numerical-chain time | nonnegative scalar, seconds | `fmm_i8_point`; both entries |
| `adef_sigma`, `adef_ratio`, `aphys_sigma`, `aphys_ratio` | point fields | four matching-matrix metrics from one call | nonnegative scalars | `fmm_i8_point`; ledgers |
| `round_rows` | round ledger | observed grid geometry, winner, platform, and repeat evidence | structure vector | search and output artifacts |
| `requested_step` | round field | requested adjacent spacing before binary64 construction | scalar, wavenumber | grid construction / round ledger |
| `actual_W` | round field | actual last node minus actual first node | scalar, wavenumber | stopping rule |
| `spacing` | round field | complete actual `diff(k)` vector for one grid | real row vector, wavenumber | grid audit / round ledger |
| `min_spacing`, `max_spacing` | round fields | extrema of actual `diff(k)` | scalars, wavenumber | round ledger |
| `left_gap`, `right_gap`, `neighbor_w` | round fields | actual winner-neighbor gaps and their sum | scalars, wavenumber | next bracket / round ledger |
| `round_best` | round field | current round minimum `aphys_ratio` | scalar | next-round winner |
| `cumulative_best` | round field | minimum over only new I8.4 evaluations so far | scalar | platform diagnostic / final winner |
| `round_best_abs_improvement`, `round_best_relative_change` | round fields | prior round minimum minus current minimum, and that difference divided by the prior minimum | scalars | round-depth audit |
| `cumulative_abs_improvement` | round field | prior cumulative minimum minus current cumulative minimum | scalar | platform diagnostic |
| `relative_improvement` | round field | `(prior-current)/prior` for cumulative best | dimensionless scalar | platform diagnostic |
| `below_5pct_streak` | platform state | consecutive completed refinement transitions below 5% | integer scalar | platform diagnostic |
| `platform_candidate` | round field | third consecutive below-5% transition | logical scalar | evidence only |
| `platform_confirmation` | round field | next-round pending/confirmed/rejected state | character vector | evidence only |
| `selection_mode` | round field | wide dip or local stable-first rule used for the bracket winner | character vector | round ledger |
| `global_winner_index`, `global_winner_k` | round fields | stable first global score minimum in that complete grid | integer / scalar | round ledger |
| `global_tie_indices`, `global_tie_distinct_k_count` | round fields | all exact-score ties and their distinct actual nodes | integer row vector / integer scalar | tie disclosure |
| `strict_dip_indices` | round field | all interior indices strictly lower than both neighbors | integer row vector | wide selection / curve audit |
| `repeat_k_count`, `repeat_metrics_bitwise`, `repeat_max_abs_diff` | round fields | repeated prior nodes, exact four-metric agreement flag, and maximum absolute difference | integer / logical / scalar | determinism audit |
| `is_width_shrinking_transition`, `platform_transition_counted` | round fields | whether the grid shrank and whether that transition updated the platform state | logical scalars | platform audit |
| `winner` | final record | stable first cumulative argmin over all successful new evaluations | scalar structure | result / new-process literal |
| `budget_charge_seconds` | monitor field | wall time of any launched MATLAB process charged to the shared budget | seconds | `monitor.sh` status ledger |
| `peak_task_tree_rss_bytes` | monitor field | sampled peak RSS of the launched process tree | bytes | `monitor.sh` status ledger |
