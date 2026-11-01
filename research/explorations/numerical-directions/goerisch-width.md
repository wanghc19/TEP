# Goerisch 区间：成立条件、通量极限与宽度公式（draft，已审查）

本文件整理 goerisch-v1 实验（[[README]] 第 3b 阶段）背后的引理、命题与推论，供证明审查线程审查。作者：Claude（证明从零写出，模式 Proof from scratch）。

## 进度

- 已完成：引理 0、命题 1–3、推论 4 的陈述和证明；与实验数据的对照（第 5 节，不属于证明）。
- 审查：证明审查线程已审（[[goerisch-width-review]]），0 个 blocker、0 个重要、0 个次要问题；Claude 另外更正了 (10.45) 的页码（第 372 页）。
- 2026-11-01 补充：(H) 后加了一条说明，指出 $\alpha_\pm$ 可以取能带间隙的真子区间，并给出宽度随之变化的算例。它只解释 (H) 的适用范围，没有新的证明步骤，未送审查。
- 2026-11-01 新增命题 5（第 4b 节）：不依赖 (H) 的一阶区间。Claude 从零写出；证明审查线程第二轮审查（[[goerisch-width-review]] Round 2）结果为 0 个 blocker、0 个重要、0 个次要问题。
- 未决：命题 3 的修正量 $R$ 只给出用谱分布表示的界，没有给出可由数值验证的界；谱隙端点的认证不在本文件范围内。

## 0. 设定与记号

- 条带 $B=\mathbb R\times(-\tfrac12,\tfrac12)$，横向相位 $\beta_0\in\mathbb R$（实验中 $\beta_0=0.5$）。材料 $\rho\in L^\infty(B)$，$1\le\rho\le\rho_{\max}$（实验中 $\rho_{\max}=17$）。
- $V=H^1_{\beta_0}(B)$：$H^1(B)$ 中满足 $u(\cdot,\tfrac12)=e^{\mathrm i\beta_0}u(\cdot,-\tfrac12)$（迹意义，a.e. $x$）的函数，配 $H^1(B)$ 范数。
- $a(u,\varphi)=\int_B\nabla u\cdot\overline{\nabla\varphi}$，$b(u,\varphi)=\int_B\rho\,u\bar\varphi$，$\|u\|_\rho^2=b(u,u)$。取定 $\gamma>0$，$a_\gamma=a+\gamma b$。由 $1\le\rho\le\rho_{\max}$，$a_\gamma$ 是 $V$ 上与 $H^1$ 等价的内积。
- $A$：$L^2_\rho(B)$（内积 $b$）中由闭形式 $a$（定义域 $V$）确定的非负自伴算子，即 $-\rho^{-1}\Delta$ 加准周期条件。$E(\cdot)$ 是它的谱测度。
- 谱隙假设 **(H)**：$0\le\alpha_-<\alpha_+<\infty$，$\sigma(A)\cap(\alpha_-,\alpha_+)=\{\lambda\}$，$\lambda$ 是有限重特征值。记 $\mu=\alpha_-+\gamma$，$\nu=\alpha_++\gamma$，$\ell=\lambda+\gamma$。
  - **说明（2026-11-01 补充）：$\alpha_\pm$ 不必是能带间隙的端点。** (H) 只要求 $(\alpha_-,\alpha_+)$ 中除 $\lambda$ 外没有谱点，它可以是能带间隙的真子区间。区间落在间隙内时，其中没有本质谱，$\lambda$ 是点谱；间隙中别处可以有其他特征值。下文的"谱隙"均指 (H) 中的这个区间 $(\alpha_-,\alpha_+)$，各结论对满足 (H) 的任意 $\alpha_\pm$ 成立；使用时另需 $\alpha_-<\theta<\alpha_+$（命题 2、3 的条件 $\mu<q<\nu$）。
  - 代价是区间变宽。命题 3 的常数 $C=(\lambda+\gamma)(\alpha_+-\alpha_-)/((\lambda-\alpha_-)(\alpha_+-\lambda))$ 随 $\alpha_\pm$ 靠近 $\lambda$ 而增大，宽度约为 $C(\theta-\lambda)$。以 P3 试探函数（$\theta-\lambda\approx7.02\times10^{-10}$，$\gamma=1$）为例：取整个未认证间隙 $(1.3174^2,2.1875^2)$ 时 $C\approx6.40$，宽度约 $4.5\times10^{-9}$；取 $\lambda\pm0.3$ 时 $C\approx22.9$，宽度约 $1.6\times10^{-8}$；取 $\lambda\pm0.1$ 时 $C\approx68.6$，宽度约 $4.8\times10^{-8}$。
  - 所以认证 (H) 只需证明 $\lambda$ 附近一段距离内没有其他谱点，并且这段区间不碰本质谱，不需要证明整个间隙只有一个特征值。本说明只是对 (H) 适用范围的解释，没有新的证明步骤，未送审查。
- 试探函数 $v\in V$，$\|v\|_\rho=1$。记
  $$q=a_\gamma(v,v),\qquad\theta=q-\gamma=\frac{a(v,v)}{b(v,v)} .$$
- 源解 $z\in V$：$a_\gamma(z,\varphi)=b(v,\varphi)$ 对一切 $\varphi\in V$ 成立，即 $z=(A+\gamma)^{-1}v$。记 $G=a_\gamma(z,z)$。
- 辅助空间 $X=L^2(B)^2\times L^2(B)$，半双线性形式 $b_X((p,r),(p',r'))=\int_B p\cdot\overline{p'}+\gamma\rho\,r\overline{r'}$，算子 $T:V\to X$，$T\varphi=(\nabla\varphi,\varphi)$。
- 文献：Nakao, Plum, Watanabe (2019)，[[ref/ref_data/books/Nakao2019.pdf|本地]]，页码为印刷页（PDF 页 = 印刷页 + 6）。书中问题 (10.45)（第 372 页）是 $\langle u,\varphi\rangle=\Lambda B[u,\varphi]$；书中的位移参数记作 $\rho$，本文改记为 $t$，以免与材料 $\rho$ 冲突。

## 1. 引理 0：与书中设定的对应

**引理 0.** 取 $H=V$，$\langle u,\varphi\rangle=a_\gamma(u,\varphi)$，$B[u,\varphi]=b(u,\varphi)$。则

1. $(H,\langle\cdot,\cdot\rangle)$ 是无穷维可分复 Hilbert 空间，$B$ 是 $H$ 上有界、Hermitian、正定的形式，满足书中第 372 页对 (10.45) 的要求；
2. 书中 (10.46)–(10.47)（第 373–374 页）定义的自伴算子 $A_{\rm book}$ 与 $A+\gamma$ 酉等价。所以 (10.45) 的谱、本质谱、特征值及其重数，恰为 $A$ 的相应对象平移 $\gamma$；
3. 书中 (10.52) 的 $w_1$（取 $\tilde u_1=v$）就是 $z$。书中 (10.54) 的 $A_0,A_1,A_2$ 依次为 $G$、$1$、$q$。

**证明.**

1. $a_\gamma$ 与 $H^1$ 内积等价，$V$ 是 $H^1(B)$ 的闭子空间（迹算子连续），所以完备且可分；它显然是无穷维的。$|b(u,\varphi)|\le\rho_{\max}\|u\|_0\|\varphi\|_0\le\rho_{\max}\gamma^{-1}\|u\|\,\|\varphi\|$，其中 $\|u\|^2=a_\gamma(u,u)\ge\gamma\|u\|_\rho^2\ge\gamma\|u\|_0^2$。$b(u,u)\ge\|u\|_0^2>0$（$u\ne0$）。
2. 书中 (10.46) 定义 $T_{\rm book}u\in H$ 满足 $\langle\varphi,T_{\rm book}u\rangle=B[\varphi,u]$ 对一切 $\varphi\in H$ 成立。由 $A$ 的定义，$(A+\gamma)^{-1}u\in V$，且 $a_\gamma(\varphi,(A+\gamma)^{-1}u)=b(\varphi,u)$ 对 $\varphi\in V$ 成立，所以 $T_{\rm book}=(A+\gamma)^{-1}|_V$。由形式表示定理，$U=(A+\gamma)^{1/2}$ 是 $(V,a_\gamma)$ 到 $L^2_\rho(B)$ 的酉映射，并且 $UT_{\rm book}U^{-1}=(A+\gamma)^{-1}$。所以 $A_{\rm book}=T_{\rm book}^{-1}=U^{-1}(A+\gamma)U$。酉等价保持谱、本质谱、特征值及其重数。
3. 书中 (10.52) 写作 $\langle w_1,\varphi\rangle=B[\tilde u_1,\varphi]$，即 $a_\gamma(w_1,\varphi)=b(v,\varphi)$，所以 $w_1=z$。代入 (10.54)（第 375 页）：$A_0=\langle w_1,w_1\rangle=G$，$A_1=B[v,v]=1$，$A_2=\langle v,v\rangle=q$。$\square$

## 2. 命题 1：截断通量给出的区间

**命题 1.** 设 (H) 成立，$v\in V$，$\|v\|_\rho=1$。取盒子 $D=(-X,X)\times(-\tfrac12,\tfrac12)$ 和 $p\in H(\operatorname{div},D)$，满足

- (P1) $p\cdot n\in L^2(\partial D)$；
- (P2) 在两条截线 $x=\pm X$ 上 $p\cdot n=0$；
- (P3) $p_y(x,\tfrac12)=e^{\mathrm i\beta_0}p_y(x,-\tfrac12)$，a.e. $x\in(-X,X)$。

把 $p$ 零延拓到 $B$，记为 $\tilde p$。令
$$J=\int_B|\tilde p|^2+\int_B\frac{|\operatorname{div}\tilde p+\rho v|^2}{\gamma\rho}
=\int_D|p|^2+\int_D\frac{|\operatorname{div}p+\rho v|^2}{\gamma\rho}+\frac1\gamma\int_{B\setminus D}\rho|v|^2 ,$$
并对 $t\in\{\mu,\nu\}$ 令 $\hat B_1(t)=1-tJ$，$\hat B_2(t)=q-2t+t^2J$。若符号条件

- (C) $\hat B_2(\mu)>0$，$\hat B_2(\nu)>0$，$\hat\kappa(\mu):=\hat B_1(\mu)/\hat B_2(\mu)>1/(\nu-\mu)$，$\hat\kappa(\nu):=\hat B_1(\nu)/\hat B_2(\nu)<-1/(\nu-\mu)$

成立，则
$$\lambda\in[E(\nu),E(\mu)],\qquad E(t)=\frac{q-t}{1-tJ}-\gamma .$$

**证明.**

*第 1 步：零延拓属于 $H(\operatorname{div},B)$，且 $\operatorname{div}\tilde p=\mathbf 1_D\operatorname{div}p$。* 对 $\phi\in C_c^\infty(B)$，在 Lipschitz 区域 $D$ 上用 Green 公式，再用 (P1) 把边界对偶写成 $L^2(\partial D)$ 积分：
$$\int_D p\cdot\nabla\phi+\int_D(\operatorname{div}p)\phi=\int_{\partial D}(p\cdot n)\phi .$$
截线上 $p\cdot n=0$（P2）；在 $y=\pm\tfrac12$ 上 $\phi=0$，因为 $\phi$ 的支集在开集 $B$ 内。所以右端为零，即 $\int_B\tilde p\cdot\nabla\phi=-\int_B\mathbf 1_D(\operatorname{div}p)\phi$。

*第 2 步：容许性 (10.69)。* 令 $\hat w=\big(\tilde p,(\operatorname{div}\tilde p+\rho v)/(\gamma\rho)\big)$。由 $\rho\ge1$ 和第 1 步知 $\hat w\in X$，并且 $b_X(\hat w,\hat w)=J$。对 $\varphi\in V$，
$$b_X(\hat w,T\varphi)=\int_B\tilde p\cdot\overline{\nabla\varphi}+\int_B(\operatorname{div}\tilde p)\bar\varphi+b(v,\varphi).$$
前两项之和等于 $\int_D p\cdot\overline{\nabla\varphi}+(\operatorname{div}p)\bar\varphi=\int_{\partial D}(p\cdot n)\bar\varphi$（同上，$\varphi|_D\in H^1(D)$）。截线部分为零；上下两边的贡献为
$$\int_{-X}^{X}p_y(x,\tfrac12)\overline{\varphi(x,\tfrac12)}\,dx-\int_{-X}^{X}p_y(x,-\tfrac12)\overline{\varphi(x,-\tfrac12)}\,dx=0,$$
因为由 (P3) 和 $\varphi\in V$，第一个被积函数等于 $e^{\mathrm i\beta_0}p_y(x,-\tfrac12)\,e^{-\mathrm i\beta_0}\overline{\varphi(x,-\tfrac12)}$。所以 $b_X(\hat w,T\varphi)=b(v,\varphi)=B[v,\varphi]$，这正是书中 (10.69)。

*第 3 步：引理 10.25 的其余条件。* $b_X$ 是 $X$ 上半正定的 Hermitian 形式；$b_X(Tu,T\varphi)=\int\nabla u\cdot\overline{\nabla\varphi}+\gamma\rho u\bar\varphi=a_\gamma(u,\varphi)=\langle u,\varphi\rangle$，即 (10.68)。所以 $N=1$ 时书中 (10.70) 的 $\hat A_0=J$，且由引理 10.25，$J\ge A_0=G$。

*第 4 步：定理 10.29 的假设。* 由引理 0 和 (H)，(10.45) 在 $(\mu,\nu)$ 中的谱恰为有限重特征值 $\ell=\lambda+\gamma$，所以 $(\mu,\nu)$ 中没有本质谱，其中的特征值不聚集，(a) 和 (b) 的聚集条件都成立。又 $\mu=\alpha_-+\gamma>0$，$\nu<\infty$。

还要验证：$\mu$ 和 $\nu$ 都不是以 $\operatorname{span}\{v\}$ 中元素为特征元的特征值。若 $v$ 是 $t$ 对应的特征元（$t\in\{\mu,\nu\}$），则 $q=\langle v,v\rangle=tB[v,v]=t$，且 $z=v/t$，所以 $G=q/t^2=1/t$，从而 $J\ge1/t$，$\hat B_1(t)=1-tJ\le0$。

- 若 $t=\mu$，则 $\hat\kappa(\mu)\le0<1/(\nu-\mu)$，与 (C) 矛盾。
- 若 $t=\nu$，则 $\hat B_2(\nu)=\nu(\nu J-1)$。若 $\nu J=1$，则 $\hat B_2(\nu)=0$，与 (C) 矛盾；否则 $\hat\kappa(\nu)=-1/\nu>-1/(\nu-\mu)$（因 $0<\nu-\mu<\nu$），也与 (C) 矛盾。

*第 5 步：应用定理 10.29（第 386–387 页）。* $N=1$ 时 (10.81) 的矩阵是标量 $\hat B_1(t)=A_1-t\hat A_0=1-tJ$ 和 $\hat B_2(t)=A_2-2tA_1+t^2\hat A_0=q-2t+t^2J$，(10.82)/(10.85) 的唯一特征值是 $\hat\kappa(t)$。

- 由 (C) 中 $\hat\kappa(\mu)>1/(\nu-\mu)$，(10.83) 中 $r=1$。由 (a)，$(\mu,\nu)$ 中至少有一个特征值，最小者 $\lambda_1^+\le\mu+1/\hat\kappa(\mu)$。
- 由 $\hat\kappa(\nu)<-1/(\nu-\mu)$，(10.86) 中 $s=1$。由 (b)，最大者 $\lambda_1^-\ge\nu+1/\hat\kappa(\nu)$。

由第 4 步，$(\mu,\nu)$ 中只有 $\ell$，所以 $\lambda_1^+=\lambda_1^-=\ell$，从而 $\nu+1/\hat\kappa(\nu)\le\ell\le\mu+1/\hat\kappa(\mu)$。由 (C)，$1-\mu J>0$，$1-\nu J<0$，分母不为零。直接计算得
$$t+\frac1{\hat\kappa(t)}=\frac{t(1-tJ)+q-2t+t^2J}{1-tJ}=\frac{q-t}{1-tJ}.$$
两边减去 $\gamma$ 即得结论。$\square$

**注.** 实验中的 RT 通量逐单元是多项式，法向分量在单元间连续，所以满足 (P1)；(P2)、(P3) 是实验代码施加的约束。盒外项 $\gamma^{-1}\int_{B\setminus D}\rho|v|^2$ 在实验中用 $w_d$ 的解析尾部加上界处理，这一实现不在本文件审查范围内。

## 3. 命题 2：通量越准，区间越窄；精确通量给出最窄区间

**命题 2.** 设 (H) 成立，$\mu<q<\nu$（即 $\alpha_-<\theta<\alpha_+$），$J$ 是任一容许 $\hat w$ 给出的值（$b_X(\hat w,T\varphi)=b(v,\varphi)$ 对一切 $\varphi\in V$ 成立），且 $J<1/\mu$。记 $I(J')=[E_{J'}(\nu),E_{J'}(\mu)]$，$E_{J'}(t)=(q-t)/(1-tJ')-\gamma$，宽度
$$W(J')=E_{J'}(\mu)-E_{J'}(\nu)=\frac{(\nu-\mu)(qJ'-1)}{(1-\mu J')(\nu J'-1)} .$$
则

1. $1/\nu<1/q\le G\le J<1/\mu$；
2. $I(G)\subset I(J)$，从而 $W(G)\le W(J)$；
3. $G$ 可以被取到：$\hat w=Tz$ 是容许的，对应通量 $p=\nabla z$，且 $b_X(Tz,Tz)=G$。

所以在一切容许通量中，精确通量 $\nabla z$ 给出最窄的区间，宽度 $W(G)$ 只由试探函数 $v$ 决定。

**证明.**

1. 由引理 10.25，$J\ge G$。由 Cauchy–Schwarz：$1=b(v,v)=a_\gamma(z,v)\le G^{1/2}q^{1/2}$，所以 $G\ge1/q$；又 $q<\nu$，所以 $1/q>1/\nu$。$J<1/\mu$ 是假设。
2. 在 $(1/\nu,1/\mu)$ 上，$E_{J'}(\mu)=(q-\mu)/(1-\mu J')-\gamma$ 的分子 $q-\mu>0$，分母为正且随 $J'$ 递减，所以 $E_{J'}(\mu)$ 随 $J'$ 递增；$E_{J'}(\nu)=(\nu-q)/(\nu J'-1)-\gamma$ 的分子 $\nu-q>0$，分母为正且随 $J'$ 递增，所以 $E_{J'}(\nu)$ 随 $J'$ 递减。由 1，$G,J\in(1/\nu,1/\mu)$ 且 $G\le J$，所以 $I(G)\subset I(J)$。宽度公式由两端相减得到。
3. 由 $a_\gamma$ 的定义，$b_X(Tz,T\varphi)=a_\gamma(z,\varphi)=b(v,\varphi)$，所以 $Tz$ 容许，且 $b_X(Tz,Tz)=a_\gamma(z,z)=G$。由 $-\Delta z+\gamma\rho z=\rho v$（分布意义），$\operatorname{div}\nabla z=\gamma\rho z-\rho v\in L^2(B)$，所以 $(\operatorname{div}\nabla z+\rho v)/(\gamma\rho)=z$，即 $Tz=\big(\nabla z,(\operatorname{div}\nabla z+\rho v)/(\gamma\rho)\big)$。$\square$

**注.** 命题 2 没有说 $I(G)$ 本身满足 (C)；它只说明任何容许通量给出的区间都包含 $I(G)$。命题 1 的盒子截断通量是容许的特例，所以 $W(G)$ 也是它的下限。

## 4. 命题 3：精确通量下的宽度公式

设 $m(\cdot)=b(E(\cdot)v,v)$ 是 $v$ 关于 $A$ 的谱测度，它是 $[0,\infty)$ 上的概率测度。由 $v\in V$，$\int t\,dm=a(v,v)<\infty$。定义
$$R=\int\frac{t-\lambda}{t+\gamma}\,dm(t),\qquad
R_+=\int_{[\alpha_+,\infty)}\frac{t-\lambda}{t+\gamma}\,dm,\qquad
R_-=\int_{[0,\alpha_-]}\frac{\lambda-t}{t+\gamma}\,dm,$$
$$e_+=\int_{[\alpha_+,\infty)}(t-\lambda)\,dm,\qquad d_-=\int_{[0,\alpha_-]}(\lambda-t)\,dm .$$
由 (H)，$m$ 在 $(\alpha_-,\alpha_+)\setminus\{\lambda\}$ 上为零，所以 $R=R_+-R_-$，$\theta-\lambda=e_+-d_-$，且 $R_\pm,e_+,d_-\ge0$。

**命题 3.** 设 (H) 成立，$\mu<q<\nu$，且 $G<1/\mu$（存在满足 (C) 的容许 $J$ 时自动成立，因为 $G\le J<1/\mu$）。则

1. $G=(1-R)/\ell$，且
   $$qG-1=\frac{(\theta-\lambda)-qR}{\ell};$$
2. 精确通量下的宽度为
   $$W(G)=\frac{(\alpha_+-\alpha_-)\,\ell\,\big[(\theta-\lambda)-qR\big]}{(\lambda-\alpha_-+\mu R)(\alpha_+-\lambda-\nu R)} ,$$
   其中两个分母因子都为正；
3. $0\le R_+\le e_+/(\tau+\gamma)$，其中 $\tau\ge\alpha_+$ 是 $m|_{[\alpha_+,\infty)}$ 支集的下确界（该部分为零时取 $R_+=0$）；$d_-/\mu\le R_-\le d_-/(t_0+\gamma)$，其中 $t_0=\inf\sigma(A)\ge0$。

记 $C=\dfrac{(\alpha_+-\alpha_-)(\lambda+\gamma)}{(\lambda-\alpha_-)(\alpha_+-\lambda)}$。当 $\theta\ne\lambda$ 时，2 可以写成
$$W(G)=C(\theta-\lambda)\cdot\frac{1-\varepsilon}{\big(1+\mu R/(\lambda-\alpha_-)\big)\big(1-\nu R/(\alpha_+-\lambda)\big)},\qquad\varepsilon=\frac{qR}{\theta-\lambda}.$$

**推论 4.** 设 (H) 成立，$\mu<q<\nu$。若 $d_-=0$（$v$ 在谱隙下方没有谱分量），则 $\theta\ge\lambda$，$0\le R\le(\theta-\lambda)/(\tau+\gamma)$，并且
$$C(\theta-\lambda)\Big(1-\frac{q}{\tau+\gamma}\Big)\frac{\lambda-\alpha_-}{\lambda-\alpha_-+\mu(\theta-\lambda)/\nu}\;\le\;W(G)\;\le\;C(\theta-\lambda)\,\frac{\alpha_+-\lambda}{\alpha_+-\theta}.$$

**证明（命题 3）.**

1. $z=(A+\gamma)^{-1}v$，所以 $G=a_\gamma(z,z)=b((A+\gamma)z,z)=b(v,(A+\gamma)^{-1}v)=\int(t+\gamma)^{-1}dm$。于是
   $$1-\ell G=\int\Big(1-\frac{\lambda+\gamma}{t+\gamma}\Big)dm=\int\frac{t-\lambda}{t+\gamma}dm=R .$$
   又 $q-\ell=\theta-\lambda$，所以 $\ell(qG-1)=q\ell G-\ell=q(\ell G-1)+(q-\ell)=(\theta-\lambda)-qR$。
2. 由 1，$1-\mu G=(\ell-\mu+\mu R)/\ell=(\lambda-\alpha_-+\mu R)/\ell$，$\nu G-1=(\nu-\ell-\nu R)/\ell=(\alpha_+-\lambda-\nu R)/\ell$。前者为正由假设 $G<1/\mu$；后者为正，因为由 Cauchy–Schwarz（命题 2 证明第 1 步）$G\ge1/q>1/\nu$。代入 $W$ 的公式，并用 $\nu-\mu=\alpha_+-\alpha_-$，得结论。
3. 当 $t\ge\tau$ 时 $0\le(t-\lambda)/(t+\gamma)\le(t-\lambda)/(\tau+\gamma)$，积分得 $R_+$ 的界。当 $t_0\le t\le\alpha_-$ 时 $t+\gamma\in[t_0+\gamma,\mu]$，所以 $(\lambda-t)/\mu\le(\lambda-t)/(t+\gamma)\le(\lambda-t)/(t_0+\gamma)$，积分得 $R_-$ 的界。
   最后的乘积形式由 2 两边除以 $C(\theta-\lambda)=\dfrac{(\alpha_+-\alpha_-)\ell(\theta-\lambda)}{(\lambda-\alpha_-)(\alpha_+-\lambda)}$ 得到。$\square$

**证明（推论 4）.** $d_-=0$ 时 $m$ 在 $[0,\alpha_-]$ 上为零（若 $m$ 在该区间有质量，则 $\lambda-t\ge\lambda-\alpha_->0$ 使 $d_->0$）。于是 $R_-=0$，$R=R_+\ge0$，$\theta-\lambda=e_+\ge0$，且 $R\le e_+/(\tau+\gamma)=(\theta-\lambda)/(\tau+\gamma)\le(\theta-\lambda)/\nu$。由 $R\ge0$，$G=(1-R)/\ell\le1/\ell<1/\mu$，所以命题 3 的假设 $G<1/\mu$ 自动成立。

- 上界：$1-\varepsilon\le1$，$1+\mu R/(\lambda-\alpha_-)\ge1$；又 $\nu R\le\theta-\lambda$，所以 $\alpha_+-\lambda-\nu R\ge\alpha_+-\theta>0$。
- 下界：$\varepsilon=qR/(\theta-\lambda)\le q/(\tau+\gamma)$；$\lambda-\alpha_-+\mu R\le\lambda-\alpha_-+\mu(\theta-\lambda)/\nu$；$1-\nu R/(\alpha_+-\lambda)\le1$。

代入命题 3 的乘积形式即得。（$\theta=\lambda$ 时 $R=0$，$W(G)=0$，两边也成立。）$\square$

**解读.** 精确通量下，宽度约为 $C(\theta-\lambda)$，即试探函数 Rayleigh 商误差的固定倍数。偏差来自三处：

- $\varepsilon$：误差的谱分量离谱隙越远（$\tau\gg q$），$\varepsilon$ 越小；
- $d_-$：误差在谱隙下方的分量；
- $R$ 本身：它与 $\theta-\lambda$ 同阶，所以两个分母修正是 $O(\theta-\lambda)$ 的相对量，可以忽略。

$C$ 只由谱隙端点、$\lambda$ 和 $\gamma$ 决定，与离散无关。

## 4b. 命题 5：不依赖 (H) 的一阶区间（draft，2026-11-01，已审查）

本节**不假设 (H)**，也不需要 $\alpha_\pm$、$\mu$、$\nu$ 或符号条件 (C)。只用第 0 节的设定：$v\in V$，$\|v\|_\rho=1$，$q=a_\gamma(v,v)$，$z=(A+\gamma)^{-1}v$，$G=a_\gamma(z,z)$。称 $\hat w\in X$ **容许**，若 $b_X(\hat w,T\varphi)=b(v,\varphi)$ 对一切 $\varphi\in V$ 成立；记 $J=b_X(\hat w,\hat w)$。命题 1 第 1–2 步没有用到 (H)，所以满足 (P1)–(P3) 的盒子截断通量给出容许的 $\hat w$，其 $J$ 就是命题 1 中的表达式。

**命题 5.** 设 $\hat w$ 容许，$\delta:=qJ-1$。则 $\delta\ge0$，并且 $A$ 的谱与闭区间
$$I_1=\Big[\,q\Big(1+\tfrac\delta2-\sqrt{\delta+\tfrac{\delta^2}4}\Big)-\gamma,\;\;q\Big(1+\tfrac\delta2+\sqrt{\delta+\tfrac{\delta^2}4}\Big)-\gamma\,\Big]$$
相交：$\sigma(A)\cap I_1\neq\varnothing$。$I_1$ 的宽度为 $q\sqrt{\delta(4+\delta)}$。

若另有区间 $(\beta_-,\beta_+)$ 满足 $(\beta_-,\beta_+)\cap\sigma_{\rm ess}(A)=\varnothing$ 且 $I_1\subset(\beta_-,\beta_+)$，则 $I_1$ 中至少有一个 $A$ 的有限重孤立特征值。

**证明.**

*第 1 步：$G\le J$，且 $1\le qG\le qJ$。* 由 $T$ 和 $b_X$ 的定义，$b_X(Tz,Tz)=a_\gamma(z,z)=G$。由容许性取 $\varphi=z$，再在 $z$ 的定义 $a_\gamma(z,\varphi)=b(v,\varphi)$ 中取 $\varphi=z$：
$$b_X(\hat w,Tz)=b(v,z)=a_\gamma(z,z)=G .$$
$b_X$ 是 $X$ 上半正定的 Hermitian 形式，Cauchy–Schwarz 不等式对它成立，所以 $G=|b_X(\hat w,Tz)|\le J^{1/2}G^{1/2}$，即 $G\le J$（$G=0$ 时显然）。又 $1=b(v,v)=a_\gamma(z,v)\le G^{1/2}q^{1/2}$（$a_\gamma$ 的 Cauchy–Schwarz），所以 $qG\ge1$。于是 $\delta=qJ-1\ge qG-1\ge0$。

*第 2 步：谱表示。* 令 $m(\cdot)=b(E(\cdot)v,v)$。它是 Borel 概率测度，$m(\mathbb R\setminus\sigma(A))=0$，且 $\sigma(A)\subset[0,\infty)$。因为 $v\in V$ 属于 $A$ 的形式定义域，$\int t\,dm=a(v,v)<\infty$，所以 $q=\int(t+\gamma)\,dm$。由命题 3 证明第 1 步（那里没有用 (H)），$G=\int(t+\gamma)^{-1}dm$。

*第 3 步：一个非负积分。* 对 $t\ge0$ 令 $f(t)=(t+\gamma-q)^2/(t+\gamma)\ge0$。展开平方：
$$\int f\,dm=\int(t+\gamma)\,dm-2q\int dm+q^2\int\frac{dm}{t+\gamma}=q-2q+q^2G=q(qG-1).$$
三个积分都有限（第 2 步，且 $(t+\gamma)^{-1}\le\gamma^{-1}$），所以展开合法。由第 1 步，$\int f\,dm\le q\delta$。

*第 4 步：存在谱点。* 若对一切 $t\in\sigma(A)$ 都有 $f(t)>q\delta$，则 $f-q\delta$ 在 $m$-几乎处处为正，而 $m$ 是概率测度，所以 $\int(f-q\delta)\,dm>0$，与第 3 步矛盾。所以存在 $t^*\in\sigma(A)$ 使 $f(t^*)\le q\delta$。记 $\ell^*=t^*+\gamma>0$，则
$$(\ell^*)^2-(2q+q\delta)\,\ell^*+q^2\le0 .$$
这个二次式的判别式为 $(2q+q\delta)^2-4q^2=q^2\delta(4+\delta)\ge0$，两根为 $q\big(1+\tfrac\delta2\pm\sqrt{\delta+\tfrac{\delta^2}4}\big)$，所以 $\ell^*$ 在两根之间，即 $t^*\in I_1$。宽度为两根之差 $2q\sqrt{\delta+\delta^2/4}=q\sqrt{\delta(4+\delta)}$。

*第 5 步：点谱。* 设 $t^*\in\sigma(A)\cap I_1\subset(\beta_-,\beta_+)$。因为 $(\beta_-,\beta_+)$ 不含本质谱，$t^*\in\sigma(A)\setminus\sigma_{\rm ess}(A)$。按自伴算子本质谱的标准定义，$\sigma(A)\setminus\sigma_{\rm ess}(A)$ 恰为离散谱，即有限重孤立特征值的集合。$\square$

**注.**

1. **与命题 1 的区别。** 命题 5 不需要 (H)，也不需要知道 $\lambda$ 附近其他谱点的位置；要说明区间里是点谱，只需认证一个不含本质谱、包住 $I_1$ 的区间。代价是区间宽度是一阶的：$\delta$ 很小时宽度约为 $2q\sqrt\delta$；而在 (H) 下，命题 1 的宽度约为 $C\,q\,\delta$（命题 3 加上 $J\approx G$）。
2. **通量的作用。** 由第 1 步，精确通量 $\nabla z$（命题 2 第 3 项）给出最小的 $\delta=qG-1$，从而最窄的 $I_1$。若 (H) 成立且 $R$ 可以忽略，由命题 3 第 1 项，$qG-1\approx(\theta-\lambda)/\ell$，所以最窄的 $I_1$ 宽约 $2q\sqrt{(\theta-\lambda)/\ell}\approx2\sqrt{q(\theta-\lambda)}$，与试探函数的能量误差同阶。这一条是解释，不是命题。
3. **与已有结果的关系（2026-11-02 查新后补充）。** 命题 5 等价于 D. Weinstein 定理（Nakao–Plum–Watanabe 2019，定理 10.6，第 356 页：$\tilde u\in D(A)$，$\delta=\|A\tilde u-\tilde\lambda\tilde u\|/\|\tilde u\|$，则 $[\tilde\lambda-\delta,\tilde\lambda+\delta]$ 含 $\sigma(A)$ 中的点）应用于算子 $B_q=C^{1/2}-qC^{-1/2}$，其中 $C=A+\gamma$：$\|B_qv\|_\rho^2=q-2q+q^2G=q(qG-1)$，再经映射 $\ell\mapsto(\ell-q)/\sqrt\ell$ 拉回，即得 $I_1$。查新见 [[isolation-survey]] S1；没有找到用 $q,J$ 写出的同一公式，但原理是已知的，命题 5 不作为新结果。
4. **数值例子（不属于证明）。** goerisch-v3 run-003 的 P3/RT3：$q=3.4287286707248676$，平方积分给出 $\delta=2.13952\times10^{-10}$，得 $I_1=[2.4286785187,\ 2.4287788235]$，宽 $1.003\times10^{-4}$，包含 $\mu_{\rm BIE}$。同一数据在 (H) 下（取整个未认证间隙）的命题 1 区间宽 $4.70\times10^{-9}$。

## 5. 与实验数据的对照（不属于证明）

数据来自 `test/numerical-directions/goerisch-v1/` 的 run-017 至 run-022。$\lambda$ 用 $\mu_{\rm BIE}=2.428728670022710$ 代替，谱隙端点 $\alpha_-=1.3174^2$、$\alpha_+=2.1875^2$ 未认证，$\gamma=1$，全部为浮点计算。

- $C=6.4014$。
- R（$w_d$，$\theta-\lambda=2.944\times10^{-8}$）：预测 $C(\theta-\lambda)=1.8848\times10^{-7}$；实测宽度（RT3、加密 RT2、RT4）为 $1.8863$、$1.8862$、$1.8860\times10^{-7}$。实测 $qJ-1$ 与 $(\theta-\lambda)/q$ 之比为 1.0008、1.0008、1.0007。
- D（截断 FEM 场，$\theta-\lambda=5.623\times10^{-7}$）：预测 $3.5992\times10^{-6}$；实测 $3.5989$、$3.5989$、$3.5989\times10^{-6}$。比值为 0.99992、0.99994、0.99991。

由命题 3，$\ell(qJ-1)=(\theta-\lambda)-qR+q\ell(J-G)$，其中 $J-G\ge0$。所以这些比值与 1 的差，等于 $-\varepsilon$ 加上通量误差项，再加上用 $\mu_{\rm BIE}$ 代替 $\lambda$ 引起的偏差。D 的比值小于 1，说明对 D 有 $\varepsilon\ge8\times10^{-5}$（在 $\mu_{\rm BIE}$ 足够准的前提下）。两者都表明 $|\varepsilon|\lesssim10^{-3}$，即两个试探函数的误差主要落在远高于谱隙的谱分量上。这是对数据的解释，不是证明。

## 6. 审查范围

第二轮审查（2026-11-01）只审命题 5（第 4b 节）。第一轮审查范围：引理 0、命题 1、命题 2、命题 3、推论 4 的陈述与证明，以及对 Nakao2019 第 372–375 页 (10.45)–(10.54)、第 380 页引理 10.25、第 386–387 页定理 10.29 的引用是否准确、假设是否逐条满足。

不在范围内：第 5 节的数值对照；谱隙假设 (H) 本身是否成立（端点认证）；实验代码与盒外尾项的实现；区间算术；新颖性与写作风格。
