# In-place repair

Use this workflow only after selecting **In-place repair** mode.

Resolve one existing target environment before editing. Use `proof` by default
unless the user specifies another environment. Insert repair blocks only inside
that environment. Do not alter its begin/end boundaries or anything outside it
without explicit authorization.

## Preserve original text

Treat all target-file content present at the start as immutable. Do not delete,
replace, rewrite, move, reorder, or reformat any original character, formula,
punctuation, whitespace, line break, comment, or control text.

For plain text, Markdown, LaTeX, and similar formats, removing every Agent
insertion block must reproduce the pre-repair target environment byte for byte.
Outside that environment, preserve the file exactly except for separately
authorized additions. For structured documents, preserve every original text
run, formula, and order using native tracked-change or insertion mechanisms,
then verify visually.

## Use typed insertion blocks

Number each type independently and stably:

- `P1`, `P2`, ...: omitted reasoning or a missing proof obligation;
- `C1`, `C2`, ...: invalid original assertion plus replacement argument;
- `R1`, `R2`, ...: source and hypothesis verification;
- `U1`, `U2`, ...: unresolved literature dependency or proof gap.

Give every block visible start and end boundaries, a textual label, and a style
compatible with the format. Use this abstract form:

```text
[Proof Addition P1 Start]
Added proof text ...
[Proof Addition P1 End]
```

Do not rely on color alone. When safe and already supported, prefer blue for
`P`, red for `C`, green for `R`, and orange for `U`. Do not add a dependency
that could break the build merely to provide color.

## Place and revise blocks

Insert each block at the first logical point of need. Put prerequisites earlier
and refer to their stable identifiers later. Do not introduce undefined symbols,
circular reasoning, or an assumption of the target conclusion.

After an invalid original assertion, insert a `C` block stating that the
preceding assertion is not used and giving the valid replacement. Later
reasoning may rely only on the replacement conclusion.

On later passes, modify only Agent content inside existing boundaries. Preserve
identifiers and markers, report each changed block, and mark obsolete blocks as
superseded rather than deleting them unless the user authorizes deletion.

## Integrity gate

Verify that:

1. stripping all blocks reproduces the original target environment;
2. every boundary is paired and every identifier unique;
3. each block is logically placed;
4. no later step uses a rejected conclusion;
5. additions create no undefined symbols, circularity, or new gaps;
6. every new citation has a hypothesis-by-hypothesis check; and
7. the effective repaired proof is a continuous chain to the conclusion.

Report the integrity result and every inserted or revised block. Separately
report every authorized addition outside the target environment, including its
content, label, and resulting number.
