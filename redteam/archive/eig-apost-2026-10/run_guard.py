#!/usr/bin/env python3
"""Run one scientific command with a shared wall-time and sampled RSS budget.

All process-tree RSS samples and stdout/stderr stay in the explicit output
directory. A child launched and exited between samples can escape sampling;
sampled peaks are not OS-certified peak-memory bounds.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def process_tree_rss(root_pid):
  rows = subprocess.check_output(['ps', '-axo', 'pid=,ppid=,rss='], text=True)
  tree = {}
  for row in rows.splitlines():
    parts = row.split()
    if len(parts) == 3:
      pid, parent, rss = map(int, parts)
      tree[pid] = (parent, rss * 1024)
  selected = {root_pid}
  while True:
    extra = {pid for pid, (parent, _) in tree.items() if parent in selected}
    if extra <= selected:
      break
    selected |= extra
  return sum(tree[pid][1] for pid in selected if pid in tree)


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--output', required=True)
  parser.add_argument('--seconds', type=float, default=1800)
  parser.add_argument('--gib', type=float, default=2)
  parser.add_argument('command', nargs=argparse.REMAINDER)
  args = parser.parse_args()
  command = args.command[1:] if args.command[:1] == ['--'] else args.command
  if not command or not 0 < args.seconds <= 2400 or not 0 < args.gib <= 2:
    parser.error('Command required; wall limit <=2400 s and memory <=2 GiB.')
  destination = Path(args.output).resolve()
  destination.mkdir(parents=True, exist_ok=True)
  run_id = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
  # Fail before launch when the operating-system monitor is unavailable.
  process_tree_rss(os.getpid())
  started = time.monotonic()
  peak = 0
  stopped = None
  with (destination / (run_id + '.log')).open('w') as log, \
      (destination / (run_id + '-rss.csv')).open('w') as rss_log:
    rss_log.write('elapsed_seconds,process_tree_rss_bytes\n')
    process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                               start_new_session=True)
    try:
      while process.poll() is None:
        elapsed = time.monotonic() - started
        rss = process_tree_rss(process.pid)
        peak = max(peak, rss)
        rss_log.write(f'{elapsed:.6f},{rss}\n')
        rss_log.flush()
        if elapsed >= args.seconds or rss >= args.gib * 1024**3:
          stopped = 'WALL_LIMIT' if elapsed >= args.seconds else 'MEMORY_LIMIT'
          break
        time.sleep(0.25)
    finally:
      if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
          process.wait(timeout=3)
        except subprocess.TimeoutExpired:
          os.killpg(process.pid, signal.SIGKILL)
      returncode = process.wait()
  result = dict(command=command, cwd=os.getcwd(), run_id=run_id,
                wall_seconds=time.monotonic() - started,
                sampled_peak_rss_bytes=peak, returncode=returncode,
                stopped=stopped, wall_limit_seconds=args.seconds,
                memory_limit_bytes=args.gib * 1024**3, sampling_seconds=.25)
  (destination / (run_id + '-run.json')).write_text(json.dumps(result, indent=2) + '\n')
  print(json.dumps(result, indent=2))
  raise SystemExit(returncode if returncode else (1 if stopped else 0))


if __name__ == '__main__':
  main()
