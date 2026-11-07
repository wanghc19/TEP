"""Launch the Rayleigh order experiment under a process-tree memory monitor.
Input: explicit package, FMM (fast multipole method), MATLAB and output paths.
Output: command, preflight and monitor records plus scalar scientific results.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import shutil
sys.dont_write_bytecode = True
from monitor import run

p = argparse.ArgumentParser()
for n in ('output', 'package-root', 'fmm', 'matlab'):
  p.add_argument('--' + n, type=Path, required=True)
p.add_argument('--mode', choices=['pilot', 'part1', 'part2', 'cutcheck', 'cutpoles'], required=True)
a = p.parse_args()
out = a.output.resolve()
if out.exists() and any(out.iterdir()):
  raise ValueError('Use an empty output directory')
out.mkdir(parents=True, exist_ok=True)
raw = subprocess.check_output(['ps', '-axo', 'pid=,ppid=,%cpu=,rss=,comm=,args='], text=True)
rows = []
for line in raw.splitlines():
  v = line.split(None,5)
  if len(v) >= 5 and any(x in Path(v[4]).name.lower() for x in ('matlab','python','julia','octave')):
    rows.append(v[:5])
(out/'preflight.json').write_text(json.dumps({'numerical_processes': rows, 'threads': 5}, indent=2))
os.environ.update(OMP_NUM_THREADS='5', OMP_DYNAMIC='FALSE', VECLIB_MAXIMUM_THREADS='5', OPENBLAS_NUM_THREADS='5', MKL_NUM_THREADS='5')
def quote(x):
  return "'" + str(x).replace("'", "''") + "'"
here = Path(__file__).resolve().parent
support = out/'inputs'
support.mkdir()
for source in here.glob('*.m'):
  shutil.copyfile(source, support/source.name)
for name in ['launch.py','monitor.py']:
  shutil.copyfile(here/name, support/name)
paths = [a.package_root.resolve(), a.fmm.resolve(), support]
expr = 'restoredefaultpath;' + ''.join('addpath(' + quote(x) + ');' for x in paths)
expr += 'study(' + quote(out) + ',' + quote(a.mode) + ');'
r = run(out, expr, soft=1800, hard=2400, matlab_path=str(a.matlab.resolve()))
sys.exit(0 if r['returncode'] == 0 and r['reason'] == 'completed' else 1)
