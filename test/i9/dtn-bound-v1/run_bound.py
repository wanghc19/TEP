#!/usr/bin/env python3
"""Monitor one I9.6a source-reconstruction bound run (design-9-6a); no scientific decisions.

Based on test/i9/fem-dtn-v1/run_dtn.py (process-tree RSS sampling, killpg
cleanup, machine records, soft/grace/hard limits). Main changes: the grace
rule reads MATLAB's predicted_remaining_seconds (design 6); the entry is
dtn_bound_i96(dtn_bound_i96_config(mode),[],output); summarize_bound.py runs
inside the same wall clock. MATLAB receives only the output path and mode.
D2: the launched sources are copied to output/source/ before MATLAB starts;
after run-03 the survivor check records command names and polls 10 s.
"""
import argparse
import csv
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import summarize_bound  # noqa: E402


def write_json(path, value):
  path.write_text(json.dumps(value, indent=2, allow_nan=True) + '\n')


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


def editor_trees(rows):
  """Process trees of the VS Code MATLAB language-server extension (an editor
  service of the user, not a computation); recorded and excluded from the
  serial-launch / concurrency check. Any other MATLAB still stops the run."""
  result = subprocess.run(['ps', '-axo', 'pid=,args='], capture_output=True, text=True, check=True)
  roots = set()
  for line in result.stdout.splitlines():
    parts = line.strip().split(maxsplit=1)
    if len(parts) == 2 and 'mathworks.language-matlab' in parts[1] and int(parts[0]) in rows:
      roots.add(int(parts[0]))
  members = set()
  for root in roots:
    members |= tree(rows, root)
  return members


def matlab(rows, exclude_editor=True):
  found = {pid for pid, row in rows.items() if 'matlab' in row['command'].lower()}
  return found - editor_trees(rows) if exclude_editor else found


def provenance(paths):
  """Identity of launched source files, machine record only."""
  record = {}
  for name, path in paths.items():
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    stat = path.stat()
    record[name] = dict(path=str(path), bytes=stat.st_size, sha256=digest,
      mtime_utc=dt.datetime.fromtimestamp(stat.st_mtime, dt.timezone.utc).isoformat())
  return record


def quote(value):
  return "'" + str(value).replace("'", "''") + "'"


def grace_decision(progress_path, limits):
  """Design 6: one grace of at most 10 minutes only when MATLAB's progress.json
  carries a finite objective prediction of the remaining work (levels already
  timed + save) and 1.5 x prediction <= grace."""
  try:
    progress = json.loads(progress_path.read_text())
  except (OSError, ValueError) as error:
    return dict(granted=False, rule=None, reason='progress unreadable: ' + str(error))
  predicted = progress.get('predicted_remaining_seconds')
  record = dict(progress=progress, grace_seconds=limits['grace_seconds'])
  if isinstance(predicted, (int, float)) and math.isfinite(predicted):
    record.update(rule='predicted_remaining', predicted_seconds=predicted,
      granted=1.5*predicted <= limits['grace_seconds'])
  else:
    record.update(rule=None, granted=False, reason='no finite prediction at the soft limit')
  return record


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--matlab', required=True)
  parser.add_argument('--mode', default='formal', choices=['formal', 'smoke'])
  parser.add_argument('--soft-seconds', type=float, default=1800)
  parser.add_argument('--grace-seconds', type=float, default=600)
  parser.add_argument('--hard-seconds', type=float, default=2400)
  parser.add_argument('--warn-bytes', type=int, default=2_700_000_000)
  parser.add_argument('--rss-bytes', type=int, default=3_000_000_000)
  args = parser.parse_args()
  output = Path(args.output).resolve()
  output.mkdir(parents=True, exist_ok=False)
  limits = dict(rss_bytes=args.rss_bytes, warn_bytes=args.warn_bytes, sample_seconds=1,
    soft_seconds=args.soft_seconds, grace_seconds=args.grace_seconds,
    hard_seconds=args.hard_seconds)
  threads = 11
  expression = ('addpath(' + quote(HERE) + '); dtn_bound_i96(dtn_bound_i96_config('
    + quote(args.mode) + '),[],' + quote(output) + ');')
  command = [args.matlab, '-batch', expression]
  launched_utc = dt.datetime.now(dt.timezone.utc)
  started = time.monotonic()
  write_json(output/'command.json', dict(command=command, mode=args.mode,
    launcher=sys.argv, started_utc=launched_utc.isoformat(), limits=limits, threads=threads,
    environment=dict(OMP_NUM_THREADS=str(threads), python=sys.version)))
  write_json(output/'provenance.json', dict(sources=provenance({p.name: p for p in [
    HERE/'dtn_bound_i96.m', HERE/'dtn_bound_i96_config.m', HERE/'run_bound.py',
    HERE/'summarize_bound.py']})))
  (output/'source').mkdir()
  for path in [HERE/'dtn_bound_i96.m', HERE/'dtn_bound_i96_config.m', HERE/'run_bound.py',
      HERE/'summarize_bound.py']:
    shutil.copy2(path, output/'source'/path.name)
  process = None
  known = set()
  peak = 0
  exit_code = None
  reason = 'not_started'
  stop_status = None
  soft_crossed = None
  grace = None
  warned = None
  deadline = limits['soft_seconds']
  matlab_seconds = None

  def interrupted(signum, frame):
    raise KeyboardInterrupt('signal ' + str(signum))
  for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
    signal.signal(sig, interrupted)

  def cleanup():
    if process is None or process.poll() is not None:
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

  log = (output/'run.log').open('w')
  try:
    rows = snapshot()
    write_json(output/'preflight.json', dict(external_matlab=sorted(matlab(rows)),
      all_matlab=sorted(matlab(rows, exclude_editor=False)),
      excluded_editor_tree=sorted(editor_trees(rows)),
      rows={str(k): v for k, v in rows.items()}))
    if matlab(rows):
      raise RuntimeError('Existing MATLAB prevents serial launch')
    with (output/'resources.csv').open('w') as resource:
      writer = csv.writer(resource)
      writer.writerow(['utc', 'elapsed_seconds', 'rss_bytes', 'pids', 'external_matlab'])
      env = dict(os.environ, OMP_NUM_THREADS=str(threads), OMP_DYNAMIC='FALSE')
      process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT,
        start_new_session=True)
      known.add(process.pid)
      reason = 'process_exited'
      while process.poll() is None:
        time.sleep(limits['sample_seconds'])
        rows = snapshot()
        members = tree(rows, process.pid)
        known |= members
        outside = matlab(rows)-members
        rss = sum(rows[pid]['rss'] for pid in members if pid in rows)
        peak = max(peak, rss)
        elapsed = time.monotonic()-started
        writer.writerow([dt.datetime.now(dt.timezone.utc).isoformat(), '%.3f' % elapsed, rss,
          ' '.join(map(str, sorted(members))), ' '.join(map(str, sorted(outside)))])
        resource.flush()
        if warned is None and rss >= limits['warn_bytes']:
          warned = elapsed
          log.write('LAUNCHER RSS warning %.0f bytes at %.1fs\n' % (rss, elapsed))
          log.flush()
        if outside:
          stop_status = 'RESOURCE_STOP'
          raise RuntimeError('Concurrent MATLAB detected')
        if rss >= limits['rss_bytes']:
          stop_status = 'RESOURCE_STOP'
          raise RuntimeError('Process-tree RSS hard limit')
        if elapsed >= limits['hard_seconds']:
          stop_status = 'RESOURCE_STOP'
          raise RuntimeError('hard limit')
        if soft_crossed is None and elapsed >= limits['soft_seconds']:
          soft_crossed = elapsed
          grace = grace_decision(output/'progress.json', limits)
          log.write('LAUNCHER soft limit at %.1fs; grace %s (%s)\n' % (elapsed,
            grace.get('granted'), grace.get('rule')))
          log.flush()
          if not grace.get('granted'):
            stop_status = 'RESOURCE_STOP'
            raise RuntimeError('Soft limit without objective grace evidence')
          deadline = min(limits['soft_seconds'] + limits['grace_seconds'], limits['hard_seconds'])
        if soft_crossed is not None and elapsed >= deadline:
          stop_status = 'RESOURCE_STOP'
          raise RuntimeError('Grace deadline reached')
      exit_code = process.wait()
      matlab_seconds = time.monotonic()-started
      if exit_code:
        raise RuntimeError('MATLAB exit ' + str(exit_code))
  except BaseException as error:  # record, clean up, still summarize
    reason = type(error).__name__ + ': ' + str(error)
  finally:
    cleanup()
    if matlab_seconds is None and process is not None:
      matlab_seconds = time.monotonic()-started
    try:
      rows = snapshot() if process else {}
      survivors = [pid for pid, row in rows.items() if process and row['group'] == process.pid]
      survivor_records = [dict(pid=pid, command=rows[pid]['command'], rss=rows[pid]['rss'])
        for pid in survivors]
      for _ in range(20):  # exiting children: poll up to 10 s, then record what remains
        if not survivors:
          break
        time.sleep(0.5)
        rows = snapshot()
        survivors = [pid for pid in survivors if pid in rows and rows[pid]['group'] == process.pid]
    except (OSError, subprocess.SubprocessError) as error:
      survivors = []
      survivor_records = []
      reason += '; cleanup verification failed: ' + str(error)
    log.close()
  summary_started = time.monotonic()
  launcher = dict(launched_utc=launched_utc.isoformat(), exit_code=exit_code, reason=reason,
    stop_status=stop_status, matlab_process_seconds=matlab_seconds, peak_rss_bytes=peak,
    soft_limit_crossed_seconds=soft_crossed, grace=grace, rss_warning_seconds=warned,
    survivors=survivors, survivors_at_first_check=survivor_records, limits=limits)
  summary_error = None
  try:
    summarize_bound.summarize(output, launcher, summary_started - started)
  except Exception as error:  # summary failure is recorded, never hidden
    summary_error = type(error).__name__ + ': ' + str(error)
  summary_seconds = time.monotonic()-summary_started
  status = dict(launcher, summary_seconds=summary_seconds, summary_error=summary_error,
    wall_seconds=time.monotonic()-started,
    finished_utc=dt.datetime.now(dt.timezone.utc).isoformat())
  write_json(output/'status.json', status)
  print(json.dumps({k: status[k] for k in ('exit_code', 'reason', 'stop_status',
    'wall_seconds', 'peak_rss_bytes', 'summary_error')}), flush=True)
  if exit_code != 0 or summary_error:
    sys.exit(1)


if __name__ == '__main__':
  main()
