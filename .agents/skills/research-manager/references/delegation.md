# Delegating to Codex threads

## Rules

- The user creates every worker thread in the Codex app and sets its model
  and reasoning effort. Never create a thread (no `codex exec`, no new
  session, no `codex resume <id> "<prompt>"`), and never override model or
  effort with `-m` or `-c`. If you need a new thread, ask the user.
- The Codex home directory (`$CODEX_HOME`, default `~/.codex`) is read-only
  for you. The only allowed changes are those made by `codex queue` itself
  and by Codex while it replies.
- Keep separate threads for separate roles when the user provides them:
  a worker thread for experiments and surveys, and a proof-review thread
  that only reviews proofs. Reviews from a thread that did not write the
  result are independent; keep them that way by not forwarding the worker's
  conclusions to the reviewer.
- Record each thread's ID and role in the manager log. Read its current
  model and effort from the rollout file; the user may change them between
  turns.

## Sending

```bash
codex queue --thread <thread-id> --message "$(cat <prompt-file>)"
```

Save the prompt file under `codex-prompts/` next to the manager log before
sending. A running thread picks the message up within about a minute.

The first message to a new thread introduces its role: what the project is
(one paragraph), which skill to follow (`research-worker`, and the proof
skill for a reviewer), what it may and may not write, and the reply format.

## Waiting

Right after sending, start the wait script in the background and stop until
it exits:

```bash
<skill-dir>/scripts/codex-wait.sh <thread-id> [timeout-min=40] [interval-sec=20]
```

`<skill-dir>` is this skill's directory. The script is silent while the
thread is busy and exits when no turn is running and nothing is queued on
two consecutive polls. It prints the status, the model and effort, and the
turn's last message. Exit codes: 0 finished, 1 no rollout file, 2 timeout,
3 turn aborted. Set the timeout to the time limit you gave in the prompt
plus a margin.

## Reading replies

`codex resume <id>` opens an interactive interface, and typing into it
starts a new turn; do not use it to read. Read the rollout file instead:

- path: `<codex-home>/sessions/YYYY/MM/DD/rollout-*-<thread-id>.jsonl`;
- replies are `response_item` messages; an `event_msg` with type
  `task_complete` ends a turn and carries `last_agent_message`;
- `turn_context` entries give the model and effort actually used.

The final reply is a summary. Always read the files the worker wrote before
you believe it.
