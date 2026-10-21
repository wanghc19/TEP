# 物理算子、界面记账与谱包含

## 1. 权威模型及定义域

本专题采用 2026-09-18 只读核对的 main `draft/zh/s-modelproblem.tex`
中 `eq:fixed-beta-operator`，而非单个人工胞元的 Dirichlet 算子。
固定实数 $\beta$，设

$$
B=\mathbb R\times(-d/2,d/2),\qquad
\mathcal H=L^2(B,\rho\,\mathrm dx\,\mathrm dy),\qquad
0<\rho_-\le\rho\le\rho_+<\infty.
$$

令 $\Sigma=\mathbb R\times\{d/2\}$、
$\widetilde\Sigma=\mathbb R\times\{-d/2\}$，则

$$
H^1(\Delta,B)=\{v\in H^1(B):\Delta v\in L^2(B)\},
$$

$$
\begin{aligned}
A(\beta)&:D(A(\beta))\subset\mathcal H\longrightarrow\mathcal H,
&A(\beta)v&=-\rho^{-1}\Delta v,\\
D(A(\beta))
&=\{v\in H^1(\Delta,B):
v|_\Sigma=e^{\mathrm i\beta d}v|_{\widetilde\Sigma},\quad
\partial_yv|_\Sigma=e^{\mathrm i\beta d}\partial_yv|_{\widetilde\Sigma}\}.
\end{aligned}
\tag{F1}
$$

$\Delta$ 是全条带的分布 Laplacian，导数边界条件先按弱迹理解。
材料 transmission 要求值及同一个法向的普通导数连续，均包含在 (F1)；没有
$\rho$ 加权通量。$H^1(B)$ 同时包含无穷远的平方可积及有限梯度能量条件。
人工胞元边界不对这个算子增加边界条件。

为不把尚未核验的外部适配当作依据，非负自伴性可在这里直接确认。
$V_\beta=H^1_\beta(B)$ 上的
$a(v,w)=\int_B\nabla v\cdot\nabla\overline w$ 是稠密定义的非负闭形式，
因为 $\rho$ 上下有界，且准周期值条件是闭的迹条件。形式表示定理给出非负自伴算子。
对内部紧支撑测试函数，其作用必为 $-\rho^{-1}\Delta v$；对允许非零上下迹的
准周期测试函数，Green 公式给出 (F1) 的弱导数配对条件。反之，(F1) 给出的场
满足该形式恒等式（先用紧支撑截断，再取极限）。故此形式算子正是 (F1)。
这里仅使用闭形式表示、Sobolev 迹和 Fourier/谱定理这些基础结果；关键的全局
$H^2$ 升阶及全部常数在
[[research/projects/eig-apost/phase3-analysis/resolvent-bound/s-trace|T1--T5]] 自行证明。

## 2. 唯一的界面记账

中心胞元宽度为 $2a$，左右背景胞元宽度为 $L$，两者不必相等。
保留单个单连通 inclusion $\Omega_0$，不分裂成多个分支；左右单胞中对应的 inclusion
仍按来源记为 $\Omega_-,\Omega_+$，其周期复制是不同空间位置，不是
$\Omega_0$ 的多个连通分支。为使用本专题定理，另要求实际出现的边界满足假设 G。
没有中心材料界面的冻结实例，中心材料项直接为空，不制造一个虚构 inclusion。

取

$$
\mathscr E=\mathscr E_{\mathrm{mat}}\mathbin{\dot\cup}
\mathscr E_{\mathrm{art}}.
\tag{F2}
$$

- $\mathscr E_{\mathrm{mat}}$：中心的 $\partial\Omega_0$（若存在）及左右单胞
  $\partial\Omega_\pm$ 的全部半无限周期平移，覆盖实际 raw 重建中的全部材料界面。
- $\mathscr E_{\mathrm{art}}$：中心/首胞两条界面
  $\Gamma_-\ (x=-a)$、$\Gamma_+\ (x=a)$，以及
  $x=-a-(n+1)L$、$x=a+(n+1)L$，$n\ge0$，每条只计一次。

此基线按 i5 的分离 inclusion/直墙几何设置；若材料边界跨人工胞元切线，则必须先将
实际材料边界按圆柱几何和胞元分片建立唯一 incidence 清单，而不能把同一边界同时作为
材料项和人工项重复累加。重合的材料/人工界面只能保留一个两侧面；本轮的分离证书
已经排除该退化情形，不声称自动覆盖它。

上下边界代表一条准周期接缝。raw 场精确满足值和 $\partial_y$ 的准周期匹配时，
它们的 Green 项相消，不属于 (F2)；这样既未遗漏缺陷，也未重复计数。
若 raw 存在准周期缺陷，按第 5 节将该接缝计入一次。

在每条界面固定从侧 1 指向侧 2 的法向，定义

$$
a_\Gamma=u^{(2)}|_\Gamma-u^{(1)}|_\Gamma,
\qquad
j_\Gamma=\partial_{\nu_\Gamma}u^{(1)}|_\Gamma
-\partial_{\nu_\Gamma}u^{(2)}|_\Gamma.
\tag{F3}
$$

本文 $u=u_{h,M}$ 是 frozen exact-kernel raw 场。其连续定义由冻结系数与指定精确核
确定；有限求积/截断造成的评价误差必须另作包围，不能假称为零。

| 界面 | 侧 1、侧 2 与法向 | 与最新 i5 的对应 |
|---|---|---|
| 材料 | inclusion 内、外，$\nu$ 指向外 | $a=u^{\mathrm{out}}-u^{\mathrm{in}}$，$j=\partial_\nu u^{\mathrm{in}}-\partial_\nu u^{\mathrm{out}}$，与 `residual-bound/README.md` 和材料模块的强缺陷一致 |
| 中心/首胞人工界面 | 中心、首胞，$\nu_-=-e_x,\nu_+=e_x$ | 法向缺陷等于两侧外法向导数之和；值缺陷按 `design-5-1g` (I5.1g-12) 的实际配对值差 |
| 半波导内部人工界面 | 近中心胞元、远中心胞元，法向朝无穷远 | 法向缺陷仍为两侧外法向之和；值差为 `design-5-1g` (I5.1g-13) 的远侧减近侧 |

若旧数据保存的是 $a_{\Gamma,r}=u^{(r)}-g_\Gamma$，则只有对同一个共享
$g_\Gamma$ 才有 $a_\Gamma=a_{\Gamma,2}-a_{\Gamma,1}$；两条单侧范数不能
被当成一条跳跃，已有总 lift 上界也不是本路线的缺陷范数。
较新的 i5.1g--i5.1j 已采用实际配对跳跃，这一点优先于旧 README 中的单侧文字。

main `s-error.tex` 的材料符号仍写成
$a_\Upsilon=u^+-u^-$、$j_\Upsilon=\partial_\nu u^+-\partial_\nu u^-$。
这对旧 lift 路线有其上下文，但不能不加映射地作为 (F3) 的 Green 配对：若
$+$ 表外侧，新的 $a$ 相同而新的 $j$ 取负；若 $+$ 表内侧，新的 $a$ 取负而新的
$j$ 相同。本专题直接使用 i5 明确的 in/out 定义，不静默重解释旧符号。

## 3. raw 场的充分正则性条件

**假设 U。** 原始材料/胞元分区局部有限，各有界截断片为 Lipschitz 域。
$u\in\mathcal H$，在每个分片直至其边界局部属于 $H^2$，使第二 Green 恒等式可用。
这里不假定 $u\in H^1(B)$。给定候选 $\mu=\widehat k^2\in I$，逐片有

$$
(-\Delta-\mu\rho)u=0.
\tag{F4}
$$

raw 的上下值和导数精确准周期匹配，且
$\varepsilon_{\partial,\ell_*}<\infty$，其中范数为 (T10)。
无量纲形式使用 $\ell_*=1$。光滑有限密度 exact-kernel 层势在光滑材料边界两侧的
正则性、完整 $P_\pm$ 的衰减与单胞映射有界性，是未来需要核对的输入条件；
本轮未根据已有小矩阵残量宣称这些输入已全部评价。

假设 U 是便于实施的充分条件；可以改用弱 Green 迹，但本轮不引入负阶支线。
它不包含修正场 $e$，也不要求先把 $u$ 提升为全局 $H^1$。

## 4. 全条带 Green 恒等式及无穷远极限

**命题 F1（原始跳跃恒等式）。** 假设 G、U 成立。若
$\mu\notin\sigma(A(\beta))$，定义证明辅助场

$$
z=(A(\beta)-\mu I)^{-1}u\in D(A(\beta)).
\tag{F5}
$$

则

$$
\boxed{\|u\|_{\mathcal H}^2
=\sum_{\Gamma\in\mathscr E}\int_\Gamma
\left(j_\Gamma\overline z+
a_\Gamma\partial_{\nu_\Gamma}\overline z\right)\,\mathrm ds .}
\tag{F6}
$$

级数绝对收敛。$z$ 只用于证明，后续算法不需要实际求解它。

**证明。** 在一个分片 $K$ 上，对 $\phi$ 用第二 Green 恒等式：

$$
\int_K u(-\Delta-\mu\rho)\overline\phi
=\int_K(-\Delta-\mu\rho)u\,\overline\phi
+\int_{\partial K}
\left(\partial_{\nu_K}u\,\overline\phi
-u\,\partial_{\nu_K}\overline\phi\right)\,\mathrm ds.
\tag{F7}
$$

两侧外法向分别为 $\nu_\Gamma,-\nu_\Gamma$，$z$ 及其普通法向导数的迹单值。
因此两片之和的边界项为 $j_\Gamma\overline\phi+
a_\Gamma\partial_{\nu_\Gamma}\overline\phi$，给出 (F3) 的两个正号。
原始上下边两项在同相位准周期条件下相消；$\beta$ 实数保证共轭相位抵消。

为严谨处理无穷远，取实 $\chi\in C_c^\infty(\mathbb R)$，$0\le\chi\le1$，
在 $[-1,1]$ 上为一、在 $[-2,2]$ 外为零；置 $\chi_R(x)=\chi(x/R)$，
$\phi=\chi_Rz$。其支撑只接触有限个胞元，(F7) 可先有限求和。
令 $r=(-\Delta-\mu\rho)u$（当前为零），得到准确的截断恒等式

$$
\begin{aligned}
\int_B\chi_R\rho|u|^2
={}&\int_B r\chi_R\overline z
+\sum_\Gamma\int_\Gamma\chi_R
(j_\Gamma\overline z+a_\Gamma\partial_{\nu_\Gamma}\overline z)\,\mathrm ds\\
&+\sum_\Gamma\int_\Gamma
a_\Gamma(\partial_{\nu_\Gamma}\chi_R)\overline z\,\mathrm ds
+\int_Bu(2\chi_R'\partial_x\overline z+\chi_R''\overline z).
\end{aligned}
\tag{F8}
$$

由 T4，$z$ 的值迹和法向迹都在界面 $L^2$ 的平方可和直和中。与 (T10) 使用
Cauchy--Schwarz 得到边界主级数绝对收敛。附加界面项的绝对值至多为

$$
\frac{\|\chi'\|_\infty}{R}
\left(\sum_\Gamma\|a_\Gamma\|_2^2\right)^{1/2}
\left(\sum_\Gamma\|z|_\Gamma\|_2^2\right)^{1/2}\longrightarrow0.
$$

附加体项至多为

$$
\|u\|_2\left(
\frac{2\|\chi'\|_\infty}{R}\|\partial_xz\|_2
+\frac{\|\chi''\|_\infty}{R^2}\|z\|_2\right)\longrightarrow0.
$$

此处只需要 $u\in\mathcal H$，没有暗中假设 raw 场的全局 $H^1$ 连续性或人为
端面通量逐点消失。对质量积分及绝对收敛级数取极限，$r=0$ 给出 (F6)。证毕。

## 5. 体缺陷及准周期缺陷的有限扩展

若逐片体缺陷 $r=(-\Delta-\mu\rho)u$ 非零，且

$$
\varepsilon_{\mathrm{vol}}
:=\|\rho^{-1}r\|_{\mathcal H}
=\left(\int_B\rho^{-1}|r|^2\right)^{1/2}<\infty,
\tag{F9}
$$

则 (F6) 右端增加 $\int_Br\overline z$。这是体缺陷，不属于界面缺陷。
在 $\mu\notin\sigma(A)$ 时，其绝对值至多
$\varepsilon_{\mathrm{vol}}\|u\|_{\mathcal H}/\delta_{\mathrm{spec}}$。

若 raw 场准周期不匹配，在上边 $\Sigma$ 用相位拉回下边，定义

$$
a_{\mathrm{qp}}=e^{\mathrm i\beta d}u|_{\widetilde\Sigma}-u|_\Sigma,
\qquad
j_{\mathrm{qp}}=\partial_yu|_\Sigma
-e^{\mathrm i\beta d}\partial_yu|_{\widetilde\Sigma}.
\tag{F10}
$$

两边未相消的项恰为

$$
\int_{\mathbb R}
(j_{\mathrm{qp}}\overline z|_\Sigma
+a_{\mathrm{qp}}\partial_y\overline z|_\Sigma)\,\mathrm dx.
\tag{F11}
$$

将它作为一条水平圆柱接缝（或按胞元分段、端点忽略）计入 $\mathscr E$ 一次，
将其两个 $L^2(\mathbb R)$ 缺陷加到 (T10)，并相应重评 T4 的 collar 重数。
可取接缝 collar 宽度小于 $d/2$，自身重数为一；它与材料/人工 collar 的重叠
只给旧重数加一。$z$ 本身仍精确准周期，物理算子不变。
若这些 seam 缺陷不在 $L^2$，不能声称本专题的 $L^2$ 定理适用。

## 6. 从迹界到谱距离

**定理 F2（原始缺陷谱包含）。** 令
$U=\|u\|_{\mathcal H}>0$、$Q=C_{\mathrm{tr},\ell_*}
\varepsilon_{\partial,\ell_*}$，使用 T4 的常数，必要时包含第 5 节 seam。
若假设 G、U 成立且 $Q<U$，则

$$
\boxed{\delta_{\mathrm{spec}}
:=\operatorname{dist}(\mu,\sigma(A(\beta)))
\le\frac{2\mu Q}{U-Q}.}
\tag{F12}
$$

有体缺陷时，以第 5 节的 $\rho^{-1}r\in\mathcal H$ 条件替换假设 U 中的
(F4)，其余条件保留，只将右端分子改为 $2\mu Q+\varepsilon_{\mathrm{vol}}$。

**证明。** $\mu$ 在谱上时距离为零，结论直接成立。否则自伴算子的谱定理给出
$\|(A-\mu I)^{-1}\|_{\mathcal H\to\mathcal H}=1/\delta_{\mathrm{spec}}$，
不需要离散特征基。由 $(A+\mu I)z=u+2\mu z$，

$$
\|(A+\mu I)z\|_{\mathcal H}
\le\left(1+\frac{2\mu}{\delta_{\mathrm{spec}}}\right)U.
\tag{F13}
$$

(F6)、(T9)--(T10) 和 Cauchy--Schwarz 给出

$$
U^2\le\varepsilon_{\partial,\ell_*}T_{\ell_*}(z)
\le Q\left(1+\frac{2\mu}{\delta_{\mathrm{spec}}}\right)U.
$$

除以 $U$，在 $U-Q>0$ 下移项即得 (F12)。若有体缺陷，增加
$\varepsilon_{\mathrm{vol}}U/\delta_{\mathrm{spec}}$，同样整理即可。证毕。

因此可以用严格单侧输入 $\underline U\le U$、
$\overline\varepsilon_\partial\ge\varepsilon_{\partial,\ell_*}$、
$\overline C\ge C_{\mathrm{tr},\ell_*}$、
$\overline\varepsilon_{\mathrm{vol}}\ge\varepsilon_{\mathrm{vol}}$
（精确 PDE 时为零）形成

$$
\overline Q=\overline C\,\overline\varepsilon_\partial,
\qquad \underline U>\overline Q,
\qquad
\mathcal R_{\mathrm{spec}}
=\frac{2\mu\overline Q+\overline\varepsilon_{\mathrm{vol}}}
{\underline U-\overline Q}.
\tag{F14}
$$

则 $[\mu-\mathcal R_{\mathrm{spec}},\mu+\mathcal R_{\mathrm{spec}}]$
与 $\sigma(A(\beta))$ 相交。闭非空实谱的最近距离在有限点取得；也可将区间与
$[0,\infty)$ 相交。这里没有识别特征值编号、重数或唯一性。

若分母很小，界会很宽；若分母非正，该公式不提供有限上界。二者都不等于 candidate
错误。只有另行确认该包含区间严格位于同一 $A(\beta)$ 的本质谱空隙中，才能按
Weyl--Fredholm 本质谱约定将其中的谱点解释为孤立有限重特征值。
本专题不使用 draft 尚列为猜想的本质谱等式来自动认证 gap，也不承担整个 gap 专题。
