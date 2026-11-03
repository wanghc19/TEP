# Problem statement: computable certification of the isolation hypothesis (H)

> 给用户的说明（中文）：`h-cert` = certification of hypothesis (H)（隔离假设 (H) 的认证）。本文件是发给外部证明模型（ChatGPT Pro）的独立任务说明，正文用英文，含全部背景，不需要访问仓库。它把 (H) 剩下的四个待认证部分整理成要证明的命题：(A) 两侧导波的能带间隙；(B) 截线处无 Dirichlet 表面态；(C) 端点 DtN 误差常数 $\varepsilon^\pm$；(D) 投影常数 $C_h$。证明返回后存为同目录下的 `h-cert-proof.md`，由研究经理核查，必要时再送审稿线程。数字来自 `test/numerical-directions/gap-ends-v1/`、`stage1-findings.md` 和 `qj-cert-v2`（均为 2026-11-03 之前的普通浮点结果）；定理 1、2 来自已审查的 [[dtn-inertia-count]]。标注 "to be confirmed" 的代码事实由研究经理核对，不由证明者负责。

## 0. What we ask from you

We compute a guided-mode eigenvalue $\lambda_*\approx2.4287286700$ of a 2D periodic waveguide with a line defect. A Lehmann–Goerisch enclosure already gives an interval of width $4.46\times10^{-9}$ containing $\lambda_*$, with every truncation error bounded (floating-point rounding excluded). That enclosure is valid **only under the isolation hypothesis (H)**: the window $(\alpha_-,\alpha_+)=(1.32^2,\,2.37^2)$ contains exactly one spectral point, an eigenvalue of finite multiplicity.

We already have a proved and reviewed reduction (Section 2): (H) follows from two finite Hermitian matrix inertia counts, **provided** four further ingredients are certified. **Your task is to supply these four ingredients as theorems with complete proofs and explicit, computable constants**, or to replace the reduction by a better one that needs fewer or easier ingredients:

- **(A) Band gap of each lead.** The window does not meet the spectrum of either periodic lead.
- **(B) No surface states.** Neither half-lead, cut at the port, has a Dirichlet eigenvalue in the window (equivalently the DtN maps have no poles there).
- **(C) DtN error constants.** Explicit $\varepsilon^+_\pm$ for hypothesis (D+) at $\alpha_-$ and $\varepsilon^-_\pm$ for (D−) at $\alpha_+$, for our discrete DtN construction or for a modified computable one.
- **(D) Projection constant.** An explicit $C_h$ for hypothesis (C) on our core mesh.

"Certified" means: every error source except floating-point rounding is bounded rigorously by a finite procedure. Rounding is out of scope (it will be handled later by interval arithmetic), so treat all finite-dimensional computations (eigenvalues of given matrices, quadrature with proved remainder bounds, etc.) as exact. We already have tools for proved quadrature remainders on curved P3 meshes with material interfaces (polynomial models with explicit remainders, certified inverse maps of curved elements), so you may assume integrals of explicit piecewise-smooth functions over our meshes can be enclosed.

Deliver one Markdown file (math in `$...$` / `$$...$$`) with:

1. Precise statements (theorem / lemma / proposition) and complete proofs for each of (A)–(D). Every constant explicit and computable; say exactly what the code must compute.
2. For each item, a finite algorithm (steps, what is solved, what is bounded), the expected size of the constants for our data (Section 3), and a rough cost estimate (number and size of the eigenvalue or linear solves).
3. A list of every assumption used, separated into (a) mathematical assumptions, (b) facts about the discrete construction that the code must satisfy.
4. A feasibility check: given the sizes you expect, will the perturbed endpoint matrices $U_h$, $L_h$ of Theorem 2 keep the floating inertia counts $0$ and $1$ (Section 3.3)? If Theorem 2's constants are too lossy, propose and prove a sharper version.

You may change the window $(\alpha_-,\alpha_+)$ slightly (Section 3.1 gives the sampled band edges), the cut positions, the core domain, the finite element space used for the inertia test, or the port formulation, as long as you prove what you use. Mark such proposals clearly as design changes.

Priority if you cannot finish everything: (B), then (C), then (A), then (D). (B) is the item for which we know no method; (A) and (D) are probably adaptations of known methods (Section 5). If an item cannot be closed, say exactly which step fails and what extra hypothesis or computation would close it. Write plainly and state results at the strength you can prove.

Out of scope: the Lehmann–Goerisch enclosure itself and the bounds for its quantities (done); floating-point rounding; choosing a better candidate.

## 1. Model

- Strip $B=\mathbb R\times I$, $I=(-\tfrac12,\tfrac12)$. Transverse quasi-periodicity $u(x,y+1)=e^{\mathrm i\beta_0}u(x,y)$ with $\beta_0=0.5$; Fourier modes $e^{\mathrm i\beta_ky}$, $\beta_k=\beta_0+2\pi k$, $\langle k\rangle=(1+\beta_k^2)^{1/2}\ge1$.
- Cells $C_n=[n-\tfrac12,n+\tfrac12]\times I$, $n\in\mathbb Z$. Cell $C_n$ contains one inclusion $\Omega_n$ centered at $(n,0)$; $\rho=\rho_n^{\rm in}$ in $\Omega_n$, $\rho=1$ elsewhere.
  - Center $n=0$: star with boundary $c_0(\theta)=0.2\,\big((1.5+0.3\cos5\theta)\cos\theta,\ (1+0.3\cos5\theta)\sin\theta\big)$; $\rho_0^{\rm in}=4$.
  - Leads $n\ne0$: trefoil $r(\theta)=R_a(1+a\cos3\theta)$, $R_a=0.2/\sqrt{1+a^2/2}$; $a=0.12$ for $n<0$ (left lead), $a=0.20$ for $n>0$ (right lead); $\rho_n^{\rm in}=17$.
  - All inclusions stay at distance $\ge0.14$ from the cell walls $x=n\pm\tfrac12$ (trefoil radius $\le R_a(1+a)\approx0.239$; star half-width $0.36$ in $x$), so $\rho=1$ near every wall. The trefoil is symmetric under $y\mapsto-y$ but **not** under $x\mapsto-x$.
- $V=H^1_{\beta_0}(B)$; $a(u,v)=\int_B\nabla u\cdot\overline{\nabla v}$, $b(u,v)=\int_B\rho u\bar v$. $A$ is the self-adjoint operator in $L^2_\rho(B)$ of the form $a$ on $V$, i.e. $-\rho^{-1}\Delta$ with the quasi-periodic condition. Eigenvalue equation $-\Delta u=\lambda\rho u$; in code $\lambda=k^2$.
- **Periodic leads.** $A^{\rm per}_a$ is the same operator with the lead material in every cell (no defect), $a\in\{0.12,0.20\}$. By Floquet–Bloch in $x$, $\sigma(A^{\rm per}_a)=\bigcup_{\theta\in[-\pi,\pi]}\sigma(A_{a,\theta})$, where $A_{a,\theta}$ acts on one cell with $u(x+1,y)=e^{\mathrm i\theta}u(x,y)$ and the transverse condition; each $A_{a,\theta}$ has compact resolvent, eigenvalues $\lambda_1(\theta)\le\lambda_2(\theta)\le\cdots$.
- **Core and half-leads for the inertia test.** $x_\pm=\pm\tfrac12$, $\ell=x_+-x_-=1$. Core $D=(-\tfrac12,\tfrac12)\times I$ (the center cell; $1\le\rho\le4$ in $D$). Half-leads $\Omega_+=(\tfrac12,\infty)\times I$ (right-lead cells $n\ge1$) and $\Omega_-=(-\infty,-\tfrac12)\times I$ (left-lead cells $n\le-1$). Ports $\Gamma_\pm=\{x_\pm\}\times I$. Each half-lead is a periodic medium cut at a cell wall.
- $A_\pm$: the Dirichlet half-lead operators in $L^2_\rho(\Omega_\pm)$ (form $a_{\Omega_\pm}$ on $H^1_{\beta_0,0}(\Omega_\pm)$, zero trace on $\Gamma_\pm$). Expected structure (please prove or cite if you use it): $\sigma_{\rm ess}(A_\pm)=\sigma(A^{\rm per}_{a_\pm})$, and $\sigma(A_\pm)\setminus\sigma_{\rm ess}(A_\pm)$ consists of isolated eigenvalues of finite multiplicity in the gaps ("surface states").

## 2. What is already proved (you may use it)

Notation: $a_O$, $b_O$ are the forms restricted to $O$; $s^O_\lambda=a_O-\lambda b_O$; $\mathcal H=H^1_{\beta_0}(D)$ with no condition on $\Gamma_\pm$; $\|u\|_1^2=a_D(u,u)+\|u\|_{L^2(D)}^2$ (unweighted). Trace space $\mathcal T$ with $\|g\|_{1/2}^2=\sum_k\langle k\rangle|g_k|^2$, $g_k=\int_Ig\,e^{-\mathrm i\beta_ky}dy$. $\tau_\pm u=u|_{\Gamma_\pm}$.

**Hypothesis (P).** $\mathcal W=[\alpha_-,\alpha_+]$ satisfies $\mathcal W\cap\sigma(A_-)=\mathcal W\cap\sigma(A_+)=\emptyset$.

(P) = items (A) and (B) of Section 0 together.

**Extension and reduced form.** For $\lambda\in\mathcal W\cup\{-1\}$ and $g\in\mathcal T$, $E_\pm(\lambda)g$ is the unique $w\in H^1_{\beta_0}(\Omega_\pm)$ with $w|_{\Gamma_\pm}=g$ and $s^{\Omega_\pm}_\lambda(w,\varphi)=0$ for all $\varphi\in H^1_{\beta_0,0}(\Omega_\pm)$. Set
$$\Lambda_\pm(\lambda)(g,h)=s^{\Omega_\pm}_\lambda(E_\pm(\lambda)g,E_\pm(\lambda)h),\qquad t_\lambda(u,v)=a_D(u,v)-\lambda b_D(u,v)+\sum_\pm\Lambda_\pm(\lambda)(\tau_\pm u,\tau_\pm v).$$
$\Lambda_\pm$ is the DtN form, positive on decaying modes. $n(t)$ is the maximal dimension of a subspace on which $t$ is negative definite.

**Theorem 1 (count).** Under (P): for every $\lambda\in\mathcal W$, $t_\lambda$ is a bounded Hermitian form on $\mathcal H$ with $n(\lambda):=n(t_\lambda)<\infty$ and $\dim\{u:t_\lambda(u,\cdot)=0\}=\dim\ker(A-\lambda)$; $\sigma(A)\cap\mathcal W$ is a finite set of eigenvalues of finite multiplicity; and
$$n(\alpha_+)-n(\alpha_-)=\sum_{\lambda\in[\alpha_-,\alpha_+)}\dim\ker(A-\lambda).$$
Key facts in the proof: $\frac{d}{d\lambda}t_\lambda(u,u)=-\|U_\lambda u\|_\rho^2\le-b_D(u,u)$ (so zero crossings are strictly downward); $t_\lambda=p((I-K(\lambda))\cdot,\cdot)$ with $p=t_{-1}$ an inner product equivalent to $\|\cdot\|_1$ and $K(\lambda)$ compact; the resolvent bounds use $d_{\mathcal W}=\min_\pm\operatorname{dist}(\mathcal W,\sigma(A_\pm))>0$.

**Lemma 2.** $\|\tau_\pm u\|_{1/2}^2\le\coth(\ell)\|u\|_1^2$ for $u\in\mathcal H$.

**Discrete data.** $V_h\subset\mathcal H$ is a conforming finite element space with basis $\varphi_1,\dots,\varphi_N$, $v=\sum_jc_j\varphi_j$. Matrices: stiffness $K_{ij}=a_D(\varphi_j,\varphi_i)$; weighted mass $M^\rho$ (true $\rho$); unweighted mass $M^1$; $(B_\pm)_{kj}=(\tau_\pm\varphi_j)_k$, $|k|\le M_F$ (we write $M_F$ for the Fourier truncation); $W_\pm$ selects the DOFs on $\Gamma_\pm$; $D_\pm(\lambda)$ the code's discrete DtN in the wall-node basis (Section 3.2); $\hat\Lambda_\pm(\lambda)$ a $(2M_F+1)\times(2M_F+1)$ Hermitian DtN in the Fourier basis.

**Hypotheses to be certified (items (C), (D) of Section 0).**

- **(D+)** at $\alpha_-$: for all $v=\sum c_j\varphi_j\in V_h$,
  $$\Lambda_\pm(\alpha_-)(\tau_\pm v,\tau_\pm v)\le(W_\pm c)^HD_\pm(\alpha_-)(W_\pm c)+\varepsilon^+_\pm\|\tau_\pm v\|_{1/2}^2 .$$
- **(D−)** at $\alpha_+$: for all $g\in\mathcal T$,
  $$\Lambda_\pm(\alpha_+)(g,g)\ge\hat g^H\hat\Lambda_\pm(\alpha_+)\hat g-\varepsilon^-_\pm\|g\|_{1/2}^2,\qquad\hat g=(g_k)_{|k|\le M_F}.$$
- **(C)** For fixed $\sigma>0$ let $e(u,v)=a_D(u,v)+\sigma\int_Du\bar v$ and $P_h$ the $e$-orthogonal projection onto $V_h$. Then $\|w\|_{L^2(D)}\le C_h\|w\|_e$ for every $w\in\mathcal H$ with $e(w,V_h)=0$.

**Lemma 7 (port representatives).** With $\kappa_k=(\beta_k^2+\sigma)^{1/2}$, $r_{+,k}=\frac{\cosh(\kappa_k(x-x_-))}{\kappa_k\sinh(\kappa_k\ell)}e^{\mathrm i\beta_ky}$ (and $r_{-,k}$ mirrored) satisfy $e(u,r_{\pm,k})=(\tau_\pm u)_k$, and $\delta_{\pm,k}:=\|r_{\pm,k}-P_hr_{\pm,k}\|_e$ is computable: $\delta_{\pm,k}^2=\coth(\kappa_k\ell)/\kappa_k-B_{\pm,k}(K+\sigma M^1)^{-1}B_{\pm,k}^H$. Set $\delta_\pm^2=\sum_{|k|\le M_F}\delta_{\pm,k}^2$.

**Theorem 2 (endpoint matrices).** Let
$$U_h=(1+\eta^+)K+\eta^+M^1-\alpha_-M^\rho+\sum_\pm W_\pm^HD_\pm(\alpha_-)W_\pm,\qquad\eta^+=\coth(\ell)(\varepsilon^+_-+\varepsilon^+_+).$$
Let $\alpha_+\ge0$, $\eta=\coth(\ell)(\varepsilon^-_-+\varepsilon^-_+)<1$, $q_{\max}=\alpha_+\rho_{\max}+\eta+(1-\eta)\sigma$ with $\rho_{\max}=\sup_D\rho$, $M^q=\alpha_+M^\rho+(\eta+(1-\eta)\sigma)M^1$; choose $\theta,\theta_\pm>0$ with
$$c_W:=(1-\eta)-\theta-q_{\max}C_h^2-\sum_\pm\big(\theta_\pm+\|\hat\Lambda_\pm\|\delta_\pm^2\big)\ge0,$$
$$L_h=(1-\eta)(K+\sigma M^1)-\Big(1+\frac{q_{\max}C_h^2}{\theta}\Big)M^q+\sum_\pm B_\pm^H\Big(\hat\Lambda_\pm(\alpha_+)-\frac{\|\hat\Lambda_\pm\|^2\delta_\pm^2}{\theta_\pm}I\Big)B_\pm .$$
Under (P), (D+) at $\alpha_-$, (D−) at $\alpha_+$ and (C): $n(\alpha_-)\ge n(U_h)$ and $n(\alpha_+)\le n(L_h)$, hence $\sum_{\lambda\in[\alpha_-,\alpha_+)}\dim\ker(A-\lambda)\le n(L_h)-n(U_h)$. If moreover $n(L_h)-n(U_h)\le1$, $0\le\alpha_-$, and a Weinstein-type first-order interval $I_1\subset(\alpha_-,\alpha_+)$ meets $\sigma(A)$ (we have this, width $\approx10^{-4}$, around $2.4287$), then (H) holds with a simple eigenvalue.

Proof idea: $U_h$ is a Galerkin upper bound of $t_{\alpha_-}$ on $V_h$; $L_h$ is a lower bound of $t_{\alpha_+}$ on all of $\mathcal H$ after splitting $u=P_hu+w$ and absorbing $w$ with (C) and Lemma 7. When $\varepsilon,C_h,\delta\to0$ both reduce to the code's matrix $T_h(\lambda)=K-\lambda M^\rho+\sum_\pm W_\pm^HD_\pm(\lambda)W_\pm$.

## 3. Numerical facts (ordinary floating point; not certified)

### 3.1 Bands and window

A 17-point scan of $\theta\in[-\pi,\pi]$ at $\beta_0=0.5$ (P3 cell computations) gives the gap edges, both attained at $\theta=\pm\pi$, in $k=\sqrt\lambda$ units:

| Lead | lower edge $k$ | upper edge $k$ |
|---|---|---|
| left ($a=0.12$) | 1.312557304887 | 2.395219092458 |
| right ($a=0.20$) | 1.317414080243 | 2.380844148165 |

The window is $k\in[1.32,2.37]$, i.e. $\alpha_-=1.7424$, $\alpha_+=5.6169$. Margins to the nearest sampled edge: lower $\Delta\lambda=0.00682$ (right lead), upper $\Delta\lambda=0.0515$ (right lead). These edges are sampled values only; a certified band computation may move them. The Goerisch interval width changes only mildly with $\alpha_\pm$ (moving $\alpha_+$ from $2.1875^2$ to $2.37^2$ changed it by 6%), so shrinking the window by a few $10^{-3}$ in $k$ is acceptable.

### 3.2 Discretization

- Meshes: one template per cell type (left lead, center, right lead), P3 isoparametric Lagrange elements, curved elements fitted to the material interface, 48 subdivisions per cell side (to be confirmed), quasi-periodic identification on $y=\pm\tfrac12$. Center template: 28629 DOFs, 6330 triangles; lead templates 28989 and 28908 DOFs. Matching wall meshes between adjacent cells (to be confirmed: identical wall node sets, $n$ DOFs per wall, $n=144$ for P3 with 48 wall segments).
- $M^\rho$ is integrated with the true curved interface (not the polygonal one).
- **Discrete DtN** (`LOCAL_dtn`). For a lead cell, assemble $K_{\rm cell}-\lambda M^\rho_{\rm cell}$ and take the Schur complement onto the two walls, $S=\begin{pmatrix}S_{00}&S_{01}\\S_{10}&S_{11}\end{pmatrix}$, wall 0 being the wall nearer the core. Wall traces $x_j$ of a discrete half-lead solution satisfy $S_{10}x_{j-1}+(S_{11}+S_{00})x_j+S_{01}x_{j+1}=0$. The code solves the linear pencil
  $$\mathcal A=\begin{pmatrix}-(S_{11}+S_{00})&-S_{10}\\I&0\end{pmatrix},\qquad\mathcal B=\begin{pmatrix}S_{01}&0\\0&I\end{pmatrix}$$
  by complex QZ, checks that exactly $n$ eigenvalues satisfy $|\zeta|<1$ and that none is near the unit circle, takes the stable invariant subspace $Z=\begin{pmatrix}Z_1\\Z_0\end{pmatrix}$, and sets
  $$P_{\rm out}=Z_1Z_0^{-1},\qquad D=S_{00}+S_{01}P_{\rm out},$$
  so $P_{\rm out}$ solves $S_{10}+(S_{11}+S_{00})P+S_{01}P^2=0$ with spectral radius $<1$, and $x_0^HDx_0$ is the discrete half-lead energy $s_\lambda$ of the decaying extension. $Z_0$ singular would mean a decaying discrete solution with zero trace on wall 0, i.e. a discrete surface state. The left lead uses the mirrored orientation (to be confirmed).
- $T_h(\lambda)$ is the center-cell matrix $K-\lambda M^\rho$ with $\mathrm{blkdiag}(D_-,D_+)$ added on the wall block.

### 3.3 Current evidence

| Check | Result |
|---|---|
| $n(T_h)$ at $k=1.32$ / $2.37$ | $0$ / $1$, for P2 and P3; difference $1$ |
| $\min\lvert\text{eig}(T_h)\rvert$, P3, raw FE basis (not mass-normalized) | $1.65\times10^{-4}$ at $k=1.32$; $1.53\times10^{-4}$ at $k=2.37$; $\|T_h\|_1\approx83.7$ |
| $n(T_h)$ on 78 points in $k\in[2.1875,2.38]$ | constant 1 |
| only upward jump of $n(T_h)$ in the window | at $k=1.5584378944$ (the candidate) |
| surface-state scan, 171 points, $\Delta k\le0.01$, refined to $0.001$ near the ends | $\min\sigma_{\min}(Z_0)=0.763$ (left), $0.739$ (right), both attained at $k=1.32$; no pole detected; minimal unit-circle separation index 0.092 / 0.054 |
| $\max\|D\|_2$ over the scan | 5.14 |
| Goerisch interval (under (H)) | $[2.4287286691977914,\ 2.4287286736601232]$ |

Mass-normalized distances of $0$ from the spectrum of $T_h(\alpha_\pm)$ have not been computed; we can compute any such floating quantity you need for the feasibility check.

Rough size requirement (our heuristic, please replace with a proper one): in $L_h$ the factor $(1+q_{\max}C_h^2/\theta)$ inflates the mass term, and $(1-\eta)$ deflates the stiffness, so they act roughly like replacing $\alpha_+$ by $\alpha_+(1+q_{\max}C_h^2/\theta)/(1-\eta)$. The upper margin $0.0515/5.617\approx0.9\%$ then suggests $\eta$ and $q_{\max}C_h^2/\theta$ of order $10^{-3}$. With $\rho_{\max}=4$ in the core, $q_{\max}\approx22.5+\sigma$; if $C_h\approx h/\pi$ with $h=1/48$, $q_{\max}C_h^2\approx10^{-3}$. Similarly $\eta^+$ in $U_h$ should be of order $10^{-3}$ or smaller.

## 4. The propositions to prove

### (A) Band gap of each periodic lead

**Wanted.** For $a\in\{0.12,0.20\}$, a theorem of the form: if a finite list of computable quantities satisfies explicit inequalities, then $\mathcal W\cap\sigma(A^{\rm per}_a)=\emptyset$. Concretely, there is an index $j$ with $\sup_\theta\lambda_j(\theta)<\alpha_-$ and $\inf_\theta\lambda_{j+1}(\theta)>\alpha_+$. This needs:

1. upper bounds for $\lambda_j(\theta)$ (Rayleigh–Ritz on a FE space) and lower bounds for $\lambda_{j+1}(\theta)$ (Lehmann–Goerisch with a homotopy or base problem, or projection-error-based lower bounds), at finitely many $\theta$;
2. an explicit modulus of continuity of $\theta\mapsto\lambda_m(\theta)$ to cover $[-\pi,\pi]$ (for example a Lipschitz bound from the $\theta$-dependence of the shifted form $\int|(\nabla+\mathrm i\theta e_x)u|^2$ on the periodic cell);
3. a certified value of the index $j$ (the number of bands below the gap).

Please give the version you consider cheapest for our data (contrast 17, curved trefoil interface, a narrow lower margin $\approx0.4\%$), including how to obtain the lower bounds without a compact-resolvent base problem that is hard to compare. Also prove, or give an exact citation for, $\sigma_{\rm ess}(A_\pm)=\sigma(A^{\rm per}_{a_\pm})$ if you use it.

### (B) No Dirichlet surface states at the cuts

**Wanted.** A theorem with computable hypotheses implying $\mathcal W\cap\sigma_{\rm disc}(A_\pm)=\emptyset$ for the half-leads cut at the cell wall, given (A). Equivalently: for every $\lambda\in\mathcal W$ there is no nonzero decaying solution of $-\Delta u=\lambda\rho u$ in $\Omega_\pm$ with zero trace on $\Gamma_\pm$.

Ideas we have **not** verified (use, repair, or discard them):

1. *Pointwise Riccati certificate plus covering in $\lambda$.* At a fixed $\lambda$ in the gap, with the single-cell two-wall Dirichlet problem well posed, a decaying solution is determined by its wall traces $x_j$. If a bounded propagation operator $P(\lambda)$ on the trace space solves the continuous Riccati equation built from the cell DtN blocks and has spectral radius $<1$, and its graph contains every decaying trace pair $(x_0,x_1)$, then $x_0=0$ forces $u=0$. A Newton–Kantorovich argument around the discrete $P_{\rm out}$ might certify such a $P(\lambda)$, and a quantitative perturbation bound might extend it to a neighbourhood of $\lambda$, so finitely many $\lambda$ cover $\mathcal W$. Open points: the right function space for $P$ (traces in $H^{1/2}$), the claim that graph$(P)$ captures all decaying solutions, the discretization error of the cell DtN blocks, and $\lambda$ values where the single cell has a two-wall Dirichlet eigenvalue (one could then cut the cell elsewhere).
2. *Count with poles, applied to the pure lead.* A finite-dimensional analogue is the Haynsworth inertia additivity $n(H)=n(H_{22})+n(H/H_{22})$: across a window, the negative index of the Schur complement changes by (eigenvalues of the full problem) minus (eigenvalues of the Dirichlet sub-block). A continuous version of Theorem 1 allowing finitely many DtN poles in $\mathcal W$ (with endpoints not poles) would read, plausibly,
   $$n(\alpha_+)-n(\alpha_-)=\#\big(\sigma(A)\cap[\alpha_-,\alpha_+)\big)-\sum_\pm\#\big(\sigma(A_\pm)\cap(\alpha_-,\alpha_+)\big)$$
   (multiplicities; exact endpoint conventions to be determined). Applied to the **defect-free** lead $A^{\rm per}_a$, whose spectrum misses $\mathcal W$ by (A), with core one lead cell and half-leads cut at its two walls, it would give: the total number of surface states of the two half-leads of that lead in $\mathcal W$ equals $-\big(n(\alpha_+)-n(\alpha_-)\big)$ for the one-cell reduced form. Certifying that this index difference is $\ge0$ (a Galerkin lower bound at $\alpha_+$ and a complement upper bound at $\alpha_-$, as in Theorem 2 with roles swapped) would exclude surface states for both cuts at once. Our half-leads $\Omega_+$ (right lead, cut at a left wall) and $\Omega_-$ (left lead, cut at a right wall) are each one of the two half-leads of the corresponding pure lead. Open points: the theorem with poles itself; how to certify the DtN errors at the endpoints when the endpoint resolvent norm of $A_\pm$ is not yet known (possible circularity); whether the endpoints can be shown not to be poles by a cheaper argument.
3. *Pole-free port formulation.* Replace the Dirichlet cut by a Robin or other port condition for which the half-lead problem has no real eigenvalue in $\mathcal W$, while keeping a Hermitian reduced form whose inertia counts eigenvalues of $A$. We do not know whether such a formulation exists; if you find one, it may also simplify (C).

Any route is acceptable if it ends in a finite computation. If you prove the count theorem with poles, state it in full, since it would also replace Theorem 1.

### (C) DtN error constants $\varepsilon^\pm$

**Wanted.** Computable $\varepsilon^+_\pm$ with (D+) at $\lambda=\alpha_-$ for our $D_\pm$, and computable $\varepsilon^-_\pm$ and $\hat\Lambda_\pm$ with (D−) at $\lambda=\alpha_+$, with sizes small enough for the feasibility check (order $10^{-3}$ or smaller in $\eta,\eta^+$; Section 3.3). Both are one-sided statements at a single $\lambda$, which may help: (D+) is needed only on the traces of $V_h$ (a finite-dimensional set), (D−) on all of $\mathcal T$ (high modes must be handled analytically; the trace form $\Lambda_\pm$ is heuristically $\operatorname{diag}\langle k\rangle$ plus a relatively compact part).

Allowed modifications (prove what you use):
- a different construction of $D_\pm$ or $\hat\Lambda_\pm$ (for example extension over finitely many lead cells plus a certified tail, or a Riccati solution with a Newton–Kantorovich enclosure);
- a modified trial space for the $\alpha_-$ side whose port traces are low Fourier modes only ($V_h$ functions vanishing on $\Gamma_\pm$ plus $\chi_\pm(x)e^{\mathrm i\beta_ky}$, $|k|\le M_F$), so that (D+) is needed only on $\mathrm{span}\{e^{\mathrm i\beta_ky}\}_{|k|\le M_F}$;
- any sharper replacement of Theorem 2's way of using $\varepsilon^\pm$.

State how the constants depend on $\operatorname{dist}(\alpha_\pm,\sigma(A_\pm))$ and on the certificates of (A), (B), and avoid circular use.

### (D) Projection constant $C_h$

**Wanted.** An explicit computable $C_h$ in (C) for the core $D=(-\tfrac12,\tfrac12)\times I$ with natural boundary conditions on $\Gamma_\pm$ (no constraint in $\mathcal H$) and quasi-periodic identification on $y=\pm\tfrac12$. The form $e$ has no material coefficient, so the material interface matters only through the mesh.

Facts that may help:
- If $W_h\subset V_h$ and $\|w\|\le C\|w\|_e$ holds for every $w$ that is $e$-orthogonal to $W_h$, then it holds for every $w$ that is $e$-orthogonal to $V_h$, with the same $C$.
- Theorem 2 allows **any** conforming $V_h\subset\mathcal H$ for the inertia test; it need not be the curved Goerisch mesh. A straight-sided mesh of the unit square would avoid curved elements, at the price of integrating $\rho$ over the curved star inside elements (we can enclose such integrals).
- Known approaches to pointwise-free projection constants (for example hypercircle / Prager–Synge with Raviart–Thomas fluxes and Crouzeix–Raviart or P1 spaces, as in work of X. Liu and S. Oishi) may need adaptation to the natural port condition and the quasi-periodic identification.

Give the constant, its proof, the computation, and its expected size for our mesh. If a weighted variant of (C) (for example with $q=\alpha_+\rho+\dots$ inside the norm, using that $\rho=4$ only on the star) gives a much better $L_h$, propose it with a proof.

## 5. Literature pointers (check them yourself; we have not verified every detail)

- V. Hoang, M. Plum, C. Wieners, "A computer-assisted proof for photonic band gaps", Z. Angew. Math. Phys. 60 (2009) 1035–1052: cell eigenvalue bounds with homotopy and a covering of the Bloch parameter set (Theorems 1–2 and 7).
- S. Fliss, "A Dirichlet-to-Neumann approach for the exact computation of guided modes in photonic crystal waveguides", SIAM J. Sci. Comput. 35 (2013) B438–B461: exact DtN reduction, propagation operator, half-lead Dirichlet poles and the Robin-to-Robin alternative (Theorem 4.1, Remark 4.2).
- S. Fliss, P. Joly, V. Lescarret, "A DtN approach to the mathematical and numerical analysis in waveguides with periodic outlets at infinity", Pure Appl. Anal. 3 (2021) 487–526: Riccati characterization of the propagation operator (Theorem 4.8).
- M. Plum and coauthors on computer-assisted eigenvalue exclusion; M. T. Nakao, M. Plum, Y. Watanabe, *Numerical Verification Methods and Computer-Assisted Proofs for Partial Differential Equations*, Springer 2019 (Lehmann–Goerisch, homotopy, Chapter 10).
- X. Liu and S. Oishi (projection error constants and guaranteed lower eigenvalue bounds on polygonal domains); C. Carstensen, J. Gedicke (guaranteed lower bounds); E. Cancès et al., Math. Comp. 89 (2020) (clusters).
- B. M. Brown, V. Hoang, M. Plum, I. Wood and coauthors on spectrum created by line defects (counts for weak defects).

## 6. Reply format

One Markdown file, sections:

1. Summary: which of (A)–(D) are closed, and under which hypotheses.
2. One section per item (A)–(D): statements, proofs, algorithm, expected constants, cost.
3. Any new or sharpened version of Theorem 1 or Theorem 2, with proof.
4. Feasibility check against Section 3.3.
5. Assumption list: (a) mathematical, (b) code facts.
6. Open steps, if any, each with the exact missing hypothesis or computation.
