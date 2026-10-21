#!/usr/bin/python3
"""Reviewer-side field-identity audit for run-008.

Purpose:
  Reconstruct old run-007 candidate 7 on five prescribed twists and compare
  its full fine-mesh field inventory with the run-008 s=30 inventory.
Main algorithm:
  Decode only the MATLAB v7.3 fields frozen by design sections 46--47,
  rebuild the old common grid by deterministic P1 interpolation, normalize
  every object in the weighted Gram metric, compute principal overlaps with a
  pure-Python Hermitian Jacobi method, and solve the complete dummy-augmented
  lexicographic assignment at each twist.
Based on:
  research/projects/eig-apost/implementation/i4/design-4-1a.md sections 46--47.
Main changes:
  This read-only reviewer entry does not run FEM solves or change either
  canonical scientific artifact.
Numerical goal:
  Publish one RFC 8259 identity-audit.json with a same-mode, ambiguous, or
  unavailable result for old candidate 7.
"""

import ctypes
import json
import math
import os
import sys


HDF5_LIBRARY = (
  "/Applications/MATLAB_R2023b.app/bin/maca64/libhdf5-1.8.8.dylib"
)
OLD_SCHEMA = "i4a-diagnostic-ranking-v2"
NEW_SCHEMA = "i4a-s30-refinement-v1"
NEW_FIELDS_SCHEMA = "i4a-s30-fields-v1"
AUDIT_SCHEMA = "i4a-candidate7-identity-v1"
OLD_RUN_ID = "run-007"
NEW_RUN_ID = "run-008"
EXECUTION_ID = "execution-001"
AUDIT_ID = "identity-003"
TARGET_THETA_INDICES = (1, 5, 9, 13, 17)
TARGET_SOLVE_IDS = ("fine-p01", "fine-p05", "fine-p09", "fine-p13", "fine-p17")
TARGET_PHASES = (0.0, math.pi / 4.0, math.pi / 2.0, 3.0 * math.pi / 4.0, math.pi)
OLD_MESH_ID = "defect-N5-s24-g48"
NEW_MESH_ID = "defect-N5-s30-g60"
W3 = (0.45, 3.25)
BINARY64_EPSILON = 2.0 ** -52
BARYCENTRIC_TOLERANCE = 64.0 * BINARY64_EPSILON
GRAM_HERMITIAN_TOLERANCE = 5.0e-13
WEIGHT_TOLERANCE = 1.0e-14
JACOBI_SCALE_FACTOR = 64.0 * BINARY64_EPSILON
INTERFACE_TOLERANCE = 1.0e-12
INTERFACE_CENTERS = (-2.0, -1.0, 1.0, 2.0)
INTERFACE_RADIUS = 0.2
Q_INSIDE = 17.0
Q_OUTSIDE = 1.0


class AuditUnavailable(Exception):
  """A frozen input, decoder, or numerical requirement is unavailable."""


class MatArray:
  """MATLAB-shaped column-major data decoded from one HDF5 dataset."""

  def __init__(self, shape, data):
    self.shape = tuple(int(value) for value in shape)
    self.data = list(data)


LEAF = object()


OLD_OBJECT_SPEC = {
  "object_id": LEAF,
  "configuration": LEAF,
  "solve_id": LEAF,
  "mesh_id": LEAF,
  "theta": LEAF,
  "theta_index": LEAF,
  "cluster_id": LEAF,
  "root_index": LEAF,
  "root_indices": LEAF,
  "dimension": LEAF,
  "eigenvalues": LEAF,
  "frequencies": LEAF,
  "lambda_envelope": LEAF,
  "k_envelope": LEAF,
  "L0_min": LEAF,
  "Lcore_min": LEAF,
  "tail_max": LEAF,
  "localization_status": LEAF,
  "parity_label": LEAF,
  "parity_status": LEAF,
}

NEW_COMPACT_OBJECT_SPEC = dict(OLD_OBJECT_SPEC)
del NEW_COMPACT_OBJECT_SPEC["configuration"]
NEW_OBJECT_SPEC = dict(NEW_COMPACT_OBJECT_SPEC)
NEW_OBJECT_SPEC.update({
  "common_core_samples": LEAF,
  "common_core_weights": LEAF,
  "common_core_valid": LEAF,
})

OLD_CANDIDATE_SPEC = {
  "candidate_id": LEAF,
  "realization_ids": LEAF,
}

NEW_CANDIDATE_SPEC = {
  "candidate_id": LEAF,
  "realization_ids": LEAF,
  "lambda_30": LEAF,
  "k_30": LEAF,
}

EDGE_SPEC = {
  "source_object_id": LEAF,
  "target_object_id": LEAF,
  "axis": LEAF,
  "kind": LEAF,
  "overlap": LEAF,
}

COMPONENT_SPEC = {
  "candidate_id": LEAF,
  "realization_ids": LEAF,
}

OLD_SCIENCE_SPEC = {
  "schema_version": LEAF,
  "run_id": LEAF,
  "execution_id": LEAF,
  "spec": {
    "localization_center_min": LEAF,
    "localization_core_min": LEAF,
    "tail_max": LEAF,
  },
  "candidate_inventory": {
    "objects": OLD_OBJECT_SPEC,
    "candidates": OLD_CANDIDATE_SPEC,
  },
  "tracking": {
    "edges": EDGE_SPEC,
    "components": COMPONENT_SPEC,
  },
}

OLD_MESH_SPEC = {
  "id": LEAF,
  "points": LEAF,
  "triangles": LEAF,
}

OLD_SPECTRUM_SPEC = {
  "mesh_id": LEAF,
  "phase": LEAF,
  "eigenvalues": LEAF,
  "frequencies": LEAF,
  "cluster_ids": LEAF,
  "vectors_full": LEAF,
}

NEW_SCIENCE_SPEC = {
  "schema_version": LEAF,
  "run_id": LEAF,
  "execution_id": LEAF,
  "spec": {
    "localization_center_min": LEAF,
    "localization_core_min": LEAF,
    "tail_max": LEAF,
  },
  "candidate_inventory": {
    "objects": NEW_COMPACT_OBJECT_SPEC,
    "candidates": NEW_CANDIDATE_SPEC,
  },
  "tracking": {
    "edges": EDGE_SPEC,
    "components": COMPONENT_SPEC,
  },
  "selected_candidate": {
    "candidate_id": LEAF,
    "lambda_30": LEAF,
    "k_30": LEAF,
  },
}

NEW_FIELDS_SPEC = {
  "schema_version": LEAF,
  "run_id": LEAF,
  "execution_id": LEAF,
  "mesh_id": LEAF,
  "theta_5": LEAF,
  "objects": NEW_OBJECT_SPEC,
  "winner_candidate_id": LEAF,
  "lambda_30": LEAF,
  "k_30": LEAF,
}


class Hdf5MatFile:
  """Allowlisted MATLAB v7.3 reader using the fixed HDF5 1.8 library."""

  H5I_GROUP = 2
  H5I_DATASET = 5
  H5T_INTEGER = 0
  H5T_FLOAT = 1
  H5T_STRING = 3
  H5T_COMPOUND = 6
  H5T_REFERENCE = 7
  H5T_SGN_NONE = 0

  def __init__(self, path):
    self.path = path
    self.lib = None
    self.file_id = -1

  def __enter__(self):
    try:
      self.lib = ctypes.CDLL(HDF5_LIBRARY)
    except OSError as error:
      raise AuditUnavailable("HDF5_LIBRARY_UNAVAILABLE") from error
    try:
      self._bind()
    except (AttributeError, TypeError) as error:
      raise AuditUnavailable("HDF5_BINDING_UNAVAILABLE") from error
    if self.lib.H5open() < 0:
      raise AuditUnavailable("HDF5_INITIALIZATION_FAILED")
    encoded = os.fsencode(self.path)
    self.file_id = self.lib.H5Fopen(encoded, 0, 0)
    if self.file_id < 0:
      raise AuditUnavailable("HDF5_INPUT_OPEN_FAILED")
    return self

  def __exit__(self, exception_type, exception, traceback):
    if self.file_id >= 0:
      self.lib.H5Fclose(self.file_id)
      self.file_id = -1

  def _bind(self):
    hid = ctypes.c_longlong
    hsize = ctypes.c_ulonglong
    self.lib.H5open.argtypes = []
    self.lib.H5open.restype = ctypes.c_int
    self.lib.H5Fopen.argtypes = [ctypes.c_char_p, ctypes.c_uint, hid]
    self.lib.H5Fopen.restype = hid
    self.lib.H5Fclose.argtypes = [hid]
    self.lib.H5Fclose.restype = ctypes.c_int
    self.lib.H5Oopen.argtypes = [hid, ctypes.c_char_p, hid]
    self.lib.H5Oopen.restype = hid
    self.lib.H5Oclose.argtypes = [hid]
    self.lib.H5Oclose.restype = ctypes.c_int
    self.lib.H5Gclose.argtypes = [hid]
    self.lib.H5Gclose.restype = ctypes.c_int
    self.lib.H5Iget_type.argtypes = [hid]
    self.lib.H5Iget_type.restype = ctypes.c_int
    self.lib.H5Lexists.argtypes = [hid, ctypes.c_char_p, hid]
    self.lib.H5Lexists.restype = ctypes.c_int
    self.lib.H5Aexists.argtypes = [hid, ctypes.c_char_p]
    self.lib.H5Aexists.restype = ctypes.c_int
    self.lib.H5Aopen.argtypes = [hid, ctypes.c_char_p, hid]
    self.lib.H5Aopen.restype = hid
    self.lib.H5Aget_type.argtypes = [hid]
    self.lib.H5Aget_type.restype = hid
    self.lib.H5Aread.argtypes = [hid, hid, ctypes.c_void_p]
    self.lib.H5Aread.restype = ctypes.c_int
    self.lib.H5Aclose.argtypes = [hid]
    self.lib.H5Aclose.restype = ctypes.c_int
    self.lib.H5Dget_space.argtypes = [hid]
    self.lib.H5Dget_space.restype = hid
    self.lib.H5Dget_type.argtypes = [hid]
    self.lib.H5Dget_type.restype = hid
    self.lib.H5Dread.argtypes = [hid, hid, hid, hid, hid, ctypes.c_void_p]
    self.lib.H5Dread.restype = ctypes.c_int
    self.lib.H5Dclose.argtypes = [hid]
    self.lib.H5Dclose.restype = ctypes.c_int
    self.lib.H5Sget_simple_extent_ndims.argtypes = [hid]
    self.lib.H5Sget_simple_extent_ndims.restype = ctypes.c_int
    self.lib.H5Sget_simple_extent_dims.argtypes = [
      hid, ctypes.POINTER(hsize), ctypes.POINTER(hsize)
    ]
    self.lib.H5Sget_simple_extent_dims.restype = ctypes.c_int
    self.lib.H5Sget_simple_extent_npoints.argtypes = [hid]
    self.lib.H5Sget_simple_extent_npoints.restype = ctypes.c_longlong
    self.lib.H5Sclose.argtypes = [hid]
    self.lib.H5Sclose.restype = ctypes.c_int
    self.lib.H5Tget_class.argtypes = [hid]
    self.lib.H5Tget_class.restype = ctypes.c_int
    self.lib.H5Tget_size.argtypes = [hid]
    self.lib.H5Tget_size.restype = ctypes.c_size_t
    self.lib.H5Tget_native_type.argtypes = [hid, ctypes.c_int]
    self.lib.H5Tget_native_type.restype = hid
    self.lib.H5Tget_sign.argtypes = [hid]
    self.lib.H5Tget_sign.restype = ctypes.c_int
    self.lib.H5Tget_nmembers.argtypes = [hid]
    self.lib.H5Tget_nmembers.restype = ctypes.c_int
    self.lib.H5Tget_member_index.argtypes = [hid, ctypes.c_char_p]
    self.lib.H5Tget_member_index.restype = ctypes.c_int
    self.lib.H5Tget_member_offset.argtypes = [hid, ctypes.c_uint]
    self.lib.H5Tget_member_offset.restype = ctypes.c_size_t
    self.lib.H5Tget_member_type.argtypes = [hid, ctypes.c_uint]
    self.lib.H5Tget_member_type.restype = hid
    self.lib.H5Tclose.argtypes = [hid]
    self.lib.H5Tclose.restype = ctypes.c_int
    self.lib.H5Rdereference.argtypes = [hid, ctypes.c_int, ctypes.c_void_p]
    self.lib.H5Rdereference.restype = hid

  def read_payload(self, specification):
    if self.lib.H5Lexists(self.file_id, b"/payload", 0) <= 0:
      raise AuditUnavailable("HDF5_PAYLOAD_MISSING")
    object_id = self.lib.H5Oopen(self.file_id, b"/payload", 0)
    if object_id < 0:
      raise AuditUnavailable("HDF5_PAYLOAD_OPEN_FAILED")
    try:
      return self._decode_object(object_id, specification)
    finally:
      self._close_object(object_id)

  def _matlab_class(self, object_id):
    if self.lib.H5Aexists(object_id, b"MATLAB_class") <= 0:
      return ""
    attribute_id = self.lib.H5Aopen(object_id, b"MATLAB_class", 0)
    if attribute_id < 0:
      raise AuditUnavailable("HDF5_CLASS_ATTRIBUTE_OPEN_FAILED")
    type_id = self.lib.H5Aget_type(attribute_id)
    try:
      size = int(self.lib.H5Tget_size(type_id))
      if size <= 0 or size > 128:
        raise AuditUnavailable("HDF5_CLASS_ATTRIBUTE_INVALID")
      buffer = ctypes.create_string_buffer(size + 1)
      if self.lib.H5Aread(attribute_id, type_id, buffer) < 0:
        raise AuditUnavailable("HDF5_CLASS_ATTRIBUTE_READ_FAILED")
      return buffer.raw[:size].split(b"\0", 1)[0].decode("ascii")
    except UnicodeDecodeError as error:
      raise AuditUnavailable("HDF5_CLASS_ATTRIBUTE_INVALID") from error
    finally:
      self.lib.H5Tclose(type_id)
      self.lib.H5Aclose(attribute_id)

  def _decode_object(self, object_id, specification):
    object_type = self.lib.H5Iget_type(object_id)
    if object_type == self.H5I_GROUP:
      if not isinstance(specification, dict):
        raise AuditUnavailable("HDF5_UNEXPECTED_GROUP")
      matlab_class = self._matlab_class(object_id)
      if matlab_class not in ("", "struct"):
        raise AuditUnavailable("HDF5_UNKNOWN_GROUP_CLASS")
      fields = {}
      for name, child_specification in specification.items():
        encoded = os.fsencode(name)
        if self.lib.H5Lexists(object_id, encoded, 0) <= 0:
          raise AuditUnavailable("HDF5_REQUIRED_FIELD_MISSING")
        child_id = self.lib.H5Oopen(object_id, encoded, 0)
        if child_id < 0:
          raise AuditUnavailable("HDF5_FIELD_OPEN_FAILED")
        try:
          fields[name] = self._decode_object(child_id, child_specification)
        finally:
          self._close_object(child_id)
      if matlab_class == "struct":
        return self._combine_struct_fields(fields)
      return fields
    if object_type == self.H5I_DATASET:
      return self._decode_dataset(object_id, specification)
    raise AuditUnavailable("HDF5_UNKNOWN_OBJECT_TYPE")

  def _close_object(self, object_id):
    object_type = self.lib.H5Iget_type(object_id)
    if object_type == self.H5I_GROUP:
      self.lib.H5Gclose(object_id)
    elif object_type == self.H5I_DATASET:
      self.lib.H5Dclose(object_id)
    else:
      self.lib.H5Oclose(object_id)

  def _shape_and_count(self, space_id):
    count = int(self.lib.H5Sget_simple_extent_npoints(space_id))
    if count < 0:
      raise AuditUnavailable("HDF5_DATASPACE_INVALID")
    rank = self.lib.H5Sget_simple_extent_ndims(space_id)
    if rank < 0:
      raise AuditUnavailable("HDF5_DATASPACE_INVALID")
    if rank == 0:
      return (), count
    dimensions = (ctypes.c_ulonglong * rank)()
    if self.lib.H5Sget_simple_extent_dims(space_id, dimensions, None) < 0:
      raise AuditUnavailable("HDF5_DIMENSIONS_UNAVAILABLE")
    return tuple(reversed([int(dimensions[index]) for index in range(rank)])), count

  def _decode_dataset(self, dataset_id, specification):
    matlab_class = self._matlab_class(dataset_id)
    allowed = {
      "", "double", "single", "int8", "uint8", "int16", "uint16",
      "int32", "uint32", "int64", "uint64", "logical", "char", "cell",
    }
    if matlab_class not in allowed:
      raise AuditUnavailable("HDF5_UNKNOWN_DATASET_CLASS")
    space_id = self.lib.H5Dget_space(dataset_id)
    type_id = self.lib.H5Dget_type(dataset_id)
    if space_id < 0 or type_id < 0:
      raise AuditUnavailable("HDF5_DATASET_METADATA_UNAVAILABLE")
    try:
      shape, count = self._shape_and_count(space_id)
      type_class = self.lib.H5Tget_class(type_id)
      if type_class == self.H5T_REFERENCE:
        return self._decode_references(
          dataset_id, type_id, shape, count, specification
        )
      if specification is not LEAF:
        raise AuditUnavailable("HDF5_EXPECTED_REFERENCE_FIELD")
      if type_class == self.H5T_COMPOUND:
        values = self._read_complex(dataset_id, type_id, count)
      elif type_class in (self.H5T_INTEGER, self.H5T_FLOAT):
        values = self._read_numeric(dataset_id, type_id, type_class, count)
      elif type_class == self.H5T_STRING:
        values = self._read_fixed_string(dataset_id, type_id, count)
      else:
        raise AuditUnavailable("HDF5_UNKNOWN_DATA_TYPE")
      if matlab_class == "char":
        try:
          return "".join(chr(int(value)) for value in values if int(value) != 0)
        except (TypeError, ValueError) as error:
          raise AuditUnavailable("HDF5_CHAR_DECODE_FAILED") from error
      if matlab_class == "logical":
        values = [bool(value) for value in values]
      return MatArray(shape, values)
    finally:
      self.lib.H5Tclose(type_id)
      self.lib.H5Sclose(space_id)

  def _decode_references(self, dataset_id, type_id, shape, count, specification):
    reference_size = int(self.lib.H5Tget_size(type_id))
    if reference_size <= 0 or reference_size > 32:
      raise AuditUnavailable("HDF5_REFERENCE_SIZE_INVALID")
    raw = (ctypes.c_ubyte * (max(1, count * reference_size)))()
    if count and self.lib.H5Dread(dataset_id, type_id, 0, 0, 0, raw) < 0:
      raise AuditUnavailable("HDF5_REFERENCE_READ_FAILED")
    values = []
    for index in range(count):
      offset = index * reference_size
      reference = (ctypes.c_ubyte * reference_size).from_buffer(raw, offset)
      if not any(reference):
        raise AuditUnavailable("HDF5_DANGLING_REFERENCE")
      target_id = self.lib.H5Rdereference(dataset_id, 0, reference)
      if target_id < 0:
        raise AuditUnavailable("HDF5_DANGLING_REFERENCE")
      try:
        values.append(self._decode_object(target_id, specification))
      finally:
        self._close_object(target_id)
    return MatArray(shape, values)

  def _read_numeric(self, dataset_id, type_id, type_class, count):
    native_id = self.lib.H5Tget_native_type(type_id, 0)
    if native_id < 0:
      raise AuditUnavailable("HDF5_NATIVE_TYPE_UNAVAILABLE")
    try:
      size = int(self.lib.H5Tget_size(native_id))
      if type_class == self.H5T_FLOAT:
        ctype = {4: ctypes.c_float, 8: ctypes.c_double}.get(size)
      else:
        signed = self.lib.H5Tget_sign(native_id) != self.H5T_SGN_NONE
        ctype = {
          (1, False): ctypes.c_uint8, (1, True): ctypes.c_int8,
          (2, False): ctypes.c_uint16, (2, True): ctypes.c_int16,
          (4, False): ctypes.c_uint32, (4, True): ctypes.c_int32,
          (8, False): ctypes.c_uint64, (8, True): ctypes.c_int64,
        }.get((size, signed))
      if ctype is None:
        raise AuditUnavailable("HDF5_NUMERIC_TYPE_UNSUPPORTED")
      buffer = (ctype * max(1, count))()
      if count and self.lib.H5Dread(dataset_id, native_id, 0, 0, 0, buffer) < 0:
        raise AuditUnavailable("HDF5_NUMERIC_READ_FAILED")
      return [buffer[index] for index in range(count)]
    finally:
      self.lib.H5Tclose(native_id)

  def _read_fixed_string(self, dataset_id, type_id, count):
    size = int(self.lib.H5Tget_size(type_id))
    if size <= 0 or size > 4096:
      raise AuditUnavailable("HDF5_STRING_TYPE_UNSUPPORTED")
    raw = (ctypes.c_char * max(1, count * size))()
    if count and self.lib.H5Dread(dataset_id, type_id, 0, 0, 0, raw) < 0:
      raise AuditUnavailable("HDF5_STRING_READ_FAILED")
    values = []
    for index in range(count):
      start = index * size
      value = bytes(raw[start:start + size]).split(b"\0", 1)[0]
      try:
        values.append(value.decode("utf-8"))
      except UnicodeDecodeError as error:
        raise AuditUnavailable("HDF5_STRING_DECODE_FAILED") from error
    return values

  def _read_complex(self, dataset_id, type_id, count):
    members = self.lib.H5Tget_nmembers(type_id)
    if members != 2:
      raise AuditUnavailable("HDF5_COMPLEX_TYPE_UNSUPPORTED")
    description = {}
    indices = {
      name: self.lib.H5Tget_member_index(type_id, name.encode("ascii"))
      for name in ("real", "imag")
    }
    if any(index < 0 or index >= members for index in indices.values()) or \
        len(set(indices.values())) != 2:
      raise AuditUnavailable("HDF5_COMPLEX_TYPE_UNSUPPORTED")
    for name in ("real", "imag"):
      index = indices[name]
      member_id = self.lib.H5Tget_member_type(type_id, index)
      if member_id < 0:
        raise AuditUnavailable("HDF5_COMPLEX_MEMBER_UNAVAILABLE")
      try:
        if self.lib.H5Tget_class(member_id) != self.H5T_FLOAT:
          raise AuditUnavailable("HDF5_COMPLEX_TYPE_UNSUPPORTED")
        description[name] = (
          int(self.lib.H5Tget_member_offset(type_id, index)),
          int(self.lib.H5Tget_size(member_id)),
        )
      finally:
        self.lib.H5Tclose(member_id)
    total_size = int(self.lib.H5Tget_size(type_id))
    raw = (ctypes.c_ubyte * max(1, count * total_size))()
    if count and self.lib.H5Dread(dataset_id, type_id, 0, 0, 0, raw) < 0:
      raise AuditUnavailable("HDF5_COMPLEX_READ_FAILED")
    values = []
    for item in range(count):
      parts = {}
      for name in ("real", "imag"):
        offset, size = description[name]
        ctype = {4: ctypes.c_float, 8: ctypes.c_double}.get(size)
        if ctype is None:
          raise AuditUnavailable("HDF5_COMPLEX_TYPE_UNSUPPORTED")
        address = ctypes.addressof(raw) + item * total_size + offset
        parts[name] = ctype.from_address(address).value
      values.append(complex(parts["real"], parts["imag"]))
    return values

  def _combine_struct_fields(self, fields):
    if not fields:
      return {}
    first = next(iter(fields.values()))
    if not isinstance(first, MatArray):
      return fields
    shape = first.shape
    count = len(first.data)
    for value in fields.values():
      if not isinstance(value, MatArray) or value.shape != shape or len(value.data) != count:
        return fields
    records = []
    for index in range(count):
      records.append({name: value.data[index] for name, value in fields.items()})
    if count == 1:
      return records[0]
    return MatArray(shape, records)


def scalar(value, name):
  if isinstance(value, MatArray):
    if len(value.data) != 1:
      raise AuditUnavailable("SHAPE_MISMATCH_" + name)
    value = value.data[0]
  if isinstance(value, MatArray):
    return scalar(value, name)
  return value


def text(value, name):
  value = scalar(value, name)
  if not isinstance(value, str):
    raise AuditUnavailable("TEXT_FIELD_INVALID_" + name)
  return value


def number(value, name):
  value = scalar(value, name)
  if isinstance(value, bool) or not isinstance(value, (int, float)):
    raise AuditUnavailable("NUMERIC_FIELD_INVALID_" + name)
  result = float(value)
  if not math.isfinite(result):
    raise AuditUnavailable("NONFINITE_FIELD_" + name)
  return result


def integer(value, name):
  result = number(value, name)
  rounded = int(result)
  if result != rounded:
    raise AuditUnavailable("INTEGER_FIELD_INVALID_" + name)
  return rounded


def boolean(value, name):
  value = scalar(value, name)
  if isinstance(value, bool):
    return value
  if isinstance(value, (int, float)) and value in (0, 1):
    return bool(value)
  raise AuditUnavailable("LOGICAL_FIELD_INVALID_" + name)


def records(value, name):
  if isinstance(value, dict):
    return [value]
  if not isinstance(value, MatArray):
    raise AuditUnavailable("STRUCT_ARRAY_INVALID_" + name)
  if any(not isinstance(item, dict) for item in value.data):
    raise AuditUnavailable("STRUCT_ARRAY_INVALID_" + name)
  return value.data


def flat_numbers(value, name, integer_values=False):
  if not isinstance(value, MatArray):
    raise AuditUnavailable("ARRAY_FIELD_INVALID_" + name)
  output = []
  for item in value.data:
    if isinstance(item, bool) or not isinstance(item, (int, float)):
      raise AuditUnavailable("ARRAY_FIELD_INVALID_" + name)
    converted = float(item)
    if not math.isfinite(converted):
      raise AuditUnavailable("ARRAY_FIELD_NONFINITE_" + name)
    if integer_values:
      rounded = int(converted)
      if converted != rounded:
        raise AuditUnavailable("ARRAY_FIELD_NONINTEGER_" + name)
      output.append(rounded)
    else:
      output.append(converted)
  return output


def dense_matrix(value, name):
  if not isinstance(value, MatArray) or len(value.shape) != 2:
    raise AuditUnavailable("MATRIX_FIELD_INVALID_" + name)
  rows, columns = value.shape
  if rows * columns != len(value.data):
    raise AuditUnavailable("MATRIX_FIELD_INVALID_" + name)
  matrix = [[0j for _ in range(columns)] for _ in range(rows)]
  for column in range(columns):
    for row in range(rows):
      item = value.data[row + rows * column]
      if isinstance(item, bool) or not isinstance(item, (int, float, complex)):
        raise AuditUnavailable("MATRIX_FIELD_INVALID_" + name)
      converted = complex(item)
      if not (math.isfinite(converted.real) and math.isfinite(converted.imag)):
        raise AuditUnavailable("MATRIX_FIELD_NONFINITE_" + name)
      matrix[row][column] = converted
  return matrix


def close_number(first, second):
  scale = max(1.0, abs(first), abs(second))
  return abs(first - second) <= 64.0 * BINARY64_EPSILON * scale


def require_identity(payload, schema, run_id):
  if text(payload["schema_version"], "schema_version") != schema:
    raise AuditUnavailable("SCHEMA_IDENTITY_MISMATCH")
  if text(payload["run_id"], "run_id") != run_id:
    raise AuditUnavailable("RUN_IDENTITY_MISMATCH")
  if text(payload["execution_id"], "execution_id") != EXECUTION_ID:
    raise AuditUnavailable("EXECUTION_IDENTITY_MISMATCH")


def object_record(raw, include_samples=False):
  output = {
    "object_id": integer(raw["object_id"], "object_id"),
    "configuration": text(raw.get("configuration", MatArray((1, 1), [""])), "configuration"),
    "solve_id": text(raw["solve_id"], "solve_id"),
    "mesh_id": text(raw["mesh_id"], "mesh_id"),
    "theta": number(raw["theta"], "theta"),
    "theta_index": integer(raw["theta_index"], "theta_index"),
    "cluster_id": integer(raw["cluster_id"], "cluster_id"),
    "root_index": integer(raw["root_index"], "root_index"),
    "root_indices": flat_numbers(raw["root_indices"], "root_indices", True),
    "dimension": integer(raw["dimension"], "dimension"),
    "eigenvalues": flat_numbers(raw["eigenvalues"], "eigenvalues"),
    "frequencies": flat_numbers(raw["frequencies"], "frequencies"),
    "lambda_envelope": flat_numbers(raw["lambda_envelope"], "lambda_envelope"),
    "k_envelope": flat_numbers(raw["k_envelope"], "k_envelope"),
    "L0_min": optional_number(raw["L0_min"]),
    "Lcore_min": optional_number(raw["Lcore_min"]),
    "tail_max": optional_number(raw["tail_max"]),
    "localization_status": text(raw["localization_status"], "localization_status"),
    "parity_label": text(raw["parity_label"], "parity_label"),
    "parity_status": text(raw["parity_status"], "parity_status"),
  }
  if len(output["root_indices"]) != output["dimension"]:
    raise AuditUnavailable("OBJECT_DIMENSION_MISMATCH")
  if len(output["eigenvalues"]) != output["dimension"] or \
      len(output["frequencies"]) != output["dimension"]:
    raise AuditUnavailable("OBJECT_SPECTRUM_DIMENSION_MISMATCH")
  if len(output["lambda_envelope"]) != 2 or len(output["k_envelope"]) != 2:
    raise AuditUnavailable("OBJECT_ENVELOPE_SHAPE_MISMATCH")
  if include_samples:
    output["common_core_samples"] = dense_matrix(
      raw["common_core_samples"], "common_core_samples"
    )
    output["common_core_weights"] = flat_numbers(
      raw["common_core_weights"], "common_core_weights"
    )
    output["common_core_valid"] = boolean(raw["common_core_valid"], "common_core_valid")
  return output


def optional_number(value):
  if not isinstance(value, MatArray) or len(value.data) != 1:
    return None
  item = value.data[0]
  if isinstance(item, bool) or not isinstance(item, (int, float)):
    return None
  converted = float(item)
  return converted if math.isfinite(converted) else None


def candidate_record(raw):
  output = {
    "candidate_id": integer(raw["candidate_id"], "candidate_id"),
    "realization_ids": flat_numbers(raw["realization_ids"], "realization_ids", True),
  }
  if "lambda_30" in raw:
    output["lambda_30"] = optional_number(raw["lambda_30"])
    output["k_30"] = optional_number(raw["k_30"])
  return output


def edge_record(raw):
  return {
    "source_object_id": integer(raw["source_object_id"], "source_object_id"),
    "target_object_id": integer(raw["target_object_id"], "target_object_id"),
    "axis": text(raw["axis"], "axis"),
    "kind": text(raw["kind"], "kind"),
    "overlap": optional_number(raw["overlap"]),
  }


def component_record(raw):
  return {
    "candidate_id": integer(raw["candidate_id"], "candidate_id"),
    "realization_ids": flat_numbers(raw["realization_ids"], "realization_ids", True),
  }


def indexed_unique(items, key, label):
  output = {}
  for item in items:
    value = item[key]
    if value in output:
      raise AuditUnavailable("DUPLICATE_" + label)
    output[value] = item
  return output


def finite_localization(record):
  return (
    record["localization_status"] == "AVAILABLE" and
    all(record[name] is not None for name in ("L0_min", "Lcore_min", "tail_max"))
  )


def localization_label(record, thresholds):
  if not finite_localization(record):
    return "unavailable"
  if (
      record["L0_min"] >= thresholds[0] and
      record["Lcore_min"] >= thresholds[1] and
      record["tail_max"] <= thresholds[2]
  ):
    return "localized"
  return "weakly-localized"


def thresholds(payload):
  specification = payload["spec"]
  return (
    number(specification["localization_center_min"], "localization_center_min"),
    number(specification["localization_core_min"], "localization_core_min"),
    number(specification["tail_max"], "tail_max"),
  )


def load_inputs(base_dir):
  old_root = os.path.join(base_dir, "output", OLD_RUN_ID, EXECUTION_ID)
  new_root = os.path.join(base_dir, "output", NEW_RUN_ID, EXECUTION_ID)
  paths = {
    "old_science": os.path.join(old_root, "scientific-result.mat"),
    "old_mesh": os.path.join(old_root, "work", "mesh-defect-N5-s24-g48.mat"),
    "new_science": os.path.join(new_root, "scientific-result.mat"),
    "new_fields": os.path.join(new_root, "fields.mat"),
  }
  for index, solve_id in enumerate(TARGET_SOLVE_IDS):
    paths["old_spectrum_" + str(index)] = os.path.join(old_root, "work", solve_id + ".mat")
  for path in paths.values():
    if not os.path.isfile(path):
      raise AuditUnavailable("REQUIRED_INPUT_MISSING")
  with Hdf5MatFile(paths["old_science"]) as source:
    old_science = source.read_payload(OLD_SCIENCE_SPEC)
  with Hdf5MatFile(paths["old_mesh"]) as source:
    old_mesh = source.read_payload(OLD_MESH_SPEC)
  with Hdf5MatFile(paths["new_science"]) as source:
    new_science = source.read_payload(NEW_SCIENCE_SPEC)
  with Hdf5MatFile(paths["new_fields"]) as source:
    new_fields = source.read_payload(NEW_FIELDS_SPEC)
  require_identity(old_science, OLD_SCHEMA, OLD_RUN_ID)
  require_identity(new_science, NEW_SCHEMA, NEW_RUN_ID)
  require_identity(new_fields, NEW_FIELDS_SCHEMA, NEW_RUN_ID)
  if text(old_mesh["id"], "old_mesh_id") != OLD_MESH_ID:
    raise AuditUnavailable("OLD_MESH_ID_MISMATCH")
  if text(new_fields["mesh_id"], "new_mesh_id") != NEW_MESH_ID:
    raise AuditUnavailable("NEW_MESH_ID_MISMATCH")
  phases = flat_numbers(new_fields["theta_5"], "theta_5")
  if len(phases) != 5 or any(not close_number(a, b) for a, b in zip(phases, TARGET_PHASES)):
    raise AuditUnavailable("NEW_PHASE_SCHEDULE_MISMATCH")
  return paths, old_science, old_mesh, new_science, new_fields


def reconstruct_old_selection(old_science):
  raw_inventory = old_science["candidate_inventory"]
  objects = [object_record(raw) for raw in records(raw_inventory["objects"], "old_objects")]
  candidates = [candidate_record(raw) for raw in records(raw_inventory["candidates"], "old_candidates")]
  object_by_id = indexed_unique(objects, "object_id", "OLD_OBJECT_ID")
  candidate_matches = [candidate for candidate in candidates if candidate["candidate_id"] == 7]
  if len(candidate_matches) != 1:
    raise AuditUnavailable("OLD_CANDIDATE7_NOT_UNIQUE")
  candidate = candidate_matches[0]
  if any(object_id not in object_by_id for object_id in candidate["realization_ids"]):
    raise AuditUnavailable("OLD_CANDIDATE7_OBJECT_MISSING")
  members = [object_by_id[object_id] for object_id in candidate["realization_ids"]]
  fine_members = [item for item in members if item["configuration"] == "fine"]
  all_by_theta = {}
  for theta_index in range(1, 18):
    matches = [item for item in fine_members if item["theta_index"] == theta_index]
    if len(matches) != 1:
      raise AuditUnavailable("OLD_FINE_CHAIN_INCOMPLETE")
    all_by_theta[theta_index] = matches[0]
  targets = []
  for theta_index, solve_id in zip(TARGET_THETA_INDICES, TARGET_SOLVE_IDS):
    item = all_by_theta[theta_index]
    if item["solve_id"] != solve_id or item["mesh_id"] != OLD_MESH_ID:
      raise AuditUnavailable("OLD_TARGET_IDENTITY_MISMATCH")
    targets.append(item)
  edges = [edge_record(raw) for raw in records(old_science["tracking"]["edges"], "old_edges")]
  chain_ok = True
  chain_rows = []
  for theta_index in range(1, 17):
    source = all_by_theta[theta_index]["object_id"]
    target = all_by_theta[theta_index + 1]["object_id"]
    matches = [
      edge for edge in edges
      if edge["source_object_id"] == source and edge["target_object_id"] == target
      and edge["axis"] == "twist"
    ]
    present = len(matches) == 1
    chain_ok = chain_ok and present
    chain_rows.append({
      "theta_index_from": theta_index,
      "theta_index_to": theta_index + 1,
      "source_object_id": source,
      "target_object_id": target,
      "present": present,
    })
  return objects, candidate, targets, chain_ok, chain_rows


def reconstruct_new_inventory(new_science, new_fields):
  science_objects = [
    object_record(raw)
    for raw in records(new_science["candidate_inventory"]["objects"], "new_science_objects")
  ]
  field_objects = [
    object_record(raw, True)
    for raw in records(new_fields["objects"], "new_field_objects")
  ]
  science_by_id = indexed_unique(science_objects, "object_id", "NEW_SCIENCE_OBJECT_ID")
  fields_by_id = indexed_unique(field_objects, "object_id", "NEW_FIELDS_OBJECT_ID")
  if set(science_by_id) != set(fields_by_id):
    raise AuditUnavailable("NEW_OBJECT_INVENTORY_MISMATCH")
  compare_fields = (
    "solve_id", "mesh_id", "theta_index", "cluster_id", "root_index",
    "root_indices", "dimension", "eigenvalues", "frequencies",
  )
  for object_id in science_by_id:
    compact = science_by_id[object_id]
    full = fields_by_id[object_id]
    for name in compare_fields:
      first = compact[name]
      second = full[name]
      if isinstance(first, list):
        if len(first) != len(second) or any(not close_number(a, b) for a, b in zip(first, second)):
          raise AuditUnavailable("NEW_OBJECT_METADATA_MISMATCH")
      elif isinstance(first, (int, float)):
        if not close_number(first, second):
          raise AuditUnavailable("NEW_OBJECT_METADATA_MISMATCH")
      elif first != second:
        raise AuditUnavailable("NEW_OBJECT_METADATA_MISMATCH")
    if not full["common_core_valid"]:
      raise AuditUnavailable("NEW_COMMON_CORE_UNAVAILABLE")
  candidates = [
    candidate_record(raw)
    for raw in records(new_science["candidate_inventory"]["candidates"], "new_candidates")
  ]
  components = [
    component_record(raw)
    for raw in records(new_science["tracking"]["components"], "new_components")
  ]
  candidate_by_id = indexed_unique(candidates, "candidate_id", "NEW_CANDIDATE_ID")
  component_by_id = indexed_unique(components, "candidate_id", "NEW_COMPONENT_ID")
  if set(candidate_by_id) != set(component_by_id):
    raise AuditUnavailable("NEW_COMPONENT_INVENTORY_MISMATCH")
  for candidate_id in candidate_by_id:
    if candidate_by_id[candidate_id]["realization_ids"] != \
        component_by_id[candidate_id]["realization_ids"]:
      raise AuditUnavailable("NEW_COMPONENT_MEMBERSHIP_MISMATCH")
  edges = [edge_record(raw) for raw in records(new_science["tracking"]["edges"], "new_edges")]
  return list(fields_by_id.values()), candidates, components, edges


def build_common_grid(old_mesh):
  points = dense_matrix(old_mesh["points"], "old_mesh_points")
  raw_triangles = dense_matrix(old_mesh["triangles"], "old_mesh_triangles")
  if any(abs(value.imag) > 0 for row in points for value in row):
    raise AuditUnavailable("OLD_MESH_POINTS_COMPLEX")
  if len(points) < 3 or any(len(row) != 2 for row in points):
    raise AuditUnavailable("OLD_MESH_POINTS_SHAPE_MISMATCH")
  coordinates = [(row[0].real, row[1].real) for row in points]
  triangles = []
  for row in raw_triangles:
    if len(row) != 3:
      raise AuditUnavailable("OLD_MESH_TRIANGLES_SHAPE_MISMATCH")
    vertices = []
    for value in row:
      if abs(value.imag) > 0 or value.real != int(value.real):
        raise AuditUnavailable("OLD_MESH_TRIANGLE_INDEX_INVALID")
      vertex = int(value.real) - 1
      if vertex < 0 or vertex >= len(coordinates):
        raise AuditUnavailable("OLD_MESH_TRIANGLE_INDEX_INVALID")
      vertices.append(vertex)
    if len(set(vertices)) != 3:
      raise AuditUnavailable("OLD_MESH_TRIANGLE_DEGENERATE")
    triangles.append(tuple(vertices))

  x_values = [-2.5 + 5.0 * index / 160.0 for index in range(161)]
  y_values = [-0.5 + 1.0 * index / 64.0 for index in range(65)]
  x_weights = [5.0 / 160.0] * 161
  y_weights = [1.0 / 64.0] * 65
  x_weights[0] *= 0.5
  x_weights[-1] *= 0.5
  y_weights[0] *= 0.5
  y_weights[-1] *= 0.5

  bin_width = 0.05
  bins = {}
  for triangle_index, vertices in enumerate(triangles):
    xs = [coordinates[vertex][0] for vertex in vertices]
    ys = [coordinates[vertex][1] for vertex in vertices]
    ix0 = math.floor((min(xs) + 2.5) / bin_width)
    ix1 = math.floor((max(xs) + 2.5) / bin_width)
    iy0 = math.floor((min(ys) + 0.5) / bin_width)
    iy1 = math.floor((max(ys) + 0.5) / bin_width)
    for ix in range(ix0, ix1 + 1):
      for iy in range(iy0, iy1 + 1):
        bins.setdefault((ix, iy), []).append(triangle_index)

  interpolation = []
  weights = []
  sample_points = []
  for x_index, x_value in enumerate(x_values):
    for y_index, y_value in enumerate(y_values):
      distances = [math.hypot(x_value - center, y_value) for center in INTERFACE_CENTERS]
      if any(abs(distance - INTERFACE_RADIUS) <= INTERFACE_TOLERANCE for distance in distances):
        continue
      q_value = Q_INSIDE if any(distance < INTERFACE_RADIUS for distance in distances) else Q_OUTSIDE
      weight = x_weights[x_index] * y_weights[y_index] * q_value
      if not math.isfinite(weight) or weight <= 0.0:
        raise AuditUnavailable("COMMON_GRID_WEIGHT_INVALID")
      ix = math.floor((x_value + 2.5) / bin_width)
      iy = math.floor((y_value + 0.5) / bin_width)
      candidates = sorted(set(bins.get((ix, iy), [])))
      best = None
      for triangle_index in candidates:
        vertices = triangles[triangle_index]
        barycentric = barycentric_coordinates(
          (x_value, y_value), [coordinates[vertex] for vertex in vertices]
        )
        if barycentric is None:
          continue
        if any(value < -BARYCENTRIC_TOLERANCE or value > 1.0 + BARYCENTRIC_TOLERANCE for value in barycentric):
          continue
        score = min(barycentric)
        if best is None or score > best[0] or (score == best[0] and triangle_index < best[1]):
          best = (score, triangle_index, vertices, barycentric)
      if best is None:
        raise AuditUnavailable("COMMON_GRID_POINT_UNCOVERED")
      interpolation.append((best[2], best[3]))
      weights.append(weight)
      sample_points.append([x_value, y_value])
  return interpolation, weights, sample_points


def barycentric_coordinates(point, triangle):
  x, y = point
  x1, y1 = triangle[0]
  x2, y2 = triangle[1]
  x3, y3 = triangle[2]
  denominator = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
  if not math.isfinite(denominator) or denominator == 0.0:
    return None
  first = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denominator
  second = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denominator
  third = 1.0 - first - second
  if not all(math.isfinite(value) for value in (first, second, third)):
    return None
  return (first, second, third)


def interpolate_subspace(vectors, root_indices, interpolation):
  rows = len(vectors)
  columns = len(vectors[0]) if rows else 0
  selected = [index - 1 for index in root_indices]
  if any(index < 0 or index >= columns for index in selected):
    raise AuditUnavailable("SPECTRUM_ROOT_INDEX_INVALID")
  output = []
  for vertices, barycentric in interpolation:
    row = []
    for column in selected:
      value = sum(
        barycentric[index] * vectors[vertices[index]][column]
        for index in range(3)
      )
      if not (math.isfinite(value.real) and math.isfinite(value.imag)):
        raise AuditUnavailable("INTERPOLATED_FIELD_NONFINITE")
      row.append(value)
    output.append(row)
  return output


def gram_matrix(samples, weights):
  if len(samples) != len(weights) or not samples:
    raise AuditUnavailable("GRAM_INPUT_SHAPE_MISMATCH")
  dimension = len(samples[0])
  if dimension == 0 or any(len(row) != dimension for row in samples):
    raise AuditUnavailable("GRAM_INPUT_SHAPE_MISMATCH")
  gram = [[0j for _ in range(dimension)] for _ in range(dimension)]
  for row, weight in zip(samples, weights):
    if not math.isfinite(weight) or weight <= 0.0:
      raise AuditUnavailable("GRAM_WEIGHT_INVALID")
    for first in range(dimension):
      for second in range(dimension):
        gram[first][second] += row[first].conjugate() * weight * row[second]
  return gram


def frobenius_norm(matrix):
  return math.sqrt(sum(abs(value) ** 2 for row in matrix for value in row))


def hermitian_defect(matrix):
  size = len(matrix)
  difference = [[matrix[row][column] - matrix[column][row].conjugate()
                 for column in range(size)] for row in range(size)]
  return frobenius_norm(difference) / max(1.0, frobenius_norm(matrix))


def canonical_hermitian(matrix):
  size = len(matrix)
  if any(len(row) != size for row in matrix):
    raise AuditUnavailable("HERMITIAN_MATRIX_SHAPE_MISMATCH")
  if hermitian_defect(matrix) > GRAM_HERMITIAN_TOLERANCE:
    raise AuditUnavailable("GRAM_HERMITIAN_DEFECT_EXCEEDED")
  output = [[0j for _ in range(size)] for _ in range(size)]
  for row in range(size):
    output[row][row] = complex(matrix[row][row].real, 0.0)
    for column in range(row + 1, size):
      value = 0.5 * (matrix[row][column] + matrix[column][row].conjugate())
      output[row][column] = value
      output[column][row] = value.conjugate()
  return output


def cholesky_lower(matrix):
  matrix = canonical_hermitian(matrix)
  size = len(matrix)
  lower = [[0j for _ in range(size)] for _ in range(size)]
  for row in range(size):
    for column in range(row + 1):
      value = matrix[row][column] - sum(
        lower[row][index] * lower[column][index].conjugate()
        for index in range(column)
      )
      if row == column:
        pivot = value.real
        if not math.isfinite(pivot) or abs(value.imag) > GRAM_HERMITIAN_TOLERANCE * max(1.0, abs(pivot)) or pivot <= 0.0:
          raise AuditUnavailable("GRAM_NOT_POSITIVE_DEFINITE")
        lower[row][column] = math.sqrt(pivot)
      else:
        lower[row][column] = value / lower[column][column].real
  return lower


def normalize_samples(samples, weights):
  lower = cholesky_lower(gram_matrix(samples, weights))
  dimension = len(lower)
  upper = [[lower[column][row].conjugate() for column in range(dimension)]
           for row in range(dimension)]
  normalized = []
  for source in samples:
    solution = [0j] * dimension
    for column in range(dimension):
      numerator = source[column] - sum(
        solution[index] * upper[index][column] for index in range(column)
      )
      solution[column] = numerator / upper[column][column]
    normalized.append(solution)
  check = gram_matrix(normalized, weights)
  identity_error = frobenius_norm([
    [check[row][column] - (1.0 if row == column else 0.0)
     for column in range(dimension)] for row in range(dimension)
  ])
  if identity_error > 5.0e-11:
    raise AuditUnavailable("GRAM_NORMALIZATION_FAILED")
  return normalized


def cross_gram(first, second, weights):
  if len(first) != len(second) or len(first) != len(weights):
    raise AuditUnavailable("OVERLAP_INPUT_SHAPE_MISMATCH")
  first_dimension = len(first[0])
  second_dimension = len(second[0])
  output = [[0j for _ in range(second_dimension)] for _ in range(first_dimension)]
  for first_row, second_row, weight in zip(first, second, weights):
    for first_index in range(first_dimension):
      for second_index in range(second_dimension):
        output[first_index][second_index] += (
          first_row[first_index].conjugate() * weight * second_row[second_index]
        )
  return output


def conjugate_transpose_product(matrix):
  rows = len(matrix)
  columns = len(matrix[0]) if rows else 0
  if rows >= columns:
    return [[sum(matrix[row][first].conjugate() * matrix[row][second]
                 for row in range(rows))
             for second in range(columns)] for first in range(columns)]
  return [[sum(matrix[first][column] * matrix[second][column].conjugate()
               for column in range(columns))
           for second in range(rows)] for first in range(rows)]


def hermitian_jacobi_eigenvalues(matrix):
  current = canonical_hermitian(matrix)
  size = len(current)
  if size == 0:
    raise AuditUnavailable("JACOBI_EMPTY_MATRIX")
  scale = JACOBI_SCALE_FACTOR * max(1.0, frobenius_norm(current))
  converged = False
  for _ in range(max(1, 100 * size * size)):
    off_diagonal = math.sqrt(sum(
      abs(current[row][column]) ** 2
      for row in range(size) for column in range(size) if row != column
    ))
    if off_diagonal <= scale:
      converged = True
      break
    for first in range(size - 1):
      for second in range(first + 1, size):
        coupling = current[first][second]
        magnitude = abs(coupling)
        if magnitude == 0.0:
          continue
        difference = current[second][second].real - current[first][first].real
        tau = difference / (2.0 * magnitude)
        sign = 1.0 if tau >= 0.0 else -1.0
        tangent = sign / (abs(tau) + math.sqrt(1.0 + tau * tau))
        cosine = 1.0 / math.sqrt(1.0 + tangent * tangent)
        sine = cosine * tangent
        phase = coupling / magnitude
        unitary = [[0j for _ in range(size)] for _ in range(size)]
        for index in range(size):
          unitary[index][index] = 1.0
        unitary[first][first] = phase * cosine
        unitary[first][second] = phase * sine
        unitary[second][first] = -sine
        unitary[second][second] = cosine
        product = [[sum(current[row][inner] * unitary[inner][column]
                        for inner in range(size))
                    for column in range(size)] for row in range(size)]
        current = [[sum(unitary[inner][row].conjugate() * product[inner][column]
                        for inner in range(size))
                    for column in range(size)] for row in range(size)]
        current = canonical_hermitian(current)
  if not converged:
    off_diagonal = math.sqrt(sum(
      abs(current[row][column]) ** 2
      for row in range(size) for column in range(size) if row != column
    ))
    if off_diagonal <= scale:
      converged = True
  if not converged:
    raise AuditUnavailable("JACOBI_NOT_CONVERGED")
  eigenvalues = []
  for index in range(size):
    value = current[index][index].real
    if value < 0.0 and abs(value) <= scale:
      value = 0.0
    if value < 0.0 or not math.isfinite(value):
      raise AuditUnavailable("JACOBI_NEGATIVE_EIGENVALUE")
    eigenvalues.append(value)
  return sorted(eigenvalues)


def principal_singular_values(matrix):
  eigenvalues = hermitian_jacobi_eigenvalues(conjugate_transpose_product(matrix))
  return sorted([math.sqrt(value) for value in eigenvalues], reverse=True)


def envelope_distance(first, second):
  return max(abs(first[0] - second[0]), abs(first[1] - second[1]))


def lex_less(first, second):
  return tuple(first) < tuple(second)


def tuple_add(first, second):
  return tuple(a + b for a, b in zip(first, second))


def tuple_subtract(first, second):
  return tuple(a - b for a, b in zip(first, second))


def lexicographic_assignment(old_objects, new_objects, overlaps, distances):
  old_count = len(old_objects)
  new_count = len(new_objects)
  count = old_count + new_count
  if count == 0:
    return [], [], []
  costs = [[None for _ in range(count)] for _ in range(count)]
  for old_index, old_object in enumerate(old_objects):
    for new_index, new_object in enumerate(new_objects):
      if overlaps[old_index][new_index] is not None:
        costs[old_index][new_index] = (
          -overlaps[old_index][new_index], 0.0, distances[old_index][new_index],
          float(new_object["root_index"]), float(old_object["object_id"]),
          float(new_object["object_id"]),
        )
    costs[old_index][new_count + old_index] = (
      0.0, 1.0, 0.0, 0.0, float(old_object["object_id"]), 0.0,
    )
  for new_index, new_object in enumerate(new_objects):
    row = old_count + new_index
    costs[row][new_index] = (
      0.0, 1.0, 0.0, float(new_object["root_index"]), 0.0,
      float(new_object["object_id"]),
    )
    for column in range(new_count, count):
      costs[row][column] = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

  zero = (0.0,) * 6
  row_potential = [zero for _ in range(count)]
  column_potential = [zero for _ in range(count + 1)]
  column_row = [-1 for _ in range(count + 1)]
  predecessor = [-1 for _ in range(count + 1)]
  for row in range(count):
    column_row[0] = row
    column = 0
    best = [None for _ in range(count)]
    used = [False for _ in range(count + 1)]
    while True:
      used[column] = True
      active_row = column_row[column]
      delta = None
      next_column = -1
      for candidate in range(count):
        if used[candidate + 1] or costs[active_row][candidate] is None:
          continue
        current = tuple_subtract(
          tuple_subtract(costs[active_row][candidate], row_potential[active_row]),
          column_potential[candidate + 1],
        )
        if best[candidate] is None or lex_less(current, best[candidate]):
          best[candidate] = current
          predecessor[candidate + 1] = column
        if best[candidate] is not None and (delta is None or lex_less(best[candidate], delta)):
          delta = best[candidate]
          next_column = candidate + 1
      if next_column < 0 or delta is None or any(not math.isfinite(value) for value in delta):
        raise AuditUnavailable("ASSIGNMENT_NO_FINITE_COMPLETION")
      for used_column in range(count + 1):
        if used[used_column]:
          assigned_row = column_row[used_column]
          if assigned_row >= 0:
            row_potential[assigned_row] = tuple_add(row_potential[assigned_row], delta)
          column_potential[used_column] = tuple_subtract(column_potential[used_column], delta)
      for candidate in range(count):
        if not used[candidate + 1] and best[candidate] is not None:
          best[candidate] = tuple_subtract(best[candidate], delta)
      column = next_column
      if column_row[column] < 0:
        break
    while True:
      previous = predecessor[column]
      column_row[column] = column_row[previous]
      column = previous
      if column == 0:
        break
  assignment = [-1 for _ in range(count)]
  for column in range(1, count + 1):
    if column_row[column] >= 0:
      assignment[column_row[column]] = column - 1
  pairs = []
  total = [0.0] * 6
  complete_assignment = []
  for row, column in enumerate(assignment):
    cost = costs[row][column]
    if cost is None:
      raise AuditUnavailable("ASSIGNMENT_INVALID_EDGE")
    total = [a + b for a, b in zip(total, cost)]
    if row < old_count and column < new_count and overlaps[row][column] is not None:
      pairs.append((row, column))
      kind = "REAL_PAIR"
    elif row < old_count:
      kind = "OLD_DEATH"
    elif column < new_count:
      kind = "NEW_BIRTH"
    else:
      kind = "DUMMY_PAIR"
    complete_assignment.append({
      "row_index": row + 1,
      "column_index": column + 1,
      "kind": kind,
      "old_object_id": old_objects[row]["object_id"] if row < old_count else None,
      "new_object_id": new_objects[column]["object_id"] if column < new_count else None,
      "cost_tuple": list(cost),
    })
  return pairs, total, complete_assignment


def spectrum_cross_check(spectrum, old_objects, phase):
  if text(spectrum["mesh_id"], "spectrum_mesh_id") != OLD_MESH_ID:
    raise AuditUnavailable("OLD_SPECTRUM_MESH_MISMATCH")
  if not close_number(number(spectrum["phase"], "spectrum_phase"), phase):
    raise AuditUnavailable("OLD_SPECTRUM_PHASE_MISMATCH")
  eigenvalues = flat_numbers(spectrum["eigenvalues"], "spectrum_eigenvalues")
  frequencies = flat_numbers(spectrum["frequencies"], "spectrum_frequencies")
  cluster_ids = flat_numbers(spectrum["cluster_ids"], "spectrum_cluster_ids", True)
  vectors = dense_matrix(spectrum["vectors_full"], "spectrum_vectors_full")
  if not (len(eigenvalues) == len(frequencies) == len(cluster_ids)):
    raise AuditUnavailable("OLD_SPECTRUM_LENGTH_MISMATCH")
  if not vectors or len(vectors[0]) != len(eigenvalues):
    raise AuditUnavailable("OLD_SPECTRUM_FIELD_SHAPE_MISMATCH")
  for item in old_objects:
    roots = [index - 1 for index in item["root_indices"]]
    if any(index < 0 or index >= len(eigenvalues) for index in roots):
      raise AuditUnavailable("OLD_OBJECT_ROOT_OUT_OF_RANGE")
    if any(cluster_ids[index] != item["cluster_id"] for index in roots):
      raise AuditUnavailable("OLD_OBJECT_CLUSTER_MISMATCH")
    if len(roots) != item["dimension"]:
      raise AuditUnavailable("OLD_OBJECT_DIMENSION_MISMATCH")
    if any(not close_number(eigenvalues[root], expected)
           for root, expected in zip(roots, item["eigenvalues"])):
      raise AuditUnavailable("OLD_OBJECT_EIGENVALUE_MISMATCH")
    if any(not close_number(frequencies[root], expected)
           for root, expected in zip(roots, item["frequencies"])):
      raise AuditUnavailable("OLD_OBJECT_FREQUENCY_MISMATCH")
    if not close_number(min(item["eigenvalues"]), item["lambda_envelope"][0]) or \
        not close_number(max(item["eigenvalues"]), item["lambda_envelope"][1]) or \
        not close_number(min(item["frequencies"]), item["k_envelope"][0]) or \
        not close_number(max(item["frequencies"]), item["k_envelope"][1]):
      raise AuditUnavailable("OLD_OBJECT_ENVELOPE_MISMATCH")
  return vectors


def audit_identity(base_dir):
  paths, old_science, old_mesh, new_science, new_fields = load_inputs(base_dir)
  old_objects, old_candidate, old_targets, old_chain_ok, old_chain_rows = \
    reconstruct_old_selection(old_science)
  new_objects, new_candidates, new_components, new_edges = \
    reconstruct_new_inventory(new_science, new_fields)
  old_thresholds = thresholds(old_science)
  new_thresholds = thresholds(new_science)
  interpolation, old_weights, sample_points = build_common_grid(old_mesh)

  per_twist = []
  matched_new_ids = []
  all_pair_pass = True
  multiplicity_changed = False
  localization_rows = []
  parity_rows = []
  for stream_index, (old_theta_index, new_theta_index, solve_id, phase) in enumerate(zip(
      TARGET_THETA_INDICES, range(1, 6), TARGET_SOLVE_IDS, TARGET_PHASES)):
    old_slice = [
      item for item in old_objects
      if item["configuration"] == "fine" and item["theta_index"] == old_theta_index
      and item["k_envelope"][1] >= W3[0] and item["k_envelope"][0] <= W3[1]
    ]
    new_slice = [
      item for item in new_objects
      if item["theta_index"] == new_theta_index
      and item["k_envelope"][1] >= W3[0] and item["k_envelope"][0] <= W3[1]
    ]
    old_slice.sort(key=lambda item: item["object_id"])
    new_slice.sort(key=lambda item: item["object_id"])
    if not old_slice or not new_slice:
      raise AuditUnavailable("TWIST_INVENTORY_EMPTY")
    with Hdf5MatFile(paths["old_spectrum_" + str(stream_index)]) as source:
      spectrum = source.read_payload(OLD_SPECTRUM_SPEC)
    vectors = spectrum_cross_check(spectrum, old_slice, phase)
    old_normalized = []
    for item in old_slice:
      samples = interpolate_subspace(vectors, item["root_indices"], interpolation)
      old_normalized.append(normalize_samples(samples, old_weights))
    new_normalized = []
    for item in new_slice:
      samples = item["common_core_samples"]
      weights = item["common_core_weights"]
      if len(weights) != len(old_weights) or len(samples) != len(old_weights):
        raise AuditUnavailable("COMMON_GRID_SHAPE_MISMATCH")
      if any(abs(first - second) > WEIGHT_TOLERANCE
             for first, second in zip(old_weights, weights)):
        raise AuditUnavailable("COMMON_GRID_WEIGHT_MISMATCH")
      new_normalized.append(normalize_samples(samples, weights))

    overlaps = [[None for _ in new_slice] for _ in old_slice]
    singular_values = [[None for _ in new_slice] for _ in old_slice]
    distances = [[0.0 for _ in new_slice] for _ in old_slice]
    for old_index, old_item in enumerate(old_slice):
      for new_index, new_item in enumerate(new_slice):
        matrix = cross_gram(old_normalized[old_index], new_normalized[new_index], old_weights)
        values = principal_singular_values(matrix)
        singular_values[old_index][new_index] = values
        overlaps[old_index][new_index] = min(values)
        distances[old_index][new_index] = envelope_distance(
          old_item["k_envelope"], new_item["k_envelope"]
        )
    pairs, total_cost, complete_assignment = lexicographic_assignment(
      old_slice, new_slice, overlaps, distances
    )
    target_old = old_targets[stream_index]
    target_row_matches = [index for index, item in enumerate(old_slice)
                          if item["object_id"] == target_old["object_id"]]
    if len(target_row_matches) != 1:
      raise AuditUnavailable("TARGET_ROW_NOT_UNIQUE")
    target_row = target_row_matches[0]
    target_pairs = [(row, column) for row, column in pairs if row == target_row]
    if len(target_pairs) == 1:
      _, target_column = target_pairs[0]
      target_new = new_slice[target_column]
      overlap = overlaps[target_row][target_column]
      row_others = [value for index, value in enumerate(overlaps[target_row])
                    if index != target_column and value is not None]
      column_others = [overlaps[index][target_column] for index in range(len(old_slice))
                       if index != target_row and overlaps[index][target_column] is not None]
      row_runner_up = max(row_others) if row_others else None
      column_runner_up = max(column_others) if column_others else None
      row_gap = overlap - row_runner_up if row_runner_up is not None else None
      column_gap = overlap - column_runner_up if column_runner_up is not None else None
      strict_mutual_best = (
        all(overlap > value for value in row_others) and
        all(overlap > value for value in column_others)
      )
      threshold = 0.90 if target_old["dimension"] == 1 and target_new["dimension"] == 1 else 0.80
      overlap_pass = overlap >= threshold
      pair_pass = strict_mutual_best and overlap_pass
      matched_new_ids.append(target_new["object_id"])
      multiplicity_changed = multiplicity_changed or target_old["dimension"] != target_new["dimension"]
      old_label = localization_label(target_old, old_thresholds)
      new_label = localization_label(target_new, new_thresholds)
      localization_available = finite_localization(target_old) and finite_localization(target_new)
      localization_rows.append({
        "phase": phase,
        "old": {
          "L0_min": target_old["L0_min"], "Lcore_min": target_old["Lcore_min"],
          "tail_max": target_old["tail_max"], "classification": old_label,
        },
        "new": {
          "L0_min": target_new["L0_min"], "Lcore_min": target_new["Lcore_min"],
          "tail_max": target_new["tail_max"], "classification": new_label,
        },
        "signed_difference_new_minus_old": {
          "L0_min": target_new["L0_min"] - target_old["L0_min"] if localization_available else None,
          "Lcore_min": target_new["Lcore_min"] - target_old["Lcore_min"] if localization_available else None,
          "tail_max": target_new["tail_max"] - target_old["tail_max"] if localization_available else None,
        },
        "available": localization_available,
      })
      if stream_index in (0, 4):
        parity_available = (
          target_old["parity_status"] == "AVAILABLE" and
          target_new["parity_status"] == "AVAILABLE" and
          target_old["parity_label"] in ("even", "odd") and
          target_new["parity_label"] in ("even", "odd")
        )
        parity_rows.append({
          "phase": phase,
          "old_label": target_old["parity_label"],
          "new_label": target_new["parity_label"],
          "available": parity_available,
          "matches": parity_available and target_old["parity_label"] == target_new["parity_label"],
        })
    else:
      target_column = None
      target_new = None
      overlap = None
      row_runner_up = None
      column_runner_up = None
      row_gap = None
      column_gap = None
      strict_mutual_best = False
      threshold = 0.80 if target_old["dimension"] != 1 else 0.90
      overlap_pass = False
      pair_pass = False
      localization_rows.append({"phase": phase, "available": False})
      if stream_index in (0, 4):
        parity_rows.append({"phase": phase, "available": False, "matches": False})
    all_pair_pass = all_pair_pass and pair_pass
    per_twist.append({
      "phase": phase,
      "old_theta_index": old_theta_index,
      "new_theta_index": new_theta_index,
      "old_inventory": [compact_object(item) for item in old_slice],
      "new_inventory": [compact_object(item) for item in new_slice],
      "overlap_matrix": overlaps,
      "principal_singular_values": singular_values,
      "frequency_distance_matrix": distances,
      "assignment_pairs": [
        {
          "old_object_id": old_slice[row]["object_id"],
          "new_object_id": new_slice[column]["object_id"],
          "overlap": overlaps[row][column],
        }
        for row, column in pairs
      ],
      "complete_dummy_augmented_assignment": complete_assignment,
      "assignment_total_cost": total_cost,
      "candidate7_target": {
        "old_object_id": target_old["object_id"],
        "new_object_id": target_new["object_id"] if target_new else None,
        "principal_singular_values": singular_values[target_row][target_column]
          if target_column is not None else None,
        "overlap": overlap,
        "row_runner_up": row_runner_up,
        "column_runner_up": column_runner_up,
        "row_strict_gap": row_gap,
        "column_strict_gap": column_gap,
        "strict_mutual_best": strict_mutual_best,
        "threshold": threshold,
        "threshold_pass": overlap_pass,
        "pair_pass": pair_pass,
      },
    })

  matched_component = None
  component_matches = []
  if len(matched_new_ids) == 5:
    for component in new_components:
      if all(object_id in component["realization_ids"] for object_id in matched_new_ids):
        component_matches.append(component)
  if len(component_matches) == 1:
    matched_component = component_matches[0]
  new_chain_rows = []
  new_chain_ok = matched_component is not None
  if matched_component is not None:
    for source, target in zip(matched_new_ids[:-1], matched_new_ids[1:]):
      matches = [
        edge for edge in new_edges
        if edge["source_object_id"] == source and edge["target_object_id"] == target
        and edge["axis"] == "twist"
      ]
      present = len(matches) == 1
      new_chain_ok = new_chain_ok and present
      new_chain_rows.append({
        "source_object_id": source,
        "target_object_id": target,
        "present": present,
      })
  localization_ok = len(localization_rows) == 5 and all(
    row.get("available", False) for row in localization_rows
  )
  parity_ok = len(parity_rows) == 2 and all(
    row.get("available", False) and row.get("matches", False) for row in parity_rows
  )
  identity_supported = (
    all_pair_pass and old_chain_ok and new_chain_ok and
    localization_ok and parity_ok and matched_component is not None
  )
  if identity_supported:
    status = (
      "SAME_MODE_SUPPORTED_WITH_MULTIPLICITY_CAVEAT"
      if multiplicity_changed else "SAME_MODE_SUPPORTED"
    )
  else:
    status = "IDENTITY_AMBIGUOUS"

  canonical_winner = integer(new_science["selected_candidate"]["candidate_id"], "canonical_winner")
  fields_winner = integer(new_fields["winner_candidate_id"], "fields_winner")
  if canonical_winner != fields_winner:
    raise AuditUnavailable("CANONICAL_WINNER_MISMATCH")
  canonical_lambda = number(new_science["selected_candidate"]["lambda_30"], "canonical_lambda_30")
  canonical_k = number(new_science["selected_candidate"]["k_30"], "canonical_k_30")
  fields_lambda = number(new_fields["lambda_30"], "fields_lambda_30")
  fields_k = number(new_fields["k_30"], "fields_k_30")
  canonical_candidates = [candidate for candidate in new_candidates
                          if candidate["candidate_id"] == canonical_winner]
  if len(canonical_candidates) != 1 or \
      not close_number(canonical_lambda, fields_lambda) or \
      not close_number(canonical_k, fields_k) or \
      not close_number(canonical_lambda, canonical_candidates[0]["lambda_30"]) or \
      not close_number(canonical_k, canonical_candidates[0]["k_30"]):
    raise AuditUnavailable("CANONICAL_WINNER_SCALAR_MISMATCH")
  internal_matched_candidate_id = matched_component["candidate_id"] if matched_component else None
  if not identity_supported:
    matched_candidate_id = None
    selection_relation = "NO_UNIQUE_IDENTITY_COMPONENT"
    selection_fact = None
  elif internal_matched_candidate_id == canonical_winner:
    matched_candidate_id = internal_matched_candidate_id
    selection_relation = "PURE_FEM_WINNER_IS_IDENTITY_COMPONENT"
    selection_fact = None
  else:
    matched_candidate_id = internal_matched_candidate_id
    selection_relation = "PURE_FEM_WINNER_DIFFERS_IDENTITY_COMPONENT"
    selection_fact = "SELECTED_BRANCH_MISMATCH / ALTERNATE_MATCH_IDENTIFIED"

  lambda_candidate7 = None
  k_candidate7 = None
  envelope_candidate7 = None
  publication_cross_check = None
  if identity_supported:
    new_by_id = indexed_unique(new_objects, "object_id", "NEW_OBJECT_ID")
    component_objects = [new_by_id[object_id] for object_id in matched_component["realization_ids"]]
    if len(component_objects) != 5 or len({item["theta_index"] for item in component_objects}) != 5:
      raise AuditUnavailable("IDENTITY_COMPONENT_NOT_FIVE_TWIST")
    eigenvalues = [value for item in component_objects for value in item["eigenvalues"]]
    envelope_candidate7 = [min(eigenvalues), max(eigenvalues)]
    lambda_candidate7 = 0.5 * sum(envelope_candidate7)
    k_candidate7 = math.sqrt(lambda_candidate7)
    candidate_matches = [candidate for candidate in new_candidates
                         if candidate["candidate_id"] == matched_candidate_id]
    if len(candidate_matches) != 1:
      raise AuditUnavailable("MATCHED_CANDIDATE_PUBLICATION_MISSING")
    stored = candidate_matches[0]
    publication_cross_check = {
      "stored_lambda_30": stored.get("lambda_30"),
      "stored_k_30": stored.get("k_30"),
      "lambda_matches": stored.get("lambda_30") is not None and
        close_number(lambda_candidate7, stored["lambda_30"]),
      "k_matches": stored.get("k_30") is not None and
        close_number(k_candidate7, stored["k_30"]),
    }
    if not publication_cross_check["lambda_matches"] or not publication_cross_check["k_matches"]:
      raise AuditUnavailable("MATCHED_CANDIDATE_PUBLICATION_MISMATCH")

  caveats = []
  if multiplicity_changed:
    caveats.append("MULTIPLICITY_CHANGED")
  if not all_pair_pass:
    caveats.append("PAIR_IDENTITY_NOT_UNIQUE_OR_BELOW_THRESHOLD")
  if not old_chain_ok:
    caveats.append("OLD_CONTINUATION_CHAIN_INCOMPLETE")
  if not new_chain_ok:
    caveats.append("NEW_CONTINUATION_CHAIN_INCOMPLETE")
  if not localization_ok:
    caveats.append("LOCALIZATION_EVIDENCE_UNAVAILABLE")
  elif any(row["old"]["classification"] != row["new"]["classification"] for row in localization_rows):
    caveats.append("LOCALIZATION_CLASSIFICATION_CHANGED")
  if not parity_ok:
    caveats.append("ENDPOINT_PARITY_UNAVAILABLE_OR_MISMATCHED")
  return {
    "schema_version": AUDIT_SCHEMA,
    "audit_id": AUDIT_ID,
    "audit_terminal": "IDENTITY_AUDIT_COMPLETE",
    "input_ids": {
      "old": {"run_id": OLD_RUN_ID, "execution_id": EXECUTION_ID, "schema_version": OLD_SCHEMA},
      "new": {"run_id": NEW_RUN_ID, "execution_id": EXECUTION_ID,
              "science_schema_version": NEW_SCHEMA,
              "fields_schema_version": NEW_FIELDS_SCHEMA},
    },
    "candidate7_selection": {
      "candidate_id": old_candidate["candidate_id"],
      "realization_ids": old_candidate["realization_ids"],
      "target_rows": [compact_object(item) for item in old_targets],
    },
    "common_grid": {
      "x_count": 161, "y_count": 65,
      "retained_point_count": len(sample_points),
      "weight_sum": sum(old_weights),
      "barycentric_tolerance": BARYCENTRIC_TOLERANCE,
    },
    "per_twist": per_twist,
    "continuation": {
      "old_complete_theta17_chain": old_chain_ok,
      "old_edges": old_chain_rows,
      "new_matched_five_twist_chain": new_chain_ok,
      "new_edges": new_chain_rows,
    },
    "localization": localization_rows,
    "parity": parity_rows,
    "canonical_pure_fem_winner": {
      "candidate_id": canonical_winner,
      "lambda_30": canonical_lambda,
      "k_30": canonical_k,
    },
    "matched_component_id": matched_candidate_id,
    "candidate7_identity_status": status,
    "selection_relation": selection_relation,
    "selection_fact": selection_fact,
    "lambda30_candidate7_envelope": envelope_candidate7,
    "lambda30_candidate7": lambda_candidate7,
    "k30_candidate7": k_candidate7,
    "publication_cross_check": publication_cross_check,
    "caveats": caveats,
    "profile_gate": "ELIGIBLE_AFTER_POST_AUDIT_REVIEW" if identity_supported else "NOT_ELIGIBLE",
  }


def compact_object(item):
  return {
    "object_id": item["object_id"],
    "solve_id": item["solve_id"],
    "theta": item["theta"],
    "theta_index": item["theta_index"],
    "root_indices": item["root_indices"],
    "dimension": item["dimension"],
    "lambda_envelope": item["lambda_envelope"],
    "k_envelope": item["k_envelope"],
  }


def unavailable_result(reason):
  return {
    "schema_version": AUDIT_SCHEMA,
    "audit_id": AUDIT_ID,
    "audit_terminal": "IDENTITY_AUDIT_UNAVAILABLE",
    "input_ids": {
      "old": {"run_id": OLD_RUN_ID, "execution_id": EXECUTION_ID, "schema_version": OLD_SCHEMA},
      "new": {"run_id": NEW_RUN_ID, "execution_id": EXECUTION_ID,
              "science_schema_version": NEW_SCHEMA,
              "fields_schema_version": NEW_FIELDS_SCHEMA},
    },
    "candidate7_identity_status": "IDENTITY_AUDIT_UNAVAILABLE",
    "selection_relation": "NO_UNIQUE_IDENTITY_COMPONENT",
    "matched_component_id": None,
    "lambda30_candidate7": None,
    "k30_candidate7": None,
    "caveats": [reason],
    "profile_gate": "NOT_ELIGIBLE",
  }


def publish_json(base_dir, result):
  output_path = os.path.join(
    base_dir, "output", NEW_RUN_ID, EXECUTION_ID,
    "review-audit", AUDIT_ID, "identity-audit.json"
  )
  encoded = (json.dumps(
    result, allow_nan=False, ensure_ascii=True, indent=2, sort_keys=True
  ) + "\n").encode("utf-8")
  flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
  descriptor = os.open(output_path, flags, 0o600)
  try:
    view = memoryview(encoded)
    while view:
      written = os.write(descriptor, view)
      if written <= 0:
        raise OSError("short JSON write")
      view = view[written:]
    os.fsync(descriptor)
  finally:
    os.close(descriptor)


def main():
  if len(sys.argv) != 1:
    sys.stderr.write("identity_audit.py accepts no arguments\n")
    return 2
  base_dir = os.path.dirname(os.path.abspath(__file__))
  try:
    result = audit_identity(base_dir)
  except AuditUnavailable as error:
    result = unavailable_result(str(error))
  try:
    publish_json(base_dir, result)
  except OSError as error:
    sys.stderr.write("IDENTITY_AUDIT_PUBLICATION_FAILED: " + str(error) + "\n")
    return 2
  sys.stdout.write(result["audit_terminal"] + "\n")
  return 0


if __name__ == "__main__":
  sys.exit(main())
