"""Build and verify a shifted field under one package resource monitor.

Pass explicit paths for the release, MATLAB, FMM2D, driver, same-shift input,
empty field directory, run directory and scratch. Launch this script through
the package monitor, which measures both MATLAB and verification.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def quote(x):
  return "'" + str(x).replace("'", "''") + "'"


def main():
  p = argparse.ArgumentParser(description=__doc__)
  for key in ['package', 'matlab', 'fmm', 'driver', 'source', 'data', 'run', 'scratch']:
    p.add_argument('--' + key, type=Path, required=True)
  a = p.parse_args()
  kh = json.loads((a.source / 'fixed-input.json').read_bytes())['k']['real'][0]
  a.data.mkdir(parents=True, exist_ok=False)
  a.scratch.mkdir(parents=True, exist_ok=True)
  for name in ['preferences', 'temp']:
    (a.scratch / name).mkdir(exist_ok=True)
  env = dict(os.environ, MATLAB_PREFDIR=str(a.scratch / 'preferences'), TMPDIR=str(a.scratch / 'temp'),
             OMP_NUM_THREADS='11', OPENBLAS_NUM_THREADS='11', MKL_NUM_THREADS='11',
             VECLIB_MAXIMUM_THREADS='11', OMP_DYNAMIC='FALSE', LC_ALL='C')
  expr = (f'restoredefaultpath;addpath({quote(a.driver)});'
          f'refit({quote(a.package)},{quote(a.fmm)},{quote(a.data)},{quote(kh)});')
  (a.run / 'part.txt').write_text('field solve')
  subprocess.run([a.matlab, '-sd', a.data, '-batch', expr], env=env, check=True)
  exported = json.loads((a.data / 'fixed-input.json').read_bytes())
  assert exported['k']['real'][0] == kh
  for name in ['model.json', 'disks-input.json', 'band-inputs.json']:
    shutil.copyfile(a.source / name, a.data / name)
  (a.run / 'part.txt').write_text('verify')
  subprocess.run([sys.executable, '-B', '-I', a.package / 'scripts/verify.py',
                  '--example', 'ex1', '--workers', '4', '--data', a.data, '--output', a.run / 'verify'], check=True)


if __name__ == '__main__':
  main()
