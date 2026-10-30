# 从离散端点惯性到连续谱计数

日期：2026-10-28。本文研究“没有漏掉负方向”的证明合同，不继续优化候选波数误差。结论依赖 [[research/explorations/spectral-counting/minimal_counting_theorem]] 的 H1–H3；以下认证还可证明 H4。台账仅见 [[research/explorations/spectral-counting/STATUS]]。

## 1. 首要区别：矩阵完备不等于空间完备

对完整 FEM 矩阵做可靠 LDL，最多证明其全部有限维惯性。连续空间还有中心高频方向、墙面高频迹，以及真实无限端响应。两个求解器在候选处相差约 $10^{-12}$，只涉及已找到的一个根；不能排除同一区间中别的根，也不能证明其重数为一。

相容 Galerkin 对精确中心形式满足

$$
n_-(t_\mu|_{V_h})\le n_-(t_\mu).
$$

这是单向结论。两端各有一个单向不等式，不能相减得到正确区间计数。若已经取得端点整数区间 $L_e\le n_-(t_e)\le U_e$，$e=a,b$，才有

$$
\max\{0,L_b-U_a\}\le N_A((a,b))\le U_b-L_a.
$$

若已认证的区间彼此导致右端小于左端，则至少一个前提或证书有误。

## 2. 不能把 DtN 的未解析部分补零

沿用主定理的 $X=H^{1/2}_\beta$、$X^*=H^{-1/2}_\beta$、$\Lambda_c$。使用等价的 Fourier 范数

$$
\|g\|_X^2=\sum_n\kappa_n|g_n|^2,
\qquad \|f\|_{X^*}^2=\sum_n\kappa_n^{-1}|f_n|^2.
$$

则 $\Lambda_c:X\to X^*$ 是等距映射。若 $\Pi_N$ 截断到有限 Fourier 模态，

$$
\|\Lambda_c-\Pi_N\Lambda_c\Pi_N\|_{X\to X^*}=1
\quad\hbox{对所有有限 }N.
$$

这是直接由任一遗漏 Fourier 向量得到的严格反例；不是计算结果。因而有限维 DtN 矩阵补零后不可能逼近其完整一阶主部。对中心归一化算子 $T_\mu=I+\text{compact}$ 同样不能把整体补零后要求算子范数收敛。

正确的两个方向是：保留 $\Lambda_c$ 或补空间上的恒等正主部，仅逼近紧余项；或直接证明未解析补空间上的正性并估计交叉块。以下采用后者。

## 3. 一个有限块加补空间的严格惯性证书

在主定理的 Hilbert 空间 $(V,b_c)$ 上，取有限维相容子空间 $V_h$，$P$ 为 $b_c$ 正交投影，$Q=I-P$。对某个端点 $\mu$，把精确 $T_\mu$ 写成

$$
T_\mu=\begin{pmatrix}B&C\\C^*&D\end{pmatrix}
\quad\hbox{作用于 }V_h\oplus QV,
$$

其中 $B:V_h\to V_h$、$C:QV\to V_h$、$D:QV\to QV$。$B$ 的坐标必须相对于 $b_c$ 正交归一基；若使用原 FEM 基，则先用其 $b_c$ Gram 矩阵进行合同归一化。

**定理 C1（可认证的端点惯性充分条件）。** 假设已严格证明

$$
D\ge\gamma I,\quad \gamma>0,
\qquad \|C\|\le\eta,
\qquad \|B-\widehat B\|\le\varepsilon, \tag{1}
$$

其中 $\widehat B$ 为一个有限维 Hermitian 算子。设其有序特征值为 $\widehat\lambda_1\le\cdots\le\widehat\lambda_m$。若对某个 $0\le r\le m$，

$$
\widehat\lambda_r+\varepsilon<0,
\qquad
\widehat\lambda_{r+1}-\varepsilon-\frac{\eta^2}{\gamma}>0, \tag{2}
$$

其中 $r=0$ 时省略第一式、$r=m$ 时省略第二式，则 $T_\mu$ 可逆且 $n_-(t_\mu)=r$。

**Proof.** 因 $D$ 有界可逆且严格正，三角有界可逆合同变换把 $T_\mu$ 化成 $S\oplus D$，其中 $S=B-CD^{-1}C^*$。故 $n_-(T_\mu)=n_-(S)$，且二者同时可逆。由 (1)，

$$
\widehat B-\left(\varepsilon+\eta^2/\gamma\right)I
\ \le S\le\ \widehat B+\varepsilon I.
$$

有限维 min–max 给出 (2) 所需的前 $r$ 个严格负、其余严格正。证毕。

若 $\widehat B$ 的特征值也只被区间包围，用 $\widehat\lambda_r$ 的可靠上界及 $\widehat\lambda_{r+1}$ 的可靠下界代替即可。也可以用经过验证的有限维 LDL 及可计算范数扰动界实现同一判据；普通 LDL 中的对角数值不是自动严格的谱余量。

这是标准 Schur 补和惯性原理的组合，**不声称抽象 C1 新颖**。其作用在于将尚缺的证书明确限定为 $\gamma,\eta,\varepsilon$。两个端点都通过 C1 后，L3 排除连续端点谱，SC1 给出区间精确整数。

## 4. 怎样把补空间正性变成可证明的不等式

由主定理 L1 的式 (2)，对 $w\in QV$，

$$
t_\mu[w,w]-b_c[w,w]
=-\int_C(\mu\rho+c)|w|^2
-\sum_{\sigma=\pm}\int_{E_\sigma}(\mu\rho_\sigma+c)
P_\sigma(\mu)\gamma_\sigma w\,
\overline{P_c^0\gamma_\sigma w}. \tag{3}
$$

设已经证明下列常数，所有 $L^2$ 范数在此节均为非加权范数：

$$
\begin{aligned}
\|w\|_{L^2(C)}&\le e_V\|w\|_{b_c}, && w\in QV,\\
\|P_c^0\gamma_\sigma w\|_{L^2(E_\sigma)}&\le e_{\Gamma,\sigma}\|w\|_{b_c}, &&w\in QV,\\
\|\gamma_\sigma v\|_X&\le C_{\mathrm{tr},\sigma}\|v\|_{b_c}, &&v\in V,\\
\|P_\sigma(\mu)g\|_{L^2(E_\sigma)}&\le M_\sigma(\mu)\|g\|_X, &&g\in X.
\end{aligned} \tag{4}
$$

于是 Cauchy–Schwarz 直接给出

$$
\gamma=1-(\mu\rho_{\max}+c)
\left(e_V^2+\sum_\sigma M_\sigma(\mu)C_{\mathrm{tr},\sigma}e_{\Gamma,\sigma}\right)>0
\quad\Longrightarrow\quad D\ge\gamma I. \tag{5}
$$

这是一条**已证明的条件充分不等式**，不是已获得的数值常数。不同区域可用各自 $\rho_{\max}$ 收紧；本轮不追求最紧版本。

式 (4) 的两种补空间常数来自紧映射 $V\to L^2(C)$ 与 $V\to L^2(E_\sigma)$。对 $b_c$ 稠密的嵌套空间，它们理论上趋零，但“趋零”没有给出当前网格的上界。下一步最值得证明的是：用明确的准插值／正交投影误差和参考 Fourier 延拓，给出这两个常数的显式上界，适用于真实材料几何、准周期约束及选定 FEM 空间。可以使用额外辅助 Fourier 或源问题空间；无需把所有认证空间固定为原求解器的空间。

尾部常数也有明确合同。设

$$
d_\sigma(\mu)=\operatorname{dist}(\mu,\sigma(A^D_\sigma))>0.
$$

由主定理式 (1) 和加权／非加权范数等价，可取一个有效的保守上界

$$
M_\sigma(\mu)=
\left[1+\sqrt{\frac{\rho_{\max}}{\rho_{\min}}}
\frac{\mu+c/\rho_{\min}}{d_\sigma(\mu)}\right]
\|P_c^0\|_{X\to L^2}. \tag{6}
$$

在上述 Fourier 范数下，$\|P_c^0\|_{X\to L^2}=1/(\sqrt2\min_n\kappa_n)$。所以这里真正需要的不是任意“衰减看起来很快”，而是半条带 Dirichlet 谱距的可靠下界或能替代它的可靠源问题稳定常数。

$\eta$ 可通过有限个归一化基函数的交叉残量及 Riesz 表示估计；必须界住 $\|P(T_\mu-I)Q\|$，不能只在几条已计算向量上检查残差。$\varepsilon$ 至少包含：中心真实材料积分误差、非精确几何表示误差、两端 DtN 在所需有限迹空间上的算子误差、Gram 归一化误差、代数求解和舍入误差。最后一项只是整个合同的一部分。

## 5. 当前实现与所需证书逐项对应

| 对象 | 当前可提供的普通数值资料 | 连续计数仍需的证明 |
| --- | --- | --- |
| 中心 $K_c,M_c$ | 原几何、真实材料薄带质量修正、对称性与正定性检查 | 积分及真实域的可靠包围；不能把主规则与复核规则之差直接当上界 |
| lead 响应 | 稳定 QZ 子空间、Riccati 残差、Hermitian 缺陷 | 精确半条带到离散 DtN 的误差，在指定迹范数下量化 |
| 完整端点惯性 | 稀疏 Hermitian LDL；含全部内部自由度 | 有限矩阵符号可靠性，以及 C1 的无限补空间正性和交叉块控制 |
| projected gap | 离散 Floquet 乘子与采样 band | 两侧全部实横向 Floquet 参数的连续谱排除 |
| lead 无极点 | 端点稳定子空间的 Dirichlet 图可逆 | 整个区间不存在半条带 Dirichlet 本征值；bulk gap 不足 |
| 相邻网格一致 | 数值可重复性／可行性证据 | 不能代替任何上述上界，也不自动构成无谱污染证明 |

当前源码指针：`test/i10/refine-v1/refine_i102.m` 的 `LOCAL_operators`（约 1743 行）、`LOCAL_eliminate`（约 1856 行）、`LOCAL_dtn`（约 1921 行）、中心消元和墙面矩阵（约 2067–2078 行）。稳定子空间图、单胞消元图和真正的 half-guide Dirichlet pole 是三个不同对象。

## 6. 最小 projected gap 证书

对每个周期端 $\sigma$，在一个真实二维周期胞元上，令 $A_\sigma(\theta,\beta)$ 为横向 Floquet 参数 $\theta$ 下的加权 Laplacian。需要覆盖完整实 Brillouin 区的有限个参数区间 $J_j$，并分别认证某个索引 $N_\sigma$ 满足

$$
\sup_{\theta\in J_j}\lambda_{N_\sigma,\sigma}(\theta,\beta)<a,
\qquad
\inf_{\theta\in J_j}\lambda_{N_\sigma+1,\sigma}(\theta,\beta)>b. \tag{7}
$$

若目标在最低谱以下，省略第一式。不同侧索引不必相同；无需证明所有 band edges 的精确位置。固定 $\beta$ 将覆盖降为一维参数问题；不能自动只算 $\theta=0,\pi$，也不能在无已证明对称性时把参数区间减半。

Hoang–Plum–Wieners 2009 的 Theorems 1–2 给胞元上下界，§4 构造必要的下一本征值下界，Lemma6／Theorem7 用显式参数扰动半径填补采样点之间的空隙。若已有严格 gap 证书覆盖 (7)，应复用证书而不是重做；普通采样图不能充当该证书。

对本质量型算子，也有一个可直接使用的保守覆盖不等式。令 $\theta$ 为具有波数单位的横向参数（胞元周期 $d_\sigma$ 时，边界相位为 $e^{\mathrm i\theta d_\sigma}$），在固定周期函数空间上作 gauge 后，三角不等式及 min–max 给出

$$
\left|\sqrt{\lambda_{j,\sigma}(\theta,\beta)}-
\sqrt{\lambda_{j,\sigma}(\theta_0,\beta)}\right|
\le\frac{|\theta-\theta_0|}{\sqrt{\rho_{\sigma,\min}}}. \tag{8}
$$

**Proof.** 对任意试探函数，$\|\nabla_{\theta,\beta}u\|_{L^2}$ 与 $\|\nabla_{\theta_0,\beta}u\|_{L^2}$ 的差的绝对值至多为 $|\theta-\theta_0|\|u\|_{L^2}$；以 $\|u\|_{L^2(\rho_\sigma)}$ 归一化后至多为右侧。对每个 $j$ 维试探子空间取上确界，再取下确界，分别交换 $\theta,\theta_0$ 即得 (8)。不要求 band 简单，也不要求已证明端点极值。证毕。

故若节点 $\theta_0$ 的严格上下界为 $L_j\le\lambda_j(\theta_0,\beta)\le U_j$，覆盖半径 $r$ 上可用

$$
\left(\max\{0,\sqrt{L_j}-r/\sqrt{\rho_{\sigma,\min}}\}\right)^2
\le\lambda_j(\theta,\beta)\le
\left(\sqrt{U_j}+r/\sqrt{\rho_{\sigma,\min}}\right)^2. \tag{9}
$$

这里只在 $L_j\ge0$ 时使用该写法；负的可靠下界可先用非负性替换为零。式 (8)–(9) 是标准变分不等式的本模型表达，不作新颖性声明。它把“有限采样还缺什么”明确为可靠的逐索引胞元包围和可覆盖的参数半径；代价可能保守，但无需数值估计 band 导数。

**反射排除机制及当前模型的限制：** 若每个周期端关于其实际人工切口分别反射对称，奇函数子空间为全周期算子的约化子空间，半条带 Dirichlet 实现与其限制酉等价；故 bulk gap 也是该半条带的 gap。该论证保持 $y$ 准周期条件，不要求左右相同。但当前三叶形不满足这一条件：源码给出 $r_\alpha(\theta)=q_\alpha(1+\alpha\cos3\theta)$，$q_\alpha=0.2/\sqrt{1+\alpha^2/2}$，$\alpha=0.12,0.20$，没有旋转。竖直反射把 $\theta$ 变为 $\pi-\theta$，使余弦项变号。在切口 $m+1/2$ 两侧对应点 $m+q_\alpha$ 与 $m+1-q_\alpha$、$y=0$，材料分别为 $17$ 与 $1$，因为 $q_\alpha(1-\alpha)<q_\alpha<q_\alpha(1+\alpha)$。严格不等式也给出开集上的反射不一致。依据为 `refine_i102.m` 约 682、1210 行及当前配置。故本模型不能使用这条廉价机制；这并不证明实际存在 lead pole。

若反射不成立，则 H3 需要独立半条带谱排除／经过验证的稳定 Cauchy 图在整个区间内可逆。仅验证两个端点或离散稳定乘子远离单位圆都不足。也可分段或改用穿 pole 的相对指数理论，但不应未经校正继续使用 SC1。

## 7. 本轮严格结果、尚缺内容和停止条件

已证明：主部补零的算子范数障碍；C1；由 (4) 推出 (5) 的条件估计；有反射时的 lead-pole 排除机制。它们不依赖运行数值实验。

尚缺：当前模型的全部认证常数和区间 gap／pole 证书。因此本轮不能输出实际连续整数。最优先证明缺口是 **两个端点上的有限计算如何排除整个未解析空间中的负方向**，建议以式 (4)–(6) 和 C1 为验收合同。其结果能直接决定是否可把本轮已计算的两个离散惯性提升为连续计数。

若有限块符号余量明显大于可达到的误差上界，则值得继续认证；若宽区间穿越 lead pole 或余量过小，先改区间／切口或分段。不能因旧候选吻合很好而强行输出 $1$。

证明模式为 **Proof from scratch**，新增环境 C1 的 `Proof` 块位于 §3；§2 和 §4–6 为授权的辅助推导。外部结果的核对见方法比较文件；本文件 C1 不依赖专门的未经核验定理。`Proof literature verification completed.` 实例常数尚缺是认证实施缺口，不是 C1 的证明缺口。
