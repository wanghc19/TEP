# I1 阶段总结

## 摘要

当前方法必须分成连续定义和数值计算两个层次理解。连续层面与 Fliss 2013 的做法相同：固定沿缺陷方向的准周期参数，并把实数 $k$ 取在 projected gap 中；再避开 half-guide 的 Dirichlet 例外值后，对人工墙上的任意 Dirichlet 数据，求解整个半无限周期介质中唯一的衰减解，并把该解在人工墙上的定向法向导数定义为 DtN。当前项目与 Fliss 2013 采用的法向方向相反，所以两者的 DtN 整体相差一个负号。这个连续算子先由 half-guide 偏微分方程定义，与 Fourier 截断、BIE、Bloch mode 或 QZ 无关。

数值层面仍沿用早期 `TEP/draft` 的基本路线：先用普通周期胞元的 BIE/Fourier 求解得到 one-cell scattering matrix，再把胞元两端相差一个 Floquet multiplier 的条件写成 generalized eigenvalue problem。主要变化不是放弃 Bloch 理论或绕过这个广义特征值问题，而是改变衰减 Bloch 信息的提取方式：早期方法显式求出各个 Bloch multiplier 和 Bloch mode，再逐个挑选衰减 mode；当前方法用 ordered QZ 直接提取这些衰减 mode 张成的整个子空间，减少对单个特征向量、mode 排序和可能不稳定的逆运算的依赖。

因此，当前离散 DtN 的计算主链是

$$
\text{one-cell scattering matrix}
\longrightarrow
\text{generalized eigenvalue problem}
\longrightarrow
\text{ordered QZ 衰减子空间}
\longrightarrow
\text{Cauchy data}
\longrightarrow
\text{离散 DtN}.
$$

最后一步中，QZ 子空间先给出墙上所有允许的“函数值--法向导数”配对；只有函数值能够稳定决定法向导数时才显式形成 DtN，否则保留完整 Cauchy graph。这一分层与 [[research/projects/eig-apost/implementation/i1/design|I1 design]] 一致，也说明 QZ 只是连续 DtN 的离散计算手段，而不是 DtN 的定义。

## 一页结论

I1 的任务，是把“左右无限周期介质只允许向无穷远衰减的场”变成一个可以实际计算和审计的有限维边界条件，再与挖掉中心一整列后留下的 homogeneous 空列耦合。I1 依次完成了理论设计、实际带宽装配检查、实轴候选搜索和候选附近的小复圆盘 readiness 检查。

阶段最终状态为：

`I1_COMPLETE_WITH_CONDITIONS / SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS`

这里的“完成”严格限于固定 $M=48$ 的离散算子。当前可信候选为

$$
k_*=1.8327703475952146.
$$

在该点，coarse/fine 两个空间层的物理最小奇异值分别约为 $1.11983265\times10^{-8}$ 和 $1.11983284\times10^{-8}$，归一化指标 $s_1=\sigma_1/\sigma_{\max}$ 分别约为 $8.32008721\times10^{-8}$ 和 $8.32008862\times10^{-8}$。这说明矩阵存在一个残差很小的近零方向，但 I1 **没有**运行 contour、locator 或 root isolation，因而尚未得到离散 root；更没有得到连续物理 eigenvalue 或 estimator。

现在允许进入另行预注册的经验型 root isolation，是因为 I1.4 已在候选周围检查：各采样点仍使用同一平方根分支、同一衰减子空间、同一坐标表示和同一批可用线性因子，没有观察到能制造假 dip 的切换或内部奇点。这是进入下一步计算的经验依据，不是特征值存在性定理。

## I1 处理的数学问题

### 从无限区域到一个有限矩阵

左右两侧都是无限延伸的周期介质，不能直接把无穷多个胞元全部放入矩阵。连续理论先由左右 half-guide 边值问题定义精确 DtN：给定人工墙上的函数值，返回能够向相应无穷远衰减的解的有向法向导数。I1 不用有限 trace 矩阵反过来定义这个精确对象，而是构造它的离散近似。

墙上保留 Fourier 模态 $m=-M,\ldots,M$，故每个墙有

$$
K=2M+1
$$

个系数。当前模型完整挖掉中心一列，中心区域是 homogeneous 空列，没有中心介质边界密度，因此中心 BIE density dimension 为 $n=0$。BIE 在本阶段主要用于求普通周期胞元的 one-cell scattering blocks；未来若中心重新放入介质柱，才需要加入尚未资格化的中心 density blocks。

令 $X_L<X_R$ 为中心空列的左右人工墙，$W=X_R-X_L$，并定义

$$
\Gamma(k)=\operatorname{diag}(\gamma_m(k)),
\qquad
E(k)=\operatorname{diag}\!\left(\exp(\mathrm{i}\gamma_m(k)W)\right).
$$

$\Gamma$ 收集各 Fourier 模态沿波导 $x$ 方向的传播或衰减常数，$E$ 表示相应模态穿过中心空列后的传播因子。当前未知量为

$$
\mathbf q=
\begin{bmatrix}
a_c^-\\
b_c^+
\end{bmatrix}
\in\mathbb C^{2K},
$$

其中 $a_c^-$ 是从左墙沿正 $x$ 方向进入中心空列的振幅，$b_c^+$ 是从右墙沿负 $x$ 方向进入中心空列的振幅；二者都锚定在各自所在的墙上。这里用粗体 $\mathbf q$ 与后续实验中的标量 score 区分。法向统一从中心指向 half-guide，即 $\nu_-=-e_x$、$\nu_+=e_x$。因此中心场在两墙上的 Dirichlet/Neumann 系数为

$$
\begin{aligned}
D_-&=[I\ \ E]\mathbf q,
&N_-&=[-\mathrm{i}\Gamma\ \ \mathrm{i}\Gamma E]\mathbf q,\\
D_+&=[E\ \ I]\mathbf q,
&N_+&=[\mathrm{i}\Gamma E\ \ -\mathrm{i}\Gamma]\mathbf q.
\end{aligned}
$$

左墙的负号来自 $\nu_-=-e_x$，不是由左右对称性猜出来的。

### 当前 $A_{\mathrm{def}}(k)$ 的定义

记左右 half-guide 的离散 DtN 为 $\Lambda_{-,h,M}(k)$、$\Lambda_{+,h,M}(k)$。当 Dirichlet 坐标安全时，要求中心场的 Cauchy 数据满足

$$
N_\pm-\Lambda_{\pm,h,M}D_\pm=0.
$$

按列 $(a_c^-,b_c^+)$ 和行“左端口残差、右端口残差”排列，得到当前实际使用的未平衡矩阵

$$
\boxed{
A_{\mathrm{def},h,M}^{D}(k)=
\begin{bmatrix}
-(\mathrm{i}\Gamma+\Lambda_{-,h,M})
&(\mathrm{i}\Gamma-\Lambda_{-,h,M})E\\
(\mathrm{i}\Gamma-\Lambda_{+,h,M})E
&-(\mathrm{i}\Gamma+\Lambda_{+,h,M})
\end{bmatrix}}
\in\mathbb C^{2K\times2K}.
$$

本文后面简称它为 $A_{\mathrm{def}}(k)$。它的第一块行衡量左墙不匹配，第二块行衡量右墙不匹配。若存在 $\mathbf q\ne0$ 使 $A_{\mathrm{def}}(k)\mathbf q=0$，则在当前离散空间内，中心空列的非零波场同时满足左右无限介质所要求的衰减边界条件。若在冻结的物理 trace 权重与归一化下，加权矩阵的最小奇异值很小，则只说明存在一个非零方向使两侧匹配残差都很小，所以产生一个 root candidate；单个小奇异值不等于已经隔离出复根，也不自动等于连续物理特征值。

I1.3 实际扫描的是按已冻结 Sobolev/physical coefficient convention 加权并以固定 seed scale 归一化后的矩阵；同时核对 raw 与 physical 最低点位置。可逆加权不改变精确 kernel，但会改变奇异值的数值大小，所以报告中的 deep dip 必须连同这套固定坐标和粗细层一致性一起解释，不能脱离坐标单看一个 $\sigma_{\min}$。

### 容易误解的上下标

本报告不逐一解释表示左右位置或模态编号的普通下标，下面只说明容易与其他对象混淆的记号：

| 记号 | 含义 |
|---|---|
| $a_c^-,b_c^+$ 中的 $c$ | `center`，表示系数属于中心空列。它不是 graph 组合系数 $c_-,c_+$。 |
| $A_s,B_s$ 中的 $s$ | `stable`，表示原 one-cell pencil 中朝右侧无穷远衰减的 QZ 子空间。$A_s,B_s$ 是同一个 QZ frame 的上下两个振幅 blocks。 |
| $A_u,B_u$ 中的 $u$ | 沿用历史 `unstable` 命名；当前实际通过 reversed pencil 独立构造，物理上表示朝左侧无穷远衰减的子空间，不表示采用增长场。 |
| $D_{s,\pm},N_{s,\pm}$ 中的 $s$ | `stable/decaying`，表示这些 Dirichlet 和 Neumann blocks 来自相应 half-guide 的衰减子空间。 |
| $A_{\mathrm{sc}},B_{\mathrm{sc}}$ 中的 `sc` | `scattering`，表示由 one-cell scattering blocks 组装的广义 pencil。它们是整个 $2K\times2K$ pencil matrices，不是 $A_s,B_s$。 |
| $A_{\mathrm{def}}$ 中的 `def` | `defect`，表示中心缺陷与左右 half-guide 的匹配矩阵。它不是 deformation 或 derivative 的缩写。 |
| $A_{\mathrm{def}}^{D}$ 的上标 $D$ | `Dirichlet-chart/DtN realization`：当 $D_{s,\pm}$ 能安全求解时，先形成离散 DtN，再把 half-guide 组合系数消去所得的较小矩阵。这里的 $D$ 不是幂。 |
| $A_{\mathrm{def}}^{G}$ 的上标 $G$ | `graph realization`：不消去 half-guide 组合系数，直接同时匹配 Dirichlet 和 Neumann 数据所得的完整矩阵。这里的 graph 是 Cauchy-data subspace，不是图论中的图。 |
| 下标 $h,M$ | $h$ 概括空间/BIE 离散层，$M$ 是墙面 Fourier 截断阶数；它们提醒读者该对象是离散近似，不是精确连续算子。 |
| $c_-,c_+$ | 左右 half-guide 衰减基的组合系数。它们与 $a_c^-,b_c^+$ 中表示 `center` 的下标 $c$ 没有关系。 |

因此，$A_{\mathrm{def},h,M}^{D}$ 可以直接读作“在空间层 $h$、Fourier 带宽 $M$ 下，用安全 Dirichlet/DtN 坐标写成的缺陷匹配矩阵”；$A_{\mathrm{def},h,M}^{G}$ 则是同一匹配条件的完整 Cauchy-graph 写法。

### One-cell、QZ、Cauchy graph 和 DtN 的关系

整个离散链可以概括为

$$
\text{one-cell scattering}
\longrightarrow
\text{generalized pencil}
\longrightarrow
\text{decaying subspace}
\longrightarrow
\text{Cauchy graph}
\longrightarrow
\text{DtN 或 graph realization}
\longrightarrow
A_{\mathrm{def}}.
$$

1. **One-cell scattering。** 普通周期胞元的 BIE/Fourier 求解给出

   $$
   \begin{bmatrix}b^L\\a^R\end{bmatrix}
   =
   \begin{bmatrix}R_L&T_{RL}\\T_{LR}&R_R\end{bmatrix}
   \begin{bmatrix}a^L\\b^R\end{bmatrix}.
   $$

   四个 $K\times K$ blocks 表示从胞元两端入射后产生的反射和透射。

2. **One-cell generalized pencil。** 把“穿过一个周期后只差一个 Floquet multiplier $\lambda$”写成

   $$
   A_{\mathrm{sc}}z=\lambda B_{\mathrm{sc}}z,
   \qquad
   A_{\mathrm{sc}}=
   \begin{bmatrix}-R_L&I\\T_{LR}&0\end{bmatrix},
   \qquad
   B_{\mathrm{sc}}=
   \begin{bmatrix}0&T_{RL}\\I&-R_R\end{bmatrix}.
   $$

   这里的 $\lambda$ 是胞元间的传播倍数，不是要寻找的 guided eigenvalue $k$。

3. **Ordered QZ。** QZ 直接处理这个广义特征值问题，不需要先形成可能不稳定的 transfer-matrix inverse。原 pencil 选出朝右侧无穷远衰减的 $K$ 维子空间；reversed pencil 独立选出朝左侧无穷远衰减的 $K$ 维子空间，并把它放在正确的参考墙上。若方向、数量或所选子空间跳变，压缩后的 half-guide 边界条件就会选错。

4. **Cauchy graph。** 将左右 QZ frames 写成振幅 blocks 后，分别得到

   $$
   \begin{aligned}
   D_{s,+}&=A_s+B_s,
   &N_{s,+}&=\mathrm{i}\Gamma(A_s-B_s),\\
   D_{s,-}&=A_u+B_u,
   &N_{s,-}&=-\mathrm{i}\Gamma(A_u-B_u).
   \end{aligned}
   $$

   集合

   $$
   \left\{(D_{s,\pm}c,N_{s,\pm}c):c\in\mathbb C^K\right\}
   $$

   本实验沿用“离散 Cauchy graph”的简称：它列出一个向无穷远衰减的场在人工墙上可能出现的“函数值与法向导数配对”。严格说，它首先是一个 Cauchy-data subspace；只有安全 Dirichlet chart 存在时，才是某个单值 DtN 的 graph，否则应视为 linear relation。

5. **Chart 与 DtN。** chart 只是给同一个 Cauchy graph 选坐标。若 $D_{s,\pm}$ 能够安全求解，函数值可以稳定决定法向导数，便形成

   $$
   \Lambda_{\pm,h,M}=N_{s,\pm}D_{s,\pm}^{-1},
   $$

   实现中用右线性求解，不使用显式 inverse 或 `pinv`。若 graph 对 Dirichlet 坐标近乎“竖直”，强行形成 DtN 会放大误差；这时 graph 本身未必错误，只是该坐标不安全，必须保留完整 Cauchy relation。

不显式形成 DtN 时，保留 graph coordinates $c_-,c_+$，使用

$$
\boxed{
A_{\mathrm{def},h,M}^{G}(k)=
\begin{bmatrix}
I&E&-D_{s,-}&0\\
-\mathrm{i}\Gamma&\mathrm{i}\Gamma E&-N_{s,-}&0\\
E&I&0&-D_{s,+}\\
\mathrm{i}\Gamma E&-\mathrm{i}\Gamma&0&-N_{s,+}
\end{bmatrix}}
\in\mathbb C^{4K\times4K}.
$$

其未知量顺序为 $(a_c^-,b_c^+,c_-,c_+)$，四块行依次匹配左 Dirichlet、左 Neumann、右 Dirichlet、右 Neumann 数据。当两个 Dirichlet charts 都安全时，消去 $c_-$、$c_+$ 会精确得到 $A_{\mathrm{def}}^{D}$；因此 graph 形式是更原始的边界表示，DtN 形式是它在安全坐标下的 Schur reduction。

当前 $M=48$、$K=97$ 时，主要尺寸如下：

| 对象 | 尺寸 |
|---|---:|
| one-cell blocks $R_L,T_{RL},T_{LR},R_R$ | $97\times97$ |
| generalized pencil $A_{\mathrm{sc}},B_{\mathrm{sc}}$ | $194\times194$ |
| QZ frame $Z_\pm$ | $194\times97$ |
| $D_{s,\pm},N_{s,\pm},\Lambda_{\pm,h,M}$ | $97\times97$ |
| safe-DtN matrix $A_{\mathrm{def}}^{D}$ | $194\times194$ |
| full-graph matrix $A_{\mathrm{def}}^{G}$ | $388\times388$ |

## 四个里程碑得到了什么

### I1.1：冻结一套没有循环定义的构造

I1.1 先把连续对象和离散计算手段分开：精确 DtN 由 half-guide PDE 定义，QZ 和有限 Cauchy graph 只是它的离散计算路线；$A_{\mathrm{def}}$ 是离散中心耦合算子的矩阵表示，不反过来定义连续特征值问题。设计还冻结了 Fourier 顺序、左右法向、original/reversed 两次 QZ、regular infinite pair 的处理、安全 chart、graph fallback、未知量顺序、块尺寸和失败策略。

两项独立审查最终均为 `PASS WITH CONDITIONS`，design-level `BLOCKER=0`。这说明有限维公式、符号、尺寸和实现合同内部一致；它没有填补连续 BIE kernel--field 等价或谱逼近证明。

### I1.2：实际 $M=48$ 矩阵链条填对了

I1.2 先用人工小矩阵检查尺寸、顺序、法向符号、basis invariance、Schur 等价和必要错误负例，再使用 MATLAB `lsqminnorm` 生成实际 $M=48$、$K=97$ 的 coarse/fine one-cell maps。权威结果为 `I1_2_M48_PASS_WITH_CONDITIONS`：

- one-cell block 的最大 coarse/fine coefficient change 为 $5.75\times10^{-14}$；
- original/reversed QZ 的计数与残差门通过，最大 residual 为 $5.25\times10^{-15}$；
- 四次 QZ 均得到 97 stable、97 unstable、0 neutral、0 indeterminate；
- coarse/fine Cauchy graph projector change 为 $7.06\times10^{-15}$；
- DtN action change 为 $6.52\times10^{-16}$；
- graph--DtN Schur 等价误差为 $4.30\times10^{-16}$；
- coarse/fine $A_{\mathrm{def}}$ action change 为 $2.98\times10^{-16}$。

因此，当前实际带宽上的 one-cell $\to$ QZ $\to$ graph $\to$ DtN $\to A_{\mathrm{def}}$ 静态装配链通过。这里的 chart 仅认证为代数上条件良好，production generalized-Sylvester separation 尚未计算，所以不是无条件的扰动稳定性认证。

### I1.3：找到了明显且跨空间层一致的 dip

I1.3 先确认 real-$k$ 邻域内 QZ 计数、衰减子空间、chart 和 coarse/fine matrices 连续，再以 $M=12\to24\to48$ 的廉价分层筛查缩小搜索范围。最终 width-driven 局部加密固定 $M=48$，每层把区间分为四段，并以区间宽度而不是局部 prominence 作为停止条件。

最终 15 个区间层、33 个唯一 $k$ 点和 167 个 hard gates 全部通过，区间宽度达到

$$
7.6293945295\times10^{-7}<10^{-6}.
$$

coarse/fine 最小点均为 $k_*$，位置漂移为 0；最终物理最小奇异值约为 $1.11983\times10^{-8}$，归一化 $s_1$ 约为 $8.32009\times10^{-8}$。左右最小奇异向量的 coarse/fine overlap 约为 1，且

$$
\frac{\sigma_1}{\sigma_2}=1.6258325\times10^{-7},
$$

说明唯一的近零奇异方向与下一奇异方向清晰分离。QZ 仍保持 97 stable、97 unstable、0 neutral、0 indeterminate。最后三个逐层稳健指标，即每层 coarse/fine 最小 $s_1$ 的较大者，仍明显下降，没有形成 $10^{-3}$ 平台。

I1.3 同时暴露了明确边界：graph-basis mutation 后的有限差分变化为 $3.65\times10^{-11}>10^{-12}$，所以 `FD_DERIVATIVE_READY=false`。当前差分导数不能充当 production $A_{\mathrm{def}}'(k)$，也不能支持 Newton、simple-root correction 或 estimator。

### I1.4：确认 dip 不像离散构造切换造成的假象

I1.3 只告诉我们实轴上有很深的 dip。一个 dip 仍可能是数值构造在附近突然改变造成的，例如平方根换支、QZ 误选另一簇、graph 改用另一套坐标、某个中间求解因子接近奇异，或左右 block 装反。I1.4 围绕 $k_*$ 取半径

$$
r_0=3.8146972647\times10^{-7}
$$

的小复圆盘，检查候选附近是否确实是一套固定的离散矩阵族。

- **Anchored branch** 固定 $\gamma_m(k)=\sqrt{k^2-\beta_m^2}$ 的起始选支并连续跟踪。若邻点重新取平方根主值而翻转传播方向，矩阵可能人为不连续。
- **固定 QZ cluster 与 frame** 从种子点继续同一个衰减子空间，不能逐点按模长重新选簇或重新选坐标行。若子空间计数或 overlap 失败，说明所比较的已不是同一个离散对象。
- **固定 chart/rank** 禁止根据局部结果临时改坐标、删模态或改 rank。这排除了“表示方法切换后恰好出现小奇异值”的解释。
- **Factor/pole ledger** 逐点记录 proxy、BIE、固定 frame、Dirichlet solve 和 DtN/Schur 等内部因子的可用性、条件性和残差。它检查已采样点的 dip 是否只是某个隐藏分母近奇异造成的假象，但不能证明未采样处绝无 pole。
- **Closure** 从不同路径继续衰减子空间，到达同一目标点时必须回到同一个 graph。若结果依赖路径，就发生了换支或换簇。
- **Cauchy--Riemann 检查** 比较完整 $A_{\mathrm{def}}$ 沿复数 $k$ 的实方向和虚方向变化。通过支持这些采样矩阵来自同一个局部解析离散族；失败则会提示隐藏的复共轭、分支重选、$k$ 依赖坐标或严重差分问题。
- **必要负例** 故意施加错误改动，确认上述检查能够拒绝已知坏构造，而不是无论输入怎样都给 PASS。

V4 的全部正向门以及 6 个 CR-negative 门通过：82 个 node rows、820 个 factor rows、164 个 branch rows、164 个 QZ rows、8 个 closure rows 和 36 个 CR rows 均通过。QZ 始终为 97/97/0/0，最小 chordal separation 为 $0.8444105$，continued-subspace 最小 overlap 为 $0.9999999999999398$。最近 branch point 距候选约 $1.33277$，而检查使用的最大位移仅约 $1.72\times10^{-6}$；最大 full-$A_{\mathrm{def}}$ CR defect 为 $5.80\times10^{-7}<10^{-6}$。尽管如此，V4 的 overall verdict 仍因下面的普通 `transmission_swap` 负例固定为 FAIL。

唯一未通过的普通负例是交换 $T_{RL}$ 与 $T_{LR}$：当前左右完全对称的物理模型使二者相对差仅约 $1.25\times10^{-14}$，所以交换在这个模型中本来就不可辨识。该物理负例没有被追溯改写为通过。V5 保留 V4 的结果，只用一个可辨识的非对称 $K=3$ assembly oracle 检查代码公式，得到 identifiability $0.212904$、formula error $0$、swap change $0.129922$。因此关闭的是“装配顺序是否实现正确”这个问题，而不是宣称当前对称模型动态辨识了左右传输 labels。

综合而言，I1.4 支持如下有限结论：I1.3 的 dip 在已采样小复圆盘内仍属于同一套 branch-anchored、fixed-frame、fixed-chart、fixed-rank 的 $M=48$ 离散算子构造，没有发现已列出的数值机制能够偶然制造它。这就是 `SAMPLED_FIXED_M_DISCRETE_ROOT_READINESS` 的含义。

## 最终 verdict 与下一步边界

I1 可以正式标记为 `COMPLETE WITH CONDITIONS`，但“完成”只表示：

1. 固定 $M=48$ 的离散 $A_{\mathrm{def}}$ 有经过审查的定义；
2. 实际 one-cell/QZ/graph/DtN/$A_{\mathrm{def}}$ 装配链已经通过；
3. 实轴上找到一个 coarse/fine 一致、近零方向清晰分离的 deep dip；
4. 该候选在一个小复圆盘的有限采样上通过当前 I1.4 readiness。

当前结果仍只是 fixed-$M=48$ 的离散 root candidate。I1 没有计算 contour count，没有隔离或求出复 root，没有建立它与连续物理 eigenvalue 的严格等价，也没有计算 eigenvalue correction、estimator 或 effectivity。

下一阶段可以在完全冻结的模型、$M=48$、branch、frame、chart 和 factor gates 下，另行预注册 derivative-free contour/count 与 root isolation，并比较 coarse/fine isolated roots。之所以现在可以做这一步，是因为 I1 已把“先确认候选附近比较的是同一个稳定离散算子族”这项前置风险降到当前经验门以下；不是因为 root 已经被证明存在。

## 遗留问题及其实际限制

### 限制连续物理 eigenvalue 解释

- 精确 half-guide DtN 在所选复域上的 holomorphy，以及与 Wood threshold、half-guide Dirichlet spectrum 和 BIE poles 的分离，尚未形成完整证明。
- 连续 BIE representation 的 completeness、injectivity、kernel--field equivalence、Fredholm/adjoint 关系尚未证明。因此未来即使离散矩阵有 root，也还需排除非零 algebraic vector 对应零场或非物理解。
- 连续 one-cell relation 到 BIE/Fourier pencil 的 primal/adjoint consistency，以及 regular spectral approximation 与排除 spectral pollution 尚未证明。
- 当前只验证固定 $M=48$，不是 Fourier trace-order convergence；I1.4 的 factor ledger 只覆盖有限采样点，也不是“圆盘内不存在未采样 pole”的定理。

这些问题不阻止下一阶段先隔离同一个有限维离散族的 root，但阻止把该 root 直接称为真实连续 guided eigenvalue。

### 限制 derivative-based Newton、simple-root correction 和 estimator

- production $A_{\mathrm{def}}'(k)$ 尚不可用；缺少经过资格化的 analytic QZ subspace tangent，有限差分 mutation 门也未通过。
- 物理 adjoint pairing、simple-root 的非零左右导数配对和 eigentrace regularity 尚未完成。
- 设计已经冻结系数级 zero-padding prolongation 和对偶 Neumann restriction，但它们还需真正用于 matched-root hierarchy，并补齐 operator consistency、eigentrace regularity 和 saturation/remainder 假设。没有这些条件，相邻层差只能称 next-level correction，不能称剩余误差 estimator。

因此下一阶段应优先使用 derivative-free isolation；Newton、simple-root correction、estimator 和 effectivity 仍未获资格。

### 不阻止下一阶段但必须披露

- Production generalized-Sylvester `DIF/sep` 尚未资格化，当前 graph/chart 稳定性依赖 residual、count、overlap、margin 和相邻层变化等经验门，不是严格 perturbation lower bound。
- I1.4 是 sampled readiness；它没有证明所有未采样复点都没有 branch、factor 或 pole 问题。
- 当前模型左右对称，物理 $T_{RL}$、$T_{LR}$ 的 swap 负例不可辨识；V5 只用非对称人工 oracle 认证装配公式。未来若改用非对称 lead，必须增加真实路径的 label test。
- I1.2/I1.3 的部分 solver/provenance 字段主要来自生成器自证；V5 锁定了 V4 的父证据和 sources，但没有把 V5 自己的 plan/runner 纳入其 self-manifest。这不改变当前数值结果，却限制更强的 provenance closure 声明。
- I1.4 中最小 proxy factor reciprocal condition 约为 $1.05\times10^{-8}$，只略高于 $10^{-8}$ 门。当前 residual 与粗细层检查通过，但下一阶段仍应逐点保留 factor ledger。

## 权威入口

- 理论设计：[[research/projects/eig-apost/implementation/i1/design|I1 design]]；设计审查：[[research/projects/eig-apost/implementation/i1/review|I1 review]]。
- 阶段路线和问题边界：[[research/projects/eig-apost/implementation/ROADMAP|ROADMAP]]；[[research/projects/eig-apost/implementation/open-problems#Current I1|current I1 ledger]]。
- I1.2：[[test/README#I1-HG-ADEF-V1|experiment index]]；[[test/i1/hg-adef/output/prod-full/report|M48 static report]]。
- I1.3：[[test/README#I1-K-SCAN-V1|candidate search]]；[[test/README#I1-K-SCAN-ZOOM-V2|width-driven zoom]]；[[test/i1/k-scan/output/zoom2/report|final zoom report]]。
- I1.4：[[test/README#I1-K-READY-V1|readiness experiment]]；[[test/i1/k-ready/output/v4-a1/report|positive parent]]；[[test/i1/k-ready/output/v5-a1/report|final conditional closure]]。
