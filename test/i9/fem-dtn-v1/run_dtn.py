#!/usr/bin/env python3
"""Monitor one I9.5b FEM+DtN run (design-9-5b D2); no scientific decisions.

Based on test/i9/eq-temple-v1/run_eq.py (process-tree RSS sampling, killpg
cleanup, machine records). Main changes: the 30-minute soft limit is a real
stop unless the design's objective grace evidence (read from the MATLAB
progress.json) supports one grace of at most 10 minutes; the post-run summary
(summarize_dtn.py, where the historical BIE value lives) runs inside the same
budget and wall clock. MATLAB receives only the output path and mode.
"""
import argparse
import csv
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import summarize_dtn  # noqa: E402


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


def matlab(rows):
  return {pid for pid, row in rows.items() if 'matlab' in row['command'].lower()}


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


def grace_decision(progress_path, limits, bracket_target=1e-10):
  """Design 7.2: grace only for (a) all required roots converged with known
  remaining checks/output, or (b) the last bracketed root chain whose remaining
  bisection steps x slowest response (+ known remaining work) x 1.5 <= grace."""
  try:
    progress = json.loads(progress_path.read_text())
  except (OSError, ValueError) as error:
    return dict(granted=False, rule=None, reason='progress unreadable: ' + str(error))
  phase = progress.get('phase')
  remaining = progress.get('remaining_required') or []   # MATLAB's effective required set
  slowest = progress.get('slowest_eval_seconds')
  slowest = float(slowest) if isinstance(slowest, (int, float)) else math.nan
  known = float(progress.get('save_estimate_seconds') or 30)
  record = dict(progress=progress, grace_seconds=limits['grace_seconds'])
  if progress.get('all_required_converged') and phase in ('figures', 'save', 'done'):
    predicted = known
    record.update(rule='all_required_converged', predicted_seconds=predicted,
      granted=1.5*predicted <= limits['grace_seconds'])
    return record
  if phase == 'recovery' and not remaining:
    predicted = 2*slowest + known
    record.update(rule='last_chain_recovery', predicted_seconds=predicted,
      granted=math.isfinite(predicted) and 1.5*predicted <= limits['grace_seconds'])
    return record
  width = progress.get('bracket_width')
  if phase == 'root' and not remaining and isinstance(width, (int, float)) and width > 0:
    steps = max(0, math.ceil(math.log2(width/bracket_target))) + 2
    predicted = steps*slowest + 2*slowest + known
    record.update(rule='last_bracketed_chain', bisection_steps=steps,
      predicted_seconds=predicted,
      granted=math.isfinite(predicted) and 1.5*predicted <= limits['grace_seconds'])
    return record
  record.update(rule=None, granted=False,
    reason='unstarted required configuration or no valid bracket at the soft limit')
  return record


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--output', required=True)
  parser.add_argument('--matlab', required=True)
  parser.add_argument('--mode', default='formal', choices=['formal', 'smoke', 'meshcheck', 'smoke-entry'])
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
  expression = ('addpath(' + quote(HERE) + '); fem_dtn_i95b(' + quote(output) + ','
    + quote(args.mode) + ');')
  command = [args.matlab, '-batch', expression]
  launched_utc = dt.datetime.now(dt.timezone.utc)
  started = time.monotonic()
  write_json(output/'command.json', dict(command=command, mode=args.mode,
    launcher=sys.argv, started_utc=launched_utc.isoformat(), limits=limits, threads=threads,
    environment=dict(OMP_NUM_THREADS=str(threads), python=sys.version)))
  write_json(output/'provenance.json', dict(sources=provenance({p.name: p for p in [
    HERE/'fem_dtn_i95b.m', HERE/'fem_dtn_i95b_config.m', HERE/'run_dtn.py',
    HERE/'summarize_dtn.py']})))
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
          raise RuntimeError('40-minute hard limit')
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
    except (OSError, subprocess.SubprocessError) as error:
      survivors = []
      reason += '; cleanup verification failed: ' + str(error)
    log.close()
  summary_started = time.monotonic()
  launcher = dict(launched_utc=launched_utc.isoformat(), exit_code=exit_code, reason=reason,
    stop_status=stop_status, matlab_process_seconds=matlab_seconds, peak_rss_bytes=peak,
    soft_limit_crossed_seconds=soft_crossed, grace=grace, rss_warning_seconds=warned,
    survivors=survivors, limits=limits)
  summary_error = None
  try:
    summarize_dtn.summarize(output, launcher, summary_started - started)
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
