# 真实二维条带的最小连续计数定理

日期：2026-10-28。任务模式：**Proof from scratch**。本文件中新写出证明，不改写既有理论。计数公式是 Fliss 2013、Klindworth–Schmidt–Fliss 2014 的精确约化、有限负指数和质量导数结构的标准推论；**不主张其为新定理机制**。本轮证明的是下述假设下的命题，不是当前算例已满足这些假设的证书。

关联：[[research/explorations/spectral-counting/counting_methods_comparison]]；计算提升见 [[research/explorations/spectral-counting/continuous_vs_discrete_gap]]；唯一问题台账见 [[research/explorations/spectral-counting/STATUS]]。

## 1. 模型、空间与假设

固定实数 $\beta$，取条带 $B=\mathbb R\times(0,L)$，在 $y$ 方向施加 $u(x,L)=e^{\mathrm i\beta L}u(x,0)$；导数的准周期条件由算子定义域决定。$H^s_\beta$ 表示相应准周期 Sobolev 空间。$C=(-R,R)\times(0,L)$ 是完整中心区域，$E_-$、$E_+$ 是左右半条带，$\Gamma_\pm$ 为两个人工接口。方向约定：$\nu_\pm$ 是 **从对应 lead 指向中心** 的外法向。

假设：

1. **H1（真实材料）** $\rho$ 实值可测，$0<\rho_{\min}\le\rho\le\rho_{\max}<\infty$，在两端分别等于周期材料 $\rho_\pm$。允许分片常数、二维通道耦合及左右不同的横向周期。共同的 $y$ 周期为 $L$。中心改变仅有界支撑。
2. **H2（严格共同 gap）** $0<a<b$，$[a,b]$ 与两个无限周期端在固定 $\beta$ 下的 projected bulk 谱均不相交。紧区间与这些闭谱有正距离。本质谱等于两端 bulk 谱的并集，是既有精确约化理论的输入。
3. **H3（lead Dirichlet 无极点）** 对每个 $\sigma\in\{-,+\}$，$[a,b]\subset\operatorname{res}(A^D_\sigma)$，其中 $A^D_\sigma$ 是在 $\Gamma_\sigma$ 取零 Dirichlet 条件的半条带算子。**H2 不蕴含 H3。**
4. **H4（目标端点正则）** $a,b\notin\sigma(A(\beta))$。实际认证时，可由后文的端点惯性证书同时证明 H4，而不必预先假定已被数值确认。

在 $\mathcal H=L^2(B,\rho\,dx\,dy)$ 上定义非负自伴算子 $A=A(\beta)$，其闭形式为

$$
\mathfrak a[u,v]=\int_B\nabla u\cdot\overline{\nabla v},
\qquad D(\mathfrak a)=H^1_\beta(B).
$$

其作用为 $Au=-\rho^{-1}\Delta u$，$D(A)=H^2_\beta(B)$。最后这个等式使用主部为常系数 Laplacian、$\rho$ 正有界；不是把一般散度型材料强行视为 $H^2$。分片描述下传输条件是场及普通法向导数连续，不能改成 $\rho\partial_\nu u$ 连续。$A^D_\sigma$ 用同一形式在 $H^1_\beta(E_\sigma)$ 的零墙迹子空间定义。

中心空间 $V=H^1_\beta(C)$。迹空间为 $X=H^{1/2}_\beta(0,L)$，反对偶为 $X^*=H^{-1/2}_\beta(0,L)$；$\gamma_\sigma:V\to X$。所有形式对第一个变量线性。$n_-(t)$ 是形式 $t$ 严格负定子空间的最大维数，重数计入。

## 2. 精确 DtN 与正主部

H3 下定义唯一的 $L^2$ 半条带延拓

$$
P_\sigma(\mu):X\longrightarrow H^1_\beta(E_\sigma),\qquad
(-\Delta-\mu\rho_\sigma)P_\sigma(\mu)g=0,
\quad \gamma P_\sigma(\mu)g=g.
$$

它位于无限端的平方可积解空间；在 gap 内也可由衰减 Bloch 表述，但本证明不需要构造有限维传递矩阵。定义

$$
D_\sigma(\mu)g=\partial_{\nu_\sigma}P_\sigma(\mu)g\in X^*.
$$

这是弱法向迹；不要求任意 $g\in X$ 产生经典点值法导数。

**引理 L1（解析性及紧余项）。** 任取 $c>0$，设

$$
q_n=\beta+\frac{2\pi n}{L},\qquad
\kappa_n=(q_n^2+c)^{1/2},\qquad
\Lambda_c g=\sum_{n\in\mathbb Z}\kappa_n g_n L^{-1/2}e^{\mathrm iq_n y}.
$$

则 $D_\sigma(\mu):X\to X^*$ 在 H3 窗口的一个复邻域中解析，实 $\mu$ 时自伴，且 $D_\sigma(\mu)-\Lambda_c$ 紧。

**Proof.** 在每个 lead 使用向外距离 $s\ge0$。常系数参考延拓为

$$
P_c^0g=\sum_n g_n e^{-\kappa_n s}L^{-1/2}e^{\mathrm iq_n y},
\qquad (-\Delta+c)P_c^0g=0.
$$

它有界 $X\to H^1$，且紧 $X\to L^2$：$L^2$ 范数平方为 $\sum_n|g_n|^2/(2\kappa_n)$，而 $X$ 范数等价于 $\sum_n\kappa_n|g_n|^2$，故高 Fourier 模态尾部一致趋零。取半条带加权空间 $\mathcal H_\sigma=L^2(E_\sigma,\rho_\sigma)$，可直接写

$$
P_\sigma(\mu)g=P_c^0g+
(A^D_\sigma-\mu)^{-1}(\mu+c/\rho_\sigma)P_c^0g. \tag{1}
$$

修正项为零迹，满足所需非齐次方程；唯一性来自 H3。预解式 $\mathcal H_\sigma\to D(A^D_\sigma)$ 的图范数有界，从而给出 $X\to H^1$ 的解析性及 $X\to L^2$ 的紧性。实参数的 Green 恒等式给出自伴性，以及

$$
\langle(D_\sigma(\mu)-\Lambda_c)g,h\rangle
=-\int_{E_\sigma}(\mu\rho_\sigma+c)
P_\sigma(\mu)g\,\overline{P_c^0h}. \tag{2}
$$

右端是一对有界 $L^2$ 映射的组合，其中至少一个紧，故得到 $X\to X^*$ 的紧算子。弱 Green 恒等式可先在光滑迹上证明，再由连续性延拓。式 (1) 和 (2) 也给出所宣称的算子值解析性。证毕。

**注意。** $\Lambda_c$ 仅为证明及认证选择的正参考算子，没有替换真实二维材料；所有通道耦合都保留在紧余项中。此证明不要求材料在切口附近常数，也不调用伪微分符号演算。

## 3. 完整中心形式与重数对应

定义

$$
t_\mu[u,v]=\int_C\nabla u\cdot\overline{\nabla v}
-\mu\int_C\rho u\bar v
+\sum_{\sigma=\pm}\langle D_\sigma(\mu)\gamma_\sigma u,\gamma_\sigma v\rangle. \tag{3}
$$

引入固定的强制内积

$$
b_c[u,v]=\int_C(\nabla u\cdot\overline{\nabla v}+c u\bar v)
+\sum_{\sigma=\pm}\langle\Lambda_c\gamma_\sigma u,\gamma_\sigma v\rangle. \tag{4}
$$

它等价于 $H^1(C)$ 内积。令 $T_\mu:V\to V$ 满足 $b_c[T_\mu u,v]=t_\mu[u,v]$。

**引理 L2（有限负指数）。** $T_\mu$ 是有界自伴 Fredholm 算子，且 $T_\mu-I$ 紧；因此 $n_-(t_\mu)<\infty$，$\ker T_\mu$ 有限维。

**Proof.** 式 (3) 减式 (4) 中，中心质量项通过紧嵌入 $H^1(C)\hookrightarrow L^2(C)$ 分解，边界项由 L1 紧。经 $b_c$ 的 Riesz 同构归一化，即 $I+$ 紧自伴算子；其本质谱仅有 $1$，负谱与零空间有限维。证毕。

**引理 L3（精确核双射）。** H1、H3 下，限制到中心给出

$$
\ker(A-\mu)\cong\ker T_\mu. \tag{5}
$$

**Proof.** 从右侧的 $u$ 出发，以 $P_\pm(\mu)\gamma_\pm u$ 拼接两端。相同迹保证拼接场 $U\in H^1_\beta(B)$，L1 保证尾部 $L^2$。中心测试和任意墙迹测试分别给出体方程及两侧法向通量平衡，所以对全局紧支撑弱测试有 $-\Delta U=\mu\rho U$。右端在 $L^2$，条带的 Fourier 椭圆正则性给出 $U\in H^2_\beta(B)=D(A)$。反过来，全局本征函数的两端由 H3 唯一地等于这些延拓；Green 恒等式给出 (3) 的核条件。若中心限制为零，则两端零迹解由 H3 也为零，故双射且保持核维数。证毕。

这里没有使用中心 Dirichlet 逆。**中心 Dirichlet 本征值可以位于区间内部，甚至与端点相同；只要完整形式可逆，便不影响定理。** 全部中心自由度保留，因此不另行假设“无隐藏中心模态”。这与把中心也消去后只保留墙迹的做法不同。

## 4. 负 crossing form 和计数

**引理 L4（质量导数）。** 对实 $\mu\in[a,b]$ 及 $u,v\in V$，

$$
t'_\mu[u,v]=-
\int_C\rho u\bar v-
\sum_{\sigma=\pm}\int_{E_\sigma}\rho_\sigma
P_\sigma(\mu)\gamma_\sigma u\,
\overline{P_\sigma(\mu)\gamma_\sigma v}. \tag{6}
$$

尤其对非零 $u$，$t'_\mu[u,u]<0$。

**Proof.** $D_\sigma(\mu)$ 的二次型是其 Poisson 解的体能量减 $\mu$ 倍质量。微分后，延拓的导数具有零墙迹；原方程的弱形式使两项交叉导数消失，剩余 $-\int\rho_\sigma |P_\sigma(\mu)g|^2$。解析性已由 L1 建立，故可微分；极化给出双线性版本。加上中心项即 (6)。中心质量严格正，给出严格性。证毕。

**定理 SC1（无 lead 极点的连续区间计数）。** H1–H4 下，

$$
\boxed{\displaystyle
\operatorname{rank}\mathbf1_{(a,b)}(A(\beta))
=n_-(t_b)-n_-(t_a).} \tag{7}
$$

右端是两个有限整数之差。若差为 $1$，区间内恰有一个本征值且几何、代数重数均为 $1$；差为 $0$ 或更大时按相应整数解释。

**Proof.** L2 给出解析自伴 Fredholm 路径 $T_\mu$。在任意零点 $\mu_0$，按 $V=Z\oplus Z^{\perp_{b_c}}$ 分块，其中 $Z=\ker T_{\mu_0}$。在补空间上的块于 $\mu_0$ 可逆，局部仍可逆。消去补空间得到有限维自伴 Schur 算子 $S(\mu)$；由于零点处交叉块为零，

$$
S(\mu_0)=0,\qquad
b_c[S'(\mu_0)z,z]=t'_{\mu_0}[z,z]<0\quad(0\ne z\in Z).
$$

有限维性使此负定性一致，故零点孤立，$\mu$ 增大穿过 $\mu_0$ 时恰有 $\dim Z$ 个正方向变负。补空间块的惯性在此邻域不变。紧区间上零点不能无限积聚：积聚极限必为非可逆点，而刚证明每个这样的点局部孤立。H4 排除端点，故求和得到负指数总增量等于全部核维数之和。

H2 及既有 essential-spectrum 结论保证区间谱为离散本征值；L3 保持每个核维数。自伴算子没有 Jordan 链，故核维数等于谱投影秩。于是得到 (7)，并得到差为 $1$ 时的简单性。证毕。

本证明在完整中心 $H^1$ 空间 $V$ 上进行，并保留无限维 Sobolev 迹；所需有限维化仅发生在 Fredholm 算子的有限维核附近。没有假定边界算子具有有限 deficiency index，也没有将无限波导的两个无限负指数相减。

## 5. 离散矩阵及不能省略的中心项

令 $V_h\subset V$ 为相容中心 FEM 空间。**若边界算子精确**，Galerkin 矩阵为

$$
B_h(\mu)_{ij}=t_\mu[\phi_j,\phi_i].
$$

实际 FEM＋DtN 给出的是近似矩阵

$$
\widehat T_h(\mu)=K_c-\mu M_c+
E_W^*\operatorname{diag}(D_{-,h}(\mu),D_{+,h}(\mu))E_W. \tag{8}
$$

两者不能不加误差证明就等同。若离散 lead 确实来自一个相容无限 FEM 模型、质量积分精确且离散 lead 正则，式 (8) 的端点负指数差可解释为**那个离散无限模型**的计数；普通 QZ 和求积输出首先只是近似矩阵结果。

把中心分为内部 $I$ 和墙面 $W$，当 $A_{II}=(K_c-\mu M_c)_{II}$ 可逆时，

$$
n_-(\widehat T_h)=n_-(A_{II})+n_-(F_h),\qquad
F_h=S_c+\operatorname{diag}(D_{-,h},D_{+,h}). \tag{9}
$$

惯性在非奇异合同变换下不变，因而 $R_W^{-*}F_hR_W^{-1}$ 仍只代表墙面部分。

漏掉 $n_-(A_{II})$ 的危险可由一个纯代数例子看出：取

$$
T(\mu)=\begin{pmatrix}3-\mu&1\\1&3-\mu\end{pmatrix},
\quad a=2.5,\ b=3.5.
$$

完整矩阵两端各有一个负方向，计数差为 $0$；墙面 Schur 数量为 $3-\mu-(3-\mu)^{-1}$，两端负指数差却是 $-1$。中心块贡献 $+1$ 恰好补回。此例只验证惯性记账，不替代二维模型或构成数值实验。

## 6. 结论的四个层次

| 层次 | 本文件得到什么 | 没有得到什么 |
| --- | --- | --- |
| 连续 $A(\beta)$ | H1–H4 下严格公式 (7)，按重数计 | 当前具体区间已经计数为 $1$ |
| 精确 DtN | (3)–(6) 的完整中心约化、有限负指数、负 crossing | 有限 QZ 输出自动等于精确 DtN |
| 离散 FEM | 合同及 Schur 惯性恒等式；理想离散模型可有自己的计数定理 | 离散负指数已穷尽连续负方向 |
| 认证提升 | 下一文件的有限块／无限补空间判据可作为充分条件 | 当前代码已经提供了该判据的全部常数 |

## 7. 文献核验与证明报告

- **已核验的主要来源：** Fliss 2013 [DOI](https://doi.org/10.1137/12086697X)，Prop.3.1、Thm.4.1、Thm.4.5、Lemma4.7、Prop.4.8、Thm.4.9、Prop.4.10；本地作者稿 PDF pp.7、10–14、16。Klindworth–Schmidt–Fliss 2014 [DOI](https://doi.org/10.1016/j.camwa.2013.03.005)，Prop.2.1、Thm.3.4、Thm.3.11、Cor.3.12、Remark3.13、Eq.(36)；本地 2013-02-08 稿 PDF pp.4、6、9、13。
- **条件核对：** 实正有界权重、固定准周期参数、周期端、公共 bulk gap、半条带 Dirichlet 正则性与这里 H1–H3 对应。2014 §2.1 明确允许不同两端，§7.4 有异质实例；不把异质推广作为本轮新结论。其频率参数为 $\omega$，Eq.(36) 的 $-2\omega$ 导数经 $\mu=\omega^2$ 变为 (6) 的负质量。
- **本轮独立写出的推理：** L1 显式参考延拓与紧性；L2–L4；SC1 的有限核 Schur crossing 证明；式 (9) 的必要记账。均为标准算子工具的本模型化表达，不据此声明首创。
- **目标位置和环境：** 本文件 §§2–4 的 Markdown `Proof` 块；新增标签 L1–L4、SC1，编号为本文件手工编号，不接入论文编号。用户同时授权了定义、比较、解释及实验设计等非 proof 内容。
- **原文完整性：** 新建独立探索文件；没有替换旧证明。书籍引用：无。本证明没有待核验的外部定理依赖；基础 Sobolev、谱定理及 Fredholm 事实为标准输入，并已写出本问题所需的连接步骤。
- **证明状态：** `Proof literature verification completed.` 这是 H1–H4 下定理的状态。材料实例的 H2、H3、H4 及离散提升均尚未认证，不能由该状态升级。

更一般的 lead 极点穿越、边缘阈值、变号材料或非自伴损耗情形不在 SC1 中。它们不阻止本轮无极点最小定理成立，也不需要先扩展后才能设计端点实验。
