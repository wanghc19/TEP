# 理论到未来数值设计的接口

本文件仅给出未来计算合同，不创建 I6，不执行实验。
主定理与谱代数分别见
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace|T4]]、
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-framework|F2]]。
当前状态是“理论基线已经证明；本实例的常数、缺陷和分母尚未评价”。

## 1. 冻结对象与输入表

后续所有量必须来自同一个 $\widehat k,\beta$、几何、材料、有限密度、中心状态、
$P_\pm,c_\pm$ 和 exact-kernel raw 场定义。调整评价分辨率不得重新生成 candidate
或在不同 raw 场之间混用分子、分母。

| 所需输入 | 有限内容/判据 | i5 复用边界 |
|---|---|---|
| 模型与尺度 | $\rho_-,\rho_+,d,L,2a,I$，固定 $\ell_*=d$ 或记录无量纲化 | 可复用已冻结数值及材料含义；需重新记录尺度和频率窗口 |
| 全界面清单 | 中心材料、左右材料模板、两条中心/首胞墙、全部内部墙；seam 是否精确相消 | 可复用 singleton/full-$P$ 归属，但按 F2 核对每条一次 |
| 几何常数 | $h,\kappa_*,\theta,N_{\mathrm{ov}}$；T12--T13 的有限证书 | i5 的曲线、曲率、collar、间距信息可候选复用；不能把旧门为 true 当作新完整族的证明 |
| 实际值跳跃 | $a_\Gamma=u^{(2)}-u^{(1)}$ 的完整 $L^2$ 上界 | i5.1g 的 paired wall rows、材料 signed value rows 可复用；旧 shared-data 单侧量须先相减 |
| 普通法向跳跃 | $j_\Gamma=\partial_\nu u^{(1)}-\partial_\nu u^{(2)}$ 的完整 $L^2$ 上界 | 单个 signed coefficient/row 及其误差包围可复用；旧 $H^{-1/2}$ 总量不可直接复用 |
| raw 质量下界 | $0<\underline U\le\|u_{h,M}\|_{\mathcal H}$ | 必须评价 raw 场；旧 $\widehat u$ 的移位能量分母不适用 |
| 传播尾 | 完整 $P_\pm$ 的块幂收缩或 Lyapunov 证书 | 若矩阵、状态、坐标范数完全相同，旧有限矩阵证书可复用 |
| exact PDE/QP | 精确核恒等式和 seam cancellation；否则 $\varepsilon_{\mathrm{vol}}$、seam 跳跃 | 不能从小数值残差自动推得零；有限镜像核可能仍满足局部 PDE，却未精确准周期 |
| 评价误差 | 几何、求积、源插值、核截断、特殊函数、有限模/无限胞元尾，按实际对象唯一归属 | 旧未关闭的 $\Delta_{\mathrm{sf}},\Delta_{\mathrm{fp}}$ 仍未关闭 |

原生字段可在 `implementation/i5/SYMBOL.md` 追踪：`z.khat`、`z.beta`、`z.d`、
`z.L`（其旧 i5 理论含义为 $d_x$）、`z.eta_unit_256`、`z.Gplus/Gminus`、
`z.Pplus/Pminus`、`z.cplus/cminus`、`z.q_center`。这些只是已存在合同的只读定位；
本轮未打开 MAT 文件验证数值，也不保证所有 future 实例使用相同维数或圆形适配器。

## 2. 值跳跃的最新 i5 映射

最新 `design-5-1g` (I5.1g-12)--(13) 及 `s-lift-tail` (ME-29)--(30)
已将人工墙改为实际配对跳跃。用其已定义的 $V_L,V_R,G_\pm$，内部墙的值行是

$$
(V_RG_+-V_LG_+P_+)P_+^nc_+,
\qquad
(V_LG_--V_RG_-P_-)P_-^nc_-,\quad n\ge0.
\tag{N1}
$$

其法向行仍分别为

$$
(Q_RG_++Q_LG_+P_+)P_+^nc_+,
\qquad
(Q_LG_-+Q_RG_-P_-)P_-^nc_-.
\tag{N2}
$$

$Q_{L/R}$ 是旧 i5 的单胞外法向行；(N2) 的加号对应两侧外法向之和。
中心/首胞 singleton 使用各自的中心 Rayleigh 场加首胞实际迹，不可把
$n=0$ 的内部墙误当成中心墙。材料 $a,j$ 则使用完整 identity/self/regular-image/
off-surface 带符号行，先组合物理跳跃，再求范数。

旧 $B_{\mathrm{lift}}$ 不进入新公式。尤其 i5.1j 中较大的 $R_1$ 是为控制提升的
切向导数误差而引入；本方法的材料值缺陷只需要 $L^2$。其已保存的 $Q_0,R_0$
及生成它们的行包围可按下节重新组合，不使用旧提升权重、$Q_1$ 或总
$B_{\mathrm{lift}}$。这不保证新结果必然小：法向跳跃 $L^2$ 比旧负阶范数更强，
其高模尾必须重新评价。

## 3. 全部界面 L2 范数的有限算法

### 3.1 一种统一的实变量行包围

单胞中的任一实际缺陷写为 $F(s)x$，其中 $x\in\mathbb C^q$ 是冻结状态，
$F$ 是该曲线或墙上的完整物理行。这里 $F$ 是缺陷行，不是物理算子 $A(\beta)$。
在有限个弧长 panel $J_r$ 上选择显式行中心 $C(s)$（分片常数或连续线性），并给出

$$
\|F(s)-C(s)\|_{\mathrm{op}}\le e_r(s),\qquad s\in J_r,
\qquad
G_C=\int C(s)^*C(s)\,\mathrm ds,
\qquad
R_F=\sum_r\int_{J_r}e_r(s)^2\,\mathrm ds.
\tag{N3}
$$

只用有限行代数和多项式积分即可形成 $G_C$。于是

$$
\|Fx\|_{L^2}
\le\sqrt{x^*G_Cx}+\sqrt{R_F}\|x\|_2,
\qquad
\|F\|_{\mathbb C^q\to L^2}
\le\sqrt{\|G_C\|_2}+\sqrt{R_F}.
\tag{N4}
$$

**证明。** $\|Cx\|_{L^2}^2=x^*G_Cx$，且点态行误差界给出
$\|(F-C)x\|_{L^2}^2\le R_F\|x\|_2^2$，再用三角不等式。证毕。

一个无无限维优化的后备方案是 panel 中心取常行 $C_r$、使用整个 panel 的常半径
$e_r$，这时 $G_C=\sum_r|J_r|C_r^*C_r$、$R_F=\sum_r|J_r|e_r^2$。
半径可由一点行包围加上 panel 长度乘完整行的一阶导数界得到。
若材料存在对角奇异核，不能直接取未消去核的最大值：先使用 i5 已定义的 Kress/Maue
消去表达和源求积余项，再包围完整行。i5 的有限光滑密度和高阶导数合同为此提供
输入结构；实际特殊函数误差与舍入层仍需补齐，采样最大值不是 panel 界。
一般 $C^2$ 几何已足以证明 T4；选择 i5 的高阶核评价方法时，还需满足该方法自身
更强的曲线/密度光滑性，不能由 T4 的 $C^2$ 自动推出。

也可直接复用 i5.1j 的线性插值行包围：
$G_C=Q_0,R_F=R_0$，于是 (N4) 不再含 $R_1$。
但只有在 $Q_0,R_0$ 确实包围本专题的实际带符号值跳跃、全部状态和同一精确核时才可复用。
这是一条数学转换，不是将旧 run 中的普通浮点数字升级为可靠界。

### 3.2 复用 Fourier 行时必须改变尾权重

在归一化正交基中，$L^2$ 范数平方就是全部系数绝对值平方之和。
旧法向模块中的 $1/b_m$ 或 $1/\omega_m$ 权重必须移除后重新求尾。
负阶上界不能自动上界 $L^2$，因为其权重在高模趋于零。

作为一个完全展开的替代尾证书，若弧长周期为 $p_\Gamma$ 的缺陷行满足
$\|\partial_s^pF\|_{L^2(\mathrm{op})}\le D_p$，$p\ge1$，则 Parseval 给出

$$
\sum_{|m|\ge M}\|(Fx)_m\|^2
\le\left(\frac{p_\Gamma}{2\pi M}\right)^{2p}D_p^2\|x\|_2^2,
\qquad M\ge1.
\tag{N5}
$$

对准周期直墙先对 $e^{-\mathrm i\beta y}F(y)$ 使用周期 Parseval，其导数界由
有限 Leibniz 展开形成。也可复用旧指数衰减系数界，然后直接对无负阶权重的平方和
求几何级数及多项式乘几何级数。必须保留新的 $L^2$ 权重与所有未计算模。
这两种办法只需有限阶行导数或已有显式高模系数常数；不需求一个精确 transmission 解。

### 3.3 用完整传播矩阵控制无限胞元

对每个方向 $\varsigma\in\{-,+\}$，将其单胞材料和内部人工墙的两种缺陷按 (T10)
放入同一个直和行映射 $F_\varsigma$。它的自变量是近中心胞元状态；
人工墙远侧状态 $P_\varsigma x$ 已包含在 (N1)--(N2) 的行内。
设有限算法证明 $\|F_\varsigma\|\le D_\varsigma$。则精確的记账是

$$
\varepsilon_{\partial,\ell_*}^2
=\varepsilon_{\mathrm{sing},\ell_*}^2
+\sum_{\varsigma\in\{-,+\}}\sum_{n=0}^{\infty}
\|F_\varsigma P_\varsigma^nc_\varsigma\|^2.
\tag{N6}
$$

singleton 只含两条中心/首胞人工界面和中心材料界面；$n=0$ 的材料项是首胞材料，
$n=0$ 的人工项是首胞与第二胞间的墙，没有重叠。若存在准周期缺陷，其中心段进入
singleton、各半波导单胞段进入对应 $F_\varsigma$。

给定整数 $b_\varsigma\ge1$，若有有限矩阵范数上界

$$
\|P_\varsigma^{b_\varsigma}\|_2\le\alpha_\varsigma<1,
\qquad \|P_\varsigma^r\|_2\le p_{\varsigma,r},\quad0\le r<b_\varsigma,
\qquad
K_\varsigma=\frac{\sum_{r=0}^{b_\varsigma-1}p_{\varsigma,r}^2}
{1-\alpha_\varsigma^2},
\tag{N7}
$$

则

$$
\sum_{n=J}^{\infty}
\|F_\varsigma P_\varsigma^nc_\varsigma\|^2
\le D_\varsigma^2K_\varsigma\|P_\varsigma^Jc_\varsigma\|_2^2.
\tag{N8}
$$

**证明。** 写 $n-J=qb_\varsigma+r$，用
$\|P^{qb+r}x\|\le\alpha^qp_r\|x\|$，对 $q,r$ 求和即得 (N7)--(N8)。
所有矩阵乘法保留完整 $P$，未使用标量模态独立性、正规性或特征向量条件数。证毕。

有限部分 $0\le n<J$ 可使用 (N4) 的有向行中心改善效果，剩余尾只用 $D_\varsigma$。
计算 $D_\varsigma$ 时各个值行乘 $\ell_*^{-1}$，普通法向行不另加权。
若使用 Lyapunov 证书 $Y\succ0$、$Y-P^*YP\succeq I$，同样由有限望远镜求和得到
$\sum_{n\ge J}\|P^nc\|^2\le(P^Jc)^*Y(P^Jc)$。
同一传播因子只能使用一次。仅观察谱半径小于一而无幂界，不能给出 (N8) 的数值尾界。

raw 的 $\mathcal H$ 成员资格同样可由各单胞场映射
$\mathbb C^q\to L^2(\text{cell},\rho)$ 有界和 (N7) 保证。
光滑有限维 exact-kernel 场在各有界材料片上的局部 $H^2$ 正则性须从表示和边界光滑性
核对；它是有限模板的检查，不是全波导预解式求解。

## 4. raw 质量下界：不必估计无限尾

为证明 $U>0$ 和分母正性，选有限个互不相交的闭小矩形 $D_r$，严格位于若干材料
子区域内部并远离核源/界面。对同一 raw 场，用有限核评价与导数界给出

$$
|u(x)-u_r|\le e_r\quad(x\in D_r),\qquad
\rho|_{D_r}\ge\rho_{r,-}>0.
$$

则有完全显式的下界

$$
\boxed{\underline U^2
=\sum_r\rho_{r,-}|D_r|\,
\bigl(\max\{|u_r|-e_r,0\}\bigr)^2
\le\|u\|_{\mathcal H}^2.}
\tag{N9}
$$

证明是逐点反三角不等式后积分。若用多项式重构中心，可替代为
$\|u\|_{L^2(D_r,\rho)}\ge\max\{\|u_{\mathrm{center}}\|-
\|u-u_{\mathrm{center}}\|,0\}$。
遗漏的全条带质量非负，故有限子域下界不需要扣除任何无限尾。
但 $u\in\mathcal H$ 的资格仍须由上节关闭；下界不能替代成员资格。
少数 patch 下界为零只表示该选取无信息，可扩大或细分有限区域，不意味着 raw 场为零。

## 5. 输出强度与分母判据

后续计算的最短顺序如下。

1. 冻结 raw 对象和尺度，核对界面唯一清单、PDE/QP、局部正则性与 $\mathcal H$ 资格。
2. 评价有限几何证书，形成向上的 $\overline C$；选择点值 $\mu$ 或统一窗口。
3. 计算两类实际跳跃的 $L^2$ 上界，含 singleton、有限胞元、界面全部模与完整 $P$ 尾。
4. 用有限安全体积区域评价 raw 质量下界 $\underline U$。
5. 检查 $\underline U>\overline Q=\overline C\,\overline\varepsilon_\partial$。
   通过时用 (F14) 形成谱距离界；失败时报告分母无信息，列明是常数、跳跃或下界主导。

理论式只在输入确为单侧界时产生可靠谱距离上界。普通浮点评价可以用于未来实验设计
和诊断，但应标为经验量；特殊函数误差未包围、舍入未包围或几何仅采样时，不能称为
可靠包含。全部浮点认证不是本轮理论完成的前置门槛。
最后把区间解释为离散特征值存在性，还需要独立的本质谱 gap 认证及区间包含检查。

主要保守性分别来自：T4 的共同窄 collar 和全局材料界、行中心/误差半径中损失的
物理相消、$L^2$ 法向高模尾、非正规 $P$ 的幂界，以及只积分有限 patch 的质量下界。
这些来源可逐项记录。避免把大的旧提升切向导数项误判成新路线必然失败，也避免把
移除该项解释成新估计必然有效。
