#!/usr/bin/env bash
# codex-wait.sh: block until a Codex thread has no running turn and no queued
# messages, then print the result of its latest turn.
#
# Usage:
#   codex-wait.sh <thread-id> [timeout-min=40] [interval-sec=20]
#
# Intended to be launched in the background right after `codex queue`; it
# prints nothing while waiting, so the caller can sleep until it exits.
#
# State is read only (never written):
#   ~/.codex/sessions/*/*/*/rollout-*-<thread-id>.jsonl  turn events, replies
#   ~/.codex/queue_1.sqlite                               pending queued items (opened mode=ro)
# The thread counts as finished when the latest `task_started` has a matching
# `task_complete` / `turn_aborted` and no item is queued, on two consecutive polls.
#
# Output: status, turn id, duration, model/effort of the last turn and the
# thread's current settings, then the turn's last agent message.
# Exit codes: 0 finished, 1 usage/file error, 2 timeout, 3 latest turn aborted.

set -u
tid="${1:?usage: codex-wait.sh <thread-id> [timeout-min] [interval-sec]}"
timeout_min="${2:-40}"
interval="${3:-20}"
codex_home="${CODEX_HOME:-$HOME/.codex}"

LOCAL_check='
import json, sys, sqlite3, glob, os
tid, home, final = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
files = glob.glob(os.path.join(home, "sessions", "*", "*", "*", f"rollout-*-{tid}.jsonl"))
if not files:
    print("error: no rollout file for thread", tid); sys.exit(1)
try:
    db = os.path.join(home, "queue_1.sqlite")
    con = sqlite3.connect("file:" + db + "?mode=ro", uri=True, timeout=5)
    queued = con.execute("select count(*) from queued_items where thread_id=?", (tid,)).fetchone()[0]
    con.close()
except Exception:
    queued = -1  # unknown: keep waiting
started = end = ctx = cur = None
for line in open(files[0], encoding="utf-8"):
    try:
        o = json.loads(line)
    except ValueError:
        continue  # partially written last line
    p = o.get("payload") if isinstance(o.get("payload"), dict) else {}
    t = p.get("type")
    if o.get("type") == "event_msg" and t == "task_started":
        started, end = p, None
    elif o.get("type") == "event_msg" and t in ("task_complete", "turn_aborted"):
        end = p
    elif o.get("type") == "turn_context":
        ctx = p
    elif t == "thread_settings_applied":
        cur = p.get("thread_settings") or {}
running = started is not None and end is None
if not final:
    print("busy" if running or queued != 0 else "idle"); sys.exit(0)
status = "aborted" if end and end.get("type") == "turn_aborted" else ("running" if running else "complete")
print(f"status: {status}   queued: {queued}   rollout: {files[0]}")
if end:
    print("turn: %s   duration: %.0f s" % (end.get("turn_id"), (end.get("duration_ms") or 0) / 1000))
if ctx:
    print("last turn: model %s, effort %s" % (ctx.get("model"), ctx.get("effort")))
if cur:
    print("current settings: model %s, effort %s" % (cur.get("model"), cur.get("reasoning_effort")))
print("--- last agent message ---")
print((end or {}).get("last_agent_message") or "(none)")
sys.exit(3 if status == "aborted" else 0)
'

deadline=$(( $(date +%s) + timeout_min * 60 ))
idle_polls=0
while :; do
  state=$(python3 -I -c "$LOCAL_check" "$tid" "$codex_home" 0) || { echo "$state"; exit 1; }
  if [ "$state" = idle ]; then idle_polls=$((idle_polls + 1)); else idle_polls=0; fi
  if [ "$idle_polls" -ge 2 ]; then
    python3 -I -c "$LOCAL_check" "$tid" "$codex_home" 1
    exit $?
  fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "timeout after ${timeout_min} min (thread still busy)"
    python3 -I -c "$LOCAL_check" "$tid" "$codex_home" 1
    exit 2
  fi
  sleep "$interval"
done
