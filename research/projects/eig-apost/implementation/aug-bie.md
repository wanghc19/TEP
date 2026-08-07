# Augmented BIE Stage 2 design

## Material Passport

- Origin Skill: academic-research-suite/experiment-agent
- Origin Mode: plan
- Origin Date: 2026-08-02
- Verification Status: PRE-REVIEWED
- Version Label: eig-apost-aug-bie-v1.0
- Repro Lock: null
- Git Base: 20b0cd0f4b26

This document freezes the Stage 2 center-coupling experiment. Its governing sources are
[[research/projects/eig-apost/phase3-analysis/s-root|root qualification]], especially
Section 4, and the center-coupling section of
[[research/projects/eig-apost/phase4-report/method.tex|the report method]]. The finite-lead
block convention and Dirichlet termination formulas come from
[[research/projects/eig-apost/phase3-analysis/s-dtn-chain|the DtN computation chain]] and
[[research/projects/eig-apost/implementation/half_guide_map|half-guide map Stage 1]]. The
implementation boundary comes from
[[research/projects/eig-apost/phase3-analysis/p-implement|the implementation route]].

The design passed a static Skeptic pre-review after revision. It authorizes
STAGE2_DISCRETE_ALGEBRA_IMPLEMENTATION_GO, subject to a second Skeptic review of the
executed evidence bundle. It does not authorize a guided-mode root calculation.

## Context, dependency map, and evidence level

The question is whether the current BIE and scattering interfaces can be joined into the
fixed-dimensional augmented matrix prescribed by the governing theory, while retaining
an auditable route to a center scattering matrix and a Dirichlet-terminated reduced
cross-check.

    primitive center BIE and port blocks
      + finite-lead scattering blocks
      + fixed density and port coordinates
        -> raw nine-group augmented matrix
        -> conditional center-scattering elimination
        -> conditional far-amplitude elimination
        -> independent 2p-by-2p reduced cross-check

The raw augmented matrix is primary. Every later arrow is available only when its own
elimination factors pass. No Cayley transform, root search, estimator, or physical
kernel--field claim is in scope.

- ESTABLISHED: the governing nine equation groups, the unknown count, and the abstract
  elimination follow from the cited Phase 3 and Phase 4 sources.
- ESTABLISHED: the direct-phase placement and density-coordinate mismatch below follow
  from line-by-line inspection of the named MATLAB interfaces.
- CONDITIONAL: discrete augmented-to-reduced nullspace equivalence holds only when all
  listed elimination factors are invertible.
- PROVISIONAL: the ellipse case is an interface smoke test at one unscreened point.
- BLOCKED: continuous BIE kernel--field equivalence and root readiness remain unproved.

## Frozen unknown and row order

Let the center BIE block have length $n$ and every amplitude block have length $p$. The
only allowed unknown order is

$$
  z=(\xi,a_c^-,b_c^+,b_c^-,a_c^+,a_f^-,b_f^-,b_f^+,a_f^+)^{\mathsf T}.
$$

The superscripts $-$ and $+$ identify the left and right leads, not adjoints.

| Block | One-based column range |
|---|---|
| $\xi$ | 1:n |
| $a_c^-$ | n + (1:p) |
| $b_c^+$ | n + p + (1:p) |
| $b_c^-$ | n + 2p + (1:p) |
| $a_c^+$ | n + 3p + (1:p) |
| $a_f^-$ | n + 4p + (1:p) |
| $b_f^-$ | n + 5p + (1:p) |
| $b_f^+$ | n + 6p + (1:p) |
| $a_f^+$ | n + 7p + (1:p) |

| Group | Equation | One-based row range |
|---|---|---|
| 1 | center BIE | 1:n |
| 2 | center left outgoing trace | n + (1:p) |
| 3 | center right outgoing trace | n + p + (1:p) |
| 4 | left-segment far output | n + 2p + (1:p) |
| 5 | left-segment center return | n + 3p + (1:p) |
| 6 | left far Dirichlet condition | n + 4p + (1:p) |
| 7 | right-segment center return | n + 5p + (1:p) |
| 8 | right-segment far output | n + 6p + (1:p) |
| 9 | right far Dirichlet condition | n + 7p + (1:p) |

With these orders, the raw matrix is exactly

$$
F_{j,h}^{\mathrm{aug}}=
\begin{bmatrix}
A_c&B_L&B_R&0&0&0&0&0&0\\
-\mathcal E_L&-J_{LL}&-J_{LR}&I&0&0&0&0&0\\
-\mathcal E_R&-J_{RL}&-J_{RR}&0&I&0&0&0&0\\
0&0&0&-T_{RL,j}^-&0&-R_{L,j}^-&I&0&0\\
0&I&0&-R_{R,j}^-&0&-T_{LR,j}^-&0&0&0\\
0&0&0&0&0&I&I&0&0\\
0&0&I&0&-R_{L,j}^+&0&0&-T_{RL,j}^+&0\\
0&0&0&0&-T_{LR,j}^+&0&0&-R_{R,j}^+&I\\
0&0&0&0&0&0&0&I&I
\end{bmatrix}.
$$

It is square of size $(n+8p)\times(n+8p)$. The implementation may not infer dimensions
from nonzero values, delete a zero block, or change the stored raw order.

## Density coordinate and actual code interfaces

The physical Nyström density used by bloch.farfield_extractors is

$$
  \eta=(\tau,-\sigma)^{\mathsf T}.
$$

Let the center boundary have $N_c=n/2$ nodes, parameter step
$h_{\partial,c}=\ell_c/N_c$, and nodal speeds $s_1,\ldots,s_{N_c}$. Define

$$
  D_h=\operatorname{diag}\!\left(
    \sqrt{h_{\partial,c}s_1},\ldots,\sqrt{h_{\partial,c}s_{N_c}},
    \sqrt{h_{\partial,c}s_1},\ldots,\sqrt{h_{\partial,c}s_{N_c}}
  \right).
$$

The augmented density coordinate is frozen as

$$
  \xi=D_h\eta.
$$

The mapping from actual interfaces is:

| Interface | Raw output | Stage 2 object |
|---|---|---|
| op.construct_A_QP | scaled square BIE matrix | $A_c=D_hA_c^{\mathrm{phys}}D_h^{-1}$ |
| bloch.incident_rhs | physical Cauchy columns | $B_L=D_hB_L^{\mathrm{phys}}$, $B_R=D_hB_R^{\mathrm{phys}}$ |
| bloch.farfield_extractors | physical scattered-field extractors named F_L and F_R in code | $\mathcal E_L=\mathcal E_L^{\mathrm{phys}}D_h^{-1}$, $\mathcal E_R=\mathcal E_R^{\mathrm{phys}}D_h^{-1}$ |
| bloch.construct_S | one-cell blocks, raw H_L and H_R, and E | scattering oracle only for constant-speed parameterizations; E is the direct phase |

The scaling follows directly from lines 99--101 of op.construct_A_QP. The current
bloch.construct_S solves the scaled matrix against unscaled incident columns and applies
unscaled extractors. It is coordinate-consistent only when $D_h=cI$, as for the circle
parameterization in Stage 1. On a variable-speed ellipse, its raw densities and scattering
blocks are diagnostic-only and may not be used as physical truth.

The variable-speed oracle uses two independent coordinate paths:

$$
\begin{aligned}
  H^{\mathrm{scaled}}&=-A_c\backslash[B_L,B_R],\\
  A_c^{\mathrm{phys}}&=D_h\backslash(A_cD_h),\\
  H^{\mathrm{phys}}&=-A_c^{\mathrm{phys}}\backslash
    [B_L^{\mathrm{phys}},B_R^{\mathrm{phys}}].
\end{aligned}
$$

It must verify $H^{\mathrm{scaled}}=D_hH^{\mathrm{phys}}$ and equal outgoing coefficients
under the scaled and physical extractors. Code uses diagonal scaling and linear solves,
not a general explicit inverse.

## Direct phase derived from bloch.construct_S

Define

$$
  E_c=\operatorname{diag}\!\left(
    \exp(\mathrm{i}\gamma_m(X_R^c-X_L^c))
  \right).
$$

The fields rayleighchan.phase and S_cell.E must reproduce $E_c$. The current code forms

$$
\begin{aligned}
  R_L^c&=\mathcal E_LH_L,&
  T_{LR}^c&=E_c+\mathcal E_RH_L,\\
  T_{RL}^c&=E_c+\mathcal E_LH_R,&
  R_R^c&=\mathcal E_RH_R.
\end{aligned}
$$

Therefore the direct blocks are fixed by code inspection:

$$
  J_{LL}=J_{RR}=0,
  \qquad
  J_{LR}=J_{RL}=E_c.
$$

The necessary aggregate is

$$
  J_c=\begin{bmatrix}0&E_c\\E_c&0\end{bmatrix}.
$$

This placement is falsified by three gates: zero density with left-only input gives only
the right direct output $E_ca_c^-$; zero density with right-only input gives only the left
direct output $E_cb_c^+$; and diagonal placement, a cross-block swap, or a sign mutation
must fail the manufactured known-vector residual.

For a constant-speed circle, the corrected scattering blocks must agree with
bloch.construct_S and corrected densities must equal $D_h$ times its raw densities. On an
ellipse, the scaled-versus-physical coordinate identity is the oracle.

## Center scattering and terminated reduction

Define center incoming and outgoing vectors

$$
  x_c=\begin{bmatrix}a_c^-\\b_c^+\end{bmatrix},
  \qquad
  y_c=\begin{bmatrix}b_c^-\\a_c^+\end{bmatrix}.
$$

When $A_c$ passes its pole gate, one multi-right-hand-side solve gives

$$
  [H_L,H_R]=-A_c\backslash[B_L,B_R],
$$

and

$$
  S_c=
  \begin{bmatrix}R_L^c&T_{RL}^c\\T_{LR}^c&R_R^c\end{bmatrix}
  =
  J_c+
  \begin{bmatrix}\mathcal E_L\\\mathcal E_R\end{bmatrix}
  [H_L,H_R],
  \qquad y_c=S_cx_c.
$$

At the left far wall,

$$
  \widehat R_{-,j}^{\mathrm D}
  =R_{R,j}^-
   -T_{LR,j}^-\left((I+R_{L,j}^-)\backslash T_{RL,j}^-\right).
$$

At the right far wall,

$$
  \widehat R_{+,j}^{\mathrm D}
  =R_{L,j}^+
   -T_{RL,j}^+\left((I+R_{R,j}^+)\backslash T_{LR,j}^+\right).
$$

Let

$$
  R_j^{\mathrm D}
  =\operatorname{diag}(\widehat R_{-,j}^{\mathrm D},
                       \widehat R_{+,j}^{\mathrm D}).
$$

The separately formed reduced cross-check is

$$
  F_{j,h}^{\mathrm{red}}=I_{2p}-R_j^{\mathrm D}S_c
$$

with explicit blocks

$$
F_{j,h}^{\mathrm{red}}=
\begin{bmatrix}
I-\widehat R_{-,j}^{\mathrm D}R_L^c&
-\widehat R_{-,j}^{\mathrm D}T_{RL}^c\\
-\widehat R_{+,j}^{\mathrm D}T_{LR}^c&
I-\widehat R_{+,j}^{\mathrm D}R_R^c
\end{bmatrix}.
$$

The mutation $I_{2p}-S_cR_j^{\mathrm D}$ is wrong when the factors do not commute, even
though its determinant can agree.

### Independent raw Schur path

The raw path assembles all nine groups. It retains columns $(a_c^-,b_c^+)$ and equation
groups 5 and 7. It eliminates

$$
  (\xi,b_c^-,a_c^+,a_f^-,b_f^-,b_f^+,a_f^+)
$$

using equation groups 1, 2, 3, 4, 6, 8, and 9. After independent row and column
permutation, write the matrix as

$$
  \begin{bmatrix}K_{ee}&K_{er}\\K_{re}&K_{rr}\end{bmatrix}.
$$

The raw Schur complement is computed by one solve:

$$
  K_{rr}-K_{re}(K_{ee}\backslash K_{er}).
$$

The reduced path consumes primitive corrected center and lead blocks, implements its own
center and termination formulas, and may not call the raw assembler, the raw-Schur helper,
or read blocks back from $F_{j,h}^{\mathrm{aug}}$. The two paths meet only at the final
matrix comparison.

When $A_c$, both terminal factors, and $K_{ee}$ are invertible, a nonzero augmented
nullvector exists if and only if a nonzero $x_c$ belongs to
$\ker F_{j,h}^{\mathrm{red}}$. This is conditional discrete algebra, not continuous
kernel--field equivalence.

## Manufactured exact oracle A1

This deterministic complex fixture is noncommuting and has a known one-dimensional
kernel. Set $p=2$, $n=4$, $I=I_2$, $0=0_{2\times2}$, and

$$
A_c=
\begin{bmatrix}
2&0.2+0.1\mathrm{i}&0&0.1\\
-0.1\mathrm{i}&1.7&0.15&0\\
0.05&0&1.5&-0.2\mathrm{i}\\
0&0.1&0.05&1.8
\end{bmatrix},
\quad
E_c=\operatorname{diag}(0.7+0.1\mathrm{i},0.4-0.2\mathrm{i}),
$$

$$
  \mathcal E_L=[I\;0],
  \qquad
  \mathcal E_R=[0\;I].
$$

Choose

$$
R_-=
\begin{bmatrix}
0.4&0.1+0.2\mathrm{i}\\
-0.05\mathrm{i}&0.3
\end{bmatrix},
\qquad
R_+=
\begin{bmatrix}
0.2&-0.15\mathrm{i}\\
0.07+0.04\mathrm{i}&0.35
\end{bmatrix},
$$

set $R^{\mathrm D}=\operatorname{diag}(R_-,R_+)$, and let

$$
  x_\star=(1,2\mathrm{i},-1+\mathrm{i},0.5)^{\mathsf T}.
$$

Start from

$$
S_0=
\begin{bmatrix}
0.2&0.05\mathrm{i}&0.1&-0.03\\
-0.04&0.25&0.02+0.01\mathrm{i}&0.06\\
0.08&-0.02\mathrm{i}&0.18&0.07\\
0.01+0.03\mathrm{i}&0.05&-0.06&0.22
\end{bmatrix}.
$$

Define $y_\star$ by the solve $R^{\mathrm D}y_\star=x_\star$, then set

$$
  S_c=S_0+
  \frac{(y_\star-S_0x_\star)x_\star^*}{x_\star^*x_\star}.
$$

Thus $S_cx_\star=y_\star$ and
$(I_4-R^{\mathrm D}S_c)x_\star=0$. With

$$
  J_c=\begin{bmatrix}0&E_c\\E_c&0\end{bmatrix},
  \qquad
  [B_L,B_R]=-A_c(S_c-J_c),
$$

the exact density is $\xi_\star=(S_c-J_c)x_\star$. Freeze the four distinct
transmission blocks as

$$
\begin{aligned}
T_{LR}^-&=
\begin{bmatrix}1&0.2\\-0.1\mathrm{i}&0.8\end{bmatrix},
&
T_{RL}^-&=
\begin{bmatrix}0.7&0.1\mathrm{i}\\0.15&1.1\end{bmatrix},\\
T_{LR}^+&=
\begin{bmatrix}0.9&-0.1\mathrm{i}\\0.2&1.2\end{bmatrix},
&
T_{RL}^+&=
\begin{bmatrix}1.1&0.15\\-0.05\mathrm{i}&0.75\end{bmatrix}.
\end{aligned}
$$

The full lead blocks are

| Lead | $R_L$ | $T_{RL}$ | $T_{LR}$ | $R_R$ |
|---|---|---|---|---|
| left | $0$ | $T_{RL}^-$ | $T_{LR}^-$ | $R_-+T_{LR}^-T_{RL}^-$ |
| right | $R_++T_{RL}^+T_{LR}^+$ | $T_{RL}^+$ | $T_{LR}^+$ | $0$ |

Writing $y_\star=((b_c^-)_\star,(a_c^+)_\star)^{\mathsf T}$, use

$$
\begin{aligned}
  (a_f^-)_\star&=-T_{RL}^-(b_c^-)_\star,&
  (b_f^-)_\star&=T_{RL}^-(b_c^-)_\star,\\
  (b_f^+)_\star&=-T_{LR}^+(a_c^+)_\star,&
  (a_f^+)_\star&=T_{LR}^+(a_c^+)_\star
\end{aligned}
$$

to form $z_\star$ in the frozen order.

A read-only Octave preflight gave augmented and reduced residuals 1.77e-17 and 2.35e-16,
an augmented normalized second-smallest singular value 3.740e-2, and a relative
noncommutator 4.20e-1. Wrong reduced order, diagonal direct phase, and a wrong left
terminal sign gave known-vector residuals 2.54e-1, 9.32e-2, and 7.32e-1. These are
provisional preflight values, not the formal evidence bundle.

The two terminated-map errors were 1.30e-16 and 1.24e-16. A literal simultaneous
$T_{LR}\leftrightarrow T_{RL}$ mutation in both scattering rows, with reflection blocks
and $z_\star$ unchanged, gave residuals 2.277e-2 on the left, 1.138e-2 on the right, and
2.545e-2 when applied on both sides. The four transmission reciprocal condition estimates
were all greater than 0.51.

Formal A1 gates require numerical nullity exactly one for augmented and reduced matrices,
agreement of lifted null directions, a second-smallest normalized singular value above
1e-4, and nonzero density, center-port, and far-port participation.

## Manufactured coordinate oracle A2

Reuse A1 as a physical-coordinate fixture and set

$$
  Q=\operatorname{diag}(1,2,3,4).
$$

Form

$$
  A_s=QA_cQ^{-1},
  \qquad
  B_s=Q[B_L,B_R],
  \qquad
  \mathcal E_s=
  \begin{bmatrix}\mathcal E_L\\\mathcal E_R\end{bmatrix}Q^{-1}.
$$

The corrected scaled and physical paths must reproduce A1 and the density-coordinate
relation. The intentional raw mutation that solves $A_s$ against unscaled $[B_L,B_R]$ and
applies unscaled extractors must differ from the A1 truth by more than 1e-3. The preflight
relative difference was 7.50e-2. This negative is SCALING_COORDINATE_MISMATCH.

## Actual BIE interface smoke B

The lead configuration is exactly validated Stage 1 Case B:

| Quantity | Frozen value |
|---|---|
| quasiperiodic parameter | $\beta=0.8$ |
| exterior and interior wavenumbers | $k=0.10$, $k_{\mathrm{int}}=0.30$ |
| material index | $n_{\mathrm{ref}}=3$ |
| lead inclusion | circle of radius $0.4$ |
| cell walls | $X_L=-1$, $X_R=1$ |
| cell length and period | $L=2$, $d=2\pi$ |
| Rayleigh truncation | $M=7$, hence $p=15$ |
| lead nodes and levels | 60, with $j=0,\ldots,6$ |

Proxy settings are periodic_axis equal to y, H equal to 1.8, proxy_dist equal to 0.7,
N_side and N_top equal to 40, N_proxy_edge equal to 24, and M_pw equal to 8.

The center is the unrotated ellipse with semiaxes $(0.28,0.21)$, the same walls, material,
channel chart, and 60 nodes. This is only the provisional seed from
[[research/projects/eig-apost/phase3-analysis/p-benchmark|the benchmark plan]]. No gap or
root has been screened for this circle-lead/ellipse-center combination. Its required label
is UNSCREENED_CENTER_BIE_INTERFACE_SMOKE.

Here $n=120$, $p=15$, and every augmented matrix is $240\times240$. The center uses the
corrected $D_h$ coordinate. Both leads reuse the same oriented doubled circle segment, so
$S_j^-=S_j^+=S_j$ only for this symmetric smoke.

The smoke may not call bloch.solve_modes, form a Cayley transform, search for a root, or
interpret a smallest singular vector as a mode. A near singular matrix at $k=0.10$ is only
an UNQUALIFIED_SINGULAR_CANDIDATE.

## Left/right sign gates

1. Compare bloch.incident_rhs against the explicit canonical traces

   $$
   u_m^L=\exp(\mathrm{i}\gamma_m(x-X_L))\psi_m,
   \qquad
   u_m^R=\exp(-\mathrm{i}\gamma_m(x-X_R))\psi_m
   $$

   and outward-normal derivatives. The left multiplier is
   $\mathrm{i}(\gamma_m\nu_x+\beta_m\nu_y)$; the right multiplier is
   $\mathrm{i}(-\gamma_m\nu_x+\beta_m\nu_y)$.
2. Apply the two zero-density direct-phase tests that fix the cross placement of $E_c$.
3. For each canonical $b_c^-$, solve raw left groups 4--6 and compare the returned $a_c^-$
   with $\widehat R_{-,j}^{\mathrm D}b_c^-$. Separately, for each canonical $a_c^+$, solve
   raw right groups 7--9 and compare $b_c^+$ with
   $\widehat R_{+,j}^{\mathrm D}a_c^+$.

Mutations of $a_f+b_f=0$ to $a_f-b_f=0$, a left/right swap, and the literal simultaneous
$T_{LR}\leftrightarrow T_{RL}$ replacement in both scattering rows of either chosen lead
must fail the known-vector threshold. In the transmission mutation, the reflection blocks
and $z_\star$ stay fixed.

## Fixed representation and adjacent-level difference

Across $j$, the dimensions, orders, center blocks, density scaling, channel ordering,
phase origins, normalization, material, terminal equations, and amplitude convention are
immutable. Only these eight positions may change in
$F_{j+1,h}^{\mathrm{aug}}-F_{j,h}^{\mathrm{aug}}$:

| Row group | Column block | Required difference |
|---|---|---|
| 4 | $b_c^-$ | $-\Delta T_{RL}^-$ |
| 4 | $a_f^-$ | $-\Delta R_L^-$ |
| 5 | $b_c^-$ | $-\Delta R_R^-$ |
| 5 | $a_f^-$ | $-\Delta T_{LR}^-$ |
| 7 | $a_c^+$ | $-\Delta R_L^+$ |
| 7 | $b_f^+$ | $-\Delta T_{RL}^+$ |
| 8 | $a_c^+$ | $-\Delta T_{LR}^+$ |
| 8 | $b_f^+$ | $-\Delta R_R^+$ |

Here $\Delta X=X_{j+1}-X_j$. Each allowed block is checked against the independently stored
lead difference. Every other block must be numerical zero. Padding, projection between
levels, and level-dependent rescaling are forbidden.

## Scalar gates

For like-sized matrices, define

$$
  e_{\mathrm{mat}}(X,Y)=
  \frac{\lVert X-Y\rVert_F}
  {\max\{1,\lVert X\rVert_F,\lVert Y\rVert_F\}}.
$$

For $MX=B$, define

$$
  r_{\mathrm{solve}}(M,X,B)=
  \frac{\lVert MX-B\rVert_F}
  {\max\{1,\lVert M\rVert_2\lVert X\rVert_F+\lVert B\rVert_F\}}.
$$

For a homogeneous vector,

$$
  r_0(M,x)=
  \frac{\lVert Mx\rVert_2}
  {\max\{1,\lVert M\rVert_2\lVert x\rVert_2\}}.
$$

Use

$$
  s_{\min}^{\mathrm{rel}}(M)=
  \frac{\sigma_{\min}(M)}{\max\{1,\lVert M\rVert_2\}},
  \qquad
  \tau_{\mathrm{rank}}(M)=10^{-10}\max\{1,\lVert M\rVert_2\}.
$$

Numerical nullity counts singular values not exceeding $\tau_{\mathrm{rank}}$. The tall
stack

$$
  V_c=\begin{bmatrix}A_c\\\mathcal E_L\\\mathcal E_R\end{bmatrix}
$$

uses its singular values and numerical rank, never rcond.

| Gate | Threshold |
|---|---|
| manufactured equality and residual | at most 1e-11 |
| actual BIE raw-versus-reduced Schur equality | at most 1e-10 |
| incident-trace check | at most 1e-12 |
| BIE solve residual | at most 1e-10 |
| center and lead BIE reciprocal condition estimate | at least 1e-2 |
| other square elimination-factor reciprocal condition estimate | at least 1e-10 |
| minimum $|\gamma_m|$ | at least 0.1 |
| A1 second-smallest normalized singular value | greater than 1e-4 |
| A1 density, center, and far participation | each greater than 1e-4 |
| wrong order or sign residual | greater than 1e-4 |
| A2 raw-scaling mutation | greater than 1e-3 |
| relative noncommutator | greater than 1e-3 |
| each allowed adjacent-level block error | at most 1e-13 |
| forbidden adjacent-level norm divided by $\max\{1,\lVert\Delta F\rVert_F\}$ | at most 1e-14 |

For a unit augmented direction, record

$$
\begin{aligned}
  \pi_\xi&=\lVert\xi\rVert_2,\\
  \pi_c&=\lVert(a_c^-,b_c^+,b_c^-,a_c^+)\rVert_2,\\
  \pi_f&=\lVert(a_f^-,b_f^-,b_f^+,a_f^+)\rVert_2.
\end{aligned}
$$

These are hard gates only for A1. They are diagnostics in smoke B.

## Pole ledger and layered availability

The ledger records size, reciprocal condition estimate when square, solve residual,
threshold, status, and downstream availability for:

- the non-Wood gate;
- center and lead BIE matrices;
- every Stage 1 doubling factor $G_A=I-R_R^AR_L^B$ and
  $G_B=I-R_L^BR_R^A$;
- the center multi-right-hand-side solve;
- the far blocks

  $$
  \mathcal B_{f,-,j}=
  \begin{bmatrix}-R_{L,j}^-&I\\I&I\end{bmatrix},
  \qquad
  \mathcal B_{f,+,j}=
  \begin{bmatrix}-R_{R,j}^+&I\\I&I\end{bmatrix},
  $$

  with variable orders $(a_f^-,b_f^-)$ and $(b_f^+,a_f^+)$;
- terminal factors $I+R_{L,j}^-$ and $I+R_{R,j}^+$;
- the raw eliminated block $K_{ee}$;
- the $D_h$ fingerprint and singular spectrum of $V_c$.

No failed solve is repaired by a pseudoinverse, regularization, or changed threshold.

Availability has three layers:

1. If primitive blocks are finite and their dimensions, order, phase, and scaling
   fingerprint agree, preserve the raw augmented matrix even when $A_c$, a far block, or
   $K_{ee}$ is singular.
2. Center scattering, terminated maps, the reduced matrix, and raw Schur equivalence exist
   only when their own factors pass. Write NaN only for an undefined derived quantity; do
   not erase primitive blocks or the raw matrix.
3. A discrete algebra pass still does not make physical root interpretation available.

Every row stores primary_failure_reason, the first failed gate in documented order, and
all_failure_reasons, every failed stable label in deterministic semicolon-separated order.
A downstream availability label never replaces its upstream cause.

Stable labels are WOOD_POINT, LEAD_BIE_POLE, CENTER_BIE_POLE, DOUBLING_POLE,
TERMINAL_RESONANCE, RAW_SCHUR_POLE, ZERO_FIELD_REPRESENTATION,
SCALING_COORDINATE_MISMATCH, DIMENSION_OR_FINGERPRINT_MISMATCH,
BLOCK_ORDER_OR_SIGN_MISMATCH, REDUCED_CROSSCHECK_UNAVAILABLE, and
UNQUALIFIED_SINGULAR_CANDIDATE.

## Mandatory falsification cases

| Case | Construction | Required outcome |
|---|---|---|
| Wood | Stage 1 Case B with $k=0.20$ | WOOD_POINT; no invalid BIE or lead map |
| doubling pole | $R_R^A=I$ and $R_L^B=I$ | DOUBLING_POLE; later lead levels unavailable |
| center pole with visible density | $A_c=\operatorname{diag}(1,1,1,0)$ and $[\mathcal E_L;\mathcal E_R]=I_4$ | CENTER_BIE_POLE; $V_c$ full column rank; raw matrix retained, derived center and reduced quantities unavailable |
| zero-field representation | same $A_c$, $\mathcal E_L=[I\;0]$, $\mathcal E_R=[0\;0\;1\;0;0\;0\;0\;0]$ | ZERO_FIELD_REPRESENTATION; fourth density coordinate is a density-only augmented nullvector |
| left terminal pole | $R_L^-=-I$ | TERMINAL_RESONANCE; raw matrix retained, left termination and reduced checks unavailable |
| right terminal pole | $R_R^+=-I$ | same on the right |
| wrong direct phase | diagonal $E_c$ or changed cross sign | BLOCK_ORDER_OR_SIGN_MISMATCH |
| wrong reduced order | $I-S_cR_j^{\mathrm D}$ | known-vector rejection |
| wrong terminal or side role | terminal minus sign, literal simultaneous $T_{LR}\leftrightarrow T_{RL}$ replacement in both rows of a chosen lead, or side swap | BLOCK_ORDER_OR_SIGN_MISMATCH |
| wrong scaling | A2 with unscaled right-hand sides and extractors | SCALING_COORDINATE_MISMATCH |
| changed level representation | change $p$, order, phase origin, $D_h$, or padding | DIMENSION_OR_FINGERPRINT_MISMATCH |

The two center singularities are distinct. An $A_c$ pole need not be a zero-field
representation: the first null density is visible, whereas the second belongs to the
common kernel of $A_c$, $\mathcal E_L$, and $\mathcal E_R$.

## Evidence bundle

The Engineer owns test/aug-bie. Expected entry points are run_aug_bie_experiment.m and the
substantial function file aug_bie_experiment.m. The formal command is equivalent to:

    perl -e 'alarm shift; exec @ARGV' 1800 conda run -n octave octave --quiet --no-gui --eval "addpath('test/aug-bie'); results=run_aug_bie_experiment();"

The output directory test/aug-bie/output contains at least:

- config.txt with frozen parameters and source hashes;
- levels.csv with dimensions, fingerprints, direct differences, and availability;
- algebra.csv with A1, A2, phase, sign, and Schur metrics;
- kernel.csv with singular values, nullities, lifted directions, and participation;
- pole-ledger.csv and representation-ledger.csv;
- negative-cases.csv;
- results.mat with primitive blocks, raw matrices, available derived matrices, and all
  report metrics;
- assembly.svg;
- run.log, report.md, and reproducibility.txt.

Every negative and failed smoke row remains in the report. No level may be deleted or
rerun with altered settings. Reproducibility compares a frozen vector under identical
source hashes.

## Decision and claim boundary

Stage 2 is GO only if A1, A2, all shared gates and negatives, and actual smoke B pass; all
$j=0,\ldots,6$ matrices have dimension 240; the adjacent-level difference has exactly the
frozen support; and the second Skeptic review accepts the evidence.

It is REVISE if exact algebra passes but BIE integration, coordinate consistency, evidence
completeness, or a non-authoritative numerical threshold fails without contradicting the
governing formulation. It is STOP if the governing order, direct phase, density coordinate,
manufactured equivalence, or raw-versus-derived availability distinction cannot be
implemented as frozen.

A Stage 2 GO licenses only:

- STAGE2_DISCRETE_ALGEBRA_GO;
- integration of the named interfaces in one fixed density and port coordinate;
- the prescribed raw matrix dimension and adjacent-level support;
- conditional discrete algebraic equivalence at points where all factors pass;
- the label UNSCREENED_CENTER_BIE_INTERFACE_SMOKE.

It does not license a physical guided eigenvalue or resonance, a root at $k=0.10$,
physical multiplicity, absence of spurious roots, continuous BIE kernel--field
equivalence, exact half-guide truth, a validated gap, an estimator, effectivity, or a
publishable benchmark.

The output field root_ready is frozen to STOP. It may change only after a separate accepted
kernel--field bridge and pole-free search-domain argument. A small singular value cannot
substitute for that gate.
