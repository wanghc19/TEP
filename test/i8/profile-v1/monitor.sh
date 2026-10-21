#!/bin/bash
# Monitor one serial I8 single-point profiling run under the frozen resource caps.
exec /usr/bin/python3 - "$@" <<'PY'
import csv
import fcntl
import json
import os
from pathlib import Path
import platform
import shlex
import signal
import subprocess
import sys
import time


MAX_WALL_SECONDS = 1800
MAX_RSS_BYTES = 2 * 1024**3
SAMPLE_SECONDS = 0.2


def read_limit(name, default, maximum):
  text = os.environ.get(name, str(default))
  if not text.isdigit():
    raise ValueError(f"{name} must be an integer from 1 to {maximum}")
  value = int(text)
  if value < 1 or value > maximum:
    raise ValueError(f"{name} must be an integer from 1 to {maximum}")
  return value


def snapshot():
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
      "I8PROFILE_WALL_LIMIT_SECONDS", MAX_WALL_SECONDS, MAX_WALL_SECONDS)
  rss_limit_bytes = read_limit(
      "I8PROFILE_RSS_LIMIT_BYTES", MAX_RSS_BYTES, MAX_RSS_BYTES)
except ValueError as error:
  print(error, file=sys.stderr)
  sys.exit(2)

run_dir = Path(sys.argv[1])
matlab_expression = sys.argv[2]
matlab_bin = os.environ.get("MATLAB_BIN", "matlab")
run_dir.parent.mkdir(parents=True, exist_ok=True)
lock_path = run_dir.parent / ".profile-lock"
lock_stream = lock_path.open("a+", encoding="utf-8")
try:
  fcntl.flock(lock_stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
  print(f"another monitor owns {lock_path}", file=sys.stderr)
  sys.exit(3)
run_dir.mkdir(parents=True, exist_ok=True)

resource_csv = run_dir / "resources.csv"
run_log = run_dir / "run.log"
command_file = run_dir / "command.txt"
snapshot_file = run_dir / "ps-preflight.txt"
system_file = run_dir / "system-preflight.json"
status_file = run_dir / "status.txt"
outputs = [resource_csv, run_log, command_file, snapshot_file,
           system_file, status_file]
if any(path.exists() for path in outputs):
  print(f"monitor output already exists in {run_dir}", file=sys.stderr)
  sys.exit(2)

command = [matlab_bin, "-batch", matlab_expression]
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
signal_exit_code = None

with command_file.open("x", encoding="utf-8") as stream:
  stream.write(f"I8PROFILE_WALL_LIMIT_SECONDS={wall_limit_seconds} ")
  stream.write(f"I8PROFILE_RSS_LIMIT_BYTES={rss_limit_bytes} ")
  stream.write(shlex.join(command) + "\n")
with resource_csv.open("x", newline="", encoding="utf-8") as stream:
  writer = csv.writer(stream)
  writer.writerow([
      "utc", "elapsed_seconds", "task_tree_rss_bytes",
      "matlab_union_rss_bytes", "task_tree_cpu_percent",
      "load_1m", "load_5m", "load_15m", "task_pids",
      "external_matlab_roots"])
run_log.touch(exist_ok=False)


def kill_task_tree(refresh=True):
  current_pids = set(known_task_pids)
  if root_pid is not None:
    if refresh:
      try:
        _, rows = snapshot()
        current_pids.update(descendants(rows, {root_pid}))
      except (OSError, subprocess.SubprocessError, ValueError):
        pass
    try:
      os.killpg(root_pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
      pass
  for pid in sorted(current_pids, reverse=True):
    try:
      os.kill(pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
      pass


def handle_signal(signum, _frame):
  global termination, signal_exit_code
  termination = f"monitor received {signal.Signals(signum).name}"
  signal_exit_code = 128 + signum
  kill_task_tree(refresh=False)


for watched_signal in (signal.SIGHUP, signal.SIGINT, signal.SIGTERM):
  signal.signal(watched_signal, handle_signal)

try:
  preflight_text, rows = snapshot()
  snapshot_file.write_text(preflight_text, encoding="utf-8")
  preflight_matlab = matlab_roots(rows)
  system_record = {
      "utc": start_utc,
      "platform": platform.platform(),
      "machine": platform.machine(),
      "logical_cpus": os.cpu_count(),
      "load_average": list(os.getloadavg()),
      "preflight_matlab_roots": sorted(preflight_matlab),
      "wall_limit_seconds": wall_limit_seconds,
      "rss_limit_bytes": rss_limit_bytes,
      "sample_seconds": SAMPLE_SECONDS,
  }
  system_file.write_text(
      json.dumps(system_record, indent=2) + "\n", encoding="utf-8")
  if preflight_matlab:
    last_external_roots = preflight_matlab
    termination = "preflight found an existing MATLAB process"
    with run_log.open("a", encoding="utf-8") as stream:
      stream.write(f"{termination}: {pid_text(preflight_matlab)}\n")
    sys.exit(exit_code)

  with run_log.open("w", encoding="utf-8") as log_stream:
    process = subprocess.Popen(
        command, stdout=log_stream, stderr=subprocess.STDOUT,
        start_new_session=True)
    root_pid = process.pid
    known_task_pids = {root_pid}
    termination = "process exited"
    next_sample = time.monotonic()
    while process.poll() is None:
      now = time.monotonic()
      if now < next_sample:
        time.sleep(next_sample-now)
      sample_time = time.monotonic()
      elapsed = sample_time-start_monotonic
      next_sample = max(next_sample+SAMPLE_SECONDS,sample_time)
      if signal_exit_code is not None:
        break
      try:
        _, rows = snapshot()
      except (OSError, subprocess.SubprocessError, ValueError) as error:
        termination = f"process monitoring failed: {error}"
        kill_task_tree()
        break
      task_pids = descendants(rows,{root_pid})
      known_task_pids = task_pids
      matlab_root_pids = matlab_roots(rows)
      matlab_union_pids = descendants(rows,matlab_root_pids)
      external_roots = matlab_root_pids.difference(task_pids)
      last_external_roots = external_roots
      task_rss = rss_bytes(rows,task_pids)
      matlab_union_rss = rss_bytes(rows,matlab_union_pids)
      task_cpu = cpu_percent(rows,task_pids)
      peak_task_rss = max(peak_task_rss,task_rss)
      peak_matlab_union_rss = max(peak_matlab_union_rss,matlab_union_rss)
      loads = os.getloadavg()
      with resource_csv.open("a", newline="", encoding="utf-8") as stream:
        csv.writer(stream).writerow([
            time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            f"{elapsed:.6f}", task_rss, matlab_union_rss,
            f"{task_cpu:.3f}", *(f"{value:.6f}" for value in loads),
            pid_text(task_pids), pid_text(external_roots)])
      if external_roots:
        termination = "foreign MATLAB process detected during run"
        kill_task_tree()
        break
      if task_rss >= rss_limit_bytes or matlab_union_rss >= rss_limit_bytes:
        termination = "2 GiB RSS hard limit reached"
        kill_task_tree()
        break
      if elapsed >= wall_limit_seconds:
        termination = "30 minute wall hard limit reached"
        kill_task_tree()
        break
    if signal_exit_code is not None:
      exit_code = signal_exit_code
    else:
      return_code = process.wait()
      exit_code = 128-return_code if return_code < 0 else return_code
finally:
  if root_pid is not None:
    kill_task_tree()
  end_wall = time.time()
  end_utc = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(end_wall))
  status_lines = [
      f"start_utc={start_utc}", f"end_utc={end_utc}",
      f"wall_seconds={end_wall-start_wall:.6f}", f"exit_code={exit_code}",
      f"termination={termination}",
      f"wall_limit_seconds={wall_limit_seconds}",
      f"rss_limit_bytes={rss_limit_bytes}",
      f"sample_seconds={SAMPLE_SECONDS:.3f}",
      f"root_pid={root_pid if root_pid is not None else 'none'}",
      f"last_known_task_pids={pid_text(known_task_pids)}",
      f"last_external_matlab_roots={pid_text(last_external_roots)}",
      f"peak_task_tree_rss_bytes={peak_task_rss}",
      f"peak_matlab_union_rss_bytes={peak_matlab_union_rss}",
  ]
  status_file.write_text("\n".join(status_lines) + "\n", encoding="utf-8")

sys.exit(exit_code)
PY
