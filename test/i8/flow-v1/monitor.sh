#!/bin/bash
# Monitor the I8 process tree, with one shared 45-minute science budget.
# Based on the I7.3 monitor; only names and cumulative time accounting differ.
exec /usr/bin/python3 - "$@" <<'PY'
import csv
import fcntl
import os
from pathlib import Path
import shlex
import signal
import subprocess
import sys
import time


MAX_WALL_SECONDS = 2700
MAX_RSS_BYTES = 2_300_000_000
SAMPLE_SECONDS = 0.1


def read_limit(name, default, maximum):
  text = os.environ.get(name, str(default))
  if not text.isdigit():
    raise ValueError(f"{name} must be an integer from 1 to {maximum}")
  value = int(text)
  if value < 1 or value > maximum:
    raise ValueError(f"{name} must be an integer from 1 to {maximum}")
  return value


def process_snapshot():
  completed = subprocess.run(
      ["ps", "-axo", "pid=,ppid=,rss=,%cpu=,comm="],
      check=True, capture_output=True, text=True)
  rows = {}
  for line in completed.stdout.splitlines():
    fields = line.split(maxsplit=4)
    if len(fields) != 5:
      continue
    pid, ppid, rss_kib, cpu_percent, command = fields
    rows[int(pid)] = {
        "ppid": int(ppid),
        "rss_kib": int(rss_kib),
        "cpu_percent": float(cpu_percent),
        "command": command,
    }
  return completed.stdout, rows


def descendants(rows, roots):
  members = set(roots)
  changed = True
  while changed:
    changed = False
    for pid, row in rows.items():
      if row["ppid"] in members and pid not in members:
        members.add(pid)
        changed = True
  return members


def matlab_roots(rows):
  return {pid for pid, row in rows.items()
          if "matlab" in row["command"].lower()}


def rss_bytes(rows, pids):
  return 1024 * sum(rows[pid]["rss_kib"] for pid in pids if pid in rows)


def cpu_percent(rows, pids):
  return sum(rows[pid]["cpu_percent"] for pid in pids if pid in rows)


def pid_text(pids):
  return ";".join(str(pid) for pid in sorted(pids)) or "none"


if len(sys.argv) != 3:
  print(f"usage: {sys.argv[0]} RUN_DIR MATLAB_EXPRESSION", file=sys.stderr)
  sys.exit(2)

try:
  wall_limit_seconds = read_limit(
      "I8_WALL_LIMIT_SECONDS", MAX_WALL_SECONDS, MAX_WALL_SECONDS)
  rss_limit_bytes = read_limit(
      "I8_RSS_LIMIT_BYTES", MAX_RSS_BYTES, MAX_RSS_BYTES)
except ValueError as error:
  print(error, file=sys.stderr)
  sys.exit(2)

run_dir = Path(sys.argv[1])
# Every stage and debugging call in this flow shares the same conservative cap.
prior_wall_seconds = 0.0
for prior_status in run_dir.parent.parent.glob("attempt-*/run-*/status.txt"):
  fields = dict(line.split("=", 1) for line in prior_status.read_text().splitlines()
                if "=" in line)
  prior_wall_seconds += float(fields["wall_seconds"])
remaining_seconds = int(MAX_WALL_SECONDS - prior_wall_seconds)
if remaining_seconds <= 0:
  print("I8 cumulative computation budget exhausted", file=sys.stderr)
  sys.exit(3)
wall_limit_seconds = min(wall_limit_seconds, remaining_seconds)
matlab_expression = sys.argv[2]
matlab_bin = os.environ.get("MATLAB_BIN", "matlab")
resource_csv = run_dir / "resources.csv"
run_log = run_dir / "run.log"
command_file = run_dir / "command.txt"
snapshot_file = run_dir / "ps-current.txt"
status_file = run_dir / "status.txt"
outputs = [resource_csv, run_log, command_file, snapshot_file, status_file]

run_dir.parent.mkdir(parents=True, exist_ok=True)
lock_path = run_dir.parent / ".i8-lock"
lock_stream = lock_path.open("a+", encoding="utf-8")
try:
  fcntl.flock(lock_stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
  print(f"another monitor owns {lock_path}", file=sys.stderr)
  sys.exit(3)
lock_stream.seek(0)
lock_stream.truncate()
lock_stream.write(f"pid={os.getpid()}\n")
lock_stream.flush()

run_dir.mkdir(parents=True, exist_ok=True)
if any(path.exists() for path in outputs):
  print(f"monitor output already exists in {run_dir}", file=sys.stderr)
  sys.exit(2)

start_wall = time.time()
start_monotonic = time.monotonic()
start_utc = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(start_wall))
termination = "preflight not completed"
exit_code = 3
root_pid = None
known_task_pids = set()
last_external_roots = set()
peak_task_rss = 0
peak_matlab_union_rss = 0
status_written = False
signal_exit_code = None

command = [matlab_bin, "-batch", matlab_expression]
with command_file.open("x", encoding="utf-8") as stream:
  stream.write(f"I8_WALL_LIMIT_SECONDS={wall_limit_seconds} ")
  stream.write(f"I8_RSS_LIMIT_BYTES={rss_limit_bytes} ")
  stream.write(shlex.join(command) + "\n")
with resource_csv.open("x", newline="", encoding="utf-8") as stream:
  writer = csv.writer(stream)
  writer.writerow([
      "utc", "elapsed_seconds", "task_tree_rss_bytes",
      "matlab_union_rss_bytes", "task_tree_cpu_percent",
      "task_pids", "external_matlab_roots"])
run_log.touch(exist_ok=False)


def write_status():
  global status_written
  if status_written:
    return
  end_wall = time.time()
  end_utc = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(end_wall))
  lines = [
      f"start_utc={start_utc}",
      f"end_utc={end_utc}",
      f"wall_seconds={end_wall - start_wall:.6f}",
      f"exit_code={exit_code}",
      f"termination={termination}",
      f"wall_limit_seconds={wall_limit_seconds}",
      f"prior_wall_seconds={prior_wall_seconds:.6f}",
      f"cumulative_wall_seconds={prior_wall_seconds + end_wall - start_wall:.6f}",
      f"rss_limit_bytes={rss_limit_bytes}",
      f"sample_seconds={SAMPLE_SECONDS:.3f}",
      f"root_pid={root_pid if root_pid is not None else 'none'}",
      f"last_known_task_pids={pid_text(known_task_pids)}",
      f"last_external_matlab_roots={pid_text(last_external_roots)}",
      f"peak_task_tree_rss_bytes={peak_task_rss}",
      f"peak_matlab_union_rss_bytes={peak_matlab_union_rss}",
  ]
  with status_file.open("x", encoding="utf-8") as stream:
    stream.write("\n".join(lines) + "\n")
  status_written = True


def kill_task_tree(refresh=True):
  current_pids = set(known_task_pids)
  if root_pid is not None:
    if refresh:
      try:
        _, rows = process_snapshot()
        current_pids.update(descendants(rows, {root_pid}))
      except (OSError, subprocess.SubprocessError, ValueError):
        pass
    try:
      os.killpg(root_pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
      pass
  for pid in sorted(current_pids, reverse=True):
    try:
      if root_pid is not None and os.getpgid(pid) == root_pid:
        os.kill(pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError, OSError):
      pass


def handle_signal(signum, _frame):
  global termination, signal_exit_code
  termination = f"monitor received {signal.Signals(signum).name}"
  signal_exit_code = 128 + signum
  kill_task_tree(refresh=False)


for watched_signal in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
  signal.signal(watched_signal, handle_signal)

try:
  try:
    snapshot_text, rows = process_snapshot()
    snapshot_file.write_text(snapshot_text, encoding="utf-8")
  except (OSError, subprocess.SubprocessError, ValueError) as error:
    termination = "preflight process monitoring failed"
    with run_log.open("a", encoding="utf-8") as stream:
      stream.write(f"{termination}: {error}\n")
    sys.exit(exit_code)

  preflight_matlab = matlab_roots(rows)
  if preflight_matlab:
    last_external_roots = preflight_matlab
    termination = "preflight found an existing MATLAB process"
    with run_log.open("a", encoding="utf-8") as stream:
      stream.write(f"{termination}: {pid_text(preflight_matlab)}\n")
    sys.exit(exit_code)

  if signal_exit_code is not None:
    exit_code = signal_exit_code
    sys.exit(exit_code)

  with run_log.open("w", encoding="utf-8") as log_stream:
    try:
      process = subprocess.Popen(
          command, stdout=log_stream, stderr=subprocess.STDOUT,
          start_new_session=True)
    except OSError as error:
      termination = "process launch failed"
      log_stream.write(f"{termination}: {error}\n")
      log_stream.flush()
      sys.exit(exit_code)
    root_pid = process.pid
    known_task_pids = {root_pid}
    termination = "process exited"
    next_sample = time.monotonic()

    while process.poll() is None:
      now = time.monotonic()
      if now < next_sample:
        time.sleep(next_sample - now)
      sample_time = time.monotonic()
      elapsed = sample_time - start_monotonic
      next_sample += SAMPLE_SECONDS
      if next_sample < sample_time:
        next_sample = sample_time

      if signal_exit_code is not None:
        break

      try:
        snapshot_text, rows = process_snapshot()
        snapshot_file.write_text(snapshot_text, encoding="utf-8")
      except (OSError, subprocess.SubprocessError, ValueError) as error:
        termination = "process monitoring failed"
        log_stream.write(f"{termination}: {error}\n")
        log_stream.flush()
        kill_task_tree()
        break

      task_pids = descendants(rows, {root_pid})
      known_task_pids = task_pids
      matlab_root_pids = matlab_roots(rows)
      matlab_union_pids = descendants(rows, matlab_root_pids)
      external_roots = matlab_root_pids.difference(task_pids)
      last_external_roots = external_roots
      task_rss = rss_bytes(rows, task_pids)
      matlab_union_rss = rss_bytes(rows, matlab_union_pids)
      task_cpu = cpu_percent(rows, task_pids)
      peak_task_rss = max(peak_task_rss, task_rss)
      peak_matlab_union_rss = max(
          peak_matlab_union_rss, matlab_union_rss)

      with resource_csv.open("a", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow([
            time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            f"{elapsed:.6f}", task_rss, matlab_union_rss,
            f"{task_cpu:.3f}", pid_text(task_pids),
            pid_text(external_roots)])

      if external_roots:
        termination = "foreign MATLAB process detected during run"
        kill_task_tree()
        break
      if task_rss >= rss_limit_bytes:
        termination = "task tree RSS early-stop limit reached"
        kill_task_tree()
        break
      if matlab_union_rss >= rss_limit_bytes:
        termination = "MATLAB-union RSS early-stop limit reached"
        kill_task_tree()
        break
      if elapsed >= wall_limit_seconds:
        termination = "wall-time hard limit reached"
        kill_task_tree()
        break

    if signal_exit_code is not None:
      exit_code = signal_exit_code
    else:
      return_code = process.wait()
      exit_code = 128 - return_code if return_code < 0 else return_code
finally:
  if root_pid is not None:
    kill_task_tree()
    try:
      if 'process' in locals() and process.poll() is None:
        process.wait(timeout=5)
    except (subprocess.SubprocessError, OSError):
      kill_task_tree()
  write_status()

sys.exit(exit_code)
PY
