# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project summary

MATLAB codebase for **Bloch-mode eigenvalue, scattering, and transmission problems** in 2D periodic dielectric waveguides with y-periodicity. The core approach: a trace-matching framework coupling Rayleigh expansions in empty regions to Bloch-mode expansions in periodic half-leads, where the lead-cell BIE uses the **augmented Method of Fundamental Solutions (MFS)** (proxy sources + plane-wave expansions) for the quasi-periodic exterior Green function.

The active branch `bloch` extends the original 1D-waveguide TEP work (archived in `waveguide_1d/`) to include: Bloch far-field extraction, empty-defect-cell eigenproblems, point-source forced scattering, and reusable scan/refine infrastructure.

## How to run

No build step. Open MATLAB, `cd` to the repo root, and run any top-level script by name:

```matlab
bloch_test_F               % Test Bloch far-field extractor matrices F_L, F_R
bloch_test_S               % Test Bloch cell scattering matrix S_cell
bloch_test_modes           % Test Bloch mode eigensolve (S_cell -> eigenvalues/vectors)
bloch_test_empty_cell      % End-to-end test: empty-defect Bloch matching system smoke test
tep_1d_scan_local          % Recursive local scan for the 1D waveguide TEP
tep_edc_scan_local         % Recursive local scan for the empty-defect-cell cavity eigenproblem
scat_edc_ps                % Point-source forced scattering in an empty-defect cell
tep_edc_projected_gap_scan % Pre-scan: find k intervals where the lead crystal has no x-propagating Bloch multiplier
test_qpgreen_axis_swap     % Smoke test: qpgreen_mfs y-periodic axis-swap consistency
```

Legacy 1D TEP scripts (Kress quadrature, KR comparisons, convergence studies) live in `waveguide_1d/` and are not maintained on this branch.

**Never run MATLAB automatically.** After code changes, tell the user which script to run and what outcome to expect. Use Octave via `conda run -n octave octave --eval "script_name"` for rough sanity checks only.

## Architecture

### Package structure

```
+bloch/     Bloch mode computations
  rayleigh_channels   -- builds Rayleigh channel struct (gamma_m, beta_m, K, etc.)
  construct_S         -- builds the single-cell scattering matrix S_cell
  solve_modes         -- eigen-decomposes S_cell to find Bloch modes
  mode_traces         -- extracts Dirichlet/Neumann port traces from Bloch modes
  select_port_traces  -- selects outgoing half-lead trace bases from Bloch modes
  farfield_extractors -- builds Rayleigh extraction matrices F_L, F_R
  incident_rhs        -- builds incident Rayleigh RHS for forced problems

+kernel/    Quasi-periodic Green functions (MFS)
  precomp_proxy         -- precomputes MFS proxy coefficients
  qpgreen_mfs           -- evaluates QP Green function at target points
  qpgreen_mfs_pairmat   -- vectorized pair-matrix version of qpgreen_mfs
  h2d_directch          -- 2D Helmholtz direct evaluation
  kress_l_splits / kress_mn_splits -- Kress quadrature ingredients

+scan/      Generic 1D scalar scan and refinement infrastructure
  scan_then_refine      -- coarse scan, dip selection, recursive refinement
  refine_interval       -- multi-level interval-halving refinement
  eval_grid             -- evaluate objective on grid with per-point error catching
  find_dip_intervals    -- identify local-minimum dip candidates
  choose_dip_interval   -- select one dip (global_min / index / nearest)
  build_refined_interval -- shrink interval around current best point
  default_options       -- default parameters for scan/refine control
  print_summary         -- report scan results in tabular format

+geom/      Geometry construction and caching
  construct_cont        -- builds boundary discretization C for given shape
  build_geometry_cache  -- caches geometry evaluations
  get_geometry_from_cache -- retrieves cached geometry

+op/        Boundary integral operators
  construct_A_QP        -- assembles the QP BIE system matrix A_QP for one cell

+quad/ +utils/   Kress quadrature and special-function utilities
```

### Workflow chain (empty-defect cavity / scattering)

```
kernel.precomp_proxy        -- precompute proxy once
       ↓
bloch.rayleigh_channels      -- build Rayleigh channel for given k, beta, d, M
       ↓
op.construct_A_QP            -- assemble BIE matrix for one periodic lead cell
bloch.farfield_extractors    -- build extraction matrices F_L, F_R
bloch.construct_S            -- form S_cell = [S11 S12; S21 S22]
bloch.solve_modes            -- eigendecompose S_cell -> Bloch modes (lambda, V)
bloch.mode_traces            -- extract D_out, N_out trace bases
bloch.select_port_traces     -- select outgoing modes by port-direction filter
       ↓
LOCAL_assemble_empty_defect_matrix  -- build 4-block trace-matching matrix
       ↓
svd (eigenproblem) or backslash (forced scattering)
       ↓
scan.scan_then_refine (eigenproblem) or residual check (scattering)
```

### Key parameters (shared across top-level scripts)

- `beta`: y-quasiperiodic Bloch phase; Rayleigh basis uses `beta_m = beta + 2*pi*m/d`
- `d`: y-period
- `L`: x-period of one lead cell
- `M`: Rayleigh truncation half-width; total channels `K = 2*M+1`
- `ntot`: number of boundary discretization nodes per cylinder
- `flag_geom`, `radius`: geometry selector and size passed to `geom.construct_cont`
- `pars2`: MFS proxy parameters (H, proxy_dist, N_side, N_top, N_proxy_edge, M_pw)

## File naming conventions (from README.md)

Pattern: `<prefix>_<task>[_model][_qualifier].m`

| Prefix | Meaning |
|---|---|
| `tep_` | eigenvalue/resonance problems (broad sense, includes EDC cavity) |
| `bloch_` | Bloch mode tests or Bloch-mode workflows |
| `scat_` | scattering / forced response (not `scatt`) |
| `bie_` | boundary integral equation / operator assembly |
| `test_` | fallback for standalone validation scripts |

Model abbreviations: `1d`, `edc` (empty defect cell), `mc` (missing column), `lead`, `pc`.

Task abbreviations: `scan`, `local`, `global`, `test`, `ps` (point-source), `trmatch` (trace matching), `conv` (convergence).

Package functions inside `+pkg/` do not need top-level prefixes.

## Research workspace

The `research/` directory holds theoretical work still under investigation, with its own authority hierarchy and rules (see `research/AGENTS.md`). Key structure:

- `research/archive/` — frozen historical mainlines (non-authoritative unless a task explicitly selects them)
- `research/projects/` — independent专题 investigations; currently active: `eig-apost/` (BIE-DtN posterior error estimator for guided-mode eigenvalues)
- `research/planning/` — nascent ideas and research strategy
- `research/tmp/` — disposable derivations (normally untracked)

The Müller-Cauchy unified theory mainline is frozen at git tag `mainline-muller-cauchy-2026-07-26` and moved to `research/archive/muller-cauchy-2026-07/`. There is currently no active `research/mainline/`. Do not create one without explicit review.

Literature PDFs referenced by research tasks are accessed through the repo-root
`ref/ref_data/` directory and named `<FirstAuthorSurname><PublicationYear>.pdf`.

## Code conventions (from AGENTS.md)

- 2-space indentation; comments in English
- Local helper functions prefixed with `LOCAL_`
- New files must have a header comment block: Purpose, Main algorithm, Based on, Main changes, Numerical goal
- Stage comments: `% --- stage N: brief description ---`
- Prefer readable vectorization; preserve numerical behavior up to floating-point roundoff
- Do not change the mathematical model unless asked
- Top-level scripts should be function files (not scripts) so Octave handles local helpers reliably
- After edits, report what changed and which MATLAB command to run for validation
