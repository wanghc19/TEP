# `tep_scan_local2_1.m` Route-B Diagnostic

This file is a conservative Route-B variant of `tep_scan_local2.m`.
Only a narrow cyclic near-diagonal band controlled by `m_band` is changed.

Inside that off-diagonal band, the three non-hypersingular Muller blocks
avoid subtracting the full exterior quasi-periodic kernel from the interior
kernel directly.  Instead they use

```text
G_ext_qp = Phi_k + R_k
S:   Phi_{n k} - Phi_k - R_k
D:   d(Phi_{n k} - Phi_k - R_k)/dn_y
D':  d(Phi_{n k} - Phi_k - R_k)/dn_x
```

The diagonal analytic limits from `tep_scan_local2.m` are unchanged, and
entries outside the band keep the `tep_scan_local2.m` behavior.  The T-block
is not changed and remains on the existing Kapur-Rokhlin-corrected path.

The purpose is to test whether the accuracy loss in `tep_scan_local2.m`
comes mainly from near-diagonal cancellation in the S, D, and D' blocks.
