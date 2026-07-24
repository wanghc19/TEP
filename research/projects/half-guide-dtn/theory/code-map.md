# Current Code Inventory

This note records the initial source-code inventory for the DtN attempt. It is
based on direct inspection of the current repository and should be extended as
more files are read.

## Repository State

- Repository root: `/Users/whc/Documents/Work/TEP`.
- Requested local documents were found under repository paths, not `/mnt/data`:
  - `pdf/Joly2006.pdf`
  - `pdf/Coatleven2012.pdf`
  - `pdf/Barnett2010.pdf`
  - `pdf/Luan2019.pdf`
  - `pdf/Linton1998.pdf`
  - `notes/theory/scat_formulation.md`
  - `notes/theory/scat_formulation2.md`
  - `pre/pre1/pre1.pdf`
  - `pre/pre2/pre2.pdf`
  - `pre/pre3/pre3.pdf`
  - `pdf/report_legacy.pdf`
- There are pre-existing modified/untracked files outside `attempt/`. This
  attempt treats them as user work and does not modify them.

## Rayleigh Channel Ordering

Inspected file: `+bloch/rayleigh_channels.m`.

- Fourier/Rayleigh modes are ordered by
  \[
    m=-M,\ldots,M,\qquad K=2M+1.
  \]
- The transverse quasi-periodic frequencies are
  \[
    \beta_m=\beta+\frac{2\pi m}{d}.
  \]
- The open-direction square-root branch is
  \[
    \gamma_m=\sqrt{k^2-\beta_m^2},\qquad \operatorname{Im}\gamma_m\ge 0.
  \]
- The one-cell phase used by scattering code is
  \[
    E_m=\exp(i\gamma_m L).
  \]

## Single-Cell Scattering Matrix

Inspected file: `+bloch/construct_S.m`.

The code defines incoming and outgoing Rayleigh amplitudes on a single lead cell
as

\[
  \begin{bmatrix} b^L \\ a^R \end{bmatrix}
  =
  \begin{bmatrix} R_L & T_{RL} \\ T_{LR} & R_R \end{bmatrix}
  \begin{bmatrix} a^L \\ b^R \end{bmatrix}.
\]

Here \(a\) denotes right-going Rayleigh amplitudes and \(b\) denotes left-going
Rayleigh amplitudes. The superscripts \(L,R\) mean left/right wall of one cell,
not the negative/positive half-leads.

The matrix is assembled by solving

\[
  A_{\mathrm{QP}}H_L=-B_L,\qquad A_{\mathrm{QP}}H_R=-B_R,
\]

and extracting scattered coefficients using \(F_L,F_R\). The direct propagation
phase \(E=\operatorname{diag}(\exp(i\gamma_m L))\) is added only to the
transmission blocks.

## Bloch Generalized Eigenproblem

Inspected files:

- `+bloch/solve_modes.m`
- `+bloch/mode_traces.m`

The generalized eigenproblem is

\[
  A_{\mathrm{sc}}\begin{bmatrix}a\\b\end{bmatrix}
  =
  \lambda
  B_{\mathrm{sc}}\begin{bmatrix}a\\b\end{bmatrix},
\]

with

\[
  A_{\mathrm{sc}}=
  \begin{bmatrix}
    -R_L & I\\
     T_{LR} & 0
  \end{bmatrix},
  \qquad
  B_{\mathrm{sc}}=
  \begin{bmatrix}
    0 & T_{RL}\\
    I & -R_R
  \end{bmatrix}.
\]

The eigenvector ordering is

\[
  V_j=\begin{bmatrix}a_L^{(j)}\\ b_L^{(j)}\end{bmatrix}.
\]

The Bloch condition from the left wall to the right wall is

\[
  a_R^{(j)}=\lambda_j a_L^{(j)},\qquad
  b_R^{(j)}=\lambda_j b_L^{(j)}.
\]

The trace coefficients computed by `mode_traces` are x-derivative traces,
not half-lead outward normal traces:

\[
  D_L=a_L+b_L,\qquad
  N_L=\partial_x u|_L=i\Gamma(a_L-b_L),
\]

\[
  D_R=a_R+b_R,\qquad
  N_R=\partial_x u|_R=i\Gamma(a_R-b_R).
\]

## Outgoing Port Selection

Inspected file: `+bloch/select_port_traces.m`.

For the positive/right center port:

\[
  |\lambda|<1,\qquad D_{\mathrm{out}}^+=D_L,\qquad
  N_{\mathrm{out}}^+=N_L.
\]

For the negative/left center port:

\[
  |\lambda|>1,\qquad D_{\mathrm{out}}^-=D_R,\qquad
  N_{\mathrm{out}}^-=-N_R.
\]

The minus sign converts the x-derivative at a cell right wall to the center
left-port outward normal derivative \(N^-=-\partial_xu\).

## Current Trace-Matching Matrix

Inspected files:

- `scat_ld_lead_in.m`
- `tep_edc_scan_local.m`
- `notes/theory/scat_formulation.md`
- `notes/theory/scat_formulation2.md`

The empty-defect center cell uses unknown center Rayleigh amplitudes
\((a,b)\) and outgoing lead coefficients \((r^-,r^+)\). With

\[
  E=\operatorname{diag}(\exp(i\gamma_mL_0)),\qquad
  \Gamma=\operatorname{diag}(\gamma_m),
\]

the homogeneous trace matching matrix is

\[
\begin{bmatrix}
I & I & -D_{\mathrm{out}}^- & 0\\
-i\Gamma & i\Gamma & -N_{\mathrm{out}}^- & 0\\
E & E^{-1} & 0 & -D_{\mathrm{out}}^+\\
i\Gamma E & -i\Gamma E^{-1} & 0 & -N_{\mathrm{out}}^+
\end{bmatrix}.
\]

For a center cell with an obstacle, `scat_ld_lead_in.m` assembles a larger
matrix with unknown

\[
  [\eta;\ c^+;\ c^-;\ a_s^-;\ a_s^+],
\]

where \(\eta=[\tau;-\sigma]\) is the Muller density and \(c^\pm\) are
homogeneous center Rayleigh coefficients. The BIE row is

\[
  A_{\mathrm{QP}}\eta+H^+c^+ + H^-c^-.
\]

The port rows use the same outward-normal convention:

\[
  N^-=-\partial_xu|_{\Gamma^-},\qquad
  N^+=+\partial_xu|_{\Gamma^+}.
\]

## Muller Matrix

Inspected file: `+op/construct_A_QP.m`.

The unknown is

\[
  \eta=\begin{bmatrix}\tau\\-\sigma\end{bmatrix}.
\]

The assembled operator is documented as

\[
A_{\mathrm{QP}}
=I+
\begin{bmatrix}
D_{\mathrm{QP}}^{(k_{\rm ext})}-D^{(k_{\rm int})}
&
S^{(k_{\rm int})}-S_{\mathrm{QP}}^{(k_{\rm ext})}
\\
T_{\mathrm{QP}}^{(k_{\rm ext})}-T^{(k_{\rm int})}
&
D^{(k_{\rm int}),*}-D_{\mathrm{QP}}^{(k_{\rm ext}),*}
\end{bmatrix}.
\]

The file scales rows and columns by trapezoid/Kress weights after assembly.

## First DtN Implication

The existing port trace selection produces an outgoing graph

\[
  (D_{\mathrm{out}}^\pm,N_{\mathrm{out}}^\pm).
\]

The most direct DtN replacement would attempt to form

\[
  \Lambda^\pm \approx N_{\mathrm{out}}^\pm(D_{\mathrm{out}}^\pm)^{-1},
\]

but the code inventory already shows why this is risky:

- \(D_{\mathrm{out}}^\pm\) is not guaranteed square in all samples because
  mode counts can be bad near neutral modes or truncation failures.
- Even when square, it may be ill-conditioned or singular.
- Forming this quotient would still rely on the outgoing Bloch trace basis,
  so it is better viewed as a diagnostic bridge than as a true replacement.

