#!/usr/bin/env python3
"""Compute the I6 v3 resolvent certificate with python-flint Arb balls."""

import json
import math
from pathlib import Path
import sys
import time

from flint import acb, acb_mat, arb, ctx

from arb_common_v3 import (
    ARBITRARY_PRECISION_BITS,
    abs_upper,
    ball_record,
    column,
    endpoint_lower,
    endpoint_upper,
    exact_pi,
    exp_i,
    integer_value,
    load_binary64_export,
    matrix,
    matrix_frobenius_upper,
    matrix_row_norm_upper,
    scalar,
    scalar_float,
    vector_norm_upper,
)


NODE_COUNT = 280
KERNEL_SERIES_CUTOFF = 10
PARAMETER_STRIP_WIDTH = arb(1) / 5
CELL_CUTOFF_SCHEDULE = (16, 24, 32, 48, 64)
TAIL_SQUARED_ALLOCATION = arb("1e-24")
RECIPROCAL_CUTOFF = 5
IMAGE_CUTOFF = 3
EWALD_LOCAL_CUTOFF = 18
REGULAR_TAYLOR_CUTOFF = 18
EWALD_SPLIT = 2
LOCAL_CAUCHY_FACTOR = arb(3) / 2
WALL_MODE_CUTOFF = 256


def upper(value):
    return value.upper()


def lower(value):
    return value.lower()


def square(value):
    """Integer square by multiplication, safe for signed Arb intervals."""
    return value * value


def positive_upper(value, name):
    if lower(value) < 0:
        raise ValueError(f"{name} is not proven nonnegative")
    return upper(value)


def row_norm_sums(coefficients, orders, strip_width=arb(0), max_order=5):
    values = []
    for derivative in range(max_order + 1):
        total = arb(0)
        for row, order in enumerate(orders):
            factor = arb(abs(order)) ** derivative
            if strip_width != 0:
                factor *= (strip_width * abs(order)).exp()
            total += factor * matrix_row_norm_upper(coefficients, row)
        values.append(upper(total))
    return values


def exact_dft_operator(eta):
    source_count = 256
    state_count = eta.ncols()
    if eta.nrows() != 2 * source_count:
        raise ValueError("eta shape")
    pi = exact_pi()
    orders = list(range(-128, 128))
    dft = acb_mat(source_count, source_count)
    for row, order in enumerate(orders):
        for node in range(source_count):
            angle = -2 * pi * order * node / source_count
            dft[row, node] = exp_i(angle) / source_count
    eta_tau = acb_mat(source_count, state_count)
    eta_zeta = acb_mat(source_count, state_count)
    for row in range(source_count):
        for col_index in range(state_count):
            eta_tau[row, col_index] = eta[row, col_index]
            eta_zeta[row, col_index] = eta[source_count + row, col_index]
    return orders, dft * eta_tau, dft * eta_zeta


def circle_geometry(radius):
    pi = exact_pi()
    nodes = []
    positions = []
    normals = []
    for node in range(NODE_COUNT):
        t = 2 * pi * node / NODE_COUNT
        cosine = t.cos()
        sine = t.sin()
        nodes.append(t)
        positions.append((radius * cosine, radius * sine))
        normals.append((cosine, sine))
    return {
        "nodes": nodes,
        "position": positions,
        "normal": normals,
        "speed": radius,
        "boundary_length": 2 * pi * radius,
        "strip_position_abs": radius * PARAMETER_STRIP_WIDTH.cosh(),
        "strip_position_imag": radius * PARAMETER_STRIP_WIDTH.sinh(),
        "normal_component_upper": PARAMETER_STRIP_WIDTH.cosh(),
    }


def density_nodes(tau_coeff, zeta_coeff, orders, nodes):
    phase = acb_mat(len(nodes), len(orders))
    phase_prime = acb_mat(len(nodes), len(orders))
    for row, t in enumerate(nodes):
        for col_index, order in enumerate(orders):
            value = exp_i(t * order)
            phase[row, col_index] = value
            phase_prime[row, col_index] = acb(0, order) * value
    return phase * tau_coeff, phase * zeta_coeff, phase_prime * tau_coeff, phase


def exact_gamma(mu, beta_mode):
    radicand = mu - square(beta_mode)
    if lower(radicand) > 0:
        return acb(radicand.sqrt())
    if upper(radicand) < 0:
        return acb(0, (-radicand).sqrt())
    raise ValueError("Wood or unresolved gamma sign")


def polynomial_value(coefficients, value):
    result = acb(0)
    for coefficient in reversed(coefficients):
        result = result * value + coefficient
    return result


def retained_primitive(kappa, cutoff):
    pi = exact_pi()
    alpha = square(kappa) / 4
    euler = arb.const_euler()
    c0 = acb(0, arb(1) / 4) - (kappa.log() - arb(2).log() + euler) / (2 * pi)
    a = [acb(1)]
    y = [acb(0)]
    harmonic = arb(0)
    for n in range(1, cutoff + 1):
        a.append(a[-1] * (-alpha) / (n * n))
        harmonic += arb(1) / n
        y.append(harmonic * a[-1])
    jfirst = [-2 * (m + 1) * a[m + 1] for m in range(cutoff)]
    cfrak = [
        -a[m + 1] / (2 * pi)
        + 2 * c0 * (m + 1) * a[m + 1]
        + (m + 1) * y[m + 1] / pi
        for m in range(cutoff)
    ]
    return {"a": a, "y": y, "jfirst": jfirst, "cfrak": cfrak, "c0": c0}


def entire_series_record(kappa, x_max, cutoff, max_derivative, kind):
    alpha = square(kappa) / 4
    upper_values = []
    tail_values = []
    ratios = []
    for derivative in range(max_derivative + 1):
        retained = arb(0)
        if kind == "j_shift":
            for degree in range(derivative, cutoff):
                falling = math.factorial(degree) // math.factorial(degree - derivative)
                retained += (
                    falling
                    * alpha ** (degree + 1)
                    * x_max ** (degree - derivative)
                    / math.factorial(degree + 1) ** 2
                )
            degree = cutoff
            falling = math.factorial(degree) // math.factorial(degree - derivative)
            first = (
                falling
                * alpha ** (degree + 1)
                * x_max ** (degree - derivative)
                / math.factorial(degree + 1) ** 2
            )
            ratio = (
                alpha
                * x_max
                * (degree + 1)
                / ((degree + 1 - derivative) * (degree + 2) ** 2)
            )
        else:
            start = derivative if kind != "Y" else max(1, derivative)
            for degree in range(start, cutoff + 1):
                harmonic = sum(arb(1) / j for j in range(1, degree + 1)) if kind == "Y" else arb(1)
                falling = math.factorial(degree) // math.factorial(degree - derivative)
                retained += (
                    harmonic
                    * falling
                    * alpha**degree
                    * x_max ** (degree - derivative)
                    / math.factorial(degree) ** 2
                )
            degree = cutoff + 1
            harmonic = sum(arb(1) / j for j in range(1, degree + 1)) if kind == "Y" else arb(1)
            falling = math.factorial(degree) // math.factorial(degree - derivative)
            first = (
                harmonic
                * falling
                * alpha**degree
                * x_max ** (degree - derivative)
                / math.factorial(degree) ** 2
            )
            ratio = alpha * x_max / ((degree + 1) * (degree + 1 - derivative))
            if kind == "Y":
                ratio *= 1 + arb(1) / (degree + 1)
        ratio = upper(ratio)
        if not upper(ratio) < 1:
            raise ValueError("series ratio not contractive")
        tail = upper(first / (1 - ratio))
        upper_values.append(upper(retained + tail))
        tail_values.append(tail)
        ratios.append(ratio)
    return {"upper": upper_values, "tail": tail_values, "ratio": ratios}


def derivative_retained_record(coefficients, x_max, max_derivative):
    values = []
    for derivative in range(max_derivative + 1):
        total = arb(0)
        for degree in range(derivative, len(coefficients)):
            falling = math.factorial(degree) // math.factorial(degree - derivative)
            total += abs_upper(coefficients[degree]) * falling * x_max ** (degree - derivative)
        values.append(upper(total))
    return {"upper": values, "tail": [arb(0)] * (max_derivative + 1)}


def primitive_bounds(kappa, radius, cutoff, max_derivative=4):
    retained = retained_primitive(kappa, cutoff)
    x_max = upper(4 * square(radius))
    J = entire_series_record(kappa, x_max, cutoff, max_derivative + 1, "J")
    Y = entire_series_record(kappa, x_max, cutoff, max_derivative + 1, "Y")
    Jshift = entire_series_record(kappa, x_max, cutoff, max_derivative, "j_shift")
    Jfirst = derivative_retained_record(retained["jfirst"], x_max, max_derivative)
    Cfrak = derivative_retained_record(retained["cfrak"], x_max, max_derivative)
    c0_abs = abs_upper(retained["c0"])
    pi = exact_pi()
    for derivative in range(max_derivative + 1):
        Jfirst["tail"][derivative] = upper(2 * J["tail"][derivative + 1])
        Jfirst["upper"][derivative] = upper(Jfirst["upper"][derivative] + Jfirst["tail"][derivative])
        Cfrak["tail"][derivative] = upper(
            (arb(1) / (2 * pi * (derivative + 1)) + 2 * c0_abs)
            * J["tail"][derivative + 1]
            + Y["tail"][derivative + 1] / pi
        )
        Cfrak["upper"][derivative] = upper(Cfrak["upper"][derivative] + Cfrak["tail"][derivative])
    return {
        "retained": retained,
        "J": J,
        "Y": Y,
        "Jshift": Jshift,
        "Jfirst": Jfirst,
        "Cfrak": Cfrak,
        "c0_abs": c0_abs,
    }


def local_factor_bounds(outer, inner, kappa_e, kappa_i, radius):
    pi = exact_pi()
    logc = abs_upper(square(radius).log())
    Jsum = [upper(outer["J"]["upper"][q] + inner["J"]["upper"][q]) for q in range(5)]
    Jfsum = [upper(outer["Jfirst"]["upper"][q] + inner["Jfirst"]["upper"][q]) for q in range(5)]
    Csum = [upper(outer["Cfrak"]["upper"][q] + inner["Cfrak"]["upper"][q]) for q in range(5)]
    qouter = [
        upper((logc / (4 * pi) + outer["c0_abs"]) * outer["J"]["upper"][q] + outer["Y"]["upper"][q] / (2 * pi))
        for q in range(5)
    ]
    qinner = [
        upper((logc / (4 * pi) + inner["c0_abs"]) * inner["J"]["upper"][q] + inner["Y"]["upper"][q] / (2 * pi))
        for q in range(5)
    ]
    W = [upper(logc * Jfsum[q] / (4 * pi) + Csum[q]) for q in range(5)]
    S1x = [upper(radius * Jsum[q] / (4 * pi)) for q in range(5)]
    S2x = [upper(radius * (qouter[q] + qinner[q])) for q in range(5)]
    D1x = [upper(Jfsum[q] / (8 * pi)) for q in range(5)]
    D2x = [upper(W[q] / 2) for q in range(5)]
    C1x = [upper(Jfsum[q] / (4 * pi)) for q in range(5)]
    C2x = W
    A1x = [upper(radius * (square(kappa_e) * outer["J"]["upper"][q] + square(kappa_i) * inner["J"]["upper"][q]) / (4 * pi)) for q in range(5)]
    A2x = [upper(radius * (square(kappa_e) * qouter[q] + square(kappa_i) * qinner[q])) for q in range(5)]
    one = [arb(1), arb(0), arb(0), arb(0), arb(0)]
    radius_squared = square(radius)
    x_h = [4 * radius_squared, 2 * radius_squared, 2 * radius_squared, 2 * radius_squared, 2 * radius_squared]
    p_h = [radius_squared] * 5
    cos_h = [arb(1)] * 5
    base = {
        "S1": derivative_product(derivative_compose(S1x, radius), one),
        "S2": derivative_product(derivative_compose(S2x, radius), one),
        "D1": derivative_product(derivative_compose(D1x, radius), x_h),
        "D2": derivative_product(derivative_compose(D2x, radius), x_h),
        "C1": derivative_product(derivative_compose(C1x, radius), p_h),
        "C2": derivative_product(derivative_compose(C2x, radius), p_h),
        "A1cos": derivative_product(derivative_compose(A1x, radius), cos_h),
        "A2cos": derivative_product(derivative_compose(A2x, radius), cos_h),
    }
    # The q=0 continuous tails are the only entries needed by NF1.
    tail_J = upper(outer["J"]["tail"][0] + inner["J"]["tail"][0])
    tail_Y = upper(outer["Y"]["tail"][0] + inner["Y"]["tail"][0])
    tail_Jf = upper(outer["Jfirst"]["tail"][0] + inner["Jfirst"]["tail"][0])
    tail_C = upper(outer["Cfrak"]["tail"][0] + inner["Cfrak"]["tail"][0])
    qo = upper((logc / (4 * pi) + outer["c0_abs"]) * outer["J"]["tail"][0] + outer["Y"]["tail"][0] / (2 * pi))
    qi = upper((logc / (4 * pi) + inner["c0_abs"]) * inner["J"]["tail"][0] + inner["Y"]["tail"][0] / (2 * pi))
    wt = upper(logc * tail_Jf / (4 * pi) + tail_C)
    tail = {
        "S1": upper(radius * tail_J / (4 * pi)),
        "S2": upper(radius * (qo + qi)),
        "D1": upper(4 * radius_squared * tail_Jf / (8 * pi)),
        "D2": upper(4 * radius_squared * wt / 2),
        "C1": upper(radius_squared * tail_Jf / (4 * pi)),
        "C2": upper(radius_squared * wt),
        "A1cos": upper(radius * (square(kappa_e) * outer["J"]["tail"][0] + square(kappa_i) * inner["J"]["tail"][0]) / (4 * pi)),
        "A2cos": upper(radius * (square(kappa_e) * qo + square(kappa_i) * qi)),
    }
    return base, tail


def derivative_compose(values, radius):
    x1 = 2 * square(radius)
    return [
        values[0],
        values[1] * x1,
        values[2] * x1**2 + values[1] * x1,
        values[3] * x1**3 + 3 * values[2] * x1**2 + values[1] * x1,
        values[4] * x1**4 + 6 * values[3] * x1**3 + 7 * values[2] * x1**2 + values[1] * x1,
    ]


def derivative_product(left, right):
    result = []
    for order in range(5):
        total = arb(0)
        for split in range(order + 1):
            total += math.comb(order, split) * left[split] * right[order - split]
        result.append(upper(total))
    return result


def kress_weights(node_count):
    pi = exact_pi()
    result = []
    for offset in range(node_count):
        accum = arb(0)
        for order in range(1, node_count // 2):
            accum += (2 * pi * order * offset / node_count).cos() / order
        accum += (pi * offset).cos() / node_count
        result.append(-4 * pi * accum / node_count)
    return result


def local_bounds(factors, tails, tau_bounds, zeta_bounds, radius):
    pi = exact_pi()
    log_moment = 8 * pi * arb.const_log2()
    value = upper(
        tau_bounds[0]
        + log_moment
        * (factors["D1"][0] * tau_bounds[0] + factors["S1"][0] * zeta_bounds[0])
        + 2
        * pi
        * (factors["D2"][0] * tau_bounds[0] + factors["S2"][0] * zeta_bounds[0])
    )
    normal = upper(
        zeta_bounds[0]
        + log_moment
        * (
            factors["A1cos"][0] * tau_bounds[0]
            + factors["C1"][0] / radius * tau_bounds[1]
            + factors["D1"][0] * zeta_bounds[0]
        )
        + 2
        * pi
        * (
            factors["A2cos"][0] * tau_bounds[0]
            + factors["C2"][0] / radius * tau_bounds[1]
            + factors["D2"][0] * zeta_bounds[0]
        )
    )
    radius_value = upper(
        log_moment * (tails["D1"] * tau_bounds[0] + tails["S1"] * zeta_bounds[0])
        + 2 * pi * (tails["D2"] * tau_bounds[0] + tails["S2"] * zeta_bounds[0])
    )
    radius_normal = upper(
        log_moment
        * (
            tails["A1cos"] * tau_bounds[0]
            + tails["C1"] / radius * tau_bounds[1]
            + tails["D1"] * zeta_bounds[0]
        )
        + 2
        * pi
        * (
            tails["A2cos"] * tau_bounds[0]
            + tails["C2"] / radius * tau_bounds[1]
            + tails["D2"] * zeta_bounds[0]
        )
    )
    return value, normal, radius_value, radius_normal


def local_split(kappa_e, kappa_i, radius, difference, p_tangent, cosine, outer, inner):
    pi = exact_pi()
    radius_squared = square(radius)
    logc = radius_squared.log()
    Je = polynomial_value(outer["a"], difference)
    Ji = polynomial_value(inner["a"], difference)
    Ye = polynomial_value(outer["y"], difference)
    Yi = polynomial_value(inner["y"], difference)
    Jfe = polynomial_value(outer["jfirst"], difference)
    Jfi = polynomial_value(inner["jfirst"], difference)
    Ce = polynomial_value(outer["cfrak"], difference)
    Ci = polynomial_value(inner["cfrak"], difference)
    qe = (-logc / (4 * pi) + outer["c0"]) * Je + Ye / (2 * pi)
    qi = (-logc / (4 * pi) + inner["c0"]) * Ji + Yi / (2 * pi)
    dJ = Je - Ji
    dJf = Jfe - Jfi
    W = logc * dJf / (4 * pi) + Ce - Ci
    S1 = -radius * dJ / (4 * pi)
    S2 = radius * (qe - qi)
    D1 = difference * dJf / (8 * pi)
    D2 = difference * W / 2
    C1 = p_tangent * dJf / (4 * pi)
    C2 = p_tangent * W
    Se1 = -radius * Je / (4 * pi)
    Si1 = -radius * Ji / (4 * pi)
    Se2 = radius * qe
    Si2 = radius * qi
    A1 = (square(kappa_e) * Se1 - square(kappa_i) * Si1) * cosine
    A2 = (square(kappa_e) * Se2 - square(kappa_i) * Si2) * cosine
    return D1, D2, S1, S2, A1, A2, C1, C2


def local_centers(kappa_e, kappa_i, radius, nodes, tau_nodes, zeta_nodes, tau_prime_nodes, outer, inner):
    count = len(nodes)
    pi = exact_pi()
    dt = 2 * pi / count
    weights = kress_weights(count)
    D = acb_mat(count, count)
    S = acb_mat(count, count)
    A = acb_mat(count, count)
    C = acb_mat(count, count)
    for target in range(count):
        for source in range(count):
            # Use the common analytic grid expression. Subtracting two
            # separately rounded Arb enclosures of the same pi-dependent node
            # would lose dependency and make the diagonal a nonzero interval.
            angle = 2 * pi * (target - source) / count
            sine_half = (angle / 2).sin()
            difference = 4 * square(radius) * square(sine_half)
            p_tangent = square(radius) * angle.sin()
            cosine = angle.cos()
            D1, D2, S1, S2, A1, A2, C1, C2 = local_split(
                kappa_e, kappa_i, radius, difference, p_tangent, cosine, outer, inner
            )
            local_entries = (D1, D2, S1, S2, A1, A2, C1, C2)
            if not all(value.is_finite() for value in local_entries):
                raise ValueError(
                    f"nonfinite retained local split target={target} source={source}: "
                    + ",".join(str(value) for value in local_entries)
                )
            weight = weights[(target - source) % count]
            D[target, source] = weight * D1 + dt * D2
            S[target, source] = weight * S1 + dt * S2
            A[target, source] = weight * A1 + dt * A2
            C[target, source] = weight * C1 / radius + dt * C2 / radius
    value = tau_nodes + D * tau_nodes - S * zeta_nodes
    normal = -zeta_nodes - A * tau_nodes - C * tau_prime_nodes + D * zeta_nodes
    return value, normal


def linton_q(kappa, transverse):
    radicand = square(transverse) - square(kappa)
    if lower(radicand) > 0:
        return acb(radicand.sqrt())
    if upper(radicand) < 0:
        return acb(0, -(-radicand).sqrt())
    raise ValueError("retained reciprocal Wood mode")


def regular_c_coefficients(kappa, d, cutoff):
    pi = exact_pi()
    h = arb(EWALD_SPLIT) / d
    chi = square(kappa * d / (2 * EWALD_SPLIT))
    J = [acb(0)] * (cutoff + 1)
    S = [acb(0)] * (cutoff + 1)
    D = [acb(0)] * (cutoff + 1)
    Q = [acb(0)] * (cutoff + 1)
    harmonic = arb(0)
    for order in range(cutoff + 1):
        J[order] = (-chi) ** order / math.factorial(order) ** 2
        if order >= 1:
            harmonic += arb(1) / order
            S[order] = arb((-1) ** order) / (order * math.factorial(order))
            D[order] = (-1) ** order * harmonic * chi**order / math.factorial(order) ** 2
            for degree in range(order):
                Q[degree] += chi**order * math.factorial(order - degree - 1) * (-1) ** degree / math.factorial(order) ** 2
    c_chi = chi.log() + arb.const_euler() - acb(0, pi)
    polynomial = [acb(0)] * (2 * cutoff + 1)
    for i, left in enumerate(J):
        for j, right in enumerate(S):
            polynomial[i + j] += left * right
    for order in range(cutoff + 1):
        polynomial[order] += -c_chi * J[order] + 2 * D[order]
    polynomial = [value / (4 * pi) for value in polynomial]
    return chi, polynomial, Q


def polynomial_012(coefficients, value):
    value0 = polynomial_value(coefficients, value)
    first = [index * coefficients[index] for index in range(1, len(coefficients))]
    second = [index * (index - 1) * coefficients[index] for index in range(2, len(coefficients))]
    value1 = polynomial_value(first, value) if first else acb(0)
    value2 = polynomial_value(second, value) if second else acb(0)
    return value0, value1, value2


def H_chi_finite(zeta, chi, cutoff):
    exp_minus = (-zeta).exp()
    Eminus = exp_minus * (1 / zeta + 1 / square(zeta))
    Ezero = exp_minus / zeta
    Eplus = zeta.expint(1)
    H0 = acb(0)
    H1 = acb(0)
    H2 = acb(0)
    coefficient = arb(1)
    for order in range(cutoff + 1):
        H0 += coefficient * Eplus
        H1 -= coefficient * Ezero
        H2 += coefficient * Eminus
        if order < cutoff:
            next_value = (exp_minus - zeta * Eplus) / (order + 1)
            Eminus, Ezero, Eplus = Ezero, Eplus, next_value
            coefficient *= chi / (order + 1)
    return H0, H1, H2


def C_chi_finite(zeta, polynomial, q_coefficients):
    pi = exact_pi()
    P0, P1, P2 = polynomial_012(polynomial, zeta)
    Q0, Q1, Q2 = polynomial_012(q_coefficients, zeta)
    factor = (-zeta).exp() / (4 * pi)
    return (
        P0 - factor * Q0,
        P1 - factor * (Q1 - Q0),
        P2 - factor * (Q2 - 2 * Q1 + Q0),
    )


def regular_coordinate_pair(target, source, kappa, beta, d, chi, polynomial,
                            q_coefficients, coincident=False, displacement=None):
    pi = exact_pi()
    if displacement is not None:
        X, Y = displacement
    elif coincident:
        # The diagonal is the exact same analytic point. Independent interval
        # subtraction would lose this dependency at nonzero grid nodes.
        X = arb(0)
        Y = arb(0)
    else:
        X = target[0] - source[0]
        Y = target[1] - source[1]
    h = arb(EWALD_SPLIT) / d
    value = acb(0)
    dx = acb(0)
    dy = acb(0)
    dxx = acb(0)
    dxy = acb(0)
    dyy = acb(0)
    for mode in range(-(RECIPROCAL_CUTOFF - 1), RECIPROCAL_CUTOFF):
        transverse = beta + 2 * pi * mode / d
        q_mode = linton_q(kappa, transverse)
        phase = exp_i(transverse * Y) / (4 * d * q_mode)
        F0 = acb(0)
        F1 = acb(0)
        F2 = acb(0)
        for epsilon in (-1, 1):
            argument = q_mode / (2 * h) + epsilon * h * X
            exponential = (epsilon * q_mode * X).exp()
            erfc_value = argument.erfc()
            argument_squared = square(argument)
            erfc_first = -2 / arb.const_sqrt_pi() * (-argument_squared).exp()
            erfc_second = 4 / arb.const_sqrt_pi() * argument * (-argument_squared).exp()
            F0 += exponential * erfc_value
            F1 += epsilon * exponential * (q_mode * erfc_value + h * erfc_first)
            F2 += exponential * (
                square(q_mode) * erfc_value
                + 2 * q_mode * h * erfc_first
                + square(h) * erfc_second
            )
        value += phase * F0
        dx += phase * F1
        dy += acb(0, transverse) * phase * F0
        dxx += phase * F2
        dxy += acb(0, transverse) * phase * F1
        dyy -= square(transverse) * phase * F0
    for image_index in (-2, -1, 1, 2):
        shifted_y = Y - image_index * d
        h_squared = square(h)
        zeta = h_squared * (square(X) + square(shifted_y))
        H0, H1, H2 = H_chi_finite(zeta, chi, REGULAR_TAYLOR_CUTOFF)
        phase = exp_i(beta * image_index * d) / (4 * pi)
        zx = 2 * h_squared * X
        zy = 2 * h_squared * shifted_y
        value += phase * H0
        dx += phase * H1 * zx
        dy += phase * H1 * zy
        dxx += phase * (H2 * square(zx) + 2 * h_squared * H1)
        dxy += phase * H2 * zx * zy
        dyy += phase * (H2 * square(zy) + 2 * h_squared * H1)
    h_squared = square(h)
    zeta = h_squared * (square(X) + square(Y))
    C0, C1, C2 = C_chi_finite(zeta, polynomial, q_coefficients)
    zx = 2 * h_squared * X
    zy = 2 * h_squared * Y
    value -= C0
    dx -= C1 * zx
    dy -= C1 * zy
    dxx -= C2 * square(zx) + 2 * h_squared * C1
    dxy -= C2 * zx * zy
    dyy -= C2 * square(zy) + 2 * h_squared * C1
    return value, dx, dy, dxx, dxy, dyy


def regular_centers(kappa, beta, d, geometry, tau_nodes, zeta_nodes):
    count = len(geometry["nodes"])
    chi, polynomial, q_coefficients = regular_c_coefficients(
        kappa, d, REGULAR_TAYLOR_CUTOFF
    )
    value_tau = acb_mat(count, count)
    value_zeta = acb_mat(count, count)
    normal_tau = acb_mat(count, count)
    normal_zeta = acb_mat(count, count)
    source_weight = geometry["speed"] * 2 * exact_pi() / count
    for target_index in range(count):
        ntx, nty = geometry["normal"][target_index]
        target = geometry["position"][target_index]
        for source_index in range(count):
            nsx, nsy = geometry["normal"][source_index]
            delta = 2 * exact_pi() * (target_index - source_index) / count
            midpoint = exact_pi() * (target_index + source_index) / count
            sine_half = (delta / 2).sin()
            displacement = (
                -2 * geometry["speed"] * midpoint.sin() * sine_half,
                2 * geometry["speed"] * midpoint.cos() * sine_half,
            )
            coordinate = regular_coordinate_pair(
                target,
                geometry["position"][source_index],
                kappa,
                beta,
                d,
                chi,
                polynomial,
                q_coefficients,
                coincident=(target_index == source_index),
                displacement=displacement,
            )
            if not all(value.is_finite() for value in coordinate):
                raise ValueError(
                    f"nonfinite regular coordinate target={target_index} source={source_index}: "
                    + ",".join(str(value) for value in coordinate)
                )
            value, dx, dy, dxx, dxy, dyy = coordinate
            source_normal = -(dx * nsx + dy * nsy)
            target_normal = dx * ntx + dy * nty
            mixed = -(
                dxx * ntx * nsx
                + dxy * (ntx * nsy + nty * nsx)
                + dyy * nty * nsy
            )
            value_tau[target_index, source_index] = source_weight * source_normal
            value_zeta[target_index, source_index] = -source_weight * value
            normal_tau[target_index, source_index] = source_weight * mixed
            normal_zeta[target_index, source_index] = -source_weight * target_normal
    return (
        value_tau * tau_nodes + value_zeta * zeta_nodes,
        normal_tau * tau_nodes + normal_zeta * zeta_nodes,
    )


def coordinate_contract(coordinate, nt, ns):
    return [
        coordinate[0],
        ns[0] * coordinate[1] + ns[1] * coordinate[2],
        nt[0] * coordinate[1] + nt[1] * coordinate[2],
        nt[0] * ns[0] * coordinate[3]
        + (nt[0] * ns[1] + nt[1] * ns[0]) * coordinate[4]
        + nt[1] * ns[1] * coordinate[5],
    ]


def radial_to_coordinate(radial, h, rx, ry):
    h_squared = square(h)
    return [
        radial[0],
        2 * h_squared * rx * radial[1],
        2 * h_squared * ry * radial[1],
        4 * square(h_squared) * square(rx) * radial[2] + 2 * h_squared * radial[1],
        4 * square(h_squared) * rx * ry * radial[2],
        4 * square(h_squared) * square(ry) * radial[2] + 2 * h_squared * radial[1],
    ]


def ewald_finite_upper(kappa, beta, d, rx, ry, ix, iy, ux, uy):
    pi = exact_pi()
    h = arb(EWALD_SPLIT) / d
    chi = square(kappa * d / (2 * EWALD_SPLIT))
    h_squared = square(h)
    upper_values = [arb(0)] * 6
    moments = [arb.const_sqrt_pi() / 2, arb(1) / 2, arb.const_sqrt_pi() / 4]
    radial = [
        moments[0],
        2 * h_squared * rx * moments[0] + 2 * h * moments[1],
        (4 * square(h_squared) * square(rx) + 2 * h_squared) * moments[0]
        + 8 * h * h_squared * rx * moments[1]
        + 4 * h_squared * moments[2],
    ]
    derivative_orders = ((0, 0), (1, 0), (0, 1), (2, 0), (1, 1), (0, 2))
    for mode in range(-(RECIPROCAL_CUTOFF - 1), RECIPROCAL_CUTOFF):
        transverse = beta + 2 * pi * mode / d
        q_mode = linton_q(kappa, transverse)
        q_abs = abs_upper(q_mode)
        q_lower = abs(q_mode).lower()
        if not q_lower > 0:
            raise ValueError("finite Ewald q denominator is not separated from zero")
        real_q = q_mode.real
        simple = lower(real_q) >= upper(2 * h_squared * ux) and lower(real_q) > 0
        if simple:
            q_lower = real_q.lower()
            for index, (r_order, s_order) in enumerate(derivative_orders):
                upper_values[index] += (
                    radial[r_order]
                    / (d * arb.const_sqrt_pi())
                    * abs_upper(transverse) ** s_order
                    / q_lower
                    * (-square(q_lower) / (4 * h_squared) + h_squared * square(ix) + abs_upper(transverse) * iy).exp()
                )
        else:
            u = q_abs / (2 * h) + h * rx
            exp_u = square(u).exp()
            E0 = 1 + 2 * u * exp_u / arb.const_sqrt_pi()
            E1 = 2 * exp_u / arb.const_sqrt_pi()
            E2 = 4 * u * exp_u / arb.const_sqrt_pi()
            exponential = (q_abs * rx + abs_upper(transverse) * iy).exp() / (2 * d * q_lower)
            F0 = exponential * E0
            F1 = exponential * (q_abs * E0 + h * E1)
            F2 = exponential * (square(q_abs) * E0 + 2 * q_abs * h * E1 + h_squared * E2)
            increment = [F0, F1, abs_upper(transverse) * F0, F2, abs_upper(transverse) * F1, square(abs_upper(transverse)) * F0]
            upper_values = [upper(upper_values[j] + increment[j]) for j in range(6)]
    for image in (-2, -1, 1, 2):
        u = h_squared * (square(abs(image) * d - uy) - square(ix) - square(iy))
        if lower(u) <= 0:
            raise ValueError("image finite domain")
        u_lower = lower(u)
        H01 = (chi - u_lower).exp() / u_lower
        H2 = (chi - u_lower).exp() * (1 / u_lower + 1 / square(u_lower))
        zx = 2 * h_squared * rx
        zy = 2 * h_squared * (abs(image) * d + ry)
        increment = [H01, zx * H01, zy * H01, square(zx) * H2 + 2 * h_squared * H01, zx * zy * H2, square(zy) * H2 + 2 * h_squared * H01]
        upper_values = [upper(upper_values[j] + increment[j] / (4 * pi)) for j in range(6)]
    return [upper(value) for value in upper_values]


def ewald_reciprocal_tail(kappa, beta, d, rx, ix, iy, ux):
    pi = exact_pi()
    h = arb(EWALD_SPLIT) / d
    h_squared = square(h)
    step = 2 * pi / d
    moments = [arb.const_sqrt_pi() / 2, arb(1) / 2, arb.const_sqrt_pi() / 4]
    radial = [
        moments[0],
        2 * h_squared * rx * moments[0] + 2 * h * moments[1],
        (4 * square(h_squared) * square(rx) + 2 * h_squared) * moments[0]
        + 8 * h * h_squared * rx * moments[1]
        + 4 * h_squared * moments[2],
    ]
    result = [arb(0)] * 6
    orders = ((0, 0), (1, 0), (0, 1), (2, 0), (1, 1), (0, 2))
    for sign in (-1, 1):
        transverse = step * RECIPROCAL_CUTOFF + sign * beta
        if lower(transverse - kappa) <= 0:
            raise ValueError("reciprocal first omitted")
        q_first = (square(transverse) - square(kappa)).sqrt()
        if lower(q_first - 2 * h_squared * ux) < 0:
            raise ValueError("reciprocal monotonicity")
        for index, (r_order, s_order) in enumerate(orders):
            ratio = (1 + step / transverse) ** s_order * (
                -step * (2 * transverse + step) / (4 * h_squared) + step * iy
            ).exp()
            ratio = upper(ratio)
            if not ratio < 1:
                raise ValueError("reciprocal tail ratio")
            first = transverse**s_order / q_first * (-square(q_first) / (4 * h_squared) + transverse * iy).exp()
            result[index] += radial[r_order] * (h_squared * square(ix)).exp() / (d * arb.const_sqrt_pi()) * first / (1 - ratio)
    return [upper(value) for value in result]


def ewald_image_tail(kappa, d, rx, ry, ix, iy, uy):
    pi = exact_pi()
    h = arb(EWALD_SPLIT) / d
    h_squared = square(h)
    chi = square(kappa * d / (2 * EWALD_SPLIT))
    u = h_squared * (square(IMAGE_CUTOFF * d - uy) - square(ix) - square(iy))
    distance = IMAGE_CUTOFF * d + ry
    if lower(u) <= 0:
        raise ValueError("image tail u")
    S1 = []
    S2 = []
    for power in range(3):
        ratio = (1 + d / distance) ** power * (
            -square(h) * d * (2 * (IMAGE_CUTOFF * d - uy) + d)
        ).exp()
        ratio = upper(ratio)
        if not ratio < 1:
            raise ValueError("image tail ratio")
        S1.append(upper(2 * distance**power * (-u).exp() / (u * (1 - ratio))))
        S2.append(upper(2 * distance**power * (-u).exp() / (square(u) * (1 - ratio))))
    scale = chi.exp() / (4 * pi)
    zx = 2 * h_squared * rx
    values = [
        S1[0],
        zx * S1[0],
        2 * h_squared * S1[1],
        square(zx) * (S1[0] + S2[0]) + 2 * h_squared * S1[0],
        zx * 2 * h_squared * (S1[1] + S2[1]),
        square(2 * h_squared) * (S1[2] + S2[2]) + 2 * h_squared * S1[0],
    ]
    return [upper(scale * value) for value in values]


def ewald_local_bound(kappa, d, rx, ry):
    pi = exact_pi()
    h = arb(EWALD_SPLIT) / d
    h_squared = square(h)
    chi = square(kappa * d / (2 * EWALD_SPLIT))
    r0 = h_squared * (square(rx) + square(ry))
    B = LOCAL_CAUCHY_FACTOR * r0
    if not lower(B - r0) > 0:
        raise ValueError("local Ewald Cauchy radius is not separated")
    cutoff = EWALD_LOCAL_CUTOFF
    x = chi * B
    xq = chi * (1 + B)
    ratios = [
        x / (cutoff + 2) ** 2,
        B * (cutoff + 1) / (cutoff + 2) ** 2,
        x / (cutoff + 2) ** 2 * (1 + arb(1) / (cutoff + 2)),
        xq * (cutoff + 1) / (cutoff + 2) ** 2,
    ]
    ratios = [upper(value) for value in ratios]
    if not all(value < 1 for value in ratios):
        raise ValueError("local Ewald ratio")
    harmonic = sum(arb(1) / j for j in range(1, cutoff + 2))
    tau_J = x ** (cutoff + 1) / (math.factorial(cutoff + 1) ** 2 * (1 - ratios[0]))
    tau_S = B ** (cutoff + 1) / ((cutoff + 1) * math.factorial(cutoff + 1) * (1 - ratios[1]))
    tau_D = harmonic * x ** (cutoff + 1) / (math.factorial(cutoff + 1) ** 2 * (1 - ratios[2]))
    tau_Q = xq ** (cutoff + 1) / ((1 + B) * (cutoff + 1) * math.factorial(cutoff + 1) * (1 - ratios[3]))
    c_eta = abs_upper(chi.log() + arb.const_euler() - acb(0, pi))
    tau_C = (
        tau_J * (B.exp() - 1 + c_eta) + (chi * B).exp() * tau_S + B.exp() * tau_Q
    ) / (4 * pi) + tau_D / (2 * pi)
    tail = radial_to_coordinate([tau_C, tau_C / (B - r0), 2 * tau_C / square(B - r0)], h, rx, ry)
    indices = range(cutoff + 1)
    Jfinite = sum((chi * B) ** n / math.factorial(n) ** 2 for n in indices)
    Sfinite = sum(B**n / (n * math.factorial(n)) for n in range(1, cutoff + 1))
    harmonic_value = arb(0)
    Dfinite = arb(0)
    Qfinite = arb(0)
    for n in range(1, cutoff + 1):
        harmonic_value += arb(1) / n
        Dfinite += harmonic_value * (chi * B) ** n / math.factorial(n) ** 2
        inner = sum(math.factorial(n - degree - 1) * B**degree for degree in range(n))
        Qfinite += chi**n / math.factorial(n) ** 2 * inner
    Mfinite = Jfinite * (Sfinite + c_eta) / (4 * pi) + B.exp() * Qfinite / (4 * pi) + Dfinite / (2 * pi)
    finite = radial_to_coordinate([Mfinite, Mfinite / (B - r0), 2 * Mfinite / square(B - r0)], h, rx, ry)
    return [upper(value) for value in finite], [upper(value) for value in tail]


def ewald_coordinate_bound(kappa, beta, d, domain):
    finite = ewald_finite_upper(kappa, beta, d, *domain)
    reciprocal = ewald_reciprocal_tail(kappa, beta, d, domain[0], domain[2], domain[3], domain[4])
    image = ewald_image_tail(kappa, d, domain[0], domain[1], domain[2], domain[3], domain[5])
    local_finite, local_tail = ewald_local_bound(kappa, d, domain[0], domain[1])
    return (
        [upper(finite[j] + local_finite[j]) for j in range(6)],
        [upper(reciprocal[j] + image[j] + local_tail[j]) for j in range(6)],
        reciprocal,
        image,
        local_tail,
    )


def retained_image_taylor_tail(kappa, d, rx, ry, uy):
    pi = exact_pi()
    h = arb(EWALD_SPLIT) / d
    h_squared = square(h)
    chi = square(kappa * d / (2 * EWALD_SPLIT))
    cutoff = REGULAR_TAYLOR_CUTOFF
    ratio = upper(chi / (cutoff + 2))
    if not ratio < 1:
        raise ValueError("retained-image Taylor ratio is not contractive")
    poisson = upper(chi ** (cutoff + 1) / math.factorial(cutoff + 1) / (1 - ratio))
    result = [arb(0)] * 6
    for image in (-2, -1, 1, 2):
        u = h_squared * square(abs(image) * d - uy)
        if not lower(u) > 0:
            raise ValueError("retained-image Taylor distance is not positive")
        theta = poisson * (-u).exp() / u
        zx = 2 * h_squared * rx
        zy = 2 * h_squared * (abs(image) * d + ry)
        increment = [1, zx, zy, square(zx) + 2 * h_squared, zx * zy, square(zy) + 2 * h_squared]
        result = [upper(result[j] + theta / (4 * pi) * increment[j]) for j in range(6)]
    return result


def regular_bounds(kappa, beta, d, radius, tau_coeff, zeta_coeff, orders):
    pi = exact_pi()
    a = PARAMETER_STRIP_WIDTH
    real_domain = (2 * radius, 2 * radius, arb(0), arb(0), 2 * radius, 2 * radius)
    position_abs = radius * a.cosh()
    position_imag = radius * a.sinh()
    strip_domain = (
        2 * position_abs,
        2 * position_abs,
        2 * position_imag,
        2 * position_imag,
        2 * position_abs,
        2 * position_abs,
    )
    real_finite, real_tail, reciprocal, image, local_tail = ewald_coordinate_bound(kappa, beta, d, real_domain)
    strip_finite, strip_tail, _, _, _ = ewald_coordinate_bound(kappa, beta, d, strip_domain)
    taylor_tail = retained_image_taylor_tail(kappa, d, real_domain[0], real_domain[1], real_domain[5])
    real_mass = [
        upper(2 * pi * radius * sum(matrix_row_norm_upper(tau_coeff, row) for row in range(tau_coeff.nrows()))),
        upper(2 * pi * radius * sum(matrix_row_norm_upper(zeta_coeff, row) for row in range(zeta_coeff.nrows()))),
    ]
    source_mass = [arb(0), arb(0)]
    for row, order in enumerate(orders):
        growth = (a * abs(order)).exp()
        source_mass[0] += growth * matrix_row_norm_upper(tau_coeff, row)
        source_mass[1] += growth * matrix_row_norm_upper(zeta_coeff, row)
    source_mass = [upper(value) for value in source_mass]
    normal_bound = a.cosh()
    KQ = coordinate_contract(strip_finite, [normal_bound, normal_bound], [normal_bound, normal_bound])
    Kfull = coordinate_contract([upper(strip_finite[j] + strip_tail[j]) for j in range(6)], [normal_bound, normal_bound], [normal_bound, normal_bound])
    source_integrand = [
        upper(radius * (KQ[1] * source_mass[0] + KQ[0] * source_mass[1])),
        upper(radius * (KQ[3] * source_mass[0] + KQ[2] * source_mass[1])),
    ]
    strip_action = [
        upper(Kfull[1] * real_mass[0] + Kfull[0] * real_mass[1]),
        upper(Kfull[3] * real_mass[0] + Kfull[2] * real_mass[1]),
    ]
    denominator = (a * NODE_COUNT).exp() - 1
    source_radius = [upper(4 * pi * source_integrand[j] / denominator) for j in range(2)]
    tails = (reciprocal, image, taylor_tail, local_tail)
    names = ("M_R", "M_I", "M_T", "M_L")
    components = []
    total_radius = []
    for action in range(2):
        item = {"source": source_radius[action]}
        for name, coordinate in zip(names, tails):
            contracted = coordinate_contract(coordinate, [arb(1), arb(1)], [arb(1), arb(1)])
            if action == 0:
                bound = contracted[1] * real_mass[0] + contracted[0] * real_mass[1]
            else:
                bound = contracted[3] * real_mass[0] + contracted[2] * real_mass[1]
            item[name] = upper(bound)
        item["total"] = upper(sum(item.values()))
        components.append(item)
        total_radius.append(item["total"])
    return total_radius, strip_action, components


# ---------------------------------------------------------------------------
# C5--C7 assembly: finite Rayleigh pieces, propagated states, walls and F14.


def row_scale(matrix_value, scales):
    if matrix_value.nrows() != len(scales):
        raise ValueError("row scale shape")
    out = acb_mat(matrix_value.nrows(), matrix_value.ncols())
    for row in range(matrix_value.nrows()):
        for col_index in range(matrix_value.ncols()):
            out[row, col_index] = scales[row] * matrix_value[row, col_index]
    return out


def embed_rows(matrix_value, source_orders, target_orders):
    if matrix_value.nrows() != len(source_orders):
        raise ValueError("embed source shape")
    positions = {order: row for row, order in enumerate(target_orders)}
    out = acb_mat(len(target_orders), matrix_value.ncols())
    for source_row, order in enumerate(source_orders):
        if order not in positions:
            raise ValueError("embed order absent")
        target_row = positions[order]
        for col_index in range(matrix_value.ncols()):
            out[target_row, col_index] = matrix_value[source_row, col_index]
    return out


def subrows(matrix_value, first, last):
    out = acb_mat(last - first, matrix_value.ncols())
    for row in range(first, last):
        for col_index in range(matrix_value.ncols()):
            out[row - first, col_index] = matrix_value[row, col_index]
    return out


def stack_columns(left, right):
    if left.nrows() != right.nrows():
        raise ValueError("column stack shape")
    out = acb_mat(left.nrows(), left.ncols() + right.ncols())
    for row in range(out.nrows()):
        for col_index in range(left.ncols()):
            out[row, col_index] = left[row, col_index]
        for col_index in range(right.ncols()):
            out[row, left.ncols() + col_index] = right[row, col_index]
    return out


def split_vector(vector_value, first, last):
    out = acb_mat(last - first, 1)
    for row in range(first, last):
        out[row - first, 0] = vector_value[row, 0]
    return out


def sum_row_bound_squared(center, radius):
    if center.nrows() != len(radius):
        raise ValueError("row-radius shape")
    total = arb(0)
    for row in range(center.nrows()):
        total += square(abs_upper(center[row, 0]) + radius[row])
    return upper(total)


def operator_row_bound_squared(center, radius):
    if center.nrows() != len(radius):
        raise ValueError("operator-radius shape")
    total = arb(0)
    for row in range(center.nrows()):
        total += square(matrix_row_norm_upper(center, row) + radius[row])
    return upper(total)


def acb_matrix_equal(left, right):
    if left.nrows() != right.nrows() or left.ncols() != right.ncols():
        return False
    return all(left[row, col_index] == right[row, col_index]
               for row in range(left.nrows()) for col_index in range(left.ncols()))


def off_surface_centers(mu, beta, d, geometry, xi_left, xi_right, wall_orders, x_left, x_right):
    mode_count = len(wall_orders)
    gamma = []
    beta_modes = []
    multiplier = []
    for order in wall_orders:
        beta_mode = beta + 2 * exact_pi() * order / d
        gamma_mode = exact_gamma(mu, beta_mode)
        beta_modes.append(beta_mode)
        gamma.append(gamma_mode)
        multiplier.append(acb(0, 1) / (2 * gamma_mode))
    left = acb_mat(NODE_COUNT, mode_count)
    right = acb_mat(NODE_COUNT, mode_count)
    dleft = acb_mat(NODE_COUNT, mode_count)
    dright = acb_mat(NODE_COUNT, mode_count)
    sqrt_d = d.sqrt()
    for node, ((x, y), (nx, ny)) in enumerate(zip(geometry["position"], geometry["normal"])):
        for mode in range(mode_count):
            psi = exp_i(y * beta_modes[mode]) / sqrt_d
            sl = psi * exp_i((x - x_left) * gamma[mode]) * multiplier[mode]
            sr = psi * exp_i((x_right - x) * gamma[mode]) * multiplier[mode]
            left[node, mode] = sl
            right[node, mode] = sr
            dleft[node, mode] = sl * acb(0, 1) * (nx * gamma[mode] + ny * beta_modes[mode])
            dright[node, mode] = sr * acb(0, 1) * (-nx * gamma[mode] + ny * beta_modes[mode])
    value = left * xi_left + right * xi_right
    normal = dleft * xi_left + dright * xi_right
    clearance = upper(min(lower(abs(x_left) - geometry["strip_position_abs"]),
                          lower(abs(x_right) - geometry["strip_position_abs"])))
    if not clearance > 0:
        raise ValueError("off-surface strip clearance")
    map_norm = [upper(matrix_row_norm_upper(xi_left, row) + matrix_row_norm_upper(xi_right, row))
                for row in range(mode_count)]
    A0 = arb(0)
    A1 = arb(0)
    for mode in range(mode_count):
        real_gamma = abs(gamma[mode].real).upper()
        imag_gamma = gamma[mode].imag.lower()
        if imag_gamma < 0:
            raise ValueError("off-surface outgoing branch")
        beta_abs = abs(beta_modes[mode]).upper()
        growth = (real_gamma * geometry["strip_position_imag"]
                  + beta_abs * geometry["strip_position_imag"]
                  - imag_gamma * clearance).exp()
        row_bound = abs_upper(multiplier[mode]) * map_norm[mode] / sqrt_d.lower() * growth
        A0 += row_bound
        A1 += row_bound * (abs_upper(gamma[mode]) + beta_abs) * geometry["normal_component_upper"]
    return value, normal, upper(A0), upper(A1), gamma, beta_modes


def propagation_record(P):
    norm_upper = matrix_frobenius_upper(P)
    if not norm_upper < 1:
        raise ValueError("full propagation Frobenius bound is not contractive")
    return {"frobenius_upper": norm_upper,
            "sum_power_squared_upper": upper(1 / (1 - square(norm_upper)))}


def propagate(P, state, count):
    result = state
    for _ in range(count):
        result = P * result
    return result


def choose_cell_cutoff(Pplus, Pminus, cplus, cminus, prop_plus, prop_minus):
    records = []
    selected = None
    for cutoff in CELL_CUTOFF_SCHEDULE:
        qp = propagate(Pplus, cplus, cutoff)
        qm = propagate(Pminus, cminus, cutoff)
        plus = upper(prop_plus["sum_power_squared_upper"] * square(vector_norm_upper(qp)))
        minus = upper(prop_minus["sum_power_squared_upper"] * square(vector_norm_upper(qm)))
        total = upper(plus + minus)
        records.append({"cutoff": cutoff, "plus": plus, "minus": minus, "total": total})
        if selected is None and total <= TAIL_SQUARED_ALLOCATION:
            selected = cutoff
    if selected is None:
        selected = CELL_CUTOFF_SCHEDULE[-1]
    return selected, records


def direct_material_sequence(center, radius, strip_upper, boundary_length, G, P, c,
                             propagation, cutoff):
    ds = boundary_length / NODE_COUNT
    target_factor = 2 * boundary_length / ((PARAMETER_STRIP_WIDTH * NODE_COUNT).exp() - 1)
    state = c
    finite_node = arb(0)
    finite_contour = arb(0)
    for _ in range(cutoff):
        field_state = G * state
        state_norm = vector_norm_upper(field_state)
        finite_node += ds * sum_row_bound_squared(center * field_state,
                                                   [upper(item * state_norm) for item in radius])
        finite_contour += target_factor * square(strip_upper) * square(state_norm)
        state = P * state
    state_factor = upper(propagation["sum_power_squared_upper"] * square(vector_norm_upper(state)))
    # C6 uses a complete real-line row upper. The strip upper also bounds it.
    tail = upper(boundary_length * square(strip_upper) * square(matrix_frobenius_upper(G)) * state_factor)
    finite_node_upper = upper(finite_node)
    finite_contour_upper = upper(finite_contour)
    return {"finite_node_squared": finite_node_upper,
            "finite_contour_squared": finite_contour_upper,
            "propagation_tail_squared": tail,
            "total_squared": upper(finite_node_upper + finite_contour_upper + tail)}


def density_map_l1(coefficients, maps, boundary_length):
    total = arb(0)
    for state_map in maps:
        action = coefficients * state_map
        for row in range(action.nrows()):
            total += boundary_length * matrix_row_norm_upper(action, row)
    return upper(total)


def geometric_moments(ratio, first):
    if not (lower(ratio) > 0 and upper(ratio) < 1):
        raise ValueError("geometric ratio gate")
    first_power = ratio**first
    S0 = first_power / (1 - ratio)
    S1 = first_power * (first / (1 - ratio) + ratio / (1 - ratio) ** 2)
    S2 = first_power * (first**2 / (1 - ratio)
                        + 2 * first * ratio / (1 - ratio) ** 2
                        + ratio * (1 + ratio) / (1 - ratio) ** 3)
    return upper(S0), upper(S1), upper(S2)


def wall_high_normal(mu, beta, d, delta, boundary_length, tau, zeta, maps):
    At = density_map_l1(tau, maps, boundary_length)
    Az = density_map_l1(zeta, maps, boundary_length)
    q0 = 2 * exact_pi() / d
    b = abs(beta).upper()
    k = mu.sqrt().upper()
    first = WALL_MODE_CUTOFF + 1
    b0 = q0 * first - b
    if not lower(b0 - 2 * k) > 0:
        raise ValueError("wall normal high-mode margin")
    ratio = (-2 * delta * q0).exp()
    S0, S1, S2 = geometric_moments(ratio, first)
    bracket = (4 * square(At) * (square(q0) * S2 + 2 * q0 * b * S1 + square(b) * S0)
               + 4 * At * Az * (q0 * S1 + b * S0) + square(Az) * S0)
    return upper((2 * delta * (b + k)).exp() / (2 * d) * bracket)


def wall_high_value(mu, beta, d, delta, boundary_length, tau, zeta, maps):
    At = density_map_l1(tau, maps, boundary_length)
    Az = density_map_l1(zeta, maps, boundary_length)
    q0 = 2 * exact_pi() / d
    b = abs(beta).upper()
    k = mu.sqrt().upper()
    first = WALL_MODE_CUTOFF + 1
    b0 = q0 * first - b - k
    if not lower(b0) > 0:
        raise ValueError("wall value high-mode margin")
    Rbeta = upper(1 + k / b0)
    amplitude = upper((2 * Rbeta * At + Az / b0) / (2 * d.sqrt().lower()))
    constant = upper((delta * (k + b)).exp() * amplitude)
    ratio = (-2 * delta * q0).exp()
    S0, _, _ = geometric_moments(ratio, first)
    return upper(2 * square(constant) * S0)


def wall_curve_rows(side, wall_x, beta_modes, gamma, geometry, tau_nodes, zeta_nodes,
                    tau_coeff, zeta_coeff, density_orders, d):
    mode_count = len(beta_modes)
    phase = acb_mat(mode_count, NODE_COUNT)
    phase_factor = acb_mat(mode_count, NODE_COUNT)
    for mode in range(mode_count):
        for node, ((x, y), (nx, ny)) in enumerate(zip(geometry["position"], geometry["normal"])):
            distance = side * (wall_x - x)
            if not lower(distance) > 0:
                raise ValueError("wall curve distance")
            value = exp_i(distance * gamma[mode] - y * beta_modes[mode])
            factor = acb(0, 1) * (side * nx * gamma[mode] + ny * beta_modes[mode])
            phase[mode, node] = value
            phase_factor[mode, node] = value * factor
    weighted_tau = row_scale(tau_nodes, [geometry["speed"]] * NODE_COUNT)
    weighted_zeta = row_scale(zeta_nodes, [geometry["speed"]] * NODE_COUNT)
    scale = 2 * exact_pi() / NODE_COUNT / (2 * d.sqrt())
    rows = scale * (phase_factor * weighted_tau + phase * weighted_zeta)
    tau_strip = row_norm_sums(tau_coeff, density_orders, PARAMETER_STRIP_WIDTH, 0)[0]
    zeta_strip = row_norm_sums(zeta_coeff, density_orders, PARAMETER_STRIP_WIDTH, 0)[0]
    clearance = abs(wall_x) - geometry["strip_position_abs"]
    if not lower(clearance) > 0:
        raise ValueError("wall source strip clearance")
    radius = []
    denominator = (PARAMETER_STRIP_WIDTH * NODE_COUNT).exp() - 1
    for beta_mode, gamma_mode in zip(beta_modes, gamma):
        log_phase = (abs(gamma_mode.real).upper() * geometry["strip_position_imag"]
                     + abs(beta_mode).upper() * geometry["strip_position_imag"]
                     - gamma_mode.imag.lower() * clearance.lower())
        factor_bound = (abs_upper(gamma_mode) + abs(beta_mode).upper()) * geometry["normal_component_upper"]
        M = geometry["speed"] / (2 * d.sqrt().lower()) * (factor_bound * tau_strip + zeta_strip)
        radius.append(upper(4 * exact_pi() * M * log_phase.exp() / denominator))
    return rows, radius


def wall_certificate(fields, mu, beta, d, geometry, tau_nodes, zeta_nodes,
                     tau_coeff, zeta_coeff, density_orders, cutoff, propagation):
    retained_orders = list(range(-WALL_MODE_CUTOFF, WALL_MODE_CUTOFF + 1))
    old_orders = [int(round(value.real)) for value in fields["wall_orders_512"]["values"]]
    if old_orders != list(range(-256, 256)):
        raise ValueError("wall half-open source support")
    beta_modes = [beta + 2 * exact_pi() * order / d for order in retained_orders]
    gamma = [exact_gamma(mu, item) for item in beta_modes]
    xi_left = embed_rows(matrix(fields, "xi_left_unit_512"), old_orders, retained_orders)
    xi_right = embed_rows(matrix(fields, "xi_right_unit_512"), old_orders, retained_orders)
    wall_input = matrix(fields, "wall_input_unit_512")
    input_left = embed_rows(subrows(wall_input, 0, 512), old_orders, retained_orders)
    input_right = embed_rows(subrows(wall_input, 512, 1024), old_orders, retained_orders)
    x_left = scalar(fields, "X_L")
    x_right = scalar(fields, "X_R")
    curve_left, eps_left = wall_curve_rows(-1, x_left, beta_modes, gamma, geometry,
                                           tau_nodes, zeta_nodes, tau_coeff,
                                           zeta_coeff, density_orders, d)
    curve_right, eps_right = wall_curve_rows(1, x_right, beta_modes, gamma, geometry,
                                             tau_nodes, zeta_nodes, tau_coeff,
                                             zeta_coeff, density_orders, d)
    length_x = x_right - x_left
    phase = [exp_i(item * length_x) for item in gamma]
    flat_left = (xi_left - row_scale(xi_right, phase)) / 2
    flat_right = (-row_scale(xi_left, phase) + xi_right) / 2
    QL = flat_left + curve_left
    QR = flat_right + curve_right
    inv_i_gamma = [1 / (acb(0, 1) * item) for item in gamma]
    flat_value_multiplier = [-item / 2 for item in inv_i_gamma]
    curve_value_multiplier = list(inv_i_gamma)
    flat_multiplier_gate = all(
        (2 * gamma[row] * flat_value_multiplier[row] - acb(0, 1)).contains(0)
        for row in range(len(gamma)))
    curve_multiplier_gate = all(
        (acb(0, 1) * gamma[row] * curve_value_multiplier[row] - 1).contains(0)
        for row in range(len(gamma)))
    if not flat_multiplier_gate:
        raise ValueError("flat wall value multiplier sign")
    if not curve_multiplier_gate:
        raise ValueError("curve wall value multiplier sign")
    flat_value_left = row_scale(xi_left + row_scale(xi_right, phase),
                                flat_value_multiplier)
    flat_value_right = row_scale(row_scale(xi_left, phase) + xi_right,
                                 flat_value_multiplier)
    curve_value_left = row_scale(curve_left, curve_value_multiplier)
    curve_value_right = row_scale(curve_right, curve_value_multiplier)
    VL = input_left - flat_value_left - curve_value_left
    VR = input_right - flat_value_right - curve_value_right
    gamma_lower = [abs(item).lower() for item in gamma]
    if not all(item > 0 for item in gamma_lower):
        raise ValueError("retained wall non-Wood")
    eps_VL = [upper(eps_left[row] / gamma_lower[row]) for row in range(len(gamma))]
    eps_VR = [upper(eps_right[row] / gamma_lower[row]) for row in range(len(gamma))]

    K = integer_value(fields, "K")
    M = integer_value(fields, "M")
    if K != 2 * M + 1:
        raise ValueError("center state order count")
    state_orders = list(range(-M, M + 1))
    selector = acb_mat(len(retained_orders), K)
    retained_positions = {order: row for row, order in enumerate(retained_orders)}
    for col_index, order in enumerate(state_orders):
        selector[retained_positions[order], col_index] = 1
    zero_selector = acb_mat(len(retained_orders), K)
    if not acb_matrix_equal(input_left, stack_columns(selector, zero_selector)):
        raise ValueError("left wall shared-data selector")
    if not acb_matrix_equal(input_right, stack_columns(zero_selector, selector)):
        raise ValueError("right wall shared-data selector")
    q = matrix(fields, "q_center")
    q_left = embed_rows(split_vector(q, 0, K), state_orders, retained_orders)
    q_right = embed_rows(split_vector(q, K, 2 * K), state_orders, retained_orders)
    d_left = row_scale(q_left - row_scale(q_right, phase),
                       [acb(0, 1) * item for item in gamma])
    d_right = row_scale(row_scale(q_left, phase) - q_right,
                        [acb(0, 1) * item for item in gamma])
    Dplus = matrix(fields, "Dplus")
    Dminus = matrix(fields, "Dminus")
    Gplus = matrix(fields, "Gplus")
    Gminus = matrix(fields, "Gminus")
    Pplus = matrix(fields, "Pplus")
    Pminus = matrix(fields, "Pminus")
    cplus = matrix(fields, "cplus")
    cminus = matrix(fields, "cminus")
    if not acb_matrix_equal(subrows(Gplus, 0, K), Dplus):
        raise ValueError("Gplus near block differs from Dplus")
    if not acb_matrix_equal(subrows(Gminus, K, 2 * K), Dminus):
        raise ValueError("Gminus near block differs from Dminus")
    hc_left = embed_rows(Dminus * cminus, state_orders, retained_orders) - q_left - row_scale(q_right, phase)
    hc_right = embed_rows(Dplus * cplus, state_orders, retained_orders) - row_scale(q_left, phase) - q_right

    gp_cp = Gplus * cplus
    gm_cm = Gminus * cminus
    normal_singleton = upper(
        sum_row_bound_squared(d_right + QL * gp_cp,
                              [upper(x * vector_norm_upper(gp_cp)) for x in eps_left])
        + sum_row_bound_squared(-d_left + QR * gm_cm,
                                [upper(x * vector_norm_upper(gm_cm)) for x in eps_right]))
    value_singleton = upper(
        sum_row_bound_squared(hc_left - VR * gm_cm,
                              [upper(x * vector_norm_upper(gm_cm)) for x in eps_VR])
        + sum_row_bound_squared(hc_right - VL * gp_cp,
                                [upper(x * vector_norm_upper(gp_cp)) for x in eps_VL]))

    rp = QR * Gplus + QL * (Gplus * Pplus)
    rm = QL * Gminus + QR * (Gminus * Pminus)
    GplusPplus = Gplus * Pplus
    GminusPminus = Gminus * Pminus
    Gplus_frobenius = matrix_frobenius_upper(Gplus)
    Gminus_frobenius = matrix_frobenius_upper(Gminus)
    GplusPplus_frobenius = matrix_frobenius_upper(GplusPplus)
    GminusPminus_frobenius = matrix_frobenius_upper(GminusPminus)
    ep = [upper(eps_right[row] * Gplus_frobenius
                + eps_left[row] * GplusPplus_frobenius)
          for row in range(len(gamma))]
    em = [upper(eps_left[row] * Gminus_frobenius
                + eps_right[row] * GminusPminus_frobenius)
          for row in range(len(gamma))]
    Wp = VR * Gplus - VL * GplusPplus
    Wm = VL * Gminus - VR * GminusPminus
    Wp_radius = [upper(eps_VR[row] * Gplus_frobenius
                       + eps_VL[row] * GplusPplus_frobenius)
                 for row in range(len(gamma))]
    Wm_radius = [upper(eps_VL[row] * Gminus_frobenius
                       + eps_VR[row] * GminusPminus_frobenius)
                 for row in range(len(gamma))]
    xp = cplus
    xm = cminus
    normal_finite = arb(0)
    value_finite = arb(0)
    for _ in range(cutoff):
        normal_finite += sum_row_bound_squared(rp * xp,
                                               [upper(x * vector_norm_upper(xp)) for x in ep])
        normal_finite += sum_row_bound_squared(rm * xm,
                                               [upper(x * vector_norm_upper(xm)) for x in em])
        value_finite += sum_row_bound_squared(Wp * xp,
                                              [upper(x * vector_norm_upper(xp)) for x in Wp_radius])
        value_finite += sum_row_bound_squared(Wm * xm,
                                              [upper(x * vector_norm_upper(xm)) for x in Wm_radius])
        xp = Pplus * xp
        xm = Pminus * xm
    plus_factor = upper(propagation["plus"]["sum_power_squared_upper"] * square(vector_norm_upper(xp)))
    minus_factor = upper(propagation["minus"]["sum_power_squared_upper"] * square(vector_norm_upper(xm)))
    plus_full_factor = upper(propagation["plus"]["sum_power_squared_upper"] * square(vector_norm_upper(cplus)))
    minus_full_factor = upper(propagation["minus"]["sum_power_squared_upper"] * square(vector_norm_upper(cminus)))
    normal_tail = upper(operator_row_bound_squared(rp, ep) * plus_factor
                        + operator_row_bound_squared(rm, em) * minus_factor)
    value_tail = upper(operator_row_bound_squared(Wp, Wp_radius) * plus_factor
                       + operator_row_bound_squared(Wm, Wm_radius) * minus_factor)

    boundary_length = geometry["boundary_length"]
    delta = (abs(x_left) - geometry["speed"])
    other_delta = abs(x_right) - geometry["speed"]
    if other_delta < delta:
        delta = other_delta
    normal_seq_plus = wall_high_normal(mu, beta, d, delta, boundary_length,
                                       tau_coeff, zeta_coeff, [Gplus, GplusPplus])
    normal_seq_minus = wall_high_normal(mu, beta, d, delta, boundary_length,
                                        tau_coeff, zeta_coeff, [Gminus, GminusPminus])
    normal_high = upper(normal_seq_plus * plus_full_factor + normal_seq_minus * minus_full_factor
                        + wall_high_normal(mu, beta, d, delta, boundary_length,
                                           tau_coeff, zeta_coeff, [gp_cp])
                        + wall_high_normal(mu, beta, d, delta, boundary_length,
                                           tau_coeff, zeta_coeff, [gm_cm]))
    value_seq_plus = wall_high_value(mu, beta, d, delta, boundary_length,
                                     tau_coeff, zeta_coeff, [Gplus, GplusPplus])
    value_seq_minus = wall_high_value(mu, beta, d, delta, boundary_length,
                                      tau_coeff, zeta_coeff, [Gminus, GminusPminus])
    value_high = upper(value_seq_plus * plus_full_factor + value_seq_minus * minus_full_factor
                       + wall_high_value(mu, beta, d, delta, boundary_length,
                                         tau_coeff, zeta_coeff, [gp_cp])
                       + wall_high_value(mu, beta, d, delta, boundary_length,
                                         tau_coeff, zeta_coeff, [gm_cm]))
    normal_finite_upper = upper(normal_finite)
    value_finite_upper = upper(value_finite)
    normal_total = upper(normal_singleton + normal_finite_upper + normal_tail + normal_high)
    value_total = upper(value_singleton + value_finite_upper + value_tail + value_high)
    return {
        "normal": {"singleton": normal_singleton, "finite": normal_finite_upper,
                   "propagation_tail": normal_tail, "high_mode": normal_high,
                   "total": normal_total},
        "value": {"singleton": value_singleton, "finite": value_finite_upper,
                  "propagation_tail": value_tail, "high_mode": value_high,
                  "total": value_total},
        "gates": {"Dplus_Gplus_near_exact": True,
                  "Dminus_Gminus_near_exact": True,
                  "shared_wall_input_selectors_exact": True,
                  "flat_value_multiplier_i_over_2gamma": flat_multiplier_gate,
                  "curve_value_multiplier_inverse_i_gamma": curve_multiplier_gate,
                  "retained_mode_count": len(retained_orders),
                  "first_omitted_absolute_order": WALL_MODE_CUTOFF + 1},
        "tail_state_factors": {"propagation_plus_from_J": plus_factor,
                               "propagation_minus_from_J": minus_factor,
                               "high_mode_plus_from_zero": plus_full_factor,
                               "high_mode_minus_from_zero": minus_full_factor}
    }


def center_mass_lower(fields, mu, beta, d):
    K = integer_value(fields, "K")
    M = integer_value(fields, "M")
    q = matrix(fields, "q_center")
    q_left = split_vector(q, 0, K)
    q_right = split_vector(q, K, 2 * K)
    length_x = scalar(fields, "X_R") - scalar(fields, "X_L")
    total_lower = arb(0)
    minimum_lambda = None
    for row, order in enumerate(range(-M, M + 1)):
        beta_mode = beta + 2 * exact_pi() * order / d
        radicand = mu - square(beta_mode)
        if lower(radicand) > 0:
            gamma = radicand.sqrt()
            A = length_x
            B = (gamma * length_x).sin() / gamma
        elif upper(radicand) < 0:
            kappa = (-radicand).sqrt()
            A = (1 - (-2 * kappa * length_x).exp()) / (2 * kappa)
            B = length_x * (-kappa * length_x).exp()
        else:
            raise ValueError("center mass Wood mode")
        lambda_plus = A + B
        lambda_minus = A - B
        lp = max(arb(0), lower(lambda_plus))
        lm = max(arb(0), lower(lambda_minus))
        minimum_lambda = min(lp, lm) if minimum_lambda is None else min(minimum_lambda, lp, lm)
        plus = q_left[row, 0] + q_right[row, 0]
        minus = q_left[row, 0] - q_right[row, 0]
        total_lower += (lp * square(abs(plus).lower()) + lm * square(abs(minus).lower())) / 2
    if not total_lower > 0:
        raise ValueError("center mass lower bound is not positive")
    squared_lower = lower(total_lower)
    return lower(squared_lower.sqrt()), squared_lower, minimum_lambda


def trace_constant(fields, mu):
    d = scalar(fields, "d")
    radius = scalar(fields, "R")
    delta_c = scalar(fields, "delta_c")
    delta_w = scalar(fields, "delta_w")
    h = delta_c if delta_c < delta_w else delta_w
    rho_disk = scalar(fields, "rho_disk")
    rho_min = arb(1) if rho_disk >= 1 else rho_disk
    rho_max = rho_disk if rho_disk >= 1 else arb(1)
    theta = 1 - h / radius
    if not lower(theta) > 0:
        raise ValueError("trace theta")
    c0 = 1 / (theta * h)
    c1 = h / (2 * theta)
    squared = c0 / (rho_min * square(mu)) + (c1 + square(d) * c0) / (4 * mu) + square(d) * c1 * rho_max
    x_left = scalar(fields, "X_L")
    x_right = scalar(fields, "X_R")
    L = scalar(fields, "L")
    geometry_gates = {
        "material_wall_disjoint": lower(min(abs(x_left) - radius, abs(x_right) - radius) - h - delta_w) >= 0,
        "material_cell_copy_disjoint": lower(L - 2 * (radius + h)) >= 0,
        "material_transverse_copy_disjoint": lower(d - 2 * (radius + h)) >= 0,
        "wall_pair_disjoint": lower(L - 2 * delta_w) >= 0,
    }
    if not all(geometry_gates.values()):
        raise ValueError("trace collar geometry")
    return upper(squared.sqrt()), upper(squared), geometry_gates


def record_parts(parts):
    return {name: ball_record(value) for name, value in parts.items()}


def require_finite_scalar(value, name):
    if not value.is_finite():
        raise ValueError(f"nonfinite certified scalar: {name}={value}")


def require_finite_matrix(value, name):
    for row in range(value.nrows()):
        for col_index in range(value.ncols()):
            if not value[row, col_index].is_finite():
                raise ValueError(
                    f"nonfinite certified matrix entry: {name}[{row},{col_index}]={value[row,col_index]}"
                )


def exact_input_self_test(fields):
    for name, item in fields.items():
        for stored in item["values"]:
            exact_components = []
            for component in (stored.real, stored.imag):
                numerator, denominator = component.as_integer_ratio()
                expected = arb(numerator) / denominator
                lifted = arb(component)
                if lifted.rad() != 0 or lifted != expected:
                    raise ValueError(f"binary64 exact-lift failure: {name}")
                exact_components.append(expected)
            lifted_complex = acb(stored)
            expected_complex = acb(exact_components[0], exact_components[1])
            if (lifted_complex.real.rad() != 0 or lifted_complex.imag.rad() != 0
                    or lifted_complex != expected_complex):
                raise ValueError(f"complex binary64 exact-lift failure: {name}")


def require_input_contract(fields):
    required = {
        "khat", "mu_h", "beta", "d", "R", "rho_disk", "rho_exterior", "delta_c", "delta_w",
        "X_L", "X_R", "L", "M", "K", "q_center", "Dplus", "Dminus",
        "Gplus", "Gminus", "Pplus", "Pminus", "cplus", "cminus",
        "eta_unit_256", "xi_left_unit_512", "xi_right_unit_512",
        "wall_input_unit_512", "wall_orders_512",
    }
    if set(fields) != required:
        raise ValueError(f"input field contract mismatch: {set(fields) ^ required}")
    M = integer_value(fields, "M")
    K = integer_value(fields, "K")
    shapes = {
        "q_center": (2 * K, 1), "Dplus": (K, K), "Dminus": (K, K),
        "Gplus": (2 * K, K), "Gminus": (2 * K, K),
        "Pplus": (K, K), "Pminus": (K, K), "cplus": (K, 1), "cminus": (K, 1),
        "eta_unit_256": (512, 2 * K), "xi_left_unit_512": (512, 2 * K),
        "xi_right_unit_512": (512, 2 * K), "wall_input_unit_512": (1024, 2 * K),
    }
    if K != 2 * M + 1:
        raise ValueError("K/M contract")
    if scalar(fields, "rho_exterior") != 1:
        raise ValueError("unit exterior density contract")
    for name, shape in shapes.items():
        if fields[name]["shape"] != shape:
            raise ValueError(f"shape contract {name}: {fields[name]['shape']} != {shape}")
    orders = [value.real for value in fields["wall_orders_512"]["values"]]
    if orders != list(range(-256, 256)):
        raise ValueError("wall order contract")
    if not (128 + KERNEL_SERIES_CUTOFF + 1 < NODE_COUNT / 2):
        raise ValueError("retained source degree exactness")
    exact_input_self_test(fields)


def run_certificate(export_dir, output_path):
    started = time.monotonic()
    _, fields = load_binary64_export(export_dir)
    require_input_contract(fields)
    print("STAGE input exact binary64 and shape gates PASS", flush=True)
    khat = scalar(fields, "khat")
    mu = square(khat)
    mu_h = scalar(fields, "mu_h")
    beta = scalar(fields, "beta")
    d = scalar(fields, "d")
    radius = scalar(fields, "R")
    rho_disk = scalar(fields, "rho_disk")
    geometry = circle_geometry(radius)

    trace_upper, trace_squared_upper, geometry_gates = trace_constant(fields, mu)
    print(f"STAGE trace C <= {trace_upper}", flush=True)
    Pplus = matrix(fields, "Pplus")
    Pminus = matrix(fields, "Pminus")
    cplus = matrix(fields, "cplus")
    cminus = matrix(fields, "cminus")
    Gplus = matrix(fields, "Gplus")
    Gminus = matrix(fields, "Gminus")
    propagation = {"plus": propagation_record(Pplus), "minus": propagation_record(Pminus)}
    cutoff, cutoff_records = choose_cell_cutoff(Pplus, Pminus, cplus, cminus,
                                                 propagation["plus"], propagation["minus"])
    print(f"STAGE propagation J={cutoff} r+= {propagation['plus']['frobenius_upper']} "
          f"r-= {propagation['minus']['frobenius_upper']}", flush=True)

    eta = matrix(fields, "eta_unit_256")
    density_orders, tau_coeff, zeta_coeff = exact_dft_operator(eta)
    tau_nodes, zeta_nodes, tau_prime_nodes, _ = density_nodes(
        tau_coeff, zeta_coeff, density_orders, geometry["nodes"])
    require_finite_matrix(tau_coeff, "tau_coeff")
    require_finite_matrix(zeta_coeff, "zeta_coeff")
    require_finite_matrix(tau_nodes, "tau_nodes")
    require_finite_matrix(zeta_nodes, "zeta_nodes")
    require_finite_matrix(tau_prime_nodes, "tau_prime_nodes")
    kappa_e = khat
    kappa_i = khat * rho_disk.sqrt()
    outer_bounds = primitive_bounds(kappa_e, radius, KERNEL_SERIES_CUTOFF)
    inner_bounds = primitive_bounds(kappa_i, radius, KERNEL_SERIES_CUTOFF)
    factors, local_tails = local_factor_bounds(outer_bounds, inner_bounds,
                                                kappa_e, kappa_i, radius)
    tau_real = row_norm_sums(tau_coeff, density_orders, arb(0), 5)
    zeta_real = row_norm_sums(zeta_coeff, density_orders, arb(0), 5)
    tau_strip = row_norm_sums(tau_coeff, density_orders, PARAMETER_STRIP_WIDTH, 5)
    zeta_strip = row_norm_sums(zeta_coeff, density_orders, PARAMETER_STRIP_WIDTH, 5)
    local_value_bound, local_normal_bound, local_value_radius, local_normal_radius = \
        local_bounds(factors, local_tails, tau_real, zeta_real, radius)
    local_value_strip, local_normal_strip, _, _ = \
        local_bounds(factors, local_tails, tau_strip, zeta_strip, radius)
    local_value, local_normal = local_centers(
        kappa_e, kappa_i, radius, geometry["nodes"], tau_nodes, zeta_nodes,
        tau_prime_nodes, outer_bounds["retained"], inner_bounds["retained"])
    require_finite_matrix(local_value, "local_value")
    require_finite_matrix(local_normal, "local_normal")
    for name, value in (("local_value_radius", local_value_radius),
                        ("local_normal_radius", local_normal_radius),
                        ("local_value_strip", local_value_strip),
                        ("local_normal_strip", local_normal_strip)):
        require_finite_scalar(value, name)
    print("STAGE local signed centers/radii PASS", flush=True)

    regular_value, regular_normal = regular_centers(
        kappa_e, beta, d, geometry, tau_nodes, zeta_nodes)
    regular_radius, regular_strip, regular_components = regular_bounds(
        kappa_e, beta, d, radius, tau_coeff, zeta_coeff, density_orders)
    require_finite_matrix(regular_value, "regular_value")
    require_finite_matrix(regular_normal, "regular_normal")
    for index, action in enumerate(("value", "normal")):
        require_finite_scalar(regular_radius[index], f"regular_{action}_radius")
        require_finite_scalar(regular_strip[index], f"regular_{action}_strip")
        for component, value in regular_components[index].items():
            require_finite_scalar(value, f"regular_{action}_{component}")
    print("STAGE regular Ewald centers/radii PASS", flush=True)
    wall_orders = list(range(-256, 256))
    off_value, off_normal, off_value_strip, off_normal_strip, _, _ = off_surface_centers(
        mu, beta, d, geometry, matrix(fields, "xi_left_unit_512"),
        matrix(fields, "xi_right_unit_512"), wall_orders,
        scalar(fields, "X_L"), scalar(fields, "X_R"))
    require_finite_matrix(off_value, "off_value")
    require_finite_matrix(off_normal, "off_normal")
    require_finite_scalar(off_value_strip, "off_value_strip")
    require_finite_scalar(off_normal_strip, "off_normal_strip")
    print("STAGE material component witnesses "
          f"rL=({local_value_radius},{local_normal_radius}) "
          f"rR=({regular_radius[0]},{regular_radius[1]}) "
          f"M=({local_value_strip + regular_strip[0] + off_value_strip},"
          f"{local_normal_strip + regular_strip[1] + off_normal_strip})", flush=True)
    material_value_center = local_value + regular_value + off_value
    material_normal_center = local_normal - regular_normal - off_normal
    material_value_radius = [upper(local_value_radius + regular_radius[0])] * NODE_COUNT
    material_normal_radius = [upper(local_normal_radius + regular_radius[1])] * NODE_COUNT
    material_value_strip = upper(local_value_strip + regular_strip[0] + off_value_strip)
    material_normal_strip = upper(local_normal_strip + regular_strip[1] + off_normal_strip)
    require_finite_matrix(material_value_center, "material_value_center")
    require_finite_matrix(material_normal_center, "material_normal_center")
    require_finite_scalar(material_value_strip, "material_value_strip")
    require_finite_scalar(material_normal_strip, "material_normal_strip")
    material_value_minus = direct_material_sequence(
        material_value_center, material_value_radius, material_value_strip,
        geometry["boundary_length"], Gminus, Pminus, cminus,
        propagation["minus"], cutoff)
    material_value_plus = direct_material_sequence(
        material_value_center, material_value_radius, material_value_strip,
        geometry["boundary_length"], Gplus, Pplus, cplus,
        propagation["plus"], cutoff)
    material_normal_minus = direct_material_sequence(
        material_normal_center, material_normal_radius, material_normal_strip,
        geometry["boundary_length"], Gminus, Pminus, cminus,
        propagation["minus"], cutoff)
    material_normal_plus = direct_material_sequence(
        material_normal_center, material_normal_radius, material_normal_strip,
        geometry["boundary_length"], Gplus, Pplus, cplus,
        propagation["plus"], cutoff)
    for label, part in (("material_value_minus", material_value_minus),
                        ("material_value_plus", material_value_plus),
                        ("material_normal_minus", material_normal_minus),
                        ("material_normal_plus", material_normal_plus)):
        for component, value in part.items():
            require_finite_scalar(value, f"{label}.{component}")
    material_value_total = upper(material_value_minus["total_squared"] + material_value_plus["total_squared"])
    material_normal_total = upper(material_normal_minus["total_squared"] + material_normal_plus["total_squared"])
    print(f"STAGE material value2<={material_value_total} normal2<={material_normal_total}", flush=True)

    wall = wall_certificate(fields, mu, beta, d, geometry, tau_nodes, zeta_nodes,
                            tau_coeff, zeta_coeff, density_orders, cutoff, propagation)
    for action in ("value", "normal"):
        for component, value in wall[action].items():
            require_finite_scalar(value, f"wall.{action}.{component}")
    for component, value in wall["tail_state_factors"].items():
        require_finite_scalar(value, f"wall.tail_state_factors.{component}")
    print(f"STAGE wall value2<={wall['value']['total']} normal2<={wall['normal']['total']}", flush=True)
    value_squared = upper(material_value_total + wall["value"]["total"])
    normal_squared = upper(material_normal_total + wall["normal"]["total"])
    epsilon_squared = upper(normal_squared + value_squared / square(d))
    epsilon_upper = upper(epsilon_squared.sqrt())
    mass_lower, mass_squared_lower, min_lambda = center_mass_lower(fields, mu, beta, d)
    Q_upper = upper(trace_upper * epsilon_upper)
    denominator_lower = lower(mass_lower - Q_upper)
    for name, value in (("value_squared", value_squared),
                        ("normal_squared", normal_squared),
                        ("epsilon_squared", epsilon_squared),
                        ("epsilon_upper", epsilon_upper),
                        ("mass_lower", mass_lower),
                        ("mass_squared_lower", mass_squared_lower),
                        ("Q_upper", Q_upper),
                        ("denominator_lower", denominator_lower)):
        require_finite_scalar(value, name)
    finite_bound = denominator_lower > 0
    if finite_bound:
        spectral_upper = upper(2 * upper(mu) * Q_upper / denominator_lower)
        interval_lower = lower(lower(mu) - spectral_upper)
        interval_upper = upper(upper(mu) + spectral_upper)
        require_finite_scalar(spectral_upper, "spectral_upper")
        require_finite_scalar(interval_lower, "interval_lower")
        require_finite_scalar(interval_upper, "interval_upper")
        status = "CERTIFIED_SPECTRAL_DISTANCE_UPPER_BOUND"
    else:
        spectral_upper = None
        interval_lower = None
        interval_upper = None
        status = "CERTIFIED_COMPONENT_BOUNDS_NO_FINITE_SPECTRAL_BOUND"
    print(f"STAGE F14 U>={mass_lower} eps<={epsilon_upper} Q<={Q_upper} "
          f"den>={denominator_lower} finite={finite_bound}", flush=True)

    result = {
        "schema": "EPOST_I6_RESOLVENT_V3_ARB_CERTIFICATE",
        "status": status,
        "backend": {"python_flint": "0.9.0", "arb_precision_bits": ARBITRARY_PRECISION_BITS,
                    "python_executable": sys.executable},
        "configuration": {"node_count": NODE_COUNT, "kernel_series_cutoff": KERNEL_SERIES_CUTOFF,
                          "parameter_strip_width_exact": "1/5",
                          "maximum_density_order": 128,
                          "retained_product_degree": 128 + KERNEL_SERIES_CUTOFF + 1,
                          "half_node_count": NODE_COUNT // 2,
                          "cell_cutoff_schedule": list(CELL_CUTOFF_SCHEDULE),
                          "selected_cell_cutoff": cutoff,
                          "propagated_state_tail_allocation": ball_record(TAIL_SQUARED_ALLOCATION)},
        "candidate": {"khat": ball_record(khat), "mu_exact_khat_squared": ball_record(mu),
                      "mu_h_diagnostic": ball_record(mu_h),
                      "mu_h_minus_mu": ball_record(mu_h - mu), "beta": ball_record(beta)},
        "trace": {"constant_upper": ball_record(trace_upper),
                  "constant_squared_upper": ball_record(trace_squared_upper),
                  "geometry_gates": geometry_gates},
        "propagation": {
            "plus": record_parts(propagation["plus"]),
            "minus": record_parts(propagation["minus"]),
            "cutoff_records": [{"cutoff": item["cutoff"],
                                "plus": ball_record(item["plus"]),
                                "minus": ball_record(item["minus"]),
                                "total": ball_record(item["total"])} for item in cutoff_records]},
        "material": {
            "value_minus": record_parts(material_value_minus),
            "value_plus": record_parts(material_value_plus),
            "normal_minus": record_parts(material_normal_minus),
            "normal_plus": record_parts(material_normal_plus),
            "value_total_squared": ball_record(material_value_total),
            "normal_total_squared": ball_record(material_normal_total),
            "node_radius": {"value": ball_record(material_value_radius[0]),
                            "normal": ball_record(material_normal_radius[0]),
                            "local_value": ball_record(local_value_radius),
                            "local_normal": ball_record(local_normal_radius),
                            "regular_value_components": record_parts(regular_components[0]),
                            "regular_normal_components": record_parts(regular_components[1])},
            "strip_action": {"local_value": ball_record(local_value_strip),
                             "local_normal": ball_record(local_normal_strip),
                             "regular_value": ball_record(regular_strip[0]),
                             "regular_normal": ball_record(regular_strip[1]),
                             "off_value": ball_record(off_value_strip),
                             "off_normal": ball_record(off_normal_strip),
                             "total_value": ball_record(material_value_strip),
                             "total_normal": ball_record(material_normal_strip)},
            "direct_curve_no_target_fourier": True,
            "material_high_mode_applicable": False},
        "wall": {"value": record_parts(wall["value"]),
                 "normal": record_parts(wall["normal"]), "gates": wall["gates"],
                 "tail_state_factors": record_parts(wall["tail_state_factors"])},
        "defect": {"value_squared_upper": ball_record(value_squared),
                   "normal_squared_upper": ball_record(normal_squared),
                   "epsilon_boundary_squared_upper": ball_record(epsilon_squared),
                   "epsilon_boundary_upper": ball_record(epsilon_upper),
                   "epsilon_volume_exact": ball_record(arb(0))},
        "mass": {"center_mass_squared_lower": ball_record(mass_squared_lower),
                 "U_lower": ball_record(mass_lower),
                 "minimum_gram_eigenvalue_lower": ball_record(min_lambda)},
        "F14": {"Q_upper": ball_record(Q_upper),
                "denominator_lower": ball_record(denominator_lower),
                "finite_bound": finite_bound,
                "spectral_distance_upper": ball_record(spectral_upper) if finite_bound else None,
                "interval_lower": ball_record(interval_lower) if finite_bound else None,
                "interval_upper": ball_record(interval_upper) if finite_bound else None},
        "gates": {"exact_binary64_payload_lift": True,
                  "lossless_stored_integer_to_binary64": True,
                  "interval_DFT": True,
                  "source_degree_exactness": True, "same_exact_mu_everywhere": True,
                  "unit_exterior_density_explicit": True,
                  "full_propagation_matrices": True, "denominator_positive": finite_bound,
                  "complete_strict_pipeline": True},
        "elapsed_seconds_python": time.monotonic() - started,
    }
    output_path = Path(output_path)
    if output_path.exists():
        raise FileExistsError(output_path)
    output_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    return result


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: certify_resolvent_v3.py EXPORT_DIR OUTPUT_JSON")
    result = run_certificate(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
    print(json.dumps({"status": result["status"],
                      "finite_bound": result["F14"]["finite_bound"],
                      "selected_cell_cutoff": result["configuration"]["selected_cell_cutoff"]}),
          flush=True)


if __name__ == "__main__":
    main()
