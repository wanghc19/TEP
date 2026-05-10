# quad_note.md

Purpose: concise implementation notes for the Kress quadrature/Nyström discretization used in Section 6.2–6.3 of Hao–Barnett–Martinsson–Young, together with the simplest test problem in Section 7.1.

## 1. General second-kind periodic integral equation

We start from

\[
\sigma(x) + \int_0^T k(x,x')\,\sigma(x')\,dx' = f(x), \qquad x\in[0,T].
\]

Given quadrature nodes \(\{x_j\}_{j=1}^N\), Nyström discretization enforces the equation at the same target nodes:

\[
\sigma(x_i) + \sum_{j=1}^N a_{ij}\,\sigma(x_j) = f(x_i), \qquad i=1,\dots,N.
\]

In matrix form,

\[
(I + A)\,\sigma = f.
\]

For the Kress scheme, the kernel must be split explicitly as

\[
k(t,s) = \phi(t,s)\,\log\!\Bigl(4\sin^2\frac{t-s}{2}\Bigr) + \psi(t,s),
\]

with smooth \(2\pi\)-periodic functions \(\phi\) and \(\psi\).

## 2. Kress setup (Section 6.1–6.3)

Use the paper's normalization:

- period \(T = 2\pi\)
- \(N\) must be **even**
- periodic trapezoid nodes
  \[
  x_j = \frac{2\pi j}{N}, \qquad j=1,\dots,N,
  \]
- mesh size
  \[
  h = \frac{2\pi}{N}.
  \]

### 2.1 Product quadrature idea

For a smooth periodic function \(f\) and a fixed singular periodic factor \(g\), Kress uses a product quadrature

\[
\int_0^{2\pi} f(s) g(s)\,ds \approx \sum_{j=1}^N w_j f(x_j).
\]

The special singular factor is

\[
g(s) = \log\!\Bigl(4\sin^2\frac{s}{2}\Bigr),
\]

whose Fourier coefficients are

\[
g_0 = 0, \qquad g_n = -\frac{1}{|n|} \quad (n\neq 0).
\]

After translating by the target location \(t\), the Kress weights become

\[
R_j^{(N/2)}(t)
= -\frac{4\pi}{N}
\left[
\sum_{n=1}^{N/2-1} \frac{1}{n}\cos\bigl(n(x_j-t)\bigr)
+ \frac{1}{N}\cos\Bigl(\frac{N}{2}(x_j-t)\Bigr)
\right].
\]

Then

\[
\int_0^{2\pi}
\log\!\Bigl(4\sin^2\frac{t-s}{2}\Bigr)\,\phi(s)
\,ds
\approx
\sum_{j=1}^N R_j^{(N/2)}(t)\,\phi(x_j).
\]

If a smooth term is present too, use ordinary periodic trapezoid for it:

\[
\int_0^{2\pi}
\Bigl[
\log\!\Bigl(4\sin^2\frac{t-s}{2}\Bigr)\,\phi(s) + \psi(s)
\Bigr] ds
\approx
\sum_{j=1}^N R_j^{(N/2)}(t)\,\phi(x_j)
+
\frac{2\pi}{N}\sum_{j=1}^N \psi(x_j).
\]

## 3. Nyström matrix for Kress

Apply the above to the kernel split

\[
k(x_i,x_j)=\phi(x_i,x_j)\log\!\Bigl(4\sin^2\frac{x_i-x_j}{2}\Bigr)+\psi(x_i,x_j).
\]

The Kress Nyström entries are

\[
a_{ij} = R_{|i-j|}^{(N/2)}\,\phi(x_i,x_j) + h\,\psi(x_i,x_j),
\]

where \(R_{|i-j|}^{(N/2)}\) is the circulant weight coming from the target-dependent formula above.

A practical offset form is the following. For an offset

\[
m = j-i \pmod N, \qquad m\in\{0,1,\dots,N-1\},
\]

define

\[
r_m = -\frac{4\pi}{N}
\left[
\sum_{n=1}^{N/2-1} \frac{1}{n}\cos\Bigl(\frac{2\pi n m}{N}\Bigr)
+ \frac{1}{N}\cos(\pi m)
\right].
\]

Then the dense circulant matrix \(R\) satisfies

\[
R_{ij} = r_{(j-i)\bmod N}.
\]

Finally,

\[
A = R \odot \Phi + h\,\Psi,
\]

where \(\Phi_{ij}=\phi(x_i,x_j)\), \(\Psi_{ij}=\psi(x_i,x_j)\), and \(\odot\) is entrywise multiplication.

Solve

\[
(I+A)u = f.
\]

## 4. Simplest test problem: Section 7.1

The test equation is

\[
u(x) + \int_0^{2\pi} k(x,x')u(x')\,dx' = f(x), \qquad x\in[0,2\pi].
\]

Use

\[
k(x,x') = \frac12 \log\left|\sin\frac{x-x'}{2}\right|.
\]

Rewrite it in Kress form:

\[
k(x,x')
= \frac14\log\!\Bigl(4\sin^2\frac{x-x'}{2}\Bigr)
- \frac12\log 2.
\]

Therefore

\[
\phi(x,x') = \frac14,
\qquad
\psi(x,x') = -\frac12\log 2.
\]

Right-hand side:

\[
f(x) = \sin(3x)\,e^{\cos(5x)}.
\]

The paper notes:

- this kernel is analogous to the Laplace single-layer operator on the unit circle,
- exact eigenvalues of the integral operator are
  \[
  \lambda_0 = -\pi\log 2,
  \qquad
  \lambda_{\pm n} = -\frac{\pi}{2n}, \quad n\ge 1,
  \]
- the exact condition number is about \(5.5\),
- \(\|u\|_\infty \approx 6.1\),
- errors in the paper are estimated against a Kress solution at \(N=2560\).

## 5. Practical implementation recipe for Section 7.1

Because \(\phi\) and \(\psi\) are constants here, assembly is especially simple.

### 5.1 Build the Kress weight vector

For each even \(N\):

1. set \(h = 2\pi/N\),
2. for offsets \(m=0,1,\dots,N-1\), compute
   \[
   r_m = -\frac{4\pi}{N}
   \left[
   \sum_{n=1}^{N/2-1} \frac{1}{n}\cos\Bigl(\frac{2\pi n m}{N}\Bigr)
   + \frac{1}{N}\cos(\pi m)
   \right],
   \]
3. make the dense circulant matrix \(R\) from \(r_m\).

### 5.2 Assemble the Nyström matrix

Since \(\phi=1/4\) and \(\psi=-\frac12\log 2\),

\[
A = \frac14 R - \frac{h\log 2}{2}\,\mathbf{1}\mathbf{1}^T.
\]

Then solve

\[
(I+A)u = f.
\]

### 5.3 Convergence experiment matching Section 7.1

Suggested node counts:

\[
N = 20,40,80,160,320,640,1280.
\]

Reference solution:

- compute a fine Kress solution at \(N_{\rm ref}=2560\),
- since every coarse \(N\) divides 2560, the coarse trapezoid nodes are a subset of the fine grid,
- compare \(u_N\) with the sampled fine-grid solution using stride
  \[
  \texttt{stride} = N_{\rm ref}/N.
  \]

Recommended relative infinity error:

\[
\frac{\|u_N - u_{\rm ref}|\_\infty}{\|u_{\rm ref}|\_\infty},
\]

where both vectors are evaluated on the same coarse node set.

This is the easiest way to reproduce the Section 7.1 convergence behavior without needing the exact Fourier-series solution.

## 6. Coding tips for Codex

- MATLAB is enough; no special toolbox is needed.
- Keep \(N\) even.
- Do **not** evaluate the kernel directly on the diagonal; the diagonal singularity is already handled by Kress through \(R\).
- For this test, avoid over-generalizing too early: first get the constant-\(\phi\), constant-\(\psi\) case working.
- A good minimal file structure is:
  - `quad_demo_7_1_kress.m`
  - local helper `quad_kress_rvec(N)` returning the first row of the circulant Kress matrix.
- Print a small convergence table and generate one log-log plot.
- Since this is only the first quadrature test, dense assembly and MATLAB backslash are completely fine.
