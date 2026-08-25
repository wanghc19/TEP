#!/usr/bin/env python3
"""Stage the immutable fbie-a1 certificate for the I3.2 evaluator.

Purpose:
  Perform a separately authorized host-side, append-only whitelist extraction.
  The formal MATLAB entry never reads or hashes historical experiment output.

Input:
  --source: explicit immutable fbie-a1 result.mat
  --target: explicit new e-cap input .mat; it must not exist

Output:
  A formal-runtime variable named ``staged`` plus a separate host-only
  ``staging_provenance`` variable that MATLAB never loads.

Notes:
  This is intentionally not a MATLAB entry point. It requires Python with
  scipy and must not be executed before separate staging authorization.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import os
from pathlib import Path
import tempfile
from typing import Any

try:
  import numpy as np
  from scipy.io import loadmat, savemat
except ImportError as exc:  # pragma: no cover - exercised only by host setup
  raise SystemExit("staging requires a host Python environment with scipy") from exc


SOURCE_SHA256 = "276d1c52ed4ca6f522c47359e22771a63d23a8d9b5b5ca0443d32f66417b1592"
SOURCE_ATTEMPT = "fbie-a1"
SOURCE_SCHEMA = "TEP_I3_1_FULL_BOUNDARY_CELL_BIE_RESIDUAL_V1"
TARGET_SCHEMA = "TEP_I3_2_STAGED_FBIE_A1_CERTIFICATE_V1"


def main() -> None:
  """Validate, whitelist, and append-only publish one staged input."""
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--source", required=True, type=Path)
  parser.add_argument("--target", required=True, type=Path)
  args = parser.parse_args()
  source = args.source.expanduser().resolve()
  target = args.target.expanduser().resolve()
  if not source.is_file():
    raise SystemExit(f"explicit source is unavailable: {source}")
  if target.exists():
    raise SystemExit(f"append-only target already exists: {target}")

  source_before = sha256(source)
  if source_before != SOURCE_SHA256:
    raise SystemExit("fbie-a1 source SHA-256 is not the frozen artifact hash")
  loaded = loadmat(source, simplify_cells=True)
  result = require(loaded, "result")
  source_gate(result)
  staged = build_staged(result)
  provenance = {
    "source_sha256": source_before,
    "source_path_at_staging": str(source),
    "generated_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    "host_tool": Path(__file__).name,
    "formal_runtime_variable": False,
  }
  source_after = sha256(source)
  if source_after != source_before:
    raise SystemExit("immutable source changed during staging")

  target.parent.mkdir(parents=True, exist_ok=True)
  descriptor, temporary_name = tempfile.mkstemp(
    dir=target.parent, prefix=".fbie-a1-stage-", suffix=".mat")
  os.close(descriptor)
  temporary = Path(temporary_name)
  try:
    savemat(temporary, {"staged": staged, "staging_provenance": provenance},
            do_compression=True,
            long_field_names=True, oned_as="column")
    os.link(temporary, target)  # fails rather than overwriting a raced target
  finally:
    temporary.unlink(missing_ok=True)


def build_staged(r: dict[str, Any]) -> dict[str, Any]:
  """Copy only the preregistered certificate and audit whitelist."""
  c = require(r, "config")
  m = require(r, "small_maps")
  b = require(r, "boundary")
  coordinates = require(r, "coordinates")
  full = require(m, "full_boundary_maps")
  source_port = require(require(r, "branch"), "port")
  branch_t = np.asarray(require(source_port, "t_m"), dtype=float)
  branch_class = np.zeros(branch_t.shape, dtype=np.int8)
  branch_class[branch_t > 0] = 1
  branch_class[branch_t < 0] = -1
  branch_port = {
    "beta_m": require(source_port, "beta_m"),
    "gamma_m": require(source_port, "gamma_m"),
    "t_m": require(source_port, "t_m"),
    "classification": branch_class,
    "outgoing_reference": require(source_port, "outgoing_reference"),
    "outgoing_relative_defects": require(source_port, "outgoing_relative_defects"),
    "outgoing_sign_pass": require(source_port, "outgoing_sign_pass"),
    "axis_pass": require(source_port, "axis_pass"),
    "available": require(source_port, "available"),
    "pass": require(source_port, "pass"),
  }

  certificate = {
    "source_attempt": SOURCE_ATTEMPT,
    "khat": require(c, "khat"),
    "mu_h": require(c, "mu_h"),
    "gamma": require(c, "gamma"),
    "beta": require(c, "beta"),
    "d": require(c, "d"),
    "R": require(c, "R"),
    "rho_disk": require(c, "rho_disk"),
    "X_L": require(c, "X_L"),
    "X_R": require(c, "X_R"),
    "L": require(c, "L"),
    "M": require(c, "M"),
    "K": require(c, "K"),
    "delta_c": require(c, "delta_c"),
    "delta_w": require(c, "delta_w"),
    "q_center": require(m, "weighted_q"),
    "Pplus": require(m, "Pplus"),
    "Pminus": require(m, "Pminus"),
    "cplus": require(coordinates, "cplus"),
    "cminus": require(coordinates, "cminus"),
    "Dplus": require(m, "Dplus"),
    "Dminus": require(m, "Dminus"),
    "Gplus": require(m, "Gplus"),
    "Gminus": require(m, "Gminus"),
    "branch_port": branch_port,
    "eta_unit_256": require(m, "physical_unit_density"),
    "xi_left_unit_512": require(full, "xi_left_unit"),
    "xi_right_unit_512": require(full, "xi_right_unit"),
    "wall_input_unit_512": require(full, "wall_input_unit"),
    "wall_orders_512": require(m, "wall_orders_512"),
    "center_actual_left_trace": require(m, "center_actual_left_trace"),
    "center_actual_right_trace": require(m, "center_actual_right_trace"),
    "center_shared_left_trace": require(m, "center_shared_left_trace"),
    "center_shared_right_trace": require(m, "center_shared_right_trace"),
    "center_left_value_mismatch": require(m, "center_left_value_mismatch"),
    "center_right_value_mismatch": require(m, "center_right_value_mismatch"),
    "center_wall_jumps": require(m, "center_wall_jumps"),
    "density_coordinate": require(m, "density_coordinate"),
    "global_normal_label": require(b, "normal_orientation"),
    "lift_contract": {
      "delta_c": require(c, "delta_c"),
      "delta_w": require(c, "delta_w"),
      "shape": "chi(t)=1-3*t^2+2*t^3",
      "circle_value_only": True,
      "wall_value_only": True,
      "exact_amplitude_rule": "shared value minus exact continuous raw trace",
    },
  }

  estimator = require(r, "estimator")
  tails = require(r, "tails")
  ordinary_anchor = {
    "B_wall": require(estimator, "wall_component"),
    "B_circle": require(estimator, "circle_component"),
    "B_volume": require(estimator, "collar_volume_component"),
    "M_tilde": require(estimator, "triangle_majorant"),
    "N_tilde": require(estimator, "field_lower_squared"),
    "lead_wall_factor_plus": require(m, "lead_wall_factor_plus"),
    "lead_wall_factor_minus": require(m, "lead_wall_factor_minus"),
    "lead_circle_factor_plus": require(m, "lead_circle_factor_plus"),
    "lead_circle_factor_minus": require(m, "lead_circle_factor_minus"),
    "lead_volume_factor_plus": require(m, "lead_volume_factor_plus"),
    "lead_volume_factor_minus": require(m, "lead_volume_factor_minus"),
    "lead_field_factor_plus": require(m, "lead_field_factor_plus"),
    "lead_field_factor_minus": require(m, "lead_field_factor_minus"),
    "center_plus_wall_lift_factor": require(m, "center_plus_wall_lift_factor"),
    "center_minus_wall_lift_factor": require(m, "center_minus_wall_lift_factor"),
    "center_left_value_lift_source": require(m, "center_left_value_lift_source"),
    "center_right_value_lift_source": require(m, "center_right_value_lift_source"),
    "center_wall_jumps": require(m, "center_wall_jumps"),
    "tail_minus": {"selected_N": require(require(tails, "minus"), "selected_N")},
    "tail_plus": {"selected_N": require(require(tails, "plus"), "selected_N")},
    "first_level_indices": {
      "minus_physical_start": require(require(tails, "minus"),
                                      "physical_start_indices"),
      "plus_physical_start": require(require(tails, "plus"),
                                     "physical_start_indices"),
      "minus_selected_N": require(require(tails, "minus"), "selected_N"),
      "plus_selected_N": require(require(tails, "plus"), "selected_N"),
    },
  }

  # Raw maps are staged separately from already weighted factors. They are
  # required to rebuild artifact quantities on the final common coordinates.
  raw_maps = {
    "delta_plus": require(m, "delta_plus"),
    "delta_minus": require(m, "delta_minus"),
    "circle_jump_plus": require(m, "circle_jump_plus"),
    "circle_jump_minus": require(m, "circle_jump_minus"),
    "QLplus": require(m, "QLplus"),
    "QRplus": require(m, "QRplus"),
    "QLminus": require(m, "QLminus"),
    "QRminus": require(m, "QRminus"),
    "Jplus": require(m, "Jplus"),
    "Jminus": require(m, "Jminus"),
    "wall_flux_left_unit_512": require(m, "wall_flux_left_unit_512"),
    "wall_flux_right_unit_512": require(m, "wall_flux_right_unit_512"),
    "circle_delta_D_unit_wall_512": require(m, "circle_delta_D_unit_wall_512"),
    "circle_j_Gamma_unit_wall_512": require(m, "circle_j_Gamma_unit_wall_512"),
    "circle_orders_512": np.arange(-256, 256, dtype=np.int64),
    "circle_theta_512": require(m, "circle_theta_512"),
    "wall_common_y_1024": require(full, "common_y"),
    "wall_common_value_1024": require(full, "common_value_official"),
    "wall_common_flux_1024": require(full, "common_flux_official"),
    "wall_input_unit_512": require(full, "wall_input_unit"),
    "circle_value_residual_unit_512": require(full, "circle_value_residual_unit"),
    "circle_normal_residual_unit_512": require(full, "circle_normal_residual_unit"),
  }

  cell_bie = require(r, "cell_bie")
  first_warning = require(r, "first_nonblocking_failure")
  historical_diagnostics = {
    "circle_action_metric": require(cell_bie, "circle_action_metric"),
    "circle_action_change": require(cell_bie, "circle_action_change"),
    "circle_angular_tail_metric": require(cell_bie, "circle_angular_tail_metric"),
    "outside_M_metric": require(b, "circle_outside_retained_band_metric"),
    "historical_warning_label": text(require(first_warning, "code")),
  }

  input_contract = {
    "schema": TARGET_SCHEMA,
    "source_attempt": SOURCE_ATTEMPT,
    "staging_only": True,
    "formal_runtime_must_not_read_historical_output": True,
    "M_role": "97 retained QZ wall-input modes only",
    "eta_source_nodes": 256,
    "wall_source_orders": 512,
    "no_resolve_required": True,
    "density_coordinate": "[tau;zeta], zeta=-sigma",
    "circle_basis": "exp(i*l*theta)/sqrt(2*pi*R) in L2(ds)",
    "wall_basis": "d^(-1/2)*exp(i*(beta+2*pi*m/d)*y)",
    "circle_ordering": "-N/2:N/2-1 with negative Nyquist retained",
    "wall_output_ordering": "-N/2:N/2-1 with negative Nyquist retained",
    "branch_classification_encoding": "int8: +1 propagating, -1 evanescent, 0 Wood",
    "circle_value_only_lift": True,
    "wall_value_only_lift": True,
    "lift_shape": "chi(t)=1-3*t^2+2*t^3",
    "exact_lift_amplitude_rule": "shared value minus exact continuous raw trace",
  }
  return {
    "input_contract": input_contract,
    "certificate": certificate,
    "ordinary_anchor": ordinary_anchor,
    "raw_maps": raw_maps,
    "historical_diagnostics": historical_diagnostics,
  }


def source_gate(r: dict[str, Any]) -> None:
  """Reject anything except the consumed, finite fbie-a1 producer schema."""
  if text(require(r, "attempt")) != SOURCE_ATTEMPT:
    raise SystemExit("source attempt is not fbie-a1")
  if text(require(r, "schema")) != SOURCE_SCHEMA:
    raise SystemExit("source schema is not the frozen fbie-a1 schema")
  for name in ("config", "coordinates", "branch", "small_maps", "boundary",
               "tails", "estimator", "cell_bie", "first_nonblocking_failure"):
    require(r, name)
  m = require(r, "small_maps")
  for name in (
      "Pplus", "Pminus", "Dplus", "Dminus", "Gplus", "Gminus",
      "weighted_q", "physical_unit_density", "wall_orders_512",
      "full_boundary_maps", "QLplus", "QRplus", "QLminus", "QRminus",
      "Jplus", "Jminus", "delta_plus", "delta_minus",
      "circle_jump_plus", "circle_jump_minus",
      "wall_flux_left_unit_512", "wall_flux_right_unit_512",
      "circle_delta_D_unit_wall_512", "circle_j_Gamma_unit_wall_512",
      "lead_wall_factor_plus", "lead_wall_factor_minus",
      "lead_circle_factor_plus", "lead_circle_factor_minus",
      "lead_volume_factor_plus", "lead_volume_factor_minus",
      "lead_field_factor_plus", "lead_field_factor_minus"):
    require(m, name)
  full = require(m, "full_boundary_maps")
  for name in ("xi_left_unit", "xi_right_unit", "wall_input_unit",
               "common_y", "common_value_official", "common_flux_official",
               "circle_value_residual_unit", "circle_normal_residual_unit"):
    require(full, name)
  estimator = require(r, "estimator")
  anchors = np.asarray([
    require(estimator, "wall_component"),
    require(estimator, "circle_component"),
    require(estimator, "collar_volume_component"),
    require(estimator, "triangle_majorant"),
    require(estimator, "field_lower_squared"),
  ], dtype=float)
  if not np.all(np.isfinite(anchors)) or not np.all(anchors > 0):
    raise SystemExit("an ordinary fbie-a1 anchor is unavailable")


def require(value: Any, name: str) -> Any:
  """Return one mandatory field from a scipy simplified MATLAB struct."""
  if not isinstance(value, dict) or name not in value:
    raise SystemExit(f"missing staged source field: {name}")
  return value[name]


def text(value: Any) -> str:
  """Normalize one MATLAB character/string scalar."""
  if isinstance(value, str):
    return value
  array = np.asarray(value)
  if array.size != 1:
    raise SystemExit("expected a scalar string field")
  return str(array.reshape(-1)[0])


def sha256(path: Path) -> str:
  """Stream one file into SHA-256 without loading it into memory."""
  digest = hashlib.sha256()
  with path.open("rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
      digest.update(chunk)
  return digest.hexdigest()


if __name__ == "__main__":
  main()
