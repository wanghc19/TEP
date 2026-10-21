#!/usr/bin/env python3
"""Run the MATLAB binary64 export and Arb certificate as one budgeted stage."""

import os
from pathlib import Path
import subprocess
import sys


def matlab_quote(value):
  return str(value).replace("'", "''")


def main():
  if len(sys.argv) != 7:
    raise SystemExit(
      "usage: run_pipeline_v3.py MATLAB PYTHON CANDIDATE CURVE EXPORT_DIR RESULT_JSON"
    )
  matlab, python, candidate, curve, export_dir, result_json = map(
    lambda item: Path(item).resolve(), sys.argv[1:]
  )
  source_dir = Path(__file__).resolve().parent
  expression = (
    f"addpath('{matlab_quote(source_dir)}');"
    f"export_frozen_binary64_v3('{matlab_quote(candidate)}',"
    f"'{matlab_quote(curve)}','{matlab_quote(export_dir)}');"
  )
  subprocess.run([str(matlab), "-batch", expression], check=True)
  environment = os.environ.copy()
  environment["PYTHONPATH"] = os.pathsep.join(
    [str(source_dir / "vendor"), str(source_dir)]
  )
  subprocess.run(
    [str(python), str(source_dir / "certify_resolvent_v3.py"),
     str(export_dir), str(result_json)],
    check=True,
    env=environment,
  )


if __name__ == "__main__":
  main()
