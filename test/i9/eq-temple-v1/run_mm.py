#!/usr/bin/env python3
"""Monitor one plan-D.1 run of eq_mm_d1 (fixed-tail projection diagnostic + MM flux).
Based on run_eq.py; differences: two explicit MAT inputs, a 2 GiB process-tree RSS
hard limit, a 30-minute soft marker (no kill) and a provenance record of the input
files. MATLAB receives only explicit paths and the mode; it never reads this record.
"""
import argparse
import hashlib
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


def provenance(native, derived):
  """Input identity for humans; not passed to MATLAB."""
  def item(path):
    stat = path.stat()
    digest = hashlib.sha256()
    with path.open('rb') as handle:
      for block in iter(lambda: handle.read(1 << 24), b''):
        digest.update(block)
    return dict(path=str(path), bytes=stat.st_size,
      mtime_utc=dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat(),
      sha256=digest.hexdigest())
  run = derived.parent
  record = dict(native=item(native), derived=item(derived))
  for name in ('result.json', 'status.json', 'command.json'):
    if (run/name).exists():
      record['derived_' + name.replace('.json', '')] = item(run/name)
  status = json.loads((run/'status.json').read_text())
  record['derived_run_status'] = dict(exit_code=status.get('exit_code'),
    wall_seconds=status.get('wall_seconds'), peak_rss_bytes=status.get('peak_rss_bytes'))
  return record


def quote(value):
  return "'" + str(value).replace("'", "''") + "'"


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--matlab', required=True)
  parser.add_argument('--native', required=True, help='I9.3 compare-v1 run-02 evidence.mat')
  parser.add_argument('--derived', required=True, help='I9.5 eq-temple-v1 run-03 evidence.mat')
  parser.add_argument('--mode', default='formal', choices=['formal', 'smoke'])
  parser.add_argument('--soft-seconds', type=float, default=1800)
  parser.add_argument('--hard-seconds', type=float, default=2400)
  parser.add_argument('--rss-bytes', type=int, default=2_147_483_648)
  parser.add_argument('--nojvm', action='store_true', help='Start MATLAB without the JVM (memory)')
  args = parser.parse_args()
  output = Path(args.output).resolve()
  output.mkdir(parents=True, exist_ok=False)
  limits = dict(rss_bytes=args.rss_bytes, soft_seconds=args.soft_seconds,
    hard_seconds=args.hard_seconds, sample_seconds=1)
  native = Path(args.native).resolve()
  derived = Path(args.derived).resolve()
  write_json(output/'provenance.json', provenance(native, derived))
  threads = 11
  experiment = str(Path(__file__).resolve().parent)
  expression = 'addpath(' + quote(experiment) + '); '
  expression += ('eq_mm_d1(' + quote(native) + ',' + quote(derived) + ',' + quote(output) + ','
    + quote(args.mode) + ');')
  command = [args.matlab] + (['-nojvm'] if args.nojvm else []) + ['-batch', expression]
  launched_utc=dt.datetime.now(dt.timezone.utc)
  budget_started_utc=launched_utc
  write_json(output/'command.json', dict(command=command, native=str(native), derived=str(derived),
    started_utc=launched_utc.isoformat(), budget_started_utc=budget_started_utc.isoformat(),limits=limits, threads=threads))
  process = None
  known = set()
  peak = 0
  exit_code = 3
  reason = 'not_started'
  started = time.monotonic()
  prior_elapsed=max(0,(launched_utc-budget_started_utc).total_seconds())
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
    if prior_elapsed>=limits['hard_seconds']:
      raise RuntimeError('Shared scientific hard budget already exhausted before launch')
    with (output/'run.log').open('w') as log, (output/'resources.csv').open('w') as resource:
      writer = csv.writer(resource)
      writer.writerow(['utc', 'elapsed_seconds', 'rss_bytes', 'pids', 'external_matlab'])
      env = dict(os.environ, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC='FALSE')
      process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
        start_new_session=True)
      known.add(process.pid)
      reason = 'process_exited'
      soft_crossed = None
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
        if soft_crossed is None and elapsed >= limits['soft_seconds']:
          soft_crossed = elapsed
          log.write('LAUNCHER soft 30-minute budget crossed at %.1fs\n' % elapsed)
          log.flush()
        if outside:
          raise RuntimeError('Concurrent MATLAB detected')
        if rss >= limits['rss_bytes']:
          raise RuntimeError('Process-tree RSS hard limit')
        if elapsed >= limits['hard_seconds']:
          raise RuntimeError('Shared scientific 40-minute hard limit')
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
      soft_limit_crossed_seconds=locals().get('soft_crossed'),
      shared_elapsed_seconds=prior_elapsed+time.monotonic()-started, peak_rss_bytes=peak,
      budget_started_utc=budget_started_utc.isoformat(),
      survivors=survivors, finished_utc=dt.datetime.now(dt.timezone.utc).isoformat())
    write_json(output/'status.json', status)
    print(json.dumps(status), flush=True)


if __name__ == '__main__':
  main()
