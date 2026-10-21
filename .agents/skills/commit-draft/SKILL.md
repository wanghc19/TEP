---
name: commit-draft
description: Review current Git changes and draft copy-ready commit messages that learn the repository's recent type, scope, language, wording, and body style. Use when the user asks for a commit message, commit comment, or review of changes before committing. Never stage, commit, or push.
---

# Commit draft

Review the proposed commit for correctness and produce one repository-style
commit message in two copy-ready forms: subject only, and the identical subject
with a concise body.

## Safety and commit scope

- Read every applicable `AGENTS.md` before inspecting files in its scope.
- Use read-only Git and filesystem operations. Never modify files, stage changes,
  create a commit, amend history, or push.
- Honor a user-specified ref, path, or staged/unstaged scope.
- Otherwise, if the index contains changes, treat only staged changes as the
  proposed commit. Report unstaged and untracked changes as excluded.
- If the index is empty, treat all relevant non-ignored working-tree changes,
  including readable untracked files, as the proposed commit.
- If there are no eligible changes, say so and do not invent a message.
- Identify binary, generated, unreadable, or unusually large changes whose
  contents could not be reviewed fully, and state the limitation.

Inspect enough status, diff, and file context to understand behavior rather than
merely restating filenames. Review the proposed commit for correctness risks,
contradictions, missing updates, and unsupported validation claims.

## Learn the repository's commit style

Inspect a representative recent sample of non-merge commit subjects and bodies,
normally 30-50 commits. Infer and follow the repository's current conventions:

- allowed types and how each type is used;
- optional scope vocabulary and when scopes are omitted;
- subject syntax, language, capitalization, verb form, and punctuation;
- body format, level of detail, and bullet or prose style.

Choose the type from the primary intent of the proposed commit, not merely from
file extensions. Do not impose or normalize a generic Conventional Commits
vocabulary when history establishes a local variant. In this repository,
historical types such as `docs`, `test`, `chore`, `feat`, `research`, `wip`, and
`checkpoint` are valid evidence, including scopes such as `eig-apost`, `i3`,
`test`, and `agents`; choose among them only when the current change supports
that meaning.

When history is inconsistent, prefer the dominant recent style among commits
with a similar purpose. Mention a material ambiguity outside the copy blocks;
never place style commentary inside a proposed commit message.

## Drafting rules

- Describe exactly the proposed commit scope and nothing excluded from it.
- Make the subject specific enough to distinguish the change without listing
  every file.
- Make the body explain the important work, intent, result, or limitation
  without merely repeating the subject.
- Match the repository's body style and use only as many body items as the
  change warrants.
- Mention tests, numerical results, or validation only when they were actually
  run in the current task or are supported by reviewed artifacts in the commit.
- Do not conceal negative results, unresolved blockers, or incomplete work
  behind a stronger type or claim.

## Output contract

Write review commentary in the user's language, while the commit text follows
the language learned from repository history. Use this order:

1. `审查结果`: list actionable findings by severity with precise file
   references. If none are found, state that no blocking issue was found.
2. `仅标题版`: one plain-text fenced block containing only the subject.
3. `标题 + 正文版`: a separate plain-text fenced block containing the exact same
   subject, a blank line, and the body.
4. `范围与验证`: state whether the draft covers staged changes or the unstaged
   working tree, note excluded changes, and report only validation actually
   observed.

Keep both fenced blocks directly copyable. Do not put labels, alternatives,
explanations, shell commands, or Markdown decorations inside them. The subject
in the two blocks must be identical byte for byte.
