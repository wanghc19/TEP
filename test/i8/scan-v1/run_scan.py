#!/usr/bin/env python3
"""Launch and monitor one serial I8.5 MATLAB run without scientific decisions.

Paths are explicit launcher inputs. All scientific/resource parameters originate
in scan_i8_config.m and are exported by the small config/selftest setup call.
Corrected operational retries share an attempt directory and preserve all runs.
"""
import argparse
import csv
import datetime as dt
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def write_json(path, value):
  path.write_text(json.dumps(value, indent=2, allow_nan=False) + '\n')


def snapshot():
  result = subprocess.run(['ps', '-axo', 'pid=,ppid=,pgid=,rss=,%cpu=,comm='],
    capture_output=True, text=True, check=True)
  rows = {}
  for line in result.stdout.splitlines():
    parts = line.split(maxsplit=5)
    if len(parts) == 6:
      pid, parent, group, rss, cpu, command = parts
      rows[int(pid)] = dict(parent=int(parent), group=int(group), rss=int(rss)*1024,
        cpu=float(cpu), command=command)
  return rows


def tree(rows, root):
  members = {root}
  while True:
    added = {pid for pid, row in rows.items() if row['parent'] in members} - members
    if not added:
      return members
    members |= added


def matlab(rows):
  return {pid for pid, row in rows.items() if 'matlab' in row['command'].lower()}


def quote(value):
  return "'" + str(value).replace("'", "''") + "'"


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--package-root', required=True)
  parser.add_argument('--fmm-root', required=True, help='Installed FMM2D matlab directory')
  parser.add_argument('--matlab', required=True)
  parser.add_argument('--mode', choices=['run', 'selftest', 'config'], default='run')
  parser.add_argument('--config', help='This attempt setup config export; required for science')
  args = parser.parse_args()
  output = Path(args.output).resolve()
  output.mkdir(parents=True, exist_ok=False)
  config = json.loads(Path(args.config).read_text()) if args.config else None
  if args.mode == 'run' and config is None:
    parser.error('science requires this attempt --config setup export')
  # Setup runs no physical computation and uses only conservative management limits.
  limits = config['resources'] if config else dict(rss_bytes=3_000_000_000,
    soft_seconds=120, hard_seconds=180, sample_seconds=1)
  threads = config['backend']['threads'] if config else 11
  paths = [args.package_root, str(Path(__file__).resolve().parent), args.fmm_root]
  expression = '; '.join('addpath(' + quote(p) + ')' for p in paths)
  expression += '; scan_i8_search(' + quote(output) + ',' + quote(args.mode) + ');'
  command = [args.matlab, '-batch', expression]
  write_json(output/'command.json', dict(command=command, mode=args.mode,
    started_utc=dt.datetime.now(dt.timezone.utc).isoformat(), config_source=args.config))
  process = None
  known = set()
  peak = 0
  exit_code = 3
  reason = 'not_started'
  started = time.monotonic()
  prior_elapsed = 0
  def interrupted(signum, frame):
    raise KeyboardInterrupt('signal ' + str(signum))
  for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
    signal.signal(sig, interrupted)
  def cleanup():
    if process is None:
      return
    try:
      os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
      pass
    rows = snapshot()
    for pid in known:
      if pid in rows and rows[pid]['group'] == process.pid:
        try:
          os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
          pass
    process.wait()
  try:
    rows = snapshot()
    write_json(output/'preflight.json', rows)
    if matlab(rows):
      raise RuntimeError('Existing MATLAB prevents serial launch')
    with (output/'run.log').open('w') as log, (output/'resources.csv').open('w') as resource:
      writer = csv.writer(resource)
      writer.writerow(['utc', 'elapsed_seconds', 'rss_bytes', 'pids', 'external_matlab'])
      env = dict(os.environ, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC='FALSE')
      process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
        start_new_session=True)
      known.add(process.pid)
      reason = 'process_exited'
      grace = False
      while process.poll() is None:
        time.sleep(limits['sample_seconds'])
        rows = snapshot()
        members = tree(rows, process.pid)
        known |= members
        outside = matlab(rows)-members
        rss = sum(rows[pid]['rss'] for pid in members if pid in rows)
        peak = max(peak, rss)
        elapsed = prior_elapsed + time.monotonic()-started
        writer.writerow([dt.datetime.now(dt.timezone.utc).isoformat(), elapsed, rss,
          sorted(members), sorted(outside)])
        resource.flush()
        if outside:
          raise RuntimeError('Concurrent MATLAB detected')
        if rss >= limits['rss_bytes']:
          raise RuntimeError('Process-tree RSS hard limit')
        if elapsed >= limits['hard_seconds']:
          raise RuntimeError('Shared scientific 40-minute hard limit')
        if elapsed >= limits['soft_seconds'] and not grace:
          progress = json.loads((output/'progress.json').read_text())
          # A single pending interval with almost all points in its final round
          # is necessary; the manager otherwise returns before this boundary.
          if progress.get('pending_intervals', 999) > 1:
            raise RuntimeError('Soft limit: completion not objectively imminent')
          state = json.loads((output/'state.json').read_text())
          history = state.get('history', [])
          if not history or history[-1]['W'] > 1e-12:
            raise RuntimeError('Soft limit: fine interval still too wide')
          grace = True
      exit_code = process.wait()
      if exit_code:
        raise RuntimeError('MATLAB exit ' + str(exit_code))
  except BaseException as error:
    reason = type(error).__name__ + ': ' + str(error)
    raise
  finally:
    cleanup()
    try:
      rows = snapshot() if process else {}
      survivors = [pid for pid, row in rows.items() if process and row['group'] == process.pid]
    except (OSError, subprocess.SubprocessError) as error:
      survivors = []
      reason += '; cleanup verification failed: ' + str(error)
    status = dict(exit_code=exit_code, reason=reason, wall_seconds=time.monotonic()-started,
      shared_elapsed_seconds=prior_elapsed+time.monotonic()-started, peak_rss_bytes=peak,
      survivors=survivors, finished_utc=dt.datetime.now(dt.timezone.utc).isoformat())
    write_json(output/'status.json', status)
    print(json.dumps(status), flush=True)


if __name__ == '__main__':
  main()
