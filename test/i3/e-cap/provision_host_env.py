#!/usr/bin/env python3
"""Provision the isolated host-only dependency environment for I3.2 staging.

Purpose:
  Create one append-only Python environment for the separately authorized
  fbie-a1 certificate staging operation.

Input:
  No command-line arguments. All paths, versions, hashes, budgets, and the
  official package index are frozen below.

Output:
  /private/tmp/tep-i32-ecap-dep-a1 and its internal host-only provision
  provenance record. The scientific staged input is never opened or created.

Notes:
  This host utility uses only the Python standard library. It must not be run
  before separate provision authorization. Success authorizes only the later
  read-only dependency preflight, not staging or MATLAB.
"""

from __future__ import annotations

import ctypes
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import stat
import subprocess
import sys
import time
from typing import Any


BASE_PYTHON = Path(
  "/Users/whc/.cache/codex-runtimes/codex-primary-runtime/"
  "dependencies/python/bin/python3")
BASE_VERSION = (3, 12, 13)
FINAL_ENV = Path("/private/tmp/tep-i32-ecap-dep-a1")
PARTIAL_ENV = Path("/private/tmp/tep-i32-ecap-dep-a1.partial")
PYPI_INDEX = "https://pypi.org/simple"
NUMPY_VERSION = "2.3.2"
SCIPY_VERSION = "1.18.0"
TIME_BUDGET_SECONDS = 300
STATIC_NETWORK_PLANNING_CAP_BYTES = 100 * 1024 * 1024
DISK_BUDGET_BYTES = 300 * 1024 * 1024
MAX_WHEEL_PAYLOAD_BYTES = 42_866_549
PROVENANCE_RELATIVE = Path("host-provenance/provision-a1.json")
REQUIREMENTS_SNAPSHOT_RELATIVE = Path(
  "host-provision-input/requirements-host-a1.txt")
EXPERIMENT_DIR = Path(__file__).resolve().parent
REQUIREMENTS = EXPERIMENT_DIR / "requirements-host-a1.txt"
REQUIREMENTS_SHA256 = (
  "822ec7bca4e50c3482786f16afc8c883e294b81af92aaad5354c9a03a8c4b6e8")
STAGED_INPUT = EXPERIMENT_DIR / "input" / "fbie-a1-certificate.mat"
FORMAL_OUTPUT = EXPERIMENT_DIR / "output" / "ecap-a1"
RENAME_EXCL = 0x00000004
SCHEMA = "TEP_I3_2_HOST_DEPENDENCY_PROVISION_A1"


def main() -> None:
  """Validate the host and publish one isolated append-only environment."""
  started = time.monotonic()
  utc_started = dt.datetime.now(dt.timezone.utc).isoformat()
  verify_invocation()
  guard_absent(FINAL_ENV, "final environment")
  guard_absent(STAGED_INPUT, "staged input")
  guard_absent(FORMAL_OUTPUT, "formal output")
  requirements_bytes = read_once(REQUIREMENTS)
  requirements_identity = sha256_bytes(requirements_bytes)
  if requirements_identity != REQUIREMENTS_SHA256:
    fail("frozen requirements identity does not match Revision A")
  if shutil.disk_usage(FINAL_ENV.parent).free < DISK_BUDGET_BYTES:
    fail("less than the frozen disk budget is free")

  clean_environment = isolated_environment()
  created_partial = False
  try:
    try:
      os.mkdir(PARTIAL_ENV, 0o700)
    except FileExistsError:
      fail("partial environment already exists")
    created_partial = True
    os.chmod(PARTIAL_ENV, 0o700)
    run_limited([
      str(BASE_PYTHON), "-I", "-m", "venv", "--copies", str(PARTIAL_ENV)
    ], started, clean_environment)
    requirements_snapshot = PARTIAL_ENV / REQUIREMENTS_SNAPSHOT_RELATIVE
    write_new_bytes(requirements_snapshot, requirements_bytes)
    environment_python = PARTIAL_ENV / "bin" / "python3"
    if not environment_python.is_file():
      fail("venv did not create the frozen interpreter path")
    pip_command = [
      str(environment_python), "-I", "-m", "pip", "--isolated", "install",
      "--index-url", PYPI_INDEX,
      "--only-binary=:all:",
      "--no-deps",
      "--require-hashes",
      "--no-cache-dir",
      "--disable-pip-version-check",
      "--no-input",
      "--retries", "0",
      "--timeout", "60",
      "--requirement", str(requirements_snapshot),
    ]
    pip_result = run_limited(pip_command, started, clean_environment)
    installed = installed_versions(environment_python, started,
                                   clean_environment)
    if installed != {"numpy": NUMPY_VERSION, "scipy": SCIPY_VERSION}:
      fail("installed package versions differ from the frozen contract")
    used_bytes = tree_bytes(PARTIAL_ENV)
    if used_bytes > DISK_BUDGET_BYTES:
      fail("provisioned environment exceeds the frozen disk budget")
    elapsed = time.monotonic() - started
    if elapsed > TIME_BUDGET_SECONDS:
      fail("provisioning exceeded the frozen wall-time budget")

    provenance = {
      "schema": SCHEMA,
      "status": "HOST_DEPENDENCY_PROVISIONED",
      "generated_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
      "started_utc": utc_started,
      "base_python": str(BASE_PYTHON),
      "base_python_version": platform.python_version(),
      "base_python_implementation": platform.python_implementation(),
      "platform": sys.platform,
      "machine": platform.machine(),
      "final_environment": str(FINAL_ENV),
      "partial_environment": str(PARTIAL_ENV),
      "official_index": PYPI_INDEX,
      "installed_versions": installed,
      "requirements_source": str(REQUIREMENTS),
      "requirements_snapshot_relative": str(REQUIREMENTS_SNAPSHOT_RELATIVE),
      "requirements_sha256": requirements_identity,
      "provision_script_sha256": sha256(Path(__file__)),
      "pip_stdout_sha256": sha256_text(pip_result.stdout),
      "pip_stderr_sha256": sha256_text(pip_result.stderr),
      "elapsed_before_provenance_seconds": elapsed,
      "environment_bytes": used_bytes,
      "time_budget_seconds": TIME_BUDGET_SECONDS,
      "static_network_planning_cap_bytes": STATIC_NETWORK_PLANNING_CAP_BYTES,
      "network_bytes_measured": False,
      "maximum_compatible_wheel_payload_bytes": MAX_WHEEL_PAYLOAD_BYTES,
      "disk_budget_bytes": DISK_BUDGET_BYTES,
      "python_no_user_site": True,
      "pip_isolated": True,
      "no_dependencies": True,
      "binary_only": True,
      "hash_required": True,
      "prior_host_staging": {
        "completed_launches": 1,
        "last_interpreter": "/usr/bin/python3",
        "last_shell_status": 1,
        "last_code": "HOST_SCIPY_UNAVAILABLE",
        "next_retry_count": 1,
      },
      "formal_matlab": {
        "record_kind": "frozen_prior_history_plus_runtime_absence_guards",
        "completed_launches": 0,
        "retry_count": 0,
        "ecap_a1_consumed": False,
        "staged_input_absent_at_provision_start": True,
        "formal_output_absent_at_provision_start": True,
      },
      "dependency_preflight_run": False,
      "staging_retry_run": False,
      "formal_matlab_must_not_read": True,
    }
    provenance_path = PARTIAL_ENV / PROVENANCE_RELATIVE
    write_new_json(provenance_path, provenance)
    publish_exclusive(PARTIAL_ENV, FINAL_ENV)
    created_partial = False
  except BaseException as exc:
    if created_partial and PARTIAL_ENV.exists():
      try:
        shutil.rmtree(PARTIAL_ENV)
      except Exception as cleanup_error:
        raise SystemExit(
          "HOST_DEPENDENCY_PARTIAL_REMAINS: "
          f"{type(cleanup_error).__name__}: {cleanup_error}") from exc
    if isinstance(exc, SystemExit):
      raise
    fail(f"{type(exc).__name__}: {exc}")


def verify_invocation() -> None:
  """Require the frozen CPython, platform, architecture, and zero arguments."""
  if sys.argv[1:]:
    fail("this command accepts no arguments")
  if not BASE_PYTHON.is_file() or not os.path.samefile(sys.executable,
                                                       BASE_PYTHON):
    fail("script was not launched by the frozen base interpreter")
  if platform.python_implementation() != "CPython":
    fail("base interpreter is not CPython")
  if sys.version_info[:3] != BASE_VERSION:
    fail("base interpreter version is not CPython 3.12.13")
  if sys.platform != "darwin" or platform.machine() != "arm64":
    fail("host is not the frozen macOS arm64 platform")
  if os.environ.get("PYTHONNOUSERSITE") != "1":
    fail("PYTHONNOUSERSITE=1 was not supplied")


def guard_absent(path: Path, label: str) -> None:
  """Reject an existing append-only target."""
  if path.exists() or path.is_symlink():
    fail(f"{label} already exists: {path}")


def isolated_environment() -> dict[str, str]:
  """Remove ambient Python and pip configuration from child processes."""
  environment = dict(os.environ)
  for name in tuple(environment):
    if name.startswith("PYTHON") or name.startswith("PIP"):
      environment.pop(name, None)
  environment["PYTHONNOUSERSITE"] = "1"
  environment["PIP_CONFIG_FILE"] = os.devnull
  return environment


def run_limited(command: list[str], started: float,
                environment: dict[str, str]) -> subprocess.CompletedProcess[str]:
  """Run one frozen child command within the shared wall-time budget."""
  remaining = TIME_BUDGET_SECONDS - (time.monotonic() - started)
  if remaining <= 0:
    fail("provisioning exhausted the frozen wall-time budget")
  return subprocess.run(
    command, check=True, capture_output=True, text=True, env=environment,
    timeout=remaining)


def installed_versions(python: Path, started: float,
                       environment: dict[str, str]) -> dict[str, str]:
  """Read installed distribution metadata without importing NumPy or SciPy."""
  code = (
    "import importlib.metadata as m,json;"
    "print(json.dumps({'numpy':m.version('numpy'),'scipy':m.version('scipy')},"
    "sort_keys=True))")
  completed = run_limited([str(python), "-I", "-c", code], started,
                          environment)
  value = json.loads(completed.stdout)
  if not isinstance(value, dict) or set(value) != {"numpy", "scipy"}:
    fail("installed-version audit returned an invalid record")
  return {name: str(version) for name, version in value.items()}


def tree_bytes(root: Path) -> int:
  """Return the regular-file byte count below one exact partial directory."""
  total = 0
  for directory, _, filenames in os.walk(root, followlinks=False):
    for filename in filenames:
      path = Path(directory) / filename
      if path.is_file() and not path.is_symlink():
        total += path.stat().st_size
  return total


def read_once(path: Path) -> bytes:
  """Open one regular machine input once without following a symlink."""
  flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
  try:
    descriptor = os.open(path, flags)
  except OSError as exc:
    fail(f"frozen requirements file is unavailable: {exc}")
  with os.fdopen(descriptor, "rb") as handle:
    if not stat.S_ISREG(os.fstat(handle.fileno()).st_mode):
      fail("frozen requirements input is not a regular file")
    return handle.read()


def write_new_bytes(path: Path, value: bytes) -> None:
  """Snapshot verified requirements inside the atomically owned partial."""
  path.parent.mkdir(mode=0o700, parents=True, exist_ok=False)
  flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
  descriptor = os.open(path, flags, 0o400)
  with os.fdopen(descriptor, "wb") as handle:
    handle.write(value)
    handle.flush()
    os.fsync(handle.fileno())


def write_new_json(path: Path, value: dict[str, Any]) -> None:
  """Create one host-only provenance record without overwrite."""
  path.parent.mkdir(parents=True, exist_ok=False)
  flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
  descriptor = os.open(path, flags, 0o600)
  with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
    json.dump(value, handle, indent=2, sort_keys=True)
    handle.write("\n")
    handle.flush()
    os.fsync(handle.fileno())


def publish_exclusive(source: Path, target: Path) -> None:
  """Atomically rename on macOS and reject any destination that appears."""
  library = ctypes.CDLL(None, use_errno=True)
  try:
    renamex = library.renamex_np
  except AttributeError:
    fail("macOS renamex_np is unavailable")
  renamex.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_uint]
  renamex.restype = ctypes.c_int
  status = renamex(os.fsencode(source), os.fsencode(target), RENAME_EXCL)
  if status != 0:
    error_number = ctypes.get_errno()
    raise OSError(error_number, os.strerror(error_number), str(target))


def sha256(path: Path) -> str:
  """Hash one exact machine-side file."""
  digest = hashlib.sha256()
  with path.open("rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
      digest.update(chunk)
  return digest.hexdigest()


def sha256_bytes(value: bytes) -> str:
  """Hash already opened machine input bytes without reopening their path."""
  return hashlib.sha256(value).hexdigest()


def sha256_text(value: str) -> str:
  """Hash captured child-process text for compact provenance."""
  return hashlib.sha256(value.encode("utf-8")).hexdigest()


def fail(message: str) -> None:
  """Stop without a scientific artifact or fallback."""
  raise SystemExit(f"HOST_DEPENDENCY_PROVISION_UNAVAILABLE: {message}")


if __name__ == "__main__":
  main()
