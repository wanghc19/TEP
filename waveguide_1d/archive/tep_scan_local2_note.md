# `tep_scan_local2.m` Assembly Note

For small `r`, the 2D Helmholtz fundamental solution satisfies

```text
Phi_k(r) = (i/4) H_0^(1)(k r)
         = -(1/(2*pi)) log(r)
           -(1/(2*pi)) log(k/2)
           - gamma/(2*pi)
           + i/4
           + O(r^2 log r).
```

Thus the logarithmic singularity cancels in the Muller single-layer
difference, and the remaining diagonal contribution from
`Phi_{n k} - Phi_k` is `-(1/(2*pi))*log(n)`.

The exterior quasi-periodic Green's function is handled as

```text
G_ext_qp = Phi_k + R_k,
```

where `Phi_k` is the singular center-image free-space kernel and `R_k` is
the regular proxy/MFS remainder.  The diagonal limits in `tep_scan_local2.m`
use only `R_k` for the exterior regular part:

```text
S-difference:   K_S(x,x)  = -(1/(2*pi))*log(n) - R_k(x,x)
D-difference:   K_D(x,x)  = - d/dn_y R_k(x,y) |_{y=x}
D'-difference:  K_Dp(x,x) = - d/dn_x R_k(x,y) |_{x=y}
```

The S, D, and D' difference blocks are therefore treated as continuous
kernels: off-diagonal entries are direct kernel differences, and diagonal
entries use the analytic limits above.  Only the T-type block remains on the
old Kapur-Rokhlin-corrected path for now.
