#!/usr/bin/env python3
"""Monitor one I9.5 eq-temple calculation (s-eq-temple steps 0-1); no scientific decisions.
Based on fem-bound-v1/run_bound.py; only the entry point and mode argument differ.
The launcher passes explicit paths; it never reads documentation.
E.2 modes (e2, e2smoke; design-9-5a Section 6) run, in ONE MATLAB process and one
shared budget, compare-v1 fem_i9_run (new mesh/candidate, written to <output>/fem)
followed by eq_temple_i95 on that new evidence. They add a 30-minute soft marker,
a 2.7 GB warning line and provenance.json (human record; never passed to MATLAB).
"""
import argparse
import csv
import datetime as dt
import hashlib
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


def provenance(paths):
  """Identity of explicit inputs and launched source files, for humans only."""
  record = {}
  for name, path in paths.items():
    if path is None or not path.exists():
      record[name] = None
      continue
    digest = hashlib.sha256()
    with path.open('rb') as handle:
      for block in iter(lambda: handle.read(1 << 24), b''):
        digest.update(block)
    stat = path.stat()
    record[name] = dict(path=str(path), bytes=stat.st_size, sha256=digest.hexdigest(),
      mtime_utc=dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat())
  return record


def quote(value):
  return "'" + str(value).replace("'", "''") + "'"


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--matlab', required=True)
  parser.add_argument('--input', help='Explicit original FEM evidence.mat (formal/smoke modes)')
  parser.add_argument('--mode', default='formal', choices=['formal', 'smoke', 'e2', 'e2smoke'])
  parser.add_argument('--reference', help='E.2 only: old I9.3 evidence.mat for the wall-trace diagnostic')
  parser.add_argument('--soft-seconds', type=float, default=1800)
  parser.add_argument('--warn-bytes', type=int, default=2_700_000_000)
  parser.add_argument('--tail', type=int, nargs=2, metavar=('GLUE_CELL', 'TAIL_CELLS'),
    help='Optional finite Floquet tail: glue cell index and tail length')
  parser.add_argument('--hard-seconds', type=float, default=2400)
  parser.add_argument('--rss-bytes', type=int, default=3_000_000_000)
  args = parser.parse_args()
  output = Path(args.output).resolve()
  output.mkdir(parents=True, exist_ok=False)
  limits = dict(rss_bytes=args.rss_bytes, hard_seconds=args.hard_seconds, sample_seconds=1,
    soft_seconds=args.soft_seconds, warn_bytes=args.warn_bytes)
  threads = 11
  here = Path(__file__).resolve().parent
  experiment = str(here)
  expression = 'addpath(' + quote(experiment) + '); '
  if args.mode.startswith('e2'):
    compare = here.parent/'compare-v1'
    tail = args.tail or [1, 12]
    reference = Path(args.reference).resolve() if args.reference else None
    fem = output/'fem'
    expression += 'addpath(' + quote(compare) + '); '
    expression += 'fem_i9_run(' + quote(fem) + ',' + quote(args.mode) + '); '
    expression += ('eq_temple_i95(' + quote(fem/'evidence.mat') + ',' + quote(output) + ','
      + quote(args.mode) + ',[' + str(tail[0]) + ',' + str(tail[1]) + '],'
      + quote(reference if reference else '') + ');')
    sources = {f.name: f for f in [compare/'fem_i9_config.m', compare/'fem_i9_run.m',
      here/'eq_temple_i95.m', here/'eq_temple_i95_config.m', here/'eq_tail_build_i95.m',
      Path(__file__).resolve()]}
    write_json(output/'provenance.json', dict(reference=provenance({'reference': reference}),
      sources=provenance(sources)))
  else:
    if not args.input:
      parser.error('--input is required for formal/smoke modes')
    expression += 'eq_temple_i95(' + quote(Path(args.input).resolve()) + ',' + quote(output) + ',' + quote(args.mode) + (',[' + str(args.tail[0]) + ',' + str(args.tail[1]) + ']' if args.tail else '') + ');'
  command = [args.matlab, '-batch', expression]
  launched_utc=dt.datetime.now(dt.timezone.utc)
  budget_started_utc=launched_utc
  write_json(output/'command.json', dict(command=command,
    input=str(Path(args.input).resolve()) if args.input else None, mode=args.mode,
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
      warned = None
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
        if warned is None and rss >= limits['warn_bytes']:
          warned = elapsed
          log.write('LAUNCHER RSS warning %.0f bytes at %.1fs\n' % (rss, elapsed))
          log.flush()
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
      shared_elapsed_seconds=prior_elapsed+time.monotonic()-started, peak_rss_bytes=peak,
      budget_started_utc=budget_started_utc.isoformat(),
      soft_limit_crossed_seconds=locals().get('soft_crossed'),
      rss_warning_seconds=locals().get('warned'),
      survivors=survivors, finished_utc=dt.datetime.now(dt.timezone.utc).isoformat())
    write_json(output/'status.json', status)
    print(json.dumps(status), flush=True)


if __name__ == '__main__':
  main()
