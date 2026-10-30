#!/usr/bin/env python3
"""Launch one endpoint stage with process-tree RSS and shared wall-time limits.

The P2 stage is completed and saved before any separately authorized P3 stage.
Pass the elapsed seconds of an earlier successful stage through --prior-seconds
so both stages share the same 30/40 minute scientific budget. No MATLAB input
is derived from reports, Markdown, Git or historical experiment artifacts.
"""
import argparse
import csv
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def snapshot():
  process = subprocess.run(['ps', '-axo', 'pid=,ppid=,pgid=,rss='],
    capture_output=True, text=True, check=True)
  rows = {}
  for line in process.stdout.splitlines():
    pid, parent, group, rss = map(int, line.split())
    rows[pid] = (parent, group, 1024*rss)
  return rows


def descendants(rows, root):
  members = {root}
  while True:
    added = {pid for pid, row in rows.items() if row[0] in members} - members
    if not added:
      return members
    members |= added


def quote(text):
  return "'" + str(text).replace("'", "''") + "'"


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument('--matlab', required=True)
  parser.add_argument('--order', type=int, choices=[2, 3], required=True)
  parser.add_argument('--tag', required=True)
  parser.add_argument('--prior-seconds', type=float, default=0)
  args = parser.parse_args()
  here = Path(__file__).resolve().parent
  assert args.prior_seconds >= 0
  limits = dict(soft_seconds=1800, hard_seconds=2400, rss_bytes=2**31,
    sample_seconds=0.2, prior_seconds=args.prior_seconds)
  if args.prior_seconds >= limits['soft_seconds']:
    raise SystemExit('No new stage may start after the shared soft limit.')
  # Confirm that monitoring works before starting MATLAB.
  snapshot()
  expression = f"addpath({quote(here)}); endpoint_inertia({quote(here)},{args.order});"
  command = [args.matlab, '-batch', expression]
  env = dict(os.environ, OMP_NUM_THREADS='4', MKL_NUM_THREADS='4',
    VECLIB_MAXIMUM_THREADS='4', OPENBLAS_NUM_THREADS='4')
  log_path = here/f'{args.tag}.log'
  resource_path = here/f'{args.tag}-resources.csv'
  if log_path.exists() or resource_path.exists():
    raise SystemExit('Use a fresh log tag in the same experiment directory.')
  # A previous done marker must never authorize grace for a fresh launch.
  (here/f'progress-p{args.order}.json').write_text(json.dumps(
    dict(phase='starting',all_endpoints_done=False))+'\n')
  started = time.monotonic()
  peak = 0
  reason = 'COMPLETED'
  grace_checked = False
  grace_granted = False
  known = set()
  process = None
  try:
    with log_path.open('w') as log, resource_path.open('w') as resource:
      writer = csv.writer(resource)
      writer.writerow(['stage_seconds', 'shared_seconds', 'tree_rss_bytes', 'pids'])
      process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
        env=env, cwd=here, start_new_session=True)
      while True:
        rows = snapshot()
        members = descendants(rows, process.pid)
        # Include the monitor itself in the declared process-tree memory total.
        members.add(os.getpid())
        known |= members - {os.getpid()}
        rss = sum(rows[pid][2] for pid in members if pid in rows)
        peak = max(peak, rss)
        elapsed = time.monotonic()-started
        shared = elapsed+args.prior_seconds
        writer.writerow([f'{elapsed:.3f}',f'{shared:.3f}',rss,' '.join(map(str,sorted(members)))])
        resource.flush()
        if rss >= limits['rss_bytes']:
          reason = 'RSS_HARD_LIMIT'
          break
        if shared >= limits['hard_seconds']:
          reason = 'TIME_HARD_LIMIT'
          break
        if shared >= limits['soft_seconds'] and not grace_checked:
          grace_checked = True
          try:
            progress = json.loads((here/f'progress-p{args.order}.json').read_text())
            grace_granted = (progress.get('all_endpoints_done') is True and
              progress.get('phase') in ('save', 'done'))
          except (OSError, ValueError):
            grace_granted = False
          if not grace_granted:
            reason = 'TIME_SOFT_LIMIT_NO_IMMINENT_COMPLETION'
            break
        if process.poll() is not None:
          break
        time.sleep(limits['sample_seconds'])
      if reason != 'COMPLETED':
        log.write(f'\nMONITOR STOP {reason}\n')
        log.flush()
  finally:
    if process is not None and process.poll() is None:
      try:
        os.killpg(process.pid, signal.SIGKILL)
      except ProcessLookupError:
        pass
      process.wait()
    # Clean up only descendants of this invocation if any survived the group.
    if process is not None:
      rows = snapshot()
      survivors = [pid for pid, row in rows.items()
        if (pid in known or row[1] == process.pid) and pid != os.getpid()]
      for pid in survivors:
        try:
          os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
          pass
    elapsed = time.monotonic()-started
    record = dict(order=args.order, command=command, limits=limits,
      stage_seconds=elapsed, shared_seconds=elapsed+args.prior_seconds,
      sampled_peak_tree_rss_bytes=peak, grace_granted=grace_granted, reason=reason,
      returncode=None if process is None else process.returncode,
      note='RSS sampled every 0.2 s; peaks between samples are not observed.')
    (here/f'{args.tag}-monitor.json').write_text(json.dumps(record,indent=2)+'\n')
    print(json.dumps(record,indent=2),flush=True)
  if reason != 'COMPLETED' or process.returncode != 0:
    raise SystemExit(1)


if __name__ == '__main__':
  main()
