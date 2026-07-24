# AGENTS.md

## Scope
This repository contains MATLAB code for numerical experiments on periodic waveguides and related eigenvalue problems.

## Theoretical research workflow

### Required reading order
Before starting a theoretical research task, read in this order:
1. `AGENTS.md`
2. `research/README.md`
3. `research/STATUS.md`
4. `research/NOTATION.md`
5. only the files in `research/mainline/` that are relevant to the task
6. the relevant planning or project files

Do not read the whole repository indiscriminately when the task has a narrower scope.

### Authority within `research/`
For theoretical research tasks, use the following authority order:
1. `research/mainline/`
2. `research/NOTATION.md`
3. `research/projects/`
4. `research/planning/`
5. `pre/`
6. `legacy/`

- `research/mainline/` is the authority for the current theory and notation, but not every proposition there has been proved and its contents are not automatically ready for `draft/`.
- `research/NOTATION.md` is only an index of the mainline notation, not an independent source of definitions.
- Do not promote project conclusions to mainline conclusions without explicit review.
- Roadmaps govern research planning, not formal mathematical statements.
- `pre/` contains stage-specific presentation material.
- Do not use `legacy/` for current research unless the task explicitly requires historical reconstruction.
- `draft/` is a downstream writing target, not an authority for current research, unless a task explicitly selects a frozen draft version.

### Notation rules
1. Use the current notation in `research/mainline/` for theoretical research tasks.
2. Do not block proof work from introducing better notation merely to remain consistent with an old `draft/`, presentation, or code variable.
3. Never silently change notation, definitions, assumptions, theorem status, or citation sources.
4. When changing mainline notation, check:
   - internal consistency throughout `research/mainline/`;
   - consistency between the English and Chinese versions;
   - `research/NOTATION.md`;
   - project files directly related to that symbol.
5. Do not force theoretical symbols and code variables to match at the current stage.
6. A code-implementation task must specify the theoretical source file or Git version and create a theory-to-code symbol map when needed.
7. A formal-paper task must specify whether it uses current mainline notation or a frozen version.

### Scope and handoff
- Do not modify MATLAB code directories unless the task explicitly requests it.
- Do not create a separate directory for every proposition or lemma.
- Do not create many overlapping `README`, `STATUS`, `SUMMARY`, or `PLAN` files.
- At the end of a long research task, update `research/STATUS.md`.
- Update `research/DECISIONS.md` when the task creates a new research-direction decision.
- Record notation, citation, bilingual consistency, or rigor issues in `research/mainline/review-log.md`.
- Do not duplicate long proofs or complete literature content in collaboration metadata.

## Always follow
- Do not change the mathematical model unless explicitly requested.
- Preserve function input/output interfaces unless explicitly requested.
- Comments must be in English.
- Use 2-space indentation.
- Prefer local helper functions with `LOCAL_` prefixes.
- For any theorem proof or proof audit, use `$rigorous-theorem-proof` by default unless the user explicitly opts out.

## Research temporary files and naming policy

### Research temporary files

* Use `research/tmp/` for disposable research-stage material, including temporary derivations, local audits, extracted text, conversion products, and outputs whose permanent location has not yet been decided.
* Files in `research/tmp/` are non-authoritative and should normally remain untracked by Git.
* Do not place durable research results, accepted decisions, or established mainline content in `research/tmp/`.
* When temporary material becomes useful, move or integrate it into:

  * `research/mainline/` for accepted current theory;
  * `research/planning/` for research strategy;
  * `research/projects/` for a multi-stage investigation.
* Do not create a dedicated project directory for a small, single-stage task unless it develops into a multi-file or multi-session investigation.

### General naming principles

These rules apply to newly created directories and, for files, only to the
in-scope human-facing documents defined below. Supporting record filenames may
retain the stable scheme used by their collection.

1. Use lowercase ASCII names.
2. Use hyphens instead of spaces or underscores.
3. Prefer short, meaningful, and stable names.
4. Use recognizable project-specific abbreviations rather than arbitrary truncation.
5. Reuse abbreviation patterns already established nearby.
6. Do not rename an existing concise name merely to make it more verbose.
7. Clarity takes priority over a rigid character limit, but excessive descriptive names are prohibited.
8. Avoid vague version-like names such as:

   * `new`
   * `final`
   * `final2`
   * `updated`
   * `latest`
   * `codex-output`

### Directory naming policy

* Directory names must be concise and must not attempt to encode the directory’s full purpose as a sentence.
* Prefer names such as:

```text
hg-dtn
sol-rep
novel-audit
ref-audit
sym-audit
```

rather than:

```text
half-guide-dtn-formulation-feasibility
complete-solution-representation-conjecture-study
full-literature-novelty-and-reference-audit
```

* Do not abbreviate already clear structural directory names such as:

```text
mainline
planning
projects
tmp
archive
legacy
figs
```

* A thematic directory whose shortened name does not fully state its topic must contain a `README.md`.
* The first line of that `README.md` must be a Markdown heading giving the complete human-readable title.

Example:

```text
research/projects/hg-dtn/
└── README.md
```

with:

```markdown
# Half-Guide DtN Formulation Feasibility Study
```

* Do not create a `README.md` solely to expand obvious names such as `tmp`, `archive`, `figs`, or `mainline`.
* Do not create empty explanatory files in every directory. Add a directory-level `README.md` only when:

  * the directory name uses a non-obvious abbreviation;
  * its scope or authority needs clarification;
  * another agent could reasonably misunderstand its purpose.
* Before creating a thematic directory, check whether the material belongs in an existing directory.
* Prefer a single concise thematic directory over several deeply nested directories.
* Do not create a separate directory for every proposition, lemma, audit item, or single-output task.

### Filename simplification scope

Filename simplification applies only to durable, human-facing files that a
reader is expected to browse, cite, or maintain directly. Typical examples are
main theory modules, primary report or plan sources, and top-level research
coordination documents.

Do not interpret “human-facing” as “any text file that a human can open.” The
following supporting or record-oriented files are exempt from filename
simplification:

* checkpoint snapshots under any `checkpoints/` directory, including files
  such as those under `research/planning/muller-cauchy/checkpoints/`;
* files under `tmp/`, `logs/`, cache, rendered-output, or build-artifact
  directories;
* generated files, experiment outputs, extracted text, conversion products,
  and command logs;
* enumerated paper notes, evidence records, fixtures, and other supporting
  collections whose filenames act as stable record identifiers;
* files whose existing names intentionally preserve a date, stage, source,
  provenance marker, or external naming convention.

Do not bulk-rename exempt files merely to satisfy a length preference, prefix
pattern, or hyphen convention. Preserve their established names unless a task
explicitly targets that collection or a name is actually misleading. When it
is unclear whether a file is a primary human-facing document, keep its current
name.

### Text filename policy

This policy applies to in-scope human-facing `.tex`, `.md`, `.txt`, `.bib`, and
similar text files as defined above. It does not apply mechanically to every
text file in the repository.

1. For in-scope human-facing files, prefer filenames of at most 15 characters
   before the extension.
2. Use short, meaningful abbreviations; do not remove letters arbitrarily merely to satisfy the length preference.
3. Use role prefixes where applicable:

   * `s-` for a LaTeX section included by a main file;
   * `a-` for a LaTeX appendix;
   * `r-` for an audit or review;
   * `p-` for a plan.
4. Do not invent additional prefixes unless they will be reused consistently.
5. Preserve established mathematical abbreviations such as:

   * `dtn`
   * `ucp`
   * `bie`
   * `mfs`
   * `qp`
6. Avoid filenames such as:

   * `new.tex`
   * `final.tex`
   * `final2.tex`
   * `notes-new.md`
   * `updated-report.md`
   * `codex-output.md`
7. When an in-scope human-facing filename is shortened and no longer expresses
   the complete title, put the complete descriptive title on the first line:

   * LaTeX:

```latex
% Full title: Spectral Scanning Interval for a Fixed Transverse Bloch Parameter
```

* Markdown:

```markdown
<!-- Full title: Reference and Assumption Audit for the Spectral Scanning Proposition -->
```

8. A standard file whose purpose is already obvious from its established name does not need such a first-line title comment. Examples include:

   * `README.md`
   * `STATUS.md`
   * `NOTATION.md`
   * `DECISIONS.md`
   * `theory.tex`
9. Before creating an in-scope human-facing file, inspect nearby filenames and
   follow the existing naming convention.
10. Do not lengthen a concise existing filename solely to make it more self-descriptive.
11. Do not apply these rules retroactively to checkpoint, provenance, generated,
   or support files unless the task explicitly requests those files.

Examples:

```text
s-specint.tex
s-bloch.tex
s-outtrace.tex
s-solrep.tex
a-ucp.tex
a-longproof.tex
r-symbols.md
r-refs.md
p-mainline.md
```

The governing priority is:

```text
meaningful and consistent
    > concise
    > mechanically descriptive
```

## Documentation comments
- For every newly created source file, add a clear English header comment block at the top of the file.
- For substantial new MATLAB files, prefer an explicit labeled format such as:
  `% Purpose:`
  `% Main algorithm:`
  `% Based on:`
  `% Main changes:`
  `% Numerical goal:`
- The header should explain:
  1. the purpose of the file,
  2. the main algorithm or workflow,
  3. which earlier file it is based on, if any,
  4. the main differences relative to that earlier file,
  5. the numerical goal, study target, or expected output.
- The header should be specific enough that a reader can understand why the file exists without reading the whole file.
- Avoid overly short or generic descriptions.

- For user-adjustable input parameters near the top of the file, add necessary English comments explaining their meaning and role.
- Document parameters that control geometry, scan intervals, grid sizes, refinement levels, discretization sizes such as `ntot`, and stopping or selection criteria.
- Parameter comments should explain purpose and usage, not merely repeat the variable name.
- When introducing a new parameter, add or update nearby comments so that a reader can understand how to use it.

- For scripts or test files with multiple logical steps, add short stage comments before each major block using the format:
  `% --- stage N: brief description ---`
  For example:
  `% --- stage 1: set parameters ---`
  `% --- stage 2: build geometry and operators ---`
  `% --- stage 3: run checks and report errors ---`
- Stage comments should describe the purpose of the block, not implementation minutiae. Use them especially in test scripts, prototype scripts, and long numerical workflows.

- When a MATLAB file has many local `LOCAL_` helper functions, group them by role so that VSCode's outline is easy to navigate. Start each group with a MATLAB section marker using exactly this spaced format:
  `%% ==================== Trace-matching matrix helper ====================`
  Then add one short English comment line below it explaining what the group does, for example:
  `% This helper builds the empty-defect block matrix used by the solve.`
  Use role-specific section names such as incoming trace helpers, matrix assembly helpers, field evaluation helpers, or plotting helpers.

- When documenting mathematical logic, operator structure, or matrix assembly, do not rely on prose alone.
- Explicitly include the key mathematical formulas in LaTeX-style notation whenever this helps clarify the implementation.
- In particular, for important kernels, block operators, jump relations, or assembled matrix formulas, prefer writing the defining formula explicitly rather than only describing it in words.

- For MATLAB `.m` files, distinguish between scripts and function files:
  - For MATLAB script files, place the file header comment block before the main executable code.
  - For MATLAB function files, place the function header comment block immediately after the `function ...` signature line, as MATLAB help text.
  - The comment block in a function file must start at column 1, without indentation, even though it is inside the function body.
  - Use the function-name style header when appropriate, for example:
    ```matlab
    function [C, curvelen, xxint, xxext] = construct_cont(ntot, flag_geom, nint, next, varargin)
    % CONSTRUCT_CONT Build the TEP contour and optional interior/exterior points.
    %
    % Purpose:
    %   Constructs the common contour matrix used by the TEP scripts.
    %
    % Input:
    %   ntot      - Number of periodic contour samples.
    %
    % Output:
    %   C         - Contour data array.
    %
    % Notes:
    %   Add implementation notes or compatibility notes here.
    ```
  - Do not place a separate file-level comment block above the `function` line unless there is a special reason, such as licensing or package-level metadata.

## When editing code
- For nontrivial refactors, summarize the plan before coding.
- Keep changes as localized as possible.
- Prefer readable vectorization over clever but opaque rewrites.
- Preserve numerical behavior up to normal floating-point roundoff.

## LaTeX temporary files
- This exception applies ONLY to files that are clearly generated as temporary artifacts by a LaTeX toolchain.
- At the start of a task, record which LaTeX temporary files already exist before running any command that may generate new ones.
- Codex has standing authorization to use `rm` on LaTeX temporary files created during the current task without requesting separate user confirmation.
- Do not remove a LaTeX temporary file that already existed at task start unless the user explicitly requests its removal.
- If the task-start state was not recorded, treat every existing candidate as pre-existing and preserve it.
- Resolve each removal target explicitly. Do not use recursive `rm` or broad, unverified globs under this exception.
- Eligible temporary suffixes include `.aux`, `.bbl`, `.bcf`, `.blg`, `.fdb_latexmk`, `.fls`, `.glg`, `.glo`, `.gls`, `.idx`, `.ilg`, `.ind`, `.ist`, `.lof`, `.log`, `.lot`, `.nav`, `.out`, `.run.xml`, `.snm`, `.synctex.gz`, `.toc`, and `.vrb` when the file was generated during the current task.
- This exception NEVER applies to LaTeX sources or inputs such as `.tex`, `.bib`, `.sty`, `.cls`, and `.bst`, or to deliverables and assets such as PDF files, figures, data files, or directories.

## Validation
- Do not run MATLAB automatically.
- After making code changes, stop and let the user run MATLAB manually for final validation.
- Do not claim MATLAB code was executed unless it actually was.
- Codex may use Octave for rough sanity checks when helpful.
- Prefer non-interactive Octave execution when possible, for example via:
  - `conda run -n octave octave --eval "..."`
  - `conda run -n octave octave script_name.m`
- If interactive Octave is needed, use:
  - `conda activate octave`
  - `octave --no-line-editing`
- When creating substantial new MATLAB `.m` files that include local helper functions, prefer writing them as function files rather than script files, since Octave handles this more reliably.
- In particular, do not rely on script files with trailing local functions for Octave-based validation; use a main function with subfunctions instead.
- Do not rely on Octave GUI features or plotting during validation.
- Treat Octave results only as rough compatibility / sanity checks, not as final numerical validation.

- After edits, report:
  1. what changed
  2. which file/functions were modified
  3. any Octave command(s) that were run and their results
  4. the exact MATLAB command(s) the user should run manually to validate the change
  5. what outcome is expected if the change is correct

- If static inspection or Octave-based checking suggests possible issues, mention them explicitly.

## Output contract
- Modify files in place.
- Do not paste full files back into chat unless explicitly requested.
- Report:
  1. short summary of changes
  2. functions modified
  3. tests/commands run and results
