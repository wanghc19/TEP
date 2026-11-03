# Problem statement: truncation-reliable bounds for the Goerisch quantities $q$, $J$

> 给用户的说明（中文）：本文件是发给外部证明模型（ChatGPT Pro）的独立任务说明，正文用英文。它把"给 $q$、$J$ 的求积、曲边映射和归一化加上截断误差意义下可靠的一侧界"整理成可证明的问题，包含全部背景，不需要访问仓库。证明返回后存为同目录下的 `qj-bounds-proof.md`，由研究经理核查后再送审稿线程。文中的数字来自 `test/numerical-directions/gap-ends-v1/`（2026-11-03），代码事实来自 `test/numerical-directions/fem-pipeline-v1/`。标注 "to be confirmed" 的代码事实由研究经理核对，不由证明者负责。

## 0. What we ask from you

We compute a guided-mode eigenvalue $\lambda$ of a 2D periodic waveguide by a Lehmann–Goerisch enclosure built from a finite element trial function $v$ and a Raviart–Thomas flux $p$. The enclosure formula (Section 2, already proved and reviewed) needs three numbers: an energy $E$, a mass $M$, and a nonnegative residual integral $S$. They are currently computed by ordinary Gauss quadrature, with no remainder bound. **Your task is to turn this into a theorem: give computable, explicit bounds on $E$, $M$, $S$ (two-sided for $E$, $M$; upper for $S$), valid in exact real arithmetic, and assemble them into an interval that provably contains $\lambda$ under the stated assumptions.**

"Truncation-reliable" means: every error source except floating-point rounding is bounded rigorously (quadrature remainders, geometry of curved elements, material interface location, normalization). Rounding is out of scope; it will be handled later by interval arithmetic. You may therefore treat Gauss nodes/weights and all evaluations as exact real numbers, but every bound must be computable by a finite procedure from data the code has (mesh, coefficients, curve formulas).

Deliver one Markdown file (math in `$...$` / `$$...$$`) with:

1. Precise statements (theorem / lemma / proposition) and complete proofs. Every constant explicit and computable; say exactly what the code must compute for each.
2. A final table: quantity, bound used, how computed, expected size relative to the targets in Section 5.
3. A list of every assumption used, separated into (a) mathematical assumptions, (b) facts about the discrete construction that the code must satisfy.
4. Where a construction choice makes rigorous bounds hard (Section 4.6 lists the ones we know), you may propose a modified construction that keeps $v\in V$ and $p$ admissible, with an argument why it does not degrade the enclosure noticeably. Mark such proposals clearly as design changes.

Out of scope (do not work on these): the spectral isolation assumption (H) and the certification of $\alpha_\pm$; errors of the DtN maps (they only influence how $v$ was obtained, not the validity of the enclosure); floating-point rounding; choosing a better candidate or flux.

Write plainly. State results at the strength you can prove; if a part cannot be closed, say exactly which step fails and what extra hypothesis would close it.

## 1. Model

- Strip $B=\mathbb R\times(-\tfrac12,\tfrac12)$; quasi-periodicity phase $\beta_0=0.5$ in $y$ (period 1).
- Cells $C_n=[n-\tfrac12,n+\tfrac12]\times(-\tfrac12,\tfrac12)$, $n\in\mathbb Z$. Each cell contains one inclusion $\Omega_n$ centered at $(n,0)$; the material is $\rho=\rho_n^{\rm in}$ in $\Omega_n$ and $\rho=1$ elsewhere.
  - Center cell $n=0$: star, boundary $c_0(\theta)=0.2\,\big((1.5+0.3\cos5\theta)\cos\theta,\ (1+0.3\cos5\theta)\sin\theta\big)$, $\theta\in[0,2\pi)$; $\rho_0^{\rm in}=4$.
  - Lead cells $n\ne0$: trefoil in polar form $r(\theta)=R_a(1+a\cos3\theta)$, $R_a=0.2/\sqrt{1+a^2/2}$, with $a=0.12$ for $n<0$ and $a=0.20$ for $n>0$; $\rho_n^{\rm in}=17$.
  - So $1\le\rho\le17$, piecewise constant, discontinuous across analytic closed curves.
- $V=H^1_{\beta_0}(B)$: $u\in H^1(B)$ with $u(\cdot,\tfrac12)=e^{\mathrm i\beta_0}u(\cdot,-\tfrac12)$.
- $a(u,\varphi)=\int_B\nabla u\cdot\overline{\nabla\varphi}$, $b(u,\varphi)=\int_B\rho u\bar\varphi$, $a_\gamma=a+\gamma b$, with $\gamma=1$ fixed.
- $A$ = the self-adjoint operator in $L^2_\rho(B)$ of the form $a$ on $V$ (that is, $-\rho^{-1}\Delta$ with the quasi-periodic condition). The target $\lambda\approx2.4287286700$ is an eigenvalue in a spectral gap.

## 2. The enclosure theorem (given; already proved and reviewed)

**Assumption (H).** $0\le\alpha_-<\alpha_+$, $\sigma(A)\cap(\alpha_-,\alpha_+)=\{\lambda\}$, $\lambda$ an eigenvalue of finite multiplicity. Current values: $\alpha_-=1.32^2$, $\alpha_+=2.37^2$. Write $\mu=\alpha_-+\gamma$, $\nu=\alpha_++\gamma$.

**Proposition 1** (Lehmann–Goerisch, $N=1$; Nakao–Plum–Watanabe 2019, Thm 10.29, applied with $H=V$, $\langle\cdot,\cdot\rangle=a_\gamma$, $B[\cdot,\cdot]=b$). Let $v\in V$ with $\|v\|_\rho=1$, $q=a_\gamma(v,v)$. Let $D=(-X,X)\times(-\tfrac12,\tfrac12)$ and $p\in H(\operatorname{div},D)$ with

- (P1) $p\cdot n\in L^2(\partial D)$;
- (P2) $p\cdot n=0$ on $x=\pm X$;
- (P3) $p_y(x,\tfrac12)=e^{\mathrm i\beta_0}p_y(x,-\tfrac12)$ a.e.

Extend $p$ by zero and let
$$J=\int_D|p|^2+\int_D\frac{|\operatorname{div}p+\rho v|^2}{\gamma\rho}+\frac1\gamma\int_{B\setminus D}\rho|v|^2 .$$
If (H) holds and the sign conditions

- (C) $\hat B_2(t):=q-2t+t^2J>0$ for $t=\mu,\nu$; $\hat\kappa(\mu)>1/(\nu-\mu)$; $\hat\kappa(\nu)<-1/(\nu-\mu)$, where $\hat\kappa(t)=(1-tJ)/\hat B_2(t)$,

hold, then
$$\lambda\in[E(\nu),E(\mu)],\qquad E(t)=\frac{q-t}{1-tJ}-\gamma .$$

The proof uses only: $v\in V$, admissibility $\int_D p\cdot\overline{\nabla\varphi}+(\operatorname{div}p)\bar\varphi=0$ for all $\varphi\in V$ (which follows from P1–P3), and (H). Equivalently, with $T\varphi=(\nabla\varphi,\varphi)$, $\hat w=(p,(\operatorname{div}p+\rho v)/(\gamma\rho))$ and $b_X((p,r),(p',r'))=\int p\cdot\overline{p'}+\gamma\rho r\overline{r'}$: $b_X(\hat w,T\varphi)=b(v,\varphi)$ for all $\varphi\in V$, and $J=b_X(\hat w,\hat w)$.

You may use Proposition 1 as given. You must handle that the code does not normalize $v$ exactly and does not compute $q$, $J$ exactly.

## 3. What the code computes now

### 3.1 Unnormalized quantities

The code works with an unnormalized $v\in V$ (Section 4) supported in $\overline D$, $D=(-13.5,13.5)\times(-\tfrac12,\tfrac12)$, so the exterior term in $J$ vanishes. It computes by quadrature

$$E=\int_D|\nabla v|^2,\qquad M=\int_D\rho|v|^2,\qquad q=1+\frac EM\quad(\gamma=1),$$

and, for a fixed real number $s>0$ (the code uses $s=$ its computed $q$),

$$S(s)=\int_D\Big|p-\frac{\nabla v}{s}\Big|^2+\int_D\frac{\big|\operatorname{div}p+\rho\,(1-\tfrac1s)\,v\big|^2}{\rho}=b_X\!\Big(\hat w-\frac{Tv}{s},\ \hat w-\frac{Tv}{s}\Big),$$

where here $\hat w=(p,(\operatorname{div}p+\rho v)/\rho)$ is formed with the unnormalized $v$, and admissibility reads $b_X(\hat w,T\varphi)=b(v,\varphi)$. The code then uses $\delta:=qJ-1$ with $\delta=q\,S(s)/M$ and the stable endpoint formulas
$$E(\nu)=q-\gamma+\frac{q\nu\delta}{q-\nu-\nu\delta},\qquad E(\mu)=q-\gamma+\frac{q\mu\delta}{q-\mu-\mu\delta}.$$

### 3.2 Manager's sketch of the reduction (to be checked and completed by you)

With exact admissibility, $b_X(\hat w,Tv)=b(v,v)=M$ and $b_X(Tv,Tv)=a_\gamma(v,v)=qM$. Expanding $S(s)$ gives, for the normalized $J$,
$$J=\frac{S(s)}M+\frac2s-\frac q{s^2},\qquad qJ-1=\frac{q\,S(s)}M-\frac{(q-s)^2}{s^2}\le\frac{q\,S(s)}M .$$
So an upper bound for $\delta$ needs only $q$ from above, $S(s)$ from above, $M$ from below, for any fixed $s$; there is no cancellation. Since $E(\nu)$ decreases and $E(\mu)$ increases in $\delta$, and both endpoints move with $q$ at rate about 1, we expect the reliable interval to be $[E_{\rm lo},E_{\rm hi}]$ with $E_{\rm lo}$ evaluated at $(q_{\rm lo},\delta_{\rm hi})$ and $E_{\rm hi}$ at $(q_{\rm hi},\delta_{\rm hi})$, where $q_{\rm lo}=1+E_{\rm lo}/M_{\rm hi}$, $q_{\rm hi}=1+E_{\rm hi}/M_{\rm lo}$, $\delta_{\rm hi}=q_{\rm hi}S_{\rm hi}/M_{\rm lo}$. **Prove or correct this**, including: the exact monotonicity region; how to verify (C) from the bounds; and whether a better combination exists (for example, one avoiding the loss from bounding $q$ and $\delta$ separately).

### 3.3 Current numbers (P3 field, RT3 flux, old endpoints $\alpha_\pm=1.3174^2,2.1875^2$)

| quantity | value |
|---|---|
| $M$ | $4.7230110180205935$ |
| $E$ | $11.470912271616058$ |
| $q$ | $3.428728670724867$ |
| $J$ | $0.291653290839882$ |
| $qJ-1$ via $S$ | $2.13952\times10^{-10}$ (gradient part $2.10551\times10^{-10}$, divergence part $3.401\times10^{-12}$) |
| $qJ-1$ via $q\cdot J$ directly | $2.13962\times10^{-10}$ |
| interval width, new endpoints $1.32^2,2.37^2$ | $4.454\times10^{-9}$ |
| change of $M$, $E$ from quadrature order 16 to 24 | $2.3\times10^{-15}$, $2.5\times10^{-15}$ relative |
| change of $qJ-1$ (via $S$) from order 16 to 24 | $1\times10^{-12}$ relative |

## 4. The discrete construction (exact definitions)

### 4.1 Native mesh and trial function $v$

- Each cell is meshed by 6-node (quadratic-geometry) triangles $K$ with map $F_K:\hat K\to K$, $\hat K=\{(\xi,\eta):\xi,\eta\ge0,\ \xi+\eta\le1\}$, $F_K$ a vector quadratic polynomial (the isoparametric $P_2$ map from the six nodes). The background mesh size is about $h=1/48$. Interface edges: the inclusion boundary is split into $N_\Gamma$ arcs of equal parameter length $\Delta\theta$; each arc $[\theta_j,\theta_j+\Delta\theta]$ is a curved mesh edge whose three nodes are $c(\theta_j)$, $c(\theta_j+\Delta\theta/2)$, $c(\theta_j+\Delta\theta)$ (exact curve points), so the native curved edge is the quadratic interpolant of the true curve and differs from it by $O(\Delta\theta^3)$. To be confirmed: triangles with no interface edge are affine (straight edges, midside nodes at edge midpoints).
- Field: on each native triangle $u_h|_K=\hat u_K\circ F_K^{-1}$ with $\hat u_K$ a cubic polynomial (degree 3 Lagrange on $\hat K$, field degree 3, geometry degree 2). $u_h$ is globally continuous: interior nodal values are shared, nodal values on the cell walls $x=n\pm\frac12$ coincide exactly between neighbouring cells, and top/bottom nodal values satisfy $u(x,\tfrac12)=e^{\mathrm i\beta_0}u(x,-\tfrac12)$ exactly (the code checks both with result 0).
- Taper: with $K_c=13$,
$$\chi(x)=\tfrac12\big(1+\cos\pi\tau(x)\big),\quad \tau(x)=\min\{1,\max\{0,(|x|-(K_c-1.5))/2\}\},$$
so $\chi=1$ for $|x|\le11.5$, $\chi=0$ for $|x|\ge13.5$, $\chi\in C^1$. The trial function is $v=\chi u_h$ on $|x|\le13.5$ (cells $n=-13,\dots,13$) and $v=0$ outside. Then $v\in V$, $\operatorname{supp}v\subset\overline D$.

### 4.2 Fitted (exact-interface) mesh and flux $p$

- Same triangulation and vertices. For a triangle with no interface edge, $\tilde F_K=F_K$. For an interface triangle with curved edge between local vertices $a,b$ (barycentric $\lambda_a,\lambda_b$) belonging to arc $[\theta_j,\theta_j+\Delta\theta]$:
$$r=\lambda_a+\lambda_b,\quad t=\lambda_b/r,\quad \tilde F_K=F_K+r^3\big(c(\theta_j+t\Delta\theta)-\Pi_2c(t)\big),$$
where $\Pi_2c(t)=c(\theta_j)(1-t)(1-2t)+c(\theta_j+\tfrac{\Delta\theta}2)\,4t(1-t)+c(\theta_j+\Delta\theta)\,t(2t-1)$. On the curved edge ($r=1$) $\tilde F_K$ traces the exact curve; the other two edges are unchanged. Both triangles sharing an interface arc use the same exact arc, so the fitted mesh is conforming and $\rho$ is exactly constant on each fitted triangle. The code asserts $\det D\tilde F_K>0$ at all quadrature points.
- Flux: $p|_K=\frac{1}{\det D\tilde F_K}D\tilde F_K\,\hat p_K\circ\tilde F_K^{-1}$ (contravariant Piola), $\hat p_K\in RT_3(\hat K)$, so $\operatorname{div}p=\frac{1}{\det D\tilde F_K}\widehat{\operatorname{div}}\,\hat p_K$. Normal-trace degrees of freedom are shared across interior edges; $p\cdot n=0$ is imposed at $x=\pm13.5$; the top/bottom quasi-periodic condition (P3) is imposed through edge degrees of freedom. To be confirmed: whether normal continuity across cell walls is exact by construction (the code reports a "normal trace error" $8\times10^{-14}$ that the manager will explain). If you can, also give a variant of the result that tolerates a small, computable normal-trace jump $[p\cdot n]$ on a set of edges.

### 4.3 How $E$ and $M$ are integrated now

- On each native triangle, collapsed (Duffy) Gauss–Legendre rule: $\xi=z_i$, $\eta=(1-z_i)z_j$, weight $w_iw_j(1-z_i)$, with $n=16$ Gauss–Legendre nodes $z_i$ on $[0,1]$ ($n=24$ as a check). $E$ uses $|\nabla v|^2\det DF_K$; $M$ uses $\rho_K^{\rm native}|v|^2\det DF_K$ where $\rho_K^{\rm native}$ is the material of the native triangle (inside or outside the native, quadratic-interpolated interface).
- Material correction for $M$: the region between the native interface edge $\Pi_2c$ and the true arc $c$ has the wrong material. The code adds $(\rho^{\rm in}-1)\int|v|^2$ over this sliver, parametrized for each arc by
$$P(u,w)=\Pi_2c(u)+w\,\big(c(\theta_j+u\Delta\theta)-\Pi_2c(u)\big),\quad(u,w)\in[0,1]^2,$$
with signed weight $\det\partial_{(u,w)}P$ (so slivers on either side of the native edge get the right sign), a tensor Gauss rule with 10 points per direction (16 as a check), and $v(P)$ evaluated in the native triangle that contains $P$ (chosen among the two triangles sharing the arc by the larger minimum barycentric coordinate after Newton inversion of $F_K$).

### 4.4 How $S$ is integrated now

On each fitted triangle, $n\times n$ tensor Gauss rule in collapsed coordinates, $n=16$ (24 check):
- non-interface triangles: $\xi=r$, $\eta=(1-r)t$, weight $(1-r)$;
- interface triangles: $\lambda_a=r(1-t)$, $\lambda_b=rt$, $\lambda_{\rm opp}=1-r$, i.e. the same $(r,t)$ as in the fitted map, so the fitted map is a polynomial in $r$ and analytic in $t$ in these coordinates.

$p$, $\operatorname{div}p$ and $\rho$ are those of the fitted triangle; $v$ and $\nabla v$ at the physical point are evaluated in the native triangle containing it (Newton inversion of $F_K$, falling back to the neighbouring native triangle across the arc).

### 4.5 Sizes

Per cell template roughly $6.4\times10^3$ triangles; 27 cells; the three cell types (left lead, center, right lead) share a template each. Integrand evaluations for one $S$ evaluation at order 16: about $4\times10^7$.

### 4.6 Known obstacles to rigorous bounds

1. $E$ on curved native triangles: $|\nabla v|^2\det DF_K$ is rational in $(\xi,\eta)$ (denominator $\det DF_K$). On affine triangles it is a polynomial and the Gauss rule is exact.
2. $M$: $\rho|v|^2\det DF_K$ is a polynomial on each native triangle (degree $\le 6+2$) except for the taper factor $\chi^2$, which is not polynomial.
3. Taper cells $11.5<|x|<13.5$ (cells $n=\pm12,\pm13$): $\chi$ and $\chi'$ involve $\cos$, $\sin$ of $\pi\tau(x)$, so the integrands are analytic but not polynomial there. $\chi$ is only $C^1$ at $|x|=11.5$ and $|x|=13.5$, but these lines are cell walls, hence mesh edges, so each triangle sees an analytic $\chi$.
4. Sliver integral for $M$: the integrand involves $F_K^{-1}$ at sliver points and the trigonometric curve; the sliver is thin ($O(\Delta\theta^3)$) and changes side where $c$ crosses $\Pi_2c$.
5. $S$ on fitted interface triangles: $v$ comes from the native mesh, so inside a fitted interface triangle $\nabla v$ jumps across the native quadratic edge (a curve at distance $O(\Delta\theta^3)$ from the true arc). The integrand is only piecewise smooth there; tensor Gauss does not converge spectrally across that kink. A possible design change: transport the native field to the fitted mesh, $\tilde v|_K=\hat u_K\circ\tilde F_K^{-1}$, so $v$, $p$, $\rho$ all live on one mesh; then $\tilde v\in V$ still (same nodal values, conforming exact edges) but $\tilde v\ne v$, so $E$, $M$ would also be computed on the fitted mesh.
6. Fitted map: $t=\lambda_b/r$ is singular at the vertex $r=0$; $r^3(\cdot)$ makes $\tilde F_K$ $C^2$ there, analytic in the collapsed $(r,t)$ coordinates.

Rigorous Gauss remainder bounds via analyticity (Bernstein ellipses for tensor or collapsed rules) are one option; exactness arguments for polynomial integrands are another; splitting elements at kinks is a third. Choose what gives explicit, computable constants at acceptable cost.

## 5. Targets

- Width penalty: the reliable interval should be at most about 1% wider than the current floating-point interval ($4.45\times10^{-9}$ in $\mu$). Both endpoints move with $q$ at rate about 1, so this needs two-sided bounds of $q$ with absolute error $\lesssim2\times10^{-11}$, i.e. $E$ and $M$ to relative accuracy $\lesssim5\times10^{-12}$; and an upper bound of $\delta=qJ-1$ within about 1% of $2.14\times10^{-10}$, i.e. $S$ to relative accuracy about $10^{-2}$.
- Cost: the present floating-point evaluation of $E$, $M$, $S$ at order 16 takes about 25 s of a 125 s pipeline (the order-24 check adds about 38 s). A bound that costs up to a few times this is acceptable; say how your bound's cost scales.
- If the target accuracy is not reachable with the present construction, say which part blocks it, give the accuracy you can prove, and propose the smallest change that reaches the target.

## 6. Reply format

- One Markdown file. Sections: summary of results (what is proved, under which assumptions); algebraic reduction (Section 3.2 made rigorous); admissibility and membership $v\in V$; bounds for $E$, $M$, $S$ per element type; assembly into the final interval; table of computable quantities; assumptions list; open steps.
- For each lemma, state the hypotheses actually used. Do not cite results you have not checked; if you use a known quadrature remainder theorem, give the exact statement you use and a reference (author, title, year, theorem number).
