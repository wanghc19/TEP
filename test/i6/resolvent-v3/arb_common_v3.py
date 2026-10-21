"""Exact binary64 loading and Arb helpers for the I6 v3 certificate."""

from array import array
import json
import math
from pathlib import Path
import sys

from flint import acb, acb_mat, arb, arb_mat, ctx


ARBITRARY_PRECISION_BITS = 192
ctx.prec = ARBITRARY_PRECISION_BITS
ctx.pretty = False


def load_binary64_export(export_dir):
    """Load MATLAB column-major binary64 payloads as Python binary64 values."""
    export_dir = Path(export_dir)
    manifest = json.loads((export_dir / "manifest.json").read_text())
    if manifest["schema"] != "EPOST_I6_RESOLVENT_V3_BINARY64_INPUT":
        raise ValueError("wrong export schema")
    fields = {}
    for name, meta in manifest["fields"].items():
        count = int(meta["count"])
        is_complex = bool(meta["complex"])
        path = export_dir / meta["file"]
        expected = 8 * count * (2 if is_complex else 1)
        if path.stat().st_size != expected:
            raise ValueError(f"wrong byte count for {name}")
        raw = array("d")
        with path.open("rb") as stream:
            raw.fromfile(stream, count * (2 if is_complex else 1))
        if sys.byteorder != "little":
            raw.byteswap()
        real = raw[:count]
        imag = raw[count:] if is_complex else [0.0] * count
        if not all(math.isfinite(x) for x in real) or not all(
            math.isfinite(x) for x in imag
        ):
            raise ValueError(f"nonfinite frozen input {name}")
        fields[name] = {
            "shape": tuple(int(x) for x in meta["shape"]),
            "values": [complex(real[k], imag[k]) for k in range(count)],
            "complex": is_complex,
            "stored_class": str(meta["stored_class"]),
        }
    return manifest, fields


def scalar(fields, name):
    item = fields[name]
    if len(item["values"]) != 1:
        raise ValueError(f"{name} is not scalar")
    value = item["values"][0]
    if value.imag != 0:
        raise ValueError(f"{name} is not real")
    return arb(value.real)


def scalar_float(fields, name):
    value = fields[name]["values"][0]
    if value.imag != 0:
        raise ValueError(f"{name} is not real")
    return value.real


def matrix(fields, name):
    """Return an exact-singleton acb_mat from MATLAB column-major storage."""
    item = fields[name]
    shape = item["shape"]
    if len(shape) != 2:
        raise ValueError(f"{name} must be two-dimensional")
    rows, cols = shape
    values = item["values"]
    out = acb_mat(rows, cols)
    for col in range(cols):
        base = col * rows
        for row in range(rows):
            out[row, col] = acb(values[base + row])
    return out


def column(values):
    out = acb_mat(len(values), 1)
    for row, value in enumerate(values):
        out[row, 0] = value
    return out


def row_abs_upper_sum(matrix_value, row):
    total = arb(0)
    for col_index in range(matrix_value.ncols()):
        total += abs(matrix_value[row, col_index]).upper()
    return total.upper()


def vector_norm_upper(vector):
    total = arb(0)
    for row in range(vector.nrows()):
        total += abs(vector[row, 0]).upper() ** 2
    return total.sqrt().upper()


def matrix_frobenius_upper(matrix_value):
    total = arb(0)
    for row in range(matrix_value.nrows()):
        for col_index in range(matrix_value.ncols()):
            total += abs(matrix_value[row, col_index]).upper() ** 2
    return total.sqrt().upper()


def matrix_row_norm_upper(matrix_value, row):
    total = arb(0)
    for col_index in range(matrix_value.ncols()):
        total += abs(matrix_value[row, col_index]).upper() ** 2
    return total.sqrt().upper()


def abs_upper(value):
    return abs(value).upper()


def abs_lower(value):
    return abs(value).lower()


def arb_upper(value):
    return value.upper()


def arb_lower(value):
    return value.lower()


def dyadic(value):
    """Return an exact dyadic endpoint dictionary for a point arb."""
    if value.rad() != 0:
        raise ValueError("dyadic export requires a point arb")
    mantissa, exponent = value.man_exp()
    return {"mantissa": str(mantissa), "exponent": int(exponent)}


def endpoint_upper(value):
    return dyadic(value.upper())


def endpoint_lower(value):
    return dyadic(value.lower())


def dyadic_decimal(endpoint):
    mantissa = int(endpoint["mantissa"])
    exponent = int(endpoint["exponent"])
    if exponent >= 0:
        return str(mantissa * (2**exponent))
    digits_after_point = -exponent
    scaled = abs(mantissa) * (5**digits_after_point)
    decimal_digits = str(scaled).rjust(digits_after_point + 1, "0")
    integer_part = decimal_digits[:-digits_after_point]
    fractional_part = decimal_digits[-digits_after_point:]
    sign = "-" if mantissa < 0 else ""
    return f"{sign}{integer_part}.{fractional_part}"


def ball_record(value):
    lower = endpoint_lower(value)
    upper = endpoint_upper(value)
    return {
        "lower_dyadic": lower,
        "upper_dyadic": upper,
        "lower_decimal_exact": dyadic_decimal(lower),
        "upper_decimal_exact": dyadic_decimal(upper),
        "display": str(value),
    }


def integer_value(fields, name):
    value = scalar_float(fields, name)
    if value != math.floor(value):
        raise ValueError(f"{name} is not an exact integer-valued binary64")
    return int(value)


def exact_pi():
    return arb.pi()


def exp_i(theta):
    """Return exp(i*theta) for a real arb or complex acb argument."""
    if isinstance(theta, acb):
        return (acb(0, 1) * theta).exp()
    return acb(0, theta).exp()


def complex_zero_matrix(rows, cols):
    return acb_mat(rows, cols)
