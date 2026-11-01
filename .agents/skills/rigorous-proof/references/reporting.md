# Completion reporting

Report at the end of every pass. Lead with the result; keep process narration
out. Omit any field that is empty or does not apply to the selected mode;
do not write "None" placeholders.

## Core fields (every mode)

```text
Task mode:
Target: <source file, theorem number or name, environment and location>
Output file: <only if a file was written>
Result: <proved / proved under listed conditions / findings: N blockers, N important, N minor>
Remaining gaps: <proof gaps and conditional steps, each with location>
Literature status: <one of the four status lines in literature-verification.md>
```

If the theorem was supplied only in conversation, write as the target:

```text
Source file: not provided; the theorem was supplied by the user in the current conversation.
```

## Literature fields (when references were used or are missing)

```text
Verified references: <source, exact result number, printed and PDF pages for books>
References downloaded in this pass:
References missing locally: <full bibliographic data, stable URL, why not downloaded, suggested filename, dependent steps>
```

Do not list standard results that need no citation.

## Mode-specific fields

- **Review only**: the findings, each with location, form, class, effect, and
  repair for blockers and important caveats; then one line confirming that
  the proof file was not modified.
- **In-place repair**: integrity-check result; each added or revised `P`,
  `C`, `R`, and `U` block with location and purpose.
- **Complete rewrite**: replaced environment; new proof strategy in a few
  lines; confirmation that no new proof file was created; outside-environment
  diff result.
- **Proof from scratch**: where the proof was written, or that it was returned
  only in the conversation.

When changes outside the target environment were authorized, also report each
one with its new environment, label, and resulting number.
