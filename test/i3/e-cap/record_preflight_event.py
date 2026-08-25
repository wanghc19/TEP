#!/usr/bin/env python3
"""Publish the already completed I3.2 host preflight as one immutable event.

Purpose:
  Record fixed stdout, status, timing, and parsed gates from the separately
  authorized dependency preflight without rerunning it.

Input:
  No arguments. This recorder reads only the host provision record and local
  path state; all preflight evidence is frozen below.

Output:
  /private/tmp/tep-i32-ecap-dep-a1/host-provenance/preflight-a1.json,
  created once with O_EXCL and mode 0600.

Notes:
  This script uses only the Python standard library. It never imports NumPy or
  SciPy, opens historical fbie output, creates staged input, or starts MATLAB.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
from typing import Any


BASE_PYTHON = Path(
  "/Users/whc/.cache/codex-runtimes/codex-primary-runtime/"
  "dependencies/python/bin/python3")
FINAL_ENV = Path("/private/tmp/tep-i32-ecap-dep-a1")
PARTIAL_ENV = Path("/private/tmp/tep-i32-ecap-dep-a1.partial")
PROVISION = FINAL_ENV / "host-provenance/provision-a1.json"
EVENT = FINAL_ENV / "host-provenance/preflight-a1.json"
EXPERIMENT_DIR = Path(__file__).resolve().parent
STAGED_INPUT = EXPERIMENT_DIR / "input/fbie-a1-certificate.mat"
FORMAL_OUTPUT = EXPERIMENT_DIR / "output/ecap-a1"
PROVISION_SHA256 = (
  "193ad311278add47ec08bcff8e86aa3a7529c7ca477129aa2c302189cca2cde8")
SCHEMA = "TEP_I3_2_HOST_DEPENDENCY_PREFLIGHT_A1"
WALL_TIME_SECONDS = 2.6695757909999998
SHELL_STATUS = 0
RAW_STDOUT = (
  '{"flags": {"loadmat_simplify_cells": true, "python_ge_3_9": true, '
  '"savemat_long_field_names": true, "savemat_oned_as_column": true}, '
  '"numpy": "2.3.2", "python": "3.12.13", "scipy": "1.18.0"}\n')
PREFLIGHT_COMMAND = (
  "PYTHONNOUSERSITE=1 "
  "/private/tmp/tep-i32-ecap-dep-a1/bin/python3 -I -c \""
  "import io,json,sys,numpy,scipy; from scipy.io import loadmat,savemat; "
  "assert sys.version_info>=(3,9); "
  "key='revision_a_long_field_name_probe_123456789'; b=io.BytesIO(); "
  "savemat(b,{'probe':{key:numpy.array([1.0])},"
  "'vector':numpy.array([1.0,2.0])},long_field_names=True,"
  "oned_as='column'); raw=b.getvalue(); "
  "simple=loadmat(io.BytesIO(raw),simplify_cells=True); "
  "plain=loadmat(io.BytesIO(raw)); "
  "flags={'python_ge_3_9':True,'loadmat_simplify_cells':"
  "isinstance(simple['probe'],dict) and key in simple['probe'],"
  "'savemat_long_field_names':isinstance(simple['probe'],dict) and key in "
  "simple['probe'],'savemat_oned_as_column':"
  "numpy.asarray(plain['vector']).shape==(2,1)}; "
  "assert all(flags.values()); "
  "print(json.dumps({'python':sys.version.split()[0],"
  "'numpy':numpy.__version__,'scipy':scipy.__version__,'flags':flags},"
  "sort_keys=True))\"")


def main() -> None:
  """Validate frozen host state and publish the fixed preflight event."""
  verify_invocation()
  verify_paths()
  provision_bytes = read_regular_once(PROVISION)
  if sha256_bytes(provision_bytes) != PROVISION_SHA256:
    fail("provision record identity differs from the reviewed artifact")
  provision = json.loads(provision_bytes)
  verify_provision(provision)
  parsed = json.loads(RAW_STDOUT)
  verify_parsed(parsed)
  event = {
    "schema": SCHEMA,
    "status": "HOST_DEPENDENCY_PREFLIGHT_PASS",
    "recorded_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    "command": PREFLIGHT_COMMAND,
    "shell_status": SHELL_STATUS,
    "wall_time_seconds": WALL_TIME_SECONDS,
    "raw_stdout": RAW_STDOUT,
    "raw_stdout_sha256": sha256_bytes(RAW_STDOUT.encode("utf-8")),
    "parsed": parsed,
    "provision_record": str(PROVISION),
    "provision_record_sha256": PROVISION_SHA256,
    "recorder_script_sha256": sha256_file(Path(__file__)),
    "source_artifact_read": False,
    "staged_input_absent": True,
    "formal_output_absent": True,
    "partial_environment_absent": True,
    "staging_retry_run": False,
    "host_staging_retry_count": 1,
    "formal_matlab": {
      "completed_launches": 0,
      "retry_count": 0,
      "ecap_a1_consumed": False,
    },
    "next_gate": "SEPARATE_HOST_STAGING_AUTHORIZATION",
    "formal_matlab_must_not_read": True,
  }
  write_new_json(EVENT, event)


def verify_invocation() -> None:
  """Require the frozen standard-library host recorder invocation."""
  if sys.argv[1:]:
    fail("this command accepts no arguments")
  if not BASE_PYTHON.is_file() or not os.path.samefile(sys.executable,
                                                       BASE_PYTHON):
    fail("recorder was not launched by the frozen base interpreter")
  if os.environ.get("PYTHONNOUSERSITE") != "1":
    fail("PYTHONNOUSERSITE=1 was not supplied")


def verify_paths() -> None:
  """Require the reviewed provision and absence of every later artifact."""
  if not FINAL_ENV.is_dir() or FINAL_ENV.is_symlink():
    fail("final environment is unavailable or is a symlink")
  if stat.S_IMODE(FINAL_ENV.stat().st_mode) != 0o700:
    fail("final environment mode is not 0700")
  for path, label in (
      (PARTIAL_ENV, "partial environment"),
      (STAGED_INPUT, "staged input"),
      (FORMAL_OUTPUT, "formal output"),
      (EVENT, "preflight event")):
    if path.exists() or path.is_symlink():
      fail(f"{label} already exists: {path}")


def verify_provision(value: Any) -> None:
  """Check only the provision fields needed by this forward event."""
  if not isinstance(value, dict):
    fail("provision record is not a JSON object")
  expected = {
    "schema": "TEP_I3_2_HOST_DEPENDENCY_PROVISION_A1",
    "status": "HOST_DEPENDENCY_PROVISIONED",
    "base_python_version": "3.12.13",
    "platform": "darwin",
    "machine": "arm64",
    "dependency_preflight_run": False,
    "staging_retry_run": False,
  }
  for name, target in expected.items():
    if value.get(name) != target:
      fail(f"provision field mismatch: {name}")
  if value.get("installed_versions") != {
      "numpy": "2.3.2", "scipy": "1.18.0"}:
    fail("provision package versions differ from the preflight")
  formal = value.get("formal_matlab")
  if not isinstance(formal, dict) or formal.get("completed_launches") != 0 or \
      formal.get("retry_count") != 0 or formal.get("ecap_a1_consumed") is not False:
    fail("provision formal-attempt history is inconsistent")


def verify_parsed(value: Any) -> None:
  """Require exact versions and all four successful preflight gates."""
  expected = {
    "flags": {
      "loadmat_simplify_cells": True,
      "python_ge_3_9": True,
      "savemat_long_field_names": True,
      "savemat_oned_as_column": True,
    },
    "numpy": "2.3.2",
    "python": "3.12.13",
    "scipy": "1.18.0",
  }
  if value != expected or SHELL_STATUS != 0 or WALL_TIME_SECONDS <= 0:
    fail("fixed preflight evidence is inconsistent")


def read_regular_once(path: Path) -> bytes:
  """Read one regular host record without following its final symlink."""
  flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
  try:
    descriptor = os.open(path, flags)
  except OSError as exc:
    fail(f"provision record is unavailable: {exc}")
  with os.fdopen(descriptor, "rb") as handle:
    if not stat.S_ISREG(os.fstat(handle.fileno()).st_mode):
      fail("provision record is not a regular file")
    return handle.read()


def write_new_json(path: Path, value: dict[str, Any]) -> None:
  """Publish one host-only preflight event without overwrite."""
  flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
  descriptor = os.open(path, flags, 0o600)
  with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
    json.dump(value, handle, indent=2, sort_keys=True)
    handle.write("\n")
    handle.flush()
    os.fsync(handle.fileno())


def sha256_file(path: Path) -> str:
  """Hash one exact machine-side source file."""
  digest = hashlib.sha256()
  with path.open("rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
      digest.update(chunk)
  return digest.hexdigest()


def sha256_bytes(value: bytes) -> str:
  """Hash already opened evidence bytes."""
  return hashlib.sha256(value).hexdigest()


def fail(message: str) -> None:
  """Stop without staging, fallback, or overwrite."""
  raise SystemExit(f"HOST_PREFLIGHT_EVENT_RECORD_UNAVAILABLE: {message}")


if __name__ == "__main__":
  main()
