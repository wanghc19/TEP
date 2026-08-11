# DLP action and derivative derivation

Let $G(x_t,x_s)$ denote the qualified quasi-periodic Green function. The
outward source normal on the circle is $n_s=(n_{sx},n_{sy})$, while the wall
target normal is $n_t=(n_{tx},0)$ with $n_{tx}=-1$ on the left and $+1$ on the
right. Because source differentiation is the negative of target separation
differentiation,

$$
G_{n_s}=-(G_x n_{sx}+G_y n_{sy}).
$$

Differentiating this field in the wall normal gives

$$
G_{n_tn_s}=n_{tx}(-G_{xx}n_{sx}-G_{xy}n_{sy}).
$$

With the existing augmented-density convention $\eta=[\rho;0]$, the DLP
Dirichlet action is the quadrature of $G_{n_s}\rho$ and the DLP Neumann action
is the quadrature of $G_{n_tn_s}\rho$. The SLP actions cached for trace
certification remain $-G\rho$ and $-G_{n_t}\rho$.

For each wall Fourier coefficient, the direct Rayleigh extractor supplies the
DLP Dirichlet coefficient $D_m$. The raw Neumann coefficient is

$$
N_m=\mathrm{i}\gamma_m D_m
$$

on both walls under the frozen outgoing branch. It is never divided by
$\gamma_m$ for a scientific gate.

Pilot controls independently check source/target signs, transverse parity,
value-only centered finite differences, a nonmirror point, mixed-Hessian
symmetry, and the public-solution rank diagnostics. Ewald derivatives are
obtained by analytic differentiation of the already qualified Linton split;
package derivatives are not used to certify them.
