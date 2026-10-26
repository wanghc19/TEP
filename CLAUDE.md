# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

## Instruction files to read first

Claude Code does not load `AGENTS.md` files automatically, but they are binding here:

- `AGENTS.md` (repo root): applies everywhere. It covers code style, MATLAB source documentation, LaTeX cleanup, validation, and the output contract.
- `test/AGENTS.md`: read before planning, creating, debugging, or running anything under `test/`. It covers run budgets, attempt lifecycle, and MATLAB runtime portability.
- `research/AGENTS.md`: read before touching `research/`. It covers authority order, research depth, notation, naming, temporary material, and handoff.
- `ref/AGENTS.md`: read before adding, renaming, or removing references.

If this file and an `AGENTS.md` disagree, the `AGENTS.md` wins. The key rules are summarized below.

## Project summary

This is a MATLAB codebase plus research workspace for **2D periodic dielectric waveguides with $y$-periodicity**. The topics are Bloch-mode eigenvalue problems, transmission eigenvalue problems (TEP), forced scattering, and line-defect guided modes. The core numerical framework is trace matching. It couples Rayleigh expansions in homogeneous regions to Bloch-mode (outgoing Cauchy/trace) expansions in periodic half-leads. Each lead-cell BIE is a Müller system. Its quasi-periodic Green function comes from the **augmented Method of Fundamental Solutions** (proxy sources plus plane-wave expansions).

The current activity is mostly research. The project `research/projects/eig-apost/` studies **a posteriori error estimation for fixed-$\beta$ line-defect guided-mode eigenvalues**. Its two end goals are:

1. Produce a numerical candidate for a continuous eigenvalue.
2. Estimate, and ideally bound, the candidate's distance to the true spectrum.

The project runs in stages I1–I9. Each stage's experiments live under `test/i*/`; its design and review notes live under `research/projects/eig-apost/implementation/i*/`. Later stages add curved-$P_2$ FEM reference solves, FMM-accelerated pipelines, and spectral-distance estimates with RT2 fluxes. The production packages are **not** modified by this research.

For the current status, read `research/STATUS.md` and `research/projects/eig-apost/STATUS.md`. For the current I9 state, read `research/projects/eig-apost/implementation/i9/README.md`. Do not rely on numbers copied elsewhere.

## Repository layout

```
+bloch/   Bloch-mode data for one periodic lead cell (Rayleigh channels, S_cell, modes, traces)
+kernel/  Free-space and quasi-periodic Helmholtz Green functions (augmented MFS), Kress splits
+op/      construct_A_QP: quasi-periodic Müller BIE matrix for one cell
+geom/    Contour construction (star / ellipse / circle), inside tests, geometry cache
+scan/    Generic 1D scalar scan + recursive dip refinement
+quad/    Kress product quadrature weights (quad_kress_rvec)
+utils/   Bessel/Hankel derivatives, trigonometric interpolation grid
+viz/     Column-lattice plotting helpers (geometry, cell grids, masks, tiles, overlays)

*.m (root)   Maintained top-level workflows (see "How to run")
benchmark/   bloch/: Bloch package tests; qpgreen/: MFS vs Ewald/Linton QP-Green benchmarks
crystal_2d/  Doubly-periodic perfect-crystal validation scripts (not production solvers)
waveguide_1d/ Legacy 1D TEP scripts (Kress, K-R comparisons, convergence); not maintained
test/        Agent experiments: test/i1 ... test/i9 (eig-apost stages), test/archive/legacy-route-v1
research/    Theory workspace (Chinese-language notes, Obsidian vault): projects/, planning/, archive/
draft/       Paper draft "A Boundary Integral Trace-Subspace Formulation for Periodic
             Line-Defect Waveguides" (draft.tex, appendixA.tex) + draft/examples/ run scripts
pre/         Presentations (pre1–pre3) and the LaTeX report (pre/report/)
legacy/notes Historical theory/implementation notes (Bloch modes, scattering formulations, MFS, Kress)
ref/         Reference catalog (README.md, reference.bib); PDFs via ref/ref_data/ (symlink, untracked)
.agents/skills  Shared agent skills: rigorous-proof, notation-discipline, commit-draft
.codex/      Codex agent role configs (not used by Claude Code)
tmp/         Untracked scratch (ignored by git)
```

Every package directory except `+op`, `+quad`, and `+utils` has a `README.md`. Each one documents the public functions, data structures, conventions, and a typical workflow. Read the relevant one before changing or calling a package.

## How to run

There is no build step. Start MATLAB at the repo root. Root scripts are function files you can call by name:

```matlab
tep_1d_scan_local            % Recursive local sigma_min scan for the 1D waveguide TEP
tep_edc_projected_gap_scan   % Pre-scan: k intervals where the lead crystal has no |lambda|=1 Bloch multiplier
tep_edc_scan_local           % Recursive local scan for the empty-defect-cell (missing-column) cavity problem
scat_edc_ps                  % Empty-defect forced scattering driven by a center point source
scat_edc_lead_in             % Empty-defect scattering driven by an incoming lead Bloch mode
scat_ld_lead_in              % Lead-incoming scattering with a dielectric obstacle in the center cell
```

Scripts in subdirectories need the repo root on the path, so call `addpath(pwd)` from the root first. Some scripts do this themselves, for example `benchmark/qpgreen/*` and `draft/examples/*`.

```matlab
bloch_test_F, bloch_test_S, bloch_test_modes, bloch_test_empty_cell   % benchmark/bloch/
test_qpgreen_axis_swap, qpgreen_linton_tables, qpgreen_mfs_eval_bench % benchmark/qpgreen/
run_tep_band_structure, run_tep_fixed_beta_k_scan                     % draft/examples/
```

Each `test/i*/<experiment>/` directory has a README that gives its entry point and the exact reproduction command. Some recent experiments are started through a Python or shell launcher that monitors MATLAB, for example `test/i9/fem-bound-v1/run_bound.py`, `test/i8/pipeline-v1/run_pipeline.py`, and `test/i7/run_matlab_monitored.sh`. The index `test/README.md` covers I1–I3. For later stages, use `research/projects/eig-apost/implementation/README.md` and the stage READMEs.

### MATLAB / Octave policy

- The local install is MATLAB R2023b at `/Applications/MATLAB_R2023b.app/bin/matlab`. In zsh, `matlab` is an alias, so use the full path in non-interactive commands. Run it non-interactively with `-batch "..."`.
- Validate numerically in MATLAB. MFS workflows and anything that depends on MATLAB-specific behavior (for example `lsqminnorm`) **must** be validated in MATLAB.
- Before launching a run under `test/`, estimate its wall time and peak memory. The default budget is 30 min soft, 40 min hard, and 2 GiB, unless the user authorizes a different budget in advance. See `test/AGENTS.md`.
- Use Octave only as a fallback rough sanity check: `conda run -n octave octave --eval "..."`. Interactive fallback is `conda activate octave` followed by `octave --no-line-editing`. Never treat an Octave result as final validation, and never use Octave plotting or GUI.
- Never claim MATLAB was run unless it actually was. Report MATLAB and Octave commands and results separately.
- The Conda environment `octave` is also the project's Python environment.

## Core workflow chain (empty-defect cavity / scattering)

```
kernel.precomp_proxy(pars1, pars2)                 -- MFS proxy, once per (k, beta, d)
bloch.rayleigh_channels(k, beta, d, M, L)          -- beta_m, gamma_m (imag >= 0), phase = exp(i gamma_m L)
geom.construct_cont(ntot, flag_geom, 0, 0, radius) -- 6 x ntot contour matrix C, curvelen
bloch.construct_S(C, kext, kint, pars1, proxy, curvelen, rayleighchan, X_L, X_R)
    -> op.construct_A_QP, bloch.incident_rhs, bloch.farfield_extractors, multi-RHS solve
bloch.solve_modes(S_cell, opts)                    -- generalized eigenproblem A_sc v = lambda B_sc v
bloch.mode_traces(lambda, V, rayleighchan)         -- wall Dirichlet / x-derivative traces
bloch.select_port_traces(modes, traces, '+'|'-')   -- outgoing trace bases per center port
    -> LOCAL_ trace-matching assembly in the top-level script
    -> svd + scan.scan_then_refine (eigenproblem)  |  backslash + residual check (forced)
```

## Conventions that are easy to get wrong

- **L/R and +/- mean different things.** `L`/`R` are the left and right walls of *one lead cell*. `+`/`-` are the center ports and the positive and negative half-leads. `c^+`/`c^-` are right-going and left-going center Rayleigh coefficients, not leads.
- `S_cell` convention: `[b^L; a^R] = [R_L, T_RL; T_LR, R_R] * [a^L; b^R]`. Here `a` is the right-going amplitude and `b` is the left-going amplitude. The direct cell phase is added only to the transmission blocks, inside `construct_S`.
- The BIE density is `eta = [tau; -sigma]`. `F_L` and `F_R` map `eta` to *scattered* outgoing coefficients only.
- Rows of the contour matrix `C`: `x, x', x'', y, y', y''`. The outward normal is `(y', -x')/speed`, using counter-clockwise orientation.
- `kernel.precomp_proxy` uses computational coordinates that are periodic in the first coordinate. For physical $y$-periodicity, set `pars1.periodic_axis = 'y'`, set `pars1.d` to the $y$ period, and set `pars2.H` to the half-width after the swap.
- Keep selector inputs as char or string scalars: `flag_geom` (`'star'|'ellipse'|'circle'`), `portSign` (`'+'|'-'`), and periodic axis (`'x'|'y'`). Do not convert them into structs.
- Outgoing Hankel functions use `besselh(n, 1, z)`.
- Shared parameters: `beta` (Bloch phase; `beta_m = beta + 2*pi*m/d`), `d` (y-period), `L` (lead-cell x-period), `M` (Rayleigh half-width; `K = 2M+1`), `ntot` (boundary nodes), and `kext`/`kint` (exterior and interior wavenumbers). `pars2` holds `H, proxy_dist, N_side, N_top, N_proxy_edge, M_pw`.

## Code conventions (summary of root AGENTS.md)

- Do not change the mathematical model or function interfaces unless explicitly asked. Keep changes localized, and preserve numerical results up to floating-point roundoff.
- Use 2-space indentation and write comments in English. Name local helpers `LOCAL_*`. Prefer readable vectorization.
- Make substantial new files function files with subfunctions, not scripts with trailing local functions, so that the Octave fallback works.
- Header rules:
  - Script header: put the header before any code.
  - Function help text: put it immediately after the `function` line, starting in column 1.
  - Substantial files: use the labels `% Purpose:`, `% Main algorithm:`, `% Based on:`, `% Main changes:`, and `% Numerical goal:` where they apply.
- Stage markers look like `% --- stage N: brief description ---`.
- Group many `LOCAL_` helpers under `%% ==================== Role name ====================`, followed by a one-sentence description.
- Document user-adjustable parameters where they are defined, for example geometry, scan intervals, grid sizes, `ntot`, and refinement or stopping criteria. Add LaTeX-style formulas when they clarify kernels, jump relations, or block assembly.
- For a nontrivial refactor, summarize the plan before coding.
- After edits, report what changed, the files and functions you touched, the checks you ran with their results, and the expected successful outcome. Do not paste whole files.

### File naming (top-level and benchmark scripts)

Pattern: `<prefix>_<task>[_model][_qualifier].m`.

- Prefixes:
  - `tep_`: eigenvalue/resonance problems, including EDC cavities
  - `bloch_`: Bloch-mode tests and workflows
  - `scat_`: scattering / forced problems (not `scatt`)
  - `bie_`: BIE/operator assembly
  - `test_`: fallback prefix for standalone validation scripts
- Model abbreviations: `1d`, `edc` (empty defect cell), `ld` (linear defect), `mc` (missing column), `lead`, `pc` (perfect periodic crystal).
- Task abbreviations: `scan`, `local`, `global`, `test`, `ps` (point source), `trmatch`, `conv`.

Functions inside `+pkg/` need no prefix.

## `test/` experiments (summary of test/AGENTS.md)

- Each experiment gets its own subdirectory, normally `test/i<stage>/<name>-v<N>/` or `.../<name>-a<N>/`. By default the active experiment directory is the only place you may write. Keep logs, figures, and reports inside it, and do not modify packages or main code from an experiment.
- One attempt directory is reused for implementation, debugging, and reruns of the same method. Operational failures do not consume the attempt. Open a new attempt only after a complete run shows that the *method* failed.
- MATLAB entry points must run from MATLAB source alone:
  - Do not read Markdown, README, manifest, Git, hash, or report files.
  - Do not discover the repo root or depend on the repo layout.
  - Put parameters in MATLAB source or pass them as explicit inputs.
- Generated outputs (`test/**/output/`, `test/**/tmp/`) and `*.mat`/`*.png`/`*.pdf` files are git-ignored. Do not show SHA-256 values in human-facing docs.

## `research/` workspace (summary of research/AGENTS.md)

- Reading order:
  1. root `AGENTS.md`
  2. `research/README.md`
  3. `research/STATUS.md`
  4. `research/NOTATION.md`
  5. only the relevant project or planning files
- There is **no active `research/mainline/`**, and you must not create one without explicit review. The Müller–Cauchy mainline is frozen at tag `mainline-muller-cauchy-2026-07-26` in `research/archive/muller-cauchy-2026-07/`. It is non-authoritative unless a task selects it.
- Projects: `eig-apost/` is active. `half-guide-dtn/` is paused. `cell-representation/` and `novelty-audit/` are complete. Project conclusions do not auto-promote to a mainline or to `draft/`.
- Classify each concern as `blocker`, `important caveat`, or `minor caveat`. Only a blocker may stop a stage. Track open items in the project's single open-problem ledger, `implementation/open-problems.md` for eig-apost, rather than duplicating them.
- Do not modify MATLAB code directories from research tasks unless asked. After long tasks, update `STATUS.md` and record direction decisions in `DECISIONS.md`.
- Never silently change notation, definitions, assumptions, theorem status, or citations. Use notation local to the selected project, for eig-apost `implementation/SYMBOL.md`.
- Naming: lowercase ASCII with hyphens and short stable names. Use the prefixes `s-` (section), `a-` (appendix), `r-` (review), and `p-` (plan). Avoid vague words like `new`, `final`, or `latest`.
- Write notes with Obsidian wikilinks `[[...]]` for substantive connections.
- Disposable material goes in `research/tmp/` (untracked). Never put durable results there.
- For theorem proofs or proof audits, follow `.agents/skills/rigorous-proof/SKILL.md` unless the user opts out.

## Markdown, LaTeX, and references

- In repository Markdown, use `$...$` for inline math and `$$...$$` for display math. Inside math, write Greek letters as LaTeX commands (`\beta`), not as bare names or Unicode glyphs.
- LaTeX cleanup: only `latexmk -c` in the project directory, or with the main `.tex` file given explicitly. Never use `rm`/globs, and never `latexmk -C` unless asked. Never delete sources, bibliographies, figures, or data.
- References:
  - Access PDFs through `ref/ref_data/` (a symlink to `../TEP_ref/`), named `<FirstAuthorSurname><Year>.pdf` with `a`, `b`, … suffixes on collisions. Use only lawful public full texts, and verify their identity.
  - When adding a reference, update both `ref/README.md` and `ref/reference.bib`, keeping them alphabetized by surname and then year. Never add PDFs to Git.
