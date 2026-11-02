# DtN 惯性计数：用两个端点矩阵的惯性认证隔离假设 (H)（draft，已审查）

本文件给出 [[isolation-survey]] 推荐路线第 3、4 步的数学部分：
1. 一个计数定理：窗口内 $A$ 的特征值个数，等于约化形式 $t_\lambda$ 的负指数在两端点的差；
2. 由此得到的 (H) 认证判据：明确写出两个端点上需要计算惯性的有限矩阵，以及它们依赖的、尚待数值认证的常数。

作者：Claude，模式 Proof from scratch。记号沿用 [[goerisch-width]] 第 0 节。

## 进度

- 2026-11-02 第 1 阶段：设定、假设和定理陈述。完成。
- 2026-11-02 第 2 阶段：引理 1–6 及定理 1 的证明。完成（draft）。
- 2026-11-02 第 3 阶段：引理 7、定理 2（端点矩阵与判据）及其证明。完成（draft）。
- 2026-11-02 第 4 阶段：需要计算的量清单（第 5 节）。完成。
- 审查：证明审查线程（[[dtn-inertia-count-review]]）结果为 0 个 blocker、1 个重要、2 个次要问题，均已按审查给出的修正改正：引理 3(d) 的 min 改为 sup（D-1）；引理 5 补上 $H_-=\{0\}$ 时的 $c_-$（D-2）；定理 2 第 2 条断言 (H) 时补上条件 $\alpha_-\ge0$（D-3）。修正未再送审。第 0–4 节的数学部分已审；第 5 节和标为启发式的说明不在审查范围内。
- 未决（不在本文件证明范围内）：假设 (P) 的认证；端点 DtN 误差常数 $\varepsilon^\pm$、投影常数 $C_h$ 的认证；矩阵惯性的区间算术计算。

## 0. 设定与记号

- 条带 $B=\mathbb R\times I$，$I=(-\tfrac12,\tfrac12)$，横向相位 $\beta_0$，$\beta_k=\beta_0+2\pi k$，$\langle k\rangle=(1+\beta_k^2)^{1/2}\ge1$。材料 $\rho\in L^\infty(B)$，$1\le\rho\le\rho_{\max}$。$V=H^1_{\beta_0}(B)$，$a$、$b$、$A$ 同 [[goerisch-width]] 第 0 节。本文件**不用**导波的周期性，只用下面的假设 (P)。
- 取 $x_-<x_+$，$\ell=x_+-x_-$。芯区 $D=(x_-,x_+)\times I$，半导波 $\Omega_-=(-\infty,x_-)\times I$，$\Omega_+=(x_+,\infty)\times I$，端口 $\Gamma_\pm=\{x_\pm\}\times I$。与代码的对应：$\Gamma_\pm$ 是中心端口 `+`/`-`，$\Omega_\pm$ 是正/负半导波。
- 对开集 $O\in\{D,\Omega_\pm\}$，$H^1_{\beta_0}(O)$ 定义同 $V$（上下边准周期）。$\mathcal H:=H^1_{\beta_0}(D)$。$H^1_{\beta_0,0}(\Omega_\pm)$ 为 $H^1_{\beta_0}(\Omega_\pm)$ 中在 $\Gamma_\pm$ 上迹为零的函数。
- 迹与 Fourier 系数。$g\in L^2(I)$ 写成 $g=\sum_kg_ke^{\mathrm i\beta_ky}$，$g_k=\int_Ig\,e^{-\mathrm i\beta_ky}dy$。端口迹空间 $\mathcal T=\{g:\|g\|_{1/2}^2:=\sum_k\langle k\rangle|g_k|^2<\infty\}$。$\tau_\pm u=u|_{\Gamma_\pm}$。
- 形式：
  - $a_O(u,v)=\int_O\nabla u\cdot\overline{\nabla v}$；
  - $b_O(u,v)=\int_O\rho u\bar v$；
  - $s^O_\lambda=a_O-\lambda b_O$；
  - 在 $B$ 上记 $s_\lambda=a-\lambda b$。
  - 芯区上另记 $\|u\|_1^2=a_D(u,u)+\|u\|_{L^2(D)}^2$（不带权）。
- 半导波 Dirichlet 算子 $A_{\pm}$：$L^2_\rho(\Omega_\pm)$ 中由闭形式 $a_{\Omega_\pm}$（定义域 $H^1_{\beta_0,0}(\Omega_\pm)$）确定的非负自伴算子（Kato 1995，Theorem VI.2.6，印刷页 323）。$R_\pm(\lambda)=(A_\pm-\lambda)^{-1}$。

**假设 (P).** $\alpha_-<\alpha_+$ 为实数，窗口 $\mathcal W=[\alpha_-,\alpha_+]$ 满足 $\mathcal W\cap\sigma(A_-)=\mathcal W\cap\sigma(A_+)=\emptyset$。

(P) 要求每个半导波在窗口内既无本质谱，也无截线 $x=x_\pm$ 处 Dirichlet 条件下的特征值（即 DtN 的极点）。它是本文件唯一的谱假设；它的认证不在本文件范围内。

**定义（延拓与约化形式）.** 对 $\lambda\in\mathcal W\cup\{-1\}$ 和 $g\in\mathcal T$，$E_\pm(\lambda)g$ 是满足下列条件的唯一 $w\in H^1_{\beta_0}(\Omega_\pm)$（存在唯一性见引理 1）：
$$w|_{\Gamma_\pm}=g,\qquad s^{\Omega_\pm}_\lambda(w,\varphi)=0\quad\forall\varphi\in H^1_{\beta_0,0}(\Omega_\pm).$$
对 $u\in\mathcal H$，令 $U_\lambda u$ 为：在 $D$ 上等于 $u$，在 $\Omega_\pm$ 上等于 $E_\pm(\lambda)\tau_\pm u$。定义
$$t_\lambda(u,v)=s_\lambda(U_\lambda u,U_\lambda v),\qquad u,v\in\mathcal H .$$
展开即
$$t_\lambda(u,v)=a_D(u,v)-\lambda b_D(u,v)+\sum_\pm\Lambda_\pm(\lambda)(\tau_\pm u,\tau_\pm v),\qquad \Lambda_\pm(\lambda)(g,h)=s^{\Omega_\pm}_\lambda(E_\pm(\lambda)g,E_\pm(\lambda)h).$$
$\Lambda_\pm(\lambda)$ 是 DtN 映射对应的形式：对衰减模 $e^{-\kappa|x-x_\pm|}$ 它给出 $\kappa>0$。

**指数.** 对 $\mathcal H$ 上有界 Hermitian 形式 $t$：
- $n(t)$：使 $t$ 在其上负定（$t(u,u)<0$，$u\ne0$）的子空间的最大维数；
- $z(t)=\dim\{u:t(u,v)=0\ \forall v\in\mathcal H\}$。

记 $n(\lambda)=n(t_\lambda)$，$z(\lambda)=z(t_\lambda)$。有限维时 $n$ 即 Hermitian 矩阵的负特征值个数（Sylvester 惯性律）。

## 1. 结果

**定理 1（计数）.** 设 (P)。则
1. 对每个 $\lambda\in\mathcal W$，$t_\lambda$ 是 $\mathcal H$ 上有界 Hermitian 形式，$n(\lambda)$、$z(\lambda)$ 有限，且 $z(\lambda)=\dim\ker(A-\lambda)$；
2. $\sigma(A)\cap\mathcal W=\{\lambda\in\mathcal W:z(\lambda)>0\}$，这是有限集，每点是 $A$ 的有限重特征值；
3. $$n(\alpha_+)-n(\alpha_-)=\sum_{\lambda\in[\alpha_-,\alpha_+)}\dim\ker(A-\lambda).$$

**定理 2（(H) 的端点惯性判据）.** 精确陈述见第 4.3 节。它把 $n(\alpha_-)$ 的下界和 $n(\alpha_+)$ 的上界化为两个有限 Hermitian 矩阵的负特征值个数：

- $U_h$ 只在 $\alpha_-$ 处用到数值 DtN；
- $L_h$ 只在 $\alpha_+$ 处用到数值 DtN。

若 $n(L_h)-n(U_h)\le1$，且命题 5 的区间 $I_1\subset(\alpha_-,\alpha_+)$，则 $[\alpha_-,\alpha_+)$ 中只有一个谱点，它是单重特征值，落在 $I_1$ 中；再加上 $\alpha_-\ge0$，(H) 对 $(\alpha_-,\alpha_+)$ 成立。

## 2. 引理

**所用标准事实（不另引）.**
- (F1) $y$ 方向 Fourier 级数。对 $O=(x_1,x_2)\times I$（$x_1$ 可为 $-\infty$，$x_2$ 可为 $+\infty$）：$u\in H^1_{\beta_0}(O)$ 当且仅当 $u=\sum_ku_k(x)e^{\mathrm i\beta_ky}$，$u_k\in H^1(x_1,x_2)$，且 $\sum_k\int(|u_k'|^2+\langle k\rangle^2|u_k|^2)<\infty$；这个和等于 $a_O(u,u)+\|u\|_{L^2(O)}^2$。有限端点处 $(\tau u)_k=u_k(x_j)$。
- (F2) 拼接。$O_1,O_2$ 沿 $\Gamma$ 相邻，$u_i\in H^1_{\beta_0}(O_i)$ 在 $\Gamma$ 上迹相等，则拼接函数属于 $H^1_{\beta_0}$（两块与 $\Gamma$ 之并的内部）。反之，$H^1$ 函数在 $\Gamma$ 两侧的迹相等。由 (F1) 化为一维：分段 $H^1$ 且在接点连续的函数属于 $H^1$。
- (F3) 有界区间上 $H^1\hookrightarrow L^2$ 紧（一维 Rellich）。
- (F4) 紧自伴算子的谱定理；$I-K$（$K$ 紧）的 Fredholm 择一；闭图像定理；自伴 $S$ 有 $\|(S-\lambda)^{-1}\|\le1/\operatorname{dist}(\lambda,\sigma(S))$；预解式恒等式。

**所引定理.** Kato, *Perturbation Theory for Linear Operators*, 2nd ed., Springer 1995（[[ref/ref_data/books/Kato1995.pdf|本地]]，PDF 页 = 印刷页 + 22）。

Theorem VI.2.1（第一表示定理，印刷页 322）。设 $\mathfrak t$ 是 $H$ 中稠定、闭、扇形的半双线性形式，则存在 m-扇形算子 $T$ 使
- (i) $D(T)\subset D(\mathfrak t)$，且对 $u\in D(T)$、$v\in D(\mathfrak t)$ 有 $\mathfrak t[u,v]=(Tu,v)$；
- (iii) 若 $u\in D(\mathfrak t)$、$w\in H$，且 $\mathfrak t[u,v]=(w,v)$ 对 $\mathfrak t$ 的某个核中的一切 $v$ 成立，则 $u\in D(T)$，$Tu=w$。

Theorem VI.2.6（印刷页 323）：对称、闭、下有界的稠定形式所对应的 $T$ 自伴且下有界。

本文对 $A$（$H=L^2_\rho(B)$，$\mathfrak t=a$，$D(\mathfrak t)=V$）和 $A_\pm$（$H=L^2_\rho(\Omega_\pm)$，$\mathfrak t=a_{\Omega_\pm}$，$D(\mathfrak t)=H^1_{\beta_0,0}(\Omega_\pm)$）使用这两条。前提是：形式非负对称，故扇形；定义域含 $C_c^\infty$ 型准周期函数，故稠定；形式范数与 $H^1$ 范数等价且定义域是 $H^1$ 的闭子空间，故闭。在 (iii) 中取核为整个形式定义域。

记 $d_{\mathcal W}=\min_\pm\operatorname{dist}(\mathcal W,\sigma(A_\pm))$。由 (P)，$\mathcal W$ 紧且与闭集 $\sigma(A_\pm)$ 不交，故 $d_{\mathcal W}>0$。

### 引理 1（半导波延拓）

只写 $\Omega_+$，$\Omega_-$ 相同。记 $s=x-x_+$。对 $\lambda\in\mathcal W\cup\{-1\}$：

- (a) $E_+(\lambda)$ 有定义，是 $\mathcal T\to H^1_{\beta_0}(\Omega_+)$ 的有界线性映射；
- (b) $E_+(\lambda)=E_+(-1)+(\lambda+1)R_+(\lambda)E_+(-1)$（$\lambda\in\mathcal W$）；
- (c) $E_+(-1):\mathcal T\to L^2_\rho(\Omega_+)$ 是紧算子；
- (d) 若 $w_h\in H^1_{\beta_0}(\Omega_+)$ 的迹为 $h$，则 $\Lambda_+(\lambda)(g,h)=s^{\Omega_+}_\lambda(E_+(\lambda)g,w_h)$。

**证明.**

1. *显式提升.* 令 $E^0g=\sum_kg_ke^{\mathrm i\beta_ky}e^{-\langle k\rangle s}$。由 (F1)，
   $$\|E^0g\|_{H^1(\Omega_+)}^2=\sum_k|g_k|^2\!\int_0^\infty\!(\langle k\rangle^2+\beta_k^2+1)e^{-2\langle k\rangle s}ds=\|g\|_{1/2}^2,\qquad \|E^0g\|_{L^2(\Omega_+)}^2=\sum_k\frac{|g_k|^2}{2\langle k\rangle}.$$
   对 $\varphi\in H^1_{\beta_0,0}(\Omega_+)$，按模分部积分。记 $f_k=e^{-\langle k\rangle s}$，有 $f_k''=\langle k\rangle^2f_k$ 与 $\varphi_k(0)=0$，所以
   $$\int_{\Omega_+}\nabla E^0g\cdot\overline{\nabla\varphi}+E^0g\,\bar\varphi=\sum_kg_k\int_0^\infty(f_k'\bar\varphi_k'+\langle k\rangle^2f_k\bar\varphi_k)\,ds=0 .$$
   因此 $s^{\Omega_+}_{-1}(E^0g,\varphi)=\int_{\Omega_+}(\rho-1)E^0g\,\bar\varphi$。
2. *唯一性.* 设 $\lambda\in\mathcal W\cup\{-1\}$，$d\in H^1_{\beta_0,0}(\Omega_+)$ 满足 $s^{\Omega_+}_\lambda(d,\varphi)=0$ 对一切 $\varphi\in H^1_{\beta_0,0}(\Omega_+)$ 成立。这就是 $a_{\Omega_+}(d,\varphi)=b_{\Omega_+}(\lambda d,\varphi)$。由 Kato VI.2.1(iii)，$d\in D(A_+)$ 且 $A_+d=\lambda d$。又 $\lambda\notin\sigma(A_+)$：对 $\mathcal W$ 由 (P)；对 $-1$ 由 $A_+\ge0$。所以 $d=0$。由此，两个满足定义的 $w$ 之差为零。
3. *$\lambda=-1$ 的存在性与 (c).* 令 $z=(A_++1)^{-1}[(1-\rho^{-1})E^0g]\in D(A_+)\subset H^1_{\beta_0,0}(\Omega_+)$。由 Kato VI.2.1(i)，
   $$s^{\Omega_+}_{-1}(z,\varphi)=b_{\Omega_+}((1-\rho^{-1})E^0g,\varphi)=\int(\rho-1)E^0g\,\bar\varphi .$$
   与第 1 步相减，$w=E^0g-z$ 满足定义，所以
   $$E_+(-1)=E^0-(A_++1)^{-1}(1-\rho^{-1})E^0 .$$
   有界性：
   - $E^0:\mathcal T\to H^1$ 是等距；
   - 乘以 $(1-\rho^{-1})$ 在 $L^2$ 上有界；
   - $(A_++1)^{-1}$ 把 $L^2_\rho$ 有界地映入 $H^1$：对 $z=(A_++1)^{-1}f$，$\|z\|_{H^1}^2\le s_{-1}^{\Omega_+}(z,z)=b(f,z)\le\|f\|_\rho\|z\|_\rho\le\rho_{\max}^{1/2}\|f\|_\rho\|z\|_{H^1}$。

   紧性：令 $P_N$ 为保留 $|k|\le N$ 的 Fourier 截断。$E^0P_N$ 有限秩，且
   $$\|E^0(I-P_N)g\|_{L^2}^2=\sum_{|k|>N}\frac{|g_k|^2}{2\langle k\rangle}\le\Big(\sup_{|k|>N}\frac1{2\langle k\rangle^2}\Big)\|g\|_{1/2}^2\to0 .$$
   所以 $E^0:\mathcal T\to L^2(\Omega_+)$ 紧。$E_+(-1)$ 是 $E^0$ 与有界算子之积的差，故 $\mathcal T\to L^2_\rho$ 紧（$\rho$ 有上下界，$L^2$ 与 $L^2_\rho$ 范数等价）。
4. *$\lambda\in\mathcal W$ 的存在性与 (b).* 令 $\zeta=(\lambda+1)R_+(\lambda)E_+(-1)g\in D(A_+)\subset H^1_{\beta_0,0}(\Omega_+)$。由 Kato VI.2.1(i)，$s^{\Omega_+}_\lambda(\zeta,\varphi)=b((A_+-\lambda)\zeta,\varphi)=(\lambda+1)b(E_+(-1)g,\varphi)$。又 $s^{\Omega_+}_\lambda(E_+(-1)g,\varphi)=s^{\Omega_+}_{-1}(E_+(-1)g,\varphi)-(\lambda+1)b(E_+(-1)g,\varphi)=-(\lambda+1)b(E_+(-1)g,\varphi)$。两式相加为零，所以 $w=E_+(-1)g+\zeta$ 满足定义。由第 2 步，$w=E_+(\lambda)g$，(b) 成立。

   有界性：$\|\zeta\|_\rho\le|\lambda+1|d_{\mathcal W}^{-1}\|E_+(-1)g\|_\rho$，且
   $$a_{\Omega_+}(\zeta,\zeta)=\lambda\|\zeta\|_\rho^2+(\lambda+1)b(E_+(-1)g,\zeta),$$
   所以 $\|\zeta\|_{H^1}\le C\|g\|_{1/2}$。
5. *(d).* $w_h-E_+(\lambda)h\in H^1_{\beta_0,0}(\Omega_+)$，由定义 $s^{\Omega_+}_\lambda(E_+(\lambda)g,w_h-E_+(\lambda)h)=0$。$\square$

### 引理 2（端口迹）

对 $u\in\mathcal H$，$\|\tau_\pm u\|_{1/2}^2\le\coth(\ell)\,\|u\|_1^2$。

**证明.** 一维不等式：对 $\kappa>0$、$f\in H^1(0,\ell)$，
$$\kappa|f(\ell)|^2\le\coth(\kappa\ell)\int_0^\ell(|f'|^2+\kappa^2|f|^2).$$
1. 令 $f_0=\cosh(\kappa x)/\cosh(\kappa\ell)$，$\mathcal E(f)=\int_0^\ell(|f'|^2+\kappa^2|f|^2)$。直接计算得 $\mathcal E(f_0)=\kappa\tanh(\kappa\ell)$。
2. 写 $f=f(\ell)f_0+d$，$d(\ell)=0$。由 $f_0''=\kappa^2f_0$ 与 $f_0'(0)=0$，交叉项
   $$\int_0^\ell(f_0'\bar d'+\kappa^2f_0\bar d)=f_0'(\ell)\bar d(\ell)-f_0'(0)\bar d(0)=0 .$$
3. 所以 $\mathcal E(f)=|f(\ell)|^2\mathcal E(f_0)+\mathcal E(d)\ge|f(\ell)|^2\kappa\tanh(\kappa\ell)$。左端点由反射同理。

取 $\kappa=\langle k\rangle\ge1$，有 $\coth(\langle k\rangle\ell)\le\coth\ell$。对 $k$ 求和并用 (F1)：
$$\|\tau_+u\|_{1/2}^2=\sum_k\langle k\rangle|u_k(x_+)|^2\le\coth(\ell)\sum_k\int(|u_k'|^2+\langle k\rangle^2|u_k|^2)=\coth(\ell)\|u\|_1^2 .\qquad\square$$

由引理 1(a)、引理 2 与 (F2)，对 $\lambda\in\mathcal W\cup\{-1\}$，$U_\lambda$ 是 $\mathcal H\to V$ 的有界线性映射。

### 引理 3（约化形式的恒等式与正则性）

设 $\lambda,\mu\in\mathcal W\cup\{-1\}$，$u,v\in\mathcal H$。

- (a) $t_\lambda(u,v)-t_\mu(u,v)=-(\lambda-\mu)\,b(U_\lambda u,U_\mu v)$。
- (b) $U_\lambda=(I+(\lambda+1)\tilde R(\lambda))U_{-1}$，其中 $\tilde R(\lambda)$ 在 $L^2_\rho(B)=L^2_\rho(\Omega_-)\oplus L^2_\rho(D)\oplus L^2_\rho(\Omega_+)$ 上作用为 $R_-(\lambda)\oplus0\oplus R_+(\lambda)$。
- (c) $p:=t_{-1}$ 是 $\mathcal H$ 上内积，且 $\|u\|_1^2\le p(u,u)\le C_p\|u\|_1^2$。
- (d) $J:=U_{-1}:(\mathcal H,p)\to L^2_\rho(B)$ 紧，且 $M_U:=\sup_{\lambda\in\mathcal W}\|U_\lambda\|_{(\mathcal H,p)\to L^2_\rho(B)}<\infty$。
- (e) 对 $\lambda\in\mathcal W$，$t_\lambda$ 有界 Hermitian，$t_\lambda(u,v)=p((I-K(\lambda))u,v)$，其中
  $$K(\lambda)=(\lambda+1)J^*(I+(\lambda+1)\tilde R(\lambda))J$$
  紧且关于 $p$ 自伴。并且 $|t_\lambda(u,v)-t_\mu(u,v)|\le M_U^2|\lambda-\mu|\,p(u,u)^{1/2}p(v,v)^{1/2}$（$\lambda,\mu\in\mathcal W$）。
- (f) 对 $u\in\mathcal H$，$\lambda\mapsto t_\lambda(u,u)$ 在 $\mathcal W$ 上可微（端点单侧），导数为 $-\|U_\lambda u\|_\rho^2\le-b_D(u,u)$。于是对 $\alpha_-\le\lambda_1<\lambda_2\le\alpha_+$，
  $$t_{\lambda_2}(u,u)\le t_{\lambda_1}(u,u)-(\lambda_2-\lambda_1)\,b_D(u,u).$$

**证明.**

1. *(a).* 函数 $\Phi_0=U_\lambda v-U_\mu v$ 在 $D$ 上为零，在 $\Omega_\pm$ 上迹为零。由定义，$s_\lambda(U_\lambda u,\Phi_0)=\sum_\pm s^{\Omega_\pm}_\lambda(E_\pm(\lambda)\tau_\pm u,\Phi_0|_{\Omega_\pm})=0$。所以
   $$t_\lambda(u,v)=s_\lambda(U_\lambda u,U_\mu v)=s_\mu(U_\lambda u,U_\mu v)-(\lambda-\mu)b(U_\lambda u,U_\mu v).$$
   同理，$U_\lambda u-U_\mu u$ 也是这样的函数。$s_\mu$ 对实 $\mu$ 是 Hermitian 的，所以
   $$s_\mu(U_\lambda u,U_\mu v)=t_\mu(u,v)+\overline{s_\mu(U_\mu v,U_\lambda u-U_\mu u)}=t_\mu(u,v).$$
2. *(b).* 在 $D$ 上两边都等于 $u$；在 $\Omega_\pm$ 上即引理 1(b)。
3. *(c).* $p(u,u)=a(U_{-1}u,U_{-1}u)+b(U_{-1}u,U_{-1}u)\ge a_D(u,u)+b_D(u,u)\ge\|u\|_1^2$（$\rho\ge1$）。上界由 $U_{-1}:\mathcal H\to V$ 有界得到。$p$ 是 Hermitian 正定的，且与 $\|\cdot\|_1$ 等价，所以 $(\mathcal H,p)$ 是 Hilbert 空间。
4. *(d).* $Ju=(E_-(-1)\tau_-u,\,u,\,E_+(-1)\tau_+u)$。
   - 端口分量由引理 2 与引理 1(c) 为紧。
   - 中间分量是嵌入 $\mathcal H\to L^2(D)$，它也紧。令 $P_N$ 为 $y$ 方向截断，则 $\|u-P_Nu\|_{L^2(D)}^2\le(\sup_{|k|>N}\langle k\rangle^{-2})\|u\|_1^2\to0$。$P_N$ 的值域在 $\bigoplus_{|k|\le N}H^1(x_-,x_+)$ 中，由 (F3) 嵌入 $L^2$ 是紧的。紧算子的范数极限仍是紧算子。

   一致界由 (b) 与 (F4) 得到：$\|U_\lambda\|\le(1+(|\lambda|+1)d_{\mathcal W}^{-1})\|J\|$。
5. *(e).* 取 (a) 中 $\mu=-1$，并用 (b)：
   $$t_\lambda(u,v)=p(u,v)-(\lambda+1)b\big((I+(\lambda+1)\tilde R(\lambda))Ju,Jv\big)=p(u,v)-p(K(\lambda)u,v).$$
   - $K(\lambda)$ 紧，因为 $J$ 紧。
   - $s_\lambda$ 对实 $\lambda$ 是 Hermitian 的，所以 $t_\lambda$ 也是，因此 $K(\lambda)$ 关于 $p$ 自伴。
   - Lipschitz 界由 (a) 与 Cauchy–Schwarz 得到。
6. *(f).* 由 (a)，
   $$\frac{t_\lambda(u,u)-t_\mu(u,u)}{\lambda-\mu}=-b(U_\lambda u,U_\mu u).$$
   当 $\mu\to\lambda$（$\mu\in\mathcal W$）时，由 (b) 与预解式恒等式 $R(\mu)-R(\lambda)=(\mu-\lambda)R(\mu)R(\lambda)$（$\|R\|\le d_{\mathcal W}^{-1}$），有 $\|U_\mu-U_\lambda\|\to0$，所以导数为 $-\|U_\lambda u\|_\rho^2$。$U_\lambda u$ 在 $D$ 上等于 $u$，所以导数 $\le-b_D(u,u)$。$t_\lambda(u,u)$ 是实值可微函数，由中值定理得最后的不等式。$\square$

### 引理 4（核的对应）

设 $\lambda\in\mathcal W$，$N(\lambda)=\{u\in\mathcal H:t_\lambda(u,v)=0\ \forall v\in\mathcal H\}$。则 $U_\lambda$ 是 $N(\lambda)$ 到 $\ker(A-\lambda)$ 的线性双射。特别地，$z(\lambda)=\dim\ker(A-\lambda)$。

**证明.**

*分解.* 对 $\Phi\in V$，令 $\Phi_D=\Phi|_D\in\mathcal H$。由 (F2)，$\tau_\pm\Phi_D$ 等于 $\Phi|_{\Omega_\pm}$ 在 $\Gamma_\pm$ 上的迹。所以 $\Phi_0:=\Phi-U_\lambda\Phi_D$ 在 $D$ 上为零，在 $\Omega_\pm$ 上属于 $H^1_{\beta_0,0}$，并且由 (F2) 有 $\Phi_0\in V$。由 $E_\pm(\lambda)$ 的定义，对任意 $u\in\mathcal H$，$s_\lambda(U_\lambda u,\Phi_0)=0$。

1. *映入.* 设 $u\in N(\lambda)$，$U=U_\lambda u\in V$。对任意 $\Phi\in V$，
   $$s_\lambda(U,\Phi)=s_\lambda(U,U_\lambda\Phi_D)+s_\lambda(U,\Phi_0)=t_\lambda(u,\Phi_D)=0,$$
   即 $a(U,\Phi)=b(\lambda U,\Phi)$。由 Kato VI.2.1(iii)，$U\in D(A)$ 且 $AU=\lambda U$。
2. *单射.* 若 $U_\lambda u=0$，则 $u=(U_\lambda u)|_D=0$。
3. *满射.* 设 $U\in\ker(A-\lambda)$。由 Kato VI.2.1(i)，$s_\lambda(U,\Phi)=0$ 对 $\Phi\in V$ 成立。
   - 对 $\varphi\in H^1_{\beta_0,0}(\Omega_+)$，其零延拓属于 $V$（(F2)），代入得 $s^{\Omega_+}_\lambda(U|_{\Omega_+},\varphi)=0$。由引理 1 的唯一性，$U|_{\Omega_+}=E_+(\lambda)\tau_+(U|_D)$。$\Omega_-$ 同理。所以 $U=U_\lambda(U|_D)$。
   - 于是 $t_\lambda(U|_D,v)=s_\lambda(U,U_\lambda v)=0$ 对一切 $v$ 成立，即 $U|_D\in N(\lambda)$。$\square$

### 引理 5（$t_\lambda$ 的谱结构）

设 $\lambda\in\mathcal W$，$K=K(\lambda)$。则存在 $p$-正交分解 $\mathcal H=H_-\oplus H_0\oplus H_+$ 与常数 $c_\pm>0$，满足：
- $H_0=N(\lambda)$，$\dim H_-<\infty$，$\dim H_0<\infty$；
- $t_\lambda(u,u)\le-c_-p(u,u)$（$u\in H_-$）；
- $t_\lambda(u,u)\ge c_+p(u,u)$（$u\in H_+$）。

由此：
- $n(\lambda)=\dim H_-$；
- $\nu(\lambda):=\max\{\dim X:\ t_\lambda(u,u)\le0\ \forall u\in X\}=n(\lambda)+z(\lambda)$；
- 若 $z(\lambda)=0$，则 $I-K$ 在 $(\mathcal H,p)$ 上有有界逆。

**证明.**

1. 由紧自伴算子的谱定理（F4），$K$ 的非零特征值 $\kappa_j$ 为实数，各有有限重数，只可能在 $0$ 处聚集；$\mathcal H$ 是 $\ker K$ 与各特征空间的 $p$-正交和。所以 $\kappa_j\ge\tfrac12$ 的只有有限个。
2. 令
   - $H_-$ 为 $\kappa_j>1$ 的特征空间之和；
   - $H_0$ 为 $\kappa_j=1$ 的特征空间；
   - $H_+$ 为其余（$\ker K$ 与 $\kappa_j<1$ 的特征空间）的闭包和。

   它们都是 $K$ 的不变子空间，彼此 $p$-正交，所以 $t_\lambda$ 在不同块之间的交叉项为零。
3. 取
   $$c_-=\min\{\kappa_j-1:\kappa_j>1\}\ (H_-\ne\{0\}),\quad c_-=1\ (H_-=\{0\}),\qquad c_+=1-\max\big(\{\tfrac12\}\cup\{\kappa_j:\tfrac12\le\kappa_j<1\}\big).$$
   两者都是有限集上的最值（或取定的常数），所以为正；$H_-=\{0\}$ 时 $H_-$ 上的不等式是空的。由 $t_\lambda(u,u)=p((I-K)u,u)$ 得到 $H_\pm$ 上的两个不等式。
4. $t_\lambda(u,\cdot)=p((I-K)u,\cdot)\equiv0$ 当且仅当 $(I-K)u=0$，所以 $N(\lambda)=H_0$。
5. *$n(\lambda)=\dim H_-$.* $H_-$ 是负定子空间，所以 $n(\lambda)\ge\dim H_-$。反之，若 $X$ 负定，则 $X\cap(H_0\oplus H_+)=\{0\}$，因为 $t_\lambda\ge0$ 在 $H_0\oplus H_+$ 上成立（交叉项为零）。$H_0\oplus H_+$ 的余维数是 $\dim H_-$，所以 $\dim X\le\dim H_-$。
6. *$\nu(\lambda)=\dim H_-+\dim H_0$.* 同理：用 $H_-\oplus H_0$（其上 $t_\lambda\le0$）与 $H_+$（其上 $t_\lambda>0$）。
7. 最后一句是 Fredholm 择一（F4）。$\square$

### 引理 6（可逆点属于预解集）

设 $\lambda\in\mathcal W$ 且 $z(\lambda)=0$，则 $\lambda\in\rho(A)$。

**证明.** 由引理 4，$A-\lambda$ 是单射。下证满射。

1. *半导波上的特解.* 给定 $f\in L^2_\rho(B)$，令 $F_\pm=R_\pm(\lambda)(f|_{\Omega_\pm})\in D(A_\pm)$，零延拓后由 (F2) 得 $F\in V$。由 Kato VI.2.1(i)，
   $$s^{\Omega_\pm}_\lambda(F_\pm,\varphi)=b_{\Omega_\pm}(f,\varphi),\qquad\varphi\in H^1_{\beta_0,0}(\Omega_\pm).$$
2. *芯区方程.* 令 $\ell_f(v)=b(f,U_\lambda v)-s_\lambda(F,U_\lambda v)$，它是 $\mathcal H$ 上有界反线性泛函（$U_\lambda:\mathcal H\to V$ 有界）。由 Riesz 表示，$\ell_f(v)=p(r,v)$。由引理 5，存在 $u=(I-K)^{-1}r$，于是 $t_\lambda(u,v)=\ell_f(v)$ 对一切 $v$ 成立。
3. *验证.* 令 $U=F+U_\lambda u\in V$。对 $\Phi\in V$，按引理 4 写 $\Phi=U_\lambda\Phi_D+\Phi_0$：
   $$s_\lambda(U,U_\lambda\Phi_D)=s_\lambda(F,U_\lambda\Phi_D)+t_\lambda(u,\Phi_D)=b(f,U_\lambda\Phi_D),$$
   $$s_\lambda(U,\Phi_0)=\sum_\pm s^{\Omega_\pm}_\lambda(F_\pm,\Phi_0|_{\Omega_\pm})+0=b(f,\Phi_0).$$
   相加得 $a(U,\Phi)=b(\lambda U+f,\Phi)$ 对一切 $\Phi\in V$ 成立。由 Kato VI.2.1(iii)，$U\in D(A)$，$(A-\lambda)U=f$。
4. 于是 $A-\lambda:D(A)\to L^2_\rho(B)$ 是双射。$A$ 自伴，所以是闭的；它的逆闭且处处有定义，由闭图像定理有界，因此 $\lambda\in\rho(A)$。$\square$

## 3. 定理 1 的证明

1. *第 1 条.* 由引理 3(e)、引理 5、引理 4 得到。
2. *局部结构.* 取 $\lambda_0\in\mathcal W$，记 $n_0=n(\lambda_0)$，$z_0=z(\lambda_0)$，$c_\pm$ 为引理 5 中 $\lambda_0$ 处的常数，$c_0=\min(c_-,c_+)$。设 $\lambda\in\mathcal W$，$M_U^2|\lambda-\lambda_0|<c_0$。
   - (i) $n(\lambda)\ge n_0$。在 $H_-(\lambda_0)$ 上，由引理 3(e)，
     $$t_\lambda(u,u)\le(-c_-+M_U^2|\lambda-\lambda_0|)p(u,u)<0\qquad(u\ne0).$$
   - (ii) $\nu(\lambda)\le n_0+z_0$。在 $H_+(\lambda_0)$ 上，$t_\lambda(u,u)\ge(c_+-M_U^2|\lambda-\lambda_0|)p(u,u)>0$（$u\ne0$）。所以任一 $t_\lambda$ 非正子空间与 $H_+(\lambda_0)$ 只交于零，维数不超过其余维数 $n_0+z_0$。
   - (iii) 对 $\lambda_1<\lambda_2$（均在 $\mathcal W$ 中），$n(\lambda_2)\ge n(\lambda_1)+z(\lambda_1)$。取 $X=H_-(\lambda_1)\oplus H_0(\lambda_1)$。对 $u=v+k\in X\setminus\{0\}$，$k$ 属于 $t_{\lambda_1}$ 的核，所以 $t_{\lambda_1}(u,u)=t_{\lambda_1}(v,v)\le0$。由引理 3(f) 与 $b_D(u,u)\ge\|u\|_{L^2(D)}^2>0$，得 $t_{\lambda_2}(u,u)<0$。所以 $X$ 是 $t_{\lambda_2}$ 的负定子空间，维数为 $n(\lambda_1)+z(\lambda_1)$。
3. *由 (i)–(iii) 得到.*
   - 对 $\lambda<\lambda_0$ 且足够近：由 (i)，$n(\lambda)\ge n_0$；由 (iii)（取 $\lambda_1=\lambda$，$\lambda_2=\lambda_0$），$n_0\ge n(\lambda)+z(\lambda)$。所以 $n(\lambda)=n_0$，$z(\lambda)=0$。
   - 对 $\lambda>\lambda_0$ 且足够近：由 (iii)，$n(\lambda)\ge n_0+z_0$；由 (ii) 与引理 5，$n(\lambda)+z(\lambda)\le n_0+z_0$。所以 $n(\lambda)=n_0+z_0$，$z(\lambda)=0$。

   因此 $\{z>0\}$ 在 $\mathcal W$ 中没有聚点。$\mathcal W$ 紧，所以它是有限集 $\lambda^{(1)}<\dots<\lambda^{(r)}$。
4. *第 2 条.*
   - $z(\lambda)>0$ 时，由引理 4，$\lambda$ 是 $A$ 的特征值，重数为 $z(\lambda)<\infty$。
   - $z(\lambda)=0$ 时，由引理 6，$\lambda\in\rho(A)$。
5. *第 3 条.* 由第 3 步：
   - 在 $\mathcal W\setminus\{\lambda^{(i)}\}$ 上 $n$ 局部常值，故在每个相邻点之间的区间上为常数；
   - 在每个 $\lambda^{(i)}$ 处，$n$ 等于左侧的值，右侧的值比它大 $z(\lambda^{(i)})$；
   - 在 $\alpha_+$ 处，$n(\alpha_+)$ 等于其左侧的值；在 $\alpha_-$ 处，右侧的值为 $n(\alpha_-)+z(\alpha_-)$。

   逐段相加，
   $$n(\alpha_+)-n(\alpha_-)=\sum_{\lambda^{(i)}<\alpha_+}z(\lambda^{(i)})=\sum_{\lambda\in[\alpha_-,\alpha_+)}\dim\ker(A-\lambda).\qquad\square$$

**说明.**
- 定理 1 不用导波的周期性，也不用数值 DtN，只用 (P)。
- 由 (iii) 可知，零点穿越都是从正到负：$\lambda$ 增大时，$t_\lambda$ 的特征值只会向下越过零。
- (P) 必须在整个 $\mathcal W$ 上成立。若 $\mathcal W$ 中有 Dirichlet 极点，$\Lambda_\pm(\lambda)$ 在该点发散，引理 3 的连续性失效，计数公式需要另加极点的贡献。本文不处理这种情形。

## 4. 定理 2：端点矩阵

### 4.1 离散数据

$V_h\subset\mathcal H$ 是有限元空间，例如准周期 P3 Lagrange 元，端口上不加约束，基为 $\varphi_1,\dots,\varphi_N$。$v=\sum_jc_j\varphi_j$ 与系数向量 $c\in\mathbb C^N$ 对应。

| 矩阵 | 元素 | 说明 |
|---|---|---|
| $K$ | $K_{ij}=a_D(\varphi_j,\varphi_i)$ | 刚度矩阵 |
| $M^\rho$ | $M^\rho_{ij}=b_D(\varphi_j,\varphi_i)$ | 带权质量矩阵，曲界面上用真实 $\rho$ 积分 |
| $M^1$ | $M^1_{ij}=\int_D\varphi_j\bar\varphi_i$ | 不带权质量矩阵 |
| $B_\pm$ | $(B_\pm)_{kj}=(\tau_\pm\varphi_j)_k=\int_I\varphi_j(x_\pm,y)e^{-\mathrm i\beta_ky}dy$，$\lvert k\rvert\le M$ | $(2M+1)\times N$，端口迹的低阶 Fourier 系数 |
| $W_\pm$ | 选出 $\Gamma_\pm$ 上自由度 | $n_\pm\times N$ |
| $D_\pm(\lambda)$ | 代码中的离散 DtN | $n_\pm\times n_\pm$ Hermitian，墙节点基 |
| $\hat\Lambda_\pm(\lambda)$ | 低阶 Fourier 基下的 DtN | $(2M+1)\times(2M+1)$ Hermitian |

各矩阵的说明：
- 这样定义后有 $a_D(v,v)=c^HKc$，$\hat c_\pm(v):=((\tau_\pm v)_k)_{|k|\le M}=B_\pm c$。
- $D_\pm(\lambda)$ 在 goerisch-v3 的 `direct_native.m::LOCAL_dtn` 中计算：导波单元 Schur 补 $S$，再由有序 QZ 得传播算子 `Pout`，`D = S00 + S01*Pout`。它与 $V_h$ 端口迹的对应（墙网格一致、符号约定：本文 $\Lambda_\pm$ 对衰减模为正）需逐项核对。
- $\hat\Lambda_\pm(\lambda)$ 可以由 $D_\pm$ 作用在 $e^{\mathrm i\beta_ky}$ 的墙迹投影上得到，也可以用别的方法；其误差计入下面的 $\varepsilon^-$。

### 4.2 假设（端点上的数值量，均待认证）

- **(D+)** 在 $\alpha_-$：存在 $\varepsilon^+_\pm\ge0$，使对一切 $v=\sum c_j\varphi_j\in V_h$，
  $$\Lambda_\pm(\alpha_-)(\tau_\pm v,\tau_\pm v)\le(W_\pm c)^HD_\pm(\alpha_-)(W_\pm c)+\varepsilon^+_\pm\|\tau_\pm v\|_{1/2}^2 .$$
- **(D−)** 在 $\alpha_+$：存在 $\varepsilon^-_\pm\ge0$，使对一切 $g\in\mathcal T$，
  $$\Lambda_\pm(\alpha_+)(g,g)\ge\hat g_M^H\hat\Lambda_\pm(\alpha_+)\hat g_M-\varepsilon^-_\pm\|g\|_{1/2}^2,\qquad\hat g_M=(g_k)_{|k|\le M}.$$
- **(C)** 取定 $\sigma>0$，令 $e(u,v)=a_D(u,v)+\sigma\int_Du\bar v$，$P_h$ 为 $\mathcal H$ 到 $V_h$ 的 $e$-正交投影。存在 $C_h$ 使得对一切满足 $e(w,V_h)=0$ 的 $w\in\mathcal H$，有 $\|w\|_{L^2(D)}\le C_h\|w\|_e$。

**端口代表元.** 对 $|k|\le M$ 令 $\kappa_k=(\beta_k^2+\sigma)^{1/2}$，
$$r_{+,k}=\frac{\cosh(\kappa_k(x-x_-))}{\kappa_k\sinh(\kappa_k\ell)}e^{\mathrm i\beta_ky},\qquad r_{-,k}=\frac{\cosh(\kappa_k(x_+-x))}{\kappa_k\sinh(\kappa_k\ell)}e^{\mathrm i\beta_ky}.$$
记 $\delta_{\pm,k}=\|r_{\pm,k}-P_hr_{\pm,k}\|_e$，$\delta_\pm=(\sum_{|k|\le M}\delta_{\pm,k}^2)^{1/2}$。

**引理 7.** $e(u,r_{\pm,k})=(\tau_\pm u)_k$ 对 $u\in\mathcal H$ 成立，且
$$\delta_{\pm,k}^2=\frac{\coth(\kappa_k\ell)}{\kappa_k}-B_{\pm,k}(K+\sigma M^1)^{-1}B_{\pm,k}^H ,$$
其中 $B_{\pm,k}$ 是 $B_\pm$ 的第 $k$ 行。对任意 $v\in V_h$ 还有 $\delta_{\pm,k}\le\|r_{\pm,k}-v\|_e$。

**证明.**
1. 写 $r_{+,k}=f(x)e^{\mathrm i\beta_ky}$。$f$ 是实函数，$f''=\kappa_k^2f$，$f'(x_-)=0$，$f'(x_+)=1$。由 (F1) 的极化形式，只有第 $k$ 个模有贡献：
   $$e(u,r_{+,k})=\int_{x_-}^{x_+}(u_k'f'+\kappa_k^2u_kf)\,dx=[u_kf']_{x_-}^{x_+}=u_k(x_+)=(\tau_+u)_k .$$
2. 于是 $\|r_{+,k}\|_e^2=f(x_+)=\coth(\kappa_k\ell)/\kappa_k$。
3. $P_hr$ 的系数 $c$ 满足 $(K+\sigma M^1)c=\big(\overline{e(\varphi_i,r)}\big)_i=B_{+,k}^H$，所以 $\|P_hr\|_e^2=c^H(K+\sigma M^1)c=B_{+,k}(K+\sigma M^1)^{-1}B_{+,k}^H$。由勾股定理得第一式；第二式即最佳逼近性。
4. $r_{-,k}$ 同理。$\square$

$e$ 不含材料系数，$r_{\pm,k}$ 光滑，所以 $\delta_{\pm,k}$ 随网格加密按高阶速率趋于零。用第一式时差值有抵消，数值上宜用第二式取上界。

### 4.3 两个端点矩阵

**$\alpha_-$ 端（Galerkin 限制）.** 令 $\eta^+=\coth(\ell)(\varepsilon^+_-+\varepsilon^+_+)$，
$$U_h=(1+\eta^+)K+\eta^+M^1-\alpha_-M^\rho+\sum_\pm W_\pm^HD_\pm(\alpha_-)W_\pm .$$

**$\alpha_+$ 端（Ritz 投影加补空间界）.** 设 $\alpha_+\ge0$。令
- $\eta=\coth(\ell)(\varepsilon^-_-+\varepsilon^-_+)<1$；
- $q=\alpha_+\rho+\eta+(1-\eta)\sigma$（$D$ 上的函数），$q_{\max}=\alpha_+\rho_{\max}+\eta+(1-\eta)\sigma$；
- $M^q=\alpha_+M^\rho+(\eta+(1-\eta)\sigma)M^1$。

取 $\theta,\theta_\pm>0$，使
$$c_W:=(1-\eta)-\theta-q_{\max}C_h^2-\sum_\pm\big(\theta_\pm+\|\hat\Lambda_\pm\|\delta_\pm^2\big)\ge0 ,$$
其中 $\|\cdot\|$ 为谱范数（用可计算的上界即可）。令
$$L_h=(1-\eta)(K+\sigma M^1)-\Big(1+\frac{q_{\max}C_h^2}{\theta}\Big)M^q+\sum_\pm B_\pm^H\Big(\hat\Lambda_\pm(\alpha_+)-\frac{\|\hat\Lambda_\pm\|^2\delta_\pm^2}{\theta_\pm}I\Big)B_\pm .$$

**说明.**
- $C_h,\delta\to0$、$\varepsilon\to0$ 时，两者都退化为现有 FEM+DtN 矩阵 $T_h(\lambda)=K-\lambda M^\rho+\text{DtN}$ 在端点处的值。
- $L_h$ 中 $\sigma$ 在主项里抵消：$(1-\eta)(K+\sigma M^1)-(\eta+(1-\eta)\sigma)M^1=(1-\eta)K-\eta M^1$。

**定理 2.** 设 (P)、在 $\alpha_-$ 处 (D+)、在 $\alpha_+$ 处 (D−) 与 (C) 成立，$\alpha_+\ge0$，$\eta<1$，$c_W\ge0$。则

1. $n(\alpha_-)\ge n(U_h)$，$n(\alpha_+)\le n(L_h)$，其中矩阵的 $n$ 是负特征值个数。于是
   $$\sum_{\lambda\in[\alpha_-,\alpha_+)}\dim\ker(A-\lambda)\le n(L_h)-n(U_h).$$
2. 若还有 $n(L_h)-n(U_h)\le1$，且存在 $\|v\|_\rho=1$ 的 $v\in V$ 和容许的 $\hat w$（例如命题 1 的截断通量），使 [[goerisch-width]] 命题 5 的闭区间 $I_1\subset(\alpha_-,\alpha_+)$，则
   - $\sigma(A)\cap[\alpha_-,\alpha_+)=\{\lambda_*\}$；
   - $\lambda_*\in I_1$ 是单重特征值。

   若还有 $\alpha_-\ge0$（[[goerisch-width]] 中 (H) 的定义要求 $0\le\alpha_-$），则 (H) 对 $(\alpha_-,\alpha_+)$ 和 $\lambda=\lambda_*$ 成立。

**证明.**

1. *$n(\alpha_-)\ge n(U_h)$.*
   - 对 $v=\sum c_j\varphi_j\in V_h$，由 (D+) 与引理 2，
     $$\Lambda_\pm(\alpha_-)(\tau_\pm v,\tau_\pm v)\le(W_\pm c)^HD_\pm(W_\pm c)+\varepsilon^+_\pm\coth(\ell)\|v\|_1^2 ,$$
     而 $\|v\|_1^2=c^H(K+M^1)c$。所以 $t_{\alpha_-}(v,v)\le c^HU_hc$。
   - 取 $U_h$ 的负特征向量张成的 $n(U_h)$ 维子空间，它在 $c\mapsto v$ 下的像是 $n(U_h)$ 维的，并且是 $t_{\alpha_-}$ 的负定子空间。
2. *$t_{\alpha_+}$ 的下界形式.* 对 $u\in\mathcal H$，由 (D−) 与引理 2，$\varepsilon^-_\pm\|\tau_\pm u\|_{1/2}^2\le\varepsilon^-_\pm\coth(\ell)\|u\|_1^2$。于是
   $$t_{\alpha_+}(u,u)\ge(1-\eta)a_D(u,u)-\alpha_+b_D(u,u)-\eta\|u\|_{L^2(D)}^2+\sum_\pm\hat c_\pm(u)^H\hat\Lambda_\pm\hat c_\pm(u).$$
   代入 $(1-\eta)a_D=(1-\eta)e-(1-\eta)\sigma\|\cdot\|_{L^2(D)}^2$，得
   $$t_{\alpha_+}(u,u)\ge\ell(u,u):=(1-\eta)e(u,u)-(qu,u)_{L^2(D)}+\sum_\pm\hat c_\pm(u)^H\hat\Lambda_\pm\hat c_\pm(u).$$
3. *分解.* 写 $u=v+w$，$v=P_hu$，$e(v,w)=0$。由 (C)，$\|w\|_{L^2(D)}\le C_h\|w\|_e$。
   - (i) $e(u,u)=e(v,v)+e(w,w)$。
   - (ii) $q\ge0$，所以 $|(qv,w)|\le(qv,v)^{1/2}(qw,w)^{1/2}$，且 $(qw,w)\le q_{\max}C_h^2e(w,w)$。由 Young 不等式，
     $$(qu,u)\le\Big(1+\frac{q_{\max}C_h^2}{\theta}\Big)(qv,v)+(\theta+q_{\max}C_h^2)\,e(w,w).$$
   - (iii) 由引理 7，$\hat c_{\pm,k}(w)=e(w,r_{\pm,k})=e(w,r_{\pm,k}-P_hr_{\pm,k})$，所以 $|\hat c_\pm(w)|\le\delta_\pm\|w\|_e$。于是
     $$\hat c_\pm(u)^H\hat\Lambda_\pm\hat c_\pm(u)\ge\hat c_\pm(v)^H\hat\Lambda_\pm\hat c_\pm(v)-2\|\hat\Lambda_\pm\|\,|\hat c_\pm(v)|\,\delta_\pm\|w\|_e-\|\hat\Lambda_\pm\|\delta_\pm^2e(w,w),$$
     中间项不超过 $\theta_\pm e(w,w)+\theta_\pm^{-1}\|\hat\Lambda_\pm\|^2\delta_\pm^2|\hat c_\pm(v)|^2$。
4. *合并.* 用 $\hat c_\pm(v)=B_\pm c$、$(qv,v)=c^HM^qc$、$e(v,v)=c^H(K+\sigma M^1)c$，得
   $$t_{\alpha_+}(u,u)\ge\ell(u,u)\ge c^HL_hc+c_W\,e(w,w)\ge c^HL_hc ,$$
   其中 $c$ 是 $P_hu$ 的系数。
5. *$n(\alpha_+)\le n(L_h)$.* 设 $X$ 是 $t_{\alpha_+}$ 的负定子空间，$\Pi:X\to\mathbb C^N$ 为 $u\mapsto P_hu$ 的系数。
   - 对 $u\in X\setminus\{0\}$，$\Pi u^HL_h\Pi u\le t_{\alpha_+}(u,u)<0$，所以 $\Pi u\ne0$，$\Pi$ 在 $X$ 上单射。
   - $\Pi X$ 是 $L_h$ 的负定子空间，所以 $\dim X\le n(L_h)$。
6. *第 1 条的计数式.* 由第 1、5 步与定理 1 第 3 条。
7. *第 2 条.*
   - 由命题 5，$\sigma(A)\cap I_1\ne\emptyset$。取其中一点 $\lambda_*$。$I_1\subset(\alpha_-,\alpha_+)\subset\mathcal W$，由定理 1 第 2 条，$\lambda_*$ 是特征值，$z(\lambda_*)\ge1$。
   - 由第 1 条，$[\alpha_-,\alpha_+)$ 中重数之和 $\le1$，所以 $z(\lambda_*)=1$，其余点 $z=0$。
   - 再由定理 1 第 2 条，其余点不属于 $\sigma(A)$。$\square$

**说明.**
1. *$\alpha_+$ 本身可以是特征值.* 定理 2 不需要它不是。(H) 只涉及开区间，而第 1 条统计的是 $[\alpha_-,\alpha_+)$。
2. *数值上判据能否成立.* 当 $t_{\alpha_\pm}$ 在零附近没有特征值时，$n(U_h)$ 与 $n(L_h)$ 应在网格加密、$M$ 增大、$\varepsilon$ 减小时分别取到 $n(\alpha_-)$ 与 $n(\alpha_+)$。这一点本文没有证明；判据失败只说明需要加密或改选端点，不会给出错误结论。
3. *(D−) 的合理性（启发式，未证明）.* $\Lambda_\pm(\alpha)$ 等于对角算子 $\mathrm{diag}\langle k\rangle$ 加上一个相对于它为紧的项（由引理 1(c) 与引理 3(a)），所以：
   - 高阶模上 $\Lambda_\pm$ 接近 $\|\cdot\|_{1/2}^2$，是强正的；
   - 低高阶耦合随 $M$ 增大而变小。

   因此可以期望 (D−) 在 $M$ 适中时以小的 $\varepsilon^-$ 成立。
4. *(D+) 的合理性（启发式，未证明）.* 代码中 $D_\pm$ 是离散半导波上的 Galerkin 能量。在强制情形（$\lambda<\inf\sigma(A_\pm)$）下，它由更小空间上的极小化给出，所以 $\Lambda\le D$ 精确成立。在间隙内能量不定，但高频部分仍由强制部分主导。若 (D+) 难以对粗糙迹认证，可以改用端口迹为低阶 Fourier 模的试探空间：$V_h$ 中端口迹为零的函数，加上 $\chi_\pm(x)e^{\mathrm i\beta_ky}$（$|k|\le M$）。这时 (D+) 只需在 $\mathrm{span}\{e^{\mathrm i\beta_ky}\}_{|k|\le M}$ 上成立，证明与第 1 步相同。
5. *$C_h$.* (C) 中的 $e$ 不含材料系数，所以 $C_h$ 只依赖网格与元次。若 $V_h$ 包含同一网格上的 P1 空间，P1 的投影常数可直接用：与 $V_h$ 正交蕴含与 P1 正交。有界区域上 P1 投影误差常数的已有计算方法能否用于本文的边界条件（端口自然边界、上下准周期）和曲边单元，待核实。

## 5. 需要计算或认证的量

定理 2 把 (H) 的认证拆成下列各项。只有第一项是区间上的谱命题，其余都只在两个端点上计算。

| 项 | 内容 | 现状 |
|---|---|---|
| (P) | $\mathcal W$ 内两个半导波 Dirichlet 算子无谱：导波能带间隙，且截线处无 Dirichlet 表面态（DtN 无极点） | 未认证；能带间隙可沿用 Hoang–Plum–Wieners 2009 的覆盖法（[[isolation-survey]] 第 10 节），表面态的排除没有现成方法 |
| $K,M^\rho,M^1$ | 芯区 FEM 矩阵 | 代码已有；$M^\rho$ 的曲界面积分需包络 |
| $B_\pm$ | 端口迹的低阶 Fourier 系数 | 多项式乘指数，可精确积分 |
| $D_\pm(\alpha_-)$ | 代码的离散 DtN | 代码已有（`LOCAL_dtn`） |
| $\hat\Lambda_\pm(\alpha_+)$ | 低阶 Fourier 基下的 DtN | 由 $D_\pm$ 换基可得 |
| $\varepsilon^+_\pm$ | (D+)：真 DtN 与 $D_\pm$ 在 $V_h$ 迹上的误差 | 未认证，路线第 2 步 |
| $\varepsilon^-_\pm$ | (D−)：真 DtN 在整个迹空间上相对 $\hat\Lambda_\pm$ 的下界误差 | 未认证，路线第 2 步 |
| $C_h$ | 材料无关的投影常数 (C) | 未认证，见第 4.3 节说明 5 |
| $\delta_\pm$ | 端口代表元的逼近误差 | 引理 7 给出公式，可直接计算 |
| $\lVert\hat\Lambda_\pm\rVert$ | 谱范数上界 | 小矩阵，可直接计算 |
| $n(U_h),n(L_h)$ | 两个 $N\times N$ Hermitian 矩阵的负特征值个数 | 需带舍入控制的 $LDL^H$ 或特征值包络；规模与现有 P3 矩阵相同，DtN 块使端口自由度稠密耦合 |
| $I_1$ | 命题 5 的一阶区间 | 已有（P3/RT3，宽约 $10^{-4}$）；需区间算术重算 |

**与现有计算的关系.**
- $U_h$、$L_h$ 都是现有 FEM+DtN 矩阵 $T_h(\lambda)=K-\lambda M^\rho+\text{DtN}$ 在端点处的扰动。
- 若浮点下 $n(T_h(\alpha_+))-n(T_h(\alpha_-))=1$，且两端 $T_h$ 的最小特征值的绝对值离零较远，判据有望在小的 $\varepsilon,C_h,\delta$ 下成立。

这一检查不构成认证，但可以先用浮点做，以决定是否值得投入第 2 步。
