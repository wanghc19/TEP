---
name: rigorous-theorem-proof
description: Enforce a rigorous workflow for proving, reviewing, repairing, rewriting, and source-verifying mathematical theorems, lemmas, propositions, and corollaries. Use for English requests to prove or establish a result from scratch, review or audit an existing proof, fill proof gaps or repair a proof in place while preserving all original text, rewrite a proof completely, or verify citations and theorem hypotheses. Also use for Chinese requests containing intents such as 从零开始证明、证明定理、只审查、检查证明、审查证明、补全证明、修正证明、原位修订、完整重写证明、核验引用、检查参考文献 or 检查定理条件.
---

# Rigorous theorem proof

Follow every applicable rule. Do not silently skip a required step, and do not present an unverified literature claim as verified.

Use the language requested by the user. If the user does not specify an output language, respond in the language of the request while preserving original bibliographic titles and source notation when appropriate.

## Select the task mode

Before beginning, select and explicitly report exactly one of these modes from the user's request:

1. **Proof from scratch**: construct a new proof from the statement and assumptions.
2. **Review only**: check an existing proof for correctness, completeness, and citation integrity without modifying the proof file.
3. **In-place repair**: preserve all original text absolutely and insert visibly marked additions, corrections, reference-verification blocks, or unverified-item blocks near the relevant gaps.
4. **Complete rewrite**: reorganize and write a complete proof without overwriting or modifying the original file; save the rewritten proof to a new file, or return it only in the conversation when the user requests conversational output.

If the user asks only to "check," "review," or "audit," or does not clearly authorize modifications, select **Review only**. If the user asks to "complete," "fill gaps," "fix," or "repair" without requesting a rewrite, select **In-place repair**. Select **Complete rewrite** only when the user explicitly asks for a complete rewrite or reorganization.

Unless a mode states otherwise, apply the statement-clarification, literature-management, theorem-hypothesis, and conclusion-deduction rules to all four modes.

### Proof from scratch

Construct the proof by following Sections 1 through 7. If writing the proof to a file, create or modify only the user-specified target and do not change unrelated files.

### Review only

Do not modify any content in the proof under review. You may read local references and download publicly accessible references into `ref/` under Section 2, but list every downloaded file in the final report.

For every finding, report:

1. the file, theorem, and exact location;
2. the issue category, such as a logical gap, false assertion, unmet theorem hypothesis, missing citation, or ambiguous statement;
3. the effect on the validity of the proof;
4. the minimum addition needed to repair the issue.

Do not write repair suggestions into the source file in Review-only mode.

### In-place repair

Follow the original-text protection and insertion-block protocol in Section 8. Do not turn an in-place repair into an unmarked rewrite.

### Complete rewrite

Keep the original file completely unchanged and write the rewritten proof to a new file. By default, append `.rewritten` to the original basename; for example, write the rewrite of `paper.tex` to `paper.rewritten.tex`. If the target file already exists, do not overwrite it. Report the conflict and ask the user to specify a new path.

Make the rewritten proof independently readable and apply every literature-verification rule. At completion, briefly map the major steps of the rewritten proof to the corresponding parts of the original proof.

## 1. State the claim precisely

Before proving the claim:

1. State its assumptions, quantifiers, and conclusion precisely.
2. Define every nonstandard symbol.
3. Specify the domain, codomain, and action of every operator or mapping.
4. State the relevant spaces, topology, norms, regularity assumptions, parameter ranges, and boundary conditions.
5. If the statement is ambiguous, incompletely defined, or missing an assumption, report the problem before deciding whether the proof can continue.

Do not begin a formal proof until the mathematical statement is sufficiently well-defined.

## 2. Manage references

### 2.1 Local directory and search order

Store task-specific references in the `ref/` directory at the root of the current mathematical project. Do not place task-specific literature in the Skill's own `references/` directory.

Before using an external result:

1. Check whether the target reference already exists in `ref/`.
2. If it is absent, search lawful, publicly accessible sources, including journal or publisher websites, DOI pages, arXiv, author websites, and institutional repositories.
3. If a lawful public full text exists, attempt to download it into `ref/`.
4. Do not bypass a paywall, institutional login, CAPTCHA, or other access control, and do not download from an obviously unauthorized source.

### 2.2 Downloaded-file naming

Name an Agent-downloaded reference as follows:

```text
<FirstAuthorSurname><PublicationYear>.pdf
```

For example:

```text
Fliss2013.pdf
Barnett2010.pdf
```

If the same first author has multiple works in the same year, append `a`, `b`, and so on, as in `Fliss2013a.pdf` and `Fliss2013b.pdf`.

After downloading, verify that:

1. the file is an openable PDF rather than a login page, error page, or HTML file;
2. its title, authors, publication year, and version match the intended reference;
3. it actually contains the result to be cited.

### 2.3 Citation information

When citing a paper, book, or other publication:

1. Give the complete bibliographic reference.
2. Give a DOI, publisher page, or another stable and accessible URL; when a public full-text URL exists, give that URL as well.
3. Identify the exact result number, such as Theorem 3.2, Proposition 4.1, or Lemma 2.5.
4. Do not cite only a chapter or section.
5. If the source result is unnumbered, do not invent a number. State that the result is unnumbered and give the page and enough location context to identify it uniquely.
6. If the source itself has not been inspected, do not claim from memory that its result number, page, hypotheses, or conclusion have been verified.

## 3. First pass: produce a preliminary proof or review

In the first pass, complete as much of the mathematical argument and source verification as the available references permit.

### 3.1 Available references

For every reference already in `ref/` or successfully downloaded:

1. Verify its identity and version.
2. Locate the exact result to be used.
3. Verify its result number, complete hypotheses, and exact conclusion.
4. Check every hypothesis under Section 5 before applying the result.

### 3.2 Unavailable papers or books

If a paper cannot be downloaded, or a book requires the user to obtain it through institutional access, do not stop the entire proof. Instead:

1. Mark every dependent step as unverified.
2. Do not guess a result number, book page, or exact source statement.
3. Continue the dependent argument only conditionally, and identify the unverified external result on which it depends.
4. Do not present a conditional argument as a formally source-verified proof.

Use language such as:

> The following step is conditional on the unverified literature claim A. If the corresponding theorem in the source has the required hypotheses and conclusion, then the argument continues as follows: ...

Mark the first-pass output with exactly one status appropriate to the task mode:

```text
Preliminary proof; literature verification is incomplete.
Preliminary review; literature verification is incomplete.
```

Use the second status for Review-only mode and the first status for the other three modes.

## 4. Second pass: complete literature verification

After the user places the missing references in `ref/`, recheck the entire proof. Do not merely add result numbers and page numbers.

For each newly available reference:

1. Verify the authors, title, edition or version, publication year, and publication information.
2. Locate the exact result number actually used.
3. For a book, give the printed page number; if the PDF page differs, give both the printed page and the PDF page.
4. Recheck every hypothesis in the order used by the source statement.
5. Compare the theorem's actual conclusion with the conclusion attributed to it in the first pass.
6. Recheck every deduction from the cited conclusion to the current target conclusion.
7. If the source differs from the conditional assumption used in the first pass, revise the proof rather than merely changing the citation.

Only after every citation and dependent inference passes verification, assign exactly one status appropriate to the task mode:

```text
Proof literature verification completed.
Review literature verification completed.
```

Use the second status for Review-only mode and the first status for the other three modes.

## 5. Check cited-theorem hypotheses one by one

Before applying any cited theorem:

1. Identify the exact reference and result number to be used.
2. Preserve the order, terminology, and logical structure of the hypotheses in the source theorem.
3. Do not replace the cited theorem with an arbitrarily chosen equivalent formulation.
4. List every hypothesis of the theorem.
5. Match each hypothesis to a fact already established in the current proof.

Use an explicit form such as:

> Apply [Reference, Theorem number]. Its hypotheses are verified one by one as follows:  
> (1) Condition X holds because ...  
> (2) Condition Y is satisfied because ...  
> (3) Object Z has the required property because ...

Make the correspondence explicit enough that a reader can compare every item directly with the theorem in the source. If any hypothesis has not been established, do not apply the theorem. Prove the missing hypothesis or report the proof gap.

## 6. Do not skip from the cited conclusion to the target conclusion

State exactly what the cited theorem yields.

If the cited theorem yields $A$ while the current proof requires $B$, use the following structure:

> By [Reference, Theorem number], we obtain $A$. Because ..., $A$ implies $B$.

Explain or prove $A \Rightarrow B$. Add an appropriate Remark if the implication requires a nontrivial explanation, a translation of notation, or an additional fact.

Omit further proof only for genuinely standard results from foundational courses. For example, a closed subspace of a Banach space is complete. If it is reasonably disputable whether an implication is foundational and standard, prove it or cite it.

## 7. Organize a long proof

Divide a long proof into purpose-specific Steps or Stages, such as:

- necessity and sufficiency;
- existence and uniqueness;
- review of definitions and notation;
- verification of the hypotheses of a major theorem;
- application of that theorem;
- deduction of the current target from the theorem's conclusion.

For example:

```text
Step 1: Review definitions and notation
Step 2: Verify every hypothesis of [Theorem]
Step 3: Apply [Theorem]
Step 4: Deduce the target conclusion
```

Include a separate definitions-and-notation step only when the notation or definitions are sufficiently complex.

## 8. Repair an existing proof in place

Apply this section only in In-place-repair mode.

### 8.1 Keep original text absolutely immutable

Treat all content present in the target file when the repair begins as original text. Do not delete, replace, rewrite, move, or reorder any original character, formula, punctuation, whitespace, line break, comment, or formatting-control text. Do not run a tool that reformats the entire file.

Insert new Agent blocks only between parts of the original text. For plain text, Markdown, LaTeX, and other text formats, removing every Agent insertion block after the repair must reproduce the pre-repair file byte for byte.

For a structured document that cannot be compared byte for byte, preserve every original text run, formula, and their order. Use the format's native tracked-change, comment, or insertion mechanism and perform visual verification. Do not claim that original-text integrity was verified unless the corresponding check was actually performed.

### 8.2 Use typed insertion blocks

Use four insertion-block types, assigning stable numbers beginning at 1 for each type within each file:

1. `P1`, `P2`: add omitted reasoning or discharge a missing proof obligation.
2. `C1`, `C2`: identify an invalid original assertion and provide a replacement argument.
3. `R1`, `R2`: add a source, result number, page, and hypothesis-by-hypothesis reference verification.
4. `U1`, `U2`: mark missing literature or another proof gap that remains unresolved.

Every insertion block must have:

- a stable identifier;
- explicit start and end boundaries;
- a visible textual label;
- a visually distinctive style compatible with the file format.

Use the following abstract form, adapting it to valid syntax for the target format:

```text
[Proof Addition P1 Start]
Added proof text ...
[Proof Addition P1 End]
```

Do not rely on color alone. Color may disappear in plain text, black-and-white printing, or some rendering environments. Always retain the textual label and boundary markers.

When the format supports color without breaking compilation or rendering, prefer:

- blue for `P` blocks;
- red for `C` blocks;
- green for `R` blocks;
- orange for `U` blocks.

Prefer existing color macros, revision environments, or annotation mechanisms in the file. Do not introduce a dependency that could break the existing build merely to add color. If color cannot be used safely, use only the visible label and boundaries.

### 8.3 Place insertions at the logical point of need

Place each insertion near the first original passage that requires it. Do not collect all additions at the end of the proof.

If an addition depends on an earlier missing fact, insert the prerequisite addition at the earlier location and refer to its stable identifier in the later insertion. Check that an insertion does not use an undefined symbol, assume the current target conclusion, or create circular reasoning.

### 8.4 Handle incorrect original text

Do not delete or rewrite incorrect original text. Insert a correction block immediately after it, and state explicitly that the original assertion is not a valid step in the repaired proof. For example:

```text
[Original-Text Correction C1 Start]
The preceding compactness assertion is false in general and is not used as a valid step in the repaired proof.
The correct replacement argument is as follows: ...
[Original-Text Correction C1 End]
```

Subsequent reasoning may use only the valid conclusion established by the correction block and must not rely on the rejected original assertion.

### 8.5 Revise insertion blocks in later passes

Keep original text permanently immutable. In a later pass, you may modify or replace content inside an existing Agent insertion block, but you must:

1. preserve the block identifier and boundary markers;
2. modify only Agent content inside the boundaries;
3. report which insertion blocks changed and why;
4. if a block is no longer applicable, mark it as superseded inside the block and identify its replacement rather than deleting the entire block, unless the user explicitly requests deletion of Agent-inserted content.

Do not extend a later revision outside the insertion boundaries into original text.

### 8.6 Verify integrity after repair

After an in-place repair, check that:

1. removing all Agent insertion blocks reproduces the pre-repair original text;
2. every start boundary has exactly one matching end boundary;
3. all `P`, `C`, `R`, and `U` identifiers are unique and stable;
4. every insertion is placed at the correct logical location;
5. later reasoning does not use a conclusion rejected by a correction block;
6. added content introduces no undefined symbols, circular reasoning, or new proof gaps;
7. every new citation has a complete hypothesis-by-hypothesis check;
8. the effective repaired proof forms a continuous chain from assumptions to conclusion.

## 9. Report at the end of every task

At the end of every pass, report:

1. the task mode used;
2. the file containing the theorem proved, reviewed, or repaired;
3. the theorem number or name;
4. what was proved, reviewed, or revised in this pass;
5. every reference used and its exact result number;
6. the printed and PDF page numbers for every verified book citation;
7. every reference currently absent from local `ref/`;
8. every public reference downloaded into `ref/` during this pass;
9. every step that remains unverified;
10. whether the result is preliminary or has completed literature verification.

Also report the following mode-specific information:

- **Review only**: list each finding, exact location, effect, and minimum repair suggestion; explicitly confirm that the proof file was not modified.
- **In-place repair**: state whether the original-text integrity check passed; list every `P`, `C`, `R`, and `U` block added or revised, together with its location and purpose.
- **Complete rewrite**: give the original and new file paths, confirm that the original file was not modified, and summarize the correspondence between the old and new proof steps.
- **Proof from scratch**: identify where the proof was written; if it was returned only in the conversation, state that no proof file was written.

If the user supplied the theorem only in the conversation, state:

```text
Source file: not provided; the theorem was supplied by the user in the current conversation.
```

In the first pass, also report for every missing reference:

- complete bibliographic information;
- an accessible DOI, publisher page, or other stable URL;
- why it could not be downloaded automatically;
- the suggested filename under `ref/`;
- the proof steps that depend on it.

Use this minimum report format:

```text
Task mode:
Proof status:
Source file:
Output file:
Theorem number or name:
Work completed in this pass:
Original-text integrity check:
Insertion blocks added or revised:
Review-only findings:
Verified references:
Verified book pages:
References downloaded in this pass:
References missing locally:
Steps awaiting literature verification:
Remaining proof gaps:
```
