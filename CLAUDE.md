# CLAUDE.md

Guidance for Claude Code in this repository. Claude Code does not load `AGENTS.md` automatically, but they are binding. If this file and an `AGENTS.md` disagree, the `AGENTS.md` wins.

## Read first

- `AGENTS.md` (root): scope, naming, code and math documentation, execution, reproducibility, LaTeX cleanup.
- `README.md` (root): entry points, terminology for math statements, file naming, historical directories.
- `test/AGENTS.md`: before planning, creating, debugging, or running anything under `test/`.
- `research/AGENTS.md`: before touching `research/`.
- `ref/AGENTS.md`: before adding, renaming, or removing references.

## Long tasks: save work in stages

Usage limits can cut a session off at any moment. One past session spent 2 hours thinking without writing a file, then hit the 5-hour limit and lost everything. For long tasks (theory, proofs, method design, large code or documents):

- Split the task into stages that can each be written down alone. Write the plan (or a skeleton with placeholder sections) to a file first.
- Write each finished stage to its target file right away. Touch a file at least every 20–30 minutes; if nothing is deliverable, write a working note (partial derivations, attempts, dead ends).
- Think about one stage at a time, not the whole task in one pass.
- Label unfinished parts `TODO`, `draft`, or `unverified`, and keep a short progress section (done / next / open questions) at the top of the main file so a new session can resume from files alone.
- Durable results go to their final location; scratch notes go to `research/tmp/` or `tmp/`.
- Checkpoints are local writes only. Commit only when asked.

## Delegating to Codex

Claude manages research and can delegate work to a Codex thread that the user created in the Codex desktop app.

- Send: `codex queue --thread <thread ID> --message "..."`, using the thread ID the user provides.
- Read replies (read-only): `codex resume <thread ID>` opens an interactive TUI that a non-TTY shell cannot drive, and typing into it starts a new turn. Read the rollout file `~/.codex/sessions/YYYY/MM/DD/rollout-*-<thread ID>.jsonl` instead: replies are `response_item` messages, and `event_msg` `task_complete` ends a turn. Read the `turn_context` entries for the thread's actual model and effort.
- The user creates every queue thread in the Codex desktop app and sets its model and effort. Never create a thread yourself (for example with `codex exec`, `codex resume <id> "<prompt>"`, or a new session) and never override model or effort with `-m`/`-c`. If you need a new thread, ask the user for it.
- `~/.codex/` is read-only for Claude. Never write, edit, move, or delete anything there by hand. Only the normal changes made by `codex queue` and by Codex while it replies are allowed.

## Project summary

MATLAB code and research on **2D periodic dielectric waveguides with $y$-periodicity**: Bloch modes, transmission eigenvalue problems (TEP), forced scattering, line-defect guided modes. The BIE route uses trace matching: Rayleigh expansions in homogeneous regions are coupled to Bloch-mode expansions in periodic half-leads; each lead-cell BIE is a Müller system with a quasi-periodic Green function from the augmented Method of Fundamental Solutions (MFS). The other route is FEM + DtN.

The active project is `research/projects/eig-apost/`: computing fixed-$\beta$ line-defect guided-mode candidates and a posteriori error / spectral-distance estimates through BIE and FEM + DtN routes. Experiments live in `test/i*/`; design and review notes in `research/projects/eig-apost/implementation/i*/`. Shared packages are not modified by this research.

Current status lives in `research/STATUS.md`, `research/projects/eig-apost/STATUS.md`, and the stage READMEs under `implementation/`. Do not rely on numbers copied elsewhere.

## Layout

```
+bloch/ +kernel/ +op/ +geom/ +scan/ +quad/ +utils/ +viz/   shared MATLAB packages (still in use)
benchmark/   bloch/ and qpgreen/ tests and benchmarks
test/        agent experiments: test/i*/, test/archive/
research/    Chinese-language theory workspace (Obsidian vault); explorations/ for independent studies
redteam/     cross-check of the two numerical routes (see its README)
draft/       paper draft, draft/examples/, draft/fem-dtn-epost/ (FEM + DtN lecture notes)
pre/         presentations and report
ref/         reference catalog; PDFs via ref/ref_data/ (untracked symlink)
.agents/skills  rigorous-proof, notation-discipline, commit-draft
tmp/         untracked scratch
```

Packages `+bloch`, `+kernel`, `+geom`, `+scan`, `+viz` have a `README.md`; read it before changing or calling the package.

`legacy/`, `crystal_2d/`, and `waveguide_1d/` are historical. Do not routinely read or search them, and do not use them as theory, examples, or baselines unless the user explicitly asks for historical investigation, reproduction, or migration.

## How to run

No build step. Each `test/i*/<experiment>/` README gives its entry point and reproduction command; some use a monitoring launcher (for example `run_bound.py`). Scripts in subdirectories need the repo root on the path (`addpath(pwd)`).

- MATLAB R2023b: `/Applications/MATLAB_R2023b.app/bin/matlab -batch "..."` (use the full path; `matlab` is a zsh alias).
- Run MATLAB code in MATLAB; Octave is not a substitute for validation (MFS and `lsqminnorm` behavior must be checked in MATLAB).
- Never claim a run or validation that did not happen. Ask before installing any dependency.
- The Conda env `octave` is only for running Python.

## Conventions that are easy to get wrong

- `L`/`R` are the left and right walls of one lead cell. `+`/`-` are the center ports and the positive/negative half-leads. `c^+`/`c^-` are right-/left-going center Rayleigh coefficients.
- `S_cell`: `[b^L; a^R] = [R_L, T_RL; T_LR, R_R] * [a^L; b^R]`, with `a` right-going and `b` left-going. The direct cell phase is added only to the transmission blocks, inside `construct_S`.
- BIE density is `eta = [tau; -sigma]`. `F_L`, `F_R` map `eta` to *scattered* outgoing coefficients only.
- Contour matrix `C` rows: `x, x', x'', y, y', y''`. Outward normal is `(y', -x')/speed` (counter-clockwise).
- `kernel.precomp_proxy` is periodic in the first coordinate. For physical $y$-periodicity set `pars1.periodic_axis = 'y'`, `pars1.d` = $y$ period, `pars2.H` = half-width after the swap.
- Selector inputs stay char/string scalars: `flag_geom` (`'star'|'ellipse'|'circle'`), `portSign` (`'+'|'-'`), periodic axis (`'x'|'y'`). Do not turn them into structs.
- Outgoing Hankel functions: `besselh(n, 1, z)`.
- Parameters: `beta` (Bloch phase, `beta_m = beta + 2*pi*m/d`), `d` ($y$-period), `L` (lead-cell $x$-period), `M` (Rayleigh half-width, `K = 2M+1`), `ntot` (boundary nodes), `kext`/`kint`.

## Code and documentation

- Preserve the mathematical model, function interfaces, and unrelated changes unless authorized. Keep edits local; explain nontrivial refactors before coding and preserve numerical behavior.
- 2-space indentation, English comments, `LOCAL_*` helpers, readable implementations.
- Source documentation starts with a concise introduction. Function files: help text right after the signature, then `Input` and `Output` (the only required labels). Scripts: introduction before executable code, describing adjustable parameters and outputs.
- Use LaTeX formulas to define core mathematical objects in complex computations and link symbols to code. Mention source algorithms or earlier files only when actually used.
- Names must be short and meaningful, follow the directory's habits, and avoid cosmetic renaming. Every abbreviation in a file or directory name must be expanded: at the top of the file (function files: opening help text), or at the top of the directory's `README.md`; for binary files, list them in the containing directory's `README.md`.
- Access `.git` only through Git commands; never edit or remove Git files or lock files by hand.
- After edits report the changes, checks actually run, results, and unresolved limitations. Edit in place; do not paste whole files.

## Terminology in results

- Estimate computed numerically: "error estimate" / "spectral-distance estimate".
- Guaranteed bound with a mathematical guarantee: "reliable upper bound" (guaranteed upper bound); if it depends on an unverified condition, say "upper bound valid under the listed conditions" and list them.
- Field, candidate, or parameter kept unchanged: "fixed" / "held fixed". Enlarging the FEM space: "扩充有限元空间".
- Do not use "严格认证", "冻结", or "frozen" for these meanings. Quotations, titles, code identifiers, and historical labels stay as written.

## `test/` experiments

- One directory per experiment. By default write only in the active experiment directory (code, logs, outputs, reports); anything outside needs authorization.
- Budget: estimate complete-run time and peak memory before launch. Unless the user says otherwise: 30 min soft, 40 min hard, **3 GiB** peak memory hard limit. Do not launch a run expected to exceed it. At most one extension beyond 30 min with objective evidence of imminent completion, never beyond 40. Stop and report at a hard limit. All stages of one result share its budget; a corrected rerun after an operational failure gets a fresh budget.
- Layout for new experiments: `test/iN/name-vN/output/run-001/`, with no `attempt-*` layer. `-vN` is the plan/implementation version; `run-NNN` is one execution. Reuse the version for debugging and reruns, keep failure logs, and open a new version only for substantial plan or implementation changes. Do not move old `attempt-*` outputs.
- Numerical entry points must not read documentation, designs, reviews, Git metadata, manifests, or hashes, must not require old outputs as hidden prerequisites, and must not discover the repo root or need a fixed layout. Scientific parameters live in MATLAB source or explicit arguments.
- Untracked large outputs (MAT files) need a recoverable path in Git: source version, configuration, reproduction commands, dependencies, seeds, resource needs, and compact reference results with tolerances. Before deleting outputs behind a retained result, confirm recoverability or get explicit acceptance; never silently erase the only evidence.
- `test/**/output/`, `*.mat`, `*.png`, `*.pdf` are git-ignored. Keep content hashes out of human-facing reports. Promote only validated results to research records, with limitations.

## `research/` workspace

- Reading order: `research/README.md`, `research/STATUS.md`, `research/NOTATION.md`, then only the relevant project files. Avoid unrelated repository-wide reading.
- `mainline` is only a historical label with no theoretical or notation authority; do not treat it as an active hierarchy or promotion target. `draft/` is a writing output, not theoretical authority. Archived material and historical notation are for explicitly requested historical work. Planning documents govern strategy, not proofs.
- Do not silently change definitions, assumptions, notation, theorem status, or citation sources. eig-apost notation: `implementation/SYMBOL.md`. Explain the mapping between symbols and code when needed.
- Classify concerns by effect: `blocker` (invalidates the deliverable or blocks the next step), `important caveat` (limits interpretation), `minor caveat` (deferrable). Only blockers justify stopping a stage. Keep unresolved issues in one project ledger (`implementation/open-problems.md` for eig-apost). Request revision only for a concrete repair.
- Match rigor to the claim; keep numerical evidence, conditional conclusions, and reliable bounds distinct. Investigate side questions only if they can change the current acceptance criterion or next computation; prefer the smallest decisive check.
- Do not modify MATLAB code directories without authorization. After substantial work update `STATUS.md` and record direction decisions in `DECISIONS.md`.
- Durable results go in project files; temporary derivations go in `tmp/` and have no authority. Reuse existing directories and records; avoid per-lemma folders and overlapping README/STATUS/SUMMARY/PLAN files. Use Obsidian `[[...]]` links; do not duplicate long proofs.
- Names: lowercase ASCII with hyphens for new files. The prefixes `p-`, `s-`, `a-`, `r-` are no longer required; if kept, expand them at the top of the file.
- Proofs and proof audits: use `.agents/skills/rigorous-proof/SKILL.md` unless the user opts out.

## Markdown, LaTeX, references

- Markdown math: `$...$` and `$$...$$`, Greek letters as LaTeX commands (`\beta`). In chat use the renderer's normal math delimiters.
- LaTeX cleanup: only `latexmk -c` in the identified project or with its main `.tex`. No manual deletion or globs; `latexmk -C` only if explicitly requested; never delete sources, references, styles, figures, or data. If the project or main file is ambiguous, report it and do not clean.
- References: follow `ref/AGENTS.md`. Verify metadata and source identity (do not guess fields), use lawful public full texts, keep `ref/README.md` and `ref/reference.bib` in sync (by surname, then year), name PDFs `<FirstAuthorSurname><Year>.pdf` (`a`, `b`, … on collisions) under `ref/ref_data/`, and never commit PDFs.
