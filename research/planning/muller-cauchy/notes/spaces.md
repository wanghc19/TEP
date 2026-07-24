# Function spaces

## Goal

Supply the minimum functional framework for L1, L2, L6 and L14. This note is normative for the roadmap: later informal coefficient vectors must be interpreted through these spaces.

## Quasiperiodic Sobolev spaces

For an axial period `L` and real `\beta`,

\[
H^s_\beta(0,L)=\{u=e^{i\beta x}v:\ v\in H^s_{\rm per}(0,L)\},\qquad
\|u\|_{H^s_\beta}:=\|e^{-i\beta x}u\|_{H^s_{\rm per}}.
\]

If `u(x)=\sum_m u_m e^{i(\beta+2\pi m/L)x}`, an equivalent norm is

\[
\|u\|_{H^s_\beta}^2\asymp
\sum_{m\in\mathbb Z}\langle\beta+2\pi m/L\rangle^{2s}|u_m|^2.
\]

The dual of `H^{1/2}_\beta` under the periodic anti-duality pairing is `H^{-1/2}_\beta` (with conjugation convention fixed in the final proof).

## Trace graph spaces

`\gamma_D:H^1(\Omega)\to H^{1/2}(\partial\Omega)` is bounded. A weak Neumann/conormal trace requires a PDE graph condition. For

\[
H^1_L(\Omega)=\{u\in H^1(\Omega):Lu\in L^2(\Omega)\},
\]

define `\gamma_Nu\in H^{-1/2}` by Green's identity against a bounded lifting. This is independent of the lifting because the weak PDE is known. On a port in a homogeneous neighborhood, the definition is unambiguous and agrees with the classical normal derivative for smooth fields.

## Layer and modal products

The center density product is

\[
\mathcal H_{\partial\Omega_0}
=H^{1/2}(\partial\Omega_0)\times H^{-1/2}(\partial\Omega_0).
\]

For port Fourier data use `h^s_\beta` with the same weighted norm as above. A Dirichlet series belongs to `h^{1/2}_\beta`; applying a modal normal derivative changes its natural target to `h^{-1/2}_\beta`. Near a Wood value, the multiplier is not uniformly invertible, which is why A8 is structural.

## Quotients

For a closed representation nullspace `\mathcal N`,

\[
\|[x]\|_{\mathcal X/\mathcal N}=\inf_{n\in\mathcal N}\|x+n\|_{\mathcal X}.
\]

All “spurious-free” statements are about classes unless injectivity has been proved. A convenient side constraint is legitimate only if it defines a bounded complement of `\mathcal N`.

## Checks before proof

1. Fix linear-versus-antilinear duality conventions.
2. Verify all port normals and TM conormal weights.
3. Prove the stable synthesis maps into both trace factors.
4. Check every block for derivative loss; never infer boundedness from a matrix-looking formula.

