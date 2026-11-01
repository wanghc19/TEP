# Handover

Usage limits or a new session can stop a manager at any time. Keep the state
in files, so a new manager (another agent or a new session) can resume
without the conversation.

## The manager log

File: `research-manager-log.md` in the repository's scratch directory, with
the prompts in `codex-prompts/` next to it. Keep this header at the top and
update it at every stage boundary:

```markdown
# Research manager log

Goal: <the research goal in one or two lines>
User language: <language for user-facing documents>
Threads: <thread-id> = <role>; ...  (model and effort are set by the user)
Status files: <tracked files that hold the durable state of each line of work>
Constraints from the user: <standing instructions not in the repository rules>

## Now
Done: <last completed stage, one line>
Running: <prompt file sent, thread, time sent, time limit> | none
Next: <next stage, one line>
Waiting for the user on: <question> | nothing
```

Below the header, append one dated entry per stage: prompt file, what came
back, what you verified and how, what you reported, commit if any.

Before stopping for any reason, update `## Now`.

## Resuming

1. Read the repository's agent instructions, then the log header and the
   last few entries.
2. Read the status files the header lists, and the last user-facing report.
3. If `Running` names a sent prompt, check the thread with the wait script
   (it returns at once if the thread is idle) and read the result. If the
   turn finished, verify it before anything else.
4. If `Waiting for the user on` is set, ask that question first.
5. Check `git status` and `git log` for uncommitted or recent work that the
   log does not mention, and reconcile the log with it.
6. Tell the user, in their language, that you resumed, where the work
   stands, and what you will do next.

## What not to rely on

- The previous manager's conversation and memory: they are not available.
- Numbers copied into the log: check them against the status files or the
  outputs before reporting them again.
