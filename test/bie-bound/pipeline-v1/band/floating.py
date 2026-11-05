# Copied from test/bie-bound/bandrel-v1/floating.py; pipeline adaptations documented in README.
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




def reproduce():
  """Original Appendix A arithmetic, with per-lead rows added for comparison."""
  import time
  start=time.perf_counter()
  eps=32*np.pi/np.expm1(.1*J);em=16*DIM*eps;eg=256*DIM*eps*(3+DIM*eps)
  Bs=[indicator_matrix(a) for a in (.12,.20)]
  templates=[(np.eye(DIM)+16*B,256*(B-B@B)) for B in Bs];rows=[]
  for panel,(l,h) in enumerate(zip(END,END[1:])):
    theta=np.pi*(l+h)/(2*SCALE);r=np.pi*(h-l)/(2*SCALE)
    low=(KLOW-r)**2;high=(KHIGH+r)**2
    K=np.diag((2*np.pi*MN[:,0]+theta)**2+(.5+2*np.pi*MN[:,1])**2)
    tail=min((2*np.pi*(N+1)-abs(theta))**2+.25,(2*np.pi*(N+1)-.5)**2+theta**2)
    den=tail-17*high;err=high*em+high**2/den*eg
    for side,(M,G) in enumerate(templates):
      e1=eigh(K-low*M,subset_by_index=[0,0],check_finite=False)[0][0]
      e2=eigh(K-high*M-high**2/den*G,subset_by_index=[0,1],check_finite=False)[0][1]
      rows.append(dict(panel=panel,side=side,lower=-e1-low*em,upper=e2-err,denominator=den,high=high,upper_error=err))
  result=dict(coefficient_error=eps,mass_matrix_error=em,G_matrix_error=eg,
    min_lower_negative_margin=min(r['lower'] for r in rows),min_upper_positive_margin=min(r['upper'] for r in rows),
    min_tail_denominator=min(r['denominator'] for r in rows),max_upper_lambda=max(r['high'] for r in rows),
    max_upper_matrix_error=max(r['upper_error'] for r in rows),rows=rows,seconds=time.perf_counter()-start)
  assert result['min_lower_negative_margin']>1.3972e-4 and result['min_upper_positive_margin']>7.5205e-3
  return result,Bs
