# Proof from scratch

Use this workflow only after selecting **Proof from scratch** mode.

## Workflow

1. Clarify the statement under the core contract in `SKILL.md`.
2. Inventory definitions, available lemmas, source-dependent steps, and the
   exact proof obligations.
3. Choose a direct proof structure and identify where existence, uniqueness,
   necessity, sufficiency, regularity, or boundary arguments separate.
4. Produce a preliminary proof while following `literature-verification.md`.
5. Check every cited theorem hypothesis one by one in source order.
6. State the cited conclusion exactly and prove every nontrivial bridge to the
   target conclusion.
7. Recheck the full chain for undefined symbols, circularity, hidden
   assumptions, and unresolved gaps.

If writing to a file, place the proof only in the selected environment at the
specified location. Use `proof` unless the user selected another environment.
When the location is unique but the environment is absent, create the selected
environment there. If an existing target environment contains substantive proof
text, do not overwrite it under this mode; obtain explicit Complete-rewrite
authorization instead.

Do not add a supporting lemma, proposition, definition, remark, or other content
outside the target environment without explicit authorization. Report every
authorized outside addition and its resulting label and number.

If no output file was requested, return the proof in the conversation and
report that no proof file was written.

Organize a long proof into purpose-specific steps. Prefer divisions that expose
the logical obligations rather than arbitrary page-sized sections.

Do not assign a completed status while any literature dependency or proof gap
remains unresolved.
