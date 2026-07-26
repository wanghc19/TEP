# Research guidance

This file applies under `research/`; the repository-root `AGENTS.md` also applies.

## Reading order

For theoretical tasks, read the root `AGENTS.md`, then `README.md`, `STATUS.md`,
and `NOTATION.md`, followed by only the relevant planning or project files. Read
an archived mainline only when the task explicitly selects that archive or its
Git tag. Do not read the whole repository when the task is narrower.

## Authority

When an active `mainline/` exists, use this order: `mainline/` > `NOTATION.md` >
`projects/` > `planning/` > `pre/` > `legacy/`. There is currently no active
`mainline/`.

- `mainline/` governs current theory and notation but may contain proof gaps or
  unproved propositions and is not automatically ready for `draft/`; create it
  only after a new unified direction has been explicitly reviewed.
- `NOTATION.md` currently indexes the frozen Müller--Cauchy notation; it does not
  govern a new direction or define a second system.
- `archive/` is non-authoritative historical material unless a task explicitly
  selects an archive or frozen Git version.
- Do not promote project conclusions into the mainline without explicit review.
- Planning files govern strategy, not formal mathematics.
- `pre/` contains stage-specific presentations; use `legacy/` only for explicitly
  requested historical reconstruction.
- `draft/` is a downstream writing target, not an authority, unless a task selects
  a frozen draft version.

## Notation

- When an active `mainline/` exists, use its notation. Otherwise use notation
  local to the selected project or planning task and do not silently inherit the
  frozen archive's notation.
- Never silently change notation, definitions, assumptions, theorem status, or
  citation sources.
- When changing an active mainline's notation, check mainline-wide consistency,
  English and Chinese agreement, `NOTATION.md`, and directly related project files.
- Do not force theory symbols and code variables to match at this stage.
- Code tasks must name the governing theory file or Git version and add a
  theory-to-code map when needed.
- Paper tasks must state whether they use current mainline notation or a frozen
  version.

## Scope and handoff

- Do not modify MATLAB code directories unless explicitly requested.
- Do not create a directory for each proposition, lemma, audit item, or small task.
- Avoid overlapping `README`, `STATUS`, `SUMMARY`, and `PLAN` files.
- After long tasks update `STATUS.md`; record new direction decisions in
  `DECISIONS.md`. Record notation, citation, bilingual, and rigor issues in an
  active `mainline/review-log.md`, or in the selected project's status material
  when no active mainline exists. Do not edit a frozen review log unless the task
  explicitly concerns that archive.
- Do not copy long proofs or complete literature content into collaboration files.

## Temporary material

- Put disposable derivations, audits, extracted text, conversions, and unclassified
  outputs in `tmp/`; it is non-authoritative and normally untracked.
- Never keep durable results, accepted decisions, or established theory in `tmp/`.
- Move useful material to `planning/` for strategy or `projects/` for multi-stage
  investigations. Move accepted theory to `mainline/` only after a unified
  direction has been explicitly reviewed and activated.
- Create a project directory only for a multi-file or multi-session investigation.

## Naming

- These rules cover new directories and durable human-facing documents, not every
  readable file or supporting record collection.
- Use lowercase ASCII and hyphens; prefer short, meaningful, stable names and
  established abbreviations.
- Do not lengthen concise names, invent arbitrary truncations, or use vague labels
  such as `new`, `final`, `updated`, `latest`, or `codex-output`.
- Keep clear structural names such as `mainline`, `planning`, `projects`, `tmp`,
  `archive`, `legacy`, and `figs` unchanged.

### Directories

- Summarize the topic instead of encoding the full purpose; prefer concise forms
  such as `hg-dtn`, `sol-rep`, or `novel-audit`.
- Expand a non-obvious abbreviation in the first-line heading of its `README.md`.
- Add a README only when an abbreviation, scope, or authority may be misunderstood.
- Reuse an existing directory when possible and avoid unnecessary deep nesting.

### Filename simplification

- Simplify only primary files readers browse, cite, or maintain directly, such as
  theory modules, reports, plans, and top-level coordination documents.
- Exempt checkpoints; files under `tmp/`, `logs/`, caches, rendered-output, or
  build directories; generated or experimental outputs; extracted text,
  conversions, and command logs; enumerated evidence collections; and names that
  preserve dates, stages, sources, provenance, or external conventions.
- Preserve the current name when scope is uncertain or when the name is a stable
  record identifier, unless it is actually misleading.

### Human-facing text files

- Prefer at most 15 characters before the extension without arbitrary truncation.
- Where applicable, use `s-` for sections, `a-` for appendices, `r-` for reviews,
  and `p-` for plans; preserve abbreviations such as `dtn`, `ucp`, `bie`, `mfs`,
  and `qp` and invent new prefixes only for repeated use.
- If a shortened name loses its full meaning, add the complete title as a comment
  at the start of the file.
- Obvious standard names such as `README.md`, `STATUS.md`, `NOTATION.md`,
  `DECISIONS.md`, and `theory.tex` need no title comment.
- Follow nearby conventions and do not apply these rules retroactively to exempt
  supporting files unless explicitly requested.

Priority: meaningful and consistent > concise > mechanically descriptive.
