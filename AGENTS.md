# Repository guidance

This repository contains MATLAB code and research on periodic waveguides and
eigenvalue problems. These rules apply throughout the repository.

## Scope and authority

- Read the applicable nested `AGENTS.md` before working in `research/`, `test/`,
  `redteam/`, or `ref/`. Use `README.md` for project entry points and layout.
- `legacy/`, `crystal_2d/`, and `waveguide_1d/` are historical. Do not routinely
  search, read, or use them as current theory, implementation examples, or
  baselines; use them only for explicitly requested historical work. Root MATLAB
  packages such as `+kernel/` and `+bloch/` remain shared dependencies.
- Preserve the mathematical model, function interfaces, and unrelated changes
  unless explicitly authorized to change them. Keep edits localized; explain
  nontrivial refactors before coding and preserve numerical behavior.
- Access or modify `.git` metadata only through Git commands, including shared
  worktree metadata. Never manually edit or remove Git files or lock files.

## Cloud work and synchronization

- Codex Cloud theory work writes only under `research/cloud/`; read its
  `AGENTS.md` before starting. Local agents treat that directory as read-only
  unless the user explicitly authorizes maintenance or integration.
- When authorized to push, first fetch and inspect the target remote branch.
  Integrate any remote commits missing locally, resolve conflicts, and review
  the final diff before pushing. If conflicts extend outside the authorized
  scope, stop and hand them to the user. Never force-push; this rule itself
  grants no push permission.

## Naming

- Use short, meaningful names that follow the habits of the containing
  directory. Use an abbreviation only when it is standard or clearly helps
  understanding; do not add prefixes, abbreviations, or qualifiers to fit a
  template.
- Do not rename existing files for a uniform look. If a rename is needed, check
  callers and documentation links first. A subdirectory's more specific naming
  rules apply within its scope.
- Every abbreviation in a file or directory name must have its full form and
  meaning stated explicitly. For files, put this at the beginning of the file;
  in function files, use the opening help text after the signature. For
  directories, put it at the beginning of that directory's `README.md`.
- For binary files or formats that cannot contain explanatory text, list each
  filename and its abbreviation expansions at the beginning of the containing
  directory's `README.md`; do not alter the file format to add explanations.

## Terminology in results

- In repository documents, research discussions, experiment reports, and handoff
  prompts, state the mathematical objects, computations, and meaning of results
  in direct, standard mathematical language; avoid process labels. When
  simplifying wording, keep the necessary assumptions and do not change the
  meaning of a mathematical conclusion.
- Use these terms:

  | Situation | Chinese | English |
  | --- | --- | --- |
  | Error or spectral-distance expression computed numerically | 误差估计、谱距离估计 | error estimate, spectral-distance estimate |
  | Value with a mathematical guarantee that it is not below the target error or spectral distance | 可靠上界 | reliable upper bound (guaranteed upper bound) |
  | Upper bound that depends on unverified conditions | 在所列条件下成立的上界 | upper bound valid under the listed conditions; list the conditions |
  | Field, candidate, or parameter kept unchanged during a computation | 固定场、固定候选、固定参数 | fixed, held fixed |
  | Adding degrees of freedom or polynomial degree to the FEM space | 扩充有限元空间 | enlarging the FEM space |

- Do not use “严格认证”, “冻结”, or “frozen” for these meanings. Quotations,
  titles of references, code identifiers, and historical result labels stay as
  written; explain them with the terms above.

## Code and mathematical documentation

- Write source comments in English with 2-space indentation. Prefer readable
  implementations and local helpers named `LOCAL_*`.
- Start source documentation with a concise introduction. In function files,
  place help text immediately after the signature, followed by `Input` and
  `Output` sections in that order; these are the only required section labels.
  In scripts, place the introduction before executable code and describe the
  adjustable parameters and outputs without inventing a function interface.
- Explain important parameters, dimensions, conventions, and major stages as
  needed. Mention source algorithms or earlier files only when actually used.
- For complex computations, inputs, or outputs, use LaTeX formulas to define the
  core mathematical objects and connect their symbols to the code.
- In repository Markdown, use `$...$` and `$$...$$`; write Greek symbols with
  LaTeX commands. Chat replies use the chat renderer's normal math delimiters.
- Use `$rigorous-proof` for proofs and proof audits unless the user opts out.

## Execution and reporting

- Run MATLAB code in MATLAB; do not use Octave as a substitute. Put new
  experimental code under `test/` unless another location is explicitly
  authorized; follow its execution rules.
- Report the changes, checks actually run, results, and unresolved limitations.
  Never claim a run or validation that did not occur. Edit files in place and
  do not paste complete files into chat unless requested.
- Before installing dependencies, stop and obtain explicit user permission.
- The Conda environment named `octave` is only for running Python.

## Reproducibility and large outputs

- Untracked large outputs, including MAT files, must have a recoverable
  generation path. Keep the actual source version, configuration, reproduction
  commands, dependency versions/setup, and relevant seeds and resource needs in
  Git, using the existing experiment documentation. A source hash alone is not
  a substitute for recoverable source code.
- Reproduction must start from the recorded checkout and documented inputs and
  dependencies. Include upstream generation steps or durable external sources;
  do not depend on undocumented old outputs, binaries, or machine-specific paths.
- Keep compact reference results and comparison tolerances in Git. Numerical
  reproduction need not preserve MAT bytes, timings, or arbitrary mode phases.
  Distinguish a recipe, static checks, and a completed rerun; reruns still require
  the task's execution authorization and resource budget.
- Before deleting outputs supporting a retained result, confirm recoverability
  of the source, inputs, recipe, and reference results. If reproduction has not
  been demonstrated, obtain explicit acceptance of that limitation or retain a
  recoverable backup within the storage policy. Never silently erase the only
  evidence; record legacy gaps honestly.
- Keep provenance and documentation out of numerical runtime prerequisites;
  see `test/AGENTS.md` for input and path requirements.

## Temporary outputs

- Put temporary outputs (trial builds, bug reproductions, scratch copies) in a
  subfolder of the repository's untracked `tmp/` named after the task, for
  example `tmp/xr-cleveref-repro/`. Do not create them in system temporary
  directories (`mktemp -d`, `$TMPDIR`, `/var/folders/...`) or elsewhere in the
  repository.
- An agent may delete, without asking, a task-named folder under the root
  `tmp/` that it created during the current task, by its exact path (no broad
  globs). Whether to keep it for later use is the agent's call. This permission
  covers nothing else: not files or folders from other tasks or other agents,
  not existing contents of `tmp/` (such as logs and prompts), not `research/tmp/`,
  and not outputs backing a reported result. List any other leftovers for the
  user instead of deleting them.

## LaTeX cleanup

- Use only `latexmk -c` in the identified project or with its main TeX file.
  Do not use manual deletion or broad globs. Use `latexmk -C` only when removal
  of PDFs and other primary outputs is explicitly requested. Never delete
  sources, references, styles, figures, or data as routine cleanup.
- If the project or main file is ambiguous, report it and do not clean.
