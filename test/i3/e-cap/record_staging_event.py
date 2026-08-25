#!/usr/bin/env python3
"""Publish the already completed I3.2 host staging retry as one event.

Purpose:
  Record the fixed staging command, outcome, target identity, and reviewed MAT
  schema/provenance without rerunning the stager or parsing the staged input.

Input:
  No arguments. The recorder reads only fixed file identities and host state.

Output:
  /private/tmp/tep-i32-ecap-dep-a1/host-provenance/staging-a1.json,
  created once with O_EXCL and mode 0600.

Notes:
  This standard-library script never imports NumPy/SciPy, starts MATLAB, or
  changes the staged input, historical source, or prior host events.
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
PREFLIGHT = FINAL_ENV / "host-provenance/preflight-a1.json"
EVENT = FINAL_ENV / "host-provenance/staging-a1.json"
EXPERIMENT_DIR = Path(__file__).resolve().parent
SOURCE = EXPERIMENT_DIR.parent / "fb-resid/output/fbie-a1/result.mat"
STAGER = EXPERIMENT_DIR / "stage_fbie_input.py"
TARGET = EXPERIMENT_DIR / "input/fbie-a1-certificate.mat"
FORMAL_OUTPUT = EXPERIMENT_DIR / "output/ecap-a1"

SCHEMA = "TEP_I3_2_HOST_STAGING_EVENT_A1"
TARGET_SCHEMA = "TEP_I3_2_STAGED_FBIE_A1_CERTIFICATE_V1"
SOURCE_SHA256 = (
  "276d1c52ed4ca6f522c47359e22771a63d23a8d9b5b5ca0443d32f66417b1592")
STAGER_SHA256 = (
  "c21e371d420b917e42bcae8f178470acddb30ba69ea3bc03d5f69cd8af11f9f9")
TARGET_SHA256 = (
  "bb502ed97bfda5d60bd653fcb9e75f67fe15e86e053e160750ed5a735280e1b3")
PROVISION_SHA256 = (
  "193ad311278add47ec08bcff8e86aa3a7529c7ca477129aa2c302189cca2cde8")
PREFLIGHT_SHA256 = (
  "86b76821fd926f1fd03c66f3fd33d5bcf77b61a6fe2ae94f0e08b3becfe468b3")
TARGET_SIZE_BYTES = 40978143
TARGET_MODE = 0o600
SHELL_STATUS = 0
WALL_TIME_SECONDS = 1.495451792
RAW_STDOUT = ""
STAGING_COMMAND = (
  "PYTHONNOUSERSITE=1 "
  "/private/tmp/tep-i32-ecap-dep-a1/bin/python3 -I "
  "test/i3/e-cap/stage_fbie_input.py "
  "--source test/i3/fb-resid/output/fbie-a1/result.mat "
  "--target test/i3/e-cap/input/fbie-a1-certificate.mat")
STAGING_PROVENANCE = {
  "source_sha256": SOURCE_SHA256,
  "source_path_at_staging": (
    "/Users/whc/Documents/Work/epost/"
    "test/i3/fb-resid/output/fbie-a1/result.mat"),
  "generated_utc": "2026-08-24T17:24:44.937413+00:00",
  "host_tool": "stage_fbie_input.py",
  "formal_runtime_variable": False,
}


def main() -> None:
  """Validate immutable host state and publish the fixed staging event."""
  verify_invocation()
  verify_paths()
  provision = read_json_identity(PROVISION, PROVISION_SHA256)
  preflight = read_json_identity(PREFLIGHT, PREFLIGHT_SHA256)
  verify_prior_events(provision, preflight)
  identities = {
    "source_sha256": hash_regular_file(SOURCE),
    "stager_sha256": hash_regular_file(STAGER),
    "target_sha256": hash_regular_file(
      TARGET, expected_mode=TARGET_MODE, expected_size=TARGET_SIZE_BYTES),
  }
  expected = {
    "source_sha256": SOURCE_SHA256,
    "stager_sha256": STAGER_SHA256,
    "target_sha256": TARGET_SHA256,
  }
  if identities != expected:
    fail("source, stager, or staged-target identity differs from review")
  event = {
    "schema": SCHEMA,
    "status": "HOST_STAGING_SUCCEEDED",
    "recorded_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    "command": STAGING_COMMAND,
    "shell_status": SHELL_STATUS,
    "wall_time_seconds": WALL_TIME_SECONDS,
    "raw_stdout": RAW_STDOUT,
    "raw_stdout_sha256": sha256_bytes(RAW_STDOUT.encode("utf-8")),
    "host_staging_completed_launches": 2,
    "host_staging_retry_count": 1,
    "initial_failure": {
      "interpreter": "ambient system python3 command",
      "shell_status": 1,
      "outcome": "HOST_SCIPY_UNAVAILABLE",
      "target_created": False,
    },
    "successful_retry": {
      "interpreter": "/private/tmp/tep-i32-ecap-dep-a1/bin/python3",
      "retry_count": 1,
      "shell_status": SHELL_STATUS,
      "wall_time_seconds": WALL_TIME_SECONDS,
      "raw_stdout": RAW_STDOUT,
    },
    "target": {
      "path": str(TARGET),
      "mode": "0600",
      "size_bytes": TARGET_SIZE_BYTES,
      "sha256": TARGET_SHA256,
      "top_level_variables": ["staged", "staging_provenance"],
      "staged_input_schema": TARGET_SCHEMA,
      "staging_provenance": STAGING_PROVENANCE,
      "identity_basis": (
        "exact target SHA-256 plus completed read-only host MAT audit"),
      "parsed_by_recorder": False,
    },
    "source_artifact": {
      "path": str(SOURCE),
      "sha256": SOURCE_SHA256,
      "parsed_by_recorder": False,
    },
    "stager": {"path": str(STAGER), "sha256": STAGER_SHA256},
    "provision_record_sha256": PROVISION_SHA256,
    "preflight_record_sha256": PREFLIGHT_SHA256,
    "recorder_script_sha256": hash_regular_file(Path(__file__)),
    "partial_environment_absent": True,
    "formal_output_absent": True,
    "formal_matlab": {
      "completed_launches": 0,
      "retry_count": 0,
      "ecap_a1_consumed": False,
    },
    "next_gate": "SEPARATE_FORMAL_MATLAB_AUTHORIZATION",
    "formal_matlab_must_not_read": True,
  }
  write_new_json(EVENT, event)


def verify_invocation() -> None:
  """Require the frozen standard-library recorder invocation."""
  if sys.argv[1:]:
    fail("this command accepts no arguments")
  if not BASE_PYTHON.is_file() or not os.path.samefile(sys.executable,
                                                       BASE_PYTHON):
    fail("recorder was not launched by the frozen base interpreter")
  if os.environ.get("PYTHONNOUSERSITE") != "1":
    fail("PYTHONNOUSERSITE=1 was not supplied")


def verify_paths() -> None:
  """Require the completed staging state and absence of later artifacts."""
  if not FINAL_ENV.is_dir() or FINAL_ENV.is_symlink():
    fail("final environment is unavailable or is a symlink")
  if stat.S_IMODE(FINAL_ENV.stat().st_mode) != 0o700:
    fail("final environment mode is not 0700")
  if not EVENT.parent.is_dir() or EVENT.parent.is_symlink():
    fail("host-provenance directory is unavailable or is a symlink")
  for path, label in (
      (PARTIAL_ENV, "partial environment"),
      (FORMAL_OUTPUT, "formal output"),
      (EVENT, "staging event")):
    if path.exists() or path.is_symlink():
      fail(f"{label} already exists: {path}")
  if not TARGET.is_file() or TARGET.is_symlink():
    fail("the staged target is absent or is a symlink")


def verify_prior_events(provision: Any, preflight: Any) -> None:
  """Require exact prior host status and an unconsumed formal attempt."""
  if not isinstance(provision, dict) or not isinstance(preflight, dict):
    fail("a prior host event is not a JSON object")
  if provision.get("schema") != "TEP_I3_2_HOST_DEPENDENCY_PROVISION_A1" or \
      provision.get("status") != "HOST_DEPENDENCY_PROVISIONED":
    fail("provision event status is inconsistent")
  if preflight.get("schema") != "TEP_I3_2_HOST_DEPENDENCY_PREFLIGHT_A1" or \
      preflight.get("status") != "HOST_DEPENDENCY_PREFLIGHT_PASS" or \
      preflight.get("shell_status") != 0:
    fail("preflight event status is inconsistent")
  formal = preflight.get("formal_matlab")
  if not isinstance(formal, dict) or formal.get("completed_launches") != 0 or \
      formal.get("retry_count") != 0 or \
      formal.get("ecap_a1_consumed") is not False:
    fail("formal-attempt history is inconsistent")
  if preflight.get("staging_retry_run") is not False or \
      preflight.get("host_staging_retry_count") != 1:
    fail("preflight event does not precede the frozen staging retry")


def read_json_identity(path: Path, expected_sha256: str) -> Any:
  """Read one exact regular JSON event without following its final symlink."""
  value = read_regular_once(path)
  if sha256_bytes(value) != expected_sha256:
    fail(f"prior event identity differs: {path}")
  try:
    return json.loads(value)
  except (UnicodeDecodeError, json.JSONDecodeError) as exc:
    fail(f"prior event is not valid JSON: {exc}")


def read_regular_once(path: Path) -> bytes:
  """Read one regular file without following its final symlink."""
  flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
  try:
    descriptor = os.open(path, flags)
  except OSError as exc:
    fail(f"required file is unavailable: {path}: {exc}")
  with os.fdopen(descriptor, "rb") as handle:
    if not stat.S_ISREG(os.fstat(handle.fileno()).st_mode):
      fail(f"required path is not a regular file: {path}")
    return handle.read()


def hash_regular_file(path: Path, expected_mode: int | None = None,
                      expected_size: int | None = None) -> str:
  """Hash one regular file while checking optional frozen metadata."""
  flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
  try:
    descriptor = os.open(path, flags)
  except OSError as exc:
    fail(f"required file is unavailable: {path}: {exc}")
  digest = hashlib.sha256()
  with os.fdopen(descriptor, "rb") as handle:
    metadata = os.fstat(handle.fileno())
    if not stat.S_ISREG(metadata.st_mode):
      fail(f"required path is not a regular file: {path}")
    if expected_mode is not None and \
        stat.S_IMODE(metadata.st_mode) != expected_mode:
      fail(f"required file mode differs: {path}")
    if expected_size is not None and metadata.st_size != expected_size:
      fail(f"required file size differs: {path}")
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
      digest.update(chunk)
  return digest.hexdigest()


def write_new_json(path: Path, value: dict[str, Any]) -> None:
  """Publish one host-only staging event without overwrite."""
  flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
  descriptor = os.open(path, flags, 0o600)
  with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
    json.dump(value, handle, indent=2, sort_keys=True)
    handle.write("\n")
    handle.flush()
    os.fsync(handle.fileno())


def sha256_bytes(value: bytes) -> str:
  """Hash already opened evidence bytes."""
  return hashlib.sha256(value).hexdigest()


def fail(message: str) -> None:
  """Stop without staging, fallback, overwrite, or MATLAB."""
  raise SystemExit(f"HOST_STAGING_EVENT_RECORD_UNAVAILABLE: {message}")


if __name__ == "__main__":
  main()
