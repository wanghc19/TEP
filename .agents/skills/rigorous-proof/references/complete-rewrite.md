# Complete rewrite

Use this workflow only after explicit authorization for **Complete rewrite**.
Reserve it for a proof whose strategy or logical organization has changed so
substantially that insertion-based repair is inappropriate.

Resolve one existing target environment in the original file. Use `proof` by
default unless the user specifies another environment. If the target is not
unique, stop and request clarification.

Keep the environment's begin/end boundaries and any optional heading intact.
Delete its entire body and write the new proof in that same environment. Do not
create a rewritten file.

Preserve everything outside the target environment unless the user explicitly
authorizes an addition such as a new lemma. Report every authorized outside
addition, including its content, label, and resulting number.

## Workflow

1. Capture the target environment and verify its exact boundaries.
2. Reconstruct the exact statement, assumptions, definitions, and source
   obligations from the original.
3. Design an independently readable proof with a continuous logical structure.
4. Replace only the target environment's body.
5. Apply all literature and hypothesis checks in
   `references/literature-verification.md` as routed by `SKILL.md`.
6. Recheck the rewritten proof for missing dependencies, undefined notation,
   circularity, and changes to the claim.
7. Verify from the diff that no unauthorized text outside the target
   environment changed.

At completion, identify the replaced environment and summarize the new proof
strategy, confirm that no new proof file was created, and report the
outside-environment diff check.
