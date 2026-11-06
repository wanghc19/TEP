# Research guidance

The root `AGENTS.md` also applies. Read the relevant research/project README,
status, notation, and task files; avoid unrelated repository-wide reading.

## Authority and mathematical meaning

- Use the selected project's current theory files, notation, and supporting
  evidence. Current organization and status belong in README/STATUS.
- `mainline` is only a historical designation and has no theoretical or notation
  authority. Do not treat it as an active hierarchy or a destination for promotion.
- `draft/` is a writing output, not a source of theoretical authority. Selecting
  a draft for editing or review does not change that status.
- Archived material and historical notation are for explicitly requested
  historical work. Planning documents govern strategy, not proofs.
- Do not silently change definitions, assumptions, notation, theorem status, or
  citation sources. For approved notation changes, check affected theory,
  notation records, and both language versions where applicable.
- Identify the governing theory/version for code or papers. Explain the mapping
  between mathematical symbols and code when needed; do not force identical names.

## Research depth and evidence

- Classify unresolved concerns by their effect on the current task:
  `blocker` invalidates the deliverable or prevents the next required step;
  `important caveat` limits interpretation or applicability; `minor caveat`
  can be deferred. Only blockers justify stopping a stage.
- Match rigor to the claim. Numerical evidence, conditional conclusions, and
  reliable bounds must remain distinct; an unproved condition does not by itself
  invalidate a clearly stated conditional or numerical result.
- Investigate side questions only when they can change the current acceptance
  criterion or next computation. Prefer the smallest decisive check; do not
  expand a numerical question into an unnecessary theoretical project.
- Request revision for a concrete required repair, not merely for a caveat.
  Keep unresolved issues in one project-level ledger with their effect, next
  check, and status, linked from the project README and relevant reviews.

## Scope, records, and handoff

- Do not modify MATLAB code directories without explicit authorization.
- Update status after substantial work and record new direction decisions.
  Keep review issues in the active project's records; do not rewrite historical
  records unless the task explicitly concerns them.
- Keep durable results in project files and temporary derivations, extracts,
  and conversions in `tmp/`. Temporary material is not theoretical authority.
- Reuse existing directories and records. Avoid separate folders for individual
  lemmas or tasks, and overlapping README/STATUS/SUMMARY/PLAN documents.
- Use meaningful Obsidian links between related notes. Do not duplicate long
  proofs or source literature in handoff files.
- Follow `ref/AGENTS.md` for literature acquisition and catalog updates.

## Naming

- Follow the root `AGENTS.md` naming rules: use short, meaningful names and
  existing conventions. Prefer lowercase ASCII and hyphens for new directories
  and human-facing files.
- Avoid deep nesting, arbitrary abbreviations, mandatory prefixes, and cosmetic
  renaming. Preserve established paths and identifiers unless a change is needed;
  check references before renaming. Follow the root `AGENTS.md` requirements for
  explaining abbreviations in file and directory names.
- Historical prefixes such as `p-` and `s-` are no longer required because their
  meanings are not self-evident. If needed, treat them as abbreviations and
  explain their full names in a comment at the beginning of the file.
