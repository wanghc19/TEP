#!/bin/bash
# Monitor one serial I8.4 search/confirmation process under a shared budget.
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


MAX_SCIENCE_SECONDS = 1800
MAX_RSS_BYTES = 2 * 1024**3
SAMPLE_SECONDS = 0.2


def snapshot():
  completed = subprocess.run(
      ["ps", "-axo", "pid=,ppid=,pgid=,rss=,%cpu=,comm="],
      check=True, capture_output=True, text=True)
  rows = {}
  for line in completed.stdout.splitlines():
    fields = line.split(maxsplit=5)
    if len(fields) != 6:
      continue
    pid, ppid, pgid, rss_kib, cpu_percent, command = fields
    rows[int(pid)] = {
        "ppid": int(ppid),
        "pgid": int(pgid),
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


def total(rows, pids, field, scale=1):
  return scale * sum(rows[pid][field] for pid in pids if pid in rows)


def pid_text(pids):
  return ";".join(str(pid) for pid in sorted(pids)) or "none"


if len(sys.argv) != 3:
  print(f"usage: {sys.argv[0]} RUN_DIR MATLAB_EXPRESSION", file=sys.stderr)
  sys.exit(2)

run_dir = Path(sys.argv[1])
matlab_expression = sys.argv[2]
matlab_bin = os.environ.get("MATLAB_BIN", "matlab")
attempt_dir = run_dir.parent
attempt_dir.mkdir(parents=True, exist_ok=True)
lock_path = attempt_dir / ".fmm-search-lock"
lock_stream = lock_path.open("a+", encoding="utf-8")
try:
  fcntl.flock(lock_stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
  print(f"another monitor owns {lock_path}", file=sys.stderr)
  sys.exit(3)

prior_budget_seconds = 0.0
for prior_status in attempt_dir.glob("run-*/status.txt"):
  fields = dict(line.split("=", 1)
                for line in prior_status.read_text().splitlines()
                if "=" in line)
  prior_budget_seconds += float(fields.get("budget_charge_seconds", "0"))
remaining_budget_seconds = MAX_SCIENCE_SECONDS-prior_budget_seconds
if remaining_budget_seconds <= 0:
  print("I8.4 shared scientific budget exhausted", file=sys.stderr)
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
post_cleanup_survivors = set()
post_cleanup_status = "not_checked"

with command_file.open("x", encoding="utf-8") as stream:
  stream.write(f"OMP_NUM_THREADS={os.environ.get('OMP_NUM_THREADS', '')} ")
  stream.write(f"remaining_budget_seconds={remaining_budget_seconds:.6f} ")
  stream.write(f"rss_limit_bytes={MAX_RSS_BYTES} ")
  stream.write(shlex.join(command) + "\n")
with resource_csv.open("x", newline="", encoding="utf-8") as stream:
  csv.writer(stream).writerow([
      "utc", "elapsed_seconds", "task_tree_rss_bytes",
      "matlab_union_rss_bytes", "task_tree_cpu_percent",
      "load_1m", "load_5m", "load_15m", "task_pids",
      "external_matlab_roots"])
run_log.touch(exist_ok=False)


def kill_task_tree(refresh=True):
  global known_task_pids
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
  known_task_pids.update(current_pids)
  for pid in sorted(current_pids, reverse=True):
    try:
      os.kill(pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
      pass


def handle_signal(signum, _frame):
  global termination, signal_exit_code
  termination = f"monitor received {signal.Signals(signum).name}"
  signal_exit_code = 128+signum
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
      "omp_num_threads": os.environ.get("OMP_NUM_THREADS", ""),
      "prior_budget_seconds": prior_budget_seconds,
      "remaining_budget_seconds": remaining_budget_seconds,
      "rss_limit_bytes": MAX_RSS_BYTES,
      "sample_seconds": SAMPLE_SECONDS,
  }
  system_file.write_text(
      json.dumps(system_record, indent=2) + "\n", encoding="utf-8")
  if preflight_matlab:
    last_external_roots = preflight_matlab
    termination = "preflight found an existing MATLAB process"
  elif signal_exit_code is None:
    with run_log.open("w", encoding="utf-8") as log_stream:
      process = subprocess.Popen(
          command, stdout=log_stream, stderr=subprocess.STDOUT,
          start_new_session=True)
      root_pid = process.pid
      known_task_pids = {root_pid}
      termination = "process exited"
      while process.poll() is None:
        time.sleep(SAMPLE_SECONDS)
        elapsed = time.monotonic()-start_monotonic
        if signal_exit_code is not None:
          break
        _, rows = snapshot()
        task_pids = descendants(rows,{root_pid})
        known_task_pids.update(task_pids)
        matlab_root_pids = matlab_roots(rows)
        matlab_union_pids = descendants(rows,matlab_root_pids)
        external_roots = matlab_root_pids.difference(task_pids)
        last_external_roots = external_roots
        task_rss = total(rows,task_pids,"rss_kib",1024)
        matlab_union_rss = total(rows,matlab_union_pids,"rss_kib",1024)
        task_cpu = total(rows,task_pids,"cpu_percent")
        peak_task_rss = max(peak_task_rss,task_rss)
        peak_matlab_union_rss = max(peak_matlab_union_rss,matlab_union_rss)
        loads = os.getloadavg()
        with resource_csv.open("a", newline="", encoding="utf-8") as stream:
          csv.writer(stream).writerow([
              time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              f"{elapsed:.6f}", task_rss, matlab_union_rss,
              f"{task_cpu:.3f}", *(f"{value:.6f}" for value in loads),
              pid_text(task_pids),pid_text(external_roots)])
        if external_roots:
          termination = "foreign MATLAB process detected during run"
          kill_task_tree()
          break
        if task_rss >= MAX_RSS_BYTES or matlab_union_rss >= MAX_RSS_BYTES:
          termination = "2 GiB RSS hard limit reached"
          kill_task_tree()
          break
        if elapsed >= remaining_budget_seconds:
          termination = "shared 30 minute scientific budget reached"
          kill_task_tree()
          break
      return_code = process.wait()
      exit_code = 128-return_code if return_code < 0 else return_code
  elif signal_exit_code is not None:
    exit_code = signal_exit_code
except (OSError, subprocess.SubprocessError, ValueError) as error:
  termination = f"monitor exception: {type(error).__name__}"
  with run_log.open("a", encoding="utf-8") as stream:
    stream.write(f"{termination}: {error}\n")
finally:
  if root_pid is not None:
    kill_task_tree()
    time.sleep(SAMPLE_SECONDS)
    try:
      _, cleanup_rows = snapshot()
      post_cleanup_survivors = {
          pid for pid in known_task_pids if pid in cleanup_rows}
      post_cleanup_survivors.update(
          pid for pid, row in cleanup_rows.items()
          if row["pgid"] == root_pid)
      post_cleanup_status = "clean" if not post_cleanup_survivors else "survivors"
      if post_cleanup_survivors:
        termination = f"{termination}; post-cleanup survivors detected"
        exit_code = 3
    except (OSError, subprocess.SubprocessError, ValueError) as error:
      post_cleanup_status = f"monitoring_failed:{type(error).__name__}"
      termination = f"{termination}; post-cleanup monitoring failed"
      exit_code = 3
  else:
    post_cleanup_status = "no_process_launched"
  if signal_exit_code is not None:
    exit_code = signal_exit_code
  end_wall = time.time()
  wall_seconds = end_wall-start_wall
  budget_charge_seconds = wall_seconds if root_pid is not None else 0.0
  status_lines = [
      f"start_utc={start_utc}",
      f"end_utc={time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(end_wall))}",
      f"wall_seconds={wall_seconds:.6f}",
      f"budget_charge_seconds={budget_charge_seconds:.6f}",
      f"prior_budget_seconds={prior_budget_seconds:.6f}",
      f"cumulative_budget_seconds={prior_budget_seconds+budget_charge_seconds:.6f}",
      f"exit_code={exit_code}", f"termination={termination}",
      f"science_budget_seconds={MAX_SCIENCE_SECONDS}",
      f"rss_limit_bytes={MAX_RSS_BYTES}",
      f"sample_seconds={SAMPLE_SECONDS:.3f}",
      f"root_pid={root_pid if root_pid is not None else 'none'}",
      f"last_known_task_pids={pid_text(known_task_pids)}",
      f"last_external_matlab_roots={pid_text(last_external_roots)}",
      f"post_cleanup_status={post_cleanup_status}",
      f"post_cleanup_survivors={pid_text(post_cleanup_survivors)}",
      f"peak_task_tree_rss_bytes={peak_task_rss}",
      f"peak_matlab_union_rss_bytes={peak_matlab_union_rss}",
  ]
  status_file.write_text("\n".join(status_lines) + "\n", encoding="utf-8")

sys.exit(exit_code)
PY
