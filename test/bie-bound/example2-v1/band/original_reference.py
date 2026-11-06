# B2 source: test/bie-bound/pipeline-v1/band/original_reference.py; generalized model plumbing.
# Copied from test/bie-bound/bandrel-v1/original_reference.py; pipeline adaptations documented in README.
"""Reproduce the finite certificate for both periodic-lead gaps.

Requires NumPy and SciPy. Run: OPENBLAS_NUM_THREADS=1 python h-band-reproduce.py
The certificate includes Fourier tails, phase interpolation, and the analytic
2048-point trapezoidal remainder. Finite matrix arithmetic/eigenvalues are
interpreted in the problem's rounding-excluded model. This implementation uses
ordinary floating point, not interval arithmetic or a rounding-error bound.
"""
import json
import numpy as np
from scipy.linalg import eigh

N, J, SCALE = 6, 2048, 4096
KLOW, KHIGH = 1.318, 2.375
MN = np.array([(m, n) for m in range(-N, N + 1)
                        for n in range(-N, N + 1)])
DIM = len(MN)  # 169

# Exact panel endpoints are these INTEGERS times pi/4096.
END = ([0, 1024, 1536, 2048, 2560, 2816, 3072, 3200,
        3328, 3392, 3456, 3520, 3584, 3616, 3648, 3680, 3712, 3744]
       + list(range(3760, 3889, 16)) + list(range(3896, 3953, 8))
       + list(range(3956, 4005, 4)) + list(range(4006, 4047, 2))
       + list(range(4047, 4097)))
assert END[0] == 0 and END[-1] == SCALE
assert all(l < h for l, h in zip(END, END[1:]))
assert len(END) - 1 == 118  # A consecutive chain covers [0, pi] exactly.


def indicator_matrix(a):
    """B_ij = integral_D exp(2 pi i ((m_j-m_i)x+(n_j-n_i)y))."""
    t = 2 * np.pi * np.arange(J) / J
    radius = .2 / np.sqrt(1 + a * a / 2)
    r, dr = radius * (1 + a * np.cos(3 * t)), -3 * radius * a * np.sin(3 * t)
    x, y = r * np.cos(t), r * np.sin(t)
    dx, dy = dr * np.cos(t) - r * np.sin(t), dr * np.sin(t) + r * np.cos(t)
    integers = np.arange(-2 * N, 2 * N + 1)
    coeff = np.empty((4 * N + 1, 4 * N + 1), complex)
    for i, m in enumerate(integers):
        qx, qy = 2 * np.pi * m, 2 * np.pi * integers[:, None]
        q2 = qx * qx + qy * qy
        wave = np.exp(1j * (qx * x[None, :] + qy * y[None, :]))
        flux = qx * dy[None, :] - qy * dx[None, :]
        integral = np.sum(wave * flux, axis=1) * (2 * np.pi / J)
        nz = q2[:, 0] > 0
        coeff[i, nz] = -1j * integral[nz] / q2[nz, 0]
        if m == 0:
            coeff[i, 2 * N] = .04 * np.pi  # Exact inclusion area.
    dm = MN[None, :, 0] - MN[:, None, 0]
    dn = MN[None, :, 1] - MN[:, None, 1]
    B = coeff[dm + 2 * N, dn + 2 * N]
    return (B + B.conj().T) / 2


# On |Im t| <= .1, every nonzero coefficient integrand has modulus < 8.
# Therefore each coefficient error is <= 32*pi/(exp(.1*J)-1).
EPS_B_ENTRY = 32 * np.pi / np.expm1(.1 * J)
EPS_B = DIM * EPS_B_ENTRY
EPS_M = 16 * EPS_B
EPS_G = 256 * EPS_B * (3 + EPS_B)
templates = []
for a in (.12, .20):
    B = indicator_matrix(a)
    templates.append((np.eye(DIM) + 16 * B, 256 * (B - B @ B)))

lower_min = upper_min = denominator_min = np.inf
lambda_max = upper_error_max = 0.
for l, h in zip(END, END[1:]):
    theta = np.pi * (l + h) / (2 * SCALE)
    r = np.pi * (h - l) / (2 * SCALE)
    assert 0 <= theta <= np.pi and KLOW > r
    low, high = (KLOW - r) ** 2, (KHIGH + r) ** 2
    K = np.diag((2 * np.pi * MN[:, 0] + theta) ** 2
                + (.5 + 2 * np.pi * MN[:, 1]) ** 2)
    tail = min((2 * np.pi * (N + 1) - abs(theta)) ** 2 + .25,
               (2 * np.pi * (N + 1) - .5) ** 2 + theta ** 2)
    denominator = tail - 17 * high
    assert denominator > 0
    upper_error = high * EPS_M + high ** 2 / denominator * EPS_G
    for M, G in templates:
        # lambda_1(T(low)+low*EPS_M*I) < 0 gives a true trial direction.
        eig1 = eigh(K - low * M, subset_by_index=[0, 0],
                    check_finite=False)[0][0]
        # lambda_2(Tminus(high)-upper_error*I) > 0 bounds full inertia <= 1.
        eig2 = eigh(K - high * M - high ** 2 / denominator * G,
                    subset_by_index=[0, 1], check_finite=False)[0][1]
        negative_margin = -eig1 - low * EPS_M
        positive_margin = eig2 - upper_error
        assert negative_margin > 0 and positive_margin > 0
        lower_min = min(lower_min, negative_margin)
        upper_min = min(upper_min, positive_margin)
    denominator_min = min(denominator_min, denominator)
    lambda_max = max(lambda_max, high)
    upper_error_max = max(upper_error_max, upper_error)

# The proved inequality |sqrt(lambda_j(theta))-sqrt(lambda_j(phi))|
# <= |theta-phi| extends both midpoint signs to every point of each panel.
# y-reflection composed with conjugation gives the same bands at -theta.
# Thus both full periodic leads have no spectrum in [1.318^2, 2.375^2].
print(json.dumps({
    "mode_dimension": DIM, "leads": 2, "common_panels": len(END) - 1,
    "phase_coverage": "[-pi, pi], exact consecutive integer endpoints + symmetry",
    "coefficient_error": EPS_B_ENTRY, "mass_matrix_error": EPS_M,
    "G_matrix_error": EPS_G, "max_upper_lambda": lambda_max,
    "min_tail_denominator": denominator_min,
    "max_upper_matrix_error": upper_error_max,
    "min_lower_negative_margin": lower_min,
    "min_upper_positive_margin": upper_min,
    "distance_to_original_window_at_least": "0.005276 (exact decimal)",
    "rounding": "excluded by the problem; no interval arithmetic used"
}, indent=2))
