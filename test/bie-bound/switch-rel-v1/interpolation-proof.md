# Kernel interpolation enclosure

This is the inline derivation supporting `reliable_switch.py`, expanded here for checking. It uses no external literature. Arb means arbitrary-precision ball arithmetic. Task mode: Proof from scratch. Target: the kernel interpolation remainder in this experiment.

Let $f$ be any one of the six jump components (three components at each of the two cuts). On a real panel $[c-a,c+a]$, assume that $f(c+at)$ is analytic on and inside the Bernstein ellipse with parameter $\rho>1$ and has modulus at most $M$ there. Let $I_nf$ interpolate at the $n$ zeros of $T_n$.

**Proof.** Set $F(w)=f(c+a(w+w^{-1})/2)$. It is analytic in $\rho^{-1}<|w|<\rho$ and satisfies $F(w)=F(w^{-1})$. Its Laurent coefficients on $|w|=\rho$ are bounded by $M\rho^{-k}$, directly by the contour coefficient formula. Pairing coefficients with exponents $k$ and $-k$ gives Chebyshev coefficients bounded by $2M\rho^{-k}$ for $k\ge1$. At the zeros of $T_n$, every $T_k$ aliases to zero or to $\pm T_j$ for some $0\le j<n$. Thus $\|I_nT_k\|_{[-1,1]}\le1$, while $\|T_k\|\le1$. The terms of degree below $n$ interpolate exactly, so absolute convergence of the series gives
$$
\|f-I_nf\|\le 4M\sum_{k=n}^\infty\rho^{-k}
=\frac{4M\rho^{1-n}}{\rho-1}.
$$
The discrete cosine formulas evaluated in Arb enclose the exact interpolant coefficients; their numerical errors need no separate estimate. Adding the displayed remainder to both real and imaginary radii encloses the complex approximation error. $\square$

Here $\rho=4$, $n=40$, $a=7/512$ and 64 panels cover $[-7/8,7/8]$. A rectangle with both halfwidths $a(\rho+\rho^{-1})/2$ contains the closed ellipse. Each source/proxy term is evaluated on that complex rectangle. The code verifies $\operatorname{Re}((X-Z_x)^2+(Y-Z_y)^2)>0$ for every term, so the principal square root is analytic and its image, multiplied by positive $k$, avoids the Hankel branch cut. Summing the individual term modulus bounds gives $M$ without relying on cancellation. The same formulas apply to the first derivatives.

For a source-angle panel with midpoint $t$ and halfwidth $h$, a fixed trigonometric polynomial $v(\theta)=\sum_m c_m e^{im\theta}$ obeys
$$
|v(\theta)-v(t)|\le h\sum_m |m c_m|.
$$
This follows by integrating its derivative along the real angle interval. The implementation evaluates the midpoint by a direct Arb Fourier dot product and adds this bound. Curve positions use midpoint Taylor expansions with $\frac12h^2\sum m^2|c_m|$ remainder; their derivatives use $h\sum m^2|c_m|$. All coefficients and remainders are balls.

The source integral uses panel supremum times parameter-panel length, including the speed bound. The refined line integral uses a uniform Y-cell enclosure of $\overline{g_i}g_j$; cells covering the entire translated segment are summed. Extending that segment is safe because the combined squared integrand is nonnegative. The moment identity used is
$$
\int (|A_0|^2+|A_1|^2+|J_0|^2)
= a|\tau|^2+b|\zeta|^2+2\operatorname{Re}(c\overline\tau\zeta),
$$
where $H_{ij}=\int\overline{g_i}g_j$, $(g_0,g_1,g_2)=(g_0,g_x,g_y)$ and
$$
a=\mu^2 n_y^2 H_{00}+H_{11}+H_{22},\quad b=H_{00}+H_{22},\quad
c=-\mu n_y H_{02}+n_xH_{10}+n_yH_{20}.
$$
Expanding the three squares proves this identity; the cancellation in $a$ uses $n_x^2+n_y^2=1$. For leads, $|\tau|^2$, $|\zeta|^2$ and $\overline\tau\zeta$ are summed over cells before taking a square root. The endpoint expression uses $|n_y g_x-n_xg_y|\,|\tau|$ at both ends.

If $T=\sum_m\|\tau_m\|_2$ and $Z=\sum_m\|\zeta_m\|_2$ bound the two density row maps, and $G_j$ are global jump suprema, then the squared Hilbert--Schmidt norm of the line map is bounded by
$$
\Theta\le2[(\mu^2G_0^2+G_1^2+G_2^2)T^2+(G_0^2+G_2^2)Z^2].
$$
This is the two-term Cauchy--Schwarz bound applied to the vector of three residual components on a segment of length one. The endpoint row-norm sum is at most $2(G_1+G_2)T$. Multiplying by a reliable curve-length bound gives the source integrals of $\sqrt\Theta$ and $B_{\rm end}$. These bounds enter SW26 and SW27; the finite 40-cell part uses exact-input ball powers $P^jc$.

The stored binary64 phase has a small modulus defect. Both cut orientations are evaluated separately. To cover the exact $e^{i\beta d}$ convention as well, each component receives $|q_{\rm exact}-q_{\rm stored}|$ times a branch envelope. Thus the reported switch bound covers both choices; the full residual still needs its own seam and volume accounting.

Result: the interpolation and integration upper bounds follow under the analytic-rectangle checks executed by the code. The application to the residual uses Theorem SW and Proposition EP with their stated operator and field hypotheses. Proof literature verification completed. No external reference is required by the derivation above.
